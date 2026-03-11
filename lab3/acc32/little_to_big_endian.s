     ; ======================================
     ; Little to Big Endian Script
     ; Architecture: acc32
     ; Recommended Configuration: config.yaml
     ; ======================================


    .data

input_addr:      .word  0x80
output_addr:     .word  0x84

const_1:         .word  1                  ; counter step
const_8:         .word  8                  ; constant step for increasing / decreasing shift values
mask:            .word  0xFF               ; mask for specific byte substraction

shr:             .word  24                 ; current value of right shift (0 -> 8 -> 16 -> 16)
shl:             .word  0                  ; current value of left shift (24 -> 16 -> 8 -> 0)

counter:         .word  4                  ; amount of unsubstracted bytes
num:             .word  0                  ; input number
result:          .word  0

    .text

_start:

    load         input_addr
    load_acc                                 ; load into ACC value by address from ACC (acc <- mem[acc])
    store        num

loop:
    load         counter                     ; get amount of unsubstructed bytes to ACC

    beqz         _finish                     ; exit loop if all bytes were substructed (ACC = 0)

    load         num                         ; get address of input number

    shiftr       shr                         ; shift required bytes as the last one
    and          mask                        ; reset other bytes except the last one

    shiftl       shl                         ; move current byte to final position
    or           result                      ; combine with result number
    store        result                      ; update result

    ; Update shift values

    load         shr                         ;
    sub          const_8                     ; decrease by byte
    store        shr                         ; update

    load         shl                         ;
    add          const_8                     ; increase by byte
    store        shl                         ; update

    ; Update counter

    load         counter
    sub          const_1                     ; decrease by 1
    store        counter

    jmp          loop                        ; go to loop start

_finish:
    load         result
    store_ind    output_addr
    halt