use IO::Socket::INET;

# flush after every write
$| = 1;

my ($socket,$data);

$x = 1280;
$y = 720;

#  We call IO::Socket::INET->new() to create the UDP Socket 
# and bind with the PeerAddr.
$socket = new IO::Socket::INET (
PeerAddr   => '192.168.1.144:1234',
Proto        => 'tcp'
) or die "ERROR in Socket Creation : $!\n";
#send operation
#for($f=0;$f<20;$f++)
#{
#	$pid = fork();
#	last if ($pid == 0);
#}

$red = 0;
$green = 0;
$blue = 0;

$size = 50;

$count = 0;
while(1)
{
	undef($data);
	$new_x2 = int(rand($x));
	$new_y2 = int(rand($y));
	
	$frequency = 0.1;
	$red1   = sin($frequency*$count + 0) * 127 + 128;
	$green1 = sin($frequency*$count + 2) * 127 + 128;
	$blue1  = sin($frequency*$count + 4) * 127 + 128;
	$count++;
	for ($i=0;$i<$size;$i++)
	{
		for ($j=0;$j<$size;$j++)
		{
			$new_x = $new_x2 + $i;
			$new_y = $new_y2 + $j;
			@rgb = ($red1,$green1,$blue1);
			$hex = rgbToHex(@rgb);
			$data = $data . "PX $new_x $new_y $hex\n";
		}
		$socket->send($data);
	}
}
$socket->close();

sub rgbToHex {
    $red=$_[0];
    $green=$_[1];
    $blue=$_[2];
    #printf ("%2.2X%2.2X%2.2X\n",$red,$green,$blue);
    return sprintf("%2.2X%2.2X%2.2X",$red,$green,$blue);
}