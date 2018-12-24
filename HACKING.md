# Teampagina Commodore 64 demo

Hierin staan bronnen voor het maken van de integratiedemo.

# RUNnen van c64 programma's

* [Emulatie met VICE](http://vice-emu.sourceforge.net/)
* [Ultimate II+](http://www.1541ultimate.net/content/index.php)

# Code

* [Programmeerwiki](http://codebase64.org)
* [Wiki](https://www.c64-wiki.de/wiki/Hauptseite)
* [Folkerts stuff](http://vanverseveld.me/txt/c64.html)
* [Memory map](http://sta.c64.org/cbm64mem.html)
* [Screen codes](http://sta.c64.org/cbm64scr.html)

Folkert: laten we beginnen met een paar .prg's en ze op een disk zetten met loader als het allemaal een beetje werkt. Een cartridge zou ook kunnen, maar we moeten dan kijken of 16K genoeg is of we een bankswitchingmechanisme willen gebruiken.

## Memory map

Heel globaal geheugenoverzicht:

Bereik (hex) | Doel
-------------|-----
0000-A000    | RAM
A000-BFFF    | BASIC ROM of RAM
C000-CFFF    | RAM
D000-DFFF    | I/O
E000-FFFF    | KERNAL ROM of RAM

De KERNAL is het besturingssysteem van de C64. Met bankswitching kan bij de 'of' stukken gekozen worden.

# Gfx

Merk op dat CHAR ROM in banks 0 en 2 altijd door de VIC-II gezien wordt!!!

## Font

* [PETSCII editor](http://petscii.krissz.hu/)

We kunnen zowel het originele font gebruiken als een 2x2 char font. Een bitmap font lijkt me niet zo'n goed idee, want we moeten dan veel meer rekenwerk doen.

## Koala

* [Convertron3000](https://github.com/fieserWolF/convertron3000)

# Sfx

* [HVSC](https://hvsc.de)
* [Hoe werkt oldskool muziek](https://www.youtube.com/watch?v=q_3d1x2VPxk)

# Demoscene

* [Pouët](http://www.pouet.net/)
* [Commodore Scene Database](https://csdb.dk/)
