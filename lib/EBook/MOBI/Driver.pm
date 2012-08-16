package EBook::MOBI::Driver;

use strict;
use warnings;

use HTML::Entities;

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

our $VERSION = 0.1;

sub new {
    my $self = shift;
    my $ref = {};  

    bless($ref, $self);
    return $ref;
}

sub parse {
    die ("method parse() not overriden.\n");
}

sub set_options {
    die ("method set_options() not overriden.\n");
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

1;

__END__

=encoding utf8

=head1 NAME

EBook::MOBI::Driver - Interface for plugins.

=head1 SYNOPSIS


  use EBook::MOBI::Driver;

=head1 IMPLEMENTED METHODS

=head2 new

Saves a plugin the need to wrtite this one.

=head2 debug_on

Enable debugging by passing a sub.

=head2 debug_off

Stop debug messages.

=head2 debug_msg

Write a debug message.

=head1 EMPTY METHODS

=head2 parse

Should be implemented by the plugin!
Takes a string, returns a string.

=head2 set_options

Should be implemented by the plugin!
Takes a %hash with arguments.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Boris Däppen, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms of Artistic License 2.0.

=head1 AUTHOR

Boris Däppen E<lt>boris_daeppen@bluewin.chE<gt>

=cut

