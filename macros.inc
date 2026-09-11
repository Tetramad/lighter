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

pcall:          .macro  fid,args
                .if $ismember(arg1,args)
                .if $symlen(arg1)
                mov.w   arg1,R12
                .endif
                .endif
                .if $ismember(arg2,args)
                .if $symlen(arg2)
                mov.w   arg2,R13
                .endif
                .endif
                .if $ismember(arg3,args)
                .if $symlen(arg3)
                mov.w   arg3,R14
                .endif
                .endif
                .if $ismember(arg4,args)
                .if $symlen(arg4)
                mov.w   arg4,R15
                .endif
                .endif
                .if $ismember(arg5,args)
                .emsg   "Too many arguments"
                .endif
                call    #fid
                .endm
