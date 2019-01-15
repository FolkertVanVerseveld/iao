.PHONY: default clean

default: game.d64
game.d64: start.prg menu.prg game.prg
	c1541 -format iaodrip,id d64 game.d64 -write start.prg -write menu.prg -write game.prg
start.prg: top.prg zeropage.inc pseudo.lib loader.inc kernal.inc basic.inc start.asm
	kickass start.asm
top.prg: zeropage.inc pseudo.lib loader.inc top.asm
	kickass top.asm
menu.prg: zeropage.inc loader.inc pseudo.lib menu.asm
	kickass menu.asm
game.prg: zeropage.inc loader.inc macros.inc pseudo.lib joy.inc io.inc kernal.inc game.asm
	kickass game.asm

clean:
	rm -f *.sym *.prg *.d64
