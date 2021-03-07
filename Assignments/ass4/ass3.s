;constants;
STKSIZE equ 16*1024				;16kb
DronesSize equ 40
CODEP equ 0
SPP equ 4
D_INDEX equ 8
D_XPOSTION equ 12
D_YPOSTION equ 20
D_ANGLE equ 28
D_SCORE equ 36
;globals;
global dronesArray
global Narg
global Targ
global Karg
global Barg
global Darg
global SEEDarg
;macros;
%macro scan_arg_to_var 1
	pushad
	push %1
	push scanf_format
	push dword [eax]
	call sscanf
	add esp, 12
	popad
	add eax, 4
%endmacro

section .rodata
	scanf_format: db "%d", 0
    MAX_INTVALUE:    dd 65536
section .bss
	Narg: resd 1
	Targ: resd 1
	Karg: resd 1
	Barg: resd 1
	Darg: resd 1
	SEEDarg: resd 1
	SPT: resd 1
	CURR: resd 1
	dronesArray: resd 1
	dronesStksPointers: resd 1
	targetSTK: resb STKSIZE
	printerSTK: resb STKSIZE
	schedulerSTK: resb STKSIZE
	originalSTK: resd 1
	
section .data
	global co1
	global co2
	global co3
	global currentID
	currentID: dd 0
	co1: dd scheduler
		 dd schedulerSTK + STKSIZE
	co2: dd printer
		 dd printerSTK + STKSIZE
	co3: dd createTarget
		 dd targetSTK + STKSIZE
section .text
	align 16
	global main
	global generate_random
	global main.fin
	global generate_scale
	global resume
	extern printf
	extern malloc
	extern sscanf
	extern free
	extern generateTargetXY
	extern createTarget
	extern printer
	extern scheduler
	extern targetX
	extern targetY
	extern step

main:
	push ebp
	mov ebp,esp
	pushad
	mov dword eax, [ebp+12]
	add eax, 4
	;#############init#############
	scan_arg_to_var Narg
	scan_arg_to_var Targ
	scan_arg_to_var Karg
	scan_arg_to_var Barg
	scan_arg_to_var Darg
	scan_arg_to_var SEEDarg
	call generate_drones_array		;create space for drones array
	call generateTargetXY			;init target x,y 
	call initialize_drones			;init drones array
	;;init co-routines
	mov ebx, co2
	call co_init
	mov ebx, co3
	call co_init
	mov ebx, co1
	call co_init
	;;save current stack pointer(for ending-game purpose)
	mov [originalSTK], esp
	;;starting the game
	jmp do_resume
	;;finishing - returning stack pointer to original one + freeing all memory
	.fin:	
		mov esp,[originalSTK]
		call freeAllMem

		popad
		mov esp, ebp
		pop ebp
		ret
			



;############################### Generating drones array ################################
generate_drones_array:
	push ebp
    mov ebp, esp
	pushad

	pushad
	mov eax, [Narg]			;move number of drones to eax
	mov ebx, DronesSize		;move mem size of drone to ebx
	mul ebx							;all drones memory = number of drones X mem size of each drone
	push eax
	call malloc
	add esp, 4
	mov [dronesArray], eax			;moving the address of the array to dronesArray
	popad
	;;init to all drones stack pointers
	mov eax, [Narg]
	mov ebx, 4
	mul ebx
	push eax
	call malloc
	add esp, 4
	mov [dronesStksPointers], eax
	
	popad
	mov esp, ebp
	pop ebp
	ret
;############################### Generating random num ################################
generate_random:
	push ebp
	mov ebp, esp
	pushad
	mov ecx, 16						;number of routines(16 times loop)
	.genLoop:
		mov ebx, 0
		mov dword ebx, [SEEDarg]
		shr dword [SEEDarg], 1
		and ebx, 0x2D				;bits 16 14 13 11 on rest is off(for xoring)
		jp .handleEven
		add dword [SEEDarg], 0x8000			
		
		.handleEven:
			loop .genLoop
		
		popad
		mov esp, ebp
		pop ebp
		ret
