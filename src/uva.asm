:BasicUpstart2(start)

// UvA logo intro part

#import "local.inc"
#import "pseudo.lib"

//.var music = LoadSid(HVSC + "/MUSICIANS/G/Gangstar/Hyperraum.sid")
.var music = LoadSid(HVSC + "/MUSICIANS/0-9/20CC/van_Santen_Edwin/Megamix_II_C64.sid")

.var vic = $0000
.var screen = vic + $0400
.var colram = $d800

.var scroll_screen = screen
.var scroll_colram = colram

.var irq_line_top = $20
.var irq_line_middle = $3b
.var irq_line_bottom = $f8

.var fade_step = $5

start:
	lda #0
	sta $d020
	sta $d021

	jsr copy_image

	// just put some colors in scroller
	ldx #0
!:
	lda scroll_coltbl, x
	sta scroll_colram + 4, x
	inx
	lda scroll_coltbl, x
	sta scroll_colram + 4, x
	inx
	cpx #32
	bne !-

	ldx #0
	ldy #0
	lda #music.startSong - 1
	jsr music.init

	// inline: setup irq
	sei
	lda #$35
	sta $1
	mov16 #irq_top : $fffe
	// use dummy nmi and cold reset
	lda #<dummy
	sta $fffa
	sta $fffc
	lda #>dummy
	sta $fffb
	sta $fffd
	mov #$1b : $d011
	mov #irq_line_top : $d012
	mov #$81 : $d01a
	// init timers
	mov #$7f : $dc0d
	mov #$7f : $dd0d
	lda $dc0d
	lda $dd0d
	// purge pending interrupts
	asl $d019
	cli

	jmp *


copy_image:
	ldx #0
!l:
	lda image  + $000, x
	sta screen + $000, x
	lda image  + $100, x
	sta screen + $100, x
	lda image  + $200, x
	sta screen + $200, x
	lda image  + $2e8, x
	sta screen + $2e8, x
	lda #0
	sta colram + $000, x
	sta colram + $100, x
	sta colram + $200, x
	sta colram + $2e8, x
	dex
	bne !l-
	rts

//---------------------------------------------------------
irq_top:
	irq

	//inc $d020
scroll_vector:
	bit scroll
	//dec $d020

	qri #irq_line_middle : #irq_music

irq_music:
	irq

	lda #$c8
	sta $d016

	//inc $d020
	jsr music.play
	//dec $d020

	qri #irq_line_bottom : #irq_bottom

irq_bottom:
	irq

	lda fade_times
	bpl !+
	jmp !done+
!:

	ldx fade_wait
	beq !+
	dex
	stx fade_wait
	jmp !done+
!:

	jsr fade_roll


!done:
	qri #irq_line_top : #irq_top

!next:
	ldx #0
	stx fade_index

	dec fade_times
	ldx fade_times

.if (true) {
	// TODO advance fade color roll code
	lda fade_jtlo, x
	sta fade_roll + 1
	sta screen + 2 * 40 + 2
	lda fade_jthi, x
	sta fade_roll + 2
	sta screen + 2 * 40 + 3
} else {
	stx screen + 2 * 40 + 2
}

	rts

dummy:
	rti

// jump vector to proper roll code
fade_roll:
	jsr fade_roll1

	ldx fade_delay
	bne !wait+
	lda #fade_step
	sta fade_delay
	ldx fade_index
	cpx #9
	beq !next-
	inx
	stx fade_index
!wait:
	ldx fade_delay
	dex
	stx fade_delay

	rts

fade_roll1:
	ldx fade_index
	.for (var i = 0; i < 6; i++) {
		lda fade_tbl + i, x
		sta colram + (i + 1) * 40 + 17
		sta colram + (i + 1) * 40 + 17 + 1
		sta colram + (i + 1) * 40 + 17 + 2
		sta colram + (i + 1) * 40 + 17 + 3
		sta colram + (i + 1) * 40 + 17 + 4
		sta colram + (i + 1) * 40 + 17 + 5
	}

	rts

