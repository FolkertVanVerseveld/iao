/*
Code: methos
Menu top loader code

High memory resident loader that waits for menu stuff to load.
*/

* = $e000

#import "local.inc"
#import "pseudo.lib"

// Use first VIC bank
.var vic = $0000
.var screen = vic + $0400

.var colram = $d800

// --- KRILL's LOADER VARIABLES ---- //
.var resident = $0200
.var loadraw = resident

.var resident_size = $01f5

.var drivecode = $5000
.var install = drivecode + $1390
// --------------------------------- //

.var irq_line_top = $20

start:
	cld

	sei

	// character at $1000-$1FFF, screen at $0400-$07FF
	lda #%00010100
	sta $d018

	lda #<irq_top
	sta $fffe
	lda #>irq_top
	sta $ffff
	// use dummy nmi and cold reset
	lda #<dummy
	sta $fffa
	sta $fffc
	lda #>dummy
	sta $fffb
	sta $fffd
	lda #$1b
	sta $d011
	lda #irq_line_top
	sta $d012
	lda #$81
	sta $d01a
	// init timers
	lda #$7f
	sta $dc0d
	sta $dd0d
	lda $dc0d
	lda $dd0d
	// purge pending interrupts
	asl $d019

	cli

	// put some text on screen

	// TODO move these vars to zeropage
	ldx #0
!:
	lda text, x
	cmp #$ff
	beq !+
	sta screen, x
	lda text_col
	sta colram, x
	inx
	jmp !-
!:

	ldx #<file
	ldy #>file
	sec
	jsr loadraw
	bcs error

	jmp (file_start)

error:
	inc $d020
	jmp error

irq_top:
	irq

	inc $d020

	ldx #$10
	dex
	bne *-1

	lda #$c8
	sta $d016

	dec $d020

	qri

dummy:
	asl $d019
	rti

text_col:
	.byte 1
// TODO random text?
text:
	.encoding "screencode_mixed"
	.text "coole laadtekst hier... neem een bak koffie!"
	.byte $ff

// TODO refactor to file table and use index
file:
	.encoding "petscii_upper"
	.text "MENU.PRG"
	.byte 0

// bug in cpu: indirect jump must be page-aligned, rather than
// aligning to 256 bytes, we can just align to word length
.align $2
file_start:
	.word $80e