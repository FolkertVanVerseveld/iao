:BasicUpstart2(start)

#import "local.inc"
#import "pseudo.lib"

.var vic = $0000
.var screen = vic + $0400

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

.var amplitude = 90

.var irq_line_top = $20 - 1
.var irq_line_middle = cos_full(3, amplitude, center_y, 12) + 21 + 2

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
	lda #$00
	sta $d015

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
	jmp *

irq_top:
	irq

	inc $d020

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

	asl $d019
	dec $d020

	qri #irq_line_middle : #irq_middle

irq_middle:
	irq

	inc $d020

	lda #sinus_lo(0, amplitude, center_x, 12)
	sta $d000
	lda #cos_full(0, amplitude, center_y, 12)
	sta $d001
	lda #sinus_lo(1, amplitude, center_x, 12)
	sta $d002
	lda #cos_full(1, amplitude, center_y, 12)
	sta $d003
	lda #sinus_lo(2, amplitude, center_x, 12)
	sta $d004
	lda #cos_full(2, amplitude, center_y, 12)
	sta $d005
	lda #sinus_lo(10, amplitude, center_x, 12)
	sta $d006
	lda #cos_full(10, amplitude, center_y, 12)
	sta $d007
	lda #sinus_lo(11, amplitude, center_x, 12)
	sta $d008
	lda #cos_full(11, amplitude, center_y, 12)
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

	asl $d019
	dec $d020

	qri #irq_line_top : #irq_top

dummy:
	rti

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
