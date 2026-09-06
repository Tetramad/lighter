; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "systick.inc"
                .include "datatable.inc"
                .include "math.inc"
                .include "indicator.inc"

                .bss    index,1,1
                .bss    buffer,3,1
                .bss    flags,1,1
                .asg    0001b,IN_RMC
                .asg    0010b,DATA_VALID
                .asg    0100b,CHECKSUM_PASSED
                .asg    1000b,PARSING_VALID
                .bss    checksum,1,1
                .bss    time,2,2
                .bss    synchronized,2,2

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

                bic.b   #BIT6|BIT7,&P1REN
                bis.b   #BIT6|BIT7,&P1SEL0

                call    #GNSS_wakeup

                ; TODO: better wakeup delay
                delay   #1000

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

                ; TODO: better backup sleep delay
                delay   #1000

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
                delay   #1500
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
                delay   #500
                bic.b   #BIT7,&P2DIR
                ret
                .endasmfunc

                .text
                .def    GNSS_timesync
GNSS_timesync:
; () -> (error@R12)
                .asmfunc
                clr.b   &index
                clr.b   &buffer+2
                clr.b   &buffer+1
                clr.b   &buffer+0
                clr.b   &flags
                clr.b   &checksum
                clr.w   &time
                clr.w   &synchronized

rx_loop?:
                call    #GNSS_rx_processing
                tst.w   &synchronized
                jz      rx_loop?

                ; TODO: error handling
                call    #SYSTICK_get ; -> (systick_l@R12, systick_h@R13)
                push.w  R12
                mov.w   #DT_GNSS_TICK_H,R12
                call    #DT_store
                mov.w   #DT_GNSS_TICK_L,R12
                pop.w   R13
                call    #DT_store
                mov.w   #DT_GNSS_QUATERS,R12
                mov.w   &time,R13
                call    #DT_store

                clr.w   R12
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
                .def    GNSS_reftime
GNSS_reftime:
; () -> (error@R12,quaters@R13)
                .asmfunc
                mov.w   #DT_GNSS_QUATERS,R12
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

                .text
GNSS_rx_processing:
; () -> ()
                .asmfunc
wait_rx?:
                bit.w   #UCRXIFG,&UCA0IFG
                ; TODO: check timeout or use watchdog
                jz      wait_rx?
                mov.b   &buffer+1,&buffer+2
                mov.b   &buffer+0,&buffer+1
                mov.b   &UCA0RXBUF_L,&buffer+0

                ; NOTE: NMEA183 legacy sentence length was 82 include newlines
                cmp.b   #(82+1),&index
                jc      skip_increase_index?
                inc.b   &index
skip_increase_index?:

                xor.b   &buffer,&checksum

                ; NOTE: data using here
                ; data
                ;   buffer[3]
                ;   flags
                ;     IN_RMC
                ;     DATA_VALID
                ;     CHECKSUM_PASSED
                ;     PARSING_VALID
                ;   checksum
                ;   index
                ;   synchronized

                ; NOTE: control logic using here
                ; if (*buffer == '$')
                ;   then reset all
                ; if (buffer == reverse("RMC"))
                ;   then now in rmc sentence
                ; if (INRMC && index == 8)
                ;   then buffer[0:2] has hours in characters
                ; if (INRMC && index == 10)
                ;   then buffer[0:2] has minutes in characters
                ; if (INRMC && index == 12)
                ;   then buffer[0:2] has seconds in characters
                ; if (INRMC && index == 16)
                ;   then buffer has milliseconds in characters
                ; if (INRMC && index == 18)
                ;   then buffer[0] has valitidy in 'A'(valid) or 'D'(differential) or 'V'(invalid)
                ; if (buffer[2] == '*')
                ;   then buffer[0:2] has checksum characters
                ; if (buffer[0:2] == reverse("\r\n"))
                ;   then tranmitting a sentence completed

                cmp.b   #'$',&buffer
                jz      reset_data?

                cmp.b   #'R',&buffer+2
                jnz     rmc_not_matched?
                cmp.b   #'M',&buffer+1
                jnz     rmc_not_matched?
                cmp.b   #'C',&buffer+0
                jz      rmc_matched?
rmc_not_matched?:

                bit.b   #IN_RMC,&flags
                jz      maybe_not_in_rmc?
                cmp.b   #8,&index
                jz      parse_hours?
                cmp.b   #10,&index
                jz      parse_minutes?
                cmp.b   #12,&index
                jz      parse_seconds?
                cmp.b   #16,&index
                jz      parse_milliseconds?
                cmp.b   #18,&index
                jz      parse_data_validity?

maybe_not_in_rmc?:
                cmp.b   #'*',&buffer+2
                jz      check_checksum?
                cmp.b   #0Dh,&buffer+1
                jnz     not_interested?
                cmp.b   #0Ah,&buffer+0
                jz      sentence_complete?
not_interested?:
                ret

reset_data?:
                clr.b   &index
                clr.b   &buffer+2
                clr.b   &buffer+1
                clr.b   &buffer+0
                mov.b   #DATA_VALID|PARSING_VALID,&flags
                clr.b   &checksum
                clr.w   &time
                clr.w   &synchronized
                ret

rmc_matched?:
                bis.b   #IN_RMC,&flags
                ret

