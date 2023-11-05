process BMTAGGER {
    tag "$meta.id"
    label 'process_large'

    conda "bioconda::bmtagger=3.101"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        'https://depot.galaxyproject.org/singularity/bmtagger%3A3.101--h470a237_4'}"

    input: // input as ISGC( tuple(meta, merged_reads))
    tuple val(meta), path(trimmed_reads) //input trimmed reads from fastp - need to transform to new channel and flatten for input here
    path bitmask
    path srprism
    
    output:
    tuple val(meta), path("*.bmtagger_{1,2}.fastq"), emit: bmtagger_out //need to regroup both reads as tuple

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in cjroyer/nfhbptwo/bin/
    def prefix = task.ext.prefix ?: "${meta.id}"
    def (r1, r2) = trimmed_reads
    """
    bmtagger.sh -b $bitmask -x "${srprism}/GRCh.38.p10.fna.srprism" -T "${srprism}/tmp/" -q 1 -1 "${r1}" -2 "${r2}" -o ${prefix}.bmtagger -X
    """
}
