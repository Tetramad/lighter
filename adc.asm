; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"

                .def    adc_result_A0
                .bss    adc_result_A0,2,2
                .def    adc_result_A4
                .bss    adc_result_A4,2,2
                .def    adc_result_A5
                .bss    adc_result_A5,2,2

                .text
                .def    ADC_init
ADC_init:
                .asmfunc
                mov.w   #ADCSHT_3|ADCMSC_0|ADCON_1|ADCENC_0|ADCSC_0,&ADCCTL0
                mov.w   #ADCSHS_0|ADCSHP_1|ADCISSH_0|ADCDIV_0|ADCSSEL_0|ADCCONSEQ_0,&ADCCTL1
                mov.w   #ADCPDIV_0|ADCRES_1|ADCDF_0,&ADCCTL2
                mov.w   #ADCSREF_0|ADCINCH_0,&ADCMCTL0
                bic.b   #BIT0|BIT4|BIT5,&P1SEL0
                bic.b   #BIT0|BIT4|BIT5,&P1SEL1
                bis.b   #BIT0|BIT4|BIT5,&P1SELC
                ret
                .endasmfunc

                .text
                .def    ADC_fetch
ADC_fetch:
                .asmfunc
                bic.w   #ADCINCH,&ADCMCTL0
                bis.w   #ADCINCH_0,&ADCMCTL0
                bis.w   #ADCENC|ADCSC,&ADCCTL0
$1:             bit.w   #ADCIFG0,&ADCIFG
                jz      $1
                mov.w   &ADCMEM0,&adc_result_A0
                bic.w   #ADCENC,&ADCCTL0

                bic.w   #ADCINCH,&ADCMCTL0
                bis.w   #ADCINCH_4,&ADCMCTL0
                bis.w   #ADCENC|ADCSC,&ADCCTL0
$2:             bit.w   #ADCIFG0,&ADCIFG
                jz      $2
                mov.w   &ADCMEM0,&adc_result_A4
                bic.w   #ADCENC,&ADCCTL0

                bic.w   #ADCINCH,&ADCMCTL0
                bis.w   #ADCINCH_5,&ADCMCTL0
                bis.w   #ADCENC|ADCSC,&ADCCTL0
$3:             bit.w   #ADCIFG0,&ADCIFG
                jz      $3
                mov.w   &ADCMEM0,&adc_result_A5
                bic.w   #ADCENC,&ADCCTL0
                ret
                .endasmfunc
