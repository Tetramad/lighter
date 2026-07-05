; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "systick.inc"

                .asg    0FFFFh,IND_ERROR_HALF_PERIOD
                .asg    100,IND_MORSE_TICK

                .text
                .def    IND_init
IND_init:
; () -> ()
                .asmfunc
                bic.b   #BIT0,&P2REN
                bic.b   #BIT0,&P2OUT
                bic.b   #BIT0,&P2DIR

                ret
                .endasmfunc

                .text
                .def    IND_error
IND_error:
; (error@R12) -> ()
                .asmfunc
                ; assume that global interrupt is disabled.
                push.w  R4

                inv.w   R12
                inc.w   R12
loop?:
                cmp.w   #1,R12
                jn      done?
                bis.b   #BIT0,&P2DIR
                mov.w   #IND_ERROR_HALF_PERIOD,R4
active_delay_loop?:
                tst.w   R4
                jz      active_delay_done?
                dec.w   R4
                jmp     active_delay_loop?
active_delay_done?:
                bic.b   #BIT0,&P2DIR
                mov.w   #IND_ERROR_HALF_PERIOD,R4
deactive_delay_loop?:
                tst.w   R4
                jz      deactive_delay_done?
                dec.w   R4
                jmp     deactive_delay_loop?
deactive_delay_done?:
                dec.w   R12
                jmp     loop?

done?:
                pop.w   R4
                ret
                .endasmfunc

                .text
                .def    IND_morse
IND_morse:
; (u64_0@R12,u64_1@R13,u64_2@R14,u64_3@R15) -> ()
                .asmfunc
                push.w  R4
                push.w  R5
                push.w  R6
                push.w  R7
                mov.w   R12,R4
                mov.w   R13,R5
                mov.w   R14,R6
                mov.w   R15,R7

loop?:
                tst.w   R4
                jnz     remains?
                tst.w   R5
                jnz     remains?
                tst.w   R6
                jnz     remains?
                tst.w   R7
                jnz     remains?
                jmp     last_3space?

remains?:
                bit.w   #1b,R4
                jz      state_space?
state_mark?:
                bis.b   #BIT0,P2DIR
                jmp     state_set?
state_space?:
                bic.b   #BIT0,P2DIR
                jmp     state_set?
state_set?:
                clrc
                rrc.w   R7
                rrc.w   R6
                rrc.w   R5
                rrc.w   R4
                delay   #IND_MORSE_TICK
                jmp     loop?

last_3space?:
                bic.b   #BIT0,&P2DIR
                delay   #IND_MORSE_TICK
                delay   #IND_MORSE_TICK
                delay   #IND_MORSE_TICK

                pop.w   R7
                pop.w   R6
                pop.w   R5
                pop.w   R4
                ret
                .endasmfunc

