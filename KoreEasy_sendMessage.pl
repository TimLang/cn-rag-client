#######################################
#######################################
#OUTGOING PACKET FUNCTIONS
#######################################
#######################################

sub decrypt {
        my $r_msg = shift;
        my $themsg = shift;
        my @mask;
        my $i;
        my ($temp, $msg_temp, $len_add, $len_total, $loopin, $len, $val);
        if ($config{'encrypt'} == 1) {
                undef $$r_msg;
                undef $len_add;
                undef $msg_temp;
                for ($i = 0; $i < 13;$i++) {
                        $mask[$i] = 0;
                }
                $len = unpack("S1",substr($themsg,0,2));
                $val = unpack("S1",substr($themsg,2,2));
                {
                        use integer;
                        $temp = ($val * $val * 1391);
                }
                $temp = ~(~($temp));
                $temp = $temp % 13;
                $mask[$temp] = 1;
                {
                        use integer;
                        $temp = $val * 1397;
                }
                $temp = ~(~($temp));
                $temp = $temp % 13;
                $mask[$temp] = 1;
                for($loopin = 0; ($loopin + 4) < $len; $loopin++) {
                         if (!($mask[$loopin % 13])) {
                                  $msg_temp .= substr($themsg,$loopin + 4,1);
                        }
                }
                if (($len - 4) % 8 != 0) {
                        $len_add = 8 - (($len - 4) % 8);
                }
                $len_total = $len + $len_add;
                $$r_msg = $msg_temp.substr($themsg, $len_total, length($themsg) - $len_total);
        } elsif ($config{'encrypt'} >= 2) {
                undef $$r_msg;
                undef $len_add;
                undef $msg_temp;
                for ($i = 0; $i < 17;$i++) {
                        $mask[$i] = 0;
                }
                $len = unpack("S1",substr($themsg,0,2));
                $val = unpack("S1",substr($themsg,2,2));
                {
                        use integer;
                        $temp = ($val * $val * 34953);
                }
                $temp = ~(~($temp));
                $temp = $temp % 17;
                $mask[$temp] = 1;
                {
                        use integer;
                        $temp = $val * 2341;
                }
                $temp = ~(~($temp));
                $temp = $temp % 17;
                $mask[$temp] = 1;
                for($loopin = 0; ($loopin + 4) < $len; $loopin++) {
                         if (!($mask[$loopin % 17])) {
                                  $msg_temp .= substr($themsg,$loopin + 4,1);
                        }
                }
                if (($len - 4) % 8 != 0) {
                        $len_add = 8 - (($len - 4) % 8);
                }
                $len_total = $len + $len_add;
                $$r_msg = $msg_temp.substr($themsg, $len_total, length($themsg) - $len_total);
        } else {
                $$r_msg = $themsg;
        }
}

sub encrypt {
        my $r_msg = shift;
        my $themsg = shift;
        my @mask;
        my $newmsg;
        my ($in, $out);
        if ($config{'encrypt'} == 1 && $conState >= 5) {
                $out = 0;
                undef $newmsg;
                for ($i = 0; $i < 13;$i++) {
                        $mask[$i] = 0;
                }
                {
                        use integer;
                        $temp = ($encryptVal * $encryptVal * 1391);
                }
                $temp = ~(~($temp));
                $temp = $temp % 13;
                $mask[$temp] = 1;
                {
                        use integer;
                        $temp = $encryptVal * 1397;
                }
                $temp = ~(~($temp));
                $temp = $temp % 13;
                $mask[$temp] = 1;
                for($in = 0; $in < length($themsg); $in++) {
                        if ($mask[$out % 13]) {
                                $newmsg .= pack("C1", int(rand() * 255) & 0xFF);
                                $out++;
                        }
                        $newmsg .= substr($themsg, $in, 1);
                        $out++;
                }
                $out += 4;
                $newmsg = pack("S2", $out, $encryptVal) . $newmsg;
                while ((length($newmsg) - 4) % 8 != 0) {
                        $newmsg .= pack("C1", (rand() * 255) & 0xFF);
                }
        } elsif ($config{'encrypt'} >= 2 && $conState >= 5) {
                $out = 0;
                undef $newmsg;
                for ($i = 0; $i < 17;$i++) {
                        $mask[$i] = 0;
                }
                {
                        use integer;
                        $temp = ($encryptVal * $encryptVal * 34953);
                }
                $temp = ~(~($temp));
                $temp = $temp % 17;
                $mask[$temp] = 1;
                {
                        use integer;
                        $temp = $encryptVal * 2341;
                }
                $temp = ~(~($temp));
                $temp = $temp % 17;
                $mask[$temp] = 1;
                for($in = 0; $in < length($themsg); $in++) {
                        if ($mask[$out % 17]) {
                                $newmsg .= pack("C1", int(rand() * 255) & 0xFF);
                                $out++;
                        }
                        $newmsg .= substr($themsg, $in, 1);
                        $out++;
                }
                $out += 4;
                $newmsg = pack("S2", $out, $encryptVal) . $newmsg;
                while ((length($newmsg) - 4) % 8 != 0) {
                        $newmsg .= pack("C1", (rand() * 255) & 0xFF);
                }
        } else {
                $newmsg = $themsg;
        }

        $$r_msg = $newmsg;
}

