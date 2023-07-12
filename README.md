# htcondor_ex

Some examples to run jobs using HTCondor. It is mostly generic, but it is tested on [the Blackett Computing Facility – at the University of Manchester](https://www.blackett.manchester.ac.uk/) with HTCondor 9.0.17.

# Examples

Under the directory `examples/`, you will find subdirectories of examples.

- Conventions

    - Makefiles: Inside each subdirectory, there's at least 2 make targets, `clean` and `submit`. `make submit` would submit the job, and `make clean` would cleanup the outputs from a job. Study the `submit` target will let you know which file is the job configuration file.

    - Job configuration files: Most job configuration files here are `.ini` for syntax parser, and some are of different extensions to preserve the original code after copy & paste.

- Compilation: binaries are put inside `bin/`
    - Pre-compiled binaries: `make download` and it will download precompiled binaries compiled using `module load mpi/openmpi3-x86_64`.
    - To compile it yourself, the only way to do it as of writing is to request an interactive node first, inside that, run `module load mpi/openmpi3-x86_64` then `make`. How you transfer it back to the login node is up to you. If you want to use rsync, setup your ssh keys beforehand.
- Wrapper script: Running MPI via HTCondor requires a wrapper script.
    - `openmpiscript`: HTCondor provided wrappers for OpenMPI and MPICH. The wrapper for OpenMPI, `openmpiscript`, does not work out of the box. A modified version is provided at `src/`.
    - `cbatch_openmpi.sh`: a refactored version of `openmpiscript` to provide user more control over the environment and the mpirun command to use. This is more similar to `sbatch` from SLURM for example.
    
        - usage: `cbatch_openmpi.sh <env.sh> <mpirun.sh>`
        - the `<env.sh>` is a script that setup the environment, including OpenMPI.
        
            Example:
            
            ```sh
            module load mpi/openmpi3-x86_64
            ```

        - the `<mpirun.sh>` is a script that runs mpirun with the desired arguments,
        - this script can either setup the host on their own, or use the 2 convenience functions provided:
            - `set_OMPI_HOST_one_slot_per_condor_proc` setup one slot per condor process, useful for hybrid-MPI
            - `set_OMPI_HOST_one_slot_per_CPU` setup one slot per CPU
        
            Example:

            ```sh
            set_OMPI_HOST_one_slot_per_condor_proc
            mpirun -host "$OMPI_HOST" ...
            ```

Descriptions:

`eg01` and `eg02`
: from [Users’ Quick Start Guide — HTCondor Manual 10.6.0 documentation](https://htcondor.readthedocs.io/en/latest/users-manual/quick-start-guide.html).

`interactive`
: a minimal example on submitting interactive job. Note that from HTCondor documentation,

    > The interactive job is a vanilla universe job.

    And therefore you cannot submit interactive job in the parallel universe (i.e. multi-nodes jobs) for example.

`parallel` and `parallel-cpu`
: minimal examples to submit jobs to the parallel universe, modified from the HTCondor manual.

`mpi-hello-world-vanilla`
: Running MPI executables in vanilla universe. This is simple to do.

`mpi-hello-world`
: Running MPI executables in parallel universe. Note the use of our own `openmpiscript` here.

`cbatch-*`
: Variants of MPI jobs that uses our own `cbatch_openmpi.sh` instead of `openmpiscript`.

`debug*`
: These are various jobs to test the system. Feel free to study and use them.
