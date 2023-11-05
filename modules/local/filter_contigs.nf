process FILTER_CONTIGS {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::bbmap=39.01"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        'https://depot.galaxyproject.org/singularity/bbmap%3A39.01--h92535d8_1' }"

    input:

    tuple val(meta), path(scaffolds) //trimmed reads from fastp, input tuple (meta, [reads1, reads2])
    
    output:
    tuple val(meta), path("*.filt.fa"), emit: filt_assembly //
        
    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in cjroyer/ESKAPEE/bin/
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
     reformat.sh in=$scaffolds out=./${prefix}.filt.fa minlength=2000
    
    """
}
