# Makefile untuk program MPI
CC       := mpicc
CFLAGS   := -O2 -Wall -Wextra -std=c11
BIN      := pi
SRC      := pi.c

.PHONY: all clean run

all: $(BIN)

$(BIN): $(SRC)
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f $(BIN)

run: $(BIN)
	mpirun --hostfile ../config/hostfile --allow-run-as-root -np 4 ./$(BIN)
