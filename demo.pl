#!/usr/bin/perl
#

use lib "./lib";
use strict;
use Device::MatrixOrbital::GLK;

my $lcd = new Device::MatrixOrbital::GLK();

$lcd->clear_screen();

#$lcd->print("hello world\n");

$lcd->draw_rect( 1, 10, 10, 20, 20 );
$lcd->draw_rect( 1, 25, 25, 35, 35 );
$lcd->draw_rect( 1, 40, 40, 50, 50 );

$lcd->draw_line( 120, 1,  120, 62 );

$lcd->draw_rect( 1, 0, 0, 239, 63 );
$lcd->draw_rect( 1, 1, 1, 238, 62 );

$lcd->draw_bitmap( 1, 150, 5 );

#while(1) {
#	$lcd->draw_rect( int(rand(240)), int(rand(64)), int(rand(240)), int(rand(64)) );
#	sleep(0.1);
#}

#while(1) {
#	$lcd->draw_pixel( int(rand(240)), int(rand(64)),  );
#	sleep(0.1);
#}

#foreach my $n (0...100) {
#	$lcd->print("Hello World $n\n");
#	sleep 1;
#}

