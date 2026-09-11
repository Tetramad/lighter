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
                pcall   WATCHDOG_init
                pcall   SYSTICK_init
                pcall   IND_init
                pcall   UIN_init
                pcall   GNSS_wakeup_init
                pcall   GNSS_reset_init
                pcall   LC_power_init
                pcall   eUSCI_B0_init

                bic.w   #LOCKLPM5,&PM5CTL0
                eint

                br      #main

                .text
main:
                pcall   DT_store,#DT_LOG_RESETREASON,&SYSRSTIV ; -> (error@R12)
                pcall   DT_load,#DT_LOG_RESETREASON ; -> (error@R12,value@R13)
                cmp.w   #SYSRSTIV__WDTIFG,R13
                jne     skip_watchdog_reset_recovery?
                pcall   GNSS_reset
                pcall   SYSTICK_delay_ms,#1000
skip_watchdog_reset_recovery?:

                pcall   GNSS_begin
                pcall   GNSS_end

read_user_configuration?:
                pcall   UIN_begin
                pcall   UIN_read_and_decode ; -> (error@R12)
                tsterr  R12,on_error
                pcall   UIN_end

main_loop?:
walltime_sync?:
                pcall   GNSS_begin
                pcall   GNSS_timesync
                pcall   GNSS_end

wait_next_lighting?:
                .asg    R4,R4$gnssreftick
                .asg    R6,R6$systick

                pcall   GNSS_reftick ; -> (error@R12,reftick@R13)
                tsterr  R12,on_error
                mov.w   R13,R4$gnssreftick
                pcall   SYSTICK_get ; -> (systick@R12)
                mov.w   R12,R6$systick

                pcall   DT_store,#DT_LOG_LATEST_TICK,R6$systick ; -> (error@R12)

                sub.w   R4$gnssreftick,R6$systick

                .unasg  R4$gnssreftick
                .unasg  R6$systick
                .asg    R6,R6$deltatick
                .asg    R5,R5$gnssreftime

                pcall   GNSS_reftime ; -> (error@R12,reftime@R13)
                tsterr  R12,on_error
                mov.w   R13,R5$gnssreftime

                .asg    R4,R4$currenttime

                mov.w   R5$gnssreftime,R12
                add.w   R6$deltatick,R12
                pcall   tick_to_time, ; -> (error@R12,time@R13)
                mov.w   R13,R4$currenttime

                .unasg  R5$gnssreftime
                .unasg  R6$deltatick

                .asg    R5,R5$sunrisetime
                .asg    R6,R6$sunsettime

                pcall   UIN_sunrise ; -> (error@R12,sunrisetime@R13)
                mov.w   R13,R5$sunrisetime
                pcall   UIN_sunset ; -> (error@R12,sunsettime@R13)
                mov.w   R13,R6$sunsettime

                .asg    R5,R5$untilsunrisetick
                .asg    R6,R6$untilsunsettick

                mov.w   R5$sunrisetime,R12
                sub.w   R4$currenttime,R12
                pcall   tick_to_time, ; -> (error@R12,time@R13)
                mov.w   R13,R5$untilsunrisetick
                mov.w   R6$sunsettime,R12
                sub.w   R4$currenttime,R12
                pcall   tick_to_time, ; -> (error@R12,time@R13)
                mov.w   R13,R6$untilsunsettick

                .unasg  R5$sunrisetime
                .unasg  R6$sunsettime

                pcall   DT_store,#DT_LOG_CURRENT_TIME,R4$currenttime ; -> (error@R12)
                pcall   DT_store,#DT_LOG_UNTIL_SUNRISE_TIME,R5$untilsunrisetick ; -> (error@R12)
                pcall   DT_store,#DT_LOG_UNTIL_SUNSET_TIME,R6$untilsunsettick ; -> (error@R12)

                cmp.w   R6$untilsunsettick,R5$untilsunrisetick
                jl      wait_sunrise
                jmp     wait_sunset

wait_sunset:
                pcall   SYSTICK_elapse,R6$untilsunsettick
                jmp     sunset
wait_sunrise:
                pcall   SYSTICK_elapse,R5$untilsunrisetick
                jmp     sunrise

                .unasg  R4$currenttime
                .unasg  R5$untilsunrisetick
                .unasg  R6$untilsunsettick

sunrise:
                pcall   LC_begin,#0,#0
                pcall   LC_transit,#LC_STEP_ON,#LC_STEP_OFF
                pcall   LC_transit,#LC_STEP_OFF,#LC_STEP_ON
                pcall   SYSTICK_delay_ms,#30000
                pcall   LC_end
                jmp     wait_next_lighting?

sunset:
                pcall   LC_begin,#0,#100
                pcall   LC_transit,#LC_STEP_ON,#LC_STEP_OFF
                pcall   LC_transit,#LC_STEP_OFF,#LC_STEP_OFF
                pcall   SYSTICK_delay_ms,#30000
                pcall   LC_end
                jmp     walltime_sync?

on_error:
                dint
                pcall   IND_error
                jmp     hang?

hang?:          jmp     hang?

; Interrupt Vectors
                .sect   RESET_VECTOR
                .word   RESET
                .end
