; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"

                .bss    done,2,2

                .text
                .def RTC_sleep_ms
RTC_sleep_ms:   .asmfunc
; (ms->R12) -> (error->R12)
                clr.w   &done
                mov.w   R12,&RTCMOD
                mov.w   &RTCIV,R3
                mov.w   #RTCSS__VLOCLK|RTCPS__10|RTCSR_1|RTCIE_1,&RTCCTL
                push    SR
                eint
$1:             tst.w   &done
                jz      $1
                dint
                pop     SR
                mov.w   #RTCSS__DISABLED|RTCPS__1|RTCSR_1|RTCIE_0,&RTCCTL
                clr.w   R12
                ret
                .endasmfunc

                .text
                .def RTC_sleep_s
RTC_sleep_s:    .asmfunc
; (s->R12) -> (error->R12)
                cmp.w   #((0FFFFh + 9) / 10),R12
                jlo     $1
                mov.w   #-1,R12
                ret
$1:
                call    #mul10u
                clr.w   &done
                mov.w   R12,&RTCMOD
                mov.w   &RTCIV,R3
                mov.w   #RTCSS__VLOCLK|RTCPS__1000|RTCSR_1|RTCIE_1,&RTCCTL
                push    SR
                eint
$2:             tst.w   &done
                jz      $2
                dint
                pop     SR
                mov.w   #RTCSS__DISABLED|RTCPS__1|RTCSR_1|RTCIE_0,&RTCCTL
                clr.w   R12
                ret
                .endasmfunc

                .text
mul10u:
                .asmfunc
                push    R4
                rla.w   R12
                mov.w   R12,R4
                rla.w   R12
                rla.w   R12
                add.w   R12,R4
                mov.w   R4,R12
                pop     R4
                ret
                .endasmfunc

                .text
div10u:
                .asmfunc
                push    R4
                push    R5
                push    R6
                clr.w   R4
                mov.w   #0001000000000000b,R5
                mov.w   #1010000000000000b,R6
$2:             cmp.w   R12,R6
                jhs     $1
                sub.w   R6,R12
                add.w   R5,R4
$1:
                clrc
                rrc.w   R5
                clrc
                rrc.w   R6
                tst.w   R5
                jnz     $2
                mov.w   R4,R12
                pop     R6
                pop     R5
                pop     R4
                ret
                .endasmfunc

                .sect   ".text:_isr"
RTC:
                add.w   &RTCIV,PC
                reti
                inc.w   &done
                bic.w   #RTCIE,&RTCCTL
                reti

                .sect   RTC_VECTOR
                .word   RTC
                .end
