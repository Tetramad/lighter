; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "macros.inc"
                .include "user_input.inc"
                .include "gnss.inc"
                .include "systick.inc"
                .include "light_control.inc"
                .include "math.inc"
                .include "indicator.inc"
                .include "datatable.inc"
                .include "watchdog.inc"
                .include "eusci_b.inc"

                .def    RESET

                .global __STACK_END
                .sect   .stack

                .text
                .retain
                .retainrefs
RESET:
                mov.w   #__STACK_END,SP

; Hold watchdog timer
                mov.w   #WDTPW+WDTHOLD,&WDTCTL

; Lock FLL
                bis.w   #SCG0,SR
                mov.w   #SELREF__REFOCLK,&CSCTL3
                bic.w   #SCG0,SR
                waitbic #FLLUNLOCK,&CSCTL7

; Default unused pins
                mov.w   #00000h,&PADIR
                mov.w   #0C1FFh,&PAOUT
                mov.w   #0C1FFh,&PAREN

; Initialization
                call    #WATCHDOG_init
                call    #SYSTICK_init
                call    #IND_init
                call    #UIN_init
                call    #GNSS_wakeup_init
                call    #GNSS_reset_init
                call    #LC_power_init
                call    #eUSCI_B0_init

                bic.w   #LOCKLPM5,&PM5CTL0
                eint

                br      #main

                .text
main:
                mov.w   #DT_LOG_RESETREASON,R12
                mov.w   &SYSRSTIV,R13
                call    #DT_store ; -> (error@R12)
                mov.w   #DT_LOG_RESETREASON,R12
                call    #DT_load ; -> (error@R12,value@R13)
                cmp.w   #SYSRSTIV__WDTIFG,R13
                jne     skip_watchdog_reset_recovery?
                call    #GNSS_reset
                delay   #1000
skip_watchdog_reset_recovery?:

                call    #GNSS_begin
                call    #GNSS_end

read_user_configuration?:
                call    #UIN_begin
                call    #UIN_read_and_decode
                tsterr  R12,on_error
                call    #UIN_end

main_loop?:
walltime_sync?:
                call    #GNSS_begin
                call    #GNSS_timesync
                call    #GNSS_end

wait_next_lighting?:
                ; tick_delta = tick_sys - tick_gnss
                ; quater_delta = tick_delta / TICK_PER_QUATER
                ; -- TICK_PER_QUATER = 1
                ; quater_delta = quater_delta % QUATER_PER_DAY
                ; -time in symbol -> Quater-minutes
                .asg    R4,R4$gnssreftick
                .asg    R6,R6$systick

                call    #GNSS_reftick ; -> (error@R12,gnsstick@R13)
                tsterr  R12,on_error
                mov.w   R13,R4$gnssreftick
                call    #SYSTICK_get ; -> (systick@R12)
                mov.w   R12,R6$systick

                mov.w   #DT_LOG_LATEST_TICK,R12
                mov.w   R6$systick,R13
                call    #DT_store

                sub.w   R4$gnssreftick,R6$systick

                .unasg  R4$gnssreftick
                .unasg  R6$systick
                .asg    R6,R6$deltatime
                .asg    R5,R5$gnssreftime

                call    #GNSS_reftime ; -> (error@R12,quaters@R13)
                tsterr  R12,on_error
                mov.w   R13,R5$gnssreftime

                .asg    R4,R4$currenttime

                mov.w   R5$gnssreftime,R12
                add.w   R6$deltatime,R12
                call    #quaters_unsigned ; -> (error@R12,quaters_unsigned@R13)
                mov.w   R13,R4$currenttime

                .unasg  R5$gnssreftime
                .unasg  R6$deltatime

                .asg    R5,R5$sunrisetime
                .asg    R6,R6$sunsettime

                call    #UIN_sunrise
                mov.w   R13,R5$sunrisetime
                call    #UIN_sunset
                mov.w   R13,R6$sunsettime

                .asg    R5,R5$untilsunrisetick
                .asg    R6,R6$untilsunsettick

                mov.w   R5$sunrisetime,R12
                sub.w   R4$currenttime,R12
                call    #quaters_unsigned ; -> (error@R12,quaters_unsigned@R13)
                mov.w   R13,R5$untilsunrisetick
                mov.w   R6$sunsettime,R12
                sub.w   R4$currenttime,R12
                call    #quaters_unsigned ; -> (error@R12,quaters_unsigned@R13)
                mov.w   R13,R6$untilsunsettick

                .unasg  R5$sunrisetime
                .unasg  R6$sunsettime

                mov.w   #DT_LOG_CURRENT_TIME,R12
                mov.w   R4$currenttime,R13
                call    #DT_store
                mov.w   #DT_LOG_UNTIL_SUNRISE_TIME,R12
                mov.w   R5$untilsunrisetick,R13
                call    #DT_store
                mov.w   #DT_LOG_UNTIL_SUNSET_TIME,R12
                mov.w   R6$untilsunsettick,R13
                call    #DT_store

                cmp.w   R6$untilsunsettick,R5$untilsunrisetick
                jl      wait_sunrise
                jmp     wait_sunset

wait_sunset:
                mov.w   R6$untilsunsettick,R12
                call    #SYSTICK_elapse
                jmp     sunset
wait_sunrise:
                mov.w   R5$untilsunrisetick,R12
                call    #SYSTICK_elapse
                jmp     sunrise

                .unasg  R4$currenttime
                .unasg  R5$untilsunrisetick
                .unasg  R6$untilsunsettick

sunrise:
                mov.w   #0,R12
                mov.w   #0,R13
                call    #LC_begin
                mov.w   #LC_STEP_ON,R12
                mov.w   #LC_STEP_OFF,R13
                call    #LC_transit
                mov.w   #LC_STEP_OFF,R12
                mov.w   #LC_STEP_ON,R13
                call    #LC_transit
                delay   #30000
                call    #LC_end
                jmp     wait_next_lighting?

sunset:
                mov.w   #0,R12
                mov.w   #100,R13
                call    #LC_begin
                mov.w   #LC_STEP_ON,R12
                mov.w   #LC_STEP_OFF,R13
                call    #LC_transit
                mov.w   #LC_STEP_OFF,R12
                mov.w   #LC_STEP_OFF,R13
                call    #LC_transit
                delay   #30000
                call    #LC_end
                jmp     walltime_sync?

on_error:
                dint
                call    #IND_error
                jmp     hang?

hang?:          jmp     hang?

; Interrupt Vectors
                .sect   RESET_VECTOR
                .word   RESET
                .end
