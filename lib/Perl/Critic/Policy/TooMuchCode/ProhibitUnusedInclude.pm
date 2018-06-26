package Perl::Critic::Policy::TooMuchCode::ProhibitUnusedInclude;

use strict;
use warnings;
use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

our $VERSION = '0.01';

sub default_themes       { return qw( maintenance )     }
sub applies_to           { return 'PPI::Document' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    my @violations = $self->gather_violtaions_trytiny($elem, $doc);
    push @violations, $self->gather_violtaions_filespec($elem, $doc);
    return @violations;
}

sub gather_violtaions_trytiny {
    my ( $self, $elem, $doc ) = @_;
    my @use_try_tiny = grep { $_->module eq 'Try::Tiny' } @{ $elem->find('PPI::Statement::Include') ||[] };
    return () unless 0 < @use_try_tiny;

    my $has_try_block = 0;
    for my $try_keyword (@{ $elem->find(sub { $_[1]->isa('PPI::Token::Word') && $_[1]->content eq "try" }) ||[]}) {
        my $try_block = $try_keyword->snext_sibling or next;
        next unless $try_block->isa('PPI::Structure::Block');
        $has_try_block = 1;
        last;
    }
    return () if $has_try_block;

    return map {
        $self->violation("Unused Try::Tiny module", "There are no `try` block in the code.", $_);
    } @use_try_tiny;
}

sub gather_violtaions_filespec {
    my ( $self, $elem, $doc ) = @_;

    my @include_statements = grep { $_->module eq 'File::Spec' } @{ $elem->find('PPI::Statement::Include') ||[] };
    return () unless 0 < @include_statements;

    my $is_unused = ! $elem->find(
        sub {
            my $el = $_[1];
            $el->isa('PPI::Token::Word') && $el->content eq 'File::Spec' && !($el->parent->isa('PPI::Statement::Include'))
        }
    );

    return unless $is_unused;
    return map {
        $self->violation("Unused File::Spec module.", "No methods from File::Spec are invoked.", $_)
    } @include_statements;
}

1;

=encoding utf-8

=head1 NAME

TooMuchCode::ProhibitUnusedInclude -- Find unused include statements.

=head1 DESCRIPTION

This critic policy scans for unused include statement according to their documentation.

For example, L<Try::Tiny> implicity introduce a C<try> subroutine that takes a block. There fore, A
lonely C<use Try::Tiny> statement without a C<try { .. }> block somewhere in its scope is considered
to be an "Unused Include".

=cut
