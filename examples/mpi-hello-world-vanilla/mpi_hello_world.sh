#!/usr/bin/bash -l

module load mpi/openmpi3-x86_64

mpirun -n 8 ./mpi_hello_world
