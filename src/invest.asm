#importonce

#import "zeropage.inc"
#import "pseudo.lib"
#import "engine/val_to_dec_str.asm"
#import "engine/scrn_addr.inc"


init_inv:
        lda #$00
        ldx #$00
init_inv_loop:
        sta investment_table, X
        inx
        cpx #$23
        bne init_inv_loop
        rts

init_itb:
        lda #$00
        ldx #$00
init_itb_loop:
        sta itb, X
        inx
        cpx #$23
        bne init_itb_loop
        rts

update_itb:
        jsr recalc_itb
        jsr write_itb
        rts


recalc_itb:
        ldx #$00
recalc_itb_loop:
        lda itb, X
        add investment_table, X
        bcc recalc_itb_no_overflow
        lda #$ff
recalc_itb_no_overflow:
        sta itb, X
        inx
        cpx #$23
        bne init_itb_loop
        rts


//temp
write_itb:
        mov #$00 : c_h_hi
        ldx #$00
        ldy #$00
write_itb_loop:
        // city 1
        lda itb, X
        sta c_h_lo
        jsr itoa
        mov dec_char+2 : screen_subsidies+coordToAddr(11, 4), X
        mov dec_char+3 : screen_subsidies+coordToAddr(12, 4), X
        mov dec_char+4 : screen_subsidies+coordToAddr(13, 4), X

        // city 2
        lda itb+5, X
        sta c_h_lo
        jsr itoa
        mov dec_char+2 : screen_subsidies+coordToAddr(11, 7), X
        mov dec_char+3 : screen_subsidies+coordToAddr(12, 7), X
        mov dec_char+4 : screen_subsidies+coordToAddr(13, 7), X


        // city 3
        lda itb+10, X
        sta c_h_lo
        jsr itoa
        mov dec_char+2 : screen_subsidies+coordToAddr(11, 10), X
        mov dec_char+3 : screen_subsidies+coordToAddr(12, 10), X
        mov dec_char+4 : screen_subsidies+coordToAddr(13, 10), X


        // city 4
        lda itb+15, X
        sta c_h_lo
        jsr itoa
        mov dec_char+2 : screen_subsidies+coordToAddr(11, 13), X
        mov dec_char+3 : screen_subsidies+coordToAddr(12, 13), X
        mov dec_char+4 : screen_subsidies+coordToAddr(13, 13), X


        iny
        txa
        add #$06
        tax
        cpy #$05
        bne write_itb_loop
        rts

write_investments:
        mov #$00 : c_h_hi
        ldx #$00
        ldy #$00
write_investments_loop:
        // city 1
        lda investment_table, y
        sta c_h_lo
        jsr itoa
        mov dec_char+2 : screen_subsidies+coordToAddr(11, 3), X
        mov dec_char+3 : screen_subsidies+coordToAddr(12, 3), X
        mov dec_char+4 : screen_subsidies+coordToAddr(13, 3), X

        // city 2
        lda investment_table+5, y
        sta c_h_lo
        jsr itoa
        mov dec_char+2 : screen_subsidies+coordToAddr(11, 6), X
        mov dec_char+3 : screen_subsidies+coordToAddr(12, 6), X
        mov dec_char+4 : screen_subsidies+coordToAddr(13, 6), X


        // city 3
        lda investment_table+10, y
        sta c_h_lo
        jsr itoa
        mov dec_char+2 : screen_subsidies+coordToAddr(11, 9), X
        mov dec_char+3 : screen_subsidies+coordToAddr(12, 9), X
        mov dec_char+4 : screen_subsidies+coordToAddr(13, 9), X


        // city 4
        lda investment_table+15, y
        sta c_h_lo
        jsr itoa
        mov dec_char+2 : screen_subsidies+coordToAddr(11, 12), X
        mov dec_char+3 : screen_subsidies+coordToAddr(12, 12), X
        mov dec_char+4 : screen_subsidies+coordToAddr(13, 12), X


        iny
        txa
        add #$06
        tax
        cpy #$05
        bne write_investments_loop
        rts

