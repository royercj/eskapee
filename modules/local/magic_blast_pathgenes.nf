process MAGIC_BLAST_PATHGENES {
    tag "$meta.id"
    label 'process_large'

    conda "bioconda::blast=2.14.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        'https://depot.galaxyproject.org/singularity/magicblast%3A1.7.0--hf1761c0_0'}"

    input: // input as MAGIC_BLAST( tuple(meta, merged_reads), pathgenes)
    
    tuple val(meta), path(merged_reads)
    path mbdb

    
    output:
    tuple val(meta), path("*.blast"), emit: path_blast

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in cjroyer/nfhbptwo/bin/
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    magicblast -query $merged_reads -db ${mbdb}/pathgenes.mbdb -infmt fasta -no_unaligned -splice F -outfmt tabular -parse_deflines T -out ${prefix}.topath.blast
    """
}
