:BasicUpstart2(start)

/*
tutorial stuff
code: methos
*/

#import "pseudo.lib"
#import "zeropage.inc"
#import "loader.inc"
#import "joy.inc"
#import "io.inc"
#import "kernal.inc"

.var vic = $0000
.var screen = vic + $0400

.var irq_line_top = 50 + 6 * 8 - 5
.var irq_line_middle = 50 + 19 * 8 - 2

.var zp = $16

.var scroll = zp + 0
.var vscroll = zp + 1
.var key = zp + 2
.var index = zp + 3

.var music = LoadSid("assets/Airwolf_Mix.sid")

start:
	jsr init

	lda #3
	sta $dd00

	lda #0
	sta $d020
	sta $d021
	sta $d015

	lda #music.startSong - 1
	jsr music.init

	lda #0
	sta scroll
	sta key

	lda #3
	sta vscroll

	lda #%00010110
	sta $d018

	ldx #0
!:
	lda #' '
	sta $0400, x
	sta $0500, x
	sta $0600, x
	sta $06e8, x
	lda #5
	sta colram + $000, x
	sta colram + $100, x
	sta colram + $200, x
	sta colram + $2e8, x
	inx
	bne !-

.if (false) {
.for (var i=0;i<25;i++) {
	lda #i
	sta screen + i * 40
}
}

	ldx #0
!:
	lda #WHITE
	sta colram + 2 * 40 + 3, x
	lda text_top, x
	sta screen + 2 * 40 + 3, x
	inx
	cpx #(text_top_end - text_top)
	bne !-

	lda #$ff - 12
	sta scroll
	jsr scroll_up

	sei
	lda #$35
	sta $01

	lda #<irq_top
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

	asl $d019

	cli
	jmp *

irq_top:
	irq

	//inc $d020

	ldx #5
	dex
	bne *-1

	lda vscroll
	and #$07
	ora #$10
	sta $d011

	//dec $d020

	jsr music.play
	jsr read_keyboard

	// TODO add keyboard handling

	qri #irq_line_middle : #irq_middle

irq_middle:
	irq

.if (false) {
	lda #WHITE
	sta colram + 2 * 40 + 2
	lda index
	sta screen + 2 * 40 + 2
}

	lda $dc00
	and #%11111
	sta key

	lda key
	and #%10
	bne !+
	// TODO limit scroll
	ldx index
	cpx #(text_end - text) / 40
	beq !+
	dec vscroll
!:

	lda key
	and #%1
	bne !+
	// limit scroll
	ldx index
	//cpx #$9e
	cpx #$0d
	beq !+
	inc vscroll
!:

	lda vscroll
	and #$07
	bne !s+
	lda key
	and #$02
	bne !+
	dec scroll
	jmp !s+
!:
	inc scroll
!s:

	lda #$10
	sta $d011

	//inc $d020

	lda scroll
	beq !s+
	bmi !+
	//sta screen + 40
	lda #1
	sta vscroll
	jsr scroll_down
	jmp !s+
!:
	//sta screen + 40
	lda #7
	sta vscroll
	jsr scroll_up
!s:

	//dec $d020

	qri #irq_line_top : #irq_top

dummy:
	asl $d019
	rti

scroll_down:
	ldx #0
!:
	.for (var yy = 14 - 3; yy >= 0; yy--) {
		lda screen + (6 + yy) * 40, x
		sta screen + (6 + 1 + yy) * 40, x
	}
	inx
	cpx #40
	bne !-

	ldx #0
!:
fetch_down:
	lda text - 14 * 40, x
	sta screen + 6 * 40, x
	inx
	cpx #40
	bne !-

	lda fetch_down + 1
	sec
	sbc #40
	sta fetch_down + 1
	bcs !+
	dec fetch_down + 2
!:

	// FIXME
	lda fetch_up + 1
	sec
	sbc #40
	sta fetch_up + 1
	bcs !+
	dec fetch_up + 2
!:

	dec index
	dec scroll
	beq !+
	jmp scroll_down
!:
	rts

scroll_up:

	ldx #0
!:
	.for (var yy = 0; yy < 14; yy++) {
		lda screen + (6 + 1 + yy) * 40, x
		sta screen + (6 + yy) * 40, x
	}
	inx
	cpx #40
	bne !-

	ldx #0
!:
fetch_up:
	lda text, x
	sta screen + $200 + 6 * 40 - 40 + 8, x
	inx
	cpx #40
	bne !-

	lda fetch_up + 1
	clc
	adc #40
	sta fetch_up + 1
	bcc !+
	inc fetch_up + 2
!:

	// FIXME
	lda fetch_down + 1
	clc
	adc #40
	sta fetch_down + 1
	bcc !+
	inc fetch_down + 2
