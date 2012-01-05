package EBook::MOBI::Pod2Mhtml;

use strict;
use warnings;

use Pod::Parser;
our @ISA = qw(Pod::Parser);

our $VERSION = 0.1;
our $DEBUG   = 0;

use Text::Trim;
use HTML::Entities;
use Carp;

# This constants are used for internal replacement
# See interior_sequence() and _html_enc() for usage
use constant { GT  => '1_qpdhcn_thisStringShouldNeverOccurInInput',
               LT  => '2_udtcqk_thisStringShouldNeverOccurInInput',
               AMP => '3_pegjyq_thisStringShouldNeverOccurInInput',
               COL => '4_jdkmso_thisStringShouldNeverOccurInInput',
               QUO => '5_wuehlo_thisStringShouldNeverOccurInInput'};

# Overwrite sub of Pod::Parser
# At start of POD we print a html BODY tag
sub begin_input {
    my $parser = shift;
    my $out_fh = $parser->output_handle();       # handle for parsing output

    $parser->_debug('found POD, parsing...');

    # make sure that this variable is set to 0 at beginning
    $parser->{__listcontext} = 0;

    if (exists $parser->{__body} and $parser->{__body}) {
        print $out_fh "<body>\n";
    }
}

# Overwrite sub of Pod::Parser
# At end of POD we print a html /BODY tag
sub end_input {
    my $parser = shift;
    my $out_fh = $parser->output_handle();

    $parser->_debug('...end of POD reached');

    # at the end of file we should not be in listcontext anymore
    if($parser->{__listcontext}) {
        croak "POD parsing error. Did you forget '=back' at end of list?";
    }

    if (exists $parser->{__body} and $parser->{__body}) {
        print $out_fh "</body>\n";
    }
}

# Overwrite sub of Pod::Parser
# Here all POD commands starting with '=' are handled
sub command { 
    my ($parser, $command, $paragraph, $line_num) = @_; 
    my $out_fh = $parser->output_handle();       # handle for parsing output

    # IMAGE is an unofficial command introduced by Renee, its very simple:
    # =image PATH_TO_IMAGE ANY TEXT FOLLOWING UNTIL END OF LINE
    if ($command eq 'image') {

        # With this regex we parse the content, coming with the command.
        # An example could look like this:
        # $paragraph = '/home/user/picture.jpg Pic1: A Camel'
        if ($paragraph =~ m/(\S*)\s*(.*)/g) {
            my $img_path = $1;  # e.g.: '/home/user/picture.jpg'
            my $img_desc = $2;  # e.g.: 'A Camel'

            # We convert special chars to HTML, but only in the
            # description, not in the path!
            $img_desc = _html_enc($img_desc);

            # We count the pictures, so that each has a number
            $parser->{'EBook::MOBI::Pod2Mhtml::img_count'} ++;

            # We print out an html image tag.
            # e.g.: <img src="/home/user/picture.jpg" recindex="1">
            # recindex is MOBI specific, its the number of the picture,
            # pointing into the picture records of the Mobi-format
            print $out_fh '<img src="' . $img_path . '"'
                        . ' recindex="' . $parser-> {
                                'EBook::MOBI::Pod2Mhtml::img_count'
                            }
                        .'" >'
                        . "\n";
            # Then we print out the image description
            print $out_fh '<p>' . $img_desc . '</p>' . "\n";
        }
    }
    # if we reach this ELSE, this means that the command can only be
    # of type HEAD
    else {
        # first we remove all whitespace from begin and end of the title
        trim $paragraph;
        # then we call interpolate so that 'interior_sequence' is called.
        # this is replacing inline POD.
        my $expansion = $parser->interpolate($paragraph, $line_num);
        # then we replace special chars with HTML entities
        $expansion = _html_enc($expansion);

        # Now we just need to print the text with the matching HTML tag
        if ($command eq 'head1') {
            # before every head1 we insert a "mobi-pagebreak"
            # but not before the first one!
            if (exists $parser->{__firstH1passed} and
                exists $parser->{__pages} and
                       $parser->{__pages}) {
                print $out_fh '<mbp:pagebreak />'       . "\n";
            }
            else {
                $parser->{__firstH1passed} = 1;
            }
            print $out_fh '<h1>' . $expansion . '</h1>' . "\n"
        }
        elsif ($command eq 'head2') {
            print $out_fh '<h2>' . $expansion . '</h2>' . "\n"
        }
        elsif ($command eq 'head3') {
            print $out_fh '<h3>' . $expansion . '</h3>' . "\n"
        }
        elsif ($command eq 'head4') {
            print $out_fh '<h4>' . $expansion . '</h4>' . "\n"
        }
        # Lists are a bit complex. The commands 'over', 'back' and 'item'
        # are used. They exchange state over a global variable. This state
        # is the listcontext, which can be: 'begin', 'ul' or 'ol'.
        # OVER: starts the listcontext
        elsif ($command eq 'over') {

            # If we reach an 'over' command we can't do anything yet
            # because we don't know if it will be an ordered or an
            # unordered list! So we just set a global variable to 'begin',
            # the first item call can then know that it is the first item
            # and that it defines the rest of the list type.
            $parser->{__listcontext} = 'begin';
        }
        # BACK: ends the listcontext
        elsif ($command eq 'back') {

            # print end-tag according to the lists type
            if ($parser->{__listcontext} eq 'ul') {
                print $out_fh '</ul>' . "\n";
            }
            elsif ($parser->{__listcontext} eq 'ol') {
                print $out_fh '</ol>' . "\n";
            }
            else {
                croak 'POD parsing error. Undefined listcontext:'
                      . $parser->{__listcontext};
            }

            # Set listcontext to zero
            $parser->{__listcontext} = 0;

        }
        # ITEM: the lists items
        elsif ($command eq 'item') {

            # If we are still in listcontext 'begin' this means that this is
            # the first item of the list, which will be used to figure out
            # the type of the list.
            if ($parser->{__listcontext} eq 'begin') {

                # is there a digit at first, if yes this is an ordered list
                if ($expansion =~ /^\s*\d+\s*(.*)$/) {
                    $expansion = $1;
                    $parser->{__listcontext} = 'ol';
                    print $out_fh '<ol>' . "\n"
                }
                # is there a '*' at first, if yes this is an unordered list
                elsif ($expansion =~ /^\s*\*{1}\s*(.*)$/) {
                    $expansion = $1;
                    $parser->{__listcontext} = 'ul';
                    print $out_fh '<ul>' . "\n"
                }
                # are there only prinable chars? We default to unordered
                elsif ($expansion =~ /^[[:print:]]+$/) {
                    $parser->{__listcontext} = 'ul';
                    print $out_fh '<ul>' . "\n"
                    # do nothing
                }
                # something seems to be wrong if we reach here!
                else {
                    croak 'This string does not seem to fit into a list: '
                          . $expansion;
                }
            }
            
            # If it is not the first item, but also after the first one...
            # we always need to print out the items content.
            print $out_fh '<li>' . $expansion . '</li>' . "\n"
        }
        elsif ($command eq 'cut') {
            # We don't need to do anything here...
        }
    }
}

