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
		
		'0802' => ['sync_request_ex'],
		'0963' => ['sync_request_ex'],
		'0877' => ['sync_request_ex'],
		'092D' => ['sync_request_ex'],
		'086D' => ['sync_request_ex'],
		'0922' => ['sync_request_ex'],
		'094E' => ['sync_request_ex'],
		'0861' => ['sync_request_ex'],
		'091E' => ['sync_request_ex'],
		'087F' => ['sync_request_ex'],
		'086E' => ['sync_request_ex'],
		'0886' => ['sync_request_ex'],
		'0882' => ['sync_request_ex'],
		'0871' => ['sync_request_ex'],
		'0364' => ['sync_request_ex'],
		'0281' => ['sync_request_ex'],
		'08A1' => ['sync_request_ex'],
		'0934' => ['sync_request_ex'],
		'0363' => ['sync_request_ex'],
		'0953' => ['sync_request_ex'],
		'08A3' => ['sync_request_ex'],
		'094C' => ['sync_request_ex'],
		'091D' => ['sync_request_ex'],
		'0930' => ['sync_request_ex'],
		'0872' => ['sync_request_ex'],
		'0365' => ['sync_request_ex'],
		'0967' => ['sync_request_ex'],
		'08A5' => ['sync_request_ex'],
		'0968' => ['sync_request_ex'],
		'0815' => ['sync_request_ex'],
		'088E' => ['sync_request_ex'],
		'0917' => ['sync_request_ex'],
		'0811' => ['sync_request_ex'],
		'0864' => ['sync_request_ex'],
		'094F' => ['sync_request_ex'],
		'088C' => ['sync_request_ex'],
		'093D' => ['sync_request_ex'],
		'0946' => ['sync_request_ex'],
		'0881' => ['sync_request_ex'],
		'0869' => ['sync_request_ex'],
		'0866' => ['sync_request_ex'],
		'089D' => ['sync_request_ex'],
		'0948' => ['sync_request_ex'],
		'0885' => ['sync_request_ex'],
		'0952' => ['sync_request_ex'],
		'094B' => ['sync_request_ex'],
		'0935' => ['sync_request_ex'],
		'0893' => ['sync_request_ex'],
		'085F' => ['sync_request_ex'],
		'08A4' => ['sync_request_ex'],
		'093C' => ['sync_request_ex'],
		'0928' => ['sync_request_ex'],
		'095E' => ['sync_request_ex'],
		'0955' => ['sync_request_ex'],
		'089F' => ['sync_request_ex'],
		'0438' => ['sync_request_ex'],
		'0944' => ['sync_request_ex'],
		'08AD' => ['sync_request_ex'],
		'0876' => ['sync_request_ex'],
		'096A' => ['sync_request_ex'],
		'0202' => ['sync_request_ex'],
		'08A2' => ['sync_request_ex'],
		'07E4' => ['sync_request_ex'],
		'088B' => ['sync_request_ex'],
		'0943' => ['sync_request_ex'],
		'023B' => ['sync_request_ex'],
		'0817' => ['sync_request_ex'],
		'087A' => ['sync_request_ex'],
		'0961' => ['sync_request_ex'],
		'0868' => ['sync_request_ex'],
		'089A' => ['sync_request_ex'],
		'0368' => ['sync_request_ex'],
		'0921' => ['sync_request_ex'],
		'0924' => ['sync_request_ex'],
		'089C' => ['sync_request_ex'],
		'093F' => ['sync_request_ex'],
		'0931' => ['sync_request_ex'],
		'0879' => ['sync_request_ex'],
		'0897' => ['sync_request_ex'],
		'0959' => ['sync_request_ex'],
		'088F' => ['sync_request_ex'],
		'0819' => ['sync_request_ex'],
		'0888' => ['sync_request_ex'],
		'0939' => ['sync_request_ex'],
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
