.PHONY: preview build deploy freeze clean

# The academic year being taught. Bump it (and site-url in _quarto.yml) when a new
# year starts: the previous year's folder on gh-pages is then never touched again.
AY ?= 2026-27

preview:        ## live reload while editing
	quarto preview

build:          ## render -> _site/
	quarto render

deploy: build   ## render locally, publish _site/ into the $(AY)/ folder of gh-pages
	bash scripts/publish.sh $(AY)

freeze:         ## at the end of a year: tag the source the year was taught from
	git tag -a aa-$(AY) -m "Bachelor QBM, A.Y. $(AY), as taught" && git push origin aa-$(AY)

clean:
	rm -rf _site .quarto
