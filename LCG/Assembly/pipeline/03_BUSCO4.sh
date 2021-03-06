#!/bin/bash
#SBATCH --nodes 1 --ntasks 4 --mem 16G --time 36:00:00
#SBATCH --out logs/busco4.%a.log -J busco4

module load busco/4.0.5

# for augustus training
#export AUGUSTUS_CONFIG_PATH=/bigdata/stajichlab/shared/pkg/augustus/3.3/config
# set to a local dir to avoid permission issues and pollution in global
export AUGUSTUS_CONFIG_PATH=$(realpath augustus-BUSCO4/3.3/config)
echo $AUGUSTUS_CONFIG_PATH

CPU=${SLURM_CPUS_ON_NODE}
N=${SLURM_ARRAY_TASK_ID}
if [ ! $CPU ]; then
     CPU=2
fi

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi
if [ -z ${SLURM_ARRAY_JOB_ID} ]; then
	SLURM_ARRAY_JOB_ID=$$
fi
GENOMEFOLDER=genomes
ENDING=fasta
LINEAGE=/srv/projects/db/BUSCO/v10/lineages/fungi_odb10
OUTFOLDER=BUSCO4
mkdir -p $OUTFOLDER
SAMPLEFILE=ploidy_target_assembly.tsv
SEED_SPECIES="batrachochytrium_dendrobatidis_G2"
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read STRAIN GENUS SPECIES ASMTYPE PHYLUM
do
	LINEAGE=$(realpath $LINEAGE)
	if [ -d $AUGUSTUS_CONFIG_PATH/species/BUSCO_$STRAIN ]; then
	    SEED_SPECIES=BUSCO_$STRAIN
	fi
	for EXT in .sorted .sorted_shovill .spades .dipspades_consensus
	do
	    NAME=${STRAIN}${EXT}
	    GENOMEFILE=$(realpath $GENOMEFOLDER/$NAME.${ENDING})
	    if [ ! -s $GENOMEFILE ]; then
		echo "Skipping $NAME does not exist"
		continue
	    elif [ -d "$OUTFOLDER/${NAME}" ];  then
		echo "Already have run $STRAIN in folder busco - do you need to delete it to rerun?"
	    else
		if [[ $SEED_SPECIES == "BUSCO_$STRAIN" ]]; then
		    # already have run optimization
		    busco -in $GENOMEFILE -l $LINEAGE -o $NAME --out_path $OUTFOLDER \
			-m geno --cpu $CPU ---augustus_species $SEED_SPECIES --offline
		else
		    busco --in $GENOMEFILE -l $LINEAGE -o $NAME -m geno \
		     --cpu $CPU --augustus_species $SEED_SPECIES --long --offline --out_path $OUTFOLDER

		    rsync -av --progress ${NAME}/augustus_output/retraining_parameters/ $AUGUSTUS_CONFIG_PATH/species/BUSCO_$STRAIN/

		    for d in $(ls $AUGUSTUS_CONFIG_PATH/species/BUSCO_$STRAIN/*.cfg);
		    do
			m=$(echo $d | perl -p -e 's/_(\d+)_([^_]+).cfg/_$2.cfg/; s/\.sorted//g');
			mv $d $m
		    done
		    for d in $(ls $AUGUSTUS_CONFIG_PATH/species/BUSCO_$STRAIN/*.txt);
		    do
			       m=$(echo $d | perl -p -e 's/_(\d+)_([^_]+).txt/_$2.txt/; s/\.sorted//g');
		    done
		fi
	    fi
	done
done
rm -rf $TEMP
