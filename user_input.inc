; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                ; User INput -> UIN

                .global UIN_begin
                ; () -> ()
                .global UIN_end
                ; () -> ()

                .global UIN_read_and_decode
                ; () -> (error@R12)

                .global UIN_timezone
                ; () -> (error@R12, timezone_index@R13)
                .global UIN_sunrise
                ; () -> (error@R12, sunrise_index@R13)
                .global UIN_sunset
                ; () -> (error@R12, sunset_index@R13)
