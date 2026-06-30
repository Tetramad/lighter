; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"

                .text
                .def    ulidiv1000
ulidiv1000:
; (x_l@R12,x_h@R13) -> (qout_l@R12,qout_h@R13)
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
                sub.w   R6,R4
                subc.w  R7,R5
                jl      not_subtractable?
                add.w   R8,R12
                addc.w  R9,R13
                jmp     processed?
not_subtractable?:
                add.w   R6,R4
                addc.w  R7,R5
processed?:
                clrc
                rlc.w   R7
                rlc.w   R6
                clrc
                rlc.w   R9
                rlc.w   R8
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
                .def    ulidivmod60
ulidivmod60:
; (x_l@R12,x_h@R13) -> (qout_l@R12,qout_h@R13,rem@R14)
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
                mov.w   #00400h,R9
                clr.w   R12
                clr.w   R13

repeat?:
                sub.w   R6,R4
                subc.w  R7,R5
                jl      not_subtractable?
                add.w   R8,R12
                addc.w  R9,R13
                jmp     processed?
not_subtractable?:
                add.w   R6,R4
                addc.w  R7,R5
processed?:
                clrc
                rlc.w   R7
                rlc.w   R6
                clrc
                rlc.w   R9
                rlc.w   R8
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
                .def    ulidivmod24
ulidivmod24:
; (x_l@R12,x_h@R13) -> (qout_l@R12,qout_h@R13,rem@R14)
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
                mov.w   #0C000h,R7
                mov.w   #00000h,R8
                mov.w   #00800h,R9
                clr.w   R12
                clr.w   R13

repeat?:
                sub.w   R6,R4
                subc.w  R7,R5
                jl      not_subtractable?
                add.w   R8,R12
                addc.w  R9,R13
                jmp     processed?
not_subtractable?:
                add.w   R6,R4
                addc.w  R7,R5
processed?:
                clrc
                rlc.w   R7
                rlc.w   R6
                clrc
                rlc.w   R9
                rlc.w   R8
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
                ret
                .endasmfunc
