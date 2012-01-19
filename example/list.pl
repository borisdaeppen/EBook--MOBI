#!/usr/bin/perl

use EBook::MOBI;

my $pod = <<END;

=head1 A List

=over

=item *

First item.

=item *

Second item.

=item *

Third item.

=back

=head1 Another List

=over

=item * First item.

=item * Second item.

=item * Third item.

=back

=cut

END

my $book = EBook::MOBI->new();

# let's define a debug sub witch will be used by all modules
sub debug {
    my ($package, $filename, $line) = caller;
    print "$package\t$_[0]\n";
}

# pass the reference of the sub to our book
#$book->debug_on(\&debug);

# fill the book with meta info
$book->set_filename('List.mobi');
$book->set_title   ('A List');
$book->set_author  ('Boris');
$book->set_encoding('utf-8');

# fill the book with content
$book->add_pod_content($pod);

$book->make();
$book->print_mhtml();
$book->save();

