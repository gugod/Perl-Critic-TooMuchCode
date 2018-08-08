package Perl::Critic::Policy::TooMuchCode::ProhibitUnnecessaryScalarKeyword;
use strict;
use warnings;

use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

sub default_themes       { return qw(maintenance)    }
sub applies_to           { return 'PPI::Token::Word' }

sub violates {
    my ( $self, $elem, undef ) = @_;
    return unless $elem->content eq 'scalar';
    my $e = $elem->snext_sibling;
    return unless $e && $e->isa('PPI::Token::Symbol') && $e->raw_type eq '@';
    $e = $elem->sprevious_sibling;
    return unless $e && $e->isa('PPI::Token::Operator') && $e->content eq '=';
    $e = $e->sprevious_sibling;
    return unless $e && $e->isa('PPI::Token::Symbol') && $e->raw_type eq '$';

    return $self->violation('Unnecessary scalar keyword', "Assigning an array to a scalar implies scalar context.", $elem);
}

1;
