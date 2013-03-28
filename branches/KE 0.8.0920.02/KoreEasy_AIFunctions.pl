#######################################
#######################################
#AI FUNCTIONS
#######################################
#######################################


sub ai_clientSuspend {
        my ($type,$initTimeout,@args) = @_;
        my %args;
        $args{'type'} = $type;
        $args{'time'} = time;
        $args{'timeout'} = $initTimeout;
        @{$args{'args'}} = @args;
        unshift @ai_seq, "clientSuspend";
        unshift @ai_seq_args, \%args;
}

sub ai_follow {
        my $name = shift;
        my %args;
        $args{'name'} = $name;
        unshift @ai_seq, "follow";
        unshift @ai_seq_args, \%args;
}

sub ai_getAggressives {
        my @agMonsters;
        foreach (@monstersID) {
                next if ($_ eq "");
                if ($monsters{$_}{'dmgToYou'} > 0 || $monsters{$_}{'missedYou'} > 0) {
                        push @agMonsters, $_;
                }
        }
        return @agMonsters;
}

sub ai_getIDFromChat {
        my $r_hash = shift;
        my $msg_user = shift;
        my $match_text = shift;
        my $qm;
        if ($match_text !~ /\w+/ || $match_text eq "me") {
                foreach (keys %{$r_hash}) {
                        next if ($_ eq "");
                        if ($msg_user eq $$r_hash{$_}{'name'}) {
                                return $_;
                        }
                }
        } else {
                foreach (keys %{$r_hash}) {
                        next if ($_ eq "");
                        $qm = quotemeta $match_text;
                        if ($$r_hash{$_}{'name'} =~ /$qm/i) {
                                return $_;
                        }
                }
        }
}

sub ai_getMonstersWhoHitMe {
        my @agMonsters;
        foreach (@monstersID) {
                next if ($_ eq "");
                if ($monsters{$_}{'dmgToYou'} > 0 && $monsters{$_}{'attack_failed'} <= 1) {
                        push @agMonsters, $_;
                }
        }
        return @agMonsters;
}

sub ai_getSkillUseType {
        my $skill = shift;
        if ($skill eq "WZ_FIREPILLAR" || $skill eq "WZ_METEOR"
                || $skill eq "WZ_VERMILION" || $skill eq "WZ_STORMGUST"
                || $skill eq "WZ_HEAVENDRIVE" || $skill eq "WZ_QUAGMIRE"
                || $skill eq "MG_SAFETYWALL" || $skill eq "MG_FIREWALL"
                || $skill eq "MG_THUNDERSTORM" || $skill eq "AL_PNEUMA"
                || $skill eq "AL_WARP"
                || $skill eq "PR_SANCTUARY" || $skill eq "PR_BENEDICTIO"
                || $skill eq "PR_MAGNUS" || $skill eq "BS_HAMMERFALL"
                || $skill eq "HT_SKIDTRAP" || $skill eq "HT_LANDMINE"
                || $skill eq "HT_ANKLESNARE" || $skill eq "HT_SHOCKWAVE"
                || $skill eq "HT_SANDMAN" || $skill eq "HT_FLASHER"
                || $skill eq "HT_FREEZINGTRAP" || $skill eq "HT_BLASTMINE"
                || $skill eq "HT_CLAYMORETRAP" || $skill eq "AS_VENOMDUST"
                || $skill eq "SA_VOLCANO" || $skill eq "SA_DELUGE"
                || $skill eq "SA_VIOLENTGALE" || $skill eq "SA_LANDPROTECTOR") {
                return 1;
        } else {
                return 0;
        }

}

sub ai_mapRoute_getRoute {

        my %args;

        ##VARS

        $args{'g_normal'} = 1;

        ###

        my ($returnArray, $r_start_field, $r_start_pos, $r_dest_field, $r_dest_pos, $time_giveup) = @_;
        $args{'returnArray'} = $returnArray;
        $args{'r_start_field'} = $r_start_field;
        $args{'r_start_pos'} = $r_start_pos;
        $args{'r_dest_field'} = $r_dest_field;
        $args{'r_dest_pos'} = $r_dest_pos;
        $args{'time_giveup'}{'timeout'} = $time_giveup;
        $args{'time_giveup'}{'time'} = time;
        unshift @ai_seq, "route_getMapRoute";
        unshift @ai_seq_args, \%args;
}

