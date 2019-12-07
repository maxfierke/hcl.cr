CRYSTAL_BIN ?= $(shell which crystal)
SHARDS_BIN  ?= $(shell which shards)
FINCHER_BIN ?= $(shell which fincher)
PREFIX      ?= /usr/local
RELEASE     ?=
STATIC      ?=
SOURCES      = src/*.cr src/**/*.cr

override CRFLAGS += --error-on-warnings $(if $(RELEASE),--release ,--debug --error-trace )$(if $(STATIC),--static )$(if $(LDFLAGS),--link-flags="$(LDFLAGS)" )

.PHONY: all
all: parse-trace

bin/hcl_parse_test: $(SOURCES)
	mkdir -p bin
	$(CRYSTAL_BIN) build $(CRFLAGS) -o bin/hcl_parse_test src/hcl_parse_test.cr

.PHONY: parse-trace
parse-trace: bin/hcl_parse_test
	bin/hcl_parse_test > trace.txt

.PHONY: deps
deps:
	$(SHARDS_BIN) check || $(SHARDS_BIN) install

.PHONY: clean
clean:
	rm -rf ./bin/*
	rm -rf ./dist

.PHONY: test
test: deps $(SOURCES)
	$(CRYSTAL_BIN) spec $(CRFLAGS)

.PHONY: spec
spec: test
