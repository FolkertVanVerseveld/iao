:BasicUpstart2(start)

#import "local.inc"
#import "pseudo.lib"

.var vic = $0000
.var screen = vic + $0400

.var FA = $ba

// NOTE this must match krill's loader vectors
.var resident = $0200
.var loadraw = resident

.var resident_size = $01f5

.var drivecode = $4000
.var install = drivecode + $1390

.var org_api_size = org_api_end - org_api
.var org_drv_size = org_drv_end - org_drv

.var irq_line_top = $20

start:
	// dump values for debug purposes
	lda FA
	sta screen

	lda #<org_api_size
	sta screen + 1
	lda #>org_api_size
	sta screen + 2

	lda org_api
	sta screen + 3
	lda org_api + 1
	sta screen + 4

	lda #<org_drv_size
	sta screen + 5
	lda #>org_drv_size
	sta screen + 6

	lda org_drv
	sta screen + 7
	lda org_drv + 1
	sta screen + 8

	// check destination
	lda org_api
	cmp #<resident
	bne error
	lda org_api + 1
	cmp #>resident
	bne error

	lda org_drv
	cmp #<drivecode
	bne error
	lda org_drv + 1
	cmp #>drivecode
	bne error

	jsr relocate

	sec
	jsr install
	bcs error

.if (true) {
	sei
	lda #$35
	sta $01

	lda #<irq_top
	sta $fffe
	lda #>irq_top
	sta $ffff

	lda #<dummy
	sta $fffa
	sta $fffc
	lda #>dummy
	sta $fffb
	sta $fffd

	lda #%00011011		// Load screen control:
				// Vertical scroll    : 3
				// Screen height      : 25 rows
				// Screen             : ON
				// Mode               : TEXT
				// Extended background: OFF
	sta $d011       	// Set screen control

	lda #irq_line_top
	sta $d012

	lda #$01		// Enable mask
	sta $d01a		// IRQ interrupt ON

	lda #%01111111		// Load interrupt control CIA 1:
				// Timer A underflow : OFF
				// Timer B underflow : OFF
				// TOD               : OFF
				// Serial shift reg. : OFF
				// Pos. edge FLAG pin: OFF
	sta $dc0d		// Set interrupt control CIA 1
	sta $dd0d		// Set interrupt control CIA 2

	lda $dc0d		// Clear pending interrupts CIA 1
	lda $dd0d		// Clear pending interrupts CIA 2

	lda #$00
	sta $dc0e

	asl $d019

	cli

	jsr relocate2

	jmp *
}

	jmp *

error:
	inc $d020
	jmp error

relocate:
	ldx #0
!:
	.for (var i = 0; i < ($191c - 255) / 256 + 1; i++) {
		lda org_drv + i * $100 + 2, x
		sta drivecode + i * $100, x
	}
	inx
	beq !s+
	jmp !-
!s:
	rts

relocate2:
	ldx #0
!:
	.for (var i = 0; i < ($01f5 - 255) / 256 + 1; i++) {
		lda org_api + i * $100 + 2, x
		sta resident + i * $100, x
	}
	inx
	bne !-
	rts

irq_top:
	irq

	inc $d020
	ldx #8
	dex
	bne *-1
	dec $d020

	qri

dummy:
	rti

org_api:
.import binary "../tools/krill/loader/build/loader-c64.prg"
org_api_end:

org_drv:
.import binary "../tools/krill/loader/build/install-c64.prg"
org_drv_end:
