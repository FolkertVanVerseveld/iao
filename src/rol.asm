// Assembler: KickAssembler 4.4
// rollende tekst

BasicUpstart2(start)

.var scr_clear_char = ' '
.var scr_clear_color = $00

	* = $0810 "start"

.var vic = $0000

.var scherm = $0400
.var spr_data = vic + $2400

.var font = vic + $2800

.var wis_links = scherm + 4 * 40
.var links = wis_links + 3
.var wis_rechts = scherm + 7 * 40
.var rechts = wis_rechts + 39 - 3

// Update these to your HVSC directory

.var music = LoadSid("/home/methos/Music/HVSC69/MUSICIANS/0-9/20CC/Paul_Falco/Peanut_Pleasure.sid")
//.var music = LoadSid("/home/methos/Music/C64Music/MUSICIANS/T/Tel_Jeroen/Fun_Fun.sid")
//.var music = LoadSid("/home/methos/Music/C64Music/MUSICIANS/T/Tel_Jeroen/Alternative_Fuel.sid")

.var num1lo = $62
.var num1hi = $63
.var num2lo = $64
.var num2hi = $65
.var reslo = $66
.var reshi = $67
.var delta = $68

.var irq_line_top = $20
.var irq_line_grond = $b0
.var irq_line_bottom = $e2
.var irq_line_bottom2 = $20

.var colram = $d800

.var scroll_screen = scherm + 20 * 40
.var scroll_colram = colram + 20 * 40

start:
	jsr scr_clear
	lda #$08
	ldx #$00
!l:
	sta scroll_colram, x
	dex
	bne !l-

	lda $d016
	sta scroll_oud
	lda #$03
	sta $d020
	sta $d021
	lda $d018
	sta mem_old
	lda #music.startSong - 1
	jsr music.init
	jsr spr_init
	jsr irq_init
	jmp *

scroll_oud:
	.byte 0

irq_init:
	// zet irq done
	sei
	lda #<irq_top
	sta $0314
	lda #>irq_top
	sta $0315
	// zorg dat de irq gebruikt wordt
	asl $d019

	// geen idee wat dit precies doet
	// het zet alle interrupts eerst uit en dan
	// de volgende aan: timer a, timer b, flag pin, serial shift
	lda #$7b
	sta $dc0d

	// zet raster interrupt aan
	lda #$81
	sta $d01a

	// bit-7 van de te schrijven waarde is bit-8 van de interruptregel (hier 0)
	// tekst mode (bit-5 uit)
	// scherm aan (bit-4 aan)
	// 25 rijen (bit-3 aan)
	// y scroll = 3 (bits 0-2)
	lda $d011
	and #%01111111
	sta $d011

	// de onderste 8-bits van de interruptregel.
	// dus: regel $80 (128)
	lda #irq_line_top
	sta $d012
	lda $d011
	and #$7F
	sta $d011

	// vanaf nu kunnen de interrupts gevuurd worden
	cli

	rts

spr_init:
	// setup sprite at $0340 (== 13 * 64)
	lda #(spr_data - vic + 64 * 0) / 64
	sta scherm + $03f8
	// copy sprites
	ldx #0
!l:
	lda m0spr, x
	sta spr_data + 64 * 0, x
	// sprite 4 is identical to sprite 3
	inx
	cpx #64
	bne !l-
	// show sprites
	lda #$01
	sta $d015
	lda #$04
	sta $d027

	lda #$70
	sta $d000
	lda #$80
	sta $d001
	rts

// add 8-bit constant to 16-bit number

add8_16:
	clc
	lda num1lo
	adc #2     // the constant
	sta num1lo
	bcc !ok+
	inc num1hi
!ok:
	rts

balon:
	ldx balon_pos
	lda sinus, x
	sta $d001
	lda sinus2, x
	sta $d000
	inc balon_pos
	rts

