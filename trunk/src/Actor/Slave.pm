package Actor::Slave;

use strict;
use Actor;
use Globals;
use encoding 'utf8';
use base qw/Actor/;

sub new {
	my ($class, $type) = @_;
	
	my $actorType =
		(($type >= 6001 && $type <= 6016) || ($type >= 6048 && $type <= 6052)) ? '人工生命体' :
		($type >= 6017 && $type <= 6046) ? '佣兵' :
	'未知';
	
	return $class->SUPER::new ($actorType);
}

1;