len: equ 5
buffer_size: equ 80
section .rodata
        input_string:   db "calc:", 32 , 0         ;input stream
	overflow_error: db "Error: Operand Stack Overflow",10,0
	underflow_error: db "Error: Insufficient Number of Arguments on Stack", 10, 0
	y_error: db "wrong Y value", 10, 0
	format_hex: db "%X", 0
	format_hex2: db "%02X", 0
	format_hex3: db "%X", 10, 0
	format_debug: db "###DEBUG_MODE### - Result of operation: ", 0
	format_debug_input: db "###DEBUG_MODE### - input from user: %s", 10, 0
	newLine: db 10, 0
	format_number: db "%d", 10, 0
	array_of_ones: 
	%macro print_error 1
		pushad
		push %1
		push dword [stdout]
		call fprintf
		add esp,8
		popad
	%endmacro
	%macro print_newLine 0
		pushad
		push dword newLine
		call printf
		add esp,4
		popad
	%endmacro
section .bss
	op_stack: resd len	;operands stack
	buffer: resb 82
section .data
	dFlag: db 0
	calculations_number: dd 0
	stack_counter: dd 0
	build_list_start_pointer: dd 0
section .text
    align 16
	global main 
	extern printf 
	extern fflush
	extern malloc 
	extern calloc 
	extern free 
	extern gets 
	extern fgets
	extern fprintf
	extern stdin
	extern stdout
	extern stderr

main:
	push ebp
	mov ebp,esp
	pushad
	
	mov eax,[ebp+8]
	mov ebx,[ebp+12]
	cmp eax,1
	je continue_to_calc
	mov ebx, [ebx+4]
	cmp byte[ebx],'-'
	jne continue_to_calc
	
	cmp byte [ebx+1],'d'
	jne continue_to_calc
	inc byte[dFlag]

	
	;------calling myCalc-------
	continue_to_calc:
		call myCalc
	.fin:
		push eax
		push format_hex3
		call printf
		add esp, 8
		popad
		mov esp, ebp
		pop ebp
		ret
		




;--------------------------------------------------Calculator--------------------------------------------------
myCalc:
		push ebp
		mov ebp, esp
		sub esp, 4
		pushad
		input:
			push input_string                       ; push string to stuck
			call printf             
			add esp, 4                      ; remove pushed argument
			push dword stdin                ; stdin input
			push dword buffer_size                   ; max lenght
			push dword buffer               ; input buffer
			call gets
			add esp, 12                     ; restore stack
			cmp byte [dFlag], 0
			je .continue
			pushad
			push buffer
			push format_debug_input
			call printf
			add esp, 8
			popad
			.continue:
			cmp byte [buffer], 'q'
			je .quit
			cmp byte [buffer], '+'
			je .plus
			cmp byte [buffer], '^'
			je .pos_power
			cmp byte [buffer], 'v'
			je .neg_power
			cmp byte [buffer], 'd'
			je .duplicate
			cmp byte [buffer], 'p'
			je .pop_and_print
			cmp byte [buffer], 'n'
			je .number_of_ones
			jmp .build_list
		.fin:
			mov dword eax, [calculations_number]
			mov [ebp-4], eax            ; save the returned value
			popad
			mov eax,[ebp-4]
			mov esp, ebp
			pop ebp
			ret 
;--------------------------------------------------Operations--------------------------------------------------

.neg_power:
	pushad
	call neg_power
	popad
	jmp input
.pos_power:
	pushad
	call pos_power
	popad
	jmp input
.number_of_ones:
	pushad
	call number_of_ones
	popad
	jmp input
.build_list:
	pushad
	call build_list
	popad
	jmp input
.pop_and_print:
	pushad
	call pop_and_print
	popad
	jmp input
.duplicate:
	pushad
	call duplicate
	popad
	jmp input
.plus:
	pushad
	call plus
	popad
	jmp input
	
.quit:
	pushad
	call quit
	popad
	jmp .fin
