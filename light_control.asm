; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "systick.inc"

                .text
                .def    LC_begin
LC_begin:
; () -> ()
                .asmfunc
                bic.w   #MC,&TB0CTL
                bis.w   #TBCLR,&TB0CTL
                mov.w   #TBCLGRP_0|CNTL__16|TBSSEL__SMCLK|ID__1|MC__STOP|TBIE_0|TBIFG_0,&TB0CTL
                mov.w   #99,&TB0CCR0
                mov.w   #0,&TB0CCR1
                mov.w   #CLLD_1|OUTMOD_7,&TB0CCTL1
                mov.w   #100,&TB0CCR2
                mov.w   #CLLD_1|OUTMOD_3,&TB0CCTL2

                bic.b   #BIT6|BIT7,&P1REN
                bis.b   #BIT6|BIT7,&P1DIR
                bis.b   #BIT6|BIT7,&P1SEL1
                bis.w   #MC__UP,&TB0CTL

                bis.b   #BIT1,&P1OUT
                ret
                .endasmfunc

                .text
                .def    LC_end
LC_end:
; () -> ()
                .asmfunc
                bic.b   #BIT1,&P1OUT

                bic.w   #MC,&TB0CTL
                bic.b   #BIT6|BIT7,&P1SEL1
                bic.b   #BIT6|BIT7,&P1DIR
                bis.b   #BIT6|BIT7,&P1REN

                ret
                .endasmfunc

                .text
                .def    LC_transit
LC_transit:
; (warm_step@R12,cold_step@R13) -> (error@R12)
                .asmfunc
                push.w  R4
                push.w  R5
                push.w  R6

                mov.w   R12,R5
                mov.w   R13,R6
                inv.w   R6

stepping?:      clr.w   R4
                tst.w   R5
                jn      warm_downward?
warm_upward?:   cmp.w   #100,&TB0CCR1
                jc      warm_stepping_complete?
                inc.w   &TB0CCR1
                bis.w   #BIT0,R4
                jmp     warm_stepping_complete?
warm_downward?: cmp.w   #1,&TB0CCR1
                jnc     warm_stepping_complete?
                dec.w   &TB0CCR1
                bis.w   #BIT0,R4
                jmp     warm_stepping_complete?
warm_stepping_complete?:

                tst.w   R6
                jn      cold_downward?
cold_upward?:   cmp.w   #100,&TB0CCR2
                jc      cold_stepping_complete?
                inc.w   &TB0CCR2
                bis.w   #BIT0,R4
                jmp     cold_stepping_complete?
cold_downward?: cmp.w   #1,&TB0CCR2
                jnc     cold_stepping_complete?
                dec.w   &TB0CCR2
                bis.w   #BIT0,R4
                jmp     cold_stepping_complete?
cold_stepping_complete?:

                delay   #100
                tst.w   R4
                jnz     stepping?

                mov.w   #0,R12
                pop.w   R6
                pop.w   R5
                pop.w   R4
                ret

error?:         mov.w   #-1,R12
                pop.w   R6
                pop.w   R5
                pop.w   R4
                ret
                .endasmfunc

                .text
                .def    LC_power_init
LC_power_init:
; () -> ()
                .asmfunc
                bic.b   #BIT1,&P1REN
                bic.b   #BIT1,&P1OUT
                bis.b   #BIT1,&P1DIR
                ret
                .endasmfunc
