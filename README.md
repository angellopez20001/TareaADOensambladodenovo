# TareaADOensambladodenovo
Aqui se encuentra el trabajo fase 2 de la asignatura de ADO :)
# Pipeline Genómica Bacteriana: Ensamblado de novo y anotación funcional de E. coli

Análisis de Datos Ómicos — Máster en Bioinformática, Universidad de Murcia  
Realizado por:
Ángel López Francés 
Juan Andrés Serrat Hurtado  
30/03/2026

## Descripción

Pipeline Nextflow DSL2 para el ensamblado *de novo* y anotación funcional del genoma
bacteriano ERR15113764 (*Escherichia coli*). Replica el análisis realizado en Galaxy Europe
usando los mismos parámetros y versiones de herramientas, combinando ejecución en
clúster (single-end) y en Galaxy (paired-end).

**Herramientas:** FastQC → SPAdes → MEGAHIT → QUAST → Prokka → ABRicate (CARD + VFDB + ResFinder) → ABRicate Summary  
**Ejecutor:** SLURM (servidor ECK, UMU)

## Estructura

```
.
├── main.nf                      # Pipeline principal (Nextflow DSL2)
├── main_galaxy_workflow.nf      # Pipeline equivalente al workflow Galaxy
├── nextflow.config              # Configuración SLURM
├── nextflow_galaxy.config       # Configuración workflow Galaxy
├── run_nextflow.sh              # Script SBATCH para lanzar el pipeline principal
└── run_galaxy_workflow.sh       # Script SBATCH para lanzar el workflow Galaxy
```

Los archivos de referencia (genoma *E. coli* K-12 MG1655) y los ficheros FASTQ
no se incluyen por su tamaño y deben prepararse según las instrucciones de abajo.

## Mínimos para ejecución

- Nextflow >= 22.10
- Java >= 17
- SPAdes >= 3.15.0
- MEGAHIT >= 1.2.9 (instalación manual, ver instrucciones abajo)
- QUAST >= 5.2.0
- Prokka >= 1.14.6
- ABRicate >= 1.0.1
- Acceso al servidor ECK con cuenta en la cola SLURM (eck-q)

## Instalación de Nextflow en el cluster ECK

El servidor ECK incluye Java por defecto, pero Nextflow requiere Java 17 o superior.
Si la versión disponible es anterior, es necesario instalar Java 17 en el directorio
home sin permisos de administrador.

```bash
# 1. Comprobar versión de Java disponible
java -version

# 2. Si la versión es inferior a 17, descargar Java 17 
wget https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz

# 3. Descomprimir
tar -xzf openjdk-17.0.2_linux-x64_bin.tar.gz -C ~/

# 4. Configurar variables de entorno 
echo 'export JAVA_HOME=~/jdk-17.0.2' >> ~/.bashrc
echo 'export JAVA_CMD=$JAVA_HOME/bin/java' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:~/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 5. Verificar Java
java -version
# Debe mostrar: openjdk version "17.0.2"

# 6. Instalar Nextflow
curl -s https://get.nextflow.io | bash
mkdir -p ~/bin && mv nextflow ~/bin/

# 7. Verificar Nextflow
nextflow -version
```

## Instalación de MEGAHIT en el cluster 

MEGAHIT no está disponible como módulo en el servidor ECK, por lo tanto debe
instalarse manualmente descargando el binario precompilado directamente con wget,
sin necesidad de permisos de administrador ni compilación.

```bash
# 1. Descargar el binario precompilado de MEGAHIT v1.2.9 desde GitHub
cd ~
wget https://github.com/voutcn/megahit/releases/download/v1.2.9/MEGAHIT-1.2.9-Linux-x86_64-static.tar.gz

# 2. Descomprimir el archivo descargado
tar -xzf MEGAHIT-1.2.9-Linux-x86_64-static.tar.gz

# 3. Mover el binario a un directorio en el PATH
mkdir -p ~/bin
cp MEGAHIT-1.2.9-Linux-x86_64-static/bin/megahit ~/bin/

# 4. Añadir ~/bin al PATH de forma permanente
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 5. Verificar la instalación
megahit --version
# Debe mostrar: MEGAHIT v1.2.9

# 6. Limpiar archivos temporales (opcional)
rm -rf MEGAHIT-1.2.9-Linux-x86_64-static.tar.gz MEGAHIT-1.2.9-Linux-x86_64-static/
```

