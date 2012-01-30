package EBook::MOBI::Picture;

use strict;
use warnings;

use Image::Resize;
use File::Basename;

our $VERSION = 0.1;
our $DEBUG   = 0;

# Constructor of this class
sub new {
    my $self=shift;
    my $ref={
                # According to
                # http://kindleformatting.com/formatting.php
                # this values are best for images
                max_width => 520,
                max_height => 622,
            };

    bless($ref, $self);

    $self->_debug('Tests with PNG on the Kindle-Reader failed. So all poictures get converted to JPG!');

    return $ref;
}

sub debug_on {
    my ($self, $ref_to_debug_sub) = @_; 

    $self->{ref_to_debug_sub} = $ref_to_debug_sub;
    $DEBUG = 1;
    
    &{$ref_to_debug_sub}('DEBUG mode on');
}

sub debug_off {
    my ($self) = @_; 

    if ($self->{ref_to_debug_sub}) {
        &{$self->{ref_to_debug_sub}}('DEBUG mode off');
        $self->{ref_to_debug_sub} = 0;
        $DEBUG = 0;
    }
}

# Internal debug method
sub _debug {
    my ($self,$msg) = @_; 

    if($DEBUG) {
        if ($self->{ref_to_debug_sub}) {
            &{$self->{ref_to_debug_sub}}($msg);
        }   
        else {
            print "DEBUG: $msg\n";
        }   
    }   
}

sub rescale_dimensions {
    my ($self, $image_path) = @_;

    # Prepare for work...
    my $image = GD::Image->new($image_path);

    # Get details for renaming
    my @suffixlist = qw( .jpg .jpeg .gif .png );
    my ($name,$path,$suffix) = fileparse($image_path,@suffixlist);

    # determine the size of the image
    my $width = $image->width();
    my $height= $image->height();

    my $outfilename = 'no name set';

    # Only resize the image if it is bigger than max
    if ($width > $self->{max_width} or $height > $self->{max_height}) {

        my $resize = Image::Resize->new($image);

        # We rename the out-file so that we don't destroy the original
        # picture by overwriting it with the resized version
        $outfilename = $path . $name . '-mobi_resized';

        #copy ($image_path, $outfilename);
        $self->_debug(  "Image $image_path is of size $width"."x$height"
                      . " - resizing to $self->{max_width}"
                      . "x$self->{max_height}, renaming to $outfilename"
                      );

        # Resize the image... proportions will stay the same
        $image = $resize->resize($self->{max_width}, $self->{max_height});
    }
    
    # If the file is below max width/height we dont to anything
    # NOPE: We do convert to JPG, because PNG fails on Kindle
    else {
        $self->_debug(
          "Image $image_path is of size $width"."x$height - no resizing."
        );

        # BUG: Seems like Kindle Reader can't display PNG in my tests...
        # SO I CONVERT EVERYTHING TO JPEG
        $outfilename = $path . $name . '-mobi';
    }

    # Write the file as JPG or GIF
    # PNG fails on the Kindle Reader!
    my $FH;
    if ($suffix eq '.png') {
        $outfilename = "$outfilename.gif";
        open($FH, ">$outfilename");
    my $white = $image->colorAllocate(255,255,255);
    # make the background transparent and interlaced
    $image->transparent($white);
    $image->interlaced('true');
        print $FH $image->gif();
    }
    else {
        $outfilename = "$outfilename.jpg";
        open($FH, ">$outfilename");

        print $FH $image->jpeg();
    }
    close($FH);

    # return path of the picture with the valid size
    return $outfilename;
}

1;

__END__

=encoding utf8

=head1 NAME

EBook::MOBI::Picture - Make sure that pictures cope with the MOBI standards.

=head1 SYNOPSIS

  use EBook::MOBI::Picture;
  my $p = EBook::MOBI::Picture->new();
    
  my $img_path_small = $p->rescale_dimensions($img_path_big);

=head1 METHODS

=head2 rescale_dimensions

According to my own research at the web, it is a good idea to have a maximum size for images of 520 x 622.
And this is what this method does, it ensures that this maximum is kept.

Pass a path to an image as the first argument, you will then get the path of a rescaled image back. The image is only rescaled if necessary.

Attention: All pictures, no matter what size will be converted to JPG.
In my tests, the Kindle-Reader failed to display PNG, that is why I convert everything - to go safe.

=head2 debug_on

You can just ignore this method if you are not interested in debuging!

Pass a reference to a debug subroutine and enable debug messages.

=head2 debug_off

Stop debug messages and erease the the reference to the subroutine.

=head1 TODO

A method to 'clean up' and also to change the maximum values would be nice.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Boris Däppen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms of Artistic License 2.0.

=head1 AUTHOR

Boris Däppen E<lt>boris_daeppen@bluewin.chE<gt>

=cut
