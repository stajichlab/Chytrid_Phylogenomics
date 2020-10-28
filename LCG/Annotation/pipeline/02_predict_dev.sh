#!/bin/bash
#SBATCH -p batch --time 3-0:00:00 --ntasks 16 --nodes 1 --mem 24G --out logs/predict-dev.%a.log
# Define program name
PROGNAME=$(basename $0)
hostname
# Load software

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

BUSCO=fungi_odb10
INDIR=genomes
OUTDIR=annotate
PREDS=$(realpath prediction_support)
mkdir -p $OUTDIR
SAMPFILE=samples.csv
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=`wc -l $SAMPFILE | awk '{print $1}'`

if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPFILE"
    exit
fi

module unload miniconda2
module unload miniconda3
module load funannotate/development
module unload perl
module unload python
source activate funannotate
module load phobius
module load diamond
module load genemarkESET/4.57

export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
export FUNANNOTATE_DB=/bigdata/stajichlab/shared/lib/funannotate_db
# make genemark key link required to run it
if [ ! -s ~/.gm_key ]; then
	GMFOLDER=`dirname $(which gmhmme3)`
  	ln -s $GMFOLDER/.gm_key ~/.gm_key
fi
IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read SPECIES STRAIN PHYLUM BIOSAMPLE BIOPROJECT SRA LOCUSTAG WGS
do
    SEQCENTER=JGI
    if [[ ! -z $BIOPROJECT ]]; then
      SEQCENTER=UMichigan
    fi
    BASE=$(echo -n "$SPECIES $STRAIN" | perl -p -e 's/\s+/_/g')
    echo "$BASE"
    MASKED=$(realpath $INDIR/$BASE.masked.fasta)
    if [ ! -f $MASKED ]; then
      echo "Cannot find $BASE.masked.fasta in $INDIR - may not have been run yet"
      exit
    fi
   SEED_SPECIES=rhizophydium_sp._jel0838
   if [[ $PHYLUM == "Chytridiomycota" ]]; then
      SEED_SPECIES=rhizophydium_sp._jel0838
    if [[ $STRAIN == "CCIBt4013" ]]; then
      # special case
      mkdir $BASE.predict.$$
      pushd $BASE.predict.$$
      SEED_SPECIES=cladochytrium_tenue_ccibt4013_CRF
      funannotate predict --cpus $CPU --keep_no_stops --SeqCenter $SEQCENTER --busco_db $BUSCO \
          --strain $STRAIN --min_training_models 40 --AUGUSTUS_CONFIG_PATH $AUGUSTUS_CONFIG_PATH \
          -i ../$INDIR/$BASE.masked.fasta --name $LOCUSTAG --protein_evidence ../lib/informant.aa --augustus_species $SEED_SPECIES \
          -s "$SPECIES"  -o ../$OUTDIR/$BASE --genemark_gtf $PREDS/$BASE.genemark.gtf
      popd
      rmdir $BASE.predict.$$
      exit
    elif [[ $STRAIN == "JEL0829" ]]; then
	SEED_SPECIES=kappamyces_sp._jel0680
    fi
   elif [[ $PHYLUM == "Blastocladiomycota" ]]; then
     SEED_SPECIES=allomyces_arbuscula_burma_1f
    if [[ $SPECIES == "Coelomomyces lativittatus" ]]; then
	   SEED_SPECIES=coelomomyces_lativittatus_cirm-ava-1-amber
    fi
   fi
    echo "looking for $MASKED to run"
    echo "LOCUSTAG IS '$LOCUSTAG'"
# is this temp folder still needed?
    mkdir $BASE.predict.$$
    pushd $BASE.predict.$$
    if [[ -f $PREDS/$BASE.genemark.gtf ]]; then
      funannotate predict --cpus $CPU --keep_no_stops --SeqCenter $SEQCENTER --busco_db $BUSCO --optimize_augustus \
        --strain $STRAIN --min_training_models 40 --AUGUSTUS_CONFIG_PATH $AUGUSTUS_CONFIG_PATH \
        -i ../$INDIR/$BASE.masked.fasta --name $LOCUSTAG --protein_evidence ../lib/informant.aa \
        -s "$SPECIES"  -o ../$OUTDIR/$BASE --busco_seed_species $SEED_SPECIES --genemark_gtf $PREDS/$BASE.genemark.gtf
    else
    funannotate predict --cpus $CPU --keep_no_stops --SeqCenter $SEQCENTER --busco_db $BUSCO --optimize_augustus \
	--strain $STRAIN --min_training_models 40 --AUGUSTUS_CONFIG_PATH $AUGUSTUS_CONFIG_PATH \
	-i ../$INDIR/$BASE.masked.fasta --name $LOCUSTAG --protein_evidence ../lib/informant.aa \
	-s "$SPECIES"  -o ../$OUTDIR/$BASE --busco_seed_species $SEED_SPECIES
    fi
    popd
    rmdir $BASE.predict.$$
done
