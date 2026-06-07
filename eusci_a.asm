; vim: filetype=msp
; vim: path+=$HOME/.local/share/ti/ccs2050/ccs/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "eusci_a.inc"

                .text
                .def eUSCI_A0_init
eUSCI_A0_init:  .asmfunc
                bis.b   #UCSWRST_L,&UCA0CTLW0_L
                mov.w   #UCSWRST__ENABLE+UCSSEL__SMCLK+UCSPB_0,&UCA0CTLW0
; UCOS16=1, UCBRx=6, UCBRFx=13, UCBRSx=0x22 -> 9600baud@1048576hz
                mov.w   #6,&UCA0BRW
                mov.w   #2200h+00D0h+UCOS16,&UCA0MCTLW
                bis.b   #BIT7,&P1SEL0
                bis.b   #BIT6,&P1SEL0
                bic.b   #UCSWRST_L,&UCA0CTLW0_L
                ret
                .endasmfunc

                .def eUSCI_A0_transmit
eUSCI_A0_transmit: .asmfunc
; (buf->R12,n->R13,type->R14,format->R15) -> ()
WAIT_SOH?:      bit.b   #UCTXIFG_L,&UCA0IFG_L
                jz      WAIT_SOH?
                mov.b   #ASCII_SOH,&UCA0TXBUF_L
WAIT_TYPE?:     bit.b   #UCTXIFG_L,&UCA0IFG_L
                jz      WAIT_TYPE?
                mov.b   R14,&UCA0TXBUF_L
WAIT_FORMAT?:   bit.b   #UCTXIFG_L,&UCA0IFG_L
                jz      WAIT_FORMAT?
                mov.b   R15,&UCA0TXBUF_L
WAIT_LENGTH_H?: bit.b   #UCTXIFG_L,&UCA0IFG_L
                jz      WAIT_LENGTH_H?
                swpb    R13
                mov.b   R13,&UCA0TXBUF_L
WAIT_LENGTH_L?: bit.b   #UCTXIFG_L,&UCA0IFG_L
                jz      WAIT_LENGTH_L?
                swpb    R13
                mov.b   R13,&UCA0TXBUF_L
WAIT_STX?:      bit.b   #UCTXIFG_L,&UCA0IFG_L
                jz      WAIT_STX?
                mov.b   #ASCII_STX,&UCA0TXBUF_L
WAIT_DATA?:     bit.b   #UCTXIFG_L,&UCA0IFG_L
                jz      WAIT_DATA?
                tst.w   R13
                jz      WAIT_ETX?
                dec.w   R13
                mov.b   @R12+,&UCA0TXBUF_L
                jmp     WAIT_DATA?
WAIT_ETX?:      bit.b   #UCTXIFG_L,&UCA0IFG_L
                jz      WAIT_ETX?
                mov.b   #ASCII_ETX,&UCA0TXBUF_L
WAIT_EOT?:      bit.b   #UCTXIFG_L,&UCA0IFG_L
                jz      WAIT_EOT?
                mov.b   #ASCII_EOT,&UCA0TXBUF_L
                ret
                .endasmfunc
