package Perl::Critic::Policy::TooMuchCode::ProhibitUnusedInclude;

use strict;
use warnings;
use Scalar::Util qw(refaddr);
use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

sub default_themes       { return qw( maintenance )     }
sub applies_to           { return 'PPI::Document' }

sub supported_parameters {
    return (
        +{
            name => 'ignore',
            description => 'List of modules to be disregarded. Separated by whitespaces.',
            behavior => 'string list',
        }
    )
}

#---------------------------------------------------------------------------


## this mapping fines a set of modules with behaviour that introduce
## new words as subroutine names or method names when they are `use`ed
## without argumnets.

# perlbrew list-modules | xargs -n1 -I{} -- perl -M{} -l -e 'if (my @e = grep /\A\w+\z/, (@{}::EXPORT) ) { print "### \x27{}\x27 => [qw(@e)],"; }' \;  2>/dev/null | grep '^### ' | cut -c 5-
use constant DEFAULT_EXPORT => {
    'B::Hooks::EndOfScope'         => [qw(on_scope_end)],
    'Carp::Assert'                 => [qw(assert affirm should shouldnt DEBUG assert affirm should shouldnt DEBUG)],
    'Carp::Assert::More'           => [qw(assert_all_keys_in assert_arrayref assert_coderef assert_defined assert_empty assert_exists assert_fail assert_hashref assert_in assert_integer assert_is assert_isa assert_isa_in assert_isnt assert_lacks assert_like assert_listref assert_negative assert_negative_integer assert_nonblank assert_nonempty assert_nonnegative assert_nonnegative_integer assert_nonref assert_nonzero assert_nonzero_integer assert_numeric assert_positive assert_positive_integer assert_undefined assert_unlike)],
    'Class::Method::Modifiers'     => [qw(before after around)],
    'Compress::Raw::Bzip2'         => [qw(BZ_RUN BZ_FLUSH BZ_FINISH BZ_OK BZ_RUN_OK BZ_FLUSH_OK BZ_FINISH_OK BZ_STREAM_END BZ_SEQUENCE_ERROR BZ_PARAM_ERROR BZ_MEM_ERROR BZ_DATA_ERROR BZ_DATA_ERROR_MAGIC BZ_IO_ERROR BZ_UNEXPECTED_EOF BZ_OUTBUFF_FULL BZ_CONFIG_ERROR)],
    'Compress::Raw::Zlib'          => [qw(ZLIB_VERSION ZLIB_VERNUM OS_CODE MAX_MEM_LEVEL MAX_WBITS Z_ASCII Z_BEST_COMPRESSION Z_BEST_SPEED Z_BINARY Z_BLOCK Z_BUF_ERROR Z_DATA_ERROR Z_DEFAULT_COMPRESSION Z_DEFAULT_STRATEGY Z_DEFLATED Z_ERRNO Z_FILTERED Z_FIXED Z_FINISH Z_FULL_FLUSH Z_HUFFMAN_ONLY Z_MEM_ERROR Z_NEED_DICT Z_NO_COMPRESSION Z_NO_FLUSH Z_NULL Z_OK Z_PARTIAL_FLUSH Z_RLE Z_STREAM_END Z_STREAM_ERROR Z_SYNC_FLUSH Z_TREES Z_UNKNOWN Z_VERSION_ERROR WANT_GZIP WANT_GZIP_OR_ZLIB crc32 adler32 DEF_WBITS)],
    'Cookie::Baker'                => [qw(bake_cookie crush_cookie)],
    'Cpanel::JSON::XS'             => [qw(encode_json decode_json to_json from_json)],
    'Crypt::RC4'                   => [qw(RC4)],
    'DBIx::DSN::Resolver::Cached'  => [qw(dsn_resolver)],
    'DBIx::DisconnectAll'          => [qw(dbi_disconnect_all)],
    'Data::Clone'                  => [qw(clone)],
    'Data::Compare'                => [qw(Compare)],
    'Data::Dump'                   => [qw(dd ddx)],
    'Data::NestedParams'           => [qw(expand_nested_params collapse_nested_params)],
    'Data::UUID'                   => [qw(NameSpace_DNS NameSpace_OID NameSpace_URL NameSpace_X500)],
    'Data::Validate::Domain'       => [qw(is_domain is_hostname is_domain_label)],
    'Data::Validate::IP'           => [qw(is_ip is_ipv4 is_ipv6 is_innet_ipv4 is_unroutable_ipv4 is_testnet_ipv4 is_multicast_ipv4 is_linklocal_ipv4 is_private_ipv4 is_loopback_ipv4 is_anycast_ipv4 is_public_ipv4 is_loopback_ipv6 is_linklocal_ipv6 is_private_ipv6 is_documentation_ipv6 is_orchid_ipv6 is_discard_ipv6 is_multicast_ipv6 is_teredo_ipv6 is_special_ipv6 is_ipv4_mapped_ipv6 is_public_ipv6 is_linklocal_ip is_loopback_ip is_multicast_ip is_private_ip is_public_ip)],
    'Data::Walk'                   => [qw(walk walkdepth)],
    'Devel::CheckCompiler'         => [qw(check_c99 check_c99_or_exit check_compile)],
    'Devel::CheckLib'              => [qw(assert_lib check_lib_or_exit check_lib)],
    'Devel::GlobalDestruction'     => [qw(in_global_destruction)],
    'Dist::CheckConflicts'         => [qw(conflicts check_conflicts calculate_conflicts dist)],
    'Email::MIME::ContentType'     => [qw(parse_content_type parse_content_disposition)],
    'Encode'                       => [qw(decode decode_utf8 encode encode_utf8 str2bytes bytes2str encodings find_encoding find_mime_encoding clone_encoding)],
    'Eval::Closure'                => [qw(eval_closure)],
    'ExtUtils::MakeMaker'          => [qw(WriteMakefile prompt os_unsupported)],
    'File::HomeDir'                => [qw(home)],
    'File::Listing'                => [qw(parse_dir)],
    'File::Path'                   => [qw(mkpath rmtree)],
    'File::ShareDir::Install'      => [qw(install_share delete_share)],
    'File::Which'                  => [qw(which)],
    'File::Zglob'                  => [qw(zglob)],
    'File::pushd'                  => [qw(pushd tempd)],
    'Graphics::ColorUtils'         => [qw(rgb2yiq yiq2rgb rgb2cmy cmy2rgb rgb2hls hls2rgb rgb2hsv hsv2rgb)],
    'HTML::Escape'                 => [qw(escape_html)],
    'HTTP::Date'                   => [qw(time2str str2time)],
    'HTTP::Negotiate'              => [qw(choose)],
    'IO::HTML'                     => [qw(html_file)],
    'IO::Socket::SSL'              => [qw(SSL_WANT_READ SSL_WANT_WRITE SSL_VERIFY_NONE SSL_VERIFY_PEER SSL_VERIFY_FAIL_IF_NO_PEER_CERT SSL_VERIFY_CLIENT_ONCE SSL_OCSP_NO_STAPLE SSL_OCSP_TRY_STAPLE SSL_OCSP_MUST_STAPLE SSL_OCSP_FAIL_HARD SSL_OCSP_FULL_CHAIN GEN_DNS GEN_IPADD)],
    'IPC::Run3'                    => [qw(run3)],
    'JSON'                         => [qw(from_json to_json jsonToObj objToJson encode_json decode_json)],
    'JSON::MaybeXS'                => [qw(encode_json decode_json JSON)],
    'JSON::PP'                     => [qw(encode_json decode_json from_json to_json)],
    'JSON::Types'                  => [qw(number string bool)],
    'JSON::XS'                     => [qw(encode_json decode_json)],
    'LWP::MediaTypes'              => [qw(guess_media_type media_suffix)],
    'Lingua::JA::Regular::Unicode' => [qw(hiragana2katakana alnum_z2h alnum_h2z space_z2h katakana2hiragana katakana_h2z katakana_z2h space_h2z)],
    'Locale::Currency::Format'     => [qw(currency_format currency_name currency_set currency_symbol decimal_precision decimal_separator thousands_separator FMT_NOZEROS FMT_STANDARD FMT_COMMON FMT_SYMBOL FMT_HTML FMT_NAME SYM_UTF SYM_HTML)],
    'Log::Minimal'                 => [qw(critf critff warnf warnff infof infoff debugf debugff croakf croakff ddf)],
    'MIME::Charset'                => [qw(body_encoding canonical_charset header_encoding output_charset body_encode encoded_header_len header_encode)],
    'Math::Round'                  => [qw(round nearest)],
    'Module::Build::Tiny'          => [qw(Build Build_PL)],
    'Module::Find'                 => [qw(findsubmod findallmod usesub useall setmoduledirs)],
    'Module::Functions'            => [qw(get_public_functions)],
    'Module::Spy'                  => [qw(spy_on)],
};

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my @includes = grep {
        !$_->pragma && $_->module && $_->module !~ /\A Mo([ou](?:se)?)? (\z|::)/x && (! $self->{_ignore}{$_->module})
    } @{ $doc->find('PPI::Statement::Include') ||[] };

    # print STDERR Data::Dumper::Dumper({ ignore => $self->{_ignore}, inc_mod => \@includes });

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
    my @mods = grep { !$uses->{$_} } map { $_->module } @$includes;

    my @inc_without_args;
    for my $inc (@$includes) {
        if ($inc->arguments) {
            my $r = refaddr($inc);
            $uses->{$r} = -1;
        } else {
            push @inc_without_args, $inc;
        }
    }

    for my $word (@words) {
        for my $inc (@inc_without_args) {
            my $mod = $inc->module;
            my $r   = refaddr($inc);
            next if $uses->{$r};
            $uses->{$r} = 1 if $word->content =~ /\A $mod (\z|::)/x;
            $uses->{$r} = 1 if grep { $_ eq $word } @{DEFAULT_EXPORT->{$mod} ||[]};
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
        next unless $is_objective{$mod} && $doc->find(
            sub {
                my $el = $_[1];
                $el->isa('PPI::Token::Word') && $el->content eq $mod && !($el->parent->isa('PPI::Statement::Include'))
            }
        );

        $uses->{ refaddr($inc) } = 1;
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
