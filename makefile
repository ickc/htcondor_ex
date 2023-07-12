SHELL = /bin/bash

MPICC ?= mpicc

C_SRC = $(wildcard src/*.c)
C_EXE = $(patsubst src/%.c,bin/%,$(C_SRC))

.PHONY: all
all: $(C_EXE)

bin/%: src/%.c
	@mkdir -p $(@D)
	$(MPICC) -o $@ $<

.PHONY: format c-format shell-format tag upload download clean
format: c-format shell-format
c-format:
	find src -name '*.c' -exec clang-format -i --style=Google {} +
shell-format:
	find . \( -name '*.sh' -o -name openmpiscript \) -exec shfmt --write --simplify --case-indent --space-redirects {} +

tag:
	git tag -m "Version $$(cat VERSION)" $$(cat VERSION)
	git push origin $$(cat VERSION)
upload:
	tar -czf bin.tar.gz bin/
	gh release create $$(cat VERSION) bin.tar.gz

download:
	wget -qO- 'https://github.com/ickc/htcondor_ex/releases/latest/download/bin.tar.gz' | tar -xzf -

clean:
	find examples -mindepth 1 -maxdepth 1 -type d -exec $(MAKE) -C {} clean \;

Clean: clean
	rm -rf bin

print-%:
	$(info $* = $($*))
