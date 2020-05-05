#!/usr/bin/env perl
use strict;
use warnings;

use Bio::SeqIO;

my $in = Bio::SeqIO->new(-format => 'fasta', -file => shift);
my $out = Bio::SeqIO->new(-format=> 'fasta');

my %seqs;
while( my $seq = $in->next_seq ) {
    my $id = $seq->display_id;
    push @{$seqs{$id}}, $seq
}
for my $id ( keys %seqs ) {
    my @isoforms = sort { $b->length <=> $a->length } @{$seqs{$id}};
    $out->write_seq($isoforms[0])
}

