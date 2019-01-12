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