# Hi-C-analysis-pipeline

#!/bin/tcsh

### need to fix hotspot_to_bedfile.pl, it will replace the whatever bed file with the same chr

set BWA = /mnt/thumper/home/jdixon/software/bwa-0.5.9/bwa
set FASTA = /mnt/thumper/home/jdixon/database/human/hg18.fa
set DIR = /mnt/thumper/solexa/runs/individual_runs/2011_02_10_HiSeq_PE_flowcell-B/fastq_files/

# This is to map the reads using bwa, also, in this version, the FASTA genome file is set to human,
# The alternative is /mnt/thumper/home/jdixon/database/mouse/mm9.fa 

echo "Mapping Read 1 now" >> mapping_master_log_file
($BWA aln $FASTA $DIR/lane7_read1.trim.fastq > lane7_read1.aln.sai) >&! mapping_log_file
#1 processor memory usage???
echo "Mapping Read 2 now" >> mapping_master_log_file
($BWA aln $FASTA $DIR/lane7_read2.trim.fastq > lane7_read2.aln.sai) >&! mapping_log_file
echo "Running Sampe now" >> mapping_master_log_file
($BWA sampe $FASTA lane7_read1.aln.sai lane7_read2.aln.sai $DIR/lane7_read1.trim.fastq $DIR/lane7_read2.trim.fastq > lane7.sam) >&! mapping_log_file

# the above mapping takes roughly 10 hours or so, result is lane2.sam 
#get uniq mapped reads, will get monoclonal later, the output is *.unique
./sam_uniq_reads.pl lane2.sam

#we should combine them together, something like this:
# ./sam_uniq_reads.pl lane2.sam | samtools view -bS -o lane7.unique.bam - | samtools sort - lane7.unique.sorted 
#the lane2.sam is just the mapping result, lane2.sam.uniq (uniq reads), will 
#generate monoclonal reads later
samtools view -bS -o lane7.unique.bam lane7.sam.unique
#get basic stats

# sort the bam file, samtools sort will automatically append the ".bam" on the end of the file.

samtools sort lane7.unique.bam lane7.unique.sorted

# use the next three lines to remove duplicates using picard MarkDuplicates
# by product is metrics.lane7.txt

set JAVA = "java -Xmx6g -jar"
set RMDUPS = /mnt/thumper/home/ghon/mysoftware/picard-tools-1.43/MarkDuplicates.jar

$JAVA $RMDUPS INPUT=lane7.unique.sorted.bam OUTPUT=lane7.nodup.bam METRICS_FILE=metrics.lane7.txt ASSUME_SORTED=true REMOVE_DUPLICATES=true VALIDATION_STRINGENCY=LENIENT

#Now have monoclonal reads in lane2.nodup.bam

# Index the sam file, by-product is *.bai appended on.
samtools index lane7.nodup.bam # this is fast only take a few minuts
#NOW, we have some statistics
./total_stats.pl lane2.uniq.bam 20000 lane2.uniq.stat
###uniq or cortex_R2.nodup.bam???

# Make a matrix: the output is like this: chr1	9000000	10000000	0	0	0	140	240	194	451	974	1282
# examples: J1.hind.ori.matrix
# also the ones in yin's folder

/mnt/thumper/home/jdixon/HiC/Gary/get_matrix.pl
/mnt/thumper/home/jdixon/HiC/Gary/new_get_matrix.pl

Usage: ./get_matrix.pl <bam file> <bin size> <chr> <genome size file>
./get_matrix.pl lane2.nodup.bam 1000000 chr19 /mnt/thumper/home/jdixon/HiC/Gary/mm9.fa.fai > chr19.1m.matrix
set GSIZE = /mnt/thumper/home/jdixon/HiC/Gary/mm9.fa.fai


# if you want to merge bam/sam files, use picard program MergeSamFiles.jar

set JAVA = "java -Xmx6g -jar"
set MERGE = /mnt/thumper/home/ghon/mysoftware/picard-tools-1.43/MergeSamFiles.jar

$JAVA $MERGE INPUT=[first lane] INPUT=[second lane] [...] OUTPUT=Yin.cortex.merged.bam VALIDATION_STRINGENCY=LENIENT

# re-remove PCR duplicates if the samples are different lanes of sequencing of the same library

# correlate two file: Outputs as 5 columns: Row, column, Distance, counts sample 1, counts sample 2

/mnt/thumper/home/jdixon/HiC/merged/correlation_counts.pl

# load into R and calculate pearson for columns 4 and 5.

#get hotspot
./spot_matrix.pl # seems like this is a internediate file
./hostspot_matrix.pl


**************** on 1017-2011 remove *.uniq, because it is th same as uniq.bam
Also convert the orignal sam to bam to save space
