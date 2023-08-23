#!/usr/bin/bash -l

#* usage: cbatch_mpich.sh <env.sh> <mpiexec.sh>
#* the <env.sh> is a script that setup the environment, including MPICH.
#* the <mpiexec.sh> is a script that runs mpiexec with the desired arguments.

# CONDOR_LIBEXEC=/usr/libexec/condor by default
CONDOR_LIBEXEC="$(condor_config_val libexec)"
SSHD_SH="$CONDOR_LIBEXEC/sshd.sh"
CONDOR_SSH="$CONDOR_LIBEXEC/condor_ssh"

# helpers ##############################################################

# Prints a line of '=' characters.
print_double_line() {
	eval printf %.0s= '{1..'"${COLUMNS:-72}"'}'
	echo
}

# Prints a line of '-' characters.
print_line() {
	eval printf %.0s- '{1..'"${COLUMNS:-72}"'}'
	echo
}

# wrapping mpiexec to baked in the ssh launcher
mpiexec() {
	print_double_line
	# shellcheck disable=SC2145
	echo "Running mpiexec -launcher ssh -launcher-exec $CONDOR_SSH $@"
	command mpiexec -launcher ssh -launcher-exec "$CONDOR_SSH" "$@"
}

########################################################################

print_double_line
echo "Starting $1"
# shellcheck disable=SC1090
. "$1"
env_exit_code=$?
if [[ $env_exit_code != 0 ]]; then
	echo "Error: $1 exited with code $env_exit_code" >&2
	exit $env_exit_code
fi
echo 'Environment loaded with the following mpiexec:'
if ! command -v mpiexec; then
	echo 'Error: mpiexec not found in PATH' >&2
	exit 1
fi

print_double_line
echo "Starting $SSHD_SH"
# shellcheck disable=SC1090
. "$SSHD_SH" "$_CONDOR_PROCNO" "$_CONDOR_NPROCS"

if [[ "$_CONDOR_PROCNO" == 0 ]]; then
	CONDOR_CONTACT_FILE="$_CONDOR_SCRATCH_DIR/contact"
	export HYDRA_HOST_FILE="$_CONDOR_SCRATCH_DIR/machines"
	# The second field in the contact file is the machine name
	# that condor_ssh knows how to use
	sort -n -k 1 <"$CONDOR_CONTACT_FILE" | awk '{print $2}' >"$HYDRA_HOST_FILE"

	print_double_line
	echo "Starting $2"
	# shellcheck disable=SC1090
	. "$2"
	mpi_exit_code=$?

	# cleanup MPICH
	sshd_cleanup
	rm -f "$HYDRA_HOST_FILE"
	exit $mpi_exit_code
# If not the head node, just sleep forever, to let the sshds run
else
	wait
	sshd_cleanup
	exit 0
fi
