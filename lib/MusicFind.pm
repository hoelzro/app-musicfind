#!/usr/bin/perl

package MusicFind;

use strict;
use warnings;

use constant DEBUG => 0;

BEGIN
{
    if(DEBUG) {
        require Data::Dumper;
        Data::Dumper->import();
    }
}

require Exporter;

our $VERSION = 1.0;
our @ISA = qw(Exporter);
our @EXPORT = qw(DEBUG);
our @EXPORT_OK = @EXPORT;
our %EXPORT_TAGS = (':DEFAULT' => \@EXPORT);

our $noconfirm;

sub promptYesNo
{
    my ($this, $prompt) = @_;
    my $answer;

    local $| = 1;
    do {
        if(defined $answer) {
            print STDERR "Please enter either \'yes\' or \'no\': ";
        } else {
            print STDERR $prompt;
        }
        $answer = <STDIN>;
        chomp $answer;
        $answer = '' unless($answer eq 'yes' || $answer eq 'no');
    } until($answer);
    return $answer eq 'yes';
}

sub substitute
{
    my ($this, $string) = @_;

    $string =~ s/%(%|(\w*))/$1 eq '%' ? '%' : $this->tag($1)/ge;
    if($string =~ /\// && ! $MusicFind::noconfirm) {
        undef $string unless($this->promptYesNo($this->filename . "'s tags contain one or more \'/\' characters; do you still want to go through with the rename/exec? (yes/no) "));
    }
    return $string;
}

sub rename
{
    my ($this, $newName) = @_;

    $this->flush if($this->writeTags);
    my $name = $this->{'filename'};
    my $extension = '';
    if($name =~ /(\.[^.]*)$/) {
        $extension = $1;
    }
    $newName = $this->substitute($newName);
    return unless(defined $newName);
    $newName = $this->{'directory'} . '/' . $newName . $extension;
    return if($name eq $newName);
    if(DEBUG) {
        print "Renaming $name to $newName\n";
    } else {
        if(-e $newName && ! $MusicFind::noconfirm) {
            return unless($this->promptYesNo("$newName already exists;  do you still want to rename $name to $newName? (yes/no) "));
        }
        rename $name, $newName or warn "Unable to rename $name to $newName: $!\n";
    }
    $this->{filename} = $newName;
    $this->dirty = 1;
}

sub _print
{
    my ($this, $format) = @_;

    if($format) {
        # We don't care about /s in the substitution here
        local $MusicFind::noconfirm = 1;
        print $this->substitute($format);
    } else {
        print $this->filename;
    }
}

sub print
{
    my ($this, $format) = @_;
    local $\ = "\n";
    $this->_print($format);
}

sub print0
{
    my ($this, $format) = @_;
    local $\ = "\0";
    $this->_print($format);
}

sub exec
{
    my ($this, $programName, @args) = @_;

    $this->flush if($this->writeTags);
    $this->load if($this->dirty);

    local $_;
    @args = map {
        if($_ eq '{}') {
            $_ = $this->filename;
        } else {
            $_ = $this->substitute($_);
            return unless(defined $_);
        }
    } @args;

    if(DEBUG) {
        local $" = ' ';
        print "Running $programName @args\n";
    } else {
        system($programName, @args);
    }
}

sub new
{
    my ($class, $filename, $filedir) = @_;
    my $this = bless {dirty => undef, 
                      writeTags => undef,
                      directory => $filedir,
                      filename => $filename}, $class;
    eval {
        $this->load();
    };
    undef $this if($@);
    return $this;
}

sub dirty : lvalue
{
    my $this = shift;
    $this->{dirty};
}

sub writeTags : lvalue
{
    my $this = shift;
    $this->{writeTags};
}

sub accept
{
    return 0;
}

sub DESTROY
{
    my $this = shift;

    $this->flush() if($this->writeTags);
}
1;
__END__

=head1 NAME

MusicFind - Base class for MusicFind plugins

=head1 DESCRIPTION

MusicFind implements two methods that should not change in subclasses (but
there's nothing stopping you from overloading them), plus a utility method used
by those two methods.

=head2 Implemented Routines

=over

=item $object->promptYesNo($prompt)

Prompts the user for a yes/no answer.

=item $object->substitute($format)

Substitutes music file tags in for % marked fields, or % in for %%.  Examples:

C<$this-E<gt>substitute("%artist - %title") # Results in "System of a Down - Soil">

=item $object->rename($format)

Substitutes % fields in $format, and then renames the file represented by this
MusicFind object to the name generated by $format, keeping the file in its
original directory.

=item $object->print([$format])

If $format is not specified, this method just prints out the object's filename
to standard output.  Otherwise, it expands $format using substitute and prints
the resulting string.  Newlines are added to the output.

=item $object->print0([$format])

Just just C<print>, only this version prints a NULL character instead of a
newline.

=item $object->exec(@args)

Essentially performs system(@args), only each argument after the first is
run through substitute, and '{}' is replaced by the filename.  Similar to find's
exec.  If the execution fails, the program will warn the user.

=item $object->dirty

A read-write property indicating that the location of the current file has
changed.  Set to true after a rename action.  You shouldn't have to touch this.

=item $object->writeTags

A read-write property indicating that the file's tags have changed, and need to
be written to file.

=item $class->new($filename, $filedir)

This class method constructs a new object, and calls load() on that object.
Returns the new object or undef on failure.

=back

=head2 Abstract methods

=over

=item $class->accept($filename)

This class method should return true only if the plugin represented by $class can
handle the file specified by $filename.

=item $object->channels()

This method should return the number of audio channels in the file represented
by this MusicFind object.

=item $object->set_tag(@name_value_pairs)

This method should add/overwrite tags in the file;  items in @_ with an even
index are tag names; odd indices are the new tag values.  It should also set
$object->writeTags to a true value.

=item $object->delete_tag(@names)

This method should remove all of the tags in @names from the file.  It should
also set $object->writeTags to a true value.

=item $object->tag($name)

This method should return the value of the tag specified by $name.

=item $object->filename()

This method should return the filename of the file represented by this MusicFind
object.  Note:  This returns the full path to the file.

=item $object->load()

This method should load the wrapped object with the file given by
$object->{filename}.  This gets called by exec if the current object is dirty,
and also by new upon creation.  $object->dirty should be a false value after
this method is called.

See C<dirty>.

=item $object->flush()

This method should write the tags of the current file to disk.
$object->writeTags should be a false value after this method is called.

=back

Feel free to look at the standard plugins I've written to see how a plugin
should be written.

=head1 AUTHOR

Robert Hoelz <hoelz@wisc.edu>

=head1 COPYING

Copyright (c) 2007-2010, Robert Hoelz. All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version. A copy of this license is included with this module (LICENSE.GPL).

=cut
