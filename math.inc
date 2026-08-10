; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                ; uli:  double word
                ; ui:   word (single register)
                ; uhi:  half word (_l: lower half, _u: upper half)

                .global ulidiv1000
                ; (u_l@R12,u_h@R13) -> (quot_l@R12,quot_h@R13)
                .global ulidivmod15
                ; (u_l@R12,u_h@R13) -> (quot_l@R12,quot_h@R13,rem@R14)
                .global ulidivmod5760
                ; (u_l@R12,u_h@R13) -> (quot_l@R12,quot_h@R13,rem@R14)

                .global uimul10
                ; (u@R12) -> (u@R12)
                .global uimul16
                ; (u@R12) -> (u@R12)
                .global uimul60
                ; (u@R12) -> (u@R12)
                .global uidivmodui
                ; (dividend@R12,divider@R13) -> (quot@R12,rem@R13)

                .global quaters_unsigned
                ; (quaters@R12) -> (error@R12,quaters_unsigned@R13)

                ; quater minutes or quaters
                ; 0000 0000 0000 0000 b
                ;                     -> quater minutes (signed)
                ;
                ; e.g. 0000000000000001b => 15 seconds
                ;      0000000000000100b => 1 minute
                ;      0000000011110000b => 1 hour(60 minutes)
                ;      1111111100010000b => -1 hours
