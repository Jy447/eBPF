#define KPROBE_HASH_BITS 6
#define KPROBE_TABLE_SIZE (1 << KPROBE_HASH_BITS)
static int kprobes_initialized;
static struct hlist_head kprobe_table[KPROBE_TABLE_SIZE];
static struct hlist_head kretprobe_inst_table[KPROBE_TABLE_SIZE];
/* NOTE: change this value only with kprobe_mutex held */
static bool kprobes_all_disarmed;
/* This protects kprobe_table and optimizing_list */
static DEFINE_MUTEX(kprobe_mutex);
static DEFINE_PER_CPU(struct kprobe *, kprobe_instance) = NULL;
static struct {
	raw_spinlock_t lock ____cacheline_aligned_in_smp;
} kretprobe_table_locks[KPROBE_TABLE_SIZE];
kprobe_opcode_t * __weak kprobe_lookup_name(const char *name,
					unsigned int __unused)
{
	return ((kprobe_opcode_t *)(kallsyms_lookup_name(name)));
}
static raw_spinlock_t *kretprobe_table_lock_ptr(unsigned long hash)
{
	return &(kretprobe_table_locks[hash].lock);
}
/* Blacklist -- list of struct kprobe_blacklist_entry */
static LIST_HEAD(kprobe_blacklist);
#ifdef __ARCH_WANT_KPROBES_INSN_SLOT
/*
 * kprobe->ainsn.insn points to the copy of the instruction to be
 * single-stepped. x86_64, POWER4 and above have no-exec support and
 * stepping on the instruction on a vmalloced/kmalloced/data page
 * is a recipe for disaster
 */
struct kprobe_insn_page {
	struct list_head list;
	kprobe_opcode_t *insns;		/* Page of instruction slots */
	struct kprobe_insn_cache *cache;
	int nused;
	int ngarbage;
	char slot_used[];
};
#define KPROBE_INSN_PAGE_SIZE(slots)			\
	(offsetof(struct kprobe_insn_page, slot_used) +	\
	 (sizeof(char) * (slots)))
static int slots_per_page(struct kprobe_insn_cache *c)
{
	return PAGE_SIZE/(c->insn_size * sizeof(kprobe_opcode_t));
}
enum kprobe_slot_state {
	SLOT_CLEAN = 0,
	SLOT_DIRTY = 1,
	SLOT_USED = 2,
};
void __weak *alloc_insn_page(void)
{
	return module_alloc(PAGE_SIZE);
}
void __weak free_insn_page(void *page)
{
	module_memfree(page);
}
struct kprobe_insn_cache kprobe_insn_slots = {
	.mutex = __MUTEX_INITIALIZER(kprobe_insn_slots.mutex),
	.alloc = alloc_insn_page,
	.free = free_insn_page,
	.pages = LIST_HEAD_INIT(kprobe_insn_slots.pages),
	.insn_size = MAX_INSN_SIZE,
	.nr_garbage = 0,
};
static int collect_garbage_slots(struct kprobe_insn_cache *c);
/**
 * __get_insn_slot() - Find a slot on an executable page for an instruction.
 * We allocate an executable page if there's no room on existing ones.
 */
