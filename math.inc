; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .global ulimul60
                ; (ul@[R13:R12]) -> (ul@[R13:R12])
                .global ulidiv1000
                ; (u_l@R12,u_h@R13) -> (quot_l@R12,quot_h@R13)
                .global ulidivmod60
                ; (u_l@R12,u_h@R13) -> (quot_l@R12,quot_h@R13,rem@R14)
                .global ulidivmod24
                ; (u_l@R12,u_h@R13) -> (quot_l@R12,quot_h@R13,rem@R14)

                .global uimul10
                ; (u@R12) -> (u@R12)
                .global uimul16
                ; (u@R12) -> (u@R12)
                .global uidivmod10
                ; (u@R12) -> (qout@R12,rem@R13)

                .global uhimul24
                ; (u@R12_L) -> (y@R12)

                .global utobcd
                ; (u@R12) -> (bcd_l@R12,bcd_h@R13)

                .global ss_to_shhmmq
                ; (ss@[R13:R12]) -> (error@R12,shhmmq@R13)
                .global hhmmss_to_shhmmq
                ; (hh@R12,mm@R13,ss@R14) -> (error@R12,shhmmq@R13)
                .global shhmmq_add
                ; (rhs@R12,lhs@R13) -> (error@R12,result@R13)

ulisub:         .macro  rhs_l,rhs_h,lhs_l,lhs_h
                ; (rhs_l@Ra,rhs_h@Rb,lhs_l@Rc,lhs_h@Rd) -> (ul_l@Rc,ul_h@Rd)
                sub.w   rhs_l,lhs_l
                subc.w  rhs_h,lhs_h
                .endm

                ; shh:mm.q (shhmmq)
                ; 0000 0000 0000 0000 b
                ;                  00 -> quater minutes
                ;           1111 00   -> minutes
                ;    1 1000           -> hours
                ; 1                   -> sign
                ;  00                 -> reserved(0 by default)
                ; s00h hhhh mmmm mmqq b
                ;
                ; [-12:00:0, +24:00:0] 36 hours range -- TODO: but why?
