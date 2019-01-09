.PHONY: default clean

default: game.d64
game.d64: start.asm
	kickass start.asm
	c1541 -format iaodrip,id d64 game.d64 -write start.prg
clean:
	rm -f *.sym *.prg
