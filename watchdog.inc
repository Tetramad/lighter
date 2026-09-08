; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                ; WDTIS__2G    = 59:39:08.3648
                ; WDTIS__128M  = 03:43:41.7728
                ; WDTIS__8192K = 00:13:58.8608
                ; WDTIS__512K  = 00:00:52.4288
                ; WDTIS__32K   = 00:00:03.2768
                ; WDTIS__8192  = 00:00:00.8192
                ; WDTIS__512   = 00:00:00.0512
                ; WDTIS__64    = 00:00:00.0064

                .global WATCHDOG_init
                ; () -> ()

                .global WATCHDOG_begin
                ; (interval@R12) -> ()
                .global WATCHDOG_end
                ; () -> ()

                .global WATCHDOG_feed
                ; () -> ()
