; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "datatable.inc"

                .global DT_store
                .global DT_load

                .bss    dt_base,DT_RECORD_LENGTH*2,2

                .text
                .def    DT_store
DT_store:
; (key@R12,value@R13) -> (error@R12)
                .asmfunc
                cmp.w   #DT_RECORD_LENGTH,R12
                jc      error?
                rla.w   R12
                add.w   #dt_base,R12
                mov.w   R13,0(R12)
                clr.w   R12
                ret
error?:
                mov.w   #-1,R12
                ret
                .endasmfunc

                .text
                .def    DT_load
DT_load:
; (key@R12) -> (error@R12,value@R13)
                .asmfunc
                cmp.w   #DT_RECORD_LENGTH,R12
                jc      error?
                rla.w   R12
                add.w   #dt_base,R12
                mov.w   @R12,R13
                clr.w   R12
                ret
error?:
                mov.w   #-1,R12
                clr.w   R13
                ret
                .endasmfunc

                ; shh:mm.q (shhmmq)
                ; 0000 0000 0000 0000 b
                ;                  00 -> quater minutes
                ;           1111 00   -> minutes
                ;    1 1000           -> hours
                ; 1                   -> sign
                ;  00                 -> reserved(0 by default)
                ; s00h hhhh mmmm mmqq b
