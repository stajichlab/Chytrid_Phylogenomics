#!/bin/bash
#SBATCH --nodes 1 --ntasks 16 --mem 128gb -p batch -J FilterAAFTF --out logs/AAFTF_filter.%a.%A.log --time 36:00:00

hostname
MEM=128

CPU=$SLURM_CPUS_ON_NODE
N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi

module load AAFTF

OUTDIR=input
SAMPLEFILE=ploidy_target_assembly.tsv
ASM=genomes
mkdir -p $ASM

if [ -z $CPU ]; then
    CPU=1
fi
WORKDIR=working_AAFTF
mkdir -p $WORKDIR

TMPTRIM=/scratch/${USER}_trim_$$
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read STRAIN GENUS SPECIES ASMTYPE PHYLUM
do
	BASE=${GENUS}_${SPECIES}_${STRAIN}

	ASMFILE=$ASM/${STRAIN}.spades.fasta
	VECCLEAN=$ASM/${STRAIN}.vecscreen.fasta
	PURGE=$ASM/${STRAIN}.sourpurge.fasta
	CLEANDUP=$ASM/${STRAIN}.rmdup.fasta
	PILON=$ASM/${STRAIN}.pilon.fasta
	SORTED=$ASM/${STRAIN}.sorted.fasta
	STATS=$ASM/${STRAIN}.sorted.stats.txt
	LEFTTRIM=$TMPTRIM/${STRAIN}_1P.fastq.gz
	RIGHTTRIM=$TMPTRIM/${STRAIN}_2P.fastq.gz

	LEFT=$WORKDIR/${STRAIN}_filtered_1.fastq.gz
	RIGHT=$WORKDIR/${STRAIN}_filtered_2.fastq.gz
	mkdir -p $WORKDIR $TMPTRIM
	echo "$STRAIN"
	if [[ ! -f $ASMFILE || ! -f $SORTED ]]; then
	    if [ ! -f $LEFT ]; then
		echo "$OUTDIR/${STRAIN}_R1.fq.gz $OUTDIR/${STRAIN}_R2.fq.gz"
		#if [ ! -f $LEFTTRIM ]; then
		echo "Running Trim on $OUTDIR/${STRAIN}_R1.fq.gz and $OUTDIR/${STRAIN}_R2.fq.gz"
		rsync -a -v $OUTDIR/${STRAIN}_R1.fq.gz $OUTDIR/${STRAIN}_R2.fq.gz $TMPTRIM
		AAFTF trim --method bbduk --memory $MEM --left $TMPTRIM/${STRAIN}_R1.fq.gz --right $TMPTRIM/${STRAIN}_R2.fq.gz -c $CPU -o $TMPTRIM/${STRAIN}
		#AAFTF trim --method bbduk --memory $MEM --left $OUTDIR/${STRAIN}_R1.fq.gz --right $OUTDIR/${STRAIN}_R2.fq.gz -c $CPU -o $WORKDIR/${BASE}
		AAFTF filter -c $CPU --memory $MEM -o $TMPTRIM/${STRAIN} --left $LEFTTRIM --right $RIGHTTRIM --aligner bbduk
		echo "$LEFT $RIGHT"
		if [ -f $TMPTRIM/$(basename $LEFT) ]; then
		    rsync -av $TMPTRIM/$(basename $LEFT) $LEFT
		    rsync -av $TMPTRIM/$(basename $RIGHT) $RIGHT
		    rm -rf $TMPTRIM
		else
		    echo "Error in AAFTF filter"
		fi
	    fi
	fi
done
