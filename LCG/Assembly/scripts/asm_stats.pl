#!/usr/bin/perl
#
use File::Spec;
use strict;
use warnings;

my %stats;


my $read_map_stat = 'mapping_report';
my $dir = shift || 'genomes';
my %cols;
my @header;
my %header_seen;

opendir(DIR,$dir) || die $!;
my $first = 1;
foreach my $file ( readdir(DIR) ) {
    next unless ( $file =~ /(\S+)(\.fasta)?\.stats.txt$/);
    my $stem = $1; 

    warn("$file ($dir)\n");
    open(my $fh => "$dir/$file") || die "cannot open $dir/$file: $!";
    while(<$fh>) {
	next if /^\s+$/;
	s/^\s+//;
	chomp;
	if ( /\s*(.+)\s+=\s+(\d+(\.\d+)?)/ ) {
	    my ($name,$val) = ($1,$2);	    
	    $name =~ s/\s*$//;
	    $stats{$stem}->{$name} = $val;
#	    warn("'$name'"," '", $val,"'\n");
	    $cols{$name}++;
	    if( ! exists $header_seen{$name} ) {
		push @header, $name;
		$header_seen{$name} = 1;
	    }
	}
    }
    if ( $first ) { 
	push @header, qw(BUSCO_Complete BUSCO_Single BUSCO_Duplicate
                 BUSCO_Fragmented BUSCO_Missing BUSCO_NumGenes
                 );
    }


    my $busco_file = File::Spec->catfile("BUSCO",sprintf("run_%s",$stem),
					 sprintf("short_summary_%s.txt",$stem));

    if ( $stem =~ /\.dipspades/ ) {
	$busco_file = File::Spec->catfile("BUSCO",sprintf("run_%s_consensus",$stem),
					     sprintf("short_summary_%s_consensus.txt",$stem));
    } 
#elsif ( $is_sorted ) {
#	$busco_file = File::Spec->catfile("BUSCO",sprintf("run_%s.sorted",$stem)#,
#					  sprintf("short_summary_%s.txt",$stem));
#
#    }

    if ( -f $busco_file ) {

	open(my $fh => $busco_file) || die $!;
	while(<$fh>) {	 
	    if (/^\s+C:(\d+\.\d+)\%\[S:(\d+\.\d+)%,D:(\d+\.\d+)%\],F:(\d+\.\d+)%,M:(\d+\.\d+)%,n:(\d+)/ ) {
		$stats{$stem}->{"BUSCO_Complete"} = $1;
		$stats{$stem}->{"BUSCO_Single"} = $2;
		$stats{$stem}->{"BUSCO_Duplicate"} = $3;
		$stats{$stem}->{"BUSCO_Fragmented"} = $4;
		$stats{$stem}->{"BUSCO_Missing"} = $5;
		$stats{$stem}->{"BUSCO_NumGenes"} = $6;
	    } 
	}

    } else {
	warn("Cannot find $busco_file");
    }

    my $fstem = $stem;
    
    my $is_sorted = ( $fstem =~ s/\.sorted_shovill/.shovill/ || $fstem =~ s/\.sorted// ) ? 1 : 0;
    warn("$fstem looking for file $fstem.bbmap_summary.txt\n");
    my $sumstatfile = File::Spec->catfile($read_map_stat,
				      sprintf("%s.bbmap_summary.txt",$fstem));
    if ( -f $sumstatfile ) {
	open(my $fh => $sumstatfile) || die "Cannot open $sumstatfile: $!";
	my $read_dir = 0;
	my $base_count = 0;
	$stats{$stem}->{'Mapped reads'} = 0;
	while(<$fh>) {
	    if( /Read (\d+) data:/) {
		$read_dir = $1;
	    } elsif( $read_dir && /^mapped:\s+(\S+)\s+(\d+)\s+(\S+)\s+(\d+)/) {
		$base_count += $4;
		$stats{$stem}->{'Mapped_reads'} += $2;
	    }  elsif( /^Reads(\s+Used)?:\s+(\S+)/) {
		$stats{$stem}->{'Reads'} = $2;
	    }
	    
	}
	$stats{$stem}->{'Pct_reads_mapped'} = sprintf("%.1f",100*$stats{$stem}->{'Mapped_reads'}/$stats{$stem}->{'Reads'});
	$stats{$stem}->{'Average_Coverage'} =
	    sprintf("%.1f",$base_count / $stats{$stem}->{'TOTAL LENGTH'});
	if( $first )  {
	    push @header, ('Reads',
			   'Mapped_reads',			   
			   'Pct_reads_mapped',
			   'Average_Coverage');
	}
    }
    
    $first = 0;
}

print join("\t", qw(SampleID), @header), "\n";
foreach my $sp ( sort keys %stats ) {    
    print join("\t", $sp, map { $stats{$sp}->{$_} || 'NA' } @header), "\n";
}
