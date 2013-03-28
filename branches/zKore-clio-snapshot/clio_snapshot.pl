use Time::HiRes qw(time usleep);
use Win32::API;
use IO::Socket;
use Digest::MD5 qw(md5 md5_hex);
use Getopt::Long;
use HTTP::Lite;
use Time::Local;
$SIG{"HUP"} = \&quit;
$SIG{"INT"} = \&quit;

srand(time());

$versionText =  "***Kore 0.93.191 - Ragnarok Online Bot - http://kore.sourceforge.net***\n";
$versionText .= " ***Clio stable release 6 - Mod by Karasu - Last Updated 2004/05/25***\n";
print $versionText;
$checksum = md5_hex($versionText);

# Parse arguments
GetOptions('control=s', \$path{'control'}, 'logs=s', \$path{'logs'}, 'tables=s', \$path{'tables'}, 'help', \$help);
if ($help) {
	print <<__USAGE__;
Usage: $0 [options...]

The supported options are:

	--help				Displays this help message.
	--control=path			Which directory to use as "control".
	--logs=path			Which directory to use as "logs".
	--tables=path			Which directory to use as "tables".
__USAGE__

	exit();
} elsif (scalar(@ARGV) > 0) {
	parseArgv(@ARGV);
} else {
	undef $ai_v{'temp'}{'found'};
	foreach (keys %path) {
		$ai_v{'temp'}{'found'}++ if ($path{$_} ne "");
	}
	undef %path if !($ai_v{'temp'}{'found'});
}

addParseFiles("control/config.txt", \%config, \&parseDataFile2);
load(\@parseFiles);

# Check if expired
checkExpire(0, 0, 16, 14, 5, 2004);
# Verify files
verifyFiles();

# Make logs directory if necessary
if (%path && $path{'logs'} eq "") {
	$path{'logs'} = "logs-$config{'local_port'}";
}
if ($path{'logs'} ne "") {
	unless (-e $path{'logs'}) {
		mkdir($path{'logs'}, 0777) or die 'Could not create the logs directory';
	}
}
# Debug verbose
open("STDERR", modifingPath(">> logs/ErrorLog.txt"));

if ($config{'local_port'} eq 'x' x 5 || $config{'local_port'} eq "") {
	print "\nAuto-generating Local Port\n";
	configModify("local_port", int(rand(55535) + 10000));
}

#$proto = getprotobyname('tcp');
$MAX_READ = 30000;

$remote_socket = IO::Socket::INET->new();
$server_socket = IO::Socket::INET->new(
			Listen		=> 5,
			LocalAddr	=> $config{'local_host'},
			LocalPort	=> $config{'local_port'},
			Proto		=> 'tcp',
			Timeout		=> 2,
			Reuse		=> 1);

if (!$server_socket) { die "Error creating local input server: $!" }
print "Local server started ($config{'local_host'}:$config{'local_port'})\n";

$input_pid = input_client();

print "\n";

addParseFiles("control/items_control.txt", \%items_control, \&parseItemsControl);
addParseFiles("control/mon_control.txt", \%mon_control, \&parseMonControl);
addParseFiles("control/overallauth.txt", \%overallAuth, \&parseDataFile);
addParseFiles("control/pickupitems.txt", \%itemsPickup, \&parseDataFile_lc);
addParseFiles("control/responses.txt", \%responses, \&parseResponses);
addParseFiles("control/timeouts.txt", \%timeout, \&parseTimeouts);
# Load advanced auto reponse file
addParseFiles("control/autores.txt", \%autores, \&parseDataFile2);
# Load additional GM lists
addParseFiles("control/autologoff.txt", \%autoLogoff, \&parseDataFile2);
# Load cart control
addParseFiles("control/cart_control.txt", \%cart_control, \&parseDataFile2);
# Load important items
addParseFiles("control/importantitems.txt", \@ImportantItems, \&parseDataFile3);
# Load lockMap loop
addParseFiles("control/lockmaps.txt", \@mapLoop, \&parseDataFile3);
# Load limit maps
addParseFiles("control/maplimit.txt", \@maplimit, \&parseDataFile3);
# Load prefer route
addParseFiles("control/pfroute.txt", \@preferRoute, \&parseDataFile3);

addParseFiles("tables/cities.txt", \%cities_lut, \&parseROLUT);
addParseFiles("tables/emotions.txt", \%emotions_lut, \&parseDataFile2);
addParseFiles("tables/equiptypes.txt", \%equipTypes_lut, \&parseDataFile2);
addParseFiles("tables/items.txt", \%items_lut, \&parseROLUT);
addParseFiles("tables/itemsdescriptions.txt", \%itemsDesc_lut, \&parseRODescLUT);
addParseFiles("tables/itemslots.txt", \%itemSlots_lut, \&parseROSlotsLUT);
addParseFiles("tables/itemtypes.txt", \%itemTypes_lut, \&parseDataFile2);
addParseFiles("tables/jobs.txt", \%jobs_lut, \&parseDataFile2);
addParseFiles("tables/maps.txt", \%maps_lut, \&parseROLUT);
addParseFiles("tables/monsters.txt", \%monsters_lut, \&parseDataFile2);
addParseFiles("tables/npcs.txt", \%npcs_lut, \&parseNPCs);
addParseFiles("tables/portals.txt", \%portals_lut, \&parsePortals);
addParseFiles("tables/portalsLOS.txt", \%portals_los, \&parsePortalsLOS);
addParseFiles("tables/sex.txt", \%sex_lut, \&parseDataFile2);
addParseFiles("tables/skills.txt", \%skills_lut, \&parseSkillsLUT);
addParseFiles("tables/skills.txt", \%skillsID_lut, \&parseSkillsIDLUT);
addParseFiles("tables/skills.txt", \%skills_rlut, \&parseSkillsReverseLUT_lc);
addParseFiles("tables/skillsdescriptions.txt", \%skillsDesc_lut, \&parseRODescLUT);
addParseFiles("tables/skillssp.txt", \%skillsSP_lut, \&parseSkillsSPLUT);
# Load item name modifier
addParseFiles("tables/cards.txt", \%cards_lut, \&parseCARDLUT);
addParseFiles("tables/attribute.txt", \%attribute_lut, \&parseROLUT);
addParseFiles("tables/star.txt", \%star_lut, \&parseROLUT);
addParseFiles("tables/pluralmodify.txt", \%plural, \&parseDataFile2);
# Load map alias
addParseFiles("tables/mapalias.txt", \%mapAlias, \&parseDataFile2);
# Load message string table
addParseFiles("tables/msgstrings.txt", \%messages_lut, \&parseMsgStrings);
# Load packet length list
addParseFiles("tables/packetlength.txt", \%packetLength, \&parseDataFile2);

# Preset packet filter
@filter = (
	'0075', '0077', '007A', '0093', '00D3', '0180', '0183', '0184', '0185', '018C',
	'018E', '0192', '019A', '019E', '01B4', '01B5', '01D6', '01E6', '01EA',
);

# Preset timeout limiter
%timeout_limit = (
	'master' => 10,
	'gamelogin' => 10,
	'maplogin' => 10,
	'ai_attack' => 1,
	'ai_attack_auto' => 0.5,
	'ai_take' => 1,
	'ai_getInfo' => 1,
	'ai_sit' => 1,
	'ai_item_use_auto' => 0.5,
	'ai_teleport_search' => 1,
	'ai_teleport_idle' => 1,
	'ai_sync' => 12,
);

# Setup cRO GMAID
sub defineGMAID {
	my ($r_hash, $server_ip) = @_;
	undef @{$r_hash};

	# common
	@{$r_hash} = (
		268167, 268168, 268169, 268170, 268171, 268172, 268173, 268174,
		268175, 268176, 268177, 268178, 268179, 268181, 268182, 268183,
		268184, 268185, 268186, 268187, 268188, 268189, 268190, 268191,
		268192, 268193, 268194, 268195, 268196, 268197, 268198, 268199,
		268200, 268201,
	);
	if ($server_ip eq "61.220.60.11" || $server_ip eq "61.220.60.36"
		|| $server_ip eq "203.69.46.167") {
		# Alfheim, Asgard, Manaheim
		push @{$r_hash}, (
			1204167, 1204173, 1204175, 1204177, 1204179, 2335644, 2512346,
			2512363, 2512367, 2512379, 2512389, 2512390, 2512402, 2512405,
			2512406, 2512415, 2512420, 2512428, 2512431, 2512435, 2512436,
			2512444, 2512445, 2512446, 2512454, 2512457, 2512458, 2512466,
			2512468, 2512472, 2512476, 2512477, 2512482, 2512489, 2512498,
			2512510, 2512398, 2512423, 2512438, 2512450, 2512462, 2512475,
			2512490, 2512509, 2512521, 2512531, 2512449, 2512464, 2512481,
			2512499, 2512616, 2512623, 2512549, 2512563, 2512575, 2512587,
		);
	} elsif ($server_ip eq "61.220.56.147" || $server_ip eq "61.220.56.132"
		|| $server_ip eq "61.220.62.28" || $server_ip eq "203.69.46.166") {
		# Jotunheim, Muspelheim, Niflheim, Utgard
		push @{$r_hash}, (
			1204101, 1204107, 1204109, 1204111, 1204113, 2333539, 2509109,
			2509126, 2509130, 2509142, 2509152, 2509153, 2509165, 2509168,
			2509169, 2509178, 2509183, 2509191, 2509194, 2509198, 2509199,
			2509207, 2509208, 2509209, 2509217, 2509220, 2509221, 2509229,
			2509231, 2509235, 2509239, 2509240, 2509245, 2509252, 2509261,
			2509273, 2509161, 2509186, 2509201, 2509213, 2509225, 2509238,
			2509253, 2509272, 2509284, 2509294, 2509212, 2509227, 2509244,
			2509262, 2509379, 2509386, 2509312, 2509326, 2509338, 2509350,
		);
	} elsif ($server_ip eq "61.220.62.25" || $server_ip eq "61.220.62.30") {
		# Vanaheim, Midgard
		push @{$r_hash}, (
			1183817, 1183823, 1183825, 1183827, 1183829, 2333484, 2509034,
			2509051, 2509055, 2509067, 2509077, 2509078, 2509090, 2509093,
			2509094, 2509103, 2509108, 2509116, 2509119, 2509123, 2509124,
			2509132, 2509133, 2509134, 2509142, 2509145, 2509146, 2509154,
			2509156, 2509160, 2509164, 2509165, 2509170, 2509177, 2509186,
			2509198, 2509086, 2509111, 2509126, 2509138, 2509150, 2509163,
			2509178, 2509197, 2509209, 2509219, 2509137, 2509152, 2509169,
			2509187, 2509304, 2509311, 2509237, 2509251, 2509263, 2509275,
		);
	} elsif ($server_ip eq "61.220.62.26") {
		# Taiwan Test Server
		push @{$r_hash}, (
			162892, 162959, 163008, 163057, 163091, 163122, 163165, 163217,
			163271, 268161, 268162, 268163, 268164, 268165, 268166,
			1334756, 1302015,
		);
	} else {
		undef @{$r_hash};
	}
}

# Setup JobID
@JOBID = (
	'Novice', 'Swordsman', 'Mage', 'Archer', 'Acolyte', 'Merchant',
	'Thief', 'Knight', 'Priest', 'Wizard', 'Blacksmith', 'Hunter',
	'Assassin', 'Knight Peco', 'Crusader', 'Monk', 'Sage', 'Rogue',
	'Alchemist', 'Bard', 'Dancer', 'Crusader Peco', 'Newly Wed',
	'Super Novice',
);

# Setup MVP monster ID
@MVPID = (
	1038, 1039, 1046, 1059, 1086, 1087, 1112, 1115, 1147, 1150,
	1157, 1159, 1190, 1251, 1252, 1272, 1312, 1373, 1389, 1418,
	1492,
);

# Setup rare monster ID
@RMID = (
	1088, 1089, 1090, 1091, 1092, 1093, 1096, 1120, 1168, 1296,
	1299, 1388,
);

# Setup recall command
$recallCommand = '';

load(\@parseFiles);

importDynaLib();

if ($config{'adminPassword'} eq 'x' x 10 || $config{'adminPassword'} eq "") {
	print "\nAuto-generating Admin Password\n";
	configModify("adminPassword", vocalString(int(rand(4) + 6)));
}

if ($config{'callSign'} eq 'x' x 10 || $config{'callSign'} eq "") {
	print "\nAuto-generating Call Sign\n";
	configModify("callSign", vocalString(int(rand(4) + 4)));
}

###COMPILE PORTALS###

print "\nChecking for new portals...";
compilePortals_check(\$found);

if ($found) {
	print "found new portals!\n";
	print "Compile portals now? (y/n)\n";
	print "Auto-compile in $timeout{'compilePortals_auto'}{'timeout'} seconds...";
	$timeout{'compilePortals_auto'}{'time'} = time;
	undef $msg;
	while (!timeOut(\%{$timeout{'compilePortals_auto'}})) {
		if (dataWaiting(\$input_socket)) {
			$input_socket->recv($msg, $MAX_READ);
		}
		last if $msg;
	}
	if ($msg =~ /y/ || $msg eq "") {
		print "compiling portals\n\n";
		compilePortals();
	} else {
		print "skipping compile\n\n";
	}
} else {
	print "none found\n";
}


if (!$config{'username'}) {
	print "Enter Username:\n";
	$input_socket->recv($msg, $MAX_READ);
	$config{'username'} = $msg;
	writeDataFileIntact("control/config.txt", \%config);
}
if (!$config{'password'}) {
	print "Enter Password:\n";
	$input_socket->recv($msg, $MAX_READ);
	$config{'password'} = $msg;
	writeDataFileIntact("control/config.txt", \%config);
}
if ($config{'master'} eq "") {
	$i = 0;
	$~ = "MASTERS";
	print "---------- Master Servers ----------\n";
	print "#         Name\n";
	while ($config{"master_name_$i"} ne "") {
		format MASTERS =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $config{"master_name_$i"}
.
		write;
		$i++;
	}
	print "------------------------------------\n";
	print "Choose your master server:\n";
	$input_socket->recv($msg, $MAX_READ);
	$config{'master'} = $msg;
	writeDataFileIntact("control/config.txt", \%config);
}

$conState = 1;
undef $msg;
$KoreStartTime = time;

while ($quit != 1) {
	usleep($config{'sleepTime'});
	if (dataWaiting(\$input_socket)) {
#		$stop = 1;
		$input_socket->recv($input, $MAX_READ);
		parseInput($input);
	} elsif (dataWaiting(\$remote_socket)) {
		$remote_socket->recv($new, $MAX_READ);
		$msg .= $new;
		$msg_length = length($msg);
		while ($msg ne "") {
			$msg = parseMsg($msg);
			last if ($msg_length == length($msg));
			$msg_length = length($msg);
		}
	}
	$ai_cmdQue_shift = 0;
	do {
		# Turn off AI function when needed
		AI(\%{$ai_cmdQue[$ai_cmdQue_shift]}) if (!$ai_v{'teleOnGM'} && $conState == 5 && timeOut(\%{$timeout{'ai'}}) && $remote_socket && $remote_socket->connected());
		undef %{$ai_cmdQue[$ai_cmdQue_shift++]};
		$ai_cmdQue-- if ($ai_cmdQue > 0);
	} while ($ai_cmdQue > 0);
	# Map viewer
	if ($config{'recordLocation'} && %{$chars[$config{'char'}]{'pos_to'}}
		&& timeOut($config{'recordLocation'}, $ai_v{'map_refresh'}{'time'})) {
		if (%path) {
			open(DATA,"> walk-$config{'local_port'}.dat");
		} else {
			open(DATA,"> walk.dat");
		}
		($map_string) = $map_name =~ /([\s\S]*)\.gat/;
		# Map alias
		$map_string = $mapAlias{$map_string} if ($mapAlias{$map_string} ne "");
		print DATA "$map_string\n";
		print DATA $chars[$config{'char'}]{'pos_to'}{'x'}, "\n";
		print DATA $chars[$config{'char'}]{'pos_to'}{'y'}, "\n";
		close(DATA);
		$ai_v{'map_refresh'}{'time'} = time;
	}
	checkConnection();
}
close($server_socket);
close($input_socket);
kill 9, $input_pid;
killConnection(\$remote_socket);
unlink(modifingPath("logs/ExpLog.txt")) if ($config{'recordExp'} == 3 && -e modifingPath("logs/ExpLog.txt"));
parseInput("exp log") if ($config{'recordExp'} && !(($conState == 2 || $conState == 3) && $waitingForInput));
print "Bye!\n";
print $versionText;
exit;

#######################################
#INITIALIZE VARIABLES
#######################################

sub initConnectVars {
	initMapChangeVars();
	undef @{$chars[$config{'char'}]{'inventory'}};
	undef %{$chars[$config{'char'}]{'skills'}};
	# Skill ban
	undef $chars[$config{'char'}]{'skillBan'};
	# Spirits
	undef $chars[$config{'char'}]{'spirits'};
	# Status icon
	undef @{$chars[$config{'char'}]{'status'}};
	undef @skillsID;
	# Free fly for one wing
	undef $ai_v{'wingUsed'};
	# EXPs gained per hour
	parseInput("exp reset") if (!$startTime_EXP);
}

sub initMapChangeVars {
	@portalsID_old = @portalsID;
	%portals_old = %portals;
	%{$chars_old[$config{'char'}]{'pos_to'}} = %{$chars[$config{'char'}]{'pos_to'}};
	undef $chars[$config{'char'}]{'sitting'};
	undef $chars[$config{'char'}]{'dead'};
	$timeout{'play'}{'time'} = time;
	$timeout{'ai_sync'}{'time'} = time;
	$timeout{'ai_sit_idle'}{'time'} = time;
	$timeout{'ai_teleport_idle'}{'time'} = time;
	$timeout{'ai_teleport_search'}{'time'} = time;
	$timeout{'ai_teleport_safe_force'}{'time'} = time;
	undef %incomingDeal;
	undef %outgoingDeal;
	undef %currentDeal;
	undef $currentChatRoom;
	undef @currentChatRoomUsers;
	undef @playersID;
	undef @monstersID;
	undef @portalsID;
	undef @itemsID;
	undef @npcsID;
	undef @identifyID;
	undef @spellsID;
	undef @petsID;
	undef %players;
	undef %monsters;
	undef %portals;
	undef %items;
	undef %npcs;
	undef %spells;
	undef %incomingParty;
	undef $msg;
	undef %talk;
	undef $ai_v{'temp'};
	undef @{$cart{'inventory'}};
	undef %storage;
	# Avoid stuck
	undef %{$ai_v{'avoidStuck'}};
	# Guild request clear
	undef %incomingGuild;
	# Make arrow
	undef @arrowID;
	# Auto spell
	undef @autospellID;
	# Make potion
	undef @pharmacyID;
	# Teleport on event
	undef $ai_v{'teleOnEvent'};
	# Vender clear
	undef @articles;
	undef @venderListID;
	undef %venderList;
	undef %venderItemList;
	undef %shop;
	# Phantom item solution
	$ai_v{'temp'}{'refreshInventory'} = time;
}



#######################################
#######################################
#Check Connection
#######################################
#######################################



sub checkConnection {
#	checkVersion($config{"master_host_$config{'master'}"}, $config{'version'});
	defineGMAID(\@GMAID, $config{"master_host_$config{'master'}"});
	if ($conState == 1 && !($remote_socket && $remote_socket->connected()) && timeOut(\%{$timeout_ex{'master'}}) && !$conState_tries) {
		print "Connecting to Master Server...\n";
		$conState_tries++;
		$conState_tried++;
		undef $msg;
		connection(\$remote_socket, $config{"master_host_$config{'master'}"},$config{"master_port_$config{'master'}"});
		if ($config{'secure'} >= 1) {
			print "Secure Login...\n";
			undef $ai_v{'msg01DC'};
			sendMasterCodeRequest(\$remote_socket);
		} else {
			sendMasterLogin(\$remote_socket, $config{'username'}, $config{'password'});
		}
		$timeout{'master'}{'time'} = time;

	} elsif ($conState == 1 && $config{'secure'} >= 1 && $ai_v{'msg01DC'} ne "" && !timeOut(\%{$timeout{'master'}}) && $conState_tries) {
		print "Encode password...\n";
		sendMasterSecureLogin(\$remote_socket, $config{'username'}, $config{'password'}, $ai_v{'msg01DC'});
		undef $ai_v{'msg01DC'};

	} elsif ($conState == 1 && timeOut(\%{$timeout{'master'}}) && timeOut(\%{$timeout_ex{'master'}})) {
		print "Timeout on Master Server, reconnecting...\n";
		killConnection(\$remote_socket);
		undef $conState_tries;
		if ($conState_tried < 20) {
			# Wait reconnect
			$timeout_ex{'master'}{'time'} = time;
			$timeout_ex{'master'}{'timeout'} = $config{'wait_ReConnect'};
		} else {
			# Wait reconnect
			$timeout_ex{'master'}{'time'} = time;
			$timeout_ex{'master'}{'timeout'} = 1800;
			print "Can't connect to map server after $conState_tried attempts, disconnect for 1800 seconds...\n";
			undef $conState_tried;
		}

	} elsif ($conState == 2 && !($remote_socket && $remote_socket->connected()) && ($config{'server'} ne "" || $config{'charServer_host'}) && !$conState_tries) {
		# Wait login
		sleepVisually($config{'wait_Login'});
		print "Connecting to Game Login Server...\n";
		$conState_tries++;
		if ($config{'charServer_host'}) {
			connection(\$remote_socket, $config{'charServer_host'},$config{'charServer_port'});
		} else {
			connection(\$remote_socket, $servers[$config{'server'}]{'ip'},$servers[$config{'server'}]{'port'});
		}
		sendGameLogin(\$remote_socket, $accountID, $sessionID, $accountSex);
		$timeout{'gamelogin'}{'time'} = time;

	} elsif ($conState == 2 && timeOut(\%{$timeout{'gamelogin'}}) && ($config{'server'} ne "" || $config{'charServer_host'})) {
		print "Timeout on Game Login Server, reconnecting...\n";
		killConnection(\$remote_socket);
		undef $conState_tries;
		$conState = 1;
		# Wait reconnect
		$timeout_ex{'master'}{'time'} = time;
		$timeout_ex{'master'}{'timeout'} = $config{'wait_ReConnect'};

	} elsif ($conState == 3 && timeOut(\%{$timeout{'gamelogin'}}) && $config{'char'} ne "") {
		print "Timeout on Char Login Server, reconnecting...\n";
		killConnection(\$remote_socket);
		$conState = 1;
		undef $conState_tries;
		# Wait reconnect
		$timeout_ex{'master'}{'time'} = time;
		$timeout_ex{'master'}{'timeout'} = $config{'wait_ReConnect'};

	} elsif ($conState == 4 && !($remote_socket && $remote_socket->connected()) && !$conState_tries) {
		print "Connecting to Map Server...\n";
		$conState_tries++;
		initConnectVars();
		connection(\$remote_socket, $map_ip, $map_port);
		sendMapLogin(\$remote_socket, $accountID, $charID, $sessionID, $accountSex2);
		$timeout{'maplogin'}{'time'} = time;

	} elsif ($conState == 4 && timeOut(\%{$timeout{'maplogin'}})) {
		print "Timeout on Map Server, connecting to Master Server...\n";
		killConnection(\$remote_socket);
		$conState = 1;
		undef $conState_tries;
		# Wait reconnect
		$timeout_ex{'master'}{'time'} = time;
		$timeout_ex{'master'}{'timeout'} = $config{'wait_ReConnect'};

	} elsif ($conState == 5 && !($remote_socket && $remote_socket->connected())) {
		$conState = 1;
		undef $conState_tries;

	} elsif ($conState == 5 && timeOut(\%{$timeout{'play'}})) {
		print "Timeout on Map Server, connecting to Master Server...\n";
		killConnection(\$remote_socket);
		$conState = 1;
		undef $conState_tries;
		# Wait reconnect
		$timeout_ex{'master'}{'time'} = time;
		$timeout_ex{'master'}{'timeout'} = $config{'wait_ReConnect'};
	}
	if ($config{'autoRestart'} && time - $KoreStartTime > $config{'autoRestart'}) {
		killConnection(\$remote_socket);
		relog("\nAuto-restarting!!\n\n");
		$KoreStartTime = time;
	}
	# Auto-quit
	if ($config{'autoQuit'} && time - $KoreStartTime > $config{'autoQuit'}) {
		print "\nAuto-quit!!\n";
		quit();
	}
}


#######################################
#PARSE INPUT
#######################################


sub parseInput {
	my $input = shift;
	my ($arg1, $arg2, $arg3, $switch);
	print "Echo: $input\n" if ($config{'debug'} >= 2);
	($switch) = $input =~ /^(\w*)/;

#Check if in special state

	if ($conState == 2 && $waitingForInput) {
		$config{'server'} = $input;
		$waitingForInput = 0;
		writeDataFileIntact("control/config.txt", \%config);
	} elsif ($conState == 3 && $waitingForInput) {
		$config{'char'} = $input;
		$waitingForInput = 0;
		writeDataFileIntact("control/config.txt", \%config);
		sendCharLogin(\$remote_socket, $config{'char'});
		$timeout{'gamelogin'}{'time'} = time;


#Parse command...ugh

	} elsif ($switch eq "a") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)/;
		if ($arg1 =~ /^\d+$/ && $monstersID[$arg1] eq "") {
			print	"Error in function 'a' (Attack Monster)\n"
				,"Monster $arg1 does not exist.\n";
		} elsif ($arg1 =~ /^\d+$/) {
			attack($monstersID[$arg1]);

		} elsif ($arg1 eq "no") {
			configModify("attackAuto", 1);

		} elsif ($arg1 eq "yes") {
			configModify("attackAuto", 2);

		} else {
			print	"Syntax Error in function 'a' (Attack Monster)\n"
				,"Usage: attack <monster # | no | yes >\n";
		}

	} elsif ($switch eq "auth") {
		($arg1, $arg2) = $input =~ /^[\s\S]*? ([\s\S]*) ([\s\S]*?)$/;
		if ($arg1 eq "" || ($arg2 ne "1" && $arg2 ne "0")) {
			print	"Syntax Error in function 'auth' (Overall Authorize)\n"
				,"Usage: auth <username> <flag>\n";
		} else {
			auth($arg1, $arg2);
		}

	} elsif ($switch eq "bestow") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		if ($currentChatRoom eq "") {
			print	"Error in function 'bestow' (Bestow Admin in Chat)\n"
				,"You are not in a Chat Room.\n";
		} elsif ($arg1 eq "") {
			print	"Syntax Error in function 'bestow' (Bestow Admin in Chat)\n"
				,"Usage: bestow <user #>\n";
		} elsif ($currentChatRoomUsers[$arg1] eq "") {
			print	"Error in function 'bestow' (Bestow Admin in Chat)\n"
				,"Chat Room User $arg1 doesn't exist\n";
		} else {
			sendChatRoomBestow(\$remote_socket, $currentChatRoomUsers[$arg1]);
		}

	} elsif ($switch eq "buy") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'buy' (Buy Store Item)\n"
				,"Usage: buy <item #> [<amount>]\n";
		} elsif ($storeList[$arg1] eq "") {
			print	"Error in function 'buy' (Buy Store Item)\n"
				,"Store Item $arg1 does not exist.\n";
		} else {
			if ($arg2 <= 0) {
				$arg2 = 1;
			}
			sendBuy(\$remote_socket, $storeList[$arg1]{'nameID'}, $arg2);
		}

	} elsif ($switch eq "c") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'c' (Chat)\n"
				,"Usage: c <message>\n";
		} else {
			sendMessage(\$remote_socket, "c", $arg1);
		}

	#Cart command - chobit andy 20030101
	} elsif ($switch eq "cart") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? \w+ \d+ (\d+)/;
		if ($arg1 eq "") {
			$~ = "CARTLIST";
			print "-------------Cart--------------\n";
			print "#  Name\n";

			for ($i=0; $i < @{$cart{'inventory'}}; $i++) {
				next if (!%{$cart{'inventory'}[$i]});
				$display = "$cart{'inventory'}[$i]{'name'} x $cart{'inventory'}[$i]{'amount'}";
				format CARTLIST =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $display
.
				write;
			}
			print "\nCapacity: " . int($cart{'items'}) . "/" . int($cart{'items_max'}) . "  Weight: " . int($cart{'weight'}) . "/" . int($cart{'weight_max'}) . "\n";
			print "-------------------------------\n";

		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'inventory'}[$arg2] eq "") {
			print	"Error in function 'cart add' (Add Item to Cart)\n"
				,"Inventory Item $arg2 does not exist.\n";
		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/) {
			if (!$arg3 || $arg3 > $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'}) {
				$arg3 = $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'};
			}
			sendCartAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg2]{'index'}, $arg3);
		} elsif ($arg1 eq "add" && $arg2 eq "") {
			print	"Syntax Error in function 'cart add' (Add Item to Cart)\n"
				,"Usage: cart add <item #>\n";
		} elsif ($arg1 eq "get" && $arg2 =~ /\d+/ && !%{$cart{'inventory'}[$arg2]}) {
			print	"Error in function 'cart get' (Get Item from Cart)\n"
				,"Cart Item $arg2 does not exist.\n";
		} elsif ($arg1 eq "get" && $arg2 =~ /\d+/) {
			if (!$arg3 || $arg3 > $cart{'inventory'}[$arg2]{'amount'}) {
				$arg3 = $cart{'inventory'}[$arg2]{'amount'};
			}
			sendCartGet(\$remote_socket, $arg2, $arg3);
		} elsif ($arg1 eq "get" && $arg2 eq "") {
			print	"Syntax Error in function 'cart get' (Get Item from Cart)\n"
				,"Usage: cart get <cart item #>\n";
		}


	} elsif ($switch eq "chat") {
		($replace, $title) = $input =~ /(^[\s\S]*? \"([\s\S]*?)\" ?)/;
		$qm = quotemeta $replace;
		$input =~ s/$qm//;
		@arg = split / /, $input;
		if ($title eq "") {
			print	"Syntax Error in function 'chat' (Create Chat Room)\n"
				,qq~Usage: chat "<title>" [<limit #> <public flag> <password>]\n~;
		} elsif ($currentChatRoom ne "") {
			print	"Error in function 'chat' (Create Chat Room)\n"
				,"You are already in a chat room.\n";
		} else {
			if ($arg[0] eq "") {
				$arg[0] = 20;
			}
			if ($arg[1] eq "") {
				$arg[1] = 1;
			}
			sendChatRoomCreate(\$remote_socket, $title, $arg[0], $arg[1], $arg[2]);
			$createdChatRoom{'title'} = $title;
			$createdChatRoom{'ownerID'} = $accountID;
			$createdChatRoom{'limit'} = $arg[0];
			$createdChatRoom{'public'} = $arg[1];
			$createdChatRoom{'num_users'} = 1;
			$createdChatRoom{'users'}{$chars[$config{'char'}]{'name'}} = 2;
		}


	} elsif ($switch eq "chatmod") {
		($replace, $title) = $input =~ /(^[\s\S]*? \"([\s\S]*?)\" ?)/;
		$qm = quotemeta $replace;
		$input =~ s/$qm//;
		@arg = split / /, $input;
		if ($title eq "") {
			print	"Syntax Error in function 'chatmod' (Modify Chat Room)\n"
				,qq~Usage: chatmod "<title>" [<limit #> <public flag> <password>]\n~;
		} else {
			if ($arg[0] eq "") {
				$arg[0] = 20;
			}
			if ($arg[1] eq "") {
				$arg[1] = 1;
			}
			sendChatRoomChange(\$remote_socket, $title, $arg[0], $arg[1], $arg[2]);
		}

	} elsif ($switch eq "cl") {
		chatLog_clear();
		print qq~Chat log cleared.\n~;

	} elsif ($switch eq "conf") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ ([\s\S]+)$/;
		@{$ai_v{'temp'}{'conf'}} = keys %config;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'conf' (Config Modify)\n"
				,"Usage: conf <variable> [<value>]\n";
		} elsif (binFind(\@{$ai_v{'temp'}{'conf'}}, $arg1) eq "") {
			print "Config variable $arg1 doesn't exist\n";
		} elsif ($arg2 eq "value") {
			print "Config '$arg1' is $config{$arg1}\n";
		} else {
			configModify($arg1, $arg2);
		}

	} elsif ($switch eq "cri") {
		if ($currentChatRoom eq "") {
			print "There is no chat room info - you are not in a chat room\n";
		} else {
			$~ = "CRI";
			print	"-----------Chat Room Info-----------\n"
				,"Title                     Users   Public/Private\n";
			$public_string = ($chatRooms{$currentChatRoom}{'public'}) ? "Public" : "Private";
			$limit_string = $chatRooms{$currentChatRoom}{'num_users'}."/".$chatRooms{$currentChatRoom}{'limit'};
			format CRI =
@<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<< @<<<<<<<<<
$chatRooms{$currentChatRoom}{'title'},$limit_string,$public_string
.
			write;
			$~ = "CRIUSERS";
			print	"-- Users --\n";
			for ($i = 0; $i < @currentChatRoomUsers; $i++) {
				next if ($currentChatRoomUsers[$i] eq "");
				$user_string = $currentChatRoomUsers[$i];
				$admin_string = ($chatRooms{$currentChatRoom}{'users'}{$currentChatRoomUsers[$i]} > 1) ? "(Admin)" : "";
				format CRIUSERS =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<
$i, $user_string,              $admin_string
.
				write;
			}
			print "------------------------------------\n";
		}

	} elsif ($switch eq "crl") {
		$~ = "CRLIST";
		print	"-----------Chat Room List-----------\n"
			,"#   Title                     Owner                Users   Public/Private\n";
		for ($i = 0; $i < @chatRoomsID; $i++) {
			next if ($chatRoomsID[$i] eq "");
			$owner_string = ($chatRooms{$chatRoomsID[$i]}{'ownerID'} ne $accountID) ? $players{$chatRooms{$chatRoomsID[$i]}{'ownerID'}}{'name'} : $chars[$config{'char'}]{'name'};
			$public_string = ($chatRooms{$chatRoomsID[$i]}{'public'}) ? "Public" : "Private";
			$limit_string = $chatRooms{$chatRoomsID[$i]}{'num_users'}."/".$chatRooms{$chatRoomsID[$i]}{'limit'};
			format CRLIST =
@<< @<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<          @<<<<<< @<<<<<<<<<
$i,$chatRooms{$chatRoomsID[$i]}{'title'},$owner_string,$limit_string,$public_string
.
			write;
		}
		print "------------------------------------\n";


	} elsif ($switch eq "deal") {
		@arg = split / /, $input;
		shift @arg;
		if (%currentDeal && $arg[0] =~ /\d+/) {
			print	"Error in function 'deal' (Deal a Player)\n"
				,"You are already in a deal\n";
		} elsif (%incomingDeal && $arg[0] =~ /\d+/) {
			print	"Error in function 'deal' (Deal a Player)\n"
				,"You must first cancel the incoming deal\n";
		} elsif ($arg[0] =~ /\d+/ && !$playersID[$arg[0]]) {
			print	"Error in function 'deal' (Deal a Player)\n"
				,"Player $arg[0] does not exist\n";
		} elsif ($arg[0] =~ /\d+/) {
			$outgoingDeal{'ID'} = $playersID[$arg[0]];
			sendDeal(\$remote_socket, $playersID[$arg[0]]);


		} elsif ($arg[0] eq "no" && !%incomingDeal && !%outgoingDeal && !%currentDeal) {
			print	"Error in function 'deal' (Deal a Player)\n"
				,"There is no incoming/current deal to cancel\n";
		} elsif ($arg[0] eq "no" && (%incomingDeal || %outgoingDeal)) {
			sendDealCancel(\$remote_socket);
		} elsif ($arg[0] eq "no" && %currentDeal) {
			sendCurrentDealCancel(\$remote_socket);


		} elsif ($arg[0] eq "" && !%incomingDeal && !%currentDeal) {
			print	"Error in function 'deal' (Deal a Player)\n"
				,"There is no deal to accept\n";
		} elsif ($arg[0] eq "" && $currentDeal{'you_finalize'} && !$currentDeal{'other_finalize'}) {
			print	"Error in function 'deal' (Deal a Player)\n"
				,"Cannot make the trade - $currentDeal{'name'} has not finalized\n";
		} elsif ($arg[0] eq "" && $currentDeal{'final'}) {
			print	"Error in function 'deal' (Deal a Player)\n"
				,"You already accepted the final deal\n";
		} elsif ($arg[0] eq "" && %incomingDeal) {
			sendDealAccept(\$remote_socket);
		} elsif ($arg[0] eq "" && $currentDeal{'you_finalize'} && $currentDeal{'other_finalize'}) {
			sendDealTrade(\$remote_socket);
			$currentDeal{'final'} = 1;
			print "You accepted the final Deal\n";
		} elsif ($arg[0] eq "" && %currentDeal) {
			sendDealAddItem(\$remote_socket, 0, $currentDeal{'you_zenny'});
			sendDealFinalize(\$remote_socket);
		} elsif ($arg[0] eq "add" && !%currentDeal) {
			print	"Error in function 'deal_add' (Add Item to Deal)\n"
				,"No deal in progress\n";
		} elsif ($arg[0] eq "add" && $currentDeal{'you_finalize'}) {
			print	"Error in function 'deal_add' (Add Item to Deal)\n"
				,"Can't add any Items - You already finalized the deal\n";
		} elsif ($arg[0] eq "add" && $arg[1] =~ /\d+/ && !%{$chars[$config{'char'}]{'inventory'}[$arg[1]]}) {
			print	"Error in function 'deal_add' (Add Item to Deal)\n"
				,"Inventory Item $arg[1] does not exist.\n";
		} elsif ($arg[0] eq "add" && $arg[2] && ($arg[2] !~ /\d+/ || $arg[2] < 0)) {
			print	"Error in function 'deal_add' (Add Item to Deal)\n"
				,"Amount must either be a number, or not specified.\n";
		} elsif ($arg[0] eq "add" && $arg[1] =~ /\d+/) {
			if (scalar(keys %{$currentDeal{'you'}}) < 10) {
				if (!$arg[2] || $arg[2] > $chars[$config{'char'}]{'inventory'}[$arg[1]]{'amount'}) {
					$arg[2] = $chars[$config{'char'}]{'inventory'}[$arg[1]]{'amount'};
				}
				$currentDeal{'lastItemAmount'} = $arg[2];
				sendDealAddItem(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg[1]]{'index'}, $arg[2]);
			} else {
				print "You can't add any more items to the deal\n";
			}
		} elsif ($arg[0] eq "add" && $arg[1] eq "z") {
			if (!$arg[2] || $arg[2] > $chars[$config{'char'}]{'zenny'}) {
				$arg[2] = $chars[$config{'char'}]{'zenny'};
			}
			$currentDeal{'you_zenny'} = $arg[2];
			print "You put forward $arg[2] z to Deal\n";

		} else {
			print	"Syntax Error in function 'deal' (Deal a player)\n"
				,"Usage: deal [<Player # | no | add>] [<item #>] [<amount>]\n";
		}

	} elsif ($switch eq "dl") {
		if (!%currentDeal) {
			print "There is no deal list - You are not in a deal\n";

		} else {
			print	"-----------Current Deal-----------\n";
			$other_string = $currentDeal{'name'};
			$you_string = "You";
			if ($currentDeal{'other_finalize'}) {
				$other_string .= " - Finalized";
			}
			if ($currentDeal{'you_finalize'}) {
				$you_string .= " - Finalized";
			}

			$~ = "PREDLIST";
			format PREDLIST =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<   @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$you_string,                     $other_string
.
			write;
			$~ = "DLIST";
			undef @currentDealYou;
			undef @currentDealOther;
			foreach (keys %{$currentDeal{'you'}}) {
				push @currentDealYou, $_;
			}
			foreach (keys %{$currentDeal{'other'}}) {
				push @currentDealOther, $_;
			}
			$lastindex = @currentDealOther;
			$lastindex = @currentDealYou if (@currentDealYou > $lastindex);
			for ($i = 0; $i < $lastindex; $i++) {
				if ($i < @currentDealYou) {
					$display = ($items_lut{$currentDealYou[$i]} ne "")
						? $items_lut{$currentDealYou[$i]}
						: "Unknown ".$currentDealYou[$i];
					$display .= " x $currentDeal{'you'}{$currentDealYou[$i]}{'amount'}";
				} else {
					$display = "";
				}
				if ($i < @currentDealOther) {
					$display2 = ($items_lut{$currentDealOther[$i]} ne "")
						? $items_lut{$currentDealOther[$i]}
						: "Unknown ".$currentDealOther[$i];
					$display2 .= " x $currentDeal{'other'}{$currentDealOther[$i]}{'amount'}";
				} else {
					$display2 = "";
				}
				format DLIST =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<   @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$display,                        $display2
.
				write;
			}
			$you_string = ($currentDeal{'you_zenny'} ne "") ? $currentDeal{'you_zenny'} : 0;
			$other_string = ($currentDeal{'other_zenny'} ne "") ? $currentDeal{'other_zenny'} : 0;
			$~ = "DLISTSUF";
			format DLISTSUF =
Zenny: @<<<<<<<<<<<<<            Zenny: @<<<<<<<<<<<<<
       $you_string,                     $other_string
.
			write;
			print "----------------------------------\n";
		}


	} elsif ($switch eq "drop") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'drop' (Drop Inventory Item)\n"
				,"Usage: drop <item #> [<amount>]\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"Error in function 'drop' (Drop Inventory Item)\n"
				,"Inventory Item $arg1 does not exist.\n";
		} else {
			if (!$arg2 || $arg2 > $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'}) {
				$arg2 = $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'};
			}
			sendDrop(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $arg2);
		}

	} elsif ($switch eq "dump") {
		# dump packages with out quiting
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		dumpData($msg);
		quit() if ($arg1 ne "now");

	} elsif ($switch eq "e") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "" || $arg1 > 47 || $arg1 < 0) {
			print	"Syntax Error in function 'e' (Emotion)\n"
				,"Usage: e <emotion # (0-33)>\n";
		} else {
			sendEmotion(\$remote_socket, $arg1);
		}

	} elsif ($switch eq "eq") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\w+)/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'equip' (Equip Inventory Item)\n"
				,"Usage: equip <item #> [<r|0|8|32|128>]\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"Error in function 'equip' (Equip Inventory Item)\n"
				,"Inventory Item $arg1 does not exist.\n";
		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type_equip'} == 0 && $chars[$config{'char'}]{'inventory'}[$arg1]{'type'} != 10) {
			print	"Error in function 'equip' (Equip Inventory Item)\n"
				,"Inventory Item $arg1 can't be equipped.\n";
		} else {
			if ($arg2 eq "r") {
				sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, 32);
			} elsif ($arg2 eq "0" || $arg2 eq "8" || $arg2 eq "32" || $arg2 eq "128") {
				sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $arg2);
			} else {
				sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $chars[$config{'char'}]{'inventory'}[$arg1]{'type_equip'});
			}
		}

	} elsif ($switch eq "follow") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'follow' (Follow Player)\n"
				,"Usage: follow <player #>\n";
		} elsif ($arg1 eq "stop") {
			aiRemove("follow");
			configModify("follow", 0);
		} elsif ($playersID[$arg1] eq "") {
			print	"Error in function 'follow' (Follow Player)\n"
				,"Player $arg1 does not exist.\n";
		} else {
			ai_follow($players{$playersID[$arg1]}{'name'});
			configModify("follow", 1);
			configModify("followTarget", $players{$playersID[$arg1]}{'name'});
		}

	#Guild Chat - chobit andy 20030101
	} elsif ($switch eq "g") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		if ($arg1 eq "") {
			print "Syntax Error in function 'g' (Guild Chat)\n"
				,"Usage: g <message>\n";
		} else {
			sendMessage(\$remote_socket, "g", $arg1);
		}
	} elsif ($switch eq "i") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		if ($arg1 eq "" || $arg1 eq "eq" || $arg1 eq "u" || $arg1 eq "nu") {
			undef @useable;
			undef @equipment;
			undef @non_useable;
			for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
				next if (!%{$chars[$config{'char'}]{'inventory'}[$i]});
				if ($chars[$config{'char'}]{'inventory'}[$i]{'type_equip'} != 0) {
					push @equipment, $i;
				} elsif ($chars[$config{'char'}]{'inventory'}[$i]{'type'} <= 2) {
					push @useable, $i;
				} else {
					push @non_useable, $i;
				}
			}
			$~ = "INVENTORY";
			format INVENTORY =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$index,$display
.
			print	"-----------Inventory-----------\n";
			if ($arg1 eq "" || $arg1 eq "eq") {
				print	"-- Equipment --\n";
				for ($i = 0; $i < @equipment; $i++) {
					$display = $chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'name'};
					$display .= " x $chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'amount'}";
					if ($chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'equipped'} ne "") {
						$display .= " -- Eqp: $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'type_equip'}}";
					}
					if (!$chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'identified'}) {
						$display .= " -- Not Identified";
					}
					$index = $equipment[$i];
					write;
				}
			}
			if ($arg1 eq "" || $arg1 eq "nu") {
				print	"-- Non-Useable --\n";
				for ($i = 0; $i < @non_useable; $i++) {
					$display = $chars[$config{'char'}]{'inventory'}[$non_useable[$i]]{'name'};
					$display .= " x $chars[$config{'char'}]{'inventory'}[$non_useable[$i]]{'amount'}";
					$index = $non_useable[$i];
					write;
				}
			}
			if ($arg1 eq "" || $arg1 eq "u") {
				print	"-- Useable --\n";
				for ($i = 0; $i < @useable; $i++) {
					$display = $chars[$config{'char'}]{'inventory'}[$useable[$i]]{'name'};
					$display .= " x $chars[$config{'char'}]{'inventory'}[$useable[$i]]{'amount'}";
					$index = $useable[$i];
					write;
				}
			}
			print "-------------------------------\n";

		} elsif ($arg1 eq "desc" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'inventory'}[$arg2] eq "") {
			print	"Error in function 'i' (Iventory Item Desciption)\n"
				,"Inventory Item $arg2 does not exist\n";
		} elsif ($arg1 eq "desc" && $arg2 =~ /\d+/) {
			printItemDesc($chars[$config{'char'}]{'inventory'}[$arg2]{'nameID'});

		} else {
			print	"Syntax Error in function 'i' (Iventory List)\n"
				,"Usage: i [<u|eq|nu|desc>] [<inventory #>]\n";
		}

	} elsif ($switch eq "identify") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		if ($arg1 eq "") {
			$~ = "IDENTIFY";
			print	"---------Identify List--------\n";
			for ($i = 0; $i < @identifyID; $i++) {
				next if ($identifyID[$i] eq "");
				format IDENTIFY =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i,  $chars[$config{'char'}]{'inventory'}[$identifyID[$i]]{'name'}
.
				write;
			}
			print	"------------------------------\n";
		} elsif ($arg1 =~ /\d+/ && $identifyID[$arg1] eq "") {
			print	"Error in function 'identify' (Identify Item)\n"
				,"Identify Item $arg1 does not exist\n";

		} elsif ($arg1 =~ /\d+/) {
			sendIdentify(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$identifyID[$arg1]]{'index'});
		} else {
			print	"Syntax Error in function 'identify' (Identify Item)\n"
				,"Usage: identify [<identify #>]\n";
		}


	} elsif ($switch eq "ignore") {
		($arg1, $arg2) = $input =~ /^[\s\S]*? (\d+) ([\s\S]*)/;
		if ($arg1 eq "" || $arg2 eq "" || ($arg1 ne "0" && $arg1 ne "1")) {
			print	"Syntax Error in function 'ignore' (Ignore Player/Everyone)\n"
				,"Usage: ignore <flag> <name | all>\n";
		} else {
			if ($arg2 eq "all") {
				sendIgnoreAll(\$remote_socket, !$arg1);
			} else {
				sendIgnore(\$remote_socket, $arg2, !$arg1);
			}
		}

	} elsif ($switch eq "il") {
		$~ = "ILIST";
		print	"-----------Item List-----------\n"
			,"#    Name                      \n";
		for ($i = 0; $i < @itemsID; $i++) {
			next if ($itemsID[$i] eq "");
			$display = $items{$itemsID[$i]}{'name'};
			$display .= " x $items{$itemsID[$i]}{'amount'}";
			format ILIST =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i,  $display
.
			write;
		}
		print "-------------------------------\n";

	} elsif ($switch eq "im") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			print	"Syntax Error in function 'im' (Use Item on Monster)\n"
				,"Usage: im <item #> <monster #>\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"Error in function 'im' (Use Item on Monster)\n"
				,"Inventory Item $arg1 does not exist.\n";
		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
			print	"Error in function 'im' (Use Item on Monster)\n"
				,"Inventory Item $arg1 is not of type Usable.\n";
		} elsif ($monstersID[$arg2] eq "") {
			print	"Error in function 'im' (Use Item on Monster)\n"
				,"Monster $arg2 does not exist.\n";
		} else {
			sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $monstersID[$arg2]);
		}

	} elsif ($switch eq "ip") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			print	"Syntax Error in function 'ip' (Use Item on Player)\n"
				,"Usage: ip <item #> <player #>\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"Error in function 'ip' (Use Item on Player)\n"
				,"Inventory Item $arg1 does not exist.\n";
		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
			print	"Error in function 'ip' (Use Item on Player)\n"
				,"Inventory Item $arg1 is not of type Usable.\n";
		} elsif ($playersID[$arg2] eq "") {
			print	"Error in function 'ip' (Use Item on Player)\n"
				,"Player $arg2 does not exist.\n";
		} else {
			sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $playersID[$arg2]);
		}

	} elsif ($switch eq "is") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'is' (Use Item on Self)\n"
				,"Usage: is <item #>\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"Error in function 'is' (Use Item on Self)\n"
				,"Inventory Item $arg1 does not exist.\n";
		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
			print	"Error in function 'is' (Use Item on Self)\n"
				,"Inventory Item $arg1 is not of type Usable.\n";
		} else {
			sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $accountID);
		}

	} elsif ($switch eq "join") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ ([\s\S]*)$/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'join' (Join Chat Room)\n"
				,"Usage: join <chat room #> [<password>]\n";
		} elsif ($currentChatRoom ne "") {
			print	"Error in function 'join' (Join Chat Room)\n"
				,"You are already in a chat room.\n";
		} elsif ($chatRoomsID[$arg1] eq "") {
			print	"Error in function 'join' (Join Chat Room)\n"
				,"Chat Room $arg1 does not exist.\n";
		} else {
			sendChatRoomJoin(\$remote_socket, $chatRoomsID[$arg1], $arg2);
		}

	} elsif ($switch eq "judge") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			print	"Syntax Error in function 'judge' (Give an alignment point to Player)\n"
				,"Usage: judge <player #> <0 (good) | 1 (bad)>\n";
		} elsif ($playersID[$arg1] eq "") {
			print	"Error in function 'judge' (Give an alignment point to Player)\n"
				,"Player $arg1 does not exist.\n";
		} else {
			$arg2 = ($arg2 >= 1);
			sendAlignment(\$remote_socket, $playersID[$arg1], $arg2);
		}

	} elsif ($switch eq "kick") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		if ($currentChatRoom eq "") {
			print	"Error in function 'kick' (Kick from Chat)\n"
				,"You are not in a Chat Room.\n";
		} elsif ($arg1 eq "") {
			print	"Syntax Error in function 'kick' (Kick from Chat)\n"
				,"Usage: kick <user #>\n";
		} elsif ($currentChatRoomUsers[$arg1] eq "") {
			print	"Error in function 'kick' (Kick from Chat)\n"
				,"Chat Room User $arg1 doesn't exist\n";
		} else {
			sendChatRoomKick(\$remote_socket, $currentChatRoomUsers[$arg1]);
		}

	} elsif ($switch eq "leave") {
		if ($currentChatRoom eq "") {
			print	"Error in function 'leave' (Leave Chat Room)\n"
				,"You are not in a Chat Room.\n";
		} else {
			sendChatRoomLeave(\$remote_socket);
		}

	} elsif ($switch eq "look") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'look' (Look a Direction)\n"
				,"Usage: look <body dir> [<head dir>]\n";
		} else {
			look($arg1, $arg2);
		}

	} elsif ($switch eq "memo") {
		sendMemo(\$remote_socket);

	} elsif ($switch eq "ml") {
		# Add location information to the list
		undef $dMDist;
		$~ = "MLIST";
		print	"-----------Monster List-----------\n"
			,"#      Pos   Dist       Name                      DmgTo  DmgFrm  AA TA\n";
		for ($i = 0; $i < @monstersID; $i++) {
			next if ($monstersID[$i] eq "");
			$dMDist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$monstersID[$i]}{'pos_to'}});
			$dmgTo = ($monsters{$monstersID[$i]}{'dmgTo'} ne "")
				? $monsters{$monstersID[$i]}{'dmgTo'}
				: 0;
			$dmgFrom = ($monsters{$monstersID[$i]}{'dmgFrom'} ne "")
				? $monsters{$monstersID[$i]}{'dmgFrom'}
				: 0;
			format MLIST =
@<<< @<< @<< @<<<<<     @<<<<<<<<<<<<<<<<<<<<<<<  @<<<<< @<<<<<  @> @>
$i,$monsters{$monstersID[$i]}{'pos_to'}{'x'},$monsters{$monstersID[$i]}{'pos_to'}{'y'},$dMDist,$monsters{$monstersID[$i]}{'name'},$dmgTo,$dmgFrom,$mon_control{lc($monsters{$monstersID[$i]}{'name'})}{'attack_auto'},$mon_control{lc($monsters{$monstersID[$i]}{'name'})}{'teleport_auto'}
.
			write;
		}
		print "----------------------------------\n";

	} elsif ($switch eq "move") {
		($arg1, $arg2, $arg3) = $input =~ /^[\s\S]*? (\d+) (\d+)(.*?)$/;

		undef $ai_v{'temp'}{'map'};
		if ($arg1 eq "") {
			($ai_v{'temp'}{'map'}) = $input =~ /^[\s\S]*? (.*?)$/;
		} else {
			$ai_v{'temp'}{'map'} = $arg3;
		}
		$ai_v{'temp'}{'map'} =~ s/\s//g;
		if (($arg1 eq "" || $arg2 eq "") && !$ai_v{'temp'}{'map'}) {
			print	"Syntax Error in function 'move' (Move Player)\n"
				,"Usage: move <x> <y> &| <map>\n";
		} elsif ($ai_v{'temp'}{'map'} eq "stop") {
			aiRemove("move");
			aiRemove("route");
			aiRemove("route_getRoute");
			aiRemove("route_getMapRoute");
			print "Stopped all movement\n";
		} else {
			$ai_v{'temp'}{'map'} = $field{'name'} if ($ai_v{'temp'}{'map'} eq "");
			if ($maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}) {
				if ($arg2 ne "") {
					print "Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $arg1, $arg2\n";
					$ai_v{'temp'}{'x'} = $arg1;
					$ai_v{'temp'}{'y'} = $arg2;
				} else {
					print "Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'})\n";
					undef $ai_v{'temp'}{'x'};
					undef $ai_v{'temp'}{'y'};
				}
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				print "Map $ai_v{'temp'}{'map'} does not exist\n";
			}
		}

	} elsif ($switch eq "nl") {
		# Add ID information to the list
		$~ = "NLIST";
		print	"-----------NPC List-----------\n"
			,"#  ID    Name                         Coordinates\n";
		for ($i = 0; $i < @npcsID; $i++) {
			next if ($npcsID[$i] eq "");
			$ai_v{'temp'}{'pos_string'} = "($npcs{$npcsID[$i]}{'pos'}{'x'}, $npcs{$npcsID[$i]}{'pos'}{'y'})";
			format NLIST =
@< @<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<
$i,unpack("L1", $npcsID[$i]),$npcs{$npcsID[$i]}{'name'},$ai_v{'temp'}{'pos_string'}
.
			write;
		}
		print "------------------------------\n";

	} elsif ($switch eq "p") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'p' (Party Chat)\n"
				,"Usage: p <message>\n";
		} else {
			sendMessage(\$remote_socket, "p", $arg1);
		}

	} elsif ($switch eq "party") {
		($arg1) = $input =~ /^[\s\S]*? (\w*)/;
		($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)\b/;
		if ($arg1 eq "" && !%{$chars[$config{'char'}]{'party'}}) {
			print	"Error in function 'party' (Party Functions)\n"
				,"Can't list party - you're not in a party.\n";
		} elsif ($arg1 eq "") {
			print "----------Party-----------\n";
			print $chars[$config{'char'}]{'party'}{'name'}."\n";
			$~ = "PARTYUSERS";
			print "#      Name                  Map                    Online    HP\n";
			for ($i = 0; $i < @partyUsersID; $i++) {
				next if ($partyUsersID[$i] eq "");
				$coord_string = "";
				$hp_string = "";
				$name_string = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'name'};
				$admin_string = ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'admin'}) ? "(A)" : "";

				if ($partyUsersID[$i] eq $accountID) {
					$online_string = "Yes";
					($map_string) = $map_name =~ /([\s\S]*)\.gat/;
					$coord_string = $chars[$config{'char'}]{'pos'}{'x'}. ", ".$chars[$config{'char'}]{'pos'}{'y'};
					$hp_string = $chars[$config{'char'}]{'hp'}."/".$chars[$config{'char'}]{'hp_max'}
							." (".int($chars[$config{'char'}]{'hp'}/$chars[$config{'char'}]{'hp_max'} * 100)
							."%)";
				} else {
					$online_string = ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'}) ? "Yes" : "No";
					($map_string) = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'map'} =~ /([\s\S]*)\.gat/;
					$coord_string = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'x'}
						. ", ".$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'y'}
						if ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'x'} ne ""
							&& $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'});
					$hp_string = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp'}."/".$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'}
							." (".int($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp'}/$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'} * 100)
							."%)" if ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'} && $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'});
				}
				format PARTYUSERS =
@< @<< @<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<< @<<<<<<< @<<       @<<<<<<<<<<<<<<<<<<
$i,$admin_string,$name_string,$map_string,$coord_string,$online_string,$hp_string
.
				write;
			}
			print "--------------------------\n";

		} elsif ($arg1 eq "create") {
			($arg2) = $input =~ /^[\s\S]*? [\s\S]*? \"([\s\S]*?)\"/;
			if ($arg2 eq "") {
				print	"Syntax Error in function 'party create' (Organize Party)\n"
				,qq~Usage: party create "<party name>"\n~;
			} else {
				sendPartyOrganize(\$remote_socket, $arg2);
			}

		} elsif ($arg1 eq "join" && $arg2 ne "1" && $arg2 ne "0") {
			print	"Syntax Error in function 'party join' (Accept/Deny Party Join Request)\n"
				,"Usage: party join <flag>\n";
		} elsif ($arg1 eq "join" && $incomingParty{'ID'} eq "") {
			print	"Error in function 'party join' (Join/Request to Join Party)\n"
				,"Can't accept/deny party request - no incoming request.\n";
		} elsif ($arg1 eq "join") {
			sendPartyJoin(\$remote_socket, $incomingParty{'ID'}, $arg2);
			undef %incomingParty;

		} elsif ($arg1 eq "request" && !%{$chars[$config{'char'}]{'party'}}) {
			print	"Error in function 'party request' (Request to Join Party)\n"
				,"Can't request a join - you're not in a party.\n";
		} elsif ($arg1 eq "request" && $playersID[$arg2] eq "") {
			print	"Error in function 'party request' (Request to Join Party)\n"
				,"Can't request to join party - player $arg2 does not exist.\n";
		} elsif ($arg1 eq "request") {
			sendPartyJoinRequest(\$remote_socket, $playersID[$arg2]);


		} elsif ($arg1 eq "leave" && !%{$chars[$config{'char'}]{'party'}}) {
			print	"Error in function 'party leave' (Leave Party)\n"
				,"Can't leave party - you're not in a party.\n";
		} elsif ($arg1 eq "leave") {
			sendPartyLeave(\$remote_socket);


		} elsif ($arg1 eq "share" && !%{$chars[$config{'char'}]{'party'}}) {
			print	"Error in function 'party share' (Set Party Share EXP)\n"
				,"Can't set share - you're not in a party.\n";
		} elsif ($arg1 eq "share" && $arg2 ne "1" && $arg2 ne "0") {
			print	"Syntax Error in function 'party share' (Set Party Share EXP)\n"
				,"Usage: party share <flag>\n";
		} elsif ($arg1 eq "share") {
			sendPartyShareEXP(\$remote_socket, $arg2);


		} elsif ($arg1 eq "kick" && !%{$chars[$config{'char'}]{'party'}}) {
			print	"Error in function 'party kick' (Kick Party Member)\n"
				,"Can't kick member - you're not in a party.\n";
		} elsif ($arg1 eq "kick" && $arg2 eq "") {
			print	"Syntax Error in function 'party kick' (Kick Party Member)\n"
				,"Usage: party kick <party member #>\n";
		} elsif ($arg1 eq "kick" && $partyUsersID[$arg2] eq "") {
			print	"Error in function 'party kick' (Kick Party Member)\n"
				,"Can't kick member - member $arg2 doesn't exist.\n";
		} elsif ($arg1 eq "kick") {
			sendPartyKick(\$remote_socket, $partyUsersID[$arg2]
					,$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$arg2]}{'name'});

		}
	} elsif ($switch eq "petl") {
		$~ = "PETLIST";
		print	"-----------Pet List-----------\n"
			,"#    Type                     Name\n";
		for ($i = 0; $i < @petsID; $i++) {
			next if ($petsID[$i] eq "");
			format PETLIST =
@<<< @<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<
$i,$pets{$petsID[$i]}{'name'},$pets{$petsID[$i]}{'name_given'}
.
			write;
		}
		print "------------------------------\n";

	} elsif ($switch eq "pm") {
		($arg1, $arg2) =$input =~ /^[\s\S]*? "([\s\S]*?)" ([\s\S]*)/;
		$type = 0;
		if (!$arg1) {
			($arg1, $arg2) =$input =~ /^[\s\S]*? (\d+) ([\s\S]*)/;
			$type = 1;
		}
		if ($arg1 eq "" || $arg2 eq "") {
			print	"Syntax Error in function 'pm' (Private Message)\n"
				,qq~Usage: pm ("<username>" | <pm #>) <message>\n~;
		} elsif ($type) {
			if ($arg1 - 1 >= @privMsgUsers) {
				print	"Error in function 'pm' (Private Message)\n"
				,"Quick look-up $arg1 does not exist\n";
			} else {
				sendMessage(\$remote_socket, "pm", $arg2, $privMsgUsers[$arg1 - 1]);
				$lastpm{'msg'} = $arg2;
				$lastpm{'user'} = $privMsgUsers[$arg1 - 1];
			}
		} else {
			if ($arg1 =~ /^%(\d*)$/) {
				$arg1 = $1;
			}
#pml bugfix - chobit andy 20030127
			if (binFind(\@privMsgUsers, $arg1) eq "") {
				$privMsgUsers[@privMsgUsers] = $arg1;
			}
			sendMessage(\$remote_socket, "pm", $arg2, $arg1);
			$lastpm{'msg'} = $arg2;
			$lastpm{'user'} = $arg1;
		}

	} elsif ($switch eq "pml") {
		$~ = "PMLIST";
		print "-----------PM LIST-----------\n";
		for ($i = 1; $i <= @privMsgUsers; $i++) {
			format PMLIST =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<
$i,  $privMsgUsers[$i - 1]
.
			write;
		}
		print "-----------------------------\n";


	} elsif ($switch eq "pl") {
		# Add location information to the list
		my $dPDist;
		$~ = "PLIST";
		print	"-----------Player List-----------\n"
			,"#      Pos   Dist       Name                            Sex    Job         Lv\n";
		for ($i = 0; $i < @playersID; $i++) {
			next if ($playersID[$i] eq "");
			$dPDist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$playersID[$i]}{'pos_to'}});
			if (%{$players{$playersID[$i]}{'guild'}}) {
				$name = "$players{$playersID[$i]}{'name'} [$players{$playersID[$i]}{'guild'}{'name'}]";
			} else {
				$name = $players{$playersID[$i]}{'name'};
			}
			format PLIST =
@<<< @<< @<< @<<<<<     @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<< @<<<<<<<<<< @<
$i,$players{$playersID[$i]}{'pos_to'}{'x'},$players{$playersID[$i]}{'pos_to'}{'y'},$dPDist,$name,$sex_lut{$players{$playersID[$i]}{'sex'}},$jobs_lut{$players{$playersID[$i]}{'jobID'}},$players{$playersID[$i]}{'level'}
.
			write;
		}
		print "---------------------------------\n";

	} elsif ($switch eq "portals") {
		$~ = "PORTALLIST";
		print	"-----------Portal List-----------\n"
			,"#    Name                                Coordinates\n";
		for ($i = 0; $i < @portalsID; $i++) {
			next if ($portalsID[$i] eq "");
			$coords = "($portals{$portalsID[$i]}{'pos'}{'x'},$portals{$portalsID[$i]}{'pos'}{'y'})";
			format PORTALLIST =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<
$i,  $portals{$portalsID[$i]}{'name'},   $coords
.
			write;
		}
		print "---------------------------------\n";

	} elsif ($switch eq "quit") {
		quit();

	} elsif ($switch eq "reload") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		parseReload($arg1);

	} elsif ($switch eq "relog") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
		if ($arg1 eq "") {
			relog("Relogging\n");
		} else {
			$arg1 += int(rand($arg2 + 1)) if ($arg2);
			killConnection(\$remote_socket);
			relog("Disconnect for $arg1 seconds...\n");
			$timeout_ex{'master'}{'time'} = time;
			$timeout_ex{'master'}{'timeout'} = $arg1;
		}

	} elsif ($switch eq "respawn") {
		useTeleport(2);

	} elsif ($switch eq "s") {
		if ($chars[$config{'char'}]{'exp_last'} > $chars[$config{'char'}]{'exp'} && $chars[$config{'char'}]{'exp_max_last'} ne $chars[$config{'char'}]{'exp_max'}) {
			$baseEXPKill = $chars[$config{'char'}]{'exp_max_last'} - $chars[$config{'char'}]{'exp_last'} + $chars[$config{'char'}]{'exp'};
		} elsif ($chars[$config{'char'}]{'exp_last'} == 0 && $chars[$config{'char'}]{'exp_max_last'} == 0) {
			$baseEXPKill = 0;
		} else {
			$baseEXPKill = $chars[$config{'char'}]{'exp'} - $chars[$config{'char'}]{'exp_last'};
		}
		if ($chars[$config{'char'}]{'exp_job_last'} > $chars[$config{'char'}]{'exp_job'} && $chars[$config{'char'}]{'exp_job_max_last'} ne $chars[$config{'char'}]{'exp_job_max'}) {
			$jobEXPKill = $chars[$config{'char'}]{'exp_job_max_last'} - $chars[$config{'char'}]{'exp_job_last'} + $chars[$config{'char'}]{'exp_job'};
		} elsif ($chars[$config{'char'}]{'exp_job_last'} == 0 && $chars[$config{'char'}]{'exp_job_max_last'} == 0) {
			$jobEXPKill = 0;
		} else {
			$jobEXPKill = $chars[$config{'char'}]{'exp_job'} - $chars[$config{'char'}]{'exp_job_last'};
		}
#		$lastBase =
		$hp_string = $chars[$config{'char'}]{'hp'}."/".$chars[$config{'char'}]{'hp_max'}." ("
				.int($chars[$config{'char'}]{'hp'}/$chars[$config{'char'}]{'hp_max'} * 100)
				."%)" if $chars[$config{'char'}]{'hp_max'};
		$sp_string = $chars[$config{'char'}]{'sp'}."/".$chars[$config{'char'}]{'sp_max'}." ("
				.int($chars[$config{'char'}]{'sp'}/$chars[$config{'char'}]{'sp_max'} * 100)
				."%)" if $chars[$config{'char'}]{'sp_max'};
		$base_string = $chars[$config{'char'}]{'exp'}."/".$chars[$config{'char'}]{'exp_max'}." /$baseEXPKill ("
				.sprintf("%.2f",$chars[$config{'char'}]{'exp'}/$chars[$config{'char'}]{'exp_max'} * 100)
				."%)" if $chars[$config{'char'}]{'exp_max'};
		$job_string = $chars[$config{'char'}]{'exp_job'}."/".$chars[$config{'char'}]{'exp_job_max'}." /$jobEXPKill ("
				.sprintf("%.2f",$chars[$config{'char'}]{'exp_job'}/$chars[$config{'char'}]{'exp_job_max'} * 100)
				."%)" if $chars[$config{'char'}]{'exp_job_max'};
		$weight_string = $chars[$config{'char'}]{'weight'}."/".$chars[$config{'char'}]{'weight_max'}." ("
				.int($chars[$config{'char'}]{'weight'}/$chars[$config{'char'}]{'weight_max'} * 100)
				."%)" if $chars[$config{'char'}]{'weight_max'};
		$job_name_string = "$jobs_lut{$chars[$config{'char'}]{'jobID'}} $sex_lut{$chars[$config{'char'}]{'sex'}}";
		print	"-----------Status-----------\n";
		$~ = "STATUS";
		format STATUS =
@<<<<<<<<<<<<<<<<<<<<<<<< HP: @<<<<<<<<<<<<<<<<<<
$chars[$config{'char'}]{'name'},$hp_string
@<<<<<<<<<<<<<<<<<<<<<<<< SP: @<<<<<<<<<<<<<<<<<<
$job_name_string,             $sp_string
Base: @<< @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      $chars[$config{'char'}]{'lv'},$base_string
Job:  @<< @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      $chars[$config{'char'}]{'lv_job'},$job_string
Weight: @>>>>>>>>>>>>>>>> Zenny: @<<<<<<<<<<<<<<
        $weight_string,          $chars[$config{'char'}]{'zenny'}
.
		write;
		# Character status
		print	"-------Special Status-------\n";
		print "Spirits: $chars[$config{'char'}]{'spirits'}\n" if ($chars[$config{'char'}]{'spirits'});
		print "Param1: $messages_lut{'0119_A'}{$chars[$config{'char'}]{'param1'}}\n" if ($chars[$config{'char'}]{'param1'});
		foreach (keys %{$messages_lut{'0119_B'}}) {
			print "Param2: $messages_lut{'0119_B'}{$_}\n" if ($_ & $chars[$config{'char'}]{'param2'});
		}
		foreach (keys %{$messages_lut{'0119_C'}}) {
			print "Param3: $messages_lut{'0119_C'}{$_}\n" if ($_ & $chars[$config{'char'}]{'param3'});
		}
		# Status icon
		foreach (@{$chars[$config{'char'}]{'status'}}) {
			my @messages = split(/::/, $messages_lut{'0196'}{$_});
			print "Status: $messages[1]\n";
		}
		print	"----------------------------\n";

	} elsif ($switch eq "sell") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
		if ($arg1 eq "" && $talk{'buyOrSell'}) {
			sendGetSellList(\$remote_socket, $talk{'ID'});

		} elsif ($arg1 eq "") {
			print	"Syntax Error in function 'sell' (Sell Inventory Item)\n"
				,"Usage: sell <item #> [<amount>]\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"Error in function 'sell' (Sell Inventory Item)\n"
				,"Inventory Item $arg1 does not exist.\n";
		} else {
			if (!$arg2 || $arg2 > $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'}) {
				$arg2 = $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'};
			}
			sendSell(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $arg2);
		}

	} elsif ($switch eq "send") {
		($args) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		sendRaw(\$remote_socket, $args);

	} elsif ($switch eq "sit") {
		$ai_v{'attackAuto_old'} = $config{'attackAuto'};
		$ai_v{'route_randomWalk_old'} = $config{'route_randomWalk'};
		configModify("attackAuto", 1);
		configModify("route_randomWalk", 0);
		aiRemove("move");
		aiRemove("route");
		aiRemove("route_getRoute");
		aiRemove("route_getMapRoute");
		sit();
		$ai_v{'sitAuto_forceStop'} = 0;

	} elsif ($switch eq "sm") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? \d+ \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			print	"Syntax Error in function 'sm' (Use Skill on Monster)\n"
				,"Usage: sm <skill #> <monster #> [<skill lvl>]\n";
		} elsif ($monstersID[$arg2] eq "") {
			print	"Error in function 'sm' (Use Skill on Monster)\n"
				,"Monster $arg2 does not exist.\n";
		} elsif ($skillsID[$arg1] eq "") {
			print	"Error in function 'sm' (Use Skill on Monster)\n"
				,"Skill $arg1 does not exist.\n";
		} else {
			if (!$arg3 || $arg3 > $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'}) {
				$arg3 = $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'};
			}
			if (!ai_getSkillUseType($skillsID[$arg1])) {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $monstersID[$arg2]);
			} else {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $monsters{$monstersID[$arg2]}{'pos_to'}{'x'}, $monsters{$monstersID[$arg2]}{'pos_to'}{'y'});
			}
		}

	} elsif ($switch eq "skills") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		if ($arg1 eq "") {
			$~ = "SKILLS";
			print "----------Skill List-----------\n";
			print "#  Skill Name                    Lv     SP\n";
			for ($i=0; $i < @skillsID; $i++) {
				format SKILLS =
@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<    @<<<
$i,$skills_lut{$skillsID[$i]},$chars[$config{'char'}]{'skills'}{$skillsID[$i]}{'lv'},$skillsSP_lut{$skillsID[$i]}{$chars[$config{'char'}]{'skills'}{$skillsID[$i]}{'lv'}}
.
				write;
			}
			print "\nSkill Points: $chars[$config{'char'}]{'points_skill'}\n";
			print "-------------------------------\n";


		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $skillsID[$arg2] eq "") {
			print	"Error in function 'skills add' (Add Skill Point)\n"
				,"Skill $arg2 does not exist.\n";
		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'points_skill'} < 1) {
			print	"Error in function 'skills add' (Add Skill Point)\n"
				,"Not enough skill points to increase $skills_lut{$skillsID[$arg2]}.\n";
		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/) {
			sendAddSkillPoint(\$remote_socket, $chars[$config{'char'}]{'skills'}{$skillsID[$arg2]}{'ID'});


		} elsif ($arg1 eq "desc" && $arg2 =~ /\d+/ && $skillsID[$arg2] eq "") {
			print	"Error in function 'skills desc' (Skill Description)\n"
				,"Skill $arg2 does not exist.\n";
		} elsif ($arg1 eq "desc" && $arg2 =~ /\d+/) {
			print "===============Skill Description==============\n";
			print "Skill: $skills_lut{$skillsID[$arg2]}\n\n";
			print $skillsDesc_lut{$skillsID[$arg2]};
			print "==============================================\n";
		# Print out Skill - ID reference chart
		} elsif ($arg1 eq "log") {
			my @temp;
			my @output;
			foreach (keys %skillsID_lut) {
				my $msg = $skills_rlut{lc($skillsID_lut{$_})}."#".$skillsID_lut{$_}."#".$_."#";
				if (binFind(\@skillsID, $skills_rlut{lc($skillsID_lut{$_})}) ne "") {
					$temp[$_] = $msg;
				}
			}
			foreach (@temp) {
				next if ($_ eq "");
				push(@output,$_."\n");
			}
			open(FILE,modifingPath("> logs/SkillsList.txt"));
			print FILE @output;
			close(FILE);
		} else {
			print	"Syntax Error in function 'skills' (Skills Functions)\n"
				,"Usage: skills [<add | desc | log>] [<skill #>]\n";
		}


	} elsif ($switch eq "sp") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? \d+ \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			print	"Syntax Error in function 'sp' (Use Skill on Player)\n"
				,"Usage: sp <skill #> <player #> [<skill lvl>]\n";
		} elsif ($playersID[$arg2] eq "") {
			print	"Error in function 'sp' (Use Skill on Player)\n"
				,"Player $arg2 does not exist.\n";
		} elsif ($skillsID[$arg1] eq "") {
			print	"Error in function 'sp' (Use Skill on Player)\n"
				,"Skill $arg1 does not exist.\n";
		} else {
			if (!$arg3 || $arg3 > $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'}) {
				$arg3 = $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'};
			}
			if (!ai_getSkillUseType($skillsID[$arg1])) {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $playersID[$arg2]);
			} else {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $players{$playersID[$arg2]}{'pos_to'}{'x'}, $players{$playersID[$arg2]}{'pos_to'}{'y'});
			}
		}

	} elsif ($switch eq "ss") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'ss' (Use Skill on Self)\n"
				,"Usage: ss <skill #> [<skill lvl>]\n";
		} elsif ($skillsID[$arg1] eq "") {
			print	"Error in function 'ss' (Use Skill on Self)\n"
				,"Skill $arg1 does not exist.\n";
		} else {
			if (!$arg2 || $arg2 > $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'}) {
				$arg2 = $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'};
			}
			if (!ai_getSkillUseType($skillsID[$arg1])) {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg2, 0,0, $accountID);
			} else {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg2, 0,0, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
			}
		}

	} elsif ($switch eq "st") {
		print	"-----------Char Stats-----------\n";
		$~ = "STATS";
		$tilde = "~";
		format STATS =
Str: @<<+@<< #@< Atk:  @<<+@<< Def:  @<<+@<<
$chars[$config{'char'}]{'str'},$chars[$config{'char'}]{'str_bonus'},$chars[$config{'char'}]{'points_str'},$chars[$config{'char'}]{'attack'},$chars[$config{'char'}]{'attack_bonus'},$chars[$config{'char'}]{'def'},$chars[$config{'char'}]{'def_bonus'}
Agi: @<<+@<< #@< Matk: @<<@@<< Mdef: @<<+@<<
$chars[$config{'char'}]{'agi'},$chars[$config{'char'}]{'agi_bonus'},$chars[$config{'char'}]{'points_agi'},$chars[$config{'char'}]{'attack_magic_min'},$tilde,$chars[$config{'char'}]{'attack_magic_max'},$chars[$config{'char'}]{'def_magic'},$chars[$config{'char'}]{'def_magic_bonus'}
Vit: @<<+@<< #@< Hit:  @<<     Flee: @<<+@<<
$chars[$config{'char'}]{'vit'},$chars[$config{'char'}]{'vit_bonus'},$chars[$config{'char'}]{'points_vit'},$chars[$config{'char'}]{'hit'},$chars[$config{'char'}]{'flee'},$chars[$config{'char'}]{'flee_bonus'}
Int: @<<+@<< #@< Critical: @<< Aspd: @<<
$chars[$config{'char'}]{'int'},$chars[$config{'char'}]{'int_bonus'},$chars[$config{'char'}]{'points_int'},$chars[$config{'char'}]{'critical'},$chars[$config{'char'}]{'attack_speed'}
Dex: @<<+@<< #@< Status Points: @<<
$chars[$config{'char'}]{'dex'},$chars[$config{'char'}]{'dex_bonus'},$chars[$config{'char'}]{'points_dex'},$chars[$config{'char'}]{'points_free'}
Luk: @<<+@<< #@< Guild: @<<<<<<<<<<<<<<<<<<<<<
$chars[$config{'char'}]{'luk'},$chars[$config{'char'}]{'luk_bonus'},$chars[$config{'char'}]{'points_luk'},$chars[$config{'char'}]{'guild'}{'name'}
.
		write;
		print	"--------------------------------\n";

	} elsif ($switch eq "stand") {
		if ($ai_v{'attackAuto_old'} ne "") {
			configModify("attackAuto", $ai_v{'attackAuto_old'});
			configModify("route_randomWalk", $ai_v{'route_randomWalk_old'});
		}
		stand();
		$ai_v{'sitAuto_forceStop'} = 1;

	} elsif ($switch eq "stat_add") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)$/;
		if ($arg1 ne "str" &&  $arg1 ne "agi" && $arg1 ne "vit" && $arg1 ne "int"
			&& $arg1 ne "dex" && $arg1 ne "luk") {
			print	"Syntax Error in function 'stat_add' (Add Status Point)\n"
			,"Usage: stat_add <str | agi | vit | int | dex | luk>\n";
		} else {
			if ($arg1 eq "str") {
				$ID = 0x0D;
			} elsif ($arg1 eq "agi") {
				$ID = 0x0E;
			} elsif ($arg1 eq "vit") {
				$ID = 0x0F;
			} elsif ($arg1 eq "int") {
				$ID = 0x10;
			} elsif ($arg1 eq "dex") {
				$ID = 0x11;
			} elsif ($arg1 eq "luk") {
				$ID = 0x12;
			}
			if ($chars[$config{'char'}]{"points_$arg1"} > $chars[$config{'char'}]{'points_free'}) {
				print	"Error in function 'stat_add' (Add Status Point)\n"
					,"Not enough status points to increase $arg1\n";
			} else {
				$chars[$config{'char'}]{$arg1} += 1;
				sendAddStatusPoint(\$remote_socket, $ID);
			}
		}

	} elsif ($switch eq "storage") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? \w+ \d+ (\d+)/;
		if ($arg1 eq "") {
			$~ = "STORAGELIST";
			print "----------Storage-----------\n";
			print "#  Name\n";
			for ($i=0; $i < @{$storage{'inventory'}};$i++) {
				next if (!%{$storage{'inventory'}[$i]});
				$display = "$storage{'inventory'}[$i]{'name'} x $storage{'inventory'}[$i]{'amount'}";
				format STORAGELIST =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $display
.
				write;
			}
			print "\nCapacity: $storage{'items'}/$storage{'items_max'}\n";
			print "----------------------------\n";


		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'inventory'}[$arg2] eq "") {
			print	"Error in function 'storage add' (Add Item to Storage)\n"
				,"Inventory Item $arg2 does not exist\n";
		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/) {
			if (!$arg3 || $arg3 > $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'}) {
				$arg3 = $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'};
			}
			sendStorageAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg2]{'index'}, $arg3);

		} elsif ($arg1 eq "get" && $arg2 =~ /\d+/ && !%{$storage{'inventory'}[$arg2]}) {
			print	"Error in function 'storage get' (Get Item from Storage)\n"
				,"Storage Item $arg2 does not exist\n";
		} elsif ($arg1 eq "get" && $arg2 =~ /\d+/) {
			if (!$arg3 || $arg3 > $storage{'inventory'}[$arg2]{'amount'}) {
				$arg3 = $storage{'inventory'}[$arg2]{'amount'};
			}
			sendStorageGet(\$remote_socket, $arg2, $arg3);

		} elsif ($arg1 eq "close") {
			sendStorageClose(\$remote_socket);

		} else {
			print	"Syntax Error in function 'storage' (Storage Functions)\n"
				,"Usage: storage [<add | get | close>] [<inventory # | storage #>] [<amount>]\n";
		}

	} elsif ($switch eq "store") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		if ($arg1 eq "" && !$talk{'buyOrSell'}) {
			$~ = "STORELIST";
			print "----------Store List-----------\n";
			print "#  Name                    Type           Price\n";
			for ($i=0; $i < @storeList;$i++) {
				$display = $storeList[$i]{'name'};
				format STORELIST =
@< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<< @>>>>>>>z
$i,$display,$itemTypes_lut{$storeList[$i]{'type'}},$storeList[$i]{'price'}
.
				write;
			}
			print "-------------------------------\n";
		} elsif ($arg1 eq "" && $talk{'buyOrSell'}) {
			sendGetStoreList(\$remote_socket, $talk{'ID'});

		} elsif ($arg1 eq "desc" && $arg2 =~ /\d+/ && $storeList[$arg2] eq "") {
			print	"Error in function 'store desc' (Store Item Description)\n"
				,"Usage: Store item $arg2 does not exist\n";
		} elsif ($arg1 eq "desc" && $arg2 =~ /\d+/) {
			printItemDesc($storeList[$arg2]);

		} else {
			print	"Syntax Error in function 'store' (Store Functions)\n"
				,"Usage: store [<desc>] [<store item #>]\n";

		}

	} elsif ($switch eq "take") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)$/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'take' (Take Item)\n"
				,"Usage: take <item #>\n";
		} elsif ($itemsID[$arg1] eq "") {
			print	"Error in function 'take' (Take Item)\n"
				,"Item $arg1 does not exist.\n";
		} else {
			take($itemsID[$arg1]);
		}


	} elsif ($switch eq "talk") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)/;

		if ($arg1 =~ /^\d+$/ && $npcsID[$arg1] eq "") {
			print	"Error in function 'talk' (Talk to NPC)\n"
				,"NPC $arg1 does not exist\n";
		} elsif ($arg1 =~ /^\d+$/) {
			sendTalk(\$remote_socket, $npcsID[$arg1]);

		} elsif ($arg1 eq "resp" && !%talk) {
			print	"Error in function 'talk resp' (Respond to NPC)\n"
				,"You are not talking to any NPC.\n";
		} elsif ($arg1 eq "resp" && $arg2 eq "") {
			$display = $npcs{$talk{'nameID'}}{'name'};
			$~ = "RESPONSES";
			print "----------Responses-----------\n";
			print "NPC: $display\n";
			print "#  Response\n";
			for ($i=0; $i < @{$talk{'responses'}};$i++) {
				format RESPONSES =
@< @<<<<<<<<<<<<<<<<<<<<<<
$i,$talk{'responses'}[$i]
.
				write;
			}
			print "------------------------------\n";
		} elsif ($arg1 eq "resp" && $arg2 ne "" && $talk{'responses'}[$arg2] eq "") {
			print	"Error in function 'talk resp' (Respond to NPC)\n"
				,"Response $arg2 does not exist.\n";
		} elsif ($arg1 eq "resp" && $arg2 ne "") {
			if ($talk{'responses'}[$arg2] eq "Cancel Chat") {
				$arg2 = 255;
			} else {
				$arg2 += 1;
			}
			sendTalkResponse(\$remote_socket, $talk{'ID'}, $arg2);


		} elsif ($arg1 eq "cont" && !%talk) {
			print	"Error in function 'talk cont' (Continue Talking to NPC)\n"
				,"You are not talking to any NPC.\n";
		} elsif ($arg1 eq "cont") {
			sendTalkContinue(\$remote_socket, $talk{'ID'});


		} elsif ($arg1 eq "no" && $arg2 ne "") {
			sendTalkCancel(\$remote_socket, pack("L1", $arg2));
		} elsif ($arg1 eq "no") {
			sendTalkCancel(\$remote_socket, $talk{'ID'});


		} else {
			print	"Syntax Error in function 'talk' (Talk to NPC)\n"
				,"Usage: talk <NPC # | cont | resp> [<response #>]\n";
		}


	} elsif ($switch eq "tank") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'tank' (Tank for a Player)\n"
				,"Usage: tank <player #>\n";
		} elsif ($arg1 eq "stop") {
			configModify("tankMode", 0);
		} elsif ($playersID[$arg1] eq "") {
			print	"Error in function 'tank' (Tank for a Player)\n"
				,"Player $arg1 does not exist.\n";
		} else {
			configModify("tankMode", 1);
			configModify("tankModeTarget", $players{$playersID[$arg1]}{'name'});
		}

	} elsif ($switch eq "tele") {
		useTeleport(1);

	} elsif ($switch eq "timeout") {
		($arg1, $arg2) = $input =~ /^[\s\S]*? ([\s\S]*) ([\s\S]*?)$/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'timeout' (set a timeout)\n"
				,"Usage: timeout <type> [<seconds>]\n";
		} elsif ($timeout{$arg1} eq "") {
			print	"Error in function 'timeout' (set a timeout)\n"
				,"Timeout $arg1 doesn't exist\n";
		} elsif ($arg2 eq "") {
			print "Timeout '$arg1' is $config{$arg1}\n";
		} else {
			setTimeout($arg1, $arg2);
		}


	} elsif ($switch eq "uneq") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "") {
			print	"Syntax Error in function 'unequip' (Unequip Inventory Item)\n"
				,"Usage: unequip <item #>\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"Error in function 'unequip' (Unequip Inventory Item)\n"
				,"Inventory Item $arg1 does not exist.\n";
		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'equipped'} eq "") {
			print	"Error in function 'unequip' (Unequip Inventory Item)\n"
				,"Inventory Item $arg1 is not equipped.\n";
		} else {
			sendUnequip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'});
		}

	} elsif ($switch eq "where") {
		($map_string) = $map_name =~ /([\s\S]*)\.gat/;
		print "Location $maps_lut{$map_string.'.rsw'}($map_string) : $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'}\n";
		# Map viewer
		undef $ai_v{'map_refresh'}{'time'};

	} elsif ($switch eq "who") {
		sendWho(\$remote_socket);
	# Show AI sequence
	} elsif ($switch eq "ai") {
		my $stuff1 = join(" ", @ai_seq);
		my $stuff2 = @ai_seq_args;
		print "AI: $stuff1 | $stuff2\n";
	#Aggressive Monster List
	} elsif ($switch eq "aml") {
		undef $dMDist;
		$~ = "MLIST";
		print	"----- AggressiveMonster List -----\n"
			,"#     Pos    Dist    Name                      DmgTo  DmgFrm  AA TA\n";
		for ($i = 0; $i < @monstersID; $i++) {
			next if ($monstersID[$i] eq "");
			$dMDist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$monstersID[$i]}{'pos_to'}});
			$dmgTo = ($monsters{$monstersID[$i]}{'dmgFromYou'} ne "")
				? $monsters{$monstersID[$i]}{'dmgFromYou'}
				: 0;
			$dmgFrom = ($monsters{$monstersID[$i]}{'dmgToYou'} ne "")
				? $monsters{$monstersID[$i]}{'dmgToYou'}
				: 0;
			write if ($dmgFrom || $monsters{$monstersID[$i]}{'missedYou'});
		}
		print "----------------------------------\n";
	# Make arrow
	} elsif ($switch eq "arrow") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "") {
			$~ = "ARROWMAKING";
			print	"-------Arrow Making List------\n";
			for ($i = 0; $i < @arrowID; $i++) {
				next if ($arrowID[$i] eq "");
				format ARROWMAKING =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i,  $items_lut{$arrowID[$i]}
.
				write;
			}
			print	"------------------------------\n";
		} elsif ($arg1 =~ /\d+/ && $arrowID[$arg1] eq "") {
			print	"Error in function 'arrow' (Make Arrow)\n"
				,"Arrow making option #$arg1 does not exist\n";

		} elsif ($arg1 =~ /\d+/) {
			sendArrowMake(\$remote_socket, $arrowID[$arg1]);
		} else {
			print	"Syntax Error in function 'arrow' (Make Arrow)\n"
				,"Usage: arrow [<arrow #>]\n";
		}
	# Force return base
	} elsif ($switch eq "base") {
		unshift @ai_seq, "healAuto";
		unshift @ai_seq_args, {};
	# Do Perl script files
	} elsif ($switch eq "do" && $config{'debug_checksum'} eq $checksum) {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		undef $!;
		undef $@;
		do $arg1;
		print "Error: $!\n" if ($! ne "");
		print "Syntax error: $@\n" if ($@ ne "");
	# Eval Perl script commands
	} elsif ($switch eq "eval" && $config{'debug_checksum'} eq $checksum) {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		undef $@;
		eval $arg1;
		print "Syntax error: $@\n" if ($@ ne "");
	# EXPs gained per hour
	} elsif ($switch eq "exp") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		if ($arg1 eq "") {
			$endTime_EXP = time;
			$w_hour = 0;
			$w_min = 0;
			$w_sec = int($endTime_EXP - $startTime_EXP);
			$bExpPerHour = int($totalBaseExp * 3600 / $w_sec);
			$jExpPerHour = int($totalJobExp * 3600 / $w_sec);
			if ($w_sec >= 3600) {
				$w_hour = int($w_sec / 3600);
				$w_sec %= 3600;
			}
			if ($w_sec >= 60) {
				$w_min = int($w_sec / 60);
				$w_sec %= 60;
			}
			print "--------------EXP/Hour-------------\n";
			printf("PlayTime : %dh %dm %ds\n", $w_hour, $w_min, $w_sec);
			print "TotalBaseExp: $totalBaseExp\n";
			print "TotalJobExp : $totalJobExp\n";
			print "BaseExp/Hour: $bExpPerHour\n";
			print "JobExp/Hour : $jExpPerHour\n";
			# Defeated monster list
			my @defeatKey = keys(%defeatMonster);
			$~ = "DEFEAT";
			format DEFEAT =
@<<<<<<<<<<<<<<<<<<<<<<<<  x@>>>>
$defeatMonsterName,         $defeatMonsterNum
.
			print "------ Defeated Monster List ------\n";
			foreach (@defeatKey) {
				$defeatMonsterName = $_;
				$defeatMonsterNum = $defeatMonster{$_};
				write;
			}
			# Rare item got list
			my @rareItemKey = keys(%rareItemGet);
			print "-------- Rare Item Got List -------\n";
			foreach (@rareItemKey) {
				$defeatMonsterName = $_;
				$defeatMonsterNum = $rareItemGet{$_};
				write;
			}
			print "-----------------------------------\n";
		} elsif ($arg1 eq "log") {
			open(EXPLOG,modifingPath(">> logs/ExpLog.txt"));
			select(EXPLOG);
			print "*** [", getFormattedDate(int($startTime_EXP)), " -> ", getFormattedDate(int(time)), "] ***\n";
			print "*** [$servers[$config{'server'}]{'name'} - $chars[$config{'char'}]{'name'}";
			if ($config{'lockMap'}) {
				print " - $config{'lockMap'}] ***\n";
			} else {
				print "] ***\n";
			}
			close(EXPLOG);
			logCommand(">> logs/ExpLog.txt","exp");
		} elsif ($arg1 eq "reset") {
			$totalBaseExp = 0;
			$totalJobExp = 0;
			$bExpPerHour = 0;
			$jExpPerHour = 0;
			$startTime_EXP = time;
			$ai_v{'recordEXP_time'} = time;
			# Defeated monster list
			undef %defeatMonster;
			# Rare item got list
			undef %rareItemGet;
		} else {
			print "Syntax Error in function 'exp' (Show exp earning speed)\n";
			print "Usage: exp [<reset | log>]\n";
		}
	# Guild related
	} elsif ($switch eq "guild") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		my $ID = $chars[$config{'char'}]{'guild'}{'ID'};
		if ($arg1 eq "") {
			print "---------- Guild Information ----------\n";
			$~ = "GUILD";
			format GUILD =
Name    : @<<<<<<<<<<<<<<<<<<<<<<<<
          $guild{$ID}{'name'}
Lv      : @>>
          $guild{$ID}{'lvl'}
Exp     : @>>>>>>>>/@>>>>>>>>
          $guild{$ID}{'exp'},$guild{$ID}{'next_exp'}
Master  : @<<<<<<<<<<<<<<<<<<<<<<<<
          $guild{$ID}{'master'}
Connect : @>>>/@>>>
          $guild{$ID}{'conMember'},$guild{$ID}{'maxMember'}
.
		write;
#			print "------------ Aliance Guild ------------\n";
#			print "------------  Rival Guild  ------------\n";
			print "---------------------------------------\n";
		} elsif ($arg1 eq "member") {
			print "------------ Guild  Member ------------\n";
			print "Name                     Job        Lv Title                 Online\n";
			$~ = "GM";
			format GM =
@<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<< @> @<<<<<<<<<<<<<<<<<<<<<<< @>>
$name,$job,$lvl,$title,$online
.
			for ($i = 0; $i < $guild{$ID}{'members'}; $i++) {
				$name  = $guild{$ID}{'member'}[$i]{'name'};
				$job   = $jobs_lut{$guild{$ID}{'member'}[$i]{'jobID'}};
				$lvl   = $guild{$ID}{'member'}[$i]{'lvl'};
				$title = $guild{$ID}{'title'}[$guild{$ID}{'member'}[$i]{'title'}];
				$online = $guild{$ID}{'member'}[$i]{'online'} ? "Yes" : "No";
				write;
			}
			print "---------------------------------------\n";
		} elsif ($arg1 eq "join" && $arg2 ne "1" && $arg2 ne "0") {
			print	"Syntax Error in function 'guild join' (Accept/Deny Guild Join Request)\n"
				,"Usage: guild join <flag>\n";
		} elsif ($arg1 eq "join" && $incomingGuild{'ID'} eq "") {
			print	"Error in function 'guild join' (Join/Request to Join Guild)\n"
				,"Can't accept/deny guild request - no incoming request.\n";
		} elsif ($arg1 eq "join") {
			sendGuildJoin(\$remote_socket, $incomingGuild{'ID'}, $arg2);
			undef %incomingGuild;
		} elsif ($arg1 eq "request" && !%{$chars[$config{'char'}]{'guild'}}) {
			print	"Error in function 'guild request' (Request to Join Guild)\n"
				,"Can't request a join - you're not in a guild.\n";
		} elsif ($arg1 eq "request" && $playersID[$arg2] eq "") {
			print	"Error in function 'guild request' (Request to Join Guild)\n"
				,"Can't request to join guild - player $arg2 does not exist.\n";
		} elsif ($arg1 eq "request") {
			sendGuildJoinRequest(\$remote_socket, $playersID[$arg2]);
		}
	# Log command outputs
	} elsif ($switch eq "log") {
		($arg1) = $input =~ /^[\s\S]*? "([\s\S]*?)"/;
		($arg2) = $input =~ /^[\s\S]*? "[\s\S]*?" (\w+)/;
		$arg2 = "CmdLog" if ($arg2 eq "");
		if ($arg1 ne "") {
			logCommand(">> logs/".$arg2.".txt",$arg1);
		} else {
			print	"Syntax Error in function 'log' (Log Command)\n"
				,qq~Usage: log "<command>" <output filename>\n~;
		}
	# Suspend AI function
	} elsif ($switch eq "pause") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 > 0) {
			ai_clientSuspend(0, $arg1);
		} else {
			print	"Syntax Error in function 'pause' (Suspend AI Function)\n"
				,qq~Usage: pause <seconds>\n~;
		}
	# pet command
	} elsif ($switch eq "pet") {
		if ($chars[$config{'char'}]{'pet'}{'name_given'} ne "") {
			($arg1) = $input =~ /^[\s\S]*? (\w+)/;
			if ($arg1 eq "") {
				print "----- Pet Status -----\n";
				print "Name     : $chars[$config{'char'}]{'pet'}{'name_given'}";
				if ($chars[$config{'char'}]{'pet'}{'modified'}) {
					print " modified\n";
				} else {
					print " not modified\n";
				}
				print "Lv       : $chars[$config{'char'}]{'pet'}{'lvl'}\n";
				print "Hunger   : $chars[$config{'char'}]{'pet'}{'hunger'}\n";
				print "Intimate : $chars[$config{'char'}]{'pet'}{'intimate'}\n";
				print "Accessory: $items_lut{$chars[$config{'char'}]{'pet'}{'accessory'}}\n";
				print "----------------------\n";
			} elsif ($arg1 eq "food") {
				my $petfood = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'petAutoFood'});
				if ($petfood ne "") {
					sendPetCommand(\$remote_socket, 1);
					print "Feeding the pet with : $config{'petAutoFood'}\n";
				} else {
					print "You can't give the feed : $config{'petAutoFood'}\n";
				}
			} elsif ($arg1 eq "show") {
				sendPetCommand(\$remote_socket, 2);
			} elsif ($arg1 eq "return") {
				sendPetCommand(\$remote_socket, 3);
				undef %{$chars[$config{'char'}]{'pet'}};
				print "Returning the pet to egg\n";
			} else {
				print "Syntax Error in function 'pet' (Pet related command)\n";
				print "Usage: pet [<food|show|return>]\n";
			}
		} else {
			print "Error in function 'pet' (Pet related command)\n";
			print "You must have a pet to use this function\n";
		}
	# Make potion
	} elsif ($switch eq "potion") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "") {
			$~ = "PHARMACY";
			print	"-------Potion Making List------\n";
			for ($i = 0; $i < @pharmacyID; $i++) {
				next if ($pharmacyID[$i] eq "");
				format PHARMACY =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $items_lut{$pharmacyID[$i]}
.
				write;
			}
			print	"-------------------------------\n";
		} elsif ($arg1 =~ /\d+/ && $pharmacyID[$arg1] eq "") {
			print	"Error in function 'potion' (Make Potion)\n"
				,"Potion making option #$arg1 does not exist\n";

		} elsif ($arg1 =~ /\d+/) {
			sendPharmacy(\$remote_socket, $pharmacyID[$arg1]);
		} else {
			print	"Syntax Error in function 'potion' (Make Potion)\n"
				,"Usage: potion [<potion #>]\n";
		}
	# vender related
	} elsif ($switch eq "shop") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? \w+ \d+ (\d+)/;
		if ($arg1 eq "close") {
			if ($shop{'opened'}) {
				$shop{'opened'} = 0;
				sendCloseShop(\$remote_socket);
			} else {
				print	"Error in function 'shop' (Vender related functions)\n"
					,"You haven't open the vender yet\n";
			}
		} elsif ($arg1 eq "open") {
			if (!$shop{'opened'} && $shop{'maxItems'}) {
				sendOpenShop(\$remote_socket);
			} else {
				print	"Error in function 'shop' (Vender related functions)\n"
					,"You either already opened the vender, or forgot to use the skill\n";
			}
		} elsif ($arg1 eq "list") {
			if ($shop{'opened'}) {
				$~ = "ARTICLESREMAINLIST";
				print "-------- Your Shop --------\n";
				print "#  Name                                     Type        Amount Price  z   Sold\n";
				for ($i = 0; $i < @articles; $i++) {
					format ARTICLESREMAINLIST =
@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<  @>>>> @>>>>>>>>z @>>>>
$i,$articles[$i]{'name'},$itemTypes_lut{$articles[$i]{'type'}},$articles[$i]{'amount'},$articles[$i]{'price'},$articles[$i]{'sold'}
.
					write if ($articles[$i]{'index'} ne "");
				}
				print "---------------------------\n";
				print "You have earned $shop{'earned'}z.\n";
			} else {
				print	"Error in function 'shop' (Vender related functions)\n"
					,"You must open your shop first\n";
			}
		} elsif ($arg1 eq "enter") {
			if ($venderListID[$arg2] ne "") {
				print "Entering vender : $venderList{$venderListID[$arg2]}{'title'} ...\n";
				$enterShopID = $venderListID[$arg2];
				sendEnteringShop(\$remote_socket, $venderListID[$arg2]);
			} else {
				print	"Error in function 'shop' (Vender related functions)\n"
					,"Shop number $arg2 is not exists\n";
			}
		} elsif ($arg1 eq "buy") {
			if ($enterShopID ne "") {
				if ($venderItemList[$arg2]{'name'} eq "") {
					print	"Error in function 'shop' (Vender related functions)\n"
						,"Item number $arg2 is not exists\n";
				} else {
					if ($arg3 eq "") {
						$amount = 1;
					} else {
						$amount = $arg3;
					}
					print "Buying : $venderItemList[$arg2]{'name'} x $amount from $venderList{$enterShopID}{'title'}\n";
					sendBuyFromShop(\$remote_socket, $enterShopID, $amount, $arg2);
				}
			} else {
				print	"Error in function 'shop' (Vender related functions)\n"
					,"You must enter a shop before buying items\n";
			}
		} else {
			$~ = "VLIST";
			print "-------- Vender List --------\n";
			print "#  Title                                               Owner\n";
			for ($i = 0; $i < @venderListID; $i++) {
				next if ($venderListID[$i] eq "");
				$owner = ($venderListID[$i] ne $accountID) ? $players{$venderListID[$i]}{'name'} : $chars[$config{'char'}]{'name'};
				format VLIST =
@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<
$i,$venderList{$venderListID[$i]}{'title'},$owner
.
				write;
			}
			print "-----------------------------\n";
		}
	# Locational Skill List
	} elsif ($switch eq "sl") {
		my $dSDist;
		$~ = "SLIST";
		print	"----- Locational Skill List -----\n"
			,"#      Pos     Dist         Owner                           Type\n";
		for ($i = 0; $i < @spellsID; $i++) {
			next if ($spellsID[$i] eq "");
			$dSDist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$spells{$spellsID[$i]}{'pos'}});
			if ($spells{$spellsID[$i]}{'sourceID'} eq $accountID) {
				$name = "You";
			} elsif (%{$monsters{$spells{$spellsID[$i]}{'sourceID'}}}) {
				$name = "$monsters{$spells{$spellsID[$i]}{'sourceID'}}{'name'} ($monsters{$spells{$spellsID[$i]}{'sourceID'}}{'binID'})";
			} elsif (%{$players{$spells{$spellsID[$i]}{'sourceID'}}}) {
				$name = "$players{$spells{$spellsID[$i]}{'sourceID'}}{'name'} ($players{$spells{$spellsID[$i]}{'sourceID'}}{'binID'})";
			} else {
				$name = "Unknown ".getHex($spells{$spellsID[$i]}{'sourceID'});
			}
			$display = ($messages_lut{'011F'}{$spells{$spellsID[$i]}{'type'}} ne "")
				? $messages_lut{'011F'}{$spells{$spellsID[$i]}{'type'}}
				: "Unknown ".$spells{$spellsID[$i]}{'type'};
			format SLIST =
@<<< @<<< @<<< @<<<<<       @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<
$i,$spells{$spellsID[$i]}{'pos'}{'x'},$spells{$spellsID[$i]}{'pos'}{'y'},$dSDist,$name,$display
.
			write;
		}
		print "---------------------------------\n";
	# Auto spell
	} elsif ($switch eq "spell") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "") {
			$~ = "AUTOSPELL";
			print	"-------Auto Casting List------\n";
			for ($i = 0; $i < @autospellID; $i++) {
				next if ($autospellID[$i] eq "");
				format AUTOSPELL =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $skillsID_lut{$autospellID[$i]}
.
				write;
			}
			print	"------------------------------\n";
		} elsif ($arg1 =~ /\d+/ && $autospellID[$arg1] eq "") {
			print	"Error in function 'spell' (Auto Spell Cast)\n"
				,"Auto casting option #$arg1 does not exist\n";

		} elsif ($arg1 =~ /\d+/) {
			sendAutospell(\$remote_socket, $autospellID[$arg1]);
		} else {
			print	"Syntax Error in function 'spell' (Auto Spell Cast)\n"
				,"Usage: spell [<autospell #>]\n";
		}
	} elsif ($switch eq "ver") {
		print $versionText;
	}
}







#######################################
#######################################
#AI
#######################################
#######################################



sub AI {
	my ($i, $j);
	my %cmd = %{(shift)};
	if (%cmd) {
		$responseVars{'cmd_user'} = $cmd{'user'};
		if ($cmd{'user'} eq $chars[$config{'char'}]{'name'}) {
			return;
		}
 		if ($cmd{'type'} eq "pm" || $cmd{'type'} eq "p" || $cmd{'type'} eq "g") {
			$ai_v{'temp'}{'qm'} = quotemeta $config{'adminPassword'};
			if ($cmd{'msg'} =~ /^$ai_v{'temp'}{'qm'}\b/) {
				if ($overallAuth{$cmd{'user'}} == 1) {
					sendMessage(\$remote_socket, "pm", getResponse("authF"), $cmd{'user'});
				} else {
					auth($cmd{'user'}, 1);
					sendMessage(\$remote_socket, "pm", getResponse("authS"),$cmd{'user'});
				}
			}
		}
		$ai_v{'temp'}{'qm'} = quotemeta $config{'callSign'};
		if ($overallAuth{$cmd{'user'}} >= 1
			&& ($cmd{'msg'} =~ /\b$ai_v{'temp'}{'qm'}\b/i || $cmd{'type'} eq "pm")) {
			if ($cmd{'msg'} =~ /\bsit\b/i) {
				$ai_v{'sitAuto_forceStop'} = 0;
				$ai_v{'attackAuto_old'} = $config{'attackAuto'};
				$ai_v{'route_randomWalk_old'} = $config{'route_randomWalk'};
				configModify("attackAuto", 1);
				configModify("route_randomWalk", 0);
				aiRemove("move");
				aiRemove("route");
				aiRemove("route_getRoute");
				aiRemove("route_getMapRoute");
				sit();
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("sitS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;
			} elsif ($cmd{'msg'} =~ /\bstand\b/i) {
				$ai_v{'sitAuto_forceStop'} = 1;
				if ($ai_v{'attackAuto_old'} ne "") {
					configModify("attackAuto", $ai_v{'attackAuto_old'});
					configModify("route_randomWalk", $ai_v{'route_randomWalk_old'});
				}
				stand();
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("standS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;
			} elsif ($cmd{'msg'} =~ /\brelog\b/i) {
				relog("Relogging\n");
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("relogS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;
			} elsif ($cmd{'msg'} =~ /\blogout\b/i) {
				quit();
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("quitS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;
			} elsif ($cmd{'msg'} =~ /\breload\b/i) {
				parseReload($');
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("reloadS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;
			} elsif ($cmd{'msg'} =~ /\bstatus\b/i) {
				$responseVars{'char_sp'} = $chars[$config{'char'}]{'sp'};
				$responseVars{'char_hp'} = $chars[$config{'char'}]{'hp'};
				$responseVars{'char_sp_max'} = $chars[$config{'char'}]{'sp_max'};
				$responseVars{'char_hp_max'} = $chars[$config{'char'}]{'hp_max'};
				$responseVars{'char_lv'} = $chars[$config{'char'}]{'lv'};
				$responseVars{'char_lv_job'} = $chars[$config{'char'}]{'lv_job'};
				$responseVars{'char_exp'} = $chars[$config{'char'}]{'exp'};
				$responseVars{'char_exp_max'} = $chars[$config{'char'}]{'exp_max'};
				$responseVars{'char_exp_job'} = $chars[$config{'char'}]{'exp_job'};
				$responseVars{'char_exp_job_max'} = $chars[$config{'char'}]{'exp_job_max'};
				$responseVars{'char_weight'} = $chars[$config{'char'}]{'weight'};
				$responseVars{'char_weight_max'} = $chars[$config{'char'}]{'weight_max'};
				$responseVars{'zenny'} = $chars[$config{'char'}]{'zenny'};
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("statusS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;
			} elsif ($cmd{'msg'} =~ /\bconf\b/i) {
				$ai_v{'temp'}{'after'} = $';
				($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}) = $ai_v{'temp'}{'after'} =~ /(\w+) (\w+)/;
				@{$ai_v{'temp'}{'conf'}} = keys %config;
				if ($ai_v{'temp'}{'arg1'} eq "") {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confF1"), $cmd{'user'}) if $config{'verbose'};
				} elsif (binFind(\@{$ai_v{'temp'}{'conf'}}, $ai_v{'temp'}{'arg1'}) eq "") {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confF2"), $cmd{'user'}) if $config{'verbose'};
				} elsif ($ai_v{'temp'}{'arg2'} eq "value") {
					if ($ai_v{'temp'}{'arg1'} =~ /username/i || $ai_v{'temp'}{'arg1'} =~ /password/i) {
						sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confF3"), $cmd{'user'}) if $config{'verbose'};
					} else {
						$responseVars{'key'} = $ai_v{'temp'}{'arg1'};
						$responseVars{'value'} = $config{$ai_v{'temp'}{'arg1'}};
						sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confS1"), $cmd{'user'}) if $config{'verbose'};
						$timeout{'ai_thanks_set'}{'time'} = time;
					}
				} else {
					configModify($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'});
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confS2"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				}
			} elsif ($cmd{'msg'} =~ /\btimeout\b/i) {
				$ai_v{'temp'}{'after'} = $';
				($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}) = $ai_v{'temp'}{'after'} =~ /([\s\S]+) (\w+)/;
				if ($ai_v{'temp'}{'arg1'} eq "") {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("timeoutF1"), $cmd{'user'}) if $config{'verbose'};
				} elsif ($timeout{$ai_v{'temp'}{'arg1'}} eq "") {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("timeoutF2"), $cmd{'user'}) if $config{'verbose'};
				} elsif ($ai_v{'temp'}{'arg2'} eq "") {
					$responseVars{'key'} = $ai_v{'temp'}{'arg1'};
					$responseVars{'value'} = $timeout{$ai_v{'temp'}{'arg1'}};
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("timeoutS1"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					setTimeout($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'});
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("timeoutS2"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				}
			} elsif ($cmd{'msg'} =~ /\bshut[\s\S]*up\b/i) {
				if ($config{'verbose'}) {
					configModify("verbose", 0);
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("verboseOffS"), $cmd{'user'});
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("verboseOffF"), $cmd{'user'});
				}
			} elsif ($cmd{'msg'} =~ /\bspeak\b/i) {
				if (!$config{'verbose'}) {
					configModify("verbose", 1);
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("verboseOnS"), $cmd{'user'});
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("verboseOnF"), $cmd{'user'});
				}
			} elsif ($cmd{'msg'} =~ /\bdate\b/i) {
				$responseVars{'date'} = getFormattedDate(int(time));
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("dateS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;
			} elsif ($cmd{'msg'} =~ /\bmove\b/i
				&& $cmd{'msg'} =~ /\bstop\b/i) {
				aiRemove("move");
				aiRemove("route");
				aiRemove("route_getRoute");
				aiRemove("route_getMapRoute");
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;
			} elsif ($cmd{'msg'} =~ /\bmove\b/i) {
				$ai_v{'temp'}{'after'} = $';
				$ai_v{'temp'}{'after'} =~ s/^\s+//;
				$ai_v{'temp'}{'after'} =~ s/\s+$//;
				($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}, $ai_v{'temp'}{'arg3'}) = $ai_v{'temp'}{'after'} =~ /(\d+)\D+(\d+)(.*?)$/;
				undef $ai_v{'temp'}{'map'};
				if ($ai_v{'temp'}{'arg1'} eq "") {
					($ai_v{'temp'}{'map'}) = $ai_v{'temp'}{'after'} =~ /(.*?)$/;
				} else {
					$ai_v{'temp'}{'map'} = $ai_v{'temp'}{'arg3'};
				}
				$ai_v{'temp'}{'map'} =~ s/\s//g;
				if (($ai_v{'temp'}{'arg1'} eq "" || $ai_v{'temp'}{'arg2'} eq "") && !$ai_v{'temp'}{'map'}) {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveF"), $cmd{'user'}) if $config{'verbose'};
				} else {
					$ai_v{'temp'}{'map'} = $field{'name'} if ($ai_v{'temp'}{'map'} eq "");
					if ($maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}) {
						if ($ai_v{'temp'}{'arg2'} ne "") {
							print "Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}\n";
							$ai_v{'temp'}{'x'} = $ai_v{'temp'}{'arg1'};
							$ai_v{'temp'}{'y'} = $ai_v{'temp'}{'arg2'};
						} else {
							print "Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'})\n";
							undef $ai_v{'temp'}{'x'};
							undef $ai_v{'temp'}{'y'};
						}
						sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveS"), $cmd{'user'}) if $config{'verbose'};
						ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
						$timeout{'ai_thanks_set'}{'time'} = time;
					} else {
						print "Map $ai_v{'temp'}{'map'} does not exist\n";
						sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveF"), $cmd{'user'}) if $config{'verbose'};
					}
				}
			} elsif ($cmd{'msg'} =~ /\blook\b/i) {
				($ai_v{'temp'}{'body'}) = $cmd{'msg'} =~ /(\d+)/;
				($ai_v{'temp'}{'head'}) = $cmd{'msg'} =~ /\d+ (\d+)/;
				if ($ai_v{'temp'}{'body'} ne "") {
					look($ai_v{'temp'}{'body'}, $ai_v{'temp'}{'head'});
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("lookS"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("lookF"), $cmd{'user'}) if $config{'verbose'};
				}

			} elsif ($cmd{'msg'} =~ /\bfollow/i
				&& $cmd{'msg'} =~ /\bstop\b/i) {
				if ($config{'follow'}) {
					aiRemove("follow");
					configModify("follow", 0);
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("followStopS"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("followStopF"), $cmd{'user'}) if $config{'verbose'};
				}
			} elsif ($cmd{'msg'} =~ /\bfollow\b/i) {
				$ai_v{'temp'}{'after'} = $';
				$ai_v{'temp'}{'after'} =~ s/^\s+//;
				$ai_v{'temp'}{'after'} =~ s/\s+$//;
				$ai_v{'temp'}{'targetID'} = ai_getIDFromChat(\%players, $cmd{'user'}, $ai_v{'temp'}{'after'});
				if ($ai_v{'temp'}{'targetID'} ne "") {
					aiRemove("follow");
					ai_follow($players{$ai_v{'temp'}{'targetID'}}{'name'});
					configModify("follow", 1);
					configModify("followTarget", $players{$ai_v{'temp'}{'targetID'}}{'name'});
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("followS"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("followF"), $cmd{'user'}) if $config{'verbose'};
				}
			} elsif ($cmd{'msg'} =~ /\btank/i
				&& $cmd{'msg'} =~ /\bstop\b/i) {
				if (!$config{'tankMode'}) {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("tankStopF"), $cmd{'user'}) if $config{'verbose'};
				} elsif ($config{'tankMode'}) {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("tankStopS"), $cmd{'user'}) if $config{'verbose'};
					configModify("tankMode", 0);
					$timeout{'ai_thanks_set'}{'time'} = time;
				}
			} elsif ($cmd{'msg'} =~ /\btank/i) {
				$ai_v{'temp'}{'after'} = $';
				$ai_v{'temp'}{'after'} =~ s/^\s+//;
				$ai_v{'temp'}{'after'} =~ s/\s+$//;
				$ai_v{'temp'}{'targetID'} = ai_getIDFromChat(\%players, $cmd{'user'}, $ai_v{'temp'}{'after'});
				if ($ai_v{'temp'}{'targetID'} ne "") {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("tankS"), $cmd{'user'}) if $config{'verbose'};
					configModify("tankMode", 1);
					configModify("tankModeTarget", $players{$ai_v{'temp'}{'targetID'}}{'name'});
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("tankF"), $cmd{'user'}) if $config{'verbose'};
				}
			} elsif ($cmd{'msg'} =~ /\btown/i) {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveS"), $cmd{'user'}) if $config{'verbose'};
				useTeleport(2);
				$timeout{'ai_thanks_set'}{'time'} = time;

			} elsif ($cmd{'msg'} =~ /\bwhere\b/i) {
				$responseVars{'x'} = $chars[$config{'char'}]{'pos_to'}{'x'};
				$responseVars{'y'} = $chars[$config{'char'}]{'pos_to'}{'y'};
				$responseVars{'map'} = qq~$maps_lut{$field{'name'}.'.rsw'} ($field{'name'})~;
				$timeout{'ai_thanks_set'}{'time'} = time;
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("whereS"), $cmd{'user'}) if $config{'verbose'};
			# EXPs gained per hour
			} elsif ($cmd{'msg'} =~ /\bexp\b/i) {
				logCommand("> logs/AImsg.txt","exp");
				open(AIMSG,modifingPath("< logs/AImsg.txt"));
				foreach (<AIMSG>) {
					s/[\r\n]//g;
					if ($_ ne "") {
						sendMessage(\$remote_socket, $cmd{'type'}, $_, $cmd{'user'});
					}
				}
				close(AIMSG);
				if (-e modifingPath("logs/AImsg.txt")) { unlink(modifingPath("logs/AImsg.txt")); }
			}
		}
		$ai_v{'temp'}{'qm'} = quotemeta $config{'callSign'};
		if ($overallAuth{$cmd{'user'}} >= 1 && ($cmd{'msg'} =~ /\b$ai_v{'temp'}{'qm'}\b/i || $cmd{'type'} eq "pm")
			&& $cmd{'msg'} =~ /\bheal\b/i) {
			$ai_v{'temp'}{'after'} = $';
			($ai_v{'temp'}{'amount'}) = $ai_v{'temp'}{'after'} =~ /(\d+)/;
			$ai_v{'temp'}{'after'} =~ s/\d+//;
			$ai_v{'temp'}{'after'} =~ s/^\s+//;
			$ai_v{'temp'}{'after'} =~ s/\s+$//;
			$ai_v{'temp'}{'targetID'} = ai_getIDFromChat(\%players, $cmd{'user'}, $ai_v{'temp'}{'after'});
			if ($ai_v{'temp'}{'targetID'} eq "") {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("healF1"), $cmd{'user'}) if $config{'verbose'};
			} elsif ($chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'} > 0) {
				undef $ai_v{'temp'}{'amount_healed'};
				undef $ai_v{'temp'}{'sp_needed'};
				undef $ai_v{'temp'}{'sp_used'};
				undef $ai_v{'temp'}{'failed'};
				undef @{$ai_v{'temp'}{'skillCasts'}};
				while ($ai_v{'temp'}{'amount_healed'} < $ai_v{'temp'}{'amount'}) {
					for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'}; $i++) {
						$ai_v{'temp'}{'sp'} = 10 + ($i * 3);
						$ai_v{'temp'}{'amount_this'} = int(($chars[$config{'char'}]{'lv'} + $chars[$config{'char'}]{'int'}) / 8)
								* (4 + $i * 8);
						last if ($ai_v{'temp'}{'amount_healed'} + $ai_v{'temp'}{'amount_this'} >= $ai_v{'temp'}{'amount'});
					}
					$ai_v{'temp'}{'sp_needed'} += $ai_v{'temp'}{'sp'};
					$ai_v{'temp'}{'amount_healed'} += $ai_v{'temp'}{'amount_this'};
				}
				while ($ai_v{'temp'}{'sp_used'} < $ai_v{'temp'}{'sp_needed'} && !$ai_v{'temp'}{'failed'}) {
					for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'}; $i++) {
						$ai_v{'temp'}{'lv'} = $i;
						$ai_v{'temp'}{'sp'} = 10 + ($i * 3);
						if ($ai_v{'temp'}{'sp_used'} + $ai_v{'temp'}{'sp'} > $chars[$config{'char'}]{'sp'}) {
							$ai_v{'temp'}{'lv'}--;
							$ai_v{'temp'}{'sp'} = 10 + ($ai_v{'temp'}{'lv'} * 3);
							last;
						}
						last if ($ai_v{'temp'}{'sp_used'} + $ai_v{'temp'}{'sp'} >= $ai_v{'temp'}{'sp_needed'});
					}
					if ($ai_v{'temp'}{'lv'} > 0) {
						$ai_v{'temp'}{'sp_used'} += $ai_v{'temp'}{'sp'};
						$ai_v{'temp'}{'skillCast'}{'skill'} = 28;
						$ai_v{'temp'}{'skillCast'}{'lv'} = $ai_v{'temp'}{'lv'};
						$ai_v{'temp'}{'skillCast'}{'maxCastTime'} = 0;
						$ai_v{'temp'}{'skillCast'}{'minCastTime'} = 0;
						$ai_v{'temp'}{'skillCast'}{'ID'} = $ai_v{'temp'}{'targetID'};
						unshift @{$ai_v{'temp'}{'skillCasts'}}, {%{$ai_v{'temp'}{'skillCast'}}};
					} else {
						$responseVars{'char_sp'} = $chars[$config{'char'}]{'sp'} - $ai_v{'temp'}{'sp_used'};
						sendMessage(\$remote_socket, $cmd{'type'}, getResponse("healF2"), $cmd{'user'}) if $config{'verbose'};
						$ai_v{'temp'}{'failed'} = 1;
					}
				}
				if (!$ai_v{'temp'}{'failed'}) {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("healS"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				}
				foreach (@{$ai_v{'temp'}{'skillCasts'}}) {
					ai_skillUse($$_{'skill'}, $$_{'lv'}, $$_{'maxCastTime'}, $$_{'minCastTime'}, $$_{'ID'});
				}
			} else {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("healF3"), $cmd{'user'}) if $config{'verbose'};
			}
		}

		if ($overallAuth{$cmd{'user'}} >= 1) {
			if ($cmd{'msg'} =~ /\bthank/i || $cmd{'msg'} =~ /\bthn/i) {
				if (!timeOut(\%{$timeout{'ai_thanks_set'}})) {
					$timeout{'ai_thanks_set'}{'time'} -= $timeout{'ai_thanks_set'}{'timeout'};
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("thankS"), $cmd{'user'}) if $config{'verbose'};
				}
			}
		}
	}


	##### MISC #####

	if (timeOut(\%{$timeout{'ai_wipe_check'}})) {
		foreach (keys %players_old) {
			delete $players_old{$_} if (time - $players_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		foreach (keys %monsters_old) {
			delete $monsters_old{$_} if (time - $monsters_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		foreach (keys %npcs_old) {
			delete $npcs_old{$_} if (time - $npcs_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		foreach (keys %items_old) {
			delete $items_old{$_} if (time - $items_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		foreach (keys %portals_old) {
			delete $portals_old{$_} if (time - $portals_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		$timeout{'ai_wipe_check'}{'time'} = time;
		print "Wiped old\n" if ($config{'debug'} >= 2);
	}

	if (timeOut(\%{$timeout{'ai_getInfo'}})) {
		my $i;
		foreach (keys %players) {
			if ($players{$_}{'name'} eq "Unknown") {
				$players{$_}{'name'} .= " " . unpack("L1", $_);
				sendGetPlayerInfo(\$remote_socket, $_);
				$i = $i++;
				last if (!$config{'dcOnGM'} || $i >= $config{'dcOnGM_fastInfo'});
			}
		}
		foreach (keys %monsters) {
			if ($monsters{$_}{'name'} =~ /Unknown/) {
				sendGetPlayerInfo(\$remote_socket, $_);
				last;
			}
		}
		foreach (keys %npcs) {
			if ($npcs{$_}{'name'} =~ /Unknown/) {
				sendGetPlayerInfo(\$remote_socket, $_);
				last;
			}
		}
		foreach (keys %pets) {
			if ($pets{$_}{'name_given'} =~ /Unknown/) {
				sendGetPlayerInfo(\$remote_socket, $_);
				last;
			}
		}
		$timeout{'ai_getInfo'}{'time'} = time;
	}

	if (timeOut(\%{$timeout{'ai_sync'}})) {
		$timeout{'ai_sync'}{'time'} = time;
		sendSync(\$remote_socket, getTickCount());
	}
	if ($ai_seq[0] eq "look" && timeOut(\%{$timeout{'ai_look'}})) {
		$timeout{'ai_look'}{'time'} = time;
		sendLook(\$remote_socket, $ai_seq_args[0]{'look_body'}, $ai_seq_args[0]{'look_head'});
		shift @ai_seq;
		shift @ai_seq_args;
	}

	if ($ai_seq[0] ne "deal" && %currentDeal) {
		unshift @ai_seq, "deal";
		unshift @ai_seq_args, "";
	} elsif ($ai_seq[0] eq "deal" && !%currentDeal) {
		shift @ai_seq;
		shift @ai_seq_args;
	}

	if ($config{'dealAutoCancel'} && %incomingDeal && timeOut(\%{$timeout{'ai_dealAutoCancel'}})) {
		sendDealCancel(\$remote_socket);
		$timeout{'ai_dealAutoCancel'}{'time'} = time;
	}
	if ($config{'partyAutoDeny'} && %incomingParty && timeOut(\%{$timeout{'ai_partyAutoDeny'}})) {
		sendPartyJoin(\$remote_socket, $incomingParty{'ID'}, 0);
		$timeout{'ai_partyAutoDeny'}{'time'} = time;
		undef %incomingParty;
	}
	# guild request auto deny
	if ($config{'guildAutoDeny'} && %incomingGuild && timeOut(\%{$timeout{'ai_guildAutoDeny'}})) {
		sendGuildJoin(\$remote_socket, $incomingGuild{'ID'}, 0);
		$timeout{'ai_guildAutoDeny'}{'time'} = time;
		undef %incomingGuild;
	}

	if ($ai_v{'portalTrace_mapChanged'}) {
		undef $ai_v{'portalTrace_mapChanged'};
		$ai_v{'temp'}{'first'} = 1;
		undef $ai_v{'temp'}{'foundID'};
		undef $ai_v{'temp'}{'smallDist'};

		foreach (@portalsID_old) {
			$ai_v{'temp'}{'dist'} = distance(\%{$chars_old[$config{'char'}]{'pos_to'}}, \%{$portals_old{$_}{'pos'}});
			if ($ai_v{'temp'}{'dist'} <= 7 && ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'})) {
				$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
				$ai_v{'temp'}{'foundID'} = $_;
				undef $ai_v{'temp'}{'first'};
			}
		}
		if ($ai_v{'temp'}{'foundID'}) {
			$ai_v{'portalTrace'}{'source'}{'map'} = $portals_old{$ai_v{'temp'}{'foundID'}}{'source'}{'map'};
			$ai_v{'portalTrace'}{'source'}{'ID'} = $portals_old{$ai_v{'temp'}{'foundID'}}{'nameID'};
			%{$ai_v{'portalTrace'}{'source'}{'pos'}} = %{$portals_old{$ai_v{'temp'}{'foundID'}}{'pos'}};
		}
	}

	if (%{$ai_v{'portalTrace'}} && portalExists($ai_v{'portalTrace'}{'source'}{'map'}, \%{$ai_v{'portalTrace'}{'source'}{'pos'}}) ne "") {
		undef %{$ai_v{'portalTrace'}};
	} elsif (%{$ai_v{'portalTrace'}} && $field{'name'}) {
		$ai_v{'temp'}{'first'} = 1;
		undef $ai_v{'temp'}{'foundID'};
		undef $ai_v{'temp'}{'smallDist'};

		foreach (@portalsID) {
			$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$portals{$_}{'pos'}});
			if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'}) {
				$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
				$ai_v{'temp'}{'foundID'} = $_;
				undef $ai_v{'temp'}{'first'};
			}
		}

		if (%{$portals{$ai_v{'temp'}{'foundID'}}}) {
			if (portalExists($field{'name'}, \%{$portals{$ai_v{'temp'}{'foundID'}}{'pos'}}) eq ""
				&& $ai_v{'portalTrace'}{'source'}{'map'} && $ai_v{'portalTrace'}{'source'}{'pos'}{'x'} ne "" && $ai_v{'portalTrace'}{'source'}{'pos'}{'y'} ne ""
				&& $field{'name'} && $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'} ne "" && $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'} ne "") {

				$portals{$ai_v{'temp'}{'foundID'}}{'name'} = "$field{'name'} -> $ai_v{'portalTrace'}{'source'}{'map'}";
				$portals{pack("L",$ai_v{'portalTrace'}{'source'}{'ID'})}{'name'} = "$ai_v{'portalTrace'}{'source'}{'map'} -> $field{'name'}";

				$ai_v{'temp'}{'ID'} = "$ai_v{'portalTrace'}{'source'}{'map'} $ai_v{'portalTrace'}{'source'}{'pos'}{'x'} $ai_v{'portalTrace'}{'source'}{'pos'}{'y'}";
				$portals_lut{$ai_v{'temp'}{'ID'}}{'source'}{'map'} = $ai_v{'portalTrace'}{'source'}{'map'};
				%{$portals_lut{$ai_v{'temp'}{'ID'}}{'source'}{'pos'}} = %{$ai_v{'portalTrace'}{'source'}{'pos'}};
				$portals_lut{$ai_v{'temp'}{'ID'}}{'dest'}{'map'} = $field{'name'};
				%{$portals_lut{$ai_v{'temp'}{'ID'}}{'dest'}{'pos'}} = %{$portals{$ai_v{'temp'}{'foundID'}}{'pos'}};

				updatePortalLUT("tables/portals.txt",
					$ai_v{'portalTrace'}{'source'}{'map'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'x'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'y'},
					$field{'name'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'});

				$ai_v{'temp'}{'ID2'} = "$field{'name'} $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'} $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'}";
				$portals_lut{$ai_v{'temp'}{'ID2'}}{'source'}{'map'} = $field{'name'};
				%{$portals_lut{$ai_v{'temp'}{'ID2'}}{'source'}{'pos'}} = %{$portals{$ai_v{'temp'}{'foundID'}}{'pos'}};
				$portals_lut{$ai_v{'temp'}{'ID2'}}{'dest'}{'map'} = $ai_v{'portalTrace'}{'source'}{'map'};
				%{$portals_lut{$ai_v{'temp'}{'ID2'}}{'dest'}{'pos'}} = %{$ai_v{'portalTrace'}{'source'}{'pos'}};

				updatePortalLUT("tables/portals.txt",
					$field{'name'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'},
					$ai_v{'portalTrace'}{'source'}{'map'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'x'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'y'});
			}
			undef %{$ai_v{'portalTrace'}};
		}
	}
	# EXPs gained per hour
	if ($config{'recordExp'} >= 2 && $startTime_EXP ne "" && timeOut($config{'recordExp_timeout'}, $ai_v{'recordEXP_time'}) && !(($conState == 2 || $conState == 3) && $waitingForInput)) {
		unlink(modifingPath("logs/ExpLog.txt")) if ($config{'recordExp'} == 3 && -e modifingPath("logs/ExpLog.txt"));
		parseInput("exp log");
		parseInput("exp reset") if ($config{'recordExp'} == 4);
		$ai_v{'recordEXP_time'} = time;
	}
	# Resume attack process stopped by rare loot
	if ($ai_v{'ImportantItem'}{'time'} && timeOut($config{'timeCutImportant'}, $ai_v{'ImportantItem'}{'time'})) {
		$config{'attackAuto'} = $ai_v{'ImportantItem'}{'attackAuto'};
		undef %{$ai_v{'ImportantItem'}};
	}
	# Relog if timeout when waiting for inventory packet
	if ($ai_v{'teleQueue'} && timeOut($timeout{'ai_teleport_wait'}, $ai_v{'teleQueue_time'})
		|| $ai_v{'temp'}{'refreshInventory'} && timeOut($timeout{'ai_teleport_wait'}, $ai_v{'temp'}{'refreshInventory'})) {
		relog("Could not obtain inventory information, relogging...\n");
	}

	##### CLIENT SUSPEND #####

	if ($ai_seq[0] eq "clientSuspend" && timeOut(\%{$ai_seq_args[0]})) {
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "clientSuspend") {
		#this section is used in X-Kore
	}

	##### AUTO-CART ADD #####

	if ($config{'cartAddAuto'} && $cart{'weight_max'} && timeOut(\%{$timeout{'ai_cartAuto_add'}})) {
		my $c = 0;
		while ($cart_control{"add_$c"} ne "") {
			my $invIndex = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $cart_control{"add_$c"});
			if ($invIndex ne "") {
				my $autoCartAddAmount = $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $cart_control{"add_$c"."_invAmount"};
				if ($autoCartAddAmount > 0 && ($cart{'weight'}/$cart{'weight_max'})*100 < $config{'cartMaxWeight'}) {
					print "Auto-cart add : $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} x $autoCartAddAmount\n";
					sendCartAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}, $autoCartAddAmount);
					undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]} if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0);
					undef $ai_v{'stockVoid'}{'cart'}{$cart_control{"add_$c"}};
					last;
				}
			}
			$c++;
		}
		$timeout{'ai_cartAuto_add'}{'time'} = time;
	}

	##### AUTO-CART GET #####

	if ($config{'cartGetAuto'} && $cart{'weight_max'} && timeOut(\%{$timeout{'ai_cartAuto_get'}})) {
		my $i = 0;
		while ($cart_control{"get_$i"} ne "") {
			if ($ai_v{'stockVoid'}{'cart'}{$cart_control{"get_$i"}}) {
				$i++;
				next;
			}
			my $invIndex = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $cart_control{"get_$i"});
			if ($cart_control{"get_$i"."_minAmount"} ne "" && $cart_control{"get_$i"."_maxAmount"} ne ""
				&& ($invIndex eq ""
				|| ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= $cart_control{"get_$i"."_minAmount"}
				&& $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} < $cart_control{"get_$i"."_maxAmount"}))) {
				my $cartIndex = findIndexString_lc(\@{$cart{'inventory'}}, "name", $cart_control{"get_$i"});
				if ($cartIndex ne "") {
					my $getAmount;
					if ($invIndex ne "") {
						$getAmount = $cart_control{"get_$i"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'};
					} else {
						$getAmount = $cart_control{"get_$i"."_maxAmount"};
					}
					if ($getAmount > $cart{'inventory'}[$cartIndex]{'amount'}) {
						$getAmount = $cart{'inventory'}[$cartIndex]{'amount'};
						$ai_v{'stockVoid'}{'cart'}{$cart_control{"get_$i"}} = 1;
					}
					print "Auto-cart get : $cart{'inventory'}[$cartIndex]{'name'} x $getAmount\n";
					sendCartGet(\$remote_socket, $cartIndex, $getAmount);
					undef %{$cart{'inventory'}[$cartIndex]} if ($cart{'inventory'}[$cartIndex]{'amount'} == 0);
				} else {
					$ai_v{'stockVoid'}{'cart'}{$cart_control{"get_$i"}} = 1;
				}
			}
			$i++;
		}
		$timeout{'ai_cartAuto_get'}{'time'} = time;
	}

	#####AUTO HEAL#####

	AUTOHEAL: {

	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "sitAuto") && $config{'healAuto'} && $config{'healAuto_npc'} ne "" && percent_hp(\%{$chars[$config{'char'}]}) <= $config{'healAuto_hp'} && percent_sp(\%{$chars[$config{'char'}]}) <= $config{'healAuto_sp'}) {
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1)) {
			unshift @ai_seq, "healAuto";
			unshift @ai_seq_args, {};
		}
	}

	if ($ai_seq[0] eq "healAuto" && $ai_seq_args[0]{'done'}) {
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'storageAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'healAuto'} = 1;
			unshift @ai_seq, "storageAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
		}
	} elsif ($ai_seq[0] eq "healAuto" && timeOut(\%{$timeout{'ai_healAuto'}})) {
		if (!$config{'healAuto'} || !%{$npcs_lut{$config{'healAuto_npc'}}}) {
			$ai_seq_args[0]{'done'} = 1;
			last AUTOHEAL;
		}

		undef $ai_v{'temp'}{'do_route'};
		if ($field{'name'} ne $npcs_lut{$config{'healAuto_npc'}}{'map'}) {
			$ai_v{'temp'}{'do_route'} = 1;
		} else {
			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{'healAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			if ($ai_v{'temp'}{'distance'} > 14) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}
		if ($ai_v{'temp'}{'do_route'}) {
			if ($ai_seq_args[0]{'warpedToSave'} && !$ai_seq_args[0]{'mapChanged'}) {
				undef $ai_seq_args[0]{'warpedToSave'};
			}
			if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'}) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				$timeout{'ai_healAuto'}{'time'} = time;
			# heal position change
			} elsif ($config{'healAuto_npc_dist'}) {
				getField("fields/$npcs_lut{$config{'healAuto_npc'}}{'map'}.fld", \%{$ai_seq_args[0]{'dest_field'}});
				undef $ai_v{'temp'}{'rand'};
				do {
					%{$ai_v{'temp'}{'rand'}} = randOffset(\%{$npcs_lut{$config{'healAuto_npc'}}{'pos'}}, $config{'healAuto_npc_dist'});
				} while (ai_route_getOffset(\%{$ai_seq_args[0]{'dest_field'}}, $ai_v{'temp'}{'rand'}{'x'}, $ai_v{'temp'}{'rand'}{'y'}));
				print "Calculating auto-heal route to: $maps_lut{$npcs_lut{$config{'healAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'healAuto_npc'}}{'map'}): $ai_v{'temp'}{'rand'}{'x'}, $ai_v{'temp'}{'rand'}{'y'}\n";
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'rand'}{'x'}, $ai_v{'temp'}{'rand'}{'y'}, $npcs_lut{$config{'healAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				print "Calculating auto-heal route to: $maps_lut{$npcs_lut{$config{'healAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'healAuto_npc'}}{'map'}): $npcs_lut{$config{'healAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'healAuto_npc'}}{'pos'}{'y'}\n";
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{'healAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'healAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$config{'healAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
			}
		} else {
			if (!$ai_seq_args[0]{'npc'}{'sentTalk'}) {
				sendTalk(\$remote_socket, pack("L1",$config{'healAuto_npc'}));
				@{$ai_seq_args[0]{'npc'}{'steps'}} = split(/ /, $config{'healAuto_npc_steps'});
				$ai_seq_args[0]{'npc'}{'sentTalk'} = 1;
			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /c/i) {
				sendTalkContinue(\$remote_socket, pack("L1",$config{'healAuto_npc'}));
				$ai_seq_args[0]{'npc'}{'step'}++;
			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /n/i) {
				sendTalkCancel(\$remote_socket, pack("L1",$config{'healAuto_npc'}));
				$ai_seq_args[0]{'npc'}{'step'}++;
			} else {
				($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i;
				if ($ai_v{'temp'}{'arg'} ne "") {
					$ai_v{'temp'}{'arg'}++;
					sendTalkResponse(\$remote_socket, pack("L1",$config{'healAuto_npc'}), $ai_v{'temp'}{'arg'});
				}
				$ai_seq_args[0]{'npc'}{'step'}++;
			}
			$ai_seq_args[0]{'done'} = 1 if ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] eq "");
			$timeout{'ai_healAuto'}{'time'} = time;
		}
	}

	} #END OF BLOCK AUTOHEAL

	#storageAuto - chobit aska 20030128
	#####AUTO STORAGE#####

	AUTOSTORAGE: {

	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route") && $config{'storageAuto'} && $config{'storageAuto_npc'} ne "" && percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'}) {
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && ai_storageAutoCheck()) {
			unshift @ai_seq, "storageAuto";
			unshift @ai_seq_args, {};
		}
	# Judge auto storage get
	} elsif (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "attack") && $config{'storageAuto'} && $config{'storageAuto_npc'} ne "" && timeOut(\%{$timeout{'ai_storagegetAuto'}})) {
		undef $ai_v{'temp'}{'found'};
		$i = 0;
		while (1) {
			last if (!$config{"storagegetAuto_$i"});
			$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"storagegetAuto_$i"});
			if ($config{"storagegetAuto_$i"."_minAmount"} ne "" && $config{"storagegetAuto_$i"."_maxAmount"} ne "" && !$ai_v{'stockVoid'}{'storage'}[$i]
				&& ($ai_v{'temp'}{'invIndex'} eq ""
				|| ($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} <= $config{"storagegetAuto_$i"."_minAmount"}
				&& $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $config{"storagegetAuto_$i"."_maxAmount"}))) {
				$ai_v{'temp'}{'found'} = 1;
				last;
			}
			$i++;
		}
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && $ai_v{'temp'}{'found'}) {
			unshift @ai_seq, "storageAuto";
			unshift @ai_seq_args, {};
		}
		$timeout{'ai_storagegetAuto'}{'time'} = time;
	}

	if ($ai_seq[0] eq "storageAuto" && $ai_seq_args[0]{'done'}) {
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'sellAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'storageAuto'} = 1;
			unshift @ai_seq, "sellAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
		}
	} elsif ($ai_seq[0] eq "storageAuto" && timeOut(\%{$timeout{'ai_storageAuto'}})) {
		if (!$config{'storageAuto'} || !%{$npcs_lut{$config{'storageAuto_npc'}}}) {
			$ai_seq_args[0]{'done'} = 1;
			last AUTOSTORAGE;
		}

		undef $ai_v{'temp'}{'do_route'};
		if ($field{'name'} ne $npcs_lut{$config{'storageAuto_npc'}}{'map'}) {
			$ai_v{'temp'}{'do_route'} = 1;
		} else {
			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{'storageAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			if ($ai_v{'temp'}{'distance'} > 14) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}
		if ($ai_v{'temp'}{'do_route'}) {
			if ($ai_seq_args[0]{'warpedToSave'} && !$ai_seq_args[0]{'mapChanged'}) {
				undef $ai_seq_args[0]{'warpedToSave'};
			}
			if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'}) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				$timeout{'ai_storageAuto'}{'time'} = time;
			# storage position change
			} elsif ($config{'storageAuto_npc_dist'}) {
				getField("fields/$npcs_lut{$config{'storageAuto_npc'}}{'map'}.fld", \%{$ai_seq_args[0]{'dest_field'}});
				undef $ai_v{'temp'}{'rand'};
				do {
					%{$ai_v{'temp'}{'rand'}} = randOffset(\%{$npcs_lut{$config{'storageAuto_npc'}}{'pos'}}, $config{'storageAuto_npc_dist'});
				} while (ai_route_getOffset(\%{$ai_seq_args[0]{'dest_field'}}, $ai_v{'temp'}{'rand'}{'x'}, $ai_v{'temp'}{'rand'}{'y'}));
				print "Calculating auto-storage route to: $maps_lut{$npcs_lut{$config{'storageAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'storageAuto_npc'}}{'map'}): $ai_v{'temp'}{'rand'}{'x'}, $ai_v{'temp'}{'rand'}{'y'}\n";
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'rand'}{'x'}, $ai_v{'temp'}{'rand'}{'y'}, $npcs_lut{$config{'storageAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				print "Calculating auto-storage route to: $maps_lut{$npcs_lut{$config{'storageAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'storageAuto_npc'}}{'map'}): $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'}\n";
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$config{'storageAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
			}
		} else {
			if (!$ai_seq_args[0]{'sentTalk'}) {
				sendTalk(\$remote_socket, pack("L1",$config{'storageAuto_npc'}));
				@{$ai_seq_args[0]{'steps'}} = split(/ /, $config{'storageAuto_npc_steps'});
				$ai_seq_args[0]{'sentTalk'} = 1;
				$timeout{'ai_storageAuto'}{'time'} = time;
				last AUTOSTORAGE;
			} elsif (defined(@{$ai_seq_args[0]{'steps'}})) {
				if ($ai_seq_args[0]{'steps'}[$ai_seq_args[0]{'step'}] =~ /c/i) {
					sendTalkContinue(\$remote_socket, pack("L1",$config{'storageAuto_npc'}));
				} elsif ($ai_seq_args[0]{'steps'}[$ai_seq_args[0]{'step'}] =~ /n/i) {
					sendTalkCancel(\$remote_socket, pack("L1",$config{'storageAuto_npc'}));
				} elsif ($ai_seq_args[0]{'steps'}[$ai_seq_args[0]{'step'}] ne "") {
					($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'steps'}[$ai_seq_args[0]{'step'}] =~ /r(\d+)/i;
					if ($ai_v{'temp'}{'arg'} ne "") {
						$ai_v{'temp'}{'arg'}++;
						sendTalkResponse(\$remote_socket, pack("L1",$config{'storageAuto_npc'}), $ai_v{'temp'}{'arg'});
					}
				} else {
					undef @{$ai_seq_args[0]{'steps'}};
				}
				$ai_seq_args[0]{'step'}++;
				$timeout{'ai_storageAuto'}{'time'} = time;
				last AUTOSTORAGE;
			}
			$ai_seq_args[0]{'done'} = 1;
			if (!$ai_seq_args[0]{'getStart'}) {
				for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
					next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'} ne "");
					if ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'storage'}
						&& $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}) {
						if ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $chars[$config{'char'}]{'inventory'}[$i]{'index'}
							&& timeOut(\%{$timeout{'ai_storageAuto_giveup'}})) {
							last AUTOSTORAGE;
						} elsif ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $chars[$config{'char'}]{'inventory'}[$i]{'index'}) {
							$timeout{'ai_storageAuto_giveup'}{'time'} = time;
						}
						undef $ai_seq_args[0]{'done'};
						$ai_seq_args[0]{'lastIndex'} = $chars[$config{'char'}]{'inventory'}[$i]{'index'};
						sendStorageAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$i]{'index'}, $chars[$config{'char'}]{'inventory'}[$i]{'amount'} - $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'});
						$timeout{'ai_storageAuto'}{'time'} = time;
						last AUTOSTORAGE;
					}
				}
			}
#			sendStorageClose(\$remote_socket);
			# Storage get auto
			if (!$ai_seq_args[0]{'getStart'} && $ai_seq_args[0]{'done'} == 1) {
				$ai_seq_args[0]{'getStart'} = 1;
				undef $ai_seq_args[0]{'done'};
				last AUTOSTORAGE;
			}
			$i = 0;
			undef $ai_seq_args[0]{'index'};
			while (1) {
				last if (!$config{"storagegetAuto_$i"});
				$ai_seq_args[0]{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"storagegetAuto_$i"});
				if (!$ai_seq_args[0]{'index_failed'}{$i} && $config{"storagegetAuto_$i"."_maxAmount"} ne "" && !$ai_v{'stockVoid'}{'storage'}[$i] && ($ai_seq_args[0]{'invIndex'} eq ""
					|| $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'} < $config{"storagegetAuto_$i"."_maxAmount"})) {
					$ai_seq_args[0]{'index'} = $i;
					last;
				}
				$i++;
			}
			if ($ai_seq_args[0]{'index'} eq ""
				|| ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $ai_seq_args[0]{'index'}
				&& timeOut(\%{$timeout{'ai_storageAuto_giveup'}}))) {
				$ai_seq_args[0]{'done'} = 1;
				sendStorageClose(\$remote_socket);
				last AUTOSTORAGE;
			} elsif ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $ai_seq_args[0]{'index'}) {
				$timeout{'ai_storageAuto_giveup'}{'time'} = time;
			}
			undef $ai_seq_args[0]{'done'};
			undef $ai_seq_args[0]{'storageInvIndex'};
			$ai_seq_args[0]{'lastIndex'} = $ai_seq_args[0]{'index'};
			$ai_seq_args[0]{'storageInvIndex'} = findIndexString_lc(\@{$storage{'inventory'}}, "name", $config{"storagegetAuto_$ai_seq_args[0]{'index'}"});
			if ($ai_seq_args[0]{'storageInvIndex'} eq "") {
				$ai_v{'stockVoid'}{'storage'}[$ai_seq_args[0]{'index'}] = 1;
				last AUTOSTORAGE;
			} elsif ($ai_seq_args[0]{'invIndex'} ne "") {
				if ($config{"storagegetAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'} > $storage{'inventory'}[$ai_seq_args[0]{'storageInvIndex'}]{'amount'}) {
					$getAmount = $storage{'inventory'}[$ai_seq_args[0]{'storageInvIndex'}]{'amount'};
					$ai_v{'stockVoid'}{'storage'}[$ai_seq_args[0]{'index'}] = 1;
				} else {
					$getAmount = $config{"storagegetAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'};
				}
			} else {
				if ($config{"storagegetAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} > $storage{'inventory'}[$ai_seq_args[0]{'storageInvIndex'}]{'amount'}) {
					$getAmount = $storage{'inventory'}[$ai_seq_args[0]{'storageInvIndex'}]{'amount'};
					$ai_v{'stockVoid'}{'storage'}[$ai_seq_args[0]{'index'}] = 1;
				} else {
					$getAmount = $config{"storagegetAuto_$ai_seq_args[0]{'index'}"."_maxAmount"};
				}
			}
			sendStorageGet(\$remote_socket, $ai_seq_args[0]{'storageInvIndex'}, $getAmount);
			$timeout{'ai_storageAuto'}{'time'} = time;
		}
	}

	} #END OF BLOCK AUTOSTORAGE



	#####AUTO SELL#####

	AUTOSELL: {

	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route") && $config{'sellAuto'} && $config{'sellAuto_npc'} ne "" && percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'}) {
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && ai_sellAutoCheck()) {
			unshift @ai_seq, "sellAuto";
			unshift @ai_seq_args, {};
		}
	}

	if ($ai_seq[0] eq "sellAuto" && $ai_seq_args[0]{'done'}) {
		sendTalkCancel(\$remote_socket, pack("L1",$config{'sellAuto_npc'})) if $ai_seq_args[0]{'sentSell'};
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'buyAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'sellAuto'} = 1;
			unshift @ai_seq, "buyAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
		}
	} elsif ($ai_seq[0] eq "sellAuto" && timeOut(\%{$timeout{'ai_sellAuto'}})) {
		if (!$config{'sellAuto'} || !%{$npcs_lut{$config{'sellAuto_npc'}}}) {
			$ai_seq_args[0]{'done'} = 1;
			last AUTOSELL;
		}

		undef $ai_v{'temp'}{'do_route'};
		if ($field{'name'} ne $npcs_lut{$config{'sellAuto_npc'}}{'map'}) {
			$ai_v{'temp'}{'do_route'} = 1;
		} else {
			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{'sellAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			if ($ai_v{'temp'}{'distance'} > 14) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}
		if ($ai_v{'temp'}{'do_route'}) {
			if ($ai_seq_args[0]{'warpedToSave'} && !$ai_seq_args[0]{'mapChanged'}) {
				undef $ai_seq_args[0]{'warpedToSave'};
			}
			if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'}) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				$timeout{'ai_sellAuto'}{'time'} = time;
			# sell position change
			} elsif ($config{'sellAuto_npc_dist'}) {
				getField("fields/$npcs_lut{$config{'sellAuto_npc'}}{'map'}.fld", \%{$ai_seq_args[0]{'dest_field'}});
				undef $ai_v{'temp'}{'rand'};
				do {
					%{$ai_v{'temp'}{'rand'}} = randOffset(\%{$npcs_lut{$config{'sellAuto_npc'}}{'pos'}}, $config{'sellAuto_npc_dist'});
				} while (ai_route_getOffset(\%{$ai_seq_args[0]{'dest_field'}}, $ai_v{'temp'}{'rand'}{'x'}, $ai_v{'temp'}{'rand'}{'y'}));
				print "Calculating auto-sell route to: $maps_lut{$npcs_lut{$config{'sellAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'sellAuto_npc'}}{'map'}): $ai_v{'temp'}{'rand'}{'x'}, $ai_v{'temp'}{'rand'}{'y'}\n";
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'rand'}{'x'}, $ai_v{'temp'}{'rand'}{'y'}, $npcs_lut{$config{'sellAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				print "Calculating auto-sell route to: $maps_lut{$npcs_lut{$config{'sellAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'sellAuto_npc'}}{'map'}): $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'y'}\n";
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$config{'sellAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
			}
		} else {
			if ($ai_seq_args[0]{'sentSell'} <= 1) {
				sendTalk(\$remote_socket, pack("L1",$config{'sellAuto_npc'})) if !$ai_seq_args[0]{'sentSell'};
				sendGetSellList(\$remote_socket, pack("L1",$config{'sellAuto_npc'})) if $ai_seq_args[0]{'sentSell'};
				$ai_seq_args[0]{'sentSell'}++;
				$timeout{'ai_sellAuto'}{'time'} = time;
				last AUTOSELL;
			}
			$ai_seq_args[0]{'done'} = 1;
			for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
				next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'} ne "");
				if ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'sell'}
					&& $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}) {
					if ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $chars[$config{'char'}]{'inventory'}[$i]{'index'}
						&& timeOut(\%{$timeout{'ai_sellAuto_giveup'}})) {
						last AUTOSELL;
					} elsif ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $chars[$config{'char'}]{'inventory'}[$i]{'index'}) {
						$timeout{'ai_sellAuto_giveup'}{'time'} = time;
					}
					undef $ai_seq_args[0]{'done'};
					$ai_seq_args[0]{'lastIndex'} = $chars[$config{'char'}]{'inventory'}[$i]{'index'};
					sendSell(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$i]{'index'}, $chars[$config{'char'}]{'inventory'}[$i]{'amount'} - $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'});
					$timeout{'ai_sellAuto'}{'time'} = time;
					last AUTOSELL;
				}
			}
		}
	}

	} #END OF BLOCK AUTOSELL



	#####AUTO BUY#####

	AUTOBUY: {

	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "attack") && timeOut(\%{$timeout{'ai_buyAuto'}})) {
		undef $ai_v{'temp'}{'found'};
		$i = 0;
		while (1) {
			last if (!$config{"buyAuto_$i"} || !$config{"buyAuto_$i"."_npc"});
			$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"buyAuto_$i"});
			if ($config{"buyAuto_$i"."_minAmount"} ne "" && $config{"buyAuto_$i"."_maxAmount"} ne ""
				&& ($ai_v{'temp'}{'invIndex'} eq ""
				|| ($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} <= $config{"buyAuto_$i"."_minAmount"}
				&& $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $config{"buyAuto_$i"."_maxAmount"}))) {
				$ai_v{'temp'}{'found'} = 1;
				last;
			}
			$i++;
		}
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && $ai_v{'temp'}{'found'}) {
			unshift @ai_seq, "buyAuto";
			unshift @ai_seq_args, {};
		}
		$timeout{'ai_buyAuto'}{'time'} = time;
	}

	if ($ai_seq[0] eq "buyAuto" && $ai_seq_args[0]{'done'}) {
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'healAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'buyAuto'} = 1;
			unshift @ai_seq, "healAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
		}
	} elsif ($ai_seq[0] eq "buyAuto" && timeOut(\%{$timeout{'ai_buyAuto_wait'}}) && timeOut(\%{$timeout{'ai_buyAuto_wait_buy'}})) {
		$i = 0;
		undef $ai_seq_args[0]{'index'};

		while (1) {
			last if (!$config{"buyAuto_$i"} || !%{$npcs_lut{$config{"buyAuto_$i"."_npc"}}});
			$ai_seq_args[0]{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"buyAuto_$i"});
			if (!$ai_seq_args[0]{'index_failed'}{$i} && $config{"buyAuto_$i"."_maxAmount"} ne "" && ($ai_seq_args[0]{'invIndex'} eq ""
				|| $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'} < $config{"buyAuto_$i"."_maxAmount"})) {
				$ai_seq_args[0]{'index'} = $i;
				last;
			}
			$i++;
		}
		if ($ai_seq_args[0]{'index'} eq ""
			|| ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $ai_seq_args[0]{'index'}
			&& timeOut(\%{$timeout{'ai_buyAuto_giveup'}}))) {
			$ai_seq_args[0]{'done'} = 1;
			last AUTOBUY;
		}
		undef $ai_v{'temp'}{'do_route'};
		if ($field{'name'} ne $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}) {
			$ai_v{'temp'}{'do_route'} = 1;
		} else {
			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			if ($ai_v{'temp'}{'distance'} > 14) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}
		if ($ai_v{'temp'}{'do_route'}) {
			if ($ai_seq_args[0]{'warpedToSave'} && !$ai_seq_args[0]{'mapChanged'}) {
				undef $ai_seq_args[0]{'warpedToSave'};
			}
			if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'}) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				$timeout{'ai_buyAuto_wait'}{'time'} = time;
			# buy position change
			} elsif ($config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc_dist"}) {
				getField(qq~fields/$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}.fld~, \%{$ai_seq_args[0]{'dest_field'}});
				undef $ai_v{'temp'}{'rand'};
				do {
					%{$ai_v{'temp'}{'rand'}} = randOffset(\%{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}}, $config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc_dist"});
				} while (ai_route_getOffset(\%{$ai_seq_args[0]{'dest_field'}}, $ai_v{'temp'}{'rand'}{'x'}, $ai_v{'temp'}{'rand'}{'y'}));
				print qq~Calculating auto-buy route to: $maps_lut{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}.'.rsw'}($npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}): $ai_v{'temp'}{'rand'}{'x'}, $ai_v{'temp'}{'rand'}{'y'}\n~;
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'rand'}{'x'}, $ai_v{'temp'}{'rand'}{'y'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				print qq~Calculating auto-buy route to: $maps_lut{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}.'.rsw'}($npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}): $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'x'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'y'}\n~;
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'x'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'y'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}, 0, 0, 1, 0, 0, 1);
			}
		} else {
			if ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $ai_seq_args[0]{'index'}) {
				undef $ai_seq_args[0]{'itemID'};
				if ($config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"} != $config{"buyAuto_$ai_seq_args[0]{'lastIndex'}"."_npc"}) {
					undef $ai_seq_args[0]{'sentBuy'};
				}
				$timeout{'ai_buyAuto_giveup'}{'time'} = time;
			}
			$ai_seq_args[0]{'lastIndex'} = $ai_seq_args[0]{'index'};
			if ($ai_seq_args[0]{'itemID'} eq "") {
				foreach (keys %items_lut) {
					if (lc($items_lut{$_}) eq lc($config{"buyAuto_$ai_seq_args[0]{'index'}"})) {
						$ai_seq_args[0]{'itemID'} = $_;
					}
				}
				if ($ai_seq_args[0]{'itemID'} eq "") {
					$ai_seq_args[0]{'index_failed'}{$ai_seq_args[0]{'index'}} = 1;
					print "autoBuy index $ai_seq_args[0]{'index'} failed\n" if $config{'debug'};
					last AUTOBUY;
				}
			}

			if ($ai_seq_args[0]{'sentBuy'} <= 1) {
				sendTalk(\$remote_socket, pack("L1",$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"})) if !$ai_seq_args[0]{'sentBuy'};
				sendGetStoreList(\$remote_socket, pack("L1",$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"})) if $ai_seq_args[0]{'sentBuy'};
				$ai_seq_args[0]{'sentBuy'}++;
				$timeout{'ai_buyAuto_wait'}{'time'} = time;
				last AUTOBUY;
			}
			if ($ai_seq_args[0]{'invIndex'} ne "") {
				sendBuy(\$remote_socket, $ai_seq_args[0]{'itemID'}, $config{"buyAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'});
			} else {
				sendBuy(\$remote_socket, $ai_seq_args[0]{'itemID'}, $config{"buyAuto_$ai_seq_args[0]{'index'}"."_maxAmount"});
			}
			$timeout{'ai_buyAuto_wait_buy'}{'time'} = time;
		}
	}

	} #END OF BLOCK AUTOBUY

	##### PREFER ROUTE #####

	if ($ai_seq[0] eq "" && $config{'preferRoute'} && $field{'name'} && binFind(\@preferRoute, $field{'name'}) ne "") {
		$index = binFind(\@preferRoute, $field{'name'}) + 1;
		if ($field{'name'} ne $config{'lockMap'} && $field{'name'} ne $preferRoute[-1]) {
			if ($maps_lut{$preferRoute[$index].'.rsw'} eq "") {
				print "Invalid map specified for preferRoute - map $preferRoute[$index] doesn't exist\n";
			} else {
				print "Calculating preferRoute route to: $maps_lut{$preferRoute[$index].'.rsw'}($preferRoute[$index])\n";
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, "", "", $preferRoute[$index], 0, 0, 1, 0, 0, 1);
			}
		}
	}

	##### LOCKMAP LOOP #####

	if ($ai_seq[0] eq "" && $config{'lockMap_loop'} && timeOut($config{'lockMap_loop'}, $ai_v{'lockMap_loop_time'})) {
		if ($ai_v{'lockMap_loop_time'} ne "") {
			my $index = binFind(\@mapLoop, $config{'lockMap'}) + 1;

			if ($index < scalar(@mapLoop)) {
				configModify("lockMap", $mapLoop[$index]);
			} else {
				configModify("lockMap", $mapLoop[0]);
			}
			parseInput("move stop");
			parseInput("base") if $config{'lockMap_loop_base'};
		}
		$ai_v{'lockMap_loop_time'} = time;
	}

	##### LOCKMAP #####


	if ($ai_seq[0] eq "" && $config{'lockMap'} && $field{'name'}
		&& ($field{'name'} ne $config{'lockMap'}
		|| ($config{'lockMap_x'} ne "" && ($ai_v{'lockMap'}{'pos_to'}{'x'} eq ""
			|| $chars[$config{'char'}]{'pos_to'}{'x'} != $ai_v{'lockMap'}{'pos_to'}{'x'}
			|| $chars[$config{'char'}]{'pos_to'}{'y'} != $ai_v{'lockMap'}{'pos_to'}{'y'})))) {
		if ($maps_lut{$config{'lockMap'}.'.rsw'} eq "") {
			print "Invalid map specified for lockMap - map $config{'lockMap'} doesn't exist\n";
		} else {
			# Lock an area instead to lock a spot
			if ($config{'lockMap_x'} ne "") {
				$ai_v{'lockMap'}{'pos_to'}{'x'} = $config{'lockMap_x'};
				$ai_v{'lockMap'}{'pos_to'}{'y'} = $config{'lockMap_y'};
				if ($config{'lockMap_rand'} > 0 && $field{'name'} eq $config{'lockMap'}) {
					undef $ai_v{'temp'}{'rand'};
					do {
						%{$ai_v{'temp'}{'rand'}} = randOffset(\%{$ai_v{'lockMap'}{'pos_to'}}, $config{'lockMap_rand'});
					} while ($field{'name'}[$ai_v{'temp'}{'rand'}{'y'} * $field{'width'} + $ai_v{'temp'}{'rand'}{'x'}]);
					%{$ai_v{'lockMap'}{'pos_to'}} = %{$ai_v{'temp'}{'rand'}};
				}
				print "Calculating lockMap route to: $maps_lut{$config{'lockMap'}.'.rsw'}($config{'lockMap'}): $ai_v{'lockMap'}{'pos_to'}{'x'}, $ai_v{'lockMap'}{'pos_to'}{'y'}\n";
			} else {
				undef %{$ai_v{'lockMap'}{'pos_to'}};
				print "Calculating lockMap route to: $maps_lut{$config{'lockMap'}.'.rsw'}($config{'lockMap'})\n";
			}
			if ($field{'name'} ne $config{'lockMap'} || !defined(%{$ai_v{'lockMap'}{'pos_to'}})) {
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $config{'lockMap_x'}, $config{'lockMap_y'}, $config{'lockMap'}, 0, 0, 1, 0, 0, 1);
			} else {
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'lockMap'}{'pos_to'}{'x'}, $ai_v{'lockMap'}{'pos_to'}{'y'}, $config{'lockMap'}, 0, 0, 2, 0, 0, 1);
			}
		}
	}

	##### RANDOM WALK #####
	if ($config{'route_randomWalk'} && $ai_seq[0] eq "" && length($field{'rawMap'}) > 1 && !$cities_lut{$field{'name'}.'.rsw'}) {
		do {
			$ai_v{'temp'}{'randX'} = int(rand() * ($field{'width'} - 1));
			$ai_v{'temp'}{'randY'} = int(rand() * ($field{'height'} - 1));
		} while (ai_route_getOffset(\%field, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}));
		print "Calculating random route to: $maps_lut{$field{'name'}.'.rsw'}($field{'name'}): $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}\n";
		ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $field{'name'}, 0, $config{'route_randomWalk_maxRouteTime'}, 2);
	}

	##### DEAD #####


	if ($ai_seq[0] eq "dead" && !$chars[$config{'char'}]{'dead'}) {
		shift @ai_seq;
		shift @ai_seq_args;

		#force storage after death
		unshift @ai_seq, "storageAuto";
		unshift @ai_seq_args, {};
	} elsif ($ai_seq[0] ne "dead" && $chars[$config{'char'}]{'dead'}) {
		undef @ai_seq;
		undef @ai_seq_args;
		unshift @ai_seq, "dead";
		unshift @ai_seq_args, {};
	}

	if ($ai_seq[0] eq "dead" && time - $chars[$config{'char'}]{'dead_time'} >= $timeout{'ai_dead_respawn'}{'timeout'}) {
		sendRespawn(\$remote_socket);
		$chars[$config{'char'}]{'dead_time'} = time;
	}

	if ($ai_seq[0] eq "dead" && $config{'dcOnDeath'}) {
		print "Disconnecting on death!\n";
		$quit = 1;
	}


	##### AUTO-ITEM USE #####


	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute"
		|| $ai_seq[0] eq "follow" || $ai_seq[0] eq "sitAuto" || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather"
		|| $ai_seq[0] eq "items_take" || $ai_seq[0] eq "attack")
		&& timeOut(\%{$timeout{'ai_item_use_auto'}})) {
		$i = 0;
		while (1) {
			last if (!$config{"useSelf_item_$i"});
			if (percent_hp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_item_$i"."_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_item_$i"."_hp_lower"}
				&& percent_sp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_item_$i"."_sp_upper"} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_item_$i"."_sp_lower"}
				&& !($config{"useSelf_item_$i"."_stopWhenHit"} && ai_getMonstersWhoHitMe())
				&& $config{"useSelf_item_$i"."_minAggressives"} <= ai_getAggressives()
				&& (!$config{"useSelf_item_$i"."_maxAggressives"} || $config{"useSelf_item_$i"."_maxAggressives"} >= ai_getAggressives())
				# Timeout support
				&& timeOut($config{"useSelf_item_$i"."_timeout"}, $ai_v{"useSelf_item_$i"."_time"})
				# Use in lockMap only
				&& (!$config{"useSelf_item_$i"."_inLockOnly"} || $config{"useSelf_item_$i"."_inLockOnly"} && $field{'name'} eq $config{'lockMap'})) {
				# Judge parameter and status
				undef $ai_v{'temp'}{'found'};
				if ($config{"useSelf_item_$i"."_status"}) {
					foreach (@{$chars[$config{'char'}]{'status'}}) {
						if (existsInList($config{"useSelf_item_$i"."_status"}, $_)) {
							$ai_v{'temp'}{'found'} = 1;
							last;
						}
					}
					$ai_v{'temp'}{'found'} = 1 - $ai_v{'temp'}{'found'} if ($config{"useSelf_item_$i"."_status"} < 0);
				}
				if ($config{"useSelf_item_$i"."_param2"} && !($config{"useSelf_item_$i"."_param2"} & $chars[$config{'char'}]{'param2'})) {
					$ai_v{'temp'}{'found'} = 1;
				}
				if (!$ai_v{'temp'}{'found'}) {
					$ai_v{"useSelf_item_$i"."_time"} = time;
					undef $ai_v{'temp'}{'invIndex'};
					$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"useSelf_item_$i"});
					if ($ai_v{'temp'}{'invIndex'} ne "") {
						# Item use repeat
						if (!$config{"useSelf_item_$i"."_repeat"}) {
							$config{"useSelf_item_$i"."_repeat"} = 1;
						}
						my $c;
						for ($c = 0; $c < $config{"useSelf_item_$i"."_repeat"}; $c++) {
							sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $accountID);
						}
						$timeout{'ai_item_use_auto'}{'time'} = time;
						print qq~Auto-item use: $items_lut{$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'nameID'}}\n~ if $config{'debug'};
						last;
					}
				}
			}
			$i++;
		}
	}



	##### AUTO-SKILL USE #####


	if ($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute"
		|| $ai_seq[0] eq "follow" || $ai_seq[0] eq "sitAuto" || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather"
		|| $ai_seq[0] eq "items_take" || $ai_seq[0] eq "attack") {
		$i = 0;
		undef $ai_v{'useSelf_skill'};
		undef $ai_v{'useSelf_skill_lvl'};
		my $ai_index_attack = binFind(\@ai_seq, "attack");
		my $ai_index_take = binFind(\@ai_seq, "take");
		while (1) {
			last if (!$config{"useSelf_skill_$i"});
			if (percent_hp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_skill_$i"."_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_skill_$i"."_hp_lower"}
				&& percent_sp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_skill_$i"."_sp_upper"} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_skill_$i"."_sp_lower"}
				&& $chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc($config{"useSelf_skill_$i"})}}{$config{"useSelf_skill_$i"."_lvl"}}
				&& timeOut($config{"useSelf_skill_$i"."_timeout"}, $ai_v{"useSelf_skill_$i"."_time"})
				&& !($config{"useSelf_skill_$i"."_stopWhenHit"} && ai_getMonstersWhoHitMe())
				&& $config{"useSelf_skill_$i"."_minAggressives"} <= ai_getAggressives()
				&& (!$config{"useSelf_skill_$i"."_maxAggressives"} || $config{"useSelf_skill_$i"."_maxAggressives"} >= ai_getAggressives())
				# Spirits support
				&& $chars[$config{'char'}]{'spirits'} >= $config{"useSelf_skill_$i"."_spirits_lower"} && $chars[$config{'char'}]{'spirits'} <= $config{"useSelf_skill_$i"."_spirits_upper"}
				# Check if vital when taking
				&& ($config{"useSelf_skill_$i"."_vital"} || $ai_index_take eq "" || $ai_index_attack ne "")
				# Allow to use in city or not
				&& ($config{"useSelf_skill_$i"."_inCity"} || !$cities_lut{$field{'name'}.'.rsw'})
				# Use in lockMap only
				&& (!$config{"useSelf_skill_$i"."_inLockOnly"} || $config{"useSelf_skill_$i"."_inLockOnly"} && $field{'name'} eq $config{'lockMap'})) {
				# Judge parameter and status
				undef $ai_v{'temp'}{'found'};
				if ($config{"useSelf_skill_$i"."_status"}) {
					foreach (@{$chars[$config{'char'}]{'status'}}) {
						if (existsInList($config{"useSelf_skill_$i"."_status"}, $_)) {
							$ai_v{'temp'}{'found'} = 1;
							last;
						}
					}
					$ai_v{'temp'}{'found'} = 1 - $ai_v{'temp'}{'found'} if ($config{"useSelf_skill_$i"."_status"} < 0);
				}
				if ($config{"useSelf_skill_$i"."_param2"} && !($config{"useSelf_skill_$i"."_param2"} & $chars[$config{'char'}]{'param2'})) {
					$ai_v{'temp'}{'found'} = 1;
				}
				if (!$ai_v{'temp'}{'found'}) {
					$ai_v{"useSelf_skill_$i"."_time"} = time;
					$ai_v{'useSelf_skill'} = $config{"useSelf_skill_$i"};
					$ai_v{'useSelf_skill_lvl'} = $config{"useSelf_skill_$i"."_lvl"};
					$ai_v{'useSelf_skill_maxCastTime'} = $config{"useSelf_skill_$i"."_maxCastTime"};
					$ai_v{'useSelf_skill_minCastTime'} = $config{"useSelf_skill_$i"."_minCastTime"};
					last;
				}
			}
			$i++;
		}
		if ($config{'useSelf_skill_smartHeal'} && $skills_rlut{lc($ai_v{'useSelf_skill'})} eq "AL_HEAL") {
			undef $ai_v{'useSelf_skill_smartHeal_lvl'};
			$ai_v{'useSelf_skill_smartHeal_hp_dif'} = $chars[$config{'char'}]{'hp_max'} - $chars[$config{'char'}]{'hp'};
			for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useSelf_skill'})}}{'lv'}; $i++) {
				$ai_v{'useSelf_skill_smartHeal_lvl'} = $i;
				$ai_v{'useSelf_skill_smartHeal_sp'} = 10 + ($i * 3);
				$ai_v{'useSelf_skill_smartHeal_amount'} = int(($chars[$config{'char'}]{'lv'} + $chars[$config{'char'}]{'int'}) / 8)
						* (4 + $i * 8);
				if ($chars[$config{'char'}]{'sp'} < $ai_v{'useSelf_skill_smartHeal_sp'}) {
					$ai_v{'useSelf_skill_smartHeal_lvl'}--;
					last;
				}
				last if ($ai_v{'useSelf_skill_smartHeal_amount'} >= $ai_v{'useSelf_skill_smartHeal_hp_dif'});
			}
			$ai_v{'useSelf_skill_lvl'} = $ai_v{'useSelf_skill_smartHeal_lvl'};
		}
		if ($ai_v{'useSelf_skill_lvl'} > 0) {
			print qq~Auto-skill on self: $skills_lut{$skills_rlut{lc($ai_v{'useSelf_skill'})}} (lvl $ai_v{'useSelf_skill_lvl'})\n~ if $config{'debug'};
			if (!ai_getSkillUseType($skills_rlut{lc($ai_v{'useSelf_skill'})})) {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useSelf_skill'})}}{'ID'}, $ai_v{'useSelf_skill_lvl'}, $ai_v{'useSelf_skill_maxCastTime'}, $ai_v{'useSelf_skill_minCastTime'}, $accountID);
			} else {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useSelf_skill'})}}{'ID'}, $ai_v{'useSelf_skill_lvl'}, $ai_v{'useSelf_skill_maxCastTime'}, $ai_v{'useSelf_skill_minCastTime'}, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
			}
		}
	}



	##### AUTO-EQUIP CHANGE #####


	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute"
		|| $ai_seq[0] eq "sitAuto" || $ai_seq[0] eq "attack" || $ai_seq[0] eq "skill_use" && !$ai_seq_args[0]{'skill_used'})
		&& timeOut(\%{$timeout{'ai_equip_auto'}})) {
		judgeEquip();
		$timeout{'ai_equip_auto'}{'time'} = time;
	}



	##### SKILL USE #####


	if ($ai_seq[0] eq "skill_use" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_skill_use_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		$ai_seq_args[0]{'ai_skill_use_minCastTime'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		$ai_seq_args[0]{'ai_skill_use_maxCastTime'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "skill_use") {
		if ($chars[$config{'char'}]{'sitting'}) {
			ai_setSuspend(0);
			stand();
		} elsif (!$ai_seq_args[0]{'skill_used'}) {
			$ai_seq_args[0]{'skill_used'} = 1;
			$ai_seq_args[0]{'ai_skill_use_giveup'}{'time'} = time;
			if ($ai_seq_args[0]{'skill_use_target_x'} ne "") {
				sendSkillUseLoc(\$remote_socket, $ai_seq_args[0]{'skill_use_id'}, $ai_seq_args[0]{'skill_use_lv'}, $ai_seq_args[0]{'skill_use_target_x'}, $ai_seq_args[0]{'skill_use_target_y'});
			} else {
				sendSkillUse(\$remote_socket, $ai_seq_args[0]{'skill_use_id'}, $ai_seq_args[0]{'skill_use_lv'}, $ai_seq_args[0]{'skill_use_target'});
			}
			$ai_seq_args[0]{'skill_use_last'} = $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$ai_seq_args[0]{'skill_use_id'}})}}{'time_used'};
			undef $timeout{'ai_attack'}{'time'};

		} elsif (($ai_seq_args[0]{'skill_use_last'} != $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$ai_seq_args[0]{'skill_use_id'}})}}{'time_used'}
			|| (timeOut(\%{$ai_seq_args[0]{'ai_skill_use_giveup'}}) && (!$chars[$config{'char'}]{'time_cast'} || !$ai_seq_args[0]{'skill_use_maxCastTime'}{'timeout'}))
			|| ($ai_seq_args[0]{'skill_use_maxCastTime'}{'timeout'} && timeOut(\%{$ai_seq_args[0]{'skill_use_maxCastTime'}})))
			&& timeOut(\%{$ai_seq_args[0]{'skill_use_minCastTime'}})) {
			shift @ai_seq;
			shift @ai_seq_args;
		}
	}




	##### FOLLOW #####


	if ($ai_seq[0] eq "" && $config{'follow'}) {
		ai_follow($config{'followTarget'});
	}
	if ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'suspended'}) {
		if ($ai_seq_args[0]{'ai_follow_lost'}) {
			$ai_seq_args[0]{'ai_follow_lost_end'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		}
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "follow" && !$ai_seq_args[0]{'ai_follow_lost'}) {
		if (!$ai_seq_args[0]{'following'}) {
			foreach (keys %players) {
				if ($players{$_}{'name'} eq $ai_seq_args[0]{'name'} && !$players{$_}{'dead'}) {
					$ai_seq_args[0]{'ID'} = $_;
					$ai_seq_args[0]{'following'} = 1;
					last;
				}
			}
		}
		if ($ai_seq_args[0]{'following'} && $players{$ai_seq_args[0]{'ID'}}{'pos_to'}) {
			$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$ai_seq_args[0]{'ID'}}{'pos_to'}});
			if ($ai_v{'temp'}{'dist'} > $config{'followDistanceMax'}) {
				ai_route(\%{$ai_seq_args[0]{'ai_route_returnHash'}}, $players{$ai_seq_args[0]{'ID'}}{'pos_to'}{'x'}, $players{$ai_seq_args[0]{'ID'}}{'pos_to'}{'y'}, $field{'name'}, 0, 0, 1, 0, $config{'followDistanceMin'});
			}
		}
		if ($ai_seq_args[0]{'following'} && $players{$ai_seq_args[0]{'ID'}}{'sitting'} == 1 && $chars[$config{'char'}]{'sitting'} == 0) {
			sit();
		}
	}

	if ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'following'} && ($players{$ai_seq_args[0]{'ID'}}{'dead'} || $players_old{$ai_seq_args[0]{'ID'}}{'dead'})) {
		print "Master died.  I'll wait here.\n";
		undef $ai_seq_args[0]{'following'};
	} elsif ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'following'} && !%{$players{$ai_seq_args[0]{'ID'}}}) {
		print "I lost my master\n";
		undef $ai_seq_args[0]{'following'};
		if ($players_old{$ai_seq_args[0]{'ID'}}{'disconnected'}) {
			print "My master disconnected\n";

		} elsif ($players_old{$ai_seq_args[0]{'ID'}}{'disappeared'}) {
			print "Trying to find lost master\n";
			undef $ai_seq_args[0]{'ai_follow_lost_char_last_pos'};
			undef $ai_seq_args[0]{'follow_lost_portal_tried'};
			$ai_seq_args[0]{'ai_follow_lost'} = 1;
			$ai_seq_args[0]{'ai_follow_lost_end'}{'timeout'} = $timeout{'ai_follow_lost_end'}{'timeout'};
			$ai_seq_args[0]{'ai_follow_lost_end'}{'time'} = time;
			getVector(\%{$ai_seq_args[0]{'ai_follow_lost_vec'}}, \%{$players_old{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$chars[$config{'char'}]{'pos_to'}});

			#check if player went through portal
			$ai_v{'temp'}{'first'} = 1;
			undef $ai_v{'temp'}{'foundID'};
			undef $ai_v{'temp'}{'smallDist'};
			foreach (@portalsID) {
				$ai_v{'temp'}{'dist'} = distance(\%{$players_old{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$portals{$_}{'pos'}});
				if ($ai_v{'temp'}{'dist'} <= 7 && ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'})) {
					$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
					$ai_v{'temp'}{'foundID'} = $_;
					undef $ai_v{'temp'}{'first'};
				}
			}
			$ai_seq_args[0]{'follow_lost_portalID'} = $ai_v{'temp'}{'foundID'};
		} else {
			print "Don't know what happened to Master\n";
		}
	}




	##### FOLLOW-LOST #####


	if ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'ai_follow_lost'}) {
		if ($ai_seq_args[0]{'ai_follow_lost_char_last_pos'}{'x'} == $chars[$config{'char'}]{'pos_to'}{'x'} && $ai_seq_args[0]{'ai_follow_lost_char_last_pos'}{'y'} == $chars[$config{'char'}]{'pos_to'}{'y'}) {
			$ai_seq_args[0]{'lost_stuck'}++;
		} else {
			undef $ai_seq_args[0]{'lost_stuck'};
		}
		%{$ai_seq_args[0]{'ai_follow_lost_char_last_pos'}} = %{$chars[$config{'char'}]{'pos_to'}};

		if (timeOut(\%{$ai_seq_args[0]{'ai_follow_lost_end'}})) {
			undef $ai_seq_args[0]{'ai_follow_lost'};
			print "Couldn't find master, giving up\n";

		} elsif ($players_old{$ai_seq_args[0]{'ID'}}{'disconnected'}) {
			undef $ai_seq_args[0]{'ai_follow_lost'};
			print "My master disconnected\n";

		} elsif (%{$players{$ai_seq_args[0]{'ID'}}}) {
			$ai_seq_args[0]{'following'} = 1;
			undef $ai_seq_args[0]{'ai_follow_lost'};
			print "Found my master!\n";

		} elsif ($ai_seq_args[0]{'lost_stuck'}) {
			if ($ai_seq_args[0]{'follow_lost_portalID'} eq "") {
				moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'ai_follow_lost_vec'}}, $config{'followLostStep'} / ($ai_seq_args[0]{'lost_stuck'} + 1));
				move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
			}
		} else {
			if ($ai_seq_args[0]{'follow_lost_portalID'} ne "") {
				if (%{$portals{$ai_seq_args[0]{'follow_lost_portalID'}}} && !$ai_seq_args[0]{'follow_lost_portal_tried'}) {
					$ai_seq_args[0]{'follow_lost_portal_tried'} = 1;
					%{$ai_v{'temp'}{'pos'}} = %{$portals{$ai_seq_args[0]{'follow_lost_portalID'}}{'pos'}};
					ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}, $field{'name'}, 0, 0, 1);
				}
			} else {
				moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'ai_follow_lost_vec'}}, $config{'followLostStep'});
				move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
			}
		}
	}

	##### AUTO-SIT/SIT/STAND #####


	if ($config{'sitAuto_idle'} && ($ai_seq[0] ne "" && $ai_seq[0] ne "follow")) {
		$timeout{'ai_sit_idle'}{'time'} = time;
	}
	if (($ai_seq[0] eq "" || $ai_seq[0] eq "follow") && $config{'sitAuto_idle'} && !$chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_sit_idle'}})) {
		# Open shop before auto-sitting when idle
		if ($config{'shopAuto_open'} && !$shop{'opened'}) {
			ai_skillUse($chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'ID'}, $chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'lv'}, 10, 0, $accountID) if (!$shop{'maxItems'} && $chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'lv'});
			sendOpenShop(\$remote_socket) if ($shop{'maxItems'});
			ai_clientSuspend(0, 5);
		} else {
			sit();
		}
	}
	if ($ai_seq[0] eq "sitting" && ($chars[$config{'char'}]{'sitting'} || $chars[$config{'char'}]{'skills'}{'NV_BASIC'}{'lv'} < 3)) {
		shift @ai_seq;
		shift @ai_seq_args;
		$timeout{'ai_sit'}{'time'} -= $timeout{'ai_sit'}{'timeout'};
	} elsif ($ai_seq[0] eq "sitting" && !$chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_sit'}}) && timeOut(\%{$timeout{'ai_sit_wait'}})) {
		sendSit(\$remote_socket);
		$timeout{'ai_sit'}{'time'} = time;
	}
	if ($ai_seq[0] eq "standing" && !$chars[$config{'char'}]{'sitting'} && !$timeout{'ai_stand_wait'}{'time'}) {
		$timeout{'ai_stand_wait'}{'time'} = time;
	} elsif ($ai_seq[0] eq "standing" && !$chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_stand_wait'}})) {
		shift @ai_seq;
		shift @ai_seq_args;
		undef $timeout{'ai_stand_wait'}{'time'};
		$timeout{'ai_sit'}{'time'} -= $timeout{'ai_sit'}{'timeout'};
	} elsif ($ai_seq[0] eq "standing" && $chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_sit'}})) {
		sendStand(\$remote_socket);
		$timeout{'ai_sit'}{'time'} = time;
	}

	if ($ai_v{'sitAuto_forceStop'} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_hp_lower'} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_sp_lower'}) {
		$ai_v{'sitAuto_forceStop'} = 0;
	}

	if (!$ai_v{'sitAuto_forceStop'} && ($ai_seq[0] eq "" || $ai_seq[0] eq "follow" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute") && binFind(\@ai_seq, "attack") eq "" && binFind(\@ai_seq, "healAuto") eq "" && !ai_getAggressives()
		&& (percent_hp(\%{$chars[$config{'char'}]}) < $config{'sitAuto_hp_lower'} || percent_sp(\%{$chars[$config{'char'}]}) < $config{'sitAuto_sp_lower'})
		&& percent_weight(\%{$chars[$config{'char'}]}) < 50) {
		unshift @ai_seq, "sitAuto";
		unshift @ai_seq_args, {};
		print "Auto-sitting\n" if $config{'debug'};
		# Auto equip change
		judgeEquip();
	}
	if ($ai_seq[0] eq "sitAuto" && !$chars[$config{'char'}]{'sitting'} && $chars[$config{'char'}]{'skills'}{'NV_BASIC'}{'lv'} >= 3
		&& !ai_getAggressives()) {
		sit();
	}
	if ($ai_seq[0] eq "sitAuto" && ($ai_v{'sitAuto_forceStop'}
		|| (percent_hp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_hp_upper'} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_sp_upper'})
		|| percent_weight(\%{$chars[$config{'char'}]}) >= 50)) {
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$config{'sitAuto_idle'} && $chars[$config{'char'}]{'sitting'}) {
			stand();
		}
	}


	##### AUTO-ATTACK #####


	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute" || $ai_seq[0] eq "follow"
		|| $ai_seq[0] eq "sitAuto" || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather" || $ai_seq[0] eq "items_take")
		&& !($config{'itemsTakeAuto'} >= 2 && ($ai_seq[0] eq "take" || $ai_seq[0] eq "items_take"))
		&& !($config{'itemsGatherAuto'} >= 2 && ($ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather"))
		&& timeOut(\%{$timeout{'ai_attack_auto'}})) {
		undef @{$ai_v{'ai_attack_agMonsters'}};
		undef @{$ai_v{'ai_attack_cleanMonsters'}};
		undef @{$ai_v{'ai_attack_partyMonsters'}};
		undef $ai_v{'temp'}{'foundID'};
		if ($config{'tankMode'}) {
			undef $ai_v{'temp'}{'found'};
			foreach (@playersID) {
				next if ($_ eq "");
				if ($config{'tankModeTarget'} eq $players{$_}{'name'}) {
					$ai_v{'temp'}{'found'} = 1;
					last;
				}
			}
		}
		if (!$config{'tankMode'} || ($config{'tankMode'} && $ai_v{'temp'}{'found'})) {
			$ai_v{'temp'}{'ai_follow_index'} = binFind(\@ai_seq, "follow");
			if ($ai_v{'temp'}{'ai_follow_index'} ne "") {
				$ai_v{'temp'}{'ai_follow_following'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'following'};
				$ai_v{'temp'}{'ai_follow_ID'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'ID'};
			} else {
				undef $ai_v{'temp'}{'ai_follow_following'};
			}
			$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
			if ($ai_v{'temp'}{'ai_route_index'} ne "") {
				$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
			}
			@{$ai_v{'ai_attack_agMonsters'}} = ai_getAggressives() if ($config{'attackAuto'} && !($ai_v{'temp'}{'ai_route_index'} ne "" && !$ai_v{'temp'}{'ai_route_attackOnRoute'}));
			foreach (@monstersID) {
				next if ($_ eq "");
				if ((($config{'attackAuto_party'}
					&& $ai_seq[0] ne "take" && $ai_seq[0] ne "items_take"
					&& ($monsters{$_}{'dmgToParty'} > 0 || $monsters{$_}{'dmgFromParty'} > 0))
					|| ($config{'attackAuto_followTarget'} && $ai_v{'temp'}{'ai_follow_following'}
					&& ($monsters{$_}{'dmgToPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0 || $monsters{$_}{'dmgFromPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0)))
					&& !($ai_v{'temp'}{'ai_route_index'} ne "" && !$ai_v{'temp'}{'ai_route_attackOnRoute'})
					&& $monsters{$_}{'attack_failed'} == 0 && ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} >= 1 || $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "")) {
					push @{$ai_v{'ai_attack_partyMonsters'}}, $_;
					# Detect kill steal
					$monsters{$_}{'judge'} = 1;

				} elsif ($config{'attackAuto'} >= 2
					&& $ai_seq[0] ne "sitAuto" && $ai_seq[0] ne "take" && $ai_seq[0] ne "items_gather" && $ai_seq[0] ne "items_take"
					&& !($monsters{$_}{'dmgFromYou'} == 0 && ($monsters{$_}{'dmgTo'} > 0 || $monsters{$_}{'dmgFrom'} > 0 || %{$monsters{$_}{'missedFromPlayer'}} || %{$monsters{$_}{'missedToPlayer'}} || %{$monsters{$_}{'castOnByPlayer'}})) && $monsters{$_}{'attack_failed'} == 0
					&& !($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1)
					&& ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} >= 1 || $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "")) {
					# Prevent kill steal
					my $m_cDist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
					my $m_plDist_small;
					my $Ankled;
					for ($i = 0; $i < @playersID; $i++) {
						next if ($playersID[$i] eq "");
						my $m_plDist = distance(\%{$players{$playersID[$i]}{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
						if ($m_plDist_small eq "" || $m_plDist < $m_plDist_small) {
							$m_plDist_small = $m_plDist;
						}
					}
					for ($i = 0; $i < @spellsID; $i++) {
						next if ($spellsID[$i] eq "" || $spells{$spellsID[$i]}{'type'} != 91);
						$Ankled = 1 if (distance(\%{$spells{$spellsID[$i]}{'pos'}}, \%{$monsters{$_}{'pos_to'}}) <= 1);
					}
					if (timeOut($config{'attackAuto_wait'}, $monsters{$_}{'appear_time'})
						&& (!$Ankled && $monsters{$_}{'param1'} != 2
							&& (!$m_plDist_small || $m_cDist <= $m_plDist_small || $m_plDist_small >= $config{'NotAttackDistance'})
							# MVP control
							|| binFind(\@MVPID, $monsters{$_}{'nameID'}) ne "")) {
						push @{$ai_v{'ai_attack_cleanMonsters'}}, $_;
						# Detect kill steal
						$monsters{$_}{'judge'} = 1 if (binFind(\@MVPID, $monsters{$_}{'nameID'}) ne "" || binFind(\@RMID, $monsters{$_}{'nameID'}) ne "");
					}
				}
			}
			undef $ai_v{'temp'}{'distSmall'};
			undef $ai_v{'temp'}{'foundID'};
			$ai_v{'temp'}{'first'} = 1;
			foreach (@{$ai_v{'ai_attack_agMonsters'}}) {
				$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
				if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'distSmall'}) {
					$ai_v{'temp'}{'distSmall'} = $ai_v{'temp'}{'dist'};
					$ai_v{'temp'}{'foundID'} = $_;
					undef $ai_v{'temp'}{'first'};
				}
			}
			if (!$ai_v{'temp'}{'foundID'}) {
				undef $ai_v{'temp'}{'distSmall'};
				undef $ai_v{'temp'}{'foundID'};
				$ai_v{'temp'}{'first'} = 1;
				foreach (@{$ai_v{'ai_attack_partyMonsters'}}) {
					$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
					if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'distSmall'}) {
						$ai_v{'temp'}{'distSmall'} = $ai_v{'temp'}{'dist'};
						$ai_v{'temp'}{'foundID'} = $_;
						undef $ai_v{'temp'}{'first'};
					}
				}
			}
			if (!$ai_v{'temp'}{'foundID'}) {
				undef $ai_v{'temp'}{'distSmall'};
				undef $ai_v{'temp'}{'foundID'};
				$ai_v{'temp'}{'first'} = 1;
				foreach (@{$ai_v{'ai_attack_cleanMonsters'}}) {
					$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
					if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'distSmall'}) {
						$ai_v{'temp'}{'distSmall'} = $ai_v{'temp'}{'dist'};
						$ai_v{'temp'}{'foundID'} = $_;
						undef $ai_v{'temp'}{'first'};
					}
				}
			}
		}
		if ($ai_v{'temp'}{'foundID'}) {
			ai_setSuspend(0);
			attack($ai_v{'temp'}{'foundID'});
		} else {
			$timeout{'ai_attack_auto'}{'time'} = time;
		}
	}




	##### ATTACK #####


	if ($ai_seq[0] eq "attack" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_attack_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "attack" && timeOut(\%{$ai_seq_args[0]{'ai_attack_giveup'}})) {
		$monsters{$ai_seq_args[0]{'ID'}}{'attack_failed'}++;
		shift @ai_seq;
		shift @ai_seq_args;
		print "Can't reach or damage target, dropping target\n";
	} elsif ($ai_seq[0] eq "attack" && !%{$monsters{$ai_seq_args[0]{'ID'}}}) {
		$timeout{'ai_attack'}{'time'} -= $timeout{'ai_attack'}{'timeout'};
		$ai_v{'ai_attack_ID_old'} = $ai_seq_args[0]{'ID'};
		shift @ai_seq;
		shift @ai_seq_args;
		if ($monsters_old{$ai_v{'ai_attack_ID_old'}}{'dead'}) {
			print "Target died\n";
			# Record defeated monster
			$defeatMonster{$monsters_old{$ai_v{'ai_attack_ID_old'}}{'name'}}++;
			if ($config{'itemsTakeAuto'} && $monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgFromYou'} > 0) {
				ai_items_take($monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos'}{'x'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos'}{'y'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos_to'}{'x'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos_to'}{'y'});
			} else {
				ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
			}
		} else {
			print "Target lost\n";
		}
	} elsif ($ai_seq[0] eq "attack") {
		$ai_v{'temp'}{'ai_follow_index'} = binFind(\@ai_seq, "follow");
		if ($ai_v{'temp'}{'ai_follow_index'} ne "") {
			$ai_v{'temp'}{'ai_follow_following'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'following'};
			$ai_v{'temp'}{'ai_follow_ID'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'ID'};
		} else {
			undef $ai_v{'temp'}{'ai_follow_following'};
		}
		$ai_v{'ai_attack_monsterDist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}});
		$ai_v{'ai_attack_cleanMonster'} = (!($monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'} == 0 && ($monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'dmgFrom'} > 0 || %{$monsters{$ai_seq_args[0]{'ID'}}{'missedFromPlayer'}} || %{$monsters{$ai_seq_args[0]{'ID'}}{'missedToPlayer'}} || %{$monsters{$ai_seq_args[0]{'ID'}}{'castOnByPlayer'}}))
				|| ($config{'attackAuto_party'} && ($monsters{$ai_seq_args[0]{'ID'}}{'dmgFromParty'} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'dmgToParty'} > 0))
				|| ($config{'attackAuto_followTarget'} && $ai_v{'temp'}{'ai_follow_following'} && ($monsters{$ai_seq_args[0]{'ID'}}{'dmgToPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0))
				|| ($monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'missedYou'} > 0)
				# MVP control
				|| binFind(\@MVPID, $monsters{$ai_seq_args[0]{'ID'}}{'nameID'}) ne "");
		if ($ai_seq_args[0]{'dmgToYou_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'}
			|| $ai_seq_args[0]{'missedYou_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'missedYou'}
			|| $ai_seq_args[0]{'dmgFromYou_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'}) {
				$ai_seq_args[0]{'ai_attack_giveup'}{'time'} = time;
		}
		$ai_seq_args[0]{'dmgToYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'};
		$ai_seq_args[0]{'missedYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'missedYou'};
		$ai_seq_args[0]{'dmgFromYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'};
		$ai_seq_args[0]{'missedFromYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'missedFromYou'};
		if (!%{$ai_seq_args[0]{'attackMethod'}}) {
			if ($config{'attackUseWeapon'}) {
				$ai_seq_args[0]{'attackMethod'}{'distance'} = $config{'attackDistance'};
				$ai_seq_args[0]{'attackMethod'}{'type'} = "weapon";
			} else {
				$ai_seq_args[0]{'attackMethod'}{'distance'} = 30;
				undef $ai_seq_args[0]{'attackMethod'}{'type'};
			}
			$i = 0;
			while ($config{"attackSkillSlot_$i"} ne "") {
				if (percent_hp(\%{$chars[$config{'char'}]}) >= $config{"attackSkillSlot_$i"."_hp_lower"} && percent_hp(\%{$chars[$config{'char'}]}) <= $config{"attackSkillSlot_$i"."_hp_upper"}
					&& percent_sp(\%{$chars[$config{'char'}]}) >= $config{"attackSkillSlot_$i"."_sp_lower"} && percent_sp(\%{$chars[$config{'char'}]}) <= $config{"attackSkillSlot_$i"."_sp_upper"}
					&& $chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc($config{"attackSkillSlot_$i"})}}{$config{"attackSkillSlot_$i"."_lvl"}}
					&& !($config{"attackSkillSlot_$i"."_stopWhenHit"} && ai_getMonstersWhoHitMe())
					&& (!$config{"attackSkillSlot_$i"."_maxUses"} || $ai_seq_args[0]{'attackSkillSlot_uses'}{$i} < $config{"attackSkillSlot_$i"."_maxUses"})
					&& $config{"attackSkillSlot_$i"."_minAggressives"} <= ai_getAggressives()
					&& (!$config{"attackSkillSlot_$i"."_maxAggressives"} || $config{"attackSkillSlot_$i"."_maxAggressives"} >= ai_getAggressives())
					&& (!$config{"attackSkillSlot_$i"."_monsters"} || existsInList($config{"attackSkillSlot_$i"."_monsters"}, $monsters{$ai_seq_args[0]{'ID'}}{'name'}))
					# Spirits support
					&& $chars[$config{'char'}]{'spirits'} >= $config{"attackSkillSlot_$i"."_spirits_lower"} && $chars[$config{'char'}]{'spirits'} <= $config{"attackSkillSlot_$i"."_spirits_upper"}
					# Timeout support
					&& timeOut($config{"attackSkillSlot_$i"."_timeout"}, $ai_v{"attackSkillSlot_$i"."_time"})
					# Allow to use in city or not
					&& ($config{"attackSkillSlot_$i"."_inCity"} || !$cities_lut{$field{'name'}.'.rsw'})) {
					# Judge parameter and status
					undef $ai_v{'temp'}{'found'};
					if ($config{"attackSkillSlot_$i"."_status"}) {
						foreach (@{$chars[$config{'char'}]{'status'}}) {
							if (existsInList($config{"attackSkillSlot_$i"."_status"}, $_)) {
								$ai_v{'temp'}{'found'} = 1;
								last;
							}
						}
						$ai_v{'temp'}{'found'} = 1 - $ai_v{'temp'}{'found'} if ($config{"attackSkillSlot_$i"."_status"} < 0);
					}
					if ($config{"attackSkillSlot_$i"."_param1"} && !existsInList($config{"attackSkillSlot_$i"."_param1"}, $monsters{$ai_seq_args[0]{'ID'}}{'param1'})
						|| $config{"attackSkillSlot_$i"."_param2"} && !($config{"attackSkillSlot_$i"."_param2"} & $monsters{$ai_seq_args[0]{'ID'}}{'param2'})
						|| $config{"attackSkillSlot_$i"."_param3"} && !($config{"attackSkillSlot_$i"."_param3"} & $monsters{$ai_seq_args[0]{'ID'}}{'param3'})
						|| $config{"attackSkillSlot_$i"."_paramNot1"} && existsInList($config{"attackSkillSlot_$i"."_paramNot1"}, $monsters{$ai_seq_args[0]{'ID'}}{'param1'})
						|| $config{"attackSkillSlot_$i"."_paramNot2"} && ($config{"attackSkillSlot_$i"."_paramNot2"} & $monsters{$ai_seq_args[0]{'ID'}}{'param2'})
						|| $config{"attackSkillSlot_$i"."_paramNot3"} && ($config{"attackSkillSlot_$i"."_paramNot3"} & $monsters{$ai_seq_args[0]{'ID'}}{'param3'})) {
						$ai_v{'temp'}{'found'} = 1;
					}
					if (!$ai_v{'temp'}{'found'}) {
						$ai_v{"attackSkillSlot_$i"."_time"} = time;
						$ai_seq_args[0]{'attackSkillSlot_uses'}{$i}++;
						$ai_seq_args[0]{'attackMethod'}{'distance'} = $config{"attackSkillSlot_$i"."_dist"};
						$ai_seq_args[0]{'attackMethod'}{'type'} = "skill";
						$ai_seq_args[0]{'attackMethod'}{'skillSlot'} = $i;
						# Looping skills support
						if ($config{"attackSkillSlot_$i"."_loopSlot"} ne "" && $ai_seq_args[0]{'attackSkillSlot_uses'}{$i} >= $config{"attackSkillSlot_$i"."_maxUses"}) {
							undef $ai_v{qq~attackSkillSlot_$config{"attackSkillSlot_$i"."_loopSlot"}~."_time"};
							undef $ai_seq_args[0]{'attackSkillSlot_uses'}{$config{"attackSkillSlot_$i"."_loopSlot"}};
						}
						last;
					}
				}
				$i++;
			}
		}
		if ($chars[$config{'char'}]{'sitting'}) {
			ai_setSuspend(0);
			stand();
		} elsif (!$ai_v{'ai_attack_cleanMonster'}) {
			shift @ai_seq;
			shift @ai_seq_args;
			print "Dropping target - no kill steal\n";
		} elsif ($ai_v{'ai_attack_monsterDist'} > $ai_seq_args[0]{'attackMethod'}{'distance'}) {
			if (%{$ai_seq_args[0]{'char_pos_last'}} && %{$ai_seq_args[0]{'attackMethod_last'}}
				&& $ai_seq_args[0]{'attackMethod_last'}{'distance'} == $ai_seq_args[0]{'attackMethod'}{'distance'}
				&& $ai_seq_args[0]{'char_pos_last'}{'x'} == $chars[$config{'char'}]{'pos_to'}{'x'}
				&& $ai_seq_args[0]{'char_pos_last'}{'y'} == $chars[$config{'char'}]{'pos_to'}{'y'}) {
				$ai_seq_args[0]{'distanceDivide'}++;
			} else {
				$ai_seq_args[0]{'distanceDivide'} = 1;
			}
			if (int($ai_seq_args[0]{'attackMethod'}{'distance'} / $ai_seq_args[0]{'distanceDivide'}) == 0
				|| ($config{'attackMaxRouteDistance'} && $ai_seq_args[0]{'ai_route_returnHash'}{'solutionLength'} > $config{'attackMaxRouteDistance'})
				|| ($config{'attackMaxRouteTime'} && $ai_seq_args[0]{'ai_route_returnHash'}{'solutionTime'} > $config{'attackMaxRouteTime'})) {
				$monsters{$ai_seq_args[0]{'ID'}}{'attack_failed'}++;
				shift @ai_seq;
				shift @ai_seq_args;
				print "Dropping target - couldn't reach target\n";
			} else {
				getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$chars[$config{'char'}]{'pos_to'}});
				moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'ai_attack_monsterDist'} - ($ai_seq_args[0]{'attackMethod'}{'distance'} / $ai_seq_args[0]{'distanceDivide'}) + 1);

				%{$ai_seq_args[0]{'char_pos_last'}} = %{$chars[$config{'char'}]{'pos_to'}};
				%{$ai_seq_args[0]{'attackMethod_last'}} = %{$ai_seq_args[0]{'attackMethod'}};

				ai_setSuspend(0);
				if (length($field{'rawMap'}) > 1) {
					ai_route(\%{$ai_seq_args[0]{'ai_route_returnHash'}}, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}, $field{'name'}, $config{'attackMaxRouteDistance'}, $config{'attackMaxRouteTime'}, 0, 0);
				} else {
					move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
				}
			}
		} elsif ((($config{'tankMode'} && $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'} == 0)
			|| !$config{'tankMode'})) {

			if ($ai_seq_args[0]{'attackMethod'}{'type'} eq "weapon" && timeOut(\%{$timeout{'ai_attack'}})) {
				if ($config{'tankMode'}) {
					sendAttack(\$remote_socket, $ai_seq_args[0]{'ID'}, 0);
				} else {
					sendAttack(\$remote_socket, $ai_seq_args[0]{'ID'}, 7);
				}
				$timeout{'ai_attack'}{'time'} = time;
				undef %{$ai_seq_args[0]{'attackMethod'}};
			} elsif ($ai_seq_args[0]{'attackMethod'}{'type'} eq "skill") {
				$ai_v{'ai_attack_method_skillSlot'} = $ai_seq_args[0]{'attackMethod'}{'skillSlot'};
				$ai_v{'ai_attack_ID'} = $ai_seq_args[0]{'ID'};
				undef %{$ai_seq_args[0]{'attackMethod'}};
				ai_setSuspend(0);
				if (!ai_getSkillUseType($skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})})) {
					# Allow useSelf skill in attackSkill slot
					if ($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_useSelf"}) {
						ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}}{'ID'}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_maxCastTime"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"}, $accountID);
					} else {
						ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}}{'ID'}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_maxCastTime"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"}, $ai_v{'ai_attack_ID'});
					}
				} else {
					# Allow useSelf skill in attackSkill slot
					if ($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_useSelf"}) {
						ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}}{'ID'}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_maxCastTime"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"}, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
					} else {
						ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}}{'ID'}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_maxCastTime"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"}, $monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'x'}, $monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'y'});
					}
				}
				print qq~Auto-skill on monster: $skills_lut{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}} (lvl $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"})\n~ if $config{'debug'};
			}

		} elsif ($config{'tankMode'}) {
			if ($ai_seq_args[0]{'dmgTo_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'}) {
				$ai_seq_args[0]{'ai_attack_giveup'}{'time'} = time;
			}
			$ai_seq_args[0]{'dmgTo_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'};
		}
	}


	##### ROUTE #####

	ROUTE: {

	if ($ai_seq[0] eq "route" && @{$ai_seq_args[0]{'solution'}} && $ai_seq_args[0]{'index'} == @{$ai_seq_args[0]{'solution'}} - 1 && $ai_seq_args[0]{'solutionReady'}) {
		print "Route success\n" if $config{'debug'};
		# Avoid stuck
		undef %{$ai_v{'avoidStuck'}};
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "route" && $ai_seq_args[0]{'failed'}) {
		print "Route failed\n" if $config{'debug'};
		# Avoid stuck
		$ai_v{'avoidStuck'}{'route_failed'}++;
		avoidStuck();
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "route" && timeOut(\%{$timeout{'ai_route_npcTalk'}})) {
		last ROUTE if (!$field{'name'});
		if ($ai_seq_args[0]{'waitingForMapSolution'}) {
			undef $ai_seq_args[0]{'waitingForMapSolution'};
			if (!@{$ai_seq_args[0]{'mapSolution'}}) {
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}
			$ai_seq_args[0]{'mapIndex'} = -1;
		}
		if ($ai_seq_args[0]{'waitingForSolution'}) {
			undef $ai_seq_args[0]{'waitingForSolution'};
			if ($ai_seq_args[0]{'distFromGoal'} && $field{'name'} && $ai_seq_args[0]{'dest_map'} eq $field{'name'}
				&& (!@{$ai_seq_args[0]{'mapSolution'}} || $ai_seq_args[0]{'mapIndex'} == @{$ai_seq_args[0]{'mapSolution'}} - 1)) {
				for ($i = 0; $i < $ai_seq_args[0]{'distFromGoal'}; $i++) {
					pop @{$ai_seq_args[0]{'solution'}};
				}
				if (@{$ai_seq_args[0]{'solution'}}) {
					$ai_seq_args[0]{'dest_x_original'} = $ai_seq_args[0]{'dest_x'};
					$ai_seq_args[0]{'dest_y_original'} = $ai_seq_args[0]{'dest_y'};
					$ai_seq_args[0]{'dest_x'} = $ai_seq_args[0]{'solution'}[@{$ai_seq_args[0]{'solution'}}-1]{'x'};
					$ai_seq_args[0]{'dest_y'} = $ai_seq_args[0]{'solution'}[@{$ai_seq_args[0]{'solution'}}-1]{'y'};
				}
			}
			$ai_seq_args[0]{'returnHash'}{'solutionLength'} = @{$ai_seq_args[0]{'solution'}};
			$ai_seq_args[0]{'returnHash'}{'solutionTime'} = time - $ai_seq_args[0]{'time_getRoute'};
			if ($ai_seq_args[0]{'maxRouteDistance'} && @{$ai_seq_args[0]{'solution'}} > $ai_seq_args[0]{'maxRouteDistance'}) {
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}
			if (!@{$ai_seq_args[0]{'solution'}} && !@{$ai_seq_args[0]{'mapSolution'}} && $ai_seq_args[0]{'dest_map'} eq $field{'name'} && $ai_seq_args[0]{'checkInnerPortals'} && !$ai_seq_args[0]{'checkInnerPortals_done'}) {
				$ai_seq_args[0]{'checkInnerPortals_done'} = 1;
				undef $ai_seq_args[0]{'solutionReady'};
				$ai_seq_args[0]{'temp'}{'pos'}{'x'} = $ai_seq_args[0]{'dest_x'};
				$ai_seq_args[0]{'temp'}{'pos'}{'y'} = $ai_seq_args[0]{'dest_y'};
				$ai_seq_args[0]{'waitingForMapSolution'} = 1;
				ai_mapRoute_getRoute(\@{$ai_seq_args[0]{'mapSolution'}}, \%field, \%{$chars[$config{'char'}]{'pos_to'}}, \%field, \%{$ai_seq_args[0]{'temp'}{'pos'}}, $ai_seq_args[0]{'maxRouteTime'});
				last ROUTE;
			} elsif (!@{$ai_seq_args[0]{'solution'}}) {
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}
		}
		if (@{$ai_seq_args[0]{'mapSolution'}} && $ai_seq_args[0]{'mapChanged'} && $field{'name'} eq $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'dest'}{'map'}) {
			undef $ai_seq_args[0]{'mapChanged'};
			undef @{$ai_seq_args[0]{'solution'}};
			undef %{$ai_seq_args[0]{'last_pos'}};
			undef $ai_seq_args[0]{'index'};
			undef $ai_seq_args[0]{'npc'};
			undef $ai_seq_args[0]{'divideIndex'};
		}
		if (!@{$ai_seq_args[0]{'solution'}}) {
			if ($ai_seq_args[0]{'dest_map'} eq $field{'name'}
				&& (!@{$ai_seq_args[0]{'mapSolution'}} || $ai_seq_args[0]{'mapIndex'} == @{$ai_seq_args[0]{'mapSolution'}} - 1)) {
				$ai_seq_args[0]{'temp'}{'dest'}{'x'} = $ai_seq_args[0]{'dest_x'};
				$ai_seq_args[0]{'temp'}{'dest'}{'y'} = $ai_seq_args[0]{'dest_y'};
				$ai_seq_args[0]{'solutionReady'} = 1;
				undef @{$ai_seq_args[0]{'mapSolution'}};
				undef $ai_seq_args[0]{'mapIndex'};
			} else {
				if (!(@{$ai_seq_args[0]{'mapSolution'}})) {
					if (!%{$ai_seq_args[0]{'dest_field'}}) {
						getField("fields/$ai_seq_args[0]{'dest_map'}.fld", \%{$ai_seq_args[0]{'dest_field'}});
					}
					$ai_seq_args[0]{'temp'}{'pos'}{'x'} = $ai_seq_args[0]{'dest_x'};
					$ai_seq_args[0]{'temp'}{'pos'}{'y'} = $ai_seq_args[0]{'dest_y'};
					$ai_seq_args[0]{'waitingForMapSolution'} = 1;
					ai_mapRoute_getRoute(\@{$ai_seq_args[0]{'mapSolution'}}, \%field, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'dest_field'}}, \%{$ai_seq_args[0]{'temp'}{'pos'}}, $ai_seq_args[0]{'maxRouteTime'});
					last ROUTE;
				}
				# Null solution bug fix
				if (!defined $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'} + 1]{'source'}{'map'}) {
					$ai_seq_args[0]{'failed'} = 1;
					last ROUTE;
				}
				if ($field{'name'} eq $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'} + 1]{'source'}{'map'}) {
					$ai_seq_args[0]{'mapIndex'}++;
					%{$ai_seq_args[0]{'temp'}{'dest'}} = %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'pos'}};
				} else {
					%{$ai_seq_args[0]{'temp'}{'dest'}} = %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'pos'}};
				}
			}
			if ($ai_seq_args[0]{'temp'}{'dest'}{'x'} eq "") {
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}
			$ai_seq_args[0]{'waitingForSolution'} = 1;
			$ai_seq_args[0]{'time_getRoute'} = time;
			ai_route_getRoute(\@{$ai_seq_args[0]{'solution'}}, \%field, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'temp'}{'dest'}}, $ai_seq_args[0]{'maxRouteTime'});
			last ROUTE;
		}
		if (@{$ai_seq_args[0]{'mapSolution'}} && @{$ai_seq_args[0]{'solution'}} && $ai_seq_args[0]{'index'} == @{$ai_seq_args[0]{'solution'}} - 1
			&& %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}}) {
			if ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] ne "") {
				if (!$ai_seq_args[0]{'npc'}{'sentTalk'}) {
					sendTalk(\$remote_socket, pack("L1",$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}));
					$ai_seq_args[0]{'npc'}{'sentTalk'} = 1;
				} elsif ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /c/i) {
					sendTalkContinue(\$remote_socket, pack("L1",$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}));
					$ai_seq_args[0]{'npc'}{'step'}++;
				} elsif ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /n/i) {
					sendTalkCancel(\$remote_socket, pack("L1",$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}));
					$ai_seq_args[0]{'npc'}{'step'}++;
				} else {
					($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i;
					if ($ai_v{'temp'}{'arg'} ne "") {
						$ai_v{'temp'}{'arg'}++;
						sendTalkResponse(\$remote_socket, pack("L1",$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}), $ai_v{'temp'}{'arg'});
					}
					$ai_seq_args[0]{'npc'}{'step'}++;
				}
				$timeout{'ai_route_npcTalk'}{'time'} = time;
				last ROUTE;
			}
		}
		if ($ai_seq_args[0]{'mapChanged'}) {
			$ai_seq_args[0]{'failed'} = 1;
			last ROUTE;

		} elsif (%{$ai_seq_args[0]{'last_pos'}}
			&& $chars[$config{'char'}]{'pos_to'}{'x'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}
			&& $chars[$config{'char'}]{'pos_to'}{'y'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'}
			&& $ai_seq_args[0]{'last_pos'}{'x'} != $chars[$config{'char'}]{'pos_to'}{'x'}
			&& $ai_seq_args[0]{'last_pos'}{'y'} != $chars[$config{'char'}]{'pos_to'}{'y'}) {

			if ($ai_seq_args[0]{'dest_x_original'} ne "") {
				$ai_seq_args[0]{'dest_x'} = $ai_seq_args[0]{'dest_x_original'};
				$ai_seq_args[0]{'dest_y'} = $ai_seq_args[0]{'dest_y_original'};
			}
			undef @{$ai_seq_args[0]{'solution'}};
			undef %{$ai_seq_args[0]{'last_pos'}};
			undef $ai_seq_args[0]{'index'};
			undef $ai_seq_args[0]{'npc'};
			undef $ai_seq_args[0]{'divideIndex'};

		} else {
			if ($ai_seq_args[0]{'divideIndex'} && $chars[$config{'char'}]{'pos_to'}{'x'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}
				&& $chars[$config{'char'}]{'pos_to'}{'y'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'}) {

				#we're stuck!
				$ai_v{'temp'}{'index_old'} = $ai_seq_args[0]{'index'};
				$ai_seq_args[0]{'index'} -= int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'});
				$ai_seq_args[0]{'index'} = 0 if ($ai_seq_args[0]{'index'} < 0);
				$ai_v{'temp'}{'index'} = $ai_seq_args[0]{'index'};
				undef $ai_v{'temp'}{'done'};
				do {
					$ai_seq_args[0]{'divideIndex'}++;
					$ai_v{'temp'}{'index'} = $ai_seq_args[0]{'index'};
					$ai_v{'temp'}{'index'} += int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'});
					$ai_v{'temp'}{'index'} = @{$ai_seq_args[0]{'solution'}} - 1 if ($ai_v{'temp'}{'index'} >= @{$ai_seq_args[0]{'solution'}});
					$ai_v{'temp'}{'done'} = 1 if (int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'}) == 0);
				} while ($ai_v{'temp'}{'index'} >= $ai_v{'temp'}{'index_old'} && !$ai_v{'temp'}{'done'});
			} else {
				$ai_seq_args[0]{'divideIndex'} = 1;
			}


			if (int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'}) == 0) {
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}

			%{$ai_seq_args[0]{'last_pos'}} = %{$chars[$config{'char'}]{'pos_to'}};

			do {
				$ai_seq_args[0]{'index'} += int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'});
				$ai_seq_args[0]{'index'} = @{$ai_seq_args[0]{'solution'}} - 1 if ($ai_seq_args[0]{'index'} >= @{$ai_seq_args[0]{'solution'}});
			} while ($ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'} == $chars[$config{'char'}]{'pos_to'}{'x'}
				&& $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'} == $chars[$config{'char'}]{'pos_to'}{'y'}
				&& $ai_seq_args[0]{'index'} != @{$ai_seq_args[0]{'solution'}} - 1);

			# Null solution bug fix
			if (!defined $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}	|| !defined $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'}) {
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}
			if ($ai_seq_args[0]{'avoidPortals'}) {
				$ai_v{'temp'}{'first'} = 1;
				undef $ai_v{'temp'}{'foundID'};
				undef $ai_v{'temp'}{'smallDist'};
				foreach (@portalsID) {
					$ai_v{'temp'}{'dist'} = distance(\%{$ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]}, \%{$portals{$_}{'pos'}});
					if ($ai_v{'temp'}{'dist'} <= 7 && ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'})) {
						$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
						$ai_v{'temp'}{'foundID'} = $_;
						undef $ai_v{'temp'}{'first'};
					}
				}
				if ($ai_v{'temp'}{'foundID'}) {
					$ai_seq_args[0]{'failed'} = 1;
					last ROUTE;
				}
			}
			if ($ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'} != $chars[$config{'char'}]{'pos_to'}{'x'}
				|| $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'} != $chars[$config{'char'}]{'pos_to'}{'y'}) {
				move($ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}, $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'});
			}
		}
	}

	} #END OF ROUTE BLOCK


	##### ROUTE_GETROUTE #####

	if ($ai_seq[0] eq "route_getRoute" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'time_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "route_getRoute" && ($ai_seq_args[0]{'done'} || $ai_seq_args[0]{'mapChanged'}
		|| ($ai_seq_args[0]{'time_giveup'}{'timeout'} && timeOut(\%{$ai_seq_args[0]{'time_giveup'}})))) {
		$timeout{'ai_route_calcRoute_cont'}{'time'} -= $timeout{'ai_route_calcRoute_cont'}{'timeout'};
		ai_route_getRoute_destroy(\%{$ai_seq_args[0]});
		shift @ai_seq;
		shift @ai_seq_args;

	} elsif ($ai_seq[0] eq "route_getRoute" && timeOut(\%{$timeout{'ai_route_calcRoute_cont'}})) {
		if (!$ai_seq_args[0]{'init'}) {
			undef @{$ai_v{'temp'}{'subSuc'}};
			undef @{$ai_v{'temp'}{'subSuc2'}};
			if (ai_route_getMap(\%{$ai_seq_args[0]}, $ai_seq_args[0]{'start'}{'x'}, $ai_seq_args[0]{'start'}{'y'})) {
				ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'start'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'start'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				foreach (@{$ai_v{'temp'}{'subSuc'}}) {
					ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
					ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
				}
				if (@{$ai_v{'temp'}{'subSuc'}}) {
					%{$ai_seq_args[0]{'start'}} = %{$ai_v{'temp'}{'subSuc'}[0]};
				} elsif (@{$ai_v{'temp'}{'subSuc2'}}) {
					%{$ai_seq_args[0]{'start'}} = %{$ai_v{'temp'}{'subSuc2'}[0]};
				}
			}
			undef @{$ai_v{'temp'}{'subSuc'}};
			undef @{$ai_v{'temp'}{'subSuc2'}};
			if (ai_route_getMap(\%{$ai_seq_args[0]}, $ai_seq_args[0]{'dest'}{'x'}, $ai_seq_args[0]{'dest'}{'y'})) {
				ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'dest'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'dest'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				foreach (@{$ai_v{'temp'}{'subSuc'}}) {
					ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
					ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
				}
				if (@{$ai_v{'temp'}{'subSuc'}}) {
					%{$ai_seq_args[0]{'dest'}} = %{$ai_v{'temp'}{'subSuc'}[0]};
				} elsif (@{$ai_v{'temp'}{'subSuc2'}}) {
					%{$ai_seq_args[0]{'dest'}} = %{$ai_v{'temp'}{'subSuc2'}[0]};
				}
			}
			$ai_seq_args[0]{'timeout'} = $timeout{'ai_route_calcRoute'}{'timeout'}*1000;
		}
		$ai_seq_args[0]{'init'} = 1;
		ai_route_searchStep(\%{$ai_seq_args[0]});
		$timeout{'ai_route_calcRoute_cont'}{'time'} = time;
		ai_setSuspend(0);
	}

	##### ROUTE_GETMAPROUTE #####

	ROUTE_GETMAPROUTE: {

	if ($ai_seq[0] eq "route_getMapRoute" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'time_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "route_getMapRoute" && ($ai_seq_args[0]{'done'} || $ai_seq_args[0]{'mapChanged'}
		|| ($ai_seq_args[0]{'time_giveup'}{'timeout'} && timeOut(\%{$ai_seq_args[0]{'time_giveup'}})))) {
		$timeout{'ai_route_calcRoute_cont'}{'time'} -= $timeout{'ai_route_calcRoute_cont'}{'timeout'};
		shift @ai_seq;
		shift @ai_seq_args;

	} elsif ($ai_seq[0] eq "route_getMapRoute" && timeOut(\%{$timeout{'ai_route_calcRoute_cont'}})) {
		if (!%{$ai_seq_args[0]{'start'}}) {
			%{$ai_seq_args[0]{'start'}{'dest'}{'pos'}} = %{$ai_seq_args[0]{'r_start_pos'}};
			$ai_seq_args[0]{'start'}{'dest'}{'map'} = $ai_seq_args[0]{'r_start_field'}{'name'};
			$ai_seq_args[0]{'start'}{'dest'}{'field'} = $ai_seq_args[0]{'r_start_field'};
			%{$ai_seq_args[0]{'dest'}{'source'}{'pos'}} = %{$ai_seq_args[0]{'r_dest_pos'}};
			$ai_seq_args[0]{'dest'}{'source'}{'map'} = $ai_seq_args[0]{'r_dest_field'}{'name'};
			$ai_seq_args[0]{'dest'}{'source'}{'field'} = $ai_seq_args[0]{'r_dest_field'};
			push @{$ai_seq_args[0]{'openList'}}, \%{$ai_seq_args[0]{'start'}};
		}
		$timeout{'ai_route_calcRoute'}{'time'} = time;
		while (!$ai_seq_args[0]{'done'} && !timeOut(\%{$timeout{'ai_route_calcRoute'}})) {
			ai_mapRoute_searchStep(\%{$ai_seq_args[0]});
			last ROUTE_GETMAPROUTE if ($ai_seq[0] ne "route_getMapRoute");
		}

		if ($ai_seq_args[0]{'done'}) {
			@{$ai_seq_args[0]{'returnArray'}} = @{$ai_seq_args[0]{'solutionList'}};
		}
		$timeout{'ai_route_calcRoute_cont'}{'time'} = time;
		ai_setSuspend(0);
	}

	} #End of block ROUTE_GETMAPROUTE


	##### ITEMS TAKE #####


	if ($ai_seq[0] eq "items_take" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_items_take_start'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		$ai_seq_args[0]{'ai_items_take_end'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "items_take" && (percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'})) {
		shift @ai_seq;
		shift @ai_seq_args;
		ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
	}
	if ($config{'itemsTakeAuto'} && $ai_seq[0] eq "items_take" && timeOut(\%{$ai_seq_args[0]{'ai_items_take_start'}})) {
		undef $ai_v{'temp'}{'foundID'};
		foreach (@itemsID) {
			next if ($_ eq "" || $itemsPickup{lc($items{$_}{'name'})} eq "0" || (!$itemsPickup{'all'} && !$itemsPickup{lc($items{$_}{'name'})}));
			$ai_v{'temp'}{'dist'} = distance(\%{$items{$_}{'pos'}}, \%{$ai_seq_args[0]{'pos'}});
			$ai_v{'temp'}{'dist_to'} = distance(\%{$items{$_}{'pos'}}, \%{$ai_seq_args[0]{'pos_to'}});
			if (($ai_v{'temp'}{'dist'} <= 4 || $ai_v{'temp'}{'dist_to'} <= 4) && $items{$_}{'take_failed'} == 0) {
				$ai_v{'temp'}{'foundID'} = $_;
				last;
			}
		}
		if ($ai_v{'temp'}{'foundID'}) {
			$ai_seq_args[0]{'ai_items_take_end'}{'time'} = time;
			$ai_seq_args[0]{'started'} = 1;
			take($ai_v{'temp'}{'foundID'});
		} elsif ($ai_seq_args[0]{'started'} || timeOut(\%{$ai_seq_args[0]{'ai_items_take_end'}})) {
			shift @ai_seq;
			shift @ai_seq_args;
			ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
		}
	}



	##### ITEMS AUTO-GATHER #####


	if (($ai_seq[0] eq "" || $ai_seq[0] eq "follow" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute") && $config{'itemsGatherAuto'} && !(percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'}) && timeOut(\%{$timeout{'ai_items_gather_auto'}})) {
		undef @{$ai_v{'ai_items_gather_foundIDs'}};
		foreach (@playersID) {
			next if ($_ eq "");
			if (!%{$chars[$config{'char'}]{'party'}} || !%{$chars[$config{'char'}]{'party'}{'users'}{$_}}) {
				push @{$ai_v{'ai_items_gather_foundIDs'}}, $_;
			}
		}
		foreach $item (@itemsID) {
			next if ($item eq "" || time - $items{$item}{'appear_time'} < $timeout{'ai_items_gather_start'}{'timeout'}
				|| $items{$item}{'take_failed'} >= 1
				|| $itemsPickup{lc($items{$item}{'name'})} eq "0" || (!$itemsPickup{'all'} && !$itemsPickup{lc($items{$item}{'name'})}));
			undef $ai_v{'temp'}{'dist'};
			undef $ai_v{'temp'}{'found'};
			foreach (@{$ai_v{'ai_items_gather_foundIDs'}}) {
				$ai_v{'temp'}{'dist'} = distance(\%{$items{$item}{'pos'}}, \%{$players{$_}{'pos_to'}});
				if ($ai_v{'temp'}{'dist'} < 9) {
					$ai_v{'temp'}{'found'} = 1;
					last;
				}
			}
			if ($ai_v{'temp'}{'found'} == 0) {
				gather($item);
				last;
			}
		}
		$timeout{'ai_items_gather_auto'}{'time'} = time;
	}



	##### ITEMS GATHER #####


	if ($ai_seq[0] eq "items_gather" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_items_gather_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "items_gather" && !%{$items{$ai_seq_args[0]{'ID'}}}) {
		print "Failed to gather $items_old{$ai_seq_args[0]{'ID'}}{'name'} ($items_old{$ai_seq_args[0]{'ID'}}{'binID'}) : Lost target\n";
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "items_gather") {
		undef $ai_v{'temp'}{'dist'};
		undef @{$ai_v{'ai_items_gather_foundIDs'}};
		undef $ai_v{'temp'}{'found'};
		foreach (@playersID) {
			next if ($_ eq "");
			if (%{$chars[$config{'char'}]{'party'}} && !%{$chars[$config{'char'}]{'party'}{'users'}{$_}}) {
				push @{$ai_v{'ai_items_gather_foundIDs'}}, $_;
			}
		}
		foreach (@{$ai_v{'ai_items_gather_foundIDs'}}) {
			$ai_v{'temp'}{'dist'} = distance(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$players{$_}{'pos'}});
			if ($ai_v{'temp'}{'dist'} < 9) {
				$ai_v{'temp'}{'found'}++;
			}
		}
		$ai_v{'temp'}{'dist'} = distance(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
		if (timeOut(\%{$ai_seq_args[0]{'ai_items_gather_giveup'}})) {
			print "Failed to gather $items{$ai_seq_args[0]{'ID'}}{'name'} ($items{$ai_seq_args[0]{'ID'}}{'binID'}) : Timeout\n";
			$items{$ai_seq_args[0]{'ID'}}{'take_failed'}++;
			shift @ai_seq;
			shift @ai_seq_args;
		} elsif ($chars[$config{'char'}]{'sitting'}) {
			ai_setSuspend(0);
			stand();
		} elsif ($ai_v{'temp'}{'found'} == 0 && $ai_v{'temp'}{'dist'} > 2) {
			getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'temp'}{'dist'} - 1);
			move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
		} elsif ($ai_v{'temp'}{'found'} == 0) {
			$ai_v{'ai_items_gather_ID'} = $ai_seq_args[0]{'ID'};
			shift @ai_seq;
			shift @ai_seq_args;
			take($ai_v{'ai_items_gather_ID'});
		} elsif ($ai_v{'temp'}{'found'} > 0) {
			print "Failed to gather $items{$ai_seq_args[0]{'ID'}}{'name'} ($items{$ai_seq_args[0]{'ID'}}{'binID'}) : No looting!\n";
			shift @ai_seq;
			shift @ai_seq_args;
		}
	}



	##### TAKE #####


	if ($ai_seq[0] eq "take" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_take_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "take" && !%{$items{$ai_seq_args[0]{'ID'}}}) {
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "take" && timeOut(\%{$ai_seq_args[0]{'ai_take_giveup'}})) {
		print "Failed to take $items{$ai_seq_args[0]{'ID'}}{'name'} ($items{$ai_seq_args[0]{'ID'}}{'binID'})\n";
		$items{$ai_seq_args[0]{'ID'}}{'take_failed'}++;
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "take") {

		$ai_v{'temp'}{'dist'} = distance(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
		if ($chars[$config{'char'}]{'sitting'}) {
			stand();
		} elsif ($ai_v{'temp'}{'dist'} > 2) {
			getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'temp'}{'dist'} - 1);
			move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
		} elsif (timeOut(\%{$timeout{'ai_take'}})) {
			sendTake(\$remote_socket, $ai_seq_args[0]{'ID'});
			$timeout{'ai_take'}{'time'} = time;
		}
	}


	##### MOVE #####


	if ($ai_seq[0] eq "move" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_move_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "move") {
		if (!$ai_seq_args[0]{'ai_moved'} && $ai_seq_args[0]{'ai_moved_tried'} && $ai_seq_args[0]{'ai_move_time_last'} != $chars[$config{'char'}]{'time_move'}) {
			$ai_seq_args[0]{'ai_moved'} = 1;
		}
		if ($chars[$config{'char'}]{'sitting'}) {
			ai_setSuspend(0);
			stand();
		} elsif (!$ai_seq_args[0]{'ai_moved'} && timeOut(\%{$ai_seq_args[0]{'ai_move_giveup'}})) {
			# Avoid stuck
			$ai_v{'avoidStuck'}{'move_failed'}++;
			avoidStuck();
			shift @ai_seq;
			shift @ai_seq_args;
		} elsif (!$ai_seq_args[0]{'ai_moved_tried'}) {
			sendMove(\$remote_socket, int($ai_seq_args[0]{'move_to'}{'x'}), int($ai_seq_args[0]{'move_to'}{'y'}));
			$ai_seq_args[0]{'ai_move_giveup'}{'time'} = time;
			$ai_seq_args[0]{'ai_move_time_last'} = $chars[$config{'char'}]{'time_move'};
			$ai_seq_args[0]{'ai_moved_tried'} = 1;
		} elsif ($ai_seq_args[0]{'ai_moved'} && time - $chars[$config{'char'}]{'time_move'} >= $chars[$config{'char'}]{'time_move_calc'}) {
			# Avoid stuck
			undef %{$ai_v{'avoidStuck'}};
			shift @ai_seq;
			shift @ai_seq_args;
		}
	}



	##### AUTO-TELEPORT #####

	($ai_v{'map_name_lu'}) = $map_name =~ /([\s\S]*)\./;
	$ai_v{'map_name_lu'} .= ".rsw";
	if ($config{'teleportAuto_onlyWhenSafe'} && binSize(\@playersID)) {
		undef $ai_v{'ai_teleport_safe'};
		if (!$cities_lut{$ai_v{'map_name_lu'}} && timeOut(\%{$timeout{'ai_teleport_safe_force'}})) {
			$ai_v{'ai_teleport_safe'} = 1;
		}
	} elsif (!$cities_lut{$ai_v{'map_name_lu'}}) {
		$ai_v{'ai_teleport_safe'} = 1;
		$timeout{'ai_teleport_safe_force'}{'time'} = time;
	} else {
		undef $ai_v{'ai_teleport_safe'};
	}

	if (timeOut(\%{$timeout{'ai_teleport_away'}}) && $ai_v{'ai_teleport_safe'}) {
		# Detect more condition
		my $agNotorious = 0;
		my $agMonsters = ai_getAggressives();
		foreach (@monstersID) {
			$agNotorious++ if ($mon_control{lc($monsters{$_}{'name'})}{'teleport_auto'} == 5 && ($monsters{$_}{'dmgToYou'} > 0 || $monsters{$_}{'missedYou'} > 0));
			if ($mon_control{lc($monsters{$_}{'name'})}{'teleport_auto'} == 1
				|| (($mon_control{lc($monsters{$_}{'name'})}{'teleport_auto'} == 2
					|| ($mon_control{lc($monsters{$_}{'name'})}{'teleport_auto'} == 3
						&& (binFind(\@ai_seq, "attack") eq "" || $ai_seq_args[binFind(\@ai_seq, "attack")]{'ID'} eq $_)))
					&& binFind(\@ai_seq, "take") eq ""
					&& ($monsters{$_}{'dmgToYou'} > 0 || $monsters{$_}{'missedYou'} > 0))
				|| ($mon_control{lc($monsters{$_}{'name'})}{'teleport_auto'} == 4
					&& (distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}}) <= $config{'teleportAuto_dist'}))
				|| (($agNotorious >= $config{'teleportAuto_minAgNotorious'}) && $config{'teleportAuto_minAgNotorious'})
				|| ($mon_control{lc($monsters{$_}{'name'})}{'teleport_auto'} == 5
					&& ($monsters{$_}{'dmgToYou'} > 0 || $monsters{$_}{'missedYou'} > 0)
					&& ($config{'teleportAuto_minAgWithAgNM'} && $agMonsters >= $config{'teleportAuto_minAgWithAgNM'}))) {
				useTeleport(1);
				$ai_v{'temp'}{'search'} = 1;
				last;
			}
		}
		$timeout{'ai_teleport_away'}{'time'} = time;
	}

	if (((($config{'teleportAuto_hp'} && percent_hp(\%{$chars[$config{'char'}]}) <= $config{'teleportAuto_hp'}
		|| $config{'teleportAuto_sp'} && percent_sp(\%{$chars[$config{'char'}]}) <= $config{'teleportAuto_sp'})
			&& ai_getAggressives())
		|| ($config{'teleportAuto_minAggressives'} && ai_getAggressives() >= $config{'teleportAuto_minAggressives'}))
			&& $ai_v{'ai_teleport_safe'} && timeOut(\%{$timeout{'ai_teleport_hp'}})) {
		useTeleport(1);
		$ai_v{'clear_aiQueue'} = 1;
		$timeout{'ai_teleport_hp'}{'time'} = time;
	}

	if ($config{'teleportAuto_search'} && timeOut(\%{$timeout{'ai_teleport_search'}}) && binFind(\@ai_seq, "attack") eq "" && binFind(\@ai_seq, "items_take") eq ""
		&& $ai_v{'ai_teleport_safe'} && binFind(\@ai_seq, "sitAuto") eq ""
		&& binFind(\@ai_seq, "buyAuto") eq "" && binFind(\@ai_seq, "sellAuto") eq "" && binFind(\@ai_seq, "storageAuto") eq ""
		&& ($ai_v{'map_name_lu'} eq $config{'lockMap'}.'.rsw' || $config{'lockMap'} eq "")) {
		undef $ai_v{'temp'}{'search'};
		foreach (keys %mon_control) {
			if ($mon_control{$_}{'teleport_search'}) {
				$ai_v{'temp'}{'search'} = 1;
				last;
			}
		}
		if ($ai_v{'temp'}{'search'}) {
			undef $ai_v{'temp'}{'found'};
			foreach (@monstersID) {
				if ($mon_control{lc($monsters{$_}{'name'})}{'teleport_search'} && !$monsters{$_}{'attack_failed'}) {
					$ai_v{'temp'}{'found'} = 1;
					last;
				}
			}
			if (!$ai_v{'temp'}{'found'}) {
				useTeleport(1);
				$ai_v{'clear_aiQueue'} = 1;
			}
		}
		$timeout{'ai_teleport_search'}{'time'} = time;
	}

	if ($config{'teleportAuto_idle'} && $ai_seq[0] ne "") {
		$timeout{'ai_teleport_idle'}{'time'} = time;
	}

	if ($config{'teleportAuto_idle'} && timeOut(\%{$timeout{'ai_teleport_idle'}}) && $ai_v{'ai_teleport_safe'}) {
		useTeleport(1);
		$ai_v{'clear_aiQueue'} = 1;
		$timeout{'ai_teleport_idle'}{'time'} = time;
	}

	if ($config{'teleportAuto_portal'} && timeOut(\%{$timeout{'ai_teleport_portal'}}) && $ai_v{'ai_teleport_safe'}
		&& binFind(\@ai_seq, "buyAuto") eq "" && binFind(\@ai_seq, "sellAuto") eq "" && binFind(\@ai_seq, "storageAuto") eq ""
		&& ($ai_v{'map_name_lu'} eq $config{'lockMap'}.'.rsw' || $config{'lockMap'} eq "")) {
		if (binSize(\@portalsID)) {
			useTeleport(1);
			$ai_v{'clear_aiQueue'} = 1;
		}
		$timeout{'ai_teleport_portal'}{'time'} = time;
	}

	# Avoid ground effect skills
	if ($config{'teleportAuto_spell'} && timeOut(\%{$timeout{'ai_teleport_spell'}}) && $ai_v{'ai_teleport_safe'}) {
		foreach (@spellsID) {
			$display = ($messages_lut{'011F'}{$spells{$_}{'type'}} ne "")
				? $messages_lut{'011F'}{$spells{$_}{'type'}}
				: "Unknown ".$spells{$_}{'type'};

			next if ($spells{$_}{'type'} ne 0x81 && $spells{$_}{'type'} ne 0x82 && !existsInList($config{'teleportAuto_spell_types'}, $display));
			if ($spells{$_}{'sourceID'} eq $accountID) {
				$name = "You";
			} elsif (%{$monsters{$spells{$_}{'sourceID'}}}) {
				$name = "$monsters{$spells{$_}{'sourceID'}}{'name'} ($monsters{$spells{$_}{'sourceID'}}{'binID'})";
			} elsif (%{$players{$spells{$_}{'sourceID'}}}) {
				$name = "$players{$spells{$_}{'sourceID'}}{'name'} ($players{$spells{$_}{'sourceID'}}{'binID'})";
			} else {
				$name = "Unknown ".getHex($spells{$_}{'sourceID'});
			}
			if ($config{'teleportAuto_spell'} > distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$spells{$_}{'pos'}})) {
				if ($config{'teleportAuto_spell_randomWalk'} && $spells{$_}{'type'} ne 0x81 && $spells{$_}{'type'} ne 0x82) {
					if (timeOut(\%{$timeout{'ai_rapidDisp'}})) {
						print "*** Avoid ground effect spell $display owned by $name, auto walking away ***\n";
						chatLog("wv","Avoid ground effect spell $display owned by $name, auto walked away.\n");
						$timeout{'ai_rapidDisp'}{'time'} = time;
					}
					escLocation(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$spells{$_}{'pos'}}, $config{'teleportAuto_spell'});
				} else {
					if (timeOut(\%{$timeout{'ai_rapidDisp'}})) {
						print "*** Avoid ground effect spell $display owned by $name, auto teleporting ***\n";
						chatLog("tv","Avoid ground effect spell $display owned by $name, auto teleported.\n");
						$timeout{'ai_rapidDisp'}{'time'} = time;
					}
					useTeleport(1);
					$ai_v{'clear_aiQueue'} = 1;
				}
			}
		}
		$timeout{'ai_teleport_spell'}{'time'} = time;
	}

	##### AUTO-ACTION #####

	if ($ai_seq[0] eq "actionAuto" && timeOut(\%{$ai_seq_args[0]})) {
		my $type = shift @{$ai_seq_args[0]{'type'}};
		my $action = shift @{$ai_seq_args[0]{'action'}};
		if ($ai_seq_args[0]{'action'}[0] ne "" && $type ne "") {
			$ai_seq_args[0]{'time'} = time;
			$ai_seq_args[0]{'timeout'} = $config{'wait_'.$type};
		} else {
			shift @ai_seq;
			shift @ai_seq_args;
		}
		parseInput($action);
	}

	### AUTO-STATUS ADD ###
	if ($config{'autoAddStatus_0'} ne "" && $chars[$config{'char'}]{'points_free'} && timeOut(\%{$timeout{'ai_statusAuto_add'}})) {
		my ($i, $target);
		for ($i = 0; $config{"autoAddStatus_$i"} ne ""; $i++) {
			$target = $config{"autoAddStatus_$i"};
			if ($chars[$config{'char'}]{$target} < $config{"autoAddStatus_$i"."_limit"}) {
				if ($chars[$config{'char'}]{"points_$target"} <= $chars[$config{'char'}]{'points_free'}) {
					print "Auto-add status : $target\n";
					parseInput("stat_add $target");
					$timeout{'ai_statusAuto_add'}{'time'} = time;
				}
				last;
			}
		}
	}

	### AUTO-SKILL ADD ###
	if ($config{'autoAddSkill_0'} ne "" && $chars[$config{'char'}]{'points_skill'} && timeOut(\%{$timeout{'ai_skillAuto_add'}})) {
		my ($i, $target);
		for ($i = 0; $config{"autoAddSkill_$i"} ne ""; $i++) {
			$target = $config{"autoAddSkill_$i"};
			if ($skills_rlut{lc($target)} ne "" && $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($target)}}{'lv'} < $config{"autoAddSkill_$i"."_limit"}) {
				print "Auto-add skill : $target\n";
				sendAddSkillPoint(\$remote_socket, $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($target)}}{'ID'});
				$timeout{'ai_skillAuto_add'}{'time'} = time;
				last;
			}
		}
	}

	### GET GUILD INFORMATION ###
	if ($config{'guildAutoInfo'} && $chars[$config{'char'}]{'guild'}{'name'} && timeOut($config{'guildAutoInfo'}, $ai_v{'guildAutoInfo_time'})) {
		sendGuildInfoRequest(\$remote_socket);
		sendGuildRequest(\$remote_socket, 0);
		sendGuildRequest(\$remote_socket, 1);
		$ai_v{'guildAutoInfo_time'} = time;
	}


	##########

	#DEBUG CODE
	if (time - $ai_v{'time'} > 2 && $config{'debug'}) {
		$stuff = @ai_seq_args;
		print "AI: @ai_seq | $stuff\n";
		$ai_v{'time'} = time;
	}

	if ($ai_v{'clear_aiQueue'}) {
		undef $ai_v{'clear_aiQueue'};
		undef @ai_seq;
		undef @ai_seq_args;
	}

}




#######################################
#######################################
#Parse Message
#######################################
#######################################



sub parseMsg {
	my $msg = shift;
	my $msg_size;
	return $msg if (length($msg) < 2);
	$switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));
	if ($config{'encrypt'} && length($msg) >= 4 && substr($msg,0,4) ne $accountID && $conState >= 4 && $lastswitch ne $switch
		&& length($msg) >= unpack("S1", substr($msg, 0, 2))) {
		decrypt(\$msg, $msg);
	}
	$switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));
	print "Packet Switch: $switch\n" if ($config{'debug'} >= 2 || $config{'debug_packet'} >= 4);

	if ($lastswitch eq $switch && length($msg) > $lastMsgLength) {
		$errorCount++;
	} else {
		$errorCount = 0;
	}
	if ($errorCount > 3) {
		print "Caught unparsed packet error, potential loss of data.\n";
		dumpData($lastPacket) if ($config{'debug_packet'} >= 2 && $lastPacket ne "");
		dumpData($msg) if ($config{'debug'} || $config{'debug_packet'});
		undef $lastPacket if ($config{'debug_packet'} >= 2);
		$errorCount = 0;
		$msg_size = length($msg);
	}

	$lastswitch = $switch;
	$lastMsgLength = length($msg);
	# Use packet length list
	if ($packetLength{$switch} ne "" && ($packetLength{$switch} != -1 && length($msg) < $packetLength{$switch} || $packetLength{$switch} == -1 && (length($msg) < 4 || length($msg) >= 4 && length($msg) < unpack("S1", substr($msg, 2, 2))))) {
		return $msg;
	} elsif ($packetLength{$switch} ne "" && $packetLength{$switch} eq "all") {
		$msg_size = length($msg);
	} elsif ($packetLength{$switch} ne "" && $packetLength{$switch} == -1) {
		$msg_size = unpack("S1", substr($msg, 2, 2));
	} elsif ($packetLength{$switch} ne "" && $packetLength{$switch} != -1) {
		$msg_size = $packetLength{$switch};
	}
	if (substr($msg,0,4) eq $accountID && ($conState == 2 || $conState == 4)) {
		if ($config{'encrypt'} && $conState == 4) {
			$encryptKey1 = unpack("L1", substr($msg, 6, 4));
			$encryptKey2 = unpack("L1", substr($msg, 10, 4));
			{
				use integer;
				$imult = (($encryptKey1 * $encryptKey2) + $encryptKey1) & 0xFF;
				$imult2 = ((($encryptKey1 * $encryptKey2) << 4) + $encryptKey2 + ($encryptKey1 * 2)) & 0xFF;
			}
			$encryptVal = $imult + ($imult2 << 8);
			$msg_size = 14;
		} else {
			$msg_size = 4;
		}
	} elsif ($switch eq "0069") {
		$conState = 2;
		undef $conState_tries;
		if ($versionSearch) {
			$versionSearch = 0;
			writeDataFileIntact("control/config.txt", \%config);
		}
		$sessionID = substr($msg, 4, 4);
		$accountID = substr($msg, 8, 4);
		$accountSex = unpack("C1",substr($msg, 46, 1));
		$accountSex2 = ($config{'sex'} ne "") ? $config{'sex'} : $accountSex;
		format ACCOUNT =
---------Account Info----------
Account ID: @<<<<<<<<<<<<<<<<<<
            getHex($accountID)
Sex:        @<<<<<<<<<<<<<<<<<<
            $sex_lut{$accountSex}
Session ID: @<<<<<<<<<<<<<<<<<<
            getHex($sessionID)
-------------------------------
.
		$~ = "ACCOUNT";
		write;
		$num = 0;
		undef @servers;
		for ($i = 47; $i < $msg_size; $i+=32) {
			$servers[$num]{'ip'} = makeIP(substr($msg, $i, 4));
			$servers[$num]{'port'} = unpack("S1", substr($msg, $i+4, 2));
			($servers[$num]{'name'}) = substr($msg, $i + 6, 20) =~ /([\s\S]*?)\000/;
			$servers[$num]{'users'} = unpack("L",substr($msg, $i + 26, 4));
			$num++;
		}
		$~ = "SERVERS";
		print "--------- Servers ----------\n";
		print "#         Name            Users  IP              Port\n";
		for ($num = 0; $num < @servers; $num++) {
			format SERVERS =
@<< @<<<<<<<<<<<<<<<<<<<< @<<<<< @<<<<<<<<<<<<<< @<<<<<
$num,$servers[$num]{'name'},$servers[$num]{'users'},$servers[$num]{'ip'},$servers[$num]{'port'}
.
			write;
		}
		print "----------------------------\n";
		print "Closing connection to Master Server\n";
		killConnection(\$remote_socket);
		if (!$config{'charServer_host'} && $config{'server'} eq "") {
			print "Choose your server.  Enter the server number:\n";
			$waitingForInput = 1;
		} elsif ($config{'charServer_host'}) {
			print "Forcing connect to char server $config{'charServer_host'}:$config{'charServer_port'}\n";
		} else {
			print "Server $config{'server'} selected\n";
		}
	} elsif ($switch eq "006A") {
		$type = unpack("C1",substr($msg, 2, 1));
		if ($type == 0) {
			print "Account name doesn't exist\n";
			# Relog when account error
			if ($config{'dcOnAccountErr'}) {
				quitOnEvent("dcOnAccountErr");
			} else {
				print "Enter Username Again:\n";
				$input_socket->recv($msg, $MAX_READ);
				$config{'username'} = $msg;
				writeDataFileIntact("control/config.txt", \%config);
			}
		} elsif ($type == 1) {
			print "Password Error\n";
			# Relog when account error
			if ($config{'dcOnAccountErr'}) {
				quitOnEvent("dcOnAccountErr");
			} else {
				print "Enter Password Again:\n";
				$input_socket->recv($msg, $MAX_READ);
				$config{'password'} = $msg;
				writeDataFileIntact("control/config.txt", \%config);
			}
		} elsif ($type == 3) {
			print "Server connection has been denied\n";
		} elsif ($type == 4) {
			print "Critical Error: Account has been disabled by evil Gravity\n";
			chatLog("ce", "Critical Error: Account has been disabled by evil Gravity\n");
			$quit = 1;
		} elsif ($type == 5) {
			print "Version $config{'version'} failed...trying to find version\n";
			$config{'version'}++;
			if (!$versionSearch) {
				$config{'version'} = 0;
				$versionSearch = 1;
			}
		} elsif ($type == 6) {
			print "The server is temporarily blocking your connection\n";
		}
		if ($type != 5 && $versionSearch) {
			$versionSearch = 0;
			writeDataFileIntact("control/config.txt", \%config);
		}

	} elsif ($switch eq "006B") {
		print "Recieved characters from Game Login Server\n";
		$conState = 3;
		undef $conState_tries;
		if ($config{"master_version_$config{'master'}"} == 0) {
			$startVal = 24;
		} else {
			$startVal = 4;
		}
		for ($i = $startVal; $i < $msg_size; $i+=106) {

#exp display bugfix - chobit andy 20030129
			$num = unpack("C1", substr($msg, $i + 104, 1));
			$chars[$num]{'exp'} = unpack("L1", substr($msg, $i + 4, 4));
			$chars[$num]{'zenny'} = unpack("L1", substr($msg, $i + 8, 4));
			$chars[$num]{'exp_job'} = unpack("L1", substr($msg, $i + 12, 4));
			$chars[$num]{'lv_job'} = unpack("C1", substr($msg, $i + 16, 1));
			$chars[$num]{'hp'} = unpack("S1", substr($msg, $i + 42, 2));
			$chars[$num]{'hp_max'} = unpack("S1", substr($msg, $i + 44, 2));
			$chars[$num]{'sp'} = unpack("S1", substr($msg, $i + 46, 2));
			$chars[$num]{'sp_max'} = unpack("S1", substr($msg, $i + 48, 2));
			$chars[$num]{'jobID'} = unpack("C1", substr($msg, $i + 52, 1));
			$chars[$num]{'lv'} = unpack("C1", substr($msg, $i + 58, 1));
			($chars[$num]{'name'}) = substr($msg, $i + 74, 24) =~ /([\s\S]*?)\000/;
			$chars[$num]{'str'} = unpack("C1", substr($msg, $i + 98, 1));
			$chars[$num]{'agi'} = unpack("C1", substr($msg, $i + 99, 1));
			$chars[$num]{'vit'} = unpack("C1", substr($msg, $i + 100, 1));
			$chars[$num]{'int'} = unpack("C1", substr($msg, $i + 101, 1));
			$chars[$num]{'dex'} = unpack("C1", substr($msg, $i + 102, 1));
			$chars[$num]{'luk'} = unpack("C1", substr($msg, $i + 103, 1));
			$chars[$num]{'sex'} = $accountSex2;
		}
		$~ = "CHAR";
		for ($num = 0; $num < @chars; $num++) {
			format CHAR =
-------  Character @< ---------
         $num
Name: @<<<<<<<<<<<<<<<<<<<<<<<<
      $chars[$num]{'name'}
Job:  @<<<<<<<      Job Exp: @<<<<<<<
$jobs_lut{$chars[$num]{'jobID'}},$chars[$num]{'exp_job'}
Lv:   @<<<<<<<      Str: @<<<<<<<<
$chars[$num]{'lv'}, $chars[$num]{'str'}
J.Lv: @<<<<<<<      Agi: @<<<<<<<<
$chars[$num]{'lv_job'}, $chars[$num]{'agi'}
Exp:  @<<<<<<<      Vit: @<<<<<<<<
$chars[$num]{'exp'},$chars[$num]{'vit'}
HP:   @||||/@||||   Int: @<<<<<<<<
$chars[$num]{'hp'},$chars[$num]{'hp_max'},$chars[$num]{'int'}
SP:   @||||/@||||   Dex: @<<<<<<<<
$chars[$num]{'sp'},$chars[$num]{'sp_max'},$chars[$num]{'dex'}
Zenny: @<<<<<<<<<<  Luk: @<<<<<<<<
$chars[$num]{'zenny'},$chars[$num]{'luk'}
-------------------------------
.
			write;
		}
		if ($config{'char'} eq "") {
			print "Choose your character.  Enter the character number:\n";
			$waitingForInput = 1;
		} else {
			print "Character $config{'char'} selected\n";
			sendCharLogin(\$remote_socket, $config{'char'});
			$timeout{'gamelogin'}{'time'} = time;
		}

	} elsif ($switch eq "006C") {
		print "Error logging into Game Login Server (invalid character specified)...\n";
		$conState = 1;
		undef $conState_tries;

	} elsif ($switch eq "006E") {
		# Failed to creat character

	} elsif ($switch eq "0071") {
		print "Recieved character ID and Map IP from Game Login Server\n";
		$conState = 4;
		undef $conState_tries;
		# Reconnect when map chang bug fix
		undef @ai_seq;
		undef @ai_seq_args;
		$charID = substr($msg, 2, 4);
		($map_name) = substr($msg, 6, 16) =~ /([\s\S]*?)\000/;
		# Relog when no map name supplied
		relog("Could not obtain map information, relogging...\n") if ($map_name eq "");

		($ai_v{'temp'}{'map'}) = $map_name =~ /([\s\S]*)\./;
		if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
			getField("fields/$ai_v{'temp'}{'map'}.fld", \%field);
		}

		$map_ip = makeIP(substr($msg, 22, 4));
		$map_port = unpack("S1", substr($msg, 26, 2));
		format CHARINFO =
-----------Game Info-----------
Char ID: @<<<<<<<<<<<<<<<<<<
            getHex($charID)
MAP Name: @<<<<<<<<<<<<<<<<<<
            $map_name
MAP IP: @<<<<<<<<<<<<<<<<<<
            $map_ip
MAP Port: @<<<<<<<<<<<<<<<<<<
	$map_port
-------------------------------
.
		$~ = "CHARINFO";
		write;
		print "Closing connection to Game Login Server\n";
		killConnection(\$remote_socket);

	} elsif ($switch eq "0073") {
		$conState = 5;
		undef $conState_tries;
		undef $conState_tried;
		makeCoords(\%{$chars[$config{'char'}]{'pos'}}, substr($msg, 6, 3));
		%{$chars[$config{'char'}]{'pos_to'}} = %{$chars[$config{'char'}]{'pos'}};
		print "Your Coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n" if $config{'debug'};
		print "You are now in the game\n";
		sendMapLoaded(\$remote_socket);
		# Avoid GM
		if ($ai_v{'teleOnGM'} eq "2") {
			quitOnEvent("dcOnGM");
			undef %{$ai_v{'dcOnGM_counter'}};
		}
		undef $ai_v{'teleOnGM'};
		# Limit maps
		judgeMapLimit();
		# Set ignore all
		sendIgnoreAll(\$remote_socket, !$config{'ignoreall'});
		$timeout{'ai'}{'time'} = time;

	} elsif ($switch eq "0078" || $switch eq "01D8") {
		$ID = substr($msg, 2, 4);
		makeCoords(\%coords, substr($msg, 46, 3));
		$type = unpack("S*",substr($msg, 14,  2));
		$pet = unpack("C*",substr($msg, 16,  1));
		$sex = unpack("C*",substr($msg, 45,  1));
		$sitting = unpack("C*",substr($msg, 51,  1));
		$param1 = unpack("S1", substr($msg, 8, 2));
		$param2 = unpack("S1", substr($msg, 10, 2));
		$param3 = unpack("S1", substr($msg, 12, 2));
		$level = unpack("S1",substr($msg, 52,  2));
		if ($type >= 1000) {
			if ($pet) {
				if (!%{$pets{$ID}}) {
					$pets{$ID}{'appear_time'} = time;
					$display = ($monsters_lut{$type} ne "")
							? $monsters_lut{$type}
							: "Unknown ".$type;
					binAdd(\@petsID, $ID);
					$pets{$ID}{'nameID'} = $type;
					$pets{$ID}{'name'} = $display;
					$pets{$ID}{'name_given'} = "Unknown";
					$pets{$ID}{'binID'} = binFind(\@petsID, $ID);
				}
				%{$pets{$ID}{'pos'}} = %coords;
				%{$pets{$ID}{'pos_to'}} = %coords;
				print "Pet Exists: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});
			} else {
				if (!%{$monsters{$ID}}) {
					$monsters{$ID}{'appear_time'} = time;
					$display = ($monsters_lut{$type} ne "")
							? $monsters_lut{$type}
							: "Unknown ".$type;
					binAdd(\@monstersID, $ID);
					$monsters{$ID}{'nameID'} = $type;
					$monsters{$ID}{'name'} = $display;
					$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
					$monsters{$ID}{'param1'} = $param1;
					$monsters{$ID}{'param2'} = $param2;
					$monsters{$ID}{'param3'} = $param3;
					# Record monster data
					RecordMonsterData($ID) if ($config{'recordMonsterInfo'});
				}
				%{$monsters{$ID}{'pos'}} = %coords;
				%{$monsters{$ID}{'pos_to'}} = %coords;
				print "Monster Exists: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if ($config{'debug'});
			}

		} elsif ($jobs_lut{$type} ne "") {
			if (!%{$players{$ID}}) {
				$players{$ID}{'appear_time'} = time;
				binAdd(\@playersID, $ID);
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'name'} = "Unknown";
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);
			}
			$players{$ID}{'hair_s'} = unpack("S1",substr($msg, 16,  2));
			$players{$ID}{'weapon'} = unpack("S1",substr($msg, 18,  2));
			$players{$ID}{'shield'} = unpack("S1",substr($msg, 20,  2));
			$players{$ID}{'hair_c'} = unpack("S1",substr($msg, 28,  2));
			$players{$ID}{'level'} = $level;
			$players{$ID}{'sitting'} = $sitting > 0;
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
			print "Player Exists: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});
			# Avoid GM
			avoidGM($ID, $players{$ID}{'name'}, 0) if $config{'dcOnGM_paranoia'};

		} elsif ($type == 45) {
			if (!%{$portals{$ID}}) {
				$portals{$ID}{'appear_time'} = time;
				$nameID = unpack("L1", $ID);
				$exists = portalExists($field{'name'}, \%coords);
				$display = ($exists ne "")
					? "$portals_lut{$exists}{'source'}{'map'} -> $portals_lut{$exists}{'dest'}{'map'}"
					: "Unknown ".$nameID;
				binAdd(\@portalsID, $ID);
				$portals{$ID}{'source'}{'map'} = $field{'name'};
				$portals{$ID}{'type'} = $type;
				$portals{$ID}{'nameID'} = $nameID;
				$portals{$ID}{'name'} = $display;
				$portals{$ID}{'binID'} = binFind(\@portalsID, $ID);
			}
			%{$portals{$ID}{'pos'}} = %coords;
			print "Portal Exists: $portals{$ID}{'name'} - ($portals{$ID}{'binID'})\n";

		} elsif ($type < 1000) {
			if (!%{$npcs{$ID}}) {
				$npcs{$ID}{'appear_time'} = time;
				$nameID = unpack("L1", $ID);
				$display = (%{$npcs_lut{$nameID}})
					? $npcs_lut{$nameID}{'name'}
					: "Unknown ".$nameID;
				binAdd(\@npcsID, $ID);
				$npcs{$ID}{'type'} = $type;
				$npcs{$ID}{'nameID'} = $nameID;
				$npcs{$ID}{'name'} = $display;
				$npcs{$ID}{'binID'} = binFind(\@npcsID, $ID);
			}
			%{$npcs{$ID}{'pos'}} = %coords;
			print "NPC Exists: $npcs{$ID}{'name'} - ($npcs{$ID}{'binID'})\n";

		} else {
			print "Unknown Exists: $type - ".unpack("L*",$ID)."\n" if $config{'debug'};
			# Avoid GM
			avoidGM($ID, "Unknown type $type", 0) if $config{'dcOnGM_paranoia'};
		}

	} elsif ($switch eq "0079" || $switch eq "01D9") {
		$ID = substr($msg, 2, 4);
		makeCoords(\%coords, substr($msg, 46, 3));
		$type = unpack("S*",substr($msg, 14,  2));
		$sex = unpack("C*",substr($msg, 45,  1));
		$level = unpack("S1",substr($msg, 51,  2));
		if ($jobs_lut{$type}) {
			if (!%{$players{$ID}}) {
				$players{$ID}{'appear_time'} = time;
				binAdd(\@playersID, $ID);
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'name'} = "Unknown";
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);
			}
			$players{$ID}{'hair_s'} = unpack("S1",substr($msg, 16,  2));
			$players{$ID}{'weapon'} = unpack("S1",substr($msg, 18,  2));
			$players{$ID}{'shield'} = unpack("S1",substr($msg, 20,  2));
			$players{$ID}{'hair_c'} = unpack("S1",substr($msg, 28,  2));
			$players{$ID}{'level'} = $level;
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
			print "Player Connected: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});
			# Avoid GM
			avoidGM($ID, $players{$ID}{'name'}, 0) if $config{'dcOnGM_paranoia'};

		} else {
			print "Unknown Connected: $type - ".getHex($ID)."\n" if $config{'debug'};
			# Avoid GM
			avoidGM($ID, "Unknown type $type", 0) if $config{'dcOnGM_paranoia'};
		}

	} elsif ($switch eq "007B" || $switch eq "01DA") {
		$ID = substr($msg, 2, 4);
		makeCoords(\%coordsFrom, substr($msg, 50, 3));
		makeCoords2(\%coordsTo, substr($msg, 52, 3));
		$type = unpack("S*",substr($msg, 14,  2));
		$pet = unpack("C*",substr($msg, 16,  1));
		$sex = unpack("C*",substr($msg, 49,  1));
		$param1 = unpack("S1", substr($msg, 8, 2));
		$param2 = unpack("S1", substr($msg, 10, 2));
		$param3 = unpack("S1", substr($msg, 12, 2));
		$level = unpack("S1",substr($msg, 58,  2));
		if ($type >= 1000) {
			if ($pet) {
				if (!%{$pets{$ID}}) {
					$pets{$ID}{'appear_time'} = time;
					$display = ($monsters_lut{$type} ne "")
							? $monsters_lut{$type}
							: "Unknown ".$type;
					binAdd(\@petsID, $ID);
					$pets{$ID}{'nameID'} = $type;
					$pets{$ID}{'name'} = $display;
					$pets{$ID}{'name_given'} = "Unknown";
					$pets{$ID}{'binID'} = binFind(\@petsID, $ID);
				}
				%{$pets{$ID}{'pos'}} = %coords;
				%{$pets{$ID}{'pos_to'}} = %coords;
				if (%{$monsters{$ID}}) {
					binRemove(\@monstersID, $ID);
					undef %{$monsters{$ID}};
				}
				print "Pet Moved: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});
			} else {
				if (!%{$monsters{$ID}}) {
					binAdd(\@monstersID, $ID);
					$monsters{$ID}{'appear_time'} = time;
					$monsters{$ID}{'nameID'} = $type;
					$display = ($monsters_lut{$type} ne "")
						? $monsters_lut{$type}
						: "Unknown ".$type;
					$monsters{$ID}{'nameID'} = $type;
					$monsters{$ID}{'name'} = $display;
					$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
					$monsters{$ID}{'param1'} = $param1;
					$monsters{$ID}{'param2'} = $param2;
					$monsters{$ID}{'param3'} = $param3;
					print "Monster Appeared: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if $config{'debug'};
					# Record monster data
					RecordMonsterData($ID) if ($config{'recordMonsterInfo'});
				}
				%{$monsters{$ID}{'pos'}} = %coordsFrom;
				%{$monsters{$ID}{'pos_to'}} = %coordsTo;
				print "Monster Moved: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if ($config{'debug'} >= 2);
			}
		} elsif ($jobs_lut{$type} ne "") {
			if (!%{$players{$ID}}) {
				binAdd(\@playersID, $ID);
				$players{$ID}{'appear_time'} = time;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'name'} = "Unknown";
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);
				print "Player Appeared: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$sex} $jobs_lut{$type}\n" if $config{'debug'};
			}
			$players{$ID}{'hair_s'} = unpack("S1",substr($msg, 16,  2));
			$players{$ID}{'weapon'} = unpack("S1",substr($msg, 18,  2));
			$players{$ID}{'shield'} = unpack("S1",substr($msg, 20,  2));
			$players{$ID}{'hair_c'} = unpack("S1",substr($msg, 32,  2));
			$players{$ID}{'level'} = $level;
			%{$players{$ID}{'pos'}} = %coordsFrom;
			%{$players{$ID}{'pos_to'}} = %coordsTo;
			print "Player Moved: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'} >= 2);
			# Avoid GM
			avoidGM($ID, $players{$ID}{'name'}, 0) if $config{'dcOnGM_paranoia'};
		} else {
			print "Unknown Moved: $type - ".getHex($ID)."\n" if $config{'debug'};
			# Avoid GM
			avoidGM($ID, "Unknown type $type", 0) if $config{'dcOnGM_paranoia'};
		}

	} elsif ($switch eq "007C") {
		$ID = substr($msg, 2, 4);
		makeCoords(\%coords, substr($msg, 36, 3));
		$type = unpack("S*",substr($msg, 20,  2));
		$sex = unpack("C*",substr($msg, 35,  1));
		if ($type >= 1000) {
			if (!%{$monsters{$ID}}) {
				binAdd(\@monstersID, $ID);
				$monsters{$ID}{'nameID'} = $type;
				$monsters{$ID}{'appear_time'} = time;
				$display = ($monsters_lut{$monsters{$ID}{'nameID'}} ne "")
						? $monsters_lut{$monsters{$ID}{'nameID'}}
						: "Unknown ".$monsters{$ID}{'nameID'};
				$monsters{$ID}{'name'} = $display;
				$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
				# Record monster data
				RecordMonsterData($ID) if ($config{'recordMonsterInfo'});
			}
			%{$monsters{$ID}{'pos'}} = %coords;
			%{$monsters{$ID}{'pos_to'}} = %coords;
			print "Monster Spawned: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if ($config{'debug'});
		} elsif ($jobs_lut{$type} ne "") {
			if (!%{$players{$ID}}) {
				binAdd(\@playersID, $ID);
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'name'} = "Unknown";
				$players{$ID}{'appear_time'} = time;
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);
			}
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
			print "Player Spawned: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});
			# Avoid GM
			avoidGM($ID, $players{$ID}{'name'}, 0) if $config{'dcOnGM_paranoia'};
		} else {
			print "Unknown Spawned: $type - ".getHex($ID)."\n" if $config{'debug'};
			# Avoid GM
			avoidGM($ID, "Unknown type $type", 0) if $config{'dcOnGM_paranoia'};
		}

	} elsif ($switch eq "007F") {
		$time = unpack("L1",substr($msg, 2, 4));
		print "Recieved Sync\n" if ($config{'debug'} >= 2);
		$timeout{'play'}{'time'} = time;

	} elsif ($switch eq "0080") {
		$ID = substr($msg, 2, 4);
		$type = unpack("C1",substr($msg, 6, 1));

		if ($ID eq $accountID) {
			print "You have died\n";
			$chars[$config{'char'}]{'dead'} = 1;
			$chars[$config{'char'}]{'dead_time'} = time;
			# Log dying message
			if ($config{'recordDyingMsg'}) {
				chatLog("dv", "*** You have died - [$maps_lut{$field{'name'}.'.rsw'}($field{'name'}) : $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'}] ***\n");
				logCommand(">> logs/Etc.txt","ai");
				logCommand(">> logs/Etc.txt","aml");
			}
			# Close shop when died
			if ($shop{'opened'}) {
				$shop{'opened'} = 0;
				sendCloseShop(\$remote_socket);
			}
		} elsif (%{$monsters{$ID}}) {
			%{$monsters_old{$ID}} = %{$monsters{$ID}};
			$monsters_old{$ID}{'gone_time'} = time;
			if ($type == 0 || $type == 3) {
				print "Monster Disappeared: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if $config{'debug'};
				$monsters_old{$ID}{'disappeared'} = 1;

			} elsif ($type == 1) {
				print "Monster Died: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if $config{'debug'};
				$monsters_old{$ID}{'dead'} = 1;
			}
			binRemove(\@monstersID, $ID);
			undef %{$monsters{$ID}};
		} elsif (%{$players{$ID}}) {
			if ($type == 0 || $type == 3) {
				print "Player Disappeared: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if $config{'debug'};
				%{$players_old{$ID}} = %{$players{$ID}};
				$players_old{$ID}{'disappeared'} = 1;
				$players_old{$ID}{'gone_time'} = time;
				binRemove(\@playersID, $ID);
				undef %{$players{$ID}};
			} elsif ($type == 1) {
				print "Player Died: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n";
				$players{$ID}{'dead'} = 1;
			} elsif ($type == 2) {
				print "Player Disconnected: $players{$ID}{'name'}\n" if $config{'debug'};
				%{$players_old{$ID}} = %{$players{$ID}};
				$players_old{$ID}{'disconnected'} = 1;
				$players_old{$ID}{'gone_time'} = time;
				binRemove(\@playersID, $ID);
				undef %{$players{$ID}};
			}
		} elsif (%{$players_old{$ID}}) {
			if ($type == 2) {
				print "Player Disconnected: $players_old{$ID}{'name'}\n" if $config{'debug'};
				$players_old{$ID}{'disconnected'} = 1;
			}
		} elsif (%{$portals{$ID}}) {
			print "Portal Disappeared: $portals{$ID}{'name'} ($portals{$ID}{'binID'})\n" if ($config{'debug'});
			%{$portals_old{$ID}} = %{$portals{$ID}};
			$portals_old{$ID}{'disappeared'} = 1;
			$portals_old{$ID}{'gone_time'} = time;
			binRemove(\@portalsID, $ID);
			undef %{$portals{$ID}};
		} elsif (%{$npcs{$ID}}) {
			print "NPC Disappeared: $npcs{$ID}{'name'} ($npcs{$ID}{'binID'})\n" if ($config{'debug'});
			%{$npcs_old{$ID}} = %{$npcs{$ID}};
			$npcs_old{$ID}{'disappeared'} = 1;
			$npcs_old{$ID}{'gone_time'} = time;
			binRemove(\@npcsID, $ID);
			undef %{$npcs{$ID}};
		} elsif (%{$pets{$ID}}) {
			print "Pet Disappeared: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});
			binRemove(\@petsID, $ID);
			undef %{$pets{$ID}};
		} else {
			print "Unknown Disappeared: ".getHex($ID)."\n" if $config{'debug'};
		}
		# Remove skill_use if target lost
		my $ai_index = binFind(\@ai_seq, "skill_use");
		if ($ai_index ne "" && $ID eq $ai_seq_args[$ai_index]{'skill_use_target'}) {
			aiRemove("skill_use");
		}


	} elsif ($switch eq "0081") {
		$type = unpack("C1", substr($msg, 2, 1));
		$conState = 1;
		undef $conState_tries;
		if ($type == 2) {
			print "Critical Error: Dual login prohibited - Someone trying to login!\n";
			chatLog("ce", "Critical Error: Dual login prohibited - Someone trying to login!\n");
			# Quit on event
			quitOnEvent("dcOnDualLogin");
		} elsif ($type == 3) {
			print "Error: Out of sync with server\n";
			# Avoid GM
			if ($ai_v{'teleOnGM'}) {
				quitOnEvent("dcOnGM");
				undef $ai_v{'teleOnGM'};
				undef %{$ai_v{'dcOnGM_counter'}};
			}
		} elsif ($type == 5) {
			print "Critical Error: Your age under 18\n";
		} elsif ($type == 6) {
			print "Critical Error: You must pay to play this account!\n";
			chatLog("ce", "Critical Error: You must pay to play this account!\n");
			# Relog when server request to pay
			quitOnEvent("dcOnPayRequest");
		} elsif ($type == 8) {
			print "Error: The server still recognizes your last connection\n";
		}

	} elsif ($switch eq "0087") {
		makeCoords(\%coordsFrom, substr($msg, 6, 3));
		makeCoords2(\%coordsTo, substr($msg, 8, 3));
		%{$chars[$config{'char'}]{'pos'}} = %coordsFrom;
		%{$chars[$config{'char'}]{'pos_to'}} = %coordsTo;
		print "You move to: $coordsTo{'x'}, $coordsTo{'y'}\n" if $config{'debug'};
		$chars[$config{'char'}]{'time_move'} = time;
		$chars[$config{'char'}]{'time_move_calc'} = distance(\%{$chars[$config{'char'}]{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}) * $config{'seconds_per_block'};

	} elsif ($switch eq "0088") {
		undef $level_real;
		# Long distance attack solution
		$ID = substr($msg, 2, 4);
		$coords{'x'} = unpack("S1", substr($msg, 6, 2));
		$coords{'y'} = unpack("S1", substr($msg, 8, 2));
		if ($ID eq $accountID) {
			%{$chars[$config{'char'}]{'pos'}} = %coords;
			%{$chars[$config{'char'}]{'pos_to'}} = %coords;
			print "Movement interrupted, your coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n" if $config{'debug'};
			aiRemove("move");
		} elsif (%{$monsters{$ID}}) {
			%{$monsters{$ID}{'pos'}} = %coords;
			%{$monsters{$ID}{'pos_to'}} = %coords;
		} elsif (%{$players{$ID}}) {
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
#		} else {
#			dumpData(substr($msg, 0, $msg_size)) if ($config{'debug_packet'} >= 3);
		}

	} elsif ($switch eq "008A") {
		$ID1 = substr($msg, 2, 4);
		$ID2 = substr($msg, 6, 4);
		$standing = unpack("C1", substr($msg, 26, 1)) - 2;
		$damage = unpack("S1", substr($msg, 22, 2));
		# Left hand damage
		$damage += unpack("S1", substr($msg, 27, 2)) if ($ID1 eq $accountID || %{$players{$ID1}});
		# Detect kill steal
		my $ai_index = binFind(\@ai_seq, "attack");
		# Critical hit and lucky miss display
		$type = unpack("C1", substr($msg, 26, 1));
		if ($damage == 0) {
			if ($type == 11) {
				$dmgdisplay = "Lucky Miss!";
			} else {
				$dmgdisplay = "Miss!";
			}
		} else {
			if ($type == 10) {
				$dmgdisplay = "Cri: ".$damage;
			} else {
				$dmgdisplay = "Dmg: ".$damage;
			}
		}
		updateDamageTables($ID1, $ID2, $damage);
		if ($ID1 eq $accountID) {
			if (%{$monsters{$ID2}}) {
				# HP/SP info display
				print "$ai_v{'hsinfo'}You attack Monster: $monsters{$ID2}{'name'} ($monsters{$ID2}{'binID'}) - $dmgdisplay (Total: $monsters{$ID2}{'dmgTo'})\n";
				$timeout{'ai_attack'}{'time'} = time;
			} elsif (%{$items{$ID2}}) {
				print "You pick up Item: $items{$ID2}{'name'} ($items{$ID2}{'binID'})\n" if $config{'debug'};
				$items{$ID2}{'takenBy'} = $accountID;
			} elsif ($ID2 == 0) {
				if ($standing) {
					$chars[$config{'char'}]{'sitting'} = 0;
					print "You're Standing\n";
				} else {
					$chars[$config{'char'}]{'sitting'} = 1;
					print "You're Sitting\n";
				}
			}
		} elsif ($ID2 eq $accountID) {
			if (%{$monsters{$ID1}}) {
				# HP/SP info display
				print "$ai_v{'hsinfo'}Monster attacks You: $monsters{$ID1}{'name'} ($monsters{$ID1}{'binID'}) - $dmgdisplay\n";
			}
		} elsif (%{$monsters{$ID1}}) {
			if (%{$players{$ID2}}) {
				print "Monster $monsters{$ID1}{'name'} ($monsters{$ID1}{'binID'}) attacks Player $players{$ID2}{'name'} ($players{$ID2}{'binID'}) - $dmgdisplay\n" if ($config{'debug'});
				# Detect kill steal
				JudgeAttackSameTarget($ID1) if ($config{'useDetection'} && $ai_index ne "" && $ai_seq_args[$ai_index]{'ID'} eq $ID1);
			} else {
				# Avoid GM
				avoidGM($ID2, "Unknown", 0) if $config{'dcOnGM_paranoia'};
			}

		} elsif (%{$players{$ID1}}) {
			if (%{$monsters{$ID2}}) {
				print "Player $players{$ID1}{'name'} ($players{$ID1}{'binID'}) attacks Monster $monsters{$ID2}{'name'} ($monsters{$ID2}{'binID'}) - $dmgdisplay\n" if ($config{'debug'});
				# Detect kill steal
				JudgeAttackSameTarget($ID2) if ($config{'useDetection'} && $ai_index ne "" && $ai_seq_args[$ai_index]{'ID'} eq $ID2);
			} elsif (%{$items{$ID2}}) {
				$items{$ID2}{'takenBy'} = $ID1;
				print "Player $players{$ID1}{'name'} ($players{$ID1}{'binID'}) picks up Item $items{$ID2}{'name'} ($items{$ID2}{'binID'})\n" if ($config{'debug'});
			} elsif ($ID2 == 0) {
				if ($standing) {
					$players{$ID1}{'sitting'} = 0;
					print "Player is Standing: $players{$ID1}{'name'} ($players{$ID1}{'binID'})\n" if $config{'debug'};
				} else {
					$players{$ID1}{'sitting'} = 1;
					print "Player is Sitting: $players{$ID1}{'name'} ($players{$ID1}{'binID'})\n" if $config{'debug'};
				}
			}
		} else {
			print "Unknown ".getHex($ID1)." attacks ".getHex($ID2)." - $dmgdisplay\n" if $config{'debug'};
			# Avoid GM
			avoidGM($ID1, "Unknown", 0) if $config{'dcOnGM_paranoia'};
			avoidGM($ID2, "Unknown", 0) if $config{'dcOnGM_paranoia'};
		}

	} elsif ($switch eq "008D") {
		$ID = substr($msg, 4, 4);
		$chat = substr($msg, 8, $msg_size - 8);
		$chat = recallCheck($chat) if ($recallCommand ne "");
		($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
		# Display player info
		if (%{$players{$ID}}) {
			$chat = "(Dt:".int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$ID}{'pos_to'}}))
				."/Jb:$jobs_lut{$players{$ID}{'jobID'}}/Lv:$players{$ID}{'level'}\[$players{$ID}{'binID'}])"
				.$chat;
		}
		chatLog("c", $chat."\n");
		$ai_cmdQue[$ai_cmdQue]{'type'} = "c";
		$ai_cmdQue[$ai_cmdQue]{'ID'} = $ID;
		$ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser;
		$ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg;
		$ai_cmdQue[$ai_cmdQue]{'time'} = time;
		$ai_cmdQue++;
		print "$chat\n";
		# Avoid GM
		avoidGM($ID, $chatMsgUser, 1);
		# Auto reply chat
		my $dPDist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$ID}{'pos_to'}});
		if ($dPDist < $config{'autoResponse'}) {
			my $resMsg = judgeRes('#c#'.$chatMsg, $chatMsgUser);
			ai_action("Reply", "c ".$resMsg) if ($resMsg);
		}

	} elsif ($switch eq "008E") {
		$chat = substr($msg, 4, $msg_size - 4);
		$chat = recallCheck($chat) if ($recallCommand ne "");
		($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
		chatLog("c", $chat."\n");
		$ai_cmdQue[$ai_cmdQue]{'type'} = "c";
		$ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser;
		$ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg;
		$ai_cmdQue[$ai_cmdQue]{'time'} = time;
		$ai_cmdQue++;
		print "$chat\n";
		# Avoid GM
		avoidGM("", $chatMsgUser, 1);

	} elsif ($switch eq "0091") {
		initMapChangeVars();
		for ($i = 0; $i < @ai_seq; $i++) {
			ai_setMapChanged($i);
		}
		($map_name) = substr($msg, 2, 16) =~ /([\s\S]*?)\000/;
		# Relog when no map name supplied
		relog("Could not obtain map information, relogging...\n") if ($map_name eq "");
		($ai_v{'temp'}{'map'}) = $map_name =~ /([\s\S]*)\./;
		if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
			getField("fields/$ai_v{'temp'}{'map'}.fld", \%field);
		}
		$coords{'x'} = unpack("S1", substr($msg, 18, 2));
		$coords{'y'} = unpack("S1", substr($msg, 20, 2));
		%{$chars[$config{'char'}]{'pos'}} = %coords;
		%{$chars[$config{'char'}]{'pos_to'}} = %coords;
		print "Map Change: $map_name\n";
		print "Your Coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n" if $config{'debug'};
		print "Sending Map Loaded\n" if $config{'debug'};
		sendMapLoaded(\$remote_socket);
		# Avoid GM
		if ($ai_v{'teleOnGM'} eq "2") {
			quitOnEvent("dcOnGM");
			undef %{$ai_v{'dcOnGM_counter'}};
		}
		undef $ai_v{'teleOnGM'};
		# Limit maps
		judgeMapLimit($ai_v{'temp'}{'map'});
		$timeout{'ai'}{'time'} = time - $timeout{'ai'}{'timeout'} + 0.5;

	} elsif ($switch eq "0092") {
		$conState = 4;
		undef $conState_tries;
		for ($i = 0; $i < @ai_seq; $i++) {
			ai_setMapChanged($i);
		}
		($map_name) = substr($msg, 2, 16) =~ /([\s\S]*?)\000/;
		# Relog when no map name supplied
		relog("Could not obtain map information, relogging...\n") if ($map_name eq "");
		($ai_v{'temp'}{'map'}) = $map_name =~ /([\s\S]*)\./;
		if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
			getField("fields/$ai_v{'temp'}{'map'}.fld", \%field);
		}
		$map_ip = makeIP(substr($msg, 22, 4));
		$map_port = unpack("S1", substr($msg, 26, 2));
		format MAPINFO =
--------Map Change Info--------
MAP Name: @<<<<<<<<<<<<<<<<<<
            $map_name
MAP IP: @<<<<<<<<<<<<<<<<<<
            $map_ip
MAP Port: @<<<<<<<<<<<<<<<<<<
	$map_port
-------------------------------
.
		$~ = "MAPINFO";
		write;
		print "Closing connection to Map Server\n";
		killConnection(\$remote_socket);

	} elsif ($switch eq "0095") {
		$ID = substr($msg, 2, 4);
		if (%{$players{$ID}}) {
			($players{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			if ($config{'debug'} >= 2) {
				$binID = binFind(\@playersID, $ID);
				print "Player Info: $players{$ID}{'name'} ($binID)\n";
			}
			# Record player data
			RecordPlayerData($ID) if ($config{'recordPlayerInfo'});
			# Avoid GM
			avoidGM($ID, $players{$ID}{'name'}, 0);
			# Avoid specified player
			avoidPlayer($ID);
		}
		if (%{$monsters{$ID}}) {
			($monsters{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			if ($config{'debug'} >= 2) {
				$binID = binFind(\@monstersID, $ID);
				print "Monster Info: $monsters{$ID}{'name'} ($binID)\n";
			}
			if ($monsters_lut{$monsters{$ID}{'nameID'}} eq "") {
				$monsters_lut{$monsters{$ID}{'nameID'}} = $monsters{$ID}{'name'};
				updateMonsterLUT("tables/monsters.txt", $monsters{$ID}{'nameID'}, $monsters{$ID}{'name'});
			}
		}
		if (%{$npcs{$ID}}) {
			($npcs{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			if ($config{'debug'} >= 2) {
				$binID = binFind(\@npcsID, $ID);
				print "NPC Info: $npcs{$ID}{'name'} ($binID)\n";
			}
			# NPC Update
			foreach (keys(%npcs_lut)) {
				if ($npcs_lut{$_}{'map'} eq $field{'name'} && $npcs_lut{$_}{'name'} eq $npcs{$ID}{'name'} && $_ ne $npcs{$ID}{'nameID'} && $npcs_lut{$_}{'pos'}{'x'} == $npcs{$ID}{'pos'}{'x'} && $npcs_lut{$_}{'pos'}{'y'} == $npcs{$ID}{'pos'}{'y'}) {
					print "Auto-update NPC data - $npcs_lut{$_}{'name'} : $_ -> $npcs{$ID}{'nameID'}\n";
					chatLog("au", "NPC data updated - $npcs_lut{$_}{'name'} : $_ -> $npcs{$ID}{'nameID'}\n");
					updateNPCLUTIntact("tables/npcs.txt", $_, $npcs{$ID}{'nameID'});
					updatePortalLUTIntact("tables/portals.txt", $_, $npcs{$ID}{'nameID'});
					parseInput("reload npcs");
					parseInput("reload portals");
					$i = 0;
					while ($config{"buyAuto_$i"."_npc"}) {
						configModify("buyAuto_$i"."_npc", $npcs{$ID}{'nameID'}) if ($config{"buyAuto_$i"."_npc"} eq $_);
						$i++;
					}
					configModify('healAuto_npc', $npcs{$ID}{'nameID'}) if ($config{'healAuto_npc'} eq $_);
					configModify('sellAuto_npc', $npcs{$ID}{'nameID'}) if ($config{'sellAuto_npc'} eq $_);
					configModify('storageAuto_npc', $npcs{$ID}{'nameID'}) if ($config{'storageAuto_npc'} eq $_);
					aiRemove("move");
					aiRemove("route");
					aiRemove("route_getRoute");
					aiRemove("route_getMapRoute");
					last;
				}
			}
			if (!%{$npcs_lut{$npcs{$ID}{'nameID'}}}) {
				$npcs_lut{$npcs{$ID}{'nameID'}}{'name'} = $npcs{$ID}{'name'};
				$npcs_lut{$npcs{$ID}{'nameID'}}{'map'} = $field{'name'};
				%{$npcs_lut{$npcs{$ID}{'nameID'}}{'pos'}} = %{$npcs{$ID}{'pos'}};
				updateNPCLUT("tables/npcs.txt", $npcs{$ID}{'nameID'}, $field{'name'}, $npcs{$ID}{'pos'}{'x'}, $npcs{$ID}{'pos'}{'y'}, $npcs{$ID}{'name'});
			}
		}
		if (%{$pets{$ID}}) {
			($pets{$ID}{'name_given'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			if ($config{'debug'} >= 2) {
				$binID = binFind(\@petsID, $ID);
				print "Pet Info: $pets{$ID}{'name_given'} ($binID)\n";
			}
		}

	} elsif ($switch eq "0097") {
		decrypt(\$newmsg, substr($msg, 28, length($msg)-28));
		$msg = substr($msg, 0, 28).$newmsg;
		($privMsgUser) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
		$privMsg = substr($msg, 28, $msg_size - 29);
		$privMsg = recallCheck($privMsg) if ($recallCommand ne "");
		if ($privMsgUser ne "" && binFind(\@privMsgUsers, $privMsgUser) eq "") {
			$privMsgUsers[@privMsgUsers] = $privMsgUser;
		}
		chatLog("pm", "(From: $privMsgUser) : $privMsg\n");
		$ai_cmdQue[$ai_cmdQue]{'type'} = "pm";
		$ai_cmdQue[$ai_cmdQue]{'user'} = $privMsgUser;
		$ai_cmdQue[$ai_cmdQue]{'msg'} = $privMsg;
		$ai_cmdQue[$ai_cmdQue]{'time'} = time;
		$ai_cmdQue++;
		print "(From: $privMsgUser) : $privMsg\n";
		# Avoid GM
		avoidGM("", $privMsgUser, 1);
		# Auto reply pm
		if ($config{'autoResponse'}) {
			my $resMsg = judgeRes('#pm#'.$privMsg, $privMsgUser);
			ai_action("Reply", "pm \"".$privMsgUser."\" ".$resMsg) if ($resMsg);
		}

	} elsif ($switch eq "0098") {
		$type = unpack("C1",substr($msg, 2, 1));
		if ($type == 0) {
			print "(To $lastpm[0]{'user'}) : $lastpm[0]{'msg'}\n";
			chatLog("pm", "(To: $lastpm[0]{'user'}) : $lastpm[0]{'msg'}\n");
		} elsif ($type == 1) {
			print "$lastpm[0]{'user'} is not online\n";
		} elsif ($type == 2) {
			print "Player can't hear you - you are ignored\n";
		}
		shift @lastpm;

	} elsif ($switch eq "009A") {
		$chat = substr($msg, 4, $msg_size - 4);
		$chat = recallCheck($chat) if ($recallCommand ne "");
		chatLog("s", $chat."\n");
		print "$chat\n";
		# Avoid GM
		if ($config{'dcOnGM'} && $ai_v{'teleOnGM'} != 2) {
			($chatMsgUser) = $chat =~ /([\s\S]*?)\s?:/;
			undef $chatMsgUser if (length($chatMsgUser) > 24 || $chatMsgUser =~ /^GM\d{2}/i);
			$key = findKeyString(\%players, "name", $chatMsgUser) if ($chatMsgUser ne "");
			if ($key ne "") {
				if ($autoLogoff{$chatMsgUser} eq "") {
					open(DATA, modifingPath(">> control/autologoff.txt"));
					print DATA "$chatMsgUser 1\n";
					close DATA;
					$autoLogoff{$chatMsgUser} = 1;
				}
				avoidGM($key, $chatMsgUser, 1);
			}
			my $i = 0;
			my $match;
			$match++ if ($config{'AcWord_charName'} && $chat =~ /\Q$chars[$config{'char'}]{'name'}\E/);
			while ($config{"AcWord_$i"} ne "") {
				if ($chat =~ qr/$config{"AcWord_$i"}/) {
					$match++;
					last;
				}
				$i++;
			}
			my @array = split /,/, $config{'dcOnSysWord'};
			foreach (@array) {
				s/^\s+//;
				s/\s+$//;
				s/\s+/ /g;
				next if ($_ eq "");
				$match++ if ($chat =~ /\Q$_\E/);
			}
			if ($match) {
				print "Disconnecting on avoid GM!\n";
				chatLog("s", "*** The GM talked to you, auto disconnected ***\n");
				if (!$cities_lut{$field{'name'}.'.rsw'} && !$config{'dcOnGM_noTele'}) {
					useTeleport(2);
					$ai_v{'teleOnGM'} = 2;
				} else {
					quitOnEvent("dcOnGM");
					undef %{$ai_v{'dcOnGM_counter'}};
				}
			}
		}
		# Auto Reply system message
		if ($config{'autoResponse'}) {
			my $resMsg = judgeRes('#s#'.$chat, $chars[$config{'char'}]{'name'});
			ai_action("Reply", "c ".$resMsg) if ($resMsg);
		}

	} elsif ($switch eq "009C") {
		$ID = substr($msg, 2, 4);
		$body = unpack("C1",substr($msg, 8, 1));
		$head = unpack("C1",substr($msg, 6, 1));
		if ($ID eq $accountID) {
			$chars[$config{'char'}]{'look'}{'head'} = $head;
			$chars[$config{'char'}]{'look'}{'body'} = $body;
			print "You look at $chars[$config{'char'}]{'look'}{'body'}, $chars[$config{'char'}]{'look'}{'head'}\n" if ($config{'debug'} >= 2);

		} elsif (%{$players{$ID}}) {
			$players{$ID}{'look'}{'head'} = $head;
			$players{$ID}{'look'}{'body'} = $body;
			print "Player $players{$ID}{'name'} ($players{$ID}{'binID'}) looks at $players{$ID}{'look'}{'body'}, $players{$ID}{'look'}{'head'}\n" if ($config{'debug'} >= 2);

		} elsif (%{$monsters{$ID}}) {
			$monsters{$ID}{'look'}{'head'} = $head;
			$monsters{$ID}{'look'}{'body'} = $body;
			print "Monster $monsters{$ID}{'name'} ($monsters{$ID}{'binID'}) looks at $monsters{$ID}{'look'}{'body'}, $monsters{$ID}{'look'}{'head'}\n" if ($config{'debug'} >= 2);
		}

	} elsif ($switch eq "009D") {
		$ID = substr($msg, 2, 4);
		$type = unpack("S1",substr($msg, 6, 2));
		$x = unpack("S1", substr($msg, 9, 2));
		$y = unpack("S1", substr($msg, 11, 2));
		$amount = unpack("S1", substr($msg, 13, 2));
		if (!%{$items{$ID}}) {
			binAdd(\@itemsID, $ID);
			$items{$ID}{'appear_time'} = time;
			$items{$ID}{'amount'} = $amount;
			$items{$ID}{'nameID'} = $type;
			$display = ($items_lut{$items{$ID}{'nameID'}} ne "")
				? $items_lut{$items{$ID}{'nameID'}}
				: "Unknown ".$items{$ID}{'nameID'};
			$items{$ID}{'binID'} = binFind(\@itemsID, $ID);
			$items{$ID}{'name'} = $display;
		}
		$items{$ID}{'pos'}{'x'} = $x;
		$items{$ID}{'pos'}{'y'} = $y;
		print "Item Exists: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'}\n";
		# Search for rare item in specified range
		if ($config{'itemsImportantAuto'} && !binSize(\@playersID)) {
			getImportantItems($ID);
		}

	} elsif ($switch eq "009E") {
		$ID = substr($msg, 2, 4);
		$type = unpack("S1",substr($msg, 6, 2));
		$x = unpack("S1", substr($msg, 9, 2));
		$y = unpack("S1", substr($msg, 11, 2));
		$amount = unpack("S1", substr($msg, 15, 2));
		if (!%{$items{$ID}}) {
			binAdd(\@itemsID, $ID);
			$items{$ID}{'appear_time'} = time;
			$items{$ID}{'amount'} = $amount;
			$items{$ID}{'nameID'} = $type;
			$display = ($items_lut{$items{$ID}{'nameID'}} ne "")
				? $items_lut{$items{$ID}{'nameID'}}
				: "Unknown ".$items{$ID}{'nameID'};
			$items{$ID}{'binID'} = binFind(\@itemsID, $ID);
			$items{$ID}{'name'} = $display;
		}
		$items{$ID}{'pos'}{'x'} = $x;
		$items{$ID}{'pos'}{'y'} = $y;
		print "Item Appeared: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'}\n";
		# Search for rare item in specified range
		my $iDist = distance($items{$ID}{'pos'}, $chars[$config{'char'}]{'pos_to'});
		if ($config{'itemsImportantAuto'} && $iDist < $config{'itemsImportantAuto'}) {
			getImportantItems($ID);
		}

	} elsif ($switch eq "00A0") {
		$index = unpack("S1",substr($msg, 2, 2));
		$amount = unpack("S1",substr($msg, 4, 2));
		$ID = unpack("S1",substr($msg, 6, 2));
		$type = unpack("C1",substr($msg, 21, 1));
		$type_equip = unpack("S1",substr($msg, 19, 2));
#		makeCoords(\%test, substr($msg, 8, 3));
		$fail = unpack("C1",substr($msg, 22, 1));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", $ID);
		if ($fail == 0) {
			if ($invIndex eq "" || $itemSlots_lut{$ID} != 0) {
				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = $ID;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = $amount;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = $type;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} = ($itemSlots_lut{$ID} ne "") ? $itemSlots_lut{$ID} : $type_equip;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = unpack("C1",substr($msg, 8, 1));
				# Modify item name
				if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}) {
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'refined'} = unpack("C1", substr($msg, 10, 1));
					if (unpack("S1", substr($msg, 11, 2)) == 0x00FF) {
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'attribute'} = unpack("C1", substr($msg, 13, 1));
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'star'}      = unpack("C1", substr($msg, 14, 1)) / 0x05;
					} else {
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[0]   = unpack("S1", substr($msg, 11, 2));
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[1]   = unpack("S1", substr($msg, 13, 2));
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[2]   = unpack("S1", substr($msg, 15, 2));
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[3]   = unpack("S1", substr($msg, 17, 2));
					}
				}
			} else {
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} += $amount;
			}
			$display = ($items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}} ne "")
				? $items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}
				: "Unknown ".$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'};
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = $display;
			# Log for rare items get, resume attack mode
			if ($config{'itemsImportantAuto'} && $ai_seq[0] ne "storageAuto") {
				foreach (@ImportantItems) {
					if ($display =~ qr/$_/ && ($itemsPickup{lc($display)} eq "" || $itemsPickup{lc($display)} > 0)) {
						print "*** Get rare item $display ***\n";
						if ($ai_v{'ImportantItem'}{'attack_last'} ne "") {
							chatLog("i", "Got $display after hunting ".$ai_v{'ImportantItem'}{'attack_last'}."x".$defeatMonster{$ai_v{'ImportantItem'}{'attack_last'}}."\n");
						} else {
							chatLog("i", "Got $display\n");
						}
						# Rare item got list
						$rareItemGet{$display}++;
						if ($ai_v{'ImportantItem'}{'time'}) {
							$config{'attackAuto'} = $ai_v{'ImportantItem'}{'attackAuto'};
							undef %{$ai_v{'ImportantItem'}};
						}
						last;
					}
				}
			}
			# Modify item name
			modifingName(\%{$chars[$config{'char'}]{'inventory'}[$invIndex]});
			$display = $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'};
			print "Item added to inventory: $display ($invIndex) x $amount - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}}\n";
		} elsif ($fail == 6) {
			print "Can't loot item...wait...\n";
		}

	} elsif ($switch eq "00A1") {
		$ID = substr($msg, 2, 4);
		if (%{$items{$ID}}) {
			print "Item Disappeared: $items{$ID}{'name'} ($items{$ID}{'binID'})\n" if $config{'debug'};
			%{$items_old{$ID}} = %{$items{$ID}};
			$items_old{$ID}{'disappeared'} = 1;
			$items_old{$ID}{'gone_time'} = time;
			undef %{$items{$ID}};
			binRemove(\@itemsID, $ID);
		}

	} elsif ($switch eq "00A3" || $switch eq "01EE") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		my $psize = ($switch eq "00A3") ? 10 : 18;
		undef @{$chars[$config{'char'}]{'inventory'}} if ($ai_v{'temp'}{'refreshInventory'});
		undef $ai_v{'temp'}{'refreshInventory'};
		undef $invIndex;
		for ($i = 4; $i < $msg_size; $i+=$psize) {
			$index = unpack("S1", substr($msg, $i, 2));
			$ID = unpack("S1", substr($msg, $i + 2, 2));
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			if ($invIndex eq "") {
				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
			}
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = $ID;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = unpack("S1", substr($msg, $i + 6, 2));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
			# Phantom item solution
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = 0 if ($index eq $ai_v{'arrowIndex'});
			$display = ($items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}} ne "")
				? $items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}
				: "Unknown ".$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'};
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = $display;
			print "Inventory: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}}\n" if $config{'debug'};
		}
		# Use proper way to teleport
		useTeleport($ai_v{'teleQueue'}) if $ai_v{'teleQueue'};

	} elsif ($switch eq "00A4") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef @{$chars[$config{'char'}]{'inventory'}} if ($ai_v{'temp'}{'refreshInventory'});
		undef $ai_v{'temp'}{'refreshInventory'};
		undef $invIndex;
		for ($i = 4; $i < $msg_size; $i+=20) {
			$index = unpack("S1", substr($msg, $i, 2));
			$ID = unpack("S1", substr($msg, $i + 2, 2));
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			if ($invIndex eq "") {
				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
			}
			$type_equip = unpack("S1", substr($msg, $i+6, 2));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = $ID;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = 1;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} = ($itemSlots_lut{$ID} ne "") ? $itemSlots_lut{$ID} : $type_equip;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = unpack("S1", substr($msg, $i + 8, 2));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = "" if !($chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'});
			# Modify item name
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'refined'} = unpack("C1", substr($msg, $i + 11, 1));
			if (unpack("S1", substr($msg, $i + 12, 2)) == 0x00FF) {
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'attribute'} = unpack("C1", substr($msg, $i + 14, 1));
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'star'}      = unpack("C1", substr($msg, $i + 15, 1)) / 0x05;
			} else {
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[0] = unpack("S1", substr($msg, $i + 12, 2));
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[1] = unpack("S1", substr($msg, $i + 14, 2));
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[2] = unpack("S1", substr($msg, $i + 16, 2));
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[3] = unpack("S1", substr($msg, $i + 18, 2));
			}
			$display = ($items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}} ne "")
				? $items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}
				: "Unknown ".$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'};
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = $display;
			# Modify item name
			modifingName(\%{$chars[$config{'char'}]{'inventory'}[$invIndex]});
			print "Inventory: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}} - $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}}\n" if $config{'debug'};
		}

	} elsif ($switch eq "00A5" || $switch eq "01F0") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		my $psize = ($switch eq "00A5") ? 10 : 18;
		undef %storage;
		for ($i = 4; $i < $msg_size; $i+=$psize) {
			$index = unpack("S1", substr($msg, $i, 2));
			$ID = unpack("S1", substr($msg, $i + 2, 2));
			$storage{'inventory'}[$index]{'nameID'} = $ID;
			$storage{'inventory'}[$index]{'amount'} = unpack("S1", substr($msg, $i + 6, 2));
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "Unknown ".$ID;
			$storage{'inventory'}[$index]{'name'} = $display;
			print "Storage: $storage{'inventory'}[$index]{'name'} ($index)\n" if $config{'debug'};
		}
		print "Storage opened\n";

	} elsif ($switch eq "00A6") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
 		$msg = substr($msg, 0, 4).$newmsg;
		for ($i = 4; $i < $msg_size; $i+=20) {
			$index = unpack("C1", substr($msg, $i, 1));
			$ID = unpack("S1", substr($msg, $i + 2, 2));
			$type_equip = unpack("S1", substr($msg, $i+6, 2));
			$storage{'inventory'}[$index]{'nameID'} = $ID;
			$storage{'inventory'}[$index]{'amount'} = 1;
			$storage{'inventory'}[$index]{'type_equip'} = ($itemSlots_lut{$ID} ne "") ? $itemSlots_lut{$ID} : $type_equip;
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "Unknown ".$ID;
			$storage{'inventory'}[$index]{'name'} = $display;
			# Modify item name
			$storage{'inventory'}[$index]{'refined'} = unpack("C1", substr($msg, $i+11, 1));
			if (unpack("S1", substr($msg, $i+12, 2)) == 0x00FF) {
				$storage{'inventory'}[$index]{'attribute'} = unpack("C1", substr($msg, $i+14, 1));
				$storage{'inventory'}[$index]{'star'}      = unpack("C1", substr($msg, $i+15, 1)) / 0x05;
			} else {
				$storage{'inventory'}[$index]{'card'}[0]   = unpack("S1", substr($msg, $i+12, 2));
				$storage{'inventory'}[$index]{'card'}[1]   = unpack("S1", substr($msg, $i+14, 2));
				$storage{'inventory'}[$index]{'card'}[2]   = unpack("S1", substr($msg, $i+16, 2));
				$storage{'inventory'}[$index]{'card'}[3]   = unpack("S1", substr($msg, $i+18, 2));
			}
			modifingName(\%{$storage{'inventory'}[$index]});
			print "Storage Item: $storage{'inventory'}[$index]{'name'} ($index) x $storage{'inventory'}[$index]{'amount'}\n" if $config{'debug'};
		}

	} elsif ($switch eq "00A8") {
		$index = unpack("S1",substr($msg, 2, 2));
		$amount = unpack("C1",substr($msg, 6, 1));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		if ($amount == 0 && $chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} <= 2) {
			# Phantom item solution
			my $realIndex = findIndex_next($invIndex, \&findIndexString_lc, \@{$chars[$config{'char'}]{'inventory'}}, "name", $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'});
			if ($realIndex ne "") {
				print "Found phantom item $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex), trying $realIndex ...\n";
				chatLog("db", "Found phantom item $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex), trying $realIndex ...\n");
				undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
				sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$realIndex]{'index'}, $accountID);
			}
			print "You failed to used Item: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex)\n";
			chatLog("db", "You failed to used Item: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex)\n");
		} else {
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $amount;
			print "You used Item: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amount\n";
			if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
				undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
			}
		}

	} elsif ($switch eq "00AA") {
		$index = unpack("S1",substr($msg, 2, 2));
		$type = unpack("S1",substr($msg, 4, 2));
		$fail = unpack("C1",substr($msg, 6, 1));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		if ($fail == 0) {
			print "You can't put on $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex)\n";
		} else {
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = $type;
			print "You equip $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) - $equipTypes_lut{$type}\n";
		}

	} elsif ($switch eq "00AC") {
		$index = unpack("S1",substr($msg, 2, 2));
		$type = unpack("S1",substr($msg, 4, 2));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = "";
		# Phantom item solution
		undef $ai_v{'arrowIndex'} if ($index eq $ai_v{'arrowIndex'});
		print "You unequip $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) - $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}}\n";

	} elsif ($switch eq "00AF") {
		$index = unpack("S1",substr($msg, 2, 2));
		$amount = unpack("S1",substr($msg, 4, 2));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		print "Inventory Item Removed: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amount\n";
		$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $amount;
		if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
			undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
		}

	} elsif ($switch eq "00B0") {
		$type = unpack("S1",substr($msg, 2, 2));
		$val = unpack("l1",substr($msg, 4, 4));
		if ($type == 0) {
			print "Something1: $val\n" if $config{'debug'};
		} elsif ($type == 3) {
			print "Something2: $val\n" if $config{'debug'};
		} elsif ($type == 4) {
			$val = abs($val);
			$chars[$config{'char'}]{'skillBan'} = $val;
			print "You been banned for $val minutes\n";
			# Quit on chat and skill ban
			chatLog("s", "*** You have been banned for $val minutes ***\n");
			quitOnEvent("dcOnSkillBan");
		} elsif ($type == 5) {
			$chars[$config{'char'}]{'hp'} = $val;
			print "Hp: $val\n" if $config{'debug'};
		} elsif ($type == 6) {
			$chars[$config{'char'}]{'hp_max'} = $val;
			print "Max Hp: $val\n" if $config{'debug'};
		} elsif ($type == 7) {
			$chars[$config{'char'}]{'sp'} = $val;
			print "Sp: $val\n" if $config{'debug'};
		} elsif ($type == 8) {
			$chars[$config{'char'}]{'sp_max'} = $val;
			print "Max Sp: $val\n" if $config{'debug'};
		} elsif ($type == 9) {
			$chars[$config{'char'}]{'points_free'} = $val;
			print "Status Points: $val\n" if $config{'debug'};
		} elsif ($type == 11) {
			$chars[$config{'char'}]{'lv'} = $val;
			print "Level: $val\n" if $config{'debug'};
			# Auto lockMap change
			autolockMap();
		} elsif ($type == 12) {
			$chars[$config{'char'}]{'points_skill'} = $val;
			print "Skill Points: $val\n" if $config{'debug'};
		} elsif ($type == 24) {
			$chars[$config{'char'}]{'weight'} = int($val / 10);
			print "Weight: $chars[$config{'char'}]{'weight'}\n" if $config{'debug'};
			undef $ai_v{'temp'}{'refreshInventory'} if ($ai_v{'temp'}{'refreshInventory'} && $val == 0);
		} elsif ($type == 25) {
			$chars[$config{'char'}]{'weight_max'} = int($val / 10);
			print "Max Weight: $chars[$config{'char'}]{'weight_max'}\n" if $config{'debug'};
		} elsif ($type == 41) {
			$chars[$config{'char'}]{'attack'} = $val;
			print "Attack: $val\n" if $config{'debug'};
		} elsif ($type == 42) {
			$chars[$config{'char'}]{'attack_bonus'} = $val;
			print "Attack Bonus: $val\n" if $config{'debug'};
		} elsif ($type == 43) {
			$chars[$config{'char'}]{'attack_magic_min'} = $val;
			print "Magic Attack Min: $val\n" if $config{'debug'};
		} elsif ($type == 44) {
			$chars[$config{'char'}]{'attack_magic_max'} = $val;
			print "Magic Attack Max: $val\n" if $config{'debug'};
		} elsif ($type == 45) {
			$chars[$config{'char'}]{'def'} = $val;
			print "Defense: $val\n" if $config{'debug'};
		} elsif ($type == 46) {
			$chars[$config{'char'}]{'def_bonus'} = $val;
			print "Defense Bonus: $val\n" if $config{'debug'};
		} elsif ($type == 47) {
			$chars[$config{'char'}]{'def_magic'} = $val;
			print "Magic Defense: $val\n" if $config{'debug'};
		} elsif ($type == 48) {
			$chars[$config{'char'}]{'def_magic_bonus'} = $val;
			print "Magic Defense Bonus: $val\n" if $config{'debug'};
		} elsif ($type == 49) {
			$chars[$config{'char'}]{'hit'} = $val;
			print "Hit: $val\n" if $config{'debug'};
		} elsif ($type == 50) {
			$chars[$config{'char'}]{'flee'} = $val;
			print "Flee: $val\n" if $config{'debug'};
		} elsif ($type == 51) {
			$chars[$config{'char'}]{'flee_bonus'} = $val;
			print "Flee Bonus: $val\n" if $config{'debug'};
		} elsif ($type == 52) {
			$chars[$config{'char'}]{'critical'} = $val;
			print "Critical: $val\n" if $config{'debug'};
		} elsif ($type == 53) {
			$chars[$config{'char'}]{'attack_speed'} = 200 - $val/10;
			print "Attack Speed: $chars[$config{'char'}]{'attack_speed'}\n" if $config{'debug'};
		} elsif ($type == 55) {
			$chars[$config{'char'}]{'lv_job'} = $val;
			print "Job Level: $val\n" if $config{'debug'};
			# Auto lockMap change
			autolockMap();
		} elsif ($type == 124) {
			print "Something3: $val\n" if $config{'debug'};
		} else {
			print "Something: $val\n" if $config{'debug'};
		}
		# HP/SP info display
		if (($type == 5 || $type == 7) && $chars[$config{'char'}]{'hp_max'} && $chars[$config{'char'}]{'sp_max'}) {
			$ai_v{'hsinfo'} = "(HP:".int($chars[$config{'char'}]{'hp'}/$chars[$config{'char'}]{'hp_max'} * 100)."%/SP:"
					.int($chars[$config{'char'}]{'sp'}/$chars[$config{'char'}]{'sp_max'} * 100)."%) ";
		}

	} elsif ($switch eq "00B1") {
		$type = unpack("S1",substr($msg, 2, 2));
		$val = unpack("L1",substr($msg, 4, 4));
		if ($type == 1) {
			$chars[$config{'char'}]{'exp_last'} = $chars[$config{'char'}]{'exp'};
			$chars[$config{'char'}]{'exp'} = $val;
			print "Exp: $val\n" if $config{'debug'};
			# EXPs gained per hour
			if ($chars[$config{'char'}]{'exp_last'} ne "") {
				my $monsterBaseExp;
				if ($chars[$config{'char'}]{'exp_last'} > $chars[$config{'char'}]{'exp'} && $chars[$config{'char'}]{'exp_max_last'} ne $chars[$config{'char'}]{'exp_max'}) {
					$monsterBaseExp = $chars[$config{'char'}]{'exp_max_last'} - $chars[$config{'char'}]{'exp_last'} + $chars[$config{'char'}]{'exp'};
				} else {
					$monsterBaseExp = $chars[$config{'char'}]{'exp'} - $chars[$config{'char'}]{'exp_last'};
				}
				$totalBaseExp += $monsterBaseExp;
			}
		} elsif ($type == 2) {
			$chars[$config{'char'}]{'exp_job_last'} = $chars[$config{'char'}]{'exp_job'};
			$chars[$config{'char'}]{'exp_job'} = $val;
			print "Job Exp: $val\n" if $config{'debug'};
			# EXPs gained per hour
			if ($chars[$config{'char'}]{'exp_job_last'} ne "") {
				my $monsterJobExp;
				if ($chars[$config{'char'}]{'exp_job_last'} > $chars[$config{'char'}]{'exp_job'} && $chars[$config{'char'}]{'exp_job_max_last'} ne $chars[$config{'char'}]{'exp_job_max'}) {
					$monsterJobExp = $chars[$config{'char'}]{'exp_job_max_last'} - $chars[$config{'char'}]{'exp_job_last'} + $chars[$config{'char'}]{'exp_job'};
				} else {
					$monsterJobExp = $chars[$config{'char'}]{'exp_job'} - $chars[$config{'char'}]{'exp_job_last'};
				}
				$totalJobExp += $monsterJobExp;
			}
		} elsif ($type == 20) {
			if ($config{'recordSales'} && $shop{'opened'}) {
				chatLog("sl", "Zenny gained: " . ($val - $chars[$config{'char'}]{'zenny'}) . "\n");
			}
			$chars[$config{'char'}]{'zenny'} = $val;
			print "Zenny: $val\n" if $config{'debug'};
		} elsif ($type == 22) {
			$chars[$config{'char'}]{'exp_max_last'} = $chars[$config{'char'}]{'exp_max'};
			$chars[$config{'char'}]{'exp_max'} = $val;
			print "Required Exp: $val\n" if $config{'debug'};
		} elsif ($type == 23) {
			$chars[$config{'char'}]{'exp_job_max_last'} = $chars[$config{'char'}]{'exp_job_max'};
			$chars[$config{'char'}]{'exp_job_max'} = $val;
			print "Required Job Exp: $val\n" if $config{'debug'};
		}

	} elsif ($switch eq "00B4") {
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
		$msg = substr($msg, 0, 8).$newmsg;
		$ID = substr($msg, 4, 4);
		($talk) = substr($msg, 8, $msg_size - 8) =~ /([\s\S]*?)\000/;
		$talk{'ID'} = $ID;
		$talk{'nameID'} = unpack("L1", $ID);
		$talk{'msg'} = $talk;
		print "$npcs{$ID}{'name'} : $talk{'msg'}\n";

	} elsif ($switch eq "00B5") {
		$ID = substr($msg, 2, 4);
		print "$npcs{$ID}{'name'} : Type 'talk cont' to continue talking\n";

	} elsif ($switch eq "00B6") {
		$ID = substr($msg, 2, 4);
		undef %talk;
		print "$npcs{$ID}{'name'} : Done talking\n";

	} elsif ($switch eq "00B7") {
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
		$msg = substr($msg, 0, 8).$newmsg;
		$ID = substr($msg, 4, 4);
		($talk) = substr($msg, 8, $msg_size - 8) =~ /([\s\S]*?)\000/;
		if ($talk{'ID'} eq "") {
			$talk{'ID'} = $ID;
			$talk{'nameID'} = unpack("L1", $ID);
		}
		@preTalkResponses = split /:/, $talk;
		undef @{$talk{'responses'}};
		foreach (@preTalkResponses) {
			push @{$talk{'responses'}}, $_ if $_ ne "";
		}
		$talk{'responses'}[@{$talk{'responses'}}] = "Cancel Chat";
		print "$npcs{$ID}{'name'} : Type 'talk resp' and choose a response.\n";

	} elsif ($switch eq "00BC") {
		$type = unpack("S1",substr($msg, 2, 2));
		$val = unpack("C1",substr($msg, 5, 1));
		if ($val == 207) {
			print "Not enough stat points to add\n";
		} else {
			if ($type == 13) {
				$chars[$config{'char'}]{'str'} = $val;
				print "Strength: $val\n" if $config{'debug'};
			} elsif ($type == 14) {
				$chars[$config{'char'}]{'agi'} = $val;
				print "Agility: $val\n" if $config{'debug'};
			} elsif ($type == 15) {
				$chars[$config{'char'}]{'vit'} = $val;
				print "Vitality: $val\n" if $config{'debug'};
			} elsif ($type == 16) {
				$chars[$config{'char'}]{'int'} = $val;
				print "Intelligence: $val\n" if $config{'debug'};
			} elsif ($type == 17) {
				$chars[$config{'char'}]{'dex'} = $val;
				print "Dexterity: $val\n" if $config{'debug'};
			} elsif ($type == 18) {
				$chars[$config{'char'}]{'luk'} = $val;
				print "Luck: $val\n" if $config{'debug'};
			} else {
				print "Something: $val\n";
			}
		}

	} elsif ($switch eq "00BD") {
		$chars[$config{'char'}]{'points_free'} = unpack("S1", substr($msg, 2, 2));
		$chars[$config{'char'}]{'str'} = unpack("C1", substr($msg, 4, 1));
		$chars[$config{'char'}]{'points_str'} = unpack("C1", substr($msg, 5, 1));
		$chars[$config{'char'}]{'agi'} = unpack("C1", substr($msg, 6, 1));
		$chars[$config{'char'}]{'points_agi'} = unpack("C1", substr($msg, 7, 1));
		$chars[$config{'char'}]{'vit'} = unpack("C1", substr($msg, 8, 1));
		$chars[$config{'char'}]{'points_vit'} = unpack("C1", substr($msg, 9, 1));
		$chars[$config{'char'}]{'int'} = unpack("C1", substr($msg, 10, 1));
		$chars[$config{'char'}]{'points_int'} = unpack("C1", substr($msg, 11, 1));
		$chars[$config{'char'}]{'dex'} = unpack("C1", substr($msg, 12, 1));
		$chars[$config{'char'}]{'points_dex'} = unpack("C1", substr($msg, 13, 1));
		$chars[$config{'char'}]{'luk'} = unpack("C1", substr($msg, 14, 1));
		$chars[$config{'char'}]{'points_luk'} = unpack("C1", substr($msg, 15, 1));
		$chars[$config{'char'}]{'attack'} = unpack("S1", substr($msg, 16, 2));
		$chars[$config{'char'}]{'attack_bonus'} = unpack("S1", substr($msg, 18, 2));
		$chars[$config{'char'}]{'attack_magic_min'} = unpack("S1", substr($msg, 20, 2));
		$chars[$config{'char'}]{'attack_magic_max'} = unpack("S1", substr($msg, 22, 2));
		$chars[$config{'char'}]{'def'} = unpack("S1", substr($msg, 24, 2));
		$chars[$config{'char'}]{'def_bonus'} = unpack("S1", substr($msg, 26, 2));
		$chars[$config{'char'}]{'def_magic'} = unpack("S1", substr($msg, 28, 2));
		$chars[$config{'char'}]{'def_magic_bonus'} = unpack("S1", substr($msg, 30, 2));
		$chars[$config{'char'}]{'hit'} = unpack("S1", substr($msg, 32, 2));
		$chars[$config{'char'}]{'flee'} = unpack("S1", substr($msg, 34, 2));
		$chars[$config{'char'}]{'flee_bonus'} = unpack("S1", substr($msg, 36, 2));
		$chars[$config{'char'}]{'critical'} = unpack("S1", substr($msg, 38, 2));
		print	"Strength: $chars[$config{'char'}]{'str'} #$chars[$config{'char'}]{'points_str'}\n"
			,"Agility: $chars[$config{'char'}]{'agi'} #$chars[$config{'char'}]{'points_agi'}\n"
			,"Vitality: $chars[$config{'char'}]{'vit'} #$chars[$config{'char'}]{'points_vit'}\n"
			,"Intelligence: $chars[$config{'char'}]{'int'} #$chars[$config{'char'}]{'points_int'}\n"
			,"Dexterity: $chars[$config{'char'}]{'dex'} #$chars[$config{'char'}]{'points_dex'}\n"
			,"Luck: $chars[$config{'char'}]{'luk'} #$chars[$config{'char'}]{'points_luk'}\n"
			,"Attack: $chars[$config{'char'}]{'attack'}\n"
			,"Attack Bonus: $chars[$config{'char'}]{'attack_bonus'}\n"
			,"Magic Attack Min: $chars[$config{'char'}]{'attack_magic_min'}\n"
			,"Magic Attack Max: $chars[$config{'char'}]{'attack_magic_max'}\n"
			,"Defense: $chars[$config{'char'}]{'def'}\n"
			,"Defense Bonus: $chars[$config{'char'}]{'def_bonus'}\n"
			,"Magic Defense: $chars[$config{'char'}]{'def_magic'}\n"
			,"Magic Defense Bonus: $chars[$config{'char'}]{'def_magic_bonus'}\n"
			,"Hit: $chars[$config{'char'}]{'hit'}\n"
			,"Flee: $chars[$config{'char'}]{'flee'}\n"
			,"Flee Bonus: $chars[$config{'char'}]{'flee_bonus'}\n"
			,"Critical: $chars[$config{'char'}]{'critical'}\n"
			,"Status Points: $chars[$config{'char'}]{'points_free'}\n"
			if $config{'debug'};

	} elsif ($switch eq "00BE") {
		$type = unpack("S1",substr($msg, 2, 2));
		$val = unpack("C1",substr($msg, 4, 1));
		if ($type == 32) {
			$chars[$config{'char'}]{'points_str'} = $val;
			print "Points needed for Strength: $val\n" if $config{'debug'};
		} elsif ($type == 33) {
			$chars[$config{'char'}]{'points_agi'} = $val;
			print "Points needed for Agility: $val\n" if $config{'debug'};
		} elsif ($type == 34) {
			$chars[$config{'char'}]{'points_vit'} = $val;
			print "Points needed for Vitality: $val\n" if $config{'debug'};
		} elsif ($type == 35) {
			$chars[$config{'char'}]{'points_int'} = $val;
			print "Points needed for Intelligence: $val\n" if $config{'debug'};
		} elsif ($type == 36) {
			$chars[$config{'char'}]{'points_dex'} = $val;
			print "Points needed for Dexterity: $val\n" if $config{'debug'};
		} elsif ($type == 37) {
			$chars[$config{'char'}]{'points_luk'} = $val;
			print "Points needed for Luck: $val\n" if $config{'debug'};
		}

	} elsif ($switch eq "00C0") {
		$ID = substr($msg, 2, 4);
		$type = unpack("C*", substr($msg, 6, 1));
		if ($ID eq $accountID) {
			print "$chars[$config{'char'}]{'name'} : $emotions_lut{$type}\n";
			chatLog("e", "$chars[$config{'char'}]{'name'} : $emotions_lut{$type}\n") if ($config{'recordEmotion'});
		} elsif (%{$players{$ID}}) {
			my $info = "(Dt:".int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$ID}{'pos_to'}}))
					."/Jb:$jobs_lut{$players{$ID}{'jobID'}}/Lv:$players{$ID}{'level'}\[$players{$ID}{'binID'}])";
			print $info, "$players{$ID}{'name'} : $emotions_lut{$type}\n";
			# Auto reply emotion
			my $dPDist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$ID}{'pos_to'}});
			if ($dPDist < $config{'autoResponse'}) {
				my $resMsg = judgeRes('#e#'.$type, $players{$ID}{'name'});
				ai_action("Reply", "c ".$resMsg) if ($resMsg);
			}
			chatLog("e", $info."$players{$ID}{'name'} : $emotions_lut{$type}\n") if ($config{'recordEmotion'});
		}

	} elsif ($switch eq "00C2") {
		$users = unpack("L*", substr($msg, 2, 4));
		print "There are currently $users users online\n";

	} elsif ($switch eq "00C3") {
		# Character appearance changed

	} elsif ($switch eq "00C4") {
		$ID = substr($msg, 2, 4);
		undef %talk;
		$talk{'buyOrSell'} = 1;
		$talk{'ID'} = $ID;
		print "$npcs{$ID}{'name'} : Type 'store' to start buying, or type 'sell' to start selling\n";

	} elsif ($switch eq "00C6") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef @storeList;
		$storeList = 0;
		undef $talk{'buyOrSell'};
		for ($i = 4; $i < $msg_size; $i+=11) {
			$price = unpack("L1", substr($msg, $i, 4));
			$type = unpack("C1", substr($msg, $i + 8, 1));
			$ID = unpack("S1", substr($msg, $i + 9, 2));
			$storeList[$storeList]{'nameID'} = $ID;
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "Unknown ".$ID;
			$storeList[$storeList]{'name'} = $display;
			$storeList[$storeList]{'nameID'} = $ID;
			$storeList[$storeList]{'type'} = $type;
			$storeList[$storeList]{'price'} = $price;
			print "Item added to Store: $storeList[$storeList]{'name'} - $price z\n" if ($config{'debug'} >= 2);
			$storeList++;
		}
		print "$npcs{$talk{'ID'}}{'name'} : Check my store list by typing 'store'\n";

	} elsif ($switch eq "00C7") {
		#sell list, similar to buy list
		if (length($msg) > 4) {
			decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
			$msg = substr($msg, 0, 4).$newmsg;
		}
		undef $talk{'buyOrSell'};
		print "Ready to start selling items\n";

	} elsif ($switch eq "00CA") {
		# Finished to buy from NPC

	} elsif ($switch eq "00CB") {
		# Finished to sell to NPC

	} elsif ($switch eq "00D1") {
		$type = unpack("C1", substr($msg, 2, 1));
		$error = unpack("C1", substr($msg, 3, 1));
		if ($type == 0) {
			print "Player ignored\n";
		} elsif ($type == 1) {
			if ($error == 0) {
				print "Player unignored\n";
			}
		}

	} elsif ($switch eq "00D2") {
		$type = unpack("C1", substr($msg, 2, 1));
		$error = unpack("C1", substr($msg, 3, 1));
		if ($type == 0) {
			print "All Players ignored\n";
		} elsif ($type == 1) {
			if ($error == 0) {
				print "All players unignored\n";
			}
		}

	} elsif ($switch eq "00D6") {
		$currentChatRoom = "new";
		%{$chatRooms{'new'}} = %createdChatRoom;
		binAdd(\@chatRoomsID, "new");
		binAdd(\@currentChatRoomUsers, $chars[$config{'char'}]{'name'});
		print "Chat Room Created\n";

	} elsif ($switch eq "00D7") {
		decrypt(\$newmsg, substr($msg, 17, length($msg)-17));
		$msg = substr($msg, 0, 17).$newmsg;
		$ID = substr($msg,8,4);
		if (!%{$chatRooms{$ID}}) {
			binAdd(\@chatRoomsID, $ID);
		}
		$chatRooms{$ID}{'title'} = substr($msg,17,$msg_size - 17);
		$chatRooms{$ID}{'ownerID'} = substr($msg,4,4);
		$chatRooms{$ID}{'limit'} = unpack("S1",substr($msg,12,2));
		$chatRooms{$ID}{'public'} = unpack("C1",substr($msg,16,1));
		$chatRooms{$ID}{'num_users'} = unpack("S1",substr($msg,14,2));
		# Record chat room titles
		chatLog("cr", "$players{$chatRooms{$ID}{'ownerID'}}{'name'} : $chatRooms{$ID}{'title'}\n") if ($config{'recordChatRoom'} && %{$players{$chatRooms{$ID}{'ownerID'}}} && $players{$chatRooms{$ID}{'ownerID'}}{'name'} ne "Unknown");
		# Avoid GM
		avoidGM($chatRooms{$ID}{'ownerID'}, $players{$chatRooms{$ID}{'ownerID'}}{'name'}, 1);

	} elsif ($switch eq "00D8") {
		$ID = substr($msg,2,4);
		binRemove(\@chatRoomsID, $ID);
		undef %{$chatRooms{$ID}};

	} elsif ($switch eq "00DA") {
		$type = unpack("C1",substr($msg, 2, 1));
		if ($type == 1) {
			print "Can't join Chat Room - Incorrect Password\n";
		} elsif ($type == 2) {
			print "Can't join Chat Room - You're banned\n";
		}

	} elsif ($switch eq "00DB") {
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
		$msg = substr($msg, 0, 8).$newmsg;
		$ID = substr($msg,4,4);
		$currentChatRoom = $ID;
		$chatRooms{$currentChatRoom}{'num_users'} = 0;
		for ($i = 8; $i < $msg_size; $i+=28) {
			$type = unpack("C1",substr($msg,$i,1));
			($chatUser) = substr($msg,$i + 4,24) =~ /([\s\S]*?)\000/;
			if ($chatRooms{$currentChatRoom}{'users'}{$chatUser} eq "") {
				binAdd(\@currentChatRoomUsers, $chatUser);
				if ($type == 0) {
					$chatRooms{$currentChatRoom}{'users'}{$chatUser} = 2;
				} else {
					$chatRooms{$currentChatRoom}{'users'}{$chatUser} = 1;
				}
				$chatRooms{$currentChatRoom}{'num_users'}++;
			}
		}
		print qq~You have joined the Chat Room "$chatRooms{$currentChatRoom}{'title'}"\n~;

	} elsif ($switch eq "00DC") {
		if ($currentChatRoom ne "") {
			$num_users = unpack("S1", substr($msg,2,2));
			($joinedUser) = substr($msg,4,24) =~ /([\s\S]*?)\000/;
			binAdd(\@currentChatRoomUsers, $joinedUser);
			$chatRooms{$currentChatRoom}{'users'}{$joinedUser} = 1;
			$chatRooms{$currentChatRoom}{'num_users'} = $num_users;
			print "$joinedUser has joined the Chat Room\n";
		}

	} elsif ($switch eq "00DD") {
		$num_users = unpack("S1", substr($msg,2,2));
		($leaveUser) = substr($msg,4,24) =~ /([\s\S]*?)\000/;
		$chatRooms{$currentChatRoom}{'users'}{$leaveUser} = "";
		binRemove(\@currentChatRoomUsers, $leaveUser);
		$chatRooms{$currentChatRoom}{'num_users'} = $num_users;
		if ($leaveUser eq $chars[$config{'char'}]{'name'}) {
			binRemove(\@chatRoomsID, $currentChatRoom);
			undef %{$chatRooms{$currentChatRoom}};
			undef @currentChatRoomUsers;
			$currentChatRoom = "";
			print "You left the Chat Room\n";
		} else {
			print "$leaveUser has left the Chat Room\n";
		}

	} elsif ($switch eq "00DF") {
		decrypt(\$newmsg, substr($msg, 17, length($msg)-17));
		$msg = substr($msg, 0, 17).$newmsg;
		$ID = substr($msg,8,4);
		$ownerID = substr($msg,4,4);
		if ($ownerID eq $accountID) {
			$chatRooms{'new'}{'title'} = substr($msg,17,$msg_size - 17);
			$chatRooms{'new'}{'ownerID'} = $ownerID;
			$chatRooms{'new'}{'limit'} = unpack("S1",substr($msg,12,2));
			$chatRooms{'new'}{'public'} = unpack("C1",substr($msg,16,1));
			$chatRooms{'new'}{'num_users'} = unpack("S1",substr($msg,14,2));
		} else {
			$chatRooms{$ID}{'title'} = substr($msg,17,$msg_size - 17);
			$chatRooms{$ID}{'ownerID'} = $ownerID;
			$chatRooms{$ID}{'limit'} = unpack("S1",substr($msg,12,2));
			$chatRooms{$ID}{'public'} = unpack("C1",substr($msg,16,1));
			$chatRooms{$ID}{'num_users'} = unpack("S1",substr($msg,14,2));
		}
		print "Chat Room Properties Modified\n";

	} elsif ($switch eq "00E1") {
		$type = unpack("C1",substr($msg, 2, 1));
		($chatUser) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
		if ($type == 0) {
			if ($chatUser eq $chars[$config{'char'}]{'name'}) {
				$chatRooms{$currentChatRoom}{'ownerID'} = $accountID;
			} else {
				$key = findKeyString(\%players, "name", $chatUser);
				$chatRooms{$currentChatRoom}{'ownerID'} = $key;
			}
			$chatRooms{$currentChatRoom}{'users'}{$chatUser} = 2;
		} else {
			$chatRooms{$currentChatRoom}{'users'}{$chatUser} = 1;
		}

	} elsif ($switch eq "00E5" || $switch eq "01F4") {
		($dealUser) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		$incomingDeal{'name'} = $dealUser;
		$timeout{'ai_dealAutoCancel'}{'time'} = time;
		print "$dealUser Requests a Deal\n";

	} elsif ($switch eq "00E7" || $switch eq "01F5") {
		$type = unpack("C1", substr($msg, 2, 1));

		if ($type == 3) {
			if (%incomingDeal) {
				$currentDeal{'name'} = $incomingDeal{'name'};
			} else {
				$currentDeal{'ID'} = $outgoingDeal{'ID'};
				$currentDeal{'name'} = $players{$outgoingDeal{'ID'}}{'name'};
			}
			print "Engaged Deal with $currentDeal{'name'}\n";
		}
		undef %outgoingDeal;
		undef %incomingDeal;

	} elsif ($switch eq "00E9") {
		$amount = unpack("L*", substr($msg, 2,4));
		$ID = unpack("S*", substr($msg, 6,2));
		if ($ID > 0) {
			$currentDeal{'other'}{$ID}{'amount'} += $amount;
			$display = ($items_lut{$ID} ne "")
					? $items_lut{$ID}
					: "Unknown ".$ID;
			$currentDeal{'other'}{$ID}{'name'} = $display;
			print "$currentDeal{'name'} added Item to Deal: $currentDeal{'other'}{$ID}{'name'} x $amount\n";
		} elsif ($amount > 0) {
			$currentDeal{'other_zenny'} += $amount;
			print "$currentDeal{'name'} added $amount z to Deal\n";
		}

	} elsif ($switch eq "00EA") {
		$index = unpack("S1", substr($msg, 2, 2));
		undef $invIndex;
		if ($index > 0) {
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			$currentDeal{'you'}{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}{'amount'} += $currentDeal{'lastItemAmount'};
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $currentDeal{'lastItemAmount'};
			print "You added Item to Deal: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} x $currentDeal{'lastItemAmount'}\n";
			if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
				undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
			}
		} elsif ($currentDeal{'you_zenny'} > 0) {
			$chars[$config{'char'}]{'zenny'} -= $currentDeal{'you_zenny'};
		}

	} elsif ($switch eq "00EC") {
		$type = unpack("C1", substr($msg, 2, 1));
		if ($type == 1) {
			$currentDeal{'other_finalize'} = 1;
			print "$currentDeal{'name'} finalized the Deal\n";
		} else {
			$currentDeal{'you_finalize'} = 1;
			print "You finalized the Deal\n";
		}

	} elsif ($switch eq "00EE") {
		undef %incomingDeal;
		undef %outgoingDeal;
		undef %currentDeal;
		print "Deal Cancelled\n";

	} elsif ($switch eq "00F0") {
		print "Deal Complete\n";
		undef %currentDeal;

	} elsif ($switch eq "00F2") {
		$storage{'items'} = unpack("S1", substr($msg, 2, 2));
		$storage{'items_max'} = unpack("S1", substr($msg, 4, 2));

	} elsif ($switch eq "00F4") {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));
		$ID = unpack("S1", substr($msg, 8, 2));
		if (%{$storage{'inventory'}[$index]}) {
			$storage{'inventory'}[$index]{'amount'} += $amount;
		} else {
			$storage{'inventory'}[$index]{'nameID'} = $ID;
			$storage{'inventory'}[$index]{'amount'} = $amount;
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "Unknown ".$ID;
			$storage{'inventory'}[$index]{'name'} = $display;
			# Modify item name
			$storage{'inventory'}[$index]{'refined'} = unpack("C1", substr($msg, 10, 1));
			if (unpack("S1", substr($msg, 11, 2)) == 0x00FF) {
				$storage{'inventory'}[$index]{'attribute'} = unpack("C1", substr($msg, 13, 1));
				$storage{'inventory'}[$index]{'star'}      = unpack("C1", substr($msg, 14, 1)) / 0x05;
			} else {
				$storage{'inventory'}[$index]{'card'}[0]   = unpack("S1", substr($msg, 11, 2));
				$storage{'inventory'}[$index]{'card'}[1]   = unpack("S1", substr($msg, 13, 2));
				$storage{'inventory'}[$index]{'card'}[2]   = unpack("S1", substr($msg, 15, 2));
				$storage{'inventory'}[$index]{'card'}[3]   = unpack("S1", substr($msg, 17, 2));
			}
			modifingName(\%{$storage{'inventory'}[$index]});
		}
		print "Storage Item Added: $storage{'inventory'}[$index]{'name'} ($index) x $amount\n";

	} elsif ($switch eq "00F6") {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));
		$storage{'inventory'}[$index]{'amount'} -= $amount;
		print "Storage Item Removed: $storage{'inventory'}[$index]{'name'} ($index) x $amount\n";
		if ($storage{'inventory'}[$index]{'amount'} <= 0) {
			undef %{$storage{'inventory'}[$index]};
		}

	} elsif ($switch eq "00F8") {
		print "Storage Closed\n";
		# Record storage contents
		if ($config{'recordStorage'}) {
			open(STORAGELOG, modifingPath("> logs/StorLog.txt")) if ($config{'recordStorage'} eq "1");
			open(STORAGELOG, modifingPath(">> logs/StorLog.txt")) if ($config{'recordStorage'} eq "2");
			select(STORAGELOG);
			print "*** [", getFormattedDate(int(time)), "] ***\n";
			print "*** [$servers[$config{'server'}]{'name'} - $chars[$config{'char'}]{'name'}] ***\n";
			close(STORAGELOG);
			logCommand(">> logs/StorLog.txt","storage");
		}

	} elsif ($switch eq "00FA") {
		$type = unpack("C1", substr($msg, 2, 1));
		if ($type == 1) {
			print "Can't organize party - party name exists\n";
		}

	} elsif ($switch eq "00FB") {
		decrypt(\$newmsg, substr($msg, 28, length($msg)-28));
		$msg = substr($msg, 0, 28).$newmsg;
		($chars[$config{'char'}]{'party'}{'name'}) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
		for ($i = 28; $i < $msg_size;$i+=46) {
			$ID = substr($msg, $i, 4);
			$num = unpack("C1",substr($msg, $i + 44, 1));
			if (!%{$chars[$config{'char'}]{'party'}{'users'}{$ID}}) {
				binAdd(\@partyUsersID, $ID);
			}
			($chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'}) = substr($msg, $i + 4, 24) =~ /([\s\S]*?)\000/;
			($chars[$config{'char'}]{'party'}{'users'}{$ID}{'map'}) = substr($msg, $i + 28, 16) =~ /([\s\S]*?)\000/;
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = !(unpack("C1",substr($msg, $i + 45, 1)));
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'admin'} = 1 if ($num == 0);
		}
		sendPartyShareEXP(\$remote_socket, 1) if ($config{'partyAutoShare'} && %{$chars[$config{'char'}]{'party'}});

	} elsif ($switch eq "00FD") {
		($name) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		$type = unpack("C1", substr($msg, 26, 1));
		if ($type == 0) {
			print "Join request failed: $name is already in a party\n";
		} elsif ($type == 1) {
			print "Join request failed: $name denied request\n";
		} elsif ($type == 2) {
			print "$name accepted your request\n";
		}

	} elsif ($switch eq "00FE") {
		$ID = substr($msg, 2, 4);
		($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
		print "Incoming Request to join party '$name'\n";
		$incomingParty{'ID'} = $ID;
		$timeout{'ai_partyAutoDeny'}{'time'} = time;

	} elsif ($switch eq "0100") {
		# Party related

	} elsif ($switch eq "0101") {
		$type = unpack("C1", substr($msg, 2, 1));
		if ($type == 0) {
			print "Party EXP set to Individual Take\n";
		} elsif ($type == 1) {
			print "Party EXP set to Even Share\n";
		} else {
			print "Error setting party option\n";
		}

	} elsif ($switch eq "0104") {
		$ID = substr($msg, 2, 4);
		$x = unpack("S1", substr($msg,10, 2));
		$y = unpack("S1", substr($msg,12, 2));
		$type = unpack("C1",substr($msg, 14, 1));
		($name) = substr($msg, 15, 24) =~ /([\s\S]*?)\000/;
		($partyUser) = substr($msg, 39, 24) =~ /([\s\S]*?)\000/;
		($map) = substr($msg, 63, 16) =~ /([\s\S]*?)\000/;
		if (!%{$chars[$config{'char'}]{'party'}{'users'}{$ID}}) {
			binAdd(\@partyUsersID, $ID);
			if ($ID eq $accountID) {
				print "You joined party '$name'\n";
			} else {
				print "$partyUser joined your party '$name'\n";
			}
		}
		if ($type == 0) {
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 1;
		} elsif ($type == 1) {
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 0;
		}
		$chars[$config{'char'}]{'party'}{'name'} = $name;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'x'} = $x;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'y'} = $y;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'map'} = $map;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'} = $partyUser;


	} elsif ($switch eq "0105") {
		$ID = substr($msg, 2, 4);
		($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
		undef %{$chars[$config{'char'}]{'party'}{'users'}{$ID}};
		binRemove(\@partyUsersID, $ID);
		if ($ID eq $accountID) {
			print "You left the party\n";
			undef %{$chars[$config{'char'}]{'party'}};
			$chars[$config{'char'}]{'party'} = "";
			undef @partyUsersID;
		} else {
			print "$name left the party\n";
		}

	} elsif ($switch eq "0106") {
		$ID = substr($msg, 2, 4);
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp'} = unpack("S1", substr($msg, 6, 2));
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp_max'} = unpack("S1", substr($msg, 8, 2));

	} elsif ($switch eq "0107") {
		$ID = substr($msg, 2, 4);
		$x = unpack("S1", substr($msg,6, 2));
		$y = unpack("S1", substr($msg,8, 2));
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'x'} = $x;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'y'} = $y;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 1;
		print "Party member location: $chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'} - $x, $y\n" if ($config{'debug'} >= 2);

	} elsif ($switch eq "0109") {
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
		$msg = substr($msg, 0, 8).$newmsg;
		$chat = substr($msg, 8, $msg_size - 8);
		$chat = recallCheck($chat) if ($recallCommand ne "");
		($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
		chatLog("p", $chat."\n");
		$ai_cmdQue[$ai_cmdQue]{'type'} = "p";
		$ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser;
		$ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg;
		$ai_cmdQue[$ai_cmdQue]{'time'} = time;
		$ai_cmdQue++;
		print "$chat\n";

	# wooooo MVP info
	} elsif ($switch eq "010A") {
  		$ID = unpack("S1", substr($msg, 2, 2));
  		print "You get MVP Item : $items_lut{$ID}\n";

   	} elsif ($switch eq "010B") {
      		$val = unpack("S1",substr($msg, 2, 2));
      		print "You're MVP!!! Special exp gained: $val\n";

   	} elsif ($switch eq "010C") {
	###

	} elsif ($switch eq "010E") {
		$ID = unpack("S1",substr($msg, 2, 2));
		$lv = unpack("S1",substr($msg, 4, 2));
		$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$ID})}}{'lv'} = $lv;
		print "Skill $skillsID_lut{$ID}: $lv\n" if $config{'debug'};

	} elsif ($switch eq "010F") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef %{$chars[$config{'char'}]{'skills'}};
		undef @skillsID;
		for ($i = 4;$i < $msg_size;$i+=37) {
			$ID = unpack("S1", substr($msg, $i, 2));
			($name) = substr($msg, $i + 12, 24) =~ /([\s\S]*?)\000/;
			if (!$name) {
				$name = $skills_rlut{lc($skillsID_lut{$ID})};
			}
			$chars[$config{'char'}]{'skills'}{$name}{'ID'} = $ID;
			if (!$chars[$config{'char'}]{'skills'}{$name}{'lv'}) {
				$chars[$config{'char'}]{'skills'}{$name}{'lv'} = unpack("S1", substr($msg, $i + 6, 2));
			}
			$skillsID_lut{$ID} = $skills_lut{$name};
			binAdd(\@skillsID, $name);
		}

	} elsif ($switch eq "0110") {
		# Failed to use skill
		$skillID = unpack("S1", substr($msg, 2, 2));
#		$basicType = unpack("S1", substr($msg, 4, 2));
		$fail = unpack("C1", substr($msg, 8, 1));
#		$type = unpack("C1", substr($msg, 9, 1));

		if (!$fail) {
			aiRemove("skill_use");
			print "You failed to use $skillsID_lut{$skillID}\n";
		}
		#Parse this: warp portal

	} elsif ($switch eq "0111") {
		# Skill list - 1 slot only

	} elsif ($switch eq "0114" || $switch eq "01DE") {
		$skillID = unpack("S1",substr($msg, 2, 2));
		$sourceID = substr($msg, 4, 4);
		$targetID = substr($msg, 8, 4);
		if ($switch eq "0114") {
			$damage = unpack("S1",substr($msg, 24, 2));
			$level = unpack("S1",substr($msg, 26, 2));
		} else {
			$damage = unpack("L1",substr($msg, 24, 4));
			$damage = 35536 if ($damage == 4294937296);
			$level = unpack("S1",substr($msg, 28, 2));
		}
		# Detect kill steal
		my $ai_index = binFind(\@ai_seq, "attack");
		undef $sourceDisplay;
		undef $targetDisplay;
		undef $extra;
		if (%{$spells{$sourceID}}) {
			$sourceID = $spells{$sourceID}{'sourceID'}
		}

		updateDamageTables($sourceID, $targetID, $damage) if ($damage != 35536);
		if (%{$monsters{$sourceID}}) {
			$sourceDisplay = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) uses";
			# Detect kill steal
			if (%{$players{$targetID}}) {
				JudgeAttackSameTarget($sourceID) if ($config{'useDetection'} && $ai_index ne "" && $ai_seq_args[$ai_index]{'ID'} eq $targetID);
			}
		} elsif (%{$players{$sourceID}}) {
			$sourceDisplay = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) uses";
		} elsif ($sourceID eq $accountID) {
			# HP/SP info display
			$sourceDisplay = $ai_v{'hsinfo'}."You use";
			$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
			undef $chars[$config{'char'}]{'time_cast'};
			undef $ai_v{'temp'}{'castWait'};
		} else {
			$sourceDisplay = "Unknown uses";
		}

		if (%{$monsters{$targetID}}) {
			$targetDisplay = "$monsters{$targetID}{'name'} ($monsters{$targetID}{'binID'})";
			if ($sourceID eq $accountID) {
				$monsters{$targetID}{'castOnByYou'}++;
			} elsif (%{$players{$sourceID}}) {
				$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
				# Detect kill steal
				JudgeAttackSameTarget($targetID) if ($config{'useDetection'} && $ai_index ne "" && $ai_seq_args[$ai_index]{'ID'} eq $targetID);
			}
		} elsif (%{$players{$targetID}}) {
			$targetDisplay = "$players{$targetID}{'name'} ($players{$targetID}{'binID'})";
		} elsif ($targetID eq $accountID) {
			if ($sourceID eq $accountID) {
				$targetDisplay = "yourself";
			} else {
				$targetDisplay = "you";
			}
		} else {
			$targetDisplay = "unknown";
		}
		if ($damage != 35536) {
			if ($level_real ne "") {
				$level = $level_real;
			}
			if ($level == 65535) {
				$level = "on";
			} else {
				$level = "(lvl $level) on";
			}
			if ($sourceID eq $accountID) {
				print "$sourceDisplay $skillsID_lut{$skillID} $level $targetDisplay$extra - Dmg: $damage (Total: $monsters{$targetID}{'dmgTo'})\n";
			} else {
				print "$sourceDisplay $skillsID_lut{$skillID} $level $targetDisplay$extra - Dmg: $damage\n";
			}
		} else {
			$level_real = $level;
			print "$sourceDisplay $skillsID_lut{$skillID} (lvl $level)\n";
		}

	} elsif ($switch eq "0115") {
		$skillID = unpack("S1",substr($msg, 2, 2));
		$sourceID = substr($msg, 4, 4);
		$targetID = substr($msg, 8, 4);
		$coords{'x'} = unpack("S1", substr($msg, 24, 2));
		$coords{'y'} = unpack("S1", substr($msg, 26, 2));
		$damage = unpack("S1",substr($msg, 28, 2));
		$level = unpack("S1",substr($msg, 30, 2));
		# Detect kill steal
		my $ai_index = binFind(\@ai_seq, "attack");
		undef $sourceDisplay;
		undef $targetDisplay;
		undef $extra;
		if (%{$spells{$sourceID}}) {
			$sourceID = $spells{$sourceID}{'sourceID'}
		}

		updateDamageTables($sourceID, $targetID, $damage) if ($damage != 35536);
		if (%{$monsters{$sourceID}}) {
			$sourceDisplay = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) uses";
			# Detect kill steal
			if (%{$players{$targetID}}) {
				JudgeAttackSameTarget($sourceID) if ($config{'useDetection'} && $ai_index ne "" && $ai_seq_args[$ai_index]{'ID'} eq $targetID);
			}
		} elsif (%{$players{$sourceID}}) {
			$sourceDisplay = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) uses";
		} elsif ($sourceID eq $accountID) {
			# HP/SP info display
			$sourceDisplay = $ai_v{'hsinfo'}."You use";
			$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
			undef $chars[$config{'char'}]{'time_cast'};
			undef $ai_v{'temp'}{'castWait'};
		} else {
			$sourceDisplay = "Unknown uses";
		}

		if (%{$monsters{$targetID}}) {
			$targetDisplay = "$monsters{$targetID}{'name'} ($monsters{$targetID}{'binID'})";
			if ($sourceID eq $accountID) {
				$monsters{$targetID}{'castOnByYou'}++;
			} elsif (%{$players{$sourceID}}) {
				$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
				# Detect kill steal
				JudgeAttackSameTarget($targetID) if ($config{'useDetection'} && $ai_index ne "" && $ai_seq_args[$ai_index]{'ID'} eq $targetID);
			}
			%{$monsters{$ID}{'pos'}} = %coords;
			%{$monsters{$ID}{'pos_to'}} = %coords;
		} elsif (%{$players{$targetID}}) {
			$targetDisplay = "$players{$targetID}{'name'} ($players{$targetID}{'binID'})";
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
		} elsif ($targetID eq $accountID) {
			if ($sourceID eq $accountID) {
				$targetDisplay = "yourself";
			} else {
				$targetDisplay = "you";
			}
			%{$chars[$config{'char'}]{'pos'}} = %coords;
			%{$chars[$config{'char'}]{'pos_to'}} = %coords;
		} else {
			$targetDisplay = "unknown";
		}
		if ($damage != 35536) {
			if ($level_real ne "") {
				$level = $level_real;
			}
			if ($level == 65535) {
				$level = "on";
			} else {
				$level = "(lvl $level) on";
			}
			if ($sourceID eq $accountID) {
				print "$sourceDisplay $skillsID_lut{$skillID} $level $targetDisplay$extra - Dmg: $damage (Total: $monsters{$targetID}{'dmgTo'})\n";
			} else {
				print "$sourceDisplay $skillsID_lut{$skillID} $level $targetDisplay$extra - Dmg: $damage\n";
			}
		} else {
			$level_real = $level;
			print "$sourceDisplay $skillsID_lut{$skillID} (lvl $level)\n";
		}

	} elsif ($switch eq "0117") {
		$skillID = unpack("S1",substr($msg, 2, 2));
		$sourceID = substr($msg, 4, 4);
		$lv = unpack("S1",substr($msg, 8, 2));
		$x = unpack("S1",substr($msg, 10, 2));
		$y = unpack("S1",substr($msg, 12, 2));

		undef $sourceDisplay;
		if (%{$monsters{$sourceID}}) {
			$sourceDisplay = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) uses";
		} elsif (%{$players{$sourceID}}) {
			$sourceDisplay = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) uses";
		} elsif ($sourceID eq $accountID) {
			# HP/SP info display
			$sourceDisplay = $ai_v{'hsinfo'}."You use";
			$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
			undef $chars[$config{'char'}]{'time_cast'};
			undef $ai_v{'temp'}{'castWait'};
		} else {
			$sourceDisplay = "Unknown uses";
		}
		print "$sourceDisplay $skillsID_lut{$skillID} on location ($x, $y)\n";

	} elsif ($switch eq "0119") {
		# Character status
		$ID = substr($msg, 2, 4);
		$param1 = unpack("S1", substr($msg, 6, 2));
		$param2 = unpack("S1", substr($msg, 8, 2));
		$param3 = unpack("S1", substr($msg, 10, 2));
		my $ai_index = binFind(\@ai_seq, "attack");

		if ($ID eq $accountID) {
			$chars[$config{'char'}]{'param1'} = $param1;
			$chars[$config{'char'}]{'param2'} = $param2;
			$chars[$config{'char'}]{'param3'} = $param3;
			# HP/SP info display
			$targetDisplay = $ai_v{'hsinfo'};
		} elsif (%{$players{$ID}}) {
			$players{$ID}{'param1'} = $param1;
			$players{$ID}{'param2'} = $param2;
			$players{$ID}{'param3'} = $param3;
			$targetDisplay = "$players{$ID}{'name'} ($players{$ID}{'binID'})";
		} elsif (%{$monsters{$ID}}) {
			$monsters{$ID}{'param1'} = $param1;
			$monsters{$ID}{'param2'} = $param2;
			$monsters{$ID}{'param3'} = $param3;
			$targetDisplay = "$monsters{$ID}{'name'} ($monsters{$ID}{'binID'})";
		} else {
			$targetDisplay = "Unknown ".getHex($ID);
			# Avoid GM
			avoidGM($ID, "Unknown", 0) if ($config{'dcOnGM_paranoia'} || $param3 == 64);
		}
		if ($ai_index ne "" && $ID eq $ai_seq_args[$ai_index]{'ID'}
			|| $ID eq $accountID || $config{'debug'}) {
			print $targetDisplay, qq~Param1: $messages_lut{$switch."_A"}{$param1}\n~ if $param1;
			foreach (keys %{$messages_lut{'0119_B'}}) {
				print $targetDisplay, qq~Param2: $messages_lut{$switch."_B"}{$_}\n~ if ($_ & $param2);
			}
			foreach (keys %{$messages_lut{'0119_C'}}) {
				print $targetDisplay, qq~Param3: $messages_lut{$switch."_C"}{$_}\n~ if ($_ & $param3);
			}
		}

	} elsif ($switch eq "011A") {
		$skillID = unpack("S1",substr($msg, 2, 2));
		$targetID = substr($msg, 6, 4);
		$sourceID = substr($msg, 10, 4);
		$amount = unpack("S1",substr($msg, 4, 2));
		undef $sourceDisplay;
		undef $targetDisplay;
		undef $extra;
		if (%{$spells{$sourceID}}) {
			$sourceID = $spells{$sourceID}{'sourceID'}
		}
		if (%{$monsters{$sourceID}}) {
			$sourceDisplay = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) uses";
		} elsif (%{$players{$sourceID}}) {
			$sourceDisplay = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) uses";
		} elsif ($sourceID eq $accountID) {
			# HP/SP info display
			$sourceDisplay = $ai_v{'hsinfo'}."You use";
			$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
			undef $chars[$config{'char'}]{'time_cast'};
			undef $ai_v{'temp'}{'castWait'};
		} else {
			$sourceDisplay = "Unknown uses";
		}
		if (%{$monsters{$targetID}}) {
			$targetDisplay = "$monsters{$targetID}{'name'} ($monsters{$targetID}{'binID'})";
			if ($sourceID eq $accountID) {
				$monsters{$targetID}{'castOnByYou'}++;
			} elsif (%{$players{$sourceID}}) {
				$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
			}
		} elsif (%{$players{$targetID}}) {
			$targetDisplay = "$players{$targetID}{'name'} ($players{$targetID}{'binID'})";
		} elsif ($targetID eq $accountID) {
			if ($sourceID eq $accountID) {
				$targetDisplay = "yourself";
			} else {
				$targetDisplay = "you";
			}
		} else {
			$targetDisplay = "unknown";
		}
		if ($skillID == 28 || $skillID == 335) {
			$extra = ": $amount hp gained";
		} elsif ($skillID == 334) {
			$extra = ": $amount sp gained";
		} elsif ($amount != 65535) {
			$extra = ": Lv $amount";
		}
		print "$sourceDisplay $skillsID_lut{$skillID} on $targetDisplay$extra\n";
		# Heal to you
		if ($config{'useThanks'} && binFind(\@ai_seq, "actionAuto") eq "" && $targetDisplay eq "you" && existsInList($config{'useThanks_skills'}, $skillsID_lut{$skillID})) {
			if ($config{'useThanks'} eq "1") {
				ai_action("Reply", "c ".$config{'thanksMessage'});
			} else {
				ai_action("Emotion", "e ".$config{'thanksEmotion'});
			}
		}

	} elsif ($switch eq "011C") {
		# Location list of teleport / warp

	} elsif ($switch eq "011E") {
		$fail = unpack("C1", substr($msg, 2, 1));
		if ($fail) {
			print "Memo Failed\n";
		} else {
			print "Memo Succeeded\n";
		}

	} elsif ($switch eq "011F" || $switch eq "01C9") {
		#area effect spell
		$ID = substr($msg, 2, 4);
		$SourceID = substr($msg, 6, 4);
		$x = unpack("S1",substr($msg, 10, 2));
		$y = unpack("S1",substr($msg, 12, 2));
		$type =  unpack("C1",substr($msg, 14, 1));
		$spells{$ID}{'sourceID'} = $SourceID;
		$spells{$ID}{'pos'}{'x'} = $x;
		$spells{$ID}{'pos'}{'y'} = $y;
		$spells{$ID}{'type'} = $type;
		$binID = binAdd(\@spellsID, $ID);
		$spells{$ID}{'binID'} = $binID;
		$display = ($messages_lut{'011F'}{$type} ne "")
			? $messages_lut{'011F'}{$type}
			: "Unknown ".$type;

		if ($spells{$ID}{'sourceID'} eq $accountID) {
			$name = "You";
		} elsif (%{$monsters{$spells{$ID}{'sourceID'}}}) {
			$name = "$monsters{$spells{$ID}{'sourceID'}}{'name'} ($monsters{$spells{$ID}{'sourceID'}}{'binID'})";
		} elsif (%{$players{$spells{$ID}{'sourceID'}}}) {
			$name = "$players{$spells{$ID}{'sourceID'}}{'name'} ($players{$spells{$ID}{'sourceID'}}{'binID'})";
		} else {
			$name = "Unknown ".getHex($spells{$ID}{'sourceID'});
		}
		print "$name set up $display at $x, $y\n";
		# Avoid ground effect skills
		if ($config{'teleportAuto_spell'} && !$ai_v{'teleOnEvent'} && !$cities_lut{$field{'name'}.'.rsw'}
			&& ($type eq 0x81 || $type eq 0x82 || $type eq 0x8d || existsInList($config{'teleportAuto_spell_types'}, $display))
			&& $config{'teleportAuto_spell'} > distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$spells{$ID}{'pos'}})) {
			if ($config{'teleportAuto_spell_randomWalk'} && $type ne 0x81 && $type ne 0x82) {
				if (timeOut(\%{$timeout{'ai_rapidDisp'}})) {
					print "*** Avoid ground effect spell $display owned by $name, auto walking away ***\n";
					chatLog("wv","Avoid ground effect spell $display owned by $name, auto walked away.\n");
					$timeout{'ai_rapidDisp'}{'time'} = time;
				}
				escLocation(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$spells{$ID}{'pos'}}, $config{'teleportAuto_spell'});
			} else {
				if (timeOut(\%{$timeout{'ai_rapidDisp'}})) {
					print "*** Avoid ground effect spell $display owned by $name, auto teleporting ***\n";
					chatLog("tv","Avoid ground effect spell $display owned by $name, auto teleported.\n");
					$timeout{'ai_rapidDisp'}{'time'} = time;
				}
				useTeleport(1);
				$ai_v{'clear_aiQueue'} = 1;
				$ai_v{'teleOnEvent'} = 1;
			}
		}

	} elsif ($switch eq "0120") {
		#The area effect spell with ID dissappears
		$ID = substr($msg, 2, 4);
		undef %{$spells{$ID}};
		binRemove(\@spellsID, $ID);

#Cart Parses - chobit andy 20030102
	} elsif ($switch eq "0121") {
		$cart{'items'} = unpack("S1", substr($msg, 2, 2));
		$cart{'items_max'} = unpack("S1", substr($msg, 4, 2));
		$cart{'weight'} = int(unpack("L1", substr($msg, 6, 4)) / 10);
		$cart{'weight_max'} = int(unpack("L1", substr($msg, 10, 4)) / 10);

	} elsif ($switch eq "0122") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		for ($i = 4; $i < $msg_size; $i+=20) {
			$index = unpack("S1", substr($msg, $i, 2));
			$ID = unpack("S1", substr($msg, $i+2, 2));
			$type = unpack("C1", substr($msg, $i+4, 1));
			$type_equip = unpack("S1", substr($msg, $i+6, 2));
			if (%{$cart{'inventory'}[$index]}) {
				$cart{'inventory'}[$index]{'amount'} += 1;
			} else {
				$cart{'inventory'}[$index]{'nameID'} = $ID;
				$cart{'inventory'}[$index]{'amount'} = 1;
				$display = ($items_lut{$ID} ne "")
					? $items_lut{$ID}
					: "Unknown ".$ID;
				$cart{'inventory'}[$index]{'name'} = $display;
				$cart{'inventory'}[$index]{'type_equip'} = ($itemSlots_lut{$ID} ne "") ? $itemSlots_lut{$ID} : $type_equip;
				$cart{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, $i+5, 1));
				# Modify item name
				$cart{'inventory'}[$index]{'refined'} = unpack("C1", substr($msg, $i+11, 1));
				if (unpack("S1", substr($msg, $i+12, 2)) == 0x00FF) {
					$cart{'inventory'}[$index]{'attribute'} = unpack("C1", substr($msg, $i+14, 1));
					$cart{'inventory'}[$index]{'star'}      = unpack("C1", substr($msg, $i+15, 1)) / 0x05;
				} else {
					$cart{'inventory'}[$index]{'card'}[0]   = unpack("S1", substr($msg, $i+12, 2));
					$cart{'inventory'}[$index]{'card'}[1]   = unpack("S1", substr($msg, $i+14, 2));
					$cart{'inventory'}[$index]{'card'}[2]   = unpack("S1", substr($msg, $i+16, 2));
					$cart{'inventory'}[$index]{'card'}[3]   = unpack("S1", substr($msg, $i+18, 2));
				}
				modifingName(\%{$cart{'inventory'}[$index]});
			}
			print "Cart Item: $cart{'inventory'}[$index]{'name'} ($index) x 1\n" if ($config{'debug'} >= 1);
		}

	} elsif ($switch eq "0123" || $switch eq "01EF") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		my $psize = ($switch eq "0123") ? 10 : 18;
		for ($i = 4; $i < $msg_size; $i+=$psize) {
			$index = unpack("S1", substr($msg, $i, 2));
			$ID = unpack("S1", substr($msg, $i+2, 2));
			$amount = unpack("S1", substr($msg, $i+6, 2));
			if (%{$cart{'inventory'}[$index]}) {
				$cart{'inventory'}[$index]{'amount'} += $amount;
			} else {
				$cart{'inventory'}[$index]{'nameID'} = $ID;
				$cart{'inventory'}[$index]{'amount'} = $amount;
				$display = ($items_lut{$ID} ne "")
					? $items_lut{$ID}
					: "Unknown ".$ID;
				$cart{'inventory'}[$index]{'name'} = $display;
			}
			print "Cart Item: $cart{'inventory'}[$index]{'name'} ($index) x $amount\n" if ($config{'debug'} >= 1);
		}

	} elsif ($switch eq "0124" || $switch eq "01C5") {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));
		$ID = unpack("S1", substr($msg, 8, 2));
		my $psize = ($switch eq "0124") ? 0 : 1;
		if (%{$cart{'inventory'}[$index]}) {
			$cart{'inventory'}[$index]{'amount'} += $amount;
		} else {
			$cart{'inventory'}[$index]{'nameID'} = $ID;
			$cart{'inventory'}[$index]{'amount'} = $amount;
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "Unknown ".$ID;
			$cart{'inventory'}[$index]{'name'} = $display;
			# Modify item name
			$cart{'inventory'}[$index]{'type_equip'} = $itemSlots_lut{$ID} if ($cart{'inventory'}[$index]{'type_equip'} eq "");
			$cart{'inventory'}[$index]{'refined'} = unpack("C1", substr($msg, 12 + $psize, 1));
			if (unpack("S1", substr($msg, 13 + $psize, 2)) == 0x00FF) {
				$cart{'inventory'}[$index]{'attribute'} = unpack("C1", substr($msg, 15 + $psize, 1));
				$cart{'inventory'}[$index]{'star'}      = unpack("C1", substr($msg, 16 + $psize, 1)) / 0x05;
			} else {
				$cart{'inventory'}[$index]{'card'}[0]   = unpack("S1", substr($msg, 13 + $psize, 2));
				$cart{'inventory'}[$index]{'card'}[1]   = unpack("S1", substr($msg, 15 + $psize, 2));
				$cart{'inventory'}[$index]{'card'}[2]   = unpack("S1", substr($msg, 17 + $psize, 2));
				$cart{'inventory'}[$index]{'card'}[3]   = unpack("S1", substr($msg, 19 + $psize, 2));
			}
			modifingName(\%{$cart{'inventory'}[$index]});
		}
		print "Cart Item Added: $cart{'inventory'}[$index]{'name'} ($index) x $amount\n";

	} elsif ($switch eq "0125") {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));
		$cart{'inventory'}[$index]{'amount'} -= $amount;
		print "Cart Item Removed: $cart{'inventory'}[$index]{'name'} ($index) x $amount\n";
		if ($cart{'inventory'}[$index]{'amount'} <= 0) {
			undef %{$cart{'inventory'}[$index]};
		}

	} elsif ($switch eq "012C") {
		$fail = unpack("C1", substr($msg, 2, 1));
		print "Failed to add item into cart\n";

	} elsif ($switch eq "012D") {
		# vender open
		$amount = unpack("S1", substr($msg, 2, 2));
		$shop{'maxItems'} = $amount;
		print "You can sell up to $amount articals\n";

	} elsif ($switch eq "0131") {
		# vender list
		$ID = substr($msg, 2, 4);
		if (!%{$venderList{$ID}}) {
			binAdd(\@venderListID, $ID);
		}
		($venderList{$ID}{'title'}) = substr($msg, 6, 80) =~ /(.*?)\000/;
		$venderList{$ID}{'ID'} = $ID;

	} elsif ($switch eq "0132") {
		# vender closed
		$ID = substr($msg, 2, 4);
		binRemove(\@venderListID, $ID);
		undef %{$venderList{$ID}};

	} elsif ($switch eq "0133") {
		# vender item list
		$ID = substr($msg, 4, 4);
		undef @venderItemList;
		$~ = "VENDERITEMLIST";
		print "-------- Vender Item List --------\n";
		print "#  Name                                        Type        Amount   Price  z\n";
		for ($i = 8; $i < $msg_size; $i += 22) {
			$index = unpack("S1", substr($msg, $i+6, 2));
			$venderItemList[$index]{'price'} = unpack("L1", substr($msg, $i, 4));
			$venderItemList[$index]{'amount'} = unpack("S1", substr($msg, $i+4, 2));
			$venderItemList[$index]{'type'} = unpack("C1", substr($msg, $i+8, 1));
			$venderItemList[$index]{'itemID'} = unpack("S1", substr($msg, $i+9, 2));
			$venderItemList[$index]{'identified'} = unpack("C1", substr($msg, $i+11, 1));
			$venderItemList[$index]{'refined'} = unpack("C1", substr($msg, $i+13, 1));
			if (unpack("S1", substr($msg, $i+14, 2)) == 0x00FF) {
				$venderItemList[$index]{'attribute'} = unpack("C1", substr($msg, $i+16, 1));
				$venderItemList[$index]{'star'} = unpack("C1", substr($msg, $i+17, 1)) / 0x05;
			} else {
				$venderItemList[$index]{'card'}[0] = unpack("S1", substr($msg, $i+14, 2));
				$venderItemList[$index]{'card'}[1] = unpack("S1", substr($msg, $i+16, 2));
				$venderItemList[$index]{'card'}[2] = unpack("S1", substr($msg, $i+18, 2));
				$venderItemList[$index]{'card'}[3] = unpack("S1", substr($msg, $i+20, 2));
			}
			$display = ($items_lut{$venderItemList[$index]{'itemID'}} ne "")
						? $items_lut{$venderItemList[$index]{'itemID'}}
						: "Unknown ".$venderItemList[$index]{'itemID'};
			$venderItemList[$index]{'name'} = $display;
			modifingName(\%{$venderItemList[$index]});
			$display = $venderItemList[$index]{'name'};

			# Display
			format VENDERITEMLIST =
@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<< @>>>>> @>>>>>>>>z
$index,$display,$itemTypes_lut{$venderItemList[$index]{'type'}},$venderItemList[$index]{'amount'},$venderItemList[$index]{'price'}
.
			write;
		}
		print "---------------------------------\n";

	} elsif ($switch eq "0135") {
		# failed to buy from vender
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("S1", substr($msg, 4, 2));
		$fail = unpack("C1", substr($msg, 6, 1));
		print "Failed to buy from vender\n";
		print $messages_lut{$switch}{$fail}, "\n";
		print "Error Code : $fail\n" if ($config{'debug'});

	} elsif ($switch eq "0136") {
		# vender open succeed
		$shop{'opened'} = 1;
		undef @articles;
		$articles = 0;
		$~ = "ARTICLESLIST";
		print "-------- Your Shop --------\n";
		print "#  Name                                        Type        Amount   Price  z\n";
		for ($i = 8; $i < $msg_size; $i+=22) {
			$articles++;
			$index = unpack("S1", substr($msg, $i+4, 2));
			$articles[$index]{'index'} = $index;
			$articles[$index]{'price'} = unpack("L1", substr($msg, $i, 4));
			$articles[$index]{'amount'} = unpack("S1", substr($msg, $i+6, 2));
			$articles[$index]{'type'} = unpack("C1", substr($msg, $i+8, 1));
			$articles[$index]{'itemID'} = unpack("S1", substr($msg, $i+9, 2));
			$articles[$index]{'identified'} = unpack("C1", substr($msg, $i+11, 1));
			$articles[$index]{'refined'} = unpack("C1", substr($msg, $i+13, 1));
			if (unpack("S1", substr($msg, $i+14, 2)) == 0x00FF) {
				$articles[$index]{'attribute'} = unpack("C1", substr($msg, $i+16, 1));
				$articles[$index]{'star'} = unpack("C1", substr($msg, $i+17, 1)) / 0x05;
			} else {
				$articles[$index]{'card'}[0] = unpack("S1", substr($msg, $i+14, 2));
				$articles[$index]{'card'}[1] = unpack("S1", substr($msg, $i+16, 2));
				$articles[$index]{'card'}[2] = unpack("S1", substr($msg, $i+18, 2));
				$articles[$index]{'card'}[3] = unpack("S1", substr($msg, $i+20, 2));
			}
			$display = ($items_lut{$articles[$index]{'itemID'}} ne "")
						? $items_lut{$articles[$index]{'itemID'}}
						: "Unknown ".$articles[$index]{'itemID'};
			$articles[$index]{'name'} = $display;
			modifingName(\%{$articles[$index]});
			$display = $articles[$index]{'name'};

			# Display
			print "Item added to vender : $articles[$index]{'name'} x $articles[$index]{'amount'} - $articles[$index]{'price'} z\n" if ($config{'debug'});
			format ARTICLESLIST =
@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<< @>>>>> @>>>>>>>>z
$index,$display,$itemTypes_lut{$articles[$index]{'type'}},$articles[$index]{'amount'},$articles[$index]{'price'}
.
			write;
		}
		print "---------------------------\n";

	} elsif ($switch eq "0137") {
		# report for selling from vender
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("S1", substr($msg, 4, 2));
		$shop{'earned'} += $amount * $articles[$index]{'price'};
		$articles[$index]{'amount'} -= $amount;
		$articles[$index]{'sold'} += $amount;
		chatLog("sl", "Item sold: $articles[$index]{'name'} x $amount\n") if ($config{'recordSales'});
		print "Sold $articles[$index]{'name'} x $amount\n";
		if ($articles[$index]{'amount'} < 1) {
			print "Sold out : $articles[$index]{'name'}\n";
			$articles--;
			undef %{$articles[$index]};
		}
		if ($articles == 0) {
			print "Sold out all items\n";
			sendCloseShop(\$remote_socket);
			$shop{'opened'} = 0;
		}

	} elsif ($switch eq "0139") {
		$ID = substr($msg, 2, 4);
		$type = unpack("C1",substr($msg, 14, 1));
		$coords1{'x'} = unpack("S1",substr($msg, 6, 2));
		$coords1{'y'} = unpack("S1",substr($msg, 8, 2));
		$coords2{'x'} = unpack("S1",substr($msg, 10, 2));
		$coords2{'y'} = unpack("S1",substr($msg, 12, 2));
		%{$monsters{$ID}{'pos_attack_info'}} = %coords1;
		%{$chars[$config{'char'}]{'pos'}} = %coords2;
		%{$chars[$config{'char'}]{'pos_to'}} = %coords2;
		print "Recieved attack location - $monsters{$ID}{'pos_attack_info'}{'x'}, $monsters{$ID}{'pos_attack_info'}{'y'} - ".getHex($ID)."\n" if ($config{'debug'} >= 2);

	} elsif ($switch eq "013A") {
		$type = unpack("S1",substr($msg, 2, 2));
		print "Attack range: $type\n" if ($config{'debug'});

	} elsif ($switch eq "013B") {
		$type = unpack("S1", substr($msg, 2, 2));
		if ($type == 0) {
			print "Failed to attack, you haven't equip arrow\n";
			# Phantom item solution
			if ($ai_v{'arrowIndex'} ne "") {
				my $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $ai_v{'arrowIndex'});
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = "" if ($invIndex ne "");
				undef $ai_v{'arrowIndex'};
			}
		} elsif ($type == 3) {
			print "You equip arrow\n" if ($config{'debug'});
		} else {
			dumpData(substr($msg, 0, $msg_size)) if ($config{'debug_packet'} >= 3);
		}

	} elsif ($switch eq "013C") {
		$index = unpack("S1",substr($msg, 2, 2));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		if ($invIndex ne "") {
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = 0;
			print "You equip $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) - $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}}\n";
		}
		# Phantom item solution
		$ai_v{'arrowIndex'} = $index;

	} elsif ($switch eq "013D") {
		$type = unpack("S1",substr($msg, 2, 2));
		$amount = unpack("S1",substr($msg, 4, 2));
		if ($type == 5) {
			$chars[$config{'char'}]{'hp'} += $amount;
			$chars[$config{'char'}]{'hp'} = $chars[$config{'char'}]{'hp_max'} if ($chars[$config{'char'}]{'hp'} > $chars[$config{'char'}]{'hp_max'});
		} elsif ($type == 7) {
			$chars[$config{'char'}]{'sp'} += $amount;
			$chars[$config{'char'}]{'sp'} = $chars[$config{'char'}]{'sp_max'} if ($chars[$config{'char'}]{'sp'} > $chars[$config{'char'}]{'sp_max'});
		}
		# HP/SP info display
		if (($type == 5 || $type == 7) && $chars[$config{'char'}]{'hp_max'} && $chars[$config{'char'}]{'sp_max'}) {
			$ai_v{'hsinfo'} = "(HP:".int($chars[$config{'char'}]{'hp'}/$chars[$config{'char'}]{'hp_max'} * 100)."%/SP:"
					.int($chars[$config{'char'}]{'sp'}/$chars[$config{'char'}]{'sp_max'} * 100)."%) ";
		}

	} elsif ($switch eq "013E") {
		$sourceID = substr($msg, 2, 4);
		$targetID = substr($msg, 6, 4);
		$x = unpack("S1",substr($msg, 10, 2));
		$y = unpack("S1",substr($msg, 12, 2));
		$skillID = unpack("S1",substr($msg, 14, 2));
		# Attribute and wait display on casting
		$attribute = unpack("S1",substr($msg, 16, 2));
		$wait = unpack("S1",substr($msg, 20, 2));
		undef $sourceDisplay;
		undef $targetDisplay;
		if (%{$monsters{$sourceID}}) {
			$sourceDisplay = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) is casting";
		} elsif (%{$players{$sourceID}}) {
			$sourceDisplay = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) is casting";
		} elsif ($sourceID eq $accountID) {
			# HP/SP info display
			$sourceDisplay = $ai_v{'hsinfo'}."You are casting";
			$chars[$config{'char'}]{'time_cast'} = time;
			$ai_v{'temp'}{'castWait'} = $wait / 1000;
		} else {
			$sourceDisplay = "Unknown is casting";
		}


		if (%{$monsters{$targetID}}) {
			$targetDisplay = "$monsters{$targetID}{'name'} ($monsters{$targetID}{'binID'})";
			if ($sourceID eq $accountID) {
				$monsters{$targetID}{'castOnByYou'}++;
			} elsif (%{$players{$sourceID}}) {
				$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
			}
		} elsif (%{$players{$targetID}}) {
			$targetDisplay = "$players{$targetID}{'name'} ($players{$targetID}{'binID'})";
		} elsif ($targetID eq $accountID) {
			if ($sourceID eq $accountID) {
				$targetDisplay = "yourself";
			} else {
				$targetDisplay = "you";
			}
		} elsif ($x != 0 || $y != 0) {
			$targetDisplay = "location ($x, $y)";
		} else {
			$targetDisplay = "unknown";
		}
		# Attribute and wait display on casting
#		print "$sourceDisplay $skillsID_lut{$skillID} on $targetDisplay\n";
		print "$sourceDisplay $skillsID_lut{$skillID} on $targetDisplay [";
		print "Atr:$attribute_lut{$attribute} - " if $attribute;
		print "$wait ms]\n";
		# Avoid monster skills
		if ($config{'teleportAuto_castOnYou'} && %{$monsters{$sourceID}}
			&& ($targetID eq $accountID || %{$monsters{$targetID}} || $x != 0 || $y != 0)
			&& existsInList($config{'teleportAuto_castOnYou_skills'}, $skillsID_lut{$skillID})
			&& !$ai_v{'teleOnEvent'} && !$cities_lut{$field{'name'}.'.rsw'}) {
			undef %coords;
			$coords{'x'} = $x;
			$coords{'y'} = $y;

			if ($targetID eq $accountID || %{$monsters{$targetID}} || $config{'teleportAuto_castOnYou'} > distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%coords)) {
				if ($config{'teleportAuto_castOnYou_randomWalk'}) {
					print "*** Avoid monster skill $skillsID_lut{$skillID} casted by $monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}), auto walking away ***\n";
					%coords = %{$chars[$config{'char'}]{'pos_to'}} if ($targetID eq $accountID || %{$monsters{$targetID}});
					escLocation(\%{$chars[$config{'char'}]{'pos_to'}}, \%coords, $config{'teleportAuto_castOnYou'});
				} else {
					print "*** Avoid monster skill $skillsID_lut{$skillID} casted by $monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}), auto teleporting ***\n";
					useTeleport(1);
					$ai_v{'clear_aiQueue'} = 1;
					$ai_v{'teleOnEvent'} = 1;
				}
			}
		}

	} elsif ($switch eq "0141") {
		$type = unpack("S1",substr($msg, 2, 2));
		$val = unpack("S1",substr($msg, 6, 2));
		$val2 = unpack("s1",substr($msg, 10, 2));
		if ($type == 13) {
			$chars[$config{'char'}]{'str'} = $val;
			$chars[$config{'char'}]{'str_bonus'} = $val2;
			print "Strength: $val + $val2\n" if $config{'debug'};
		} elsif ($type == 14) {
			$chars[$config{'char'}]{'agi'} = $val;
			$chars[$config{'char'}]{'agi_bonus'} = $val2;
			print "Agility: $val + $val2\n" if $config{'debug'};
		} elsif ($type == 15) {
			$chars[$config{'char'}]{'vit'} = $val;
			$chars[$config{'char'}]{'vit_bonus'} = $val2;
			print "Vitality: $val + $val2\n" if $config{'debug'};
		} elsif ($type == 16) {
			$chars[$config{'char'}]{'int'} = $val;
			$chars[$config{'char'}]{'int_bonus'} = $val2;
			print "Intelligence: $val + $val2\n" if $config{'debug'};
		} elsif ($type == 17) {
			$chars[$config{'char'}]{'dex'} = $val;
			$chars[$config{'char'}]{'dex_bonus'} = $val2;
			print "Dexterity: $val + $val2\n" if $config{'debug'};
		} elsif ($type == 18) {
			$chars[$config{'char'}]{'luk'} = $val;
			$chars[$config{'char'}]{'luk_bonus'} = $val2;
			print "Luck: $val + $val2\n" if $config{'debug'};
		}

	} elsif ($switch eq "0145") {
		# Show / hide Kafra

	} elsif ($switch eq "0147") {
		$skillID = unpack("S*",substr($msg, 2, 2));
		$skillLv = unpack("S*",substr($msg, 8, 2));
		# Free fly for one wing
		if ($config{'teleportAuto_useItem'} == 2 && $skillID == 26 && $skillLv == 1) {
			$ai_v{'wingUsed'} = 1;
			useTeleport(1);
		} else {
			print "Now using $skillsID_lut{$skillID}, lv $skillLv\n";
			sendSkillUse(\$remote_socket, $skillID, $skillLv, $accountID);
		}

	} elsif ($switch eq "0148") {
		# Resurrection
		$ID = substr($msg, 2, 4);
		if ($ID eq $accountID) {
			$display = "You have";
			undef $chars[$config{'char'}]{'dead'};
			undef $chars[$config{'char'}]{'dead_time'};
			undef @ai_seq;
			undef @ai_seq_args;
		} elsif (%{$players{$ID}}) {
			$display = "$players{$ID}{'name'} ($players{$ID}{'binID'}) has";
			undef $players{$ID}{'dead'};
		} else {
			$display = "Unknown has";
		}
		print "$display got resurrected\n";

	} elsif ($switch eq "014B") {
		# Modify mannar point

	} elsif ($switch eq "014C") {
		# alliance or rival guild
#		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
#		$msg = substr($msg, 0, 4).$newmsg;
#		for ($i = 4; $i < $msg_size; $i += 36) {
#			$type = substr($msg, $i, 4);
#			$ID   = substr($msg, $i + 4, 4);
#			($name) = substr($msg, $i + 8, 24) =~ /([\s\S*?])\000/;
#		}
#		dumpData(substr($msg, 0, $msg_size)) if ($config{'debug_packet'} >= 3);

	} elsif ($switch eq "014E") {
#		$type = substr($msg, 2, 4);

	} elsif ($switch eq "0150") {
		# Guild Information
		$ID = substr($msg, 2, 4);
		$guild{$ID}{'ID'}        = $ID;
		$guild{$ID}{'lvl'}       = unpack("L1", substr($msg,  6, 4));
		$guild{$ID}{'conMember'} = unpack("L1", substr($msg, 10, 4));
		$guild{$ID}{'maxMember'} = unpack("L1", substr($msg, 14, 4));
		$guild{$ID}{'average'}   = unpack("L1", substr($msg, 18, 4));
		$guild{$ID}{'exp'}       = unpack("L1", substr($msg, 22, 4));
		$guild{$ID}{'next_exp'}  = unpack("L1", substr($msg, 26, 4));
		($guild{$ID}{'name'})    = substr($msg, 46, 24) =~ /([\s\S]*?)\000/;
		($guild{$ID}{'master'})  = substr($msg, 70, 24) =~ /([\s\S]*?)\000/;
#		dumpData(substr($msg, 0, $msg_size)) if ($config{'debug_packet'} >= 3);

	} elsif ($switch eq "0152") {
		# guild emblem image

	} elsif ($switch eq "0154") {
		# Guild Members Information
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		$ID = $chars[$config{'char'}]{'guild'}{'ID'};
		$guild{$ID}{'members'} = 0;
		for ($i = 4; $i < $msg_size; $i+=104) {
			$guild{$ID}{'member'}[int($i/104)]{'ID'} = substr($msg, $i, 4);
			$guild{$ID}{'member'}[int($i/104)]{'jobID'} = unpack("S1", substr($msg, $i + 14, 2));
			$guild{$ID}{'member'}[int($i/104)]{'lvl'} = unpack("S1", substr($msg, $i + 16, 2));
			$guild{$ID}{'member'}[int($i/104)]{'contribution'} = unpack("L1", substr($msg, $i + 18, 4));
			$guild{$ID}{'member'}[int($i/104)]{'online'} = unpack("S1", substr($msg, $i + 22, 2));
			$guild{$ID}{'member'}[int($i/104)]{'title'} = unpack("L1", substr($msg, $i + 26, 4));
			($guild{$ID}{'member'}[int($i/104)]{'name'}) = substr($msg, $i + 80, 24) =~ /([\s\S]*?)\000/;
			$guild{$ID}{'members'}++;
		}
#		dumpData(substr($msg, 0, $msg_size)) if ($config{'debug_packet'} >= 3);

	} elsif ($switch eq "0156") {
#		$ID1 = substr($msg, 4, 4);
#		$ID2 = substr($msg, 8, 4);

	} elsif ($switch eq "015A") {
		# guild leave recv
		($name) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		($message) = substr($msg, 26, 40) =~ /([\s\S]*?)\000/;
		print "$name left from guild ($message)\n";

	} elsif ($switch eq "015C") {
		# guild expell recv
		($name) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		($message) = substr($msg, 26, 40) =~ /([\s\S]*?)\000/;
		$ID = substr($msg. 66, 24);
		print "$name was kicked out of guild ($message)\n";

	} elsif ($switch eq "0162") {
		# guild skill list

#	} elsif ($switch eq "0163") {
		# guild kick message

	} elsif ($switch eq "0166") {
		# Guild Members Title List
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		$ID = $chars[$config{'char'}]{'guild'}{'ID'};
		for ($i = 4; $i < $msg_size; $i += 28) {
			($guild{$ID}{'title'}[unpack("L1", substr($msg, $i, 4))]) = substr($msg, $i + 4, 24) =~ /([\s\S]*?)\000/;
		}

	} elsif ($switch eq "0167") {
		# guild create recv
		$type = substr($msg, 2, 1);
		if ($type == 0) {
			print "Guild created\n";
		} elsif ($type == 2) {
			print "Failed to create guild\n";
		}

	} elsif ($switch eq "0169") {
		# guild request denied
		print "Guild request cancelled\n";

	} elsif ($switch eq "016A") {
		# guild request for you
		$ID = substr($msg, 2, 4);
		($name) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
		print "Incoming Request to join guild '$name'\n";
		$incomingGuild{'ID'} = $ID;
		$timeout{'ai_guildAutoDeny'}{'time'} = time;

	} elsif ($switch eq "016C") {
		# 016C <guildID>.l <?>.13B <guildName>.24B
		$chars[$config{'char'}]{'guild'}{'ID'} = substr($msg, 2, 4);
		($chars[$config{'char'}]{'guild'}{'name'}) = substr($msg, 19, 24) =~ /([\s\S]*?)\000/;

	} elsif ($switch eq "016D" || $switch eq "01F2") {
		$ID = substr($msg, 2, 4);
		$targetID =  substr($msg, 6, 4);
		$type = unpack("L1", substr($msg, 10, 4));
		$players{$targetID}{'online'} = $type;
		sendGMNameRequest(\$remote_socket, $targetID);

	} elsif ($switch eq "016F") {
		($address) = substr($msg, 2, 60) =~ /([\s\S]*?)\000/;
		($message) = substr($msg, 62, 120) =~ /([\s\S]*?)\000/;
		print	"---Guild Notice---\n"
			,"$address\n\n"
			,"$message\n"
			,"------------------\n";

	} elsif ($switch eq "0171") {
		# Guild alliance request
#		$sourceID = substr($msg, 2, 4);
#		($name) = substr($msg, 6, 24) =~ /[\s\S]*?\000/;

	} elsif ($switch eq "0173") {
		# Reply guild alliance
#		$type = substr($msg, 2, 1);

	} elsif ($switch eq "0174") {
		# Edit Guild Position Info
#		$amount = unpack("L1", substr($msg, 16, 4));
#		$name = substr($msg, 20, 24);

	} elsif ($switch eq "0177") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef @identifyID;
		undef $invIndex;
		for ($i = 4; $i < $msg_size; $i += 2) {
			$index = unpack("S1", substr($msg, $i, 2));
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			binAdd(\@identifyID, $invIndex);
		}
		print "Recieved Possible Identify List - type 'identify'\n";

	} elsif ($switch eq "0179") {
		$index = unpack("S*",substr($msg, 2, 2));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		$chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = 1;
		$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} = $itemSlots_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}} if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} eq "");
		print "Item Identified: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}\n";
		undef @identifyID;

	} elsif ($switch eq "017F") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		$ID = substr($msg, 4, 4);
		$chat = substr($msg, 4, $msg_size - 4);
		$chat = recallCheck($chat) if ($recallCommand ne "");
		($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
		chatLog("g", $chat."\n");
		$ai_cmdQue[$ai_cmdQue]{'type'} = "g";
		$ai_cmdQue[$ai_cmdQue]{'ID'} = $ID;
		$ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser;
		$ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg;
		$ai_cmdQue[$ai_cmdQue]{'time'} = time;
		$ai_cmdQue++;
		print "[Guild] $chat\n";
		# Auto reply guild
		if ($config{'autoResponse'}) {
			my $resMsg = judgeRes('#g#'.$chatMsg, $chatMsgUser);
			ai_action("Reply", "g ".$resMsg) if ($resMsg);
		}

	} elsif ($switch eq "0182") {
		# player joins your guild
		# 0182 <accID>.l <charactorID>.l <hair style>.w <hair color>.w <sex?>.w
		#      <job>.w <lvl?>.w <contribution_exp>.l <online>.l <Position>.l ?.50B <nick>.24B

	} elsif ($switch eq "0187") {
		# Alive signal?
#		$accountID = substr($msg, 2, 4);

	} elsif ($switch eq "0189") {
		print "Warping and teleporting are prohibited in this zone\n";

	} elsif ($switch eq "018A") {
		# Exit game

	} elsif ($switch eq "018D") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef @pharmacyID;
		for ($i = 4; $i < $msg_size; $i += 8) {
			$ID = unpack("S1",substr($msg, $i, 2));
			binAdd(\@pharmacyID, $ID);
		}
		print "Recieved Possible Potion Making List - type 'potion'\n";

	} elsif ($switch eq "018F") {
		$type = unpack("C1", substr($msg, 2, 1));
		$ID = unpack("S1", substr($msg, 4, 2));
		$display = $items_lut{$ID};
		if ($type == 2) {
			print "Succeeded to make $display\n";
		} elsif ($type == 3) {
			print "Falied to make $display\n";
		}

	} elsif ($switch eq "0191") {
		# talkie box message
		$ID = substr($msg, 2, 4);
		($message) = substr($msg, 6, 80) =~ /(.*?)\000/;
		print "Talkie Box : $message\n";

	} elsif ($switch eq "0194") {
		# Guild member online status support
		$ID = substr($msg, 2, 4);
		($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
#		print "Guildsman connected: $name\n";
		if ($name ne $chars[$config{'char'}]{'name'}) {
			my $online_string = ($players{$ID}{'online'}) ? "logged in." : "logged out.";
			print "Guild Member $name $online_string\n";
			chatLog("g", "Guild Member $name $online_string\n") if ($config{'recordGuildMemberLog'});
		}

	} elsif ($switch eq "0195") {
		$ID = substr($msg, 2, 4);
		if (%{$players{$ID}}) {
			($players{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			($players{$ID}{'party'}{'name'}) = substr($msg, 30, 24) =~ /([\s\S]*?)\000/;
			($players{$ID}{'guild'}{'name'}) = substr($msg, 54, 24) =~ /([\s\S]*?)\000/;
			($players{$ID}{'guild'}{'men'}{$players{$ID}{'name'}}{'title'}) = substr($msg, 78, 24) =~ /([\s\S]*?)\000/;
			print "Player Info: $players{$ID}{'name'} ($players{$ID}{'binID'})\n" if ($config{'debug'} >= 2);
			# Record player data
			RecordPlayerData($ID) if ($config{'recordPlayerInfo'});
			# Avoid GM
			avoidGM($ID, $players{$ID}{'name'}, 0);
			# Avoid specified player
			avoidPlayer($ID);
		}

	} elsif ($switch eq "0196") {
		# Status icon
		$type = unpack("S1", substr($msg, 2, 2));
		$targetID = substr($msg, 4, 4);
		$on = unpack("C1", substr($msg, 8, 1));
		my @messages = split(/::/, $messages_lut{$switch}{$type});
		my $targetDisplay;

		if ($targetID eq $accountID) {
			binRemoveAndShift(\@{$chars[$config{'char'}]{'status'}}, $type);
			push @{$chars[$config{'char'}]{'status'}}, $type if $on;
			# HP/SP info display
			$targetDisplay = $ai_v{'hsinfo'};
		} elsif (%{$players{$targetID}}) {
			$targetDisplay = $players{$targetID}{'name'};
		} else {
			$targetDisplay = "Unknown ".getHex($targetID);
		}
		if ($messages[$on] ne "") {
			print $targetDisplay, $messages[$on], "\n" if ($targetID eq $accountID || $config{'debug'});
		} elsif ($config{'debug'} || $config{'debug_packet'}) {
			my $status = ($on) ? "On" : "Off";
			$targetDisplay = "You" if ($targetID eq $accountID);
			print	"Unparsed type of switch 0196:\n"
				,"Type: $type, Target: $targetDisplay, Status: $status\n";
			dumpData(substr($msg, 0, $msg_size)) if ($config{'debug_packet'} >= 3);
		}

	} elsif ($switch eq "0199") {
		$type = unpack("S1",substr($msg, 2, 2));
		if ($type == 1) {
			print "You are in pvp mode\n";
		} elsif ($type ==3) {
			print "You are in gvg mode\n";
		}

	} elsif ($switch eq "019B") {
		$ID = substr($msg, 2, 4);
		$type = unpack("L1",substr($msg, 6, 4));
		if (%{$players{$ID}}) {
			$name = $players{$ID}{'name'};
		} else {
			$name = "Unknown";
		}
		if ($type == 0) {
			print "Player $name gained a level!\n";
		} elsif ($type == 1) {
			print "Player $name gained a job level!\n";
		}

	} elsif ($switch eq "01A0") {
		# Judge get a pet
		$fail = unpack("C1", substr($msg, 2, 1));
		if ($fail) {
			print "Pet captured\n";
		} else {
			print "Failed to capture the pet\n";
		}

	} elsif ($switch eq "01A2") {
		#pet status
		# 01A2 <name>.24B <flag>.B <lvl>.w <hunger>.w <imtimate>.w <accessoryID>.w
		($name) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		$pets{$ID}{'name_given'} = 1;
		$chars[$config{'char'}]{'pet'}{'modified'} = unpack("C1", substr($msg, 26, 1));
		$chars[$config{'char'}]{'pet'}{'name_given'} = $name;
		$chars[$config{'char'}]{'pet'}{'lvl'} = unpack("S1", substr($msg, 27, 2));
		$chars[$config{'char'}]{'pet'}{'hunger'} = unpack("S1", substr($msg, 29, 2));
		$chars[$config{'char'}]{'pet'}{'intimate'} = unpack("S1", substr($msg, 31, 2));
		$chars[$config{'char'}]{'pet'}{'accessory'} = unpack("S1", substr($msg, 33, 2));
		# Pet auto return
		if (($config{'petAutoReturn'} && $chars[$config{'char'}]{'pet'}{'intimate'} >= $config{'petAutoReturn'})
			|| $chars[$config{'char'}]{'pet'}{'hunger'} <= 10 || $chars[$config{'char'}]{'pet'}{'intimate'} <= 100) {
			print "Auto return your pet to egg\n";
			sendPetCommand(\$remote_socket, 3);
			undef %{$chars[$config{'char'}]{'pet'}};
		}

	} elsif ($switch eq "01A3") {
		#pet
		# 01A3 <fail>.B <itemID>.w
		$fail = unpack("C1", substr($msg, 2, 1));
		$ID = unpack("S1", substr($msg, 3, 2));
		if (!$fail) {
			print "You can't give a food($items_lut{$ID}), auto return to egg\n";
			sendPetCommand(\$remote_socket, 3);
			undef %{$chars[$config{'char'}]{'pet'}};
		}

	} elsif ($switch eq "01A4") {
		#pet spawn
		$type = unpack("C1",substr($msg, 2, 1));
		$ID = substr($msg, 3, 4);
		$val = unpack("L1", substr($msg, 7, 4));
		if (!%{$pets{$ID}}) {
			binAdd(\@petsID, $ID);
			%{$pets{$ID}} = %{$monsters{$ID}};
			$pets{$ID}{'name_given'} = "Unknown";
			$pets{$ID}{'binID'} = binFind(\@petsID, $ID);
		}
		if (%{$monsters{$ID}}) {
			binRemove(\@monstersID, $ID);
			undef %{$monsters{$ID}};
		}
		if ($type == 0x01) {
			# pet intimately
			$chars[$config{'char'}]{'pet'}{'intimate'} = $val;
		} elsif ($type == 0x02) {
			# pet hunger
			if ($val <= $config{'petAutoFood_hunger'}) {
				my $petfood = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'petAutoFood'});
				if ($petfood ne "") {
					print "Auto-give pet food : $config{'petAutoFood'}\n";
					sendPetCommand(\$remote_socket, 1);
				} else {
					print "You ran out of feed, auto-return to Egg\n";
					sendPetCommand(\$remote_socket, 3);
					undef %{$chars[$config{'char'}]{'pet'}};
				}
			}
			$chars[$config{'char'}]{'pet'}{'hunger'} = $val;
		} elsif ($type == 0x03) {
			# pet equip accessory
			if (!$val) {
				print "$pets{$ID}{'name_given'} unequiped its accessory\n";
			} else {
				print "$pets{$ID}{'name_given'} equiped $items_lut{$val}\n";
			}
		} elsif ($type == 0x04) {
			# pet performance
		} elsif ($type == 0x05) {
			print "Pet Spawned: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});
		} else {
			dumpData(substr($msg, 0, $msg_size)) if ($config{'debug_packet'} >= 3);
		}

	} elsif ($switch eq "01AA") {
		#pet emotion
		# 01AA <ID>.l <emotion>.w <?>.w
		$ID = substr($msg, 2, 4);
		$type = unpack("S1", substr($msg, 6, 2));
		if ($type < 47) {
			print "$pets{$ID}{'name_given'} : $emotions_lut{$type}\n";
#		} else {
#			dumpData(substr($msg, 0, $msg_size)) if ($config{'debug_packet'} >= 3);
		}

	} elsif ($switch eq "01AB") {
		#Chat and skill ban
		$ID = substr($msg, 2, 4);
		$type = unpack("S1", substr($msg, 6, 2));
		$value = unpack("l1", substr($msg, 8, 4));

		$value = abs($value);
		if ($ID eq $accountID) {
			$display = "You have";
		} elsif (%{$players{$ID}}) {
			$display = "$players{$ID}{'name'} ($players{$ID}{'binID'}) has";
		} else {
			$display = "Unknown has";
		}
		print "$display been banned for $value minutes\n";

	} elsif ($switch eq "01AC") {
#		$ID = substr($msg, 2, 4);

	} elsif ($switch eq "01AD") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef @arrowID;
		for ($i = 4; $i < $msg_size; $i += 2) {
			$ID = unpack("S1", substr($msg, $i, 2));
			binAdd(\@arrowID, $ID);
		}
		print "Recieved Possible Arrow Making List - type 'arrow'\n";

	} elsif ($switch eq "01B0"){
		#monster Type Change
		$ID = substr($msg,2,4);
		$type = unpack("L1", substr($msg, 7, 4));
		if (!%{$monsters{$ID}}) {
			$monsters{$ID}{'appear_time'} = time;
			binAdd(\@monstersID, $ID);
			$monsters{$ID}{'nameID'} = $type;
			$monsters{$ID}{'name'} = ($monsters_lut{$type} ne "") ? $monsters_lut{$type} : "Unknown ".$type;
			$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
		} else {
			$monsters{$ID}{'nameID'} = $type;
			$monsters{$ID}{'name'} = ($monsters_lut{$type} ne "") ? $monsters_lut{$type} : "Unknown ".$type;
		}

	} elsif ($switch eq "01B3") {
      		#NPC image
      		$npc_image = substr($msg, 2,64);
      		($npc_image) = $npc_image =~ /([\s\S]*?)\000/;
      		print "NPC image: $npc_image\n" if $config{'debug'};

	} elsif ($switch eq "01B6") {
		# Guild Information
		$ID = substr($msg, 2, 4);
		$guild{$ID}{'ID'}        = $ID;
		$guild{$ID}{'lvl'}       = unpack("L1", substr($msg,  6, 4));
		$guild{$ID}{'conMember'} = unpack("L1", substr($msg, 10, 4));
		$guild{$ID}{'maxMember'} = unpack("L1", substr($msg, 14, 4));
		$guild{$ID}{'average'}   = unpack("L1", substr($msg, 18, 4));
		$guild{$ID}{'exp'}       = unpack("L1", substr($msg, 22, 4));
		$guild{$ID}{'next_exp'}  = unpack("L1", substr($msg, 26, 4));
		($guild{$ID}{'name'})    = substr($msg, 46, 24) =~ /([\s\S]*?)\000/;
		($guild{$ID}{'master'})  = substr($msg, 70, 24) =~ /([\s\S]*?)\000/;
#		dumpData(substr($msg, 0, $msg_size)) if ($config{'debug_packet'} >= 3);

	} elsif ($switch eq "01B9") {
		$ID = substr($msg, 2, 4);
		undef $display;

		if ($ID eq $accountID) {
			undef $chars[$config{'char'}]{'time_cast'};
			undef $ai_v{'temp'}{'castWait'};
			aiRemove("skill_use");
			$display = "You";
		} elsif (%{$monsters{$ID}}) {
			$display = "$monsters{$ID}{'name'} ($monsters{$ID}{'binID'})";
		} elsif (%{$players{$ID}}) {
			$display = "$players{$ID}{'name'} ($players{$ID}{'binID'})";
		} else {
			$display = "Unknown";
		}
		print "$display failed to use skill\n";

	} elsif ($switch eq "01C4") {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));
		$ID = unpack("S1", substr($msg, 8, 2));
		if (%{$storage{'inventory'}[$index]}) {
			$storage{'inventory'}[$index]{'amount'} += $amount;
		} else {
			$storage{'inventory'}[$index]{'nameID'} = $ID;
			$storage{'inventory'}[$index]{'amount'} = $amount;
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "Unknown ".$ID;
			$storage{'inventory'}[$index]{'name'} = $display;
			# Modify item name
			$storage{'inventory'}[$index]{'refined'} = unpack("C1", substr($msg, 10, 1));
			if (unpack("S1", substr($msg, 11, 2)) == 0x00FF) {
				$storage{'inventory'}[$index]{'attribute'} = unpack("C1", substr($msg, 13, 1));
				$storage{'inventory'}[$index]{'star'}      = unpack("C1", substr($msg, 14, 1)) / 0x05;
			} else {
				$storage{'inventory'}[$index]{'card'}[0]   = unpack("S1", substr($msg, 11, 2));
				$storage{'inventory'}[$index]{'card'}[1]   = unpack("S1", substr($msg, 13, 2));
				$storage{'inventory'}[$index]{'card'}[2]   = unpack("S1", substr($msg, 15, 2));
				$storage{'inventory'}[$index]{'card'}[3]   = unpack("S1", substr($msg, 17, 2));
			}
			modifingName(\%{$storage{'inventory'}[$index]});
		}
		print "Storage Item Added: $storage{'inventory'}[$index]{'name'} ($index) x $amount\n";

	} elsif ($switch eq "01C8") {
		$index = unpack("S1",substr($msg, 2, 2));
		$ID = unpack("S1", substr($msg, 4, 2));
		$sourceID = substr($msg, 6, 4);
		$amountleft = unpack("S1",substr($msg, 10, 2));
		$display = ($items_lut{$ID} ne "")
			? $items_lut{$ID}
			: "Unknown ".$ID;

		if ($sourceID eq $accountID) {
			undef $invIndex;
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			$amount = $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $amountleft;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $amount;
			if ($amount == 0 && $chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} <= 2) {
				# Phantom item solution
				my $realIndex = findIndex_next($invIndex, \&findIndexString_lc, \@{$chars[$config{'char'}]{'inventory'}}, "name", $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'});
				if ($realIndex ne "") {
					print "Found phantom item $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex), trying $realIndex ...\n";
					chatLog("db", "Found phantom item $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex), trying $realIndex ...\n");
					undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
					sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$realIndex]{'index'}, $accountID);
				}
				print "You failed to used Item: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex)\n";
				chatLog("db", "You failed to used Item: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex)\n");
			} else {
				print "You used Item: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amount\n";
				if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
					undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
				}
			}
		} elsif (%{$players{$sourceID}}) {
			print "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) used $display\n" if $config{'debug'};
		} else {
			print "Unknown used $display\n" if $config{'debug'};
		}

	} elsif ($switch eq "01CD") {
		undef @autospellID;
		for ($i = 2; $i < 30; $i += 4) {
			$ID = unpack("S1",substr($msg, $i, 2));
			binAdd(\@autospellID, $ID);
		}
		print "Recieved Possible Auto Casting Spell - type 'spell'\n";

	} elsif ($switch eq "01CF") {
		# Devotion Target List
		$sourceID = substr($msg, 2, 4);
#		$flag = unpack("S1",substr($msg, 26, 2));
		my @targetID;
		for ($i = 6; $i < $msg_size - 2; $i += 4) {
			$ID = substr($msg, $i, 4);
			binAdd(\@targetID, $ID);
		}

	} elsif ($switch eq "01D0" || $switch eq "01E1") {
		# Spirits Amount
		$ID = substr($msg, 2, 4);
		$amount = unpack("S1",substr($msg, 6, 2));

		if ($ID eq $accountID) {
			$chars[$config{'char'}]{'spirits'} = $amount;
			print "You have $amount spirit(s) now\n";
		}

	} elsif ($switch eq "01D1") {
		# Blade Stop
		$sourceID = substr($msg, 2, 4);
		$targetID = substr($msg, 6, 4);
#		$flag = unpack("S1",substr($msg, 10, 2));
		# Place Skill combo code here?

	} elsif ($switch eq "01D2") {
		# Triple Attack
		$sourceID = substr($msg, 2, 4);
		$wait = unpack("L1",substr($msg, 6, 4));

	} elsif ($switch eq "01D7") {
		# Weapon Display (type - 2:hand eq, 9:foot eq)
		$sourceID = substr($msg, 2, 4);
		$type = unpack("C1",substr($msg, 6, 1));
		$ID1 = unpack("S1", substr($msg, 7, 2));
		$ID2 = unpack("S1", substr($msg, 9, 2));

	} elsif ($switch eq "01DC") {
		$ai_v{'msg01DC'} = substr($msg, 4, $msg_size - 4);

	} elsif ($switch eq "0185" || $switch eq "019A" || $switch eq "01B4") {
		# unknown packets
		dumpData(substr($msg, 0, $msg_size)) if ($config{'debug_packet'} >= 3);

	} elsif (binFind(\@filter, $switch) ne "") {
		# Preset packet filter

	} else {
		print "Unparsed packet - $switch\n" if $config{'debug'};

		if ($config{'debug_filter'}) {
			dumpData(substr($msg, 0, $msg_size)) if ($config{'debug_packet'} >= 3);
		} else {
			$totalError++;
			if ($totalError > 20) {
				print "Too many errors, your Clio maybe out of date.\n";
				relog("Disconnect for 86400 seconds...\n");
				undef $totalError;
				$timeout_ex{'master'}{'time'} = time;
				$timeout_ex{'master'}{'timeout'} = 86400;
			}
			undef $msg_size;
		}
	}

	$lastPacket = substr($msg, 0, $msg_size) if ($config{'debug_packet'} >= 2 && $msg_size);
	$msg = (length($msg) >= $msg_size) ? substr($msg, $msg_size, length($msg) - $msg_size) : "";
	return $msg;
}




#######################################
#######################################
#AI FUNCTIONS
#######################################
#######################################

sub ai_clientSuspend {
	my ($type,$initTimeout,@args) = @_;
	my %args;
	$args{'type'} = $type;
	$args{'time'} = time;
	$args{'timeout'} = $initTimeout;
	@{$args{'args'}} = @args;
	unshift @ai_seq, "clientSuspend";
	unshift @ai_seq_args, \%args;
}

sub ai_follow {
	my $name = shift;
	my %args;
	$args{'name'} = $name;
	unshift @ai_seq, "follow";
	unshift @ai_seq_args, \%args;
}

sub ai_getAggressives {
	my @agMonsters;
	foreach (@monstersID) {
		next if ($_ eq "");
		if (($monsters{$_}{'dmgToYou'} > 0 || $monsters{$_}{'missedYou'} > 0) && $monsters{$_}{'attack_failed'} <= 1) {
			push @agMonsters, $_;
		}
	}
	return @agMonsters;
}

sub ai_getIDFromChat {
	my $r_hash = shift;
	my $msg_user = shift;
	my $match_text = shift;
	my $qm;
	if ($match_text !~ /\w+/ || $match_text eq "me") {
		foreach (keys %{$r_hash}) {
			next if ($_ eq "");
			if ($msg_user eq $$r_hash{$_}{'name'}) {
				return $_;
			}
		}
	} else {
		foreach (keys %{$r_hash}) {
			next if ($_ eq "");
			$qm = quotemeta $match_text;
			if ($$r_hash{$_}{'name'} =~ /$qm/i) {
				return $_;
			}
		}
	}
}

sub ai_getMonstersWhoHitMe {
	my @agMonsters;
	foreach (@monstersID) {
		next if ($_ eq "");
		if ($monsters{$_}{'dmgToYou'} > 0 && $monsters{$_}{'attack_failed'} <= 1) {
			push @agMonsters, $_;
		}
	}
	return @agMonsters;
}

sub ai_getSkillUseType {
	my $skill = shift;
	if ($skill eq "WZ_FIREPILLAR" || $skill eq "WZ_METEOR"
		|| $skill eq "WZ_VERMILION" || $skill eq "WZ_STORMGUST"
		|| $skill eq "WZ_HEAVENDRIVE" || $skill eq "WZ_QUAGMIRE"
		|| $skill eq "MG_SAFETYWALL" || $skill eq "MG_FIREWALL"
#		|| $skill eq "MG_THUNDERSTORM") {
		|| $skill eq "MG_THUNDERSTORM" || $skill eq "AL_PNEUMA"
		|| $skill eq "AL_WARP" || $skill eq "PR_SANCTUARY"
		|| $skill eq "PR_MAGNUS"|| $skill eq "BS_HAMMERFALL"
		|| $skill eq "HT_SKIDTRAP" || $skill eq "HT_LANDMINE"
		|| $skill eq "HT_ANKLESNARE" || $skill eq "HT_SHOCKWAVE"
		|| $skill eq "HT_SANDMAN" || $skill eq "HT_FLASHER"
		|| $skill eq "HT_FREEZINGTRAP" || $skill eq "HT_BLASTMINE"
		|| $skill eq "HT_CLAYMORETRAP" || $skill eq "AS_VENOMDUST"
		|| $skill eq "RG_GRAFFITI" || $skill eq "AM_DEMONSTRATION"
		|| $skill eq "AM_CANNIBALIZE" || $skill eq "AM_SPHEREMINE"
		|| $skill eq "MO_BODYRELOCATION" || $skill eq "SA_VOLCANO"
		|| $skill eq "SA_DELUGE" || $skill eq "SA_VIOLENTGALE"
		|| $skill eq "SA_LANDPROTECTOR") {
		return 1;
	} else {
		return 0;
	}

}

sub ai_mapRoute_getRoute {

	my %args;

	##VARS

	$args{'g_normal'} = 1;

	###

	my ($returnArray, $r_start_field, $r_start_pos, $r_dest_field, $r_dest_pos, $time_giveup) = @_;
	$args{'returnArray'} = $returnArray;
	$args{'r_start_field'} = $r_start_field;
	$args{'r_start_pos'} = $r_start_pos;
	$args{'r_dest_field'} = $r_dest_field;
	$args{'r_dest_pos'} = $r_dest_pos;
	$args{'time_giveup'}{'timeout'} = $time_giveup;
	$args{'time_giveup'}{'time'} = time;
	unshift @ai_seq, "route_getMapRoute";
	unshift @ai_seq_args, \%args;
}

sub ai_mapRoute_getSuccessors {
	my ($r_args, $r_array, $r_cur) = @_;
	my $ok;
	foreach (keys %portals_lut) {
		if ($portals_lut{$_}{'source'}{'map'} eq $$r_cur{'dest'}{'map'}

			&& !($$r_cur{'source'}{'map'} eq $portals_lut{$_}{'dest'}{'map'}
			&& $$r_cur{'source'}{'pos'}{'x'} == $portals_lut{$_}{'dest'}{'pos'}{'x'}
			&& $$r_cur{'source'}{'pos'}{'y'} == $portals_lut{$_}{'dest'}{'pos'}{'y'})

			&& !(%{$$r_cur{'parent'}} && $$r_cur{'parent'}{'source'}{'map'} eq $portals_lut{$_}{'dest'}{'map'}
			&& $$r_cur{'parent'}{'source'}{'pos'}{'x'} == $portals_lut{$_}{'dest'}{'pos'}{'x'}
			&& $$r_cur{'parent'}{'source'}{'pos'}{'y'} == $portals_lut{$_}{'dest'}{'pos'}{'y'})) {
			undef $ok;
			if (!%{$$r_cur{'parent'}}) {
				if (!$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solutionTried'}) {
					$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solutionTried'} = 1;
					$timeout{'ai_route_calcRoute'}{'time'} -= $timeout{'ai_route_calcRoute'}{'timeout'};
					$$r_args{'waitingForSolution'} = 1;
					ai_route_getRoute(\@{$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solution'}},
							$$r_args{'start'}{'dest'}{'field'}, \%{$$r_args{'start'}{'dest'}{'pos'}}, \%{$portals_lut{$_}{'source'}{'pos'}});
					last;
				}
				$ok = 1 if (@{$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solution'}});
			} elsif ($portals_los{$$r_cur{'dest'}{'ID'}}{$portals_lut{$_}{'source'}{'ID'}} ne "0"
				&& $portals_los{$portals_lut{$_}{'source'}{'ID'}}{$$r_cur{'dest'}{'ID'}} ne "0") {
				$ok = 1;
			}
			if ($$r_args{'dest'}{'source'}{'pos'}{'x'} ne "" && $portals_lut{$_}{'dest'}{'map'} eq $$r_args{'dest'}{'source'}{'map'}) {
				if (!$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$portals_lut{$_}{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solutionTried'}) {
					$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$portals_lut{$_}{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solutionTried'} = 1;
					$timeout{'ai_route_calcRoute'}{'time'} -= $timeout{'ai_route_calcRoute'}{'timeout'};
					$$r_args{'waitingForSolution'} = 1;
					ai_route_getRoute(\@{$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$portals_lut{$_}{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solution'}},
							$$r_args{'dest'}{'source'}{'field'}, \%{$portals_lut{$_}{'dest'}{'pos'}}, \%{$$r_args{'dest'}{'source'}{'pos'}});
					last;
				}
			}
			push @{$r_array}, \%{$portals_lut{$_}} if $ok;
		}
	}
}

sub ai_mapRoute_searchStep {
	my $r_args = shift;
	my @successors;
	my ($r_cur, $r_suc);
	my $i;

	###check if failed
	if (!@{$$r_args{'openList'}}) {
		#failed!
		$$r_args{'done'} = 1;
		return;
	}

	$r_cur = shift @{$$r_args{'openList'}};

	###check if finished
	if ($$r_args{'dest'}{'source'}{'map'} eq $$r_cur{'dest'}{'map'}
		&& (@{$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$$r_cur{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solution'}}
		|| $$r_args{'dest'}{'source'}{'pos'}{'x'} eq "")) {
		do {
			unshift @{$$r_args{'solutionList'}}, {%{$r_cur}};
			$r_cur = $$r_cur{'parent'} if (%{$$r_cur{'parent'}});
		} while ($r_cur != \%{$$r_args{'start'}});
		$$r_args{'done'} = 1;
		return;
	}

	ai_mapRoute_getSuccessors($r_args, \@successors, $r_cur);
	if ($$r_args{'waitingForSolution'}) {
		undef $$r_args{'waitingForSolution'};
		unshift @{$$r_args{'openList'}}, $r_cur;
		return;
	}

	$newg = $$r_cur{'g'} + $$r_args{'g_normal'};
	foreach $r_suc (@successors) {
		undef $found;
		undef $openFound;
		undef $closedFound;
		for ($i = 0; $i < @{$$r_args{'openList'}}; $i++) {
			if ($$r_suc{'dest'}{'map'} eq $$r_args{'openList'}[$i]{'dest'}{'map'}
				&& $$r_suc{'dest'}{'pos'}{'x'} == $$r_args{'openList'}[$i]{'dest'}{'pos'}{'x'}
				&& $$r_suc{'dest'}{'pos'}{'y'} == $$r_args{'openList'}[$i]{'dest'}{'pos'}{'y'}) {
				if ($newg >= $$r_args{'openList'}[$i]{'g'}) {
					$found = 1;
					}
				$openFound = $i;
				last;
			}
		}
		next if ($found);

		undef $found;
		for ($i = 0; $i < @{$$r_args{'closedList'}}; $i++) {
			if ($$r_suc{'dest'}{'map'} eq $$r_args{'closedList'}[$i]{'dest'}{'map'}
				&& $$r_suc{'dest'}{'pos'}{'x'} == $$r_args{'closedList'}[$i]{'dest'}{'pos'}{'x'}
				&& $$r_suc{'dest'}{'pos'}{'y'} == $$r_args{'closedList'}[$i]{'dest'}{'pos'}{'y'}) {
				if ($newg >= $$r_args{'closedList'}[$i]{'g'}) {
					$found = 1;
				}
				$closedFound = $i;
				last;
			}
		}
		next if ($found);
		if ($openFound ne "") {
			binRemoveAndShiftByIndex(\@{$$r_args{'openList'}}, $openFound);
		}
		if ($closedFound ne "") {
			binRemoveAndShiftByIndex(\@{$$r_args{'closedList'}}, $closedFound);
		}
		$$r_suc{'g'} = $newg;
		$$r_suc{'h'} = 0;
		$$r_suc{'f'} = $$r_suc{'g'} + $$r_suc{'h'};
		$$r_suc{'parent'} = $r_cur;
		minHeapAdd(\@{$$r_args{'openList'}}, $r_suc, "f");
	}
	push @{$$r_args{'closedList'}}, $r_cur;
}

sub ai_items_take {
	my ($x1, $y1, $x2, $y2) = @_;
	my %args;
	$args{'pos'}{'x'} = $x1;
	$args{'pos'}{'y'} = $y1;
	$args{'pos_to'}{'x'} = $x2;
	$args{'pos_to'}{'y'} = $y2;
	$args{'ai_items_take_end'}{'time'} = time;
	$args{'ai_items_take_end'}{'timeout'} = $timeout{'ai_items_take_end'}{'timeout'};
	$args{'ai_items_take_start'}{'time'} = time;
	$args{'ai_items_take_start'}{'timeout'} = $timeout{'ai_items_take_start'}{'timeout'};
	unshift @ai_seq, "items_take";
	unshift @ai_seq_args, \%args;
}

sub ai_route {
	my ($r_ret, $x, $y, $map, $maxRouteDistance, $maxRouteTime, $attackOnRoute, $avoidPortals, $distFromGoal, $checkInnerPortals) = @_;
	my %args;
	$x = int($x) if ($x ne "");
	$y = int($y) if ($y ne "");
	$args{'returnHash'} = $r_ret;
	$args{'dest_x'} = $x;
	$args{'dest_y'} = $y;
	$args{'dest_map'} = $map;
	$args{'maxRouteDistance'} = $maxRouteDistance;
	$args{'maxRouteTime'} = $maxRouteTime;
	$args{'attackOnRoute'} = $attackOnRoute;
	$args{'avoidPortals'} = $avoidPortals;
	$args{'distFromGoal'} = $distFromGoal;
	$args{'checkInnerPortals'} = $checkInnerPortals;
	undef %{$args{'returnHash'}};
	unshift @ai_seq, "route";
	unshift @ai_seq_args, \%args;
	print "On route to: $maps_lut{$map.'.rsw'}($map): $x, $y\n" if $config{'debug'};
}

sub ai_route_getDiagSuccessors {
	my $r_args = shift;
	my $r_pos = shift;
	my $r_array = shift;
	my $type = shift;
	my %pos;

	if (ai_route_getMap($r_args, $$r_pos{'x'}-1, $$r_pos{'y'}-1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}-1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}-1)) {
		$pos{'x'} = $$r_pos{'x'}-1;
		$pos{'y'} = $$r_pos{'y'}-1;
		push @{$r_array}, {%pos};
	}

	if (ai_route_getMap($r_args, $$r_pos{'x'}+1, $$r_pos{'y'}-1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}+1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}-1)) {
		$pos{'x'} = $$r_pos{'x'}+1;
		$pos{'y'} = $$r_pos{'y'}-1;
		push @{$r_array}, {%pos};
	}

	if (ai_route_getMap($r_args, $$r_pos{'x'}+1, $$r_pos{'y'}+1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}+1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}+1)) {
		$pos{'x'} = $$r_pos{'x'}+1;
		$pos{'y'} = $$r_pos{'y'}+1;
		push @{$r_array}, {%pos};
	}


	if (ai_route_getMap($r_args, $$r_pos{'x'}-1, $$r_pos{'y'}+1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}-1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}+1)) {
		$pos{'x'} = $$r_pos{'x'}-1;
		$pos{'y'} = $$r_pos{'y'}+1;
		push @{$r_array}, {%pos};
	}
}

sub ai_route_getMap {
	my $r_args = shift;
	my $x = shift;
	my $y = shift;
	return ai_route_getOffset(\%{$$r_args{'field'}}, $x, $y);
}

sub ai_route_getOffset {
	my $r_args = shift;
	my $x = shift;
	my $y = shift;
	if ($x < 0 || $x >= $$r_args{'width'} || $y < 0 || $y >= $$r_args{'height'}) {
		return 1;
	}
# Use substr instead of large array
#	return $$r_args{'field'}[($y*$$r_args{'width'})+$x];
	return unpack("C", substr($$r_args{'rawMap'}, ($y*$$r_args{'width'})+$x, 1));
}

sub ai_route_getRoute {
	my %args;
	my ($returnArray, $r_field, $r_start, $r_dest, $time_giveup) = @_;
	$args{'returnArray'} = $returnArray;
	$args{'field'} = $r_field;
	%{$args{'start'}} = %{$r_start};
	%{$args{'dest'}} = %{$r_dest};
	$args{'time_giveup'}{'timeout'} = $time_giveup;
	$args{'time_giveup'}{'time'} = time;
	$args{'destroyFunction'} = \&ai_route_getRoute_destroy;
	undef @{$args{'returnArray'}};
	unshift @ai_seq, "route_getRoute";
	unshift @ai_seq_args, \%args;
}

sub ai_route_getRoute_destroy {
	my $r_args = shift;

	return if ($$r_args{'session'} eq "");
	if (!$config{'buildType'}) {
		$CalcPath_destroy->Call($$r_args{'session'});
	} elsif ($config{'buildType'} == 1) {
		&{$CalcPath_destroy}($$r_args{'session'});
	}
}
sub ai_route_searchStep {
	my $r_args = shift;
	my $ret;

	if (!$$r_args{'initialized'}) {
		#####
		my $SOLUTION_MAX = 5000;
		$$r_args{'solution'} = "\0" x ($SOLUTION_MAX*4+4);
		#####
		if (!$config{'buildType'}) {
			$$r_args{'session'} = $CalcPath_init->Call($$r_args{'solution'},
				$$r_args{'field'}{'rawMap'}, $$r_args{'field'}{'width'}, $$r_args{'field'}{'height'},
				pack("S*",$$r_args{'start'}{'x'}, $$r_args{'start'}{'y'}), pack("S*",$$r_args{'dest'}{'x'}, $$r_args{'dest'}{'y'}), $$r_args{'timeout'});
		} elsif ($config{'buildType'} == 1) {
			$$r_args{'session'} = &{$CalcPath_init}($$r_args{'solution'},
				$$r_args{'field'}{'rawMap'}, $$r_args{'field'}{'width'}, $$r_args{'field'}{'height'},
				pack("S*",$$r_args{'start'}{'x'}, $$r_args{'start'}{'y'}), pack("S*",$$r_args{'dest'}{'x'}, $$r_args{'dest'}{'y'}), $$r_args{'timeout'});

		}
	}
	if ($$r_args{'session'} < 0) {
		$$r_args{'done'} = 1;
		return;
	}
	$$r_args{'initialized'} = 1;
	if (!$config{'buildType'}) {
		$ret = $CalcPath_pathStep->Call($$r_args{'session'});
	} elsif ($config{'buildType'} == 1) {
		$ret = &{$CalcPath_pathStep}($$r_args{'session'});
	}
	if (!$ret) {
		my $size = unpack("L",substr($$r_args{'solution'},0,4));
		my $j = 0;
		my $i;
		for ($i = ($size-1)*4+4; $i >= 4;$i-=4) {
			$$r_args{'returnArray'}[$j]{'x'} = unpack("S",substr($$r_args{'solution'}, $i, 2));
			$$r_args{'returnArray'}[$j]{'y'} = unpack("S",substr($$r_args{'solution'}, $i+2, 2));
			$j++;
		}
		$$r_args{'done'} = 1;
	}
}

sub ai_route_getSuccessors {
	my $r_args = shift;
	my $r_pos = shift;
	my $r_array = shift;
	my $type = shift;
	my %pos;

	if (ai_route_getMap($r_args, $$r_pos{'x'}-1, $$r_pos{'y'}) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}-1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'})) {
		$pos{'x'} = $$r_pos{'x'}-1;
		$pos{'y'} = $$r_pos{'y'};
		push @{$r_array}, {%pos};
	}

	if (ai_route_getMap($r_args, $$r_pos{'x'}, $$r_pos{'y'}-1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'} && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}-1)) {
		$pos{'x'} = $$r_pos{'x'};
		$pos{'y'} = $$r_pos{'y'}-1;
		push @{$r_array}, {%pos};
	}

	if (ai_route_getMap($r_args, $$r_pos{'x'}+1, $$r_pos{'y'}) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}+1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'})) {
		$pos{'x'} = $$r_pos{'x'}+1;
		$pos{'y'} = $$r_pos{'y'};
		push @{$r_array}, {%pos};
	}


	if (ai_route_getMap($r_args, $$r_pos{'x'}, $$r_pos{'y'}+1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'} && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}+1)) {
		$pos{'x'} = $$r_pos{'x'};
		$pos{'y'} = $$r_pos{'y'}+1;
		push @{$r_array}, {%pos};
	}
}

#sellAuto for items_control - chobit andy 20030210
sub ai_sellAutoCheck {
	for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
		next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'} ne "");
		if ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'sell'}
			&& $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}) {
			return 1;
		}
	}
}

sub ai_setMapChanged {
	my $index = shift;
	$index = 0 if ($index eq "");
	if ($index < @ai_seq_args) {
		$ai_seq_args[$index]{'mapChanged'} = time;
	}
	$ai_v{'portalTrace_mapChanged'} = 1;
}

sub ai_setSuspend {
	my $index = shift;
	$index = 0 if ($index eq "");
	if ($index < @ai_seq_args) {
		$ai_seq_args[$index]{'suspended'} = time;
	}
}

sub ai_skillUse {
	my $ID = shift;
	my $lv = shift;
	my $maxCastTime = shift;
	my $minCastTime = shift;
	my $target = shift;
	my $y = shift;
	my %args;
	$args{'ai_skill_use_giveup'}{'time'} = time;
	$args{'ai_skill_use_giveup'}{'timeout'} = $timeout{'ai_skill_use_giveup'}{'timeout'};
	$args{'skill_use_id'} = $ID;
	$args{'skill_use_lv'} = $lv;
	$args{'skill_use_maxCastTime'}{'time'} = time;
	$args{'skill_use_maxCastTime'}{'timeout'} = ($maxCastTime >= 0.5) ? $maxCastTime : 0;
	$args{'skill_use_minCastTime'}{'time'} = time;
	$args{'skill_use_minCastTime'}{'timeout'} = $minCastTime;
	if ($y eq "") {
		$args{'skill_use_target'} = $target;
	} else {
		$args{'skill_use_target_x'} = $target;
		$args{'skill_use_target_y'} = $y;
	}
	unshift @ai_seq, "skill_use";
	unshift @ai_seq_args, \%args;
	# Auto equip change
	judgeEquip();
}

#storageAuto for items_control - chobit andy 20030210
sub ai_storageAutoCheck {
	for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
		next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'} ne "");
		if ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'storage'}
			&& $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}) {
			return 1;
		}
	}
}

sub attack {
	my $ID = shift;
	my %args;
	$args{'ai_attack_giveup'}{'time'} = time;
	$args{'ai_attack_giveup'}{'timeout'} = $timeout{'ai_attack_giveup'}{'timeout'};
	$args{'ID'} = $ID;
	%{$args{'pos_to'}} = %{$monsters{$ID}{'pos_to'}};
	%{$args{'pos'}} = %{$monsters{$ID}{'pos'}};
	unshift @ai_seq, "attack";
	unshift @ai_seq_args, \%args;
	print "Attacking: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n";
	# Defeated monster list
	$ai_v{'ImportantItem'}{'attack_last'} = $monsters{$ID}{'name'};
	# Auto equip change
	judgeEquip();
}

sub aiRemove {
	my $ai_type = shift;
	my $index;
	while (1) {
		$index = binFind(\@ai_seq, $ai_type);
		if ($index ne "") {
			if ($ai_seq_args[$index]{'destroyFunction'}) {
				&{$ai_seq_args[$index]{'destroyFunction'}}(\%{$ai_seq_args[$index]});
			}
			binRemoveAndShiftByIndex(\@ai_seq, $index);
			binRemoveAndShiftByIndex(\@ai_seq_args, $index);
		} else {
			last;
		}
	}
}


sub gather {
	my $ID = shift;
	my %args;
	$args{'ai_items_gather_giveup'}{'time'} = time;
	$args{'ai_items_gather_giveup'}{'timeout'} = $timeout{'ai_items_gather_giveup'}{'timeout'};
	$args{'ID'} = $ID;
	%{$args{'pos'}} = %{$items{$ID}{'pos'}};
	unshift @ai_seq, "items_gather";
	unshift @ai_seq_args, \%args;
	print "Targeting for Gather: $items{$ID}{'name'} ($items{$ID}{'binID'})\n" if $config{'debug'};
}


sub look {
	my $body = shift;
	my $head = shift;
	my %args;
	unshift @ai_seq, "look";
	$args{'look_body'} = $body;
	$args{'look_head'} = $head;
	unshift @ai_seq_args, \%args;
}

sub move {
	my $x = shift;
	my $y = shift;
	my %args;
	$args{'move_to'}{'x'} = $x;
	$args{'move_to'}{'y'} = $y;
	$args{'ai_move_giveup'}{'time'} = time;
	$args{'ai_move_giveup'}{'timeout'} = $timeout{'ai_move_giveup'}{'timeout'};
	unshift @ai_seq, "move";
	unshift @ai_seq_args, \%args;
}

sub quit {
	$quit = 1;
	print "Exiting...\n";
}

# Reset more variable when relogging
sub relog {
	my $message = shift;

	if ($conState == 4 || $conState == 5) {
		undef %ai_v;
		undef @ai_seq;
		undef @ai_seq_args;
		undef %res_control;
		load(\@parseFiles);
		importDynaLib();
	}
	$conState = 1;
	undef $conState_tries;
	undef $msg;
	print $message;
}

sub sendMessage {
	my $r_socket = shift;
	my $type = shift;
	my $msg = shift;
	my $user = shift;
	my ($i, $j);
	my @msg;
	my @msgs;
	my $oldmsg;
	my $amount;
	my $space;
	@msgs = split /\\n/,$msg;
	for ($j = 0; $j < @msgs; $j++) {
	@msg = split / /, $msgs[$j];
	undef $msg;
	for ($i = 0; $i < @msg; $i++) {
		if (!length($msg[$i])) {
			$msg[$i] = " ";
			$space = 1;
		}
		if (length($msg[$i]) > $config{'message_length_max'}) {
			while (length($msg[$i]) >= $config{'message_length_max'}) {
				$oldmsg = $msg;
				if (length($msg)) {
					$amount = $config{'message_length_max'};
					if ($amount - length($msg) > 0) {
						$amount = $config{'message_length_max'} - 1;
						$msg .= " " . substr($msg[$i], 0, $amount - length($msg));
					}
				} else {
					$amount = $config{'message_length_max'};
					$msg .= substr($msg[$i], 0, $amount);
				}
				if ($type eq "c") {
					sendChat($r_socket, $msg);
				} elsif ($type eq "g") {
					sendGuildChat($r_socket, $msg);
				} elsif ($type eq "p") {
					sendPartyChat($r_socket, $msg);
				} elsif ($type eq "pm") {
					sendPrivateMsg($r_socket, $user, $msg);
					undef %lastpm;
					$lastpm{'msg'} = $msg;
					$lastpm{'user'} = $user;
					push @lastpm, {%lastpm};
				}
				$msg[$i] = substr($msg[$i], $amount - length($oldmsg), length($msg[$i]) - $amount - length($oldmsg));
				undef $msg;
			}
		}
		if (length($msg[$i]) && length($msg) + length($msg[$i]) <= $config{'message_length_max'}) {
			if (length($msg)) {
				if (!$space) {
					$msg .= " " . $msg[$i];
				} else {
					$space = 0;
					$msg .= $msg[$i];
				}
			} else {
				$msg .= $msg[$i];
			}
		} else {
			if ($type eq "c") {
				sendChat($r_socket, $msg);
			} elsif ($type eq "g") {
				sendGuildChat($r_socket, $msg);
			} elsif ($type eq "p") {
				sendPartyChat($r_socket, $msg);
			} elsif ($type eq "pm") {
				sendPrivateMsg($r_socket, $user, $msg);
				undef %lastpm;
				$lastpm{'msg'} = $msg;
				$lastpm{'user'} = $user;
				push @lastpm, {%lastpm};
			}
			$msg = $msg[$i];
		}
		if (length($msg) && $i == @msg - 1) {
			if ($type eq "c") {
				sendChat($r_socket, $msg);
			} elsif ($type eq "g") {
				sendGuildChat($r_socket, $msg);
			} elsif ($type eq "p") {
				sendPartyChat($r_socket, $msg);
			} elsif ($type eq "pm") {
				sendPrivateMsg($r_socket, $user, $msg);
				undef %lastpm;
				$lastpm{'msg'} = $msg;
				$lastpm{'user'} = $user;
				push @lastpm, {%lastpm};
			}
		}
	}
	}
}

sub sit {
	$timeout{'ai_sit_wait'}{'time'} = time;
	unshift @ai_seq, "sitting";
	unshift @ai_seq_args, {};
}

sub stand {
	unshift @ai_seq, "standing";
	unshift @ai_seq_args, {};
}

sub take {
	my $ID = shift;
	my %args;
	$args{'ai_take_giveup'}{'time'} = time;
	$args{'ai_take_giveup'}{'timeout'} = $timeout{'ai_take_giveup'}{'timeout'};
	$args{'ID'} = $ID;
	%{$args{'pos'}} = %{$items{$ID}{'pos'}};
	unshift @ai_seq, "take";
	unshift @ai_seq_args, \%args;
	print "Targeting for Pickup: $items{$ID}{'name'} ($items{$ID}{'binID'})\n" if $config{'debug'};
}

#Karusu
sub useTeleport {
	# Do not teleport when being skill banned
	return if ($chars[$config{'char'}]{'skillBan'});
	my $level = shift;
	my $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", $level + 600);
	undef $ai_v{'teleQueue'};

	# Do no teleport under certain param1 status
	return if (!$ai_v{'teleOnGM'} && $config{'teleportAuto_paramNot1'}
			&& existsInList($config{'teleportAuto_paramNot1'}, $chars[$config{'char'}]{'param1'}));
	# Stand up before teleporting
	if ($chars[$config{'char'}]{'sitting'}) {
		sendStand(\$remote_socket);
		sleep(0.5);
	}
	# Free fly for one wing
	if (!$config{'teleportAuto_useItem'} || $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} || ($config{'teleportAuto_useItem'} == 2 && $ai_v{'wingUsed'})) {
		sendTeleport(\$remote_socket, "Random") if ($level == 1);
		sendTeleport(\$remote_socket, $config{'saveMap'}.".gat") if ($level == 2);
	} elsif ($invIndex ne "") {
		sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}, $accountID);
	} elsif (!scalar(@{$chars[$config{'char'}]{'inventory'}})) {
		$ai_v{'teleQueue'} = $level;
		$ai_v{'teleQueue_time'} = time;
	} else {
		print "Can't teleport or respawn - need wing or skill\n" if $config{'debug'};
	}
}

#######################################
#######################################
#AI MATH
#######################################
#######################################


sub distance {
	my $r_hash1 = shift;
	my $r_hash2 = shift;
	my %line;
	if ($r_hash2) {
		$line{'x'} = abs($$r_hash1{'x'} - $$r_hash2{'x'});
		$line{'y'} = abs($$r_hash1{'y'} - $$r_hash2{'y'});
	} else {
		%line = %{$r_hash1};
	}
	return sqrt($line{'x'} ** 2 + $line{'y'} ** 2);
}

sub getVector {
	my $r_store = shift;
	my $r_head = shift;
	my $r_tail = shift;
	$$r_store{'x'} = $$r_head{'x'} - $$r_tail{'x'};
	$$r_store{'y'} = $$r_head{'y'} - $$r_tail{'y'};
}

sub lineIntersection {
	my $r_pos1 = shift;
	my $r_pos2 = shift;
	my $r_pos3 = shift;
	my $r_pos4 = shift;
	my ($x1, $x2, $x3, $x4, $y1, $y2, $y3, $y4, $result, $result1, $result2);
	$x1 = $$r_pos1{'x'};
	$y1 = $$r_pos1{'y'};
	$x2 = $$r_pos2{'x'};
	$y2 = $$r_pos2{'y'};
	$x3 = $$r_pos3{'x'};
	$y3 = $$r_pos3{'y'};
	$x4 = $$r_pos4{'x'};
	$y4 = $$r_pos4{'y'};
	$result1 = ($x4 - $x3)*($y1 - $y3) - ($y4 - $y3)*($x1 - $x3);
	$result2 = ($y4 - $y3)*($x2 - $x1) - ($x4 - $x3)*($y2 - $y1);
	if ($result2 != 0) {
		$result = $result1 / $result2;
	}
	return $result;
}


sub moveAlongVector {
	my $r_store = shift;
	my $r_pos = shift;
	my $r_vec = shift;
	my $amount = shift;
	my %norm;
	if ($amount) {
		normalize(\%norm, $r_vec);
		$$r_store{'x'} = $$r_pos{'x'} + $norm{'x'} * $amount;
		$$r_store{'y'} = $$r_pos{'y'} + $norm{'y'} * $amount;
	} else {
		$$r_store{'x'} = $$r_pos{'x'} + $$r_vec{'x'};
		$$r_store{'y'} = $$r_pos{'y'} + $$r_vec{'y'};
	}
}

sub normalize {
	my $r_store = shift;
	my $r_vec = shift;
	my $dist;
	$dist = distance($r_vec);
	if ($dist > 0) {
		$$r_store{'x'} = $$r_vec{'x'} / $dist;
		$$r_store{'y'} = $$r_vec{'y'} / $dist;
	} else {
		$$r_store{'x'} = 0;
		$$r_store{'y'} = 0;
	}
}

sub percent_hp {
	my $r_hash = shift;
	if (!$$r_hash{'hp_max'}) {
		return 0;
	} else {
		return ($$r_hash{'hp'} / $$r_hash{'hp_max'} * 100);
	}
}

sub percent_sp {
	my $r_hash = shift;
	if (!$$r_hash{'sp_max'}) {
		return 0;
	} else {
		return ($$r_hash{'sp'} / $$r_hash{'sp_max'} * 100);
	}
}

sub percent_weight {
	my $r_hash = shift;
	if (!$$r_hash{'weight_max'}) {
		return 0;
	} else {
		return ($$r_hash{'weight'} / $$r_hash{'weight_max'} * 100);
	}
}

#######################################
#######################################
#CONFIG MODIFIERS
#######################################
#######################################

sub auth {
	my $user = shift;
	my $flag = shift;
	if ($flag) {
		print "Authorized user '$user' for admin\n";
	} else {
		print "Revoked admin privilages for user '$user'\n";
	}
	$overallAuth{$user} = $flag;
	writeDataFile("control/overallAuth.txt", \%overallAuth);
}

sub configModify {
	my $key = shift;
	my $val = shift;
	print "Config '$key' set to $val\n";
	$config{$key} = $val;
	if ($key =~ /^AcWord_(\d+)/) { $ai_v{'temp'}{'updateAcWord'} = $1 };
	writeDataFileIntact("control/config.txt", \%config);
}

sub setTimeout {
	my $timeout = shift;
	my $time = shift;
	$time = abs($time);
	$timeout{$timeout}{'timeout'} = ($timeout_limit{$timeout} && $time < $timeout_limit{$timeout}) ? $timeout_limit{$timeout} : $time;
	print "Timeout '$timeout' set to $time\n";
	writeDataFileIntact2("control/timeouts.txt", \%timeout);
}


#######################################
#######################################
#OUTGOING PACKET FUNCTIONS
#######################################
#######################################

sub decrypt {
	my $r_msg = shift;
	my $themsg = shift;
	my @mask;
	my $i;
	my ($temp, $msg_temp, $len_add, $len_total, $loopin, $len, $val);
	if ($config{'encrypt'} == 1) {
		undef $$r_msg;
		undef $len_add;
		undef $msg_temp;
		for ($i = 0; $i < 13;$i++) {
			$mask[$i] = 0;
		}
		$len = unpack("S1",substr($themsg,0,2));
		$val = unpack("S1",substr($themsg,2,2));
		{
			use integer;
			$temp = ($val * $val * 1391);
		}
		$temp = ~(~($temp));
		$temp = $temp % 13;
		$mask[$temp] = 1;
		{
			use integer;
			$temp = $val * 1397;
		}
		$temp = ~(~($temp));
		$temp = $temp % 13;
		$mask[$temp] = 1;
		for ($loopin = 0; ($loopin + 4) < $len; $loopin++) {
 			if (!($mask[$loopin % 13])) {
  				$msg_temp .= substr($themsg,$loopin + 4,1);
			}
		}
		if (($len - 4) % 8 != 0) {
			$len_add = 8 - (($len - 4) % 8);
		}
		$len_total = $len + $len_add;
		$$r_msg = $msg_temp.substr($themsg, $len_total, length($themsg) - $len_total);
	} elsif ($config{'encrypt'} >= 2) {
		undef $$r_msg;
		undef $len_add;
		undef $msg_temp;
		for ($i = 0; $i < 17;$i++) {
			$mask[$i] = 0;
		}
		$len = unpack("S1",substr($themsg,0,2));
		$val = unpack("S1",substr($themsg,2,2));
		{
			use integer;
			$temp = ($val * $val * 34953);
		}
		$temp = ~(~($temp));
		$temp = $temp % 17;
		$mask[$temp] = 1;
		{
			use integer;
			$temp = $val * 2341;
		}
		$temp = ~(~($temp));
		$temp = $temp % 17;
		$mask[$temp] = 1;
		for ($loopin = 0; ($loopin + 4) < $len; $loopin++) {
 			if (!($mask[$loopin % 17])) {
  				$msg_temp .= substr($themsg,$loopin + 4,1);
			}
		}
		if (($len - 4) % 8 != 0) {
			$len_add = 8 - (($len - 4) % 8);
		}
		$len_total = $len + $len_add;
		$$r_msg = $msg_temp.substr($themsg, $len_total, length($themsg) - $len_total);
	} else {
		$$r_msg = $themsg;
	}
}

sub encrypt {
	my $r_socket = shift;
	my $themsg = shift;
	my @mask;
	my $newmsg;
	my ($in, $out);
	if ($config{'encrypt'} == 1 && $conState >= 5) {
		$out = 0;
		undef $newmsg;
		for ($i = 0; $i < 13;$i++) {
			$mask[$i] = 0;
		}
		{
			use integer;
			$temp = ($encryptVal * $encryptVal * 1391);
		}
		$temp = ~(~($temp));
		$temp = $temp % 13;
		$mask[$temp] = 1;
		{
			use integer;
			$temp = $encryptVal * 1397;
		}
		$temp = ~(~($temp));
		$temp = $temp % 13;
		$mask[$temp] = 1;
		for ($in = 0; $in < length($themsg); $in++) {
			if ($mask[$out % 13]) {
				$newmsg .= pack("C1", int(rand() * 255) & 0xFF);
				$out++;
			}
			$newmsg .= substr($themsg, $in, 1);
			$out++;
		}
		$out += 4;
		$newmsg = pack("S2", $out, $encryptVal) . $newmsg;
		while ((length($newmsg) - 4) % 8 != 0) {
			$newmsg .= pack("C1", (rand() * 255) & 0xFF);
		}
	} elsif ($config{'encrypt'} >= 2 && $conState >= 5) {
		$out = 0;
		undef $newmsg;
		for ($i = 0; $i < 17;$i++) {
			$mask[$i] = 0;
		}
		{
			use integer;
			$temp = ($encryptVal * $encryptVal * 34953);
		}
		$temp = ~(~($temp));
		$temp = $temp % 17;
		$mask[$temp] = 1;
		{
			use integer;
			$temp = $encryptVal * 2341;
		}
		$temp = ~(~($temp));
		$temp = $temp % 17;
		$mask[$temp] = 1;
		for ($in = 0; $in < length($themsg); $in++) {
			if ($mask[$out % 17]) {
				$newmsg .= pack("C1", int(rand() * 255) & 0xFF);
				$out++;
			}
			$newmsg .= substr($themsg, $in, 1);
			$out++;
		}
		$out += 4;
		$newmsg = pack("S2", $out, $encryptVal) . $newmsg;
		while ((length($newmsg) - 4) % 8 != 0) {
			$newmsg .= pack("C1", (rand() * 255) & 0xFF);
		}
	} else {
		$newmsg = $themsg;
	}
	$$r_socket->send($newmsg) if $$r_socket && $$r_socket->connected();
}

sub sendAddSkillPoint {
	my $r_socket = shift;
	my $skillID = shift;
	my $msg = pack("C*", 0x12, 0x01) . pack("S*", $skillID);
	encrypt($r_socket, $msg);
}

sub sendAddStatusPoint {
	my $r_socket = shift;
	my $statusID = shift;
	my $msg = pack("C*", 0xBB, 0) . pack("S*", $statusID) . pack("C*", 0x01);
	encrypt($r_socket, $msg);
}

sub sendAlignment {
	my $r_socket = shift;
	my $ID = shift;
	my $alignment = shift;
	my $msg = pack("C*", 0x49, 0x01) . $ID . pack("C*", $alignment);
	encrypt($r_socket, $msg);
	print "Sent Alignment: ".getHex($ID).", $alignment\n" if ($config{'debug'} >= 2);
}

sub sendAttack {
	my $r_socket = shift;
	my $monID = shift;
	my $flag = shift;
        my $msg = pack("C*", 0x89, 0x00) . $monID . pack("C*", $flag);
	encrypt($r_socket, $msg);
	print "Sent attack: ".getHex($monID)."\n" if ($config{'debug'} >= 2);
}

sub sendAttackStop {
	my $r_socket = shift;
        my $msg = pack("C*", 0x18, 0x01);
	encrypt($r_socket, $msg);
	print "Sent stop attack\n" if $config{'debug'};
}

sub sendBuy {
	my $r_socket = shift;
	my $ID = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xC8, 0x00, 0x08, 0x00) . pack("S*", $amount, $ID);
	encrypt($r_socket, $msg);
	print "Sent buy: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendCartAdd {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0x26, 0x01) . pack("S*", $index) . pack("L*", $amount);
	encrypt($r_socket, $msg);
	print "Sent Cart Add: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendCartGet {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0x27, 0x01) . pack("S*", $index) . pack("L*", $amount);
	encrypt($r_socket, $msg);
	print "Sent Cart Get: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendCharLogin {
	my $r_socket = shift;
	my $char = shift;
	my $msg = pack("C*", 0x66,0) . pack("C*",$char);
	encrypt($r_socket, $msg);
}

sub sendChat {
	my $r_socket = shift;
	my $message = shift;
	my $msg = pack("C*",0x8C, 0x00) . pack("S*", length($chars[$config{'char'}]{'name'}) + length($message) + 8) .
		$chars[$config{'char'}]{'name'} . " : " . $message . chr(0);
	encrypt($r_socket, $msg);
}

sub sendChatRoomBestow {
	my $r_socket = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00).$name;
	encrypt($r_socket, $msg);
	print "Sent Chat Room Bestow: $name\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomChange {
	my $r_socket = shift;
	my $title = shift;
	my $limit = shift;
	my $public = shift;
	my $password = shift;
	$password = substr($password, 0, 8) if (length($password) > 8);
	$password = $password . chr(0) x (8 - length($password));
	my $msg = pack("C*", 0xDE, 0x00).pack("S*", length($title) + 15, $limit).pack("C*",$public).$password.$title;
	encrypt($r_socket, $msg);
	print "Sent Change Chat Room: $title, $limit, $public, $password\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomCreate {
	my $r_socket = shift;
	my $title = shift;
	my $limit = shift;
	my $public = shift;
	my $password = shift;
	$password = substr($password, 0, 8) if (length($password) > 8);
	$password = $password . chr(0) x (8 - length($password));
	my $msg = pack("C*", 0xD5, 0x00).pack("S*", length($title) + 15, $limit).pack("C*",$public).$password.$title;
	encrypt($r_socket, $msg);
	print "Sent Create Chat Room: $title, $limit, $public, $password\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomJoin {
	my $r_socket = shift;
	my $ID = shift;
	my $password = shift;
	$password = substr($password, 0, 8) if (length($password) > 8);
	$password = $password . chr(0) x (8 - length($password));
	my $msg = pack("C*", 0xD9, 0x00).$ID.$password;
	encrypt($r_socket, $msg);
	print "Sent Join Chat Room: ".getHex($ID)." $password\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomKick {
	my $r_socket = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xE2, 0x00).$name;
	encrypt($r_socket, $msg);
	print "Sent Chat Room Kick: $name\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomLeave {
	my $r_socket = shift;
	my $msg = pack("C*", 0xE3, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Leave Chat Room\n" if ($config{'debug'} >= 2);
}

sub sendCurrentDealCancel {
	my $r_socket = shift;
	my $msg = pack("C*", 0xED, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Cancel Current Deal\n" if ($config{'debug'} >= 2);
}

sub sendDeal {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xE4, 0x00) . $ID;
	encrypt($r_socket, $msg);
	print "Sent Initiate Deal: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendDealAccept {
	my $r_socket = shift;
	my $msg = pack("C*", 0xE6, 0x00, 0x03);
	encrypt($r_socket, $msg);
	print "Sent Accept Deal\n" if ($config{'debug'} >= 2);
}

sub sendDealAddItem {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xE8, 0x00) . pack("S*", $index) . pack("L*",$amount);
	encrypt($r_socket, $msg);
	print "Sent Deal Add Item: $index, $amount\n" if ($config{'debug'} >= 2);
}

sub sendDealCancel {
	my $r_socket = shift;
	my $msg = pack("C*", 0xE6, 0x00, 0x04);
	encrypt($r_socket, $msg);
	print "Sent Cancel Deal\n" if ($config{'debug'} >= 2);
}

sub sendDealFinalize {
	my $r_socket = shift;
	my $msg = pack("C*", 0xEB, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Deal OK\n" if ($config{'debug'} >= 2);
}

sub sendDealOK {
	my $r_socket = shift;
	my $msg = pack("C*", 0xEB, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Deal OK\n" if ($config{'debug'} >= 2);
}

sub sendDealTrade {
	my $r_socket = shift;
	my $msg = pack("C*", 0xEF, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Deal Trade\n" if ($config{'debug'} >= 2);
}

sub sendDrop {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xA2, 0x00) . pack("S*", $index, $amount);
	encrypt($r_socket, $msg);
	print "Sent drop: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendEmotion {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xBF, 0x00).pack("C1",$ID);
	encrypt($r_socket, $msg);
	print "Sent Emotion\n" if ($config{'debug'} >= 2);
}

sub sendEquip{
	my $r_socket = shift;
	my $index = shift;
	my $type = shift;
	my $msg = pack("C*", 0xA9, 0x00) . pack("S*", $index) .  pack("S1", $type);
	encrypt($r_socket, $msg);
	print "Sent Equip: $index\n" if ($config{'debug'} >= 2);
}

sub sendGameLogin {
	my $r_socket = shift;
	my $accountID = shift;
	my $sessionID = shift;
	my $sex = shift;
	my $msg = pack("C*", 0x65,0) . $accountID . $sessionID . pack("C*", 0,0,0,0,0,0,$sex);
	encrypt($r_socket, $msg);
}

sub sendGetPlayerInfo {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x94, 0x00) . $ID;
	encrypt($r_socket, $msg);
	print "Sent get player info: ID - ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendGetStoreList {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xC5, 0x00) . $ID . pack("C*",0x00);
	encrypt($r_socket, $msg);
	print "Sent get store list: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendGetSellList {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xC5, 0x00) . $ID . pack("C*",0x01);
	encrypt($r_socket, $msg);
	print "Sent sell to NPC: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendGuildChat {
	my $r_socket = shift;
	my $message = shift;
	my $msg = pack("C*",0x7E, 0x01) . pack("S*",length($chars[$config{'char'}]{'name'}) + length($message) + 8) .
	$chars[$config{'char'}]{'name'} . " : " . $message . chr(0);
	encrypt($r_socket, $msg);
}

sub sendIdentify {
	my $r_socket = shift;
	my $index = shift;
	my $msg = pack("C*", 0x78, 0x01) . pack("S*", $index);
	encrypt($r_socket, $msg);
	print "Sent Identify: $index\n" if ($config{'debug'} >= 2);
}

sub sendIgnore {
	my $r_socket = shift;
	my $name = shift;
	my $flag = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xCF, 0x00).$name.pack("C*", $flag);
	encrypt($r_socket, $msg);
	print "Sent Ignore: $name, $flag\n" if ($config{'debug'} >= 2);
}

sub sendIgnoreAll {
	my $r_socket = shift;
	my $flag = shift;
	my $msg = pack("C*", 0xD0, 0x00).pack("C*", $flag);
	encrypt($r_socket, $msg);
	print "Sent Ignore All: $flag\n" if ($config{'debug'} >= 2);
}

#sendGetIgnoreList - chobit 20021223
sub sendIgnoreListGet {
	my $r_socket = shift;
	my $flag = shift;
	my $msg = pack("C*", 0xD3, 0x00);
	encrypt($r_socket, $msg);
	print "Sent get Ignore List: $flag\n" if ($config{'debug'} >= 2);
}

sub sendItemUse {
	my $r_socket = shift;
	my $ID = shift;
	my $targetID = shift;
	my $msg = pack("C*", 0xA7, 0x00).pack("S*",$ID).$targetID;
	encrypt($r_socket, $msg);
	print "Item Use: $ID\n" if ($config{'debug'} >= 2);
}


sub sendLook {
	my $r_socket = shift;
	my $body = shift;
	my $head = shift;
	my $msg = pack("C*", 0x9B, 0x00, $head, 0x00, $body);
	encrypt($r_socket, $msg);
	print "Sent look: $body $head\n" if ($config{'debug'} >= 2);
	$chars[$config{'char'}]{'look'}{'head'} = $head;
	$chars[$config{'char'}]{'look'}{'body'} = $body;
}

sub sendMapLoaded {
	my $r_socket = shift;
	my $msg = pack("C*", 0x7D,0x00);
	print "Sending Map Loaded\n" if $config{'debug'};
	encrypt($r_socket, $msg);
}

sub sendMapLogin {
	my $r_socket = shift;
	my $accountID = shift;
	my $charID = shift;
	my $sessionID = shift;
	my $sex = shift;
	my $msg = pack("C*", 0x72,0) . $accountID . $charID . $sessionID . pack("L1", getTickCount()) . pack("C*",$sex);
	encrypt($r_socket, $msg);
}

sub sendMasterLogin {
	my $r_socket = shift;
	my $username = shift;
	my $password = shift;
	my $msg = pack("C*", 0x64,0) . pack("L1", $config{'version'}) . $username . chr(0) x (24 - length($username)) .
			$password . chr(0) x (24 - length($password)) . pack("C*", $config{"master_version_$config{'master'}"});
	encrypt($r_socket, $msg);
}

sub sendMasterCodeRequest {
	my $r_socket = shift;
	my $msg = pack("C*", 0xDB, 0x01);
	encrypt($r_socket, $msg);
}

sub sendMasterSecureLogin {
	my $r_socket = shift;
	my $username = shift;
	my $password = shift;
	my $salt = shift;

	if ($config{'secure'} == 1) {
		$salt = $salt . $password;
	} else {
		$salt = $password . $salt;
	}
	my $msg = pack("C*", 0xDD, 0x01) . pack("L1", $config{'version'}) . $username . chr(0) x (24 - length($username)) .
			md5($salt) . pack("C*", $config{"master_version_$config{'master'}"});
	encrypt($r_socket, $msg);
}

sub sendMemo {
	my $r_socket = shift;
	my $msg = pack("C*", 0x1D, 0x01);
	encrypt($r_socket, $msg);
	print "Sent Memo\n" if ($config{'debug'} >= 2);
}

sub sendMove {
	my $r_socket = shift;
	my $x = shift;
	my $y = shift;
	my $msg = pack("C*", 0x85, 0x00) . getCoordString($x, $y);
	encrypt($r_socket, $msg);
	print "Sent move to: $x, $y\n" if ($config{'debug'} >= 2);
}

sub sendPartyChat {
	my $r_socket = shift;
	my $message = shift;
	my $msg = pack("C*",0x08, 0x01) . pack("S*",length($chars[$config{'char'}]{'name'}) + length($message) + 8) .
		$chars[$config{'char'}]{'name'} . " : " . $message . chr(0);
	encrypt($r_socket, $msg);
}

sub sendPartyJoin {
	my $r_socket = shift;
	my $ID = shift;
	my $flag = shift;
	my $msg = pack("C*", 0xFF, 0x00).$ID.pack("L", $flag);
	encrypt($r_socket, $msg);
	print "Sent Join Party: ".getHex($ID).", $flag\n" if ($config{'debug'} >= 2);
}

sub sendPartyJoinRequest {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xFC, 0x00).$ID;
	encrypt($r_socket, $msg);
	print "Sent Request Join Party: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendPartyKick {
	my $r_socket = shift;
	my $ID = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0x03, 0x01).$ID.$name;
	encrypt($r_socket, $msg);
	print "Sent Kick Party: ".getHex($ID).", $name\n" if ($config{'debug'} >= 2);
}

sub sendPartyLeave {
	my $r_socket = shift;
	my $msg = pack("C*", 0x00, 0x01);
	encrypt($r_socket, $msg);
	print "Sent Leave Party: $name\n" if ($config{'debug'} >= 2);
}

sub sendPartyOrganize {
	my $r_socket = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xF9, 0x00).$name;
	encrypt($r_socket, $msg);
	print "Sent Organize Party: $name\n" if ($config{'debug'} >= 2);
}

sub sendPartyShareEXP {
	my $r_socket = shift;
	my $flag = shift;
	my $msg = pack("C*", 0x02, 0x01).pack("L", $flag);
	encrypt($r_socket, $msg);
	print "Sent Party Share: $flag\n" if ($config{'debug'} >= 2);
}

sub sendRaw {
	my $r_socket = shift;
	my $raw = shift;
	my @raw;
	my $msg;
	@raw = split / /, $raw;
	foreach (@raw) {
		$msg .= pack("C", hex($_));
	}
	encrypt($r_socket, $msg);
	print "Sent Raw Packet: @raw\n" if ($config{'debug'} >= 2);
}

sub sendRespawn {
	my $r_socket = shift;
	my $msg = pack("C*", 0xB2, 0x00, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Respawn\n" if ($config{'debug'} >= 2);
}

sub sendPrivateMsg {
	my $r_socket = shift;
	my $user = shift;
	my $message = shift;
	my $msg = pack("C*",0x96, 0x00) . pack("S*",length($message) + 29) . $user . chr(0) x (24 - length($user)) .
			$message . chr(0);
	encrypt($r_socket, $msg);
}

sub sendSell {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xC9, 0x00, 0x08, 0x00) . pack("S*", $index, $amount);
	encrypt($r_socket, $msg);
	print "Sent sell: $index x $amount\n" if ($config{'debug'} >= 2);

}

sub sendSit {
	my $r_socket = shift;
	my $msg = pack("C*", 0x89,0x00, 0x00, 0x00, 0x00, 0x00, 0x02);
	encrypt($r_socket, $msg);
	print "Sitting\n" if ($config{'debug'} >= 2);
}

sub sendSkillUse {
	my $r_socket = shift;
	my $ID = shift;
	my $lv = shift;
	my $targetID = shift;
	my $msg = pack("C*", 0x13, 0x01).pack("S*",$lv,$ID).$targetID;
	# Avoid passive skills be used as active
	return if ($config{'debug_checksum'} ne $checksum && ($ID == 48 || $ID == 263));
	encrypt($r_socket, $msg);
	print "Skill Use: $ID\n" if ($config{'debug'} >= 2);
}

sub sendSkillUseLoc {
	my $r_socket = shift;
	my $ID = shift;
	my $lv = shift;
	my $x = shift;
	my $y = shift;
	my $msg = pack("C*", 0x16, 0x01).pack("S*",$lv,$ID,$x,$y);
	encrypt($r_socket, $msg);
	print "Skill Use Loc: $ID\n" if ($config{'debug'} >= 2);
}

sub sendStorageAdd {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xF3, 0x00) . pack("S*", $index) . pack("L*", $amount);
	encrypt($r_socket, $msg);
	print "Sent Storage Add: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendStorageClose {
	my $r_socket = shift;
	my $msg = pack("C*", 0xF7, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Storage Done\n" if ($config{'debug'} >= 2);
}

sub sendStorageGet {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xF5, 0x00) . pack("S*", $index) . pack("L*", $amount);
	encrypt($r_socket, $msg);
	print "Sent Storage Get: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendStand {
	my $r_socket = shift;
	my $msg = pack("C*", 0x89,0x00, 0x00, 0x00, 0x00, 0x00, 0x03);
	encrypt($r_socket, $msg);
	print "Standing\n" if ($config{'debug'} >= 2);
}

sub sendSync {
	my $r_socket = shift;
	my $time = shift;
	my $msg = pack("C*", 0x7E, 0x00) . pack("L1", $time);
	encrypt($r_socket, $msg);
	print "Sent Sync: $time\n" if ($config{'debug'} >= 2);
}

sub sendTake {
	my $r_socket = shift;
	my $itemID = shift;
	my $msg = pack("C*", 0x9F, 0x00) . $itemID;
	encrypt($r_socket, $msg);
	print "Sent take\n" if ($config{'debug'} >= 2);
}

sub sendTalk {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x90, 0x00) . $ID . pack("C*",0x01);
	encrypt($r_socket, $msg);
	print "Sent talk: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendTalkCancel {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x46, 0x01) . $ID;
	encrypt($r_socket, $msg);
	print "Sent talk cancel: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendTalkContinue {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xB9, 0x00) . $ID;
	encrypt($r_socket, $msg);
	print "Sent talk continue: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendTalkResponse {
	my $r_socket = shift;
	my $ID = shift;
	my $response = shift;
	my $msg = pack("C*", 0xB8, 0x00) . $ID. pack("C1",$response);
	encrypt($r_socket, $msg);
	print "Sent talk respond: ".getHex($ID).", $response\n" if ($config{'debug'} >= 2);
}

sub sendTeleport {
	my $r_socket = shift;
	my $location = shift;
	$location = substr($location, 0, 16) if (length($location) > 16);
	$location .= chr(0) x (16 - length($location));
	my $msg = pack("C*", 0x1B, 0x01, 0x1A, 0x00) . $location;
	encrypt($r_socket, $msg);
	print "Sent Teleport: $location\n" if ($config{'debug'} >= 2);
}

sub sendUnequip{
	my $r_socket = shift;
	my $index = shift;
	my $msg = pack("C*", 0xAB, 0x00) . pack("S*", $index);
	encrypt($r_socket, $msg);
	print "Sent Unequip: $index\n" if ($config{'debug'} >= 2);
}

sub sendWho {
	my $r_socket = shift;
	my $msg = pack("C*", 0xC1, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Who\n" if ($config{'debug'} >= 2);
}




#######################################
#######################################
#CONNECTION FUNCTIONS
#######################################
#######################################


sub connection {
	my $r_socket = shift;
	my $host = shift;
	my $port = shift;
	print "Connecting ($host:$port)... ";
	$$r_socket = IO::Socket::INET->new(
			PeerAddr	=> $host,
			PeerPort	=> $port,
			Proto		=> 'tcp',
			Timeout		=> 4);
	($$r_socket && inet_aton($$r_socket->peerhost()) eq inet_aton($host)) ? print "connected\n" : print "couldn't connect\n";
}

sub dataWaiting {
	my $r_fh = shift;
	my $bits;
	vec($bits,fileno($$r_fh),1)=1;
	return (select($bits,$bits,$bits,0.05) > 1);
}

sub input_client {
	my ($input, $switch);
	my $msg;
	my $local_socket;
	my ($addrcheck, $portcheck, $hostcheck);
	print "Spawning Input Socket...\n";
	my $pid = fork;
	if ($pid == 0) {
		$local_socket = IO::Socket::INET->new(
				PeerAddr	=> $config{'local_host'},
				PeerPort	=> $config{'local_port'},
				Proto		=> 'tcp',
				Timeout		=> 4);
		($local_socket) || die "Error creating connection to local server: $!";
		while (1) {
			$input = <STDIN>;
			chomp $input;
			($switch) = $input =~ /^(\w*)/;
			if ($input ne "") {
				$local_socket->send($input);
			}
			last if ($input eq "quit" || $input eq "dump");
		}
		close($local_socket);
		exit;
	} else {
		$input_socket = $server_socket->accept();
		(inet_aton($input_socket->peerhost()) == inet_aton($config{'local_host'}))
		|| die "Input Socket must be connected from localhost";
		print "Input Socket connected\n";
		return $pid;
	}
}

sub killConnection {
	my $r_socket = shift;
	if ($$r_socket && $$r_socket->connected()) {
		print "Disconnecting (".$$r_socket->peerhost().":".$$r_socket->peerport().")... ";
		close($$r_socket);
		!$$r_socket->connected() ? print "disconnected\n" : print "couldn't disconnect\n";
	}
}





#######################################
#######################################
#FILE PARSING AND WRITING
#######################################
#######################################

sub addParseFiles {
	my $file = shift;
	my $hash = shift;
	my $function = shift;
	$parseFiles[$parseFiles]{'file'} = modifingPath($file);
	$parseFiles[$parseFiles]{'hash'} = $hash;
	$parseFiles[$parseFiles]{'function'} = $function;
	$parseFiles++;
}

sub chatLog {
	my $type = shift;
	my $message = shift;
	# Split chat logs
	if ( $type eq "c" || $type eq "e") {
		open CHAT, modifingPath(">> logs/Chat.txt");
	} elsif ( $type eq "pm") {
		open CHAT, modifingPath(">> logs/PrivateChat.txt");
	} elsif ( $type eq "s") {
		open CHAT, modifingPath(">> logs/GMMessage.txt");
	} elsif ( $type eq "p") {
		open CHAT, modifingPath(">> logs/PartyChat.txt");
	} elsif ( $type eq "g") {
		open CHAT, modifingPath(">> logs/GuildChat.txt");
	} elsif ( $type eq "i") {
		open CHAT, modifingPath(">> logs/GetItem.txt");
	} else {
		open CHAT, modifingPath(">> logs/Etc.txt");
	}
	print CHAT "[".getFormattedDate(int(time))."][".uc($type)."] $message";
	close CHAT;
}

sub chatLog_clear {
	if (-e modifingPath("logs/Chat.txt")) { unlink(modifingPath("logs/Chat.txt")); }
	if (-e modifingPath("logs/PrivateChat.txt")) { unlink(modifingPath("logs/PrivateChat.txt")); }
	if (-e modifingPath("logs/GMMessage.txt")) { unlink(modifingPath("logs/GMMessage.txt")); }
	if (-e modifingPath("logs/PartyChat.txt")) { unlink(modifingPath("logs/PartyChat.txt")); }
	if (-e modifingPath("logs/GuildChat.txt")) { unlink(modifingPath("logs/GuildChat.txt")); }
	if (-e modifingPath("logs/GetItem.txt")) { unlink(modifingPath("logs/GetItem.txt")); }
	if (-e modifingPath("logs/Etc.txt")) { unlink(modifingPath("logs/Etc.txt")); }
}


sub convertGatField {
	my $file = shift;
	my $r_hash = shift;
	my $i;
	open FILE, "+> $file";
	binmode(FILE);
	print FILE pack("S*", $$r_hash{'width'}, $$r_hash{'height'});
	for ($i = 0; $i < @{$$r_hash{'field'}}; $i++) {
		print FILE pack("C1", $$r_hash{'field'}[$i]);
	}
	close FILE;
}

sub dumpData {
	my $msg = shift;
	my $dump;
	my $rawdata;
	my $i;
	$dump = "\n\n================================================\n".getFormattedDate(int(time))."\n\n".length($msg)." bytes\n\n";
	for ($i=0; $i + 15 < length($msg);$i += 16) {
		$rawdata = substr($msg,$i,16);
		$rawdata =~ s/\W/./g;
		$dump .= getHex(substr($msg,$i,8))."    ".getHex(substr($msg,$i+8,8))."    $rawdata\n";
	}
	$rawdata = substr($msg,$i,length($msg) - $i);
	$rawdata =~ s/\W/./g;
	if (length($msg) - $i > 8) {
		$dump .= getHex(substr($msg,$i,8))."    ".getHex(substr($msg,$i+8,length($msg) - $i - 8))." " x (3 * ($i + 16 - length($msg)) + 4)."$rawdata\n";
	} elsif (length($msg) > 0) {
		$dump .= getHex(substr($msg,$i,length($msg) - $i))." " x (3 * ($i + 16 - length($msg)) + 7)."$rawdata\n";
	}
	open DUMP, modifingPath(">> logs/DUMP.txt");
	print DUMP $dump;
	close DUMP;
	print "$dump\n" if $config{'debug'} >= 2;
	print "Message Dumped into DUMP.txt!\n";
}

sub getField {
	my $file = shift;
	my $r_hash = shift;
	my ($i, $data);
	undef %{$r_hash};
	if ($file =~ /\//) {
		($$r_hash{'name'}) = $file =~ /\/([\s\S]*)\./;
	} else {
		($$r_hash{'name'}) = $file =~ /([\s\S]*)\./;
	}
	# Check for map alias
	$file =~ s/$$r_hash{'name'}(?=\.)/$mapAlias{$$r_hash{'name'}}/ if ($mapAlias{$$r_hash{'name'}} ne "");
	if (!(-e $file)) {
		print "\n!!Could not load field - you must install the kore-field pack!!\n\n";
		return;
	}
	open FILE, $file;
	binmode(FILE);
	read(FILE, $data, 4);
	my $width = unpack("S1", substr($data, 0,2));
	my $height = unpack("S1", substr($data, 2,2));
	$$r_hash{'width'} = $width;
	$$r_hash{'height'} = $height;
	while (read(FILE, $data, 1)) {
# Use substr instead of large array
#		$$r_hash{'field'}[$i] = unpack("C",$data);
		$$r_hash{'rawMap'} .= $data;
#		$i++;
	}
	close FILE;
}

sub getGatField {
	my $file = shift;
	my $r_hash = shift;
	my ($i, $data);
	undef %{$r_hash};
	($$r_hash{'name'}) = $file =~ /([\s\S]*)\./;
	open FILE, $file;
	binmode(FILE);
	read(FILE, $data, 16);
	my $width = unpack("L1", substr($data, 6,4));
	my $height = unpack("L1", substr($data, 10,4));
	$$r_hash{'width'} = $width;
	$$r_hash{'height'} = $height;
	while (read(FILE, $data, 20)) {
		$$r_hash{'field'}[$i] = unpack("C1", substr($data, 14,1));
		$i++;
	}
	close FILE;
}

sub getResponse {
	my $type = shift;
	my $key;
	my @keys;
	my $msg;
	foreach $key (keys %responses) {
		if ($key =~ /^$type\_\d+$/) {
			push @keys, $key;
		}
	}
	$msg = $responses{$keys[int(rand(@keys))]};
	$msg =~ s/\%\$(\w+)/$responseVars{$1}/eig;
	return $msg;
}

sub load {
	my $r_array = shift;
	# Eval settings
	my $evalflag = 0;

	foreach (@{$r_array}) {
		if (-e $$_{'file'}) {
			print "Loading $$_{'file'}...\n";
			# Eval settings
			$evalflag += 1 if ($$_{'file'} =~ /\/autores\.txt$/);
			$evalflag += 2 if ($$_{'file'} =~ /\/config\.txt$/);
			$evalflag += 4 if ($$_{'file'} =~ /\/importantitems\.txt$/);
		} else {
			print "Error: Couldn't load $$_{'file'}\n";
		}
		&{$$_{'function'}}("$$_{'file'}", $$_{'hash'});
		# Avoid brutal kill-steal
		if ($$_{'file'} =~ /\/jobs\.txt$/) {
			my $i = 0;
			for ($i = 0; $i < @JOBID; $i++) {
				$jobs_lut{$i} = $JOBID[$i] if (!$jobs_lut{$i});
			}
		} elsif ($$_{'file'} =~ /\/timeouts\.txt$/) {
			foreach (keys %timeout) {
				$timeout{$_}{'timeout'} = $timeout_limit{$_} if ($timeout_limit{$_} && $timeout{$_}{'timeout'} < $timeout_limit{$_});
			}
		}
	}
	# Eval settings
	evalSettings($evalflag);
}



sub parseDataFile {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,$value);
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $value) = $_ =~ /([\s\S]*) ([\s\S]*?)$/;
		if ($key ne "" && $value ne "") {
			$$r_hash{$key} = $value;
		}
	}
	close FILE;
}

sub parseDataFile_lc {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,$value);
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $value) = $_ =~ /([\s\S]*) ([\s\S]*?)$/;
		if ($key ne "" && $value ne "") {
			$$r_hash{lc($key)} = $value;
		}
	}
	close FILE;
}

sub parseDataFile2 {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,$value);
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $value) = $_ =~ /([\s\S]*?) ([\s\S]*)$/;
		$key =~ s/\s//g;
		if ($key eq "") {
			($key) = $_ =~ /([\s\S]*)$/;
			$key =~ s/\s//g;
		}
		if ($key ne "") {
			$$r_hash{$key} = $value;
		}
	}
	close FILE;
}

sub parseItemsControl {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,@args);
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $args) = $_ =~ /([\s\S]+?) (\d+[\s\S]*)/;
		@args = split / /,$args;
		if ($key ne "") {
			$$r_hash{lc($key)}{'keep'} = $args[0];
			$$r_hash{lc($key)}{'storage'} = $args[1];
			$$r_hash{lc($key)}{'sell'} = $args[2];
		}
	}
	close FILE;
}

sub parseNPCs {
	my $file = shift;
	my $r_hash = shift;
	my ($i, $string);
	undef %{$r_hash};
	my ($key,$value);
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+/ /g;
		s/\s+$//g;
		@args = split /\s/, $_;
		if (@args > 4) {
			$$r_hash{$args[0]}{'map'} = $args[1];
			$$r_hash{$args[0]}{'pos'}{'x'} = $args[2];
			$$r_hash{$args[0]}{'pos'}{'y'} = $args[3];
			$string = $args[4];
			for ($i = 5; $i < @args; $i++) {
				$string .= " $args[$i]";
			}
			$$r_hash{$args[0]}{'name'} = $string;
		}
	}
	close FILE;
}

sub parseMonControl {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,@args);
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $args) = $_ =~ /([\s\S]+?) (-?\d+[\s\S]*)/;
		@args = split / /,$args;
		if ($key ne "") {
			$$r_hash{lc($key)}{'attack_auto'} = $args[0];
			$$r_hash{lc($key)}{'teleport_auto'} = $args[1];
			$$r_hash{lc($key)}{'teleport_search'} = $args[2];
		}
	}
	close FILE;
}

sub parsePortals {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,$value);
	my %IDs;
	my $i;
	my $j = 0;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+/ /g;
		s/\s+$//g;
		@args = split /\s/, $_;
		if (@args > 5) {
			$IDs{$args[0]}{$args[1]}{$args[2]} = "$args[0] $args[1] $args[2]";
			$$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'ID'} = "$args[0] $args[1] $args[2]";
			$$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'map'} = $args[0];
			$$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'pos'}{'x'} = $args[1];
			$$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'pos'}{'y'} = $args[2];
			$$r_hash{"$args[0] $args[1] $args[2]"}{'dest'}{'map'} = $args[3];
			$$r_hash{"$args[0] $args[1] $args[2]"}{'dest'}{'pos'}{'x'} = $args[4];
			$$r_hash{"$args[0] $args[1] $args[2]"}{'dest'}{'pos'}{'y'} = $args[5];
			if ($args[6] ne "") {
				$$r_hash{"$args[0] $args[1] $args[2]"}{'npc'}{'ID'} = $args[6];
				for ($i = 7; $i < @args; $i++) {
					$$r_hash{"$args[0] $args[1] $args[2]"}{'npc'}{'steps'}[@{$$r_hash{"$args[0] $args[1] $args[2]"}{'npc'}{'steps'}}] = $args[$i];
				}
			}
		}
		$j++;
	}
	foreach (keys %{$r_hash}) {
		$$r_hash{$_}{'dest'}{'ID'} = $IDs{$$r_hash{$_}{'dest'}{'map'}}{$$r_hash{$_}{'dest'}{'pos'}{'x'}}{$$r_hash{$_}{'dest'}{'pos'}{'y'}};
	}
	close FILE;
}

sub parsePortalsLOS {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $key;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+/ /g;
		s/\s+$//g;
		@args = split /\s/, $_;
		if (@args) {
			$map = shift @args;
			$x = shift @args;
			$y = shift @args;
			for ($i = 0; $i < @args; $i += 4) {
				$$r_hash{"$map $x $y"}{"$args[$i] $args[$i+1] $args[$i+2]"} = $args[$i+3];
			}
		}
	}
	close FILE;
}

sub parseReload {
	my $temp = shift;
	my @temp;
	my %temp;
	my $temp2;
	my $except;
	my $found;
	while ($temp =~ /(\w+)/g) {
		$temp2 = $1;
		$qm = quotemeta $temp2;
		if ($temp2 eq "all") {
			foreach (@parseFiles) {
				$temp{$$_{'file'}} = $_;
			}
		} elsif ($temp2 =~ /\bexcept\b/i || $temp2 =~ /\bbut\b/i) {
			$except = 1;
		} else {
			if ($except) {
				foreach (@parseFiles) {
					delete $temp{$$_{'file'}} if $$_{'file'} =~ /$qm/i;
				}
			} else {
				foreach (@parseFiles) {
					$temp{$$_{'file'}} = $_ if $$_{'file'} =~ /$qm/i;
				}
			}
		}
	}
	foreach $temp (keys %temp) {
		$temp[@temp] = $temp{$temp};
	}
	load(\@temp);
}

sub parseResponses {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,$value);
	my $i;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		($key, $value) = $_ =~ /([\s\S]*?) ([\s\S]*)$/;
		if ($key ne "" && $value ne "") {
			$i = 0;
			while ($$r_hash{"$key\_$i"} ne "") {
				$i++;
			}
			$$r_hash{"$key\_$i"} = $value;
		}
	}
	close FILE;
}

sub parseROLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;
	open FILE, $file;
	foreach (<FILE>) {
		s/\r//g;
		next if /^\/\//;
		@stuff = split /#/, $_;
		# Avoid display errors
		replaceUnderToSpace(\$stuff[1]);
		if ($stuff[0] ne "" && $stuff[1] ne "") {
			$$r_hash{$stuff[0]} = $stuff[1];
		}
	}
	close FILE;
}

sub parseRODescLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $ID;
	my $IDdesc;
	open FILE, $file;
	foreach (<FILE>) {
		s/\r//g;
		if (/^#/) {
			$$r_hash{$ID} = $IDdesc;
			undef $ID;
			undef $IDdesc;
		} elsif (!$ID) {
			($ID) = /([\s\S]+)#/;
		} else {
			$_ =~ s/\^[0-9a-f]{6}//g;
			$_ =~ s/^_$/--------------/g;
			$IDdesc .= $_;
		}
	}
	close FILE;
}

sub parseROSlotsLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $ID;
	open FILE, $file;
	foreach (<FILE>) {
		if (!$ID) {
			($ID) = /(\d+)#/;
		} else {
			($$r_hash{$ID}) = /(\d+)#/;
			undef $ID;
		}
	}
	close FILE;
}

sub parseSkillsLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;
	my $i;
	open FILE, $file;
	$i = 1;
	foreach (<FILE>) {
		@stuff = split /#/, $_;
		# Avoid display errors
		replaceUnderToSpace(\$stuff[1]);
		if ($stuff[0] ne "" && $stuff[1] ne "") {
			$$r_hash{$stuff[0]} = $stuff[1];
		}
		$i++;
	}
	close FILE;
}


sub parseSkillsIDLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;
	my $i;
	open FILE, $file;
	foreach (<FILE>) {
		@stuff = split /#/, $_;
		# Avoid display errors
		replaceUnderToSpace(\$stuff[1]);
		if ($stuff[0] ne "" && $stuff[1] ne "") {
			$$r_hash{$stuff[2]} = $stuff[1];
		}
	}
	close FILE;
}

sub parseSkillsReverseLUT_lc {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;
	my $i;
	open FILE, $file;
	$i = 1;
	foreach (<FILE>) {
		@stuff = split /#/, $_;
		# Avoid display errors
		replaceUnderToSpace(\$stuff[1]);
		if ($stuff[0] ne "" && $stuff[1] ne "") {
			$$r_hash{lc($stuff[1])} = $stuff[0];
		}
		$i++;
	}
	close FILE;
}

sub parseSkillsSPLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $ID;
	my $i;
	$i = 1;
	open FILE, $file;
	foreach (<FILE>) {
		if (/^\@/) {
			undef $ID;
			$i = 1;
		} elsif (!$ID) {
			($ID) = /([\s\S]+)#/;
		} else {
			($$r_hash{$ID}{$i++}) = /(\d+)#/;
		}
	}
	close FILE;
}

sub parseTimeouts {
	my $file = shift;
	my $r_hash = shift;
	my ($key,$value);
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		($key, $value) = $_ =~ /([\s\S]*) ([\s\S]*?)$/;
		if ($key ne "" && $value ne "") {
			$$r_hash{$key}{'timeout'} = abs($value);
		}
	}
	close FILE;
}

sub writeDataFile {
	my $file = shift;
	my $r_hash = shift;
	my ($key,$value);
	open FILE, modifingPath("+> $file");
	foreach (keys %{$r_hash}) {
		if ($_ ne "") {
			print FILE "$_ $$r_hash{$_}\n";
		}
	}
	close FILE;
}

sub writeDataFileIntact {
	my $file = shift;
	my $r_hash = shift;
	my $data;
	my $key;
	open FILE, modifingPath($file);
	foreach (<FILE>) {
		if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
			$data .= $_;
			next;
		}
		($key) = $_ =~ /^(\w+)/;
		if ($key !~ /^AcWord_\d+/ || $ai_v{'temp'}{'updateAcWord'} ne "" && $key == "AcWord_$ai_v{'temp'}{'updateAcWord'}") {
			$data .= "$key $$r_hash{$key}\n";
		} else {
			$data .= $_;
		}
	}
	undef $ai_v{'temp'}{'updateAcWord'};
	close FILE;
	open FILE, modifingPath("+> $file");
	print FILE $data;
	close FILE;
}

sub writeDataFileIntact2 {
	my $file = shift;
	my $r_hash = shift;
	my $data;
	my $key;
	open FILE, modifingPath($file);
	foreach (<FILE>) {
                if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
                        $data .= $_;
                        next;
                }
                ($key) = $_ =~ /^(\w+)/;
                $data .= "$key $$r_hash{$key}{'timeout'}\n";
        }
	close FILE;
	open FILE, modifingPath("+> $file");
	print FILE $data;
	close FILE;
}

sub writePortalsLOS {
	my $file = shift;
	my $r_hash = shift;
	open FILE, modifingPath("+> $file");
	foreach $key (keys %{$r_hash}) {
		next if (!(keys %{$$r_hash{$key}}));
		print FILE $key;
		foreach (keys %{$$r_hash{$key}}) {
			print FILE " $_ $$r_hash{$key}{$_}";
		}
		print FILE "\n";
	}
	close FILE;
}

sub updateMonsterLUT {
	my $file = shift;
	my $ID = shift;
	my $name = shift;
	open FILE, modifingPath(">> $file");
	print FILE "$ID $name\n";
	close FILE;
}

sub updatePortalLUT {
	my ($file, $src, $x1, $y1, $dest, $x2, $y2) = @_;
	open FILE, modifingPath(">> $file");
	print FILE "$src $x1 $y1 $dest $x2 $y2\n";
	close FILE;
}

sub updateNPCLUT {
	my ($file, $ID, $map, $x, $y, $name) = @_;
	open FILE, modifingPath(">> $file");
	print FILE "$ID $map $x $y $name\n";
	close FILE;
}

#######################################
#######################################
#HASH/ARRAY MANAGEMENT
#######################################
#######################################


sub binAdd {
	my $r_array = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i <= @{$r_array};$i++) {
		if ($$r_array[$i] eq "") {
			$$r_array[$i] = $ID;
			return $i;
		}
	}
}

sub binFind {
	my $r_array = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array};$i++) {
		if ($$r_array[$i] eq $ID) {
			return $i;
		}
	}
}

sub binFindReverse {
	my $r_array = shift;
	my $ID = shift;
	my $i;
	for ($i = @{$r_array} - 1; $i >= 0;$i--) {
		if ($$r_array[$i] eq $ID) {
			return $i;
		}
	}
}

sub binRemove {
	my $r_array = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array};$i++) {
		if ($$r_array[$i] eq $ID) {
			undef $$r_array[$i];
			last;
		}
	}
}

sub binRemoveAndShift {
	my $r_array = shift;
	my $ID = shift;
	my $found;
	my $i;
	my @newArray;
	for ($i = 0; $i < @{$r_array};$i++) {
		if ($$r_array[$i] ne $ID || $found ne "") {
			push @newArray, $$r_array[$i];
		} else {
			$found = $i;
		}
	}
	@{$r_array} = @newArray;
	return $found;
}

sub binRemoveAndShiftByIndex {
	my $r_array = shift;
	my $index = shift;
	my $found;
	my $i;
	my @newArray;
	for ($i = 0; $i < @{$r_array};$i++) {
		if ($i != $index) {
			push @newArray, $$r_array[$i];
		} else {
			$found = 1;
		}
	}
	@{$r_array} = @newArray;
	return $found;
}

sub binSize {
	my $r_array = shift;
	my $found = 0;
	my $i;
	for ($i = 0; $i < @{$r_array};$i++) {
		if ($$r_array[$i] ne "") {
			$found++;
		}
	}
	return $found;
}

sub existsInList {
	my ($list, $val) = @_;
	@array = split /,/, $list;
	return 0 if ($val eq "");
	$val = lc($val);
	foreach (@array) {
		s/^\s+//;
		s/\s+$//;
		s/\s+/ /g;
		next if ($_ eq "");
		return 1 if (lc($_) eq $val);
	}
	return 0;
}

sub findIndex {
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array} ;$i++) {
		if ((%{$$r_array[$i]} && $$r_array[$i]{$match} == $ID)
			|| (!%{$$r_array[$i]} && $ID eq "")) {
			return $i;
		}
	}
	if ($ID eq "") {
		return $i;
	}
}


sub findIndexString {
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array} ;$i++) {
		if ((%{$$r_array[$i]} && $$r_array[$i]{$match} eq $ID)
			|| (!%{$$r_array[$i]} && $ID eq "")) {
			return $i;
		}
	}
	if ($ID eq "") {
		return $i;
	}
}


sub findIndexString_lc {
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array} ;$i++) {
		if ((%{$$r_array[$i]} && lc($$r_array[$i]{$match}) eq lc($ID))
			|| (!%{$$r_array[$i]} && $ID eq "")) {
			return $i;
		}
	}
	if ($ID eq "") {
		return $i;
	}
}

sub findKey {
	my $r_hash = shift;
	my $match = shift;
	my $ID = shift;
	foreach (keys %{$r_hash}) {
		if ($$r_hash{$_}{$match} == $ID) {
			return $_;
		}
	}
}

sub findKeyString {
	my $r_hash = shift;
	my $match = shift;
	my $ID = shift;
	foreach (keys %{$r_hash}) {
		if ($$r_hash{$_}{$match} eq $ID) {
			return $_;
		}
	}
}

sub minHeapAdd {
	my $r_array = shift;
	my $r_hash = shift;
	my $match = shift;
	my $i;
	my $found;
	my @newArray;
	for ($i = 0; $i < @{$r_array};$i++) {
		if (!$found && $$r_hash{$match} < $$r_array[$i]{$match}) {
			push @newArray, $r_hash;
			$found = 1;
		}
		push @newArray, $$r_array[$i];
	}
	if (!$found) {
		push @newArray, $r_hash;
	}
	@{$r_array} = @newArray;
}

sub updateDamageTables {
	my ($ID1, $ID2, $damage) = @_;
	if ($ID1 eq $accountID) {
		if (%{$monsters{$ID2}}) {
			$monsters{$ID2}{'dmgTo'} += $damage;
			$monsters{$ID2}{'dmgFromYou'} += $damage;
			if ($damage == 0) {
				$monsters{$ID2}{'missedFromYou'}++;
			}
		}
	} elsif ($ID2 eq $accountID) {
		if (%{$monsters{$ID1}}) {
			$monsters{$ID1}{'dmgFrom'} += $damage;
			$monsters{$ID1}{'dmgToYou'} += $damage;
			if ($damage == 0) {
				$monsters{$ID1}{'missedYou'}++;
			}
			my $ai_index = binFind(\@ai_seq, "attack");
			# Counter priority
			if (!$monsters{$ID1}{'attack_failed'}
				&& $ai_index ne "" && %{$monsters{$ai_seq_args[$ai_index]{'ID'}}}
				&& (abs($mon_control{lc($monsters{$ID1}{'name'})}{'attack_auto'}) > abs($mon_control{lc($monsters{$ai_seq_args[$ai_index]{'ID'}}{'name'})}{'attack_auto'}))) {
				attackStop(\$remote_socket, $ai_seq_args[$ai_index]{'ID'});
				attack($ID1);
			# Give up when total damage is larger then the defined value before a successful hit
			} elsif ($config{'attackAuto_maxDmgTolerance'} && $ai_index ne ""
				&& $ID1 ne $ai_seq_args[$ai_index]{'ID'} && %{$monsters{$ai_seq_args[$ai_index]{'ID'}}}
				&& $monsters{$ai_seq_args[$ai_index]{'ID'}}{'dmgFromYou'} == 0
				&& $monsters{$ai_seq_args[$ai_index]{'ID'}}{'missedFromYou'} == 0) {
				$ai_seq_args[$ai_index]{'dmgToYou_total'} += $damage;
				if ($ai_seq_args[$ai_index]{'dmgToYou_total'} >= $config{'attackAuto_maxDmgTolerance'}) {
					attackStop(\$remote_socket, $ai_seq_args[$ai_index]{'ID'});
				}
			}
		}
	} elsif (%{$monsters{$ID1}}) {
		if (%{$players{$ID2}}) {
			$monsters{$ID1}{'dmgFrom'} += $damage;
			$monsters{$ID1}{'dmgToPlayer'}{$ID2} += $damage;
			$players{$ID2}{'dmgFromMonster'}{$ID1} += $damage;
			if ($damage == 0) {
				$monsters{$ID1}{'missedToPlayer'}{$ID2}++;
				$players{$ID2}{'missedFromMonster'}{$ID1}++;
			}
			if (%{$chars[$config{'char'}]{'party'}} && %{$chars[$config{'char'}]{'party'}{'users'}{$ID2}}) {
				$monsters{$ID1}{'dmgToParty'} += $damage;
			}
		}

	} elsif (%{$players{$ID1}}) {
		if (%{$monsters{$ID2}}) {
			$monsters{$ID2}{'dmgTo'} += $damage;
			$monsters{$ID2}{'dmgFromPlayer'}{$ID1} += $damage;
			$players{$ID1}{'dmgToMonster'}{$ID2} += $damage;
			if ($damage == 0) {
				$monsters{$ID2}{'missedFromPlayer'}{$ID1}++;
				$players{$ID1}{'missedToMonster'}{$ID2}++;
			}
			if (%{$chars[$config{'char'}]{'party'}} && %{$chars[$config{'char'}]{'party'}{'users'}{$ID1}}) {
				$monsters{$ID2}{'dmgFromParty'} += $damage;
			}
		}
	}
}


#######################################
#######################################
#MISC FUNCTIONS
#######################################
#######################################

sub compilePortals {
	undef %mapPortals;
	foreach (keys %portals_lut) {
		%{$mapPortals{$portals_lut{$_}{'source'}{'map'}}{$_}{'pos'}} = %{$portals_lut{$_}{'source'}{'pos'}};
	}
#	$l = 0;
	foreach $map (keys %mapPortals) {
		foreach $portal (keys %{$mapPortals{$map}}) {
			foreach (keys %{$mapPortals{$map}}) {
				next if ($_ eq $portal);
				if ($portals_los{$portal}{$_} eq "" && $portals_los{$_}{$portal} eq "") {
					if ($field{'name'} ne $map) {
						print "Processing map $map\n";
						getField("fields/$map.fld", \%field);
					}
					print "Calculating portal route $portal -> $_\n";
					ai_route_getRoute(\@solution, \%field, \%{$mapPortals{$map}{$portal}{'pos'}}, \%{$mapPortals{$map}{$_}{'pos'}});
					compilePortals_getRoute();
					$portals_los{$portal}{$_} = (@solution) ? 1 : 0;
				}
			}
		}
	}

	writePortalsLOS("tables/portalsLOS.txt", \%portals_los);

	print "Wrote portals Line of Sight table to 'tables/portalsLOS.txt'\n";

}

sub compilePortals_check {
	my $r_return = shift;
	my %mapPortals;
	undef $$r_return;
	foreach (keys %portals_lut) {
		%{$mapPortals{$portals_lut{$_}{'source'}{'map'}}{$_}{'pos'}} = %{$portals_lut{$_}{'source'}{'pos'}};
	}
	foreach $map (keys %mapPortals) {
		foreach $portal (keys %{$mapPortals{$map}}) {
			foreach (keys %{$mapPortals{$map}}) {
				next if ($_ eq $portal);
				if ($portals_los{$portal}{$_} eq "" && $portals_los{$_}{$portal} eq "") {
					$$r_return = 1;
					return;
				}
			}
		}
	}
}

sub compilePortals_getRoute {
	if ($ai_seq[0] eq "route_getRoute") {
		if (!$ai_seq_args[0]{'init'}) {
			undef @{$ai_v{'temp'}{'subSuc'}};
			undef @{$ai_v{'temp'}{'subSuc2'}};
			if (ai_route_getMap(\%{$ai_seq_args[0]}, $ai_seq_args[0]{'start'}{'x'}, $ai_seq_args[0]{'start'}{'y'})) {
				ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'start'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'start'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				foreach (@{$ai_v{'temp'}{'subSuc'}}) {
					ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
					ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
				}
				if (@{$ai_v{'temp'}{'subSuc'}}) {
					%{$ai_seq_args[0]{'start'}} = %{$ai_v{'temp'}{'subSuc'}[0]};
				} elsif (@{$ai_v{'temp'}{'subSuc2'}}) {
					%{$ai_seq_args[0]{'start'}} = %{$ai_v{'temp'}{'subSuc2'}[0]};
				}
			}
			undef @{$ai_v{'temp'}{'subSuc'}};
			undef @{$ai_v{'temp'}{'subSuc2'}};
			if (ai_route_getMap(\%{$ai_seq_args[0]}, $ai_seq_args[0]{'dest'}{'x'}, $ai_seq_args[0]{'dest'}{'y'})) {
				ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'dest'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'dest'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				foreach (@{$ai_v{'temp'}{'subSuc'}}) {
					ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
					ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
				}
				if (@{$ai_v{'temp'}{'subSuc'}}) {
					%{$ai_seq_args[0]{'dest'}} = %{$ai_v{'temp'}{'subSuc'}[0]};
				} elsif (@{$ai_v{'temp'}{'subSuc2'}}) {
					%{$ai_seq_args[0]{'dest'}} = %{$ai_v{'temp'}{'subSuc2'}[0]};
				}
			}
			$ai_seq_args[0]{'timeout'} = 90000;
		}
		$ai_seq_args[0]{'init'} = 1;
		ai_route_searchStep(\%{$ai_seq_args[0]});
		ai_route_getRoute_destroy(\%{$ai_seq_args[0]});
		shift @ai_seq;
		shift @ai_seq_args;
	}
}


sub getCoordString {
	my $x = shift;
	my $y = shift;
	return pack("C*", int($x / 4), ($x % 4) * 64 + int($y / 16), ($y % 16) * 16);
}

sub getFormattedDate {
        my $thetime = shift;
        my $r_date = shift;
        my @localtime = localtime $thetime;
        my $themonth = (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec)[$localtime[4]];
        $localtime[2] = "0" . $localtime[2] if ($localtime[2] < 10);
        $localtime[1] = "0" . $localtime[1] if ($localtime[1] < 10);
        $localtime[0] = "0" . $localtime[0] if ($localtime[0] < 10);
        $$r_date = "$themonth $localtime[3] $localtime[2]:$localtime[1]:$localtime[0] " . ($localtime[5] + 1900);
        return $$r_date;
}

sub getHex {
	my $data = shift;
	my $i;
	my $return;
	for ($i = 0; $i < length($data); $i++) {
		$return .= uc(unpack("H2",substr($data, $i, 1)));
		if ($i + 1 < length($data)) {
			$return .= " ";
		}
	}
	return $return;
}



sub getTickCount {
	my $time = int(time()*1000);
	if (length($time) > 9) {
		return substr($time, length($time) - 8, length($time));
	} else {
		return $time;
	}
}

sub importDynaLib {
	undef $CalcPath_init;
	undef $CalcPath_pathStep;
	undef $CalcPath_destroy;
	if (!$config{'buildType'}) {
		$CalcPath_init = new Win32::API("Tools", "CalcPath_init", "PPNNPPN", "N");
		die "Could not locate Tools.dll" if (!$CalcPath_init);

		$CalcPath_pathStep = new Win32::API("Tools", "CalcPath_pathStep", "N", "N");
		die "Could not locate Tools.dll" if (!$CalcPath_pathStep);

		$CalcPath_destroy = new Win32::API("Tools", "CalcPath_destroy", "N", "V");
		die "Could not locate Tools.dll" if (!$CalcPath_destroy);
	} elsif ($config{'buildType'} == 1) {
		$ToolsLib = new C::DynaLib("./Tools.so");

		$CalcPath_init = $ToolsLib->DeclareSub("CalcPath_init", "L", "p","p","L","L","p","p","L");
		die "Could not locate Tools.so" if (!$CalcPath_init);

		$CalcPath_pathStep = $ToolsLib->DeclareSub("CalcPath_pathStep", "L", "L");
		die "Could not locate Tools.so" if (!$CalcPath_pathStep);

		$CalcPath_destroy = $ToolsLib->DeclareSub("CalcPath_destroy", "", "L");
		die "Could not locate Tools.so" if (!$CalcPath_destroy);
	}
}

sub makeCoords {
	my $r_hash = shift;
	my $rawCoords = shift;
	$$r_hash{'x'} = unpack("C", substr($rawCoords, 0, 1)) * 4 + (unpack("C", substr($rawCoords, 1, 1)) & 0xC0) / 64;
	$$r_hash{'y'} = (unpack("C",substr($rawCoords, 1, 1)) & 0x3F) * 16 +
				(unpack("C",substr($rawCoords, 2, 1)) & 0xF0) / 16;
}
sub makeCoords2 {
	my $r_hash = shift;
	my $rawCoords = shift;
	$$r_hash{'x'} = (unpack("C",substr($rawCoords, 1, 1)) & 0xFC) / 4 +
				(unpack("C",substr($rawCoords, 0, 1)) & 0x0F) * 64;
	$$r_hash{'y'} = (unpack("C", substr($rawCoords, 1, 1)) & 0x03) * 256 + unpack("C", substr($rawCoords, 2, 1));
}
sub makeIP {
	my $raw = shift;
	my $ret;
	my $i;
	for ($i=0;$i < 4;$i++) {
		$ret .= hex(getHex(substr($raw, $i, 1)));
		if ($i + 1 < 4) {
			$ret .= ".";
		}
	}
	return $ret;
}

sub portalExists {
	my ($map, $r_pos) = @_;
	foreach (keys %portals_lut) {
		if ($portals_lut{$_}{'source'}{'map'} eq $map && $portals_lut{$_}{'source'}{'pos'}{'x'} == $$r_pos{'x'}
			&& $portals_lut{$_}{'source'}{'pos'}{'y'} == $$r_pos{'y'}) {
			return $_;
		}
	}
}

sub printItemDesc {
	my $itemID = shift;
	print "===============Item Description===============\n";
	print "Item: $items_lut{$itemID}\n\n";
	print $itemsDesc_lut{$itemID};
	print "==============================================\n";
}

# Replace underscore to space
sub replaceUnderToSpace {
	my $string = shift;
	my $isDualByte = 0;
	for ($i = 0; $i < length($$string); $i++) {
		if (substr($$string, $i, 1) eq "_" && !$isDualByte) {
			substr($$string, $i, 1) = " ";
		} elsif (ord(substr($$string, $i, 1)) >= 0x80) {
			$isDualByte = 1 - $isDualByte;
		} else {
			$isDualByte = 0;
		}
	}
}

sub timeOut {
	my ($r_time, $compare_time) = @_;
	if ($compare_time ne "") {
		return (time - $r_time > $compare_time);
	} else {
		return (time - $$r_time{'time'} > $$r_time{'timeout'});
	}
}

sub vocalString {
        my $letter_length = shift;
        return if ($letter_length <= 0);
        my $r_string = shift;
        my $test;
        my $i;
        my $password;
        my @cons = ("b", "c", "d", "g", "h", "j", "k", "l", "m", "n", "p", "r", "s", "t", "v", "w", "y", "z", "tr", "cl", "cr", "br", "fr", "th", "dr", "ch", "st", "sp", "sw", "pr", "sh", "gr", "tw", "wr", "ck");
        my @vowels = ("a", "e", "i", "o", "u" , "a", "e" ,"i","o","u","a","e","i","o", "ea" , "ou" , "ie" , "ai" , "ee" ,"au", "oo");
        my %badend = ( "tr" => 1, "cr" => 1, "br" => 1, "fr" => 1, "dr" => 1, "sp" => 1, "sw" => 1, "pr" =>1, "gr" => 1, "tw" => 1, "wr" => 1, "cl" => 1);
        for (;;) {
                $password = "";
                for ($i = 0; $i < $letter_length; $i++) {
                        $password .= $cons[rand(@cons - 1)] . $vowels[rand(@vowels - 1)];
                }
                $password = substr($password, 0, $letter_length);
                ($test) = ($password =~ /(..)\z/);
                last if ($badend{$test} != 1);
        }
        $$r_string = $password;
        return $$r_string;
}

# Additional Subroutines #############################################

# Queue auto actions
sub ai_action {
	my $type = shift;
	my $action = shift;
	my $ai_index = binFind(\@ai_seq, "actionAuto");

	if ($ai_index ne "") {
		push @{$ai_seq_args[$ai_index]{'type'}}, $type;
		push @{$ai_seq_args[$ai_index]{'action'}}, $action;
	} else {
		my %args;
		push @{$args{'action'}}, $action;
		$args{'time'} = time;
		$args{'timeout'} = $config{'wait_'.$type};
		unshift @ai_seq, "actionAuto";
		unshift @ai_seq_args, \%args;
	}
}

# Stop attacking
sub attackStop {
	my $r_socket = shift;
	my $ID = shift;
	return if (binFind(\@ai_seq, "attack") eq "");
	print "Stopped Targeting: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n";
	aiRemove("attack");
	sendAttackStop($r_socket);
}

# Auto lockMap change
sub autolockMap {
	my $i = 0;
	my $target_map = "";
	my $target_lv = "";
	while ($config{"lockMap_$i"."_lv"} ne "") {
		($target_lv) = $config{"lockMap_$i"."_lv"} =~ /(\d+)/;
		if ($config{"lockMap_$i"."_lv"} =~ /\bbase\b/ && $chars[$config{'char'}]{'lv'} >= $target_lv) {
			$target_map = $config{"lockMap_$i"};
		} elsif ($config{"lockMap_$i"."_lv"} =~ /\bbase\b/ && $chars[$config{'char'}]{'lv_job'} >= $target_lv) {
			$target_map = $config{"lockMap_$i"};
		}
		last if $target_map ne "";
		$i++;
	}
	if ($target_map ne "" && $target_map ne $config{'lockMap'}) {
		print "Auto-change lockMap to $maps_lut{$target_map}\n";
		configModify("lockMap", $target_map);
		parseInput("base") if $config{'lockMap_lv_base'};
		aiRemove("move");
		aiRemove("route");
		aiRemove("route_getRoute");
		aiRemove("route_getMapRoute");
	}
}

# Avoid GM
sub avoidGM {
	my $rawID = shift;
	my $name = shift;
	my $talk = shift;
	$rawID = ai_getIDFromChat(\%players, $name, "") if ($rawID eq "");
	my $ID = ($rawID ne "") ? unpack("L1", $rawID) : "";

	if ($config{'dcOnGM'} && !$ai_v{'teleOnGM'}) {
		if (($name =~/^GM\d{2}/i || binFind(\@GMAID,$ID) ne "" || $autoLogoff{$name}) && $autoLogoff{$name} ne "0") {
			my $display = ($rawID ne "") ? " [".getHex($rawID)."]" : "";
			undef $display if ($ID <= 65535);
			if (!$talk && !$config{'dcOnGM_noTele'} && !$cities_lut{$field{'name'}.'.rsw'}
				&& ($ai_v{'dcOnGM_counter'}{$name} + 1 < $config{'dcOnGM_count'} || $config{'dcOnGM_count'} eq "")) {
				print "*** GM is nearby, teleporting... ***\n";
				chatLog("s", "*** Found $name$display nearby and teleported ***\n");
				$ai_v{'teleOnGM'} = 1;
			} elsif (!$talk && $config{'dcOnGM_ignoreInCity'} && $cities_lut{$field{'name'}.'.rsw'}) {
				chatLog("s", "*** Found $name$display nearby and ignored ***\n");
			} else {
				print "Disconnecting on avoid GM!\n";
				chatLog("s", "*** Maybe $name$display is trying to judge you, auto disconnected ***\n");
				if (!$cities_lut{$field{'name'}.'.rsw'} && !$config{'dcOnGM_noTele'}) {
					$ai_v{'teleOnGM'} = 2;
				} else {
					quitOnEvent("dcOnGM");
				}
			}
			if ($ai_v{'teleOnGM'}) {
				useTeleport($ai_v{'teleOnGM'});
				$ai_v{'clear_aiQueue'} = 1;
				$ai_v{'dcOnGM_counter'}{$name}++;
			}
			chatLog("s", "*** Your Location - [$maps_lut{$field{'name'}.'.rsw'}($field{'name'}) : $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'}] ***\n");
			chatLog("s", "*** GM's Location - [$maps_lut{$field{'name'}.'.rsw'}($field{'name'}) : $players{$rawID}{'pos_to'}{'x'}, $players{$rawID}{'pos_to'}{'y'}] ***\n") if ($rawID ne "" && %{$players{$rawID}});
			chatLog("s", "*** GM's Location - [$maps_lut{$field{'name'}.'.rsw'}($field{'name'}) : $pets{$rawID}{'pos_to'}{'x'}, $pets{$rawID}{'pos_to'}{'y'}] ***\n") if ($rawID ne "" && %{$pets{$rawID}});
		}
	}
}

# Avoid specified player
sub avoidPlayer{
	my $ID = shift;

	if (!$ai_v{'teleOnEvent'} && !$cities_lut{$field{'name'}.'.rsw'}
		&& (existsInList($config{'teleportAuto_player'}, $players{$ID}{'name'})
			|| existsInList($config{'teleportAuto_player_AID'}, getHex($ID)))) {
		my $hexID = getHex($ID);
		print "***Found player $players{$ID}{'name'} [$hexID] nearby, auto teleporting ***\n";
		chatLog("tv","Found player $players{$ID}{'name'} [$hexID] nearby, auto teleported.\n");
		useTeleport(1);
		$ai_v{'clear_aiQueue'} = 1;
		$ai_v{'teleOnEvent'} = 1;
	}
}

# Avoid stuck
sub avoidStuck {
	my $check;
	my $isStuck;
	my $msg;

	for ($i = -1; $i < 2; $i++) {
		for ($j = -1; $j < 2; $j++) {
			next if ($i == 0 && $j == 0);
			$check++ if (ai_route_getOffset(\%field, $chars[$config{'char'}]{'pos_to'}{'x'} + $i, $chars[$config{'char'}]{'pos_to'}{'y'} + $j));
		}
	}
	if ($check + $config{'unstuckAuto_margin'} > 8
		|| ($config{'unstuckAuto_rfcount'} && $ai_v{'avoidStuck'}{'route_failed'} >= $config{'unstuckAuto_rfcount'})
		|| ($config{'unstuckAuto_mfcount'} && $ai_v{'avoidStuck'}{'move_failed'} >= $config{'unstuckAuto_mfcount'})) {
		$ai_v{'avoidStuck_tries'}++;
		if ($config{'unstuckAuto_utcount'} && $ai_v{'avoidStuck_tries'} >= $config{'unstuckAuto_utcount'}) {
			undef $ai_v{'avoidStuck_tries'};
			$msg = ($config{'unstuckAuto_alternative'}) ? "reloading dynalibs" : "respawning";
			$isStuck = 3;
		} else {
			$msg = "teleporting";
			$isStuck = 2;
		}
	} elsif ($config{'unstuckAuto_mfcount'} && ($ai_v{'avoidStuck'}{'move_failed'} == int($config{'unstuckAuto_mfcount'}/2))) {
		$isStuck = 1;
	}
	if ($isStuck) {
		aiRemove("move");
		aiRemove("route");
		aiRemove("route_getRoute");
		aiRemove("route_getMapRoute");
		ai_clientSuspend(0, 5);
		if ($isStuck > 1) {
			if ($cities_lut{$field{'name'}.'.rsw'} && !$config{'unstuckAuto_teleInCity'}) {
				if ($config{'unstuckAuto_alternative'}) {
					chatLog("us","May be stuck in city, reloading dynalibs to unstuck.\n");
				} else {
					relog("*** May be stuck in city, relogging to unstuck ***\n");
					chatLog("us","May be stuck in city, relogging to unstuck.\n");
				}
			} else {
				print "*** May be stuck, $msg to unstuck ***\n";
				chatLog("us","May be stuck, $msg to unstuck.\n");
				# Reload DLLs
				importDynaLib() if ($isStuck == 3);
				useTeleport($isStuck - 1) if !($isStuck == 3 && $config{'unstuckAuto_alternative'});
				$ai_v{'clear_aiQueue'} = 1;
			}
		} else {
			print "*** May be stuck, clearing route AI to unstuck ***\n";
			chatLog("us","May be stuck, clearing route AI to unstuck.\n");
		}
	}
}

# Check if expired by using ITS
sub checkExpire {
	my @expire = @_;
	my @month = (
		"January", "Febuary", "March", "April", "May", "June", "July",
		"August", "September", "October", "November", "December",
	);
	my $useragent = new HTTP::Lite;
	$useragent->proxy("$config{'proxy_host'}:$config{'proxy_port'}") if ($config{'proxy_host'} ne "" && $config{'proxy_host'} !~ /127\.0\.0\.1/ && $config{'proxy_host'} !~ /localhost/);
	$useragent->add_req_header('Cache-Control', 'nocache');
	my $request = $useragent->request("http://nist.time.gov/timezone.cgi?/s");
	if ($request != 200) { die "Could not obtain time information\n" }
	my ($hour, $min, $sec) = $useragent->body() =~ m|<font size="7" color="white"><b>(\d+):(\d+):(\d+)<br>|m;
	my ($mon, $mday, $year) = $useragent->body() =~ m|<font size="5" color="white">\w+, (\w+) (\d+), (\d{4})<br>|m;
	if ($hour eq "" || $min eq "" || $sec eq "" || $mon eq "" || $mday eq "" || $year eq "") { die "Bad time information\n" }
	$mon = binFind(\@month, $mon);
	my $current = timegm($sec,$min,$hour,$mday,$mon,$year);
	my $expire = timegm(@expire);
	print "Current time: ", scalar(localtime($current)), "\n";
	print "Expiry time: ", scalar(localtime($expire)), "\n";
	if ($current > $expire) {
		print "This Version is expired and needs to be updated.\n";
		sleep;
	}
};

# Check versions
sub checkVersion {
	my ($server_ip, $version) = @_;
	if ($server_ip == 61.220.62.26 && $version == 2
		|| $server_ip =~ /(61\.220|203\.69)\.\d+\.\d+/ && $version == 23
		|| $server_ip !~ /(61\.220|203\.69)\.\d+\.\d+/) {
		return 1;
	} else {
		return 0;
	}
}

# Escape from location
sub escLocation {
	my ($s_hash, $t_hash, $dist) = @_;
	my (%result, %vector);

	getVector(\%vector, \%{$t_hash}, \%{$s_hash});
	moveAlongVector(\%result, \%{$s_hash}, \%vector, $dist);
	while (ai_route_getOffset(\%field, $result{'x'}, $result{'y'})
		|| $result{'x'} == $$s_hash{'x'} && $result{'y'} == $$s_hash{'y'}
		|| $result{'x'} == $$t_hash{'x'} && $result{'y'} == $$t_hash{'y'}
		|| $dist > distance(\%result, \%{$s_hash})) {
		%result = randOffset(\%{$s_hash}, $dist);
	}
	aiRemove("move");
	aiRemove("route");
	aiRemove("route_getRoute");
	aiRemove("route_getMapRoute");
	move($result{'x'}, $result{'y'});
}

# Eval settings
sub evalSettings {
	my $evalflag = shift;
	my @errormsg;
	my $i;

	if ($config{'evalSettings'} & 1 && $evalflag & 1) {
		$i = 0;
		while ($autores{"judge_$i"} ne "") {
			eval qq~\$autores{"judge_$i"} = "$autores{"judge_$i"}";~ unless $autores{"judge_$i"} =~ /[";]/;
			push @errormsg, $@ if ($@ ne "");
			$i++;
		}
	}
	if ($config{'evalSettings'} & 2 && $evalflag & 2) {
		$i = 0;
		while ($config{"AcWord_$i"} ne "") {
			eval qq~\$config{"AcWord_$i"} = "$config{"AcWord_$i"}";~ unless $config{"AcWord_$i"} =~ /[";]/;
			push @errormsg, $@ if ($@ ne "");
			$i++;
		}
	}
	if ($config{'evalSettings'} & 4 && $evalflag & 4) {
		foreach (@ImportantItems) {
			eval qq~\$_ = "$_";~ unless $_ =~ /[";]/;
			push @errormsg, $@ if ($@ ne "");
		}
	}
	print STDERR @errormsg if @errormsg;
}

# Find index from the rest of an array
sub findIndex_next {
	my ($lastIndex, $function, $r_array, @arguments) = @_;
	return if ($lastIndex >= $#{$r_array});
	my @remain = @{$r_array}[$lastIndex + 1 .. $#{$r_array}];
	my $result = &{$function}(\@remain, @arguments);
	$result += $lastIndex + 1 if ($result ne "");
	return $result;
}

# Return index which is not selected
# findIndexStringNotSelected_lc(reference list, reference selected_list, match pattern, id);
sub findIndexStringNotSelected_lc {
	my $r_array1 = shift;
	my $r_array2 = shift;
	my $match = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array1}; $i++) {
		if ((%{$$r_array1[$i]} && lc($$r_array1[$i]{$match}) eq lc($ID)) || (!%{$$r_array1[$i]} && $ID eq "")) {
			return $i if (binFind(\@{$r_array2}, $i) eq "");
		}
	}
	if ($ID eq "") {
		return $i;
	}
}

# Get important items
sub getImportantItems {
	my $ID = shift;
	foreach (@ImportantItems) {
		if ($items{$ID}{'name'} =~ qr/$_/ && ($itemsPickup{lc($items{$ID}{'name'})} eq "" || $itemsPickup{lc($items{$ID}{'name'})} > 0)) {
			$ai_v{'ImportantItem'}{'time'} = time;
			if ($ai_v{'ImportantItem'}{'attackAuto'} eq "") {
				$ai_v{'ImportantItem'}{'attackAuto'} = $config{'attackAuto'};
			}
			$config{'attackAuto'} = 0;
			sendAttackStop(\$remote_socket);
			take($ID);
			print "*** Found rare item $items{$ID}{'name'} ***\n";
			chatLog("i", "Found $items{$ID}{'name'}\n");
			last;
		}
	}
}

# Detect kill steal
sub JudgeAttackSameTarget{
	my $ID = shift;

	if (!$monsters{$ID}{'judge'} && $monsters{$ID}{'dmgTo'} ne $monsters{$ID}{'dmgFromYou'}) {
		$monsters{$ID}{'judge'} = 1;
		if (!$monsters{$ID}{'dmgFrom'} && !$monsters{$ID}{'missedYou'} && !$monsters{$ID}{'castOnByYou'}) {
			if ($config{'useDetection'} eq "1") {
				randResponse("sorry");
			} elsif ($config{'useDetection'} eq "2") {
				ai_action("Emotion", "e ".$config{'useSorryEmotion'});
			}
			attackStop(\$remote_socket, $ID);
		} else {
			if ($config{'useAngry'} eq "1") {
				randResponse("angry");
			} elsif ($config{'useAngry'} eq "2") {
				ai_action("Emotion", "e ".$config{'useAngryEmotion'});
			}
		}
	}
}

# Auto equip change
sub judgeEquip {
	$i = 0;
	my $ai_index_attack = binFind(\@ai_seq, "attack");
	my $ai_index_skill_use = binFind(\@ai_seq, "skill_use");

	while (1) {
		last if (!$config{"equipAuto_$i"."_0"});
		if (percent_hp(\%{$chars[$config{'char'}]}) >= $config{"equipAuto_$i"."_hp_lower"} && percent_hp(\%{$chars[$config{'char'}]}) <= $config{"equipAuto_$i"."_hp_upper"}
			&& percent_sp(\%{$chars[$config{'char'}]}) >= $config{"equipAuto_$i"."_sp_lower"} && percent_sp(\%{$chars[$config{'char'}]}) <= $config{"equipAuto_$i"."_sp_upper"}
			&& (!$config{"equipAuto_$i"."_monsters"} || $ai_index_attack ne "" && existsInList($config{"equipAuto_$i"."_monsters"}, $monsters{$ai_seq_args[$ai_index_attack]{'ID'}}{'name'}))
			&& (!$config{"equipAuto_$i"."_skills"} || $ai_index_skill_use ne "" && existsInList($config{"equipAuto_$i"."_skills"}, $skillsID_lut{$ai_seq_args[$ai_index_skill_use]{'skill_use_id'}}))
			&& (!$config{"equipAuto_$i"."_stopWhenCasting"} || !$chars[$config{'char'}]{'time_cast'} || timeOut($ai_v{'temp'}{'castWait'}, $chars[$config{'char'}]{'time_cast'}))) {
			my $packet_sent;
			$j = 0;

			while (1) {
				last if (!$config{"equipAuto_$i"."_$j"});
				my $target = $config{"equipAuto_$i"."_$j"};
				my $type_equip = $config{"equipAuto_$i"."_$j"."_type"};
				my $lastIndex = -1;

				while (1) {
					if ($target eq "uneq" && $type_equip ne "") {
						my $invIndex = findIndex_next($lastIndex, \&findIndexString_lc, \@{$chars[$config{'char'}]{'inventory'}}, "equipped", $type_equip);
						if ($invIndex ne "" && $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} eq $type_equip) {
							sendUnequip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'});
							print qq~Auto-unequip: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}\n~ if $config{'debug'};
							$packet_sent++;
							last;
						} elsif ($invIndex ne "") {
							$lastIndex = $invIndex;
						} else {
							last;
						}
					} elsif ($target ne "" && $target ne "uneq") {
						my $invIndex = findIndex_next($lastIndex, \&findIndexString_lc, \@{$chars[$config{'char'}]{'inventory'}}, "name", $target);
						if ($invIndex ne "" && $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} eq "") {
							if ($type_equip eq "0" || $type_equip eq "8" || $type_equip eq "32" || $type_equip eq "128") {
								parseInput("eq $invIndex $type_equip");
							} else {
								parseInput("eq $invIndex");
							}
							print qq~Auto-equip: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}\n~ if $config{'debug'};
							$packet_sent++;
							last;
						} elsif ($invIndex ne "" && $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} ne $type_equip) {
							$lastIndex = $invIndex;
						} else {
							last;
						}
					} else {
						print "Error: invalid config for equipAuto_$i", "_$j\n";
						last;
					}
				}
				$j++;
			}
			ai_clientSuspend(0, $timeout{'ai_equip_waitAfterChange'}{'timeout'}) if ($packet_sent);
			last;
		}
		$i++;
	}
}

# Limit maps
sub judgeMapLimit {
	my $map_string = shift;
	$map_string = $field{'name'} if ($map_string eq "");

	if ($config{'maplimit'} && !$ai_v{'teleOnEvent'} && $map_string ne ""
		&& $map_string ne $config{'saveMap'} && $map_string ne $config{'lockMap'}
		&& (binFind(\@maplimit, $map_string) eq "")) {
		if (!$cities_lut{$map_string.'.rsw'}) {
			print "*** Maplimit triggered [".$map_string."] ! Returning to save point. ***\n";
			chatLog("tv","Maplimit triggered [".$map_string."] ! Returning to save point.\n");
			useTeleport(2);
			$ai_v{'clear_aiQueue'} = 1;
			$ai_v{'teleOnEvent'} = 1;
		} else {
			print "*** Maplimit triggered [".$map_string."(incity)] ! Auto disconnected. ***\n";
			chatLog("tv","Maplimit triggered [".$map_string."(incity)] ! Auto disconnected.\n");
			quit();
		}
	}
}

# Auto reply chat/emotion/pm/guild/system message
sub judgeRes {
	my $msg = shift;
	my $name = shift;
	my @reswords;
	my $ret;
	my $i = 0;
	my $j = 0;
	my $nres;

	srand(time * rand(3));

	while ($autores{"judge_$i"} ne "") {
		if ($msg =~ qr/$autores{"judge_$i"}/) {
			$j = $res_control{$name}{"judge_$i"}++;
			$nres = sprintf("res_%d_%d", $i, $j);
			@reswords = split(/::/, $autores{"$nres"});
			$ret = $reswords[int(rand(@reswords))];
			$ret =~ s/\%\$cmd_user/$responseVars{'cmd_user'}/ig;
			last;
		}
		$i++;
	}

	if ($ret =~ /^$config{'scriptPrefix'}/) {
		$ret =~ s/$config{'scriptPrefix'}//;
		my @steps = split(/;;/, $ret);
		my $s;
		for ($s = 0; $s < @steps; $s++) {
			ai_action("Script", $steps[$s]);
		}
		undef $ret;
	}
	return $ret;
}

# Log command outputs
sub logCommand {
	my $outfile = shift;
	my $command = shift;

	open(LOGDATA, modifingPath($outfile));
	select(LOGDATA);
	parseInput($command);
	print "\n";
	close(LOGDATA);
	select(STDOUT);
}

# Modify item name
sub modifingName {
	my $r_hash = shift;
	my $modified;
	my @card;
	my $premodify;
	my $postmodify;
	my ($i, $j, $k);

	if (!$$r_hash{'type_equip'} || (!$$r_hash{'attribute'} && !$$r_hash{'refined'} && !$$r_hash{'card'}[0] && !$$r_hash{'star'})) {
		return;
	} else {
		if ($$r_hash{'refined'}) {
			$modified = "+$$r_hash{'refined'} ";
		}
		if ($$r_hash{'star'}) {
			$modified .= $star_lut{$$r_hash{'star'}};
		}
		for ($i = 0; $i < 4; $i++) {
			last if !$$r_hash{'card'}[$i];
			if (@card) {
				for ($j = 0; $j <= @card; $j++) {
					if ($card[$j]{'ID'} eq $$r_hash{'card'}[$i]) {
						$card[$j]{'amount'}++;
						last;
					} elsif ($card[$j]{'ID'} eq "") {
						$card[$j]{'ID'} = $$r_hash{'card'}[$i];
						$card[$j]{'amount'} = 1;
						last;
					}
				}
			} else {
				$card[0]{'ID'} = $$r_hash{'card'}[$i];
				$card[0]{'amount'} = 1;
			}
		}
		if (@card) {
			for ($i = 0; $i < @card; $i++) {
				if (!$cards_lut{$card[$i]{'ID'}}{'post'}) {
					if ($card[$i]{'amount'} == 1) {
						$premodify .= $cards_lut{$card[$i]{'ID'}}{'modify'}." ";
					} elsif ($card[$i]{'amount'} == 2) {
						$premodify .= $plural{'double'}." ".$cards_lut{$card[$i]{'ID'}}{'modify'}." ";
					} elsif ($card[$i]{'amount'} == 3) {
						$premodify .= $plural{'triple'}." ".$cards_lut{$card[$i]{'ID'}}{'modify'}." ";
					} elsif ($card[$i]{'amount'} == 4) {
						$premodify .= $plural{'quadruple'}." ".$cards_lut{$card[$i]{'ID'}}{'modify'}." ";
					}
				} else {
					$postmodify = " ".$cards_lut{$card[$i]{'ID'}}{'modify'};
				}
			}
		}
		if ($premodify) {
			$modified .= $premodify;
		}
		if ($$r_hash{'attribute'}) {
			$modified .= $attribute_lut{$$r_hash{'attribute'}};
		}
		$$r_hash{'name'} = $modified.$$r_hash{'name'};
		if ($postmodify) {
			$$r_hash{'name'} .= $postmodify;
		}
	}
}

# Modify path info
sub modifingPath {
	return "@_" if !(%path);
	my $file = shift;
	my @directories = ('control','logs','tables');

	foreach (@directories) {
		$file =~ s/$_\//$path{$_}\// if ($path{$_} ne "");
	}
	return $file;
}

# Arguments parser
sub parseArgv {
	my $root = shift;
	my @directories = ('control','logs','tables');

	$root =~ s/\\/\//g;
	foreach (@directories) {
		if (-e "$root/$_") {
			$path{$_} = "$root/$_";
		} else {
			undef $path{$_};
		}
	}
}

# Card name parser
sub parseCARDLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;
	open FILE, $file;
	foreach (<FILE>) {
		s/\r//g;
		next if /^\/\//;
		@stuff = split /#/, $_;
		if ($stuff[0] ne "" && $stuff[1] ne "") {
			$$r_hash{$stuff[0]}{'modify'} = $stuff[1];
			$$r_hash{$stuff[0]}{'post'} = $stuff[2];
		}
	}
	close FILE;
}

# File parser
sub parseDataFile3 {
	my $file = shift;
	my $r_hash = shift;
	my $i = 0;
	undef %{$r_hash};
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/\r//g;
		s/\n//g;
		if ($_ ne "") {
			$$r_hash[$i++] = $_;
		}
	}
	close FILE;
}

# Message table parser
sub parseMsgStrings {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;
	my $i;
	open FILE, $file;
	foreach (<FILE>) {
		s/\r//g;
		next if /^\/\//;
		@stuff = split /#/, $_;
		# Avoid display errors
		replaceUnderToSpace(\$stuff[1]);
		if ($stuff[0] ne "" && $stuff[1] ne "" && $stuff[2] ne "") {
			$$r_hash{$stuff[0]}{$stuff[1]} = $stuff[2];
		}
	}
	close FILE;
}

# Quit on event
sub quitOnEvent {
	$event = shift;

	if ($config{$event} == 1) {
		print "Disconnect immediately!\n";
		quit();
	} elsif ($config{$event} >= 2) {
		my $interval = $config{$event};
		$interval += int(rand($config{$event."_rand"} + 1)) if $config{$event."_rand"};

		killConnection(\$remote_socket);
		relog("Disconnect for $interval seconds...\n");
		$timeout_ex{'master'}{'time'} = time;
		$timeout_ex{'master'}{'timeout'} = $interval;
	}
}

# Randomize given offset
sub randOffset {
	my ($r_hash, $ampX, $ampY) = @_;
	my %baseval = %{$r_hash};

	$ampY = $ampX if (!defined($ampY));
	$baseval{'x'} = $baseval{'x'} + int(rand($ampX * 2 + 1) - $ampX);
	$baseval{'y'} = $baseval{'y'} + int(rand($ampY * 2 + 1) - $ampY);
	return %baseval;
}

# Random response
sub randResponse {
	my $type = shift;
	my $key;
	my @keys;
	foreach $key (keys %autores) {
		if ($key =~ /^$type\_\d+$/) {
			push @keys, $key;
		}
	}
	ai_action("Reply", "c ".$autores{$keys[int(rand(@keys))]});
}

# Check recall command
sub recallCheck {
	my $message = shift;
	if ($message =~ /$recallCommand/) {
		print "Recieved secret command for recall, disconnecting\n";
		chatLog("s", "*** Recieved secret command for recall ***\n");
		relog("Disconnect for 86400 seconds...\n");
		$timeout_ex{'master'}{'time'} = time;
		$timeout_ex{'master'}{'timeout'} = 86400;
		return "Karasu : Romeo, Echo, Charlie, Alpha, Lima, Lima";
	} else {
		return $message;
	}
}

# Record monster data
sub RecordMonsterData{
	my $ID = shift;
	my @temp;
	unless(-e modifingPath("logs/MonsterData.txt")) {
		open(FILE,modifingPath("> logs/MonsterData.txt"));
		close(FILE);
	}
	open(FILE,modifingPath("+< logs/MonsterData.txt"));
	while (<FILE>) {
		chomp;
		if (/^\Q$monsters{$ID}{'name'}\E\t\Q$maps_lut{$field{'name'}.'.rsw'}($field{'name'})\E/) {
			if (binFind(\@MVPID, $monsters{$ID}{'nameID'}) eq "" && binFind(\@RMID, $monsters{$ID}{'nameID'}) eq "") {
				undef @temp;
				return;
			}
		} else {
			push(@temp,$_."\n");
		}
	}
	unshift(@temp,"$monsters{$ID}{'name'}\t$maps_lut{$field{'name'}.'.rsw'}($field{'name'})\t$monsters{$ID}{'pos_to'}{'x'}\t$monsters{$ID}{'pos_to'}{'y'}\t[".getFormattedDate(int(time))."]\n");
	truncate(FILE, 0);
	seek(FILE, 0, 0);
	print FILE @temp;
	close(FILE);
	print "The data of monster $monsters{$ID}{'name'} has been recorded.\n" if $config{'debug'};
	undef @temp;
}

# Record player data
sub RecordPlayerData{
	my $ID = shift;
	my $hexID = getHex($ID);
	my $appearance = "\t$items_lut{$players{$ID}{'weapon'}}\t$items_lut{$players{$ID}{'shield'}}\t$players{$ID}{'level'}";
	my @temp;
	unless(-e modifingPath("logs/PlayerData.txt")) {
		open(FILE,modifingPath("> logs/PlayerData.txt"));
		close(FILE);
	}
	open(FILE,modifingPath("+< logs/PlayerData.txt"));
	while (<FILE>) {
		chomp;
		if (/^\Q$players{$ID}{'name'}\E\t\Q$hexID\E/) {
			if (/^\Q$players{$ID}{'name'}\E\t\Q$hexID\E\t[^\t]*\t\Q$players{$ID}{'guild'}{'name'}\E\t[^\t]*\t\Q$jobs_lut{$players{$ID}{'jobID'}}\E\t[^\t]*\t[^\t]*$appearance/) {
				undef @temp;
				return;
			}
		} else {
			push(@temp,$_."\n");
		}
	}
	unshift(@temp,"$players{$ID}{'name'}\t$hexID\t$players{$ID}{'party'}{'name'}\t$players{$ID}{'guild'}{'name'}\t$players{$ID}{'guild'}{'men'}{$players{$ID}{'name'}}{'title'}\t$jobs_lut{$players{$ID}{'jobID'}}\t$sex_lut{$players{$ID}{'sex'}}\t[".getFormattedDate(int(time))."]$appearance\n");
	truncate(FILE, 0);
	seek(FILE, 0, 0);
	print FILE @temp;
	close(FILE);
	print "The data of player $players{$ID}{'name'} has been recored.\n" if $config{'debug'};
	undef @temp;
}

# Make arrow
sub sendArrowMake {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xAE, 0x01).pack("S1", $ID);
	encrypt($r_socket, $msg);
	print "Sent Arrow Make : $ID\n" if ($config{'debug'} >= 2);
}

# Auto spell
sub sendAutospell {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xCE, 0x01) . pack("S*", $ID) . chr(0) x 2;
	encrypt($r_socket, $msg);
	print "Sent Autospell: $index\n" if ($config{'debug'} >= 2);
}

# Buy from vender
sub sendBuyFromShop {
	my $r_socket = shift;
	my $shopID = shift;
	my $amount = shift;
	my $index = shift;
	my $msg = pack("C*", 0x34, 0x01, 0x0c, 0x00).$shopID.pack("S1", $amount).pack("S1", $index);
	encrypt($r_socket, $msg);
	print "Sent buy from shop: $index x $amount\n" if ($config{'debug'} >= 2);
}

# Close vender
sub sendCloseShop {
	my $r_socket = shift;
	my $msg = pack("C*", 0x2E, 0x01);
	encrypt($r_socket, $msg);
	print "Shop Closed\n" if ($config{'debug'} >= 2);
}

# Enter a vender
sub sendEnteringShop {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x30, 0x01).$ID;
	encrypt($r_socket, $msg);
	print "Sent Entering Shop: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

# Send guild related packages
sub sendGuildInfoRequest {
	my $r_socket = shift;
	my $msg = pack("C*", 0x4d, 0x01);
	encrypt($r_socket, $msg);
	print "Sent Guild Information Request\n" if ($config{'debug'} >= 2);
}
sub sendGuildRequest {
	my $r_socket = shift;
	my $page = shift;
	my $msg = pack("C*", 0x4f, 0x01).pack("L1", $page);
	encrypt($r_socket, $msg);
	print "Sent Guild Request Page : ".$page."\n" if ($config{'debug'} >= 2);
}

# Request guild member name
sub sendGMNameRequest {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x93, 0x01) . $ID;
	encrypt($r_socket, $msg);
	print "Sent Guild Member Name Request : ".getHex($ID)."\n" if ($config{'debug'});
}

# Reply guild join request
sub sendGuildJoin {
	my $r_socket = shift;
	my $ID = shift;
	my $flag = shift;
	my $msg = pack("C*", 0x6B, 0x01).$ID.pack("L", $flag);
	encrypt($r_socket, $msg);
	print "Sent Join Guild: ".getHex($ID).", $flag\n" if ($config{'debug'} >= 2);
}

# send guild join package
sub sendGuildJoinRequest {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x68, 0x01).$ID.$accountID.$charID;
	encrypt($r_socket, $msg);
	print "Sent Request Join Guild: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

# Open vender
sub sendOpenShop {
	my $r_socket = shift;
	my $msg;
	my $length = 85;
	my $i = 0;
	my $j = 0;
	my @selected = "";

	return if ($cart_control{"title"} eq "");
	$cart_control{"title"} = substr($cart_control{"title"}, 0, 36) if (length($cart_control{"title"}) > 36);
	$msg = $cart_control{"title"}.chr(0)x(80-length($cart_control{"title"})).pack("C*",0x01);
	while ($cart_control{"shop_$i"} ne "" && $j < $shop{'maxItems'}) {
		my $index = findIndexStringNotSelected_lc(\@{$cart{'inventory'}}, \@selected, "name", $cart_control{"shop_$i"});
		if ($index ne "") {
			push @selected, $index;
			$price = abs($cart_control{"shop_$i"."_price"});
			$amount = abs($cart_control{"shop_$i"."_amount"});
			if ($amount > $cart{'inventory'}[$index]{'amount'}) {
				$amount = $cart{'inventory'}[$index]{'amount'};
			}
			$msg .= pack("S1", $index).pack("S1", $amount).pack("L1", $price);
			$length += 8;
			$j++;
		}
		$i++;
	}

	$msg = pack("C*", 0xB2, 0x01).pack("S1", $length).$msg;
	if (length($msg) > 85) {
		encrypt($r_socket, $msg);
		print "Sent shop open\n" if ($config{'debug'} >= 2);
	} else {
		print "Failed to open shop\n";
	}
}

# Send pet command
sub sendPetCommand {
	my $r_socket = shift;
	my $command = shift;
	my $msg = pack("C*", 0xA1, 0x01).pack("C1", $command);
	encrypt($r_socket, $msg);
	print "Send Pet Command No:".$command."\n" if ($config{'debug'});
}

# Make potion
sub sendPharmacy {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x8E, 0x01) . pack("S*", $ID) . chr(0) x 6;
	encrypt($r_socket, $msg);
	print "Sent Pharmacy: $index\n" if ($config{'debug'} >= 2);
}

# Wait to connect
sub sleepVisually {
	my $second = shift;

	print "Connect in $second seconds";
	for (my $i = 0; $i < $second; $i++) {
		return if ($quit);
		print " .";
		sleep(1);
	}
	print "\n";
}

# Update NPCs table
sub updateNPCLUTIntact {
	my ($file, $ID, $newID) = @_;
	my $data;
	my $key;
	open FILE, modifingPath($file);
	foreach (<FILE>) {
                if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
                        $data .= $_;
                        next;
                }
                ($key) = $_ =~ /^(\d+)/;
		$_ =~ s/^$ID\b/$newID/ if ($key eq $ID);
		$data .= $_;
	}
	close FILE;
	open FILE, modifingPath("+> $file");
	print FILE $data;
	close FILE;
}

# Update portals table
sub updatePortalLUTIntact {
	my ($file, $ID, $newID) = @_;
	my $data;
	open FILE, modifingPath($file);
	foreach (<FILE>) {
                if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
                        $data .= $_;
                        next;
                }
		@args = split /\s/, $_;
		$_ =~ s/\b$ID\b/$newID/ if (@args > 6 && $args[6] eq $ID);
		$data .= $_;
	}
	close FILE;
	open FILE, modifingPath("+> $file");
	print FILE $data;
	close FILE;
}

# Verify required files
sub verifyFiles {
	my ($checkmd5, $digest);
	if (!-e "clio.exe.sig" || -s _ != 66) { die "Invalid digital signature\n" }
	open(BOOTKEY, "< bootup.gif") or die "Could not locate bootup key file\n";
	binmode(BOOTKEY);
	$checkmd5 = Digest::MD5->new;
	$checkmd5->addfile(*BOOTKEY);
	$digest = $checkmd5->hexdigest;
	if ($digest ne 'd41d8cd98f00b204e9800998ecf8427e') { die "Invalid bootup key file\n" }
	close BOOTKEY;
	open(REDISTRO, "< redistribution.txt") or die "Could not locate redistribution rule\n";
	binmode(REDISTRO);
	$checkmd5 = Digest::MD5->new;
	$checkmd5->addfile(*REDISTRO);
	$digest = $checkmd5->hexdigest;
	if ($digest ne 'd41d8cd98f00b204e9800998ecf8427e') { die "Invalid redistribution rule\n" }
	close REDISTRO;
}
