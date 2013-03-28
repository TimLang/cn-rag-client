#########################################################################
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################

# KoreEasy ParseInput Full Module - Version: 0.8.00.0402




#######################################
#PARSE INPUT FULL VERSION
#######################################


sub parseInput {
        my $input = shift;
        my $printType;
        $printType = shift if ($xKore);

        my ($arg1, $arg2, $switch);
        print "Echo: $input\n" if ($config{'debug'} >= 2);
        ($switch) = $input =~ /^(\w*)/;

        if ($printType) {
                $noColor = 1;
                open(BUFFER, '>logs/buffer');
                select(BUFFER);
                BUFFER->autoflush(0);
        }

#Check if in special state

        if (!$xKore && $conState == 2 && $waitingForInput) {
                $config{'server'} = $input;
                $waitingForInput = 0;
                writeDataFileIntact("$setup_path/config.txt", \%config);
        } elsif (!$xKore && $conState == 3 && $waitingForInput) {
                $config{'char'} = $input;
                $waitingForInput = 0;
                writeDataFileIntact("$setup_path/config.txt", \%config);
                sendCharLogin(\$remote_socket, $config{'char'});
                $timeout{'charlogin'}{'time'} = time;


#Parse command...ugh

        } elsif ($switch eq "a") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                ($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)/;
                if ($arg1 =~ /^\d+$/ && $monstersID[$arg1] eq "") {
                        print        "������� 'a' (Attack Monster)\n"
                                ,"���� $arg1 ������.\n";
                } elsif ($arg1 =~ /^\d+$/) {
                        attack($monstersID[$arg1]);
                } elsif ($arg1 eq "no") {
                        configModify("attackAuto", 1);
                } elsif ($arg1 eq "yes") {
                        configModify("attackAuto", 2);
                } else {
                        print        "��Ч�Ĳ��� 'a' (Attack Monster)\n"
                                ,"ʹ�÷���: attack <monster # | no | yes >\n";
                }

        } elsif ($switch eq "auth") {
                ($arg1, $arg2) = $input =~ /^[\s\S]*? ([\s\S]*) ([\s\S]*?)$/;
                if ($arg1 eq "" || ($arg2 ne "1" && $arg2 ne "0")) {
                        print        "��Ч�Ĳ��� 'auth' (Overall Authorize)\n"
                                ,"ʹ�÷���: auth <username> <flag>\n";
                } else {
                        auth($arg1, $arg2);
                }

        } elsif ($switch eq "bestow") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($currentChatRoom eq "") {
                        print        "������� 'bestow' (Bestow Admin in Chat)\n"
                                ,"�㲻��������.\n";
                } elsif ($arg1 eq "") {
                        print        "��Ч�Ĳ��� 'bestow' (Bestow Admin in Chat)\n"
                                ,"ʹ�÷���: bestow <user #>\n";
                } elsif ($currentChatRoomUsers[$arg1] eq "") {
                        print        "������� 'bestow' (Bestow Admin in Chat)\n"
                                ,"��������� $arg1 ������.\n";
                } else {
                        sendChatRoomBestow(\$remote_socket, $currentChatRoomUsers[$arg1]);
                }

        } elsif ($switch eq "buy") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
                if ($arg1 eq "") {
                        print        "��Ч�Ĳ��� 'buy' (Buy Store Item)\n"
                                ,"ʹ�÷���: buy <item #> [<amount>]\n";
                } elsif ($storeList[$arg1] eq "") {
                        print        "������� 'buy' (Buy Store Item)\n"
                                ,"�̵���Ʒ $arg1 ������.\n";
                } else {
                        if ($arg2 <= 0) {
                                $arg2 = 1;
                        }
                        sendBuy(\$remote_socket, $storeList[$arg1]{'nameID'}, $arg2);
                }

        } elsif ($switch eq "c") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($arg1 eq "") {
                        print        "��Ч�Ĳ��� 'c' (Chat)\n"
                                ,"ʹ�÷���: c <message>\n";
                } else {
                        sendMessage(\$remote_socket, "c", $arg1);
                }

        #Cart command - chobit andy 20030101
        } elsif ($switch eq "cart") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? \w+ \d+ (\d+)/;

                if ($arg1 eq "" || $arg1 eq "eq" || $arg1 eq "u" || $arg1 eq "nu") {
                        printc("nyn", "-----------", "������Ʒ", "-----------\n");
                        printItemList(\@{$cart{'inventory'}}, $arg1);
                        print "------------------------------\n";
                        print "����: " . int($cart{'items'}) . "/" . int($cart{'items_max'}) . "  ����: " . int($cart{'weight'}) . "/" . int($cart{'weight_max'}) . "\n";
                        print "------------------------------\n";
                } elsif ($arg1 eq "log") {
			logItem("$logs_path/item_cart.txt", \%cart, "������Ʒ");
                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'inventory'}[$arg2] eq "") {
                        print        "������� 'cart add' (Add Item to Cart)\n"
                                ,"������Ʒ $arg2 ������.\n";
                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/) {
                        if (!$arg3 || $arg3 > $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'}) {
                                $arg3 = $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'};
                        }
                        sendCartAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg2]{'index'}, $arg3);
                } elsif ($arg1 eq "add" && $arg2 eq "") {
                        print        "��Ч�Ĳ��� 'cart add' (Add Item to Cart)\n"
                                ,"ʹ�÷���: cart add <item #>\n";
                } elsif ($arg1 eq "get" && $arg2 =~ /\d+/ && !%{$cart{'inventory'}[$arg2]}) {
                        print        "������� 'cart get' (Get Item from Cart)\n"
                                ,"������Ʒ $arg2 ������.\n";
                } elsif ($arg1 eq "get" && $arg2 =~ /\d+/) {
                        if (!$arg3 || $arg3 > $cart{'inventory'}[$arg2]{'amount'}) {
                                $arg3 = $cart{'inventory'}[$arg2]{'amount'};
                        }
                        sendCartGet(\$remote_socket, $arg2, $arg3);
                } elsif ($arg1 eq "get" && $arg2 eq "") {
                        print        "��Ч�Ĳ��� 'cart get' (Get Item from Cart)\n"
                                ,"ʹ�÷���: cart get <cart item #>\n";
                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/ && !%{$cart{'inventory'}[$arg2]}) {
                        print        "������� 'cart desc' (Cart Item Desciption)\n"
                                ,"������Ʒ $arg2 ������.\n";
                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/) {
                        printItemDesc($cart{'inventory'}[$arg2]{'nameID'});
                } else {
                        print        "��Ч�Ĳ��� 'cart' (Cart Items List)\n"
                                ,"ʹ�÷���: cart [<eq | u | nu | log | desc>] [<cart #>]\n"
                                ,"          cart [<add | get | close>] [<inventory # | cart #>] [<amount>]\n";
                }


        } elsif ($switch eq "chat") {
                ($replace, $title) = $input =~ /(^[\s\S]*? \"([\s\S]*?)\" ?)/;
                $qm = quotemeta $replace;
                $input =~ s/$qm//;
                @arg = split / /, $input;
                if ($title eq "") {
                        print        "��Ч�Ĳ��� 'chat' (Create Chat Room)\n"
                                ,qq~ʹ�÷���: chat "<title>" [<limit #> <public flag> <password>]\n~;
                } elsif ($currentChatRoom ne "") {
                        print        "������� 'chat' (Create Chat Room)\n"
                                ,"���Ѿ�����������.\n";
                } else {
			$arg[0] = ($arg[0] eq "") ? 20 : $arg[0];
			$arg[1] = ($arg[1] eq "") ? 1 : $arg[1];
                        sendChatRoomCreate(\$remote_socket, $title, $arg[0], $arg[1], $arg[2]);
                        $createdChatRoom{'title'} = $title;
                        $createdChatRoom{'ownerID'} = $accountID;
                        $createdChatRoom{'limit'} = $arg[0];
                        $createdChatRoom{'public'} = $arg[1];
                        $createdChatRoom{'num_users'} = 1;
                        $createdChatRoom{'users'}{$chars[$config{'char'}]{'name'}} = 2;
                }


        } elsif ($switch eq "chatmod") {
                ($replace, $title) = $input =~ /(^[\s\S]*? \"([\s\S]*?)\" ?)/;
                $qm = quotemeta $replace;
                $input =~ s/$qm//;
                @arg = split / /, $input;
                if ($title eq "") {
                        print        "��Ч�Ĳ��� 'chatmod' (Modify Chat Room)\n"
                                ,qq~ʹ�÷���: chatmod "<title>" [<limit #> <public flag> <password>]\n~;
                } else {
			$arg[0] = ($arg[0] eq "") ? 20 : $arg[0];
			$arg[1] = ($arg[1] eq "") ? 1 : $arg[1];
                        sendChatRoomChange(\$remote_socket, $title, $arg[0], $arg[1], $arg[2]);
                }

#####
        } elsif ($switch eq "cl") {
                chatLog_clear();
                print qq~Chat log cleared.\n~;

        } elsif ($switch eq "conf") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                ($arg2) = $input =~ /^[\s\S]*? \w+ ([\s\S]+)$/;
                @{$ai_v{'temp'}{'conf'}} = keys %config;
                if ($arg1 eq "") {
                        print        "��Ч�Ĳ��� 'conf' (Config Modify)\n"
                                ,"ʹ�÷���: conf <variable> [<value>]\n";
                } elsif (binFind(\@{$ai_v{'temp'}{'conf'}}, $arg1) eq "") {
                        print "Config ���� $arg1 ������\n";
                } elsif ($arg2 eq "value") {
                        print "Config '$arg1' ��ֵΪ $config{$arg1}\n";
                } else {
                        configModify($arg1, $arg2);
                }

        } elsif ($switch eq "cri") {
                if ($currentChatRoom eq "") {
                        print        "������� 'cri' (Chat Room Information)\n"
                                ,"�㲻����������.\n";
                } else {
                        my $public_string = ($chatRooms{$currentChatRoom}{'public'}) ? "Public" : "Private";
                        my $limit_string = $chatRooms{$currentChatRoom}{'num_users'}."/".$chatRooms{$currentChatRoom}{'limit'};
                	printc("nyn", "----------", "��������Ϣ", "----------\n");
	                printc("w", "����                                 ����  ����/˽��\n");
			print sprintf("%-36s %-5s %-8s\n",$chatRooms{$currentChatRoom}{'title'},$limit_string,$public_string);
                        printc("nwn", "----", "���", "----\n");
                        for ($i = 0; $i < @currentChatRoomUsers; $i++) {
                                next if ($currentChatRoomUsers[$i] eq "");
                                my $user_string = $currentChatRoomUsers[$i];
                                my $admin_string = ($chatRooms{$currentChatRoom}{'users'}{$currentChatRoomUsers[$i]} > 1) ? "(A)" : "";
				print sprintf("%-3d %-3s %-24s\n", $i, $admin_string, $user_string);
                        }
                        print "------------------------------\n";
                }

        } elsif ($switch eq "crl") {
               	printc("nyn", "----------", "�������б�", "----------\n");
                printc("w", "#   ����                                 ������                 ����  ����/˽��\n");                	
                for ($i = 0; $i < @chatRoomsID; $i++) {
       	                next if ($chatRoomsID[$i] eq "");
               	        my $owner_string = ($chatRooms{$chatRoomsID[$i]}{'ownerID'} ne $accountID) ? $players{$chatRooms{$chatRoomsID[$i]}{'ownerID'}}{'name'} : $chars[$config{'char'}]{'name'};
                       	my $public_string = ($chatRooms{$chatRoomsID[$i]}{'public'}) ? "Public" : "Private";
                        my $limit_string = $chatRooms{$chatRoomsID[$i]}{'num_users'}."/".$chatRooms{$chatRoomsID[$i]}{'limit'};
			print sprintf("%-3d %-36s %-22s %-5s %-8s\n", $i, $chatRooms{$chatRoomsID[$i]}{'title'}, $owner_string, $limit_string, $public_string);
                }
                print "------------------------------\n";


        } elsif ($switch eq "deal") {
                @arg = split / /, $input;
                shift @arg;
                if (%currentDeal && $arg[0] =~ /\d+/) {
                        print        "������� 'deal' (Deal a Player)\n"
                                ,"���Ѿ��ڽ�����.\n";
                } elsif (%incomingDeal && $arg[0] =~ /\d+/) {
                        print        "������� 'deal' (Deal a Player)\n"
                                ,"���������ֹ�����еĽ���.\n";
                } elsif ($arg[0] =~ /\d+/ && !$playersID[$arg[0]]) {
                        print        "������� 'deal' (Deal a Player)\n"
                                ,"��� $arg[0] ������.\n";
                } elsif ($arg[0] =~ /\d+/) {
                        $outgoingDeal{'ID'} = $playersID[$arg[0]];
                        sendDeal(\$remote_socket, $playersID[$arg[0]]);
			printc("wy", "<��Ϣ> ", "��ѯ�� $players{$playersID[$arg[0]]}{'name'} Ը��Ը�⽻�׵���\n");

                } elsif ($arg[0] eq "no" && !%incomingDeal && !%outgoingDeal && !%currentDeal) {
                        print        "������� 'deal no' (Deal Cancel)\n"
                                ,"û���κν��׿���ȡ��.\n";
                } elsif ($arg[0] eq "no" && (%incomingDeal || %outgoingDeal)) {
                        sendDealCancel(\$remote_socket);
                } elsif ($arg[0] eq "no" && %currentDeal) {
                        sendCurrentDealCancel(\$remote_socket);

                } elsif ($arg[0] eq "" && !%incomingDeal && !%currentDeal) {
                        print        "������� 'deal' (Deal a Player)\n"
                                ,"û���κν��׿��Խ���.\n";
                } elsif ($arg[0] eq "" && $currentDeal{'you_finalize'} && !$currentDeal{'other_finalize'}) {
                        print        "������� 'deal' (Deal a Player)\n"
                                ,"�޷���ɽ��� - $currentDeal{'name'} ��δȷ�Ͻ���.\n";
                } elsif ($arg[0] eq "" && $currentDeal{'final'}) {
                        print        "������� 'deal' (Deal a Player)\n"
                                ,"���Ѿ�ȷ�Ͽ�ʼ����.\n";
                } elsif ($arg[0] eq "" && %incomingDeal) {
                        sendDealAccept(\$remote_socket);
                } elsif ($arg[0] eq "" && $currentDeal{'you_finalize'} && $currentDeal{'other_finalize'}) {
                        sendDealTrade(\$remote_socket);
                        $currentDeal{'final'} = 1;
                        printc("ww", "<��Ϣ> ", "��ȷ�Ͽ�ʼ����\n");
                } elsif ($arg[0] eq "" && %currentDeal) {
                        sendDealAddItem(\$remote_socket, 0, $currentDeal{'you_zenny'});
                        sendDealFinalize(\$remote_socket);

                } elsif ($arg[0] eq "add" && !%currentDeal) {
                        print        "������� 'deal add' (Add Item to Deal)\n"
                                ,"�޷������κ���Ʒ�������� - ��û���ڽ���.\n";
                } elsif ($arg[0] eq "add" && $currentDeal{'you_finalize'}) {
                        print        "������� 'deal add' (Add Item to Deal)\n"
                                ,"�޷������κ���Ʒ�������� - ���Ѿ�ȷ�Ͽ�ʼ����.\n";
                } elsif ($arg[0] eq "add" && $arg[1] =~ /\d+/ && !%{$chars[$config{'char'}]{'inventory'}[$arg[1]]}) {
                        print        "������� 'deal add' (Add Item to Deal)\n"
                                ,"������Ʒ $arg[1] ������.\n";
                } elsif ($arg[0] eq "add" && $arg[2] && $arg[2] !~ /\d+/) {
                        print        "������� 'deal add' (Add Item to Deal)\n"
                                ,"��������Ϊ����, �ұ��������.\n";
                } elsif ($arg[0] eq "add" && $arg[1] =~ /\d+/) {
                        if (scalar(keys %{$currentDeal{'you'}}) < 10) {
                                if (!$arg[2] || $arg[2] > $chars[$config{'char'}]{'inventory'}[$arg[1]]{'amount'}) {
                                        $arg[2] = $chars[$config{'char'}]{'inventory'}[$arg[1]]{'amount'};
                                }
                                $currentDeal{'lastItemAmount'} = $arg[2];
                                sendDealAddItem(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg[1]]{'index'}, $arg[2]);
                        } else {
        	                print        "������� 'deal add' (Add Item to Deal)\n"
	                                ,"���ֻ�ܽ���10����Ʒ.\n";
                        }
                } elsif ($arg[0] eq "add" && $arg[1] eq "z") {
                        if (!$arg[2] || $arg[2] > $chars[$config{'char'}]{'zenny'}) {
                                $arg[2] = $chars[$config{'char'}]{'zenny'};
                        }
                        $currentDeal{'you_zenny'} = $arg[2];
                        printc("ww", "<��Ϣ> ", "���뽻�׽�Ǯ: $arg[2] zeny\n");
                } else {
                        print        "��Ч�Ĳ��� 'deal' (Deal a player)\n"
                                ,"ʹ�÷���: deal [<Player # | no | add>] [<item #>] [<amount>]\n";
                }

        } elsif ($switch eq "dl") {
                if (!%currentDeal) {
        	        print        "������� 'dl' (Deal List)\n"
	                        ,"�޷���ʾ�����б� - ��û���ڽ���.\n";
                } else {
                	printc("nyn", "-----------", "�����б�", "-----------\n");
                        $other_string = $currentDeal{'name'};
                        $you_string = "��";
                        if ($currentDeal{'other_finalize'}) {
                                $other_string .= " - ��ȷ��";
                        } else {
                                $other_string .= " - δȷ��";
                        }                        	
                        if ($currentDeal{'you_finalize'}) {
                                $you_string .= " - ��ȷ��";
                        } else {
                                $you_string .= " - δȷ��";                        	
                        }
			print sprintf("%-30s %-30s\n", $you_string, $other_string);
                        undef @currentDealYou;
                        undef @currentDealOther;
                        foreach (keys %{$currentDeal{'you'}}) {
                                push @currentDealYou, $_;
                        }
                        foreach (keys %{$currentDeal{'other'}}) {
                                push @currentDealOther, $_;
                        }
                        $lastindex = @currentDealOther;
                        $lastindex = @currentDealYou if (@currentDealYou > $lastindex);
                        for ($i = 0; $i < $lastindex; $i++) {
                                if ($i < @currentDealYou) {
                                        $display = ($items_lut{$currentDealYou[$i]} ne "")
                                                ? $items_lut{$currentDealYou[$i]}
                                                : "Unknown ".$currentDealYou[$i];
                                        $display .= " x $currentDeal{'you'}{$currentDealYou[$i]}{'amount'}";
                                } else {
                                        $display = "";
                                }
                                if ($i < @currentDealOther) {
                                        $display2 = ($items_lut{$currentDealOther[$i]} ne "")
                                                ? $items_lut{$currentDealOther[$i]}
                                                : "Unknown ".$currentDealOther[$i];
                                        $display2 .= " x $currentDeal{'other'}{$currentDealOther[$i]}{'amount'}";
                                } else {
                                        $display2 = "";
                                }
				print sprintf("%-30s %-30s\n", $display, $display2);
                        }
                        $you_string = ($currentDeal{'you_zenny'} ne "") ? $currentDeal{'you_zenny'} : 0;
                        $other_string = ($currentDeal{'other_zenny'} ne "") ? $currentDeal{'other_zenny'} : 0;
			print sprintf("Zeny: %-24s Zeny: %-24s\n", $you_string, $other_string);                        
                        print "------------------------------\n";
                }


        } elsif ($switch eq "drop") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
                if ($arg1 eq "") {
                        print        "��Ч�Ĳ��� 'drop' (Drop ������Ʒ)\n"
                                ,"ʹ�÷���: drop <item #> [<amount>]\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "������� 'drop' (Drop ������Ʒ)\n"
                                ,"������Ʒ $arg1 ������.\n";
                } else {
                        if (!$arg2 || $arg2 > $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'}) {
                                $arg2 = $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'};
                        }
                	printc("yw", "<ϵͳ> ", "��Ҫ�ӵ� $chars[$config{'char'}]{'inventory'}[$arg1]{'name'} x $arg2 ��(y/n) ");
			$temp_msg = "\0" x 256;
			$temp_msgLen = $input_recv->Call($temp_msg, 1);
			$temp_msg = substr($temp_msg, 0, $temp_msgLen);
                        if ($temp_msg =~ /y/) {
	                        sendDrop(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $arg2);
	                }
                }

        } elsif ($switch eq "dump") {
                dumpData($msg);

        } elsif ($switch eq "e") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                if ($arg1 eq "") {
                        printc("nyn", "-----------", "�����б�", "-----------\n");                	
                        printc("w", "#   ����\n");
                	my $i = 0;
                	while ($emotions_lut{$i} ne "") {
                		print sprintf("%-3d %-10s\n", $i, "$emotions_lut{$i}");
                		$i++;
                	}
                	print "------------------------------\n";
	        } elsif ($arg1 > 47 || $arg1 < 0) {
                        print        "��Ч�Ĳ��� 'e' (Emotion)\n"
                                ,"ʹ�÷���: e [<emotion # (0-47)>]\n";
                } else {
                        sendEmotion(\$remote_socket, $arg1);
                }

        } elsif ($switch eq "eq") {
                my ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                my ($arg2) = $input =~ /^[\s\S]*? \d+ (\w+)/;
                if ($arg1 eq "") {
                        print        "��Ч�Ĳ��� 'equip' (Equip Inventory Item)\n"
                                ,"ʹ�÷���: equip <item #> [left]\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "������� 'equip' (Equip Inventory Item)\n"
                                ,"������Ʒ $arg1 ������.\n";
                } elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type_equip'} == 0 && $chars[$config{'char'}]{'inventory'}[$arg1]{'type'} != 10) {
                        print        "������� 'equip' (Equip Inventory Item)\n"
                                ,"������Ʒ $arg1 ����װ��.\n";
                } else {
                        if ($chars[$config{'char'}]{'inventory'}[$arg1]{'type_equip'} == 2 && $arg2 eq "left") {
                                sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, 32);
                        } elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type_equip'} == 136 && $arg2 eq "left") {
                                sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, 128);
                        } else {
                                sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $chars[$config{'char'}]{'inventory'}[$arg1]{'type_equip'});
                        }
                        undef $chars[$config{'char'}]{'autoSwitch'};
                }

        } elsif ($switch eq "follow") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                if ($arg1 eq "") {
                        print        "��Ч�Ĳ��� 'follow' (Follow Player)\n"
                                ,"ʹ�÷���: follow <player #>\n";
                } elsif ($arg1 eq "stop") {
                        aiRemove("follow");
                        configModify("follow", 0);
                } elsif ($playersID[$arg1] eq "") {
                        print        "������� 'follow' (Follow Player)\n"
                                ,"��� $arg1 ������.\n";
                } else {
                        ai_follow($players{$playersID[$arg1]}{'name'});
                        configModify("follow", 1);
                        configModify("followTarget", $players{$playersID[$arg1]}{'name'});
                }

        #Guild Chat - chobit andy 20030101
        } elsif ($switch eq "g") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($arg1 eq "") {
                        print "��Ч�Ĳ��� 'g' (Guild Chat)\n"
                                ,"ʹ�÷���: g <message>\n";
                } else {
                        sendMessage(\$remote_socket, "g", $arg1);
                }
        } elsif ($switch eq "i") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                ($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
                if ($arg1 eq "" || $arg1 eq "eq" || $arg1 eq "u" || $arg1 eq "nu") {
                        printc("nyn", "-----------", "������Ʒ", "-----------\n");
                        printItemList(\@{$chars[$config{'char'}]{'inventory'}}, $arg1);
                        print "------------------------------\n";
                        print "����: " . int($chars[$config{'char'}]{'items'}) . "/" . int($chars[$config{'char'}]{'items_max'}) . "  ����: " . int($chars[$config{'char'}]{'weight'}) . "/" . int($chars[$config{'char'}]{'weight_max'}) . "\n";                        
		        print "------------------------------\n";
                } elsif ($arg1 eq "log") {
			logItem("$logs_path/item_inventory.txt", \%{$chars[$config{'char'}]}, "������Ʒ");

                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'inventory'}[$arg2] eq "") {
                        print        "������� 'i desc' (Iventory Item Desciption)\n"
                                ,"������Ʒ $arg2 ������.\n";
                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/) {
                        printItemDesc($chars[$config{'char'}]{'inventory'}[$arg2]{'nameID'});

                } else {
                        print        "��Ч�Ĳ��� 'i' (Iventory List)\n"
                                ,"ʹ�÷���: i [<eq | u | nu | desc>] [<inventory #>]\n";
                }

        } elsif ($switch eq "identify") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                if ($arg1 eq "") {
                        printc("nyn", "---------", "��Ʒ�����б�", "---------\n");
	                printc("w", "#   ����\n");
                        for ($i = 0; $i < @identifyID; $i++) {
                                next if ($identifyID[$i] eq "");
				print sprintf("%-3d %-40s\n",$i,$chars[$config{'char'}]{'inventory'}[$identifyID[$i]]{'name'});
                        }
                        print "------------------------------\n";
                } elsif ($arg1 =~ /\d+/ && $identifyID[$arg1] eq "") {
                        print        "������� 'identify' (Identify Item)\n"
                                ,"������Ʒ $arg1 ������.\n";

                } elsif ($arg1 =~ /\d+/) {
                        sendIdentify(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$identifyID[$arg1]]{'index'});
                } else {
                        print        "��Ч�Ĳ��� 'identify' (Identify Item)\n"
                                ,"ʹ�÷���: identify [<identify #>]\n";
                }


        } elsif ($switch eq "ignore") {
                ($arg1, $arg2) = $input =~ /^[\s\S]*? (\d+) ([\s\S]*)/;
                if ($arg1 eq "" || $arg2 eq "" || ($arg1 ne "0" && $arg1 ne "1")) {
                        print        "��Ч�Ĳ��� 'ignore' (Ignore Player/Everyone)\n"
                                ,"ʹ�÷���: ignore <flag> <name | all>\n";
                } else {
                        if ($arg2 eq "all") {
                                sendIgnoreAll(\$remote_socket, !$arg1);
                        } else {
                                sendIgnore(\$remote_socket, $arg2, !$arg1);
                        }
                }

        } elsif ($switch eq "il") {
                printc("nyn", "---------", "������Ʒ�б�", "---------\n");
                printc("w", "#   λ��      ����\n");                
                for ($i = 0; $i < @itemsID; $i++) {
                        next if ($itemsID[$i] eq "");
			print sprintf("%-3d %-9s %-40s\n",$i,"($items{$itemsID[$i]}{'pos'}{'x'},$items{$itemsID[$i]}{'pos'}{'y'})","$items{$itemsID[$i]}{'name'} x $items{$itemsID[$i]}{'amount'}");
                }
                print "------------------------------\n";

        } elsif ($switch eq "im") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
                if ($arg1 eq "" || $arg2 eq "") {
                        print        "��Ч�Ĳ��� 'im' (Use Item on Monster)\n"
                                ,"ʹ�÷���: im <item #> <monster #>\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "������� 'im' (Use Item on Monster)\n"
                                ,"������Ʒ $arg1 ������.\n";
                } elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
                        print        "������� 'im' (Use Item on Monster)\n"
                                ,"������Ʒ $arg1 ���ǿ�ʹ����Ʒ.\n";
                } elsif ($monstersID[$arg2] eq "") {
                        print        "������� 'im' (Use Item on Monster)\n"
                                ,"���� $arg2 ������.\n";
                } else {
                        sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $monstersID[$arg2]);
                }

        } elsif ($switch eq "ip") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
                if ($arg1 eq "" || $arg2 eq "") {
                        print        "��Ч�Ĳ��� 'ip' (Use Item on Player)\n"
                                ,"ʹ�÷���: ip <item #> <player #>\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "������� 'ip' (Use Item on Player)\n"
                                ,"������Ʒ $arg1 ������.\n";
                } elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
                        print        "������� 'ip' (Use Item on Player)\n"
                                ,"������Ʒ $arg1 ���ǿ�ʹ����Ʒ.\n";
                } elsif ($playersID[$arg2] eq "") {
                        print        "������� 'ip' (Use Item on Player)\n"
                                ,"��� $arg2 ������.\n";
                } else {
                        sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $playersID[$arg2]);
                }

        } elsif ($switch eq "is") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                if ($arg1 eq "") {
                        print        "��Ч�Ĳ��� 'is' (Use Item on Self)\n"
                                ,"ʹ�÷���: is <item #>\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "������� 'is' (Use Item on Self)\n"
                                ,"������Ʒ $arg1 ������.\n";
                } elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
                        print        "������� 'is' (Use Item on Self)\n"
                                ,"������Ʒ $arg1 is ���ǿ�ʹ����Ʒ.\n";
                } else {
                        sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $accountID);
                }

        } elsif ($switch eq "join") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ ([\s\S]*)$/;
                if ($arg1 eq "") {
                        print        "��Ч�Ĳ��� 'join' (Join Chat Room)\n"
                                ,"ʹ�÷���: join <chat room #> [<password>]\n";
                } elsif ($currentChatRoom ne "") {
                        print        "������� 'join' (Join Chat Room)\n"
                                ,"You are already in a chat room.\n";
                } elsif ($chatRoomsID[$arg1] eq "") {
                        print        "������� 'join' (Join Chat Room)\n"
                                ,"Chat Room $arg1 ������.\n";
                } else {
                        sendChatRoomJoin(\$remote_socket, $chatRoomsID[$arg1], $arg2);
                }

        } elsif ($switch eq "judge") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
                if ($arg1 eq "" || $arg2 eq "") {
                        print        "��Ч�Ĳ��� 'judge' (Give an alignment point to Player)\n"
                                ,"ʹ�÷���: judge <player #> <0 (good) | 1 (bad)>\n";
                } elsif ($playersID[$arg1] eq "") {
                        print        "������� 'judge' (Give an alignment point to Player)\n"
                                ,"��� $arg1 ������.\n";
                } else {
                        $arg2 = ($arg2 >= 1);
                        sendAlignment(\$remote_socket, $playersID[$arg1], $arg2);
                }

        } elsif ($switch eq "kick") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($currentChatRoom eq "") {
                        print        "������� 'kick' (Kick from Chat)\n"
                                ,"�㲻����������.\n";
                } elsif ($arg1 eq "") {
                        print        "��Ч�Ĳ��� 'kick' (Kick from Chat)\n"
                                ,"ʹ�÷���: kick <user #>\n";
                } elsif ($currentChatRoomUsers[$arg1] eq "") {
                        print        "������� 'kick' (Kick from Chat)\n"
                                ,"��������� $arg1 ������.\n";
                } else {
                        sendChatRoomKick(\$remote_socket, $currentChatRoomUsers[$arg1]);
                }

        } elsif ($switch eq "leave") {
                if ($currentChatRoom eq "") {
                        print        "������� 'leave' (Leave Chat Room)\n"
                                ,"�㲻����������.\n";
                } else {
                        sendChatRoomLeave(\$remote_socket);
                }

        } elsif ($switch eq "look") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
                if ($arg1 eq "") {
                        print        "��Ч�Ĳ��� 'look' (Look a Direction)\n"
                                ,"ʹ�÷���: look <body dir> [<head dir>]\n";
                } else {
                        look($arg1, $arg2);
                }

        } elsif ($switch eq "memo") {
                sendMemo(\$remote_socket);

        } elsif ($switch eq "ml") {
                printc("nyn", "-----------", "�����б�", "-----------\n");
                printc("w", "#   λ��      ���� ����                     �˺�     ����     ����\n");
                for ($i = 0; $i < @monstersID; $i++) {
                        next if ($monstersID[$i] eq "");
			print sprintf("%-3d %-9s %4s %-20s %8d %8d %8d\n",$i,"($monsters{$monstersID[$i]}{'pos_to'}{'x'},$monsters{$monstersID[$i]}{'pos_to'}{'y'})",int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$monstersID[$i]}{'pos_to'}})*10)/10,$monsters{$monstersID[$i]}{'name'},$monsters{$monstersID[$i]}{'dmgTo'},$monsters{$monstersID[$i]}{'dmgFromYou'},$monsters{$monstersID[$i]}{'dmgToYou'});                        
                }
                print "------------------------------\n";

        } elsif ($switch eq "move") {
                ($arg1, $arg2, $arg3) = $input =~ /^[\s\S]*? (\d+) (\d+)(.*?)$/;
                undef $ai_v{'temp'}{'map'};
                if ($arg1 eq "") {
                        ($ai_v{'temp'}{'map'}) = $input =~ /^[\s\S]*? (.*?)$/;
                } else {
                        $ai_v{'temp'}{'map'} = $arg3;
                }
                
                $ai_v{'temp'}{'map'} =~ s/\s//g;
                if (($arg1 eq "" || $arg2 eq "") && !$ai_v{'temp'}{'map'}) {
                        print        "��Ч�Ĳ��� 'move' (Move Player)\n"
                                ,"ʹ�÷���: move <x> <y> &| <map>\n";
                } elsif ($ai_v{'temp'}{'map'} eq "stop") {
                        aiRemove("move");
                        aiRemove("route");
                        aiRemove("route_getRoute");
                        aiRemove("route_getMapRoute");
                        print "ֹͣ�����ƶ�.\n";
                } else {
                        $ai_v{'temp'}{'map'} = $field{'name'} if ($ai_v{'temp'}{'map'} eq "");
                        if ($maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}) {
                                if ($arg2 ne "") {
                                        printc("yw", "<ϵͳ> ", "���ڼ���·��: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $arg1, $arg2\n");
                                        $ai_v{'temp'}{'x'} = $arg1;
                                        $ai_v{'temp'}{'y'} = $arg2;
                                } else {
                                        printc("yw", "<ϵͳ> ", "���ڼ���·��: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'})\n");
                                        undef $ai_v{'temp'}{'x'};
                                        undef $ai_v{'temp'}{'y'};
                                }
                                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
                        } else {
	                        print        "������� 'move' (Move Player)\n"
                                	,"��ͼ $ai_v{'temp'}{'map'} ������.\n";
                        }
                }

        } elsif ($switch eq "nl") {
                printc("nyn", "-----------", "�����б�", "-----------\n");
                printc("w", "#   λ��      ����\n");
                for ($i = 0; $i < @npcsID; $i++) {
                        next if ($npcsID[$i] eq "");
			print sprintf("%-3d %-9s %-40s\n",$i,"($npcs{$npcsID[$i]}{'pos'}{'x'},$npcs{$npcsID[$i]}{'pos'}{'y'})",$npcs{$npcsID[$i]}{'name'});                        
                }
                print "------------------------------\n";

        } elsif ($switch eq "p") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($arg1 eq "") {
                        print        "��Ч�Ĳ��� 'p' (Party Chat)\n"
                                ,"ʹ�÷���: p <message>\n";
                } else {
                        sendMessage(\$remote_socket, "p", $arg1);
                }

        } elsif ($switch eq "party") {
                ($arg1) = $input =~ /^[\s\S]*? (\w*)/;
                ($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)\b/;
                if ($arg1 eq "" && !%{$chars[$config{'char'}]{'party'}}) {
                        print        "������� 'party' (Party Functions)\n"
                                ,"�޷���ʾ�����б� - ��û�ж���.\n";
                } elsif ($arg1 eq "") {
	                printc("nyn", "-----------", "�����б�", "-----------\n");
	                print "����: $chars[$config{'char'}]{'party'}{'name'}\n";
                        printc("w", "#       ���                     ��ͼ        λ��      ���� HP\n");
                        for ($i = 0; $i < @partyUsersID; $i++) {
                                next if ($partyUsersID[$i] eq "");
                                $coord_string = "";
                                $hp_string = "";
                                $name_string = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'name'};
                                $admin_string = ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'admin'}) ? "(A)" : "";

                                if ($partyUsersID[$i] eq $accountID) {
                                        $online_string = "Yes";
                                        ($map_string) = $map_name =~ /([\s\S]*)\.gat/;
                                        $coord_string = "($chars[$config{'char'}]{'pos'}{'x'},$chars[$config{'char'}]{'pos'}{'y'})";
                                        $hp_string = $chars[$config{'char'}]{'hp'}."/".$chars[$config{'char'}]{'hp_max'}
                                                        ." (".int($chars[$config{'char'}]{'hp'}/$chars[$config{'char'}]{'hp_max'} * 100)
                                                        ."%)";
                                } else {
                                        $online_string = ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'}) ? "Yes" : "No";
                                        ($map_string) = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'map'} =~ /([\s\S]*)\.gat/;
                                        $coord_string = "($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'x'}"
                                                . ","."$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'y'})"
                                                if ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'x'} ne ""
                                                        && $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'});
                                        $hp_string = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp'}."/".$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'}
                                                        ." (".int($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp'}/$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'} * 100)
                                                        ."%)" if ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'} && $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'});
                                }
				print sprintf("%-3d %-3s %-24s %-11s %-9s %-4s %-11s\n", $i, $admin_string, $name_string, $map_string,  $coord_string, $online_string, $hp_string);
                        }
                        print "------------------------------\n";

        } elsif ($arg1 eq "create") {
                        ($arg2) = $input =~ /^[\s\S]*? [\s\S]*? \"([\s\S]*?)\"/;
                        if ($arg2 eq "") {
                                print        "��Ч�Ĳ��� 'party create' (Organize Party)\n"
                                ,qq~ʹ�÷���: party create "<party name>"\n~;
                        } else {
                                sendPartyOrganize(\$remote_socket, $arg2);
                        }

                } elsif ($arg1 eq "join" && $arg2 ne "1" && $arg2 ne "0") {
                        print        "��Ч�Ĳ��� 'party join' (Accept/Deny Party Join Request)\n"
                                ,"ʹ�÷���: party join <flag>\n";
                } elsif ($arg1 eq "join" && $incomingParty{'ID'} eq "") {
                        print        "������� 'party join' (Join/Request to Join Party)\n"
                                ,"�޷����ܻ�ܾ��������� - û�ж�������.\n";
                } elsif ($arg1 eq "join") {
                        sendPartyJoin(\$remote_socket, $incomingParty{'ID'}, $arg2);
                        undef %incomingParty;

                } elsif ($arg1 eq "request" && !%{$chars[$config{'char'}]{'party'}}) {
                        print        "������� 'party request' (Request to Join Party)\n"
                                ,"�޷�������� - ��û�ж���.\n";
                } elsif ($arg1 eq "request" && $playersID[$arg2] eq "") {
                        print        "������� 'party request' (Request to Join Party)\n"
                                ,"�޷�������� - ��� $arg2 ������.\n";
                } elsif ($arg1 eq "request") {
                        sendPartyJoinRequest(\$remote_socket, $playersID[$arg2]);

                } elsif ($arg1 eq "leave" && !%{$chars[$config{'char'}]{'party'}}) {
                        print        "������� 'party leave' (Leave Party)\n"
                                ,"�޷��뿪���� - ��û�ж���.\n";
                } elsif ($arg1 eq "leave") {
                        sendPartyLeave(\$remote_socket);

                } elsif ($arg1 eq "share" && !%{$chars[$config{'char'}]{'party'}}) {
                        print        "������� 'party share' (Set Party Share EXP)\n"
                                ,"�޷��趨����ֵ���� - ��û�ж���.\n";
                } elsif ($arg1 eq "share" && $arg2 ne "1" && $arg2 ne "0") {
                        print        "��Ч�Ĳ��� 'party share' (Set Party Share EXP)\n"
                                ,"ʹ�÷���: party share <flag>\n";
                } elsif ($arg1 eq "share") {
                        sendPartyShareEXP(\$remote_socket, $arg2);

                } elsif ($arg1 eq "kick" && !%{$chars[$config{'char'}]{'party'}}) {
                        print        "������� 'party kick' (Kick Party Member)\n"
                                ,"�޷��߳���� - ��û�ж���.\n";
                } elsif ($arg1 eq "kick" && $arg2 eq "") {
                        print        "��Ч�Ĳ��� 'party kick' (Kick Party Member)\n"
                                ,"ʹ�÷���: party kick <party member #>\n";
                } elsif ($arg1 eq "kick" && $partyUsersID[$arg2] eq "") {
                        print        "������� 'party kick' (Kick Party Member)\n"
                                ,"�޷��߳���� - ��� $arg2 ������.\n";
                } elsif ($arg1 eq "kick") {
                        sendPartyKick(\$remote_socket, $partyUsersID[$arg2], $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$arg2]}{'name'});
                }

        } elsif ($switch eq "pet") {
                my ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                if ( $arg1 eq "info" || $arg1 eq "") {
	                printc("nyn", "-----------", "������Ϣ", "-----------\n");
                        print sprintf("����  : %-20s ����  : %-2s\n",$chars[$config{'char'}]{'pet'}{'name'},$chars[$config{'char'}]{'pet'}{'level'});
                        print sprintf("��ʳ��: %-20s ���ܶ�: %-10s\n",$chars[$config{'char'}]{'pet'}{'hungry'}."/100",$chars[$config{'char'}]{'pet'}{'friendly'}."/1000");
                        print "------------------------------\n";
                } elsif ( $arg1 eq "feed"){
                        sendPetCommand(\$remote_socket,1);
                        print "��������ι������\n";
                } elsif ( $arg1 eq "play"){
                        sendPetCommand(\$remote_socket,2);
                        print "���������������\n";
                } elsif ( $arg1 eq "back"){
                        sendPetCommand(\$remote_socket,3);
                        print "���������������\n";
                } else {
                        print "��Ч�Ĳ��� 'pet' ( pet command )\n"
                        ,"ʹ�÷���: pet [<info | feed | play | back>]\n";
                }

        } elsif ($switch eq "petl") {
                printc("nyn", "-----------", "�����б�", "-----------\n");
                printc("w", "#   ����                         ����\n");
                for (my $i = 0; $i < @petsID; $i++) {
                        next if ($petsID[$i] eq "");
                        print sprintf("%-3d %-24s %-24s\n",$i,$pets{$petsID[$i]}{'name'},$pets{$petsID[$i]}{'name_given'});
                }
                print "------------------------------\n";

        } elsif ($switch eq "pm") {
                ($arg1, $arg2) =$input =~ /^[\s\S]*? "([\s\S]*?)" ([\s\S]*)/;
                $type = 0;
                if (!$arg1) {
                        ($arg1, $arg2) =$input =~ /^[\s\S]*? (\d+) ([\s\S]*)/;
                        $type = 1;
                }
                if ($arg1 eq "" || $arg2 eq "") {
                        print        "��Ч�Ĳ��� 'pm' (Private Message)\n"
                                ,qq~ʹ�÷���: pm ("<username>" | <pm #>) <message>\n~;
                } elsif ($type) {
                        if ($arg1 - 1 >= @privMsgUsers) {
                                print        "������� 'pm' (Private Message)\n"
                                ,"˽���б���� $arg1 ������.\n";
                        } else {
                                sendMessage(\$remote_socket, "pm", $arg2, $privMsgUsers[$arg1 - 1]);
                                $lastpm{'msg'} = $arg2;
                                $lastpm{'user'} = $privMsgUsers[$arg1 - 1];
                        }
                } else {
                        if ($arg1 =~ /^%(\d*)$/) {
                                $arg1 = $1;
                        }
#pml bugfix - chobit andy 20030127
                        if (binFind(\@privMsgUsers, $arg1) eq "") {
                                $privMsgUsers[@privMsgUsers] = $arg1;
                        }
                        sendMessage(\$remote_socket, "pm", $arg2, $arg1);
                        $lastpm{'msg'} = $arg2;
                        $lastpm{'user'} = $arg1;
                }

        } elsif ($switch eq "pml") {
                $~ = "PMLIST";
                printc("nyn", "-----------", "˽���б�", "-----------\n");
                printc("w", "#   ����\n");
                for ($i = 1; $i <= @privMsgUsers; $i++) {
			print sprintf("%-3d %-30s\n",$i,$privMsgUsers[$i - 1]);
		}
                print "------------------------------\n";

        } elsif ($switch eq "pl") {
                printc("nyn", "-----------", "����б�", "-----------\n");
                printc("w", "#   λ��      ���� ����                                       �Ա� ְҵ\n");
                for ($i = 0; $i < @playersID; $i++) {
                        next if ($playersID[$i] eq "");
                        if (%{$players{$playersID[$i]}{'guild'}}) {
                                $name = "$players{$playersID[$i]}{'name'} [$players{$playersID[$i]}{'guild'}{'name'}]";
                        } else {
                                $name = $players{$playersID[$i]}{'name'};
                        }
			print sprintf("%-3d %-9s %4s %-42s %-2s %-4s\n",$i,"($players{$playersID[$i]}{'pos_to'}{'x'},$players{$playersID[$i]}{'pos_to'}{'y'})",int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$playersID[$i]}{'pos_to'}}) * 10) / 10,$name,$sex_lut{$players{$playersID[$i]}{'sex'}},$jobs_lut{$players{$playersID[$i]}{'jobID'}});
                }
                print "------------------------------\n";

        } elsif ($switch eq "portals") {
                printc("nyn", "----------", "���͵��б�", "----------\n");
                printc("w", "#   λ��      ����\n");
                for ($i = 0; $i < @portalsID; $i++) {
                        next if ($portalsID[$i] eq "");
			print sprintf("%-3d %-9s %-40s\n",$i,"($portals{$portalsID[$i]}{'pos'}{'x'},$portals{$portalsID[$i]}{'pos'}{'y'})",$portals{$portalsID[$i]}{'name'});
                }
                print "------------------------------\n";

        } elsif ($switch eq "quit") {
                quit();

        } elsif ($switch eq "reload") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                parseReload($arg1);

        } elsif ($switch eq "relog") {
                relog();

        } elsif ($switch eq "respawn") {
                sendRespawn(\$remote_socket);

        } elsif ($switch eq "s") {
                my $hp_string = $chars[$config{'char'}]{'hp'}."/".$chars[$config{'char'}]{'hp_max'}." ("
                                .int($chars[$config{'char'}]{'hp'}/$chars[$config{'char'}]{'hp_max'} * 100)
                                ."%)" if $chars[$config{'char'}]{'hp_max'};
                my $sp_string = $chars[$config{'char'}]{'sp'}."/".$chars[$config{'char'}]{'sp_max'}." ("
                                .int($chars[$config{'char'}]{'sp'}/$chars[$config{'char'}]{'sp_max'} * 100)
                                ."%)" if $chars[$config{'char'}]{'sp_max'};
                my $base_string = getFormattedNumber($chars[$config{'char'}]{'exp'})."/".getFormattedNumber($chars[$config{'char'}]{'exp_max'})."("
                                .sprintf("%.2f",$chars[$config{'char'}]{'exp'}/$chars[$config{'char'}]{'exp_max'} * 100)
                                ."%)" if $chars[$config{'char'}]{'exp_max'};
                my $job_string = getFormattedNumber($chars[$config{'char'}]{'exp_job'})."/".getFormattedNumber($chars[$config{'char'}]{'exp_job_max'})."("
                                .sprintf("%.2f",$chars[$config{'char'}]{'exp_job'}/$chars[$config{'char'}]{'exp_job_max'} * 100)
                                ."%)" if $chars[$config{'char'}]{'exp_job_max'};
                my $weight_string = $chars[$config{'char'}]{'weight'}."/".$chars[$config{'char'}]{'weight_max'}." ("
                                .int($chars[$config{'char'}]{'weight'}/$chars[$config{'char'}]{'weight_max'} * 100)
                                ."%)" if $chars[$config{'char'}]{'weight_max'};
                if (($chars[$config{'char'}]{'weight'}/$chars[$config{'char'}]{'weight_max'}) >= 0.5) {
                	$ai_v{'temp'}{'color'} = "r";
                } else {
                	$ai_v{'temp'}{'color'} = "n";
                }
		printc("ny", "----------------", "������Ϣ����");
                if ($vipLevel) {
                	printc("nyn", "----------", "VIP $vipLevel", "-\n");                	
                } else {
                	printc("n", "----------------\n");
                }
                printc("wwn", sprintf("%-23s", $chars[$config{'char'}]{'name'}), "HP", sprintf("%19s\n",$hp_string));
                printc("nwn", sprintf("%-23s", "$sex_lut{$chars[$config{'char'}]{'sex'}} $jobs_lut{$chars[$config{'char'}]{'jobID'}}"), "SP", sprintf("%19s\n\n",$sp_string));
                printc("wnn", "Base Lv. ", sprintf("%-2s", $chars[$config{'char'}]{'lv'}), sprintf("%33s\n",$base_string));
                printc("wnn", "Job  Lv. ", sprintf("%-2s", $chars[$config{'char'}]{'lv_job'}),sprintf("%33s\n",$job_string));
		printc("w".$ai_v{'temp'}{'color'}."wn", "Weight ", sprintf("%-18s",$weight_string), "Zeny", sprintf("%15s\n",getFormattedNumber($chars[$config{'char'}]{'zenny'})."z"));
                print "--------------------------------------------\n";
                printStatus("%-22s", 2, \%{$chars[$config{'char'}]});
                print "--------------------------------------------\n";

        } elsif ($switch eq "sell") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
                if ($arg1 eq "" && $talk{'buyOrSell'}) {
                        sendGetSellList(\$remote_socket, $talk{'ID'});

                } elsif ($arg1 eq "") {
                        print        "��Ч�Ĳ��� 'sell' (Sell ������Ʒ)\n"
                                ,"ʹ�÷���: sell <item #> [<amount>]\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "������� 'sell' (Sell ������Ʒ)\n"
                                ,"������Ʒ $arg1 ������.\n";
                } else {
                        if (!$arg2 || $arg2 > $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'}) {
                                $arg2 = $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'};
                        }
                        sendSell(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $arg2);
                }

        } elsif ($switch eq "send") {
                ($args) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                sendRaw(\$remote_socket, $args);

        } elsif ($switch eq "sit") {
                $ai_v{'attackAuto_old'} = $config{'attackAuto'} if ($ai_v{'attackAuto_old'} eq "");
                $ai_v{'route_randomWalk_old'} = $config{'route_randomWalk'} if ($ai_v{'route_randomWalk_old'} eq "");
                configModify("attackAuto", 1);
                configModify("route_randomWalk", 0);
                aiRemove("move");
                aiRemove("route");
                aiRemove("route_getRoute");
                aiRemove("route_getMapRoute");
                sit();
                $ai_v{'sitAuto_forceStop'} = 0;

        } elsif ($switch eq "sm") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
                ($arg3) = $input =~ /^[\s\S]*? \d+ \d+ (\d+)/;
                if ($arg1 eq "" || $arg2 eq "") {
                        print        "��Ч�Ĳ��� 'sm' (Use Skill on Monster)\n"
                                ,"ʹ�÷���: sm <skill #> <monster #> [<skill lvl>]\n";
                } elsif ($monstersID[$arg2] eq "") {
                        print        "������� 'sm' (Use Skill on Monster)\n"
                                ,"���� $arg2 ������.\n";
                } elsif ($skillsID[$arg1] eq "") {
                        print        "������� 'sm' (Use Skill on Monster)\n"
                                ,"���� $arg1 ������.\n";
                } else {
                        if (!$arg3 || $arg3 > $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'}) {
                                $arg3 = $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'};
                        }
                        if (!ai_getSkillUseType($skillsID[$arg1])) {
                                ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $monstersID[$arg2]);
                        } else {
                                ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $monsters{$monstersID[$arg2]}{'pos_to'}{'x'}, $monsters{$monstersID[$arg2]}{'pos_to'}{'y'});
                        }
                }

        } elsif ($switch eq "skills") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                ($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
                if ($arg1 eq "") {
                        printc("nyn", "-----------", "�����б�", "-----------\n");
                        printc("w", "#   ��������             ����     ����SP\n");
                        for ($i=0; $i < @skillsID; $i++) {
                 	       print sprintf("%-3d %-20s %-8s %-8s\n",$i,$skills_lut{$skillsID[$i]},$chars[$config{'char'}]{'skills'}{$skillsID[$i]}{'lv'},$skillsSP_lut{$skillsID[$i]}{$chars[$config{'char'}]{'skills'}{$skillsID[$i]}{'lv'}});
	                }
                        print "-------------------------------\n";
                        print "ʣ�༼�ܵ���: $chars[$config{'char'}]{'points_skill'}\n";
                        print "-------------------------------\n";

                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $skillsID[$arg2] eq "") {
                        print        "������� 'skills add' (Add Skill Point)\n"
                                ,"���� $arg2 ������.\n";
                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'points_skill'} < 1) {
                        print        "������� 'skills add' (Add Skill Point)\n"
                                ,"û���㹻�ļ��ܵ���.\n";
                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/) {
                	printc("yw", "<ϵͳ> ", "��Ҫ�Ѽ��ܵ����� $skills_lut{$skillsID[$arg2]} ��(y/n) ");
			$temp_msg = "\0" x 256;
			$temp_msgLen = $input_recv->Call($temp_msg, 1);
			$temp_msg = substr($temp_msg, 0, $temp_msgLen);
                        if ($temp_msg =~ /y/) {
	                        sendAddSkillPoint(\$remote_socket, $chars[$config{'char'}]{'skills'}{$skillsID[$arg2]}{'ID'});
	                }

                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/ && $skillsID[$arg2] eq "") {
                        print        "������� 'skills desc' (Skill Description)\n"
                                ,"���� $arg2 ������.\n";
                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/) {
		        dynParseFiles("data/skillsdescriptions.txt", \%skillsDesc_lut, \&parseRODescLUT);
                        printc("nyn", "-----------", "����˵��", "-----------\n");
                        printc("w", "����: $skills_lut{$skillsID[$arg2]}\n\n");
                        print $skillsDesc_lut{$skillsID[$arg2]};
                        print "-------------------------------\n";
                        undef %skillsDesc_lut;
                } else {
                        print        "��Ч�Ĳ��� 'skills' (Skills Functions)\n"
                                ,"ʹ�÷���: skills [<add | desc>] [<skill #>]\n";
                }


        } elsif ($switch eq "sp") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
                ($arg3) = $input =~ /^[\s\S]*? \d+ \d+ (\d+)/;
                if ($arg1 eq "" || $arg2 eq "") {
                        print        "��Ч�Ĳ��� 'sp' (Use Skill on Player)\n"
                                ,"ʹ�÷���: sp <skill #> <player #> [<skill lvl>]\n";
                } elsif ($playersID[$arg2] eq "") {
                        print        "������� 'sp' (Use Skill on Player)\n"
                                ,"��� $arg2 ������.\n";
                } elsif ($skillsID[$arg1] eq "") {
                        print        "������� 'sp' (Use Skill on Player)\n"
                                ,"���� $arg1 ������.\n";
                } else {
                        if (!$arg3 || $arg3 > $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'}) {
                                $arg3 = $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'};
                        }
                        if (!ai_getSkillUseType($skillsID[$arg1])) {
                                ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $playersID[$arg2]);
                        } else {
                                ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $players{$playersID[$arg2]}{'pos_to'}{'x'}, $players{$playersID[$arg2]}{'pos_to'}{'y'});
                        }
                }

        } elsif ($switch eq "ss") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
                if ($arg1 eq "") {
                        print        "��Ч�Ĳ��� 'ss' (Use Skill on Self)\n"
                                ,"ʹ�÷���: ss <skill #> [<skill lvl>]\n";
                } elsif ($skillsID[$arg1] eq "") {
                        print        "������� 'ss' (Use Skill on Self)\n"
                                ,"���� $arg1 ������.\n";
                } else {
                        if (!$arg2 || $arg2 > $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'}) {
                                $arg2 = $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'};
                        }
                        if (!ai_getSkillUseType($skillsID[$arg1])) {
                                ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg2, 0,0, $accountID);
                        } else {
                                ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg2, 0,0, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
                        }
                }

        } elsif ($switch eq "st") {
		printc("nyn", "----------------", "�������Դ���", "----------------\n");
		printc("wnwnwn", "Str ", sprintf("%-3d+%-2d#%2d  ",$chars[$config{'char'}]{'str'},$chars[$config{'char'}]{'str_bonus'},$chars[$config{'char'}]{'points_str'}), "Atk", sprintf("%11s  ", $chars[$config{'char'}]{'attack'}." + ".$chars[$config{'char'}]{'attack_bonus'}), "Def", sprintf("%10s\n", $chars[$config{'char'}]{'def'}." + ".$chars[$config{'char'}]{'def_bonus'}));
		printc("wnwnwn", "Agi ", sprintf("%-3d+%-2d#%2d  ",$chars[$config{'char'}]{'agi'},$chars[$config{'char'}]{'agi_bonus'},$chars[$config{'char'}]{'points_agi'}), "Matk", sprintf("%10s  ", $chars[$config{'char'}]{'attack_magic_min'}." ~ ".$chars[$config{'char'}]{'attack_magic_max'}), "Mdef", sprintf("%9s\n", $chars[$config{'char'}]{'def_magic'}." + ".$chars[$config{'char'}]{'def_magic_bonus'}));
		printc("wnwnwn", "Vit ", sprintf("%-3d+%-2d#%2d  ",$chars[$config{'char'}]{'vit'},$chars[$config{'char'}]{'vit_bonus'},$chars[$config{'char'}]{'points_vit'}), "Hit", sprintf("%11d  ", $chars[$config{'char'}]{'hit'}), "Flee", sprintf("%9s\n", $chars[$config{'char'}]{'flee'}." + ".$chars[$config{'char'}]{'flee_bonus'}));
		printc("wnwnwn", "Int ", sprintf("%-3d+%-2d#%2d  ",$chars[$config{'char'}]{'int'},$chars[$config{'char'}]{'int_bonus'},$chars[$config{'char'}]{'points_int'}), "Critical", sprintf("%6d  ", $chars[$config{'char'}]{'critical'}), "Aspd", sprintf("%9s\n", $chars[$config{'char'}]{'attack_speed'}));
		printc("wnwn", "Dex ", sprintf("%-3d+%-2d#%2d  ",$chars[$config{'char'}]{'dex'},$chars[$config{'char'}]{'dex_bonus'},$chars[$config{'char'}]{'points_dex'}), "Status Point", sprintf("%17d\n",$chars[$config{'char'}]{'points_free'}));
		printc("wnwn", "Luk ", sprintf("%-3d+%-2d#%2d  ",$chars[$config{'char'}]{'luk'},$chars[$config{'char'}]{'luk_bonus'},$chars[$config{'char'}]{'points_luk'}), "Guild", sprintf("%24s\n","$chars[$config{'char'}]{'guild'}{'name'}"));
		print "--------------------------------------------\n";

        } elsif ($switch eq "stand") {
                if ($ai_v{'attackAuto_old'} ne "") {
                        configModify("attackAuto", $ai_v{'attackAuto_old'});
                        configModify("route_randomWalk", $ai_v{'route_randomWalk_old'});
                        undef $ai_v{'attackAuto_old'};
                        undef $ai_v{'route_randomWalk_old'};
                }
                stand();
                $ai_v{'sitAuto_forceStop'} = 1;

        } elsif ($switch eq "stat_add") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)$/;
                if ($arg1 ne "str" &&  $arg1 ne "agi" && $arg1 ne "vit" && $arg1 ne "int"
                        && $arg1 ne "dex" && $arg1 ne "luk") {
                        print        "��Ч�Ĳ��� 'stat_add' (Add Status Point)\n"
                        ,"ʹ�÷���: stat_add <str | agi | vit | int | dex | luk>\n";
                } else {
                        if ($arg1 eq "str") {
                                $ID = 0x0D;
                        } elsif ($arg1 eq "agi") {
                                $ID = 0x0E;
                        } elsif ($arg1 eq "vit") {
                                $ID = 0x0F;
                        } elsif ($arg1 eq "int") {
                                $ID = 0x10;
                        } elsif ($arg1 eq "dex") {
                                $ID = 0x11;
                        } elsif ($arg1 eq "luk") {
                                $ID = 0x12;
                        }
                        if ($chars[$config{'char'}]{"points_$arg1"} > $chars[$config{'char'}]{'points_free'}) {
                                print        "������� 'stat_add' (Add Status Point)\n"
                                        ,"û���㹻�����Ե���\n";
                        } else {
                                $chars[$config{'char'}]{$arg1} += 1;
                                sendAddStatusPoint(\$remote_socket, $ID);
                        }
                }

        } elsif ($switch eq "storage") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                ($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
                ($arg3) = $input =~ /^[\s\S]*? \w+ \d+ (\d+)/;
                if ($arg1 eq "" || $arg1 eq "eq" || $arg1 eq "u" || $arg1 eq "nu") {
                        printc("nyn", "-----------", "�ֿ���Ʒ", "-----------\n");
                        printItemList(\@{$storage{'inventory'}}, $arg1);
                        print "------------------------------\n";
                        print "����: $storage{'items'}/$storage{'items_max'}\n";
                        print "------------------------------\n";
                } elsif ($arg1 eq "log") {
			logItem("$logs_path/item_storage.txt", \%storage, "�ֿ���Ʒ");
                } elsif ($arg1 eq "addindex" && $arg2 =~ /\d+/ && findIndexString(\@{$chars[$config{'char'}]{'inventory'}}, "index", $arg2) ne "") {
                        print        "������� 'storage addindex' (Add Item to Storage by index)\n"
                                ,"������Ʒ $arg2 ����.\n";
                } elsif ($arg1 eq "addindex" && $arg2 =~ /\d+/) {
                        sendStorageAdd(\$remote_socket, $arg2, $arg3);
                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'inventory'}[$arg2] eq "") {
                        print        "������� 'storage add' (Add Item to Storage)\n"
                                ,"������Ʒ $arg2 ������.\n";
                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/) {
                        if (!$arg3 || $arg3 > $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'}) {
                                $arg3 = $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'};
                        }
                        sendStorageAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg2]{'index'}, $arg3);

                } elsif ($arg1 eq "get" && $arg2 =~ /\d+/ && !%{$storage{'inventory'}[$arg2]}) {
                        print        "������� 'storage get' (Get Item from Storage)\n"
                                ,"�ֿ���Ʒ $arg2 ������.\n";
                } elsif ($arg1 eq "get" && $arg2 =~ /\d+/) {
                        if (!$arg3 || $arg3 > $storage{'inventory'}[$arg2]{'amount'}) {
                                $arg3 = $storage{'inventory'}[$arg2]{'amount'};
                        }
                        sendStorageGet(\$remote_socket, $arg2, $arg3);

                } elsif ($arg1 eq "close") {
                        sendStorageClose(\$remote_socket);

                } elsif ($arg1 eq "clear") {
			$ai_v{'ai_storageAuto_clear'} = 1;
                        printc(1, "yw", "<ϵͳ> ", "��ʼ����ֿ�\n");
			unshift @ai_seq, "sellAuto";
			unshift @ai_seq_args, {};

                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/ && !%{$storage{'inventory'}[$arg2]}) {
                        print        "������� 'storage desc' (Storage Item Desciption)\n"
                                ,"�ֿ���Ʒ $arg2 ������.\n";
                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/) {
                        printItemDesc($storage{'inventory'}[$arg2]{'nameID'});
                } else {
                        print        "��Ч�Ĳ��� 'storage' (Storage List)\n"
                                ,"ʹ�÷���: storage [<eq | u | nu | log | clear | desc>] [<storage #>]\n"
                                ,"          storage [<add | get | close>] [<inventory # | storage #>] [<amount>]\n";
                }

        } elsif ($switch eq "store") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                ($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
                if ($arg1 eq "" && !$talk{'buyOrSell'}) {
                        printc("nyn", "---------", "�̵���Ʒ�б�", "---------\n");
	                printc("w", "#   ����                 ����           �۸�\n");
                        for ($i=0; $i < @storeList;$i++) {
	                        print sprintf("%-3d %-20s %-10s %8sz\n",$i ,$storeList[$i]{'name'} ,$itemTypes_lut{$storeList[$i]{'type'}} ,$storeList[$i]{'price'});
                        }
                        print "------------------------------\n";
                } elsif ($arg1 eq "" && $talk{'buyOrSell'}) {
                        sendGetStoreList(\$remote_socket, $talk{'ID'});

                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/ && $storeList[$arg2] eq "") {
                        print        "������� 'store desc' (Store Item Description)\n"
                                ,"�̵���Ʒ $arg2 ������.\n";
                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/) {
                        printItemDesc($storeList[$arg2]);

                } else {
                        print        "��Ч�Ĳ��� 'store' (Store List)\n"
                                ,"ʹ�÷���: store [<desc>] [<store item #>]\n";
                }

        } elsif ($switch eq "take") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)$/;
                if ($arg1 eq "") {
                        print        "��Ч�Ĳ��� 'take' (Take Item)\n"
                                ,"ʹ�÷���: take <item #>\n";
                } elsif ($itemsID[$arg1] eq "") {
                        print        "������� 'take' (Take Item)\n"
                                ,"������Ʒ $arg1 ������.\n";
                } else {
                        take($itemsID[$arg1]);
                }

        } elsif ($switch eq "warp") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)$/;
                if ($arg1 eq "") {
                        print        "��Ч�Ĳ��� 'warp' (Warp to Map)\n"
                                ,"ʹ�÷���: warp <map name>\n";
                } elsif ($maps_lut{$arg1.'.rsw'} eq "") {
                        print        "������� 'warp' (Warp to Map)\n"
                                ,"��ͼ $arg1 ������.\n";              	
                } else {
        		ai_warp($arg1);
        	}

        } elsif ($switch eq "resp") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                if (!@{$warp{'responses'}}) {
                        print        "������� 'resp' (Respond)\n"
                                ,"û��Ӧ���б�.\n";
                } elsif ($arg1 eq "") {
                        printc("nyn", "-----------", "Ӧ���б�", "-----------\n");
                        printc("w", "#   ����\n");
                        for ($i=0; $i < @{$warp{'responses'}};$i++) {
                        	print sprintf("%-3d %-30s\n", $i, $warp{'responses'}[$i]);
                        }
                        print "------------------------------\n";
                        printc("ww", "<�Ի�>", "���� 'resp' ѡ��Ӧ��\n");

                } elsif ($warp{'responses'}[$arg1] eq "") {
                        print        "������� 'resp' (Respond)\n"
                                ,"Ӧ�� $arg1 ������.\n";

                } else {
                        sendWarpto(\$remote_socket, $warp{'responses'}[$arg1]);
                }

