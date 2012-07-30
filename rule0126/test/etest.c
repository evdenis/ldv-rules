#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/version.h>

#include "generate.h"

MODULE_LICENSE( "GPL" );

odecl(static, s_test_e)

func(static, s_test_e)
ifunc(inline, i_test_e)
ifunc(static inline, si_test_e)

static int __init
mod_init( void )
{
   return 0;
}

static void __exit
mod_exit( void )
{
}

module_init( mod_init );
module_exit( mod_exit );

