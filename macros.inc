; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

tsterr:         .macro  reg,label
                tst.w   reg
                jn      label
                .endm

waitbis:        .macro  bits,address
wait?:          bit.w   bits,address
                jz      wait?
                .endm

waitbic:        .macro  bits,address
wait?:          bit.w   bits,address
                jnz     wait?
                .endm
