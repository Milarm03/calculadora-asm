; calculadora.asm - suma, resta y multiplicacion de dos numeros
; x86-64, sintaxis NASM, syscalls de Linux
;
; nasm -f elf64 calculadora.asm -o calculadora.o
; ld calculadora.o -o calculadora

section .data
    msg_num1    db "Primer numero: ", 0
    len_num1    equ $ - msg_num1

    msg_num2    db "Segundo numero: ", 0
    len_num2    equ $ - msg_num2

    msg_suma    db 10, "Suma:           ", 0
    len_suma    equ $ - msg_suma

    msg_resta   db "Resta:          ", 0
    len_resta   equ $ - msg_resta

    msg_mult    db "Multiplicacion: ", 0
    len_mult    equ $ - msg_mult

    salto       db 10

section .bss
    buffer      resb 16     ; para leer del teclado
    salida      resb 24     ; para convertir numeros a texto
    num1        resq 1
    num2        resq 1

section .text
    global _start

_start:
    ; --- pedir el primer numero ---
    mov rsi, msg_num1
    mov rdx, len_num1
    call imprimir

    call leer_numero
    mov [num1], rax

    ; --- pedir el segundo ---
    mov rsi, msg_num2
    mov rdx, len_num2
    call imprimir

    call leer_numero
    mov [num2], rax

    ; --- suma ---
    mov rsi, msg_suma
    mov rdx, len_suma
    call imprimir

    mov rax, [num1]
    add rax, [num2]
    call imprimir_numero

    ; --- resta ---
    mov rsi, msg_resta
    mov rdx, len_resta
    call imprimir

    mov rax, [num1]
    sub rax, [num2]
    call imprimir_numero

    ; --- multiplicacion ---
    mov rsi, msg_mult
    mov rdx, len_mult
    call imprimir

    mov rax, [num1]
    imul qword [num2]       ; resultado en rax
    call imprimir_numero

    ; salir con codigo 0
    mov rax, 60
    xor rdi, rdi
    syscall


; ----------------------------------------------------------
; imprimir: escribe rdx bytes desde rsi por pantalla
; ----------------------------------------------------------
imprimir:
    mov rax, 1              ; syscall write
    mov rdi, 1              ; fd 1 = stdout
    syscall
    ret


; ----------------------------------------------------------
; leer_numero: lee del teclado y devuelve el numero en rax
; solo acepta enteros positivos
; ----------------------------------------------------------
leer_numero:
    mov rax, 0              ; syscall read
    mov rdi, 0              ; fd 0 = stdin
    mov rsi, buffer
    mov rdx, 16
    syscall

    ; ahora convertimos el texto a numero
    xor rax, rax            ; aqui acumulamos el resultado
    xor rcx, rcx            ; indice del buffer

.bucle:
    movzx rbx, byte [buffer + rcx]

    cmp rbx, 10             ; salto de linea = hemos terminado
    je .fin
    cmp rbx, '0'
    jb .fin
    cmp rbx, '9'
    ja .fin

    sub rbx, '0'            ; de caracter ASCII a valor
    imul rax, 10            ; desplazamos lo que llevabamos
    add rax, rbx            ; y sumamos la cifra nueva

    inc rcx
    jmp .bucle

.fin:
    ret


; ----------------------------------------------------------
; imprimir_numero: escribe el numero de rax por pantalla
; maneja negativos
; ----------------------------------------------------------
imprimir_numero:
    mov rdi, salida
    add rdi, 23             ; empezamos por el final del buffer
    mov byte [rdi], 10      ; salto de linea
    dec rdi

    xor r8, r8              ; bandera: 1 si es negativo
    cmp rax, 0
    jge .positivo
    neg rax
    mov r8, 1

.positivo:
    mov rbx, 10             ; divisor

.bucle:
    xor rdx, rdx            ; div usa rdx:rax, hay que limpiarlo
    div rbx                 ; cociente en rax, resto en rdx

    add rdx, '0'            ; el resto es la cifra
    mov [rdi], dl
    dec rdi

    cmp rax, 0
    jne .bucle              ; seguimos mientras quede algo

    cmp r8, 1
    jne .imprimir
    mov byte [rdi], '-'
    dec rdi

.imprimir:
    inc rdi                 ; rdi apunta al primer caracter

    mov rsi, rdi
    mov rdx, salida
    add rdx, 24
    sub rdx, rdi            ; longitud = fin - inicio

    mov rax, 1
    mov rdi, 1
    syscall
    ret