irq_top:
	asl $d019

	lda mem_old
	and #$f0
	ora #%00001010
	sta $d018

	// BEGIN kernel
	//inc $d020
	jsr scroll_tekst
	jsr balon
	jsr music.play

	lda #<irq_grond
	sta $0314
	lda #>irq_grond
	sta $0315

	lda #irq_line_grond
	sta $d012

	//dec $d020
	// EIND kernel
	pla
	tay
	pla
	tax
	pla
	rti

mem_old:
	.byte 0

irq_grond:
	asl $d019
	// BEGIN kernel
	//inc $d020

	jsr scroll

	lda mem_old
	sta $d018

	//dec $d020

	lda #<irq_bottom
	sta $0314
	lda #>irq_bottom
	sta $0315

	lda #irq_line_bottom
	sta $d012

	// EIND kernel
	pla
	tay
	pla
	tax
	pla
	rti

irq_bottom:
	asl $d019
	// BEGIN kernel
	nop
	nop
	nop
	nop
	nop
	nop
	lda #$05
	sta $d020
	sta $d021
	lda scroll_oud
	sta $d016

	lda #<irq_bottom2
	sta $0314
	lda #>irq_bottom2
	sta $0315

	lda #irq_line_bottom2
	sta $d012
	lda $d011
	ora #$80
	sta $d011

	// EIND kernel
	pla
	tay
	pla
	tax
	pla
	rti

irq_bottom2:
	asl $d019

	lda #$03
	sta $d020
	sta $d021

	lda #<irq_top
	sta $0314
	lda #>irq_top
	sta $0315

	lda #irq_line_top
	sta $d012
	lda $d011
	and #$7f
	sta $d011

	// EIND kernel
	pla
	tay
	pla
	tax
	pla
	rti

scr_clear:
	lda #scr_clear_char
	ldx #0
	// `wis' alle karakters door alles te vullen met spaties
!l:
	sta $0400, x
	sta $0500, x
	sta $0600, x
	sta $06e8, x
	inx
	bne !l-
	// verander kleur van alle karakters
	lda #scr_clear_color
	ldx #0
!l:
	sta $d800, x
	sta $d900, x
	sta $da00, x
	sta $dae8, x
	inx
	bne !l-
	rts

scroll:
	// verplaats horizontaal
	lda scroll_xpos
	sec
	sbc scroll_speed
	and #$07
	sta scroll_xpos
	bcc !move+
	jmp !klaar+
!move:
	// verplaats alles één naar links
	ldx #$00
!l:
	lda scroll_screen + 1, x
	sta scroll_screen, x
	lda scroll_screen + 40 + 1, x
	sta scroll_screen + 40, x
	inx
	cpx #40
	bne !l-

	// haal eentje op uit de rij
!textptr:
	lda scroll_text
	cmp #$ff
	bne !nowrap+
	jsr scroll_herstel
!nowrap:
	sta scroll_screen + 39
!textptr2:
	lda scroll_text2
	sta scroll_screen + 39 + 40
	// werk text ptr bij
	inc !textptr- + 1
	bne !skip+
	inc !textptr- + 2
!skip:
	inc !textptr2- + 1
	bne !skip+
	inc !textptr2- + 2
!skip:
!klaar:
	// pas horizontale verplaatsing toe
	lda #$c0
	ora scroll_xpos
	sta $d016
	rts

scroll_herstel:
	// herstel ptr
	lda #<scroll_text
	sta !textptr- + 1
	lda #>scroll_text
	sta !textptr- + 2
	lda #<scroll_text2
	sta !textptr2- + 1
	lda #>scroll_text2
	sta !textptr2- + 2
	lda scroll_text
	rts

balon_pos:
	.byte 0

// sprite movement table
sinus:
	.fill $100, round($8c + $6 * sin(toRadians(i * 2 * 360 / $100)))
sinus2:
	.fill $100, round($70 + $12 * sin(toRadians(i * 360 / $100)))

scroll_xpos:
	.byte 0
