#importonce

#import "pseudo.lib"
#import "zeropage.inc"
#import "engine/val_to_dec_str.asm"
#import "engine/scrn_addr.inc"

init_disaster:
        lda #$00
        sta disaster_num
        ldx #$00
init_disaster_loop:
        sta impact_table, X
        inx
        cpx #$07
        bne init_disaster_loop
        rts

update_disaster:
        lda lfsr4_state
        lsr; lsr
        sta disaster_num
        jsr clear_disaster_text
        jsr write_disaster_txt
        jsr write_disaster_date
        rts

read_disaster:
        rts

write_disaster_txt:
        // write disaster text
        ldy disaster_num
        ldx text_length, Y
write_disaster_txt_loop:
        dex
        txa
        bmi write_disaster_done
        cpy #$00
        beq write_disaster_water
        cpy #$01
        beq write_disaster_elec
        cpy #$02
        beq write_disaster_earth
        jmp write_disaster_cyb
write_disaster_water:
        lda dis_water, X
        sta screen_log+coordToAddr(14, 2), X
        jmp write_disaster_txt_loop
write_disaster_elec:
        lda dis_elec, X
        sta screen_log+coordToAddr(14, 2), X
        jmp write_disaster_txt_loop
write_disaster_earth:
        lda dis_earth, X
        sta screen_log+coordToAddr(14, 2), X
        jmp write_disaster_txt_loop
write_disaster_cyb:
        lda dis_cyb, X
        sta screen_log+coordToAddr(14, 2), X
        jmp write_disaster_txt_loop
write_disaster_done:
        rts

clear_disaster_text:
        lda #$20
        ldx #$10
clear_disaster_text_loop:
        sta screen_log+coordToAddr(14, 2), X
        dex
        bpl clear_disaster_text_loop
        rts

write_disaster_date:
        ldx #$06
write_disaster_date_loop:
        mov screen_log+coordToAddr(33, 24), X : screen_log+coordToAddr(9, 7), X
        dex
        bpl write_disaster_date_loop
        rts

write_disaster_impact:
        lda #$00
        sta c_h_hi

        lda impact_table
        sta c_h_lo
        jsr itoa
        mov dec_chars : screen_log+coordToAddr(11, 13)
        mov dec_chars+1 : screen_log+coordToAddr(11, 13)+1
        mov dec_chars+2 : screen_log+coordToAddr(11, 13)+2

        lda impact_table+1
        sta c_h_lo
        jsr itoa
        mov dec_chars : screen_log+coordToAddr(11, 16)
        mov dec_chars+1 : screen_log+coordToAddr(11, 16)+1
        mov dec_chars+2 : screen_log+coordToAddr(11, 16)+2

        lda impact_table+2
        sta c_h_lo
        jsr itoa
        mov dec_chars : screen_log+coordToAddr(11, 19)
        mov dec_chars+1 : screen_log+coordToAddr(11, 19)+1
        mov dec_chars+2 : screen_log+coordToAddr(11, 19)+2

        lda impact_table+3
        sta c_h_lo
        jsr itoa
        mov dec_chars : screen_log+coordToAddr(11, 21)
        mov dec_chars+1 : screen_log+coordToAddr(11, 21)+1
        mov dec_chars+2 : screen_log+coordToAddr(11, 21)+2
        rts




text_length:
        .byte $0c, $0c, $0a, $0b

dis_water:
        .text "overstroming"

dis_elec:
        .text "stroomuitval"

dis_earth:
        .text "aardbeving"

dis_cyb:
        .text "cyberaanval"
