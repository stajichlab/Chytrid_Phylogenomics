#!/usr/bin/bash
#SBATCH -p short

OUTDIR=manual/Paraphelidium
mkdir -p $OUTDIR
pushd $OUTDIR
curl -L https://ndownloader.figshare.com/files/13564436 | tar zxf -
perl -p -e 's/>(\S+)\|(\S+)/>PTRIB|$2 $1/' Commun_Biol_2018_aphelid_datasets/transcriptome/Par_tr_st_mkc2_trinity.fasta.transdecoder.pep > ../Paraphelidium_tribonemae_X-108.Trinity.aa.fasta
popd
