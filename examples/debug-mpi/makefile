default: mpi.csv

mpi.csv: header.csv 0.csv 1.csv 2.csv 3.csv 4.csv 5.csv 6.csv 7.csv
	cat $^ > $@

submit:
	condor_submit mpi.ini

clean:
	rm -f *.log *.out *.err *.txt
	find . -name '*.csv' \! -name 'header.csv' -delete
