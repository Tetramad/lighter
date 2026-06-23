; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "datatable.inc"

                .text
                .def    UIN_begin
UIN_begin:
                .asmfunc
                mov.w   #ADCSHT_3|ADCMSC_0|ADCON_1|ADCENC_0|ADCSC_0,&ADCCTL0
                mov.w   #ADCSHS_0|ADCSHP_1|ADCISSH_0|ADCDIV_0|ADCSSEL_0|ADCCONSEQ_0,&ADCCTL1
                mov.w   #ADCPDIV_0|ADCRES_1|ADCDF_0,&ADCCTL2
                mov.w   #ADCSREF_0,&ADCMCTL0

                bic.b   #BIT0|BIT4|BIT5,&P1REN
                bic.b   #BIT0|BIT4|BIT5,&P1DIR
                bic.b   #BIT0|BIT4|BIT5,&P1OUT
                bic.b   #BIT0|BIT4|BIT5,&P1SEL0
                bic.b   #BIT0|BIT4|BIT5,&P1SEL1
                bis.b   #BIT0|BIT4|BIT5,&P1SELC
                ret
                .endasmfunc

                .text
                .def    UIN_end
UIN_end:
                .asmfunc
                bic.w   #ADCENC|ADCON,&ADCCTL0

                bic.b   #BIT0|BIT4|BIT5,&P1DIR
                bis.b   #BIT0|BIT4|BIT5,&P1OUT
                bis.b   #BIT0|BIT4|BIT5,&P1REN
                bis.b   #BIT0|BIT4|BIT5,&P1SELC
                ret
                .endasmfunc

                .text
                .def    UIN_read_and_decode
UIN_read_and_decode:
; () -> (error@R12)
                .asmfunc
                bic.w   #ADCINCH,&ADCMCTL0
                bis.w   #ADCINCH_0,&ADCMCTL0
                bis.w   #ADCENC|ADCSC,&ADCCTL0
$1:             bit.w   #ADCIFG0,&ADCIFG
                jz      $1
                ; TODO: decode
                mov.w   #DT_UIN_TZ,R12
                mov.w   &ADCMEM0,R13
                call    #DT_store
                tst.w   R12
                jl      error?
                bic.w   #ADCENC,&ADCCTL0

                bic.w   #ADCINCH,&ADCMCTL0
                bis.w   #ADCINCH_4,&ADCMCTL0
                bis.w   #ADCENC|ADCSC,&ADCCTL0
$2:             bit.w   #ADCIFG0,&ADCIFG
                jz      $2
                ; TODO: decode
                mov.w   #DT_UIN_SR,R12
                mov.w   &ADCMEM0,R13
                call    #DT_store
                tst.w   R12
                jl      error?
                bic.w   #ADCENC,&ADCCTL0

                bic.w   #ADCINCH,&ADCMCTL0
                bis.w   #ADCINCH_5,&ADCMCTL0
                bis.w   #ADCENC|ADCSC,&ADCCTL0
$3:             bit.w   #ADCIFG0,&ADCIFG
                jz      $3
                ; TODO: decode
                mov.w   #DT_UIN_SS,R12
                mov.w   &ADCMEM0,R13
                call    #DT_store
                tst.w   R12
                jl      error?
                bic.w   #ADCENC,&ADCCTL0

                clr.w   R12
                ret
error?:
                mov.w   #-1,R12
                ret
                .endasmfunc

                .text
                .def    UIN_timezone
UIN_timezone:
; () -> (error@R12, timezone_index@R13)
                .asmfunc
                mov.w   #DT_UIN_TZ,R12
                call    #DT_load
                tst.w   R12
                jl      error?

                clr.w   R12
                ret
error?:
                mov.w   #-1,R12
                ret
                .endasmfunc

                .text
                .def    UIN_sunrise
UIN_sunrise:
; () -> (error@R12, sunrise_index@R13)
                .asmfunc
                mov.w   #DT_UIN_SR,R12
                call    #DT_load
                tst.w   R12
                jl      error?

                clr.w   R12
                ret
error?:
                mov.w   #-1,R12
                ret
                .endasmfunc

                .text
                .def    UIN_sunset
UIN_sunset:
; () -> (error@R12, sunset_index@R13)
                .asmfunc
                mov.w   #DT_UIN_SS,R12
                call    #DT_load
                tst.w   R12
                jl      error?

                clr.w   R12
                ret
error?:
                mov.w   #-1,R12
                ret
                .endasmfunc