# Overwrite sub of Pod::Parser
# Here all code parts of POD get parsed
sub verbatim { 
    my ($parser, $paragraph, $line_num) = @_; 
    my $out_fh = $parser->output_handle();       # handle for parsing output

    # We have to escape the case where there is only a newline, because
    # Pod::Parser calls verbatim() with $paragraph="\n" every time an empty
    # line is found in the Pod. But that is not what we are looking for!
    # We are looking for code-blocks here...
    if ($paragraph eq "\n") { return }

    # we look for POD inline commands
    my $expansion = $parser->interpolate($paragraph, $line_num);
    # then for special chars
    $expansion = _html_enc($expansion);
    # and last but not least we replace whitespace with a HTML tag.
    # this we do only for the verbatim command!
    # this is so, that code format (indenting) is keeped in html
    $expansion = _nbsp($expansion);

    # also only in verbatim we replace newline with the <br /> tag
    # this is so, that code format is keeped in html
    $expansion =~ s/\n/<br \/>\n/g;

    # trim must be last,
    # otherwise _nbsp() is not working for the first line
    trim $expansion;

    # ok, we are done and print out the result
    print $out_fh '<code>' . $expansion . '</code>' . "\n";
}

# Overwrite sub of Pod::Parser
# Here normal POD text paragraphs get parsed
sub textblock { 
    my ($parser, $paragraph, $line_num) = @_; 
    my $out_fh = $parser->output_handle();       # handle for parsing output

    # we translate the POD inline commands...
    my $expansion = $parser->interpolate($paragraph, $line_num);
    # remove leading and trailing whitespace...
    trim $expansion;
    # and translate special chars to HTML
    $expansion = _html_enc($expansion);

    # that's it. we're done!
    print $out_fh '<p>' . $expansion . '</p>' . "\n";
}

