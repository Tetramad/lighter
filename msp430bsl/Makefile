CFLAGS = -std=gnu11 -Wall -Wextra -Werror
LDFLAGS = -L/usr/lib
LDLIBS = -ldwf

all: main

clean:
	$(RM) main main.o

install: main
	cp main $(HOME)/.local/bin/msp430bsl
	chmod u+x $(HOME)/.local/bin/msp430bsl

uninstall:
	$(RM) $(HOME)/.local/bin/msp430bsl

main: main.o
	gcc $(CFLAGS) -o $@ $< $(LDFLAGS) $(LDLIBS)

%.o : %.c
	gcc $(CFLAGS) -c -o $@ $<

.PHONEY: all clean
