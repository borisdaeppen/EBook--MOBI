package EBook::MOBI::Converter;

use strict;
use warnings;

use HTML::Entities;

our $VERSION = 0.5;

#############################
# Constructor of this class #
#############################

sub new {
    my $self    = shift;
    my $ref = {};

    bless($ref, $self);

    return $ref;
}

##########################
# Interface to implement #
##########################

sub parse {
    die "the method parse() must be overwritten!\n";
}

##########################
# Manage converted stuff #
##########################

sub begin {
    my $self = shift;

    # open a "body" tag
    if (not $self->{no_body}) {
        return "<body>\n";
    }
    else {
        return '';
    }
}

sub end {
    my $self = shift;

    # close the "body" tag
    if (not $self->{no_body}) {
        return "</body>\n";
    }
    else {
        return '';
    }
}

########################################
# Implementation of the converter subs #
########################################

sub text {
    my $self = shift;
    my $txt  = shift;

    #we have to make sure that HTML entities get encoded
    my $mhtml = encode_entities($txt);

    return $mhtml;
}

sub title {
    my $self = shift;
    my $txt  = shift;
    my $lvl  = shift || '1';

    die("Titles can't be higher than level 6\n") if ($lvl > 6);

    my $mhtml = "<h$lvl>$txt</h$lvl>\n";

    return $mhtml;
}

sub paragraph {
    my $self = shift;
    my $txt  = shift;

    my $mhtml = "<p>$txt</p>\n";

    return $mhtml;
}

sub newline {
    my $self = shift;

    my $mhtml = "<br />\n";

    return $mhtml;
}

sub pagebreak {
    my $self = shift;

    my $mhtml = "<mbp:pagebreak />\n";

    return $mhtml;
}

sub italic {
    my $self = shift;
    my $txt  = shift;

    my $mhtml = "<i>$txt</i>";

    return $mhtml;
}

sub bold {
    my $self = shift;
    my $txt  = shift;

    my $mhtml = "<b>$txt</b>";

    return $mhtml;
}

sub code {
    my $self = shift;
    my $txt  = shift;

    my $mhtml = "<code>$txt</code>\n";

    return $mhtml;
}

sub small {
    my $self = shift;
    my $txt  = shift;

    my $mhtml = "<small>$txt</small>";

    return $mhtml;
}

sub big {
    my $self = shift;
    my $txt  = shift;

    my $mhtml = "<big>$txt</big>";

    return $mhtml;
}

sub emphasize {
    my $self = shift;
    my $txt  = shift;

    my $mhtml = "<em>$txt</em>";

    return $mhtml;
}

sub list {
    my $self      = shift;
    my $list_ref  = shift;
    my $list_type = shift || 'ul';

    my $mhtml = "<$list_type>\n";
    foreach my $item (@{$list_ref}) {
        $mhtml .= "<li>$item</li>\n";
    }
    $mhtml .= "</$list_type>\n";

    return $mhtml;
}

sub table {
    my $self      = shift;
    my %table_data = @_;

    my $table_args = '';
    if (exists $table_data{border}) {
        $table_args .= ' border="'. $table_data{border} .'"';
    }
    if (exists $table_data{cellspacing}) {
        $table_args .= ' cellspacing="'. $table_data{cellspacing} .'"';
    }
    if (exists $table_data{cellpadding}) {
        $table_args .= ' cellpadding="'. $table_data{cellpadding} .'"';
    }

    my $mhtml;
    $mhtml = "<table$table_args>\n";

    if (exists $table_data{th}) {
        my @table_header = @{$table_data{th}};

        $mhtml .= "<tr>";
        foreach my $head (@table_header) {
            $mhtml .= "<th>$head</th>";
        }
        $mhtml .= "</tr>\n";
    }

    if (exists $table_data{td}) {
        my @table_datarow = @{$table_data{td}};

        foreach my $row (@table_datarow) {
            my @table_data= @{$row};

            $mhtml .= "<tr>";
            foreach my $data (@table_data) {
                $mhtml .= "<td>$data</td>"
            }
            $mhtml .= "</tr>\n";
        }
    }

    if (exists $table_data{caption}) {
        $mhtml .= '<caption>' . $table_data{caption} . '</caption>' . "\n";
    }

    $mhtml .= "</table>\n";

    return $mhtml;
}

sub image {
    my $self        = shift;
    my $path        = shift;
    my $description = shift || '';

    # We count the pictures, so that each has a number
    $self->{img_count} ++; 

    my $mhtml;

    # e.g.: <img src="/home/user/picture.jpg" recindex="1">
    # recindex is MOBI specific, its the number of the picture,
    # pointing into the picture records of the Mobi-format
    $mhtml =  '<img src="'  . $path . '"' 
            . ' recindex="' . $self->{img_count} .'" >'
            . "\n";

    # Then we print out the image description
    $mhtml .= '<p>' . $description . '</p>' . "\n"
        if ($description);

    return $mhtml;
}

1;

__END__

=encoding utf8

=head1 NAME

EBook::MOBI::Driver - Interface for plugins.

=head1 SYNOPSIS


  use EBook::MOBI::Driver;

=head1 METHODS

=head2 new

=head2 add_content

=head2 delete_content

=head2 get_content

=head2 text

=head2 title

=head2 paragraph

=head2 newline

=head2 pagebreak

=head2 italic

=head2 bold

=head2 code

=head2 small

=head2 big

=head2 emphasize

=head2 list

=head2 table

=head2 image

=head1 Possible Tags

According to L<http://www.mobipocket.com/dev/article.asp?BaseFolder=prcgen&File=TagRef_OEB.htm> the following tags are supported in Mobipocket. Not all are implemented in the methods mentioned above.

  <?xml?>
  <?xml-stylesheet?>
  <!--
  <!doctype>
  <a>
  <area>
  <b>
  <base>
  <big>
  <blockquote>
  <body>
  <br
  <caption>
  <center>
  <cite>
  <code>
  <dd>
  <del>
  <dfn>
  <dir>
  <div>
  <dl>
  <dt>
  <em>
  <font>
  <head>
  <h1
  <hr
  <html>
  <i>
  <img
  <ins>
  <kbd>
  <li>
  <link
  <listing>
  <map>
  <menu>
  <meta>
  <object>
  <ol>
  <p>
  <param>
  <plaintext>
  <pre>
  <q>
  <s>
  <samp>
  <small>
  <span>
  <strike>
  <strong>
  <style>
  <sub>
  <sup>
  <table>
  <td>
  <th>
  <title>
  <tr>
  <tt>
  <u>
  <ul>
  <var>
  <xmp>

=head1 COPYRIGHT & LICENSE

Copyright 2011 Boris Däppen, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms of Artistic License 2.0.

=head1 AUTHOR

Boris Däppen E<lt>boris_daeppen@bluewin.chE<gt>

=cut

