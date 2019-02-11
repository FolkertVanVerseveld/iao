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


// 1 amsterdam
// 2 parijs
// 3 berlijn
// 4 londen
full_impact_table:
        .byte $a8,$04,$07,$0a // water 0
        .byte $2a,$08,$02,$31 // water 1
        .byte $0f,$7c,$00,$0e // water 2
        .byte $23,$18,$02,$07 // water 3
        .byte $83,$31,$12,$5d // elec 0
        .byte $0d,$32,$08,$13 // elec 1
        .byte $0d,$04,$b8,$01 // elec 2
        .byte $10,$44,$09,$02 // elec 3
        .byte $7c,$13,$36,$5d // seis 0
        .byte $3f,$0c,$07,$72 // seis 1
        .byte $12,$0e,$58,$08 // seis 2
        .byte $10,$0c,$4b,$07 // seis 3
        .byte $34,$23,$02,$ea // cyber 0
        .byte $ae,$18,$08,$39 // cyber 1
        .byte $29,$0c,$78,$09 // cyber 2
        .byte $21,$9b,$10,$2d // cyber 3
