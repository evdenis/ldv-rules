#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/version.h>

MODULE_LICENSE( "GPL" );

static int __init
mod_init( void )
{
   unsigned long flags;
   
   local_irq_save( flags );
      local_irq_disable();
      local_irq_enable();
   local_irq_restore( flags );
  
   return 0;
}

static void __exit
mod_exit( void )
{
}

module_init( mod_init );
module_exit( mod_exit );