fade_roll2:
	ldx fade_index
	.for (var i = 0; i < 6; i++) {
		lda fade_tbl + i, x
		sta colram + (i + 8) * 40 + 17
		sta colram + (i + 8) * 40 + 17 + 1
		sta colram + (i + 8) * 40 + 17 + 2
		sta colram + (i + 8) * 40 + 17 + 3
		sta colram + (i + 8) * 40 + 17 + 4
		sta colram + (i + 8) * 40 + 17 + 5
	}

	rts

fade_roll3:
	ldx fade_index
	.for (var i = 0; i < 6; i++) {
		lda fade_tbl + i, x
		sta colram + (i + 18) * 40 + 17
		sta colram + (i + 18) * 40 + 17 + 1
		sta colram + (i + 18) * 40 + 17 + 2
		sta colram + (i + 18) * 40 + 17 + 3
		sta colram + (i + 18) * 40 + 17 + 4
		sta colram + (i + 18) * 40 + 17 + 5
	}

	rts

scroll:
	lda scroll_xpos
	sec
	sbc scroll_speed
	and #$07
	sta scroll_xpos
	bcc !move+
	jmp !done+
!move:
	ldx #$00
!:
	lda scroll_screen + 1, x
	sta scroll_screen, x
	inx
	cpx #40
	bne !-

!textptr:
	lda scroll_text
	cmp #$ff
	bne !nowrap+
	jsr scroll_reset
!nowrap:
	sta scroll_screen + 39
	// werk text ptr bij
	inc !textptr- + 1
	bne !done+
	inc !textptr- + 2
!done:
	// pas horizontale verplaatsing toe
	lda #$c0
	ora scroll_xpos
	sta $d016
	rts

scroll_reset:
	// herstel ptr
	lda #<scroll_text
	sta !textptr- + 1
	lda #>scroll_text
	sta !textptr- + 2
	lda scroll_text
	rts

	lda #$c0
	sta $d016
	rts

scroll_xpos:
	.byte 0
scroll_speed:
	.byte 2
scroll_text:
	.text "integratie academisch onderzoek gemaakt door methos, flevosap, theezakje, mund en york .... ... ... .. .. . . . .                 "
	.byte $ff

scroll_coltbl:
	.byte 3, 1, 8, 4, 2, 9, 7, 12, 6, 11, 5, 10, 13, 14, 15, 7
	.byte 3, 1, 8, 4, 2, 9, 7, 12, 6, 11, 5, 10, 13, 14, 15, 7

fade_tbl:
	// kruis is 6 rijen, dus minstens 5 ervoor en en 6 erna
	// dan hebben we precies 5 over, maar voor de timing halen we 1 weg.
	.byte 0, 0, 0, 0, 0
	.byte 9, 9, 8, 7
	.byte 1, 1, 1, 1, 1, 1

fade_index:
	.byte 0

fade_wait:
	.byte $03
fade_delay:
	.byte fade_step
fade_times:
	.byte 3

	// NOTE reversed order! this saves us a couple of bytes for indexing
fade_jtlo:
	.byte <fade_roll_uva, <fade_roll3, <fade_roll2
fade_jthi:
	.byte >fade_roll_uva, >fade_roll3, >fade_roll2

//---------------------------------------------------------
	*=music.location "Music"
	.fill music.size, music.getData(i)

// character data
.align $100

