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

for ($i=0;$i<$num_frames;$i++)
{
	print "Image Size = ".$imgs[$i]->getwidth()." x ".$imgs[$i]->getheight()."\n";
}


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
			$hex = 0 if ($hex eq "00");
			$pixelflut[$frame][$count] = "PX $i $j $hex\n";
			$count++;
		}
	}
}

undef(@imgs);


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

	
	$start = 0;
	$end = 0;
	
	$size = int(@{$pixelflut[0]} / $num_children) + 1;
	$start = int((@{$pixelflut[0]} / $num_children) * $child_number); 
	$end = $start + $size;
	for ($frame=0;$frame<$num_frames;$frame++)
	{
		#$data[$frame] = "OFFSET $start_x, $start_y\n";
		for($i=$start;$i<=$end;$i++)
		{
			$data[$frame] = $data[$frame] . $pixelflut[$frame][$i];
		}
	}
	
	$socket = new IO::Socket::INET (
		PeerAddr   => $server,
		Proto        => 'tcp'
	) or die "ERROR in Socket Creation : $!\n";
	while(1)
	{
		($sec, $ms) = gettimeofday(); 
		#$ms = time(); 
		#print "MS = $ms - ";
		$ms = int($ms / 20000);
		#print "NEW MS = $ms\n";
		#Timing on MOD of frame each second works
		#Need a way to time thats less than 1 second in lenght and that will sync up.
		#Tried millisecond but was out of sync...
		$cur_frame = $ms % $num_frames;
		$socket->send($data[$cur_frame]);
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

	$alpha=$_[3];
	if ($alpha == 0)
	{
		return "TRANS";
	}
    $red=$_[0];
    $green=$_[1];
    $blue=$_[2];
	return (sprintf("%2.2X%2.2X%2.2X",$red,$green,$blue));
}