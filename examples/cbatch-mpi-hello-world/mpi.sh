#!/usr/bin/env bash

set_OMPI_HOST_one_slot_per_CPU
echo "Running mpirun with host configuration: $OMPI_HOST" >&2
# recall that the files are copied to the cwd
mpirun -v -host "$OMPI_HOST" ./mpi_hello_world
