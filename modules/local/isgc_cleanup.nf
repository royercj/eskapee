process  ISGC_CLEANUP {
    tag "$meta.id"
    label 'process_medium'

    conda "conda-forge::python=3.8.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'biocontainers/python:3.8.3' }"

    input: // input as ISGC( tuple(meta, merged_reads))
    tuple val(meta), path(blast_file), path(coupled_reads) //input blast file from magic blast
    
    
    output:
    tuple val(meta), path("*fltrdBstHts.blst"),    emit: isgc_pathgenes_blast_filtered
    tuple val(meta), path("*contig_anir.tsv"),     emit: isgc_pathgenes_contig_anir
    tuple val(meta), path("*contig_breadth.tsv"),  emit: isgc_pathgenes_contig_breadth
    tuple val(meta), path("*contig_tad.tsv"),      emit: isgc_pathgenes_contig_tad
    tuple val(meta), path("*genome_by_bp.tsv"),    emit: isgc_pathgenes_genome_by_bp
    tuple val(meta), path("*genome.tsv"),          emit: isgc_pathgenes_genome_summary

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in cjroyer/nfhbptwo/bin/
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    01c_MagicBlast_ShortRead_Filter.py -i $blast_file
    03a_MagicBlast_CoverageMagic.py -m $coupled_reads -g /pathgenes/pathgenes.fa  -b ${prefix}.fltrdBstHts.blst -c 95 -d 100 -o ${prefix}.topath
    #TODO - update the path for the pathgenes files
    
    """
}
