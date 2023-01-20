;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The iNES header (contains a total of 16 bytes with the flags at $7FF0)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment "HEADER"
.org $7FF0
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
.org $8000

RESET:
    sei                      ; disable all IRQ interrupts
    cld                      ; clear the decimal mode flag
    ldx #$FF
    txs                      ; initialize stack pointer to $01FF

    lda #$0                  ; A = 0
    inx                      ; increment X from $FF to $0
                             ; start from $0 which is not zeroed out below
MemLoop:
    sta $0,x                 ; store A (zero) into memory position at $0+X
    dex                      ; X--, wrap around to $FF
    bne MemLoop              ; branch if X is not equal to zero

NMI:
    rti                      ; return from interrupt

IRQ:
    rti                      ; return from interrupt

.segment "VECTORS"
.org $FFFA
.word NMI                    ; address of the NMI handler
.word RESET                  ; address of the RESET handler
.word IRQ                    ; address of the IRQ handler
