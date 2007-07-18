package Device::MatrixOrbital::GLK;

################
#
# Perl module for controling the Matrix Orbital graphic LCD displays
#
# Nicholas J Humfrey
# njh@cpan.org
#

use Time::HiRes qw(sleep alarm);
use POSIX qw(:termios_h);
use IO::File;
use strict;
use Carp;

use vars qw/$VERSION @ISA/;
@ISA = qw/IO::File/;
$VERSION="0.02";



sub new {
    my $class = shift;
    my $port = shift || '/dev/ttyS0';
    my $baudrate = shift || 19200;
    my $lcd_type = shift;
    

    # Bless self hashref into an object
	my $self = {};
    bless $self, $class;


	# Create self using super class
	$self->{'port'} = new IO::File( $port, 'r+' )
	or croak "Failed to create IO::File object: $!";
	
	# Create new termios object
	$self->{'termios'} = new POSIX::Termios();
	
	# Configure the Serial Port
	#$self->configure_serialport();
	
	# Set the baud rate
	$self->set_baudrate( $baudrate );
	


	
	# Set a serial timeout default of 1 second
	$self->{'timeout'} = 1000;
	
	# We don't support flow control - turn it off
	$self->set_flow_control_off();

	# Check LCD type
	if (defined $lcd_type) {
		$self->{'lcd_type'} = $lcd_type;
	} else {
		$self->{'lcd_type'} = $self->get_lcd_type();
	}
	
	
	
	return $self;
}


sub configure_serialport {
	my $self = shift;
	my $termios = $self->{'termios'};
	my $fileno = $self->{'port'}->fileno();
	
	## Serial settings, 8 data bits, 1 stop bit, no parity, no handshaking
	$termios->getattr( $fileno ) || die "getattr: $!\n";
	$termios->setcflag( 0x00 | &POSIX::CS8 | &POSIX::HUPCL | &POSIX::CREAD | &POSIX::CLOCAL);
	$termios->setlflag( 0x00 );
	$termios->setiflag( 0x00 | &POSIX::IGNBRK | &POSIX::IGNPAR );
	$termios->setoflag( 0x00 );
	$termios->setattr( $fileno, &POSIX::TCSANOW ) || die "getattr: $!\n";
	
    # Make reads wait up to 200ms for a character
   # $termios->getattr($fileno) || die "getattr: $!\n";        
    #$termios->setcc(VMIN,0);
    #$termios->setcc(VTIME,1);
    #$termios->setattr($fileno,TCSANOW) || die "setattr: $!\n";
}

sub set_baudrate {
	my $self = shift;
	my ($baudrate) = @_;
	
	# Lookup the POSIX symbol/value
	my $brate = undef;
	if ($baudrate==9600) { $brate=&POSIX::B9600; }
	elsif ($baudrate==14400) { $brate=&POSIX::B14400; }
	elsif ($baudrate==19200) { $brate=&POSIX::B19200; }
	elsif ($baudrate==28800) { $brate=&POSIX::B28800; }
	elsif ($baudrate==38400) { $brate=&POSIX::B38400; }
	elsif ($baudrate==57600) { $brate=&POSIX::B57600; }
	elsif ($baudrate==76800) { $brate=&POSIX::B76800; }
	elsif ($baudrate==115200) { $brate=&POSIX::B115200; }
	
	if (defined $brate) {
		# Apply the baud rate
		my $termios = $self->{'termios'};
		my $fileno = $self->{'port'}->fileno();
		$termios->getattr( $fileno ) || die "getattr: $!\n";
		$termios->setospeed( $brate ) || die "setospeed: $!";
		$termios->setispeed( $brate ) || die "setispeed: $!";
		$termios->setattr( $fileno, &POSIX::TCSANOW ) || die "getattr: $!\n";
	} else {
		croak "Invalid/unsupported baud rate: $baudrate";
	}
}

