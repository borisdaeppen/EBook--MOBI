#!/usr/bin/perl

use strict;
use warnings;

use IO::String;
use File::Temp qw(tempfile);

#######################
# TESTING starts here #
#######################
use Test::More tests => 12;

###########################
# General module tests... #
###########################

my $module = 'EBook::MOBI::Pod2Mhtml';
use_ok( $module );

my $obj = $module->new();

isa_ok($obj, $module);
isa_ok($obj, 'Pod::Parser');

can_ok($obj, qw(parse_from_filehandle _nbsp _html_enc _debug html_body pagemode));

################################
# We define some parsing input #
# and also how the result      #
# should look like             #
################################
my %pod_input; # parsing input
my %html_out;  # parsing result

# 1
$pod_input{minimal} = <<'HEREDOC';
==head1 MINIMAL

Text

==cut
HEREDOC

$html_out{minimal} = <<'HEREDOC';
<body>
<h1>MINIMAL</h1>
<p>Text</p>
</body>
HEREDOC

# 2
$pod_input{lists} = <<'HEREDOC';
==head1 LISTS

==over

==item normal list (1)

==item normal list (2)

==back

==over

==item 1 numbered list

==item 2 numbered list

==back

==over

==item * 5

==item normal list with number as first item

==back

==cut
HEREDOC

$html_out{lists} = <<'HEREDOC';
<body>
<h1>LISTS</h1>
<ul>
<li>normal list (1)</li>
<li>normal list (2)</li>
</ul>
<ol>
<li>numbered list</li>
<li>2 numbered list</li>
</ol>
<ul>
<li>5</li>
<li>normal list with number as first item</li>
</ul>
</body>
HEREDOC

# 3
$pod_input{pic} = <<'HEREDOC';
==head2 PIC

Some text?

==image /path/to/pic.jpg This is the description!

Some other text...

==cut
HEREDOC

$html_out{pic} = <<'HEREDOC';
<body>
<h2>PIC</h2>
<p>Some text?</p>
<img src="/path/to/pic.jpg" recindex="1" >
<p>This is the description!</p>
<p>Some other text...</p>
</body>
HEREDOC

# 4
$pod_input{umlaut} = <<'HEREDOC';
==head3 UMLAUT

üöäÜÖÄ
éàèÉÀÈ

==cut
HEREDOC

$html_out{umlaut} = <<'HEREDOC';
<body>
<h3>UMLAUT</h3>
<p>&uuml;&ouml;&auml;&Uuml;&Ouml;&Auml;
&eacute;&agrave;&egrave;&Eacute;&Agrave;&Egrave;</p>
</body>
HEREDOC

# 5
$pod_input{angle_bracket} = <<'HEREDOC';
==head4 ANGLE BRACKET

HTML chars::
<html> &nbsp; </html>

POD markup:
B<BOLD> C<CODE> F<FILE> I<ITALIC> E<nbsp> L<perl.org>

==cut
HEREDOC

$html_out{angle_bracket} = <<'HEREDOC';
<body>
<h4>ANGLE BRACKET</h4>
<p>HTML chars::
&lt;html&gt; &amp;nbsp; &lt;/html&gt;</p>
<p>POD markup:
<b>BOLD</b> <code>CODE</code> <code>FILE</code> <i>ITALIC</i> &nbsp; <a href='perl.org'>perl.org</a></p>
</body>
HEREDOC

# 6
$pod_input{code} = <<'HEREDOC';
==head1 CODE

Text1

  # Code
  # Multiline
  # No special chars
  # We only want to test
  # multiline code

Text2

==cut
HEREDOC

$html_out{code} = <<'HEREDOC';
<body>
<h1>CODE</h1>
<p>Text1</p>
<code>&nbsp;&nbsp;#&nbsp;Code<br />
&nbsp;&nbsp;#&nbsp;Multiline<br />
&nbsp;&nbsp;#&nbsp;No&nbsp;special&nbsp;chars<br />
&nbsp;&nbsp;#&nbsp;We&nbsp;only&nbsp;want&nbsp;to&nbsp;test<br />
&nbsp;&nbsp;#&nbsp;multiline&nbsp;code<br />
<br /></code>
<p>Text2</p>
</body>
HEREDOC

# 7
$pod_input{pagebreak} = <<'HEREDOC';
==head1 PAGEBREAK

Text1

==head1 Here should be a break

Text2

==cut
HEREDOC

$html_out{pagebreak} = <<'HEREDOC';
<body>
<h1>PAGEBREAK</h1>
<p>Text1</p>
<mbp:pagebreak />
<h1>Here should be a break</h1>
<p>Text2</p>
</body>
HEREDOC

#################################################
# Now we parse the input and compare the result #
# with what we expected...                      #
#################################################
for my $key (keys %pod_input) {
    # we reset the parser, because the <mbp:pagebreak /> (see Parser-code)
    my $obj = $module->new();

    my ($fh,$f_name) = tempfile();
    binmode $fh;
    print $fh $pod_input{$key};
    close $fh;
    open my $pod_handle, "<:encoding(utf-8)", $f_name;

    my $html_res; # this variable will contain the result!!!
    my $res_handle = IO::String->new($html_res);

    $obj->html_body(1);
    $obj->pagemode(1);
    $obj->parse_from_filehandle($pod_handle, $res_handle);
    is($html_res, $html_out{$key}, "POD to HTML -> $key");
}

# Ok, we should also test what happens if we DON'T
# use $obj->html_body() so we do a seperate test here.
$obj = $module->new();

my ($fh,$f_name) = tempfile();
binmode $fh;
print $fh "==head1 NO BODY

There should be no html body-tag here.

==cut
";
close $fh;
open my $pod_handle, "<:encoding(utf-8)", $f_name;

my $html_res; # this variable will contain the result!!!
my $res_handle = IO::String->new($html_res);

$obj->parse_from_filehandle($pod_handle, $res_handle);
is($html_res,
   "<h1>NO BODY</h1>\n<p>There should be no html body-tag here.</p>\n",
   "POD to HTML -> no-body-tag"
  );

########
# done #
########
1;

