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
		
		'093D' => ['sync_request_ex'],
		'08A3' => ['sync_request_ex'],
		'0964' => ['sync_request_ex'],
		'093E' => ['sync_request_ex'],
		'0929' => ['sync_request_ex'],
		'08A7' => ['sync_request_ex'],
		'0965' => ['sync_request_ex'],
		'0883' => ['sync_request_ex'],
		'0942' => ['sync_request_ex'],
		'0437' => ['sync_request_ex'],
		'0886' => ['sync_request_ex'],
		'085E' => ['sync_request_ex'],
		'0866' => ['sync_request_ex'],
		'0881' => ['sync_request_ex'],
		'087E' => ['sync_request_ex'],
		'0917' => ['sync_request_ex'],
		'0281' => ['sync_request_ex'],
		'0955' => ['sync_request_ex'],
		'087D' => ['sync_request_ex'],
		'035F' => ['sync_request_ex'],
		'0876' => ['sync_request_ex'],
		'0918' => ['sync_request_ex'],
		'088E' => ['sync_request_ex'],
		'0365' => ['sync_request_ex'],
		'07EC' => ['sync_request_ex'],
		'0885' => ['sync_request_ex'],
		'088A' => ['sync_request_ex'],
		'08A6' => ['sync_request_ex'],
		'0948' => ['sync_request_ex'],
		'0956' => ['sync_request_ex'],
		'096A' => ['sync_request_ex'],
		'0962' => ['sync_request_ex'],
		'0893' => ['sync_request_ex'],
		'0943' => ['sync_request_ex'],
		'087B' => ['sync_request_ex'],
		'0888' => ['sync_request_ex'],
		'088C' => ['sync_request_ex'],
		'0864' => ['sync_request_ex'],
		'093C' => ['sync_request_ex'],
		'0835' => ['sync_request_ex'],
		'0958' => ['sync_request_ex'],
		'085D' => ['sync_request_ex'],
		'094C' => ['sync_request_ex'],
		'0897' => ['sync_request_ex'],
		'093A' => ['sync_request_ex'],
		'08AB' => ['sync_request_ex'],
		'0933' => ['sync_request_ex'],
		'08A9' => ['sync_request_ex'],
		'0887' => ['sync_request_ex'],
		'0802' => ['sync_request_ex'],
		'0949' => ['sync_request_ex'],
		'095D' => ['sync_request_ex'],
		'0940' => ['sync_request_ex'],
		'022D' => ['sync_request_ex'],
		'085B' => ['sync_request_ex'],
		'095B' => ['sync_request_ex'],
		'0875' => ['sync_request_ex'],
		'085A' => ['sync_request_ex'],
		'0865' => ['sync_request_ex'],
		'0922' => ['sync_request_ex'],
		'087A' => ['sync_request_ex'],
		'08A5' => ['sync_request_ex'],
		'0959' => ['sync_request_ex'],
		'0815' => ['sync_request_ex'],
		'093F' => ['sync_request_ex'],
		'093B' => ['sync_request_ex'],
		'0937' => ['sync_request_ex'],
		'0369' => ['sync_request_ex'],
		'0891' => ['sync_request_ex'],
		'0879' => ['sync_request_ex'],
		'0934' => ['sync_request_ex'],
		'0967' => ['sync_request_ex'],
		'0935' => ['sync_request_ex'],
		'091A' => ['sync_request_ex'],
		'092E' => ['sync_request_ex'],
		'0947' => ['sync_request_ex'],
		'0894' => ['sync_request_ex'],
		'094F' => ['sync_request_ex'],
		'089B' => ['sync_request_ex'],
		'08A2' => ['sync_request_ex'],
		'0899' => ['sync_request_ex'],
		'0892' => ['sync_request_ex'],
		'0926' => ['sync_request_ex'],
		'092B' => ['sync_request_ex'],
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