sub ai_mapRoute_getSuccessors {
        my ($r_args, $r_array, $r_cur) = @_;
        my $ok;
        foreach (keys %portals_lut) {
                if ($portals_lut{$_}{'source'}{'map'} eq $$r_cur{'dest'}{'map'}

                        && !($$r_cur{'source'}{'map'} eq $portals_lut{$_}{'dest'}{'map'}
                        && $$r_cur{'source'}{'pos'}{'x'} == $portals_lut{$_}{'dest'}{'pos'}{'x'}
                        && $$r_cur{'source'}{'pos'}{'y'} == $portals_lut{$_}{'dest'}{'pos'}{'y'})

                        && !(%{$$r_cur{'parent'}} && $$r_cur{'parent'}{'source'}{'map'} eq $portals_lut{$_}{'dest'}{'map'}
                        && $$r_cur{'parent'}{'source'}{'pos'}{'x'} == $portals_lut{$_}{'dest'}{'pos'}{'x'}
                        && $$r_cur{'parent'}{'source'}{'pos'}{'y'} == $portals_lut{$_}{'dest'}{'pos'}{'y'})) {
                        undef $ok;
                        if (!%{$$r_cur{'parent'}}) {
                                if (!$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solutionTried'}) {
                                        $$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solutionTried'} = 1;
                                        $timeout{'ai_route_calcRoute'}{'time'} -= $timeout{'ai_route_calcRoute'}{'timeout'};
                                        $$r_args{'waitingForSolution'} = 1;
                                        ai_route_getRoute(\@{$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solution'}},
                                                        $$r_args{'start'}{'dest'}{'field'}, \%{$$r_args{'start'}{'dest'}{'pos'}}, \%{$portals_lut{$_}{'source'}{'pos'}});
                                        last;
                                }
                                $ok = 1 if (@{$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solution'}});
                        } elsif ($portals_los{$$r_cur{'dest'}{'ID'}}{$portals_lut{$_}{'source'}{'ID'}} ne "0"
                                && $portals_los{$portals_lut{$_}{'source'}{'ID'}}{$$r_cur{'dest'}{'ID'}} ne "0") {
                                $ok = 1;
                        }
                        if ($$r_args{'dest'}{'source'}{'pos'}{'x'} ne "" && $portals_lut{$_}{'dest'}{'map'} eq $$r_args{'dest'}{'source'}{'map'}) {
                                if (!$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$portals_lut{$_}{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solutionTried'}) {
                                        $$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$portals_lut{$_}{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solutionTried'} = 1;
                                        $timeout{'ai_route_calcRoute'}{'time'} -= $timeout{'ai_route_calcRoute'}{'timeout'};
                                        $$r_args{'waitingForSolution'} = 1;
                                        ai_route_getRoute(\@{$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$portals_lut{$_}{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solution'}},
                                                        $$r_args{'dest'}{'source'}{'field'}, \%{$portals_lut{$_}{'dest'}{'pos'}}, \%{$$r_args{'dest'}{'source'}{'pos'}});
                                        last;
                                }
                        }
                        push @{$r_array}, \%{$portals_lut{$_}} if $ok;
                }
        }
}

sub ai_mapRoute_searchStep {
        my $r_args = shift;
        my @successors;
        my $r_cur, $r_suc;
        my $i;

        ###check if failed
        if (!@{$$r_args{'openList'}}) {
                #failed!
                $$r_args{'done'} = 1;
                return;
        }

        $r_cur = shift @{$$r_args{'openList'}};

        ###check if finished
        if ($$r_args{'dest'}{'source'}{'map'} eq $$r_cur{'dest'}{'map'}
                && (@{$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$$r_cur{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solution'}}
                || $$r_args{'dest'}{'source'}{'pos'}{'x'} eq "")) {
                do {
                        unshift @{$$r_args{'solutionList'}}, {%{$r_cur}};
                        $r_cur = $$r_cur{'parent'} if (%{$$r_cur{'parent'}});
                } while ($r_cur != \%{$$r_args{'start'}});
                $$r_args{'done'} = 1;
                return;
        }

        ai_mapRoute_getSuccessors($r_args, \@successors, $r_cur);
        if ($$r_args{'waitingForSolution'}) {
                undef $$r_args{'waitingForSolution'};
                unshift @{$$r_args{'openList'}}, $r_cur;
                return;
        }

        $newg = $$r_cur{'g'} + $$r_args{'g_normal'};
        foreach $r_suc (@successors) {
                undef $found;
                undef $openFound;
                undef $closedFound;
                for($i = 0; $i < @{$$r_args{'openList'}}; $i++) {
                        if ($$r_suc{'dest'}{'map'} eq $$r_args{'openList'}[$i]{'dest'}{'map'}
                                && $$r_suc{'dest'}{'pos'}{'x'} == $$r_args{'openList'}[$i]{'dest'}{'pos'}{'x'}
                                && $$r_suc{'dest'}{'pos'}{'y'} == $$r_args{'openList'}[$i]{'dest'}{'pos'}{'y'}) {
                                if ($newg >= $$r_args{'openList'}[$i]{'g'}) {
                                        $found = 1;
                                        }
                                $openFound = $i;
                                last;
                        }
                }
                next if ($found);

                undef $found;
                for($i = 0; $i < @{$$r_args{'closedList'}}; $i++) {
                        if ($$r_suc{'dest'}{'map'} eq $$r_args{'closedList'}[$i]{'dest'}{'map'}
                                && $$r_suc{'dest'}{'pos'}{'x'} == $$r_args{'closedList'}[$i]{'dest'}{'pos'}{'x'}
                                && $$r_suc{'dest'}{'pos'}{'y'} == $$r_args{'closedList'}[$i]{'dest'}{'pos'}{'y'}) {
                                if ($newg >= $$r_args{'closedList'}[$i]{'g'}) {
                                        $found = 1;
                                }
                                $closedFound = $i;
                                last;
                        }
                }
                next if ($found);
                if ($openFound ne "") {
                        binRemoveAndShiftByIndex(\@{$$r_args{'openList'}}, $openFound);
                }
                if ($closedFound ne "") {
                        binRemoveAndShiftByIndex(\@{$$r_args{'closedList'}}, $closedFound);
                }
                $$r_suc{'g'} = $newg;
                $$r_suc{'h'} = 0;
                $$r_suc{'f'} = $$r_suc{'g'} + $$r_suc{'h'};
                $$r_suc{'parent'} = $r_cur;
                minHeapAdd(\@{$$r_args{'openList'}}, $r_suc, "f");
        }
        push @{$$r_args{'closedList'}}, $r_cur;
}

sub ai_items_take {
        my ($x1, $y1, $x2, $y2) = @_;
        my %args;
        $args{'pos'}{'x'} = $x1;
        $args{'pos'}{'y'} = $y1;
        $args{'pos_to'}{'x'} = $x2;
        $args{'pos_to'}{'y'} = $y2;
        $args{'ai_items_take_end'}{'time'} = time;
        $args{'ai_items_take_end'}{'timeout'} = $timeout{'ai_items_take_end'}{'timeout'};
        $args{'ai_items_take_start'}{'time'} = time;
        $args{'ai_items_take_start'}{'timeout'} = $timeout{'ai_items_take_start'}{'timeout'};
        unshift @ai_seq, "items_take";
        unshift @ai_seq_args, \%args;
}

sub ai_route {
        my ($r_ret, $x, $y, $map, $maxRouteDistance, $maxRouteTime, $attackOnRoute, $avoidPortals, $distFromGoal, $checkInnerPortals) = @_;
        my %args;
        $x = int($x) if ($x ne "");
        $y = int($y) if ($y ne "");
        $args{'returnHash'} = $r_ret;
        $args{'dest_x'} = $x;
        $args{'dest_y'} = $y;
        $args{'dest_map'} = $map;
        $args{'maxRouteDistance'} = $maxRouteDistance;
        $args{'maxRouteTime'} = $maxRouteTime;
        $args{'attackOnRoute'} = $attackOnRoute;
        $args{'avoidPortals'} = $avoidPortals;
        $args{'distFromGoal'} = $distFromGoal;
        $args{'checkInnerPortals'} = $checkInnerPortals;
        undef %{$args{'returnHash'}};
        unshift @ai_seq, "route";
        unshift @ai_seq_args, \%args;
        print "On route to: $maps_lut{$map.'.rsw'}($map): $x, $y\n" if $config{'debug'};
}

sub ai_route_getDiagSuccessors {
        my $r_args = shift;
        my $r_pos = shift;
        my $r_array = shift;
        my $type = shift;
        my %pos;

        if (ai_route_getMap($r_args, $$r_pos{'x'}-1, $$r_pos{'y'}-1) == $type
                && !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}-1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}-1)) {
                $pos{'x'} = $$r_pos{'x'}-1;
                $pos{'y'} = $$r_pos{'y'}-1;
                push @{$r_array}, {%pos};
        }

        if (ai_route_getMap($r_args, $$r_pos{'x'}+1, $$r_pos{'y'}-1) == $type
                && !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}+1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}-1)) {
                $pos{'x'} = $$r_pos{'x'}+1;
                $pos{'y'} = $$r_pos{'y'}-1;
                push @{$r_array}, {%pos};
        }

        if (ai_route_getMap($r_args, $$r_pos{'x'}+1, $$r_pos{'y'}+1) == $type
                && !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}+1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}+1)) {
                $pos{'x'} = $$r_pos{'x'}+1;
                $pos{'y'} = $$r_pos{'y'}+1;
                push @{$r_array}, {%pos};
        }


        if (ai_route_getMap($r_args, $$r_pos{'x'}-1, $$r_pos{'y'}+1) == $type
                && !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}-1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}+1)) {
                $pos{'x'} = $$r_pos{'x'}-1;
                $pos{'y'} = $$r_pos{'y'}+1;
                push @{$r_array}, {%pos};
        }
}