#####
        } elsif ($switch eq "talk") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                ($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)/;

                if ($arg1 =~ /^\d+$/ && $npcsID[$arg1] eq "") {
                        print        "������� 'talk' (Talk to NPC)\n"
                                ,"���� $arg1 ������.\n";
                } elsif ($arg1 =~ /^\d+$/) {
                        sendTalk(\$remote_socket, $npcsID[$arg1]);

                } elsif ($arg1 eq "resp" && !%talk) {
                        print        "������� 'talk resp' (Respond to NPC)\n"
                                ,"��û�����κ����ｻ̸.\n";
                } elsif ($arg1 eq "resp" && $arg2 eq "") {
                        $display = $npcs{$talk{'ID'}}{'name'};
                        printc("nyn", "-----------", "�ش��б�", "-----------\n");
                        print "����: $npcs{$talk{'ID'}}{'name'}\n";
                        printc("w", "#   ����\n");
                        for ($i=0; $i < @{$talk{'responses'}};$i++) {
	                      	print sprintf("%-3d %-30s\n", $i, $talk{'responses'}[$i]);                        
                        }
                        print "------------------------------\n";
                } elsif ($arg1 eq "resp" && $arg2 ne "" && $talk{'responses'}[$arg2] eq "") {
                        print        "������� 'talk resp' (Respond to NPC)\n"
                                ,"�ش� $arg2 ������.\n";
                } elsif ($arg1 eq "resp" && $arg2 ne "") {
                        $arg2 += 1;
                        sendTalkResponse(\$remote_socket, $talk{'ID'}, $arg2);

                } elsif ($arg1 eq "cont" && !%talk) {
                        print        "������� 'talk cont' (Continue Talking to NPC)\n"
                                ,"��û�����κ����ｻ̸.\n";
                } elsif ($arg1 eq "cont") {
                        sendTalkContinue(\$remote_socket, $talk{'ID'});
                } elsif ($arg1 eq "answer" && %talk) {
                        sendTalkAnswer(\$remote_socket, $talk{'ID'}, $arg2);
                } elsif ($arg1 eq "no" && %talk) {
                        sendTalkCancel(\$remote_socket, $talk{'ID'});
                } else {
                        print        "��Ч�Ĳ��� 'talk' (Talk to NPC)\n"
                                ,"ʹ�÷���: talk <NPC # | cont | resp | answer | no> [<response # | amount>]\n";
                }

        } elsif ($switch eq "tank") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                if ($arg1 eq "") {
                        print        "��Ч�Ĳ��� 'tank' (Tank for a Player)\n"
                                ,"ʹ�÷���: tank <player #>\n";
                } elsif ($arg1 eq "stop") {
                        configModify("tankMode", 0);
                } elsif ($playersID[$arg1] eq "") {
                        print        "������� 'tank' (Tank for a Player)\n"
                                ,"��� $arg1 ������.\n";
                } else {
                        configModify("tankMode", 1);
                        configModify("tankModeTarget", $players{$playersID[$arg1]}{'name'});
                }

        } elsif ($switch eq "tele") {
                useTeleport(1);

        } elsif ($switch eq "timeout") {
                ($arg1, $arg2) = $input =~ /^[\s\S]*? ([\s\S]*) ([\s\S]*?)$/;
                if ($arg1 eq "") {
                        print        "��Ч�Ĳ��� 'timeout' (set a timeout)\n"
                                ,"ʹ�÷���: timeout <type> [<seconds>]\n";
                } elsif ($timeout{$arg1} eq "") {
                        print        "������� 'timeout' (set a timeout)\n"
                                ,"Timeout $arg1 ������\n";
                } elsif ($arg2 eq "") {
                        print "Timeout '$arg1' ��ֵΪ $timeout{$arg1}{'timeout'}\n";
                } else {
                        setTimeout($arg1, $arg2);
                }

        } elsif ($switch eq "uneq") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                if ($arg1 eq "") {
                        print        "��Ч�Ĳ��� 'unequip' (Unequip Inventory Item)\n"
                                ,"ʹ�÷���: unequip <item #>\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "������� 'unequip' (Unequip Inventory Item)\n"
                                ,"������Ʒ $arg1 ������.\n";
                } elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'equipped'} == 0) {
                        print        "������� 'unequip' (Unequip Inventory Item)\n"
                                ,"������Ʒ $arg1 û��װ��.\n";
                } else {
                        sendUnequip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'});
                        undef $chars[$config{'char'}]{'autoSwitch'};
                }

        } elsif ($switch eq "where") {
                ($map_string) = $map_name =~ /([\s\S]*)\.gat/;
                print "λ��: $maps_lut{$map_string.'.rsw'}($map_string) ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n";

        } elsif ($switch eq "who") {
                sendWho(\$remote_socket);

        } elsif ($switch eq "shop") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? \w+ \d+ (\d+)/;
		($arg4) = $input =~ /^[\s\S]*? \w+ \d+ \d+ (\d+)/;
		if ($arg1 eq "") {
			if (!$chars[$config{'char'}]{'shopOpened'}) {
                                print        "������� 'shop' (Show My Shop)\n"
                                	,"���¶���̵껹û����.\n";
			} else {
	                        printc("nyn", "--------", "�ҵ�¶���̵�", "--------\n");
				print "����: $shop{'title'}\n";
	        	        printc("w", "#   ����                           ����           �۸�   ����  ����\n");
                        	for ($i=0; $i < @{$shop{'inventory'}};$i++) {
                        		next if ($shop{'inventory'}[$i] eq "");
	                        	print sprintf("%-3d %-30s %-10s %8dz %5d %5d\n", $i, $shop{'inventory'}[$i]{'name'}, $itemTypes_lut{$shop{'inventory'}[$i]{'type'}}, $shop{'inventory'}[$i]{'price'}, $shop{'inventory'}[$i]{'amount'}, $shop{'inventory'}[$i]{'sold'});
	                        }
        	                print "------------------------------\n";
                                $chars[$config{'char'}]{'shopEarned'} = 0 if ($chars[$config{'char'}]{'shopEarned'} eq "");
                	        print "¶���̵�����: $chars[$config{'char'}]{'shopEarned'}"."z\n";
                        	print "------------------------------\n";
                        }
		} elsif ($arg1 eq "list") {
                        printc("nyn", "--------", "¶���̵��б�", "--------\n");			
	                printc("w", "#   ����                                 ������\n");
                        for ($i = 0; $i < @venderListsID; $i++) {
                                next if ($venderListsID[$i] eq "");
                                $owner_string = ($venderListsID[$i] ne $accountID) ? $players{$venderListsID[$i]}{'name'} : $chars[$config{'char'}]{'name'};
				print sprintf("%-3d %-36s %-22s %-5s %-8s\n", $i, $venderLists{$venderListsID[$i]}{'title'}, $owner_string);
                        }
			print "------------------------------\n";
                } elsif ($arg1 eq "open") {
			if ($chars[$config{'char'}]{'shopOpened'}) {
                                print        "������� 'shop open' (Open My Shop)\n"
                                	,"���¶���̵��Ѿ�������.\n";
                        } else {
	                        sendOpenShop(\$remote_socket);
        	                $shop_control{'shopAuto_open'} = 1;
        	        }
                } elsif ($arg1 eq "close") {
			if (!$chars[$config{'char'}]{'shopOpened'}) {
                                print        "������� 'shop close' (Close My Shop)\n"
                                	,"���¶���̵껹û����.\n";
                        } else {
	                        sendCloseShop(\$remote_socket);
        	                $shop_control{'shopAuto_open'} = 0;
                        }
                } elsif ($arg1 eq "enter") {
                        if ($arg2 eq "") {
                        	print        "��Ч�Ĳ��� 'shop enter' (Enter to Shop)\n"
                                	,"ʹ�÷���: shop enter <shop #>\n";
                        } elsif ($venderListsID[$arg2] eq "") {
                                print        "������� 'shop enter' (Enter to Shop)\n"
                                	,"¶���̵� $arg2 ������.\n";
                        } else {
	                        sendEnteringVender(\$remote_socket, $venderListsID[$arg2]);
	                }
                } elsif ($arg1 eq "item") {
                	if (!%{$venderLists{$venderID}}) {
                                print        "������� 'shop item' (List Item from Shop)\n"
                                	,"��û�н����κ�¶���̵�.\n";
			} else {
	                        printc("nyn", "------", "¶���̵���Ʒ�б�", "------\n");
				print "����: $venderLists{$venderID}{'title'}\n";
		                printc("w", "#   ����                           ����           �۸�   ����\n");
	                        for ($i=0; $i < @venderItemList;$i++) {
	                        	next if ($venderItemList[$i] eq "");
		                        print sprintf("%-3d %-30s %-10s %8dz %5d\n", $i, $venderItemList[$i]{'name'}, $itemTypes_lut{$venderItemList[$i]{'type'}}, $venderItemList[$i]{'price'}, $venderItemList[$i]{'amount'});
                	        }
                        	print "------------------------------\n";
                        }
                } elsif ($arg1 eq "quit") {
	                printc("wr", "<��Ϣ> ", "���뿪��¶���̵�\n");
                        undef @venderItemList;
                        undef $venderID;
                } elsif ($arg1 eq "buy") {
                        if ($venderID eq "") {
                                print        "������� 'shop buy' (Buy Item from Shop)\n"
                                	,"��û�н����κ�¶���̵�.\n";
                        } elsif (%{$venderItemList[$arg2]} && $arg3 > 0 && $arg3 =~ /\d+/) {
                                sendBuyVender(\$remote_socket, $arg2, $arg3);
                        } else {
                        	print        "��Ч�Ĳ��� 'shop buy' (Buy Item from Shop)\n"
                                	,"ʹ�÷���: shop buy <item #> <amount>\n";
                        }
                } else {
                        print        "��Ч�Ĳ��� 'shop' (Shop Command)\n"
                               	,"ʹ�÷���: shop [<open | close | list | item | quit>]\n"
                               	,"          shop [<enter | buy>] [<shop #> | <item #> <amount>]\n";
                }

        } elsif ($switch eq "map") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
       	        ($map_string) = $map_name =~ /([\s\S]*)\.gat/;
		if ($arg1 eq "") {
	        	my @array;
                	printc("nyn", "--------", "��ͼ���͵���Ϣ", "--------\n");
			print "λ��: $maps_lut{$map_string.'.rsw'}($map_string) ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n";
        	        printc("w", "#   λ��      ��ͼ         ����\n");
                	foreach (sort (keys %portals_lut)) {
                        	if ($portals_lut{$_}{'source'}{'map'} eq $map_string){
                        		push @array, $_;
	                        }
        	        }
                	for (my $i = 0; $i < @array; $i++) {
				print sprintf("%-3d %-9s %-12s %-40s\n", $i, "($portals_lut{$array[$i]}{'source'}{'pos'}{'x'},$portals_lut{$array[$i]}{'source'}{'pos'}{'y'})", $portals_lut{$array[$i]}{'dest'}{'map'}, $maps_lut{$portals_lut{$array[$i]}{'dest'}{'map'}.'.rsw'});
			}
        	        print "------------------------------\n";
        	} elsif ($arg1 eq "lock") {
        		if ($config{'lockMap'} eq "") {
				$config{'lockMap'} = $map_string;
        	                configModify("lockMap", $map_string);
        	        } else {
				$config{'lockMap'} = "";
        	                configModify("lockMap", "");
                        }
                } elsif ($arg1 eq "save") {
			$config{'saveMap'} = $map_string;
       	                configModify("saveMap", $map_string);
	        } else {
                        print        "��Ч�Ĳ��� 'map' (Map Info - Lock/Save)\n"
                               	,"ʹ�÷���: map [<save | lock>]\n";
	        }	

        } elsif ($switch eq "ver") {
                printc("yw", "<ϵͳ> ", $versionText);

        } elsif ($switch eq "base") {
                unshift @ai_seq, "sellAuto";
                unshift @ai_seq_args, {};

        } elsif ($switch eq "heal") {
                unshift @ai_seq, "healAuto";
                unshift @ai_seq_args, {};

#####
        } elsif ($switch eq "time" && $vipLevel >= 2) {
              	printc("nyn", "----------", "BOSSʱ���", "----------\n");
              	printc("w", "BOSS                  ����ʱ��\n");
                my %stuff;
                foreach (keys %mvptime) {
                        next if ($_ eq "");
                        $stuff{$mvptime{$_}} = $_;
                }
                foreach (sort (keys %stuff)) {
                        print sprintf("%-20s  %8s\n", $stuff{$_}, getFormattedTime(int($_)));
                }
              	print "------------------------------\n";
                printc("wy", "Ŀ�� ", "$mvp{'now_monster'}{'name'}\n");
                printc("wnwn", "��ʱ ", getFormattedTime(int(time)),  "    ʣ�� ", getFormattedTime(int($mvp{'now_monster'}{'end_time'} - time))."\n");
              	print "------------------------------\n";
#####
        } elsif ($switch eq "exp") {
                ($arg1) = $input =~ /^.*? (\w+)/;
                if($arg1 eq "" || $arg1 eq "e" || $arg1 eq "m" || $arg1 eq "i" || $arg1 eq "a"){
                        if ($arg1 eq "" || $arg1 eq "e" || $arg1 eq "a") {
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
                                $playTime_string = $w_hour."Сʱ ".$w_min."�� ".$w_sec."��";
                                $levelTime_string = $n_hour."Сʱ ".$n_min."�� ".$n_sec."��";
                                $exp{'base'}{'back'} = 0 if ($exp{'base'}{'back'} eq "");
                                $exp{'base'}{'dead'} = 0 if ($exp{'base'}{'dead'} eq "");
                                $exp{'base'}{'disconnect'} = 0 if ($exp{'base'}{'disconnect'} eq "");
                                $totalBaseExp_string = $totalBaseExp." (".(int($totalBaseExp/$chars[$config{'char'}]{'exp_max'}*10000)/100)."%)";
                                $totalJobExp_string = $totalJobExp." (".(int($totalJobExp/$chars[$config{'char'}]{'exp_job_max'}*10000)/100)."%)";
                                $bExpPerHour_string = $bExpPerHour." (".(int($bExpPerHour/$chars[$config{'char'}]{'exp_max'}*10000)/100)."%)";
                                $jExpPerHour_string = $jExpPerHour." (".(int($jExpPerHour/$chars[$config{'char'}]{'exp_job_max'}*10000)/100)."%)";
                                print "-------------------------------------------------------------------------\n";
                                printc("y", "����ʱ��           ������Ҫ              ս��ʱ�� ��Ϣʱ�� �س� ���� ����\n");

                                $~ = "EXPBLIST";
                                format EXPBLIST =
@<<<<<<<<<<<<<<<<  @<<<<<<<<<<<<<<<<<    @>>>>>>> @>>>>>>> @>>> @>>> @>>>
$playTime_string $levelTime_string $attack_string $sit_string $exp{'base'}{'back'} $exp{'base'}{'dead'} $exp{'base'}{'disconnect'}
.
                                write;
                                print "-------------------------------------------------------------------------\n";
                               printc("c", "�����BASE����     �����JOB����         ÿСʱBASE����     ÿСʱJOB����   \n");
                                $~ = "EXPELIST";
                                format EXPELIST =
@<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<< @>>>>>>>>>>>>>>>>  @>>>>>>>>>>>>>>>
$totalBaseExp_string $totalJobExp_string $bExpPerHour_string $jExpPerHour_string
.
                                write;
                                print "-------------------------------------------------------------------------\n";
                        }
                        if ($arg1 eq "" || $arg1 eq "m" || $arg1 eq "a") {
                                $~ = "EXPMLIST";
                                print "-------------------------------------------------------------------------\n" if ($arg1 eq "m");
                                printc("w", "�������           ����  ƽ��ʱ��  BASEЧ��   JOBЧ��  ÿ���˺�  ÿ����ʧ\n");
                                foreach (keys %{$exp{'monster'}}) {
                                        next if ($exp{'monster'}{$_}{'kill'} <= 0 || $monsters_lut{$_} eq "");
                                        $exp{'monster'}{$_}{'avg_time'} =  int($exp{'monster'}{$_}{'time'} / $exp{'monster'}{$_}{'kill'} * 100) / 100;
                                        $exp{'monster'}{$_}{'avg_baseExp'} = int($exp{'monster'}{$_}{'baseExp'} / $exp{'monster'}{$_}{'time'} * 100) / 100;
                                        $exp{'monster'}{$_}{'avg_jobExp'} = int($exp{'monster'}{$_}{'jobExp'} / $exp{'monster'}{$_}{'time'} * 100) / 100;
                                        $exp{'monster'}{$_}{'avg_dmgTo'} = int($exp{'monster'}{$_}{'dmgTo'} / $exp{'monster'}{$_}{'time'} * 100) / 100;
                                        $exp{'monster'}{$_}{'avg_dmgFrom'} = int($exp{'monster'}{$_}{'dmgFrom'} / $exp{'monster'}{$_}{'time'} * 100) / 100;
                                        format EXPMLIST =
@<<<<<<<<<<<<<<<< @>>>>  @>>>>>>>  @>>>>>>>  @>>>>>>>  @>>>>>>>  @>>>>>>>
$monsters_lut{$_} $exp{'monster'}{$_}{'kill'} $exp{'monster'}{$_}{'avg_time'} $exp{'monster'}{$_}{'avg_baseExp'} $exp{'monster'}{$_}{'avg_jobExp'} $exp{'monster'}{$_}{'avg_dmgTo'} $exp{'monster'}{$_}{'avg_dmgFrom'}
.
                                        write;
                                }
                                print "-------------------------------------------------------------------------\n";
                        }
                        if ($arg1 eq "i" || $arg1 eq "a") {
                                $~ = "EXPILIST";
                                print "-------------------------------------------------------------------------\n" if ($arg1 eq "i");
                        printc("w", "ʹ����Ʒ           ����                   �����Ʒ           ����    ��Ҫ\n");
                                undef @exp_pick;
                                undef @exp_used;
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
                                        format EXPILIST =
@<<<<<<<<<<<<<<<<< @>>>                   @<<<<<<<<<<<<<<<<< @>>>    @>>>
$used_string       $used_amount           $pick_string       $pick_amount $flag_string
.
                                        write;
                                        $i++;
                                }
                                print "-------------------------------------------------------------------------\n";
                        }
                } elsif($arg1 eq "reset") {
                        $chars[$config{'char'}]{'exp_start'} = $chars[$config{'char'}]{'exp'};
                        $chars[$config{'char'}]{'exp_job_start'} = $chars[$config{'char'}]{'exp_job'};
                        $chars[$config{'char'}]{'exp_start_time'} = time;
                        undef $exp{'monster'}{'startTime'};
                        undef $exp{'base'}{'sitStartTime'};
                        $exp{'base'}{'attackTime'} = 0;
                        $exp{'base'}{'sitTime'} = 0;
                        $chars[$config{'char'}]{'totalDamage'} = 0;
                        $chars[$config{'char'}]{'totalHit'} = 0;
                        undef %exp;
                } else {
                        print "��Ч�Ĳ��� 'exp' (Exp Calculation)\n";
                        print "ʹ�÷���: exp [e|m|i|a|reset]\n";
                }
        # ICE End

        } elsif ($switch eq "exall") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($arg1 eq "1" || $arg1 eq "0"){
                        sendIgnoreAll(\$remote_socket, !$arg1);
                } else {
                        print        "��Ч�Ĳ��� 'exall' (Ignore/Unignore Everyone)\n"
                        	,"ʹ�÷���: exall <flag>\n";
                }

