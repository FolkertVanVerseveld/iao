:BasicUpstart2(start)

/*
Simple 4 bits random number generator
Code: methos

uses lineair feedback shiftregister
*/

#import "zeropage.inc"
#import "io.inc"

.var vic = $0000
.var screen = vic + $0400

start:
	// read sort of random number
	lda $d012
	// make sure it is never zero
	bne !+
	lda #%1100
!:
	and #$f
	sta lfsr4_state

	ldy #16
!l:
	ldx lfsr4_state
	lda hexstring, x
!put:
	sta screen
	inc !put- + 1
	jsr lfsr4_next
	dey
	bne !l-

	jmp *

lfsr4_next:
	// bit = ((lfsr >> 0) ^ (lfsr >> 1)) & 1
	// lfsr = (lfsr >> 1) | (bit << 3)
	lda lfsr4_state
	lsr lfsr4_state
	eor lfsr4_state
	and #1
	beq !+
	lda #8
	ora lfsr4_state
	sta lfsr4_state
!:
	rts

hexstring:
	.text "0123456789abcdef"
