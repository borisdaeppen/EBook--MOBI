#!/usr/bin/perl

use EBook::MOBI;

my $someText = '';
for (1..100) {
    $someText .= 'Hello World! This is just a test. '
}

my $pod = <<END;

=head1 Some POD

$someText

=image ./example/img/camel.jpg Pic one

$someText

=image ./example/img/camel_big.jpg Pic two

$someText

=image ./example/img/camel.jpg Pic one

$someText

=image ./example/img/camel_big.jpg Pic two

$someText

=image ./example/img/camel.jpg Pic one

$someText

=image ./example/img/camel_big.jpg Pic two

$someText

END

my $book = EBook::MOBI->new();

# let's define a debug sub witch will be used by all modules
sub debug {
    my ($package, $filename, $line) = caller;
    print "$package\t$_[0]\n";
}

# pass the reference of the sub to our book
$book->debug_on(\&debug);

# fill the book with meta info
$book->set_filename('Simple.mobi');
$book->set_title   ('A Test');
$book->set_author  ('Boris');
$book->set_encoding('utf-8');

# fill the book with content
$book->add_mhtml_content(" <h1>A Test Titlepage</h1><p>Very simple...</p>");
$book->add_pagebreak();
$book->add_toc_once();
$book->add_pagebreak();
$book->add_pod_content($pod, 'pagemode');

$book->make();
$book->print_mhtml();
$book->save();

