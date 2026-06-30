; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "systick.inc"
                .include "datatable.inc"

PARSER_STRUCT:  .struct
run_length:     .uchar
buffer:         .space  3
flags:          .word
hh:             .space  2
mm:             .space  2
ss:             .space  2
sss:            .space  3
checksum:       .uchar
PARSER_SIZE:    .endstruct

parser:         .tag    PARSER_STRUCT
                .bss    parser, PARSER_SIZE
                .bss    time, 8, 2

                .sect   ".const"
GNSS_INIT_CMD:  .string "$PMTK314,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0*35",0Dh,0Ah,0
GNSS_DISTXT_CMD:.string "$PQTXT,W,0,0*22",0Dh,0Ah,0
GNSS_BACKUP_CMD:.string "$PMTK225,4*2F",0Dh,0Ah,0
GNSS_FCOLD_CMD: .string "$PMTK104*37",0Dh,0Ah,0

                .text
                .def    GNSS_begin
GNSS_begin:
; () -> ()
                .asmfunc
                bis.w   #UCSWRST,&UCA0CTLW0
                ; UCOS16=1, UCBRx=6, UCBRFx=13,
                ; UCBRSx=0x22 -> 9600baud@1048576hz
                mov.w   #UCSWRST__ENABLE|UCSSEL__SMCLK|UCSPB_0,&UCA0CTLW0
                mov.w   #6,&UCA0BRW
                mov.w   #2200h|00D0h|UCOS16_1,&UCA0MCTLW
                bic.w   #UCSWRST,&UCA0CTLW0
                bis.w   #UCRXIE,&UCA0IE

                bic.b   #BIT6|BIT7,&P1REN
                bis.b   #BIT6|BIT7,&P1SEL0

                call    #GNSS_wakeup

                mov.w   #1000,R12
                call    #SYSTICK_delay_ms
                mov.w   #GNSS_INIT_CMD,R12
                call    #GNSS_transmit
                mov.w   #GNSS_DISTXT_CMD,R12
                call    #GNSS_transmit

                ret
                .endasmfunc

                .text
                .def    GNSS_end
GNSS_end:
; () -> ()
                .asmfunc
                mov.w   #GNSS_BACKUP_CMD,R12
                call    #GNSS_transmit

                bic.w   #UCRXIE,&UCA0IE

                mov.w   #1000,R12
                call    #SYSTICK_delay_ms

                bic.b   #BIT6|BIT7,&P1SEL0
                bis.b   #BIT6|BIT7,&P1REN
                ret
                .endasmfunc

                .text
                .def    GNSS_wakeup_init
GNSS_wakeup_init:
; () -> ()
                .asmfunc
                bic.b   #BIT6,&P2REN
                bic.b   #BIT6,&P2OUT
                bis.b   #BIT6,&P2DIR
                ret
                .endasmfunc

                .text
                .def    GNSS_wakeup
GNSS_wakeup:
; () -> ()
                .asmfunc
                bis.b   #BIT6,&P2OUT
                mov.w   #1500,R12
                call    #SYSTICK_delay_ms
                bic.b   #BIT6,&P2OUT
                ret
                .endasmfunc

                .text
                .def    GNSS_reset_init
GNSS_reset_init:
; () -> ()
                .asmfunc
                bic.b   #BIT7,&P2REN
                bic.b   #BIT7,&P2OUT
                ret
                .endasmfunc

                .text
                .def    GNSS_reset
GNSS_reset:
; () -> ()
                .asmfunc
                bis.b   #BIT7,&P2DIR
                mov.w   #500,R12
                call    #SYSTICK_delay_ms
                bic.b   #BIT7,&P2DIR
                ret
                .endasmfunc

                .text
                .def    GNSS_timesync
GNSS_timesync:
; () -> (error@R12)
                .asmfunc
                clr.w   &time+6
$2:             cmp.w   #9,&time+6
                jlo     $2
                call    #SYSTICK_get
                push.w  R12
                mov.w   #DT_GNSS_TICK_H,R12
                call    #DT_store
                pop.w   R13
                mov.w   #DT_GNSS_TICK_L,R12
                call    #DT_store
                mov.w   #DT_GNSS_HH,R12
                mov.w   &time+0,R13
                call    #DT_store
                mov.w   #DT_GNSS_MM,R12
                mov.w   &time+2,R13
                call    #DT_store
                mov.w   #DT_GNSS_SS,R12
                mov.w   &time+4,R13
                call    #DT_store
                ret
                .endasmfunc

                .text
                .def    GNSS_reftick
GNSS_reftick:
; () -> (error@R12,tick_l@R13,tick_h@R14)
                .asmfunc
                mov.w   #DT_GNSS_TICK_H,R12
                call    #DT_load
                tst.w   R12
                jn      error?
                push.w  R13
                mov.w   #DT_GNSS_TICK_L,R12
                call    #DT_load
                pop.w   R14
                tst.w   R12
                jn      error?
                ret
error?:
                mov.w   #-1,R12
                ret
                .endasmfunc

                .text
                .def    GNSS_hour
GNSS_hour:
; () -> (error@R12,hour@R13)
                .asmfunc
                mov.w   #DT_GNSS_HH,R12
                call    #DT_load
                ret
                .endasmfunc

                .text
                .def    GNSS_minute
GNSS_minute:
; () -> (error@R12,minute@R13)
                .asmfunc
                mov.w   #DT_GNSS_MM,R12
                call    #DT_load
                ret
                .endasmfunc

                .text
                .def    GNSS_second
