     ; ======================================
     ; Sum And Sum Squares Script
     ; Architecture: vliw-iv
     ; Recommended Configuration: config.yaml
     ; ======================================

     ; Used registers
     ; t0 - read data (memory-mapped input)
     ; t1 - write data (memory-mapped output)

     ; t2 - N
     ; t3 - total counter
     ; t4 - square_total counter
     ; t5 - max number

     ; a0   - current number / error code
     ; a1   - square of current number
     ; a2   - new total (before overflow check)
     ; a3   - result of overflow check
     ; a4   - temp result of XOR during sign overflow
     ; a5   - new square_total (before overflow check)
     ; a6   - module x (-x, if x < 0)

    .data
input_addr:      .word  0x80               ; input addr
output_addr:     .word  0x84               ; output addr
max_sqrt_val:    .word  46340              ; max x, those x*x will not occur overflow
error_neg_code:  .word  -1                 ; error code for incorrect input (negative N)
error_ovf_code:  .word  0xCCCCCCCC         ; overflow error code

    .text
    .org 0x100
_start:
    ; load input_addr to t0
    lui t0, %hi(input_addr)          / nop              / nop          / nop
    addi t0, t0, %lo(input_addr)     / nop              / nop          / nop
    nop                              / nop              / lw t0, 0(t0) / nop

    ; load output_addr to t1
    lui t1, %hi(output_addr)         / nop              / nop          / nop
    addi t1, t1, %lo(output_addr)    / nop              / nop          / nop
    nop                              / nop              / lw t1, 0(t1) / nop

    ; load N to t2
    nop                              / nop              / lw t2, 0(t0) / nop

    ; check if N < 0 then goto error_negative_n
    nop                              / nop              / nop          / blt t2, zero, error_negative_n

    ; initialize total counter (t3) and square_total counter (t4)
    addi t3, zero, 0                 / addi t4, zero, 0 / nop          / nop

    ; set upper limit of num in t5
    lui t5, %hi(max_sqrt_val)        / nop              / nop          / nop
    addi t5, t5, %lo(max_sqrt_val)   / nop              / nop          / nop
    nop                              / nop              / lw t5, 0(t5) / nop

loop_while:
    ; check if N == 0 then exit cycle
    nop                              / nop              / nop          / beqz t2, loop_end

    ; slot 2: decrement loop counter (t2)
    ; slot 3: read current num from input (t0)
    nop                              / addi t2, t2, -1  / lw a0, 0(t0) / nop

    ; slot 1: compute x * x
    ; slot 2: compute total + x
    ; slot 4: check if x < 0 then goto x_is_neg
    mul a1, a0, a0                   / add a2, t3, a0   / nop          / blt a0, zero, x_is_neg

    ; x >= 0
    ; prepare to overflow check - (old_total ^ new_total) & (x ^ new_total)
    xor a3, t3, a2                   / xor a4, a0, a2   / nop          / nop

    ; check square overflow - if 46340 < x then x*x is overflow
    and a3, a3, a4                   / add a5, t4, a1   / nop          / blt t5, a0, overflow_detected

    ; apply new values and check total overflow
    mv t3, a2                        / mv t4, a5        / nop          / blt a3, zero, overflow_detected

    ; check square_total overflow
    nop                              / nop              / nop          / blt a5, zero, overflow_detected
    nop                              / nop              / nop          / j loop_while

x_is_neg:
    ; compute module x (a6 = -x) to check square overflow
    sub a6, zero, a0                 / xor a3, t3, a2   / nop          / nop
    xor a4, a0, a2                   / add a5, t4, a1   / nop          / nop
    and a3, a3, a4                   / mv t3, a2        / nop          / blt t5, a6, overflow_detected
    mv t4, a5                        / nop              / nop          / blt a3, zero, overflow_detected
    nop                              / nop              / nop          / blt a5, zero, overflow_detected
    nop                              / nop              / nop          / j loop_while

loop_end:
    ; write result
    nop                              / nop              / sw t3, 0(t1) / nop
    nop                              / nop              / sw t4, 0(t1) / j finish

error_negative_n:
    ; error N < 0
    lui a0, %hi(error_neg_code)      / nop              / nop          / nop
    addi a0, a0, %lo(error_neg_code) / nop              / nop          / nop
    nop                              / nop              / lw a0, 0(a0) / nop
    nop                              / nop              / sw a0, 0(t1) / j finish

overflow_detected:
    ; overflow error, read remaining input
    nop                              / nop              / nop          / beqz t2, overflow_write_error
    nop                              / addi t2, t2, -1  / lw a0, 0(t0) / j overflow_detected

overflow_write_error:
    lui a0, %hi(error_ovf_code)      / nop              / nop          / nop
    addi a0, a0, %lo(error_ovf_code) / nop              / nop          / nop
    nop                              / nop              / lw a0, 0(a0) / nop
    nop                              / nop              / sw a0, 0(t1) / nop

finish:
    nop                              / nop              / nop          / halt