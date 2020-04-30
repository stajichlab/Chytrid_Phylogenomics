#!/usr/bin/bash

OUTDIR=pep
mkdir -p $OUTDIR
cat lib/downloads.txt | while read PREF OUTNAME URL
do
  if [ ! -f $OUTDIR/$OUTNAME ]; then
    curl $URL | pigz -dc | perl scripts/get_longest.pl -p $PREF > $OUTDIR/$OUTNAME
  fi
done
