; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                ; DataTable -> DT

                .global DT_store
                ; (key@R12,value@R13) -> (error@R12)
                .global DT_load
                ; (key@R12) -> (error@R12,value@R13)

                .asg    0,DT_UIN_TZ
                .asg    0,DT_UIN_SR
                .asg    0,DT_UIN_SS

                .asg    0,DT_GNSS_TICK_L
                .asg    0,DT_GNSS_TICK_H
                .asg    0,DT_GNSS_HH
                .asg    0,DT_GNSS_MM
                .asg    0,DT_GNSS_SS
