#!/bin/bash
#SBATCH --nodes 1 --ntasks 24 --mem 96gb -J AsmAAFTF
#SBATCH --out logs/AAFTF_asm.%a.%A.log -p intel --time 7-0:00:00

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
BESTFILE=best_assembly_choice.tsv
ASM=genomes

mkdir -p $ASM

if [ -z $CPU ]; then
    CPU=1
fi
WORKDIR=working_AAFTF
TEMPDIR=/scratch/$USER

mkdir -p $WORKDIR $TEMPDIR

tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read STRAIN GENUS SPECIES ASSEMBLER PHYLUM
do
    BASE=${GENUS}_${SPECIES}_${STRAIN}
    ASMTOOL=$ASSEMBLER

    LEFT=$WORKDIR/${STRAIN}_filtered_1.fastq.gz
    RIGHT=$WORKDIR/${STRAIN}_filtered_2.fastq.gz
    if [ ! -f $LEFT ]; then
      echo "Cannot find LEFT $LEFT or RIGHT $RIGHT - did you run"
      echo "$OUTDIR/${STRAIN}_R1.fq.gz $OUTDIR/${STRAIN}_R2.fq.gz"
      exit
    fi
    echo "running assemble for $STRAIN"

    if [[ ! -f $ASM/${STRAIN}.spades.fasta ]]; then
      #	module switch SPAdes/3.14.0

      mkdir -p $TEMPDIR
      AAFTF assemble -c $CPU --left $LEFT --right $RIGHT  \
	    -o $ASM/${STRAIN}.spades.fasta -w $TEMPDIR/spades_${STRAIN}_$$ --mem $MEM

	     if [ -f $ASM/${STRAIN}.spades.fasta ]; then
	        rm -rf $TEMPDIR/spades_${STRAIN}_$$
	       fi

	        AAFTF assess -i $ASM/${STRAIN}.spades.fasta -r $ASM/${STRAIN}.spades.stats.txt
    fi

    if [[ $ASSEMBLER == "dipspades" ]]; then
	     if [[  -s $ASM/${STRAIN}.${ASMTOOL}.fasta || -s $ASM/${STRAIN}.dipspades_consensus.fasta ]]; then
         echo "dipspades done -- not running dipspades $ASM/${STRAIN}.dipspades_conseneus.fasta"
         if [ ! -s $ASM/${STRAIN}.${ASMTOOL}.fasta ]; then
           rsync -a $ASM/${STRAIN}.dipspades_consensus.fasta $ASM/${STRAIN}.${ASMTOOL}.fasta
         fi
       else
         module switch SPAdes/3.11.1
         if [ -d $WORKDIR/dipspades_$STRAIN ]; then
           dipspades.py --threads $CPU --memory $MEM -o $WORKDIR/dipspades_$STRAIN --continue
         else
           dipspades.py -1 $LEFT -2 $RIGHT --threads $CPU --memory $MEM -o $WORKDIR/dipspades_$STRAIN --tmp-dir $TEMPDIR/dipspades_${STRAIN}
         fi

         if [ -f $WORKDIR/dipspades_$STRAIN/dipspades/consensus_contigs.fasta ]; then
           #	    rsync -a $WORKDIR/dipspades_$STRAIN/spades/scaffolds.fasta $ASM/${STRAIN}.spades.fasta
           rsync -a $WORKDIR/dipspades_$STRAIN/dipspades/consensus_contigs.fasta $ASM/${STRAIN}.dipspades_consensus.fasta
           rsync -a $WORKDIR/dipspades_$STRAIN/dipspades/paired_consensus_contigs.fasta $ASM/${STRAIN}.dipspades_consensus_paired.fasta
           rsync -a $WORKDIR/dipspades_$STRAIN/dipspades/unpaired_consensus_contigs.fasta $ASM/${STRAIN}.dipspades_consensus_unpaired.fasta

           rsync -a $ASM/${STRAIN}.dipspades_consensus.fasta $ASM/${STRAIN}.${ASMTOOL}.fasta
         fi
       fi
       AAFTF assess -i $ASM/${STRAIN}.${ASMTOOL}.fasta -r $ASM/${STRAIN}.${ASMTOOL}.stats.txt
    fi

    for ASMTOOL in spades dipspades
    do
      ASMFILE=$ASM/${STRAIN}.$ASMTOOL.fasta
      if [ -f $ASMFILE ]; then
        echo "processing $ASMFILE for $ASMTOOL"
      else
        echo "Cannot process $ASMFILE does not exist for $ASMTOOL"
        continue
      fi
      VECCLEAN=$ASM/${STRAIN}.${ASMTOOL}_vecscreen.fasta
      PURGE=$ASM/${STRAIN}.${ASMTOOL}_sourpurge.fasta
      CLEANDUP=$ASM/${STRAIN}.${ASMTOOL}_rmdup.fasta
      PILON=$ASM/${STRAIN}.${ASMTOOL}_pilon.fasta
      SORTED=$ASM/${STRAIN}.${ASMTOOL}_sorted.fasta
      STATS=$ASM/${STRAIN}.${ASMTOOL}_sorted.stats.txt

      if [[ ! -s $VECCLEAN || $ASMFILE -nt $VECCLEAN ]]; then
        AAFTF vecscreen -i $ASMFILE -c $CPU -o $VECCLEAN
      fi

      if [[ ! -s $PURGE || $VECCLEAN -nt $PURGE ]]; then
        AAFTF sourpurge -i $VECCLEAN -o $PURGE -c $CPU --phylum $PHYLUM --left $LEFT  --right $RIGHT
      fi

      if [[ ! -s $CLEANDUP || $PURGE -nt $CLEANDUP ]]; then
        AAFTF rmdup -i $PURGE -o $CLEANDUP -c $CPU -m 1000
      fi

      if [[ ! -s $PILON || $CLEANDUP -nt $PILON ]]; then
        AAFTF pilon -i $CLEANDUP -o $PILON -c $CPU --left $LEFT  --right $RIGHT
      fi

      if [[ ! -s $PILON && ! -f $PILON.gz ]]; then
        echo "Error running Pilon, did not create file. Exiting"
        exit
      fi

      if [[ ! -s $SORTED || $PILON -nt $SORTED ]]; then
        AAFTF sort -i $PILON -o $SORTED
      fi

      if [[ ! -f $STATS || $SORTED -nt $STATS ]]; then
        AAFTF assess -i $SORTED -r $STATS
      fi
    done
done
