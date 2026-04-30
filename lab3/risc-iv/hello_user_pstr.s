     ; ======================================
     ; Hellow User Pascal String Script
     ; Architecture: risc-iv
     ; Recommended Configuration: config.yaml
     ; ======================================

     ; Used registers
     ; t0 - read input data
     ; t1 - write output data
     ; t2 - memory pointer (ptr)
     ; t3 - current symbol
     ; t4 - stop symbol (compare to stop reading loop)

     ; ra - store programm counter


    .data

input_addr:      .word  0x80
output_addr:     .word  0x84

question:        .byte  'What is your name?\n'
greeting:        .byte  'Hello, '

    .text

    .org     0x100

_start:
    lui      t0, %hi(input_addr)             ; load the upper 20 bits of input_addr address
    addi     t0, t0, %lo(input_addr)         ; load the lower 12 bits of input_addr address & add them to previous 20
    lw       t0, 0(t0)                       ; load value from input_addr (0x80) to t0 register

    lui      t1, %hi(output_addr)            ; load the upper 20 bits of output_addr address
    addi     t1, t1, %lo(output_addr)        ; load the lower 12 bits of output_addr address & add them to previous 20
    lw       t1, 0(t1)                       ; load value from output_addr (0x84) to t0 register

write_question:
    addi     t2, t2, question                ; set ptr to question start
    addi     t4, zero, 0x0A                  ; set '\n' as  stop symbol

    jal      ra, write_symbol_loop           ; goto write_symbol_loop procedure

finish:
    halt                                     ; stop the program

write_symbol_loop:
    lb       t3, 0(t2)                       ; load current symbol from memory by ptr
    sb       t3, 0(t3)                       ; write current symbol to output
    sb       t3, 0(t1)                       ; write current symbol to output

    addi     t2, t2, 1                       ; increment ptr
    bne      t3, t4, write_symbol_loop       ; compare current symbol with stop symbol, if not equal, continue reading
    jr       ra                              ; return to pc store in ra