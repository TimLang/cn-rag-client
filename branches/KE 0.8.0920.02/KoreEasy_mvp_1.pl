#########################################################################
# KoreEasy MVP Module
#########################################################################


sub mvpMonsterFound {
	my $ID = shift;
	if (($config{'lockMap'} ne "" && $field{'name'} ne "" && $config{'lockMap'} ne $field{'name'}) || $monsterTypes_lut{lc($monsters{$ID}{'name'})} < 2 || $monsters{$ID}{'mvp'} || !$mon_control{lc($monsters{$ID}{'name'})}{'attack_auto'}) {
		return;
	}
	chatLog("m", "发现: $monsters{$ID}{'name'} $field{'name'} ($monsters{$ID}{'pos_to'}{'x'},$monsters{$ID}{'pos_to'}{'y'})\n") if (!$monsters{$ID}{'mvp'});
        $monsters{$ID}{'mvp'} = 1;
        if ($config{'mvpMode'} && !$chars[$config{'char'}]{'mvp'}) {
           	ai_changeToMvpMode(1);
               	attack($ID) if ($config{'attackMvpFirst'});
                mvpNoticeSent("appeared", $monsters{$ID}{'name'}, $field{'name'}, $monsters{$ID}{'pos_to'}{'x'}, $monsters{$ID}{'pos_to'}{'y'});
        }
}                               

sub mvpTimeLog {
	return if (!$vipLevel);	
	my $ID = shift;
        if ($monsters{$ID}{'name'} eq $mvp{'now_monster'}{'name'} && $field{'name'} eq $mvp{'now_monster'}{'map'}) {
                $mvptime{$monsters{$ID}{'name'}} = int(time);
                writeMvptimeFileIntact("$logs_path/mvptime.txt", \%mvptime);
                undef $mvp{'now_monster'}{'name'};
        }
}

