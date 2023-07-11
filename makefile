SHELL := /usr/bin/env bash
MPICC ?= mpicc

C_SRC = $(wildcard src/*.c)
C_EXE = $(patsubst src/%.c,bin/%,$(C_SRC))

.PHONY: all
all: $(C_EXE)

bin/%: src/%.c
	@mkdir -p $(@D)
	${MPICC} -o $@ $<

.PHONY: clean
clean:
	find examples -mindepth 1 -maxdepth 1 -type d -exec make -C {} clean \;

print-%:
    $(info $* = $($*))
