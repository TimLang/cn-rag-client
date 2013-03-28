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
                        print        "命令错误 'a' (Attack Monster)\n"
                                ,"怪物 $arg1 不存在.\n";
                } elsif ($arg1 =~ /^\d+$/) {
                        attack($monstersID[$arg1]);
                } elsif ($arg1 eq "no") {
                        configModify("attackAuto", 1);
                } elsif ($arg1 eq "yes") {
                        configModify("attackAuto", 2);
                } else {
                        print        "无效的参数 'a' (Attack Monster)\n"
                                ,"使用方法: attack <monster # | no | yes >\n";
                }

        } elsif ($switch eq "auth") {
                ($arg1, $arg2) = $input =~ /^[\s\S]*? ([\s\S]*) ([\s\S]*?)$/;
                if ($arg1 eq "" || ($arg2 ne "1" && $arg2 ne "0")) {
                        print        "无效的参数 'auth' (Overall Authorize)\n"
                                ,"使用方法: auth <username> <flag>\n";
                } else {
                        auth($arg1, $arg2);
                }

        } elsif ($switch eq "bestow") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($currentChatRoom eq "") {
                        print        "命令错误 'bestow' (Bestow Admin in Chat)\n"
                                ,"你不在聊天室.\n";
                } elsif ($arg1 eq "") {
                        print        "无效的参数 'bestow' (Bestow Admin in Chat)\n"
                                ,"使用方法: bestow <user #>\n";
                } elsif ($currentChatRoomUsers[$arg1] eq "") {
                        print        "命令错误 'bestow' (Bestow Admin in Chat)\n"
                                ,"聊天室玩家 $arg1 不存在.\n";
                } else {
                        sendChatRoomBestow(\$remote_socket, $currentChatRoomUsers[$arg1]);
                }

        } elsif ($switch eq "buy") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
                if ($arg1 eq "") {
                        print        "无效的参数 'buy' (Buy Store Item)\n"
                                ,"使用方法: buy <item #> [<amount>]\n";
                } elsif ($storeList[$arg1] eq "") {
                        print        "命令错误 'buy' (Buy Store Item)\n"
                                ,"商店物品 $arg1 不存在.\n";
                } else {
                        if ($arg2 <= 0) {
                                $arg2 = 1;
                        }
                        sendBuy(\$remote_socket, $storeList[$arg1]{'nameID'}, $arg2);
                }

        } elsif ($switch eq "c") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($arg1 eq "") {
                        print        "无效的参数 'c' (Chat)\n"
                                ,"使用方法: c <message>\n";
                } else {
                        sendMessage(\$remote_socket, "c", $arg1);
                }

        #Cart command - chobit andy 20030101
        } elsif ($switch eq "cart") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? \w+ \d+ (\d+)/;

                if ($arg1 eq "" || $arg1 eq "eq" || $arg1 eq "u" || $arg1 eq "nu") {
                        printc("nyn", "-----------", "车子物品", "-----------\n");
                        printItemList(\@{$cart{'inventory'}}, $arg1);
                        print "------------------------------\n";
                        print "数量: " . int($cart{'items'}) . "/" . int($cart{'items_max'}) . "  负重: " . int($cart{'weight'}) . "/" . int($cart{'weight_max'}) . "\n";
                        print "------------------------------\n";
                } elsif ($arg1 eq "log") {
			logItem("$logs_path/item_cart.txt", \%cart, "车子物品");
                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'inventory'}[$arg2] eq "") {
                        print        "命令错误 'cart add' (Add Item to Cart)\n"
                                ,"随身物品 $arg2 不存在.\n";
                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/) {
                        if (!$arg3 || $arg3 > $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'}) {
                                $arg3 = $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'};
                        }
                        sendCartAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg2]{'index'}, $arg3);
                } elsif ($arg1 eq "add" && $arg2 eq "") {
                        print        "无效的参数 'cart add' (Add Item to Cart)\n"
                                ,"使用方法: cart add <item #>\n";
                } elsif ($arg1 eq "get" && $arg2 =~ /\d+/ && !%{$cart{'inventory'}[$arg2]}) {
                        print        "命令错误 'cart get' (Get Item from Cart)\n"
                                ,"车子物品 $arg2 不存在.\n";
                } elsif ($arg1 eq "get" && $arg2 =~ /\d+/) {
                        if (!$arg3 || $arg3 > $cart{'inventory'}[$arg2]{'amount'}) {
                                $arg3 = $cart{'inventory'}[$arg2]{'amount'};
                        }
                        sendCartGet(\$remote_socket, $arg2, $arg3);
                } elsif ($arg1 eq "get" && $arg2 eq "") {
                        print        "无效的参数 'cart get' (Get Item from Cart)\n"
                                ,"使用方法: cart get <cart item #>\n";
                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/ && !%{$cart{'inventory'}[$arg2]}) {
                        print        "命令错误 'cart desc' (Cart Item Desciption)\n"
                                ,"车子物品 $arg2 不存在.\n";
                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/) {
                        printItemDesc($cart{'inventory'}[$arg2]{'nameID'});
                } else {
                        print        "无效的参数 'cart' (Cart Items List)\n"
                                ,"使用方法: cart [<eq | u | nu | log | desc>] [<cart #>]\n"
                                ,"          cart [<add | get | close>] [<inventory # | cart #>] [<amount>]\n";
                }


        } elsif ($switch eq "chat") {
                ($replace, $title) = $input =~ /(^[\s\S]*? \"([\s\S]*?)\" ?)/;
                $qm = quotemeta $replace;
                $input =~ s/$qm//;
                @arg = split / /, $input;
                if ($title eq "") {
                        print        "无效的参数 'chat' (Create Chat Room)\n"
                                ,qq~使用方法: chat "<title>" [<limit #> <public flag> <password>]\n~;
                } elsif ($currentChatRoom ne "") {
                        print        "命令错误 'chat' (Create Chat Room)\n"
                                ,"你已经在聊天室里.\n";
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
                        print        "无效的参数 'chatmod' (Modify Chat Room)\n"
                                ,qq~使用方法: chatmod "<title>" [<limit #> <public flag> <password>]\n~;
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
                        print        "无效的参数 'conf' (Config Modify)\n"
                                ,"使用方法: conf <variable> [<value>]\n";
                } elsif (binFind(\@{$ai_v{'temp'}{'conf'}}, $arg1) eq "") {
                        print "Config 参数 $arg1 不存在\n";
                } elsif ($arg2 eq "value") {
                        print "Config '$arg1' 的值为 $config{$arg1}\n";
                } else {
                        configModify($arg1, $arg2);
                }

        } elsif ($switch eq "cri") {
                if ($currentChatRoom eq "") {
                        print        "命令错误 'cri' (Chat Room Information)\n"
                                ,"你不在聊天室里.\n";
                } else {
                        my $public_string = ($chatRooms{$currentChatRoom}{'public'}) ? "Public" : "Private";
                        my $limit_string = $chatRooms{$currentChatRoom}{'num_users'}."/".$chatRooms{$currentChatRoom}{'limit'};
                	printc("nyn", "----------", "聊天室信息", "----------\n");
	                printc("w", "名称                                 人数  公开/私有\n");
			print sprintf("%-36s %-5s %-8s\n",$chatRooms{$currentChatRoom}{'title'},$limit_string,$public_string);
                        printc("nwn", "----", "玩家", "----\n");
                        for ($i = 0; $i < @currentChatRoomUsers; $i++) {
                                next if ($currentChatRoomUsers[$i] eq "");
                                my $user_string = $currentChatRoomUsers[$i];
                                my $admin_string = ($chatRooms{$currentChatRoom}{'users'}{$currentChatRoomUsers[$i]} > 1) ? "(A)" : "";
				print sprintf("%-3d %-3s %-24s\n", $i, $admin_string, $user_string);
                        }
                        print "------------------------------\n";
                }

        } elsif ($switch eq "crl") {
               	printc("nyn", "----------", "聊天室列表", "----------\n");
                printc("w", "#   名称                                 所有者                 人数  公开/私有\n");                	
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
                        print        "命令错误 'deal' (Deal a Player)\n"
                                ,"你已经在交易中.\n";
                } elsif (%incomingDeal && $arg[0] =~ /\d+/) {
                        print        "命令错误 'deal' (Deal a Player)\n"
                                ,"你必须先终止进行中的交易.\n";
                } elsif ($arg[0] =~ /\d+/ && !$playersID[$arg[0]]) {
                        print        "命令错误 'deal' (Deal a Player)\n"
                                ,"玩家 $arg[0] 不存在.\n";
                } elsif ($arg[0] =~ /\d+/) {
                        $outgoingDeal{'ID'} = $playersID[$arg[0]];
                        sendDeal(\$remote_socket, $playersID[$arg[0]]);
			printc("wy", "<信息> ", "你询问 $players{$playersID[$arg[0]]}{'name'} 愿不愿意交易道具\n");

                } elsif ($arg[0] eq "no" && !%incomingDeal && !%outgoingDeal && !%currentDeal) {
                        print        "命令错误 'deal no' (Deal Cancel)\n"
                                ,"没有任何交易可以取消.\n";
                } elsif ($arg[0] eq "no" && (%incomingDeal || %outgoingDeal)) {
                        sendDealCancel(\$remote_socket);
                } elsif ($arg[0] eq "no" && %currentDeal) {
                        sendCurrentDealCancel(\$remote_socket);

                } elsif ($arg[0] eq "" && !%incomingDeal && !%currentDeal) {
                        print        "命令错误 'deal' (Deal a Player)\n"
                                ,"没有任何交易可以接受.\n";
                } elsif ($arg[0] eq "" && $currentDeal{'you_finalize'} && !$currentDeal{'other_finalize'}) {
                        print        "命令错误 'deal' (Deal a Player)\n"
                                ,"无法完成交易 - $currentDeal{'name'} 尚未确认交易.\n";
                } elsif ($arg[0] eq "" && $currentDeal{'final'}) {
                        print        "命令错误 'deal' (Deal a Player)\n"
                                ,"你已经确认开始交换.\n";
                } elsif ($arg[0] eq "" && %incomingDeal) {
                        sendDealAccept(\$remote_socket);
                } elsif ($arg[0] eq "" && $currentDeal{'you_finalize'} && $currentDeal{'other_finalize'}) {
                        sendDealTrade(\$remote_socket);
                        $currentDeal{'final'} = 1;
                        printc("ww", "<信息> ", "你确认开始交换\n");
                } elsif ($arg[0] eq "" && %currentDeal) {
                        sendDealAddItem(\$remote_socket, 0, $currentDeal{'you_zenny'});
                        sendDealFinalize(\$remote_socket);

                } elsif ($arg[0] eq "add" && !%currentDeal) {
                        print        "命令错误 'deal add' (Add Item to Deal)\n"
                                ,"无法放入任何物品到交易栏 - 你没有在交易.\n";
                } elsif ($arg[0] eq "add" && $currentDeal{'you_finalize'}) {
                        print        "命令错误 'deal add' (Add Item to Deal)\n"
                                ,"无法放入任何物品到交易栏 - 你已经确认开始交换.\n";
                } elsif ($arg[0] eq "add" && $arg[1] =~ /\d+/ && !%{$chars[$config{'char'}]{'inventory'}[$arg[1]]}) {
                        print        "命令错误 'deal add' (Add Item to Deal)\n"
                                ,"随身物品 $arg[1] 不存在.\n";
                } elsif ($arg[0] eq "add" && $arg[2] && $arg[2] !~ /\d+/) {
                        print        "命令错误 'deal add' (Add Item to Deal)\n"
                                ,"数量必需为数字, 且必须大于零.\n";
                } elsif ($arg[0] eq "add" && $arg[1] =~ /\d+/) {
                        if (scalar(keys %{$currentDeal{'you'}}) < 10) {
                                if (!$arg[2] || $arg[2] > $chars[$config{'char'}]{'inventory'}[$arg[1]]{'amount'}) {
                                        $arg[2] = $chars[$config{'char'}]{'inventory'}[$arg[1]]{'amount'};
                                }
                                $currentDeal{'lastItemAmount'} = $arg[2];
                                sendDealAddItem(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg[1]]{'index'}, $arg[2]);
                        } else {
        	                print        "命令错误 'deal add' (Add Item to Deal)\n"
	                                ,"最多只能交换10样物品.\n";
                        }
                } elsif ($arg[0] eq "add" && $arg[1] eq "z") {
                        if (!$arg[2] || $arg[2] > $chars[$config{'char'}]{'zenny'}) {
                                $arg[2] = $chars[$config{'char'}]{'zenny'};
                        }
                        $currentDeal{'you_zenny'} = $arg[2];
                        printc("ww", "<信息> ", "加入交易金钱: $arg[2] zeny\n");
                } else {
                        print        "无效的参数 'deal' (Deal a player)\n"
                                ,"使用方法: deal [<Player # | no | add>] [<item #>] [<amount>]\n";
                }

        } elsif ($switch eq "dl") {
                if (!%currentDeal) {
        	        print        "命令错误 'dl' (Deal List)\n"
	                        ,"无法显示交易列表 - 你没有在交易.\n";
                } else {
                	printc("nyn", "-----------", "交易列表", "-----------\n");
                        $other_string = $currentDeal{'name'};
                        $you_string = "你";
                        if ($currentDeal{'other_finalize'}) {
                                $other_string .= " - 已确认";
                        } else {
                                $other_string .= " - 未确认";
                        }                        	
                        if ($currentDeal{'you_finalize'}) {
                                $you_string .= " - 已确认";
                        } else {
                                $you_string .= " - 未确认";                        	
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
                        print        "无效的参数 'drop' (Drop 随身物品)\n"
                                ,"使用方法: drop <item #> [<amount>]\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "命令错误 'drop' (Drop 随身物品)\n"
                                ,"随身物品 $arg1 不存在.\n";
                } else {
                        if (!$arg2 || $arg2 > $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'}) {
                                $arg2 = $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'};
                        }
                	printc("yw", "<系统> ", "您要扔掉 $chars[$config{'char'}]{'inventory'}[$arg1]{'name'} x $arg2 吗？(y/n) ");
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
                        printc("nyn", "-----------", "表情列表", "-----------\n");                	
                        printc("w", "#   表情\n");
                	my $i = 0;
                	while ($emotions_lut{$i} ne "") {
                		print sprintf("%-3d %-10s\n", $i, "$emotions_lut{$i}");
                		$i++;
                	}
                	print "------------------------------\n";
	        } elsif ($arg1 > 47 || $arg1 < 0) {
                        print        "无效的参数 'e' (Emotion)\n"
                                ,"使用方法: e [<emotion # (0-47)>]\n";
                } else {
                        sendEmotion(\$remote_socket, $arg1);
                }

        } elsif ($switch eq "eq") {
                my ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                my ($arg2) = $input =~ /^[\s\S]*? \d+ (\w+)/;
                if ($arg1 eq "") {
                        print        "无效的参数 'equip' (Equip Inventory Item)\n"
                                ,"使用方法: equip <item #> [left]\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "命令错误 'equip' (Equip Inventory Item)\n"
                                ,"随身物品 $arg1 不存在.\n";
                } elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type_equip'} == 0 && $chars[$config{'char'}]{'inventory'}[$arg1]{'type'} != 10) {
                        print        "命令错误 'equip' (Equip Inventory Item)\n"
                                ,"随身物品 $arg1 不是装备.\n";
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
                        print        "无效的参数 'follow' (Follow Player)\n"
                                ,"使用方法: follow <player #>\n";
                } elsif ($arg1 eq "stop") {
                        aiRemove("follow");
                        configModify("follow", 0);
                } elsif ($playersID[$arg1] eq "") {
                        print        "命令错误 'follow' (Follow Player)\n"
                                ,"玩家 $arg1 不存在.\n";
                } else {
                        ai_follow($players{$playersID[$arg1]}{'name'});
                        configModify("follow", 1);
                        configModify("followTarget", $players{$playersID[$arg1]}{'name'});
                }

        #Guild Chat - chobit andy 20030101
        } elsif ($switch eq "g") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($arg1 eq "") {
                        print "无效的参数 'g' (Guild Chat)\n"
                                ,"使用方法: g <message>\n";
                } else {
                        sendMessage(\$remote_socket, "g", $arg1);
                }
        } elsif ($switch eq "i") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                ($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
                if ($arg1 eq "" || $arg1 eq "eq" || $arg1 eq "u" || $arg1 eq "nu") {
                        printc("nyn", "-----------", "随身物品", "-----------\n");
                        printItemList(\@{$chars[$config{'char'}]{'inventory'}}, $arg1);
                        print "------------------------------\n";
                        print "数量: " . int($chars[$config{'char'}]{'items'}) . "/" . int($chars[$config{'char'}]{'items_max'}) . "  负重: " . int($chars[$config{'char'}]{'weight'}) . "/" . int($chars[$config{'char'}]{'weight_max'}) . "\n";                        
		        print "------------------------------\n";
                } elsif ($arg1 eq "log") {
			logItem("$logs_path/item_inventory.txt", \%{$chars[$config{'char'}]}, "随身物品");

                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'inventory'}[$arg2] eq "") {
                        print        "命令错误 'i desc' (Iventory Item Desciption)\n"
                                ,"随身物品 $arg2 不存在.\n";
                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/) {
                        printItemDesc($chars[$config{'char'}]{'inventory'}[$arg2]{'nameID'});

                } else {
                        print        "无效的参数 'i' (Iventory List)\n"
                                ,"使用方法: i [<eq | u | nu | desc>] [<inventory #>]\n";
                }

        } elsif ($switch eq "identify") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                if ($arg1 eq "") {
                        printc("nyn", "---------", "物品鉴定列表", "---------\n");
	                printc("w", "#   名称\n");
                        for ($i = 0; $i < @identifyID; $i++) {
                                next if ($identifyID[$i] eq "");
				print sprintf("%-3d %-40s\n",$i,$chars[$config{'char'}]{'inventory'}[$identifyID[$i]]{'name'});
                        }
                        print "------------------------------\n";
                } elsif ($arg1 =~ /\d+/ && $identifyID[$arg1] eq "") {
                        print        "命令错误 'identify' (Identify Item)\n"
                                ,"鉴定物品 $arg1 不存在.\n";

                } elsif ($arg1 =~ /\d+/) {
                        sendIdentify(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$identifyID[$arg1]]{'index'});
                } else {
                        print        "无效的参数 'identify' (Identify Item)\n"
                                ,"使用方法: identify [<identify #>]\n";
                }


        } elsif ($switch eq "ignore") {
                ($arg1, $arg2) = $input =~ /^[\s\S]*? (\d+) ([\s\S]*)/;
                if ($arg1 eq "" || $arg2 eq "" || ($arg1 ne "0" && $arg1 ne "1")) {
                        print        "无效的参数 'ignore' (Ignore Player/Everyone)\n"
                                ,"使用方法: ignore <flag> <name | all>\n";
                } else {
                        if ($arg2 eq "all") {
                                sendIgnoreAll(\$remote_socket, !$arg1);
                        } else {
                                sendIgnore(\$remote_socket, $arg2, !$arg1);
                        }
                }

        } elsif ($switch eq "il") {
                printc("nyn", "---------", "地上物品列表", "---------\n");
                printc("w", "#   位置      名称\n");                
                for ($i = 0; $i < @itemsID; $i++) {
                        next if ($itemsID[$i] eq "");
			print sprintf("%-3d %-9s %-40s\n",$i,"($items{$itemsID[$i]}{'pos'}{'x'},$items{$itemsID[$i]}{'pos'}{'y'})","$items{$itemsID[$i]}{'name'} x $items{$itemsID[$i]}{'amount'}");
                }
                print "------------------------------\n";

        } elsif ($switch eq "im") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
                if ($arg1 eq "" || $arg2 eq "") {
                        print        "无效的参数 'im' (Use Item on Monster)\n"
                                ,"使用方法: im <item #> <monster #>\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "命令错误 'im' (Use Item on Monster)\n"
                                ,"随身物品 $arg1 不存在.\n";
                } elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
                        print        "命令错误 'im' (Use Item on Monster)\n"
                                ,"随身物品 $arg1 不是可使用物品.\n";
                } elsif ($monstersID[$arg2] eq "") {
                        print        "命令错误 'im' (Use Item on Monster)\n"
                                ,"怪物 $arg2 不存在.\n";
                } else {
                        sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $monstersID[$arg2]);
                }

        } elsif ($switch eq "ip") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
                if ($arg1 eq "" || $arg2 eq "") {
                        print        "无效的参数 'ip' (Use Item on Player)\n"
                                ,"使用方法: ip <item #> <player #>\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "命令错误 'ip' (Use Item on Player)\n"
                                ,"随身物品 $arg1 不存在.\n";
                } elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
                        print        "命令错误 'ip' (Use Item on Player)\n"
                                ,"随身物品 $arg1 不是可使用物品.\n";
                } elsif ($playersID[$arg2] eq "") {
                        print        "命令错误 'ip' (Use Item on Player)\n"
                                ,"玩家 $arg2 不存在.\n";
                } else {
                        sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $playersID[$arg2]);
                }

        } elsif ($switch eq "is") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                if ($arg1 eq "") {
                        print        "无效的参数 'is' (Use Item on Self)\n"
                                ,"使用方法: is <item #>\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "命令错误 'is' (Use Item on Self)\n"
                                ,"随身物品 $arg1 不存在.\n";
                } elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
                        print        "命令错误 'is' (Use Item on Self)\n"
                                ,"随身物品 $arg1 is 不是可使用物品.\n";
                } else {
                        sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $accountID);
                }

        } elsif ($switch eq "join") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ ([\s\S]*)$/;
                if ($arg1 eq "") {
                        print        "无效的参数 'join' (Join Chat Room)\n"
                                ,"使用方法: join <chat room #> [<password>]\n";
                } elsif ($currentChatRoom ne "") {
                        print        "命令错误 'join' (Join Chat Room)\n"
                                ,"You are already in a chat room.\n";
                } elsif ($chatRoomsID[$arg1] eq "") {
                        print        "命令错误 'join' (Join Chat Room)\n"
                                ,"Chat Room $arg1 不存在.\n";
                } else {
                        sendChatRoomJoin(\$remote_socket, $chatRoomsID[$arg1], $arg2);
                }

        } elsif ($switch eq "judge") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
                if ($arg1 eq "" || $arg2 eq "") {
                        print        "无效的参数 'judge' (Give an alignment point to Player)\n"
                                ,"使用方法: judge <player #> <0 (good) | 1 (bad)>\n";
                } elsif ($playersID[$arg1] eq "") {
                        print        "命令错误 'judge' (Give an alignment point to Player)\n"
                                ,"玩家 $arg1 不存在.\n";
                } else {
                        $arg2 = ($arg2 >= 1);
                        sendAlignment(\$remote_socket, $playersID[$arg1], $arg2);
                }

        } elsif ($switch eq "kick") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($currentChatRoom eq "") {
                        print        "命令错误 'kick' (Kick from Chat)\n"
                                ,"你不在聊天室里.\n";
                } elsif ($arg1 eq "") {
                        print        "无效的参数 'kick' (Kick from Chat)\n"
                                ,"使用方法: kick <user #>\n";
                } elsif ($currentChatRoomUsers[$arg1] eq "") {
                        print        "命令错误 'kick' (Kick from Chat)\n"
                                ,"聊天室玩家 $arg1 不存在.\n";
                } else {
                        sendChatRoomKick(\$remote_socket, $currentChatRoomUsers[$arg1]);
                }

        } elsif ($switch eq "leave") {
                if ($currentChatRoom eq "") {
                        print        "命令错误 'leave' (Leave Chat Room)\n"
                                ,"你不在聊天室里.\n";
                } else {
                        sendChatRoomLeave(\$remote_socket);
                }

        } elsif ($switch eq "look") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
                if ($arg1 eq "") {
                        print        "无效的参数 'look' (Look a Direction)\n"
                                ,"使用方法: look <body dir> [<head dir>]\n";
                } else {
                        look($arg1, $arg2);
                }

        } elsif ($switch eq "memo") {
                sendMemo(\$remote_socket);

        } elsif ($switch eq "ml") {
                printc("nyn", "-----------", "怪物列表", "-----------\n");
                printc("w", "#   位置      距离 名称                     伤害     攻击     防守\n");
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
                        print        "无效的参数 'move' (Move Player)\n"
                                ,"使用方法: move <x> <y> &| <map>\n";
                } elsif ($ai_v{'temp'}{'map'} eq "stop") {
                        aiRemove("move");
                        aiRemove("route");
                        aiRemove("route_getRoute");
                        aiRemove("route_getMapRoute");
                        print "停止所有移动.\n";
                } else {
                        $ai_v{'temp'}{'map'} = $field{'name'} if ($ai_v{'temp'}{'map'} eq "");
                        if ($maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}) {
                                if ($arg2 ne "") {
                                        printc("yw", "<系统> ", "正在计算路线: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $arg1, $arg2\n");
                                        $ai_v{'temp'}{'x'} = $arg1;
                                        $ai_v{'temp'}{'y'} = $arg2;
                                } else {
                                        printc("yw", "<系统> ", "正在计算路线: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'})\n");
                                        undef $ai_v{'temp'}{'x'};
                                        undef $ai_v{'temp'}{'y'};
                                }
                                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
                        } else {
	                        print        "命令错误 'move' (Move Player)\n"
                                	,"地图 $ai_v{'temp'}{'map'} 不存在.\n";
                        }
                }

        } elsif ($switch eq "nl") {
                printc("nyn", "-----------", "人物列表", "-----------\n");
                printc("w", "#   位置      名称\n");
                for ($i = 0; $i < @npcsID; $i++) {
                        next if ($npcsID[$i] eq "");
			print sprintf("%-3d %-9s %-40s\n",$i,"($npcs{$npcsID[$i]}{'pos'}{'x'},$npcs{$npcsID[$i]}{'pos'}{'y'})",$npcs{$npcsID[$i]}{'name'});                        
                }
                print "------------------------------\n";

        } elsif ($switch eq "p") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($arg1 eq "") {
                        print        "无效的参数 'p' (Party Chat)\n"
                                ,"使用方法: p <message>\n";
                } else {
                        sendMessage(\$remote_socket, "p", $arg1);
                }

        } elsif ($switch eq "party") {
                ($arg1) = $input =~ /^[\s\S]*? (\w*)/;
                ($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)\b/;
                if ($arg1 eq "" && !%{$chars[$config{'char'}]{'party'}}) {
                        print        "命令错误 'party' (Party Functions)\n"
                                ,"无法显示队伍列表 - 你没有队伍.\n";
                } elsif ($arg1 eq "") {
	                printc("nyn", "-----------", "队伍列表", "-----------\n");
	                print "名称: $chars[$config{'char'}]{'party'}{'name'}\n";
                        printc("w", "#       玩家                     地图        位置      在线 HP\n");
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
                                print        "无效的参数 'party create' (Organize Party)\n"
                                ,qq~使用方法: party create "<party name>"\n~;
                        } else {
                                sendPartyOrganize(\$remote_socket, $arg2);
                        }

                } elsif ($arg1 eq "join" && $arg2 ne "1" && $arg2 ne "0") {
                        print        "无效的参数 'party join' (Accept/Deny Party Join Request)\n"
                                ,"使用方法: party join <flag>\n";
                } elsif ($arg1 eq "join" && $incomingParty{'ID'} eq "") {
                        print        "命令错误 'party join' (Join/Request to Join Party)\n"
                                ,"无法接受或拒绝队伍邀请 - 没有队伍邀请.\n";
                } elsif ($arg1 eq "join") {
                        sendPartyJoin(\$remote_socket, $incomingParty{'ID'}, $arg2);
                        undef %incomingParty;

                } elsif ($arg1 eq "request" && !%{$chars[$config{'char'}]{'party'}}) {
                        print        "命令错误 'party request' (Request to Join Party)\n"
                                ,"无法邀请加入 - 你没有队伍.\n";
                } elsif ($arg1 eq "request" && $playersID[$arg2] eq "") {
                        print        "命令错误 'party request' (Request to Join Party)\n"
                                ,"无法邀请加入 - 玩家 $arg2 不存在.\n";
                } elsif ($arg1 eq "request") {
                        sendPartyJoinRequest(\$remote_socket, $playersID[$arg2]);

                } elsif ($arg1 eq "leave" && !%{$chars[$config{'char'}]{'party'}}) {
                        print        "命令错误 'party leave' (Leave Party)\n"
                                ,"无法离开队伍 - 你没有队伍.\n";
                } elsif ($arg1 eq "leave") {
                        sendPartyLeave(\$remote_socket);

                } elsif ($arg1 eq "share" && !%{$chars[$config{'char'}]{'party'}}) {
                        print        "命令错误 'party share' (Set Party Share EXP)\n"
                                ,"无法设定经验值分配 - 你没有队伍.\n";
                } elsif ($arg1 eq "share" && $arg2 ne "1" && $arg2 ne "0") {
                        print        "无效的参数 'party share' (Set Party Share EXP)\n"
                                ,"使用方法: party share <flag>\n";
                } elsif ($arg1 eq "share") {
                        sendPartyShareEXP(\$remote_socket, $arg2);

                } elsif ($arg1 eq "kick" && !%{$chars[$config{'char'}]{'party'}}) {
                        print        "命令错误 'party kick' (Kick Party Member)\n"
                                ,"无法踢出玩家 - 你没有队伍.\n";
                } elsif ($arg1 eq "kick" && $arg2 eq "") {
                        print        "无效的参数 'party kick' (Kick Party Member)\n"
                                ,"使用方法: party kick <party member #>\n";
                } elsif ($arg1 eq "kick" && $partyUsersID[$arg2] eq "") {
                        print        "命令错误 'party kick' (Kick Party Member)\n"
                                ,"无法踢出玩家 - 玩家 $arg2 不存在.\n";
                } elsif ($arg1 eq "kick") {
                        sendPartyKick(\$remote_socket, $partyUsersID[$arg2], $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$arg2]}{'name'});
                }

        } elsif ($switch eq "pet") {
                my ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                if ( $arg1 eq "info" || $arg1 eq "") {
	                printc("nyn", "-----------", "宠物信息", "-----------\n");
                        print sprintf("名称  : %-20s 级别  : %-2s\n",$chars[$config{'char'}]{'pet'}{'name'},$chars[$config{'char'}]{'pet'}{'level'});
                        print sprintf("饱食度: %-20s 亲密度: %-10s\n",$chars[$config{'char'}]{'pet'}{'hungry'}."/100",$chars[$config{'char'}]{'pet'}{'friendly'}."/1000");
                        print "------------------------------\n";
                } elsif ( $arg1 eq "feed"){
                        sendPetCommand(\$remote_socket,1);
                        print "发出宠物喂养命令\n";
                } elsif ( $arg1 eq "play"){
                        sendPetCommand(\$remote_socket,2);
                        print "发出宠物表演命令\n";
                } elsif ( $arg1 eq "back"){
                        sendPetCommand(\$remote_socket,3);
                        print "发出宠物回收命令\n";
                } else {
                        print "无效的参数 'pet' ( pet command )\n"
                        ,"使用方法: pet [<info | feed | play | back>]\n";
                }

        } elsif ($switch eq "petl") {
                printc("nyn", "-----------", "宠物列表", "-----------\n");
                printc("w", "#   类型                         名称\n");
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
                        print        "无效的参数 'pm' (Private Message)\n"
                                ,qq~使用方法: pm ("<username>" | <pm #>) <message>\n~;
                } elsif ($type) {
                        if ($arg1 - 1 >= @privMsgUsers) {
                                print        "命令错误 'pm' (Private Message)\n"
                                ,"私聊列表玩家 $arg1 不存在.\n";
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
                printc("nyn", "-----------", "私聊列表", "-----------\n");
                printc("w", "#   名称\n");
                for ($i = 1; $i <= @privMsgUsers; $i++) {
			print sprintf("%-3d %-30s\n",$i,$privMsgUsers[$i - 1]);
		}
                print "------------------------------\n";

        } elsif ($switch eq "pl") {
                printc("nyn", "-----------", "玩家列表", "-----------\n");
                printc("w", "#   位置      距离 名称                                       性别 职业\n");
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
                printc("nyn", "----------", "传送点列表", "----------\n");
                printc("w", "#   位置      名称\n");
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
		printc("ny", "----------------", "基本信息窗口");
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
                        print        "无效的参数 'sell' (Sell 随身物品)\n"
                                ,"使用方法: sell <item #> [<amount>]\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "命令错误 'sell' (Sell 随身物品)\n"
                                ,"随身物品 $arg1 不存在.\n";
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
                        print        "无效的参数 'sm' (Use Skill on Monster)\n"
                                ,"使用方法: sm <skill #> <monster #> [<skill lvl>]\n";
                } elsif ($monstersID[$arg2] eq "") {
                        print        "命令错误 'sm' (Use Skill on Monster)\n"
                                ,"怪物 $arg2 不存在.\n";
                } elsif ($skillsID[$arg1] eq "") {
                        print        "命令错误 'sm' (Use Skill on Monster)\n"
                                ,"技能 $arg1 不存在.\n";
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
                        printc("nyn", "-----------", "技能列表", "-----------\n");
                        printc("w", "#   技能名称             级别     消耗SP\n");
                        for ($i=0; $i < @skillsID; $i++) {
                 	       print sprintf("%-3d %-20s %-8s %-8s\n",$i,$skills_lut{$skillsID[$i]},$chars[$config{'char'}]{'skills'}{$skillsID[$i]}{'lv'},$skillsSP_lut{$skillsID[$i]}{$chars[$config{'char'}]{'skills'}{$skillsID[$i]}{'lv'}});
	                }
                        print "-------------------------------\n";
                        print "剩余技能点数: $chars[$config{'char'}]{'points_skill'}\n";
                        print "-------------------------------\n";

                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $skillsID[$arg2] eq "") {
                        print        "命令错误 'skills add' (Add Skill Point)\n"
                                ,"技能 $arg2 不存在.\n";
                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'points_skill'} < 1) {
                        print        "命令错误 'skills add' (Add Skill Point)\n"
                                ,"没有足够的技能点数.\n";
                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/) {
                	printc("yw", "<系统> ", "您要把技能点分配给 $skills_lut{$skillsID[$arg2]} 吗？(y/n) ");
			$temp_msg = "\0" x 256;
			$temp_msgLen = $input_recv->Call($temp_msg, 1);
			$temp_msg = substr($temp_msg, 0, $temp_msgLen);
                        if ($temp_msg =~ /y/) {
	                        sendAddSkillPoint(\$remote_socket, $chars[$config{'char'}]{'skills'}{$skillsID[$arg2]}{'ID'});
	                }

                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/ && $skillsID[$arg2] eq "") {
                        print        "命令错误 'skills desc' (Skill Description)\n"
                                ,"技能 $arg2 不存在.\n";
                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/) {
		        dynParseFiles("data/skillsdescriptions.txt", \%skillsDesc_lut, \&parseRODescLUT);
                        printc("nyn", "-----------", "技能说明", "-----------\n");
                        printc("w", "技能: $skills_lut{$skillsID[$arg2]}\n\n");
                        print $skillsDesc_lut{$skillsID[$arg2]};
                        print "-------------------------------\n";
                        undef %skillsDesc_lut;
                } else {
                        print        "无效的参数 'skills' (Skills Functions)\n"
                                ,"使用方法: skills [<add | desc>] [<skill #>]\n";
                }


        } elsif ($switch eq "sp") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
                ($arg3) = $input =~ /^[\s\S]*? \d+ \d+ (\d+)/;
                if ($arg1 eq "" || $arg2 eq "") {
                        print        "无效的参数 'sp' (Use Skill on Player)\n"
                                ,"使用方法: sp <skill #> <player #> [<skill lvl>]\n";
                } elsif ($playersID[$arg2] eq "") {
                        print        "命令错误 'sp' (Use Skill on Player)\n"
                                ,"玩家 $arg2 不存在.\n";
                } elsif ($skillsID[$arg1] eq "") {
                        print        "命令错误 'sp' (Use Skill on Player)\n"
                                ,"技能 $arg1 不存在.\n";
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
                        print        "无效的参数 'ss' (Use Skill on Self)\n"
                                ,"使用方法: ss <skill #> [<skill lvl>]\n";
                } elsif ($skillsID[$arg1] eq "") {
                        print        "命令错误 'ss' (Use Skill on Self)\n"
                                ,"技能 $arg1 不存在.\n";
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
		printc("nyn", "----------------", "能力属性窗口", "----------------\n");
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
                        print        "无效的参数 'stat_add' (Add Status Point)\n"
                        ,"使用方法: stat_add <str | agi | vit | int | dex | luk>\n";
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
                                print        "命令错误 'stat_add' (Add Status Point)\n"
                                        ,"没有足够的属性点数\n";
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
                        printc("nyn", "-----------", "仓库物品", "-----------\n");
                        printItemList(\@{$storage{'inventory'}}, $arg1);
                        print "------------------------------\n";
                        print "数量: $storage{'items'}/$storage{'items_max'}\n";
                        print "------------------------------\n";
                } elsif ($arg1 eq "log") {
			logItem("$logs_path/item_storage.txt", \%storage, "仓库物品");
                } elsif ($arg1 eq "addindex" && $arg2 =~ /\d+/ && findIndexString(\@{$chars[$config{'char'}]{'inventory'}}, "index", $arg2) ne "") {
                        print        "命令错误 'storage addindex' (Add Item to Storage by index)\n"
                                ,"随身物品 $arg2 存在.\n";
                } elsif ($arg1 eq "addindex" && $arg2 =~ /\d+/) {
                        sendStorageAdd(\$remote_socket, $arg2, $arg3);
                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'inventory'}[$arg2] eq "") {
                        print        "命令错误 'storage add' (Add Item to Storage)\n"
                                ,"随身物品 $arg2 不存在.\n";
                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/) {
                        if (!$arg3 || $arg3 > $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'}) {
                                $arg3 = $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'};
                        }
                        sendStorageAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg2]{'index'}, $arg3);

                } elsif ($arg1 eq "get" && $arg2 =~ /\d+/ && !%{$storage{'inventory'}[$arg2]}) {
                        print        "命令错误 'storage get' (Get Item from Storage)\n"
                                ,"仓库物品 $arg2 不存在.\n";
                } elsif ($arg1 eq "get" && $arg2 =~ /\d+/) {
                        if (!$arg3 || $arg3 > $storage{'inventory'}[$arg2]{'amount'}) {
                                $arg3 = $storage{'inventory'}[$arg2]{'amount'};
                        }
                        sendStorageGet(\$remote_socket, $arg2, $arg3);

                } elsif ($arg1 eq "close") {
                        sendStorageClose(\$remote_socket);

                } elsif ($arg1 eq "clear") {
			$ai_v{'ai_storageAuto_clear'} = 1;
                        printc(1, "yw", "<系统> ", "开始清理仓库\n");
			unshift @ai_seq, "sellAuto";
			unshift @ai_seq_args, {};

                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/ && !%{$storage{'inventory'}[$arg2]}) {
                        print        "命令错误 'storage desc' (Storage Item Desciption)\n"
                                ,"仓库物品 $arg2 不存在.\n";
                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/) {
                        printItemDesc($storage{'inventory'}[$arg2]{'nameID'});
                } else {
                        print        "无效的参数 'storage' (Storage List)\n"
                                ,"使用方法: storage [<eq | u | nu | log | clear | desc>] [<storage #>]\n"
                                ,"          storage [<add | get | close>] [<inventory # | storage #>] [<amount>]\n";
                }

        } elsif ($switch eq "store") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                ($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
                if ($arg1 eq "" && !$talk{'buyOrSell'}) {
                        printc("nyn", "---------", "商店物品列表", "---------\n");
	                printc("w", "#   名称                 类型           价格\n");
                        for ($i=0; $i < @storeList;$i++) {
	                        print sprintf("%-3d %-20s %-10s %8sz\n",$i ,$storeList[$i]{'name'} ,$itemTypes_lut{$storeList[$i]{'type'}} ,$storeList[$i]{'price'});
                        }
                        print "------------------------------\n";
                } elsif ($arg1 eq "" && $talk{'buyOrSell'}) {
                        sendGetStoreList(\$remote_socket, $talk{'ID'});

                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/ && $storeList[$arg2] eq "") {
                        print        "命令错误 'store desc' (Store Item Description)\n"
                                ,"商店物品 $arg2 不存在.\n";
                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/) {
                        printItemDesc($storeList[$arg2]);

                } else {
                        print        "无效的参数 'store' (Store List)\n"
                                ,"使用方法: store [<desc>] [<store item #>]\n";
                }

        } elsif ($switch eq "take") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)$/;
                if ($arg1 eq "") {
                        print        "无效的参数 'take' (Take Item)\n"
                                ,"使用方法: take <item #>\n";
                } elsif ($itemsID[$arg1] eq "") {
                        print        "命令错误 'take' (Take Item)\n"
                                ,"地上物品 $arg1 不存在.\n";
                } else {
                        take($itemsID[$arg1]);
                }

        } elsif ($switch eq "warp") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)$/;
                if ($arg1 eq "") {
                        print        "无效的参数 'warp' (Warp to Map)\n"
                                ,"使用方法: warp <map name>\n";
                } elsif ($maps_lut{$arg1.'.rsw'} eq "") {
                        print        "命令错误 'warp' (Warp to Map)\n"
                                ,"地图 $arg1 不存在.\n";              	
                } else {
        		ai_warp($arg1);
        	}

        } elsif ($switch eq "resp") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                if (!@{$warp{'responses'}}) {
                        print        "命令错误 'resp' (Respond)\n"
                                ,"没有应答列表.\n";
                } elsif ($arg1 eq "") {
                        printc("nyn", "-----------", "应答列表", "-----------\n");
                        printc("w", "#   内容\n");
                        for ($i=0; $i < @{$warp{'responses'}};$i++) {
                        	print sprintf("%-3d %-30s\n", $i, $warp{'responses'}[$i]);
                        }
                        print "------------------------------\n";
                        printc("ww", "<对话>", "输入 'resp' 选择应答\n");

                } elsif ($warp{'responses'}[$arg1] eq "") {
                        print        "命令错误 'resp' (Respond)\n"
                                ,"应答 $arg1 不存在.\n";

                } else {
                        sendWarpto(\$remote_socket, $warp{'responses'}[$arg1]);
                }

