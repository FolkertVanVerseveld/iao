:BasicUpstart2(start)

#import "zeropage.inc"
#import "pseudo.lib"
#import "loader.inc"
#import "joy.inc"

.var vic = $0000
.var screen = vic + $0400

.var sid = $d400
.var colram = $d800

.function sinus_lo(i, amplitude, center, noOfSteps) {
	.return round(center+amplitude*sin(toRadians(i*360/noOfSteps))) & $ff
}

.function sinus_hi(i, amplitude, center, noOfSteps) {
	.return round(center+amplitude*sin(toRadians(i*360/noOfSteps)))	>> 8
}

.function cos_full(i, amplitude, center, noOfSteps) {
	.return round(center+amplitude*cos(toRadians(i*360/noOfSteps)))
}

.var center_x = 24 + (256 + 64 - 24) / 2
.var center_y = 50 + (229 - 50) / 2

.var amplitude = 88

.var irq_line_top = $20 - 1
.var irq_line_middle = cos_full(3, amplitude, center_y, 12) + 21 + 2

.var irq_line_middle_menu = $90

.var spr_delay = 4
.var spr_roll_steps = 12

//.var music = LoadSid(HVSC + "/MUSICIANS/0-9/20CC/Paul_Falco/Bomberboy.sid")
.var music = LoadSid("assets/Bomberboy.sid")

.var picture = LoadBinary("switch.koa", BF_KOALA)

.var vic2 = $4000
.var screen2 = vic2 + $2000

.var menu_screenram = vic2 + $2000
.var menu_bitmap = vic2

start:
	lda #3
	//lda #music.startSong - 1
	jsr music.init

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
	// also set colram
	lda #6
!:
	sta colram, x
	sta colram + $100, x
	sta colram + $200, x
	sta colram + $2e8, x
	inx
	bne !-

	// center text
	lda #%00010110
	sta $d018

	// set vic bank
	lda #%11
	sta $dd00

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
	// make sure sprites are invisible before irq kicks in
	lda #$00
	sta $d015
	// set draw order
	sta $d01b
	sta $d01c

	// center text
	lda #%00010110
	sta $d018

	ldx #0
	lda #6
!:
	sta colram + 8 * 40 + 13, x
	dex
	bne !-

	ldx #0
!:
	lda text, x
	sta screen + 8 * 40 + 13, x
	dex
	bne !-

	sei
	lda #$35		// Disable KERNAL and BASIC ROM
	sta $01			// Enable all RAM

	lda #<irq_top		// Setup IRQ vector
	sta $fffe
	lda #>irq_top
	sta $ffff

	lda #<dummy
	sta $fffa
	sta $fffc
	lda #>dummy
	sta $fffb
	sta $fffd

	lda #%00011011		// Load screen control:
				// Vertical scroll    : 3
				// Screen height      : 25 rows
				// Screen             : ON
				// Mode               : TEXT
				// Extended background: OFF
	sta $d011       	// Set screen control

	lda #irq_line_top
	sta $d012

	lda #$01		// Enable mask
	sta $d01a		// IRQ interrupt ON

	lda #%01111111		// Load interrupt control CIA 1:
				// Timer A underflow : OFF
				// Timer B underflow : OFF
				// TOD               : OFF
				// Serial shift reg. : OFF
				// Pos. edge FLAG pin: OFF
	sta $dc0d		// Set interrupt control CIA 1
	sta $dd0d		// Set interrupt control CIA 2

	lda $dc0d		// Clear pending interrupts CIA 1
	lda $dd0d		// Clear pending interrupts CIA 2

	lda #$00
	sta $dc0e

	lda #$01
	sta $d019		// Acknowledge pending interrupts

	cli			// Start firing interrupts

wait_logo:
	jmp wait_logo

.pc = * "menu code"

to_menu:

	// wait for good rasterline
	bit $d011
	bmi *-3

	bit $d011
	bpl *-3

	// change irq
	sei

	lda #<irq_top_menu
	sta $fffe
	lda #>irq_top_menu
	sta $ffff

	cli

	// change sprites
	lda #(spr_new_game0 / 64 - vic2)
	sta screen2 + $03f8
	lda #(spr_new_game1 / 64 - vic2)
	sta screen2 + $03f9
	lda #(spr_new_game2 / 64 - vic2)
	sta screen2 + $03fa
	lda #(spr_notes0 / 64 - vic2)
	sta screen2 + $03fb
	lda #(spr_credits0 / 64 - vic2)
	sta screen2 + $03fc
	lda #(spr_credits1 / 64 - vic2)
	sta screen2 + $03fd
	lda #(spr_credits2 / 64 - vic2)
	sta screen2 + $03fe
	lda #(spr_credits3 / 64 - vic2)
	sta screen2 + $03ff

	lda #%11111111
	sta $d015
	lda #0
	sta $d010

	lda #CYAN
	sta $d020
	lda #picture.getBackgroundColor()
	sta $d021

	ldx #0
