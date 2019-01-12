#importonce

.macro borderColor(color) {
    lda #color
    sta $d020
}

.macro backgroundColor(color) {
    lda #color
    sta $d021
}

.macro writeValue(addr) {
    lda #$00
    ldx addr
    jsr $BDCD
}

.macro storeDecVal(p5, p4, p3, p2, p1) {
    lda #p5
    sta dec_val
    lda #p4
    sta dec_val+1
    lda #p3
    sta dec_val+2
    lda #p2
    sta dec_val+3
    lda #p1
    sta dec_val+4
}