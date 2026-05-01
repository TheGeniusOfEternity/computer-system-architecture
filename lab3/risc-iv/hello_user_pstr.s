     ; ======================================
     ; Hellow User Pascal String Script
     ; Architecture: risc-iv
     ; Recommended Configuration: config.yaml
     ; ======================================

     ; Used registers
     ; a0 - read input data
     ; a1 - write output data

     ; t0 - memory pointer (ptr)
     ; t1 - current symbol
     ; t2 - stop symbol (compare to stop reading loop)

     ; t3 - name size counter
     ; t4 - name size limit

     ; ra - store programm counter


    .data

overflow_value:  .word  0xFFFFFFFF

input_addr:      .word  0x80
output_addr:     .word  0x84

question:        .byte  'What is your name?\n'
greeting:        .byte  'Hello, '

    .text

    .org     0x200

_start:
    lui      a0, %hi(input_addr)             ; load the upper 20 bits of input_addr address
    addi     a0, a0, %lo(input_addr)         ; load the lower 12 bits of input_addr address & add them to previous 20
    lw       a0, 0(a0)                       ; load value from input_addr (0x80) to a0 register

    lui      a1, %hi(output_addr)            ; load the upper 20 bits of output_addr address
    addi     a1, a1, %lo(output_addr)        ; load the lower 12 bits of output_addr address & add them to previous 20
    lw       a1, 0(a1)                       ; load value from output_addr (0x84) to a0 register

write_question:
    addi     t0, zero, question              ; set ptr to question start
    addi     t2, zero, 0x0A                  ; set '\n' as  stop symbol

    jal      ra, write_symbol_loop           ; call write_symbol_loop procedure

read_name:
    addi     t3, zero, 0x00                  ; reset name size counter to 0x00
    addi     t4, zero, 0x17                  ; set max name size

    addi     t0, zero, greeting              ; set ptr to greeting start
    addi     t0, t0, 0x07                    ; move ptr to greeting end

    jal      ra, read_symbol_loop            ; call read_symbol_loop procedure

finish:
    halt                                     ; stop the program

overflow:
    lui      t0, %hi(overflow_value)         ; load the upper 20 bits of overflow_value address
    addi     t0, t0, %lo(overflow_value)     ; load the lower 12 bits of overflow_value address & add them to previous 20
    lw       t0, 0(t0)                       ; load value by overflow_value address to t0

    sw       t0, 0(a1)                       ; write overflow value to memory
    j        finish                          ; goto finish

    ; ------- Procedures --------

read_symbol_loop:
    lb       t1, 0(a0)                       ; load current symbol from input
    sb       t1, 0(t0)                       ; write current symbol to memory

    addi     t0, t0, 1                       ; increment ptr
    addi     t3, t3, 1                       ; increment name counter

    bne      t1, t2, read_symbol_loop        ; compare current symbol with stop symbol, if not equal, continue reading

    addi     t3, t3, -1                      ; decrement name counter (last symbol, '\n' is not related to name)
    bgt      t3, t4, overflow                ; compare read count with limit, if limit is less then goto overflow

    jr       ra                              ; return to pс stored in ra

write_symbol_loop:
    lb       t1, 0(t0)                       ; load current symbol from memory by ptr
    sb       t1, 0(a1)                       ; write current symbol to output

    addi     t0, t0, 1                       ; increment ptr
    bne      t1, t2, write_symbol_loop       ; compare current symbol with stop symbol, if not equal, continue writing
    jr       ra                              ; return to pc stored in ra