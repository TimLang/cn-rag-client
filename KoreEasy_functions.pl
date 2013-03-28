#######################################
#INITIALIZE VARIABLES
#######################################

sub initConnectVars {
        initMapChangeVars();
        undef %{$chars[$config{'char'}]{'skills'}};
	undef %{$chars[$config{'char'}]{'skills_used'}};
        undef @skillsID;
        undef %cart;
	undef $chars[$config{'char'}]{'eq_arrow_index'};
        ai_stateReset();
}

sub initMapChangeVars {
        @portalsID_old = @portalsID;
        %portals_old = %portals;
        undef @{$chars[$config{'char'}]{'inventory'}};
        %{$chars_old[$config{'char'}]{'pos_to'}} = %{$chars[$config{'char'}]{'pos_to'}};
        undef $chars[$config{'char'}]{'sitting'};
        undef $chars[$config{'char'}]{'dead'};
	undef $chars[$config{'char'}]{'autoSwitch'};
        $timeout{'play'}{'time'} = time;
        undef $timeout{'ai_sync'}{'time'};
        $timeout{'ai_sit_idle'}{'time'} = time;
        $timeout{'ai_teleport_idle'}{'time'} = time;
        $timeout{'ai_teleport_search'}{'time'} = time;
        $timeout{'ai_teleport_safe_force'}{'time'} = time;
        undef %incomingDeal;
        undef %outgoingDeal;
        undef %incomingParty;
        undef %incomingGuild;
	undef %incomingFriend;
        undef %currentDeal;
        undef $currentChatRoom;
        undef @currentChatRoomUsers;

        undef @playersID;
        undef @avoidID;
        undef @monstersID;
        undef @portalsID;
        undef @itemsID;
        undef @npcsID;
        undef @identifyID;
        undef @spellsID;
        undef @petsID;
        undef %players;
        undef %monsters;
        undef %portals;
        undef %items;
        undef %npcs;
        undef %spells;
        undef $msg;
        undef %talk;
        undef $ai_v{'temp'};
        undef @{$cart{'inventory'}};        
        undef %storage;
        # ICE Start - Auto Shop
        undef @venderItemList;
        undef $venderID;
        undef @venderListsID;
        undef $venderLists;
        undef @{$shop{'inventory'}};        
        # ICE End
        undef $ai_v{'move_failed'};
        undef $chars[$config{'char'}]{'shopOpened'};
        $timeout{'ai_shopAuto'}{'time'} = time;
        undef $timeout{'ai_attack_auto'}{'time'};
        undef $timeout{'ai_skill_use'}{'time'};
        undef $timeout{'ai_item_use_auto'}{'time'};
        undef $timeout{'ai_equip_auto_giveup'}{'time'};
        undef $timeout{'ai_teleport_hp'}{'time'};
        ai_changeToMvpMode(0) if ($chars[$config{'char'}]{'mvp'});
}



#######################################
#######################################
#Check Connection
#######################################
#######################################


