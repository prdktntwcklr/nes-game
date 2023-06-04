.macro PPU_SETADDR addr
    bit PPU_STATUS           ; read PPU_STATUS to reset PPU_ADDR latch
    lda #>addr               ; load high byte of 16-bit addr
    sta PPU_ADDR             ; store high byte into PPU_ADDR $2006
    lda #<addr               ; load low byte of 16-bit addr
    sta PPU_ADDR             ; store low byte into PPU_ADDR $2006
.endmacro

.macro PPU_SETDATA val
    lda val
    sta PPU_DATA         ; send value to PPU register $2007
.endmacro
