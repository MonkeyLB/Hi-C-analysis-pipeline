#!/usr/bin/perl

use strict;

MAIN : {
    my ($bam_file1, $bam_file2, $bin_size, $chr, $genome_size_file) = @ARGV;
    if ((not defined $bam_file1) ||
	(not defined $bam_file2) ||
	(not defined $bin_size) ||
	(not defined $chr) ||
	(not defined $genome_size_file)) {
	die ("Usage: ./get_matrix.pl <bam file 1> <bam file 2> <bin size> <chr> <genome size file>\n");
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

    my $score = 1;
    foreach my $bam ($bam_file1, $bam_file2) {

	open(FILE,">$chr.matrix_$score") || die ("Could not open file!");
	
	for(my $left = 0 ;
	    $left < $genome_size{$chr} ;
	    $left += $bin_size) {
	    
	    my $query = $chr . ":" . $left . "-" . ($left + $bin_size - 1);
	    #print STDERR $query . "\n";
	    my @counts;
	    for(my $i = 0 ; $i <= int($genome_size{$chr} / $bin_size) ; $i++) {
		if (not defined $counts[$i]) {
		    $counts[$i] = 0;
		}
	    }
	    
	    my @samtools_lines = `samtools view $bam $query`;
	    foreach my $line (@samtools_lines) {
		chomp $line;
		
		my ($id, $flags,
		    $chr_from, $loc_from,
		    $d1, $d2,
		    $chr_to, $loc_to, $dist) = split(/\t/, $line);
		
		if (($chr_to eq "=") && (abs($dist) > 1000)) {
		    my $bin_to = int ($loc_to / $bin_size);
		    $counts[$bin_to]++;
		}
	    }
	    
	    print FILE (join("\t", $chr, $left, $left + $bin_size, @counts) . "\n");
	}
	
	close(FILE) || die ("Could not close file!");
	$score++;
    }
    
    my $score = 1;

    my $bam_stat;

    foreach my $bam ($bam_file1, $bam_file2) {
	open(FILE,"<$chr.matrix_$score") || die ("Can't open that file!");
	my @matrix = <FILE>;
	close(FILE) || die ("Can't close that file!");
	
	my $newrow = 0;	
	
	foreach my $line (@matrix) {
	    chomp $line;
	    my $row = $newrow + 1;
	    my ($c, $left, $right, @column) = split(/\t/, $line);
	    my $newcol = undef;
	    foreach my $numb (@column) {
		my $col = $newcol + 1;
		chomp $numb;
		$bam_stat->{$score}->{$row}->{$col} = $numb;
		$newcol = $col;
	    }
	    $newrow = $row;
	}

	close(FILE);
	$score++;
    }

    open(FILE,"<$chr.matrix_1") || die ("Couldn't even do it");
    my(@matrix) = <FILE>;
    close(FILE) || die ("Couldn't even do it");
    
    my $newrow = 0;

    foreach my $line (@matrix) {
	chomp $line;
	my $row = $newrow + 1;
	my ($c, $left, $right, @column) = split(/\t/, $line);
	my $newcol = undef;
	foreach my $numb (@column) {
	    my $col = $newcol + 1;
	    my $dist = abs($col - $row);
	    if ($dist > 0) {
		print $row . "\t" . $col . "\t" . $dist . "\t";
		for (my $i = 1; $i <= 2; $i++) {
		    print $bam_stat->{$i}->{$row}->{$col} . "\t";
		}
		print "\n";
	    }
	    $newcol = $col;
	}
	$newrow = $row;
    }


}
