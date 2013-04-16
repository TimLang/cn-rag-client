#########################################################################
#  OpenKore - Network subsystem
#  Copyright (c) 2006 OpenKore Team
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################
package Network::Receive::cRO;

use strict;
use Log qw(message warning error debug);
use base 'Network::Receive::ServerType0';
use Globals;
use Translation;
use Misc;
use log qw(debug message);
use Data::Dumper;

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
	
	my %packets = (
	
		'0097' => ['private_message', 'v Z24 V Z*', [qw(len privMsgUser flag privMsg)]],
		'07FA' => ['inventory_item_removed', 'v3', [qw(reason index amount)]],
		
		'0893' => ['sync_request_ex'],
		'0923' => ['sync_request_ex'],
		'093B' => ['sync_request_ex'],
		'0881' => ['sync_request_ex'],
		'0963' => ['sync_request_ex'],
		'0202' => ['sync_request_ex'],
		'0887' => ['sync_request_ex'],
		'0873' => ['sync_request_ex'],
		'0802' => ['sync_request_ex'],
		'0882' => ['sync_request_ex'],
		'095E' => ['sync_request_ex'],
		'086E' => ['sync_request_ex'],
		'0877' => ['sync_request_ex'],
		'0924' => ['sync_request_ex'],
		'0817' => ['sync_request_ex'],
		'07EC' => ['sync_request_ex'],
		'0943' => ['sync_request_ex'],
		'092D' => ['sync_request_ex'],
		'092A' => ['sync_request_ex'],
		'085E' => ['sync_request_ex'],
		'08A4' => ['sync_request_ex'],
		'08AC' => ['sync_request_ex'],
		'0899' => ['sync_request_ex'],
		'0365' => ['sync_request_ex'],
		'0957' => ['sync_request_ex'],
		'0944' => ['sync_request_ex'],
		'0437' => ['sync_request_ex'],
		'0870' => ['sync_request_ex'],
		'08A8' => ['sync_request_ex'],
		'0952' => ['sync_request_ex'],
		'035F' => ['sync_request_ex'],
		'095B' => ['sync_request_ex'],
		'0927' => ['sync_request_ex'],
		'092C' => ['sync_request_ex'],
		'0436' => ['sync_request_ex'],
		'08A3' => ['sync_request_ex'],
		'085B' => ['sync_request_ex'],
		'023B' => ['sync_request_ex'],
		'0931' => ['sync_request_ex'],
		'0939' => ['sync_request_ex'],
		'0920' => ['sync_request_ex'],
		'0362' => ['sync_request_ex'],
		'087A' => ['sync_request_ex'],
		'08A0' => ['sync_request_ex'],
		'0926' => ['sync_request_ex'],
		'086B' => ['sync_request_ex'],
		'0929' => ['sync_request_ex'],
		'086F' => ['sync_request_ex'],
		'089E' => ['sync_request_ex'],
		'0925' => ['sync_request_ex'],
		'087D' => ['sync_request_ex'],
		'0932' => ['sync_request_ex'],
		'0868' => ['sync_request_ex'],
		'0874' => ['sync_request_ex'],
		'088D' => ['sync_request_ex'],
		'0866' => ['sync_request_ex'],
		'0838' => ['sync_request_ex'],
		'0928' => ['sync_request_ex'],
		'0360' => ['sync_request_ex'],
		'0956' => ['sync_request_ex'],
		'0918' => ['sync_request_ex'],
		'0885' => ['sync_request_ex'],
		'085C' => ['sync_request_ex'],
		'0894' => ['sync_request_ex'],
		'08A1' => ['sync_request_ex'],
		'094C' => ['sync_request_ex'],
		'0861' => ['sync_request_ex'],
		'0917' => ['sync_request_ex'],
		'0281' => ['sync_request_ex'],
		'0964' => ['sync_request_ex'],
		'0819' => ['sync_request_ex'],
		'0935' => ['sync_request_ex'],
		'0919' => ['sync_request_ex'],
		'094D' => ['sync_request_ex'],
		'0921' => ['sync_request_ex'],
		'093C' => ['sync_request_ex'],
		'088C' => ['sync_request_ex'],
		'092F' => ['sync_request_ex'],
		'0946' => ['sync_request_ex'],
		'091A' => ['sync_request_ex'],
		'089C' => ['sync_request_ex'],
		'0940' => ['sync_request_ex'],
		'095F' => ['sync_request_ex'],
		'0967' => ['sync_request_ex'],
	);

	foreach my $switch (keys %packets) {
		$self->{packet_list}{$switch} = $packets{$switch};
	}

	return $self;
}

