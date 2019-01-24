#importonce

#import "zeropage.inc"
#import "pseudo.lib"


.pc = * "Copy impact"

copy_impact:
        lda lfsr4_state

        asl
        asl

        tax

        .for (var i = 0; i < 4; i++) {
            lda full_impact_table+i,x
            sta impact_table+i
        }

        rts

.pc = * "Subtract impact"
subtract_impact:
        lda lfsr4_state

        lsr
        lsr

        tax

        .for (var i = 0; i < 4; i++) {
            lda itb+(5*i),x
            sec
            sbc impact_table+i
            bcc !overflowed+
            sta itb+(5*i),x // if we haven't overflowed, just store the buffer again
            jmp !done+
!overflowed:                        
            eor #$ff
            adc #1
            // a has amount with which the buffer was overflowed
            tay // a->y
            lda itb+(5*i)+4 // gezondheid -> a
            sty itb+(5*i)+4 // y -> gezondheid
            sec
            sbc itb+(5*i)+4 // 
            bcc !game_over+
            sta itb+(5*i)+4
            lda #0
            sta itb+(5*i),x
!done:
        }
        rts
!game_over:
        // wat doen we als we game over zijn
        jsr game_over
        rts


full_impact_table:
        .byte $0a,$15,$07,$11
        .byte $10,$1d,$08,$24
        .byte $f0,$0f,$10,$14
        .byte $09,$12,$09,$09
        .byte $23,$13,$0b,$3d
        .byte $0d,$32,$08,$13
        .byte $07,$0d,$06,$08
        .byte $10,$24,$0d,$0e
        .byte $09,$13,$06,$0d
        .byte $0f,$0c,$07,$20
        .byte $08,$0e,$08,$08
        .byte $07,$0c,$07,$07
        .byte $14,$13,$09,$b4
        .byte $0e,$28,$08,$19
        .byte $09,$18,$07,$0b
        .byte $15,$2b,$0d,$11