sub set_i2c_slave_address {
	my $self = shift;
	my ($address) = @_;
	carp "Missing I2C address value" unless (defined $address);
	$self->send_command( 0x46, $address );
}


sub set_lcd_baudrate {
	my $self = shift;
	my ($baudrate) = @_;
	carp "Missing baudrate value" unless (defined $baudrate);
	
	if ($baudrate==9600) { $self->send_command( 0x39, 0xCF ); }
	elsif ($baudrate==14400) { $self->send_command( 0x39, 0x8A ); }
	elsif ($baudrate==19200) { $self->send_command( 0x39, 0x67 ); }
	elsif ($baudrate==28800) { $self->send_command( 0x39, 0x44 ); }
	elsif ($baudrate==38400) { $self->send_command( 0x39, 0x33 ); }
	elsif ($baudrate==57600) { $self->send_command( 0x39, 0x22 ); }
	elsif ($baudrate==76800) { $self->send_command( 0x39, 0x19 ); }
	elsif ($baudrate==115200) { $self->send_command( 0x39, 0x10 ); }
	else { carp "Invalid/unsupported baud rate: $baudrate"; }
}

#sub set_flow_control_on {
#	my $self = shift;
#	$self->send_command( 0x3A );
#}

sub set_flow_control_off {
	my $self = shift;
	$self->send_command( 0x3B );
}


sub set_backlight_on {
	my $self = shift;
	my $min = $_[0] || 0;
	$self->send_command( 0x42, $min );
}

sub set_backlight_off {
	my $self = shift;
	$self->send_command( 0x46 );
}

sub cursor_home {
	my $self = shift;
	$self->send_command( 0x48 );
}

sub set_contrast {
	my $self = shift;
	my ($contrast) = @_;
	carp "Missing contrast value" unless (defined $contrast);
	$self->send_command( 0x50, $contrast );
}

sub set_and_save_contrast {
	my $self = shift;
	my ($contrast) = @_;
	carp "Missing contrast value" unless (defined $contrast);
	$self->send_command( 0x91, $contrast );
}

sub set_brightness {
	my $self = shift;
	my ($brightness) = @_;
	carp "Missing brightness value" unless (defined $brightness);
	$self->send_command( 0x99, $brightness );
}

sub set_and_save_brightness {
	my $self = shift;
	my ($brightness) = @_;
	carp "Missing brightness value" unless (defined $brightness);
	$self->send_command( 0x98, $brightness );
}

sub set_autoscroll_on {
	my $self = shift;
	$self->send_command( 0x51 );
}

sub set_autoscroll_off {
	my $self = shift;
	$self->send_command( 0x52 );
}


sub set_drawing_color {
	my $self = shift;
	my ($color) = @_;
	carp "Missing drawing colour" unless (defined $color);
	$self->send_command( 0x63, $color );
}

sub clear_screen {
	my $self = shift;
	$self->send_command( 0x58 );
}

sub draw_bitmap {
	my $self = shift;
	my ($refid, $x, $y) = @_;
	carp "Missing reference ID" unless (defined $refid);
	carp "Missing X value" unless (defined $x);
	carp "Missing Y value" unless (defined $y);
	$self->send_command( 0x62, $refid, $x, $y );
}

sub draw_pixel {
	my $self = shift;
	my ($x, $y) = @_;
	carp "Missing X value" unless (defined $x);
	carp "Missing Y value" unless (defined $y);
	$self->send_command( 0x70, $x, $y );
}

sub draw_line {
	my $self = shift;
	my ($x1, $y1, $x2, $y2) = @_;
	carp "Missing X1 value" unless (defined $x1);
	carp "Missing Y1 value" unless (defined $y1);
	carp "Missing X2 value" unless (defined $x2);
	carp "Missing Y2 value" unless (defined $y2);
	$self->send_command( 0x6C, $x1, $y1, $x2, $y2 );
}

sub draw_line_continue {
	my $self = shift;
	my ($x, $y) = @_;
	carp "Missing X value" unless (defined $x);
	carp "Missing Y value" unless (defined $y);
	$self->send_command( 0x65, $x, $y );
}