sub sync_request_ex {
	my ($self, $args) = @_;
	
	# Debug Log
	# message "Received Sync Ex : 0x" . $args->{switch} . "\n";
	
	# Computing Sync Ex - By Fr3DBr
	my $PacketID = $args->{switch};
	
	# Sync Ex Reply Array
	my %sync_ex_question_reply = (
		'0893' => '0969',
		'0923' => '0867',
		'093B' => '0896',
		'0881' => '0889',
		'0963' => '0948',
		'0202' => '0933',
		'0887' => '0886',
		'0873' => '0941',
		'0802' => '086D',
		'0882' => '0367',
		'095E' => '088F',
		'086E' => '0966',
		'0877' => '02C4',
		'0924' => '07E4',
		'0817' => '0876',
		'07EC' => '0895',
		'0943' => '0883',
		'092D' => '0961',
		'092A' => '0835',
		'085E' => '0363',
		'08A4' => '0891',
		'08AC' => '0945',
		'0899' => '08A6',
		'0365' => '0949',
		'0957' => '089F',
		'0944' => '0922',
		'0437' => '0954',
		'0870' => '0890',
		'08A8' => '093A',
		'0952' => '089B',
		'035F' => '0364',
		'095B' => '0863',
		'0927' => '0366',
		'092C' => '0878',
		'0436' => '091E',
		'08A3' => '094E',
		'085B' => '0953',
		'023B' => '0815',
		'0931' => '087C',
		'0939' => '087B',
		'0920' => '0934',
		'0362' => '0947',
		'087A' => '0955',
		'08A0' => '093F',
		'0926' => '08A2',
		'086B' => '0960',
		'0929' => '08A5',
		'086F' => '0892',
		'089E' => '08AA',
		'0925' => '086A',
		'087D' => '096A',
		'0932' => '089D',
		'0868' => '0942',
		'0874' => '0962',
		'088D' => '08A9',
		'0866' => '092E',
		'0838' => '0959',
		'0928' => '091F',
		'0360' => '0862',
		'0956' => '087F',
		'0918' => '085D',
		'0885' => '0937',
		'085C' => '0361',
		'0894' => '0875',
		'08A1' => '08A7',
		'094C' => '088A',
		'0861' => '091C',
		'0917' => '095C',
		'0281' => '022D',
		'0964' => '0871',
		'0819' => '0368',
		'0935' => '094B',
		'0919' => '094A',
		'094D' => '088B',
		'0921' => '0369',
		'093C' => '0865',
		'088C' => '085A',
		'092F' => '094F',
		'0946' => '0872',
		'091A' => '0438',
		'089C' => '089A',
		'0940' => '0936',
		'095F' => '0888',
		'0967' => '0869',
	);
	
	# Getting Sync Ex Reply ID from Table
	my $SyncID = $sync_ex_question_reply{$PacketID};
	
	# Cleaning Leading Zeros
	$PacketID =~ s/^0+//;	
	
	# Cleaning Leading Zeros	
	$SyncID =~ s/^0+//;
	
	# Debug Log
	# print sprintf("Received Ex Packet ID : 0x%s => 0x%s\n", $PacketID, $SyncID);

	# Converting ID to Hex Number
	$SyncID = hex($SyncID);

	# Dispatching Sync Ex Reply
	$messageSender->sendReplySyncRequestEx($SyncID);
}

1;