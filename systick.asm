; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "muldivmod.inc"
                .include "systick.inc"

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

                .text
                .def    SYSTICK_elapse
SYSTICK_elapse:
; (current@R12,target@R13) -> ()
; assume(current >= 0, target >= 0)
                .asmfunc
                push.w  R4
                push.w  R5
                push.w  R6

                mov.b   R12,R4
                mov.b   R13,R5
                sub.b   R4,R5
                jc      minute_not_borrow?
                add.b   #11110000b,R5 ; add 60.0 to R5
                add.w   #0000000100000000b,R12
minute_not_borrow?:
                mov.w   R5,R6
                swpb    R12
                mov.b   R12,R4
                swpb    R13
                mov.b   R13,R5

                sub.b   R4,R5
                jc      hour_not_borrow?
                add.b   #00011000b,R15 ; add 24 to R5
hour_not_borrow?:
                ; @R5: 000h hhhh
                ; @R6: mmmm mmqq
                mov.w   R5,R12
                call    #uhimul24
                rla.w   R12
                rla.w   R12
                add.w   R6,R12
                mov.w   R12,R4
                ; @R4: 0000 mmmm mmmm mmqq b

delay_repeat?:
                tst.w   R4
                jz      delay_done?

                delay   #15000

                dec.w   R4
                jmp     delay_repeat?
delay_done?:

                pop.w   R6
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
