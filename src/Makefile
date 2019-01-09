.PHONY: default clean

default: game.d64
game.d64: start.prg europe.prg
	c1541 -format iaodrip,id d64 game.d64 -write start.prg -write europe.prg
start.prg: top.prg start.asm
	kickass start.asm
top.prg: top.asm
	kickass top.asm
europe.prg: europe.asm
	kickass europe.asm

clean:
	rm -f *.sym *.prg
