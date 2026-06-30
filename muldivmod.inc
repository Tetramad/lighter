; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .global ulidiv1000
                ; (x_l@R12,x_h@R13) -> (qout_l@R12,qout_h@R13)
                .global ulidivmod60
                ; (x_l@R12,x_h@R13) -> (qout_l@R12,qout_h@R13,rem@R14)
                .global ulidivmod24
                ; (x_l@R12,x_h@R13) -> (qout_l@R12,qout_h@R13,rem@R14)
