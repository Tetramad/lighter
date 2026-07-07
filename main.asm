; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "user_input.inc"
                .include "gnss.inc"
                .include "systick.inc"
                .include "light_control.inc"
                .include "muldivmod.inc"
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
                tst.w   R12
                jn      error?
                call    #UIN_end

main_loop:
walltime_sync:
                call    #GNSS_begin
                call    #GNSS_timesync
                call    #GNSS_end

wait_next_lighting:
                call    #GNSS_reftick
                tst.w   R12
                jn      error?
                push.w  R13
                push.w  R14
                call    #SYSTICK_get
                pop.w   R15
                pop.w   R14
                sub.w   R14,R12
                subc.w  R15,R13 ; delta(t) in milliseconds @[R13:R12]
                call    #ulidiv1000 ; seconds @[R13:R12]
                call    #ulidivmod60 ; minutes @[R13:R12], seconds @[R14]
                push.w  R14
                call    #ulidivmod60 ; hours @[R13:R12], minutes @[R14]
                push.w  R14
                push.w  R13
                push.w  R12
                call    #GNSS_second
                push.w  R13
                call    #GNSS_minute
                push.w  R13
                call    #GNSS_hour
                mov.w   R13,R12 ; GNSS_hour
                pop.w   R13     ; GNSS_minute
                pop.w   R14     ; GNSS_second
                pop.w   R4      ; hour_l
                pop.w   R5      ; hour_h
                pop.w   R6      ; minute
                pop.w   R7      ; second

                add.w   R14,R7
                cmp.w   #60,R7
                jnc     second_borrow?
                sub.w   #60,R7
                inc.w   R13
second_borrow?:
                add.w   R13,R6
                cmp.w   #60,R6
                jnc     minute_borrow?
                sub.w   #60,R6
                inc.w   R12
minute_borrow?:
                add.w   R12,R4
                adc.w   R5

                mov.w   R4,R12
                mov.w   R5,R13
                call    #ulidivmod24 ; qout @[R13:R12], hours @[R14]
                mov.w   R14,R5
                ; @R5: hour
                ; @R6: minute
                ; @R7: second
                and.w   #0000000000011111b,R5
                .loop 8
                rla.w   R5
                .endloop
                mov.w   R5,R4
                and.w   #0000000000111111b,R6
                .loop 2
                rla.w   R6
                .endloop
                add.w   R6,R4
                cmp.w   #45,R7
                jc      quater_3
                cmp.w   #30,R7
                jc      quater_2
                cmp.w   #15,R7
                jc      quater_1
                jmp     quater_0

                ; [0,15),[15,30),[30,45),[45,60)
                ; 00     01      10      11
quater_3:       inc.w   R4
quater_2:       inc.w   R4
quater_1:       inc.w   R4
quater_0:

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
                jmp     error?

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
                jmp     wait_next_lighting

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
                jmp     walltime_sync

error?:
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
