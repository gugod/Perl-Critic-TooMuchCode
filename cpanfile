requires 'Perl::Critic';
requires 'PPIx::Utils';
requires 'List::Util';

on test => sub {
    requires 'Test2::V0';
};
