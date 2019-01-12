#importonce

.const prg_index = $f7
.const prg_start = $f8


// Keyboard driver addresses

.var res = $d0          // Read key result
.var res_row = res+1    // Read row number
.var res_col = res+2    // Read column number
