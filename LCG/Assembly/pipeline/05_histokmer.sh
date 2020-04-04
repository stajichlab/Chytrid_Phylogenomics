#!/usr/bin/bash
#SBATCH --nodes 1 --ntasks 16 --mem 32G -p short -J histokmer
#SBATCH --out logs/histokmer.%a.log --time 2:00:00

module load jellyfish
module load BBMap
hostname
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
OUTDIR=kmer_hist
TEMP=/scratch
mkdir -p $OUTDIR
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read STRAIN GENUS SPECIES ASMTYPE PHYLUM
do
	BASE=${GENUS}_${SPECIES}_${STRAIN}
	SORTED=$(realpath $ASM/${BASE}.sorted.fasta)
	LEFT=$(realpath $INDIR/${BASE}_R1.fq.gz)
	RIGHT=$(realpath $INDIR/${BASE}_R2.fq.gz)
	if [ ! -f $OUTDIR/$BASE.histo ]; then
		pigz -dc $LEFT $RIGHT > $TEMP/$BASE.reads.fq
		jellyfish count -C -m 21 -s 1000000000 -t $CPU $TEMP/$BASE.reads.fq -o $TEMP/$BASE.jf
		jellyfish histo -t $CPU $TEMP/$BASE.jf > $OUTDIR/$BASE.histo
		rm $TEMP/$BASE.reads.fq $TEMP/$BASE.jf
	fi
	for K in 23 27 31 
	do
		if [ ! -f $OUTDIR/$BASE.$K.khist ]; then
			kmercountexact.sh k=$K in=$LEFT in2=$RIGHT khist=$OUTDIR/$BASE.$K.khist peaks=$OUTDIR/$BASE.$K.peaks
		fi
	done
done
