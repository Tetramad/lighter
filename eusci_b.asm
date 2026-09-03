; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "datatable.inc"

                .bss    dbuffer,2,2

                .text
                .def    eUSCI_B0_init
eUSCI_B0_init:
; () -> ()
                .asmfunc
                clr.w   &dbuffer

                bis.w   #UCSWRST,&UCB0CTLW0 ; hold sw reset
                mov.w   #UCMODE_3+UCSWRST_1,&UCB0CTLW0 ; configure to I2C slave
                mov.w   #048h+UCOAEN__ENABLE,&UCB0I2COA0 ; own address as 48h
                bis.b   #BIT2|BIT3,&P1SEL0 ; dio selection
                bic.w   #UCSWRST,&UCB0CTLW0 ; release sw reset
                mov.w   #UCTXIE0_1+UCRXIE0_1,&UCB0IE ; enable interrupts
                ret
                .endasmfunc

                .sect   ".text:_isr"
EUSCI_B0_ISR:
                .asmfunc
                add.w   &UCB0IV,PC
                reti
                jmp     arbitration_lost?
                jmp     not_acknowledgement?
                jmp     start_received?
                jmp     stop_received?
                jmp     slave3_data_received?
                jmp     slave3_transmit_buffer_empty?
                jmp     slave2_data_received?
                jmp     slave2_transmit_buffer_empty?
                jmp     slave1_data_received?
                jmp     slave1_transmit_buffer_empty?
                jmp     data_received?
                jmp     transmit_buffer_empty?
                jmp     byte_count_zero?
                jmp     clock_low_timeout?
                jmp     nineth_bit_position?
arbitration_lost?:
not_acknowledgement?:
start_received?:
stop_received?:
slave3_data_received?:
slave3_transmit_buffer_empty?:
slave2_data_received?:
slave2_transmit_buffer_empty?:
slave1_data_received?:
slave1_transmit_buffer_empty?:
byte_count_zero?:
clock_low_timeout?:
nineth_bit_position?:
                reti
data_received?:
                push.w  R12
                push.w  R13
                push.w  R14
                push.w  R15
                clr.w   &dbuffer
                mov.b   &UCB0RXBUF,R12
                cmp.w   #DT_RECORD_LENGTH,R12
                jhs     out_of_bound?
                call    #DT_load
                tst.w   R12
                jn      data_load_error?
                mov.w   R13,&dbuffer
out_of_bound?:
data_load_error?:
                pop.w   R15
                pop.w   R14
                pop.w   R13
                pop.w   R12
                reti
transmit_buffer_empty?:
                push.w  R12
                mov.w   &dbuffer,R12
                mov.b   R12,&UCB0TXBUF
                swpb    R12
                mov.b   R12,R12
                mov.w   R12,&dbuffer
                pop.w   R12
                reti
                .endasmfunc

                .sect   EUSCI_B0_VECTOR
                .word   EUSCI_B0_ISR
