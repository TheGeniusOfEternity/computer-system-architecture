     ; ======================================
     ; Format String Script
     ; Architecture: m68k
     ; Recommended Configuration: config.yaml
     ; ======================================

    .data

input_addr:      .word  0x80
output_addr:     .word  0x84

input_buffer:    .word  0x550

plus_limit:      .byte  '2' , '1' , '4' , '7' , '4' , '8' , '3' , '6' , '4' , '7'
minus_limit:     .byte  '2' , '1' , '4' , '7' , '4' , '8' , '3' , '6' , '4' , '8'

    .text

    .org     0x100

_start:
    movea.l  input_addr, A0                  ; A0 <- address of input_addr
    movea.l  (A0), A0                        ; A0 <- value at input_addr

    movea.l  output_addr, A1                 ; A1 <- address of output_addr
    movea.l  (A1), A1                        ; A1 <- value at output_addr

    move.l   0x00, D1                        ; clear D1 (format str size counter)
    move.l   0x00, D2                        ; clear D2 (placeholders count)
    move.l   0x00, D3                        ; clear D3 (read nums count)

    movea.l  input_buffer, A2                ; A2 <- address of input_buffer
    movea.l  (A2), A3                        ; A3 <- value of input_buffer, current position in input_buffer (for input)
    movea.l  (A2), A4                        ; A4 <- value of input_buffer, nums pointer in input_buffer
    movea.l  (A2), A5                        ; A5 <- value of input_buffer, placeholder pointer in input_buffer
    move.l   (A2), D6                        ; A5 <- value of input_buffer, placeholder pointer in input_buffer

    movea.l  (A2), A2                        ; A2 <- value of input_buffer, current position in input_buffer (for output)

read_format_str:
    move.l   (A0), D0                        ; load current symbol

    cmp.b    0x0A, D0                        ; compare current symbol with "\n"
    beq      check_size                      ; if current symbol was "\n" then goto check_size

    move.l   D0, (A3)+                       ; copy symbol to buffer and increase current position in input_buffer
    move.l   D0, (A4)+                       ; copy symbol to buffer and increase current position in input_buffer
    add.l    1, D1                           ; increase format str size

    jmp      read_format_str                 ; goto start of the loop

check_size:
    cmp.l    0x00, D1                        ; compare format str size with 0
    beq      error                           ; if D1 == 0 then goto error

    cmp.l    0x20, D1                        ; compare format str size with 32
    bgt      error                           ; if D1 > 32 then goto error

    move.l   D0, (A3)+                       ; copy current symbol ("\n") to input buffer, now A3 points to nums start
    move.l   D0, (A4)+                       ; copy symbol to buffer and increase current position in input_buffer

check_ph:
    move.l   (A5)+, D0                       ; load symbol from buffer
    add.l    0x04, D6                        ; increment address

    cmp.b    0x0A, D0                        ; compare current symbol with "\n"
    beq      prepare_read_num                ; if current symbol was "\n" then goto prepare_read_num

    cmp.b    0x25, D0                        ; compare current symbol with "%"
    bne      check_ph                        ; if current symbol was not "%" then goto next iteration

    move.l   (A5)+, D0                       ; load symbol from buffer
    add.l    0x04, D6                        ; increment address

    cmp.b    0x2D, D0                        ; compare current symbol with "-"
    bne      check_ph_digit                  ; if current symbol was not "-" then goto digits check

    move.l   (A5)+, D0                       ; load symbol ("d" or digit) after "-"
    add.l    0x04, D6                        ; increment address

check_ph_digit:
    cmp.b    0x30, D0                        ; compare current symbol with "0"
    blt      invalid_ph                      ; if current symbol < "0" (lexically) then goto next iteration

    cmp.b    0x64, D0                        ; compare current symbol with "d"
    beq      count_ph                        ; if current symbol was "d" then goto count_ph

    cmp.b    0x39, D0                        ; compare current symbol with "9"
    bgt      invalid_ph                      ; if current symbol > "9" (lexically) then goto next iteration

    move.l   (A5)+, D0                       ; load symbol ("d" or digit)
    add.l    0x04, D6                        ; increment address
    jmp      check_ph_digit                  ; goto next digit

invalid_ph:
    move.l   -(A5), D0                       ; load previous symbol
    sub.l    0x04, D6                        ; increment address
    jmp      check_ph                        ; goto next placeholder

count_ph:
    add.l    1, D2                           ; increment placeholders count
    jmp      check_ph                        ; goto next placeholder

prepare_read_num:
    move.l   0x00, D4                        ; clear D4 - length of current num