scroll_speed:
	.byte 2
scroll_text:
	//.text "hey, deze scroller kan alleen van rechts naar links bewegen. "
	//.text "hij gaat door tot 0xff en dan weer rond. "
	//.fill $100, i
	.byte ' ', ' ', ' ', ' ', ' '
	.byte 233, 160, 227, 248, 121, ' '
	.byte ' ', ' ', ' ', ' ', ' ', ' '
	.byte 121, 121
	.byte ' ', ' ', ' '
	.byte 233, 160, 223
	.byte ' ', ' ', ' ', ' ', ' ', ' ', ' '
	.byte 233, 160, 160, 223
	.byte ' ', ' ', ' ', ' ', ' ', ' ', ' '
	.byte 121, ' ', ' ', ' ', ' ', ' ', ' '
	.byte $ff
scroll_text2:
	.byte ' ', ' ', ' ', ' ', 233
	.byte 160, 160, 160, 160, 160, 160
	.byte 223, ' ', ' ', ' ', ' ', 233
	.byte 160, 160
	.byte 160, 223, 233
	.byte 160, 160, 160
	.byte 223, ' ', ' ', ' ', ' ', ' ', 233
	.byte 160, 160, 160, 160
	.byte 160, 160, 160, 227, 227, 227, 160
	.byte 160, 160, 223, ' ', 121, 121, ' '
	.byte $ff

	* = music.location "music"

	.fill music.size, music.getData(i)

	.print "music_init = $" + toHexString(music.init)
	.print "music_play = $" + toHexString(music.play)

.align $100
m0spr:
	.byte %00000000, %01111111, %00000000
	.byte %00000001, %11111111, %11000000
	.byte %00000011, %11111111, %11100000
	.byte %00000011, %11100011, %11100000
	.byte %00000111, %11011100, %11110000
	.byte %00000111, %11011101, %11110000
	.byte %00000111, %11011100, %11110000
	.byte %00000011, %11100011, %11100000
	.byte %00000011, %11111111, %11100000
	.byte %00000011, %11111111, %11100000
	.byte %00000010, %11111111, %10100000
	.byte %00000001, %01111111, %01000000
	.byte %00000001, %00111110, %01000000
	.byte %00000000, %10011100, %10000000
	.byte %00000000, %10011100, %10000000
	.byte %00000000, %01001001, %00000000
	.byte %00000000, %01001001, %00000000
	.byte %00000000, %00111110, %00000000
	.byte %00000000, %00111110, %00000000
	.byte %00000000, %00111110, %00000000
	.byte %00000000, %00011100, %00000000
	.byte 0

regel24_links:
	.text "demo uit te brenge"
regel24_rechts:
	.byte 'n'
	.byte 0

regel25_links:
	.text "we zijn voornamelijk dinge"
regel25_rechts:
	.byte 'n'
	.byte 0
regel26_links:
	.text "aan het proberen en uitdenke"
regel26_rechts:
	.byte 'n'
	.byte 0
regel27_links:
	.text "maar we zien nog we"
regel27_rechts:
	.byte 'l'
	.byte 0
regel28_links:
	.text "of het allemaal gaat lukken"
regel28_rechts:
	.byte '!'
	.byte 0

.var stappen = 120

scroll_tekst:
	lda #$00
	bne !a+
	jmp scroll_links
!a:
	jmp scroll_rechts

scroll_links:
rol_ptr_links:
	lda regel1_links
	beq !done+
text_ptr_links:
	sta links
	// verplaats rol_ptr
	inc rol_ptr_links + 1
	bne !skip+
	inc rol_ptr_links + 2
!skip:
	// verplaats text_ptr
	inc text_ptr_links + 1
	bne !skip+
	inc text_ptr_links + 2
!skip:
	rts
	// reset rechts logic
!done:
	inc scroll_tekst + 1
tabel_ptr_rechts_lo:
	lda regel_tabel_rechts
	sta rol_ptr_rechts + 1
