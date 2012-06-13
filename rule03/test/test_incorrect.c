#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/version.h>

#include <linux/interrupt.h>
#include <linux/spinlock.h>

MODULE_LICENSE( "GPL" );

static DEFINE_SPINLOCK(lock);

static irqreturn_t
dummy_irq_handler1( int irq, void *dev_id )
{
   ulong flags;
   spin_lock_irqsave( &lock, flags );
   spin_unlock_irqrestore( &lock, flags );
   return IRQ_HANDLED;
}

static irqreturn_t
dummy_irq_handler2( int irq, void *dev_id )
{
   ulong flags;
   spin_lock_irqsave( &lock, flags );
   spin_unlock_irqrestore( &lock, flags );
   return IRQ_HANDLED;
}

#if LINUX_VERSION_CODE < KERNEL_VERSION( 2, 6, 36 )
static void noop( uint irq )
{
}

static uint noop_ret( uint irq )
{
   return 0;
}

struct irq_chip tst_irq_chip = {
   .name         = "tst_dummy",
   .startup      = noop_ret,
   .shutdown      = noop,
   .enable         = noop,
   .disable      = noop,
   
   .ack         = noop,
   .mask         = noop,
   .mask_ack      = noop,
   .unmask         = noop,
   .eoi         = noop,
   
   .end         = noop,
   //.set_affinity   = noop,
   //.retrigger      = noop,
   //.set_type       = noop,
   //.set_wake       = noop,
};
#else
static void noop( struct irq_data *data )
{
}

static uint noop_ret( struct irq_data *data )
{
   return 0;
}

struct irq_chip tst_irq_chip = {
   .name         = "tst_dummy",
   .irq_startup      = noop_ret,
   .irq_shutdown      = noop,
   .irq_enable         = noop,
   .irq_disable      = noop,
   
   .irq_ack         = noop,
   .irq_mask         = noop,
   .irq_unmask         = noop,
   
   //.irq_end         = noop,
   //.set_affinity   = noop,
   //.retrigger      = noop,
   //.set_type       = noop,
   //.set_wake       = noop,
};

#define set_irq_chip irq_set_chip

#endif

int irq1;
int irq2;

static int __init
mod_init( void )
{
   int irq;
   int r = 0;
   int status = false;
   irq_handler_t func = dummy_irq_handler1;
   // SA_INTERRUPT flags
   pr_info( "================================================================================\n" );
   for_each_irq_nr( irq ) {
      r = request_irq( irq, func, 0, NULL, NULL );
      if ( -ENOSYS == r ) {
         set_irq_chip( irq, &tst_irq_chip );
         r = request_irq( irq, func, 0, 0, 0 );
      }
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
	 if ( !status ) {
            func = dummy_irq_handler2;
	    status = true;
	 } else {
            break;
	 }
      }
   }
   pr_info( "================================================================================\n" );
   
   return 0;
}

static void __exit
mod_exit( void )
{
   if ( irq1 ) {
      set_irq_chip( irq1, NULL );
      free_irq( irq1, NULL );
   }
   if ( irq2 ) {
      set_irq_chip( irq2, NULL );
      free_irq( irq2, NULL );
   }
}

module_init( mod_init );
module_exit( mod_exit );

