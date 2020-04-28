#!/usr/bin/bash
#SBATCH --ntasks 24 --mem 16G --time 2:00:00 -p short -N 1 --out logs/phyling.%A.log

module load hmmer/3
module load python/3
module unload perl
module load parallel
if [ ! -f config.txt ]; then
	echo "Need config.txt for PHYling"
	exit
fi

source config.txt
if [ ! -z $HMM ]; then
	rm -rf aln/$HMM
fi
# probably should check to see if allseq is newer than newest file in the folder?
rm prefix.tab
./PHYling_unified/PHYling init
cat jgi_ref_names.tab >> prefix.tab
./PHYling_unified/PHYling search -q parallel
./PHYling_unified/PHYling aln -c -q parallel
module unload python
pushd phylo
sbatch --time 2:00:00 -p short fast_run.sh
