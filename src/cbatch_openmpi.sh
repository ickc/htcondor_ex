#!/usr/bin/bash -l

# this modifies from
# https://github.com/htcondor/htcondor/blob/main/src/condor_examples/openmpiscript

#* usage: cbatch_openmpi.sh <env.sh> <mpirun.sh>
#* this is refactor from openmpiscript to provide user more control over the environment and the mpirun command to use.
#* the <env.sh> is a script that setup the environment, including OpenMPI. e.g. contains `module load mpi/openmpi3-x86_64`
#* the <mpirun.sh> is a script that runs mpirun with the desired arguments,
#* this script can either setup the host on their own, or use the 2 convenience functions provided below:
#* set_OMPI_HOST_one_slot_per_condor_proc setup one slot per condor process, useful for hybrid-MPI
#* set_OMPI_HOST_one_slot_per_CPU setup one slot per CPU
#* then in the <mpirun.sh>, use `mpirun -host "$OMPI_HOST" ...`

#* other functionally different changes from openmpiscript:
#* remove redundant checks such as EXINT, _USE_SCRATCH
#* remove MPDIR and --prefix=... in mpirun: module load is sufficient
#* instead of generating a HOSTFILE and use mpirun --hostfile $HOSTFILE ..., use mpirun --host $OMPI_HOST ... instead.
#* set OMPI_MCA_btl_base_warn_component_unused=0 to suppress warning about unused network interfaces
#* remove chmod on executable, the user should have done this already
#* refactor the usage of the script, rather than openmpiscript MPI_EXECUTABLE ARGS ..., use cbatch_openmpi.sh <env.sh> <mpirun.sh>. See above for documentation.

# CONDOR_LIBEXEC=/usr/libexec/condor by default
CONDOR_LIBEXEC="$(condor_config_val libexec)"
OPENMPI_EXCLUDE_NETWORK_INTERFACES="$(condor_config_val OPENMPI_EXCLUDE_NETWORK_INTERFACES)"

# cleanup function #####################################################################################################

# will be set after orted_launcher.sh has started
_orted_launcher_pid=0
# will be set after mpirun has started
_mpirun_pid=0
force_cleanup() {
	# Cleanup orted_launcher.sh
	# Forward SIGTERM to the orted launcher
	if [[ $_orted_launcher_pid != 0 ]]; then
		kill -s SIGTERM "$_orted_launcher_pid"
	fi

	# Cleanup mpirun
	if [[ $_CONDOR_PROCNO != 0 && $_mpirun_pid != 0 ]]; then
		"$CONDOR_LIBEXEC/condor_chirp" ulog "Node $_CONDOR_PROCNO caught SIGTERM, cleaning up mpirun"

		# Send SIGTERM to mpirun and the orted launcher
		kill -s SIGTERM "$_mpirun_pid"

		# Give mpirun 30 seconds to terminate nicely
		for _ in {1..30}; do
			kill -0 "$_mpirun_pid" 2> /dev/null # returns 0 if running
			_mpirun_killed=$?
			if [[ $_mpirun_killed != 0 ]]; then
				break
			fi
			sleep 1
		done

		# If mpirun is still running, send SIGKILL
		if [[ $_mpirun_killed != 0 ]]; then
			"$CONDOR_LIBEXEC/condor_chirp" ulog "mpirun hung on Node ${_CONDOR_PROCNO}, sending SIGKILL!"
			kill -s SIGKILL "$_mpirun_pid"
		fi
	fi
	exit 1
}
trap force_cleanup SIGTERM

# functions for generating host ########################################################################################

# These functions set the OMPI_HOST environment variable for the consumption of mpirun --host ...
# set_OMPI_HOST_one_slot_per_condor_proc setup one slot per condor process, useful for hybrid-MPI
# set_OMPI_HOST_one_slot_per_CPU setup one slot per CPU
# usage:
# set_OMPI_HOST_one_slot_per_condor_proc
# mpirun --host "$OMPI_HOST" ...
# while seq uses floating point, it should be nowhere near the limit we'd see an error here

