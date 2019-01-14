:BasicUpstart2(start)

#import "zeropage.inc"

#import "macros.inc"
#import "pseudo.lib"

.var vic = 2 * $4000
.var screen = vic + $0400
.var colram = $d800
.var sprdata = vic + 15 * $0400

.var irq_middle_line = $ef

start:
	jsr load_level
	jsr setup_interrupt

	lda #(sprdata / 64 - vic)
	sta screen + $3f8
	sta screen + $3f9
	lda #%11
	sta $d015
	lda #$10
	sta $d000
	sta $d001
	sta $d002
	lda #$ff
	sta $d003

!:
	lda $dc01
	cmp #$ef
	bne !-

	lda #0
	sta prg_index
	jmp top_loader_start

setup_interrupt:

	sei
	lda #$35
	sta $1

	lda #1
	sta $dd00

	lda #<irq_bottom
	sta $fffe
	lda #>irq_bottom
	sta $ffff
	lda #$1b
	sta $d011
	lda #$01
	sta $d01a
	// enable all NMIs
	lda #$7f
	sta $dc0d
	sta $dd0d
	lda $dc0d
	lda $dd0d

	asl $d019
	cli

	// enable all NMIs
	lda #$7f
	sta $dc0d
	sta $dd0d
	lda $dc0d
	lda $dd0d

	asl $d019
	cli

	rts

dummy:
	asl $d019
	rti


// bottom irq
irq_bottom:
	irq
	lda #$00
	sta $d012
	lda #$00
	sta $d011

	qri : #irq_top

// top irq
irq_top:
	irq
	lda #$fa
	sta $d012
	lda #$1b //If you want to display a bitmap pic, use #$3b instead
	sta $d011

	qri : #irq_bottom

load_level:
	// Set level colors: border black, background green
	borderColor(WHITE)
	backgroundColor(GREEN)

	jsr copy_image
	jsr copy_sprites
	rts

copy_sprites:
	ldx #0
!:
	lda spr_star, x
	sta sprdata, x
	inx
	cpx #63
	bne !-
	rts

	// fall through
copy_image: // Copied from uva.asm
	ldx #0
!l:
	lda level1_image_data + $000, x
	sta screen + $000, x
	lda level1_image_data  + $100, x
	sta screen + $100, x
	lda level1_image_data  + $200, x
	sta screen + $200, x
	lda level1_image_data  + $2e8, x
	sta screen + $2e8, x

	lda level1_color_data + $000, x
	sta colram + $000, x
	lda level1_color_data + $100, x
	sta colram + $100, x
	lda level1_color_data + $200, x
	sta colram + $200, x
	lda level1_color_data + $2e8, x
	sta colram + $2e8, x

	dex
	bne !l-
	rts


.pc = * "PETSCII art"

#import "level1_europe.asm"

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
