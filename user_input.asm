; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "datatable.inc"

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
                bic.w   #ADCINCH,&ADCMCTL0
                bis.w   #ADCINCH_0,&ADCMCTL0
                bis.w   #ADCENC|ADCSC,&ADCCTL0
wait_cplt?:     bit.w   #ADCIFG0,&ADCIFG
                jz      wait_cplt?
                ; [1000,) -> +12:00.0 (over)
                ; [980, 1000) -> +12:00.0 -> +24
                ; [500, 520) -> +00:00.0 -> 0
                ; [20, 40) -> -12:00.0 -> -24
                ; [,20) -> -12:00.0 (under)
                ; [20, 1000), 20 range, 49 bins
                ; [0, 1024)
                mov.w   &ADCMEM0,R12
                bic.w   #ADCENC,&ADCCTL0
                mov.w   #-24,R13
                cmp.w   #980,R12
                jnc     no_clamp_needed?
                mov.w   #980,R12
no_clamp_needed?:
count_loop?:
                cmp.w   #40,R12
                jnc     count_done?
                sub.w   #20,R12
                inc.w   R13
                jmp     count_loop?
count_done?:
                clr.w   R12
                ; @R12: need to be shhmmq
                ; @R13: count
                tst.w   R13
                jge     count_not_negative?
                bis.w   #1000000000000000b,R12
                inv.w   R13
                inc.w   R13
count_not_negative?:
                bit.w   #0000000000000001b,R13
                jz      zero_minutes?
                bic.w   #0000000000000001b,R13
                bis.w   #0000000001111000b,R12
zero_minutes?:
                swpb    R13
                rra.w   R13
                bis.w   R13,R12
                mov.w   R12,R13
                mov.w   #DT_UIN_TZ,R12
                call    #DT_store
                tst.w   R12
                jn      UIN_read_and_decode_$error

                .newblock
                bic.w   #ADCINCH,&ADCMCTL0
                bis.w   #ADCINCH_4,&ADCMCTL0
                bis.w   #ADCENC|ADCSC,&ADCCTL0
wait_cplt?:     bit.w   #ADCIFG0,&ADCIFG
                jz      wait_cplt?
                mov.w   &ADCMEM0,R12
                bic.w   #ADCENC,&ADCCTL0
                cmp.w   #960,R12
                jnc     no_clamp_needed?
                mov.w   #960,R12
no_clamp_needed?:
                clr.w   R13
count_loop?:
                cmp.w   #40,R12
                jnc     count_done?
                sub.w   #40,R12
                inc.w   R13
                jmp     count_loop?
count_done?:
                clr.w   R12
                bit.w   #1b,R13
                jz      zero_minutes?
                bic.w   #1b,R13
                bis.w   #0000000001111000b,R12
zero_minutes?:
                rra.w   R13
                swpb    R13
                bis.w   R13,R12
                push.w  R12
                mov.w   #DT_UIN_TZ,R12
                call    #DT_load
                tst.w   R12
                pop.w   R12
                jn      UIN_read_and_decode_$error
                ; @R12: SR(local)
                ; @R13: TZ(Z)
                xor.w   #8000h,R13      ; TODO: fix this temporary sign flip
                                        ; this logic add timezone not subtract.
                                        ; compansate hours only, not minutes.
                bit.w   #8000h,R13
                jz      negative_timezone?
                bic.w   #8000h,R13
                push.w  R13
                bic.w   #0FF00h,0(SP)
                swpb    R13
                mov.b   R13,R13
                inv.w   R13
                inc.w   R13
                add.w   #24,R13
                swpb    R13
                add.w   R13,0(SP)
                pop.w   R13
negative_timezone?:
                swpb    R12
                swpb    R13
                add.w   R13,R12
                jnc     minute_no_carry?
                add.w   #(4<<8),R12
minute_no_carry?:
                cmp.w   #(60<<8),R12
                jc      minute_no_overflow?
                sub.w   #(60<<8),R12
minute_no_overflow?:
                cmp.b   #24,R12
                jnc     hour_not_overflow?
                sub.w   #24,R12
hour_not_overflow?:
                swpb    R12
                mov.w   R12,R13
                mov.w   #DT_UIN_SR,R12
                call    #DT_store
                tst.w   R12
                jn      UIN_read_and_decode_$error

                .newblock
                ; TODO: something wrong in sunrise time calculation?
                bic.w   #ADCINCH,&ADCMCTL0
                bis.w   #ADCINCH_5,&ADCMCTL0
                bis.w   #ADCENC|ADCSC,&ADCCTL0
wait_cplt?:     bit.w   #ADCIFG0,&ADCIFG
                jz      wait_cplt?
                mov.w   &ADCMEM0,R12
                bic.w   #ADCENC,&ADCCTL0
                cmp.w   #960,R12
                jnc     no_clamp_needed?
                mov.w   #960,R12