;--------------------------------------------------Functions--------------------------------------------------
;------------------neg_power------------------
neg_power:
	push ebp
        mov ebp, esp
        pushad
	inc dword [calculations_number]
	cmp dword [stack_counter], 1
	jle .under_flow_error
	mov edx, [stack_counter]
	dec edx
	mov edi, [op_stack + 4*edx]	;x
	dec edx
	mov esi, [op_stack + 4*edx]	;y
	pushad
	push esi
	call LIST_check_num_greater_than_200
	add esp, 4
	cmp eax, 0
	jne .y_greater_error
	mov al, [esi]
	mov esi, edi
	.deviding_loop:
		cmp eax, 0
		je .before_fin
		dec eax
		mov ebx, 0
		mov edx, 0
		clc
		mov edi, esi
		.node_loop:
			shr byte [edi], 1
			setc bl
			shl bl, 7
			cmp edx, 0
			je .skip_first_node
			add byte [edx], bl
			.skip_first_node:
				cmp dword [edi+1], 0
				je .check_last_node
				mov edx, edi
				mov edi, [edi+1]
				jmp .node_loop
	.check_last_node:
		cmp byte [edi], 0
		jne .deviding_loop
		cmp edx, 0
		je .before_fin
		pushad
		push dword[edx+1]
		call free
		add esp, 4
		popad
		mov dword [edx+1], 0
		jmp .deviding_loop
	.y_greater_error:
		print_error y_error
		jmp .fin
	.under_flow_error:
		print_error underflow_error
		jmp .fin
	.before_fin:
		popad
		push esi
		call LIST_free
		add esp, 4
		mov dword [op_stack + 4*edx], edi
		call STACK_pop
		call debug_print
	.fin:
		popad
		mov esp, ebp
		pop ebp
		ret
;---------------/END neg_power----------------
;------------------pos_power------------------
pos_power:
	push ebp
        mov ebp, esp
        pushad
	inc dword [calculations_number]
	cmp dword [stack_counter], 1
	jle .under_flow_error
	mov edx, [stack_counter]
	dec edx
	mov edi, [op_stack + 4*edx]	;x
	dec edx
	mov esi, [op_stack + 4*edx]	;y
	push esi
	call LIST_check_num_greater_than_200
	add esp, 4
	cmp eax, 0
	jne .y_greater_error
	pushad
	mov al, [esi]
	mov esi, edi
	.multiplying_loop:
		cmp eax, 0
		je .before_fin
		dec eax
		mov ebx, 0
		mov edx, 0
		clc
		mov edi, esi
		.node_loop:
			shl byte [edi], 1
			setc bl
			add byte [edi], dl
			adc bl, 0
			mov dl, bl
			cmp dword [edi+1], 0
			je .carry_check
			mov edi, [edi+1]
			jmp .node_loop
	.carry_check:
		cmp ebx, 0
		je .multiplying_loop
		jmp .create_node
	.create_node:
		push eax
		push ebx
		push 5
		call malloc
		add esp, 4
		mov dword [edi+1], eax
		pop ebx
		pop eax
		mov edi, [edi+1]
		mov byte [edi], 1
		mov dword [edi+1], 0
		jmp .multiplying_loop
	.y_greater_error:
		print_error y_error
		jmp .fin
	.under_flow_error:
		print_error underflow_error
		jmp .fin
	.before_fin:
		popad
		push esi
		call LIST_free
		add esp, 4
		mov dword [op_stack + 4*edx], edi
		call STACK_pop
		call debug_print
	.fin:
		popad
		mov esp, ebp
		pop ebp
		ret
;---------------/END pos_power----------------
;------------------number_of_ones------------------
number_of_ones:
	push ebp
        mov ebp, esp
        pushad
	inc dword [calculations_number]
	cmp dword [stack_counter], 0
	je .under_flow_error
	call STACK_pop
	pushad
	mov ecx, 0	;counter of 1'nes
	clc		;clearing carry
	.loop_on_nodes:
		mov ebx, 0
		mov byte bl, [eax]
		.loop_on_node:
			shl bl, 1
			adc ecx, 0
			cmp byte bl, 0
			jne .loop_on_node
		.end_of_node:
			cmp dword [eax+1], 0
			je .build_node
			mov dword eax, [eax+1]
			jmp .loop_on_nodes
	.build_node:
		mov ebx, 0
		mov byte bl, cl
		shr ecx, 8
		push ebx
		push ecx
		push 5
		call malloc
		add esp, 4
		pop ecx
		pop ebx
		mov edi, eax
		mov esi, eax
		mov byte [edi], bl
		.loop:
			cmp ecx, 0
			je .fin
			mov byte bl, cl
			shr ecx, 8
			push ebx
			push ecx
			push 5
			call malloc
			add esp, 4
			pop ecx
			pop ebx
			mov dword [edi+1], eax
			mov edi, eax
			mov byte [edi], bl
			jmp .loop
			
	.under_flow_error:
		print_error underflow_error
		jmp .after_cleaning
	.fin:
		mov dword [eax+1], 0
		mov ebx, [stack_counter]
		mov [op_stack+4*ebx], esi
		inc dword [stack_counter]
		.cleaning:	
			popad
			push eax
			call LIST_free
			add esp, 4
			call debug_print
		.after_cleaning:
			popad
			mov esp, ebp
			pop ebp
			ret