#####
        } elsif ($switch eq "ar") {
                @arg = split / /, $input;
                if ($arg[1] eq "stop") {
                        aiRemove("refineAuto");
                        printc("yr", "<ϵͳ> ", "ֹͣ�Զ�����\n");
                } elsif ($arg[1] eq "" || $arg[2] < 1 || $arg[2] > 10) {
                        print        "��Ч�Ĳ��� 'ar' (Auto Refine)\n"
	                        ,"ʹ�÷���: ar <all|#> <1-10>\n";
                } elsif ($arg[1] eq "all") {
                        $arg[2] = int($arg[2]);
                        ai_refine($arg[1], $arg[2]);
                        printc("yw", "<ϵͳ> ", "��ʼ�Զ�����  ��Ʒ: ȫ��  ����: $arg[2]\n");
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg[1]]}) {
                        print        "������� 'ar' (Auto Refine)\n"
                                ,"������Ʒ $arg[1] ������.\n";
                } elsif ($chars[$config{'char'}]{'inventory'}[$arg[1]]{'type_equip'} == 0) {
                        print        "������� 'ar' (Auto Refine)\n"
                                ,"������Ʒ $arg[1] ���ܾ���.\n";
                } else {
                        $arg[2] = int($arg[2]);
                        ai_refine($items_lut{$chars[$config{'char'}]{'inventory'}[$arg[1]]{'nameID'}}, $arg[2]);
                        printc("yw", "<ϵͳ> ", "��ʼ�Զ�����  ��Ʒ: $items_lut{$chars[$config{'char'}]{'inventory'}[$arg[1]]{'nameID'}}  ����: $arg[2]\n");
                }

