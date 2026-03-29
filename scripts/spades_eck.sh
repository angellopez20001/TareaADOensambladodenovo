#!/bin/bash
#SBATCH -p eck-q
#SBATCH --cpus-per-task=2
#SBATCH -J APP-ECK

module load spades/3.15.0

readonly OUTDIR=/home/alumno13/TareaADO/results
mkdir -p ${OUTDIR}

spades.py -o ${OUTDIR} \
    --disable-gzip-output \
    --phred-offset 33 \
    -t 2 \
    -k 33,55,79 \
    -s ERR15113764.fastq