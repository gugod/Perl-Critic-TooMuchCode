package Perl::Critic::Policy::TooMuchCode::ProhibitDeeplyNestedIfs;

use strict;
use warnings;
use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

sub default_themes       { return qw(maintenance)     }
sub applies_to           { return 'PPI::Statement::Compound' }

sub violates {
    my ( $self, $elem, $doc ) = @_;
    my $limit = $self->{nested_level_limit} || 3;

    my $c0 = $elem->schild(0);
    return unless $c0 && $c0->isa('PPI::Token::Word') && $c0 eq 'if';
    my $level = 0;
    my $p = $elem;
    $level++ while(($level < $limit) && ($p = is_nested_in_a_if_block($p)));

    return if $level < $limit;

    return $self->violation('The `if` is nested too deep.', "The `if` statement is ${level}-level deep, larger then the limit of ${limit}", $elem);
}

sub is_nested_in_a_if_block {
    my ($elem) = @_;
    my $p = $elem->parent;
    return undef unless $p && $p->isa('PPI::Structure::Block');

    $p = $p->parent;
    return undef unless $p && $p->isa('PPI::Statement::Compound');

    my $c0 = $p->schild(0);
    return undef unless $c0 && $c0->isa('PPI::Token::Word') && $c0 eq 'if';
    return $p;
}

1;