# $conState contains the connection state:
# 1: Not connected to anything                (next step -> connect to master server).
# 2: Connected to master server               (next step -> connect to login server)
# 3: Connected to login server                (next step -> connect to character server)
# 4: Connected to character server            (next step -> connect to map server)
# 5: Connected to map server; ready and functional.
sub checkConnection {
        return if ($xKore);

        if ($conState == 1 && !($remote_socket && $remote_socket->connected()) && timeOut(\%{$timeout_ex{'master'}}) && !$conState_tries) {
                printc("yn", "<系统> ", "正在与主服务器建立连接...\n");
                $shopstarted = 1;
                $conState_tries++;
                undef $msg;
                connection(\$remote_socket, $config{"master_host_$config{'master'}"},$config{"master_port_$config{'master'}"});
		dynParseFiles("data/avoidaid.txt", \%aid_rlut, \&parseAidRLUT) if ($config{"master_host_$config{'master'}"} ne $master_host);
		$master_host = $config{"master_host_$config{'master'}"};
		
                if ($config{'secure'} >= 1) {
                        printc("yn", "<系统> ", "安全连接...\n");
                        undef $secureLoginKey;
                        sendMasterEncryptKeyRequest(\$remote_socket);
                } else {
                        #sendMasterLogin(\$remote_socket, $config{'username'}, decodePassword($config{'password'}));
						sendMasterLogin(\$remote_socket, $config{'username'}, $config{'password'});
                }

                $timeout{'master'}{'time'} = time;

        } elsif ($conState == 1 && $config{'secure'} >= 1 && $secureLoginKey ne "" && !timeOut(\%{$timeout{'master'}}) && $conState_tries) {
                printc("yn", "<系统> ", "发送密码编码...\n");
                sendMasterSecureLogin(\$remote_socket, $config{'username'}, decodePassword($config{'password'}), $secureLoginKey);
                undef $secureLoginKey;

        } elsif ($conState == 1 && timeOut(\%{$timeout{'master'}}) && timeOut(\%{$timeout_ex{'master'}})) {
                printc("yr", "<系统> ", "与主服务器建立连接超时，重新连接...\n");
                killConnection(\$remote_socket);
                undef $conState_tries;

        } elsif ($conState == 2 && !($remote_socket && $remote_socket->connected()) && $config{'server'} ne "" && !$conState_tries) {
                printc("yn", "<系统> ", "正在与帐号服务器建立连接...\n");
                $conState_tries++;
                connection(\$remote_socket, $servers[$config{'server'}]{'ip'},$servers[$config{'server'}]{'port'});
                sendGameLogin(\$remote_socket, $accountID, $sessionID, $accountSex);
                $timeout{'gamelogin'}{'time'} = time;

        } elsif ($conState == 2 && timeOut(\%{$timeout{'gamelogin'}}) && $config{'server'} ne "") {
                printc("yr", "<系统> ", "与帐号服务器建立连接超时，重新连接...\n");
                $timeout_ex{'master'}{'time'} = time;
                $timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
                killConnection(\$remote_socket);
                undef $conState_tries;
                $conState = 1;

        } elsif ($conState == 3 && !($remote_socket && $remote_socket->connected()) && $config{'char'} ne "" && !$conState_tries) {
                printc("yn", "<系统> ", "正在与人物服务器建立连接...\n");
                $conState_tries++;
                connection(\$remote_socket, $servers[$config{'server'}]{'ip'},$servers[$config{'server'}]{'port'});
                sendCharLogin(\$remote_socket, $config{'char'});
                $timeout{'charlogin'}{'time'} = time;

        } elsif ($conState == 3 && timeOut(\%{$timeout{'charlogin'}}) && $config{'char'} ne "") {
                printc("yr", "<系统> ", "与人物服务器建立连接超时，重新连接...\n");
                $timeout_ex{'master'}{'time'} = time;
                $timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
                killConnection(\$remote_socket);
                $conState = 1;
                undef $conState_tries;

        } elsif ($conState == 4 && !($remote_socket && $remote_socket->connected()) && !$conState_tries) {
                printc("yn", "<系统> ", "正在与地图服务器建立连接...\n");
                $conState_tries++;
                initConnectVars();
                connection(\$remote_socket, $map_ip, $map_port);
                sendMapLogin(\$remote_socket, $accountID, $charID, $sessionID, $accountSex2);
                $timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
                $timeout{'maplogin'}{'time'} = time;

        } elsif ($conState == 4 && timeOut(\%{$timeout{'maplogin'}})) {
                printc("yr", "<系统> ", "与地图服务器建立连接超时，重新连接...\n");
                $timeout_ex{'master'}{'time'} = time;
                $timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
                killConnection(\$remote_socket);
                $conState = 1;
                undef $conState_tries;

        } elsif ($conState == 5 && !($remote_socket && $remote_socket->connected())) {
                $conState = 1;
                undef $conState_tries;

        } elsif ($conState == 5 && timeOut(\%{$timeout{'play'}})) {
                printc("yr", "<系统> ", "与服务器断线\n");
                chatLog("x", "与服务器断线\n");
                $timeout_ex{'master'}{'time'} = time;
                $timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
                killConnection(\$remote_socket);
                $conState = 1;
                undef $conState_tries;
                $exp{'base'}{'disconnect'}++;
        }

        # This is where saving the random restart time to the config file makes it a little cleaner, only one simple if needed
        # The local variable $sleeptime is controlled by the same system as used in initRandomRestart() for the restart times
        # The only thing that may want changing here is the sleep and restart times being printed in minutes rather than seconds
        # However, as I'm sure we are all used to working in seconds ourselves, this can be changed come release (if at all)
        if ($config{'autoRestart'} && time - $KoreStartTime > $config{'autoRestart'} && $conState == 5 && $ai_seq[0] ne "attack") {
                printc("yw", "<系统> ", "重新启动\n\n");
                $timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
                $timeout_ex{'master'}{'time'} = time;
                $KoreStartTime = time + $timeout_ex{'master'}{'timeout'};
                killConnection(\$remote_socket);
                $conState = 1;
                undef $conState_tries;
        }
}