sub mvpMapChange {
	return if (!$vipLevel);
        if (binFind(\@ai_seq, "items_important") eq "" && ($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "sitAuto") && $config{'mvpMode'} >= 2 && $vipLevel >= 2 && !$chars[$config{'char'}]{'mvp'} && $config{"mvpMonster_0"} ne "") {
                if ($mvp{'now_monster'}{'name'} ne "" && time > $mvp{'now_monster'}{'end_time'}) {
                        undef $mvp{'now_monster'}{'index'};
                        undef $mvp{'now_monster'}{'name'};
                        undef $mvp{'now_monster'}{'map'};
		        undef $config{'lockMap_x'};
        		undef $config{'lockMap_y'};
                }
                if ($mvp{'now_monster'}{'name'} eq "") {
                        undef $config{'lockMap_x'};
                        undef $config{'lockMap_y'};
                        my $i = 0;
                        while ($config{"mvpMonster_$i"} ne "") {
                                if (time - $mvptime{$config{"mvpMonster_$i"}} < $config{"mvpRenewTime_$i"}) {
                                        $mvp{$config{"mvpMonster_$i"}}{'type'} = 1;
                                        $mvp{$config{"mvpMonster_$i"}}{'start_time'} = $mvptime{$config{"mvpMonster_$i"}} + $config{"mvpRenewTime_$i"} - $config{"mvpStartTime_$i"};
                                        $mvp{$config{"mvpMonster_$i"}}{'end_time'} = $mvp{$config{"mvpMonster_$i"}}{'start_time'} + $config{"mvpStartTime_$i"} + $config{"mvpEndTime_$i"};
                                } elsif (time - $mvptime{$config{"mvpMonster_$i"}} < $config{"mvpRenewTime_$i"} * 2) {
                                        $mvp{$config{"mvpMonster_$i"}}{'type'} = 2;
                                        $mvp{$config{"mvpMonster_$i"}}{'start_time'} = $mvptime{$config{"mvpMonster_$i"}} + $config{"mvpRenewTime_$i"} * 2 - $config{"mvpStartTime_$i"};
                                        $mvp{$config{"mvpMonster_$i"}}{'end_time'} = $mvp{$config{"mvpMonster_$i"}}{'start_time'} + $config{"mvpStartTime_$i"} + $config{"mvpEndTime_$i"} + 60;
                                } elsif (time - $mvptime{$config{"mvpMonster_$i"}} < $config{"mvpRenewTime_$i"} * 3) {
                                        $mvp{$config{"mvpMonster_$i"}}{'type'} = 3;
                                        $mvp{$config{"mvpMonster_$i"}}{'start_time'} = $mvptime{$config{"mvpMonster_$i"}} + $config{"mvpRenewTime_$i"} * 3 - $config{"mvpStartTime_$i"};
                                        $mvp{$config{"mvpMonster_$i"}}{'end_time'} = $mvp{$config{"mvpMonster_$i"}}{'start_time'} + $config{"mvpStartTime_$i"} + $config{"mvpEndTime_$i"} + 120;
                                } else {
                                        $mvp{$config{"mvpMonster_$i"}}{'type'} = 0;
                                        $mvp{$config{"mvpMonster_$i"}}{'start_time'} = int(time);
                                        $mvp{$config{"mvpMonster_$i"}}{'end_time'} = int(time) + $config{"mvpRenewTime_$i"};
                                }
                                $i++;
                        }
                        undef $ai_v{'temp'}{'found'};
                        undef $ai_v{'temp'}{'found_end'};
                        if (!$mvp{$config{"mvpMonster_0"}}{'type'}) {
                                $ai_v{'temp'}{'found'} = 0;
                                $ai_v{'temp'}{'found_end'} = 1;
                        }
                        if (!$ai_v{'temp'}{'found_end'}) {
                                my $i = 0;
                                while ($config{"mvpMonster_$i"} ne "") {
                                        if ($mvp{$config{"mvpMonster_$i"}}{'type'} && ($ai_v{'temp'}{'found'} eq "" || $mvp{$config{"mvpMonster_$i"}}{'start_time'} + $config{"mvpStartTime_$i"} < $mvp{$config{"mvpMonster_"."$ai_v{'temp'}{'found'}"}}{'start_time'})) {
                                                if ($ai_v{'temp'}{'found'} ne "" && $mvp{$config{"mvpMonster_$i"}}{'end_time'} > $mvp{$config{"mvpMonster_"."$ai_v{'temp'}{'found'}"}}{'start_time'}) {
                                                        $mvp{$config{"mvpMonster_$i"}}{'end_time'} = $mvp{$config{"mvpMonster_"."$ai_v{'temp'}{'found'}"}}{'start_time'};
                                                }
                                                $ai_v{'temp'}{'found'} = $i;
                                        }
                                        $i++;
                                }
                        }
                        if (!$ai_v{'temp'}{'found_end'}) {
                                my $i = 0;
                                while ($config{"mvpMonster_$i"} ne "") {
                        		if ($mvp{$config{"mvpMonster_$i"}}{'type'} > 1 && $mvp{$config{"mvpMonster_$i"}}{'end_time'} - $config{"mvpRenewTime_$i"} + 300 > int(time) && (int(time) + $config{"mvpStartTime_$i"} < $mvp{$config{"mvpMonster_"."$ai_v{'temp'}{'found'}"}}{'start_time'})) {
						$mvp{$config{"mvpMonster_$i"}}{'start_time'} = int(time);
                                                if ($mvp{$config{"mvpMonster_$i"}}{'start_time'} + $config{"mvpStartTime_$i"} + $config{"mvpEndTime_$i"} > $mvp{$config{"mvpMonster_"."$ai_v{'temp'}{'found'}"}}{'start_time'}) {
                                                        $mvp{$config{"mvpMonster_$i"}}{'end_time'} = $mvp{$config{"mvpMonster_"."$ai_v{'temp'}{'found'}"}}{'start_time'};
						} else {
							$mvp{$config{"mvpMonster_$i"}}{'end_time'} = $mvp{$config{"mvpMonster_$i"}}{'start_time'} + $config{"mvpStartTime_$i"} + $config{"mvpEndTime_$i"};
						}
                                                $ai_v{'temp'}{'found'} = $i;
                                                last;
					}
					$i++
				}
			}
                        if (!$ai_v{'temp'}{'found_end'}) {
                                my $i = 0;
                                while ($config{"mvpMonster_$i"} ne "") {
                                        if (!$mvp{$config{"mvpMonster_$i"}}{'type'} && int(time) + $config{"mvpStartTime_$i"} < $mvp{$config{"mvpMonster_"."$ai_v{'temp'}{'found'}"}}{'start_time'}) {
                                               $mvp{$config{"mvpMonster_$i"}}{'end_time'} = $mvp{$config{"mvpMonster_"."$ai_v{'temp'}{'found'}"}}{'start_time'};
                                               $ai_v{'temp'}{'found'} = $i;
                                               last;
                                        }
                                        $i++;
                                }
                        }
                        $mvp{'now_monster'}{'index'} = $ai_v{'temp'}{'found'};
                        $mvp{'now_monster'}{'name'} = $config{"mvpMonster_"."$ai_v{'temp'}{'found'}"};
                        $mvp{'now_monster'}{'map'} = $config{"mvpLockmap_"."$ai_v{'temp'}{'found'}"};
                        $mvp{'now_monster'}{'route'} = $config{"mvpLockmap_route_"."$ai_v{'temp'}{'found'}"};
                        $mvp{'now_monster'}{'notinmaps'} = $config{"mvpNotInMaps_"."$ai_v{'temp'}{'found'}"};
                        $mvp{'now_monster'}{'end_time'} = $mvp{$config{"mvpMonster_"."$ai_v{'temp'}{'found'}"}}{'end_time'};
                        $mvp{'now_monster'}{'warp'} = $config{"mvpWarp_"."$ai_v{'temp'}{'found'}"};
                        $mvp{'now_monster'}{'warpnotinmaps'} = $config{"mvpWarpNotInMaps_"."$ai_v{'temp'}{'found'}"};
                        $mvp{'now_monster'}{'monstersSkip'} = $config{"mvpMonsterSkip_"."$ai_v{'temp'}{'found'}"};
		}

                if ($mvp{'now_monster'}{'map'} ne "" && $config{'lockMap'} ne $mvp{'now_monster'}{'map'}) {
                        $config{'lockMap'} = $mvp{'now_monster'}{'map'};
                        $config{'lockMap_route'} = $mvp{'now_monster'}{'route'};
                        $config{'saveMap_warpToNotInMaps'} = $mvp{'now_monster'}{'notinmaps'};
                        $config{'lockMap_warpTo'} = $mvp{'now_monster'}{'warp'};
                        $config{'lockMap_warpToNotInMaps'} = $mvp{'now_monster'}{'warpnotinmaps'};
                        $config{'monstersAttackSkip'} = $mvp{'now_monster'}{'monstersSkip'};
                        initMonControl();
                        printc("yw", "<系统> ", "切换锁定地图为: $config{'lockMap'}\n");
                        chatLog("x", "切换锁定地图为: $config{'lockMap'}\n");
                        if ($field{'name'} ne "" && $config{'saveMap'} ne $field{'name'} && $config{'saveMap_warpToNotInMaps'} && !existsInList($config{'saveMap_warpToNotInMaps'}, $field{'name'})) {
                                undef @ai_seq;
                                undef @ai_seq_args;
                        }
                }
        }
}	

