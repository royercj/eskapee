process IDBAUD {
    tag "$meta.id"
    label 'process_large'

    conda "bioconda::idba=1.1.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        'https://depot.galaxyproject.org/singularity/idba%3A1.1.3--1' }"

    input:

    tuple val(meta), path(merged_reads) //
    
    output:
    tuple val(meta), path("*.fa"), emit: merged_reads //
        
    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in cjroyer/ESKAPEE/bin/
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    idba_ud -r $merged_reads -o ./ --num_threads $task.cpus --maxk 140
    
    """
}
