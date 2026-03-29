#!/bin/bash
#SBATCH -p eck-q
#SBATCH --cpus-per-task=2
#SBATCH -J NEXTFLOW_ABRICATE
#SBATCH --time=2:00:00
#SBATCH --output=nextflow_abricate_%j.log

# ============================================================
# Lanzamiento del pipeline Nextflow equivalente al
# Workflow Galaxy "Trabajo ADO"
# Pasos: FastQC + ABRicate (CARD, VFDB, ResFinder) + Summary
# ============================================================

# Cargar Nextflow si está disponible como módulo
module load nextflow 2>/dev/null || export PATH=$HOME:$PATH

PIPELINE_DIR=/home/alumno13/TareaADO

nextflow run ${PIPELINE_DIR}/main_galaxy_workflow.nf \
    -profile cluster \
    -c ${PIPELINE_DIR}/nextflow_galaxy.config \
    --reads  "/home/alumno13/TareaADO/ERR15113764.fastq" \
    --contigs "/home/alumno13/TareaADO/results/contigs.fasta" \
    --outdir  "/home/alumno13/TareaADO/nextflow_abricate" \
    --min_id  80.0 \
    --min_cov 80.0 \
    -resume

echo "Pipeline ABRicate finalizado"
