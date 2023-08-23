CSV = $(shell find . -name '*.csv' \! -name header.csv \! -name mpi.csv | sort -V)

default: mpi.csv

mpi.csv: header.csv $(CSV)
	cat $^ > $@

submit:
	condor_submit mpi.ini

tail:
	tail -F mpi.log mpi-0.out mpi-0.err mpi-1.out mpi-1.err

clean:
	rm -f *.log *.out *.err *.txt
	find . -name '*.csv' \! -name 'header.csv' -delete
