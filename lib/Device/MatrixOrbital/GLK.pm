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
	
	# Set a serial timeout default of 5 seconds
	$self->{'timeout'} = 5;


	# Check LCD type
	if (defined $lcd_type) {
		$self->{'lcd_type'} = $lcd_type;
	} else {
		$self->{'lcd_type'} = $self->get_lcd_type();
	}
	
	# Lookup the number of pixels on the display
	($self->{'lcd_width'}, $self->{'lcd_height'}) = $self->get_lcd_pixels();


	return $self;
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

sub set_and_save_contrast {
	my $self = shift;
	my ($value) = @_;
	$self->send_command( 0x91, $value );
}

sub set_brightness {
	my $self = shift;
	my ($value) = @_;
	$self->send_command( 0x99, $value );
}

sub set_and_save_brightness {
	my $self = shift;
	my ($value) = @_;
	$self->send_command( 0x98, $value );
}

sub autoscroll_on {
	my $self = shift;
	$self->send_command( 0x51 );
}

sub autoscroll_off {
	my $self = shift;
	$self->send_command( 0x52 );
}


sub set_drawing_color {
	my $self = shift;
	my ($color) = @_;
	$self->send_command( 0x63, $color );
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

		my $value = $self->getchar();
		unless (defined $value) {
			warn "Failed to read single byte from LCD screen";
			return undef;
		}
		
		if ($value==0x01) { $self->{'lcd_type'}='LCD0821' }
		elsif ($value==0x02) { $self->{'lcd_type'}='LCD2021' }
		elsif ($value==0x05) { $self->{'lcd_type'}='LCD2041' }
		elsif ($value==0x06) { $self->{'lcd_type'}='LCD4021' }
		elsif ($value==0x07) { $self->{'lcd_type'}='LCD4041' }
		elsif ($value==0x08) { $self->{'lcd_type'}='LK202-25' }
		elsif ($value==0x09) { $self->{'lcd_type'}='LK204-25' }
		elsif ($value==0x0A) { $self->{'lcd_type'}='LK404-55' }
		elsif ($value==0x0B) { $self->{'lcd_type'}='VFD2021' }
		elsif ($value==0x0C) { $self->{'lcd_type'}='VFD2041' }
		elsif ($value==0x0D) { $self->{'lcd_type'}='VFD4021' }
		elsif ($value==0x0E) { $self->{'lcd_type'}='VK202-25' }
		elsif ($value==0x0F) { $self->{'lcd_type'}='VK204-25' }
		elsif ($value==0x10) { $self->{'lcd_type'}='GLC12232' }
		elsif ($value==0x13) { $self->{'lcd_type'}='GLC24064' }
		elsif ($value==0x15) { $self->{'lcd_type'}='GLK24064-25' }
		elsif ($value==0x22) { $self->{'lcd_type'}='GLK12232-25-WBL' }
		elsif ($value==0x24) { $self->{'lcd_type'}='GLK12232-25-SM' }
		elsif ($value==0x31) { $self->{'lcd_type'}='LK404-AT' }
		elsif ($value==0x32) { $self->{'lcd_type'}='MOS-AV-162A' }
		elsif ($value==0x33) { $self->{'lcd_type'}='LK402-12' }
		elsif ($value==0x34) { $self->{'lcd_type'}='LK162-12' }
		elsif ($value==0x35) { $self->{'lcd_type'}='LK204-25PC' }
		elsif ($value==0x36) { $self->{'lcd_type'}='LK202-24-USB' }
		elsif ($value==0x37) { $self->{'lcd_type'}='VK202-24-USB' }
		elsif ($value==0x38) { $self->{'lcd_type'}='LK204-24-USB' }
		elsif ($value==0x39) { $self->{'lcd_type'}='VK204-24-USB' }
		elsif ($value==0x3A) { $self->{'lcd_type'}='PK162-12' }
		elsif ($value==0x3B) { $self->{'lcd_type'}='VK162-12' }
		elsif ($value==0x3C) { $self->{'lcd_type'}='MOS-AP-162A' }
		elsif ($value==0x3D) { $self->{'lcd_type'}='PK202-25' }
		elsif ($value==0x3E) { $self->{'lcd_type'}='MOS-AL-162A' }
		elsif ($value==0x40) { $self->{'lcd_type'}='MOS-AV-202A' }
		elsif ($value==0x41) { $self->{'lcd_type'}='MOS-AP-202A' }
		elsif ($value==0x42) { $self->{'lcd_type'}='PK202-24-USB' }
		elsif ($value==0x43) { $self->{'lcd_type'}='MOS-AL-082' }
		elsif ($value==0x44) { $self->{'lcd_type'}='MOS-AL-204' }
		elsif ($value==0x45) { $self->{'lcd_type'}='MOS-AV-204' }
		elsif ($value==0x46) { $self->{'lcd_type'}='MOS-AL-402' }
		elsif ($value==0x47) { $self->{'lcd_type'}='MOS-AV-402' }
		elsif ($value==0x48) { $self->{'lcd_type'}='LK082-12' }
		elsif ($value==0x49) { $self->{'lcd_type'}='VK402-12' }
		elsif ($value==0x4A) { $self->{'lcd_type'}='VK404-55' }
		elsif ($value==0x4B) { $self->{'lcd_type'}='LK402-25' }
		elsif ($value==0x4C) { $self->{'lcd_type'}='VK402-25' }
		else { printf STDERR ("Unknown/unsupported LCD type 0x%x", $value); }
	}
	
	return $self->{'lcd_type'};
}

sub get_lcd_pixels {
	my $self = shift;

	# We need the LCD type first
	my $lcd = $self->get_lcd_type();

	if    ($lcd eq 'GLC12232') { return (122,32) }
	elsif ($lcd eq 'GLC24064') { return (240,64) }
	elsif ($lcd eq 'GLK24064-25') { return (240,64) }
	elsif ($lcd eq 'GLK12232-25-WBL') { return (122,32) }
	elsif ($lcd eq 'GLK12232-25-SM') { return (122,32) }
	else {
		warn "Unknown pixel dimensions for LCD: $lcd";
		return undef;
	}
}

sub get_firmware_version {
	my $self = shift;
	unless (defined $self->{'firmware_version'}) {
		$self->send_command( 0x36 );

		my $value = sprintf("%2.2x", $self->getchar() );
		my ($major, $minor) = ($value =~ /(\w{1})(\w{1})/);
		$self->{'firmware_version'} = "$major.$minor";
	}
	
	return $self->{'firmware_version'};
}



#### --------------------------------------------------------- ####



## Send a command to the display
sub send_command {
	my $self = shift;
	$self->print( pack( 'C*', 0xFE, @_ ) );
}


## Send a string to the display
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


## Send a formatted string to the display
sub printf {
	my $self = shift;
	
	$self->print( sprintf( @_ ) );
}


## Read a single byte from the serial port and return it as an integer
sub getchar {
	my $self = shift;

	# don't wait for each character
	$self->read_char_time(0);
	
	# milliseconds per unfulfilled "read" call
	$self->read_const_time($self->{'timeout'}*1000);

	# Read one charater
	my ($count,$data) = $self->read(1);
	return undef if ($count<1);
	return unpack('C',$data);
}


## Close the serial port
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
