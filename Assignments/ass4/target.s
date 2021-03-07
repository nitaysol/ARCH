D_XPOSTION equ 12
D_YPOSTION equ 20
D_ANGLE equ 28

section .data
	global targetX
	global targetY
	targetX: dq 0
	targetY: dq 0
	gamma: dq 0
	

section .text
	align 16
	global generateTargetXY
	global createTarget
	global mayDestroy
	extern generate_scale
	extern co1
	extern resume
	extern Barg
	extern Darg

createTarget:
	
	call generateTargetXY
	mov ebx, co1
	call resume
	jmp createTarget
	

generateTargetXY:
	push ebp
	mov ebp, esp
	pushad
	push dword 0			; for getting x or y - lower border
	push dword 100		;upper border
	push dword targetX	;address of x
	call generate_scale
	add esp, 12
	push dword 0			; for getting x or y - lower border
	push dword 100		;upper border
	push dword targetY	;address of x
	call generate_scale
	add esp, 12	
	popad
	mov esp, ebp
	pop ebp
	ret
;#########################################mayDestroy functions###################################
mayDestroy:
	push ebp
	mov ebp, esp
	sub esp, 4									;return value
	pushad			
	mov eax, 0									;0 - cant destroy , 1 - can destroy	
	mov ebx, [ebp+8]								;current drone address
	finit										;init x87 registers
	;;calculating gamma
	call calculate_gamma						;now gamma stores the result of arctan(Ty-Dy,Tx-Dx)
	fld qword [ebx+D_ANGLE]						;inserting the drone angle = alpha
	call degreeToRad
	fsubp										;st(0)=alpha st(1)=gamma -> gamma-alpha
	fabs										;absolute value of the sub result |gamma-alpha|
	fldpi										;st(0)=pi st(1) = |alpha-gamma|
	fcomip                       				;comparing st(0)=pi with st(1)=|alpha-gamma|
	jnc .continue                       		; if pi>(alpha-gamma)
	.bitch_please:
		;;modulo alpha or gamma depends whose the smallest
		fstp st0									;need to create new alpha-gamma
		fld qword [ebx+D_ANGLE]
		call degreeToRad
		fld qword [gamma]
		fcomi
		
		jc .addingPies 
		fstp st0
		fstp st0
		fld qword [gamma]
		fld qword [ebx+D_ANGLE]
		call degreeToRad		
		.addingPies:
			fldpi
			fldpi
			faddp
			faddp
		.alpha_beta:
			fsubp
			fabs

	.continue:									;;
		fild dword [Barg]
		;;beta to Rad
		call degreeToRad
		fcomip
		jna .fin							;if beta is not above target cant be seen
		;;else - if beta is above == (abs(alpha-gamma) < beta) we check next condition:
		.b:
		;; sqrt((y2-y1)^2+(x2-x1)^2) < d
		fld qword [targetY]							;load Target Y 
    	fld qword [ebx+D_YPOSTION]      			;load Drone Y
		fsubp										;st(0)= Ty-Dy
		fmul st0, st0								;st(0)= (Ty-Dy)^2
		fld qword [targetX]            				;load Target X
    	fld qword [ebx+D_XPOSTION]       			;load Drone X
		fsubp										;st(1)= (Ty-Dy)^2, st(0) = Tx-Dx
		fmul st0, st0								;st(1)=(Ty-Dy)^2, st(0)=(Tx-Dx)^2
		faddp										;st(0)= (Ty-Dy)^2+(Tx-Dx)^2
		fsqrt										;st(0)= sqrt((Ty-Dy)^2+(Tx-Dx)^2))
		fild dword [Darg]							;loading max distance
		fcomip										;compare the distance
		jna .fin								;if >=max distance exit
		inc eax
	.fin:
        mov [ebp-4], eax            				;save returned value
		popad
		mov eax,[ebp-4]								;return value to eax after popad
		mov esp, ebp
		pop ebp
		ret


calculate_gamma:
	push ebp
	mov ebp, esp
	pushad                           
    fld qword [targetY]							;load Target Y 
    fld qword [ebx+D_YPOSTION]      			;load Drone Y
    fsubp                           			;sub Ty-Dy
    fld qword [targetX]            				;load Target X
    fld qword [ebx+D_XPOSTION]       			;load Drone X
    fsubp                  						;sub Tx-Dx        
    fpatan                  					;arctan(Ty-Dy,Tx-Dx)        
    fst qword [gamma]							;saving the value to gamma
	popad
	mov esp, ebp
	pop ebp
	ret

degreeToRad:
	push ebp
	mov ebp, esp
	pushad 
	fldpi
	push dword 180
	fidiv dword [esp]
	add esp, 4
	fmulp
	popad
	mov esp, ebp
	pop ebp
	ret