## Preparación de archivos de entrada

```bash
mkdir -p /home/alumno13/TareaADO

# Descargar datos FASTQ desde ENA
cd /home/alumno13/TareaADO
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR151/004/ERR15113764/ERR15113764.fastq.gz
gunzip ERR15113764.fastq.gz

# Descargar genoma de referencia E. coli K-12 MG1655 (para Snippy)
wget "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz"
gunzip GCF_000005845.2_ASM584v2_genomic.fna.gz
mv GCF_000005845.2_ASM584v2_genomic.fna ecoli_ref.fasta

# Verificar ficheros
ls -lh /home/alumno13/TareaADO/
```

## Ejecución en el cluster ECK

```bash
# 1. Clonar o copiar los ficheros del pipeline al servidor
# Los ficheros deben estar en /home/alumno13/TareaADO/

# 2. Lanzar el pipeline principal (SPAdes + MEGAHIT + QUAST + Prokka + ABRicate)
sbatch run_nextflow.sh

# 3. Lanzar el pipeline equivalente al workflow Galaxy (FastQC + ABRicate)
sbatch run_galaxy_workflow.sh

# 4. Monitorizar el progreso
tail -f nextflow_*.log

# 5. Reanudar si se interrumpe (Nextflow recuerda los pasos completados)
nextflow run main.nf -profile cluster -resume
```

## Resultados

```
nextflow_results/
├── 01_fastqc/             Control de calidad FastQC
├── 02_spades/             Ensamblaje SPAdes (contigs.fasta, scaffolds.fasta)
├── 03_megahit/            Ensamblaje MEGAHIT (final.contigs.fa)
├── 04_quast/
│   ├── spades/            Métricas QUAST SPAdes (report.txt, report.html)
│   ├── megahit/           Métricas QUAST MEGAHIT (report.txt, report.html)
│   └── comparativa/       Comparativa SPAdes vs MEGAHIT
├── 05_prokka/
│   ├── spades/            Anotación Prokka SPAdes (.gff, .faa, .txt)
│   └── megahit/           Anotación Prokka MEGAHIT (.gff, .faa, .txt)
├── 06_snippy/             Variantes SNPs/INDELs respecto a referencia
├── 07_abricate/           Genes resistencia y virulencia (.tsv)
├── pipeline_report.html   Informe de ejecución Nextflow
└── pipeline_timeline.html Cronograma del pipeline

nextflow_abricate/         Pipeline equivalente al workflow Galaxy
├── 00_abricate_list/      Bases de datos disponibles
├── 01_fastqc/             FastQC sobre el FASTQ
├── 02_abricate_card/      Genes resistencia CARD (abricate_card.tsv)
├── 03_abricate_vfdb/      Genes virulencia VFDB (abricate_vfdb.tsv)
├── 04_abricate_resfinder/ Genes resistencia ResFinder (abricate_resfinder.tsv)
└── 05_abricate_summary/   Tabla resumen conjunta (abricate_summary.tsv)
```

## Parámetros principales del pipeline

| Parámetro | Valor por defecto | Descripción |
|---|---|---|
| `--reads` | ERR15113764.fastq | Fichero FASTQ single-end |
| `--reference` | ecoli_ref.fasta | Genoma referencia *E. coli* K-12 |
| `--outdir` | nextflow_results | Directorio de salida |
| `--kmers` | 33,55,79 | Tamaños de k-mer para SPAdes |
| `--min_contig` | 500 | Longitud mínima de contig (bp) |
| `--cpus` | 2 | Número de CPUs por proceso |
| `--phred_offset` | 33 | Codificación Phred (Sanger/Illumina 1.9) |
| `--min_id` | 80.0 | Identidad mínima ABRicate (%) |
| `--min_cov` | 80.0 | Cobertura mínima ABRicate (%) |

## Enlace al historial de Galaxy Europe

El análisis equivalente realizado en Galaxy Europe está disponible en:  
https://usegalaxy.eu/u/angelillo/h/trabajo-ado  
https://usegalaxy.org/u/juan_serrat/h/ensamblado-comparativo-ecoli
