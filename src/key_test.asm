BasicUpstart2(start)

#import "key.asm"

// Driver testing code

start:
loop:
        jsr read_key
        lda res_row
        sta $d020
        sta $0400
        lda res_col
        sta $d021
        sta $0401
        jmp loop