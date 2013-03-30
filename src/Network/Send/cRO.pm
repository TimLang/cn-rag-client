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

		'0369' => ['actor_action', 'a4 C', [qw(targetID type)]],
		'0437' => ['character_move','a3', [qw(coords)]],		
		'035F' => ['sync', 'V', [qw(time)]],
		'0361' => ['actor_look_at', 'v C', [qw(head body)]],
		'0360' => ['item_take', 'a4', [qw(ID)]],
		'0919' => ['item_drop', 'v2', [qw(index amount)]],		
		'0367' => ['storage_item_add', 'v V', [qw(index amount)]],
		'0947' => ['storage_item_remove', 'v V', [qw(index amount)]],
		'0438' => ['skill_use_location', 'v4', [qw(lv skillID x y)]],
		'0940' => ['actor_info_request', 'a4', [qw(ID)]],
		'0860' => ['map_login', 'a4 a4 a4 V C', [qw(accountID charID sessionID tick sex)]],	
		'07D7' => ['party_setting', 'V C2', [qw(exp itemPickup itemDivision)]],		
	);
	
	$self->{packet_list}{$_} = $packets{$_} for keys %packets;	
	
	my %handlers = qw(	
		
		actor_action 0369
		character_move 0437
		sync 035F
		actor_look_at 0361
		item_take 0360
		item_drop 0919
		storage_item_add 0367
		storage_item_remove 0947
		skill_use_location 0438
		actor_info_request 0940
		map_login 0860
		party_setting 07D7
	);
	
	$self->{packet_lut}{$_} = $handlers{$_} for keys %handlers;
	
	$self;
}

# Local Servertype Globals
my $map_login = 0;
my $enc_val3 = 0;
		
sub encryptMessageID 
{
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

sub PrepareKeys()
{
	# K
	$enc_val1 = Math::BigInt->new('0x5e2f2f8e');
	# M
	$enc_val3 = Math::BigInt->new('0x280c0c55');
	# A
	$enc_val2 = Math::BigInt->new('0x7dd07a71');
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

sub sendMapLogin 
{
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

sub sendFriendRequest {
	my ($self, $name) = @_;

	my $binName = stringToBytes($name);
	$binName = substr($binName, 0, 24) if (length($binName) > 24);
	$binName = $binName . chr(0) x (24 - length($binName));
	my $msg = pack("C*", 0x21, 0x09) . $binName;

	$self->sendToServer($msg);
	debug "Sent Request to be a friend: $name\n", "sendPacket";
}

1;