#######################################
#######################################
#CONFIG MODIFIERS
#######################################
#######################################

sub auth {
        my $user = shift;
        my $flag = shift;
        if ($flag) {
                print "Authorized user '$user' for admin\n";
        } else {
                print "Revoked admin privilages for user '$user'\n";
        }
        $overallAuth{$user} = $flag;
        #Disable record authorized user name - ICE-WR
        #writeDataFile("data/overallAuth.txt", \%overallAuth);
}

sub configModify {
        my $key = shift;
        my $val = shift;
        print "Config '$key' set to $val\n";
        $config{$key} = $val;
        writeDataFileIntact("$setup_path/config.txt", \%config) if (!$chars[$config{'char'}]{'mvp'});
}

sub setTimeout {
        my $timeout = shift;
        my $time = shift;
        $timeout{$timeout}{'timeout'} = $time;
        print "Timeout '$timeout' set to $time\n";
        writeDataFileIntact2("$setup_path/timeouts.txt", \%timeout);
}




#######################################
#######################################
#CONNECTION FUNCTIONS
#######################################
#######################################


sub connection {
        my $r_socket = shift;
        my $host = shift;
        my $port = shift;
        printc("yn", "<系统> ", "正在连接 ($host:$port)... ");
	if ($config{'proxy_host'} ne "" && $config{'proxy_port'} ne "") {
	        $$r_socket = IO::Socket::Socks->new(
                        ProxyAddr       =>$config{'proxy_host'},
                        ProxyPort       =>$config{'proxy_port'},
                        ConnectAddr     =>$host,
                        ConnectPort     =>$port);
	} else {
	        $$r_socket = IO::Socket::INET->new(
                        PeerAddr        => $host,
                        PeerPort	=> $port,
                        Proto           => 'tcp',
                        Timeout         => 4);
	}
        ($$r_socket && inet_aton($$r_socket->peerhost()) eq inet_aton($host)) ? printc("g", "已连接\n") : printc("r", "无法连接\n");
}

sub dataWaiting {
        my $r_fh = shift;
        my $bits;
        vec($bits,fileno($$r_fh),1)=1;
        return (select($bits,$bits,$bits,0.05) > 1);
}

sub killConnection {
        my $r_socket = shift;
        sendQuit(\$remote_socket) if ($conState == 5 && $remote_socket && $remote_socket->connected());
        undef $msg;
        if ($$r_socket && $$r_socket->connected()) {
                printc("yn", "<系统> ", "正在关闭连接 (".$$r_socket->peerhost().":".$$r_socket->peerport().")... ");
                close($$r_socket);
                !$$r_socket->connected() ? printc("g", "断开连接\n") : printc("r", "无法断开\n");
        }
}





#######################################
#######################################
#HASH/ARRAY MANAGEMENT
#######################################
#######################################


sub binAdd {
        my $r_array = shift;
        my $ID = shift;
        my $i;
        for ($i = 0; $i <= @{$r_array};$i++) {
                if ($$r_array[$i] eq "") {
                        $$r_array[$i] = $ID;
                        return $i;
                }
        }
}

sub binFind {
        my $r_array = shift;
        my $ID = shift;
        my $i;
        for ($i = 0; $i < @{$r_array};$i++) {
                if ($$r_array[$i] eq $ID) {
                        return $i;
                }
        }
}

