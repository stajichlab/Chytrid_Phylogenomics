#!/usr/bin/bash
#SBATCH -p short -N 1 -n 5 --mem 32gb -J iqtree

module load iqtree/2.0.4

NUM=$(wc -l ../expected_prefixes.lst | awk '{print $1}')
source ../config.txt
HMM=fungi_odb9
ALN=../$PREFIX.${NUM}_taxa.$HMM.aa.fasaln
iqtree2 -s $ALN -pre $PREFIX.${NUM}_taxa.$HMM.IQT -nt AUTO -bb 1000 -alrt 1000 -m MFP -o Cowc
TREE1=$PREFIX.${NUM}_taxa.$HMM.IQT.treefile
TREE2=$PREFIX.${NUM}_taxa.$HMM.IQT.long.tre
perl ../PHYling_unified/util/rename_tree_nodes.pl $TREE1 ../prefix.tab > $TREE2
