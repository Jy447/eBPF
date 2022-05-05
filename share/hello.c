#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/seq_file.h>
#include <linux/proc_fs.h>
#include <linux/sched.h>

int helloinit(void)
{
		printk(KERN_DEBUG "hello world !!\n");
			return 0;
}

void helloexit(void)
{
		printk(KERN_DEBUG "goodbye world !!\n");
}

module_init(helloinit);
module_exit(helloexit);

MODULE_LICENSE("GPL");

