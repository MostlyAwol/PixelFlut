use IO::Socket::INET;
use Imager;
use Imager::Screenshot 'screenshot';


$server = $ARGV[0];
$server = "localhost:8080" if (!defined($server));
$server = "192.168.1.144:1234";


$monitor = $ARGV[1];
$monitor = 0 if (!defined($monitor));

$output_size = $ARGV[2];
$output_size = 1280 if (!defined($output_size));


#Grab Screenshot of Monitor 0 and use to compute final sizes for the children processes
$image = screenshot(monitor=>$monitor);
$width  = $image->getwidth();
$height = $image->getheight();
$scale = $output_size / $image->getwidth();

$image = $image->scale(scalefactor => $scale);
$scale_width  = $image->getwidth();
$scale_height = $image->getheight();


print "Screensize $width x $height of $monitor scale to $output_size\n";

#Take the width and heigth and divide by 3 as we will have 9 children running
$x_size = int($width / 3);
$y_size = int($height / 3);

$scale_x_size = int($scale_width / 3);
$scale_y_size = int($scale_height / 3);


$num_children = 9;

STARTFORK:
undef($image);
$child_number = 0;
undef($children);

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
	print "Master awaiting Commands 123\n";
	while(1)
	{
		$cmd=<STDIN>;
		chomp($cmd);
		@cmdline = split(/ /,$cmd);
		if ($cmdline[0] eq "quit")
		{
			KillMinions();
			exit;
		}
	}
}

#######################################################################################
sub StartMinion
{
	#  We call IO::Socket::INET->new() to create the TCP Socket 
	# flush after every write
	$| = 1;
	my ($socket,$data);

	$start_x = 0;
	$start_y = 0;
	
	if ($child_number >= 0 && $child_number <= 2)
	{
		$start_y = 0;
		$scale_start_y = 0;
	}
	if ($child_number >= 3 && $child_number <= 5)
	{
		$start_y = $y_size;
		$scale_start_y = $scale_y_size;
	}
	if ($child_number >= 6 && $child_number <= 8)
	{
		$start_y = 2 * $y_size;
		$scale_start_y = 2 * $scale_y_size;
	}
	
	if ($child_number == 0 || $child_number == 3 || $child_number == 6)
	{
		$start_x = 0;
		$scale_start_x = 0;
	}
	if ($child_number == 1 || $child_number == 4 || $child_number == 7)
	{
		$start_x = $x_size;
		$scale_start_x = $scale_x_size;
	}
	if ($child_number == 2 || $child_number == 5 || $child_number == 8)
	{
		$start_x = 2 * $x_size;
		$scale_start_x = 2 * $scale_x_size;
	}
	
	print "Minion $child_number Running - $start_x, $start_y x $x_size, $y_size\n";

	$socket = new IO::Socket::INET (
		PeerAddr   => $server,
		Proto        => 'tcp'
	) or die "ERROR in Socket Creation : $!\n";

	while(1)
	{
#		print "1 - Getting Screenshot\n";
		$image = screenshot(monitor=>$monitor, top => $start_y, left=> $start_x, right=> $start_x + $x_size, bottom=> $start_y + $y_size);
#		print "2 - Scaling\n";
		$image = $image->scale(scalefactor => $scale);
		#$filename = "test-". time() .".png";
		#$image->write(file=>$filename, type=>$type);
		#Create Data Stream Here for the minions to use
		#Needs to be an array so we can split that up with the minions. 
#		print "3 - Converting\n";
		$data = "";
		for (my $y=0;$y < $y_size;$y=$y+2) 
		{
			@colors = $image->getscanline(y=>$y,type=>'8bit');
			$x = 0;
			#I want to do this in a random order I have a line of pixels in an array already.
			#Replace the code below to get this done.
			#Maybe Interlace it?
			for my $color (@colors)
			{
#				$pixel = int(rand(@colors));
#				$hex = rgbToHex($colors[$pixel]->rgba());
#				$new_x = $scale_start_x + $pixel;
#				$new_y = $y + $scale_start_y;
#				$txt = "PX $new_x $new_y $hex\n";
#				#print $txt if ($child_number == 1);
#				$data = $data . $txt;
#				$x++;

				$hex = rgbToHex($color->rgba());
				$new_x = $x + $scale_start_x;
				$new_y = $y + $scale_start_y;
				$txt = "PX $new_x $new_y $hex\n";
				#print $txt if ($child_number == 1);
				$data = $data . $txt;
				$x++;

			}
			if ($y % 2 == 0 && $y+2 >= $y_size)
			{
				$y = 1;
			}
		}
		#print "4 - Sending... ". length($data) ." \n";
		#print "====================================\n";
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
    $red=$_[0];
    $green=$_[1];
    $blue=$_[2];
	return (sprintf("%2.2X%2.2X%2.2X",$red,$green,$blue));
}