sub mvpAttackAI {
	return if ($vipLevel || $xkore);
	$config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"} = 0.1 if ($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"} < 0.1);
}

sub checkVipLevel {
        if ($config{'vipPassword'} eq "$vipKey") {
                printc("wy", "<信息> ", "认证类型: 管理员\n");
                $vipLevel = 3;
                return;
        } elsif ($config{'vipPassword'} eq getVipPassword(2, $accountAID)) {
                printc("wg", "<信息> ", "认证类型: 贵宾\n");
                $vipLevel = 2;
                return;
        } elsif ($config{'vipPassword'} eq getVipPassword(1, $accountAID)) {
                printc("ww", "<信息> ", "认证类型: 高级用户\n");
                $vipLevel = 1;
                return;
        } else {
                $vipLevel = 0;
                return;
        }
}

sub getVipPassword {
	my $level = shift;
	my $key = shift;
	return md5_hex($level.$vipKey.$key);
}

sub mvpNoticeRecv {
	my $type = shift;
	my $name = shift;
	my $map = shift;
	my $pos_x = shift;
	my $pos_y = shift;
	my $time1 = shift;
	my $time2 = shift;
	my $time;
	$time = int(time - $time2);
	if ($config{'mvpMode'} >= 2 && $vipLevel >= 2) {
		if ($type eq "appeared" || $type eq "moved" || $type eq "disappeared") {
			if (!$chars[$config{'char'}]{'mvp'} && $name eq $mvp{'now_monster'}{'name'} && $map eq $mvp{'now_monster'}{'map'} && $time > $ai_v{'mvp_notice_lastTime'}) {
				$config{'lockMap_x'} = $pos_x;
				$config{'lockMap_y'} = $pos_y;
			}
		} elsif ($type eq "teleported") {
			if (!$chars[$config{'char'}]{'mvp'} && $name eq $mvp{'now_monster'}{'name'} && $map eq $mvp{'now_monster'}{'map'} && $time > $ai_v{'mvp_notice_lastTime'}) {
				undef $config{'lockMap_x'};
				undef $config{'lockMap_y'};
			}
		} elsif ($type eq "dead") {
		        my $i = 0;
        		while ($config{"mvpMonster_$i"} ne "") {
                		if ($name eq $config{"mvpMonster_$i"} && abs($mvptime{$name} - $time) > 10) {
	                        	$mvptime{$name} = $time;
		                        writeMvptimeFileIntact("$logs_path/mvptime.txt", \%mvptime);
        		                undef $mvp{'now_monster'}{'name'} if ($mvp{'now_monster'}{'name'} eq $name);
	                	        last;
		                }
        		        $i++;
		        }
		}
		$ai_v{'mvp_notice_lastTime'} = $time;
	}
}
			
