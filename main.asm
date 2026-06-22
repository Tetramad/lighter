; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "eusci_a.inc"
                .include "sleep.inc"
                .include "adc.inc"

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

config_eUSCI_A0:
                call    #eUSCI_A0_init

config_ADC:
                call    #ADC_init

config_GPIO:
                bic.b   #BIT0,&P2OUT
                bis.b   #BIT0,&P2DIR
                bic.w   #LOCKLPM5,&PM5CTL0

main:
                call    #ADC_fetch

                mov.w   #adc_result_A0,R12
                mov.w   #2,R13
                mov.w   #PT_INT,R14
                mov.w   #PF_HEX,R15
                call    #eUSCI_A0_transmit

                mov.w   #adc_result_A4,R12
                mov.w   #2,R13
                mov.w   #PT_INT,R14
                mov.w   #PF_HEX,R15
                call    #eUSCI_A0_transmit

                mov.w   #adc_result_A5,R12
                mov.w   #2,R13
                mov.w   #PT_INT,R14
                mov.w   #PF_HEX,R15
                call    #eUSCI_A0_transmit

                mov.w   #1000,R12
                call    #RTC_sleep_ms

                jmp     main

error?:
                bis.b   #BIT0,&P2OUT
                tst.w   R12
                jge     hang?
                push.w  R12
                bis.b   #BIT0,&P2OUT
                mov.w   #1000,R12
                call    #RTC_sleep_ms
                bic.b   #BIT0,&P2OUT
                mov.w   #1000,R12
                call    #RTC_sleep_ms
                pop.w   R12
                inc.w   R12
                jmp     error?

hang?:          jmp     hang?

; Interrupt Vectors
                .sect   RESET_VECTOR
                .word   RESET
                .end
