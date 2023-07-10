#!/bin/bash -l

# helpers ##############################################################

COLUMNS=72

print_double_line () {
    eval printf %.0s= '{1..'"${COLUMNS}"\}
    echo
}

print_line () {
    eval printf %.0s- '{1..'"${COLUMNS}"\}
    echo
}

########################################################################

print_double_line
echo "Current environment:"
env

print_double_line
echo "Avaiable MPI:"
module avail mpi

print_double_line
echo "module path:"
module load mpi/openmpi3-x86_64
which mpicc
which mpirun
