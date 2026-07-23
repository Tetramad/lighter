; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "systick.inc"
                .include "datatable.inc"
                .include "math.inc"

PARSER_STRUCT:  .struct
run_length:     .uchar
buffer:         .space  3
flags:          .word
hh:             .space  2
mm:             .space  2
ss:             .space  2
sss:            .space  3
checksum:       .uchar
time:           .word
                .word
                .word
                .word
PARSER_SIZE:    .endstruct

parser:         .tag    PARSER_STRUCT
                .bss    parser, PARSER_SIZE

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

                delay   #1000
                mov.w   #GNSS_INIT_CMD,R12
                call    #GNSS_transmit
                mov.w   #GNSS_DISTXT_CMD,R12
                call    #GNSS_transmit

                ; delay   #1000
                ; bis.w   #UCRXIE,&UCA0IE

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
                clr.w   &parser.time+6
$2:             cmp.w   #9,&parser.time+6
                jlo     $2
                call    #SYSTICK_get
                push.w  R12
                mov.w   #DT_GNSS_TICK_H,R12
                call    #DT_store
                pop.w   R13
                mov.w   #DT_GNSS_TICK_L,R12
                call    #DT_store
                mov.w   #DT_GNSS_HH,R12
                mov.w   &parser.time+0,R13
                call    #DT_store
                mov.w   #DT_GNSS_MM,R12
                mov.w   &parser.time+2,R13
                call    #DT_store
                mov.w   #DT_GNSS_SS,R12
                mov.w   &parser.time+4,R13
                call    #DT_store
                ret
                .endasmfunc

                .text
                .def    GNSS_timesync_v2
GNSS_timesync_v2:
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
                cmp.b   #82,&index
                jc      skip_increase_index?
                inc.b   &index
skip_increase_index?:

                xor.b   &buffer,&checksum

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
                cmp.b   #'\r',&buffer+1
                jnz     not_interested?
                cmp.b   #'\n',&buffer+0
                jz      sentence_complete?

not_interested?:
                ret

reset_data?:
                clr.b   &index
                clr.b   &buffer+2
                clr.b   &buffer+1
                clr.b   &buffer+0
                mov.b   #PARSING_VALID,&flags
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
                swpb    R13
                add.w   R13,&time
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
                cmp.w   #'A',&buffer
                jz      data_valid?
                cmp.w   #'D',&buffer
                jz      data_valid?
                bic.b   #DATA_VALID,&flags ; TODO: remove if not needed.
                ret

data_valid?:
                bis.b   #DATA_VALID,&flags
                ret

check_checksum?:
                mov.b   &buffer+0,R12
                mov.b   &buffer+1,R13
                call    #parse_hexdigit2 ; (chr0@R12,chr1@R13) -> (error@R12,n@R13)
                tst.w   R12
                jn      digit_parsing_failed?
                cmp.w   R13,&checksum
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

                .end

                .sect   ".text:_isr"
                .def    EUSCI_A0_ISR
EUSCI_A0_ISR:
                mov.b   &parser.buffer+1,&parser.buffer+0
                mov.b   &parser.buffer+2,&parser.buffer+1
                mov.b   &UCA0RXBUF_L,&parser.buffer+2
                inc.b   &parser.run_length
                xor.b   &parser.buffer+2,&parser.checksum

                ; match (run_length, buffer, flags)

                cmp.b   #80,&parser.run_length
                jnc     $1
                ; (>=80, _, _)
                clr.b   &parser.run_length
                bis.w   #010b,&parser.flags
                ; (0, _, FINVAL)
                jmp     done?
$1:
                cmp.b   #5,&parser.run_length
                jnz     $2
                cmp.b   #'R',&parser.buffer+0
                jnz     $2
                cmp.b   #'M',&parser.buffer+1
                jnz     $2
                cmp.b   #'C',&parser.buffer+2
                jnz     $2
                ; (5, "RMC", _)
                bis.w   #001b,&parser.flags
                ; (_, _, FRMC)
$2:
                cmp.b   #8,&parser.run_length
                jnz     $3
                bit.w   #001b,&parser.flags
                jz      $3
                ; (8, _, FRMC && !FINVAL)
                mov.b   &parser.buffer+1,&parser.hh+0
                mov.b   &parser.buffer+2,&parser.hh+1
                ; "_XX" -> hh
$3:
                cmp.b   #10,&parser.run_length
                jnz     $4
                bit.w   #001b,&parser.flags
                jz      $4
                ; (10, _, FRMC && !FINVAL)
                mov.b   &parser.buffer+1,&parser.mm+0
                mov.b   &parser.buffer+2,&parser.mm+1
                ; "_XX" -> mm
$4:
                cmp.b   #12,&parser.run_length
                jnz     $5
                bit.w   #001b,&parser.flags
                jz      $5
                ; (12, _, FRMC && !FINVAL)
                mov.b   &parser.buffer+1,&parser.ss+0
                mov.b   &parser.buffer+2,&parser.ss+1
                ; "_XX" -> ss
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
                ; (16, "000", _)
                bis.w   #100b,&parser.flags
                ; (_, _, FFIXED)
$6:
                cmp.b   #'*',&parser.buffer+0
                jnz     $7
                ; (_, "*__", _)
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
                ; (_, _, FINVAL)
$7:
                cmp.b   #0Dh,&parser.buffer+1
                jnz     $8
                cmp.b   #0Ah,&parser.buffer+2
                jnz     $8
                cmp.b   #101b,&parser.flags
                jnz     $8
                ; (_, "_\r\n", FRMC && !FINVAL && FFIXED)
                mov.w   &parser.hh,&parser.time+0
                mov.w   &parser.mm,&parser.time+2
                mov.w   &parser.ss,&parser.time+4
                sub.w   #03030h,&parser.time+0
                sub.w   #03030h,&parser.time+2
                sub.w   #03030h,&parser.time+4
                rla.b   &parser.time+0
                add.b   &parser.time+0,&parser.time+1
                rla.b   &parser.time+0
                rla.b   &parser.time+0
                add.b   &parser.time+0,&parser.time+1
                rla.b   &parser.time+2
                add.b   &parser.time+2,&parser.time+3
                rla.b   &parser.time+2
                rla.b   &parser.time+2
                add.b   &parser.time+2,&parser.time+3
                rla.b   &parser.time+4
                add.b   &parser.time+4,&parser.time+5
                rla.b   &parser.time+4
                rla.b   &parser.time+4
                add.b   &parser.time+4,&parser.time+5
                swpb    &parser.time+0
                swpb    &parser.time+2
                swpb    &parser.time+4
                clr.b   &parser.time+1
                clr.b   &parser.time+3
                clr.b   &parser.time+5
                inc.w   &parser.time+6
$8:
                cmp.b   #'$',&parser.buffer+2
                jnz     done?
                ; (_, "__$", _)
                clr.b   &parser.run_length
                clr.w   &parser.checksum
                clr.w   &parser.flags
done?:
                reti

                .sect   EUSCI_A0_VECTOR
                .word   EUSCI_A0_ISR