GNSS_second:
; () -> (error@R12,second@R13)
                .asmfunc
                mov.w   #DT_GNSS_SS,R12
                call    #DT_load
                ret
                .endasmfunc

                .text
GNSS_transmit:
; (cmd@R12) -> ()
                .asmfunc
LOOP?:          mov.b   @R12,R13
                tst.b   R13
                jz      WAIT_CPT?
WAIT_TX?:       bit.b   #UCTXIFG_L,&UCA0IFG_L
                jz      WAIT_TX?
                mov.b   R13,&UCA0TXBUF_L
                inc.w   R12
                jmp     LOOP?
WAIT_CPT?:      bit.b   #UCTXCPTIFG_L,&UCA0IFG_L
                jz      WAIT_CPT?
                ret
                .endasmfunc

                .sect   ".text:_isr"
                .def    EUSCI_A0_ISR
EUSCI_A0_ISR:
                mov.b   &parser.buffer+1,&parser.buffer+0
                mov.b   &parser.buffer+2,&parser.buffer+1
                mov.b   &UCA0RXBUF_L,&parser.buffer+2
                inc.b   &parser.run_length
                xor.b   &parser.buffer+2,&parser.checksum

                cmp.b   #80,&parser.run_length
                jnc     $1
                clr.b   &parser.run_length
                bis.w   #010b,&parser.flags
                jmp     $0
$1:
                cmp.b   #5,&parser.run_length
                jnz     $2
                cmp.b   #'R',&parser.buffer+0
                jnz     $2
                cmp.b   #'M',&parser.buffer+1
                jnz     $2
                cmp.b   #'C',&parser.buffer+2
                jnz     $2
                bis.w   #001b,&parser.flags
$2:
                cmp.b   #8,&parser.run_length
                jnz     $3
                bit.w   #001b,&parser.flags
                jz      $3
                mov.b   &parser.buffer+1,&parser.hh+0
                mov.b   &parser.buffer+2,&parser.hh+1
$3:
                cmp.b   #10,&parser.run_length
                jnz     $4
                bit.w   #001b,&parser.flags
                jz      $4
                mov.b   &parser.buffer+1,&parser.mm+0
                mov.b   &parser.buffer+2,&parser.mm+1
$4:
                cmp.b   #12,&parser.run_length
                jnz     $5
                bit.w   #001b,&parser.flags
                jz      $5
                mov.b   &parser.buffer+1,&parser.ss+0
                mov.b   &parser.buffer+2,&parser.ss+1
$5:
                cmp.b   #16,&parser.run_length
                jnz     $6
                bit.w   #001b,&parser.flags
                jz      $6
                cmp.b   #'0',&parser.buffer+0
                jnz     $6
                cmp.b   #'0',&parser.buffer+1
                jnz     $6
                cmp.b   #'0',&parser.buffer+2
                jnz     $6
                bis.w   #100b,&parser.flags
$6:
                cmp.b   #'*',&parser.buffer+0
                jnz     $7
                xor.b   &parser.buffer+0,&parser.checksum
                xor.b   &parser.buffer+1,&parser.checksum
                xor.b   &parser.buffer+2,&parser.checksum
                cmp.b   #'A',&parser.buffer+1
                jlo     NONHEX1?
                sub.b   #'A'-'9'+1,&parser.buffer+1
NONHEX1?:       sub.b   #'0',&parser.buffer+1
                cmp.b   #'A',&parser.buffer+2
                jlo     NONHEX2?
                sub.b   #'A'-'9'+1,&parser.buffer+2
NONHEX2?:       sub.b   #'0',&parser.buffer+2
                rla.b   &parser.buffer+1
                rla.b   &parser.buffer+1
                rla.b   &parser.buffer+1
                rla.b   &parser.buffer+1
                xor.b   &parser.buffer+1,&parser.checksum
                xor.b   &parser.buffer+2,&parser.checksum
                tst.b   &parser.checksum
                jz      $7
                bis.w   #010b,&parser.flags
$7:
                cmp.b   #0Dh,&parser.buffer+1
                jnz     $8
                cmp.b   #0Ah,&parser.buffer+2
                jnz     $8
                cmp.b   #101b,&parser.flags
                jnz     $8
                mov.w   &parser.hh,&time+0
                mov.w   &parser.mm,&time+2
                mov.w   &parser.ss,&time+4
                sub.w   #03030h,&time+0
                sub.w   #03030h,&time+2
                sub.w   #03030h,&time+4
                rla.b   &time+0
                add.b   &time+0,&time+1
                rla.b   &time+0
                rla.b   &time+0
                add.b   &time+0,&time+1
                rla.b   &time+2
                add.b   &time+2,&time+3
                rla.b   &time+2
                rla.b   &time+2
                add.b   &time+2,&time+3
                rla.b   &time+4
                add.b   &time+4,&time+5
                rla.b   &time+4
                rla.b   &time+4
                add.b   &time+4,&time+5
                swpb    &time+0
                swpb    &time+2
                swpb    &time+4
                clr.b   &time+1
                clr.b   &time+3
                clr.b   &time+5
                inc.w   &time+6
$8:
                cmp.b   #'$',&parser.buffer+2
                jnz     $0
                clr.b   &parser.run_length
                clr.w   &parser.checksum
                clr.w   &parser.flags
$0:
                reti

                .sect   EUSCI_A0_VECTOR
                .word   EUSCI_A0_ISR
