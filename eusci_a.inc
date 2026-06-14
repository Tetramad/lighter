; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

    .define 00h, PT_RES             ; PACKET_TYPE_RESERVED
    .define 01h, PT_INT             ; PACKET_TYPE_INTEGRAL
        .define 00h, PF_HEX         ;   PACKET_FORMAT_HEXADECIMAL
        .define 01h, PF_DEC         ;   PACKET_FORMAT_DECIMAL
        .define 02h, PF_OCT         ;   PACKET_FORMAT_OCTAL
        .define 03h, PF_BIN         ;   PAKCET_FORMAT_BINARY
    .define 02h, PT_FLOAT           ; PACKET_TYPE_FLOATING_POINT
    .define 03h, PT_FIXED           ; PACKET_TYPE_FIXED_POINT
    .define 04h, PT_ASCII           ; PACKET_TYPE_ASCII_PRINTABLE
    .define 01h, ASCII_SOH
    .define 02h, ASCII_STX
    .define 03h, ASCII_ETX
    .define 04h, ASCII_EOT

    .global eUSCI_A0_init
    .global eUSCI_A0_transmit
