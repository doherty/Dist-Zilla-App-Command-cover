use 5.008;
use strict;
use warnings;

package Dist::Zilla::App::Command::cover;

# ABSTRACT: Code coverage metrics for your distribution
use Dist::Zilla::App -command;
use File::Temp;
use Path::Class;
use File::chdir;
use Browser::Open qw( open_browser );
sub abstract { "code coverage metrics for your distribution" }

sub opt_spec {
    [ 'cover_args=s' => 'arguments to pass to cover command',
        { Default => '' } ],
    [ 'open'         => 'open the coverage results in a browser'    ],
}

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->usage_error("unknown arguments @$args") if @$args != 0;
}

sub execute {
    my ($self, $opt, $args) = @_;
    local $ENV{HARNESS_PERL_SWITCHES} = '-MDevel::Cover';

    # adapted from the 'test' command
    my $zilla = $self->zilla;
    my $build_root = Path::Class::dir('.build');
    $build_root->mkpath unless -d $build_root;
    my $target = Path::Class::dir(File::Temp::tempdir(DIR => $build_root));
    $self->log("building test distribution under $target");

    # Don't run author and release tests during code coverage.
    # local $ENV{AUTHOR_TESTING}  = 1;
    # local $ENV{RELEASE_TESTING} = 1;

    $zilla->ensure_built_in($target);
    $self->zilla->run_tests_in($target);

    my $cover_command = 'cover ' . $opt->cover_args;
    $self->log($cover_command);
    local $CWD = $target;
    system $cover_command;
    $self->log("leaving $target intact");

    if ($opt->open) {
        open_browser("cover_db/coverage.html", 1);
    }
}
1;

=head1 SYNOPSIS

    # dzil cover --cover_args='-outputdir /my/dir' --open

=head1 DESCRIPTION

This is a command plugin for L<Dist::Zilla>. It provides the C<cover> command,
which generates code coverage metrics for your distribution using
L<Devel::Cover>.

If there were any test errors, the C<cover> command won't be run. Author and
release tests are not run since they should not be counted against code
coverage.

=head1 ARGUMENTS

=item --cover_args="<args>"

Arguments to pass to the cover command.

=item --open

Open the coverage results in a browser.
