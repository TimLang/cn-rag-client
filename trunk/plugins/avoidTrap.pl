package avoidTrap;

use strict;
use Plugins;

use Time::HiRes qw(time);

use Globals;
use Utils;
use Misc;
use AI;
use Network::Send;
use Commands;
use Skill;
use Log qw(debug message warning error);
use Translation;
use encoding 'utf8';

our $lasttime = time;
our $dirTurn = 1;

Plugins::register('avoidTrap', 'React to traps.', \&on_unload, \&on_reload);

my $hooks = Plugins::addHooks(['AI_pre', \&AI_hook]);

my $prefix = "avoidTrap_";
my $prefix2 = "_afterCast";

sub on_unload {
        Plugins::delHooks($hooks);
        undef $prefix;
        undef $prefix2;
}

sub on_reload {
        message "avoidTrap plugin reloading\n";
        Plugins::delHooks($hooks);
        undef $prefix;
        undef $prefix2;
}

sub AI_hook {
        return if (!$config{autoAvoidTrap});
        my $timeout = $config{avoidTrapTimeout} ? $config{avoidTrapTimeout} : 1;
        if (timeOut($lasttime, $timeout)) {
                checkGroundTrap();
                $lasttime = time;
        }
}

sub checkGroundTrap {
        for my $ID (@spellsID) {
                my $spell = $spells{$ID};
                my $binID = $spell->{binID};
                next unless $spell;
                if (!$spell->{mark}) {
                        $spell->{mark} = 1;
                        last if (avoidTrap('AI_hook', {
                                'binID' => $binID,
                                'skill' => getSpellName($spell->{type}),
                                'skillID' => $spell->{type},
                                'x' => $spell->{pos}{x},
                                'y' => $spell->{pos}{y}
                        }));
                }
        }
}

sub avoidTrap {
        my (undef, $args) = @_;
        my $hookName = shift;
        my $binID = $args->{binID};
        my $skill = $args->{skill};
        my $skillID = $args->{skillID};
        my $x = $args->{x};
        my $y = $args->{y};
        my $i = 0;
        my $pos = calcPosition($char);
        my $ret = 0;
        my $domain = ($config{"autoAvoidTrap_domain"}) ? $config{"autoAvoidTrap_domain"} : "info";

        debug "checking if we should avoid $skill at ($x, $y)\n";

        for (my $i = 0; exists $config{"avoidTrap_$i"}; $i++) {
                next if (!$config{"avoidTrap_$i"});

                if (existsInList($config{"avoidTrap_$i"}, $skill)) {

                        debug "checking avoid radius on $skill\n";

                        # check if we are inside the skill area of effect
                        my $inRange;
                        my $myRadius = ($config{"avoidTrap_$i"."_radius"}) ? $config{"avoidTrap_$i"."_radius"} : 5 ;
                        my ($left,$right,$top,$bottom);
                        if ($x != 0 || $y != 0) {
                                $left = $x - $myRadius;
                                $right = $x + $myRadius;
                                $top = $y + $myRadius;
                                $bottom = $y - $myRadius;
                                $inRange = 1 if ($left <= $pos->{x} && $right >= $pos->{x} && $bottom <= $pos->{y} && $top >= $pos->{y});
                        }

                        if ($inRange) {
                                if ($char->{sitting}) {
                                        main::stand();
                                }

                                #   Methods (choose one)
                                #   0 - Random position outside <avoidTrap_#_radius> by <avoidTrap_#_step>
                                #   1 - Move to opposite side by <avoidTrap_#_step>
                                #   2 - Move the right or left side.
                                #   3 - Teleport
                                #   5 - Use skill. (monsters only)
                                my $myStep = ($config{"avoidTrap_${i}_step"}) ? $config{"avoidTrap_${i}_step"} : 5 ;

                                $domain = $config{"avoidTrap_$i"."_domain"} if ($config{"avoidTrap_$i"."_domain"});
                                if ($config{"avoidTrap_$i"."_method"} == 0) {
                                        my $found = 1;
                                        my $count = 0;
                                        my %move;
                                        do {
                                                ($move{x}, $move{y}) = getRandPosition($myStep);
                                                $count++;
                                                if ($count > 100) {
                                                        $found = 0;
                                                        last;
                                                }
                                        } while ($left <= $move{x} && $right >= $move{x} && $top <= $move{y} && $bottom >= $move{y});

                                        if ($found) {
                                                $char->sendAttackStop();
                                                $char->sendMove($move{x}, $move{y});
                                                message "-- Avoid trap $skill, random move to $move{x}, $move{y}.\n", $domain, 1;
                                        }

                                } elsif ($config{"avoidTrap_$i"."_method"} == 1) {
                                        my $dx = $x - $char->{pos_to}{x};
                                        my $dy = $y - $char->{pos_to}{y};
                                        my %random;
                                        my %move;

                                        my $found = 1;
                                        my $count = 0;
                                        do {
                                                $random{x} = int(rand($myStep)) + 1;
                                                $random{y} = int(rand($myStep)) + 1;

                                                if ($dx > 0) {
                                                        $move{x} = $char->{pos_to}{x} - $random{x};
                                                } elsif ($dx < 0) {
                                                        $move{x} = $char->{pos_to}{x} + $random{x};
                                                } else {
                                                        $move{x} = $char->{pos_to}{x};
                                                }

                                                if ($dy > 0) {
                                                        $move{y} = $char->{pos_to}{y} - $random{y};
                                                } elsif ($dy < 0) {
                                                        $move{y} = $char->{pos_to}{y} + $random{y};
                                                } else {
                                                        $move{y} = $char->{pos_to}{y};
                                                }

                                                $count++;
                                                if ($count > 100) {
                                                        $found = 0;
                                                        last;
                                                }
                                        } while (!($field->isWalkable($x, $y)));

                                        if ($found) {
                                                $char->sendAttackStop();
                                                $char->sendMove($move{x}, $move{y});
                                                message "-- Avoid trap $skill, move to $move{x}, $move{y}.\n", $domain, 1;
                                                $ret = 1;
                                        }

                                } elsif ($config{"avoidTrap_$i"."_method"} == 2) {
                                        my $found = 1;
                                        my $count = 0;
                                        my %move;
                                        ($move{x}, $move{y}) = getSidePosition($myStep, $x, $y, $pos->{x}, $pos->{y});

                                        $char->sendAttackStop();
                                        $char->sendMove($move{x}, $move{y});
                                        message "- Avoid trap $skill [$binID] ($x, $y), random move from ($pos->{x}, $pos->{y}) to ($move{x}, $move{y}).\n", $domain, 1;
                                        $ret = 1;

                                } elsif ($config{"avoidTrap_$i"."_method"} == 3) {
                                        message "-- Avoid trap $skill, use random teleport.\n", $domain, 1;
                                        main::useTeleport(1);
                                        $ret = 1;

                                } elsif ($config{"avoidTrap_$i"."_method"} == 5 && timeOut($AI::Timeouts::avoidTrap_skill, 3)) {
                                        message "Avoid trap $skill, use ".$config{"avoidTrap_$i"."_skill"}." from ($x, $y)\n", $domain, 1;

                                        $skill = new Skill(name => $config{"avoidTrap_$i"."_skill"});

                                        if (main::ai_getSkillUseType($skill->getHandle)) {
                                                my $pos = $char->{pos_to};
                                                main::ai_skillUse(
                                                        $skill->getHandle,
                                                        $config{"avoidTrap_$i"."_lvl"},
                                                        $config{"avoidTrap_$i"."_maxCastTime"},
                                                        $config{"avoidTrap_$i"."_minCastTime"},
                                                        $pos->{x},
                                                        $pos->{y});
                                        } else {
                                                main::ai_skillUse(
                                                        $skill->getHandle,
                                                        $config{"avoidTrap_$i"."_lvl"},
                                                        $config{"avoidTrap_$i"."_maxCastTime"},
                                                        $config{"avoidTrap_$i"."_minCastTime"},
                                                        $accountID);
                                        }
                                        $AI::Timeouts::avoidTrap_skill = time;
                                        $ret = 1;
                                }
                        }
                        last;
                }
        }
        return $ret;
}

