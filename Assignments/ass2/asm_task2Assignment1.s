section	.rodata				; we define (global) read-only variables in .rodata section
	format_string_illegal: db "illegal input", 10, 0	; format string for illegal input
	format_string_sum: db "%d", 10, 0			; format string for number sum
	

section .text
	global assFunc
	extern printf
	extern c_checkValidity

assFunc:
	push ebp
	mov ebp, esp
	pushad
	mov ecx, dword [ebp+8]	; get x
	mov edx, dword [ebp+12]	; get y
	push edx
	push ecx
	call c_checkValidity
	add esp, 8	; clean up stack
	cmp eax, 0
	jne print_number	; if ok print nums sum
	jmp print_illegal	; if illegal



print_number:
	add ecx, edx	;saves sum
	push ecx
	push format_string_sum
	call printf
	add esp, 8		; clean up stack after call
	jmp cleaning
	

print_illegal:
	push format_string_illegal	; pointer to str and pointer to format string
	call printf
	add esp, 4		; clean up stack after call
	jmp cleaning

cleaning:
	popad			
	mov esp, ebp	
	pop ebp
	ret
