use IO::Socket::INET;
use GD;


$screen_width = 50;
$screen_height = 50;


#For the next version load the text into an array not just the hex color.
#Load the lenght of a packet into their own array so I can just push it out.
#When loading the array set it up to have different drawing methods instead of line by line draw.


#$imagefile = "C:/Users/Awol/Pictures/m2018logo.png";
$image = new GD::Image($screen_width, $screen_height,1);
#$image->trueColor(1);

#Create Data Stream Here for the minions to use
#Needs to be an array so we can split that up with the minions. 
@imagedata = ();

$socket = new IO::Socket::INET (
	PeerAddr   => 'maglan-srv-blade05.lan.magfest.net:1234',
	Proto        => 'tcp'
) or die "ERROR in Socket Creation : $!\n";


#Load Image into an 2d Array
for($i=0;$i<$screen_height;$i++)
{
	for($j=0;$j<$screen_width;$j++)
	{
		$data = "PX $j $i\n";
		$socket->send($data);
		#Get the data
		$socket->recv($text,64);		
		chomp($text);
		$color = (split(" ",$text))[3];
		print "$text,";
		($r,$g,$b) = map $_, unpack 'C*', pack 'H*', $color;
		$image->setPixel($i,$j,$image->colorAllocate($r, $g, $b));
	}
}


$png_data = $image->png;
open (DISPLAY,">pixelflut.png") || die;
binmode DISPLAY;
print DISPLAY $png_data;
close DISPLAY;

undef($image);
exit;
