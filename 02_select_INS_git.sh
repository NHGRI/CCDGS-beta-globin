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