sub injectAdminMessage {
        my $message = shift;
        $msg = pack("C*",0x9A, 0x00) . pack("S*", length($message)+5) . $message .chr(0);
        sendToClientByInject(\$remote_socket, $msg);
}

sub injectMessage {
        my $message = shift;
        my $name = "[KE]";
        my $msg .= $name . " : " . $message . chr(0);
        $msg = pack("C*",0x09, 0x01) . pack("S*", length($name) + length($message) + 12) . pack("C*",0,0,0,0) . $msg;
        sendToClientByInject(\$remote_socket, $msg);
}

sub injectAttackRang {
        my $attackRang = shift;
        my $msg = pack("C*",0x3A, 0x01) . pack("S*", $attackRang);
        sendToClientByInject(\$remote_socket, $msg);
}

sub injectMapMark {
	my $index = shift;
	my $type = shift;
	my $x = shift;
	my $y = shift;
	my $flag;
	my $color;
	if ($type eq "g") {
		$flag = 1;
		$color = pack("C*", 0, 255, 0, 255);
	} elsif ($type eq "b") {
		$flag = 1;
		$color = pack("C*", 255, 0, 0, 255);
	} elsif ($type eq "r") {
		$flag = 1;
		$color = pack("C*", 0, 0, 255, 255);
        } elsif ($type eq "m") {
		$flag = 1;
		$color = pack("C*", 255, 0, 255, 255);
        } elsif ($type eq "y") {
		$flag = 1;
		$color = pack("C*", 0, 255, 255, 255);
	} else {
		$flag = 2;
		$color = pack("C*", 0, 0, 0, 255);
	}
	my $msg = pack("C*", 0x44, 0x01, 0, 0, 0, 0) . pack("S*", $flag) . pack("C*", 0, 0) .  pack("S*", $x) . pack("C*", 0, 0) . pack("S*", $y) 
		. pack("C*", 0, 0) .  pack("C*", $index) . $color;
	sendToClientByInject(\$remote_socket, $msg);
}

sub sendAddSkillPoint {
        my $r_socket = shift;
        my $skillID = shift;
        my $msg = pack("C*", 0x12, 0x01) . pack("v*", $skillID);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0112 ", "Sent Add Skill Point: $skillID\n") if ($config{'debug'} >= 2);  
}

sub sendAddStatusPoint {
        my $r_socket = shift;
        my $statusID = shift;
        my $msg = pack("C*", 0xBB, 0) . pack("v*", $statusID) . pack("C*", 0x01);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0112 ", "Sent Add Status Point: $statusID\n") if ($config{'debug'} >= 2);        
}

sub sendAlignment {
        my $r_socket = shift;
        my $ID = shift;
        my $alignment = shift;
        my $msg = pack("C*", 0x49, 0x01) . $ID . pack("C*", $alignment);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0149 ", "Sent Alignment: ".getHex($ID).", $alignment\n") if ($config{'debug'} >= 2);
}

sub sendArrowMake {
        my $r_socket = shift;
        my $ID = shift;
        my $msg = pack("C*", 0xAE, 0x01).pack("S1", $ID);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-01AE ", "Sent Arrow Make: $ID\n") if ($config{'debug'} >= 2);
}

sub sendAttack {
        my $r_socket = shift;
        my $monID = shift;
        my $flag = shift;
        my $msg = pack("C*", 0x89, 0x00) . $monID . pack("C*", $flag);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0089 ", "Sent attack: ".getHex($monID)."\n") if ($config{'debug'} >= 2);
}

