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
my $dir = "search/JGI_1086";

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
    $table{$lookup{$stem} || $stem} = $n
}
print join("\t", qw(SPECIES PHYLING_MARKER_RECOVERY)), "\n";
foreach my $sp ( sort keys %table ) {
    print join("\t",($sp, $table{$sp})), "\n";
}
