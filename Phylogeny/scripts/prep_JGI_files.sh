#!/bin/bash
#SBATCH -N 1 -n 1 --mem 2gb --out logs/download.log -p short
module unload perl
mkdir -p pep CDS
for file in $(ls jgi_download/cds/*.fasta.gz)
do
	base=$(basename $file .fasta.gz)
	base=$(echo $base | perl -p -e 's/_(GeneCatalog_|GeneModels_|Primary_Alleles_)\S+//')
	echo "$file $base"
	if [[ ! -s CDS/$base.cds.fasta || $file -nt CDS/$base.cds.fasta ]]; then
	    gzip -dc $file | perl -p -e 's/>jgi\|(\S+)\|(\d+)\|/>$1|$1_$2 /' > CDS/$base.cds.fasta
	    scripts/bp_translate_seq.pl CDS/$base.cds.fasta > pep/$base.aa.fasta
	fi
done
