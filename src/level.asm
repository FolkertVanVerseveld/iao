:BasicUpstart2(start)

#import "macros.inc"
#import "pseudo.lib"

.var vic = $0000
.var screen = vic + $0400
.var colram = $d800

.var irq_line_top = $20
.var irq_line_status = $ef

.var timer_a_ctrl = $dd0e
.var timer_b_ctrl = $dd0f

.var timer_a_val16 = $dd04
.var timer_b_val16 = $dd06

.var nmi_isr = $dd0d

.var color = $02

.var time = $aaaa

start:
    jsr load_level
    jsr setup_interrupt

loop:
    jmp loop


.pc = * "Interrupt setup"

setup_interrupt:
    sei

    lda #GREEN
    sta color

    // Switch out all of the ROMs except I/O
    lda #$35
    sta $1

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

    // Disable timer interrupts
    mov #$7f : $dc0d
    mov #$7f : $dd0d

    // Set timer A value
    mov16 #time : timer_a_val16

    mov #%00010001 : timer_a_ctrl

    // Enable timer A NMI
    lda #%10000001
    sta $dd0d

    lda $dc0d
    lda $dd0d

    asl $d019
    cli

    rts

dummy:
    pha

    inc color

    pla

    lda $dd0d
    sta $dd0d
    rti

irq_bgcolor_top:
    irq

    backgroundColor(GREEN)

    qri #irq_line_status : #irq_bgcolor_status

irq_bgcolor_status:
    irq

    lda color
    sta $d020

    qri #irq_line_top : #irq_bgcolor_top



load_level:
    // Set level colors: border black, background green
    borderColor(BLACK)
    backgroundColor(GREEN)

    jsr copy_image
    rts


    
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

.pc = * "Sprites"
#import "sprites.inc"
