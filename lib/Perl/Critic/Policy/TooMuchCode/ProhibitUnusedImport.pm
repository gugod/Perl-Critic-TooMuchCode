package Perl::Critic::Policy::TooMuchCode::ProhibitUnusedImport;

use strict;
use warnings;
use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

# Part of Perl-Critic distribution
use Perl::Critic::Policy::Variables::ProhibitUnusedVariables;
use Perl::Critic::TooMuchCode;

sub default_themes       { return qw( maintenance )     }
sub applies_to           { return 'PPI::Document' }

#---------------------------------------------------------------------------

# special modules, where the args of import do not mean the symbols to be imported.
my %is_special = map { $_ => 1 } qw(Getopt::Long MooseX::Foreign MouseX::Foreign Exporter Test::Requires);

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my %imported;
    $self->gather_imports_generic( \%imported, $elem, $doc );

    my %used;
    for my $el_word (
        @{
            $elem->find(
                sub {
                    $_[1]->isa('PPI::Token::Word')
                        || ( $_[1]->isa('PPI::Token::Symbol')
                        && $_[1]->symbol_type eq '&' );
                }
                )
                || []
        }
    ) {
        if ( $el_word->isa('PPI::Token::Symbol') ) {
            $el_word =~ s{^&}{};
        }
        $used{"$el_word"}++;
    }

    ## Look for the signature of misparsed ternary operator.
    ## https://github.com/adamkennedy/PPI/issues/62
    ## Once PPI is fixed, this workaround can be eliminated.
    Perl::Critic::TooMuchCode::__get_terop_usage(\%used, $doc);

    Perl::Critic::Policy::Variables::ProhibitUnusedVariables::_get_symbol_usage(\%used, $doc);
    Perl::Critic::Policy::Variables::ProhibitUnusedVariables::_get_regexp_symbol_usage(\%used, $doc);

    my @violations;
    my @to_report = sort { $a cmp $b } grep { !$used{$_} } (keys %imported);
    for my $tok (@to_report) {
        for my $inc_mod (@{ $imported{$tok} }) {
            push @violations, $self->violation( "Unused import: $tok", "A token is imported but not used in the same code.", $inc_mod );
        }
    }

    return @violations;
}

sub gather_imports_generic {
    my ( $self, $imported, $elem, $doc ) = @_;

    my $include_statements = $elem->find(sub { $_[1]->isa('PPI::Statement::Include') && !$_[1]->pragma }) || [];
    for my $st (@$include_statements) {
        next if $st->schild(0) eq 'no';
        my $expr_qw = $st->find( sub { $_[1]->isa('PPI::Token::QuoteLike::Words'); }) or next;

        my $included_module = $st->schild(1);
        next if $is_special{$included_module};

        if (@$expr_qw == 1) {
            my $expr = $expr_qw->[0];
            my @words = $expr_qw->[0]->literal;
            for my $w (@words) {
                next if $w =~ /\A [:\-\+]/x;
                push @{ $imported->{$w} //=[] }, $included_module;
            }
        }
    }
}


1;

=encoding utf-8

=head1 NAME

TooMuchCode::ProhibitUnusedImport -- Find unused imports

=head1 DESCRIPTION

An "Unused Import" is usually a subroutine name imported by a C<use> statement.
For example, the word C<Dumper> in the following statement:

    use Foo qw( baz );

The word C<baz> can be removed if it is not mentioned in the rest of this program.

Conventionally, this policy looks only for the C<use> statement with a C<qw()>
operator at the end. This syntax is easier to deal with. It also works with
the usage of C<Importer> module -- as long as a C<qw()> is there at the end:

    use Importer 'Foo' => qw( baz );

This may be adjusted to be a bit smarter, but it is a clear convention in the
beginning.

=cut
