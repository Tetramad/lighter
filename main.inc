; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

tsterr:         .macro  reg,label
                tst.w   reg
                jn      label
                .endm
