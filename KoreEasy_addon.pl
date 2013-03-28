#######################################
#Kore Easy Add-on
#######################################



##### PARSE FILES #####

sub parsePlusRLUT {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/\r//g;
                s/\n//g;
                if( $_ ne "" ){
                        $$r_hash{$_} = 1;
                }
        }
        close FILE;
}

##### INITIALIZE VARIABLES #####

sub initMonControl {
	my @array;
        if ($mon_control{'all'}{'attack_auto'} eq "") {
                $mon_control{'all'}{'attack_auto'} = 2;
        }
        @array = split /,/, $config{'monstersAttackFirst'};
        foreach (@array) {
                $mon_control{lc($_)}{'attack_auto'} = 3;
        }      
        @array = split /,/, $config{'monstersAttackSkip'};
        foreach (@array) {
                $mon_control{lc($_)}{'attack_auto'} = 0;
        }
        @array = split /,/, $config{'monstersTeleportSee'};
        foreach (@array) {
                $mon_control{lc($_)}{'teleport_auto'} = 1;
        }
        @array = split /,/, $config{'monstersTeleportHit'};
        foreach (@array) {
                $mon_control{lc($_)}{'teleport_auto'} = 2;
        }
        @array = split /,/, $config{'monstersTeleportDmg'};
        foreach (@array) {
                $mon_control{lc($_)}{'teleport_auto'} = 3;
        }
}

sub initNpcControl {
        dynParseFiles("$setup_path/npc_control.txt", \%npc_control, \&parseDataFile2);
        my $i = 0;
        my $Inx = 0;
        while ($npc_control{"saveMap_".$i} ne "") {
                if (existsInList($npc_control{"saveMap_".$i}, $config{'saveMap'})) {
                        $Inx = $i;
                        last;
                }
                $i++;
        }
        $config{'storageAuto_npc'} = $npc_control{"saveMap_".$Inx."_storage"};
        $config{'storageAuto_npc_steps'} = $npc_control{"saveMap_".$Inx."_storage_steps"};
        $config{'sellAuto_npc'} = $npc_control{"saveMap_".$Inx."_sell"};
        $config{'healAuto_npc'} = $npc_control{"saveMap_".$Inx."_heal"};
        $config{'fixAuto_npc'} = $npc_control{"saveMap_".$Inx."_fix"};
        $config{'fixAuto_npc_steps'} = $npc_control{"saveMap_".$Inx."_fix_steps"};
        
        my $i = 0;
        while ($config{"buyAuto_$i"} ne "") {
                my $j = 0;
                while ($npc_control{"saveMap_".$Inx."_item_".$j} ne "") {
                        if (existsInList($npc_control{"saveMap_".$Inx."_item_".$j}, $config{"buyAuto_$i"})) {
                                $config{"buyAuto_$i"."_npc"} = $npc_control{"saveMap_".$Inx."_npc_".$j};
                                last;
                        }
                        $j++;
                }
                $i++;
        }
        my $i = 0;
        while ($config{"getAuto_$i"} ne "") {
                $config{"getAuto_$i"."_npc"} = $config{'storageAuto_npc'};
                $i++;
        }
        undef %npc_control;
}

sub initPlusControl {
        dynParseFiles("$setup_path/plus_control.txt", \%plus, \&parseDataFile2);
        my $key;
        my @keys;
        foreach $key (keys %plus) {
                $config{$key} = $plus{$key} if ($config{$key} eq "");
        }
        undef %plus;
}

sub initSkillControl {
        dynParseFiles("$setup_path/skill_control.txt", \%skill_control, \&parseDataFile2);
        my $key;
        my @keys;
        foreach $key (keys %skill_control) {
                $config{$key} = $skill_control{$key} if ($config{$key} eq "");
        }
        undef %skill_control;
}

sub initEquipControl {
        dynParseFiles("$setup_path/weapon_control.txt", \%equip_control, \&parseDataFile2);
        my $key;
        my @keys;
        foreach $key (keys %equip_control) {
                $config{$key} = $equip_control{$key} if ($config{$key} eq "");
        }
        undef %equip_control; 
}



##### ADD-ON FUNCTIONS #####

sub startKoreEasy {
        initPlusControl();
        initSkillControl();
        initEquipControl();
        initNpcControl();
        initMonControl();
        dynParseFiles("data/avoidaid.txt", \%aid_rlut, \&parseAidRLUT);        
        $config{'sitAuto_hp_upper'} = 0 if (!$config{'sitAuto_hp_lower'});
        $config{'sitAuto_sp_upper'} = 0 if (!$config{'sitAuto_sp_lower'});
        $config{'cartAutoItemMaxWeight'} = 20 if (!$config{'cartAutoItemMaxWeight'});
	if (!$config{'itemsKeepUnlock'}) {
        	my $i = 0;
        	while ($config{"buyAuto_".$i} ne "") {
                	$items_control{lc($config{"buyAuto_".$i})}{'keep'} = $config{"buyAuto_".$i."_maxAmount"} if ($items_control{lc($config{"buyAuto_".$i})}{'keep'} < $config{"buyAuto_".$i."_maxAmount"});
                	$items_control{lc($config{"buyAuto_".$i})}{'keepCart'} = $config{"buyAuto_".$i."_maxCartAmount"} if($items_control{lc($config{"buyAuto_".$i})}{'keepCart'} < $config{"buyAuto_".$i."_maxCartAmount"});
                	$i++;
        	}
        	my $i = 0;
        	while ($config{"getAuto_".$i} ne "") {
	                $items_control{lc($config{"getAuto_".$i})}{'keep'} = $config{"getAuto_".$i."_maxAmount"} if ($items_control{lc($config{"getAuto_".$i})}{'keep'} < $config{"getAuto_".$i."_maxAmount"});
        	        $items_control{lc($config{"getAuto_".$i})}{'keepCart'} = $config{"getAuto_".$i."_maxCartAmount"} if ($items_control{lc($config{"getAuto_".$i})}{'keepCart'} < $config{"getAuto_".$i."_maxCartAmount"});
                	$i++;
	        }
	}
        my $i = 0;
        my $j = 0;
        while ($i == 0 || $config{"autoSwitch_$i"."_equip_0"} ne "") {
        	while ($config{"autoSwitch_$i"."_equip_$j"} ne "") {
        		undef %{$items_control{lc($config{"autoSwitch_$i"."_equip_$j"})}};
        		$j++;
        	}
        	$i++;
        }
        undef %{$items_control{lc($config{'accessoryTeleport'})}} if ($config{'accessoryTeleport'} ne "");
}



sub getImportantItems{
       my $ID = shift;
       my $dist = shift;
       my %args;
       if($itemsPickup{$items{$ID}{'name'}} >= 2){
                ai_setSuspend(0);
                $args{'ID'} = $ID;
                unshift @ai_seq, "items_important";
                unshift @ai_seq_args, \%args;
                printc(1, "wy", "<物品> ", "发现: $items{$ID}{'name'} - $dist\n");
                chatLog("i", "发现: $items{$ID}{'name'} - $dist\n");
                sendTake(\$remote_socket, $ID);
        }
}



##### AI FUNCTIONS #####

sub ai_changeToMvpMode {
        my $type = shift;
        if ($type) {
                undef @ai_seq;
                undef @ai_seq_args;
                $chars[$config{'char'}]{'mvp'} = 1;
                $chars[$config{'char'}]{'mvp_start_time'} = time;
                $timeout{'ai_attack_giveup'}{'timeout'} = 600;
                $timeout{'ai_attack_waitAfterKill'}{'timeout'} = 2;
                $timeout{'ai_items_take_end'}{'timeout'} = 2;
                my $key;
                my @keys;
                foreach $key (keys %mvp) {
                        $config{$key} = $mvp{$key};
                }
                printc(1, "yy", "<系统> ", "变为MVP模式\n");
                initMonControl();
        } else {
                undef $chars[$config{'char'}]{'mvp'};
                parseReload("config");
                parseReload("timeout");
                printc(1, "yy", "<系统> ", "变为正常模式\n");
                startKoreEasy();
                $chars[$config{'char'}]{'mvp_end_time'} = time;
        }
}

sub ai_getTeleportAggressives {
        my $tpMonsters;
        foreach (@monstersID) {
                next if ($_ eq "");
                if ($monsters{$_}{'dmgToYou'} > 0 || ($monsters{$_}{'missedYou'} > 0 && !$config{'teleportAuto_skipMiss'})) {
                        if (!$mon_control{lc($monsters{$_}{'name'})}{'teleport_count'}) {
                                $tpMonsters++;
                        } else {
                                $tpMonsters += $mon_control{lc($monsters{$_}{'name'})}{'teleport_count'};
                        }
                }
        }
        return $tpMonsters;
}

