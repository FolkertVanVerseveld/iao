// src: http://codebase64.org/doku.php?id=base:threads_on_the_6502
:BasicUpstart2(start)

.var vic = $0000
.var screen = vic + $0400

.var num_threads = 2
.var thread_num = $fd

start:
	sei
	lda #<ctx_swap
	sta $0314
	lda #>ctx_swap
	sta $0315

	ldx #0
	stx thread_num

	tsx
	txa
	tay
	sec
	sbc #$20
	tax
	txs

	lda #>thread2
	pha
	lda #<thread2
	pha
	lda #0
	pha
	pha
	pha
	pha

	tsx
	txa
	sta thread_data + 1

	tya
	tax
	txs

	cli
	jmp thread1

ctx_swap:
	ldy thread_num
	tsx
	txa
	sta thread_data, y

	iny
	cpy #num_threads
	bne !+
	ldy #0
!:
	sty thread_num

	lda thread_data, y
	tax
	txs

	jmp $ea31

thread1:
	inc $d020
	ldy #$01
	jsr wait2
	jmp thread1

thread2:
	lda #<msg1
	ldy #>msg1
	jsr $ab1e
	ldy #0
	jsr wait2
	jmp thread2

wait2:
!:
	ldx #0
	dex
	bne *-1
	dey
	bne !-
	rts

msg1:
	.encoding "petscii_upper"
	.text "HELLO, HERE IS THREAD 2!"
	.byte 13, 0

thread_data:
