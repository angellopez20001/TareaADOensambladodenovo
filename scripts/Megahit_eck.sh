#!/bin/bash
#SBATCH -p eck-q
#SBATCH --cpus-per-task=2
#SBATCH -J MEGAHIT

module load megahit

megahit \
    -r /home/alumno13/TareaADO/ERR15113764.fastq \
    -o /home/alumno13/TareaADO/megahit_output \
    --min-contig-len 500 \
    -t 2