sub draw_rect {
	my $self = shift;
	my ($color, $x1, $y1, $x2, $y2) = @_;
	carp "Missing color value" unless (defined $color);
	carp "Missing X1 value" unless (defined $x1);
	carp "Missing Y1 value" unless (defined $y1);
	carp "Missing X2 value" unless (defined $x2);
	carp "Missing Y2 value" unless (defined $y2);
	$self->send_command( 0x72, $color, $x1, $y1, $x2, $y2 );
}


sub delete_bitmap {
	my $self = shift;
	my ($refid) = @_;
	carp "Type of reference ID of bitmap to delete" unless (defined $refid);
	$self->send_command( 0xFE, 0xAD, 0x01, $refid );
}

sub delete_font {
	my $self = shift;
	my ($refid) = @_;
	carp "Type of reference ID of font to delete" unless (defined $refid);
	$self->send_command( 0xFE, 0xAD, 0x00, $refid );
}


sub wipe_filesystem {
	my $self = shift;
	$self->send_command( 0xFE, 0x21, 0x59, 0x21 );
}

sub get_filesystem_space {
	my $self = shift;
	$self->send_command( 0xFE, 0xAF );

	my $count = $self->getint();
	
	#$count |= ( & 0xFF) << 0;
	#$count |= ($self->getchar() & 0xFF) << 8;
	#$count |= ($self->getchar() & 0xFF) << 16;
	#$count |= ($self->getchar() & 0xFF) << 24;
	#
	#return $count;
}

sub get_filesystem_directory {
	my $self = shift;
	$self->send_command( 0xFE, 0xB3 );

	my $lsb = $self->getchar();
	
	#my @bytes = $self->getbytes( 4 );

	#my $count = 0;
	#$count |= (@bytes[0] & 0xFF) << 0;
	#$count |= (@bytes[1] & 0xFF) << 8;
	#$count |= (@bytes[2] & 0xFF) << 16;
	#$count |= (@bytes[3] & 0xFF) << 24;
	
	#return $count;
	
	return $lsb;
}