read_num:
    cmp.b    0x00, D2                        ; compare amount of placeholders with 0
    beq      check_end                       ; if amount of placeholders is 0 then goto check_end
    move.l   (A0), D0                        ; load current symbol

    cmp.b    0x0A, D0                        ; compare current symbol with '\n'
    beq      read_num_end                    ; if current symbol was "\n" then goto read_num_end

    cmp.b    0x2D, D0                        ; compare current symbol with '-'
    beq      read_num_confirm                ; if current symbol is '-' then goto read_num_confirm

    cmp.b    0x39, D0                        ; compare current symbol with "9"
    bgt      error                           ; if current symbol > "9" (lexically) then goto error

    cmp.b    0x30, D0                        ; compare current symbol with "0"
    blt      error                           ; if current symbol < "0" (lexically) then goto error


read_num_confirm:
    move.l   D0, (A3)+                       ; copy symbol to buffer and increase current position in input_buffer
    add.l    0x01, D4                        ; increment length counter

    jmp      read_num                        ; goto start of the loop

read_num_end:
    cmp.b    0x00, D4                        ; compare D4 with 0
    beq      error                           ; if length of current num is 0 then goto error

    move.l   D0, (A3)+                       ; copy "\n" to input_buffer
    add.l    1, D3                           ; increment read nums count

    cmp.l    D2, D3                          ; compare read nums count and placeholders count
    bne      prepare_read_num                ; if read nums count != placeholders count then goto prepare_read_num

prepare_check_num:
    move.l   (A4)+, D0                       ; load "\n" after format_str or last num

    cmp.b    0x00, D3                        ; compare D3 (amount of unchecked nums) with 0
    beq      check_end                       ; if all nums were checked then goto check_end

    move.l   0, D1                           ; clear D1, current num's digits counter
    sub.l    1, D3                           ; decrement D3 (amount of unchecked nums)

    movea.l  plus_limit, A5                  ; A5 <- address of plus_limit

    cmp.b    0x2D, D0                        ; compare current symbol with "-"
    bne      check_plus                      ; if current symbol is not "-" then goto digits iteration

    movea.l  minus_limit, A5                 ; A5 <- address of minus_limit
    jmp      check_digit                     ; goto check_digit

check_plus:
    move.l   -(A4), D0                       ; load "\n" after format_str or last num

check_digit:
    move.l   (A4)+, D0                       ; load current symbol from input_buffer
    move.b   (A5)+, D5                       ; load current symbol from limit

    cmp.b    0x0A, D0                        ; compare current symbol with "\n"
    beq      check_num_end                   ; if current symbol is "\n" then goto check_num

    add.l    1, D1                           ; increment digits count

    cmp.b    0x39, D0                        ; compare current symbol with "9"
    bgt      error                           ; if current symbol > "9" (lexically) then goto error

    cmp.b    0x30, D0                        ; compare current symbol with "0"
    blt      error                           ; if current symbol < "0" (lexically) then goto error
    bne      compare_limit                   ; if current symbol is not "0" then goto compare_limit

    cmp.b    0x01, D1                        ; compare D1 with 1
    beq      error                           ; if D1 is 1, which means that first digit is zero, then goto error

compare_limit:
    cmp.b    D5, D0                          ; compare current symbol with limit symbol
    blt      a1_less                         ; if D0 < D5 then goto a1_less
    bgt      a1_greater                      ; if D0 > D5 then goto a1_greater

    jmp      check_digit                     ; goto check_digit

a1_less:
    move.l   -1, D4                          ; set D4 = -1 (D0 is less than D5)
    jmp      check_digit                     ; goto check_digit

a1_greater:
    move.l   1, D4                           ; set D4 = -1 (D0 is greater than D5)
    jmp      check_digit                     ; goto check_digit

check_num_end:
    cmp.b    0x0A, D1                        ; compare length of num with 10
    blt      prepare_check_num               ; if num's length is less than 10, then goto next num
    bgt      error                           ; if nums's length is greater than 10, then goto error

    cmp.b    0x01, D4                        ; compare D4 with 1
    beq      error                           ; if D4 is 1 then goto to error

check_end:
    movea.l  input_buffer, A0                ; A0 <- address of input_buffer
    move.l   (A0), D3                        ; reset D3 to start of format str
    move.l   (A0), D4                        ; reset D4 to start of format str
    movea.l  D6, A5                          ; load address of nums start from D6 to A5

format_output:
    movea.l  D3, A2                          ; load address to address register
    move.l   (A2), D0                        ; load current symbol from input_buffer

    add.l    0x04, D3                        ; increment address
    add.l    0x04, D4                        ; increment address

    cmp.b    0x0A, D0                        ; compare current symbol with "\n"
    beq      finish                          ; if current symbol was "\n" then goto finish

    cmp.b    0x25, D0                        ; compare current symbol with "%"
    beq      confirm_ph                      ; if current symbol was "%" then goto confirm_ph

    move.l   D0, (A1)                        ; write current symbol to output
    jmp      format_output                   ; goto next iteration