sub ai_getAttackAggressives {
        my @agMonsters;
        foreach (@monstersID) {
                next if ($_ eq "");
                if ($config{'lockMap'} && $field{'name'} && $field{'name'} eq $config{'lockMap'}) {
                        if (($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "0" || ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "" && $mon_control{'all'}{'attack_auto'} eq "0"))) {
                                #don't attack skip monster
                        } elsif (($monsters{$_}{'dmgToYou'} > 0 || $monsters{$_}{'missedYou'} > 0) && !$monsters{$_}{'attack_failed'}) {
                                push @agMonsters, $_;
                        }
                } else {
                        if ($config{'attackOnRouteSkipMonsters'} eq "1" || ($config{'attackOnRouteSkipMonsters'} ne "" && existsInList($config{'attackOnRouteSkipMonsters'}, $monsters{$_}{'name'}))) {
                                #don't attack skip monster
                        } elsif ($monsters{$_}{'dmgToYou'} > 0 && !$monsters{$_}{'attack_failed'}) {
                                push @agMonsters, $_;
                        }
                }
        }
        return @agMonsters;
}

sub ai_getRoundMonster {
        my $dist = shift;
        my @rdMonsters;
        foreach (@monstersID) {
                next if ($_ eq "" || $monsterTypes_lut{lc($monsters{$_}{'name'})} eq "0");
                if (distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}}) <= $dist) {
                        push @rdMonsters, $_;
                }
        }
        return @rdMonsters;
}

sub ai_getTalkID {
        my $talkid = shift;
        if (unpack("L1",$talkid) < 10000) {
                $talkid = unpack("L1",$talkid);
                for ($i = 0; $i < @npcsID; $i++) {
                next if ($npcsID[$i] eq "");
                        if ($npcs_lut{$talkid}{'pos'}{'x'} == $npcs{$npcsID[$i]}{'pos'}{'x'} && $npcs_lut{$talkid}{'pos'}{'y'} == $npcs{$npcsID[$i]}{'pos'}{'y'}) {
                                $talkid = $npcsID[$i];
                        }
                }
                return $talkid;
        } else {
                return $talkid;
        }
}

sub findIndexMultiString_lc {
        my $r_array = shift;
        my $match = shift;
        my $list = shift;
        my @array = split /,/, $list;
        my $index;
        foreach (@array) {
                s/^\s+//;
                s/\s+$//;
                s/\s+/ /g;
                next if ($_ eq "");
                $index = findIndexString_lc($r_array, $match, $_);
                if ($index ne "") {
                        return $index;
                }
        }
        return $index;
}


##### OUTGOING PACKET FUNCTIONS #####


