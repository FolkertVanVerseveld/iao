#importonce

/*
Vectors and variables for Krill's loader API
Code: methos
*/

.var resident = $0200
.var loadraw = resident

.var resident_size = $01f5

.var drivecode = $5000
.var install = drivecode + $1390

// cld sei
.var top_magic = $78d8

.var top_loader_start = $e000
