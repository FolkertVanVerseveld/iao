BasicUpstart2(start)

// IO addresses
.var row_adr = $dc00
.var col_adr = $dc01

// Gloal results
.var res = $d0
.var res_row = res+1
.var res_col = res+2
.var col_bin = res+3

// Driver testing code

start:
loop:
        jsr read_key
        lda res_row
        sta $d020
        lda res_col
        sta $d021
        jmp loop


// Keyboard driver

read_key:
        lda #$00
        sta res
        jmp read_row
back_row:
        sty res_row
        tya 
        rol; rol; rol
        sta res
        jmp read_col
back_col:
        sty res_col
        lda res
        adc res_col
        sta res
        rts

no_key:
        lda #%10000000
        sta res
        lda #$00
        sta res_row
        sta res_col
        rts

more_keys:
        lda #%01000000
        sta res
        lda #$00
        sta res_row
        sta res_col
        rts

read_row:
        ldx #%11111110
        ldy #%00
row_loop:
        cpy #$07
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
        cpy #$07
        beq more_keys
        txa
        cmp col_bin
        beq back_col
        txa
        rol
        tax
        iny
        jmp col_loop
