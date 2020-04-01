#!/bin/bash
#SBATCH --nodes 1 --ntasks 24 --mem 128gb 
#SBATCH -J chytridShovill --out logs/AAFTF_shovill.%a.%A.log
#SBATCH -p intel --time 72:00:00
source ~/.bashrc
hostname
MEM=128
CPU=$SLURM_CPUS_ON_NODE
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi
if [ -z $CPU ]; then
    CPU=1
fi

module load AAFTF

OUTDIR=input
SAMPLEFILE=ploidy_target_assembly.tsv
ASM=genomes
TMPDIR=/scratch/$USER
WORKDIR=working_AAFTF
MINLEN=1000
mkdir -p $ASM $WORKDIR $TMPDIR

tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read STRAIN GENUS SPECIES ASMTYPE PHYLUM
do
    BASE=${GENUS}_${SPECIES}_${STRAIN}
    ASMFILE=$ASM/${BASE}.spades_shovill.fasta

    VECCLEAN=$ASM/${BASE}.vecscreen_shovill.fasta
    PURGE=$ASM/${BASE}.sourpurge_shovill.fasta
    CLEANDUP=$ASM/${BASE}.rmdup_shovill.fasta
    PILON=$ASM/${BASE}.pilon_shovill.fasta
    SORTED=$ASM/${BASE}.sorted_shovill.fasta
    STATS=$ASM/${BASE}.sorted_shovill.stats.txt

    LEFT=$WORKDIR/${BASE}_filtered_1.fastq.gz
    RIGHT=$WORKDIR/${BASE}_filtered_2.fastq.gz

    echo "$BASE"
    if [ ! -f $ASMFILE ]; then    
	if [ ! -f $LEFT ]; then
	    echo "Cannot find LEFT $LEFT or RIGHT $RIGHT - did you run"
	    echo "$OUTDIR/${BASE}_R1.fq.gz $OUTDIR/${BASE}_R2.fq.gz"
	    exit
	fi
	module unload miniconda2
	module load miniconda3
	module unload perl
	source activate shovill
	
	shovill --cpu $CPU --ram $MEM --outdir $WORKDIR/shovill_${BASE} \
	    --R1 $LEFT --R2 $RIGHT --nocorr --depth 90 --tmpdir $TMPDIR --minlen $MINLEN
	
	if [ -f $WORKDIR/shovill_${BASE}/contigs.fa ]; then
	    rsync -av $WORKDIR/shovill_${BASE}/contigs.fa $ASMFILE
	else	
	    echo "Cannot find $OUTDIR/shovill_${BASE}/contigs.fa"
	fi
	conda deactivate 
	
	if [ -s $ASMFILE ]; then
	    rm -rf $WORKDIR/shovill_${BASE}
	else
	    echo "SPADES must have failed, exiting"
	    exit
	fi
    fi

    if [ ! -f $VECCLEAN ]; then
	AAFTF vecscreen -i $ASMFILE -c $CPU -o $VECCLEAN 
    fi
    
    if [ ! -f $PURGE ]; then
	AAFTF sourpurge -i $VECCLEAN -o $PURGE -c $CPU --phylum $PHYLUM --left $LEFT  --right $RIGHT
    fi
    
    if [ ! -f $CLEANDUP ]; then
	AAFTF rmdup -i $PURGE -o $CLEANDUP -c $CPU -m 1000
    fi
    
    if [ ! -f $PILON ]; then
	AAFTF pilon -i $CLEANDUP -o $PILON -c $CPU --left $LEFT  --right $RIGHT 
    fi
    
    if [ ! -f $PILON ]; then
	echo "Error running Pilon, did not create file. Exiting"
	exit
    fi

    if [ ! -f $SORTED ]; then
	AAFTF sort -i $PILON -o $SORTED
    fi
    
    if [ ! -f $STATS ]; then
	AAFTF assess -i $SORTED -r $STATS
    fi
done