#####
        } elsif ($switch eq "talk") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                ($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)/;

                if ($arg1 =~ /^\d+$/ && $npcsID[$arg1] eq "") {
                        print        "命令错误 'talk' (Talk to NPC)\n"
                                ,"人物 $arg1 不存在.\n";
                } elsif ($arg1 =~ /^\d+$/) {
                        sendTalk(\$remote_socket, $npcsID[$arg1]);

                } elsif ($arg1 eq "resp" && !%talk) {
                        print        "命令错误 'talk resp' (Respond to NPC)\n"
                                ,"你没有与任何人物交谈.\n";
                } elsif ($arg1 eq "resp" && $arg2 eq "") {
                        $display = $npcs{$talk{'ID'}}{'name'};
                        printc("nyn", "-----------", "回答列表", "-----------\n");
                        print "人物: $npcs{$talk{'ID'}}{'name'}\n";
                        printc("w", "#   内容\n");
                        for ($i=0; $i < @{$talk{'responses'}};$i++) {
	                      	print sprintf("%-3d %-30s\n", $i, $talk{'responses'}[$i]);                        
                        }
                        print "------------------------------\n";
                } elsif ($arg1 eq "resp" && $arg2 ne "" && $talk{'responses'}[$arg2] eq "") {
                        print        "命令错误 'talk resp' (Respond to NPC)\n"
                                ,"回答 $arg2 不存在.\n";
                } elsif ($arg1 eq "resp" && $arg2 ne "") {
                        $arg2 += 1;
                        sendTalkResponse(\$remote_socket, $talk{'ID'}, $arg2);

                } elsif ($arg1 eq "cont" && !%talk) {
                        print        "命令错误 'talk cont' (Continue Talking to NPC)\n"
                                ,"你没有与任何人物交谈.\n";
                } elsif ($arg1 eq "cont") {
                        sendTalkContinue(\$remote_socket, $talk{'ID'});
                } elsif ($arg1 eq "answer" && %talk) {
                        sendTalkAnswer(\$remote_socket, $talk{'ID'}, $arg2);
                } elsif ($arg1 eq "no" && %talk) {
                        sendTalkCancel(\$remote_socket, $talk{'ID'});
                } else {
                        print        "无效的参数 'talk' (Talk to NPC)\n"
                                ,"使用方法: talk <NPC # | cont | resp | answer | no> [<response # | amount>]\n";
                }

        } elsif ($switch eq "tank") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                if ($arg1 eq "") {
                        print        "无效的参数 'tank' (Tank for a Player)\n"
                                ,"使用方法: tank <player #>\n";
                } elsif ($arg1 eq "stop") {
                        configModify("tankMode", 0);
                } elsif ($playersID[$arg1] eq "") {
                        print        "命令错误 'tank' (Tank for a Player)\n"
                                ,"玩家 $arg1 不存在.\n";
                } else {
                        configModify("tankMode", 1);
                        configModify("tankModeTarget", $players{$playersID[$arg1]}{'name'});
                }

        } elsif ($switch eq "tele") {
                useTeleport(1);

        } elsif ($switch eq "timeout") {
                ($arg1, $arg2) = $input =~ /^[\s\S]*? ([\s\S]*) ([\s\S]*?)$/;
                if ($arg1 eq "") {
                        print        "无效的参数 'timeout' (set a timeout)\n"
                                ,"使用方法: timeout <type> [<seconds>]\n";
                } elsif ($timeout{$arg1} eq "") {
                        print        "命令错误 'timeout' (set a timeout)\n"
                                ,"Timeout $arg1 不存在\n";
                } elsif ($arg2 eq "") {
                        print "Timeout '$arg1' 的值为 $timeout{$arg1}{'timeout'}\n";
                } else {
                        setTimeout($arg1, $arg2);
                }

        } elsif ($switch eq "uneq") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                if ($arg1 eq "") {
                        print        "无效的参数 'unequip' (Unequip Inventory Item)\n"
                                ,"使用方法: unequip <item #>\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "命令错误 'unequip' (Unequip Inventory Item)\n"
                                ,"随身物品 $arg1 不存在.\n";
                } elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'equipped'} == 0) {
                        print        "命令错误 'unequip' (Unequip Inventory Item)\n"
                                ,"随身物品 $arg1 没有装备.\n";
                } else {
                        sendUnequip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'});
                        undef $chars[$config{'char'}]{'autoSwitch'};
                }

        } elsif ($switch eq "where") {
                ($map_string) = $map_name =~ /([\s\S]*)\.gat/;
                print "位置: $maps_lut{$map_string.'.rsw'}($map_string) ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n";

        } elsif ($switch eq "who") {
                sendWho(\$remote_socket);

        } elsif ($switch eq "shop") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? \w+ \d+ (\d+)/;
		($arg4) = $input =~ /^[\s\S]*? \w+ \d+ \d+ (\d+)/;
		if ($arg1 eq "") {
			if (!$chars[$config{'char'}]{'shopOpened'}) {
                                print        "命令错误 'shop' (Show My Shop)\n"
                                	,"你的露天商店还没开张.\n";
			} else {
	                        printc("nyn", "--------", "我的露天商店", "--------\n");
				print "店名: $shop{'title'}\n";
	        	        printc("w", "#   名称                           类型           价格   数量  已卖\n");
                        	for ($i=0; $i < @{$shop{'inventory'}};$i++) {
                        		next if ($shop{'inventory'}[$i] eq "");
	                        	print sprintf("%-3d %-30s %-10s %8dz %5d %5d\n", $i, $shop{'inventory'}[$i]{'name'}, $itemTypes_lut{$shop{'inventory'}[$i]{'type'}}, $shop{'inventory'}[$i]{'price'}, $shop{'inventory'}[$i]{'amount'}, $shop{'inventory'}[$i]{'sold'});
	                        }
        	                print "------------------------------\n";
                                $chars[$config{'char'}]{'shopEarned'} = 0 if ($chars[$config{'char'}]{'shopEarned'} eq "");
                	        print "露天商店收入: $chars[$config{'char'}]{'shopEarned'}"."z\n";
                        	print "------------------------------\n";
                        }
		} elsif ($arg1 eq "list") {
                        printc("nyn", "--------", "露天商店列表", "--------\n");			
	                printc("w", "#   名称                                 所有者\n");
                        for ($i = 0; $i < @venderListsID; $i++) {
                                next if ($venderListsID[$i] eq "");
                                $owner_string = ($venderListsID[$i] ne $accountID) ? $players{$venderListsID[$i]}{'name'} : $chars[$config{'char'}]{'name'};
				print sprintf("%-3d %-36s %-22s %-5s %-8s\n", $i, $venderLists{$venderListsID[$i]}{'title'}, $owner_string);
                        }
			print "------------------------------\n";
                } elsif ($arg1 eq "open") {
			if ($chars[$config{'char'}]{'shopOpened'}) {
                                print        "命令错误 'shop open' (Open My Shop)\n"
                                	,"你的露天商店已经开张了.\n";
                        } else {
	                        sendOpenShop(\$remote_socket);
        	                $shop_control{'shopAuto_open'} = 1;
        	        }
                } elsif ($arg1 eq "close") {
			if (!$chars[$config{'char'}]{'shopOpened'}) {
                                print        "命令错误 'shop close' (Close My Shop)\n"
                                	,"你的露天商店还没开张.\n";
                        } else {
	                        sendCloseShop(\$remote_socket);
        	                $shop_control{'shopAuto_open'} = 0;
                        }
                } elsif ($arg1 eq "enter") {
                        if ($arg2 eq "") {
                        	print        "无效的参数 'shop enter' (Enter to Shop)\n"
                                	,"使用方法: shop enter <shop #>\n";
                        } elsif ($venderListsID[$arg2] eq "") {
                                print        "命令错误 'shop enter' (Enter to Shop)\n"
                                	,"露天商店 $arg2 不存在.\n";
                        } else {
	                        sendEnteringVender(\$remote_socket, $venderListsID[$arg2]);
	                }
                } elsif ($arg1 eq "item") {
                	if (!%{$venderLists{$venderID}}) {
                                print        "命令错误 'shop item' (List Item from Shop)\n"
                                	,"你没有进入任何露天商店.\n";
			} else {
	                        printc("nyn", "------", "露天商店物品列表", "------\n");
				print "店名: $venderLists{$venderID}{'title'}\n";
		                printc("w", "#   名称                           类型           价格   数量\n");
	                        for ($i=0; $i < @venderItemList;$i++) {
	                        	next if ($venderItemList[$i] eq "");
		                        print sprintf("%-3d %-30s %-10s %8dz %5d\n", $i, $venderItemList[$i]{'name'}, $itemTypes_lut{$venderItemList[$i]{'type'}}, $venderItemList[$i]{'price'}, $venderItemList[$i]{'amount'});
                	        }
                        	print "------------------------------\n";
                        }
                } elsif ($arg1 eq "quit") {
	                printc("wr", "<信息> ", "你离开了露天商店\n");
                        undef @venderItemList;
                        undef $venderID;
                } elsif ($arg1 eq "buy") {
                        if ($venderID eq "") {
                                print        "命令错误 'shop buy' (Buy Item from Shop)\n"
                                	,"你没有进入任何露天商店.\n";
                        } elsif (%{$venderItemList[$arg2]} && $arg3 > 0 && $arg3 =~ /\d+/) {
                                sendBuyVender(\$remote_socket, $arg2, $arg3);
                        } else {
                        	print        "无效的参数 'shop buy' (Buy Item from Shop)\n"
                                	,"使用方法: shop buy <item #> <amount>\n";
                        }
                } else {
                        print        "无效的参数 'shop' (Shop Command)\n"
                               	,"使用方法: shop [<open | close | list | item | quit>]\n"
                               	,"          shop [<enter | buy>] [<shop #> | <item #> <amount>]\n";
                }

        } elsif ($switch eq "map") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
       	        ($map_string) = $map_name =~ /([\s\S]*)\.gat/;
		if ($arg1 eq "") {
	        	my @array;
                	printc("nyn", "--------", "地图传送点信息", "--------\n");
			print "位置: $maps_lut{$map_string.'.rsw'}($map_string) ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n";
        	        printc("w", "#   位置      地图         名称\n");
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
                        print        "无效的参数 'map' (Map Info - Lock/Save)\n"
                               	,"使用方法: map [<save | lock>]\n";
	        }	

        } elsif ($switch eq "ver") {
                printc("yw", "<系统> ", $versionText);

        } elsif ($switch eq "base") {
                unshift @ai_seq, "sellAuto";
                unshift @ai_seq_args, {};

        } elsif ($switch eq "heal") {
                unshift @ai_seq, "healAuto";
                unshift @ai_seq_args, {};

#####
        } elsif ($switch eq "time" && $vipLevel >= 2) {
              	printc("nyn", "----------", "BOSS时间表", "----------\n");
              	printc("w", "BOSS                  死亡时间\n");
                my %stuff;
                foreach (keys %mvptime) {
                        next if ($_ eq "");
                        $stuff{$mvptime{$_}} = $_;
                }
                foreach (sort (keys %stuff)) {
                        print sprintf("%-20s  %8s\n", $stuff{$_}, getFormattedTime(int($_)));
                }
              	print "------------------------------\n";
                printc("wy", "目标 ", "$mvp{'now_monster'}{'name'}\n");
                printc("wnwn", "现时 ", getFormattedTime(int(time)),  "    剩余 ", getFormattedTime(int($mvp{'now_monster'}{'end_time'} - time))."\n");
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
                                $playTime_string = $w_hour."小时 ".$w_min."分 ".$w_sec."秒";
                                $levelTime_string = $n_hour."小时 ".$n_min."分 ".$n_sec."秒";
                                $exp{'base'}{'back'} = 0 if ($exp{'base'}{'back'} eq "");
                                $exp{'base'}{'dead'} = 0 if ($exp{'base'}{'dead'} eq "");
                                $exp{'base'}{'disconnect'} = 0 if ($exp{'base'}{'disconnect'} eq "");
                                $totalBaseExp_string = $totalBaseExp." (".(int($totalBaseExp/$chars[$config{'char'}]{'exp_max'}*10000)/100)."%)";
                                $totalJobExp_string = $totalJobExp." (".(int($totalJobExp/$chars[$config{'char'}]{'exp_job_max'}*10000)/100)."%)";
                                $bExpPerHour_string = $bExpPerHour." (".(int($bExpPerHour/$chars[$config{'char'}]{'exp_max'}*10000)/100)."%)";
                                $jExpPerHour_string = $jExpPerHour." (".(int($jExpPerHour/$chars[$config{'char'}]{'exp_job_max'}*10000)/100)."%)";
                                print "-------------------------------------------------------------------------\n";
                                printc("y", "在线时间           升级需要              战斗时间 休息时间 回城 死亡 掉线\n");

                                $~ = "EXPBLIST";
                                format EXPBLIST =
@<<<<<<<<<<<<<<<<  @<<<<<<<<<<<<<<<<<    @>>>>>>> @>>>>>>> @>>> @>>> @>>>
$playTime_string $levelTime_string $attack_string $sit_string $exp{'base'}{'back'} $exp{'base'}{'dead'} $exp{'base'}{'disconnect'}
.
                                write;
                                print "-------------------------------------------------------------------------\n";
                               printc("c", "共获得BASE经验     共获得JOB经验         每小时BASE经验     每小时JOB经验   \n");
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
                                printc("w", "消灭怪物           数量  平均时间  BASE效率   JOB效率  每秒伤害  每秒损失\n");
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
                        printc("w", "使用物品           数量                   获得物品           数量    重要\n");
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
                        print "无效的参数 'exp' (Exp Calculation)\n";
                        print "使用方法: exp [e|m|i|a|reset]\n";
                }
        # ICE End

        } elsif ($switch eq "exall") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($arg1 eq "1" || $arg1 eq "0"){
                        sendIgnoreAll(\$remote_socket, !$arg1);
                } else {
                        print        "无效的参数 'exall' (Ignore/Unignore Everyone)\n"
                        	,"使用方法: exall <flag>\n";
                }

