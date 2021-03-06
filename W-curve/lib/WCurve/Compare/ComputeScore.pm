########################################################################
# housekeeping
########################################################################

package WCurve::Compare::ComputeScore;

use v5.10;
use strict;

use Data::Dumper;

use List::Util      qw( max min sum );

use Exporter::Proxy
qw
(
    simple_total
    dump_chunks
);

use WCurve::Constants;

########################################################################
# package variables
########################################################################

my $verbose = 1;    # progress messages
my $debug   = '';   # skips, snps
my $trace   = '';   # all decision values

########################################################################
# utility subs
########################################################################

########################################################################
# compare entries look like:
# 
# [
#   n0 initial
#   n1 initial
#   n0 final
#   n1 final
#   sum of diff
# ]
########################################################################

sub dump_chunks
{
    my ( $wc, $chunkz ) = @_;  

    local $Data::Dumper::Terse        = 1;
    local $Data::Dumper::Indent       = 1;
    local $Data::Dumper::Purity       = 0;
    local $Data::Dumper::Deepcopy     = 0;
    local $Data::Dumper::Quotekeys    = 0;

    local $,    = "\n";
    local $\    = "\n";

    print "$wc", Dumper $chunkz;

    return 1
}

########################################################################
# score gaps constant * gap size.
# skips as average w/in block * size of skip.
# diffs are totalled.
#
# total score is divided by 2.0 * total bases 
# to get fraction of the worst score possible
# ( 0.0 <= score <= 1.0 ).

sub simple_total
{
    state $gap_cost     = 1.0;

    state $skip     = 0;
    state $gap      = 0;
    state $i        = 0;
    state $j        = 0;
    state $k        = 0;

    my ( $wc, $chunkz ) = @_;

    my $prior   = shift @$chunkz;
    my $final   = pop   @$chunkz;

    my $total   = 0;

    # add cost of initial/final alignment. 
    # these are the portions of the curve
    # skipped from differences at the start
    # of the curves and differences in the
    # lengths.

    $i      = max @$prior[2,3];
    $j      = min @$prior[2,3];

    $total  += $prior->[-1];
    $total  += (  $i -  $j );

    # trailing gap: one will be zero, the other 
    # will be the difference to the longer curve.

    $i      = $final->[2] - $final->[0];    
    $j      = $final->[3] - $final->[1];  

    $total  += $final->[-1];
    $total  += ( $i + $j );

    # now walk down the main chunks, 
    # accumulating the remaining total.

    for( @$chunkz )
    {
        # smaller difference was skipped over; 
        # difference between them is the gap 
        # introduced.
        #
        # skip total is the current diff/base 
        # times the skip size, gap total is a 
        # constant times the gap.

        $i  = $_->[0] - $prior->[2];    # inter-chunk
        $j  = $_->[1] - $prior->[3];    # inter-chunk

        $k  = $_->[2] - $_->[0];        # intra-chunk == run length

        $skip   = min $i, $j;
        $gap    = max( $i, $j ) - $skip;

        $total += $skip * ( $_->[-1] / $k ) if $k;
        $total += $gap  * $gap_cost;
        $total += $_->[-1];

        $prior  = $_;
    };

    # total / 2 * length => ( 0 <= x <= 1 ).

    my $score   = $total / ( sum @$final[2,3] );

$score > 1 and $DB::single = 1;

    $score

}

########################################################################
# score gaps constant * gap size.
# skips as average w/in block * size of skip.
# diffs are totalled.
#
# total score is divided by 2.0 * total bases 
# to get fraction of the worst score possible
# ( 0.0 <= score <= 1.0 ).

sub feature_total
{
    state $gap_cost     = 1.0;

    state $skip     = 0;
    state $gap      = 0;
    state $i        = 0;
    state $j        = 0;
    state $k        = 0;

    my ( $wc, $chunkz ) = @_;

    my $prior   = shift @$chunkz;
    my $final   = pop   @$chunkz;

    my $total   = 0;

    # ignore the cost of initial/final alignment.

    # now walk down the main chunks, 
    # accumulating the remaining total.

    for( @$chunkz )
    {
        # smaller difference was skipped over; 
        # difference between them is the gap 
        # introduced.
        #
        # skip total is the current diff/base 
        # times the skip size, gap total is a 
        # constant times the gap.

        $i  = $_->[0] - $prior->[2];    # inter-chunk
        $j  = $_->[1] - $prior->[3];    # inter-chunk

        $k  = $_->[2] - $_->[0];        # intra-chunk == run length

        $skip   = min $i, $j;
        $gap    = max( $i, $j ) - $skip;

        $total += $skip * ( $_->[-1] / $k ) if $k;
        $total += $gap  * $gap_cost;
        $total += $_->[-1];

        $prior  = $_;
    };

    # total / 2 * length => ( 0 <= x <= 1 ).

    my $score   = $total / ( sum @$final[2,3] );

    $score

}

# keep require happy

1

__END__
