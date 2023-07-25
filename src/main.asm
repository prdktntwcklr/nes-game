.include "constants.inc"
.include "header.inc"
.include "reset.inc"
.include "utils.inc"

.segment "ZEROPAGE"
Frame:   .res 1              ; reserve 1 byte to store the number of frames
Clock60: .res 1              ; reserve 1 byte to store a counter that increments
                             ; every second (every 60 frames)
BgPtr:   .res 2              ; reserve 2 bytes (16 bits) to store a pointer to
                             ; the background address (low byte first, LE)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PRG-ROM code located at $8000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.segment "CODE"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to load all 32 color palette values from ROM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc LoadPalette
    PPU_SETADDR $3F00
    ldy #0                   ; Y = 0
:   lda PaletteData,y        ; lookup byte in ROM
    sta PPU_DATA             ; set value to send to PPU_DATA
    iny                      ; Y++
    cpy #32                  ; is Y equal to 32?
    bne :-                   ; if not, keep looping to previous unamed label
    rts                      ; return from subroutine
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to load tiles and attributes into the first nametable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc LoadBackground
    lda #<BackgroundData     ; Fetch low byte of BackgroundData address
    sta BgPtr
    lda #>BackgroundData     ; Fetch high byte of BackgroundData address
    sta BgPtr+1

    PPU_SETADDR $2000

    ldx #$00                 ; x is outer loop index (hi-byte) from $0 to $4
    ldy #$00                 ; y is inner loop index (lo-byte) from $0 to $FF

OuterLoop:
InnerLoop:
    lda (BgPtr),y            ; Fetch the value *pointed* by BgPtr + Y
    sta PPU_DATA             ; Store in the PPU data
    iny                      ; Y++
    cpy #0                   ; If Y == 0 (wrapped around 256 times)?
    beq IncreaseHiByte       ; Then: we need to increase the hi-byte
    jmp InnerLoop            ; Else: Continue with the inner loop
IncreaseHiByte:
    inc BgPtr+1              ; We increment the hi-byte pointer to point to the
                             ; next background section (next 255-chunk)
    inx                      ; X++
    cpx #4                   ; Compare X with #4
    bne OuterLoop            ; If X is still not 4, then we keep looping back to
                             ; the outer loop

    rts                      ; Return from subroutine
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to load text in the nametable until it finds a 0-terminator
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc LoadText
    PPU_SETADDR $21CB        ; set position where text starts

    ldy #0                   ; Y = 0
Loop:
    lda TextMessage,y        ; fetch character byte from ROM
    beq EndLoop              ; if character is 0, end the loop

    cmp #32                  ; compare loaded character to ASCII #32 (space)
    bne DrawLetter           ; if not space, draw a letter
DrawSpace:
    lda #$24                 ; tile $24 is the empty tile
    sta PPU_DATA             ; store data and advance PPU address
    jmp NextChar             ; proceed to the next character
DrawLetter:
    sec                      ; set carry before subtracting
    sbc #55                  ; map byte to char tile by subtracting 55
    sta PPU_DATA             ; store data and advance PPU address
NextChar:
    iny                      ; Y++
    jmp Loop                 ; continue looping since we are not done
EndLoop:
    rts                      ; Return from subroutine
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; RESET handler (called when NES resets or powers on)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RESET:
    INIT_NES                 ; macro to initialize the NES

    lda #0
    sta Frame                ; initialize frame variable to zero
    sta Clock60              ; initialize Clock60 variable to zero

Main:
    jsr LoadPalette          ; jump to subroutine LoadPalette
    jsr LoadBackground       ; jump to subroutine LoadBackground
    jsr LoadText             ; draw the text message on the nametable

EnablePPURendering:
    lda #%10010000           ; enable NMI interrupt and set background to use
                             ; the second pattern table at ($1000)
    sta PPU_CTRL
    lda #0
    sta PPU_SCROLL           ; disable scroll in X
    sta PPU_SCROLL           ; disable scroll in Y
    lda #%00011110
    sta PPU_MASK             ; set PPU_MASK bits to show background and sprites

LoopForever:
    jmp LoopForever          ; force an infinite loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; NMI interrupt handler
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NMI:
    inc Frame                ; increment frame variable
    lda Frame                ; load frame into Accumulator
    cmp #60                  ; check if frame has reached 60
    bne Skip                 ; if not 60, bypass
    inc Clock60              ; if 60, increment Clock60
    lda #0
    sta Frame                ; reset frame variable to zero
Skip:
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
.byte $22,$29,$1A,$0F, $22,$36,$17,$0F, $22,$30,$21,$0F, $22,$27,$17,$0F ; Background palette
.byte $22,$16,$27,$18, $22,$1A,$30,$27, $22,$16,$30,$27, $22,$0F,$36,$17 ; Sprite palette

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Background data with tile numbers that must be copied to the nametable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BackgroundData:
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$36,$37,$36,$37,$36,$37,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$35,$25,$25,$25,$25,$25,$25,$38,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$36,$37,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$39,$3A,$3B,$3A,$3B,$3A,$3B,$3C,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$35,$25,$25,$38,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$39,$3A,$3B,$3C,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$53,$54,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$55,$56,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$53,$54,$24,$24,$24,$24,$24,$24,$24,$24,$45,$45,$53,$54,$45,$45,$53,$54,$45,$45,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$55,$56,$24,$24,$24,$24,$24,$24,$24,$24,$47,$47,$55,$56,$47,$47,$55,$56,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$60,$61,$62,$63,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$31,$32,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$64,$65,$66,$67,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$30,$26,$34,$33,$24,$24,$24,$24,$36,$37,$36,$37,$24,$24,$24,$24,$24,$24,$24,$68,$69,$26,$6A,$24,$24,$24,$24
.byte $24,$24,$24,$24,$30,$26,$26,$26,$26,$33,$24,$24,$35,$25,$25,$25,$25,$38,$24,$24,$24,$24,$24,$24,$68,$69,$26,$6A,$24,$24,$24,$24
.byte $B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5
.byte $B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7
.byte $B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B6
.byte $B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7
.byte $B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5
.byte $B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Attribute data that is used for 4x4 sections of the background
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
AttributeData:
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
.byte %00000000, %10101010, %10101010, %00000000, %00000000, %00000000, %10101010, %00000000
.byte %00000000, %00000000, %00000000, %00000000, %11111111, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %10101010, %10101010, %10101010, %10101010, %00000000, %00000000
.byte %11111111, %00000000, %00000000, %00001111, %00001111, %00000011, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
.byte %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111
.byte %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Hardcoded ASCII message stored in ROM with 0-terminator
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TextMessage:
.byte "HELLO WORLD",$0

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