kprobe_opcode_t *__get_insn_slot(struct kprobe_insn_cache *c)
{
	struct kprobe_insn_page *kip;
	kprobe_opcode_t *slot = NULL;
	/* Since the slot array is not protected by rcu, we need a mutex */
	mutex_lock(&c->mutex);
 retry:
	rcu_read_lock();
	list_for_each_entry_rcu(kip, &c->pages, list) {
		if (kip->nused < slots_per_page(c)) {
			int i;
			for (i = 0; i < slots_per_page(c); i++) {
				if (kip->slot_used[i] == SLOT_CLEAN) {
					kip->slot_used[i] = SLOT_USED;
					kip->nused++;
					slot = kip->insns + (i * c->insn_size);
					rcu_read_unlock();
					goto out;
				}
			}
			/* kip->nused is broken. Fix it. */
			kip->nused = slots_per_page(c);
			WARN_ON(1);
		}
	}
	rcu_read_unlock();
	/* If there are any garbage slots, collect it and try again. */
	if (c->nr_garbage && collect_garbage_slots(c) == 0)
		goto retry;
	/* All out of space.  Need to allocate a new page. */
	kip = kmalloc(KPROBE_INSN_PAGE_SIZE(slots_per_page(c)), GFP_KERNEL);
	if (!kip)
		goto out;
	/*
	 * Use module_alloc so this page is within +/- 2GB of where the
	 * kernel image and loaded module images reside. This is required
	 * so x86_64 can correctly handle the %rip-relative fixups.
	 */
	kip->insns = c->alloc();
	if (!kip->insns) {
		kfree(kip);
		goto out;
	}
	INIT_LIST_HEAD(&kip->list);
	memset(kip->slot_used, SLOT_CLEAN, slots_per_page(c));
	kip->slot_used[0] = SLOT_USED;
	kip->nused = 1;
	kip->ngarbage = 0;
	kip->cache = c;
	list_add_rcu(&kip->list, &c->pages);
	slot = kip->insns;
out:
	mutex_unlock(&c->mutex);
	return slot;
}
/* Return 1 if all garbages are collected, otherwise 0. */
static int collect_one_slot(struct kprobe_insn_page *kip, int idx)
{
	kip->slot_used[idx] = SLOT_CLEAN;
	kip->nused--;
	if (kip->nused == 0) {
		/*
		 * Page is no longer in use.  Free it unless
		 * it's the last one.  We keep the last one
		 * so as not to have to set it up again the
		 * next time somebody inserts a probe.
		 */
		if (!list_is_singular(&kip->list)) {
			list_del_rcu(&kip->list);
			synchronize_rcu();
			kip->cache->free(kip->insns);
			kfree(kip);
		}
		return 1;
	}
	return 0;
}
static int collect_garbage_slots(struct kprobe_insn_cache *c)
{
	struct kprobe_insn_page *kip, *next;
	/* Ensure no-one is interrupted on the garbages */
	synchronize_rcu();
	list_for_each_entry_safe(kip, next, &c->pages, list) {
		int i;
		if (kip->ngarbage == 0)
			continue;
		kip->ngarbage = 0;	/* we will collect all garbages */
		for (i = 0; i < slots_per_page(c); i++) {
			if (kip->slot_used[i] == SLOT_DIRTY && collect_one_slot(kip, i))
				break;
		}
	}
	c->nr_garbage = 0;
	return 0;
}
void __free_insn_slot(struct kprobe_insn_cache *c,
		      kprobe_opcode_t *slot, int dirty)
{
	struct kprobe_insn_page *kip;
	long idx;
	mutex_lock(&c->mutex);
	rcu_read_lock();
	list_for_each_entry_rcu(kip, &c->pages, list) {
		idx = ((long)slot - (long)kip->insns) /
			(c->insn_size * sizeof(kprobe_opcode_t));
		if (idx >= 0 && idx < slots_per_page(c))
			goto out;
	}
	/* Could not find this slot. */
	WARN_ON(1);
	kip = NULL;
out:
	rcu_read_unlock();
	/* Mark and sweep: this may sleep */
	if (kip) {
		/* Check double free */
		WARN_ON(kip->slot_used[idx] != SLOT_USED);
		if (dirty) {
			kip->slot_used[idx] = SLOT_DIRTY;
			kip->ngarbage++;
			if (++c->nr_garbage > slots_per_page(c))
				collect_garbage_slots(c);
		} else {
			collect_one_slot(kip, idx);
		}
	}
	mutex_unlock(&c->mutex);
}
/*
 * Check given address is on the page of kprobe instruction slots.
 * This will be used for checking whether the address on a stack
 * is on a text area or not.
 */
