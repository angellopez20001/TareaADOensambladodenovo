#!/usr/bin/env nextflow

/*
============================================================
  Workflow ADO - Equivalente al workflow de Galaxy
  Herramientas: FastQC + ABRicate (CARD, VFDB, ResFinder)
============================================================
*/

nextflow.enable.dsl=2

// ── Parámetros de entrada ──────────────────────────────────
params.fastq   = "ERR15113764.fastq"
params.contigs = "contigs.fasta"
params.outdir  = "resultados"

// Parámetros de ABRicate
params.min_id  = 80
params.min_cov = 80

// ── Proceso 1: FastQC ──────────────────────────────────────
process FASTQC {
    tag "FastQC: ${fastq.simpleName}"
    publishDir "${params.outdir}/fastqc", mode: 'copy'

    input:
    path fastq

    output:
    path "*.html", emit: html
    path "*.zip",  emit: zip

    script:
    """
    fastqc ${fastq} --threads 4
    """
}

// ── Proceso 2: ABRicate con CARD ──────────────────────────
process ABRICATE_CARD {
    tag "ABRicate CARD"
    publishDir "${params.outdir}/abricate", mode: 'copy'

    input:
    path contigs

    output:
    path "abricate_CARD.tsv", emit: report

    script:
    """
    abricate \
        --db card \
        --minid ${params.min_id} \
        --mincov ${params.min_cov} \
        ${contigs} > abricate_CARD.tsv
    """
}

// ── Proceso 3: ABRicate con VFDB ──────────────────────────
process ABRICATE_VFDB {
    tag "ABRicate VFDB"
    publishDir "${params.outdir}/abricate", mode: 'copy'

    input:
    path contigs

    output:
    path "abricate_VFDB.tsv", emit: report

    script:
    """
    abricate \
        --db vfdb \
        --minid ${params.min_id} \
        --mincov ${params.min_cov} \
        ${contigs} > abricate_VFDB.tsv
    """
}

// ── Proceso 4: ABRicate con ResFinder ─────────────────────
process ABRICATE_RESFINDER {
    tag "ABRicate ResFinder"
    publishDir "${params.outdir}/abricate", mode: 'copy'

    input:
    path contigs

    output:
    path "abricate_ResFinder.tsv", emit: report

    script:
    """
    abricate \
        --db resfinder \
        --minid ${params.min_id} \
        --mincov ${params.min_cov} \
        ${contigs} > abricate_ResFinder.tsv
    """
}

// ── Proceso 5: ABRicate Summary ───────────────────────────
process ABRICATE_SUMMARY {
    tag "ABRicate Summary"
    publishDir "${params.outdir}/abricate", mode: 'copy'

    input:
    path reports

    output:
    path "abricate_summary.tsv"

    script:
    """
    abricate --summary ${reports} > abricate_summary.tsv
    """
}

// ── Workflow principal ─────────────────────────────────────
workflow {

    // Canales de entrada
    ch_fastq   = Channel.fromPath(params.fastq,   checkIfExists: true)
    ch_contigs = Channel.fromPath(params.contigs,  checkIfExists: true)

    // Ejecutar procesos
    FASTQC           ( ch_fastq   )
    ABRICATE_CARD    ( ch_contigs )
    ABRICATE_VFDB    ( ch_contigs )
    ABRICATE_RESFINDER( ch_contigs )

    // Recoger los 3 reportes y hacer el summary
    ch_reports = ABRICATE_CARD.out.report
        .mix( ABRICATE_VFDB.out.report )
        .mix( ABRICATE_RESFINDER.out.report )
        .collect()

    ABRICATE_SUMMARY ( ch_reports )
}
