#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.08";
plan skip_all
      => "Test::Pod::Coverage 1.08 required for testing POD coverage" if $@;

plan tests => 4;

#all_pod_coverage_ok();
pod_coverage_ok('EBook::MOBI');
pod_coverage_ok('EBook::MOBI::Mhtml2Mobi');
pod_coverage_ok('EBook::MOBI::Picture');
pod_coverage_ok('EBook::MOBI::Pod2Mhtml');

