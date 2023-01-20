;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The iNES header (total 16 bytes) at $7FF0
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
    ldx #$FF
    txs                      ; initialize stack pointer to $01FF
    inx                      ; increment X from $FF to $0 (overflow)
                             ; to start from $0 which is not zeroed out below
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
;; Vectors with the addresses of the handlers at $FFFA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.segment "VECTORS"
.word NMI                    ; address of the NMI handler
.word RESET                  ; address of the RESET handler
.word IRQ                    ; address of the IRQ handler
