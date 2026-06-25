; vim: filetype=msp
; vim: path+=$CCS/ccs_base/msp430/include/

                .cdecls C,LIST,"msp430.h"
                .include "timer_b0.inc"
                .include "systick.inc"

                .bss    current,2,2

                .text
                .def    LCNTL_init
LCNTL_init:
                .asmfunc
                call    #Timer_B0_init
                bis.b   #BIT1,&P1OUT
                bis.b   #BIT1,&P1DIR
                mov.w   #0,&current
                mov.w   #0,R12
                mov.w   #0,R13
                call    #Timer_B0_set_duty
                call    #Timer_B0_enable_output
                ret
                .endasmfunc

                .text
                .def    LCNTL_deinit
LCNTL_deinit:
                .asmfunc
                call    #Timer_B0_disable_output
                mov.w   #0,R12
                mov.w   #0,R13
                call    #Timer_B0_set_duty
                bic.b   #BIT1,&P1DIR
                bic.b   #BIT1,&P1OUT
                ret
                .endasmfunc

                .text
                .def    LCNTL_transition
LCNTL_transition:
                .asmfunc
; (target->R12, step->R13, interval_ms->R14) -> (error->R12)
                push    R4
                push    R5
                push    R6
                push    R7
                .asg    R4,flags
                mov.w   R12,R5
                .asg    R5,target
                mov.w   R13,R6
                .asg    R6,step
                mov.w   R14,R7
                .asg    R7,interval_ms

                cmp.w   #201,target
                jhs     error?
                tst.w   step
                jz      error?
                tst.w   interval_ms
                jz      error?

                clr.w   flags
                tst.w   step ; N or notN
                bit.w   #N,SR
                adc.w   flags
                cmp.w   target,&current ; hs/C or lo/notC
                jnz     $2
                jmp     end?
$2:
                ; C(0) + N(0) | C(1) + N(1)
                ; flags.0 => direction validity
                ; flags.1 => direction up(0)/down(1) (if valid).
                ;            same as N state after "tst.w step".
                adc.w   flags
                bit.w   #BIT0,flags
                jnz     error?

loop?:
                add.w   step,&current
                bit.w   #BIT1,flags
                jz      $1
                jmp     $3

$1:
                ; upward
                cmp.w   &current,target
                jc      $5
                mov.w   target,&current
                jmp     $5

$3:
                ; downward
                cmp.w   target,&current
                jc      $5
                mov.w   target,&current
                jmp     $5

$5:
                ; Total: 0~100/101~200
                ; Warm:  0~ 50/ 49~  0
                ; Cold:  0~  0/  1~ 50
                cmp.w   #101,&current
                jhs     $6
                ; Total in [0, 100]
                mov.w   &current,R12
                clr.w   R13
                call    #Timer_B0_set_duty
                tst.w   R12
                jn      error?
                jmp     $7
$6:
                ; Total in [101~200]
                mov.w   #200,R12
                sub.w   &current,R12
                mov.w   &current,R13
                sub.w   #100,R13
                call    #Timer_B0_set_duty
                tst.w   R12
                jn      error?
                jmp     $7

$7:
                mov.w   interval_ms,R12
                call    #SYSTICK_delay_ms

                cmp.w   &current,target
                jnz     loop?

                .unasg  flags
                .unasg  target
                .unasg  step
                .unasg  interval_ms
end?:
                mov.w   #0,R12
                pop     R7
                pop     R6
                pop     R5
                pop     R4
                ret
error?:
                mov.w   #-1,R12
                pop     R7
                pop     R6
                pop     R5
                pop     R4
                ret
                .endasmfunc
