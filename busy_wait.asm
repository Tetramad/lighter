; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .global busy_wait_ms

                .define 1000000, MCO

                .text
busy_wait_ms:   .asmfunc
                push    R4
$2:             tst.w   R12
                jz      $0
                dec.w   R12
                .if (MCO-2)/4/1000 > 0FFFFh
                    .emsg   "the counter didn't fit in a register"
                .endif
                mov.w   #(MCO-2)/4/1000,R4
$1:             dec.w   R4
                tst.w   R4
                jnz     $1
                jmp     $2
$0:             pop     R4
                ret
                .endasmfunc

