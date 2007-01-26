package Device::MatrixOrbital::GLK;

################
#
# Perl module for controling the Matrix Orbital graphic LCD displays
#
# Nicholas J Humfrey
# njh@cpan.org
#

use Device::SerialPort;
use Time::HiRes qw(sleep alarm);
use strict;
use Carp;

use vars qw/$VERSION @ISA/;
@ISA = "Device::SerialPort";
$VERSION="0.01";



sub new {
    my $class = shift;
    my $port = shift || '/dev/ttyS0';
    my $baudrate = shift || 19200;
    my $timeout = shift || 5;
    

	# Create self using super class
	my $self = $class->SUPER::new( $port )
	or die "Failed to create SerialPort object: $!";
	
	# Configure the Serial Port
	$self->baudrate($baudrate) || die ("Failed to set baud rate");
	$self->parity("none") || die ("Failed to set parity");
	$self->databits(8) || die ("Failed to set data bits");
	$self->stopbits(1) || die ("Failed to set stop bits");
	$self->handshake("none") || die ("Failed to disable handshaking");
	$self->write_settings || die ("Failed to write settings");

	# Check for features
	die "status isn't available for serial port: $port"
	unless ($self->can_status());
	die "write_done isn't available for serial port: $port"
	unless ($self->can_write_done());
	

	return $self;
}


sub print {
	my $self = shift;
	my ($string) = @_;
	my $bytes = 0;

	eval {
		local $SIG{ALRM} = sub { die "Timed out."; };
		alarm(5);
		
		# Send it
		$bytes = $self->write( $string );
		
		# Block until it is sent
		while(($self->write_done(0))[0] == 0) {}
		
		alarm 0;
	};
	
	if ($@) {
		die unless $@ eq "Timed out.\n";   # propagate unexpected errors
		# timed out
		warn "Timed out while writing to serial port.\n";
 	}	

	return $bytes;
}


sub printf {
	my $self = shift;
	
	$self->print( sprintf( @_ ) );
}

sub clear_screen {
	my $self = shift;
	$self->send_command( 0x58 );
}

sub backlight_on {
	my $self = shift;
	$self->send_command( 0x42, 0x00 );
}

sub backlight_off {
	my $self = shift;
	$self->send_command( 0x46 );
}

sub cursor_home {
	my $self = shift;
	$self->send_command( 0x48 );
}

sub autoscroll_on {
	my $self = shift;
	$self->send_command( 0x51 );
}

sub autoscroll_off {
	my $self = shift;
	$self->send_command( 0x52 );
}

sub draw_bitmap {
	my $self = shift;
	my ($refid, $x, $y) = @_;
	$self->send_command( 0x62, $refid, $x, $y );
}

sub draw_line {
	my $self = shift;
	my ($x1, $y1, $x2, $y2) = @_;
	$self->send_command( 0x6C, $x1, $y1, $x2, $y2 );
}

sub draw_pixel {
	my $self = shift;
	my ($x, $y) = @_;
	$self->send_command( 0x70, $x, $y );
}

sub draw_rect {
	my $self = shift;
	my ($colour, $x1, $y1, $x2, $y2) = @_;
	$self->send_command( 0x72, $colour, $x1, $y1, $x2, $y2 );
}

sub send_command {
	my $self = shift;
	$self->print( pack( 'C*', 0xFE, @_ ) );
}


#printf(string)
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
