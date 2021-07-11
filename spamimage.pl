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
$threads = $ARGV[5];

$screen_width = 1024;
$screen_height = 768;


#  We call IO::Socket::INET->new() to create the UDP Socket 
# and bind with the PeerAddr.
for($f=0;$f<$threads;$f++)
{
	$pid = fork();
	if ($pid == 0)
	{
		print "$f ($pid) Minion Started!\n";
		last;
	}
}

# flush after every write
$| = 1;
my ($socket,$data);

$socket = new IO::Socket::INET (
PeerAddr   => 'maglan-srv-blade05.lan.magfest.net:1234',
Proto        => 'tcp'
) or die "ERROR in Socket Creation : $!\n";
#send operation

#Fork here
#Check if I'm parent or child
#if child do not fork
while(1)
{
	undef($imagedraw);
	$imagedraw = GD::Image->new($image->width,$image->height,1);
	$trans = $imagedraw->colorAllocate(0,55,0);
	$imagedraw->filledRectangle(0,0,$image->width,$image->height,$trans);
	
	if ($random == 1)
	{
		$start_x = int(rand($screen_width + ($image->width * 2)));
		$start_y = int(rand($screen_height + ($image->height * 2)));
		$imagedraw->copyRotated($image,$image->width/2,$image->height/2,0,0,$image->width,$image->height,int(rand(360)));
	}
	else
	{
		$imagedraw->copyRotated($image,$image->width/2,$image->height/2,0,0,$image->width,$image->height,0);
	}
	
	
	for($i=0;$i<$imagedraw->width;$i++)
	{
		for($j=0;$j<$imagedraw->height;$j++)
		{
			$new_x = $start_x + $i;
			$new_y = $start_y + $j;
			
			$index = $imagedraw->getPixel($i,$j);
			
			if (($img_type eq "PNG" && $index >= 1<<24) || ($index == $trans))
			{
				#The pixel is transparent
				next;
			}
			if ($img_type eq "OTHER" && $index == 206)
			{
				next;
			}
			
			@rgb = $imagedraw->rgb($index);
			$hex = rgbToHex(@rgb);

			$data = $data . "PX $new_x $new_y $hex\n";
		}
		$socket->send($data);
		undef($data);
	}
	exit unless ($loop eq "loop");
}
$socket->close();


sub rgbToHex {
    $red=$_[0];
    $green=$_[1];
    $blue=$_[2];
    return sprintf("%2.2X%2.2X%2.2X",$red,$green,$blue);
}