!:
	.for (var i = 0; i < 4; i++) {
		lda menu_colram + i * $100, x
		sta colram + i * $100, x
	}
	inx
	bne !-

	// wait
	bit $d011
	bmi *-3

	bit $d011
	bpl *-3

	// update vic bank
	lda #2
	sta $dd00

	// enable bitmap mode
	lda #$3b
	sta $d011

	lda #$d8
	sta $d016

	// screen at $4000, characters at $6000
	lda #%10000000
	sta $d018

!:
	lda $dc01
	cmp #$ef
	bne !-

.pc = * "load game"
	// kill irq
	sei

	lda #$1b
	sta $d011
	lda #$c8
	sta $d016

	lda #<dummy
	sta $fffe
	lda #>dummy
	sta $ffff

	cli

	// kill sid
	ldx #0
!:
	sta sid, x
	inx
	cpx #$20
	bne !-

	lda #1
	sta prg_index
	jmp top_loader_start

.pc = * "irqs"

irq_top:
	irq

	ldx #0
!:
	lda spr_coltbl_top, x
	sta $d027, x
	inx
	cpx #7
	bne !-

	lda #sinus_lo(3, amplitude, center_x, 12)
	sta $d000
	lda #cos_full(3, amplitude, center_y, 12)
	sta $d001
	lda #sinus_lo(4, amplitude, center_x, 12)
	sta $d002
	lda #cos_full(4, amplitude, center_y, 12)
	sta $d003
	lda #sinus_lo(5, amplitude, center_x, 12)
	sta $d004
	lda #cos_full(5, amplitude, center_y, 12)
	sta $d005
	lda #sinus_lo(6, amplitude, center_x, 12)
	sta $d006
	lda #cos_full(6, amplitude, center_y, 12)
	sta $d007
	lda #sinus_lo(7, amplitude, center_x, 12)
	sta $d008
	lda #cos_full(7, amplitude, center_y, 12)
	sta $d009
	lda #sinus_lo(8, amplitude, center_x, 12)
	sta $d00a
	lda #cos_full(8, amplitude, center_y, 12)
	sta $d00b
	lda #sinus_lo(9, amplitude, center_x, 12)
	sta $d00c
	lda #cos_full(9, amplitude, center_y, 12)
	sta $d00d
.var spr_hi_mask = 0
.for (var i=0;i<8;i++) {
	.eval spr_hi_mask = spr_hi_mask | (sinus_hi(3 + i, amplitude, center_x, 12) << i)
}
	lda #spr_hi_mask
	sta $d010
	lda #$7f
	sta $d015

	jsr spr_roll
	//asl $d019

	qri #irq_line_middle : #irq_middle

irq_middle:
	irq

	ldx #0
!:
	lda spr_coltbl_middle, x
	sta $d027, x
	inx
	cpx #5
	bne !-

	lda #sinus_lo(10, amplitude, center_x, 12)
	sta $d000
	lda #cos_full(10, amplitude, center_y, 12)
	sta $d001
	lda #sinus_lo(11, amplitude, center_x, 12)
	sta $d002
	lda #cos_full(11, amplitude, center_y, 12)
	sta $d003
	lda #sinus_lo(0, amplitude, center_x, 12)
	sta $d004
	lda #cos_full(0, amplitude, center_y, 12)
	sta $d005
	lda #sinus_lo(1, amplitude, center_x, 12)
	sta $d006
	lda #cos_full(1, amplitude, center_y, 12)
	sta $d007
	lda #sinus_lo(2, amplitude, center_x, 12)
	sta $d008
	lda #cos_full(2, amplitude, center_y, 12)
	sta $d009

.eval spr_hi_mask = 0
.for (var i=0;i<3;i++) {
	.eval spr_hi_mask = spr_hi_mask | (sinus_hi(i, amplitude, center_x, 12) << i)
}
	.eval spr_hi_mask = spr_hi_mask | (sinus_hi(10, amplitude, center_x, 12) << 3)
	.eval spr_hi_mask = spr_hi_mask | (sinus_hi(11, amplitude, center_x, 12) << 4)
	lda #spr_hi_mask
	sta $d010
	lda #$1f
	sta $d015

	jsr text_roll
	//asl $d019
	jsr music.play

	qri #irq_line_top : #irq_top

irq_top_menu:
	irq

	jsr move_sprites
	jsr music.play

	//asl $d019

	qri #irq_line_middle_menu : #irq_middle_menu

irq_middle_menu:
	irq

	inc $d020
	ldx #8
	dex
	bne *-1
	dec $d020

	qri #irq_line_top : #irq_top_menu

