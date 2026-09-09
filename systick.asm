; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "math.inc"
                .include "systick.inc"
                .include "timer1_b3.inc"

                .bss    systick,4,2

                .text
                .def    SYSTICK_init
SYSTICK_init:
; () -> ()
                .asmfunc
                ; TODO: VLOCLK has 50% range in spec.? why?
                mov.w   #(1000/125),&RTCMOD
                mov.w   &RTCIV,R3
                mov.w   #RTCSS__VLOCLK|RTCPS__1|RTCSR_1|RTCIE_0,&RTCCTL

                clr.w   &systick+0
                clr.w   &systick+2

                bis.w   #RTCIE,&RTCCTL

                call    #TIMER1_B3_init
                ret
                .endasmfunc

                .text
                .def    SYSTICK_get
SYSTICK_get:
; () -> (systick_l@R12,systick_h@R13)
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
                .asmfunc
                call    #TIMER1_B3_delay_ms
                ret
                .endasmfunc

                .text
                .def    SYSTICK_elapse
SYSTICK_elapse:
; (delay_quaters@R12) -> ()
                .asmfunc
                push.w  R12
                tst.w   0(SP)
                jz      done?
loop?:
                delay   #15000
                dec.w   0(SP)
                tst.w   0(SP)
                jnz     loop?
done?:
                pop.w   R3
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
