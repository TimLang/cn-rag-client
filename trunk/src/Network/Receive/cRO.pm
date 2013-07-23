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
		
		'0950' => ['sync_request_ex'],
		'08A1' => ['sync_request_ex'],
		'0815' => ['sync_request_ex'],
		'0884' => ['sync_request_ex'],
		'08A7' => ['sync_request_ex'],
		'091C' => ['sync_request_ex'],
		'08A9' => ['sync_request_ex'],
		'0870' => ['sync_request_ex'],
		'093F' => ['sync_request_ex'],
		'0363' => ['sync_request_ex'],
		'0941' => ['sync_request_ex'],
		'0893' => ['sync_request_ex'],
		'08A0' => ['sync_request_ex'],
		'087D' => ['sync_request_ex'],
		'0866' => ['sync_request_ex'],
		'08A8' => ['sync_request_ex'],
		'089F' => ['sync_request_ex'],
		'0881' => ['sync_request_ex'],
		'093B' => ['sync_request_ex'],
		'0921' => ['sync_request_ex'],
		'096A' => ['sync_request_ex'],
		'0958' => ['sync_request_ex'],
		'0894' => ['sync_request_ex'],
		'08A4' => ['sync_request_ex'],
		'087B' => ['sync_request_ex'],
		'0885' => ['sync_request_ex'],
		'0943' => ['sync_request_ex'],
		'0438' => ['sync_request_ex'],
		'0869' => ['sync_request_ex'],
		'0937' => ['sync_request_ex'],
		'0365' => ['sync_request_ex'],
		'0931' => ['sync_request_ex'],
		'0947' => ['sync_request_ex'],
		'0948' => ['sync_request_ex'],
		'0877' => ['sync_request_ex'],
		'0949' => ['sync_request_ex'],
		'0926' => ['sync_request_ex'],
		'0367' => ['sync_request_ex'],
		'092D' => ['sync_request_ex'],
		'0944' => ['sync_request_ex'],
		'094F' => ['sync_request_ex'],
		'0927' => ['sync_request_ex'],
		'0930' => ['sync_request_ex'],
		'0872' => ['sync_request_ex'],
		'087A' => ['sync_request_ex'],
		'0929' => ['sync_request_ex'],
		'0925' => ['sync_request_ex'],
		'0922' => ['sync_request_ex'],
		'092E' => ['sync_request_ex'],
		'0368' => ['sync_request_ex'],
		'0891' => ['sync_request_ex'],
		'093A' => ['sync_request_ex'],
		'0951' => ['sync_request_ex'],
		'0961' => ['sync_request_ex'],
		'08AD' => ['sync_request_ex'],
		'093D' => ['sync_request_ex'],
		'0936' => ['sync_request_ex'],
		'0898' => ['sync_request_ex'],
		'0817' => ['sync_request_ex'],
		'0362' => ['sync_request_ex'],
		'095C' => ['sync_request_ex'],
		'089D' => ['sync_request_ex'],
		'0880' => ['sync_request_ex'],
		'0920' => ['sync_request_ex'],
		'0366' => ['sync_request_ex'],
		'0923' => ['sync_request_ex'],
		'087C' => ['sync_request_ex'],
		'087F' => ['sync_request_ex'],
		'0361' => ['sync_request_ex'],
		'0940' => ['sync_request_ex'],
		'0436' => ['sync_request_ex'],
		'0954' => ['sync_request_ex'],
		'0873' => ['sync_request_ex'],
		'022D' => ['sync_request_ex'],
		'085F' => ['sync_request_ex'],
		'092B' => ['sync_request_ex'],
		'086A' => ['sync_request_ex'],
		'035F' => ['sync_request_ex'],
		'0966' => ['sync_request_ex'],
		'0964' => ['sync_request_ex'],
		'083C' => ['sync_request_ex'],
		'0871' => ['sync_request_ex'],
		'0957' => ['sync_request_ex'],
		'085C' => ['sync_request_ex'],
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