!:

	inc index
	inc scroll
	beq !+
	jmp scroll_up
!:
	rts

read_keyboard:
	// save CIA1 state
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
	cmp #$20
	beq goto_menu
!no_alpha:
	ldy key_y
	cpy #%10000000
	beq goto_menu
!:
	// restore CIA1 state
	lda #0
	sta $dc02
	lda key_ddr1
	sta $dc03
	// read joy2 state
	lda $dc00
	and #%11111
	// handle joystick
	cmp #joy_fire
	beq goto_menu
	rts

init:
	// clear zero page area [2, $e0]
	ldx #2
	lda #0
!:
	sta 0, x
	inx
	cpx #$e0
	bne !-
	// check if top loader is present
	ldx #0
	lda top_loader_start
	cmp #<top_magic
	bne !+
	lda top_loader_start + 1
	cmp #>top_magic
	bne !+
	ldx #1
!:
	stx has_top_loader
	rts

goto_menu:
	// kill irq
	sei

	lda #$1b
	sta $d011
	lda #$c8
	sta $d016

	lda #<dummy
	sta $fffa
	sta $fffc
	sta $fffe
	lda #>dummy
	sta $fffb
	sta $fffd
	sta $ffff

	cli

	// kill sid
	lda #0
	ldx #0
!:
	sta sid, x
	inx
	cpx #$20
	bne !-

	lda has_top_loader
	bne !+
	// reset c64
	sei
	lda #$37
	sta $1
	cli
	jmp reset
!:
	// go to main menu
	lda #0
	sta prg_index
	jmp top_loader_start

#import "kbd.asm"

* = music.location "tune"
	.fill music.size, music.getData(i)

.pc = * "scrolltext"

text:
	.text "Gebruik joy2 om te scrollen! Voor de    "
	.text "bediening van het spel moet je de joy-  "
	.text "tick en het toetsenbord gebruiken. Dit  "
	.text "wordt allemaal duidelijk gedurende het  "
	.text "spel. Nu volgt een korte uitleg over het"
	.text "onderzoek dat in dit spel is verwerkt.  "
	.text "                                        "
	.text "De naam van het onderzoek is Dynamic    "
	.text "Real-Time Infrastructure Planning and   "
	.text "Deployment(DRIP) for early warning      "
	.text "systems. Het onderzoek gaat over een    "
	.text "systeem, ook wel DRIP genoemd, voor het "
	.text "plannen, valideren en verstrekken van   "
	.text "een virtuele infrastructuur in de cloud "
	.text "wat meerdere tijdkritische applicaties  "
	.text "ondersteunt. De DRIP is onderdeel van   "
	.text "het door de EU-gesubsidieerde  SWITCH-  "
	.text "-project wat zich richt op het maken van"
	.text "tijdkritische applicaties in de cloud.  "
	.text "In het onderzoek is het DRIP-systeem ge-"
	.text "bruikt voor een vroeg waarschuwings-    "
	.text "systeem. In het spel zal u moeten inves-"
	.text "teren in een DRIP-systeem om de wereld  "
	.text "te behoeden voor rampzalige rampen.     "
	.text "In het echt kan het DRIP-systeem u hel- "
	.text "pen met de plaats van hardware-upgrades "
	.text "in het systeem, maar in deze simulatie  "
	.text "moet u alles zelf beslissen.            "
	.text "                                        "
	.text "In het spel is onze visie op informati- "
	.text "ca-onderzoek verwerkt. Zo vinden wij dat"
	.text "informatica-onderzoek de maatschappij   "
	.text "moet dienen. Vroeg waarschuwingssystemen"
	.text "zoals beschreven in het voorafgaande    "
	.text "kunnen echte mensenlevens redden.       "
	.text "Ook het proces-versus-resultaat-debat   "
	.text "heeft een beeld gekregen in ons spel.   "
	.text "Hoewel wij de waarde van het proces in  "
	.text "een ideale wereld gelijk stellen        "
	.text "aan het resultaat, kun je zelfs als je  "
	.text "het spel perfect speelt, game-over gaan."
	.text "Ofwel onderzoek niet beoordelen op het  "
	.text "resultaat, maar op het proces is een    "
	.text "utopie. Voor een succesvol onderzoek heb"
	.text "je naast een goeie methode ook een gro- "
	.text "te dosis geluk nodig.                   "
	.text "                                        "
	.text "Genoeg gepraat! Het is de hoogste tijd  "
	.text "dat u begint aan het redden van de we-  "
	.text "reld.                                   "
	.text "                                        "
	.text "     Druk op spatie of de vuurknop      "
text_end:

text_top:
	.text "DRIP spelinstructies"
text_top_end:
