#include <ldv.h>

#include <linux/kernel.h>
#include <linux/spinlock.h>

extern int LDV_IN_INTERRUPT;

extern int ldv_lock_in_process_flag_TEMPLATE;
extern int ldv_lock_in_interrupt_flag_TEMPLATE;

/* LDV_COMMENT_MODEL_STATE*/
int ldv_lock_in_process_flag_TEMPLATE = 0;
/* LDV_COMMENT_MODEL_STATE*/
int ldv_lock_in_interrupt_flag_TEMPLATE = 0;

/* LDV_COMMENT_MODEL_STATE*/
int ldv_irq_disable_nesting = 0;

#define __ldv_lock_in_interrupt()               \
   do {                                         \
      if ( LDV_IN_INTERRUPT == 2 ) {            \
         ++ldv_lock_in_interrupt_flag_TEMPLATE; \
      }                                         \
   } while(0)

#define __ldv_lock_in_process()                                               \
   do {                                                                       \
      if ( ( LDV_IN_INTERRUPT == 1 ) && ( ldv_irq_disable_nesting <= 0 ) ) {  \
         ++ldv_lock_in_process_flag_TEMPLATE;                                 \
      }                                                                       \
   } while(0)

/* LDV_COMMENT_MODEL_FUNCTION_DEFINITION(name='ldv_check_final_state') */
void ldv_check_final_state_TEMPLATE(void)
{
   /* LDV_COMMENT_ASSERT*/
   ldv_assert( ( ldv_lock_in_interrupt_flag_TEMPLATE == 0 ) ||  ( ldv_lock_in_process_flag_TEMPLATE == 0 ) );
}

void ldv_spin_lock_TEMPLATE(spinlock_t *lock)
{
   __ldv_lock_in_interrupt();
   __ldv_lock_in_process();
}

void ldv_spin_lock_bh_TEMPLATE(spinlock_t *lock)
{
   __ldv_lock_in_interrupt();
   __ldv_lock_in_process();
}

void ldv_spin_lock_irq_TEMPLATE(spinlock_t *lock)
{
   __ldv_lock_in_interrupt();
}

void ldv_spin_lock_irqsave_TEMPLATE(spinlock_t *lock, unsigned long flags)
{
   __ldv_lock_in_interrupt();
}

void ldv_local_irq_disable( void )
{
   ++ldv_irq_disable_nesting;
}

void ldv_local_irq_enable( void )
{
   --ldv_irq_disable_nesting;
}

void ldv_local_irq_save( void )
{
   ++ldv_irq_disable_nesting;
}

void ldv_local_irq_restore( void )
{
   --ldv_irq_disable_nesting;
}

/* LDV_COMMENT_MODEL_FUNCTION_DEFINITION(name='ldv_initialize') Initialize lock variables*/
void ldv_initialize_TEMPLATE(void)
{
   ldv_lock_in_process_flag_TEMPLATE = 0;
   ldv_lock_in_interrupt_flag_TEMPLATE = 0;
}


