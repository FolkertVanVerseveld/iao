BasicUpstart2(start)
#importonce

#import "macros.inc"
#import "zeropage.inc"
#import "pseudo.lib"

// TEST
start:
        mov #35 : $01 // switch out KERNAL and BASIC ROM
        mov $0111 : c_h_lo
        mov $0110 : c_h_hi
        jsr con_bit
        jsr unpack_bcd
        jsr val_to_char
        mov dec_char : $0400
        mov dec_char+1 : $0401
        mov dec_char+2 : $0402
        mov dec_char+3 : $0403
        mov dec_char+4 : $0404
        jmp start

// 16 bit to decimal converter
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
        lda dec_val
        clc
        adc dec_table+2,X
        sta dec_val
        lda dec_val+1
        adc dec_table+1,X
        sta dec_val+1
        lda dec_val+2
        adc dec_table,X
        sta dec_val+2
htd1:  
        dex
        dex
        dex
        bpl con_loop
        cld
        rts
        
        
unpack_bcd:
        ldx #$03
        ldy #$04
unpack_loop:
        lda dec_val - 1, x
        pha
        and #$0f
        sta dec_val - 1, y
        dey
        pla
        and #$f0
        lsr; lsr; lsr; lsr
        sta dec_val - 1, y
        dex
        dey
        bne unpack_loop
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