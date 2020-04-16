#!/usr/bin/env python3

import csv, re, sys, os
import xml.etree.ElementTree as ET
from Bio import Entrez
Entrez.email = 'jason.stajich@ucr.edu'
insamples = "../Assembly/ploidy_target_assembly.tsv"
outsamples="samples.csv"

# the input format is specific to this chytrid project but it only
# really uses the STRAIN column to determine the strain to look for in NCBI
# BioProject / BioSample
# usage: query_biosample_prefix.py in_sample_file outsamples
# defaults:  in_sample_file = ../Assembly/ploidy_target_assembly.tsv
#            outsamples     = samples.csv

# in_samplefile is expected to have the followng columns and be tab delimited
#ID	Genus	species	assembly_method	Phylum
#ID==STRAIN

if len(sys.argv) > 1:
    insamples = sys.argv[1]

if len(sys.argv) > 2:
    outsamples = sys.argv[2]

seen = {}
# to deal with crashes and re-running, this first reads in an existing
# sample.csv file and populates the dictionary with that info first
# so it can pick up where it left off or deal with hard-coded values
if os.path.exists(outsamples):
    with open(outsamples,"rU") as preprocess:
        incsv = csv.reader(preprocess,delimiter=",")
        h = next(incsv)
        for row in incsv:
            seen[row[0]] = row

# read the in_sample file and also set up the output
with open(insamples,"rU") as infh, open(outsamples,"w",newline='\n') as outfh:
    outcsv    = csv.writer(outfh,delimiter=",")
    # the output columns will be the following
    outcsv.writerow(['SPECIES','STRAIN','PHYLUM',
                     'BIOSAMPLE','BIOPROJECT','SRA','LOCUSTAG'])

    samplescsv = csv.reader(infh,delimiter="\t")
    header = next(samplescsv)
    for row in samplescsv:
        strain  = row[0]
        species = " ".join([row[1],row[2]])
        phylum  = row[4]
        outrow = [ species,strain,phylum]
        query = " ".join([species,strain])

        if strain in seen:
            outrow = seen[strain]
            outcsv.writerow(outrow)
            continue

        print("query for biosample is %s"%(query))
        # This is the part that does the magic for Entrez (NCBI) lookup
        # we essentially leave it that a strain alone is sufficient
        # for a lookup.

        # this is not going to work for multiple strains in the BioSample
        # database

        handle = Entrez.esearch(db="biosample",retmax=10,term=strain)
        record = Entrez.read(handle)
        handle.close()
        SRA = ""
        BIOSAMPLE = ""
        BIOPROJECT = ""
        LOCUSTAG = ""
        BIOPROJECTID=""

        for biosampleid in record["IdList"]:
            print("biosample %s found for query '%s'"%(biosampleid,strain))
            handle = Entrez.efetch(db="biosample", id=biosampleid)
            tree = ET.parse(handle)
            root = tree.getroot()
            for sample in root:
                BIOSAMPLE = sample.attrib['accession']
                for ids in root.iter('Ids'):
                    for id in ids.iter('Id'):
                        if 'db' in id.attrib and id.attrib['db'] == "SRA":
                            SRA = id.text
                for links in root.iter('Links'):
                    for link in links:
                        linkdat = link.attrib
                        if linkdat['type'] == 'entrez':
                            BIOPROJECT = linkdat['label']
                            BIOPROJECTID = link.text
        if BIOPROJECTID:
            bioproject_handle = Entrez.efetch(db="bioproject",id = BIOPROJECTID)
            projtree = ET.parse(bioproject_handle)
            projroot = projtree.getroot()

            lt = projroot.iter('LocusTagPrefix')
            for locus in lt:
                LOCUSTAG = locus.text
        outrow.extend([BIOSAMPLE,BIOPROJECT,SRA,LOCUSTAG])
        outcsv.writerow(outrow)
