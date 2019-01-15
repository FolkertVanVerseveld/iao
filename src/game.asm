:BasicUpstart2(start)

/*
Core game mechanics
Code: methos, theezakje
*/

#import "zeropage.inc"
#import "loader.inc"
#import "macros.inc"
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
// use last screen for sprite data
.var sprdata = vic + 15 * $0400

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
	sta $d015

	qri : #irq_top

// top irq
irq_top:
	irq

	lda #$1b //If you want to display a bitmap pic, use #$3b instead
	sta $d011

	ldx window
	lda tbl_bkg_col, x
	sta $d021

	lda #%1111
	sta $d015

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
	lda spr_star, x
	sta sprdata, x
	inx
	cpx #63
	bne !-

	// just use stars for all screens
	lda #(sprdata / 64 - vic)

	// store all sprite pointers
	sta screen_main + $3f8
	sta screen_main + $3f9
	sta screen_main + $3fa
	sta screen_main + $3fb
	sta screen_subsidies + $3f8
	sta screen_subsidies + $3f9
	sta screen_subsidies + $3fa
	sta screen_subsidies + $3fb
	sta screen_log + $3f8
	sta screen_log + $3f9
	sta screen_log + $3fa
	sta screen_log + $3fb
	sta screen_options + $3f8
	sta screen_options + $3f9
	sta screen_options + $3fa
	sta screen_options + $3fb

	// enable sprites 3,2,1,0
	lda #%1111
	sta $d015

	// sprite completely visible in range [24, 320]
	// sprite is 24 pixels wide, so:
	lda #24 - 24 / 2 + 0 * 80 + 40
	sta $d000
	lda #24 - 24 / 2 + 1 * 80 + 40
	sta $d002
	lda #24 - 24 / 2 + 2 * 80 + 40
	sta $d004
	lda #24 - 24 / 2 + 3 * 80 + 40
	sta $d006
	lda #$18
	sta $d001
	sta $d003
	sta $d005
	sta $d007

	// highest bit of spr3 must be set
	lda #%00001000
	sta $d010

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
spr_star:
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

.pc = * "gameover tune"
sid_gameover:
	.fill music_gameover.size, music_gameover.getData(i)
