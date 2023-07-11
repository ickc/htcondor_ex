#!/usr/bin/bash -l

# this modifies from
# https://github.com/htcondor/htcondor/blob/main/src/condor_examples/openmpiscript

# configurations
USE_OPENMP=false

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
		rm -f "$HOSTFILE"

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

########################################################################################################################

module load mpi/openmpi3-x86_64
MPDIR=/usr/lib64/openmpi3

# Run the orted launcher (gets orted command from condor_chirp)
"$CONDOR_LIBEXEC/orted_launcher.sh" &
_orted_launcher_pid="$!"
if [[ $_CONDOR_PROCNO != 0 ]]; then
	# If not on node 0, wait for orted
	wait "$_orted_launcher_pid"
	exit "$?"
fi

## head node (node 0) setup
# get a unique hostfile name
HOSTFILE=hosts
while [[ -f "$_CONDOR_SCRATCH_DIR/$HOSTFILE" ]]; do
	HOSTFILE="x$HOSTFILE"
done
HOSTFILE="$_CONDOR_SCRATCH_DIR/$HOSTFILE"
# Build the hostfile
REQUEST_CPUS="$(condor_q -jobads "$_CONDOR_JOB_AD" -af RequestCpus)"
for node in $(seq 0 $((_CONDOR_NPROCS - 1))); do
	if "$USE_OPENMP"; then
		# OpenMP will do the threading on the execute node
		echo "$node slots=1" >> "$HOSTFILE"
	else
		# OpenMPI will do the threading on the execute node
		echo "$node slots=$REQUEST_CPUS" >> "$HOSTFILE"
	fi
done

# Make sure the executable is executable
EXECUTABLE="$1"
shift
chmod +x "$EXECUTABLE"

# Set MCA values for running on HTCondor
export OMPI_MCA_plm_rsh_agent="$CONDOR_LIBEXEC/get_orted_cmd.sh"            # use the helper script instead of ssh
export OMPI_MCA_plm_rsh_no_tree_spawn=1                                     # disable ssh tree spawn
export OMPI_MCA_orte_hetero_nodes=1                                         # do not assume same hardware on each node
export OMPI_MCA_orte_startup_timeout=120                                    # allow two minutes before failing
export OMPI_MCA_hwloc_base_binding_policy="none"                            # do not bind to cpu cores
export OMPI_MCA_btl_tcp_if_exclude="lo,$OPENMPI_EXCLUDE_NETWORK_INTERFACES" # exclude unused tcp network interfaces

# Run mpirun in the background and wait for it to exit
# shellcheck disable=SC2068
mpirun -v --prefix "$MPDIR" -hostfile "$HOSTFILE" "$EXECUTABLE" $@ &
_mpirun_pid="$!"
wait "$_mpirun_pid"
_mpirun_exit="$?"

## clean up
# Wait for orted to finish
wait "$_orted_launcher_pid"
rm -f "$HOSTFILE"
exit "$_mpirun_exit"
