#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/kprobes.h>


/* 对于每个探测，用户需要分配一个kprobe对象*/
static struct kprobe kp = {
    .symbol_name    = "blkdev_ioctl",
};
 
/* 在被探测指令执行前，将调用预处理例程 pre_handler，用户需要定义该例程的操作*/
static int handler_pre(struct kprobe *p, struct pt_regs *regs)
{
   
    /* 在这里可以调用内核接口函数dump_stack打印出栈的内容*/
    dump_stack();
    return 0;
}
 
/* 在被探测指令执行后，kprobe调用后处理例程post_handler */
static void handler_post(struct kprobe *p, struct pt_regs *regs,
                unsigned long flags)
{

}
 
/*在pre-handler或post-handler中的任何指令或者kprobe单步执行的被探测指令产生了例外时，会调用fault_handler*/
static int handler_fault(struct kprobe *p, struct pt_regs *regs, int trapnr)
{
    printk(KERN_DEBUG "fault_handler: p->addr = 0x%p, trap #%dn",
        p->addr, trapnr);
    /* 不处理错误时应该返回*/
    return 0;
}
 
/*初始化内核模块*/
static int __init kprobe_init(void)
{
    int ret;
    kp.pre_handler = handler_pre;
    kp.post_handler = handler_post;
    kp.fault_handler = handler_fault;
 
    ret = register_kprobe(&kp);  /*注册kprobe*/
    if (ret < 0) {
        printk(KERN_DEBUG "register_kprobe failed, returned %d\n", ret);
        return ret;
    }
    printk(KERN_DEBUG "Planted kprobe at %p\n", kp.addr);
    return 0;
}

static void __exit kprobe_exit(void)
{
    unregister_kprobe(&kp);
    printk(KERN_DEBUG "kprobe at %p unregistered\n", kp.addr);
}

module_init(kprobe_init)
module_exit(kprobe_exit)
MODULE_LICENSE("GPL");