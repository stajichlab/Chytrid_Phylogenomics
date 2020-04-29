n=1
SAMPLEFILE=ploidy_target_assembly.tsv
m=$(tail -n +2 $SAMPLEFILE | while read STRAIN GENUS SPECIES ASSEMBLER PHYLUM
do
    BASE=${GENUS}_${SPECIES}_${STRAIN}
    if [ ! -f mapping_report/$BASE.bbmap_covstats.txt ]; then
	echo -n "$n,"
    fi
    n=$(expr $n + 1);
done | perl -p -e 's/,$//')
echo "sbatch --array=$m pipeline/04_read_count.sh"
