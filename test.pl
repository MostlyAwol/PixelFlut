#!/usr/local/bin/perl
use Color::Rgb;
$color = "FFCC00";
($r,$g,$b) = map $_, unpack 'C*', pack 'H*', $color;

print "$r - $g - $b\n";
