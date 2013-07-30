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
		
		'086A' => ['sync_request_ex'],
		'094D' => ['sync_request_ex'],
		'0933' => ['sync_request_ex'],
		'0966' => ['sync_request_ex'],
		'091A' => ['sync_request_ex'],
		'086C' => ['sync_request_ex'],
		'094E' => ['sync_request_ex'],
		'0867' => ['sync_request_ex'],
		'0870' => ['sync_request_ex'],
		'0945' => ['sync_request_ex'],
		'0893' => ['sync_request_ex'],
		'0918' => ['sync_request_ex'],
		'0815' => ['sync_request_ex'],
		'0872' => ['sync_request_ex'],
		'0923' => ['sync_request_ex'],
		'086B' => ['sync_request_ex'],
		'0835' => ['sync_request_ex'],
		'0941' => ['sync_request_ex'],
		'092E' => ['sync_request_ex'],
		'0960' => ['sync_request_ex'],
		'0364' => ['sync_request_ex'],
		'0951' => ['sync_request_ex'],
		'0877' => ['sync_request_ex'],
		'085B' => ['sync_request_ex'],
		'0360' => ['sync_request_ex'],
		'0958' => ['sync_request_ex'],
		'0938' => ['sync_request_ex'],
		'089E' => ['sync_request_ex'],
		'092F' => ['sync_request_ex'],
		'0802' => ['sync_request_ex'],
		'0964' => ['sync_request_ex'],
		'091B' => ['sync_request_ex'],
		'0936' => ['sync_request_ex'],
		'096A' => ['sync_request_ex'],
		'094A' => ['sync_request_ex'],
		'0935' => ['sync_request_ex'],
		'095B' => ['sync_request_ex'],
		'0930' => ['sync_request_ex'],
		'093A' => ['sync_request_ex'],
		'089F' => ['sync_request_ex'],
		'0934' => ['sync_request_ex'],
		'0959' => ['sync_request_ex'],
		'0885' => ['sync_request_ex'],
		'0865' => ['sync_request_ex'],
		'0896' => ['sync_request_ex'],
		'0968' => ['sync_request_ex'],
		'0880' => ['sync_request_ex'],
		'0917' => ['sync_request_ex'],
		'0884' => ['sync_request_ex'],
		'085E' => ['sync_request_ex'],
		'0366' => ['sync_request_ex'],
		'08A5' => ['sync_request_ex'],
		'093F' => ['sync_request_ex'],
		'087B' => ['sync_request_ex'],
		'086E' => ['sync_request_ex'],
		'0869' => ['sync_request_ex'],
		'0931' => ['sync_request_ex'],
		'093B' => ['sync_request_ex'],
		'0895' => ['sync_request_ex'],
		'0879' => ['sync_request_ex'],
		'095E' => ['sync_request_ex'],
		'0367' => ['sync_request_ex'],
		'08A2' => ['sync_request_ex'],
		'08AB' => ['sync_request_ex'],
		'087E' => ['sync_request_ex'],
		'0362' => ['sync_request_ex'],
		'094B' => ['sync_request_ex'],
		'0862' => ['sync_request_ex'],
		'095D' => ['sync_request_ex'],
		'087A' => ['sync_request_ex'],
		'095C' => ['sync_request_ex'],
		'0369' => ['sync_request_ex'],
		'0922' => ['sync_request_ex'],
		'0363' => ['sync_request_ex'],
		'0361' => ['sync_request_ex'],
		'0866' => ['sync_request_ex'],
		'0954' => ['sync_request_ex'],
		'0881' => ['sync_request_ex'],
		'093E' => ['sync_request_ex'],
		'0939' => ['sync_request_ex'],
		'0202' => ['sync_request_ex'],
		'0819' => ['sync_request_ex'],
		'0965' => ['sync_request_ex'],
		'08A0' => ['sync_request_ex'],
	);

	foreach my $switch (keys %packets) {
		$self->{packet_list}{$switch} = $packets{$switch};
	}

	return $self;
}

sub sync_request_ex {
	my ($self, $args) = @_;
	# Debug Recv
	#message "Recv Ex : 0x" . $args->{switch} . "\n";

	my $PacketID = $args->{switch};

	my $tempValues = RSK::GetReply(hex($PacketID));
	$tempValues = sprintf("0x%04x\n",$tempValues);
	$tempValues =~ s/^0+//;
	# Debug Send
	#message "Send Ex: 0x" . uc($tempValues) . "\n";
	$tempValues = hex($tempValues);
	sleep(0.2);
	# Dispatching Sync Ex Reply
	$messageSender->sendReplySyncRequestEx($tempValues);
}

1;
