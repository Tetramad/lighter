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
                ; () -> (error@R12,reftick@R13)
                .global GNSS_reftime
                ; () -> (error@R12,reftime@R13)
