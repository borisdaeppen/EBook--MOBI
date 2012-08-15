package EBook::MOBI::Driver;

use strict;
use warnings;

use HTML::Entities;
use HTML::Table;

# This constants are used for internal replacement
# See interior_sequence() and _html_enc() for usage
use constant { GT  => '1_qpdhcn_thisStringShouldNeverOccurInInput',
               LT  => '2_udtcqk_thisStringShouldNeverOccurInInput',
               AMP => '3_pegjyq_thisStringShouldNeverOccurInInput',
               COL => '4_jdkmso_thisStringShouldNeverOccurInInput',
               QUO => '5_wuehlo_thisStringShouldNeverOccurInInput',
               DQUO=> '6_jrgwpm_thisStringShouldNeverOccurInInput',
             };

# IMPORTANT
# This constant ist JUST a shortcut for readability.
# Because it is used in hases ($parser->{}) a + is used so that it is not
# interpreted as a string, so it looks like this: $parser->{+P . 'bla'}
# See http://perldoc.perl.org/constant.html for details
use constant { P   => 'EBook_MOBI_Pod2Mhtml_' };

sub new {
    my $self = shift;
    my $ref = {};  

    bless($ref, $self);
    return $ref;
}


sub parse {
    die ("method parse() no overriden.\n");
}

sub html_body {
    my ($self, $boolean) = @_;

    if (@_ > 1) {
        $self->{+P . 'body'} = $boolean;
    }
    else {
        return $self->{+P . 'body'};
    }
}

sub pagemode {
    my ($self, $boolean) = @_;

    if (@_ > 1) {
        $self->{+P . 'pages'} = $boolean;
    }
    else {
        return $self->{+P . 'pages'};
    }
}

sub head0_mode {
    my ($self, $boolean) = @_;

    if (@_ > 1) {
        $self->{+P . 'head0_mode'} = $boolean;
    }
    else {
        return $self->{+P . 'head0_mode'};
    }
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
sub debug_msg {
    my ($self,$msg) = @_; 

    if ($self->{ref_to_debug_sub}) {
        &{$self->{ref_to_debug_sub}}($msg);
    }   
}

# encode_entities() from HTML::Entities does not translate it correctly
# this is why I make it here manually as a quick fix
# don't reall know where how to handle this utf8 problem for now...
sub html_enc {
    my $string = shift;

    $string = encode_entities($string);
                            #    ^
    my $lt = LT;            #    |
    my $gt = GT;            #    |
    my $am = AMP;           #    |
    my $co = COL;           #    |-- don't change this order!
    my $qu = QUO;           #    |
    my $dqu= DQUO;          #    |
    $string =~ s/$lt/</g;   #    |
    $string =~ s/$gt/>/g;   #    |
    $string =~ s/$am/&/g;   #    |
    $string =~ s/$co/;/g;   #    |
    $string =~ s/$qu/'/g;   #    |
    $string =~ s/$dqu/"/g;  #<---|

    return $string;
}

1;

__END__

=encoding utf8

=head1 NAME

EBook::MOBI::Driver - Interface for plugins.

=head1 SYNOPSIS


  use EBook::MOBI::Driver;

=head1 METHODS

=head1 COPYRIGHT & LICENSE

Copyright 2011 Boris Däppen, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms of Artistic License 2.0.

=head1 AUTHOR

Boris Däppen E<lt>boris_daeppen@bluewin.chE<gt>

=cut

