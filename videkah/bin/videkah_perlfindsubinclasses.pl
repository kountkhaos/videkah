#!/usr/bin/env perl
use warnings;
use strict;
use Data::Dumper;

use PPI;

my $DEBUG=0;

our @ISA=();

=pod

################################
# perlfindsubinclasses filter for vim.
################################
# I guess it could be used on other editors,
# assuming they can run external commands to filter a buffer.
#
# Karl "khaos" Hoskin Feb 2014
#
# Top tip . search for TODO in the following to find places where you'll probably need to edit this file.
#
# script to try and find where $self->methodname , $class->methoname calls get dispatched to.
#
# so pipe to this script a vim buffer (probably call perl_static_class_hierarchy in vim ) with the lines :-
#
# SUBNAME=sub2searchfor
# LIBPATHS=./mylib /some/other/perl/lib/path ./yet/another/lib/path
# STARTPERLMODULEFILE=/path/of/perl/module_to_start/search_in.pm
#
# and this script will :-
# (1) attempt to find the subname in STARTPERLMODULEFILE, if it can find it there, add it to the list .
# (2) it will then try where the module inherits from via
#   (2a) (moose) 'extends' statement
#   (2b) use base
#   (2c) (moose) 'with' statement
#
# and from all of those in 1, 2a, 2b and 2c it will output a hopefully correctly ordered list of where
# the static calls would be dispatched to with the first on the list, being the first call.
#
# this is not exact, and I'm probably going to need some help sorting out the correct calling order.
# but at least this is an attempt, that will get slowly get more accurate, and will allow someone in Vim to have a good and nice and easy # attempt of finding where a call to a $self->methodname or $class->methodname will get dispatched to .
#
# The output will be a list, hopefully in order saying something like :-
#
# PROCESSED 0 FILE=./call/should/get/here/first.pm LINE=<lineno> PACKAGE=<packagename> SUB=thesub
# PROCESSED 1 FILE=./call/might/get/here/next.pm LINE=<lineno> PACKAGE=<packagename> SUB=thesub
# PROCESSED 2 FILE=./call/could/possibly/get/here/next.pm LINE=<lineno> PACKAGE=<packagename> SUB=thesub
#
# the format is deliberately similar to the perlstacktrace so there will hopefully be some reuse of code
# in both Vimscipt and the perl parts of perlfindsubinclasses and perlstacktrace.
#
# This script unfortunately will not do anything clever like work out calls to SUPER:: or do introspection on the initial sub
# it is just a plain and simple look-for-this-sub-in-the-first-file and then try and find this subname in any base classes.
# I'm either too-stupid, too-lazy or just don't currently know how to do the introspection on such a dynamically calling language
# as perl, and some of this info is really only available at runtime, which kinda makes it hard.
#
# However that is not to say I don't think the static calling hierarchy search that this script aims to produce is pointless.
# There are a lot of programs that will be easier to look through, so I think it is worthwhile.
#
####################################################################

# handling multiple package names in a file and thus breaks the usual filepath -> package name . Dunno if I am going to handle this.

=cut

my $g_subname = '';
my $g_libpaths = '';
my $g_startperlmodulefile = '';

while (<>) {
    my $line = $_;

    if ( my ( $z ) = $line =~/^SUBNAME\s*=\s*(.*)$/ ) {
        $g_subname = trim($z) || '';
        next;
    }
    elsif ( ( $z ) = $line =~/^LIBPATHS\s*=\s*(.*)$/ ) {
        $g_libpaths = trim($z);
        next;
    }
    elsif ( ( $z ) = $line =~/^STARTPERLMODULEFILE\s*=\s*(.*)$/ ) {
        $g_startperlmodulefile = trim($z);
        next;
    }
}

die "ERROR . SUBNAME= line not found\n"             if ! defined($g_subname) ;
die "ERROR . LIBPATHS= line not found\n"            if ! $g_libpaths ;
die "ERROR . STARTPERLMODULEFILE= line not found\n" if ! $g_startperlmodulefile ;
die "ERROR . can't find $g_startperlmodulefile \n"  if ! -f $g_startperlmodulefile ;

my @g_libpaths_arr = split /\s+/ , $g_libpaths;
for my $thispath (  @g_libpaths_arr ) {
    die "ERROR . the libpath '$thispath' either doesn't exist or isn't a directory " if ! -d $thispath;
}

###########################################################

my @seq      = [];
my $output   = '';
my $outtree  = '';
my $debugout = '';
my $procline = 0 ;
my $filename_already_called = {};

find_sub_in_file( $g_startperlmodulefile, "", $g_subname );
print "$output\n\n$outtree\n\n$debugout\n";
exit 0;

###########################################################

