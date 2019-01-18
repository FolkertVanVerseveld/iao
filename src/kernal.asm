:BasicUpstart2(start)

/*
simple demo using kernal routines.
code: methos
*/

#import "pseudo.lib"

.var vic = $0000
.var screen = vic + $0400

.var chrout = $ffd2

start:
	ldx #0
!:
	lda str, x
	jsr chrout
	inx
	cpx #str_end - str
	bne !-
	rts

str:
.encoding "petscii_upper"
.text "LOADING"
str_end:
