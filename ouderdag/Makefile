.PHONY: clean

GFX=\
	c64.jpg c64c.jpg mmap.png breadbin.jpg retro.png x.jpg

default: presentatie.pdf
presentatie.pdf: presentatie.tex $(GFX)
	pdflatex presentatie.tex

c64.jpg:
	wget -O c64.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Commodore-64-Computer-FL.jpg/1024px-Commodore-64-Computer-FL.jpg
c64c.jpg:
	wget -O c64c.jpg https://www.c64-wiki.com/images/6/6c/C64c.jpg
breadbin.jpg:
	wget -O breadbin.jpg https://user-images.githubusercontent.com/5989565/58247113-281c1080-7d59-11e9-8ef5-72cd0515a085.jpg
mmap.png:
	wget -O mmap.png https://user-images.githubusercontent.com/5989565/58247886-fc018f00-7d5a-11e9-89bc-ca665489f488.png
retro.png:
	wget -O retro.png https://user-images.githubusercontent.com/5989565/58247075-0e7ac900-7d59-11e9-8e73-f13306dcc2de.png
x.jpg:
	wget -O x.jpg https://user-images.githubusercontent.com/5989565/58247316-a24c9500-7d59-11e9-99b9-770b2add9b8b.jpg

clean:
	rm -f $(GFX) presentatie.pdf presentatie.aux presentatie.log presentatie.snm presentatie.nav presentatie.out presentatie.toc
