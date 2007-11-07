#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'MusicFind',
    VERSION_FROM => 'lib/MusicFind.pm',
    EXE_FILES => ['musicfind']
);