sub ai_route_getMap {
        my $r_args = shift;
        my $x = shift;
        my $y = shift;
        if($x < 0 || $x >= $$r_args{'field'}{'width'} || $y < 0 || $y >= $$r_args{'field'}{'height'}) {
                return 1;
        }
        return unpack("C", substr($$r_args{'field'}{'rawMap'}, $y * $$r_args{'field'}{'width'} + $x, 1));
}

sub ai_route_getRoute {
        my %args;
        my ($returnArray, $r_field, $r_start, $r_dest, $time_giveup) = @_;
        $args{'returnArray'} = $returnArray;
        $args{'field'} = $r_field;
        %{$args{'start'}} = %{$r_start};
        %{$args{'dest'}} = %{$r_dest};
        $args{'time_giveup'}{'timeout'} = $time_giveup;
        $args{'time_giveup'}{'time'} = time;
        $args{'destroyFunction'} = \&ai_route_getRoute_destroy;
        undef @{$args{'returnArray'}};
        unshift @ai_seq, "route_getRoute";
        unshift @ai_seq_args, \%args;
}

sub ai_route_getRoute_destroy {
        my $r_args = shift;
        return  if ($$r_args{'session'} eq "");
        if (!$config{'buildType'}) {
                $CalcPath_destroy->Call($$r_args{'session'});
        } elsif ($config{'buildType'} == 1) {
                &{$CalcPath_destroy}($$r_args{'session'});
        }
}
sub ai_route_searchStep {
        my $r_args = shift;
        my $ret;

        if (!$$r_args{'initialized'}) {
                #####
                my $SOLUTION_MAX = 5000;
                $$r_args{'solution'} = "\0" x ($SOLUTION_MAX*4+4);
                #####
                if (!$config{'buildType'}) {
                        $$r_args{'session'} = $CalcPath_init->Call($$r_args{'solution'},
                                $$r_args{'field'}{'rawMap'}, $$r_args{'field'}{'width'}, $$r_args{'field'}{'height'},
                                pack("S*",$$r_args{'start'}{'x'}, $$r_args{'start'}{'y'}), pack("S*",$$r_args{'dest'}{'x'}, $$r_args{'dest'}{'y'}), $$r_args{'timeout'});
                } elsif ($config{'buildType'} == 1) {
                        $$r_args{'session'} = &{$CalcPath_init}($$r_args{'solution'},
                                $$r_args{'field'}{'rawMap'}, $$r_args{'field'}{'width'}, $$r_args{'field'}{'height'},
                                pack("S*",$$r_args{'start'}{'x'}, $$r_args{'start'}{'y'}), pack("S*",$$r_args{'dest'}{'x'}, $$r_args{'dest'}{'y'}), $$r_args{'timeout'});

                }
        }
        if ($$r_args{'session'} < 0) {
                $$r_args{'done'} = 1;
                return;
        }
        $$r_args{'initialized'} = 1;
        if (!$config{'buildType'}) {
                $ret = $CalcPath_pathStep->Call($$r_args{'session'});
        } elsif ($config{'buildType'} == 1) {
                $ret = &{$CalcPath_pathStep}($$r_args{'session'});
        }
        if (!$ret) {
                my $size = unpack("L",substr($$r_args{'solution'},0,4));
                my $j = 0;
                my $i;
                for ($i = ($size-1)*4+4; $i >= 4;$i-=4) {
                        $$r_args{'returnArray'}[$j]{'x'} = unpack("S",substr($$r_args{'solution'}, $i, 2));
                        $$r_args{'returnArray'}[$j]{'y'} = unpack("S",substr($$r_args{'solution'}, $i+2, 2));
                        $j++;
                }
                $$r_args{'done'} = 1;
        }
}