sub sendAttackStop {
        my $r_socket = shift;
        #my $msg = pack("C*", 0x18, 0x01);
        # Apparently this packet is wrong. The server disconnects us if we do this.
        # Sending a move command to the current position seems to be able to emulate
        # what this function is supposed to do.
        sendMove ($r_socket, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
}

sub sendAutospell {
        my $r_socket = shift;
        my $ID = shift;
        my $msg = pack("C*", 0xCE, 0x01) . pack("S*", $ID) . chr(0) x 2;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-01CE ", "Sent Autospell: $index\n") if ($config{'debug'} >= 2);
}

sub sendBuy {
        my $r_socket = shift;
        my $ID = shift;
        my $amount = shift;
        my $msg = pack("C*", 0xC8, 0x00, 0x08, 0x00) . pack("S*", $amount, $ID);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00C8 ", "Sent buy: ".getHex($ID)."\n") if ($config{'debug'} >= 2);
}

sub sendBuyVender {
        my $r_socket = shift;
        my $ID = shift;
        my $amount = shift;
        my $msg = pack("C*", 0x34, 0x01, 0x0C, 0x00) . $venderID . pack("S*", $amount, $ID);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0134 ", "Sent Vender Buy: ".getHex($ID)."\n") if ($config{'debug'} >= 2);
}

sub sendCartAdd {
        my $r_socket = shift;
        my $index = shift;
        my $amount = shift;
        my $msg = pack("C*", 0x26, 0x01) . pack("S*", $index) . pack("L*", $amount);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0126 ", "Sent Cart Add: $index x $amount\n") if ($config{'debug'} >= 2);
}

sub sendCartGet {
        my $r_socket = shift;
        my $index = shift;
        my $amount = shift;
        my $msg = pack("C*", 0x27, 0x01) . pack("S*", $index) . pack("L*", $amount);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0127 ", "Sent Cart Get: $index x $amount\n") if ($config{'debug'} >= 2);
}

sub sendCatch {
        my $r_socket = shift;
        my $monID = shift;
        my $msg = pack("C*", 0x9F, 0x01) . $monID;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-019F ", "Sent Catch\n") if ($config{'debug'} >= 2);
}

sub sendCharLogin {
        my $r_socket = shift;
        my $char = shift;
        my $msg = pack("C*", 0x66,0x00) . pack("C*",$char);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0066 ", "Sent Char Login\n") if ($config{'debug'} >= 2);
}

sub sendChat {
        my $r_socket = shift;
        my $message = shift;
        my $msg = pack("C*",0x8C, 0x00) . pack("S*", length($chars[$config{'char'}]{'name'}) + length($message) + 8) .
                $chars[$config{'char'}]{'name'} . " : " . $message . chr(0);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-008C ", "Sent Chat\n") if ($config{'debug'} >= 2);        
}

sub sendChatRoomBestow {
        my $r_socket = shift;
        my $name = shift;
        $name = substr($name, 0, 24) if (length($name) > 24);
        $name = $name . chr(0) x (24 - length($name));
        my $msg = pack("C*", 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00).$name;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00E0 ", "Sent Chat Room Bestow: $name\n") if ($config{'debug'} >= 2);
}

sub sendChatRoomChange {
        my $r_socket = shift;
        my $title = shift;
        my $limit = shift;
        my $public = shift;
        my $password = shift;
        $password = substr($password, 0, 8) if (length($password) > 8);
        $password = $password . chr(0) x (8 - length($password));
        my $msg = pack("C*", 0xDE, 0x00).pack("S*", length($title) + 15, $limit).pack("C*",$public).$password.$title;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00DE ", "Sent Change Chat Room: $title, $limit, $public, $password\n") if ($config{'debug'} >= 2);
}

sub sendChatRoomCreate {
        my $r_socket = shift;
        my $title = shift;
        my $limit = shift;
        my $public = shift;
        my $password = shift;
        $password = substr($password, 0, 8) if (length($password) > 8);
        $password = $password . chr(0) x (8 - length($password));
        my $msg = pack("C*", 0xD5, 0x00).pack("S*", length($title) + 15, $limit).pack("C*",$public).$password.$title;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00D5 ", "Sent Create Chat Room: $title, $limit, $public, $password\n") if ($config{'debug'} >= 2);
}

sub sendChatRoomJoin {
        my $r_socket = shift;
        my $ID = shift;
        my $password = shift;
        $password = substr($password, 0, 8) if (length($password) > 8);
        $password = $password . chr(0) x (8 - length($password));
        my $msg = pack("C*", 0xD9, 0x00).$ID.$password;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00D9 ", "Sent Join Chat Room: ".getHex($ID)." $password\n") if ($config{'debug'} >= 2);
}

sub sendChatRoomKick {
        my $r_socket = shift;
        my $name = shift;
        $name = substr($name, 0, 24) if (length($name) > 24);
        $name = $name . chr(0) x (24 - length($name));
        my $msg = pack("C*", 0xE2, 0x00).$name;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00E2 ", "Sent Chat Room Kick: $name\n") if ($config{'debug'} >= 2);
}

sub sendChatRoomLeave {
        my $r_socket = shift;
        my $msg = pack("C*", 0xE3, 0x00);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00E3 ", "Sent Leave Chat Room\n") if ($config{'debug'} >= 2);
}

sub sendCloseShop {
        my $r_socket = shift;
        my $msg = pack("C*", 0x2E, 0x01);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-012E ", "Sent Shop Closed\n") if ($config{'debug'} >= 2);
        printc("wr", "<信息> ", "你的露天商店关闭了\n");
        undef $chars[$config{'char'}]{'shopOpened'};
        undef %shop;        
}

sub sendCurrentDealCancel {
        my $r_socket = shift;
        my $msg = pack("C*", 0xED, 0x00);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00ED ", "Sent Cancel Current Deal\n") if ($config{'debug'} >= 2);
}

sub sendDeal {
        my $r_socket = shift;
        my $ID = shift;
        my $msg = pack("C*", 0xE4, 0x00) . $ID;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00E4 ", "Sent Initiate Deal: ".getHex($ID)."\n") if ($config{'debug'} >= 2);
}

sub sendDealAccept {
        my $r_socket = shift;
        my $msg = pack("C*", 0xE6, 0x00, 0x03);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00E6 ", "Sent Accept Deal\n") if ($config{'debug'} >= 2);
}

sub sendDealAddItem {
        my $r_socket = shift;
        my $index = shift;
        my $amount = shift;
        my $msg = pack("C*", 0xE8, 0x00) . pack("S*", $index) . pack("L*",$amount);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00E8 ", "Sent Deal Add Item: $index, $amount\n") if ($config{'debug'} >= 2);
}

sub sendDealCancel {
        my $r_socket = shift;
        my $msg = pack("C*", 0xE6, 0x00, 0x04);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00E6 ", "Sent Cancel Deal\n") if ($config{'debug'} >= 2);
}

sub sendDealFinalize {
        my $r_socket = shift;
        my $msg = pack("C*", 0xEB, 0x00);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00EB ", "Sent Deal Finalize\n") if ($config{'debug'} >= 2);
}

sub sendDealOK {
        my $r_socket = shift;
        my $msg = pack("C*", 0xEB, 0x00);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00EB ", "Sent Deal OK\n") if ($config{'debug'} >= 2);
}

sub sendDealTrade {
        my $r_socket = shift;
        my $msg = pack("C*", 0xEF, 0x00);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00EF ", "Sent Deal Trade\n") if ($config{'debug'} >= 2);
}

sub sendDrop {
        my $r_socket = shift;
        my $index = shift;
        my $amount = shift;
        my $msg = pack("C*", 0xA2, 0x00) . pack("S*", $index, $amount);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00A2 ", "Sent drop: $index x $amount\n") if ($config{'debug'} >= 2);
}

sub sendEmotion {
        my $r_socket = shift;
        my $ID = shift;
        my $msg = pack("C*", 0xBF, 0x00).pack("C1",$ID);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00BF ", "Sent Emotion\n") if ($config{'debug'} >= 2);
}

sub sendEnteringVender {
        my $r_socket = shift;
        my $ID = shift;
        my $msg = pack("C*", 0x30, 0x01) . $ID;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0130 ", "Sent Entering Vender: ".getHex($ID)."\n") if ($config{'debug'} >= 2);
}

sub sendEquip{
        my $r_socket = shift;
        my $index = shift;
        my $type = shift;
        my $msg = pack("C*", 0xA9, 0x00) . pack("S*", $index) .  pack("S*", $type);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00A9 ", "Sent Equip: $index\n") if ($config{'debug'} >= 2);
}

sub sendGameLogin {
        my $r_socket = shift;
        my $accountID = shift;
        my $sessionID = shift;
        my $sex = shift;
        my $msg = pack("C*", 0x65,0) . $accountID . $sessionID . pack("C*", 0,0,0,0,0,0,$sex);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0065 ", "Sent Game Login\n") if ($config{'debug'} >= 2);
}

sub sendGetPlayerInfo {
        my $r_socket = shift;
        my $ID = shift;
        my $msg = pack("C*", 0x94, 0x00) . $ID;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0094 ", "Sent Get Player Info: ID - ".getHex($ID)."\n") if ($config{'debug'} >= 2);
}

sub sendGetStoreList {
        my $r_socket = shift;
        my $ID = shift;
        my $msg = pack("C*", 0xC5, 0x00) . $ID . pack("C*",0x00);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00C5 ", "Sent get Store List: ".getHex($ID)."\n") if ($config{'debug'} >= 2);
}

sub sendGetSellList {
        my $r_socket = shift;
        my $ID = shift;
        my $msg = pack("C*", 0xC5, 0x00) . $ID . pack("C*",0x01);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00C5 ", "Sent Sell To NPC: ".getHex($ID)."\n") if ($config{'debug'} >= 2);
}

sub sendGuildAlly{
        my $r_socket = shift;
        my $ID = shift;
        my $flag = shift;
        my $msg = pack("C*", 0x72, 0x01).$ID.pack("L1", $flag);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0172 ", "Sent Ally Guild: ".getHex($ID).", $flag\n") if ($config{'debug'} >= 2);
}

sub sendGuildChat {
        my $r_socket = shift;
        my $message = shift;
        my $msg = pack("C*",0x7E, 0x01) . pack("S*",length($chars[$config{'char'}]{'name'}) + length($message) + 8) .
        $chars[$config{'char'}]{'name'} . " : " . $message . chr(0);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-017E ", "Sent Guild Chat\n") if ($config{'debug'} >= 2);
}

sub sendGuildInfoRequest {
        my $r_socket = shift;
        my $msg = pack("C*", 0x4d, 0x01);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-014D ", "Sent Guild Information Request\n") if ($config{'debug'} >= 2);
}

sub sendGuildJoin{
        my $r_socket = shift;
        my $ID = shift;
        my $flag = shift;
        my $msg = pack("C*", 0x6B, 0x01).$ID.pack("L1", $flag);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-016B ", "Sent Join Guild: ".getHex($ID).", $flag\n") if ($config{'debug'} >= 2);
}

sub sendGuildRequest {
        my $r_socket = shift;
        my $page = shift;
        my $msg = pack("C*", 0x4f, 0x01).pack("L1", $page);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-014F ", "Sent Guild Request Page: ".$page."\n") if ($config{'debug'} >= 2);
}

sub sendIdentify {
        my $r_socket = shift;
        my $index = shift;
        my $msg = pack("C*", 0x78, 0x01) . pack("S*", $index);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0178 ", "Sent Identify: $index\n") if ($config{'debug'} >= 2);
}

sub sendIgnore {
        my $r_socket = shift;
        my $name = shift;
        my $flag = shift;
        $name = substr($name, 0, 24) if (length($name) > 24);
        $name = $name . chr(0) x (24 - length($name));
        my $msg = pack("C*", 0xCF, 0x00).$name.pack("C*", $flag);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00CF ", "Sent Ignore: $name, $flag\n") if ($config{'debug'} >= 2);
}

sub sendIgnoreAll {
        my $r_socket = shift;
        my $flag = shift;
        my $msg = pack("C*", 0xD0, 0x00).pack("C*", $flag);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00D0 ", "Sent Ignore All: $flag\n") if ($config{'debug'} >= 2);
}

#sendGetIgnoreList - chobit 20021223
sub sendIgnoreListGet {
        my $r_socket = shift;
        my $flag = shift;
        my $msg = pack("C*", 0xD3, 0x00);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00D3 ", "Sent get Ignore List: $flag\n") if ($config{'debug'} >= 2);
}

sub sendItemUse {
        my $r_socket = shift;
        my $ID = shift;
        my $targetID = shift;
        my $msg = pack("C*", 0xA7, 0x00).pack("S*",$ID).$targetID;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00A7 Item Use: $ID\n") if ($config{'debug'} >= 2);
}


sub sendLook {
        my $r_socket = shift;
        my $body = shift;
        my $head = shift;
        my $msg = pack("C*", 0x9B, 0x00, $head, 0x00, $body);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-009B ", "Sent look: $body $head\n") if ($config{'debug'} >= 2);
        $chars[$config{'char'}]{'look'}{'head'} = $head;
        $chars[$config{'char'}]{'look'}{'body'} = $body;
}

sub sendNameRequest {
        my $r_socket = shift;
        my $ID = shift;
        my $msg = pack("C*", 0x93, 0x01) . $ID;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0193 ", "Sent Name Request : ".getHex($ID)."\n") if ($config{'debug'} >= 2);
}

sub sendMapLoaded {
        my $r_socket = shift;
        my $msg = pack("C*", 0x7D,0x00);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-007D ", "Sent Map Loaded\n") if ($config{'debug'} >= 2);
}

sub sendMapLogin {
        my $r_socket = shift;
        my $accountID = shift;
        my $charID = shift;
        my $sessionID = shift;
        my $sex = shift;
        my $msg;
        #$msg = pack("C*", 0x72,0) . $accountID . $charID . $sessionID . pack("L1", getTickCount()) . pack("C*",$sex);
        $msg = pack("C*", 0x72,0) .
			$accountID .
			$charID .
			$sessionID .
			pack("V1", getTickCount()) .
			pack("C*",$sex);
		
		sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0072 ", "Sent Map Login\n") if ($config{'debug'} >= 2);
}

sub sendMasterLogin {
        my $r_socket = shift;
        my $username = shift;
        my $password = shift;
       # my $msg = pack("C*", 0x64,0,$config{'version'},0,0,0) . $username . chr(0) x (24 - length($username)) .
        #               $password . chr(0) x (24 - length($password)) . pack("C*", $config{"master_version_$config{'master'}"});			
		
		my $msg = pack("v1 V",0x64,$config{'version'}) .
			pack("a24", $username) .
			pack("a24", $password) .
			pack("C*", $config{"master_version_$config{'master'}"});
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0064 ", "Sent Master Login\n") if ($config{'debug'} >= 2);        
}

sub sendMasterSecureLogin {
        my $r_socket = shift;
        my $username = shift;
        my $password = shift;
        my $salt = shift;
        my $md5 = Digest::MD5->new;
        if ($config{'SecureLogin'} == 1) {
                $salt = $salt . $password;
        } else {
                $salt = $password . $salt;
        }
        $md5->add($salt);
        my $msg = pack("C*", 0xDD, 0x01) . pack("L1", $config{'version'}) . $username . chr(0) x (24 - length($username)) .
                                         $md5->digest . pack("C*", $config{"master_version_$config{'master'}"});
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-01DD ", "Sent Master Secure Login\n") if ($config{'debug'} >= 2);        
}

sub sendMasterEncryptKeyRequest {
        my $r_socket = shift;
        my $msg = pack("C*", 0xDB, 0x01);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-01DB ", "Sent Master Encrypt Key Request\n") if ($config{'debug'} >= 2);                
}

sub sendMemo {
        my $r_socket = shift;
        my $msg = pack("C*", 0x1D, 0x01);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-011D ", "Sent Memo\n") if ($config{'debug'} >= 2);
}

sub sendMove {
        my $r_socket = shift;
        my $x = int scalar shift;
        my $y = int scalar shift;
        my $msg;
        $msg = pack("C*", 0x85, 0x00) . getCoordString($x, $y);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0085 ", "Sent Move To: $x, $y\n") if ($config{'debug'} >= 2);
}

sub sendOpenShop {
        parseReload("shop_control");
        $timeout{'ai_shopAuto'}{'time'} = time;
        my $r_socket = shift;
        my $strShopTitle;
        my $shopmsg;
        my $itemIndex;

        undef $strShopTitle;
        undef $shopmsg;

        $strShopTitle = $shop_control{'shop_title'};

        if (length($strShopTitle) == 0) {
                printc("wr", "<信息> ", "请给你的商店起个名字吧，商店未开张。\n");
                undef $shop_control{'shopAuto_open'} if ($shop_control{'shopAuto_open'});
                return;
        } elsif ($chars[$config{'char'}]{'shopOpened'}) {
                printc("wr", "<信息> ", "你已经开店了。\n");
                return;                
        } elsif (!$chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'lv'}) {
                printc("wr", "<信息> ", "你没有开店技能。\n");
                undef $shop_control{'shopAuto_open'};
                return;                
        } elsif (length($strShopTitle) >= 36) {
                $strShopTitle = substr($strShopTitle, 0, 36);
        }

        $sellItemsCount = 0;
        $i = 0;
        my $strSellingItems = "";
        while ($shop_control{"name_$i"} ne "") {
                undef $itemIndex;
                undef $amount;
                undef $price;
                $itemFounded = 0;
                for ($j=0; $j < @{$cart{'inventory'}}; $j++) {
                        next if (!%{$cart{'inventory'}[$j]});
                        if ($cart{'inventory'}[$j]{'name'} eq $shop_control{"name_$i"} && $shop_control{"name_$i"} ne "") {
                                if (!existsInList($strSellingItems, $j)) {
                                        $itemIndex = $j;
                                        $itemFounded = 1;
                                        last;
                                }
                        }
                }
                if ($itemFounded == 0) {
                        printc("wn", "<信息> ", "你的手推车里没有物品 " . $shop_control{"name_$i"} . ", 忽略此物品。\n");
                }
                if ($shop_control{"quantity_$i"} > 0 && $itemFounded == 1) {
                        if ($shop_control{"quantity_$i"} > $cart{'inventory'}[$j]{'amount'}) {
                                $amount = $cart{'inventory'}[$j]{'amount'};
                        } else {
                                $amount = $shop_control{"quantity_$i"};
                        }
                } elsif ($shop_control{"quantity_$i"} eq "" || $shop_control{"quantity_$i"} == 0) {
                        $amount = $cart{'inventory'}[$j]{'amount'};
                } else {
                        $itemFounded = 0;
                }

                if ($shop_control{"price_$i"} > 0 && $shop_control{"price_$i"} <= 10000000 && $itemFounded == 1) {
                        $price = $shop_control{"price_$i"};
                } elsif ($shop_control{"price_$i"} eq "" || $shop_control{"price_$i"} == 0) {
                        printc("wr", "<信息> ", "物品 " . $shop_control{"name_$i"} . " 的价格设置错误。\n");
                        $itemFounded = 0;
                } else {
                        $itemFounded = 0;
                }

                if ($itemFounded == 1) {
                        $shopmsg .= pack("S*", $itemIndex) . pack("S*", $amount) . pack("L*", $price);
                        if ($strSellingItems eq "") {
                                $strSellingItems = $itemIndex;
                        } else {
                                $strSellingItems .= ",$itemIndex";
                        }
                        $sellItemsCount++;
                        if ($sellItemsCount >= $chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'lv'} + 2) {
                                last;
                        }
                }
                $i++;
        }

        if ($sellItemsCount > 0 && $sellItemsCount <= $chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'lv'} + 2) {
                my $msglength = 0x55 + 0x08 * $sellItemsCount;
                $shopmsg = pack("C*", 0xB2, 0x01) . pack("S*", $msglength) .
                        $strShopTitle . chr(0) x (36 - length($strShopTitle)) . chr(0) x 44
                        . chr(1). $shopmsg;
        }

        if( $sellItemsCount > 0 && $sellItemsCount <= $chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'lv'} + 2) {
		sendSkillUse(\$remote_socket, 41, $chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'lv'}, $accountID);
                sendMsgToServer($r_socket, $shopmsg);
	        printc("cn", "<-01B2 ", "Sent Shop Open\n") if ($config{'debug'} >= 2);
        }else{
                printc("wr", "<信息> ", "开店失败, 请检查你的shop_control.txt文件\n");
                undef $shop_control{'shopAuto_open'};
        }
}

