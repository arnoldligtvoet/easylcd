#!/usr/bin/perl
use Mail::POP3Client;

#########################################################################
# set General variables							#
$theName = "EasyLCD";                        # Application name         #
$theVersion = "0.03";                        # Application version      #
$theUrl = "easylcd.ligtvoet.org";            # Application url          #
$thePort = "/dev/ttyS2";		     # Set serial port		#
$theSpeed = "9600";			     # Set speed of serial int. #
$theParams = "parodd parenb";		     # Comm parameters 		#
#########################################################################

#########################################################################
# set POP3 variables							#
$user = "username";			     # POP3 username            #	
$pass = "password";			     # POP3 password		#
$server = "localhost";			     # POP3 server		#
#########################################################################

#########################################################################
# Catch system interaction						#
$SIG{INT} = \&close_app;						#
$SIG{QUIT} = \&close_app;						#
$SIG{KILL} = \&close_app;						#
$SIG{HUP} = \&close_app;						#	
$SIG{TERM} = \&close_app;						#
#########################################################################

#########################################################################
# Start the application -> No editing should be needed			#
# set port to correct values						#
system("/bin/stty -F ".$thePort." ".$theParams." ".$theSpeed);		#
# open port								#
open(VFD,">>".$thePort) || die "$! \n";					#	
# flush data written to the port					#
VFD->autoflush(1);							#
# clear diplay								#	
display_clear();							#
# print proginformation							#
print VFD chr(0x1B) . chr(0x5B) . "1" . chr(0x3B) . "1" . chr(0x48);	#
print VFD "* " . $theName . "  -  " . $theVersion . " *"; 		#
print VFD chr(0x1B) . chr(0x5B) . "2" . chr(0x3B) . "1" . chr(0x48);	#
print VFD $theUrl;							#
# wait 3 seconds 							#
sleep 3;								#
# clear diplay								#
display_clear();							#
#########################################################################

#########################################################################
# This is the display loop, add functions here that should be shown     #
while() {
  # count loops
  $c = $c+1;

  # catch system interaction
  $SIG{INT} = \&close_app;
  $SIG{QUIT} = \&close_app;
  $SIG{KILL} = \&close_app;
  $SIG{HUP} = \&close_app;
  $SIG{TERM} = \&close_app;


  # Add functions from here	
  popchecker($user,$pass,$server,"1","1");
  display_text_val("C:".$c,"1","15");
  
  sleep 1;


  scroll_text_val("dit is een test","2","20","0.10");
  sleep 1;

  $np = now_playing();
  scroll_text_val($np,"2","20","0.10");
  sleep 3;

}
#########################################################################

#########################################################################
# BELOW THIS LINE ALL DISPLAY FUNCTIONS ARE DEFINED			#
#########################################################################

sub popchecker {
  #######################################################################
  # Check a POP3 mailbox and display the number of new messages       	#   
  #######################################################################
  my $usert = shift;
  my $passt = shift;
  my $servert = shift;
  my $line = shift;
  my $ char = shift;


  $pop = new Mail::POP3Client( USER     => $usert,
                             PASSWORD => $passt,
                             HOST     => $servert ); 
  $count = $pop->Count();

  # move to first line
  print VFD chr(0x1B) . chr(0x5B) . $line . chr(0x3B) . $char . chr(0x48);
  print VFD "New mail:" . $count . "   ";
}

sub imapchecker {

#######################################################################
# Check an IMAP mailbox and display the number of new messages
#
#
#######################################################################
  my $usert = shift;
  my $passt = shift;
  my $servert = shift;
  my $line = shift;
  my $char = shift;


  #$imap = new Mail::IMAPClient( USER     => $usert,
  #                           PASSWORD => $passt,
  #                           HOST     => $servert );

  $imap = Mail::IMAPClient->new(
                        Server => $servert,
                        User    => $usert,
                        Password=> $passt,
                        Clear   => 5,   # Unnecessary since '5' is the default
        #               ...             # Other key=>value pairs go here
        )       or die "Cannot connect to $host as $id: $@";

  my $unreadCount = $imap->unseen_count("INBOX");
  my $totalCount = $imap->message_count("INBOX");

  # move to first line
  print VFD chr(0x1B) . chr(0x5B) . $line . chr(0x3B) . $char . chr(0x48);
  print VFD "Unread: " . $unreadCount . "/" . $totalCount;
}

