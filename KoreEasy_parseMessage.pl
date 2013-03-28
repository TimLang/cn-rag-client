#######################################
#######################################
# Parse RO Client Send Message
#######################################
#######################################
#use Encode;
#sub bytesToString {
#	return Encode::decode($config{serverEncoding} || 'Western', $_[0]);
#}
sub parseSendMsg {
        my $msg = shift;

        $sendMsg = $msg;
        if (length($msg) >= 4 && $conState >= 4 && length($msg) >= unpack("S1", substr($msg, 0, 2))) {
                decrypt(\$msg, $msg);
        }
        $switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));
        print "Packet Switch SENT_BY_CLIENT: $switch\n" if ($config{'debugPacket_rosent'} || (existsInList($config{'debugPacket_rosent_dumpList'}, $switch)));
        dumpData($sendMsg) if (existsInList($config{'debugPacket_rosent_dumpList'}, $switch));

        # If the player tries to manually do something in the RO client, disable AI for a small period
        # of time using ai_clientSuspend().

        if ($switch eq "0066") {
                 # Login character selected
                configModify("char", unpack("C*",substr($msg, 2, 1)));

        } elsif ($switch eq "0072") {
                # Map login
                if ($config{'sex'} ne "") {
                        $sendMsg = substr($sendMsg, 0, 18) . pack("C",$config{'sex'});
                }

        } elsif ($switch eq "007D") {
                # Map loaded
                $conState = 5;
                printc("nn", "<地图> ", "读取完成\n") if ($config{'mode'} >= 2);
                if ($loadingMap) {
                        undef $loadingMap;
                        printc("wc", "<信息> ", "$chars[$config{'char'}]{'name'} 进入游戏\n");
                        $timeout{'ai'}{'time'} = time + 3;
                }
                $timeout{'welcomeText'}{'time'} = time;

        } elsif ($switch eq "0085") {
                # Move
                aiRemove("clientSuspend");
                if ($config{"master_version_$config{'master'}"} eq "0") {
	                makeCoords(\%coords, substr($msg, 6, 3));
	        } else {
	                makeCoords(\%coords, substr($msg, 2, 3));	        	
	        }
                ai_clientSuspend($switch, (distance(\%{$chars[$config{'char'}]{'pos'}}, \%coords) * $config{'seconds_per_block'}));

        } elsif ($switch eq "0089") {
                # Attack
                if (!($config{'tankMode'} && binFind(\@ai_seq, "attack") ne "")) {
                        aiRemove("clientSuspend");
                        ai_clientSuspend($switch, 2, unpack("C*",substr($msg,6,1)), substr($msg,2,4));
                        if ($AI) {
                                my $ID = substr($msg, 2, 4);
                                if (%{$monsters{$ID}}) {
                                	aiRemove("attack");
                                        attack($ID);
                                        undef $sendMsg;
                                }
                        }
                } else {
                        undef $sendMsg;
                }

        } elsif ($switch eq "008C" || $switch eq "0108" || $switch eq "017E") {
                # Public, party and guild chat
                my $length = unpack("S",substr($msg,2,2));
                my $message = substr($msg, 4, $length - 4);
                my ($chat) = $message =~ /^[\s\S]*? : ([\s\S]*)\000?/;
                $chat =~ s/^\s*//;
                if ($chat =~ /^$config{'commandPrefix'}/) {
                        $chat =~ s/^$config{'commandPrefix'}//;
                        $chat =~ s/^\s*//;
                        $chat =~ s/\s*$//;
                        $chat =~ s/\000*$//;
                        parseInput($chat, 1);
                        undef $sendMsg;
                }

        } elsif ($switch eq "0096") {
                # Private message
                $length = unpack("S",substr($msg,2,2));
                ($user) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
                $chat = substr($msg, 28, $length - 29);
                $chat =~ s/^\s*//;
                if ($chat =~ /^$config{'commandPrefix'}/) {
                        $chat =~ s/^$config{'commandPrefix'}//;
                        $chat =~ s/^\s*//;
                        $chat =~ s/\s*$//;
                        parseInput($chat, 1);
                        undef $sendMsg;
                } else {
                        undef %lastpm;
                        $lastpm{'msg'} = $chat;
                        $lastpm{'user'} = $user;
                        push @lastpm, {%lastpm};
                }

        } elsif ($switch eq "009F") {
                # Take
                aiRemove("clientSuspend");
                ai_clientSuspend($switch, 2, substr($msg,2,4));

        } elsif ($switch eq "00B2") {
                # Trying to exit (respawn)
                aiRemove("clientSuspend");
                ai_clientSuspend($switch, 10);

	} elsif ($switch eq "0113") {
		# Random skill support
		if (time - $chars[$config{'char'}]{'randomSkill_send_time'} < 2) {
			undef $sendMsg;
		}

        } elsif ($switch eq "018A") {
                # Trying to exit
                aiRemove("clientSuspend");
                ai_clientSuspend($switch, 10);
        }

        if ($sendMsg ne "") {
                sendToServerByInject(\$remote_socket, $sendMsg);
        }
}





#######################################
#######################################
#Parse Message
#######################################
#######################################



