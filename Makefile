CC      = gcc
CFLAGS  = -Wall -Wextra -Werror
LEX     = flex
YACC    = bison
YFLAGS  = -d
EXEC    = tl13_compiler
OBJS    = parse.o scan.o

.PHONY: all clean

all: $(EXEC)

clean:
	rm -f $(EXEC) $(OBJS) y.tab.h

$(EXEC): $(OBJS)
	$(CC) -o $(EXEC) $(OBJS)
