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

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
	$self->{char_create_version} = 1;


	my %packets = (

		'091B' => ['actor_action', 'a4 C', [qw(targetID type)]],
		'092B' => ['skill_use', 'v2 a4', [qw(lv skillID targetID)]],
		'0884' => ['character_move','a3', [qw(coords)]],
		'095D' => ['sync', 'V', [qw(time)]],
		'0897' => ['actor_look_at', 'v C', [qw(head body)]],
		'0938' => ['item_take', 'a4', [qw(ID)]],
		'0879' => ['item_drop', 'v2', [qw(index amount)]],
		'0968' => ['storage_item_add', 'v V', [qw(index amount)]],
		'088E' => ['storage_item_remove', 'v V', [qw(index amount)]],
		'08AB' => ['skill_use_location', 'v4', [qw(lv skillID x y)]],
		'0860' => ['actor_info_request', 'a4', [qw(ID)]],
		'0965' => ['map_login', 'a4 a4 a4 V C', [qw(accountID charID sessionID tick sex)]],
		'0898' => ['homunculus_command', 'v C', [qw(commandType, commandID)]],
		'07D7' => ['party_setting', 'V C2', [qw(exp itemPickup itemDivision)]],
	);
	
	$self->{packet_list}{$_} = $packets{$_} for keys %packets;
	
	my %handlers = qw(
		
		actor_action 091B
		skill_use 092B
		character_move 0884
		sync 095D
		actor_look_at 0897
		item_take 0938
		item_drop 0879
		storage_item_add 0968
		storage_item_remove 088E
		skill_use_location 08AB
		actor_info_request 0860
		map_login 0965
		homunculus_command 0898
		party_setting 07D7
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
	# K
	$enc_val1 = Math::BigInt->new('0x4990701c');
	# M
	$enc_val3 = Math::BigInt->new('0x65307aaf');
	# A
	$enc_val2 = Math::BigInt->new('0x4e6547cf');
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