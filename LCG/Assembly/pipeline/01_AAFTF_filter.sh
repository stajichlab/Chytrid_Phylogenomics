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

	ASMFILE=$ASM/${BASE}.spades.fasta
	VECCLEAN=$ASM/${BASE}.vecscreen.fasta
	PURGE=$ASM/${BASE}.sourpurge.fasta
	CLEANDUP=$ASM/${BASE}.rmdup.fasta
	PILON=$ASM/${BASE}.pilon.fasta
	SORTED=$ASM/${BASE}.sorted.fasta
	STATS=$ASM/${BASE}.sorted.stats.txt
	LEFTTRIM=$TMPTRIM/${BASE}_1P.fastq.gz
	RIGHTTRIM=$TMPTRIM/${BASE}_2P.fastq.gz

	LEFT=$WORKDIR/${BASE}_filtered_1.fastq.gz
	RIGHT=$WORKDIR/${BASE}_filtered_2.fastq.gz
	mkdir -p $WORKDIR $TMPTRIM
	echo "$BASE"
	if [[ ! -f $ASMFILE || ! -f $SORTED ]]; then    
	    if [ ! -f $LEFT ]; then
		echo "$OUTDIR/${BASE}_R1.fq.gz $OUTDIR/${BASE}_R2.fq.gz"
		#if [ ! -f $LEFTTRIM ]; then
		echo "Running Trim on $OUTDIR/${BASE}_R1.fq.gz and $OUTDIR/${BASE}_R2.fq.gz"
		rsync -a -v $OUTDIR/${BASE}_R1.fq.gz $OUTDIR/${BASE}_R2.fq.gz $TMPTRIM
		AAFTF trim --method bbduk --memory $MEM --left $TMPTRIM/${BASE}_R1.fq.gz --right $TMPTRIM/${BASE}_R2.fq.gz -c $CPU -o $TMPTRIM/${BASE}
		#AAFTF trim --method bbduk --memory $MEM --left $OUTDIR/${BASE}_R1.fq.gz --right $OUTDIR/${BASE}_R2.fq.gz -c $CPU -o $WORKDIR/${BASE}
		AAFTF filter -c $CPU --memory $MEM -o $TMPTRIM/${BASE} --left $LEFTTRIM --right $RIGHTTRIM --aligner bbduk
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
