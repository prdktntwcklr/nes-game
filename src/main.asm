.include "constants.inc"
.include "header.inc"
.include "reset.inc"
.include "utils.inc"

.segment "ZEROPAGE"
Buttons: .res 1              ; reserve 1 byte to store button states
XPos:    .res 1              ; Player X position
YPos:    .res 1              ; Player Y position
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
;; Subroutine to read controller state and store it inside "Buttons" in RAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc ReadControllers
    lda #1                   ; A = 1
    sta Buttons              ; Buttons = 1
    sta JOYPAD1              ; set latch to 1 to begin input mode
    lsr                      ; A = 0
    sta JOYPAD1              ; set latch to 0 to begin output mode
LoopButtons:
    lda JOYPAD1              ; read a bit from controller and inverts it
                             ; also sends a signal to clock line to shift bits
    lsr                      ; shift right to place 1 bit read into Carry
    rol Buttons              ; rotate Carry bit into Buttons
    bcc LoopButtons          ; loop until Carry is set (from initial 1)
    rts
.endproc

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
;; Subroutine to load all 16 bytes into OAM-RAM starting at $0200
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc LoadSprites
    ldx #0
LoopSprite:
    lda SpriteData,x         ; We fetch bytes from the SpriteData lookup table
    sta $0200,x              ; We store the bytes starting at OAM address $0200
    inx                      ; X++
    cpx #32
    bne LoopSprite           ; Loop 32 times (8 hardware sprites, 4 bytes each)
    rts
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; RESET handler (called when NES resets or powers on)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RESET:
    INIT_NES                 ; macro to initialize the NES

InitVariables:
    lda #0
    sta Frame                ; initialize frame variable to zero
    sta Clock60              ; initialize Clock60 variable to zero
    ldx #0
    lda SpriteData,x         ; get Y coordinate from SpriteData
    sta YPos

    inx
    inx
    inx
    lda SpriteData,x         ; get X coordinate from SpriteData
    sta XPos                 ; XPos = 0

Main:
    jsr LoadPalette          ; jump to subroutine LoadPalette
    jsr LoadBackground       ; jump to subroutine LoadBackground
    jsr LoadText             ; draw the text message on the nametable
    jsr LoadSprites          ; load all sprites into OAM-RAM

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

    lda #$02                 ; Every frame, we copy spite data starting at $02**
    sta PPU_OAM_DMA          ; The OAM DMA copy starts when we write to $4014

    jsr ReadControllers      ; read controller inputs

CheckRightButton:
    lda Buttons
    and #BUTTON_RIGHT        ; #%00000001
    beq CheckLeftButton
    inc XPos                 ; X++
CheckLeftButton:
    lda Buttons
    and #BUTTON_LEFT         ; #%00000010
    beq CheckDownButton
    dec XPos                 ; X--
CheckDownButton:
    lda Buttons
    and #BUTTON_DOWN         ; #%00000100
    beq CheckUpButton
    inc YPos                 ; Y++
CheckUpButton:
    lda Buttons
    and #BUTTON_UP           ; #%00001000
    beq :+
    dec YPos                 ; Y--
:

UpdateSpritePosition:
    lda XPos
    sta $0203                ; Set the 1st sprite X position to be XPos
    sta $020B                ; Set the 3rd sprite X position to be XPos
    clc
    adc #8
    sta $0207                ; Set the 2nd sprite X position to be XPos + 8
    sta $020F                ; Set the 4th sprite X position to be XPos + 8

    lda YPos
    sta $0200                ; Set the 1st sprite Y position to be YPos
    sta $0204                ; Set the 2nd sprite Y position to be YPos
    clc
    adc #8
    sta $0208                ; Set the 3rd sprite Y position to be YPos + 8
    sta $020C                ; Set the 4th sprite Y position to be YPos + 8

UpdateSeconds:
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
.incbin "background.nam"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This is the OAM sprite attribute data data we will use in our game.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SpriteData:
; -------------------------------
; Mario:
;      Y   tile#  attributes   X
.byte $AE,  $3A,  %00000000,  $98
.byte $AE,  $37,  %00000000,  $A0
.byte $B6,  $4F,  %00000000,  $98
.byte $B6,  $4F,  %01000000,  $A0
; -------------------------------
; Goomba:
;      Y   tile#  attributes   X
.byte $93,  $70,  %00100011,  $C7 
.byte $93,  $71,  %00100011,  $CF 
.byte $9B,  $72,  %00100011,  $C7
.byte $9B,  $73,  %00100011,  $CF
; -------------------------------

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
