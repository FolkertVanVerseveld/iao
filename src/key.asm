#importonce

#import "zeropage.inc"
#import "pseudo.lib"

// IO addresses
.const row_adr = $dc00
.const col_adr = $dc01

// Gloal results
.var col_bin = key_res+3

// Keyboard driver

read_key:
        jsr check_joy
        lda #$00
        sta key_res
        jmp read_row
back_row:
        sty key_row
        tya
        rol; rol; rol
        sta key_res
        jmp read_col
back_col:
        sty key_col
        lda key_res
        clc
        adc key_col
        sta key_res
        rts

no_key:
        lda #%10000000
        sta key_res
        lda #$00
        sta key_row
        sta key_col
        rts

more_keys:
        lda #%01000000
        sta key_res
        lda #$00
        sta key_row
        sta key_col
        rts

read_row:
        ldx #%11111110
        ldy #%00
row_loop:
        cpy #$08
        beq no_key
        txa
        sta row_adr
        lda col_adr
        sta col_bin
        cmp #%11111111
        bne back_row
        txa
        rol
        tax
        iny
        jmp row_loop

read_col:
        ldx #%11111110
        ldy #%00
col_loop:
        cpy #$08
        beq more_keys
        txa
        cmp col_bin
        beq back_col
        txa
        rol
        tax
        iny
        jmp col_loop


check_joy:
        lda $dc00
        and #%00011111
        sta joy2
        rts
