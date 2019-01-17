#importonce

/*
Zeropage constants sorted in address ascending order
Code: methos, flevosap, theezakje
*/

// global status flags
.const stat_flg = $0d

// methos' stuff:

.const lfsr4 = $07 // alias for lfsr4_state
.const lfsr4_state = $07
.const lfsr4_bit = $08

// general game stuff
.const window = $09
// joystick driver
.const joy2 = $0a
.const joy2_dir = $0b
.const joy2_dir_old = $0c
// NOTE 2 bytes long
// NOTE only irqs may use this!
.const jmp_buf = $0d
.const music_mute = $0f
// NOTE 2 bytes long
.const gameover_timer = $10
.const hide_arrow = $12
.const has_top_loader = $13

// copy of previous value
.const disaster_chr = $14
.const disaster_col = $15

// more game stuff

// NOTE 2 bytes long
.const disaster_timer = $ce

// flevosap's and theezakje's stuff:

// HEx to decimal chars conversion
.const dec_char = $d0
.const dec_val = $d5
.const c_h_hi = $da
.const c_h_lo = $db

// Keyboard driver addresses
.const key_res = $dc          // Read key result
.const key_row = key_res+1    // Read row number
.const key_col = key_res+2    // Read column number

// methos' stuff:

// top loader
.const prg_index = $f7
.const prg_start = $f8


// date stuff
.const date_month = $0e
.const date_year = $0f
.const date_last = $10

// investment stuff
.const itb = $70
