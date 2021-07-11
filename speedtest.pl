use IO::Socket::INET;
#use GD;
use Imager;
use Imager::Screenshot 'screenshot';
use Time::HiRes qw( time );

my $start = time();
#For the next version load the text into an array not just the hex color.
#Load the lenght of a packet into their own array so I can just push it out.
#When loading the array set it up to have different drawing methods instead of line by line draw.

#$imagefile = "C:/Users/Awol/Pictures/m2018logo.png";
#$imagefile = $ARGV[0];

#$image = GD::Image->new($imagefile);

#my $image = Imager->new;
#$image->read(file => $imagefile);

$image = screenshot(monitor=>0);
$image = $image->scale(xpixels=>1024);
#Create Data Stream Here for the minions to use
#Needs to be an array so we can split that up with the minions. 
@pixelflut = ();

for my $y (0..$image->getheight-1) 
{
	@colors = $image->getscanline(y=>$y,type=>'8bit');
	$x = 0;
	for my $color (@colors)
	{
		$hex = rgbToHex($color->rgba());
		push(@pixelflut,"PX $x $y $hex\n");
		$x++;
	}
}

#This uses the GD library
#Load Image into an 2d Array
#for($i=0;$i<$image->getwidth();$i++)
#{
#	for($j=0;$j<$image->getheight();$j++)
#	{
#		@rgb = $image->rgb($image->getPixel($i,$j));
#		$hex = rgbToHex($image->rgb($image->getPixel($i,$j)));
#		push(@pixelflut,"PX $i $j $hex\n");
#	}
#}


my $end = time();

print "Time took to convert image: ";
printf("%.2f\n", $end - $start);
print "Image Size = ". $image->getwidth() .",". $image->getheight() ."\n";
#print @pixelflut;
undef($image);



sub rgbToHex {
    $red=$_[0];
    $green=$_[1];
    $blue=$_[2];
	return (sprintf("%2.2X%2.2X%2.2X\n",$red,$green,$blue));
}