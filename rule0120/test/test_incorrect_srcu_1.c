#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/version.h>
#include <linux/srcu.h>

MODULE_LICENSE( "GPL" );

void *test_pointer;

static int __init
mod_init( void )
{
   void *p;
   struct srcu_struct *sp = sp;
   
   p = srcu_dereference( test_pointer, sp );
  
   return 0;
}

static void __exit
mod_exit( void )
{
}

module_init( mod_init );
module_exit( mod_exit );

