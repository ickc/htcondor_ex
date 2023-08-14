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
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

extern char **environ;

int main(int argc, char **argv) {
  char **s = environ;
  FILE *fptr;

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

  // read hostname
  char hostname[1024];
  hostname[1023] = '\0';  // ensure null-termination

  // Get the hostname
  if (gethostname(hostname, sizeof(hostname) - 1) != 0) {
    perror("gethostname");
    return 1;
  }

  // Pointer to hold the starting position of the desired substring
  char *hostname_stem = hostname;

  // Find the first dot
  char *dot_position = strchr(hostname, '.');
  if (dot_position) {
    // Null-terminate the string at the dot position to get the desired
    // substring
    *dot_position = '\0';
  }

  // read _CONDOR_SLOT from env var
  char *temp = getenv("_CONDOR_SLOT");
  char *slot = temp ? temp : "";
  char filename[256];
  snprintf(filename, sizeof(filename), "%s_%s_%d.csv", hostname_stem, slot,
           world_rank);
  fptr = fopen(filename, "w");

  // Print off a hello world message
  fprintf(fptr, "%s,%d,%d,%d,%ld\n", processor_name, world_rank, world_size,
          cpu, number_of_processors);
  fclose(fptr);

  snprintf(filename, sizeof(filename), "%s_%s_%d.txt", hostname_stem, slot,
           world_rank);
  fptr = fopen(filename, "w");
  for (; *s; s++) {
    fprintf(fptr, "%s\n", *s);
  }
  fclose(fptr);

  // Finalize the MPI environment. No more MPI calls can be made after this
  MPI_Finalize();
}
