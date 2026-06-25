; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"

                .bss    systick,4,2

                .text
                .def    SYSTICK_init
SYSTICK_init:
; () -> ()
                .asmfunc
                mov.w   #10,&RTCMOD
                mov.w   &RTCIV,R3
                mov.w   #RTCSS__VLOCLK|RTCPS__1|RTCSR_1|RTCIE_0,&RTCCTL

                clr.w   &systick+0
                clr.w   &systick+2

                bis.w   #RTCIE,&RTCCTL
                ret
                .endasmfunc

                .text
                .def    SYSTICK_get
SYSTICK_get:
; () -> (systick_L@R12,systick_H@R13)
                .asmfunc
                bic.w   #RTCIE,&RTCCTL
                mov.w   &systick+0,R12
                mov.w   &systick+2,R13
                bis.w   #RTCIE,&RTCCTL
                ret
                .endasmfunc

                .text
                .def    SYSTICK_delay_ms
SYSTICK_delay_ms:
; (delay_ms@R12) -> ()
                .asg    R4,start
                .asg    R5,stop
                .asg    R5,diff
                .asmfunc
                push.w  R4
                push.w  R5
                mov.w   &systick+0,R4
$1:             mov.w   &systick+0,R5
                sub.w   R4,R5
                cmp.w   R12,R5
                jnc     $1
                pop.w   R5
                pop.w   R4
                ret
                .endasmfunc

                .sect   ".text:_isr"
RTC_ISR:
                add.w   &RTCIV,PC
                reti
                inc.w   &systick+0
                adc.w   &systick+2
                reti

                .sect   RTC_VECTOR
                .word   RTC_ISR
                .end
