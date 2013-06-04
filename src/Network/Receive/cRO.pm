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
		
		'087B' => ['sync_request_ex'],
		'0955' => ['sync_request_ex'],
		'0364' => ['sync_request_ex'],
		'0964' => ['sync_request_ex'],
		'08AB' => ['sync_request_ex'],
		'088E' => ['sync_request_ex'],
		'0948' => ['sync_request_ex'],
		'093D' => ['sync_request_ex'],
		'0838' => ['sync_request_ex'],
		'0942' => ['sync_request_ex'],
		'087F' => ['sync_request_ex'],
		'0965' => ['sync_request_ex'],
		'08AD' => ['sync_request_ex'],
		'092D' => ['sync_request_ex'],
		'0925' => ['sync_request_ex'],
		'0885' => ['sync_request_ex'],
		'0862' => ['sync_request_ex'],
		'0880' => ['sync_request_ex'],
		'08AC' => ['sync_request_ex'],
		'0867' => ['sync_request_ex'],
		'0811' => ['sync_request_ex'],
		'0937' => ['sync_request_ex'],
		'086E' => ['sync_request_ex'],
		'0361' => ['sync_request_ex'],
		'08A2' => ['sync_request_ex'],
		'0819' => ['sync_request_ex'],
		'086A' => ['sync_request_ex'],
		'08A9' => ['sync_request_ex'],
		'0944' => ['sync_request_ex'],
		'0939' => ['sync_request_ex'],
		'08A1' => ['sync_request_ex'],
		'0923' => ['sync_request_ex'],
		'07E4' => ['sync_request_ex'],
		'0926' => ['sync_request_ex'],
		'0873' => ['sync_request_ex'],
		'086C' => ['sync_request_ex'],
		'0919' => ['sync_request_ex'],
		'0360' => ['sync_request_ex'],
		'0961' => ['sync_request_ex'],
		'0881' => ['sync_request_ex'],
		'093A' => ['sync_request_ex'],
		'093B' => ['sync_request_ex'],
		'088A' => ['sync_request_ex'],
		'0802' => ['sync_request_ex'],
		'091F' => ['sync_request_ex'],
		'0967' => ['sync_request_ex'],
		'086F' => ['sync_request_ex'],
		'08A4' => ['sync_request_ex'],
		'0202' => ['sync_request_ex'],
		'08A6' => ['sync_request_ex'],
		'0934' => ['sync_request_ex'],
		'0933' => ['sync_request_ex'],
		'0884' => ['sync_request_ex'],
		'0894' => ['sync_request_ex'],
		'0866' => ['sync_request_ex'],
		'0887' => ['sync_request_ex'],
		'0962' => ['sync_request_ex'],
		'087E' => ['sync_request_ex'],
		'0941' => ['sync_request_ex'],
		'0947' => ['sync_request_ex'],
		'0892' => ['sync_request_ex'],
		'0891' => ['sync_request_ex'],
		'0893' => ['sync_request_ex'],
		'0938' => ['sync_request_ex'],
		'0932' => ['sync_request_ex'],
		'0860' => ['sync_request_ex'],
		'08A5' => ['sync_request_ex'],
		'0929' => ['sync_request_ex'],
		'0927' => ['sync_request_ex'],
		'0922' => ['sync_request_ex'],
		'0889' => ['sync_request_ex'],
		'0281' => ['sync_request_ex'],
		'091B' => ['sync_request_ex'],
		'0865' => ['sync_request_ex'],
		'0872' => ['sync_request_ex'],
		'0950' => ['sync_request_ex'],
		'092B' => ['sync_request_ex'],
		'0953' => ['sync_request_ex'],
		'095C' => ['sync_request_ex'],
		'0362' => ['sync_request_ex'],
		'0437' => ['sync_request_ex'],
		'089B' => ['sync_request_ex'],
		'0960' => ['sync_request_ex'],
		'091D' => ['sync_request_ex'],
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
