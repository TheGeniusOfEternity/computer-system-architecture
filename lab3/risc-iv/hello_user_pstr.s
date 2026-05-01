     ; ======================================
     ; Hellow User Pascal String Script
     ; Architecture: risc-iv
     ; Recommended Configuration: config.yaml
     ; ======================================

     ; Used registers
     ; a0 - read data (memory-mapped io / buffer)
     ; a1 - write output data

     ; t0 - memory pointer (ptr)
     ; t1 - current symbol
     ; t2 - stop symbol (compare to stop reading loop)

     ; t3 - name size counter
     ; t4 - name size limit

     ; t5 - buffer size
     ; t6 - size of the greeting template

     ; ra - store programm counter


    .data

greeting:        .byte  '?Hello, '
question:        .byte  'What is your name?\n'

overflow_value:  .word  0xFFFFFFFF

input_addr:      .word  0x80
output_addr:     .word  0x84

    .text

    .org 0x100

_start:
    lui      a0, %hi(input_addr)             ; load the upper 20 bits of input_addr address
    addi     a0, a0, %lo(input_addr)         ; load the lower 12 bits of input_addr address & add them to previous 20
    lw       a0, 0(a0)                       ; load value from input_addr (0x80) to a0 register

    lui      a1, %hi(output_addr)            ; load the upper 20 bits of output_addr address
    addi     a1, a1, %lo(output_addr)        ; load the lower 12 bits of output_addr address & add them to previous 20
    lw       a1, 0(a1)                       ; load value from output_addr (0x84) to a0 register

    addi     t2, zero, 0x0A                  ; set '\n' as  stop symbol
    addi     t3, zero, 0x00                  ; reset name size counter to 0x00
    addi     t4, zero, 0x17                  ; set max name size
    addi     t5, zero, 0x20                  ; set max greeting size
    addi     t6, zero, 0x08                  ; set size of greeting template

write_question:
    addi     t0, zero, question              ; set ptr to question start

    jal      ra, write_symbol_loop           ; call write_symbol_loop procedure

read_name:
    addi     t0, zero, greeting              ; set ptr to buffer start
    addi     t0, t0, 0x08                    ; move ptr to skip first part of the greeting

    jal      ra, read_symbol_loop            ; call read_symbol_loop procedure

    addi     t2, zero, 0x21                  ; set stop symbol as '!'
    sb       t2, 0(t0)                       ; write current symbol to buffer

fill_buffer:
    addi     t0, t0, 1                       ; increment ptr after '!'
    addi     t1, zero, 0x5F                  ; set current symbol as '_'

    jal      ra, fill_buffer_loop            ; call fill_buffer_loop procedure

write_greeting:
    addi     t0, zero, greeting              ; set ptr to greeting start
    add      t3, t3, t6                      ; add name size and template size
    sb       t3, 0(t0)                       ; store greeting size to buffer

    addi     t0, t0, 0x01                    ; increment ptr to skip greeting size byte
    jal      ra, write_symbol_loop           ; call write_symbol_loop procedure

finish:
    halt                                     ; stop the program

overflow:
    lui      t0, %hi(overflow_value)         ; load the upper 20 bits of overflow_value address
    addi     t0, t0, %lo(overflow_value)     ; load the lower 12 bits of overflow_value address & add them to previous 20
    lw       t0, 0(t0)                       ; load value by overflow_value address to t0

    sw       t0, 0(a1)                       ; write overflow value to buffer
    j        finish                          ; goto finish

    ; ------- Procedures --------

    ; ------- Read symbol -------

read_symbol_loop:
    lb       t1, 0(a0)                       ; load current symbol from input

    beq      t1, t2, read_symbol_loop_end    ; compare current symbol with stop symbol, if equal then stop reading

    sb       t1, 0(t0)                       ; write current symbol to buffer
    addi     t0, t0, 1                       ; increment ptr
    addi     t3, t3, 1                       ; increment name counter

    j        read_symbol_loop                ; goto read_symbol_loop

read_symbol_loop_end:
    bgt      t3, t4, overflow                ; compare read count with limit, if limit is less then goto overflow
    jr       ra                              ; return to pс stored in ra

    ; ------- Write symbol -------

write_symbol_loop:
    lb       t1, 0(t0)                       ; load current symbol from data by ptr
    sb       t1, 0(a1)                       ; write current symbol to output
    addi     t0, t0, 1                       ; increment ptr

    bne      t1, t2, write_symbol_loop       ; compare current symbol with stop symbol, if not equal then continue writing
    jr       ra                              ; return to pc stored in ra

    ; ------- Fill buffer -------

fill_buffer_loop:
    beq      t0, t5, fill_buffer_loop_end    ; compare ptr with buffer size, if equal then stop filling
    sb       t1, 0(t0)                       ; write current symbol to buffer by ptr
    addi     t0, t0, 0x01                    ; increment ptr
    j        fill_buffer_loop                ; goto fill_buffer_loop

fill_buffer_loop_end:
    jr       ra                              ; return to pc stored in ra