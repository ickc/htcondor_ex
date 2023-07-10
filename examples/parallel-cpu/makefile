submit:
	condor_submit parallel-cpu.ini

init:
	for i in {0..1}; do touch infile.$$i; done

clean:
	rm -f logfile infile.* outfile.* errfile.*
