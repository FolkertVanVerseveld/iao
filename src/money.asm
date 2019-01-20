#importonce

#import "zeropage.inc"
#import "pseudo.lib"
#import "engine/scrn_addr.inc"
#import "engine/val_to_dec_str.asm"

init_money:
        lda #$00
        sta money
        sta money+1

        sta subsidy+1
        sta expenditure+1
        lda #$10
        sta subsidy
        lda #$03
        sta expenditure

.pc = * "Update Money"

update_money:
        // add subsidy to balance
        clc
        lda money
        adc subsidy
        sta money

        lda money + 1
        adc subsidy + 1

        bcc !save_high+

        // In this case, we've overflowed. Just cap the money to $ffff
        lda #$ff
        sta money

!save_high:
        sta money + 1

        // subtract expenditure from balance
        lda money
        sec
        sbc expenditure
        lda money + 1
        sbc expenditure + 1
        bcs !end+

        // Negative overflow, we've spent more than we have
        lda stat_flg
        ora #%10000000
        sta stat_flg
!end:
        jsr write_money
        rts

//TODO
update_subsidy:
        jsr write_subsidy
        rts

.pc = * "Update Expenditure"

update_expenditure:
        ldx #35                                         // 2
        lda #0                                          // 2
        sta expenditure + 1 // set high byte to 0       // 3
        clc                                             // 2

!loop:
        adc investment_table, x                         // 4
        bcc !cont+                                      // 2/3/4
        clc                                             // 2
        inc expenditure + 1                             // 5

!cont:
        dex                                             // 2
        bne !loop-                                      // 2/3/4
        sta expenditure                                 // 3
        jsr write_expenditure
        rts                                             // 6

        // ~670 cycles


.pc = * "Write money"

write_money:
        mov16 money : c_h_lo
        jsr itoa

        mov_money_str16(screen_main, 1, 24)
        mov_money_str16(screen_subsidies, 1, 24)
        mov_money_str16(screen_log, 1, 24)
        rts

write_subsidy:
        mov16 subsidy : c_h_lo
        jsr itoa

        mov_money_str16(screen_main, 11, 24)
        mov_money_str16(screen_subsidies, 11, 24)
        mov_money_str16(screen_log, 11, 24)
        rts

write_expenditure:
        mov16 expenditure : c_h_lo
        //jsr itoa

        mov_money_str16(screen_main, 23, 24)
        mov_money_str16(screen_subsidies, 23, 24)
        mov_money_str16(screen_log, 23, 24)
        rts
