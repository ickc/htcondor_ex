#!/bin/bash -l

# helpers ##############################################################

COLUMNS=72

print_double_line() {
	eval printf %.0s= '{1..'"${COLUMNS}"\}
	echo
}

print_line() {
	eval printf %.0s- '{1..'"${COLUMNS}"\}
	echo
}

########################################################################

print_double_line
echo "HTCondor config summary:"
print_line
condor_config_val -summary

print_double_line
echo "Current environment:"
print_line
env

print_double_line
echo "Unpacking environment..."
tar -xzf pmpm-20230718-Linux-x86_64-OpenMPI-ucx.tar.gz -C /tmp
. /tmp/pmpm-20230718/bin/activate /tmp/pmpm-20230718
print_line
echo "Environment is available at:"
which python

print_double_line
echo "module path:"
which mpirun

# print_double_line
echo "Running TOAST tests..."
mpirun -n 8 python -c "import toast.tests; toast.tests.run()"

# print_double_line
echo "Running TOAST benchmarks..."
mpirun -n 8 toast_benchmark.py
