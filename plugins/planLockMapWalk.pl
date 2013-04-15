# planLockMapWalk by Snoopy

package planLockMapWalk;

use strict;
use Plugins;

use Time::HiRes qw(time);

use Globals;
use Utils;
use Misc;
use AI;
use Log qw(debug message warning error);
use Translation;

my $errflag = 0;
my $nSpot = 0;
my $planMap = "";
my $cfID;
my $planwalk_file = "";
my @points = ();

Plugins::register('planLockMapWalk', 'Auto Plan to walk.', \&on_unload, \&on_reload);

my $hooks = Plugins::addHooks(
        ['configModify', \&on_configModify, undef],
        ['start3', \&on_start3, undef],
        ['postloadfiles', \&on_loadfiles, undef],
        ['pref_RandomWalk', \&pref_planWalk, undef],
        ['post_RandomWalk', \&post_planWalk, undef]
);

my $chooks = Commands::register(
        ['planwalk', "Plan Lock Map Walk plugin", \&planWalkCmdHandler]
);

sub on_unload {
        Plugins::delHooks($hooks);
        undef $nSpot;
        undef $planMap;
        undef $cfID;
        undef $planwalk_file;
        undef @points;
}

sub on_reload {
        message "planLockMapWalk plugin reloading\n";
        Plugins::delHooks($hooks);
        &on_start3;
}

sub on_configModify {
        my (undef, $args) = @_;
        if ($args->{key} eq 'planWalk_file') {
                $planwalk_file = $args->{val};
                Settings::removeFile($cfID);
                $cfID = Settings::addControlFile($planwalk_file, loader => [ \&parsePlanWalk, undef], mustExist => 0);                Settings::loadByHandle($cfID);
        } elsif ($args->{key} eq 'lockMap') {
                if ($planMap ne $args->{val}) {
                        $planMap = $args->{val};
                        $nSpot = 0;
                        Settings::loadByHandle($cfID);
                }
        }
}

sub on_start3 {
        &checkFile;
        Settings::removeFile($cfID) if ($cfID);
        $cfID = Settings::addControlFile($planwalk_file, loader => [ \&parsePlanWalk], mustExist => 0);
        Settings::loadByHandle($cfID);
}

sub on_loadfiles {
        if ($char && ($planMap ne $config{lockMap} || $planwalk_file ne $config{planWalk_file})) {
                $planMap = $config{lockMap};
                $planwalk_file = (defined $config{planWalk_file})? $config{planWalk_file} : "planwalk.txt";
                Settings::removeFile($cfID) if ($cfID);
                $cfID = Settings::addControlFile($planwalk_file, loader => [ \&parsePlanWalk], mustExist => 0);
                Settings::loadByHandle($cfID);
        }
}

# checks planwalk file
sub checkFile {
        $planMap = $config{lockMap};
        $planwalk_file = (defined $config{planWalk_file})? $config{planWalk_file} : "planwalk.txt";
}

# onFile(Re)load
sub parsePlanWalk {
        my $file = shift;

        my $flag1 = 0;
        @points = ();
        if (-e $file && $planMap) {
                open my $fp, "<:utf8", $file;
                while (<$fp>) {
                        $. == 1 && s/^\x{FEFF}//; # utf bom
                        s/(.*)[\s\t]+#.*$/$1/;        # remove last comments
                        s/^\s*#.*$//;                # remove comments
                        s/^\s*//;                # remove leading whitespaces
                        s/\s*[\r\n]?$//g;        # remove trailing whitespaces and eol
                        s/  +/ /g;                # trim down spaces - very cool for user's string data?
                        next unless ($_);
                        if (/^\[(.+)\]$/) {
                                $flag1 = ($1 eq $planMap) ? 1 : 0;
                        } elsif ($flag1) {
                                if (/^(\d+):(\d+)$/) {
                                        push @points, {'xPos' => $1, 'yPos' => $2};
                                }
                        }
                }
        }
        $nSpot = 0;
}

sub pref_planWalk {
        return if ($errflag || !$config{autoPlanLockMapWalk} || $config{lockMap} ne $field->baseName);

        my (undef, $args) = @_;
        my $ret = 1;
        my $maxRouteTime = $config{planWalk_maxRouteTime} ? $config{planWalk_maxRouteTime} :
                ($config{route_randomWalk_maxRouteTime} ? $config{route_randomWalk_maxRouteTime} : 120);

        my $psize = @points;
        $nSpot = $psize - 1 if ($nSpot >= $psize);
        if ($nSpot >= 0) {
                my ($to_x, $to_y);
                $to_x = $points[$nSpot]->{xPos};
                $to_y = $points[$nSpot]->{yPos};
                if ($to_x eq "" || $to_y eq "") {
                        error T("Empty coordinates setting for planLockMapWalk; planLockMapWalk disabled\n");
                        $errflag  = 1;
                } elsif ($field->isWalkable($to_x, $to_y)) {
                        AI::clear(qw/move route mapRoute/);
                        message TF("Do plan walking route to: %s: %s, %s\n", $field->descString(), $to_x, $to_y), "route";
                        main::ai_route($field->baseName, $to_x, $to_y, 
                                maxRouteTime => $maxRouteTime,
                                attackOnRoute => 2,
                                noMapRoute => ($config{route_randomWalk} == 2 ? 1 : 0));
                        $ret = 0;
                } else {
                        error TF("Invalid coordinates specified (%d, %d) for planLockMapWalk (coordinates are unwalkable); planLockMapWalk disabled\n", $to_x, $to_y);
                        $errflag  = 1;
                }
                $nSpot++;
                $nSpot = 0 if ($nSpot >= $psize);
        }
        $args->{return} = $ret;
}

sub post_planWalk {
}

sub planWalkCmdHandler {
        message TF("The Plan Lock Map is : %s (Step: %d)\n", ($planMap) ? $planMap : "???", $nSpot - 1);
        message TF("The configuration file is : %s \n", ($planwalk_file) ? $planwalk_file : "???");
my $psize = @points;
        for(my $i = 0 ; $i < $psize ; $i++) {
                message TF("Walk Point(%d/%d) : %s, %s\n", $i, $psize, $points[$i]->{xPos}, $points[$i]->{yPos});
        }
}

1;