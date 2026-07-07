; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                ; INDicator -> IND

                .global IND_init
                ; () -> ()
                .global IND_error
                ; (error@R12) -> ()
                .global IND_morse
                ; (u64_0@R12,u64_1@R13,u64_2@R14,u64_3@R15) -> ()
                .global IND_morse_digit
                ; (digit@R12) -> ()

morse_KA:       .macro
                push.w  R12
                push.w  R13
                push.w  R14
                push.w  R15
                mov.w   #0111010111010111b,R12
                mov.w   #0000000000000000b,R13
                mov.w   #0000000000000000b,R14
                mov.w   #0000000000000000b,R15
                call    #IND_morse
                pop.w   R15
                pop.w   R14
                pop.w   R13
                pop.w   R12
                .endm

morse_AR:       .macro
                push.w  R12
                push.w  R13
                push.w  R14
                push.w  R15
                mov.w   #0001011101011101b,R12
                mov.w   #0000000000000000b,R13
                mov.w   #0000000000000000b,R14
                mov.w   #0000000000000000b,R15
                call    #IND_morse
                pop.w   R15
                pop.w   R14
                pop.w   R13
                pop.w   R12
                .endm
