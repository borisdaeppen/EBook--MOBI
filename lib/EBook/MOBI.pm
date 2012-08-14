package EBook::MOBI;

use strict;
use warnings;

our $VERSION = 0.49;

# needed CPAN stuff
use IO::String;
use File::Temp qw(tempfile);

# needed local stuff
use EBook::MOBI::Driver::POD;
use EBook::MOBI::Mhtml2Mobi;

# Constructor of this class
sub new {
    my $self = shift;
    my $ref = { html_data => '',
                html_toc  => '',
                toc_label => 'Table of Contents',
                toc_set   => 0,
                toc_done  => 0,

                filename  => 'book.mobi',
                title     => 'This Book has no Title',
                author    => 'This Book has no Author',

                encoding  => ':encoding(UTF-8)',

                CONST     => '6_--TOC-_thisStringShouldNeverOccurInInput',

                ref_to_debug_sub => 0,
            };

    bless($ref, $self);
    return $ref;
}

sub reset {
    my $self = shift;
    $self->{html_data} = '',
    $self->{html_toc } = '',
    $self->{toc_label} = 'Table of Contents',
    $self->{toc_set  } = 0,
    $self->{toc_done } = 0,

    $self->{filename } = 'book',
    $self->{title    } = 'This Book has no Title',
    $self->{author   } = 'This Book has no Author',

    $self->{encoding } = ':encoding(UTF-8)',

    $self->{CONST    } = '6_--TOC-_thisStringShouldNeverOccurInInput',

    $self->{ref_to_debug_sub} = 0,
}

sub debug_on {
    my ($self, $ref_to_debug_sub) = @_;

    $self->{ref_to_debug_sub} = $ref_to_debug_sub;
    
    &$ref_to_debug_sub('DEBUG mode on');
}

sub debug_off {
    my ($self) = @_;

    if ($self->{ref_to_debug_sub}) {
        &{$self->{ref_to_debug_sub}}('DEBUG mode off');
        $self->{ref_to_debug_sub} = 0;
    }
}

# Internal debug method
sub _debug {
    my ($self,$msg) = @_;

    if ($self->{ref_to_debug_sub}) {
        &{$self->{ref_to_debug_sub}}($msg);
    }
}

sub set_title {
    my $self = shift;

    $self->{title} = shift;
}

sub set_author {
    my $self = shift;

    $self->{author} = shift;
}

sub set_filename {
    my $self = shift;

    $self->{filename} = shift;
}

sub set_encoding {
    my $self = shift;

    $self->{encoding} = shift;
}

sub add_mhtml_content {
    my ($self, $html) = @_;

    $self->{html_data} .= $html;
}

sub add_pod_content {
    my ($self, $pod, $pagemode, $head0_mode) = @_;

    # With this parser we will create HTML out of POD.
    # The HTML is specially prepared for the MOBI format
    my $parser = EBook::MOBI::Driver::POD->new();

    # pass some settings
    $parser->debug_on($self->{ref_to_debug_sub})
        if ($self->{ref_to_debug_sub});
    $parser->pagemode($pagemode);
    $parser->head0_mode($head0_mode);

    # ok, now we prepare the parsing, unfortunately we have to do
    # some complicated magic with the string data...

    # INPUT:
    # We do this trick so that we have UTF8
    # It seems like this is working after all...
    my ($fh,$f_name) = tempfile();
    binmode $fh, $self->{encoding};
    print $fh $pod;
    close $fh;
    open my $pod_handle, "<$self->{encoding}", $f_name;

    # and we have a file again...
    my $input = '';
    while (my $line = <$pod_handle>) {
        $input .= $line;
    }
    close $pod_handle;
    unlink $f_name;

    # we call the parser to parse, result will be in $buffer4html
    my $output = $parser->parse($input);

    $self->{html_data} .= $output;
}

sub add_pagebreak {
    my ($self) = @_;

    $self->{html_data} .= '<mbp:pagebreak />' . "\n";
}

