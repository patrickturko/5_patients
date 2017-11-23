#!/bin/bash

trim_galore -q 20 --length 18 --paired -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC -a2 AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGTA *Patient_5_tumor*.fastq.gz

