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
	SORTED=$(realpath $ASM/${STRAIN}.sorted.fasta)
	LEFT=$(realpath $INDIR/${STRAIN}_R1.fq.gz)
	RIGHT=$(realpath $INDIR/${STRAIN}_R2.fq.gz)
	if [ ! -f $OUTDIR/$STRAIN.histo ]; then
		pigz -dc $LEFT $RIGHT > $TEMP/$STRAIN.reads.fq
		jellyfish count -C -m 21 -s 1000000000 -t $CPU $TEMP/$STRAIN.reads.fq -o $TEMP/$STRAIN.jf
		jellyfish histo -t $CPU $TEMP/$STRAIN.jf > $OUTDIR/$STRAIN.histo
		rm $TEMP/$STRAIN.reads.fq $TEMP/$STRAIN.jf
	fi
	for K in 23 27 31
	do
		if [ ! -f $OUTDIR/$STRAIN.$K.khist ]; then
			kmercountexact.sh k=$K in=$LEFT in2=$RIGHT khist=$OUTDIR/$STRAIN.$K.khist peaks=$OUTDIR/$STRAIN.$K.peaks
		fi
	done
done
