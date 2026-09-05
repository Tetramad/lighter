; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"

                .text
                .def    ulidiv1000
ulidiv1000:
; (u_l@R12,u_h@R13) -> (quot_l@R12,quot_h@R13)
                .asmfunc
                push.w  R4
                push.w  R5
                push.w  R6
                push.w  R7
                push.w  R8
                push.w  R9

                mov.w   R12,R4
                mov.w   R13,R5
                mov.w   #00000h,R6
                mov.w   #0FA00h,R7
                mov.w   #00000h,R8
                mov.w   #00040h,R9
                clr.w   R12
                clr.w   R13

repeat?:
                cmp.w   R7,R5
                jeq     compare_lower_word?
                jhs     subtractable?
                jmp     not_subtractable?
compare_lower_word?:
                cmp.w   R6,R4
                jhs     subtractable?
                jmp     not_subtractable?
subtractable?:
                sub.w   R6,R4
                subc.w  R7,R5
                add.w   R8,R12
                addc.w  R9,R13
not_subtractable?:
processed?:
                clrc
                rrc.w   R7
                rrc.w   R6
                clrc
                rrc.w   R9
                rrc.w   R8
                cmp.w   R8,R9
                jnz     repeat?

                pop.w   R9
                pop.w   R8
                pop.w   R7
                pop.w   R6
                pop.w   R5
                pop.w   R4
                ret
                .endasmfunc

                .text
                .def    ulidivmod15
ulidivmod15:
; (u_l@R12,u_h@R13) -> (quot_l@R12,quot_h@R13,rem@R14)
                .asmfunc
                push.w  R4
                push.w  R5
                push.w  R6
                push.w  R7
                push.w  R8
                push.w  R9

                mov.w   R12,R4
                mov.w   R13,R5
                mov.w   #00000h,R6
                mov.w   #0F000h,R7
                mov.w   #00000h,R8
                mov.w   #01000h,R9
                clr.w   R12
                clr.w   R13

repeat?:
                cmp.w   R7,R5
                jeq     compare_lower_word?
                jhs     subtractable?
                jmp     not_subtractable?
compare_lower_word?:
                cmp.w   R6,R4
                jhs     subtractable?
                jmp     not_subtractable?
subtractable?:
                sub.w   R6,R4
                subc.w  R7,R5
                add.w   R8,R12
                addc.w  R9,R13
not_subtractable?:
processed?:
                clrc
                rrc.w   R7
                rrc.w   R6
                clrc
                rrc.w   R9
                rrc.w   R8
                cmp.w   R8,R9
                jnz     repeat?
                mov.w   R4,R14

                pop.w   R9
                pop.w   R8
                pop.w   R7
                pop.w   R6
                pop.w   R5
                pop.w   R4
                ret
                .endasmfunc

                .text
                .def    ulidivmod5760
ulidivmod5760:
; (u_l@R12,u_h@R13) -> (quot_l@R12,quot_h@R13,rem@R14)
                .asmfunc
                push.w  R4
                push.w  R5
                push.w  R6
                push.w  R7
                push.w  R8
                push.w  R9

                mov.w   R12,R4
                mov.w   R13,R5
                mov.w   #00000h,R6
                mov.w   #0B400h,R7
                mov.w   #00000h,R8
                mov.w   #00008h,R9
                clr.w   R12
                clr.w   R13

repeat?:
                cmp.w   R7,R5
                jeq     compare_lower_word?
                jhs     subtractable?
                jmp     not_subtractable?
compare_lower_word?:
                cmp.w   R6,R4
                jhs     subtractable?
                jmp     not_subtractable?
subtractable?:
                sub.w   R6,R4
                subc.w  R7,R5
                add.w   R8,R12
                addc.w  R9,R13
not_subtractable?:
processed?:
                clrc
                rrc.w   R7
                rrc.w   R6
                clrc
                rrc.w   R9
                rrc.w   R8
                cmp.w   R8,R9
                jnz     repeat?
                mov.w   R4,R14

                pop.w   R9
                pop.w   R8
                pop.w   R7
                pop.w   R6
                pop.w   R5
                pop.w   R4
                ret
                .endasmfunc

                .text
                .def    uimul10
uimul10:
; (u@R12) -> (u@R12)
                .asmfunc
                rla.w   R12
                push.w  R12
                rla.w   R12
                rla.w   R12
                add.w   R12,0(SP)
                pop.w   R12
                ret
                .endasmfunc

                .text
                .def    uimul16
uimul16:
; (u@R12) -> (u@R12)
                .asmfunc
                .loop 4
                rla.w   R12
                .endloop
                ret
                .endasmfunc

                .text
                .def    uimul60
uimul60:
; (u@R12) -> (u@R12)
                .asmfunc
                push.w  #0
                rla.w   R12
                .loop 4
                rla.w   R12
                add.w   R12,0(SP)
                .endloop
                pop.w   R12
                ret
                .endasmfunc

                .text
                .def    uidivmodui
uidivmodui:
; (dividend@R12,divider@R13) -> (quot@R12,rem@R13)
                .asmfunc
                push.w  R4
                push.w  R5

                mov.w   R13,R4
                mov.w   #00001h,R5

precalculation_loop?:
                bit.w   #08000h,R4
                jnz     precalculation_done?
                rla.w   R4
                rla.w   R5
                jmp     precalculation_loop?
precalculation_done?:

                mov.w   R12,R13
                clr.w   R12

loop_round?:
                cmp.w   R4,R13
                jnc     prepare_next_round?
                sub.w   R4,R13
                add.w   R5,R12
prepare_next_round?:
                clrc
                rrc.w   R5
                rrc.w   R4
                tst.w   R5
                jnz     loop_round?

                pop.w   R5
                pop.w   R4
                ret
                .endasmfunc

                .text
                .def    quaters_unsigned
quaters_unsigned:
; (quaters@R12) -> (error@R12,quaters_unsigned@R13)
                .asmfunc
                cmp.w   #0,R12
                jl      fold_up?
                jmp     positive?
fold_up?:
                add.w   #(24*60*4),R12
                cmp.w   #0,R12
                jl      fold_up?
positive?:
                cmp.w   #(24*60*4),R12
                jge     fold_down?
                jmp     clamped?
fold_down?:
                sub.w   #(24*60*4),R12
                cmp.w   #(24*60*4),R12
                jge     fold_down?
clamped?:
                mov.w   R12,R13
                clr.w   R12
                ret
                .endasmfunc
