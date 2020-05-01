#!/usr/bin/bash
#SBATCH --nodes 1 --ntasks 32 --mem 24gb --time 8:00:00 -p intel --out fasttree_run.%A.log

module load fasttree/2.1.11
module unload perl
module unload python
module load miniconda3
NUM=$(wc -l ../expected_prefixes.lst | awk '{print $1}')
source ../config.txt
HMM=JGI_1086
ALN=../$PREFIX.${NUM}_taxa.${HMM}.aa.fasaln
TREE1=$PREFIX.${NUM}_taxa.${HMM}.ft_lg.tre
TREE2=$PREFIX.${NUM}_taxa.${HMM}.ft_lg_long.tre

if [ ! -s $TREE1 ]; then
	FastTreeMP -lg -gamma < $ALN > $TREE1
	echo "ALN is $ALN"
	if [ -s $TREE1 ]; then
		perl ../PHYling_unified/util/rename_tree_nodes.pl $TREE1 ../prefix.tab > $TREE2
	fi
fi
