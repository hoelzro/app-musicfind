#!/usr/bin/perl

use strict;
use warnings;

BEGIN
{
    # MP3::Info is just used as a dummy module here
    eval {
        require MP3::Info;
        MP3::Info->import();
    };
    if($@) {
        die "MP3::Info not found; please install it if you want FLAC support.\n";
    }
}

sub accept
{
    return 0;
}
1;
