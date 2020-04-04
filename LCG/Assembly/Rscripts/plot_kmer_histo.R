library(ggplot2)
library(gridExtra)
outdir="plots"
samples <- read.csv("ploidy_target_assembly.tsv",sep="\t",header=T)
samples$basename = paste(samples$Genus,samples$species,samples$ID,sep="_")
kmerfolder = "kmer_hist"
kmer=23
# based on shared plot code from Kevin Ames (amsesk@umich.edu)
plot_kmer <- function(prefix) {
  histfile = file.path(kmerfolder,paste(prefix,kmer,"khist",sep="."))
  peakfile =   file.path(kmerfolder,paste(prefix,kmer,"peaks",sep="."))
  hist <- read.table(histfile, col.names = c("depth", "rawcount", "count"), sep="\t")
  peaks = read.table(peakfile, comment.char = "#", col.names=c("start","center","stop","max","volume"), sep="\t")
  ggplot(hist) +
    geom_point(aes(x=depth, y=count)) +
    geom_line(aes(x=depth, y=count)) +
    ylim(0,max(hist$count)*1.25) +
    xlim(0,min(peaks$stop)*3.00) +
    geom_vline(xintercept = peaks[1,]$center, colour = "blue", alpha=0.5) +
    geom_vline(xintercept = peaks[2,]$center, colour = "blue", alpha=0.5) +
    ggtitle(paste(basename(prefix), ", ",kmer,"-mer histogram", sep=""))  
}
kmer=23
plots <- lapply(samples$basename,plot_kmer)
outplotfile <- file.path(outdir,"kmer_3up_plots.23.pdf")
ggsave(outplotfile, marrangeGrob(grobs = plots, nrow=3, ncol=3),width=15,height=15)

kmer=31
plots <- lapply(samples$basename,plot_kmer)
outplotfile <- file.path(outdir,"kmer_3up_plots.k31.pdf")
ggsave(outplotfile, marrangeGrob(grobs = plots, nrow=3, ncol=3),width=15,height=15)
