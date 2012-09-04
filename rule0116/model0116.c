#include <ldv.h>

#include <linux/kernel.h>
#include <linux/spinlock.h>

extern int LDV_IN_INTERRUPT;

extern int ldv_lock_in_process_flag_TEMPLATE;
extern int ldv_lock_in_interrupt_flag_TEMPLATE;

/* LDV_COMMENT_MODEL_STATE Indicates the usage of lock in process context with enabled interrupts.*/
int ldv_lock_in_process_flag_TEMPLATE = 0;
/* LDV_COMMENT_MODEL_STATE Indicates the usage of lock in interrupt context.*/
int ldv_lock_in_interrupt_flag_TEMPLATE = 0;

/* LDV_COMMENT_MODEL_STATE Indicates whether interrupts disabled or enabled.*/
int ldv_irq_disable_nesting = 0;

#define __ldv_lock_in_interrupt()                                              \
   do {                                                                        \
      if ( LDV_IN_INTERRUPT == 2 ) {                                           \
         /* LDV_COMMENT_CHANGE_STATE usage of the lock in interrupt context.*/ \
         ++ldv_lock_in_interrupt_flag_TEMPLATE;                                \
      }                                                                        \
   } while(0)

#define __ldv_lock_in_process()                                               \
   do {                                                                       \
      if ( ( LDV_IN_INTERRUPT == 1 ) && ( ldv_irq_disable_nesting <= 0 ) ) {  \
         /* LDV_COMMENT_CHANGE_STATE usage of the lock in process context.*/  \
         ++ldv_lock_in_process_flag_TEMPLATE;                                 \
      }                                                                       \
   } while(0)

/* LDV_COMMENT_MODEL_FUNCTION_DEFINITION(name='ldv_check_final_state') Checks for usage of the same lock in different contexts.*/
void ldv_check_final_state_TEMPLATE(void)
{
   /* LDV_COMMENT_ASSERT If you use same lock in interrupt context (e.g. interrupt handler) and in process context, then in the latter case interrupts (maybe just one line) should be disabled.*/
   ldv_assert( ( ldv_lock_in_interrupt_flag_TEMPLATE == 0 ) ||  ( ldv_lock_in_process_flag_TEMPLATE == 0 ) );
}

/* LDV_COMMENT_MODEL_FUNCTION_DEFINITION(name='ldv_spin_lock') Checks the context, increments the counter.*/
void ldv_spin_lock_TEMPLATE(spinlock_t *lock)
{
   __ldv_lock_in_interrupt();
   __ldv_lock_in_process();
}

/* LDV_COMMENT_MODEL_FUNCTION_DEFINITION(name='ldv_spin_lock_bh') Checks the context, increments the counter.*/
void ldv_spin_lock_bh_TEMPLATE(spinlock_t *lock)
{
   __ldv_lock_in_interrupt();
   __ldv_lock_in_process();
}

/* LDV_COMMENT_MODEL_FUNCTION_DEFINITION(name='ldv_spin_lock_irq') Increments the counter only in interrupt context.*/
void ldv_spin_lock_irq_TEMPLATE(spinlock_t *lock)
{
   __ldv_lock_in_interrupt();
}

/* LDV_COMMENT_MODEL_FUNCTION_DEFINITION(name='ldv_spin_lock_irqsave') Increments the counter only in interrupt context.*/
void ldv_spin_lock_irqsave_TEMPLATE(spinlock_t *lock, unsigned long flags)
{
   __ldv_lock_in_interrupt();
}

/* LDV_COMMENT_MODEL_FUNCTION_DEFINITION(name='ldv_local_irq_disable') Increments the level of irq_disable nesting.*/
void ldv_local_irq_disable(void)
{
   ++ldv_irq_disable_nesting;
}

/* LDV_COMMENT_MODEL_FUNCTION_DEFINITION(name='ldv_local_irq_enable') Decrements the level of irq_disable nesting.*/
void ldv_local_irq_enable(void)
{
   --ldv_irq_disable_nesting;
}

/* LDV_COMMENT_MODEL_FUNCTION_DEFINITION(name='ldv_local_irq_save') Increments the level of irq_disable nesting.*/
void ldv_local_irq_save(void)
{
   ++ldv_irq_disable_nesting;
}

/* LDV_COMMENT_MODEL_FUNCTION_DEFINITION(name='ldv_local_irq_restore') Decrements the level of irq_disable nesting.*/
void ldv_local_irq_restore(void)
{
   --ldv_irq_disable_nesting;
}

/* LDV_COMMENT_MODEL_FUNCTION_DEFINITION(name='ldv_initialize') Initialization of lock variables.*/
void ldv_initialize_TEMPLATE(void)
{
   ldv_lock_in_process_flag_TEMPLATE = 0;
   ldv_lock_in_interrupt_flag_TEMPLATE = 0;
}


