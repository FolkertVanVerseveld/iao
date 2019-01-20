:BasicUpstart2(start)

/*
Core game mechanics
Code: methos, theezakje, flevosap
*/

#import "zeropage.inc"
#import "loader.inc"
#import "pseudo.lib"
#import "joy.inc"
#import "io.inc"
#import "cia.inc"
#import "kernal.inc"
#import "consts.inc"
#import "engine/scrn_addr.inc"

.var spr_enable_mask = %10011111

// TODO use custom font to redefine dollar character into euro valuta
// custom font takes two screens
.var game_font = vic + 6 * 2 * $0400

// use last screen for sprite data
.var sprdata = vic + 14 * $0400

// destination for sprite data
.var spr_star     = sprdata + 0 * 64
.var spr_map      = sprdata + 1 * 64
.var spr_euro     = sprdata + 2 * 64
.var spr_settings = sprdata + 3 * 64
.var spr_arrow    = sprdata + 4 * 64

.var spr_oeps0    = sprdata + 5 * 64
.var spr_oeps1    = sprdata + 6 * 64
.var spr_oeps2    = sprdata + 7 * 64
.var spr_oeps3    = sprdata + 8 * 64

.var spr_empty    = sprdata + 9 * 64

.var spr_water	  = sprdata + 10 * 64
.var spr_elec	  = sprdata + 11 * 64
.var spr_cyb	  = sprdata + 12 * 64

.var irq_text_top_line = $30

// open border magic happens in this irq, DO NOT CHANGE
.var irq_magic_line = $ef

.const gameover_delay = $10000 - $300

//.var music_gameover = LoadSid(HVSC + "/MUSICIANS/0-9/20CC/van_Santen_Edwin/13_Seconds_of_Massacre.sid")
.var music_gameover = LoadSid("assets/13_Seconds_of_Massacre.sid")

//.var music_level = LoadSid(HVSC + "/MUSICIANS/0-9/20CC/van_Santen_Edwin/Rettekettet.sid")
.var music_level = LoadSid("assets/Rettekettet.sid")

.var music_begin = min(music_gameover.location, music_level.location)
.var music_size = max(music_gameover.size, music_level.size)
.var music_end = music_begin + music_size + 1

.print "music begin=" + toHexString(music_begin)
.print "music size=" + toHexString(music_size)
.print "music end=" + toHexString(music_end)

.pc = * "Game start"

start:
	jsr change_font
	lda #music_level.startSong - 1
	jsr music_level.init
	jsr setup_interrupt
	jsr initialize_month_timer
	jsr init_sprites
	jsr copy_screens
	jsr init_money
	jsr init_itb
	jsr init_inv
	jsr init_disaster
	//jsr init_disaster_sprite
    jsr write_itb
    jsr write_date
    jsr write_subsidy
    jsr write_expenditure

	jsr change_font

	// save first disaster
	// this code must be run after all screen and video has been set up
	ldx lfsr4_state
	lda tbl_scr_disaster_lo, x
	sta !fetch_ch+ + 1
	lda tbl_scr_disaster_hi, x
	sta !fetch_ch+ + 2
!fetch_ch:
	lda screen_main
	sta disaster_chr
	lda tbl_col0_disaster_lo, x
	sta !fetch_col+ + 1
	lda tbl_col0_disaster_hi, x
	sta !fetch_col+ + 2
!fetch_col:
	lda level1_color_data
	sta disaster_col

	//jsr show_disasters

.pc = * "Game loop"

game_loop:
	jsr handle_input
	// do game tick

	lda cia_timer_register
	and #2
	beq game_loop

	jsr update_date
	jsr update_money
	jsr update_subsidy
	jsr update_expenditure
	jsr update_itb

	// check if we have a new disaster
	dec disaster_timer
	bne !s+
	jsr next_disaster
	jsr copy_impact
	jsr subtract_impact
	jsr update_disaster
	jsr update_hearts
	// choose new random interval
	lda $d012
	and #%11
	bne !+
	lda #1
!:
	sta disaster_timer
!s:

	jmp game_loop

.pc = * "Input handling"

