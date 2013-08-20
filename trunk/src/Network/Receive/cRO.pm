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
		
		'0923' => ['sync_request_ex'],
		'089E' => ['sync_request_ex'],
		'08A4' => ['sync_request_ex'],
		'08A6' => ['sync_request_ex'],
		'087D' => ['sync_request_ex'],
		'092B' => ['sync_request_ex'],
		'091C' => ['sync_request_ex'],
		'0943' => ['sync_request_ex'],
		'023B' => ['sync_request_ex'],
		'0966' => ['sync_request_ex'],
		'0363' => ['sync_request_ex'],
		'091E' => ['sync_request_ex'],
		'0951' => ['sync_request_ex'],
		'0880' => ['sync_request_ex'],
		'0940' => ['sync_request_ex'],
		'0956' => ['sync_request_ex'],
		'0895' => ['sync_request_ex'],
		'087B' => ['sync_request_ex'],
		'0939' => ['sync_request_ex'],
		'0945' => ['sync_request_ex'],
		'07EC' => ['sync_request_ex'],
		'085D' => ['sync_request_ex'],
		'022D' => ['sync_request_ex'],
		'0958' => ['sync_request_ex'],
		'0955' => ['sync_request_ex'],
		'0878' => ['sync_request_ex'],
		'085B' => ['sync_request_ex'],
		'093E' => ['sync_request_ex'],
		'0862' => ['sync_request_ex'],
		'0871' => ['sync_request_ex'],
		'089D' => ['sync_request_ex'],
		'0917' => ['sync_request_ex'],
		'0893' => ['sync_request_ex'],
		'088A' => ['sync_request_ex'],
		'086D' => ['sync_request_ex'],
		'0942' => ['sync_request_ex'],
		'086C' => ['sync_request_ex'],
		'0929' => ['sync_request_ex'],
		'08A9' => ['sync_request_ex'],
		'0961' => ['sync_request_ex'],
		'083C' => ['sync_request_ex'],
		'088C' => ['sync_request_ex'],
		'0947' => ['sync_request_ex'],
		'0920' => ['sync_request_ex'],
		'087F' => ['sync_request_ex'],
		'0876' => ['sync_request_ex'],
		'0926' => ['sync_request_ex'],
		'0892' => ['sync_request_ex'],
		'0860' => ['sync_request_ex'],
		'0946' => ['sync_request_ex'],
		'094A' => ['sync_request_ex'],
		'0887' => ['sync_request_ex'],
		'0802' => ['sync_request_ex'],
		'0873' => ['sync_request_ex'],
		'0438' => ['sync_request_ex'],
		'094D' => ['sync_request_ex'],
		'094E' => ['sync_request_ex'],
		'093A' => ['sync_request_ex'],
		'0869' => ['sync_request_ex'],
		'0919' => ['sync_request_ex'],
		'0838' => ['sync_request_ex'],
		'0885' => ['sync_request_ex'],
		'093B' => ['sync_request_ex'],
		'0963' => ['sync_request_ex'],
		'085C' => ['sync_request_ex'],
		'0369' => ['sync_request_ex'],
		'0437' => ['sync_request_ex'],
		'0965' => ['sync_request_ex'],
		'0872' => ['sync_request_ex'],
		'08AA' => ['sync_request_ex'],
		'0863' => ['sync_request_ex'],
		'088E' => ['sync_request_ex'],
		'091A' => ['sync_request_ex'],
		'087C' => ['sync_request_ex'],
		'0927' => ['sync_request_ex'],
		'0865' => ['sync_request_ex'],
		'07E4' => ['sync_request_ex'],
		'0957' => ['sync_request_ex'],
		'0870' => ['sync_request_ex'],
		'0918' => ['sync_request_ex'],
		'092F' => ['sync_request_ex'],
		'0896' => ['sync_request_ex'],
		'095C' => ['sync_request_ex'],
		'0360' => ['sync_request_ex'],
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
