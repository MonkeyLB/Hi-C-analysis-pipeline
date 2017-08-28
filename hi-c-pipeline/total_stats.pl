#!/usr/bin/perl

use strict;

MAIN : {
    my ($bam_file, $thold, $name) = @ARGV;
    if ((not defined $bam_file) ||
	(not defined $thold) ||
	(not defined $name)) {
	die ("Usage: ./total_stats.pl <bam file> <threshold> <name>\n");
	}

    my $thresh = $thold;

    my $intra_less_counts;
    my $intra_more_counts;
    my $inter_counts;
    my $numb = 1000000;
    my $new_numb;
    open(SAMTOOLS, "samtools view $bam_file |") || die ("could not open samtools\n");
    while (my $line = <SAMTOOLS>) {
	if ($intra_less_counts + $intra_more_counts + $inter_counts == $new_numb + $numb) {
	# just a state update
	    print $new_numb . "\n";
	    $new_numb += $numb;
	} 
	chomp $line;
	my ($id, $d1, $chr_from, $loc_from, $d2, $d3, $chr_to, $loc_to) = split(/\t/, $line);
	if (($chr_to eq "=") && (abs($loc_from - $loc_to) < $thresh)) {
	    $intra_less_counts++;
        }
        if (($chr_to eq "=") && (abs($loc_from - $loc_to) >= $thresh)) {
	    $intra_more_counts++;
        }
        if ($chr_to ne "=") {
	    $inter_counts++;
	}
    }
    close(SAMTOOLS) || die ("could not close samtools\n");

    my $total = $intra_less_counts + $intra_more_counts + $inter_counts;
    my $intra_less_per = 100*$intra_less_counts/$total;
    my $intra_more_per = 100*$intra_more_counts/$total;
    my $inter_per = 100*$inter_counts/$total;
    
    open(MAIN, ">stats.$name");

    print MAIN (join("\t", "Total", "Intra Less", "Intra More", "Inter", "Intra Less %", "Intra More %", "Inter %") . "\n");
    print MAIN (join("\t", $total/2, $intra_less_counts/2, $intra_more_counts/2, $inter_counts/2, $intra_less_per, $intra_more_per, $inter_per) . "\n");
    close(MAIN);

}
