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
	git tag -a $(cat VERSION) -m "Version $(cat VERSION)"
	git push origin $(cat VERSION)
upload:
	tar -czf bin.tar.gz bin/
	gh release upload $(cat VERSION) bin.tar.gz

download:
	mkdir -p bin
	# mpi_hello_world
	cd bin; wget https://github.com/ickc/mpi-hello-world/releases/download/v0.1.0/mpi_hello_world-openmpi_3.1.3.gz && gzip -d mpi_hello_world-openmpi_3.1.3.gz && chmod +x mpi_hello_world-openmpi_3.1.3 && mv mpi_hello_world-openmpi_3.1.3 mpi_hello_world
	# mpi_info
	cd bin; wget https://github.com/ickc/htcondor_ex/releases/download/v0.2.0/mpi_info && chmod +x mpi_info

clean:
	find examples -mindepth 1 -maxdepth 1 -type d -exec $(MAKE) -C {} clean \;

Clean: clean
	rm -rf bin

print-%:
	$(info $* = $($*))