bool __is_insn_slot_addr(struct kprobe_insn_cache *c, unsigned long addr)
{
	struct kprobe_insn_page *kip;
	bool ret = false;
	rcu_read_lock();
	list_for_each_entry_rcu(kip, &c->pages, list) {
		if (addr >= (unsigned long)kip->insns &&
		    addr < (unsigned long)kip->insns + PAGE_SIZE) {
			ret = true;
			break;
		}
	}
	rcu_read_unlock();
	return ret;
}
#ifdef CONFIG_OPTPROBES
/* For optimized_kprobe buffer */
struct kprobe_insn_cache kprobe_optinsn_slots = {
	.mutex = __MUTEX_INITIALIZER(kprobe_optinsn_slots.mutex),
	.alloc = alloc_insn_page,
	.free = free_insn_page,
	.pages = LIST_HEAD_INIT(kprobe_optinsn_slots.pages),
	/* .insn_size is initialized later */
	.nr_garbage = 0,
};
#endif
#endif
/* We have preemption disabled.. so it is safe to use __ versions */
static inline void set_kprobe_instance(struct kprobe *kp)
{
	__this_cpu_write(kprobe_instance, kp);
}
static inline void reset_kprobe_instance(void)
{
	__this_cpu_write(kprobe_instance, NULL);
}
/*
 * This routine is called either:
 * 	- under the kprobe_mutex - during kprobe_[un]register()
 * 				OR
 * 	- with preemption disabled - from arch/xxx/kernel/kprobes.c
 */
struct kprobe *get_kprobe(void *addr)
{
	struct hlist_head *head;
	struct kprobe *p;
	head = &kprobe_table[hash_ptr(addr, KPROBE_HASH_BITS)];
	hlist_for_each_entry_rcu(p, head, hlist) {
		if (p->addr == addr)
			return p;
	}
	return NULL;
}
NOKPROBE_SYMBOL(get_kprobe);
static int aggr_pre_handler(struct kprobe *p, struct pt_regs *regs);
/* Return true if the kprobe is an aggregator */
static inline int kprobe_aggrprobe(struct kprobe *p)
{
	return p->pre_handler == aggr_pre_handler;
}
/* Return true(!0) if the kprobe is unused */
static inline int kprobe_unused(struct kprobe *p)
{
	return kprobe_aggrprobe(p) && kprobe_disabled(p) &&
	       list_empty(&p->list);
}
/*
 * Keep all fields in the kprobe consistent
 */
static inline void copy_kprobe(struct kprobe *ap, struct kprobe *p)
{
	memcpy(&p->opcode, &ap->opcode, sizeof(kprobe_opcode_t));
	memcpy(&p->ainsn, &ap->ainsn, sizeof(struct arch_specific_insn));
}
#ifdef CONFIG_OPTPROBES
/* NOTE: change this value only with kprobe_mutex held */
static bool kprobes_allow_optimization;
/*
 * Call all pre_handler on the list, but ignores its return value.
 * This must be called from arch-dep optimized caller.
 */
void opt_pre_handler(struct kprobe *p, struct pt_regs *regs)
{
	struct kprobe *kp;
	list_for_each_entry_rcu(kp, &p->list, list) {
		if (kp->pre_handler && likely(!kprobe_disabled(kp))) {
			set_kprobe_instance(kp);
			kp->pre_handler(kp, regs);
		}
		reset_kprobe_instance();
	}
}
NOKPROBE_SYMBOL(opt_pre_handler);
/* Free optimized instructions and optimized_kprobe */
static void free_aggr_kprobe(struct kprobe *p)
{
	struct optimized_kprobe *op;
	op = container_of(p, struct optimized_kprobe, kp);
	arch_remove_optimized_kprobe(op);
	arch_remove_kprobe(p);
	kfree(op);
}
/* Return true(!0) if the kprobe is ready for optimization. */
static inline int kprobe_optready(struct kprobe *p)
{
	struct optimized_kprobe *op;
	if (kprobe_aggrprobe(p)) {
		op = container_of(p, struct optimized_kprobe, kp);
		return arch_prepared_optinsn(&op->optinsn);
	}
	return 0;
}
/* Return true(!0) if the kprobe is disarmed. Note: p must be on hash list */
static inline int kprobe_disarmed(struct kprobe *p)
{
	struct optimized_kprobe *op;
	/* If kprobe is not aggr/opt probe, just return kprobe is disabled */
	if (!kprobe_aggrprobe(p))
		return kprobe_disabled(p);
	op = container_of(p, struct optimized_kprobe, kp);
	return kprobe_disabled(p) && list_empty(&op->list);
}
/* Return true(!0) if the probe is queued on (un)optimizing lists */
static int kprobe_queued(struct kprobe *p)
{
	struct optimized_kprobe *op;
	if (kprobe_aggrprobe(p)) {
		op = container_of(p, struct optimized_kprobe, kp);
		if (!list_empty(&op->list))
			return 1;
	}
	return 0;
}
/*
 * Return an optimized kprobe whose optimizing code replaces
 * instructions including addr (exclude breakpoint).
 */
