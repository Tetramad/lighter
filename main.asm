; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "light_control.inc"
                .include "sleep.inc"

                .def    RESET

                .global __STACK_END
                .sect   .stack

                .text
                .retain
                .retainrefs

RESET:          mov.w   #__STACK_END,SP
stop_watchdog:  mov.w   #WDTPW+WDTHOLD,&WDTCTL

                bis.w   #SCG0,SR
                mov.w   #SELREF__REFOCLK,&CSCTL3
                bic.w   #SCG0,SR

FLL_LOCK:       bit.w   #FLLUNLOCK,&CSCTL7
                jnz     FLL_LOCK

config_GPIO:
                bic.b   #BIT0,&P2OUT
                bis.b   #BIT0,&P2DIR
                bic.w   #LOCKLPM5,&PM5CTL0

main:
                call    #LCNTL_init
                mov.w   #200,R12
                mov.w   #1,R13
                mov.w   #100,R14
                call    #LCNTL_transition
                mov.w   #0,R12
                mov.w   #-1,R13
                mov.w   #100,R14
                call    #LCNTL_transition
                call    #LCNTL_deinit
                mov.w   #15,R12
                call    #RTC_sleep_s
                jmp     main

error?:
                push.w  R12
                bis.b   #BIT0,&P2OUT
                mov.w   #1000,R12
                call    #RTC_sleep_ms
                bic.b   #BIT0,&P2OUT
                mov.w   #1000,R12
                call    #RTC_sleep_ms
                pop.w   R12
                inc.w   R12
                jnz     error?
                bis.b   #BIT0,&P2OUT

hang?:          jmp     hang?

; Interrupt Vectors
                .sect   RESET_VECTOR
                .word   RESET
                .end
