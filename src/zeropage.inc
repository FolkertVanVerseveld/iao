#importonce

/*
Zeropage constants
Code: methos, flevosap, theezakje
*/

// top loader
.const prg_index = $f7
.const prg_start = $f8

// general game stuff
.const window = $09

.const joy2 = $0a
.const joy2_dir = $0b

.const jmp_buf = $0c

// HEx to decimal chars conversion
.var dec_char = $d0
.var dec_val = $d5
.var c_h_hi = $da
.var c_h_lo = $db

// Keyboard driver addresses
.var res = $dc          // Read key result
.var res_row = res+1    // Read row number
.var res_col = res+2    // Read column number