# Overwrite sub of Pod::Parser
# This method is called for handling inline POD, like e.g. B<some text>
sub interior_sequence {
    my ($parser, $cmd, $arg) = @_;

    # IMPORTANT here we do some tricky stuff...
    # what we actually want is this:
    #     B<some text>   ->   <b>some text</b>
    # but this is not possible, because then the <> would be replaced by
    # HTML entities later on!
    # So that is why we replace like this:
    #     <   ->   constant: LT
    # and
    #     >   ->   constant: GT
    # So B<some text> becomes XLTXsome textXGTX
    # The function which is doing the HTML translation must then replace
    # this words again with < and > (this is what _html_enc() is doing)
    return LT . 'b'    . GT . $arg . LT . '/b'    . GT  if ($cmd eq 'B');
    return LT . 'code' . GT . $arg . LT . '/code' . GT  if ($cmd eq 'C');
    return LT . 'code' . GT . $arg . LT . '/code' . GT  if ($cmd eq 'F');
    return LT . 'i'    . GT . $arg . LT . '/i'    . GT  if ($cmd eq 'I');
    return              AMP . $arg . COL                if ($cmd eq 'E');
    return LT.'a href='.QUO.$arg.QUO.GT.$arg.LT.'/a'.GT if ($cmd eq 'L');

    # if nothing matches we return the content unformated 'as is'
    return $arg;
}

sub html_body {
    my ($self, $boolean) = @_;

    $self->{__body} = $boolean;
}

sub pagemode {
    my ($self, $boolean) = @_;

    $self->{__pages} = $boolean;
}

sub debug_on {
    my ($self, $ref_to_debug_sub) = @_; 

    $self->{ref_to_debug_sub} = $ref_to_debug_sub;
    $DEBUG = 1;
    
    &$ref_to_debug_sub('DEBUG mode on');
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

# encode_entities() from HTML::Entities does not translate it correctly
# this is why I make it here manually as a quick fix
# don't reall know where how to handle this utf8 problem for now...
sub _html_enc {
    my $string = shift;

    $string = encode_entities($string);
                            #    ^
    my $lt = LT;            #    |
    my $gt = GT;            #    |
    my $am = AMP;           #    |
    my $co = COL;           #    |-- don't change this order!
    my $qu = QUO;           #    |
    $string =~ s/$lt/</g;   #    |
    $string =~ s/$gt/>/g;   #    |
    $string =~ s/$am/&/g;   #    |
    $string =~ s/$co/;/g;   #    |
    $string =~ s/$qu/'/g;   #<---|

    return $string;
}

# replaces whitespace with html entitie
sub _nbsp {
    my $string = shift;

    $string =~ s/\ /&nbsp;/g;

    return $string;
}

1;

__END__

=encoding utf8

=head1 NAME

EBook::MOBI::Pod2Mhtml - Create HTML, flavoured for the MOBI format, out of POD.

This module extends L<Pod::Parser> for parsing capabilities.
The module L<HTML::Entities> is used to translate chars to HTML entities.

=head1 SYNOPSIS

  use EBook::MOBI::Pod2Mhtml;
  my $p2h = new EBook::MOBI::Pod2Mhtml;

  # $pod_h and $html_out_h are file handles
  # or IO::String objects
  $p2h->parse_from_filehandle($pod_h, $html_out_h);

  # result is now in $html_out_h

=head1 METHODS

=head2 parse_from_filehandle

This is the method you need to call, if you want this module to be of any help for you.
It will take your data in the POD format and return it in special flavoured HTML, which can be then further used for the MOBI format.

Hand over two file handles or Objects of L<IO::String>.
The first handle points to your POD, the second waits to receive the result.

  # $pod_h and $html_out_h are file handles
  # or IO::String objects
  $p2h->parse_from_filehandle($pod_h, $html_out_h);

  # result is now in $html_out_h

=head2 pagemode

Pass any true value to enable 'pagemode'.
The effect will be, that before every - but the first - '=head1' there will be a peagebreak inserted.
This means: The resulting eBook will start each head1 chapter at a new page.

  $p2h->pagemode(1);

Default is to not add any pagebreak.

=head2 html_body

Pass any true value to enable 'html_body'.
If set, parsed content will be encapsulated in a HTML body tag.
You may want this if you parse all data at once.
But if there is more to add, you should not use this mode,
you then will just get HTML markup which is not encapsulated in a body tag.

  $p2h->html_body(1);

Default is to not encapsulate in a body tag.

=head2 set_publisher

You can just ignore this method if you are not interested in debuging!

Pass a reference to an object which provides a method named debug() and all the debug-output will be written there if the $DEBUG variable is true.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Boris Däppen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms of Artistic License 2.0.

=head1 AUTHOR

Boris Däppen E<lt>boris_daeppen@bluewin.chE<gt>

=cut
