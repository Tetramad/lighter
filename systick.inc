; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .global SYSTICK_init
                ; () -> ()

                .global SYSTICK_get
                ; () -> (systick_L@R12,systick_H@R13)

                .global SYSTICK_delay_ms
                ; (delay_ms@R12) -> ()
