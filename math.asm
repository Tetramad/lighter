; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"

                .text
                .def    ulimul60
ulimul60:
; (ul@[R13:R12]) -> (ul@[R13:R12])
                .asmfunc
                ; 60d = 0011'1100b
                mov.w   R12,R14
                mov.w   R13,R15

                .loop   2
                rla.w   R14
                rlc.w   R15
                .endloop

                mov.w   R14,R12
                mov.w   R15,R13

                .loop   3
                rla.w   R14
                rlc.w   R15
                add.w   R14,R12
                addc.w  R15,R13
                .endloop

                ret
                .endasmfunc

                .text
                .def    ulidiv1000
ulidiv1000:
; (u_l@R12,u_h@R13) -> (qout_l@R12,qout_h@R13)
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
; (u_l@R12,u_h@R13) -> (qout_l@R12,qout_h@R13,rem@R14)
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
; (u_l@R12,u_h@R13) -> (qout_l@R12,qout_h@R13,rem@R14)
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

                .text
                .def    uhimul24
uhimul24:
; (u@R12_L) -> (y@R12)
                .asmfunc
                push.w  R4
                mov.b   R12,R4
                .loop   3
                rla.w   R4
                .endloop
                mov.w   R4,R12
                rla.w   R4
                add.w   R4,R12

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
                .def    utobcd
utobcd:
; (u@R12) -> (bcd_l@R12,bcd_h@R13)
                .asmfunc
                push.w  R4
                mov.w   R12,R4
                clr.w   R12
                clr.w   R13

d5_loop?:
                cmp.w   #10000,R4
                jnc     d5_done?
                sub.w   #10000,R4
                clrc
                dadd.w  #0001h,R13
                jmp     d5_loop?
d5_done?:

d4_loop?:
                cmp.w   #1000,R4
                jnc     d4_done?
                sub.w   #1000,R4
                clrc
                dadd.w  #1000h,R12
                jmp     d4_loop?
d4_done?:

d3_loop?:
                cmp.w   #100,R4
                jnc     d3_done?
                sub.w   #100,R4
                clrc
                dadd.w  #100h,R12
                jmp     d3_loop?
d3_done?:

d2_loop?:
                cmp.w   #10,R4
                jnc     d2_done?
                sub.w   #10,R4
                clrc
                dadd.w  #10h,R12
                jmp     d2_loop?
d2_done?:

d1_loop?:
                cmp.w   #1,R4
                jnc     d1_done?
                sub.w   #1,R4
                clrc
                dadd.w  #1h,R12
                jmp     d1_loop?
d1_done?:

                pop.w   R4
                ret
                .endasmfunc

                .text
                .def    ss_to_shhmmq
ss_to_shhmmq:
; (ss@[R13:R12]) -> (error@R12,shhmmq@R13)
                .asmfunc
                call    #ulidivmod60 ; -> (quot@[R13:R12],rem@R14)
                push.w  R14 ; seconds
                call    #ulidivmod60 ; -> (quot@[R13:R12],rem@R14)
                push.w  R14 ; minutes
                call    #ulidivmod24 ; -> (quot@[R13:R12],rem@R14)
                push.w  R14 ; hours

                .asg    0(SP),hours
                .asg    2(SP),minutes
                .asg    4(SP),seconds

                tst.w   hours
                jn      error?
                cmp.w   #24,hours
                jc      error?
                cmp.w   #60,minutes
                jc      error?
                cmp.w   #60,seconds
                jc      error?

                clr.w   R13
                cmp.w   #45,seconds
                jc      quater3?
                cmp.w   #30,seconds
                jc      quater2?
                cmp.w   #15,seconds
                jc      quater1?
                jmp     quater0?

quater3?:       inc.w   R13
quater2?:       inc.w   R13
quater1?:       inc.w   R13
quater0?:

                rla.w   minutes
                rla.w   minutes
                add.w   minutes,R13

                swpb    hours
                add.w   hours,R13

                .unasg  hours
                .unasg  minutes
                .unasg  seconds

                pop.w   R3
                pop.w   R3
                pop.w   R3
                clr.w   R12
                ret

error?:
                pop.w   R3
                pop.w   R3
                pop.w   R3
                mov.w   #-1,R12
                ret
                .endasmfunc

                .text
                .def    hhmmss_to_shhmmq
hhmmss_to_shhmmq:
; (hh@R12,mm@R13,ss@R14) -> (error@R12,shhmmq@R13)
                .asmfunc
                push.w  R14
                push.w  R13
                push.w  R12

                .asg    0(SP),hh
                .asg    2(SP),mm
                .asg    4(SP),ss

                mov.w   hh,R12
                clr.w   R13
                call    #ulimul60 ; (ul@[R13:R12]) -> (ul@[R13:R12])
                add.w   mm,R12
                adc.w   R13
                call    #ulimul60 ; (ul@[R13:R12]) -> (ul@[R13:R12])
                add.w   ss,R12
                adc.w   R13
                call    #ss_to_shhmmq ; (ss@[R13:R12]) -> (error@R12,shhmmq@R13)

                .unasg  ss
                .unasg  mm
                .unasg  hh

                pop.w   R3
                pop.w   R3
                pop.w   R3
                ret
                .endasmfunc

                .text
                .def    shhmmq_add
shhmmq_add:
; (rhs@R12,lhs@R13) -> (error@R12,result@R13)
                .asmfunc
                ; assume(rhs.s == 0 && lhs.s == 0)
                mov.w   R12,R14
                mov.w   R13,R15

                mov.b   R12,R12
                mov.b   R13,R13
                add.w   R12,R13
                cmp.w   #(60<<2),R13
                jc      not_overflow_minutes?
                sub.w   #(60<<2),R13
                add.w   #0100h,R14
not_overflow_minutes?:
                swpb    R14
                mov.b   R14,R14
                swpb    R15
                mov.b   R15,R15

                add.b   R14,R15
                swpb    R15
                cmp.w   #24,R15
                jc      not_overflow_hours?
                sub.w   #24,R15
not_overflow_hours?:
                add.w   R15,R13
                mov.w   #0,R12
                ret
                .endasmfunc