sub printAttack {
        my $type = shift;
        my $sourceID = shift;
        my $targetID = shift;
        my $damage1 = shift;
        my $damage2 = shift;
        my $extra = shift;
        my $skillID = shift;
        my $level = shift;
        my $typeDisplay, $sourceDisplay, $targetDisplay, $damageDisplay, $extraDisplay, $skillDisplay;
        $level = 0 if ($level > 10);
        $skillColor = "n";
        undef $damageDisplay;
        undef $extraDisplay;
        undef $skillDisplay;
        undef $showDisplay;

        if ($sourceID eq $accountID) {
                $sourceDisplay = "你";
                $skillColor = "c";
                $sourceType = 1;
        } elsif (%{$players{$sourceID}}) {
                $sourceDisplay = "$players{$sourceID}{'name'}($players{$sourceID}{'binID'})";
                $sourceType = 2;
        } elsif (%{$monsters{$sourceID}}) {
                $sourceDisplay = "$monsters{$sourceID}{'name'}($monsters{$sourceID}{'binID'})";
                $sourceType = 3;
        } else {
                $sourceDisplay = "未知";
                $sourceType = 4;
        }

        if ($targetID eq $sourceID) {
                $targetDisplay = "自己";
                $targetType = 5;
        } elsif ($targetID eq $accountID) {
                $targetDisplay = "你";
                $targetType = 1;
                $skillColor = "m" if ($sourceType == 3);
        } elsif (%{$players{$targetID}}) {
                $targetDisplay = "$players{$targetID}{'name'}($players{$targetID}{'binID'})";
                $targetType = 2;
        } elsif (%{$monsters{$targetID}}) {
                $targetDisplay = "$monsters{$targetID}{'name'}($monsters{$targetID}{'binID'})";
                $targetType = 3;
        } elsif ($targetID eq "pos") {
                $targetDisplay = "位置($damage1,$damage2)";
                $targetType = 6;
                undef %{$ai_v{'temp'}{'pos'}};
                $ai_v{'temp'}{'pos'}{'x'} = $damage1;
                $ai_v{'temp'}{'pos'}{'y'} = $damage2;
        } else {
                $targetDisplay = "未知";
                $targetType = 4;
        }
        if ($sourceType == 3 && $targetType == 6 && distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'pos'}}) <= 6) {
                $targetType = 7;
                $skillColor = "m";
        } elsif ($sourceType == 3 && $targetType == 5 && ($monsters{$sourceID}{'dmgToYou'} > 0 || $monsters{$sourceID}{'missedYou'} > 0 || $monsters{$sourceID}{'dmgFromYou'} > 0 || $monsters{$sourceID}{'missedFromYou'} > 0)) {
                $targetType = 8;
                $skillColor = "m";
        }

        if ($config{'mode'} >= 3 || ($config{'mode'} && ($sourceType == 1 || $targetType == 1 || $targetType == 7 || $targetType == 8))) {
                $showDisplay = 1;
        }

        if ($showDisplay) {
                if ($type eq "a") {
                        $typeDisplay = "";
                } elsif ($type eq "h") {
                        $typeDisplay = "使用";
                        $extraColor = "g";
                        $extraDisplay = $extra;
                } elsif ($type eq "u" || $type eq "s") {
                        $typeDisplay = "使用";
                } elsif ($type eq "c") {
                        $typeDisplay = "施放";
                }
                if ($sourceType == 1 && $targetType == 3 && ($type eq "a" || $type eq "s")) {
                        printc("c", "<攻击> ");
                        if ($damage1 <= 0) {
                                $chars[$config{'char'}]{'miss_count'}++;
                        } else {
                                undef $chars[$config{'char'}]{'miss_count'};
                        }
                        if ($damage1 == 0 && $extra == 11) {
                                $damageColor = "r";
                                $damageDisplay = "Luk ";
                        } elsif ($damage1 == 0) {
                                $damageColor = "r";
                                $damageDisplay = "Miss ";
                        } elsif ($damage1 > 0 && $extra == 8) {
                                $damageColor = "y";
                                $damageDisplay = $damage1;
                                $damageDisplay .= "/$damage2" if ($damage2 > 0);
                                $damageDisplay .= " ";
                        } elsif ($damage1 > 0) {
                                $damageColor = "w";
                                $damageDisplay = $damage1;
                                $damageDisplay .= "/$damage2" if ($damage2 > 0);
                                $damageDisplay .= " ";
                        } else {
                                $damageColor = "g";
                                $damageDisplay = $damage1;
                                $damageDisplay .= "/$damage2" if ($damage2 > 0);
                                $damageDisplay .= " ";
                        }
                        $extraColor = "w";
                        $extraDisplay = "($monsters{$targetID}{'dmgTo'}) ";
                } elsif ($sourceType == 3 && $targetType == 1 && ($type eq "a" || $type eq "s")) {
                        printc("r", "<防守> ");
                        if ($damage1 == 0 && $extra == 11) {
                                $damageColor = "y";
                                $damageDisplay = "Luk ";
                        } elsif ($damage1 == 0) {
                                $damageColor = "w";
                                $damageDisplay = "Miss ";
                        } elsif ($damage1 > 0 && $extra == 8) {
                                $damageColor = "r";
                                $damageDisplay = $damage1." ";
                        } elsif ($damage1 > 0) {
                                $damageColor = "r";
                                $damageDisplay = $damage1." ";
                        } else {
                                $damageColor = "g";
                                $damageDisplay = $damage1." ";
                        }
                        $extraColor = "r";
                        $extraDisplay = "(".int($chars[$config{'char'}]{'hp'}/$chars[$config{'char'}]{'hp_max'} * 100)."/".int($chars[$config{'char'}]{'sp'}/$chars[$config{'char'}]{'sp_max'} * 100).") ";
                } elsif ($type eq "a" || $type eq "s") {
                        printc("w", "<信息> ");
                        $damageColor = "n";
                        if ($damage1 == 0) {
                                $damageDisplay = "Miss ";
                        } else {
                                $damageDisplay = $damage1." ";
                        }
                } else {
                        printc("w", "<信息> ");
                }

                if ($skillID ne "") {
                        $skillDisplay = "$skillsID_lut{$skillID}";
                        $skillDisplay .= "$level级" if ($level > 0);
                        $skillDisplay .= " ";
                }
                if ($type eq "a") {
                        if ($sourceType == 1 && $targetType == 3) {
                                printc("n", "$targetDisplay ");
                        } elsif ($sourceType == 3 && $targetType == 1) {
                                printc("n", "$sourceDisplay ");
                        } else {
                                printc("n", "$sourceDisplay 攻击 $targetDisplay ");
                        }
                } else {
                        printc("n", "$sourceDisplay 对 $targetDisplay $typeDisplay ");
                }
                if ($targetID eq "pos") {
                        $extraColor = "n";
                        $extraDisplay = "距离: " . int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'pos'}}));
                }
                printc($skillColor, $skillDisplay);
                printc($damageColor, $damageDisplay);
                printc($extraColor, $extraDisplay);
                print "\n";
        }

	if ($AI) {
	        if (($type eq "a" || $type eq "u" || $type eq "s" || $type eq "c") && ($sourceType == 3 && ($targetType == 1 || $targetType == 7 || $targetType == 8))) {
		        if ($ai_v{'ai_teleport_safe'}) {
				undef $ai_v{'temp'}{'found'};
                		foreach (@monstersID) {
		                        next if ($_ eq "");
                		        if ($mon_control{lc($monsters{$_}{'name'})}{'teleport_auto'} == 1 || ($mon_control{lc($monsters{$_}{'name'})}{'teleport_auto'} == 2 && ($monsters{$_}{'dmgToYou'} > 0 || $monsters{$_}{'missedYou'} > 0)) || ($mon_control{lc($monsters{$_}{'name'})}{'teleport_auto'} == 3 && $monsters{$_}{'dmgToYou'} > 0)) {
		                                printc(1, "wr", "<瞬移> ", "躲避怪物 $monsters{$_}{'name'}\n") if ($config{'mode'});
						$ai_v{'temp'}{'found'} = 2;
                                		last;
		                        }
		                }
				if (!$ai_v{'temp'}{'found'}) {
					if ((($config{'teleportAuto_hp'} && percent_hp(\%{$chars[$config{'char'}]}) <= $config{'teleportAuto_hp'}) || ($config{'teleportAuto_sp'} && percent_sp(\%{$chars[$config{'char'}]}) <= $config{'teleportAuto_sp'})) && ai_getAggressives()) {
				                printc(1, "wr", "<瞬移> ", "剩下HP: $chars[$config{'char'}]{'hp'} / SP: $chars[$config{'char'}]{'sp'}\n") if ($config{'mode'});
						$ai_v{'temp'}{'found'} = 2;
				        } elsif ($config{'teleportAuto_minAggressives'} && ai_getTeleportAggressives() >= $config{'teleportAuto_minAggressives'}) {
	        			        $ai_v{'temp'}{'agMonsters'} = ai_getTeleportAggressives();
        	        			printc(1, "wr", "<瞬移> ", "被$ai_v{'temp'}{'agMonsters'}只怪物攻击\n") if ($config{'mode'});
						$ai_v{'temp'}{'found'} = 2;
					} elsif ($skillID ne "" && existsInList($config{'teleportAuto_skills'}, $skillsID_lut{$skillID})) {
        	                		printc("wr", "<瞬移> ", "躲避技能 $skillsID_lut{$skillID}\n") if ($config{'mode'});
						$ai_v{'temp'}{'found'} = 2;
			                } elsif ($config{'teleportAuto_damage'} && $sourceType == 3 && $targetType == 1 && ($type eq "a" || $type eq "s") && $damage1 > $config{'teleportAuto_damage'}) {
			                	printc("wr", "<瞬移> ", "一击伤害大于$config{'teleportAuto_damage'}\n") if ($config{'mode'});
			                	$ai_v{'temp'}{'found'} = 2;
			                }
				}
				if ($ai_v{'temp'}{'found'} && (binFind(\@ai_seq, "items_important") eq "" || $ai_v{'temp'}{'found'} >= 2)) {
					useTeleport(1);
					$timeout{'ai_teleport_hp'}{'time'} = time;
				}
			}	                
	        } elsif ($type eq "c" && $skillID == 27 && $sourceType != 1 && distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'pos'}}) == 0) {
        	        if ($config{'teleportAuto_portalPlayer'} == 1 && !$indoor_lut{$field{'name'}.'.rsw'}) {
                	        printc("wr", "<瞬移> ", "瞬移躲避恶意传送: $players{$sourceID}{'name'} $field{'name'} ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})\n") if ($config{'mode'});
                        	chatLog("x", "瞬移躲避恶意传送: $players{$sourceID}{'name'} $field{'name'} ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})\n");
	                        useTeleport(1);
        	        } elsif ($config{'teleportAuto_portalPlayer'} == 2 || $indoor_lut{$field{'name'}.'.rsw'}) {
                	        aiRemove("move");
                        	aiRemove("route");
	                        aiRemove("route_getRoute");
        	                aiRemove("route_getMapRoute");
                	        printc("wr", "<瞬移> ", "移动躲避恶意传送: $players{$sourceID}{'name'} $field{'name'} ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})\n") if ($config{'mode'});
                        	chatLog("x", "移动躲避恶意传送: $players{$sourceID}{'name'} $field{'name'} ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})\n");
	                        while (1) {
        	                        undef $ai_v{'temp'}{'found'};
                	                $ai_v{'temp'}{'x'} = int(rand() * 10 - 5 + $ai_v{'temp'}{'pos'}{'x'});
                        	        $ai_v{'temp'}{'y'} = int(rand() * 10 - 5 + $ai_v{'temp'}{'pos'}{'y'});
	                                if (($ai_v{'temp'}{'x'} == $ai_v{'temp'}{'pos'}{'x'}) && ($ai_v{'temp'}{'y'} == $ai_v{'temp'}{'pos'}{'y'})) {
        	                                $ai_v{'temp'}{'x'} = int(1 + $ai_v{'temp'}{'x'});
                	                }
                        	        foreach (keys %spells) {
                                	        next if ($spells{$_}{'name'} ne $msgstrings_lut{'011F'}{'129'} && $spells{$_}{'name'} ne $msgstrings_lut{'011F'}{'130'});
                                        	if ($ai_v{'temp'}{'x'} == $spells{$_}{'pos'}{'x'} && $ai_v{'temp'}{'y'} == $spells{$_}{'pos'}{'y'}) {
                                                	$ai_v{'temp'}{'found'} = 1;
	                                                last;
        	                                }
                	                }
                        	        last if (!$ai_v{'temp'}{'found'});
	                        }
        	                move($ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'});
                	}
	        }
	        if ($sourceType == 2 && $targetType == 1 && $skillID == 68 && binFind(\@partyUsersID, $sourceID) eq "") {
        	        printc(1, "wrn", "<信息> ", "恶意撒水祈福 ", "$players{$sourceID}{'name'} $field{'name'}\n") if ($config{'mode'});
	                chatLog("x", "恶意撒水祈福：$players{$sourceID}{'name'} $field{'name'}\n");
                	for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
        	                next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || !$chars[$config{'char'}]{'inventory'}[$i]{'equipped'});
	                        if ($chars[$config{'char'}]{'inventory'}[$i]{'equipped'} & 2 || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'} == 32768) {
                                	sendUnequip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$i]{'index'});
                        	        sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$i]{'index'}, $chars[$config{'char'}]{'inventory'}[$i]{'equipped'});
                	        }
        	        }
	        }
	}        
        if (($type eq "u" || $type eq "s") && $sourceType == 1 && $targetType == 3 && binFind(\@ai_seq, "attack") ne "") {
                undef $ai_v{'ai_attack_index'};
                $ai_v{'ai_attack_index'} = binFind(\@ai_seq, "attack");
                $i = 0;
                while ($config{"attackSkillSlot_$i"} ne "") {
                        if ($skillsID_lut{$skillID} eq $config{"attackSkillSlot_$i"} && $ai_seq_args[$ai_v{'ai_attack_index'}]{'attackSkillSlot_uses'}{$i} < $config{"attackSkillSlot_$i"."_maxUses"}) {
                                $ai_seq_args[$ai_v{'ai_attack_index'}]{'attackSkillSlot_uses'}{$i}++;
                                last;
                        }
                        $i++;
                }
        }
        if (%{$monsters{$targetID}} && $skillID == 50) {
                $monsters{$targetID}{'stolen'} = 1;
                $monsters{$targetID}{'stolenBy'} = $sourceID;
                ai_changedByMonster("stolen", $targetID) if ($config{'stealOnly'});
        }
        if (($type eq "u" || $type eq "s") && %{$monsters{$targetID}} && $skillID && $msgstrings_rlut{'0196'}{$skillsID_lut{$skillID}} ne "") {
        	$monsters{$targetID}{'skillsst'}{$msgstrings_rlut{'0196'}{$skillsID_lut{$skillID}}} = 1;
        }
        if ($type eq "a" && $targetID eq $accountID && $damage1 > 0 && $ai_seq[0] eq "move") {
		if (binFind(\@ai_seq, "attack") eq "") {
	                sendMove(\$remote_socket, int($ai_seq_args[0]{'move_to'}{'x'}), int($ai_seq_args[0]{'move_to'}{'y'}));
		} else {
			sendMove(\$remote_socket, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
		}
        }
}

