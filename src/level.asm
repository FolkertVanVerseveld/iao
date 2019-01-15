:BasicUpstart2(start)

#import "zeropage.inc"
#import "scrn_crd.inc"
#import "pseudo.lib"
#import "val_to_dec_str.asm"

.var irq_line_top = $20
.var irq_line_status = $ef

.var timer_a_ctrl = $dd0e
.var timer_b_ctrl = $dd0f

.var timer_a_val16 = $dd04
.var timer_b_val16 = $dd06

.var nmi_isr = $dd0d

.var color = $02

.var time = $ffff

start:
        jsr load_level
        jsr setup_interrupt
        mov #$30 : $c0
        mov #$39 : $c1

loop:
        jmp loop
    
update_level:
        // Hierin wordt het geld, de hartjes, etc. geüpdatet
        jsr update_money
        rts

update_money:
        mov16 $c0 : c_h_hi
        jsr itoa
        mov dec_char : scr_money
        mov dec_char+1 : scr_money+1
        mov dec_char+2 : scr_money+2
        mov dec_char+3 : scr_money+3
        mov dec_char+4 : scr_money+4
        rts

.pc = * "Interrupt setup"

setup_interrupt:
        sei
    
        lda #BLACK
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
        
        lda $dc0d
        lda $dd0d
        
        asl $d019
        cli
        
        rts

dummy:
        rti

irq_bgcolor_top:
        irq
        
        backgroundColor(GREEN)
        jsr update_level
        
        inc $c1
        
        qri #irq_line_status : #irq_bgcolor_status

irq_bgcolor_status:
        irq
        
        backgroundColor(BLACK)
        
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
