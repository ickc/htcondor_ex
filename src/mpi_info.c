// Author: Wes Kendall
// Copyright 2011 www.mpitutorial.com
// This code is provided freely with the tutorials on mpitutorial.com. Feel
// free to modify it for your own use. Any distribution of the code must
// either provide a link to www.mpitutorial.com or keep this header intact.
//
// An intro MPI hello world program that uses MPI_Init, MPI_Comm_size,
// MPI_Comm_rank, MPI_Finalize, and MPI_Get_processor_name.
//
#include <mpi.h>
#include <sched.h>
#include <stdio.h>
#include <unistd.h>

extern char **environ;

int main(int argc, char **argv) {
  char **s = environ;

  // Initialize the MPI environment. The two arguments to MPI Init are not
  // currently used by MPI implementations, but are there in case future
  // implementations might need the arguments.
  MPI_Init(&argc, &argv);

  // Get the number of processes
  int world_size;
  MPI_Comm_size(MPI_COMM_WORLD, &world_size);

  // Get the rank of the process
  int world_rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

  // Get the name of the processor
  char processor_name[MPI_MAX_PROCESSOR_NAME];
  int name_len;
  MPI_Get_processor_name(processor_name, &name_len);

  int cpu = sched_getcpu();

  long number_of_processors = sysconf(_SC_NPROCESSORS_ONLN);

  char filename[256];
  snprintf(filename, sizeof(filename), "%d.csv", world_rank);
  fptr = fopen(filename, "w");

  // Print off a hello world message
  fprintf(fptr, "%s,%d,%d,%d,%ld\n", processor_name, world_rank, world_size,
          cpu, number_of_processors);
  fclose(fptr);

  snprintf(filename, sizeof(filename), "%d.txt", world_rank);
  fptr = fopen(filename, "w");
  for (; *s; s++) {
    fprintf(fptr, "%s\n", *s);
  }
  fclose(fptr);

  // Finalize the MPI environment. No more MPI calls can be made after this
  MPI_Finalize();
}