sub parseMapIP {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my @stuff;
        my $i = 0;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                @stuff = split /#/, $_;
                if ($stuff[0] ne "" && $stuff[1] ne "") {
                        $$r_hash{$stuff[0]}{'name'} = $stuff[1];
                        if ($stuff[2] ne "" && $stuff[3] ne "") {
                                $$r_hash{$stuff[0]}{'ip'} = $stuff[2];
                                $$r_hash{$stuff[0]}{'port'} = $stuff[3];
                        }
                }
        }
        close FILE;
}

sub mapipModify {
        my $key = shift;
        my $val = shift;
        $mapip_lut{$key}{'ip'} = $val;
        $mapip_lut{$key}{'port'} = 5000;
        writeDataFileIntact3("data/mapip.txt", \%mapip_lut);
}


sub writeDataFileIntact3 {
        my $file = shift;
        my $r_hash = shift;
        my $data;
        my @stuff;
        my $key;
        open FILE, $file;
        foreach (<FILE>) {
                if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
                        $data .= $_;
                        next;
                }
                @stuff = split /#/, $_;
                $key = $stuff[0];
                $data .= "$key#$$r_hash{$key}{'name'}#$$r_hash{$key}{'ip'}#$$r_hash{$key}{'port'}\n";
        }
        close FILE;
        open FILE, "+> $file";
        print FILE $data;
        close FILE;
}

sub sendFly {
        my $ip = shift;
        my $port = shift;
        $sendFlyMap = 1;
        $sendFlyIP = $ip;
        $sendFlyPort = $port;
        if ($sendFlyPort eq "") {
        	if ($config{'master_version_'.$config{'master'}} eq "8") {
			$sendFlyPort = 5000;
		} else {
		        $sendFlyPort = 4500;
		}
        }
        undef @ai_seq;
        undef @ai_seq_args;
	printc(1, "yw", "<系统> ", "正在转移到: $sendFlyIP : $sendFlyPort\n");
        sendQuitToCharSelete(\$remote_socket);
        $conState = 1;
        $timeout{'master'}{'time'} = time;
}

sub parseAidRLUT {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my @stuff;
        my $i = 0;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                @stuff = split /#/, $_;
                if ($stuff[0] eq $config{"master_host_$config{'master'}"}) {
                        $$r_hash{$stuff[1]}{'avoid'} = 1;
                }
        }
        close FILE;
}

sub ai_stateCheck {
        my $r_hash = shift;
        my $list = shift;
        my $match;
        my @array = split /,/, $list;
        foreach (@array) {
                s/^\s+//;
                s/\s+$//;
                s/\s+/ /g;
                next if ($_ eq "");
                $match = $_;
                if ($msgstrings_rlut{'0119_A'}{$match} ne "" && $$r_hash{'param1'} eq $msgstrings_rlut{'0119_A'}{$match}) {
                        return 1;
                } elsif ($msgstrings_rlut{'0119_B'}{$match} ne "" && $msgstrings_rlut{'0119_B'}{$match} & $$r_hash{'param2'}) {
                        return 1;
                } elsif ($msgstrings_rlut{'0119_C'}{$match} ne "" && $msgstrings_rlut{'0119_C'}{$match} & $$r_hash{'param3'}) {
                        return 1;
                } elsif ($$r_hash{'skillsst'}{$msgstrings_rlut{'0196'}{$match}} == 1) {
                        return 1;
                } elsif (@spellsID) {
                        foreach (@spellsID) {
                                next if ($_ eq "");
                                if ($$r_hash{'pos_to'}{'x'} == $spells{$_}{'pos'}{'x'} && $$r_hash{'pos_to'}{'y'} == $spells{$_}{'pos'}{'y'}) {
                                        if ($match eq $spells{$_}{'name'}) {
                                                return 1;
                                        }
                                }
                        }
                }
        }
        return 0;
}

sub ai_checkItemState {
        my $name = shift;
        my $i = 0;
        while ($config{"useSelf_item_$i"} ne "") {
                if (existsInList($config{"useSelf_item_$i"}, $name)) {
                        if (!$config{"useSelf_item_$i"."_noState"} || ($config{"useSelf_item_$i"."_noState"} ne "" && !ai_stateCheck($chars[$config{'char'}], $config{"useSelf_item_$i"."_noState"}))) {
                                return 1;
                        } else {
                                return 0;
                        }
                }
                $i++;
        }
        return 1;
}

sub ai_stateReset {
        my $i = 0;
        while ($config{"useSelf_skill_$i"} ne "" || $config{"useSelf_item_$i"} ne "") {
                undef $ai_v{"useSelf_skill_$i"."_time"};
                undef $ai_v{"useSelf_item_$i"."_time"};
                $i++;
        }
        for ($j = 0; $j < @partyUsersID; $j++) {
                next if ($partyUsersID[$j] eq "");
                $i =0;
                while ($config{"useParty_skill_$i"}) {
                        undef $ai_v{"useParty_skill_$i"."_time"}{$partyUsersID[$j]};
                        $i++;
                }
        }
        undef %{$chars[$config{'char'}]{'skillsst'}};
        $chars[$config{'char'}]{'spirits'} = 0;
        if (!$chars[$config{'char'}]{'exp_start_time'}) {
                $chars[$config{'char'}]{'exp_start'} = $chars[$config{'char'}]{'exp'};
                $chars[$config{'char'}]{'exp_job_start'} = $chars[$config{'char'}]{'exp_job'};
                $chars[$config{'char'}]{'exp_start_time'} = time;
        }
}

sub ai_stateResetParty {
        my $ID = shift;
        $i =0;
        while ($config{"useParty_skill_$i"}) {
                undef $ai_v{"useParty_skill_$i"."_time"}{$ID};
                $i++;
        }
}

sub parseMsgLUT {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my @stuff;
        my $i = 0;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                @stuff = split /#/, $_;
                if ($stuff[0] ne "") {
                        $$r_hash{$stuff[0]}{$stuff[1]} = $stuff[2];
                }
        }
        close FILE;
}

sub parseMsgReverseLUT {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my @stuff;
        my $i = 0;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                @stuff = split /#/, $_;
                if ($stuff[0] ne "") {
                        $$r_hash{$stuff[0]}{$stuff[2]} = $stuff[1];
                }
        }
        close FILE;
}

