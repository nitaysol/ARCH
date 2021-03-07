all: task2b task1c

task2b: task2b.o
	gcc -m32 -g -Wall -o task2b task2b.o
task1c: task1c.o
	gcc -m32 -g -Wall -o task1c task1c.o

task2b.o: task2b.c
	gcc -g -Wall -m32 -c -o task2b.o task2b.c
task1c.o: task1c.c
	gcc -g -Wall -m32 -c -o task1c.o task1c.c

.PHONE: clean
clean:
	rm -f *.o task1c task2b