sub ai_route_getSuccessors {
        my $r_args = shift;
        my $r_pos = shift;
        my $r_array = shift;
        my $type = shift;
        my %pos;

        if (ai_route_getMap($r_args, $$r_pos{'x'}-1, $$r_pos{'y'}) == $type
                && !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}-1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'})) {
                $pos{'x'} = $$r_pos{'x'}-1;
                $pos{'y'} = $$r_pos{'y'};
                push @{$r_array}, {%pos};
        }

        if (ai_route_getMap($r_args, $$r_pos{'x'}, $$r_pos{'y'}-1) == $type
                && !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'} && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}-1)) {
                $pos{'x'} = $$r_pos{'x'};
                $pos{'y'} = $$r_pos{'y'}-1;
                push @{$r_array}, {%pos};
        }

        if (ai_route_getMap($r_args, $$r_pos{'x'}+1, $$r_pos{'y'}) == $type
                && !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}+1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'})) {
                $pos{'x'} = $$r_pos{'x'}+1;
                $pos{'y'} = $$r_pos{'y'};
                push @{$r_array}, {%pos};
        }


        if (ai_route_getMap($r_args, $$r_pos{'x'}, $$r_pos{'y'}+1) == $type
                && !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'} && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}+1)) {
                $pos{'x'} = $$r_pos{'x'};
                $pos{'y'} = $$r_pos{'y'}+1;
                push @{$r_array}, {%pos};
        }
}

