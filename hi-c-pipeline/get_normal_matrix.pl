#!/usr/bin/perl

use strict;

MAIN : {
    my ($bam_file, $bin_size, $chr, $genome_size_file) = @ARGV;
    if ((not defined $bam_file) ||
	(not defined $bin_size) ||
	(not defined $chr) ||
	(not defined $genome_size_file)) {
	die ("Usage: ./get_matrix.pl <bam file> <bin size> <chr> <genome size file>\n");
    }

    # read genome size file
    my %genome_size;
    open(FILE, $genome_size_file) || die("could not open file ($genome_size_file)\n");
    while (my $line = <FILE>) {
	chomp $line;
	my ($chr, $size) = split(/\t/, $line);
	$genome_size{$chr} = $size;
    }
    close(FILE) || die("could not close file ($genome_size_file)\n");
#should go through whole chromosome to get the normlization factors first
    my @n_factor;
    my $counter;
    for (my $i = 0; $i <= int($genome_size{$chr} / $bin_size); $i++) {
	$n_factor[$i] = 0;
	}
    for(my $left = 0 ; $left < $genome_size{$chr} ; $left += $bin_size) 
	{
	$counter = 0;
	my $query = $chr . ":" . $left . "-" . ($left + $bin_size - 1);
	print STDERR $query . "\t";

	my @samtools_lines = `samtools view $bam_file $query`;
	foreach my $line (@samtools_lines) {
	    chomp $line;

	    my ($id, $flags,
		$chr_from, $loc_from,
		$d1, $d2,
		$chr_to, $loc_to, $dist) = split(/\t/, $line);

	    if (($chr_to eq "=") && (abs($dist) < 1000)) {
	#bing paired ends less than 4kb apart as input to normalize
		my $bin_to = int ($loc_from / $bin_size);
		$n_factor[$bin_to]++;
		$counter ++ ;
	    }
	}
	print STDERR $counter . "\n";
	}


# only compute for one chromosome
# starting from one end and check where the other end located and then write the array
# sort of like a double array, y loop is @count
=pod
    for(my $left = 0 ;
	$left < $genome_size{$chr} ;
	$left += $bin_size) {

	my $query = $chr . ":" . $left . "-" . ($left + $bin_size - 1);
	print STDERR $query . "\n";
	my @counts;
	for(my $i = 0 ; $i <= int($genome_size{$chr} / $bin_size) ; $i++) {
	    if (not defined $counts[$i]) {
		$counts[$i] = 0;
	    }
	}

	my @samtools_lines = `samtools view $bam_file $query`;
	foreach my $line (@samtools_lines) {
	    chomp $line;

	    my ($id, $flags,
		$chr_from, $loc_from,
		$d1, $d2,
		$chr_to, $loc_to, $dist) = split(/\t/, $line);

	    if (($chr_to eq "=") && (abs($dist) > 1000)) {
	#bing paired ends less than 4kb apart as input to normalize
		my $bin_to = int ($loc_to / $bin_size);
		$counts[$bin_to]++;
	    }
	}
	print(join("\t", $chr, $left, $left + $bin_size, @counts) . "\n");
    }
=cut

}
