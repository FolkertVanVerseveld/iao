#importonce

#import "zeropage.inc"
#import "pseudo.lib"
#import "engine/val_to_dec_str.asm"
#import "engine/scrn_addr.inc"

update_itb:
        jsr recalc_itb
        jsr write_itb
        rts

recalc_itb:
        rts

write_itb:
        ldx #$00

w_itb_loop:

        rts

itb_buf_chr:
        .byte

