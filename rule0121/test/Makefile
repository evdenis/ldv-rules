
obj-m += test_correct_1.o
obj-m += test_correct_2.o
obj-m += test_incorrect.o

all:
	 make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	 make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