sub sendPartyChat {
        my $r_socket = shift;
        my $message = shift;
        my $msg = pack("C*",0x08, 0x01) . pack("S*",length($chars[$config{'char'}]{'name'}) + length($message) + 8) .
                $chars[$config{'char'}]{'name'} . " : " . $message . chr(0);
        sendMsgToServer($r_socket, $msg);
	printc("cn", "<-0108 ", "Sent Party Chat\n") if ($config{'debug'} >= 2);
}

sub sendPartyJoin {
        my $r_socket = shift;
        my $ID = shift;
        my $flag = shift;
        my $msg = pack("C*", 0xFF, 0x00).$ID.pack("L", $flag);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00FF ", "Sent Join Party: ".getHex($ID).", $flag\n") if ($config{'debug'} >= 2);
}

sub sendPartyJoinRequest {
        my $r_socket = shift;
        my $ID = shift;
        my $msg = pack("C*", 0xFC, 0x00).$ID;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00FC ", "Sent Request Join Party: ".getHex($ID)."\n") if ($config{'debug'} >= 2);
}

sub sendPartyKick {
        my $r_socket = shift;
        my $ID = shift;
        my $name = shift;
        $name = substr($name, 0, 24) if (length($name) > 24);
        $name = $name . chr(0) x (24 - length($name));
        my $msg = pack("C*", 0x03, 0x01).$ID.$name;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0103 ", "Sent Kick Party: ".getHex($ID).", $name\n") if ($config{'debug'} >= 2);
}

