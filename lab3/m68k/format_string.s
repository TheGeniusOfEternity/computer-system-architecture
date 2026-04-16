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
    beq      read_format_str_end             ; if current symbol was "\n" then goto read_format_str_end

    move.l   D0, (A3)+                       ; copy symbol to buffer and increase current position in input_buffer
    move.l   D0, (A4)+                       ; copy symbol to buffer and increase current position in input_buffer
    add.l    1, D1                           ; increase format str size

    cmp.l    0x20, D1                        ; compare format str size with 32
    bgt      error                           ; if D1 > 32 then goto error

    jmp      read_format_str                 ; goto start of the loop

read_format_str_end:
    cmp.l    0x00, D1                        ; compare format str size with 0
    beq      error                           ; if D1 == 0 then goto error

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
    sub.l    0x04, D6                        ; decrement address
    jmp      check_ph                        ; goto next placeholder

count_ph:
    add.l    1, D2                           ; increment placeholders count
    jmp      check_ph                        ; goto next placeholder

prepare_read_num:
    move.l   0x00, D1                        ; clear D1 - length of current num
    move.l   0x00, D5                        ; clear D5 - is first digit zero flag

    movea.l  plus_limit, A5                  ; load address of plus_limit

read_num:
    cmp.b    0x00, D2                        ; compare amount of placeholders with 0
    beq      read_end                        ; if amount of placeholders is 0 then goto read_end

    move.l   (A0), D0                        ; load current symbol
    move.b   (A5)+, D4                       ; load limit symbol

    cmp.b    0x0A, D0                        ; compare current symbol with '\n'
    beq      read_num_end                    ; if current symbol was "\n" then goto read_num_end

    cmp.b    0x2D, D0                        ; compare current symbol with '-'
    beq      read_num_minus                  ; if current symbol is '-' then goto read_num_confirm

    cmp.b    0x39, D0                        ; compare current symbol with "9"
    bgt      error                           ; if current symbol > "9" (lexically) then goto error

    cmp.b    0x30, D0                        ; compare current symbol with "0"
    blt      error                           ; if current symbol < "0" (lexically) then goto error
    beq      check_length                    ; if digit is "0" then goto check_length

    jmp      compare_limit                   ; goto compare_limit

read_num_minus:
    movea.l  minus_limit, A5                 ; load address of minus_limit
    add.l    0x01, D1                        ; increment length counter

    move.l   D0, (A3)+                       ; write current symbol to input_buffer
    jmp      read_num                        ; goto start of the loop

compare_limit:
    add.l    1, D1                           ; increment digits count

    cmp.b    D4, D0                          ; compare current symbol with limit symbol
    bgt      limit_exceeded                  ; if D0 > D5 then goto limit_exceeded

    move.l   D0, (A3)+                       ; write current symbol to input_buffer
    jmp      read_num                        ; goto check_digit

check_length:
    cmp.b    0x00, D1                        ; compare digits counter with 0
    bne      compare_limit                   ; if num's length > 1 then goto compare_limit

    cmp.b    0x01, D1                        ; compare first digit is zero flag with 0
    beq      error                           ; if true then goto error

    move.l   0x01, D5                        ; set first digit is zero flag
    jmp      compare_limit                   ; goto compare_limit

limit_exceeded:
    cmp.b    0x0A, D1                        ; compare digits counter with 10
    bge      error                           ; if num's length >= 10 then goto error

    move.l   D0, (A3)+                       ; write current symbol to input_buffer
    jmp      read_num                        ; goto read_num

read_num_end:
    cmp.b    0x00, D1                        ; compare D1 with 0
    beq      error                           ; if length of current num is 0 then goto error

    move.l   D0, (A3)+                       ; copy "\n" to input_buffer
    add.l    1, D3                           ; increment read nums count

    cmp.l    D2, D3                          ; compare read nums count and placeholders count
    bne      prepare_read_num                ; if read nums count != placeholders count then goto prepare_read_num

read_end:
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
    mul.l    0x0A, D5                        ; multiply offset width by 10
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
    cmp.l    D3, D4                          ; compare A2 address with A3 address
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
    sub.l    D7, D5                          ; subtract num's length from total offset
    cmp.b    0x00, D5                        ; compare D5 with 0
    bgt      write_num                       ; if D5 >= 0 (difference is non-negative) then goto write num

    move.l   0x00, D5                        ; set offset width to 0
    jmp      write_num                       ; goto write_num

write_num:
    cmp.b    0x00, D1                        ; compare D1 with 0 (check alignment direction)
    beq      write_offset                    ; if alignment direction flag is not set then goto write_offset

    move.l   (A5)+, D0                       ; load symbol of current num
    add.l    0x04, D6                        ; increment address of current digit in current num

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


