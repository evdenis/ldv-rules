obj-m += test_correct.o
obj-m += test_incorrect_1.o
obj-m += test_incorrect_2.o
obj-m += test_incorrect_3.o

all:
	 make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	 make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

