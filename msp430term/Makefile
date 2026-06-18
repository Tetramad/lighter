CFLAGS = -std=gnu11 -Wall -Wextra -Werror
LDFLAGS = -L/usr/lib
LDLIBS = -ldwf

all: main

clean:
	$(RM) main main.o

install: main
	cp main $(HOME)/.local/bin/msp430term
	chmod u+x $(HOME)/.local/bin/msp430term

uninstall:
	$(RM) $(HOME)/.local/bin/msp430term

main: main.o
	gcc $(CFLAGS) -o $@ $< $(LDFLAGS) $(LDLIBS)

%.o : %.c
	gcc $(CFLAGS) -c -o $@ $<

.PHONEY: all clean