sub sendPartyLeave {
        my $r_socket = shift;
        my $msg = pack("C*", 0x00, 0x01);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0100 ", "Sent Leave Party: $name\n") if ($config{'debug'} >= 2);
}

sub sendPartyOrganize {
        my $r_socket = shift;
        my $name = shift;
        $name = substr($name, 0, 24) if (length($name) > 24);
        $name = $name . chr(0) x (24 - length($name));
        my $msg = pack("C*", 0xF9, 0x00).$name;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00F9 ", "Sent Organize Party: $name\n") if ($config{'debug'} >= 2);
}

sub sendPartyShareEXP {
        my $r_socket = shift;
        my $flag = shift;
        my $msg = pack("C*", 0x02, 0x01).pack("L", $flag);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0102 ", "Sent Party Share: $flag\n") if ($config{'debug'} >= 2);
}

sub sendPetCommand{
        my $r_socket = shift;
        my $flag = shift;
        my $msg = pack("C*", 0xA1, 0x01).pack("C1",$flag);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-01A1 ", "Sent Pet Command : $flag\n") if ($config{'debug'});
}

sub sendQuit {
        my $r_socket = shift;
        my $msg = pack("C*", 0x8A, 0x01, 0x00, 0x00);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-018A ", "Sent Quit\n") if ($config{'debug'} >= 2);
}

