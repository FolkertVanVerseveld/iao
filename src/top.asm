/*
Code: methos
Menu top loader code

High memory resident loader that waits for menu stuff to load.
*/

// TODO add press space check for some load screens

* = $e000

#import "zeropage.inc"
#import "pseudo.lib"
#import "loader.inc"

// Use first VIC bank
.var vic = $0000
.var screen = vic + $0400

.var colram = $d800

.var irq_line_top = $20

start:
	cld

	// use dummy irqs
	sei
	lda #<dummy
	sta $fffa
	sta $fffc
	sta $fffe
	lda #>dummy
	sta $fffb
	sta $fffd
	sta $ffff
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

	// disable sprites
	lda #0
	sta $d015

	// clear screen
	lda #' '
	ldx #0
!:
	sta screen + $000, x
	sta screen + $100, x
	sta screen + $200, x
	sta screen + $2e8, x
	inx
	bne !-
	lda #WHITE
!:
	sta colram + $000, x
	sta colram + $100, x
	sta colram + $200, x
	sta colram + $2e8, x
	inx
	bne !-

	ldx prg_index
	lda text_tbl_lo, x
	sta fetch + 1
	lda text_tbl_hi, x
	sta fetch + 2

	// put load text on screen
	ldx #0
!:
fetch:
	lda text, x
	cmp #$ff
	beq !+
	sta screen + 7 * 40, x
	lda text_col
	sta colram, x
	inx
	jmp !-
!:

	// setup video hardware

	// character at $1000-$1FFF, screen at $0400-$07FF
	lda #%00010100
	sta $d018

	// use first bank
	lda #%11
	sta $dd00

	lda #$c8
	sta $d016

	lda #BLACK
	sta $d020
	sta $d021

.pc = * "load code"

	ldx prg_index
	lda start_tbl_lo, x
	sta prg_start
	lda start_tbl_hi, x
	sta prg_start + 1

	ldy name_tbl_hi, x
	lda name_tbl_lo, x
	tax

	sec
	jsr loadraw
	bcs error

	jmp (prg_start)

error:
	inc $d020
	jmp error

dummy:
	asl $d019
	rti

text_col:
	.byte 1
// TODO random text?
text:
	.encoding "screencode_mixed"
	//     0123456789012345678901234567890123456789
	.text "laden... een moment geduld alstublieft"
	.byte $ff

text_game:
	.encoding "screencode_mixed"
	//     0123456789012345678901234567890123456789
	.text "  zet u schrap, het spel wordt geladen! "
	.byte $ff

text_gameover:
	.encoding "screencode_mixed"
	//     0123456789012345678901234567890123456789
	.text "oeps! u heeft 1 of meerdere steden niet "
	.text "kunnen beschermen tegen de rampen. merk "
	.text "op dat niet elke investering bij elke   "
	.text "stad even effectief is."
	.byte $ff

// filetable
	.encoding "petscii_upper"
prg_menu:
	.text "MENU.PRG"
	.byte 0

prg_game:
	.text "GAME.PRG"
	.byte 0

name_tbl_lo:
	.byte <prg_menu, <prg_game, <prg_menu
name_tbl_hi:
	.byte >prg_menu, >prg_game, >prg_menu

start_tbl_lo:
	.byte <$80e, <$80e, <$80e
start_tbl_hi:
	.byte >$80e, >$80e, >$80e

text_tbl_lo:
	.byte <text, <text_game, <text_gameover
text_tbl_hi:
	.byte >text, >text_game, >text_gameover
