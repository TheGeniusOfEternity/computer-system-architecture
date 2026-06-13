     ; ======================================
     ; Sum And Sum Squares Script
     ; Architecture: vliw-iv
     ; Recommended Configuration: config.yaml
     ; ======================================

     ; Used registers
     ; t0 - read data (memory-mapped input)
     ; t1 - write data (memory-mapped output)

     ; t2 - N
     ; t3 - total sum
     ; t4 - square_total sum
     ; t5 - max number

     ; a0   - current number / error code
     ; a1   - square of current number
     ; a2   - new total (before overflow check) sum
     ; a3   - result of overflow check
     ; a4   - temp result of XOR during sign overflow
     ; a5   - new square_total (before overflow check) sum
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
    ; load input_addr to t0 & output_addr to t1
    ; slot 1: initialize total counter (t3)
    ; slot 2: square_total counter     (t4)
    lui t0, %hi(input_addr)          / lui t1, %hi(output_addr)           / nop             / nop

    ; slot 1: initialize total counter (t3)
    ; slot 2: square_total counter     (t4)
    addi t0, t0, %lo(input_addr)     / addi t1, t1, %lo(output_addr)      / nop             / nop

    ; slot 1: initialize total counter (t3)
    nop                              / nop                                / lw t0, 0(t0)    / nop

    ; slot 3: initialize total counter (t3)
    nop                              / nop                                / lw t1, 0(t1)    / nop

    ; slot 1: initialize total counter (t3)
    ; slot 2: square_total counter     (t4)
    ; slot 3: load N to t2
    ; slot 4: check if N < 0 then goto error_negative_n
    addi t3, zero, 0                 / addi t4, zero, 0                   / lw t2, 0(t0)      / blt t2, zero, error_negative_n

    ; slot 1: load upper 20 bits of max_sqrt_val address
    ; slot 4: check if N = 0
    lui t5, %hi(max_sqrt_val)         / nop                                / nop               / beqz t2, loop_end

    ; slot 1: load lower 12 bits of max_sqrt_val address
    addi t5, t5, %lo(max_sqrt_val)    / nop                                / nop               / nop

    ; slot 3: load into t5 value from max_sqrt_val addresss
    nop                               / nop                                / lw t5, 0(t5)      / nop

loop_start:
    ; slot 2: decrement loop counter (t2)
    ; slot 3: read current num from input (t0)
    nop                              / addi t2, t2, -1          / lw a0, 0(t0)      / nop

    ; slot 1: compute x * x
    ; slot 2: compute total + x
    ; slot 4: check if x < 0 then goto x_is_neg
    mul a1, a0, a0                   / add a2, t3, a0           / nop               / bgt a0, zero, x_is_pos

    ; slot 1: a6 = -x
    ; slot 2: goto loop_check
    sub a6, zero, a0                 / nop                      / nop               / j loop_check

x_is_pos:
    ; slot 1: a6 = x
    mv a6, a0                        / nop                      / nop               / nop

loop_check:
    ; slot 1: old_total ^ new_total
    ; slot 2: x ^ new_total
    xor a3, t3, a2                   / xor a4, a0, a2           / nop               / nop

    ; check square overflow - if 46340 < x then x*x is overflow
    ; slot 1: (old_total ^ new_total) & (x ^ new_total)
    ; slot 2: add x*x to square_total
    ; slot 4: check if max number <= x
    and a3, a3, a4                   / add a5, t4, a1           / nop               / blt t5, a6, overflow_detected

    ; apply new values and check total overflow
    ; slot 1: update total sum
    ; slot 2: update square total sum
    ; slot 4: check if overflow flag is true
    mv t3, a2                        / mv t4, a5                / nop               / blt a3, zero, overflow_detected

    ; check square_total overflow
    ; slot 4: check if square_total sum is non-negative
    nop                              / nop                      / nop               / blt a5, zero, overflow_detected

    ; slot 4: check if N != 0
    nop                              / nop                      / nop               / bnez t2, loop_start

loop_end:
    ; slot 3: write total sum
    nop                              / nop              / sw t3, 0(t1) / nop

    ; slot 3: write out square_total sum
    ; slot 4: goto finish
    nop                              / nop              / sw t4, 0(t1) / j finish

error_negative_n:
    ; slot 1: load upper 20 bits of error_neg_code address
    lui a0, %hi(error_neg_code)      / nop              / nop          / nop

    ; slot 1: load lower 12 bits of error_neg_code address
    addi a0, a0, %lo(error_neg_code) / nop              / nop          / nop

    ; slot 3: load error_neg_code value into a0
    nop                              / nop              / lw a0, 0(a0) / nop

    ; slot 3: write out error_neg_code value
    ; slot 4: goto finish
    nop                              / nop              / sw a0, 0(t1) / j finish

overflow_detected:
    ; slot 4: check if N = 0
    nop                              / nop              / nop          / beqz t2, overflow_write_error

    ; slot 2: decrement N
    ; slot 3: load x
    ; slot 4: goto overflow_detected
    nop                              / addi t2, t2, -1  / lw a0, 0(t0) / j overflow_detected

overflow_write_error:
    ; slot 1: load upper 20 bits of error_ovf_code address
    lui a0, %hi(error_ovf_code)      / nop              / nop          / nop

    ; slot 1: load lower 12 bits of error_ovf_code address
    addi a0, a0, %lo(error_ovf_code) / nop              / nop          / nop

    ; slot 3: load error_ovf_code value into a0
    nop                              / nop              / lw a0, 0(a0) / nop

    ; slot 3: write out error_ovf_code value
    nop                              / nop              / sw a0, 0(t1) / nop

finish:
    ; slot 4: stop the program
    nop                              / nop              / nop          / halt