#sellAuto for items_control - chobit andy 20030210
sub ai_sellAutoCheck {
        for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
                next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'});
                if ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'sell'}
                        && $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}) {
                        return 1;
                }
        }
        if ($config{'cartAuto'} && $config{'cartAutoSell'}) {
                for ($i = 0; $i < @{$cart{'inventory'}};$i++) {
                        next if (!%{$cart{'inventory'}[$i]});
                        if ($items_control{lc($cart{'inventory'}[$i]{'name'})}{'sell'}
                                && $cart{'inventory'}[$i]{'amount'} > $items_control{lc($cart{'inventory'}[$i]{'name'})}{'keep'}) {
                                return 1;
                        }
                }
        }
}

sub ai_setMapChanged {
        my $index = shift;
        $index = 0 if ($index eq "");
        if ($index < @ai_seq_args) {
                $ai_seq_args[$index]{'mapChanged'} = time;
        }
        $ai_v{'portalTrace_mapChanged'} = 1;
}

sub ai_setSuspend {
        my $index = shift;
        $index = 0 if ($index eq "");
        if ($index < @ai_seq_args) {
                $ai_seq_args[$index]{'suspended'} = time;
        }
}

sub ai_skillUse {
        my $ID = shift;
        my $lv = shift;
        my $maxCastTime = shift;
        my $minCastTime = shift;
        my $target = shift;
        my $y = shift;
        my %args;
        $args{'ai_skill_use_giveup'}{'time'} = time;
        $args{'ai_skill_use_giveup'}{'timeout'} = $timeout{'ai_skill_use_giveup'}{'timeout'};
        $args{'skill_use_id'} = $ID;
        $args{'skill_use_lv'} = $lv;
        $args{'skill_use_maxCastTime'}{'time'} = time;
        $args{'skill_use_maxCastTime'}{'timeout'} = $maxCastTime;
        $args{'skill_use_minCastTime'}{'time'} = time;
        $args{'skill_use_minCastTime'}{'timeout'} = $minCastTime;
        if ($y eq "") {
                $args{'skill_use_target'} = $target;
        } else {
                $args{'skill_use_target_x'} = $target;
                $args{'skill_use_target_y'} = $y;
        }
        unshift @ai_seq, "skill_use";
        unshift @ai_seq_args, \%args;
	ai_autoSwitch("skill_use", $ID);
}

#storageAuto for items_control - chobit andy 20030210
sub ai_storageAutoCheck {
        for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
                next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'});
                if ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'storage'}
                        && $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}) {
                        return 1;
                }
        }
        if ($config{'cartAuto'} && $config{'cartAutoStorage'}) {
                for ($i = 0; $i < @{$cart{'inventory'}};$i++) {
                        next if (!%{$cart{'inventory'}[$i]});
                        if ($items_control{lc($cart{'inventory'}[$i]{'name'})}{'storage'}
                                && $cart{'inventory'}[$i]{'amount'} > $items_control{lc($cart{'inventory'}[$i]{'name'})}{'keep'}) {
                                return 1;
                        }
                }
        }
}

sub attack {
        my $ID = shift;
        my %args;
        undef $timeout{'ai_attack'}{'time'};
        $args{'ai_attack_giveup'}{'time'} = time;
        $args{'ai_attack_start'}{'time'} = time;
        $args{'ai_attack_giveup'}{'timeout'} = $timeout{'ai_attack_giveup'}{'timeout'};
        $args{'ID'} = $ID;
        %{$args{'pos_to'}} = %{$monsters{$ID}{'pos_to'}};
        %{$args{'pos'}} = %{$monsters{$ID}{'pos'}};
        my $dMDist = sprintf("%-2.1f", distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ID}{'pos_to'}}));
        unshift @ai_seq, "attack";
        unshift @ai_seq_args, \%args;
        printc(1, "ww", "<信息> ", "目标: $monsters{$ID}{'name'}($monsters{$ID}{'binID'}) 距离: $dMDist\n");
	ai_autoSwitch("attack", $ID);
}