static struct kprobe *get_optimized_kprobe(unsigned long addr)
{
	int i;
	struct kprobe *p = NULL;
	struct optimized_kprobe *op;
	/* Don't check i == 0, since that is a breakpoint case. */
	for (i = 1; !p && i < MAX_OPTIMIZED_LENGTH; i++)
		p = get_kprobe((void *)(addr - i));
	if (p && kprobe_optready(p)) {
		op = container_of(p, struct optimized_kprobe, kp);
		if (arch_within_optimized_kprobe(op, addr))
			return p;
	}
	return NULL;
}
/* Optimization staging list, protected by kprobe_mutex */
static LIST_HEAD(optimizing_list);
static LIST_HEAD(unoptimizing_list);
static LIST_HEAD(freeing_list);
static void kprobe_optimizer(struct work_struct *work);
static DECLARE_DELAYED_WORK(optimizing_work, kprobe_optimizer);
#define OPTIMIZE_DELAY 5
/*
 * Optimize (replace a breakpoint with a jump) kprobes listed on
 * optimizing_list.
 */
static void do_optimize_kprobes(void)
{
	/*
	 * The optimization/unoptimization refers online_cpus via
	 * stop_machine() and cpu-hotplug modifies online_cpus.
	 * And same time, text_mutex will be held in cpu-hotplug and here.
	 * This combination can cause a deadlock (cpu-hotplug try to lock
	 * text_mutex but stop_machine can not be done because online_cpus
	 * has been changed)
	 * To avoid this deadlock, caller must have locked cpu hotplug
	 * for preventing cpu-hotplug outside of text_mutex locking.
	 */
	lockdep_assert_cpus_held();
	/* Optimization never be done when disarmed */
	if (kprobes_all_disarmed || !kprobes_allow_optimization ||
	    list_empty(&optimizing_list))
		return;
	mutex_lock(&text_mutex);
	arch_optimize_kprobes(&optimizing_list);
	mutex_unlock(&text_mutex);
}
/*
 * Unoptimize (replace a jump with a breakpoint and remove the breakpoint
 * if need) kprobes listed on unoptimizing_list.
 */
static void do_unoptimize_kprobes(void)
{
	struct optimized_kprobe *op, *tmp;
	/* See comment in do_optimize_kprobes() */
	lockdep_assert_cpus_held();
	/* Unoptimization must be done anytime */
	if (list_empty(&unoptimizing_list))
		return;
	mutex_lock(&text_mutex);
	arch_unoptimize_kprobes(&unoptimizing_list, &freeing_list);
	/* Loop free_list for disarming */
	list_for_each_entry_safe(op, tmp, &freeing_list, list) {
		/* Disarm probes if marked disabled */
		if (kprobe_disabled(&op->kp))
			arch_disarm_kprobe(&op->kp);
		if (kprobe_unused(&op->kp)) {
			/*
			 * Remove unused probes from hash list. After waiting
			 * for synchronization, these probes are reclaimed.
			 * (reclaiming is done by do_free_cleaned_kprobes.)
			 */
			hlist_del_rcu(&op->kp.hlist);
		} else
			list_del_init(&op->list);
	}
	mutex_unlock(&text_mutex);
}
/* Reclaim all kprobes on the free_list */
static void do_free_cleaned_kprobes(void)
{
	struct optimized_kprobe *op, *tmp;
	list_for_each_entry_safe(op, tmp, &freeing_list, list) {
		list_del_init(&op->list);
		if (WARN_ON_ONCE(!kprobe_unused(&op->kp))) {
			/*
			 * This must not happen, but if there is a kprobe
			 * still in use, keep it on kprobes hash list.
			 */
			continue;
		}
		free_aggr_kprobe(&op->kp);
	}
}
