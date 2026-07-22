; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "main.inc"
                .include "user_input.inc"
                .include "gnss.inc"
                .include "systick.inc"
                .include "light_control.inc"
                .include "math.inc"
                .include "indicator.inc"

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
                ; TODO:
                ; assume(GNSS_reftick() <= SYSTICK_get())
                ; which false after wrap-around
                call    #GNSS_reftick ; -> (error@R12,tick_l@R13,tick_h@R14)
                tsterr  R12,on_error
                mov.w   R13,R4 ; tick_l@R4
                mov.w   R14,R5 ; tick_h@R5
                call    #SYSTICK_get ; -> (systick_l@R12,systick_h@R13)
                mov.w   R12,R6 ; systick_l@R6
                mov.w   R13,R7 ; systick_h@R7
                ulisub  R4,R5,R6,R7 ; delta_ms@[R7:R6]
                mov.w   R6,R12
                mov.w   R7,R13
                call    #ulidiv1000 ; seconds @[R13:R12]
                call    #ss_to_shhmmq ; (ss@[R13:R12]) -> (error@R12,shhmmq@R13)
                mov.w   R13,R4 ; delta_shhmmq@R4

                call    #GNSS_second
                mov.w   R13,R10 ; gnss_seconds@R10
                call    #GNSS_minute
                mov.w   R13,R9 ; gnss_minutes@R9
                call    #GNSS_hour
                mov.w   R13,R8 ; gnss_hours@R8
                mov.w   R8,R12
                mov.w   R9,R13
                mov.w   R10,R14
                call    #hhmmss_to_shhmmq ; -> (error@R12,shhmmq@R13)
                tsterr  R12,on_error
                mov.w   R13,R5 ; gnss_shhmmq@R5

                ; delta_shhmmq@R4
                ; gnss_shhmmq@R5

                mov.w   R4,R12
                mov.w   R5,R13
                call    #shhmmq_add ; (rhs@R12,lhs@R13) -> (error@R12,result@R13)
                tsterr  R12,on_error
                mov.w   R13,R4 ; result_shhmmq@R4

                call    #UIN_sunrise
                mov.w   R13,R5
                call    #UIN_sunset
                mov.w   R13,R6
                ; @R4: current
                ; @R5: sunrise
                ; @R6: sunset

                clr.w   R7
                cmp.w   R5,R4
                rlc.w   R7 ; C if R4 >= R5
                cmp.w   R6,R5
                rlc.w   R7 ; C if R5 >= R6
                cmp.w   R6,R4
                rlc.w   R7 ; C if R4 >= R6
                ; R7 00000000 00000111
                ;                  ||`- R4 >= R6
                ;                  |`- R5 >= R6
                ;                  `- R4 >= R5
                ; full permutation       R7(2:0)
                ;   sunset sunrise current (111)-> sunset
                ;   sunrise current sunset (100)-> sunset
                ;   current sunset sunrise (010)-> sunset
                ;   sunrise sunset current (101)-> sunrise
                ;   sunset current sunrise (011)-> sunrise
                ;   current sunrise sunset (000)-> sunrise

                cmp.w   #111b,R7
                jz      wait_sunset
                cmp.w   #100b,R7
                jz      wait_sunset
                cmp.w   #010b,R7
                jz      wait_sunset
                cmp.w   #101b,R7
                jz      wait_sunrise
                cmp.w   #011b,R7
                jz      wait_sunrise
                cmp.w   #000b,R7
                jz      wait_sunrise
                jmp     on_error

wait_sunset:
                mov.w   R4,R12
                mov.w   R6,R13
                call    #SYSTICK_elapse
                jmp     sunset
wait_sunrise:
                mov.w   R4,R12
                mov.w   R5,R13
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