sub aiRemove {
        my $ai_type = shift;
        my $index;
        while (1) {
                $index = binFind(\@ai_seq, $ai_type);
                if ($index ne "") {
                        if ($ai_seq_args[$index]{'destroyFunction'}) {
                                &{$ai_seq_args[$index]{'destroyFunction'}}(\%{$ai_seq_args[$index]});
                        }
                        binRemoveAndShiftByIndex(\@ai_seq, $index);
                        binRemoveAndShiftByIndex(\@ai_seq_args, $index);
                } else {
                        last;
                }
        }
}


sub gather {
        my $ID = shift;
        my %args;
        $args{'ai_items_gather_giveup'}{'time'} = time;
        $args{'ai_items_gather_giveup'}{'timeout'} = $timeout{'ai_items_gather_giveup'}{'timeout'};
        $args{'ID'} = $ID;
        %{$args{'pos'}} = %{$items{$ID}{'pos'}};
        unshift @ai_seq, "items_gather";
        unshift @ai_seq_args, \%args;
        print "Targeting for Gather: $items{$ID}{'name'}($items{$ID}{'binID'})\n" if $config{'debug'};
}


sub look {
        my $body = shift;
        my $head = shift;
        my %args;
        unshift @ai_seq, "look";
        $args{'look_body'} = $body;
        $args{'look_head'} = $head;
        unshift @ai_seq_args, \%args;
}

sub move {
        my $x = shift;
        my $y = shift;
        my %args;
        $args{'move_to'}{'x'} = $x;
        $args{'move_to'}{'y'} = $y;
        $args{'ai_move_giveup'}{'time'} = time;
        $args{'ai_move_giveup'}{'timeout'} = $timeout{'ai_move_giveup'}{'timeout'};
        unshift @ai_seq, "move";
        unshift @ai_seq_args, \%args;
}

sub quit {
        $quit = 1;
        printc("yy", "<系统> ", "退出游戏\n\n");
}

sub relog {
        $conState = 1;
        undef $conState_tries;
        $timeout_ex{'master'}{'time'} = time;
        $timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
        killConnection(\$remote_socket) if (!$xKore);
        printc("yy", "<系统> ", "$timeout_ex{'master'}{'timeout'}秒后重新启动\n");
}

sub sendMessage {
        my $r_socket = shift;
        my $type = shift;
        my $msg = shift;
        my $user = shift;
        my $i, $j;
        my @msg;
        my @msgs;
        my $oldmsg;
        my $amount;
        my $space;
        @msgs = split /\\n/,$msg;
        for ($j = 0; $j < @msgs; $j++) {
        @msg = split / /, $msgs[$j];
        undef $msg;
        for ($i = 0; $i < @msg; $i++) {
                if (!length($msg[$i])) {
                        $msg[$i] = " ";
                        $space = 1;
                }
                if (length($msg[$i]) > $config{'message_length_max'}) {
                        while (length($msg[$i]) >= $config{'message_length_max'}) {
                                $oldmsg = $msg;
                                if (length($msg)) {
                                        $amount = $config{'message_length_max'};
                                        if ($amount - length($msg) > 0) {
                                                $amount = $config{'message_length_max'} - 1;
                                                $msg .= " " . substr($msg[$i], 0, $amount - length($msg));
                                        }
                                } else {
                                        $amount = $config{'message_length_max'};
                                        $msg .= substr($msg[$i], 0, $amount);
                                }
                                if ($type eq "c") {
                                        sendChat($r_socket, $msg);
                                } elsif ($type eq "g") {
                                        sendGuildChat($r_socket, $msg);
                                } elsif ($type eq "p") {
                                        sendPartyChat($r_socket, $msg);
                                } elsif ($type eq "pm") {
                                        sendPrivateMsg($r_socket, $user, $msg);
                                        undef %lastpm;
                                        $lastpm{'msg'} = $msg;
                                        $lastpm{'user'} = $user;
                                        push @lastpm, {%lastpm};
                                } elsif ($type eq "k" && $xKore) {
                                        injectMessage($msg);
                                }
                                $msg[$i] = substr($msg[$i], $amount - length($oldmsg), length($msg[$i]) - $amount - length($oldmsg));
                                undef $msg;
                        }
                }
                if (length($msg[$i]) && length($msg) + length($msg[$i]) <= $config{'message_length_max'}) {
                        if (length($msg)) {
                                if (!$space) {
                                        $msg .= " " . $msg[$i];
                                } else {
                                        $space = 0;
                                        $msg .= $msg[$i];
                                }
                        } else {
                                $msg .= $msg[$i];
                        }
                } else {
                        if ($type eq "c") {
                                sendChat($r_socket, $msg);
                        } elsif ($type eq "g") {
                                sendGuildChat($r_socket, $msg);
                        } elsif ($type eq "p") {
                                sendPartyChat($r_socket, $msg);
                        } elsif ($type eq "pm") {
                                sendPrivateMsg($r_socket, $user, $msg);
                                undef %lastpm;
                                $lastpm{'msg'} = $msg;
                                $lastpm{'user'} = $user;
                                push @lastpm, {%lastpm};
                        } elsif ($type eq "k" && $xKore) {
                                injectMessage($msg);
                        }
                        $msg = $msg[$i];
                }
                if (length($msg) && $i == @msg - 1) {
                        if ($type eq "c") {
                                sendChat($r_socket, $msg);
                        } elsif ($type eq "g") {
                                sendGuildChat($r_socket, $msg);
                        } elsif ($type eq "p") {
                                sendPartyChat($r_socket, $msg);
                        } elsif ($type eq "pm") {
                                sendPrivateMsg($r_socket, $user, $msg);
                                undef %lastpm;
                                $lastpm{'msg'} = $msg;
                                $lastpm{'user'} = $user;
                                push @lastpm, {%lastpm};
                        } elsif ($type eq "k" && $xKore) {
                                injectMessage($msg);
                        }
                }
        }
        }
}

