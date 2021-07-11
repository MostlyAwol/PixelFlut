use IO::Socket::INET;
use GD;
use POSIX;

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

$screen_width = 1280;
$screen_height = 720;

#Load Image into an 2d Array
for($i=0;$i<$image->width;$i++)
{
	for($j=0;$j<$image->height;$j++)
	{
		$index = $image->getPixel($i,$j);
		@rgb = $image->rgb($index);
		$hex = rgbToHex(@rgb);
		if (($img_type eq "PNG" && $index >= 1<<24))
		{
			$img[$i][$j] = "tran";
		}
		else
		{
			$img[$i][$j] = $hex;
		}
	}
}

$img_width = $image->width;
$img_height = $image->height;

print "Image Size = $img_width x $img_height\n";
undef($image);

print "Creating Protocal String\n";
$data = "";

for($i=0;$i<$img_width;$i++)
{
	for($j=0;$j<$img_height;$j++)
	{
		$new_x = $start_x + $j;
		$new_y = $start_y + $i;
		$hex = $img[$j][$i];
		$data = $data . "PX $new_x $new_y $hex\n" if ($hex ne "tran");
	}
}
print "Done Creating String\n";
$temp = length($data);
print "$temp\n";
$data_parts = ceil($temp / 1400);
print "$data_parts will be created\n";
#Split the $data string into TCP packet size chucks
$slice = ceil($data_parts / 9);

@parts = "";
for($i=0;$i<$data_parts;$i++)
{
	$start_str = $i * 1400;
	$parts[$i] = substr($data,$start_str,1400);
	#print "$i - " .length($parts[$i]). "\n";
}



STARTFORK:
#Fork Here and have the children render their own parts.
$child_number = 0;
@children = "";

#############################################################


$run = 1;

for ($i=0;$i<$data_parts;$i++)
{
	$stuff_2_send = $stuff_2_send . $parts[$i];

	if (($i % $slice) == 0)
	{
		$pid = fork();
		if ($pid == 0)
		{
			print "$child_number) I will take rows ". length($stuff_2_send) ."\n";
			StartMinion($stuff_2_send);
			last;
		}
		else
		{
			$children[$child_number] = $pid;
			$stuff_2_send = "";
			$child_number++;
		}
	}
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
	my $data2send = shift(@_);
	#$| = 1;
	my ($socket);

	print "Minion $child_number Running\n";
	$socket = new IO::Socket::INET (PeerAddr => 'maglan-srv-blade05.lan.magfest.net:1234', Proto => 'tcp') or die "ERROR in Socket Creation : $!\n";
	#send operation
	#Create an string of the protocal and save.
	while(1)
	{
		$socket->send($data2send);
	}
}

sub KillMinions
{
	for($k=0;$k<@children;$k++)
	{
		kill(9,$children[$k]);
	}
}

sub rgbToHex {
    $red=$_[0];
    $green=$_[1];
    $blue=$_[2];
    return sprintf("%2.2X%2.2X%2.2X",$red,$green,$blue);
}