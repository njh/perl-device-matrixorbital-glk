package Device::MatrixOrbital::GLK;

################
#
# Perl module for controling the Matrix Orbital graphic LCD displays
#
# Nicholas J Humfrey
# njh@cpan.org
#

use Device::SerialPort;
use Params::Util qw(_SCALAR _POSINT);
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
    my $lcd_type = shift;
    

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
	
	# Check LCD type
	$self->{'lcd_type'} = $lcd_type;
	($self->{'lcd_width'}, $self->{'lcd_height'}) = $self->get_lcd_pixels();
	
	# Set a serial timeout default of 5 seconds
	$self->{'timeout'} = 5;

	$self->read_char_time(5);     # don't wait for each character
	$self->read_const_time(100); # 1 second per unfulfilled "read" call


	return $self;
}


sub print {
	my $self = shift;
	my ($string) = @_;
	my $bytes = 0;

	eval {
		local $SIG{ALRM} = sub { die "Timed out."; };
		alarm($self->{'timeout'});
		
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

sub backlight_on {
	my $self = shift;
	my $min = $_[0] || 0;
	$self->send_command( 0x42, $min );
}

sub backlight_off {
	my $self = shift;
	$self->send_command( 0x46 );
}

sub cursor_home {
	my $self = shift;
	$self->send_command( 0x48 );
}

sub set_contrast {
	my $self = shift;
	my ($value) = @_;
	$self->send_command( 0x50, $value );
}

sub set_brightness {
	my $self = shift;
	my ($value) = @_;
	$self->send_command( 0x99, $value );
}

sub autoscroll_on {
	my $self = shift;
	$self->send_command( 0x51 );
}

sub autoscroll_off {
	my $self = shift;
	$self->send_command( 0x52 );
}

sub clear_screen {
	my $self = shift;
	$self->send_command( 0x58 );
}

sub draw_bitmap {
	my $self = shift;
	my ($refid, $x, $y) = @_;
	$self->send_command( 0x62, $refid, $x, $y );
}

sub draw_line_continue {
	my $self = shift;
	my ($x, $y) = @_;
	$self->send_command( 0x65, $x, $y );
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

sub draw_solid_rect {
	my $self = shift;
	my ($colour, $x1, $y1, $x2, $y2) = @_;
	$self->send_command( 0x78, $colour, $x1, $y1, $x2, $y2 );
}

sub get_lcd_type {
	my $self = shift;
	unless (defined $self->{'lcd_type'}) {
		$self->send_command( 0x37 );
		#$self->gets();
		my ($bytes, $data) = $self->read(1);
		printf("Got %d bytes back (0x%x).\n", $bytes, unpack('C',$data) );
		my $value = unpack('C', $data);
		if ($value==0x01) { $self->{'lcd_type'}='LCD0821' }
		elsif ($value==0x15) { $self->{'lcd_type'}='GLK24064-25' }
	}
	
	return $self->{'lcd_type'};
}

sub get_lcd_pixels {
	my $self = shift;

	# We need the LCD type first
	my $lcd = $self->get_lcd_type();

	if    ($lcd eq 'GLC12232') { return (240,64) }
	elsif ($lcd eq 'GLC24064') { return (240,64) }
	elsif ($lcd eq 'GLK24064-25') { return (240,64) }
	elsif ($lcd eq 'GLC12232') { return (240,64) }
	elsif ($lcd eq 'GLC12232') { return (240,64) }
	elsif ($lcd eq 'GLC12232') { return (240,64) }
	else {
		warn "Unknown dimensions for LCD: $lcd";
		return undef;
	}
}

sub gets {
	my $self = shift;

	my $timeout = 5;
	
	$self->read_char_time(0);     # don't wait for each character
	$self->read_const_time(1000); # 1 second per unfulfilled "read" call
	
	my $chars=0;
	my $buffer="";
	while ($timeout>0) {
		my ($count,$saw)=$self->read(255); # will read _up to_ 255 chars
		if ($count > 0) {
			$chars+=$count;
			$buffer.=$saw;
			
			# Check here to see if what we want is in the $buffer
			# say "last" if we find it
			$buffer=~s/([^\040-\176])/sprintf("{0x%02X}",ord($1))/ge;
			print "saw ->$buffer<- ($chars)\n";
			last;
		}
		else {
			$timeout--;
		}
	}
	
	if ($timeout==0) {
		warn "Waited $timeout seconds and never saw what I wanted\n";
	}

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


#sub _LCD_WIDTH
#sub _LCD_HEIGHT

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