sub binFindReverse {
        my $r_array = shift;
        my $ID = shift;
        my $i;
        for ($i = @{$r_array} - 1; $i >= 0;$i--) {
                if ($$r_array[$i] eq $ID) {
                        return $i;
                }
        }
}

sub binRemove {
        my $r_array = shift;
        my $ID = shift;
        my $i;
        for ($i = 0; $i < @{$r_array};$i++) {
                if ($$r_array[$i] eq $ID) {
                        undef $$r_array[$i];
                        last;
                }
        }
}

sub binRemoveAndShift {
        my $r_array = shift;
        my $ID = shift;
        my $found;
        my $i;
        my @newArray;
        for ($i = 0; $i < @{$r_array};$i++) {
                if ($$r_array[$i] ne $ID || $found ne "") {
                        push @newArray, $$r_array[$i];
                } else {
                        $found = $i;
                }
        }
        @{$r_array} = @newArray;
        return $found;
}

sub binRemoveAndShiftByIndex {
        my $r_array = shift;
        my $index = shift;
        my $found;
        my $i;
        my @newArray;
        for ($i = 0; $i < @{$r_array};$i++) {
                if ($i != $index) {
                        push @newArray, $$r_array[$i];
                } else {
                        $found = 1;
                }
        }
        @{$r_array} = @newArray;
        return $found;
}

sub binSize {
        my $r_array = shift;
        my $found = 0;
        my $i;
        for ($i = 0; $i < @{$r_array};$i++) {
                if ($$r_array[$i] ne "") {
                        $found++;
                }
        }
        return $found;
}

sub existsInList {
        my ($list, $val) = @_;
        @array = split /,/, $list;
        return 0 if ($val eq "");
        $val = lc($val);
        foreach (@array) {
                s/^\s+//;
                s/\s+$//;
                s/\s+/ /g;
                next if ($_ eq "");
                return 1 if (lc($_) eq $val);
        }
        return 0;
}

sub findIndex {
        my $r_array = shift;
        my $match = shift;
        my $ID = shift;
        my $i;
        for ($i = 0; $i < @{$r_array} ;$i++) {
                if ((%{$$r_array[$i]} && $$r_array[$i]{$match} == $ID)
                        || (!%{$$r_array[$i]} && $ID eq "")) {
                        return $i;
                }
        }
        if ($ID eq "") {
                return $i;
        }
}


sub findIndexString {
        my $r_array = shift;
        my $match = shift;
        my $ID = shift;
        my $i;
        for ($i = 0; $i < @{$r_array} ;$i++) {
                if ((%{$$r_array[$i]} && $$r_array[$i]{$match} eq $ID)
                        || (!%{$$r_array[$i]} && $ID eq "")) {
                        return $i;
                }
        }
        if ($ID eq "") {
                return $i;
        }
}


sub findIndexString_lc {
        my $r_array = shift;
        my $match = shift;
        my $ID = shift;
        my $i;
        for ($i = 0; $i < @{$r_array} ;$i++) {
                if ((%{$$r_array[$i]} && lc($$r_array[$i]{$match}) eq lc($ID))
                        || (!%{$$r_array[$i]} && $ID eq "")) {
                        return $i;
                }
        }
        if ($ID eq "") {
                return $i;
        }
}

sub findKey {
        my $r_hash = shift;
        my $match = shift;
        my $ID = shift;
        foreach (keys %{$r_hash}) {
                if ($$r_hash{$_}{$match} == $ID) {
                        return $_;
                }
        }
}

sub findKeyString {
        my $r_hash = shift;
        my $match = shift;
        my $ID = shift;
        foreach (keys %{$r_hash}) {
                if ($$r_hash{$_}{$match} eq $ID) {
                        return $_;
                }
        }
}

sub minHeapAdd {
        my $r_array = shift;
        my $r_hash = shift;
        my $match = shift;
        my $i;
        my $found;
        my @newArray;
        for ($i = 0; $i < @{$r_array};$i++) {
                if (!$found && $$r_hash{$match} < $$r_array[$i]{$match}) {
                        push @newArray, $r_hash;
                        $found = 1;
                }
                push @newArray, $$r_array[$i];
        }
        if (!$found) {
                push @newArray, $r_hash;
        }
        @{$r_array} = @newArray;
}

