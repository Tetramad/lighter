; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "user_input.inc"
                .include "gnss.inc"
                .include "systick.inc"
                .include "light_control.inc"

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

config_SYSTICK:
                call    #SYSTICK_init

config_GPIO:
                mov.w   #00000h,&PADIR
                mov.w   #0C1FFh,&PAOUT
                mov.w   #0C1FFh,&PAREN

                call    #GNSS_wakeup_init
                call    #GNSS_reset_init
                call    #LC_power_init

                bic.b   #BIT0,&P2OUT
                bis.b   #BIT0,&P2DIR
                bic.w   #LOCKLPM5,&PM5CTL0

main:
                eint
                call    #GNSS_reset
                delay   #1000

main_loop:
                call    #GNSS_begin
                call    #GNSS_timesync
                call    #GNSS_end

                call    #LC_begin
                mov.w   #LC_STEP_ON,R12
                mov.w   #LC_STEP_OFF,R13
                call    #LC_transit
                mov.w   #LC_STEP_OFF,R12
                mov.w   #LC_STEP_ON,R13
                call    #LC_transit
                mov.w   #LC_STEP_ON,R12
                mov.w   #LC_STEP_OFF,R13
                call    #LC_transit
                mov.w   #LC_STEP_OFF,R12
                mov.w   #LC_STEP_OFF,R13
                call    #LC_transit
                call    #LC_end

                bis.b   #BIT0,&P2OUT
                delay   #1000
                bic.b   #BIT0,&P2OUT
                delay   #500
                bis.b   #BIT0,&P2OUT
                delay   #1000
                jmp     main_loop

error?:
                dint
                bis.b   #BIT0,&P2OUT
                tst.w   R12
                jge     hang?
                push.w  R12
                bis.b   #BIT0,&P2OUT
                mov.w   #1000,R12
                call    #SYSTICK_delay_ms
                bic.b   #BIT0,&P2OUT
                mov.w   #1000,R12
                call    #SYSTICK_delay_ms
                pop.w   R12
                inc.w   R12
                jmp     error?

hang?:          jmp     hang?

; Interrupt Vectors
                .sect   RESET_VECTOR
                .word   RESET
                .end

main:
                call    #UIN_begin
                call    #UIN_read_and_decode

                call    #UIN_timezone
                tst.w   R12
                jl      error?
                push.w  R13
                mov.w   SP,R12
                mov.w   #2,R13
                mov.w   #PT_INT,R14
                mov.w   #PF_HEX,R15
                call    #eUSCI_A0_transmit
                pop.w   R3

                call    #UIN_sunrise
                tst.w   R12
                jl      error?
                push.w  R13
                mov.w   SP,R12
                mov.w   #2,R13
                mov.w   #PT_INT,R14
                mov.w   #PF_HEX,R15
                call    #eUSCI_A0_transmit
                pop.w   R3

                call    #UIN_sunset
                tst.w   R12
                jl      error?
                push.w  R13
                mov.w   SP,R12
                mov.w   #2,R13
                mov.w   #PT_INT,R14
                mov.w   #PF_HEX,R15
                call    #eUSCI_A0_transmit
                pop.w   R3

                call    #UIN_end

                mov.w   #1000,R12
                call    #SYSTICK_delay_ms

                jmp     main
