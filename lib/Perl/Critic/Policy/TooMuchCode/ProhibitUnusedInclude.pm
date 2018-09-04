package Perl::Critic::Policy::TooMuchCode::ProhibitUnusedInclude;

use strict;
use warnings;
use Scalar::Util qw(refaddr);
use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

sub default_themes       { return qw( maintenance )     }
sub applies_to           { return 'PPI::Document' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my @includes = grep {
        !$_->pragma && $_->module !~ /\A Mo([ou](?:se)?)? (\z|::)/x
    } @{ $doc->find('PPI::Statement::Include') ||[] };
    return () unless @includes;

    my %uses;
    $self->gather_uses_try_family(\@includes, $doc, \%uses);
    $self->gather_uses_objective(\@includes, $doc, \%uses);
    $self->gather_uses_generic(\@includes, $doc, \%uses);

    return map {
        $self->violation(
            "Unused include: " . $_->module,
            "A module is `use`-ed but not really consumed in other places in the code",
            $_
        )
    } grep {
        ! $uses{refaddr($_)}
    } @includes;
}

sub gather_uses_generic {
    my ( $self, $includes, $doc, $uses ) = @_;

    my @words = grep { ! $_->statement->isa('PPI::Statement::Include') } @{ $doc->find('PPI::Token::Word') || []};
    my @mods = map { $_->module } @$includes;

    my %used;
    for my $word (@words) {
        for my $inc (@$includes) {
            my $mod = $inc->module;
            if ($word->content =~ /\A $mod (\z|::)/x) {
                $uses->{ refaddr($inc) } = 1;
            }
        }
    }
}

sub gather_uses_try_family {
    my ( $self, $includes, $doc, $uses ) = @_;

    my %is_try = map { $_ => 1 } qw(Try::Tiny Try::Catch Try::Lite TryCatch Try);
    my @uses_tryish_modules = grep { $is_try{$_->module} } @$includes;
    return unless @uses_tryish_modules;

    my $has_try_block = 0;
    for my $try_keyword (@{ $doc->find(sub { $_[1]->isa('PPI::Token::Word') && $_[1]->content eq 'try' }) ||[]}) {
        my $try_block = $try_keyword->snext_sibling or next;
        next unless $try_block->isa('PPI::Structure::Block');
        $has_try_block = 1;
        last;
    }
    return unless $has_try_block;

    $uses->{refaddr($_)} = 1 for @uses_tryish_modules;
}

sub gather_uses_objective {
    my ( $self, $includes, $doc, $uses ) = @_;

    my %is_objective = map { ($_ => 1) } qw(HTTP::Tiny HTTP::Lite LWP::UserAgent File::Spec);
    for my $inc (@$includes) {
        my $mod = $inc->module;
        next unless $is_objective{ $mod };

        my $is_used = $doc->find(
            sub {
                my $el = $_[1];
                $el->isa('PPI::Token::Word') && $el->content eq $mod && !($el->parent->isa('PPI::Statement::Include'))
            }
        );

        if ($is_used) {
            $uses->{ refaddr($inc) } = 1;
        }
    }
}

1;

=encoding utf-8

=head1 NAME

TooMuchCode::ProhibitUnusedInclude -- Find unused include statements.

=head1 DESCRIPTION

This critic policy scans for unused include statement according to their documentation.

For example, L<Try::Tiny> implicity introduce a C<try> subroutine that takes a block. Therefore, a
lonely C<use Try::Tiny> statement without a C<try { .. }> block somewhere in its scope is considered
to be an "Unused Include".

=cut
