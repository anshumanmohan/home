HLJS_VERSION := 11.6.0
KATEX_VERSION := 0.16.0

# Build the site itself using Jekyll.
.PHONY: site
GENERATED := media/katex media/highlight.min.js
site: index.md $(GENERATED)
	jekyll build


# Cleaning.

.PHONY: clean cleanall
PRODUCTS := _site media/highlightjs media/katex \
	media/main.css _source/main.css
clean:
	rm -rf $(PRODUCTS)
cleanall:
	rm -rf $(PRODUCTS) _source/highlightjs node_modules
cleanbuild:
	rm -rf _site


# Deployment.

RSYNCARGS := --compress --recursive --checksum --itemize-changes \
	--delete -e ssh --timeout=30
DEST := cslinux:/people/als485/home
deploy: cleanbuild site
	rsync $(RSYNCARGS) _site/ $(DEST)


# Install dependencies.

# Dependencies from npm. TODO: This should be replaced with a package.json.
_source/katex:
	curl -L https://github.com/KaTeX/KaTeX/releases/download/v$(KATEX_VERSION)/katex.tar.gz -o _source/katex.tar.gz
	cd _source ; tar xf katex.tar.gz

# Publish client-side assets.
media/katex: _source/katex
	cp -r $< $@

# Clone and build Highlight.js to get custom languages.
_source/highlightjs:
	git clone --branch $(HLJS_VERSION) --depth 1 \
		https://github.com/isagalaev/highlight.js.git $@
_source/highlightjs/build: _source/highlightjs
	cd $< ; npm install
	cd $< ; node tools/build.js python c cpp bash typescript
media/highlight.min.js: _source/highlightjs/build
	cp $</highlight.min.js $@

# A phony target for installing all the dependencies.
.PHONY: setup
setup: $(GENERATED)
