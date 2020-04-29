#!/bin/bash
#SBATCH --nodes 1 --ntasks 4 --mem 16G --time 36:00:00 --out logs/busco.%a.log -J busco

module load busco

# for augustus training
#export AUGUSTUS_CONFIG_PATH=/bigdata/stajichlab/shared/pkg/augustus/3.3/config
# set to a local dir to avoid permission issues and pollution in global
export AUGUSTUS_CONFIG_PATH=$(realpath augustus/3.3/config)

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
LINEAGE=/srv/projects/db/BUSCO/v9/fungi_odb9
OUTFOLDER=BUSCO
TEMP=/scratch/${SLURM_ARRAY_JOB_ID}_${N}
mkdir -p $TEMP $OUTFOLDER
SAMPLEFILE=ploidy_target_assembly.tsv
SEED_SPECIES="batrachochytrium_dendrobatidis_G2"
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read STRAIN GENUS SPECIES ASMTYPE PHYLUM
do
	LINEAGE=$(realpath $LINEAGE)
	if [ -d $AUGUSTUS_CONFIG_PATH/species/BUSCO_$STRAIN ]; then
	    SEED_SPECIES=BUSCO_$STRAIN
	fi
	for EXT in .spades_sorted .sorted_shovill .dipspades_sorted .dipspades
	do
	    NAME=${STRAIN}${EXT}
	    GENOMEFILE=$(realpath $GENOMEFOLDER/$NAME.${ENDING})
	    if [ ! -s $GENOMEFILE ]; then
		echo "Skipping $NAME does not exist"
		continue
	    elif [ -d "$OUTFOLDER/run_${NAME}" ];  then
		echo "Already have run $STRAIN in folder busco - do you need to delete it to rerun?"
	    else
		pushd $OUTFOLDER
		# not sure if we should run --long re-training - it helps some but takes a lot longer
		run_BUSCO.py -i $GENOMEFILE -l $LINEAGE -o $NAME -m geno --cpu $CPU --tmp $TEMP -sp $SEED_SPECIES
		popd
	    fi
	done
done
rm -rf $TEMP
