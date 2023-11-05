process GTDBTK_CLASSIFYWF {
    tag "${meta.id}"
    label 'process_large'

    // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    conda "bioconda::gtdbtk=2.1.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gtdbtk:2.1.1--pyhdfd78af_1' :
        'biocontainers/gtdbtk:2.1.1--pyhdfd78af_1' }"

    input:
    tuple val(meta), path(bins)
    tuple val(db_name), path(database), path(temp)

    output:
    tuple val(meta), path("classify/*.summary.tsv")          , emit: summary
    tuple val(meta), path("classify/*.classify.tree")        , emit: tree
    tuple val(meta), path("identify/*.markers_summary.tsv")  , emit: markers
    tuple val(meta), path("align/*.msa.fasta.gz")            , emit: msa
    tuple val(meta), path("align/*.user_msa.fasta.gz")       , emit: user_msa
    tuple val(meta), path("align/*.filtered.tsv")            , emit: filtered
    tuple val(meta), path("${meta.id}.gtdbtk.log")           , emit: log
    tuple val(meta), path("${meta.id}.gtdbtk.warnings.log")  , emit: warnings
    tuple val(meta), path("identify/*.failed_genomes.tsv")   , emit: failed
    path "versions.yml"                                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    //def prefix = task.ext.prefix ?: "${meta.id}"
    """
    export GTDBTK_DATA_PATH="${database}"
    
    gtdbtk classify_wf \\
        $args \\
        --genome_dir ${bins}/ \\
        --prefix ${prefix} \\
        --extension fasta \\
        --out_dir . \\
        --cpus $task.cpus \\
        --pplacer_cpus $task.cpus \\
        --scratch_dir "${temp}" \\
        
    
    mv gtdbtk.log ${prefix}.gtdbtk.log
    mv gtdbtk.warnings.log ${prefix}.gtdbtk.warnings.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gtdbtk: \$(echo \$(gtdbtk --version -v 2>&1) | sed "s/gtdbtk: version //; s/ Copyright.*//")
    END_VERSIONS
    """

    stub:
    def VERSION = '2.1.1' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.

    """
    touch ${meta.id}.gtdbtk.stub.summary.tsv
    touch ${meta.id}.gtdbtk.stub.classify.tree.gz
    touch ${meta.id}.gtdbtk.stub.markers_summary.tsv
    touch ${meta.id}.gtdbtk.stub.msa.fasta.gz
    touch ${meta.id}.gtdbtk.stub.user_msa.fasta
    touch ${meta.id}.gtdbtk.stub.filtered.tsv
    touch ${meta.id}.gtdbtk.log
    touch ${meta.id}.gtdbtk.warnings.log
    touch ${meta.id}.gtdbtk.failed_genomes.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gtdbtk: \$(echo "$VERSION")
    END_VERSIONS
    """
}