move_sprites:

	lda spr_menu_pos
	clc
	adc #1
	and #$20 - 1
	sta spr_menu_pos
	tax
	// new game sprites
	lda #$a0
	sta $d000
	sta $d006 // credits x position
	clc
	adc #24
	sta $d002
	adc #24
	sta $d004
	lda spr_menu_new_y, x
	sta $d001
	sta $d003
	sta $d005
	// options y position
	clc
	adc #30
	sta $d007
	// credits sprites
	lda #$30
	sta $d008
	clc
	adc #24
	sta $d00a
	adc #24
	sta $d00c
	adc #24
	sta $d00e
	lda spr_menu_credits_y, x
	sta $d009
	sta $d00b
	sta $d00d
	sta $d00f
	// sprite colors
	lda #BLACK
	ldx #0
!:
	sta $d027, x
	inx
	cpx #8
	bne !-
	rts

dummy:
	rti

spr_roll:
	ldx spr_delay_counter
	beq !+
	dex
	stx spr_delay_counter
	rts
!:
	ldx #spr_delay
	stx spr_delay_counter

	ldx spr_counter
!cmp_counter:
	cpx #32 - 1
	bne !next+
	ldx spr_wait_counter
	beq !+
	dex
	stx spr_wait_counter
	rts
!:
	lda !cmp_counter- + 1
	cmp #52 - 1
	beq !done+
	lda #52 - 1
	sta !cmp_counter- + 1
!:
	rts
!done:
	lda #$2c
	sta wait_logo
	rts
!next:
	inx
	stx spr_counter

	ldy #0
!:
!fetch_col:
	lda fade_tbl, x
	sta spr_coltbl_top, y
	dex
	iny
	cpy #spr_roll_steps
	bne !-
	rts

text_roll:
	lda spr_coltbl_top + 7
	ldx #0
!:
	sta colram + 8 * 40 + 13, x
	dex
	bne !-
	rts

spr_wait_counter:
	.byte 50

spr_delay_counter:
	.byte spr_delay

spr_counter:
	.byte spr_roll_steps

spr_coltbl_top:
	//.byte 13, 3, 5, 10, 14, 4, 6
	.byte 6, 6, 6, 6, 6, 6, 6
spr_coltbl_middle:
	.byte 6, 6, 6, 6, 6
	//.byte 7, 7, 7, 7, 7

fade_tbl:
	.byte 6, 6, 6, 6, 6, 6, 6, 6
	.byte 6, 6, 6, 6
	.byte 6, 4, 14, 10, 5, 3, 13, 7
	.byte 7, 7, 7, 7, 7, 7, 7, 7
	.byte 7, 7, 7, 7
	.byte 7, 13, 3, 5, 10, 14, 4, 6
	.byte 6, 6, 6, 6, 6, 6, 6, 6
	.byte 6, 6, 6, 6

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
text:
	.text "SWITCH project             "
	.text "                                        "
	.text "           Software Workbench           "
	.text "            for Interactive,            "
	.text "           Time Critical and            "
	.text "          Highly self-adaptive          "
	.text "           Cloud applications           "

* = music.location "Tune"
	.fill music.size, music.getData(i)

.pc = * "menu color ram"

menu_colram:
	.fill picture.getColorRamSize(), picture.getColorRam(i)

.pc = menu_bitmap "menu switch logo"
	.fill picture.getBitmapSize(), picture.getBitmap(i)

.pc = menu_screenram "ScreenRam"
	.fill picture.getScreenRamSize(), picture.getScreenRam(i)

.align $40
.pc = * "menu sprites"
spr_new_game0:
	.byte $1f,$8f,$e0,$20,$08,$18,$40,$08
	.byte $08,$40,$08,$04,$80,$08,$04,$80
	.byte $08,$04,$80,$08,$04,$40,$08,$04
	.byte $60,$08,$08,$1c,$08,$18,$03,$8f
	.byte $e0,$00,$88,$00,$00,$48,$00,$00
	.byte $48,$00,$00,$48,$00,$00,$88,$00
	.byte $01,$88,$00,$7e,$08,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
.align $40
spr_new_game1:
	.byte $ff,$cf,$fc,$80,$08,$00,$80,$08
	.byte $00,$80,$08,$00,$80,$08,$00,$80
	.byte $08,$00,$80,$08,$00,$80,$08,$00
	.byte $80,$08,$00,$fe,$0f,$e0,$80,$08
	.byte $00,$80,$08,$00,$80,$08,$00,$80
	.byte $08,$00,$80,$08,$00,$80,$08,$00
	.byte $80,$08,$00,$ff,$cf,$fc,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
