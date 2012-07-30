#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/version.h>

#include "generate.h"

MODULE_LICENSE( "GPL" );

efunc(static, s_test2)
efunc(inline, i_test2)
efunc(static inline, si_test2)

efunc(static, s_test_e)
efunc(inline, i_test_e)
efunc(static inline, si_test_e)

odecl(static, s_test)

func(static, s_test)
ifunc(inline, i_test)
ifunc(static inline, si_test)

static int __init
mod_init( void )
{
   cfunc(s_test)
   cfunc(i_test)
   cfunc(si_test)
   
   cfunc(s_test2)
   cfunc(i_test2)
   cfunc(si_test2)
   
   cfunc(s_test_e)
   cfunc(i_test_e)
   cfunc(si_test_e)
   
   return 0;
}

static void __exit
mod_exit( void )
{
}

module_init( mod_init );
module_exit( mod_exit );

