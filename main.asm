; vim: filetype=msp
; vim: path+=$HOME/.local/share/ti/ccs2050/ccs/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "eusci_a.inc"

                .def    RESET
                .global busy_wait_ms

                .global __STACK_END
                .sect   .stack

GNSS_RESET_ACT  .macro
                bic.b   #BIT7,&P2OUT
                .endm

GNSS_RESET_INA  .macro
                bis.b   #BIT7,&P2OUT
                .endm

GNSS_WAKEUP_ACT .macro
                bis.b   #BIT6,&P2OUT
                .endm

GNSS_WAKEUP_INA .macro
                bic.b   #BIT6,&P2OUT
                .endm

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

                .text
                .retain
                .retainrefs

RESET:          mov.w   #__STACK_END,SP
stop_watchdog:  mov.w   #WDTPW+WDTHOLD,&WDTCTL

                bis.w   #SCG0,SR
                mov.w   #SELREF__REFOCLK,&CSCTL3
                bic.w   #SCG0,SR

FLL_LOCK:       bit.w   #FLLUNLOCK,&CSCTL7
                jnz     FLL_LOCK

config_GPIO:
                bic.b   #BIT2|BIT3,&P1OUT
                bis.b   #BIT2|BIT3,&P1DIR
                bic.b   #BIT6|BIT7,&P2OUT
                bis.b   #BIT6|BIT7,&P2DIR
                GNSS_RESET_INA
                GNSS_WAKEUP_ACT
                bis.b   #BIT0,&P1DIR
                bis.b   #BIT0,&P1SEL1

                bic.w   #LOCKLPM5,&PM5CTL0          ; release GPIO lock

config_eUSCI_A0:
                call    #eUSCI_A0_init
                bis.w   #UCRXIE,&UCA0IE

main:
                eint
                ;mov.w   #GNSS_FCOLD_CMD,R12
                ;call    #transmit
                mov.w   #2000,R12
                call    #busy_wait_ms

                mov.w   #GNSS_INIT_CMD,R12
                call    #transmit

                bis.b   #BIT2,&P1OUT

$1:             
                clr.w   &time+6
                GNSS_WAKEUP_ACT
                mov.w   #1000,R12
                call    #busy_wait_ms
                mov.w   #GNSS_DISTXT_CMD,R12
                call    #transmit
$2:             cmp.w   #9,&time+6
                jlo     $2
                mov.w   #time+0,R12
                mov.w   #1,R13
                mov.w   #PT_INT,R14
                mov.w   #PF_DEC,R15
                call    #eUSCI_A0_transmit
                mov.w   #time+2,R12
                mov.w   #1,R13
                mov.w   #PT_INT,R14
                mov.w   #PF_DEC,R15
                call    #eUSCI_A0_transmit
                mov.w   #time+4,R12
                mov.w   #1,R13
                mov.w   #PT_INT,R14
                mov.w   #PF_DEC,R15
                call    #eUSCI_A0_transmit

                GNSS_WAKEUP_INA
                mov.w   #GNSS_BACKUP_CMD,R12
                call    #transmit
                mov.w   #5000,R12
                call    #busy_wait_ms
                ;jmp     $1

                bis.b   #BIT6|BIT7,&P1DIR
                bis.b   #BIT6|BIT7,&P1SELC
                mov.w   #TBCLGRP_0+CNTL__16+TBSSEL__SMCLK+ID__1+MC__STOP+TBCLR,&TB0CTL
                mov.w   #CLLD_2+CAP__COMPARE+OUTMOD_7+CCIE_0,&TB0CCTL1
                mov.w   #CLLD_2+CAP__COMPARE+OUTMOD_7+CCIE_0,&TB0CCTL2
                mov.w   #1000,&TB0CCR0
                mov.w   #100,&TB0CCR1
                mov.w   #100,&TB0CCR2
                mov.w   #TBIDEX__1,&TB0EX0
                bis.w   #MC__UP,&TB0CTL

                mov.w   #30000,R12
                call    #busy_wait_ms

                bis.b   #BIT6|BIT7,&P1SELC
                jmp     $1

hang?:          jmp     hang?

                .text
transmit:       .asmfunc
; (R12:=cmd:cstring) -> ()
                mov.w   #0,R13
LOOP?:          cmp.b   @R12,R13
                jeq     $0
WAIT?:          bit.b   #UCTXIFG_L,&UCA0IFG_L
                jz      WAIT?
                mov.b   @R12+,&UCA0TXBUF_L
                jmp     LOOP?
$0:             ret
                .endasmfunc

                .sect   ".const"
GNSS_INIT_CMD:  .string "$PMTK314,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0*35",0Dh,0Ah,0
GNSS_DISTXT_CMD:.string "$PQTXT,W,0,0*22",0Dh,0Ah,0
GNSS_BACKUP_CMD:.string "$PMTK225,4*2F",0Dh,0Ah,0
GNSS_FCOLD_CMD: .string "$PMTK104*37",0Dh,0Ah,0

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
                xor.b   #BIT3,&P1OUT
$8:
                cmp.b   #'$',&parser.buffer+2
                jnz     $0
                clr.b   &parser.run_length
                clr.w   &parser.checksum
                clr.w   &parser.flags
$0:
                reti

; Interrupt Vectors
                .sect   RESET_VECTOR
                .word   RESET
                .sect   EUSCI_A0_VECTOR
                .word   EUSCI_A0_ISR
                .end
