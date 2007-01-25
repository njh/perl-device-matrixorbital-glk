package Device::MatrixOrbital::GLK24064;

################
#
# Perl module for controling the Matrix Orbital GLK24064
#
# Nicholas J Humfrey
# njh@cpan.org
#

use strict;
use Carp;

use vars qw/$VERSION/;
our $VERSION="0.01";




sub new {
    my $class = shift;
    my ($host, $adaptor) = @_;

	# Create self
    my $self = {
    	'port' => undef,
    };
    bless $self, $class;


	return $self;
}

#print_text(string)
#cursor_home()
#cursor_set_pos(col,row)
#cursor_set_coord(x,y)
#autoscroll_on()
#autoscroll_off()

#set_colour( colour )
#draw_pixel( x,y )
#draw_line( x1, y1, x2, y2 )
#draw_line_continue( x, y )
#draw_rect( x1, y1, x2, y2 )
#draw_solid_rect( x1, y1, x2, y2 )

#clear_screen()
#backlight_on()
#backlight_off()
#set_backlight_brightness(brightness)
#default_backlight_brightness(brightness)
#set_contrast(brightness)
#default_contrast(brightness)


#get_pcb_version
#get_pcb_type


#
# Close the serial port
#
sub DESTROY {
    my $self=shift;
    
}


1;

__END__

=pod

=head1 NAME

Device::MatrixOrbital::GLK24064

=head1 SYNOPSIS

  use Device::MatrixOrbital::GLK24064;

  my $lcd = new Device::MatrixOrbital::GLK24064();


  $lcd->close();


=head1 DESCRIPTION

Device::MatrixOrbital::GLK24064 blah blah blah




=head1 AUTHOR

Nicholas J Humfrey, njh@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Nicholas J Humfrey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.005 or,
at your option, any later version of Perl 5 you may have available.

=cut