.pc = * "PETSCII art"
image:
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	//        0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   32   33   34   35   36   37   38   39
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $E9, $DF, $20, $20, $E9, $DF, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $5F, $A0, $DF, $E9, $A0, $69, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $5F, $A0, $A0, $69, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $E9, $A0, $A0, $DF, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $E9, $A0, $69, $5F, $A0, $DF, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $5F, $69, $20, $20, $5F, $69, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $76, $A0, $74, $20, $20, $20, $20, $20, $20, $67, $A0, $75, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $76, $A0, $74, $E9, $DF, $20, $20, $E9, $DF, $67, $A0, $75, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $76, $A0, $74, $5F, $A0, $DF, $E9, $A0, $69, $67, $A0, $75, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $76, $A0, $74, $20, $5F, $A0, $A0, $69, $20, $67, $A0, $75, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $76, $A0, $75, $20, $E9, $A0, $A0, $DF, $20, $67, $A0, $75, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $76, $A0, $75, $E9, $A0, $69, $5F, $A0, $DF, $76, $A0, $75, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $67, $A0, $75, $5F, $69, $20, $20, $5F, $69, $76, $A0, $61, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $67, $A0, $75, $20, $20, $20, $20, $20, $20, $76, $A0, $61, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $6A, $A0, $FC, $79, $6F, $64, $64, $64, $79, $FE, $A0, $61, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $5F, $A0, $A0, $A0, $A0, $A0, $A0, $EC, $FB, $A0, $EA, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $77, $E2, $EF, $F9, $E2, $78, $20, $67, $A0, $A0, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $E9, $DF, $20, $20, $E9, $DF, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $5F, $A0, $DF, $E9, $A0, $69, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $5F, $A0, $A0, $69, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $E9, $A0, $A0, $DF, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $E9, $A0, $69, $5F, $A0, $DF, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $5F, $69, $20, $20, $5F, $69, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, 'm', 'e', 't', 'h', 'o', 's'

.pc = * "code 2"

fade_roll_uva:
	// ahhhh dirty code!
	lda #$4c
	sta fade_roll

	ldx uva_counter
	beq !+
	dex
	stx uva_counter
	rts

!:
	dec scroll_counter
	bne !+
	lda #$20
	sta scroll_vector
!:

	ldx fade_index

	.for (var i = 0; i < 8; i++) {
		lda fade_tbl_uva + i, x
		sta colram + (i + 7) * 40 + 13
		sta colram + (i + 7) * 40 + 13 + 1
		sta colram + (i + 7) * 40 + 13 + 2
		sta colram + (i + 7) * 40 + 23
		sta colram + (i + 7) * 40 + 23 + 1
		sta colram + (i + 7) * 40 + 23 + 2
	}
	.for (var i = 8; i < 11; i++) {
		lda fade_tbl_uva + i, x
		sta colram + (i + 7) * 40 + 13
		sta colram + (i + 7) * 40 + 13 + 1
		sta colram + (i + 7) * 40 + 13 + 2
		sta colram + (i + 7) * 40 + 13 + 3
		sta colram + (i + 7) * 40 + 13 + 4
		sta colram + (i + 7) * 40 + 13 + 5
		sta colram + (i + 7) * 40 + 13 + 6
		sta colram + (i + 7) * 40 + 13 + 7
		sta colram + (i + 7) * 40 + 13 + 8
		sta colram + (i + 7) * 40 + 13 + 9
		sta colram + (i + 7) * 40 + 23
		sta colram + (i + 7) * 40 + 23 + 1
		sta colram + (i + 7) * 40 + 23 + 2
	}

	.if (false) {
		ldx fade_index
		stx screen + 2 * 40 + 2
		ldx #26
		stx screen + 3 * 40 + 2
		ldx #1
		stx colram + 2 * 40 + 2
		stx colram + 3 * 40 + 2
	}

	ldx fade_delay
	bne !wait+
	lda #fade_step / 2
	sta fade_delay
	ldx fade_index
	cpx #15
	beq !+
	inx
	stx fade_index
!wait:
	ldx fade_delay
	dex
	stx fade_delay

	rts
!:
	ldx #0
	stx fade_times
	rts

uva_counter:
	.byte $58

scroll_counter:
	.byte $80

fade_tbl_uva:
	// kruis is 6 rijen, dus minstens 5 ervoor en en 6 erna
	// dan hebben we precies 5 over, maar voor de timing halen we 1 weg.
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 // 10, 10
	.byte 9, 9, 8, 7 // 4, 14
	.byte 1, 1, 1, 1, 1, 1 // 6, 20
	.byte 1, 1, 1, 1, 1, 1 // 6, 26