sub sendRaw {
        my $r_socket = shift;
        my $raw = shift;
        my @raw;
        my $msg;
        @raw = split / /, $raw;
        foreach (@raw) {
                $msg .= pack("C", hex($_));
        }
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-XXXX ", "Sent Raw Packet: @raw\n") if ($config{'debug'} >= 2);
}

sub sendRespawn {
        my $r_socket = shift;
        my $msg = pack("C*", 0xB2, 0x00, 0x00);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00B2 ", "Sent Respawn\n") if ($config{'debug'} >= 2);
}

sub sendQuitToCharSelete {
        my $r_socket = shift;
        my $msg = pack("C*", 0xB2, 0x00, 0x01);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00B2 ", "sendQuitToCharSelete\n") if ($config{'debug'} >= 2);
}

sub sendPrivateMsg {
        my $r_socket = shift;
        my $user = shift;
        my $message = shift;
        my $msg = pack("C*",0x96, 0x00) . pack("S*",length($message) + 29) . $user . chr(0) x (24 - length($user)) .
                        $message . chr(0);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0096 ", "Sent Private Chat\n") if ($config{'debug'} >= 2);
}

sub sendSell {
        my $r_socket = shift;
        my $index = shift;
        my $amount = shift;
        my $msg = pack("C*", 0xC9, 0x00, 0x08, 0x00) . pack("S*", $index, $amount);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00C9 ", "Sent Sell: $index x $amount\n") if ($config{'debug'} >= 2);

}

