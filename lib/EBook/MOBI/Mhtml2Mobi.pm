package EBook::MOBI::Mhtml2Mobi;
# This file contains some example code, borrowed from MobiPerl.
# The code comes from the html2mobi file from MobiPerl.
# Thus this code has the same license than MobiPerl:

#    Copyright (C) 2011 Boris Daeppen <bod@perl-services.de>
#
#    ORIGINAL:
#    MobiPerl/EXTH.pm, Copyright (C) 2007 Tommy Persson, tpe@ida.liu.se
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This code creates a .mobi file for the Amazone Kindle eBook Reader
use strict;
use warnings;
use File::Basename;
use File::Spec;

# Use some project library
use EBook::MOBI::Picture;

# Use the library, downloaded from MobiPerl
use EBook::MOBI::Palm::PDB;
use EBook::MOBI::Palm::Doc;
use EBook::MOBI::MobiPerl::MobiHeader;
use EBook::MOBI::MobiPerl::Util;

# This values are set according to MobiPerl
use constant DOC_UNCOMPRESSED => scalar 1;
use constant DOC_COMPRESSED => scalar 2;
use constant DOC_RECSIZE => scalar 4096;

our $VERSION = 0.1;

# Constructor of this class
sub new {
    my $self=shift;
    my $ref={};

    $ref->{picture_paths} = []; # containing all the pictures path
    $ref->{mobi_pic} = EBook::MOBI::Picture->new();

    bless($ref, $self);
    return $ref;
}

sub debug_on {
    my ($self, $ref_to_debug_sub) = @_; 

    $self->{ref_to_debug_sub} = $ref_to_debug_sub;
    
    &$ref_to_debug_sub('DEBUG mode on');

    $self->{mobi_pic}->debug_on($ref_to_debug_sub);
}

sub debug_off {
    my ($self) = @_; 

    if ($self->{ref_to_debug_sub}) {
        &{$self->{ref_to_debug_sub}}('DEBUG mode off');
        $self->{ref_to_debug_sub} = 0;

        $self->{mobi_pic}->debug_off();
    }   
}

# Internal debug method
sub _debug {
    my ($self,$msg) = @_; 

    if ($self->{ref_to_debug_sub}) {
        &{$self->{ref_to_debug_sub}}($msg);
    }   
}

# This method does the job!
# Give it some (mobi compatible) HTML and it creates a Mobi file for you
sub pack {
    my ($self,      # object
        $html,      # data to put in the mobi eBook
        $filename,  # filename (with path) of the desired eBook
        $author,    # author of the eBook
        $title      # title of the eBook
       ) = @_;

    # un-comment if you need to see all the HTML
    #print "\n--HTML--\n$html\n--HTML--\n";

    # Palm DOC Header
    # According to MobiPerl (html2mobi)
    my $mobi = new EBook::MOBI::Palm::Doc;
    $mobi->{attributes}{"resource"} = 0;
    $mobi->{attributes}{"ResDB"} = 0;
    $mobi->{"name"} = $title;
    $mobi->{"type"} = "BOOK";
    $mobi->{"creator"} = "MOBI";
    $mobi->{"version"} = 0;
    $mobi->{"uniqueIDseed"} = 28;
    $mobi->{'records'} = [];
    $mobi->{'resources'} = [];

    # Inside Palm DOC Header is the MOBI Header
    # According to MobiPerl (html2mobi)
    my $header = $mobi->append_Record();    
    my $version = DOC_COMPRESSED;
    $header->{'version'} = $version;
    $header->{'length'} = 0;
    $header->{'records'} = 0;
    $header->{'recsize'} = DOC_RECSIZE;

    # Large HTML text must be devided into chunks...
    # break the document into record-sized chunks.
    # According to MobiPerl (html2mobi)
    my $current_record_index = 1;
    for( my $i = 0; $i < length($html); $i += DOC_RECSIZE ) {

        # DEBUG: print the current record index
        $self->_debug(
            'Storing HTML in the mobi format at record '
            . $current_record_index
            );
        my $record = $mobi->append_Record;
        my $chunk = substr($html,$i,DOC_RECSIZE);
        $record->{'data'} =
            EBook::MOBI::Palm::Doc::_compress_record
            ( $version, $chunk );
        $record->{'id'} = $current_record_index++;
        $header->{'records'} ++;
    }
    $header->{'length'} += length $html;
    $header->{'recsize'} = $header->{'length'}
        if $header->{'length'} < DOC_RECSIZE;

    # pack the Palm Doc  header
    # According to MobiPerl (html2mobi)
    $header->{'data'} = pack( 'n xx N n n N'      ,
                              $header->{'version'},
                              $header->{'length'} ,
                              $header->{'records'},
                              $header->{'recsize'},
                              0
                            );

    # Add MOBI header
    # According to MobiPerl (html2mobi)
    my $mh = new EBook::MOBI::MobiPerl::MobiHeader;
    $mh->set_title ($title);
    $mh->set_author ($author);
    $mh->set_image_record_index ($current_record_index);

    $header->{'data'} .= $mh->get_data ();

    # Add pictures into the binary mobi format.
    # Each picture gets its own record, so splitting into chunks.

    # Looking for pictures in the html data,
    # storing the path of the pics in $self->{picture_paths}
    $self->_gather_IMG_ref($html);
    
    # add each pic to the mobi container
    foreach my $img_path (@{$self->{picture_paths}}) {

        # We pass the picture to this object, to ensure that
        # the picture size is fine for the mobi format.
        # Return-value migth be a new path, in case of resizing!
        $img_path = $self->{mobi_pic}->rescale_dimensions($img_path);
        
        # DEBUG: print info for each picture
        $self->_debug(
            'Storing picture in mobi format: '
            . "record_index: $current_record_index, image: $img_path");

        # According to MobiPerl (html2mobi)
        my $img = EBook::MOBI::Palm::PDB->new_Record();
        $img->{"categori"} = 0;
        $img->{"attributes"}{"Dirty"} = 1;
        # increase counter, for the next picture to be added...
        $img->{"id"} = $current_record_index++;

        # read binary picture data
        my $data;
        my $buff;
        open(my $IMG, $img_path) or die "can't open file: $!";
        binmode($IMG);
        # That's how MobiPerl reads the data so we do it the same way
        while (read($IMG, $buff, 8 * 2**10)) {
            $data .= $buff;
        }
        close($IMG);
        $img->{"data"} = $data;

        # finally we append the image data to the record,
        # and repeat the loop
        $mobi->append_Record ($img);
    }

    # FINISH! Write the Mobi file (and pray that it's fine)
    $mobi->Write ($filename);
}

