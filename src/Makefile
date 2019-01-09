.PHONY: default clean

default: game.d64
game.d64: start.prg
	c1541 -format iaodrip,id d64 game.d64 -write start.prg
start.prg: top.prg start.asm
	kickass start.asm
top.prg: top.asm
	kickass top.asm

clean:
	rm -f *.sym *.prg
