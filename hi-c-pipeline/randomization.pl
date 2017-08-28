#!/usr/bin/perl

use strict;

MAIN : {


    my ($spot_matrix, $chr, $bin_size, $window_size, $thresh, $spots, $iterations) = @ARGV;
    if ((not defined $spot_matrix) ||
	(not defined $chr) ||
	(not defined $bin_size) ||
	(not defined $window_size) ||
	(not defined $thresh) ||
	(not defined $spots) ||
	(not defined $iterations)) {
	die ("Usage: ./randomization.pl <spot matrix> <chr> <bin size> <window size> <threshold> <spots> <iterations>\n");
    }

    open(FILE, $spot_matrix);
    my @matrix = <FILE>;
    close(FILE);

    my $bins = ($window_size/$bin_size - 1);
    my %index;
    my %r_index;
    my $length = scalar(@matrix);
    
    for (my $i = 0; $i < $bins; $i++) {
	for (my $z = 0; $z < $length; $z++) {
	    my $line = $matrix[$z];
	    chomp $line;
	    my ($chr, $peak, @row) = split(/\t/, $line);
	    $index{$i}[$z] = $row[$i];
	}
    }

    my $start = 0;
    my $tally_hash;

    my @actual_table;
    for (my $i = 0; $i < $bins; $i++) {
	my @list;
	for (my $z = 0; $z < $length; $z++) {
	    push(@list, $index{$i}[$z])
	    }
	my @sorted = sort {$b <=> $a} @list;
	my $dist = scalar(@sorted);
	my $val = int($dist*$thresh/100);
	my $key = $sorted[$val];
	push(@actual_table, $key);
    }

    my $actual_score_hash;
    for (my $z = 0; $z < $length; $z++) {
	my $score= 0;
	for (my $i = 0; $i < $bins; $i++) {
	    if (($actual_table[$i] > 0) && ($index{$i}[$z] > $actual_table[$i])) {
		$score++;
	    }
	}
	$actual_score_hash->{$score}++;
    }

    while ($start < $iterations) {
	print STDERR ("Iteration number\t" . $start . "\n");
	my @new_array;
	my @table;
	for (my $i = 0; $i < $bins; $i++) {

# Here we make a random list of numbers, from 1 to the size of the array ($length = scalar(@matrix)), based on the size
# of the original spot_matrix file.  Therefore, we now have random list of spots.

	    my @array = (1 .. $length);
	    my @rand;
	    until (scalar(@rand) == $length) {
		my $top = scalar(@array);
		my $numb = int(rand($top));
		my $cut = splice(@array, $numb, 1);
		push (@rand, $cut);       
	    }

# We now go through the list of the matrix (spot_matrix, as stored in the $index hash), and we randomly select one number
# from per row (the $z is going for the length of $matrix). The random nubmer selection is based on the list of random
# number generated in the previous step.

	    my @list;
	    for (my $z = 0; $z < $length; $z++) {
		$r_index{$i}[$z] = $index{$i}[$rand[$z]];
		push(@list, $r_index{$i}[$z])
		}

# Now, we set the top 1% value at a given distance.

	    my @sorted = sort {$b <=> $a} @list;
	    my $dist = scalar(@sorted);
	    my $val = int($dist*$thresh/100);
	    my $key = $sorted[$val];
	    push(@table, $key);
	}

# At this point, we have generated an entirely random spot matrix stored as an index in $r_index, and we have
# generated a list of values representing the top 1% of values at a given distance, stored as an array in @table.
# We are now going to go through every single row and see how many interactions it is involved in.

	for (my $z = 0; $z < $length; $z++) {
	    my $score = 0;
	    for (my $i = 0; $i < $bins; $i++) {
		if (($table[$i] > 0) && ($r_index{$i}[$z] > $table[$i])) {
		    $score++;
		}
	    }
	    $tally_hash->{$score}++;
	}
	$start++;
    }

    my $greater_than_five;

    foreach my $key (sort (keys(%{$tally_hash}))) {
	if ($key >= 5) {
	    $greater_than_five += $tally_hash->{$key}; 
	}
    }

    my @test_keys = keys %{$actual_score_hash};
    my @sort_keys = sort {$b <=> $a} @test_keys;
    my $max_val = $sort_keys[0];

    open(RANDOM,">random.hotspots.$chr");
    print RANDOM "Number\tActual\tRandom\n";
    for (my $i = 0; $i <= $max_val; $i++) {
	print RANDOM $i . "\t" . $actual_score_hash->{$i}/1 . "\t" . $tally_hash->{$i}/$iterations . "\n";
    }
    close(RANDOM);
}


