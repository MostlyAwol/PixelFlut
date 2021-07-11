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

$imagedraw = GD::Image->new($image->width,$image->height,1);
#$imagedraw->trueColor(1);


$start_x = $ARGV[1];
$start_y = $ARGV[2];
$random = $ARGV[3];
$direction = $ARGV[4];

# flush after every write
$| = 1;

my ($socket,$data);

#  We call IO::Socket::INET->new() to create the UDP Socket 
# and bind with the PeerAddr.
$socket = new IO::Socket::INET (
PeerAddr   => '10.13.38.175:8080',
Proto        => 'tcp'
) or die "ERROR in Socket Creation : $!\n";
#send operation

while(1)
{
	if ($direction eq "left")
	{
		$start_x = $start_x - 2;
		$start_x = 1400 if ($start_x <= -200);
	}
	if ($direction eq "right")
	{
		$start_x = $start_x + 2;
		$start_x = -200 if ($start_x >= 1400);
	}
	if ($direction eq "down")
	{
		$start_y = $start_y + 2;
		$start_y = -200 if ($start_y >= 1000);
	}
	if ($direction eq "up")
	{
		$start_y = $start_y - 2;
		$start_y = 1000 if ($start_y <= -200);
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
}
$socket->close();


sub rgbToHex {
    $red=$_[0];
    $green=$_[1];
    $blue=$_[2];
    return sprintf("%2.2X%2.2X%2.2X",$red,$green,$blue);
}