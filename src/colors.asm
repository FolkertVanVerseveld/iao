:BasicUpstart2(start)

start:
	ldx #0
	lda #' '
!:
	sta $0400, x
	sta $0500, x
	sta $0600, x
	sta $06e8, x
	dex
	bne !-
	ldx #0
!:
	lda #$e0
	sta $0400, x
	txa
	sta $d800, x
	lda text, x
	sta $0400 + 40, x
	inx
	cpx #16
	bne !-
	jmp *

text:
	.text "0123456789abcdef"
