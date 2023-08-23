#!/usr/bin/env bash

print_double_line
echo "$(date) unarchive environment..."
tar -xzf pmpm-20230718-Linux-x86_64-MPICH.tar.gz -C /tmp

print_double_line
echo "$(date) activate environment..."
source /tmp/pmpm-20230718/bin/activate /tmp/pmpm-20230718
print_line
echo "Python is available at:"
which python