/*
handle normal key

+=================================================+
|             Returned in Accumulator             |
+===========+===========+=============+===========+
|  $00 - @  |  $10 - p  |  $20 - SPC  |  $30 - 0  |
|  $01 - a  |  $11 - q  |  $21 -      |  $31 - 1  |
|  $02 - b  |  $12 - r  |  $22 -      |  $32 - 2  |
|  $03 - c  |  $13 - s  |  $23 -      |  $33 - 3  |
|  $04 - d  |  $14 - t  |  $24 -      |  $34 - 4  |
|  $05 - e  |  $15 - u  |  $25 -      |  $35 - 5  |
|  $06 - f  |  $16 - v  |  $26 -      |  $36 - 6  |
|  $07 - g  |  $17 - w  |  $27 -      |  $37 - 7  |
|  $08 - h  |  $18 - x  |  $28 -      |  $38 - 8  |
|  $09 - i  |  $19 - y  |  $29 -      |  $39 - 9  |
|  $0a - j  |  $1a - z  |  $2a - *    |  $3a - :  |
|  $0b - k  |  $1b -    |  $2b - +    |  $3b - ;  |
|  $0c - l  |  $1c - £  |  $2c - ,    |  $3c -    |
|  $0d - m  |  $1d -    |  $2d - -    |  $3d - =  |
|  $0e - n  |  $1e - ^  |  $2e - .    |  $3e -    |
|  $0f - o  |  $1f - <- |  $2f - /    |  $3f -    |
+-----------+-----------+-------------+-----------+
*/
handle_key:
	ldx window
	cpx #1
	bne !+
	jmp subsidies_handle_key
!:

	// If m is pressed, toggle music
	// Options screen
	cpx #3
	bne !+
	// On options screen
	// Should key already be loaded in to accumulator??
	cmp #'m' // m
	bne !+
	jmp toggle_music
!:
	rts

/*
handle function key
+================================================================================
|                             Return in X-Register                              |
+=========+=========+=========+=========+=========+=========+=========+=========+
|  Bit 7  |  Bit 6  |  Bit 5  |  Bit 4  |  Bit 3  |  Bit 2  |  Bit 1  |  Bit 0  |
+---------+---------+---------+---------+---------+---------+---------+---------+
| CRSR UD |   F5    |   F3    |   F1    |   F7    | CRSR RL | RETURN  |INST/DEL |
+---------+---------+---------+---------+---------+---------+---------+---------+
*/
handle_function_key:
	// check f7
	cpx #%1000
	bne !+
	lda #3
	sta window
	jmp update_screen
!:
	cpx #%10000
	bne !+
	lda #0
	sta window
	jmp update_screen
!:
	cpx #%100000
	bne !+
	lda #1
	sta window
	jmp update_screen
!:
	cpx #%1000000
	bne !+
	lda #2
	sta window
	jmp update_screen
!:
	rts

/*
handle special key
+================================================================================
|                             Return in Y-Register                              |
+=========+=========+=========+=========+=========+=========+=========+=========+
|  Bit 7  |  Bit 6  |  Bit 5  |  Bit 4  |  Bit 3  |  Bit 2  |  Bit 1  |  Bit 0  |
+---------+---------+---------+---------+---------+---------+---------+---------+
|RUN STOP | L-SHIFT |   C=    | R-SHIFT |CLR/HOME |  CTRL   |         |         |
+---------+---------+---------+---------+---------+---------+---------+---------+
*/
handle_special_key:
	// check if run/stop has been pressed
	cpy #%10000000
	bne !+
	jmp game_over
!:
	rts

// NOTE inlined: kbdjoy.asm
// process keyboard and joystick
handle_input:
	// save CIA1 state
	lda $dc02
	sta key_ddr0
	lda $dc03
	sta key_ddr1
	jsr Keyboard
	bcs !+
	stx key_x
	sty key_y
	cmp #$ff
	beq !no_alpha+
	// handle alphanumeric key
	jsr handle_key
!no_alpha:
	ldx key_x
	beq !+
	jsr handle_function_key
!:
	ldy key_y
	beq !+
	jsr handle_special_key
!:
	// restore CIA1 state
	lda #0
	sta $dc02
	lda key_ddr1
	sta $dc03
	// read joy2 state
	lda $dc00
	and #%11111
	// handle joystick
	jmp joy_ctl

// joystick control

joy_ctl:
	.if (false) {
	// show joy2 for debug purposes
	lda $dc00
	sta joy2
	}

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
	cmp #joy_fire
	bne !+
	ldx #3
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

.pc = * "screen navigation"

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

// joystick control data

vec_scr_lo:
	.byte <scr_next, <scr_prev, <next_disaster
vec_scr_hi:
	.byte >scr_next, >scr_prev, >next_disaster

// more init code

change_font:
	sei
	lda $1
	sta !restore+ + 1
	// make char rom visible
	lda #%00110011
	sta $1
	// now copy char rom
	ldx #0
