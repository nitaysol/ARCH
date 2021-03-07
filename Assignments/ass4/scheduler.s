DronesSize equ 40
section .text
	align 16
    global scheduler
	extern co1
    extern co2
    extern dronesArray
	extern resume
    extern Karg
    extern Narg
    extern currentID
scheduler:
     mov edx, 0                         ; printing counter of steps
    .init:
        mov dword [currentID], 0
        mov dword ecx, [Narg]           ; ecx will contain number of drones in order to loop
        mov ebx, [dronesArray]          ; begining of dronesArray
    .after_init:
        call resume                     ; moving to current drone routine
        inc edx                         ; inc number of steps
        add ebx, DronesSize             ; moving to next drone
        inc dword [currentID]                 ; inc current index
        cmp edx, [Karg]                 ; checking if printing is needed
        jne .skip_printing              ; if not skip
        pushad
        mov ebx, co2                    ; moving to printing routine
        call resume                     
        popad
        mov edx, 0                      ; setting printing counter to zero
        .skip_printing:
            loop .after_init, ecx       ; looping on drones
            jmp .init                   ; if ran on all drones -> start from the begining