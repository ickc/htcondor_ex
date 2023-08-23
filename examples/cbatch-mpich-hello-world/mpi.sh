#!/usr/bin/env bash

print_double_line
echo "Running MPI hello world..."
mpiexec -n 2 ./mpi_hello_world

print_double_line
echo "Running MPI info..."
mpiexec -n 2 ./mpi_info
