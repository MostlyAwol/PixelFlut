#!perl

sub rgbToHex {
    $red=$_[0];
    $green=$_[1];
    $blue=$_[2];
    
	$hex_red = sprintf("%2.2X",$red);
	$hex_green = sprintf("%2.2X",$green);
	$hex_blue = sprintf("%2.2X",$blue);

	
	return ($hex_red . $hex_green . $hex_blue);
}

print rgbToHex(0,0,0). "\n";