#!/bin/bash
#SBATCH -p short logs/find_missing_masked.log

CPU=1

INDIR=genomes
OUTDIR=genomes
SAMPFILE=samples.csv

N=1
IFS=,
tail -n +2 $SAMPFILE | while read SPECIES STRAIN PHYLUM BIOPROJECT BIOSAMPLE SRA LOCUS
do
  name=$(echo -n "$SPECIES $STRAIN" | perl -p -e 's/\s+/_/g')
  #echo "$name"
  if [ ! -f $INDIR/${name}.sorted.fasta ]; then
    echo -e "\tCannot find $name.sorted.fasta in $INDIR - may not have been run yet ($N)"
  elif [ ! -f $OUTDIR/${name}.masked.fasta ]; then
	 echo "need to run $name ($N)"
 fi
 N=$(expr $N + 1)
done

N=1

IFS=,
m=$(tail -n +2 $SAMPFILE | while read SPECIES STRAIN PHYLUM BIOPROJECT BIOSAMPLE SRA LOCUS
do
 name=$(echo -n ${SPECIES}_${STRAIN} | perl -p -e 's/\s+/_/g')
 if [[ -f $INDIR/${name}.sorted.fasta  && ! -f $OUTDIR/${name}.masked.fasta ]]; then
         echo -n "$N,"
 fi
 N=$(expr $N + 1)
done | perl -p -e 's/,$//')

echo "sbatch --array=$m pipeline/00_mask_denovo.sh"
