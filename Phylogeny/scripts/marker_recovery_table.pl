#!/usr/bin/env perl
use strict;
use warnings;

my %table;
my %lookup;

open(my $fh => "prefix.tab" ) || die $!;
while(<$fh>) {
    my ($p,$l) = split;
    $lookup{$p} = $l;
}
my @markers = qw(JGI_1086 fungi_odb9 fungi_odb10);
foreach my $D ( @markers ) {

    my $dir = "search/$D";

    opendir(DIR,$dir) || die $!;
    foreach my $file ( readdir(DIR) ) {
	     next unless $file =~ /(\S+)\.best/;
	     my $stem = $1;
	     open(my $fh => "$dir/$file") || die $!;
    	 my $n = 0;
	     while(<$fh>) {
         # later lets capture the matrix of markers that are retrieved
	        $n++;
	       }
#    warn " $stem \n";
	  $table{$lookup{$stem} || $stem}->{$D} = $n;
    }
  }
  print join("\t", qw(SPECIES),@markers), "\n";
  foreach my $sp ( sort keys %table ) {
	   print join("\t",($sp, map { $table{$sp}->{$_} || 0 } @markers)), "\n";
  }
