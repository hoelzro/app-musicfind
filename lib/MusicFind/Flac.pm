#!/usr/bin/perl

package MusicFind::Flac;

use strict;
use warnings;

require MusicFind;
use Audio::FLAC::Header;

our $VERSION = 1.0;
our @ISA = qw(MusicFind);

sub new
{
    my ($class, $filename) = @_;
    my $this= MusicFind::new($class);
    $this->{'filename'} = $filename;
    $this->reload();
    return $this;
}

sub accept
{
    my ($class, $filename) = @_;
    # Can we make this more efficient (Audio::FLAC::Header, unlike
    #     Ogg::Vorbis::Header, loads all metadata with new)
    return $filename =~ /\.flac$/i && Audio::FLAC::Header->new($filename);
}

sub channels
{
    my $this = shift;
    return $this->{'object'}->info('NUMCHANNELS');
}

sub set_tag
{
    my ($this, @nameValuePairs) = @_;

    for(my $i = 0; $i < @nameValuePairs; $i += 2) {
        $this->{'tags'}{$this->{'mapping'}{lc $nameValuePairs[$i]}} = $nameValuePairs[$i + 1];
    }
    $this->{'object'}->write;
}

sub delete_tag
{
    my ($this, @names) = @_;
    local $_;

    foreach (@names) {
        delete $this->{'tags'}{$this->{'mapping'}{lc $_}};
    }
}

sub tag
{
    my ($this, $name) = @_;

    return $this->{'tags'}{$this->{'mapping'}{lc $name}} || '';
}

sub filename
{
    my $this = shift;
    return $this->{'filename'};
}

sub reload
{
    my $this = shift;

    local $_;

    $this->{'object'} = Audio::FLAC::Header->new($this->{'filename'});
    unless($this->{'object'}) {
        die "Somehow, a non-FLAC file slipped through accept: " .
            $this->{'filename'};
    }
    $this->{'tags'} = $this->{'object'}->tags();
    $this->{'mapping'} = {};
    foreach (keys %{$this->{'tags'}}) {
        $this->{'mapping'}{lc $_} = $_;
    }
    $this->dirty = undef; # Not really needed, but nice
}
1;
