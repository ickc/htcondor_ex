SHELL := /usr/bin/env bash
MPICC ?= mpicc

C_SRC = $(wildcard src/*.c)
C_EXE = $(patsubst src/%.c,bin/%,$(C_SRC))

.PHONY: all
all: $(C_EXE)

bin/%: src/%.c
	@mkdir -p $(@D)
	${MPICC} -o $@ $<

.PHONY: format c-format clean
format: c-format
c-format:
	find src -name '*.c' -exec clang-format -i --style=Google {} +

clean:
	find examples -mindepth 1 -maxdepth 1 -type d -exec make -C {} clean \;

print-%:
    $(info $* = $($*))
