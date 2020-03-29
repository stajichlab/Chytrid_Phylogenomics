#!/usr/bin/bash
#SBATCH --nodes 1 --ntasks 24 --mem 24G -p short -J readCount
#SBATCH --out logs/bbcount.%a.log --time 2:00:00

module load BBMap
hostname
MEM=24
CPU=$SLURM_CPUS_ON_NODE
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi

INDIR=input
SAMPLEFILE=ploidy_target_assembly.tsv
ASM=genomes
OUTDIR=mapping_report
	mkdir -p $OUTDIR
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read STRAIN GENUS SPECIES ASMTYPE PHYLUM
do
	BASE=${GENUS}_${SPECIES}_${STRAIN}
	SORTED=$(realpath $ASM/${BASE}.sorted.fasta)
	if [ ! -s $SORTED ]; then
	    echo "Assembly not finished for $SORTED"
	    exit
	fi
	LEFT=$(realpath $INDIR/${BASE}_R1.fq.gz)
	RIGHT=$(realpath $INDIR/${BASE}_R2.fq.gz)

	if [ ! -s $OUTDIR/${BASE}.bbmap_covstats.txt ]; then
	    mkdir -p N$N.$$.bbmap
	    pushd N$N.$$.bbmap
	    bbmap.sh -Xmx${MEM}g ref=$SORTED in=$LEFT in2=$RIGHT \
		covstats=../$OUTDIR/${BASE}.bbmap_covstats.txt \
		statsfile=../$OUTDIR/${BASE}.bbmap_summary.txt
	    popd
	    rm -rf N$N.$$.bbmap
	fi
done
