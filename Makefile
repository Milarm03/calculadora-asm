CC = nasm
LD = ld

calculadora: calculadora.o
	$(LD) calculadora.o -o calculadora

calculadora.o: calculadora.asm
	$(CC) -f elf64 calculadora.asm -o calculadora.o

limpiar:
	rm -f calculadora calculadora.o

.PHONY: limpiar
