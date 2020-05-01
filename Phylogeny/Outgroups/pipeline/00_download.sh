#!/usr/bin/bash
module unload perl
OUTDIR=pep
mkdir -p $OUTDIR
cat lib/downloads.tsv | while read PREF OUTNAME URL
do
  if [ ! -s $OUTDIR/$OUTNAME ]; then
    curl $URL | pigz -dc | perl scripts/get_longest.pl -p $PREF > $OUTDIR/$OUTNAME
  fi
done
