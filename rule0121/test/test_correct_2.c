#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/version.h>

#include <linux/interrupt.h>

MODULE_LICENSE( "GPL" );

static irqreturn_t
dummy_irq_prehandler( int irq, void *dev_id )
{
   return IRQ_WAKE_THREAD;
}

static irqreturn_t
dummy_irq_handler( int irq, void *dev_id )
{
   return IRQ_HANDLED;
}

int irq;

static int __init
mod_init( void )
{
   int r = 0;
   
   for_each_irq_nr( irq ) {
      r = request_threaded_irq( irq, dummy_irq_prehandler, dummy_irq_handler, IRQF_SHARED | IRQF_SAMPLE_RANDOM, NULL, NULL );
      if ( r ) {
         const char *reason = NULL;
         
         switch ( r ) {
            case -EBUSY:
               reason = "EBUSY";
               break;
            case -ENOSYS:
               reason = "ENOSYS";
               break;
            case -EINVAL:
               reason = "EINVAL";
               break;
            default:
               reason = "UNKNOWN";
               break;
         }
         pr_info( "IRQ_TEST: IRQ:%d FAIL CODE:%d REASON:%s\n", irq, r, reason );
      } else {
         pr_info( "IRQ_TEST: IRQ:%d SUCCESS\n", irq );
         break;
      }
   }
   
   return 0;
}

static void __exit
mod_exit( void )
{
   free_irq( irq, NULL );
}

module_init( mod_init );
module_exit( mod_exit );

