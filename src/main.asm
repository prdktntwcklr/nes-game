.include "constants.inc"
.include "header.inc"
.include "reset.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PRG-ROM code located at $8000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.segment "CODE"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to load all 32 color palette values from ROM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc LoadPalette
    ldy #0                   ; Y = 0
LoopPalette:
    lda PaletteData,y        ; lookup byte in ROM
    sta PPU_DATA             ; set value to send to PPU_DATA
    iny                      ; Y++
    cpy #32                  ; is Y equal to 32?
    bne LoopPalette          ; if not, keep looping
    rts                      ; return from subroutine
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to load 255 tiles into the first nametable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc LoadBackground
    ldy #0
LoopBackground:
    lda BackgroundData,y     ; lookup byte in ROM
    sta PPU_DATA             ; set value to send to PPU_DATA
    iny                      ; Y++
    cpy #255                 ; is Y equal to 255?
    bne LoopBackground       ; if not, keep looping
    rts                      ; return from subroutine
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; RESET handler (called when NES resets or powers on)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RESET:
    INIT_NES                 ; macro to initialize the NES

Main:
    bit PPU_STATUS           ; read PPU_STATUS to reset PPU_ADDR latch
    ldx #$3F
    stx PPU_ADDR             ; set hi-byte of PPU_ADDR to $3F
    ldx #$00
    stx PPU_ADDR             ; set lo-byte of PPU_ADDR to $00

    jsr LoadPalette          ; jump to subroutine LoadPalette

    bit PPU_STATUS           ; read PPU_STATUS to reset PPU_ADDR latch
    ldx #$20
    stx PPU_ADDR             ; set hi-byte of PPU_ADDR to $20
    ldx #$00
    stx PPU_ADDR             ; set lo-byte of PPU_ADDR to $00    

    jsr LoadBackground       ; jump to subroutine LoadBackground

EnablePPURendering:
    lda #%10010000           ; enable NMI interrupt and set background to use
                             ; the second pattern table at ($1000)
    sta PPU_CTRL
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
;; Palette data for background and sprites
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PaletteData:
.byte $0F,$2A,$0C,$3A, $0F,$2A,$0C,$3A, $0F,$2A,$0C,$3A, $0F,$2A,$0C,$3A ; BG
.byte $0F,$10,$00,$26, $0F,$10,$00,$26, $0F,$10,$00,$26, $0F,$10,$00,$26 ; SP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Background data that must be copied to the nametable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BackgroundData:
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$36,$37,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$35,$25,$25,$38,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$60,$61,$62,$63,$24,$24,$24,$24
.byte $24,$36,$37,$24,$24,$24,$24,$24,$39,$3a,$3b,$3c,$24,$24,$24,$24,$53,$54,$24,$24,$24,$24,$24,$24,$64,$65,$66,$67,$24,$24,$24,$24
.byte $35,$25,$25,$38,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$55,$56,$24,$24,$24,$24,$24,$24,$68,$69,$26,$6a,$24,$24,$24,$24
.byte $45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45
.byte $47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47
.byte $47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CHR-ROM data, included from an external .chr file
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.segment "CHARS"
.incbin "tiles.chr"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Vectors with the addresses of the handlers at $FFFA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.segment "VECTORS"
.word NMI                    ; address of the NMI handler
.word RESET                  ; address of the RESET handler
.word IRQ                    ; address of the IRQ handler
