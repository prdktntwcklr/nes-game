;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; constants for PPU registers mapped from addresses $2000 to $2007
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PPU_CTRL   = $2000
PPU_MASK   = $2001
PPU_STATUS = $2002
OAM_ADDR   = $2003
OAM_DATA   = $2004
PPU_SCROLL = $2005
PPU_ADDR   = $2006
PPU_DATA   = $2007

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; the iNES header (total 16 bytes) at $7FF0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment "HEADER"
.byte $4E,$45,$53,$1A        ; 4 bytes with the characters 'N','E','S','\n'
.byte $02                    ; how many 16kB of PRG-ROM we use (=32kB)
.byte $01                    ; how many 8kB of CHR-ROM we use (=8kB)
.byte %00000000              ; horz mirroring, no bat, mapper 0
.byte %00000000              ; mapper 0, playchoice, NES 2.0
.byte $00                    ; no PRG-RAM
.byte $00                    ; NTSC TV format
.byte $00                    ; no PRG-RAM
.byte $00,$00,$00,$00,$00    ; unused padding to complete 16 bytes of header

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PRG-ROM code located at $8000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.segment "CODE"

RESET:
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

Main:
    ldx #$3F
    stx PPU_ADDR             ; set hi-byte of PPU_ADDR to $3F
    ldx #$00
    stx PPU_ADDR             ; set lo-byte of PPU_ADDR to $00
    lda #$2A
    sta PPU_DATA             ; send $2A (lime-green color code) to PPU_DATA
    lda #%00011110
    sta PPU_MASK             ; set PPU_MASK bits to show background and sprites

LoopForever:
    jmp LoopForever          ; force an infinite loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; NMI interrupt handler
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NMI:
    rti                      ; return from interrupt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; IRQ interrupt handler
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IRQ:
    rti                      ; return from interrupt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; vectors with the addresses of the handlers at $FFFA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.segment "VECTORS"
.word NMI                    ; address of the NMI handler
.word RESET                  ; address of the RESET handler
.word IRQ                    ; address of the IRQ handler
