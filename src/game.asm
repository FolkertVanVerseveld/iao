:BasicUpstart2(start)

/*
Core game mechanics
Code: methos, theezakje
*/

#import "zeropage.inc"

#import "macros.inc"
#import "pseudo.lib"

.var vic = 2 * $4000
.var screen_main      = vic + 0 * $0400
.var screen_subsidies = vic + 1 * $0400
.var screen_log       = vic + 2 * $0400
.var screen_options   = vic + 3 * $0400
.var colram = $d800
.var sprdata = vic + 15 * $0400

.var irq_middle_line = $ef

start:
	jsr init
	jsr setup_interrupt
	jsr init_sprites
	jsr copy_screens

game_loop:
	jsr joy_ctl
	jsr check_space
	jmp game_loop

joy_ctl:
	// show joy2 for debug purposes
	.if (false) {
	lda #1
	sta colram
	sta colram + 1

	lda $dc00
	sta screen_main
	sta joy2
	} else {
	lda $dc00
	sta joy2
	}

	ldx #0

	cmp #$77
	bne !+
	ldx #1
	cpx joy2_dir
	beq !+
	jsr scr_next
!:
	cmp #$7b
	bne !+
	ldx #2
	cpx joy2_dir
	beq !+
	jsr scr_prev
!:

	stx joy2_dir
	rts

scr_next:
	// window = (window + 1) % screen_count
	lda window
	clc
	adc #1
	and #4 - 1
	sta window

	jmp update_screen

scr_prev:
	// window = (window + screen_count - 1) % screen_count
	lda window
	clc
	adc #4 - 1
	and #4 - 1
	sta window

	jmp update_screen

init:
	// clear zero page area [2, $e0]
	ldx #2
	lda #0
!:
	sta 0, x
	inx
	cpx #$e0
	bne !-
	rts

check_space:
	lda $dc01
	cmp #$ef
	beq !+
	rts
!:
	pla
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
	sta $d015

	qri : #irq_top

// top irq
irq_top:
	irq

	lda #$1b //If you want to display a bitmap pic, use #$3b instead
	sta $d011

	ldx window
	lda tbl_bkg_col, x
	sta $d021

	lda #%1111
	sta $d015

	qri #irq_middle_line : #irq_middle

irq_middle:
	irq

	lda #BLACK
	sta $d020
	sta $d021

	lda #$fa
	sta $d012
	lda #$1b //If you want to display a bitmap pic, use #$3b instead
	sta $d011

	qri : #irq_bottom

init_sprites:
	ldx #0
!:
	lda spr_star, x
	sta sprdata, x
	inx
	cpx #63
	bne !-

	lda #(sprdata / 64 - vic)

	sta screen_main + $3f8
	sta screen_main + $3f9
	sta screen_main + $3fa
	sta screen_main + $3fb
	sta screen_subsidies + $3f8
	sta screen_subsidies + $3f9
	sta screen_subsidies + $3fa
	sta screen_subsidies + $3fb

	lda #%1111
	sta $d015

	// sprite completely visible in range [24, 320]
	// sprite is 24 pixels wide, so:
	lda #24 - 24 / 2 + 0 * 80 + 40
	sta $d000
	lda #24 - 24 / 2 + 1 * 80 + 40
	sta $d002
	lda #24 - 24 / 2 + 2 * 80 + 40
	sta $d004
	lda #24 - 24 / 2 + 3 * 80 + 40
	sta $d006
	lda #$18
	sta $d001
	sta $d003
	sta $d005
	sta $d007

	// highest bit of spr3 must be set
	lda #%00001000
	sta $d010

	rts

tbl_bkg_col:
	// screens: map, money, log, settings
	.byte GREEN, BLACK, GREY, BLACK

copy_screens:
	// copy first screen
	ldx #0
!:
	lda level1_image_data + $000, x
	sta screen_main       + $000, x
	lda level1_image_data + $100, x
	sta screen_main       + $100, x
	lda level1_image_data + $200, x
	sta screen_main       + $200, x
	lda level1_image_data + $2e8, x
	sta screen_main       + $2e8, x

	lda level1_color_data + $000, x
	sta colram            + $000, x
	lda level1_color_data + $100, x
	sta colram            + $100, x
	lda level1_color_data + $200, x
	sta colram            + $200, x
	lda level1_color_data + $2e8, x
	sta colram            + $2e8, x

	dex
	bne !-

	lda #%00000100
	sta $d018

	// copy other screens
!:
	lda subsidies_image  + $000, x
	sta screen_subsidies + $000, x
	lda subsidies_image  + $100, x
	sta screen_subsidies + $100, x
	lda subsidies_image  + $200, x
	sta screen_subsidies + $200, x
	lda subsidies_image  + $2e8, x
	sta screen_subsidies + $2e8, x

	lda #' '
	sta screen_log + $000, x
	sta screen_log + $100, x
	sta screen_log + $200, x
	sta screen_log + $2e8, x
	sta screen_options + $000, x
	sta screen_options + $100, x
	sta screen_options + $200, x
	sta screen_options + $2e8, x
	dex
	bne !-

	rts

update_screen:
	ldx window
	lda vec_colram_lo, x
	sta jmp_buf
	lda vec_colram_hi, x
	sta jmp_buf + 1
	jmp (jmp_buf)

copy_colram0:
	lda #%00000100
	sta $d018

	ldx #0
!:
	lda level1_color_data + $000, x
	sta colram            + $000, x
	lda level1_color_data + $100, x
	sta colram            + $100, x
	lda level1_color_data + $200, x
	sta colram            + $200, x
	lda level1_color_data + $2e8, x
	sta colram            + $2e8, x

	dex
	bne !-
	rts

copy_colram1:
	lda #%00010100
	sta $d018

	ldx #0
!:
	lda subsidies_colors + $000, x
	sta colram           + $000, x
	lda subsidies_colors + $100, x
	sta colram           + $100, x
	lda subsidies_colors + $200, x
	sta colram           + $200, x
	lda subsidies_colors + $2e8, x
	sta colram           + $2e8, x

	dex
	bne !-
	rts

copy_colram3:
	lda #%00100100
	sta $d018

	ldx #0
!:
	lda options_colors + $000, x
	sta colram         + $000, x
	lda options_colors + $100, x
	sta colram         + $100, x
	lda options_colors + $200, x
	sta colram         + $200, x
	lda options_colors + $2e8, x
	sta colram         + $2e8, x

	dex
	bne !-
	rts

// jumptable
vec_colram_lo:
	.byte <copy_colram0
	.byte <copy_colram1
	.byte <copy_colram3
	.byte <copy_colram3
vec_colram_hi:
	.byte >copy_colram0
	.byte >copy_colram1
	.byte >copy_colram3
	.byte >copy_colram3

.pc = * "main screen"
#import "level1_europe.asm"

.pc = * "subsidies screen"
#import "subsidies.asm"

.pc = * "options screen"
#import "options.asm"

.pc = * "sprites"
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
