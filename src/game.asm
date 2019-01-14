:BasicUpstart2(start)

#import "zeropage.inc"

#import "macros.inc"
#import "pseudo.lib"

.var vic = $0000
.var screen = vic + $0400
.var colram = $d800

.var irq_line_top = $00
.var irq_line_status = $ef

.var irq_line_border = $fa

start:
	jsr load_level
	jsr setup_interrupt

!:
	lda $dc01
	cmp #$ef
	bne !-

	lda #0
	sta prg_index
	jmp top_loader_start

setup_interrupt:
	sei

	// Switch out all of the ROMs except I/O
	lda #$35
	sta $1

	lda #3
	sta $dd00

	lda #0
	sta $d015

	// Load the dummy function for the cold reset
	// and NMI handler
	lda #<dummy
	sta $fffa
	sta $fffc
	lda #>dummy
	sta $fffb
	sta $fffd

	mov16 #irq_bgcolor_top : $fffe

	mov #$1b : $d011
	mov16 #irq_line_top : $d012
	mov #1 : $d01a

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

irq_bgcolor_top:
	irq

	backgroundColor(GREEN)

	qri #irq_line_status : #irq_bgcolor_status

irq_bgcolor_status:
	irq

	lda #$00
	sta $d011

	backgroundColor(BLACK)

	qri #irq_line_border : #irq_open_border

irq_open_border:
	irq

	lda #$1b
	sta $d011

	qri #irq_line_top : #irq_bgcolor_top


load_level:
	// Set level colors: border black, background green
	borderColor(WHITE)
	backgroundColor(GREEN)

	// fall through
copy_image: // Copied from uva.asm
	ldx #0
!l:
	lda level1_image_data + $000, x
	sta screen + $000, x
	lda level1_image_data  + $100, x
	sta screen + $100, x
	lda level1_image_data  + $200, x
	sta screen + $200, x
	lda level1_image_data  + $2e8, x
	sta screen + $2e8, x

	lda level1_color_data + $000, x
	sta colram + $000, x
	lda level1_color_data + $100, x
	sta colram + $100, x
	lda level1_color_data + $200, x
	sta colram + $200, x
	lda level1_color_data + $2e8, x
	sta colram + $2e8, x

	dex
	bne !l-
	rts


.pc = * "PETSCII art"

#import "level1_europe.asm"
