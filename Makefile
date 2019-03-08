CRYSTAL_BIN ?= $(shell which crystal)
SHARDS_BIN  ?= $(shell which shards)
FINCHER_BIN ?= $(shell which fincher)
PREFIX      ?= /usr/local
RELEASE     ?=
STATIC      ?=
SOURCES      = src/*.cr src/**/*.cr

override CRFLAGS += $(if $(RELEASE),--release ,--debug )$(if $(STATIC),--static )$(if $(LDFLAGS),--link-flags="$(LDFLAGS)" )

.PHONY: all
all: bin/hcl_parse_test

bin/hcl_parse_test: $(SOURCES)
	$(CRYSTAL_BIN) build -o bin/hcl_parse_test src/hcl_parse_test.cr

.PHONY: deps
deps:
	$(SHARDS_BIN) check || $(SHARDS_BIN) install

.PHONY: clean
clean:
	rm -rf ./dist

.PHONY: test
test: deps $(SOURCES)
	$(CRYSTAL_BIN) spec

.PHONY: spec
spec: test
