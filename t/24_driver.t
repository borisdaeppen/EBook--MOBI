#!/usr/bin/perl

use strict;
use warnings;

use utf8;

#######################
# TESTING starts here #
#######################
use Test::More tests => 29;

###########################
# General module tests... #
###########################

my $module = 'EBook::MOBI::Driver';
use_ok( $module );

my $obj = $module->new();

isa_ok($obj, $module);

#can_ok($obj, 'html_body');

################################
# We define some parsing input #
# and also how the result      #
# should look like             #
################################

my $mhtml;
my $expect;

# text
$mhtml = $obj->text('Boris Däppen');
$expect = "Boris D&auml;ppen";
is($mhtml, $expect, "text");

# title
$mhtml = $obj->title('Test Titel');
$expect = "<h1>Test Titel</h1>\n";
is($mhtml, $expect, "title");

$mhtml = $obj->title('Test Titel', 6);
$expect = "<h6>Test Titel</h6>\n";
is($mhtml, $expect, "title 6");

my $eval_run = 0;
eval {
    $obj->title('Test Titel', 7);
} or do {
    $eval_run = 1;
};
ok($eval_run, 'title 7');

# paragraph
$mhtml = $obj->paragraph("Ein Text.\nUnd das ist gut so.");
$expect = "<p>Ein Text.\nUnd das ist gut so.</p>\n";
is($mhtml, $expect, "paragraph");

# newline
$mhtml = $obj->newline();
$expect = "<br />\n";
is($mhtml, $expect, "newline");

# pagebreak
$mhtml = $obj->pagebreak();
$expect = "<mbp:pagebreak />\n";
is($mhtml, $expect, "pagebreak");

# verbatim
$mhtml = $obj->verbatim("Ein Text.\nUnd das ist gut so.");
$expect = "<i>Ein Text.\nUnd das ist gut so.</i>";
is($mhtml, $expect, "verbatim");

# bold
$mhtml = $obj->bold("Ein Text.\nUnd das ist gut so.");
$expect = "<b>Ein Text.\nUnd das ist gut so.</b>";
is($mhtml, $expect, "bold");

# code
$mhtml = $obj->code("Ein Text.\nUnd das ist gut so.");
$expect = "<code>Ein Text.\nUnd das ist gut so.</code>";
is($mhtml, $expect, "code");

# small
$mhtml = $obj->small("Ein Text.\nUnd das ist gut so.");
$expect = "<small>Ein Text.\nUnd das ist gut so.</small>";
is($mhtml, $expect, "small");

# big
$mhtml = $obj->big("Ein Text.\nUnd das ist gut so.");
$expect = "<big>Ein Text.\nUnd das ist gut so.</big>";
is($mhtml, $expect, "big");

# emphasize
$mhtml = $obj->emphasize("Ein Text.\nUnd das ist gut so.");
$expect = "<em>Ein Text.\nUnd das ist gut so.</em>";
is($mhtml, $expect, "emphasize");

# list
$mhtml = $obj->list(['A', 'B', 'C', 'D']);
$expect = "<ul>\n<li>A</li>\n<li>B</li>\n<li>C</li>\n<li>D</li>\n</ul>\n";
is($mhtml, $expect, "list");

$mhtml = $obj->list(['A', 'B', 'C', 'D'], 'ol');
$expect = "<ol>\n<li>A</li>\n<li>B</li>\n<li>C</li>\n<li>D</li>\n</ol>\n";
is($mhtml, $expect, "list ol");

# table
$mhtml = $obj->table(   th =>   ['A', 'B', 'C'],
                        td => [
                                ['1', '2', '3'],
                                ['10', '20', '30'],
                                ['100', '200', '300']
                              ],
                   );
$expect = "<table>\n<tr><th>A</th><th>B</th><th>C</th></tr>\n<tr><td>1</td><td>2</td><td>3</td></tr>\n<tr><td>10</td><td>20</td><td>30</td></tr>\n<tr><td>100</td><td>200</td><td>300</td></tr>\n</table>\n";
is($mhtml, $expect, "table minimal");

$mhtml = $obj->table(   th =>   ['A', 'B', 'C'],
                        td => [
                                ['1', '2', '3'],
                                ['10', '20', '30'],
                                ['100', '200', '300']
                              ],
                        caption => 'This is a table',
                        border => '8',
                        cellspacing => '10',
                        cellpadding => '20'
                    );
