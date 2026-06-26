; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                ; Light Control -> LC

                .global LC_begin
                ; () -> ()
                .global LC_end
                ; () -> ()
                .global LC_transit
                ; (warm_step@R12,cold_step@R13) -> (error@R12)

                .global LC_power_init
                ; () -> ()

                .define -1,LC_STEP_OFF
                .define +1,LC_STEP_ON
