#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/version.h>

#include <linux/interrupt.h>

MODULE_LICENSE( "GPL" );

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

