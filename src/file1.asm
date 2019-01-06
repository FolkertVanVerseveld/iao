* = $4000

.var vic = $0000
.var screen = vic + $0400

	ldx #0
!:
	txa
	sta screen, x
	inx
	bne !-
	rts
