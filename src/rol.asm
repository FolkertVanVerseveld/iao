// Assembler: KickAssembler 4.4
// rollende tekst

/*
rol credits
recycled from old hcc release

code: methos
font: some free web font
*/

BasicUpstart2(start)

#import "pseudo.lib"
#import "io.inc"
#import "loader.inc"
#import "joy.inc"

.var scr_clear_char = ' '
.var scr_clear_color = $00

	* = $0810 "start"

.var vic = $0000

.var scherm = $0400
.var spr_data = vic + $3000

.var font = vic + $2800

.var wis_links = scherm + 4 * 40
.var links = wis_links + 3
.var wis_rechts = scherm + 7 * 40
.var rechts = wis_rechts + 39 - 3

// Update these to your HVSC directory

//.var music = LoadSid("/home/methos/Music/HVSC69/MUSICIANS/0-9/20CC/Paul_Falco/Peanut_Pleasure.sid")
.var music = LoadSid("Peanut_Pleasure.sid")
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
.var irq_line_bottom2 = $130

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

	// TODO wait for space
	// wacht op spatie of joystick vuurknop
!:
	lda $dc00
	cmp #$ef
	bne !-

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
	lda #0
	ldx #0
!:
	sta sid, x
	inx
	cpx #$20
	bne !-

	// TODO
	lda #0
	sta prg_index
	jmp top_loader_start

scroll_oud:
	.byte 0

irq_init:

	sei
	lda #$35
	sta $1

	lda #3
	sta $dd00

	lda #<dummy
	sta $fffa
	sta $fffc
	lda #>dummy
	sta $fffb
	sta $fffd

	lda #<irq_top
	sta $fffe
	lda #>irq_top
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

	rts

dummy:
	asl $d019
	rti

spr_init:
	// setup sprite at $0340 (== 13 * 64)
	lda #(spr_data - vic + 0 * 64) / 64
	sta scherm + $03f8
	sta scherm + $03fa
	sta scherm + $03fc
	lda #(spr_data - vic + 1 * 64) / 64
	sta scherm + $03f9
	sta scherm + $03fb
	sta scherm + $03fd
	// copy sprites
	ldx #0
!l:
	lda m0spr, x
	sta spr_data + 0 * 64, x
	lda m1spr, x
	sta spr_data + 1 * 64, x
	inx
	cpx #64
	bne !l-

	// place sprites off screen,
	// let irqs do proper sprite blitting
	lda #0
	ldx #0
!:
	sta sprx0, x
	sta spry0, x
	inx
	cpx #8
	bne !-

	// show sprites
	lda #%111111
	sta $d015
	lda #BLUE
	sta sprcol0
	sta sprcol1
	sta sprcol4
	sta sprcol5
	lda #WHITE
	sta sprcol2
	sta sprcol3
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
	sta spry0
	sta spry1
	clc
	adc #4
	sta spry2
	sta spry3
	sec
	sbc #10
	sta spry4
	clc
	adc #4
	sta spry5
	lda sinus2, x
	sta sprx0
	clc
	adc #7
	sta sprx2
	adc #10
	sta sprx4
	adc #40 - 10 - 7
	sta sprx1
	adc #7 + 8
	sta sprx3
	adc #10
	sta sprx5
	inc balon_pos
	lda #%111111
	sta $d01d
	lda #0
	sta $d017
	rts

irq_top:
	irq

	lda mem_old
	and #$f0
	ora #%00001010
	sta $d018

	// BEGIN kernel
	jsr scroll_tekst
	jsr balon
	jsr music.play

	qri #irq_line_grond : #irq_grond

mem_old:
	.byte 0

irq_grond:
	irq

	jsr scroll

	lda mem_old
	sta $d018

	qri #irq_line_bottom : #irq_bottom

irq_bottom:
	irq
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

	qri2 #irq_line_bottom2 : #irq_bottom2

irq_bottom2:
	irq

	lda #$03
	sta $d020
	sta $d021

	// EIND kernel
	qri2 #irq_line_top : #irq_top

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

