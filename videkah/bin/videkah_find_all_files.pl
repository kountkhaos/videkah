#!/usr/bin/perl
use warnings;
use strict;
use 5.14.2;
use Data::Dumper;

# find me all files from the current subdir down and print them out
# do not print out directory names.

# Khaos 2014-11-22

print "\n################################\n";
print "## ".qx{date};

for my $item (  qx{find ./} ) {
    $item = trim($item);

    if ( -f $item ) {
        if (    $item !~ /\..*?\.swp$/
            &&  $item !~ m{^\./\.videkah/}
            &&  $item !~ m{^\./\.git/}
        ){
            print $item."\n";
        } else {
#            print "SWAPPPPPPP OR Videkah : $item\n";
        }
    }

}

print "\n################################\n\n";


sub trim {
    my ($txt) = @_;
    $txt =~ s/^\s*//g;
    $txt =~ s/\s*$//g;
    return $txt;
}

