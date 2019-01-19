:BasicUpstart2(start)

#import "pseudo.lib"

.var vic = $0000
.var screen = vic + $0400
.var colram = $d800

.var irq_line_top = 50 + 6 * 8 - 5
.var irq_line_middle = 50 + 19 * 8 - 2

.var zp = $02

.var scroll = zp + 0
.var vscroll = zp + 1
.var key = zp + 2

start:
	lda #0
	sta $d020
	sta $d021

	lda #0
	sta scroll
	sta key

	lda #3
	sta vscroll

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

	asl $d019

	qri #irq_line_middle : #irq_middle

irq_middle:
	irq

	lda $dc00
	sta key

	lda key
	and #$02
	bne !+
	dec vscroll
!:

	lda key
	and #$01
	bne !+
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

	inc $d020

	lda scroll
	beq !s+
	bmi !+
	sta screen + 40
	lda #1
	sta vscroll
	jsr scroll_down
	jmp !s+
!:
	sta screen + 40
	lda #7
	sta vscroll
	jsr scroll_up
!s:

	dec $d020

	qri #irq_line_top : #irq_top

dummy:
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

	inc scroll
	beq !+
	jmp scroll_up
!:
	rts

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
	.text "voor het plannen, valideren en verstrek-"
	.text "ken van virtuele infrastructuur die     "
	.text "tijdkritische applicaties moet kunnen   "
	.text "ondersteunen. De DRIP is onderdeel van  "
	.text "het door de EU-gesubsidieerde  SWITCH-  "
	.text "-project wat zich richt op het maken van"
	.text "tijdkritische applicaties in de cloud.  "
	.text "In het onderzoek is het DRIP-systeem ge-"
	.text "bruikt om voor een vroeg waarschuwings- "
	.text "systeem. In het spel zal u moeten inves-"
	.text "teren in een DRIP-systeem om de wereld  "
	.text "te behoeden voor rampzalige rampen.     "
	.text "In het echt kan het DRIP-systeem u  hel-"
	.text "pen met de plaats van hardware-upgrades "
	.text "in het systeem , maar in deze simulatie "
	.text "moet u alles zelf beslissen.            "
	.text "                                        "
	.text "In het spel is onze visie op informati- "
	.text "ca-onderzoek verwerkt. Zo vinden wij dat"
	.text "informatica-onderzoek de maatschappij   "
	.text "moet dienen. Vroeg waarschuwingssystemen"
	.text "zoals beschreven in het voorafgaande    "
	.text "kunnen echte mensenlevens redden.       "
	.text "Ook het proces-versus-resultaat-debat   "
	.text "heeft een voorgekregen in ons spel. Hoe-"
	.text "wel wij de waarde van het proces hoger  "
	.text "schatten dan het resultaat, kun je zelfs"
	.text "als je het spel perfect speelt,         "
	.text "game-over gaan. Ofwel onderzoek volledig"
	.text "beoordelen op het proces is een utopie. "
	.text "Voor een succesvol onderzoek heb je     "
	.text "ook een grote dosis geluk nodig.        "
	.text "                                        "
	.text "Genoeg gepraat! Het is de hoogste tijd  "
	.text "dat u begint aan het redden van de we-  "
	.text "reld."
