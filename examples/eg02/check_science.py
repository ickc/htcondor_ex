#!/usr/bin/env python3

import os
import argparse

def main(num_runs=100):
    for i in range(num_runs):
        dir_name = f"run{i}"
        file_path = os.path.join(dir_name, "outfile.txt")
        with open(file_path, "r") as f:
            num = int(f.read().strip())
        expected = (32 * (i + 1)) * i + 10
        if num != expected:
            raise ValueError(f"Expected {expected} but got {num} in {file_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("num_runs", type=int, nargs='?', default=100, help="number of runs to check")
    args = parser.parse_args()
    main(args.num_runs)
