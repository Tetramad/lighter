; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"

; P1.6 WARM
; P1.7 COLD

                .text
                .def Timer_B0_init
Timer_B0_init:  .asmfunc
                bic.w   #MC,&TB0CTL
                bis.w   #TBCLR,&TB0CTL
                mov.w   #TBCLGRP_1|CNTL__16|TBSSEL__SMCLK|ID__1|MC__STOP|TBIE_0|TBIFG_0,&TB0CTL
                mov.w   #99,&TB0CCR0
                clr.w   &TB0CCR1
                mov.w   #CLLD_1|OUTMOD_7,&TB0CCTL1
                mov.w   #100,&TB0CCR2
                mov.w   #CLLD_1|OUTMOD_3,&TB0CCTL2
                ret
                .endasmfunc

                .text
                .def Timer_B0_enable_output
Timer_B0_enable_output:
                .asmfunc
                bit.w   #MC,&TB0CTL
                jnz     $0
                bis.b   #BIT6|BIT7,&P1DIR
                bis.b   #BIT6|BIT7,&P1SEL1
                bis.w   #MC__UP,&TB0CTL
$0:
                ret
                .endasmfunc

                .text
                .def Timer_B0_disable_output
Timer_B0_disable_output:
                .asmfunc
                bic.w   #MC,&TB0CTL
                bic.b   #BIT6|BIT7,&P1SEL1
                bic.b   #BIT6|BIT7,&P1DIR
                ret
                .endasmfunc

                .text
                .def Timer_B0_set_duty
Timer_B0_set_duty:
; (warm_duty->R12, cold_duty->R13) -> (error->R12)
; duty in [0, 100]
                .asmfunc
                cmp.w   #101,R12
                jhs     $1

                cmp.w   #101,R13
                jhs     $1

                clrc
                rrc.w   R12
                clrc
                rrc.w   R13

                ; 0~47 48 49  50
                ; 0~47 50 75 100
                cmp.w   #50,R12
                jhs     S1_50?
                cmp.w   #49,R12
                jhs     S1_49?
                cmp.w   #48,R12
                jhs     S1_48?
                jmp     S1_e?
S1_50?:         mov.w   #100,R12
                jmp     S1_e?
S1_49?:         mov.w   #75,R12
                jmp     S1_e?
S1_48?:         mov.w   #50,R12
                jmp     S1_e?
S1_e?:

                cmp.w   #50,R13
                jhs     S2_50?
                cmp.w   #49,R13
                jhs     S2_49?
                cmp.w   #48,R13
                jhs     S2_48?
                jmp     S2_e?
S2_50?:         mov.w   #100,R13
                jmp     S2_e?
S2_49?:         mov.w   #75,R13
                jmp     S2_e?
S2_48?:         mov.w   #50,R13
                jmp     S2_e?
S2_e?:

                sub.w   #100,R13
                inv.w   R13
                inc.w   R13

                mov.w   R13,&TB0CCR2
                mov.w   R12,&TB0CCR1

                clr.w   R12
                ret
$1:
                mov.w   #-1,R12
                ret
                .endasmfunc
