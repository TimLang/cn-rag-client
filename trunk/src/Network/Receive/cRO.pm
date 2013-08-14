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
		
		'0955' => ['sync_request_ex'],
		'08A3' => ['sync_request_ex'],
		'0925' => ['sync_request_ex'],
		'0872' => ['sync_request_ex'],
		'0802' => ['sync_request_ex'],
		'0862' => ['sync_request_ex'],
		'0959' => ['sync_request_ex'],
		'0367' => ['sync_request_ex'],
		'0942' => ['sync_request_ex'],
		'0819' => ['sync_request_ex'],
		'092B' => ['sync_request_ex'],
		'0919' => ['sync_request_ex'],
		'094B' => ['sync_request_ex'],
		'0958' => ['sync_request_ex'],
		'0965' => ['sync_request_ex'],
		'0879' => ['sync_request_ex'],
		'087A' => ['sync_request_ex'],
		'0921' => ['sync_request_ex'],
		'035F' => ['sync_request_ex'],
		'0917' => ['sync_request_ex'],
		'092D' => ['sync_request_ex'],
		'0957' => ['sync_request_ex'],
		'088C' => ['sync_request_ex'],
		'086D' => ['sync_request_ex'],
		'085E' => ['sync_request_ex'],
		'095B' => ['sync_request_ex'],
		'0940' => ['sync_request_ex'],
		'086E' => ['sync_request_ex'],
		'0369' => ['sync_request_ex'],
		'091B' => ['sync_request_ex'],
		'088D' => ['sync_request_ex'],
		'088B' => ['sync_request_ex'],
		'0941' => ['sync_request_ex'],
		'0947' => ['sync_request_ex'],
		'096A' => ['sync_request_ex'],
		'0888' => ['sync_request_ex'],
		'0922' => ['sync_request_ex'],
		'0945' => ['sync_request_ex'],
		'0893' => ['sync_request_ex'],
		'0863' => ['sync_request_ex'],
		'093F' => ['sync_request_ex'],
		'088A' => ['sync_request_ex'],
		'08AC' => ['sync_request_ex'],
		'093A' => ['sync_request_ex'],
		'0928' => ['sync_request_ex'],
		'0878' => ['sync_request_ex'],
		'087F' => ['sync_request_ex'],
		'095D' => ['sync_request_ex'],
		'0896' => ['sync_request_ex'],
		'08A7' => ['sync_request_ex'],
		'0923' => ['sync_request_ex'],
		'0934' => ['sync_request_ex'],
		'0931' => ['sync_request_ex'],
		'0956' => ['sync_request_ex'],
		'087E' => ['sync_request_ex'],
		'0899' => ['sync_request_ex'],
		'093D' => ['sync_request_ex'],
		'08A8' => ['sync_request_ex'],
		'092F' => ['sync_request_ex'],
		'0877' => ['sync_request_ex'],
		'091C' => ['sync_request_ex'],
		'092C' => ['sync_request_ex'],
		'0954' => ['sync_request_ex'],
		'0368' => ['sync_request_ex'],
		'0966' => ['sync_request_ex'],
		'0948' => ['sync_request_ex'],
		'094F' => ['sync_request_ex'],
		'0937' => ['sync_request_ex'],
		'094E' => ['sync_request_ex'],
		'0887' => ['sync_request_ex'],
		'093B' => ['sync_request_ex'],
		'022D' => ['sync_request_ex'],
		'0946' => ['sync_request_ex'],
		'0880' => ['sync_request_ex'],
		'0953' => ['sync_request_ex'],
		'0817' => ['sync_request_ex'],
		'089D' => ['sync_request_ex'],
		'093C' => ['sync_request_ex'],
		'091A' => ['sync_request_ex'],
		'0938' => ['sync_request_ex'],
		'086C' => ['sync_request_ex'],
		'095F' => ['sync_request_ex'],
		'095E' => ['sync_request_ex'],
		'0873' => ['sync_request_ex'],
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
