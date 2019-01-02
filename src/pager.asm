:BasicUpstart2(start)

#import "local.inc"
#import "pseudo.lib"

.var vic = $0000
.var screen = vic + $0400
.var colram = $d800

.var irq_line_top = 50 + 6 * 8 - 5
.var irq_line_middle = 50 + 19 * 8 - 2

start:
	lda #0
	sta $d020
	sta $d021
	lda #%00010110
	sta $d018

	lda #' '
	ldx #$ff
!:
	sta $0400, x
	sta $0500, x
	sta $0600, x
	sta $06e8, x
	dex
	bne !-

	lda #0
	ldx #0
!:
	sta screen + 6 * 40, x
	sta screen + $100 + 6 * 40, x
	inx
	bne !-

.for (var i=0;i<25;i++) {
	lda #i
	sta screen + i * 40
}

.if (false) {
!:
	lda $dc00
	sta screen
	lda $dc01
	cmp #$ef
	bne !s+
	inc screen + 2
!s:
	sta screen + 1
	jmp !-
}

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

	lda vscroll
	sec
	sbc #1
	and #$07
	sta vscroll
	ora #$10

	sta $d011

	dec $d020

	asl $d019

	qri #irq_line_middle : #irq_middle

irq_middle:
	irq

	inc $d020
	ldx #5
	dex
	bne *-1

	ldx $d011

	lda #$10
	sta $d011

	txa
	and #$07
	bne !+
	jsr scroll
!:

	dec $d020

	qri #irq_line_top : #irq_top

dummy:
	rti

scroll:
	ldx #0
!:
	lda screen + 7 * 40, x
	sta screen + 6 * 40, x
	lda screen + $100 + 7 * 40, x
	sta screen + $100 + 6 * 40, x
	inx
	bne !-

	ldx #0
!:
	lda text, x
	sta screen + $200 + 6 * 40 - 40 + 8, x
	inx
	cpx #40
	bne !-
	rts

vscroll:
	.byte 0
steps:
	.byte 0

text:
	.text "a0123456789012345678901234b5678901234567"
	.text "a                         b             "
	.text "ba                         b            "
	.text "c a                         b           "
	.text "d  a                         b          "
	.text "e   a                         b         "
	.text "f    a                         b        "
	.text "g     a                         b       "
	.text "h      a                         b      "
	.text "i       a                         b     "
	.text "j        a                         b    "
	.text "k         a                         b   "
	.text "m          a                         b  "
	.text "n           a                         b "
	.text "o            a                         b"
	.text "a                         b             "
	.text "ba                         b            "
	.text "c a                         b           "
	.text "d  a                         b          "
	.text "e   a                         b         "
	.text "f    a                         b        "
	.text "g     a                         b       "
	.text "h      a                         b      "
	.text "i       a                         b     "
	.text "j        a                         b    "
	.text "k         a                         b   "
	.text "m          a                         b  "
	.text "n           a                         b "
	.text "o            a                         b"
