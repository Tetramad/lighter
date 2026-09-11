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

                .global tick_to_time
                ; (tick@R12) -> (error@R12,time@R13)

                ; -time -> Quater-minutes (15 seconds LSB) in absolute
                ; -tick -> Quater-minutes (15 seconds LSB) in relative
