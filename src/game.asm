:BasicUpstart2(start)

/*
Core game mechanics
Code: methos, theezakje
*/

#import "zeropage.inc"
#import "loader.inc"
#import "pseudo.lib"
#import "joy.inc"
#import "io.inc"
#import "kernal.inc"

.var vic = 2 * $4000
// pointers to game screens, must be multiple of $0400
.var screen_main      = vic + 0 * $0400
.var screen_subsidies = vic + 1 * $0400
.var screen_log       = vic + 2 * $0400
.var screen_options   = vic + 3 * $0400

.var spr_enable_mask = %11111

// TODO use custom font to redefine dollar character into euro valuta

// use last screen for sprite data
.var sprdata = vic + 15 * $0400

// destination for sprite data
.var spr_star     = sprdata + 0 * 64
.var spr_map      = sprdata + 1 * 64
.var spr_euro     = sprdata + 2 * 64
.var spr_settings = sprdata + 3 * 64
.var spr_arrow    = sprdata + 4 * 64

// open border magic happens in this irq, DO NOT CHANGE
.var irq_middle_line = $ef

.const gameover_delay = $10000 - $300

//.var music_gameover = LoadSid(HVSC + "/MUSICIANS/0-9/20CC/van_Santen_Edwin/13_Seconds_of_Massacre.sid")
.var music_gameover = LoadSid("13_Seconds_of_Massacre.sid")

//.var music_level = LoadSid(HVSC + "/MUSICIANS/0-9/20CC/van_Santen_Edwin/Rettekettet.sid")
.var music_level = LoadSid("Rettekettet.sid")

.var music_begin = min(music_gameover.location, music_level.location)
.var music_size = max(music_gameover.size, music_level.size)
.var music_end = music_begin + music_size + 1

.print "music begin=" + toHexString(music_begin)
.print "music size=" + toHexString(music_size)
.print "music end=" + toHexString(music_end)

start:
	jsr init
	lda #music_level.startSong - 1
	jsr music_level.init
	jsr setup_interrupt
	jsr init_sprites
	jsr copy_screens

game_loop:
	jsr joy_ctl
	jsr check_space
	jmp game_loop

joy_ctl:
	// show joy2 for debug purposes
	lda $dc00
	sta joy2

	// if no buttons are pressed, joy2_dir = 0
	ldx #0

	cmp #joy_right
	bne !+
	ldx #1
!:
	cmp #joy_left
	bne !+
	ldx #2
!:

	stx joy2_dir
	// if a button was pressed in previous state
	lda joy2_dir_old
	beq !+
	// if now no buttons have been pressed
	txa
	bne !+
	// self modify call screen routine
	ldx joy2_dir_old
	dex
	lda vec_scr_lo, x
	sta !do_scr+ + 1
	lda vec_scr_hi, x
	sta !do_scr+ + 2
!do_scr:
	jsr scr_prev
!:
	lda joy2_dir
	sta joy2_dir_old
	rts

scr_next:
	// window = (window + 1) % screen_count
	lda window
	clc
	adc #1
	and #4 - 1
	sta window

	jmp update_screen

scr_prev:
	// window = (window + screen_count - 1) % screen_count
	lda window
	clc
	adc #4 - 1
	and #4 - 1
	sta window

	jmp update_screen

vec_scr_lo:
	.byte <scr_next, <scr_prev
vec_scr_hi:
	.byte >scr_next, >scr_prev

init:
	// clear zero page area [2, $e0]
	ldx #2
	lda #0
!:
	sta 0, x
	inx
	cpx #$e0
	bne !-
	// check if top loader is present
	ldx #0
	lda top_loader_start
	cmp #<top_magic
	bne !+
	lda top_loader_start + 1
	cmp #>top_magic
	bne !+
	ldx #1
!:
	stx has_top_loader
	rts

game_over:
	// kill sid
	lda #0
	ldx #0
!:
	sta sid, x
	inx
	cpx #$20
	bne !-
	inc music_mute

	// overwrite level sid with gameover sid
	ldx #0
!:
	.for (var i = 0; i < (music_gameover.size - 255) / 256 + 1; i++) {
		lda sid_gameover + i * $100, x
		sta music_begin  + i * $100, x
	}
	inx
	bne !-

	// init tune
	lda #music_gameover.startSong - 1
	jsr music_gameover.init

	lda #<music_gameover.play
	sta sid_play + 1
	lda #>music_gameover.play
	sta sid_play + 2

	dec music_mute

	// goto main screen
	lda #0
	sta window
	jsr update_screen

	// wait till tune has stopped
	lda #<gameover_delay
	sta gameover_timer
	lda #>gameover_delay
	sta gameover_timer + 1
