#!/bin/bash
#SBATCH --nodes 1 --ntasks 24 --mem 96gb -J AsmAAFTF --out logs/AAFTF_asm.%a.%A.log -p intel --time 7-0:00:00

hostname
MEM=96
CPU=$SLURM_CPUS_ON_NODE
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
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

tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read STRAIN GENUS SPECIES ASSEMBLER PHYLUM
do
    BASE=${GENUS}_${SPECIES}_${STRAIN}
    ASMTOOL=$ASSEMBLER
    if [[ $ASSEMBLER == "NA" ]]; then	
	ASMTOOL="dipspades"
    fi
    
    ASMFILE=$ASM/${BASE}.asm_raw.fasta
    
    VECCLEAN=$ASM/${BASE}.vecscreen.fasta
    PURGE=$ASM/${BASE}.sourpurge.fasta
    CLEANDUP=$ASM/${BASE}.rmdup.fasta
    PILON=$ASM/${BASE}.pilon.fasta
    SORTED=$ASM/${BASE}.sorted.fasta
    STATS=$ASM/${BASE}.sorted.stats.txt

    LEFT=$WORKDIR/${BASE}_filtered_1.fastq.gz
    RIGHT=$WORKDIR/${BASE}_filtered_2.fastq.gz

    echo "$BASE"
    if [ ! -f $ASMFILE ]; then    
	if [ ! -f $LEFT ]; then
	    echo "Cannot find LEFT $LEFT or RIGHT $RIGHT - did you run"
	    echo "$OUTDIR/${BASE}_R1.fq.gz $OUTDIR/${BASE}_R2.fq.gz"
	    exit
	fi
	echo "running assemble for $BASE"
	if [[ $ASMTOOL == "dipspades" ]]; then
	    module switch SPAdes/3.11.1
	    if [ ! -f $WORKDIR/dipspades_$BASE/dipspades/consensus_contigs.fasta ]; then
		if [ -d $WORKDIR/dipspades_$BASE ]; then
		    dipspades.py --threads $CPU --memory $MEM -o $WORKDIR/dipspades_$BASE --continue
		else
	    	    dipspades.py -1 $LEFT -2 $RIGHT --threads $CPU --memory $MEM -o $WORKDIR/dipspades_$BASE
		fi
	    fi
	    if [ -f $WORKDIR/dipspades_$BASE/dipspades/consensus_contigs.fasta ]; then
		rsync -a $WORKDIR/dipspades_$BASE/spades/scaffolds.fasta $ASM/${BASE}.spades.fasta
		rsync -a $WORKDIR/dipspades_$BASE/dipspades/consensus_contigs.fasta $ASM/${BASE}.dipspades_consensus.fasta
		rsync -a $WORKDIR/dipspades_$BASE/dipspades/paired_consensus_contigs.fasta $ASM/${BASE}.dipspades_consensus_paired.fasta
		rsync -a $WORKDIR/dipspades_$BASE/dipspades/unpaired_consensus_contigs.fasta $ASM/${BASE}.dipspades_consensus_unpaired.fasta
		AAFTF assess -i $ASM/${BASE}.spades.fasta -r $ASM/${BASE}.spades.stats.txt
		AAFTF assess -i $ASM/${BASE}.dipspades_consensus.fasta -r $ASM/${BASE}.dipspades.stats.txt
		rsync -a $ASM/${BASE}.dipspades_consensus.fasta $ASMFILE
		# rm -rf $WORKDIR/dipspades_${BASE}
		if [[ $ASSEMBLER == "NA" ]]; then
		    echo "fix input file to specify dipspades or spades instead of NA"
		    echo "compare spades assembly success for the two files for $ASM/${BASE}.*.stats.txt"
		    exit
		fi
	    fi	
	else
	    AAFTF assemble -c $CPU --left $LEFT --right $RIGHT  \
		-o $ASMFILE -w $WORKDIR/spades_$BASE --mem $MEM
	    AAFTF assess -i $ASMFILE -r $ASM/${BASE}.spades.stats.txt
	    if [ -s $ASMFILE ]; then
		rm -rf $WORKDIR/spades_${BASE}
	    else
		echo "SPADES must have failed, exiting"
		exit
	    fi
	fi
    fi
    if [ ! -f $ASMFILE ]; then
	echo "No assembly from spades/dipspades ($ASMFILE) exiting"
	exit
    fi
    if [[ ! -f $VECCLEAN && ! -f $VECCLEAN.gz ]]; then
	AAFTF vecscreen -i $ASMFILE -c $CPU -o $VECCLEAN 
    fi
    
    if [[ ! -f $PURGE && ! -f $PURGE.gz ]]; then
	AAFTF sourpurge -i $VECCLEAN -o $PURGE -c $CPU --phylum $PHYLUM --left $LEFT  --right $RIGHT
    fi
    
    if [[ ! -f $CLEANDUP && ! -f $CLEANDUP.gz ]]; then
	AAFTF rmdup -i $PURGE -o $CLEANDUP -c $CPU -m 1000
    fi
    
    if [[ ! -f $PILON && ! -f $PILON.gz ]]; then
	AAFTF pilon -i $CLEANDUP -o $PILON -c $CPU --left $LEFT  --right $RIGHT 
    fi
    
    if [[ ! -f $PILON && ! -f $PILON.gz ]]; then
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
