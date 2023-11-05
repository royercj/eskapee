//
// ESKAPEE MAG workflow
//
include { MERGE_READS                   } from '../../modules/local/merge_reads'
include { UNICYCLER                     } from '../../modules/nf-core/unicycler/main'
include { FILTER_CONTIGS                } from '../../modules/local/filter_contigs'
include { MAXBIN2                       } from '../../modules/nf-core/maxbin2/main'
include { GUNZIP as GUNZIP_SCAFFOLDS    } from '../../modules/nf-core/gunzip/main'
include { GUNZIP as GUNZIP_MAXBIN2      } from '../../modules/nf-core/gunzip/main'
include { GUNZIP as GUNZIP_METABAT2     } from '../../modules/nf-core/gunzip/main'
include { METABAT2_METABAT2 as METABAT2 } from '../../modules/nf-core/metabat2/metabat2/main'
include { CHECKM_LINEAGEWF              } from '../../modules/nf-core/checkm/lineagewf/main'
include { CHECKM_OUTPUTPREP             } from '../../modules/local/checkm_outputprep'
include { METABAT2_OUTPUTPREP           } from '../../modules/local/metabat2_outputprep'
include { DREP                          } from '../../modules/local/drep'
include { GTDBTK_CLASSIFYWF as GTDBTK   } from '../../modules/local/gtdbtk_classifywf'
include { ANICLUSTERMAP                 } from '../../modules/local/aniclustermap'


workflow ESKAPEE_MAG {
    take:
    ch_unzipped
    ch_scrubbed_reads
        
    main:
    //
    // Local MODULE: MERGE_READS
    //
    MERGE_READS (
        ch_unzipped
    )
    ch_merged_reads = Channel.empty()
    ch_merged_reads = ch_merged_reads.mix(MERGE_READS.out.merged_reads)
     
    //
    // MODULE: UNICYCLER
    //
    ch_unicycler_input = ch_scrubbed_reads.map { meta, reads -> [meta, reads, []]}
    
    UNICYCLER (
        ch_unicycler_input
    )
    ch_scaffolds = Channel.empty()
    ch_scaffolds = ch_scaffolds.mix(UNICYCLER.out.scaffolds)
    
    //
    // MODULE: IDBAUD
    //

    //
    // MODULE: GUNZIP_SCAFFOLDS
    //
    //
    GUNZIP_SCAFFOLDS(
        ch_scaffolds
    )
    ch_filter_input= GUNZIP_SCAFFOLDS.out.gunzip
    
    
    //
    // Local MODULE: FILTER_CONTIGS
    //
    FILTER_CONTIGS (
        ch_filter_input
    )
    ch_filt_contigs = Channel.empty()
    ch_filt_contigs = ch_filt_contigs.mix(FILTER_CONTIGS.out.filt_assembly)
    
    
    ch_maxbin2_prep = ch_filt_contigs.join(ch_merged_reads)
    ch_maxbin2_in = ch_maxbin2_prep.map { meta, contigs, reads -> [ meta, contigs, reads, []]}
    
    ch_metabat2_in = ch_filt_contigs.map { meta, contigs -> [ meta, contigs, []]}
    //
    // MODULE: MAXBIN2
    //
    MAXBIN2 (
        ch_maxbin2_in

    )
    
    ch_maxbin2_bins_for_gunzip = Channel.empty()
    ch_maxbin2_bins_for_gunzip = ch_maxbin2_bins_for_gunzip.mix(MAXBIN2.out.binned_fastas.transpose())
    
    //
    // MODULE: METABAT2
    //
    METABAT2 (
        ch_metabat2_in
    )

    ch_metabat2_bins_for_gunzip = Channel.empty()
    ch_metabat2_bins_for_gunzip = ch_metabat2_bins_for_gunzip.mix(METABAT2.out.fasta.transpose())

    //
    // Local MODULE: GUNZIP_MAXBIN2
    //
    GUNZIP_MAXBIN2 (
        ch_maxbin2_bins_for_gunzip
    )
    ch_checkm_in_maxbin2 = Channel.empty()
    ch_checkm_in_maxbin2 = ch_checkm_in_maxbin2.mix(GUNZIP_MAXBIN2.out.gunzip) //////////////////////////////////////////////////////////
    
    //
    // Local MODULE: GUNZIP_METABAT2
    //
    GUNZIP_METABAT2 (
        ch_metabat2_bins_for_gunzip
    )
    ch_metabat2_out_prep = Channel.empty()
    ch_metabat2_out_prep = ch_metabat2_out_prep.mix(GUNZIP_METABAT2.out.gunzip)
    

    //
    // Local MODULE: METABAT2_OUTPUTPREP
    //
    METABAT2_OUTPUTPREP(
        ch_metabat2_out_prep
    )
    ch_renamed_metabat2 = Channel.empty()
    ch_renamed_metabat2 = ch_renamed_metabat2.mix(METABAT2_OUTPUTPREP.out.metabat2_fasta)
    //ch_renamed_metabat2.view()

    ch_checkm_in_final = Channel.empty()
    ch_checkm_in_final = ch_checkm_in_final.mix(ch_checkm_in_maxbin2)
    ch_checkm_in_final = ch_checkm_in_final.mix(ch_renamed_metabat2)
    ch_checkm_in_final = ch_checkm_in_final.groupTuple()
    //ch_checkm_in_final = ch_checkm_in_final.groupTuple()
    
    //
    // MODULE: CHECKM_LINEAGEWF
    //
    CHECKM_LINEAGEWF(
        ch_checkm_in_final,
        'fasta',
        []
    )
    ch_checkm_qual = Channel.empty()
    ch_checkm_qual = ch_checkm_qual.mix(CHECKM_LINEAGEWF.out.checkm_tsv)
     
    //
    // Local MODULE: CHECKM_OUTPUTPREP
    //
    CHECKM_OUTPUTPREP(
        ch_checkm_qual
    )
    ch_genomeInfo = Channel.empty()
    ch_genomeInfo = ch_genomeInfo.mix(CHECKM_OUTPUTPREP.out.genomeInfo_file)
    
    ch_drep_in = ch_checkm_in_final.join(ch_genomeInfo)
    
    //
    // Local MODULE: DREP
    //
    DREP (
        ch_drep_in
        
    )

    ch_95_bins = Channel.empty()
    ch_95_bins = ch_95_bins.mix(DREP.out.drepd_bins)
    ch_95_bins_dir = Channel.empty()
    ch_95_bins_dir = ch_95_bins_dir.mix(DREP.out.drepd_bins_dir)

    //
    // Local MODULE: ANICLUSTERMAP
    //
    ANICLUSTERMAP(
        ch_95_bins_dir
    )
    ch_anicm_tsv = Channel.empty()
    ch_anicm_png = Channel.empty()

    ch_anicm_tsv = ch_anicm_tsv.mix(ANICLUSTERMAP.out.tsv)
    ch_anicm_png = ch_anicm_png.mix(ANICLUSTERMAP.out.png)

    // END WORKFLOW
    
   
    emit:
    mags = ch_95_bins
}