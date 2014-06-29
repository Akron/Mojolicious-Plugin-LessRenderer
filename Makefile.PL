#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    VERSION_FROM => 'lib/Mojolicious/Plugin/LessRenderer.pm',
    NAME         => 'Mojolicious::Plugin::LessRenderer',
    AUTHOR       => 'Nils Diewald',
    PREREQ_PM => {
        'Mojolicious' => 5.00,
        'CSS::LESSp' => 0.86,
	'CSS::Compressor' => 0.02
    },
    test => {TESTS => 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t'}
);

