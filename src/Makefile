.PHONY: default clean

default: game.d64
game.d64: start.prg menu.prg game.prg rol.prg pager.prg bars.prg
	c1541 -format iaodrip,id d64 game.d64 -write start.prg -write menu.prg -write game.prg -write rol.prg credits.prg -write pager.prg tutorial.prg -write bars.prg win.prg
start.prg: top.prg zeropage.inc pseudo.lib loader.inc kernal.inc basic.inc start.asm
	kickass start.asm
top.prg: zeropage.inc pseudo.lib loader.inc top.asm
	kickass top.asm
menu.prg: zeropage.inc loader.inc pseudo.lib menu.asm rol.asm pager.asm bars.asm
	kickass menu.asm
game.prg: zeropage.inc loader.inc pseudo.lib joy.inc io.inc kernal.inc game.asm month_timer.asm money.asm impact.asm bars.asm
	kickass game.asm
rol.prg: rol.asm
	kickass rol.asm
pager.prg: pager.asm
	kickass pager.asm
bars.prg: bars.asm
	kickass bars.asm

clean:
	rm -f *.sym *.prg *.d64
