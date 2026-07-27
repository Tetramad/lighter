; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "macros.inc"
                .include "datatable.inc"
                .include "math.inc"

                .text
                .def    UIN_init
UIN_init:
; () -> ()
                .asmfunc
                ; assume(#BIT0|BIT4|BIT5 AND P1SEL[01] == 0)
                bic.b   #BIT0|BIT4|BIT5,&P1REN
                bic.b   #BIT0|BIT4|BIT5,&P1DIR
                bic.b   #BIT0|BIT4|BIT5,&P1OUT
                bis.b   #BIT0|BIT4|BIT5,&P1SELC
                ret
                .endasmfunc

                .text
                .def    UIN_begin
UIN_begin:
                .asmfunc
                mov.w   #ADCSHT_3|ADCMSC_0|ADCON_1|ADCENC_0|ADCSC_0,&ADCCTL0
                mov.w   #ADCSHS_0|ADCSHP_1|ADCISSH_0|ADCDIV_0|ADCSSEL_0|ADCCONSEQ_0,&ADCCTL1
                mov.w   #ADCPDIV_0|ADCRES_1|ADCDF_0,&ADCCTL2
                mov.w   #ADCSREF_0,&ADCMCTL0

                ret
                .endasmfunc

                .text
                .def    UIN_end
UIN_end:
                .asmfunc
                bic.w   #ADCENC|ADCON,&ADCCTL0
                ret
                .endasmfunc

                .text
                .def    UIN_read_and_decode
UIN_read_and_decode:
; () -> (error@R12)
                .asmfunc
                push.w  #0

                bic.w   #ADCINCH,&ADCMCTL0
                bis.w   #ADCINCH_0,&ADCMCTL0
                bis.w   #ADCENC|ADCSC,&ADCCTL0
                waitbit #ADCIFG0,&ADCIFG
                mov.w   &ADCMEM0,R13
                bic.w   #ADCENC,&ADCCTL0
                mov.w   #DT_UIN_TZ_RAW,R12
                call    #DT_store

                bic.w   #ADCINCH,&ADCMCTL0
                bis.w   #ADCINCH_4,&ADCMCTL0
                bis.w   #ADCENC|ADCSC,&ADCCTL0
                waitbit #ADCIFG0,&ADCIFG
                mov.w   &ADCMEM0,R13
                bic.w   #ADCENC,&ADCCTL0
                mov.w   #DT_UIN_SR_RAW,R12
                call    #DT_store

                bic.w   #ADCINCH,&ADCMCTL0
                bis.w   #ADCINCH_5,&ADCMCTL0
                bis.w   #ADCENC|ADCSC,&ADCCTL0
                waitbit #ADCIFG0,&ADCIFG
                mov.w   &ADCMEM0,R13
                bic.w   #ADCENC,&ADCCTL0
                mov.w   #DT_UIN_SS_RAW,R12
                call    #DT_store

                .newblock
                mov.w   #DT_UIN_TZ_RAW,R12
                call    #DT_load ; -> (error@R12,timezone_raw@R13)
                cmp.w   #20,R13
                jc      lower_clamped?
                mov.w   #20,R13
lower_clamped?:
                cmp.w   #980,R13
                jnc     upper_clampled?
                mov.w   #979,R13
upper_clampled?:
                clr.w   0(SP)
                mov.w   R13,R12
                mov.w   #10,R13
                call    #uidivmodui ; -> (quot@R12,rem@R13)
                rrc.w   R12
                bic.w   #8000h,R12
                clr.w   R13
                cmp.w   #24,R12
                adc.w   R13
                xor.w   R13,R12
                bit.w   #1b,R12
                jz      zero_minutes?
                mov.w   #01111000b,0(SP)
zero_minutes?:
                rrc.w   R12
                bic.w   #8000h,R12
                sub.w   #12,R12
                jge     not_negative_hours?
                bis.w   #08000h,0(SP)
                inv.w   R12
                inc.w   R12
not_negative_hours?:
                swpb    R12
                add.w   R12,0(SP)

                mov.w   #DT_UIN_TZ,R12
                mov.w   0(SP),R13
                call    #DT_store

                .newblock
                mov.w   #DT_UIN_SR_RAW,R12
                call    #DT_load ; -> (error@R12,sunrise_raw@R13)
                cmp.w   #1000,R13
                jnc     upper_clampled?
                mov.w   #999,R13
upper_clampled?:
                clr.w   0(SP)
                mov.w   R13,R12
                mov.w   #40,R13
                call    #uidivmodui ; -> (quot@R12,rem@R13)
                bit.w   #1b,R12
                jz      zero_minutes?
                mov.w   #01111000b,0(SP)
zero_minutes?:
                rra.w   R12
                swpb    R12
                add.w   R12,0(SP)

                mov.w   #DT_UIN_TZ,R12
                call    #DT_load ; -> (error@R12,timezone@R13)
                mov.w   0(SP),R12
                call    #shhmmq_add ; -> (error@R12,result@R13)

                mov.w   #DT_UIN_SR,R12
                call    #DT_store

                .newblock
                mov.w   #DT_UIN_SS_RAW,R12
                call    #DT_load ; -> (error@R12,sunrise_raw@R13)
                cmp.w   #1000,R13
                jnc     upper_clampled?
                mov.w   #999,R13
upper_clampled?:
                clr.w   0(SP)
                mov.w   R13,R12
                mov.w   #40,R13
                call    #uidivmodui ; -> (quot@R12,rem@R13)
                rra.w   R12
                jnc     zero_minutes?
                mov.w   #01111000b,0(SP)
zero_minutes?:
                add.w   #12,R12
                swpb    R12
                add.w   R12,0(SP)

                mov.w   #DT_UIN_TZ,R12
                call    #DT_load ; -> (error@R12,timezone@R13)
                mov.w   0(SP),R12
                call    #shhmmq_add ; -> (error@R12,result@R13)

                mov.w   #DT_UIN_SS,R12
                call    #DT_store

                clr.w   R12
                pop.w   R3
                ret
                .endasmfunc

                .text
                .def    UIN_timezone
UIN_timezone:
; () -> (error@R12, timezone_shhmmq@R13)
                .asmfunc
                mov.w   #DT_UIN_TZ,R12
                call    #DT_load
                tst.w   R12
                jn      error?
                clr.w   R12
                ret
error?:
                mov.w   #-1,R12
                ret
                .endasmfunc

                .text
                .def    UIN_sunrise
UIN_sunrise:
; () -> (error@R12, sunrise_shhmmq@R13)
                .asmfunc
                mov.w   #DT_UIN_SR,R12
                call    #DT_load
                tst.w   R12
                jn      error?

                clr.w   R12
                ret
error?:
                mov.w   #-1,R12
                ret
                .endasmfunc

                .text
                .def    UIN_sunset
UIN_sunset:
; () -> (error@R12, sunset_shhmmq@R13)
                .asmfunc
                mov.w   #DT_UIN_SS,R12
                call    #DT_load
                tst.w   R12
                jn      error?

                clr.w   R12
                ret
error?:
                mov.w   #-1,R12
                ret
                .endasmfunc
