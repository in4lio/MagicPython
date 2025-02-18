.PHONY: all ci-test test release devenv publish install

PACK_VER=$(shell cat package.json | grep -e '^[[:space:]]*"version":' | sed -e 's/[[:space:]]*"version":[[:space:]]*"\(.*\)",/\1/')

all: devenv release

ci-test: release
#	Run tests
	./node_modules/.bin/syntaxdev test --tests test/**/*.py --syntax grammars/src/MagicPython.syntax.yaml
	./node_modules/.bin/syntaxdev test --tests test/**/*.re --syntax grammars/src/MagicRegExp.syntax.yaml

# 	Check if the version specified in "package.json" matches the latest git tag
	@if [ \
		$(PACK_VER) \
		!= \
		`git describe --tags --abbrev=0 | sed -e 's/v\([[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\).*/\1/'` \
	] ; \

update-test:
#	Run tests and overwrite the output
	./node_modules/.bin/syntaxdev test --tests test/**/*.py --syntax grammars/src/MagicPython.syntax.yaml --overwrite-tests
	./node_modules/.bin/syntaxdev test --tests test/**/*.re --syntax grammars/src/MagicRegExp.syntax.yaml --overwrite-tests

test: ci-test
	atom -t test/atom-spec

devenv:
	npm install --include=dev
	npm install -g vsce

release:
	./node_modules/.bin/syntaxdev build-plist --in grammars/src/MagicPython.syntax.yaml --out grammars/MagicPython.tmLanguage
	./node_modules/.bin/syntaxdev build-plist --in grammars/src/MagicRegExp.syntax.yaml --out grammars/MagicRegExp.tmLanguage

	./node_modules/.bin/syntaxdev build-cson --in grammars/src/MagicPython.syntax.yaml --out grammars/MagicPython.cson
	./node_modules/.bin/syntaxdev build-cson --in grammars/src/MagicRegExp.syntax.yaml --out grammars/MagicRegExp.cson

	./node_modules/.bin/syntaxdev scopes --syntax grammars/src/MagicPython.syntax.yaml > misc/scopes

	./node_modules/.bin/syntaxdev atom-spec --package-name MagicPython --tests test/**/*.py --syntax grammars/src/MagicPython.syntax.yaml --out test/atom-spec/python-spec.js
	./node_modules/.bin/syntaxdev atom-spec --package-name MagicPython --tests test/**/*.re --syntax grammars/src/MagicRegExp.syntax.yaml --out test/atom-spec/python-re-spec.js

install:
	vsce package
	code --install-extension MagicPython-$(PACK_VER).vsix

publish: test
	apm publish patch
	rm -rf ./node_modules/syntaxdev
	vsce publish
