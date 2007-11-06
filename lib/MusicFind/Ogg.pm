#!/usr/bin/perl

package MusicFind::Ogg;

use strict;
use warnings;

use MusicFind;

BEGIN
{
    eval {
        require Ogg::Vorbis::Header;
        Ogg::Vorbis::Header->import();
    };
    if($@) {
        die "Ogg::Vorbis::Header not found; please install it if you want FLAC support.\n";
    }
}

our $VERSION = 1.0;
our @ISA = qw(MusicFind);

sub new
{
    my ($class, $fullpath, $filename) = @_;
    my $this= MusicFind::new($class);
    $this->{'fullpath'} = $fullpath;
    $this->{'filename'} = $filename;
    eval {
        $this->reload();
    };
    undef $this if($@);
    return $this;
}

sub accept
{
    my ($class, $filename) = @_;
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

    if(@nameValuePairs % 2) {
        die "MusicFind::Ogg::set_tag was passed an odd-length list of name" .
            "-value pairs\n";
    }
    if(DEBUG) {
        for(my $i = 0; $i < @nameValuePairs; $i += 2) {
            my ($name, $value) = @nameValuePairs[$i, $i + 1];
            print "Changing tag $name to $value for ${\($this->filename())}\n";
        }
    } else {
        for(my $i = 0; $i < @nameValuePairs; $i += 2) {
            $nameValuePairs[$i] = lc $nameValuePairs[$i];
            $this->{'object'}->clear_comments($this->{'mapping'}{$nameValuePairs[$i]});
        }
        unless($this->{'object'}->add_comments(@nameValuePairs)) {
            die "An odd-length array was passed to add_comments in MusicFind::Ogg\n";
        }
        $this->{'object'}->write_vorbis;
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
            $this->{'object'}->clear_comments($this->{'mapping'}{lc $_});
        }
        $this->{'object'}->write_vorbis;
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

    $this->{'object'} = Ogg::Vorbis::Header->load($this->{'fullpath'});
    unless($this->{'object'}) {
        die "Somehow, a non-Ogg Vorbis file slipped through accept: " .
            $this->{'fullpath'};
    }
    $this->{'mapping'} = {};
    foreach ($this->{'object'}->comment_tags()) {
        $this->{'mapping'}{lc $_} = $_;
    }
    $this->dirty = undef; # Not strictly necessary
}
1;
