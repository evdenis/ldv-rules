obj-m += test_correct_rcu.o
obj-m += test_incorrect_rcu_1.o

obj-m += test_correct_rcu_bh.o
obj-m += test_incorrect_rcu_bh_1.o

obj-m += test_correct_rcu_sched.o
obj-m += test_incorrect_rcu_sched_1.o

obj-m += test_correct_srcu.o
obj-m += test_incorrect_srcu_1.o

all:
	 make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	 make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