#####
        } elsif ($switch eq "ye") {
                if (!$yelloweasy) {
                        $yelloweasy = 1;
                        printc("yy", "<ϵͳ> ", "��Yellow EasyͨѶ\n");
                        $window_socket = IO::Socket::INET->new(
                                PeerAddr        => 'localhost',
                                PeerPort            => 7600,
                                LocalAddr               => 'localhost',
                                LocalPort                   => 7000,
                                Proto                           => 'udp');
                        sendMsgToWindow("AAFF".chr(1)."7000");
                        for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
                                next if (!%{$chars[$config{'char'}]{'inventory'}[$i]});
                                sendMsgToWindow("AA20".chr(1).$i.chr(1).$chars[$config{'char'}]{'inventory'}[$i]{'type'}.chr(1).$chars[$config{'char'}]{'inventory'}[$i]{'name'}.chr(1).$chars[$config{'char'}]{'inventory'}[$i]{'amount'});                               
                        }
                } else {
                        undef $yelloweasy;
                        printc("yy", "<ϵͳ> ", "�ر�Yellow EasyͨѶ\n");
                        close($window_socket) if ($window_socket);
                }

        } elsif ($switch eq "tp") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($arg1 eq "1"){
                        useTeleport(1);
                        printc("ww", "<˲��> ", "���˲���ƶ�\n");
                } elsif ($arg1 eq "2"){
                        useTeleport(2);
                        printc("ww", "<˲��> ", "���ؼ�¼�ص�\n");
                } else {
                        print        "��Ч�Ĳ��� 'tp' (Teleport)\n"
	                        ,"ʹ�÷���: tp <1 | 2>\n";
                }

        } elsif ($switch eq "ai") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($arg1 eq "") {
                        my $stuff = @ai_seq_args;
                        my $type = ($AI) ? "On" : "Off";
                        print "AI: @ai_seq | $stuff | $type\n";
                } elsif ($arg1 eq "c" || $arg1 eq "clear") {
                        undef @ai_seq;
                        undef @ai_seq_args;
                        print "���AI����\n";
                } elsif ($arg1 eq "d" || $arg1 eq "delete") {
                        shift @ai_seq;
                        shift @ai_seq_args;
                        print "ɾ����ǰִ�е�AI\n";
                } elsif ($arg1 eq "p" || $arg1 eq "pause") {
                        undef $AI;
                        $AI_forcedOff = 1;
                        ai_setSuspend(0);
                        print "��ִͣ��AI\n";
                } elsif ($arg1 eq "r" || $arg1 eq "resume") {
                        $AI = 1;
                        undef $AI_forcedOff;
                        print "����ִ��AI\n";
                } else {
                        print        "��Ч�Ĳ��� 'ai' (AI View and Control)\n"
                        	,"ʹ�÷���: ai [<c | clear | d | delete | p | pause | r | resume>]\n";
                }

        } elsif ($switch eq "mode") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		if ($arg1 eq "") {
			print "��ǰ��ʾ���� $config{'mode'}\n";
                } elsif ($arg1 eq "0" || $arg1 eq "1" || $arg1 eq "2" || $arg1 eq "3"){
                        $config{'mode'} = $arg1;
                        configModify("mode", $arg1);
			print "��ʾ�������Ϊ $config{'mode'}\n";
                } else {
                        print        "��Ч�Ĳ��� 'mode' (Display Mode)\n"
	                        ,"ʹ�÷���: mode [<level # (0-3)>]\n";
                }

        } elsif ($switch eq "help") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
	        dynParseFiles("data/commandsdescriptions.txt", \%commandsDesc_lut, \&parseRODescLUT3);
                if ($arg1 ne "" && %{$commandsDesc_lut{$arg1}}) {
                        printc("nyn", "-----------", "����˵��", "-----------\n");
                        printc("w", "����: $arg1 - $commandsDesc_lut{$arg1}{'name'}\n");
                        print $commandsDesc_lut{$arg1}{'desc'};
                        print "------------------------------\n";
                } elsif ($arg1 ne "") {
			undef @array;
                	foreach (sort (keys %commandsDesc_lut)) {
                                if ($_ =~ /\Q$arg1\E/i || $commandsDesc_lut{$_}{'name'} =~ /\Q$arg1\E/i) {
                                	push @array, $_;
                                }
                        }
                        if (@array) {
	                        printc("nyn", "-----------", "�����б�", "-----------\n");
       	                	for (my $i=0; $i < @array; $i++) {
	                        	print sprintf("%-16s - %-60s\n",$array[$i],$commandsDesc_lut{$array[$i]}{'name'});
		                }
	                        print "------------------------------\n";
	                        print "�й�ĳ���������ϸ��Ϣ������� help ������\n";
		        } else {
	                        print        "������� 'help' (Help of Command)\n"
        	                        ,"û���κ��������ƻ�����ƥ�� $arg[1], ������ 'help' ��ȡ�����б�\n";
	                }
                } else {
                        printc("nyn", "-----------", "�����б�", "-----------\n");
                	foreach (sort (keys %commandsDesc_lut)) {
                		next if ($_ eq "");
	                        print sprintf("%-16s - %-60s\n",$_,$commandsDesc_lut{$_}{'name'});
	                }
                        print "------------------------------\n";
                        print "�й�ĳ���������ϸ��Ϣ������� 'help ������'\n";
                }
                undef %commandsDesc_lut;

        } elsif ($switch eq "vip"  && $vipLevel >= 3) {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
                if (($arg1 ne "1" && $arg1 ne "2") || $arg2 eq "") {
                	print        "��Ч�Ĳ��� 'vip' (VIP Password Calculation)\n"
                		,"ʹ�÷���: vip <level> <AID>\n";
                } else {
                	my $key = getVipPassword($arg1, $arg2);
                	print "Level: $arg1 | AID: $arg2 | Password: $key\n";
                }
                
        } elsif ($switch eq "aid") {
                printc("nyn", "-----------", "AID �б�", "-----------\n");
                printc("w", "#   λ��      ���� ����                                       AID\n");
                for ($i = 0; $i < @playersID; $i++) {
                        next if ($playersID[$i] eq "");
                        if (%{$players{$playersID[$i]}{'guild'}}) {
                                $name = "$players{$playersID[$i]}{'name'} [$players{$playersID[$i]}{'guild'}{'name'}]";
                        } else {
                                $name = $players{$playersID[$i]}{'name'};
                        }
			print sprintf("%-3d %-9s %4s %-42s %-7s\n",$i,"($players{$playersID[$i]}{'pos_to'}{'x'},$players{$playersID[$i]}{'pos_to'}{'y'})",int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$playersID[$i]}{'pos_to'}}) * 10) / 10,$name,$players{$playersID[$i]}{'nameID'});
                }
                print "------------------------------\n";
                printc("y", "���AID: $accountAID "."(".getHex($accountID).")\n");
                print "------------------------------\n";                
