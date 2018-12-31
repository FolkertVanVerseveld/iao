:BasicUpstart2(start)

.var vic = $0000
.var screen = vic + $0400

start:
	// clear screen
	lda #' '
	ldx #0
!:
	sta screen, x
	sta screen + $100, x
	sta screen + $200, x
	sta screen + $2e8, x
	inx
	bne !-
	// blue background and foreground
	lda #6
	sta $d020
	sta $d021
	// yellow stars
	lda #7
	ldx #8
!:
	dex
	sta $d027, x
	bne !-
	// setup sprite data
	ldx #8
	lda #(spr_star / 64 - vic)
!:
	dex
	sta screen + $03f8, x
	bne !-
	// move sprites
	lda #24
	sta $d000
	lda #50
	sta $d001
	lda #64
	sta $d002
	lda #50
	sta $d003
	lda #64
	sta $d004
	lda #229
	sta $d005
	lda #24
	sta $d006
	lda #229
	sta $d007
	lda #%00000110
	sta $d010
	// enable sprites
	lda #$0f
	sta $d015
	jmp *

.align $40
spr_star:
	.byte %00000000,%00011000,%00000000
	.byte %00000000,%00011000,%00000000
	.byte %00000000,%00011000,%00000000
	.byte %00000000,%00111100,%00000000
	.byte %00000000,%00111100,%00000000
	.byte %00000000,%00111100,%00000000
	.byte %00000000,%01111110,%00000000
	.byte %00000000,%01111110,%00000000
	.byte %11111111,%11111111,%11111111
	.byte %01111111,%11111111,%11111110
	.byte %00011111,%11111111,%11111000
	.byte %00000111,%11111111,%11100000
	.byte %00000011,%11111111,%11000000
	.byte %00000001,%11111111,%10000000
	.byte %00000001,%11111111,%10000000
	.byte %00000011,%11111111,%11000000
	.byte %00000011,%11100111,%11000000
	.byte %00000111,%10000001,%11100000
	.byte %00000111,%00000000,%11100000
	.byte %00000110,%00000000,%01100000
	.byte %00001100,%00000000,%00110000