sub getRandPosition {
        my $range = shift;
        my $x_pos = shift;
        my $y_pos = shift;
        my $x_rand;
        my $y_rand;
        my $x;
        my $y;

        if ($x_pos eq "" || $y_pos eq "") {
                $x_pos = $char->{'pos_to'}{'x'};
                $y_pos = $char->{'pos_to'}{'y'};
        }

        do {
                $x_rand = int(rand($range)) + 1;
                $y_rand = int(rand($range)) + 1;

                if (int(rand(2))) {
                        $x = $x_pos + $x_rand;
                } else {
                        $x = $x_pos - $x_rand;
                }

                if (int(rand(2))) {
                        $y = $y_pos + $y_rand;
                } else {
                        $y = $y_pos - $y_rand;
                }
        } while (!($field->isWalkable($x, $y)));

        my @ret = ($x, $y);
        return @ret;
}

sub getSidePosition {
        my $range = shift;
        my $x2 = shift;
        my $y2 = shift;
        my $x1 = shift;
        my $y1 = shift;

        if ($x1 eq "" || $y1 eq "") {
                my $pos = calcPosition($char);
                $x1 = $pos->{x};
                $y1 = $pos->{y};
        }

        my $a = 0.0;
        my $dx = 0;
        my $dy = $range;
        if ($y1 != $y2) {
                $a = ($x2 - $x1) / ($y1 - $y2);
                $dx = $range / sqrt(1 + $a * $a);
                $dy = $a * $dx;
        }

        my $x;
        my $y;

        $x = $x1 + int($dirTurn * $dx);
        $y = $y1 + int($dirTurn * $dy);

        if (!($field->isWalkable($x, $y))) {
                $dirTurn = -1 * $dirTurn;
                $x = $x1 + int($dirTurn * $dx);
                $y = $y1 + int($dirTurn * $dy);
        }
        my @ret = ($x, $y);
        return @ret;
}

1;