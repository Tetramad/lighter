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
                push.w  R4

                bic.w   #ADCINCH,&ADCMCTL0
                bis.w   #ADCINCH_0,&ADCMCTL0
                bis.w   #ADCENC|ADCSC,&ADCCTL0
                waitbis #ADCIFG0,&ADCIFG
                mov.w   &ADCMEM0,R13
                bic.w   #ADCENC,&ADCCTL0
                pcall   DT_store,#DT_UIN_TZ_RAW, ; -> (error@R12)

                bic.w   #ADCINCH,&ADCMCTL0
                bis.w   #ADCINCH_4,&ADCMCTL0
                bis.w   #ADCENC|ADCSC,&ADCCTL0
                waitbis #ADCIFG0,&ADCIFG
                mov.w   &ADCMEM0,R13
                bic.w   #ADCENC,&ADCCTL0
                pcall   DT_store,#DT_UIN_SR_RAW, ; -> (error@R12)

                bic.w   #ADCINCH,&ADCMCTL0
                bis.w   #ADCINCH_5,&ADCMCTL0
                bis.w   #ADCENC|ADCSC,&ADCCTL0
                waitbis #ADCIFG0,&ADCIFG
                mov.w   &ADCMEM0,R13
                bic.w   #ADCENC,&ADCCTL0
                pcall   DT_store,#DT_UIN_SS_RAW, ; -> (error@R12)

                .newblock
                ; -12:00:00 ~ 12:00:00
                ; map(0, 1023, -24, 24) 49 * 20 -> 980
                ; clamp(0, 1023, 20, 999)
                ; map(20, 999, -24, 24)
                ; 30minutes * [-24,24]
                ; 120quaters * [-24,24]
                ; 01111000b * [-24,24]
                pcall   DT_load,#DT_UIN_TZ_RAW ; -> (error@R12,timezone_raw@R13)
                mov.w   R13,R12
                cmp.w   #20,R12
                jc      lower_clamped?
                mov.w   #20,R12
lower_clamped?:
                cmp.w   #1000,R12
                jnc     upper_clampled?
                mov.w   #999,R12
upper_clampled?:
                sub.w   #20,R12
                pcall   uidivmodui,,#20 ; -> (quot@R12,rem@R13)
                sub.w   #24,R12
                ;call   #uimul120
                pcall   uimul60, ; -> (u@R12)
                rla.w   R12
                mov.w   R12,R13
                pcall   DT_store,#DT_UIN_TZ, ; -> (error@R12)

                ; TODO: white night?
                .newblock
                ; 00:00:00 ~ 11:30:00
                ; map(0, 1023, 0, 23) 24 * 40 -> 960
                ; clamp(0, 1023, 30, 989)
                ; map(30, 989, 0, 23)
                ; 30minutes * [0,23]
                ; 120quaters * [0,23]
                ; 01111000b * [0,23]
                pcall   DT_load,#DT_UIN_SR_RAW ; -> (error@R12,sunrise_raw@R13)
                mov.w   R13,R12
                cmp.w   #30,R12
                jc      lower_clamped?
                mov.w   #30,R12
lower_clamped?:
                cmp.w   #990,R12
                jnc     upper_clampled?
                mov.w   #989,R12
upper_clampled?:
                sub.w   #30,R12
                pcall   uidivmodui,,#40 ; -> (quot@R12,rem@R13)
                ;call   #uimul120
                pcall   uimul60, ; -> (u@R12)
                rla.w   R12
                mov.w   R12,R4

                pcall   DT_load,#DT_UIN_TZ ; -> (error@R12,timezone@R13)
                mov.w   R4,R12
                sub.w   R13,R12
                pcall   tick_to_time, ; -> (error@R12,time@R13)
                pcall   DT_store,#DT_UIN_SR, ; -> (error@R12)

                .newblock
                ; 12:00:00 ~ 23:30:00
                ; map(0, 1023, 24, 47) 24 * 40 -> 960
                ; clamp(0, 1023, 30, 989)
                ; map(30, 989, 24, 47)
                ; 30minutes * [24, 47]
                ; 120quaters * [24, 47]
                ; 01111000b * [24, 47]
                pcall   DT_load,#DT_UIN_SS_RAW ; -> (error@R12,sunrise_raw@R13)
                mov.w   R13,R12
                cmp.w   #30,R12
                jc      lower_clamped?
                mov.w   #30,R12
lower_clamped?:
                cmp.w   #990,R12
                jnc     upper_clampled?
                mov.w   #989,R12
upper_clampled?:
                sub.w   #30,R12
                pcall   uidivmodui,,#40 ; -> (quot@R12,rem@R13)
                add.w   #24,R12
                ;call   #uimul120
                pcall   uimul60, ; -> (u@R12)
                rla.w   R12
                mov.w   R12,R4

                pcall   DT_load,#DT_UIN_TZ ; -> (error@R12,timezone@R13)
                mov.w   R4,R12
                sub.w   R13,R12
                pcall   tick_to_time, ; -> (error@R12,time@R12)
                pcall   DT_store,#DT_UIN_SS, ; -> (error@R12)

                clr.w   R12
                pop.w   R4
                ret
                .endasmfunc

                .text
                .def    UIN_timezone
UIN_timezone:
; () -> (error@R12, timezonetick@R13)
                .asmfunc
                pcall   DT_load,#DT_UIN_TZ ; -> (error@R12,value@R13)
                ret
                .endasmfunc

                .text
                .def    UIN_sunrise
UIN_sunrise:
; () -> (error@R12, sunrisetime@R13)
                .asmfunc
                pcall   DT_load,#DT_UIN_SR ; -> (error@R12,value@R13)
                ret
                .endasmfunc

                .text
                .def    UIN_sunset
UIN_sunset:
; () -> (error@R12, sunsettime@R13)
                .asmfunc
                pcall   DT_load,#DT_UIN_SS ; -> (error@R12,value@R13)
                ret
                .endasmfunc