sub add_toc_once {
    my ($self, $label) = @_;

    $self->{toc_label} = $label if $label;
    $self->{toc_set} = 1;
    $self->{html_data} .= $self->{CONST};
    # this newline is needed, otherwise the generation of the toc will
    # not recognise the first <h1> in the split function
    $self->{html_data} .= "\n";
}

sub make {
    my ($self) = @_;

    if (exists $self->{toc_set} and $self->{toc_set}) {
        $self->_generate_toc();
    }
    else {
        my $tmp = $self->{html_data};
    $self->{html_data} = "<html>
<head>
</head>
<body>
" . $tmp . "</body>\n</html>\n";
    }
}

sub print_mhtml {
    my ($self, $arg) = @_;

    unless ($arg) {
        print $self->{html_data};
    }

    return $self->{html_data};
}

sub save {
    my ($self) = @_;

    my $mobi = EBook::MOBI::Mhtml2Mobi->new();
    $mobi->debug_on($self->{ref_to_debug_sub})
        if ($self->{ref_to_debug_sub});

    $mobi->pack(    $self->{html_data},
                    $self->{filename},
                    $self->{author},
                    $self->{title},
                );
}

sub _generate_toc {
    my $self = shift;

    if (exists $self->{toc_done} and $self->{toc_done}) {
        $self->_debug(
            'Skipping generation of TOC, has been done earlier.');

        return 1;
    }
    else {
        $self->_debug("generating TOC...");
        $self->{toc_done} = 1;
    }

    foreach my $line (split("\n", $self->{html_data})) {
        # The <h1> is only added to TOC if it is at the beginning of a line
        # and if there is a newline directly following afterwards
        if ($line =~ m/^<h1>(.*)<\/h1>$/) {
            $self->{html_toc} .=
                "<li><a filepos=\"00000000\">$1</a></li><!-- TOC entry -->\n";
        }
    }

    my $toc  = "<h1>$self->{toc_label}</h1><!-- TOC start -->\n";
       $toc .= "<p><ul>\n$self->{html_toc}<\/ul><\/p>\n";

    $self->{html_data} =~ s/$self->{CONST}/$toc/;

    my $tmp = $self->{html_data};
    $self->{html_data} = "<html>
<head>
<guide>
<reference type=\"toc\" title=\"$self->{toc_label}\" filepos=\"00000000\"/>
</guide>
</head>
<body>
" . $tmp . "</body>\n</html>\n";

    # now we need to calculate the positions for "filepos"
    my $chars = 0;
    my $data_copy = $self->{html_data};
    foreach my $line (split("\n", $data_copy)) {

        if ($line =~ m/^<h1>(.*)<\/h1>$/) {
            my $this_pos = $chars;
            my $fill_pos = sprintf("%08d", $this_pos);
            my $m = $1;

            $self->_debug("...ref to char $this_pos,\ttitle '$1'");

            $self->{html_data} =~
            s/<li><a filepos="00000000">$m<\/a><\/li><!-- TOC entry -->/<li><a filepos="$fill_pos">$m<\/a><\/li><!-- TOC entry -->/;
        }
        elsif ($line =~ /<!-- TOC start -->$/) {
            my $this_pos = $chars;
            my $fill_pos = sprintf("%08d", $this_pos);

            $self->{html_data} =~
            s/<reference type="toc" title="$self->{toc_label}" filepos="00000000"\/>/<reference type="toc" title="$self->{toc_label}" filepos="$fill_pos"\/>/;
        }
        $chars += length($line) + 1;
    }

}

1;

__END__

=encoding utf8

=head1 NAME

EBook::MOBI - create an ebook in the MOBI format, out of POD formatted content.

You are at the right place here if you want to create an ebook in the so called MOBI format (somethimes also called PRC format or Mobipocket). You are especially at the right place if you have your books content available in the POD format. Because this is, what this code does best.

=head1 SYNOPSIS

