; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "math.inc"
                .include "systick.inc"
                .include "timer1_b3.inc"
                .include "datatable.inc"

                .bss    systick,2,2
                .bss    systick_start,2,2
                .bss    counter_start,2,2
                .bss    systick_stop,2,2
                .bss    counter_stop,2,2

                .text
                .def    SYSTICK_init
SYSTICK_init:
; () -> ()
                .asmfunc
                ; TODO: VLOCLK has 50% range in spec.? why?
                mov.w   #15000,&RTCMOD
                mov.w   &RTCIV,R3
                mov.w   #RTCSS__VLOCLK|RTCPS__10|RTCSR_1|RTCIE_0,&RTCCTL

                clr.w   &systick

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
                mov.w   &systick,R12
                clr.w   R13
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

                .text
                .def    SYSTICK_calibration_start
SYSTICK_calibration_start:
; () -> ()
                .asmfunc
                ; NOTE: this function MUST be reentrant until the counterpart called.
                bic.w   #RTCSS|RTCIE,&RTCCTL
                mov.w   &systick,&systick_start
                mov.w   &RTCCNT,&counter_start
                bis.w   #RTCSS__VLOCLK|RTCIE,&RTCCTL
                ret
                .endasmfunc

                .text
                .def    SYSTICK_calibration_stop_and_update
SYSTICK_calibration_stop_and_update:
; () -> ()
                .asmfunc
                ; NOTE: the start function MUST be called before this function called.
                bic.w   #RTCSS|RTCIE,&RTCCTL
                mov.w   &systick,&systick_stop
                mov.w   &RTCCNT,&counter_stop
                bis.w   #RTCSS__VLOCLK|RTCIE,&RTCCTL

                push.w  R4
                push.w  R5

                mov.w   &systick_stop,R4
                sub.w   &systick_start,R4
                ; NOTE: we assume that the systick interval is small.
                clr.w   R5
                tst.w   R4
                jz      skip_mult_loop?
mult_loop?:     add.w   &RTCMOD,R5
                dec.w   R4
                jnz     mult_loop?
skip_mult_loop?:
                mov.w   &counter_stop,R4
                sub.w   &counter_start,R4
                add.w   R5,R4
                mov.w   R4,&RTCMOD

                ; TODO: save the counter start/stop and the RTCMOD value to the datatable
                mov.w   #DT_SYSTICK_RTCMOD,R12
                mov.w   R4,R13
                call    #DT_store

                pop.w   R5
                pop.w   R4
                ret
                .endasmfunc

                .sect   ".text:_isr"
RTC_ISR:
                add.w   &RTCIV,PC
                reti
                inc.w   &systick
                reti

                .sect   RTC_VECTOR
                .word   RTC_ISR
                .end
