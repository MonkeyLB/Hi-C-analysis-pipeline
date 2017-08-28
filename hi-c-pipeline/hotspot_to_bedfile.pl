#!/usr/bin/perl

use strict;

MAIN : {

    my ($spot_matrix, $genome_size_file, $bin_size, $window_size, $chr, $thresh, $spots) = @ARGV;
    if ((not defined $spot_matrix) ||
	(not defined $genome_size_file) ||
	(not defined $bin_size) ||
	(not defined $window_size) ||
	(not defined $chr) ||
	(not defined $thresh) ||
	(not defined $spots)) {
	die ("Usage: ./hotspots.pl <spot matrix> <genome size file> <bin size> <window size> <chromosome> <threshold> <spots>\n");
    }

# read genome size file
    

    my %genome_size;
    open(FILE, $genome_size_file) || die ("could not open file ($genome_size_file)\n");
    while (my $line = <FILE>) {
	chomp $line;
	my ($chr, $size) = split(/\t/, $line);
	$genome_size{$chr} = $size;
    }

    open(INFO, $spot_matrix);
    my (@array) = <INFO>;
    close(INFO);

    my %index;
    my $bins = $window_size/$bin_size - 1;

    foreach my $r (@array) {
	chomp $r;
	my ($chr, $peak, @ro) = split(/\t/, $r);
	for (my $i = 0; $i < $bins; $i++) {
	    $index{$peak}[$i] = $ro[$i];
	}
    }

    my @new_array;
    my @table;
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

    open(MAIN, ">$chr.hotspots.bed");

    print MAIN ("track name=$chr" . "_hotspots useScore=1\n");

    foreach my $line (@array) {
	chomp $line;
	my $score;
	my ($chr, $peak, @row) = split(/\t/, $line);
	for (my $i = 0; $i < $bins; $i++) {
	    if (($table[$i] > 0) && ($row[$i] > $table[$i])) {
		$score++;
	    }
	}
	if ($score >= $spots) {
	    my $row_start = $peak - $window_size/2 + $bin_size/2;
	    my $pstart = $peak - $bin_size/2;
	    my $pend = $peak + $bin_size/2;
	    my $block_size = $bin_size . "," . $bin_size . ",";
	    my $title = $chr . $peak;
	    for (my $i = 0; $i < $bins; $i++) {
		if (($table[$i] > 0) && ($row[$i] > $table[$i])) {
		    my $start = ($row_start + ($bin_size*$i));
		    my $end = ($start + $bin_size);
		    if ($start > $pstart) {
			my $block_starts = "0," . ($end - $pstart - $bin_size);
			print MAIN (join("\t",$chr,$pstart,$end,$title,"950","+","0","0","0","2",$block_size,$block_starts) . "\n");
		    }
		    if ($start < $pstart) {
			my $block_starts = "0," . ($pend - $start - $bin_size);
			print MAIN (join("\t",$chr,$start,$pend,$title,"950","+","0","0","0","2",$block_size,$block_starts) . "\n")
		    }
		}
	    }
	}
    }

    close(MAIN);

}
