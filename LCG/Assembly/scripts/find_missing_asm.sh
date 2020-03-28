N=1
SAMPLEFILE=ploidy_target_assembly.csv
tail -n +2 $SAMPLEFILE | while read STRAIN GENUS SPECIES ASSEMBLER PHYLUM
do
    BASE=${GENUS}_${SPECIES}_${STRAIN}
    if [ ! -f genomes/$BASE.sorted.stats.txt ]; then
            echo "No genomes/$BASE.sorted.stats.txt ($N)"
    fi
    N=$(expr $N + 1)
done

m=$(tail -n +2 $SAMPLEFILE | while read STRAIN GENUS SPECIES ASSEMBLER PHYLUM
do
    BASE=${GENUS}_${SPECIES}_${STRAIN}
    if [ ! -f genomes/$BASE.sorted.stats.txt ]; then
	    echo -n "$N,"
    fi
    N=$(expr $N + 1)
done | perl -p -e 's/,$//')

echo "sbatch --array=$m pipeline/02_AAFTF.sh"