sub updateDamageTables {
        my ($ID1, $ID2, $damage) = @_;
        if ($ID1 eq $accountID) {
                if (%{$monsters{$ID2}}) {
                        $monsters{$ID2}{'dmgTo'} += $damage;
                        $monsters{$ID2}{'dmgFromYou'} += $damage;
                        $chars[$config{'char'}]{'totalDamage'} += $damage;
                        $chars[$config{'char'}]{'totalHit'}++;
                        $exp{'monster'}{$monsters{$ID2}{'nameID'}}{'dmgTo'} += $damage;
                        $exp{'monster'}{$monsters{$ID2}{'nameID'}}{'hitTo'}++;
                        if ($damage == 0) {
                                $monsters{$ID2}{'missedFromYou'}++;
                        }
                }
        } elsif ($ID2 eq $accountID) {
                if (%{$monsters{$ID1}}) {
                        $monsters{$ID1}{'dmgFrom'} += $damage;
                        $monsters{$ID1}{'dmgToYou'} += $damage;
                        if ($damage == 0) {
                                $monsters{$ID1}{'missedYou'}++;
                        }
                        $exp{'monster'}{$monsters{$ID1}{'nameID'}}{'dmgFrom'} += $damage;
                        $exp{'monster'}{$monsters{$ID1}{'nameID'}}{'hitFrom'}++;
                }
        } elsif (%{$monsters{$ID1}}) {
                if (%{$players{$ID2}}) {
                        $monsters{$ID1}{'dmgFrom'} += $damage;
                        $monsters{$ID1}{'dmgToPlayer'}{$ID2} += $damage;
                        $players{$ID2}{'dmgFromMonster'}{$ID1} += $damage;
                        if ($damage == 0) {
                                $monsters{$ID1}{'missedToPlayer'}{$ID2}++;
                                $players{$ID2}{'missedFromMonster'}{$ID1}++;
                        }
                        if (%{$chars[$config{'char'}]{'party'}} && %{$chars[$config{'char'}]{'party'}{'users'}{$ID2}}) {
                                $monsters{$ID1}{'dmgToParty'} += $damage;
                        }
                }

        } elsif (%{$players{$ID1}}) {
                if (%{$monsters{$ID2}}) {
                        $monsters{$ID2}{'dmgTo'} += $damage;
                        $monsters{$ID2}{'dmgFromPlayer'}{$ID1} += $damage;
                        $players{$ID1}{'dmgToMonster'}{$ID2} += $damage;
                        if ($damage == 0) {
                                $monsters{$ID2}{'missedFromPlayer'}{$ID1}++;
                                $players{$ID1}{'missedToMonster'}{$ID2}++;
                        }
                        if (%{$chars[$config{'char'}]{'party'}} && %{$chars[$config{'char'}]{'party'}{'users'}{$ID1}}) {
                                $monsters{$ID2}{'dmgFromParty'} += $damage;
                        }
                }
        }
}


#######################################
#######################################
#MISC FUNCTIONS
#######################################
#######################################

sub compilePortals {
        undef %mapPortals;
        foreach (keys %portals_lut) {
                %{$mapPortals{$portals_lut{$_}{'source'}{'map'}}{$_}{'pos'}} = %{$portals_lut{$_}{'source'}{'pos'}};
        }
        $l = 0;
        foreach $map (keys %mapPortals) {
                foreach $portal (keys %{$mapPortals{$map}}) {
                        foreach (keys %{$mapPortals{$map}}) {
                                next if ($_ eq $portal);
                                if ($portals_los{$portal}{$_} eq "" && $portals_los{$_}{$portal} eq "") {
                                        if ($field{'name'} ne $map) {
                                                print "Processing map $map\n";
                                                getField("map/$map.fld", \%field);
                                        }
                                        print "Calculating portal route $portal -> $_\n";
                                        ai_route_getRoute(\@solution, \%field, \%{$mapPortals{$map}{$portal}{'pos'}}, \%{$mapPortals{$map}{$_}{'pos'}});
                                        compilePortals_getRoute();
                                        $portals_los{$portal}{$_} = (@solution) ? 1 : 0;
                                }
                        }
                }
        }

        writePortalsLOS("data/portalsLOS.txt", \%portals_los);

        print "Wrote portals Line of Sight table to 'data/portalsLOS.txt'\n";

}