sub sit {
        $timeout{'ai_sit_wait'}{'time'} = time;
        unshift @ai_seq, "sitting";
        unshift @ai_seq_args, {};
}

sub stand {
        unshift @ai_seq, "standing";
        unshift @ai_seq_args, {};
}

sub take {
        my $ID = shift;
        my %args;
        $args{'ai_take_giveup'}{'time'} = time;
        $args{'ai_take_giveup'}{'timeout'} = $timeout{'ai_take_giveup'}{'timeout'};
        $args{'ID'} = $ID;
        %{$args{'pos'}} = %{$items{$ID}{'pos'}};
        unshift @ai_seq, "take";
        unshift @ai_seq_args, \%args;
        print "Targeting for Pickup: $items{$ID}{'name'}($items{$ID}{'binID'})\n" if $config{'debug'};
}

# ICE Start - Teleport
sub useTeleport {
        my $level = shift;
        if ($chars[$config{'char'}]{'param1'} > 0) {
                printc("wr", "<信息> ", "异常状态禁止瞬移\n");
                return;
        } elsif ($ai_seq[0] ne "flyMap" && $field{'name'} ne "" && $indoor_lut{$field{'name'}.'.rsw'}) {
                printc("wrn", "<信息> ", "此地图禁止瞬移 $field{'name'}\n");
                return;
        }

        aiRemove("warp");
        aiRemove("move");
        aiRemove("attack");
        aiRemove("skill_use");
        $timeout{'ai_attack'}{'time'} = time + 2;
        $timeout{'ai_attack_auto'}{'time'} = time + 2;
        $timeout{'ai_skill_use'}{'time'} = time + 2;
        $timeout{'ai_item_use_auto'}{'time'} = time + 2;

        my $invIndex;
        my $accIndex = findIndexStringsNotSelected_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'accessoryTeleport'});
        if ($level == 1) {
                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 601) if ($level == 1);
        } elsif ($level == 2) {
                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 602) if ($level == 2);
        }
        if ($config{'saveMap_warpToFly'} && $config{'saveMap'} && $level == 2 && $mapserver_lut{$config{'saveMap'}.'.rsw'} && $mapip_lut{$config{'saveMap'}}{'ip'} ne "" && $mapip_lut{$config{'saveMap'}}{'port'} ne ""
                && $mapip_lut{$field{'name'}.'.rsw'}{'ip'} ne "" && $mapip_lut{$field{'name'}.'.rsw'}{'port'} ne "" && ($mapip_lut{$config{'saveMap'}.'.rsw'}{'ip'} ne $mapip_lut{$field{'name'}.'.rsw'}{'ip'} || ($mapip_lut{$config{'saveMap'}.'.rsw'}{'ip'} eq $mapip_lut{$field{'name'}.'.rsw'}{'ip'} && $mapip_lut{$config{'saveMap'}.'.rsw'}{'port'} ne $mapip_lut{$field{'name'}.'.rsw'}{'port'}))) {
                printc("yw", "<系统> ", "正在转移到: $mapip_lut{$config{'saveMap'}.'.rsw'}{'name'}($config{'saveMap'})\n");
                sendFly($mapip_lut{$config{'saveMap'}.'.rsw'}{'ip'}, $mapip_lut{$config{'saveMap'}.'.rsw'}{'port'});
        } elsif ($chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} >= 1) {
                sendTeleport(\$remote_socket, "Random") if ($level == 1);
                sendTeleport(\$remote_socket, $config{'saveMap'}.".gat") if ($level == 2);
        } elsif ($accIndex ne "") {
                sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$accIndex]{'index'}, $chars[$config{'char'}]{'inventory'}[$accIndex]{'type_equip'}) if (!$chars[$config{'char'}]{'inventory'}[$accIndex]{'equipped'} || $ai_v{'temp'}{'teleport_tried'} > 2);
                sendTeleport(\$remote_socket, "Random") if ($level == 1);
                sendTeleport(\$remote_socket, $config{'saveMap'}.".gat") if ($level == 2);
		$ai_v{'temp'}{'teleport_tried'}++;
        } elsif ($invIndex ne "") {
                sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}, $accountID);
        } else {
                print "Can't teleport or respawn - need wing or skill\n" if $config{'debug'};
        }
}
# -End-