.align $40
m0spr:
	.byte %00000000,%00000000,%00000000
	.byte %00000000,%00000000,%01111100
	.byte %00000000,%00000001,%11111110
	.byte %00000000,%00000011,%11111110
	.byte %00000000,%00000111,%11111111
	.byte %00000000,%11111111,%11111111
	.byte %00000011,%11111111,%11111111
	.byte %00000111,%11111111,%11111111
	.byte %00000111,%11111111,%11111111
	.byte %00011111,%11111111,%11111111
	.byte %00111111,%11111111,%11111111
	.byte %01111111,%11111111,%11111111
	.byte %11111111,%11111111,%11111111
	.byte %11111111,%11111111,%11111111
	.byte %11111111,%11111111,%11111111
	.byte %01111111,%11111111,%11111111
	.byte %00011111,%11111111,%11111111
	.byte %00000001,%11111111,%11111111
	.byte %00000000,%00111111,%11111111
	.byte %00000000,%00000011,%11111111
	.byte %00000000,%00000000,%00000000
.align $40
m1spr:
	.byte %00000000,%00000000,%00000000
	.byte %11100000,%00000000,%00000000
	.byte %11111110,%00000000,%00000000
	.byte %11111111,%00000000,%00000000
	.byte %11111111,%00000000,%00000000
	.byte %11111111,%11100000,%00000000
	.byte %11111111,%11110000,%00000000
	.byte %11111111,%11111000,%00000000
	.byte %11111111,%11111000,%00000000
	.byte %11111111,%11111000,%00000000
	.byte %11111111,%11111000,%00000000
	.byte %11111111,%11111100,%00000000
	.byte %11111111,%11111110,%00000000
	.byte %11111111,%11111110,%00000000
	.byte %11111111,%11111110,%00000000
	.byte %11111111,%11111100,%00000000
	.byte %11111111,%11111100,%00000000
	.byte %11111111,%11111000,%00000000
	.byte %11111111,%00000000,%00000000
	.byte %11110000,%00000000,%00000000
	.byte %00000000,%00000000,%00000000

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
	.text "bedankt voor het spelen"
	.byte 0
	.text "van ons spel drip"
regel2_rechts:
	.byte '!'
	.byte 0
regel3_links:
	.text "dit is gemaakt voor de"
	.byte 0
	.text "universiteit van amsterda"
regel4_rechts:
	.byte 'm'
	.byte 0
regel5_links:
	.text "in ongeveer 5 weken"
	.byte 0
	.text "hebben we dit gemaak"
regel6_rechts:
	.byte 't'
	.byte 0
regel7_links:
	.text "code door methos, flevosap"
	.byte 0
	.text "theezakje en yor"
regel8_rechts:
	.byte 'k'
	.byte 0
regel9_links:
	.text "gfx door methos, flevosap"
	.byte 0
	.text "pepermunt, york en auk"
regel10_rechts:
	.byte 'e'
	.byte 0
regel11_links:
	.text "muziek door 20cc"
	.byte 0
	.text "sprites door methos en pepermun"
regel12_rechts:
	.byte 't'
	.byte 0
regel13_links:
	.text "intro en credits door methos"
	.byte 0
	.text "design door methos en flevosa"
regel14_rechts:
	.byte 'p'
	.byte 0
regel15_links:
	.text "linken en codemagie door methos"
	.byte 0
regel16_rechts:
	.byte 0
regel17_links:
	.text "tekst door methos en auke"
	.byte 0
	.text "testen door het drip tea"
regel18_rechts:
	.byte 'm'
	.byte 0
regel19_links:
	.text "we hopen dat u net zoveel plezier"
	.byte 0
	.text "heeft als wij met het maken ervan"
regel20_rechts:
	.byte '!'
	.byte 0
regel21_links:
	.text "groetjes aan de c64 demoscene"
	.byte 0
	.text "en onze vrienden op de un"
regel22_rechts:
	.byte 'i'
	.byte 0
regel23_links:
	.text "en dank aan marco en robert voor"
	.byte 0
	.text "het geven van uitstel voor het spe"
regel24_rechts:
	.byte 'l'
	.byte 0
regel25_links:
	.text "zo hebben we het spel"
	.byte 0
	.text "goed kunnen testen en afronden"
regel26_rechts:
	.byte '!'
	.byte 0
regel27_links:
	.text "druk op de vuurknop om terug"
	.byte 0
	.text "te gaan naar het hoofdmen"
regel28_rechts:
	.byte 'u'
	.byte 0

	* = font "font"

	.import binary "aeg_collection_05.64c", 2
