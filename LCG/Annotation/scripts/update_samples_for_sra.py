#!/usr/bin/env python3

import csv, re, sys, os
import xml.etree.ElementTree as ET
from Bio import Entrez
Entrez.email = 'jason.stajich@ucr.edu'
insamples = "samples.csv"
outsamplesnew="samples.new.csv"
# the input format is specific to this chytrid project but it only
# really uses the STRAIN column to determine the strain to look for in NCBI
# BioProject / BioSample
# usage: query_biosample_prefix.py in_sample_file outsamples
# defaults:  in_sample_file = samples.csv
#            outsamples     = samples.new.csv

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

with open(insamples,"rU") as preprocess, open(outsamplesnew,"w",newline='\n') as outfh:
    outcsv    = csv.writer(outfh,delimiter=",")
    # the output columns will be the following
    outcsv.writerow(['SPECIES','STRAIN','PHYLUM',
                     'BIOSAMPLE','BIOPROJECT','SRA','LOCUSTAG'])

    incsv = csv.reader(preprocess,delimiter=",")
    h = next(incsv)
    for row in incsv:
        strain  = row[1]
        species = row[0]
        phylum  = row[2]
        biosampleid = row[3]
        if len(biosampleid) == 0:
            print("no Biosample for {} {}".format(species,strain))
            break
        bioproject = row[4]
        sra = row[5]
        locus = row[6]
        outrow = [ species,strain,phylum,biosampleid]


        # This is the part that does the magic for Entrez (NCBI) lookup
        # we essentially leave it that a strain alone is sufficient
        # for a lookup.

        # this is not going to work for multiple strains in the BioSample
        # database

        SRA = []
        BIOSAMPLE = biosampleid
        BIOPROJECT = ""
        LOCUSTAG = ""
        BIOPROJECTID=""

        handle = Entrez.efetch(db="biosample", id=biosampleid)
        tree = ET.parse(handle)
        root = tree.getroot()
        for sample in root:
            BIOSAMPLE = sample.attrib['accession']
            for ids in root.iter('Ids'):
                for id in ids.iter('Id'):
                    if 'db' in id.attrib and id.attrib['db'] == "SRA":
                        SRS = id.text
#                        print("SRA is {}".format(SRS))
                        srahandle = Entrez.esearch(db="sra", term=SRS)
                        srarecord = Entrez.read(srahandle)
                        srahandle.close()
                        for sraid in srarecord["IdList"]:
#                             print("sraid %s found for query '%s'"%(sraid,SRS))
                             srahandle = Entrez.efetch(db="sra", id=sraid)
                             sratree = ET.parse(srahandle)
                             sraroot = sratree.getroot()
                             for srainfo in sraroot:
                                 for sraruns in srainfo.iter('RUN_SET'):
                                     for run in sraruns.iter('RUN'):
                                        SRA.append(run.attrib['accession'])
#                                        print("SRA is {}".format(SRA))
#                                 print( 'accession is {}'.format(srainfo.attrib['accession']))

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
        outrow.extend([BIOPROJECT,";".join(SRA),LOCUSTAG])
        outcsv.writerow(outrow)
