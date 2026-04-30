     ; ======================================
     ; Hellow User Pascal String Script
     ; Architecture: risc-iv
     ; Recommended Configuration: config.yaml
     ; ======================================

    .data

input_addr:      .word  0x80
output_addr:     .word  0x84

buffer_start:    .word  0x90
template:        .byte  'What is your name?\nHello, '

    .text

_start:
    lui t0, %hi(input_addr)           ; load the upper 20 bits of input_addr address
    addi t0, t0, %lo(input_addr)      ; load the lower 12 bits of input_addr address & add them to previous 20
    lw t0, 0(t0)                      ; load value from input_addr (0x80) to t0 register

    lui t1, %hi(output_addr)          ; load the upper 20 bits of output_addr address
    addi t1, t1, %lo(output_addr)     ; load the lower 12 bits of output_addr address & add them to previous 20
    lw t1, 0(t1)                      ; load value from output_addr (0x84) to t0 register

    lw t2, 0(t0)                      ; load value from 0x80 to t0 register
    sw t2, 0(t1)                      ; store value from t0 register to memory by address from t1 register

_finish:
    halt