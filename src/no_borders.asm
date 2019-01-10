:BasicUpstart2(start)

.var vic = $0000
.var screen = vic + $0400

start:
         sei
         lda #$2
         sta $d020
         lda #$00
         sta $d021
         lda #<irq1
         sta $314
         lda #>irq1
         sta $315
         lda #$7f
         sta $dc0d
         lda #$1b
         sta $d011
         lda #$01
         sta $d01a
         cli
	 lda #(spr_star / 64 - vic)
	 sta screen + $3f8
	 lda #%1
	 sta $d015
	 lda #$20
	 sta $d000
	 sta $d001
         jmp *
irq1:    inc $d019
         lda #$00
         sta $d012
         lda #$00
         sta $d011
         lda #<irq2
         sta $314
         lda #>irq2
         sta $315
         jmp $ea7e
irq2:    inc $d019
         lda #$fa
         sta $d012
         lda #$1b //If you want to display a bitmap pic, use #$3b instead
         sta $d011
         lda #<irq1
         sta $314
         lda #>irq1
         sta $315
         jmp $ea7e

.align $40
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