#####
        } elsif ($switch eq "ar") {
                @arg = split / /, $input;
                if ($arg[1] eq "stop") {
                        aiRemove("refineAuto");
                        printc("yr", "<系统> ", "停止自动精练\n");
                } elsif ($arg[1] eq "" || $arg[2] < 1 || $arg[2] > 10) {
                        print        "无效的参数 'ar' (Auto Refine)\n"
	                        ,"使用方法: ar <all|#> <1-10>\n";
                } elsif ($arg[1] eq "all") {
                        $arg[2] = int($arg[2]);
                        ai_refine($arg[1], $arg[2]);
                        printc("yw", "<系统> ", "开始自动精练  物品: 全部  级别: $arg[2]\n");
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg[1]]}) {
                        print        "命令错误 'ar' (Auto Refine)\n"
                                ,"随身物品 $arg[1] 不存在.\n";
                } elsif ($chars[$config{'char'}]{'inventory'}[$arg[1]]{'type_equip'} == 0) {
                        print        "命令错误 'ar' (Auto Refine)\n"
                                ,"随身物品 $arg[1] 不能精练.\n";
                } else {
                        $arg[2] = int($arg[2]);
                        ai_refine($items_lut{$chars[$config{'char'}]{'inventory'}[$arg[1]]{'nameID'}}, $arg[2]);
                        printc("yw", "<系统> ", "开始自动精练  物品: $items_lut{$chars[$config{'char'}]{'inventory'}[$arg[1]]{'nameID'}}  级别: $arg[2]\n");
                }