sub find_sub_in_file { # and find's Moosey "has" which get subs associated with them.
    my ( $filename, $packagename , $sub2find ) = @_;

    $filename = $filename ? trim($filename) : '' ;
    $packagename = $packagename || '';

    $outtree .= "\nTREE ".($filename||$packagename)."\n";
    $debugout .= "\nfind_sub_in_file( '$filename', '$packagename', '$sub2find' ) called\n";

    # if we have a filename load that.
    # if we don't have a filename, but have a package name try and find that.
    if ( ! $filename && $packagename ){
        $filename = trim(try_find_package_in_libpath ($packagename));
    }

    if ( ! (-f $filename) ) {
        $debugout .= "can't find filename '$filename'\n";
        # hmmm not sure what to do here.
        return;
    }

    if ( exists $filename_already_called->{$filename} ) {
        $debugout .= "'$filename' already called\n";
        return;
    }
    $filename_already_called->{$filename} = 1;

    my $txt = slurp( $filename );

    my $usebase = '';
    my $extends = '';
    my $with    = '';

    my $usebase_unterminated = 0;
    my $extends_unterminated = 0;
    my $with_unterminated    = 0;

    my $i = 0;
    for my $line ( split /\n/, $txt ) {
        $i++;
        if ( $sub2find && $line =~ /^\s*(sub|has)\s+$sub2find(\s|\(|{)/ ){
            #found the sub
            my $data4line = { file => $filename, line => $i, package => $packagename, sub => $sub2find , procline => $procline };
            $output .= printout($data4line);
            $procline++;
            last;
        }
    }

    for my $tpackg ( get_packages_inherited_from($filename) ){
        find_sub_in_file( "", $tpackg, $sub2find );
    }

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

sub printout {
    # to keep the output and spaces consistent, just one output routine.
    my ($p) = @_;

    $p->{procline} = $p->{procline} ? $p->{procline} : 0  ;
    $p->{file}     = $p->{file}     ? $p->{file}     : '' ;
    $p->{package}  = $p->{package}  ? $p->{package}  : '' ;
    $p->{line}     = $p->{line}     ? $p->{line}     : '' ;
    $p->{sub}      = $p->{sub}      ? $p->{sub}      : '' ;

    my $txtout = "PROCESSED $p->{procline} FILE=$p->{file} LINE=$p->{line} PACKAGE=$p->{package} SUB=$p->{sub}\n";

    print $txtout if $p->{printout};
    return $txtout;
}

sub slurp {
    my ($file) = @_;
    open( my $fh, $file ) or die "can't open $file\n";
    my $text = do { local( $/ ) ; <$fh> } ;
    return $text;
}

###############################################################

sub trim {
    my ($txt) = @_;
    $txt =~ s/^\s+//g;
    $txt =~ s/\s+$//g;
    return $txt;
}

###############################################################
# find the packages inherited from .

sub get_packages_inherited_from {

    my ($filename) = @_;
    my @use_base_package_names   = ();
    my @with_package_names       = ();
    my @extends_package_names    = ();
    my @use_parent_package_names = ();
    my @isa_package_names        = ();

    $debugout .= "get_packages_inherited_from($filename) called \n";

    my $document = PPI::Document->new($filename);

    if ( ! $document ) {
        $debugout .= "PPI::Document->new($filename) hasn't returned a valid object\n";
        return;
    };


    if ( my $with = $document->find(
                sub { $_[1]->isa("PPI::Statement") } # and $_[1]->children->[0]->content eq 'with' }
            )
    ){
        for my $this_statement ( @$with ){

            my $ts_c0content = $this_statement->{children}[0]{content} || '';

            if ( $ts_c0content eq 'with' ){
                push @with_package_names ,get_package_names( $this_statement );
            } elsif ( $ts_c0content eq 'extends' ){
                push @extends_package_names , get_package_names( $this_statement );
            } elsif ( $this_statement->isa("PPI::Statement::Include") and $this_statement->module eq 'base'  ){
                push @use_base_package_names ,get_package_names( $this_statement );
            } elsif ( $this_statement->isa("PPI::Statement::Include") and $this_statement->module eq 'parent'  ){
                push @use_parent_package_names ,get_package_names( $this_statement );
            } elsif (
                $this_statement->isa("PPI::Statement::Variable")
                and ($this_statement->type eq 'our' || $this_statement->type eq 'local' )
              ){
                for my $b ( $this_statement->symbols ) {
                    if ( $b->content =~ /^\@ISA$/ ) { # TODO should I interpret m/^\@.*?ISA$/ ?
                        push @isa_package_names , get_package_names_from_isa($this_statement);
                    }
                }
            } elsif ( $this_statement->isa("PPI::Statement")
                    and $ts_c0content eq '@ISA'
                ){
                push @isa_package_names , get_package_names_from_isa($this_statement);
            }
        }
    }

#    print STDERR " external joined isa_pknames = ".join( " ", @isa_package_names )."\n" if $DEBUG;


    if ( @use_base_package_names ) {
        $debugout .= "    get_packages_inherited_from found \@use_base_package_names ".join(" ",@use_base_package_names)."\n" ;
    }
    if ( @with_package_names ) {
        $debugout .= "    get_packages_inherited_from found \@with_package_names ".join(" ",@with_package_names)."\n";
    }
    if ( @extends_package_names ) {
        $debugout .= "    get_packages_inherited_from found \@extends_package_names ".join(" ",@extends_package_names)."\n" ;
    }
    if ( @use_parent_package_names ) {
        $debugout .= "    get_packages_inherited_from found \@use_parent_package_names ".join(" ",@use_parent_package_names)."\n" ;
    }
    if ( @isa_package_names ) {
        $debugout .= "    get_packages_inherited_from found \@isa_package_names ".join(" ",@isa_package_names)."\n" ;
    }

    my @ret = (
        @use_base_package_names,
        @with_package_names,
        @extends_package_names,
        @use_parent_package_names,
        @isa_package_names,
    );

    $outtree .= "TREE    ".join("\nTREE    ",@ret)."\n" if @ret;

    return @ret;
}

sub get_package_names_from_isa {
    # for extracting the package names out of a PPI::Statement that has an is in it.
    my ($ppi_el) = @_;

    my $orig = trim(ppi_element_2_original( $ppi_el ));
    $orig =~ s/^(our|local)\s+//g;

    my @isa;
    # don't want to break the @ISA for this package, so :-
    {
        eval "
            {
                local $orig;
                \@isa=\@ISA;
            }
        ";


        die $@ if $@;
    }
    return @isa;
}

=item ppi_element_2_original

converts a PPI::Element back into its original form.

according to Adam Kennedy the author of PPI module this way will break with
here-doc constructs and he said :-

Because of the potential presence of here docs,  you can't serialize a statement or element.
You need to place them into a ppi::document or ppi::document::fragment to serialize

=cut

sub ppi_element_2_original {
    my ( $ppi_el ) = @_;
    return join( "", map { $_->content } $ppi_el->tokens );
}

sub get_package_names {
    my ($ppi_include) = @_;

    #print Dumper ( $ppi_include ) if $DEBUG;
    my @package_names = ();

    for my $x ( @{$ppi_include->{children}} ) {
        next if $x->content eq 'use' and $x->isa("PPI::Token::Word");
        next if $x->content eq 'base' and $x->isa("PPI::Token::Word");
        next if $x->isa("PPI::Token::Whitespace");
        next if $x->isa('PPI::Token::Structure');
        next if $x->isa('PPI::Token::Operator');
        next if $x->isa('PPI::Token::Word');

        my $content = $x->content;
        my @sns_cont;
        #print "\nbefore $content\n" if $DEBUG;

        if ( $x->isa("PPI::Token::Quote::Interpolate") ){
            # PPI::Token::Quote::Interpolate == qq
            $content =~ s/^qq//;
            @sns_cont = strip_n_split($x, $content);
        }
        elsif ( $x->isa("PPI::Token::Quote::Literal") ){
            # PPI::Token::Quote::Literal     == q
            $content =~ s/^q//;
            @sns_cont = strip_n_split($x, $content);
        }
        elsif ( $x->isa("PPI::Token::QuoteLike::Words") ){
            # PPI::Token::QuoteLike::Words   == qw
            $content =~ s/^qw//;
            @sns_cont = strip_n_split($x, $content, 1);
        }
        elsif ( $x->isa("PPI::Token::Quote::Double")
             || $x->isa("PPI::Token::Quote::Single")
        ){
            # PPI::Token::Quote::Double      == ""
            # PPI::Token::Quote::Single      == ''
            @sns_cont = strip_n_split($x, $content);
        } else {
            die "we have an unhandled case of type ".ref($x)."\n";
        }
        push @package_names, @sns_cont;
        #print "after |".join( "|", @sns_cont)."|\n" if $DEBUG;
    }
    return @package_names;
}

sub strip_n_split {
    my ($x , $content , $split ) = @_;

    $content = trim($content);
    if ( $x->{braced} ){
        $content =~ s/^\(//;
        $content =~ s/\)$//;
    } else {
        my $separator = $x->{separator};
        $content =~ s/^$separator//;
        $content =~ s/$separator$//;
    }

    my @sns_cont ;
    if ($split) {
        @sns_cont = split/\s+/, trim($content);
    } else {
        @sns_cont = (trim($content));
    }

    return @sns_cont;
}