sub sendSit {
        my $r_socket = shift;
        my $msg = pack("C*", 0x89,0x00, 0x00, 0x00, 0x00, 0x00, 0x02);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0089 ", "Sent Sit\n") if ($config{'debug'} >= 2);
}

sub sendSkillUse {
        my $r_socket = shift;
        my $ID = shift;
        my $lv = shift;
        my $targetID = shift;
        my $msg = pack("C*", 0x13, 0x01).pack("S*",$lv,$ID).$targetID;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0113 ", "Sent Skill Use: $ID\n") if ($config{'debug'} >= 2);
}

sub sendSkillUseLoc {
        my $r_socket = shift;
        my $ID = shift;
        my $lv = shift;
        my $x = shift;
        my $y = shift;
        my $msg = pack("C*", 0x16, 0x01).pack("S*",$lv,$ID,$x,$y);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0116 ", "Sent Skill Use Loc: $ID\n") if ($config{'debug'} >= 2);
}

sub sendStorageAdd {
        my $r_socket = shift;
        my $index = shift;
        my $amount = shift;
        my $msg = pack("C*", 0xF3, 0x00) . pack("S*", $index) . pack("L*", $amount);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00F3 ", "Sent Storage Add: $index x $amount\n") if ($config{'debug'} >= 2);
}

sub sendStorageClose {
        my $r_socket = shift;
        my $msg = pack("C*", 0xF7, 0x00);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00F7 ", "Sent Storage Close\n") if ($config{'debug'} >= 2);
}

sub sendStorageGet {
        my $r_socket = shift;
        my $index = shift;
        my $amount = shift;
        my $msg = pack("C*", 0xF5, 0x00) . pack("S*", $index) . pack("L*", $amount);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00F5 ", "Sent Storage Get: $index x $amount\n") if ($config{'debug'} >= 2);
}

sub sendStand {
        my $r_socket = shift;
        my $msg = pack("C*", 0x89,0x00, 0x00, 0x00, 0x00, 0x00, 0x03);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0089 ", "Sent Stand\n") if ($config{'debug'} >= 2);
}

sub sendSync {
        my $r_socket = shift;
        my $time = shift;
        my $msg = pack("C*", 0x7E, 0x00) . pack("L1", $time);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-007E ", "Sent Sync: $time\n") if ($config{'debug'} >= 2);
}

sub sendSyncInject {
        my $r_socket = shift;
        $$r_socket->send("K".pack("S", 0)) if $$r_socket && $$r_socket->connected();
        printc("cn", "<-XXXX ", "Sent Sync Inject\n") if ($config{'debug'} >= 2);
}

sub sendTake {
        my $r_socket = shift;
        my $itemID = shift;
        my $msg;
        $msg = pack("C*", 0x9F, 0x00) . $itemID;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-009F ", "Sent Take\n") if ($config{'debug'} >= 2);
}

sub sendTalk {
        my $r_socket = shift;
        my $ID = shift;
        $ID = ai_getTalkID($ID);
        my $msg = pack("C*", 0x90, 0x00) . $ID . pack("C*",0x01);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0090 ", "Sent Talk: ".getHex($ID)."\n") if ($config{'debug'} >= 2);
}

