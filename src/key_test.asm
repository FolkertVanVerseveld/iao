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
.const table_char_val = $041C

start:
        // Vanilla version:
        // Copy sub_table for testing
        jsr copy_screen
        borderColor(BLACK)
        backgroundColor(BLACK)

        // Loop through text and commit to video memory ('screen')
        ldx #0
!:
        lda text, x
        sta screen, x
        inx
        // Until reached end of text
        cpx #text_end - text
        bne !-
        // lda #'c'
        // sta $0440
        // lda #'h'
        // sta $0441
        // lda #'a'
        // sta $0442
        // lda #'r'
        // sta $0443
        // lda #':'
        // sta $0444
        // lda #' '
        // sta $0445
        // lda #'$'
        // sta $0446

loop:
        // Key is read and value is stored in key_res (global var)
        jsr read_key
        lda key_res
        // 1*** **** (no keys are pressed)
        bmi loop
        tax
        // *1** **** (multiple keys)
        and #%01000000
        cmp #%01000000
        beq loop
        txa
        // Now ignore bits 6 and 7
        and #%00111111
        // Store original in x
        tax
        // Store last 3 bits in y for col comparison
        and #%00000111
        tay
        // Original back in A
        txa

////////// QUICK TEST REMOVE AFTER /////////////
//         and #%00000111
//         cmp #%00000111
//         beq !+
//         jmp loop
// !:
//         lda #'?'
//         sta table_char_val
//         nop
//         nop
//         nop
//         nop
//         nop
//         nop
//         nop
//         nop
//         nop
//         nop
//         nop
//         nop
//         nop
//         nop
//         nop
//         lda #' '
//         sta table_char_val
//         txa
////////// END QUICK TEST ////////////////
determine_row:
        // Only compare row
        and #%00111000
        cmp #%00000000
        // jmps?
        beq !row0_jmp+ // r0  (all 0's)
        cmp #%00001000 // r1
        beq !row1_jmp+
        cmp #%00010000 // r2
        beq !row2_jmp+
        cmp #%00011000 // r3
        beq !row3_jmp+
        cmp #%00100000 // r4
        beq !row4_jmp+
        cmp #%00101000 // r5
        beq !row5_jmp+
        cmp #%00110000 // r6
        beq !row6_jmp+
        cmp #%00111000 // r7
        beq !row7_jmp+
        // Something went wrong if we get here
        jmp loop

!row0_jmp:
        jmp !row0+
!row1_jmp:
        jmp !row1+
!row2_jmp:
        jmp !row2+
!row3_jmp:
        jmp !row3+
!row4_jmp:
        jmp !row4+
!row5_jmp:
        jmp !row5+
!row6_jmp:
        jmp !row6+
!row7_jmp:
        jmp !row7+
!row0:
        tya
        cmp #$00 // c0 (all 0's)
        beq !c0+
        // sta table_char_val
        cmp #%00000001 // c1
        beq !c1+
        cmp #%00000010 // c2
        beq !c2+
        cmp #%00000011 // c3
        beq !c3+
        cmp #%00000100 // c4
        beq !c4+
        cmp #%00000101 // c5
        beq !c5+
        cmp #%00000110 // c6
        beq !c6+
        cmp #%00000111 // c7
        beq !c7+
        // Something went wrong if we get here
        jmp loop
!c0:
        // 'DELETE' input
        // lda #$14
!c0:
        jmp loop
!c1:
        // 'RETURN' input
        // lda #$0D
        jmp loop
!c2:
        // 'RIGHT' input
        jmp loop
!c3:
        // 'F7' input
        lda #'f'
        // lda #$88
        sta table_char_val
        lda #'7'
        sta table_char_val + 1
        jmp loop
!c4:
        // 'F1' input
        lda #'f'
        // lda #$85
        sta table_char_val
        lda #'1'
        sta table_char_val + 1
        jmp loop
!c5:
        // 'F3' input
        lda #'f'
        // lda #$86
        sta table_char_val
        lda #'3'
        sta table_char_val + 1
        jmp loop
!c6:
        // 'F5' input
        lda #'f'
        // lda #$87
        sta table_char_val
        lda #'5'
        sta table_char_val + 1
        jmp loop
!c7:
        // 'DOWN' input
        // sta table_char_val
        jmp loop
