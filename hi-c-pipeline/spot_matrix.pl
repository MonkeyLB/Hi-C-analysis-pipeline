#!/usr/bin/perl

use strict;

MAIN : {

    my ($bam_file, $genome_size_file, $bin_size, $window_size, $chr) = @ARGV;
    if ((not defined $bam_file) ||
	(not defined $genome_size_file) ||
	(not defined $bin_size) ||
	(not defined $window_size) ||
	(not defined $chr)) {
	die ("Usage: ./hotspots.pl <bam file> <genome size file> <bin size> <window size> <chromosome>\n");
    }

    #read genome size file
    my %genome_size;
    open(FILE, $genome_size_file) || die ("could not open file ($genome_size_file)\n");
    while (my $line = <FILE>) {
	chomp $line;
	my ($chr, $size) = split(/\t/, $line);
	$genome_size{$chr} = $size;
    }
    close(FILE) || die("could not close file ($genome_size_file)\n");

    my $bins = $window_size/$bin_size - 1;

    for (my $left = 0;
	 $left < $genome_size{$chr};
	 $left += $bin_size) {
	my $peak = $left + $bin_size/2;
	my $bin_start = $peak - $window_size/2 + $bin_size/2;
	my $query = $chr . ":" . $left . "-" . ($left + $bin_size - 1);
	print STDERR $query . "\n";
	my @counts;
	my @samtools_lines = `samtools view $bam_file $query`;
	if (scalar(@samtools_lines) > 0) {
	    foreach my $values (@samtools_lines) {
		chomp $values;
		my ($id, $flags, $chr_from, $loc_from, $d1, $d2, $chr_to, $loc_to, $dist) = split(/\t/, $values);
		if (($chr_to eq "=") &&
		    (abs($dist) >= $bin_size) &&
		    ($loc_to >= $bin_start) &&
		    ($loc_to <= ($bin_start + $window_size - $bin_size))) {
		    my $bin_to = int(($loc_to - $bin_start)/$bin_size);
		    $counts[$bin_to]++;
		}
	    }
	    for (my $i=0; $i<$bins; $i++) {
		if (not defined $counts[$i]) {
		    $counts[$i] = 0;
		}
	    }
	    print(join("\t",$chr,$peak,@counts) . "\n");
	} 
    } 
}
