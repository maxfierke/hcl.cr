CRYSTAL ?= $(shell which crystal)
SHARDS  ?= $(shell which shards)
GOPATH  ?= $(HOME)/go
PREFIX  ?= /usr/local
RELEASE ?=
STATIC  ?=
SOURCES  = src/*.cr src/hcl/*.cr src/hcl/**/*.cr src/hcldec/*.cr src/hcldec/**/*.cr
SPECSUITE         ?= $(GOPATH)/bin/hclspecsuite
SPECSUITE_TESTS   ?=
SPECSUITE_VERSION ?= v2.15.0

override CRFLAGS += --error-on-warnings $(if $(RELEASE),--release ,--debug --error-trace )$(if $(STATIC),--static )$(if $(LDFLAGS),--link-flags="$(LDFLAGS)" )

.PHONY: all
all: deps bin/hcl_parse_test bin/hcldec

bin/hcl_parse_test: $(SOURCES)
	mkdir -p bin
	$(CRYSTAL) build $(CRFLAGS) -o bin/hcl_parse_test src/hcl_parse_test.cr

bin/hcldec: $(SOURCES)
	mkdir -p bin
	$(CRYSTAL) build $(CRFLAGS) -o bin/hcldec src/hcldec.cr

.PHONY: parse-trace
parse-trace: bin/hcl_parse_test
	bin/hcl_parse_test > trace.txt

.PHONY: specsuite
specsuite: bin/hcldec
	@if [ ! -f "$(SPECSUITE)" ]; then \
		go install github.com/hashicorp/hcl/v2/cmd/hclspecsuite@$(SPECSUITE_VERSION); \
	fi;
	@if [ ! -z "$(SPECSUITE_TESTS)" ] && [ -d "$(SPECSUITE_TESTS)" ]; then \
		$(SPECSUITE) $(SPECSUITE_TESTS) bin/hcldec; \
	else \
		echo "SPECSUITE_TESTS was empty/does not point to a directory. Please define this as the root of the HCL spec suite tests you want to run."; \
	fi;

.PHONY: deps
deps:
	$(SHARDS) check || $(SHARDS) install

.PHONY: format
format:
	$(CRYSTAL) tool format

.PHONY: clean
clean:
	rm -rf ./bin/*
	rm -rf ./dist

.PHONY: test
test: deps $(SOURCES)
	$(CRYSTAL) tool format --check
	$(CRYSTAL) spec $(CRFLAGS)

.PHONY: spec
spec: test
