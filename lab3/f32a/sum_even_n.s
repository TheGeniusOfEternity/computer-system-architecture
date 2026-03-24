	\ ======================================
	\ Sum Even N Script
	\ Architecture: f32a
	\ Recommended Configuration: config.yaml
	\ ======================================


	.data

input_addr:	.word	0x80
output_addr:	.word 	0x84
overflow_value:	.word	0xCCCCCCCC

	.text

_start:
 
	@p input_addr a! @	\ n:[]

	dup			\ n:n:[]
	if not_positive		\ n:[]

	dup			\ n:n:[]
	-if prepare		\ n:[]
	
not_positive:
	drop			\ :[]
	lit -1			\ -1:[]

_finish:
	@p output_addr a! !     \ :[], A[]
   	halt

prepare:
	dup			\ :n:n:[]
	lit 1			\ 1:n:n:[]
	and			\ 1&n:n:[]

	if continue		\ n:[]

	lit -1			\ -1:n:[]
	+			\ n-1:[]

continue:
	2/			\ even_num/2:[]
	dup			\ even_num/2:even_num/2:[]
	lit 1			\ 1:k:k:[]
	+			\ k+1:k:[]
	a!			\ k:[], A[k+1]

	multiply		\ sum:[]
	dup			\ sum:sum:[]		

	-if _finish		\ sum:[]

	drop			\ :[]
	@p overflow_value	\ overflow_value:[]

	_finish ;	

multiply:
	lit 0 			\ 0:k:[]
	lit 31 >r		\ for R = 31	
multiply_loop:
	+*			
	next multiply_loop
	drop drop a		\ sum:[], A[]
	;
