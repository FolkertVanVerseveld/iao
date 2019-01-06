# C64 Integratiedemo

Hierin staan alle details voor de demo en waar alle componenten aan moeten voldoen.

# Programmeerhandleidingen

Zowel de user's als programmer's guide kun je direct downloaden van [Folkerts c64 workshop](https://github.com/FolkertVanVerseveld/workshop/releases/download/v0.2/guides.zip).
Zie ook deze overzichten: [elk geheugenadres](http://sta.c64.org/cbm64mem.html), [screen codes](http://sta.c64.org/cbm64scr.html)

# Geheugenoverzicht

Zie ook [globaal overzicht](https://www.c64-wiki.com/wiki/Memory_Map):
![Global memory map](https://www.c64-wiki.com/images/5/51/Memory_Map.png)

Bij startup is dit het geheugenoverzicht:

Bereik (hex) | Doel
-------------|-----
0000-03FF    | KERNAL RAM
0200-03F5    | Loader
0400-07FF    | Screen
0800-CFFF    | Startprogramma
4000-591C    | Drive code (reclaimable)
D000-DFFF    | I/O Area
E000-FFFF    | KERNAL ROM

Algemeen overzicht gedurende de demo:

Bereik (hex) | Doel
-------------|-----
0000-00FF    | Fast small data
0100-01FF    | Stack
0200-03FF    | Loader
0400-CFFF    | Code + data
0400-07FF    | Default screen + sprites
1000-2800    | Music
2800-3FFF    | Custom font
D000-DFFF    | I/O Area
E000-FFFA    | Loader part, treat as ROM
FFFA-FFFF    | Hardware vectors

We moeten per onderdeel even kijken hoe we 0200-CFFF precies gaan opdelen. Krills loader is best goed en ondersteunt ook compressie dus we kunnen altijd nog kiezen of we compressie willen gebruiken. Met decrunch is het ongeveer 3 pages groot, zonder decrunch maar 1.