!:
	lda font      + $000, x
	sta game_font + $000, x
	lda font      + $100, x
	sta game_font + $100, x
	lda font      + $200, x
	sta game_font + $200, x
	lda font      + $300, x
	sta game_font + $300, x
	lda font      + $400, x
	sta game_font + $400, x
	lda font      + $500, x
	sta game_font + $500, x
	lda font      + $600, x
	sta game_font + $600, x
	lda font      + $700, x
	sta game_font + $700, x
	inx
	bne !-

	// restore banks to default
!restore:
	lda #%00110111
	// mask bits we don't want to set
	and #%00110111
	sta $1
	cli
	// now patch dollar to euro valuta
	ldx #0
!:
	lda chr_euro, x
	sta game_font + $24 * 8, x
	inx
	cpx #$8
	bne !-
	rts

/*
clear zeropage data section and initialize
global game state, joystick driver, rng and date stuff
*/
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
	// initialize prng
	lda $d012
	bne !+
	lda #%1100
!:
	and #$f
	sta lfsr4_state

	// initialize date stuff
        mov #1 : date_month
        mov #11 : date_year
        mov #64 : date_last

	// disaster_prng
	lda $d012
	and #%11
	bne !+
	lda #1
!:
	sta disaster_timer
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

	inc hide_arrow

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

	lda #<dummy
	sta $fffa
	sta $fffc
	lda #>dummy
	sta $fffb
	sta $fffd

	lda #<irq_bottom
	sta $fffe
	lda #>irq_bottom
	sta $ffff
	lda #$1b
	sta $d011
	lda #$01
	sta $d01a

	// disable all NMIs
	lda #$7f
	sta $dc0d
	sta $dd0d
	lda $dc0d
	lda $dd0d

	asl $d019
	jsr init
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

	// fix bug in video chip
	lda #$ff
	sta vic + $3fff

	qri : #irq_top

// top irq
irq_top:
	irq

	lda #$1b //If you want to display a bitmap pic, use #$3b instead
	sta $d011

	ldx window
	lda tbl_bkg_col, x
	sta $d021

	// restore arrow sprite
	jsr init_menu_sprites
	jsr update_arrow

	lda #spr_enable_mask
	ldx hide_arrow
	beq !+
	eor #%10000000
!:
	sta sprmask

	ldx music_mute
	bne !+
sid_play:
	jsr music_level.play
	inc gameover_timer
	bne !+
	inc gameover_timer + 1
!:

	qri #irq_text_top_line : #irq_text_top

// this irq happens just before the petscii text is being drawn
irq_text_top:
	irq

	lda window
	bne !+
	lda hide_arrow
	beq !+

	// this code shows game over letters
	jsr show_game_over
!:

	lda #%10001111
	sta sprmask

	lda window
	cmp #2
	bne !+
	lda disaster_occurred
	beq !+
	lda #%10011111
	sta sprmask

	lda lfsr4_state
    tax
    ldy tbl_col_disaster, X
	lsr; lsr
	tax
	lda tbl_dis_spr, x
	sta screen_log + $3f8 + 4

	sty sprcol4
	lda #$20
	sta sprx4
	lda #$40
	sta spry4
!:

	qri #irq_magic_line : #irq_magic

// open border magic happens in this irq
irq_magic:
	irq

	lda #BLACK
	sta $d020
	sta $d021

	lda #$fa
	sta $d012
	lda #$1b //If you want to display a bitmap pic, use #$3b instead
	sta $d011

	// do not change anything above this line in the irq!

	lda window
	bne !+
	lda hide_arrow
	beq !+
!:

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
	lda data_oeps0, x
	sta spr_oeps0, x
	lda data_oeps1, x
	sta spr_oeps1, x
	lda data_oeps2, x
	sta spr_oeps2, x
	lda data_oeps3, x
	sta spr_oeps3, x
	lda #0
	sta spr_empty, x
	lda data_water, X
	sta spr_water, X
	lda data_elec, X
	sta spr_elec, X
	lda data_cyb, X
	sta spr_cyb, X
	inx
	cpx #63
	bne !-

	lda #(spr_arrow / 64 - vic)

	sta screen_main + $3ff
	sta screen_subsidies + $3ff
	sta screen_log + $3ff
	sta screen_options + $3ff

	lda #$18
	sta spry7
	lda tbl_arrow_pos_lo
	sta sprx7

	// highest bit of spr3 must be set
	lda tbl_arrow_pos_hi
	sta sprxhi

init_menu_sprites:
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

	// enable sprites 7,3,2,1,0
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
	sta sprcol7

	lda #%000010000
	sta sprdw
	sta sprdh
	rts

