use IO::Socket::INET;
use GD;


#For the next version load the text into an array not just the hex color.
#Load the lenght of a packet into their own array so I can just push it out.
#When loading the array set it up to have different drawing methods instead of line by line draw.


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
$start_x = 0 if (!defined($start_x));

$start_y = $ARGV[2];
$start_y = 0 if (!defined($start_y));

$num_children = $ARGV[3];
$num_children = 9 if (!defined($num_children));


$screen_width = 1024;
$screen_height = 768;

#Create Data Stream Here for the minions to use
#Needs to be an array so we can split that up with the minions. 
@pixelflut = ();

#Load Image into an 2d Array
for($i=0;$i<$image->width;$i++)
{
	for($j=0;$j<$image->height;$j++)
	{
		$index = $image->getPixel($i,$j);
		@rgb = $image->rgb($index);
		$hex = rgbToHex(@rgb);
		$hex = 0 if ($hex eq "00");
		if (($img_type eq "PNG" && $index >= 1<<24))
		{
			#Do nothing
		}
		else
		{
			push(@pixelflut,"PX $i $j $hex\n");
		}
	}
}

undef($image);

STARTFORK:
#Fork Here and have the children render their own parts.
$child_number = 0;
undef($children);

#############################################################


$px = 0;
$py = 0;
$run = 1;
while($child_number < $num_children)
{
	$pid = fork();
	if ($pid == 0)
	{
		#print "$child_number I will take every $child_number pixel\n";
		StartMinion();
		last;
	}
	else
	{
		$children[$child_number] = $pid;
	}
	$child_number++;
}


#############################################################

#If I am the parent I need to do something else.
if ($pid != 0)
{
	print "Master awaiting Commands\n";
	while(1)
	{
		$cmd=<STDIN>;
		chomp($cmd);
		@cmdline = split(/ /,$cmd);
		
		#print "You typed $cmd\n";
		
		if ($cmdline[0] eq "quit")
		{
			KillMinions();
			exit;
		}
		if ($cmdline[0] eq "move")
		{
			print "moving!\n";
			$start_x = $cmdline[1];
			$start_y = $cmdline[2];
			KillMinions();
			goto STARTFORK;
		}
	}
}

sub StartMinion
{
	#  We call IO::Socket::INET->new() to create the TCP Socket 
	# flush after every write
	#$| = 1;
	my ($socket,$data);
	print "Minion $child_number Running\n";

	if ($start_x != 0 && $start_y != 0)
	{
		$data = "OFFSET $start_x $start_y\n";
	}
	
	$start = 0;
	$end = 0;
	
	$size = int(@pixelflut / $num_children) + 1;
	#print "Total Size = $size\n";

	$start = int((@pixelflut / $num_children) * $child_number); 
	$end = $start + $size;
	#print "Start ($start) - End ($end)\n";
	#send operation
	for($i=$start;$i<=$end;$i++)
	{
		$data = $data . $pixelflut[$i];
	}

	
	
	$socket = new IO::Socket::INET (
		PeerAddr   => 'localhost:8080',
		Proto        => 'tcp'
	) or die "ERROR in Socket Creation : $!\n";
	while(1)
	{
		$socket->send($data);
	}
}

sub KillMinions
{
	for($k=0;$k<$num_children;$k++)
	{
		kill(9,$children[$k]);
	}
}

sub rgbToHex {
#    $red=$_[0];
#    $green=$_[1];
#    $blue=$_[2];
#    return sprintf("%X%X%X",$red,$green,$blue);

    $red=$_[0];
    $green=$_[1];
    $blue=$_[2];
    
	$hex_red = sprintf("%2.2X",$red);
	$hex_green = sprintf("%2.2X",$green);
	$hex_blue = sprintf("%2.2X",$blue);

	#if ($hex_red == $hex_green && $hex_green == $hex_blue)
	#{
	#	return $hex_red;
	#}
	
	#if ($hex_green eq "00")
	#{
	#	$hex_green = "";
	#}
	return ($hex_red . $hex_green . $hex_blue);
}