!:
	lda gameover_timer + 1
	bne !-
	lda gameover_timer
	bne !-

	rts

check_space:
	lda $dc01
	cmp #$ef
	beq !+
	rts
!:
	jsr game_over

	// go to main menu if top loader is present or soft reset
reset_ctl:
	lda has_top_loader
	beq !+
	pla
	lda #2
	sta prg_index
	jmp top_loader_start
!:
	// kill irq
	sei
	lda #$37
	sta $1
	lda #<dummy
	sta $fffa
	sta $fffc
	sta $fffe
	lda #>dummy
	sta $fffb
	sta $fffd
	sta $ffff
	cli
	// soft reset
	jmp reset

setup_interrupt:

	sei
	lda #$35
	sta $1

	lda #1
	sta $dd00

	lda #<irq_bottom
	sta $fffe
	lda #>irq_bottom
	sta $ffff
	lda #$1b
	sta $d011
	lda #$01
	sta $d01a
	// enable all NMIs
	lda #$7f
	sta $dc0d
	sta $dd0d
	lda $dc0d
	lda $dd0d

	asl $d019
	cli

	// enable all NMIs
	lda #$7f
	sta $dc0d
	sta $dd0d
	lda $dc0d
	lda $dd0d

	asl $d019
	cli

	rts

dummy:
	asl $d019
	rti


// bottom irq
irq_bottom:
	irq
	lda #$00
	sta $d012
	lda #$00
	sta $d011
	sta sprmask

	qri : #irq_top

// top irq
irq_top:
	irq

	lda #$1b //If you want to display a bitmap pic, use #$3b instead
	sta $d011

	ldx window
	lda tbl_bkg_col, x
	sta $d021

	lda #spr_enable_mask
	sta sprmask

	ldx music_mute
	bne !+
sid_play:
	jsr music_level.play
	inc gameover_timer
	bne !+
	inc gameover_timer + 1
!:

	qri #irq_middle_line : #irq_middle

// open border magic happens in this irq
irq_middle:
	irq

	lda #BLACK
	sta $d020
	sta $d021

	lda #$fa
	sta $d012
	lda #$1b //If you want to display a bitmap pic, use #$3b instead
	sta $d011

	qri : #irq_bottom

init_sprites:
	ldx #0
!:
	lda data_star, x
	sta spr_star, x
	lda data_map, x
	sta spr_map, x
	lda data_euro, x
	sta spr_euro, x
	lda data_settings, x
	sta spr_settings, x
	lda data_arrow, x
	sta spr_arrow, x
	inx
	cpx #63
	bne !-

	lda #(spr_map / 64 - vic)

	sta screen_main + $3f8
	sta screen_subsidies + $3f8
	sta screen_log + $3f8
	sta screen_options + $3f8

	lda #(spr_euro / 64 - vic)

	sta screen_main + $3f9
	sta screen_subsidies + $3f9
	sta screen_log + $3f9
	sta screen_options + $3f9

	// TODO use other sprite for log stuff
	lda #(spr_star / 64 - vic)

	sta screen_main + $3fa
	sta screen_subsidies + $3fa
	sta screen_log + $3fa
	sta screen_options + $3fa

	lda #(spr_settings / 64 - vic)

	sta screen_main + $3fb
	sta screen_subsidies + $3fb
	sta screen_log + $3fb
	sta screen_options + $3fb

	lda #(spr_arrow / 64 - vic)

	sta screen_main + $3fc
	sta screen_subsidies + $3fc
	sta screen_log + $3fc
	sta screen_options + $3fc

	// sprite completely visible in range [24, 320]
	// sprite is 24 pixels wide, so:
	lda #24 - 24 / 2 + 0 * 80 + 40
	sta sprx0
	lda #24 - 24 / 2 + 1 * 80 + 40
	sta sprx1
	lda #24 - 24 / 2 + 2 * 80 + 40
	sta sprx2
	lda #24 - 24 / 2 + 3 * 80 + 40
	sta sprx3
	lda #$18
	sta spry0
	sta spry1
	sta spry2
	sta spry3
	sta spry4
	lda tbl_arrow_pos_lo
	sta sprx4

	// highest bit of spr3 must be set
	lda tbl_arrow_pos_hi
	sta sprxhi

	// enable sprites 4,3,2,1,0
	lda #spr_enable_mask
	sta sprmask

	// setup colors
	lda #WHITE
	sta sprcol0
	lda #YELLOW
	sta sprcol1
	lda #RED
	sta sprcol2
	lda #CYAN
	sta sprcol3
	lda #GREEN
	sta sprcol4

	rts