!row1:
        tya
        cmp #$00 // c0 (all 0's)
        beq !c0+
        // sta table_char_val
        cmp #%00000001 // c1
        beq !c1+
        cmp #%00000010 // c2
        beq !c2+
        cmp #%00000011 // c3
        beq !c3+
        cmp #%00000100 // c4
        beq !c4+
        cmp #%00000101 // c5
        beq !c5+
        cmp #%00000110 // c6
        beq !c6+
        cmp #%00000111 // c7
        beq !c7+
        // Something went wrong if we get here
        jmp loop
!c0:
        lda #'3'
        sta table_char_val
        jmp loop
!c1:
        lda #'w'
        sta table_char_val
        jmp loop
!c2:
        lda #'a'
        sta table_char_val
        jmp loop
!c3:
        lda #'4'
        sta table_char_val
        jmp loop
!c4:
        lda #'z'
        sta table_char_val
        jmp loop
!c5:
        lda #'s'
        sta table_char_val
        jmp loop
!c6:
        lda #'e'
        sta table_char_val
        jmp loop
!c7:
        // Left-Shift input
        // lda #$5f <- left arrow
        // sta table_char_val
        jmp loop
!row2:
        tya
        cmp #$00 // c0 (all 0's)
        beq !c0+
        // 'Right' input
        // lda #$1D // c0  (all 0's)
        // sta table_char_val
        cmp #%00000001 // c1
        beq !c1+
        cmp #%00000010 // c2
        beq !c2+
        cmp #%00000011 // c3
        beq !c3+
        cmp #%00000100 // c4
        beq !c4+
        cmp #%00000101 // c5
        beq !c5+
        cmp #%00000110 // c6
        beq !c6+
        cmp #%00000111 // c7
        beq !c7+
        // Something went wrong if we get here
        jmp loop
!c0:
        lda #'5'
        sta table_char_val
        jmp loop
!c1:
        lda #'r'
        sta table_char_val
        jmp loop
!c2:
        lda #'d'
        sta table_char_val
        jmp loop
!c3:
        lda #'6'
        sta table_char_val
        jmp loop
!c4:
        lda #'c'
        sta table_char_val
        jmp loop
!c5:
        lda #'f'
        sta table_char_val
        jmp loop
!c6:
        lda #'t'
        sta table_char_val
        jmp loop
!c7:
        lda #'x'
        sta table_char_val
        jmp loop
!row3:
        tya
        cmp #$00 // c0 (all 0's)
        beq !c0+
        // 'F7' input
        // lda #$88 // c0  (all 0's)
        // sta table_char_val
        cmp #%00000001 // c1
        beq !c1+
        cmp #%00000010 // c2
        beq !c2+
        cmp #%00000011 // c3
        beq !c3+
        cmp #%00000100 // c4
        beq !c4+
        cmp #%00000101 // c5
        beq !c5+
        cmp #%00000110 // c6
        beq !c6+
        cmp #%00000111 // c7
        beq !c7+
        // Something went wrong if we get here
        jmp loop
!c0:
        lda #'7'
        sta table_char_val
        jmp loop
!c1:
        lda #'y'
        sta table_char_val
        jmp loop
!c2:
        lda #'g'
        sta table_char_val
        jmp loop
!c3:
        lda #'8'
        sta table_char_val
        jmp loop
!c4:
        lda #'b'
        sta table_char_val
        jmp loop
!c5:
        lda #'h'
        sta table_char_val
        jmp loop
!c6:
        // HOME
        lda #'u'
        sta table_char_val
        jmp loop
!c7:
        lda #'v'
        sta table_char_val
        jmp loop
!row4:
        tya
        cmp #$00 // c0 (all 0's)
        beq !c0+
        // 'F1' input
        // lda #$85 // c0  (all 0's)
        // sta table_char_val
        cmp #%00000001 // c1
        beq !c1+
        cmp #%00000010 // c2
        beq !c2+
        cmp #%00000011 // c3
        beq !c3+
        cmp #%00000100 // c4
        beq !c4+
        cmp #%00000101 // c5
        beq !c5+
        cmp #%00000110 // c6
        beq !c6+
        cmp #%00000111 // c7
        beq !c7+
        // Something went wrong if we get here
        jmp loop
!c0:
        lda #'9'
        sta table_char_val
        jmp loop
!c1:
        lda #'i'
        sta table_char_val
        jmp loop
