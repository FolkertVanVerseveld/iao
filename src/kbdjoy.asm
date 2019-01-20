:BasicUpstart2(start)

start:
	jsr handle_input
	jmp start

handle_input:
	// save cia state
	lda $dc02
	sta key_ddr0
	lda $dc03
	sta key_ddr1
	jsr Keyboard
	bcs !+
	stx key_x
	sty key_y
	cmp #$ff
	beq !no_alpha+
	// TODO handle alphanumeric key
	sta $0400
!no_alpha:
	// TODO handle X-Y key
	// either X or Y is nonzero
	ldx key_x
	ldy key_y
	stx $0401
	sty $0402
	//inc $d020
!:
	// restore cia state
	//lda key_ddr0
	lda #0
	sta $dc02
	lda key_ddr1
	sta $dc03
	// read joy2 state
	lda $dc00
	and #%11111
	// TODO handle joystick
	sta joy2
	sta $0400 + 40
	rts

joy2:
	.byte 0

key_x:
	.byte 0
key_y:
	.byte 0

key_ddr0:
	.byte 0
key_ddr1:
	.byte 0

#import "kbd.asm"