#######################################
#######################################
#AI MATH
#######################################
#######################################


sub distance {
        my $r_hash1 = shift;
        my $r_hash2 = shift;
        my %line;
        if ($r_hash2) {
                $line{'x'} = abs($$r_hash1{'x'} - $$r_hash2{'x'});
                $line{'y'} = abs($$r_hash1{'y'} - $$r_hash2{'y'});
        } else {
                %line = %{$r_hash1};
        }
        return sqrt($line{'x'} ** 2 + $line{'y'} ** 2);
}

sub getVector {
        my $r_store = shift;
        my $r_head = shift;
        my $r_tail = shift;
        $$r_store{'x'} = $$r_head{'x'} - $$r_tail{'x'};
        $$r_store{'y'} = $$r_head{'y'} - $$r_tail{'y'};
}

sub lineIntersection {
        my $r_pos1 = shift;
        my $r_pos2 = shift;
        my $r_pos3 = shift;
        my $r_pos4 = shift;
        my $x1, $x2, $x3, $x4, $y1, $y2, $y3, $y4, $result, $result1, $result2;
        $x1 = $$r_pos1{'x'};
        $y1 = $$r_pos1{'y'};
        $x2 = $$r_pos2{'x'};
        $y2 = $$r_pos2{'y'};
        $x3 = $$r_pos3{'x'};
        $y3 = $$r_pos3{'y'};
        $x4 = $$r_pos4{'x'};
        $y4 = $$r_pos4{'y'};
        $result1 = ($x4 - $x3)*($y1 - $y3) - ($y4 - $y3)*($x1 - $x3);
        $result2 = ($y4 - $y3)*($x2 - $x1) - ($x4 - $x3)*($y2 - $y1);
        if ($result2 != 0) {
                $result = $result1 / $result2;
        }
        return $result;
}


sub moveAlongVector {
        my $r_store = shift;
        my $r_pos = shift;
        my $r_vec = shift;
        my $amount = shift;
        my %norm;
        if ($amount) {
                normalize(\%norm, $r_vec);
                $$r_store{'x'} = $$r_pos{'x'} + $norm{'x'} * $amount;
                $$r_store{'y'} = $$r_pos{'y'} + $norm{'y'} * $amount;
        } else {
                $$r_store{'x'} = $$r_pos{'x'} + $$r_vec{'x'};
                $$r_store{'y'} = $$r_pos{'y'} + $$r_vec{'y'};
        }
}

sub normalize {
        my $r_store = shift;
        my $r_vec = shift;
        my $dist;
        $dist = distance($r_vec);
        if ($dist > 0) {
                $$r_store{'x'} = $$r_vec{'x'} / $dist;
                $$r_store{'y'} = $$r_vec{'y'} / $dist;
        } else {
                $$r_store{'x'} = 0;
                $$r_store{'y'} = 0;
        }
}

sub percent_hp {
        my $r_hash = shift;
        if (!$$r_hash{'hp_max'}) {
                return 0;
        } else {
                return ($$r_hash{'hp'} / $$r_hash{'hp_max'} * 100);
        }
}

sub percent_sp {
        my $r_hash = shift;
        if (!$$r_hash{'sp_max'}) {
                return 0;
        } else {
                return ($$r_hash{'sp'} / $$r_hash{'sp_max'} * 100);
        }
}

sub percent_weight {
        my $r_hash = shift;
        if (!$$r_hash{'weight_max'}) {
                return 0;
        } else {
                return ($$r_hash{'weight'} / $$r_hash{'weight_max'} * 100);
        }
}


1;