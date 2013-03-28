#######################################
#######################################
#AI
#######################################
#######################################



sub AI {
        my $i, $j;
        my %cmd = %{(shift)};


        if (timeOut(\%{$timeout{'ai_wipe_check'}})) {
                foreach (keys %players_old) {
                        delete $players_old{$_} if (time - $players_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
                }
                foreach (keys %monsters_old) {
                        delete $monsters_old{$_} if (time - $monsters_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
                }
                foreach (keys %npcs_old) {
                        delete $npcs_old{$_} if (time - $npcs_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
                }
                foreach (keys %items_old) {
                        delete $items_old{$_} if (time - $items_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
                }
                foreach (keys %portals_old) {
                        delete $portals_old{$_} if (time - $portals_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
                }
                $timeout{'ai_wipe_check'}{'time'} = time;
                print "Wiped old\n" if ($config{'debug'} >= 2);
        }

        if (timeOut(\%{$timeout{'ai_getInfo'}})) {
                foreach (keys %players) {
                        if ($players{$_}{'name'} eq "Unknown") {
                                sendGetPlayerInfo(\$remote_socket, $_);
                                last;
                        }
                }
                foreach (keys %monsters) {
                        if ($monsters{$_}{'name'} =~ /Unknown/) {
                                sendGetPlayerInfo(\$remote_socket, $_);
                                last;
                        }
                }
                foreach (keys %npcs) {
                        if ($npcs{$_}{'name'} =~ /Unknown/) {
                                sendGetPlayerInfo(\$remote_socket, $_);
                                last;
                        }
                }
                foreach (keys %pets) {
                        if ($pets{$_}{'name_given'} =~ /Unknown/) {
                                sendGetPlayerInfo(\$remote_socket, $_);
                                last;
                        }
                }
                $timeout{'ai_getInfo'}{'time'} = time;
        }

        if (!$xKore && timeOut(\%{$timeout{'ai_sync'}})) {
                $timeout{'ai_sync'}{'time'} = time;
                sendSync(\$remote_socket, getTickCount());
        }

        return if (!$AI);



        ##### REAL AI STARTS HERE #####

        if (!$accountID) {
                $AI = 0;
                injectAdminMessage("[KE] : KoreEasy 没有获得帐号信息，关闭AI功能。请重新登陆启动AI功能。") if ($config{'verbose'});
                return;
        }

        if (%cmd) {
                $responseVars{'cmd_user'} = $cmd{'user'};
                #Disable remote command if admin password is blank or user name not in admin list - ICE-WR
                if (!$config{'adminMode'} || $cmd{'user'} eq $chars[$config{'char'}]{'name'} || $config{'adminPassword'} eq "" || !existsInList($config{'adminName'}, $cmd{'user'})) {
                        return;
                }
                if ($cmd{'type'} eq "pm" || $cmd{'type'} eq "p" || $cmd{'type'} eq "g") {
                        $ai_v{'temp'}{'qm'} = quotemeta $config{'adminPassword'};
                        if ($cmd{'msg'} =~ /^$ai_v{'temp'}{'qm'}\b/) {
                                if ($overallAuth{$cmd{'user'}} == 1) {
                                        sendMessage(\$remote_socket, "pm", getResponse("authF"), $cmd{'user'});
                                } else {
                                        auth($cmd{'user'}, 1);
                                        sendMessage(\$remote_socket, "pm", getResponse("authS"), $cmd{'user'});
                                }
                        }
                }
                $ai_v{'temp'}{'qm'} = quotemeta $config{'callSign'};
                if ($overallAuth{$cmd{'user'}} >= 1
                        && ($cmd{'msg'} =~ /\b$ai_v{'temp'}{'qm'}\b/i || $cmd{'type'} eq "pm")) {
                        if ($cmd{'msg'} =~ /\bsit\b/i) {
                                $ai_v{'sitAuto_forceStop'} = 0;
                                $ai_v{'attackAuto_old'} = $config{'attackAuto'};
                                $ai_v{'route_randomWalk_old'} = $config{'route_randomWalk'};
                                configModify("attackAuto", 1);
                                configModify("route_randomWalk", 0);
                                aiRemove("move");
                                aiRemove("route");
                                aiRemove("route_getRoute");
                                aiRemove("route_getMapRoute");
                                sit();
                                sendMessage(\$remote_socket, $cmd{'type'}, getResponse("sitS"), $cmd{'user'}) if $config{'verbose'};
                                $timeout{'ai_thanks_set'}{'time'} = time;
                        } elsif ($cmd{'msg'} =~ /\bstand\b/i) {
                                $ai_v{'sitAuto_forceStop'} = 1;
                                if ($ai_v{'attackAuto_old'} ne "") {
                                        configModify("attackAuto", $ai_v{'attackAuto_old'});
                                        configModify("route_randomWalk", $ai_v{'route_randomWalk_old'});
                                }
                                stand();
                                sendMessage(\$remote_socket, $cmd{'type'}, getResponse("standS"), $cmd{'user'}) if $config{'verbose'};
                                $timeout{'ai_thanks_set'}{'time'} = time;
                        } elsif ($cmd{'msg'} =~ /\brelog\b/i) {
                                relog();
                                sendMessage(\$remote_socket, $cmd{'type'}, getResponse("relogS"), $cmd{'user'}) if $config{'verbose'};
                                $timeout{'ai_thanks_set'}{'time'} = time;
                        } elsif ($cmd{'msg'} =~ /\blogout\b/i) {
                                quit();
                                sendMessage(\$remote_socket, $cmd{'type'}, getResponse("quitS"), $cmd{'user'}) if $config{'verbose'};
                                $timeout{'ai_thanks_set'}{'time'} = time;
                        } elsif ($cmd{'msg'} =~ /\breload\b/i) {
                                parseReload($');
                                sendMessage(\$remote_socket, $cmd{'type'}, getResponse("reloadS"), $cmd{'user'}) if $config{'verbose'};
                                $timeout{'ai_thanks_set'}{'time'} = time;
                        } elsif ($cmd{'msg'} =~ /\bstatus\b/i) {
                                $responseVars{'char_sp'} = $chars[$config{'char'}]{'sp'};
                                $responseVars{'char_hp'} = $chars[$config{'char'}]{'hp'};
                                $responseVars{'char_sp_max'} = $chars[$config{'char'}]{'sp_max'};
                                $responseVars{'char_hp_max'} = $chars[$config{'char'}]{'hp_max'};
                                $responseVars{'char_lv'} = $chars[$config{'char'}]{'lv'};
                                $responseVars{'char_lv_job'} = $chars[$config{'char'}]{'lv_job'};
                                $responseVars{'char_exp'} = $chars[$config{'char'}]{'exp'};
                                $responseVars{'char_exp_max'} = $chars[$config{'char'}]{'exp_max'};
                                $responseVars{'char_exp_job'} = $chars[$config{'char'}]{'exp_job'};
                                $responseVars{'char_exp_job_max'} = $chars[$config{'char'}]{'exp_job_max'};
                                $responseVars{'char_weight'} = $chars[$config{'char'}]{'weight'};
                                $responseVars{'char_weight_max'} = $chars[$config{'char'}]{'weight_max'};
                                $responseVars{'zenny'} = $chars[$config{'char'}]{'zenny'};
                                sendMessage(\$remote_socket, $cmd{'type'}, getResponse("statusS"), $cmd{'user'}) if $config{'verbose'};
                        } elsif ($cmd{'msg'} =~ /\bconf\b/i) {
                                $ai_v{'temp'}{'after'} = $';
                                ($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}) = $ai_v{'temp'}{'after'} =~ /(\w+) (\w+)/;
                                @{$ai_v{'temp'}{'conf'}} = keys %config;
                                if ($ai_v{'temp'}{'arg1'} eq "") {
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confF1"), $cmd{'user'}) if $config{'verbose'};
                                } elsif (binFind(\@{$ai_v{'temp'}{'conf'}}, $ai_v{'temp'}{'arg1'}) eq "") {
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confF2"), $cmd{'user'}) if $config{'verbose'};
                                } elsif ($ai_v{'temp'}{'arg2'} eq "value") {
                                        if ($ai_v{'temp'}{'arg1'} =~ /username/i || $ai_v{'temp'}{'arg1'} =~ /password/i) {
                                                sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confF3"), $cmd{'user'}) if $config{'verbose'};
                                        } else {
                                                $responseVars{'key'} = $ai_v{'temp'}{'arg1'};
                                                $responseVars{'value'} = $config{$ai_v{'temp'}{'arg1'}};
                                                sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confS1"), $cmd{'user'}) if $config{'verbose'};
                                                $timeout{'ai_thanks_set'}{'time'} = time;
                                        }
                                } else {
                                        configModify($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'});
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confS2"), $cmd{'user'}) if $config{'verbose'};
                                        $timeout{'ai_thanks_set'}{'time'} = time;
                                }
                        } elsif ($cmd{'msg'} =~ /\btimeout\b/i) {
                                $ai_v{'temp'}{'after'} = $';
                                ($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}) = $ai_v{'temp'}{'after'} =~ /([\s\S]+) (\w+)/;
                                if ($ai_v{'temp'}{'arg1'} eq "") {
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("timeoutF1"), $cmd{'user'}) if $config{'verbose'};
                                } elsif ($timeout{$ai_v{'temp'}{'arg1'}} eq "") {
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("timeoutF2"), $cmd{'user'}) if $config{'verbose'};
                                } elsif ($ai_v{'temp'}{'arg2'} eq "") {
                                        $responseVars{'key'} = $ai_v{'temp'}{'arg1'};
                                        $responseVars{'value'} = $timeout{$ai_v{'temp'}{'arg1'}};
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("timeoutS1"), $cmd{'user'}) if $config{'verbose'};
                                        $timeout{'ai_thanks_set'}{'time'} = time;
                                } else {
                                        setTimeout($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'});
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("timeoutS2"), $cmd{'user'}) if $config{'verbose'};
                                        $timeout{'ai_thanks_set'}{'time'} = time;
                                }
                        } elsif ($cmd{'msg'} =~ /\bshut[\s\S]*up\b/i) {
                                if ($config{'verbose'}) {
                                        configModify("verbose", 0);
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("verboseOffS"), $cmd{'user'});
                                        $timeout{'ai_thanks_set'}{'time'} = time;
                                } else {
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("verboseOffF"), $cmd{'user'});
                                }
                        } elsif ($cmd{'msg'} =~ /\bspeak\b/i) {
                                if (!$config{'verbose'}) {
                                        configModify("verbose", 1);
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("verboseOnS"), $cmd{'user'});
                                        $timeout{'ai_thanks_set'}{'time'} = time;
                                } else {
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("verboseOnF"), $cmd{'user'});
                                }
                        } elsif ($cmd{'msg'} =~ /\bdate\b/i) {
                                $responseVars{'date'} = getFormattedDate(int(time));
                                sendMessage(\$remote_socket, $cmd{'type'}, getResponse("dateS"), $cmd{'user'}) if $config{'verbose'};
                                $timeout{'ai_thanks_set'}{'time'} = time;
                        } elsif ($cmd{'msg'} =~ /\bmove\b/i
                                && $cmd{'msg'} =~ /\bstop\b/i) {
                                aiRemove("move");
                                aiRemove("route");
                                aiRemove("route_getRoute");
                                aiRemove("route_getMapRoute");
                                sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveS"), $cmd{'user'}) if $config{'verbose'};
                                $timeout{'ai_thanks_set'}{'time'} = time;
                        } elsif ($cmd{'msg'} =~ /\bmove\b/i) {
                                $ai_v{'temp'}{'after'} = $';
                                $ai_v{'temp'}{'after'} =~ s/^\s+//;
                                $ai_v{'temp'}{'after'} =~ s/\s+$//;
                                ($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}, $ai_v{'temp'}{'arg3'}) = $ai_v{'temp'}{'after'} =~ /(\d+)\D+(\d+)(.*?)$/;
                                undef $ai_v{'temp'}{'map'};
                                if ($ai_v{'temp'}{'arg1'} eq "") {
                                        ($ai_v{'temp'}{'map'}) = $ai_v{'temp'}{'after'} =~ /(.*?)$/;
                                } else {
                                        $ai_v{'temp'}{'map'} = $ai_v{'temp'}{'arg3'};
                                }
                                $ai_v{'temp'}{'map'} =~ s/\s//g;
                                if (($ai_v{'temp'}{'arg1'} eq "" || $ai_v{'temp'}{'arg2'} eq "") && !$ai_v{'temp'}{'map'}) {
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveF"), $cmd{'user'}) if $config{'verbose'};
                                } else {
                                        $ai_v{'temp'}{'map'} = $field{'name'} if ($ai_v{'temp'}{'map'} eq "");
                                        if ($maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}) {
                                                if ($ai_v{'temp'}{'arg2'} ne "") {
                                                        printc(1, "yw", "<系统>", "正在计算路线: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}\n");
                                                        $ai_v{'temp'}{'x'} = $ai_v{'temp'}{'arg1'};
                                                        $ai_v{'temp'}{'y'} = $ai_v{'temp'}{'arg2'};
                                                } else {
                                                        printc(1, "yw", "<系统>", "正在计算路线: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'})\n");
                                                        undef $ai_v{'temp'}{'x'};
                                                        undef $ai_v{'temp'}{'y'};
                                                }
                                                sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveS"), $cmd{'user'}) if $config{'verbose'};
                                                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
                                                $timeout{'ai_thanks_set'}{'time'} = time;
                                        } else {
                                                printc(1, "yr", "<系统>", "地图 $ai_v{'temp'}{'map'} 不存在\n");
                                                sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveF"), $cmd{'user'}) if $config{'verbose'};
                                        }
                                }
                        } elsif ($cmd{'msg'} =~ /\blook\b/i) {
                                ($ai_v{'temp'}{'body'}) = $cmd{'msg'} =~ /(\d+)/;
                                ($ai_v{'temp'}{'head'}) = $cmd{'msg'} =~ /\d+ (\d+)/;
                                if ($ai_v{'temp'}{'body'} ne "") {
                                        look($ai_v{'temp'}{'body'}, $ai_v{'temp'}{'head'});
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("lookS"), $cmd{'user'}) if $config{'verbose'};
                                        $timeout{'ai_thanks_set'}{'time'} = time;
                                } else {
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("lookF"), $cmd{'user'}) if $config{'verbose'};
                                }

                        } elsif ($cmd{'msg'} =~ /\bfollow/i
                                && $cmd{'msg'} =~ /\bstop\b/i) {
                                if ($config{'follow'}) {
                                        aiRemove("follow");
                                        configModify("follow", 0);
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("followStopS"), $cmd{'user'}) if $config{'verbose'};
                                        $timeout{'ai_thanks_set'}{'time'} = time;
                                } else {
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("followStopF"), $cmd{'user'}) if $config{'verbose'};
                                }
                        } elsif ($cmd{'msg'} =~ /\bfollow\b/i) {
                                $ai_v{'temp'}{'after'} = $';
                                $ai_v{'temp'}{'after'} =~ s/^\s+//;
                                $ai_v{'temp'}{'after'} =~ s/\s+$//;
                                $ai_v{'temp'}{'targetID'} = ai_getIDFromChat(\%players, $cmd{'user'}, $ai_v{'temp'}{'after'});
                                if ($ai_v{'temp'}{'targetID'} ne "") {
                                        aiRemove("follow");
                                        ai_follow($players{$ai_v{'temp'}{'targetID'}}{'name'});
                                        configModify("follow", 1);
                                        configModify("followTarget", $players{$ai_v{'temp'}{'targetID'}}{'name'});
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("followS"), $cmd{'user'}) if $config{'verbose'};
                                        $timeout{'ai_thanks_set'}{'time'} = time;
                                } else {
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("followF"), $cmd{'user'}) if $config{'verbose'};
                                }
                        } elsif ($cmd{'msg'} =~ /\btank/i
                                && $cmd{'msg'} =~ /\bstop\b/i) {
                                if (!$config{'tankMode'}) {
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("tankStopF"), $cmd{'user'}) if $config{'verbose'};
                                } elsif ($config{'tankMode'}) {
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("tankStopS"), $cmd{'user'}) if $config{'verbose'};
                                        configModify("tankMode", 0);
                                        $timeout{'ai_thanks_set'}{'time'} = time;
                                }
                        } elsif ($cmd{'msg'} =~ /\btank/i) {
                                $ai_v{'temp'}{'after'} = $';
                                $ai_v{'temp'}{'after'} =~ s/^\s+//;
                                $ai_v{'temp'}{'after'} =~ s/\s+$//;
                                $ai_v{'temp'}{'targetID'} = ai_getIDFromChat(\%players, $cmd{'user'}, $ai_v{'temp'}{'after'});
                                if ($ai_v{'temp'}{'targetID'} ne "") {
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("tankS"), $cmd{'user'}) if $config{'verbose'};
                                        configModify("tankMode", 1);
                                        configModify("tankModeTarget", $players{$ai_v{'temp'}{'targetID'}}{'name'});
                                        $timeout{'ai_thanks_set'}{'time'} = time;
                                } else {
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("tankF"), $cmd{'user'}) if $config{'verbose'};
                                }
                        } elsif ($cmd{'msg'} =~ /\btown/i) {
                                sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveS"), $cmd{'user'}) if $config{'verbose'};
                                useTeleport(2);

                        } elsif ($cmd{'msg'} =~ /\bwhere\b/i) {
                                $responseVars{'x'} = $chars[$config{'char'}]{'pos_to'}{'x'};
                                $responseVars{'y'} = $chars[$config{'char'}]{'pos_to'}{'y'};
                                $responseVars{'map'} = qq~$maps_lut{$field{'name'}.'.rsw'} ($field{'name'})~;
                                $timeout{'ai_thanks_set'}{'time'} = time;
                                sendMessage(\$remote_socket, $cmd{'type'}, getResponse("whereS"), $cmd{'user'}) if $config{'verbose'};
                        }

                }
                $ai_v{'temp'}{'qm'} = quotemeta $config{'callSign'};
                if ($overallAuth{$cmd{'user'}} >= 1 && ($cmd{'msg'} =~ /\b$ai_v{'temp'}{'qm'}\b/i || $cmd{'type'} eq "pm")
                        && $cmd{'msg'} =~ /\bheal\b/i) {
                        $ai_v{'temp'}{'after'} = $';
                        ($ai_v{'temp'}{'amount'}) = $ai_v{'temp'}{'after'} =~ /(\d+)/;
                        $ai_v{'temp'}{'after'} =~ s/\d+//;
                        $ai_v{'temp'}{'after'} =~ s/^\s+//;
                        $ai_v{'temp'}{'after'} =~ s/\s+$//;
                        $ai_v{'temp'}{'targetID'} = ai_getIDFromChat(\%players, $cmd{'user'}, $ai_v{'temp'}{'after'});
                        if ($ai_v{'temp'}{'targetID'} eq "") {
                                sendMessage(\$remote_socket, $cmd{'type'}, getResponse("healF1"), $cmd{'user'}) if $config{'verbose'};
                        } elsif ($chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'} > 0) {
                                undef $ai_v{'temp'}{'amount_healed'};
                                undef $ai_v{'temp'}{'sp_needed'};
                                undef $ai_v{'temp'}{'sp_used'};
                                undef $ai_v{'temp'}{'failed'};
                                undef @{$ai_v{'temp'}{'skillCasts'}};
                                while ($ai_v{'temp'}{'amount_healed'} < $ai_v{'temp'}{'amount'}) {
                                        for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'}; $i++) {
                                                $ai_v{'temp'}{'sp'} = 10 + ($i * 3);
                                                $ai_v{'temp'}{'amount_this'} = int(($chars[$config{'char'}]{'lv'} + $chars[$config{'char'}]{'int'}) / 8)
                                                                * (4 + $i * 8);
                                                last if ($ai_v{'temp'}{'amount_healed'} + $ai_v{'temp'}{'amount_this'} >= $ai_v{'temp'}{'amount'});
                                        }
                                        $ai_v{'temp'}{'sp_needed'} += $ai_v{'temp'}{'sp'};
                                        $ai_v{'temp'}{'amount_healed'} += $ai_v{'temp'}{'amount_this'};
                                }
                                while ($ai_v{'temp'}{'sp_used'} < $ai_v{'temp'}{'sp_needed'} && !$ai_v{'temp'}{'failed'}) {
                                        for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'}; $i++) {
                                                $ai_v{'temp'}{'lv'} = $i;
                                                $ai_v{'temp'}{'sp'} = 10 + ($i * 3);
                                                if ($ai_v{'temp'}{'sp_used'} + $ai_v{'temp'}{'sp'} > $chars[$config{'char'}]{'sp'}) {
                                                        $ai_v{'temp'}{'lv'}--;
                                                        $ai_v{'temp'}{'sp'} = 10 + ($ai_v{'temp'}{'lv'} * 3);
                                                        last;
                                                }
                                                last if ($ai_v{'temp'}{'sp_used'} + $ai_v{'temp'}{'sp'} >= $ai_v{'temp'}{'sp_needed'});
                                        }
                                        if ($ai_v{'temp'}{'lv'} > 0) {
                                                $ai_v{'temp'}{'sp_used'} += $ai_v{'temp'}{'sp'};
                                                $ai_v{'temp'}{'skillCast'}{'skill'} = 28;
                                                $ai_v{'temp'}{'skillCast'}{'lv'} = $ai_v{'temp'}{'lv'};
                                                $ai_v{'temp'}{'skillCast'}{'maxCastTime'} = 0;
                                                $ai_v{'temp'}{'skillCast'}{'minCastTime'} = 0;
                                                $ai_v{'temp'}{'skillCast'}{'ID'} = $ai_v{'temp'}{'targetID'};
                                                unshift @{$ai_v{'temp'}{'skillCasts'}}, {%{$ai_v{'temp'}{'skillCast'}}};
                                        } else {
                                                $responseVars{'char_sp'} = $chars[$config{'char'}]{'sp'} - $ai_v{'temp'}{'sp_used'};
                                                sendMessage(\$remote_socket, $cmd{'type'}, getResponse("healF2"), $cmd{'user'}) if $config{'verbose'};
                                                $ai_v{'temp'}{'failed'} = 1;
                                        }
                                }
                                if (!$ai_v{'temp'}{'failed'}) {
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("healS"), $cmd{'user'}) if $config{'verbose'};
                                }
                                foreach (@{$ai_v{'temp'}{'skillCasts'}}) {
                                        ai_skillUse($$_{'skill'}, $$_{'lv'}, $$_{'maxCastTime'}, $$_{'minCastTime'}, $$_{'ID'});
                                }
                        } else {
                                sendMessage(\$remote_socket, $cmd{'type'}, getResponse("healF3"), $cmd{'user'}) if $config{'verbose'};
                        }
                }

                if ($overallAuth{$cmd{'user'}} >= 1) {
                        if ($cmd{'msg'} =~ /\bthank/i || $cmd{'msg'} =~ /\bthn/i) {
                                if (!timeOut(\%{$timeout{'ai_thanks_set'}})) {
                                        $timeout{'ai_thanks_set'}{'time'} -= $timeout{'ai_thanks_set'}{'timeout'};
                                        sendMessage(\$remote_socket, $cmd{'type'}, getResponse("thankS"), $cmd{'user'}) if $config{'verbose'};
                                }
                        }
                }
        }


        ##### MISC #####

        if ($ai_seq[0] eq "look" && timeOut(\%{$timeout{'ai_look'}})) {
                $timeout{'ai_look'}{'time'} = time;
                sendLook(\$remote_socket, $ai_seq_args[0]{'look_body'}, $ai_seq_args[0]{'look_head'});
                shift @ai_seq;
                shift @ai_seq_args;
        }

        if ($ai_seq[0] ne "deal" && %currentDeal) {
                unshift @ai_seq, "deal";
                unshift @ai_seq_args, "";
        } elsif ($ai_seq[0] eq "deal" && !%currentDeal) {
                shift @ai_seq;
                shift @ai_seq_args;
        }

        if ($config{'dealAutoCancel'} && %incomingDeal && timeOut(\%{$timeout{'ai_dealAutoCancel'}})) {
                sendDealCancel(\$remote_socket);
                $timeout{'ai_dealAutoCancel'}{'time'} = time;
        }
        if ($config{'partyAutoDeny'} && %incomingParty && timeOut(\%{$timeout{'ai_partyAutoDeny'}})) {
                sendPartyJoin(\$remote_socket, $incomingParty{'ID'}, 0);
                $timeout{'ai_partyAutoDeny'}{'time'} = time;
                undef %incomingParty;
        }
        if ($config{'guildAutoDeny'} && %incomingGuild && timeOut(\%{$timeout{'ai_guildAutoDeny'}})) {
                sendGuildJoin(\$remote_socket, $incomingGuild{'ID'}, 0) if ($incomingGuild{'Type'} == 1);
                sendGuildAlly(\$remote_socket, $incomingGuild{'ID'}, 0) if ($incomingGuild{'Type'} == 2);
                $timeout{'ai_guildAutoDeny'}{'time'} = time;
                undef %incomingGuild;
        }

	if ($config{'friendAutoDeny'} && %incomingFriend && timeOut(\%{$timeout{'ai_friendAutoDeny'}})) {
		sendFriendJoin(\$remote_socket, $incomingFriend{'ID'}, $incomingFriend{'charID'}, 0);
		$timeout{'ai_friendAutoDeny'}{'time'} = time;
		undef %incomingFriend;
	}
	
        if ($ai_v{'portalTrace_mapChanged'}) {
                undef $ai_v{'portalTrace_mapChanged'};
                $ai_v{'temp'}{'first'} = 1;
                undef $ai_v{'temp'}{'foundID'};
                undef $ai_v{'temp'}{'smallDist'};

                foreach (@portalsID_old) {
                        $ai_v{'temp'}{'dist'} = distance(\%{$chars_old[$config{'char'}]{'pos_to'}}, \%{$portals_old{$_}{'pos'}});
                        if ($ai_v{'temp'}{'dist'} <= 7 && ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'})) {
                                $ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
                                $ai_v{'temp'}{'foundID'} = $_;
                                undef $ai_v{'temp'}{'first'};
                        }
                }
                if ($ai_v{'temp'}{'foundID'}) {
                        $ai_v{'portalTrace'}{'source'}{'map'} = $portals_old{$ai_v{'temp'}{'foundID'}}{'source'}{'map'};
                        $ai_v{'portalTrace'}{'source'}{'ID'} = $portals_old{$ai_v{'temp'}{'foundID'}}{'nameID'};
                        %{$ai_v{'portalTrace'}{'source'}{'pos'}} = %{$portals_old{$ai_v{'temp'}{'foundID'}}{'pos'}};
                }
        }

        if (%{$ai_v{'portalTrace'}} && portalExists($ai_v{'portalTrace'}{'source'}{'map'}, \%{$ai_v{'portalTrace'}{'source'}{'pos'}}) ne "") {
                undef %{$ai_v{'portalTrace'}};
        } elsif (%{$ai_v{'portalTrace'}} && $field{'name'}) {
                $ai_v{'temp'}{'first'} = 1;
                undef $ai_v{'temp'}{'foundID'};
                undef $ai_v{'temp'}{'smallDist'};

                foreach (@portalsID) {
                        $ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$portals{$_}{'pos'}});
                        if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'}) {
                                $ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
                                $ai_v{'temp'}{'foundID'} = $_;
                                undef $ai_v{'temp'}{'first'};
                        }
                }

                if (%{$portals{$ai_v{'temp'}{'foundID'}}}) {
                        if (portalExists($field{'name'}, \%{$portals{$ai_v{'temp'}{'foundID'}}{'pos'}}) eq ""
                                && $ai_v{'portalTrace'}{'source'}{'map'} && $ai_v{'portalTrace'}{'source'}{'pos'}{'x'} ne "" && $ai_v{'portalTrace'}{'source'}{'pos'}{'y'} ne ""
                                && $field{'name'} && $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'} ne "" && $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'} ne "") {


                                $portals{$ai_v{'temp'}{'foundID'}}{'name'} = "$field{'name'} -> $ai_v{'portalTrace'}{'source'}{'map'}";
                                $portals{pack("L",$ai_v{'portalTrace'}{'source'}{'ID'})}{'name'} = "$ai_v{'portalTrace'}{'source'}{'map'} -> $field{'name'}";

                                $ai_v{'temp'}{'ID'} = "$ai_v{'portalTrace'}{'source'}{'map'} $ai_v{'portalTrace'}{'source'}{'pos'}{'x'} $ai_v{'portalTrace'}{'source'}{'pos'}{'y'}";
                                $portals_lut{$ai_v{'temp'}{'ID'}}{'source'}{'map'} = $ai_v{'portalTrace'}{'source'}{'map'};
                                %{$portals_lut{$ai_v{'temp'}{'ID'}}{'source'}{'pos'}} = %{$ai_v{'portalTrace'}{'source'}{'pos'}};
                                $portals_lut{$ai_v{'temp'}{'ID'}}{'dest'}{'map'} = $field{'name'};
                                %{$portals_lut{$ai_v{'temp'}{'ID'}}{'dest'}{'pos'}} = %{$portals{$ai_v{'temp'}{'foundID'}}{'pos'}};

                                updatePortalLUT("data/portals.txt",
                                        $ai_v{'portalTrace'}{'source'}{'map'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'x'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'y'},
                                        $field{'name'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'});

                                $ai_v{'temp'}{'ID2'} = "$field{'name'} $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'} $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'}";
                                $portals_lut{$ai_v{'temp'}{'ID2'}}{'source'}{'map'} = $field{'name'};
                                %{$portals_lut{$ai_v{'temp'}{'ID2'}}{'source'}{'pos'}} = %{$portals{$ai_v{'temp'}{'foundID'}}{'pos'}};
                                $portals_lut{$ai_v{'temp'}{'ID2'}}{'dest'}{'map'} = $ai_v{'portalTrace'}{'source'}{'map'};
                                %{$portals_lut{$ai_v{'temp'}{'ID2'}}{'dest'}{'pos'}} = %{$ai_v{'portalTrace'}{'source'}{'pos'}};

                                updatePortalLUT("data/portals.txt",
                                        $field{'name'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'},
                                        $ai_v{'portalTrace'}{'source'}{'map'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'x'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'y'});
                        }
                        undef %{$ai_v{'portalTrace'}};
                }
        }

        if ($xKore && !$sentWelcomeMessage && timeOut(\%{$timeout{'welcomeText'}})) {
                injectAdminMessage($welcomeText) if ($config{'verbose'});
                $sentWelcomeMessage = 1;
        }



        ##### AVOID GM #####

        if ((!$config{'avoidGM_skipInMaps'} || ($config{'avoidGM_skipInMaps'} ne "" && !existsInList($config{'avoidGM_skipInMaps'}, $field{'name'}))) && timeOut(\%{$timeout{'ai_teleport_away'}})) {
                undef $ai_v{'temp'}{'foundID'};
                foreach (@avoidID) {
                        next if ($_ eq "");
                        $ai_v{'temp'}{'foundID'} = $_;
                        last;
                }
                if ($ai_v{'temp'}{'foundID'} ne "") {
                        avoidAID($ai_v{'temp'}{'foundID'});
                        $chars[$config{'char'}]{'avoid'}++;
                } else {
                        undef $chars[$config{'char'}]{'avoid'};
                }
                $timeout{'ai_teleport_away'}{'time'} = time;
        }



        ##### AUTO-TELEPORT #####

        ($ai_v{'map_name_lu'}) = $map_name =~ /([\s\S]*)\./;
        $ai_v{'map_name_lu'} .= ".rsw";
        if ($config{'teleportAuto_onlyWhenSafe'} && binSize(\@playersID)) {
                undef $ai_v{'ai_teleport_safe'};
                if (!$cities_lut{$ai_v{'map_name_lu'}} && timeOut(\%{$timeout{'ai_teleport_safe_force'}})) {
                        $ai_v{'ai_teleport_safe'} = 1;
                }
        } elsif (!$cities_lut{$ai_v{'map_name_lu'}}) {
                $ai_v{'ai_teleport_safe'} = 1;
                $timeout{'ai_teleport_safe_force'}{'time'} = time;
        } else {
                undef $ai_v{'ai_teleport_safe'};
        }

        if ($ai_v{'ai_teleport_safe'} && timeOut(\%{$timeout{'ai_teleport_hp'}})) {
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
	        	} elsif (binFind(\@ai_seq, "sitAuto") ne "" && (ai_getAggressives() || ($config{'teleportAuto_roundMonstersSit'} && ai_getRoundMonster($config{'teleportAuto_roundMonstersDist'})))) {
	                	printc(1, "wr", "<瞬移> ", "坐下时附近有怪物\n") if ($config{'mode'});
				$ai_v{'temp'}{'found'} = 2;
		        } elsif ($config{'teleportAuto_minAggressives'} && ai_getTeleportAggressives() >= $config{'teleportAuto_minAggressives'}) {
	        	        $ai_v{'temp'}{'agMonsters'} = ai_getTeleportAggressives();
        	        	printc(1, "wr", "<瞬移> ", "被$ai_v{'temp'}{'agMonsters'}只怪物攻击\n") if ($config{'mode'});
				$ai_v{'temp'}{'found'} = 2;
		        } elsif ($config{'teleportAuto_roundMonsters'} && ai_getRoundMonster($config{'teleportAuto_roundMonstersDist'}) >= $config{'teleportAuto_roundMonsters'} && $config{'lockMap'} && $field{'name'} && $field{'name'} eq $config{'lockMap'}) {
	        	        $ai_v{'temp'}{'roundMonsters'} = ai_getRoundMonster($config{'teleportAuto_roundMonstersDist'});
        	        	printc(1, "wr", "<瞬移> ", "附近有$ai_v{'temp'}{'roundMonsters'}只怪物\n") if ($config{'mode'});
				$ai_v{'temp'}{'found'} = 2;
		        }
		}
		if ($ai_v{'temp'}{'found'} && (binFind(\@ai_seq, "items_important") eq "" || $ai_v{'temp'}{'found'} >= 2)) {
			useTeleport(1);
		}
		$timeout{'ai_teleport_hp'}{'time'} = time;
	}	

        if ($config{'teleportAuto_portal'} && timeOut(\%{$timeout{'ai_teleport_portal'}}) && $ai_v{'ai_teleport_safe'} && binFind(\@ai_seq, "storageAuto") eq "" && binFind(\@ai_seq, "buyAuto") eq "" && binFind(\@ai_seq, "sellAuto") eq "" && binFind(\@ai_seq, "healAuto") eq ""
                && $config{'lockMap'} && $field{'name'} && $field{'name'} eq $config{'lockMap'}) {
                foreach (@portalsID) {
                        $ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$portals{$_}{'pos'}});;
                        if ($ai_v{'temp'}{'dist'} <= $config{'teleportAuto_portalDist'} && binFind(\@ai_seq, "items_important") eq "") {
                                printc(1, "wr", "<瞬移> ", "躲避地图传送点\n") if ($config{'mode'});
                                useTeleport(1);
                                last;
                        }
                }
                $timeout{'ai_teleport_portal'}{'time'} = time;
        }
        


        ##### FLY MAP #####

        if ($sendFlyMap && $ai_seq[0] ne "flyMap") {
                        unshift @ai_seq, "flyMap";
                        unshift @ai_seq_args, {};
                        $ai_v{'temp'}{'send_fly'} = 1;
        }
        if ($ai_seq[0] eq "flyMap" && timeOut(1, $timeout{'ai_flyMap'}{'time'})) {
                if ($ai_v{'temp'}{'send_fly'} && $ai_seq_args[0]{'teleport_tried'} < 3) {
	                useTeleport(1);
        	        $ai_seq_args[0]{'teleport_tried'}++;
	        } elsif ($ai_seq[0] eq "flyMap" && !$ai_v{'temp'}{'send_fly'}) {
        	        undef $sendFlyMap;
                	shift @ai_seq;
	                shift @ai_seq_args;
        	} elsif ($ai_seq[0] eq "flyMap") {
                	undef $sendFlyMap;
	                shift @ai_seq;
        	        shift @ai_seq_args;
        		sendQuitToCharSelete(\$remote_socket);
	        	$conState = 1;
        		$timeout{'master'}{'time'} = time;
                	return;
		}
		$timeout{'ai_flyMap'}{'time'} = time;
	}


        ##### CLIENT SUSPEND #####
        # The clientSuspend AI sequence is used to freeze all other AI activity
        # for a certain period of time.

        if ($ai_seq[0] eq "clientSuspend" && timeOut(\%{$ai_seq_args[0]})) {
                shift @ai_seq;
                shift @ai_seq_args;
        } elsif ($ai_seq[0] eq "clientSuspend" && $xKore) {
                # When XKore mode is turned on, clientSuspend will increase it's timeout
                # every time the user tries to do something manually.

                if ($ai_seq_args[0]{'type'} eq "0089") {
                        # Player's manually attacking
                        if ($ai_seq_args[0]{'args'}[0] == 2) {
                                if ($chars[$config{'char'}]{'sitting'}) {
                                        $ai_seq_args[0]{'time'} = time;
                                }
                        } elsif ($ai_seq_args[0]{'args'}[0] == 3) {
                                $ai_seq_args[0]{'timeout'} = 6;
                        } else {
                                if (!$ai_seq_args[0]{'forceGiveup'}{'timeout'}) {
                                        $ai_seq_args[0]{'forceGiveup'}{'timeout'} = 6;
                                        $ai_seq_args[0]{'forceGiveup'}{'time'} = time;
                                }
                                if ($ai_seq_args[0]{'dmgFromYou_last'} != $monsters{$ai_seq_args[0]{'args'}[1]}{'dmgFromYou'}) {
                                        $ai_seq_args[0]{'forceGiveup'}{'time'} = time;
                                }
                                $ai_seq_args[0]{'dmgFromYou_last'} = $monsters{$ai_seq_args[0]{'args'}[1]}{'dmgFromYou'};
                                $ai_seq_args[0]{'missedFromYou_last'} = $monsters{$ai_seq_args[0]{'args'}[1]}{'missedFromYou'};
                                if (%{$monsters{$ai_seq_args[0]{'args'}[1]}}) {
                                        $ai_seq_args[0]{'time'} = time;
                                } else {
                                        $ai_seq_args[0]{'time'} -= $ai_seq_args[0]{'timeout'};
                                }
                                if (timeOut(\%{$ai_seq_args[0]{'forceGiveup'}})) {
                                        $ai_seq_args[0]{'time'} -= $ai_seq_args[0]{'timeout'};
                                }
                        }

                } elsif ($ai_seq_args[0]{'type'} eq "009F") {
                        # Player's manually picking up an item
                        if (!$ai_seq_args[0]{'forceGiveup'}{'timeout'}) {
                                $ai_seq_args[0]{'forceGiveup'}{'timeout'} = 4;
                                $ai_seq_args[0]{'forceGiveup'}{'time'} = time;
                        }
                        if (%{$items{$ai_seq_args[0]{'args'}[0]}}) {
                                $ai_seq_args[0]{'time'} = time;
                        } else {
                                $ai_seq_args[0]{'time'} -= $ai_seq_args[0]{'timeout'};
                        }
                        if (timeOut(\%{$ai_seq_args[0]{'forceGiveup'}})) {
                                $ai_seq_args[0]{'time'} -= $ai_seq_args[0]{'timeout'};
                        }
                }
        }


        ##### MVP MODE #####

        if ($chars[$config{'char'}]{'mvp'} && ($ai_seq[0] eq "" || $ai_seq[0] eq "follow")) {
                undef $ai_v{'temp'}{'foundID'};
                foreach (@monstersID) {
                        next if ($_ eq "");
                        $ai_v{'temp'}{'foundID'} = 1 if ($monsters{$_}{'mvp'} == 1);
                }
                ai_changeToMvpMode(0) if (!$ai_v{'temp'}{'foundID'});
        }
	if ($ai_v{'mvp_notice_message'} ne "" && timeOut(3, $ai_v{'mvp_notice_time'})) {
		$ai_v{'mvp_notice_sent'}++;
		if ($ai_v{'mvp_notice_sent'} < 60) {
			sendMessage(\$remote_socket, "g", $ai_v{'mvp_notice_message'}."|".int(time - $ai_v{'mvp_notice_init_time'}));
		} else {
			undef $ai_v{'mvp_notice_message'};
			undef $ai_v{'mvp_notice_sent'};
		}
		$ai_v{'mvp_notice_time'} = time;
	}
	if ($config{'mvpMode'} >=2 && $config{'lockMap_x'} ne "" && (abs($chars[$config{'char'}]{'pos_to'}{'x'} - $config{'lockMap_x'}) + abs($chars[$config{'char'}]{'pos_to'}{'y'} - $config{'lockMap_y'})) < 15) {
		undef $config{'lockMap_x'};
		undef $config{'lockMap_y'};		
	}
	mvpMapChange() if ($config{'mvpMode'} >= 2);



        #####AUTO SHOP#####

        AUTOSHOP: {

        if ($ai_seq[0] eq "shop" && !$chars[$config{'char'}]{'shopOpened'}) {
                shift @ai_seq;
                shift @ai_seq_args;
        } elsif ($ai_seq[0] eq "shop" && $shop{'soldOutIndex'} ne "" && time - $shop{'soldOutTime'} > 1) {
        	undef $shop{'soldOutIndex'};
        	undef $shop{'soldOutTime'};
		sendCloseShop(\$remote_socket);       	
        	$timeout{'ai_shopAutoGet'}{'time'} = time;
	        $timeout{'ai_shopAuto'}{'time'} = time;
        } elsif ($ai_seq[0] ne "shop" && $chars[$config{'char'}]{'shopOpened'}) {
                undef @ai_seq;
                undef @ai_seq_args;
                unshift @ai_seq, "shop";
                unshift @ai_seq_args, {};
        }
        if ($shop_control{'shopAuto_open'} && $ai_seq[0] eq "" && !$chars[$config{'char'}]{'shopOpened'}) {
                if ($config{'cartAuto'} && $cart{'weight_max'} > 0 && ($cart{'weight'}/$cart{'weight_max'}*100) < $config{'cartMaxWeight'} && $cart{'items'} < $cart{'items_max'} && timeOut(\%{$timeout{'ai_shopAutoGet'}})) {
                        undef $ai_v{'temp'}{'invIndex'};
                        undef $ai_v{'temp'}{'cartIndex'};
                        $i = 0;
                        while (1) {
                                last if (!$shop_control{"name_$i"});
                                $j = 0;
                                while ($config{"getAuto_$j"} ne "") {
                                        if ($shop_control{"name_$i"} eq $config{"getAuto_$j"}) {
                                                $ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $shop_control{"name_$i"});
                                                $ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $shop_control{"name_$i"});
                                                if ($ai_v{'temp'}{'cartIndex'} eq "" && $ai_v{'temp'}{'invIndex'} ne "") {
                                                        sendCartAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'});
                                                        $timeout{'ai_shopAutoGet'}{'time'} = time;
                                                        $timeout{'ai_shopAuto'}{'time'} = time;
                                                        last AUTOSHOP;
                                                }
                                        }
                                        $j++;
                                }
                                $i++;
                        }
                }
                if (timeOut(\%{$timeout{'ai_shopAuto'}})) {
                        sendOpenShop(\$remote_socket);
                        $timeout{'ai_shopAuto'}{'time'} = time;
                }
        }

        } #END OF BLOCK AUTOSHOP


        #####AUTO HEAL#####

        AUTOHEAL: {

        if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "sitAuto" || $ai_seq[0] eq "follow") && $config{'healAuto'} && $config{'healAuto_npc'} ne "" && $chars[$config{'char'}]{'hp'} > 0 && !$chars[$config{'char'}]{'mvp'}
                && (percent_hp(\%{$chars[$config{'char'}]}) < $config{'healAuto_hp'} || percent_sp(\%{$chars[$config{'char'}]}) < $config{'healAuto_sp'})) {
                $ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
                if ($ai_v{'temp'}{'ai_route_index'} ne "") {
                        $ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
                }
                if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1)) {
                        printc(1, "yw", "<系统> ", "开始自动恢复\n");
                        unshift @ai_seq, "healAuto";
                        unshift @ai_seq_args, {};
                        $exp{'base'}{'back'}++;
                }
        }

        if ($ai_seq[0] eq "healAuto" && $ai_seq_args[0]{'done'} && (percent_hp(\%{$chars[$config{'char'}]}) < 100 || percent_sp(\%{$chars[$config{'char'}]}) < 100)) {
                shift @ai_seq;
                shift @ai_seq_args;
                unshift @ai_seq, "healAuto";
                unshift @ai_seq_args, {};
        }
        if ($ai_seq[0] eq "healAuto" && ($ai_seq_args[0]{'done'} || !$config{'healAuto'} || !$config{'healAuto_npc'})) {
                undef %{$ai_v{'temp'}{'ai'}};
                %{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
                shift @ai_seq;
                shift @ai_seq_args;
        } elsif ($ai_seq[0] eq "healAuto" && timeOut(\%{$timeout{'ai_healAuto'}})) {
                if (!$config{'healAuto'} || !%{$npcs_lut{$config{'healAuto_npc'}}}) {
                        $ai_seq_args[0]{'done'} = 1;
                        last AUTOHEAL;
                }

                undef $ai_v{'temp'}{'do_route'};
                if ($field{'name'} ne $npcs_lut{$config{'healAuto_npc'}}{'map'}) {
                        $ai_v{'temp'}{'do_route'} = 1;
                } else {
                        $ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{'healAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
                        if ($ai_v{'temp'}{'distance'} > 14) {
                                $ai_v{'temp'}{'do_route'} = 1;
                        }
                }
                if ($ai_v{'temp'}{'do_route'}) {
                        if ($ai_seq_args[0]{'warpedToSave'} && $field{'name'} ne $config{'saveMap'}) {
                                undef $ai_seq_args[0]{'warpedToSave'};
                        }
                        $accIndex = findIndexStringsNotSelected_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'accessoryTeleport'});
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 602);
                        if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'} && ($accIndex ne "" || $invIndex ne "" || $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} >= 1)) {
                                $ai_seq_args[0]{'warpedToSave'} = 1;
                                useTeleport(2);
                                ai_clientSuspend(0,2);
                        } else {
                                printc(1, "yw", "<系统> ", "正在计算自动治疗路线: $maps_lut{$npcs_lut{$config{'healAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'healAuto_npc'}}{'map'}): $npcs_lut{$config{'healAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'healAuto_npc'}}{'pos'}{'y'}\n");
                                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{'healAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'healAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$config{'healAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
                        }
                } else {
                        if (!$ai_seq_args[0]{'npc'}{'sentTalk'}) {
                                sendTalk(\$remote_socket, pack("L1",$config{'healAuto_npc'}));
                                @{$ai_seq_args[0]{'npc'}{'steps'}} = split(/ /, $config{'healAuto_npc_steps'});
                                $ai_seq_args[0]{'npc'}{'sentTalk'} = 1;
                        } elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /c/i) {
                                sendTalkContinue(\$remote_socket, pack("L1",$config{'healAuto_npc'}));
                                $ai_seq_args[0]{'npc'}{'step'}++;
                        } elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /n/i) {
                                sendTalkCancel(\$remote_socket, pack("L1",$config{'healAuto_npc'}));
                                $ai_seq_args[0]{'npc'}{'step'}++;
                        } else {
                                ($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i;
                                if ($ai_v{'temp'}{'arg'} ne "") {
                                        $ai_v{'temp'}{'arg'}++;
                                        sendTalkResponse(\$remote_socket, pack("L1",$config{'healAuto_npc'}), $ai_v{'temp'}{'arg'});
                                }
                                $ai_seq_args[0]{'npc'}{'step'}++;
                        }
                        $ai_seq_args[0]{'done'} = 1 if ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] eq "");
                        $timeout{'ai_healAuto'}{'time'} = time;
                        $timeout{'ai_healAuto'}{'time'} = time + 0.5 if ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] eq "");
                }
        }

        } #END OF BLOCK AUTOHEAL



        #####AUTO FIX#####

        AUTOFIX: {

        if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "sitAuto" || $ai_seq[0] eq "follow") && $config{'fixAuto'} && $config{'fixAuto_npc'} ne "" && !$chars[$config{'char'}]{'mvp'}
                && findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "broken", 1) ne "" && timeOut(\%{$timeout{'ai_fixAuto'}})) {
                $ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
                if ($ai_v{'temp'}{'ai_route_index'} ne "") {
                        $ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
                }
                if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1)) {
                        printc(1, "yw", "<系统> ", "开始自动修理\n");
                        unshift @ai_seq, "fixAuto";
                        unshift @ai_seq_args, {};
                        $exp{'base'}{'back'}++;
                }
        }

        if ($ai_seq[0] eq "fixAuto" && $ai_seq_args[0]{'done'} && findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "broken", 1) ne "") {
                shift @ai_seq;
                shift @ai_seq_args;
                unshift @ai_seq, "fixAuto";
                unshift @ai_seq_args, {};
        }
        if ($ai_seq[0] eq "fixAuto" && ($ai_seq_args[0]{'done'} || !$config{'fixAuto'} || !$config{'fixAuto_npc'})) {
                undef %{$ai_v{'temp'}{'ai'}};
                %{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
                for (my $i = 0; $i < @{$ai_seq_args[0]{'index_list'}} ;$i++) {
                	sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'index_list'}[$i]]{'index'}, $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'index_list'}[$i]]{'type_equip'});
        	}
                shift @ai_seq;
                shift @ai_seq_args;
        } elsif ($ai_seq[0] eq "fixAuto" && timeOut(\%{$timeout{'ai_fixAuto'}})) {
                if (!$config{'fixAuto'} || !%{$npcs_lut{$config{'fixAuto_npc'}}}) {
                        $ai_seq_args[0]{'done'} = 1;
                        last AUTOHEAL;
                }

                undef $ai_v{'temp'}{'do_route'};
                if ($field{'name'} ne $npcs_lut{$config{'fixAuto_npc'}}{'map'}) {
                        $ai_v{'temp'}{'do_route'} = 1;
                } else {
                        $ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{'fixAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
                        if ($ai_v{'temp'}{'distance'} > 14) {
                                $ai_v{'temp'}{'do_route'} = 1;
                        }
                }
                if ($ai_v{'temp'}{'do_route'}) {
                        if ($ai_seq_args[0]{'warpedToSave'} && $field{'name'} ne $config{'saveMap'}) {
                                undef $ai_seq_args[0]{'warpedToSave'};
                        }
                        $accIndex = findIndexStringsNotSelected_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'accessoryTeleport'});
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 602);
                        if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'} && ($accIndex ne "" || $invIndex ne "" || $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} >= 1)) {
                                $ai_seq_args[0]{'warpedToSave'} = 1;
                                useTeleport(2);
                                ai_clientSuspend(0,2);
                        } else {
                                printc(1, "yw", "<系统> ", "正在计算自动修理路线: $maps_lut{$npcs_lut{$config{'fixAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'fixAuto_npc'}}{'map'}): $npcs_lut{$config{'fixAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'fixAuto_npc'}}{'pos'}{'y'}\n");
                                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{'fixAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'fixAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$config{'fixAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
                        }
                } else {
                	if (!@{$ai_seq_args[0]{'index_list'}}) {
        	        	for (my $i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
	                		next if (!$chars[$config{'char'}]{'inventory'}[$i]);
                	        	if ($chars[$config{'char'}]{'inventory'}[$i]{'broken'}) {
                		        	push @{$ai_seq_args[0]{'index_list'}}, $i;
                		        }
        	        	}
	                }
                        if (!$ai_seq_args[0]{'npc'}{'sentTalk'}) {
                                sendTalk(\$remote_socket, pack("L1",$config{'fixAuto_npc'}));
                                @{$ai_seq_args[0]{'npc'}{'steps'}} = split(/ /, $config{'fixAuto_npc_steps'});
                                $ai_seq_args[0]{'npc'}{'sentTalk'} = 1;
                        } elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /c/i) {
                                sendTalkContinue(\$remote_socket, pack("L1",$config{'fixAuto_npc'}));
                                $ai_seq_args[0]{'npc'}{'step'}++;
                        } elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /n/i) {
                                sendTalkCancel(\$remote_socket, pack("L1",$config{'fixAuto_npc'}));
                                $ai_seq_args[0]{'npc'}{'step'}++;
                        } else {
                                ($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i;
                                if ($ai_v{'temp'}{'arg'} ne "") {
                                        $ai_v{'temp'}{'arg'}++;
                                        sendTalkResponse(\$remote_socket, pack("L1",$config{'fixAuto_npc'}), $ai_v{'temp'}{'arg'});
                                }
                                $ai_seq_args[0]{'npc'}{'step'}++;
                        }
                        $ai_seq_args[0]{'done'} = 1 if ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] eq "");
                        $timeout{'ai_fixAuto'}{'time'} = time;
                        $timeout{'ai_fixAuto'}{'time'} = time + 1 if ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] eq "");
                }
        }

        } #END OF BLOCK AUTOHEAL



        #####AUTO STORAGE#####

        AUTOSTORAGE: {

        if (($ai_seq[0] eq "" || $ai_seq[0] eq "route") && $config{'storageAuto'} && $config{'storageAuto_npc'} ne "" && percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'}) {
                $ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
                if ($ai_v{'temp'}{'ai_route_index'} ne "") {
                        $ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
                }
                if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && ai_storageAutoCheck()) {
                        printc(1, "yw", "<系统> ", "开始自动存仓\n");
			unshift @ai_seq, "sellAuto";
			unshift @ai_seq_args, {};
                        $exp{'base'}{'back'}++;
                }
        } elsif (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "attack"  || ($ai_seq[0] eq "refineAuto" && !$ai_seq_args[0]{'refineReady'})) && timeOut(\%{$timeout{'ai_storageAuto'}}) && $ai_v{'temp'}{'inventory_received'}) {
                undef $ai_v{'temp'}{'found'};
                undef $ai_v{'temp'}{'index'};
                undef $ai_v{'temp'}{'cartIndex'};
                undef $ai_v{'temp'}{'invIndex'};
                undef $ai_v{'temp'}{'invAmount'};
                $i = 0;
                while (1) {
                        last if (!$config{"getAuto_$i"} || !$config{"getAuto_$i"."_npc"});
                        $ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"getAuto_$i"});
                        if (ai_checkItemState($config{"getAuto_$i"}) && $config{"getAuto_$i"."_minAmount"} >= 0 && $config{"getAuto_$i"."_maxAmount"} ne "" && !$stockVoid{$config{"getAuto_$i"}}
                                && ($ai_v{'temp'}{'invIndex'} eq "" || ($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} <= $config{"getAuto_$i"."_minAmount"}
                                && $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $config{"getAuto_$i"."_maxAmount"}))) {
                                $ai_v{'temp'}{'found'} = 1;
                                $ai_v{'temp'}{'index'} = $i;
                                $ai_v{'temp'}{'invAmount'} = $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} if ($ai_v{'temp'}{'invIndex'} ne "");
                                last;                                
                        }
                        $i++;
                }
                $ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
                if ($ai_v{'temp'}{'ai_route_index'} ne "") {
                        $ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
                }
                if ($ai_v{'temp'}{'found'}) {
                        $ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $config{"getAuto_".$ai_v{'temp'}{'index'}}) if ($config{'cartAuto'} && $cart{'weight_max'} > 0);
                        if ($ai_v{'temp'}{'cartIndex'} ne "" && !$shop_control{'shopAuto_open'}) {
                                if ($config{"getAuto_".$ai_v{'temp'}{'index'}."_maxAmount"} - $ai_v{'temp'}{'invAmount'} > $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'}) {
                                        sendCartGet(\$remote_socket, $ai_v{'temp'}{'cartIndex'}, $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'});
                                } else {
                                        sendCartGet(\$remote_socket, $ai_v{'temp'}{'cartIndex'}, $config{"getAuto_".$ai_v{'temp'}{'index'}."_maxAmount"} - $ai_v{'temp'}{'invAmount'});
                                }
                        } elsif (!$chars[$config{'char'}]{'mvp'} && !($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && $ai_v{'temp'}{'found'}) {
                                printc(1, "yw", "<系统> ", "开始自动取仓\n");
				unshift @ai_seq, "sellAuto";
				unshift @ai_seq_args, {};
                                $exp{'base'}{'back'}++;
                        }
                }
                $timeout{'ai_storageAuto'}{'time'} = time;
        }
        if ($ai_seq[0] eq "storageAuto" && $ai_seq_args[0]{'done'}) {
                undef %{$ai_v{'temp'}{'ai'}};
                %{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
                shift @ai_seq;
                shift @ai_seq_args;
                if ($ai_v{'ai_storageAuto_clear'}) {
			unshift @ai_seq, "sellAuto";
			unshift @ai_seq_args, {};
        	} elsif (!$ai_v{'temp'}{'ai'}{'completedAI'}{'buyAuto'}) {
                        $ai_v{'temp'}{'ai'}{'completedAI'}{'storageAuto'} = 1;
                        unshift @ai_seq, "buyAuto";
                        unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
                }
        } elsif ($ai_seq[0] eq "storageAuto" && timeOut(\%{$timeout{'ai_storageAuto'}})) {
                if ((!$config{'storageAuto'} && !$config{'getAuto_0'}) || !%{$npcs_lut{$config{'storageAuto_npc'}}}) {
                        $ai_seq_args[0]{'done'} = 1;
                        last AUTOSTORAGE;
                }

                undef $ai_v{'temp'}{'do_route'};
                if ($field{'name'} ne $npcs_lut{$config{'storageAuto_npc'}}{'map'}) {
                        $ai_v{'temp'}{'do_route'} = 1;
                } else {
                        $ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{'storageAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
                        if ($ai_v{'temp'}{'distance'} > 14) {
                                $ai_v{'temp'}{'do_route'} = 1;
                        }
                }
                if ($ai_v{'temp'}{'do_route'}) {
                        if ($ai_seq_args[0]{'warpedToSave'} && $field{'name'} ne $config{'saveMap'}) {
                                undef $ai_seq_args[0]{'warpedToSave'};
                        }
                        $accIndex = findIndexStringsNotSelected_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'accessoryTeleport'});
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 602);
                        if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'} && ($accIndex ne "" || $invIndex ne "" || $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} >= 1)) {
                                $ai_seq_args[0]{'warpedToSave'} = 1;
                                printc(1, "ww", "<瞬移> ", "自动存仓\n");
                                useTeleport(2);
                                ai_clientSuspend(0,2);
                        } else {
                                printc(1, "yw", "<系统> ", "正在计算自动存仓路线: $maps_lut{$npcs_lut{$config{'storageAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'storageAuto_npc'}}{'map'}): $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'}\n");
                                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$config{'storageAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
                        }
                } else {
                        if (!$ai_seq_args[0]{'sentTalk'}) {
                                sendTalk(\$remote_socket, pack("L1",$config{'storageAuto_npc'}));
                                @{$ai_seq_args[0]{'steps'}} = split(/ /, $config{'storageAuto_npc_steps'});
                                $ai_seq_args[0]{'sentTalk'} = 1;
                                undef %stockVoid;
                                $timeout{'ai_storageAuto'}{'time'} = time;
                                last AUTOSTORAGE;
                        } elsif (defined(@{$ai_seq_args[0]{'steps'}})) {
                                if ($ai_seq_args[0]{'steps'}[$ai_seq_args[0]{'step'}] =~ /c/i) {
                                        sendTalkContinue(\$remote_socket, pack("L1",$config{'storageAuto_npc'}));
                                } elsif ($ai_seq_args[0]{'steps'}[$ai_seq_args[0]{'step'}] =~ /n/i) {
                                        sendTalkCancel(\$remote_socket, pack("L1",$config{'storageAuto_npc'}));
                                } elsif ($ai_seq_args[0]{'steps'}[$ai_seq_args[0]{'step'}] ne "") {
                                        ($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'steps'}[$ai_seq_args[0]{'step'}] =~ /r(\d+)/i;
                                        if ($ai_v{'temp'}{'arg'} ne "") {
                                                $ai_v{'temp'}{'arg'}++;
                                                sendTalkResponse(\$remote_socket, pack("L1",$config{'storageAuto_npc'}), $ai_v{'temp'}{'arg'});
                                        }
                                } else {
                                        undef @{$ai_seq_args[0]{'steps'}};
                                }
                                $ai_seq_args[0]{'step'}++;
                                $timeout{'ai_storageAuto'}{'time'} = time;
                                last AUTOSTORAGE;
                        } elsif (!$storage{'items_max'}) {
                        	$ai_v{'storageAuto_failed'}++;
		                sendStorageClose(\$remote_socket);
                        	shift @ai_seq;
                                shift @ai_seq_args;
		                unshift @ai_seq, "storageAuto";
		                unshift @ai_seq_args, {};
				if ($ai_v{'storageAuto_failed'} > 20) {
					undef $ai_v{'storageAuto_failed'};
					printc("yr", "<系统> ", "20次无法打开仓库，重新启动\n");
                        		relog();
                        	}
                                last AUTOSTORAGE;
                        }
			undef $ai_v{'storageAuto_failed'};
			
                        if ($config{'storageAuto'} == 2 && $ai_seq_args[0]{'clearIndex'} <= 15) {
                        	while ($ai_seq_args[0]{'clearIndex'} <= 15) {
                        		if (findIndexString(\@{$chars[$config{'char'}]{'inventory'}}, "index", $ai_seq_args[0]{'clearIndex'}) eq "") {
						sendStorageAdd(\$remote_socket, $ai_seq_args[0]{'clearIndex'}, 1000);
                                		$timeout{'ai_storageAuto'}{'time'} = time;
                        			$ai_seq_args[0]{'clearIndex'}++;
                        			last AUTOSTORAGE;
                        		} else {
                        			$ai_seq_args[0]{'clearIndex'}++;
                        		}
                        	}
                        }
                        $ai_seq_args[0]{'done'} = 1;
			if (!$ai_seq_args[0]{'getStart'}) {
				for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
					next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'});
					if ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'storage'}
						&& $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}) {
						if ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $chars[$config{'char'}]{'inventory'}[$i]{'index'}
							&& timeOut(\%{$timeout{'ai_storageAuto_giveup'}})) {
							last AUTOSTORAGE;
						} elsif ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $chars[$config{'char'}]{'inventory'}[$i]{'index'}) {
							$timeout{'ai_storageAuto_giveup'}{'time'} = time;
						}
						undef $ai_seq_args[0]{'done'};
						$ai_seq_args[0]{'lastIndex'} = $chars[$config{'char'}]{'inventory'}[$i]{'index'};
						sendStorageAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$i]{'index'}, $chars[$config{'char'}]{'inventory'}[$i]{'amount'} - $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'});
						$timeout{'ai_storageAuto'}{'time'} = time;
						last AUTOSTORAGE;
					}
				}
                	        if ($config{'cartAuto'} && $config{'cartAutoStorage'} && $cart{'items'} > 0) {
        	                        $ai_seq_args[0]{'done'} = 1;
	                                for ($i = 0; $i < @{$cart{'inventory'}};$i++) {
                                        	next if (!%{$cart{'inventory'}[$i]} || !$items_control{lc($cart{'inventory'}[$i]{'name'})}{'storage'});
                                	        next if ($items_control{lc($cart{'inventory'}[$i]{'name'})}{'keepCart'} && $cart{'inventory'}[$i]{'amount'} <= $items_control{lc($cart{'inventory'}[$i]{'name'})}{'keepCart'});
                        	                if ($items_control{lc($cart{'inventory'}[$i]{'name'})}{'keepCart'}) {
                	                                $ai_v{'temp'}{'cartGetAmount'} = $cart{'inventory'}[$i]{'amount'} - $items_control{lc($cart{'inventory'}[$i]{'name'})}{'keepCart'};
        	                                } else {
	                                                $ai_v{'temp'}{'cartGetAmount'} = $cart{'inventory'}[$i]{'amount'};
                                        	}
                                	        if ($ai_v{'temp'}{'cartGetAmount'} > int(($chars[$config{'char'}]{'weight_max'} - $chars[$config{'char'}]{'weight'}) / $config{'cartAutoItemMaxWeight'})) {
                        	                        sendCartGet(\$remote_socket, $i, int(($chars[$config{'char'}]{'weight_max'} - $chars[$config{'char'}]{'weight'}) / $config{'cartAutoItemMaxWeight'}));
                	                        } else {
        	                                        sendCartGet(\$remote_socket, $i, $ai_v{'temp'}{'cartGetAmount'});
	                                        }
                                        	undef $ai_seq_args[0]{'lastIndex'};
                                	        undef $ai_seq_args[0]{'done'};
                        	                $timeout{'ai_storageAuto'}{'time'} = time;
                	                        last AUTOSTORAGE;
        	                        }
	                        }
			}	
			if (!$ai_seq_args[0]{'getStart'} && $ai_seq_args[0]{'done'} == 1) {
				$ai_seq_args[0]{'getStart'} = 1;
				undef $ai_seq_args[0]{'done'};
				last AUTOSTORAGE; 
			}
			if ($ai_v{'ai_storageAuto_clear'} && percent_weight(\%{$chars[$config{'char'}]}) < $config{'itemsMaxWeight'}) {
        			dynParseFiles("data/itemsdescriptions.txt", \%itemsWeight_lut, \&parseRODescLUT2) if (!%itemsWeight_lut);
        			undef $config{'getAuto_0'};
        			undef $config{'getAuto_0_minAmount'};
        			undef $config{'getAuto_0_maxAmount'};
        			undef $ai_v{'ai_storageAuto_clear'};
        			for ($i = 0; $i < @{$storage{'inventory'}}; $i++) {
        				next if (!{$storage{'inventory'}[$i]});
        				if (!$items_control{lc($storage{'inventory'}[$i]{'name'})}{'keep'} && $items_control{lc($storage{'inventory'}[$i]{'name'})}{'sell'}) {
						if (!$itemsWeight_lut{$storage{'inventory'}[$i]{'nameID'}}) {
							$itemsWeight_lut{$storage{'inventory'}[$i]{'nameID'}} = $config{'cartAutoItemMaxWeight'};
						}
						$config{'getAuto_0'} = $storage{'inventory'}[$i]{'name'};
						$config{'getAuto_0_minAmount'} = 0;
						$config{'getAuto_0_maxAmount'} = int(($chars[$config{'char'}]{'weight_max'} - $chars[$config{'char'}]{'weight'}) / $itemsWeight_lut{$storage{'inventory'}[$i]{'nameID'}});
						$ai_v{'ai_storageAuto_clear'} = 1;
						undef $ai_seq_args[0]{'lastIndex'};
						printc("wn", "<信息> ", "清理: $storage{'inventory'}[$i]{'name'} 重量: $itemsWeight_lut{$storage{'inventory'}[$i]{'nameID'}} 数量: $storage{'inventory'}[$i]{'amount'}\n");
						last;
					}
				}
			}			
			
                        $ai_seq_args[0]{'done'} = 1;
			$i = 0;
			undef $ai_seq_args[0]{'index'};
			while (1) {
				last if (!$config{"getAuto_$i"});
				$ai_seq_args[0]{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"getAuto_$i"});
				if (!$ai_seq_args[0]{'index_failed'}{$i} && $config{"getAuto_$i"."_maxAmount"} ne "" && !$stockVoid{$config{"getAuto_$i"}} && ($ai_seq_args[0]{'invIndex'} eq ""
				|| $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'} < $config{"getAuto_$i"."_maxAmount"})) {
					$ai_seq_args[0]{'index'} = $i;
					last;
				}
				$i++;
			}
			if ($ai_seq_args[0]{'index'} eq ""
				|| ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $ai_seq_args[0]{'index'}
				&& timeOut(\%{$timeout{'ai_storageAuto_giveup'}}))) {
					$ai_seq_args[0]{'done'} = 1;
					sendStorageClose(\$remote_socket);
					last AUTOSTORAGE;
			} elsif ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $ai_seq_args[0]{'index'}) {
				$timeout{'ai_storageAuto_giveup'}{'time'} = time;
			}
			undef $ai_seq_args[0]{'done'};
			undef $ai_seq_args[0]{'storageIndex'};
			$ai_seq_args[0]{'lastIndex'} = $ai_seq_args[0]{'index'}; 
			$ai_seq_args[0]{'storageIndex'} = findIndexString_lc(\@{$storage{'inventory'}}, "name", $config{"getAuto_$ai_seq_args[0]{'index'}"}); 
			if ($ai_seq_args[0]{'storageIndex'} eq "") {
				$stockVoid{$config{"getAuto_$ai_seq_args[0]{'index'}"}} = 1; 
				last AUTOSTORAGE; 
			} elsif ($ai_seq_args[0]{'invIndex'} ne "") { 
				if ($config{"getAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'} > $storage{'inventory'}[$ai_seq_args[0]{'storageIndex'}]{'amount'}) { 
					$ai_seq_args[0]{'amount'} = $storage{$ai_seq_args[0]{'storageIndex'}}{'amount'}; 
					$stockVoid{$config{"getAuto_$ai_seq_args[0]{'index'}"}} = 1;  
				} else { 
					$ai_seq_args[0]{'amount'} = $config{"getAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'}; 
				} 
			} else {
				if ($config{"getAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} > $storage{'inventory'}[$ai_seq_args[0]{'storageIndex'}]{'amount'}) { 
					$ai_seq_args[0]{'amount'} = $storage{'inventory'}[$ai_seq_args[0]{'storageIndex'}]{'amount'}; 
					$stockVoid{$config{"getAuto_$ai_seq_args[0]{'index'}"}} = 1;  
				} else { 
					$ai_seq_args[0]{'amount'} = $config{"getAuto_$ai_seq_args[0]{'index'}"."_maxAmount"}; 
				} 
			} 
			sendStorageGet(\$remote_socket, $ai_seq_args[0]{'storageIndex'}, $ai_seq_args[0]{'amount'}); 
			$timeout{'ai_storageAuto'}{'time'} = time;
                }
        }

        } #END OF BLOCK AUTOSTORAGE



        #####AUTO SELL#####

        AUTOSELL: {

        if (($ai_seq[0] eq "" || $ai_seq[0] eq "route") && $config{'sellAuto'} && $config{'sellAuto_npc'} ne "" && percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'}) {
                $ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
                if ($ai_v{'temp'}{'ai_route_index'} ne "") {
                        $ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
                }
                if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && ai_sellAutoCheck()) {
                        printc(1, "yw", "<系统> ", "开始自动出售\n");
                        unshift @ai_seq, "sellAuto";
                        unshift @ai_seq_args, {};
                        $exp{'base'}{'back'}++;
                }
        }

        if ($ai_seq[0] eq "sellAuto" && $ai_seq_args[0]{'done'}) {
                undef %{$ai_v{'temp'}{'ai'}};
                %{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
                shift @ai_seq;
                shift @ai_seq_args;
                if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'storageAuto'}) {
                        $ai_v{'temp'}{'ai'}{'completedAI'}{'sellAuto'} = 1;
                        unshift @ai_seq, "storageAuto";
                        unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
                }
        } elsif ($ai_seq[0] eq "sellAuto" && timeOut(\%{$timeout{'ai_sellAuto'}})) {
                if (!$config{'sellAuto'} || !%{$npcs_lut{$config{'sellAuto_npc'}}} || !ai_sellAutoCheck()) {
                        $ai_seq_args[0]{'done'} = 1;
                        last AUTOSELL;
                }

                undef $ai_v{'temp'}{'do_route'};
                if ($field{'name'} ne $npcs_lut{$config{'sellAuto_npc'}}{'map'}) {
                        $ai_v{'temp'}{'do_route'} = 1;
                } else {
                        $ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{'sellAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
                        if ($ai_v{'temp'}{'distance'} > 14) {
                                $ai_v{'temp'}{'do_route'} = 1;
                        }
                }
                if ($ai_v{'temp'}{'do_route'}) {
                        if ($ai_seq_args[0]{'warpedToSave'} && $field{'name'} ne $config{'saveMap'}) {
                                undef $ai_seq_args[0]{'warpedToSave'};
                        }
                        $accIndex = findIndexStringsNotSelected_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'accessoryTeleport'});
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 602);
                        if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'} && ($accIndex ne "" || $invIndex ne "" || $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} >= 1)) {
                                $ai_seq_args[0]{'warpedToSave'} = 1;
                                printc(1, "ww", "<瞬移> ", "自动出售\n");
                                useTeleport(2);
                                ai_clientSuspend(0,2);
                        } else {
                                printc(1, "yw", "<系统> ", "正在计算自动出售路线: $maps_lut{$npcs_lut{$config{'sellAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'sellAuto_npc'}}{'map'}): $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'y'}\n");
                                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$config{'sellAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
                        }
                } else {
                        if ($ai_seq_args[0]{'sentSell'} <= 1) {
                                sendTalk(\$remote_socket, pack("L1",$config{'sellAuto_npc'})) if !$ai_seq_args[0]{'sentSell'};
                                sendGetSellList(\$remote_socket, pack("L1",$config{'sellAuto_npc'})) if $ai_seq_args[0]{'sentSell'};
                                $ai_seq_args[0]{'sentSell'}++;
                                $timeout{'ai_sellAuto'}{'time'} = time;
                                last AUTOSELL;
                        }
                        $ai_seq_args[0]{'done'} = 1;
                        for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
                                next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'});
                                if ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'sell'}
                                        && $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}) {
                                        if ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $chars[$config{'char'}]{'inventory'}[$i]{'index'}
                                                && timeOut(\%{$timeout{'ai_sellAuto_giveup'}})) {
                                                last AUTOSELL;
                                        } elsif ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $chars[$config{'char'}]{'inventory'}[$i]{'index'}) {
                                                $timeout{'ai_sellAuto_giveup'}{'time'} = time;
                                        }
                                        undef $ai_seq_args[0]{'done'};
                                        $ai_seq_args[0]{'lastIndex'} = $chars[$config{'char'}]{'inventory'}[$i]{'index'};
                                        sendSell(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$i]{'index'}, $chars[$config{'char'}]{'inventory'}[$i]{'amount'} - $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'});
                                        $timeout{'ai_sellAuto'}{'time'} = time;
                                        last AUTOSELL;
                                }
                        }
                        if ($config{'cartAuto'} && $config{'cartAutoSell'} && $cart{'items'} > 0) {
                                $ai_seq_args[0]{'done'} = 1;
                                for ($i = 0; $i < @{$cart{'inventory'}};$i++) {
                                        next if (!%{$cart{'inventory'}[$i]} || !$items_control{lc($cart{'inventory'}[$i]{'name'})}{'sell'});
                                        next if ($items_control{lc($cart{'inventory'}[$i]{'name'})}{'keepCart'} && $cart{'inventory'}[$i]{'amount'} <= $items_control{lc($cart{'inventory'}[$i]{'name'})}{'keepCart'});
                                        if ($items_control{lc($cart{'inventory'}[$i]{'name'})}{'keepCart'}) {
                                                $ai_v{'temp'}{'getAmount'} = $cart{'inventory'}[$i]{'amount'} - $items_control{lc($cart{'inventory'}[$i]{'name'})}{'keepCart'};
                                        } else {
                                                $ai_v{'temp'}{'getAmount'} = $cart{'inventory'}[$i]{'amount'};
                                        }
                                        if ($ai_v{'temp'}{'getAmount'} > int(($chars[$config{'char'}]{'weight_max'} - $chars[$config{'char'}]{'weight'}) / $config{'cartAutoItemMaxWeight'})) {

                                                sendCartGet(\$remote_socket, $i, int(($chars[$config{'char'}]{'weight_max'} - $chars[$config{'char'}]{'weight'}) / $config{'cartAutoItemMaxWeight'}));
                                        } else {
                                                sendCartGet(\$remote_socket, $i, $ai_v{'temp'}{'getAmount'});
                                        }
                                        undef $ai_seq_args[0]{'done'};
                                        $timeout{'ai_sellAuto'}{'time'} = time;
                                        last AUTOSELL;
                                }
                        }
                }
        }

        } #END OF BLOCK AUTOSELL



        #####AUTO BUY#####

        AUTOBUY: {

        if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "attack") && timeOut(\%{$timeout{'ai_buyAuto'}}) && $ai_v{'temp'}{'inventory_received'}) {
                undef $ai_v{'temp'}{'found'};
                undef $ai_v{'temp'}{'index'};
                undef $ai_v{'temp'}{'cartIndex'};
                undef $ai_v{'temp'}{'invIndex'};
                undef $ai_v{'temp'}{'invAmount'};
                $i = 0;
                while (1) {
                        last if (!$config{"buyAuto_$i"} || !$config{"buyAuto_$i"."_npc"});
                        $ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"buyAuto_$i"});
                        if (ai_checkItemState($config{"buyAuto_$i"}) && $config{"buyAuto_$i"."_minAmount"} >= 0 && $config{"buyAuto_$i"."_maxAmount"} ne ""
                                && ($ai_v{'temp'}{'invIndex'} eq "" || ($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} <= $config{"buyAuto_$i"."_minAmount"}
                                && $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $config{"buyAuto_$i"."_maxAmount"}))) {
                                $ai_v{'temp'}{'found'} = 1;
                                $ai_v{'temp'}{'index'} = $i;
                                $ai_v{'temp'}{'invAmount'} = $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} if ($ai_v{'temp'}{'invIndex'} ne "");
                        }
                        $i++;
                }
                $ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
                if ($ai_v{'temp'}{'ai_route_index'} ne "") {
                        $ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
                }
                if ($ai_v{'temp'}{'found'}) {
                        $ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $config{"buyAuto_".$ai_v{'temp'}{'index'}}) if ($config{'cartAuto'} && $cart{'weight_max'} > 0);
                        if ($ai_v{'temp'}{'cartIndex'} ne "" && !$shop_control{'shopAuto_open'}) {
                                if ($config{"buyAuto_".$ai_v{'temp'}{'index'}."_maxAmount"} - $ai_v{'temp'}{'invAmount'} > $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'}) {
                                        sendCartGet(\$remote_socket, $ai_v{'temp'}{'cartIndex'}, $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'});
                                } else {
                                        sendCartGet(\$remote_socket, $ai_v{'temp'}{'cartIndex'}, $config{"buyAuto_".$ai_v{'temp'}{'index'}."_maxAmount"} - $ai_v{'temp'}{'invAmount'});
                                }
                        } elsif (!$chars[$config{'char'}]{'mvp'} && !($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && $ai_v{'temp'}{'found'}) {
                                printc(1, "yw", "<系统> ", "开始自动购买\n");
                                unshift @ai_seq, "sellAuto";
                                unshift @ai_seq_args, {};
                                $exp{'base'}{'back'}++;
                        }
                }
                $timeout{'ai_buyAuto'}{'time'} = time;
        }

        if ($ai_seq[0] eq "buyAuto" && $ai_seq_args[0]{'done'}) {
                undef %{$ai_v{'temp'}{'ai'}};
                %{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
                shift @ai_seq;
                shift @ai_seq_args;
                if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'sellAuto'}) {
                        $ai_v{'temp'}{'ai'}{'completedAI'}{'buyAuto'} = 1;
                        unshift @ai_seq, "sellAuto";
                        unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
                }
        } elsif ($ai_seq[0] eq "buyAuto" && timeOut(\%{$timeout{'ai_buyAuto_wait'}}) && timeOut(\%{$timeout{'ai_buyAuto_wait_buy'}})) {
                $i = 0;
                undef $ai_seq_args[0]{'index'};

                while (1) {
                        last if (!$config{"buyAuto_$i"} || !%{$npcs_lut{$config{"buyAuto_$i"."_npc"}}});
                        $ai_seq_args[0]{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"buyAuto_$i"});
                        if (!$ai_seq_args[0]{'index_failed'}{$i} && $config{"buyAuto_$i"."_maxAmount"} ne "" && ($ai_seq_args[0]{'invIndex'} eq ""
                                || $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'} < $config{"buyAuto_$i"."_maxAmount"})) {
                                $ai_seq_args[0]{'index'} = $i;
                                last;
                        }
                        $i++;
                }
                if ($ai_seq_args[0]{'index'} eq ""
                        || ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $ai_seq_args[0]{'index'}
                        && timeOut(\%{$timeout{'ai_buyAuto_giveup'}}))) {
                        $ai_seq_args[0]{'done'} = 1;
                        last AUTOBUY;
                }
                undef $ai_v{'temp'}{'do_route'};
                if ($field{'name'} ne $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}) {
                        $ai_v{'temp'}{'do_route'} = 1;
                } else {
                        $ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
                        if ($ai_v{'temp'}{'distance'} > 14) {
                                $ai_v{'temp'}{'do_route'} = 1;
                        }
                }
                if ($ai_v{'temp'}{'do_route'}) {
                        if ($ai_seq_args[0]{'warpedToSave'} && $field{'name'} ne $config{'saveMap'}) {
                                undef $ai_seq_args[0]{'warpedToSave'};
                        }
                        $accIndex = findIndexStringsNotSelected_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'accessoryTeleport'});
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 602);
                        if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'} && ($accIndex ne "" || $invIndex ne "" || $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} >= 1)) {
                                $ai_seq_args[0]{'warpedToSave'} = 1;
                                printc(1, "ww", "<瞬移> ", "自动购买\n");
                                useTeleport(2);
                                ai_clientSuspend(0,2);
                        } else {
                                printc(1, "yw", "<系统> ", qq~正在计算自动购买路线: $maps_lut{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}.'.rsw'}($npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}): $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'x'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'y'}\n~);
                                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'x'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'y'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}, 0, 0, 1, 0, 0, 1);
                        }
                } else {
                        if ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $ai_seq_args[0]{'index'}) {
                                undef $ai_seq_args[0]{'itemID'};
                                if ($config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"} != $config{"buyAuto_$ai_seq_args[0]{'lastIndex'}"."_npc"}) {
                                        undef $ai_seq_args[0]{'sentBuy'};
                                }
                                $timeout{'ai_buyAuto_giveup'}{'time'} = time;
                        }
                        $ai_seq_args[0]{'lastIndex'} = $ai_seq_args[0]{'index'};
                        if ($ai_seq_args[0]{'itemID'} eq "") {
                                foreach (keys %items_lut) {
                                        if (lc($items_lut{$_}) eq lc($config{"buyAuto_$ai_seq_args[0]{'index'}"})) {
                                                $ai_seq_args[0]{'itemID'} = $_;
                                        }
                                }
                                if ($ai_seq_args[0]{'itemID'} eq "") {
                                        $ai_seq_args[0]{'index_failed'}{$ai_seq_args[0]{'index'}} = 1;
                                        print "autoBuy index $ai_seq_args[0]{'index'} failed\n" if $config{'debug'};
                                        last AUTOBUY;
                                }
                        }

                        if ($ai_seq_args[0]{'sentBuy'} <= 1) {
                                sendTalk(\$remote_socket, pack("L1",$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"})) if !$ai_seq_args[0]{'sentBuy'};
                                sendGetStoreList(\$remote_socket, pack("L1",$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"})) if $ai_seq_args[0]{'sentBuy'};
                                $ai_seq_args[0]{'sentBuy'}++;
                                $timeout{'ai_buyAuto_wait'}{'time'} = time;
                                last AUTOBUY;
                        }
                        if ($ai_seq_args[0]{'invIndex'} ne "") {
                                sendBuy(\$remote_socket, $ai_seq_args[0]{'itemID'}, $config{"buyAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'});
                        } else {
                                sendBuy(\$remote_socket, $ai_seq_args[0]{'itemID'}, $config{"buyAuto_$ai_seq_args[0]{'index'}"."_maxAmount"});
                        }
                        $timeout{'ai_buyAuto_wait_buy'}{'time'} = time;
                }
        }

        } #END OF BLOCK AUTOBUY



        #####AUTO REFINE#####

        AUTOREFINE: {

        if ($ai_seq[0] eq "refineAuto" && $ai_seq_args[0]{'done'}) {
                printc(1, "yw", "<系统> ", "自动精练结束 $ai_seq_args[0]{'name'} 成功$ai_seq_args[0]{'succeed'} 失败$ai_seq_args[0]{'failed'}\n");
                chatLog("i", "自动精练结束 $ai_seq_args[0]{'name'} 成功$ai_seq_args[0]{'succeed'} 失败$ai_seq_args[0]{'failed'}\n");
                shift @ai_seq;
                shift @ai_seq_args;
                undef %refine_control;
        } elsif ($ai_seq[0] eq "refineAuto" && $ai_seq_args[0]{'retry'}) {
                undef $ai_seq_args[0]{'retry'};
                undef $ai_seq_args[0]{'refineReady'};
                undef $ai_seq_args[0]{'unequipReady'};
                undef $ai_seq_args[0]{'invIndex'};
                undef $ai_seq_args[0]{'lastInvIndex'};
                undef $ai_seq_args[0]{'solution'};
                undef $ai_seq_args[0]{'npc'}{'sentTalk'};
        } elsif ($ai_seq[0] eq "refineAuto" && !$ai_seq_args[0]{'refineReady'} && timeOut(\%{$timeout{'ai_refineAuto'}})) {
                if (!%{$npcs_lut{$refine_control{'refineAuto_npc'}}}) {
                        $ai_seq_args[0]{'done'} = 1;
                        last AUTOREFINE;
                } elsif (!$ai_seq_args[0]{'unequipReady'}) {
                        for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
                                if ($chars[$config{'char'}]{'inventory'}[$i]{'equipped'}) {
                                        sendUnequip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$i]{'index'});
                                        $timeout{'ai_refineAuto'}{'time'} = time;
                                        last AUTOREFINE;
                                }
                        }
                        printc("wg", "<信息> ", "全部装备卸下完成\n");
                        $ai_seq_args[0]{'unequipReady'} = 1;
                }
                undef $ai_v{'temp'}{'do_route'};
                if ($field{'name'} ne $npcs_lut{$refine_control{'refineAuto_npc'}}{'map'}) {
                        $ai_v{'temp'}{'do_route'} = 1;
                } else {
                        $ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$refine_control{'refineAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
                        if ($ai_v{'temp'}{'distance'} > 14) {
                                $ai_v{'temp'}{'do_route'} = 1;
                        }
                }
                if ($ai_v{'temp'}{'do_route'}) {
                        if ($ai_seq_args[0]{'warpedToSave'} && $field{'name'} ne $config{'saveMap'}) {
                                undef $ai_seq_args[0]{'warpedToSave'};
                        }
                        $accIndex = findIndexStringsNotSelected_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'accessoryTeleport'});
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 602);
                        if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'} && ($accIndex ne "" || $invIndex ne "" || $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} >= 1)) {
                                $ai_seq_args[0]{'warpedToSave'} = 1;
                                useTeleport(2);
                                ai_clientSuspend(0,2);
                        } else {
                                printc(1, "yw", "<系统> ", "正在计算自动精练路线: $maps_lut{$npcs_lut{$refine_control{'refineAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$refine_control{'refineAuto_npc'}}{'map'}): $npcs_lut{$refine_control{'refineAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$refine_control{'refineAuto_npc'}}{'pos'}{'y'}\n");
                                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$refine_control{'refineAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$refine_control{'refineAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$refine_control{'refineAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
                        }
                } else {
                        $ai_seq_args[0]{'lastInvIndex'} = $ai_seq_args[0]{'invIndex'};
                        undef $ai_seq_args[0]{'invIndex'};
                        my $j = 0;
                        while($refine_control{"refineAuto_$j"}) {
                                for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
                                        if (($ai_seq_args[0]{'name'} eq "all" || $ai_seq_args[0]{'name'} eq $items_lut{$chars[$config{'char'}]{'inventory'}[$i]{'nameID'}})
                                                && $chars[$config{'char'}]{'inventory'}[$i]{'refined'} < $ai_seq_args[0]{'refined'}
                                                && !$chars[$config{'char'}]{'inventory'}[$i]{'card'}[0]
                                                && existsInList($refine_control{"refineAuto_$j"}, $items_lut{$chars[$config{'char'}]{'inventory'}[$i]{'nameID'}})) {
                                                $ai_seq_args[0]{'invIndex'} = $i;
                                                $ai_seq_args[0]{'solution'} = $j;
                                                last;
                                        }
                                }
                                last if ($ai_seq_args[0]{'invIndex'} ne "");
                                $j++;
                        }
                        if ($ai_seq_args[0]{'invIndex'} eq "") {
                                printc(1, "wr", "<信息> ", "没有发现可精练装备\n");
                                $ai_seq_args[0]{'done'} = 1;
                        } elsif ($ai_seq_args[0]{'lastInvIndex'} ne "" && $ai_seq_args[0]{'lastInvIndex'} ne $ai_seq_args[0]{'invIndex'}) {
                                $ai_seq_args[0]{'retry'} = 1;
                        } else {
                                printc(1, "yw", "<系统> ", "开始精练 $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'name'}($ai_seq_args[0]{'invIndex'})\n");
                                $ai_seq_args[0]{'refineReady'} = 1;
                                sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'index'}, $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'type_equip'});
                                $timeout{'ai_refineAuto'}{'time'} = time;
                                last AUTOREFINE;
                        }
                }
        } elsif ($ai_seq[0] eq "refineAuto" && timeOut(\%{$timeout{'ai_refineAuto'}})) {
                if ($ai_seq_args[0]{'npc'}{'sentTalk'} && $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] eq "") {
                        if (!%{$chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]}) {
                                printc("wr", "<信息> ", "精练失败\n");
                                $ai_seq_args[0]{'failed'}++;
                                $ai_seq_args[0]{'retry'} = 1;
                        } elsif ($chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'refined'} >= $ai_seq_args[0]{'refined'}) {
                                printc("wc", "<信息> ", "精练完成 $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'name'}($ai_seq_args[0]{'invIndex'})\n");
                                $ai_seq_args[0]{'succeed'}++;
                                $ai_seq_args[0]{'retry'} = 1;
                        } elsif ($chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'refined'} > $ai_seq_args[0]{'last_refined'}) {
                                printc("wg", "<信息> ", "精练成功 $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'name'}($ai_seq_args[0]{'invIndex'})\n");
                                undef $ai_seq_args[0]{'npc'}{'sentTalk'};
                        } elsif (timeOut(\%{$timeout{'ai_refineAuto_giveup'}})) {
                                printc("wr", "<信息> ", "精练超时\n");
                                $ai_seq_args[0]{'retry'} = 1;
                        }
                } elsif (timeOut(\%{$timeout{'ai_refineAuto_talk'}})) {
                        if (!$ai_seq_args[0]{'npc'}{'sentTalk'}) {
                                sendTalk(\$remote_socket, pack("L1",$refine_control{'refineAuto_npc'}));
                                undef $ai_seq_args[0]{'npc'}{'step'};
                                @{$ai_seq_args[0]{'npc'}{'steps'}} = split(/ /, $refine_control{"refineAuto_"."$ai_seq_args[0]{'solution'}"."_steps_"."$chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'refined'}"});
                                $ai_seq_args[0]{'npc'}{'sentTalk'} = 1;
                                $ai_seq_args[0]{'last_refined'} = $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'refined'};
                        } elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /c/i) {
                                sendTalkContinue(\$remote_socket, pack("L1",$refine_control{'refineAuto_npc'}));
                                $ai_seq_args[0]{'npc'}{'step'}++;
                        } elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /n/i) {
                                sendTalkCancel(\$remote_socket, pack("L1",$refine_control{'refineAuto_npc'}));
                                $ai_seq_args[0]{'npc'}{'step'}++;
                        } else {
                                ($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i;
                                if ($ai_v{'temp'}{'arg'} ne "") {
                                        $ai_v{'temp'}{'arg'}++;
                                        sendTalkResponse(\$remote_socket, pack("L1",$refine_control{'refineAuto_npc'}), $ai_v{'temp'}{'arg'});
                                }
                                $ai_seq_args[0]{'npc'}{'step'}++;
                        }
                        $timeout{'ai_refineAuto_talk'}{'time'} = time;
                        $timeout{'ai_refineAuto_giveup'}{'time'} = time;
                }
        }

        } #END OF BLOCK AUTOREFINE



        ##### DEAD #####


        if ($ai_seq[0] eq "dead" && !$chars[$config{'char'}]{'dead'}) {
                shift @ai_seq;
                shift @ai_seq_args;
                #force storage after death
                unshift @ai_seq, "healAuto";
                unshift @ai_seq_args, {};
        } elsif ($ai_seq[0] ne "dead" && $chars[$config{'char'}]{'dead'}) {
                undef @ai_seq;
                undef @ai_seq_args;
                unshift @ai_seq, "dead";
                unshift @ai_seq_args, {};
        }

        if ($ai_seq[0] eq "dead" && time - $chars[$config{'char'}]{'dead_time'} >= $timeout{'ai_dead_respawn'}{'timeout'}) {
                sendRespawn(\$remote_socket);
                $chars[$config{'char'}]{'dead_time'} = time;
        }

        if ($ai_seq[0] eq "dead" && $config{'dcOnDeath'}) {
                printc("yr", "<系统> ", "人物死亡，退出游戏！\n");
                $quit = 1;
        }

                
        
        ##### AUTO-ITEM USE #####

        ($ai_v{'map_name_lu'}) = $map_name =~ /([\s\S]*)\./;
        $ai_v{'map_name_lu'} .= ".rsw";

        if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute" || $ai_seq[0] eq "items_important"
                || $ai_seq[0] eq "follow" || $ai_seq[0] eq "sitAuto" || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather"
                || $ai_seq[0] eq "items_take" || $ai_seq[0] eq "attack" || $ai_seq[0] eq "skill_use")
                && (binFind(\@ai_seq, "healAuto") eq "" || (binFind(\@ai_seq, "healAuto") ne "" && !$cities_lut{$ai_v{'map_name_lu'}})) && timeOut(\%{$timeout{'ai_item_use_auto'}})) {
                $i = 0;
                while (1) {
                        last if (!$config{"useSelf_item_$i"});
                        if (percent_hp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_item_$i"."_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_item_$i"."_hp_lower"}
                                && percent_sp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_item_$i"."_sp_upper"} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_item_$i"."_sp_lower"}
                                && timeOut($config{"useSelf_item_$i"."_timeout"}, $ai_v{"useSelf_item_$i"."_time"})
                                && (!$config{"useSelf_item_$i"."_monsters"} || ($ai_seq[0] eq "attack" && existsInList($config{"useSelf_item_$i"."_monsters"}, $monsters{$ai_seq_args[0]{'ID'}}{'name'})))
                                && (!$config{"useSelf_item_$i"."_dist"} || ($ai_seq[0] eq "attack" && distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}}) <= $config{"useSelf_item_$i"."_dist"}))
                                && (!$config{"useSelf_item_$i"."_lockMapOnly"} || ($config{"useSelf_item_$i"."_lockMapOnly"} && $field{'name'} eq $config{'lockMap'}))
                                && (!$config{"useSelf_item_$i"."_stopWhenSit"} || ($config{"useSelf_item_$i"."_stopWhenSit"} && binFind(\@ai_seq, "sitAuto") eq ""))
                                && !($config{"useSelf_item_$i"."_stopWhenHit"} && ai_getMonstersWhoHitMe())
                                && (!$config{"useSelf_item_$i"."_inState"} || ($config{"useSelf_item_$i"."_inState"} ne "" && ai_stateCheck($chars[$config{'char'}], $config{"useSelf_item_$i"."_inState"})))
                                && (!$config{"useSelf_item_$i"."_noState"} || ($config{"useSelf_item_$i"."_noState"} ne "" && !ai_stateCheck($chars[$config{'char'}], $config{"useSelf_item_$i"."_noState"})))
                                && $config{"useSelf_item_$i"."_minAggressives"} <= ai_getAggressives()
                                && (!$config{"useSelf_item_$i"."_maxAggressives"} || $config{"useSelf_item_$i"."_maxAggressives"} > ai_getAggressives())) {
                                undef $ai_v{'temp'}{'invIndex'};
                                undef $ai_v{'temp'}{'count'};
                                $ai_v{'temp'}{'invIndex'} = findIndexMultiString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"useSelf_item_$i"});
                                if ($ai_v{'temp'}{'invIndex'} ne "") {
                                        $ai_v{"useSelf_item_$i"."_time"} = time;
                                        $ai_v{'temp'}{'count'} = ($config{"useSelf_item_$i"."_repeat"}) ? $config{"useSelf_item_$i"."_repeat"} : 1;
                                        for ($i = 0; $i < $ai_v{'temp'}{'count'}; $i++) {
                                        	sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $accountID);
                                        }
                                        print qq~Auto-item use: $items_lut{$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'nameID'}}\n~ if $config{'debug'};
                                        last;
                                }
                        }
                        $i++;
                }
                $timeout{'ai_item_use_auto'}{'time'} = time;
        }



        ##### PARTY-RESURRECT #####

        if ($chars[$config{'char'}]{'party'}{'name'} ne "" && $config{'partyAutoResurrect'} > 0
                && ($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute"
                || $ai_seq[0] eq "follow" || $ai_seq[0] eq "sitAuto" || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather"
                || $ai_seq[0] eq "items_take" || $ai_seq[0] eq "attack")
                && timeOut(\%{$timeout{'ai_resurrect'}})) {
                undef $ai_v{'temp'}{'distSmall'};
                undef $ai_v{'temp'}{'foundID'};
                undef $ai_v{'temp'}{'distance'};
                for ($i = 0; $i < @partyUsersID; $i++) {
                        next if ($partyUsersID[$i] eq "" || !%{$players{$partyUsersID[$i]}} || !$players{$partyUsersID[$i]}{'dead'});
                        $ai_v{'temp'}{'distance'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$partyUsersID[$i]}{'pos_to'}});
                        next if ($ai_v{'temp'}{'distance'} > $config{'partyAutoResurrect'});
                        if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'distance'} < $ai_v{'temp'}{'distSmall'}) {
                                $ai_v{'temp'}{'distSmall'} = $ai_v{'temp'}{'distance'};
                                $ai_v{'temp'}{'foundID'} = $partyUsersID[$i];
                                undef $ai_v{'temp'}{'first'};
                        }
                }
                if ($ai_v{'temp'}{'foundID'}) {
                        if ($chars[$config{'char'}]{'skills'}{'ALL_RESURRECTION'}{'lv'} > 0) {
                                ai_skillUse($chars[$config{'char'}]{'skills'}{'ALL_RESURRECTION'}{'ID'}, $chars[$config{'char'}]{'skills'}{'ALL_RESURRECTION'}{'lv'}, 0, 0, $ai_v{'temp'}{'foundID'});
                        } else {
                                my $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 610);
                                if ($invIndex ne "") {
                                        $resurrectID = $ai_v{'temp'}{'foundID'};
                                        sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}, $ai_v{'temp'}{'foundID'});
                                }
                        }
                }
                $timeout{'ai_resurrect'}{'time'} = time;
        }



        ##### AUTO-SKILL USE #####


        if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute" || $ai_seq[0] eq "items_important"
                || $ai_seq[0] eq "follow" || $ai_seq[0] eq "sitAuto" || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather"
                || $ai_seq[0] eq "items_take" || ($ai_seq[0] eq "attack" && %{$monsters{$ai_seq_args[0]{'ID'}}}))
                && timeOut(\%{$timeout{'ai_skill_use'}})) {
                $i = 0;
                undef $ai_v{'useSelf_skill'};
                undef $ai_v{'useSelf_skill_lvl'};
                while (1) {
                        last if (!$config{"useSelf_skill_$i"});
                        if ($config{"useSelf_skill_$i"."_lvl"} > 0
                                && percent_hp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_skill_$i"."_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_skill_$i"."_hp_lower"}
                                && percent_sp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_skill_$i"."_sp_upper"} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_skill_$i"."_sp_lower"}
                                && $chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc($config{"useSelf_skill_$i"})}}{$config{"useSelf_skill_$i"."_lvl"}}
                                && !($config{"useSelf_skill_$i"."_stopWhenHit"} && ai_getMonstersWhoHitMe())
                                && $config{"useSelf_skill_$i"."_minAggressives"} <= ai_getAggressives()
                                && (!$config{"useSelf_skill_$i"."_maxAggressives"} || $config{"useSelf_skill_$i"."_maxAggressives"} > ai_getAggressives())
                                && $config{"useSelf_skill_$i"."_minSpirits"} <= $chars[$config{'char'}]{'spirits'}
                                && (!$config{"useSelf_skill_$i"."_maxSpirits"} || $config{"useSelf_skill_$i"."_maxSpirits"} > $chars[$config{'char'}]{'spirits'})
                                && (!$config{"useSelf_skill_$i"."_inState"} || ($config{"useSelf_skill_$i"."_inState"} ne "" && ai_stateCheck($chars[$config{'char'}], $config{"useSelf_skill_$i"."_inState"})))
                                && (!$config{"useSelf_skill_$i"."_noState"} || ($config{"useSelf_skill_$i"."_noState"} ne "" && !ai_stateCheck($chars[$config{'char'}], $config{"useSelf_skill_$i"."_noState"})))
                                && (!$config{"useSelf_skill_$i"."_stopWhenSit"} || ($config{"useSelf_skill_$i"."_stopWhenSit"} && binFind(\@ai_seq, "sitAuto") eq ""))
                                && (!$config{"useSelf_skill_$i"."_lockMapOnly"} || ($config{"useSelf_skill_$i"."_lockMapOnly"} && $field{'name'} eq $config{'lockMap'}))
                                && timeOut($config{"useSelf_skill_$i"."_timeout"}, $ai_v{"useSelf_skill_$i"."_time"})
                                && (!$config{"useSelf_skill_$i"."_dist"} || ($ai_seq[0] eq "attack" && distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}}) <= $config{"useSelf_skill_$i"."_dist"}))
                                && (!$config{"useSelf_skill_$i"."_monsters"} || ($config{"useSelf_skill_$i"."_monsters"} ne "" && $ai_seq[0] eq "attack" && existsInList($config{"useSelf_skill_$i"."_monsters"}, $monsters{$ai_seq_args[0]{'ID'}}{'name'})))) {

       	                        $ai_v{'useSelf_skill'} = $config{"useSelf_skill_$i"};
                        	$ai_v{'useSelf_skill_ID'} = ai_getSkillUseID($config{"useSelf_skill_$i"});
               	                $ai_v{'useSelf_skill_lvl'} = $config{"useSelf_skill_$i"."_lvl"};
                       	        $ai_v{'useSelf_skill_maxCastTime'} = $config{"useSelf_skill_$i"."_maxCastTime"};
                               	$ai_v{'useSelf_skill_minCastTime'} = $config{"useSelf_skill_$i"."_minCastTime"};
                                $ai_v{'useSelf_skill_smartHeal'} = $config{"useSelf_skill_$i"."_smartHeal"};
       	                        $ai_v{"useSelf_skill_$i"."_time"} = time;
       	                        last;
                        }
                        $i++;
                }

                if ($ai_v{'useSelf_skill'}) {
			if ($ai_v{'useSelf_skill_smartHeal'} && $skills_rlut{lc($ai_v{'useSelf_skill'})} eq "AL_HEAL") {
				undef $ai_v{'temp'}{'smartHeal_lvl'};
				$ai_v{'temp'}{'smartHeal_hp_dif'} = $chars[$config{'char'}]{'hp_max'} - $chars[$config{'char'}]{'hp'};
				$ai_v{'temp'}{'smartHeal_lvl_upper'} = ($chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'}) ? $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'} : $ai_v{'useSelf_skill_lvl'};
				for ($i = 1; $i <= $ai_v{'temp'}{'smartHeal_lvl_upper'}; $i++) {
					$ai_v{'temp'}{'smartHeal_lvl'} = $i;
					$ai_v{'temp'}{'smartHeal_sp'} = 10 + ($i * 3);
					$ai_v{'temp'}{'smartHeal_amount'} = int(($chars[$config{'char'}]{'lv'} + $chars[$config{'char'}]{'int'}) / 8)
							* (4 + $i * 8);
					if ($chars[$config{'char'}]{'sp'} < $ai_v{'temp'}{'smartHeal_sp'}) {
						$ai_v{'temp'}{'smartHeal_lvl'}--;
						last;
					}
					last if ($ai_v{'temp'}{'smartHeal_amount'} >= $ai_v{'temp'}{'smartHeal_hp_dif'});
				}
				$ai_v{'useSelf_skill_lvl'} = $ai_v{'temp'}{'smartHeal_lvl'};
			}
	                if ($ai_v{'useSelf_skill_lvl'} > 0) {
        	                print qq~Auto-skill on self: $skills_lut{$skills_rlut{lc($ai_v{'useSelf_skill'})}} (lvl $ai_v{'useSelf_skill_lvl'})\n~ if $config{'debug'};
                	        if (!ai_getSkillUseType($skills_rlut{lc($ai_v{'useSelf_skill'})})) {
                        	        ai_skillUse($ai_v{'useSelf_skill_ID'}, $ai_v{'useSelf_skill_lvl'}, $ai_v{'useSelf_skill_maxCastTime'}, $ai_v{'useSelf_skill_minCastTime'}, $accountID);
	                        } else {
        	                        ai_skillUse($ai_v{'useSelf_skill_ID'}, $ai_v{'useSelf_skill_lvl'}, $ai_v{'useSelf_skill_maxCastTime'}, $ai_v{'useSelf_skill_minCastTime'}, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
                	        }
		        }
                }
      		$timeout{'ai_skill_use'}{'time'} = time;
        }



        ##### PARTY-SKILL #####

        if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute"
                || $ai_seq[0] eq "follow" || $ai_seq[0] eq "sitAuto" || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather"
                || $ai_seq[0] eq "items_take" || ($ai_seq[0] eq "attack" && %{$monsters{$ai_seq_args[0]{'ID'}}}))
                && timeOut(\%{$timeout{'ai_skill_party'}})) {
                undef $ai_v{'useParty_skill'};
                undef $ai_v{'useParty_skill_lvl'};
                undef $ai_v{'temp'}{'distSmall'};
                undef $ai_v{'temp'}{'foundID'};
                $i = 0;
                while (1) {
                        last if (!$config{"useParty_skill_$i"});
 	                for ($j = 0; $j < @partyUsersID; $j++) {
	                        next if ($partyUsersID[$j] eq "" || !%{$players{$partyUsersID[$j]}} || $players{$partyUsersID[$j]}{'dead'} || !$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$j]}{'hp_max'});
                	        $ai_v{'temp'}{'distance'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$partyUsersID[$j]}{'pos_to'}});
                                if ($config{"useParty_skill_$i"."_lvl"} > 0
                                        && percent_hp(\%{$chars[$config{'char'}]}) <= $config{"useParty_skill_$i"."_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{"useParty_skill_$i"."_hp_lower"}
                                        && percent_sp(\%{$chars[$config{'char'}]}) <= $config{"useParty_skill_$i"."_sp_upper"} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{"useParty_skill_$i"."_sp_lower"}
                                        && $chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc($config{"useParty_skill_$i"})}}{$config{"useParty_skill_$i"."_lvl"}}
                                        && $ai_v{'temp'}{'distance'} <= $config{"useParty_skill_$i"."_dist"}
                                        && (!$config{"useParty_skill_$i"."_players"} || existsInList($config{"useParty_skill_$i"."_players"}, $players{$partyUsersID[$j]}{'name'}))
                                        && percent_hp(\%{$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$j]}}) <= $config{"useParty_skill_$i"."_player_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$j]}}) >= $config{"useParty_skill_$i"."_player_hp_lower"}
                                        && $config{"useParty_skill_$i"."_minAggressives"} <= ai_getAggressives()
                                        && (!$config{"useParty_skill_$i"."_maxAggressives"} || $config{"useParty_skill_$i"."_maxAggressives"} > ai_getAggressives())
                                        && !($config{"useParty_skill_$i"."_stopWhenHit"} && ai_getMonstersWhoHitMe())
                                        && (!$config{"useParty_skill_$i"."_stopWhenSit"} || ($config{"useParty_skill_$i"."_stopWhenSit"} && binFind(\@ai_seq, "sitAuto") eq ""))
                                        && (!$config{"useParty_skill_$i"."_lockMapOnly"} || ($config{"useParty_skill_$i"."_lockMapOnly"} && $field{'name'} eq $config{'lockMap'}))
                                        && (!$config{"useParty_skill_$i"."_jobs"} || existsInList($config{"useParty_skill_$i"."_jobs"}, $jobs_lut{$players{$partyUsersID[$j]}{'jobID'}}))
                                        && (!$config{"useParty_skill_$i"."_inState"} || ($config{"useParty_skill_$i"."_inState"} ne "" && ai_stateCheck($players{$partyUsersID[$j]}, $config{"useParty_skill_$i"."_inState"})))
                                        && (!$config{"useParty_skill_$i"."_noState"} || ($config{"useParty_skill_$i"."_noState"} ne "" && !ai_stateCheck($players{$partyUsersID[$j]}, $config{"useParty_skill_$i"."_noState"})))
                                        && timeOut($config{"useParty_skill_$i"."_timeout"}, $ai_v{"useParty_skill_$i"."_time"}{$partyUsersID[$j]})) {

                                        $ai_v{'useParty_skill'} = $config{"useParty_skill_$i"};
					$ai_v{'useParty_skill_ID'} = ai_getSkillUseID($config{"useParty_skill_$i"});
       	                                $ai_v{'useParty_skill_lvl'} = $config{"useParty_skill_$i"."_lvl"};
               	                        $ai_v{'useParty_skill_maxCastTime'} = $config{"useParty_skill_$i"."_maxCastTime"};
                       	                $ai_v{'useParty_skill_minCastTime'} = $config{"useParty_skill_$i"."_minCastTime"};
                               	        $ai_v{'useParty_skill_smartHeal'} = $config{"useParty_skill_$i"."_smartHeal"};
                                       	$ai_v{"useParty_skill_$i"."_time"}{$partyUsersID[$j]} = time;
                                        if ($config{"useParty_skill_$i"."_useSelf"}) {
       	                                        $ai_v{'useParty_skill_targetID'} = $accountID;
               	                        } else {
                       	                        $ai_v{'useParty_skill_targetID'} = $partyUsersID[$j];
                               	        }
                                       	last;
				}
	                        last if ($ai_v{'useParty_skill'});
                        }
                        last if ($ai_v{'useParty_skill'});
       	                $i++;
                }
                if ($ai_v{'useParty_skill'}) {
                        if ($ai_v{'useParty_skill_smartHeal'} && $skills_rlut{lc($ai_v{'useParty_skill'})} eq "AL_HEAL") {
                                undef $ai_v{'temp'}{'smartHeal_lvl'};
                                $ai_v{'temp'}{'smartHeal_hp_dif'} = $chars[$config{'char'}]{'party'}{'users'}{$ai_v{'useParty_skill_targetID'}}{'hp_max'} - $chars[$config{'char'}]{'party'}{'users'}{$ai_v{'useParty_skill_targetID'}}{'hp'};
				$ai_v{'temp'}{'smartHeal_lvl_upper'} = ($chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'}) ? $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'} : $ai_v{'useParty_skill_lvl'};                                
                                for ($i = 1; $i <= $ai_v{'temp'}{'smartHeal_lvl_upper'}; $i++) {
                                        $ai_v{'temp'}{'smartHeal_lvl'} = $i;
                                        $ai_v{'temp'}{'smartHeal_sp'} = 10 + ($i * 3);
                                        $ai_v{'temp'}{'smartHeal_amount'} = int(($chars[$config{'char'}]{'lv'} + $chars[$config{'char'}]{'int'}) / 8)
                                                        * (4 + $i * 8);
                                        if ($chars[$config{'char'}]{'sp'} < $ai_v{'temp'}{'smartHeal_sp'}) {
                                                $ai_v{'temp'}{'smartHeal_lvl'}--;
                                                last;
                                        }
                                        last if ($ai_v{'temp'}{'smartHeal_amount'} >= $ai_v{'temp'}{'smartHeal_hp_dif'});
                                }
                                $ai_v{'useParty_skill_lvl'} = $ai_v{'temp'}{'smartHeal_lvl'};
                        }
                        if ($ai_v{'useParty_skill_lvl'} > 0) {
                                print qq~Auto-skill on party: $skills_lut{$skills_rlut{lc($ai_v{'useParty_skill'})}} (lvl $ai_v{'useParty_skill_lvl'})\n~ if $config{'debug'};
                                if (!ai_getSkillUseType($skills_rlut{lc($ai_v{'Party_skill'})})) {
                                        ai_skillUse($ai_v{'useParty_skill_ID'}, $ai_v{'useParty_skill_lvl'}, $ai_v{'useParty_skill_maxCastTime'}, $ai_v{'useParty_skill_minCastTime'}, $ai_v{'useParty_skill_targetID'});
                                } else {
                                        ai_skillUse($ai_v{'useParty_skill_ID'}, $ai_v{'useParty_skill_lvl'}, $ai_v{'useParty_skill_maxCastTime'}, $ai_v{'useParty_skill_minCastTime'}, $players{$ai_v{'useParty_skill_targetID'}}{'pos_to'}{'x'}, $players{$ai_v{'useParty_skill_targetID'}}{'pos_to'}{'y'});
                                }

                        }
                }
                $timeout{'ai_skill_party'}{'time'} = time;
        }



        ##### LOCKMAP #####

        if ($ai_v{'waitting_for_leave_indoor'} && $field{'name'} ne "" && !$indoors_lut{$field{'name'}.'.rsw'}) {
                undef $ai_v{'waitting_for_leave_indoor'};
                aiRemove("move");
                aiRemove("route");
                aiRemove("route_getRoute");
                aiRemove("route_getMapRoute");
        }

        if ($ai_seq[0] eq "" && $config{'lockMap'} && $field{'name'}
                && ($field{'name'} ne $config{'lockMap'} || ($config{'lockMap_x'} ne "" && $config{'lockMap_y'} ne "" && (($chars[$config{'char'}]{'pos_to'}{'x'} > $config{'lockMap_x'} + $config{'lockMap_rand'}) || ($chars[$config{'char'}]{'pos_to'}{'x'} < $config{'lockMap_x'} - $config{'lockMap_rand'}) || ($chars[$config{'char'}]{'pos_to'}{'y'} > $config{'lockMap_y'} + $config{'lockMap_rand'}) || ($chars[$config{'char'}]{'pos_to'}{'y'} < $config{'lockMap_y'} - $config{'lockMap_rand'}))))) {

                if ($maps_lut{$config{'lockMap'}.'.rsw'} eq "") {
                        printc(1, "yr", "<系统> ", "无法锁定地图，地图 $config{'lockMap'} 不存在\n");
                } elsif ($config{'lockMap_warpTo'} && $config{'lockMap_warpTo'} ne $field{'name'} && ((!$config{'lockMap_warpToNotInMaps'} && $cities_lut{$field{'name'}.'.rsw'}) || ($config{'lockMap_warpToNotInMaps'} && !existsInList($config{'lockMap_warpToNotInMaps'}, $field{'name'})))) {
                        ai_warp($config{'lockMap_warpTo'});
                } elsif ($config{'lockMap_flyTo'} ne $field{'name'} && $config{'lockMap_flyTo'} && ((!$config{'lockMap_flyToNotInMaps'} && $cities_lut{$field{'name'}.'.rsw'}) || ($config{'lockMap_flyToNotInMaps'} && !existsInList($config{'lockMap_flyToNotInMaps'}, $field{'name'}))) && $mapserver_lut{$config{'lockMap_flyTo'}.'.rsw'} && $mapip_lut{$config{'lockMap_flyTo'}.'.rsw'}{'ip'} ne "" && $mapip_lut{$config{'lockMap_flyTo'}.'.rsw'}{'port'} ne ""
                        && $mapip_lut{$field{'name'}.'.rsw'}{'ip'} ne "" && $mapip_lut{$field{'name'}.'.rsw'}{'port'} ne "" && ($mapip_lut{$config{'lockMap'}.'.rsw'}{'ip'} ne $mapip_lut{$field{'name'}.'.rsw'}{'ip'} || ($mapip_lut{$config{'lockMap'}.'.rsw'}{'ip'} eq $mapip_lut{$field{'name'}.'.rsw'}{'ip'} && $mapip_lut{$config{'lockMap'}.'.rsw'}{'port'} ne $mapip_lut{$field{'name'}.'.rsw'}{'port'}))) {
                        printc(1, "yw", "<系统> ", "正在转移到: $mapip_lut{$config{'lockMap_flyTo'}.'.rsw'}{'name'}($config{'lockMap_flyTo'})\n");
                        sendFly($mapip_lut{$config{'lockMap_flyTo'}.'.rsw'}{'ip'}, $mapip_lut{$config{'lockMap_flyTo'}.'.rsw'}{'port'});
                } elsif ($config{'saveMap_warpToNotInMaps'} ne "" && $config{'saveMap'} ne $field{'name'} && !existsInList($config{'saveMap_warpToNotInMaps'}, $field{'name'})) {
                        undef $ai_v{'waitting_for_leave_indoor'};
                        if ($indoors_lut{$field{'name'}.'.rsw'}) {
                                printc(1, "yr", "<系统> ", "试图离开不能瞬移地图，当前地图：$field{'name'}\n");
                                chatLog("x", "试图离开不能瞬移地图，当前地图：$field{'name'}\n");
                                printc(1, "yw", "<系统> ", "正在计算锁定地图路线: $maps_lut{$config{'lockMap'}.'.rsw'}($config{'lockMap'})\n");
                                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, "", "", $config{'lockMap'}, 0, 0, 1, 0, 0, 1);
                                $ai_v{'waitting_for_leave_indoor'} = 1;
                        } else {
                                printc(1, "yr", "<系统> ", "不在指定地图，返回记录点，当前地图：$field{'name'}\n");
                                chatLog("x", "不在指定地图，返回记录点，当前地图：$field{'name'}\n");
                                useTeleport(2);
                                ai_clientSuspend(0,1);
                        }
                } else {
                        undef $ai_v{'temp'}{'dest_map'};
                        undef $ai_v{'temp'}{'dest_x'};
                        undef $ai_v{'temp'}{'dest_y'};
                        if ($config{'lockMap'} ne $field{'name'} && existsInList($config{'lockMap_route'}, $field{'name'})) {
                                undef @array;
                                @array = split /,/, $config{'lockMap_route'};
                                for ($i = 0; $i < @array; $i++) {
                                        if ($field{'name'} eq $array[$i]) {
                                        	$ai_v{'temp'}{'dest_map'} = $array[$i + 1];
                                                last;
                                        }
                                }
                                $ai_v{'temp'}{'dest_map'} = $config{'lockMap'} if ($ai_v{'temp'}{'dest_map'} eq "");
                                printc(1, "yw", "<系统> ", "正在计算下个地图路线: $maps_lut{$ai_v{'temp'}{'dest_map'}.'.rsw'}($ai_v{'temp'}{'dest_map'})\n");
                        } elsif ($config{'lockMap_x'} ne "" && $config{'lockMap_y'} ne "") {
				printc(1, "yw", "<系统> ", "正在计算锁定地图路线: $maps_lut{$config{'lockMap'}.'.rsw'}($config{'lockMap'}): $config{'lockMap_x'}, $config{'lockMap_y'}\n");
                                $ai_v{'temp'}{'dest_map'} = $config{'lockMap'};
                                $ai_v{'temp'}{'dest_x'} = $config{'lockMap_x'};
                                $ai_v{'temp'}{'dest_y'} = $config{'lockMap_y'};
                        } else {
                                printc(1, "yw", "<系统> ", "正在计算锁定地图路线: $maps_lut{$config{'lockMap'}.'.rsw'}($config{'lockMap'})\n");
                                $ai_v{'temp'}{'dest_map'} = $config{'lockMap'};
                        }
                        if ((($config{'lockMap_routeType'} == 1 && !$cities_lut{$field{'name'}.'.rsw'} && !$cities_lut{$ai_v{'temp'}{'dest_map'}.'.rsw'})
                        	|| ($config{'lockMap_routeType'} == 2 && !$indoors_lut{$field{'name'}.'.rsw'} && !$indoors_lut{$ai_v{'temp'}{'dest_map'}.'.rsw'}))) {
                        	if ($config{'lockMap'} ne $field{'name'}) {
		                        undef $ai_v{'temp'}{'foundID'};
        	                        undef $ai_v{'temp'}{'smallDist'};
           			        $ai_v{'temp'}{'first'} = 1;
           	        	        foreach (keys %portals_lut) {
		                	        if ($portals_lut{$_}{'source'}{'map'} eq $field{'name'} && $portals_lut{$_}{'dest'}{'map'} eq $ai_v{'temp'}{'dest_map'}){
		                        		$ai_v{'temp'}{'dist'} = abs($chars[$config{'char'}]{'pos_to'}{'x'} - $portals_lut{$_}{'source'}{'pos'}{'x'}) + abs($chars[$config{'char'}]{'pos_to'}{'y'} - $portals_lut{$_}{'source'}{'pos'}{'y'});
                		                	if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'}) {
                                				$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
	                                                	$ai_v{'temp'}{'foundID'} = $_;
        	                                        	undef $ai_v{'temp'}{'first'};
                	                                }
                        	                }
					}
					if ($ai_v{'temp'}{'foundID'} ne "") {
						if ($config{'teleportAuto_maxRouteDistance'} && $ai_v{'temp'}{'smallDist'} > $config{'teleportAuto_maxRouteDistance'}) {
			                                printc(1, "wr", "<瞬移> ", "距离地图转换点$ai_v{'temp'}{'smallDist'}格\n");
		        	                        undef $ai_v{'temp'}{'dest_map'};
                	        	                useTeleport(1);
                	                	        ai_clientSuspend(0,1);
	                                        } elsif (!$portals_lut{$ai_v{'temp'}{'foundID'}}{'npc'}{'ID'}) {
        	                              		$ai_v{'temp'}{'dest_map'} = $field{'name'};
	        	                        	$ai_v{'temp'}{'dest_x'} = $portals_lut{$ai_v{'temp'}{'foundID'}}{'source'}{'pos'}{'x'};
               			                	$ai_v{'temp'}{'dest_y'} = $portals_lut{$ai_v{'temp'}{'foundID'}}{'source'}{'pos'}{'y'};
               		        	        	if (!$ai_v{'temp'}{'smallDist'}) {
               		        	        	 	undef $ai_v{'temp'}{'dest_map'};
               		                		 	getRandomCoords(\%coords, \%{$chars[$config{'char'}]{'pos_to'}}, 2);
      								sendMove(\$remote_socket, $coords{'x'}, $coords{'y'});
      								sleep(1);
	      						}
						}	
                	                }
                	        } else {
	                        	$ai_v{'temp'}{'distance'} = abs($chars[$config{'char'}]{'pos_to'}{'x'} - $config{'lockMap_x'}) + abs($chars[$config{'char'}]{'pos_to'}{'y'} - $config{'lockMap_y'});
					if ($config{'teleportAuto_maxRouteDistance'} && $ai_v{'temp'}{'distance'} > $config{'teleportAuto_maxRouteDistance'}) {
	        	                        printc(1, "wr", "<瞬移> ", "距离地图转换点$ai_v{'temp'}{'distance'}格\n");
	                	                undef $ai_v{'temp'}{'dest_map'};
               	                	        useTeleport(1);
            	                        	ai_clientSuspend(0,5);
	                                }
	                        }
                        }
                        if ($ai_v{'temp'}{'dest_map'} ne "") {
                        	ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'dest_x'}, $ai_v{'temp'}{'dest_y'}, $ai_v{'temp'}{'dest_map'}, 0, 0, 1, 0, 0, 1);
                        	if ($xKore && $ai_v{'temp'}{'dest_map'} eq $field{'name'} && $ai_v{'temp'}{'dest_x'} ne "") {
                        		injectMapMark(1, "y", $ai_v{'temp'}{'dest_x'}, $ai_v{'temp'}{'dest_y'});
                        	}
                        }	
                }
        }



        ##### RANDOM WALK #####
        if ($config{'route_randomWalk'} && $ai_seq[0] eq "" && $field{'rawMap'} ne "" && !$cities_lut{$field{'name'}.'.rsw'}) {
                do {
                        $ai_v{'temp'}{'randX'} = int(rand() * ($field{'width'} - 1));
                        $ai_v{'temp'}{'randY'} = int(rand() * ($field{'height'} - 1));
                } while (unpack("C", substr($field{'rawMap'}, $ai_v{'temp'}{'randY'} * $field{'width'} + $ai_v{'temp'}{'randX'}, 1)));
                printc(1, "yw", "<系统> ", "正在计算随机路线: $maps_lut{$field{'name'}.'.rsw'}($field{'name'}): $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}\n");
                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $field{'name'}, 0, $config{'route_randomWalk_maxRouteTime'}, 2);
        }

        
        
        ##### WARP #####
        
        if ($ai_seq[0] eq "warp") {
                if (!$ai_seq_args[0]{'step'}) {
                        $ai_seq_args[0]{'step'}++;
			printc(1, "yw", "<系统> ", "正在传送到: $maps_lut{$ai_seq_args[0]{'map'}.'.rsw'}($ai_seq_args[0]{'map'})\n");
                        getRandomCoords(\%{$ai_seq_args[0]{'pos_to'}}, \%{$chars[$config{'char'}]{'pos_to'}}, 12);
                        ai_skillUse($chars[$config{'char'}]{'skills'}{'AL_WARP'}{'ID'}, $chars[$config{'char'}]{'skills'}{'AL_WARP'}{'lv'}, 4,2, $ai_seq_args[0]{'pos_to'}{'x'}, $ai_seq_args[0]{'pos_to'}{'y'});
                } elsif ($ai_seq_args[0]{'step'} == 1) {
                	sendWarpto(\$remote_socket, $ai_seq_args[0]{'map'}.'.gat');
                      	$ai_seq_args[0]{'step'}++;
                } elsif ($ai_seq_args[0]{'step'} == 2) {
                	$ai_seq_args[0]{'step'}++;
                        printc(1, "ww", "<信息> ", "移动到传送点 ($ai_seq_args[0]{'pos_to'}{'x'}, $ai_seq_args[0]{'pos_to'}{'y'})\n");
                	move($ai_seq_args[0]{'pos_to'}{'x'}, $ai_seq_args[0]{'pos_to'}{'y'});
                } else {
       	                shift @ai_seq;
        	        shift @ai_seq_args;
        	        ai_clientSuspend(0,2);
                }
        }
        
        
        
        ##### FOLLOW #####


        if ($ai_seq[0] eq "" && $config{'follow'}) {
                ai_follow($config{'followTarget'});
        }
        if ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'suspended'}) {
                if ($ai_seq_args[0]{'ai_follow_lost'}) {
                        $ai_seq_args[0]{'ai_follow_lost_end'}{'time'} += time - $ai_seq_args[0]{'suspended'};
                }
                undef $ai_seq_args[0]{'suspended'};
        }
        if ($ai_seq[0] eq "follow" && !$ai_seq_args[0]{'ai_follow_lost'}) {
                if (!$ai_seq_args[0]{'following'}) {
                        foreach (keys %players) {
                                if ($players{$_}{'name'} eq $ai_seq_args[0]{'name'} && !$players{$_}{'dead'}) {
                                        $ai_seq_args[0]{'ID'} = $_;
                                        $ai_seq_args[0]{'following'} = 1;
                                        last;
                                }
                        }
                }
                if (!$ai_seq_args[0]{'ID'}) {
                        for ($i = 0; $i < @partyUsersID; $i++) {
                                next if ($partyUsersID[$i] eq "");
                                if ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'name'} eq $config{'followTarget'}) {
                                        $ai_seq_args[0]{'ID'} = $partyUsersID[$i];
                                        $ai_seq_args[0]{'following'} = 1 if (%{$players{$ai_seq_args[0]{'ID'}}});
                                        last;
                                }
                        }
                }
                if ($ai_seq_args[0]{'following'} && $players{$ai_seq_args[0]{'ID'}}{'pos_to'}) {
                        $ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$ai_seq_args[0]{'ID'}}{'pos_to'}});
                        if ($ai_v{'temp'}{'dist'} > $config{'followDistanceMax'}) {
                                ai_route(\%{$ai_seq_args[0]{'ai_route_returnHash'}}, $players{$ai_seq_args[0]{'ID'}}{'pos_to'}{'x'}, $players{$ai_seq_args[0]{'ID'}}{'pos_to'}{'y'}, $field{'name'}, 0, 0, 1, 0, $config{'followDistanceMin'});
                        }
                }
                if ($ai_seq_args[0]{'following'} && $players{$ai_seq_args[0]{'ID'}}{'sitting'} == 1 && $chars[$config{'char'}]{'sitting'} == 0) {
                        sit();
                }
        }

        if ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'following'} && $players{$ai_seq_args[0]{'ID'}}{'dead'}) {
                print "Master died.  I'll wait here.\n";
                undef $ai_seq_args[0]{'following'};
        } elsif ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'following'} && !%{$players{$ai_seq_args[0]{'ID'}}}) {
                print "I lost my master\n";
                undef $ai_seq_args[0]{'following'};
                if ($players_old{$ai_seq_args[0]{'ID'}}{'disconnected'}) {
                        print "My master disconnected\n";

                } elsif ($players_old{$ai_seq_args[0]{'ID'}}{'disappeared'}) {
                        print "Trying to find lost master\n";
                        undef $ai_seq_args[0]{'ai_follow_lost_char_last_pos'};
                        undef $ai_seq_args[0]{'follow_lost_portal_tried'};
                        $ai_seq_args[0]{'ai_follow_lost'} = 1;
                        $ai_seq_args[0]{'ai_follow_lost_end'}{'timeout'} = $timeout{'ai_follow_lost_end'}{'timeout'};
                        $ai_seq_args[0]{'ai_follow_lost_end'}{'time'} = time;
                        getVector(\%{$ai_seq_args[0]{'ai_follow_lost_vec'}}, \%{$players_old{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$chars[$config{'char'}]{'pos_to'}});

                        #check if player went through portal
                        if (!$players_old{$ai_seq_args[0]{'ID'}}{'teleported'}) {
                                $ai_v{'temp'}{'first'} = 1;
                                undef $ai_v{'temp'}{'foundID'};
                                undef $ai_v{'temp'}{'smallDist'};
                                foreach (@portalsID) {
                                        $ai_v{'temp'}{'dist'} = distance(\%{$players_old{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$portals{$_}{'pos'}});
                                        if ($ai_v{'temp'}{'dist'} <= 7 && ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'})) {
                                                $ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
                                                $ai_v{'temp'}{'foundID'} = $_;
                                                undef $ai_v{'temp'}{'first'};
                                        }
                                }
                                $ai_seq_args[0]{'follow_lost_portalID'} = $ai_v{'temp'}{'foundID'};
                        }
                } else {
                        print "Don't know what happened to Master\n";
                        undef $ai_seq_args[0]{'following'};
                        undef $ai_seq_args[0]{'follow_lost_portalID'};
                        undef $players{$ai_seq_args[0]{'ID'}}{'dead'};
                        undef $players_old{$ai_seq_args[0]{'ID'}}{'dead'};
                }
        }

        if ($ai_seq[0] eq "follow" && !$ai_seq_args[0]{'following'} && !$ai_seq_args[0]{'follow_lost_portalID'} && !%{$players{$ai_seq_args[0]{'ID'}}} && !$players{$ai_seq_args[0]{'ID'}}{'dead'}) {
                if ($chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}} ne "" && $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'online'} && $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'map'} ne "") {
                        ($map_string) = $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'map'} =~ /([\s\S]*)\.gat/;
                        if ($chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'pos'}{'x'} > 0) {
                                $ai_seq_args[0]{'follow_lost_char'}{'map'} = $map_string;
                                $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'x'} = $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'pos'}{'x'} + int(rand(4)- 2);
                                $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'y'} = $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'pos'}{'y'} + int(rand(4)- 2);
                                printc(1, "yw", "<系统> ", "正在计算路线: $maps_lut{$ai_seq_args[0]{'follow_lost_char'}{'map'}.'.rsw'}($ai_seq_args[0]{'follow_lost_char'}{'map'}): $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'x'}, $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'y'}\n");
                                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'x'}, $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'y'}, $ai_seq_args[0]{'follow_lost_char'}{'map'}, 0, 0, 1, 0, 0, 1);
                        } elsif ($field{'name'} ne $map_string) {
                                $ai_seq_args[0]{'follow_lost_char'}{'map'} = $map_string;
                                undef $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'x'};
                                undef $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'y'};
                                printc(1, "yw", "<系统> ", "正在计算路线: $maps_lut{$ai_seq_args[0]{'follow_lost_char'}{'map'}.'.rsw'}($ai_seq_args[0]{'follow_lost_char'}{'map'})\n");
                                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'x'}, $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'y'}, $ai_seq_args[0]{'follow_lost_char'}{'map'}, 0, 0, 1, 0, 0, 1);
                        }
                }
        }

        if ($ai_seq[0] eq "route" && binFind(\@ai_seq, "follow") && !$ai_seq_args[binFind(\@ai_seq, "follow")]{'following'} && !$ai_seq_args[binFind(\@ai_seq, "follow")]{'follow_lost_portalID'} && $ai_seq_args[binFind(\@ai_seq, "follow")]{'ID'} ne "" && !$ai_seq_args[0]{'npc'}{'step'} && timeOut(\%{$timeout{'ai_smart_follow'}})) {
                $ai_v{'temp'}{'index'} = binFind(\@ai_seq, "follow");
                $ai_v{'temp'}{'ID'} = $ai_seq_args[$ai_v{'temp'}{'index'}]{'ID'};
                ($map_string) = $chars[$config{'char'}]{'party'}{'users'}{$ai_v{'temp'}{'ID'}}{'map'} =~ /([\s\S]*)\.gat/;
                if ($chars[$config{'char'}]{'party'}{'users'}{$ai_v{'temp'}{'ID'}}{'pos'}{'x'} > 0 && $field{'name'} eq $map_string && distance(\%{$chars[$config{'char'}]{'party'}{'users'}{$ai_v{'temp'}{'ID'}}{'pos'}}, \%{$ai_seq_args[$ai_v{'temp'}{'index'}]{'follow_lost_char'}{'pos'}}) > 40) {
                        undef @ai_seq;
                        undef @ai_seq_args;
                        ai_follow($config{'followTarget'});
                } elsif ($map_string ne $ai_seq_args[$ai_v{'temp'}{'index'}]{'follow_lost_char'}{'map'} && !$indoors_lut{$map_string.'.rsw'}) {
                        undef @ai_seq;
                        undef @ai_seq_args;
                        ai_follow($config{'followTarget'});
                } else {
                        for ($i = 0; $i < @playersID; $i++) {
                                next if ($playersID[$i] eq "");
                                if ($playersID[$i] eq $ai_seq_args[binFind(\@ai_seq, "follow")]{'ID'}) {
                                        undef @ai_seq;
                                        undef @ai_seq_args;
                                        ai_follow($config{'followTarget'});
                                        last;
                                }
                        }
                }
                $timeout{'ai_smart_follow'}{'time'} = time;
        }


        ##### FOLLOW-LOST #####


        if ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'ai_follow_lost'}) {
                if ($ai_seq_args[0]{'ai_follow_lost_char_last_pos'}{'x'} == $chars[$config{'char'}]{'pos_to'}{'x'} && $ai_seq_args[0]{'ai_follow_lost_char_last_pos'}{'y'} == $chars[$config{'char'}]{'pos_to'}{'y'}) {
                        $ai_seq_args[0]{'lost_stuck'}++;
                } else {
                        undef $ai_seq_args[0]{'lost_stuck'};
                }
                %{$ai_seq_args[0]{'ai_follow_lost_char_last_pos'}} = %{$chars[$config{'char'}]{'pos_to'}};

                if (timeOut(\%{$ai_seq_args[0]{'ai_follow_lost_end'}})) {
                        undef $ai_seq_args[0]{'ai_follow_lost'};
                        undef $ai_seq_args[0]{'follow_lost_portalID'};
                        print "Couldn't find master, giving up\n";

                } elsif ($players_old{$ai_seq_args[0]{'ID'}}{'disconnected'}) {
                        undef $ai_seq_args[0]{'ai_follow_lost'};
                        print "My master disconnected\n";

                } elsif (%{$players{$ai_seq_args[0]{'ID'}}}) {
                        $ai_seq_args[0]{'following'} = 1;
                        undef $ai_seq_args[0]{'ai_follow_lost'};
                        print "Found my master!\n";

                } elsif ($ai_seq_args[0]{'lost_stuck'}) {
                        if ($ai_seq_args[0]{'follow_lost_portalID'} eq "") {
                                moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'ai_follow_lost_vec'}}, $config{'followLostStep'} / ($ai_seq_args[0]{'lost_stuck'} + 1));
                                move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
                        }

                } else {
                        if ($ai_seq_args[0]{'follow_lost_portalID'} ne "") {
                                if (%{$portals{$ai_seq_args[0]{'follow_lost_portalID'}}} && !$ai_seq_args[0]{'follow_lost_portal_tried'}) {
                                        $ai_seq_args[0]{'follow_lost_portal_tried'} = 1;
                                        %{$ai_v{'temp'}{'pos'}} = %{$portals{$ai_seq_args[0]{'follow_lost_portalID'}}{'pos'}};
                                        ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}, $field{'name'}, 0, 0, 1);
                                        undef $ai_seq_args[0]{'follow_lost_portalID'};
                                }
                        } else {
                                moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'ai_follow_lost_vec'}}, $config{'followLostStep'});
                                move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
                        }
                }
        }

        ##### AUTO-SIT/SIT/STAND #####


        if ($exp{'base'}{'sitStartTime'} > 0 && binFind(\@ai_seq, "sitAuto") eq "") {
                $exp{'base'}{'sitTime'} += time - $exp{'base'}{'sitStartTime'};
                undef $exp{'base'}{'sitStartTime'};
        }

        if ($config{'sitAuto_idle'} && ($ai_seq[0] ne "" && $ai_seq[0] ne "follow")) {
                $timeout{'ai_sit_idle'}{'time'} = time;
        }
        if (($ai_seq[0] eq "" || $ai_seq[0] eq "follow") && $config{'sitAuto_idle'} && !$chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_sit_idle'}})) {
                sit();
        }
        if ($ai_seq[0] eq "sitting" && ($chars[$config{'char'}]{'sitting'} || $chars[$config{'char'}]{'skills'}{'NV_BASIC'}{'lv'} < 3)) {
                shift @ai_seq;
                shift @ai_seq_args;
                $timeout{'ai_sit'}{'time'} -= $timeout{'ai_sit'}{'timeout'};
                ai_autoSwitch("sitAuto");

        } elsif ($ai_seq[0] eq "sitting" && !$chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_sit'}}) && timeOut(\%{$timeout{'ai_sit_wait'}})) {
                sendSit(\$remote_socket);
                $timeout{'ai_sit'}{'time'} = time;
        }
        if ($ai_seq[0] eq "standing" && !$chars[$config{'char'}]{'sitting'} && !$timeout{'ai_stand_wait'}{'time'}) {
                $timeout{'ai_stand_wait'}{'time'} = time;
        } elsif ($ai_seq[0] eq "standing" && !$chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_stand_wait'}})) {
                shift @ai_seq;
                shift @ai_seq_args;
                undef $timeout{'ai_stand_wait'}{'time'};
                $timeout{'ai_sit'}{'time'} -= $timeout{'ai_sit'}{'timeout'};
        } elsif ($ai_seq[0] eq "standing" && $chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_sit'}})) {
                sendStand(\$remote_socket);
                $timeout{'ai_sit'}{'time'} = time;
        }

        if ($ai_v{'sitAuto_forceStop'} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_hp_lower'} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_sp_lower'}) {
                $ai_v{'sitAuto_forceStop'} = 0;
        }

        if (!$ai_v{'sitAuto_forceStop'} && ($ai_seq[0] eq "" || $ai_seq[0] eq "follow" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute") && binFind(\@ai_seq, "attack") eq "" && !ai_getAggressives()
                && binFind(\@ai_seq, "storageAuto") eq "" && binFind(\@ai_seq, "buyAuto") eq "" && binFind(\@ai_seq, "sellAuto") eq "" && binFind(\@ai_seq, "healAuto") eq ""
                && (percent_hp(\%{$chars[$config{'char'}]}) < $config{'sitAuto_hp_lower'} || percent_sp(\%{$chars[$config{'char'}]}) < $config{'sitAuto_sp_lower'}) && percent_weight(\%{$chars[$config{'char'}]}) < 50) {
                unshift @ai_seq, "sitAuto";
                unshift @ai_seq_args, {};
                print "Auto-sitting\n" if $config{'debug'};
                $exp{'base'}{'sitStartTime'} = time;
        }
        if ($ai_seq[0] eq "sitAuto" && !$chars[$config{'char'}]{'sitting'} && $chars[$config{'char'}]{'skills'}{'NV_BASIC'}{'lv'} >= 3
                && !ai_getAggressives() && !ai_getRoundMonster($config{'teleportAuto_roundMonstersDist'})){
                sit();
        }
        if ($ai_seq[0] eq "sitAuto" && ($ai_v{'sitAuto_forceStop'} || percent_weight(\%{$chars[$config{'char'}]}) >= 50
                || (percent_hp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_hp_upper'} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_sp_upper'}))) {
                shift @ai_seq;
                shift @ai_seq_args;
                if (!$config{'sitAuto_idle'} && $chars[$config{'char'}]{'sitting'}) {
                        stand();
                }
        }


        ##### AUTO-ATTACK #####


        if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute" || $ai_seq[0] eq "follow"
                || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather" || $ai_seq[0] eq "items_take")
                && !($config{'itemsTakeAuto'} >= 2 && ($ai_seq[0] eq "take" || $ai_seq[0] eq "items_take"))
                && !($config{'itemsGatherAuto'} >= 2 && ($ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather"))
                && timeOut(\%{$timeout{'ai_attack_auto'}})) {
                undef @{$ai_v{'ai_attack_agMonsters'}};
                undef @{$ai_v{'ai_attack_cleanMonsters'}};
                undef @{$ai_v{'ai_attack_partyMonsters'}};
                undef $ai_v{'temp'}{'foundID'};
                if ($config{'tankMode'}) {
                        undef $ai_v{'temp'}{'found'};
                        foreach (@playersID) {
                                next if ($_ eq "");
                                if ($config{'tankModeTarget'} eq $players{$_}{'name'}) {
                                        $ai_v{'temp'}{'found'} = 1;
                                        last;
                                }
                        }
                }
                if (!$config{'tankMode'} || ($config{'tankMode'} && $ai_v{'temp'}{'found'})) {
                        $ai_v{'temp'}{'ai_follow_index'} = binFind(\@ai_seq, "follow");
                        if ($ai_v{'temp'}{'ai_follow_index'} ne "") {
                                $ai_v{'temp'}{'ai_follow_following'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'following'};
                                $ai_v{'temp'}{'ai_follow_ID'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'ID'};
                        } else {
                                undef $ai_v{'temp'}{'ai_follow_following'};
                        }
                        $ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
                        if ($ai_v{'temp'}{'ai_route_index'} ne "") {
                                $ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
                        }
                        @{$ai_v{'ai_attack_agMonsters'}} = ai_getAttackAggressives() if ($config{'attackAuto'} && !($ai_v{'temp'}{'ai_route_index'} ne "" && !$ai_v{'temp'}{'ai_route_attackOnRoute'}));
                        foreach (@monstersID) {
                                next if ($_ eq "");
                                if ((($config{'attackAuto_party'}
                                        && $ai_seq[0] ne "take" && $ai_seq[0] ne "items_take"
                                        && ($monsters{$_}{'dmgToParty'} > 0 || $monsters{$_}{'dmgFromParty'} > 0))
                                        || ($config{'attackAuto_followTarget'} && $ai_v{'temp'}{'ai_follow_following'}
                                        && ($monsters{$_}{'dmgToPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0 || $monsters{$_}{'dmgFromPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0)))
                                        && !($ai_v{'temp'}{'ai_route_index'} ne "" && !$ai_v{'temp'}{'ai_route_attackOnRoute'})
                                        && $monsters{$_}{'attack_failed'} == 0 && ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} >= 2 || ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "" && $mon_control{'all'}{'attack_auto'} >= 2))) {
                                        push @{$ai_v{'ai_attack_partyMonsters'}}, $_;

                                } elsif ($config{'attackAuto'} >= 2
                                        && $ai_seq[0] ne "sitAuto" && $ai_seq[0] ne "take" && $ai_seq[0] ne "items_gather" && $ai_seq[0] ne "items_take"
                                        && ($config{'attackSteal'} || !($monsters{$_}{'dmgFromYou'} == 0 && ($monsters{$_}{'dmgTo'} > 0 || $monsters{$_}{'dmgFrom'} > 0 || %{$monsters{$_}{'missedFromPlayer'}} || %{$monsters{$_}{'missedToPlayer'}} || %{$monsters{$_}{'castOnByPlayer'}})))
                                        && $monsters{$_}{'attack_failed'} == 0 && !($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1)
                                        && ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} >= 2 || ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "" && $mon_control{'all'}{'attack_auto'} >= 2))) {
                                        push @{$ai_v{'ai_attack_cleanMonsters'}}, $_;
                                }
                        }
                        undef $ai_v{'temp'}{'distSmall'};
                        undef $ai_v{'temp'}{'foundID'};
                        $ai_v{'temp'}{'first'} = 1;
                        foreach (@{$ai_v{'ai_attack_agMonsters'}}) {
                                $ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
                                if ($ai_v{'temp'}{'first'} || ($ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'distSmall'} && $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq $mon_control{lc($monsters{$ai_v{'temp'}{'foundID'}}{'name'})}{'attack_auto'})
                                        || ($ai_v{'temp'}{'foundID'} ne "" && $ai_v{'temp'}{'dist'} < $config{'attackDistance'} && $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} > $mon_control{lc($monsters{$ai_v{'temp'}{'foundID'}}{'name'})}{'attack_auto'})) {
                                        $ai_v{'temp'}{'distSmall'} = $ai_v{'temp'}{'dist'};
                                        $ai_v{'temp'}{'foundID'} = $_;
                                        undef $ai_v{'temp'}{'first'};
                                }
                        }
                        if (!$ai_v{'temp'}{'foundID'}) {
                                undef $ai_v{'temp'}{'distSmall'};
                                undef $ai_v{'temp'}{'foundID'};
                                $ai_v{'temp'}{'first'} = 1;
                                foreach (@{$ai_v{'ai_attack_partyMonsters'}}) {
                                        $ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
                                        if ($ai_v{'temp'}{'first'} || ($ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'distSmall'} && $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq $mon_control{lc($monsters{$ai_v{'temp'}{'foundID'}}{'name'})}{'attack_auto'})
                                                || ($ai_v{'temp'}{'foundID'} ne "" && $ai_v{'temp'}{'dist'} < $config{'attackDistance'} && $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} > $mon_control{lc($monsters{$ai_v{'temp'}{'foundID'}}{'name'})}{'attack_auto'})) {
                                                $ai_v{'temp'}{'distSmall'} = $ai_v{'temp'}{'dist'};
                                                $ai_v{'temp'}{'foundID'} = $_;
                                                undef $ai_v{'temp'}{'first'};
                                        }
                                }
                        }
                        if (!$ai_v{'temp'}{'foundID'}) {
                                undef $ai_v{'temp'}{'distSmall'};
                                undef $ai_v{'temp'}{'foundID'};
                                $ai_v{'temp'}{'first'} = 1;
                                foreach (@{$ai_v{'ai_attack_cleanMonsters'}}) {
                                        $ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
                                        if ($ai_v{'temp'}{'first'} || ($ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'distSmall'} && $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq $mon_control{lc($monsters{$ai_v{'temp'}{'foundID'}}{'name'})}{'attack_auto'})
                                                || ($ai_v{'temp'}{'foundID'} ne "" && $ai_v{'temp'}{'dist'} < $config{'attackDistance'} && $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} > $mon_control{lc($monsters{$ai_v{'temp'}{'foundID'}}{'name'})}{'attack_auto'})) {
                                                $ai_v{'temp'}{'distSmall'} = $ai_v{'temp'}{'dist'};
                                                $ai_v{'temp'}{'foundID'} = $_;
                                                undef $ai_v{'temp'}{'first'};
                                        }
                                }
                        }
                }
                if ($ai_v{'temp'}{'foundID'}) {
                        ai_setSuspend(0);
                        attack($ai_v{'temp'}{'foundID'});
                } else {
                        $timeout{'ai_attack_auto'}{'time'} = time;
                }
        }



        ##### ATTACK #####


        if ($ai_seq[0] eq "attack" && $ai_seq_args[0]{'suspended'}) {
                $ai_seq_args[0]{'ai_attack_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
                undef $ai_seq_args[0]{'suspended'};
        }
        if ($ai_seq[0] eq "attack" && timeOut(\%{$ai_seq_args[0]{'ai_attack_giveup'}})) {
                $monsters{$ai_seq_args[0]{'ID'}}{'attack_failed'}++;
                shift @ai_seq;
                shift @ai_seq_args;
                printc(1, "wr", "<信息> ", "无法到达或攻击目标，放弃目标\n");
        } elsif ($ai_seq[0] eq "attack" && !%{$monsters{$ai_seq_args[0]{'ID'}}}) {
                $timeout{'ai_attack'}{'time'} -= $timeout{'ai_attack'}{'timeout'};
                $ai_v{'ai_attack_ID_old'} = $ai_seq_args[0]{'ID'};
                shift @ai_seq;
                shift @ai_seq_args;
                if ($monsters_old{$ai_v{'ai_attack_ID_old'}}{'dead'}) {
                        printc(1, "wc", "<信息> ", "目标死亡\n");
                        if ($monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgFromYou'} > 0) {
                                $exp{'monster'}{$exp{'monster'}{'nameID'}}{'time'} += time - $exp{'monster'}{'startTime'};
                                $exp{'base'}{'attackTime'} += time - $exp{'monster'}{'startTime'} if ($exp{'monster'}{'startTime'});
                                $exp{'monster'}{$exp{'monster'}{'nameID'}}{'kill'}++;
                        }
                        if ($config{'itemsTakeAuto'} && $monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgFromYou'} > 0 && (!$config{'itemsTakeMaxWeight'} || percent_weight(\%{$chars[$config{'char'}]}) < $config{'itemsTakeMaxWeight'})
                        	&& (!$config{'itemsTakeDamage'} || $monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgFromYou'} / $monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgTo'} * 100 >= $config{'itemsTakeDamage'})) {
                                ai_items_take($monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos'}{'x'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos'}{'y'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos_to'}{'x'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos_to'}{'y'});
                        } else {
                                ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
                        }
                } else {
                        printc(1, "wr", "<信息> ", "目标丢失\n");
                }
        } elsif ($ai_seq[0] eq "attack" && $monsters{$ai_seq_args[0]{'ID'}}{'stolen'} && ($config{'stealOnly'} eq "1" || existsInList($config{'stealOnly'}, $monsters{$ai_seq_args[0]{'ID'}}{'name'}))) {
                $monsters{$ai_seq_args[0]{'ID'}}{'attack_failed'}++;
                if ($accountID eq $monsters{$ai_seq_args[0]{'ID'}}{'stolenBy'}) {
                        printc(1, "wc", "<信息> ", "偷窃成功，放弃目标\n");
	                $exp{'monster'}{$exp{'monster'}{'nameID'}}{'time'} += time - $exp{'monster'}{'startTime'};
        	        $exp{'base'}{'attackTime'} += time - $exp{'monster'}{'startTime'} if ($exp{'monster'}{'startTime'});
	                $exp{'monster'}{$exp{'monster'}{'nameID'}}{'kill'}++;                
                } elsif (%{$players{$monsters{$ai_seq_args[0]{'ID'}}{'stolenBy'}}}) {
                        printc(1, "wr", "<信息> ", "被 $players{$monsters{$ai_seq_args[0]{'ID'}}{'stolenBy'}}{'name'} 偷窃，放弃目标\n");
                } elsif (%{$players_old{$monsters{$ai_seq_args[0]{'ID'}}{'stolenBy'}}}) {
                        printc(1, "wr", "<信息> ", "被 $players_old{$monsters{$ai_seq_args[0]{'ID'}}{'stolenBy'}}{'name'} 偷窃，放弃目标\n");
                }
                shift @ai_seq;
                shift @ai_seq_args;
        } elsif (!$xKore && $ai_seq[0] eq "attack" && $vipLevel < 1 && existsInList($mvpMonster, $monsters{$ai_seq_args[0]{'ID'}}{'nameID'})) {
                $monsters{$ai_seq_args[0]{'ID'}}{'attack_failed'}++;
                shift @ai_seq;
                shift @ai_seq_args;
                printc(1, "wc", "<信息> ", "禁止攻击，放弃目标\n");
        } elsif ($ai_seq[0] eq "attack") {
                $ai_v{'temp'}{'ai_follow_index'} = binFind(\@ai_seq, "follow");
                if ($ai_v{'temp'}{'ai_follow_index'} ne "") {
                        $ai_v{'temp'}{'ai_follow_following'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'following'};
                        $ai_v{'temp'}{'ai_follow_ID'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'ID'};
                } else {
                        undef $ai_v{'temp'}{'ai_follow_following'};
                }
                $ai_v{'ai_attack_monsterDist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}});
                if ((!($monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'} == 0 && ($monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'dmgFrom'} > 0 || %{$monsters{$ai_seq_args[0]{'ID'}}{'missedFromPlayer'}} || %{$monsters{$ai_seq_args[0]{'ID'}}{'missedToPlayer'}} || %{$monsters{$ai_seq_args[0]{'ID'}}{'castOnByPlayer'}})))
                                || ($config{'attackAuto_party'} && ($monsters{$ai_seq_args[0]{'ID'}}{'dmgFromParty'} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'dmgToParty'} > 0))
                                || ($config{'attackAuto_followTarget'} && $ai_v{'temp'}{'ai_follow_following'} && ($monsters{$ai_seq_args[0]{'ID'}}{'dmgToPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0))
                                || ($monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'missedYou'} > 0)) {
                        $ai_v{'ai_attack_cleanMonster'} = 1;
                } else {
                        $ai_v{'ai_attack_cleanMonster'} = $config{'attackSteal'};
                        $monsters{$ai_seq_args[0]{'ID'}}{'attackSteal'} = 1;
                }

                if ($monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'} >= 0 && ($ai_seq_args[0]{'dmgToYou_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'}
                        || $ai_seq_args[0]{'missedYou_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'missedYou'}
                        || $ai_seq_args[0]{'dmgFromYou_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'})) {
                                $ai_seq_args[0]{'ai_attack_giveup'}{'time'} = time;
                }
                $ai_seq_args[0]{'dmgToYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'};
                $ai_seq_args[0]{'missedYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'missedYou'};
                $ai_seq_args[0]{'dmgFromYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'};
                $ai_seq_args[0]{'missedFromYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'missedFromYou'};
                if (!%{$ai_seq_args[0]{'attackMethod'}}) {
                        if ($config{'attackUseWeapon'}) {
                                $ai_seq_args[0]{'attackMethod'}{'distance'} = $config{'attackDistance'};
                                $ai_seq_args[0]{'attackMethod'}{'type'} = "weapon";
                        } else {
                                $ai_seq_args[0]{'attackMethod'}{'distance'} = 30;
                                undef $ai_seq_args[0]{'attackMethod'}{'type'};
                        }
                        $i = 0;
                        while ($config{"attackSkillSlot_$i"} ne "") {
                                if (percent_hp(\%{$chars[$config{'char'}]}) >= $config{"attackSkillSlot_$i"."_hp_lower"} && percent_hp(\%{$chars[$config{'char'}]}) <= $config{"attackSkillSlot_$i"."_hp_upper"}
                                        && percent_sp(\%{$chars[$config{'char'}]}) >= $config{"attackSkillSlot_$i"."_sp_lower"} && percent_sp(\%{$chars[$config{'char'}]}) <= $config{"attackSkillSlot_$i"."_sp_upper"}
                                        && $chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc($config{"attackSkillSlot_$i"})}}{$config{"attackSkillSlot_$i"."_lvl"}}
                                        && $config{"attackSkillSlot_$i"."_lvl"} > 0
                                        && (ai_getSkillUseID($config{"attackSkillSlot_$i"}) != 50 || (ai_getSkillUseID($config{"attackSkillSlot_$i"}) == 50 && !$monsters{$ai_seq_args[0]{'ID'}}{'stolen'}))
                                        && !($config{"attackSkillSlot_$i"."_stopWhenHit"} && ai_getMonstersWhoHitMe())
                                        && (!$config{"attackSkillSlot_$i"."_maxUses"} || $ai_seq_args[0]{'attackSkillSlot_uses'}{$i} < $config{"attackSkillSlot_$i"."_maxUses"})
                                        && (!$config{"attackSkillSlot_$i"."_maxTrys"} || $ai_seq_args[0]{'attackSkillSlot_trys'}{$i} < $config{"attackSkillSlot_$i"."_maxTrys"})
                                        && timeOut($config{"attackSkillSlot_$i"."_timeout"}, $ai_v{"attackSkillSlot_$i"."_time"})
                                        && (!$config{"attackSkillSlot_$i"."_lockMapOnly"} || ($config{"attackSkillSlot_$i"."_lockMapOnly"} && $field{'name'} eq $config{'lockMap'}))
                                        && (!$config{"attackSkillSlot_$i"."_inState"} || ($config{"attackSkillSlot_$i"."_inState"} ne "" && ai_stateCheck($monsters{$ai_seq_args[0]{'ID'}}, $config{"attackSkillSlot_$i"."_inState"})))
                                        && (!$config{"attackSkillSlot_$i"."_noState"} || ($config{"attackSkillSlot_$i"."_noState"} ne "" && !ai_stateCheck($monsters{$ai_seq_args[0]{'ID'}}, $config{"attackSkillSlot_$i"."_noState"})))
                                        && (!$config{"attackSkillSlot_$i"."_minAggressives"} || $config{"attackSkillSlot_$i"."_minAggressives"} <= ai_getAggressives())
                                        && (!$config{"attackSkillSlot_$i"."_maxAggressives"} || $config{"attackSkillSlot_$i"."_maxAggressives"} >= ai_getAggressives())
                                        && (!$config{"attackSkillSlot_$i"."_minSpirits"} || $config{"attackSkillSlot_$i"."_minSpirits"} <= $chars[$config{'char'}]{'spirits'})
                                        && (!$config{"attackSkillSlot_$i"."_maxSpirits"} || $config{"attackSkillSlot_$i"."_maxSpirits"} >= $chars[$config{'char'}]{'spirits'})
                                        && (!$config{"attackSkillSlot_$i"."_minRoundMonsters"} || $config{"attackSkillSlot_$i"."_minRoundMonsters"} <= ai_getRoundMonster($config{"attackSkillSlot_$i"."_roundMonstersDist"}))
                                        && (!$config{"attackSkillSlot_$i"."_maxRoundMonsters"} || $config{"attackSkillSlot_$i"."_maxRoundMonsters"} >= ai_getRoundMonster($config{"attackSkillSlot_$i"."_roundMonstersDist"}))
                                        && (!$config{"attackSkillSlot_$i"."_monsters"} || existsInList($config{"attackSkillSlot_$i"."_monsters"}, $monsters{$ai_seq_args[0]{'ID'}}{'name'}))) {

                                        $ai_seq_args[0]{'attackMethod'}{'distance'} = $config{"attackSkillSlot_$i"."_dist"};
       	                                $ai_seq_args[0]{'attackMethod'}{'type'} = "skill";
               	                        $ai_seq_args[0]{'attackMethod'}{'skillSlot'} = $i;
                       	                $ai_seq_args[0]{'attackSkillSlot_trys'}{$i}++;
	                                $ai_v{'ai_attack_method_skillSlot_ID'} = ai_getSkillUseID($config{"attackSkillSlot_$i"});
                               	        $ai_v{"attackSkillSlot_$i"."_time"} = time;
                               	        last;
                                }
                                $i++;
                        }
                }
                if ($chars[$config{'char'}]{'sitting'}) {
                        ai_setSuspend(0);
                        stand();
                } elsif (!$ai_v{'ai_attack_cleanMonster'}) {
                        shift @ai_seq;
                        shift @ai_seq_args;
                        printc(1, "wc", "<信息> ", "不抢怪，放弃目标\n");
                } elsif ($ai_seq_args[0]{'check_route_step'} == 1 || $ai_v{'ai_attack_monsterDist'} > $ai_seq_args[0]{'attackMethod'}{'distance'}) {
                        if (%{$ai_seq_args[0]{'char_pos_last'}} && %{$ai_seq_args[0]{'attackMethod_last'}}
                                && $ai_seq_args[0]{'attackMethod_last'}{'distance'} == $ai_seq_args[0]{'attackMethod'}{'distance'}
                                && $ai_seq_args[0]{'char_pos_last'}{'x'} == $chars[$config{'char'}]{'pos_to'}{'x'}
                                && $ai_seq_args[0]{'char_pos_last'}{'y'} == $chars[$config{'char'}]{'pos_to'}{'y'}) {
                                $ai_seq_args[0]{'distanceDivide'}++;
                        } else {
                                $ai_seq_args[0]{'distanceDivide'} = 1;
                        }
                        if ((!$chars[$config{'char'}]{'mvp'} && int($ai_seq_args[0]{'attackMethod'}{'distance'} / $ai_seq_args[0]{'distanceDivide'}) == 0)
                                || ($config{'attackMaxRouteDistance'} && $ai_seq_args[0]{'ai_route_returnHash'}{'solutionLength'} > $config{'attackMaxRouteDistance'})
                                || ($config{'attackMaxRouteTime'} && $ai_seq_args[0]{'ai_route_returnHash'}{'solutionTime'} > $config{'attackMaxRouteTime'})) {
                                $monsters{$ai_seq_args[0]{'ID'}}{'attack_failed'}++;
                                if ($config{'attackMaxRouteDistance'} && $ai_seq_args[0]{'ai_route_returnHash'}{'solutionLength'} > $config{'attackMaxRouteDistance'}) {
                                	if ($ai_seq_args[0]{'check_route_step'} == 1) {
	                                        printc(1, "nr", "<信息> ", "有障碍物，需要移动$ai_seq_args[0]{'ai_route_returnHash'}{'solutionLength'}格，放弃目标\n");
	                                } else {
	                                	printc(1, "nr", "<信息> ", "需要移动$ai_seq_args[0]{'ai_route_returnHash'}{'solutionLength'}格，放弃目标\n");
	                                }
                        		foreach (@monsters) {
                        			next if ($_ eq "");
                        			$ai_v{'temp'}{'dist'} = distance(\%{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}},\%{$monsters{$_}{'pos_to'}});
                        			if ($ai_v{'temp'}{'dist'} < 3) {
                        				$monsters{$_}{'attack_failed'}++;
                		        	}
		                        }
                                } elsif ($config{'attackMaxRouteTime'} && $ai_seq_args[0]{'ai_route_returnHash'}{'solutionTime'} > $config{'attackMaxRouteTime'}) {
                                	$monsters{$ai_seq_args[0]{'ID'}}{'attack_failed'}++;
                                        printc(1, "nr", "<信息> ", "计算路线超过$config{'attackMaxRouteTime'}秒，放弃目标\n");
                                } else {
                                        printc(1, "nr", "<信息> ", "无法攻击，放弃目标\n");
                                }
                                shift @ai_seq;
                                shift @ai_seq_args;
                        } else {
				if ($ai_seq_args[0]{'check_route_step'} == 1) {
					if ($ai_seq_args[0]{'ai_route_returnHash'}{'solutionLength'} > $ai_seq_args[0]{'check_distance'}) {
						printc(1, "nn", "<信息> ", "攻击时有障碍物，移动到怪物旁边\n") if ($config{'mode'});
						$ai_seq_args[0]{'attackMethod'}{'distance'} = 2;
						$ai_seq_args[0]{'check_route_step'} = 2;
					} else {
						$ai_seq_args[0]{'check_route_step'} = 3;
					}
				}
				if ($ai_v{'ai_attack_monsterDist'} > $ai_seq_args[0]{'attackMethod'}{'distance'}) {
					if ($ai_seq_args[0]{'check_route_step'} == 2) {
						%{$ai_v{'temp'}{'pos'}} = %{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}};
						$ai_seq_args[0]{'check_route_step'} = 3;
					} else {
                                		getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$chars[$config{'char'}]{'pos_to'}});
                                		moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'ai_attack_monsterDist'} - ($ai_seq_args[0]{'attackMethod'}{'distance'} / $ai_seq_args[0]{'distanceDivide'}) + 1);
                                	}

                                	%{$ai_seq_args[0]{'char_pos_last'}} = %{$chars[$config{'char'}]{'pos_to'}};
                                	%{$ai_seq_args[0]{'attackMethod_last'}} = %{$ai_seq_args[0]{'attackMethod'}};

                                	ai_setSuspend(0);
                                	if ($field{'rawMap'} ne "") {
                                        	ai_route(\%{$ai_seq_args[0]{'ai_route_returnHash'}}, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}, $field{'name'}, $config{'attackMaxRouteDistance'}, $config{'attackMaxRouteTime'}, 0, 0);
                                	} else {
                                        	move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
                                	}
                                }
                        }
		} elsif ($config{'attackCheckRoute'} && !$ai_seq_args[0]{'check_route_step'} && %{$ai_seq_args[0]{'attackMethod'}} && $ai_v{'ai_attack_monsterDist'} <= $ai_seq_args[0]{'attackMethod'}{'distance'} && $ai_v{'ai_attack_monsterDist'} >= 2 && $ai_seq_args[0]{'attackMethod'}{'distance'} > 3
			&& !$monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'} && !$monsters{$ai_seq_args[0]{'ID'}}{'missedYou'} && !$monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'} && !$monsters{$ai_seq_args[0]{'ID'}}{'missedFromYou'}) {
			$ai_seq_args[0]{'check_route_step'} = 1;
			$ai_seq_args[0]{'check_distance'} = abs($chars[$config{'char'}]{'pos_to'}{'x'} - $monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}{'x'}) + abs($chars[$config{'char'}]{'pos_to'}{'y'} - $monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}{'y'}) + 1;
			ai_route(\%{$ai_seq_args[0]{'ai_route_returnHash'}}, $monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}{'x'}, $monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}{'y'}, $field{'name'}, 0.1, $config{'attackMaxRouteTime'}, 0, 0);
                } elsif ((($config{'tankMode'} && $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'} == 0)
                        || !$config{'tankMode'})) {

                        if (!$ai_seq_args[0]{'startExp'}) {
                                $exp{'monster'}{'nameID'} = $monsters{$ai_seq_args[0]{'ID'}}{'nameID'};
                                $exp{'monster'}{'startTime'} = time;
                                $ai_seq_args[0]{'startExp'} = 1;
                                $exp{'base'}{'baseExp_get'} = 0;
                                $exp{'base'}{'jobExp_get'} = 0;
                        }
                        if ($ai_seq_args[0]{'attackMethod'}{'type'} eq "weapon" && timeOut(\%{$timeout{'ai_attack'}})) {
                                if ($config{'tankMode'} == 1) {
                                        sendAttack(\$remote_socket, $ai_seq_args[0]{'ID'}, 0);
                                } else {
                                        sendAttack(\$remote_socket, $ai_seq_args[0]{'ID'}, 7);
                                }
                                $timeout{'ai_attack'}{'time'} = time;
                                undef %{$ai_seq_args[0]{'attackMethod'}};
                        } elsif ($ai_seq_args[0]{'attackMethod'}{'type'} eq "skill") {
                                $ai_v{'ai_attack_method_skillSlot'} = $ai_seq_args[0]{'attackMethod'}{'skillSlot'};
                                if ($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_attackRoundMonster"}) {
                                        $ai_v{'ai_attack_ID'} = ai_getRoundSkillID($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_roundMonstersDist"});
                                        $ai_v{'ai_attack_ID'} = $ai_seq_args[0]{'ID'} if ($ai_v{'ai_attack_ID'} eq "");
                                } else {
                                        $ai_v{'ai_attack_ID'} = $ai_seq_args[0]{'ID'};
                                }
                                undef %{$ai_seq_args[0]{'attackMethod'}};
                                undef $timeout{'ai_attack'}{'time'};
                                ai_setSuspend(0);
                                mvpAttackAI();
                                if (!ai_getSkillUseType($skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})})) {
       	                                ai_skillUse($ai_v{'ai_attack_method_skillSlot_ID'}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_maxCastTime"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"}, $ai_v{'ai_attack_ID'});
               	                } else {
                      	                ai_skillUse($ai_v{'ai_attack_method_skillSlot_ID'}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_maxCastTime"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"}, $monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'x'}, $monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'y'});
                               	}
                                print qq~Auto-skill on monster: $skills_lut{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}} (lvl $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"})\n~ if ($config{'debug'});
                        }

                } elsif ($config{'tankMode'}) {
                        if ($ai_seq_args[0]{'dmgTo_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'}) {
                                $ai_seq_args[0]{'ai_attack_giveup'}{'time'} = time;
                        }
                        $ai_seq_args[0]{'dmgTo_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'};
                }
        }



	##### AUTO-EQUIP CHANGE #####
	
	if ($ai_seq[0] eq "equipAuto" && timeOut(1, $timeout{'ai_equip_auto_giveup'}{'time'})) {
		undef @{$ai_v{'temp'}{'selected'}};
		undef $ai_v{'temp'}{'found'};
		
		$i = 0;
		while (1) {
			last if (!$config{"autoSwitch_$ai_seq_args[0]{'index'}"."_equip_$i"});
			undef $invIndex;
			$invIndex = findIndexStringsNotSelected_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"autoSwitch_$ai_seq_args[0]{'index'}"."_equip_$i"}, \@{$ai_v{'temp'}{'selected'}});
			if ($invIndex ne "") {
				$ai_seq_args[0]{'solution'}[$i]{'invIndex'} = $invIndex;
				$ai_seq_args[0]{'solution'}[$i]{'equipped'} = $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'};
                                if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} == 10) {
                                        $ai_seq_args[0]{'solution'}[$i]{'type_equip'} = 32768;
				} else {
					$ai_seq_args[0]{'solution'}[$i]{'type_equip'} = $chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'};
				}
				if (!$ai_seq_args[0]{'solution'}[$i]{'equipped'}) {
					undef $invIndex;
					undef $invIndex2;
					if ($ai_seq_args[0]{'solution'}[$i]{'type_equip'} == 136) {
						$invIndex = findIndexStringsNotSelected_lc(\@{$chars[$config{'char'}]{'inventory'}}, "equipped", 8, \@{$ai_v{'temp'}{'selected'}});
						$invIndex2 = findIndexStringsNotSelected_lc(\@{$chars[$config{'char'}]{'inventory'}}, "equipped", 128, \@{$ai_v{'temp'}{'selected'}});
					} elsif ($ai_seq_args[0]{'solution'}[$i]{'type_equip'} == 2 && findIndexString(\@{$ai_seq_args[0]{'solution'}}, 'type_equip', 2) ne "") {
						$invIndex = findIndexStringsNotSelected_lc(\@{$chars[$config{'char'}]{'inventory'}}, "equipped", 32, \@{$ai_v{'temp'}{'selected'}});
					} else {
						$invIndex = findIndexStringsNotSelected_lc(\@{$chars[$config{'char'}]{'inventory'}}, "equipped", $ai_seq_args[0]{'solution'}[$i]{'type_equip'}, \@{$ai_v{'temp'}{'selected'}});
					}
					if ($invIndex ne "" && $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'solution'}[$i]{'invIndex'}]{'name'} eq $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}) {
						$ai_seq_args[0]{'solution'}[$i]{'invIndex'} = $invIndex;
                		                if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} == 10) {
		                                        $ai_seq_args[0]{'solution'}[$i]{'type_equip'} = 32768;
						} else {
							$ai_seq_args[0]{'solution'}[$i]{'type_equip'} = $chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'};
						}
						$ai_seq_args[0]{'solution'}[$i]{'equipped'} = $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'};
					} elsif ($invIndex2 ne "" && $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'solution'}[$i]{'invIndex'}]{'name'} eq $chars[$config{'char'}]{'inventory'}[$invIndex2]{'name'}) {
						$ai_seq_args[0]{'solution'}[$i]{'invIndex'} = $invIndex2;
						$ai_seq_args[0]{'solution'}[$i]{'type_equip'} = $chars[$config{'char'}]{'inventory'}[$invIndex2]{'type_equip'};
						$ai_seq_args[0]{'solution'}[$i]{'equipped'} = $chars[$config{'char'}]{'inventory'}[$invIndex2]{'equipped'};
					}
				}
	                        push @{$ai_v{'temp'}{'selected'}}, $ai_seq_args[0]{'solution'}[$i]{'invIndex'};
			}
			$i++;
		}

		for ($i = 0; $i < @{$ai_seq_args[0]{'solution'}}; $i++) {
			next if (!%{$ai_seq_args[0]{'solution'}[$i]});
			if ($ai_seq_args[0]{'solution'}[$i]{'type_equip'} == 2) {
				if (!$ai_v{'temp'}{'found'}) {
                                	$ai_seq_args[0]{'solution'}[$i]{'equipped'} = 2;
	                                $ai_v{'temp'}{'found'} = 1;
	                        } else {
	                        	$ai_seq_args[0]{'solution'}[$i]{'equipped'} = 32;
	                        }
                        } elsif ($ai_seq_args[0]{'solution'}[$i]{'type_equip'} == 136) {
                        	if (!$ai_seq_args[0]{'solution'}[$i]{'equipped'} && findIndexString(\@{$ai_seq_args[0]{'solution'}}, 'equipped', 8) eq "") {
                        		$ai_seq_args[0]{'solution'}[$i]{'equipped'} = 8;
                        	} elsif (!$ai_seq_args[0]{'solution'}[$i]{'equipped'}) {
                        		$ai_seq_args[0]{'solution'}[$i]{'equipped'} = 128;
                        	}
                        } else {
                        	$ai_seq_args[0]{'solution'}[$i]{'equipped'} = $ai_seq_args[0]{'solution'}[$i]{'type_equip'};
			}
			if ($ai_seq_args[0]{'solution'}[$i]{'equipped'} != $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'solution'}[$i]{'invIndex'}]{'equipped'}) {
				if ($chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'solution'}[$i]{'invIndex'}]{'equipped'}) {
					sendUnequip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'solution'}[$i]{'invIndex'}]{'index'});
				}
				sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'solution'}[$i]{'invIndex'}]{'index'}, $ai_seq_args[0]{'solution'}[$i]{'equipped'});
				$timeout{'ai_equip_auto_giveup'}{'time'} = time;
			}
		}
	        my $accIndex = findIndexStringsNotSelected_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'accessoryTeleport'});
	        my $invIndex = findIndexString(\@{$ai_seq_args[0]{'solution'}}, 'equipped', $chars[$config{'char'}]{'inventory'}[$accIndex]{'equipped'});
	        if ($accIndex ne "" && $invIndex ne "" && $accIndex ne $invIndex) {
	        	$ai_v{'temp'}{'teleport_tried'} = 3;
	        }
		shift @ai_seq;
		shift @ai_seq_args;
	}
	
	

        ##### SKILL USE #####


        if ($ai_seq[0] eq "skill_use" && $ai_seq_args[0]{'suspended'}) {
                $ai_seq_args[0]{'ai_skill_use_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
                $ai_seq_args[0]{'ai_skill_use_minCastTime'}{'time'} += time - $ai_seq_args[0]{'suspended'};
                $ai_seq_args[0]{'ai_skill_use_maxCastTime'}{'time'} += time - $ai_seq_args[0]{'suspended'};
                undef $ai_seq_args[0]{'suspended'};
        }
        if ($ai_seq[0] eq "skill_use") {
                if ($chars[$config{'char'}]{'sitting'}) {
                        ai_setSuspend(0);
                        stand();
                } elsif (!$ai_seq_args[0]{'skill_used'}) {
                        $ai_seq_args[0]{'skill_used'} = 1;
                        $ai_seq_args[0]{'ai_skill_use_giveup'}{'time'} = time;
                        if ($ai_seq_args[0]{'skill_use_target_x'} ne "") {                                       
                                sendSkillUseLoc(\$remote_socket, $ai_seq_args[0]{'skill_use_id'}, $ai_seq_args[0]{'skill_use_lv'}, $ai_seq_args[0]{'skill_use_target_x'}, $ai_seq_args[0]{'skill_use_target_y'});
                        } else {                                        
                                sendSkillUse(\$remote_socket, $ai_seq_args[0]{'skill_use_id'}, $ai_seq_args[0]{'skill_use_lv'}, $ai_seq_args[0]{'skill_use_target'});
                        }
                        $ai_seq_args[0]{'skill_use_last'} = $chars[$config{'char'}]{'skills_used'}{$skills_rlut{lc($skillsID_lut{$ai_seq_args[0]{'skill_use_id'}})}}{'time_used'};
                        if ($ai_seq_args[0]{'skill_use_id'} == 290 && $config{'randomSkillAuto'} == 1) {
              	                sendSkillUse(\$remote_socket, 292, $ai_seq_args[0]{'skill_use_lv'}, $ai_seq_args[0]{'skill_use_target'});
              	                $chars[$config{'char'}]{'randomSkill_send_time'} = time;
                        } elsif ($ai_seq_args[0]{'skill_use_id'} == 290 && $config{'randomSkillAuto'} == 2) {
              	                sendSkillUse(\$remote_socket, 297, $ai_seq_args[0]{'skill_use_lv'}, $ai_seq_args[0]{'skill_use_target'});
       	                        sendCatch(\$remote_socket, $ai_seq_args[0]{'skill_use_target'});
              	                $chars[$config{'char'}]{'randomSkill_send_time'} = time;
                        }
                } elsif (($ai_seq_args[0]{'skill_use_last'} != $chars[$config{'char'}]{'skills_used'}{$skills_rlut{lc($skillsID_lut{$ai_seq_args[0]{'skill_use_id'}})}}{'time_used'}
                        || (timeOut(\%{$ai_seq_args[0]{'ai_skill_use_giveup'}}) && (!$chars[$config{'char'}]{'time_cast'} || !$ai_seq_args[0]{'skill_use_maxCastTime'}{'timeout'}))
                        || ($ai_seq_args[0]{'skill_use_maxCastTime'}{'timeout'} && timeOut(\%{$ai_seq_args[0]{'skill_use_maxCastTime'}})))
                        && timeOut(\%{$ai_seq_args[0]{'skill_use_minCastTime'}})) {
                        shift @ai_seq;
                        shift @ai_seq_args;
                        $timeout{'ai_sit_wait'}{'time'} = time;
                }
        }


        ##### ROUTE #####

        ROUTE: {

        if ($ai_seq[0] eq "route" && @{$ai_seq_args[0]{'solution'}} && $ai_seq_args[0]{'index'} == @{$ai_seq_args[0]{'solution'}} - 1 && $ai_seq_args[0]{'solutionReady'}) {
                print "Route success\n" if $config{'debug'};
                shift @ai_seq;
                shift @ai_seq_args;
                undef $ai_v{'route_failed'};

        } elsif ($ai_seq[0] eq "route" && $ai_seq_args[0]{'failed'}) {
                print "Route failed\n" if $config{'debug'};
                shift @ai_seq;
                shift @ai_seq_args;
                ($map_string) = $map_name =~ /([\s\S]*)\.gat/;
                if (!$indoors_lut{$map_string.'.rsw'}) {
                        if ($ai_v{'route_failed'} == 10 || $ai_v{'route_failed'} == 15 || $ai_v{'route_failed'} == 20) {
                                printc(1, "yr", "<系统> ", "计算路线失败$ai_v{'route_failed'}次，瞬移1级\n");
                                chatLog("x", "计算路线失败$ai_v{'route_failed'}次，瞬移1级\n");
                                useTeleport(1);
                        } elsif ($ai_v{'route_failed'} >= 25) {
                                printc(1, "yr", "<系统> ", "计算路线失败$ai_v{'route_failed'}次，瞬移2级\n");
                                chatLog("x", "计算路线失败$ai_v{'route_failed'}次，瞬移2级\n");
                                undef $ai_v{'route_failed'};
                                useTeleport(2);
                                ai_clientSuspend(0,2);
                                $ai_v{'clear_aiQueue'} = 1;
                        }
                } elsif ($ai_v{'route_failed'} >= 25) {
                        printc(1, "yr", "<系统> ", "室内计算路线失败$ai_v{'route_failed'}次，断线3600秒\n");
                        chatLog("x", "室内计算路线失败$ai_v{'route_failed'}次，断线3600秒\n");
                        undef $ai_v{'route_failed'};
                        $ai_v{'clear_aiQueue'} = 1;
        	        $conState = 1;
	                undef $conState_tries;
                	$timeout_ex{'master'}{'time'} = time;
        	        $timeout_ex{'master'}{'timeout'} = 3600;
	                killConnection(\$remote_socket) if (!$xKore);
                }

        } elsif ($ai_seq[0] eq "route" && timeOut(\%{$timeout{'ai_route_npcTalk'}})) {
                last ROUTE if (!$field{'name'});
                if ($ai_seq_args[0]{'waitingForMapSolution'}) {
                        undef $ai_seq_args[0]{'waitingForMapSolution'};
                        if (!@{$ai_seq_args[0]{'mapSolution'}}) {
                                $ai_seq_args[0]{'failed'} = 1;
                		$ai_v{'route_failed'}++;
                                last ROUTE;
                        }
                        $ai_seq_args[0]{'mapIndex'} = -1;
                }
                if ($ai_seq_args[0]{'waitingForSolution'}) {
                        undef $ai_seq_args[0]{'waitingForSolution'};
                        if ($ai_seq_args[0]{'distFromGoal'} && $field{'name'} && $ai_seq_args[0]{'dest_map'} eq $field{'name'}
                                && (!@{$ai_seq_args[0]{'mapSolution'}} || $ai_seq_args[0]{'mapIndex'} == @{$ai_seq_args[0]{'mapSolution'}} - 1)) {
                                for ($i = 0; $i < $ai_seq_args[0]{'distFromGoal'}; $i++) {
                                        pop @{$ai_seq_args[0]{'solution'}};
                                }
                                if (@{$ai_seq_args[0]{'solution'}}) {
                                        $ai_seq_args[0]{'dest_x_original'} = $ai_seq_args[0]{'dest_x'};
                                        $ai_seq_args[0]{'dest_y_original'} = $ai_seq_args[0]{'dest_y'};
                                        $ai_seq_args[0]{'dest_x'} = $ai_seq_args[0]{'solution'}[@{$ai_seq_args[0]{'solution'}}-1]{'x'};
                                        $ai_seq_args[0]{'dest_y'} = $ai_seq_args[0]{'solution'}[@{$ai_seq_args[0]{'solution'}}-1]{'y'};
                                }
                        }
                        $ai_seq_args[0]{'returnHash'}{'solutionLength'} = @{$ai_seq_args[0]{'solution'}};
                        $ai_seq_args[0]{'returnHash'}{'solutionTime'} = time - $ai_seq_args[0]{'time_getRoute'};
                        print "Route to $ai_seq_args[0]{'dest_x'}, $ai_seq_args[0]{'dest_y'} Length $ai_seq_args[0]{'returnHash'}{'solutionLength'} Time ".int($ai_seq_args[0]{'returnHash'}{'solutionTime'} * 1000)." ms\n" if $config{'debug'};
                        if ($ai_seq_args[0]{'maxRouteDistance'} && @{$ai_seq_args[0]{'solution'}} > $ai_seq_args[0]{'maxRouteDistance'}) {
                                $ai_seq_args[0]{'failed'} = 1;
                                last ROUTE;
                        }
                        if (!@{$ai_seq_args[0]{'solution'}} && !@{$ai_seq_args[0]{'mapSolution'}} && $ai_seq_args[0]{'dest_map'} eq $field{'name'} && $ai_seq_args[0]{'checkInnerPortals'} && !$ai_seq_args[0]{'checkInnerPortals_done'}) {
                                $ai_seq_args[0]{'checkInnerPortals_done'} = 1;
                                undef $ai_seq_args[0]{'solutionReady'};
                                $ai_seq_args[0]{'temp'}{'pos'}{'x'} = $ai_seq_args[0]{'dest_x'};
                                $ai_seq_args[0]{'temp'}{'pos'}{'y'} = $ai_seq_args[0]{'dest_y'};
                                $ai_seq_args[0]{'waitingForMapSolution'} = 1;
                                ai_mapRoute_getRoute(\@{$ai_seq_args[0]{'mapSolution'}}, \%field, \%{$chars[$config{'char'}]{'pos_to'}}, \%field, \%{$ai_seq_args[0]{'temp'}{'pos'}}, $ai_seq_args[0]{'maxRouteTime'});
                                last ROUTE;
                        } elsif (!@{$ai_seq_args[0]{'solution'}}) {
                                $ai_seq_args[0]{'failed'} = 1;
                                $ai_v{'route_failed'}++;
                                last ROUTE;
                        }
                }
                if (@{$ai_seq_args[0]{'mapSolution'}} && $ai_seq_args[0]{'mapChanged'} && $field{'name'} eq $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'dest'}{'map'}) {
                        undef $ai_seq_args[0]{'mapChanged'};
                        undef @{$ai_seq_args[0]{'solution'}};
                        undef %{$ai_seq_args[0]{'last_pos'}};
                        undef $ai_seq_args[0]{'index'};
                        undef $ai_seq_args[0]{'npc'};
                        undef $ai_seq_args[0]{'divideIndex'};
                }
                if (!@{$ai_seq_args[0]{'solution'}}) {
                        if ($ai_seq_args[0]{'dest_map'} eq $field{'name'}
                                && (!@{$ai_seq_args[0]{'mapSolution'}} || $ai_seq_args[0]{'mapIndex'} == @{$ai_seq_args[0]{'mapSolution'}} - 1)) {
                                $ai_seq_args[0]{'temp'}{'dest'}{'x'} = $ai_seq_args[0]{'dest_x'};
                                $ai_seq_args[0]{'temp'}{'dest'}{'y'} = $ai_seq_args[0]{'dest_y'};
                                $ai_seq_args[0]{'solutionReady'} = 1;
                                undef @{$ai_seq_args[0]{'mapSolution'}};
                                undef $ai_seq_args[0]{'mapIndex'};
                        } else {
                                if (!(@{$ai_seq_args[0]{'mapSolution'}})) {
                                        if (!%{$ai_seq_args[0]{'dest_field'}}) {
                                                getField("map/$ai_seq_args[0]{'dest_map'}.fld", \%{$ai_seq_args[0]{'dest_field'}});
                                        }
                                        $ai_seq_args[0]{'temp'}{'pos'}{'x'} = $ai_seq_args[0]{'dest_x'};
                                        $ai_seq_args[0]{'temp'}{'pos'}{'y'} = $ai_seq_args[0]{'dest_y'};
                                        $ai_seq_args[0]{'waitingForMapSolution'} = 1;
                                        ai_mapRoute_getRoute(\@{$ai_seq_args[0]{'mapSolution'}}, \%field, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'dest_field'}}, \%{$ai_seq_args[0]{'temp'}{'pos'}}, $ai_seq_args[0]{'maxRouteTime'});
                                        last ROUTE;
                                }
                                if (!defined $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'} + 1]{'source'}{'map'}) {
                                        $ai_seq_args[0]{'failed'} = 1;
                                        $ai_v{'route_failed'}++;
                                        last ROUTE;
                                }

                                if ($field{'name'} eq $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'} + 1]{'source'}{'map'}) {
                                        $ai_seq_args[0]{'mapIndex'}++;
                                        %{$ai_seq_args[0]{'temp'}{'dest'}} = %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'pos'}};
                                } else {
                                        %{$ai_seq_args[0]{'temp'}{'dest'}} = %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'pos'}};
                                }
                        }
                        if ($ai_seq_args[0]{'temp'}{'dest'}{'x'} eq "") {
                                $ai_seq_args[0]{'failed'} = 1;
                                last ROUTE;
                        }
                        $ai_seq_args[0]{'waitingForSolution'} = 1;
                        $ai_seq_args[0]{'time_getRoute'} = time;
                        ai_route_getRoute(\@{$ai_seq_args[0]{'solution'}}, \%field, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'temp'}{'dest'}}, $ai_seq_args[0]{'maxRouteTime'});
                        last ROUTE;
                }
                if (@{$ai_seq_args[0]{'mapSolution'}} && @{$ai_seq_args[0]{'solution'}} && $ai_seq_args[0]{'index'} == @{$ai_seq_args[0]{'solution'}} - 1
                        && %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}}) {
                        if ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] ne "") {
                                $ai_v{'temp'}{'talk_npc'} = ai_getTalkID(pack("L1",$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}));
                                if (binFind(\@npcsID, $ai_v{'temp'}{'talk_npc'}) eq "") {
                                        $ai_seq_args[0]{'failed'} = 1;
                                        last ROUTE;
                                } elsif (!$ai_seq_args[0]{'npc'}{'sentTalk'}) {
                                        sendTalk(\$remote_socket, pack("L1",$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}));
                                        $ai_seq_args[0]{'npc'}{'sentTalk'} = 1;
                                } elsif ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /c/i) {
                                               sendTalkContinue(\$remote_socket, pack("L1",$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}));
                                               $ai_seq_args[0]{'npc'}{'step'}++;
                                } elsif ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /n/i) {
                                               sendTalkCancel(\$remote_socket, pack("L1",$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}));
                                               $ai_seq_args[0]{'npc'}{'step'}++;
                                } else {
                                        ($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i;
                                        if ($ai_v{'temp'}{'arg'} ne "") {
                                                $ai_v{'temp'}{'arg'}++;
                                                sendTalkResponse(\$remote_socket, pack("L1",$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}), $ai_v{'temp'}{'arg'});
                                        }
                                        $ai_seq_args[0]{'npc'}{'step'}++;
                                }
                                if ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] ne "") {
                                        $timeout{'ai_route_npcTalk'}{'time'} = time;
                                } else {
                                        $timeout{'ai_route_npcTalk'}{'time'} = time + 2;
                                }
                                last ROUTE;
                        } elsif (!$ai_seq_args[0]{'mapChanged'}) {
                                $ai_seq_args[0]{'failed'} = 1;
                                last ROUTE;
                        }
                }
                if ($ai_seq_args[0]{'mapChanged'}) {
                        $ai_seq_args[0]{'failed'} = 1;
                        last ROUTE;

                } elsif (%{$ai_seq_args[0]{'last_pos'}}
                        && $chars[$config{'char'}]{'pos_to'}{'x'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}
                        && $chars[$config{'char'}]{'pos_to'}{'y'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'}
                        && $ai_seq_args[0]{'last_pos'}{'x'} != $chars[$config{'char'}]{'pos_to'}{'x'}
                        && $ai_seq_args[0]{'last_pos'}{'y'} != $chars[$config{'char'}]{'pos_to'}{'y'}) {

                        if ($ai_seq_args[0]{'dest_x_original'} ne "") {
                                $ai_seq_args[0]{'dest_x'} = $ai_seq_args[0]{'dest_x_original'};
                                $ai_seq_args[0]{'dest_y'} = $ai_seq_args[0]{'dest_y_original'};
                        }
                        undef @{$ai_seq_args[0]{'solution'}};
                        undef %{$ai_seq_args[0]{'last_pos'}};
                        undef $ai_seq_args[0]{'index'};
                        undef $ai_seq_args[0]{'npc'};
                        undef $ai_seq_args[0]{'divideIndex'};

                } else {
                        if ($ai_seq_args[0]{'divideIndex'} && $chars[$config{'char'}]{'pos_to'}{'x'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}
                                && $chars[$config{'char'}]{'pos_to'}{'y'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'}) {

                                #we're stuck!
                                $ai_v{'temp'}{'index_old'} = $ai_seq_args[0]{'index'};
                                $ai_seq_args[0]{'index'} -= int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'});
                                $ai_seq_args[0]{'index'} = 0 if ($ai_seq_args[0]{'index'} < 0);
                                $ai_v{'temp'}{'index'} = $ai_seq_args[0]{'index'};
                                undef $ai_v{'temp'}{'done'};
                                do {
                                        $ai_seq_args[0]{'divideIndex'}++;
                                        $ai_v{'temp'}{'index'} = $ai_seq_args[0]{'index'};
                                        $ai_v{'temp'}{'index'} += int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'});
                                        $ai_v{'temp'}{'index'} = @{$ai_seq_args[0]{'solution'}} - 1 if ($ai_v{'temp'}{'index'} >= @{$ai_seq_args[0]{'solution'}});
                                        $ai_v{'temp'}{'done'} = 1 if (int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'}) == 0);
                                } while ($ai_v{'temp'}{'index'} >= $ai_v{'temp'}{'index_old'} && !$ai_v{'temp'}{'done'});
                        } else {
                                $ai_seq_args[0]{'divideIndex'} = 1;
                        }


                        if (int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'}) == 0) {
                                $ai_seq_args[0]{'failed'} = 1;
                                last ROUTE;
                        }

                        %{$ai_seq_args[0]{'last_pos'}} = %{$chars[$config{'char'}]{'pos_to'}};

                        do {
                                $ai_seq_args[0]{'index'} += int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'});
                                $ai_seq_args[0]{'index'} = @{$ai_seq_args[0]{'solution'}} - 1 if ($ai_seq_args[0]{'index'} >= @{$ai_seq_args[0]{'solution'}});
                        } while ($ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'} == $chars[$config{'char'}]{'pos_to'}{'x'}
                                && $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'} == $chars[$config{'char'}]{'pos_to'}{'y'}
                                && $ai_seq_args[0]{'index'} != @{$ai_seq_args[0]{'solution'}} - 1);

			if (!defined $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}	|| !defined $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'}) {
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}

                        if ($ai_seq_args[0]{'avoidPortals'}) {
                                $ai_v{'temp'}{'first'} = 1;
                                undef $ai_v{'temp'}{'foundID'};
                                undef $ai_v{'temp'}{'smallDist'};
                                foreach (@portalsID) {
                                        $ai_v{'temp'}{'dist'} = distance(\%{$ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]}, \%{$portals{$_}{'pos'}});
                                        if ($ai_v{'temp'}{'dist'} <= 7 && ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'})) {
                                                $ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
                                                $ai_v{'temp'}{'foundID'} = $_;
                                                undef $ai_v{'temp'}{'first'};
                                        }
                                }
                                if ($ai_v{'temp'}{'foundID'}) {
                                        $ai_seq_args[0]{'failed'} = 1;
                                        last ROUTE;
                                }
                        }
                        if ($config{'teleportAuto_maxRouteDistance'} && $ai_seq_args[0]{'returnHash'}{'solutionLength'} > $config{'teleportAuto_maxRouteDistance'} && $config{'lockMap'} ne ""
                                && (($config{'lockMap_routeType'} == 1 && !$cities_lut{$field{'name'}.'.rsw'}) || ($config{'lockMap_routeType'} == 2 && !$indoors_lut{$field{'name'}.'.rsw'}))
                                && binFind(\@ai_seq, "healAuto") eq "" && binFind(\@ai_seq, "buyAuto") eq "" && binFind(\@ai_seq, "sellAuto") eq "" && binFind(\@ai_seq, "storageAuto") eq "" && binFind(\@ai_seq, "attack") eq "") {
                                printc(1, "wr", "<瞬移> ", "移动到地图转换点需要$ai_seq_args[0]{'returnHash'}{'solutionLength'}格\n");
                                useTeleport(1);
                        }
                        if ($ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'} != $chars[$config{'char'}]{'pos_to'}{'x'}
                                || $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'} != $chars[$config{'char'}]{'pos_to'}{'y'}) {
                                move($ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}, $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'});
                                undef $ai_v{'route_failed'};
                        }
                }
        }

        } #END OF ROUTE BLOCK


        ##### ROUTE_GETROUTE #####

        if ($ai_seq[0] eq "route_getRoute" && $ai_seq_args[0]{'suspended'}) {
                $ai_seq_args[0]{'time_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
                undef $ai_seq_args[0]{'suspended'};
        }
        if ($ai_seq[0] eq "route_getRoute" && ($ai_seq_args[0]{'done'} || $ai_seq_args[0]{'mapChanged'}
                || ($ai_seq_args[0]{'time_giveup'}{'timeout'} && timeOut(\%{$ai_seq_args[0]{'time_giveup'}})))) {
                $timeout{'ai_route_calcRoute_cont'}{'time'} -= $timeout{'ai_route_calcRoute_cont'}{'timeout'};
                ai_route_getRoute_destroy(\%{$ai_seq_args[0]});
                shift @ai_seq;
                shift @ai_seq_args;

        } elsif ($ai_seq[0] eq "route_getRoute" && timeOut(\%{$timeout{'ai_route_calcRoute_cont'}})) {
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
                        $ai_seq_args[0]{'timeout'} = $timeout{'ai_route_calcRoute'}{'timeout'}*1000;
                }
                $ai_seq_args[0]{'init'} = 1;
                ai_route_searchStep(\%{$ai_seq_args[0]});
                $timeout{'ai_route_calcRoute_cont'}{'time'} = time;
                ai_setSuspend(0);
        }

        ##### ROUTE_GETMAPROUTE #####

        ROUTE_GETMAPROUTE: {

        if ($ai_seq[0] eq "route_getMapRoute" && $ai_seq_args[0]{'suspended'}) {
                $ai_seq_args[0]{'time_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
                undef $ai_seq_args[0]{'suspended'};
        }
        if ($ai_seq[0] eq "route_getMapRoute" && ($ai_seq_args[0]{'done'} || $ai_seq_args[0]{'mapChanged'}
                || ($ai_seq_args[0]{'time_giveup'}{'timeout'} && timeOut(\%{$ai_seq_args[0]{'time_giveup'}})))) {
                $timeout{'ai_route_calcRoute_cont'}{'time'} -= $timeout{'ai_route_calcRoute_cont'}{'timeout'};
                shift @ai_seq;
                shift @ai_seq_args;

        } elsif ($ai_seq[0] eq "route_getMapRoute" && timeOut(\%{$timeout{'ai_route_calcRoute_cont'}})) {
                if (!%{$ai_seq_args[0]{'start'}}) {
                        %{$ai_seq_args[0]{'start'}{'dest'}{'pos'}} = %{$ai_seq_args[0]{'r_start_pos'}};
                        $ai_seq_args[0]{'start'}{'dest'}{'map'} = $ai_seq_args[0]{'r_start_field'}{'name'};
                        $ai_seq_args[0]{'start'}{'dest'}{'field'} = $ai_seq_args[0]{'r_start_field'};
                        %{$ai_seq_args[0]{'dest'}{'source'}{'pos'}} = %{$ai_seq_args[0]{'r_dest_pos'}};
                        $ai_seq_args[0]{'dest'}{'source'}{'map'} = $ai_seq_args[0]{'r_dest_field'}{'name'};
                        $ai_seq_args[0]{'dest'}{'source'}{'field'} = $ai_seq_args[0]{'r_dest_field'};
                        push @{$ai_seq_args[0]{'openList'}}, \%{$ai_seq_args[0]{'start'}};
                }
                $timeout{'ai_route_calcRoute'}{'time'} = time;
                while (!$ai_seq_args[0]{'done'} && !timeOut(\%{$timeout{'ai_route_calcRoute'}})) {
                        ai_mapRoute_searchStep(\%{$ai_seq_args[0]});
                        last ROUTE_GETMAPROUTE if ($ai_seq[0] ne "route_getMapRoute");
                }

		if ($ai_seq_args[0]{'done'}) {
			@{$ai_seq_args[0]{'returnArray'}} = @{$ai_seq_args[0]{'solutionList'}};
		}
                if ($config{'mode'} >= 2 && @{$ai_seq_args[0]{'returnArray'}}) {
                       	$ai_seq_args[0]{'map_list'} = $ai_seq_args[0]{'returnArray'}[0]{'source'}{'map'};
                       	for (my $i=0;$i < @{$ai_seq_args[0]{'returnArray'}};$i++) {
                       		$ai_seq_args[0]{'map_list'} .= ','.$ai_seq_args[0]{'returnArray'}[$i]{'dest'}{'map'};
                       	}
                      	printc(1, "yw", "<系统> ", "地图路线: $ai_seq_args[0]{'map_list'}\n");
                }
                $timeout{'ai_route_calcRoute_cont'}{'time'} = time;
                ai_setSuspend(0);
        }

        } #End of block ROUTE_GETMAPROUTE



        ##### ITEMS IMPORTANT #####

        if ($ai_seq[0] eq "items_important" && !%{$items{$ai_seq_args[0]{'ID'}}}) {
               	$ai_v{'temp'}{'ID'} = $ai_seq_args[0]{'ID'};
                shift @ai_seq;
                shift @ai_seq_args;
                if ($accountID eq $items_old{$ai_v{'temp'}{'ID'}}{'takenBy'}) {
                
	        } elsif (%{$players{$items_old{$ai_v{'temp'}{'ID'}}{'takenBy'}}}) {
                        printc("wr", "<信息> ", "捡取: $items_old{$ai_v{'temp'}{'ID'}}{'name'} - $players{$items_old{$ai_v{'temp'}{'ID'}}{'takenBy'}}{'name'} $sex_lut{$players{$items_old{$ai_v{'temp'}{'ID'}}{'takenBy'}}{'sex'}} $jobs_lut{$players{$items_old{$ai_v{'temp'}{'ID'}}{'takenBy'}}{'jobID'}}\n");
                        chatLog("i", "捡取: $items_old{$ai_v{'temp'}{'ID'}}{'name'} - $players{$items_old{$ai_v{'temp'}{'ID'}}{'takenBy'}}{'name'} $sex_lut{$players{$items_old{$ai_v{'temp'}{'ID'}}{'takenBy'}}{'sex'}} $jobs_lut{$players{$items_old{$ai_v{'temp'}{'ID'}}{'takenBy'}}{'jobID'}}\n");
                } elsif (%{$players_old{$items_old{$ai_v{'temp'}{'ID'}}{'takenBy'}}}) {
                        printc("wr", "<信息> ", "捡取: $items_old{$ai_v{'temp'}{'ID'}}{'name'} - $players_old{$items_old{$ai_v{'temp'}{'ID'}}{'takenBy'}}{'name'} $sex_lut{$players{$items_old{$ai_v{'temp'}{'ID'}}{'takenBy'}}{'sex'}} $jobs_lut{$players{$items_old{$ai_v{'temp'}{'ID'}}{'takenBy'}}{'jobID'}}\n");
                        chatLog("i", "捡取: $items_old{$ai_v{'temp'}{'ID'}}{'name'} - $players_old{$items_old{$ai_v{'temp'}{'ID'}}{'takenBy'}}{'name'} $sex_lut{$players{$items_old{$ai_v{'temp'}{'ID'}}{'takenBy'}}{'sex'}} $jobs_lut{$players{$items_old{$ai_v{'temp'}{'ID'}}{'takenBy'}}{'jobID'}}\n");
                } elsif ($config{'pickupMonsters'}) {
                        foreach (@monstersID) {
                                next if ($_ eq "" || !existsInList($config{'pickupMonsters'}, $monsters{$_}{'name'}));
                                $ai_v{'temp'}{'dist'} = distance(\%{$items_old{$ai_v{'temp'}{'ID'}}{'pos'}}, \%{$monsters{$_}{'pos_to'}});
                                if ($ai_v{'temp'}{'dist'} < 3) {
              	                        ai_setSuspend(0);
		                        chatLog("i", "攻击: $monsters{$_}{'name'}($monsters{$_}{'binID'})\n");
              	                        attack($_);
              	                }
                        }
                }
        } elsif ($ai_seq[0] eq "items_important") {
                $ai_v{'temp'}{'dist'} = distance(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
                if ($chars[$config{'char'}]{'sitting'}) {
                        stand();
                } elsif ($ai_v{'temp'}{'dist'} >= 2) {
                        getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
                        moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'temp'}{'dist'} - 1);
                        move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
                } else {
                        sendTake(\$remote_socket, $ai_seq_args[0]{'ID'});
                }
        }



        ##### ITEMS TAKE #####


        if ($ai_seq[0] eq "items_take" && $ai_seq_args[0]{'suspended'}) {
                $ai_seq_args[0]{'ai_items_take_start'}{'time'} += time - $ai_seq_args[0]{'suspended'};
                $ai_seq_args[0]{'ai_items_take_end'}{'time'} += time - $ai_seq_args[0]{'suspended'};
                undef $ai_seq_args[0]{'suspended'};
        }
        if ($ai_seq[0] eq "items_take" && (percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'})) {
                shift @ai_seq;
                shift @ai_seq_args;
                ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
        }
        if ($config{'itemsTakeAuto'} && $ai_seq[0] eq "items_take" && timeOut(\%{$ai_seq_args[0]{'ai_items_take_start'}})) {
                undef $ai_v{'temp'}{'foundID'};
                foreach (@itemsID) {
                        next if ($_ eq "" || $itemsPickup{lc($items{$_}{'name'})} eq "0" || (!$itemsPickup{'all'} && !$itemsPickup{lc($items{$_}{'name'})}));
                        $ai_v{'temp'}{'dist'} = distance(\%{$items{$_}{'pos'}}, \%{$ai_seq_args[0]{'pos'}});
                        $ai_v{'temp'}{'dist_to'} = distance(\%{$items{$_}{'pos'}}, \%{$ai_seq_args[0]{'pos_to'}});
                        if (($ai_v{'temp'}{'dist'} <= 4 || $ai_v{'temp'}{'dist_to'} <= 4) && $items{$_}{'take_failed'} == 0) {
                                $ai_v{'temp'}{'foundID'} = $_;
                                last;
                        }
                }
                if ($ai_v{'temp'}{'foundID'}) {
                        $ai_seq_args[0]{'ai_items_take_end'}{'time'} = time;
                        $ai_seq_args[0]{'started'} = 1;
                        take($ai_v{'temp'}{'foundID'});
                } elsif ($ai_seq_args[0]{'started'} || timeOut(\%{$ai_seq_args[0]{'ai_items_take_end'}})) {
                        shift @ai_seq;
                        shift @ai_seq_args;
                        ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
                }
        }



        ##### ITEMS AUTO-GATHER #####


        if (($ai_seq[0] eq "" || $ai_seq[0] eq "follow" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute") && $config{'itemsGatherAuto'} && !(percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'}) && timeOut(\%{$timeout{'ai_items_gather_auto'}})) {
                undef @{$ai_v{'ai_items_gather_foundIDs'}};
                foreach (@playersID) {
                        next if ($_ eq "");
                        if (!%{$chars[$config{'char'}]{'party'}} || !%{$chars[$config{'char'}]{'party'}{'users'}{$_}}) {
                                push @{$ai_v{'ai_items_gather_foundIDs'}}, $_;
                        }
                }
                foreach $item (@itemsID) {
                        next if ($item eq "" || time - $items{$item}{'appear_time'} < $timeout{'ai_items_gather_start'}{'timeout'}
                                || $items{$item}{'take_failed'} >= 1
                                || $itemsPickup{lc($items{$item}{'name'})} eq "0" || (!$itemsPickup{'all'} && !$itemsPickup{lc($items{$item}{'name'})}));
                        undef $ai_v{'temp'}{'dist'};
                        undef $ai_v{'temp'}{'found'};
                        foreach (@{$ai_v{'ai_items_gather_foundIDs'}}) {
                                $ai_v{'temp'}{'dist'} = distance(\%{$items{$item}{'pos'}}, \%{$players{$_}{'pos_to'}});
                                if ($ai_v{'temp'}{'dist'} < 9) {
                                        $ai_v{'temp'}{'found'} = 1;
                                        last;
                                }
                        }
                        if ($ai_v{'temp'}{'found'} == 0) {
                                gather($item);
                                last;
                        }
                }
                $timeout{'ai_items_gather_auto'}{'time'} = time;
        }



        ##### ITEMS GATHER #####


        if ($ai_seq[0] eq "items_gather" && $ai_seq_args[0]{'suspended'}) {
                $ai_seq_args[0]{'ai_items_gather_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
                undef $ai_seq_args[0]{'suspended'};
        }
        if ($ai_seq[0] eq "items_gather" && !%{$items{$ai_seq_args[0]{'ID'}}}) {
                printc("wn", "<信息> ", "无法收集物品 $items_old{$ai_seq_args[0]{'ID'}}{'name'} : 目标丢失\n");
                shift @ai_seq;
                shift @ai_seq_args;
        } elsif ($ai_seq[0] eq "items_gather") {
                undef $ai_v{'temp'}{'dist'};
                undef @{$ai_v{'ai_items_gather_foundIDs'}};
                undef $ai_v{'temp'}{'found'};
                foreach (@playersID) {
                        next if ($_ eq "");
                        if (%{$chars[$config{'char'}]{'party'}} && !%{$chars[$config{'char'}]{'party'}{'users'}{$_}}) {
                                push @{$ai_v{'ai_items_gather_foundIDs'}}, $_;
                        }
                }
                foreach (@{$ai_v{'ai_items_gather_foundIDs'}}) {
                        $ai_v{'temp'}{'dist'} = distance(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$players{$_}{'pos'}});
                        if ($ai_v{'temp'}{'dist'} < 9) {
                                $ai_v{'temp'}{'found'}++;
                        }
                }
                $ai_v{'temp'}{'dist'} = distance(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
                if (timeOut(\%{$ai_seq_args[0]{'ai_items_gather_giveup'}})) {
                        printc("wn", "<信息> ", "无法收集物品 $items{$ai_seq_args[0]{'ID'}}{'name'} : 超时\n");
                        $items{$ai_seq_args[0]{'ID'}}{'take_failed'}++;
                        shift @ai_seq;
                        shift @ai_seq_args;
                } elsif ($chars[$config{'char'}]{'sitting'}) {
                        ai_setSuspend(0);
                        stand();
                } elsif ($ai_v{'temp'}{'found'} == 0 && $ai_v{'temp'}{'dist'} > 2) {
                        getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
                        moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'temp'}{'dist'} - 1);
                        move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
                } elsif ($ai_v{'temp'}{'found'} == 0) {
                        $ai_v{'ai_items_gather_ID'} = $ai_seq_args[0]{'ID'};
                        shift @ai_seq;
                        shift @ai_seq_args;
                        take($ai_v{'ai_items_gather_ID'});
                } elsif ($ai_v{'temp'}{'found'} > 0) {
                        printc("wn", "<信息> ", "无法收集物品 $items{$ai_seq_args[0]{'ID'}}{'name'} : 无法捡取\n");
                        shift @ai_seq;
                        shift @ai_seq_args;
                }
        }



        ##### TAKE #####


        if ($ai_seq[0] eq "take" && $ai_seq_args[0]{'suspended'}) {
                $ai_seq_args[0]{'ai_take_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
                undef $ai_seq_args[0]{'suspended'};
        }
        if ($ai_seq[0] eq "take" && !%{$items{$ai_seq_args[0]{'ID'}}}) {
                shift @ai_seq;
                shift @ai_seq_args;
        } elsif ($ai_seq[0] eq "take" && timeOut(\%{$ai_seq_args[0]{'ai_take_giveup'}})) {
                printc("wn", "<信息> ", "无法捡取物品 $items{$ai_seq_args[0]{'ID'}}{'name'}\n") if ($config{'mode'});
                $items{$ai_seq_args[0]{'ID'}}{'take_failed'}++;
                shift @ai_seq;
                shift @ai_seq_args;
        } elsif ($ai_seq[0] eq "take") {

                $ai_v{'temp'}{'dist'} = distance(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
                if ($chars[$config{'char'}]{'sitting'}) {
                        stand();
                } elsif ($ai_v{'temp'}{'dist'} >= 2) {
                        getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
                        moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'temp'}{'dist'} - 1);
                        move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
                } elsif (timeOut(\%{$timeout{'ai_take'}})) {
                        sendTake(\$remote_socket, $ai_seq_args[0]{'ID'});
                        $timeout{'ai_take'}{'time'} = time;
                }
        }


        ##### MOVE #####


        if ($ai_seq[0] eq "move" && $ai_seq_args[0]{'suspended'}) {
                $ai_seq_args[0]{'ai_move_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
                undef $ai_seq_args[0]{'suspended'};
        }
        if ($ai_seq[0] eq "move") {
                if (!$ai_seq_args[0]{'ai_moved'} && $ai_seq_args[0]{'ai_moved_tried'} && $ai_seq_args[0]{'ai_move_time_last'} != $chars[$config{'char'}]{'time_move'}) {
                        $ai_seq_args[0]{'ai_moved'} = 1;
                }
                if ($chars[$config{'char'}]{'sitting'}) {
                        ai_setSuspend(0);
                        stand();
                } elsif (!$ai_seq_args[0]{'ai_moved'} && timeOut(\%{$ai_seq_args[0]{'ai_move_giveup'}})) {
                        $ai_v{'move_failed'}++;
                        shift @ai_seq;
                        shift @ai_seq_args;
                        if ($ai_v{'move_failed'} == 10 || $ai_v{'move_failed'} == 15) {
                                printc(1, "yr", "<系统> ", "移动失败$ai_v{'move_failed'}次，重新计算路线\n");
                                chatLog("x", "移动失败$ai_v{'move_failed'}次，重新计算路线\n");
                                $ai_v{'move_failed'}++;
                                aiRemove("move");
                                aiRemove("route");
                                aiRemove("route_getRoute");
                                aiRemove("route_getMapRoute");
                        } elsif ($ai_v{'move_failed'} >= 20) {
                                printc(1, "yr", "<系统> ", "移动失败$ai_v{'move_failed'}次，瞬移1级\n");
                                chatLog("x", "移动失败$ai_v{'move_failed'}次，瞬移1级\n");
                                undef $ai_v{'move_failed'};
                                useTeleport(1);
                        }
                } elsif (!$ai_seq_args[0]{'ai_moved_tried'}) {
                        sendMove(\$remote_socket, int($ai_seq_args[0]{'move_to'}{'x'}), int($ai_seq_args[0]{'move_to'}{'y'}));
                        $ai_seq_args[0]{'ai_move_giveup'}{'time'} = time;
                        $ai_seq_args[0]{'ai_move_time_last'} = $chars[$config{'char'}]{'time_move'};
                        $ai_seq_args[0]{'ai_moved_tried'} = 1;
                } elsif ($ai_seq_args[0]{'ai_moved'} && time - $chars[$config{'char'}]{'time_move'} >= $chars[$config{'char'}]{'time_move_calc'}) {
                        undef $ai_v{'move_failed'};
                        shift @ai_seq;
                        shift @ai_seq_args;
                }
        }



        ##### SMART AI #####

        if ($timeout{'ai_exp_log'}{'timeout'} && timeOut(\%{$timeout{'ai_exp_log'}})) {
                chatLogExp() if ($timeout{'ai_exp_log'}{'time'});
                $timeout{'ai_exp_log'}{'time'} = time;
        }

        if ($yelloweasy && time - $mapdrttime > 1) {
                $mapdrttime = time;
                sendMsgToWindow("AA10".chr(1).$field{'name'}.chr(1).$chars[$config{'char'}]{'pos_to'}{'x'}.chr(1).$chars[$config{'char'}]{'pos_to'}{'y'});
        }

        undef $ai_v{'ai_attack_index'};
      	undef $ai_v{'temp'}{'found'};
        undef @{$ai_v{'ai_attack_agMonsters'}};
        $ai_v{'ai_attack_index'} = binFind(\@ai_seq, "attack");
        @{$ai_v{'ai_attack_agMonsters'}} = ai_getAttackAggressives();

        if ($ai_v{'ai_attack_index'} ne "" && %{$monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}}) {
                if (!$monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}{'dmgFromYou'} && $config{'attackTimeout'} && time - $ai_seq_args[$ai_v{'ai_attack_index'}]{'ai_attack_start'}{'time'} > $config{'attackTimeout'}) {
                        printc(1, "wr", "<信息> ", "$config{'attackTimeout'}秒内无法攻击目标，放弃目标\n");
                        $monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}{'attack_failed'}++;
      	                $ai_v{'temp'}{'found'} = 1;
                } elsif ($config{'attackCheckMiss'} && $chars[$config{'char'}]{'miss_count'} >= $config{'attackCheckMiss'}) {
                        printc(1, "wr", "<信息> ", "连续$config{'attackCheckMiss'}次无法伤害目标，放弃目标\n");
                        undef $chars[$config{'char'}]{'miss_count'};
                        $monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}{'attack_failed'}++;
      	                $ai_v{'temp'}{'found'} = 1;
		} elsif (@{$ai_v{'ai_attack_agMonsters'}} && $mon_control{lc($monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}{'name'})}{'attack_auto'} < 4 && timeOut(\%{$timeout{'ai_smart_attack'}})) {
                        $ai_v{'temp'}{'dist_attack'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}{'pos_to'}});
			if ($monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}{'dmgFromYou'} == 0 && binFind(\@{$ai_v{'ai_attack_agMonsters'}}, $ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}) eq "" && !$chars[$config{'char'}]{'mvp'}) {
              	                printc("wc", "<信息> ", "优先反击围攻怪物\n");
               	                $ai_v{'temp'}{'found'} = 1;
                       	} else {
	                        foreach (@{$ai_v{'ai_attack_agMonsters'}}) {
        	                        next if ($_ eq $ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'});
                	                $ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
                        	        if ($ai_v{'temp'}{'dist'} <= $config{'attackDistance'} && $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} > $mon_control{lc($monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}{'name'})}{'attack_auto'}) {
                                	        printc("wc", "<信息> ", "优先攻击\n");
		               	                $ai_v{'temp'}{'found'} = 1;
                	                        last;
                        	        } elsif ($ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'dist_attack'} && $ai_v{'temp'}{'dist_attack'} > $config{'attackDistance'} && $monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}{'dmgFromYou'} == 0 && !$chars[$config{'char'}]{'mvp'} && !$chars[$config{'char'}]{'time_cast'}) {
                                	        printc("wc", "<信息> ", "优先反击近距离怪物\n");
		               	                $ai_v{'temp'}{'found'} = 1;
                	                        last;
                        	        }
	                        }
			}
                }
		if ($ai_v{'temp'}{'found'}) {
			ai_changedByMonster("failed", $ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'});
		        aiRemove("attack");
	                $timeout{'ai_smart_attack'}{'time'} = time;
		}
        }



        ##### AUTO-TELEPORT #####


        if (@monstersID > 0 && !$ai_v{'temp'}{'teleport_search'}) {
        	$ai_v{'temp'}{'teleport_search'} = 1;
        	$timeout{'ai_teleport_search_wait'}{'time'} = time;
        }
        
        if ($ai_seq[0] eq "" && $config{'teleportAuto_search'} && $ai_v{'ai_teleport_safe'} && $config{'lockMap'} && $field{'name'} && $field{'name'} eq $config{'lockMap'} && $config{'lockMap_x'} eq "") {
                undef $ai_v{'temp'}{'found'};
                foreach (@monstersID) {
                	next if ($_ eq "");
                        if (($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} >= 2 || ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "" && $mon_control{'all'}{'attack_auto'} >= 2)) && !$monsters{$_}{'attack_failed'} && ($config{'attackSteal'} || !($monsters{$_}{'dmgFromYou'} == 0 && ($monsters{$_}{'dmgTo'} > 0 || $monsters{$_}{'dmgFrom'} > 0 || %{$monsters{$_}{'missedFromPlayer'}} || %{$monsters{$_}{'missedToPlayer'}} || %{$monsters{$_}{'castOnByPlayer'}})))) {
                        	$ai_v{'temp'}{'found'} = 1;
                                last;
                        }
                }
                if (!$ai_v{'temp'}{'found'} && $ai_v{'temp'}{'teleport_search'} == 1 && timeOut(\%{$timeout{'ai_teleport_search_wait'}})) {
                        printc("ww", "<瞬移> ", "寻找怪物\n") if ($config{'mode'} >= 2);
                        useTeleport(1);
                        $ai_v{'temp'}{'teleport_search'}++;
                        $timeout{'ai_teleport_search'}{'time'} = time;
                } elsif (!$ai_v{'temp'}{'found'} && timeOut(\%{$timeout{'ai_teleport_search'}})) {
                        printc("ww", "<瞬移> ", "寻找怪物\n") if ($config{'mode'} >= 2);
                        useTeleport(1);
                        $timeout{'ai_teleport_search'}{'time'} = time;
                }
        }

        if ($ai_seq[0] ne "") {
                $timeout{'ai_teleport_idle'}{'time'} = time;
        }

        if ($config{'teleportAuto_idle'} && timeOut(\%{$timeout{'ai_teleport_idle'}}) && $ai_v{'ai_teleport_safe'}) {
                printc("ww", "<瞬移> ", "空闲$timeout{'ai_teleport_idle'}{'timeout'}秒\n") if ($config{'mode'} >= 2);
                useTeleport(1);
                $ai_v{'clear_aiQueue'} = 1;
                $timeout{'ai_teleport_idle'}{'time'} = time;
        }


        ##########

        #DEBUG CODE
        if (time - $ai_v{'time'} > 2 && $config{'debug'}) {
                $stuff = @ai_seq_args;
                print "AI: @ai_seq | $stuff\n";
                $ai_v{'time'} = time;
        }

        if ($ai_v{'clear_aiQueue'}) {
                undef $ai_v{'clear_aiQueue'};
        }

        if (@ai_seq > 20) {
                undef @ai_seq;
                undef @ai_seq_args;
                chatLog("x", "错误: AI队列超出范围，清除队列\n");
        }

}

1;