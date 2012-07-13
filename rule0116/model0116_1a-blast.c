#include <linux/kernel.h>
#include <linux/spinlock.h>

extern int ldv_spinlock_in_process_flag_TEMPLATE;
extern int ldv_spinlock_in_interrupt_flag_TEMPLATE;

int ldv_spinlock_in_process_flag_TEMPLATE = 0;
int ldv_spinlock_in_interrupt_flag_TEMPLATE = 0;


static inline void spin_lock_TEMPLATE( spinlock_t *lock )
{
   if ( LDV_IN_INTERRUPT == 2 ) {
      ++ldv_spinlock_in_interrupt_flag_TEMPLATE;
   } else if ( LDV_IN_INTERRUPT == 1 ) {
      ++ldv_spinlock_in_process_flag_TEMPLATE;
   }
   ldv_assert( ldv_spinlock_in_interrupt_flag_TEMPLATE && ldv_spinlock_in_process_flag_TEMPLATE  );
}

void ldv_init_TEMPLATE( void )
{
   ldv_spinlock_in_process_flag_TEMPLATE = 0;
   ldv_spinlock_in_interrupt_flag_TEMPLATE = 0;
}