sub sendTalkAnswer {
        my $r_socket = shift;
        my $ID = shift;
        $ID = ai_getTalkID($ID);
        my $amount = shift;
        my $msg = pack("C*", 0x43, 0x01) . $ID . pack("L*", $amount);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0143 ", "Sent Talk Answer: ".getHex($ID).", $amount\n") if ($config{'debug'} >= 2);
}

sub sendTalkCancel {
        my $r_socket = shift;
        my $ID = shift;
        $ID = ai_getTalkID($ID);
        my $msg = pack("C*", 0x46, 0x01) . $ID;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-0146 ", "Sent Talk Cancel: ".getHex($ID)."\n") if ($config{'debug'} >= 2);
}

sub sendTalkContinue {
        my $r_socket = shift;
        my $ID = shift;
        $ID = ai_getTalkID($ID);
        my $msg = pack("C*", 0xB9, 0x00) . $ID;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00B9 ", "Sent Talk Continue: ".getHex($ID)."\n") if ($config{'debug'} >= 2);
}

sub sendTalkResponse {
        my $r_socket = shift;
        my $ID = shift;
        $ID = ai_getTalkID($ID);
        my $response = shift;
        my $msg = pack("C*", 0xB8, 0x00) . $ID. pack("C1",$response);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00B8 ", "Sent Talk Respond: ".getHex($ID).", $response\n") if ($config{'debug'} >= 2);
}

sub sendTeleport {
        my $r_socket = shift;
        my $location = shift;
        $location = substr($location, 0, 16) if (length($location) > 16);
        $location .= chr(0) x (16 - length($location));
        my $msg = pack("C*", 0x1B, 0x01, 0x1A, 0x00) . $location;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-011B ", "Sent Teleport: $location\n") if ($config{'debug'} >= 2);
}

sub sendToClientByInject {
        my $r_socket = shift;
        my $msg = shift;
        encrypt(\$msg, $msg);
        push @sendToClient_injectQue, $msg if ($xKore && $$r_socket && $$r_socket->connected());
}

sub sendToServerByInject {
        my $r_socket = shift;
        my $msg = shift;
        encrypt(\$msg, $msg);
        $$r_socket->send("S".pack("S", length($msg)).$msg) if ($$r_socket && $$r_socket->connected());
}

sub sendMsgToServer {
        my $r_socket = shift;
        my $msg = shift;
        return if (!$$r_socket || !$$r_socket->connected());
        encrypt(\$msg, $msg);
        if ($xKore) {
                sendToServerByInject(\$remote_socket, $msg);
        } else {
                $$r_socket->send($msg);
        }
        my $switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));
        print "Packet Switch SENT: $switch\n" if ($config{'debugPacket_sent'} || (existsInList($config{'debugPacket_sent_dumpList'}, $switch)));
        dumpData($msg) if (existsInList($config{'debugPacket_sent_dumpList'}, $switch));
}

sub sendMsgToWindow {
        my $msg = shift;
        return if (!$window_socket);
        $window_socket->send($msg);
        my $switch = substr($msg, 0, 4);
        print "Window Packet SENT: $switch\n" if ($config{'debug'} >= 2);
}

sub sendUnequip{
        my $r_socket = shift;
        my $index = shift;
        my $msg = pack("C*", 0xAB, 0x00) . pack("S*", $index);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00AB ", "Sent Unequip: $index\n") if ($config{'debug'} >= 2);
}

sub sendWarpto {
        my $r_socket = shift;
        my $location = shift;
        $location = substr($location, 0, 16) if (length($location) > 16);
        $location .= chr(0) x (16 - length($location));
        my $msg = pack("C*", 0x1B, 0x01, 0x1B, 0x00) . $location;
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-011B ", "Sent Warpto: $location\n") if ($config{'debug'} >= 2);
}

sub sendWho {
        my $r_socket = shift;
        my $msg = pack("C*", 0xC1, 0x00);
        sendMsgToServer($r_socket, $msg);
        printc("cn", "<-00C1 ", "Sent Who\n") if ($config{'debug'} >= 2);
}

sub sendFriendJoin {
	# friend join
	# 0208 <account ID>.l <charactor ID>.l <type>.l
	my $r_socket = shift;
	my $ID = shift;
	my $ID2 = shift;
	my $flag = shift;
	my $msg = pack("C*", 0x08, 0x02).$ID.$ID2.pack("L", $flag);
        sendMsgToServer($r_socket, $msg);
	printc("cn", "<-00C1 ", "Sent Join Friend: ".getHex($ID).", ".getHex($ID2).", $flag\n") if ($config{'debug'} >= 2);
}

sub sendFriendJoinRequest {
	# friend join request
	# 0202 <name>.24B
	my $r_socket = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0x02, 0x02).$name;
        sendMsgToServer($r_socket, $msg);
	printc("cn", "<-00C1 ", "Sent Request Join friend: $name\n") if ($config{'debug'} >= 2);
}

sub sendFriendKick {
	# friend kick
	# 0203 <account ID>.l <charactor ID>.l
	my $r_socket = shift;
	my $ID = shift;
	my $ID2 = shift;
	my $msg = pack("C*", 0x03, 0x02).$ID.$ID2;
        sendMsgToServer($r_socket, $msg);
	printc("cn", "<-00C1 ", "Sent Kick Friend: ".getHex($ID).", ".getHex($ID2)."\n") if ($config{'debug'} >= 2);
}

1;