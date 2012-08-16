package EBook::MOBI::Driver::Example;

use feature 'switch';

use EBook::MOBI::Converter;
use EBook::MOBI::Driver;

our @ISA = ('EBook::MOBI::Driver');


sub parse {
    my ($self, $input) = @_;

    # This module can help me to translate my stuff to html understood by
    # the mopipocket format
    my $converter = EBook::MOBI::Converter->new();

    # Because of "KISS" the module does not do much, but return the
    # converted stuff. So I need to manage the output myself.
    # I'll keep everything in this variable.
    my $mobiFormat = ''; 

    # We have some usefull methods from EBook::MOBI::Driver
    $self->debug_msg("Start parsing...");

    ########################################################################
    # Here is the parsing... for sure this looks different for any other   #
    # format. You might even use an existing parser like e.g. POD::Parser. #
    ########################################################################

    # work on each line, including newline
    while($input =~ /([^\n]+\n?)/g){
        my $line = $1; 

        # this converts every html special char to it's html entity.
        # if your markups format does interfere with html special chars
        # you should call this AFTER parsing.
        my $mobi_line .= $converter->text($line);

        if ($mobi_line =~ /^!(.)!\s+(.*)/) {
            my $cmd = $1; 
            my $txt = $2; 

            $self->debug_msg('work');

            given ($cmd) {
                when ('h') { $mobiFormat .= $converter->title ($txt)  }
                when ('i') { $mobiFormat .= $converter->italic($txt)
                                         .  $converter->newline();    }   
                when ('b') { $mobiFormat .= $converter->bold  ($txt)
                                         .  $converter->newline();    }
                when (' ') { $mobiFormat .=                    $txt
                                         .  $converter->newline();    }
                default    { $self->debug_msg("Unknown format: $cmd") }
            }
        }
        else {
            $self->debug_msg("Unknown line: $mobi_line");
        }
    }

    $self->debug_msg("...done");

    # and return the complete converted text
    return $mobiFormat;
}

1;

