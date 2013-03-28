#########################################################################
# KoreEasy Normal Module
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
}

sub mvpAttackAI {
	return if ($vipLevel || $xkore);	
	$config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"} = 0.3 if ($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"} < 0.3);
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

sub mvpNoticeRecv {
}

sub mvpNoticeSent {
}

1;