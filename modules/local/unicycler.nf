process UNICYCLER {
    tag "$meta.id"
    label 'process_high_memory'

    conda "bioconda::unicycler=0.5.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        'https://depot.galaxyproject.org/singularity/unicycler%3A0.5.0--py39h4e691d4_3'}"

    input: // input as ISGC( tuple(meta, merged_reads))
    tuple val(meta), path(trimmed_reads) //input trimmed reads from fastp - need to transform to new channel and flatten for input here

    
    output:
    tuple val(meta), path("*.scaffolds.fa"),    emit: scaffolds 
    tuple val(meta), path("*.assembly.gfa"),    emit: assembly_gfa

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in cjroyer/nfhbptwo/bin/
    def prefix = task.ext.prefix ?: "${meta.id}"
    def (r1, r2) = trimmed_reads
    """
    unicycler --threads $task.cpus --mode normal -1 "${r1}" -2 "${r2}" --out ./
    mv assembly.fasta ${prefix}.scaffolds.fa
    mv assembly.gfa ${prefix}.assembly.gfa
    mv unicycler.log ${prefix}.unicycler.log
    """
}
