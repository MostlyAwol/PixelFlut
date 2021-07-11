use IO::Socket::INET;
use Imager;
use Time::HiRes qw(gettimeofday);
use Data::Dumper;

#For the next version load the text into an array not just the hex color.
#Load the lenght of a packet into their own array so I can just push it out.
#When loading the array set it up to have different drawing methods instead of line by line draw.


#$imagefile = "C:/Users/Awol/Pictures/m2018logo.png";
$imagefile = $ARGV[0];

$server = "192.168.1.144:1234";

#$image = Imager->new;

if (substr($imagefile,-4) eq ".gif")
{
	@imgs = Imager->read_multi(file=>$imagefile, type=>'gif') or die "Cannot read: ", Imager->errstr;
	$img_type = "GIF";
}
else
{
	print "Not a GIF use another code branch\n";
	exit;
}

$start_x = $ARGV[1];
$start_x = 0 if (!defined($start_x));

$start_y = $ARGV[2];
$start_y = 0 if (!defined($start_y));

$num_children = $ARGV[3];
$num_children = 9 if (!defined($num_children));

$screen_width = 1024;
$screen_height = 768;


$num_frames = @imgs;
print "GIF has $num_frames Frames\n";

#Create Data Stream Here for the minions to use
#Needs to be an array so we can split that up with the minions. 
#If PNG only needs a single array to hold data.
#If GIF and more than 1 frame needs 2d array


@pixelflut = ();
#Load image into 2DArray
$count = 0;
for ($frame=0;$frame < $num_frames;$frame++)
{
	$count = 0;
	for($i=0;$i<$imgs[$frame]->getwidth();$i++)
	{
		for($j=0;$j<$imgs[$frame]->getheight();$j++)
		{
			$index = $imgs[$frame]->getpixel(x=>$i,y=>$j);
			@rgb = $index->rgba();
			$hex = rgbToHex(@rgb);
			next if ($hex eq "TRANS");
			$pixelflut[$frame] = $pixelflut[$frame] . "PX $i $j $hex\n";
			$count++;
		}
	}
}

undef(@imgs);

#############################################################
#############################################################
#  We call IO::Socket::INET->new() to create the TCP Socket 
# flush after every write
#$| = 1;
print "Starting to draw\n";
$socket = new IO::Socket::INET (
	PeerAddr   => $server,
	Proto        => 'tcp'
) or die "ERROR in Socket Creation : $!\n";
$frame = 0;
while(1)
{
	
	if ($frame < $num_frames)
	{
		$socket->send($pixelflut[$frame]);
		$frame++;
	}
	else
	{
		$frame = 0;
	}
}

sub rgbToHex {
#    $red=$_[0];
#    $green=$_[1];
#    $blue=$_[2];
#    return sprintf("%X%X%X",$red,$green,$blue);

	$alpha=$_[3];
	if ($alpha == 0)
	{
		return "TRANS";
	}
    $red=$_[0];
    $green=$_[1];
    $blue=$_[2];
	#return (sprintf("%2.2X%2.2X%2.2X",$red,$green,$blue));
	return (sprintf("%2.2X",$green));
}