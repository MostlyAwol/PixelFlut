use IO::Socket::INET;
use GD;

#$imagefile = "C:/Users/Awol/Pictures/m2018logo.png";
$imagefile = $ARGV[0];

if (substr($imagefile,-4) eq ".png")
{
	$image = GD::Image->newFromPng($imagefile, 1);
	$img_type = "PNG";
}
else
{
	$image = GD::Image->new($imagefile);
	$img_type = "OTHER";
}

$start_x = $ARGV[1];
$start_y = $ARGV[2];
$random = $ARGV[3];
$loop = $ARGV[4];

# flush after every write
$| = 1;

my ($socket,$data);

#  We call IO::Socket::INET->new() to create the UDP Socket 
# and bind with the PeerAddr.
$socket = new IO::Socket::INET (
PeerAddr   => '192.168.13.128:8080',
Proto        => 'tcp'
) or die "ERROR in Socket Creation : $!\n";
#send operation

while(1)
{
	if ($random == 1)
	{
		$start_x = int(rand(1280));
		$start_y = int(rand(720));
	}
	for($i=0;$i<$image->width;$i++)
	{
		for($j=0;$j<$image->height;$j++)
		{
			$new_x = $start_x + $i;
			$new_y = $start_y + $j;
			
			$index = $image->getPixel($i,$j);
			
			if ($img_type eq "PNG" && $index >= 1<<24)
			{
				#The pixel is transparent
				next;
			}
			if ($img_type eq "OTHER" && $index == 206)
			{
				next;
			}
			
			@rgb = $image->rgb($index);
			$hex = rgbToHex(@rgb);

			$data = $data . "PX $new_x $new_y $hex\n";
		}
		$socket->send($data);
		undef($data);
	}
	exit unless($loop eq "loop");
}
$socket->close();


sub rgbToHex {
    $red=$_[0];
    $green=$_[1];
    $blue=$_[2];
    return sprintf("%2.2X%2.2X%2.2X",$red,$green,$blue);
}