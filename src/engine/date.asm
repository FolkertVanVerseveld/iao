#importonce

#import "../zeropage.inc"
#import "../pseudo.lib"
#import "scrn_addr.inc"
#import "val_to_dec_str.asm"

update_date:
        lda date_month
        cmp #$0c
        beq new_year
        adc #$01
        sta date_month

write_date:
        // write month
        lda #$00
        sta c_h_hi
        lda date_month
        sta c_h_lo
        jsr itoa
        mov dec_char+3 : screen_main+coordToAddr(33, 24)
        mov dec_char+4 : screen_main+coordToAddr(34, 24)

        mov dec_char+3 : screen_subsidies+coordToAddr(33, 24)
        mov dec_char+4 : screen_subsidies+coordToAddr(34, 24)

        mov dec_char+3 : screen_log+coordToAddr(33, 24)
        mov dec_char+4 : screen_log+coordToAddr(34, 24)
        // write year
        lda #$00
        sta c_h_hi
        lda date_year
        sta c_h_lo
        jsr itoa
        mov dec_char+3 : screen_main+coordToAddr(38, 24)
        mov dec_char+4 : screen_main+coordToAddr(39, 24)

        mov dec_char+3 : screen_subsidies+coordToAddr(38, 24)
        mov dec_char+4 : screen_subsidies+coordToAddr(39, 24)

        mov dec_char+3 : screen_log+coordToAddr(38, 24)
        mov dec_char+4 : screen_log+coordToAddr(39, 24)
        rts

new_year:
        lda date_year
        cmp date_last
        //beq last_reached
        adc #$01
        sta date_year
        lda #$01
        sta date_month
        jmp write_date

last_reached:
        lda stat_flg
        ora #%01000000
        sta stat_flg
        rts