sub compilePortals_check {
        my $r_return = shift;
        my %mapPortals;
        undef $$r_return;
        foreach (keys %portals_lut) {
                %{$mapPortals{$portals_lut{$_}{'source'}{'map'}}{$_}{'pos'}} = %{$portals_lut{$_}{'source'}{'pos'}};
        }
        foreach $map (keys %mapPortals) {
                foreach $portal (keys %{$mapPortals{$map}}) {
                        foreach (keys %{$mapPortals{$map}}) {
                                next if ($_ eq $portal);
                                if ($portals_los{$portal}{$_} eq "" && $portals_los{$_}{$portal} eq "") {
                                        $$r_return = 1;
                                        return;
                                }
                        }
                }
        }
}

sub compilePortals_getRoute {
        if ($ai_seq[0] eq "route_getRoute") {
                if (!$ai_seq_args[0]{'init'}) {
                        undef @{$ai_v{'temp'}{'subSuc'}};
                        undef @{$ai_v{'temp'}{'subSuc2'}};
                        if (ai_route_getMap(\%{$ai_seq_args[0]}, $ai_seq_args[0]{'start'}{'x'}, $ai_seq_args[0]{'start'}{'y'})) {
                                ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'start'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
                                ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'start'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
                                foreach (@{$ai_v{'temp'}{'subSuc'}}) {
                                        ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
                                        ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
                                }
                                if (@{$ai_v{'temp'}{'subSuc'}}) {
                                        %{$ai_seq_args[0]{'start'}} = %{$ai_v{'temp'}{'subSuc'}[0]};
                                } elsif (@{$ai_v{'temp'}{'subSuc2'}}) {
                                        %{$ai_seq_args[0]{'start'}} = %{$ai_v{'temp'}{'subSuc2'}[0]};
                                }
                        }
                        undef @{$ai_v{'temp'}{'subSuc'}};
                        undef @{$ai_v{'temp'}{'subSuc2'}};
                        if (ai_route_getMap(\%{$ai_seq_args[0]}, $ai_seq_args[0]{'dest'}{'x'}, $ai_seq_args[0]{'dest'}{'y'})) {
                                ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'dest'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
                                ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'dest'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
                                foreach (@{$ai_v{'temp'}{'subSuc'}}) {
                                        ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
                                        ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
                                }
                                if (@{$ai_v{'temp'}{'subSuc'}}) {
                                        %{$ai_seq_args[0]{'dest'}} = %{$ai_v{'temp'}{'subSuc'}[0]};
                                } elsif (@{$ai_v{'temp'}{'subSuc2'}}) {
                                        %{$ai_seq_args[0]{'dest'}} = %{$ai_v{'temp'}{'subSuc2'}[0]};
                                }
                        }
                        $ai_seq_args[0]{'timeout'} = 90000;
                }
                $ai_seq_args[0]{'init'} = 1;
                ai_route_searchStep(\%{$ai_seq_args[0]});
                ai_route_getRoute_destroy(\%{$ai_seq_args[0]});
                shift @ai_seq;
                shift @ai_seq_args;
        }
}


sub getCoordString {
        my $x = shift;
        my $y = shift;
        return pack("C*", int($x / 4), ($x % 4) * 64 + int($y / 16), ($y % 16) * 16);
}

sub getFormattedDate {
        my $thetime = shift;
        my $r_date = shift;
        my @localtime = localtime $thetime;
        my $themonth = (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec)[$localtime[4]];
        $localtime[2] = "0" . $localtime[2] if ($localtime[2] < 10);
        $localtime[1] = "0" . $localtime[1] if ($localtime[1] < 10);
        $localtime[0] = "0" . $localtime[0] if ($localtime[0] < 10);
        $$r_date = "$themonth $localtime[3] $localtime[2]:$localtime[1]:$localtime[0]";
        return $$r_date;
}

