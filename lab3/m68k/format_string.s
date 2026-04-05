     ; ======================================
     ; Format String Script
     ; Architecture: m68k
     ; Recommended Configuration: config.yaml
     ; ======================================    

    .data

input_addr:      .word  0x80
output_addr:     .word  0x84

input_buffer:	 .word  0x200 
ph_buffer:	 .word  0x300
output_buffer:   .word  0x400 

    .text

.org 0x100

_start:
    movea.l  input_addr, A0                  ; A0 <- address of input_addr
    movea.l  (A0), A0                        ; A0 <- value at input_addr
 
    movea.l  output_addr, A1                 ; A1 <- address of output_addr
    movea.l  (A1), A1                        ; A1 <- value at output_addr

    move.l   0, D1			     ; clear D1 (format str size counter)
    move.l   0, D2			     ; clear D2 (placeholders count)

    movea.l  input_buffer, A2		     ; A2 <- address of input_buffer
    movea.l  (A2), A3			     ; A3 <- value of input_buffer, current position in input_buffer
    movea.l  (A2), A4			     ; A4 <- value of input_buffer, current position in input_buffer
    movea.l  (A2), A5			     ; A5 <- value of input_buffer, current position in input_buffer

read_format_str:
    move.l   (A0), D0			     ; load current symbol

    cmp.b    0x0A, D0	             	     ; compare current symbol with "\n"
    beq      check_size			     ; if current symbol was "\n" then goto check_size
    
    move.l   D0, (A3)+			     ; copy symbol to buffer and increase current position in input_buffer
    move.l   D0, (A4)+			     ; copy symbol to buffer and increase current position in input_buffer
    add.l    1, D1			     ; increase format str size

    jmp      read_format_str		     ; goto start of the loop

check_size:
    cmp.l    0x00, D1		 	     ; compare format str size with 0
    beq      error			     ; if D1 == 0 then goto error

    cmp.l    0x20, D1			     ; compare format str size with 32
    bgt      error			     ; if D1 > 32 then goto error

    move.l   D0, (A3)+			     ; copy current symbol ("\n") to input buffer, now A3 points to nums start

check_ph:
    move.l   (A5)+, D0			     ; load symbol from buffer    
    
    cmp.b    0x0A, D0		             ; compare current symbol with "\n"
    beq      read_nums			     ; if current symbol was "\n" then goto read_nums

    cmp.b    0x25, D0		     	     ; compare current symbol with "%"
    bne      check_ph		    	     ; if current symbol was not "%" then goto next iteration	
    
    move.l   (A5)+, D0			     ; load symbol from buffer
    cmp.b    0x2D, D0			     ; compare current symbol with "-"
    bne      check_ph_digit		     ; if current symbol was not "-" then goto digits check
	
    move.l   (A5)+, D0			     ; load symbol ("d" or digit) after "-"

check_ph_digit:
    cmp.b    0x30, D0			     ; compare current symbol with "0"
    blt      invalid_ph		             ; if current symbol < "0" (lexically) then goto next iteration

    cmp.b    0x64, D0		     	     ; compare current symbol with "d"
    beq      count_ph			     ; if current symbol was "d" then goto count_ph

    cmp.b    0x39, D0			     ; compare current symbol with "9"
    bgt	     invalid_ph			     ; if current symbol > "9" (lexically) then goto next iteration
    
    move.l   (A5)+, D0			     ; load symbol ("d" or digit)
    jmp      check_ph_digit		     ; goto next digit

invalid_ph:
    move.l   -(A5), D0			     ; load previous symbol
    jmp      check_ph		             ; goto next placeholder

count_ph:
    add.l    1, D2			     ; increment placeholders count
    jmp      check_ph			     ; goto next placeholder

read_nums:
    move.l D2, (A1)
 
finish:
    halt

error:
    move.l -1, (A1)
    jmp finish



    