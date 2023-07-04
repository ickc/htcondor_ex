#!/usr/bin/env python3

import os
import argparse

def main(num_iterations):
    for i in range(num_iterations):
        dir_name = f"run{i}"
        os.mkdir(dir_name)
        with open(os.path.join(dir_name, "infile-A.txt"), "w") as f:
            f.write(str((4*i+1)**2))
        with open(os.path.join(dir_name, "infile-B.txt"), "w") as f:
            f.write(str((4*i+3)**2))

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--num_iterations", type=int, default=100, help="Number of iterations to run")
    args = parser.parse_args()
    main(args.num_iterations)
