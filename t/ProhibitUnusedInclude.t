#!perl

use strict;
use warnings;
use Test2::V0;

use Perl::Critic;
diag "Perl::Critic version ", Perl::Critic->VERSION;

my @data = (
    ['use File::Spec; print 42', 1],
    ['use Try::Tiny; print 42', 1],
    ['use File::Spec; use Try::Tiny; print 42', 2],
    ['use File::Spec; use Try::Tiny; try { print 42 }', 1],
    ['use File::Spec; use Try::Tiny; try { print File::Spec->catfile(42) }', 0],
    ['use File::Spec; use Try::Tiny; print File::Spec->catfile(42);', 1],

    # We have no idea how Xyzthppp mutate the language, therefore that is ignored.
    ['use Xyzthppp; print 42;', 0],
);

my $critic = Perl::Critic->new(
    '-profile' => '',
    '-single-policy' => '^Perl::Critic::Policy::TooMuchCode::ProhibitUnusedInclude$'
);

for my $data (@data) {
    my ($code, $want_count) = @$data;
    my @violations = $critic->critique (\$code);
    my $got_count = scalar @violations;
    is ($got_count, $want_count, "code: '$code'");
 
    if ($got_count != $want_count) {
        foreach (@violations) {
            diag($_->description);
        }
    }
}
done_testing;
