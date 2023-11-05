process METABAT2_OUTPUTPREP {
    tag "$meta.id"
    label 'process_low'

    conda "conda-forge::pigz=2.3.4"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pigz:2.3.4' :
        'quay.io/biocontainers/pigz:2.3.4' }"

    input:

    tuple val(meta), path(metabat_fa) //
    
    output:
    tuple val(meta), path("*.fasta"), emit: metabat2_fasta //
        
    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in cjroyer/ESKAPEE/bin/
    def prefix = task.ext.prefix ?: "${meta.id}"
    def oldname = "${metabat_fa}"
    def newname = "${oldname}sta"
    """
     mv ${metabat_fa} ${newname}
     
    """
}
