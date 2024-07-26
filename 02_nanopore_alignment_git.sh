#!/bin/bash
# alignment of the ONT long reads sequencing data
# alignment from FASTQ
# writing the following onto stand alone script 02_run_guppy_aligner and run by sbatch

sinteractive --mem=100g --cpus-per-task=16 --time=18:00:00

# directories and paths
WORKDIR=/data/Hanserv/yxhan/ONT
cd $WORKDIR

REFFA=/data/Hanserv/Reference/T2T_CHM13/chm13v2.0.fa
REFBED=$WORKDIR/chm13_bedregion_chr.bed

module load guppy/6.5.7

sampleID_1=NA_WGA_2169_SCD_adaptive_2_6_24
sampleID_2=NA_WGA_9246_SCD_adaptive_2_6_24
sampleID_3=NA_WGA_9295_SCD_adaptive_2_6_24
sampleID_4=NA_WGA_NR12_SCD_adaptive_2_6_24

# adaptive sampling FASTQ data
fastq_pass_1=$WORKDIR/GridIONdata/SCD_Adaptive/NA_WGA_2169_SCD_adaptive_2_6_24/20240206_1305_X3_FAV24945_5a2a123e/fastq_pass/
fastq_pass_2=$WORKDIR/GridIONdata/SCD_Adaptive/NA_WGA_9246_SCD_adaptive_2_6_24/20240206_1305_X2_FAU93417_9f87dd7b/fastq_pass/
fastq_pass_3=$WORKDIR/GridIONdata/SCD_Adaptive/NA_WGA_9295_SCD_adaptive_2_6_24/20240206_1305_X1_FAU93891_553590e8/fastq_pass/
fastq_pass_4=$WORKDIR/GridIONdata/SCD_Adaptive/NA_WGA_NR12_SCD_adaptive_2_6_24/20240206_1305_X4_FAU93413_a0be6b55/fastq_pass/

# running guppy_aligner
for i in {1..4}; do
sampleID="sampleID_${i}"
fastq_pass="fastq_pass_${i}"
echo "guppy_aligner \
-i ${!fastq_pass} \
-s $WORKDIR/bam_t2t/${!sampleID} \
--align_type full \
--align_ref $REFFA \
--bam_out \
--index \
--worker_threads 8"
done >> ./Scripts/03_run_guppy_aligner_testing_v2_scd_repeat.swarm

swarm --file ./Scripts/03_run_guppy_aligner_testing_v2_scd_repeat.swarm --module guppy/6.5.7 -g 64 -t 12 --time 24:00:00