tbl_bkg_col:
	// screens: map, money, log, settings
	.byte GREEN, BLACK, GREY, BLACK

tbl_dis_spr:
	.byte sprpos(vic, spr_water), sprpos(vic, spr_elec), sprpos(vic, spr_star), sprpos(vic, spr_cyb)

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

	lda #memsetup_mask
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

update_arrow:
	ldx window
	lda tbl_arrow_pos_lo, x
	sta sprx7
	lda tbl_arrow_pos_hi, x
	sta sprxhi
	rts

update_screen:
	lda window
	cmp #$02
	bne not_dis_scr
	lda sprmask
	add #%00010000
	sta sprmask
	jmp jmp_dis_scr
not_dis_scr:
	lda sprmask
	and #%11101111
	sta sprmask
jmp_dis_scr:
	jsr update_arrow
	lda vec_colram_lo, x
	sta jmp_buf
	lda vec_colram_hi, x
	sta jmp_buf + 1
	jmp (jmp_buf)

toggle_music:
	ldx music_mute // Should be 0 if playing, non-zero if muted
	beq !+
	// Turn on here
	ldx #$00
	stx music_mute
	// Set chars in screen
	lda #'a'
	sta screen_options + (5 * 40) + 26
	lda #'a'
	sta screen_options + (5 * 40) + 27
	lda #'n'
	sta screen_options + (5 * 40) + 28
	rts
!:
	// Turn off here
	ldx #$01
	stx music_mute
	// kill sid
	lda #0
	ldx #0
!:
	sta sid, x
	inx
	cpx #$20
	bne !-

	// Set chars in screen
	lda #'u'
	sta screen_options + (5 * 40) + 26
	lda #'i'
	sta screen_options + (5 * 40) + 27
	lda #'t'
	sta screen_options + (5 * 40) + 28
	rts

/////////////////////////////////
// menu screen transition code //
/////////////////////////////////

goto_main:
	lda #memsetup_mask
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
	lda #memsetup_mask + %00010000
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
	lda #memsetup_mask + %00100000
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
	lda #memsetup_mask + %00110000
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

show_game_over:
	lda #(spr_oeps0 / 64 - vic)
	sta screen_main + $3f8
	lda #(spr_oeps1 / 64 - vic)
	sta screen_main + $3f9
	lda #(spr_oeps2 / 64 - vic)
	sta screen_main + $3fa
	lda #(spr_oeps3 / 64 - vic)
	sta screen_main + $3fb

	lda #(320 - 24 - 2 * 24) / 2 + 0 * 24 + 12
	sta sprx0
	lda #(320 - 24 - 2 * 24) / 2 + 1 * 24 + 12
	sta sprx1
	lda #(320 - 24 - 2 * 24) / 2 + 2 * 24 + 12
	sta sprx2
	lda #(320 - 24 - 2 * 24) / 2 + 3 * 24 + 12
	sta sprx3

	ldx game_over_index
	lda tbl_game_over_y, x
	sta spry0
	lda tbl_game_over_y + 4, x
	sta spry1
	lda tbl_game_over_y + 8, x
	sta spry2
	lda tbl_game_over_y + 12, x
	sta spry3

	inx
	txa
	and #$20 - 1
	sta game_over_index

	ldx game_over_colindex

	and #$7
	cmp #$7
	bne !+
	inx
	txa
	and #$8 - 1
	sta game_over_colindex
!:

	lda tbl_game_over_col, x
	sta sprcol0
	lda tbl_game_over_col + 1, x
	sta sprcol1
	lda tbl_game_over_col + 2, x
	sta sprcol2
	lda tbl_game_over_col + 3, x
	sta sprcol3

	lda #%1111
	sta sprmask

	lda #0
	sta sprxhi
	rts

next_disaster:
	lda #1
	sta disaster_occurred

	ldx lfsr4_state

	// store state on screen to know it should work...
	.if (false) {
	lda hexstring, x
	sta screen_main
	lda #WHITE
	sta colram
	}

	// restore previous character
	lda tbl_scr_disaster_lo, x
	sta !put_ch+ + 1
	lda tbl_scr_disaster_hi, x
	sta !put_ch+ + 2
	lda disaster_chr
!put_ch:
	sta screen_main
	lda tbl_col0_disaster_lo, x
	sta !put_col0+ + 1
	lda tbl_col0_disaster_hi, x
	sta !put_col0+ + 2
	lda disaster_col
!put_col0:
	sta level1_color_data
	// only update colram if this window is visible
	lda window
	bne !+
	lda tbl_col1_disaster_lo, x
	sta !put_col1+ + 1
	lda tbl_col1_disaster_hi, x
	sta !put_col1+ + 2
	lda disaster_col
