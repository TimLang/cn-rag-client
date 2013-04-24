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
use Utils::RSK;
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

	my $tempValues = RSK::GetReply(hex($PacketID));
	$tempValues = sprintf("0x%04x\n",$tempValues);
	$tempValues =~ s/^0+//;
	$tempValues = hex($tempValues);
	
	# Dispatching Sync Ex Reply
	$messageSender->sendReplySyncRequestEx($tempValues);
}

1;
