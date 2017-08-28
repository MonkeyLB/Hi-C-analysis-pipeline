#!/usr/bin/perl  
use strict;

my $file;

unless (scalar @ARGV == 1)
    {
      print STDERR
        "USAGE: $0 *.sam\n";
      exit (0);
    }

$file = $ARGV[0];
open (FILE, "<$file") or die "couldn't open $file, $!\n";

my $output = $file.'.unique';
open (OUT,">$output");

while (my $line = <FILE>)
{ chomp $line;
  if (substr($line,0,1) eq '@') {print OUT "$line\n"; next;}  
  my $previous = $line;
  my @pr_liner = split ('\t',$line);
  my $pr_qual  = $pr_liner[4];
  my $pr_x     = $pr_liner[15]; $pr_x =~ s/X0:i://g;

  $line = <FILE>; chomp $line;
  my $next = $line;
  my @ne_liner = split ('\t',$line);
  my $ne_qual  = $ne_liner[4];
  my $ne_x     = $ne_liner[15]; $ne_x =~ s/X0:i://g;

 # if the reads are consecutive and both x0's are defined
 if (($pr_liner[0] eq $ne_liner[0]) and (defined $ne_x) and (defined $pr_x))
 { # if either are best and if either qual is > 10
   if ((($ne_x == 1) or ($pr_x == 1)) and (($ne_qual > 10) or ($pr_qual > 10)))
   {print OUT "$previous\n";
    print OUT "$next\n";
   }
 } 
}

close FILE;
close OUT;
