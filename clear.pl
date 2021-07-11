use IO::Socket::INET;

# flush after every write
$| = 1;

my ($socket,$data);

$x = 1280;
$y = 800;

#  We call IO::Socket::INET->new() to create the UDP Socket 
# and bind with the PeerAddr.
$socket = new IO::Socket::INET (
PeerAddr   => '192.168.1.144:1234',
Proto        => 'tcp'
) or die "ERROR in Socket Creation : $!\n";
#send operation
$data = "";
for($i=0;$i<$y;$i++)
{
	for($j=0;$j<$x;$j++)
	{
		$new_y = $i;
		$new_x = $j;
		$hex = "0";
		$data = $data . "PX $new_x $new_y $hex\n";
	}
}

while(1)
{
	$socket->send($data);
}

$socket->close();

sub rgbToHex {
    $red=$_[0];
    $green=$_[1];
    $blue=$_[2];
    #printf ("%2.2X%2.2X%2.2X\n",$red,$green,$blue);
    #return sprintf("%X%X%X",$red,$green,$blue);
	return "ffffff";
}