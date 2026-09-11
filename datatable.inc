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

                .asg    6,DT_GNSS_TICK
                .asg    7,DT_GNSS_TIME

                .asg    8,DT_LOG_LATEST_TICK

                .asg    9,DT_LOG_CURRENT_TIME
                .asg    10,DT_LOG_UNTIL_SUNRISE_TIME
                .asg    11,DT_LOG_UNTIL_SUNSET_TIME

                .asg    12,DT_LOG_RESETREASON

                .asg    13,DT_SYSTICK_RTCMOD

                .asg    14,DT_RECORD_LENGTH