sub display_text_val {
  #######################################################################
  # Display fixed text (string) 					#
  #######################################################################
  my $value = shift;
  my $line = shift;
  my $char = shift;
  print VFD chr(0x1B) . chr(0x5B) . $line . chr(0x3B) . $char . chr(0x48);  print VFD $value;
}

sub blink_text_val {
  #######################################################################
  # NOT FINISHED -> should blink text					#
  #######################################################################
  my $value = shift;
  my $line = shift;
  my $char = shift;
  my $times = shift;
  my $pause = shift;
  
  $t=0;
  $s=$char;


  while ($t<$times) {
	print VFD chr(0x1B) . chr(0x5B) . $line . chr(0x3B) . $char . chr(0x48);
	print VFD $value;
	select(undef, undef, undef, $pause);
	
	
	while ($s<21) {
		 print VFD chr(0x1B) . chr(0x5B) . $line . chr(0x3B) . $s . chr(0x48);
		print VFD " ";
		$s++;
	}
  	$t++;
  }
}

sub scroll_text_val {
  #######################################################################
  # Scrolls the given text through the display at the specfied line     #
  #######################################################################
  my $value = shift;
  my $line = shift;
  my $char = shift;
  my $pause = shift;

  display_clear;
  
  $count = 0 - length($value);
  $t = $char;
  $s = 1;  


  while($t>$count) {
        if ($t < 1) {
	  print VFD chr(0x1B) . chr(0x5B) . $line . chr(0x3B) . "1" . chr(0x48);
          print VFD substr($value,1-$t)."                    ";
 	} else {
	  print VFD chr(0x1B) . chr(0x5B) . $line . chr(0x3B) . $t . chr(0x48);
	  print VFD substr($value,0,$s)."                    ";
    	}
	select(undef, undef, undef, $pause);
 	$t--;
	$s++;	
   }
}

sub now_playing {
  #######################################################################
  # This function assumes a text file at the give location.             #
  # This text file should give a first line artist - title              #
  # This data is then parsed and displayed                              #
  # Tested with : Currently Playing to Textfile v0.4 and Winamp					#
  #######################################################################

  $text_file = "/var/www/html/winamp/winamp.txt";
  open(FILE, $text_file) or die("Can't open file ".$text_file);

  while ($line = <FILE>) {
        #chop ($line) if ($line =~ /\n$/);
        $name1 = <FILE>;
        chomp $name;
        $line2 = $line
 }

  @title = split("-",$line2); 
  $artist = $title[0];
  $artist =~ s/[^[:print:]]+//g;
  $title = $title[1];
  $title =~ s/[^[:print:]]+//g;
  if ($artist eq "<Winamp Is Not Running>") {
	$user_data = "Winamp is not running .....";
  } else {
  	$user_data = "Now playing " . $artist . " - $title .....";
  }
  $user_data =~ s/[^[:print:]]+//g; 
  return $user_data;
}

sub display_clear {
  #######################################################################
  # clears the display							#
  #######################################################################
  print VFD chr(0x1B) . chr(0x5B) . "2" . chr(0x4A);
}


sub close_app {
  #######################################################################
  # close application nicely						#
  #######################################################################
  print VFD chr(0x1B) . chr(0x5B) . "2" . chr(0x4A);
  print VFD chr(0x1B) . chr(0x5B) . "1" . chr(0x3B) . "1" . chr(0x48);
  print VFD "*     bye bye      *";
  close(VFD);
  die "Quit received. Closing port";
}