!put_col1:
	sta colram
!:

	jsr lfsr4_next
	ldx lfsr4_state

	// remember old state
	lda tbl_scr_disaster_lo, x
	sta !fetch_ch+ + 1
	lda tbl_scr_disaster_hi, x
	sta !fetch_ch+ + 2
!fetch_ch:
	lda screen_main
	sta disaster_chr
	lda tbl_col0_disaster_lo, x
	sta !fetch_col+ + 1
	lda tbl_col0_disaster_hi, x
	sta !fetch_col+ + 2
!fetch_col:
	lda colram
	sta disaster_col

	// now place new disaster
	lda tbl_scr_disaster_lo, x
	sta !put_ch+ + 1
	lda tbl_scr_disaster_hi, x
	sta !put_ch+ + 2
	// cross character
	lda #$56
!put_ch:
	sta screen_main
	lda tbl_col0_disaster_lo, x
	sta !put_col0+ + 1
	lda tbl_col0_disaster_hi, x
	sta !put_col0+ + 2
	lda tbl_col_disaster, x
!put_col0:
	sta level1_color_data
	// only update colram if this window is visible
	lda window
	bne !+
	lda tbl_col1_disaster_lo, x
	sta !put_col1+ + 1
	lda tbl_col1_disaster_hi, x
	sta !put_col1+ + 2
	lda tbl_col_disaster, x
!put_col1:
	sta colram
!:
	rts

lfsr4_next:
	// bit = ((lfsr >> 0) ^ (lfsr >> 1)) & 1
	// lfsr = (lfsr >> 1) | (bit << 3)
	lda lfsr4_state
	lsr lfsr4_state
	eor lfsr4_state
	and #1
	beq !+
	lda #8
	ora lfsr4_state
	sta lfsr4_state
!:
	rts

show_disasters:
	ldx #0
!:
	lda tbl_scr_disaster_lo, x
	sta !put_scr+ + 1
	lda tbl_scr_disaster_hi, x
	sta !put_scr+ + 2
	lda #$56
!put_scr:
	sta screen_main
	// NOTE we have to both update colram and the original screen data
	// because otherwise, we can switch back and forth between screens
	// and the wrong old colram data will show up
	lda tbl_col0_disaster_lo, x
	sta !put_col0+ + 1
	lda tbl_col0_disaster_hi, x
	sta !put_col0+ + 2
	lda tbl_col_disaster, x
!put_col0:
	sta level1_color_data
	lda tbl_col1_disaster_lo, x
	sta !put_col1+ + 1
	lda tbl_col1_disaster_hi, x
	sta !put_col1+ + 2
	lda tbl_col_disaster, x
!put_col1:
	sta colram
	inx
	cpx #16
	bne !-
	rts

game_over_index:
	.byte 0
game_over_colindex:
	.byte 0

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
	.byte $00,$00,$00,$00,$00,$00,$00,$ff
	.byte $00,$01,$ff,$80,$03,$c1,$c0,$07
	.byte $81,$e0,$07,$9f,$e0,$0f,$bf,$f0
	.byte $0f,$07,$f0,$0f,$07,$f0,$0f,$bf
	.byte $f0,$0f,$bf,$f0,$0f,$07,$f0,$0f
	.byte $07,$f0,$0f,$bf,$f0,$07,$9f,$e0
	.byte $07,$81,$e0,$03,$c1,$c0,$01,$ff
	.byte $80,$00,$ff,$00,$00,$00,$00,$0d
data_star:
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$18,$00,$00,$3c,$00,$00
	.byte $7e,$00,$00,$e7,$00,$01,$e7,$80
	.byte $03,$e7,$c0,$07,$e7,$e0,$0f,$e7
	.byte $f0,$1f,$e7,$f8,$3f,$ff,$fc,$3f
	.byte $e7,$fc,$3f,$e7,$fc,$3f,$ff,$fc
	.byte $1f,$ff,$f8,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$07
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
data_water:
	.byte $00,$00,$00,$00,$00,$00,$00,$18
	.byte $00,$00,$18,$00,$00,$18,$00,$00
	.byte $3c,$00,$00,$3c,$00,$00,$7e,$00
	.byte $00,$7e,$00,$00,$ff,$00,$00,$ff
	.byte $00,$01,$ff,$80,$01,$ff,$80,$01
	.byte $ff,$80,$01,$ff,$80,$01,$ff,$80
	.byte $00,$ff,$00,$00,$7e,$00,$00,$3c
	.byte $00,$00,$00,$00,$00,$00,$00,$06