sub parseMsg {
        my $msg = shift;
        my $msg_size;

        if (length($msg) < 2) {
                return $msg;
        }

        # Determine packet switch
        $switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));
        if (length($msg) >= 4 && substr($msg,0,4) ne $accountID && $conState >= 4 && $lastswitch ne $switch
                && length($msg) >= unpack("S1", substr($msg, 0, 2))) {
                decrypt(\$msg, $msg);
        }
        $switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));

        print "Packet Switch: $switch : $rpackets{$switch}\n" if ($config{'debugPacket_received'} >= 2 || (existsInList($config{'debugPacket_received_dumpList'}, $switch)));

        $lastswitch = $switch;

        # Determine packet length using recvpackets.txt.
        if (substr($msg,0,4) ne $accountID || ($conState != 2 && $conState != 4)) {
                if ($rpackets{$switch} eq "-") {
                        # Complete packet; the size of this packet is equal
                        # to the size of the entire data
                        $msg_size = length($msg);
                } elsif ($rpackets{$switch} eq "0") {
                        # Variable length packet
                        if (length($msg) < 4) {
                                return $msg;
                        }
                        $msg_size = unpack("S1", substr($msg, 2, 2));
                        if (length($msg) < $msg_size) {
                                return $msg;
                        }
                } elsif ($rpackets{$switch} > 1) {
                        # Static length packet
                        if (length($msg) < $rpackets{$switch}) {
                                return $msg;
                        }
                        $msg_size = $rpackets{$switch};
                } else {
      	                printc("yr", "<错误> ", "封包解释错误: $last_know_switch -> $switch ($msg_size)\n");
               	        injectAdminMessage("[KE] : 封包解释错误: $last_know_switch -> $switch ($msg_size)\n") if ($xKore);
		        chatLog("封包解释错误: $last_know_switch -> $switch ($msg_size)\n");
                        dumpData($msg);
			return "";
                }
                $last_know_msg = substr($msg, 0, $msg_size);
                $last_know_switch = $switch;
        }

        $lastMsgLength = length($msg);

        # Start parse message
        if ((substr($msg,0,4) eq $accountID && ($conState == 2 || $conState == 4)) || ($xKore && !$accountID && length($msg) == 4)) {
                $accountID = substr($msg, 0, 4);
                $AI = 1 if (!$AI_forcedOff);
                if ($config{'encrypt'} && $conState == 4) {
                        $encryptKey1 = unpack("L1", substr($msg, 6, 4));
                        $encryptKey2 = unpack("L1", substr($msg, 10, 4));
                        {
                                use integer;
                                $imult = (($encryptKey1 * $encryptKey2) + $encryptKey1) & 0xFF;
                                $imult2 = ((($encryptKey1 * $encryptKey2) << 4) + $encryptKey2 + ($encryptKey1 * 2)) & 0xFF;
                        }
                        $encryptVal = $imult + ($imult2 << 8);
                        $msg_size = 14;
                } else {
                        $msg_size = 4;
                }

        } elsif ($switch eq "0069") {
                #0069 <len>.w <login ID1>.l <account ID>.l <login ID2>.l ?.32B <sex>.B {<IP>.l <port>.w <server name>.20B <login users>.w <maintenance>.w <new>.w}.32B*
                #Login info
                $conState = 2;
                undef $conState_tries;
                if ($versionSearch) {
                        $versionSearch = 0;
                        writeDataFileIntact("$setup_path/config.txt", \%config);
                }
                $sessionID = substr($msg, 4, 4);
                $accountID = substr($msg, 8, 4);
                $sessionID2 = substr($msg, 12, 4);
                $accountSex = unpack("C1",substr($msg, 46, 1));
                $accountSex2 = ($config{'sex'} ne "") ? $config{'sex'} : $accountSex;
                $accountAID = unpack("L1",$accountID);
                print "---------Account Info----------\n";
                print sprintf("Account ID: %-20s\n",getHex($accountID));
                print sprintf("Sex:        %-20s\n",$sex_lut{$accountSex});
                print sprintf("Session ID: %-20s\n",getHex($sessionID));
                print sprintf("            %-20s\n",getHex($sessionID2));
                print "-------------------------------\n";
                my $num = 0;
                undef @servers;
                print "------------Servers------------\n";
                print "#         Name            Users  IP              Port  Main  new\n";
                for(my $i = 47; $i < $msg_size; $i+=32) {
                        $servers[$num]{'ip'} = makeIP(substr($msg, $i, 4));
                        $servers[$num]{'port'} = unpack("S1", substr($msg, $i+4, 2));
                        ($servers[$num]{'name'}) = substr($msg, $i + 6, 20) =~ /([\s\S]*?)\000/;
                        $servers[$num]{'users'} = unpack("S1",substr($msg, $i + 26, 2));
                        $servers[$num]{'maintenance'} = unpack("S1",substr($msg, $i + 28, 2));
                        $servers[$num]{'new'} = unpack("S1",substr($msg, $i + 30, 2));
                        print sprintf("%-3d %-21s %-6d %-15s %-6d%-6d%-6d\n",$num,$servers[$num]{'name'},$servers[$num]{'users'},$servers[$num]{'ip'},$servers[$num]{'port'},$servers[$num]{'maintenance'},$servers[$num]{'new'});
                        $num++;
                }
                print "-------------------------------\n";
                if (!$xKore) {
                        printc("yn", "<系统> ", "关闭与帐号服务器的连接\n");
                        killConnection(\$remote_socket);
                        if ($config{'server'} eq "") {
                                printc("yw", "<系统> ", "请选择服务器: \n");
                                $waitingForInput = 1;
                        } else {
                                printc("yn", "<系统> ", "已选择服务器: $config{'server'}\n");
                        }
                }

        } elsif ($switch eq "006A") {
                #006a <error No>.B
                #login error
                my $type = unpack("C1",substr($msg, 2, 1));
                if ($type == 0) {
                        printc("yr", "<系统> ", "尚未登录的使用者账号。请重新确认账号\n");
                        if (!$xKore) {
                                printc("yw", "<系统> ", "请输入用户名: \n");
                                $timeout{'reconnect_auto'}{'time'} = time;
                                while (!timeOut(\%{$timeout{'reconnect_auto'}})) {
                      	        	usleep($config{'sleepTime'});
					$temp_msg = "\0" x 256;
					$temp_msgLen = $input_recv->Call($temp_msg, 0);
                			if ($temp_msgLen != -1) {
                				$temp_msg = substr($temp_msg, 0, $temp_msgLen);
                				last;
                			} else {
                				undef $temp_msg;
					}
                                }
                                if ($temp_msg ne "") {
                                        $config{'username'} = $temp_msg;
                                        writeDataFileIntact("$setup_path/config.txt", \%config);
                                }
                        }
                } elsif ($type == 1) {
                        printc("yr", "<系统> ", "密码错误\n");
                        if (!$xKore) {
                                printc("yw", "<系统> ", "请输入密码\n");
                                $timeout{'reconnect_auto'}{'time'} = time;
                                while (!timeOut(\%{$timeout{'reconnect_auto'}})) {
			        	usleep($config{'sleepTime'});
					$temp_msg = "\0" x 256;
					$temp_msgLen = $input_recv->Call($temp_msg, 0);
                			if ($temp_msgLen != -1) {
                				$temp_msg = substr($temp_msg, 0, $temp_msgLen);
                				last;
                			} else {
                				undef $temp_msg;
					}
                                }
                                if ($temp_msg ne "") {
                                        $config{'password'} = encodePassword($temp_msg);
                                        writeDataFileIntact("$setup_path/config.txt", \%config);
                                }
                        }
                } elsif ($type == 3) {
                        printc("yr", "<系统> ", "服务器拒绝联机\n");
                } elsif ($type == 4) {
                        printc("yr", "<系统> ", "服务器终止联机，此帐号已被冻结\n");
                        quit();
                } elsif ($type == 5) {
                        printc("yr", "<系统> ", "游戏版本$config{'version'}无效...尝试寻找正确的版本\n");
                        $config{'version'}++;
                        if (!$versionSearch) {
                                $config{'version'} = 0;
                                $versionSearch = 1;
                        }
                        undef $timeout{'master'}{'time'};
                } elsif ($type == 6) {
                        prinC("Y", "游戏暂时停止联机，请重新联机。\n");
                }
                if ($type != 5 && $versionSearch) {
                        $versionSearch = 0;
                        writeDataFileIntact("$setup_path/config.txt", \%config);
                }

        } elsif ($switch eq "006B") {
                #006b <len>.w <charactor select data>.106B*
                #Character select connection success & character data
                printc("yn", "<系统> ", "接收到人物资料\n");
                $conState = 3;
                undef $conState_tries;
                if ($config{"master_version_$config{'master'}"} eq "0") {
                        $startVal = 24;
                } else {
                        $startVal = 4;
                }
                for(my $i = $msg_size % 112; $i < $msg_size; $i+=112) {
                        #exp display bugfix - chobit andy 20030129
						
			my ($cID,$exp,$zeny,$jobExp,$jobLevel, $opt1, $opt2, $option, $karma, $manner, $statpt,
			$hp,$maxHp,$sp,$maxSp, $walkspeed, $jobId,$hairstyle, $weapon, $level, $skillpt,$headLow, $shield,$headTop,$headMid,$hairColor,
			$clothesColor,$name,$str,$agi,$vit,$int,$dex,$luk,$num, $rename) =
						unpack('a4 V9 v V2 v14 Z24 C6 v2', substr($msg, $i));
						
                        #$num = unpack("C1", substr($msg, $i + 104, 1));
						$chars[$num]{'ID'} = $accountID;
                        $chars[$num]{'exp'} = $exp;
                        $chars[$num]{'zenny'} = $zeny;
                        $chars[$num]{'exp_job'} = $jobExp;
                        $chars[$num]{'lv_job'} = $jobLevel;
                        $chars[$num]{'hp'} = $hp;
                        $chars[$num]{'hp_max'} = $maxHp;
                        $chars[$num]{'sp'} = $sp;
                        $chars[$num]{'sp_max'} = $maxSp;
                        $chars[$num]{'jobID'} = $jobId;
                        $chars[$num]{'lv'} = $level;
                        $chars[$num]{'name'} = $name;
                        $chars[$num]{'str'} = $str;
                        $chars[$num]{'agi'} = $agi;
                        $chars[$num]{'vit'} = $vit;
                        $chars[$num]{'int'} = $int;
                        $chars[$num]{'dex'} = $dex;
                        $chars[$num]{'luk'} = $luk;
                        $chars[$num]{'sex'} = $accountSex2;
						$chars[$num]{'nameID'} = unpack("V", $chars[$num]{ID});
						#$chars[$num]{'name'} = bytesToString($chars[$num]{name});
                }
                for (my $num = 0; $num < @chars; $num++) {
                        print sprintf("-------  Character %2d ---------\n",$num);
                        print sprintf("Name: %-25s\n",$chars[$num]{'name'});
                        print sprintf("Job : %-8s      Job Exp: %-8s\n",$jobs_lut{$chars[$num]{'jobID'}},$chars[$num]{'exp_job'});
                        print sprintf("Lv  : %-8s      Str: %-8s\n",$chars[$num]{'lv'},$chars[$num]{'str'});
                        print sprintf("J.Lv: %-8s      Agi: %-8s\n",$chars[$num]{'lv_job'},$chars[$num]{'agi'});
                        print sprintf("Exp : %-8s      Vit: %-8s\n",$chars[$num]{'exp'},$chars[$num]{'vit'});
                        print sprintf("HP  : %-5s/%-5s   Int: %-8s\n",$chars[$num]{'hp'},$chars[$num]{'hp_max'},$chars[$num]{'int'});
                        print sprintf("SP  : %-5s/%-5s   Dex: %-8s\n",$chars[$num]{'sp'},$chars[$num]{'sp_max'},$chars[$num]{'dex'});
                        print sprintf("Zeny: %-12s  Luk: %-8s\n",$chars[$num]{'zenny'},$chars[$num]{'luk'});
                        print "-------------------------------\n";
                }
                if (!$xKore) {
                        if ($config{'char'} eq "") {
                                printc("yw", "<系统> ", "请选择人物: \n");
                                $waitingForInput = 1;
                        } else {
                                printc("yn", "<系统> ", "已选择人物: $config{'char'}\n");
                                sendCharLogin(\$remote_socket, $config{'char'});
                                $timeout{'charlogin'}{'time'} = time;
                        }
                }

        } elsif ($switch eq "006C") {
                #006c <error No> B
                #Failure of character selection
                printc("yr", "<系统> ", "登录身份验证服务器错误，没有指定的人物...\n");
                $conState = 1;
                undef $conState_tries;
                $timeout_ex{'master'}{'time'} = time;
                $timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
                killConnection(\$remote_socket) if (!$xKore);

        } elsif ($switch eq "0071") {
                #0071 <character ID> l <map name> 16B <ip> l <port> w
                #Character selection success & map name & game IP/port
                printc("yn", "<系统> ", "接收到人物ID及地图服务器的IP地址\n");
                $conState = 4;
                undef $conState_tries;
                $charID = substr($msg, 2, 4);
                ($map_name) = substr($msg, 6, 16) =~ /([\s\S]*?)\000/;

                ($ai_v{'temp'}{'map'}) = $map_name =~ /([\s\S]*)\./;
                if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
                        getField("map/$ai_v{'temp'}{'map'}.fld", \%field);
			$timeout{'ai_attack_auto'}{'time'} = time + 10 if ($config{'lockMap'} ne "" && $ai_v{'temp'}{'map'} ne $config{'lockMap'});
                }

                $map_ip = makeIP(substr($msg, 22, 4));
                $map_port = unpack("S1", substr($msg, 26, 2));
                if ($sendFlyMap) {
                        $map_ip = $sendFlyIP;
                        $map_port = $sendFlyPort;
                } elsif (!$sendFlyMap && $mapip_lut{$ai_v{'temp'}{'map'}.'.rsw'}{'ip'} ne $map_ip) {
                        mapipModify($ai_v{'temp'}{'map'}.'.rsw', $map_ip);
                }
                print "--------Game Info---------\n";
                print sprintf("Char ID  : %-20s\n",getHex($charID));
                print sprintf("MAP Name : %-20s\n",$map_name);
                print sprintf("MAP IP   : %-20s\n",$map_ip);
                print sprintf("MAP Port : %-20s\n",$map_port);
                print "--------------------------\n";
                printc("yn", "<系统> ", "关闭与帐号服务器的连接\n");
                killConnection(\$remote_socket) if (!$xKore);
                initConnectVars() if ($xKore);
                aiRemove("route");
	        aiRemove("route_getRoute");
        	aiRemove("route_getMapRoute");

        } elsif ($switch eq "02EB") {
                #0073 <server tick> l <coordinate> 3B? 2B
                #Game connection success & server side 1ms clock & appearance position
                $conState = 5 if (!$xKore);
                undef $conState_tries;
                makeCoords(\%{$chars[$config{'char'}]{'pos'}}, substr($msg, 6, 3));
                %{$chars[$config{'char'}]{'pos_to'}} = %{$chars[$config{'char'}]{'pos'}};
                printc("gn", "->$switch ", "Your Coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n") if $config{'debug'};
                if ($xKore) {
                        printc("yn", "<系统> ", "等待读入地图...\n");
                        $loadingMap = 1;
                } else {
                        printc("wc", "<信息> ", "$chars[$config{'char'}]{'name'} 进入游戏\n");
                        sendMapLoaded(\$remote_socket);
                        $timeout{'ai'}{'time'} = time;
                }
                sendIgnoreAll(\$remote_socket, 0) if($config{'chatAutoExall'} && !$xKore);
                checkVipLevel();

        } elsif ($switch eq "0075") {
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);

        } elsif ($switch eq "0077") {
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);

        } elsif ($switch eq "0078" || $switch eq "01D8") {
                #0078 <ID> l <speed> w <opt1> w <opt2> w <option> w <class> w <hair> w <weapon> w <head option bottom> w <shield> w <head option top> w <head option mid> w <hair color> w? W <head dir> w <guild> l <emblem> l <manner> w <karma> B <sex> B <X_Y_dir> 3B? B? B <sit> B <Lv> B
                #01d8 <ID>.l <speed>.w <opt1>.w <opt2>.w <option>.w <class>.w <hair>.w <item id1>.w <item id2>.w <head option bottom>.w <head option top>.w <head option mid>.w <hair color>.w ?.w <head dir>.w <guild>.l <emblem>.l <manner>.w <karma>.B <sex>.B <X_Y_dir>.3B ?.B ?.B <sit>.B <Lv>.B ?.B
                #0078 mainly is monster , portal
                #01D8 = npc + player for episode 4+
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                my $ID = substr($msg, 2, 4);
                my $param1 = unpack("S1", substr($msg, 8, 2));
                my $param2 = unpack("S1", substr($msg, 10, 2));
                my $param3 = unpack("S1", substr($msg, 12, 2));
                my $type = unpack("S*",substr($msg, 14,  2));
                my $pet = unpack("C*",substr($msg, 16,  1));
                my $sex = unpack("C*",substr($msg, 45,  1));
                makeCoords(\%coords, substr($msg, 46, 3));
                my $act = unpack("C*",substr($msg, 51,  1));
                my $level = unpack("C1", substr($msg, 52, 1));
                if ($type >= 1000 && $type < 4000) {
                        if ($pet) {
                                if (!%{$pets{$ID}}) {
                                        binAdd(\@petsID, $ID);
                                        $pets{$ID}{'appear_time'} = time;
                                        $display = ($monsters_lut{$type} ne "")
                                                        ? $monsters_lut{$type}
                                                        : "Unknown ".$type;
                                        $pets{$ID}{'nameID'} = $type;
                                        $pets{$ID}{'name'} = $display;
                                        $pets{$ID}{'name_given'} = "Unknown";
                                        $pets{$ID}{'binID'} = binFind(\@petsID, $ID);
                                        $pets{$ID}{'lv'} = $level;
                                }
                                %{$pets{$ID}{'pos'}} = %coords;
                                %{$pets{$ID}{'pos_to'}} = %coords;
                                printc("gn", "->$switch ", "Pet Exists: $pets{$ID}{'name'}($pets{$ID}{'binID'})\n") if ($config{'debug'});
                        } else {
                                if (!%{$monsters{$ID}}) {
                                        binAdd(\@monstersID, $ID);
                                        $monsters{$ID}{'appear_time'} = time;
                                        $display = ($monsters_lut{$type} ne "")
                                                        ? $monsters_lut{$type}
                                                        : "Unknown ".$type;
                                        $monsters{$ID}{'nameID'} = $type;
                                        $monsters{$ID}{'name'} = $display;
                                        $monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
                                        %{$monsters{$ID}{'pos_to'}} = %coords;
	                                mvpMonsterFound($ID);
                                }
                                %{$monsters{$ID}{'pos'}} = %coords;
                                %{$monsters{$ID}{'pos_to'}} = %coords;
		               	setStatus($ID, $param1, $param2, $param3);
                                printc("gn", "->$switch ", "Monster Exists: $monsters{$ID}{'name'}($monsters{$ID}{'binID'})\n") if ($config{'debug'});
                        }

                } elsif ($jobs_lut{$type}) {
                        if (!%{$players{$ID}}) {
                                binAdd(\@playersID, $ID);
                                $players{$ID}{'appear_time'} = time;
                                $players{$ID}{'jobID'} = $type;
                                $players{$ID}{'sex'} = $sex;
                                $players{$ID}{'name'} = "Unknown";
                                $players{$ID}{'binID'} = binFind(\@playersID, $ID);
                                $players{$ID}{'nameID'} = unpack("L1", $ID);
                                if ($aid_rlut{$players{$ID}{'nameID'}}{'avoid'}) {
                                        %{$players{$ID}{'pos'}} = %coords;
                                        %{$players{$ID}{'pos_to'}} = %coords;
                                        binAdd(\@avoidID, $ID);
                                }
                        }
			if ($act == 1) {
	                        $players{$ID}{'dead'} = 1;
	                        if ($config{'partyAutoResurrect'} > 0 && $chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'} ne "") {
                                        $chars[$config{'char'}]{'party'}{'users'}{$ID}{'dead_time'} = time;
                                        ai_stateResetParty($ID);
                                }
                        } elsif ($act == 2) {
	                        $players{$ID}{'sitting'} = 1;
	                }
                        %{$players{$ID}{'pos'}} = %coords;
                        %{$players{$ID}{'pos_to'}} = %coords;
	               	setStatus($ID, $param1, $param2, $param3);
                        printc("gn", "->$switch ", "Player Exists: $players{$ID}{'name'}($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n") if ($config{'debug'});

                } elsif ($type == 45) {
                        if (!%{$portals{$ID}}) {
                                binAdd(\@portalsID, $ID);
                                $portals{$ID}{'appear_time'} = time;
                                $nameID = unpack("L1", $ID);
                                $exists = portalExists($field{'name'}, \%coords);
                                $display = ($exists ne "")
                                        ? "$portals_lut{$exists}{'source'}{'map'} -> $portals_lut{$exists}{'dest'}{'map'}"
                                        : "Unknown ".$nameID;
                                $portals{$ID}{'source'}{'map'} = $field{'name'};
                                $portals{$ID}{'type'} = $type;
                                $portals{$ID}{'nameID'} = $nameID;
                                $portals{$ID}{'name'} = $display;
                                $portals{$ID}{'binID'} = binFind(\@portalsID, $ID);
                        }
                        %{$portals{$ID}{'pos'}} = %coords;
                        printc("nn", "<传送> ", "存在: $portals{$ID}{'name'} - ($portals{$ID}{'binID'})\n");

                } elsif ($type < 1000) {
                        if (!%{$npcs{$ID}}) {
                                binAdd(\@npcsID, $ID);
                                $npcs{$ID}{'appear_time'} = time;
                                $nameID = unpack("L1", $ID);
                                $display = (%{$npcs_lut{$nameID}})
                                        ? $npcs_lut{$nameID}{'name'}
                                        : "Unknown ".$nameID;
                                $npcs{$ID}{'type'} = $type;
                                $npcs{$ID}{'nameID'} = $nameID;
                                $npcs{$ID}{'name'} = $display;
                                $npcs{$ID}{'binID'} = binFind(\@npcsID, $ID);
                        }
                        %{$npcs{$ID}{'pos'}} = %coords;
                        printc("nn", "<人物> ", "存在: $npcs{$ID}{'name'} - ($npcs{$ID}{'binID'})\n");

                } else {
                        printc("gn", "->$switch ", "Unknown Exists: $type - ".unpack("L*",$ID)."\n") if $config{'debug'};
                }

        } elsif ($switch eq "0079" || $switch eq "01D9") {
                ##0079 <ID>.l <speed>.w <opt1>.w <opt2>.w <option>.w <class>.w <hair>.w <weapon>.w <head option bottom>.w <sheild>.w <head option top>.w <head option mid>.w <hair color>.w ?.w <head dir>.w <guild>.l <emblem>.l <manner>.w <karma>.B <sex>.B <X_Y_dir>.3B ?.B ?.B <Lv>.B
                #01d9 <ID>.l <speed>.w <opt1>.w <opt2>.w <option>.w <class>.w <hair>.w <item id1>.w <item id2>.w.<head option bottom>.w <head option top>.w <head option mid>.w <hair color>.w ?.w <head dir>.w <guild>.l <emblem>.l <manner>.w <karma>.B <sex>.B <X_Y_dir>.3B ?.B ?.B <Lv>.B ?.B
                #For boiling Character inside the indicatory range of teleport and the like, it faces and is not attached Character information?
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                my $ID = substr($msg, 2, 4);
                makeCoords(\%coords, substr($msg, 46, 3));
                my $type = unpack("S*",substr($msg, 14,  2));
                my $sex = unpack("C*",substr($msg, 45,  1));
		my $param1 = unpack("S1", substr($msg, 8, 2));
		my $param2 = unpack("S1", substr($msg, 10, 2));
		my $param3 = unpack("S1", substr($msg, 12, 2));
                if ($jobs_lut{$type}) {
                        if (!%{$players{$ID}}) {
                                binAdd(\@playersID, $ID);
                                $players{$ID}{'appear_time'} = time;
                                $players{$ID}{'jobID'} = $type;
                                $players{$ID}{'sex'} = $sex;
                                $players{$ID}{'name'} = "Unknown";
                                $players{$ID}{'binID'} = binFind(\@playersID, $ID);
                                $players{$ID}{'nameID'} = unpack("L1", $ID);
                                if ($aid_rlut{$players{$ID}{'nameID'}}{'avoid'}) {
                                        %{$players{$ID}{'pos'}} = %coords;
                                        %{$players{$ID}{'pos_to'}} = %coords;
                                        binAdd(\@avoidID, $ID);
                                }
                        }
                        %{$players{$ID}{'pos'}} = %coords;
                        %{$players{$ID}{'pos_to'}} = %coords;
                        setStatus($ID, $param1, $param2, $param3);
                        printc("gn", "->$switch ", "Player Connected: $players{$ID}{'name'}($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n") if ($config{'debug'});

                } else {
                        printc("gn", "->$switch ", "Unknown Connected: $type - ".getHex($ID)."\n") if $config{'debug'};
                }

        } elsif ($switch eq "007A") {
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);

        } elsif ($switch eq "007B" || $switch eq "01DA") {
                #007b <ID> l <speed> w <opt1> w <opt2> w <option> w <class> w <hair> w <weapon> w <head option bottom> w <server tick> l <shield> w <head option top> w <head option mid> w <hair color> w? W <head dir> w <guild> l <emblem> l <manner> w <karma> B <sex> B <X_Y_X_Y> 5B? B? B? B <Lv> B
                #01da <ID>.l <speed>.w <opt1>.w <opt2>.w <option>.w <class>.w <hair>.<item id1>.w <item id2>.w <head option bottom>.w <server tick>.l <head option top>.w <head option mid>.w <hair color>.w ?.w <head dir>.w <guild>.l <emblem>.l <manner>.w <karma>.B <sex>.B <X_Y_X_Y>.5B ?.B ?.B ?.B <Lv>.B ?.B
                #Information of Character movement inside indicatory range
                $conState = 5 if ($conState != 4 && $xKore);
                my $ID = substr($msg, 2, 4);
                makeCoords(\%coordsFrom, substr($msg, 50, 3));
                makeCoords2(\%coordsTo, substr($msg, 52, 3));
                my $type = unpack("S*",substr($msg, 14,  2));
                my $pet = unpack("C*",substr($msg, 16,  1));
                my $sex = unpack("C*",substr($msg, 49,  1));
		my $param1 = unpack("S1", substr($msg, 8, 2));
		my $param2 = unpack("S1", substr($msg, 10, 2));
		my $param3 = unpack("S1", substr($msg, 12, 2));
                if ($type >= 1000 && $type < 4000) {
                        if ($pet) {
                                if (!%{$pets{$ID}}) {
                                        $pets{$ID}{'appear_time'} = time;
                                        $display = ($monsters_lut{$type} ne "")
                                                        ? $monsters_lut{$type}
                                                        : "Unknown ".$type;
                                        binAdd(\@petsID, $ID);
                                        $pets{$ID}{'nameID'} = $type;
                                        $pets{$ID}{'name'} = $display;
                                        $pets{$ID}{'name_given'} = "Unknown";
                                        $pets{$ID}{'binID'} = binFind(\@petsID, $ID);
                                }
                                %{$pets{$ID}{'pos'}} = %coords;
                                %{$pets{$ID}{'pos_to'}} = %coords;
                                if (%{$monsters{$ID}}) {
                                        binRemove(\@monstersID, $ID);
                                        undef %{$monsters{$ID}};
                                }
                                printc("gn", "->$switch ", "Pet Moved: $pets{$ID}{'name'}($pets{$ID}{'binID'})\n") if ($config{'debug'});
                        } else {
                                if (!%{$monsters{$ID}}) {
                                        binAdd(\@monstersID, $ID);
                                        $monsters{$ID}{'appear_time'} = time;
                                        $monsters{$ID}{'nameID'} = $type;
                                        $display = ($monsters_lut{$type} ne "")
                                                ? $monsters_lut{$type}
                                                : "Unknown ".$type;
                                        $monsters{$ID}{'nameID'} = $type;
                                        $monsters{$ID}{'name'} = $display;
                                        $monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
                                        printc("gn", "->$switch ", "Monster Appeared: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n") if $config{'debug'};
	                                %{$monsters{$ID}{'pos_to'}} = %coordsTo;
					mvpMonsterFound($ID);
                                } else {
                                	mvpNoticeSent("moved", $monsters{$ID}{'name'}, $field{'name'}, $monsters{$ID}{'pos_to'}{'x'}, $monsters{$ID}{'pos_to'}{'y'}) if ($monsters{$ID}{'mvp'});
                                }
                                %{$monsters{$ID}{'pos'}} = %coordsFrom;
                                %{$monsters{$ID}{'pos_to'}} = %coordsTo;
                                setStatus($ID, $param1, $param2, $param3);
                                printc("gn", "->$switch ", "Monster Moved: $monsters{$ID}{'name'}($monsters{$ID}{'binID'})\n") if ($config{'debug'} >= 2);
                        }
                } elsif ($jobs_lut{$type}) {
                        if (!%{$players{$ID}}) {
                                binAdd(\@playersID, $ID);
                                $players{$ID}{'appear_time'} = time;
                                $players{$ID}{'sex'} = $sex;
                                $players{$ID}{'jobID'} = $type;
                                $players{$ID}{'name'} = "Unknown";
                                $players{$ID}{'binID'} = binFind(\@playersID, $ID);
                                $players{$ID}{'nameID'} = unpack("L1", $ID);
                                if ($aid_rlut{$players{$ID}{'nameID'}}{'avoid'}) {
                                        %{$players{$ID}{'pos'}} = %coords;
                                        %{$players{$ID}{'pos_to'}} = %coords;
                                        binAdd(\@avoidID, $ID);
                                }
                                printc("gn", "->$switch ", "Player Appeared: $players{$ID}{'name'}($players{$ID}{'binID'}) $sex_lut{$sex} $jobs_lut{$type}\n") if $config{'debug'};
                        }
                        %{$players{$ID}{'pos'}} = %coordsFrom;
                        %{$players{$ID}{'pos_to'}} = %coordsTo;
                        setStatus($ID, $param1, $param2, $param3);
                        printc("gn", "->$switch ", "Player Moved: $players{$ID}{'name'}($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n") if ($config{'debug'} >= 2);
                } else {
                        printc("gn", "->$switch ", "Unknown Moved: $type - ".getHex($ID)."\n") if $config{'debug'};
                }

        } elsif ($switch eq "007C") {
                #007c <ID> l <speed> w? 6w <class> w? 7w <X_Y> 3B? 2B
                #Character information inside the indicatory range for NPC
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                my $ID = substr($msg, 2, 4);
                makeCoords(\%coords, substr($msg, 36, 3));
                my $type = unpack("S*",substr($msg, 20,  2));
                my $sex = unpack("C*",substr($msg, 35,  1));
                if ($type >= 1000 && $type < 4000) {
                        if (!%{$monsters{$ID}}) {
                                binAdd(\@monstersID, $ID);
                                $monsters{$ID}{'nameID'} = $type;
                                $monsters{$ID}{'appear_time'} = time;
                                $display = ($monsters_lut{$monsters{$ID}{'nameID'}} ne "")
                                                ? $monsters_lut{$monsters{$ID}{'nameID'}}
                                                : "Unknown ".$monsters{$ID}{'nameID'};
                                $monsters{$ID}{'name'} = $display;
                                $monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
	                        %{$monsters{$ID}{'pos_to'}} = %coords;
				mvpMonsterFound($ID);
                        }
                        %{$monsters{$ID}{'pos'}} = %coords;
                        %{$monsters{$ID}{'pos_to'}} = %coords;
                        printc("gn", "->$switch ", "Monster Spawned: $monsters{$ID}{'name'}($monsters{$ID}{'binID'})\n") if ($config{'debug'});
                } elsif ($jobs_lut{$type}) {
                        if (!%{$players{$ID}}) {
                                binAdd(\@playersID, $ID);
                                $players{$ID}{'jobID'} = $type;
                                $players{$ID}{'sex'} = $sex;
                                $players{$ID}{'name'} = "Unknown";
                                $players{$ID}{'appear_time'} = time;
                                $players{$ID}{'binID'} = binFind(\@playersID, $ID);
                                $players{$ID}{'nameID'} = unpack("L1", $ID);
                                if ($aid_rlut{$players{$ID}{'nameID'}}{'avoid'}) {
                                        %{$players{$ID}{'pos'}} = %coords;
                                        %{$players{$ID}{'pos_to'}} = %coords;
                                        binAdd(\@avoidID, $ID);
                                }
                        }
                        %{$players{$ID}{'pos'}} = %coords;
                        %{$players{$ID}{'pos_to'}} = %coords;
                        printc("gn", "->$switch ", "Player Spawned: $players{$ID}{'name'}($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n") if ($config{'debug'});
                } else {
                        printc("gn", "->$switch ", "Unknown Spawned: $type - ".getHex($ID)."\n") if $config{'debug'};
                }

        } elsif ($switch eq "007F") {
                #007f <server tick> l
                #Server side 1ms timer transmission
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                my $time = unpack("L1",substr($msg, 2, 4));
                printc("gn", "->$switch ", "Recieved Sync: $time\n") if ($config{'debug'} >= 2);
                $timeout{'play'}{'time'} = time;

        } elsif ($switch eq "0080") {
                #0080 <ID> l <type> B
                #Character Status (include other)
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                my $ID = substr($msg, 2, 4);
                my $type = unpack("C1",substr($msg, 6, 1));
                if ($ID eq $accountID) {
                        printc("wy", "<信息> ", "你已经死亡了。\n");
                        chatLog("m", "你已经死亡了。 $field{'name'} ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        $chars[$config{'char'}]{'dead'} = 1;
                        $chars[$config{'char'}]{'dead_time'} = time;

                        my $stuff = @ai_seq_args;
                        my $type = ($AI) ? "On" : "Off";
                	($map_string) = $map_name =~ /([\s\S]*)\.gat/;
			my @stuff = ai_getAggressives();
                        my $message;
			for ($i = 0; $i < @stuff; $i++) {
				$monsters{$stuff[$i]}{'dmgToYou'} = 0 if (!$monsters{$stuff[$i]}{'dmgToYou'});
				$message .= " | " if ($message ne "");
				$message .= "$monsters{$stuff[$i]}{'name'}($monsters{$stuff[$i]}{'binID'}) $monsters{$stuff[$i]}{'dmgToYou'}";
                        }
                        printc("nyn", "-----------", "死亡信息", "-----------\n");
                        printc("wn", "AI   : ", "@ai_seq | $stuff | $type\n");
                        printc("wn", "位置 : ", "$maps_lut{$map_string.'.rsw'}($map_string) ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");                        
                        printc("wn", "怪物 : ", "$message\n");                        
                        printc("n", "------------------------------\n");

                        chatLog("d", "-----------死亡信息-----------\n");
                        chatLog("d", "AI   : @ai_seq | $stuff | $type\n");
                        chatLog("d", "位置 : $maps_lut{$map_string.'.rsw'}($map_string) ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");                        
                        chatLog("d", "怪物 : $message\n");                        
                        chatLog("d", "------------------------------\n");

                } elsif (%{$monsters{$ID}}) {
                        %{$monsters_old{$ID}} = %{$monsters{$ID}};
                        $monsters_old{$ID}{'gone_time'} = time;
                        if ($type == 0) {
                                printc("gn", "->$switch ", "Monster Disappeared: $monsters{$ID}{'name'}($monsters{$ID}{'binID'})\n") if $config{'debug'};
                                if ($monsters{$ID}{'mvp'}) {
                                        chatLog("m", "消失: $monsters{$ID}{'name'} $field{'name'} ($monsters{$ID}{'pos_to'}{'x'},$monsters{$ID}{'pos_to'}{'y'})\n");
                                        mvpNoticeSent("disappeared", $monsters{$ID}{'name'}, $field{'name'}, $monsters{$ID}{'pos_to'}{'x'}, $monsters{$ID}{'pos_to'}{'y'});
                                }
                                $monsters_old{$ID}{'disappeared'} = 1;
                                ai_changedByMonster("disappeared", $ID);
                        } elsif ($type == 1) {
                                printc("gn", "->$switch ", "Monster Died: $monsters{$ID}{'name'}($monsters{$ID}{'binID'})\n") if $config{'debug'};
                                $monsters_old{$ID}{'dead'} = 1;
                                if ($monsters{$ID}{'mvp'}) {
                                        chatLog("m", "死亡: $monsters{$ID}{'name'} $field{'name'} ($monsters{$ID}{'pos_to'}{'x'},$monsters{$ID}{'pos_to'}{'y'})\n");
                                        mvpTimeLog($ID);
                                        mvpNoticeSent("dead", $monsters{$ID}{'name'},$field{'name'}, $monsters{$ID}{'pos_to'}{'x'}, $monsters{$ID}{'pos_to'}{'y'});
                                }
                                ai_changedByMonster("dead", $ID);
                        } elsif ($type == 3) {
                                printc("gn", "->$switch ", "Monster Teleported: $monsters{$ID}{'name'}($monsters{$ID}{'binID'})\n") if $config{'debug'};
                                if ($monsters{$ID}{'mvp'}) {
                                        chatLog("m", "瞬移: $monsters{$ID}{'name'} $field{'name'} ($monsters{$ID}{'pos_to'}{'x'},$monsters{$ID}{'pos_to'}{'y'})\n");
                                        mvpNoticeSent("teleported", $monsters{$ID}{'name'}, $field{'name'}, $monsters{$ID}{'pos_to'}{'x'}, $monsters{$ID}{'pos_to'}{'y'});
                                }
                                $monsters_old{$ID}{'teleported'} = 1;
                                ai_changedByMonster("teleported", $ID);                                
                        }
                        binRemove(\@monstersID, $ID);
                        undef %{$monsters{$ID}};
                } elsif (%{$players{$ID}}) {
                        if ($type == 0) {
                                printc("gn", "->$switch ", "Player Disappeared: $players{$ID}{'name'}($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n") if $config{'debug'};
                                $players_old{$ID}{'disappeared'} = 1;
                        } elsif ($type == 1) {
                                printc("wn", "<玩家> ", "玩家死亡: $players{$ID}{'name'}($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n");
                                $players{$ID}{'dead'} = 1;
                                if ($config{'partyAutoResurrect'} > 0 && $chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'} ne "") {
                                        $chars[$config{'char'}]{'party'}{'users'}{$ID}{'dead_time'} = time;
                                        ai_stateResetParty($ID);
                                }
                        } elsif ($type == 2) {
                                printc("gn", "->$switch ", "Player Disconnected: $players{$ID}{'name'}\n") if $config{'debug'};
                                $players_old{$ID}{'disconnected'} = 1;
                        } elsif ($type == 3) {
                                printc("gn", "->$switch ", "Player Teleported: $players{$ID}{'name'}($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n") if $config{'debug'};
                                $players_old{$ID}{'teleported'} = 1;
                        }
                        if ($type != 1) {
                                %{$players_old{$ID}} = %{$players{$ID}};
                                $players_old{$ID}{'gone_time'} = time;
                                binRemove(\@playersID, $ID);
                                binRemove(\@avoidID, $ID);
                                undef %{$players{$ID}};
                                for (my $i = 0; $i < @partyUsersID; $i++) {
                                        next if ($partyUsersID[$i] eq "");
                                        undef %{$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}} if ($ID eq $_);
                                        ai_stateResetParty($ID);
                                }
                        }
                        if (%{$venderLists{$ID}}) {
                                binRemove(\@venderListsID, $ID);
                                undef %{$venderLists{$ID}};
                        }
                        if (%{$chatRooms{$ID}}) {
                        	binRemove(\@chatRoomsID, $ID);
                        	undef %{$chatRooms{$ID}};
                        }
                        
                } elsif (%{$players_old{$ID}}) {
                        if ($type != 1) {
                                printc("gn", "->$switch ", "Player Disconnected: $players_old{$ID}{'name'}\n") if $config{'debug'};
                                $players_old{$ID}{'disconnected'} = 1;
                        }
                } elsif (%{$portals{$ID}}) {
                        printc("gn", "->$switch ", "Portal Disappeared: $portals{$ID}{'name'}($portals{$ID}{'binID'})\n") if ($config{'debug'});
                        %{$portals_old{$ID}} = %{$portals{$ID}};
                        $portals_old{$ID}{'disappeared'} = 1;
                        $portals_old{$ID}{'gone_time'} = time;
                        binRemove(\@portalsID, $ID);
                        undef %{$portals{$ID}};
                } elsif (%{$npcs{$ID}}) {
                        printc("gn", "->$switch ", "NPC Disappeared: $npcs{$ID}{'name'}($npcs{$ID}{'binID'})\n") if ($config{'debug'});
                        %{$npcs_old{$ID}} = %{$npcs{$ID}};
                        $npcs_old{$ID}{'disappeared'} = 1;
                        $npcs_old{$ID}{'gone_time'} = time;
                        binRemove(\@npcsID, $ID);
                        undef %{$npcs{$ID}};
                } elsif (%{$pets{$ID}}) {
                        undef %{$chars[$config{'char'}]{'pet'}} if ($chars[$config{'char'}]{'pet'}{'ID'} == $ID);
                        printc("gn", "->$switch ", "Pet Disappeared: $pets{$ID}{'name'}($pets{$ID}{'binID'})\n") if ($config{'debug'});
                        binRemove(\@petsID, $ID);
                        undef %{$pets{$ID}};
                } else {
                        printc("gn", "->$switch ", "Unknown Disappeared: ".getHex($ID)."\n") if $config{'debug'};
                }

        } elsif ($switch eq "0081") {
                #0081 <type> B
                #Login Failure 2
                my $type = unpack("C1", substr($msg, 2, 1));
                $conState = 1;
                undef $conState_tries;
                $timeout_ex{'master'}{'time'} = time;
                $timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
                killConnection(\$remote_socket) if (!$xKore);
                if ($type == 2) {
                        printc("yr", "<系统> ", "相同的账号角色 已经登录了\n");
                        chatLog("x", "相同的账号角色 已经登录了\n");
                        if ($config{'dcOnDualLogin'} == 1) {
                                quit();
                        } elsif ($config{'dcOnDualLogin'} >= 2) {
                                printc("yr", "<系统> ", "与服务器联机中断，等待 $config{'dcOnDualLogin'} 秒后重新连接...\n");
                                $timeout_ex{'master'}{'timeout'} = $config{'dcOnDualLogin'};
                        }
                } elsif ($type == 3) {
                        printc("yr", "<系统> ", "无法与服务器同步\n");
                        chatLog("x", "无法与服务器同步\n");
                } elsif ($type == 5) {
                        printc("yr", "<系统> ", "你年龄不满18岁，结束游戏。\n");
                        chatLog("x", "你年龄不满18岁，结束游戏。\n");
                } elsif ($type == 6) {
                        printc("yr", "<系统> ", "储值点数已用完，结束游戏。\n");
                        chatLog("x", "储值点数已用完，结束游戏。\n");
                } elsif ($type == 8) {
                        printc("yr", "<系统> ", "请稍后联机\n");
                } elsif ($type == 15) {
                        printc("yr", "<系统> ", "您已被管理人员 ,强制结束游戏。\n");
                        chatLog("gm", "您已被管理人员 ,强制结束游戏。\n");
                        $sleeptime = int($config{'avoidGM_reconnect'} + rand(1800) + 1800);
                        $timeout_ex{'master'}{'timeout'} = $sleeptime;
                }


        } elsif ($switch eq "0087") {
                #0087 <server tick> l <X_Y_X_Y> 5B? B
                #Movement response
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                makeCoords(\%coordsFrom, substr($msg, 6, 3));
                makeCoords2(\%coordsTo, substr($msg, 8, 3));
                $speed = unpack("C1", substr($msg, 11, 1));
                %{$chars[$config{'char'}]{'pos'}} = %coordsFrom;
                %{$chars[$config{'char'}]{'pos_to'}} = %coordsTo;
                printc("gn", "->$switch ", "Recv Move To: $coordsTo{'x'}, $coordsTo{'y'} From: $coordsFrom{'x'}, $coordsFrom{'y'} Speed: $speed ms\n") if $config{'debug'};
                if ($chars[$config{'char'}]{'pos'}{'x'} != $chars[$config{'char'}]{'pos_to'}{'x'} || $chars[$config{'char'}]{'pos'}{'y'} != $chars[$config{'char'}]{'pos_to'}{'y'}) {
	                $chars[$config{'char'}]{'time_move'} = time;
        	        $chars[$config{'char'}]{'time_move_calc'} = distance(\%{$chars[$config{'char'}]{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}) * $config{'seconds_per_block'};
        	}

        } elsif ($switch eq "0088") {
                #0088 <ID> l <X> w <Y> w
                # Long distance attack solution
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                my $ID = substr($msg, 2, 4);
                undef %coords;
                $coords{'x'} = unpack("S1", substr($msg, 6, 2));
                $coords{'y'} = unpack("S1", substr($msg, 8, 2));
                if ($ID eq $accountID) {
                        %{$chars[$config{'char'}]{'pos'}} = %coords;
                        %{$chars[$config{'char'}]{'pos_to'}} = %coords;
                        printc("gn", "->$switch ", "Your coordinates changed to $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n") if $config{'debug'};
                        aiRemove("move");
                } elsif (%{$monsters{$ID}}) {
                        %{$monsters{$ID}{'pos'}} = %coords;
                        %{$monsters{$ID}{'pos_to'}} = %coords;
                } elsif (%{$players{$ID}}) {
                        %{$players{$ID}{'pos'}} = %coords;
                        %{$players{$ID}{'pos_to'}} = %coords;
                } else {
                        printc("gn", "->$switch ", "Coordinates Changed ".getHex($ID)." ($coords{'x'},$coords{'y'})\n") if $config{'debug'};
                }

        } elsif ($switch eq "008A") {
                #008a <src ID> l <dst ID> l <server tick> l <src speed> l <dst speed> l <param1> w <param2> w <type> B <param3> w
                #malee attack
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                my $ID1 = substr($msg, 2, 4);
                my $ID2 = substr($msg, 6, 4);
                my $standing = unpack("C1", substr($msg, 26, 2)) - 2;
                my $damage = unpack("s1", substr($msg, 22, 2));
                my $type = unpack("C1",substr($msg,26,1));
                my $damage1 = unpack("s1", substr($msg, 27, 2));
                my $totaldamage = $damage;
                if ($ID1 eq $accountID && $damage != 0 && $damage1 > 0) {
                        $totaldamage += $damage1;
                }
                updateDamageTables($ID1, $ID2, $totaldamage);
                if ($ID1 eq $accountID) {
                        if (%{$monsters{$ID2}}) {
                                printAttack("a", $ID1, $ID2, $damage, $damage1, $standing, "", "");
                        } elsif (%{$items{$ID2}}) {
                                printc("gn", "->$switch ", "You pick up Item: $items{$ID2}{'name'}($items{$ID2}{'binID'})\n") if $config{'debug'};
                                $items{$ID2}{'takenBy'} = $accountID;
                        } elsif ($ID2 == 0) {
                                if ($standing == 0) {
                                        $chars[$config{'char'}]{'sitting'} = 1;
                                        printc("wc", "<状态> ", "已变成坐下状态\n");
                                } elsif ($standing == 1) {
                                        $chars[$config{'char'}]{'sitting'} = 0;
                                        printc("wc", "<状态> ", "已变成站立状态\n");
                                }
                        }
                } elsif ($ID2 eq $accountID) {
                        if (%{$monsters{$ID1}}) {
                                printAttack("a", $ID1, $ID2, $damage, 0, 0, "", "");
                        }
                        undef $chars[$config{'char'}]{'time_cast'};
                        useTeleport(1) if ($monsters{$ID1}{'name'} eq "");
                } elsif (%{$monsters{$ID1}}) {
                        if (%{$players{$ID2}}) {
                                printAttack("a", $ID1, $ID2, $damage, 0, 0, "", "") if ($config{'debug'});
                        }
                } elsif (%{$players{$ID1}}) {
                        if (%{$monsters{$ID2}}) {
                                printAttack("a", $ID1, $ID2, $damage, 0, 0, "", "") if ($config{'debug'});
                        } elsif (%{$items{$ID2}}) {
                                $items{$ID2}{'takenBy'} = $ID1;
                                printc("gn", "->$switch ", "Player $players{$ID1}{'name'}($players{$ID1}{'binID'}) picks up Item $items{$ID2}{'name'}($items{$ID2}{'binID'})\n") if ($config{'debug'});
                        } elsif ($ID2 == 0) {
                                if ($standing == 0) {
                                        $players{$ID1}{'sitting'} = 1;
                                        printc("gn", "->$switch ", "Player is Sitting: $players{$ID1}{'name'}($players{$ID1}{'binID'})\n") if $config{'debug'};
                                } elsif ($standing == 1) {
                                        $players{$ID1}{'sitting'} = 0;
                                        printc("gn", "->$switch ", "Player is Standing: $players{$ID1}{'name'}($players{$ID1}{'binID'})\n") if $config{'debug'};
                                }
                        }
                } else {
                        printc("gn", "->$switch ", "Unknown ".getHex($ID1)." attacks ".getHex($ID2)." - Dmg: $dmgdisplay\n") if $config{'debug'};
                }

        } elsif ($switch eq "008D") {
                #008d <len> w <ID> l <str>.? B
                #The speech reception ID. The inside of the chat becomes one for speech within the chat
                my $ID = substr($msg, 4, 4);
                my $chat = substr($msg, 8, $msg_size - 8);
                $chat =~ s/\000//g;
                my ($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)/;
                $chatMsgUser =~ s/ $//;
                $ai_cmdQue[$ai_cmdQue]{'type'} = "c";
                $ai_cmdQue[$ai_cmdQue]{'ID'} = $ID;
                $ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser;
                $ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg;
                $ai_cmdQue[$ai_cmdQue]{'time'} = time;
                $ai_cmdQue++;
                printc("gwn", "<公聊> ", $chat, "\n") if (!$config{'hideMsg_chatPublic'});
                chatLog("c", $chat."\n") if (!$config{'hideChatPublic'});               
		sendMsgToWindow("008D".chr(1).$chatMsgUser.chr(1).$chatMsg) if ($yelloweasy);
                avoidChat($ID, $chatMsgUser, "");

        } elsif ($switch eq "008E") {
                #008e <len> w <str>.? B
                #Your own speech reception. The inside of the chat becomes one for speech within the chat
                my $chat = substr($msg, 4, $msg_size - 4);
                $chat =~ s/\000//g;
                ($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)/;
                chatLog("c", $chat."\n");
                printc("gcn", "<公聊> ", $chat, "\n");
                sendMsgToWindow("008D".chr(1).$chatMsgUser.chr(1).$chatMsg) if ($yelloweasy);

        } elsif ($switch eq "0091") {
                #0091 <map name> 16B <X> w <Y> w
                #Business such as movement, teleport and fly between maps inside
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                initMapChangeVars();
                for ($i = 0; $i < @ai_seq; $i++) {
                        ai_setMapChanged($i);
                }
                ($map_name) = substr($msg, 2, 16) =~ /([\s\S]*?)\000/;
                ($ai_v{'temp'}{'map'}) = $map_name =~ /([\s\S]*)\./;
                if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
                        getField("map/$ai_v{'temp'}{'map'}.fld", \%field);
      			$timeout{'ai_attack_auto'}{'time'} = time + 10 if ($config{'lockMap'} ne "" && $ai_v{'temp'}{'map'} ne $config{'lockMap'});
                        if ($xKore) {
                                $conState = 4;
                                printc("yn", "<系统> ", "等待读入地图...\n");
                                $loadingMap = 1;
                        }
                }
                $coords{'x'} = unpack("S1", substr($msg, 18, 2));
                $coords{'y'} = unpack("S1", substr($msg, 20, 2));
                %{$chars[$config{'char'}]{'pos'}} = %coords;
                %{$chars[$config{'char'}]{'pos_to'}} = %coords;
                printc("nn", "<地图> ", "位置: $ai_v{'temp'}{'map'} ($chars[$config{'char'}]{'pos'}{'x'},$chars[$config{'char'}]{'pos'}{'y'})\n") if ($config{'mode'});
                printc("gn", "->$switch ", "Your Coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n") if $config{'debug'};
                print "Sending Map Loaded\n" if ($config{'debug'} && !$xKore);
                sendMapLoaded(\$remote_socket) if (!$xKore);
                if (!$sendFlyMap && $mapip_lut{$ai_v{'temp'}{'map'}.'.rsw'}{'ip'} ne $map_ip) {
                        mapipModify($ai_v{'temp'}{'map'}.'.rsw', $map_ip);
                }

        } elsif ($switch eq "0092") {
                #0092 <map name> 16B <X> w <Y> w <IP> l <port> w
                #Movement between
                $conState = 4;
                undef $conState_tries;
                for ($i = 0; $i < @ai_seq; $i++) {
                        ai_setMapChanged($i);
                }
                ($map_name) = substr($msg, 2, 16) =~ /([\s\S]*?)\000/;
                ($ai_v{'temp'}{'map'}) = $map_name =~ /([\s\S]*)\./;
                if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
                        getField("map/$ai_v{'temp'}{'map'}.fld", \%field);
			$timeout{'ai_attack_auto'}{'time'} = time + 10 if ($config{'lockMap'} ne "" && $ai_v{'temp'}{'map'} ne $config{'lockMap'});
                }
                $map_ip = makeIP(substr($msg, 22, 4));
                $map_port = unpack("S1", substr($msg, 26, 2));
                print "-----Map Change Info------\n";
                print sprintf("MAP Name : %-20s\n",$map_name);
                print sprintf("MAP IP   : %-20s\n",$map_ip);
                print sprintf("MAP Port : %-20s\n",$map_port);
                print "--------------------------\n";
                printc("yn", "<系统> ", "关闭与地图服务器的连接\n");
                killConnection(\$remote_socket) if (!$xKore);
                initConnectVars() if ($xKore);
                if (!$sendFlyMap && $mapip_lut{$ai_v{'temp'}{'map'}.'.rsw'}{'ip'} ne $map_ip) {
                        mapipModify($ai_v{'temp'}{'map'}.'.rsw', $map_ip);
                }

        } elsif ($switch eq "0095") {
                #0095 <ID> l <nick> 24B
                #Answer to the 0094 of NPC and guild not yet post PC
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                my $ID = substr($msg, 2, 4);
                my $binID;
                if (%{$players{$ID}}) {
                        ($players{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
                        if ($config{'debug'} >= 2) {
                                $binID = binFind(\@playersID, $ID);
                                printc("gn", "->$switch ", "Player Info: $players{$ID}{'name'}($binID)\n");
                        }
                        if ($avoidlist_rlut{$players{$ID}{'name'}}) {
                                $players{$ID}{'nameID'} = unpack("L1", $ID);
                                binAdd(\@avoidID, $ID);
                                $aid_rlut{$players{$ID}{'nameID'}}{'avoid'} = 1;
                        }
                }
                if (%{$monsters{$ID}}) {
                        ($monsters{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
                        if ($config{'debug'} >= 2) {
                                $binID = binFind(\@monstersID, $ID);
                                printc("gn", "->$switch ", "Monster Info: $monsters{$ID}{'name'}($binID)\n");
                        }
                        if ($monsters_lut{$monsters{$ID}{'nameID'}} eq "") {
                                $monsters_lut{$monsters{$ID}{'nameID'}} = $monsters{$ID}{'name'};
                                updateMonsterLUT("data/monsters.txt", $monsters{$ID}{'nameID'}, $monsters{$ID}{'name'});
                        }
                }
                if (%{$npcs{$ID}}) {
                        ($npcs{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
                        if ($config{'debug'} >= 2) {
                                $binID = binFind(\@npcsID, $ID);
                                printc("gn", "->$switch ", "NPC Info: $npcs{$ID}{'name'}($binID)\n");
                        }
                        # ICE Start - NPC ID
                        if ($config{'npcRecord'} && !%{$npcs_lut{$npcs{$ID}{'nameID'}}}) {
                                $npcs_lut{$npcs{$ID}{'nameID'}}{'name'} = $npcs{$ID}{'name'};
                                $npcs_lut{$npcs{$ID}{'nameID'}}{'map'} = $field{'name'};
                                %{$npcs_lut{$npcs{$ID}{'nameID'}}{'pos'}} = %{$npcs{$ID}{'pos'}};
                                updateNPCLUT("data/npcs.txt", $npcs{$ID}{'nameID'}, $field{'name'}, $npcs{$ID}{'pos'}{'x'}, $npcs{$ID}{'pos'}{'y'}, $npcs{$ID}{'name'});
                        }
                        # ICE End
                }
                if (%{$pets{$ID}}) {
                        ($pets{$ID}{'name_given'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
                        if ($config{'debug'} >= 2) {
                                $binID = binFind(\@petsID, $ID);
                                printc("gn", "->$switch ", "Pet Info: $pets{$ID}{'name_given'}($binID)\n");
                        }
                }

        } elsif ($switch eq "0097") {
                #0097 <len> w <nick> 24B <message>.? B
                #Whisper reception
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                decrypt(\$newmsg, substr($msg, 28, length($msg)-28));
                $msg = substr($msg, 0, 28).$newmsg;
                my ($privMsgUser) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
                my $privMsg = substr($msg, 28, $msg_size - 29);
                if ($privMsgUser ne "" && binFind(\@privMsgUsers, $privMsgUser) eq "") {
                        $privMsgUsers[@privMsgUsers] = $privMsgUser;
                }
                $ai_cmdQue[$ai_cmdQue]{'type'} = "pm";
                $ai_cmdQue[$ai_cmdQue]{'user'} = $privMsgUser;
                $ai_cmdQue[$ai_cmdQue]{'msg'} = $privMsg;
                $ai_cmdQue[$ai_cmdQue]{'time'} = time;
                $ai_cmdQue++;
                chatLog("pm", "(From: $privMsgUser) : $privMsg\n");
                printc("gyn", "<私聊> ", "(From: $privMsgUser) : $privMsg", "\n");
                sendMsgToWindow("0097".chr(1).$privMsgUser.chr(1).$privMsg) if ($yelloweasy);
                avoidChat("", $privMsgUser, $privMsg);

        } elsif ($switch eq "0098") {
                #0098 <type> B
                #Whisper Tranmis status
                my $type = unpack("C1",substr($msg, 2, 1));
                if ($type == 0) {
                        printc("gyn", "<私聊> ", "(To $lastpm[0]{'user'}) : $lastpm[0]{'msg'}", "\n");
                        chatLog("pm", "(To: $lastpm[0]{'user'}) : $lastpm[0]{'msg'}\n");
                        sendMsgToWindow("0098".chr(1).$lastpm[0]{'user'}.chr(1).$lastpm[0]{'msg'}) if ($yelloweasy);
                } elsif ($type == 1) {
                        printc("yr", "<系统> ", "$lastpm[0]{'user'} 玩家不在线\n");
                } elsif ($type == 2) {
                        printc("yr", "<系统> ", "拒绝接收所有悄悄话讯息\n");
                }
                shift @lastpm;

        } elsif ($switch eq "009A") {
                #009a <len> w <message>.? B
                #Voice of the heaven from GM
                my $chat = substr($msg, 4, $msg_size - 4);
                chatLog("s", $chat."\n");
                printc("gyn", "<公告> ", $chat, "\n");
                avoidChat("", "", $chat);

        } elsif ($switch eq "009C") {
                #009c <ID> l <head dir> w <dir> B
                #The body of ID & direction modification of head
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                my $ID = substr($msg, 2, 4);
                my $body = unpack("C1",substr($msg, 8, 1));
                my $head = unpack("C1",substr($msg, 6, 1));
                if ($ID eq $accountID) {
                        $chars[$config{'char'}]{'look'}{'head'} = $head;
                        $chars[$config{'char'}]{'look'}{'body'} = $body;
                        printc("gn", "->$switch ", "You look at $chars[$config{'char'}]{'look'}{'body'}, $chars[$config{'char'}]{'look'}{'head'}\n") if ($config{'debug'} >= 2);
                } elsif (%{$players{$ID}}) {
                        $players{$ID}{'look'}{'head'} = $head;
                        $players{$ID}{'look'}{'body'} = $body;
                        printc("gn", "->$switch ", "Player $players{$ID}{'name'}($players{$ID}{'binID'}) looks at $players{$ID}{'look'}{'body'}, $players{$ID}{'look'}{'head'}\n") if ($config{'debug'} >= 2);
                } elsif (%{$monsters{$ID}}) {
                        $monsters{$ID}{'look'}{'head'} = $head;
                        $monsters{$ID}{'look'}{'body'} = $body;
                        printc("gn", "->$switch ", "Monster $monsters{$ID}{'name'}($monsters{$ID}{'binID'}) looks at $monsters{$ID}{'look'}{'body'}, $monsters{$ID}{'look'}{'head'}\n") if ($config{'debug'} >= 2);
                }

        } elsif ($switch eq "009D") {
                #009d <ID> l <item ID> w <identify flag> B <X> w <Y> w <amount> w <subX> B <subY> B
                #When the floor item goes inside the picture with such as movement,
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                my $ID = substr($msg, 2, 4);
                my $type = unpack("S1",substr($msg, 6, 2));
                my $x = unpack("S1", substr($msg, 9, 2));
                my $y = unpack("S1", substr($msg, 11, 2));
                my $amount = unpack("S1", substr($msg, 13, 2));
                if (!%{$items{$ID}}) {
                        binAdd(\@itemsID, $ID);
                        $items{$ID}{'appear_time'} = time;
                        $items{$ID}{'amount'} = $amount;
                        $items{$ID}{'nameID'} = $type;
                        $display = ($items_lut{$items{$ID}{'nameID'}} ne "")
                                ? $items_lut{$items{$ID}{'nameID'}}
                                : "Unknown ".$items{$ID}{'nameID'};
                        $items{$ID}{'binID'} = binFind(\@itemsID, $ID);
                        $items{$ID}{'name'} = $display;
                }
                $items{$ID}{'pos'}{'x'} = $x;
                $items{$ID}{'pos'}{'y'} = $y;
                printc("nn", "<物品> ", "存在: $items{$ID}{'name'} x $items{$ID}{'amount'}\n") if ($config{'mode'} >= 2);
                my $iDist = int(distance(\%{$items{$ID}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}));
                getImportantItems($ID, $iDist) if ($iDist <= 18);

        } elsif ($switch eq "009E") {
                #009e <ID> l <item ID> w <identify flag> B <X> w <Y> w <subX> B <subY> B <amount> w
                #Item drop. Why, position & the quantity inside 009d and the mass eye insert and have changed
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                my $ID = substr($msg, 2, 4);
                my $type = unpack("S1",substr($msg, 6, 2));
                my $x = unpack("S1", substr($msg, 9, 2));
                my $y = unpack("S1", substr($msg, 11, 2));
                my $amount = unpack("S1", substr($msg, 15, 2));
                if (!%{$items{$ID}}) {
                        binAdd(\@itemsID, $ID);
                        $items{$ID}{'appear_time'} = time;
                        $items{$ID}{'amount'} = $amount;
                        $items{$ID}{'nameID'} = $type;
                        $display = ($items_lut{$items{$ID}{'nameID'}} ne "")
                                ? $items_lut{$items{$ID}{'nameID'}}
                                : "Unknown ".$items{$ID}{'nameID'};
                        $items{$ID}{'binID'} = binFind(\@itemsID, $ID);
                        $items{$ID}{'name'} = $display;
                }
                $items{$ID}{'pos'}{'x'} = $x;
                $items{$ID}{'pos'}{'y'} = $y;
                printc("nn", "<物品> ", "出现: $items{$ID}{'name'} x $items{$ID}{'amount'}\n") if ($config{'mode'} >= 2);
                my $iDist = int(distance(\%{$items{$ID}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}));
		if ($AI && $iDist <= 5 && $config{'itemsTakeAuto'} && (!$config{'itemsTakeMaxWeight'} || percent_weight(\%{$chars[$config{'char'}]}) < $config{'itemsTakeMaxWeight'}) && ($itemsPickup{lc($items{$ID}{'name'})} eq "1" || ($itemsPickup{'all'} && $itemsPickup{lc($items{$ID}{'name'})} eq ""))) {
			sendTake(\$remote_socket, $ID);
		}
                getImportantItems($ID, $iDist) if ($iDist <= 18);

        } elsif ($switch eq "00A0") {
                #00a0 <index>.w <amount>.w <item ID>.w <identify flag>.B <attribute?>.B <refine>.B <card>.4w <equip type>.w <type>.B <fail>.B
                #item add to inventory
                my $index = unpack("S1",substr($msg, 2, 2));
                my $amount = unpack("S1",substr($msg, 4, 2));
                my $ID = unpack("S1",substr($msg, 6, 2));
                my $type = unpack("C1",substr($msg, 21, 1));
                my $type_equip = unpack("S1",substr($msg, 19, 2));
                my $fail = unpack("C1",substr($msg, 22, 1));
                if ($fail == 0) {
	                undef $invIndex;
	                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                        if ($invIndex eq "") {
                                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", "");
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = $ID;
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = $amount;
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = $type;
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} = ($itemSlots_lut{$ID} ne "") ? $itemSlots_lut{$ID} : $type_equip;
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = unpack("C1",substr($msg, 8, 1));
                                #------------------------------------------------------------------------------------------------------------
				if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} == 1024) {
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'borned'} = unpack("C1", substr($msg, 9, 1));
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'named'} = unpack("C1", substr($msg, 17, 1));
				} elsif ($chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}) {
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'broken'} = unpack("C1", substr($msg, 9, 1));
                                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'refined'} = unpack("C1", substr($msg, 10, 1));
                                        if (unpack("S1", substr($msg, 11, 2)) == 0x00FF) {
                                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'attribute'} = unpack("C1", substr($msg, 13, 1));
                                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'star'} = unpack("C1", substr($msg, 14, 1)) / 0x05;
                                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'maker_charID'} = substr($msg, 15, 4);
                                        } else {
                                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[0] = unpack("S1", substr($msg, 11, 2));
                                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[1] = unpack("S1", substr($msg, 13, 2));
                                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[2] = unpack("S1", substr($msg, 15, 2));
                                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[3] = unpack("S1", substr($msg, 17, 2));
                                        }
                                }
                                #------------------------------------------------------------------------------------------------------------
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
                                modifingName(\%{$chars[$config{'char'}]{'inventory'}[$invIndex]});
                        } else {
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} += $amount;
                        }
                        if (binFind(\@ai_seq, "buyAuto") eq "" && binFind(\@ai_seq, "storageAuto") eq "") {
	                        if ($itemsPickup{lc($items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}})} >= 2) {
       		                        printc(1, "wy", "<物品> ", "获得: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} x $amount\n");
               		                chatLog("i", "获得: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} x $amount *\n");
	                       	} else {
        	                       	printc("wn", "<物品> ", "增加: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} x $amount\n") if ($config{'mode'});
                	        }
	                        $exp{'item'}{$ID}{'pick'} += $amount;
                        } else {
        	                printc("wn", "<物品> ", "增加: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} x $amount\n") if ($config{'mode'});
        	        }
       	                if ($ai_seq[0] eq "buyAuto") {
               	                chatLog("b", "购买: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} x $amount\n");
                       	}

                        if ($config{'cartAuto'} && $cart{'weight_max'} > 0 && ($cart{'weight'}/$cart{'weight_max'}*100) < $config{'cartMaxWeight'} && $cart{'items'} < $cart{'items_max'}) {
                                if ($ai_seq[0] eq "buyAuto") {
                                        $i = 0;
                                        while(1) {
                                                last if (!$config{"buyAuto_$i"} || !$config{"buyAuto_$i"."_npc"});
                                                if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} eq $config{"buyAuto_$i"} && $config{"buyAuto_$i"."_maxCartAmount"} > 0 && $config{"buyAuto_$i"."_minAmount"} ne "" && $config{"buyAuto_$i"."_maxAmount"} ne "") {
                                                        $ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'});
                                                        $ai_v{'temp'}{'cartAmount'} = ($ai_v{'temp'}{'cartIndex'} eq "") ? 0 : $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'};
                                                        if ($ai_v{'temp'}{'cartAmount'} < $config{"buyAuto_$i"."_maxCartAmount"}) {
	                                                       	if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} > $config{"buyAuto_$i"."_maxCartAmount"} - $ai_v{'temp'}{'cartAmount'}) {
        	                                                        sendCartAdd(\$remote_socket, $index, $config{"buyAuto_$i"."_maxCartAmount"} - $ai_v{'temp'}{'cartAmount'});
                	                                        } else {
                        	                                        sendCartAdd(\$remote_socket, $index, $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'});
                                	                        }
                                                                $timeout{'ai_buyAuto_wait'}{'time'} = time;
                                                                $timeout{'ai_buyAuto_giveup'}{'time'} = time;
                                	                }
                                                        last;
                                                }
                                                $i++
                                        }
                                } elsif ($ai_seq[0] eq "storageAuto") {
                                        $i = 0;
                                        while(1) {
                                                last if (!$config{"getAuto_$i"} || !$config{"getAuto_$i"."_npc"});
                                                if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} eq $config{"getAuto_$i"} && $config{"getAuto_$i"."_maxCartAmount"} > 0 && $config{"getAuto_$i"."_minAmount"} ne "" && $config{"getAuto_$i"."_maxAmount"} ne "") {
                                                        $ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'});
                                                        $ai_v{'temp'}{'cartAmount'} = ($ai_v{'temp'}{'cartIndex'} eq "") ? 0 : $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'};
                                                        if ($ai_v{'temp'}{'cartAmount'} < $config{"getAuto_$i"."_maxCartAmount"}) {
                                                                if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} > $config{"getAuto_$i"."_maxCartAmount"} - $ai_v{'temp'}{'cartAmount'}) {
                                                                        sendCartAdd(\$remote_socket, $index, $config{"getAuto_$i"."_maxCartAmount"} - $ai_v{'temp'}{'cartAmount'});
                                                                } else {
                                                                        sendCartAdd(\$remote_socket, $index, $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'});
                                                                }
                                                                undef $ai_seq_args[0]{'lastIndex'};
                                                                $timeout{'ai_storageAuto'}{'time'} = time;
                                                        }
                                                        last;
                                                }
                                                $i++;
                                        }
                                } elsif ($config{'cartAutoTake'} && binFind(\@ai_seq, "buyAuto") eq "" && binFind(\@ai_seq, "storageAuto") eq "" && binFind(\@ai_seq, "sellAuto") eq "" && !$chars[$config{'char'}]{'inventory'}[$invIndex]{'broken'}) {
                                        undef $ai_v{'temp'}{'found'};
                                        $i = 0;
                                        while(1) {
                                                last if (!$config{"useSelf_item_$i"});
                                                if (existsInList($config{"useSelf_item_$i"}, $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'})) {
                                                        $ai_v{'temp'}{'found'} = 1;
                                                        last;
                                                }
                                                $i++;
                                        }
                                        if (!$ai_v{'temp'}{'found'}) {
                                                if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$invIndex]{'name'})}{'keep'}) {
                                                        sendCartAdd(\$remote_socket, $index, $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $items_control{lc($chars[$config{'char'}]{'inventory'}[$invIndex]{'name'})}{'keep'});
                                                }
                                        }
                                }
                        } elsif (binFind(\@ai_seq, "buyAuto") eq "" && binFind(\@ai_seq, "storageAuto") eq "" && binFind(\@ai_seq, "sellAuto") eq "" && $config{'itemsDropAuto'} && $itemsPickup{lc($chars[$config{'char'}]{'inventory'}[$invIndex]{'name'})} eq "0") {
                                sendDrop(\$remote_socket, $index, $amount);
                                $exp{'item'}{$ID}{'pick'} -= $amount;
                        }
                } elsif ($fail == 2) {
                        printc("wr", "<信息> ", "超过最大负重量，无法取得道具\n");
                } elsif ($fail == 4) {
                        printc("wr", "<信息> ", "已经超过一次可以拿取的数量，无法再拿取任何道具。\n");
                } elsif ($fail == 5) {
                        printc("wr", "<信息> ", "同一种道具无法取得3万个以上\n");
                } elsif ($fail == 6) {
                        printc("wr", "<信息> ", "无法捡取物品...请等待...\n") if ($config{'mode'} >= 2);
                }

        } elsif ($switch eq "00A1") {
                #00a1 <ID> l
                #The floor item elimination of ID
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                my $ID = substr($msg, 2, 4);
                if (%{$items{$ID}}) {
                        printc("gn", "->$switch ", "Item Disappeared: $items{$ID}{'name'}($items{$ID}{'binID'})\n") if $config{'debug'};
                        %{$items_old{$ID}} = %{$items{$ID}};
                        $items_old{$ID}{'disappeared'} = 1;
                        $items_old{$ID}{'gone_time'} = time;
                        undef %{$items{$ID}};
                        binRemove(\@itemsID, $ID);
                }

        } elsif ($switch eq "00A3" || $switch eq "01EE") {
                #00a3 <len> w {<index> w <item ID> w <type> B <identify flag> B <amount> w? 2B} 10B*
                #Possession consumable & collection item list
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                my $block_size = ($switch eq "00A3") ? 10 : 18;
                undef $invIndex;
                for($i = 4; $i < $msg_size; $i += $block_size) {
                        my $index = unpack("S1", substr($msg, $i, 2));
                        my $ID = unpack("S1", substr($msg, $i + 2, 2));
			my $type = unpack("C1", substr($msg, $i + 4, 1));
			my $amount = unpack("S1", substr($msg, $i + 6, 2));
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                        if ($invIndex eq "") {
                                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
                        }
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = $ID;
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = $amount;
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = $type;
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
                        printc("gn", "->$switch ", "Stackable Inventory Item: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}($invIndex) x $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}}\n") if $config{'debug'};
                }
	        $ai_v{'temp'}{'inventory_received'} = 1;
                if ($chars[$config{'char'}]{'eq_arrow_index'}) {
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $chars[$config{'char'}]{'eq_arrow_index'});
			if ($invIndex ne "") {
	                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = 32768;
	                }
                }

        } elsif ($switch eq "00A4") {
                #00a4 <len> w {<index> w <item ID> w <type> B <identify flag> B <equip type> w <equip point> w <attribute? > B <refine> B <card> 4w} 20B*
                #Possession equipment list
                $conState = 5 if ($conState != 4 && $xKore);
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                undef $invIndex;
                for(my $i = 4; $i < $msg_size; $i+=20) {
                        my $index = unpack("S1", substr($msg, $i, 2));
                        my $ID = unpack("S1", substr($msg, $i + 2, 2));
                        my $type_equip = unpack("S1", substr($msg, $i + 6, 2));
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                        if ($invIndex eq "") {
                                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
                        }
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = $ID;
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = 1;
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} = ($itemSlots_lut{$ID} ne "") ? $itemSlots_lut{$ID} : $type_equip;
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
                        #------------------------------------------------------------------------------------------------------------
			if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} == 1024) {
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'borned'} = unpack("C1", substr($msg, $i + 10, 1));
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'named'} = unpack("C1", substr($msg, $i + 18, 1));
			} elsif ($chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}) {
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'broken'}       = unpack("C1", substr($msg, $i + 10, 1));
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'refined'}      = unpack("C1", substr($msg, $i + 11, 1));
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = unpack("S1", substr($msg, $i + 8, 2));
                                if(unpack("S1", substr($msg,$i+12, 2)) == 0x00FF){
                                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'attribute'} = unpack("C1", substr($msg,$i+14, 1));
                                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'star'} = unpack("C1", substr($msg,$i+15, 1)) / 0x05;
                                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'maker_charID'} = substr($msg, 15, 4);
                                }else{
                                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[0] = unpack("S1", substr($msg,$i+12, 2));
                                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[1] = unpack("S1", substr($msg,$i+14, 2));
                                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[2] = unpack("S1", substr($msg,$i+16, 2));
                                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[3] = unpack("S1", substr($msg,$i+18, 2));
                                }
                                modifingName(\%{$chars[$config{'char'}]{'inventory'}[$invIndex]});
                        }
                        #------------------------------------------------------------------------------------------------------------
                        printc("gn", "->$switch ", "Non-Stackable Inventory Item: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}} - $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'}}\n") if $config{'debug'};
                }
	        $ai_v{'temp'}{'inventory_received'} = 1;

        } elsif ($switch eq "00A5" || $switch eq "01F0") {
                #00a5 <len> w {<index> w <item ID> w <type> B <identify flag> B <amount> w? 2B} 10B*
                #Consumable & collection item list which are deposited to the Kapra
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                my $block_size = ($switch eq "00A5") ? 10 : 18;
                for(my $i = 4; $i < $msg_size; $i+=$block_size) {
                        my $index = unpack("S1", substr($msg, $i, 2));
                        my $ID = unpack("S1", substr($msg, $i + 2, 2));
                        $storage{'inventory'}[$index]{'nameID'} = $ID;
                        $storage{'inventory'}[$index]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
                        $storage{'inventory'}[$index]{'amount'} = unpack("S1", substr($msg, $i + 6, 2));
                        $storage{'inventory'}[$index]{'name'} = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
                        $storage{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
                        printc("gn", "->$switch ", "Storage: $storage{'inventory'}[$index]{'name'}($index)\n") if $config{'debug'};
                }

        } elsif ($switch eq "00A6") {
                #00a6 <len> w {<index> w <item ID> w <type> B <identify flag> B <equip type> w <equip point> w <attribute? > B <refine> B <card> 4w} 20B*
                #Equipment list which is deposited to the Kapra
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                for(my $i = 4; $i < $msg_size; $i+=20) {
                        my $index = unpack("S1", substr($msg, $i, 2));
                        my $ID = unpack("S1", substr($msg, $i + 2, 2));
                        my $type_equip = unpack("S1", substr($msg, $i + 6, 2));
                        $storage{'inventory'}[$index]{'nameID'} = $ID;
                        $storage{'inventory'}[$index]{'amount'} = 1;
                        $storage{'inventory'}[$index]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
                        $storage{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
                        $storage{'inventory'}[$index]{'type_equip'} = ($itemSlots_lut{$ID} ne "") ? $itemSlots_lut{$ID} : $type_equip;
                        $storage{'inventory'}[$index]{'name'} = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
			if ($storage{'inventory'}[$index]{'type_equip'} == 1024) {
				$storage{'inventory'}[$index]{'borned'} = unpack("C1", substr($msg, $i + 10, 1));
				$storage{'inventory'}[$index]{'named'} = unpack("C1", substr($msg, $i + 18, 1));
			} elsif ($storage{'inventory'}[$index]{'type_equip'}) {
				$storage{'inventory'}[$index]{'broken'}       = unpack("C1", substr($msg, $i + 10, 1));
                                $storage{'inventory'}[$index]{'refined'} = unpack("C1", substr($msg, $i+11, 1));
                                if (unpack("S1", substr($msg, $i+12, 2)) == 0x00FF) {
                                        $storage{'inventory'}[$index]{'attribute'} = unpack("C1", substr($msg, $i+14, 1));
                                        $storage{'inventory'}[$index]{'star'}     = unpack("C1", substr($msg, $i+15, 1)) / 0x05;
					$storage{'inventory'}[$index]{'maker_charID'} = substr($msg, $i + 16, 4);
                                } else {
                                        $storage{'inventory'}[$index]{'card'}[0]  = unpack("S1", substr($msg, $i+12, 2));
                                        $storage{'inventory'}[$index]{'card'}[1]  = unpack("S1", substr($msg, $i+14, 2));
                                        $storage{'inventory'}[$index]{'card'}[2]  = unpack("S1", substr($msg, $i+16, 2));
                                        $storage{'inventory'}[$index]{'card'}[3]  = unpack("S1", substr($msg, $i+18, 2));
                                }
                                modifingName(\%{$storage{'inventory'}[$index]});
                        #------------------------------------------------------------------------------------------------------------
                        }
                        printc("gn", "->$switch ", "Storage Item: $storage{'inventory'}[$index]{'name'}($index) x $storage{'inventory'}[$index]{'amount'}\n") if $config{'debug'};
                }

        } elsif ($switch eq "00A8") {
                #00a8 <index> w <amount> w <type> B
                #Item use response.
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                my $index = unpack("S1",substr($msg, 2, 2));
                my $amount = unpack("C1",substr($msg, 6, 1));
                undef $invIndex;
                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                if ($invIndex ne "") {
	                $exp{'item'}{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}{'used'} += $amount;
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $amount;
                        printc("wngn", "<物品> ", "使用: ", "$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ", "x $amount\n") if ($config{'mode'});
                        if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
                                undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
                        }
                } else {
                        printc("yr", "<错误> ", "使用: Inventory Index: $index x $amount\n");
                }

        } elsif ($switch eq "00AA") {
                #00aa <index> w <equip point> w <type> B
                #Item equipment response
                my $index = unpack("S1",substr($msg, 2, 2));
                my $type = unpack("S1",substr($msg, 4, 2));
                my $fail = unpack("C1",substr($msg, 6, 1));
                undef $invIndex;
                my $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                if ($fail == 0) {
                        printc("wrn", "<信息> ", "无法装备道具 ", "$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}\n");
                } else {
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = $type;
                        printc("wgn", "<信息> ", "装备穿着完成 ", "$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}\n") if ($config{'mode'});
                }

        } elsif ($switch eq "00AC") {
                #00ac <index> w <equip point> w <type> B
                #Equipment cancellation response
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                my $index = unpack("S1",substr($msg, 2, 2));
                my $type = unpack("S1",substr($msg, 4, 2));
                my $fail = unpack("C1",substr($msg, 6, 1));
                undef $invIndex;
                my $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                if ($fail == 0) {
                        printc("wrn", "<信息> ", "无法卸下装备 ", "$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}\n");
                } else {
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = 0;
                        printc("wrn", "<信息> ", "装备卸下完成 ", "$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}\n") if ($config{'mode'} >= 2);
                }

        } elsif ($switch eq "00AF") {
                #00af <index> w <amount> w
                #Item several decreases. Amount just decreases
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                my $index = unpack("S1",substr($msg, 2, 2));
                my $amount = unpack("S1",substr($msg, 4, 2));
                undef $invIndex;
                my $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                if ($invIndex eq "") {
                        printc("yr", "<错误> ", "减少: Inventory Index: $index x $amount\n");
                } else {
                        if ($amount == 0 && $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} == 32768) {
                                printc("wr", "<信息> ", "装载的箭一定要解除");
                        } elsif ($config{'mode'} < 2 && $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} == 32768) {
                                # 不显示箭矢减少
                        } else {
                                printc("wn", "<物品> ", "减少: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} x $amount\n") if ($config{'mode'});
                        }
                        if ($ai_seq[0] eq "sellAuto" && $items_control{lc($chars[$config{'char'}]{'inventory'}[$invIndex]{'name'})}{'sell'}) {
                                chatLog("b", "出售: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} x $amount\n");
                        }
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $amount;
                        if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
                                undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
                        }
                }

        } elsif ($switch eq "00B0") {
                #00b0 <type> w <val> l
                #Renewal of various performance figures. Below type: Enumerating the numerical value which corresponds
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                my $type = unpack("S1",substr($msg, 2, 2));
                my $val = unpack("L1",substr($msg, 4, 4));
                if ($type == 0) {
                        printc("gn", "->$switch ", "Something1: $val\n") if $config{'debug'};
                } elsif ($type == 3) {
                        printc("gn", "->$switch ", "Something2: $val\n") if $config{'debug'};
                } elsif ($type == 4) {
                        $val = unpack("l1",substr($msg, 4, 4));
                        $val = abs($val);
                        printc("yr", "<系统> ", "你被禁言 $val 分钟...\n");
                        chatLog("gm", "你被禁言 $val 分钟...\n");
                        ($map_string) = $map_name =~ /([\s\S]*)\.gat/;
                        $sleeptime = int($val * 60 + rand() * 600);
                        printc("yr", "<系统> ", "躲避禁言,断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        chatLog("gm", "躲避禁言,断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                	$conState = 1;
                	undef $conState_tries;
                	$timeout_ex{'master'}{'time'} = time;
                	$timeout_ex{'master'}{'timeout'} = $sleeptime;
                	killConnection(\$remote_socket) if (!$xKore);
                } elsif ($type == 5) {
                        $chars[$config{'char'}]{'hp'} = $val;
                        printc("gn", "->$switch ", "Hp: $val\n") if ($config{'debug'});
                } elsif ($type == 6) {
                        $chars[$config{'char'}]{'hp_max'} = $val;
                        printc("gn", "->$switch ", "Max Hp: $val\n") if $config{'debug'};
                } elsif ($type == 7) {
                        $chars[$config{'char'}]{'sp'} = $val;
                        printc("gn", "->$switch ", "Sp: $val\n") if ($config{'debug'});
                } elsif ($type == 8) {
                        $chars[$config{'char'}]{'sp_max'} = $val;
                        printc("gn", "->$switch ", "Max Sp: $val\n") if $config{'debug'};
                } elsif ($type == 9) {
                        $chars[$config{'char'}]{'points_free'} = $val;
                        printc("gn", "->$switch ", "Status Points: $val\n") if $config{'debug'};
                } elsif ($type == 11) {
                        $chars[$config{'char'}]{'lv'} = $val;
                        printc("gn", "->$switch ", "Level: $val\n") if $config{'debug'};
                } elsif ($type == 12) {
                        $chars[$config{'char'}]{'points_skill'} = $val;
                        printc("gn", "->$switch ", "Skill Points: $val\n") if $config{'debug'};
                } elsif ($type == 24) {
                        $chars[$config{'char'}]{'weight'} = int($val / 10);
                        printc("gn", "->$switch ", "Weight: $chars[$config{'char'}]{'weight'}\n") if $config{'debug'};
                        $ai_v{'temp'}{'inventory_received'} = 1 if (!$val);
                } elsif ($type == 25) {
                        $chars[$config{'char'}]{'weight_max'} = int($val / 10);
                        printc("gn", "->$switch ", "Max Weight: $chars[$config{'char'}]{'weight_max'}\n") if $config{'debug'};
                } elsif ($type == 41) {
                        $chars[$config{'char'}]{'attack'} = $val;
                        printc("gn", "->$switch ", "Attack: $val\n") if $config{'debug'};
                } elsif ($type == 42) {
                        $chars[$config{'char'}]{'attack_bonus'} = $val;
                        printc("gn", "->$switch ", "Attack Bonus: $val\n") if $config{'debug'};
                } elsif ($type == 43) {
                        $chars[$config{'char'}]{'attack_magic_max'} = $val;
                        printc("gn", "->$switch ", "Magic Attack Max: $val\n") if $config{'debug'};
                } elsif ($type == 44) {
                        $chars[$config{'char'}]{'attack_magic_min'} = $val;
                        printc("gn", "->$switch ", "Magic Attack Min: $val\n") if $config{'debug'};
                } elsif ($type == 45) {
                        $chars[$config{'char'}]{'def'} = $val;
                        printc("gn", "->$switch ", "Defense: $val\n") if $config{'debug'};
                } elsif ($type == 46) {
                        $chars[$config{'char'}]{'def_bonus'} = $val;
                        printc("gn", "->$switch ", "Defense Bonus: $val\n") if $config{'debug'};
                } elsif ($type == 47) {
                        $chars[$config{'char'}]{'def_magic'} = $val;
                        printc("gn", "->$switch ", "Magic Defense: $val\n") if $config{'debug'};
                } elsif ($type == 48) {
                        $chars[$config{'char'}]{'def_magic_bonus'} = $val;
                        printc("gn", "->$switch ", "Magic Defense Bonus: $val\n") if $config{'debug'};
                } elsif ($type == 49) {
                        $chars[$config{'char'}]{'hit'} = $val;
                        printc("gn", "->$switch ", "Hit: $val\n") if $config{'debug'};
                } elsif ($type == 50) {
                        $chars[$config{'char'}]{'flee'} = $val;
                        printc("gn", "->$switch ", "Flee: $val\n") if $config{'debug'};
                } elsif ($type == 51) {
                        $chars[$config{'char'}]{'flee_bonus'} = $val;
                        printc("gn", "->$switch ", "Flee Bonus: $val\n") if $config{'debug'};
                } elsif ($type == 52) {
                        $chars[$config{'char'}]{'critical'} = $val;
                        printc("gn", "->$switch ", "Critical: $val\n") if $config{'debug'};
                } elsif ($type == 53) {
                        $chars[$config{'char'}]{'attack_speed'} = 200 - $val/10;
                        printc("gn", "->$switch ", "Attack Speed: $chars[$config{'char'}]{'attack_speed'}\n") if $config{'debug'};
                } elsif ($type == 55) {
                        $chars[$config{'char'}]{'lv_job'} = $val;
                        printc("gn", "->$switch ", "Job Level: $val\n") if $config{'debug'};
                } elsif ($type == 124) {
                        printc("gn", "->$switch ", "Something3: $val\n") if $config{'debug'};
                } else {
                        printc("gn", "->$switch ", "Something: $val\n") if $config{'debug'};
                }

        } elsif ($switch eq "00B1") {
                #00b1 <type> w <val> l
                #Renewal of various performance figures. Below type: Enumerating the numerical value which corresponds
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                my $type = unpack("S1",substr($msg, 2, 2));
                my $val = unpack("L1",substr($msg, 4, 4));
                if ($type == 1) {
                        $chars[$config{'char'}]{'exp_last'} = $chars[$config{'char'}]{'exp'};
                        $chars[$config{'char'}]{'exp'} = $val;
                        printc("gn", "->$switch ", "Exp: $val\n") if $config{'debug'};
                        if (!$exp{'base'}{'baseExp_get'} && $chars[$config{'char'}]{'exp'} > $chars[$config{'char'}]{'exp_last'}) {
                                $exp{'monster'}{$exp{'monster'}{'nameID'}}{'baseExp'} += $chars[$config{'char'}]{'exp'} - $chars[$config{'char'}]{'exp_last'};
                                $exp{'base'}{'baseExp_get'} = $chars[$config{'char'}]{'exp'} - $chars[$config{'char'}]{'exp_last'};
                        } elsif ($chars[$config{'char'}]{'exp'} < $chars[$config{'char'}]{'exp_last'}) {
                                $exp{'base'}{'dead'}++;
                        }
                } elsif ($type == 2) {
                        $chars[$config{'char'}]{'exp_job_last'} = $chars[$config{'char'}]{'exp_job'};
                        $chars[$config{'char'}]{'exp_job'} = $val;
                        printc("gn", "->$switch ", "Job Exp: $val\n") if $config{'debug'};
                        if (!$exp{'base'}{'jobExp_get'} && $chars[$config{'char'}]{'exp_job'} > $chars[$config{'char'}]{'exp_job_last'}) {
                                $exp{'monster'}{$exp{'monster'}{'nameID'}}{'jobExp'} += $chars[$config{'char'}]{'exp_job'} - $chars[$config{'char'}]{'exp_job_last'};
                                $exp{'base'}{'jobExp_get'} = $chars[$config{'char'}]{'exp_job'} - $chars[$config{'char'}]{'exp_job_last'};
                                printc(1, "ww", "<信息> ", "获得: 经验 $exp{'base'}{'baseExp_get'} / $exp{'base'}{'jobExp_get'}\n") if (!$config{'hideMsg_exp'});
                        }
                } elsif ($type == 20) {
                        $chars[$config{'char'}]{'zenny'} = $val;
                        printc("gn", "->$switch ", "Zenny: $val\n") if $config{'debug'};
                } elsif ($type == 22) {
                        $chars[$config{'char'}]{'exp_max_last'} = $chars[$config{'char'}]{'exp_max'};
                        $chars[$config{'char'}]{'exp_max'} = $val;
                        printc("gn", "->$switch ", "Required Exp: $val\n") if $config{'debug'};
                        if ($chars[$config{'char'}]{'exp_max_last'} > 0 && $chars[$config{'char'}]{'exp_max'} > $chars[$config{'char'}]{'exp_max_last'}) {
                                $chars[$config{'char'}]{'exp_start'} = $chars[$config{'char'}]{'exp_start'} - $chars[$config{'char'}]{'exp_max_last'};
                                $exp{'base'}{'dead'}--;
                        }
                } elsif ($type == 23) {
                        $chars[$config{'char'}]{'exp_job_max_last'} = $chars[$config{'char'}]{'exp_job_max'};
                        $chars[$config{'char'}]{'exp_job_max'} = $val;
                        printc("gn", "->$switch ", "Required Job Exp: $val\n") if $config{'debug'};
                        if ($chars[$config{'char'}]{'exp_job_max_last'} > 0 && $chars[$config{'char'}]{'exp_job_max'} > $chars[$config{'char'}]{'exp_job_max_last'}) {
                                $chars[$config{'char'}]{'exp_job_start'} = $chars[$config{'char'}]{'exp_job_start'} - $chars[$config{'char'}]{'exp_job_max_last'};
                        }
                }

        } elsif ($switch eq "00B3") {
                #00b3 <type>
                #Type=01 character select response
	        $conState = 2;
        	undef $conState_tries;
	        if (!$xKore) {
                	printc("yn", "<系统> ", "关闭与帐号服务器的连接\n");
        	        killConnection(\$remote_socket);
	        }                

        } elsif ($switch eq "00B4") {
                #00b4 <len> w <ID> l <str>.? B
                #The message from NPC of ID
                decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
                $msg = substr($msg, 0, 8).$newmsg;
                $ID = substr($msg, 4, 4);
                ($talk) = substr($msg, 8, $msg_size - 8) =~ /([\s\S]*?)\000/;
                $talk{'ID'} = $ID;
                $talk{'nameID'} = unpack("L1", $ID);
                $talk =~ s/^\s+//;
                $talk =~ s/\^[0-9a-fA-F]{6}//g;
                $talk{'msg'} = $talk;
                printc("wn", "<对话> ", "$npcs{$ID}{'name'} : $talk{'msg'}\n");

        } elsif ($switch eq "00B5") {
                #00b5 <ID> l
                #"NEXT" icon is put out to message window of NPC of ID
                $ID = substr($msg, 2, 4);
                printc("ww", "<对话> ", "$npcs{$ID}{'name'} : 输入 'talk cont' 继续对话\n");

        } elsif ($switch eq "00B6") {
                #00b6 <ID> l
                #"CLOSE" icon is put out to message window of NPC of ID
                $ID = substr($msg, 2, 4);
                undef %talk;
                printc("ww", "<对话> ", "$npcs{$ID}{'name'} : 对话完毕\n");
                sendTalkCancel(\$remote_socket, $ID);

        } elsif ($switch eq "00B7") {
                #00b7 <len> w <ID> l <str>.? B
                #In the conversation of NPC of ID selection item indication. Each item is divided with '':''
                decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
                $msg = substr($msg, 0, 8).$newmsg;
                $ID = substr($msg, 4, 4);
                ($talk) = substr($msg, 8, $msg_size - 8) =~ /([\s\S]*?)\000/;
                @preTalkResponses = split /:/, $talk;
                undef @{$talk{'responses'}};
                foreach (@preTalkResponses) {
                        $_ =~ s/^\s+//;
                        $_ =~ s/\^[0-9a-fA-F]{6}//g;
                        push @{$talk{'responses'}}, $_ if $_ ne "";
                }
                parseInput("talk resp");
                printc("ww", "<对话> ", "$npcs{$ID}{'name'} : 输入 'talk resp' 选择回答\n");

        } elsif ($switch eq "00BC") {
                #00bc <type> w <fail> B <val> B
                #Status up response. fail=01 If success. As for type the same as 00bb. As for val after rising, the number
                my $type = unpack("S1",substr($msg, 2, 2));
                my $val = unpack("C1",substr($msg, 5, 1));
                if ($val == 207) {
                        printc("wr", "<信息> ", "没有足够的属性点数\n");
                } else {
                        if ($type == 13) {
                                $chars[$config{'char'}]{'str'} = $val;
                                printc("gn", "->$switch ", "Strength: $val\n") if $config{'debug'};
                        } elsif ($type == 14) {
                                $chars[$config{'char'}]{'agi'} = $val;
                                printc("gn", "->$switch ", "Agility: $val\n") if $config{'debug'};
                        } elsif ($type == 15) {
                                $chars[$config{'char'}]{'vit'} = $val;
                                printc("gn", "->$switch ", "Vitality: $val\n") if $config{'debug'};
                        } elsif ($type == 16) {
                                $chars[$config{'char'}]{'int'} = $val;
                                printc("gn", "->$switch ", "Intelligence: $val\n") if $config{'debug'};
                        } elsif ($type == 17) {
                                $chars[$config{'char'}]{'dex'} = $val;
                                printc("gn", "->$switch ", "Dexterity: $val\n") if $config{'debug'};
                        } elsif ($type == 18) {
                                $chars[$config{'char'}]{'luk'} = $val;
                                printc("gn", "->$switch ", "Luck: $val\n") if $config{'debug'};
                        } else {
                                printc("gn", "->$switch ", "Something: $val\n");
                        }
                }

        } elsif ($switch eq "00BD") {
                #00bd <status point> w <STR> B <STRupP> B <AGI> B <AGIupP> B <VIT> B <VITupP> B <INT> B <INTupP> B <DEX> B <DEXupP> B <LUK> B <LUKupP> B <ATK> w <ATKbonus> w <MATKmax> w <MATKmin> w <DEF> w <DEFbonus> w <MDEF> w <MDEFbonus> w <HIT> w <FLEE> w <FLEEbonus> w <critical> w? W
                #Collecting, the packet which sends status information
                $chars[$config{'char'}]{'points_free'} = unpack("S1", substr($msg, 2, 2));
                $chars[$config{'char'}]{'str'} = unpack("C1", substr($msg, 4, 1));
                $chars[$config{'char'}]{'points_str'} = unpack("C1", substr($msg, 5, 1));
                $chars[$config{'char'}]{'agi'} = unpack("C1", substr($msg, 6, 1));
                $chars[$config{'char'}]{'points_agi'} = unpack("C1", substr($msg, 7, 1));
                $chars[$config{'char'}]{'vit'} = unpack("C1", substr($msg, 8, 1));
                $chars[$config{'char'}]{'points_vit'} = unpack("C1", substr($msg, 9, 1));
                $chars[$config{'char'}]{'int'} = unpack("C1", substr($msg, 10, 1));
                $chars[$config{'char'}]{'points_int'} = unpack("C1", substr($msg, 11, 1));
                $chars[$config{'char'}]{'dex'} = unpack("C1", substr($msg, 12, 1));
                $chars[$config{'char'}]{'points_dex'} = unpack("C1", substr($msg, 13, 1));
                $chars[$config{'char'}]{'luk'} = unpack("C1", substr($msg, 14, 1));
                $chars[$config{'char'}]{'points_luk'} = unpack("C1", substr($msg, 15, 1));
                $chars[$config{'char'}]{'attack'} = unpack("S1", substr($msg, 16, 2));
                $chars[$config{'char'}]{'attack_bonus'} = unpack("S1", substr($msg, 18, 2));
                $chars[$config{'char'}]{'attack_magic_max'} = unpack("S1", substr($msg, 20, 2));
                $chars[$config{'char'}]{'attack_magic_min'} = unpack("S1", substr($msg, 22, 2));
                $chars[$config{'char'}]{'def'} = unpack("S1", substr($msg, 24, 2));
                $chars[$config{'char'}]{'def_bonus'} = unpack("S1", substr($msg, 26, 2));
                $chars[$config{'char'}]{'def_magic'} = unpack("S1", substr($msg, 28, 2));
                $chars[$config{'char'}]{'def_magic_bonus'} = unpack("S1", substr($msg, 30, 2));
                $chars[$config{'char'}]{'hit'} = unpack("S1", substr($msg, 32, 2));
                $chars[$config{'char'}]{'flee'} = unpack("S1", substr($msg, 34, 2));
                $chars[$config{'char'}]{'flee_bonus'} = unpack("S1", substr($msg, 36, 2));
                $chars[$config{'char'}]{'critical'} = unpack("S1", substr($msg, 38, 2));
                printc("gnnnnnnnnnnnnnnnnnnn", "->$switch ",        "Strength: $chars[$config{'char'}]{'str'} #$chars[$config{'char'}]{'points_str'}\n"
                        ,"Agility: $chars[$config{'char'}]{'agi'} #$chars[$config{'char'}]{'points_agi'}\n"
                        ,"Vitality: $chars[$config{'char'}]{'vit'} #$chars[$config{'char'}]{'points_vit'}\n"
                        ,"Intelligence: $chars[$config{'char'}]{'int'} #$chars[$config{'char'}]{'points_int'}\n"
                        ,"Dexterity: $chars[$config{'char'}]{'dex'} #$chars[$config{'char'}]{'points_dex'}\n"
                        ,"Luck: $chars[$config{'char'}]{'luk'} #$chars[$config{'char'}]{'points_luk'}\n"
                        ,"Attack: $chars[$config{'char'}]{'attack'}\n"
                        ,"Attack Bonus: $chars[$config{'char'}]{'attack_bonus'}\n"
                        ,"Magic Attack Min: $chars[$config{'char'}]{'attack_magic_min'}\n"
                        ,"Magic Attack Max: $chars[$config{'char'}]{'attack_magic_max'}\n"
                        ,"Defense: $chars[$config{'char'}]{'def'}\n"
                        ,"Defense Bonus: $chars[$config{'char'}]{'def_bonus'}\n"
                        ,"Magic Defense: $chars[$config{'char'}]{'def_magic'}\n"
                        ,"Magic Defense Bonus: $chars[$config{'char'}]{'def_magic_bonus'}\n"
                        ,"Hit: $chars[$config{'char'}]{'hit'}\n"
                        ,"Flee: $chars[$config{'char'}]{'flee'}\n"
                        ,"Flee Bonus: $chars[$config{'char'}]{'flee_bonus'}\n"
                        ,"Critical: $chars[$config{'char'}]{'critical'}\n"
                        ,"Status Points: $chars[$config{'char'}]{'points_free'}\n")
                        if $config{'debug'};

        } elsif ($switch eq "00BE") {
                #00be <type> w <val> B
                #Necessary status point renewal packet. Type 0020 - 0025 corresponds to STR - LUK to order
                my $type = unpack("S1",substr($msg, 2, 2));
                my $val = unpack("C1",substr($msg, 4, 1));
                if ($type == 32) {
                        $chars[$config{'char'}]{'points_str'} = $val;
                        printc("gn", "->$switch ", "Points needed for Strength: $val\n") if $config{'debug'};
                } elsif ($type == 33) {
                        $chars[$config{'char'}]{'points_agi'} = $val;
                        printc("gn", "->$switch ", "Points needed for Agility: $val\n") if $config{'debug'};
                } elsif ($type == 34) {
                        $chars[$config{'char'}]{'points_vit'} = $val;
                        printc("gn", "->$switch ", "Points needed for Vitality: $val\n") if $config{'debug'};
                } elsif ($type == 35) {
                        $chars[$config{'char'}]{'points_int'} = $val;
                        printc("gn", "->$switch ", "Points needed for Intelligence: $val\n") if $config{'debug'};
                } elsif ($type == 36) {
                        $chars[$config{'char'}]{'points_dex'} = $val;
                        printc("gn", "->$switch ", "Points needed for Dexterity: $val\n") if $config{'debug'};
                } elsif ($type == 37) {
                        $chars[$config{'char'}]{'points_luk'} = $val;
                        printc("gn", "->$switch ", "Points needed for Luck: $val\n") if $config{'debug'};
                }

        } elsif ($switch eq "00C0") {
                #00c0 <ID> l <type> B
                #The person of ID voiced emotion. As for type the same as 00bf
                my $ID = substr($msg, 2, 4);
                my $type = unpack("C*", substr($msg, 6, 1));
                if ($ID eq $accountID) {
                        printc("wng", "<表情> ", "$chars[$config{'char'}]{'name'} : ", "$emotions_lut{$type}\n") if (!$config{'hideMsg_emotion'});
                } elsif (%{$players{$ID}}) {
                        printc("nng", "<表情> ", "$players{$ID}{'name'}($players{$ID}{'binID'}) : ", "$emotions_lut{$type}\n") if (!$config{'hideMsg_emotion'});
                } elsif (%{$monsters{$ID}}) {
                        printc("nng", "<表情> ", "$monsters{$ID}{'name'}($monsters{$ID}{'binID'}) : ", "$emotions_lut{$type}\n") if (!$config{'hideMsg_emotion'});
                }

        } elsif ($switch eq "00C2") {
                #00c2 <val> l
                #Login number of people response
                my $users = unpack("L*", substr($msg, 2, 4));
                printc("yn", "<系统> ", "在线人数 $users\n");

        } elsif ($switch eq "00C3") {
#00c3 <ID> l <type> B <val> B
#The eye modification which you saw. As for type with 00 substance (when and the like switching jobs), 02 weapon, 03 head (under), 04 head (on), 05 head (in), 08 shield

        } elsif ($switch eq "00C4") {
                #00c4 <ID> l
                #Story it meaning that NPC which was applied is the merchant, the buy/sell selection window coming out
                my $ID = substr($msg, 2, 4);
                undef %talk;
                $talk{'buyOrSell'} = 1;
                $talk{'ID'} = $ID;
                printc("ww", "<对话> ", "$npcs{$ID}{'name'} : 输入 'store' 开始购买, 输入 'sell' 开始出售\n");

#00c5 <ID> l <type> B
#Buy/sell selection. If type=00 buy. If type=01 sell

        } elsif ($switch eq "00C6") {
                #00c6 <len> w {<value> l <DCvalue> l <type> B <item ID> w} 11B*
                #At the time of the store buy selection of NPC. As for DCvalue price after merchant DC
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                undef @storeList;
                $storeList = 0;
                undef $talk{'buyOrSell'};
                for (my $i = 4; $i < $msg_size; $i+=11) {
                        my $price = unpack("L1", substr($msg, $i, 4));
                        my $type = unpack("C1", substr($msg, $i + 8, 1));
                        my $ID = unpack("S1", substr($msg, $i + 9, 2));
                        $storeList[$storeList]{'nameID'} = $ID;
                        $storeList[$storeList]{'name'} = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
                        $storeList[$storeList]{'type'} = $type;
                        $storeList[$storeList]{'price'} = $price;
                        printc("gn", "->$switch ", "Item added to Store: $storeList[$storeList]{'name'} - $price z\n") if ($config{'debug'} >= 2);
                        $storeList++;
                }
                parseInput("store");
                printc("ww", "<对话> ", "$npcs{$talk{'ID'}}{'name'} : 请输入 'buy # amount' 购买物品\n");

        } elsif ($switch eq "00C7") {
                #00c7 <len> w {<index> w <value> l <OCvalue> l} 10B*
                #At the time of the store sell selection of NPC. As for OCvalue price after merchant OC
                if (length($msg) > 4) {
                        decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                        $msg = substr($msg, 0, 4).$newmsg;
                }
                undef $talk{'buyOrSell'};
                printc("ww", "<对话> ", "请输入 'sell # amount' 出售物品\n");

        } elsif ($switch eq "00CA" && length($msg) >= 3) {
                # Finished to buy from NPC
                $fail = unpack("C1", substr($msg, 2, 1));
                if (!$fail) {
                        printc("wc", "<信息> ", "交易成功\n") if ($config{'mode'} >= 2);
                } elsif ($fail == 1) {
                        printc("wr", "<信息> ", "金钱不足\n");
                        print "金钱不足\n";
                } elsif ($fail == 2) {
                        printc("wr", "<信息> ", "超过负重量\n");
                }
                $msg_size = 3;

#00cb <type> B
#To NPC sale end. Type=00 success

        } elsif ($switch eq "00CD") {
                #00cd <ID? > l
                #GM Kick
                printc("yr", "<系统> ", "您已被管理人员 ,强制结束游戏。\n");
                chatLog("gm","您已被管理人员 ,强制结束游戏。\n");
                $sleeptime = int($config{'avoidGM_reconnect'} + rand(1800) + 1800);
                $conState = 1;
                undef $conState_tries;
                $timeout_ex{'master'}{'time'} = time;
                $timeout_ex{'master'}{'timeout'} = $sleeptime;
                killConnection(\$remote_socket) if (!$xKore);

        } elsif ($switch eq "00D1") {
                #00d1 < type >.B < fail >.B
                #ignored player
                my $type = unpack("C1", substr($msg, 2, 1));
                my $error = unpack("C1", substr($msg, 3, 1));
                if ($type == 0) {
                        printc("wr", "<信息> ", "拒绝悄悄话状态\n");
                } elsif ($type == 1) {
                        if ($error == 0) {
                                printc("wc", "<信息> ", "开启悄悄话状态\n");
                        }
                }

        } elsif ($switch eq "00D2") {
                #00d2 < type >.B < fail >.B
                # /exall
                my $type = unpack("C1", substr($msg, 2, 1));
                my $error = unpack("C1", substr($msg, 3, 1));
                if ($type == 0) {
                        printc("wr", "<信息> ", "拒绝接收所有悄悄话讯息\n");
                } elsif ($type == 1) {
                        if ($error == 0) {
                                printc("wc", "<信息> ", "开启接收所有悄悄话功能\n");
                        }
                }

        } elsif ($switch eq "00D6") {
                #00d6 < fail >.B
                #Chat raising response
                $currentChatRoom = "new";
                %{$chatRooms{'new'}} = %createdChatRoom;
                binAdd(\@chatRoomsID, "new");
                binAdd(\@currentChatRoomUsers, $chars[$config{'char'}]{'name'});
                printc("wc", "<信息> ", "开启聊天室成功\n");

        } elsif ($switch eq "00D7") {
                #00d7 < len >.w < owner ID >.l < chat ID >.l < limit >.w < users >.w < pub >.B < title >.? B
                #Chat information inside picture
                decrypt(\$newmsg, substr($msg, 17, length($msg)-17));
                $msg = substr($msg, 0, 17).$newmsg;
                my $ID = substr($msg, 8, 4);
                if (!%{$chatRooms{$ID}}) {
                        binAdd(\@chatRoomsID, $ID);
                }
                $chatRooms{$ID}{'title'} = substr($msg,17,$msg_size - 17);
                $chatRooms{$ID}{'ownerID'} = substr($msg,4,4);
                $chatRooms{$ID}{'limit'} = unpack("S1",substr($msg,12,2));
                $chatRooms{$ID}{'public'} = unpack("C1",substr($msg,16,1));
                $chatRooms{$ID}{'num_users'} = unpack("S1",substr($msg,14,2));

        } elsif ($switch eq "00D8") {
                #00d8 < chat ID >.l
                #Chat elimination
                my $ID = substr($msg, 2, 4);
                binRemove(\@chatRoomsID, $ID);
                undef %{$chatRooms{$ID}};

        } elsif ($switch eq "00DA") {
                #00da < fail >.B
                #Failure of Chat participation
                my $type = unpack("C1",substr($msg, 2, 1));
                if ($type == 0) {
                        printc("wr", "<信息> ", "此聊天室人数超过上限，无法进入\n");
                } elsif ($type == 1) {
                        printc("wr", "<信息> ", "此聊天室人密码错误，无法进入\n");
                } elsif ($type == 2) {
                        printc("wr", "<信息> ", "被拒绝进入此聊天室\n");
                }

        } elsif ($switch eq "00DB") {
                #00db < len >.w < chat ID >.l { < index >.l < nick >.24b }.28b*
                #Chat participant list
                decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
                $msg = substr($msg, 0, 8).$newmsg;
                my $ID = substr($msg, 4, 4);
                $currentChatRoom = $ID;
                $chatRooms{$currentChatRoom}{'num_users'} = 0;
                for (my $i = 8; $i < $msg_size; $i+=28) {
                        my $type = unpack("C1",substr($msg,$i,1));
                        my ($chatUser) = substr($msg,$i + 4,24) =~ /([\s\S]*?)\000/;
                        if ($chatRooms{$currentChatRoom}{'users'}{$chatUser} eq "") {
                                binAdd(\@currentChatRoomUsers, $chatUser);
                                if ($type == 0) {
                                        $chatRooms{$currentChatRoom}{'users'}{$chatUser} = 2;
                                } else {
                                        $chatRooms{$currentChatRoom}{'users'}{$chatUser} = 1;
                                }
                                $chatRooms{$currentChatRoom}{'num_users'}++;
                        }
                }
                printc("wc", "<信息> ", "进入聊天室 $chatRooms{$currentChatRoom}{'title'}\n");

        } elsif ($switch eq "00DC") {
                #00dc < users >.w < nick >.24b
                #Participant addition to Chat (?)
                if ($currentChatRoom ne "") {
                        my $num_users = unpack("S1", substr($msg,2,2));
                        my ($joinedUser) = substr($msg,4,24) =~ /([\s\S]*?)\000/;
                        binAdd(\@currentChatRoomUsers, $joinedUser);
                        $chatRooms{$currentChatRoom}{'users'}{$joinedUser} = 1;
                        $chatRooms{$currentChatRoom}{'num_users'} = $num_users;
                        printc("wn", "<信息> ", "$joinedUser 进入聊天室\n");
                }

        } elsif ($switch eq "00DD") {
                #00dd < index >.w < nick >.24b < fail >.B
                #From Chat participant to come out
                my $num_users = unpack("S1", substr($msg,2,2));
                my ($leaveUser) = substr($msg,4,24) =~ /([\s\S]*?)\000/;
                $chatRooms{$currentChatRoom}{'users'}{$leaveUser} = "";
                binRemove(\@currentChatRoomUsers, $leaveUser);
                $chatRooms{$currentChatRoom}{'num_users'} = $num_users;
                if ($leaveUser eq $chars[$config{'char'}]{'name'}) {
                        binRemove(\@chatRoomsID, $currentChatRoom);
                        undef %{$chatRooms{$currentChatRoom}};
                        undef @currentChatRoomUsers;
                        $currentChatRoom = "";
                        printc("wr", "<信息> ", "离开聊天室\n");
                } else {
                        printc("wn", "<信息> ", "$leaveUser 离开聊天室\n");
                }

        } elsif ($switch eq "00DF") {
                #00df < len >.w < owner ID >.l < chat ID >.l < limit >.w < users >.w < pub >.B < title >.? B
                #Chat status modification success
                decrypt(\$newmsg, substr($msg, 17, length($msg)-17));
                $msg = substr($msg, 0, 17).$newmsg;
                my $ID = substr($msg, 8, 4);
                my $ownerID = substr($msg, 4, 4);
                if ($ownerID eq $accountID) {
                        $chatRooms{'new'}{'title'} = substr($msg,17,$msg_size - 17);
                        $chatRooms{'new'}{'ownerID'} = $ownerID;
                        $chatRooms{'new'}{'limit'} = unpack("S1",substr($msg,12,2));
                        $chatRooms{'new'}{'public'} = unpack("C1",substr($msg,16,1));
                        $chatRooms{'new'}{'num_users'} = unpack("S1",substr($msg,14,2));
                } else {
                        $chatRooms{$ID}{'title'} = substr($msg,17,$msg_size - 17);
                        $chatRooms{$ID}{'ownerID'} = $ownerID;
                        $chatRooms{$ID}{'limit'} = unpack("S1",substr($msg,12,2));
                        $chatRooms{$ID}{'public'} = unpack("C1",substr($msg,16,1));
                        $chatRooms{$ID}{'num_users'} = unpack("S1",substr($msg,14,2));
                }
                printc("ww", "<信息> ", "聊天室属性变更\n");

        } elsif ($switch eq "00E1") {
                #00e1 < index >.l < nick >.24b
                #Chat participant number it does again to attach?
                my $type = unpack("C1",substr($msg, 2, 1));
                my ($chatUser) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
                if ($type == 0) {
                        if ($chatUser eq $chars[$config{'char'}]{'name'}) {
                                $chatRooms{$currentChatRoom}{'ownerID'} = $accountID;
                        } else {
                                $key = findKeyString(\%players, "name", $chatUser);
                                $chatRooms{$currentChatRoom}{'ownerID'} = $key;
                        }
                        $chatRooms{$currentChatRoom}{'users'}{$chatUser} = 2;
                } else {
                        $chatRooms{$currentChatRoom}{'users'}{$chatUser} = 1;
                }

        } elsif ($switch eq "00E5") {
                #00e5 < nick >.24b
                #Transaction request to receive
                my ($dealUser) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
                $incomingDeal{'name'} = $dealUser;
                $timeout{'ai_dealAutoCancel'}{'time'} = time;
                printc("wy", "<信息> ", "$dealUser (先生／小姐)询问您愿不愿意交易道具\n");
                parseInput("deal") if ($config{'dealAuto'});

        } elsif ($switch eq "00E7") {
                #00e7 < fail >.B
                #Transaction request response
                my $type = unpack("C1", substr($msg, 2, 1));
                if ($type == 0) {
                        printc("wr", "<信息> ", "超过可交易的距离\n");
                } elsif ($type == 1) {
                        printc("wr", "<信息> ", "没有您所指定的人物\n");
                } elsif ($type == 2) {
                        printc("wr", "<信息> ", "此人物与其他人物正在交易中\n");
                } elsif ($type == 3) {
                        if (%incomingDeal) {
                                $currentDeal{'name'} = $incomingDeal{'name'};
                        } else {
                                $currentDeal{'ID'} = $outgoingDeal{'ID'};
                                $currentDeal{'name'} = $players{$outgoingDeal{'ID'}}{'name'};
                        }
                        printc("ww", "<信息> ", "接受交易邀请 $currentDeal{'name'}\n");
                        parseInput("dl");
                }
                undef %outgoingDeal;
                undef %incomingDeal;

        } elsif ($switch eq "00E9") {
                #00e9 < amount >.l < type ID >.w < identify flag >.B < attribute? >.B < refine >.B < card >.4w
                #Item addition from partners
                my $amount = unpack("L*", substr($msg, 2,4));
                my $ID = unpack("S*", substr($msg, 6,2));
                if ($ID > 0) {
                        $currentDeal{'other'}{$ID}{'amount'} += $amount;
                        #------------------------------------------------------------------------------------------------------------
                        if ($currentDeal{'other'}{$ID}{'type_equip'}) {
                                $currentDeal{'other'}{$ID}{'refined'}      = unpack("C1", substr($msg, 10, 1));
                                if (unpack("S1", substr($msg, 11, 2)) == 0x00FF) {
                                        $currentDeal{'other'}{$ID}{'attribute'} = unpack("C1",substr($msg,9,1));
                                        $currentDeal{'other'}{$ID}{'star'} = unpack("C1",substr($msg,14,1)) / 0x05;
                                } else {
                                        $currentDeal{'other'}{$ID}{'card'}[0]   = unpack("S1", substr($msg, 11, 2));
                                        $currentDeal{'other'}{$ID}{'card'}[1]   = unpack("S1", substr($msg, 13, 2));
                                        $currentDeal{'other'}{$ID}{'card'}[2]   = unpack("S1", substr($msg, 15, 2));
                                        $currentDeal{'other'}{$ID}{'card'}[3]   = unpack("S1", substr($msg, 17, 2));
                                }
                        }
                        $currentDeal{'other'}{$ID}{'name'} = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
                        modifingName(\%{$currentDeal{'other'}{$ID}});
                        #------------------------------------------------------------------------------------------------------------
                        printc("ww", "<信息> ", "$currentDeal{'name'} 加入交易物品: $currentDeal{'other'}{$ID}{'name'} x $amount\n");
                        parseInput("dl");
                } elsif ($amount > 0) {
                        $currentDeal{'other_zenny'} += $amount;
                        printc("ww", "<信息> ", "$currentDeal{'name'} 加入交易金钱: $amount Zeny\n");
                        parseInput("dl");
                }

        } elsif ($switch eq "00EA") {
                #00ea < index >.w < fail >.B
                #item add to deal
                my $index = unpack("S1", substr($msg, 2, 2));
                my $fail = unpack("C1", substr($msg, 4, 1));
                if (!$fail) {
                        undef $invIndex;
                        if ($index > 0) {
                                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                                $currentDeal{'you'}{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}{'amount'} += $currentDeal{'lastItemAmount'};
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $currentDeal{'lastItemAmount'};
                                printc("ww", "<信息> ", "加入交易物品: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} x $currentDeal{'lastItemAmount'}\n");
                                if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
                                        undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
                                }
                                parseInput("dl");
                        } elsif ($currentDeal{'you_zenny'} > 0) {
                                $chars[$config{'char'}]{'zenny'} -= $currentDeal{'you_zenny'};
                        }
                } elsif ($fail == 1) {
                        printc("wr", "<信息> ", "对方人物超过最大负重量，无法拿取\n");
                }

        } elsif ($switch eq "00EC") {
                #00ec < fail >.B
                my $type = unpack("C1", substr($msg, 2, 1));
                if ($type == 1) {
                        $currentDeal{'other_finalize'} = 1;
                        printc("ww", "<信息> ", "$currentDeal{'name'} 确认交易\n");
                        parseInput("deal") if ($config{'dealAuto'});
                        parseInput("dl");
                } else {
                        $currentDeal{'you_finalize'} = 1;
                        printc("ww", "<信息> ", "确认交易\n");
                        if ($config{'dealAuto'}) {
                                sleep(1);
                                parseInput("deal");
                                printc("ww", "<信息> ", "确认最后交易\n");
                                parseInput("dl");
                        }
                }

        } elsif ($switch eq "00EE") {
                #00ee
                #Transaction was cancelled
                undef %incomingDeal;
                undef %outgoingDeal;
                undef %currentDeal;
                printc("wr", "<信息> ", "交易取消\n");

        } elsif ($switch eq "00F0") {
                #00f0
                #Completion of transaction
                printc("wc", "<信息> ", "交易道具成功\n");
                undef %currentDeal;

        } elsif ($switch eq "00F2") {
                #00f2 < num >.w < limit >.w
                #Kapra approved item quantity & present condition
                printc("wc", "<仓库> ", "打开仓库\n") if (!$storage{'items_max'});
                $storage{'items'} = unpack("S1", substr($msg, 2, 2));
                $storage{'items_max'} = unpack("S1", substr($msg, 4, 2));

        } elsif ($switch eq "00F4") {
                #00f4 < index >.w < amount >.l < type ID >.w < identify flag >.B < attribute? >.B < refine >.B < card >.4w
                #Item addition of Kapra warehouse
                my $index = unpack("S1", substr($msg, 2, 2));
                my $amount = unpack("L1", substr($msg, 4, 4));
                my $ID = unpack("S1", substr($msg, 8, 2));
                if (%{$storage{'inventory'}[$index]}) {
                        $storage{'inventory'}[$index]{'amount'} += $amount;
                } else {
                        $storage{'inventory'}[$index]{'nameID'} = $ID;
                        $storage{'inventory'}[$index]{'amount'} = $amount;
                        $storage{'inventory'}[$index]{'name'} = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
                        $storage{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, 10, 1));
			$storage{'inventory'}[$index]{'type_equip'} = $itemSlots_lut{$ID};
			if ($storage{'inventory'}[$index]{'type_equip'} == 1024) {
				$storage{'inventory'}[$index]{'borned'} = unpack("C1", substr($msg, 11, 1));
				$storage{'inventory'}[$index]{'named'} = unpack("C1", substr($msg, 19, 1));
			} elsif ($storage{'inventory'}[$index]{'type_equip'}) {
				$storage{'inventory'}[$index]{'broken'}       = unpack("C1", substr($msg, 11, 1));
				$storage{'inventory'}[$index]{'refined'}      = unpack("C1", substr($msg, 12, 1));
				if (unpack("S1", substr($msg, 13, 2)) == 0x00FF) {
					$storage{'inventory'}[$index]{'attribute'} = unpack("C1", substr($msg, 15, 1));
					$storage{'inventory'}[$index]{'star'}      = unpack("C1", substr($msg, 16, 1)) / 0x05;
					$storage{'inventory'}[$index]{'maker_charID'} = substr($msg, 17, 4);
	                        } else {
        	                        $storage{'inventory'}[$index]{'card'}[0]   = unpack("S1", substr($msg, 13, 2));
                	                $storage{'inventory'}[$index]{'card'}[1]   = unpack("S1", substr($msg, 15, 2));
                        	        $storage{'inventory'}[$index]{'card'}[2]   = unpack("S1", substr($msg, 17, 2));
                                	$storage{'inventory'}[$index]{'card'}[3]   = unpack("S1", substr($msg, 19, 2));
                                }
                        }
                        modifingName(\%{$storage{'inventory'}[$index]});
                }
                printc("wn", "<仓库> ", "增加: $storage{'inventory'}[$index]{'name'} x $amount\n");
                chatLog("b", "存仓: $storage{'inventory'}[$index]{'name'} x $amount\n");

        } elsif ($switch eq "00F6") {
                #00f6 < index >.w < amount >.l
                #Item deletion of Kapra warehouse
                my $index = unpack("S1", substr($msg, 2, 2));
                my $amount = unpack("L1", substr($msg, 4, 4));
                $storage{'inventory'}[$index]{'amount'} -= $amount;
                printc("wn", "<仓库> ", "减少: $storage{'inventory'}[$index]{'name'} x $amount\n");
                chatLog("b", "取仓: $storage{'inventory'}[$index]{'name'} x $amount\n");
                if ($storage{'inventory'}[$index]{'amount'} <= 0) {
                        undef %{$storage{'inventory'}[$index]};
                }

        } elsif ($switch eq "00F8") {
                #00f8
                #Kapra warehouse closing response
                printc("wc", "<仓库> ", "关闭仓库\n");
	        if ($storage{'items'} >= $storage{'items_max'} - 10) {
        	        printc("yy", "<系统> ", "仓库已经有$storage{'items'}种物品\n");
                	chatLog("x", "仓库已经有$storage{'items'}种物品\n");
	        }
		logItem("$logs_path/item_storage.txt", \%storage, "仓库物品");
                undef %storage;

        } elsif ($switch eq "00FA") {
                #00fa < fail >.B
                #party organized
                my $type = unpack("C1", substr($msg, 2, 1));
                if ($type == 1) {
                        printc("wr", "<信息> ", "这个组队名称已经有人使用\n");
                } elsif ($type == 2) {
                        printc("wr", "<信息> ", "已经加入组队中\n");
                }

        } elsif ($switch eq "00FB") {
                #00fb < len >.w < party name >.24b { < ID >.l < nick >.24b < map name >.16b < leader >.B < offline >.B }.46b*
                #Party information collecting, to send
                decrypt(\$newmsg, substr($msg, 28, length($msg)-28));
                $msg = substr($msg, 0, 28).$newmsg;
                ($chars[$config{'char'}]{'party'}{'name'}) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
                for (my $i = 28; $i < $msg_size;$i+=46) {
                        my $ID = substr($msg, $i, 4);
                        if (!%{$chars[$config{'char'}]{'party'}{'users'}{$ID}}) {
                                binAdd(\@partyUsersID, $ID);
                        }
                        ($chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'}) = substr($msg, $i + 4, 24) =~ /([\s\S]*?)\000/;
                        ($chars[$config{'char'}]{'party'}{'users'}{$ID}{'map'}) = substr($msg, $i + 28, 16) =~ /([\s\S]*?)\000/;
                        $chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = !(unpack("C1",substr($msg, $i + 45, 1)));
                        $chars[$config{'char'}]{'party'}{'users'}{$ID}{'admin'} = !(unpack("C1",substr($msg, $i + 44, 1)));
                }
                sendPartyShareEXP(\$remote_socket, 1) if ($config{'partyAutoShare'} && %{$chars[$config{'char'}]{'party'}});

        } elsif ($switch eq "00FD") {
                #00fd < nick >.24b < fail >.B
                #party join
                my ($name) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
                my $type = unpack("C1", substr($msg, 26, 1));
                if ($type == 0) {
                        printc("wr", "<信息> ", "$name 已经加入了其它组队\n");
                } elsif ($type == 1) {
                        printc("wr", "<信息> ", "$name 拒绝加入组队\n");
                } elsif ($type == 2) {
                        printc("wc", "<信息> ", "$name 成功加入组队\n");
                }

        } elsif ($switch eq "00FE") {
                my $ID = substr($msg, 2, 4);
                my ($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
                printc("wy", "<信息> ", "'$name' 送来一封邀请加入组队的讯息。请问您同意加入组队吗？\n");
                $incomingParty{'ID'} = $ID;
                $timeout{'ai_partyAutoDeny'}{'time'} = time;

        } elsif ($switch eq "0101") {
                my $type = unpack("C1", substr($msg, 2, 1));
                if ($type == 0) {
                        printc("wr", "<信息> ", "经验值分配方式: 各自取得\n");
                } elsif ($type == 1) {
                        printc("wc", "<信息> ", "经验值分配方式: 均等分配\n");
                } else {
                        printc("wr", "<信息> ", "只有组队队长可以设定\n");
                }

        } elsif ($switch eq "0104") {
                my $ID = substr($msg, 2, 4);
                my $x = unpack("S1", substr($msg,10, 2));
                my $y = unpack("S1", substr($msg,12, 2));
                my $type = unpack("C1",substr($msg, 14, 1));
                my ($name) = substr($msg, 15, 24) =~ /([\s\S]*?)\000/;
                my ($partyUser) = substr($msg, 39, 24) =~ /([\s\S]*?)\000/;
                my ($map) = substr($msg, 63, 16) =~ /([\s\S]*?)\000/;
                if (!%{$chars[$config{'char'}]{'party'}{'users'}{$ID}}) {
                        binAdd(\@partyUsersID, $ID);
                        if ($ID eq $accountID) {
                                printc("ww", "<信息> ", "成功加入组队 '$name'\n");
                        } else {
                                printc("ww", "<信息> ", "$partyUser 成功加入组队 '$name'\n");
                        }
                }
                if ($type == 0) {
                        $chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 1;
                } elsif ($type == 1) {
                        $chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 0;
                }
                $chars[$config{'char'}]{'party'}{'name'} = $name;
                $chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'x'} = $x;
                $chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'y'} = $y;
                $chars[$config{'char'}]{'party'}{'users'}{$ID}{'map'} = $map;
                $chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'} = $partyUser;

        } elsif ($switch eq "0105") {
                my $ID = substr($msg, 2, 4);
                my ($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
                undef %{$chars[$config{'char'}]{'party'}{'users'}{$ID}};
                binRemove(\@partyUsersID, $ID);
                if ($ID eq $accountID) {
                        printc("wr", "<信息> ", "已退出队伍\n");
                        undef %{$chars[$config{'char'}]{'party'}};
                        $chars[$config{'char'}]{'party'} = "";
                        undef @partyUsersID;
                } else {
                        printc("wr", "<信息> ", "$name 已退出队伍\n");
                }

        } elsif ($switch eq "0106") {
                my $ID = substr($msg, 2, 4);
                $chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp'} = unpack("S1", substr($msg, 6, 2));
                $chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp_max'} = unpack("S1", substr($msg, 8, 2));

        } elsif ($switch eq "0107") {
                my $ID = substr($msg, 2, 4);
                my $x = unpack("S1", substr($msg,6, 2));
                my $y = unpack("S1", substr($msg,8, 2));
                $chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'x'} = $x;
                $chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'y'} = $y;
                $chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 1;
                printc("gn", "->$switch ", "Party member location: $chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'} - $x, $y\n") if ($config{'debug'} >= 2);

        } elsif ($switch eq "0109") {
                decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
                $msg = substr($msg, 0, 8).$newmsg;
                my $chat = substr($msg, 8, $msg_size - 8);
                ($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
                $ai_cmdQue[$ai_cmdQue]{'type'} = "p";
                $ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser;
                $ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg;
                $ai_cmdQue[$ai_cmdQue]{'time'} = time;
                $ai_cmdQue++;
                chatLog("p", $chat."\n");
                printc("gmn", "<队聊> ", $chat, "\n");
                sendMsgToWindow("0109".chr(1).$chatMsgUser.chr(1).$chatMsg) if ($yelloweasy);
                if ($chatMsg eq $config{'username'}) {
                        sendMessage(\$remote_socket, "p", "断开连接$config{'dcOnDualLogin'}秒\n");
                        sleep(1);
                	$conState = 1;
                	undef $conState_tries;
                	$timeout_ex{'master'}{'time'} = time;
                	$timeout_ex{'master'}{'timeout'} = $config{'dcOnDualLogin'};
                	killConnection(\$remote_socket) if (!$xKore);
                }

        } elsif ($switch eq "010A") {
                my $ID = unpack("S1", substr($msg, 2, 2));
                printc("wy", "<信息> ", "成为MVP啰!! MVP 道具是 : ".$items_lut{$ID}."\n");
                chatLog("m", "成为MVP啰!! MVP 道具是 : ".$items_lut{$ID}."\n");
                useTeleport(1) if (!$xKore && !$vipLevel);

        } elsif ($switch eq "010B") {
                my $val = unpack("S1",substr($msg, 2, 2));
                printc("wy", "<信息> ", "成为MVP啰！！特别经验值 $val 取得！！\n");
                chatLog("m", "成为MVP啰！！特别经验值 $val 取得！！\n");
                useTeleport(1) if (!$xKore && !$vipLevel);                
                
        } elsif ($switch eq "010C") {
                my $ID = substr($msg, 2, 4);
                my $display = "未知";
                if ($ID eq $accountID) {
                        $display = "你";
                } elsif (%{$players{$ID}}) {
                        $display = "$players{$ID}{'name'} [$players{$ID}{'guild'}{'name'}] $players{$ID}{'party'}{'name'} $jobs_lut{$players{$ID}{'jobID'}}";
                }
                printc("wy", "<信息> ", "$display 成为 MVP!\n");
                chatLog("m", "$display 成为 MVP!\n");

        } elsif ($switch eq "010E") {
                my $ID = unpack("S1",substr($msg, 2, 2));
                my $lv = unpack("S1",substr($msg, 4, 2));
                $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$ID})}}{'lv'} = $lv;
                printc("gn", "->$switch ", "Skill $skillsID_lut{$ID}: $lv\n") if $config{'debug'};

        } elsif ($switch eq "010F") {
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                undef %{$chars[$config{'char'}]{'skills'}};
                undef @skillsID;
                for($i = 4;$i < $msg_size; $i+=37) {
                        my $ID = unpack("S1", substr($msg, $i, 2));
                        my ($name) = substr($msg, $i + 12, 24) =~ /([\s\S]*?)\000/;
                        if (!$name) {
                                $name = $skills_rlut{lc($skillsID_lut{$ID})};
                        }
                        $chars[$config{'char'}]{'skills'}{$name}{'ID'} = $ID;
                        if (!$chars[$config{'char'}]{'skills'}{$name}{'lv'}) {
                                $chars[$config{'char'}]{'skills'}{$name}{'lv'} = unpack("S1", substr($msg, $i + 6, 2));
                        }
                        $skillsID_lut{$ID} = $skills_lut{$name};
                        binAdd(\@skillsID, $name);
                }

        } elsif ($switch eq "0110") {
                my $skillID = unpack("S1", substr($msg, 2, 2));
                my $basicType = unpack("S1", substr($msg, 4, 2));
                my $fail = unpack("C1", substr($msg, 8, 1));
                my $type = unpack("C1", substr($msg, 9, 1));
                if (!$fail) {
                        aiRemove("skill_use");
                        printc("wrn", "<信息> " ,"$msgstrings_lut{'0110'}{$type} ", "$skillsID_lut{$skillID}\n") if (!$config{'hideMsg_skillFail'} && $config{'mode'});
                }

        } elsif ($switch eq "0111") {
        	# new skill information

        } elsif ($switch eq "0114" || $switch eq "01DE") {
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                $skillID = unpack("S1",substr($msg, 2, 2));
                $sourceID = substr($msg, 4, 4);
                $targetID = substr($msg, 8, 4);
                if ($switch eq "0114") {
                        $damage = unpack("s1",substr($msg, 24, 2));
                        $level = unpack("S1",substr($msg, 26, 2));
                } else {
                        $damage = unpack("l1",substr($msg, 24, 4));
                        $level = unpack("S1",substr($msg, 28, 2));
                }
                $level = 0 if ($level == 65535);
                if (%{$spells{$sourceID}}) {
                        $sourceID = $spells{$sourceID}{'sourceID'};
                }
                updateDamageTables($sourceID, $targetID, $damage) if ($damage != -30000);
                if ($sourceID eq $accountID) {
                        $chars[$config{'char'}]{'skills_used'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
                        undef $chars[$config{'char'}]{'time_cast'};
                }
                if (%{$monsters{$targetID}}) {
                        if ($sourceID eq $accountID) {
                                $monsters{$targetID}{'castOnByYou'}++;
                        } else {
                                $monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
                        }
                }
                if ($damage != -30000) {
                        if ($level_real ne "") {
                                     $level = $level_real;
                                     undef $level_real;
                        }
                        printAttack("s", $sourceID, $targetID, $damage, 0, 0, $skillID, $level);
                } else {
                        $level_real = $level;
                        printAttack("c", $sourceID, $targetID, 0, 0, 0, $skillID, $level);
                }

        } elsif ($switch eq "0115") {
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                $skillID = unpack("S1",substr($msg, 2, 2));
                $sourceID = substr($msg, 4, 4);
                $targetID = substr($msg, 8, 4);
                $coords{'x'} = unpack("S1",substr($msg, 24, 2));
                $coords{'y'} = unpack("S1",substr($msg, 26, 2));
                $damage = unpack("s1",substr($msg, 28, 2));
                $level = unpack("S1",substr($msg, 30, 2));
                if (%{$spells{$sourceID}}) {
                        $sourceID = $spells{$sourceID}{'sourceID'};
                }
                updateDamageTables($sourceID, $targetID, $damage) if ($damage != -30000);
		if ($sourceID eq $accountID) {
			$chars[$config{'char'}]{'skills_used'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
			undef $chars[$config{'char'}]{'time_cast'};
		}
                $level = 0 if ($level == 65535);
                if ($damage != -30000) {
                        if ($level_real ne "") {
                                     $level = $level_real;
                                     undef $level_real;
                        }
                        printAttack("s", $sourceID, $targetID, $damage, 0, 0, $skillID, $level);
                } else {
                        $level_real = $level;
                        printAttack("c", $sourceID, $targetID, 0, 0, 0, $skillID, $level);
                }

        } elsif ($switch eq "0117") {
                my $skillID = unpack("S1",substr($msg, 2, 2));
                my $sourceID = substr($msg, 4, 4);
                my $targetID = "pos";
                my $lv = unpack("S1",substr($msg, 8, 2));
                my $x = unpack("S1",substr($msg, 10, 2));
                my $y = unpack("S1",substr($msg, 12, 2));
                if ($sourceID eq $accountID) {
                        $chars[$config{'char'}]{'skills_used'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
                        undef $chars[$config{'char'}]{'time_cast'};
                }
                printAttack("c", $sourceID, $targetID, $x, $y, 0, $skillID, $lv);

        } elsif ($switch eq "0119") {
                my $ID = substr($msg, 2, 4);
                my $param1 = unpack("S1", substr($msg, 6, 2));
                my $param2 = unpack("S1", substr($msg, 8, 2));
                my $param3 = unpack("S1", substr($msg, 10, 2));
               	setStatus($ID, $param1, $param2, $param3);
	        my $AID = unpack("L1", $ID);
                if ($aid_rlut{$AID}{'avoid'}) {
                        binAdd(\@avoidID, $ID);
                }

        } elsif ($switch eq "011A") {
                $conState = 5 if ($conState != 2 && $conState != 4 && $xKore);
                my $skillID = unpack("S1",substr($msg, 2, 2));
                my $targetID = substr($msg, 6, 4);
                my $sourceID = substr($msg, 10, 4);
                my $amount = unpack("S1",substr($msg, 4, 2));
                $amount = 0 if ($amount == 65535);
                if (%{$spells{$sourceID}}) {
                        $sourceID = $spells{$sourceID}{'sourceID'};
                }
                if ($sourceID eq $accountID) {
                        $chars[$config{'char'}]{'skills_used'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
                        undef $chars[$config{'char'}]{'time_cast'};
                }
                if (%{$monsters{$targetID}}) {
                        if ($sourceID eq $accountID) {
                                $monsters{$targetID}{'castOnByYou'}++;
                        } else {
                                $monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
                        }
                }
                if ($skillID == 28) {
                        printAttack("h", $sourceID, $targetID, 0, 0, $amount, $skillID, 0);
                } else {
                        printAttack("u", $sourceID, $targetID, 0, 0, 0, $skillID, $amount);
                }

        } elsif ($switch eq "011C") {
                my $skillID = unpack("S1",substr($msg, 2, 2));
                undef @{$warp{'responses'}};
                for ($i=4; $i < 68;$i+=16) {
                        ($resp_name) = substr($msg, $i, 16) =~ /([\s\S]*?)\000/;
                        push @{$warp{'responses'}}, $resp_name if $resp_name ne "";
                }
                print "----------$skillsID_lut{$skillID}-----------\n";
                print "#  responses\n";
                for (my $i=0; $i < @{$warp{'responses'}};$i++) {
                        print sprintf("%2d %-23s\n",$i,$warp{'responses'}[$i]);
                }
                print "-------------------------------\n";
                printc("ww", "<对话> ", "输入 'warpto' 选择地图\n");

        } elsif ($switch eq "011E") {
                my $fail = unpack("C1", substr($msg, 2, 1));
                if ($fail) {
                        printc("wr", "<信息> ", "无法记忆空间移动场所\n");
                } else {
                        printc("wc", "<信息> ", "已记忆空间移动场所\n");
                }

        } elsif ($switch eq "011F") {
                #011f <dst ID>.l <src ID>.l <X>.w <Y>.w <type>.B <fail>.B
                #01c9 <dst ID>.l <src ID>.l <X>.w <Y>.w <type>.B <fail>.B ?.81b
                #area effect spell
                my $ID = substr($msg, 2, 4);
                my $SourceID = substr($msg, 6, 4);
                my $x = unpack("S1",substr($msg, 10, 2));
                my $y = unpack("S1",substr($msg, 12, 2));
                my $type = unpack("C1",substr($msg, 14, 1));
                $spells{$ID}{'sourceID'} = $SourceID;
                $spells{$ID}{'pos'}{'x'} = $x;
                $spells{$ID}{'pos'}{'y'} = $y;
                $spells{$ID}{'binID'} = $binID;
                $spells{$ID}{'distance'} = int(distance(\%{$chars[$config{'char'}]{'pos_to'}},\%{$spells{$ID}{'pos'}}));
                $spells{$ID}{'name'} = $msgstrings_lut{'011F'}{$type} eq "" ? "unknown $type" : $msgstrings_lut{'011F'}{$type};
                $binID = binAdd(\@spellsID, $ID);
                printc("wn", "<信息> ", "出现: $spells{$ID}{'name'} ($spells{$ID}{'pos'}{'x'},$spells{$ID}{'pos'}{'y'}) 距离: $spells{$ID}{'distance'}\n") if ($config{'mode'} >= 3);

        } elsif ($switch eq "0120") {
                #The area effect spell with ID dissappears
                my $ID = substr($msg, 2, 4);
                $spells{$ID}{'distance'} = int(distance(\%{$chars[$config{'char'}]{'pos_to'}},\%{$spells{$ID}{'pos'}}));
                printc("wn", "<信息> ", "消失: $spells{$ID}{'name'} ($spells{$ID}{'pos'}{'x'},$spells{$ID}{'pos'}{'y'}) 距离: $spells{$ID}{'distance'}\n") if ($config{'mode'} >= 3);
                undef %{$spells{$ID}};
                binRemove(\@spellsID, $ID);

        } elsif ($switch eq "0121") {
                $cart{'items'} = unpack("S1", substr($msg, 2, 2));
                $cart{'items_max'} = unpack("S1", substr($msg, 4, 2));
                $cart{'weight'} = int(unpack("L1", substr($msg, 6, 4)) / 10);
                $cart{'weight_max'} = int(unpack("L1", substr($msg, 10, 4)) / 10);

        } elsif ($switch eq "0122") {
                #"0122" sends non-stackable item info
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                for($i = 4; $i < $msg_size; $i+=20) {
                        my $index = unpack("S1", substr($msg, $i, 2));
                        my $ID = unpack("S1", substr($msg, $i+2, 2));
                        my $type = unpack("C1",substr($msg, $i+4, 1));
                        my $type_equip = unpack("S1", substr($msg, $i + 6, 2));
                        $cart{'inventory'}[$index]{'nameID'} = $ID;
                        $cart{'inventory'}[$index]{'amount'} = 1;
			$cart{'inventory'}[$index]{'type'} = $type;                        
                        $cart{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, $i+5, 1));
                        $cart{'inventory'}[$index]{'type_equip'} = ($itemSlots_lut{$ID}) ? $itemSlots_lut{$ID} : $type_equip;
			if ($cart{'inventory'}[$index]{'type_equip'} == 1024) {
				$cart{'inventory'}[$index]{'borned'} = unpack("C1", substr($msg, $i + 10, 1));
				$cart{'inventory'}[$index]{'named'} = unpack("C1", substr($msg, $i + 18, 1));
			} elsif ($cart{'inventory'}[$index]{'type_equip'}) {
				$cart{'inventory'}[$index]{'broken'}       = unpack("C1", substr($msg, $i + 10, 1));
				$cart{'inventory'}[$index]{'refined'}      = unpack("C1", substr($msg, $i + 11, 1));
                                if (unpack("S1", substr($msg, $i+12, 2)) == 0x00FF) {
                                        $cart{'inventory'}[$index]{'attribute'} = unpack("C1", substr($msg, $i+14, 1));
                                        $cart{'inventory'}[$index]{'star'}      = unpack("C1", substr($msg, $i+15, 1))/ 0x05;
                                        $cart{'inventory'}[$index]{'maker_charID'} = substr($msg, $i + 16, 4);
                                } else {
                                        $cart{'inventory'}[$index]{'card'}[0]   = unpack("S1", substr($msg, $i+12, 2));
                                        $cart{'inventory'}[$index]{'card'}[1]   = unpack("S1", substr($msg, $i+14, 2));
                                        $cart{'inventory'}[$index]{'card'}[2]   = unpack("S1", substr($msg, $i+16, 2));
                                        $cart{'inventory'}[$index]{'card'}[3]   = unpack("S1", substr($msg, $i+18, 2));
                                }
                        }
                        $cart{'inventory'}[$index]{'name'} = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
                        modifingName(\%{$cart{'inventory'}[$index]});
                        printc("gn", "->$switch ", "Non-Stackable Cart Item: $cart{'inventory'}[$index]{'name'} ($index) x 1\n") if ($config{'debug'} >= 1);
                }

        } elsif ($switch eq "0123" || $switch eq "01EF") {
                #"0123" sends stackable item info
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                my $block_size = ($switch eq "0123") ? 10 : 18;
                for($i = 4; $i < $msg_size; $i+=$block_size) {
                        my $index = unpack("S1", substr($msg, $i, 2));
                        my $ID = unpack("S1", substr($msg, $i+2, 2));
                        my $type   = unpack("C1", substr($msg, $i + 4, 1));
                        my $amount = unpack("S1", substr($msg, $i+6, 2));
                        $cart{'inventory'}[$index]{'nameID'} = $ID;
                        $cart{'inventory'}[$index]{'amount'} = $amount;
                        $cart{'inventory'}[$index]{'type'} = $type;
                        $cart{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
                        $cart{'inventory'}[$index]{'name'} = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
                        printc("gn", "->$switch ", "Stackable Cart Item: $cart{'inventory'}[$index]{'name'} ($index) x $amount\n") if ($config{'debug'} >= 1);
                }

        } elsif ($switch eq "0124") {
                my $index = unpack("S1", substr($msg, 2, 2));
                my $amount = unpack("L1", substr($msg, 4, 4));
                my $ID = unpack("S1", substr($msg, 8, 2));
                if (%{$cart{'inventory'}[$index]}) {
                        $cart{'inventory'}[$index]{'amount'} += $amount;
                } else {
                        $cart{'inventory'}[$index]{'nameID'} = $ID;
                        $cart{'inventory'}[$index]{'amount'} = $amount;
                        #------------------------------------------------------------------------------------------------------------
                        #<index>.w <amount>.l <item ID>.w <identify flag>.B <attribute?>.B <refine>.B <card>.4w
                        $cart{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, 10, 1));
                        $cart{'inventory'}[$index]{'refined'} = unpack("C1", substr($msg, 12, 1));
                        $cart{'inventory'}[$index]{'type_equip'} = $itemSlots_lut{$ID};
			if ($cart{'inventory'}[$index]{'type_equip'} == 1024) {
				$cart{'inventory'}[$index]{'borned'} = unpack("C1", substr($msg, 11, 1));
				$cart{'inventory'}[$index]{'named'} = unpack("C1", substr($msg, 19, 1));
			} elsif ($cart{'inventory'}[$index]{'type_equip'}) {
				$cart{'inventory'}[$index]{'broken'}       = unpack("C1", substr($msg, 11, 1));
				$cart{'inventory'}[$index]{'refined'}      = unpack("C1", substr($msg, 12, 1));
	                        if (unpack("S1", substr($msg, 13, 2)) == 0x00FF) {
        	                        $cart{'inventory'}[$index]{'attribute'} = unpack("C1", substr($msg, 15, 1));
                	                $cart{'inventory'}[$index]{'star'}      = unpack("C1", substr($msg, 16, 1))/ 0x05;
                	                $cart{'inventory'}[$index]{'maker_charID'} = substr($msg, 17, 4);
                        	} else {
                                	$cart{'inventory'}[$index]{'card'}[0]   = unpack("S1", substr($msg, 13, 2));
	                                $cart{'inventory'}[$index]{'card'}[1]   = unpack("S1", substr($msg, 15, 2));
        	                        $cart{'inventory'}[$index]{'card'}[2]   = unpack("S1", substr($msg, 17, 2));
                	                $cart{'inventory'}[$index]{'card'}[3]   = unpack("S1", substr($msg, 19, 2));
                	        }
                        }
                        $cart{'inventory'}[$index]{'name'} = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
                        modifingName(\%{$cart{'inventory'}[$index]});
                }
                printc("wn", "<车子> ", "增加: $cart{'inventory'}[$index]{'name'} x $amount\n");

        } elsif ($switch eq "0125") {
                my $index = unpack("S1", substr($msg, 2, 2));
                my $amount = unpack("L1", substr($msg, 4, 4));
                $cart{'inventory'}[$index]{'amount'} -= $amount;
                printc("wn", "<车子> ", "减少: $cart{'inventory'}[$index]{'name'} x $amount\n");
                if ($cart{'inventory'}[$index]{'amount'} <= 0) {
                        undef %{$cart{'inventory'}[$index]};
                }

        } elsif ($switch eq "012C") {
                my $fail = unpack("C1", substr($msg, 2, 1));
                my $index = unpack("S1", substr($msg, 3, 2));
                my $amount = unpack("L1", substr($msg, 7, 2));
                my $ID = unpack("S1", substr($msg, 9, 2));
                if ($fail == 0) {
                        printc("wr", "<车子> ", "手推车的负重量已超过上限\n");
                } elsif ($fail == 1) {
                        printc("wr", "<车子> ", "手推车的物品数量已超过上限\n");
                }

        } elsif ($switch eq "012D") {
                #used vending skill.
                my $amount = unpack("S1", substr($msg, 2, 2));
                printc("wn", "<信息> ", "商店可以放$amount样物品\n");

        } elsif ($switch eq "0131") {
                #Street stall signboard indication
                $ID = substr($msg,2,4);
                if (!%{$venderLists{$ID}}) {
                        binAdd(\@venderListsID, $ID);
                }
                ($venderLists{$ID}{'title'}) = substr($msg,6,36) =~ /(.*?)\000/;

        } elsif ($switch eq "0132") {
                #Street stall signboard elimination
                $ID = substr($msg,2,4);
                binRemove(\@venderListsID, $ID);
                undef %{$venderLists{$ID}};

        } elsif ($switch eq "0133") {
                undef @venderItemList;
                undef $venderID;
                $venderID = substr($msg,4,4);
                $venderItemList = 0;
                for ($i = 8; $i < $msg_size; $i+=22) {
                        $index = unpack("S1", substr($msg, $i + 6, 2));
                        $ID = unpack("S1", substr($msg, $i + 9, 2));
                        $venderItemList[$index]{'nameID'} = $ID;
                        $venderItemList[$index]{'name'} = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
                        #------------------------------------------------------------------------------------------------------------
                        $venderItemList[$index]{'price'} = unpack("L1", substr($msg, $i, 4));
                        $venderItemList[$index]{'amount'} = unpack("S1", substr($msg, $i + 4, 2));
                        $venderItemList[$index]{'type'} = unpack("C1", substr($msg, $i + 8, 1));
                        $venderItemList[$index]{'type_equip'} = $itemSlots_lut{$ID};
                        $venderItemList[$index]{'identified'} = unpack("C1", substr($msg, $i + 11, 1));
			if ($venderItemList[$index]{'type_equip'} == 1024) {
				$venderItemList[$index]{'borned'} = unpack("C1", substr($msg, $i + 12, 1));
				$venderItemList[$index]{'named'} = unpack("C1", substr($msg, $i + 20, 1));
			} elsif ($venderItemList[$index]{'type_equip'}) {
				$venderItemList[$index]{'broken'} = unpack("C1", substr($msg, $i + 12, 1));
				$venderItemList[$index]{'refined'} = unpack("C1", substr($msg, $i + 13, 1));
	                        if (unpack("S1", substr($msg,$i+14, 2)) == 0x00FF) {
        	                        $venderItemList[$index]{'attribute'} = unpack("C1", substr($msg,$i+16, 1));
                	                $venderItemList[$index]{'star'}      = unpack("C1", substr($msg,$i+17, 1)) / 0x05;
                	                $venderItemList[$index]{'maker_charID'} = substr($msg, $i + 18, 4);
                        	} else {
	                                $venderItemList[$index]{'card'}[0] = unpack("S1", substr($msg, $i + 14, 2));
        	                        $venderItemList[$index]{'card'}[1] = unpack("S1", substr($msg, $i + 16, 2));
                	                $venderItemList[$index]{'card'}[2] = unpack("S1", substr($msg, $i + 18, 2));
                        	        $venderItemList[$index]{'card'}[3] = unpack("S1", substr($msg, $i + 20, 2));
                        	}
                        }
                        modifingName(\%{$venderItemList[$index]});
                        #------------------------------------------------------------------------------------------------------------
                        $venderItemList++;
                        printc("gn", "->$switch ", "Item added to Vender Store: $items{$ID}{'name'} - $price z\n") if ($config{'debug'} >= 2);
                }
                printc("wc", "<信息> ", "你进入了露天商店\n");
                parseInput("shop item");


        } elsif ($switch eq "0135") {
                #Failure of street stall item purchase.
		my $index = unpack("S1", substr($msg, 2, 2));
		my $amount = unpack("S1", substr($msg, 4, 2));
                my $fail = unpack("C1",substr($msg,6,1));
                if (!$fail) {
                	printc("wc", "<信息> ", $msgstrings_lut{$switch}{$fail}."\n");
                } else {
			printc("wr", "<信息> ", $msgstrings_lut{$switch}{$fail}."\n");
		}
		
        } elsif ($switch eq "0136") {
                undef %shop;
                $shop{'title'} = $shop_control{'shop_title'};
                $shop{'openTime'} = time;
                $chars[$config{'char'}]{'shopOpened'} = 1;
                for ($i = 8; $i < $msg_size; $i+=22) {
                        $index = unpack("S1", substr($msg, $i + 4, 2));
                        $shop{'inventory'}[$index]{'price'} = unpack("L1", substr($msg, $i, 4));
                        $shop{'inventory'}[$index]{'amount'} = unpack("S1", substr($msg, $i + 6, 2));
                        $shop{'inventory'}[$index]{'type'} = unpack("C1", substr($msg, $i + 8, 1));
                        $ID = unpack("S1", substr($msg, $i + 9, 2));
                        $shop{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, $i + 11, 1));
			$shop{'inventory'}[$index]{'type_equip'} = $itemSlots_lut{$ID};
                        $shop{'inventory'}[$index]{'nameID'} = $ID;
                        # parse Card & Elements
                        #------------------------------------------------------------------------------------------------------------
                        #<value>.l <index>.w <amount>.w <type>.B <item ID>.w <identify flag>.B <attribute?>.B <refine>.B <card>.4w
                        $shop{'inventory'}[$index]{'name'} = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
			if ($shop{'inventory'}[$index]{'type_equip'} == 1024) {
				$shop{'inventory'}[$index]{'borned'} = unpack("C1", substr($msg, $i + 12, 1));
				$shop{'inventory'}[$index]{'named'} = unpack("C1", substr($msg, $i + 20, 1));
			} elsif ($shop{'inventory'}[$index]{'type_equip'}) {
	                        $shop{'inventory'}[$index]{'refined'} = unpack("C1", substr($msg, $i + 13, 1));
        	                if (unpack("S1", substr($msg,$i+14, 2)) == 0x00FF) {
                	                $shop{'inventory'}[$index]{'attribute'} = unpack("C1", substr($msg,$i+16, 1));
                        	        $shop{'inventory'}[$index]{'star'}      = unpack("C1", substr($msg,$i+17, 1)) / 0x05;
                        	        $shop{'inventory'}[$index]{'maker_charID'} = substr($msg, $i + 18, 4);
	                        } else {
        	                        $shop{'inventory'}[$index]{'card'}[0] = unpack("S1", substr($msg, $i + 14, 2));
                	                $shop{'inventory'}[$index]{'card'}[1] = unpack("S1", substr($msg, $i + 16, 2));
                        	        $shop{'inventory'}[$index]{'card'}[2] = unpack("S1", substr($msg, $i + 18, 2));
                                	$shop{'inventory'}[$index]{'card'}[3] = unpack("S1", substr($msg, $i + 20, 2));
                                }
                        }
                        modifingName(\%{$shop{'inventory'}[$index]});
                }
                printc("wc", "<信息> ", "你的露天商店开张了\n");
                parseInput("shop");

        } elsif ($switch eq "0137") {
                my $index = unpack("S1",substr($msg, 2, 2));
                my $amount = unpack("S1",substr($msg, 4, 2));
                my $price = $amount * $shop{'inventory'}[$index]{'price'};
                $shop{'inventory'}[$index]{'sold'} += $amount;
                $shop{'inventory'}[$index]{'total'} = $amount * $shop{'inventory'}[$index]{'price'};
                $chars[$config{'char'}]{'shopEarned'} += $shop{'inventory'}[$index]{'total'};
                $shop{'inventory'}[$index]{'amount'} -= $amount;
                printc("ww", "<车子> ", "出售: $shop{'inventory'}[$index]{'name'} x $amount  单价: $shop{'inventory'}[$index]{'price'} zeny  总价: $shop{'inventory'}[$index]{'total'} zeny\n");
                chatLog("b", "出售: $shop{'inventory'}[$index]{'name'} x $amount  价格: $shop{'inventory'}[$index]{'price'} zeny\n");
                if ($shop{'inventory'}[$index]{'amount'} < 1) {
                        printc("ww", "<车子> ", "全部售出: $shop{'inventory'}[$index]{'name'}\n");
			$shop{'soldOutIndex'} = $index;
			$shop{'soldOutTime'} = time;
                }

        } elsif ($switch eq "0139") {
                my $ID = substr($msg, 2, 4);
                my $type = unpack("C1",substr($msg, 14, 1));
                $coords1{'x'} = unpack("S1",substr($msg, 6, 2));
                $coords1{'y'} = unpack("S1",substr($msg, 8, 2));
                $coords2{'x'} = unpack("S1",substr($msg, 10, 2));
                $coords2{'y'} = unpack("S1",substr($msg, 12, 2));
                # Adjust monster position
                %{$monsters{$ID}{'pos_attack_info'}} = %coords1;
                %{$chars[$config{'char'}]{'pos'}} = %coords2;
                %{$chars[$config{'char'}]{'pos_to'}} = %coords2;
                printc("gn", "->$switch ", "Recieved attack location You $coords2{'x'}, $coords2{'y'} and $monsters{$ID}{'name'}($monsters{$ID}{'binID'}) $coords1{'x'}, $coords1{'y'}\n") if ($config{'debug'} >=2);

        } elsif ($switch eq "013A") {
                $chars[$config{'char'}]{'attack_rang'} = unpack("S1",substr($msg, 2, 2));
                printc("gn", "->$switch ", "Your Real Attack Range is : $chars[$config{'char'}]{'attack_rang'}\n") if ($config{'debug'});

        } elsif ($switch eq "013B") {
                my $type = unpack("S1",substr($msg, 2, 2));
                if ($type == 0) {
                        printc("wr", "<信息> ", "请先装备箭矢\n");
                        undef $invIndex;
                        my $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "type", 10);
                        sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}, $chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}) if ($invIndex ne "");
                } elsif ($type == 3) {
                        printc("wg", "<信息> ", "已装备箭矢\n") if ($config{'mode'} >= 3);
                }

        } elsif ($switch eq "013C") {
                my $index = unpack("S1", substr($msg, 2, 2));
       	        undef $invIndex;
                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                $chars[$config{'char'}]{'eq_arrow_index'} = $index;
		if ($chars[$config{'char'}]{'eq_arrow_index'}) {
	                if ($invIndex ne "") {
        	                printc("wgn", "<信息> ", "箭矢装备完成 ", "$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}\n") if ($config{'mode'} && !$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'});
                	        $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = 32768;
	                }
                } else {
	                if ($invIndex ne "") {
        	                printc("wrn", "<信息> ", "箭矢卸下完成 ", "$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}\n") if ($config{'mode'} >= 2);
                	        undef $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'};
	                }
                }

        } elsif ($switch eq "013D") {
                my $type = unpack("S1",substr($msg, 2, 2));
                my $amount = unpack("S1",substr($msg, 4, 2));
                if ($type == 5) {
                        $chars[$config{'char'}]{'hp'} += $amount;
                        $chars[$config{'char'}]{'hp'} = $chars[$config{'char'}]{'hp_max'} if ($chars[$config{'char'}]{'hp'} > $chars[$config{'char'}]{'hp_max'});
                } elsif ($type == 7) {
                        $chars[$config{'char'}]{'sp'} += $amount;
                        $chars[$config{'char'}]{'sp'} = $chars[$config{'char'}]{'sp_max'} if ($chars[$config{'char'}]{'sp'} > $chars[$config{'char'}]{'sp_max'});
                }

        } elsif ($switch eq "013E") {
                my $sourceID = substr($msg, 2, 4);
                my $targetID = substr($msg, 6, 4);
                my $x = unpack("S1",substr($msg, 10, 2));
                my $y = unpack("S1",substr($msg, 12, 2));
                my $skillID = unpack("S1",substr($msg, 14, 2));
                my $wait = unpack("L1",substr($msg, 20, 4)) / 1000;
                if ($sourceID eq $accountID) {
                        $chars[$config{'char'}]{'time_cast'} = time;
                }
                if (%{$monsters{$targetID}}) {
                        if ($sourceID eq $accountID) {
                                $monsters{$targetID}{'castOnByYou'}++;
                        } else {
                                $monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
                        }
                } elsif (%{$players{$targetID}} || $targetID eq $accountID) {

                } elsif ($x != 0 || $y != 0) {
                        $targetID = "pos";
                }
                printAttack("c", $sourceID, $targetID, $x, $y, 0, $skillID, 0);

        } elsif ($switch eq "0141") {
                my $type = unpack("S1",substr($msg, 2, 2));
                my $val = unpack("S1",substr($msg, 6, 2));
                my $val2 = unpack("S1",substr($msg, 10, 2));
                if ($type == 13) {
                        $chars[$config{'char'}]{'str'} = $val;
                        $chars[$config{'char'}]{'str_bonus'} = $val2;
                        printc("gn", "->$switch ","Strength: $val + $val2\n") if $config{'debug'};
                } elsif ($type == 14) {
                        $chars[$config{'char'}]{'agi'} = $val;
                        $chars[$config{'char'}]{'agi_bonus'} = $val2;
                        printc("gn", "->$switch ","Agility: $val + $val2\n") if $config{'debug'};
                } elsif ($type == 15) {
                        $chars[$config{'char'}]{'vit'} = $val;
                        $chars[$config{'char'}]{'vit_bonus'} = $val2;
                        printc("gn", "->$switch ","Vitality: $val + $val2\n") if $config{'debug'};
                } elsif ($type == 16) {
                        $chars[$config{'char'}]{'int'} = $val;
                        $chars[$config{'char'}]{'int_bonus'} = $val2;
                        printc("gn", "->$switch ","Intelligence: $val + $val2\n") if $config{'debug'};
                } elsif ($type == 17) {
                        $chars[$config{'char'}]{'dex'} = $val;
                        $chars[$config{'char'}]{'dex_bonus'} = $val2;
                        printc("gn", "->$switch ","Dexterity: $val + $val2\n") if $config{'debug'};
                } elsif ($type == 18) {
                        $chars[$config{'char'}]{'luk'} = $val;
                        $chars[$config{'char'}]{'luk_bonus'} = $val2;
                        printc("gn", "->$switch ","Luck: $val + $val2\n") if $config{'debug'};
                }

        } elsif ($switch eq "0142") {
                my $ID = substr($msg, 2, 4);
                printc("ww", "<对话> ", "$npcs{$ID}{'name'} : 输入 'talk answer <数量>' 选择数量。\n");

	} elsif ($switch eq "0144") {
		# map mark
		my $ID = substr($msg, 2, 4);
		my $type = unpack("S1",substr($msg, 6, 2));
		my $x = unpack("S*",substr($msg, 10, 2));
		my $y = unpack("S*",substr($msg, 14, 2));
		my $index = unpack("C*",substr($msg, 18, 1));
		my $color_b = unpack("C*",substr($msg, 19, 1));
		my $color_g = unpack("C*",substr($msg, 20, 1));
		my $color_r = unpack("C*",substr($msg, 21, 1));
		if ($type == 2) {
			printc("nn", "<对话> ", "$npcs{$ID}{'name'} : 删除地图标记 $index 位于 ($x,$y)\n");
		} else {
			printc("nn", "<对话> ", "$npcs{$ID}{'name'} : 显示地图标记 $index 位于 ($x,$y)\n");	
		}

        } elsif ($switch eq "0147") {
                my $skillID = unpack("S*",substr($msg, 2, 2));
                my $skillLv = unpack("S*",substr($msg, 8, 2));
                printc("gn", "->$switch ", "You get temporary skill $skillsID_lut{$skillID}($skillID) Lv $skillLv\n") if ($config{'debug'});
                if ($skillID == 54 && $resurrectID ne "") {
                	printc("wn", "<信息> ", "获得临时技能 $skillsID_lut{$skillID}$skillLv级\n");
                        sendSkillUse(\$remote_socket, $skillID, $skillLv, $resurrectID);
                        undef $resurrectID;
                } elsif (!$xKore && $skillID == 26) {
			printc("wn", "<信息> ", "获得临时技能 $skillsID_lut{$skillID}$skillLv级\n");
                	if (time - $chars[$config{'char'}]{'randomSkill_send_time'} < 2) {
                		relog();
                	} else {
	                        sendSkillUse(\$remote_socket, $skillID, $skillLv, $accountID);
	                }
                } elsif (($config{'randomSkillAuto'} == 1 && $skillID == 292) || ($config{'randomSkillAuto'} == 2 && $skillID == 297)) {
			printc("wy", "<信息> ", "获得临时技能 $skillsID_lut{$skillID}$skillLv级\n");
			chatLog("m", "获得临时技能 $skillsID_lut{$skillID}$skillLv级\n");
		}

        } elsif ($switch eq "0148") {
                my $ID = substr($msg, 2, 4);
                if ($ID eq $accountID) {
                        printc("wy", "<信息> ", "你 已经复活了\n");
                        chatLog("m", "你已经复活了。 $field{'name'} ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        undef $chars[$config{'char'}]{'dead'};
                        undef $chars[$config{'char'}]{'dead_time'};
                } elsif (%{$players{$ID}}) {
                        printc("nn", "<信息> ", "$players{$ID}{'name'}($players{$ID}{'binID'}) 已经复活了\n") if ($config{'mode'});
                        undef $players{$ID}{'dead'};
                }

        } elsif ($switch eq "0152") {
		# guild emblem image

        } elsif ($switch eq "0154") {
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                my $id;
                for(my $i = 4; $i < $msg_size; $i+=104) {
                        $id = substr($msg, $i+4, 4);
                        $chars[$config{'char'}]{'guild'}{'members'}{$id}{'accountID'} = substr($msg, $i, 4);
                        $chars[$config{'char'}]{'guild'}{'members'}{$id}{'nameID'} = substr($msg, $i+4, 4);
                        $chars[$config{'char'}]{'guild'}{'members'}{$id}{'sex'} = unpack("S1",substr($msg, $i+12, 2));
                        $chars[$config{'char'}]{'guild'}{'members'}{$id}{'job'} = unpack("S1",substr($msg, $i+14, 2));
                        $chars[$config{'char'}]{'guild'}{'members'}{$id}{'lv'} = unpack("S1",substr($msg, $i+16, 2));
                        $chars[$config{'char'}]{'guild'}{'members'}{$id}{'exp'} = unpack("L1",substr($msg, $i+18, 4));
                        $chars[$config{'char'}]{'guild'}{'members'}{$id}{'online'} = unpack("L1",substr($msg, $i+22, 4));
                        $chars[$config{'char'}]{'guild'}{'members'}{$id}{'position'} = unpack("L1",substr($msg, $i+26, 4));
                        ($chars[$config{'char'}]{'guild'}{'members'}{$id}{'name'}) = substr($msg, $i+80, 24) =~ /([\s\S]*?)\000/;
                }

        } elsif ($switch eq "0160") {
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                my ($num,$join,$kick);
                for(my $i = 4; $i < $msg_size; $i+=16) {
                        $num = unpack("L*",substr($msg, $i, 4));
                        $join = (unpack("C1",substr($msg, $i+4, 1)) & 0x01) ? 1 : '';
                        $kick = (unpack("C1",substr($msg, $i+4, 1)) & 0x10) ? 1 : '';
                        $chars[$config{'char'}]{'guild'}{'positions'}[$num]{'join'} = $join;
                        $chars[$config{'char'}]{'guild'}{'positions'}[$num]{'kick'} = $kick;
                        $chars[$config{'char'}]{'guild'}{'positions'}[$num]{'feeEXP'} = unpack("L1",substr($msg, $i+12, 4));
                }

        } elsif ($switch eq "0166") {
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                my ($num,$name);
                for(my $i = 4; $i < $msg_size; $i+=28) {
                        $num = unpack("L1",substr($msg, $i, 4));
                        ($name) = substr($msg, $i+4, 24) =~ /([\s\S]*?)\000/;
                        $chars[$config{'char'}]{'guild'}{'positions'}[$num]{'name'} = $name;
                }


        } elsif ($switch eq "016A") {
                # guild request for you
                $ID = substr($msg, 2, 4);
                ($name) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
                printc("wy", "<信息> ", "从 '$name' 公会送来 ,邀请加入的讯息。请问您是否同意加入公会？\n");
                $incomingGuild{'ID'} = $ID;
                $incomingGuild{'Type'} = 1;
                $timeout{'ai_guildAutoDeny'}{'time'} = time;

        } elsif ($switch eq "016C") {
                ($chars[$config{'char'}]{'guild'}{'name'}) = substr($msg, 19, 24) =~ /([\s\S]*?)\000/;

        } elsif ($switch eq "016D") {
                my $ID = substr($msg, 2, 4);
                my $TargetID =  substr($msg, 6, 4);
                my $type = unpack("L1", substr($msg, 10, 4));
                if ($config{'mode'} >= 2) {
                        my $isOnline;
                        if ($type) {
                                $isOnline = "上线了";
                        } else {
                                $isOnline = "离线了";
                        }
\                       printc("wc", "<信息> ", "公会成员（$chars[$config{'char'}]{'guild'}{'members'}{$ID}{'name'} 先生，小姐）$isOnline。\n");
                 }

        } elsif ($switch eq "016F") {
                my ($address) = substr($msg, 2, 60) =~ /([\s\S]*?)\000/;
                my ($message) = substr($msg, 62, 120) =~ /([\s\S]*?)\000/;
                if ($config{'mode'} >= 2 || ($config{'mode'} && $message ne $guild_message)) {
                        printc("y", "---- 工会信息 ----\n");
                        printc("y", "$address\n\n");
                        printc("y", "$message\n");
                        printc("y", "------------------\n");
                }
                our $guild_message = $message;

        } elsif ($switch eq "0171") {
                my $ID = substr($msg, 2, 4);
                my ($name) = substr($msg, 6, 24) =~ /[\s\S]*?\000/;
                printc("wy", "<信息> ", "从 '$name' 公会收到邀请加入同盟的讯息。请问您是否愿意加入同盟？\n");
                $incomingGuild{'ID'} = $ID;
                $incomingGuild{'Type'} = 2;
                $timeout{'ai_guildAutoDeny'}{'time'} = time;

        } elsif ($switch eq "0174") {
                #$givenPercent = unpack("L1", substr($msg, 16, 4));
                #$PositionDesc = substr($msg, 20, 24);

        } elsif ($switch eq "0177") {
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                undef @identifyID;
                undef $invIndex;
                for ($i = 4; $i < $msg_size; $i += 2) {
                        $index = unpack("S1", substr($msg, $i, 2));
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                        binAdd(\@identifyID, $invIndex);
                }
                printc("wn", "<信息> ", "接收可鉴定物品列表 - 输入 'identify'\n");
                parseInput("identify") if (!$xKore);

        } elsif ($switch eq "0179") {
                $index = unpack("S*",substr($msg, 2, 2));
                undef $invIndex;
                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                $chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = 1;
                printc("w", "<物品> ", "n", "鉴定: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}\n");
                undef @identifyID;

        } elsif ($switch eq "017F") {
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                my $ID = substr($msg, 4, 4);
                my $chat = substr($msg, 4, $msg_size - 4);
                my ($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
                $ai_cmdQue[$ai_cmdQue]{'type'} = "g";
                $ai_cmdQue[$ai_cmdQue]{'ID'} = $ID;
                $ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser;
                $ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg;
                $ai_cmdQue[$ai_cmdQue]{'time'} = time;
                $ai_cmdQue++;

                printc("ggn", "<工会> ", $chat, "\n");               
       		my @args = split /\|/, $chatMsg;
                if ($config{'mvpMode'} && $args[0] eq "[KM]") {
			mvpNoticeRecv($args[1],$args[2],$args[3],$args[4],$args[5],$args[6],$args[7]);
                } else {
                        chatLog("g", $chat."\n");
                }
                sendMsgToWindow("017F".chr(1).$chatMsgUser.chr(1).$chatMsg) if ($yelloweasy);

        } elsif ($switch eq "0188") {
                my $fail =  unpack("S1",substr($msg, 2, 2));
                my $index = unpack("S1",substr($msg, 4, 2));
                my $refined = unpack("S1",substr($msg, 6, 2));
                if ($fail) {
                        printc("gn", "->$switch ", "Refined failure\n") if $config{'debug'};
                } else {
                        undef $invIndex;
                        my $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = $items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}};
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'refined'} = unpack("C1",substr($msg, 6,  2));
                        modifingName(\%{$chars[$config{'char'}]{'inventory'}[$invIndex]});
                        printc("gn", "->$switch ", "Refined Change : $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}\n") if $config{'debug'};
                }

        } elsif ($switch eq "0189") {
                #failed to use teleport or memo
                printc("wr", "<信息> " , "瞬间移动失败\n");

        } elsif ($switch eq "018B") {
                #quit game
                $fail = unpack("S1", substr($msg, 2, 2));
                if (!$fail) {
                        quit();
                } else {
                        printc("yr", "<系统> ", "现在无法离线\n");
                        if (!$xKore) {
                        	killConnection(\$remote_socket);
                        	relog();
                        } else {
	                        ai_clientSuspend(0,2);
	                }
                }

        } elsif ($switch eq "0194") {
                #Parse Guildman Connect
                my $ID = substr($msg, 2, 4);
                if ($accountID ne $ID) {
                        my ($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
                }
                sendGuildRequest(\$remote_socket, 0);
                sendGuildRequest(\$remote_socket, 1);
                sendGuildRequest(\$remote_socket, 2);

        } elsif ($switch eq "0195") {
                #0195 < ID >.l < nick >.24b < party name >.24b < guild name >.24b < class name >.24b
                #player info
                my $ID = substr($msg, 2, 4);
                if (%{$players{$ID}}) {
                        ($players{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
                        ($players{$ID}{'party'}{'name'}) = substr($msg, 30, 24) =~ /([\s\S]*?)\000/;
                        ($players{$ID}{'guild'}{'name'}) = substr($msg, 54, 24) =~ /([\s\S]*?)\000/;
                        ($players{$ID}{'guild'}{'men'}{$players{$ID}{'name'}}{'title'}) = substr($msg, 78, 24) =~ /([\s\S]*?)\000/;
                        printc("gn", "->$switch ", "Player Info: $players{$ID}{'name'}($players{$ID}{'binID'})\n") if ($config{'debug'} >= 2);
                        if ($avoidlist_rlut{$players{$ID}{'name'}} && binFind(\@avoidID, $ID) eq "") {
                                $players{$ID}{'nameID'} = unpack("L1", $ID);
                                binAdd(\@avoidID, $ID);
                                $aid_rlut{$players{$ID}{'nameID'}}{'avoid'} = 1;
                        }
                }

        } elsif ($switch eq "0196") {
                #0196 < type >.w < ID >.l < switch >.b (after the comodo)
                # Status Parser Kokal improve
                my $type = unpack("S1", substr($msg, 2, 2));
                my $ID = substr($msg, 4, 4);
                my $flag = unpack("C1",substr($msg, 8, 1));
                my $display;
                if (%{$monsters{$ID}}) {
                        $display = "$monsters{$ID}{'name'}($monsters{$ID}{'binID'}) ";
                        $monsters{$ID}{'skillsst'}{$type} = $flag;
                } elsif (%{$players{$ID}}) {
                        $display = "$players{$ID}{'name'}($players{$ID}{'binID'}) ";
                        $players{$ID}{'skillsst'}{$type} = $flag;
                } elsif ($ID eq $accountID) {
                        $display = "";
                        $chars[$config{'char'}]{'skillsst'}{$type} = $flag;
                } else {
                        $display = "未知 ";
                }
                if ($ID ne $accountID && %{$chars[$config{'char'}]{'party'}{'users'}{$ID}} ne "") {
                        $i = 0;
                        while ($config{"useParty_skill_$i"} ne "") {
                                if ($msgstrings_lut{'0196'}{$type} eq $config{"useParty_skill_$i"} && $config{"useParty_skill_$i"."_stateTimeout"} > 0) {
                                        if ($flag == 1) {
                                                $ai_v{"useParty_skill_$i"."_time"}{$ID} = time - $config{"useParty_skill_$i"."_timeout"} + $config{"useParty_skill_$i"."_stateTimeout"};
                                        } else {
                                                $ai_v{"useParty_skill_$i"."_time"}{$ID} = time - $config{"useParty_skill_$i"."_timeout"};
                                        }
                                        last;
                                }
                                $i++;
                        }
                }
                if ($flag == 1) {
                        $display .= "变成";
                        $display .= $msgstrings_lut{'0196'}{$type}."状态";
                        if ($ID eq $accountID) {
                                printc("wc", "<状态> ", "$display\n") if ($config{'mode'} >= 2);
                        } else {
                                printc("nn", "<信息> ", "$display\n") if ($config{'mode'} >= 3);
                        }
                } else {
                        $display .= "解除";
                        $display .= $msgstrings_lut{'0196'}{$type}."状态";
                        if ($ID eq $accountID) {
                                printc("wr", "<状态> ", "$display\n") if ($config{'mode'} >= 2);
                        } else {
                                printc("wn", "<信息> ", "$display\n") if ($config{'mode'} >= 3);
                        }
                }

        } elsif ($switch eq "0199") {
                #0199 < type >.w
                #game mode change
                my $type = unpack("S1",substr($msg, 2, 2));
                if ($type == 1) {
                        printc("wy", "<信息> ", "进入PVP游戏模式\n");
                } elsif ($type ==3) {
                        printc("wy", "<信息> ", "进入GVG游戏模式\n");
                }

        } elsif ($switch eq "019B") {
                #019b < ID >.l < type >.l
                # lvup packet
                my $ID = substr($msg, 2, 4);
                my $type = unpack("L1",substr($msg, 6, 4));
                my $name;
                if ($ID eq $accountID) {
                       $name = ""
                } elsif (%{$players{$ID}}) {
                        $name = $players{$ID}{'name'}." ";
                } else {
                        $name = "未知 ";
                }
                if ($type == 0) {
                        printc("wy", "<信息> ", "$name基本等级提升\n");
                } elsif ($type == 1) {
                        printc("wy", "<信息> ", "$name职业等级提升\n");
                } elsif ($type == 2){
                        printc("gn", "->$switch ", "$name refined weapon fail !!\n") if ($config{'debug'});
                } elsif ($type == 3){
                        printc("gn", "->$switch ", "$name refined weapon Success !!\n") if ($config{'debug'});
                }

         } elsif ($switch eq "01A0") {
                my $type = unpack("C1",substr($msg, 2, 1));
                if ($type == 0) {
                        printc("nr", "<宠物> ", "捕捉失败\n");
                        chatLog("m", "宠物捕捉失败\n");
                } elsif ($type == 1) {
                        printc("nc", "<宠物> ", "捕捉成功\n");
                        chatLog("m", "宠物捕捉成功\n");
                }

        } elsif ($switch eq "01A2") {
                #01a2 < pet name >.24b < name flag >.B < lv >.w < hungry >.w < friendly >.w < accessory >.w
                # Pet Info
                ($chars[$config{'char'}]{'pet'}{'name'}) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
                $chars[$config{'char'}]{'pet'}{'name_flag'} = unpack("C1",substr($msg, 26, 1));
                $chars[$config{'char'}]{'pet'}{'level'} = unpack("S1",substr($msg, 27, 2));
                $chars[$config{'char'}]{'pet'}{'hungry'} = unpack("S1",substr($msg, 29, 2));
                $chars[$config{'char'}]{'pet'}{'friendly'} = unpack("S1",substr($msg, 31, 2));
                $chars[$config{'char'}]{'pet'}{'accessory'} = unpack("S1",substr($msg, 33, 2));
                $chars[$config{'char'}]{'pet'}{'action'} = 0;
                if ($chars[$config{'char'}]{'pet'}{'hungry'} <= 10 || ($config{'petAuto_feed'} && $chars[$config{'char'}]{'pet'}{'hungry'} <= $config{'petAuto_feed'})){
                        printc(1, "wy", "<宠物> ", "自动喂宠\n");
                        sendPetCommand(\$remote_socket, 1);
                }

        } elsif ($switch eq "01A3") {
                #01a3 < fail >.B < itemId >.w
                #give pet food result
                my $success=unpack("C1",substr($msg, 2, 1));
                my $ID=unpack("S1",substr($msg, 3, 2));
                if (!$success) {
                        printc(1, "wr", "<宠物> ", "没有宠物饲料 $items_lut{$ID}, 回收宠物\n");
                        sendPetCommand(\$remote_socket, 3);
                        undef %{$chars[$config{'char'}]{'pet'}};
                }

        } elsif ($switch eq "01A4") {
                #01a4 < type >.B < ID >.l < val >.l
                #pet spawn
                my $type = unpack("C1",substr($msg, 2, 1));
                my $ID = substr($msg, 3, 4);
                my $val = unpack("L",substr($msg, 7, 4));
                if ($type == 0) {
                        $chars[$config{'char'}]{'pet'}{'ID'} = $ID;
                } elsif ($type == 1) {
                        printc("gn", "->$switch ", "Pet Friendly : $val\n") if ($config{'debug'});
                        if ($val >= $chars[$config{'char'}]{'pet'}{'friendly'}) {
                        	printc(1, "wc", "<宠物> ", "亲密度增加 $val/1000\n") if (!$config{'hideMsg_petStatus'});
                        } else {	
                        	printc(1, "wr", "<宠物> ", "亲密度减少 $val/1000\n") if (!$config{'hideMsg_petStatus'});
                        }
                        $chars[$config{'char'}]{'pet'}{'friendly'} = $val;
        	        if ($val < 100) {
                        	printc(1, "wr", "<宠物> ", "亲密度低于100, 回收宠物\n");
                                sendPetCommand(\$remote_socket, 3);
	                } elsif ($config{'petAuto_return'} && $val >= $config{'petAuto_return'}) {
                        	printc(1, "wy", "<宠物> ", "亲密度达到$config{'petAuto_return'}, 回收宠物\n");
                                sendPetCommand(\$remote_socket, 3);
                        }                     
                } elsif ($type == 2) {
                        printc("gn", "->$switch ", "Pet Hungry : $val\n") if ($config{'debug'});
                        if ($val >= $chars[$config{'char'}]{'pet'}{'hungry'}) {
                        	printc(1, "wc", "<宠物> ", "饱食度增加 $val/100\n") if (!$config{'hideMsg_petStatus'});
                        } else {
                        	printc(1, "wr", "<宠物> ", "饱食度减少 $val/100\n") if (!$config{'hideMsg_petStatus'});
                        }	
                        $chars[$config{'char'}]{'pet'}{'hungry'} = $val;
                        if ($val <= 10 || ($config{'petAuto_feed'} && $val <= $config{'petAuto_feed'})){
                                printc("wy", "<宠物> ", "自动喂宠\n");
                                sendPetCommand(\$remote_socket, 1);
                        }
                } elsif ($type == 3) {
                        if ($chars[$config{'char'}]{'pet'}{'ID'} eq $ID) {
                                $chars[$config{'char'}]{'pet'}{'accessory'} = $val;
                        } else {
                                $pets{$ID}{'accessory'} = $val;
                        }
                } elsif ($type == 4) {
                        if ($chars[$config{'char'}]{'pet'}{'ID'} eq $ID) {
                                $chars[$config{'char'}]{'pet'}{'action'} = $val;
                        } else {
                                $pets{$ID}{'action'} = $val;
                        }
                } elsif ($type == 5) {                	
                        if (!%{$pets{$ID}}) {
                                binAdd(\@petsID, $ID);
                                %{$pets{$ID}} = %{$monsters{$ID}};
                                $pets{$ID}{'name_given'} = "Unknown";
                                $pets{$ID}{'binID'} = binFind(\@petsID, $ID);
                        }
                        if ($ID eq $chars[$config{'char'}]{'pet'}{'ID'}) {
                                $chars[$config{'char'}]{'pet'}{'name'} = $pets{$ID}{'name'};
                        }
                }
                if (%{$monsters{$ID}}) {
                        binRemove(\@monstersID, $ID);
                        undef %{$monsters{$ID}};
                }
                printc("gn", "->$switch ", "Pet Spawned: $pets{$ID}{'name'}($pets{$ID}{'binID'})\n") if ($config{'debug'});

        } elsif ($switch eq "01AA") {
                #01aa < ID >.l < emotion >.l
                #pet emotion
                my $ID = substr($msg, 2, 4);
                my $type = unpack("L1", substr($msg, 6, 4));
                if ($type < 34) {
                        if (!%{$pets{$ID}}) {
                                $display = "Unknown";
                        } else {
                                $display = "$pets{$ID}{'name_given'}";
                        }
                        printc("nng", "<宠物> ", "$display : ", "$emotions_lut{$type}\n") if (!$config{'hideMsg_emotion'});
                }

        } elsif ($switch eq "01AB") {
                #Chat and skill ban
                my $ID = substr($msg, 2, 4);
                my $type = unpack("S1", substr($msg, 6, 2));
                my $val =  abs(unpack("l1", substr($msg, 8, 4)));
                if ($ID eq $accountID) {
                        $display = "你";
                } elsif (%{$players{$ID}}) {
                        $display = "$players{$ID}{'name'}($players{$ID}{'binID'})";
                } else {
                        $display = "Unknown";
                }
                if ($ID eq $accountID) {
                        printc("yr", "<系统> ", "你被禁言 $val 分钟...\n");
                        chatLog("gm", "你被禁言 $val 分钟...\n");
                        ($map_string) = $map_name =~ /([\s\S]*)\.gat/;
                        $sleeptime = int($val * 60 + rand() * 600);
                        printc("yr", "<系统> ", "躲避禁言,断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        chatLog("gm", "躲避禁言,断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
        	        $conState = 1;
	                undef $conState_tries;
                	$timeout_ex{'master'}{'time'} = time;
        	        $timeout_ex{'master'}{'timeout'} = $sleeptime;
	                killConnection(\$remote_socket) if (!$xKore);
                } else {
                        printc("nn", "<玩家> ", "$display 被禁言 $val 分钟...\n");
                }

        } elsif ($switch eq "01B0"){
                #01b0 <monster id>.l <?>.b <new monster code>.l
                #monster Type Change
                my $ID = substr($msg,2,4);
                my $type = unpack("L1", substr($msg, 7, 4));
                if (!%{$monsters{$ID}}) {
                        $monsters{$ID}{'appear_time'} = time;
                        binAdd(\@monstersID, $ID);
                        $monsters{$ID}{'nameID'} = $type;
                        $monsters{$ID}{'name'} = ($monsters_lut{$type} ne "") ? $monsters_lut{$type} : "Unknown ".$type;
                        $monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
                } else {
                        $monsters{$ID}{'nameID'} = $type;
                        $monsters{$ID}{'name'} = ($monsters_lut{$type} ne "") ? $monsters_lut{$type} : "Unknown ".$type;
                }

        } elsif ($switch eq "01B3") {
                #NPC image
                my $npc_image = substr($msg, 2,64);
                ($npc_image) = $npc_image =~ /(\S+)/;
                printc("gn", "->$switch ", "NPC image: $npc_image\n") if $config{'debug'};

        } elsif ($switch eq "01B5") {
                #Airtime remaining
                my $remain = unpack("L1", substr($msg, 2, 4));
                my ($day,$hour,$minute);
                if (!$remain) {
                        $remain = unpack("L1", substr($msg, 6, 4));
                }
                $day = int($remain / 1440);
                $remain = $remain % 1440;
                $hour = int($remain / 60);
                $remain = $remain % 60;
                $minute = $remain;
                print "You have Airtime : $day days, $hour hours and $minute minutes\n";
                $chars[$config{'char'}]{'Airtime'}{'day'}=$day;
                $chars[$config{'char'}]{'Airtime'}{'hour'}=$hour;
                $chars[$config{'char'}]{'Airtime'}{'minute'}=$minute;
                $chars[$config{'char'}]{'Airtime'}{'loginat'}= getFormattedDate(int(time));

        } elsif ($switch eq "01B6") {
                #01b6 < guildId >.l < guildLv >.l < connum >.l < fixed capacity >.l < Avl.lvl >.l < now_exp >.l < next_exp >.l < payment point >.l < propensity F-V >.l < propensity R-W >.l < members >.l < guild name >.24b < guild master >.24b < agit? >.20B 
                #Guild Info 
                $chars[$config{'char'}]{'guild'}{'ID'} = substr($msg, 2, 4);
                $chars[$config{'char'}]{'guild'}{'lv'} = unpack("L1", substr($msg,  6, 4));
                $chars[$config{'char'}]{'guild'}{'conMember'} = unpack("L1", substr($msg, 10, 4));
                $chars[$config{'char'}]{'guild'}{'maxMember'} = unpack("L1", substr($msg, 14, 4));
                $chars[$config{'char'}]{'guild'}{'average'} = unpack("L1", substr($msg, 18, 4));
                $chars[$config{'char'}]{'guild'}{'exp'} = unpack("L1", substr($msg, 22, 4));
                $chars[$config{'char'}]{'guild'}{'next_exp'} = unpack("L1", substr($msg, 26, 4));
                $chars[$config{'char'}]{'guild'}{'offerPoint'} = unpack("L1", substr($msg, 30, 4));
                $chars[$config{'char'}]{'guild'}{'inclination_FtoV'} = unpack("L1", substr($msg, 34, 4));
                $chars[$config{'char'}]{'guild'}{'inclination_RtoW'} = unpack("L1", substr($msg, 38, 4));
                ($chars[$config{'char'}]{'guild'}{'name'}) = substr($msg, 46, 24) =~ /([\s\S]*?)\000/;
                ($chars[$config{'char'}]{'guild'}{'master'}) = substr($msg, 70, 24) =~ /([\s\S]*?)\000/;
                ($chars[$config{'char'}]{'guild'}{'castle'}) = substr($msg, 94, 20) =~ /([\s\S]*?)\000/;

                sendGuildRequest(\$remote_socket, 0); 
                sendGuildRequest(\$remote_socket, 1);
                sendGuildRequest(\$remote_socket, 2);

        } elsif ($switch eq "01B9") {
                #01b9 < ID >.I
                #The permanent residence discontinuance of ID and the like with suffering uselessly
                $ID = substr($msg, 2, 4);
                if ($ID eq $accountID) {
                        aiRemove("skill_use");
                        undef $chars[$config{'char'}]{'time_cast'};
                        printc("wr", "<信息> ", "技能施放被中断\n") if (!$config{'hideMsg_skillFail'} && $config{'mode'});
                } elsif (%{$monsters{$ID}}) {
                        printc("wn", "<信息> ", "$monsters{$ID}{'name'}($monsters{$ID}{'binID'}) 技能施放被中断\n") if ($config{'mode'} >= 3);
                } elsif (%{$players{$ID}}) {
                        printc("wn", "<信息> ", "$players{$ID}{'name'}($players{$ID}{'binID'}) 技能施放被中断\n") if ($config{'mode'} >= 3);
                } else {
                        printc("wn", "<信息> ", "未知 技能施放被中断\n") if ($config{'mode'} >= 3);
                }

        } elsif ($switch eq "01C4") {
                #01c4 < index >.w < amount >.l < itemId >.w < item data >.12b
                #Coupler warehouse item
                my $index = unpack("S1", substr($msg, 2, 2));
                my $amount = unpack("L1", substr($msg, 4, 4));
                my $ID = unpack("S1", substr($msg, 8, 2));
                my $type = unpack("C1", substr($msg, 10, 1));
                my $identify = unpack("C1", substr($msg, 11, 1));
                if (%{$storage{'inventory'}[$index]}) {
                        $storage{'inventory'}[$index]{'amount'} += $amount;
                } else {
                        $storage{'inventory'}[$index]{'nameID'} = $ID;
                        $storage{'inventory'}[$index]{'amount'} = $amount;
                        $storage{'inventory'}[$index]{'type'} = $type;
                        $storage{'inventory'}[$index]{'identified'} = $identify;
                        $storage{'inventory'}[$index]{'type_equip'} = $itemSlots_lut{$ID};
                        $storage{'inventory'}[$index]{'name'} = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
			if ($storage{'inventory'}[$index]{'type_equip'} == 1024) {
				$storage{'inventory'}[$index]{'borned'} = unpack("C1", substr($msg, 12, 1));
				$storage{'inventory'}[$index]{'named'} = unpack("C1", substr($msg, 20, 1));
			} elsif ($storage{'inventory'}[$index]{'type_equip'}) {
				$storage{'inventory'}[$index]{'broken'}       = unpack("C1", substr($msg, 12, 1));
				$storage{'inventory'}[$index]{'refined'}      = unpack("C1", substr($msg, 13, 1));
                                if(unpack("S1", substr($msg,14, 2)) == 0x00FF){
                                        $storage{'inventory'}[$index]{'attribute'} = unpack("C1", substr($msg,16, 1));
                                        $storage{'inventory'}[$index]{'star'} = unpack("C1", substr($msg,17, 1)) / 0x05;
                                        $storage{'inventory'}[$index]{'maker_charID'} = substr($msg, 18, 4);
                                } else {
                                        $storage{'inventory'}[$index]{'card'}[0] = unpack("S1", substr($msg,14, 2));
                                        $storage{'inventory'}[$index]{'card'}[1] = unpack("S1", substr($msg,16, 2));
                                        $storage{'inventory'}[$index]{'card'}[2] = unpack("S1", substr($msg,18, 2));
                                        $storage{'inventory'}[$index]{'card'}[3] = unpack("S1", substr($msg,20, 2));
                                }
                                modifingName(\%{$storage{'inventory'}[$index]});
                        }
                }
                printc("wn", "<仓库> ", "增加: $storage{'inventory'}[$index]{'name'} x $amount\n");

        } elsif ($switch eq "01C5") {
                my $index = unpack("S1", substr($msg, 2, 2));
                my $amount = unpack("L1", substr($msg, 4, 4));
                my $ID = unpack("S1", substr($msg, 8, 2));
                my $type = unpack("C1", substr($msg, 10, 1));
                my $identify = unpack("C1", substr($msg, 11, 1));
                if (%{$cart{'inventory'}[$index]}) {
                        $cart{'inventory'}[$index]{'amount'} += $amount;
                } else {
                        $cart{'inventory'}[$index]{'nameID'} = $ID;
                        $cart{'inventory'}[$index]{'amount'} = $amount;
                        #------------------------------------------------------------------------------------------------------------
                        #<index>.w <amount>.l <item ID>.w <identify flag>.B <attribute?>.B <refine>.B <card>.4w
                        $cart{'inventory'}[$index]{'type'} = $type;
                        $cart{'inventory'}[$index]{'identified'} = $identify;
                        $cart{'inventory'}[$index]{'type_equip'} = $itemSlots_lut{$ID};
			if ($cart{'inventory'}[$index]{'type_equip'} == 1024) {
				$cart{'inventory'}[$index]{'borned'} = unpack("C1", substr($msg, 12, 1));
				$cart{'inventory'}[$index]{'named'} = unpack("C1", substr($msg, 20, 1));
			} elsif ($cart{'inventory'}[$index]{'type_equip'}) {
				$cart{'inventory'}[$index]{'broken'}       = unpack("C1", substr($msg, 12, 1));
				$cart{'inventory'}[$index]{'refined'}      = unpack("C1", substr($msg, 13, 1));
	                        if (unpack("S1", substr($msg, 14, 2)) == 0x00FF) {
        	                        $cart{'inventory'}[$index]{'attribute'} = unpack("C1", substr($msg, 16, 1));
                	                $cart{'inventory'}[$index]{'star'}      = unpack("C1", substr($msg, 17, 1))/ 0x05;
                	                $cart{'inventory'}[$index]{'maker_charID'} = substr($msg, 18, 4);
                        	} else {
                                	$cart{'inventory'}[$index]{'card'}[0]   = unpack("S1", substr($msg, 14, 2));
	                                $cart{'inventory'}[$index]{'card'}[1]   = unpack("S1", substr($msg, 16, 2));
        	                        $cart{'inventory'}[$index]{'card'}[2]   = unpack("S1", substr($msg, 18, 2));
                	                $cart{'inventory'}[$index]{'card'}[3]   = unpack("S1", substr($msg, 20, 2));
                                }
                        }
                        $cart{'inventory'}[$index]{'name'} = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
                        modifingName(\%{$cart{'inventory'}[$index]});
                }
                printc("wn", "<车子> ", "增加: $cart{'inventory'}[$index]{'name'} x $amount\n");

        } elsif ($switch eq "01C8") {
                #01c8 < index >.w < item ID >.w < ID >.l < amount left >.w < type >.B
                #Item use response. (The higher rank version of 00a8? )
                my $index = unpack("S1",substr($msg, 2, 2));
                my $ID = unpack("S1", substr($msg, 4, 2));
                my $sourceID = substr($msg, 6, 4);
                my $amountleft = unpack("S1",substr($msg, 10, 2));
                my $display = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
                my $invIndex;
                if ($sourceID eq $accountID) {
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                        $amount = $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $amountleft;
	                $exp{'item'}{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}{'used'} += $amount;                
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $amount;
                        printc("wngn", "<物品> ", "使用: ", "$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ", "x $amount\n") if ($config{'mode'});
                        if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
                                undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
                        }
               } elsif (%{$players{$sourceID}}) {
                        printc("nn", "<玩家> ", "$players{$sourceID}{'name'}($players{$sourceID}{'binID'}) 使用物品: $display\n") if ($config{'mode'} >= 3);
                } elsif (%{$monsters{$sourceID}}) {
                        printc("nn", "<怪物> ", "$monsters{$sourceID}{'name'}($monsters{$sourceID}{'binID'}) 使用物品: $display\n") if ($config{'mode'} >= 3);
               } else {
                        printc("nn", "<玩家> ", "未知 使用物品: $display\n") if ($config{'mode'} >= 3);
               }

        } elsif ($switch eq "01C9") {
                #area effect spell
                $ID = substr($msg, 2, 4);
                $SourceID = substr($msg, 6, 4);
                $x = unpack("S1",substr($msg, 10, 2));
                $y = unpack("S1",substr($msg, 12, 2));
                $type = unpack("C1",substr($msg, 14, 1));
                $spells{$ID}{'sourceID'} = $SourceID;
                $spells{$ID}{'pos'}{'x'} = $x;
                $spells{$ID}{'pos'}{'y'} = $y;
                $spells{$ID}{'binID'} = $binID;
                $spells{$ID}{'distance'} = int(distance(\%{$chars[$config{'char'}]{'pos_to'}},\%{$spells{$ID}{'pos'}}));
                $spells{$ID}{'name'} = $msgstrings_lut{'011F'}{$type};
                $binID = binAdd(\@spellsID, $ID);
                printc("wn", "<信息> ", "出现: $spells{$ID}{'name'} ($spells{$ID}{'pos'}{'x'},$spells{$ID}{'pos'}{'y'}) 距离: $spells{$ID}{'distance'}\n") if ($config{'mode'} >= 3);

        } elsif ($switch eq "01CD") {
		#undef @autospellID;
		#for (my $i = 2; $i < 30; $i += 4) {
		#	my $ID = unpack("S1",substr($msg, $i, 2));
		#	binAdd(\@autospellID, $ID);
		#}
                #print "Recieved Possible Auto Casting Spell - type 'spell'\n";

	} elsif ($switch eq "01CF") {
		#01cf <crusader id>.l <target id>.l <?>.18b
		# Unknow

        } elsif ($switch eq "01D0" || $switch eq "01E1"){
		#monk Spirits
                my $sourceID = substr($msg, 2, 4);
                if ($sourceID eq $accountID) {
                        $chars[$config{'char'}]{'spirits'} = unpack("S1",substr($msg, 6, 2));
                        printc("wng", "<信息> ", "你有 ", "气弹$chars[$config{'char'}]{'spirits'}个\n") if ($config{'mode'} >= 2);
                }

	} elsif ($switch eq "01D1") {
		#01d1 <monk id>.l <target monster id>.l <bool>.l
		#Steal Spirit Ball

        } elsif ($switch eq "01D2") {
                #Triple Attack
                $sourceID = substr($msg, 2, 4);
                $wait = unpack("L1",substr($msg, 6, 4));

	} elsif ($switch eq "01D4") {
		#npc let you input word for response
		$ID = substr($msg, 2, 4);
                printc("ww", "<对话> ", "$npcs{$ID}{'name'} : 输入 'talk answer 文字' 选择回答\n");

	} elsif ($switch eq "01D7") {
		#Weapon Information (Type: 0=Job, 2=Hand, 9=Foot)
		$sourceID = substr($msg, 2, 4);
		$type = unpack("C1",substr($msg, 6, 1));
		$itemID1 = unpack("S1",substr($msg, 7, 2));
		$itemID2 = unpack("S1",substr($msg, 9, 2));

        } elsif ($switch eq "01DC") {
                $secureLoginKey = substr($msg, 4, $msg_size);

	} elsif ($switch eq "01F4") {
                #01F4 <nick>.24B <charactor ID>.l <level>.w
                #Transaction request to receive
                my ($dealUser) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
                my $ID = substr($msg, 26, 4); 
                my $level = unpack("S1", substr($msg, 30, 2));
                $incomingDeal{'name'} = $dealUser;
                $timeout{'ai_dealAutoCancel'}{'time'} = time;
                printc("wy", "<信息> ", "$dealUser $level级(先生／小姐)询问您愿不愿意交易道具\n");
                parseInput("deal") if ($config{'dealAuto'});

	} elsif ($switch eq "01F5") {
                #01F5 <fail>.B <charactor ID>.l <level>.w
                #Transaction request response
                my $type = unpack("C1", substr($msg, 2, 1));
		my $ID = substr($msg, 3, 4); 
                my $level = unpack("S1", substr($msg, 7, 2));
                if ($type == 0) {
                        printc("wr", "<信息> ", "超过可交易的距离\n");
                } elsif ($type == 1) {
                        printc("wr", "<信息> ", "没有您所指定的人物\n");
                } elsif ($type == 2) {
                        printc("wr", "<信息> ", "此人物与其他人物正在交易中\n");
                } elsif ($type == 3) {
                        if (%incomingDeal) {
                                $currentDeal{'name'} = $incomingDeal{'name'};
                        } else {
                                $currentDeal{'ID'} = $outgoingDeal{'ID'};
                                $currentDeal{'name'} = $players{$outgoingDeal{'ID'}}{'name'};
                        }
                        printc("ww", "<信息> ", "接受交易邀请 $currentDeal{'name'} $level级\n");
                        parseInput("dl");
                }
                undef %outgoingDeal;
                undef %incomingDeal;                   
              
	} elsif ($switch eq "0201") {
		# friend list
		# 0201 <len>.w {<account ID>.l <charactor ID>.l <name>.24B}.32B*
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef %friend;
		for ($i = 4; $i < $msg_size; $i+=32) {
			my %args;
			$args{'ID'} = substr($msg, $i, 4);
			$args{'charID'} = substr($msg, $i + 4, 4);
			($args{'name'}) = substr($msg, $i + 8, 24) =~ /([\s\S]*?)\000/;
			push @{$friend{'member'}}, \%args;
		}

	} elsif ($switch eq "0206") {
		# friend online (status?)
		# 0206 <account ID>.l <charactor ID>.l ?.B
		my $ID = substr($msg, 2, 4);
		my $index = findIndexString(\@{$friend{'member'}}, "ID", $ID);
		if ($index ne "") {
			print "Friend $friend{'member'}[$index]{'name'} logged in.\n";
		}

	} elsif ($switch eq "0207") {
		# friend request for you
		# 0207 <account ID>.l <charactor ID>.l <name>.24B
		$incomingFriend{'ID'} = substr($msg, 2, 4);
		$incomingFriend{'charID'} = substr($msg, 6, 4);
		my ($name) = substr($msg, 10, 24) =~ /([\s\S]*?)\000/;
		print "Incoming Request to make friend with '$name'\n";
		$timeout{'ai_friendAutoDeny'}{'time'} = time;

	} elsif ($switch eq "0209") {
		# friend join
		# 0209 <type>.w <account ID>.l <charactor ID>.l <name>.24B
		my %args;
		$args{'ID'} = substr($msg, 4, 4);
		$args{'charID'} = substr($msg, 8, 4);
		($args{'name'}) = substr($msg, 12, 24) =~ /([\s\S]*?)\000/;
		if ($type == 0) {
			print "$args{'name'} accepted your request\n";
			push @{$friend{'member'}}, \%args;
		} elsif ($type == 1) {
			print "Join request failed: $args{'name'} denied request\n";
		}

	} elsif ($switch eq "020A") {
		# friend remove
		# 020A <account ID>.l <charactor ID>.l
		my $ID = substr($msg, 2, 4);
		my $index = findIndexString(\@{$friend{'member'}}, "ID", $ID);
		if ($index ne "") {
			print "$friend{'member'}[$index]{'name'} removed from your friend list\n";
			splice @{$friend{'member'}}, $index, 1;
		}

        } elsif ($rpackets{$switch} eq "") {
                printc("r", "Unknown packet - $switch\n");
        } else {
        	printc("y", "Unparsed packet - $switch : $rpackets{$switch}\n") if ($config{'debugPacket_received'});
        }
        if (length($msg) >= $msg_size) {
	        dumpData(substr($msg,0,$msg_size)) if (existsInList($config{'debugPacket_received_dumpList'}, $switch) || $config{'debugPacket_received'} >= 3);
        }
        $msg = (length($msg) >= $msg_size) ? substr($msg, $msg_size, length($msg) - $msg_size) : "";
        return $msg;
}


1;