tabel_ptr_rechts_hi:
	lda regel_tabel_rechts + 1
	sta rol_ptr_rechts + 2
	lda #<rechts
	sta text_ptr_rechts + 1
	lda #>rechts
	sta text_ptr_rechts + 2
	// verplaats tabel ptr
	lda tabel_ptr_rechts_lo + 1
	sta num1lo
	lda tabel_ptr_rechts_lo + 2
	sta num1hi
	jsr add8_16
	lda num1lo
	sta tabel_ptr_rechts_lo + 1
	lda num1hi
	sta tabel_ptr_rechts_lo + 2
	lda tabel_ptr_rechts_hi + 1
	sta num1lo
	lda tabel_ptr_rechts_hi + 2
	sta num1hi
	jsr add8_16
	lda num1lo
	sta tabel_ptr_rechts_hi + 1
	lda num1hi
	sta tabel_ptr_rechts_hi + 2
	// reset als eind
	lda tabel_ptr_rechts_lo + 1
	cmp #<regel_tabel_rechts_eind
	bne !skip+
	lda tabel_ptr_rechts_lo + 2
	cmp #>regel_tabel_rechts_eind
	bne !skip+
	// reset ptr
	lda #<regel_tabel_rechts
	sta tabel_ptr_rechts_lo + 1
	lda #>regel_tabel_rechts
	sta tabel_ptr_rechts_lo + 2
	lda #<regel_tabel_rechts + 1
	sta tabel_ptr_rechts_hi + 1
	lda #>regel_tabel_rechts + 1
	sta tabel_ptr_rechts_hi + 2
!skip:
	rts

scroll_rechts:
rol_ptr_rechts:
	lda regel2_rechts
	beq !done+
text_ptr_rechts:
	sta rechts
	// verplaats rol_ptr
	dec rol_ptr_rechts + 1
	lda rol_ptr_rechts + 1
	cmp #$ff
	bne !skip+
	dec rol_ptr_rechts + 2
!skip:
	// verplaats text_ptr
	dec text_ptr_rechts + 1
	lda text_ptr_rechts + 1
	cmp #$ff
	bne !skip+
	dec text_ptr_rechts + 2
!skip:
	rts
	// reset links logic
!done:
	// maak vertraging...
teller:
	lda #stappen
	beq !skip+
	dec teller + 1
	rts
!skip:
	lda #stappen
	sta teller + 1

	// ik wil het eigenlijk anders doen,
	// maar wis beide regels
	lda #' '
	ldx #0
!l:
	sta wis_links, x
	sta wis_rechts, x
	inx
	cpx #40
	bne !l-
	//inc $d020
	dec scroll_tekst + 1
tabel_ptr_links_lo:
	lda regel_tabel_links
	sta rol_ptr_links + 1
tabel_ptr_links_hi:
	lda regel_tabel_links + 1
	sta rol_ptr_links + 2
	lda #<links
	sta text_ptr_links + 1
	lda #>links
	sta text_ptr_links + 2
	// verplaats tabel ptr
	lda tabel_ptr_links_lo + 1
	sta num1lo
	lda tabel_ptr_links_lo + 2
	sta num1hi
	jsr add8_16
	lda num1lo
	sta tabel_ptr_links_lo + 1
	lda num1hi
	sta tabel_ptr_links_lo + 2
	lda tabel_ptr_links_hi + 1
	sta num1lo
	lda tabel_ptr_links_hi + 2
	sta num1hi
	jsr add8_16
	lda num1lo
	sta tabel_ptr_links_hi + 1
	lda num1hi
	sta tabel_ptr_links_hi + 2
	// reset als eind
	lda tabel_ptr_links_lo + 1
	cmp #<regel_tabel_links_eind
	bne !skip+
	lda tabel_ptr_links_lo + 2
	cmp #>regel_tabel_links_eind
	bne !skip+
	// reset ptr
	lda #<regel_tabel_links
	sta tabel_ptr_links_lo + 1
	lda #>regel_tabel_links
	sta tabel_ptr_links_lo + 2
	lda #<regel_tabel_links + 1
	sta tabel_ptr_links_hi + 1
	lda #>regel_tabel_links + 1
	sta tabel_ptr_links_hi + 2
