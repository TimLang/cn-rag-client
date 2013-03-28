#########################################################################
# KoreEasy Auth Module
#########################################################################

sub initMVPvar {
	our $mvpMonster = "1039,1251,1038,1157,1059,1147,1112,1272,1115,1086,1159,1190,1087,1046,1150,1511";
	our $vipKey = "174219";
}

sub avoidChat {
        my $ID = shift;
        my $name = shift;
        my $message = shift;
        my $keyTemp1;
        my $keyTemp2;
        my $keyCount = 0;
        my $i;
        my @keyWords;
        my $sleeptime;
        my $AID = unpack("L1", $ID);
        ($map_string) = $map_name =~ /([\s\S]*)\.gat/;
        $config{'avoidGM_reconnect'} = 60 if ($config{'avoidGM_reconnect'} < 60);
       
	if ($config{'avoidGM_myName'} && $message ne "") {
		for ($i = 1; $i < length($chars[$config{'char'}]{'name'}) - 1; $i++) {
			$keyTemp1 = substr($chars[$config{'char'}]{'name'}, 0, $i);
			$keyTemp2 = substr($chars[$config{'char'}]{'name'}, $i, length($chars[$config{'char'}]{'name'}) - $i);
			if ($message =~ /\Q$keyTemp1\E/i && $message =~ /\Q$keyTemp2\E/i) {
		                if (!$indoors_lut{$map_string.'.rsw'}) {
        	        	        $sleeptime = int($config{'avoidGM_reconnect'} + rand($config{'avoidGM_reconnect'}) + 3600);
        		                printc("yr", "<系统> ", "$name($AID) 说话，瞬移断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                		        chatLog("gm", "$name($AID) 说话，瞬移断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        		useTeleport(1);
		                        sleep(2);
        		        } else {
                		        $sleeptime = int($config{'avoidGM_reconnect'} + rand($config{'avoidGM_reconnect'}) + 3600);
                        		printc("yr", "<系统> ", "$name($AID) 说话，房内断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
	                        	chatLog("gm", "$name($AID) 说话，房内断线$sleeptime秒。位置: 位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
	        	        }
        	        	$conState = 1;
	        	        undef $conState_tries;
        	        	$timeout_ex{'master'}{'time'} = time;
	                	$timeout_ex{'master'}{'timeout'} = $sleeptime;
		                killConnection(\$remote_socket) if (!$xKore);
        		        return;
	                }
	        }
	}
        if ($message ne "" && $config{'avoidGM_word'}) {
                @keyWords = split /,/, $config{'avoidGM_word'};
                for ($i = 0; $i < @keyWords; $i++) {
                        next if ($keyWords[$i] eq "");
                        if ($message =~ /\Q$keyWords[$i]\E/i) {
                        	if (time - $avoidChat_lastTime > 900) {
                        		undef $avoidChat_count;
                        	}
				$avoidChat_count++;
                        	$avoidChat_lastTime = time;
                        	if ($avoidChat_count == 1) {
                        		if (!$indoors_lut{$map_string.'.rsw'}) {
	                                        printc("yr", "<系统> ", "$name($AID) 说话，瞬移躲避\n");
        	                		chatLog("gm", "$name($AID) 说话，瞬移躲避\n");
                	                        useTeleport(1);
                	                } else {
	                                        printc("yr", "<系统> ", "$name($AID) 房内说话，忽略躲避\n");
        	                		chatLog("gm", "$name($AID) 房内说话，忽略躲避\n");
                	                }
                	                last;
				} else {
	                                if (!$indoors_lut{$map_string.'.rsw'}) {
        	                               	$sleeptime = int($config{'avoidGM_reconnect'} + rand($config{'avoidGM_reconnect'}));
                	                        printc("yr", "<系统> ", "$name($AID) 说话，瞬移断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        	                chatLog("gm", "$name($AID) 说话，瞬移断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                                	        useTeleport(1);
                                        	sleep(2);
	                                } else {
        	                                $sleeptime = int($config{'avoidGM_reconnect'} + rand($config{'avoidGM_reconnect'}) + 1800);
                	                        printc("yr", "<系统> ", "$name($AID) 说话，房内断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        	                chatLog("gm", "$name($AID) 说话，房内断线$sleeptime秒。位置: 位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                                	}
	                		$conState = 1;
        	        		undef $conState_tries;
                			$timeout_ex{'master'}{'time'} = time;
                			$timeout_ex{'master'}{'timeout'} = $sleeptime;
	                		killConnection(\$remote_socket) if (!$xKore);
        	                        return;
        	                }
                        }
                }
        }
        if($name ne "" && $avoidlist_rlut{$name}){
                if (!$indoors_lut{$map_string.'.rsw'}) {
                	$sleeptime = int($config{'avoidGM_reconnect'} + rand($config{'avoidGM_reconnect'}));
                      	if ($config{'mvpMode'} >= 2 && $mvp{'now_monster'}{'name'} ne "" && $mvp{'now_monster'}{'end_time'} > time && $sleeptime > $mvp{'now_monster'}{'end_time'} - time) {
                       		$sleeptime = int($mvp{'now_monster'}{'end_time'} - time);
                       	}
                        printc("yr", "<系统> ", "$name($AID) 说话，瞬移断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        chatLog("gm", "$name($AID) 说话，瞬移断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        useTeleport(1);
                        sleep(2);
                } else {
                        $sleeptime = int($config{'avoidGM_reconnect'} + rand($config{'avoidGM_reconnect'}) + 1800);
                        printc("yr", "<系统> ", "$name($AID) 说话，房内断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        chatLog("gm", "$name($AID) 说话，房内断线$sleeptime秒。位置: 位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                }
                $conState = 1;
                undef $conState_tries;
                $timeout_ex{'master'}{'time'} = time;
                $timeout_ex{'master'}{'timeout'} = $sleeptime;
                killConnection(\$remote_socket) if (!$xKore);
                return;
        }
        if ($ID ne "" && $aid_rlut{$AID}{'avoid'}) {
                if (!$indoors_lut{$map_string.'.rsw'}) {
                	$sleeptime = int($config{'avoidGM_reconnect'} + rand($config{'avoidGM_reconnect'}));
                      	if ($config{'mvpMode'} >= 2 && $mvp{'now_monster'}{'name'} ne "" && $mvp{'now_monster'}{'end_time'} > time && $sleeptime > $mvp{'now_monster'}{'end_time'} - time) {
                       		$sleeptime = int($mvp{'now_monster'}{'end_time'} - time);
                       	}
                        printc("yr", "<系统> ", "$name($AID) 说话，瞬移断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        chatLog("gm", "$name($AID) 说话，瞬移断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        useTeleport(1);
                        sleep(2);
                } else {
                        $sleeptime = int($config{'avoidGM_reconnect'} + rand($config{'avoidGM_reconnect'}) + 1800);
                        printc("yr", "<系统> ", "$name($AID) 说话，房内断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        chatLog("gm", "$name($AID) 说话，房内断线$sleeptime秒。位置: 位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                }
                $conState = 1;
                undef $conState_tries;
                $timeout_ex{'master'}{'time'} = time;
                $timeout_ex{'master'}{'timeout'} = $sleeptime;
                killConnection(\$remote_socket) if (!$xKore);
                return;
        }
}
1;