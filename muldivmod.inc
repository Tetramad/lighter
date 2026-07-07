; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .global ulidiv1000
                ; (u_l@R12,u_h@R13) -> (qout_l@R12,qout_h@R13)
                .global ulidivmod60
                ; (u_l@R12,u_h@R13) -> (qout_l@R12,qout_h@R13,rem@R14)
                .global ulidivmod24
                ; (u_l@R12,u_h@R13) -> (qout_l@R12,qout_h@R13,rem@R14)

                .global uhimul24
                ; (u@R12_L) -> (y@R12)

                .global utobcd
                ; (u@R12) -> (bcd_l@R12,bcd_h@R13)