data_elec:
	.byte $00,$00,$00,$00,$1f,$c0,$00,$1f
	.byte $c0,$00,$3f,$80,$00,$3f,$00,$00
	.byte $7e,$00,$00,$7c,$00,$00,$f8,$00
	.byte $00,$3f,$00,$00,$3e,$00,$00,$7c
	.byte $00,$00,$78,$00,$00,$f0,$00,$00
	.byte $e0,$00,$01,$c0,$00,$01,$80,$00
	.byte $03,$00,$00,$02,$00,$00,$04,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$07
data_cyb:
	.byte $00,$00,$00,$00,$00,$00,$00,$3c
	.byte $00,$00,$3c,$00,$00,$3c,$00,$00
	.byte $3c,$00,$0c,$3c,$30,$0f,$3c,$f0
	.byte $1f,$ff,$f8,$1f,$ff,$f8,$0f,$ff
	.byte $f0,$03,$ff,$c0,$00,$ff,$00,$01
	.byte $ff,$80,$01,$ff,$80,$03,$ff,$c0
	.byte $07,$e7,$e0,$07,$c3,$e0,$03,$81
	.byte $c0,$00,$00,$00,$00,$00,$00,$05

.pc = * "keyboard driver"

#import "kbd.asm"

#import "oeps.spr"

tbl_arrow_pos_lo:
	.byte -24 / 2 + 0 * 80 + 40
	.byte -24 / 2 + 1 * 80 + 40
	.byte -24 / 2 + 2 * 80 + 40
	.byte -24 / 2 + 3 * 80 + 40

tbl_arrow_pos_hi:
	.byte %00001000
	.byte %00001000
	.byte %00001000
	.byte %10001000

tbl_game_over_y:
	.fill $20, round(90 + $8 * sin(toRadians(i * 360 / $20)))
	.fill $20, round(90 + $8 * sin(toRadians(i * 360 / $20)))

tbl_game_over_col:
	.byte 3, 7, 9, 10, 4, 13, 11, 12
	.byte 3, 7, 9, 10

chr_euro:
	.byte %00111110
	.byte %01100000
	.byte %11111100
	.byte %01100000
	.byte %11111100
	.byte %01100000
	.byte %00111110
	.byte %00000000

.pc = * "infrastructure data"

.pc = * "disaster data"

tbl_scr_disaster_lo:
	.byte <screen_main +  0 * 40 + 19, <screen_main +  5 * 40 + 13, <screen_main + 18 * 40 +  3, <screen_main + 20 * 40 + 29
	.byte <screen_main + 10 * 40 +  5, <screen_main +  7 * 40 + 19, <screen_main +  5 * 40 + 35, <screen_main + 19 * 40 + 18
	.byte <screen_main +  0 * 40 + 24, <screen_main +  1 * 40 +  0, <screen_main + 18 * 40 + 34, <screen_main + 19 * 40 + 37
	.byte <screen_main +  5 * 40 +  7, <screen_main +  6 * 40 + 16, <screen_main +  9 * 40 + 28, <screen_main + 17 * 40 + 15
tbl_scr_disaster_hi:
	.byte >screen_main +  0 * 40 + 19, >screen_main +  5 * 40 + 13, >screen_main + 18 * 40 +  3, >screen_main + 20 * 40 + 29
	.byte >screen_main + 10 * 40 +  5, >screen_main +  7 * 40 + 19, >screen_main +  5 * 40 + 35, >screen_main + 19 * 40 + 18
	.byte >screen_main +  0 * 40 + 24, >screen_main +  1 * 40 +  0, >screen_main + 18 * 40 + 34, >screen_main + 19 * 40 + 37
	.byte >screen_main +  5 * 40 +  7, >screen_main +  6 * 40 + 16, >screen_main +  9 * 40 + 28, >screen_main + 17 * 40 + 15
tbl_col0_disaster_lo:
	.byte <level1_color_data +  0 * 40 + 19, <level1_color_data +  5 * 40 + 13, <level1_color_data + 18 * 40 +  3, <level1_color_data + 20 * 40 + 29
	.byte <level1_color_data + 10 * 40 +  5, <level1_color_data +  7 * 40 + 19, <level1_color_data +  5 * 40 + 35, <level1_color_data + 19 * 40 + 18
	.byte <level1_color_data +  0 * 40 + 24, <level1_color_data +  1 * 40 +  0, <level1_color_data + 18 * 40 + 34, <level1_color_data + 19 * 40 + 37
	.byte <level1_color_data +  5 * 40 +  7, <level1_color_data +  6 * 40 + 16, <level1_color_data +  9 * 40 + 28, <level1_color_data + 17 * 40 + 15
