package Device::MatrixOrbital::GLK;

################
#
# Perl module for controling the Matrix Orbital graphic LCD displays
#
# Nicholas J Humfrey
# njh@cpan.org
#

use Device::SerialPort;
use strict;
use Carp;

use vars qw/$VERSION/;
our $VERSION="0.01";




sub new {
    my $class = shift;
    my ($device, $rate) = @_;

	# Create self
    my $self = {
    	'device' => $device || '/dev/ttyS0',
    	'baud_rate' => $rate || 19200,
    };
    bless $self, $class;


	# Create Serial Port and check for features
	$self->{'serial'} = new Device::SerialPort( $self->{'device'} )
	or die "Failed to create SerialPort object: $!";
	
	# Configure the Serial Port
	$self->{'serial'}->baudrate($self->{'baud_rate'}) || die ("Failed to set baud rate");
	$self->{'serial'}->parity("none") || die ("Failed to set parity");
	$self->{'serial'}->databits(8) || die ("Failed to set data bits");
	$self->{'serial'}->stopbits(1) || die ("Failed to set stop bits");
	$self->{'serial'}->handshake("none") || die ("Failed to disable handshaking");
	$self->{'serial'}->write_settings || die ("Failed to write settings");

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
    
    if (defined $self->{'serial'}) {
    	$self->{'serial'}->close || warn "Failed to close serial port.";
    	undef $self->{'serial'};
    }
}


1;

__END__

=pod

=head1 NAME

Device::MatrixOrbital::GLK

=head1 SYNOPSIS

  use Device::MatrixOrbital::GLK;

  my $lcd = new Device::MatrixOrbital::GLK();


  $lcd->close();


=head1 DESCRIPTION

Device::MatrixOrbital::GLK blah blah blah




=head1 AUTHOR

Nicholas J Humfrey, njh@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Nicholas J Humfrey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.005 or,
at your option, any later version of Perl 5 you may have available.

=cut
