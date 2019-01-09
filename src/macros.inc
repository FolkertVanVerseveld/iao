.macro borderColor(color) {
    lda #color
    sta $d020
}

.macro backgroundColor(color) {
    lda #color
    sta $d021
}

