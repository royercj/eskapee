/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowEskapee.initialise(params, log)

// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { INPUT_CHECK                 } from '../subworkflows/local/input_check'
include { PATHOGEN_GENE_DETECTION     } from '../subworkflows/local/pathogen_gene_detection'
include { ESKAPEE_MAG                 } from '../subworkflows/local/eskapee_mag'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { FASTQC                      } from '../modules/nf-core/fastqc/main'
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { FASTP                       } from '../modules/nf-core/fastp/main'
include { GUNZIP                      } from '../modules/nf-core/gunzip/main'
include { KRAKEN2_KRAKEN2             } from '../modules/nf-core/kraken2/kraken2/main'
include { KRONA_KTIMPORTTEXT          } from '../modules/nf-core/krona/ktimporttext/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow ESKAPEE {

    ch_versions = Channel.empty()
    
    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    //
    // MODULE: Run FastQC
    //
    FASTQC (
        INPUT_CHECK.out.reads
    )
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    //
    // MODULE: FASTP
    //
    FASTP (
        INPUT_CHECK.out.reads,
        [],
        false,
        false
    )
    ch_trimmed = FASTP.out.reads
    ch_versions = ch_versions.mix(FASTP.out.versions.first())

    //
    // MODULE: KRAKEN2
    //
    KRAKEN2_KRAKEN2 (
        ch_trimmed,
        //#TODO add kraken db flag ,
        true,
        true

    )
    ch_scrubbed_reads = KRAKEN2_KRAKEN2.out.unclassified_reads_fastq
    ch_k2_report = KRAKEN2_KRAKEN2.out.report
    ch_versions = ch_versions.mix(KRAKEN2_KRAKEN2.out.versions.first())
    
    //
    // MODULE: KRONA
    //
    KRONA_KTIMPORTTEXT (
        ch_k2_report
    )
    ch_krona_report = KRONA_KTIMPORTTEXT.out.html
    ch_versions = ch_versions.mix(KRONA_KTIMPORTTEXT.out.versions.first())


    ch_reads_for_gunzip = Channel.empty()
    ch_reads_for_gunzip = ch_reads_for_gunzip.mix(KRAKEN2_KRAKEN2.out.unclassified_reads_fastq.transpose())
    //
    // MODULE: GUNZIP
    //
    GUNZIP (
        ch_reads_for_gunzip
    )
    ch_unzipped = Channel.empty()
    ch_unzipped = ch_unzipped.mix(GUNZIP.out.gunzip.groupTuple())
    ch_versions = ch_versions.mix(GUNZIP.out.versions.first())

    
    //
    // SUBWORKFLOW: PATHOGEN_GENE_DETECTION
    //
    PATHOGEN_GENE_DETECTION (
        ch_unzipped 

    )
    ch_pathgenes_blast_filtered = PATHOGEN_GENE_DETECTION.out.path_blast_filtered
    ch_pathgenes_contig_anir    = PATHOGEN_GENE_DETECTION.out.path_contig_anir    
    ch_pathgenes_contig_breadth = PATHOGEN_GENE_DETECTION.out.path_contig_breadth
    ch_pathgenes_contig_tad     = PATHOGEN_GENE_DETECTION.out.path_contig_tad 
    ch_pathgenes_genome_by_bp   = PATHOGEN_GENE_DETECTION.out.path_genome_by_bp 
    ch_pathgenes_genome_summary = PATHOGEN_GENE_DETECTION.out.path_genome_summary

    //
    // SUBWORKFLOW: ESKAPEE_MAG
    //
    ESKAPEE_MAG (
        ch_unzipped,
        ch_scrubbed_reads
    )
    ch_mags = ESKAPEE_MAG.out.mags


    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowEskapee.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowEskapee.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )
    multiqc_report = MULTIQC.out.report.toList()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
