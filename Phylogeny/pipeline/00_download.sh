#!/usr/bin/bash
#SBATCH -N 1 -n 1 --mem 2gb --out logs/download.log -p short
if [ ! -d HMM/JGI_1086 ]; then
    echo "need to download HMM/JGI_1086"
    exit
    curl -O https://github.com/1KFG/PHYling_HMMs_fungi/archive/v1.3.tar.gz
    tar zxf v1.3.tar.gz PHYling_HMMs_fungi-1.3/HMM/JGI_1086
    rm v1.3.tar.gz
    ln -s PHYling_HMMs_fungi-1.3/HMM HMM
    pigz -d HMM/JGI_1086/HMM3/*.gz
fi

# prepare translation

# bash scripts/prep_JGI_files.sh
module unload perl

BASE=Synchytrium_microbalum_JEL517
if [ ! -s pep/$BASE.aa.fasta ]; then
    if [ ! -s jgi_download/$BASE.cds.fasta.gz ]; then
	curl -o jgi_download/$BASE.cds.fasta.gz https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/006/535/985/GCF_006535985.1_ASM653598v1/GCF_006535985.1_ASM653598v1_cds_from_genomic.fna.gz
    fi
    pigz -dc jgi_download/$BASE.cds.fasta.gz | perl -p -e 's/>(\S+)\s+.*\[locus_tag=(([^\]]+)_\S+)\]/>$3|$2 $1/' > CDS/$BASE.cds.fasta
    scripts/bp_translate_seq.pl CDS/$BASE.cds.fasta > pep/$BASE.aa.fasta
fi


BASE=Synchytrium_endobioticum_MB42
if [ ! -s pep/$BASE.aa.fasta ]; then
    if [ ! -s jgi_download/$BASE.cds.fasta.gz ]; then
	curl -o jgi_download/$BASE.cds.fasta.gz https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/006/535/955/GCA_006535955.1_ASM653595v1/GCA_006535955.1_ASM653595v1_cds_from_genomic.fna.gz
    fi
    pigz -dc jgi_download/$BASE.cds.fasta.gz | perl -p -e 's/>(\S+)\s+.*\[locus_tag=(([^\]]+)_\S+)\]/>$3|$2 $1/' > CDS/$BASE.cds.fasta
    scripts/bp_translate_seq.pl CDS/$BASE.cds.fasta > pep/$BASE.aa.fasta
fi    


