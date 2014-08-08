Description of project by Evgeny Novikov.
Original description http://forge.ispras.ru/news/187

Second "Formalization of Correct Usage of Kernel Core API" project developed during Google Summer of Code 2012 was completed.

In [Google Summer of Code 2012](http://www.google-melange.com/gsoc/homepage/google/gsoc2012) Ph.D. student Denis Efremov managed by mentor Alexey Khoroshilov has successfully developed a project titled Formalization of Correct Usage of Kernel Core API for The Linux Foundation.

Denis implemented 12 formal models for safety rules that help him to find a lot of bugs in Linux kernel drivers:
1.  Enabling interrupts while in an interrupt handler (commits [1](http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=186e868786f97c8026f0a81400b451ace306b3a4), acked [2](https://lkml.org/lkml/2012/7/21/5))
2.  might\_sleep functions in interrupt context (found the same results as less general variants of the given rule)
3.  Spinlocks acquisition in process and interrupt contexts (5 suspicious drivers)
4.  local\_irq\_enable/disable and local\_irq\_save/restore order (commits [1](http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=dacae5a19b4cbe1b5e3a86de23ea74cbe9ec9652), [2](http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=f49a59c4471d81a233e09dda45187cc44fda009d))
5.  rcu\_dereference() outside of rcu\_read\_lock/unlock (commits [1](http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=bc78c57388e7f447f58e30d60b1505ddaaaf3a7d), [2](http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=08a16208c8cb2ce1f79fea24f21dd7a8df4f12b6), [3](http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=c03307eab68d583ea6db917681afa14ed1fb3b84), [4](http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=3a7f8c34fefb109903af9a0fac6d0d05f93335c5))
6.  might\_sleep functions with disabled interrupts (7 suspicious drivers)
7.  Inlined functions marked with EXPORT\_SYMBOL (commits [1](http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=e4eda8e0654c19cd7e3d143b051f3d5c213f0b43))
8.  might\_sleep functions in spinlock context (verification results need to be carefully analyzed)
9.  might\_sleep functions in rcu\_read\_lock/unlock (verification results need to be carefully analyzed)
10. Requesting a threaded interrupt without a primary handler and without IRQF\_ONESHOT (needs more accurate driver environment)
11. Initialization functions marked with EXPORT\_SYMBOL (found bugs seems not to be critical)
12. BUG like macros in interrupt context (rule highly depends on user purposes, thus it was rejected)

To develop 5 of these rule models Denis has suggested a new approach of an automatic construction of a Linux kernel core model. This approach is based on a suggestion if some program interface may invoke directly or indirectly some specific program interface (like might\_sleep macro) then it can be marked respectively (e.g. as might\_sleep interface). The approach was implemented in the following way:
1.  Creates list of program interfaces used by some Linux kernel module, in particular by a driver.
2.  Linux kernel source code is analyzed with help of cscope tool.
3.  On the basis of a generated cscope base a call graph containing program interfaces of interest (e.g. might\_sleep macro) is created.
4.  Intersects lists of program interfaces obtained at 1st and 3rd steps. Thus obtains a list of program interfaces that can, say, sleep, and that are used by the module.
5.  Constructs a rule model on the basis of the list obtained at 4th step. For instance, checks a specific context for program interfaces from the given list.

Several rule models were merged to the master branch of the Linux Driver Verification project. To merge other rule models we need to integrate tools developed by Denis with LDV tools.

