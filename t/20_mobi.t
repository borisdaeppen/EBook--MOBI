#!/usr/bin/perl

use strict;
use warnings;

#######################
# TESTING starts here #
#######################
use Test::More tests => 4;

###########################
# General module tests... #
###########################

my $module = 'EBook::MOBI';
use_ok( $module );

my $obj = $module->new();

isa_ok($obj, $module);

can_ok($obj, qw(set_title set_author set_filename add_mhtml_content add_pod_content add_pagebreak add_toc_once make save print_mhtml));

################################
# We define some parsing input #
# and also how the result      #
# should look like             #
################################
my %html_in ; # parsing input
my %html_out;  # parsing result

# 1
$html_in{TOC} = <<'HEREDOC';
 <h1>NOT IN TOC</h1>
This should not appear in TOC because of the whitespace at begin of line.
<h1>CHAPTER ONE</h1>
This should appear in the TOC.
<h1>CHAPTER TWO</h1>
This too. Lets make some text to fill some gaps:<br />
<br />
<b>I've a Pain in my Head by Jane Austen</b><br />
<br />
'I've a pain in my head'<br />
Said the suffering Beckford;<br />
To her Doctor so dread.<br />
'Oh! what shall I take for't?'<br />
<br />
Said this Doctor so dread<br />
Whose name it was Newnham.<br />
'For this pain in your head<br />
Ah! What can you do Ma'am?'<br />
<br />
Said Miss Beckford, 'Suppose<br />
If you think there's no risk,<br />
I take a good Dose<br />
Of calomel brisk.'--<br />
<br />
'What a praise worthy Notion.'<br />
Replied Mr. Newnham.<br />
'You shall have such a potion<br />
And so will I too Ma'am.' <br />
<h2>NOT IN TOC 2</h2>
This should not appear in TOC because it's head type 2.
HEREDOC

$html_out{TOC} = <<'HEREDOC';
<html>
<head>
<guide>
<reference type="toc" title="Table of Contents" filepos="00000151"/>
</guide>
</head>
<body>
<b><i>TEST</i></b><mbp:pagebreak />
<h1>Table of Contents</h1><!-- TOC start -->
<p><ul>
<li><a filepos="00000458">CHAPTER ONE</a></li><!-- TOC entry -->
<li><a filepos="00000510">CHAPTER TWO</a></li><!-- TOC entry -->
</ul></p>

<mbp:pagebreak />
 <h1>NOT IN TOC</h1>
This should not appear in TOC because of the whitespace at begin of line.
<h1>CHAPTER ONE</h1>
This should appear in the TOC.
<h1>CHAPTER TWO</h1>
This too. Lets make some text to fill some gaps:<br />
<br />
<b>I've a Pain in my Head by Jane Austen</b><br />
<br />
'I've a pain in my head'<br />
Said the suffering Beckford;<br />
To her Doctor so dread.<br />
'Oh! what shall I take for't?'<br />
<br />
Said this Doctor so dread<br />
Whose name it was Newnham.<br />
'For this pain in your head<br />
Ah! What can you do Ma'am?'<br />
<br />
Said Miss Beckford, 'Suppose<br />
If you think there's no risk,<br />
I take a good Dose<br />
Of calomel brisk.'--<br />
<br />
'What a praise worthy Notion.'<br />
Replied Mr. Newnham.<br />
'You shall have such a potion<br />
And so will I too Ma'am.' <br />
<h2>NOT IN TOC 2</h2>
This should not appear in TOC because it's head type 2.
</body>
</html>
HEREDOC

#################################################
# Now we parse the input and compare the result #
# with what we expected...                      #
#################################################
for my $key (keys %html_in) {
    # we make a new book for each test
    my $obj = $module->new();

    $obj->add_mhtml_content('<b><i>TEST</i></b>');
    $obj->add_pagebreak();
    $obj->add_toc_once();
    $obj->add_pagebreak();
    $obj->add_mhtml_content($html_in{$key});
    $obj->make();

    my $html_res = $obj->print_mhtml('no print to stdout');

    is($html_res, $html_out{$key}, "Book -> $key");
}

########
# done #
########
1;

