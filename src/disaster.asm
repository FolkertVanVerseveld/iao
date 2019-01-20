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
