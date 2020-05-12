#!/usr/bin/bash
module unload perl
PEPDIR=pep
DNADIR=DNA
PEPEXT=aa.fasta
NTEXT=nt.fasta
mkdir -p $PEPDIR $DNADIR
cat lib/downloads.tsv | while read PREF OUTNAME PEPURL DNAURL
do
  if [ ! -s $PEPDIR/$OUTNAME.$PEPEXT ]; then
    curl $PEPURL | pigz -dc | perl scripts/get_longest.pl -p $PREF > $PEPDIR/$OUTNAME.$PEPEXT
  fi
  if [ ! -s $DNADIR/$OUTNAME.$NTEXT ]; then
	  curl -o $DNADIR/$OUTNAME.$NTEXT.gz $DNAURL
  fi
done
