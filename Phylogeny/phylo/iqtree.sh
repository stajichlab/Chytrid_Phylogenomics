#!/usr/bin/bash
#SBATCH -p short -N 1 -n 3 --mem 8gb -J iqtree

module load IQ-TREE

NUM=$(wc -l ../expected_prefixes.lst | awk '{print $1}')
source ../config.txt
ALN=../$PREFIX.${NUM}_taxa.JGI_1086.aa.fasaln
ln -s $ALN .
iqtree -s $ALN -pre $PREFIX.${NUM}_taxa.JGI_1086.IQT -nt 3 -bb 1000 -alrt 1000 -m TESTMERGE -o Rozal1_1
TREE1=$PREFIX.${NUM}_taxa.JGI_1086.IQT.treefile
TREE2=$PREFIX.${NUM}_taxa.JGI_1086.IQT.long.tre
perl ../PHYling_unified/util/rename_tree_nodes.pl $TREE1 ../prefix.tab > $TREE2
