#importonce


// global screen adresses
.var font = $d000

.var memsetup_mask = %00001100

.var vic = 2 * $4000
// pointers to game screens, must be multiple of $0400
.var screen_main      = vic + 0 * $0400
.var screen_subsidies = vic + 1 * $0400
.var screen_log       = vic + 2 * $0400
.var screen_options   = vic + 3 * $0400

