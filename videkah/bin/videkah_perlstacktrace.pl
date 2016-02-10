#!/usr/bin/env perl
use warnings;
use strict;
use Data::Dumper;

################################
# perlstacktrace filter for vim.
################################
# I guess it could be used on other editors,
# assuming they can run external commands to filter a buffer.
#
# Karl "khaos" Hoskin Jan 2014
#
# Top tip . search for TODO in the following to find places where you'll probably need to edit this file.


# TODO explain what this script does.

# TODO add the vimscript code in a pod section

my $perlstacktrace_loc ;
my $count = 0 ;
my $seq = [];
my $output = '';
my $processed_output = '' ;
my $ignore_output = '' ;

my @g_libpaths_arr = ();

while (<>) {
    my $line = $_;

    if (! $count) {
        # we're on the first line , so this is the perlstacktrace_loc number.
        $perlstacktrace_loc = $line;
        $count ++;
        next;
    }
    elsif ( $line =~/^GOTO_/ ) {
        next;
    }
    elsif ( my ( $z ) = $line =~/^LIBPATHS\s*=\s*(.*)$/ ) {
        @g_libpaths_arr = split /\s+/ , trim($z);
        for my $thispath (  @g_libpaths_arr ) {
            die "ERROR . the libpath '$thispath' either doesn't exist or isn't a directory " if ! -d $thispath;
        }
        next;
    }
    elsif ( $line =~/^IGNORE/ ) {
        $ignore_output .= $line ;
        next;
    } # INSERTED = inserted by add command | PROCESSED = processed from stacktrace
    elsif (my($insORproc, undef,$pfile,$pline,$ppackage,$psub) = $line =~ /^(INSERTED|PROCESSED) (\d+) FILE=(.*?) LINE=(.*?) PACKAGE=(.*?) SUB=(.*?)$/ ) {

        $pfile=strip_caller_file(trim($pfile)); # any inserted lines will need to be stripped. inserted by the vimscript  PerlStacktrace_addline that is.

        # if you change the $processed_output you will break the regex that depends on it.
        $processed_output .="$insORproc ".(scalar @$seq)." FILE=$pfile LINE=$pline PACKAGE=$ppackage SUB=$psub\n";
        push @$seq, { file => $pfile , line => $pline , package => $ppackage , sub => $psub };
        next;
    }
    elsif ( my ($callee , $caller ) = $line =~ m/(.*?) called at (.*)/){ # the original perl stack trace lines.
       $output .= $line;
       $ignore_output .= "IGNORE $line";# want to keep the original stack trace lines at the end.
        # These stack trace lines are in the general format :-
        # callee-package::callee-sub(params) called by callee-filename line-number
        # this next section of code is splitting this up

        if ( my ($caller_file , $caller_line ) = $caller =~ m/(.*?) line (\d+)/){

            # strip of leading stuff from dev env code path
            $caller_file = strip_caller_file( $caller_file );

            $caller_file = trim($caller_file);
            $caller_line = trim($caller_line);

            if ( my ($callee_package_n_sub ) = $callee =~ m/(.+?)\(/){

                if ( my ($callee_package , $callee_sub ) = $callee_package_n_sub =~ m/(.+)::(.+)/){
                    $callee_package = trim($callee_package);
                    $callee_sub = trim($callee_sub);

                    # trying to fine the callee-file from the callee package name.
                    # This is not an exact "science" but for what I want it
                    # is probably more than 90% useful :-
                    my $callee_file =trim(try_find_package_in_libpath($callee_package));

                    # if you change the $processed_output you will break the regex that depends on it. (above)
                    # these following 6 lines are in VERY important order.
                    $processed_output .="PROCESSED ".(scalar @$seq)." FILE=$callee_file LINE= PACKAGE=$callee_package SUB=$callee_sub\n";
                    push @$seq, { file => $callee_file , line => '' , package => $callee_package , sub => $callee_sub };
                    $count++;
                    $processed_output .="PROCESSED ".(scalar @$seq)." FILE=$caller_file LINE=$caller_line PACKAGE= SUB=\n";
                    push @$seq, { file => $caller_file , line => $caller_line , package => "" , sub => "" };
                    $count++;
                }
            }
        }
        next;
    }
    elsif ( ( my ($flcaller_file, $flcaller_line) = $line =~ m/.* at (\/.*) line (\d+)\.$/ ) && $count==1 ){
        # The above regex MUST come after the "called at" regex, because it "gobbles" up those if it was earlier in the elsif blocks sequence.
        # no entries in the seq . flcaller = first line caller.
        $output .= $line;
        $ignore_output .= "IGNORE $line";

        # strip of leading stuff from dev env code path
        $flcaller_file = strip_caller_file( $flcaller_file );

        $processed_output .="PROCESSED ".(scalar @$seq)." FILE=$flcaller_file LINE=$flcaller_line PACKAGE= SUB=\n";
        push @$seq, { file => $flcaller_file, line => $flcaller_line, package => "", sub => "" };
        $count++;
        next;
    } else {
        chomp $line ;
        if ( $line ne '' ) {
            $ignore_output .= "IGNORE $line\n";
            next;
        }
    }
}

if ( ! @$seq || $count == 0 ) {
    print "IGNORE Nothing to Process error\n";
    exit 0;
}

# now do output of this vim filter.
if ( my ($ps_loc) = $perlstacktrace_loc =~ m/=(\-?\d+)/ ) {
    my $linenum = ( $ps_loc ) % @$seq ;

    my $goto_header = "GOTO_FILE $seq->[$linenum]{file}\n"
        ."GOTO_LINE $seq->[$linenum]{line}\n"
        ."GOTO_SUB $seq->[$linenum]{sub}\n"
        ."GOTO_PERLSTACKTRACE_LOC $linenum\n" ;

    print "$goto_header\n$processed_output\n$ignore_output\n" ;
} else {
    print "NOT WORKING, didn't detect the perlstacktrace_loc. Just outputting what we can\n$output" ;
}

exit 0;
#######################################################

=item strip_caller_file

hacky regex to remove part of the leading path of filenames.

TODO you'll probably want to change this.

TODO the /export/www/code probably needs to go into the .vidkah/config

=cut

sub strip_caller_file {
    my ($cf) = @_;
    # strip of leading stuff from dev env code path
    # TODO needs factoring out somehow .... This works for my stack traces.
    $cf =~ s{/export/www/code/.*?/}{}g;
    return $cf;
}

sub try_find_package_in_libpath {
    # trying to find where "My::Frickin::Perl::Module" is in the libpaths.
    my ($x) = @_;
    $x =~ s/\:\:/\//g;
    my $ret = "";
    for my $prefix ( "" , @g_libpaths_arr ){

        if ( -f "${prefix}${x}.pm" ) {
            $ret .= " ${prefix}${x}.pm";
        }
    }
    return $ret;
}
sub trim {
    my ($txt) = @_;
    $txt =~ s/^\s+//g;
    $txt =~ s/\s+$//g;
    return $txt;
}