$expect = "<table border=\"8\" cellspacing=\"10\" cellpadding=\"20\">\n<tr><th>A</th><th>B</th><th>C</th></tr>\n<tr><td>1</td><td>2</td><td>3</td></tr>\n<tr><td>10</td><td>20</td><td>30</td></tr>\n<tr><td>100</td><td>200</td><td>300</td></tr>\n<caption>This is a table</caption>\n</table>\n";
is($mhtml, $expect, "table full");

# image
$mhtml = $obj->image('/path/to/pic.jpg', 'This is a picture');
$expect = '<img src="/path/to/pic.jpg" recindex="1" >' . "\n<p>This is a picture</p>\n";
is($mhtml, $expect, "image");

$mhtml = $obj->image('/path/to/pic2.jpg', 'This is a second picture');
$expect = '<img src="/path/to/pic2.jpg" recindex="2" >' . "\n<p>This is a second picture</p>\n";
is($mhtml, $expect, "image 2");

__END__
# 2
$pod_input{lists} = <<'HEREDOC';
=head1 LISTS

=over

=item normal list (1)

=item normal list (2)

=back

=over

=item 1 numbered list

=item 2 numbered list

=back

=over

=item * 5

=item normal list with number as first item

=back

=cut
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
<li>numbered list</li>
</ol>
<ul>
<li>5</li>
<li>normal list with number as first item</li>
</ul>
</body>
HEREDOC

# 3
$pod_input{lists_breakline} = <<'HEREDOC';
=head1 LISTS

=over

=item

normal list (1)

=item

normal list (2)

=back

=over

=item 1

numbered list

=item 2

numbered list

=back

=over

=item *

5

=item

normal list with number as first item

=back

=cut
HEREDOC

$html_out{lists_breakline} = <<'HEREDOC';
<body>
<h1>LISTS</h1>
<ul>
<li>normal list (1)</li>
<li>normal list (2)</li>
</ul>
<ol>
<li>numbered list</li>
<li>numbered list</li>
</ol>
<ul>
<li>5</li>
<li>normal list with number as first item</li>
</ul>
</body>
HEREDOC

$pod_input{lists_contentInCommand} = <<'HEREDOC';
=head1 Content in Command

=over

=item * First item.

=item * Second item.

=item * Third item.

=back
HEREDOC

$html_out{lists_contentInCommand} = <<'HEREDOC';
<body>
<h1>Content in Command</h1>
<ul>
<li>First item.</li>
<li>Second item.</li>
<li>Third item.</li>
</ul>
</body>
HEREDOC

$pod_input{lists_contentInTextblock} = <<'HEREDOC';
=head1 Content in Textblock

=over

=item

First item.

=item

Second item.

=item

Third item.

=back
HEREDOC

$html_out{lists_contentInTextblock} = <<'HEREDOC';
<body>
<h1>Content in Textblock</h1>
<ul>
<li>First item.</li>
<li>Second item.</li>
<li>Third item.</li>
</ul>
</body>
HEREDOC

$pod_input{lists_contentInTextblock2} = <<'HEREDOC';
=head1 Content as Textblock with *

=over

=item *

First item.

=item *

Second item.

=item *

Third item.

=back
HEREDOC

$html_out{lists_contentInTextblock2} = <<'HEREDOC';
<body>
<h1>Content as Textblock with *</h1>
<ul>
<li>First item.</li>
<li>Second item.</li>
<li>Third item.</li>
</ul>
</body>
HEREDOC

$pod_input{lists_contentMixed} = <<'HEREDOC';
=head1 Content mixed as Command and Textblock

=over

=item * First item.

=item * Second item.

With additional Text.

=item * Third item.

With additional Text.
With additional Text.

=back
HEREDOC

$html_out{lists_contentMixed} = <<'HEREDOC';
<body>
<h1>Content mixed as Command and Textblock</h1>
<ul>
<li>First item.</li>
<li>Second item.<br />With additional Text.</li>
<li>Third item.<br />With additional Text.
With additional Text.</li>
</ul>
</body>
HEREDOC