.align $40
spr_new_game2:
	.byte $80,$00,$00,$80,$00,$00,$80,$00
	.byte $00,$80,$00,$00,$80,$00,$00,$80
	.byte $00,$00,$80,$00,$00,$80,$00,$00
	.byte $80,$00,$00,$80,$00,$00,$80,$00
	.byte $00,$80,$00,$00,$80,$00,$00,$80
	.byte $00,$00,$80,$00,$00,$80,$00,$00
	.byte $80,$00,$00,$ff,$c0,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
.align $40
spr_notes0:
	.byte %00111111,%00001100,%00001100
	.byte %01111111,%10001100,%00001100
	.byte %11100001,%11001100,%00001100
	.byte %11000000,%11001100,%00001100
	.byte %11000000,%11001100,%00001100
	.byte %11000000,%11001100,%00001100
	.byte %11000000,%11001100,%00001100
	.byte %11000000,%11001100,%00001100
	.byte %11000000,%11001100,%00001100
	.byte %11000000,%11001100,%00001100
	.byte %11000000,%11001100,%00001100
	.byte %11000000,%11001100,%00001100
	.byte %11000000,%11001100,%00001100
	.byte %11000000,%11001100,%00001100
	.byte %11000000,%11001110,%00011100
	.byte %11100001,%11000111,%11111000
	.byte %01111111,%10000011,%11110000
	.byte %00111111,%00000000,%11000000
	.byte %00000000,%00000000,%00000000
	.byte %00000000,%00000000,%00000000
	.byte %00000000,%00000000,%00000000
.align $40
spr_notes1:
	.byte %11111111,%11001111,%11111000
	.byte %11111111,%11001111,%11111100
	.byte %11000000,%00001100,%00011100
	.byte %11000000,%00001100,%00001100
	.byte %11000000,%00001100,%00001100
	.byte %11000000,%00001100,%00001100
	.byte %11000000,%00001100,%00001100
	.byte %11000000,%00001100,%00011100
	.byte %11111110,%00001111,%11111100
	.byte %11111110,%00001111,%11111000
	.byte %11000000,%00001111,%00000000
	.byte %11000000,%00001111,%10000000
	.byte %11000000,%00001101,%11000000
	.byte %11000000,%00001100,%11100000
	.byte %11000000,%00001100,%01110000
	.byte %11000000,%00001100,%00111000
	.byte %11111111,%11001100,%00011100
	.byte %11111111,%11001100,%00001100
	.byte %00000000,%00000000,%00000000
	.byte %00000000,%00000000,%00000000
	.byte %00000000,%00000000,%00000000

.align $40
spr_credits0:
	.byte $03,$e7,$f0,$0c,$04,$0c,$10,$04
	.byte $04,$20,$04,$02,$40,$04,$02,$40
	.byte $04,$02,$80,$04,$02,$80,$04,$02
	.byte $80,$04,$04,$80,$04,$0c,$80,$07
	.byte $f0,$80,$05,$00,$80,$04,$80,$40
	.byte $04,$40,$40,$04,$20,$20,$04,$10
	.byte $10,$04,$08,$0c,$04,$04,$03,$e4
	.byte $02,$00,$00,$00,$00,$00,$00,$00
.align $40
spr_credits1:
	.byte $ff,$cf,$c0,$80,$08,$30,$80,$08
	.byte $10,$80,$08,$08,$80,$08,$08,$80
	.byte $08,$04,$80,$08,$04,$80,$08,$04
	.byte $80,$08,$04,$fe,$08,$04,$80,$08
	.byte $04,$80,$08,$04,$80,$08,$04,$80
	.byte $08,$08,$80,$08,$08,$80,$08,$10
	.byte $80,$08,$30,$ff,$cf,$c0,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
.align $40
spr_credits2:
	.byte $f9,$ff,$c1,$20,$08,$02,$20,$08
	.byte $04,$20,$08,$04,$20,$08,$08,$20
	.byte $08,$08,$20,$08,$08,$20,$08,$04
	.byte $20,$08,$06,$20,$08,$01,$20,$08
	.byte $00,$20,$08,$00,$20,$08,$00,$20
	.byte $08,$00,$20,$08,$00,$20,$08,$00
	.byte $20,$08,$00,$f8,$08,$07,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
.align $40
spr_credits3:
	.byte $f8,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$c0,$00,$00,$38,$00
	.byte $00,$08,$00,$00,$04,$00,$00,$04
	.byte $00,$00,$04,$00,$00,$08,$00,$00
	.byte $18,$00,$00,$e0,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00

.align $40
spr_menu_credits_y:
	.fill $20, round($e0 + $4 * sin(toRadians(i * 360 / $20)))

spr_menu_new_y:
	.fill $20, round($38 + $4 * sin(toRadians(i * 360 / $20)))

spr_menu_pos:
	.byte 0
