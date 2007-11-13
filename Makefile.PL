#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'MusicFind',
    VERSION_FROM => 'lib/MusicFind.pm',
    EXE_FILES => ['musicfind']
);
print "For Ogg Vorbis support, install Ogg::Vorbis::Header\n";
print "For FLAC support, install Audio::FLAC::Header\n";
