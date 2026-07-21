; calculadora.asm - suma, resta y multiplicacion de dos enteros
; x86-64, sintaxis NASM, syscalls de Linux
;
; nasm -f elf64 calculadora.asm -o calculadora.o
; ld calculadora.o -o calculadora

section .data
    msg_num1    db "Primer numero: "
    len_num1    equ $ - msg_num1

    msg_num2    db "Segundo numero: "
    len_num2    equ $ - msg_num2

    msg_suma    db 10, "Suma:           "
    len_suma    equ $ - msg_suma

    msg_resta   db "Resta:          "
    len_resta   equ $ - msg_resta

    msg_mult    db "Multiplicacion: "
    len_mult    equ $ - msg_mult

section .bss
    car         resb 1      ; leemos de uno en uno
    salida      resb 24     ; buffer para convertir numero a texto
    num1        resq 1
    num2        resq 1

section .text
    global _start

_start:
    mov rsi, msg_num1
    mov rdx, len_num1
    call imprimir
    call leer_numero
    mov [num1], rax

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

    ; salir limpiamente
    mov rax, 60
    xor rdi, rdi
    syscall


; ----------------------------------------------------------
; imprimir: escribe rdx bytes desde rsi
; ----------------------------------------------------------
imprimir:
    mov rax, 1              ; write
    mov rdi, 1              ; stdout
    syscall
    ret


; ----------------------------------------------------------
; leer_numero: lee del teclado hasta el salto de linea
; y devuelve el numero en rax
;
; Va caracter a caracter en vez de leer un bloque entero.
; Si leyera 16 bytes de golpe y la entrada viniera de un
; pipe, se tragaria los dos numeros en la primera llamada
; y la segunda se quedaria sin nada.
; ----------------------------------------------------------
leer_numero:
    push rbx
    xor r12, r12            ; acumulador
    xor r13, r13            ; 1 si es negativo
    xor r14, r14            ; 1 si ya hemos leido alguna cifra

.siguiente:
    mov rax, 0              ; read
    mov rdi, 0              ; stdin
    mov rsi, car
    mov rdx, 1
    syscall

    cmp rax, 0
    jle .fin                ; se acabo la entrada

    movzx rbx, byte [car]

    cmp rbx, 10
    je .fin                 ; enter, ya tenemos el numero

    cmp rbx, '-'
    jne .es_cifra
    cmp r14, 0
    jne .siguiente          ; un guion en medio no cuenta
    mov r13, 1
    jmp .siguiente

.es_cifra:
    cmp rbx, '0'
    jb .siguiente           ; ignoramos lo que no sea digito
    cmp rbx, '9'
    ja .siguiente

    sub rbx, '0'            ; de ASCII a valor
    imul r12, 10            ; desplazamos lo acumulado
    add r12, rbx            ; y metemos la cifra nueva
    mov r14, 1
    jmp .siguiente

.fin:
    mov rax, r12
    cmp r13, 1
    jne .listo
    neg rax
.listo:
    pop rbx
    ret


; ----------------------------------------------------------
; imprimir_numero: escribe el entero de rax por pantalla
;
; Construye el texto de derecha a izquierda, porque al
; dividir entre 10 la primera cifra que sale es la ultima
; del numero.
; ----------------------------------------------------------
imprimir_numero:
    mov rdi, salida
    add rdi, 23
    mov byte [rdi], 10      ; salto de linea al final
    dec rdi

    xor r8, r8
    cmp rax, 0
    jge .positivo
    neg rax                 ; trabajamos con el valor absoluto
    mov r8, 1

.positivo:
    mov rbx, 10

.bucle:
    xor rdx, rdx            ; div usa rdx:rax, hay que limpiarlo
    div rbx                 ; cociente en rax, resto en rdx

    add rdx, '0'            ; el resto es la cifra
    mov [rdi], dl
    dec rdi

    cmp rax, 0
    jne .bucle

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