#####
        } elsif ($switch eq "ye") {
                if (!$yelloweasy) {
                        $yelloweasy = 1;
                        printc("yy", "<系统> ", "打开Yellow Easy通讯\n");
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
                        printc("yy", "<系统> ", "关闭Yellow Easy通讯\n");
                        close($window_socket) if ($window_socket);
                }

        } elsif ($switch eq "tp") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($arg1 eq "1"){
                        useTeleport(1);
                        printc("ww", "<瞬移> ", "随机瞬间移动\n");
                } elsif ($arg1 eq "2"){
                        useTeleport(2);
                        printc("ww", "<瞬移> ", "返回记录地点\n");
                } else {
                        print        "无效的参数 'tp' (Teleport)\n"
	                        ,"使用方法: tp <1 | 2>\n";
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
                        print "清空AI队列\n";
                } elsif ($arg1 eq "d" || $arg1 eq "delete") {
                        shift @ai_seq;
                        shift @ai_seq_args;
                        print "删除当前执行的AI\n";
                } elsif ($arg1 eq "p" || $arg1 eq "pause") {
                        undef $AI;
                        $AI_forcedOff = 1;
                        ai_setSuspend(0);
                        print "暂停执行AI\n";
                } elsif ($arg1 eq "r" || $arg1 eq "resume") {
                        $AI = 1;
                        undef $AI_forcedOff;
                        print "开启执行AI\n";
                } else {
                        print        "无效的参数 'ai' (AI View and Control)\n"
                        	,"使用方法: ai [<c | clear | d | delete | p | pause | r | resume>]\n";
                }

        } elsif ($switch eq "mode") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		if ($arg1 eq "") {
			print "当前显示级别 $config{'mode'}\n";
                } elsif ($arg1 eq "0" || $arg1 eq "1" || $arg1 eq "2" || $arg1 eq "3"){
                        $config{'mode'} = $arg1;
                        configModify("mode", $arg1);
			print "显示级别更改为 $config{'mode'}\n";
                } else {
                        print        "无效的参数 'mode' (Display Mode)\n"
	                        ,"使用方法: mode [<level # (0-3)>]\n";
                }

        } elsif ($switch eq "help") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
	        dynParseFiles("data/commandsdescriptions.txt", \%commandsDesc_lut, \&parseRODescLUT3);
                if ($arg1 ne "" && %{$commandsDesc_lut{$arg1}}) {
                        printc("nyn", "-----------", "命令说明", "-----------\n");
                        printc("w", "命令: $arg1 - $commandsDesc_lut{$arg1}{'name'}\n");
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
	                        printc("nyn", "-----------", "命令列表", "-----------\n");
       	                	for (my $i=0; $i < @array; $i++) {
	                        	print sprintf("%-16s - %-60s\n",$array[$i],$commandsDesc_lut{$array[$i]}{'name'});
		                }
	                        print "------------------------------\n";
	                        print "有关某个命令的详细信息，请键入 help 命令名\n";
		        } else {
	                        print        "命令错误 'help' (Help of Command)\n"
        	                        ,"没有任何命令名称或描述匹配 $arg[1], 请输入 'help' 获取命令列表\n";
	                }
                } else {
                        printc("nyn", "-----------", "命令列表", "-----------\n");
                	foreach (sort (keys %commandsDesc_lut)) {
                		next if ($_ eq "");
	                        print sprintf("%-16s - %-60s\n",$_,$commandsDesc_lut{$_}{'name'});
	                }
                        print "------------------------------\n";
                        print "有关某个命令的详细信息，请键入 'help 命令名'\n";
                }
                undef %commandsDesc_lut;

        } elsif ($switch eq "vip"  && $vipLevel >= 3) {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
                if (($arg1 ne "1" && $arg1 ne "2") || $arg2 eq "") {
                	print        "无效的参数 'vip' (VIP Password Calculation)\n"
                		,"使用方法: vip <level> <AID>\n";
                } else {
                	my $key = getVipPassword($arg1, $arg2);
                	print "Level: $arg1 | AID: $arg2 | Password: $key\n";
                }
                
        } elsif ($switch eq "aid") {
                printc("nyn", "-----------", "AID 列表", "-----------\n");
                printc("w", "#   位置      距离 名称                                       AID\n");
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
                printc("y", "你的AID: $accountAID "."(".getHex($accountID).")\n");
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
                        print sprintf("  公会名称  : %-25s    经验     : %10d\n", $chars[$config{'char'}]{'guild'}{'name'}, $chars[$config{'char'}]{'guild'}{'exp'});
                        print sprintf("  公会等级  : %-25d    Next     : %10d\n", $chars[$config{'char'}]{'guild'}{'lv'}, $chars[$config{'char'}]{'guild'}{'next_exp'});
                        print sprintf("  会长名称  : %-25s    交纳点数 : %10d\n", $chars[$config{'char'}]{'guild'}{'master'}, $chars[$config{'char'}]{'guild'}{'offerPoint'});
                        print sprintf("  公会人数  : %3d/%-3d (Max: %d)\n", $chars[$config{'char'}]{'guild'}{'conMember'}, scalar(keys %{$chars[$config{'char'}]{'guild'}{'members'}}), $chars[$config{'char'}]{'guild'}{'maxMember'});
                        print sprintf("  平均等级  : %-3d\n", $chars[$config{'char'}]{'guild'}{'average'});
                        print sprintf("  管理领域  : %-25s    ID       : %-20s\n", $chars[$config{'char'}]{'guild'}{'castle'}, getHex($chars[$config{'char'}]{'guild'}{'ID'}));
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
                        print "----------------------------- 转移地图列表 ------------------------------\n";
                        printc("w", "编号 地图         地图名称                           IP地址          端口\n");
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
                        print "----------------------------- 转移地图列表 ------------------------------\n";
                        printc("w", "IP地址          端口  地图         地图名称                          转移\n");
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
                        printc("yw", "<系统> ", "正在转移到: $mapip_lut{$fly_list[$arg[1]]}{'name'}($fly_list[$arg[1]])\n");
                        sendFly($mapip_lut{$fly_list[$arg[1]]}{'ip'}, $mapip_lut{$fly_list[$arg[1]]}{'port'});
                } else {
                        print "无效的参数 'fly'\n","使用方法: fly [Map Name|ip] [ip_address] [port]\n";
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