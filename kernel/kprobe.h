#include"types.h"
#include"spinlock.h"

struct kprobe;
struct pt_regs;//这是什么？
struct kretprobe;
struct kretprobe_instance;

struct hlist_node;
struct list_head;

typedef int kprobe_opcode_t;


typedef int (*kprobe_pre_handler_t) (struct kprobe *, struct pt_regs *);
typedef void (*kprobe_post_handler_t) (struct kprobe *, struct pt_regs *,
				       unsigned long flags);
typedef int (*kprobe_fault_handler_t) (struct kprobe *, struct pt_regs *,
				       int trapnr);
typedef int (*kretprobe_handler_t) (struct kretprobe_instance *,
				    struct pt_regs *);
struct kprobe {
	struct hlist_node hlist;
	/* list of kprobes for multi-handler support */
	struct list_head list;
	/*count the number of times this probe was temporarily disarmed */
	unsigned long nmissed;
	/* location of the probe point */
	kprobe_opcode_t *addr;
	/* Allow user to indicate symbol name of the probe point */
	const char *symbol_name;
	/* Offset into the symbol */
	unsigned int offset;
	/* Called before addr is executed. */
	kprobe_pre_handler_t pre_handler;
	/* Called after addr is executed, unless... */
	kprobe_post_handler_t post_handler;
	/*
	 * ... called if executing addr causes a fault (eg. page fault).
	 * Return 1 if it handled fault, otherwise kernel will see it.
	 */
	kprobe_fault_handler_t fault_handler;
	/* Saved opcode (which has been replaced with breakpoint) */
	kprobe_opcode_t opcode;
	/* copy of the original instruction */
	struct arch_specific_insn ainsn;
	/*
	 * Indicates various status flags.
	 * Protected by kprobe_mutex after this kprobe is registered.
	 */
	uint32 flags;
};

/* Kprobe status flags */
#define KPROBE_FLAG_GONE	    1 /* breakpoint has already gone */
#define KPROBE_FLAG_DISABLED	2 /* probe is temporarily disabled */
#define KPROBE_FLAG_OPTIMIZED	4 /*    
				                * probe is really optimized.
				                * NOTE:
				                * this flag is only for optimized_kprobe.*/
				   
#define KPROBE_FLAG_FTRACE	8 /* probe is using ftrace */

static inline int kprobe_gone(struct probe *p)
{
    return p->flags & KPROBE_FLAG_GONE;//&就是判断是不是某一个标志位
}

int kprobe_disabled(struct probe *p)
{
    return p->flags & (KPROBE_FLAG_DISABLED | KPROBE_FLAG_GONE);
}

/* Is this kprobe really running optimized path ? */
static inline int kprobe_optimized(struct kprobe *p)
{
	return p->flags & KPROBE_FLAG_OPTIMIZED;
}
/* Is this kprobe uses ftrace ? */
static inline int kprobe_ftrace(struct kprobe *p)
{
	return p->flags & KPROBE_FLAG_FTRACE;
}

/*
 * Function-return probe -
 * Note:
 * User needs to provide a handler function, and initialize maxactive.
 * maxactive - The maximum number of instances of the probed function that
 * can be active concurrently.
 * nmissed - tracks the number of times the probed function's return was
 * ignored, due to maxactive being too low.
 *
 */

struct kretprobe {
	struct kprobe kp;
	kretprobe_handler_t handler;
	kretprobe_handler_t entry_handler;
	int maxactive;
	int nmissed;
	unsigned int data_size;
	struct hlist_head free_instances;
	spinlock lock;
};

struct kretprobe_instance
{
    struct hlist_node hlist;
    struct kretprobe *rp;
    kprobe_opcode_t *ret_addr;
    struct task_struct *task;//task_structure是个任务进程
    char data[0];
};


struct kretprobe_blackpoint {
	const char *name;
	void *addr;
};

struct kprobe_blacklist_entry {
	struct list_head list;
	unsigned long start_addr;
	unsigned long end_addr;
};

static inline int kprobes_built_in(void)
{
	return 1;
}

#ifdef CONFIG_KRETPROBES
extern void arch_prepare_kretprobe(struct kretprobe_instance *ri,
				   struct pt_regs *regs);
extern int arch_trampoline_kprobe(struct kprobe *p);
#else /* CONFIG_KRETPROBES */
static inline void arch_prepare_kretprobe(struct kretprobe *rp,
					struct pt_regs *regs)
{
}
static inline int arch_trampoline_kprobe(struct kprobe *p)
{
	return 0;
}
#endif /* CONFIG_KRETPROBES */
extern struct kretprobe_blackpoint kretprobe_blacklist[];
static inline void kretprobe_assert(struct kretprobe_instance *ri,
	unsigned long orig_ret_address, unsigned long trampoline_address)
{
	if (!orig_ret_address || (orig_ret_address == trampoline_address)) {
		printf("kretprobe BUG!: Processing kretprobe %p @ %p\n",
				ri->rp, ri->rp->kp.addr);
		BUG();
	}
}
#ifdef CONFIG_KPROBES_SANITY_TEST
extern int init_test_probes(void);
#else
static inline int init_test_probes(void)
{
	return 0;
}
#endif /* CONFIG_KPROBES_SANITY_TEST */


extern int arch_prepare_kprobe(struct kprobe *p);
extern void arch_arm_kprobe(struct kprobe *p);
extern void arch_disarm_kprobe(struct kprobe *p);
extern int arch_init_kprobes(void);
extern void show_registers(struct pt_regs *regs);
extern void kprobes_inc_nmissed_count(struct kprobe *p);
extern bool arch_within_kprobe_blacklist(unsigned long addr);
extern int arch_populate_kprobe_blacklist(void);
extern bool arch_kprobe_on_func_entry(unsigned long offset);
extern bool kprobe_on_func_entry(kprobe_opcode_t *addr, const char *sym, unsigned long offset);
extern bool within_kprobe_blacklist(unsigned long addr);
extern int kprobe_add_ksym_blacklist(unsigned long entry);
extern int kprobe_add_area_blacklist(unsigned long start, unsigned long end);

