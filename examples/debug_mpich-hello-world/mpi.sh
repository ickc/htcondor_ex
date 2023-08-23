#!/usr/bin/env bash

# helpers ##############################################################

COLUMNS=72

print_double_line() {
	eval printf %.0s= '{1..'"${COLUMNS}"\}
	echo
}

print_line() {
	eval printf %.0s- '{1..'"${COLUMNS}"\}
	echo
}

# env ##################################################################

print_double_line
echo "HTCondor config summary:"
print_line
condor_config_val -summary

print_double_line
echo "Current environment:"
print_line
env

print_double_line
echo "$(date) unarchive environment..."
tar -xzf pmpm-20230718-Linux-x86_64-MPICH.tar.gz -C /tmp

print_double_line
echo "$(date) activate environment..."
source /tmp/pmpm-20230718/bin/activate /tmp/pmpm-20230718
print_line
echo "Python is available at:"
which python
echo "mpiexec is available at:"
which mpiexec

# setup MPICH ##########################################################

print_double_line
# CONDOR_LIBEXEC=/usr/libexec/condor by default
CONDOR_LIBEXEC="$(condor_config_val libexec)"
SSHD_SH=$CONDOR_LIBEXEC/sshd.sh
CONDOR_SSH=$CONDOR_LIBEXEC/condor_ssh

. $SSHD_SH $_CONDOR_PROCNO $_CONDOR_NPROCS
# If not the head node, just sleep forever, to let the
# sshds run
if [ $_CONDOR_PROCNO -ne 0 ]
then
		wait
		sshd_cleanup
		exit 0
fi

CONDOR_CONTACT_FILE=$_CONDOR_SCRATCH_DIR/contact
echo "Created the following contact file:"
cat "$CONDOR_CONTACT_FILE"

# The second field in the contact file is the machine name
# that condor_ssh knows how to use
sort -n -k 1 < $CONDOR_CONTACT_FILE | awk '{print $2}' > $_CONDOR_SCRATCH_DIR/machines

export HYDRA_HOST_FILE=$_CONDOR_SCRATCH_DIR/machines
echo "Created the following machine file:"
cat $HYDRA_HOST_FILE

# MPI applications #####################################################

print_double_line
echo "Running MPI hello world..."
mpiexec -launcher ssh -launcher-exec "$CONDOR_SSH" -n 4 ./mpi_hello_world

print_double_line
echo "Running MPI info..."
mpiexec -launcher ssh -launcher-exec "$CONDOR_SSH" -n 4 ./mpi_info

# cleanup MPICH ########################################################

sshd_cleanup
rm -f $HYDRA_HOST_FILE
