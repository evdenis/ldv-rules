#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/version.h>

MODULE_LICENSE( "GPL" );


void __init
test( void )
{
}
EXPORT_SYMBOL( test );


static int __init
mod_init( void )
{
   test();
   return 0;
}

static void __exit
mod_exit( void )
{
}

module_init( mod_init );
module_exit( mod_exit );

