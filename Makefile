.PHONY: all clean

all: clearmem.o
	ld65 -C nes.cfg $< -o clearmem.nes

clearmem.o: clearmem.asm
	 ca65 $< -o $@

clean:
	rm -f clearmem.o clearmem.nes