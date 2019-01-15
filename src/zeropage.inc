#importonce

/*
Zeropage constants sorted in address ascending order
Code: methos, flevosap, theezakje
*/

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
.var dec_char = $d0
.var dec_val = $d5
.var c_h_hi = $da
.var c_h_lo = $db

// Keyboard driver addresses
.var res = $dc          // Read key result
.var res_row = res+1    // Read row number
.var res_col = res+2    // Read column number

// methos' stuff:

// top loader
.const prg_index = $f7
.const prg_start = $f8
