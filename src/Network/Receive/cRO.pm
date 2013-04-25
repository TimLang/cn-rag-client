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
		
		'0866' => ['sync_request_ex'],
		'0931' => ['sync_request_ex'],
		'08A7' => ['sync_request_ex'],
		'08AA' => ['sync_request_ex'],
		'0892' => ['sync_request_ex'],
		'0437' => ['sync_request_ex'],
		'0897' => ['sync_request_ex'],
		'0891' => ['sync_request_ex'],
		'0929' => ['sync_request_ex'],
		'086D' => ['sync_request_ex'],
		'095F' => ['sync_request_ex'],
		'085B' => ['sync_request_ex'],
		'083C' => ['sync_request_ex'],
		'0884' => ['sync_request_ex'],
		'0927' => ['sync_request_ex'],
		'08AB' => ['sync_request_ex'],
		'096A' => ['sync_request_ex'],
		'07EC' => ['sync_request_ex'],
		'0946' => ['sync_request_ex'],
		'094B' => ['sync_request_ex'],
		'0920' => ['sync_request_ex'],
		'0938' => ['sync_request_ex'],
		'095E' => ['sync_request_ex'],
		'0879' => ['sync_request_ex'],
		'0883' => ['sync_request_ex'],
		'08AD' => ['sync_request_ex'],
		'0918' => ['sync_request_ex'],
		'094D' => ['sync_request_ex'],
		'0958' => ['sync_request_ex'],
		'0933' => ['sync_request_ex'],
		'0873' => ['sync_request_ex'],
		'0952' => ['sync_request_ex'],
		'0896' => ['sync_request_ex'],
		'0838' => ['sync_request_ex'],
		'0819' => ['sync_request_ex'],
		'0876' => ['sync_request_ex'],
		'0940' => ['sync_request_ex'],
		'0924' => ['sync_request_ex'],
		'0835' => ['sync_request_ex'],
		'08A9' => ['sync_request_ex'],
		'022D' => ['sync_request_ex'],
		'085A' => ['sync_request_ex'],
		'0811' => ['sync_request_ex'],
		'0934' => ['sync_request_ex'],
		'0925' => ['sync_request_ex'],
		'0967' => ['sync_request_ex'],
		'0941' => ['sync_request_ex'],
		'0872' => ['sync_request_ex'],
		'087A' => ['sync_request_ex'],
		'0930' => ['sync_request_ex'],
		'0945' => ['sync_request_ex'],
		'095A' => ['sync_request_ex'],
		'0948' => ['sync_request_ex'],
		'093D' => ['sync_request_ex'],
		'0954' => ['sync_request_ex'],
		'0969' => ['sync_request_ex'],
		'094A' => ['sync_request_ex'],
		'089D' => ['sync_request_ex'],
		'0923' => ['sync_request_ex'],
		'0953' => ['sync_request_ex'],
		'091C' => ['sync_request_ex'],
		'0917' => ['sync_request_ex'],
		'0887' => ['sync_request_ex'],
		'08A3' => ['sync_request_ex'],
		'0874' => ['sync_request_ex'],
		'092E' => ['sync_request_ex'],
		'0438' => ['sync_request_ex'],
		'086E' => ['sync_request_ex'],
		'0364' => ['sync_request_ex'],
		'088E' => ['sync_request_ex'],
		'0864' => ['sync_request_ex'],
		'0935' => ['sync_request_ex'],
		'0367' => ['sync_request_ex'],
		'0965' => ['sync_request_ex'],
		'0436' => ['sync_request_ex'],
		'08A8' => ['sync_request_ex'],
		'0880' => ['sync_request_ex'],
		'0368' => ['sync_request_ex'],
		'093F' => ['sync_request_ex'],
		'0871' => ['sync_request_ex'],
		'0817' => ['sync_request_ex'],
		'0886' => ['sync_request_ex'],
		'07E4' => ['sync_request_ex'],
		'0959' => ['sync_request_ex'],
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