;############################### Generating scaled num using random num generating ################################
generate_scale:
	push ebp
	mov ebp, esp
	pushad
	mov eax, [ebp+8]				;address to put the value in		
	mov ebx, [ebp+12]				;max border value
	mov ecx, [ebp+16]				;represents if its an angle or not -60 or zero
	finit							;init x87
	call generate_random			;update SEEDarg with the new random number
	fild dword[SEEDarg]				;load SEEDarg into the x87 stack
	fidiv dword[MAX_INTVALUE]		;div with MAX integer
	push ebx						;+100/+120 depends on angle\x\y
	fimul dword [esp]				;pushing 100/120 to x87 stack
	add esp, 4						;returning esp to before pushing 100
	push ecx
	fisub dword [esp]				;to get a number between -60-60 if zero nothing happen
	add esp, 4
	.a:
	.fin:
		fstp qword [eax]
		popad
		mov esp, ebp
		pop ebp
		ret


;############################### initialize drones array ################################
initialize_drones:
	push ebp
	mov ebp, esp
	pushad
	mov eax, [dronesArray]			;pointer to the array
	mov ebx, 0						;counter to drones id
	mov dword ecx, [Narg]			;number of drones
	.loopOnDrones:
		;;drones function:
		mov dword[eax+CODEP], step
		;;malloc for drones spp:
		pushad
		mov edi, eax
		mov esi, ebx
		push STKSIZE
		call malloc
		add esp, 4
		mov ebx, [dronesStksPointers]
		mov dword [ebx +4*esi], eax
		add eax, STKSIZE
		mov dword [edi+SPP], eax
		popad
		;;co init
		pushad
		mov ebx, eax
		call co_init
		popad
		;;drones INDEX:
		mov dword [eax+D_INDEX], ebx
		;;drones x&y:
		push dword 0		
		push dword 100
		push eax
		add dword [esp], D_XPOSTION
		call generate_scale
		add esp, 12	
		push dword 0			; for getting x or y - lower border
		push dword 100		;upper border
		push dword eax
		add dword [esp], D_YPOSTION
		call generate_scale
		add esp, 12	
		;;drones angle:
		push dword 0
		push dword 360
		push dword eax
		add dword [esp], D_ANGLE
		call generate_scale
		add esp, 12	
		;;drones score
		mov dword [eax+D_SCORE], 0
		;;move to next drone and loop again:
		inc ebx
		add eax, DronesSize
		loop .loopOnDrones
	popad
	mov esp, ebp
	pop ebp
	ret
;############################### free all memory ################################
freeAllMem:
	push ebp
	mov ebp, esp
	pushad
	;;free drones stacks
	mov ebx, [dronesStksPointers]
	mov dword ecx, [Narg]			;number of drones
	mov edx, 0
	.free_loop:
		pushad
		push dword [ebx+4*edx]
		call free
		add esp, 4
		popad
		inc edx
		loop .free_loop
	pushad
	push dword [dronesStksPointers]
	call free
	add esp, 4
	popad
	;;free drones array
	push dword [dronesArray]
	call free
	add esp, 4

	popad
	mov esp, ebp
	pop ebp
	ret
;############################### co\resume\do resume (copied from class material################################
co_init:
    pushad
    mov     eax,[ebx+CODEP]
    mov     [SPT],esp
    mov     esp,[ebx+SPP]
    push    eax
    pushfd
    pushad
    mov     [ebx+SPP],esp
    mov     esp,[SPT]
    popad
    ret
    
resume:
    pushfd
    pushad
    mov     edx,[CURR]
    mov     [edx+SPP],esp

do_resume:
    mov     esp,[ebx+SPP]
    mov     [CURR],ebx
    popad
    popfd
    ret