#!/usr/bin/env perl
use warnings;
use strict;
use Data::Dumper;


#videkah_perl_ackgrep.pl

# searches perl lib dirs ( well could be any list of paths ) using ack-grep

# Karl 'khaos' Hoskin


# needs 2 lines piped into this script :-
#   SEARCHSTRING=" something2search4  "
#   LIBPATHS=/path/one /path/two
#
# or if you don't want spaces at the beginning and/or end of the searchstring :-
#   SEARCHSTRING=something2search4
#   LIBPATHS=/path/one /path/two
#

my $g_searchstring = '';
my $g_libpaths = '';

while (<>) {
    my $line = $_;

    if ( my ( $z ) = $line =~/^SEARCHSTRING\s*=\s*(.*)$/ ) {
        $g_searchstring = trim($z) || '';
        next;
    }
    elsif ( ( $z ) = $line =~/^LIBPATHS\s*=\s*(.*)$/ ) {
        $g_libpaths = trim($z);
        next;
    }
}

die "ERROR . SEARCHSTRING= line not found\n"        if ! $g_searchstring ;
die "ERROR . LIBPATHS= line not found\n"            if ! $g_libpaths ;

my @g_libpaths_arr = split /\s+/ , $g_libpaths;
for my $thispath (  @g_libpaths_arr ) {
    die "ERROR . the libpath '$thispath' either doesn't exist or isn't a directory " if ! -d $thispath;
}

my $cmd = "ack-grep -r '$g_searchstring' $g_libpaths";

print qx{$cmd};


sub trim {
    my ($txt) = @_;
    $txt =~ s/^\s+//g;
    $txt =~ s/\s+$//g;
    return $txt;
}


