obj-m += main.o

all:
	 make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	 make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

EXTRA_CFLAGS = -fno-inline -fno-inline-functions-called-once
