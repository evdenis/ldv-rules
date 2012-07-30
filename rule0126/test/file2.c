#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>

#include "generate.h"

odecl(static, s_test2)

func(static, s_test2)
ifunc(inline, i_test2)
ifunc(static inline, si_test2)