;--------------\END number_of_ones----------------
;------------------build_list------------------
build_list:
	push ebp
        mov ebp, esp
        pushad
	cmp dword [stack_counter], len		;checking if stack has free space
	je .over_flow_error			;if not print overflow error
	mov eax, buffer
	.remove_leading_zeros:
		cmp byte [eax+1], 0
		je .continue
		cmp byte [eax], '0'
		jne .continue
		inc eax
		jmp .remove_leading_zeros
	.continue:
	mov [build_list_start_pointer], eax
	mov esi, 0				;counter of string length
	mov edi, 0				;counter for handle odd\even
	.string_length_loop:
		mov eax, [build_list_start_pointer]
		cmp byte [eax+esi], 0
		je .check_even
		inc esi
		jmp .string_length_loop
	.check_even:
		mov eax, esi	;rest of number
		mov esi, 0	;setting esi to be 0 again
		mov edx, 0	;modulo
		mov ebx, 2	;divider
		div ebx
		cmp edx, 0
		je .create_nodes
	.handle_odd:
		mov ecx, 0
		mov ebx, 0

		push eax
		mov eax, [build_list_start_pointer]
		mov bl, [eax]	;get first char
		pop eax
		sub bl, '0'		;get its numberic value
		inc edi
		cmp bl, 9
		jle .create_node
		sub bl, 7
		jmp .create_node
		
	.create_nodes:
		.get_decimal_from_chars:
			.first_char:
				mov ebx, 0
				push eax
				mov eax, [build_list_start_pointer]
				cmp byte [eax+edi], 0
				je .before_fin_pop
				mov bl, [eax+edi]
				pop eax
				sub bl, '0'
				inc edi
				cmp bl, 9
				jle .second_char
				sub bl, 7
			.second_char:
				shl bl, 4
				mov ecx, 0
				push eax
				mov eax, [build_list_start_pointer]
				mov cl, [eax + edi]
				pop eax
				sub cl, '0'
				inc edi
				cmp cl, 9
				jle .create_node
				sub cl, 7
		.create_node:
			add bl, cl
			push 5
			call malloc
			add esp, 4
			mov byte [eax], bl
			mov dword [eax+1], esi
			mov esi, eax
			jmp .get_decimal_from_chars
			
	.over_flow_error:
		print_error overflow_error
		jmp .fin
	.before_fin_pop:
		pop eax
	.before_fin:
		mov ebx, [stack_counter]
		mov [op_stack+4*ebx], esi
		inc dword [stack_counter]
		call debug_print
	.fin:
		popad
		mov esp, ebp
		pop ebp
		ret
;---------------/END build_list---------------

;----------------pop_and_print----------------
pop_and_print:
	push ebp
        mov ebp, esp
        pushad
	inc dword [calculations_number]
	cmp dword [stack_counter], 0
	je .under_flow_error
	call STACK_pop
	pushad
	push eax
	call LIST_print
	add esp, 4
	print_newLine
	jmp .fin
	.under_flow_error:
		print_error underflow_error
		jmp .after_cleaning
	.fin:
		.cleaning:
			popad
			push eax
			call LIST_free
			add esp, 4
		.after_cleaning:
		popad
		mov esp, ebp
		pop ebp
		ret
;--------------/END pop_and_print--------------

;------------------Duplicate------------------
duplicate:
	push ebp
        mov ebp, esp
        pushad
	inc dword [calculations_number]
	cmp dword [stack_counter], 0
	je .under_flow_error
	cmp dword [stack_counter], len
	je .over_flow_error
	
	call STACK_top
	push eax
	call LIST_hardcopy
	add esp, 4
	mov ebx, [stack_counter]
	mov dword [op_stack + 4*ebx], eax
	inc dword [stack_counter]
	call debug_print
	jmp .fin
		
	.under_flow_error:
		print_error underflow_error
		jmp .fin
	.over_flow_error:
		print_error overflow_error
	.fin:
		popad
		mov esp, ebp
		pop ebp
		ret
;------------------/END Duplicate------------------
;-----------------------Plus-----------------------
plus:
	push ebp
        mov ebp, esp
        pushad
	inc dword [calculations_number]
	cmp dword [stack_counter], 1
	jle .under_flow_error
	call STACK_pop
	mov ebx, eax		;first number - first node
	pushad			;for cleaning purpose
	call STACK_top		
	mov ecx, eax		;second number - second node
	clc			;clearing carry
	.adding_loop_both:
		mov eax, 0
		mov al, [ebx]
		adc al, [ecx]
		pushfd
		mov edx, ebx	;save for restore
		mov byte [ecx], al
		cmp dword [ebx+1], 0
		je .finished_1
		mov ebx, [ebx+1]
		cmp dword [ecx+1], 0
		je .finished_2
		mov ecx, [ecx+1]
		popfd
		jmp .adding_loop_both
	.finished_1:
		mov byte [ebx], 0
		cmp dword [ecx+1], 0
		je .fin
		popfd
		mov ecx, [ecx+1]
		jmp .adding_loop_both
	.finished_2:
		mov dword [ecx+1], ebx
		mov ecx, [ecx+1]
		mov ebx, edx
		mov dword [ebx+1], 0
		mov byte [ebx], 0
		popfd
		jmp .adding_loop_both
	.under_flow_error:
		print_error underflow_error
		jmp .after_cleaning
	.fin:
		popfd
		jnc .cleaning
		.create_node:
			push ecx
			push 5                      
	    		call malloc
			add esp, 4
			pop ecx
			mov dword [ecx+1], eax
			mov byte [eax], 1
			mov dword [eax+1], 0
		.cleaning:	
				popad
				push ebx
				call LIST_free
				add esp, 4
				call debug_print
		.after_cleaning:
		popad
		mov esp, ebp
		pop ebp
		ret
