#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/version.h>
#include <linux/rcupdate.h>

MODULE_LICENSE( "GPL" );

void *test_pointer;

static int __init
mod_init( void )
{
   void *p;
   
   p = rcu_dereference( test_pointer );
  
   return 0;
}

static void __exit
mod_exit( void )
{
}

module_init( mod_init );
module_exit( mod_exit );

