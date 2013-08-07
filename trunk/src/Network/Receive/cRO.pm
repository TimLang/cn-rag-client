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
		
		'0935' => ['sync_request_ex'],
		'0931' => ['sync_request_ex'],
		'0889' => ['sync_request_ex'],
		'087D' => ['sync_request_ex'],
		'094C' => ['sync_request_ex'],
		'08A3' => ['sync_request_ex'],
		'095C' => ['sync_request_ex'],
		'0892' => ['sync_request_ex'],
		'0943' => ['sync_request_ex'],
		'088F' => ['sync_request_ex'],
		'0369' => ['sync_request_ex'],
		'0888' => ['sync_request_ex'],
		'087E' => ['sync_request_ex'],
		'0954' => ['sync_request_ex'],
		'0871' => ['sync_request_ex'],
		'0436' => ['sync_request_ex'],
		'094F' => ['sync_request_ex'],
		'0362' => ['sync_request_ex'],
		'022D' => ['sync_request_ex'],
		'0860' => ['sync_request_ex'],
		'0925' => ['sync_request_ex'],
		'0872' => ['sync_request_ex'],
		'089E' => ['sync_request_ex'],
		'095D' => ['sync_request_ex'],
		'0963' => ['sync_request_ex'],
		'086E' => ['sync_request_ex'],
		'087B' => ['sync_request_ex'],
		'0926' => ['sync_request_ex'],
		'0877' => ['sync_request_ex'],
		'0969' => ['sync_request_ex'],
		'0875' => ['sync_request_ex'],
		'092E' => ['sync_request_ex'],
		'02C4' => ['sync_request_ex'],
		'093B' => ['sync_request_ex'],
		'083C' => ['sync_request_ex'],
		'085A' => ['sync_request_ex'],
		'092F' => ['sync_request_ex'],
		'095B' => ['sync_request_ex'],
		'096A' => ['sync_request_ex'],
		'0933' => ['sync_request_ex'],
		'0368' => ['sync_request_ex'],
		'087F' => ['sync_request_ex'],
		'091B' => ['sync_request_ex'],
		'0937' => ['sync_request_ex'],
		'08A4' => ['sync_request_ex'],
		'0835' => ['sync_request_ex'],
		'0815' => ['sync_request_ex'],
		'0891' => ['sync_request_ex'],
		'0948' => ['sync_request_ex'],
		'095A' => ['sync_request_ex'],
		'0817' => ['sync_request_ex'],
		'0367' => ['sync_request_ex'],
		'0924' => ['sync_request_ex'],
		'091F' => ['sync_request_ex'],
		'085B' => ['sync_request_ex'],
		'085D' => ['sync_request_ex'],
		'0942' => ['sync_request_ex'],
		'0360' => ['sync_request_ex'],
		'088D' => ['sync_request_ex'],
		'0887' => ['sync_request_ex'],
		'0811' => ['sync_request_ex'],
		'0952' => ['sync_request_ex'],
		'093F' => ['sync_request_ex'],
		'08A5' => ['sync_request_ex'],
		'0882' => ['sync_request_ex'],
		'0867' => ['sync_request_ex'],
		'085E' => ['sync_request_ex'],
		'0862' => ['sync_request_ex'],
		'0962' => ['sync_request_ex'],
		'0890' => ['sync_request_ex'],
		'095F' => ['sync_request_ex'],
		'089C' => ['sync_request_ex'],
		'086A' => ['sync_request_ex'],
		'0968' => ['sync_request_ex'],
		'089F' => ['sync_request_ex'],
		'0819' => ['sync_request_ex'],
		'023B' => ['sync_request_ex'],
		'0964' => ['sync_request_ex'],
		'091D' => ['sync_request_ex'],
		'0957' => ['sync_request_ex'],
		'0896' => ['sync_request_ex'],
		'0920' => ['sync_request_ex'],
		'08A8' => ['sync_request_ex'],
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
