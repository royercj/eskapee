//
// Check input samplesheet and get read channels
//

include { MERGE_READS                } from '../../modules/local/merge_reads'
include { MAGIC_BLAST_PATHGENES      } from '../../modules/local/magic_blast_pathgenes'
include { ISGC_PATHGENES             } from '../../modules/local/isgc_pathgenes'

workflow PATHOGEN_GENE_DETECTION {
    take:
    ch_unzipped
        
    main:

    //
    // Local MODULE: MERGE_READS
    //
    MERGE_READS(
        ch_unzipped
    )
    ch_merged_reads = Channel.empty()
    ch_merged_reads = ch_merged_reads.mix(MERGE_READS.out.merged_reads)

    //
    // Local MODULE: MAGIC_BLAST
    //
    MAGIC_BLAST_PATHGENES(
        ch_merged_reads,
        //#TODO - fix db directory
        
    )
    ch_blast = Channel.empty()
    ch_blast = ch_blast.mix(MAGIC_BLAST_PATHGENES.out.path_blast)

    //
    // Local MODULE: ISGC_PATHGENES
    //
    ch_ISGC_in = ch_blast.join(ch_merged_reads)
    ISGC_PATHGENES(ch_ISGC_in)
    
    ch_pathgenes_blast_filtered = ISGC_PATHGENES.out.blast_filtered
    ch_pathgenes_contig_anir    = ISGC_PATHGENES.out.contig_anir
    ch_pathgenes_contig_breadth = ISGC_PATHGENES.out.contig_breadth
    ch_pathgenes_contig_tad     = ISGC_PATHGENES.out.contig_tad
    ch_pathgenes_genome_by_bp   = ISGC_PATHGENES.out.genome_by_bp
    ch_pathgenes_genome_summary = ISGC_PATHGENES.out.genome_summary

    // END WORKFLOW
    
    emit:
    path_blast_filtered = ch_pathgenes_blast_filtered
    path_contig_anir    = ch_pathgenes_contig_anir
    path_contig_breadth = ch_pathgenes_contig_breadth
    path_contig_tad     = ch_pathgenes_contig_tad
    path_genome_by_bp   = ch_pathgenes_genome_by_bp
    path_genome_summary = ch_pathgenes_genome_summary
        

}