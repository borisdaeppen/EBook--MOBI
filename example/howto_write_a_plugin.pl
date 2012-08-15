#!/home/bo/perl5/perlbrew/perls/perl-5.14.2/bin/perl

package EBook::MOBI::Example::AnyPlugin;

# This is an input plugin for EBook::MOBI
use EBook::MOBI::Driver;
our @ISA = qw(EBook::MOBI::Driver);

# We use the converter to give us some help
use EBook::MOBI::Converter;

sub parse {
    ($self, $anyFormat) = @_;

    my $converter = EBook::MOBI::Converter->new();

    my $mobiFormat = '';

    $self->debug_msg("Start parsing...");

    while($anyFormat =~ /([^\n]+)\n?/g){
        my $line = $1;

        my $mobi_line .= $converter->text($line);

        if    ($mobi_line =~ /^!h!\s+(.*)/) {
            $self->debug_msg("Title found");
            $mobiFormat .= $converter->title($1);
        }
        elsif ($mobi_line =~ /^!i!\s+(.*)/) {
            $mobiFormat .= $converter->italic($1);
        }
        elsif ($mobi_line =~ /^!b!\s+(.*)/) {
            $mobiFormat .= $converter->bold($1);
        }
        elsif ($mobi_line =~ /^\s+(.*)/) {
            $mobiFormat .= $1;
        }
    }

    $self->debug_msg("...done");

    return $mobiFormat;
}


package EBook::MOBI::Example::UsePlugin;
use utf8;

my $plugin = EBook::MOBI::Example::AnyPlugin->new();

sub debug {
    my ($package, $filename, $line) = caller;
    print "$package\t$_[0]\n";
}
$plugin->debug_on(\&debug);

my $anyFormat = <<END;
!h! Goethe: An die Erwählte
    Frisch gewagt ist schon gewonnen,
!i! Halb ist schon mein Werk vollbracht!
    Sterne leuchten mir wie Sonnen,
!b! Nur dem Feigen ist es Nacht.
END

print $plugin->parse($anyFormat);
print "\n";

$plugin->debug_off();

#1;
