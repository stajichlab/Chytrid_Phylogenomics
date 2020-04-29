n=1
tail -n +2 ploidy_target_assembly.tsv | while read STRAIN GENUS SPECIES ASSEMBLER PHYLUM; do 
	if [ ! -d BUSCO/run_${strain} ]; then echo "$n $strain"; fi; 
	n=$(expr $n + 1);
done
n=1
m=$(tail -n +2 ploidy_target_assembly.tsv | while read STRAIN GENUS SPECIES ASSEMBLER PHYLUM; do 
if [ ! -d BUSCO/run_${strain} ]; then echo "$n"; fi; 
n=$(expr $n + 1); 
done | perl -p -e 's/\n/,/' | perl -p -e 's/,$//')
echo "sbatch --array=$m pipeline/03_BUSCO.sh"

