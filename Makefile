ASM = ca65
LD = ld65
PROJECT = clearmem
CFG = nes.cfg

.PHONY: all clean

all: $(PROJECT).nes

clean:
	rm -f *.o *.nes

$(PROJECT).nes: $(PROJECT).o
	$(LD) -C $(CFG) $< -o $@

$(PROJECT).o: $(PROJECT).asm
	$(ASM) $< -o $@