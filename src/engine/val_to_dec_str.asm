#importonce

#import "../zeropage.inc"
#import "../pseudo.lib"

.pc = * "ITOA"

// 16 bit to decimal converter
itoa:
        jsr con_bit
        jsr unpack_bcd
        //jsr val_to_char
        rts

con_bit:
        sed
        lda #0
        sta dec_val
        sta dec_val+1
        sta dec_val+2
        ldx #$2d
con_loop:
        asl c_h_lo
        rol c_h_hi
        bcc htd1
        lda dec_val+2
        clc
        adc dec_table+2,X
        sta dec_val+2
        lda dec_val+1
        adc dec_table+1,X
        sta dec_val+1
        lda dec_val
        adc dec_table,X
        sta dec_val
htd1:
        dex
        dex
        dex
        bpl con_loop
        cld
        rts

.pc = * "Unpack BCD"

unpack_bcd:
        ldx #$03
        ldy #$04
unpack_loop:
        lda dec_val - 1, x
        pha
        and #$0f
        clc
        adc #$30
        sta dec_char, y
        dey
        pla
        and #$f0
        lsr; lsr; lsr; lsr
        clc
        adc #$30
        sta dec_char, y
        dex
        dey
        bne unpack_loop

        lda dec_val
        clc
        adc #$30
        sta dec_char
        rts


.pc = * "Label"

val_to_char:
        ldx #$05
char_loop:
        dex
        php
        ldy dec_val, x
        lda dec_chars, y
        sta dec_char, x
        plp
        bne char_loop
        rts


dec_table:
    .byte    $0, $0,  $1,  $0, $0,  $2,  $0, $0,  $4,  $0, $0,  $8
    .byte    $0, $0,  $16, $0, $0,  $32, $0, $0,  $64, $0, $1,  $28
    .byte    $0, $2,  $56, $0, $5,  $12, $0, $10, $24, $0, $20, $48
    .byte    $0, $40, $96, $0, $81, $92, $1, $63, $84, $3, $27, $68


dec_chars:
        .text "0123456789"
