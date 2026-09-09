; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "indicator.inc"

                .bss    tick,2,2

                .text
                .def    TIMER1_B3_init
TIMER1_B3_init:
; () -> ()
                .asmfunc
                mov.w   #TBCLGRP_0+CNTL__16+TBSSEL__SMCLK+ID__1+MC__STOP+TBCLR+TBIE_0,&TB1CTL
                mov.w   #TBIDEX_0,&TB1EX0
                mov.w   #1048576/1000,TB1CCR0
                mov.w   #CM__NONE+CCIS__CCIA+SCS__ASYNC+CLLD_1+CAP__COMPARE+OUTMOD_0+CCIE_0+OUT_0,&TB1CCTL0
                ret
                .endasmfunc

                .text
                .def    TIMER1_B3_delay_ms
TIMER1_B3_delay_ms:
; (millis@R12) -> ()
                .asmfunc
                mov.w   R12,&tick
                bis.w   #CCIE,&TB1CCTL0
                add.w   #MC__UP+TBCLR,&TB1CTL
wait_tick?:     tst.w   &tick
                jnz     wait_tick?
                ret
                .endasmfunc

                .sect   ".text:_isr"
TIMER1_B0_ISR:
                .asmfunc
                xor.w   #1,TB1CCR0
                dec.w   &tick
                jz      stop_timer?
                reti
stop_timer?:
                bic.w   #MC,&TB1CTL
                bic.w   #CCIE|CCIFG,&TB1CCTL0
                reti
                .endasmfunc

                .sect   TIMER1_B0_VECTOR
                .word   TIMER1_B0_ISR
                .end
