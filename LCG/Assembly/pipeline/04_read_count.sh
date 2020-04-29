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
	LEFT=$(realpath $INDIR/${STRAIN}_R1.fq.gz)
	RIGHT=$(realpath $INDIR/${STRAIN}_R2.fq.gz)

	for ASMTOOL in spades_sorted dipspades_sorted sorted_shovill spades dipspades
	do
	    SORTED=$(realpath $ASM/${STRAIN}.$ASMTOOL.fasta)
	    PREFIX=${STRAIN}.$ASMTOOL
	    if [ ! -s $SORTED ]; then
		echo "Assembly not finished for $SORTED"
	    else
		if [[ ! -s $OUTDIR/${PREFIX}.bbmap_covstats.txt || $SORTED -nt $OUTDIR/${PREFIX}.bbmap_covstats.txt ]]; then
		    mkdir -p N$N.$$.bbmap
		    pushd N$N.$$.bbmap
		    bbmap.sh -Xmx${MEM}g ref=$SORTED in=$LEFT in2=$RIGHT \
			covstats=../$OUTDIR/${PREFIX}.bbmap_covstats.txt \
			statsfile=../$OUTDIR/${PREFIX}.bbmap_summary.txt
		    popd
		    rm -rf N$N.$$.bbmap
		fi
	    fi
	done
done
