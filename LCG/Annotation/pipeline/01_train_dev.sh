#!/bin/bash -l

#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --mem 64gb -p intel
#SBATCH --time=3-00:15:00
#SBATCH --output=logs/train.%a.log
#SBATCH --job-name="TrainFun"

# Define program name
PROGNAME=$(basename $0)
echo "PROGRAM is $PROGNAME"
# Load software
#module load funannotate/development
module load funannotate/development
source activate funannotate
module switch trinity-rnaseq/2.10.0
module list
MEM=64G

#export SINGULARITY_BINDPATH=/bigdata,/bigdata/operations/pkgadmin/opt/linux:/opt/linux
export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
# Set some vars
export FUNANNOTATE_DB=/bigdata/stajichlab/shared/lib/funannotate_db
#export SINGULARITYENV_PASACONF=/rhome/jstajich/pasa.CONFIG
export PASAHOMEPATH=$(dirname `which Launch_PASA_pipeline.pl`)
export TRINITY=$(realpath `which Trinity`)
export TRINITYHOMEPATH=$(dirname $TRINITY)
export PASACONF=/rhome/jstajich/pasa.config.txt

# Determine CPUS
if [[ -z ${SLURM_CPUS_ON_NODE} ]]; then
    CPUS=1
else
    CPUS=${SLURM_CPUS_ON_NODE}
fi


N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
ODIR=annotate
INDIR=genomes
RNAFOLDER=lib/RNASeq
SAMPLEFILE=samples.csv
IFS=,
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read SPECIES STRAIN PHYLUM BIOSAMPLE BIOPROJECT SRA LOCUSTAG WGS
do
    echo "SPECIES is $SPECIES"
    SPECIESNOSPACE=$(echo -n "$SPECIES" | perl -p -e 's/\s+/_/g')
    if [[ ! -d $RNAFOLDER/$SPECIESNOSPACE || ! -f $RNAFOLDER/$SPECIESNOSPACE/Forward.fq.gz ]]; then
	echo "For training step Need RNASeq files in folder  $RNAFOLDER/$SPECIESNOSPACE as  $RNAFOLDER/$SPECIESNOSPACE/Forward.fq.gz and  $RNASEQ/$SPECIESNOSPACE/Reverse.fq.gz"
	exit
    fi
    BASE=$(echo -n "$SPECIES $STRAIN" | perl -p -e 's/\s+/_/g')
    echo "sample is $BASE"
    MASKED=$(realpath $INDIR/$BASE.masked.fasta)
    if [ ! -f $MASKED ]; then
	echo "Cannot find $BASE.masked.fasta in $INDIR - may not have been run yet"
	exit
    fi

    echo $ODIR/$BASE/training
    funannotate train -i $MASKED -o $ODIR/$BASE \
   	--jaccard_clip --species "$SPECIES" --isolate $STRAIN \
	  --cpus $CPUS --memory $MEM \
	  --left $RNAFOLDER/$SPECIESNOSPACE/Forward.fq.gz --right $RNAFOLDER/$SPECIESNOSPACE/Reverse.fq.gz
done
