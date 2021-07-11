use IO::Socket::INET;
use GD;


#For the next version load the text into an array not just the hex color.
#Load the lenght of a packet into their own array so I can just push it out.
#When loading the array set it up to have different drawing methods instead of line by line draw.


#$imagefile = "C:/Users/Awol/Pictures/m2018logo.png";

$num_children = $ARGV[0];
$num_children = 9 if (!defined($num_children));

$screen_width = 1024;
$screen_height = 768;

#Load Image into an 2d Array
for($i=0;$i<$screen_width;$i++)
{
	for($j=0;$j<$screen_height;$j++)
	{
		$img[$i][$j] = "0";
	}
}

$img_width = $screen_width;
$img_height = $screen_height;

print "Image Size = $img_width x $img_height\n";

$section_size_x = int($img_width / sqrt($num_children));
$section_size_y = int($img_height / sqrt($num_children));

print "X = $section_size_x\n";
print "Y = $section_size_y\n";




undef($image);

$child_number = 0;


STARTFORK:
#Fork Here and have the children render their own parts.
$start = "";
$end = "";
$start_height = 0;
$end_height = 0;
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
		$start = $section_size_x * $px;
		$end = $section_size_x * ($px + 1);

		$start_height = $section_size_y * $py;
		$end_height = $section_size_y * ($py + 1);
		
		print "$child_number) I will take rows $start x $end TO $start_height x $end_height\n";
		StartMinion();
		last;
	}
	else
	{
		$children[$child_number] = $pid;
	}
	
	$px++;
	if ($px >= (sqrt($num_children)))
	{
		$px = 0;
		$py++;
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
	$socket = new IO::Socket::INET (
	PeerAddr   => 'maglan-srv-blade05.lan.magfest.net:1234',
	Proto        => 'tcp'
	) or die "ERROR in Socket Creation : $!\n";
	#send operation
	for($i=$start;$i<$end;$i++)
	{
		for($j=$start_height;$j<$end_height;$j++)
		{
			$new_x = $start_x + $i;
			$new_y = $start_y + $j;
			$hex = $img[$i][$j];
			$data = $data . "PX $new_x $new_y $hex\n" if ($hex ne "tran");
		}
	}

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

	if ($hex_green eq "0")
	{
		$hex_green = "";
	}
	return ($hex_red . $hex_green . $hex_blue);
}