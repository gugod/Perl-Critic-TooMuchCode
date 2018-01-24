package Perl::Critic::Policy::TooMuchCode::ProhibitUnnecessaryUTF8Pragma;
# ABSTRACT: "use utf8" is probably not needed if all characters in the source code are in 7bit ASCII range.

use strict;
use warnings;
use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

our $VERSION = '0.01';

sub default_themes       { return qw( tests )     }
sub applies_to           { return 'PPI::Document' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $use_utf8_statements = $elem->find(
        sub {
            my $st = $_[1];
            $st->isa('PPI::Statement::Include') && $st->schild(0) eq "use" && $st->schild(1) eq "utf8";
        }
    );
    return unless $use_utf8_statements;

    my $chars_outside_ascii_range = 0;
    for (my $tok = $elem->first_token; $tok; $tok = $tok->next_token) {
        next unless $tok->significant;
        my $src = $tok->content;
        utf8::decode($src);

        my @c = split "", $src;
        for (my $i = 0; $i < @c; $i++) {
            if (ord($c[$i]) > 127) {
                $chars_outside_ascii_range++;
            }
        }
        last if $chars_outside_ascii_range;
    }

    unless ($chars_outside_ascii_range) {
        return $self->violation(
            "'use utf8;' seems to be unnecessary",
            "All characters in the source code are within ASCII range.",
            $use_utf8_statements->[0],
        );
    }
    return;
}

1;
