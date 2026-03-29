#!/usr/bin/env nextflow

/*
========================================================================================
    Pipeline ABRicate — Equivalente al Workflow de Galaxy "Trabajo ADO"
    Análisis de Datos Ómicos — Máster en Bioinformática — Universidad de Murcia
    Autores: Ángel López Francés & Juan Andrés Serrat Hurtado

    Pasos del workflow Galaxy reproducidos:
      Step 0  → Input: ERR15113764.fastq
      Step 1  → Input: contigs.fasta
      Step 2  → ABRicate List (listar bases de datos disponibles)
      Step 3  → FastQC (control de calidad sobre el FASTQ)
      Step 4  → ABRicate CARD   (min_id=80%, min_cov=80%)
      Step 5  → ABRicate VFDB   (min_id=80%, min_cov=80%)
      Step 6  → ABRicate ResFinder (min_id=80%, min_cov=80%)
      Step 7  → ABRicate Summary (combinar resultados de steps 4,5,6)
========================================================================================
*/

nextflow.enable.dsl=2

// ========================================================================================
// PARÁMETROS — equivalentes a los inputs del workflow Galaxy
// ========================================================================================

params.reads    = "/home/alumno13/TareaADO/ERR15113764.fastq"
params.contigs  = "/home/alumno13/TareaADO/results/contigs.fasta"
params.outdir   = "/home/alumno13/TareaADO/nextflow_abricate"
params.min_id   = 80.0   // --min_dna_id en Galaxy
params.min_cov  = 80.0   // --min_cov en Galaxy

log.info """
========================================================================================
    ABRICATE PIPELINE — Galaxy Workflow Equivalente
========================================================================================
Reads    : ${params.reads}
Contigs  : ${params.contigs}
Output   : ${params.outdir}
Min ID   : ${params.min_id}%
Min Cov  : ${params.min_cov}%
========================================================================================
"""

// ========================================================================================
// STEP 2 — ABRicate List (listar bases de datos disponibles)
// Equivalente a: toolshed.g2.bx.psu.edu/repos/iuc/abricate/abricate_list/1.0.1
// ========================================================================================

process ABRICATE_LIST {
    tag "ABRicate List"
    publishDir "${params.outdir}/00_abricate_list", mode: 'copy'

    output:
    path "abricate_databases.txt", emit: db_list

    script:
    """
    abricate --list > abricate_databases.txt
    """
}

// ========================================================================================
// STEP 3 — FastQC sobre el FASTQ
// Equivalente a: toolshed.g2.bx.psu.edu/repos/devteam/fastqc/fastqc/0.74+galaxy1
// Parámetros Galaxy: kmers=7, no adapters/contaminants/limits files, nogroup=false
// ========================================================================================

process FASTQC {
    tag "FastQC: ${reads.simpleName}"
    publishDir "${params.outdir}/01_fastqc", mode: 'copy'

    input:
    path reads

    output:
    path "*.html", emit: html
    path "*.zip",  emit: zip

    script:
    """
    fastqc ${reads} \
        --kmers 7 \
        --outdir .
    """
}

// ========================================================================================
// STEP 4 — ABRicate CARD
// Equivalente a: toolshed.g2.bx.psu.edu/repos/iuc/abricate/abricate/1.0.1
// Parámetros Galaxy: db=card, min_dna_id=80.0, min_cov=80.0, no_header=false
// ========================================================================================

process ABRICATE_CARD {
    tag "ABRicate: CARD"
    publishDir "${params.outdir}/02_abricate_card", mode: 'copy'

    input:
    path contigs

    output:
    path "abricate_card.tsv", emit: report

    script:
    """
    abricate \
        --db card \
        --minid ${params.min_id} \
        --mincov ${params.min_cov} \
        ${contigs} > abricate_card.tsv
    """
}

// ========================================================================================
// STEP 5 — ABRicate VFDB
// Equivalente a: toolshed.g2.bx.psu.edu/repos/iuc/abricate/abricate/1.0.1
// Parámetros Galaxy: db=vfdb, min_dna_id=80.0, min_cov=80.0, no_header=false
// ========================================================================================

process ABRICATE_VFDB {
    tag "ABRicate: VFDB"
    publishDir "${params.outdir}/03_abricate_vfdb", mode: 'copy'

    input:
    path contigs

    output:
    path "abricate_vfdb.tsv", emit: report

    script:
    """
    abricate \
        --db vfdb \
        --minid ${params.min_id} \
        --mincov ${params.min_cov} \
        ${contigs} > abricate_vfdb.tsv
    """
}

// ========================================================================================
// STEP 6 — ABRicate ResFinder
// Equivalente a: toolshed.g2.bx.psu.edu/repos/iuc/abricate/abricate/1.0.1
// Parámetros Galaxy: db=resfinder, min_dna_id=80.0, min_cov=80.0, no_header=false
// ========================================================================================

process ABRICATE_RESFINDER {
    tag "ABRicate: ResFinder"
    publishDir "${params.outdir}/04_abricate_resfinder", mode: 'copy'

    input:
    path contigs

    output:
    path "abricate_resfinder.tsv", emit: report

    script:
    """
    abricate \
        --db resfinder \
        --minid ${params.min_id} \
        --mincov ${params.min_cov} \
        ${contigs} > abricate_resfinder.tsv
    """
}

// ========================================================================================
// STEP 7 — ABRicate Summary
// Equivalente a: toolshed.g2.bx.psu.edu/repos/iuc/abricate/abricate_summary/1.0.1
// Combina los outputs de CARD (step 4), VFDB (step 5) y ResFinder (step 6)
// ========================================================================================

process ABRICATE_SUMMARY {
    tag "ABRicate: Summary"
    publishDir "${params.outdir}/05_abricate_summary", mode: 'copy'

    input:
    path card_report
    path vfdb_report
    path resfinder_report

    output:
    path "abricate_summary.tsv", emit: summary

    script:
    """
    abricate --summary \
        ${card_report} \
        ${vfdb_report} \
        ${resfinder_report} \
        > abricate_summary.tsv
    """
}

// ========================================================================================
// WORKFLOW PRINCIPAL
// Reproduce el orden exacto del workflow Galaxy:
//   Step 0 → reads input
//   Step 1 → contigs input
//   Step 2 → ABRicate List
//   Step 3 → FastQC
//   Step 4 → ABRicate CARD
//   Step 5 → ABRicate VFDB
//   Step 6 → ABRicate ResFinder
//   Step 7 → ABRicate Summary (Steps 4+5+6)
// ========================================================================================

workflow {

    // Inputs (Steps 0 y 1 del workflow Galaxy)
    reads_ch   = Channel.fromPath(params.reads)
    contigs_ch = Channel.fromPath(params.contigs)

    // Step 2 — Listar bases de datos disponibles
    ABRICATE_LIST()

    // Step 3 — FastQC sobre el FASTQ
    FASTQC(reads_ch)

    // Steps 4, 5, 6 — ABRicate con las tres bases de datos (en paralelo)
    ABRICATE_CARD(contigs_ch)
    ABRICATE_VFDB(contigs_ch)
    ABRICATE_RESFINDER(contigs_ch)

    // Step 7 — ABRicate Summary combinando los tres resultados
    ABRICATE_SUMMARY(
        ABRICATE_CARD.out.report,
        ABRICATE_VFDB.out.report,
        ABRICATE_RESFINDER.out.report
    )
}