!c2:
        lda #'j'
        sta table_char_val
        jmp loop
!c3:
        lda #'0'
        sta table_char_val
        jmp loop
!c4:
        lda #'m'
        sta table_char_val
        jmp loop
!c5:
        lda #'k'
        sta table_char_val
        jmp loop
!c6:
        lda #'o'
        sta table_char_val
        jmp loop
!c7:
        // space
        lda #'n'
        sta table_char_val
        jmp loop
!row5:
        tya
        cmp #$00 // c0 (all 0's)
        beq !c0+
        // 'F3' input
        // lda #$86 // c0  (all 0's)
        // sta table_char_val
        cmp #%00000001 // c1
        beq !c1+
        cmp #%00000010 // c2
        beq !c2+
        cmp #%00000011 // c3
        beq !c3+
        cmp #%00000100 // c4
        beq !c4+
        cmp #%00000101 // c5
        beq !c5+
        cmp #%00000110 // c6
        beq !c6+
        cmp #%00000111 // c7
        beq !c7+
        // Something went wrong if we get here
        jmp loop
!c0:
        lda #'+'
        sta table_char_val
        jmp loop
!c1:
        lda #'p'
        sta table_char_val
        jmp loop
!c2:
        lda #'l'
        sta table_char_val
        jmp loop
!c3:
        lda #'-'
        sta table_char_val
        jmp loop
!c4:
        lda #'.'
        sta table_char_val
        jmp loop
!c5:
        lda #':'
        sta table_char_val
        jmp loop
!c6:
        lda #'@'
        sta table_char_val
        jmp loop
!c7:
        lda #','
        sta table_char_val
        jmp loop
!row6:
        tya
        cmp #$00 // c0 (all 0's)
        beq !c0+
        // 'F5' input
        // lda #$87 // c0  (all 0's)
        // sta table_char_val
        cmp #%00000001 // c1
        beq !c1+
        cmp #%00000010 // c2
        beq !c2+
        cmp #%00000011 // c3
        beq !c3+
        cmp #%00000100 // c4
        beq !c4+
        cmp #%00000101 // c5
        beq !c5+
        cmp #%00000110 // c6
        beq !c6+
        cmp #%00000111 // c7
        beq !c7+
        // Something went wrong if we get here
        jmp loop
!c0:
        lda #'$'
        sta table_char_val
        jmp loop
!c1:
        lda #'*'
        sta table_char_val
        jmp loop
!c2:
        lda #';'
        sta table_char_val
        jmp loop
!c3:
        // HOME
        // lda #'u'
        // sta table_char_val
        jmp loop
!c4:
        // RIGHT_SHIFT
        // lda #'o'
        // sta table_char_val
        jmp loop
!c5:
        lda #'='
        sta table_char_val
        jmp loop
!c6:
        lda #'^'
        sta table_char_val
        jmp loop
!c7:
        lda #'/'
        sta table_char_val
        jmp loop
!row7:
        tya
        cmp #$00 // c0 (all 0's)
        beq !c0+
        // 'Down' input
        // lda #$11 // c0  (all 0's)
        // sta table_char_val
        cmp #%00000001 // c1
        beq !c1+
        cmp #%00000010 // c2
        beq !c2+
        cmp #%00000011 // c3
        beq !c3+
        cmp #%00000100 // c4
        beq !c4+
        cmp #%00000101 // c5
        beq !c5+
        cmp #%00000110 // c6
        beq !c6+
        cmp #%00000111 // c7
        beq !c7+
        // Something went wrong if we get here
        jmp loop
!c0:
        lda #'1'
        sta table_char_val
        jmp loop
!c1:
        lda #'<'
        sta table_char_val
        jmp loop
!c2:
        // CONTROL
        // lda #'x'
        // sta table_char_val
        jmp loop
!c3:
        lda #'2'
        sta table_char_val
        jmp loop
!c4:
        lda #' '
        sta table_char_val
        jmp loop
!c5:
        // COMMODORE
        // lda #','
        // sta table_char_val
        jmp loop
!c6:
        lda #'q'
        sta table_char_val
        jmp loop
!c7:
        // STOP input
        lda #$03
        sta table_char_val
        jmp loop

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

set_row_selector:
        sta table_row_val
        rts
set_col_selector:
        sta table_col_val
        rts
text:
        .text "row: $     col: $     char: $"
text_end:

#import "subsidies.asm"