;--------------------/END Plus---------------------
;----------------------/Quit-----------------------
quit:
	push ebp
        mov ebp, esp
        pushad
	mov ebx, [stack_counter]
	dec ebx
	.loop_on_stack_nodes:
		cmp ebx, -1
		je .fin
		push dword [op_stack + 4*ebx]
		call LIST_free
		add esp, 4
		mov dword [op_stack + 4*ebx], 0
		dec ebx
		jmp .loop_on_stack_nodes
	.fin:	
		popad
		mov esp, ebp
		pop ebp
		ret
;--------------------/END quit---------------------
;--------------------------------------------------Stack realted Functions--------------------------------------------------
STACK_pop:
	push ebp
        mov ebp, esp
	sub esp, 4	;returned value
	pushad
	mov eax, [stack_counter]
	dec eax
	mov ebx, [op_stack + 4*eax]
	mov dword [op_stack+4*eax],0 
	sub dword [stack_counter],1            
	mov [ebp-4], ebx                   
	popad
	mov eax,[ebp-4]
	mov esp, ebp
	pop ebp
	ret

STACK_top:
	push ebp
        mov ebp, esp
	sub esp, 4	;returned value
	pushad
	mov eax, [stack_counter]
	dec eax
	mov ebx, [op_stack + 4*eax]           
	mov [ebp-4], ebx                   
	popad
	mov eax,[ebp-4]
	mov esp, ebp
	pop ebp
	ret
;--------------------------------------------------List realted Functions--------------------------------------------------
LIST_print:
	push ebp
        mov ebp, esp
        pushad
	mov ebx, 0
	mov eax, [ebp+8]
	mov bl, [eax]
	cmp dword [eax+1], 0
	je .fin
	push dword [eax+1]
	call LIST_print
	add esp, 4
	.fin:
		push ebx
		push format_hex2
		cmp dword [eax+1], 0
		jne .continue
		add esp, 4
		push format_hex
		.continue:
			call printf
			add esp, 8
			popad
			mov esp, ebp
			pop ebp
			ret



LIST_hardcopy:
	push ebp
        mov ebp, esp
	sub esp, 4	;returned value
	pushad
	mov ebx, 0		;for register bl to initialize
	mov esi, [ebp+8]	;getting the argument
	mov bl, [esi]		;getting value of first node
	push 5			
	call malloc		;creating new link
	add esp, 4
	mov ecx, eax		;put the address of malloc in ecx
	mov byte [ecx], bl	;putting the value of the first byte in ecx
	mov dword [ecx+1], 0	;initialize next link with zero

	cmp dword [esi+1], 0	;if link to duplicate has no 'next' link continue
	je .fin
	push dword [esi+1]
	call LIST_hardcopy	;recursivly go to next link
	add esp, 4
	mov edx, eax
	mov dword [ecx+1], edx
	
	.fin:
		mov [ebp-4], ecx
		popad
		mov eax,[ebp-4]
		mov esp, ebp
		pop ebp
		ret


LIST_free:
	    push ebp
	    mov ebp, esp
	    pushad
	    mov ebx, [ebp +8]
	    .loop:
		mov ecx, [ebx+1]
		pushad
		push ebx
		call free
		add esp,4
		popad
		mov ebx, ecx
		cmp ebx, 0                      
		jne .loop
	    popad
	    mov esp, ebp
	    pop ebp
	    ret

LIST_check_num_greater_than_200:
	push ebp
        mov ebp, esp
	sub esp, 4	;returned value
	pushad
	mov eax, 0
	mov ebx, [ebp +8]
	cmp byte [ebx], 200
	jbe .check_2
	inc eax
	.check_2:
		cmp dword [ebx+1], 0
		je .fin
		inc eax
			
	.fin:
		mov [ebp-4], eax
		popad
		mov eax,[ebp-4]
		mov esp, ebp
		pop ebp
		ret
debug_print:
	push ebp
	mov ebp, esp
	pushad
	cmp byte [dFlag], 0
	je .fin
	print_error format_debug
	call STACK_top
	push eax
	call LIST_print
	add esp, 4
	print_newLine
	.fin:
		popad
		mov esp, ebp
		pop ebp
		ret

	

