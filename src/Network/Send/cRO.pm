#########################################################################
#  OpenKore - Network subsystem
#  This module contains functions for sending messages to the server.
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################
package Network::Send::cRO;

use strict;
use Globals;
use Log qw(message warning error debug);
use Utils qw(existsInList getHex getTickCount getCoordString);
use base qw(Network::Send::ServerType0);
use Math::BigInt;
use Digest::MD5;
use I18N qw(bytesToString stringToBytes);
#modify by jackywei 20130420
use Utils::RSK;

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
	my $ID1 = uc(sprintf("%04x",RSK::GetSendID(1)));
	my $ID2 = uc(sprintf("%04x",RSK::GetSendID(2)));
	my $ID3 = uc(sprintf("%04x",RSK::GetSendID(3)));
	my $ID4 = uc(sprintf("%04x",RSK::GetSendID(4)));
	my $ID5 = uc(sprintf("%04x",RSK::GetSendID(5)));
	my $ID6 = uc(sprintf("%04x",RSK::GetSendID(6)));
	my $ID7 = uc(sprintf("%04x",RSK::GetSendID(7)));
	my $ID8 = uc(sprintf("%04x",RSK::GetSendID(8)));
	my $ID9 = uc(sprintf("%04x",RSK::GetSendID(9)));
	my $ID10 = uc(sprintf("%04x",RSK::GetSendID(10)));
	my $ID11 = uc(sprintf("%04x",RSK::GetSendID(11)));
	my $ID12 = uc(sprintf("%04x",RSK::GetSendID(12)));
	my $ID13 = uc(sprintf("%04x",RSK::GetSendID(13)));
	$self->{char_create_version} = 1;

	my %packets = (
		"$ID1" => ['actor_action', 'a4 C', [qw(targetID type)]],
		"$ID2" => ['skill_use', 'v2 a4', [qw(lv skillID targetID)]],
		"$ID3" => ['character_move','a3', [qw(coords)]],
		"$ID4" => ['sync', 'V', [qw(time)]],
		"$ID5" => ['actor_look_at', 'v C', [qw(head body)]],
		"$ID6" => ['item_take', 'a4', [qw(ID)]],
		"$ID7" => ['item_drop', 'v2', [qw(index amount)]],
		"$ID8" => ['storage_item_add', 'v V', [qw(index amount)]],
		"$ID9" => ['storage_item_remove', 'v V', [qw(index amount)]],
		"$ID10" => ['skill_use_location', 'v4', [qw(lv skillID x y)]],
		"$ID11" => ['actor_info_request', 'a4', [qw(ID)]],
		"$ID12" => ['map_login', 'a4 a4 a4 V C', [qw(accountID charID sessionID tick sex)]],
		"$ID13" => ['homunculus_command', 'v C', [qw(commandType, commandID)]],
		'07D7' => ['party_setting', 'V C2', [qw(exp itemPickup itemDivision)]],
		'0187' => ['ban_check', 'a4', [qw(accountID)]],
	);
	
	$self->{packet_list}{$_} = $packets{$_} for keys %packets;
	
	my %handlers = (
		'actor_action' => "$ID1",
		'skill_use' => "$ID2",
		'character_move' => "$ID3",
		'sync' => "$ID4",
		'actor_look_at' => "$ID5",
		'item_take' => "$ID6",
		'item_drop' => "$ID7",
		'storage_item_add' => "$ID8",
		'storage_item_remove' => "$ID9",
		'skill_use_location' => "$ID10",
		'actor_info_request' => "$ID11",
		'map_login' => "$ID12",
		'homunculus_command' => "$ID13",
		'party_setting' => '07D7',
		'ban_check' => '0187',
	);
	
	$self->{packet_lut}{$_} = $handlers{$_} for keys %handlers;
	
	$self;
}

# Local Servertype Globals
my $map_login = 0;
my $enc_val3 = 0;
		
sub encryptMessageID {
	my ($self, $r_message, $MID) = @_;
	
	# Checking In-Game State
	if ($self->{net}->getState() != Network::IN_GAME && !$map_login) { $enc_val1 = 0; $enc_val2 = 0; return; }
	
	# Turn Off Map Login Flag
	if ($map_login)	{ $map_login = 0; }
	
		# Calculating the Encryption Key
		$enc_val1 = $enc_val1->bmul($enc_val3)->badd($enc_val2) & 0xFFFFFFFF;
	
		# Xoring the Message ID
		$MID = ($MID ^ (($enc_val1 >> 8 >> 8) & 0x7FFF)) & 0xFFFF;
		$$r_message = pack("v", $MID) . substr($$r_message, 2);
}

sub PrepareKeys() {
	#modify by jackywei 20130420
	#K
	$enc_val1 = Math::BigInt->new(sprintf("0x%08x",RSK::GetKey11EncVal(1)));
	# M
	$enc_val3 = Math::BigInt->new(sprintf("0x%08x",RSK::GetKey11EncVal(3)));
	# A
	$enc_val2 = Math::BigInt->new(sprintf("0x%08x",RSK::GetKey11EncVal(2)));
	#modify end
}

sub sendMasterLogin {
	my ($self, $username, $password, $master_version, $version) = @_;
	my $msg;
	my $password_hash;
	
	for (Digest::MD5->new) {
		$_->add($password);
		$password_hash = $_->hexdigest;
	}
	$msg = pack("v1 S1 V", hex("0987"), length($username) + 41, $version || $self->version) .
		pack("a*", $password_hash) .
		pack("C*", $master_version).
		pack("a*", $username);

	$self->sendToServer($msg);
	debug "Sent sendMasterLogin\n", "sendPacket", 2;
}


sub sendBancheck {
	my ($self, $accountID) = @_;
	$self->sendToServer($self->reconstruct({
		switch => 'ban_check',
		accountID => $accountID,
	}));
	debug "Sent sendBancheck\n", "sendPacket", 2;
}


sub sendMapLogin {
	my ($self, $accountID, $charID, $sessionID, $sex) = @_;
	my $msg;

	$sex = 0 if ($sex > 1 || $sex < 0); # Sex can only be 0 (female) or 1 (male)
	
	if ( $map_login == 0 ) { PrepareKeys(); $map_login = 1; }

	# Reconstructing Packet 
	$msg = $self->reconstruct({
		switch => 'map_login',
		accountID => $accountID,
		charID => $charID,
		sessionID => $sessionID,
		tick => getTickCount,
		sex => $sex,
	});

	$self->sendToServer($msg);
	debug "Sent sendMapLogin\n", "sendPacket", 2;
}

sub sendHomunculusCommand {
	my ($self, $command, $type) = @_;

	$self->sendToServer($self->reconstruct({
		switch => 'homunculus_command',
		commandType => $type,
		commandID => $command,
	}));
	debug "Sent Homunculus Command $command", "sendPacket", 2;
}

1;