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
    my ($class, $fullpath, $filename) = @_;
    my $this= MusicFind::new($class);
    $this->{'fullpath'} = $fullpath;
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

    if(@nameValuePairs % 2) {
        die "MusicFind::Flac::set_tag was passed an odd-length list of name" .
            "-value pairs\n";
    }
    if(DEBUG) {
        for(my $i = 0; $i < @nameValuePairs; $i += 2) {
            my ($name, $value) = @nameValuePairs[$i, $i + 1];

            print "Changing tag $name to $value for ${\($this->filename())}\n";
        }
    } else {
        for(my $i = 0; $i < @nameValuePairs; $i += 2) {
            my $lcName = lc $nameValuePairs[$i];
            my $value = $nameValuePairs[$i + 1];
            $this->{'tags'}{$this->{'mapping'}{$lcName} || $lcName} = $value;
        }
        $this->{'object'}->write;
    }
}

sub delete_tag
{
    my ($this, @names) = @_;
    local $_;

    if(DEBUG) {
        local $" = ' ';
        print "Deleting tags @names for ${\($this->filename())}\n";
    } else {
        foreach (@names) {
            my $lcName = lc $_;
            my $mapping = $this->{'mapping'}{$lcName};
            if(defined $mapping) {
                delete $this->{'tags'}{$mapping};
                delete $this->{'mapping'}{$lcName};
            }
        }
        $this->{'object'}->write;
    }
}

sub tag
{
    my ($this, $name) = @_;

    return $this->{'tags'}{$this->{'mapping'}{lc $name} || ''} || '';
}

sub filename
{
    my $this = shift;
    return $this->{'fullpath'};
}

sub reload
{
    my $this = shift;

    local $_;

    $this->{'object'} = Audio::FLAC::Header->new($this->{'fullpath'});
    unless($this->{'object'}) {
        die "Somehow, a non-FLAC file slipped through accept: " .
            $this->{'fullpath'};
    }
    $this->{'tags'} = $this->{'object'}->tags();
    $this->{'mapping'} = {};
    foreach (keys %{$this->{'tags'}}) {
        $this->{'mapping'}{lc $_} = $_;
    }
    $this->dirty = undef; # Not really needed, but nice
}
1;
