#!/usr/bin/perl

package MusicFind::Ogg;

use strict;
use warnings;

require MusicFind;
use Ogg::Vorbis::Header;

our $VERSION = 1.0;
our @ISA = qw(MusicFind);

sub new
{
    my ($class, $filename) = @_;
    my $this= MusicFind::new($class);
    $this->{'filename'} = $filename;
    $this->reload();
}

sub accept
{
    my ($this, $filename) = @_;
    return $filename =~ /\.ogg$/i && Ogg::Vorbis::Header->new($filename);
}

sub channels
{
    my $this = shift;
    return $this->{'object'}->info('channels');
}

sub set_tag
{
    my ($this, @nameValuePairs) = @_;

    for(my $i = 0; $i < @nameValuePairs; $i += 2) {
        $nameValuePairs[$i] = lc $nameValuePairs[$i];
        $this->{'object'}->clear_comments($this->{'mapping'}{$nameValuePairs[$i]});
    }
    $this->{'object'}->add_comments(@nameValuePairs);
}

sub delete_tag
{
    my ($this, @names) = @_;

    local $_;
    foreach (@names) {
        $this->{'object'}->clear_comments($this->{'mapping'}{lc $_});
    }
}

sub tag
{
    my ($this, $name) = @_;

    my @comments = $this->{'object'}->comment($this->{'mapping'}{lc $name});
    return $comments[0] || '';
}

sub filename
{
    my $this = shift;
    return $this->{'object'}->path();
}

sub reload
{
    my $this = shift;

    local $_;

    $this->{'object'} = Ogg::Vorbis::Header->load($this->{'filename'});
    $this->{'mapping'} = {};
    foreach ($this->{'object'}->comment_tags()) {
        $this->{'mapping'}{lc $_} = $_;
    }
    $this->dirty = undef; # Not strictly necessary
}
1;
