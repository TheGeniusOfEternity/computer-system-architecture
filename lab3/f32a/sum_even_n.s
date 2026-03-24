	\ ======================================
	\ Sum Even N Script
	\ Architecture: f32a
	\ Recommended Configuration: config.yaml
	\ ======================================


	.data

input_addr:	.word	0x80
output_addr:	.word 	0x84

	.text

_start:
 
	@p input_addr a! @	\ n:[]

	dup			\ n:n:[]
	if not_positive		\ n:[]

	dup			\ n:n:[]
	-if prepare_sum		\ n:[]
	
not_positive:
	drop			\ :[]
	lit -1			\ -1:[]
	a!			\ :[], A[-1]

_finish:
	@p output_addr a! !     \ :[], A[]
   	halt

prepare_sum:
	dup			\ n:n:[]
	lit 1			\ n:n:1:[]
	and 			\ n:n&1:[]

	if prepare_num		\ n:[]
	
	lit -1			\ n:-1:[]
	+			\ n-1:[]
prepare_num:
	dup			\ sum:sum:[]
	a!			\ sum:[], A[sum]

calc_loop:
	a			\ sum:num:[]
	lit -2			\ sum:num:-2:[]
	+			\ sum:num-2:[]
	
	dup			\ sum:num-2:num-2:[]
	-if update_sum		\ sum:num-2:[]
	
	a!			\ :[], A[sum]
	_finish ;

update_sum:
	dup			\ sum:new_num:new_num:[]
	a!			\ sum:new_num:[], A[new_num]
	+			\ sum+new_start:[]
	calc_loop ;
 
