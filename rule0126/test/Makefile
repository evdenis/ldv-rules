obj-m += etest.o
obj-m += main.o
main-objs := file1.o file2.o

all:
	 make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	 make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

EXTRA_CFLAGS = -DEXTERN=1