tbl_col0_disaster_hi:
	.byte >level1_color_data +  0 * 40 + 19, >level1_color_data +  5 * 40 + 13, >level1_color_data + 18 * 40 +  3, >level1_color_data + 20 * 40 + 29
	.byte >level1_color_data + 10 * 40 +  5, >level1_color_data +  7 * 40 + 19, >level1_color_data +  5 * 40 + 35, >level1_color_data + 19 * 40 + 18
	.byte >level1_color_data +  0 * 40 + 24, >level1_color_data +  1 * 40 +  0, >level1_color_data + 18 * 40 + 34, >level1_color_data + 19 * 40 + 37
	.byte >level1_color_data +  5 * 40 +  7, >level1_color_data +  6 * 40 + 16, >level1_color_data +  9 * 40 + 28, >level1_color_data + 17 * 40 + 15
tbl_col1_disaster_lo:
	.byte <colram +  0 * 40 + 19, <colram +  5 * 40 + 13, <colram + 18 * 40 +  3, <colram + 20 * 40 + 29
	.byte <colram + 10 * 40 +  5, <colram +  7 * 40 + 19, <colram +  5 * 40 + 35, <colram + 19 * 40 + 18
	.byte <colram +  0 * 40 + 24, <colram +  1 * 40 +  0, <colram + 18 * 40 + 34, <colram + 19 * 40 + 37
	.byte <colram +  5 * 40 +  7, <colram +  6 * 40 + 16, <colram +  9 * 40 + 28, <colram + 17 * 40 + 15
tbl_col1_disaster_hi:
	.byte >colram +  0 * 40 + 19, >colram +  5 * 40 + 13, >colram + 18 * 40 +  3, >colram + 20 * 40 + 29
	.byte >colram + 10 * 40 +  5, >colram +  7 * 40 + 19, >colram +  5 * 40 + 35, >colram + 19 * 40 + 18
	.byte >colram +  0 * 40 + 24, >colram +  1 * 40 +  0, >colram + 18 * 40 + 34, >colram + 19 * 40 + 37
	.byte >colram +  5 * 40 +  7, >colram +  6 * 40 + 16, >colram +  9 * 40 + 28, >colram + 17 * 40 + 15

tbl_col_disaster:
	.byte CYAN, CYAN, CYAN, CYAN
	.byte YELLOW, YELLOW, YELLOW, YELLOW
	.byte BROWN, BROWN, BROWN, BROWN
	.byte DARK_GREY, DARK_GREY, DARK_GREY, DARK_GREY

.pc = * "gameover tune"
sid_gameover:
	.fill music_gameover.size, music_gameover.getData(i)

.pc = * "money routines"
#import "money.asm"

.pc = * "month timer code"
#import "month_timer.asm"

.pc = * "itb routines"
#import "invest.asm"

.pc = * "disaster screen routines"
#import "disaster.asm"

#import "engine/val_to_dec_str.asm"
#import "engine/date.asm"

.pc = * "Subsidies keyboard handling"

subsidies_handle_key:
	/*
	scratch memory:
	0 = key
	1 = investment table index
	*/
	// save key
	sta scratch_main

	// column handling
	// erase old position
	ldx sub_col
	lda sub_column_col, x
	sta !erase+ + 1
	clc
	adc #1
	sta !erase2+ + 1
	lda #WHITE
!erase:
	sta colram
!erase2:
	sta colram + 1

	// determine column
	ldx sub_col
	lda scratch_main
	cmp #'q'
	bne !+
	ldx #0
!:
	cmp #'w'
	bne !+
	ldx #1
!:
	cmp #'e'
	bne !+
	ldx #2
!:
	cmp #'r'
	bne !+
	ldx #3
!:
	cmp #'t'
	bne !+
	ldx #4
!:
	stx sub_col

	// select column
	lda sub_column_col, x
	sta !put+ + 1
	clc
	adc #1
	sta !put2+ + 1
	lda #RED
!put:
	sta colram
!put2:
	sta colram + 1

	// row handling
	// erase old position
	ldx sub_row
	lda sub_row_col_lo, x
	sta !erase+ + 1
	clc
	adc #1
	sta !erase2+ + 1
	lda sub_row_col_hi, x
	sta !erase+ + 2
	sta !erase2+ + 2
	lda #WHITE
!erase:
	sta colram
