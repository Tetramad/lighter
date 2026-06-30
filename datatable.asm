; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"

                .global DT_store
                .global DT_load

                .text
                .def    DT_store
DT_store:
; (key@R12,value@R13) -> (error@R12)
                .asmfunc
                ; TODO: implement
                clr.w   R12
                ret
                .endasmfunc

                .text
                .def    DT_load
DT_load:
; (key@R12) -> (error@R12,value@R13)
                .asmfunc
                ; TODO: implement
                clr.w   R12
                clr.w   R13
                ret
                .endasmfunc

                ; shh:mm.q
                ; 0000 0000 0000 0000 b
                ;                  00 -> quater minutes
                ;           1111 00   -> minutes
                ;    1 1000            -> hours
                ; s00h hhhh mmmm mmqq b