no_clamp_needed?:
                clr.w   R13
count_loop?:
                cmp.w   #40,R12
                jnc     count_done?
                sub.w   #40,R12
                inc.w   R13
                jmp     count_loop?
count_done?:
                clr.w   R12
                bit.w   #1b,R13
                jz      zero_minutes?
                bic.w   #1b,R13
                bis.w   #0000000001111000b,R12
zero_minutes?:
                rra.w   R13
                add.w   #12,R13
                swpb    R13
                bis.w   R13,R12
                push.w  R12
                mov.w   #DT_UIN_TZ,R12
                call    #DT_load
                tst.w   R12
                pop.w   R12
                jn      UIN_read_and_decode_$error
                ; @R12: SS(local)
                ; @R13: TZ(Z)
                xor.w   #8000h,R13      ; TODO: fix this temporary sign flip
                                        ; this logic add timezone not subtract.
                                        ; compansate hours only, not minutes.
                bit.w   #8000h,R13
                jz      negative_timezone?
                bic.w   #8000h,R13
                push.w  R13
                bic.w   #0FF00h,0(SP)
                swpb    R13
                mov.b   R13,R13
                inv.w   R13
                inc.w   R13
                add.w   #24,R13
                swpb    R13
                add.w   R13,0(SP)
                pop.w   R13
negative_timezone?:
                swpb    R12
                swpb    R13
                add.w   R13,R12
                jnc     minute_no_carry?
                add.w   #(4<<8),R12
minute_no_carry?:
                cmp.w   #(60<<8),R12
                jc      minute_no_overflow?
                sub.w   #(60<<8),R12
minute_no_overflow?:
                cmp.b   #24,R12
                jnc     hour_not_overflow?
                sub.w   #24,R12
hour_not_overflow?:
                swpb    R12
                mov.w   R12,R13
                mov.w   #DT_UIN_SS,R12
                call    #DT_store
                tst.w   R12
                jn      UIN_read_and_decode_$error

                clr.w   R12
                ret
UIN_read_and_decode_$error:
                mov.w   #-1,R12
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

                ; 0 -24 20 40 -12 0
                ; 1 -23 40 60 -12 30
                ; 2 -22 60 80 -11 0
                ; 3 -21 80 100 -11 30
                ; 4 -20 100 120 -10 0
                ; 5 -19 120 140 -10 30
                ; 6 -18 140 160 -9 0
                ; 7 -17 160 180 -9 30
                ; 8 -16 180 200 -8 0
                ; 9 -15 200 220 -8 30
                ; 10 -14 220 240 -7 0
                ; 11 -13 240 260 -7 30
                ; 12 -12 260 280 -6 0
                ; 13 -11 280 300 -6 30
                ; 14 -10 300 320 -5 0
                ; 15 -9 320 340 -5 30
                ; 16 -8 340 360 -4 0
                ; 17 -7 360 380 -4 30
                ; 18 -6 380 400 -3 0
                ; 19 -5 400 420 -3 30
                ; 20 -4 420 440 -2 0
                ; 21 -3 440 460 -2 30
                ; 22 -2 460 480 -1 0
                ; 23 -1 480 500 -1 30
                ; 24 0 500 520 0 0
                ; 25 1 520 540 0 30
                ; 26 2 540 560 1 0
                ; 27 3 560 580 1 30
                ; 28 4 580 600 2 0
                ; 29 5 600 620 2 30
                ; 30 6 620 640 3 0
                ; 31 7 640 660 3 30
                ; 32 8 660 680 4 0
                ; 33 9 680 700 4 30
                ; 34 10 700 720 5 0
                ; 35 11 720 740 5 30
                ; 36 12 740 760 6 0
                ; 37 13 760 780 6 30
                ; 38 14 780 800 7 0
                ; 39 15 800 820 7 30
                ; 40 16 820 840 8 0
                ; 41 17 840 860 8 30
                ; 42 18 860 880 9 0
                ; 43 19 880 900 9 30
                ; 44 20 900 920 10 0
                ; 45 21 920 940 10 30
                ; 46 22 940 960 11 0
                ; 47 23 960 980 11 30
                ; 48 24 980 1000 12 0

                ; 0 [0, 40) 00:00
                ; 1 [40, 80) 00:30
                ; 2 [80, 120) 01:30
                ; 24 [960, 1000) 12:00
                ; 24 [1000,) 12:00
                ; i [40*i, 40*i+40) i//2 : 30*(i%2)

                ; 0 [0, 40) 12:00
                ; 1 [40, 80) 12:30
                ; 2 [80, 120) 13:30
                ; 24 [960, 1000) 24:00
                ; 24 [1000,) 24:00
                ; i [40*i, 40*i+40) i//2+12 : 30*(i%2)
