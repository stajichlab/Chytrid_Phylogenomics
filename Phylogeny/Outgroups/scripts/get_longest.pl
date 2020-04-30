#!/usr/bin/env perl
use strict;
use Bio::SeqIO;
use Getopt::Long;

sub random_prefix {
  my @chars = ("A".."Z");
  my $string;
  $string .= $chars[rand @chars] for 1..6;
  return $string;
}
my $prefix = &random_prefix();
GetOptions('p|prefix:s' => \$prefix);

my $in = Bio::SeqIO->new(-format => 'fasta', -fh => \*ARGV);
my $out = Bio::SeqIO->new(-format => 'fasta');
my %seqs;
while(my $seq = $in->next_seq ){
  my $id = $seq->display_id;
  my $desc = $seq->description;
  my $locus;
  if ( $desc =~ /locus_tag=([^\]]+)\]/ || $desc =~ /protein_id=([^\]]+)\]/ ) {
    $locus = $1;
  } else {
      warn("no locus in $desc $id");
      $locus = $1;
  }
  if ( ! exists $seqs{$locus} || $seq->length > $seqs{$locus}->length ) {
    $seqs{$locus} = $seq;      # store longest isoform
  }
}

for my $seqname ( sort keys %seqs ) {
  my $seq = $seqs{$seqname};
  $seq->description(sprintf("%s %s",$seq->display_id, $seq->description));
  $seq->display_id(sprintf("%s|%s",$prefix,$seqname));
  $out->write_seq($seq);
}
