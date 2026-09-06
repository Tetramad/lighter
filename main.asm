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

wait_fll_lock?: bit.w   #FLLUNLOCK,&CSCTL7
                jnz     wait_fll_lock?

; Default unused pins
                mov.w   #00000h,&PADIR
                mov.w   #0C1FFh,&PAOUT
                mov.w   #0C1FFh,&PAREN

; Initialization
                call    #SYSTICK_init
                call    #IND_init
                call    #UIN_init
                call    #GNSS_wakeup_init
                call    #GNSS_reset_init
                call    #LC_power_init
                call    #eUSCI_B0_init

                bic.w   #LOCKLPM5,&PM5CTL0
                eint

main:
                call    #GNSS_reset
                delay   #1000
                call    #GNSS_begin
                call    #GNSS_end

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
                call    #GNSS_reftick ; -> (error@R12,gnsstick_l@R13,gnsstick_h@R14)
                tsterr  R12,on_error
                mov.w   R13,R4
                .asg    R4,R4$gnsstick_l
                mov.w   R14,R5
                .asg    R5,R5$gnsstick_h
                call    #SYSTICK_get ; -> (systick_l@R12,systick_h@R13)
                mov.w   R12,R6
                .asg    R6,R6$systick_l
                mov.w   R13,R7
                .asg    R7,R7$systick_h
                mov.w   #DT_LOG_LATEST_TICK_L,R12
                mov.w   R6$systick_l,R13
                call    #DT_store
                mov.w   #DT_LOG_LATEST_TICK_H,R12
                mov.w   R7$systick_h,R13
                call    #DT_store
                sub.w   R4$gnsstick_l,R6$systick_l
                .unasg  R4$gnsstick_l
                .unasg  R6$systick_l
                .asg    R6,R6$delta_ms_l
                subc.w  R5$gnsstick_h,R7$systick_h
                .unasg  R5$gnsstick_h
                .unasg  R7$systick_h
                .asg    R7,R7$delta_ms_h
                mov.w   R6$delta_ms_l,R12
                .unasg  R6$delta_ms_l
                mov.w   R7$delta_ms_h,R13
                .unasg  R7$delta_ms_h
                call    #ulidiv1000 ; seconds @[R13:R12]
                call    #ulidivmod15 ; quaters@[R13:R12]
                call    #ulidivmod5760 ; quaters@R14
                mov.w   R14,R4
                .asg    R4,R4$delta_qm

                call    #GNSS_reftime ; -> (error@R12,quaters@R13)
                tsterr  R12,on_error
                mov.w   R13,R5
                .asg    R5,R5$gnss_qm

                mov.w   R5$gnss_qm,R12
                .unasg  R5$gnss_qm
                add.w   R4$delta_qm,R12
                .unasg  R4$delta_qm
                call    #quaters_unsigned ; -> (error@R12,quaters_unsigned@R13)
                mov.w   R13,R4
                .asg    R4,R4$current_qm

                call    #UIN_sunrise
                mov.w   R13,R5
                .asg    R5,R5$sunrise_qm
                call    #UIN_sunset
                mov.w   R13,R6
                .asg    R6,R6$sunset_qm

                mov.w   R5$sunrise_qm,R12
                .unasg  R5$sunrise_qm
                sub.w   R4$current_qm,R12
                call    #quaters_unsigned ; -> (error@R12,quaters_unsigned@R13)
                mov.w   R13,R5
                .asg    R5,R5$till_sunrise_qm
                mov.w   R6$sunset_qm,R12
                .unasg  R6$sunset_qm
                sub.w   R4$current_qm,R12
                call    #quaters_unsigned ; -> (error@R12,quaters_unsigned@R13)
                mov.w   R13,R6
                .asg    R6,R6$till_sunset_qm

                mov.w   #DT_LOG_CURRENT,R12
                mov.w   R4$current_qm,R13
                .unasg  R4$current_qm
                call    #DT_store
                mov.w   #DT_LOG_TILL_SUNRISE,R12
                mov.w   R5$till_sunrise_qm,R13
                call    #DT_store
                mov.w   #DT_LOG_TILL_SUNSET,R12
                mov.w   R6$till_sunset_qm,R13
                call    #DT_store

                cmp.w   R6$till_sunset_qm,R5$till_sunrise_qm
                jl      wait_sunrise
                jmp     wait_sunset

wait_sunset:
                mov.w   R6$till_sunset_qm,R12
                .unasg  R6$till_sunset_qm
                call    #SYSTICK_elapse
                jmp     sunset
wait_sunrise:
                mov.w   R5$till_sunrise_qm,R12
                .unasg  R5$till_sunrise_qm
                call    #SYSTICK_elapse
                jmp     sunrise

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

; PUC -> initialization -> user input check
; -> [walltime sync] wall time synchronization
; -> [wait next] wait next sunrise or sunset
; -> if sunrise [sunrise] if sunset [sunset] --
; [sunrise] light control to show sunrise -> [wait next]
; [sunset]  light control to show sunset -> [walltime sync]
