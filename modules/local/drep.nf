process DREP {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::drep=3.4.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        'https://depot.galaxyproject.org/singularity/drep%3A3.4.3--pyhdfd78af_0' }"

    input: // input as ISGC( tuple(meta, merged_reads))
    tuple val(meta), path(unzipped_bins), path(genome_information)
    //tuple val(meta), path(genome_information)  //

    
    output:
    tuple val(meta), path("dereplicated_genomes/*.fasta"),    emit: drepd_bins
    tuple val(meta), path("dereplicated_genomes/"),          emit: drepd_bins_dir
    

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in cjroyer/nfhbptwo/bin/
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    dRep dereplicate --genomes $unzipped_bins --S_ani 0.95 --S_algorithm fastANI --genomeInfo $genome_information ./
    """
}
