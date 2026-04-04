     ; ======================================
     ; Format String Script
     ; Architecture: m68k
     ; Recommended Configuration: config.yaml
     ; ======================================    

    .data

input_addr:      .word  0x80
output_addr:     .word  0x84
buffer_start:	 .word  0x512   

    .text

_start:
    movea.l  input_addr, A0                  ; A0 <- address of input_addr
    movea.l (A0), A0                         ; A0 <- value at input_addr
 
    movea.l  output_addr, A1                 ; A1 <- address of output_addr
    movea.l  (A1), A1                        ; A1 <- value at output_addr

    move.l 0, D1			     ; clear D1 (format str size counter)

read_format_str:
    cmp.b 0x0A, (A0)			     ; compare current symbol with \n
    beq check_size			     ; if current symbol was \n, goto check_size
    
    add.l 1, D1				     ; increase format str size
    jmp read_format_str			     ; goto start of the loop


check_size:
    cmp.l 0x00, D1		 	     ; compare format str size with 0
    beq error				     ; if D1 == 0 then goto error

    cmp.l 0x20, D1			     ; compare format str size with 32
    bgt error				     ; if D1 > 32 then goto error		

finish:
    halt

error:
    move.l -1, (A1)
    jmp finish



    