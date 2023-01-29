;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Macro to initialize NES by disabling rendering and clearing RAM values
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.macro INIT_NES
    sei                      ; disable all IRQ interrupts
    cld                      ; clear the decimal mode flag
    
    lda #$40
    sta $4017                ; disable APU frame IRQ
    
    ldx #$FF
    txs                      ; initialize stack pointer to $01FF
    inx                      ; increment X from $FF to $0 (overflow)
                             ; to start from $0 which is not zeroed out below
    stx PPU_CTRL             ; disable NMI
    stx PPU_MASK             ; disable rendering
    stx $4010                ; disable DMC IRQs

Wait1stVBlank:               ; wait for the first VBlank from the PPU
    bit PPU_STATUS           ; perform bit-wise check
    bpl Wait1stVBlank        ; loop until bit 7 (sign bit) is 1 (inside VBlank)

    lda #$0                  ; A = 0
ClearRAM:
    sta $0000,x              ; zero RAM addresses from $0000 to $00FF
    sta $0100,x              ; zero RAM addresses from $0100 to $01FF
    sta $0200,x              ; zero RAM addresses from $0200 to $02FF
    sta $0300,x              ; zero RAM addresses from $0300 to $03FF
    sta $0400,x              ; zero RAM addresses from $0400 to $04FF
    sta $0500,x              ; zero RAM addresses from $0500 to $05FF
    sta $0600,x              ; zero RAM addresses from $0600 to $06FF
    sta $0700,x              ; zero RAM addresses from $0700 to $07FF
    inx                      ; X++
    bne ClearRAM             ; loops until X reaches 0 again (after overflow)

Wait2ndVBlank:               ; wait for the second VBlank from the PPU
    bit PPU_STATUS           ; perform bit-wise check
    bpl Wait2ndVBlank        ; loop until bit 7 (sign bit) is 1 (inside VBlank)
.endmacro