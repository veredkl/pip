$HOSTNAME = ""
params.outdir = 'results'  


if (!params.inputparam1){params.inputparam1 = ""} 
if (!params.inputparam2){params.inputparam2 = ""} 
if (!params.inputparam){params.inputparam = ""} 

Channel.value(params.inputparam1).set{g_4_1_g_9}
if (params.inputparam){
Channel
	.fromFilePairs( params.inputparam , size: params.mate == "single" ? 1 : params.mate == "pair" ? 2 : params.mate == "triple" ? 3 : params.mate == "quadruple" ? 4 : -1 )
	.ifEmpty { error "Cannot find any reads matching: ${params.inputparam}" }
	.set{g_11_0_g_9}
 } else {  
	g_11_0_g_9 = Channel.empty()
 }



process align {

input:
 set val(name),file(reads) from g_11_0_g_9
 val mate from g_4_1_g_9

output:
 set val(name), file("${name}_aligned_reads.bam")  into g_9_bam_file00_g_10

script:

readGroup = "@RG\\tID:${name}\\tLB:${name}\\tPL:${params.pl}\\tPM:${params.pm}\\tSM:${name}"

"""
    bwa mem \
	-K 100000000 \
	-v 3 \
	-t 1 \
	-Y \
	-R '${readGroup}' \
	${ref} \
	${reads} \
	> ${name}_aligned_reads.sam
	
	samtools view -bS ${name}_aligned_reads.sam > ${name}_aligned_reads.bam 
"""
}


process getMetrics {

input:
 set val(name),file(sorted_dedup_reads) from g_9_bam_file00_g_10

output:
 file "${name}_alignment_metrics.txt"  into g_10_txtFile00
 file "${name}_insert_metrics.txt"  into g_10_txtFile11
 file "${name}_insert_size_histogram.pdf"  into g_10_outputFilePdf22
 file "${name}_depth_out.txt"  into g_10_txtFile33

errorStrategy 'retry'
maxRetries 1

when:
(params.run_Metrics && (params.run_Metrics == "yes")) || !params.run_Metrics

script:
"""
    picard \
       CollectAlignmentSummaryMetrics \
	   R=${ref} \
       I=${sorted_dedup_reads} \
	   O=${name}_alignment_metrics.txt
    picard \
        CollectInsertSizeMetrics \
        INPUT=${sorted_dedup_reads} \
	    OUTPUT=${name}_insert_metrics.txt \
        HISTOGRAM_FILE=${name}_insert_size_histogram.pdf 
    samtools depth -a ${sorted_dedup_reads} > ${name}_depth_out.txt
"""
}


workflow.onComplete {
println "##Pipeline execution summary##"
println "---------------------------"
println "##Completed at: $workflow.complete"
println "##Duration: ${workflow.duration}"
println "##Success: ${workflow.success ? 'OK' : 'failed' }"
println "##Exit status: ${workflow.exitStatus}"
}