set_OMPI_HOST_one_slot_per_condor_proc() {
	# This is the no. of logical CPUs requested
	REQUEST_CPUS="$(condor_q -jobads "$_CONDOR_JOB_AD" -af RequestCpus)"
	echo "$REQUEST_CPUS logical CPUs requested" >&2
	# devide this by 2 to get the no. of physical CPUs
	REQUEST_CPUS="$((REQUEST_CPUS / 2))"
	echo "$REQUEST_CPUS physical CPUs requested" >&2

	export OPENBLAS_NUM_THREADS="$REQUEST_CPUS"
	export JULIA_NUM_THREADS="$REQUEST_CPUS"
	export TF_NUM_THREADS="$REQUEST_CPUS"
	export MKL_NUM_THREADS="$REQUEST_CPUS"
	export NUMEXPR_NUM_THREADS="$REQUEST_CPUS"
	export OMP_NUM_THREADS="$REQUEST_CPUS"
	OMPI_HOST="$(seq -s ',' 0 $((_CONDOR_NPROCS - 1)))"
	echo "Setting up $_CONDOR_NPROCS MPI processes where each has *_NUM_THREADS set to $REQUEST_CPUS" >&2
}
export -f set_OMPI_HOST_one_slot_per_condor_proc

set_OMPI_HOST_one_slot_per_CPU() {
	# This is the no. of logical CPUs requested
	REQUEST_CPUS="$(condor_q -jobads "$_CONDOR_JOB_AD" -af RequestCpus)"
	echo "$REQUEST_CPUS logical CPUs requested" >&2
	# devide this by 2 to get the no. of physical CPUs
	REQUEST_CPUS="$((REQUEST_CPUS / 2))"
	echo "$REQUEST_CPUS physical CPUs requested" >&2

	export OPENBLAS_NUM_THREADS=1
	export JULIA_NUM_THREADS=1
	export TF_NUM_THREADS=1
	export MKL_NUM_THREADS=1
	export NUMEXPR_NUM_THREADS=1
	export OMP_NUM_THREADS=1
	# shellcheck disable=SC2034
	OMPI_HOST="$(seq -s ',' -f "%.0f:$REQUEST_CPUS" 0 $((_CONDOR_NPROCS - 1)))"
	echo "With $_CONDOR_NPROCS HTCondor processes where each has $REQUEST_CPUS physical cores, setting up $((_CONDOR_NPROCS * REQUEST_CPUS)) MPI processes where each has *_NUM_THREADS set to 1" >&2
}
export -f set_OMPI_HOST_one_slot_per_CPU

########################################################################################################################

PATH=".:$PATH"
export PATH
# shellcheck disable=SC1090
. "$1"

# Run the orted launcher (gets orted command from condor_chirp)
"$CONDOR_LIBEXEC/orted_launcher.sh" &
_orted_launcher_pid="$!"
if [[ $_CONDOR_PROCNO != 0 ]]; then
	# If not on node 0, wait for orted
	wait "$_orted_launcher_pid"
	exit "$?"
fi

# Set MCA values for running on HTCondor
export OMPI_MCA_plm_rsh_agent="$CONDOR_LIBEXEC/get_orted_cmd.sh"            # use the helper script instead of ssh
export OMPI_MCA_plm_rsh_no_tree_spawn=1                                     # disable ssh tree spawn
export OMPI_MCA_orte_hetero_nodes=1                                         # do not assume same hardware on each node
export OMPI_MCA_orte_startup_timeout=120                                    # allow two minutes before failing
export OMPI_MCA_hwloc_base_binding_policy="none"                            # do not bind to cpu cores
export OMPI_MCA_btl_tcp_if_exclude="lo,$OPENMPI_EXCLUDE_NETWORK_INTERFACES" # exclude unused tcp network interfaces
export OMPI_MCA_btl_base_warn_component_unused=0                            # do not warn about unused network interfaces

# Run mpirun in the background and wait for it to exit
"$2" &
_mpirun_pid="$!"
wait "$_mpirun_pid"
_mpirun_exit="$?"

## clean up
# Wait for orted to finish
wait "$_orted_launcher_pid"
exit "$_mpirun_exit"