tbl_bkg_col:
	// screens: map, money, log, settings
	.byte GREEN, BLACK, GREY, BLACK

copy_screens:
	// copy first screen
	ldx #0
!:
	lda level1_image_data + $000, x
	sta screen_main       + $000, x
	lda level1_image_data + $100, x
	sta screen_main       + $100, x
	lda level1_image_data + $200, x
	sta screen_main       + $200, x
	lda level1_image_data + $2e8, x
	sta screen_main       + $2e8, x

	lda level1_color_data + $000, x
	sta colram            + $000, x
	lda level1_color_data + $100, x
	sta colram            + $100, x
	lda level1_color_data + $200, x
	sta colram            + $200, x
	lda level1_color_data + $2e8, x
	sta colram            + $2e8, x

	dex
	bne !-

	lda #%00000100
	sta $d018

	// copy other screens
!:
	lda subsidies_image  + $000, x
	sta screen_subsidies + $000, x
	lda subsidies_image  + $100, x
	sta screen_subsidies + $100, x
	lda subsidies_image  + $200, x
	sta screen_subsidies + $200, x
	lda subsidies_image  + $2e8, x
	sta screen_subsidies + $2e8, x

	lda log_image  + $000, x
	sta screen_log + $000, x
	lda log_image  + $100, x
	sta screen_log + $100, x
	lda log_image  + $200, x
	sta screen_log + $200, x
	lda log_image  + $2e8, x
	sta screen_log + $2e8, x
	lda options_image  + $000, x
	sta screen_options + $000, x
	lda options_image  + $100, x
	sta screen_options + $100, x
	lda options_image  + $200, x
	sta screen_options + $200, x
	lda options_image  + $2e8, x
	sta screen_options + $2e8, x
	dex
	bne !-

	rts

update_screen:
	ldx window
	lda tbl_arrow_pos_lo, x
	sta sprx4
	lda tbl_arrow_pos_hi, x
	sta sprxhi
	lda vec_colram_lo, x
	sta jmp_buf
	lda vec_colram_hi, x
	sta jmp_buf + 1
	jmp (jmp_buf)

goto_main:
	lda #%00000100
	sta $d018

	ldx #0
!:
	lda level1_color_data + $000, x
	sta colram            + $000, x
	lda level1_color_data + $100, x
	sta colram            + $100, x
	lda level1_color_data + $200, x
	sta colram            + $200, x
	lda level1_color_data + $2e8, x
	sta colram            + $2e8, x

	dex
	bne !-
	rts

goto_subsidies:
	lda #%00010100
	sta $d018

	ldx #0
!:
	lda subsidies_colors + $000, x
	sta colram           + $000, x
	lda subsidies_colors + $100, x
	sta colram           + $100, x
	lda subsidies_colors + $200, x
	sta colram           + $200, x
	lda subsidies_colors + $2e8, x
	sta colram           + $2e8, x

	dex
	bne !-
	rts

goto_log:
	lda #%00100100
	sta $d018

	ldx #0
!:
	lda log_colors + $000, x
	sta colram     + $000, x
	lda log_colors + $100, x
	sta colram     + $100, x
	lda log_colors + $200, x
	sta colram     + $200, x
	lda log_colors + $2e8, x
	sta colram     + $2e8, x

	dex
	bne !-
	rts

goto_options:
	lda #%00110100
	sta $d018

	ldx #0
!:
	lda options_colors + $000, x
	sta colram         + $000, x
	lda options_colors + $100, x
	sta colram         + $100, x
	lda options_colors + $200, x
	sta colram         + $200, x
	lda options_colors + $2e8, x
	sta colram         + $2e8, x

	dex
	bne !-
	rts

// jumptable
vec_colram_lo:
	.byte <goto_main
	.byte <goto_subsidies
	.byte <goto_log
	.byte <goto_options
