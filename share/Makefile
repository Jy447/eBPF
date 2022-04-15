ifneq (${KERNELRELEASE},)
	obj-m := hello.o
else
	KERNEL_SOURCE := /home/xiaoy/linux-5.17.1 # 注意自行展开变量LINUX_KERNEL_PATH
PWD := $(shell pwd)

default:
		${MAKE} -C ${KERNEL_SOURCE} M=${PWD} modules

clean:
		${MAKE} -C ${KERNEL_SOURCE} M=${PWD} clean
endif

