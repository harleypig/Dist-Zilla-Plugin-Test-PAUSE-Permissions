use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Warnings 0.005 ':no_end_test', ':all';
use Test::DZil;
use Path::Tiny;
use Safe::Isa;
use File::pushd 'pushd';

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ 'Test::PAUSE::Permissions' ],
                    [ '%PAUSE' => { username => 'username', password => 'password' } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );
    $tzil->build;

    my $build_dir = path($tzil->tempdir)->child('build');
    my $file = $build_dir->child(qw(xt release pause-permissions.t));
    ok(-e $file, 'test created');

    my $content = $file->slurp_utf8;
    unlike($content, qr/[^\S\n]\n/m, 'no trailing whitespace in generated test');

    like($content, qr/^all_permissions_ok\('username'\);$/m, 'username extracted from stash and passed to test');

    subtest 'run the generated test' => sub
    {
        my $wd = pushd $build_dir;

        # ensure we don't call out to the network when running the test
        local $ENV{RELEASE_TESTING};
        allow_warnings(1);
        do $file;
        allow_warnings(0);
        warn $@ if $@ and not $@->$_isa('Test::Builder::Exception');
    };
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ 'Test::PAUSE::Permissions' ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );
    $tzil->build;

    my $build_dir = path($tzil->tempdir)->child('build');
    my $file = $build_dir->child(qw(xt release pause-permissions.t));
    ok(-e $file, 'test created');

    my $content = $file->slurp_utf8;
    unlike($content, qr/[^\S\n]\n/m, 'no trailing whitespace in generated test');

    like($content, qr/^all_permissions_ok\(\);$/m, 'no username passed to test');
}

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;