!erase2:
	sta colram + 1
	// determine row
	ldx sub_row
	lda scratch_main
	cmp #'1'
	bne !+
	ldx #0
!:
	cmp #'2'
	bne !+
	ldx #1
!:
	cmp #'3'
	bne !+
	ldx #2
!:
	cmp #'4'
	bne !+
	ldx #3
!:
	stx sub_row

	// select row
	lda sub_row_col_lo, x
	sta !put+ + 1
	clc
	adc #1
	sta !put2+ + 1
	lda sub_row_col_hi, x
	sta !put+ + 2
	sta !put2+ + 2
	lda #RED
!put:
	sta colram
!put2:
	sta colram + 1

	// check for + en -
	lda scratch_main
	cmp #'+'
	bne !skip+
	// compute table index
	lda #-5
	ldx sub_row
!:
	clc
	adc #5
	dex
	bpl !-
	clc
	adc sub_col
	// store table index
	sta scratch_main + 1
	// update investment
	tax
	lda investment_table, x
	ldx sub_col
	clc
	adc tbl_sub_cost, x
	bvs !+
	// store investment

	.if (false) {
	sta screen_subsidies
	ldx #WHITE
	stx colram
	}

	ldx scratch_main + 1
	sta investment_table, x

	jsr write_investments
    jsr update_expenditure
!:

!skip:
	cmp #'-'
	bne !skip+
	// compute table index
	lda #-5
	ldx sub_row
!:
	clc
	adc #5
	dex
	bpl !-
	clc
	adc sub_col
	// store table index
	sta scratch_main + 1
	// update investment
	tax
	lda investment_table, x
	ldx sub_col
	sec
	sbc tbl_sub_cost, x
	bpl !+
	// underflow, store 0
	lda #0
	// store investment

!:
	ldx scratch_main + 1
	sta investment_table, x

	.if (false) {
	sta screen_subsidies
	ldx #WHITE
	stx colram
	}

	jsr write_investments
    jsr update_expenditure
!skip:
	rts

update_hearts:
	lda itb + 0 * 5 + 4
	lsr; lsr; lsr; lsr
	tax
	lda tbl_hearts_col, x
	sta level1_color_data + coordToAddr(22, 5)
	lda itb + 1 * 5 + 4
	lsr; lsr; lsr; lsr
	tax
	lda tbl_hearts_col, x
	sta level1_color_data + coordToAddr(16, 20)
	lda itb + 2 * 5 + 4
	lsr; lsr; lsr; lsr
	tax
	lda tbl_hearts_col, x
	sta level1_color_data + coordToAddr(38, 8)
	lda itb + 3 * 5 + 4
	lsr; lsr; lsr; lsr
	tax
	lda tbl_hearts_col, x
	sta level1_color_data + coordToAddr(2, 8)

	lda window
	bne !+
	lda itb + 0 * 5 + 4
	lsr; lsr; lsr; lsr
	tax
	lda tbl_hearts_col, x
	sta colram + coordToAddr(22, 5)
	lda itb + 1 * 5 + 4
	lsr; lsr; lsr; lsr
	tax
	lda tbl_hearts_col, x
	sta colram + coordToAddr(16, 20)
	lda itb + 2 * 5 + 4
	lsr; lsr; lsr; lsr
	tax
	lda tbl_hearts_col, x
	sta colram + coordToAddr(38, 8)
	lda itb + 3 * 5 + 4
	lsr; lsr; lsr; lsr
	tax
	lda tbl_hearts_col, x
	sta colram + coordToAddr(2, 8)
!:
	rts

tbl_hearts_col:
	.byte BLACK, BLACK, RED, RED
	.byte RED, ORANGE, ORANGE, ORANGE
	.byte ORANGE, YELLOW, YELLOW, YELLOW
	.byte YELLOW, LIGHT_GREEN, LIGHT_GREEN, LIGHT_GREEN

tbl_sub_cost:
	.byte 5, 5, 5, 5, 20

sub_column_col:
	.for (var i=0; i<5; i++) {
	.byte <colram + coordToAddr(10 + 6 * i, 0)
	}

sub_row_col_lo:
	.for (var i=0; i<4; i++) {
	.byte <colram + coordToAddr(0, 3 + 3 * i)
	}

sub_row_col_hi:
	.for (var i=0; i<4; i++) {
	.byte >colram + coordToAddr(0, 3 + 3 * i)
	}

.pc = * "Impact calculation code"
#import "impact.asm"

.pc = * "Hex string data"
hexstring:
	.encoding "screencode_mixed"
	.text "0123456789abcdef"


.pc = $8000 "data barrier"
