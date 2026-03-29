#!/bin/bash
#SBATCH -p eck-q
#SBATCH --cpus-per-task=2
#SBATCH -J PROKKA_SPADES

module load prokka

prokka /home/alumno13/TareaADO/results/contigs.fasta \
    --outdir /home/alumno13/TareaADO/results/prokka_spades \
    --prefix ERR15113764_spades \
    --metagenome \
    --cpus 2 \
    --force
