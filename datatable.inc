; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                ; DataTable -> DT

                ; TODO: errors aren't handled in several place.
                .global DT_store
                ; (key@R12,value@R13) -> (error@R12)
                .global DT_load
                ; (key@R12) -> (error@R12,value@R13)

                .asg    0,DT_UIN_TZ_RAW
                .asg    1,DT_UIN_TZ
                .asg    2,DT_UIN_SR_RAW
                .asg    3,DT_UIN_SR
                .asg    4,DT_UIN_SS_RAW
                .asg    5,DT_UIN_SS

                .asg    6,DT_GNSS_TICK_L
                .asg    7,DT_GNSS_TICK_H
                .asg    8,DT_GNSS_QUATERS

                .asg    9,DT_LOG_LATEST_TICK_L
                .asg    10,DT_LOG_LATEST_TICK_H

                .asg    11,DT_LOG_CURRENT
                .asg    12,DT_LOG_TILL_SUNRISE
                .asg    13,DT_LOG_TILL_SUNSET

                .asg    15,DT_LOG_AL
                .asg    16,DT_LOG_AH
                .asg    17,DT_LOG_BL
                .asg    18,DT_LOG_BH

                .asg    19,DT_RECORD_LENGTH