sub chatLogExp {
        open CHAT, "> $logs_path/exp.txt";
        select (CHAT);
        $chars[$config{'char'}]{'exp_end_time'} = time;
        $w_hour = 0;
        $w_min = 0;
        $n_hour = 0;
        $n_min = 0;
        $n_sec = 0;
        $w_sec = int($chars[$config{'char'}]{'exp_end_time'} - $chars[$config{'char'}]{'exp_start_time'});
        if ($w_sec > 0) {
                $totalBaseExp = $chars[$config{'char'}]{'exp'} - $chars[$config{'char'}]{'exp_start'};
                $totalJobExp = $chars[$config{'char'}]{'exp_job'} - $chars[$config{'char'}]{'exp_job_start'};
                $bExpPerHour = int($totalBaseExp * 3600 / $w_sec);
                $jExpPerHour = int($totalJobExp * 3600 / $w_sec);
                $totalDamage = $chars[$config{'char'}]{'totalDamage'};
                $damagePerSec = int($chars[$config{'char'}]{'totalDamage'} / $w_sec);
        }
        if ($chars[$config{'char'}]{'totalHit'} > 0) {
                $damagePerHit = int($chars[$config{'char'}]{'totalDamage'} / $chars[$config{'char'}]{'totalHit'});
        }
        if ($bExpPerHour > 0) {
                $n_sec = int(($chars[$config{'char'}]{'exp_max'} - $chars[$config{'char'}]{'exp'}) / $bExpPerHour * 3600);
        }
        if ($w_sec >= 3600) {
                $w_hour = int($w_sec / 3600);
                $w_sec %= 3600;
        }
        if ($w_sec >= 60) {
                $w_min = int($w_sec / 60);
                $w_sec %= 60;
        }
        if ($n_sec >= 3600) {
                $n_hour = int($n_sec / 3600);
                $n_sec %= 3600;
        }
        if ($n_sec >= 60) {
                $n_min = int($n_sec / 60);
                $n_sec %= 60;
        }
        $attack_string = (int($exp{'base'}{'attackTime'}/($chars[$config{'char'}]{'exp_end_time'} - $chars[$config{'char'}]{'exp_start_time'})*10000)/100)."%";
        $sit_string = (int($exp{'base'}{'sitTime'}/($chars[$config{'char'}]{'exp_end_time'} - $chars[$config{'char'}]{'exp_start_time'})*10000)/100)."%";
        $playTime_string = $w_hour."小时 ".$w_min."分 ".$w_sec."秒";
        $levelTime_string = $n_hour."小时 ".$n_min."分 ".$n_sec."秒";
        $exp{'base'}{'back'} = 0 if ($exp{'base'}{'back'} eq "");
        $exp{'base'}{'dead'} = 0 if ($exp{'base'}{'dead'} eq "");
        $exp{'base'}{'disconnect'} = 0 if ($exp{'base'}{'disconnect'} eq "");
        $totalBaseExp_string = $totalBaseExp." (".(int($totalBaseExp/$chars[$config{'char'}]{'exp_max'}*10000)/100)."%)";
        $totalJobExp_string = $totalJobExp." (".(int($totalJobExp/$chars[$config{'char'}]{'exp_job_max'}*10000)/100)."%)";
        $bExpPerHour_string = $bExpPerHour." (".(int($bExpPerHour/$chars[$config{'char'}]{'exp_max'}*10000)/100)."%)";
        $jExpPerHour_string = $jExpPerHour." (".(int($jExpPerHour/$chars[$config{'char'}]{'exp_job_max'}*10000)/100)."%)";
        print CHAT "战斗记录时间: [".getFormattedDate(int(time))."]\n\n";
        print CHAT "-------------------------------------------------------------------------\n";
        print CHAT "在线时间           升级需要              战斗时间 休息时间 回城 死亡 掉线\n";
        $~ = "EXPBLISTLOGA";
        format EXPBLISTLOGA =
@<<<<<<<<<<<<<<<<  @<<<<<<<<<<<<<<<<<    @>>>>>>> @>>>>>>> @>>> @>>> @>>>
$playTime_string $levelTime_string $attack_string $sit_string $exp{'base'}{'back'} $exp{'base'}{'dead'} $exp{'base'}{'disconnect'}
.
        write;
        print CHAT "-------------------------------------------------------------------------\n";
        print CHAT "共获得BASE经验     共获得JOB经验         每小时BASE经验     每小时JOB经验\n";
        $~ = "EXPBLISTLOGB";
        format EXPBLISTLOGB =
@<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<< @>>>>>>>>>>>>>>>>  @>>>>>>>>>>>>>>>
$totalBaseExp_string $totalJobExp_string $bExpPerHour_string $jExpPerHour_string
.
        write;
        print CHAT "-------------------------------------------------------------------------\n";
        print CHAT "消灭怪物           数量  平均时间  BASE效率   JOB效率  每秒伤害  每秒损失\n";
        $~ = "EXPMLISTLOG";
        foreach (keys %{$exp{'monster'}}) {
                next if ($exp{'monster'}{$_}{'kill'} <= 0 || $monsters_lut{$_} eq "");
                $exp{'monster'}{$_}{'avg_time'} =  int($exp{'monster'}{$_}{'time'} / $exp{'monster'}{$_}{'kill'} * 100) / 100;
                $exp{'monster'}{$_}{'avg_baseExp'} = int($exp{'monster'}{$_}{'baseExp'} / $exp{'monster'}{$_}{'time'} * 100) / 100;
                $exp{'monster'}{$_}{'avg_jobExp'} = int($exp{'monster'}{$_}{'jobExp'} / $exp{'monster'}{$_}{'time'} * 100) / 100;
                $exp{'monster'}{$_}{'avg_dmgTo'} = int($exp{'monster'}{$_}{'dmgTo'} / $exp{'monster'}{$_}{'time'} * 100) / 100;
                $exp{'monster'}{$_}{'avg_dmgFrom'} = int($exp{'monster'}{$_}{'dmgFrom'} / $exp{'monster'}{$_}{'time'} * 100) / 100;
                format EXPMLISTLOG =
@<<<<<<<<<<<<<<<<< @>>>  @>>>>>>>  @>>>>>>>  @>>>>>>>  @>>>>>>>  @>>>>>>>
$monsters_lut{$_} $exp{'monster'}{$_}{'kill'} $exp{'monster'}{$_}{'avg_time'} $exp{'monster'}{$_}{'avg_baseExp'} $exp{'monster'}{$_}{'avg_jobExp'} $exp{'monster'}{$_}{'avg_dmgTo'} $exp{'monster'}{$_}{'avg_dmgFrom'}
.
                write;
        }
        print CHAT "-------------------------------------------------------------------------\n";
        print CHAT "使用物品           数量                   获得物品           数量    重要\n";
        undef @exp_pick;
        undef @exp_used;
        $~ = "EXPILISTLOG";
        foreach (keys %{$exp{'item'}}) {
                next if ($exp{'item'}{$_}{'pick'} <= 0 );
                push @exp_pick, $_;
        }
        foreach (keys %{$exp{'item'}}) {
                next if ($exp{'item'}{$_}{'used'} <= 0 );
                push @exp_used, $_;
        }
        $i = 0;
        while ($exp_pick[$i] ne "" || $exp_used[$i] ne "") {
                undef $pick_string;
                undef $pick_amount;
                undef $used_string;
                undef $used_amount;
                undef $flag_string;
                if ($exp_pick[$i] > 0) {
                        $pick_string = $items_lut{$exp_pick[$i]};
                        $pick_amount = $exp{'item'}{$exp_pick[$i]}{'pick'};
                        if ($itemsPickup{lc($pick_string)} >= 2) {
                                $flag_string = "Y";
                        }
                }
                if ($exp_used[$i] > 0) {
                        $used_string = $items_lut{$exp_used[$i]};
                        $used_amount = $exp{'item'}{$exp_used[$i]}{'used'};
                }
                format EXPILISTLOG =
@<<<<<<<<<<<<<<<<< @>>>                   @<<<<<<<<<<<<<<<<< @>>>    @>>>
$used_string       $used_amount           $pick_string       $pick_amount $flag_string
.
                write;
                $i++;
        }
        print CHAT "-------------------------------------------------------------------------\n";
        close CHAT;
        select (STDOUT);
}

sub ai_getRoundSkillID {
        my $distance = shift;
        my $foundMax;
        my $foundID;
        foreach (@monstersID) {
                next if ($_ eq "" || distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}}) > $distance);
                $monsters{$_}{'roundMonsters'} = ai_getRoundMonstersByMonster($_, $distance);
                if ($monsters{$_}{'roundMonsters'} >= $foundMax) {
                        $foundMax = $monsters{$_}{'roundMonsters'};
                        $foundID = $_;
                }
        }
        return $foundID;
}

sub ai_getRoundMonstersByMonster {
        my $ID = shift;
        my $distance = shift;
        my $count;
        foreach (@monstersID) {
                next if ($_ eq "" || distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}}) > $distance);
                if (distance(\%{$monsters{$ID}{'pos_to'}}, \%{$monsters{$_}{'pos_to'}}) <= 1) {
                        $count++;
                }
        }
        return $count;
}

sub writeMvptimeFileIntact {
        my $file = shift;
        my $r_hash = shift;
        my $data;
        my $key;
        my $value;
        open FILE, $file;
        foreach (<FILE>) {
                if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
                        $data .= $_;
                        next;
                }
                ($key, $value) = $_ =~ /([\s\S]*) ([\s\S]*?)$/;
                $data .= "$key $$r_hash{$key}\n";
        }
        close FILE;
        open FILE, "+> $file";
        print FILE $data;
        close FILE;
}

