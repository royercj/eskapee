process CHECKM_OUTPUTPREP {
	tag "$meta.id"
    label 'process_low'

    conda "conda-forge::pigz=2.3.4"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pigz:2.3.4' :
        'quay.io/biocontainers/pigz:2.3.4' }"

    input: // 
    tuple val(meta), path(checkm_tsv)
        
    output:
    tuple val(meta), path("*.csv"),    emit: genomeInfo_file
    

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in cjroyer/nfhbptwo/bin/
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    touch ${prefix}.csv
    echo "genome,completeness,contamination,strain_heterogeneity" > ${prefix}.csv
    tail -n +2 $checkm_tsv | cut -d '	' -f 1,12,13,14 | sed 's/	/,/g' | sed 's/[^,]*/&.fasta/1' >> ${prefix}.csv
    
    """
}
