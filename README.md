# calculadora-asm

Calculadora de dos operandos escrita en ensamblador x86-64. Suma, resta y multiplica enteros con signo.

Sin librería estándar. Solo syscalls de Linux.

```
Primer numero: 12
Segundo numero: 7

Suma:           19
Resta:          5
Multiplicacion: 84
```

> De la asignatura de estructura de computadores. Acabo de abrir GitHub y estoy subiendo lo que tenía en local.

## Compilar

```bash
make
./calculadora
```

O a mano:

```bash
nasm -f elf64 calculadora.asm -o calculadora.o
ld calculadora.o -o calculadora
```

Necesitas `nasm` y Linux de 64 bits. En Ubuntu: `sudo apt install nasm`.

## Qué tiene de interesante

En C escribes `printf("%d", x)` y ya está. Aquí no hay `printf`. No hay nada. Hay que construirlo.

### Convertir texto a número

El teclado no manda números, manda caracteres ASCII. El `7` llega como el byte 55.

```asm
sub rbx, '0'        ; 55 - 48 = 7
imul r12, 10        ; desplazamos lo que llevábamos
add r12, rbx        ; y metemos la cifra nueva
```

Leer "123" es: empiezas en 0, luego 0×10+1=1, luego 1×10+2=12, luego 12×10+3=123.

### Convertir número a texto

Al revés y con un detalle incómodo: dividiendo entre 10, la primera cifra que obtienes es la **última** del número. Con 123 sacas el 3, luego el 2, luego el 1.

Por eso el buffer se rellena de derecha a izquierda:

```asm
mov rdi, salida
add rdi, 23         ; empezamos por el final
...
mov [rdi], dl
dec rdi             ; y vamos hacia atrás
```

### El bug que me costó un rato

La primera versión leía 16 bytes de golpe con `read`. Funcionaba tecleando a mano, pero al probarlo con `printf "12\n7\n" | ./calculadora` daba 24 en la suma.

El motivo: en un pipe los dos números llegan juntos al buffer. La primera llamada se los tragaba ambos y la segunda se quedaba sin nada, así que `num2` mantenía el valor de `num1`.

La solución fue leer carácter a carácter y parar en el `\n`. Menos eficiente, pero correcto en los dos casos.

## Registros que uso

| Registro | Para qué |
|---|---|
| `rax` | Número de syscall / valor de retorno |
| `rdi` | Primer argumento (descriptor de archivo) |
| `rsi` | Segundo argumento (puntero al buffer) |
| `rdx` | Tercer argumento (cuántos bytes) |
| `r12`–`r14` | Variables de `leer_numero` |

Las syscalls que necesito son solo tres: `read` (0), `write` (1) y `exit` (60).

## Detalles

`imul` en lugar de `mul` porque hay que respetar el signo. Y `div` usa el par `rdx:rax` como dividendo, así que hay que poner `rdx` a cero antes de cada división o el resultado sale mal.

## Limitaciones

Sin división: habría que decidir qué hacer con los decimales y con la división entre cero.

Sin control de desbordamiento. Si multiplicas dos números enormes, el resultado da la vuelta en silencio.

## Pendiente

- [ ] División entera con resto
- [ ] Detectar desbordamiento
- [ ] Menú para elegir la operación
- [ ] Aceptar números por argumentos

---

Milagrosa Rivero · [github.com/Milarm03](https://github.com/Milarm03)