sub avoidAID {
        my $ID = shift;
        my $sleeptime;
        my $AID = unpack("L1", $ID);
        my $display;
        my $pos;
        ($map_string) = $map_name =~ /([\s\S]*)\.gat/;
        $pos = "$map_string($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})";
        $config{'avoidGM_reconnect'} = 60 if ($config{'avoidGM_reconnect'} < 60);
        if (%{$players{$ID}}) {
                $display = "$players{$ID}{'name'}($AID) ($players{$ID}{'pos_to'}{'x'},$players{$ID}{'pos_to'}{'y'})";
        } else {
                $display = "Unknown($AID) (未知位置)";
        }
        if (!$indoors_lut{$map_string.'.rsw'} && $chars[$config{'char'}]{'avoid'} <= 8) {
                if ($chars[$config{'char'}]{'shopOpened'}) {
                        $sleeptime = int($config{'avoidGM_reconnect'} + rand(60));
                        printc("yr", "<系统> ", "躲避 $display，直接断线$sleeptime秒。位置: $pos\n");
                        chatLog("gm", "躲避 $display，直接断线$sleeptime秒。位置: $pos\n");
        	        $conState = 1;
	                undef $conState_tries;
                	$timeout_ex{'master'}{'time'} = time;
        	        $timeout_ex{'master'}{'timeout'} = $sleeptime;
	                killConnection(\$remote_socket) if (!$xKore);
                } elsif (!$config{'avoidGM'}) {
                        printc("yr", "<系统> ", "躲避 $display，瞬移。位置: $pos\n");
                        chatLog("gm", "躲避 $display，瞬移。位置: $pos\n");
                        $chars[$config{'char'}]{'avoid'}++;
                        useTeleport(1);
                } elsif ($config{'avoidGM'} == 1) {
                        $sleeptime = int($config{'avoidGM_reconnect'} + rand(60));
                      	if ($config{'mvpMode'} >= 2 && $mvp{'now_monster'}{'name'} ne "" && $mvp{'now_monster'}{'end_time'} > time && $sleeptime > $mvp{'now_monster'}{'end_time'} - time) {
                       		$sleeptime = int($mvp{'now_monster'}{'end_time'} - time);
                       	}
                        printc("yr", "<系统> ", "躲避 $display，瞬移断线$sleeptime秒。位置: $pos\n");
                        chatLog("gm", "躲避 $display，瞬移断线$sleeptime秒。位置: $pos\n");
                        useTeleport(1);
                        sleep(2);
        	        $conState = 1;
	                undef $conState_tries;
                	$timeout_ex{'master'}{'time'} = time;
        	        $timeout_ex{'master'}{'timeout'} = $sleeptime;
	                killConnection(\$remote_socket) if (!$xKore);
                } else {
                        $sleeptime = int($config{'avoidGM_reconnect'} + rand(60));
                        printc("yr", "<系统> ", "躲避 $display，直接断线$sleeptime秒。位置: $pos\n");
                        chatLog("gm", "躲避 $display，直接断线$sleeptime秒。位置: $pos\n");
        	        $conState = 1;
	                undef $conState_tries;
                	$timeout_ex{'master'}{'time'} = time;
        	        $timeout_ex{'master'}{'timeout'} = $sleeptime;
	                killConnection(\$remote_socket) if (!$xKore);
                }
        } else {
                $sleeptime = int($config{'avoidGM_reconnect'} + rand(1800) + 1800);
                printc("yr", "<系统> ", "躲避 $display，断线$sleeptime秒。位置: $pos\n");
                chatLog("gm", "躲避 $display，断线$sleeptime秒。位置: $pos\n");
       	        $conState = 1;
                undef $conState_tries;
               	$timeout_ex{'master'}{'time'} = time;
       	        $timeout_ex{'master'}{'timeout'} = $sleeptime;
                killConnection(\$remote_socket) if (!$xKore);
        }
}

sub printc {
        my $printType = shift;
        my $colors;
        if ($printType eq "1") {
        	$colors = shift;
        } else {
        	$colors = $printType;
        }
        my $length = length($colors);
        my $type;
        my $msg;
        my @msgs;
        my $sendMsg;

        for (my $i=0; $i < $length; $i++) {
        	$type = substr($colors, $i, 1);
                $msg = shift;
                if (!$noColor) {
                        if ($type eq "k") {
                                $CONSOLE->Attr($FG_BLACK|$BG_BLACK);
                        } elsif ($type eq "B") {
                                $CONSOLE->Attr($FG_BLUE|$BG_BLACK);
                        } elsif ($type eq "b") {
                                $CONSOLE->Attr($FG_LIGHTBLUE|$BG_BLACK);
                        } elsif ($type eq "R") {
                                $CONSOLE->Attr($FG_RED|$BG_BLACK);
                        } elsif ($type eq "r") {
                                $CONSOLE->Attr($FG_LIGHTRED|$BG_BLACK);
                        } elsif ($type eq "G") {
                                $CONSOLE->Attr($FG_GREEN|$BG_BLACK);
                        } elsif ($type eq "g") {
                                $CONSOLE->Attr($FG_LIGHTGREEN|$BG_BLACK);
                        } elsif ($type eq "M") {
                                $CONSOLE->Attr($FG_MAGENTA|$BG_BLACK);
                        } elsif ($type eq "m") {
                                $CONSOLE->Attr($FG_LIGHTMAGENTA|$BG_BLACK);
                        } elsif ($type eq "C") {
                                $CONSOLE->Attr($FG_CYAN|$BG_BLACK);
                        } elsif ($type eq "c") {
                                $CONSOLE->Attr($FG_LIGHTCYAN|$BG_BLACK);
                        } elsif ($type eq "y") {
                                $CONSOLE->Attr($FG_YELLOW|$BG_BLACK);
                        } elsif ($type eq "w") {
                                $CONSOLE->Attr($FG_WHITE|$BG_BLACK);
                        } else {
                                $CONSOLE->Attr($ATTR_NORMAL);
                        }
                        $CONSOLE->Write("$msg") if ($msg ne "");
                } else {
                        print "$msg";
                }
                if (($xKore && $printType eq "1") || $yelloweasy) {
               		@msgs = split /\\n/,$msg;
	                $sendMsg .= $msgs[0];
		}
        }
        $CONSOLE->Attr($ATTR_NORMAL) if (!$noColor);
        if ($xKore && $printType eq "1") {
	        injectMessage($sendMsg) if ($config{'verbose'});
	} elsif ($yelloweasy) {
	        sendMsgToWindow("AA00".chr(1).$sendMsg);
	}
}

sub modifingName {
        my $r_hash = shift;
        my $modified = "";
        my @card;
        my $prefix="";
        my $postfix="";
        my ($i, $j, $k);

        if (!$$r_hash{'type_equip'} && (!$$r_hash{'attribute'} && !$$r_hash{'refined'} && !$$r_hash{'card'}[0] && !$$r_hash{'star'})) {
                return 0;
        } elsif ($$r_hash{'type_equip'} == 1024) {
        	if ($$r_hash{'named'}) {
                        $modified .="被爱的 ";
                }
                $$r_hash{'name'} = $modified.$$r_hash{'name'};
        } else {
                $modified = "+$$r_hash{'refined'} " if ($$r_hash{'refined'});
                if ($$r_hash{'star'}==1){
                        $modified .="一级强悍 ";
                }elsif ($$r_hash{'star'}==2){
                        $modified .="二级强悍 ";
                }elsif ($$r_hash{'star'}==3){
                        $modified .="三级强悍 ";
                }
                $modified .= $elements_lut{$$r_hash{'attribute'}}." " if ($$r_hash{'attribute'});

                for ($i = 0; $i < 4; $i++) {
                        last if !$$r_hash{'card'}[$i];
                        if (@card) {
                                for ($j = 0; $j <= @card; $j++) {
                                        if ($card[$j]{'ID'} eq $$r_hash{'card'}[$i]) {
                                                $card[$j]{'amount'}++;
                                                last;
                                        } elsif ($card[$j]{'ID'} eq "") {
                                                $card[$j]{'ID'} = $$r_hash{'card'}[$i];
                                                $card[$j]{'amount'} = 1;
                                                last;
                                        }
                                }
                        } else {
                                $card[0]{'ID'} = $$r_hash{'card'}[$i];
                                $card[0]{'amount'} = 1;
                        }
                }
                if (@card) {
                        for ($i = 0; $i < @card; $i++) {
                                if ($card[$i]{'amount'} == 1) {
                                        $prefix .= "$cards_lut{$card[$i]{'ID'}} ";
                                } elsif ($card[$i]{'amount'} == 2) {
                                        $prefix .= "两倍卡片 $cards_lut{$card[$i]{'ID'}} ";
                                } elsif ($card[$i]{'amount'} == 3) {
                                        $prefix .= "三倍卡片 $cards_lut{$card[$i]{'ID'}} ";
                                } elsif ($card[$i]{'amount'} == 4) {
                                        $prefix .= "四倍卡片 $cards_lut{$card[$i]{'ID'}} ";
                                }
                        }
                }
                $$r_hash{'name'} = $modified.$prefix.$$r_hash{'name'};
        }
}

sub sendNotice {
	my $msg = shift;
	if ($config{'XKore_noticeType'} == 1 && %{$chars[$config{'char'}]{'party'}}) {
		sendMessage(\$remote_socket, "p", $msg);
	} elsif ($config{'XKore_noticeType'} == 2 && %{$chars[$config{'char'}]{'guild'}}) {
		sendMessage(\$remote_socket, "g", $msg);
	} else {
		sendMessage(\$remote_socket, "k", $msg);
        }
}

sub ai_refine {
        my $name = shift;
        my $refined = shift;
        my %args;
        dynParseFiles("$setup_path/refine_control.txt", \%refine_control, \&parseDataFile2);
        $args{'name'} = $name;
        $args{'refined'} = $refined;
        unshift @ai_seq, "refineAuto";
        unshift @ai_seq_args, \%args;
}

sub ai_warp {
        my $map = shift;
        my %args;
        $args{'map'} = $map;
        unshift @ai_seq, "warp";
        unshift @ai_seq_args, \%args;
}
                
