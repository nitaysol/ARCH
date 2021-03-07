section	.rodata				; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0	; format string

section .bss				; we define (global) uninitialized variables in .bss section
	an: resb 12			; enough to store integer in [-2,147,483,648 (-2^31) : 2,147,483,647 (2^31-1)]
	array_of_powers: resd 32 	;array for powers of 2
	array_of_flipped_chars: resb 12	; array of chars represingting the number flipped(temporary array)

section .text
	global convertor
	extern printf

convertor:
	push ebp
	mov ebp, esp
	pushad
	mov ecx, dword [ebp+8]	; get function argument (pointer to string)
	jmp main_function	; starting the procedure
	return:			;returning when finished all procedure in order to make output
	push an
	push format_string	; pointer to str and pointer to format string
	call printf
	add esp, 8		; clean up stack after call
	popad			
	mov esp, ebp	
	pop ebp
	ret

main_function:
	step_1:
		jmp create_array_of_powers ;creating the array of powers dynamically
	step_2:
		jmp count_string_size ; count_string_size counting the string size ebx will store it size in the end of the loop
	step_3:
		mov edi, 0	; edi will represent MSB signed flag 
		cmp ebx, 32	; check valid negative number(all 32 bits)
		jne step_4
		cmp byte [ecx], '1'
		jne step_4
		mov byte [an], '-'
		mov edi, 1	;edi now stores 1-if negative 0-if non-negative
	step_4:
		jmp convert_to_decimal ;converting the binary to decimal
	step_5:
		cmp edi, 1
		jne step_6
		neg esi
	step_6:
		cmp esi, 0
		jne convert_to_string	;convering the number into string
		mov byte [array_of_flipped_chars], 0x30
		mov esi, 1
		
	step_7:
		jmp creating_output
	step_8:
		mov byte[an+edi], 0	;terminating byte to string
		jmp return		;return to to end of function(all set)
		
create_array_of_powers:
	mov edx, 0	;starting place of the array
	mov ebx, 1	;starting power(2^0)
	building_array_loop:
		mov dword [array_of_powers + 4*edx], ebx	; array[i] = ebx
		sal ebx, 1	; multiplying by 2
		inc edx
		cmp edx, 32
		jne building_array_loop	
		jmp step_2					; returning to main

count_string_size:
	mov ebx, -1
	count_string_size_loop:	;counting the input string size
		inc ebx
		cmp byte [ecx + ebx], 0XA
		jne count_string_size_loop
		jmp step_3

convert_to_decimal:
	mov esi, 0	;esi will store the number as decimal
	mov edx, 0	;starting place of the array
	mov eax, ebx	;starting place of array_of_power
	dec eax
	convert_to_decimal_loop:
		cmp byte [ecx+edx], '1'
		jne continue_to_next_char
		add esi, [array_of_powers + 4*eax]
		
		
continue_to_next_char:
	inc edx
	dec eax
	cmp edx, ebx
	jne convert_to_decimal_loop
	jmp step_5
	
	
convert_to_string:
	mov eax, esi	;rest of the number
	mov ebx, 10	;divider
	mov esi, 0	;counter of array
	deviding_loop:
		mov edx, 0	;modulo
		cmp eax, 0
		je step_7
		div ebx      ; Divides number by 10. DX = modulo and AX = rest of the number
		add edx, '0'	;converting the digit into char
		mov [array_of_flipped_chars + esi], edx
		inc esi
		jmp deviding_loop
		
		
creating_output:
	dec esi		;size of chars array
	creating_output_loop:
		cmp esi, -1		;if finished looping on chars array finish
		je step_8
		mov edx, [array_of_flipped_chars + esi]
		mov [an+edi], edx
		inc edi
		dec esi
		jmp creating_output_loop 
	
	
	

	