$pod_input{lists_nested} = <<'HEREDOC';
=head1 Nested List

=over

=item * First item.

=over

=item 1 First item.

=item 2 Second item.

=item 3 Third item.

=back

=item * Second item.

=item * Third item.

=back
HEREDOC

$html_out{lists_nested} = <<'HEREDOC';
<body>
<h1>Nested List</h1>
<ul>
<li>First item.</li>
<ol>
<li>First item.</li>
<li>Second item.</li>
<li>Third item.</li>
</ol>
<li>Second item.</li>
<li>Third item.</li>
</ul>
</body>
HEREDOC

$pod_input{lists_noItems} = <<'HEREDOC';
=head1 No Items (Blockquote)

=over

First item.

Second item.

Third item.

=back
HEREDOC

$html_out{lists_noItems} = <<'HEREDOC';
<body>
<h1>No Items (Blockquote)</h1>
<blockquote>First item.</blockquote>
<blockquote>Second item.</blockquote>
<blockquote>Third item.</blockquote>
</body>
HEREDOC

$pod_input{lists_noItemsNested} = <<'HEREDOC';
=head1 Nested Blockquote

=over

First item.

Second item.

=over

First.

Second.

Third.

=back

Third item.

=back
HEREDOC

$html_out{lists_noItemsNested} = <<'HEREDOC';
<body>
<h1>Nested Blockquote</h1>
<blockquote>First item.</blockquote>
<blockquote>Second item.</blockquote>
<blockquote><blockquote>First.</blockquote>
</blockquote>
<blockquote><blockquote>Second.</blockquote>
</blockquote>
<blockquote><blockquote>Third.</blockquote>
</blockquote>
<blockquote>Third item.</blockquote>
</body>
HEREDOC

$pod_input{lists_deepNested} = <<'HEREDOC';
=head1 Nested List of Depth 5 !!!

=over

=item * First item.

=item * First item.

=item * First item.

=over

=item 1 One.

=item 2 Two.

=over

=item * A

=over

=item * First item.

=item * First item.

=item * First item.

=over

=item 1 One.

=item 2 Two.

=over

=item * A

=item * B

=item * C

=back

=item 3 Three.

=back

=item * Second item.

=item * Third item.

=back

=item * B

=item * C

=back

=item 3 Three.

=back

=item * Second item.

=item * Third item.

=back
HEREDOC

$html_out{lists_deepNested} = <<'HEREDOC';
<body>
<h1>Nested List of Depth 5 !!!</h1>
<ul>
<li>First item.</li>
<li>First item.</li>
<li>First item.</li>
<ol>
<li>One.</li>
<li>Two.</li>
<ul>
<li>A</li>
<ul>
<li>First item.</li>
<li>First item.</li>
<li>First item.</li>
<ol>
<li>One.</li>
<li>Two.</li>
<ul>
<li>A</li>
<li>B</li>
<li>C</li>
</ul>
<li>Three.</li>
</ol>
<li>Second item.</li>
<li>Third item.</li>
</ul>
<li>B</li>
<li>C</li>
</ul>
<li>Three.</li>
</ol>
<li>Second item.</li>
<li>Third item.</li>
</ul>
</body>
HEREDOC

$pod_input{lists_nestedMixed1} = <<'HEREDOC';
=head1 Nested List with Blockquote

=over

=item 1 One.

=item 2 Two.

=over

A

B

C

=back

=item 3 Three.

=back
HEREDOC

$html_out{lists_nestedMixed1} = <<'HEREDOC';
<body>
<h1>Nested List with Blockquote</h1>
<ol>
<li>One.</li>
<li>Two.</li>
<blockquote><blockquote>A</blockquote>
</blockquote>
<blockquote><blockquote>B</blockquote>
</blockquote>
<blockquote><blockquote>C</blockquote>
</blockquote>
<li>Three.</li>
</ol>
</body>
HEREDOC

$pod_input{lists_nestedMixed2} = <<'HEREDOC';
=head1 Nested Blockquote with List

=over

One.

Two.

=over

=item * A

=item * B

=item * C

=back

Three.

=back
HEREDOC