parse_hours?:
                mov.b   &buffer+0,R12
                mov.b   &buffer+1,R13
                call    #parse_digit2 ; -> (chr0@R12,chr1@R13) -> (error@R12,n@R13)
                tst.w   R12
                jn      digit_parsing_failed?
                mov.w   R13,R12
                call    #uimul60 ; -> (u@R12)
                rla.w   R12
                rla.w   R12
                add.w   R12,&time
                ret

parse_minutes?:
                mov.b   &buffer+0,R12
                mov.b   &buffer+1,R13
                call    #parse_digit2 ; (chr0@R12,chr1@R13) -> (error@R12,n@R13)
                tst.w   R12
                jn      digit_parsing_failed?
                rla.w   R13
                rla.w   R13
                add.w   R13,&time
                ret

parse_seconds?:
                mov.b   &buffer+0,R12
                mov.b   &buffer+1,R13
                call    #parse_digit2 ; (chr0@R12,chr1@R13) -> (error@R12,n@R13)
                tst.w   R12
                jn      digit_parsing_failed?
                cmp.w   #45,R13
                jnc     seconds_below_45?
                inc.w   &time
seconds_below_45?:
                cmp.w   #30,R13
                jnc     seconds_below_30?
                inc.w   &time
seconds_below_30?:
                cmp.w   #15,R13
                jnc     seconds_below_15?
                inc.w   &time
seconds_below_15?:
                ret

parse_milliseconds?:
                mov.b   &buffer+0,R12
                mov.b   &buffer+1,R13
                mov.b   &buffer+2,R14
                call    #parse_digit3 ; (chr0@R12,chr1@R13,chr2@R14) -> (error@R12,n@R13)
                tst.w   R12
                jn      digit_parsing_failed?
                cmp.w   #0,R13
                jz      data_valid?
                bic.b   #DATA_VALID,&flags ; TODO: remove if not needed.
                ret

parse_data_validity?:
                cmp.b   #'A',&buffer
                jz      data_valid?
                cmp.b   #'D',&buffer
                jz      data_valid?
                bic.b   #DATA_VALID,&flags ; TODO: remove if not needed.
                ret

data_valid?:
                ret

check_checksum?:
                xor.b   &buffer+0,&checksum
                xor.b   &buffer+1,&checksum
                xor.b   &buffer+2,&checksum
                mov.b   &buffer+0,R12
                mov.b   &buffer+1,R13
                call    #parse_hexdigit2 ; (chr0@R12,chr1@R13) -> (error@R12,n@R13)
                tst.w   R12
                jn      digit_parsing_failed?
                cmp.b   R13,&checksum
                jnz     checksum_invalid?
                bis.b   #CHECKSUM_PASSED,&flags
checksum_invalid?:
                ret

sentence_complete?:
                cmp.b   #IN_RMC|DATA_VALID|CHECKSUM_PASSED|PARSING_VALID,&flags
                jnz     sync_invalid?
                inc.w   &synchronized
sync_invalid?:
                ret

digit_parsing_failed?:
                bic.b   #PARSING_VALID,&flags
                ret
                .endasmfunc

; NOTE: chrN for example: 42 -> chr0=2,chr1=4
                .text
parse_digit2:
; (chr0@R12,chr1@R13) -> (error@R12,n@R13)
                .asmfunc
                mov.w   #'0',R14
                call    #parse_digit3
                ret
                .endasmfunc

                .text
parse_digit3:
; (chr0@R12,chr1@R13,chr2@R14) -> (error@R12,n@R13)
                .asmfunc
                sub.w   #'0',R12
                cmp.w   #10,R12
                jc      on_error?
                sub.w   #'0',R13
                cmp.w   #10,R13
                jc      on_error?
                sub.w   #'0',R14
                cmp.w   #10,R14
                jc      on_error?
                push.w  R12
                push.w  R13
                mov.w   R14,R12
                call    #uimul10 ; -> (u@R12)
                add.w   R12,0(SP)
                pop.w   R12
                call    #uimul10 ; -> (u@R12)
                pop.w   R13
                add.w   R12,R13
                clr.w   R12
                ret

on_error?:
                mov.w   #-1,R12
                clr.w   R13
                ret
                .endasmfunc

                .text
parse_hexdigit2:
; (chr0@R12,chr1@R13) -> (error@R12,n@R13)
                .asmfunc
                cmp.w   #'a',R12
                jnc     chr0_not_lowercase?
                sub.w   #'a'-'A',R12
chr0_not_lowercase?:
                cmp.w   #'A',R12
                jnc     chr0_not_uppercase?
                sub.w   #'A'-('9'+1),R12
chr0_not_uppercase?:
                sub.w   #'0',R12
                cmp.w   #16,R12
                jc      on_error?

                cmp.w   #'a',R13
                jnc     chr1_not_lowercase?
                sub.w   #'a'-'A',R13
chr1_not_lowercase?:
                cmp.w   #'A',R13
                jnc     chr1_not_uppercase?
                sub.w   #'A'-('9'+1),R13
chr1_not_uppercase?:
                sub.w   #'0',R13
                cmp.w   #16,R13
                jc      on_error?

                push.w  R12
                mov.w   R13,R12
                call    #uimul16 ; -> (u@R12)
                pop.w   R13
                add.w   R12,R13
                clr.w   R12
                ret

on_error?:
                mov.w   #-1,R12
                clr.w   R13
                ret
                .endasmfunc
