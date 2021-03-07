STKSIZE equ 16*1024
DronesSize equ 40
CODEP equ 0
SPP equ 4
D_INDEX equ 8
D_XPOSTION equ 12
D_YPOSTION equ 20
D_ANGLE equ 28
D_SCORE equ 36
section .rodata
	winner_format: db "Drone id %d: I am a winner",10,0

section .data
	circle:	dd 360.0
	board:	dd 100.0
	deg:	dd 180.0
	tmp:    dq 0

section .text
	align 16
	global step
	extern generate_scale
	extern currentID
	extern mayDestroy
	extern Darg
	extern Barg
	extern dronesArray
	extern co1
	extern co3
	extern Targ
	extern printf
	extern resume
	extern main.fin


step:
	;;moving to current drone
	mov esi, [dronesArray]
	mov eax, [currentID]
	mov ebx, DronesSize
	mul ebx
	add esi, eax

	;;starting calculation
	finit
	push dword 60
	push dword 120
	push dword tmp
	call generate_scale
	add esp, 12
	fld qword [esi+D_ANGLE]
	fadd qword [tmp]
	push dword esi
	add dword [esp], D_ANGLE
	call torusCircle
	add esp,4
	push dword 0
	push dword 50
	push dword tmp
	call generate_scale
	add esp, 12
	fld qword [esi+D_ANGLE]
	fldpi
	fdiv dword [deg]
	fmulp
	
	fsincos
	fmul qword [tmp]
	fadd qword [esi+D_XPOSTION]
        push dword esi
        add dword [esp], D_XPOSTION
        call torusBoard
        add esp,4
	fmul qword [tmp]
	fadd qword [esi+D_YPOSTION]
	push dword esi
	add dword [esp], D_YPOSTION
	call torusBoard
	add esp,4

	push esi
	call mayDestroy
	add esp, 4
	cmp  eax,1
	jne .false
	;;TRUE
	inc dword [esi+D_SCORE]
	mov eax,[esi+D_SCORE]
	cmp eax,[Targ]
	jne .newtar
	;;increase D_SCORE
	;;cmp score with dest_SCORE
	;;     if equal, print winner and jmp main.fin
	
	;;     else, call target co-routine
	pushad
	mov eax,[esi+D_INDEX]
	inc eax
	push eax
	push winner_format
	call printf
	add esp,8
	popad
	jmp main.fin
	.newtar:
		mov ebx,co3
		call resume
		jmp step
	.false:
	;;FALSE - call scheduler
		mov ebx,co1 ;scheduler
		call resume
		jmp step
	
	
	
torusCircle:
    push ebp
    mov ebp,esp
    pushad
    
    fldz
    fcomip
    jna     .big
    fadd dword [circle]
    jmp     .fin
    .big:
		fld     dword [circle]
		fcomip
		jnbe    .fin
		fsub dword [circle]
    .fin:    
    
		mov eax,[ebp+8]
		fstp qword [eax]
		popad
		mov esp, ebp
		pop ebp
		ret
    
torusBoard:
    push ebp
    mov ebp,esp
    pushad
    
    fldz
    fcomip
    jna     .big
    fadd dword [board]
    jmp     .fin
    .big:
		fld     dword [board]
		fcomip
		jnbe    .fin
		fsub dword [board]
    .fin:    
    
		mov eax,[ebp+8]
		fstp qword [eax]
		popad
		mov esp, ebp
		pop ebp
		ret