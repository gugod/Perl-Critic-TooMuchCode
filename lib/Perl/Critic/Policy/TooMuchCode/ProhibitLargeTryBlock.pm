package Perl::Critic::Policy::TooMuchCode::ProhibitLargeTryBlock;

use strict;
use warnings;
use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

our $VERSION = '0.01';

sub default_themes       { return qw( tests )     }
sub applies_to           { return 'PPI::Document' }

sub violates {
    my ( $self, $elem, $doc ) = @_;
    ...
}

1;


=encoding utf-8

=head1 NAME

TooMuchCode::ProhibitLargeTryBlock -- Find oversized `try..catch` block.

=head1 DESCRIPTION

You may or may not consider it a bad idea to have a lot of code in a
C<try> block.  And if you do, this module can be used to catch the
oversize try blocks.

=cut
