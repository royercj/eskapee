process ANICLUSTERMAP {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::aniclustermap=1.2.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        'https://depot.galaxyproject.org/singularity/aniclustermap%3A1.2.0--pyhdfd78af_0'}"

    input: 
    tuple val(meta), path(drepped_bins)
    
    output:
    tuple val(meta), path("*.png"), emit: png 
    tuple val(meta), path("*.svg"), emit: svg
    tuple val(meta), path("*.tsv"), emit: tsv
    tuple val(meta), path("*.nwk"), emit: nwk

    when:
    task.ext.when == null || task.ext.when

    script: 
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    ANIclustermap -i $drepped_bins -o ./${prefix}.anicm --fig_width 20 --fig_height 15 --annotation
    cd ${prefix}.anicm
    mv ANIclustermap_dendrogram.nwk ../${prefix}_dendrogram.nwk
    mv ANIclustermap_matrix.tsv ../${prefix}_matrix.tsv
    mv ANIclustermap.png ../${prefix}.png
    mv ANIclustermap.svg ../${prefix}.svg
    
    """
}