vec_colram_hi:
	.byte >goto_main
	.byte >goto_subsidies
	.byte >goto_log
	.byte >goto_options

.pc = music_begin "music area"

* = music_level.location "level tune"
	.fill music_level.size, music_level.getData(i)

.pc = music_end "main screen"
#import "level1_europe.asm"

.pc = * "subsidies screen"
#import "subsidies.asm"

.pc = * "log screen"
#import "log.asm"

.pc = * "options screen"
#import "options.asm"

.pc = * "sprites"
data_map:
	.byte $00,$00,$00,$1f,$ff,$f8,$10,$00
	.byte $38,$11,$c0,$78,$16,$07,$28,$14
	.byte $0f,$88,$14,$cd,$88,$14,$4d,$88
	.byte $13,$cf,$88,$10,$0f,$88,$10,$07
	.byte $08,$10,$37,$08,$10,$72,$08,$10
	.byte $e2,$08,$13,$c0,$88,$17,$01,$c8
	.byte $1e,$00,$e8,$1c,$00,$78,$18,$00
	.byte $38,$1f,$ff,$f8,$00,$00,$00,$01
data_euro:
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$7f,$00,$01,$c1,$c0,$01
	.byte $00,$40,$01,$1c,$40,$01,$30,$40
	.byte $01,$20,$40,$01,$78,$40,$01,$20
	.byte $40,$01,$78,$40,$01,$20,$40,$01
	.byte $30,$40,$01,$1c,$40,$01,$00,$40
	.byte $01,$c1,$c0,$00,$7f,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$0d
data_star:
	.byte %00000000,%00011000,%00000000
	.byte %00000000,%00011000,%00000000
	.byte %00000000,%00011000,%00000000
	.byte %00000000,%00111100,%00000000
	.byte %00000000,%00111100,%00000000
	.byte %00000000,%00111100,%00000000
	.byte %00000000,%01111110,%00000000
	.byte %00000000,%01111110,%00000000
	.byte %11111111,%11111111,%11111111
	.byte %01111111,%11111111,%11111110
	.byte %00011111,%11111111,%11111000
	.byte %00000111,%11111111,%11100000
	.byte %00000011,%11111111,%11000000
	.byte %00000001,%11111111,%10000000
	.byte %00000001,%11111111,%10000000
	.byte %00000011,%11111111,%11000000
	.byte %00000011,%11100111,%11000000
	.byte %00000111,%10000001,%11100000
	.byte %00000111,%00000000,%11100000
	.byte %00000110,%00000000,%01100000
	.byte %00001100,%00000000,%00110000
data_settings:
	.byte $00,$00,$00,$00,$00,$00,$07,$00
	.byte $00,$03,$80,$00,$00,$e0,$00,$20
	.byte $e0,$00,$30,$e0,$00,$31,$e0,$00
	.byte $1f,$f0,$00,$0f,$f8,$00,$00,$7c
	.byte $00,$00,$3e,$00,$00,$0f,$80,$00
	.byte $07,$c0,$00,$03,$f0,$00,$01,$88
	.byte $00,$00,$98,$00,$00,$b0,$00,$00
	.byte $60,$00,$00,$00,$00,$00,$00,$01
data_arrow:
	.byte $00,$00,$00,$00,$00,$00,$00,$08
	.byte $00,$00,$0c,$00,$00,$0e,$00,$00
	.byte $0f,$00,$00,$0f,$80,$3f,$ff,$c0
	.byte $3f,$ff,$e0,$3f,$ff,$f0,$3f,$ff
	.byte $f8,$3f,$ff,$f0,$3f,$ff,$e0,$3f
	.byte $ff,$c0,$00,$0f,$80,$00,$0f,$00
	.byte $00,$0e,$00,$00,$0c,$00,$00,$08
	.byte $00,$00,$00,$00,$00,$00,$00,$00

tbl_arrow_pos_lo:
	.byte -24 / 2 + 0 * 80 + 40
	.byte -24 / 2 + 1 * 80 + 40
	.byte -24 / 2 + 2 * 80 + 40
	.byte -24 / 2 + 3 * 80 + 40

tbl_arrow_pos_hi:
	.byte %00001000
	.byte %00001000
	.byte %00001000
	.byte %00011000

.pc = * "gameover tune"
sid_gameover:
	.fill music_gameover.size, music_gameover.getData(i)