sub draw_solid_rect {
	my $self = shift;
	my ($color, $x1, $y1, $x2, $y2) = @_;
	carp "Missing color value" unless (defined $color);
	carp "Missing X1 value" unless (defined $x1);
	carp "Missing Y1 value" unless (defined $y1);
	carp "Missing X2 value" unless (defined $x2);
	carp "Missing Y2 value" unless (defined $y2);
	$self->send_command( 0x78, $color, $x1, $y1, $x2, $y2 );
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

sub get_lcd_dimensions {
	my $self = shift;

	# We need the LCD type first
	my $lcd = $self->get_lcd_type();

	if    ($lcd eq 'GLC12232') { return (122,32) }
	elsif ($lcd eq 'GLC24064') { return (240,64) }
	elsif ($lcd eq 'GLK24064-25') { return (240,64) }
	elsif ($lcd eq 'GLK12232-25-WBL') { return (122,32) }
	elsif ($lcd eq 'GLK12232-25-SM') { return (122,32) }
	elsif ($lcd eq 'GLK240128-25') { return (240,128) }
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
	$self->{'port'}->print( pack( 'C*', 0xFE, @_ ) );
}


## Send a string to the display
#sub print {
#	my $self = shift;
#	my ($string) = @_;
# 	my $bytes = 0;
# 
# 	eval {
# 		local $SIG{ALRM} = sub { die "Timed out."; };
# 		alarm($self->{'timeout'}/1000);
# 		
# 		# Send it
# 		$bytes = $self->write( $string );
# 		
# 		# Block until it is sent
# 		while(($self->write_done(0))[0] == 0) {}
# 		
# 		alarm 0;
# 	};
# 	
# 	if ($@) {
# 		die unless $@ eq "Timed out.\n";   # propagate unexpected errors
# 		# timed out
# 		warn "Timed out while writing to serial port.\n";
#  	}	
# 
# 	return $bytes;
# }


## Send a formatted string to the display
# sub printf {
# 	my $self = shift;
# 	
# 	$self->print( sprintf( @_ ) );
# }


## Read a single byte from the serial port and return it as an integer
sub getchar {
	my $self = shift;

	# Read one charater
	my $data = '';
	my $count = $self->{'port'}->read($data, 1);
	return undef if ($count<1);
	return unpack('C',$data);
}


## Read an integer from the serial port
sub getint {
	my $self = shift;

	# Read one charater
	my $data = '';
	my $count = $self->{'port'}->read($data, 4);
	printf("Read $count bytes: 0x%x,0x%x,0x%x,0x%x\n", unpack("C*", $data) );
	
	#return undef if ($count<4);
	return unpack('C*',$data);
}



## Close the serial port
sub DESTROY {
    my $self=shift;
    
    undef $self->{'termios'};
    
    $self->close || warn "Failed to close serial port.";
}


1;

__END__

=pod

=head1 NAME

Device::MatrixOrbital::GLK - Control the GLK series Matrix Orbital displays

=head1 SYNOPSIS

  use Device::MatrixOrbital::GLK;

  my $lcd = new Device::MatrixOrbital::GLK();

  $lcd->clear_screen();
  $lcd->print("Hello World!");

  $lcd->close();


=head1 DESCRIPTION

Device::MatrixOrbital::GLK is an object oriented perl module for controlling 
the GLK serial of LCD screens made by Matrix Orbital.

For more information about GLK series MatrixOrbital displays, please visit:
L<http://www.matrixorbital.ca/products/glk_Series/>

Please note that I am not an employee and have nothing to do with MatrixOrbital,
other than being a happy customer.


=head1 METHODS

=over 4

=item B<new( [$port], [$baudrate], [$lcdtype] )>

Creates a new C<Device::MatrixOrbital::GLK> object. All of the parametes are 
optional. The default port is '/dev/ttyS0', the default baud rate is 19200 and 
by default the LCD screen type will be detected automatically.


=item B<print( $string )>

Display a string on the screen.

=item B<printf( $format, @params )>

Display a formatted string on the screen.


=item B<set_i2c_slave_address( $address )>

This command sets the I2C write address of the module between 0x00 
and 0xFF. The I2C write address must be an even number and the read 
address is automatically set to one higher. For example if the I2C write 
address is set to 0x50, then the read address is 0x51. 


=item B<set_lcd_baudrate( $speed )>

This command sets the LCD;s RS-232 port to the specified C<$speed>. The 
change takes place immediately. Valid baud rate are:

 9600
 14400
 19200
 28800
 38400
 57600
 76800
 115200


=item B<set_backlight_on( $minutes )>

This command turns the backlight on after the [minutes] timer has ex- 
pired, with a one-hundred minute maximum timer. A time of 0 specifies 
that the display should turn on immediately and stay on. When this com- 
mand is sent while the remember function is on, the timer will reset and 
begin after power up.


=item B<set_backlight_off()>

This command turns the backlight off immediately. The backlight will 
remain off until a C<set_backlight_on()> command has been received.


=item B<cursor_home()>

This command moves the text insertion point to the top left of the display 
area, based on the current font metrics.


=item B<set_contrast( $contrast )>

This command sets the display's contrast to C<$contrast>, where C<$contrast> 
is a value between 0 to 255. Lower values cause 'on' elements in the display 
area to appear lighter, while higher values cause 'on' elements to appear darker.


=item B<set_and_save_contrast( $contrast )>

Like the C<set_contrast()> method, only this command saves the C<$contrast>
value so that it is not lost after power down.


=item B<set_brightness( $brightness )>

This command sets the backlight brightness according to C<$brightness>.


=item B<set_and_save_brightness( $brightness )>

Like the C<set_brightness()> method, only this command saves the C<$brightness>
value so that it is not lost after power down.


=item B<set_autoscroll_on()>

When auto scrolling is on, it causes the display to shift the entire display's 
contents up to make room for a new line of text when the text reaches 
the end of the scroll row defined in the font metrics (the bottom right 
character position).


=item B<set_autoscroll_off()>

When auto scrolling is disabled, text will wrap to the top left corner of 
the display area when the text reaches the end of the scroll row defined in 
the font metrics (the bottom right character position). Existing text in 
the display area is not erased before new text is placed. A series of spaces 
followed by a C<cursor_home()> command may be used to erase the top line of 
text.


=item B<set_drawing_color( $color )>

This command sets the drawing color for subsequent graphic commands 
that do not have the drawing color passed as a parameter. The parameter 
C<$color> is the value of the color where white is 0 and black is 1-255.


=item B<clear_screen()>

This command clears the display and resets the text insertion position to 
the top left position of the screen defined in the font metrics. 


=item B<draw_bitmap( $refid, $x, $y)>

This command will draw a bitmap that is located in the on board memory. 
The bitmap is referenced by the bitmaps reference identification number, 
which is established when the bitmap is uploaded to the display module. 
The bitmap will be drawn beginning at the top left, from the specified 
X,Y coordinates.


=item B<draw_pixel( $x, $y)>

This command will draw a pixel at C<$x>, C<$y> using the current drawing color.


=item B<draw_line( $x1, $y1, $x2, $y2)>

This command will draw a line from C<$x1>, C<$y1> to C<$x2>, C<$y2> using 
the current drawing color. Lines may be drawn from any part of the display to any 
other part. However, it may be important to note that the line may in- 
terpolate differently right to left, or left to right. This means that a line 
drawn in white from right to left may not fully erase the same line drawn 
in black from left to right. 


=item B<draw_line_continue( $x, $y)>

This command will draw a line with the current drawing color from the 
last line end (x2,y2) to C<$x>, C<$y>. This command uses the global 
drawing color.


=item B<draw_rect( $x1, $y1, $x2, $y2)>

This command draws a rectangular box in the specified color.
The top left corner is specified by C<$x1>, C<$y1> and the bottom right 
corner by C<$x2>, C<$y2>.


=item B<delete_bitmap( $refid )>

This command deletes a single bitmap from the LCD's memory.
The reference number is defined when the file is saved to the LCD.


=item B<delete_font( $refid )>

This command deletes a single font from the LCD's memory.
The reference number is defined when the file is saved to the LCD.


=item B<wipe_filesystem()>

This command completely erases the display's non-volatile memory. It 
removes all fonts, font metrics, bitmaps, and settings (current font, cursor 
position, communication speed, etc.).


=item B<get_filesystem_space()>

This command will return how many bytes are remaining in the 
16 KB on board memory.


=item B<draw_solid_rect( $x1, $y1, $x2, $y2)>

This command draws a solid rectangle in the specified color. 
The top left corner is specified by C<$x1>, C<$y1> and the bottom right 
corner by C<$x2>, C<$y2>. Since this command involves considerable processing 
overhead, we strongly recommend the use of flow control, particularly if 
the command is to be repeated frequently. 


=item B<get_lcd_type()>

Returns the model of the LCD module that you are communicating with
(for example 'GLK24064-25'). 


=item B<($width, $height) = get_lcd_dimensions()>

Returns the dimensions (in pixels) of the LCD screen you are talking to 
as an array, width followed by height.


=item B<get_firmware_version()>

Returns the firmware version of the LCD module that you are communicating with
as a dotted integer (for example '5.4').



=back

=head1 SEE ALSO

Manuals for the GLK and GLC Series of graphic LCD's:

L<http://www.matrixorbital.ca/manuals/GLK_series/>

=head1 AUTHOR

Nicholas J Humfrey, njh@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Nicholas J Humfrey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.005 or,
at your option, any later version of Perl 5 you may have available.

=cut