# Internal sub.
# It fetches all the paths from the IMG tags of a HTML string
sub _gather_IMG_ref {
    my ($self,$html) = @_;

    # process line by line
    my @lines = split /\n/, $html;
    foreach my $line (@lines) {
        #<img src="THIS TEXT IS WHAT WE ARE LOOKING FOR" >
        if ($line =~ m/.*<img.*\ssrc=["'](\S*)["']\s.*>/g) {
            my $img_path = $1;

            # if we found a path, we add it to a classwide array
            push (@{$self->{picture_paths}}, $img_path);
        }
    }
}

1;

__END__

=encoding utf8

=head1 NAME

EBook::MOBI::Mhtml2Mobi- Create a Mobi eBook by packing MOBI-ready HTML.

=head1 SYNOPSIS

  use EBook::MOBI::Mhtml2Mobi;
  my $mobi = EBook::MOBI::Mhtml2Mobi->new();
  $mobi->pack($mhtml, $out_filename, $author, $title);

=head1 METHODS

=head2 pack

The input parameters are the following:

  $mhtml     # data to put in the mobi eBook
  $filename  # filename (with path) of the desired eBook
  $author    # author of the eBook
  $title     # title of the eBook
    
Call the method like this:

  $mobi->pack($mhtml, $filename, $author, $title);

After the method call a Mobi eBook should be found at the path you specified in $filename.

=head3 Handling of Images

If your input data ($mhtml) contains <img> tags which are pointing to images on the filesystem, these images will be stored and linked into the MOBI datafile. The images will be rescaled if necessary, according to L<EBook::MOBI::Picture>.

=head1 WHAT IS MHTML?

'mhtml' stands for mobi-html, which means: it is actually HTML but some things are different. I invented this term myself, so it is probably not a good idea to search the web or ask other people about this term. If you are looking for more information about this format you might search the web for 'mobipocket file format' or something similar.

If you stick to the most basic HTML tags it should be perfect mhtml 'compatible'. So if you want to 'write a book' or something similar you can just use basic HTML for markup. The eBook readers using the MOBI format actually just display plain HTML. But sadly that's not the whole truth - you can't stick to the official HTML standards. Since I did some research on how to do things, I'd like to share my knowledge.

=head2 Simple Text

Most simple HTML tags will just work.

  <h1>My Book</h1>
  <p>
  This is my first book.
  I want to show the world <b>my</b> mind!
  <br />&nbsp; -- the author
  </p>

=head2 TOC and Hyperlinks

Hyperlinks pointing to the WWW are working just like in HTML. But if you want to point into your own file, e.g. for a table of contents, it will not work. You then have to declare an attribute called 'filepos' which points to the char where you whant to jump to.

  h1>Table of Contents</h1>
  <ul>
  <li><a filepos="00000458">CHAPTER ONE</a></li>
  <li><a filepos="00000510">CHAPTER TWO</a></li>
  </ul>

=head2 Images

Images are handled slightly different than in standard HTML, since all the data is not on a normal filesystem - it is packed into the MOBI format. Since there are no such thing as filenames in the MOBI format (at least as far as I know) you can't point to an image over it's name. Images are stored in seperat format-intern containers, which have a count. You can then adress to an image with the number of it's container. The syntax is like this:

  <img recindex="0004">

Attention! If you have a lot of text, it will fill up more than one container. But even then... images always start counting from recindex one! So this count seems to be relative, not absolute. Just start counting with C<recindex="1"> and it will be fine!

=head2 New Page

If you want to enforce a new page at the eBook-reader you can use a MOBI specific tag:

  <mbp:pagebreak />

=head1 TODO

A method to set the maximum image width and height would be nice.

=head1 COPYRIGHT & LICENSE

Copyright 2012 Boris Däppen, all rights reserved.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Boris Däppen E<lt>boris_daeppen@bluewin.chE<gt>

=cut
