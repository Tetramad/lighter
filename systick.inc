; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .global SYSTICK_init
                ; () -> ()

                .global SYSTICK_get
                ; () -> (systick@R12)

                .global SYSTICK_delay_ms
                ; (delay_ms@R12) -> ()
                .global SYSTICK_elapse
                ; (delay_quaters@R12) -> ()

                .global SYSTICK_calibration_start
                ; () -> ()
                .global SYSTICK_calibration_stop_and_update
                ; () -> ()

delay:          .macro  millis
; (delay_ms@R12) -> ()
                mov.w   :millis:,R12
                call    #SYSTICK_delay_ms
                .endm