#####

	} elsif ($switch eq "friend") {
		($arg1) = $input =~ /^[\s\S]*? (\w*)/;
		($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)\b/;
		if ($arg1 eq "") {
		# friend list
			print "--- Friend List ---\n",
				"#  Name\n";
			for ($i = 0; $i < @{$friend{'member'}}; $i++) {
				printf("%2d %s", $i, $friend{'member'}[$i]{'name'});
			}
 		} elsif ($arg1 eq "join" && $arg2 ne "1" && $arg2 ne "0") {
			print "Syntax Error in function 'friend join' (Accept/Deny Friend Join Request)\n"
				,"Usage: friend join <flag>\n";
		} elsif ($arg1 eq "join" && $incomingFriend{'ID'} eq "") {
			print "Error in function 'friend join' (Join/Request to Join Friend)\n"
				,"Can't accept/deny friend request - no incoming request.\n";
		} elsif ($arg1 eq "join") {
			sendFriendJoin(\$remote_socket, $incomingFriend{'ID'}, $incomingFriend{'charID'}, $arg2);
			undef %incomingFriend;
		} elsif ($arg1 eq "request" && $playersID[$arg2] eq "") {
			print "Error in function 'friend request' (Request to Join Friend)\n"
				,"Can't request to join friend - player $arg2 does not exist.\n";
		} elsif ($arg1 eq "request") {
			sendFriendJoinRequest(\$remote_socket, $players{$playersID[$arg1]}{'name'});
		} elsif ($arg1 eq "kick" && $arg2 eq "") {
			print "Syntax Error in function 'friend kick' (Kick Friend Member)\n"
				,"Usage: friend kick <friend member #>\n";
		} elsif ($arg1 eq "kick" && $friend{'member'}[$arg2]{'ID'} eq "") {
			print "Error in function 'friend kick' (Kick Friend Member)\n"
				,"Can't kick member - member $arg2 doesn't exist.\n";
		} elsif ($arg1 eq "kick") {
			sendFriendKick(\$remote_socket, $friend{'member'}[$arg2]{'ID'}, $friend{'member'}[$arg2]{'charID'});
		}

        } elsif ($switch eq "guild") {
                my ($arg1) = $input =~ /^.*? (\w+)/;
                my ($arg2) = $input =~ /^.*? \w+ (\w+)/;
                if ($arg1 eq "i") {
                        sendGuildRequest(\$remote_socket, 0);
                        print "----------------------- Guild Information -----------------------\n";
                        print sprintf("  ��������  : %-25s    ����     : %10d\n", $chars[$config{'char'}]{'guild'}{'name'}, $chars[$config{'char'}]{'guild'}{'exp'});
                        print sprintf("  ����ȼ�  : %-25d    Next     : %10d\n", $chars[$config{'char'}]{'guild'}{'lv'}, $chars[$config{'char'}]{'guild'}{'next_exp'});
                        print sprintf("  �᳤����  : %-25s    ���ɵ��� : %10d\n", $chars[$config{'char'}]{'guild'}{'master'}, $chars[$config{'char'}]{'guild'}{'offerPoint'});
                        print sprintf("  ��������  : %3d/%-3d (Max: %d)\n", $chars[$config{'char'}]{'guild'}{'conMember'}, scalar(keys %{$chars[$config{'char'}]{'guild'}{'members'}}), $chars[$config{'char'}]{'guild'}{'maxMember'});
                        print sprintf("  ƽ���ȼ�  : %-3d\n", $chars[$config{'char'}]{'guild'}{'average'});
                        print sprintf("  ��������  : %-25s    ID       : %-20s\n", $chars[$config{'char'}]{'guild'}{'castle'}, getHex($chars[$config{'char'}]{'guild'}{'ID'}));
                        print "-----------------------------------------------------------------\n";
                } elsif ($arg1 eq "m") {
                        sendGuildRequest(\$remote_socket, 1);
                        undef $i;
                        print "-------------------------------- Guild  Member --------------------------------\n";
                        print "#    Name                     Position                 Job         Lv Exp\n";
                        foreach (keys %{$chars[$config{'char'}]{'guild'}{'members'}}) {
                                $online_string = ($chars[$config{'char'}]{'guild'}{'members'}{$_}{'online'}) ? "*" : "";
                                print sprintf("%-2d %1s %-24s %-24s %-11s %2d %-8d\n", $i++, $online_string, $chars[$config{'char'}]{'guild'}{'members'}{$_}{'name'}, $chars[$config{'char'}]{'guild'}{'positions'}[$chars[$config{'char'}]{'guild'}{'members'}{$_}{'position'}]{'name'}, $jobs_lut{$chars[$config{'char'}]{'guild'}{'members'}{$_}{'job'}}, $chars[$config{'char'}]{'guild'}{'members'}{$_}{'lv'}, $chars[$config{'char'}]{'guild'}{'members'}{$_}{'exp'});
                                #    printf "                                (ID: %11s)      (AccountID: %11s)\n", getHex($_), getHex($chars[$config{'char'}]{'guild'}{'members'}{$_}{'accountID'});
                        }
                        print "-------------------------------------------------------------------------------\n";
                } elsif ($arg1 eq "p") {
                        sendGuildRequest(\$remote_socket, 2);
                        undef $i;
                        print "------------ Guild  Positions ------------\n";
                        print "#  Position Name            Join Kick EXP%\n";
                        for (my $i = 0; $i < @{$chars[$config{'char'}]{'guild'}{'positions'}}; $i++) {
                                print sprintf("%-2d %-24s %4s %4s  %2d%s\n", $i, $chars[$config{'char'}]{'guild'}{'positions'}[$i]{'name'}, $chars[$config{'char'}]{'guild'}{'positions'}[$i]{'join'}, $chars[$config{'char'}]{'guild'}{'positions'}[$i]{'kick'}, $chars[$config{'char'}]{'guild'}{'positions'}[$i]{'feeEXP'}, "%");
                        }
                        print "------------------------------------------\n";
                } elsif ($arg1 eq "") {
                           print "Requesting : guild information\n",
                           "Usage: guild < info | member | position >\n";
                           sendGuildInfoRequest(\$remote_socket);
                           sendGuildRequest(\$remote_socket, 0);
                           sendGuildRequest(\$remote_socket, 1);
                }
                
        } elsif ($switch eq "fly") {
                @arg = split / /, $input;
                if ($arg[1] eq "") {
                        print "----------------------------- ת�Ƶ�ͼ�б� ------------------------------\n";
                        printc("w", "��� ��ͼ         ��ͼ����                           IP��ַ          �˿�\n");
                        undef @fly_list;
                        foreach (keys %mapserver_lut) {
                                next if ($_ eq "");
                                push @fly_list, $_;
                        }
                        for ($i = 0; $i < @fly_list; $i++) {
				print sprintf("%-3d %-12s %-36s %-17s %-5s\n", $i, $fly_list[$i], $mapip_lut{$fly_list[$i]}{'name'}, $mapip_lut{$fly_list[$i]}{'ip'}, $mapip_lut{$fly_list[$i]}{'port'});
                        }
                } elsif ($arg[1] eq "ip" && $arg[2] eq "") {
                        foreach (keys %mapserver_lut) {
                                next if ($_ eq "" || $mapip_lut{$_}{'ip'} eq "" || $mapip_lut{$_}{'port'} eq "");
                                $mapip_rlut{"$mapip_lut{$_}{'ip'}".":"."$mapip_lut{$_}{'port'}"} = $_;
                        }
                        foreach (keys %mapip_lut) {
                                next if ($mapip_lut{$_}{'ip'} eq "" || $mapip_lut{$_}{'port'} eq "" || $mapip_rlut{"$mapip_lut{$_}{'ip'}".":"."$mapip_lut{$_}{'port'}"} ne "");
                                $mapip_rlut{"$mapip_lut{$_}{'ip'}".":"."$mapip_lut{$_}{'port'}"} = $_;
                        }
                        print "----------------------------- ת�Ƶ�ͼ�б� ------------------------------\n";
                        printc("w", "IP��ַ          �˿�  ��ͼ         ��ͼ����                          ת��\n");
                        foreach (keys %mapip_rlut) {
                                next if ($_ eq "");
                                if ($mapserver_lut{$mapip_rlut{$_}} ne "") {
                                	$string = "Y";
                                } else {
                                	$string = "";
                                }
				print sprintf("%-17s %-5s %-12s %-36s %-1s\n", $mapip_lut{$mapip_rlut{$_}}{'ip'}, $mapip_lut{$mapip_rlut{$_}}{'port'}, $mapip_rlut{$_}, $mapip_lut{$mapip_rlut{$_}}{'name'}, $string);
                        }
                } elsif ($arg[1] eq "ip" && $arg[2] ne "") {
                        sendFly($arg[2], $arg[3]);
                } elsif ($mapserver_lut{$fly_list[$arg[1]]} ne "" && $mapip_lut{$fly_list[$arg[1]]}{'ip'} ne "") {
                        printc("yw", "<ϵͳ> ", "����ת�Ƶ�: $mapip_lut{$fly_list[$arg[1]]}{'name'}($fly_list[$arg[1]])\n");
                        sendFly($mapip_lut{$fly_list[$arg[1]]}{'ip'}, $mapip_lut{$fly_list[$arg[1]]}{'port'});
                } else {
                        print "��Ч�Ĳ��� 'fly'\n","ʹ�÷���: fly [Map Name|ip] [ip_address] [port]\n";
                }
        }



        if ($printType) {
                $noColor = 0;
                close(BUFFER);
                open(BUFREAD, '<logs/buffer');

                my $msg = '';
                while (<BUFREAD>) {
                        $msg .= $_;
                }
                close(BUFREAD);

                select(STDOUT);
                print "$input\n";
                print $msg;

                if ($xKore) {
                        $msg =~ s/\n*$//s;
                        $msg =~ s/\n/\\n/g;
                        sendMessage(\$remote_socket, "k", $msg);
                }
        }
}


1;