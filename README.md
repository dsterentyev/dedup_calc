# dedup_calc
dedup_calc.pl - script for calculate similarity of two files

This is done by dividing files into chunks of a given size, calculating the hash (sha256) of each chunk and finding the same hashes. 

Usage: dedup_calc.pl blocksize file1 file2 [formatter]

Block size must be positive number >= 32 (with optional suffix K or M)

Option formatter is optional and defines output format. Possible values - csv, json
