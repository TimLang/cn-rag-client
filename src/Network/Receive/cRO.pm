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
		
		'092F' => ['sync_request_ex'],
		'0934' => ['sync_request_ex'],
		'0363' => ['sync_request_ex'],
		'0880' => ['sync_request_ex'],
		'091C' => ['sync_request_ex'],
		'0281' => ['sync_request_ex'],
		'095E' => ['sync_request_ex'],
		'0965' => ['sync_request_ex'],
		'0811' => ['sync_request_ex'],
		'091B' => ['sync_request_ex'],
		'0887' => ['sync_request_ex'],
		'0862' => ['sync_request_ex'],
		'08A0' => ['sync_request_ex'],
		'0949' => ['sync_request_ex'],
		'08A6' => ['sync_request_ex'],
		'093B' => ['sync_request_ex'],
		'08AB' => ['sync_request_ex'],
		'0868' => ['sync_request_ex'],
		'085F' => ['sync_request_ex'],
		'08A2' => ['sync_request_ex'],
		'0968' => ['sync_request_ex'],
		'0944' => ['sync_request_ex'],
		'0873' => ['sync_request_ex'],
		'0872' => ['sync_request_ex'],
		'0918' => ['sync_request_ex'],
		'0951' => ['sync_request_ex'],
		'088A' => ['sync_request_ex'],
		'087A' => ['sync_request_ex'],
		'089B' => ['sync_request_ex'],
		'094B' => ['sync_request_ex'],
		'089C' => ['sync_request_ex'],
		'095C' => ['sync_request_ex'],
		'0930' => ['sync_request_ex'],
		'08A7' => ['sync_request_ex'],
		'0881' => ['sync_request_ex'],
		'0877' => ['sync_request_ex'],
		'0937' => ['sync_request_ex'],
		'0929' => ['sync_request_ex'],
		'0926' => ['sync_request_ex'],
		'0943' => ['sync_request_ex'],
		'0963' => ['sync_request_ex'],
		'0878' => ['sync_request_ex'],
		'0874' => ['sync_request_ex'],
		'0369' => ['sync_request_ex'],
		'091F' => ['sync_request_ex'],
		'0882' => ['sync_request_ex'],
		'0923' => ['sync_request_ex'],
		'0864' => ['sync_request_ex'],
		'0863' => ['sync_request_ex'],
		'087C' => ['sync_request_ex'],
		'0364' => ['sync_request_ex'],
		'0960' => ['sync_request_ex'],
		'0920' => ['sync_request_ex'],
		'085C' => ['sync_request_ex'],
		'0894' => ['sync_request_ex'],
		'092D' => ['sync_request_ex'],
		'088B' => ['sync_request_ex'],
		'0838' => ['sync_request_ex'],
		'085D' => ['sync_request_ex'],
		'0815' => ['sync_request_ex'],
		'096A' => ['sync_request_ex'],
		'089A' => ['sync_request_ex'],
		'0953' => ['sync_request_ex'],
		'086B' => ['sync_request_ex'],
		'0954' => ['sync_request_ex'],
		'087D' => ['sync_request_ex'],
		'0921' => ['sync_request_ex'],
		'0938' => ['sync_request_ex'],
		'07EC' => ['sync_request_ex'],
		'0917' => ['sync_request_ex'],
		'0958' => ['sync_request_ex'],
		'0932' => ['sync_request_ex'],
		'0947' => ['sync_request_ex'],
		'0875' => ['sync_request_ex'],
		'0969' => ['sync_request_ex'],
		'086F' => ['sync_request_ex'],
		'0879' => ['sync_request_ex'],
		'086D' => ['sync_request_ex'],
		'08A3' => ['sync_request_ex'],
		'0865' => ['sync_request_ex'],
		'092E' => ['sync_request_ex'],
		'089F' => ['sync_request_ex'],
		'0361' => ['sync_request_ex'],
		'0948' => ['sync_request_ex'],
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