sub encodePassword {
        my $msg = shift;
        my $newmsg;
        my $encryptVal = (ord(substr($config{'username'}, 0, 1)) * 34 + ord(substr($config{'username'}, length($config{'username'}) - 1, 1)) * 137) % 254 + 1;
        for ($i = 0; $i < length($msg) ;$i++) {
                $newmsg .= uc(unpack("H4", pack("S2", ord(substr($msg, $i, 1)) * $encryptVal)));
        }
        return $newmsg;
}

sub decodePassword {
        my $msg = shift;
        my $newmsg;
        my $encryptVal = (ord(substr($config{'username'}, 0, 1)) * 34 + ord(substr($config{'username'}, length($config{'username'}) - 1, 1)) * 137) % 254 + 1;
        for ($i = 0; $i < length($msg) ;$i+=4) {
                $newmsg .= chr(unpack("S2", pack("H4", substr($msg, $i, 4))) / $encryptVal  % 255);
        }
        return $newmsg;
}
			
sub mvpNoticeSent {
	my $type = shift;
	my $name = shift;
	my $map = shift;
	my $pos_x = shift;
	my $pos_y = shift;
	$ai_v{'mvp_notice_sent'} = 0;
	$ai_v{'mvp_notice_init_time'} = int(time);
	$ai_v{'mvp_notice_message'} = "[KM]|$type|$name|$map|$pos_x|$pos_y|".$ai_v{'mvp_notice_init_time'};
}



	
1;