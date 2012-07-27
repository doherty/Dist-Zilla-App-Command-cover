package Dist::Zilla::App::Command::cover;
use 5.008;
use strict;
use warnings;
# ABSTRACT: Code coverage metrics for your distribution
# VERSION

use Dist::Zilla::App -command;

=head1 SYNOPSIS

    # dzil cover -launch

=head1 DESCRIPTION

This is a command plugin for L<Dist::Zilla>. It provides the C<cover> command,
which generates code coverage metrics for your distribution using
L<Devel::Cover>.

If there were any test errors, the C<cover> command won't be run. Author and
release tests are not run since they should not be counted against code
coverage. Any additional command-line arguments are passed to the C<cover>
command.

=for Pod::Coverage abstract execute

=cut

sub abstract { "code coverage metrics for your distribution" }

sub execute {
    my $self = shift;
    require File::Temp;
    require Path::Class;
    require File::chdir;

    local $ENV{HARNESS_PERL_SWITCHES} = '-MDevel::Cover';
    my @cover_command = @ARGV;

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

    $self->log(join ' ' => @cover_command);
    local $File::chdir::CWD = $target;
    system @cover_command;
    $self->log("leaving $target intact");
}

1;
