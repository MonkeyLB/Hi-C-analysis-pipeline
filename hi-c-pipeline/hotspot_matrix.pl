#!/usr/bin/perl

use strict;

MAIN : {

    my ($spot_matrix, $genome_size_file, $bin_size, $window_size, $chr, $thresh, $spot) = @ARGV;
    if ((not defined $spot_matrix) ||
	(not defined $genome_size_file) ||
	(not defined $bin_size) ||
	(not defined $window_size) ||
	(not defined $chr) ||
	(not defined $thresh) ||
	(not defined $spot)) {
	die ("Usage: ./hotspots.pl <spot matrix> <genome size file> <bin size> <window size> <chromosome> <threshold> <hot spots>\n");
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

    my %index;
    my @counts;
    my @table;
    my $bins = $window_size/$bin_size - 1;
    my @new_array;
    
    open(INFO, $spot_matrix);
    my (@array) = <INFO>;
    close(INFO);
    
    foreach my $line (@array) {
	chomp $line;
	my ($chr, $peak, @row) = split(/\t/, $line);
	for (my $i = 0; $i < $bins; $i++) {
	    $index{$peak}[$i] = $row[$i];
	}
    }

    for (my $i = 0; $i < $bins; $i++) {
	my @list;
	for (my $left = 0;
	     $left < $genome_size{$chr};
	     $left += $bin_size) {
	    my $peak = $left + $bin_size/2;
	    push(@list, $index{$peak}[$i]);
	}
	my @sorted = sort {$b <=> $a} @list;
	my $length = scalar(@sorted);
	my $val = int($length*$thresh/100);
	my $key = $sorted[$val];
	push (@table, $key);
    }

    open(MAIN, ">$chr.hotspot.matrix");
    open(SCORES, ">$chr.hotspot.density");

    foreach my $line (@array) {
	chomp $line;
	my $score;
	my ($chr, $peak, @row) = split(/\t/, $line);
	for (my $i = 0; $i < $bins; $i++) {
	    if (($table[$i] > 0) && ($row[$i] > $table[$i])) {
		$score++;
	    }
	}
	if ($score >= $spot) {
	    push(@new_array, ($line . "\n"));
	    print MAIN ($line . "\n");
	}
    }


    foreach my $tune (@new_array) {
	chomp $tune;
	my ($chr, $peak, @row) = split(/\t/, $tune);
	for (my $i = 0; $i < $bins; $i++) {
	    if (($table[$i] > 0) && ($row[$i] > $table[$i])) {
		$counts[$i]++;
	    }
	}
    }
    for (my $i = 0; $i < $bins; $i++) {
	if ($counts[$i] > 0) {
	    print SCORES ($counts[$i] . "\t");
	} else {
	    print SCORES ("0\t");
	}
    }

    close(MAIN);
    close(SCORES);

}

