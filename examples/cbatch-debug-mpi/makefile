CSV = $(shell find . -name '*.csv' \! -name header.csv \! -name mpi.csv | sort -V)

default: mpi.csv

mpi.csv: header.csv $(CSV)
	cat $^ > $@

submit:
	condor_submit mpi.ini

clean:
	rm -f *.log *.out *.err *.txt
	find . -name '*.csv' \! -name 'header.csv' -delete

print-%:
	$(info $* = $($*))
