#!/usr/bin/perl

use strict;
use warnings;

use File::Temp qw(tempfile);
use Data::Random qw(rand_image);
use Image::Size;

#######################
# TESTING starts here #
#######################
use Test::More tests => 5;

###########################
# General module tests... #
###########################

my $module = 'EBook::MOBI::Picture';
use_ok( $module );

my $obj = $module->new();

isa_ok($obj, $module);

can_ok($obj, qw(rescale_dimensions));

# we generate a random image
my ($fh,$f_name) = tempfile();
binmode $fh;
print $fh rand_image( bgcolor   => [0, 0, 0],
                      minwidth  => 600,
                      maxwidth  => 700,
                      minheight => 700,
                      maxheight => 800,
                    );
close $fh;

# rescale the image
my $checked_pic_path = $obj->rescale_dimensions($f_name);

# check the rescales size
my ($x, $y) = imgsize($checked_pic_path);
cmp_ok($x, '<=',  520, 'Image resized width');
cmp_ok($y, '<=',  622, 'Image resized heigth');

# remove the image, since it was just a test
unlink $checked_pic_path;


########
# done #
########
1;