If you plan to create a typical ebook you probably will need all of the methods provided by this class. So it might be a good idea to read all the descriptions in the methods section, and also have a look at this example here:

  # Create an object of a book
  use EBook::MOBI;
  my $book = EBook::MOBI->new();

  # give some meta information about this book
  $book->set_filename('./data/my_ebook.mobi');
  $book->set_title   ('Read my Wisdome');
  $book->set_author  ('Bam Bam');
  $book->set_encoding(':encoding(UTF-8)');

  # lets create our own title page!
  $book->add_mhtml_content(
      " <h1>This is my Book</h1>
       <p>Read my wisdome.</p>"
  );
  $book->add_pagebreak();

  # insert a table of contents after the titlepage
  $book->add_toc_once();
  $book->add_pagebreak();

  # add the books text, which is e.g. in the POD format
  $book->add_pod_content($pod, 'pagemode');

  # prepare the book (e.g. calculate the references for the TOC)
  $book->make();

  # let me see how this mobi-html looks like
  $book->print_mhtml();

  # ok, give me that mobi-book as a file!
  $book->save();

  # done

=head1 METHODS

=head2 set_title

Give a string which will appear in the meta data of the format. This will be used e.g. by ebook-readers to determine the books name.

  $book->set_title('Read my Wisdome');

=head2 set_author

Give a string which will appear in the meta data of the format. This will be used e.g. by ebook-readers to determine the books author.

  $book->set_author('Bam Bam');

=head2 set_filename

The book will be stored under the name and location you pass here. When calling the save() method the file will be created.

  $book->set_filename('./data/my_ebook.mobi');

If you don't use this method, the default name will be 'book.mobi'.

=head2 set_encoding

If you don't set anything here, C<:encoding(UTF-8)> will be default.
As far as I know, only CP1252 (Win Latin1) und UTF-8 are supported by popular readers.

  $book->set_encoding(':encoding(UTF-8)');

Please see L<http://perldoc.perl.org/functions/binmode.html> for the syntax of your encoding keyword.
If you use use hardcoded strings in your program, C<use utf8;> should be helping.

=head2 add_mhtml_content

'mhtml' stands for mobi-html, which means: it is actually HTML but some things are different. I invented this term myself, so it is probably not a good idea to search the web or ask other people about it. If you are looking for more information about this format you might search the web for 'mobipocket file format' or something similar.

If you stick to the most basic HTML tags it should be perfect mhtml 'compatible'. This way you can add your own content directly. If this is to tricky, have a look at the add_pod_content() method.

  $book->add_mhtml_content(
      " <h1>This is my Book</h1>
       <p>Read my wisdome.</p>"
  );

If you indent the 'h1' tag with any whitespace, it will not appear in the TOC (only 'h1' tags directly starting and ending with a newline are marked for the TOC). This may be usefull if you want to design a title page.

=head2 add_pod_content

Perls POD format is very simple to use. So it might be a good idea to write your content in POD. If you did so, you can use this method to put your content into the book. Your POD will automatically be parsed and transformed to what I call 'mhtml' format. This means, your POD content will just look great in the ebook.

  $book->add_pod_content($pod, 'pagemode', 'head0_mode');

=head3 pagemode

If you pass any true value as the second argument, every head1 chapter will end with a peagebreak. This mostly makes sence, so it is a good idea to use this feature.

Default is to not insert pagebreak.

=head3 head0_mode

Pass any true value as the third argument to enable 'head0_mode'. The effect will be, that you are allowed to use a '=head0' command in your POD.

  my $pod = <<POD;
  =head0 Module EBook::MOBI
  
  =head1 NAME

  =head1 SYNOPSIS

  =head0 Module EBook::MOBI::Pod2Mhtml

  =head1 NAME

  =head1 SYNOPSIS

  =cut
  POD

  $book->add_pod_content($pod, 0, 'head0_mode');

This feature is useful if you want to have the documentation of several modules in Perl in one ebook. You then can add a higher level of titles, so that the TOC does not only contain several NAME and SYNOPSIS entries.

