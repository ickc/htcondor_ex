#!/bin/bash -l

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

########################################################################

export X509_USER_PROXY=ac.pem

print_double_line
echo 'Testing gfal-ls with webdav'
print_line
gfal-ls -alH --full-time davs://bohr3226.tier2.hep.manchester.ac.uk/dpm/tier2.hep.manchester.ac.uk/home/souk.ac.uk/

print_double_line
echo 'Testing gfal-mkdir with webdav'
gfal-mkdir davs://bohr3226.tier2.hep.manchester.ac.uk/dpm/tier2.hep.manchester.ac.uk/home/souk.ac.uk/testing
print_line
gfal-ls -alH --full-time davs://bohr3226.tier2.hep.manchester.ac.uk/dpm/tier2.hep.manchester.ac.uk/home/souk.ac.uk/

print_double_line
echo 'Testing gfal-rm with webdav'
print_line
gfal-rm -r davs://bohr3226.tier2.hep.manchester.ac.uk/dpm/tier2.hep.manchester.ac.uk/home/souk.ac.uk/testing

print_double_line
echo 'Testing gfal-copy with webdav'
echo hello world > hello-davs.txt
gfal-copy -f hello-davs.txt davs://bohr3226.tier2.hep.manchester.ac.uk/dpm/tier2.hep.manchester.ac.uk/home/souk.ac.uk/

########################################################################

print_double_line
echo 'Testing gfal-ls with xrootd'
print_line
gfal-ls -alH --full-time root://bohr3226.tier2.hep.manchester.ac.uk/dpm/tier2.hep.manchester.ac.uk/home/souk.ac.uk/

print_double_line
echo 'Testing gfal-mkdir with xrootd'
gfal-mkdir root://bohr3226.tier2.hep.manchester.ac.uk/dpm/tier2.hep.manchester.ac.uk/home/souk.ac.uk/testing
print_line
gfal-ls -alH --full-time root://bohr3226.tier2.hep.manchester.ac.uk/dpm/tier2.hep.manchester.ac.uk/home/souk.ac.uk/

print_double_line
echo 'Testing gfal-rm with xrootd'
print_line
gfal-rm -r root://bohr3226.tier2.hep.manchester.ac.uk/dpm/tier2.hep.manchester.ac.uk/home/souk.ac.uk/testing

print_double_line
echo 'Testing gfal-copy with xrootd'
echo hello world > hello-root.txt
gfal-copy -f hello-root.txt root://bohr3226.tier2.hep.manchester.ac.uk/dpm/tier2.hep.manchester.ac.uk/home/souk.ac.uk/
