#!/usr/bin/perl

use strict;
use warnings;

#######################
# TESTING starts here #
#######################
use Test::More tests => 1;

my $POD_in = <<END;
=head1 This is a special char \Q isnt it

Text 1

=head2 Two

Text \Q 2

=head1 Three

Text 3

=cut
END

my $POD_res_namedtoc = <<END;
<html>
<head>
<guide>
<reference type="toc" title="Inhaltsverzeichnis" filepos="00000116"/>
</guide>
</head>
<body>
<h1>Inhaltsverzeichnis</h1><!-- TOC start -->
<p><ul>
<li><a filepos="00000297">This is a special char &#92;Q isnt it</a></li><!-- TOC entry -->
<li><a filepos="00000351">Three</a></li><!-- TOC entry -->
</ul></p>

<h1>This is a special char &#92;Q isnt it</h1>
<p>Text 1</p>
<h2>Two</h2>
<p>Text 2</p>
<h1>Three</h1>
<p>Text 3</p>
</body>
</html>
END

use EBook::MOBI;
my $obj = EBook::MOBI->new();
$obj->reset();
$obj->add_toc_once('Inhaltsverzeichnis');
$obj->add_content(data => $POD_in);
$obj->make();
my $res = $obj->print_mhtml(1);
#$obj->print_mhtml();
is($res, $POD_res_namedtoc, 'backslash Q');

########
# done #
########
1;