sub getRandomCoords {
        my $r_hash1 = shift;
        my $r_hash2 = shift;
        my $dist = shift;
        do {
                $$r_hash1{'x'} = $$r_hash2{'x'} + int(rand() * ($dist + 1) - $dist / 2);
                $$r_hash1{'y'} = $$r_hash2{'y'} + int(rand() * ($dist + 1) - $dist / 2);
        } while (unpack("C", substr($field{'field'}{'rawMap'}, $$r_hash1{'y'} * $field{'field'}{'width'} + $$r_hash1{'x'}, 1)));
}

sub printItemList {
        my $r_array = shift;
        my $arg1 = shift;
        my @non_useable;
        my @useable;
        my @equipment;
        my $index;
        my $flag;
        my $display;
        my $conut;
        for (my $i = 0; $i < @{$r_array};$i++) {
        	next if (!%{$$r_array[$i]});
        	$conut++;
        	if ($$r_array[$i]{'type'} == 3 ||$$r_array[$i]{'type'} == 6 || $$r_array[$i]{'type'} == 10) {
                	push @non_useable, $i;
                } elsif ($$r_array[$i]{'type'} <= 2) {
                	push @useable, $i;
                } else {
                	push @equipment, $i;
                }
	}
	if ($r_array eq \@{$chars[$config{'char'}]{'inventory'}}) {
		$chars[$config{'char'}]{'items'} = $conut;
		$chars[$config{'char'}]{'items_max'} = 100;
	}
        if ($arg1 eq "" || $arg1 eq "eq") {
        	printc("ncn", "----", "装备", "----\n");
        	for (my $i = 0; $i < @equipment; $i++) {
                        $index = $equipment[$i];
                	$flag = ($itemsPickup{lc($items_lut{$$r_array[$index]{'nameID'}})} >= 2) ? "*" : " ";
                	$display = $$r_array[$equipment[$i]]{'name'};
                        if ($$r_array[$equipment[$i]]{'equipped'}) {
                        	$display .= " -- $equipTypes_lut{$$r_array[$equipment[$i]]{'equipped'}}";
                        }
                        if (!$$r_array[$equipment[$i]]{'identified'}) {
                        	$display .= " (未鉴定)";
                        }
                        if ($$r_array[$equipment[$i]]{'broken'}) {
                        	$display .= " (已损坏)";
                        }
                        print sprintf("%-3d %-2s %-60s\n",$index,$flag,$display);
		}
	}
        if ($arg1 eq "" || $arg1 eq "u") {
        	printc("ngn", "---", "可使用", "---\n");
                for (my $i = 0; $i < @useable; $i++) {
                        $index = @useable[$i];
                	$flag = ($itemsPickup{lc($items_lut{$$r_array[$index]{'nameID'}})} >= 2) ? "*" : " ";
                        $display = $$r_array[$useable[$i]]{'name'};
                        $display .= " x $$r_array[$useable[$i]]{'amount'}";
                        print sprintf("%-3d %-2s %-60s\n",$index,$flag,$display);
                }
        }
	if ($arg1 eq "" || $arg1 eq "nu") {
		printc("nwn", "--", "不可使用", "--\n");
		for (my $i = 0; $i < @non_useable; $i++) {
			$index = $non_useable[$i];
                	$flag = ($itemsPickup{lc($items_lut{$$r_array[$index]{'nameID'}})} >= 2) ? "*" : " ";			
			$display = $$r_array[$non_useable[$i]]{'name'};
			$display .= " x $$r_array[$non_useable[$i]]{'amount'}";
			if ($$r_array[$non_useable[$i]]{'equipped'}) {
				$display .= " -- 箭矢";
			}
                        print sprintf("%-3d %-2s %-60s\n",$index,$flag,$display);
		}
	}
}

sub setStatus {
   	my $ID = shift;
	my $agr1 = shift;
	my $agr2 = shift;
	my $agr3 = shift;
	my $r_hash;
	my $type;
	my @stuff;
        if ($ID eq $accountID) {
        	$r_hash = \%{$chars[$config{'char'}]};
        	$type = 1;
        } elsif (%{$players{$ID}}) {
        	$r_hash = \%{$players{$ID}};
        	$type = 3;
	} elsif (%{$monsters{$ID}}) {
        	$r_hash = \%{$monsters{$ID}};
        	$type = 4;
        } else {
        	return;
        }
	$$r_hash{'param1_old'} = $$r_hash{'param1'};
	$$r_hash{'param2_old'} = $$r_hash{'param2'};
	$$r_hash{'param3_old'} = $$r_hash{'param3'};
	$$r_hash{'param1'} = $agr1;
	$$r_hash{'param2'} = $agr2;
	$$r_hash{'param3'} = $agr3;
        if (($config{'mode'} >= $type) && (($$r_hash{'param1'} != $$r_hash{'param1_old'}) || ($$r_hash{'param2'} != $$r_hash{'param2_old'}) || ($config{'mode'} >= 2 && ($$r_hash{'param3'} != $$r_hash{'param3_old'})))) {
               	getFormattedStatus(\@stuff, $r_hash);
		if (@stuff > 0) {
			if ($type <= 2) {
				printc("w", "<状态> ");
			} elsif ($type == 3) {
				printc("nn", "<玩家> ", "$$r_hash{'name'}($$r_hash{'binID'}) ");
			} elsif ($type == 4) {
				printc("nn", "<怪物> ", "$$r_hash{'name'}($$r_hash{'binID'}) ");
			}
			for (my $i = 0; $i < @stuff; $i+=2) {
 				if ($type <= 2) {
	 				printc($stuff[$i], $stuff[$i+1]." ");
 				} else {
 					printc("n", $stuff[$i+1]." ");
 				}
	 		}
	 		print "\n";
	 	}
 	}
}

sub parseRODescLUT2 {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $ID;
        my $value;
        open FILE, $file;
        foreach (<FILE>) {
                s/\r//g;
                if (/^#/) {
                        $$r_hash{$ID} = $value if ($value ne "");
                        undef $ID;
                        undef $value;
                } elsif (!$ID) {
                        ($ID) = /([\s\S]+)#/;
                } else {
                	($value) = $_ =~ /重量 : \^[0-9a-fA-F]{6}([\s\S]*?)\^[0-9a-fA-F]{6}/ if ($value eq "");
                }
        }
        close FILE;
}

sub logItem {
	my $flie = shift;
	my $r_hash = shift;
	my $title = shift;
	$noColor = 1;
        open FILE, "> $flie";
        select (FILE);
        print "记录时间: [".getFormattedDate(int(time))."]\n\n";
        print "-----------$title-----------\n";                	
        printItemList(\@{$$r_hash{'inventory'}}, "");
        print "------------------------------\n";
        if ($$r_hash{'items_max'} > 0) {
	        print "数量: $$r_hash{'items'}/$$r_hash{'items_max'}\n";
	        print "------------------------------\n";
	}
        if ($$r_hash{'weight_max'} > 0) {
        	print "负重: " . int($$r_hash{'weight'}) . "/" . int($$r_hash{'weight_max'}) . "\n";
	        print "------------------------------\n";
        }
        close (FILE);
        $noColor = 0;
        select(STDOUT);
        printc("yw", "<系统> ", "$title已记录到 $flie\n");
}

sub parseRODescLUT3 {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $ID;
        my $IDdesc;
        my @stuff;
        open FILE, $file;
        foreach (<FILE>) {
                s/\r//g;
                if (/^#/) {
                        $$r_hash{$ID}{'desc'} = $IDdesc if ($ID ne "");
                        undef $ID;
                        undef $IDdesc;
                } elsif (!$ID) {
	                @stuff = split /#/, $_;
        	        $stuff[1] =~ s/_/ /g;
                	if ($stuff[0] ne "" && $stuff[1] ne "") {
                		$ID = $stuff[0];
                        	$$r_hash{$ID}{'name'} = $stuff[1];
	                }
                } else {
                        $IDdesc .= $_;
                }
        }
        close FILE;
}

sub dynParseFiles {
        my $file = shift;
        my $hash = shift;
        my $function = shift;
        if (!(-e $file)) {
        	printc("yr", "<系统> ", "无法加载 $file\n");
        }     	
        &$function("$file", $hash);        
}

