# C64 Integratiedemo

Hierin staan alle details voor de demo en waar alle componenten aan moeten voldoen.

# Programmeerhandleidingen

Zowel de user's als programmer's guide kun je direct downloaden van [Folkerts c64 workshop](https://github.com/FolkertVanVerseveld/workshop/releases/download/v0.2/guides.zip).

# Geheugenoverzicht

Globaal overzicht:

Bereik (hex) | Doel
-------------|-----
0000-00FF    | Zero page + fast data
0100-01FF    | Stack
0200-03FF    | BASIC RAM (reclaimable)
D800-DBE7    | Color RAM
DBE8-DBFF    | RAM (let op, alleen de onderste nibble is bruikbaar!)
DC00-DDFF    | Complex Interface Adapters
DE00-DFFF    | I/O Area
E000-FFFF    | KERNAL ROM
FFFA-FFFF    | Hardware vectors

Bij startup is dit het geheugenoverzicht:

Bereik (hex) | Doel
-------------|-----
0000-07FF    | KERNAL RAM
0800-CFFF    | Startprogramma + loader
D000-DFFF    | I/O Area
E000-FFFF    | KERNAL ROM

Algemeen overzicht gedurende de demo:

Bereik (hex) | Doel
-------------|-----
0000-00FF    | Zero page + fast data
0100-01FF    | Stack
0200-CFFF    | Code + loader + data
D000-DFFF    | I/O Area
E000-FFFA    | Loader part, treat as ROM
FFFA-FFFF    | Hardware vectors

We moeten per onderdeel even kijken hoe we 0200-CFFF precies gaan opdelen. Krills loader is best goed en ondersteunt ook compressie dus we kunnen altijd nog kiezen of we compressie willen gebruiken.
