#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"

volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
  if(cpuid() == 0){
    consoleinit();
#if defined(LAB_PGTBL) || defined(LAB_LOCK)
    statsinit();
#endif
    printfinit();
    printf("\n");
    printf("xv6 kernel is booting\n");
    printf("\n");
    // printf("11111111\n");
    kinit();         // physical page allocator

    // printf("22222222\n");
    kvminit();       // create kernel page table

    // printf("33333333333\n");
    kvminithart();   // turn on paging

    // printf("4444444444\n");
    procinit();      // process table
    // printf("555555555555\n");


    trapinit();      // trap vectors
    trapinithart();  // install kernel trap vector
    plicinit();      // set up interrupt controller
    plicinithart();  // ask PLIC for device interrupts
    binit();         // buffer cache
    iinit();         // inode cache
    fileinit();      // file table
    virtio_disk_init(); // emulated hard disk
    // printf("888888888\n");
#ifdef LAB_NET
    pci_init();
    sockinit();
#endif 
    // printf("444444444\n");   
    userinit();      // first user process
    // printf("55555555\n");
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
      ;
    __sync_synchronize();
    printf("hart %d starting\n", cpuid());
    kvminithart();    // turn on paging
    trapinithart();   // install kernel trap vector
    plicinithart();   // ask PLIC for device interrupts
  }

  printf("666666666666\n");
  scheduler();        
  printf("7777777777\n");
}
