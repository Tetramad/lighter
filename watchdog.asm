; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"

; VLOCLK = 10kHz
; WDTIS__2G    = 59:39:08.3648
; WDTIS__128M  = 03:43:41.7728
; WDTIS__8192K = 00:13:58.8608
; WDTIS__512K  = 00:00:52.4288
; WDTIS__32K   = 00:00:03.2768
; WDTIS__8192  = 00:00:00.8192
; WDTIS__512   = 00:00:00.0512
; WDTIS__64    = 00:00:00.0064

                .text
                .def    WATCHDOG_init
WATCHDOG_init:
; () -> ()
                .asmfunc
                mov.w   #WDTPW+WDTHOLD__HOLD+WDTCNTCL_1,&WDTCTL
                bis.b   #WDTIE__ENABLE_L,&SFRIE1_L
                ret
                .endasmfunc

                .text
                .def    WATCHDOG_begin
WATCHDOG_begin:
; (interval@R12) -> ()
                .asmfunc
                and.w   #111b,R12
                add.w   #WDTPW+WDTHOLD__UNHOLD+WDTSSEL__VLOCLK+WDTTMSEL_0+WDTCNTCL_1,R12
                mov.w   R12,&WDTCTL
                ret
                .endasmfunc

                .text
                .def    WATCHDOG_end
WATCHDOG_end:
; () -> ()
                .asmfunc
                mov.w   #WDTPW+WDTHOLD__HOLD+WDTCNTCL_1,&WDTCTL
                ret
                .endasmfunc

                .text
                .def    WATCHDOG_feed
WATCHDOG_feed:
; () -> ()
                .asmfunc
                mov.w   &WDTCTL,R12
                bit.w   #WDTHOLD,R12
                jnz     skip_feed?
                mov.b   R12,R12
                bis.w   #WDTPW|WDTCNTCL,R12
                mov.w   R12,&WDTCTL
skip_feed?:
                ret
                .endasmfunc