sub printStatus {
	my $type = shift;
	my $max = shift;
	my $r_hash = shift;
	my @color;
	my @stuff;
        my $count;
        $count = 0;
        if ($$r_hash{'spirits'} > 0) {
                printc("g", sprintf($type, "气弹$$r_hash{'spirits'}个"));
        	$count++;
        }
        if ($count >= $max) {
        	print "\n";
        	$count = 0;
        }
        if ($$r_hash{'dead'}) {
        	printc("g", sprintf($type, "死亡"));
        	$count++;
        } elsif ($$r_hash{'sitting'}) {
        	printc("g", sprintf($type, "坐下"));
        	$count++;
        }
        if ($count >= $max) {
        	print "\n";
        	$count = 0;
        }
        foreach (keys %{$$r_hash{'skillsst'}}) {
        	if ($$r_hash{'skillsst'}{$_} == 1) {
                	printc("c", sprintf($type,$msgstrings_lut{'0196'}{$_}));
                        $count++;
	        	if ($count >= $max) {
        			print "\n";
		        	$count = 0;
        		}
                }
        }
        if ($count) {
        	print "\n";
        	$count = 0;
        }
        getFormattedStatus(\@stuff, $r_hash);
        for (my $i=0; $i < @stuff; $i+=2) {
        	printc($stuff[$i], sprintf($type,$stuff[$i+1]));
                $count++;
	       	if ($count >= $max) {
        		print "\n";
	        	$count = 0;
        	}
	}
        print "\n" if ($count);
}


sub getFormattedStatus {
	my $r_array = shift;
	my $r_hash = shift;
	if ($$r_hash{'param1'} > 0) {
		push @{$r_array}, "r";
                push @{$r_array}, "$msgstrings_lut{'0119_A'}{$$r_hash{'param1'}}";
	}
	if ($$r_hash{'param2'} > 0) {		
		foreach (keys %{$msgstrings_lut{'0119_B'}}) {
			if ($_ & $$r_hash{'param2'}) {
				push @{$r_array}, "m";
		                push @{$r_array}, "$msgstrings_lut{'0119_B'}{$_}";
			}
		}
	}
	if (!$$r_hash{'param1'} && !$$r_hash{'param2'}) {
		push @{$r_array}, "w";
                push @{$r_array}, "正常状态";
	}
	if (($$r_hash{'param3'} > 0)) {
		foreach (keys %{$msgstrings_lut{'0119_C'}}) {
			if ($_ & $$r_hash{'param3'}) {
				push @{$r_array}, "n";
                                push @{$r_array}, "$msgstrings_lut{'0119_C'}{$_}";
			}
		}
	}
}

sub getFormattedNumber {
	my $amount = shift;
	my $length;
	my $count;
	my $temp;
	my @array;
	my $i;
	
	return 0 if (!$amount);
	$amount = reverse $amount;
	$length = length($amount);

	$count = 0;
	for ($i = 0; $i < $length; $i++) {
		$temp .= substr($amount, $i, 1);
		$count++;
		if ($count == 3) {
			push @array, $temp;
			$count = 0;
			undef $temp;
		}
	}
	push @array, $temp if ($temp ne "");
	return reverse join(",", @array);
}

sub getFormattedTime {
        my $thetime = shift;
        my $r_time = shift;
        my @localtime = localtime $thetime;
        $localtime[2] = "0" . $localtime[2] if ($localtime[2] < 10);
        $localtime[1] = "0" . $localtime[1] if ($localtime[1] < 10);
        $localtime[0] = "0" . $localtime[0] if ($localtime[0] < 10);
        $localtime[0] = "00" if ($localtime[0] eq "0");
        $localtime[1] = "00" if ($localtime[1] eq "0");
        $localtime[2] = "00" if ($localtime[2] eq "0");
        $localtime[2] = "00" if ($thetime < 86400);
        $$r_time = "$localtime[2]:$localtime[1]:$localtime[0]";
        return $$r_time;
}
	
sub r_getFormattedTime {
        my $thetime = shift;
        my $r_time = shift;
        my @stuff;
        @stuff = split /:/, $thetime;
        my @localtime = localtime $thetime;
        $r_time = time - ($localtime[2] - $stuff[0]) * 3600 - ($localtime[1] - $stuff[1]) * 60 - ($localtime[0] - $stuff[2]);
        $r_time -= 86400 if ($stuff[0] > $localtime[2]);
        return $$r_time;
}

sub findIndexStringsNotSelected_lc {
	my $r_array = shift;
        my $match = shift;
        my $ID = shift;	
        return if ($ID eq "");
        my $r_array2 = shift;
        my @stuff = split /,/, $ID;
        my $found;
        my $i;
        for ($i = 0; $i < @{$r_array}; $i++) {
        	next if (!%{$$r_array[$i]} || !$$r_array[$i]{'identified'} || $$r_array[$i]{'broken'} || (!$$r_array[$i]{'type_equip'} && $$r_array[$i]{'type'} != 10));
        	if ($stuff[0] eq $ID && lc($$r_array[$i]{$match}) eq lc($stuff[0])) {
        		return $i if ($r_array2 eq "" || binFind(\@{$r_array2}, $i) eq "");
        	} elsif ($stuff[0] ne $ID) {
       			undef $found;
	                foreach (@stuff) {
        	                s/^\s+//;
                	        s/\s+$//;
                        	s/\s+/ /g;
	                        next if ($_ eq "" || (lc($$r_array[$i]{$match}) =~ /\Q$_\E/i));
	                        $found = 1;
	                        last;
        		}
       			return $i if (!$found && ($r_array2 eq "" || binFind(\@{$r_array2}, $i) eq ""));
                }
        }
}

sub ai_getSkillUseID {
	my $name = shift;
	if (%{$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($name)}}} && $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($name)}}{'ID'} ne "") {
		return $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($name)}}{'ID'};
	} else {
		foreach (keys %skillsID_lut) {
			if ($skillsID_lut{$_} eq $name) {
				return $_;
			}
		}
	}
}

sub ai_autoSwitch {
	return if (!$config{'autoSwitch'});
	my $type = shift;
	my $ID = shift;
	my $i = 1;
	my $foundID;
	while (1) {
		last if (!$config{"autoSwitch_$i"."_equip_0"});
 		if ($type eq "skill_use" && existsInList($config{"autoSwitch_$i"."_useSkills"}, $skillsID_lut{$ID})) {
			$foundID = $i;
			last;
		} elsif ($type eq "attack" && (existsInList($config{"autoSwitch_$i"."_mon"}, $monsters{$ID}{'name'})
	        	|| ($config{"autoSwitch_$i"."_hp_lower"} && percent_hp(\%{$chars[$config{'char'}]}) < $config{"autoSwitch_$i"."_hp_lower"})
        	       	|| ($config{"autoSwitch_$i"."_sp_lower"} && percent_sp(\%{$chars[$config{'char'}]}) < $config{"autoSwitch_$i"."_sp_lower"})
	        	|| ($config{"autoSwitch_$i"."_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{"autoSwitch_$i"."_hp_upper"})
        	       	|| ($config{"autoSwitch_$i"."_sp_upper"} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{"autoSwitch_$i"."_sp_upper"}))) {
       			$foundID = $i;
	        	last;
	        } elsif ($type eq "sitAuto" && $config{"autoSwitch_$i"."_whenSit"}) {
	        	$foundID = $i;
	        	last;
	        }
		$i++;
	}
	$foundID = 0 if ($type eq "attack" && $foundID eq "");
	if ($foundID ne "" && ($chars[$config{'char'}]{'autoSwitch'} ne $foundID || ($chars[$config{'char'}]{'autoSwitch'} eq $foundID && timeOut(3, $timeout{'ai_equip_auto_giveup'}{'time'})))) {
		my %args;
		$args{'index'} = $foundID;
		$chars[$config{'char'}]{'autoSwitch'} = $foundID;
        	unshift @ai_seq, "equipAuto";
       		unshift @ai_seq_args, \%args;
	}
}	

sub ai_changedByMonster {
	my $type = shift;
	my $ID = shift;
	if ($type eq "dead" || $type eq "teleported" || $type eq "failed" || $type eq "stolen") {
		if ($ai_seq[0] eq "skill_use" && $ID eq $ai_seq_args[0]{'skill_use_target'}) {
			aiRemove("skill_use");
			undef $chars[$config{'char'}]{'time_cast'};
		}
		if ($ai_seq[0] eq "route" && $ai_seq[1] eq "attack" && $ID eq $ai_seq_args[1]{'ID'}) {
                       	binRemoveAndShiftByIndex(\@ai_seq, 0);
              		binRemoveAndShiftByIndex(\@ai_seq_args, 0);
		} elsif ($ai_seq[0] eq "move" && $ai_seq[1] eq "route" && $ai_seq[2] eq "attack" && $ID eq $ai_seq_args[2]{'ID'}) {
                       	binRemoveAndShiftByIndex(\@ai_seq, 1);
              		binRemoveAndShiftByIndex(\@ai_seq_args, 1);
		}
	} elsif ($type eq "disappeared") {
		if ($ai_seq[0] eq "skill_use" && $ID eq $ai_seq_args[0]{'skill_use_target'}) {
			aiRemove("skill_use");
			undef $chars[$config{'char'}]{'time_cast'};
		}
	}
}
	
1;