confirm_ph:
    move.l   0x00, D1                        ; clear D1 - alignment direction flag (offset before num by default)
    move.l   0x00, D5                        ; clear D5 - offset width / placeholder invalid flag
    move.l   0x00, D7                        ; clear D6 - num's length
    move.l   D6, D2                          ; address of current digit of current num

    movea.l  D4, A3                          ; load address to address register
    move.l   (A3), D0                        ; load current symbol from input_buffer

    cmp.b    0x2D, D0                        ; compare current symbol with "-"
    bne      compute_offset                  ; if current symbol was not "-" then goto compute_offset

    move.l   0x01, D1                        ; set alignment direction flag (num before offset)
    add.l    0x04, D4                        ; increment address (load next "d" or digit after "-")

compute_offset:
    movea.l  D4, A3                          ; load address to address register
    move.l   (A3), D0                        ; load current symbol ("d" or digit)

    cmp.b    0x30, D0                        ; compare current symbol with "0"
    blt      confirm_ph_fail                 ; if current symbol < "0" (lexically) then goto next iteration

    cmp.b    0x64, D0                        ; compare current symbol with "d"
    beq      evaluate_num                    ; if current symbol was "d" then goto evaluate_num

    cmp.b    0x39, D0                        ; compare current symbol with "9"
    bgt      confirm_ph_fail                 ; if current symbol > "9" (lexically) then goto next iteration

    sub.l    0x30, D0                        ; convert 'number' to number
    mul.l    0x10, D5                        ; multiply offset width by 10
    add.l    D0, D5                          ; add current digit to offset width

    add.l    0x04, D4                        ; increment address (load next "d" or digit)

    jmp      compute_offset                  ; goto next digit

confirm_ph_fail:
    sub.l    0x04, D3                        ; decrement address
    movea.l  D3, A2                          ; load address to address register

    move.l   (A2), (A1)                      ; write current symbol to output
    add.l    0x04, D3                        ; increment address

    move.l   0xFF, D5                        ; set placeholder is invalid flag = true
    jmp      sync_check                      ; goto sync_check

sync_check:
    cmp.b    D3, D4                          ; compare A2 address with A3 address
    beq      format_output                   ; if A2 == A3 then goto format_output

    cmp.b    0xFF, D5                        ; compare D5 with -1
    beq      sync_A3                         ; if D2 == -1 (placeholder is invalid) then goto sync_A3

    jmp      sync_A2                         ; goto sync_A2

sync_A2:
    add.l    0x04, D3                        ; increment address
    jmp      sync_check                      ; goto sync_check

sync_A3:
    sub.l    0x04, D4                        ; decrement address
    jmp      sync_check                      ; goto sync_check

evaluate_num:
    movea.l  D2, A6                          ; load address
    move.l   (A6)+, D0                       ; load symbol of current num

    cmp.b    0x0A, D0                        ; compare D0 with '\n'
    beq      adjust_offset                   ; if D0 == '\n' then goto adjust_offset

    add.l    0x01, D7                        ; increment num's length
    add.l    0x04, D2                        ; increment address of current digit in current num
    jmp      evaluate_num                    ; goto next iteration


adjust_offset:
    sub.l    D7, D5                          ; substact num's length from total offset
    cmp.b    0x00, D5                        ; compare D5 with 0
    bgt      write_num                       ; if D5 >= 0 (difference is non-negative) then goto write num

    move.l   0x00, D5                        ; set offset width to 0
    jmp      write_num                       ; goto write_num

write_num:
    cmp.b    0x00, D1                        ; compare D1 with 0 (check alignment direction)
    beq      write_offset                    ; if alignment direction flag is not set then goto write_offset

    move.l   (A5)+, D0                       ; load symbol of current num
    add.l    0x04, D6                        ; increment address of curreте digits in nums

    cmp.b    0x0A, D0                        ; compare D0 with '\n'
    beq      confirm_num                     ; if D0 == '\n' then goto confirm_num

    move.l   D0, (A1)                        ; write symbol to the output
    jmp      write_num                       ; goto next iteration

confirm_num:
    move.l   0xFF, D7                        ; set num was written flag true
    cmp.b    0x01, D1                        ; compare D1 with 1 (check alignment direction)
    beq      write_offset                    ; if alignment direction flag is set then goto write_offset

    add.l    0x04, D4                        ; decrement address
    movea.l  D4, A3                          ; load address to address register
    jmp      sync_check                      ; goto sync_check

write_offset:
    cmp.b    0x00, D5                        ; compare D5 with 0 (check remaining offset to write)
    beq      confirm_offset                  ; if D5 == 0 then goto confirm_offset

    move.l   0x20, (A1)                      ; write 'space' to the output
    sub.l    0x01, D5                        ; decrement remaining offset width

    jmp      write_offset                    ; goto next iteration

confirm_offset:
    move.l   0xFF, D1                        ; clear alignment direction flag
    cmp.b    0xFF, D7                        ; compare D7 with -1
    bne      write_num                       ; if D7 != -1 (num was not written) then goto write_num
    jmp      confirm_num                     ; goto confirm_num

finish:
    halt                                     ; stop program

error:
    move.l   -1, (A1)                        ; write -1 to output
    jmp      finish                          ; goto finish