!skip:
	rts

regel_tabel_links:
	.word regel3_links, regel5_links, regel7_links, regel9_links, regel11_links, regel13_links, regel15_links, regel17_links
	.word regel19_links, regel21_links, regel23_links, regel25_links, regel27_links, regel1_links
regel_tabel_links_eind:

regel_tabel_rechts:
	.word regel2_rechts, regel4_rechts, regel6_rechts, regel8_rechts, regel10_rechts, regel12_rechts, regel14_rechts, regel16_rechts
	.word regel18_rechts, regel20_rechts, regel22_rechts, regel24_rechts, regel26_rechts, regel28_rechts
regel_tabel_rechts_eind:

	.byte 0
regel1_links:
	.text "yo, daar zijn we weer"
regel1_rechts:
	.byte 0
regel2_links:
	.text "gezellig bij de hcc"
regel2_rechts:
	.byte '!'
	.byte 0
regel3_links:
	.text "laten we eens iets moois maken"
regel3_rechts:
	.byte '!'
	.byte 0
regel4_links:
	.text "dit is een klein probeelse"
regel4_rechts:
	.byte 'l'
	.byte 0
regel5_links:
	.text "dit was een paar uurtjes wer"
regel5_rechts:
	.byte 'k'
	.byte 0
regel6_links:
	.text "geinig toch"
regel6_rechts:
	.byte '?'
	.byte 0
regel7_links:
	.text "code door metho"
regel7_rechts:
	.byte 's'
	.byte 0
regel8_links:
	.text "muziek door wav"
regel8_rechts:
	.byte 'e'
	.byte 0
regel9_links:
	.text "vriendelijke groeten aa"
regel9_rechts:
	.byte 'n'
	.byte 0
regel10_links:
	.text "jan, wolf, fred, dunca"
regel10_rechts:
	.byte 'n'
	.byte 0
regel11_links:
	.text "shape, abyss connection, censo"
regel11_rechts:
	.byte 'r'
	.byte 0
regel12_links:
	.text "f4cg, fairlight, genesis p, monocero"
regel12_rechts:
	.byte 's'
	.byte 0
regel13_links:
	.text "bij revision 2018 had i"
regel13_rechts:
	.byte 'k'
	.byte 0
regel14_links:
	.text "mijn eerste demo uitgebrach"
regel14_rechts:
	.byte 't'
	.byte 0
regel15_links:
	.text "en sinds kort ben ik li"
regel15_rechts:
	.byte 'd'
	.byte 0
regel16_links:
	.text "van de demogroep f4cg"
regel16_rechts:
	.byte '!'
	.byte 0
regel17_links:
	.text "ze smasher had me gevraag"
regel17_rechts:
	.byte 'd'
	.byte 0
regel18_links:
	.text "en dat vond ik heel gaaf"
regel18_rechts:
	.byte '!'
	.byte 0
regel19_links:
	.text "daarnaast ben ik met anto"
regel19_rechts:
	.byte 'n'
	.byte 0
regel20_links:
	.text "een scener die een winterslaap ha"
regel20_rechts:
	.byte 'd'
	.byte 0
regel21_links:
	.text "begonnen om een groe"
regel21_rechts:
	.byte 'p'
	.byte 0
regel22_links:
	.text "op te richte"
regel22_rechts:
	.byte 'n'
	.byte 0
regel23_links:
	.text "we hopen op x2018 een cool"
regel23_rechts:
	.byte 'e'
	.byte 0

	* = font "font"

	.import binary "aeg_collection_05.64c", 2
