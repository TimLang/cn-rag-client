# 自动传送之阵功能
# 插件修订: CoCo
# 发布 CN Kore Team
# Revision: r189
# Date: 2013年4月20日 02:27:09

package autowarpn;

use strict;
use Globals;
use Log qw(message error);
use Utils;
use Network::Send;
use Misc;
use AI;
use Translation;
use encoding 'utf8';

Plugins::register('autowarpn', 'Auto warp before walk to lockmap.', \&unload);

my $hooks = Plugins::addHooks(
	['AI_pre', \&AI_hook],
	['packet/warp_portal_list', \&warplist_hook],
	['packet/skill_use_location', \&warpopen_hook],
	['packet/skill_use_failed', \&warpfailed_hook],
	['Network::Receive::map_changed', \&mapchange_hook],
);

my $cHook = Log::addHook(\&cHook);
my $warpOpened;
my $warpNowOpen;
my $movewarp;
my $warpfailed;
my $warpoff = 0;

sub unload {
   Plugins::delHooks($hooks);
}

sub cHook {
   my $type = shift;
   my $domain = shift;
   my $level = shift;
   my $currentVerbosity = shift;
   my $message = shift;
   
   if ($message =~ /计算路径至坐标/ && $warpoff == 0 &&
     existsInList($config{autoWarp_from}, $field->baseName) &&
     $char->{skills}{AL_WARP} && $char->{skills}{AL_WARP}{lv} > 0 && !$char->statusActive('EFST_POSTDELAY') ) {
      AI::queue("autowarp");
      AI::args->{timeout} = 1;
      AI::args->{time} = time;
      AI::args->{map} = $field->baseName;
      message "准备使用传送之阵至地图 $config{autoWarp_to}\n";
	  $warpOpened = 1;
   }
}

sub AI_hook {
	my $hookName = shift;

	if ($warpOpened == 1) {
		AI::dequeue if (AI::action eq "route");
		if (AI::action eq "autowarp" && timeOut(AI::args)) {
			if ($field->baseName ne AI::args->{map} || $field->name ne AI::args->{map}) {
			AI::dequeue;
			return;
		} else {
			my $pos = getEmptyPos($char, 4);
			$messageSender->sendSkillUseLoc(27, 4, $pos->{x}, $pos->{y});
			$warpOpened = 0;
#			stopAttack();
			message "尝试在坐标 $pos->{x}, $pos->{y} 施放传送之阵\n";
			AI::args->{timeout} = 15;
			AI::args->{time} = time;
			}
		}
	}
	
	if (AI::action eq "autowarp" && $warpOpened == 0 && $warpfailed == 1) {
		$warpfailed = 0;
		$warpoff = 1;
		AI::dequeue;
		return;
	}
}

sub warplist_hook {
	if (AI::action eq "autowarp") {
		for (my $i = 0; $i < @{$char->{warp}{memo}}; $i++) {
			last if ($char->{warp}{memo}[$i] eq $config{autoWarp_to});
			if (($i == @{$char->{warp}{memo}} - 1) && ($char->{warp}{memo}[$i] ne $config{autoWarp_to})) {
				error TF("您当前角色并未记录地图 '%s' 的传送点! 自动传送之阵功能关闭, 再次使用自动传送之门需重启程序!\n", $config{autoWarp_to});
				$warpfailed = 1;
			} 
		}
		$messageSender->sendWarpTele(27, $config{autoWarp_to}.".gat");
		$warpNowOpen = 1;
	}
}

sub warpopen_hook {
	my ($hookname, $args) = @_;

	if (AI::action eq "autowarp" && $warpfailed != 1) {
		if ($args->{sourceID} eq $accountID && $args->{skillID} == 27 && $warpNowOpen == 1) {
		$warpNowOpen = 0;
		$movewarp = 1;
		message "正在移动至坐标 $args->{x}, $args->{y} 进入传送之阵\n";
		main::ai_route($field->baseName, $args->{x}, $args->{y},
		noSitAuto => 1,
		attackOnRoute => 0);
		}
	}
}

sub mapchange_hook {
	my $ai_string;
	if (@ai_seq) {
		$ai_string =  join(' ', @ai_seq);
	}
	if ($ai_string =~ /autowarp/) {
			AI::clear;
			return;
	}
}

sub warpfailed_hook {
	my ($hookname, $args) = @_;

	if ($movewarp == 1) {
		if ($args->{skillID} == 27 && $args->{type} == 8) {
		error "您没有设置自动购买蓝色魔力矿石并且身上已没有蓝色魔力矿石了! 自动传送之阵功能关闭, 再次使用自动传送之门需重启程序!\n";
		$movewarp = 0;
		$warpfailed = 1;
		}
	}
}

sub getEmptyPos {
   my $obj = shift;
   my $maxDist = shift;

   my %pos;
   for (my $i = 0; $i < @playersID; $i++) {
      next if (!$playersID[$i]);
      my $player = $players{$playersID[$i]};
      $pos{$player->{pos_to}{x}}{$player->{pos_to}{y}} = 1;
   }

   my @vectors = (-1, 0, 1, 0);

   my $vecx = int abs rand 4;
   my $vecy = $vectors[$vecx] ? 2 * int(abs(rand(2))) + 1 : 2 * int(abs(rand(2)));

   my ($posx, $posy);

   for (my $i = 1; $i <= $maxDist; $i++) {
      for (my $j = 0; $j < 4; $j++) {
         $posx = $obj->{pos_to}{x} + ( $vectors[$vecx] * $i * -1) || ( ($i*2) /2 );
         $posy = $obj->{pos_to}{y} + ( $vectors[$vecy] * $i * -1) || ( ($i*2) /-2 );
         for (my $k = 0; $k < ($i*2); $k++) {
            if ($field->isWalkable($posx, $posy) && !$pos{$posx}{$posy}) {
               my $pos = {x=>$posx, y=>$posy};
               return $pos if checkLineWalkable($obj->{pos_to}, $pos);
            }
            $posx += $vectors[$vecx];
            $posy += $vectors[$vecy];
         }
         $vecx = ($vecx+1)%4;
         $vecy = ($vecy+1)%4;
      }
   }
   return undef;
}

1;