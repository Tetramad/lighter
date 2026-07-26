; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                ; User INput -> UIN

                .global UIN_init
                ; () -> ()
                .global UIN_begin
                ; () -> ()
                .global UIN_end
                ; () -> ()

                .global UIN_read_and_decode
                ; () -> (error@R12)

                .global UIN_timezone
                ; () -> (error@R12, timezone_shhmmq@R13)
                .global UIN_sunrise
                ; () -> (error@R12, sunrise_shhmmq@R13)
                .global UIN_sunset
                ; () -> (error@R12, sunset_shhmmq@R13)

                ; timezone
                ; c = clamp(raw, [20, 980))
                ; c20th = floor(c / 20)
                ; floor(c20th / 2) - 12 -> hours
                ; (c20th mod 2) xor (c20th < 24) -> minutes / 30

                ; time (firse half)
                ; c = clamp(raw, [0, 1000))
                ; c40th = floor(c / 40)
                ; floor(c40th / 2) -> hours
                ; c40th % 2 -> minutes / 30

                ; time (second half)
                ; c = clamp(raw, [0, 1000))
                ; c40th = floor(c / 40)
                ; floor(c40th / 2) + 12 -> hours
                ; c40th % 2 -> minutes / 30
