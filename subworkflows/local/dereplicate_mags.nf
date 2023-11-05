//
// Check input samplesheet and get read channels
//

include { CHECKM_LINEAGEWF           } from '../../modules/nf-core/checkm/lineagewf/main'
include { DREP                       } from '../../modules/local/drep'

workflow DEREPLICATE_MAGS {
    take:
    ch_drep_in
        
    main:

    //
    // Local MODULE: MERGE_READS
    //
    CHECKM_LINEAGEWF(
        ch_drep_in,
        "fasta",
        []
    )
    ch_checkm_qual = Channel.empty()
    ch_checkm_qual = ch_checkm_qal.mix(CHECKM_LINEAGEWF.out.checkm_tsv)

    //
    // Local MODULE: MAGIC_BLAST
    //
    
    // END WORKFLOW
    
    emit:
    

}