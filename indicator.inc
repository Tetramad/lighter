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