sub getHex {
        my $data = shift;
        my $i;
        my $return;
        for ($i = 0; $i < length($data); $i++) {
                $return .= uc(unpack("H2",substr($data, $i, 1)));
                if ($i + 1 < length($data)) {
                        $return .= " ";
                }
        }
        return $return;
}

sub getTickCount {
        my $time = int(time()*1000);
        if (length($time) > 9) {
                return substr($time, length($time) - 8, length($time));
        } else {
                return $time;
        }
}

sub makeCoords {
        my $r_hash = shift;
        my $rawCoords = shift;
        $$r_hash{'x'} = unpack("C", substr($rawCoords, 0, 1)) * 4 + (unpack("C", substr($rawCoords, 1, 1)) & 0xC0) / 64;
        $$r_hash{'y'} = (unpack("C",substr($rawCoords, 1, 1)) & 0x3F) * 16 +
                                (unpack("C",substr($rawCoords, 2, 1)) & 0xF0) / 16;
}

sub makeCoords2 {
        my $r_hash = shift;
        my $rawCoords = shift;
        $$r_hash{'x'} = (unpack("C",substr($rawCoords, 1, 1)) & 0xFC) / 4 +
                                (unpack("C",substr($rawCoords, 0, 1)) & 0x0F) * 64;
        $$r_hash{'y'} = (unpack("C", substr($rawCoords, 1, 1)) & 0x03) * 256 + unpack("C", substr($rawCoords, 2, 1));
}

sub makeIP {
        my $raw = shift;
        my $ret;
        my $i;
        for ($i=0;$i < 4;$i++) {
                $ret .= hex(getHex(substr($raw, $i, 1)));
                if ($i + 1 < 4) {
                        $ret .= ".";
                }
        }
        return $ret;
}

sub portalExists {
        my ($map, $r_pos) = @_;
        foreach (keys %portals_lut) {
                if ($portals_lut{$_}{'source'}{'map'} eq $map && $portals_lut{$_}{'source'}{'pos'}{'x'} == $$r_pos{'x'}
                        && $portals_lut{$_}{'source'}{'pos'}{'y'} == $$r_pos{'y'}) {
                        return $_;
                }
        }
}

sub printItemDesc {
        my $itemID = shift;
        dynParseFiles("data/itemsdescriptions.txt", \%itemsDesc_lut, \&parseRODescLUT);        
        printc("nyn", "-----------", "物品说明", "-----------\n");
        printc("w", "物品: $items_lut{$itemID}\n\n");
        print $itemsDesc_lut{$itemID};
        print "-------------------------------\n";
        undef %itemsDesc_lut;
}

sub timeOut {
        my ($r_time, $compare_time) = @_;
        if ($compare_time ne "") {
                return (time - $r_time > $compare_time);
        } else {
                return (time - $$r_time{'time'} > $$r_time{'timeout'});
        }
}

sub vocalString {
        my $letter_length = shift;
        return if ($letter_length <= 0);
        my $r_string = shift;
        my $test;
        my $i;
        my $password;
        my @cons = ("b", "c", "d", "g", "h", "j", "k", "l", "m", "n", "p", "r", "s", "t", "v", "w", "y", "z", "tr", "cl", "cr", "br", "fr", "th", "dr", "ch", "st", "sp", "sw", "pr", "sh", "gr", "tw", "wr", "ck");
        my @vowels = ("a", "e", "i", "o", "u" , "a", "e" ,"i","o","u","a","e","i","o", "ea" , "ou" , "ie" , "ai" , "ee" ,"au", "oo");
        my %badend = ( "tr" => 1, "cr" => 1, "br" => 1, "fr" => 1, "dr" => 1, "sp" => 1, "sw" => 1, "pr" =>1, "gr" => 1, "tw" => 1, "wr" => 1, "cl" => 1);
        for (;;) {
                $password = "";
                for($i = 0; $i < $letter_length; $i++){
                        $password .= $cons[rand(@cons - 1)] . $vowels[rand(@vowels - 1)];
                }
                $password = substr($password, 0, $letter_length);
                ($test) = ($password =~ /(..)\z/);
                last if ($badend{$test} != 1);
        }
        $$r_string = $password;
        return $$r_string;
}


1;