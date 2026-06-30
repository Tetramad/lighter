; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .global SYSTICK_init
                ; () -> ()

                .global SYSTICK_get
                ; () -> (systick_L@R12,systick_H@R13)

                .global SYSTICK_delay_ms
                ; (delay_ms@R12) -> ()

                .global SYSTICK_elapse
                ; (current@R12,target@R13) -> ()
                ; current and target are shh:mm.q format

delay:          .macro  millis
                mov.w   :millis:,R12
                call    #SYSTICK_delay_ms
                .endm
