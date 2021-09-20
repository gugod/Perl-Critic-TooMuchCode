package Perl::Critic::Policy::TooMuchCode::ProhibitDuplicateLiteral;
use strict;
use warnings;
use List::Util 1.33 qw(any);
use Perl::Critic::Utils;
use PPI;
use parent 'Perl::Critic::Policy';

sub default_themes       { return qw( bugs maintenance )     }
sub applies_to           { return 'PPI::Document' }

sub supported_parameters {
    return ({
        name           => 'whitelist_numbers',
        description    => 'A comma-separated list of numbers that can be allowed to occur multiple times.',
        default_string => "0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, -2, -3, -4, -5, -6, -7, -8, -9",
        behavior       => 'string',
        parser         => \&_parse_whitelist_numbers,
    }, {
        name           => 'allowed_strings',
        description    => 'A list of strings that can be allowed to occur multiple times.',
        default_string => "0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, -2, -3, -4, -5, -6, -7, -8, -9",
        behavior       => 'string',
        parser         => \&_parse_allowed_strings,
    }, , {
        name           => 'whitelist',
        description    => 'A list of numbers or quoted strings that can be allowed to occur multiple times.',
        default_string => "0 1",
        behavior       => 'string',
        parser         => \&_parse_whitelist,
    });
}

sub _parse_whitelist {
    my ($self, $param, $value) = @_;
    my $default = $param->get_default_string();

    my %whitelist;
    for my $v (grep { defined } ($default, $value)) {
        my $allowed_strings_parser = PPI::Document->new(\$v);
        for my $token (@{$allowed_strings_parser->find('PPI::Token::Number') ||[]}) {
            $whitelist{ $token->content } = 1;
        }
        for my $quoted_token (@{$allowed_strings_parser->find('PPI::Token::Quote') ||[]}) {
            $whitelist{ $quoted_token->string } = 1;
        }
    }
    $self->{_whitelist} = \%whitelist;
    return undef;
}

sub _parse_whitelist_numbers {
    my ($self, $param, $value) = @_;
    my $default = $param->get_default_string();
    my %nums = map { $_ => 1 } grep { defined($_) && $_ ne '' } map { split /\s*,\s*/ } ($default, $value //'');
    $self->{_whitelist_numbers} = \%nums;
    return undef;
}

sub _parse_allowed_strings {
    my ($self, $param, $value) = @_;

    my %whitelist;
    if (defined $value) {
        my $allowed_strings_parser = PPI::Document->new(\$value);
        for my $quoted_token (@{$allowed_strings_parser->find('PPI::Token::Quote') ||[]}) {
            $whitelist{ $quoted_token->string } = 1;
        }
    }

    $self->{"_allowed_strings"} = \%whitelist;
}

sub violates {
    my ($self, undef, $doc) = @_;
    my %firstSeen;
    my @violations;

    for my $el (@{ $doc->find('PPI::Token::Quote') ||[]}) {
        my $val = $el->string;
        next if $self->{"_allowed_strings"}{$val};
        next if $self->{"_whitelist"}{$val};

        if ($firstSeen{"$val"}) {
            push @violations, $self->violation(
                "A duplicate quoted literal at line: " . $el->line_number . ", column: " . $el->column_number,
                "Another string literal in the same piece of code.",
                $el,
            );
        } else {
            $firstSeen{"$val"} = $el->location;
        }
    }

    %firstSeen = ();
    for my $el (@{ $doc->find('PPI::Token::Number') ||[]}) {
        my $val = $el->content;
        next if $self->{"_whitelist_numbers"}{"$val"};
        next if $self->{"_whitelist"}{$val};
        if ($firstSeen{"$val"}) {
            push @violations, $self->violation(
                "A duplicate numerical literal at line: " . $el->line_number . ", column: " . $el->column_number,
                "Another string literal in the same piece of code.",
                $el,
            );
        } else {
            $firstSeen{"$val"} = $el->location;
        }
    }

    return @violations;
}

1;

__END__

=head1 NAME

TooMuchCode::ProhibitDuplicateLiteral - Don't repeat yourself with identical literals

=head1 DESCRIPTION

This policy checks if there are string/number literals with identical
value in the same piece of perl code. Usually that's a small signal of
repeating and perhaps a small chance of refactoring.

Some strings may be allowed as duplicates by listing them as quoted
strings via the C<allowed_strings> configuration option:

    [TooMuchCode:ProhibitDuplicateLiteral]
    allowed_strings = 'word' 'or any other quoted string'

Certain numbers are whitelisted and not being checked in this policy
because they are conventionally used everywhere.

The default whitelist is 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, -2, -3, -4, -5, -6, -7, -8, -9

To opt-out more, add C<whitelist_numbers> like this in C<.perlcriticrc>

    [TooMuchCode::ProhibitDuplicateLiteral]
    whitelist_numbers = 42, 10

This configurable parameter appends to the default whitelist and there
are no way to remove the default whitelist.

A string literal with its numerical literal counterpart with same
value (C<1> vs C<"1">) are considered to be two distinct values.
Since it's a bit rare to explicitly hard-code number as string literals,
it shouldn't make much difference otherwise. However this is just
an arbitrary choice and might be adjusted in future versions.

=cut
