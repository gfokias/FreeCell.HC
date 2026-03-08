CC=cc
CFLAGS=-Wall -Wextra -std=c89 -g

ppm2sprite: sprite.o main.o ppm.o
	$(CC) $(CFLAGS) $^ -o ppm2sprite

main.o: sprite.o ppm.o main.c
	$(CC) $(CFLAGS) -c main.c -o main.o

sprite.o: ppm.o sprite.c sprite.h
	$(CC) $(CFLAGS) -c sprite.c -o sprite.o

ppm.o: ppm.c ppm.h
	$(CC) $(CFLAGS) -c ppm.c -o ppm.o
