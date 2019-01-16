BasicUpstart2(start)

#import "key.asm"
#import "zeropage.inc"
#import "pseudo.lib"

// Driver testing code

// 1. fix keypress analysis $30 + actual value
// 2. 
//
//
//
//

.const screen = $0400
.const colram = $d800

.const table_row_val = $0405
.const table_col_val = $0410

start:
        // Vanilla version:

        jsr copy_screen

        borderColor(BLUE)
        backgroundColor(BLACK)

        // Loop through text and commit to video memory ('screen')
        ldx #0
!:
        lda text, x
        sta screen, x
        inx
        cpx #text_end - text
        bne !-

loop:
        jsr read_key
        // Key is read and value is stored in key_res (global var)
        lda key_res
        // If sign bit is 1 (then no keys are pressed)
        bmi !+

// This runs if the negative flag is set (meaning no key is pressed because sign bit is 1)
!:
        jmp loop

copy_screen:
        ldx #0
!:
        lda subsidies_image + $000, x
        sta screen + $000, x
        lda subsidies_image + $100, x
        sta screen + $100, x
        lda subsidies_image + $200, x
        sta screen + $200, x
        lda subsidies_image + $2e8, x
        sta screen + $2e8, x

        lda subsidies_colors + $000, x
        sta colram + $000, x
        lda subsidies_colors + $100, x
        sta colram + $100, x
        lda subsidies_colors + $200, x
        sta colram + $200, x
        lda subsidies_colors + $2e8, x
        sta colram + $2e8, x
        
        inx
        bne !-
        rts

text:
        .text "row: $     col: $"
text_end:

#import "subsidies.asm"