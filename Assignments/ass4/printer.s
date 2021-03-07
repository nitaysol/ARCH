DronesSize equ 40
section .rodata
    print_target:      db "%.2f,%.2f",10,0
    print_format:    db "%d,%.2f,%.2f,%.2f,%d",10,0

section .text
	global printer
	extern targetX
	extern targetY
	extern dronesArray
	extern Narg
	extern printf
	extern co1
	extern resume
	STKSIZE equ 16*1024			
	CODEP equ 0
	SPP equ 4
	D_INDEX equ 8
	D_XPOSTION equ 12
	D_YPOSTION equ 20
	D_ANGLE equ 28
	D_SCORE equ 36

printer:	
    mov esi, 0
    mov eax, [dronesArray]
    mov ecx, 1
	;;;;print target
    pushad
    push dword [targetY+4]
    push dword [targetY]
    push dword [targetX+4]
   	push dword [targetX]
    push print_target
    call printf
    add esp, 20
    popad
	;;print drones
.print_loop:
    pushad
	;score - 4 bytes
    push dword [eax+D_SCORE]
	;pushing angle - 8 bytes
	push dword [eax+D_ANGLE+4]
	push dword [eax+D_ANGLE]
	;pushing y - 8 bytes
	push dword [eax+D_YPOSTION+4]
	push dword [eax+D_YPOSTION]
    ;pushing x - 8 bytes
    push dword [eax+D_XPOSTION+4]
	push dword [eax+D_XPOSTION]
	;drone index - 4 bytes
    push esi
	inc dword [esp]
	;string format - 4 bytes
    push print_format
    call printf
    add esp, 36
    popad
    add eax, DronesSize
    inc esi
    cmp esi, [Narg]
    jne .print_loop
    mov ebx, co1
	.b:
    call resume
    jmp printer 