$html_out{lists_nestedMixed2} = <<'HEREDOC';
<body>
<h1>Nested Blockquote with List</h1>
<blockquote>One.</blockquote>
<blockquote>Two.</blockquote>
<ul>
<li>A</li>
<li>B</li>
<li>C</li>
</ul>
<blockquote>Three.</blockquote>
</body>
HEREDOC

# 4
$pod_input{pic} = <<'HEREDOC';
=head2 PIC

Some text?

=image /path/to/pic.jpg This is the description!

Some other text...

=cut
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

# 5
$pod_input{umlaut} = <<'HEREDOC';
=head3 UMLAUT

üöäÜÖÄ
éàèÉÀÈ

=cut
HEREDOC

$html_out{umlaut} = <<'HEREDOC';
<body>
<h3>UMLAUT</h3>
<p>&uuml;&ouml;&auml;&Uuml;&Ouml;&Auml;
&eacute;&agrave;&egrave;&Eacute;&Agrave;&Egrave;</p>
</body>
HEREDOC

# 6
$pod_input{angle_bracket} = <<'HEREDOC';
=head4 ANGLE BRACKET

HTML chars:
<html> &nbsp; </html>

POD markup:
B<BOLD> C<CODE> F<FILE> I<ITALIC> E<nbsp> L<perl.org>

=cut
HEREDOC

$html_out{angle_bracket} = <<'HEREDOC';
<body>
<h4>ANGLE BRACKET</h4>
<p>HTML chars:
&lt;html&gt; &amp;nbsp; &lt;/html&gt;</p>
<p>POD markup:
<b>BOLD</b> <code>CODE</code> <code>FILE</code> <i>ITALIC</i> &nbsp; <a href='perl.org'>perl.org</a></p>
</body>
HEREDOC

# 7
$pod_input{code} = <<'HEREDOC';
=head1 CODE

Text1

  # Code
  # Multiline
  # No special chars
  # We only want to test
  # multiline code

Text2

=cut
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

# 8
$pod_input{pagebreak} = <<'HEREDOC';
=head1 PAGEBREAK

Text1

=head1 Here should be a break

Text2

=cut
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

# 9
$pod_input{inline_links} = <<'HEREDOC';
=head1 Inline Links

Link 1 L<Module>

Link 2 L<Module/Chapter>

Link 3 L<Name|Module>

Link 4 L<Name|Module/Chapter>

Link 5 L<Name|/Chapter>

Link 6 L</Chapter>

Link 7 L<http://perl.org>

Link 8 L<perl.org>

Link 9 L<Perl|http://perl.org>

Link 10 L<Perl|perl.org>

=cut
HEREDOC

$html_out{inline_links} = <<'HEREDOC';
<body>
<h1>Inline Links</h1>
<p>Link 1 <a href='https://metacpan.org/module/Module'>Module</a></p>
<p>Link 2 <a href='https://metacpan.org/module/Module#Chapter'>Module/Chapter</a></p>
<p>Link 3 <a href='https://metacpan.org/module/Module'>Name</a></p>
<p>Link 4 <a href='https://metacpan.org/module/Module#Chapter'>Name</a></p>
<p>Link 5 Name (Chapter)</p>
<p>Link 6 "Chapter"</p>
<p>Link 7 <a href='http://perl.org'>http://perl.org</a></p>
<p>Link 8 <a href='perl.org'>perl.org</a></p>
<p>Link 9 <a href='http://perl.org'>Perl</a></p>
<p>Link 10 <a href='perl.org'>Perl</a></p>
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
print $fh "=head1 NO BODY

There should be no html body-tag here.

=cut
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

# Ok, and we should also test what happens if we
# use $obj->head0_mode() so we do a seperate test here.
$obj = $module->new();
$obj->head0_mode(1);

($fh,$f_name) = tempfile();
binmode $fh;
print $fh "=head0 Biggest Title

Some text...

=head1 Head One

...should now be Head Two!

=cut
";
close $fh;
open $pod_handle, "<:encoding(utf-8)", $f_name;

$res_handle = IO::String->new($html_res);

$obj->parse_from_filehandle($pod_handle, $res_handle);
is($html_res,
   "<h1>Biggest Title</h1>\n<p>Some text...</p>\n<h2>Head One</h2>\n<p>...should now be Head Two!</p>\n",
   "POD to HTML -> head0_mode"
  );

########
# done #
########
1;

