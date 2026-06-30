; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .global GNSS_begin
                ; () -> ()
                .global GNSS_end
                ; () -> ()

                .global GNSS_wakeup_init
                ; () -> ()
                .global GNSS_wakeup
                ; () -> ()
                .global GNSS_reset_init
                ; () -> ()
                .global GNSS_reset
                ; () -> ()

                .global GNSS_timesync
                ; () -> (error@R12)

                .global GNSS_reftick
                ; () -> (error@R12,tick_l@R13,tick_h@R14)
                .global GNSS_hour
                ; () -> (error@R12,hour@R13)
                .global GNSS_minute
                ; () -> (error@R12,minute@R13)
                .global GNSS_second
                ; () -> (error@R12,second@R13)