Default is to ignore any '=head0' command.

=head3 Special syntax for images

POD does not support images, but you might want images in your ebook.

If you want to add images you can use an unofficial '=image' syntax in your POD.

  =image /path/to/image.jpg fig1: description which will be the caption.

The image needs to exist at the path which you define here. When you call the save() method, those images will be read from this place and stored into the ebook-file.

=head2 add_pagebreak

Use this method to seperate content and give some structure to your book.

  $book->add_pagebreak();

=head2 add_toc_once

Use this method to place a table of contents into your book. You will B<need to> call the make() method later, B<after> you added all your content to the book. This is, because we need all the content - to be able to calculate the references where the TOC is pointing to. Only 'h1' tags starting and ending with a newline char will enter the TOC. See  the docs for the method add_mhtml_content() for an example.

  $book->add_toc_once();

By default, the toc is called 'Table of Contents'. You can change that label by passing it as a parameter:

  $book->add_toc_once( 'Summary' );

This method can only be called once. If you call it twice, the second call will not do anything.

=head2 make

You need to call this one before saving, especially if you have used the add_toc_once() method. This will calculate the references, pointing from the TOC into the content.

  $book->make();

=head2 print_mhtml

If you are curious how the mobi-specific HTML looks like, take a look!

If you call the method it will print to standard output. You can change this behaviour by passing any true argument. The content will then be returned, so that you can store it in a variable.

  # print to stdout
  $book->print_mhtml();
  
  # or get the result into a variable
  $mhtml_data = $book->print_mhtml(1);

=head2 save

Put the whole thing together as an ebook. This will create a file, with the name and location you gave with set_filename().

  $book->save();

In this process it will also read images and store them into the ebook. So it is important, that the images are readable at the path you provided in your POD or mhtml syntax.

=head2 reset

Reset the object, so that all the content is purged. Helpful if you like to make a new book, but are to lazy to create a new object. (e.g. for testing)

  $book->reset();

=head2 debug_on

You can just ignore this method if you are not interested in debuging!
Pass a reference to a debug subroutine and enable debug messages.

  sub debug {
      my ($package, $filename, $line) = caller;
      print "$package\t$_[0]\n";
  }

  $book->debug_on(\&debug);

=head2 debug_off

Stop debug messages and erease the reference to the subroutine.

  $book->debug_off();

=head1 SEE ALSO

=over

=item * L<Github|https://github.com/borisdaeppen/EBook--MOBI> for participating and also for L<bugreports|https://github.com/borisdaeppen/EBook--MOBI/issues>.

=item * L<EBook::MOBI::Pod2Mhtml> - see how the POD becomes MHTML.

=item * L<EBook::MOBI::Mhtml2Mobi> - look up what I mean by saying MHTML, and how the code from MobiPerl is doing it's job.

=item * L<EBook::MOBI::Picture> - see how bad I manage your images.

=item * Everything in the namespace C<EBook::MOBI::MobiPerl> is coming from MobiPerl. For information about this code, please visit L<https://dev.mobileread.com/trac/mobiperl>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Boris Däppen, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms of Artistic License 2.0.

=head1 AUTHOR

Boris Däppen E<lt>boris_daeppen@bluewin.chE<gt>

=head1 THANKS TO

=over

=item * Renée Bäcker and L<Perl-Services.de|http://www.perl-services.de/> for the idea and making this module possible.

=item * L<Perl-Magazin|http://perl-magazin.de/> for publishing an article in autumn 2012.

=item * L<Linux-Magazin|http://shop.linuxnewmedia.de/eh20194.html> for the same thing, the article is also available L<online|http://www.linux-magazin.de/content/view/full/69651> and as L<podcast|http://www.linux-magazin.de/plus/2012/08/Perl-Snapshot-Linux-Magazin-2012-08>.

=item * Tompe for developing MobiPerl.

=item * L<Garu|https://metacpan.org/author/GARU> for a helpfull patch, allowing to set a name for the TOC.

=back

=cut