# merge the bam files
for i in {1..4}; do
sampleID="sampleID_${i}"
fileID=$(ls $WORKDIR/bam_t2t/${!sampleID}/*_0.bam | rev | cut -d/ -f1 | rev | cut -d_ -f1-3)
echo "samtools merge $WORKDIR/bam_t2t/${!sampleID}/${fileID}.merged.bam \
\`find $WORKDIR/bam_t2t/${!sampleID} -name ${fileID}*.bam | xargs\`"
done >> ./Scripts/03_run_bam_merge_testing_v2_scd_repeat.swarm

swarm --file ./Scripts/03_run_bam_merge_testing_v2_scd_repeat.swarm --module samtools -g 64 -t 12 --time 24:00:00

# index the bam files
for i in {1..4}; do
sampleID="sampleID_${i}"
fileID=$(ls $WORKDIR/bam_t2t/${!sampleID}/*_0.bam | rev | cut -d/ -f1 | rev | cut -d_ -f1-3)
echo "samtools index $WORKDIR/bam_t2t/${!sampleID}/${fileID}.merged.bam"
done >> ./Scripts/03_run_bam_index_testing_v2_scd_repeat.swarm

swarm --file ./Scripts/03_run_bam_index_testing_v2_scd_repeat.swarm --module samtools -g 64 -t 12 --time 24:00:00

# check the depth on ROI
for i in {1..4}; do
sampleID="sampleID_${i}"
fileID=$(ls $WORKDIR/bam_t2t/${!sampleID}/*_0.bam | rev | cut -d/ -f1 | rev | cut -d_ -f1-3)
echo "samtools depth -b $REFBED $WORKDIR/bam_t2t/${!sampleID}/${fileID}.merged.bam \
> $WORKDIR/depth/${!sampleID}_t2t_depth_region.txt"
done >> ./Scripts/05_bam_t2t_depth_region_v2_scd_repeat.swarm

swarm --file ./Scripts/05_bam_t2t_depth_region_v2_scd_repeat.swarm --module samtools -g 64 -t 12 --time 24:00:00

scp hany4@biowulf.nih.gov:/data/Hanserv/yxhan/ONT/depth/*2_6_24_t2t* .


# run sniffles directly submit through swarm job

sniffles -i /data/Hanserv/yxhan/ONT/bam_t2t/NA_WGA_2169_SCD_adaptive_2_6_24/FAV24945_pass_5a2a123e.merged.bam -v /data/Hanserv/yxhan/ONT/output_t2t/NA_WGA_2169_SCD_adaptive_2_6_24_sniffles.vcf
sniffles -i /data/Hanserv/yxhan/ONT/bam_t2t/NA_WGA_9246_SCD_adaptive_2_6_24/FAU93417_pass_9f87dd7b.merged.bam -v /data/Hanserv/yxhan/ONT/output_t2t/NA_WGA_9246_SCD_adaptive_2_6_24_sniffles.vcf
sniffles -i /data/Hanserv/yxhan/ONT/bam_t2t/NA_WGA_9295_SCD_adaptive_2_6_24/FAU93891_pass_553590e8.merged.bam -v /data/Hanserv/yxhan/ONT/output_t2t/NA_WGA_9295_SCD_adaptive_2_6_24_sniffles.vcf
sniffles -i /data/Hanserv/yxhan/ONT/bam_t2t/NA_WGA_NR12_SCD_adaptive_2_6_24/FAU93413_pass_a0be6b55.merged.bam -v /data/Hanserv/yxhan/ONT/output_t2t/NA_WGA_NR12_SCD_adaptive_2_6_24_sniffles.vcf

# submit swarm
swarm --file ./Scripts/06_run_sniffles_t2t_v2_scd_repeat.swarm --module sniffles --gres=lscratch:200 -g 100 -t 16 --verbose 1 --time 8:00:00 

# index vcf files
cd output_t2t

bcftools view 110722_WGA_2169_sniffles.vcf -Oz -o 110722_WGA_2169_sniffles.vcf.gz
bcftools view 110722_WGA_9246_sniffles.vcf -Oz -o 110722_WGA_9246_sniffles.vcf.gz
bcftools view 110722_WGA_9295_sniffles.vcf -Oz -o 110722_WGA_9295_sniffles.vcf.gz
bcftools view 110722_WGA_NR12_sniffles.vcf -Oz -o 110722_WGA_NR12_sniffles.vcf.gz

bcftools view NA_WGA_9246_SCD_adaptive_2_6_24_sniffles.vcf -Oz -o NA_WGA_9246_SCD_adaptive_2_6_24_sniffles.vcf.gz
bcftools view NA_WGA_9295_SCD_adaptive_2_6_24_sniffles.vcf -Oz -o NA_WGA_9295_SCD_adaptive_2_6_24_sniffles.vcf.gz
bcftools view NA_WGA_NR12_SCD_adaptive_2_6_24_sniffles.vcf -Oz -o NA_WGA_NR12_SCD_adaptive_2_6_24_sniffles.vcf.gz
bcftools view NA_WGA_2169_SCD_adaptive_2_6_24_sniffles.vcf -Oz -o NA_WGA_2169_SCD_adaptive_2_6_24_sniffles.vcf.gz

tabix NA_WGA_9246_SCD_adaptive_2_6_24_sniffles.vcf.gz
tabix NA_WGA_9295_SCD_adaptive_2_6_24_sniffles.vcf.gz
tabix NA_WGA_NR12_SCD_adaptive_2_6_24_sniffles.vcf.gz
tabix NA_WGA_2169_SCD_adaptive_2_6_24_sniffles.vcf.gz

# select read with variants
# manually picked from IGV 2169_ReadNames_IGV.txt
samtools view -h /data/Hanserv/yxhan/ONT/bam_t2t/NA_WGA_2169_SCD_adaptive_2_6_24/FAV24945_pass_5a2a123e.merged.bam \
-N 2169_ReadNames_IGV.txt \
-b > NA_WGA_2169_SCD_adaptive_2_6_24_selectedReads.bam

samtools index NA_WGA_2169_SCD_adaptive_2_6_24_selectedReads.bam

samtools view -h /data/Hanserv/yxhan/ONT/bam_t2t/NA_WGA_NR12_SCD_adaptive_2_6_24/FAU93413_pass_a0be6b55.merged.bam \
-N NR12_ReadName_IGV.txt \
-b > NA_WGA_NR12_adaptive_2_6_24_selectedReads.bam

samtools index NA_WGA_NR12_adaptive_2_6_24_selectedReads.bam


# select 1000+bp insertion reads only
INPUT2169=/data/Hanserv/yxhan/ONT/bam_t2t/NA_WGA_2169_SCD_adaptive_2_6_24/FAV24945_pass_5a2a123e.merged.bam
INPUT9246=/data/Hanserv/yxhan/ONT/bam_t2t/NA_WGA_9246_SCD_adaptive_2_6_24/FAU93417_pass_9f87dd7b.merged.bam
INPUTNR12=/data/Hanserv/yxhan/ONT/bam_t2t/NA_WGA_NR12_SCD_adaptive_2_6_24/FAU93413_pass_a0be6b55.merged.bam


samtools view -h $INPUT2169 \
| awk 'BEGIN {OFS="\t"} {if ($0 ~ /^@/) {print} else {split($6, ops, /[0-9]+/); split($6, lens, /[^0-9]+/); insert_len=0; for (i=1; i in ops; i++) {if (ops[i]=="I") {insert_len+=lens[i]}}; if (insert_len>=2000) {print}}}' \
| samtools view -bS - > NA_WGA_2169_SCD_adaptive_2_6_24_INS2kplus.bam

samtools view -h $INPUT9246 \
| awk 'BEGIN {OFS="\t"} {if ($0 ~ /^@/) {print} else {split($6, ops, /[0-9]+/); split($6, lens, /[^0-9]+/); insert_len=0; for (i=1; i in ops; i++) {if (ops[i]=="I") {insert_len+=lens[i]}}; if (insert_len>=2000) {print}}}' \
| samtools view -bS - > NA_WGA_9246_SCD_adaptive_2_6_24_INS2kplus.bam

samtools view -h $INPUTNR12 \
| awk 'BEGIN {OFS="\t"} {if ($0 ~ /^@/) {print} else {split($6, ops, /[0-9]+/); split($6, lens, /[^0-9]+/); insert_len=0; for (i=1; i in ops; i++) {if (ops[i]=="I") {insert_len+=lens[i]}}; if (insert_len>=2000) {print}}}' \
| samtools view -bS - > NA_WGA_NR12_SCD_adaptive_2_6_24_INS2kplus.bam


samtools index NA_WGA_2169_SCD_adaptive_2_6_24_INS2kplus.bam
samtools index NA_WGA_9246_SCD_adaptive_2_6_24_INS2kplus.bam
samtools index NA_WGA_NR12_SCD_adaptive_2_6_24_INS2kplus.bam

# select reads with insertion and in region of 
region="chr11:5285000-5293000"
INPUT2169=/data/Hanserv/yxhan/ONT/bam_t2t/NA_WGA_2169_SCD_adaptive_2_6_24/FAV24945_pass_5a2a123e.merged.bam
INPUTNR12=/data/Hanserv/yxhan/ONT/bam_t2t/NA_WGA_NR12_SCD_adaptive_2_6_24/FAU93413_pass_a0be6b55.merged.bam

# Extract reads with insertions in the specified region and convert to BAM format
samtools view -h $INPUT2169 $region | awk '($6 ~ /I/ || $1 ~ /^@/) {print $0}' | samtools view -Sb - > NA_WGA_2169_SCD_adaptive_2_6_24_INS_region.bam
samtools index NA_WGA_2169_SCD_adaptive_2_6_24_INS_region.bam
samtools view -c NA_WGA_2169_SCD_adaptive_2_6_24_INS_region.bam
#130932
#131890 (region="chr11:5284000-5295000")
samtools view -h $INPUTNR12 $region | awk '($6 ~ /I/ || $1 ~ /^@/) {print $0}' | samtools view -Sb - > NA_WGA_NR12_SCD_adaptive_2_6_24_INS_region.bam
samtools index NA_WGA_NR12_SCD_adaptive_2_6_24_INS_region.bam
samtools view -c NA_WGA_NR12_SCD_adaptive_2_6_24_INS_region.bam