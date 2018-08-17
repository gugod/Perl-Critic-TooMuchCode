package Perl::Critic::Policy::TooMuchCode::ProhibitExcessiveColons;

use strict;
use warnings;
use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

our $VERSION = '0.01';

sub default_themes       { return qw( maintenance )     }
sub applies_to           { return 'PPI::Statement::Include' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    my @violations = $self->gather_violations_generic($elem, $doc);
    return @violations;
}

sub gather_violations_generic {
    my ( $self, $elem, undef ) = @_;

    # PPI::Statement::Include doesn't handle this weird case of `use Data::::Dumper`.
    # The `PPI::Statement::Include#module` method does not catch 'Data::::Dumper' as the
    # module name, but `Data::` instead.
    # So we are just use strings here.
    return unless index("$elem", "::::") > 0;

    return $self->violation(
        "Too many colons in the module name.",
        "The statement <$elem> contains so many colons to separate namespaces, while 2 colons is usually enough.",
        $elem,
    );
}

1;

=encoding utf-8

=head1 NAME

TooMuchCode::ProhibitUnusedImport -- Find unused imports

=head1 DESCRIPTION

An "Unused Import" is usually a subroutine name imported by a C<use> statement.
For example, the word C<Dumper> in the following statement:

    use Data::Dumper qw<Dumper>;

If the rest of program has not mentioned the word C<Dumper>, then it can be deleted.

=cut
