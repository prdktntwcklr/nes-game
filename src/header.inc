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
