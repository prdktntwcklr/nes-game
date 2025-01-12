ASM = ca65
LD = ld65
PROJECT = game
CFG = nes.cfg

SRC_DIR = src
BUILD_DIR = build

.PHONY: all clean

all: $(BUILD_DIR)/$(PROJECT).nes

clean:
	rm -rf $(BUILD_DIR)

$(BUILD_DIR)/$(PROJECT).nes: $(BUILD_DIR)/$(PROJECT).o
	$(LD) -C $(SRC_DIR)/$(CFG) $< -o $@

$(BUILD_DIR)/$(PROJECT).o: $(SRC_DIR)/main.asm
	mkdir -p $(BUILD_DIR)
	$(ASM) $< -o $@
