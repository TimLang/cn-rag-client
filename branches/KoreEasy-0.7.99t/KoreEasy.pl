$version = "0.7.99t";
$beta = "Beta";
$versionText = "***KoreEasy $version $beta - Ragnarok Online - http://ke4u.aboutme.com***\n\n";

use Win32::Console;
$CONSOLE = new Win32::Console(STD_OUTPUT_HANDLE) || die "Could not init Console";
printLogo();

use Time::HiRes qw(time usleep);
use IO::Socket;
use Win32::API;
use Getopt::Long;

multiuser();

srand(time());

addParseFiles("$setupPath/config.txt", \%config, \&parseDataFile2);
load(\@parseFiles);

$config{'local_host'} = "localhost" if (!$config{'local_host'});

if ($LocalPort ne "") {
        $config{'local_port'} = $LocalPort;
}

$proto = getprotobyname('tcp');
$MAX_READ = 30000;

$remote_socket = IO::Socket::INET->new();
$server_socket = IO::Socket::INET->new(
                        Listen                => 5,
                        LocalAddr        => $config{'local_host'},
                        LocalPort        => $config{'local_port'},
                        Proto                => 'tcp',
                        Timeout                => 2,
                        Reuse                => 1);

printC("S0", "正在初始化本地连接 ($config{'local_host'}:$config{'local_port'})\n");

$input_pid = input_client();

print "\n";

addParseFiles("$setupPath/plus_control.txt", \%plus, \&parseDataFile2);
addParseFiles("$setupPath/mvp_control.txt", \%mvp, \&parseDataFile2);
addParseFiles("$setupPath/skill_control.txt", \%skill_control, \&parseDataFile2);
addParseFiles("$setupPath/npc_control.txt", \%npc_control, \&parseDataFile2);
addParseFiles("$setupPath/items_control.txt", \%items_control, \&parseItemsControl);
addParseFiles("$setupPath/mon_control.txt", \%mon_control, \&parseMonControl);
addParseFiles("$setupPath/pickup_control.txt", \%itemsPickup, \&parseDataFile_lc);
addParseFiles("$setupPath/shop_control.txt", \%shop, \&parseDataFile2);
addParseFiles("$setupPath/weapon_control.txt", \%swtichAuto, \&parseDataFile2);
addParseFiles("$setupPath/timeouts.txt", \%timeout, \&parseTimeouts);
addParseFiles("$setupPath/mvptime.txt", \%mvptime, \&parseDataFile2) if ($config{'mvpMode'});

addParseFiles("data/avoidlist.txt", \%avoidlist_rlut, \&parsePlusRLUT);
addParseFiles("data/airesponses.txt", \%airesponses, \&parseResponses);
addParseFiles("data/cards.txt", \%cards_lut, \&parseROLUT);
addParseFiles("data/cities.txt", \%cities_lut, \&parseROLUT);
addParseFiles("data/elements.txt", \%elements_lut, \&parseROLUT);
addParseFiles("data/emotions.txt", \%emotions_lut, \&parseDataFile2);
addParseFiles("data/equiptypes.txt", \%equipTypes_lut, \&parseDataFile2);
addParseFiles("data/importantitems.txt", \%importantItems_rlut, \&parsePlusRLUT);
addParseFiles("data/importantmonsters.txt", \%importantMonsters_rlut, \&parsePlusRLUT);
addParseFiles("data/items.txt", \%items_lut, \&parseROLUT);
addParseFiles("data/itemsdescriptions.txt", \%itemsDesc_lut, \&parseRODescLUT) if ($plus{'loadDescriptions'});
addParseFiles("data/itemslots.txt", \%itemSlots_lut, \&parseROSlotsLUT);
addParseFiles("data/itemtypes.txt", \%itemTypes_lut, \&parseDataFile2);
addParseFiles("data/jobs.txt", \%jobs_lut, \&parseDataFile2);
addParseFiles("data/maps.txt", \%maps_lut, \&parseROLUT);
addParseFiles("data/monsters.txt", \%monsters_lut, \&parseDataFile2);
addParseFiles("data/npcs.txt", \%npcs_lut, \&parseNPCs);
addParseFiles("data/overallauth.txt", \%overallAuth, \&parseDataFile);
addParseFiles("data/portals.txt", \%portals_lut, \&parsePortals);
addParseFiles("data/portalsLOS.txt", \%portals_los, \&parsePortalsLOS);
addParseFiles("data/responses.txt", \%responses, \&parseResponses);
addParseFiles("data/sex.txt", \%sex_lut, \&parseDataFile2);
addParseFiles("data/skills.txt", \%skills_lut, \&parseSkillsLUT);
addParseFiles("data/skills.txt", \%skillsID_lut, \&parseSkillsIDLUT);
addParseFiles("data/skills.txt", \%skills_rlut, \&parseSkillsReverseLUT_lc);
addParseFiles("data/skillsdescriptions.txt", \%skillsDesc_lut, \&parseRODescLUT) if ($plus{'loadDescriptions'});
addParseFiles("data/skillssp.txt", \%skillsSP_lut, \&parseSkillsSPLUT);
addParseFiles("data/skillsst.txt", \%skillsstID_lut, \&parseSkillsIDLUT);
addParseFiles("data/skillsst.txt", \%skillsst_rlut, \&parseSkillsReverseLUT_lc);
addParseFiles("data/mapserver.txt", \%mapserver_lut, \&parseROLUT);
addParseFiles("data/mapip.txt", \%mapip_lut, \&parseMapIP);
addParseFiles("data/indoors.txt", \%indoors_lut, \&parseROLUT);
addParseFiles("data/passivemon.txt", \%passivemon_lut, \&parseDataFile2);
addParseFiles("data/avoidaid.txt", \%aid_rlut, \&parseAidRLUT);
addParseFiles("data/msgstrings.txt", \%msgstrings_lut, \&parseMsgLUT);

load(\@parseFiles);

$mvpMonster = "1039,1251,1038,1157,1059,1147,1112,1272,1115,1086,1159,1190,1087,1046,1150";

if (!$config{'buildType'}) {
        $CalcPath_init = new Win32::API("Tools", "CalcPath_init", "PPNNPPN", "N");
        die "Could not locate Tools.dll" if (!$CalcPath_init);

        $CalcPath_pathStep = new Win32::API("Tools", "CalcPath_pathStep", "N", "N");
        die "Could not locate Tools.dll" if (!$CalcPath_pathStep);

        $CalcPath_destroy = new Win32::API("Tools", "CalcPath_destroy", "N", "V");
        die "Could not locate Tools.dll" if (!$CalcPath_destroy);
} elsif ($config{'buildType'} == 1) {
        $ToolsLib = new C::DynaLib("./Tools.so");

        $CalcPath_init = $ToolsLib->DeclareSub("CalcPath_init", "L", "p","p","L","L","p","p","L");
        die "Could not locate Tools.so" if (!$CalcPath_init);

        $CalcPath_pathStep = $ToolsLib->DeclareSub("CalcPath_pathStep", "L", "L");
        die "Could not locate Tools.so" if (!$CalcPath_pathStep);

        $CalcPath_destroy = $ToolsLib->DeclareSub("CalcPath_destroy", "", "L");
        die "Could not locate Tools.so" if (!$CalcPath_destroy);
}

if ($config{'adminPassword'} eq 'x' x 10 || !$config{'adminPassword'}) {
        print "\n";
        printC("S0", "自动生成管理员密码\n");
        configModify("adminPassword", vocalString(8));
}

###COMPILE PORTALS###

print "\n";
printC("S0", "正在检查新的地图传送点...");
compilePortals_check(\$found);

if ($found) {
        print "发现新的地图传送点\n";
        printC("S0W", "现在进行编译吗？ (y/n)\n");
        printC("S0", "将在$timeout{'compilePortals_auto'}{'timeout'}秒后自动进行编译...");
        $timeout{'compilePortals_auto'}{'time'} = time;
        undef $msg;
        while (!timeOut(\%{$timeout{'compilePortals_auto'}})) {
                if (dataWaiting(\$input_socket)) {
                        $input_socket->recv($msg, $MAX_READ);
                }
                last if $msg;
        }
        if ($msg =~ /y/ || $msg eq "") {
                print "完成\n\n";
                compilePortals();
        } else {
                print "跳过\n\n";
        }
} else {
        print "完成\n";
}


if (!$config{'username'}) {
        printC("S0W", "请输入用户名: \n");
        $input_socket->recv($msg, $MAX_READ);
        $config{'username'} = $msg;
        writeDataFileIntact("$setupPath/config.txt", \%config);

}
if (!$config{'password'}) {
        printC("S0W", "请输入密码: \n");
        $input_socket->recv($msg, $MAX_READ);
        $config{'password'} = $msg;
        writeDataFileIntact("$setupPath/config.txt", \%config);
}
if ($config{'master'} eq "") {
        $i = 0;
        $~ = "MASTERS";
        print "--------- Master Servers ----------\n";
        print "#         Name\n";
        while ($config{"master_name_$i"} ne "") {
                format MASTERS =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i  $config{"master_name_$i"}
.
                write;
                $i++;
        }
        print "-------------------------------\n";
        printC("S0W", "请选择主服务器: \n");
        $input_socket->recv($msg, $MAX_READ);
        $config{'master'} = $msg;
        writeDataFileIntact("$setupPath/config.txt", \%config);
}

$conState = 1;
undef $msg;
$KoreStartTime = time;

while ($quit != 1) {
        usleep($config{'sleepTime'});
        if (dataWaiting(\$input_socket)) {
                $stop = 1;
                $input_socket->recv($input, $MAX_READ);
                parseInput($input);
        } elsif (dataWaiting(\$remote_socket)) {
                $remote_socket->recv($new, $MAX_READ);
                $msg .= $new;
                $msg_length = length($msg);
                while ($msg ne "") {
                        $msg = parseMsg($msg);
                        last if ($msg_length == length($msg));
                        $msg_length = length($msg);
                }
        } elsif (dataWaiting(\$windows_socket)) {
                $stop = 1;
                $windows_socket->recv($windows, $MAX_READ);
                print "recived: $windows\n" if ($config{'debug'});
                parseInput($windows);
        }
        $ai_cmdQue_shift = 0;
        do {
                AI(\%{$ai_cmdQue[$ai_cmdQue_shift]}) if ($conState == 5 && timeOut(\%{$timeout{'ai'}}) && $remote_socket && $remote_socket->connected());
                undef %{$ai_cmdQue[$ai_cmdQue_shift++]};
                $ai_cmdQue-- if ($ai_cmdQue > 0);
        } while ($ai_cmdQue > 0);
        checkConnection();
}
close($server_socket);
close($input_socket);
kill 9, $input_pid;
killConnection(\$remote_socket);
printC("S0", "退出游戏\n");
printC("X0Y", $versionText);
exit;

#######################################
#INITIALIZE VARIABLES
#######################################

sub initConnectVars {
        initMapChangeVars();
        undef @{$chars[$config{'char'}]{'inventory'}};
        undef %{$chars[$config{'char'}]{'skills'}};
        undef @skillsID;
}

sub initMapChangeVars {
        @portalsID_old = @portalsID;
        %portals_old = %portals;
        %{$chars_old[$config{'char'}]{'pos_to'}} = %{$chars[$config{'char'}]{'pos_to'}};
        undef $chars[$config{'char'}]{'sitting'};
        undef $chars[$config{'char'}]{'dead'};
        undef $chars[$config{'char'}]{'warpTo'};
        $timeout{'play'}{'time'} = time;
        undef $timeout{'ai_sync'}{'time'};
        $timeout{'ai_sit_idle'}{'time'} = time;
        $timeout{'ai_teleport_idle'}{'time'} = time;
        $timeout{'ai_teleport_search'}{'time'} = time;
        $timeout{'ai_teleport_search_wait'}{'time'} = time;
        $timeout{'ai_teleport_safe_force'}{'time'} = time;
        undef %incomingDeal;
        undef %outgoingDeal;
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
        undef %incomingParty;
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
        # ICE End
        undef $ai_v{'move_failed'};
        undef $chars[$config{'char'}]{'shopOpened'};
        $timeout{'ai_shopAuto'}{'time'} = time;
        undef $timeout{'ai_attack'}{'time'};
        undef $timeout{'ai_attack_auto'}{'time'};
        undef $timeout{'ai_skill_use'}{'time'};
        undef $timeout{'ai_item_use_auto'}{'time'};
}



#######################################
#######################################
#Check Connection
#######################################
#######################################



sub checkConnection {

        if ($conState == 1 && !($remote_socket && $remote_socket->connected()) && timeOut(\%{$timeout_ex{'master'}}) && !$conState_tries) {
                printC("S0", "正在与主服务器建立连接...\n");
                $conState_tries++;
                undef $msg;
                connection(\$remote_socket, $config{"master_host_$config{'master'}"},$config{"master_port_$config{'master'}"});
                sendMasterLogin(\$remote_socket, $config{'username'}, $config{'password'});
                $timeout{'master'}{'time'} = time;

        } elsif ($conState == 1 && timeOut(\%{$timeout{'master'}}) && timeOut(\%{$timeout_ex{'master'}})) {
                printC("S1R", "与主服务器建立连接超时，重新连接...\n");
                killConnection(\$remote_socket);
                undef $conState_tries;

        } elsif ($conState == 2 && !($remote_socket && $remote_socket->connected()) && ($config{'server'} ne "" || $config{'charServer_host'}) && !$conState_tries) {
                printC("S0", "正在与身份验证服务器建立连接...\n");
                $conState_tries++;
                if ($config{'charServer_host'}) {
                        connection(\$remote_socket, $config{'charServer_host'},$config{'charServer_port'});
                } else {
                        connection(\$remote_socket, $servers[$config{'server'}]{'ip'},$servers[$config{'server'}]{'port'});
                }
                sendGameLogin(\$remote_socket, $accountID, $sessionID, $accountSex);
                $timeout{'gamelogin'}{'time'} = time;

        } elsif ($conState == 2 && timeOut(\%{$timeout{'gamelogin'}}) && ($config{'server'} ne "" || $config{'charServer_host'})) {
                printC("S1R", "与身份验证服务器连接超时，重新连接...\n");
                killConnection(\$remote_socket);
                undef $conState_tries;
                $conState = 1;

        } elsif ($conState == 3 && timeOut(\%{$timeout{'gamelogin'}}) && $config{'char'} ne "") {
                printC("S1R", "与身份验证服务器连接超时，重新连接...\n");
                killConnection(\$remote_socket);
                $conState = 1;
                undef $conState_tries;

        } elsif ($conState == 4 && !($remote_socket && $remote_socket->connected()) && !$conState_tries) {
                printC("S0", "正在登录到地图服务器...\n");
                $conState_tries++;
                initConnectVars();
                connection(\$remote_socket, $map_ip, $map_port);
                sendMapLogin(\$remote_socket, $accountID, $charID, $sessionID, $accountSex2);
                $timeout{'maplogin'}{'time'} = time;

        } elsif ($conState == 4 && timeOut(\%{$timeout{'maplogin'}})) {
                printC("S1R", "与地图服务器连接超时，重新连接...\n");
                killConnection(\$remote_socket);
                $conState = 1;
                undef $conState_tries;

        } elsif ($conState == 5 && !($remote_socket && $remote_socket->connected())) {
                $conState = 1;
                undef $conState_tries;

        } elsif ($conState == 5 && timeOut(\%{$timeout{'play'}})) {
                $exp{'base'}{'disconnect'}++;
                printC("S1R", "与服务器断线\n");
                chatLog("x", "与服务器断线 AI: @ai_seq\n");
                killConnection(\$remote_socket);
                sleep(10);
                $conState = 1;
                undef $conState_tries;
        }
        if ($config{'autoRestart'} && time - $KoreStartTime > $config{'autoRestart'}) {
                $conState = 1;
                undef $conState_tries;
                undef %ai_v;
                undef @ai_seq;
                undef @ai_seq_args;
                $KoreStartTime = time;
                print "\n";
                printC("S0Y", "重新启动\n\n");
                killConnection(\$remote_socket);
        }
}


#######################################
#PARSE INPUT
#######################################


sub parseInput {
        my $input = shift;
        my ($arg1, $arg2, $switch);
        print "Echo: $input\n" if ($config{'debug'} >= 2);
        ($switch) = $input =~ /^(\w*)/;

#Check if in special state

        if ($conState == 2 && $waitingForInput) {
                $config{'server'} = $input;
                $waitingForInput = 0;
                writeDataFileIntact("$setupPath/config.txt", \%config);
        } elsif ($conState == 3 && $waitingForInput) {
                $config{'char'} = $input;
                $waitingForInput = 0;
                writeDataFileIntact("$setupPath/config.txt", \%config);
                sendCharLogin(\$remote_socket, $config{'char'});
                $timeout{'gamelogin'}{'time'} = time;


#Parse command...ugh

        } elsif ($switch eq "a") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                ($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)/;
                if ($arg1 =~ /^\d+$/ && $monstersID[$arg1] eq "") {
                        print        "Error in function 'a' (Attack Monster)\n"
                                ,"Monster $arg1 does not exist.\n";
                } elsif ($arg1 =~ /^\d+$/) {
                        attack($monstersID[$arg1]);

                } elsif ($arg1 eq "no") {
                        configModify("attackAuto", 1);

                } elsif ($arg1 eq "yes") {
                        configModify("attackAuto", 2);

                } else {
                        print        "Syntax Error in function 'a' (Attack Monster)\n"
                                ,"Usage: attack <monster # | no | yes >\n";
                }

        } elsif ($switch eq "auth") {
                ($arg1, $arg2) = $input =~ /^[\s\S]*? ([\s\S]*) ([\s\S]*?)$/;
                if ($arg1 eq "" || ($arg2 ne "1" && $arg2 ne "0")) {
                        print        "Syntax Error in function 'auth' (Overall Authorize)\n"
                                ,"Usage: auth <username> <flag>\n";
                } else {
                        auth($arg1, $arg2);
                }

        } elsif ($switch eq "bestow") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($currentChatRoom eq "") {
                        print        "Error in function 'bestow' (Bestow Admin in Chat)\n"
                                ,"You are not in a Chat Room.\n";
                } elsif ($arg1 eq "") {
                        print        "Syntax Error in function 'bestow' (Bestow Admin in Chat)\n"
                                ,"Usage: bestow <user #>\n";
                } elsif ($currentChatRoomUsers[$arg1] eq "") {
                        print        "Error in function 'bestow' (Bestow Admin in Chat)\n"
                                ,"Chat Room User $arg1 doesn't exist\n";
                } else {
                        sendChatRoomBestow(\$remote_socket, $currentChatRoomUsers[$arg1]);
                }

        } elsif ($switch eq "buy") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
                if ($arg1 eq "") {
                        print        "Syntax Error in function 'buy' (Buy Store Item)\n"
                                ,"Usage: buy <item #> [<amount>]\n";
                } elsif ($storeList[$arg1] eq "") {
                        print        "Error in function 'buy' (Buy Store Item)\n"
                                ,"Store Item $arg1 does not exist.\n";
                } else {
                        if ($arg2 <= 0) {
                                $arg2 = 1;
                        }
                        sendBuy(\$remote_socket, $storeList[$arg1]{'nameID'}, $arg2);
                }

        } elsif ($switch eq "c") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($arg1 eq "") {
                        print        "Syntax Error in function 'c' (Chat)\n"
                                ,"Usage: c <message>\n";
                } else {
                        sendMessage(\$remote_socket, "c", $arg1);
                }

        #Cart command - chobit andy 20030101
        } elsif ($switch eq "cart") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                ($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
                ($arg3) = $input =~ /^[\s\S]*? \w+ \d+ (\d+)/;
                if ($arg1 eq "") {
                        $~ = "CARTLIST";
                        print "-------------Cart--------------\n";
                        print "#  Name\n";
                        undef @non_equipment;
                        undef @equipment;
                        for ($i=0; $i < @{$cart{'inventory'}}; $i++) {
                                next if (!%{$cart{'inventory'}[$i]});
                                if ($cart{'inventory'}[$i]{'type_equip'} != 0) {
                                        push @equipment, $i;
                                } else {
                                        push @non_equipment, $i;
                                }
                        }
                                format CARTLIST =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$index $display
.
                        print        "-------------Cart-------------\n";
                        print        "-- Non-Equipment --\n";

                        for ($i = 0; $i < @non_equipment; $i++) {
                                $display = $cart{'inventory'}[$non_equipment[$i]]{'name'};
                                $display .= " x $cart{'inventory'}[$non_equipment[$i]]{'amount'}";
                                $index = $non_equipment[$i];
                                write;
                        }

                        print        "-- Equipment --\n";
                        for ($i = 0; $i < @equipment; $i++) {
                                $display = $cart{'inventory'}[$equipment[$i]]{'name'};
                                if($cart{'inventory'}[$equipment[$i]]{'enchant'} > 0) {
                                        $display .= " [+$cart{'inventory'}[$equipment[$i]]{'enchant'}]";
                                }
                                if($cart{'inventory'}[$equipment[$i]]{'elementName'}) {
                                        $display .= " [$cart{'inventory'}[$equipment[$i]]{'elementName'}]";
                                }
                                if($cart{'inventory'}[$equipment[$i]]{'slotName'}) {
                                        $display .= " [$cart{'inventory'}[$equipment[$i]]{'slotName'}]";
                                }
                                $index = $equipment[$i];
                                write;
                        }
                        print "\nCapacity: " . int($cart{'items'}) . "/" . int($cart{'items_max'}) . "  Weight: " . int($cart{'weight'}) . "/" . int($cart{'weight_max'}) . "\n";
                        print "-------------------------------\n";

                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'inventory'}[$arg2] eq "") {
                        print        "Error in function 'cart add' (Add Item to Cart)\n"
                                ,"Inventory Item $arg2 does not exist.\n";
                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/) {
                        if (!$arg3 || $arg3 > $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'}) {
                                $arg3 = $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'};
                        }
                        sendCartAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg2]{'index'}, $arg3);
                } elsif ($arg1 eq "add" && $arg2 eq "") {
                        print        "Syntax Error in function 'cart add' (Add Item to Cart)\n"
                                ,"Usage: cart add <item #>\n";
                } elsif ($arg1 eq "get" && $arg2 =~ /\d+/ && !%{$cart{'inventory'}[$arg2]}) {
                        print        "Error in function 'cart get' (Get Item from Cart)\n"
                                ,"Cart Item $arg2 does not exist.\n";
                } elsif ($arg1 eq "get" && $arg2 =~ /\d+/) {
                        if (!$arg3 || $arg3 > $cart{'inventory'}[$arg2]{'amount'}) {
                                $arg3 = $cart{'inventory'}[$arg2]{'amount'};
                        }
                        sendCartGet(\$remote_socket, $arg2, $arg3);
                } elsif ($arg1 eq "get" && $arg2 eq "") {
                        print        "Syntax Error in function 'cart get' (Get Item from Cart)\n"
                                ,"Usage: cart get <cart item #>\n";
                }


        } elsif ($switch eq "chat") {
                ($replace, $title) = $input =~ /(^[\s\S]*? \"([\s\S]*?)\" ?)/;
                $qm = quotemeta $replace;
                $input =~ s/$qm//;
                @arg = split / /, $input;
                if ($title eq "") {
                        print        "Syntax Error in function 'chat' (Create Chat Room)\n"
                                ,qq~Usage: chat "<title>" [<limit #> <public flag> <password>]\n~;
                } elsif ($currentChatRoom ne "") {
                        print        "Error in function 'chat' (Create Chat Room)\n"
                                ,"You are already in a chat room.\n";
                } else {
                        if ($arg[0] eq "") {
                                $arg[0] = 20;
                        }
                        if ($arg[1] eq "") {
                                $arg[1] = 1;
                        }
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
                        print        "Syntax Error in function 'chatmod' (Modify Chat Room)\n"
                                ,qq~Usage: chatmod "<title>" [<limit #> <public flag> <password>]\n~;
                } else {
                        if ($arg[0] eq "") {
                                $arg[0] = 20;
                        }
                        if ($arg[1] eq "") {
                                $arg[1] = 1;
                        }
                        sendChatRoomChange(\$remote_socket, $title, $arg[0], $arg[1], $arg[2]);
                }

        } elsif ($switch eq "cl") {
                chatLog_clear();
                print qq~Chat log cleared.\n~;

        } elsif ($switch eq "conf") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                ($arg2) = $input =~ /^[\s\S]*? \w+ ([\s\S]+)$/;
                @{$ai_v{'temp'}{'conf'}} = keys %config;
                if ($arg1 eq "") {
                        print        "Syntax Error in function 'conf' (Config Modify)\n"
                                ,"Usage: conf <variable> [<value>]\n";
                } elsif (binFind(\@{$ai_v{'temp'}{'conf'}}, $arg1) eq "") {
                        print "Config variable $arg1 doesn't exist\n";
                } elsif ($arg2 eq "value") {
                        print "Config '$arg1' is $config{$arg1}\n";
                } else {
                        configModify($arg1, $arg2);
                }

        } elsif ($switch eq "cri") {
                if ($currentChatRoom eq "") {
                        print "There is no chat room info - you are not in a chat room\n";
                } else {
                        $~ = "CRI";
                        print        "-----------Chat Room Info-----------\n"
                                ,"Title                     Users   Public/Private\n";
                        $public_string = ($chatRooms{$currentChatRoom}{'public'}) ? "Public" : "Private";
                        $limit_string = $chatRooms{$currentChatRoom}{'num_users'}."/".$chatRooms{$currentChatRoom}{'limit'};
                        format CRI =
@<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<< @<<<<<<<<<
$chatRooms{$currentChatRoom}{'title'} $limit_string $public_string
.
                        write;
                        $~ = "CRIUSERS";
                        print        "-- Users --\n";
                        for ($i = 0; $i < @currentChatRoomUsers; $i++) {
                                next if ($currentChatRoomUsers[$i] eq "");
                                $user_string = $currentChatRoomUsers[$i];
                                $admin_string = ($chatRooms{$currentChatRoom}{'users'}{$currentChatRoomUsers[$i]} > 1) ? "(Admin)" : "";
                                format CRIUSERS =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<
$i  $user_string               $admin_string
.
                                write;
                        }
                        print "------------------------------------\n";
                }

        } elsif ($switch eq "crl") {
                $~ = "CRLIST";
                print        "-----------Chat Room List-----------\n"
                        ,"#   Title                     Owner                Users   Public/Private\n";
                for ($i = 0; $i < @chatRoomsID; $i++) {
                        next if ($chatRoomsID[$i] eq "");
                        $owner_string = ($chatRooms{$chatRoomsID[$i]}{'ownerID'} ne $accountID) ? $players{$chatRooms{$chatRoomsID[$i]}{'ownerID'}}{'name'} : $chars[$config{'char'}]{'name'};
                        $public_string = ($chatRooms{$chatRoomsID[$i]}{'public'}) ? "Public" : "Private";
                        $limit_string = $chatRooms{$chatRoomsID[$i]}{'num_users'}."/".$chatRooms{$chatRoomsID[$i]}{'limit'};
                        format CRLIST =
@<< @<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<          @<<<<<< @<<<<<<<<<
$i  $chatRooms{$chatRoomsID[$i]}{'title'}          $owner_string $limit_string $public_string
.
                        write;
                }
                print "------------------------------------\n";


        } elsif ($switch eq "deal") {
                @arg = split / /, $input;
                shift @arg;
                if (%currentDeal && $arg[0] =~ /\d+/) {
                        print        "Error in function 'deal' (Deal a Player)\n"
                                ,"You are already in a deal\n";
                } elsif (%incomingDeal && $arg[0] =~ /\d+/) {
                        print        "Error in function 'deal' (Deal a Player)\n"
                                ,"You must first cancel the incoming deal\n";
                } elsif ($arg[0] =~ /\d+/ && !$playersID[$arg[0]]) {
                        print        "Error in function 'deal' (Deal a Player)\n"
                                ,"Player $arg[0] does not exist\n";
                } elsif ($arg[0] =~ /\d+/) {
                        $outgoingDeal{'ID'} = $playersID[$arg[0]];
                        sendDeal(\$remote_socket, $playersID[$arg[0]]);


                } elsif ($arg[0] eq "no" && !%incomingDeal && !%outgoingDeal && !%currentDeal) {
                        print        "Error in function 'deal' (Deal a Player)\n"
                                ,"There is no incoming/current deal to cancel\n";
                } elsif ($arg[0] eq "no" && (%incomingDeal || %outgoingDeal)) {
                        sendDealCancel(\$remote_socket);
                } elsif ($arg[0] eq "no" && %currentDeal) {
                        sendCurrentDealCancel(\$remote_socket);


                } elsif ($arg[0] eq "" && !%incomingDeal && !%currentDeal) {
                        print        "Error in function 'deal' (Deal a Player)\n"
                                ,"There is no deal to accept\n";
                } elsif ($arg[0] eq "" && $currentDeal{'you_finalize'} && !$currentDeal{'other_finalize'}) {
                        print        "Error in function 'deal' (Deal a Player)\n"
                                ,"Cannot make the trade - $currentDeal{'name'} has not finalized\n";
                } elsif ($arg[0] eq "" && $currentDeal{'final'}) {
                        print        "Error in function 'deal' (Deal a Player)\n"
                                ,"You already accepted the final deal\n";
                } elsif ($arg[0] eq "" && %incomingDeal) {
                        sendDealAccept(\$remote_socket);
                } elsif ($arg[0] eq "" && $currentDeal{'you_finalize'} && $currentDeal{'other_finalize'}) {
                        sendDealTrade(\$remote_socket);
                        $currentDeal{'final'} = 1;
                        print "You accepted the final Deal\n";
                } elsif ($arg[0] eq "" && %currentDeal) {
                        sendDealAddItem(\$remote_socket, 0, $currentDeal{'you_zenny'});
                        sendDealFinalize(\$remote_socket);


                } elsif ($arg[0] eq "add" && !%currentDeal) {
                        print        "Error in function 'deal_add' (Add Item to Deal)\n"
                                ,"No deal in progress\n";
                } elsif ($arg[0] eq "add" && $currentDeal{'you_finalize'}) {
                        print        "Error in function 'deal_add' (Add Item to Deal)\n"
                                ,"Can't add any Items - You already finalized the deal\n";
                } elsif ($arg[0] eq "add" && $arg[1] =~ /\d+/ && !%{$chars[$config{'char'}]{'inventory'}[$arg[1]]}) {
                        print        "Error in function 'deal_add' (Add Item to Deal)\n"
                                ,"Inventory Item $arg[1] does not exist.\n";
                } elsif ($arg[0] eq "add" && $arg[2] && $arg[2] !~ /\d+/) {
                        print        "Error in function 'deal_add' (Add Item to Deal)\n"
                                ,"Amount must either be a number, or not specified.\n";
                } elsif ($arg[0] eq "add" && $arg[1] =~ /\d+/) {
                        if (scalar(keys %{$currentDeal{'you'}}) < 10) {
                                if (!$arg[2] || $arg[2] > $chars[$config{'char'}]{'inventory'}[$arg[1]]{'amount'}) {
                                        $arg[2] = $chars[$config{'char'}]{'inventory'}[$arg[1]]{'amount'};
                                }
                                $currentDeal{'lastItemAmount'} = $arg[2];
                                sendDealAddItem(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg[1]]{'index'}, $arg[2]);
                        } else {
                                print "You can't add any more items to the deal\n";
                        }
                } elsif ($arg[0] eq "add" && $arg[1] eq "z") {
                        if (!$arg[2] || $arg[2] > $chars[$config{'char'}]{'zenny'}) {
                                $arg[2] = $chars[$config{'char'}]{'zenny'};
                        }
                        $currentDeal{'you_zenny'} = $arg[2];
                        print "You put forward $arg[2] z to Deal\n";

                } else {
                        print        "Syntax Error in function 'deal' (Deal a player)\n"
                                ,"Usage: deal [<Player # | no | add>] [<item #>] [<amount>]\n";
                }

        } elsif ($switch eq "dl") {
                if (!%currentDeal) {
                        print "There is no deal list - You are not in a deal\n";

                } else {
                        print        "-----------Current Deal-----------\n";
                        $other_string = $currentDeal{'name'};
                        $you_string = "You";
                        if ($currentDeal{'other_finalize'}) {
                                $other_string .= " - Finalized";
                        }
                        if ($currentDeal{'you_finalize'}) {
                                $you_string .= " - Finalized";
                        }

                        $~ = "PREDLIST";
                        format PREDLIST =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<   @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$you_string                      $other_string
.
                        write;
                        $~ = "DLIST";
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
                                format DLIST =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<   @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$display                         $display2
.
                                write;
                        }
                        $you_string = ($currentDeal{'you_zenny'} ne "") ? $currentDeal{'you_zenny'} : 0;
                        $other_string = ($currentDeal{'other_zenny'} ne "") ? $currentDeal{'other_zenny'} : 0;
                        $~ = "DLISTSUF";
                        format DLISTSUF =
Zenny: @<<<<<<<<<<<<<            Zenny: @<<<<<<<<<<<<<
$you_string                      $other_string
.
                        write;
                        print "----------------------------------\n";
                }


        } elsif ($switch eq "drop") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
                if ($arg1 eq "") {
                        print        "Syntax Error in function 'drop' (Drop Inventory Item)\n"
                                ,"Usage: drop <item #> [<amount>]\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "Error in function 'drop' (Drop Inventory Item)\n"
                                ,"Inventory Item $arg1 does not exist.\n";
                } else {
                        if (!$arg2 || $arg2 > $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'}) {
                                $arg2 = $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'};
                        }
                        sendDrop(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $arg2);
                }

        } elsif ($switch eq "dump") {
                dumpData($msg);
                quit();

        } elsif ($switch eq "e") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                if ($arg1 eq "" || $arg1 > 33 || $arg1 < 0) {
                        print        "Syntax Error in function 'e' (Emotion)\n"
                                ,"Usage: e <emotion # (0-33)>\n";
                } else {
                        sendEmotion(\$remote_socket, $arg1);
                }

        } elsif ($switch eq "eq") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\w+)/;
                if ($arg1 eq "") {
                        print        "Syntax Error in function 'equip' (Equip Inventory Item)\n"
                                ,"Usage: equip <item #> [r]\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "Error in function 'equip' (Equip Inventory Item)\n"
                                ,"Inventory Item $arg1 does not exist.\n";
                } elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type_equip'} == 0 && $chars[$config{'char'}]{'inventory'}[$arg1]{'type'} != 10) {
                        print        "Error in function 'equip' (Equip Inventory Item)\n"
                                ,"Inventory Item $arg1 can't be equipped.\n";
                } else {
                        ai_sendEquip($arg1,$arg2);
                }

        } elsif ($switch eq "follow") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                if ($arg1 eq "") {
                        print        "Syntax Error in function 'follow' (Follow Player)\n"
                                ,"Usage: follow <player #>\n";
                } elsif ($arg1 eq "stop") {
                        aiRemove("follow");
                        configModify("follow", 0);
                } elsif ($playersID[$arg1] eq "") {
                        print        "Error in function 'follow' (Follow Player)\n"
                                ,"Player $arg1 does not exist.\n";
                } else {
                        ai_follow($players{$playersID[$arg1]}{'name'});
                        configModify("follow", 1);
                        configModify("followTarget", $players{$playersID[$arg1]}{'name'});
                }

        #Guild Chat - chobit andy 20030101
        } elsif ($switch eq "g") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($arg1 eq "") {
                        print "Syntax Error in function 'g' (Guild Chat)\n"
                                ,"Usage: g <message>\n";
                } else {
                        sendMessage(\$remote_socket, "g", $arg1);
                }
        } elsif ($switch eq "i") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                ($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
                if ($arg1 eq "" || $arg1 eq "eq" || $arg1 eq "u" || $arg1 eq "nu") {
                        undef @useable;
                        undef @equipment;
                        undef @non_useable;
                        for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
                                next if (!%{$chars[$config{'char'}]{'inventory'}[$i]});
                                if ($chars[$config{'char'}]{'inventory'}[$i]{'type_equip'} != 0) {
                                        push @equipment, $i;
                                } elsif ($chars[$config{'char'}]{'inventory'}[$i]{'type'} <= 2) {
                                        push @useable, $i;
                                } else {
                                        push @non_useable, $i;
                                }
                        }
                        $~ = "INVENTORY";
                        format INVENTORY =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$index   $display
.
                        print        "-----------Inventory-----------\n";

                        # ICE Start - Equipment information
                        if ($arg1 eq "" || $arg1 eq "eq") {
                                print   "-- Equipment --\n";
                                for ($i = 0; $i < @equipment; $i++) {
                                        $display = $chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'name'};

                                        if($chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'enchant'} > 0) {
                                                $display .= " [+$chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'enchant'}]";
                                        }
                                        if($chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'elementName'}) {
                                                $display .= " [$chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'elementName'}]"
                                        }
                                        if($chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'slotName'} ne "") {
                                                $display .= " [$chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'slotName'}]"
                                        }
                                        if ($chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'equipped'}) {
                                                $display .= " -- Eqp: $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'type_equip'}}";
                                        }
                                        if (!$chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'identified'}) {
                                                $display .= " -- Not Identified";
                                        }
                                        $index = $equipment[$i];
                                        write;
                               }
                        }
                        # ICE End
                        if ($arg1 eq "" || $arg1 eq "nu") {
                                print        "-- Non-Useable --\n";
                                for ($i = 0; $i < @non_useable; $i++) {
                                        $display = $chars[$config{'char'}]{'inventory'}[$non_useable[$i]]{'name'};
                                        $display .= " x $chars[$config{'char'}]{'inventory'}[$non_useable[$i]]{'amount'}";
                                        if ($chars[$config{'char'}]{'inventory'}[$non_useable[$i]]{'equipped'}) {
                                                $display .= " -- Eqp: 箭矢";
                                        }
                                        $index = $non_useable[$i];
                                        write;
                                }
                        }
                        if ($arg1 eq "" || $arg1 eq "u") {
                                print        "-- Useable --\n";
                                for ($i = 0; $i < @useable; $i++) {
                                        $display = $chars[$config{'char'}]{'inventory'}[$useable[$i]]{'name'};
                                        $display .= " x $chars[$config{'char'}]{'inventory'}[$useable[$i]]{'amount'}";
                                        $index = $useable[$i];
                                        write;
                                }
                        }
                        print "-------------------------------\n";

                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'inventory'}[$arg2] eq "") {
                        print        "Error in function 'i' (Iventory Item Desciption)\n"
                                ,"Inventory Item $arg2 does not exist\n";
                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/) {
                        printItemDesc($chars[$config{'char'}]{'inventory'}[$arg2]{'nameID'});

                } else {
                        print        "Syntax Error in function 'i' (Iventory List)\n"
                                ,"Usage: i [<u|eq|nu|desc>] [<inventory #>]\n";
                }

        } elsif ($switch eq "identify") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                if ($arg1 eq "") {
                        $~ = "IDENTIFY";
                        print        "---------Identify List--------\n";
                        for ($i = 0; $i < @identifyID; $i++) {
                                next if ($identifyID[$i] eq "");
                                format IDENTIFY =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i   $chars[$config{'char'}]{'inventory'}[$identifyID[$i]]{'name'}
.
                                write;
                        }
                        print        "------------------------------\n";
                } elsif ($arg1 =~ /\d+/ && $identifyID[$arg1] eq "") {
                        print        "Error in function 'identify' (Identify Item)\n"
                                ,"Identify Item $arg1 does not exist\n";

                } elsif ($arg1 =~ /\d+/) {
                        sendIdentify(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$identifyID[$arg1]]{'index'});
                } else {
                        print        "Syntax Error in function 'identify' (Identify Item)\n"
                                ,"Usage: identify [<identify #>]\n";
                }


        } elsif ($switch eq "ignore") {
                ($arg1, $arg2) = $input =~ /^[\s\S]*? (\d+) ([\s\S]*)/;
                if ($arg1 eq "" || $arg2 eq "" || ($arg1 ne "0" && $arg1 ne "1")) {
                        print        "Syntax Error in function 'ignore' (Ignore Player/Everyone)\n"
                                ,"Usage: ignore <flag> <name | all>\n";
                } else {
                        if ($arg2 eq "all") {
                                sendIgnoreAll(\$remote_socket, !$arg1);
                        } else {
                                sendIgnore(\$remote_socket, $arg2, !$arg1);
                        }
                }

        } elsif ($switch eq "il") {
                $~ = "ILIST";
                print        "-----------Item List-----------\n"
                        ,"#    Name                      \n";
                for ($i = 0; $i < @itemsID; $i++) {
                        next if ($itemsID[$i] eq "");
                        $display = $items{$itemsID[$i]}{'name'};
                        $display .= " x $items{$itemsID[$i]}{'amount'}";
                        format ILIST =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i   $display
.
                        write;
                }
                print "-------------------------------\n";

        } elsif ($switch eq "im") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
                if ($arg1 eq "" || $arg2 eq "") {
                        print        "Syntax Error in function 'im' (Use Item on Monster)\n"
                                ,"Usage: im <item #> <monster #>\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "Error in function 'im' (Use Item on Monster)\n"
                                ,"Inventory Item $arg1 does not exist.\n";
                } elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
                        print        "Error in function 'im' (Use Item on Monster)\n"
                                ,"Inventory Item $arg1 is not of type Usable.\n";
                } elsif ($monstersID[$arg2] eq "") {
                        print        "Error in function 'im' (Use Item on Monster)\n"
                                ,"Monster $arg2 does not exist.\n";
                } else {
                        sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $monstersID[$arg2]);
                }

        } elsif ($switch eq "ip") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
                if ($arg1 eq "" || $arg2 eq "") {
                        print        "Syntax Error in function 'ip' (Use Item on Player)\n"
                                ,"Usage: ip <item #> <player #>\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "Error in function 'ip' (Use Item on Player)\n"
                                ,"Inventory Item $arg1 does not exist.\n";
                } elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
                        print        "Error in function 'ip' (Use Item on Player)\n"
                                ,"Inventory Item $arg1 is not of type Usable.\n";
                } elsif ($playersID[$arg2] eq "") {
                        print        "Error in function 'ip' (Use Item on Player)\n"
                                ,"Player $arg2 does not exist.\n";
                } else {
                        sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $playersID[$arg2]);
                }

        } elsif ($switch eq "is") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                if ($arg1 eq "") {
                        print        "Syntax Error in function 'is' (Use Item on Self)\n"
                                ,"Usage: is <item #>\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "Error in function 'is' (Use Item on Self)\n"
                                ,"Inventory Item $arg1 does not exist.\n";
                } elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
                        print        "Error in function 'is' (Use Item on Self)\n"
                                ,"Inventory Item $arg1 is not of type Usable.\n";
                } else {
                        sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $accountID);
                }

        } elsif ($switch eq "join") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ ([\s\S]*)$/;
                if ($arg1 eq "") {
                        print        "Syntax Error in function 'join' (Join Chat Room)\n"
                                ,"Usage: join <chat room #> [<password>]\n";
                } elsif ($currentChatRoom ne "") {
                        print        "Error in function 'join' (Join Chat Room)\n"
                                ,"You are already in a chat room.\n";
                } elsif ($chatRoomsID[$arg1] eq "") {
                        print        "Error in function 'join' (Join Chat Room)\n"
                                ,"Chat Room $arg1 does not exist.\n";
                } else {
                        sendChatRoomJoin(\$remote_socket, $chatRoomsID[$arg1], $arg2);
                }

        } elsif ($switch eq "judge") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
                if ($arg1 eq "" || $arg2 eq "") {
                        print        "Syntax Error in function 'judge' (Give an alignment point to Player)\n"
                                ,"Usage: judge <player #> <0 (good) | 1 (bad)>\n";
                } elsif ($playersID[$arg1] eq "") {
                        print        "Error in function 'judge' (Give an alignment point to Player)\n"
                                ,"Player $arg1 does not exist.\n";
                } else {
                        $arg2 = ($arg2 >= 1);
                        sendAlignment(\$remote_socket, $playersID[$arg1], $arg2);
                }

        } elsif ($switch eq "kick") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($currentChatRoom eq "") {
                        print        "Error in function 'kick' (Kick from Chat)\n"
                                ,"You are not in a Chat Room.\n";
                } elsif ($arg1 eq "") {
                        print        "Syntax Error in function 'kick' (Kick from Chat)\n"
                                ,"Usage: kick <user #>\n";
                } elsif ($currentChatRoomUsers[$arg1] eq "") {
                        print        "Error in function 'kick' (Kick from Chat)\n"
                                ,"Chat Room User $arg1 doesn't exist\n";
                } else {
                        sendChatRoomKick(\$remote_socket, $currentChatRoomUsers[$arg1]);
                }

        } elsif ($switch eq "leave") {
                if ($currentChatRoom eq "") {
                        print        "Error in function 'leave' (Leave Chat Room)\n"
                                ,"You are not in a Chat Room.\n";
                } else {
                        sendChatRoomLeave(\$remote_socket);
                }

        } elsif ($switch eq "look") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
                if ($arg1 eq "") {
                        print        "Syntax Error in function 'look' (Look a Direction)\n"
                                ,"Usage: look <body dir> [<head dir>]\n";
                } else {
                        look($arg1, $arg2);
                }

        } elsif ($switch eq "memo") {
                sendMemo(\$remote_socket);



        } elsif ($switch eq "ml") {
                my $dMDist;
                $~ = "MLIST";
                print        "-----------Monster List-----------\n"
                        ,"#      Pos     Dist         Name                     DmgTo    DmgFrom\n";
                for ($i = 0; $i < @monstersID; $i++) {
                        next if ($monstersID[$i] eq "");
                        $dMDist = char_distance(\%{$monsters{$monstersID[$i]}});
                        $dmgTo = ($monsters{$monstersID[$i]}{'dmgTo'} ne "")
                                ? $monsters{$monstersID[$i]}{'dmgTo'}
                                : 0;
                        $dmgFrom = ($monsters{$monstersID[$i]}{'dmgFrom'} ne "")
                                ? $monsters{$monstersID[$i]}{'dmgFrom'}
                                : 0;
                        format MLIST =
@<<< @<<< @<<< @<<<<<       @<<<<<<<<<<<<<<<<<<<<<<< @<<<<    @<<<<
$i  $monsters{$monstersID[$i]}{'pos_to'}{'x'} $monsters{$monstersID[$i]}{'pos_to'}{'y'} $dMDist $monsters{$monstersID[$i]}{'name'}                 $dmgTo   $dmgFrom
.
                        write;
                }
                print "----------------------------------\n";

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
                        print        "Syntax Error in function 'move' (Move Player)\n"
                                ,"Usage: move <x> <y> &| <map>\n";
                } elsif ($ai_v{'temp'}{'map'} eq "stop") {
                        aiRemove("move");
                        aiRemove("route");
                        aiRemove("route_getRoute");
                        aiRemove("route_getMapRoute");
                        print "Stopped all movement\n";
                } else {
                        $ai_v{'temp'}{'map'} = $field{'name'} if ($ai_v{'temp'}{'map'} eq "");
                        if ($maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}) {
                                if ($arg2 ne "") {
                                        printC("S0W", "正在计算路线: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $arg1, $arg2\n");
                                        $ai_v{'temp'}{'x'} = $arg1;
                                        $ai_v{'temp'}{'y'} = $arg2;
                                } else {
                                        printC("S0W", "正在计算路线: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'})\n");
                                        undef $ai_v{'temp'}{'x'};
                                        undef $ai_v{'temp'}{'y'};
                                }
                                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
                        } else {
                                print "Map $ai_v{'temp'}{'map'} does not exist\n";
                        }
                }

        } elsif ($switch eq "nl") {
                $~ = "NLIST";
                print        "-----------NPC List-----------\n"
                        ,"#    Name                         Coordinates\n";
                for ($i = 0; $i < @npcsID; $i++) {
                        next if ($npcsID[$i] eq "");
                        $ai_v{'temp'}{'pos_string'} = "($npcs{$npcsID[$i]}{'pos'}{'x'}, $npcs{$npcsID[$i]}{'pos'}{'y'})";
                        format NLIST =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<
$i   $npcs{$npcsID[$i]}{'name'} $ai_v{'temp'}{'pos_string'}
.
                        write;
                }
                print "---------------------------------\n";

        } elsif ($switch eq "p") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                if ($arg1 eq "") {
                        print        "Syntax Error in function 'p' (Party Chat)\n"
                                ,"Usage: p <message>\n";
                } else {
                        sendMessage(\$remote_socket, "p", $arg1);
                }

        } elsif ($switch eq "party") {
                ($arg1) = $input =~ /^[\s\S]*? (\w*)/;
                ($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)\b/;
                if ($arg1 eq "" && !%{$chars[$config{'char'}]{'party'}}) {
                        print        "Error in function 'party' (Party Functions)\n"
                                ,"Can't list party - you're not in a party.\n";
                } elsif ($arg1 eq "") {
                        print "----------Party-----------\n";
                        print $chars[$config{'char'}]{'party'}{'name'}."\n";
                        $~ = "PARTYUSERS";
                        print "#      Name                  Map                    Online    HP\n";
                        for ($i = 0; $i < @partyUsersID; $i++) {
                                next if ($partyUsersID[$i] eq "");
                                $coord_string = "";
                                $hp_string = "";
                                $name_string = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'name'};
                                $admin_string = ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'admin'}) ? "(A)" : "";

                                if ($partyUsersID[$i] eq $accountID) {
                                        $online_string = "Yes";
                                        ($map_string) = $map_name =~ /([\s\S]*)\.gat/;
                                        $coord_string = $chars[$config{'char'}]{'pos'}{'x'}. ", ".$chars[$config{'char'}]{'pos'}{'y'};
                                        $hp_string = $chars[$config{'char'}]{'hp'}."/".$chars[$config{'char'}]{'hp_max'}
                                                        ." (".int($chars[$config{'char'}]{'hp'}/$chars[$config{'char'}]{'hp_max'} * 100)
                                                        ."%)";
                                } else {
                                        $online_string = ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'}) ? "Yes" : "No";
                                        ($map_string) = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'map'} =~ /([\s\S]*)\.gat/;
                                        $coord_string = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'x'}
                                                . ", ".$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'y'}
                                                if ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'x'} ne ""
                                                        && $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'});
                                        $hp_string = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp'}."/".$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'}
                                                        ." (".int($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp'}/$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'} * 100)
                                                        ."%)" if ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'} && $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'});
                                }
                                format PARTYUSERS =
@< @<< @<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<< @<<<<<<< @<<       @<<<<<<<<<<<<<<<<<<
$i $admin_string $name_string $map_string  $coord_string $online_string $hp_string
.
                                write;
                        }
                        print "--------------------------\n";

        } elsif ($arg1 eq "create") {
                        ($arg2) = $input =~ /^[\s\S]*? [\s\S]*? \"([\s\S]*?)\"/;
                        if ($arg2 eq "") {
                                print        "Syntax Error in function 'party create' (Organize Party)\n"
                                ,qq~Usage: party create "<party name>"\n~;
                        } else {
                                sendPartyOrganize(\$remote_socket, $arg2);
                        }

                } elsif ($arg1 eq "join" && $arg2 ne "1" && $arg2 ne "0") {
                        print        "Syntax Error in function 'party join' (Accept/Deny Party Join Request)\n"
                                ,"Usage: party join <flag>\n";
                } elsif ($arg1 eq "join" && $incomingParty{'ID'} eq "") {
                        print        "Error in function 'party join' (Join/Request to Join Party)\n"
                                ,"Can't accept/deny party request - no incoming request.\n";
                } elsif ($arg1 eq "join") {
                        sendPartyJoin(\$remote_socket, $incomingParty{'ID'}, $arg2);
                        undef %incomingParty;

                } elsif ($arg1 eq "request" && !%{$chars[$config{'char'}]{'party'}}) {
                        print        "Error in function 'party request' (Request to Join Party)\n"
                                ,"Can't request a join - you're not in a party.\n";
                } elsif ($arg1 eq "request" && $playersID[$arg2] eq "") {
                        print        "Error in function 'party request' (Request to Join Party)\n"
                                ,"Can't request to join party - player $arg2 does not exist.\n";
                } elsif ($arg1 eq "request") {
                        sendPartyJoinRequest(\$remote_socket, $playersID[$arg2]);


                } elsif ($arg1 eq "leave" && !%{$chars[$config{'char'}]{'party'}}) {
                        print        "Error in function 'party leave' (Leave Party)\n"
                                ,"Can't leave party - you're not in a party.\n";
                } elsif ($arg1 eq "leave") {
                        sendPartyLeave(\$remote_socket);


                } elsif ($arg1 eq "share" && !%{$chars[$config{'char'}]{'party'}}) {
                        print        "Error in function 'party share' (Set Party Share EXP)\n"
                                ,"Can't set share - you're not in a party.\n";
                } elsif ($arg1 eq "share" && $arg2 ne "1" && $arg2 ne "0") {
                        print        "Syntax Error in function 'party share' (Set Party Share EXP)\n"
                                ,"Usage: party share <flag>\n";
                } elsif ($arg1 eq "share") {
                        sendPartyShareEXP(\$remote_socket, $arg2);


                } elsif ($arg1 eq "kick" && !%{$chars[$config{'char'}]{'party'}}) {
                        print        "Error in function 'party kick' (Kick Party Member)\n"
                                ,"Can't kick member - you're not in a party.\n";
                } elsif ($arg1 eq "kick" && $arg2 eq "") {
                        print        "Syntax Error in function 'party kick' (Kick Party Member)\n"
                                ,"Usage: party kick <party member #>\n";
                } elsif ($arg1 eq "kick" && $partyUsersID[$arg2] eq "") {
                        print        "Error in function 'party kick' (Kick Party Member)\n"
                                ,"Can't kick member - member $arg2 doesn't exist.\n";
                } elsif ($arg1 eq "kick") {
                        sendPartyKick(\$remote_socket, $partyUsersID[$arg2]
                                        ,$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$arg2]}{'name'});

                }
        } elsif ($switch eq "petl") {
                $~ = "PETLIST";
                print        "-----------Pet List-----------\n"
                        ,"#    Type                     Name\n";
                for ($i = 0; $i < @petsID; $i++) {
                        next if ($petsID[$i] eq "");
                        format PETLIST =
@<<< @<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<
$i   $pets{$petsID[$i]}{'name'} $pets{$petsID[$i]}{'name_given'}
.
                        write;
                }
                print "----------------------------------\n";

        } elsif ($switch eq "pm") {
                ($arg1, $arg2) =$input =~ /^[\s\S]*? "([\s\S]*?)" ([\s\S]*)/;
                $type = 0;
                if (!$arg1) {
                        ($arg1, $arg2) =$input =~ /^[\s\S]*? (\d+) ([\s\S]*)/;
                        $type = 1;
                }
                if ($arg1 eq "" || $arg2 eq "") {
                        print        "Syntax Error in function 'pm' (Private Message)\n"
                                ,qq~Usage: pm ("<username>" | <pm #>) <message>\n~;
                } elsif ($type) {
                        if ($arg1 - 1 >= @privMsgUsers) {
                                print        "Error in function 'pm' (Private Message)\n"
                                ,"Quick look-up $arg1 does not exist\n";
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
                print "-----------PM LIST-----------\n";
                for ($i = 1; $i <= @privMsgUsers; $i++) {
                        format PMLIST =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<
$i   $privMsgUsers[$i - 1]
.
                        write;
                }
                print "-----------------------------\n";


        } elsif ($switch eq "pl") {
                my $dPDist;
                $~ = "PLIST";
                print        "-----------Player List-----------\n"
                        ,"#      Pos     Dist    Name                            AID       Sex  Job\n";
                for ($i = 0; $i < @playersID; $i++) {
                        next if ($playersID[$i] eq "");
                        $dPDist = char_distance(\%{$players{$playersID[$i]}});
                        if (%{$players{$playersID[$i]}{'guild'}}) {
                                $name = "$players{$playersID[$i]}{'name'} [$players{$playersID[$i]}{'guild'}{'name'}]";
                        } else {
                                $name = $players{$playersID[$i]}{'name'};
                        }
                        format PLIST =
@<<< @<<< @<<< @<<<<<  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @<<<<<<<< @<<< @<<<<<<<<<
$i   $players{$playersID[$i]}{'pos_to'}{'x'} $players{$playersID[$i]}{'pos_to'}{'y'} $dPDist $name $players{$playersID[$i]}{'AID'} $sex_lut{$players{$playersID[$i]}{'sex'}} $jobs_lut{$players{$playersID[$i]}{'jobID'}}
.
                        write;
                }
                print "---------------------------------\n";

        } elsif ($switch eq "portals") {
                $~ = "PORTALLIST";
                print        "-----------Portal List-----------\n"
                        ,"#    Name                                Coordinates\n";
                for ($i = 0; $i < @portalsID; $i++) {
                        next if ($portalsID[$i] eq "");
                        $coords = "($portals{$portalsID[$i]}{'pos'}{'x'},$portals{$portalsID[$i]}{'pos'}{'y'})";
                        format PORTALLIST =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<
$i   $portals{$portalsID[$i]}{'name'}    $coords
.
                        write;
                }
                print "---------------------------------\n";

        } elsif ($switch eq "quit") {
                quit();

        } elsif ($switch eq "reload") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                parseReload($arg1);

        } elsif ($switch eq "relog") {
                relog();

        } elsif ($switch eq "respawn") {
                useTeleport(2);

        } elsif ($switch eq "s") {
                if ($chars[$config{'char'}]{'exp_last'} > $chars[$config{'char'}]{'exp'}) {
                        $baseEXPKill = $chars[$config{'char'}]{'exp_max_last'} - $chars[$config{'char'}]{'exp_last'} + $chars[$config{'char'}]{'exp'};
                } elsif ($chars[$config{'char'}]{'exp_last'} == 0 && $chars[$config{'char'}]{'exp_max_last'} == 0) {
                        $baseEXPKill = 0;
                } else {
                        $baseEXPKill = $chars[$config{'char'}]{'exp'} - $chars[$config{'char'}]{'exp_last'};
                }
                if ($chars[$config{'char'}]{'exp_job_last'} > $chars[$config{'char'}]{'exp_job'}) {
                        $jobEXPKill = $chars[$config{'char'}]{'exp_job_max_last'} - $chars[$config{'char'}]{'exp_job_last'} + $chars[$config{'char'}]{'exp_job'};
                } elsif ($chars[$config{'char'}]{'exp_job_last'} == 0 && $chars[$config{'char'}]{'exp_job_max_last'} == 0) {
                        $jobEXPKill = 0;
                } else {
                        $jobEXPKill = $chars[$config{'char'}]{'exp_job'} - $chars[$config{'char'}]{'exp_job_last'};
                }
                $lastBase =
                $hp_string = $chars[$config{'char'}]{'hp'}."/".$chars[$config{'char'}]{'hp_max'}." ("
                                .int($chars[$config{'char'}]{'hp'}/$chars[$config{'char'}]{'hp_max'} * 100)
                                ."%)" if $chars[$config{'char'}]{'hp_max'};
                $sp_string = $chars[$config{'char'}]{'sp'}."/".$chars[$config{'char'}]{'sp_max'}." ("
                                .int($chars[$config{'char'}]{'sp'}/$chars[$config{'char'}]{'sp_max'} * 100)
                                ."%)" if $chars[$config{'char'}]{'sp_max'};
                $base_string = $chars[$config{'char'}]{'exp'}."/".$chars[$config{'char'}]{'exp_max'}." ("
                                .sprintf("%.2f",$chars[$config{'char'}]{'exp'}/$chars[$config{'char'}]{'exp_max'} * 100)
                                ."%)" if $chars[$config{'char'}]{'exp_max'};
                $job_string = $chars[$config{'char'}]{'exp_job'}."/".$chars[$config{'char'}]{'exp_job_max'}." ("
                                .sprintf("%.2f",$chars[$config{'char'}]{'exp_job'}/$chars[$config{'char'}]{'exp_job_max'} * 100)
                                ."%)" if $chars[$config{'char'}]{'exp_job_max'};
                $weight_string = $chars[$config{'char'}]{'weight'}."/".$chars[$config{'char'}]{'weight_max'}." ("
                                .int($chars[$config{'char'}]{'weight'}/$chars[$config{'char'}]{'weight_max'} * 100)
                                ."%)" if $chars[$config{'char'}]{'weight_max'};
                $job_name_string = "$jobs_lut{$chars[$config{'char'}]{'jobID'}} $sex_lut{$chars[$config{'char'}]{'sex'}}";
                print        "------------------- 人物基本信息 ------------------\n";
                $~ = "STATUS";
                format STATUS =
@<<<<<<<<<<<<<<<<<<<<<< HP: @<<<<<<<<<<<<<<<<<<<<
$chars[$config{'char'}]{'name'} $hp_string
@<<<<<<<<<<<<<<<<<<<<<< SP: @<<<<<<<<<<<<<<<<<<<<
$job_name_string              $sp_string
BaseLv: @<<   EXP: @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      $chars[$config{'char'}]{'lv'} $base_string
Job Lv: @<<   EXP: @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      $chars[$config{'char'}]{'lv_job'} $job_string
负重: @<<<<<<<<<<<<<<<< 金钱: @<<<<<<<<<<<<<
        $weight_string           $chars[$config{'char'}]{'zenny'}
AID : @<<<<<<<<<<<<<<<< VIP : @<<<<<<<<<<<<<
        $accountAID              $vipLevel
.
                write;
                print "---------------------------------------------------\n";
                print "$chars[$config{'char'}]{'state'}\n";
                foreach (keys %skillsstID_lut) {
                        if ($chars[$config{'char'}]{'skillsst'}{$skillsst_rlut{lc($skillsstID_lut{$_})}} == 1) {
                                print "$skillsstID_lut{$_}\n";
                        }
                }
                if ($chars[$config{'char'}]{'Spirits'} > 0) {
                        print "气弹数: $chars[$config{'char'}]{'Spirits'}\n";
                }
                print "---------------------------------------------------\n";

        } elsif ($switch eq "sell") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
                if ($arg1 eq "" && $talk{'buyOrSell'}) {
                        sendGetSellList(\$remote_socket, $talk{'ID'});

                } elsif ($arg1 eq "") {
                        print        "Syntax Error in function 'sell' (Sell Inventory Item)\n"
                                ,"Usage: sell <item #> [<amount>]\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "Error in function 'sell' (Sell Inventory Item)\n"
                                ,"Inventory Item $arg1 does not exist.\n";
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
                $ai_v{'attackAuto_old'} = $config{'attackAuto'};
                $ai_v{'route_randomWalk_old'} = $config{'route_randomWalk'};
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
                        print        "Syntax Error in function 'sm' (Use Skill on Monster)\n"
                                ,"Usage: sm <skill #> <monster #> [<skill lvl>]\n";
                } elsif ($monstersID[$arg2] eq "") {
                        print        "Error in function 'sm' (Use Skill on Monster)\n"
                                ,"Monster $arg2 does not exist.\n";
                } elsif ($skillsID[$arg1] eq "") {
                        print        "Error in function 'sm' (Use Skill on Monster)\n"
                                ,"Skill $arg1 does not exist.\n";
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
                        $~ = "SKILLS";
                        print "----------Skill List-----------\n";
                        print "#  Skill Name                    Lv     SP\n";
                        for ($i=0; $i < @skillsID; $i++) {
                                format SKILLS =
@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<    @<<<
$i $skills_lut{$skillsID[$i]} $chars[$config{'char'}]{'skills'}{$skillsID[$i]}{'lv'} $skillsSP_lut{$skillsID[$i]}{$chars[$config{'char'}]{'skills'}{$skillsID[$i]}{'lv'}}
.
                                write;
                        }
                        print "\nSkill Points: $chars[$config{'char'}]{'points_skill'}\n";
                        print "-------------------------------\n";


                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $skillsID[$arg2] eq "") {
                        print        "Error in function 'skills add' (Add Skill Point)\n"
                                ,"Skill $arg2 does not exist.\n";
                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'points_skill'} < 1) {
                        print        "Error in function 'skills add' (Add Skill Point)\n"
                                ,"Not enough skill points to increase $skills_lut{$skillsID[$arg2]}.\n";
                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/) {
                        sendAddSkillPoint(\$remote_socket, $chars[$config{'char'}]{'skills'}{$skillsID[$arg2]}{'ID'});


                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/ && $skillsID[$arg2] eq "") {
                        print        "Error in function 'skills desc' (Skill Description)\n"
                                ,"Skill $arg2 does not exist.\n";
                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/) {
                        print "===============Skill Description===============\n";
                        print "Skill: $skills_lut{$skillsID[$arg2]}\n\n";
                        print $skillsDesc_lut{$skillsID[$arg2]};
                        print "==============================================\n";
                } else {
                        print        "Syntax Error in function 'skills' (Skills Functions)\n"
                                ,"Usage: skills [<add | desc>] [<skill #>]\n";
                }


        } elsif ($switch eq "sp") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
                ($arg3) = $input =~ /^[\s\S]*? \d+ \d+ (\d+)/;
                if ($arg1 eq "" || $arg2 eq "") {
                        print        "Syntax Error in function 'sp' (Use Skill on Player)\n"
                                ,"Usage: sp <skill #> <player #> [<skill lvl>]\n";
                } elsif ($playersID[$arg2] eq "") {
                        print        "Error in function 'sp' (Use Skill on Player)\n"
                                ,"Player $arg2 does not exist.\n";
                } elsif ($skillsID[$arg1] eq "") {
                        print        "Error in function 'sp' (Use Skill on Player)\n"
                                ,"Skill $arg1 does not exist.\n";
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
                        print        "Syntax Error in function 'ss' (Use Skill on Self)\n"
                                ,"Usage: ss <skill #> [<skill lvl>]\n";
                } elsif ($skillsID[$arg1] eq "") {
                        print        "Error in function 'ss' (Use Skill on Self)\n"
                                ,"Skill $arg1 does not exist.\n";
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
                print        "-----------Char Stats-----------\n";
                $~ = "STATS";
                $tilde = "~";
                format STATS =
Str: @<<+@<< #@< Atk:  @<<+@<< Def:  @<<+@<<
$chars[$config{'char'}]{'str'} $chars[$config{'char'}]{'str_bonus'} $chars[$config{'char'}]{'points_str'} $chars[$config{'char'}]{'attack'} $chars[$config{'char'}]{'attack_bonus'} $chars[$config{'char'}]{'def'} $chars[$config{'char'}]{'def_bonus'}
Agi: @<<+@<< #@< Matk: @<<@@<< Mdef: @<<+@<<
$chars[$config{'char'}]{'agi'} $chars[$config{'char'}]{'agi_bonus'} $chars[$config{'char'}]{'points_agi'} $chars[$config{'char'}]{'attack_magic_min'} $tilde $chars[$config{'char'}]{'attack_magic_max'} $chars[$config{'char'}]{'def_magic'} $chars[$config{'char'}]{'def_magic_bonus'}
Vit: @<<+@<< #@< Hit:  @<<     Flee: @<<+@<<
$chars[$config{'char'}]{'vit'} $chars[$config{'char'}]{'vit_bonus'} $chars[$config{'char'}]{'points_vit'} $chars[$config{'char'}]{'hit'} $chars[$config{'char'}]{'flee'} $chars[$config{'char'}]{'flee_bonus'}
Int: @<<+@<< #@< Critical: @<< Aspd: @<<
$chars[$config{'char'}]{'int'} $chars[$config{'char'}]{'int_bonus'} $chars[$config{'char'}]{'points_int'} $chars[$config{'char'}]{'critical'} $chars[$config{'char'}]{'attack_speed'}
Dex: @<<+@<< #@< Status Points: @<<
$chars[$config{'char'}]{'dex'} $chars[$config{'char'}]{'dex_bonus'} $chars[$config{'char'}]{'points_dex'} $chars[$config{'char'}]{'points_free'}
Luk: @<<+@<< #@< Guild: @<<<<<<<<<<<<<<<<<<<<<
$chars[$config{'char'}]{'luk'} $chars[$config{'char'}]{'luk_bonus'} $chars[$config{'char'}]{'points_luk'} $chars[$config{'char'}]{'guild'}{'name'}
.
                write;
                print        "--------------------------------\n";

        } elsif ($switch eq "stand") {
                if ($ai_v{'attackAuto_old'} ne "") {
                        configModify("attackAuto", $ai_v{'attackAuto_old'});
                        configModify("route_randomWalk", $ai_v{'route_randomWalk_old'});
                }
                stand();
                $ai_v{'sitAuto_forceStop'} = 1;

        } elsif ($switch eq "stat_add") {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)$/;
                if ($arg1 ne "str" &&  $arg1 ne "agi" && $arg1 ne "vit" && $arg1 ne "int"
                        && $arg1 ne "dex" && $arg1 ne "luk") {
                        print        "Syntax Error in function 'stat_add' (Add Status Point)\n"
                        ,"Usage: stat_add <str | agi | vit | int | dex | luk>\n";
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
                                print        "Error in function 'stat_add' (Add Status Point)\n"
                                        ,"Not enough status points to increase $arg1\n";
                        } else {
                                $chars[$config{'char'}]{$arg1} += 1;
                                sendAddStatusPoint(\$remote_socket, $ID);
                        }
                }

        } elsif ($switch eq "storage") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                ($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
                ($arg3) = $input =~ /^[\s\S]*? \w+ \d+ (\d+)/;
                if ($arg1 eq "") {
                        undef @non_equipment;
                        undef @equipment;
                        for ($i=0; $i < @{$storage{'inventory'}};$i++) {
                                next if (!%{$storage{'inventory'}[$i]});
                                if ($storage{'inventory'}[$i]{'type_equip'} != 0) {
                                        push @equipment, $i;
                                } else {
                                        push @non_equipment, $i;
                                }
                        }
                        $~ = "STORAGELIST";
                        format STORAGELIST =
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$index        $display
.
                        print        "-------------Storage-------------\n";

                        print        "-- Non-Equipment --\n";

                        for ($i = 0; $i < @non_equipment; $i++) {
                                $display = $storage{'inventory'}[$non_equipment[$i]]{'name'};
                                $display .= " x $storage{'inventory'}[$non_equipment[$i]]{'amount'}";
                                $index = $non_equipment[$i];
                                write;
                        }

                        print        "-- Equipment --\n";
                        for ($i = 0; $i < @equipment; $i++) {
                                $display = $storage{'inventory'}[$equipment[$i]]{'name'};
                                if($storage{'inventory'}[$equipment[$i]]{'enchant'} > 0) {
                                        $display .= " [+$storage{'inventory'}[$equipment[$i]]{'enchant'}]";
                                }
                                if($storage{'inventory'}[$equipment[$i]]{'elementName'}) {
                                        $display .= " [$storage{'inventory'}[$equipment[$i]]{'elementName'}]";
                                }
                                if($storage{'inventory'}[$equipment[$i]]{'slotName'}) {
                                        $display .= " [$storage{'inventory'}[$equipment[$i]]{'slotName'}]";
                                }
                                $index = $equipment[$i];
                                write;
                        }
                        print "\nCapacity: $storage{'items'}/$storage{'items_max'}\n";
                        print "-------------------------------\n";


                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'inventory'}[$arg2] eq "") {
                        print        "Error in function 'storage add' (Add Item to Storage)\n"
                                ,"Inventory Item $arg2 does not exist\n";
                } elsif ($arg1 eq "add" && $arg2 =~ /\d+/) {
                        if (!$arg3 || $arg3 > $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'}) {
                                $arg3 = $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'};
                        }
                        sendStorageAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg2]{'index'}, $arg3);

                } elsif ($arg1 eq "get" && $arg2 =~ /\d+/ && !%{$storage{'inventory'}[$arg2]}) {
                        print        "Error in function 'storage get' (Get Item from Storage)\n"
                                ,"Storage Item $arg2 does not exist\n";
                } elsif ($arg1 eq "get" && $arg2 =~ /\d+/) {
                        if (!$arg3 || $arg3 > $storage{'inventory'}[$arg2]{'amount'}) {
                                $arg3 = $storage{'inventory'}[$arg2]{'amount'};
                        }
                        sendStorageGet(\$remote_socket, $arg2, $arg3);

                } elsif ($arg1 eq "close") {
                        sendStorageClose(\$remote_socket);

                } else {
                        print        "Syntax Error in function 'storage' (Storage Functions)\n"
                                ,"Usage: storage [<add | get | close>] [<inventory # | storage #>] [<amount>]\n";
                }

        } elsif ($switch eq "store") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                ($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
                if ($arg1 eq "" && !$talk{'buyOrSell'}) {
                        $~ = "STORELIST";
                        print "----------Store List-----------\n";
                        print "#  Name                    Type           Price\n";
                        for ($i=0; $i < @storeList;$i++) {
                                $display = $storeList[$i]{'name'};
                                format STORELIST =
@< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<< @>>>>>>>z
$i $display                $itemTypes_lut{$storeList[$i]{'type'}} $storeList[$i]{'price'}
.
                                write;
                        }
                        print "-------------------------------\n";
                } elsif ($arg1 eq "" && $talk{'buyOrSell'}) {
                        sendGetStoreList(\$remote_socket, $talk{'ID'});


                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/ && $storeList[$arg2] eq "") {
                        print        "Error in function 'store desc' (Store Item Description)\n"
                                ,"Usage: Store item $arg2 does not exist\n";
                } elsif ($arg1 eq "desc" && $arg2 =~ /\d+/) {
                        printItemDesc($storeList[$arg2]);

                } else {
                        print        "Syntax Error in function 'store' (Store Functions)\n"
                                ,"Usage: store [<desc>] [<store item #>]\n";

                }

        } elsif ($switch eq "take") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)$/;
                if ($arg1 eq "") {
                        print        "Syntax Error in function 'take' (Take Item)\n"
                                ,"Usage: take <item #>\n";
                } elsif ($itemsID[$arg1] eq "") {
                        print        "Error in function 'take' (Take Item)\n"
                                ,"Item $arg1 does not exist.\n";
                } else {
                        take($itemsID[$arg1]);
                }


        } elsif ($switch eq "warp") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                if (!@{$warp{'responses'}}) {
                        print        "Error in function 'warpto' (Respond to warp)\n"
                                ,"You have not warp list.\n";
                } elsif ($arg1 eq "") {
                        $~ = "WARP";
                        print "----------传送之阵-----------\n";
                        print "#  responses\n";
                        for ($i=0; $i < @{$warp{'responses'}};$i++) {
                                format WARP =
@< @<<<<<<<<<<<<<<<<<<<<<<
$i $warp{'responses'}[$i]
.
                                write;
                        }
                        print "-------------------------------\n";
                        printC("I7W", "输入 'warp' 选择回答\n");
                } elsif ($warp{'responses'}[$arg1] eq "") {
                        print        "Error in function 'warpto' (Respond to warp)\n"
                                ,"Response $arg1 does not exist.\n";

                } else {
                        sendWarpto(\$remote_socket, $warp{'responses'}[$arg1]);
                }



        } elsif ($switch eq "talk") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                ($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)/;

                if ($arg1 =~ /^\d+$/ && $npcsID[$arg1] eq "") {
                        print        "Error in function 'talk' (Talk to NPC)\n"
                                ,"NPC $arg1 does not exist\n";
                } elsif ($arg1 =~ /^\d+$/) {
                        sendTalk(\$remote_socket, $npcsID[$arg1]);

                } elsif ($arg1 eq "resp" && !%talk) {
                        print        "Error in function 'talk resp' (Respond to NPC)\n"
                                ,"You are not talking to any NPC.\n";
                } elsif ($arg1 eq "resp" && $arg2 eq "") {
                        $display = $npcs{$talk{'nameID'}}{'name'};
                        $~ = "RESPONSES";
                        print "----------Responses-----------\n";
                        print "NPC: $display\n";
                        print "#  Response\n";
                        for ($i=0; $i < @{$talk{'responses'}};$i++) {
                                format RESPONSES =
@< @<<<<<<<<<<<<<<<<<<<<<<
$i $talk{'responses'}[$i]
.
                                write;
                        }
                        print "-------------------------------\n";
                } elsif ($arg1 eq "resp" && $arg2 ne "" && $talk{'responses'}[$arg2] eq "") {
                        print        "Error in function 'talk resp' (Respond to NPC)\n"
                                ,"Response $arg2 does not exist.\n";
                } elsif ($arg1 eq "resp" && $arg2 ne "") {
                        if ($talk{'responses'}[$arg2] eq "Cancel Chat") {
                                $arg2 = 255;
                        } else {
                                $arg2 += 1;
                        }
                        sendTalkResponse(\$remote_socket, $talk{'ID'}, $arg2);


                } elsif ($arg1 eq "cont" && !%talk) {
                        print        "Error in function 'talk cont' (Continue Talking to NPC)\n"
                                ,"You are not talking to any NPC.\n";
                } elsif ($arg1 eq "cont") {
                        sendTalkContinue(\$remote_socket, $talk{'ID'});

                } elsif ($arg1 eq "amount") {
                        sendTalkAmount(\$remote_socket, $talk{'ID'}, $arg2);

                } elsif ($arg1 eq "no") {
                        sendTalkCancel(\$remote_socket, $talk{'ID'});


                } else {
                        print        "Syntax Error in function 'talk' (Talk to NPC)\n"
                                ,"Usage: talk <NPC # | cont | resp> [<response #>]\n";
                }


        } elsif ($switch eq "tank") {
                ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
                if ($arg1 eq "") {
                        print        "Syntax Error in function 'tank' (Tank for a Player)\n"
                                ,"Usage: tank <player #>\n";
                } elsif ($arg1 eq "stop") {
                        configModify("tankMode", 0);
                } elsif ($playersID[$arg1] eq "") {
                        print        "Error in function 'tank' (Tank for a Player)\n"
                                ,"Player $arg1 does not exist.\n";
                } else {
                        configModify("tankMode", 1);
                        configModify("tankModeTarget", $players{$playersID[$arg1]}{'name'});
                }

        } elsif ($switch eq "tele") {
                useTeleport(1);

        } elsif ($switch eq "timeout") {
                ($arg1, $arg2) = $input =~ /^[\s\S]*? ([\s\S]*) ([\s\S]*?)$/;
                if ($arg1 eq "") {
                        print        "Syntax Error in function 'timeout' (set a timeout)\n"
                                ,"Usage: timeout <type> [<seconds>]\n";
                } elsif ($timeout{$arg1} eq "") {
                        print        "Error in function 'timeout' (set a timeout)\n"
                                ,"Timeout $arg1 doesn't exist\n";
                } elsif ($arg2 eq "") {
                        print "Timeout '$arg1' is $config{$arg1}\n";
                } else {
                        setTimeout($arg1, $arg2);
                }


        } elsif ($switch eq "uneq") {
                ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
                if ($arg1 eq "") {
                        print        "Syntax Error in function 'unequip' (Unequip Inventory Item)\n"
                                ,"Usage: unequip <item #>\n";
                } elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
                        print        "Error in function 'unequip' (Unequip Inventory Item)\n"
                                ,"Inventory Item $arg1 does not exist.\n";
                } elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'equipped'} == 0) {
                        print        "Error in function 'unequip' (Unequip Inventory Item)\n"
                                ,"Inventory Item $arg1 is not equipped.\n";
                } else {
                        sendUnequip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'});
                }

        } elsif ($switch eq "where") {
                ($map_string) = $map_name =~ /([\s\S]*)\.gat/;
                print "Location $maps_lut{$map_string.'.rsw'}($map_string) : $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'}\n";

        } elsif ($switch eq "who") {
                sendWho(\$remote_socket);

        # ICE Start - Auto Shop
        } elsif ($switch eq "shop") {
                @arg = split / /, $input;
                shift @arg;
                ($arg[1]) = $input =~ /^.*? (\d+)/;
                ($arg[2]) = $input =~ /^.*? \d+ (\d+)/;
                ($arg[3]) = $input =~ /^.*? \d+ \d+ (\d+)/;
                if ($arg[0] eq "list") {
                        $~ = "VLIST";
                        print "-------------Shop List------------\n"
                             ,"#   Title                                Owner\n";
                        for ($i = 0; $i < @venderListsID; $i++) {
                                next if ($venderListsID[$i] eq "");
                                $owner_string = ($venderListsID[$i] ne $accountID) ? $players{$venderListsID[$i]}{'name'} : $chars[$config{'char'}]{'name'};
                                format VLIST =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<
$i  $venderLists{$venderListsID[$i]}{'title'} $owner_string
.
                                write;
                        }
                        print "----------------------------------\n";
                } elsif ($arg[0] eq "end") {
                        undef @venderItemList;
                        undef $venderID;
                } elsif ($arg[0] eq "open") {
                        sendOpenShop(\$remote_socket);
                } elsif ($arg[0] eq "close") {
                        sendCloseShop(\$remote_socket);
                } elsif ($arg[0] eq "item") {
                        $~ = "ARTICLESLIST2";
                        print "----------Items being sold in store------------\n";
                        print "#   Name                        Type          Quantity     Price   Sold\n";
                        for ($number = 0; $number < @articles; $number++) {
                                next if ($articles[$number] eq "");
                        format ARTICLESLIST2 =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<< @>>>>>> @>>>>>>>z  @>>>>>
$number $articles[$number]{'name'} $itemTypes_lut{$articles[$number]{'type'}} $articles[$number]{'quantity'} $articles[$number]{'price'} $articles[$number]{'sold'}
.
                        write;
                        }
                        print "----------------------------------------------\n";
                        print "Shop name: $shop{'shop_title'}\n";
                        print "You have earned $shop{'earned'}z.\n";
                } elsif ($arg[0] eq "buy") {
                        if ($arg[1] eq "") {
                                print "Usage: shop buy <shop #>                     (Enter a shop and list sell items)\n"
                                     ,"       shop buy <shop #> <item #> <amount>   (Buy items from a shop)\n";
                        } elsif ($venderListsID[$arg[1]] eq "") {
                                print "Error in function 'shop buy' (buy item from shop)\n"
                                     ,"Shop $arg[1] does not exist.\n";
                        } elsif ($arg[2] eq "") {
                                sendEnteringVender(\$remote_socket, $venderListsID[$arg[1]]);
                        } elsif ($venderListsID[$arg[1]] ne $venderID) {
                                print "Error in function 'shop buy' (buy item from shop)\n"
                                     ,"Shop ID is wrong.\n";
                        } elsif (!$arg[3]) {
                                print "Error in function 'shop buy' (buy item from shop)\n"
                                     ,"Please enter item amount.\n";
                        } elsif ($arg[3] > 0  && $arg[3] =~ /\d+/) {
                                sendBuyVender(\$remote_socket, $arg2, $arg3);
                        } else {
                                print "Error in function 'shop buy' (Buy item from shop)\n"
                                     ,"Usage: shop buy <shop #>                     (Enter a shop and list sell items)\n"
                                     ,"       shop buy <shop #> <item #> <amount>   (Buy items from a shop)\n";
                        }
                } else {
                        print "Usage: shop < list | buy | end | open | item | close >\n"
                             ,"       - list        List all shop around you\n"
                             ,"       - buy         Buy items from a shop\n"
                             ,"       - end         End of buy items\n"
                             ,"       - open        Open your shop by shop.txt\n"
                             ,"       - item        List items of your shop\n"
                             ,"       - close       Close your shop\n";
                }
        # ICE End

        # ICE Start - Map info
        } elsif ($switch eq "map") {
                $~ = "MAPLIST";
                ($map_string) = $map_name =~ /([\s\S]*)\.gat/;
                print        "-------------Map Info------------\n";
                print   "Location $maps_lut{$map_string.'.rsw'}($map_string) : $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'}\n";
                print        "Area             Map           Portals\n";
                foreach (keys %portals_lut) {
                        if ($portals_lut{$_}{'source'}{'map'} eq $map_string){
                        $coords = "($portals_lut{$_}{'source'}{'pos'}{'x'},$portals_lut{$_}{'source'}{'pos'}{'y'})";
                        format MAPLIST =
@<<<<<<<<<<<<<<< @<<<<<<<<<<<< @<<<<<<<<<<<<
$maps_lut{$portals_lut{$_}{'dest'}{'map'}.'.rsw'}    $portals_lut{$_}{'dest'}{'map'}    $coords
.
                        write;
                        }
                }
                print "---------------------------------\n";
        # ICE End

        } elsif ($switch eq "ver") {
                printC("I0Y", "KoreEasy $version $beta\n");

        } elsif ($switch eq "base") {
                unshift @ai_seq, "sellAuto";
                unshift @ai_seq_args, {};
                unshift @ai_seq, "healAuto";
                unshift @ai_seq_args, {};

        } elsif ($switch eq "time" && $vipLevel >= 2) {
                my $temp;
                print "寻找目标 : $mvp{'now_monster'}{'name'}\n";
                $temp = getFormattedDate(int($mvp{'now_monster'}{'end_time'}));
                print "寻找时间 : $temp\n";
                undef $temp;
                foreach (keys %mvptime) {
                        next if ($_ eq "");
                        $temp = getFormattedDate(int($mvptime{$_})) if ($mvptime{$_} > 0);
                        print "$_ : $temp\n";
                        undef $temp;
                }

        # ICE Start - Exp calculation
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
                                printC("X0Y", "在线时间           升级需要              战斗时间 休息时间 回城 死亡 掉线\n");

                                $~ = "EXPBLIST";
                                format EXPBLIST =
@<<<<<<<<<<<<<<<<  @<<<<<<<<<<<<<<<<<    @>>>>>>> @>>>>>>> @>>> @>>> @>>>
$playTime_string $levelTime_string $attack_string $sit_string $exp{'base'}{'back'} $exp{'base'}{'dead'} $exp{'base'}{'disconnect'}
.
                                write;
                                print "-------------------------------------------------------------------------\n";
                               printC("X0C", "共获得BASE经验     共获得JOB经验         每小时BASE经验     每小时JOB经验   \n");
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
                                printC("X0W", "消灭怪物           数量  平均时间  BASE效率   JOB效率  每秒伤害  每秒损失\n");
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
                        printC("X0W", "使用物品           数量                   获得物品           数量    重要\n");
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
                                while (@exp_pick[$i] ne "" || @exp_used[$i] ne "") {
                                        undef $pick_string;
                                        undef $pick_amount;
                                        undef $used_string;
                                        undef $used_amount;
                                        undef $flag_string;
                                        if (@exp_pick[$i] > 0) {
                                                $pick_string = $items_lut{@exp_pick[$i]};
                                                $pick_amount = $exp{'item'}{@exp_pick[$i]}{'pick'};
                                                if ($importantItems_rlut{$pick_string} == 1) {
                                                        $flag_string = "Y";
                                                }
                                        }
                                        if (@exp_used[$i] > 0) {
                                                $used_string = $items_lut{@exp_used[$i]};
                                                $used_amount = $exp{'item'}{@exp_used[$i]}{'used'};
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
                        print "Syntax Error in function 'exp' (Exp Calculation)\n";
                        print "Usage: exp [e|m|i|a|reset]\n";
                }
        # ICE End

        # ICE Start - Ignore all private message
        } elsif ($switch eq "exall") {
                ($arg1) = $input =~ /^.*? (.*)$/;
                if ($arg1 eq "1" || $arg1 eq "0"){
                        sendIgnoreAll(\$remote_socket, !$arg1);
                } else {
                        print "Syntax Error in function 'exall'\n","Usage: exall <flag>\n";
                }
        # ICE End

        # ICE Start - Auto chat
        } elsif ($switch eq "ac") {
                if ($config{'chatAutoPublic'} > 0 || $config{'chatAutoPrivate'} > 0) {
                        $chatAutoPublic_old = $config{'chatAutoPublic'};
                        $chatAutoPrivate_old = $config{'chatAutoPrivate'};
                        $config{'chatAutoPublic'} = 0;
                        $config{'chatAutoPrivate'} = 0;
                        printC("I0", "关闭自动回复\n");
                } else {
                        $config{'chatAutoPublic'} = $chatAutoPublic_old;
                        $config{'chatAutoPrivate'} = $chatAutoPrivate_old;
                        printC("I0", "开启自动回复\n");
                }
        # ICE End

        } elsif ($switch eq "ye") {
                if (!$yelloweasy) {
                        $yelloweasy = 1;
                        printC("S0W", "打开Yellow Easy通讯\n");
                        $windows_socket = IO::Socket::INET->new(
                                PeerAddr        => $config{'local_host'},
                                PeerPort        => 7600,
                                LocalAddr        => $config{'local_host'},
                                LocalPort        => 7000,
                                Proto                => 'udp');
                        sendWindowsMessage("AAFF".chr(1)."7000");
                        for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
                                next if (!%{$chars[$config{'char'}]{'inventory'}[$i]});
                                sendWindowsMessage("AA20".chr(1).$i.chr(1).$chars[$config{'char'}]{'inventory'}[$i]{'type'}.chr(1).$chars[$config{'char'}]{'inventory'}[$i]{'name'}.chr(1).$chars[$config{'char'}]{'inventory'}[$i]{'amount'});
                                print "AA20".chr(1).$i.chr(1).$chars[$config{'char'}]{'inventory'}[$i]{'type'}.chr(1).$chars[$config{'char'}]{'inventory'}[$i]{'name'}.chr(1).$chars[$config{'char'}]{'inventory'}[$i]{'amount'}."\n";
                        }
                } else {
                        undef $yelloweasy;
                        printC("S0W", "关闭Yellow Easy通讯\n");
                        undef $windows_socket;
                }

        # ICE Start - New teleport command
        } elsif ($switch eq "tp") {
                ($arg1) = $input =~ /^.*? (.*)$/;
                if ($arg1 eq "1"){
                        useTeleport(1);
                        printC("A5W", "随机瞬间移动\n");
                } elsif ($arg1 eq "2"){
                        useTeleport(2);
                        printC("A5W", "返回记录地点\n");
                } else {
                        print "Syntax Error in function 'tp' (Teleport)\n";
                        print "Usage: tp 1  # Teleport to Random, like FlyWing\n";
                        print "       tp 2  # Teleport to SaveMap, like BeautifulWing\n";
                }
        # ICE End

        # ICE Start - Show AI
        } elsif ($switch eq "ai") {
                ($arg1) = $input =~ /^.*? (.*)$/;
                if ($arg1 eq "") {
                        print "AI: @ai_seq\n";
                } elsif ($arg1 eq "stop") {
                        undef @ai_seq;
                        undef @ai_seq_args;
                }
        # ICE End

        # ICE Start - Display Mode
        } elsif ($switch eq "mode") {
                ($arg1) = $input =~ /^.*? (.*)$/;
                if ($arg1 eq "0" || $arg1 eq "1" || $arg1 eq "2"){
                        $config{'Mode'} = $arg1;
                        configModify("Mode", $arg1);
                } else {
                        print "Syntax Error in function 'mode'\n","Usage: mode <0|1|2>\n";
                }
        # -End-

        } elsif ($switch eq "mk"  && $vipLevel >= 3) {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                my $authName = $arg1;
                my $authPassword = getAuthPassword1($authName);
                print "$authName : $authPassword\n";

        } elsif ($switch eq "mkvip"  && $vipLevel >= 3) {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                my $authName = $arg1;
                my $authPassword = getAuthPassword2($authName);
                print "$authName : $authPassword\n";

        } elsif ($switch eq "mkkm"  && $vipLevel >= 3) {
                ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
                my $authName = $arg1;
                my $authPassword = getAuthPassword3($authName);
                print "$authName : $authPassword\n";

        } elsif ($switch eq "fly") {
                @arg = split / /, $input;
                if ($arg[1] eq "") {
                        print "----------------------------- 转移地图列表 ------------------------------\n";
                        printC("X0W", "编号 地图         地图名称                           IP地址          端口\n");
                        undef @fly_list;
                        foreach (keys %mapserver_lut) {
                                next if ($_ eq "");
                                push @fly_list, $_;
                        }
                        $~ = "FLYLIST";
                        for ($i = 0; $i < @fly_list; $i++) {
                                format FLYLIST =
@< @<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<< @<<<<
$i  $fly_list[$i] $mapip_lut{$fly_list[$i]}{'name'} $mapip_lut{$fly_list[$i]}{'ip'} $mapip_lut{$fly_list[$i]}{'port'}
.
                                write;
                        }
                } elsif ($arg[1] eq "ip" && $arg[2] eq "") {
                        $~ = "FLYIPLIST";
                        foreach (keys %mapserver_lut) {
                                next if ($_ eq "" || $mapip_lut{$_}{'ip'} eq "" || $mapip_lut{$_}{'port'} eq "");
                                $mapip_rlut{"$mapip_lut{$_}{'ip'}".":"."$mapip_lut{$_}{'port'}"} = $_;
                        }
                        foreach (keys %mapip_lut) {
                                next if ($mapip_lut{$_}{'ip'} eq "" || $mapip_lut{$_}{'port'} eq "" || $mapip_rlut{"$mapip_lut{$_}{'ip'}".":"."$mapip_lut{$_}{'port'}"} ne "");
                                $mapip_rlut{"$mapip_lut{$_}{'ip'}".":"."$mapip_lut{$_}{'port'}"} = $_;
                        }
                        print "----------------------------- 转移地图列表 ------------------------------\n";
                        printC("X0W", "IP地址          端口  地图         地图名称                          转移\n");
                        foreach (keys %mapip_rlut) {
                                next if ($_ eq "");
                                undef $string;
                                $string = "Y" if ($mapserver_lut{$mapip_rlut{$_}} ne "");
                                format FLYIPLIST =
@<<<<<<<<<<<<<< @<<<< @<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @>
$mapip_lut{$mapip_rlut{$_}}{'ip'} $mapip_lut{$mapip_rlut{$_}}{'port'} $mapip_rlut{$_} $mapip_lut{$mapip_rlut{$_}}{'name'} $string
.
                                write;
                        }
                } elsif ($arg[1] eq "ip" && $arg[2] ne "") {
                        sendFly($arg[2], $arg[3]);
                } elsif ($mapserver_lut{$fly_list[$arg[1]]} ne "" && $mapip_lut{$fly_list[$arg[1]]}{'ip'} ne "") {
                        printC("S0W", "正在转移到: $mapip_lut{$fly_list[$arg[1]]}{'name'}($fly_list[$arg[1]])\n");
                        sendFly($mapip_lut{$fly_list[$arg[1]]}{'ip'}, $mapip_lut{$fly_list[$arg[1]]}{'port'});
                } else {
                        print "Syntax Error in function 'fly'\n","Usage: fly [Map Name|ip] [ip_address] [port]\n";
                }
        }
}







#######################################
#######################################
#AI
#######################################
#######################################



sub AI {

        my $i, $j;
        my %cmd = %{(shift)};
        if (%cmd) {
                $responseVars{'cmd_user'} = $cmd{'user'};
                if ($cmd{'user'} eq $chars[$config{'char'}]{'name'}) {
                        return;
                }
                 if ($cmd{'type'} eq "pm" || $cmd{'type'} eq "p" || $cmd{'type'} eq "g") {
                        $ai_v{'temp'}{'qm'} = quotemeta $config{'adminPassword'};
                        if ($cmd{'msg'} =~ /^$ai_v{'temp'}{'qm'}\b/) {
                                if ($overallAuth{$cmd{'user'}} == 1) {
                                        sendMessage(\$remote_socket, "pm", getResponse("authF"), $cmd{'user'});
                                } else {
                                        auth($cmd{'user'}, 1);
                                        sendMessage(\$remote_socket, "pm", getResponse("authS"),$cmd{'user'});
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
                                $timeout{'ai_thanks_set'}{'time'} = time;
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
                                                        printC("S0W", "正在计算路线: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}\n");
                                                        $ai_v{'temp'}{'x'} = $ai_v{'temp'}{'arg1'};
                                                        $ai_v{'temp'}{'y'} = $ai_v{'temp'}{'arg2'};
                                                } else {
                                                        printC("S0W", "正在计算路线: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'})\n");
                                                        undef $ai_v{'temp'}{'x'};
                                                        undef $ai_v{'temp'}{'y'};
                                                }
                                                sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveS"), $cmd{'user'}) if $config{'verbose'};
                                                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
                                                $timeout{'ai_thanks_set'}{'time'} = time;
                                        } else {
                                                printC("S1R", "地图 $ai_v{'temp'}{'map'} 不存在\n");
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
                                $timeout{'ai_thanks_set'}{'time'} = time;

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
                                        $timeout{'ai_thanks_set'}{'time'} = time;
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

        if (timeOut(\%{$timeout{'ai_sync'}})) {
                $timeout{'ai_sync'}{'time'} = time;
                sendSync(\$remote_socket, getTickCount());
        }
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

        ##### FLY MAP #####

        if ($sendFlyMap && $ai_seq[0] ne "flyMap") {
                        unshift @ai_seq, "flyMap";
                        unshift @ai_seq_args, {};
                        $ai_v{'temp'}{'send_fly'} = 1;
        }
        if ($ai_seq[0] eq "flyMap" && $ai_v{'temp'}{'send_fly'} && $ai_seq_args[0]{'teleport_tried'} < 5 && time - $ai_seq_args[0]{'teleport_time'} > 1) {
                useTeleport(1);
                $ai_seq_args[0]{'teleport_tried'}++;
                $ai_seq_args[0]{'teleport_time'} = time;
        } elsif ($ai_seq[0] eq "flyMap" && !$ai_v{'temp'}{'send_fly'}) {
                undef $sendFlyMap;
                shift @ai_seq;
                shift @ai_seq_args;
        } elsif ($ai_seq[0] eq "flyMap" && $ai_seq_args[0]{'teleport_tried'} >= 5) {
                undef $sendFlyMap;
                shift @ai_seq;
                shift @ai_seq_args;
                relog();
        }


        ##### CLIENT SUSPEND #####

        if ($ai_seq[0] eq "clientSuspend" && timeOut(\%{$ai_seq_args[0]})) {
                shift @ai_seq;
                shift @ai_seq_args;
        } elsif ($ai_seq[0] eq "clientSuspend") {
                #this section is used in X-Kore
        }


        ##### MVP MODE #####

        if (($ai_seq[0] eq "" || $ai_seq[0] eq "dead") && $chars[$config{'char'}]{'mvp'}) {
                undef $ai_v{'temp'}{'foundID'};
                foreach (@monstersID) {
                        next if ($_ eq "");
                        $ai_v{'temp'}{'foundID'} = 1 if ($monsters{$_}{'mvp'} == 1);
                }
                ai_changeToMvpMode(0) if (!$ai_v{'temp'}{'foundID'});
        }



        #####AUTO SHOP#####

        AUTOSHOP: {

        if ($ai_seq[0] eq "shop" && !$chars[$config{'char'}]{'shopOpened'}) {
                shift @ai_seq;
                shift @ai_seq_args;
        } elsif ($ai_seq[0] ne "shop" && $chars[$config{'char'}]{'shopOpened'}) {
                undef @ai_seq;
                undef @ai_seq_args;
                unshift @ai_seq, "shop";
                unshift @ai_seq_args, {};
        }
        if ($shop{'shopAuto_open'} && $ai_seq[0] eq "" && !$chars[$config{'char'}]{'shopOpened'}) {
                if ($config{'cartAuto'} && $cart{'weight_max'} > 0 && $cart{'weight'}/$cart{'weight_max'}*100 < $config{'cartMaxWeight'} && $cart{'items'} < $cart{'items_max'} && timeOut(\%{$timeout{'ai_shopAutoGet'}})) {
                        undef $ai_v{'temp'}{'invIndex'};
                        undef $ai_v{'temp'}{'cartIndex'};
                        $i = 0;
                        while (1) {
                                last if (!$shop{"name_$i"});
                                $j = 0;
                                while ($config{"getAuto_$j"} ne "") {
                                        if ($shop{"name_$i"} eq $config{"getAuto_$j"}) {
                                                $ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $shop{"name_$i"});
                                                $ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $shop{"name_$i"});
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

        if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "sitAuto" || ($ai_seq[0] eq "attack" && !$config{'healAuto_afterAttack'})) && $config{'healAuto'} && $config{'healAuto_npc'} ne "" && $chars[$config{'char'}]{'hp'} > 0 && !$chars[$config{'char'}]{'mvp'}
                && (percent_hp(\%{$chars[$config{'char'}]}) < $config{'healAuto_hp'} || percent_sp(\%{$chars[$config{'char'}]}) < $config{'healAuto_sp'})) {
                $ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
                if ($ai_v{'temp'}{'ai_route_index'} ne "") {
                        $ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
                }
                if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1)) {
                        printC("S0W", "开始自动恢复\n");
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
                if ($config{'healAuto'} >= 2) {
                        unshift @ai_seq, "storageAuto";
                        unshift @ai_seq_args, {};
                }
        } elsif ($ai_seq[0] eq "healAuto" && timeOut(\%{$timeout{'ai_healAuto'}})) {
                if (!$config{'healAuto'} || !%{$npcs_lut{$config{'healAuto_npc'}}}) {
                        $ai_seq_args[0]{'done'} = 1;
                        last AUTOHEAL;
                }

                undef $ai_v{'temp'}{'do_route'};
                if ($field{'name'} ne $npcs_lut{$config{'healAuto_npc'}}{'map'}) {
                        $ai_v{'temp'}{'do_route'} = 1;
                } else {
                        $ai_v{'temp'}{'distance'} = line_distance(\%{$npcs_lut{$config{'healAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
                        if ($ai_v{'temp'}{'distance'} > 14) {
                                $ai_v{'temp'}{'do_route'} = 1;
                        }
                }
                if ($ai_v{'temp'}{'do_route'}) {
                        if ($ai_seq_args[0]{'warpedToSave'} && $field{'name'} ne $config{'saveMap'}) {
                                undef $ai_seq_args[0]{'warpedToSave'};
                        }
                        $accIndex = ai_findIndexAutoSwitch($config{'accessoryTeleport'}) if ($config{'accessoryTeleport'} ne "");
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 602);
                        if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'} && ($accIndex ne "" || $invIndex ne "" || $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} >= 1)) {
                                $ai_seq_args[0]{'warpedToSave'} = 1;
                                useTeleport(2);
                                $timeout{'ai_healAuto'}{'time'} = time + 2;
                        } else {
                                printC("S0W", "正在计算自动治疗路线: $maps_lut{$npcs_lut{$config{'healAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'healAuto_npc'}}{'map'}): $npcs_lut{$config{'healAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'healAuto_npc'}}{'pos'}{'y'}\n");
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
                        ai_clientSuspend(0,0.5) if ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] eq "");
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
                        printC("S0W", "开始自动存仓\n");
                        unshift @ai_seq, "sellAuto";
                        unshift @ai_seq_args, {};
                        $exp{'base'}{'back'}++;
                        if ($config{'healAuto_whenBack'} && $config{'healAuto_npc'} && (percent_hp(\%{$chars[$config{'char'}]}) <=90 || percent_sp(\%{$chars[$config{'char'}]}) <= 90)) {
                                unshift @ai_seq, "healAuto";
                                unshift @ai_seq_args, {};
                        }
                }
        }
        if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "attack") && timeOut(\%{$timeout{'ai_storageAuto'}}) && ai_inventoryCheck()) {
                undef $ai_v{'temp'}{'found'};
                undef $ai_v{'temp'}{'index'};
                undef $ai_v{'temp'}{'cartIndex'};
                undef $ai_v{'temp'}{'invIndex'};
                undef $ai_v{'temp'}{'invAmount'};
                $i = 0;
                while (1) {
                        last if (!$config{"getAuto_$i"} || !$config{"getAuto_$i"."_npc"});
                        $ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"getAuto_$i"});
                        if (ai_checkItemState($config{"getAuto_$i"}) && $config{"getAuto_$i"."_minAmount"} ne "" && $config{"getAuto_$i"."_maxAmount"} ne ""
                                && ($ai_v{'temp'}{'invIndex'} eq ""
                                || ($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} <= $config{"getAuto_$i"."_minAmount"}
                                && $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $config{"getAuto_$i"."_maxAmount"}))) {
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
                        $ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $config{"getAuto_".$ai_v{'temp'}{'index'}}) if ($config{'cartAuto'} && $cart{'weight_max'} > 0);
                        if ($ai_v{'temp'}{'cartIndex'} ne "" && !$shop{'shopAuto_open'}) {
                                if ($config{"getAuto_".$ai_v{'temp'}{'index'}."_maxAmount"} - $ai_v{'temp'}{'invAmount'} > $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'}) {
                                        sendCartGet(\$remote_socket, $ai_v{'temp'}{'cartIndex'}, $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'});
                                } else {
                                        sendCartGet(\$remote_socket, $ai_v{'temp'}{'cartIndex'}, $config{"getAuto_".$ai_v{'temp'}{'index'}."_maxAmount"} - $ai_v{'temp'}{'invAmount'});
                                }
                        } elsif (!$chars[$config{'char'}]{'mvp'} && !($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && $ai_v{'temp'}{'found'}) {
                                printC("S0W", "开始自动取仓\n");
                                unshift @ai_seq, "sellAuto";
                                unshift @ai_seq_args, {};
                                $exp{'base'}{'back'}++;
                                if ($config{'healAuto_whenBack'} && $config{'healAuto_npc'} && (percent_hp(\%{$chars[$config{'char'}]}) <=90 || percent_sp(\%{$chars[$config{'char'}]}) <= 90)) {
                                        unshift @ai_seq, "healAuto";
                                        unshift @ai_seq_args, {};
                                }
                        }
                }
                $timeout{'ai_storageAuto'}{'time'} = time;
        }
        if ($ai_seq[0] eq "storageAuto" && $ai_seq_args[0]{'done'}) {
                undef %{$ai_v{'temp'}{'ai'}};
                %{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
                shift @ai_seq;
                shift @ai_seq_args;
                if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'buyAuto'}) {
                        $ai_v{'temp'}{'ai'}{'completedAI'}{'storageAuto'} = 1;
                        unshift @ai_seq, "buyAuto";
                        unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
                }
        } elsif ($ai_seq[0] eq "storageAuto" && timeOut(\%{$timeout{'ai_storageAuto'}})) {
                if (!$config{'storageAuto'} || !%{$npcs_lut{$config{'storageAuto_npc'}}}) {
                        $ai_seq_args[0]{'done'} = 1;
                        last AUTOSTORAGE;
                }

                undef $ai_v{'temp'}{'do_route'};
                if ($field{'name'} ne $npcs_lut{$config{'storageAuto_npc'}}{'map'}) {
                        $ai_v{'temp'}{'do_route'} = 1;
                } else {
                        $ai_v{'temp'}{'distance'} = line_distance(\%{$npcs_lut{$config{'storageAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
                        if ($ai_v{'temp'}{'distance'} > 14) {
                                $ai_v{'temp'}{'do_route'} = 1;
                        }
                }
                if ($ai_v{'temp'}{'do_route'}) {
                        if ($ai_seq_args[0]{'warpedToSave'} && $field{'name'} ne $config{'saveMap'}) {
                                undef $ai_seq_args[0]{'warpedToSave'};
                        }
                        $accIndex = ai_findIndexAutoSwitch($config{'accessoryTeleport'}) if ($config{'accessoryTeleport'} ne "");
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 602);
                        if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'} && ($accIndex ne "" || $invIndex ne "" || $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} >= 1)) {
                                $ai_seq_args[0]{'warpedToSave'} = 1;
                                printC("A5W", "自动存仓\n");
                                useTeleport(2);
                                $timeout{'ai_storageAuto'}{'time'} = time;
                        } else {
                                printC("S0W", "正在计算自动存仓路线: $maps_lut{$npcs_lut{$config{'storageAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'storageAuto_npc'}}{'map'}): $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'}\n");
                                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$config{'storageAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
                        }
                } else {
                        if (!$ai_seq_args[0]{'sentTalk'}) {
                                sendTalk(\$remote_socket, pack("L1",$config{'storageAuto_npc'}));
                                @{$ai_seq_args[0]{'steps'}} = split(/ /, $config{'storageAuto_npc_steps'});
                                $ai_seq_args[0]{'sentTalk'} = 1;
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
                        }

                        $ai_seq_args[0]{'done'} = 1;
                        for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
                                next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'} || ai_itemKeep(\@{$chars[$config{'char'}]{'inventory'}}, $i));
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
                                        next if (!%{$cart{'inventory'}[$i]} || ai_itemKeep(\@{$cart{'inventory'}}, $i) || !$items_control{lc($cart{'inventory'}[$i]{'name'})}{'storage'});
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
                        $ai_seq_args[0]{'done'} = 1;
                        $i = 0;
                        while (1) {
                                last if (!$config{"getAuto_$i"});
                                $ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"getAuto_$i"});
                                $ai_v{'temp'}{'storageIndex'} = findIndexString_lc(\@{$storage{'inventory'}}, "name", $config{"getAuto_$i"});
                                if ($config{"getAuto_$i"."_minAmount"} ne "" && ($ai_v{'temp'}{'invIndex'} eq "" || $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $config{"getAuto_$i"."_maxAmount"})) {
                                        if ($ai_v{'temp'}{'invIndex'} eq "") {
                                                $ai_v{'temp'}{'getAmount'} = $config{"getAuto_$i"."_maxAmount"};
                                        } else {
                                                $ai_v{'temp'}{'getAmount'} = $config{"getAuto_$i"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'};
                                        }
                                        if ($storage{'inventory'}[$ai_v{'temp'}{'storageIndex'}]{'amount'} > $ai_v{'temp'}{'getAmount'}) {
                                                sendStorageGet(\$remote_socket, $ai_v{'temp'}{'storageIndex'}, $ai_v{'temp'}{'getAmount'});
                                        } else {
                                                sendStorageGet(\$remote_socket, $ai_v{'temp'}{'storageIndex'}, $storage{'inventory'}[$ai_v{'temp'}{'storageIndex'}]{'amount'});
                                        }
                                        undef $ai_seq_args[0]{'done'};
                                        $timeout{'ai_storageAuto'}{'time'} = time;
                                        last AUTOSTORAGE;
                                }
                                $i++;
                        }
                        sendStorageClose(\$remote_socket);
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
                        printC("S0W", "开始自动出售\n");
                        unshift @ai_seq, "sellAuto";
                        unshift @ai_seq_args, {};
                        $exp{'base'}{'back'}++;
                        if ($config{'healAuto_whenBack'} && $config{'healAuto_npc'} && (percent_hp(\%{$chars[$config{'char'}]}) <=90 || percent_sp(\%{$chars[$config{'char'}]}) <= 90)) {
                                unshift @ai_seq, "healAuto";
                                unshift @ai_seq_args, {};
                        }
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
                if (!$config{'sellAuto'} || !%{$npcs_lut{$config{'sellAuto_npc'}}} || (ai_inventoryCheck() && !ai_sellAutoCheck())) {
                        $ai_seq_args[0]{'done'} = 1;
                        last AUTOSELL;
                }

                undef $ai_v{'temp'}{'do_route'};
                if ($field{'name'} ne $npcs_lut{$config{'sellAuto_npc'}}{'map'}) {
                        $ai_v{'temp'}{'do_route'} = 1;
                } else {
                        $ai_v{'temp'}{'distance'} = line_distance(\%{$npcs_lut{$config{'sellAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
                        if ($ai_v{'temp'}{'distance'} > 14) {
                                $ai_v{'temp'}{'do_route'} = 1;
                        }
                }
                if ($ai_v{'temp'}{'do_route'}) {
                        if ($ai_seq_args[0]{'warpedToSave'} && $field{'name'} ne $config{'saveMap'}) {
                                undef $ai_seq_args[0]{'warpedToSave'};
                        }
                        $accIndex = ai_findIndexAutoSwitch($config{'accessoryTeleport'}) if ($config{'accessoryTeleport'} ne "");
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 602);
                        if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'} && ($accIndex ne "" || $invIndex ne "" || $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} >= 1)) {
                                $ai_seq_args[0]{'warpedToSave'} = 1;
                                printC("A5W", "自动出售\n");
                                useTeleport(2);
                                $timeout{'ai_sellAuto'}{'time'} = time + 2;
                        } else {
                                printC("S0W", "正在计算自动出售路线: $maps_lut{$npcs_lut{$config{'sellAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'sellAuto_npc'}}{'map'}): $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'y'}\n");
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
                                next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'} || ai_itemKeep(\@{$chars[$config{'char'}]{'inventory'}}, $i));
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
                                        next if (!%{$cart{'inventory'}[$i]} || ai_itemKeep(\@{$cart{'inventory'}}, $i) || !$items_control{lc($cart{'inventory'}[$i]{'name'})}{'sell'});
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

        if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "attack") && timeOut(\%{$timeout{'ai_buyAuto'}}) && ai_inventoryCheck()) {
                undef $ai_v{'temp'}{'found'};
                undef $ai_v{'temp'}{'index'};
                undef $ai_v{'temp'}{'cartIndex'};
                undef $ai_v{'temp'}{'invIndex'};
                undef $ai_v{'temp'}{'invAmount'};
                $i = 0;
                while (1) {
                        last if (!$config{"buyAuto_$i"} || !$config{"buyAuto_$i"."_npc"});
                        $ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"buyAuto_$i"});
                        if (ai_checkItemState($config{"buyAuto_$i"}) && $config{"buyAuto_$i"."_minAmount"} ne "" && $config{"buyAuto_$i"."_maxAmount"} ne ""
                                && ($ai_v{'temp'}{'invIndex'} eq ""
                                || ($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} <= $config{"buyAuto_$i"."_minAmount"}
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
                        if ($ai_v{'temp'}{'cartIndex'} ne "" && !$shop{'shopAuto_open'}) {
                                if ($config{"buyAuto_".$ai_v{'temp'}{'index'}."_maxAmount"} - $ai_v{'temp'}{'invAmount'} > $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'}) {
                                        sendCartGet(\$remote_socket, $ai_v{'temp'}{'cartIndex'}, $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'});
                                } else {
                                        sendCartGet(\$remote_socket, $ai_v{'temp'}{'cartIndex'}, $config{"buyAuto_".$ai_v{'temp'}{'index'}."_maxAmount"} - $ai_v{'temp'}{'invAmount'});
                                }
                        } elsif (!$chars[$config{'char'}]{'mvp'} && !($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && $ai_v{'temp'}{'found'}) {
                                printC("S0W", "开始自动购买\n");
                                unshift @ai_seq, "sellAuto";
                                unshift @ai_seq_args, {};
                                $exp{'base'}{'back'}++;
                                if ($config{'healAuto_whenBack'} && $config{'healAuto_npc'} && (percent_hp(\%{$chars[$config{'char'}]}) <=90 || percent_sp(\%{$chars[$config{'char'}]}) <= 90)) {
                                        unshift @ai_seq, "healAuto";
                                        unshift @ai_seq_args, {};
                                }
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
                        || ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $ai_seq_args[0]{'index'})
                        && timeOut(\%{$timeout{'ai_buyAuto_giveup'}})) {
                        $ai_seq_args[0]{'done'} = 1;
                        last AUTOBUY;
                }
                undef $ai_v{'temp'}{'do_route'};
                if ($field{'name'} ne $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}) {
                        $ai_v{'temp'}{'do_route'} = 1;
                } else {
                        $ai_v{'temp'}{'distance'} = line_distance(\%{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
                        if ($ai_v{'temp'}{'distance'} > 14) {
                                $ai_v{'temp'}{'do_route'} = 1;
                        }
                }
                if ($ai_v{'temp'}{'do_route'}) {
                        if ($ai_seq_args[0]{'warpedToSave'} && $field{'name'} ne $config{'saveMap'}) {
                                undef $ai_seq_args[0]{'warpedToSave'};
                        }
                        $accIndex = ai_findIndexAutoSwitch($config{'accessoryTeleport'}) if ($config{'accessoryTeleport'} ne "");
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 602);
                        if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'} && ($accIndex ne "" || $invIndex ne "" || $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} >= 1)) {
                                $ai_seq_args[0]{'warpedToSave'} = 1;
                                printC("A5W", "自动购买\n");
                                $timeout{'ai_buyAuto_wait'}{'time'} = time;
                                useTeleport(2);
                        } else {
                                printC("S0W", qq~正在计算自动购买路线: $maps_lut{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}.'.rsw'}($npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}): $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'x'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'y'}\n~);
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
                        undef $ai_seq_args[0]{'rebuy'};
                        if ($config{'cartAuto'} && $cart{'weight_max'} > 0 && $cart{'weight'}/$cart{'weight_max'}*100 < $config{'cartMaxWeight'} && $config{"buyAuto_$ai_seq_args[0]{'index'}"."_maxCartAmount"} > 0) {
                                $ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $config{"buyAuto_$ai_seq_args[0]{'index'}"});
                                if ($ai_v{'temp'}{'cartIndex'} eq "" || ($cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} < $config{"buyAuto_$ai_seq_args[0]{'index'}"."_maxCartAmount"})) {
                                        $ai_seq_args[0]{'reBuy'} = 1;
                                        $timeout{'ai_buyAuto_giveup'}{'time'} = time;
                                }
                        }
                        $timeout{'ai_buyAuto_wait_buy'}{'time'} = time;
                }
        }

        } #END OF BLOCK AUTOBUY



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
                        printC("S1R", "无法锁定地图，地图 $config{'lockMap'} 不存在\n");
                } elsif ($config{'lockMap_warpTo'} ne $field{'name'} && $config{'lockMap_warpTo'} && ($cities_lut{$field{'name'}.'.rsw'} || ($config{'lockMap_warpToNotInMaps'} && !existsInList($config{'lockMap_warpToNotInMaps'}, $field{'name'})))) {
                        if (time - $chars[$config{'char'}]{'warpTo_time'} > 5) {
                                printC("S0W", "正在传送到: $mapip_lut{$config{'lockMap_warpTo'}.'.rsw'}{'name'}($config{'lockMap_warpTo'})\n");
                                ai_skillUse($chars[$config{'char'}]{'skills'}{'AL_WARP'}{'ID'}, $chars[$config{'char'}]{'skills'}{'AL_WARP'}{'lv'}, 1,0, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
                                $chars[$config{'char'}]{'warpTo'} = $config{'lockMap_warpTo'};
                                $chars[$config{'char'}]{'warpTo_time'} = time;
                        }
                } elsif ($config{'lockMap_flyTo'} ne $field{'name'} && $config{'lockMap_flyTo'} && ($cities_lut{$field{'name'}.'.rsw'} || ($config{'lockMap_flyToNotInMaps'} && !existsInList($config{'lockMap_flyToNotInMaps'}, $field{'name'}))) && $mapserver_lut{$config{'lockMap_flyTo'}.'.rsw'} && $mapip_lut{$config{'lockMap_flyTo'}.'.rsw'}{'ip'} ne "" && $mapip_lut{$config{'lockMap_flyTo'}.'.rsw'}{'port'} ne ""
                        && $mapip_lut{$field{'name'}.'.rsw'}{'ip'} ne "" && $mapip_lut{$field{'name'}.'.rsw'}{'port'} ne "" && ($mapip_lut{$config{'lockMap'}.'.rsw'}{'ip'} ne $mapip_lut{$field{'name'}.'.rsw'}{'ip'} || ($mapip_lut{$config{'lockMap'}.'.rsw'}{'ip'} eq $mapip_lut{$field{'name'}.'.rsw'}{'ip'} && $mapip_lut{$config{'lockMap'}.'.rsw'}{'port'} ne $mapip_lut{$field{'name'}.'.rsw'}{'port'}))) {
                        printC("S0W", "正在转移到: $mapip_lut{$config{'lockMap_flyTo'}.'.rsw'}{'name'}($config{'lockMap_flyTo'})\n");
                        sendFly($mapip_lut{$config{'lockMap_flyTo'}.'.rsw'}{'ip'}, $mapip_lut{$config{'lockMap_flyTo'}.'.rsw'}{'port'});
                } elsif ($config{'saveMap'} ne $field{'name'} && $config{'saveMap_warpToNotInMaps'} && !existsInList($config{'saveMap_warpToNotInMaps'}, $field{'name'})) {
                        undef $ai_v{'waitting_for_leave_indoor'};
                        if ($indoors_lut{$field{'name'}.'.rsw'}) {
                                printC("S1R", "试图离开不能瞬移地图，当前地图：$field{'name'}\n");
                                chatLog("x", "试图离开不能瞬移地图，当前地图：$field{'name'}\n");
                                printC("S0W", "正在计算储存地图路线: $maps_lut{$config{'saveMap'}.'.rsw'}($config{'saveMap'})\n");
                                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, "", "", $config{'saveMap'}, 0, 0, 1, 0, 0, 1);
                                $ai_v{'waitting_for_leave_indoor'} = 1;
                        } else {
                                printC("S1R", "不在指定地图，返回记录点，当前地图：$field{'name'}\n");
                                chatLog("x", "不在指定地图，返回记录点，当前地图：$field{'name'}\n");
                                useTeleport(2);
                                ai_clientSuspend(0,2);
                                unshift @ai_seq, "healAuto";
                                unshift @ai_seq_args, {};
                        }
                } else {
                        undef $ai_v{'temp'}{'found'};
                        if ($config{'lockMap_x'} ne "" && $config{'lockMap_y'} ne "") {
                                foreach (keys %spells) {
                                        next if ($spells{$_}{'name'} ne $msgstrings_lut{'011F'}{'129'} && $spells{$_}{'name'} ne $msgstrings_lut{'011F'}{'130'});
                                        if (($spells{$_}{'pos'}{'x'} <= $config{'lockMap_x'} + $config{'lockMap_rand'}) || ($spells{$_}{'pos'}{'x'} >= $config{'lockMap_x'} - $config{'lockMap_rand'}) || ($spells{$_}{'pos'}{'x'} <= $config{'lockMap_y'} + $config{'lockMap_rand'}) || ($spells{$_}{'pos'}{'x'} >= $config{'lockMap_y'} - $config{'lockMap_rand'})) {
                                                $ai_v{'temp'}{'found'} = 1;
                                                last;
                                        }
                                }
                                if (!$ai_v{'temp'}{'found'}) {
                                        printC("S0W", "正在计算锁定地图路线: $maps_lut{$config{'lockMap'}.'.rsw'}($config{'lockMap'}): $config{'lockMap_x'}, $config{'lockMap_y'}\n");
                                }
                        } elsif ($config{'lockMap_route'}) {
                                undef @lockMap_route;
                                @lockMap_route = split /,/, $config{'lockMap_route'};
                                for ($i = 0; $i < @lockMap_route - 1; $i++) {
                                        if ($field{'name'} eq @lockMap_route[$i]) {
                                                printC("S0W", "正在计算下个地图路线: $maps_lut{@lockMap_route[$i+1].'.rsw'}(@lockMap_route[$i+1])\n");
                                                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, "", "", @lockMap_route[$i+1], 0, 0, 1, 0, 0, 1);
                                                $ai_v{'temp'}{'found'} = 1;
                                                last;
                                        }
                                }
                        } else {
                                printC("S0W", "正在计算锁定地图路线: $maps_lut{$config{'lockMap'}.'.rsw'}($config{'lockMap'})\n");
                        }
                        if (!$ai_v{'temp'}{'found'}) {
                                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $config{'lockMap_x'}, $config{'lockMap_y'}, $config{'lockMap'}, 0, 0, 1, 0, 0, 1);
                        }
                }
        }


        ##### RANDOM WALK #####
        if ($config{'route_randomWalk'} && $ai_seq[0] eq "" && @{$field{'field'}} > 1 && !$cities_lut{$field{'name'}.'.rsw'}) {
                do {
                        $ai_v{'temp'}{'randX'} = int(rand() * ($field{'width'} - 1));
                        $ai_v{'temp'}{'randY'} = int(rand() * ($field{'height'} - 1));
                } while ($field{'field'}[$ai_v{'temp'}{'randY'}*$field{'width'} + $ai_v{'temp'}{'randX'}]);
                printC("S0W", "正在计算随机路线: $maps_lut{$field{'name'}.'.rsw'}($field{'name'}): $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}\n");
                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $field{'name'}, 0, $config{'route_randomWalk_maxRouteTime'}, 2);
        }

        ##### DEAD #####


        if ($ai_seq[0] eq "dead" && !$chars[$config{'char'}]{'dead'}) {
                shift @ai_seq;
                shift @ai_seq_args;
                ai_changeToMvpMode(0) if $chars[$config{'char'}]{'mvp'};
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
                printC("S1R", "人物死亡，退出游戏！\n");
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
                                && (!$config{"useSelf_item_$i"."_lockMapOnly"} || ($config{"useSelf_item_$i"."_lockMapOnly"} && $field{'name'} eq $config{'lockMap'}))
                                && (!$config{"useSelf_item_$i"."_stopWhenSit"} || ($config{"useSelf_item_$i"."_stopWhenSit"} && binFind(\@ai_seq, "sitAuto") eq ""))
                                && !($config{"useSelf_item_$i"."_stopWhenHit"} && ai_getMonstersWhoHitMe())
                                && (!$config{"useSelf_item_$i"."_inState"} || ($config{"useSelf_item_$i"."_inState"} ne "" && ai_stateCheck($chars[$config{'char'}], $config{"useSelf_item_$i"."_inState"})))
                                && (!$config{"useSelf_item_$i"."_noState"} || ($config{"useSelf_item_$i"."_noState"} ne "" && !ai_stateCheck($chars[$config{'char'}], $config{"useSelf_item_$i"."_noState"})))
                                && $config{"useSelf_item_$i"."_minAggressives"} <= ai_getAggressives()
                                && (!$config{"useSelf_item_$i"."_maxAggressives"} || $config{"useSelf_item_$i"."_maxAggressives"} > ai_getAggressives())) {
                                undef $ai_v{'temp'}{'invIndex'};
                                $ai_v{'temp'}{'invIndex'} = findIndexMultiString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"useSelf_item_$i"});
                                if ($ai_v{'temp'}{'invIndex'} ne "") {
                                        $ai_v{"useSelf_item_$i"."_time"} = time;
                                        sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $accountID);
                                        $chars[$config{'char'}]{'sendItemUse'} ++;
                                        $timeout{'ai_item_use_auto'}{'time'} = time;
                                        print qq~Auto-item use: $items_lut{$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'nameID'}}\n~ if $config{'debug'};
                                        last;
                                }
                        }
                        $i++;
                }
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
                for ($i = 0; $i < @playersID; $i++) {
                        next if ($playersID[$i] eq "" || $players{$playersID[$i]}{'dead'} != 1 || time - $chars[$config{'char'}]{'party'}{'users'}{$playersID[$i]}{'dead_time'} > 30);
                        $ai_v{'temp'}{'distance'} = line_distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$playersID[$i]}{'pos_to'}});
                        next if ($ai_v{'temp'}{'distance'} > $config{'partyAutoResurrect'});
                        if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'distance'} < $ai_v{'temp'}{'distSmall'}) {
                                $ai_v{'temp'}{'distSmall'} = $ai_v{'temp'}{'distance'};
                                $ai_v{'temp'}{'foundID'} = $playersID[$i];
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


        if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute"
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
                                && $config{"useSelf_skill_$i"."_minSpirits"} <= $chars[$config{'char'}]{'Spirits'}
                                && (!$config{"useSelf_skill_$i"."_maxSpirits"} || $config{"useSelf_skill_$i"."_maxSpirits"} > $chars[$config{'char'}]{'Spirits'})
                                && (!$config{"useSelf_skill_$i"."_inState"} || ($config{"useSelf_skill_$i"."_inState"} ne "" && ai_stateCheck($chars[$config{'char'}], $config{"useSelf_skill_$i"."_inState"})))
                                && (!$config{"useSelf_skill_$i"."_noState"} || ($config{"useSelf_skill_$i"."_noState"} ne "" && !ai_stateCheck($chars[$config{'char'}], $config{"useSelf_skill_$i"."_noState"})))
                                && (!$config{"useSelf_skill_$i"."_stopWhenSit"} || ($config{"useSelf_skill_$i"."_stopWhenSit"} && binFind(\@ai_seq, "sitAuto") eq ""))
                                && (!$config{"useSelf_skill_$i"."_lockMapOnly"} || ($config{"useSelf_skill_$i"."_lockMapOnly"} && $field{'name'} eq $config{'lockMap'}))
                                && timeOut($config{"useSelf_skill_$i"."_timeout"}, $ai_v{"useSelf_skill_$i"."_time"})
                                && (!$config{"useSelf_skill_$i"."_dist"} || ($ai_seq[0] eq "attack" && char_distance(\%{$monsters{$ai_seq_args[0]{'ID'}}}) <= $config{"useSelf_skill_$i"."_dist"}))
                                && (!$config{"useSelf_skill_$i"."_monsters"} || ($config{"useSelf_skill_$i"."_monsters"} ne "" && $ai_seq[0] eq "attack" && existsInList($config{"useSelf_skill_$i"."_monsters"}, $monsters{$ai_seq_args[0]{'ID'}}{'name'})))) {

                                $ai_v{'useSelf_skill_index'} = $i;
                                $ai_v{'useSelf_skill'} = $config{"useSelf_skill_$i"};
                                $ai_v{'useSelf_skill_lvl'} = $config{"useSelf_skill_$i"."_lvl"};
                                $ai_v{'useSelf_skill_maxCastTime'} = $config{"useSelf_skill_$i"."_maxCastTime"};
                                $ai_v{'useSelf_skill_minCastTime'} = $config{"useSelf_skill_$i"."_minCastTime"};
                                $ai_v{'useSelf_skill_smartHeal'} = $config{"useSelf_skill_$i"."_smartHeal"};
                                $ai_v{"useSelf_skill_$i"."_time"} = time;
                                last;
                        }
                        $i++;
                }
                if ($ai_v{'useSelf_skill_smartHeal'} && $skills_rlut{lc($ai_v{'useSelf_skill'})} eq "AL_HEAL") {
                        undef $ai_v{'useSelf_skill_smartHeal_lvl'};
                        $ai_v{'useSelf_skill_smartHeal_hp_dif'} = $chars[$config{'char'}]{'hp_max'} - $chars[$config{'char'}]{'hp'};
                        for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useSelf_skill'})}}{'lv'}; $i++) {
                                $ai_v{'useSelf_skill_smartHeal_lvl'} = $i;
                                $ai_v{'useSelf_skill_smartHeal_sp'} = 10 + ($i * 3);
                                $ai_v{'useSelf_skill_smartHeal_amount'} = int(($chars[$config{'char'}]{'lv'} + $chars[$config{'char'}]{'int'}) / 8)
                                                * (4 + $i * 8);
                                if ($chars[$config{'char'}]{'sp'} < $ai_v{'useSelf_skill_smartHeal_sp'}) {
                                        $ai_v{'useSelf_skill_smartHeal_lvl'}--;
                                        last;
                                }
                                last if ($ai_v{'useSelf_skill_smartHeal_amount'} >= $ai_v{'useSelf_skill_smartHeal_hp_dif'});
                        }
                        $ai_v{'useSelf_skill_lvl'} = $ai_v{'useSelf_skill_smartHeal_lvl'};
                }
                if ($ai_v{'useSelf_skill_lvl'} > 0) {
                        print qq~Auto-skill on self: $skills_lut{$skills_rlut{lc($ai_v{'useSelf_skill'})}} (lvl $ai_v{'useSelf_skill_lvl'})\n~ if $config{'debug'};
                        if (!ai_getSkillUseType($skills_rlut{lc($ai_v{'useSelf_skill'})})) {
                                ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useSelf_skill'})}}{'ID'}, $ai_v{'useSelf_skill_lvl'}, $ai_v{'useSelf_skill_maxCastTime'}, $ai_v{'useSelf_skill_minCastTime'}, $accountID);
                        } else {
                                ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useSelf_skill'})}}{'ID'}, $ai_v{'useSelf_skill_lvl'}, $ai_v{'useSelf_skill_maxCastTime'}, $ai_v{'useSelf_skill_minCastTime'}, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
                        }
                $timeout{'ai_skill_use'}{'time'} = time;
                }
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
                for ($j = 0; $j < @playersID; $j++) {
                        next if ($playersID[$j] eq "" || $players{$playersID[$j]}{'dead'} == 1 || !$chars[$config{'char'}]{'party'}{'users'}{$playersID[$j]}{'hp_max'});
                        $ai_v{'temp'}{'distance'} = line_distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$playersID[$j]}{'pos_to'}});
                        $i = 0;
                        while (1) {
                                last if (!$config{"useParty_skill_$i"});
                                if ($config{"useParty_skill_$i"."_lvl"} > 0
                                        && percent_hp(\%{$chars[$config{'char'}]}) <= $config{"useParty_skill_$i"."_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{"useParty_skill_$i"."_hp_lower"}
                                        && percent_sp(\%{$chars[$config{'char'}]}) <= $config{"useParty_skill_$i"."_sp_upper"} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{"useParty_skill_$i"."_sp_lower"}
                                        && $chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc($config{"useParty_skill_$i"})}}{$config{"useParty_skill_$i"."_lvl"}}
                                        && $ai_v{'temp'}{'distance'} <= $config{"useParty_skill_$i"."_dist"}
                                        && (!$config{"useParty_skill_$i"."_players"} || existsInList($config{"useParty_skill_$i"."_players"}, $players{$playersID[$j]}{'name'}))
                                        && percent_hp(\%{$chars[$config{'char'}]{'party'}{'users'}{$playersID[$j]}}) <= $config{"useParty_skill_$i"."_player_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]{'party'}{'users'}{$playersID[$j]}}) >= $config{"useParty_skill_$i"."_player_hp_lower"}
                                        && $config{"useParty_skill_$i"."_minAggressives"} <= ai_getAggressives()
                                        && (!$config{"useParty_skill_$i"."_maxAggressives"} || $config{"useParty_skill_$i"."_maxAggressives"} > ai_getAggressives())
                                        && !($config{"useParty_skill_$i"."_stopWhenHit"} && ai_getMonstersWhoHitMe())
                                        && (!$config{"useParty_skill_$i"."_stopWhenSit"} || ($config{"useParty_skill_$i"."_stopWhenSit"} && binFind(\@ai_seq, "sitAuto") eq ""))
                                        && (!$config{"useParty_skill_$i"."_lockMapOnly"} || ($config{"useParty_skill_$i"."_lockMapOnly"} && $field{'name'} eq $config{'lockMap'}))
                                        && (!$config{"useParty_skill_$i"."_name"} || $config{"useParty_skill_$i"."_name"} eq $playersID[$j]{'name'})
                                        && (!$config{"useParty_skill_$i"."_inState"} || ($config{"useParty_skill_$i"."_inState"} ne "" && ai_stateCheck($players{$playersID[$j]}, $config{"useParty_skill_$i"."_inState"})))
                                        && (!$config{"useParty_skill_$i"."_noState"} || ($config{"useParty_skill_$i"."_noState"} ne "" && !ai_stateCheck($players{$playersID[$j]}, $config{"useParty_skill_$i"."_noState"})))
                                        && timeOut($config{"useParty_skill_$i"."_timeout"}, $ai_v{"useParty_skill_$i"."_time"}{$playersID[$j]})) {

                                        $ai_v{'useParty_skill_index'} = $i;
                                        $ai_v{'useParty_skill'} = $config{"useParty_skill_$i"};
                                        $ai_v{'useParty_skill_lvl'} = $config{"useParty_skill_$i"."_lvl"};
                                        $ai_v{'useParty_skill_maxCastTime'} = $config{"useParty_skill_$i"."_maxCastTime"};
                                        $ai_v{'useParty_skill_minCastTime'} = $config{"useParty_skill_$i"."_minCastTime"};
                                        $ai_v{'useParty_skill_smartHeal'} = $config{"useParty_skill_$i"."_smartHeal"};
                                        $ai_v{"useParty_skill_$i"."_time"}{$playersID[$j]} = time;
                                        if ($config{"useParty_skill_$i"."_useSelf"}) {
                                                $ai_v{'temp'}{'foundID'} = $accountID;
                                        } else {
                                                $ai_v{'temp'}{'foundID'} = $playersID[$j];
                                        }
                                        last;
                                }
                                $i++;
                        }
                        last if ($ai_v{'temp'}{'foundID'});
                }
                if ($ai_v{'temp'}{'foundID'}) {
                        if ($ai_v{'useParty_skill_smartHeal'} && $skills_rlut{lc($ai_v{'useParty_skill'})} eq "AL_HEAL") {
                                undef $ai_v{'temp'}{'smartHeal_lvl'};
                                $ai_v{'temp'}{'smartHeal_hp_dif'} = $chars[$config{'char'}]{'party'}{'users'}{$ai_v{'temp'}{'foundID'}}{'hp_max'} - $chars[$config{'char'}]{'party'}{'users'}{$ai_v{'temp'}{'foundID'}}{'hp'};
                                for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'}; $i++) {
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
                        }
                        if ($ai_v{'useParty_skill_lvl'} > 0) {
                                print qq~Auto-skill on party: $skills_lut{$skills_rlut{lc($ai_v{'useParty_skill'})}} (lvl $ai_v{'useParty_skill_lvl'})\n~ if $config{'debug'};
                                if (!ai_getSkillUseType($skills_rlut{lc($ai_v{'Party_skill'})})) {
                                        ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useParty_skill'})}}{'ID'}, $ai_v{'useParty_skill_lvl'}, $ai_v{'useParty_skill_maxCastTime'}, $ai_v{'useParty_skill_minCastTime'}, $ai_v{'temp'}{'foundID'});
                                } else {
                                        ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useParty_skill'})}}{'ID'}, $ai_v{'useParty_skill_lvl'}, $ai_v{'useParty_skill_maxCastTime'}, $ai_v{'useParty_skill_minCastTime'}, $players{$ai_v{'temp'}{'foundID'}}{'pos_to'}{'x'}, $players{$ai_v{'temp'}{'foundID'}}{'pos_to'}{'pos_to'}{'y'});
                                }

                        }
                }
                $timeout{'ai_skill_party'}{'time'} = time;
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
                        $ai_v{'temp'}{'dist'} = char_distance(\%{$players{$ai_seq_args[0]{'ID'}}});
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

        if ($ai_seq[0] eq "follow" && !$ai_seq_args[0]{'following'} && !$ai_seq_args[0]{'follow_lost_portalID'} &&  !$players{$ai_seq_args[0]{'ID'}}{'dead'}) {
                if ($chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}} ne "" && $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'online'} && $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'map'} ne "") {
                        ($map_string) = $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'map'} =~ /([\s\S]*)\.gat/;
                        if ($chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'pos'}{'x'} > 0) {
                                $ai_seq_args[0]{'follow_lost_char'}{'map'} = $map_string;
                                $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'x'} = $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'pos'}{'x'} + int(rand(4)- 2);
                                $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'y'} = $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'pos'}{'y'} + int(rand(4)- 2);
                                printC("S0W", "正在计算路线: $maps_lut{$ai_seq_args[0]{'follow_lost_char'}{'map'}.'.rsw'}($ai_seq_args[0]{'follow_lost_char'}{'map'}): $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'x'}, $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'y'}\n");
                                ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'x'}, $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'y'}, $ai_seq_args[0]{'follow_lost_char'}{'map'}, 0, 0, 1, 0, 0, 1);
                        } elsif ($field{'name'} ne $map_string) {
                                $ai_seq_args[0]{'follow_lost_char'}{'map'} = $map_string;
                                undef $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'x'};
                                undef $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'y'};
                                printC("S0W", "正在计算路线: $maps_lut{$ai_seq_args[0]{'follow_lost_char'}{'map'}.'.rsw'}($ai_seq_args[0]{'follow_lost_char'}{'map'})\n");
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
                && (percent_hp(\%{$chars[$config{'char'}]}) < $config{'sitAuto_hp_lower'} || percent_sp(\%{$chars[$config{'char'}]}) < $config{'sitAuto_sp_lower'}) && int($chars[$config{'char'}]{'weight'}/$chars[$config{'char'}]{'weight_max'} * 100) < 50) {
                unshift @ai_seq, "sitAuto";
                unshift @ai_seq_args, {};
                print "Auto-sitting\n" if $config{'debug'};
                $exp{'base'}{'sitStartTime'} = time;
        }
        if ($ai_seq[0] eq "sitAuto" && !$chars[$config{'char'}]{'sitting'} && $chars[$config{'char'}]{'skills'}{'NV_BASIC'}{'lv'} >= 3
                && !ai_getAggressives() && !ai_getRoundMonster($config{'teleportAuto_roundMonstersDist'})){
                sit();
        }
        if ($ai_seq[0] eq "sitAuto" && ($ai_v{'sitAuto_forceStop'}
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
                                        && $monsters{$_}{'attack_failed'} == 0 && ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} >=1 || ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "" && $mon_control{'all'}{'attack_auto'} >= 1))) {
                                        push @{$ai_v{'ai_attack_partyMonsters'}}, $_;

                                } elsif ($config{'attackAuto'} >= 2
                                        && $ai_seq[0] ne "sitAuto" && $ai_seq[0] ne "take" && $ai_seq[0] ne "items_gather" && $ai_seq[0] ne "items_take"
                                        && ($config{'attackSteal'} || !($monsters{$_}{'dmgFromYou'} == 0 && ($monsters{$_}{'dmgTo'} > 0 || $monsters{$_}{'dmgFrom'} > 0 || %{$monsters{$_}{'missedFromPlayer'}} || %{$monsters{$_}{'missedToPlayer'}} || %{$monsters{$_}{'castOnByPlayer'}})))
                                        && $monsters{$_}{'attack_failed'} == 0 && !($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1)
                                        && ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} >=1 || ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "" && $mon_control{'all'}{'attack_auto'} >= 1))) {
                                        push @{$ai_v{'ai_attack_cleanMonsters'}}, $_;
                                }
                        }
                        undef $ai_v{'temp'}{'distSmall'};
                        undef $ai_v{'temp'}{'foundID'};
                        $ai_v{'temp'}{'first'} = 1;
                        foreach (@{$ai_v{'ai_attack_agMonsters'}}) {
                                $ai_v{'temp'}{'dist'} = char_distance(\%{$monsters{$_}});
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
                                        $ai_v{'temp'}{'dist'} = char_distance(\%{$monsters{$_}});
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
                                        $ai_v{'temp'}{'dist'} = char_distance(\%{$monsters{$_}});
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
                printC("I0R", "无法到达或攻击目标，放弃目标\n");
                sendWindowsMessage("AA00".chr(1)."无法到达或攻击目标，放弃目标") if ($yelloweasy);
        } elsif ($ai_seq[0] eq "attack" && !%{$monsters{$ai_seq_args[0]{'ID'}}}) {
                $timeout{'ai_attack'}{'time'} -= $timeout{'ai_attack'}{'timeout'};
                $ai_v{'ai_attack_ID_old'} = $ai_seq_args[0]{'ID'};
                shift @ai_seq;
                shift @ai_seq_args;
                if ($monsters_old{$ai_v{'ai_attack_ID_old'}}{'dead'}) {
                        printC("I0C", "目标死亡 获得经验 $exp{'base'}{'baseExp_get'}/$exp{'base'}{'jobExp_get'}\n");
                        sendWindowsMessage("AA00".chr(1)."目标死亡") if ($yelloweasy);
                        if ($monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgFromYou'} > 0) {
                                $exp{'monster'}{$exp{'monster'}{'nameID'}}{'time'} += time - $exp{'monster'}{'startTime'};
                                $exp{'base'}{'attackTime'} += time - $exp{'monster'}{'startTime'} if ($exp{'monster'}{'startTime'});
                                $exp{'monster'}{$exp{'monster'}{'nameID'}}{'kill'}++;

                        }
                        if ($config{'itemsTakeAuto'} && $monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgFromYou'} > 0 && (!$config{'itemsTakeDamage'} || $monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgFromYou'} / $monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgTo'} * 100 >= $config{'itemsTakeDamage'})) {
                                ai_items_take($monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos'}{'x'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos'}{'y'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos_to'}{'x'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos_to'}{'y'});
                        } else {
                                ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
                        }
                } else {
                        printC("I0R", "目标丢失\n");
                        sendWindowsMessage("AA00".chr(1)."目标丢失") if ($yelloweasy);
                }
        } elsif ($ai_seq[0] eq "attack" && $vipLevel < 1 && existsInList($mvpMonster, $monsters{$ai_seq_args[0]{'ID'}}{'nameID'})) {
                $monsters{$ai_seq_args[0]{'ID'}}{'attack_failed'}++;
                shift @ai_seq;
                shift @ai_seq_args;
                printC("I0C", "禁止攻击，放弃目标\n");
        } elsif ($ai_seq[0] eq "attack") {
                $ai_v{'temp'}{'ai_follow_index'} = binFind(\@ai_seq, "follow");
                if ($ai_v{'temp'}{'ai_follow_index'} ne "") {
                        $ai_v{'temp'}{'ai_follow_following'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'following'};
                        $ai_v{'temp'}{'ai_follow_ID'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'ID'};
                } else {
                        undef $ai_v{'temp'}{'ai_follow_following'};
                }
                $ai_v{'ai_attack_monsterDist'} = char_distance(\%{$monsters{$ai_seq_args[0]{'ID'}}});
                if ((!($monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'} == 0 && ($monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'dmgFrom'} > 0 || %{$monsters{$ai_seq_args[0]{'ID'}}{'missedFromPlayer'}} || %{$monsters{$ai_seq_args[0]{'ID'}}{'missedToPlayer'}} || %{$monsters{$ai_seq_args[0]{'ID'}}{'castOnByPlayer'}})))
                                || ($config{'attackAuto_party'} && ($monsters{$ai_seq_args[0]{'ID'}}{'dmgFromParty'} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'dmgToParty'} > 0))
                                || ($config{'attackAuto_followTarget'} && $ai_v{'temp'}{'ai_follow_following'} && ($monsters{$ai_seq_args[0]{'ID'}}{'dmgToPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0))
                                || ($monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'missedYou'} > 0)) {
                        $ai_v{'ai_attack_cleanMonster'} = 1;
                } else {
                        $ai_v{'ai_attack_cleanMonster'} = $config{'attackSteal'};
                        $monsters{$ai_seq_args[0]{'ID'}}{'attackSteal'} = 1;
                }

                if ($ai_seq_args[0]{'dmgToYou_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'}
                        || $ai_seq_args[0]{'missedYou_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'missedYou'}
                        || $ai_seq_args[0]{'dmgFromYou_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'}) {
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
                                        && !($config{"attackSkillSlot_$i"."_stopWhenHit"} && ai_getMonstersWhoHitMe())
                                        && (!$config{"attackSkillSlot_$i"."_maxUses"} || $ai_seq_args[0]{'attackSkillSlot_uses'}{$i} < $config{"attackSkillSlot_$i"."_maxUses"})
                                        && (!$config{"attackSkillSlot_$i"."_maxTrys"} || $ai_seq_args[0]{'attackSkillSlot_trys'}{$i} < $config{"attackSkillSlot_$i"."_maxTrys"})
                                        && timeOut($config{"attackSkillSlot_$i"."_timeout"}, $ai_v{"attackSkillSlot_$i"."_time"})
                                        && (!$config{"attackSkillSlot_$i"."_lockMapOnly"} || ($config{"attackSkillSlot_$i"."_lockMapOnly"} && $field{'name'} eq $config{'lockMap'}))
                                        && (!$config{"attackSkillSlot_$i"."_inState"} || ($config{"attackSkillSlot_$i"."_inState"} ne "" && ai_stateCheck($monsters{$ai_seq_args[0]{'ID'}}, $config{"attackSkillSlot_$i"."_inState"})))
                                        && (!$config{"attackSkillSlot_$i"."_noState"} || ($config{"attackSkillSlot_$i"."_noState"} ne "" && !ai_stateCheck($monsters{$ai_seq_args[0]{'ID'}}, $config{"attackSkillSlot_$i"."_noState"})))
                                        && (!$config{"attackSkillSlot_$i"."_minAggressives"} || $config{"attackSkillSlot_$i"."_minAggressives"} <= ai_getAggressives())
                                        && (!$config{"attackSkillSlot_$i"."_maxAggressives"} || $config{"attackSkillSlot_$i"."_maxAggressives"} >= ai_getAggressives())
                                        && (!$config{"attackSkillSlot_$i"."_minSpirits"} || $config{"attackSkillSlot_$i"."_minSpirits"} <= $chars[$config{'char'}]{'Spirits'})
                                        && (!$config{"attackSkillSlot_$i"."_maxSpirits"} || $config{"attackSkillSlot_$i"."_maxSpirits"} >= $chars[$config{'char'}]{'Spirits'})
                                        && (!$config{"attackSkillSlot_$i"."_minRoundMonsters"} || $config{"attackSkillSlot_$i"."_minRoundMonsters"} <= ai_getRoundMonster($config{"attackSkillSlot_$i"."_roundMonstersDist"}))
                                        && (!$config{"attackSkillSlot_$i"."_maxRoundMonsters"} || $config{"attackSkillSlot_$i"."_maxRoundMonsters"} >= ai_getRoundMonster($config{"attackSkillSlot_$i"."_roundMonstersDist"}))
                                        && (!$config{"attackSkillSlot_$i"."_monsters"} || existsInList($config{"attackSkillSlot_$i"."_monsters"}, $monsters{$ai_seq_args[0]{'ID'}}{'name'}))) {
                                        $ai_seq_args[0]{'attackMethod'}{'distance'} = $config{"attackSkillSlot_$i"."_dist"};
                                        $ai_seq_args[0]{'attackMethod'}{'type'} = "skill";
                                        $ai_seq_args[0]{'attackMethod'}{'skillSlot'} = $i;
                                        $ai_seq_args[0]{'attackSkillSlot_trys'}{$i}++;
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
                        printC("I0C", "不抢怪，放弃目标\n");
                        sendWindowsMessage("AA00".chr(1)."不抢怪，放弃目标") if ($yelloweasy);
                } elsif ($ai_v{'ai_attack_monsterDist'} > $ai_seq_args[0]{'attackMethod'}{'distance'}) {
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
                                $ai_v{'route_failed'}--;
                                if ($config{'attackMaxRouteDistance'} && $ai_seq_args[0]{'ai_route_returnHash'}{'solutionLength'} > $config{'attackMaxRouteDistance'}) {
                                        printC("I0R", "需要移动$ai_seq_args[0]{'ai_route_returnHash'}{'solutionLength'}格，放弃目标\n");
                                        sendWindowsMessage("AA00".chr(1)."需要移动$ai_seq_args[0]{'ai_route_returnHash'}{'solutionLength'}格，放弃目标") if ($yelloweasy);
                                } elsif ($config{'attackMaxRouteTime'} && $ai_seq_args[0]{'ai_route_returnHash'}{'solutionTime'} > $config{'attackMaxRouteTime'}) {
                                        printC("I0R", "计算路线超过$config{'attackMaxRouteTime'}秒，放弃目标\n");
                                        sendWindowsMessage("AA00".chr(1)."计算路线超过$config{'attackMaxRouteTime'}秒，放弃目标") if ($yelloweasy);
                                } else {
                                        printC("I0R", "无法攻击，放弃目标\n");
                                        sendWindowsMessage("AA00".chr(1)."无法攻击，放弃目标") if ($yelloweasy);
                                }
                                shift @ai_seq;
                                shift @ai_seq_args;
                        } else {
                                getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$chars[$config{'char'}]{'pos_to'}});
                                moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'ai_attack_monsterDist'} - ($ai_seq_args[0]{'attackMethod'}{'distance'} / $ai_seq_args[0]{'distanceDivide'}) + 1);

                                %{$ai_seq_args[0]{'char_pos_last'}} = %{$chars[$config{'char'}]{'pos_to'}};
                                %{$ai_seq_args[0]{'attackMethod_last'}} = %{$ai_seq_args[0]{'attackMethod'}};

                                ai_setSuspend(0);
                                if (@{$field{'field'}} > 1) {
                                        ai_route(\%{$ai_seq_args[0]{'ai_route_returnHash'}}, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}, $field{'name'}, $config{'attackMaxRouteDistance'}, $config{'attackMaxRouteTime'}, 0, 0);
                                } else {
                                        move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
                                }
                        }
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
                                if ($config{'tankMode'} >= 2) {
                                        sendAttack(\$remote_socket, $ai_seq_args[0]{'ID'}, 0);
                                } else {
                                        sendAttack(\$remote_socket, $ai_seq_args[0]{'ID'}, 7);
                                }
                                $ai_seq_args[0]{'sendAttackTime'} = time if (!$ai_seq_args[0]{'sendAttackTime'});
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
                                ai_setSuspend(0);
                                if (!ai_getSkillUseType($skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})})) {
                                        ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}}{'ID'}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_maxCastTime"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"}, $ai_v{'ai_attack_ID'});
                                } else {
                                        ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}}{'ID'}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_maxCastTime"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"}, $monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'x'}, $monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'y'});
                                }
                                $ai_seq_args[0]{'sendAttackTime'} = time if (!$ai_seq_args[0]{'sendAttackTime'});
                                print qq~Auto-skill on monster: $skills_lut{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}} (lvl $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"})\n~ if $config{'debug'};
                        }

                } elsif ($config{'tankMode'}) {
                        if ($ai_seq_args[0]{'dmgTo_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'}) {
                                $ai_seq_args[0]{'ai_attack_giveup'}{'time'} = time;
                        }
                        $ai_seq_args[0]{'dmgTo_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'};
                }
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
                                switchEquipment("u",$ai_seq_args[0]{'skill_use_id'});
                                sendSkillUseLoc(\$remote_socket, $ai_seq_args[0]{'skill_use_id'}, $ai_seq_args[0]{'skill_use_lv'}, $ai_seq_args[0]{'skill_use_target_x'}, $ai_seq_args[0]{'skill_use_target_y'});
                        } else {
                                switchEquipment("u",$ai_seq_args[0]{'skill_use_id'});
                                sendSkillUse(\$remote_socket, $ai_seq_args[0]{'skill_use_id'}, $ai_seq_args[0]{'skill_use_lv'}, $ai_seq_args[0]{'skill_use_target'});
                        }
                        $ai_seq_args[0]{'skill_use_last'} = $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$ai_seq_args[0]{'skill_use_id'}})}}{'time_used'};

                } elsif (($ai_seq_args[0]{'skill_use_last'} != $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$ai_seq_args[0]{'skill_use_id'}})}}{'time_used'}
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
                aiRemove("move");
                aiRemove("route");
                aiRemove("route_getRoute");
                aiRemove("route_getMapRoute");
                $ai_v{'route_failed'}++;
                ($map_string) = $map_name =~ /([\s\S]*)\.gat/;
                if (!$indoors_lut{$map_string.'.rsw'}) {
                        if ($ai_v{'route_failed'} == 10 || $ai_v{'route_failed'} == 15 || $ai_v{'route_failed'} == 20) {
                                printC("S1R", "计算路线失败$ai_v{'route_failed'}次，瞬移1级\n");
                                chatLog("x", "计算路线失败$ai_v{'route_failed'}次，瞬移1级\n");
                                useTeleport(1);
                        } elsif ($ai_v{'route_failed'} >= 25) {
                                printC("S1R", "计算路线失败$ai_v{'route_failed'}次，瞬移2级\n");
                                chatLog("x", "计算路线失败$ai_v{'route_failed'}次，瞬移2级\n");
                                undef $ai_v{'route_failed'};
                                useTeleport(2);
                                $ai_v{'clear_aiQueue'} = 1;
                        }
                } elsif ($ai_v{'route_failed'} >= 25) {
                        printC("S1R", "室内计算路线失败$ai_v{'route_failed'}次，断线3600秒\n");
                        chatLog("x", "室内计算路线失败$ai_v{'route_failed'}次，断线3600秒\n");
                        undef $ai_v{'route_failed'};
                        $ai_v{'clear_aiQueue'} = 1;
                        killConnection(\$remote_socket);
                        sleep(3600);
                }

        } elsif ($ai_seq[0] eq "route" && timeOut(\%{$timeout{'ai_route_npcTalk'}})) {
                last ROUTE if (!$field{'name'});
                if ($ai_seq_args[0]{'waitingForMapSolution'}) {
                        undef $ai_seq_args[0]{'waitingForMapSolution'};
                        if (!@{$ai_seq_args[0]{'mapSolution'}}) {
                                $ai_seq_args[0]{'failed'} = 1;
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
                        undef $ai_seq_args[0]{'mapSolution'};
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
                                if (!$ai_seq_args[0]{'npc'}{'sentTalk'}) {
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
                                $timeout{'ai_route_npcTalk'}{'time'} = time;
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
                        if ($ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'} != $chars[$config{'char'}]{'pos_to'}{'x'}
                                || $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'} != $chars[$config{'char'}]{'pos_to'}{'y'}) {
                                move($ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}, $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'});
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
                $timeout{'ai_route_calcRoute_cont'}{'time'} = time;
                ai_setSuspend(0);
        }

        } #End of block ROUTE_GETMAPROUTE



        ##### ITEMS IMPORTANT #####

        if ($ai_seq[0] eq "items_important" && !%{$items{$ai_seq_args[0]{'ID'}}}) {
                if ($items_old{$ai_seq_args[0]{'ID'}}{'takenBy'} eq $accountID) {
                        shift @ai_seq;
                        shift @ai_seq_args;
                } elsif (%{$players{$items_old{$ai_seq_args[0]{'ID'}}{'takenBy'}}}) {
                        printC("I0R", "捡取: $items_old{$ai_seq_args[0]{'ID'}}{'name'} - $players{$items_old{$ai_seq_args[0]{'ID'}}{'takenBy'}}{'name'}\n");
                        chatLog("i", "捡取: $items_old{$ai_seq_args[0]{'ID'}}{'name'} - $players{$items_old{$ai_seq_args[0]{'ID'}}{'takenBy'}}{'name'}\n");
                        shift @ai_seq;
                        shift @ai_seq_args;
                } elsif ($config{'pickupMonsters'}) {
                        undef $ai_v{'temp'}{'foundID'};
                        foreach (@monstersID) {
                                next if ($_ eq "" || !existsInList($config{'pickupMonsters'}, $monsters{$_}{'name'}));
                                if (distance(\%{$monsters{$_}{'pos'}}, \%{$items_old{$ai_seq_args[0]{'ID'}}{'pos'}}) < 2) {
                                        $ai_v{'temp'}{'foundID'} = $_;
                                        last;
                                }
                        }
                        if ($ai_v{'temp'}{'foundID'} eq "") {
                                foreach (@monstersID) {
                                        next if ($_ eq "" || !existsInList($config{'pickupMonsters'}, $monsters{$_}{'name'}));
                                        if (distance(\%{$monsters{$_}{'pos'}}, \%{$items_old{$ai_seq_args[0]{'ID'}}{'pos'}}) < 4) {
                                                $ai_v{'temp'}{'foundID'} = $_;
                                                last;
                                        }
                                }
                        }
                        if ($ai_v{'temp'}{'foundID'} eq "") {
                                foreach (@monstersID) {
                                        next if ($_ eq "" || !existsInList($config{'pickupMonsters'}, $monsters{$_}{'name'}));
                                        if (distance(\%{$monsters{$_}{'pos_to'}}, \%{$items_old{$ai_seq_args[0]{'ID'}}{'pos'}}) < 2) {
                                                $ai_v{'temp'}{'foundID'} = $_;
                                                last;
                                        }
                                }
                        }
                        if ($ai_v{'temp'}{'foundID'} eq "") {
                                foreach (@monstersID) {
                                        next if ($_ eq "" || !existsInList($config{'pickupMonsters'}, $monsters{$_}{'name'}));
                                        if (distance(\%{$monsters{$_}{'pos_to'}}, \%{$items_old{$ai_seq_args[0]{'ID'}}{'pos'}}) < 4) {
                                                $ai_v{'temp'}{'foundID'} = $_;
                                                last;
                                        }
                                }
                        }
                        if ($ai_v{'temp'}{'foundID'} eq "") {
                                foreach (@monstersID) {
                                        next if ($_ eq "" || !existsInList($config{'pickupMonsters'}, $monsters{$_}{'name'}));
                                        if (distance(\%{$monsters{$_}{'pos'}}, \%{$items_old{$ai_seq_args[0]{'ID'}}{'pos'}}) < 8) {
                                                $ai_v{'temp'}{'foundID'} = $_;
                                                last;
                                        }
                                }
                        }
                        if ($ai_v{'temp'}{'foundID'} eq "") {
                                foreach (@monstersID) {
                                        next if ($_ eq "" || !existsInList($config{'pickupMonsters'}, $monsters{$_}{'name'}));
                                        if (distance(\%{$monsters{$_}{'pos_to'}}, \%{$items_old{$ai_seq_args[0]{'ID'}}{'pos'}}) < 8) {
                                                $ai_v{'temp'}{'foundID'} = $_;
                                                last;
                                        }
                                }
                        }
                        shift @ai_seq;
                        shift @ai_seq_args;
                        attack($ai_v{'temp'}{'foundID'}) if ($ai_v{'temp'}{'foundID'} ne "");
                } else {
                        shift @ai_seq;
                        shift @ai_seq_args;
                }
        } elsif ($ai_seq[0] eq "items_important") {
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
                printC("I0", "无法收集物品 $items_old{$ai_seq_args[0]{'ID'}}{'name'} : 目标丢失\n");
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
                        printC("I0", "无法收集物品 $items{$ai_seq_args[0]{'ID'}}{'name'} : 超时\n");
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
                        printC("I0", "无法收集物品 $items{$ai_seq_args[0]{'ID'}}{'name'} : 无法捡取\n");
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
                printC("I0", "无法捡取物品 $items{$ai_seq_args[0]{'ID'}}{'name'}\n") if ($config{'Mode'});
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
                        if ($ai_v{'move_failed'} == 15 || $ai_v{'move_failed'} == 20 || $ai_v{'move_failed'} == 25) {
                                printC("S1R", "移动失败$ai_v{'move_failed'}次，重新计算路线\n");
                                chatLog("x", "移动失败$ai_v{'move_failed'}次，重新计算路线\n");
                                $ai_v{'move_failed'}++;
                                aiRemove("move");
                                aiRemove("route");
                                aiRemove("route_getRoute");
                                aiRemove("route_getMapRoute");
                        } elsif ($ai_v{'move_failed'} >= 30) {
                                printC("S1R", "移动失败$ai_v{'move_failed'}次，瞬移1级\n");
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
                foreach (@monstersID) {
                        next if ($_ eq "");
                        if ($mon_control{lc($monsters{$_}{'name'})}{'teleport_auto'} == 1 || ($mon_control{lc($monsters{$_}{'name'})}{'teleport_auto'} == 2 && ($monsters{$_}{'dmgToYou'} > 0 || $monsters{$_}{'missedYou'} > 0)) || ($mon_control{lc($monsters{$_}{'name'})}{'teleport_auto'} == 3 && $monsters{$_}{'dmgToYou'} > 0)) {
                                printC("A5R", "躲避怪物 $monsters{$_}{'name'}\n") if ($config{'Mode'});
                                useTeleport(1);
                                $timeout{'ai_teleport_hp'}{'time'} = time;
                                last;
                        }
                }
        }

        if ($ai_v{'ai_teleport_safe'} && timeOut(\%{$timeout{'ai_teleport_hp'}}) && (($config{'teleportAuto_hp'} && percent_hp(\%{$chars[$config{'char'}]}) <= $config{'teleportAuto_hp'})
                || ($config{'teleportAuto_sp'} && percent_sp(\%{$chars[$config{'char'}]}) <= $config{'teleportAuto_sp'})) && ai_getAggressives()) {
                printC("A5R", "剩下HP: $chars[$config{'char'}]{'hp'} / SP: $chars[$config{'char'}]{'sp'}\n") if ($config{'Mode'});
                useTeleport(1);
                $timeout{'ai_teleport_hp'}{'time'} = time;
        }

        if ($config{'teleportAuto_roundMonstersSit'} && $ai_v{'ai_teleport_safe'} && timeOut(\%{$timeout{'ai_teleport_hp'}}) && binFind(\@ai_seq, "sitAuto") ne "" && (ai_getAggressives() || ai_getRoundMonster($config{'teleportAuto_roundMonstersDist'}))) {
                printC("A5R", "坐下时附近有怪物\n") if ($config{'Mode'});
                useTeleport(1);
                $timeout{'ai_teleport_hp'}{'time'} = time;
        }

        if ($config{'teleportAuto_minAggressives'} && $ai_v{'ai_teleport_safe'} && timeOut(\%{$timeout{'ai_teleport_hp'}}) && ai_getTeleportAggressives() >= $config{'teleportAuto_minAggressives'}) {
                $ai_v{'temp'}{'agMonsters'} = ai_getTeleportAggressives();
                printC("A5R", "被$ai_v{'temp'}{'agMonsters'}只怪物攻击\n") if ($config{'Mode'});
                useTeleport(1);
                $timeout{'ai_teleport_hp'}{'time'} = time;
        }

        if ($config{'teleportAuto_roundMonsters'} && $ai_v{'ai_teleport_safe'} && timeOut(\%{$timeout{'ai_teleport_hp'}}) && ai_getRoundMonster($config{'teleportAuto_roundMonstersDist'}) >= $config{'teleportAuto_roundMonsters'} && $config{'lockMap'} && $field{'name'} && $field{'name'} eq $config{'lockMap'}) {
                $ai_v{'temp'}{'roundMonsters'} = ai_getRoundMonster($config{'teleportAuto_roundMonstersDist'});
                printC("A5R", "附近有$ai_v{'temp'}{'roundMonsters'}只怪物\n") if ($config{'Mode'});
                useTeleport(1);
                $timeout{'ai_teleport_hp'}{'time'} = time;
        }

        if ($config{'teleportAuto_portal'} && timeOut(\%{$timeout{'ai_teleport_portal'}}) && $ai_v{'ai_teleport_safe'} && binFind(\@ai_seq, "storageAuto") eq "" && binFind(\@ai_seq, "buyAuto") eq "" && binFind(\@ai_seq, "sellAuto") eq "" && binFind(\@ai_seq, "healAuto") eq ""
                && $config{'lockMap'} && $field{'name'} && $field{'name'} eq $config{'lockMap'}) {
                foreach (@portalsID) {
                        $ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$portals{$_}{'pos'}});;
                        if ($ai_v{'temp'}{'dist'} <= $config{'teleportAuto_portalDist'}) {
                                printC("A5R", "躲避地图传送点\n") if ($config{'Mode'});
                                useTeleport(1);
                                last;
                        }
                }
                $timeout{'ai_teleport_portal'}{'time'} = time;
        }

        if ($ai_seq[0] ne "" || $chars[$config{'char'}]{'shopOpened'}) {
                $timeout{'ai_teleport_search'}{'time'} = time;
                $timeout{'ai_teleport_search_wait'}{'time'} = time;
                $timeout{'ai_teleport_idle'}{'time'} = time;
        }

        if ($ai_seq[0] eq "" && $config{'teleportAuto_search'} && $config{'lockMap'} && $field{'name'} && $field{'name'} eq $config{'lockMap'}) {
                undef $ai_v{'temp'}{'found'};
                foreach (@monstersID) {
                        if (!$ai_v{'temp'}{'found'} && $_ ne "") {
                                $ai_v{'temp'}{'found'} = 1;
                        }
                        if (($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} >=1 || ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "" && $mon_control{'all'}{'attack_auto'} >= 1)) && !$monsters{$_}{'attack_failed'}) {
                                $ai_v{'temp'}{'found'} = 2;
                                last;
                        }
                }
                if (timeOut(\%{$timeout{'ai_teleport_search_wait'}}) && $ai_v{'temp'}{'found'} == 1 && !$ai_v{'temp'}{'teleport_search'} && $ai_v{'ai_teleport_safe'}) {
                        printC("A5W", "寻找怪物\n") if ($config{'Mode'} >= 2);
                        useTeleport(1);
                        $ai_v{'temp'}{'teleport_search'} = 1;
                        $timeout{'ai_teleport_search'}{'time'} = time;
                        $timeout{'ai_teleport_search_wait'}{'time'} = time;
                } elsif (timeOut(\%{$timeout{'ai_teleport_search'}}) && $ai_v{'ai_teleport_safe'}) {
                        printC("A5W", "寻找怪物\n") if ($config{'Mode'} >= 2);
                        useTeleport(1);
                        $ai_v{'temp'}{'teleport_search'} = 1;
                        $timeout{'ai_teleport_search'}{'time'} = time;
                        $timeout{'ai_teleport_search_wait'}{'time'} = time;
                }
        }

        if ($config{'teleportAuto_idle'} && timeOut(\%{$timeout{'ai_teleport_idle'}}) && $ai_v{'ai_teleport_safe'}) {
                printC("A5W", "空闲$timeout{'ai_teleport_idle'}{'timeout'}秒\n") if ($config{'Mode'} >= 2);
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


        ##### SMART AI #####

        if (!$exp{'log_time'}) {
                $exp{'log_time'} = time;
        } elsif ($timeout{'ai_exp_log'}{'timeout'} > 0 && time - $exp{'log_time'} > $timeout{'ai_exp_log'}{'timeout'}) {
                $exp{'log_time'} = time;
                chatLogExp();
        }

        if ($yelloweasy && time - $mapdrttime > 1) {
                $mapdrttime = time;
                sendWindowsMessage("AA10".chr(1).$field{'name'}.chr(1).$chars[$config{'char'}]{'pos_to'}{'x'}.chr(1).$chars[$config{'char'}]{'pos_to'}{'y'});
                #sendWindowsMessage("AA15".chr(1).$chars[$config{'char'}]{'hp'}.chr(1).$chars[$config{'char'}]{'hp_max'}.chr(1).$chars[$config{'char'}]{'sp'}.chr(1).$chars[$config{'char'}]{'sp_max'}.chr(1).$chars[$config{'char'}]{'weight'}.chr(1).$chars[$config{'char'}]{'weight_max'});
        }

        if (timeOut(\%{$timeout{'ai_mvp_use_auto'}}) && $ai_seq[0] eq "" && !$chars[$config{'char'}]{'mvp'} && $chars[$config{'char'}]{'mvp_end_time'} > 0 && time - $chars[$config{'char'}]{'mvp_end_time'} > $config{'useMvp_timeout'}) {
                undef $ai_v{'temp'}{'invIndex'};
                $ai_v{'temp'}{'invIndex'} = findIndexMultiString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'useMvp_item'});
                if ($ai_v{'temp'}{'invIndex'} ne "" && $config{'useMvp_item'} && !ai_stateCheck($chars[$config{'char'}], $config{'useMvp_item'})) {
                        sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $accountID);
                } elsif ($config{'useMvp_skill'} && $config{'useMvp_lvl'} && !ai_stateCheck($chars[$config{'char'}], $config{'useMvp_skill'})) {
                        ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{'useMvp_skill'})}}{'ID'}, $config{'useMvp_lvl'}, 1, 0, $accountID);
                } else {
                        $chars[$config{'char'}]{'mvp_end_time'} = time + 40;
                }
                $timeout{'ai_mvp_use_auto'}{'time'} = time;
        }

        undef $ai_v{'ai_attack_index'};
        $ai_v{'ai_attack_index'} = binFind(\@ai_seq, "attack");
        if ($ai_v{'ai_attack_index'} ne "" && %{$monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}} && timeOut(\%{$timeout{'ai_smart_attack'}})) {
                undef @{$ai_v{'ai_attack_agMonsters'}};
                @{$ai_v{'ai_attack_agMonsters'}} = ai_getAttackAggressives();
                if (%{$monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}} && $monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}{'dmgFromYou'} == 0 && $config{'attackTimeout'} && time - $ai_seq_args[$ai_v{'ai_attack_index'}]{'ai_attack_start'}{'time'} > $config{'attackTimeout'} && !$chars[$config{'char'}]{'mvp'}) {
                        $monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}{'attack_failed'}++;
                        printC("I0R", "$config{'attackTimeout'}秒内无法攻击目标，放弃目标\n");
                        sendWindowsMessage("AA00".chr(1)."$config{'attackTimeout'}秒内无法攻击目标，放弃目标") if ($yelloweasy);
                        $monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}{'attack_failed'}++;
                        aiRemove("attack");
                        $timeout{'ai_smart_attack'}{'time'} = time;
                } elsif ($config{'attackCheckMiss'} && $chars[$config{'char'}]{'miss_count'} >= $config{'attackCheckMiss'}) {
                        printC("I0R", "连续$config{'attackCheckMiss'}无法伤害目标，放弃目标\n");
                        sendWindowsMessage("AA00".chr(1)."连续$config{'attackCheckMiss'}无法伤害目标，放弃目标") if ($yelloweasy);
                        $monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}{'attack_failed'}++;
                        undef $chars[$config{'char'}]{'miss_count'};
                        aiRemove("attack");
                        $timeout{'ai_smart_attack'}{'time'} = time;
                } elsif (@{$ai_v{'ai_attack_agMonsters'}} && $mon_control{lc($monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}{'name'})}{'attack_auto'} <= 3) {
                        foreach (@{$ai_v{'ai_attack_agMonsters'}}) {
                                next if ($_ eq $ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'});
                                if (char_distance(\%{$monsters{$_}}) < $config{'attackDistance'} && $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} > $mon_control{lc($monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}{'name'})}{'attack_auto'}) {
                                        aiRemove("attack");
                                        printC("I0C", "优先攻击\n");
                                        $timeout{'ai_smart_attack'}{'time'} = time;
                                        last;
                                }
                                if (char_distance(\%{$monsters{$_}}) <= $config{'attackDistance'} && char_distance(\%{$monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}}) > $config{'attackDistance'} && $monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}{'dmgFromYou'} == 0) {
                                        aiRemove("attack");
                                        printC("I0C", "优先反击近距离怪物\n");
                                        $timeout{'ai_smart_attack'}{'time'} = time;
                                        last;
                                }
                        }
                        if (binFind(\@{$ai_v{'ai_attack_agMonsters'}}, $ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}) eq "" && $monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}{'dmgFromYou'} == 0 && !$chars[$config{'char'}]{'mvp'}) {
                                aiRemove("attack");
                                printC("I0C", "优先反击围攻怪物\n");
                        }
                        $timeout{'ai_smart_attack'}{'time'} = time;
                } elsif ($config{'attackCheckTimeout'} && $ai_seq_args[$ai_v{'ai_attack_index'}]{'sendAttackTime'} ne "" && $ai_seq_args[$ai_v{'ai_attack_index'}]{'sendAttackTime'} != 1 && time - $ai_seq_args[$ai_v{'ai_attack_index'}]{'sendAttackTime'} > $config{'attackCheckTimeout'}
                        && %{$monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}} && !$monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}{'dmgToYou'} && !$monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}{'missedYou'}) {
                        $monsters{$ai_seq_args[$ai_v{'ai_attack_index'}]{'ID'}}{'attack_failed'}++;
                        aiRemove("attack");
                        printC("I0R", "无法攻击目标，放弃目标\n");
                        sendWindowsMessage("AA00".chr(1)."无法攻击目标，放弃目标") if ($yelloweasy);
                }
        }

        if ($chars[$config{'char'}]{'sendItemUse'} >= 30) {
                printC("S1R", "使用物品失败$chars[$config{'char'}]{'sendItemUse'}次\n");
                chatLog("x", "使用物品失败$chars[$config{'char'}]{'sendItemUse'}次\n");
                undef $chars[$config{'char'}]{'sendItemUse'};
                relog() if (!$chars[$config{'char'}]{'mvp'});
        }



        ##### AUTO CHAT #####
        if ($chars[$config{'char'}]{'autochat'}{'send'} == 1 && (time - $chars[$config{'char'}]{'autochat'}{'time'}) > rand(3)+5) {
                if ($chars[$config{'char'}]{'autochat'}{'type'} eq "c") {
                        sendMessage(\$remote_socket, "c", $chars[$config{'char'}]{'autochat'}{'msg'}) if ($chars[$config{'char'}]{'autochat'}{'msg'});

                } elsif ($chars[$config{'char'}]{'autochat'}{'type'} eq "pm") {
                        sendPrivateMsg(\$remote_socket, $chars[$config{'char'}]{'autochat'}{'name'}, $chars[$config{'char'}]{'autochat'}{'msg'});
                        $lastpm[0]{'user'} = $chars[$config{'char'}]{'autochat'}{'name'};
                        $lastpm[0]{'msg'} = $chars[$config{'char'}]{'autochat'}{'msg'}
                }
                undef $chars[$config{'char'}]{'autochat'}{'send'};
                $chars[$config{'char'}]{'autochat'}{'last_time'} = time;
        }
        # ICE End

        ##### DISTANCE #####

        foreach (@monstersID) {
                next if $_ eq "";
                undef $monsters{$_}{'distance'};
        }
        foreach (@playersID) {
                next if $_ eq "";
                undef $players{$_}{'distance'};
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
        $switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));
        if (length($msg) >= 4 && substr($msg,0,4) ne $accountID && $conState >= 4 && $lastswitch ne $switch
                && length($msg) >= unpack("S1", substr($msg, 0, 2))) {
                decrypt(\$msg, $msg);
        }
        $switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));
        print "Packet Switch: $switch\n" if ($config{'debug'} >= 2 || $config{'debug_packet'} >= 3);

        if ($lastswitch eq $switch && length($msg) > $lastMsgLength) {
                $errorCount++;
        } else {
                $errorCount = 0;
        }
        if ($errorCount > 3) {
                $msg_size = length($msg);
                printC("S1R", "接收到无法解释的封包，丢失数据$msg_size字节\n");
                chatLog("x", "接收到无法解释的封包，丢失数据$msg_size字节\n");
                dumpData($msg) if $config{'debug'};
                $errorCount = 0;
        }

        $switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));
        $lastswitch = $switch;
        $lastMsgLength = length($msg);
        $MsgLength = length($msg);
        $dMsgLength = unpack("S1", substr($msg, 2, 2));
        if (substr($msg,0,4) eq $accountID && ($conState == 2 || $conState == 4)) {
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

        } elsif ($switch eq "0064" && $MsgLength >= 55) {
                $msg_size = 55;

        } elsif ($switch eq "0065" && $MsgLength >= 55) {
                $msg_size = 17;

        } elsif ($switch eq "0066" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0067" && $MsgLength >= 37) {
                $msg_size = 37;

        } elsif ($switch eq "0068" && $MsgLength >= 46) {
                $msg_size = 46;

        } elsif ($switch eq "0069" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                $conState = 2;
                undef $conState_tries;
                if ($versionSearch) {
                        $versionSearch = 0;
                        writeDataFileIntact("$setupPath/config.txt", \%config);
                }
                $sessionID = substr($msg, 4, 4);
                $accountID = substr($msg, 8, 4);
                $accountAID = unpack("L1",$accountID);
                $accountSex = unpack("C1",substr($msg, 46, 1));
                $accountSex2 = ($config{'sex'} ne "") ? $config{'sex'} : $accountSex;
                format ACCOUNT =
---------Account Info----------
Account ID: @<<<<<<<<<<<<<<<<<<
            $accountAID
Sex:        @<<<<<<<<<<<<<<<<<<
            $sex_lut{$accountSex}
Session ID: @<<<<<<<<<<<<<<<<<<
            getHex($sessionID)
-------------------------------
.
                $~ = "ACCOUNT";
                write;
                $num = 0;
                undef @servers;
                for($i = 47; $i < $msg_size; $i+=32) {
                        $servers[$num]{'ip'} = makeIP(substr($msg, $i, 4));
                        $servers[$num]{'port'} = unpack("S1", substr($msg, $i+4, 2));
                        ($servers[$num]{'name'}) = substr($msg, $i + 6, 20) =~ /([\s\S]*?)\000/;
                        $servers[$num]{'users'} = unpack("L",substr($msg, $i + 26, 4));
                        $num++;
                }
                $~ = "SERVERS";
                print "--------- Servers ----------\n";
                print "#         Name            Users  IP              Port\n";
                for ($num = 0; $num < @servers; $num++) {
                        format SERVERS =
@<< @<<<<<<<<<<<<<<<<<<<< @<<<<< @<<<<<<<<<<<<<< @<<<<<
$num  $servers[$num]{'name'}  $servers[$num]{'users'} $servers[$num]{'ip'} $servers[$num]{'port'}
.
                        write;
                }
                print "-------------------------------\n";
                printC("S0", "关闭与身份验证服务器的连接\n");
                killConnection(\$remote_socket);
                if (!$config{'charServer_host'} && $config{'server'} eq "") {
                        printC("S0W", "请选择服务器: \n");
                        $waitingForInput = 1;
                } elsif ($config{'charServer_host'}) {
                        printC("S0", "强制连接到身份验证服务器服务器 $config{'charServer_host'}:$config{'charServer_port'}\n");
                } else {
                        printC("S0", "已选择服务器: $config{'server'}\n");
                }

        } elsif ($switch eq "006A" && $MsgLength >= 23) {
                $type = unpack("C1",substr($msg, 2, 1));
                if ($type == 0) {
                        printC("S1R", "尚未登录的使用者账号。请重新确认账号\n");
                        printC("S0W", "请输入用户名: \n");
                        $input_socket->recv($msg, $MAX_READ);
                        $config{'username'} = $msg;
                        writeDataFileIntact("$setupPath/config.txt", \%config);
                } elsif ($type == 1) {
                        printC("S1R", "密码错误\n");
                        printC("S0W", "请输入密码\n");
                        $input_socket->recv($msg, $MAX_READ);
                        $config{'password'} = $msg;
                        writeDataFileIntact("$setupPath/config.txt", \%config);
                } elsif ($type == 3) {
                        printC("S1R", "服务器拒绝联机\n");
                } elsif ($type == 4) {
                        printC("S1R", "服务器终止联机，此帐号已被冻结\n");
                        sleep(3);
                        $quit = 1;
                } elsif ($type == 5) {
                        printC("S1R", "游戏版本$config{'version'}无效...尝试寻找正确的版本\n");
                        $config{'version'}++;
                        if (!$versionSearch) {
                                $config{'version'} = 0;
                                $versionSearch = 1;
                        }
                } elsif ($type == 6) {
                        prinC("s", "游戏暂时停止联机，请重新联机。\n");
                }
                if ($type != 5 && $versionSearch) {
                        $versionSearch = 0;
                        writeDataFileIntact("$setupPath/config.txt", \%config);
                }
                $msg_size = 23;

        } elsif ($switch eq "006B" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                printC("S0", "接收到人物资料\n");
                $conState = 3;
                undef $conState_tries;
                $msg_size = $dMsgLength;
                if ($config{"master_version_$config{'master'}"} == 0) {
                        $startVal = 24;
                } else {
                        $startVal = 4;
                }
                for($i = $startVal; $i < $msg_size; $i+=106) {

#exp display bugfix - chobit andy 20030129
                        $num = unpack("C1", substr($msg, $i + 104, 1));
                        $chars[$num]{'exp'} = unpack("L1", substr($msg, $i + 4, 4));
                        $chars[$num]{'zenny'} = unpack("L1", substr($msg, $i + 8, 4));
                        $chars[$num]{'exp_job'} = unpack("L1", substr($msg, $i + 12, 4));
                        $chars[$num]{'lv_job'} = unpack("C1", substr($msg, $i + 16, 1));
                        $chars[$num]{'hp'} = unpack("S1", substr($msg, $i + 42, 2));
                        $chars[$num]{'hp_max'} = unpack("S1", substr($msg, $i + 44, 2));
                        $chars[$num]{'sp'} = unpack("S1", substr($msg, $i + 46, 2));
                        $chars[$num]{'sp_max'} = unpack("S1", substr($msg, $i + 48, 2));
                        $chars[$num]{'jobID'} = unpack("C1", substr($msg, $i + 52, 1));
                        $chars[$num]{'lv'} = unpack("C1", substr($msg, $i + 58, 1));
                        ($chars[$num]{'name'}) = substr($msg, $i + 74, 24) =~ /([\s\S]*?)\000/;
                        $chars[$num]{'str'} = unpack("C1", substr($msg, $i + 98, 1));
                        $chars[$num]{'agi'} = unpack("C1", substr($msg, $i + 99, 1));
                        $chars[$num]{'vit'} = unpack("C1", substr($msg, $i + 100, 1));
                        $chars[$num]{'int'} = unpack("C1", substr($msg, $i + 101, 1));
                        $chars[$num]{'dex'} = unpack("C1", substr($msg, $i + 102, 1));
                        $chars[$num]{'luk'} = unpack("C1", substr($msg, $i + 103, 1));
                        $chars[$num]{'sex'} = $accountSex2;
                }
                $~ = "CHAR";
                for ($num = 0; $num < @chars; $num++) {
                        format CHAR =
-------  Character @< ---------
         $num
Name: @<<<<<<<<<<<<<<<<<<<<<<<<
      $chars[$num]{'name'}
Job:  @<<<<<<<      Job Exp: @<<<<<<<
$jobs_lut{$chars[$num]{'jobID'}} $chars[$num]{'exp_job'}
Lv:   @<<<<<<<      Str: @<<<<<<<<
$chars[$num]{'lv'}  $chars[$num]{'str'}
J.Lv: @<<<<<<<      Agi: @<<<<<<<<
$chars[$num]{'lv_job'}  $chars[$num]{'agi'}
Exp:  @<<<<<<<      Vit: @<<<<<<<<
$chars[$num]{'exp'} $chars[$num]{'vit'}
HP:   @||||/@||||   Int: @<<<<<<<<
$chars[$num]{'hp'} $chars[$num]{'hp_max'} $chars[$num]{'int'}
SP:   @||||/@||||   Dex: @<<<<<<<<
$chars[$num]{'sp'} $chars[$num]{'sp_max'} $chars[$num]{'dex'}
Zenny: @<<<<<<<<<<  Luk: @<<<<<<<<
$chars[$num]{'zenny'} $chars[$num]{'luk'}
-------------------------------
.
                        write;
                }
                if ($config{'char'} eq "") {
                        printC("S0W", "请选择人物: \n");
                        $waitingForInput = 1;
                } else {
                        printC("S0", "已选择人物: $config{'char'}\n");
                        sendCharLogin(\$remote_socket, $config{'char'});
                        $timeout{'gamelogin'}{'time'} = time;
                }

        } elsif ($switch eq "006C" && $MsgLength >= 3) {
                printC("S1R", "登录身份验证服务器错误，没有指定的人物...\n");
                $conState = 1;
                undef $conState_tries;
                $msg_size = 3;

        } elsif ($switch eq "006D" && $MsgLength >= 108) {
                $msg_size = 108;

        } elsif ($switch eq "006E" && $MsgLength >= 3) {
                $msg_size = 3;

        } elsif ($switch eq "006F" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "0070" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0071" && $MsgLength >= 28) {
                initGameStart();
                printC("S0", "接收到人物ID及地图服务器的IP地址\n");
                $conState = 4;
                undef $conState_tries;
                $charID = substr($msg, 2, 4);
                ($map_name) = substr($msg, 6, 16) =~ /([\s\S]*?)\000/;
                $map_ip = makeIP(substr($msg, 22, 4));
                $map_port = unpack("S1", substr($msg, 26, 2));
                ($ai_v{'temp'}{'map'}) = $map_name =~ /([\s\S]*)\./;
                if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
                        getField("map/$ai_v{'temp'}{'map'}.fld", \%field);
                }
                format CHARINFO =
---------Game Info----------
Char ID: @<<<<<<<<<<<<<<<<<<
            getHex($charID)
MAP Name: @<<<<<<<<<<<<<<<<<<
            $map_name
MAP IP: @<<<<<<<<<<<<<<<<<<
            $map_ip
MAP Port: @<<<<<<<<<<<<<<<<<<
        $map_port
-------------------------------
.
                $~ = "CHARINFO";
                write;
                printC("S0", "关闭与身份验证服务器的连接\n");
                killConnection(\$remote_socket);
                $msg_size = 28;
                if ($sendFlyMap) {
                        $map_ip = $sendFlyIP;
                        $map_port = $sendFlyPort;
                }


        } elsif ($switch eq "0072" && $MsgLength >= 19) {
                $msg_size = 19;

        } elsif ($switch eq "0073" && $MsgLength >= 11) {
                $conState = 5;
                undef $conState_tries;
                makeCoords(\%{$chars[$config{'char'}]{'pos'}}, substr($msg, 6, 3));
                %{$chars[$config{'char'}]{'pos_to'}} = %{$chars[$config{'char'}]{'pos'}};
                print "Your Coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n" if $config{'debug'};
                printC("I0C", "$chars[$config{'char'}]{'name'} 进入游戏\n");
                checkAuth();
                sendMapLoaded(\$remote_socket);
                sendIgnoreAll(\$remote_socket, 0) if($config{'chatAutoExall'});
                $timeout{'ai'}{'time'} = time;
                $msg_size = 11;

        } elsif ($switch eq "0074" && $MsgLength >= 3) {
                $msg_size = 3;

        } elsif ($switch eq "0075" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0076" && $MsgLength >= 9) {
                $msg_size = 9;

        } elsif ($switch eq "0077" && $MsgLength >= 5) {
                $msg_size = 5;

        } elsif ($switch eq "0078" && $MsgLength >= 54) {
                $ID = substr($msg, 2, 4);
                makeCoords(\%coords, substr($msg, 46, 3));
                $type = unpack("S*",substr($msg, 14,  2));
                $pet = unpack("C*",substr($msg, 16,  1));
                $sex = unpack("C*",substr($msg, 45,  1));
                $sitting = unpack("C*",substr($msg, 51,  1));
                $param1 = unpack("S1", substr($msg, 8, 2));
                $param2 = unpack("S1", substr($msg, 10, 2));
                $param3 = unpack("S1", substr($msg, 12, 2));
                if ($type >= 1000) {
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
                                print "Pet Exists: $pets{$ID}{'name'}($pets{$ID}{'binID'})\n" if ($config{'debug'});
                        } else {
                                if (!%{$monsters{$ID}}) {
                                        $monsters{$ID}{'appear_time'} = time;
                                        $display = ($monsters_lut{$type} ne "")
                                                        ? $monsters_lut{$type}
                                                        : "Unknown ".$type;
                                        binAdd(\@monstersID, $ID);
                                        $monsters{$ID}{'nameID'} = $type;
                                        $monsters{$ID}{'name'} = $display;
                                        $monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
                                }
                                %{$monsters{$ID}{'pos'}} = %coords;
                                %{$monsters{$ID}{'pos_to'}} = %coords;
                                print "Monster Exists: $monsters{$ID}{'name'}($monsters{$ID}{'binID'})\n" if ($config{'debug'});
                                # ICE Start - MVP Monster
                                if ($config{'mvpMode'} && $monsters{$ID}{'mvp'} != 1 && ($mon_control{lc($monsters{$ID}{'name'})}{'attack_auto'} >=1 || ($mon_control{lc($monsters{$ID}{'name'})}{'attack_auto'} eq "" && $mon_control{'all'}{'attack_auto'} >= 1))) {
                                        if($importantMonsters_rlut{$monsters{$ID}{'name'}} == 1) {
                                                $monsters{$ID}{'mvp'} = 1;
                                                if (!$chars[$config{'char'}]{'mvp'}) {
                                                        ai_changeToMvpMode(1);
                                                        chatLog("m", "发现: $monsters{$ID}{'name'} $field{'name'} ($monsters{$ID}{'pos'}{'x'}, $monsters{$ID}{'pos'}{'y'})\n");
                                                        attack($ID) if ($config{'attackMvpFirst'});
                                                }
                                        }
                                }
                                # ICE End
                        }

                } elsif ($jobs_lut{$type}) {
                        if (!%{$players{$ID}}) {
                                $players{$ID}{'appear_time'} = time;
                                binAdd(\@playersID, $ID);
                                $players{$ID}{'jobID'} = $type;
                                $players{$ID}{'sex'} = $sex;
                                $players{$ID}{'name'} = "Unknown";
                                $players{$ID}{'binID'} = binFind(\@playersID, $ID);
                                $players{$ID}{'AID'} = unpack("L1", $ID);
                                if ($aid_rlut{$players{$ID}{'AID'}}{'avoid'}) {
                                        %{$players{$ID}{'pos'}} = %coords;
                                        %{$players{$ID}{'pos_to'}} = %coords;
                                        binAdd(\@avoidID, $ID);
                                }
                        }
                        $players{$ID}{'sitting'} = $sitting > 0;
                        %{$players{$ID}{'pos'}} = %coords;
                        %{$players{$ID}{'pos_to'}} = %coords;
                        print "Player Exists: $players{$ID}{'name'}($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});

                } elsif ($type == 45) {
                        if (!%{$portals{$ID}}) {
                                $portals{$ID}{'appear_time'} = time;
                                $nameID = unpack("L1", $ID);
                                $exists = portalExists($field{'name'}, \%coords);
                                $display = ($exists ne "")
                                        ? "$portals_lut{$exists}{'source'}{'map'} -> $portals_lut{$exists}{'dest'}{'map'}"
                                        : "Unknown ".$nameID;
                                binAdd(\@portalsID, $ID);
                                $portals{$ID}{'source'}{'map'} = $field{'name'};
                                $portals{$ID}{'type'} = $type;
                                $portals{$ID}{'nameID'} = $nameID;
                                $portals{$ID}{'name'} = $display;
                                $portals{$ID}{'binID'} = binFind(\@portalsID, $ID);
                        }
                        %{$portals{$ID}{'pos'}} = %coords;
                        printC("M5", "存在: $portals{$ID}{'name'} - ($portals{$ID}{'binID'})\n");

                } elsif ($type < 1000) {
                        if (!%{$npcs{$ID}}) {
                                $npcs{$ID}{'appear_time'} = time;
                                $nameID = unpack("L1", $ID);
                                $display = (%{$npcs_lut{$nameID}})
                                        ? $npcs_lut{$nameID}{'name'}
                                        : "Unknown ".$nameID;
                                binAdd(\@npcsID, $ID);
                                $npcs{$ID}{'type'} = $type;
                                $npcs{$ID}{'nameID'} = $nameID;
                                $npcs{$ID}{'name'} = $display;
                                $npcs{$ID}{'binID'} = binFind(\@npcsID, $ID);
                        }
                        %{$npcs{$ID}{'pos'}} = %coords;
                        printC("M3", "存在: $npcs{$ID}{'name'} - ($npcs{$ID}{'binID'})\n");

                } else {
                        print "Unknown Exists: $type - ".unpack("L*",$ID)."\n" if $config{'debug'};
                }

                undef $sourceDisplay;
                undef $targetDisplay;
                undef $state;
                if ($param1 == 0 && $param2 == 0) {
                        $targetDisplay = $msgstrings_lut{'0119'}{"00"};
                } else {
                        if ($param1 == 1) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"A1"};
                        } elsif ($param1 == 2) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"A2"};
                        } elsif ($param1 == 3) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"A3"};
                        } elsif ($param1 == 4) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"A4"};
                        } elsif ($param1 == 6) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"A6"};
                        } elsif ($param2 == 1) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"B1"};
                        } elsif ($param2 == 2) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"B2"};
                        } elsif ($param2 == 4) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"B4"};
                        } elsif ($param2 == 16) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"B16"};
                        } elsif ($param2 == 32) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"B32"};
                        } else {
                                $targetDisplay = "未知状态$param1$param2$param3";
                        }
                }
                if ($param3 == 1) {
#                        $targetDisplay = $msgstrings_lut{'0119'}{"C1"};
                } elsif ($param3 == 2) {
#                        $targetDisplay = $msgstrings_lut{'0119'}{"C2"};
                } elsif ($param3 == 4) {
#                        $targetDisplay = $msgstrings_lut{'0119'}{"C4"};
                } elsif ($param3 == 8) {
#                        $targetDisplay = "持有手推车Ⅰ";
                } elsif ($param3 == 16) {
#                        $targetDisplay = "装备好猎鹰";
                } elsif ($param3 == 32) {
#                        $targetDisplay = "骑上大嘴鸟";
                } elsif ($param3 == 64) {
#                        $targetDisplay = $msgstrings_lut{'0119'}{"C64"};
                } elsif ($param3 == 128) {
#                        $targetDisplay = "持有手推车Ⅱ";
                } elsif ($param3 == 256) {
#                        $targetDisplay = "持有手推车Ⅲ";
                } elsif ($param3 == 512) {
#                        $targetDisplay = "持有手推车Ⅳ";
                } elsif ($param3 == 1024) {
#                        $targetDisplay = "持有手推车Ⅴ";
                }
                $state = $targetDisplay;
                $targetDisply .= "($param1|$param2|$param3)" if ($config{'debug'});
                if (%{$monsters{$ID}}) {
                        $sourceDisplay = "$monsters{$ID}{'name'}($monsters{$ID}{'binID'}) ";
                        $monsters{$ID}{'state'} = $state;
                } elsif (%{$players{$ID}}) {
                        $sourceDisplay = "$players{$ID}{'name'}($players{$ID}{'binID'}) ";
                        $players{$ID}{'state'} = $state;
                } elsif ($ID eq $accountID) {
                        $sourceDisplay = "";
                        $chars[$config{'char'}]{'state_last'} = $chars[$config{'char'}]{'state'};
                        $chars[$config{'char'}]{'state'} = $state;
                } else {
                        $sourceDisplay = "未知 ";
                }
                if ($ID eq $accountID && ($state ne $msgstrings_lut{'0119'}{"00"} && $state ne $msgstrings_lut{'0119'}{"B32"})) {
                        printC("I6M", "$sourceDisplay变成$targetDisplay\n") if ($config{'debug'});
                } elsif ($ID eq $accountID) {
                        printC("I6W", "$sourceDisplay变成$targetDisplay\n") if (($config{'debug'} && ($chars[$config{'char'}]{'state_last'} ne $msgstrings_lut{'0119'}{"00"} && $chars[$config{'char'}]{'state_last'} ne $msgstrings_lut{'0119'}{"B32"})) || $config{'debug'} >= 2);
                } else {
                        printC("I0", "$sourceDisplay变成$targetDisplay\n") if ($config{'debug'});
                }
                $msg_size = 54;

        } elsif ($switch eq "0079" && $MsgLength >= 53) {
                $ID = substr($msg, 2, 4);
                makeCoords(\%coords, substr($msg, 46, 3));
                $type = unpack("S*",substr($msg, 14,  2));
                $sex = unpack("C*",substr($msg, 45,  1));
                if ($jobs_lut{$type}) {
                        if (!%{$players{$ID}}) {
                                $players{$ID}{'appear_time'} = time;
                                binAdd(\@playersID, $ID);
                                $players{$ID}{'jobID'} = $type;
                                $players{$ID}{'sex'} = $sex;
                                $players{$ID}{'name'} = "Unknown";
                                $players{$ID}{'binID'} = binFind(\@playersID, $ID);
                                $players{$ID}{'AID'} = unpack("L1", $ID);
                                if ($aid_rlut{$players{$ID}{'AID'}}{'avoid'}) {
                                        %{$players{$ID}{'pos'}} = %coords;
                                        %{$players{$ID}{'pos_to'}} = %coords;
                                        binAdd(\@avoidID, $ID);
                                }
                        }
                        %{$players{$ID}{'pos'}} = %coords;
                        %{$players{$ID}{'pos_to'}} = %coords;
                        print "Player Connected: $players{$ID}{'name'}($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});

                } else {
                        print "Unknown Connected: $type - ".getHex($ID)."\n" if $config{'debug'};
                }
                $msg_size = 53;

        } elsif ($switch eq "007A" && $MsgLength >= 58) {
                $msg_size = 58;

        } elsif ($switch eq "007B" && $MsgLength >= 60) {
                $ID = substr($msg, 2, 4);
                makeCoords(\%coordsFrom, substr($msg, 50, 3));
                makeCoords2(\%coordsTo, substr($msg, 52, 3));
                $type = unpack("S*",substr($msg, 14,  2));
                $pet = unpack("C*",substr($msg, 16,  1));
                $sex = unpack("C*",substr($msg, 49,  1));
                if ($type >= 1000) {
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
                                print "Pet Moved: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});
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
                                        print "Monster Appeared: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if $config{'debug'};
                                        # ICE Start - MVP Monster
                                        %{$monsters{$ID}{'pos'}} = %coordsFrom;
                                        if ($config{'mvpMode'} && $monsters{$ID}{'mvp'} != 1 && ($mon_control{lc($monsters{$ID}{'name'})}{'attack_auto'} >=1 || ($mon_control{lc($monsters{$ID}{'name'})}{'attack_auto'} eq "" && $mon_control{'all'}{'attack_auto'} >= 1))) {
                                                if($importantMonsters_rlut{$monsters{$ID}{'name'}} == 1) {
                                                        $monsters{$ID}{'mvp'} = 1;
                                                        if (!$chars[$config{'char'}]{'mvp'}) {
                                                                ai_changeToMvpMode(1);
                                                                chatLog("m", "发现: $monsters{$ID}{'name'} $field{'name'} ($monsters{$ID}{'pos'}{'x'}, $monsters{$ID}{'pos'}{'y'})\n");
                                                                attack($ID) if ($config{'attackMvpFirst'});
                                                        }
                                                }
                                        }
                                        # ICE End
                                }
                                %{$monsters{$ID}{'pos'}} = %coordsFrom;
                                %{$monsters{$ID}{'pos_to'}} = %coordsTo;
                                print "Monster Moved: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if ($config{'debug'} >= 2);
                        }
                } elsif ($jobs_lut{$type}) {
                        if (!%{$players{$ID}}) {
                                binAdd(\@playersID, $ID);
                                $players{$ID}{'appear_time'} = time;
                                $players{$ID}{'sex'} = $sex;
                                $players{$ID}{'jobID'} = $type;
                                $players{$ID}{'name'} = "Unknown";
                                $players{$ID}{'binID'} = binFind(\@playersID, $ID);
                                $players{$ID}{'AID'} = unpack("L1", $ID);
                                if ($aid_rlut{$players{$ID}{'AID'}}{'avoid'}) {
                                        %{$players{$ID}{'pos'}} = %coords;
                                        %{$players{$ID}{'pos_to'}} = %coords;
                                        binAdd(\@avoidID, $ID);
                                }
                                print "Player Appeared: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$sex} $jobs_lut{$type}\n" if $config{'debug'};
                        }
                        %{$players{$ID}{'pos'}} = %coordsFrom;
                        %{$players{$ID}{'pos_to'}} = %coordsTo;
                        print "Player Moved: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'} >= 2);
                } else {
                        print "Unknown Moved: $type - ".getHex($ID)."\n" if $config{'debug'};
                }
                $msg_size = 60;

        } elsif ($switch eq "007C" && $MsgLength >= 41) {
                $ID = substr($msg, 2, 4);
                makeCoords(\%coords, substr($msg, 36, 3));
                $type = unpack("S*",substr($msg, 20,  2));
                $sex = unpack("C*",substr($msg, 35,  1));
                if ($type >= 1000) {
                        if (!%{$monsters{$ID}}) {
                                binAdd(\@monstersID, $ID);
                                $monsters{$ID}{'nameID'} = $type;
                                $monsters{$ID}{'appear_time'} = time;
                                $display = ($monsters_lut{$monsters{$ID}{'nameID'}} ne "")
                                                ? $monsters_lut{$monsters{$ID}{'nameID'}}
                                                : "Unknown ".$monsters{$ID}{'nameID'};
                                $monsters{$ID}{'name'} = $display;
                                $monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
                                # ICE Start - MVP Monster
                                %{$monsters{$ID}{'pos'}} = %coords;
                                if ($config{'mvpMode'} && $monsters{$ID}{'mvp'} != 1 && ($mon_control{lc($monsters{$ID}{'name'})}{'attack_auto'} >=1 || ($mon_control{lc($monsters{$ID}{'name'})}{'attack_auto'} eq "" && $mon_control{'all'}{'attack_auto'} >= 1))) {
                                        if($importantMonsters_rlut{$monsters{$ID}{'name'}} == 1) {
                                                $monsters{$ID}{'mvp'} = 1;
                                                if (!$chars[$config{'char'}]{'mvp'}) {
                                                        ai_changeToMvpMode(1);
                                                        chatLog("m", "发现: $monsters{$ID}{'name'} $field{'name'} ($monsters{$ID}{'pos'}{'x'}, $monsters{$ID}{'pos'}{'y'})\n");
                                                        attack($ID) if ($config{'attackMvpFirst'});
                                                }
                                        }
                                }
                                # ICE End
                        }
                        %{$monsters{$ID}{'pos'}} = %coords;
                        %{$monsters{$ID}{'pos_to'}} = %coords;
                        print "Monster Spawned: $monsters{$ID}{'name'}($monsters{$ID}{'binID'})\n" if ($config{'debug'});
                } elsif ($jobs_lut{$type}) {
                        if (!%{$players{$ID}}) {
                                binAdd(\@playersID, $ID);
                                $players{$ID}{'jobID'} = $type;
                                $players{$ID}{'sex'} = $sex;
                                $players{$ID}{'name'} = "Unknown";
                                $players{$ID}{'appear_time'} = time;
                                $players{$ID}{'binID'} = binFind(\@playersID, $ID);
                                $players{$ID}{'AID'} = unpack("L1", $ID);
                                if ($aid_rlut{$players{$ID}{'AID'}}{'avoid'}) {
                                        %{$players{$ID}{'pos'}} = %coords;
                                        %{$players{$ID}{'pos_to'}} = %coords;
                                        binAdd(\@avoidID, $ID);
                                }
                        }
                        %{$players{$ID}{'pos'}} = %coords;
                        %{$players{$ID}{'pos_to'}} = %coords;
                        print "Player Spawned: $players{$ID}{'name'}($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});
                } else {
                        print "Unknown Spawned: $type - ".getHex($ID)."\n" if $config{'debug'};
                }
                $msg_size = 41;

        } elsif ($switch eq "007D" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "007E" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "007F" && $MsgLength >= 6) {
                $time = unpack("L1",substr($msg, 2, 4));
                print "Recieved Sync\n" if ($config{'debug'} >= 2);
                $timeout{'play'}{'time'} = time;
                $msg_size = 6;

        } elsif ($switch eq "0080" && $MsgLength >= 7) {
                $ID = substr($msg, 2, 4);
                $type = unpack("C1",substr($msg, 6, 1));
                if ($ID eq $accountID) {
                        my $i = ai_getAggressives();
                        printC("I0Y", "你已经死亡了。附近有$i只怪物\n");
                        chatLog ("x","你已经死亡了。附近有$i只怪物\n");
                        $chars[$config{'char'}]{'dead'} = 1;
                        $chars[$config{'char'}]{'dead_time'} = time;
                        useTeleport(1);
                } elsif (%{$monsters{$ID}}) {
                        %{$monsters_old{$ID}} = %{$monsters{$ID}};
                        $monsters_old{$ID}{'gone_time'} = time;
                        if ($type == 0) {
                                print "Monster Disappeared: $monsters{$ID}{'name'}($monsters{$ID}{'binID'})\n" if $config{'debug'};
                                chatLog("m", "消失: $monsters{$ID}{'name'}\n") if ($monsters{$ID}{'mvp'} == 1);
                                $monsters_old{$ID}{'disappeared'} = 1;

                        } elsif ($type == 1) {
                                print "Monster Died: $monsters{$ID}{'name'}($monsters{$ID}{'binID'})\n" if $config{'debug'};
                                $monsters_old{$ID}{'dead'} = 1;
                                if ($monsters{$ID}{'mvp'} == 1) {
                                        chatLog("m", "死亡: $monsters{$ID}{'name'}\n");
                                        if ($monsters{$ID}{'name'} eq $mvp{'now_monster'}{'name'}) {
                                                $mvptime{$monsters{$ID}{'name'}} = int(time);
                                                $mvp{'last_monster'}{'name'} = $monsters{$ID}{'name'};
                                                sendMessage(\$remote_socket, "g", $monsters{$ID}{'name'}.",".$mvptime{$monsters{$ID}{'name'}});
                                                writeMvptimeFileIntact("$setupPath/mvptime.txt", \%mvptime);
                                                undef $mvp{'now_monster'}{'name'};
                                        }
                                }

                        } elsif ($type == 3) {
                                print "Monster Teleported: $monsters{$ID}{'name'}($monsters{$ID}{'binID'})\n" if $config{'debug'};
                                chatLog("m", "瞬移: $monsters{$ID}{'name'}\n") if ($monsters{$ID}{'mvp'} == 1);
                                $monsters_old{$ID}{'teleported'} = 1;
                        }
                        binRemove(\@monstersID, $ID);
                        undef %{$monsters{$ID}};
                } elsif (%{$players{$ID}}) {
                        if ($type == 0) {
                                print "Player Disappeared: $players{$ID}{'name'}($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if $config{'debug'};
                                %{$players_old{$ID}} = %{$players{$ID}};
                                $players_old{$ID}{'disappeared'} = 1;
                                $players_old{$ID}{'gone_time'} = time;
                                binRemove(\@playersID, $ID);
                                binRemove(\@avoidID, $ID);
                                undef %{$players{$ID}};
                                # ICE Start - Auto Shop
                                binRemove(\@venderListsID, $ID);
                                undef %{$venderLists{$ID}};
                                # ICE End
                        } elsif ($type == 1) {
                                printC("I1", "玩家死亡: $players{$ID}{'name'}($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n");
                                $players{$ID}{'dead'} = 1;
                                if ($config{'partyAutoResurrect'} > 0 && $chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'} ne "") {
                                        $chars[$config{'char'}]{'party'}{'users'}{$ID}{'dead_time'} = time;
                                        ai_stateResetParty($ID);
                                }
                        } elsif ($type == 2) {
                                print "Player Disconnected: $players{$ID}{'name'}\n" if $config{'debug'};
                                %{$players_old{$ID}} = %{$players{$ID}};
                                $players_old{$ID}{'disconnected'} = 1;
                                $players_old{$ID}{'gone_time'} = time;
                                binRemove(\@playersID, $ID);
                                binRemove(\@avoidID, $ID);
                                undef %{$players{$ID}};
                                for ($i = 0; $i < @partyUsersID; $i++) {
                                        next if ($partyUsersID[$i] eq "");
                                        if ($ID eq $_) {
                                                ai_stateResetParty($ID);
                                                undef $chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'x'};
                                                undef $chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'y'};
                                        }

                                }
                        } elsif ($type == 3) {
                                print "Player Teleported: $players{$ID}{'name'}($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if $config{'debug'};
                                %{$players_old{$ID}} = %{$players{$ID}};
                                $players_old{$ID}{'disappeared'} = 1;
                                $players_old{$ID}{'teleported'} = 1;
                                $players_old{$ID}{'gone_time'} = time;
                                binRemove(\@playersID, $ID);
                                binRemove(\@avoidID, $ID);
                                undef %{$players{$ID}};
                                for ($i = 0; $i < @partyUsersID; $i++) {
                                        next if ($partyUsersID[$i] eq "");
                                        if ($ID eq $_) {
                                                undef $chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'x'};
                                                undef $chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'y'};
                                        }

                                }
                        }
                } elsif (%{$players_old{$ID}}) {
                        if ($type == 2) {
                                print "Player Disconnected: $players_old{$ID}{'name'}\n" if $config{'debug'};
                                $players_old{$ID}{'disconnected'} = 1;
                                # ICE Start - Auto Shop
                                binRemove(\@venderListsID, $ID);
                                undef %{$venderLists{$ID}};
                                # ICE End
                        }
                } elsif (%{$portals{$ID}}) {
                        print "Portal Disappeared: $portals{$ID}{'name'}($portals{$ID}{'binID'})\n" if ($config{'debug'});
                        %{$portals_old{$ID}} = %{$portals{$ID}};
                        $portals_old{$ID}{'disappeared'} = 1;
                        $portals_old{$ID}{'gone_time'} = time;
                        binRemove(\@portalsID, $ID);
                        undef %{$portals{$ID}};
                } elsif (%{$npcs{$ID}}) {
                        print "NPC Disappeared: $npcs{$ID}{'name'}($npcs{$ID}{'binID'})\n" if ($config{'debug'});
                        %{$npcs_old{$ID}} = %{$npcs{$ID}};
                        $npcs_old{$ID}{'disappeared'} = 1;
                        $npcs_old{$ID}{'gone_time'} = time;
                        binRemove(\@npcsID, $ID);
                        undef %{$npcs{$ID}};
                } elsif (%{$pets{$ID}}) {
                        print "Pet Disappeared: $pets{$ID}{'name'}($pets{$ID}{'binID'})\n" if ($config{'debug'});
                        binRemove(\@petsID, $ID);
                        undef %{$pets{$ID}};
                } else {
                        print "Unknown Disappeared: ".getHex($ID)."\n" if $config{'debug'};
                }

                $msg_size = 7;

        } elsif ($switch eq "0081" && $MsgLength >= 3) {
                $type = unpack("C1", substr($msg, 2, 1));
                $conState = 1;
                undef $conState_tries;
                if ($type == 2) {
                        printC("S1R", "相同的账号角色 已经登录了\n");
                        chatLog("x", "相同的账号角色 已经登录了\n");
                        if ($config{'dcOnDualLogin'} == 1) {
                                printC("S0", "退出游戏\n");
                                $quit = 1;
                        } elsif ($config{'dcOnDualLogin'} >= 2) {
                                printC("S1R", "与服务器联机中断，等待 $config{'dcOnDualLogin'} 秒后重新连接...\n");
                                $timeout_ex{'master'}{'time'} = time;
                                $timeout_ex{'master'}{'timeout'} = $config{'dcOnDualLogin'};
                        }

                } elsif ($type == 3) {
                        printC("S1R", "无法与服务器同步\n");
                        chatLog("x", "无法与服务器同步\n");
                } elsif ($type == 6) {
                        printC("S1R", "储值点数已用完，结束游戏。\n");
                        chatLog("x", "储值点数已用完，结束游戏。\n");
                        sleep(3);
                        $quit = 1;
                } elsif ($type == 8) {
                        printC("S1R", "请稍后联机\n");
                }
                $msg_size = 3;

        } elsif ($switch eq "0082" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "0083" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "0084" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "0085" && $MsgLength >= 5) {
                $msg_size = 5;

        } elsif ($switch eq "0086" && $MsgLength >= 16) {
                $msg_size = 16;

        } elsif ($switch eq "0087" && $MsgLength >= 12) {
                makeCoords(\%coordsFrom, substr($msg, 6, 3));
                makeCoords2(\%coordsTo, substr($msg, 8, 3));
                %{$chars[$config{'char'}]{'pos'}} = %coordsFrom;
                %{$chars[$config{'char'}]{'pos_to'}} = %coordsTo;
                print "You move to: $coordsTo{'x'}, $coordsTo{'y'}\n" if $config{'debug'};
                $chars[$config{'char'}]{'time_move'} = time;
                $chars[$config{'char'}]{'time_move_calc'} = distance(\%{$chars[$config{'char'}]{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}) * $config{'seconds_per_block'};
                $msg_size = 12;

        } elsif ($switch eq "0088" && $MsgLength >= 10) {
                undef $level_real;
                # Long distance attack solution
                $ID = substr($msg, 2, 4);
                undef %coords;
                $coords{'x'} = unpack("S1", substr($msg, 6, 2));
                $coords{'y'} = unpack("S1", substr($msg, 8, 2));
                if ($ID eq $accountID) {
                        %{$chars[$config{'char'}]{'pos'}} = %coords;
                        %{$chars[$config{'char'}]{'pos_to'}} = %coords;
                        print "Movement interrupted, your coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n" if $config{'debug'};
                        aiRemove("move");
                } elsif (%{$monsters{$ID}}) {
                        %{$monsters{$ID}{'pos'}} = %coords;
                        %{$monsters{$ID}{'pos_to'}} = %coords;
                } elsif (%{$players{$ID}}) {
                        %{$players{$ID}{'pos'}} = %coords;
                        %{$players{$ID}{'pos_to'}} = %coords;
                } else {
                        #dumpData(substr($msg, 0, 10)) if ($config{'debug_packet'} >= 2);
                }
                $msg_size = 10;

        } elsif ($switch eq "0089" && $MsgLength >= 7) {
                $msg_size = 7;

        } elsif ($switch eq "008A" && $MsgLength >= 29) {
                $ID1 = substr($msg, 2, 4);
                $ID2 = substr($msg, 6, 4);
                $standing = unpack("C1", substr($msg, 26, 2)) - 2;
                $damage = unpack("S1", substr($msg, 22, 2));
                $damage1 = unpack("S1", substr($msg, 27, 2));
                $totaldamage = $damage;
                if ($ID1 eq $accountID && $damage != 0 && $damage1 > 0) {
                        $totaldamage += $damage1;
                }
                updateDamageTables($ID1, $ID2, $totaldamage);
                if ($ID1 eq $accountID) {
                        if (%{$monsters{$ID2}}) {
                                attackC("a", $ID1, $ID2, $damage, $damage1, $standing, "", "");
                        } elsif (%{$items{$ID2}}) {
                                print "You pick up Item: $items{$ID2}{'name'}($items{$ID2}{'binID'})\n" if $config{'debug'};
                                $items{$ID2}{'takenBy'} = $accountID;
                        } elsif ($ID2 == 0) {
                                if ($standing) {
                                        $chars[$config{'char'}]{'sitting'} = 0;
                                        printC("I6C", "已变成站立状态\n");
                                } else {
                                        $chars[$config{'char'}]{'sitting'} = 1;
                                        printC("I6C", "已变成坐下状态\n");
                                }
                        }
                } elsif ($ID2 eq $accountID) {
                        if (%{$monsters{$ID1}}) {
                                attackC("a", $ID1, $ID2, $damage, 0, 0, "", "");
                        }
                        undef $chars[$config{'char'}]{'time_cast'};
                } elsif (%{$monsters{$ID1}}) {
                        if (%{$players{$ID2}}) {
                                attackC("a", $ID1, $ID2, $damage, 0, 0, "", "") if ($config{'debug'});
                        }
                } elsif (%{$players{$ID1}}) {
                        if (%{$monsters{$ID2}}) {
                                attackC("a", $ID1, $ID2, $damage, 0, 0, "", "") if ($config{'debug'});
                        } elsif (%{$items{$ID2}}) {
                                $items{$ID2}{'takenBy'} = $ID1;
                                print "Player $players{$ID1}{'name'}($players{$ID1}{'binID'}) picks up Item $items{$ID2}{'name'}($items{$ID2}{'binID'})\n" if ($config{'debug'});
                        } elsif ($ID2 == 0) {
                                if ($standing) {
                                        $players{$ID1}{'sitting'} = 0;
                                        print "Player is Standing: $players{$ID1}{'name'}($players{$ID1}{'binID'})\n" if $config{'debug'};
                                } else {
                                        $players{$ID1}{'sitting'} = 1;
                                        print "Player is Sitting: $players{$ID1}{'name'}($players{$ID1}{'binID'})\n" if $config{'debug'};
                                }
                        }
                } else {
                        print "Unknown ".getHex($ID1)." attacks ".getHex($ID2)." - Dmg: $dmgdisplay\n" if $config{'debug'};
                }
                $msg_size = 29;

        } elsif ($switch eq "008B" && $MsgLength >= 23) {
                $msg_size = 23;

        } elsif ($switch eq "008C" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "008D" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                $ID = substr($msg, 4, 4);
                $chat = substr($msg, 8, $msg_size - 8);
                ($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
                chatLog("c", $chat."\n");
                $ai_cmdQue[$ai_cmdQue]{'type'} = "c";
                $ai_cmdQue[$ai_cmdQue]{'ID'} = $ID;
                $ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser;
                $ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg;
                $ai_cmdQue[$ai_cmdQue]{'time'} = time;
                $ai_cmdQue++;
                printC("C1W", "$chat\n");
                sendWindowsMessage("008D".chr(1).$chatMsgUser.chr(1).$chatMsg) if ($yelloweasy);
                # ICE Start - Avoid Player
                avoidChat($ID, $chatMsgUser, "");
                # ICE End
                # ICE Start - Auto chat
                if (!$chars[$config{'char'}]{'shopOpened'} && $chars[$config{'char'}]{'autochat'}{'send'} eq "" && ( time - $chars[$config{'char'}]{'autochat'}{'last_time'}) > rand(3)+1 && $config{'chatAutoPublic'} > rand(100) ) {
                        autoChat("c", $chatMsgUser, $chatMsg);
                }
                # ICE End

        } elsif ($switch eq "008E" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                $chat = substr($msg, 4, $msg_size - 4);
                ($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
                chatLog("c", $chat."\n");
                $ai_cmdQue[$ai_cmdQue]{'type'} = "c";
                $ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser;
                $ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg;
                $ai_cmdQue[$ai_cmdQue]{'time'} = time;
                $ai_cmdQue++;
                printC("C1W", "$chat\n");
                sendWindowsMessage("008D".chr(1).$chatMsgUser.chr(1).$chatMsg) if ($yelloweasy);

        } elsif ($switch eq "008F" && $MsgLength >= 4) {
                $msg_size = 4;

        } elsif ($switch eq "0090" && $MsgLength >= 7) {
                $msg_size = 7;

        } elsif ($switch eq "0091" && $MsgLength >= 22) {
                initMapChangeVars();
                for ($i = 0; $i < @ai_seq; $i++) {
                        ai_setMapChanged($i);
                }
                ($map_name) = substr($msg, 2, 16) =~ /([\s\S]*?)\000/;
                ($ai_v{'temp'}{'map'}) = $map_name =~ /([\s\S]*)\./;
                if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
                        getField("map/$ai_v{'temp'}{'map'}.fld", \%field);
                }
                $coords{'x'} = unpack("S1", substr($msg, 18, 2));
                $coords{'y'} = unpack("S1", substr($msg, 20, 2));
                %{$chars[$config{'char'}]{'pos'}} = %coords;
                %{$chars[$config{'char'}]{'pos_to'}} = %coords;
                printC("M6", "位置: $ai_v{'temp'}{'map'} ($chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'})\n") if ($config{'Mode'});
                print "Your Coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n" if $config{'debug'};
                print "Sending Map Loaded\n" if $config{'debug'};
                sendMapLoaded(\$remote_socket);
                $msg_size = 22;

                # ICE Start - Teleport
                if ($chars[$config{'char'}]{'teleport'} == 1) {
                        my $accIndex = ai_findIndexAutoSwitch($config{'accessoryDefault'});
                        ai_sendEquip($accIndex,"") if ($accIndex ne "");
                        undef $chars[$config{'char'}]{'teleport'};
                }
                # ICE End
                if (!$sendFlyMap && $mapip_lut{$ai_v{'temp'}{'map'}.'.rsw'}{'ip'} ne $map_ip) {
                        mapipModify($ai_v{'temp'}{'map'}.'.rsw', $map_ip);
                }

        } elsif ($switch eq "0092" && $MsgLength >= 28) {
                initMapChanged();
                $conState = 4;
                undef $conState_tries;
                for ($i = 0; $i < @ai_seq; $i++) {
                        ai_setMapChanged($i);
                }
                ($map_name) = substr($msg, 2, 16) =~ /([\s\S]*?)\000/;
                ($ai_v{'temp'}{'map'}) = $map_name =~ /([\s\S]*)\./;
                if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
                        getField("map/$ai_v{'temp'}{'map'}.fld", \%field);
                }
                $map_ip = makeIP(substr($msg, 22, 4));
                $map_port = unpack("S1", substr($msg, 26, 2));

                if (!$sendFlyMap && $mapip_lut{$ai_v{'temp'}{'map'}.'.rsw'}{'ip'} ne $map_ip) {
                        mapipModify($ai_v{'temp'}{'map'}.'.rsw', $map_ip);
                }

                format MAPINFO =
---------Map Change Info----------
MAP Name: @<<<<<<<<<<<<<<<<<<
            $map_name
MAP IP: @<<<<<<<<<<<<<<<<<<
            $map_ip
MAP Port: @<<<<<<<<<<<<<<<<<<
        $map_port
-------------------------------
.
                $~ = "MAPINFO";
                write;
                printC("S0", "关闭与地图服务器的连接\n");
                killConnection(\$remote_socket);
                $msg_size = 28;

        } elsif ($switch eq "0093" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "0094" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "0095" && $MsgLength >= 30) {
                $ID = substr($msg, 2, 4);
                if (%{$players{$ID}}) {
                        ($players{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
                        if ($avoidlist_rlut{$players{$ID}{'name'}}) {
                                $players{$ID}{'AID'} = unpack("L1", $ID);
                                binAdd(\@avoidID, $ID);
                                $aid_rlut{$players{$ID}{'AID'}}{'avoid'} = 1;
                        }
                        if ($config{'debug'} >= 2) {
                                $binID = binFind(\@playersID, $ID);
                                print "Player Info: $players{$ID}{'name'}($binID)\n";
                        }
                }
                if (%{$monsters{$ID}}) {
                        ($monsters{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
                        if ($config{'debug'} >= 2) {
                                $binID = binFind(\@monstersID, $ID);
                                print "Monster Info: $monsters{$ID}{'name'}($binID)\n";
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
                                print "NPC Info: $npcs{$ID}{'name'}($binID)\n";
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
                                print "Pet Info: $pets{$ID}{'name_given'}($binID)\n";
                        }
                }
                $msg_size = 30;

        } elsif ($switch eq "0096" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0097" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 28, length($msg)-28));
                $msg = substr($msg, 0, 28).$newmsg;
                ($privMsgUser) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
                $privMsg = substr($msg, 28, $msg_size - 29);
                if ($privMsgUser ne "" && binFind(\@privMsgUsers, $privMsgUser) eq "") {
                        $privMsgUsers[@privMsgUsers] = $privMsgUser;
                }
                chatLog("pm", "(From: $privMsgUser) : $privMsg\n");
                $ai_cmdQue[$ai_cmdQue]{'type'} = "pm";
                $ai_cmdQue[$ai_cmdQue]{'user'} = $privMsgUser;
                $ai_cmdQue[$ai_cmdQue]{'msg'} = $privMsg;
                $ai_cmdQue[$ai_cmdQue]{'time'} = time;
                $ai_cmdQue++;
                printC("C2Y", "(From: $privMsgUser) : $privMsg\n");
                sendWindowsMessage("0097".chr(1).$privMsgUser.chr(1).$privMsg) if ($yelloweasy);
                # ICE Start - Avoid Player
                avoidChat("", $privMsgUser, $privMsg);
                # ICE End
                # ICE Start - Auto Chat
                if ($chatMsgUser ne $chars[$config{'char'}]{'name'} && !$chars[$config{'char'}]{'shopOpened'} && $chars[$config{'char'}]{'autochat'}{'send'} eq "" && ( time - $chars[$config{'char'}]{'autochat'}{'last_time'} ) > rand(3)+1 && $config{'chatAutoPrivate'} > rand(100) ) {
                        autoChat("pm", $privMsgUser, $privMsg);
                }
                # ICE End

        } elsif ($switch eq "0098" && $MsgLength >= 3) {
                $type = unpack("C1",substr($msg, 2, 1));
                if ($type == 0) {
                        printC("C2Y", "(To $lastpm[0]{'user'}) : $lastpm[0]{'msg'}\n");
                        chatLog("pm", "(To: $lastpm[0]{'user'}) : $lastpm[0]{'msg'}\n");
                        sendWindowsMessage("0098".chr(1).$lastpm[0]{'user'}.chr(1).$lastpm[0]{'msg'}) if ($yelloweasy);
                } elsif ($type == 1) {
                        printC("S1R", "$lastpm[0]{'user'} 玩家不在线\n");
                } elsif ($type == 2) {
                        printC("S1R", "拒绝接收所有悄悄话讯息\n");
                }
                shift @lastpm;
                $msg_size = 3;

        } elsif ($switch eq "0099" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "009A" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                $chat = substr($msg, 4, $msg_size - 4);
                ($sysMsgUser, $sysMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
                chatLog("s", $chat."\n");
                printC("C0Y", "$chat\n");
                avoidChat("", $sysMsgUser, $sysMsg);

        } elsif ($switch eq "009B" && $MsgLength >= 5) {
                $msg_size = 5;

        } elsif ($switch eq "009C" && $MsgLength >= 9) {
                $ID = substr($msg, 2, 4);
                $body = unpack("C1",substr($msg, 8, 1));
                $head = unpack("C1",substr($msg, 6, 1));
                if ($ID eq $accountID) {
                        $chars[$config{'char'}]{'look'}{'head'} = $head;
                        $chars[$config{'char'}]{'look'}{'body'} = $body;
                        print "You look at $chars[$config{'char'}]{'look'}{'body'}, $chars[$config{'char'}]{'look'}{'head'}\n" if ($config{'debug'} >= 2);

                } elsif (%{$players{$ID}}) {
                        $players{$ID}{'look'}{'head'} = $head;
                        $players{$ID}{'look'}{'body'} = $body;
                        print "Player $players{$ID}{'name'}($players{$ID}{'binID'}) looks at $players{$ID}{'look'}{'body'}, $players{$ID}{'look'}{'head'}\n" if ($config{'debug'} >= 2);

                } elsif (%{$monsters{$ID}}) {
                        $monsters{$ID}{'look'}{'head'} = $head;
                        $monsters{$ID}{'look'}{'body'} = $body;
                        print "Monster $monsters{$ID}{'name'}($monsters{$ID}{'binID'}) looks at $monsters{$ID}{'look'}{'body'}, $monsters{$ID}{'look'}{'head'}\n" if ($config{'debug'} >= 2);
                }
                $msg_size = 9;

        } elsif ($switch eq "009D" && $MsgLength >= 17) {
                $ID = substr($msg, 2, 4);
                $type = unpack("S1",substr($msg, 6, 2));
                $x = unpack("S1", substr($msg, 9, 2));
                $y = unpack("S1", substr($msg, 11, 2));
                $amount = unpack("S1", substr($msg, 13, 2));
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
                printC("M2", "存在: $items{$ID}{'name'} x $items{$ID}{'amount'}\n") if ($config{'Mode'} >= 2);
                $msg_size = 17;

        } elsif ($switch eq "009E" && $MsgLength >= 17) {
                $ID = substr($msg, 2, 4);
                $type = unpack("S1",substr($msg, 6, 2));
                $x = unpack("S1", substr($msg, 9, 2));
                $y = unpack("S1", substr($msg, 11, 2));
                $amount = unpack("S1", substr($msg, 15, 2));
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
                printC("M2", "出现: $items{$ID}{'name'} x $items{$ID}{'amount'}\n") if ($config{'Mode'} >= 2);
                $msg_size = 17;
                # ICE Start - Important Item
                my $iDist = int(distance(\%{$items{$ID}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}));
                sendTake(\$remote_socket, $ID) if ($iDist < 8 && ($config{'itemsTakeAuto'} && ($itemsPickup{lc($items{$ID}{'name'})} eq "1" || ($itemsPickup{'all'} && $itemsPickup{lc($items{$ID}{'name'})} eq ""))));
                getImportantItems($ID, $iDist) if ($iDist <= $config{'attackDistance'} + 5);
                # ICE End

        } elsif ($switch eq "009F" && $MsgLength >= 6) {
                $msg_size = 6;

        # ICE Start - Equipment information
        } elsif ($switch eq "00A0" && $MsgLength >= 23) {
                $index = unpack("S1",substr($msg, 2, 2));
                $amount = unpack("S1",substr($msg, 4, 2));
                $ID = unpack("S1",substr($msg, 6, 2));
                $type = unpack("C1",substr($msg, 21, 1));
                $type_equip = unpack("C1",substr($msg, 19, 1));
                makeCoords(\%test, substr($msg, 8, 3));
                $fail = unpack("C1",substr($msg, 22, 1));
                undef $invIndex;
                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", $ID);
                if ($fail == 0) {
                        if ($invIndex eq "" || $itemSlots_lut{$ID} != 0) {
                                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = $ID;
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = $amount;
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = $type;
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} = $itemSlots_lut{$ID};
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = unpack("C1",substr($msg, 8, 1));
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'enchant'} = unpack("C1",substr($msg, 10, 1));
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'elementID'} = unpack("S1",substr($msg, 12, 2));
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'elementName'} = $elements_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'elementID'}};
                                undef @cnt;
                                $count = 0;
                                for($j=1 ;$j < 5;$j++) {
                                        if(unpack("S1", substr($msg, 9 + $j + $j, 2)) > 0) {
                                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'slotID_$j'} = unpack("S1", substr($msg, 9 + $j + $j, 2));
                                                for($k = 0;$k < 4;$k++) {
                                                        if(($chars[$config{'char'}]{'inventory'}[$invIndex]{'slotID_$j'} eq $cnt[$k]{'ID'}) && ($chars[$config{'char'}]{'inventory'}[$invIndex]{'slotID_$j'} ne "")) {
                                                                $cnt[$k]{'amount'} += 1;
                                                                last;
                                                        } elsif ($chars[$config{'char'}]{'inventory'}[$invIndex]{'slotID_$j'} ne "") {
                                                                $cnt[$k]{'amount'} = 1;
                                                                $cnt[$k]{'name'} = $cards_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'slotID_$j'}};
                                                                $cnt[$k]{'ID'} = $chars[$config{'char'}]{'inventory'}[$invIndex]{'slotID_$j'};
                                                                $count++;
                                                                last;
                                                        }
                                                }
                                        }
                                }
                                $display = "";
                                $count ++;
                                for($j = 0;$j < $count;$j++) {
                                        if($j == 0 && $cnt[$j]{'amount'}) {
                                                if($cnt[$j]{'amount'} > 1) {
                                                        $display .= "$cnt[$j]{'amount'}X$cnt[$j]{'name'}";
                                                } else {
                                                        $display .= "$cnt[$j]{'name'}";
                                                }
                                        } elsif ($cnt[$j]{'amount'}) {
                                                if($cnt[$j]{'amount'} > 1) {
                                                        $display .= ",$cnt[$j]{'amount'}X$cnt[$j]{'name'}";
                                                } else {
                                                        $display .= ",$cnt[$j]{'name'}";
                                                }
                                        }
                                }
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'slotName'} = $display;
                                undef @cnt;
                                undef $count;
                        } else {
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} += $amount;
                        }
                        $display = ($items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}} ne "")
                                ? $items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}
                                : "Unknown ".$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'};
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = $display;

                        $disp = "增加: $display";
                        $exp{'item'}{$ID}{'pick'} += $amount if (binFind(\@ai_seq, "buyAuto") eq "" && binFind(\@ai_seq, "storageAuto") eq "" && binFind(\@ai_seq, "sellAuto") eq "");
                        if($chars[$config{'char'}]{'inventory'}[$invIndex]{'enchant'} > 0) {
                                $disp .= " [+$chars[$config{'char'}]{'inventory'}[$invIndex]{'enchant'}]";
                        }
                        if($chars[$config{'char'}]{'inventory'}[$invIndex]{'elementName'} ne "") {
                                $disp .= " [$chars[$config{'char'}]{'inventory'}[$invIndex]{'elementName'}]";
                        }
                        if($chars[$config{'char'}]{'inventory'}[$invIndex]{'slotName'} ne "") {
                                $disp .= " [$chars[$config{'char'}]{'inventory'}[$invIndex]{'slotName'}]";
                        }
                        $disp .= " x $amount\n";
                        sendWindowsMessage("AA20".chr(1).$invIndex.chr(1).$type.chr(1).$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}.chr(1).$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'}) if ($yelloweasy);
                        if ($importantItems_rlut{$display} == 1) {
                                printC("I3Y", "获得: $display x $amount *\n");
                                chatLog("i", "获得: $display x $amount *\n");
                        } elsif ($config{'Mode'}) {
                                printC("I3", "$disp");
                        }
                        if ($ai_seq[0] eq "buyAuto" && !$items_control{lc($display)}{'sell'}) {
                                chatLog("b", "购买: $display x $amount\n");
                        }

                        if ($config{'cartAuto'} && $cart{'weight_max'} > 0 && ($cart{'weight'}/$cart{'weight_max'})*100 < $config{'cartMaxWeight'} && $cart{'items'} < $cart{'items_max'}) {
                                if ($ai_seq[0] eq "buyAuto") {
                                        $i = 0;
                                        while(1) {
                                                last if (!$config{"buyAuto_$i"} || !$config{"buyAuto_$i"."_npc"});
                                                if ($display eq $config{"buyAuto_$i"} && $config{"buyAuto_$i"."_maxCartAmount"} > 0 && $config{"buyAuto_$i"."_minAmount"} ne "" && $config{"buyAuto_$i"."_maxAmount"} ne "") {
                                                        $ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $display);
                                                        if ($ai_v{'temp'}{'cartIndex'} eq "" || ($ai_v{'temp'}{'cartIndex'} ne "" && $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} < $config{"buyAuto_$i"."_maxCartAmount"})) {
                                                                if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} > $config{"buyAuto_$i"."_maxCartAmount"} - $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'}) {
                                                                        sendCartAdd(\$remote_socket, $index, $config{"buyAuto_$i"."_maxCartAmount"} - $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'});
                                                                } else {
                                                                        sendCartAdd(\$remote_socket, $index, $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'});
                                                                }
                                                                $timeout{'ai_buyAuto'}{'time'} = time;
                                                                last;
                                                        }
                                                }
                                                $i++;
                                        }
                                } elsif ($ai_seq[0] eq "storageAuto") {
                                        $i = 0;
                                        while(1) {
                                                last if (!$config{"getAuto_$i"} || !$config{"getAuto_$i"."_npc"});
                                                if ($display eq $config{"getAuto_$i"} && $config{"getAuto_$i"."_maxCartAmount"} > 0 && $config{"getAuto_$i"."_minAmount"} ne "" && $config{"getAuto_$i"."_maxAmount"} ne "") {
                                                        $ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $display);
                                                        if ($ai_v{'temp'}{'cartIndex'} eq "" || ($ai_v{'temp'}{'cartIndex'} ne "" && $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} < $config{"getAuto_$i"."_maxCartAmount"})) {
                                                                if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} > $config{"getAuto_$i"."_maxCartAmount"} - $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'}) {
                                                                        sendCartAdd(\$remote_socket, $index, $config{"getAuto_$i"."_maxCartAmount"} - $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'});
                                                                } else {
                                                                        sendCartAdd(\$remote_socket, $index, $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'});
                                                                }
                                                                $timeout{'ai_storageAuto'}{'time'} = time;
                                                                last;
                                                        }
                                                }
                                                $i++;
                                        }
                                } elsif ($config{'cartAutoTake'} && binFind(\@ai_seq, "buyAuto") eq "" && binFind(\@ai_seq, "storageAuto") eq "" && binFind(\@ai_seq, "sellAuto") eq "") {
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
                        } elsif ($config{'itemsDropAuto'} && $itemsPickup{lc($display)} eq "0" && binFind(\@ai_seq, "buyAuto") eq "" && binFind(\@ai_seq, "storageAuto") eq "" && binFind(\@ai_seq, "sellAuto") eq "") {
                                sendDrop(\$remote_socket, $index, $amount);
                                $exp{'item'}{$ID}{'pick'} -= $amount;
                        }
                } elsif ($fail == 6) {
                        printC("I0", "无法捡取物品...请等待...\n") if ($config{'Mode'} >= 2);
                }
                $msg_size = 23;
        # ICE End

        } elsif ($switch eq "00A1" && $MsgLength >= 6) {
                $ID = substr($msg, 2, 4);
                if (%{$items{$ID}}) {
                        print "Item Disappeared: $items{$ID}{'name'}($items{$ID}{'binID'})\n" if $config{'debug'};
                        %{$items_old{$ID}} = %{$items{$ID}};
                        $items_old{$ID}{'disappeared'} = 1;
                        $items_old{$ID}{'gone_time'} = time;
                        undef %{$items{$ID}};
                        binRemove(\@itemsID, $ID);
                }
                $msg_size = 6;

        } elsif ($switch eq "00A2" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "00A3" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                undef $invIndex;
                for($i = 4; $i < $msg_size; $i+=10) {
                        $index = unpack("S1", substr($msg, $i, 2));
                        $ID = unpack("S1", substr($msg, $i + 2, 2));
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                        if ($invIndex eq "") {
                                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
                        }
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = $ID;
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = unpack("S1", substr($msg, $i + 6, 2));
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
                        $display = ($items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}} ne "")
                                ? $items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}
                                : "Unknown ".$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'};
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = $display;
                        if ($index == $EAIndex && $EAIndex ne "") {
                                undef $EAIndex;
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = 1;
                        }
                        print "Inventory: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}($invIndex) x $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}}\n" if $config{'debug'};
                }

        # ICE Start - Equipment Information
        } elsif ($switch eq "00A4" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                undef $invIndex;
                for($i = 4; $i < $msg_size; $i+=20) {
                        $index = unpack("S1", substr($msg, $i, 2));
                        $ID = unpack("S1", substr($msg, $i + 2, 2));
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                        if ($invIndex eq "") {
                                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = $ID;
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = 1;
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} = $itemSlots_lut{$ID};
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = unpack("C1", substr($msg, $i + 8, 1));
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'enchant'} = unpack("C1", substr($msg, $i + 11, 1));
                                if (unpack("C1", substr($msg, $i + 9, 1)) > 0) {
                                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = unpack("C1", substr($msg, $i + 9, 1));
                                }
                                $display = ($items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}} ne "")
                                        ? $items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}
                                        : "Unknown ".$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'};
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = $display;

                                undef @cnt;
                                $count = 0;
                                for($j=1 ;$j < 5;$j++) {
                                        if(unpack("S1", substr($msg, $i + 10 + $j + $j, 2)) > 0) {
                                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'slotID_$j'} = unpack("S1", substr($msg, $i + 10 + $j + $j, 2));
                                                for($k = 0;$k < 4;$k++) {
                                                        if(($chars[$config{'char'}]{'inventory'}[$invIndex]{'slotID_$j'} eq $cnt[$k]{'ID'}) && ($chars[$config{'char'}]{'inventory'}[$invIndex]{'slotID_$j'} ne "")) {
                                                                $cnt[$k]{'amount'} += 1;
                                                                last;
                                                        } elsif ($chars[$config{'char'}]{'inventory'}[$invIndex]{'slotID_$j'} ne "") {
                                                                $cnt[$k]{'amount'} = 1;
                                                                $cnt[$k]{'name'} = $cards_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'slotID_$j'}};
                                                                $cnt[$k]{'ID'} = $chars[$config{'char'}]{'inventory'}[$invIndex]{'slotID_$j'};
                                                                $count++;
                                                                last;
                                                        }
                                                }
                                        }
                                }
                                $display = "";
                                $count ++;
                                for($j = 0;$j < $count;$j++) {
                                        if($j == 0 && $cnt[$j]{'amount'}) {
                                                if($cnt[$j]{'amount'} > 1) {
                                                        $display .= "$cnt[$j]{'amount'}X$cnt[$j]{'name'}";
                                                } else {
                                                        $display .= "$cnt[$j]{'name'}";
                                                }
                                        } elsif ($cnt[$j]{'amount'}) {
                                                if($cnt[$j]{'amount'} > 1) {
                                                        $display .= ",$cnt[$j]{'amount'}X$cnt[$j]{'name'}";
                                                } else {
                                                        $display .= ",$cnt[$j]{'name'}";
                                                }
                                        }
                                }
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'slotName'} = $display;
                                undef @cnt;
                                undef $count;
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'elementID'} = unpack("S1",substr($msg, $i + 13, 2));
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'elementName'} = $elements_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'elementID'}};
                                print "Inventory: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} [+$chars[$config{'char'}]{'inventory'}[$invIndex]{'enchant'}] [$chars[$config{'char'}]{'inventory'}[$invIndex]{'slotName'}] [$chars[$config{'char'}]{'inventory'}[$invIndex]{'elementName'}] ($invIndex) x $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}} - $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}}\n" if $config{'debug'};
                        }
                }
        # ICE End

        # ICE Start - Storage bugfix
        } elsif ($switch eq "00A5" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                undef %storage;
                for($i = 4; $i < $msg_size; $i+=10) {
                        $index = unpack("S1", substr($msg, $i, 2));
                        $ID = unpack("S1", substr($msg, $i + 2, 2));
                        $storage{'inventory'}[$index]{'nameID'} = $ID;
                        $storage{'inventory'}[$index]{'amount'} = unpack("S1", substr($msg, $i + 6, 2));
                        $storage{'inventory'}[$index]{'type_equip'} = $itemSlots_lut{$ID};
                        $display = ($items_lut{$ID} ne "")
                                ? $items_lut{$ID}
                                : "Unknown ".$ID;
                        $storage{'inventory'}[$index]{'name'} = $display;
                        print "Storage: $storage{'inventory'}[$index]{'name'}($index) x $storage{'inventory'}[$index]{'amount'}\n" if ($config{'debug'});
                }
                printC("I4", "打开仓库\n");

        } elsif ($switch eq "00A6" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                for($i = 4; $i < $msg_size; $i+=20) {
                        $index = unpack("S1", substr($msg, $i, 2));
                        $ID = unpack("S1", substr($msg, $i + 2, 2));
                        $storage{'inventory'}[$index]{'nameID'} = $ID;
                        $storage{'inventory'}[$index]{'amount'} = 1;
                        $storage{'inventory'}[$index]{'type_equip'} = $itemSlots_lut{$ID};
                        $display = ($items_lut{$ID} ne "")
                                ? $items_lut{$ID}
                                : "Unknown ".$ID;
                        $storage{'inventory'}[$index]{'name'} = $display;
                        undef @cnt;
                        $count = 0;
                        for($j=1 ;$j < 5;$j++) {
                                if(unpack("S1", substr($msg, $i + 10 + $j + $j, 2)) > 0) {
                                        $storage{'inventory'}[$index]{'slotID_$j'} = unpack("S1", substr($msg, $i + 10 + $j + $j, 2));
                                        for($k = 0;$k < 4;$k++) {
                                                if(($storage{'inventory'}[$index]{'slotID_$j'} eq $cnt[$k]{'ID'}) && ($storage{'inventory'}[$index]{'slotID_$j'} ne "")) {
                                                        $cnt[$k]{'amount'} += 1;
                                                        last;
                                                } elsif ($storage{'inventory'}[$index]{'slotID_$j'} ne "") {
                                                        $cnt[$k]{'amount'} = 1;
                                                        $cnt[$k]{'name'} = $cards_lut{$storage{'inventory'}[$index]{'slotID_$j'}};
                                                        $cnt[$k]{'ID'} = $storage{'inventory'}[$index]{'slotID_$j'};
                                                        $count++;
                                                        last;
                                                }
                                        }
                                }
                        }
                        $display = "";
                        $count ++;
                        for($j = 0;$j < $count;$j++) {
                                if($j == 0 && $cnt[$j]{'amount'}) {
                                        if($cnt[$j]{'amount'} > 1) {
                                                $display .= "$cnt[$j]{'amount'}X$cnt[$j]{'name'}";
                                        } else {
                                                $display .= "$cnt[$j]{'name'}";
                                        }
                                } elsif ($cnt[$j]{'amount'}) {
                                        if($cnt[$j]{'amount'} > 1) {
                                                $display .= ",$cnt[$j]{'amount'}X$cnt[$j]{'name'}";
                                        } else {
                                                $display .= ",$cnt[$j]{'name'}";
                                        }
                                }
                        }
                        $storage{'inventory'}[$index]{'slotName'} = $display;
                        undef @cnt;
                        undef $count;
                        $storage{'inventory'}[$index]{'enchant'} = unpack("C1", substr($msg, $i + 11, 2));
                        $storage{'inventory'}[$index]{'elementID'} = unpack("S1",substr($msg, $i + 13, 2));
                        $storage{'inventory'}[$index]{'elementName'} = $elements_lut{$storage{'inventory'}[$index]{'elementID'}};
                        print "Storage Item: $storage{'inventory'}[$index]{'name'}($index) x $storage{'inventory'}[$index]{'amount'}\n" if ($config{'debug'});
                }
        # ICE End

        } elsif ($switch eq "00A7" && $MsgLength >= 8) {
                $msg_size = 8;

        } elsif ($switch eq "00A8" && $MsgLength >= 7) {
                $index = unpack("S1",substr($msg, 2, 2));
                $amount = unpack("C1",substr($msg, 6, 1));
                undef $invIndex;
                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $amount;
                if ($config{'Mode'}) {
                        printC("I3", "");
                        writeC("X", "使用: ");
                        writeC("G", "$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}");
                        writeC("X", " x $amount");
                        print "\n";
                }
                sendWindowsMessage("AA20".chr(1).$invIndex.chr(1).$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}.chr(1).$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}.chr(1).$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'}) if ($yelloweasy);
                undef $chars[$config{'char'}]{'sendItemUse'};
                if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
                        undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
                }
                $exp{'item'}{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}{'used'} += $amount;
                $msg_size = 7;

        } elsif ($switch eq "00A9" && $MsgLength >= 6) {
                $msg_size = 6;

        # ICE Start - Switch Weapon
        } elsif ($switch eq "00AA" && $MsgLength >= 7) {
                $index = unpack("S1",substr($msg, 2, 2));
                $type = unpack("S1",substr($msg, 4, 2));
                $fail = unpack("C1",substr($msg, 6, 1));
                undef $invIndex;
                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                if ($fail == 0) {
                        printC("I0R", "无法装备道具 $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}\n") if ($config{'Mode'} >= 2);
                } else {
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = $chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'};
                        $display = "$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}";
                        if($chars[$config{'char'}]{'inventory'}[$invIndex]{'enchant'} > 0) {
                                $display .= " [+$chars[$config{'char'}]{'inventory'}[$invIndex]{'enchant'}]";
                        }
                        if($chars[$config{'char'}]{'inventory'}[$invIndex]{'elementName'} ne "") {
                                $display .= "[$chars[$config{'char'}]{'inventory'}[$invIndex]{'elementName'}]";
                        }
                        if($chars[$config{'char'}]{'inventory'}[$invIndex]{'slotName'} ne "") {
                                $display .= "[$chars[$config{'char'}]{'inventory'}[$invIndex]{'slotName'}]";
                        }
                        $display .= "\n";
                        printC("I0G", "装备穿着完成 $display") if ($config{'Mode'} >= 2);
                }
                $msg_size = 7;
        # ICE End

        } elsif ($switch eq "00AB" && $MsgLength >= 4) {
                $msg_size = 4;

        } elsif ($switch eq "00AC" && $MsgLength >= 7) {
                $index = unpack("S1",substr($msg, 2, 2));
                $type = unpack("S1",substr($msg, 4, 2));
                undef $invIndex;
                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = "";
                $display = "$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}";
                if($chars[$config{'char'}]{'inventory'}[$invIndex]{'enchant'} > 0) {
                        $display .= " [+$chars[$config{'char'}]{'inventory'}[$invIndex]{'enchant'}]";
                        }
                if($chars[$config{'char'}]{'inventory'}[$invIndex]{'elementName'} ne "") {
                        $display .= "[$chars[$config{'char'}]{'inventory'}[$invIndex]{'elementName'}]";
                }
                if($chars[$config{'char'}]{'inventory'}[$invIndex]{'slotName'} ne "") {
                        $display .= "[$chars[$config{'char'}]{'inventory'}[$invIndex]{'slotName'}]";
                }
                $display .= "\n";
                printC("I0G", "装备卸下完成 $display") if ($config{'Mode'} >= 2);
                $msg_size = 7;

        } elsif ($switch eq "00AE" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "00AF" && $MsgLength >= 6) {
                $index = unpack("S1",substr($msg, 2, 2));
                $amount = unpack("S1",substr($msg, 4, 2));
                undef $invIndex;
                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                if (($config{'Mode'} < 2 || !$config{'debug'}) && $ai_seq[0] eq "attack" && $chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} == 10) {
                        # 不显示箭矢减少
                } else {
                        $display = "$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}";
                        if($chars[$config{'char'}]{'inventory'}[$invIndex]{'enchant'} > 0) {
                                $display .= " [+$chars[$config{'char'}]{'inventory'}[$invIndex]{'enchant'}]";
                        }
                        if($chars[$config{'char'}]{'inventory'}[$invIndex]{'elementName'} ne "") {
                                $display .= " [$chars[$config{'char'}]{'inventory'}[$invIndex]{'elementName'}]";
                        }
                        if($chars[$config{'char'}]{'inventory'}[$invIndex]{'slotName'} ne "") {
                                $display .= " [$chars[$config{'char'}]{'inventory'}[$invIndex]{'slotName'}]";
                        }
                        $display .= " x $amount\n";
                        printC("I3", "减少: $display") if ($config{'Mode'});
                }
                sendWindowsMessage("AA20".chr(1).$invIndex.chr(1).$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}.chr(1).$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}.chr(1).$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'}) if ($yelloweasy);
                if ($ai_seq[0] eq "sellAuto" && $items_control{lc($display)}{'sell'}) {
                        chatLog("b", "出售: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} x $amount\n");
                }
                $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $amount;
                if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
                        undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
                }
                $msg_size = 6;

        } elsif ($switch eq "00B0" && $MsgLength >= 8) {
                $type = unpack("S1",substr($msg, 2, 2));
                $val = unpack("L1",substr($msg, 4, 4));
                if ($type == 0) {
                        print "Something1: $val\n" if $config{'debug'};
                } elsif ($type == 3) {
                        print "Something2: $val\n" if $config{'debug'};
                } elsif ($type == 4) {
                        $val = abs($val);
                        printC("S0R", "你被禁言 $val 分钟...\n");
                        chatLog("gm", "你被禁言 $val 分钟...\n");
                        ($map_string) = $map_name =~ /([\s\S]*)\.gat/;
                        $sleeptime = int($val * 60 + rand() * 600);
                        printC("S0R", "躲避禁言,断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        chatLog("gm", "躲避禁言,断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        killConnection(\$remote_socket);
                        sleep($sleeptime);
                } elsif ($type == 5) {
                        $chars[$config{'char'}]{'hp'} = $val;
                        print "Hp: $val\n" if $config{'debug'};
                } elsif ($type == 6) {
                        $chars[$config{'char'}]{'hp_max'} = $val;
                        print "Max Hp: $val\n" if $config{'debug'};
                } elsif ($type == 7) {
                        $chars[$config{'char'}]{'sp'} = $val;
                        print "Sp: $val\n" if $config{'debug'};
                } elsif ($type == 8) {
                        $chars[$config{'char'}]{'sp_max'} = $val;
                        print "Max Sp: $val\n" if $config{'debug'};
                } elsif ($type == 9) {
                        $chars[$config{'char'}]{'points_free'} = $val;
                        print "Status Points: $val\n" if $config{'debug'};
                } elsif ($type == 11) {
                        $chars[$config{'char'}]{'lv'} = $val;
                        print "Level: $val\n" if $config{'debug'};
                } elsif ($type == 12) {
                        $chars[$config{'char'}]{'points_skill'} = $val;
                        print "Skill Points: $val\n" if $config{'debug'};
                } elsif ($type == 24) {
                        $chars[$config{'char'}]{'weight'} = int($val / 10);
                        print "Weight: $chars[$config{'char'}]{'weight'}\n" if $config{'debug'};
                } elsif ($type == 25) {
                        $chars[$config{'char'}]{'weight_max'} = int($val / 10);
                        print "Max Weight: $chars[$config{'char'}]{'weight_max'}\n" if $config{'debug'};
                } elsif ($type == 41) {
                        $chars[$config{'char'}]{'attack'} = $val;
                        print "Attack: $val\n" if $config{'debug'};
                } elsif ($type == 42) {
                        $chars[$config{'char'}]{'attack_bonus'} = $val;
                        print "Attack Bonus: $val\n" if $config{'debug'};
                } elsif ($type == 43) {
                        $chars[$config{'char'}]{'attack_magic_min'} = $val;
                        print "Magic Attack Min: $val\n" if $config{'debug'};
                } elsif ($type == 44) {
                        $chars[$config{'char'}]{'attack_magic_max'} = $val;
                        print "Magic Attack Max: $val\n" if $config{'debug'};
                } elsif ($type == 45) {
                        $chars[$config{'char'}]{'def'} = $val;
                        print "Defense: $val\n" if $config{'debug'};
                } elsif ($type == 46) {
                        $chars[$config{'char'}]{'def_bonus'} = $val;
                        print "Defense Bonus: $val\n" if $config{'debug'};
                } elsif ($type == 47) {
                        $chars[$config{'char'}]{'def_magic'} = $val;
                        print "Magic Defense: $val\n" if $config{'debug'};
                } elsif ($type == 48) {
                        $chars[$config{'char'}]{'def_magic_bonus'} = $val;
                        print "Magic Defense Bonus: $val\n" if $config{'debug'};
                } elsif ($type == 49) {
                        $chars[$config{'char'}]{'hit'} = $val;
                        print "Hit: $val\n" if $config{'debug'};
                } elsif ($type == 50) {
                        $chars[$config{'char'}]{'flee'} = $val;
                        print "Flee: $val\n" if $config{'debug'};
                } elsif ($type == 51) {
                        $chars[$config{'char'}]{'flee_bonus'} = $val;
                        print "Flee Bonus: $val\n" if $config{'debug'};
                } elsif ($type == 52) {
                        $chars[$config{'char'}]{'critical'} = $val;
                        print "Critical: $val\n" if $config{'debug'};
                } elsif ($type == 53) {
                        $chars[$config{'char'}]{'attack_speed'} = 200 - $val/10;
                        print "Attack Speed: $chars[$config{'char'}]{'attack_speed'}\n" if $config{'debug'};
                } elsif ($type == 55) {
                        $chars[$config{'char'}]{'lv_job'} = $val;
                        print "Job Level: $val\n" if $config{'debug'};
                } elsif ($type == 124) {
                        print "Something3: $val\n" if $config{'debug'};
                } else {
                        print "Something: $val\n" if $config{'debug'};
                }
                $msg_size = 8;

        } elsif ($switch eq "00B1" && $MsgLength >= 8) {
                $type = unpack("S1",substr($msg, 2, 2));
                $val = unpack("L1",substr($msg, 4, 4));
                if ($type == 1) {
                        $chars[$config{'char'}]{'exp_last'} = $chars[$config{'char'}]{'exp'};
                        $chars[$config{'char'}]{'exp'} = $val;
                        print "Exp: $val\n" if $config{'debug'};
                        if (!$exp{'base'}{'baseExp_get'} && $chars[$config{'char'}]{'exp'} > $chars[$config{'char'}]{'exp_last'}) {
                                $exp{'monster'}{$exp{'monster'}{'nameID'}}{'baseExp'} += $chars[$config{'char'}]{'exp'} - $chars[$config{'char'}]{'exp_last'};
                                $exp{'base'}{'baseExp_get'} = $chars[$config{'char'}]{'exp'} - $chars[$config{'char'}]{'exp_last'};
                        } elsif ($chars[$config{'char'}]{'exp'} < $chars[$config{'char'}]{'exp_last'}) {
                                $exp{'base'}{'dead'}++;
                        }
                } elsif ($type == 2) {
                        $chars[$config{'char'}]{'exp_job_last'} = $chars[$config{'char'}]{'exp_job'};
                        $chars[$config{'char'}]{'exp_job'} = $val;
                        print "Job Exp: $val\n" if $config{'debug'};
                        if (!$exp{'base'}{'jobExp_get'} && $chars[$config{'char'}]{'exp_job'} > $chars[$config{'char'}]{'exp_job_last'}) {
                                $exp{'monster'}{$exp{'monster'}{'nameID'}}{'jobExp'} += $chars[$config{'char'}]{'exp_job'} - $chars[$config{'char'}]{'exp_job_last'};
                                $exp{'base'}{'jobExp_get'} = $chars[$config{'char'}]{'exp_job'} - $chars[$config{'char'}]{'exp_job_last'};
                        }
                } elsif ($type == 20) {
                        $chars[$config{'char'}]{'zenny'} = $val;
                        print "Zenny: $val\n" if $config{'debug'};
                } elsif ($type == 22) {
                        $chars[$config{'char'}]{'exp_max_last'} = $chars[$config{'char'}]{'exp_max'};
                        $chars[$config{'char'}]{'exp_max'} = $val;
                        print "Required Exp: $val\n" if $config{'debug'};
                        # ICE Start - EXP Calculation
                        if ($chars[$config{'char'}]{'exp_max_last'} > 0 && $chars[$config{'char'}]{'exp_max'} > $chars[$config{'char'}]{'exp_max_last'}) {
                                $chars[$config{'char'}]{'exp_start'} = $chars[$config{'char'}]{'exp_start'} - $chars[$config{'char'}]{'exp_max_last'};
                                $exp{'base'}{'dead'}--;
                        }
                        # ICE End
                } elsif ($type == 23) {
                        $chars[$config{'char'}]{'exp_job_max_last'} = $chars[$config{'char'}]{'exp_job_max'};
                        $chars[$config{'char'}]{'exp_job_max'} = $val;
                        print "Required Job Exp: $val\n" if $config{'debug'};
                        # ICE Start - EXP Calculation
                        if ($chars[$config{'char'}]{'exp_job_max_last'} > 0 && $chars[$config{'char'}]{'exp_job_max'} > $chars[$config{'char'}]{'exp_job_max_last'}) {
                                $chars[$config{'char'}]{'exp_job_start'} = $chars[$config{'char'}]{'exp_job_start'} - $chars[$config{'char'}]{'exp_job_max_last'};
                        }
                        # ICE End
                }
                $msg_size = 8;

        } elsif ($switch eq "00B2" && $MsgLength >= 3) {
                $msg_size = 3;

        } elsif ($switch eq "00B3" && $MsgLength >= 3) {
                $msg_size = 3;

        } elsif ($switch eq "00B4" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
                $msg = substr($msg, 0, 8).$newmsg;
                $ID = substr($msg, 4, 4);
                ($talk) = substr($msg, 8, $msg_size - 8) =~ /([\s\S]*?)\000/;
                $talk{'ID'} = $ID;
                $talk{'nameID'} = unpack("L1", $ID);
                $talk{'msg'} = $talk;
                printC("I7", "$npcs{$ID}{'name'} : $talk{'msg'}\n");

        } elsif ($switch eq "00B5" && $MsgLength >= 6) {
                $ID = substr($msg, 2, 4);
                printC("I7W", "$npcs{$ID}{'name'} : 输入 'talk cont' 继续对话\n");
                $msg_size = 6;

        } elsif ($switch eq "00B6" && $MsgLength >= 6) {
                $ID = substr($msg, 2, 4);
                undef %talk;
                printC("I7W", "$npcs{$ID}{'name'} : 对话完毕\n");
                sendTalkCancel(\$remote_socket,$ID);
                $msg_size = 6;

        } elsif ($switch eq "00B7" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
                $msg = substr($msg, 0, 8).$newmsg;
                $ID = substr($msg, 4, 4);
                ($talk) = substr($msg, 8, $msg_size - 8) =~ /([\s\S]*?)\000/;
                @preTalkResponses = split /:/, $talk;
                undef @{$talk{'responses'}};
                foreach (@preTalkResponses) {
                        push @{$talk{'responses'}}, $_ if $_ ne "";
                }
                $talk{'responses'}[@{$talk{'responses'}}] = "Cancel Chat";
                $~ = "RESPONSESLIST";
                print "----------Responses-----------\n";
                print "#  Response\n";
                for ($i=0; $i < @{$talk{'responses'}};$i++) {
                        format RESPONSESLIST =
@< @<<<<<<<<<<<<<<<<<<<<<<
$i $talk{'responses'}[$i]
.
                        write;
                }
                print "-------------------------------\n";
                printC("I7W", "$npcs{$ID}{'name'} : 输入 'talk resp' 选择回答\n");

        } elsif ($switch eq "00B8" && $MsgLength >= 7) {
                $msg_size = 7;

        } elsif ($switch eq "00B9" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "00BA" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "00BB" && $MsgLength >= 5) {
                $msg_size = 5;

        } elsif ($switch eq "00BC" && $MsgLength >= 6) {
                $type = unpack("S1",substr($msg, 2, 2));
                $val = unpack("C1",substr($msg, 5, 1));
                if ($val == 207) {
                        printC("I0R", "没有足够的属性点数\n");
                } else {
                        if ($type == 13) {
                                $chars[$config{'char'}]{'str'} = $val;
                                print "Strength: $val\n" if $config{'debug'};
                        } elsif ($type == 14) {
                                $chars[$config{'char'}]{'agi'} = $val;
                                print "Agility: $val\n" if $config{'debug'};
                        } elsif ($type == 15) {
                                $chars[$config{'char'}]{'vit'} = $val;
                                print "Vitality: $val\n" if $config{'debug'};
                        } elsif ($type == 16) {
                                $chars[$config{'char'}]{'int'} = $val;
                                print "Intelligence: $val\n" if $config{'debug'};
                        } elsif ($type == 17) {
                                $chars[$config{'char'}]{'dex'} = $val;
                                print "Dexterity: $val\n" if $config{'debug'};
                        } elsif ($type == 18) {
                                $chars[$config{'char'}]{'luk'} = $val;
                                print "Luck: $val\n" if $config{'debug'};
                        } else {
                                print "Something: $val\n";
                        }
                }
                $msg_size = 6;


        } elsif ($switch eq "00BD" && $MsgLength >= 44) {
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
                $chars[$config{'char'}]{'attack_magic_min'} = unpack("S1", substr($msg, 20, 2));
                $chars[$config{'char'}]{'attack_magic_max'} = unpack("S1", substr($msg, 22, 2));
                $chars[$config{'char'}]{'def'} = unpack("S1", substr($msg, 24, 2));
                $chars[$config{'char'}]{'def_bonus'} = unpack("S1", substr($msg, 26, 2));
                $chars[$config{'char'}]{'def_magic'} = unpack("S1", substr($msg, 28, 2));
                $chars[$config{'char'}]{'def_magic_bonus'} = unpack("S1", substr($msg, 30, 2));
                $chars[$config{'char'}]{'hit'} = unpack("S1", substr($msg, 32, 2));
                $chars[$config{'char'}]{'flee'} = unpack("S1", substr($msg, 34, 2));
                $chars[$config{'char'}]{'flee_bonus'} = unpack("S1", substr($msg, 36, 2));
                $chars[$config{'char'}]{'critical'} = unpack("S1", substr($msg, 38, 2));
                print        "Strength: $chars[$config{'char'}]{'str'} #$chars[$config{'char'}]{'points_str'}\n"
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
                        ,"Status Points: $chars[$config{'char'}]{'points_free'}\n"
                        if $config{'debug'};
                $msg_size = 44;

        } elsif ($switch eq "00BE" && $MsgLength >= 5) {
                $type = unpack("S1",substr($msg, 2, 2));
                $val = unpack("C1",substr($msg, 4, 1));
                if ($type == 32) {
                        $chars[$config{'char'}]{'points_str'} = $val;
                        print "Points needed for Strength: $val\n" if $config{'debug'};
                } elsif ($type == 33) {
                        $chars[$config{'char'}]{'points_agi'} = $val;
                        print "Points needed for Agility: $val\n" if $config{'debug'};
                } elsif ($type == 34) {
                        $chars[$config{'char'}]{'points_vit'} = $val;
                        print "Points needed for Vitality: $val\n" if $config{'debug'};
                } elsif ($type == 35) {
                        $chars[$config{'char'}]{'points_int'} = $val;
                        print "Points needed for Intelligence: $val\n" if $config{'debug'};
                } elsif ($type == 36) {
                        $chars[$config{'char'}]{'points_dex'} = $val;
                        print "Points needed for Dexterity: $val\n" if $config{'debug'};
                } elsif ($type == 37) {
                        $chars[$config{'char'}]{'points_luk'} = $val;
                        print "Points needed for Luck: $val\n" if $config{'debug'};
                }
                $msg_size = 5;

        } elsif ($switch eq "00BF" && $MsgLength >= 3) {
                $msg_size = 3;

        } elsif ($switch eq "00C0" && $MsgLength >= 7) {
                $ID = substr($msg, 2, 4);
                $type = unpack("C*", substr($msg, 6, 1));
                if ($ID eq $accountID) {
                        printC("I0", "$chars[$config{'char'}]{'name'} : $emotions_lut{$type}\n") if ($config{'Mode'});
                } elsif (%{$players{$ID}}) {
                        printC("I1", "$players{$ID}{'name'} : $emotions_lut{$type}\n") if ($config{'Mode'});
                }
                $msg_size = 7;

        } elsif ($switch eq "00C1" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "00C2" && $MsgLength >= 6) {
                $users = unpack("L*", substr($msg, 2, 4));
                printC("S0", "在线人数 $users\n");
                $msg_size = 6;

        } elsif ($switch eq "00C3" && $MsgLength >= 8) {
                $msg_size = 8;

        } elsif ($switch eq "00C4" && $MsgLength >= 6) {
                $ID = substr($msg, 2, 4);
                undef %talk;
                $talk{'buyOrSell'} = 1;
                $talk{'ID'} = $ID;
                printC("I7", "$npcs{$ID}{'name'} : 输入 'store' 开始购买, 输入 'sell' 开始出售\n");
                $msg_size = 6;

        } elsif ($switch eq "00C5" && $MsgLength >= 7) {
                $msg_size = 7;

        } elsif ($switch eq "00C6" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                undef @storeList;
                $storeList = 0;
                undef $talk{'buyOrSell'};
                for ($i = 4; $i < $msg_size; $i+=11) {
                        $price = unpack("L1", substr($msg, $i, 4));
                        $type = unpack("C1", substr($msg, $i + 8, 1));
                        $ID = unpack("S1", substr($msg, $i + 9, 2));
                        $storeList[$storeList]{'nameID'} = $ID;
                        $display = ($items_lut{$ID} ne "")
                                ? $items_lut{$ID}
                                : "Unknown ".$ID;
                        $storeList[$storeList]{'name'} = $display;
                        $storeList[$storeList]{'nameID'} = $ID;
                        $storeList[$storeList]{'type'} = $type;
                        $storeList[$storeList]{'price'} = $price;
                        print "Item added to Store: $storeList[$storeList]{'name'} - $price z\n" if ($config{'debug'} >= 2);
                        $storeList++;
                }
                printC("I7", "$npcs{$talk{'ID'}}{'name'} : 接收购买列表\n");

        } elsif ($switch eq "00C7" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                #sell list, similar to buy list
                $msg_size = $dMsgLength;
                if (length($msg) > 4) {
                        decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                        $msg = substr($msg, 0, 4).$newmsg;
                }
                undef $talk{'buyOrSell'};
                printC("I7", "准备开始出售物品\n");

        } elsif ($switch eq "00C8" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "00C9" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "00CA" && $MsgLength >= 3) {
                $msg_size = 3;

        } elsif ($switch eq "00CB" && $MsgLength >= 3) {
                $msg_size = 3;

        } elsif ($switch eq "00CC" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "00CD" && $MsgLength >= 3) {
                $msg_size = 3;

        } elsif ($switch eq "00CE" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "00CF" && $MsgLength >= 27) {
                $msg_size = 27;

        } elsif ($switch eq "00D0" && $MsgLength >= 3) {
                $msg_size = 3;

        } elsif ($switch eq "00D1" && $MsgLength >= 4) {
                $type = unpack("C1", substr($msg, 2, 1));
                $error = unpack("C1", substr($msg, 3, 1));
                if ($type == 0) {
                        printC("I0R", "拒绝悄悄话状态\n");
                } elsif ($type == 1) {
                        if ($error == 0) {
                                printC("I0C", "开启悄悄话状态\n");
                        }
                }
                $msg_size = 4;

        } elsif ($switch eq "00D2" && $MsgLength >= 4) {
                $type = unpack("C1", substr($msg, 2, 1));
                $error = unpack("C1", substr($msg, 3, 1));
                if ($type == 0) {
                        printC("I0R", "拒绝接收所有悄悄话讯息\n");
                } elsif ($type == 1) {
                        if ($error == 0) {
                                printC("I0C", "开启接收所有悄悄话功能\n");
                        }
                }
                $msg_size = 4;

        } elsif ($switch eq "00D3" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "00D4" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "00D5" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "00D6" && $MsgLength >= 3) {
                $currentChatRoom = "new";
                %{$chatRooms{'new'}} = %createdChatRoom;
                binAdd(\@chatRoomsID, "new");
                binAdd(\@currentChatRoomUsers, $chars[$config{'char'}]{'name'});
                printC("I0C", "开启聊天室成功\n");
                $msg_size = 3;

        } elsif ($switch eq "00D7" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 17, length($msg)-17));
                $msg = substr($msg, 0, 17).$newmsg;
                $ID = substr($msg,8,4);
                if (!%{$chatRooms{$ID}}) {
                        binAdd(\@chatRoomsID, $ID);
                }
                $chatRooms{$ID}{'title'} = substr($msg,17,$msg_size - 17);
                $chatRooms{$ID}{'ownerID'} = substr($msg,4,4);
                $chatRooms{$ID}{'limit'} = unpack("S1",substr($msg,12,2));
                $chatRooms{$ID}{'public'} = unpack("C1",substr($msg,16,1));
                $chatRooms{$ID}{'num_users'} = unpack("S1",substr($msg,14,2));

        } elsif ($switch eq "00D8" && $MsgLength >= 6) {
                $ID = substr($msg,2,4);
                binRemove(\@chatRoomsID, $ID);
                undef %{$chatRooms{$ID}};
                $msg_size = 6;

        } elsif ($switch eq "00D9" && $MsgLength >= 14) {
                $msg_size = 14;

        } elsif ($switch eq "00DA" && $MsgLength >= 3) {
                $type = unpack("C1",substr($msg, 2, 1));
                if ($type == 1) {
                        printC("I0R", "此聊天室人密码错误，无法进入\n");
                } elsif ($type == 2) {
                        printC("I0R", "被拒绝进入此聊天室\n");
                }
                $msg_size = 3;

        } elsif ($switch eq "00DB" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
                $msg = substr($msg, 0, 8).$newmsg;
                $ID = substr($msg,4,4);
                $currentChatRoom = $ID;
                $chatRooms{$currentChatRoom}{'num_users'} = 0;
                for ($i = 8; $i < $msg_size; $i+=28) {
                        $type = unpack("C1",substr($msg,$i,1));
                        ($chatUser) = substr($msg,$i + 4,24) =~ /([\s\S]*?)\000/;
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
                printC("I0", "");
                print qq~进入聊天室 "$chatRooms{$currentChatRoom}{'title'}"\n~;

        } elsif ($switch eq "00DC" && $MsgLength >= 28) {
                if ($currentChatRoom ne "") {
                        $num_users = unpack("S1", substr($msg,2,2));
                        ($joinedUser) = substr($msg,4,24) =~ /([\s\S]*?)\000/;
                        binAdd(\@currentChatRoomUsers, $joinedUser);
                        $chatRooms{$currentChatRoom}{'users'}{$joinedUser} = 1;
                        $chatRooms{$currentChatRoom}{'num_users'} = $num_users;
                        printC("I0", "$joinedUser 进入聊天室\n");
                }
                $msg_size = 28;

        } elsif ($switch eq "00DD" && $MsgLength >= 29) {
                $num_users = unpack("S1", substr($msg,2,2));
                ($leaveUser) = substr($msg,4,24) =~ /([\s\S]*?)\000/;
                $chatRooms{$currentChatRoom}{'users'}{$leaveUser} = "";
                binRemove(\@currentChatRoomUsers, $leaveUser);
                $chatRooms{$currentChatRoom}{'num_users'} = $num_users;
                if ($leaveUser eq $chars[$config{'char'}]{'name'}) {
                        binRemove(\@chatRoomsID, $currentChatRoom);
                        undef %{$chatRooms{$currentChatRoom}};
                        undef @currentChatRoomUsers;
                        $currentChatRoom = "";
                        printC("I0", "离开聊天室\n");
                } else {
                        printC("I0", "$leaveUser 离开聊天室\n");
                }
                $msg_size = 29;

        } elsif ($switch eq "00DE" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "00DF" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 17, length($msg)-17));
                $msg = substr($msg, 0, 17).$newmsg;
                $ID = substr($msg,8,4);
                $ownerID = substr($msg,4,4);
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
                printC("I0", "聊天室属性变更\n");

        } elsif ($switch eq "00E0" && $MsgLength >= 30) {
                $msg_size = 30;

        } elsif ($switch eq "00E1" && $MsgLength >= 30) {
                $type = unpack("C1",substr($msg, 2, 1));
                ($chatUser) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
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
                $msg_size = 30;

        } elsif ($switch eq "00E3" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "00E4" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "00E5" && $MsgLength >= 26) {
                ($dealUser) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
                $incomingDeal{'name'} = $dealUser;
                $timeout{'ai_dealAutoCancel'}{'time'} = time;
                printC("I0W", "$dealUser (先生／小姐)询问您愿不愿意交易道具\n");
                $msg_size = 26;

        } elsif ($switch eq "00E6" && $MsgLength >= 3) {
                $msg_size = 3;

        } elsif ($switch eq "00E7" && $MsgLength >= 3) {
                $type = unpack("C1", substr($msg, 2, 1));

                if ($type == 3) {
                        if (%incomingDeal) {
                                $currentDeal{'name'} = $incomingDeal{'name'};
                        } else {
                                $currentDeal{'ID'} = $outgoingDeal{'ID'};
                                $currentDeal{'name'} = $players{$outgoingDeal{'ID'}}{'name'};
                        }
                        printC("I0W", "接受交易邀请 $currentDeal{'name'}\n");
                }
                undef %outgoingDeal;
                undef %incomingDeal;
                $msg_size = 3;

        } elsif ($switch eq "00E8" && $MsgLength >= 8) {
                $msg_size = 8;

        } elsif ($switch eq "00E9" && $MsgLength >= 19) {
                $amount = unpack("L*", substr($msg, 2,4));
                $ID = unpack("S*", substr($msg, 6,2));
                if ($ID > 0) {
                        $currentDeal{'other'}{$ID}{'amount'} += $amount;
                        $display = ($items_lut{$ID} ne "")
                                        ? $items_lut{$ID}
                                        : "Unknown ".$ID;
                        $currentDeal{'other'}{$ID}{'name'} = $display;
                        if($itemSlots_lut{$ID} != 0) {
                                $currentDeal{'other'}{$ID}{'enchant'} = unpack("C1", substr($msg, 10, 2));
                                $currentDeal{'other'}{$ID}{'elementID'} = unpack("S1",substr($msg, 12, 2));
                                $currentDeal{'other'}{$ID}{'elementName'} = $elements_lut{$currentDeal{'other'}{$ID}{'elementID'}};
                                undef @cnt;
                                $count = 0;
                                for($j=1 ;$j < 5;$j++) {
                                        if(unpack("S1", substr($msg, 9 + $j + $j, 2)) > 0) {
                                                $currentDeal{'other'}{$ID}{'slotID_$j'} = unpack("S1", substr($msg, 9 + $j + $j, 2));
                                                for($k = 0;$k < 4;$k++) {
                                                        if(($currentDeal{'other'}{$ID}{'slotID_$j'} eq $cnt[$k]{'ID'}) && ($currentDeal{'other'}{$ID}{'slotID_$j'} ne "")) {
                                                                $cnt[$k]{'amount'} += 1;
                                                                last;
                                                        } elsif ($currentDeal{'other'}{$ID}{'slotID_$j'} ne "") {
                                                                $cnt[$k]{'amount'} = 1;
                                                                $cnt[$k]{'name'} = $cards_lut{$currentDeal{'other'}{$ID}{'slotID_$j'}};
                                                                $cnt[$k]{'ID'} = $currentDeal{'other'}{$ID}{'slotID_$j'};
                                                                $count++;
                                                                last;
                                                        }
                                                }
                                        }
                                }
                                $display = "";
                                $count ++;
                                for($j = 0;$j < $count;$j++) {
                                        if($j == 0 && $cnt[$j]{'amount'}) {
                                                if($cnt[$j]{'amount'} > 1) {
                                                        $display .= "$cnt[$j]{'amount'}-?$cnt[$j]{'name'}";
                                                } else {
                                                        $display .= "$cnt[$j]{'name'}";
                                                }
                                        } elsif ($cnt[$j]{'amount'}) {
                                                if($cnt[$j]{'amount'} > 1) {
                                                        $display .= ",$cnt[$j]{'amount'}-?$cnt[$j]{'name'}";
                                                } else {
                                                        $display .= ",$cnt[$j]{'name'}";
                                                }
                                        }
                                }
                                $currentDeal{'other'}{$ID}{'slotName'} = $display;
                                undef @cnt;
                                undef $count;
                        }
                        $display = "$currentDeal{'name'} 加入交易物品: $currentDeal{'other'}{$ID}{'name'}";
                        if($currentDeal{'other'}{$ID}{'enchant'} > 0) {
                                $display .= " [+$currentDeal{'other'}{$ID}{'enchant'}]";
                        }
                        if($currentDeal{'other'}{$ID}{'elementName'}) {
                                $display .= " [$currentDeal{'other'}{$ID}{'elementName'}]";
                        }
                        if($currentDeal{'other'}{$ID}{'slotName'}) {
                                $display .= " [$currentDeal{'other'}{$ID}{'slotName'}]";
                        }
                        $display .= " x $amount\n";
                        printC("I0W", "$display");
                } elsif ($amount > 0) {
                        $currentDeal{'other_zenny'} += $amount;
                        printC("I0W", "$currentDeal{'name'} 加入交易金钱$amount\n");
                }
                $msg_size = 19;

        } elsif ($switch eq "00EA" && $MsgLength >= 5) {
                $index = unpack("S1", substr($msg, 2, 2));
                undef $invIndex;
                if ($index > 0) {
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                        $currentDeal{'you'}{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}{'amount'} += $currentDeal{'lastItemAmount'};
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $currentDeal{'lastItemAmount'};
                        $display = "$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}";
                        if($chars[$config{'char'}]{'inventory'}[$invIndex]{'enchant'} > 0) {
                                $display .= " [+$chars[$config{'char'}]{'inventory'}[$invIndex]{'enchant'}]";
                        }
                        if($chars[$config{'char'}]{'inventory'}[$invIndex]{'elementName'}) {
                                $display .= " [$chars[$config{'char'}]{'inventory'}[$invIndex]{'elementName'}]";
                        }
                        if($chars[$config{'char'}]{'inventory'}[$invIndex]{'slotName'}) {
                                $display .= " [$chars[$config{'char'}]{'inventory'}[$invIndex]{'slotName'}]";
                        }
                        $display .= " x $currentDeal{'lastItemAmount'}\n";
                        printC("I0W", "加入交易物品: $display");
                        if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
                                undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
                        }
                } elsif ($currentDeal{'you_zenny'} > 0) {
                        $chars[$config{'char'}]{'zenny'} -= $currentDeal{'you_zenny'};
                }
                $msg_size = 5;

        } elsif ($switch eq "00EB" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "00EC" && $MsgLength >= 3) {
                $type = unpack("C1", substr($msg, 2, 1));
                if ($type == 1) {
                        $currentDeal{'other_finalize'} = 1;
                        printC("I0W", "$currentDeal{'name'} 确认交易\n");
                } else {
                        $currentDeal{'you_finalize'} = 1;
                        printC("I0W", "确认交易\n");
                }
                $msg_size = 3;

        } elsif ($switch eq "00ED" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "00EE" && $MsgLength >= 2) {
                undef %incomingDeal;
                undef %outgoingDeal;
                undef %currentDeal;
                printC("I0R", "交易取消\n");
                $msg_size = 2;

        } elsif ($switch eq "00EF" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "00F0" && $MsgLength >= 3) {
                printC("I0C", "交易道具成功\n");
                undef %currentDeal;
                $msg_size = 3;

        } elsif ($switch eq "00F1" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "00F2" && $MsgLength >= 6) {
                $storage{'items'} = unpack("S1", substr($msg, 2, 2));
                $storage{'items_max'} = unpack("S1", substr($msg, 4, 2));
                if ($storage{'items'} == $storage{'items_max'}) {
                        printC("S0Y", "仓库已经满，停止自动存仓\n");
                        chatLog("x", "仓库已经满，停止自动存仓\n");
                        $config{'storageAuto'} = 0;
                        if ($ai_seq[0] eq "storageAuto") {
                                sendStorageClose(\$remote_socket);
                        }
                }
                $msg_size = 6;

        } elsif ($switch eq "00F3" && $MsgLength >= 8) {
                $msg_size = 8;

        } elsif ($switch eq "00F4" && $MsgLength >= 21) {
                $index = unpack("S1", substr($msg, 2, 2));
                $amount = unpack("L1", substr($msg, 4, 4));
                $ID = unpack("S1", substr($msg, 8, 2));
                if (%{$storage{'inventory'}[$index]} || $itemSlots_lut{$ID} == 0) {
                        $storage{'inventory'}[$index]{'amount'} += $amount;
                } else {
                        $storage{'inventory'}[$index]{'nameID'} = $ID;
                        $storage{'inventory'}[$index]{'amount'} = $amount;
                        $storage{'inventory'}[$index]{'type_equip'} = $itemSlots_lut{$ID};
                        $storage{'inventory'}[$index]{'enchant'} = unpack("C1", substr($msg, 12, 2));
                        $storage{'inventory'}[$index]{'elementID'} = unpack("S1",substr($msg, 14, 2));
                        $storage{'inventory'}[$index]{'elementName'} = $elements_lut{$storage{'inventory'}[$index]{'elementID'}};
                        undef @cnt;
                        $count = 0;
                        for($j=1 ;$j < 5;$j++) {
                                if(unpack("S1", substr($msg, 11 + $j + $j, 2)) > 0) {
                                        $storage{'inventory'}[$index]{'slotID_$j'} = unpack("S1", substr($msg, 11 + $j + $j, 2));
                                        for($k = 0;$k < 4;$k++) {
                                                if(($storage{'inventory'}[$index]{'slotID_$j'} eq $cnt[$k]{'ID'}) && ($storage{'inventory'}[$index]{'slotID_$j'} ne "")) {
                                                        $cnt[$k]{'amount'} += 1;
                                                        last;
                                                } elsif ($storage{'inventory'}[$index]{'slotID_$j'} ne "") {
                                                        $cnt[$k]{'amount'} = 1;
                                                        $cnt[$k]{'name'} = $cards_lut{$storage{'inventory'}[$index]{'slotID_$j'}};
                                                        $cnt[$k]{'ID'} = $storage{'inventory'}[$index]{'slotID_$j'};
                                                        $count++;
                                                        last;
                                                }
                                        }
                                }
                        }
                        $display = "";
                        $count ++;
                        for($j = 0;$j < $count;$j++) {
                                if($j == 0 && $cnt[$j]{'amount'}) {
                                        if($cnt[$j]{'amount'} > 1) {
                                                $display .= "$cnt[$j]{'amount'}X$cnt[$j]{'name'}";
                                        } else {
                                                $display .= "$cnt[$j]{'name'}";
                                        }
                                } elsif ($cnt[$j]{'amount'}) {
                                        if($cnt[$j]{'amount'} > 1) {
                                                $display .= ",$cnt[$j]{'amount'}X$cnt[$j]{'name'}";
                                        } else {
                                                $display .= ",$cnt[$j]{'name'}";
                                        }
                                }
                        }
                        $storage{'inventory'}[$index]{'slotName'} = $display;
                        undef @cnt;
                        undef $count;
                }
                $display = ($items_lut{$ID} ne "")
                        ? $items_lut{$ID}
                        : "Unknown ".$ID;
                $storage{'inventory'}[$index]{'name'} = $display;
                if($storage{'inventory'}[$index]{'enchant'} > 0) {
                        $display .= " [+$storage{'inventory'}[$index]{'enchant'}]";
                }
                if($storage{'inventory'}[$index]{'elementName'}) {
                        $display .= " [$storage{'inventory'}[$index]{'elementName'}]";
                }
                if($storage{'inventory'}[$index]{'slotName'}) {
                        $display .= " [$storage{'inventory'}[$index]{'slotName'}]";
                }
                $display .= " x $amount\n";
                printC("I4", "增加: $display");
                chatLog("b", "存仓: $display");
                $msg_size = 21;

        } elsif ($switch eq "00F5" && $MsgLength >= 8) {
                $msg_size = 8;

        } elsif ($switch eq "00F6" && $MsgLength >= 8) {
                $index = unpack("S1", substr($msg, 2, 2));
                $amount = unpack("L1", substr($msg, 4, 4));
                $storage{'inventory'}[$index]{'amount'} -= $amount;
                $display = "$storage{'inventory'}[$index]{'name'}";
                if($storage{'inventory'}[$index]{'enchant'} > 0) {
                        $display .= " [+$storage{'inventory'}[$index]{'enchant'}]";
                }
                if($storage{'inventory'}[$index]{'elementName'}) {
                        $display .= " [$storage{'inventory'}[$index]{'elementName'}]";
                }
                if($storage{'inventory'}[$index]{'slotName'}) {
                        $display .= " [$storage{'inventory'}[$index]{'slotName'}]";
                }
                $display .= " x $amount\n";
                printC("I4", "减少: $display");
                chatLog("b", "取仓: $display");
                if ($storage{'inventory'}[$index]{'amount'} <= 0) {
                        undef %{$storage{'inventory'}[$index]};
                }
                $msg_size = 8;

        } elsif ($switch eq "00F7" && $MsgLength >= 2) {
                $msg_size = 2;

        # ICE Start - Storage Bugfix
        } elsif ($switch eq "00F8" && $MsgLength >= 2) {
                chatLogStorage();
                undef %storage;
                printC("I4", "关闭仓库\n");
                $msg_size = 2;
        # ICE End

        } elsif ($switch eq "00F9" && $MsgLength >= 26) {
                $msg_size = 26;

        } elsif ($switch eq "00FA" && $MsgLength >= 3) {
                $type = unpack("C1", substr($msg, 2, 1));
                if ($type == 1) {
                        printC("I0R", "这个组队名称已经有人使用\n");
                }
                $msg_size = 3;

        } elsif ($switch eq "00FB" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 28, length($msg)-28));
                $msg = substr($msg, 0, 28).$newmsg;
                ($chars[$config{'char'}]{'party'}{'name'}) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
                for ($i = 28; $i < $msg_size;$i+=46) {
                        $ID = substr($msg, $i, 4);
                        $num = unpack("C1",substr($msg, $i + 44, 1));
                        if (!%{$chars[$config{'char'}]{'party'}{'users'}{$ID}}) {
                                binAdd(\@partyUsersID, $ID);
                        }
                        ($chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'}) = substr($msg, $i + 4, 24) =~ /([\s\S]*?)\000/;
                        ($chars[$config{'char'}]{'party'}{'users'}{$ID}{'map'}) = substr($msg, $i + 28, 16) =~ /([\s\S]*?)\000/;
                        $chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = !(unpack("C1",substr($msg, $i + 45, 1)));
                        $chars[$config{'char'}]{'party'}{'users'}{$ID}{'admin'} = 1 if ($num == 0);
                }
                sendPartyShareEXP(\$remote_socket, 1) if ($config{'partyAutoShare'} && %{$chars[$config{'char'}]{'party'}});

        } elsif ($switch eq "00FC" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "00FD" && $MsgLength >= 27) {
                ($name) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
                $type = unpack("C1", substr($msg, 26, 1));
                if ($type == 0) {
                        printC("I0R", "$name 已经加入了其它组队\n");
                } elsif ($type == 1) {
                        printC("I0R", "$name 拒绝加入组队\n");
                } elsif ($type == 2) {
                        printC("I0C", "$name 成功加入组队\n");
                }
                $msg_size = 27;

        } elsif ($switch eq "00FE" && $MsgLength >= 30) {
                $ID = substr($msg, 2, 4);
                ($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
                printC("I0W", "'$name' 送来一封邀请加入组队的讯息。请问您同意加入组队吗？\n");
                $incomingParty{'ID'} = $ID;
                $timeout{'ai_partyAutoDeny'}{'time'} = time;
                $msg_size = 30;

        } elsif ($switch eq "00FF" && $MsgLength >= 10) {
                $msg_size = 10;

        } elsif ($switch eq "0100" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "0101" && $MsgLength >= 6) {
                $type = unpack("C1", substr($msg, 2, 1));
                if ($type == 0) {
                        printC("I0R", "经验值分配方式: 各自取得\n");
                } elsif ($type == 1) {
                        printC("I0C", "经验值分配方式: 均等分配\n");
                } else {
                        printC("I0R", "只有组队队长可以设定\n");
                }
                $msg_size = 6;

        } elsif ($switch eq "0102" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "0103" && $MsgLength >= 30) {
                $msg_size = 30;

        } elsif ($switch eq "0104" && $MsgLength >= 79) {
                $ID = substr($msg, 2, 4);
                $x = unpack("S1", substr($msg,10, 2));
                $y = unpack("S1", substr($msg,12, 2));
                $type = unpack("C1",substr($msg, 14, 1));
                ($name) = substr($msg, 15, 24) =~ /([\s\S]*?)\000/;
                ($partyUser) = substr($msg, 39, 24) =~ /([\s\S]*?)\000/;
                ($map) = substr($msg, 63, 16) =~ /([\s\S]*?)\000/;
                if (!%{$chars[$config{'char'}]{'party'}{'users'}{$ID}}) {
                        binAdd(\@partyUsersID, $ID);
                        if ($ID eq $accountID) {
                                printC("I0W", "成功加入组队 '$name'\n");
                        } else {
                                printC("I0W", "$partyUser 成功加入组队 '$name'\n");
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

                $msg_size = 79;

        } elsif ($switch eq "0105" && $MsgLength >= 31) {
                $ID = substr($msg, 2, 4);
                ($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
                undef %{$chars[$config{'char'}]{'party'}{'users'}{$ID}};
                binRemove(\@partyUsersID, $ID);
                if ($ID eq $accountID) {
                        printC("I0R", "已退出队伍\n");
                        undef %{$chars[$config{'char'}]{'party'}};
                        $chars[$config{'char'}]{'party'} = "";
                        undef @partyUsersID;
                } else {
                        printC("I0R", "$name 已退出队伍\n");
                }
                $msg_size = 31;

        } elsif ($switch eq "0106" && $MsgLength >= 10) {
                $ID = substr($msg, 2, 4);
                $chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp'} = unpack("S1", substr($msg, 6, 2));
                $chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp_max'} = unpack("S1", substr($msg, 8, 2));
                $msg_size = 10;

        } elsif ($switch eq "0107" && $MsgLength >= 10) {
                $ID = substr($msg, 2, 4);
                $x = unpack("S1", substr($msg,6, 2));
                $y = unpack("S1", substr($msg,8, 2));
                $chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'x'} = $x;
                $chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'y'} = $y;
                $chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 1;
                print "Party member location: $chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'} - $x, $y\n" if ($config{'debug'} >= 2);
                $msg_size = 10;

        } elsif ($switch eq "0108" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0109" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
                $msg = substr($msg, 0, 8).$newmsg;
                $chat = substr($msg, 8, $msg_size - 8);
                ($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
                chatLog("p", $chat."\n");
                $ai_cmdQue[$ai_cmdQue]{'type'} = "p";
                $ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser;
                $ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg;
                $ai_cmdQue[$ai_cmdQue]{'time'} = time;
                $ai_cmdQue++;
                printC("C3M", "$chat\n");
                sendWindowsMessage("0109".chr(1).$chatMsgUser.chr(1).$chatMsg) if ($yelloweasy);
                if ($chatMsg eq $config{'username'}) {
                        sendMessage(\$remote_socket, "p", "Ok!\n");
                        sleep(2);
                        killConnection(\$remote_socket);
                        sleep($config{'dcOnDualLogin'});
                }

        # wooooo MVP info
        } elsif ($switch eq "010A" && $MsgLength >= 4) {
                $ID = unpack("S1", substr($msg, 2, 2));
                printC("I0Y", "成为MVP啰!! MVP 道具是 : ".$items_lut{$ID}."\n");
                chatLog("m", "成为MVP啰!! MVP 道具是 : ".$items_lut{$ID}."\n");
                $msg_size = 4;

        } elsif ($switch eq "010B" && $MsgLength >= 6) {
                $val = unpack("S1",substr($msg, 2, 2));
                printC("I0Y", "成为MVP啰！！特别经验值 $val 取得！！\n");
                chatLog("m", "成为MVP啰！！特别经验值 $val 取得！！\n");
                $msg_size = 6;

        } elsif ($switch eq "010C" && $MsgLength >= 6) {
                $ID = substr($msg, 2, 4);
                $display = "Unknown";
                if (%{$players{$ID}}) {
                        $display = $players{$ID}{'name'};
                } elsif ($ID eq $accountID) {
                        $display = "你";
                }
                printC("I0Y", "$display 成为 MVP!\n");
                chatLog("m", "$display 成为 MVP!\n");
                $msg_size = 6;
        ###

        } elsif ($switch eq "010D" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "010E" && $MsgLength >= 11) {
                $ID = unpack("S1",substr($msg, 2, 2));
                $lv = unpack("S1",substr($msg, 4, 2));
                $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$ID})}}{'lv'} = $lv;
                print "Skill $skillsID_lut{$ID}: $lv\n" if $config{'debug'};
                $msg_size = 11;

        } elsif ($switch eq "010F" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                undef @skillsID;
                for($i = 4;$i < $msg_size;$i+=37) {
                        $ID = unpack("S1", substr($msg, $i, 2));
                        ($name) = substr($msg, $i + 12, 24) =~ /([\s\S]*?)\000/;
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

        } elsif ($switch eq "0110" && $MsgLength >= 10) {
                #Parse this: warp portal
                $msg_size = 10;

        } elsif ($switch eq "0111" && $MsgLength >= 39) {
                $msg_size = 39;

        } elsif ($switch eq "0113" && $MsgLength >= 10) {
                $msg_size = 10;

        } elsif ($switch eq "0114" && $MsgLength >= 31) {
                $skillID = unpack("S1",substr($msg, 2, 2));
                $sourceID = substr($msg, 4, 4);
                $targetID = substr($msg, 8, 4);
                $damage = unpack("S1",substr($msg, 24, 2));
                $level = unpack("S1",substr($msg, 26, 2));
                $level = 0 if ($level == 65535);
                if (%{$spells{$sourceID}}) {
                        $sourceID = $spells{$sourceID}{'sourceID'}
                }
                updateDamageTables($sourceID, $targetID, $damage) if ($damage != 35536);
                if ($sourceID eq $accountID) {
                        $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
                        undef $chars[$config{'char'}]{'time_cast'};
                }

                if (%{$monsters{$targetID}}) {
                        if ($sourceID eq $accountID) {
                                $monsters{$targetID}{'castOnByYou'}++;
                        } else {
                                $monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
                        }
                }
                if ($damage != 35536) {
                        if ($level_real ne "") {
                                     $level = $level_real;
                        }
                        attackC("s", $sourceID, $targetID, $damage, 0, 0, $skillID, $level);
                } else {
                        $level_real = $level;
                        attackC("u", $sourceID, $targetID, 0, 0, 0, $skillID, $level);
                }
                $msg_size = 31;

        } elsif ($switch eq "0115" && $MsgLength >= 35) {
                $msg_size = 35;

        } elsif ($switch eq "0116" && $MsgLength >= 10) {
                $msg_size = 10;

        } elsif ($switch eq "0117" && $MsgLength >= 18) {
                $skillID = unpack("S1",substr($msg, 2, 2));
                $sourceID = substr($msg, 4, 4);
                $lv = unpack("S1",substr($msg, 8, 2));
                $x = unpack("S1",substr($msg, 10, 2));
                $y = unpack("S1",substr($msg, 12, 2));

                undef $sourceDisplay;
                if ($sourceID eq $accountID) {
                        $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
                        undef $chars[$config{'char'}]{'time_cast'};
                }
                $targetID = "pos";
                attackC("u", $sourceID, $targetID, $x, $y, 0, $skillID, $lv);
                $msg_size = 18;

        } elsif ($switch eq "0118" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "0119" && $MsgLength >= 13) {
                $sourceID = substr($msg, 2, 4);
                $param1 = unpack("S1", substr($msg, 6, 2));
                $param2 = unpack("S1", substr($msg, 8, 2));
                $param3 = unpack("S1", substr($msg, 10, 2));
                undef $sourceDisplay;
                undef $targetDisplay;
                undef $state;
                if ($param1 == 0 && $param2 == 0) {
                        $targetDisplay = $msgstrings_lut{'0119'}{"00"};
                } else {
                        if ($param1 == 1) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"A1"};
                        } elsif ($param1 == 2) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"A2"};
                        } elsif ($param1 == 3) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"A3"};
                        } elsif ($param1 == 4) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"A4"};
                        } elsif ($param1 == 6) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"A6"};
                        } elsif ($param2 == 1) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"B1"};
                        } elsif ($param2 == 2) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"B2"};
                        } elsif ($param2 == 4) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"B4"};
                        } elsif ($param2 == 16) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"B16"};
                        } elsif ($param2 == 32) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"B32"};
                        } else {
                                $targetDisplay = "未知状态$param1$param2$param3";
                        }
                }
                if ($param3 == 1) {
#                        $targetDisplay = $msgstrings_lut{'0119'}{"C1"};
                } elsif ($param3 == 2) {
#                        $targetDisplay = $msgstrings_lut{'0119'}{"C2"};
                } elsif ($param3 == 4) {
#                        $targetDisplay = $msgstrings_lut{'0119'}{"C4"};
                } elsif ($param3 == 8) {
#                        $targetDisplay = "持有手推车Ⅰ";
                } elsif ($param3 == 16) {
#                        $targetDisplay = "装备好猎鹰";
                } elsif ($param3 == 32) {
#                        $targetDisplay = "骑上大嘴鸟";
                } elsif ($param3 == 64) {
#                        $targetDisplay = $msgstrings_lut{'0119'}{"C64"};
                } elsif ($param3 == 128) {
#                        $targetDisplay = "持有手推车Ⅱ";
                } elsif ($param3 == 256) {
#                        $targetDisplay = "持有手推车Ⅲ";
                } elsif ($param3 == 512) {
#                        $targetDisplay = "持有手推车Ⅳ";
                } elsif ($param3 == 1024) {
#                        $targetDisplay = "持有手推车Ⅴ";
                }
                $state = $targetDisplay;
                $targetDisply .= "($param1|$param2|$param3)" if ($config{'debug'});
                if (%{$monsters{$sourceID}}) {
                        $sourceDisplay = "$monsters{$sourceID}{'name'}($monsters{$sourceID}{'binID'}) ";
                        $monsters{$sourceID}{'state'} = $state;
                } elsif (%{$players{$sourceID}}) {
                        $sourceDisplay = "$players{$sourceID}{'name'}($players{$sourceID}{'binID'}) ";
                        $players{$sourceID}{'state'} = $state;
                } elsif ($sourceID eq $accountID) {
                        $sourceDisplay = "";
                        $chars[$config{'char'}]{'state_last'} = $chars[$config{'char'}]{'state'};
                        $chars[$config{'char'}]{'state'} = $state;
                } else {
                        $sourceDisplay = "未知 ";
                }
                if ($sourceID eq $accountID && ($state ne $msgstrings_lut{'0119'}{"00"} && $state ne $msgstrings_lut{'0119'}{"B32"})) {
                        printC("I6M", "$sourceDisplay变成$targetDisplay\n") if ($config{'Mode'});
                } elsif ($sourceID eq $accountID) {
                        printC("I6W", "$sourceDisplay变成$targetDisplay\n") if (($config{'Mode'} && ($chars[$config{'char'}]{'state_last'} ne $msgstrings_lut{'0119'}{"00"} && $chars[$config{'char'}]{'state_last'} ne $msgstrings_lut{'0119'}{"B32"})) || $config{'Mode'} >= 2);
                } else {
                        printC("I0", "$sourceDisplay变成$targetDisplay\n") if ($config{'Mode'} >= 2);
                        my $AID = unpack("L1", $sourceID);
                        if ($aid_rlut{$AID}{'avoid'}) {
                                binAdd(\@avoidID, $sourceID);
                        }
                }
                $msg_size = 13;

        } elsif ($switch eq "011A" && $MsgLength >= 15) {
                $skillID = unpack("S1",substr($msg, 2, 2));
                $targetID = substr($msg, 6, 4);
                $sourceID = substr($msg, 10, 4);
                $amount = unpack("S1",substr($msg, 4, 2));
                $amount = 0 if ($amount == 65535);
                if (%{$spells{$sourceID}}) {
                        $sourceID = $spells{$sourceID}{'sourceID'}
                }
                if ($sourceID eq $accountID) {
                        $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
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
                        attackC("h", $sourceID, $targetID, 0, 0, $amount, $skillID, 0);
                } else {
                        attackC("u", $sourceID, $targetID, 0, 0, 0, $skillID, $amount);
                }
                $msg_size = 15;

        } elsif ($switch eq "011B" && $MsgLength >= 20) {
                $msg_size = 20;

        } elsif ($switch eq "011C" && $MsgLength >= 68) {
                $skillID = unpack("S1",substr($msg, 2, 2));
                undef @{$warp{'responses'}};
                for ($i=4; $i < 68;$i+=16) {
                        ($resp_name) = substr($msg, $i, 16) =~ /([\s\S]*?)\000/;
                        push @{$warp{'responses'}}, $resp_name if $resp_name ne "";
                }
                $~ = "WARPLIST";
                print "----------$skillsID_lut{$skillID}-----------\n";
                print "#  responses\n";
                for ($i=0; $i < @{$warp{'responses'}};$i++) {
                        format WARPLIST =
@< @<<<<<<<<<<<<<<<<<<<<<<
$i $warp{'responses'}[$i]
.
                        write;
                        if ($chars[$config{'char'}]{'warpTo'} && $chars[$config{'char'}]{'warpTo'}.".gat" eq $warp{'responses'}[$i]) {
                                sendWarpto(\$remote_socket, $warp{'responses'}[$i]);
                        }
                }
                print "-------------------------------\n";
                printC("I7W", "输入 'warp' 选择地图\n");
                $msg_size = 68;

        } elsif ($switch eq "011D" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "011E" && $MsgLength >= 3) {
                $fail = unpack("C1", substr($msg, 2, 1));
                if ($fail) {
                        printC("I0R", "无法记忆空间移动场所\n");
                } else {
                        printC("I0C", "已记忆空间移动场所\n");
                }
                $msg_size = 3;

        } elsif ($switch eq "011F" && $MsgLength >= 16) {
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
                printC("I0", "出现: $spells{$ID}{'name'} ($spells{$ID}{'pos'}{'x'}, $spells{$ID}{'pos'}{'y'}) 距离: $spells{$ID}{'distance'}\n") if ($config{'debug'});
                $msg_size = 16;
                if (!$chars[$config{'char'}]{'warpTo'} && ($type == 129 || $type == 130) && $spells{$ID}{'distance'} == 0 && $config{'teleportAuto_portalPlayer'}) {
                        if ($config{'teleportAuto_portalPlayer'} == 1 && !$indoor_lut{$field{'name'}.'.rsw'}) {
                                printC("A5R", "瞬移躲避恶意传送: $players{$sourceID}{'name'} $field{'name'} ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})\n") if ($config{'Mode'});
                                chatLog("x", "瞬移躲避恶意传送: $players{$sourceID}{'name'} $field{'name'} ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})\n");
                                useTeleport(1);
                        } elsif ($config{'teleportAuto_portalPlayer'} == 2 || $indoor_lut{$field{'name'}.'.rsw'}) {
                                aiRemove("move");
                                aiRemove("route");
                                aiRemove("route_getRoute");
                                aiRemove("route_getMapRoute");
                                printC("A5R", "移动躲避恶意传送 $players{$sourceID}{'name'} $field{'name'} ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})\n") if ($config{'Mode'});
                                chatLog("x", "移动躲避恶意传送: $players{$sourceID}{'name'} $field{'name'} ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})\n");
                                $ai_v{'temp'}{'pos'}{'x'} = $spells{$ID}{'pos'}{'x'};
                                $ai_v{'temp'}{'pos'}{'y'} = $spells{$ID}{'pos'}{'y'};
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

        } elsif ($switch eq "0120" && $MsgLength >= 6) {
                #The area effect spell with ID dissappears
                $ID = substr($msg, 2, 4);
                $spells{$ID}{'distance'} = int(distance(\%{$chars[$config{'char'}]{'pos_to'}},\%{$spells{$ID}{'pos'}}));
                printC("I0", "消失: $spells{$ID}{'name'} ($spells{$ID}{'pos'}{'x'}, $spells{$ID}{'pos'}{'y'}) 距离: $spells{$ID}{'distance'}\n") if ($config{'debug'});
                undef %{$spells{$ID}};
                binRemove(\@spellsID, $ID);
                $msg_size = 6;

#Cart Parses - chobit andy 20030102
        } elsif ($switch eq "0121" && $MsgLength >= 14) {
                $cart{'items'} = unpack("S1", substr($msg, 2, 2));
                $cart{'items_max'} = unpack("S1", substr($msg, 4, 2));
                $cart{'weight'} = int(unpack("L1", substr($msg, 6, 4)) / 10);
                $cart{'weight_max'} = int(unpack("L1", substr($msg, 10, 4)) / 10);
                $msg_size = 14;

        } elsif ($switch eq "0122" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                for($i = 4; $i < $msg_size; $i+=20) {
                        $index = unpack("S1", substr($msg, $i, 2));
                        $ID = unpack("S1", substr($msg, $i+2, 2));
                        $type = unpack("C1",substr($msg, $i+4, 1));
                        if (%{$cart{'inventory'}[$index]}) {
                                $cart{'inventory'}[$index]{'amount'} += 1;
                        } else {
                                $cart{'inventory'}[$index]{'nameID'} = $ID;
                                $cart{'inventory'}[$index]{'amount'} = 1;
                                $display = ($items_lut{$ID} ne "")
                                        ? $items_lut{$ID}
                                        : "Unknown ".$ID;
                                $cart{'inventory'}[$index]{'name'} = $display;
                                $cart{'inventory'}[$index]{'type_equip'} = $itemSlots_lut{$ID};
                                $cart{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, $i+5, 1));
                                undef @cnt;
                                $count = 0;
                                for($j=1 ;$j < 5;$j++) {
                                        if(unpack("S1", substr($msg, $i + 10 + $j + $j, 2)) > 0) {
                                                $cart{'inventory'}[$index]{'slotID_$j'} = unpack("S1", substr($msg, $i + 10 + $j + $j, 2));
                                                for($k = 0;$k < 4;$k++) {
                                                        if(($cart{'inventory'}[$index]{'slotID_$j'} eq $cnt[$k]{'ID'}) && ($cart{'inventory'}[$index]{'slotID_$j'} ne "")) {
                                                                $cnt[$k]{'amount'} += 1;
                                                                last;
                                                        } elsif ($cart{'inventory'}[$index]{'slotID_$j'} ne "") {
                                                                $cnt[$k]{'amount'} = 1;
                                                                $cnt[$k]{'name'} = $cards_lut{$cart{'inventory'}[$index]{'slotID_$j'}};
                                                                $cnt[$k]{'ID'} = $cart{'inventory'}[$index]{'slotID_$j'};
                                                                $count++;
                                                                last;
                                                        }
                                                }
                                        }
                                }
                                $display = "";
                                $count ++;
                                for($j = 0;$j < $count;$j++) {
                                        if($j == 0 && $cnt[$j]{'amount'}) {
                                                if($cnt[$j]{'amount'} > 1) {
                                                        $display .= "$cnt[$j]{'amount'}X$cnt[$j]{'name'}";
                                                } else {
                                                        $display .= "$cnt[$j]{'name'}";
                                                }
                                        } elsif ($cnt[$j]{'amount'}) {
                                                if($cnt[$j]{'amount'} > 1) {
                                                        $display .= ",$cnt[$j]{'amount'}X$cnt[$j]{'name'}";
                                                } else {
                                                        $display .= ",$cnt[$j]{'name'}";
                                                }
                                        }
                                }
                                $cart{'inventory'}[$index]{'slotName'} = $display;
                                undef @cnt;
                                undef $count;
                                $cart{'inventory'}[$index]{'enchant'} = unpack("C1", substr($msg, $i + 11, 2));
                                undef @cnt;
                                $count = 0;
                                for($j=1 ;$j < 5;$j++) {
                                        if(unpack("S1", substr($msg, $i + 10 + $j + $j, 2)) > 0) {
                                                $cart{'inventory'}[$index]{'slotID_$j'} = unpack("S1", substr($msg, $i + 10 + $j + $j, 2));
                                                for($k = 0;$k < 4;$k++) {
                                                        if(($cart{'inventory'}[$index]{'slotID_$j'} eq $cnt[$k]{'ID'}) && ($cart{'inventory'}[$index]{'slotID_$j'} ne "")) {
                                                                $cnt[$k]{'amount'} += 1;
                                                                last;
                                                        } elsif ($cart{'inventory'}[$index]{'slotID_$j'} ne "") {
                                                                $cnt[$k]{'amount'} = 1;
                                                                $cnt[$k]{'name'} = $cards_lut{$cart{'inventory'}[$index]{'slotID_$j'}};
                                                                $cnt[$k]{'ID'} = $cart{'inventory'}[$index]{'slotID_$j'};
                                                                $count++;
                                                                last;
                                                        }
                                                }
                                        }
                                }
                                $display = "";
                                $count ++;
                                for($j = 0;$j < $count;$j++) {
                                        if($j == 0 && $cnt[$j]{'amount'}) {
                                                if($cnt[$j]{'amount'} > 1) {
                                                        $display .= "$cnt[$j]{'amount'}X$cnt[$j]{'name'}";
                                                } else {
                                                        $display .= "$cnt[$j]{'name'}";
                                                }
                                        } elsif ($cnt[$j]{'amount'}) {
                                                if($cnt[$j]{'amount'} > 1) {
                                                        $display .= ",$cnt[$j]{'amount'}X$cnt[$j]{'name'}";
                                                } else {
                                                        $display .= ",$cnt[$j]{'name'}";
                                                }
                                        }
                                }
                                $cart{'inventory'}[$index]{'slotName'} = $display;
                                undef @cnt;
                                undef $count;
                                $cart{'inventory'}[$index]{'enchant'} = unpack("C1", substr($msg, $i + 11, 2));
                                $cart{'inventory'}[$index]{'elementID'} = unpack("S1",substr($msg, $i + 13, 2));
                                $cart{'inventory'}[$index]{'elementName'} = $elements_lut{$cart{'inventory'}[$index]{'elementID'}};
                        }
                        print "Cart Item: $cart{'inventory'}[$index]{'name'} [$cart{'inventory'}[$index]{'enchant'}|$cart{'inventory'}[$index]{'slotName'}|$cart{'inventory'}[$index]{'elementName'}]($index) x $cart{'inventory'}[$index]{'amount'}\n" if $config{'debug'};
                }

        } elsif ($switch eq "0123" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                for($i = 4; $i < $msg_size; $i+=10) {
                        $index = unpack("S1", substr($msg, $i, 2));
                        $ID = unpack("S1", substr($msg, $i+2, 2));
                        $amount = unpack("S1", substr($msg, $i+6, 2));
                        if (%{$cart{'inventory'}[$index]}) {
                                $cart{'inventory'}[$index]{'amount'} += $amount;
                        } else {
                                $cart{'inventory'}[$index]{'nameID'} = $ID;
                                $cart{'inventory'}[$index]{'amount'} = $amount;
                                $cart{'inventory'}[$index]{'type_equip'} = $itemSlots_lut{$ID};
                                $display = ($items_lut{$ID} ne "")
                                        ? $items_lut{$ID}
                                        : "Unknown ".$ID;
                                $cart{'inventory'}[$index]{'name'} = $display;
                        }
                        print "Cart Item: $cart{'inventory'}[$index]{'name'}($index) x $cart{'inventory'}[$index]{'amount'} - $itemTypes_lut{$cart{'inventory'}[$index]{'type'}}\n" if $config{'debug'};
                }

        } elsif ($switch eq "0124" && $MsgLength >= 21) {
                $index = unpack("S1", substr($msg, 2, 2));
                $amount = unpack("L1", substr($msg, 4, 4));
                $ID = unpack("S1", substr($msg, 8, 2));
                if (%{$cart{'inventory'}[$index]}) {
                        $cart{'inventory'}[$index]{'amount'} += $amount;
                } else {
                        $cart{'inventory'}[$index]{'nameID'} = $ID;
                        $cart{'inventory'}[$index]{'amount'} = $amount;
                        $cart{'inventory'}[$index]{'type_equip'} = $itemSlots_lut{$ID};
                        $cart{'inventory'}[$index]{'enchant'} = unpack("C1", substr($msg, 12, 2));
                        $cart{'inventory'}[$index]{'elementID'} = unpack("S1",substr($msg, 14, 2));
                        $cart{'inventory'}[$index]{'elementName'} = $elements_lut{$cart{'inventory'}[$index]{'elementID'}};
                        undef @cnt;
                        $count = 0;
                        for($j=1 ;$j < 5;$j++) {
                                if(unpack("S1", substr($msg, 11 + $j + $j, 2)) > 0) {
                                        $cart{'inventory'}[$index]{'slotID_$j'} = unpack("S1", substr($msg, 11 + $j + $j, 2));
                                        for($k = 0;$k < 4;$k++) {
                                                if(($cart{'inventory'}[$index]{'slotID_$j'} eq $cnt[$k]{'ID'}) && ($cart{'inventory'}[$index]{'slotID_$j'} ne "")) {
                                                        $cnt[$k]{'amount'} += 1;
                                                        last;
                                                } elsif ($cart{'inventory'}[$index]{'slotID_$j'} ne "") {
                                                        $cnt[$k]{'amount'} = 1;
                                                        $cnt[$k]{'name'} = $cards_lut{$cart{'inventory'}[$index]{'slotID_$j'}};
                                                        $cnt[$k]{'ID'} = $cart{'inventory'}[$index]{'slotID_$j'};
                                                        $count++;
                                                        last;
                                                }
                                        }
                                }
                        }
                        $display = "";
                        $count ++;
                        for($j = 0;$j < $count;$j++) {
                                if($j == 0 && $cnt[$j]{'amount'}) {
                                        if($cnt[$j]{'amount'} > 1) {
                                                $display .= "$cnt[$j]{'amount'}X$cnt[$j]{'name'}";
                                        } else {
                                                $display .= "$cnt[$j]{'name'}";
                                        }
                                } elsif ($cnt[$j]{'amount'}) {
                                        if($cnt[$j]{'amount'} > 1) {
                                                $display .= ",$cnt[$j]{'amount'}X$cnt[$j]{'name'}";
                                        } else {
                                                $display .= ",$cnt[$j]{'name'}";
                                        }
                                }
                        }
                        $cart{'inventory'}[$index]{'slotName'} = $display;
                        undef @cnt;
                        undef $count;
                }
                $display = ($items_lut{$ID} ne "")
                        ? $items_lut{$ID}
                        : "Unknown ".$ID;
                $cart{'inventory'}[$index]{'name'} = $display;
                $display = "$cart{'inventory'}[$index]{'name'}";
                if($cart{'inventory'}[$index]{'enchant'} > 0) {
                        $display .= " [+$cart{'inventory'}[$index]{'enchant'}]";
                }
                if($cart{'inventory'}[$index]{'elementName'}) {
                        $display .= " [$cart{'inventory'}[$index]{'elementName'}]";
                }
                if($cart{'inventory'}[$index]{'slotName'}) {
                        $display .= " [$cart{'inventory'}[$index]{'slotName'}]";
                }
                $display .= " x $amount\n";
                printC("I5", "增加: $display");
                $msg_size = 21;

        } elsif ($switch eq "0125" && $MsgLength >= 8) {
                $index = unpack("S1", substr($msg, 2, 2));
                $amount = unpack("L1", substr($msg, 4, 4));
                $cart{'inventory'}[$index]{'amount'} -= $amount;
                $display = "$cart{'inventory'}[$index]{'name'}";
                if($cart{'inventory'}[$index]{'enchant'} > 0) {
                        $display .= " [+$cart{'inventory'}[$index]{'enchant'}]";
                }
                if($cart{'inventory'}[$index]{'elementName'}) {
                        $display .= " [$cart{'inventory'}[$index]{'elementName'}]";
                }
                if($cart{'inventory'}[$index]{'slotName'}) {
                        $display .= " [$cart{'inventory'}[$index]{'slotName'}]";
                }
                $display .= " x $amount\n";
                printC("I5", "减少: $display");
                if ($cart{'inventory'}[$index]{'amount'} <= 0) {
                        undef %{$cart{'inventory'}[$index]};
                }
                $msg_size = 8;

        } elsif ($switch eq "0126" && $MsgLength >= 8) {
                $msg_size = 8;

        } elsif ($switch eq "0127" && $MsgLength >= 8) {
                $msg_size = 8;

        } elsif ($switch eq "0128" && $MsgLength >= 8) {
                $msg_size = 8;

        } elsif ($switch eq "0129" && $MsgLength >= 8) {
                $msg_size = 8;

        } elsif ($switch eq "012A" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "012B" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "012C" && $MsgLength >= 3) {
                printC("I5R", "无法把物品加入手推车\n");
                $msg_size = 3;

        # ICE Start - Auto Shop
        } elsif ($switch eq "012D" && $MsgLength >= 4) {
                $number = unpack("S1",substr($msg, 2, 2));
                printC("I0", "可以出售物品的数量 $number\n");
                $msg_size = 4;

        } elsif ($switch eq "012E" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "012F" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0130" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "0131" && $MsgLength >= 86) {
                $ID = substr($msg,2,4);
                if (!%{$venderLists{$ID}}) {
                        binAdd(\@venderListsID, $ID);
                }
                ($venderLists{$ID}{'title'}) = substr($msg,6,36) =~ /(.*?)\000/;
                $venderLists{$ID}{'id'} = $ID;
                $msg_size = 86;

        } elsif ($switch eq "0132" && $MsgLength >= 6) {
                $ID = substr($msg,2,4);
                binRemove(\@venderListsID, $ID);
                undef %{$venderLists{$ID}};
                $msg_size = 6;

        } elsif ($switch eq "0133" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                undef @venderItemList;
                undef $venderID;
                $venderID = substr($msg,4,4);
                $venderItemList = 0;
                $~ = "VSTORELIST";
                print "----------Vender Store List-----------\n";
                print "#  Name                        Type           Amount Price\n";
                for ($i = 8; $i < $msg_size; $i+=22) {
                        $price = unpack("L1", substr($msg, $i, 4));
                        $amount = unpack("S1", substr($msg, $i + 4, 2));
                        $number = unpack("S1", substr($msg, $i + 6, 2));
                        $type = unpack("C1", substr($msg, $i + 8, 1));
                        $ID = unpack("S1", substr($msg, $i + 9, 2));
                        $identified = unpack("C1", substr($msg, $i + 11, 1));
                        $custom = unpack("C1", substr($msg, $i + 13, 1));
                        $card1 = unpack("S1", substr($msg, $i + 14, 2));
                        $card2 = unpack("S1", substr($msg, $i + 16, 2));
                        $card3 = unpack("S1", substr($msg, $i + 18, 2));
                        $card4 = unpack("S1", substr($msg, $i + 20, 2));

                        $venderItemList[$number]{'nameID'} = $ID;
                        $display = ($items_lut{$ID} ne "")
                                ? $items_lut{$ID}
                                : "Unknown ".$ID;
                        if ($custom) {
                                $display = "+$custom " . $display;
                        }
                        $venderItemList[$number]{'name'} = $display;
                        $venderItemList[$number]{'amount'} = $amount;
                        $venderItemList[$number]{'type'} = $type;
                        $venderItemList[$number]{'identified'} = $identified;
                        $venderItemList[$number]{'custom'} = $custom;
                        $venderItemList[$number]{'card1'} = $card1;
                        $venderItemList[$number]{'card2'} = $card2;
                        $venderItemList[$number]{'card3'} = $card3;
                        $venderItemList[$number]{'card4'} = $card4;
                        $venderItemList[$number]{'price'} = $price;
                        $venderItemList++;
                        print "Item added to Vender Store: $items{$ID}{'name'} - $price z\n" if ($config{'debug'} >= 2);
                        format VSTORELIST =
@< @<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<< @>>>>> @>>>>>>>z
$number $venderItemList[$number]{'name'} $itemTypes_lut{$venderItemList[$number]{'type'}} $venderItemList[$number]{'amount'} $venderItemList[$number]{'price'}
.
                        write;
                }
                print "--------------------------------------\n";

        } elsif ($switch eq "0134" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0135" && $MsgLength >= 7) {
                $msg_size = 7;

        } elsif ($switch eq "0136" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                #started a shop.
                undef @articles;
                $articles = 0;
                $~ = "ARTICLESLIST";
                print "----------Items added to shop ------------------\n";
                print "#  Name                        Type          Quantity     Price\n";
                for ($i = 8; $i < $msg_size; $i+=22) {
                        $price = unpack("L1", substr($msg, $i, 4));
                        $number = unpack("S1", substr($msg, $i + 4, 2));
                        $amount = unpack("S1", substr($msg, $i + 6, 2));
                        $type = unpack("C1", substr($msg, $i + 8, 1));
                        $ID = unpack("S1", substr($msg, $i + 9, 2));
                        $identified = unpack("C1", substr($msg, $i + 11, 1));
                        $custom = unpack("C1", substr($msg, $i + 13, 1));
                        $card1 = unpack("S1", substr($msg, $i + 14, 2));
                        $card2 = unpack("S1", substr($msg, $i + 16, 2));
                        $card3 = unpack("S1", substr($msg, $i + 18, 2));
                        $card4 = unpack("S1", substr($msg, $i + 20, 2));
                        $articles[$number]{'nameID'} = $ID;
                        $display = ($items_lut{$ID} ne "")
                                ? $items_lut{$ID}
                                : "Unknown ".$ID;
                        if ($custom) {
                                $display = "+$custom " . $display;
                        }
                        $articles[$number]{'name'} = $display;
                        $articles[$number]{'quantity'} = $amount;
                        $articles[$number]{'type'} = $type;
                        $articles[$number]{'identified'} = $identified;
                        $articles[$number]{'custom'} = $custom;
                        $articles[$number]{'card1'} = $card1;
                        $articles[$number]{'card2'} = $card2;
                        $articles[$number]{'card3'} = $card3;
                        $articles[$number]{'card4'} = $card4;
                        $articles[$number]{'price'} = $price;
                        undef $articles[$number]{'sold'};
                        $articles++;
                        print "Item added to Vender Store: $items{$ID}{'name'} - $price z\n" if ($config{'debug'} >= 2);
                        format ARTICLESLIST =
@< @<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<< @>>>>> @>>>>>>>z
$number $articles[$number]{'name'} $itemTypes_lut{$articles[$number]{'type'}} $articles[$number]{'quantity'} $articles[$number]{'price'}
.
                        write;
                }
                print "-----------------------------------------\n";
                undef $shop{'earned'};

        } elsif ($switch eq "0137" && $MsgLength >= 6) {
                #sold something.
                $number = unpack("S1",substr($msg, 2, 2));
                $amount = unpack("S1",substr($msg, 4, 2));
                my $earned = 0;
                $articles[$number]{'sold'} += $amount;
                $earned = $amount * $articles[$number]{'price'};
                $shop{'earned'} += $earned;
                $articles[$number]{'quantity'} -= $amount;
                printC("I5W", "出售: $articles[$number]{'name'} x $amount  价格: $articles[$number]{'price'} z  获得: $earned z.\n");
                chatLog("b", "出售: $articles[$number]{'name'} x $amount  价格: $articles[$number]{'price'} z  获得: $earned z.\n");
                if ($articles[$number]{'quantity'} < 1) {
                        printC("I5W", "全部售出: $articles[$number]{'name'}.\n");
                        sendCloseShop(\$remote_socket);
                }
                $msg_size = 6;
        # -End-

        } elsif ($switch eq "0138" && $MsgLength >= 3) {
                $msg_size = 3;

        } elsif ($switch eq "0139" && $MsgLength >= 16) {
                $ID = substr($msg, 2, 4);
                $type = unpack("C1",substr($msg, 14, 1));
                $coords1{'x'} = unpack("S1",substr($msg, 6, 2));
                $coords1{'y'} = unpack("S1",substr($msg, 8, 2));
                $coords2{'x'} = unpack("S1",substr($msg, 10, 2));
                $coords2{'y'} = unpack("S1",substr($msg, 12, 2));
                %{$monsters{$ID}{'pos_attack_info'}} = %coords1;
                %{$chars[$config{'char'}]{'pos'}} = %coords2;
                %{$chars[$config{'char'}]{'pos_to'}} = %coords2;
                print "Recieved attack location - $monsters{$ID}{'pos_attack_info'}{'x'}, $monsters{$ID}{'pos_attack_info'}{'y'} - ".getHex($ID)."\n" if ($config{'debug'} >= 2);
                $msg_size = 16;

        } elsif ($switch eq "013A" && $MsgLength >= 4) {
                $type = unpack("S1",substr($msg, 2, 2));
                $msg_size = 4;

        } elsif ($switch eq "013B" && $MsgLength >= 4) {
                $type = unpack("S1",substr($msg, 2, 2));
                if ($type == 0) {
                        printC("I0R", "请先装备弓箭\n");
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "type", 10);
                        ai_sendEquip($invIndex,"") if $invIndex ne "";
                } elsif ($type == 3) {
                        printC("I0G", "已装备弓箭\n") if $config{'debug'};
                }
                $msg_size = 4;

        } elsif ($switch eq "013C" && $MsgLength >= 4) {
                $index = unpack("S1", substr($msg, 2, 2));
                undef $invIndex;
                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                if ($invIndex ne "") {
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = 1;
                        printC("I0G", "装备箭失: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}\n") if ($config{'Mode'} >= 2);
                } elsif ($index ne "") {
                        $EAIndex = $index;
                }
                $msg_size = 4;

        } elsif ($switch eq "013D" && $MsgLength >= 6) {
                $type = unpack("S1",substr($msg, 2, 2));
                $amount = unpack("S1",substr($msg, 4, 2));
                if ($type == 5) {
                        $chars[$config{'char'}]{'hp'} += $amount;
                        $chars[$config{'char'}]{'hp'} = $chars[$config{'char'}]{'hp_max'} if ($chars[$config{'char'}]{'hp'} > $chars[$config{'char'}]{'hp_max'});
                } elsif ($type == 7) {
                        $chars[$config{'char'}]{'sp'} += $amount;
                        $chars[$config{'char'}]{'sp'} = $chars[$config{'char'}]{'sp_max'} if ($chars[$config{'char'}]{'sp'} > $chars[$config{'char'}]{'sp_max'});
                }
                $msg_size = 6;

        } elsif ($switch eq "013E" && $MsgLength >= 24) {
                $sourceID = substr($msg, 2, 4);
                $targetID = substr($msg, 6, 4);
                $x = unpack("S1",substr($msg, 10, 2));
                $y = unpack("S1",substr($msg, 12, 2));
                $skillID = unpack("S1",substr($msg, 14, 2));
                undef $sourceDisplay;
                undef $targetDisplay;
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
                attackC("c", $sourceID, $targetID, $x, $y, 0, $skillID, 0);
                $msg_size = 24;

        } elsif ($switch eq "013F" && $MsgLength >= 26) {
                $msg_size = 26;

        } elsif ($switch eq "0140" && $MsgLength >= 22) {
                $msg_size = 22;

        } elsif ($switch eq "0141" && $MsgLength >= 14) {
                $type = unpack("S1",substr($msg, 2, 2));
                $val = unpack("S1",substr($msg, 6, 2));
                $val2 = unpack("S1",substr($msg, 10, 2));
                if ($type == 13) {
                        $chars[$config{'char'}]{'str'} = $val;
                        $chars[$config{'char'}]{'str_bonus'} = $val2;
                        print "Strength: $val + $val2\n" if $config{'debug'};
                } elsif ($type == 14) {
                        $chars[$config{'char'}]{'agi'} = $val;
                        $chars[$config{'char'}]{'agi_bonus'} = $val2;
                        print "Agility: $val + $val2\n" if $config{'debug'};
                } elsif ($type == 15) {
                        $chars[$config{'char'}]{'vit'} = $val;
                        $chars[$config{'char'}]{'vit_bonus'} = $val2;
                        print "Vitality: $val + $val2\n" if $config{'debug'};
                } elsif ($type == 16) {
                        $chars[$config{'char'}]{'int'} = $val;
                        $chars[$config{'char'}]{'int_bonus'} = $val2;
                        print "Intelligence: $val + $val2\n" if $config{'debug'};
                } elsif ($type == 17) {
                        $chars[$config{'char'}]{'dex'} = $val;
                        $chars[$config{'char'}]{'dex_bonus'} = $val2;
                        print "Dexterity: $val + $val2\n" if $config{'debug'};
                } elsif ($type == 18) {
                        $chars[$config{'char'}]{'luk'} = $val;
                        $chars[$config{'char'}]{'luk_bonus'} = $val2;
                        print "Luck: $val + $val2\n" if $config{'debug'};
                }
                $msg_size = 14;

        } elsif ($switch eq "0142" && $MsgLength >= 6) {
                $ID = substr($msg, 2, 4);
                printc("I7W", "$npcs{$ID}{'name'} : 输入 'talk amount <数量>' 继续跟NPC对话。\n");
                $msg_size = 6;

        } elsif ($switch eq "0143" && $MsgLength >= 10) {
                $msg_size = 10;

        } elsif ($switch eq "0144" && $MsgLength >= 23) {
                $msg_size = 23;

        } elsif ($switch eq "0145" && $MsgLength >= 19) {
                $msg_size = 19;

        } elsif ($switch eq "0146" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "0147" && $MsgLength >= 39) {
                $skillID = unpack("S*",substr($msg, 2, 2));
                $skillLv = unpack("S*",substr($msg, 8, 2));
                print "You get temporary skill $skillsID_lut{$skillID}, lv $skillLv\n" if $config{'debug'};
                if ($skillID == 54 && $resurrectID ne "") {
                        sendSkillUse(\$remote_socket, $skillID, $skillLv, $resurrectID);
                        undef $resurrectID;
                } elsif ($skillID == 26) {
                        sleep(1) if ($ai_seq[0] ne "" && $skillLv == 2);
                        sendSkillUse(\$remote_socket, $skillID, $skillLv, $accountID);
                }
                $msg_size = 39;

        } elsif ($switch eq "0148" && $MsgLength >= 8) {
                $ID = substr($msg, 2, 4);
                if ($ID eq $accountID) {
                        printC("I0Y", "你 已经复活了\n");
                        undef $chars[$config{'char'}]{'dead'};
                        undef $chars[$config{'char'}]{'dead_time'};
                        undef @ai_seq;
                        undef @ai_seq_args;
                } else {
                        undef $players{$ID}{'dead'};
                        printC("I0", "$players{$ID}{'name'}($players{$ID}{'binID'}) 已经复活了\n") if ($config{'Mode'} >= 2 || $config{'debug'});
                }
                $msg_size = 8;

        } elsif ($switch eq "0149" && $MsgLength >= 9) {
                $msg_size = 9;

        } elsif ($switch eq "014A" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "014B" && $MsgLength >= 27) {
                $msg_size = 27;

        } elsif ($switch eq "014C" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "014D" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "014E" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "014F" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "0150" && $MsgLength >= 110) {
                $msg_size = 110;

        } elsif ($switch eq "0151" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "0152" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0153" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0154" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0155" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0156" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0157" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "0158" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0159" && $MsgLength >= 54) {
                $msg_size = 54;

        } elsif ($switch eq "015A" && $MsgLength >= 66) {
                $msg_size = 66;

        } elsif ($switch eq "015B" && $MsgLength >= 54) {
                $msg_size = 54;

        } elsif ($switch eq "015C" && $MsgLength >= 90) {
                $msg_size = 90;

        } elsif ($switch eq "015D" && $MsgLength >= 42) {
                $msg_size = 42;

        } elsif ($switch eq "015E" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "015F" && $MsgLength >= 42) {
                $msg_size = 42;

        } elsif ($switch eq "0160" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0161" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0162" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0163" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0164" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0165" && $MsgLength >= 30) {
                $msg_size = 30;

        } elsif ($switch eq "0166" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0167" && $MsgLength >= 3) {
                $msg_size = 3;

        } elsif ($switch eq "0168" && $MsgLength >= 14) {
                $msg_size = 14;

        } elsif ($switch eq "0169" && $MsgLength >= 3) {
                $msg_size = 3;

        } elsif ($switch eq "016A" && $MsgLength >= 30) {
                $guildID = substr($msg, 2, 4);
                ($guildName) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
                $msg_size = 30;

        } elsif ($switch eq "016B" && $MsgLength >= 10) {
                $msg_size = 10;

        } elsif ($switch eq "016C" && $MsgLength >= 43) {
                ($chars[$config{'char'}]{'guild'}{'name'}) = substr($msg, 19, 24) =~ /([\s\S]*?)\000/;
                $msg_size = 43;

        } elsif ($switch eq "016D" && $MsgLength >= 14) {
                $msg_size = 14;

        } elsif ($switch eq "016E" && $MsgLength >= 186) {
                $msg_size = 186;

        } elsif ($switch eq "016F" && $MsgLength >= 182) {
                ($address) = substr($msg, 2, 60) =~ /([\s\S]*?)\000/;
                ($message) = substr($msg, 62, 120) =~ /([\s\S]*?)\000/;
                if ($config{'Mode'} >= 2 || ($config{'Mode'} && $message ne $message_old)) {
                        print    "---- 工会信息 ----\n"
                                ,"$address\n\n"
                                ,"$message\n"
                                ,"------------------\n";
                }
                $message_old = $message;
                $msg_size = 182;

        } elsif ($switch eq "0170" && $MsgLength >= 14) {
                $msg_size = 14;

        } elsif ($switch eq "0171" && $MsgLength >= 30) {
                $msg_size = 30;

        } elsif ($switch eq "0172" && $MsgLength >= 10) {
                $msg_size = 10;

        } elsif ($switch eq "0173" && $MsgLength >= 3) {
                $msg_size = 3;

        } elsif ($switch eq "0174" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                #$givenPercent = unpack("L1", substr($msg, 16, 4));
                #$PositionDesc = substr($msg, 20, 24);
                $msg_size = $dMsgLength;

        } elsif ($switch eq "0175" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "0176" && $MsgLength >= 106) {
                $msg_size = 106;

        } elsif ($switch eq "0177" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                undef @identifyID;
                undef $invIndex;
                for ($i = 4; $i < $msg_size; $i += 2) {
                        $index = unpack("S1", substr($msg, $i, 2));
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                        binAdd(\@identifyID, $invIndex);
                }
                printC("I0", "接收可鉴定物品列表 - 输入 'identify'\n");

        } elsif ($switch eq "0178" && $MsgLength >= 4) {
                $msg_size = 4;

        } elsif ($switch eq "0179" && $MsgLength >= 5) {
                $index = unpack("S*",substr($msg, 2, 2));
                undef $invIndex;
                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                $chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = 1;
                $chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} = $itemSlots_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}};
                printC("I3", "鉴定: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}\n");
                undef @identifyID;
                $msg_size = 5;

        } elsif ($switch eq "017A" && $MsgLength >= 4) {
                $msg_size = 4;

        } elsif ($switch eq "017B" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "017C" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "017D" && $MsgLength >= 7) {
                $msg_size = 7;

        } elsif ($switch eq "017E" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "017F" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                $ID = substr($msg, 4, 4);
                $chat = substr($msg, 4, $msg_size - 4);
                ($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
                $ai_cmdQue[$ai_cmdQue]{'type'} = "g";
                $ai_cmdQue[$ai_cmdQue]{'ID'} = $ID;
                $ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser;
                $ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg;
                $ai_cmdQue[$ai_cmdQue]{'time'} = time;
                $ai_cmdQue++;
                printC("C4G", "$chat\n");
                if ($config{'mvpMode'}) {
                        my @arg = split /,/, $chatMsg;
                        my $i = 0;
                        while ($config{"mvpMonster_$i"} ne "") {
                                if ($config{"mvpMonster_$i"} eq $arg[0] && $arg[1] ne "") {
                                        $mvptime{$arg[0]} = $arg[1];
                                        writeMvptimeFileIntact("$setupPath/mvptime.txt", \%mvptime);
                                        undef $mvp{'now_monster'}{'name'} if ($mvp{'now_monster'}{'name'} eq $arg[0]);
                                        last;
                                }
                                $i++;
                        }
                } else {
                        chatLog("g", $chat."\n");
                }
                sendWindowsMessage("017F".chr(1).$chatMsgUser.chr(1).$chatMsg) if ($yelloweasy);

        } elsif ($switch eq "0180" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "0181" && $MsgLength >= 3) {
                $msg_size = 3;

        } elsif ($switch eq "0182" && $MsgLength >= 106) {
                $ID = substr($msg, 2, 4);
                $Level = unpack("S1", substr($msg, 19, 2));
                ($name) = substr($msg, 82, 24) =~ /([\s\S]*?)\000/;
                print "$name $Level级 加入工会\n" if ($config{'debug'});
                $msg_size = 106;

        } elsif ($switch eq "0183" && $MsgLength >= 10) {
                $msg_size = 10;

        } elsif ($switch eq "0184" && $MsgLength >= 10) {
                $msg_size = 10;

        } elsif ($switch eq "0185" && $MsgLength >= 34) {
                $msg_size = 34;

        } elsif ($switch eq "0187" && $MsgLength >= 6) {
                $msg_size = 6;

        # ICE Start - Equipment Information
        } elsif ($switch eq "0188" && $MsgLength >= 8) {
                $index = unpack("S1",substr($msg, 4, 2));
                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                $chars[$config{'char'}]{'inventory'}[$invIndex]{'enchant'} = unpack("C1",substr($msg, 6,  1));
                print "Equipment enchant: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} [+$chars[$config{'char'}]{'inventory'}[$invIndex]{'enchant'}]\n";
                $msg_size = 8;
        # ICE End

        } elsif ($switch eq "0189" && $MsgLength >= 4) {
                $msg_size = 4;

        } elsif ($switch eq "018A" && $MsgLength >= 4) {
                $msg_size = 4;

        } elsif ($switch eq "018B" && $MsgLength >= 4) {
                $msg_size = 4;

        } elsif ($switch eq "018C" && $MsgLength >= 29) {
                $msg_size = 29;

        } elsif ($switch eq "018D" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "018E" && $MsgLength >= 10) {
                $msg_size = 10;

        } elsif ($switch eq "018F" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "0190" && $MsgLength >= 90) {
                $msg_size = 90;

        } elsif ($switch eq "0191" && $MsgLength >= 86) {
                $guildID = substr($msg, 2, 4);
                ($guildName) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
                $msg_size = 86;

        } elsif ($switch eq "0192" && $MsgLength >= 24) {
                $msg_size = 24;

        } elsif ($switch eq "0193" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "0194" && $MsgLength >= 30) {
                $ID = substr($msg, 2, 4);
                if ($accountID ne $ID) {
                        ($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
                        printC("I0C", "公会成员（$name 先生，小姐）上线了。\n");
                }
                $msg_size = 30;

        } elsif ($switch eq "0195" && $MsgLength >= 102) {
                $ID = substr($msg, 2, 4);
                if (%{$players{$ID}}) {
                        ($players{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
                        ($players{$ID}{'party'}{'name'}) = substr($msg, 30, 24) =~ /([\s\S]*?)\000/;
                        ($players{$ID}{'guild'}{'name'}) = substr($msg, 54, 24) =~ /([\s\S]*?)\000/;
                        ($players{$ID}{'guild'}{'men'}{$players{$ID}{'name'}}{'title'}) = substr($msg, 78, 24) =~ /([\s\S]*?)\000/;
                        print "Player Info: $players{$ID}{'name'}($players{$ID}{'binID'})\n" if ($config{'debug'} >= 2);
                        if ($avoidlist_rlut{$players{$ID}{'name'}} && binFind(\@avoidID, $ID) eq "") {
                                $players{$ID}{'AID'} = unpack("L1", $ID);
                                binAdd(\@avoidID, $ID);
                                $aid_rlut{$players{$ID}{'AID'}}{'avoid'} = 1;
                        }
                }
                $msg_size = 102;

        } elsif ($switch eq "0196" && $MsgLength >= 9) {
                $ID = unpack("S1", substr($msg, 2, 2)) + 1;
                $sourceID = substr($msg, 4, 4);
                $type = unpack("C1",substr($msg, 8, 1));
                undef $sourceDisplay;
                undef $targetDisplay;
                if (%{$monsters{$sourceID}}) {
                        $Display = "$monsters{$sourceID}{'name'}($monsters{$sourceID}{'binID'}) ";
                        $monsters{$sourceID}{'skillsst'}{$skillsst_rlut{lc($skillsstID_lut{$ID})}} = $type;
                } elsif (%{$players{$sourceID}}) {
                        $Display = "$players{$sourceID}{'name'}($players{$sourceID}{'binID'}) ";
                        $players{$sourceID}{'skillsst'}{$skillsst_rlut{lc($skillsstID_lut{$ID})}} = $type;
                } elsif ($sourceID eq $accountID) {
                        $Display = "";
                        $chars[$config{'char'}]{'skillsst'}{$skillsst_rlut{lc($skillsstID_lut{$ID})}} = $type;
                } else {
                        $Display = "未知 ";
                }
                if ($sourceID ne $accountID && $chars[$config{'char'}]{'party'}{'users'}{$sourceID}{'name'} ne "") {
                        $i = 0;
                        while ($config{"useParty_skill_$i"} ne "") {
                                if ($skillsstID_lut{$ID} eq $config{"useParty_skill_$i"} && $config{"useParty_skill_$i"."_stateTimeout"} > 0) {
                                        if ($type == 1) {
                                                $ai_v{"useParty_skill_$i"."_time"}{$sourceID} = time - $config{"useParty_skill_$i"."_timeout"} + $config{"useParty_skill_$i"."_stateTimeout"};
                                        } else {
                                                $ai_v{"useParty_skill_$i"."_time"}{$sourceID} = time - $config{"useParty_skill_$i"."_timeout"};
                                        }
                                        last;
                                }
                                $i++;
                        }
                }
                if ($type == 1) {
                        $Display .= "已变成";
                        $Display .= $skillsstID_lut{$ID}."状态";
                        if ($sourceID eq $accountID) {
                                printC("I6C", "$Display\n") if ($config{'Mode'} >= 2);
                        } else {
                                printC("M7", "$Display\n") if ($config{'Mode'} >= 2);
                        }
                } else {
                        $Display .= $skillsstID_lut{$ID}."状态";
                        $Display .= "已解除";
                        if ($sourceID eq $accountID) {
                                printC("I6R", "$Display\n") if ($config{'Mode'} >= 2);
                        } else {
                                printC("I0", "$Display\n") if ($config{'Mode'} >= 2);
                        }
                }
                $msg_size = 9;

        } elsif ($switch eq "0197" && $MsgLength >= 4) {
                $msg_size = 4;

        } elsif ($switch eq "0198" && $MsgLength >= 8) {
                $msg_size = 8;

        } elsif ($switch eq "0199" && $MsgLength >= 4) {
                $msg_size = 4;

        } elsif ($switch eq "019A" && $MsgLength >= 14) {
                $msg_size = 14;

        } elsif ($switch eq "019B" && $MsgLength >= 10) {
                $ID = substr($msg, 2, 4);
                $type = unpack("L1",substr($msg, 6, 4));
                if (%{$players{$ID}}) {
                        $name = $players{$ID}{'name'};
                } else {
                        $name = "Unknown";
                }
                if ($type == 0) {
                        printC("I0W", "玩家 $name 基本等级提升\n");
                } elsif ($type == 1) {
                        printC("I0W", "玩家 $name 职业等级提升\n");
                }
                $msg_size = 10;

        } elsif ($switch eq "019C" && $MsgLength >= 4) {
                $msg_size = 4;

        } elsif ($switch eq "019D" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "019E" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "019F" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "01A0" && $MsgLength >= 3) {
                $msg_size = 3;

        } elsif ($switch eq "01A1" && $MsgLength >= 3) {
                $msg_size = 3;

        } elsif ($switch eq "01A2" && $MsgLength >= 35) {
                #pet
                ($name) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
                $pets{$ID}{'name_given'} = 1;
                $msg_size = 35;

        } elsif ($switch eq "01A3" && $MsgLength >= 5) {
                $msg_size = 5;

        } elsif ($switch eq "01A4" && $MsgLength >= 11) {
                #pet spawn
                $type = unpack("C1",substr($msg, 2, 1));
                $ID = substr($msg, 3, 4);
                if (!%{$pets{$ID}}) {
                        binAdd(\@petsID, $ID);
                        %{$pets{$ID}} = %{$monsters{$ID}};
                        $pets{$ID}{'name_given'} = "Unknown";
                        $pets{$ID}{'binID'} = binFind(\@petsID, $ID);
                }
                if (%{$monsters{$ID}}) {
                        binRemove(\@monstersID, $ID);
                        undef %{$monsters{$ID}};
                }
                print "Pet Spawned: $pets{$ID}{'name'}($pets{$ID}{'binID'})\n" if ($config{'debug'});
                $msg_size = 11;

        } elsif ($switch eq "01A5" && $MsgLength >= 26) {
                $msg_size = 26;

        } elsif ($switch eq "01A6" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "01A7" && $MsgLength >= 4) {
                $msg_size = 4;

        } elsif ($switch eq "01A8" && $MsgLength >= 4) {
                $msg_size = 4;

        } elsif ($switch eq "01A9" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "01AA" && $MsgLength >= 10) {
                #pet
                $msg_size = 10;

        } elsif ($switch eq "01AB" && $MsgLength >= 12) {
               #Chat and skill ban
               $ID = substr($msg, 2, 4);
               $type = unpack("S1", substr($msg, 6, 2));
               $val =  abs(unpack("l1", substr($msg, 8, 4)));

               if ($ID eq $accountID) {
                       $display = "你";
               } elsif (%{$players{$ID}}) {
                       $display = "$players{$ID}{'name'}($players{$ID}{'binID'})";
               } else {
                       $display = "Unknown";
               }
               if ($ID eq $accountID) {
                        printC("S0R", "你被禁言 $val 分钟...\n");
                        chatLog("gm", "你被禁言 $val 分钟...\n");
                        ($map_string) = $map_name =~ /([\s\S]*)\.gat/;
                        $sleeptime = int($val * 60 + rand() * 600);
                        printC("S0R", "躲避禁言,断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        chatLog("gm", "躲避禁言,断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        killConnection(\$remote_socket);
                        sleep($sleeptime);
               } else {
                            printC("I1", "$display 被禁言 $val 分钟...\n");
                }
                $msg_size = 12;

        } elsif ($switch eq "01AC" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "01AD" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "01AE" && $MsgLength >= 4) {
                $msg_size = 4;

        } elsif ($switch eq "01AF" && $MsgLength >= 4) {
                $msg_size = 4;

        } elsif ($switch eq "01B0" && $MsgLength >= 11) {
                $msg_size = 11;

        } elsif ($switch eq "01B1" && $MsgLength >= 7) {
                $msg_size = 7;

        } elsif ($switch eq "01B2" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "01B3" && $MsgLength >= 67) {
                #NPC image
                $npc_image = substr($msg, 2,64);
                ($npc_image) = $npc_image =~ /(\S+)/;
                print "NPC image: $npc_image\n" if $config{'debug'};
                $msg_size = 67;

        } elsif ($switch eq "01B4" && $MsgLength >= 12) {
                $msg_size = 12;

        } elsif ($switch eq "01B5" && $MsgLength >= 18) {
                $msg_size = 18;

        } elsif ($switch eq "01B6" && $MsgLength >= 114) {
                #Guild Info
                $msg_size = 114;

        } elsif ($switch eq "01B7" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "01B8" && $MsgLength >= 3) {
                $msg_size = 3;

        } elsif ($switch eq "01B9" && $MsgLength >= 6) {
                $ID = substr($msg, 2, 4);
                undef $display;
                if ($ID eq $accountID) {
                        aiRemove("skill_use");
                        printC("I0R", "使用技能失败\n") if ($config{'Mode'} >= 1);
                } elsif (%{$monsters{$ID}}) {
                        printC("I0", "$monsters{$ID}{'name'}($monsters{$ID}{'binID'}) 使用技能失败\n") if ($config{'Mode'} >= 2);
                } elsif (%{$players{$ID}}) {
                        printC("I0", "$players{$ID}{'name'}($players{$ID}{'binID'}) 使用技能失败\n") if ($config{'Mode'} >= 2);
                } else {
                        printC("I0", "未知 使用技能失败\n") if ($config{'Mode'} >= 2);
                }
                $msg_size = 6;

        } elsif ($switch eq "01BA" && $MsgLength >= 26) {
                $msg_size = 26;

        } elsif ($switch eq "01BB" && $MsgLength >= 26) {
                $msg_size = 26;

        } elsif ($switch eq "01BC" && $MsgLength >= 26) {
                $msg_size = 26;

        } elsif ($switch eq "01BD" && $MsgLength >= 26) {
                $msg_size = 26;

        } elsif ($switch eq "01BE" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "01BF" && $MsgLength >= 3) {
                $msg_size = 3;

        } elsif ($switch eq "01C0" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "01C1" && $MsgLength >= 14) {
                $msg_size = 14;

        } elsif ($switch eq "01C2" && $MsgLength >= 10) {
                $msg_size = 10;

        } elsif ($switch eq "01C3" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "01C4" && $MsgLength >= 22) {
                $index = unpack("S1", substr($msg, 2, 2));
                $amount = unpack("L1", substr($msg, 4, 4));
                $ID = unpack("S1", substr($msg, 8, 2));
                if (%{$storage{'inventory'}[$index]}) {
                        $storage{'inventory'}[$index]{'amount'} += $amount;
                } else {
                        $storage{'inventory'}[$index]{'nameID'} = $ID;
                        $storage{'inventory'}[$index]{'amount'} = $amount;
                        $display = ($items_lut{$ID} ne "")
                                ? $items_lut{$ID}
                                : "Unknown ".$ID;
                        $storage{'inventory'}[$index]{'name'} = $display;
                }
                printC("I4", "加入: $storage{'inventory'}[$index]{'name'} x $amount\n");
                $msg_size = 22;

        } elsif ($switch eq "01C5" && $MsgLength >= 22) {
                $msg_size = 22;

        } elsif ($switch eq "01C6" && $MsgLength >= 4) {
                $msg_size = 4;

        } elsif ($switch eq "01C7" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "01C8" && $MsgLength >= 13) {
                $index = unpack("S1",substr($msg, 2, 2));
                $itemType = unpack("S1", substr($msg, 4, 2));
                $ID = substr($msg, 6, 4);
                $amount = unpack("S1",substr($msg, 10, 2));
                $amountUsed = unpack("C1",substr($msg, 12, 1));
                $display = ($items_lut{$itemType} ne "")
                        ? $items_lut{$itemType}
                        : "Unknown " . $itemType;
                if ($ID eq $accountID) {
                        undef $invIndex;
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = $amount if ($invIndex ne "");
                        if ($config{'Mode'}) {
                                printC("I3", "");
                                writeC("X", "使用: ");
                                writeC("G", "$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}");
                                writeC("X", " x $amountUsed");
                                print "\n";
                        }
                        sendWindowsMessage("AA20".chr(1).$invIndex.chr(1).$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}.chr(1).$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}.chr(1).$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'}) if ($yelloweasy);
                        undef $chars[$config{'char'}]{'sendItemUse'};
                        if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0 && $invIndex ne "") {
                                undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
                        }
                        $exp{'item'}{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}{'used'} += $amountUsed;
                } elsif (%{$players{$ID}}) {
                        printC("I1", "$players{$ID}{'name'}($players{$ID}{'binID'}) 使用物品: $display x $amountUsed ($amount)\n") if ($config{'debug'});
                } elsif (%{$monsters{$ID}}) {
                        printC("I2", "$monsters{$ID}{'name'}($monsters{$ID}{'binID'}) 使用物品: $display x $amountUsed ($amount)\n") if ($config{'debug'});
                }
                $msg_size = 13;

        } elsif ($switch eq "01C9" && $MsgLength >= 97) {
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
                printC("I0", "出现: $spells{$ID}{'name'} ($spells{$ID}{'pos'}{'x'}, $spells{$ID}{'pos'}{'y'}) 距离: $spells{$ID}{'distance'}\n") if ($config{'debug'});
                if (!$chars[$config{'char'}]{'warpTo'} && ($type == 129 || $type == 130) && $spells{$ID}{'distance'} == 0 && $config{'teleportAuto_portalPlayer'}) {
                        if ($config{'teleportAuto_portalPlayer'} == 1 && !$indoor_lut{$field{'name'}.'.rsw'}) {
                                printC("A5R", "瞬移躲避恶意传送: $players{$sourceID}{'name'} $field{'name'} ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})\n") if ($config{'Mode'});
                                chatLog("x", "瞬移躲避恶意传送: $players{$sourceID}{'name'} $field{'name'} ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})\n");
                                useTeleport(1);
                        } elsif ($config{'teleportAuto_portalPlayer'} == 2 || $indoor_lut{$field{'name'}.'.rsw'}) {
                                aiRemove("move");
                                aiRemove("route");
                                aiRemove("route_getRoute");
                                aiRemove("route_getMapRoute");
                                printC("A5R", "移动躲避恶意传送 $players{$sourceID}{'name'} $field{'name'} ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})\n") if ($config{'Mode'});
                                chatLog("x", "移动躲避恶意传送: $players{$sourceID}{'name'} $field{'name'} ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})\n");
                                $ai_v{'temp'}{'pos'}{'x'} = $spells{$ID}{'pos'}{'x'};
                                $ai_v{'temp'}{'pos'}{'y'} = $spells{$ID}{'pos'}{'y'};
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
                $msg_size = 97;

        } elsif ($switch eq "01CB" && $MsgLength >= 9) {
                $msg_size = 9;

        } elsif ($switch eq "01CC" && $MsgLength >= 9) {
                $msg_size = 9;

        } elsif ($switch eq "01CD" && $MsgLength >= 30) {
                $msg_size = 30;

        } elsif ($switch eq "01CE" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "01CF" && $MsgLength >= 28) {
                $msg_size = 28;

        } elsif ($switch eq "01D0" && $MsgLength >= 8) {
                $sourceID = substr($msg, 2, 4);
                $amount = unpack("S1",substr($msg, 6, 2));
                if ($sourceID eq $accountID) {
                        $chars[$config{'char'}]{'Spirits'} = $amount;
                }
                $msg_size = 8;

        } elsif ($switch eq "01D1" && $MsgLength >= 14) {
                $msg_size = 14;

        } elsif ($switch eq "01D2" && $MsgLength >= 10) {
                $msg_size = 10;

        } elsif ($switch eq "01D3" && $MsgLength >= 35) {
                $msg_size = 35;

        } elsif ($switch eq "01D4" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "01D5" && $MsgLength >= 8) {
                $msg_size = 8;

        } elsif ($switch eq "01D6" && $MsgLength >= 4) {
                $msg_size = 4;

        } elsif ($switch eq "01D7" && $MsgLength >= 11) {
                $ID = substr($msg, 2, 4);
                $type = unpack("C*",substr($msg, 6,  1));
                $itemID = unpack("S*",substr($msg, 7,  2));
                $msg_size = 11;

        } elsif ($switch eq "01D8" && $MsgLength >= 54) {
                $ID = substr($msg, 2, 4);
                makeCoords(\%coords, substr($msg, 46, 3));
                $type = unpack("S*",substr($msg, 14,  2));
                $pet = unpack("C*",substr($msg, 16,  1));
                $sex = unpack("C*",substr($msg, 45,  1));
                $sitting = unpack("C*",substr($msg, 51,  1));
                $param1 = unpack("S1", substr($msg, 8, 2));
                $param2 = unpack("S1", substr($msg, 10, 2));
                $param3 = unpack("S1", substr($msg, 12, 2));
                if ($type >= 1000) {
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
                                print "Pet Exists: $pets{$ID}{'name'}($pets{$ID}{'binID'})\n" if ($config{'debug'});
                        } else {
                                if (!%{$monsters{$ID}}) {
                                        $monsters{$ID}{'appear_time'} = time;
                                        $display = ($monsters_lut{$type} ne "")
                                                        ? $monsters_lut{$type}
                                                        : "Unknown ".$type;
                                        binAdd(\@monstersID, $ID);
                                        $monsters{$ID}{'nameID'} = $type;
                                        $monsters{$ID}{'name'} = $display;
                                        $monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
                                }
                                %{$monsters{$ID}{'pos'}} = %coords;
                                %{$monsters{$ID}{'pos_to'}} = %coords;
                                print "Monster Exists: $monsters{$ID}{'name'}($monsters{$ID}{'binID'})\n" if ($config{'debug'});
                                # ICE Start - MVP Monster
                                if ($config{'mvpMode'} && $monsters{$ID}{'mvp'} != 1 && ($mon_control{lc($monsters{$ID}{'name'})}{'attack_auto'} >=1 || ($mon_control{lc($monsters{$ID}{'name'})}{'attack_auto'} eq "" && $mon_control{'all'}{'attack_auto'} >= 1))) {
                                        if($importantMonsters_rlut{$monsters{$ID}{'name'}} == 1) {
                                                $monsters{$ID}{'mvp'} = 1;
                                                if (!$chars[$config{'char'}]{'mvp'}) {
                                                        ai_changeToMvpMode(1);
                                                        chatLog("m", "发现: $monsters{$ID}{'name'} $field{'name'} ($monsters{$ID}{'pos'}{'x'}, $monsters{$ID}{'pos'}{'y'})\n");
                                                        attack($ID) if ($config{'attackMvpFirst'});
                                                }
                                        }
                                }
                                # ICE End
                        }

                } elsif ($jobs_lut{$type}) {
                        if (!%{$players{$ID}}) {
                                $players{$ID}{'appear_time'} = time;
                                binAdd(\@playersID, $ID);
                                $players{$ID}{'jobID'} = $type;
                                $players{$ID}{'sex'} = $sex;
                                $players{$ID}{'name'} = "Unknown";
                                $players{$ID}{'binID'} = binFind(\@playersID, $ID);
                                $players{$ID}{'AID'} = unpack("L1", $ID);
                                if ($aid_rlut{$players{$ID}{'AID'}}{'avoid'}) {
                                        %{$players{$ID}{'pos'}} = %coords;
                                        %{$players{$ID}{'pos_to'}} = %coords;
                                        binAdd(\@avoidID, $ID);
                                }
                        }
                        $players{$ID}{'sitting'} = $sitting > 0;
                        %{$players{$ID}{'pos'}} = %coords;
                        %{$players{$ID}{'pos_to'}} = %coords;
                        print "Player Exists: $players{$ID}{'name'}($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});

                } elsif ($type == 45) {
                        if (!%{$portals{$ID}}) {
                                $portals{$ID}{'appear_time'} = time;
                                $nameID = unpack("L1", $ID);
                                $exists = portalExists($field{'name'}, \%coords);
                                $display = ($exists ne "")
                                        ? "$portals_lut{$exists}{'source'}{'map'} -> $portals_lut{$exists}{'dest'}{'map'}"
                                        : "Unknown ".$nameID;
                                binAdd(\@portalsID, $ID);
                                $portals{$ID}{'source'}{'map'} = $field{'name'};
                                $portals{$ID}{'type'} = $type;
                                $portals{$ID}{'nameID'} = $nameID;
                                $portals{$ID}{'name'} = $display;
                                $portals{$ID}{'binID'} = binFind(\@portalsID, $ID);
                        }
                        %{$portals{$ID}{'pos'}} = %coords;
                        printC("M5", "存在: $portals{$ID}{'name'} - ($portals{$ID}{'binID'})\n");

                } elsif ($type < 1000) {
                        print "type value: ($type) job value: ($jobs_lut{$type})\n";
                        if (!%{$npcs{$ID}}) {
                                $npcs{$ID}{'appear_time'} = time;
                                $nameID = unpack("L1", $ID);
                                $display = (%{$npcs_lut{$nameID}})
                                        ? $npcs_lut{$nameID}{'name'}
                                        : "Unknown ".$nameID;
                                binAdd(\@npcsID, $ID);
                                $npcs{$ID}{'type'} = $type;
                                $npcs{$ID}{'nameID'} = $nameID;
                                $npcs{$ID}{'name'} = $display;
                                $npcs{$ID}{'binID'} = binFind(\@npcsID, $ID);
                        }
                        %{$npcs{$ID}{'pos'}} = %coords;
                        printC("M3", "存在: $npcs{$ID}{'name'} - ($npcs{$ID}{'binID'})\n");

                } else {
                        print "Unknown Exists: $type - ".unpack("L*",$ID)."\n" if $config{'debug'};
                }

                undef $sourceDisplay;
                undef $targetDisplay;
                undef $state;
                if ($param1 == 0 && $param2 == 0) {
                        $targetDisplay = $msgstrings_lut{'0119'}{"00"};
                } else {
                        if ($param1 == 1) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"A1"};
                        } elsif ($param1 == 2) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"A2"};
                        } elsif ($param1 == 3) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"A3"};
                        } elsif ($param1 == 4) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"A4"};
                        } elsif ($param1 == 6) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"A6"};
                        } elsif ($param2 == 1) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"B1"};
                        } elsif ($param2 == 2) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"B2"};
                        } elsif ($param2 == 4) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"B4"};
                        } elsif ($param2 == 16) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"B16"};
                        } elsif ($param2 == 32) {
                                $targetDisplay = $msgstrings_lut{'0119'}{"B32"};
                        } else {
                                $targetDisplay = "未知状态$param1$param2$param3";
                        }
                }
                if ($param3 == 1) {
#                        $targetDisplay = $msgstrings_lut{'0119'}{"C1"};
                } elsif ($param3 == 2) {
#                        $targetDisplay = $msgstrings_lut{'0119'}{"C2"};
                } elsif ($param3 == 4) {
#                        $targetDisplay = $msgstrings_lut{'0119'}{"C4"};
                } elsif ($param3 == 8) {
#                        $targetDisplay = "持有手推车Ⅰ";
                } elsif ($param3 == 16) {
#                        $targetDisplay = "装备好猎鹰";
                } elsif ($param3 == 32) {
#                        $targetDisplay = "骑上大嘴鸟";
                } elsif ($param3 == 64) {
#                        $targetDisplay = $msgstrings_lut{'0119'}{"C64"};
                } elsif ($param3 == 128) {
#                        $targetDisplay = "持有手推车Ⅱ";
                } elsif ($param3 == 256) {
#                        $targetDisplay = "持有手推车Ⅲ";
                } elsif ($param3 == 512) {
#                        $targetDisplay = "持有手推车Ⅳ";
                } elsif ($param3 == 1024) {
#                        $targetDisplay = "持有手推车Ⅴ";
                }
                $state = $targetDisplay;
                $targetDisply .= "($param1|$param2|$param3)" if ($config{'debug'});
                if (%{$monsters{$ID}}) {
                        $sourceDisplay = "$monsters{$ID}{'name'}($monsters{$ID}{'binID'}) ";
                        $monsters{$ID}{'state'} = $state;
                } elsif (%{$players{$ID}}) {
                        $sourceDisplay = "$players{$ID}{'name'}($players{$ID}{'binID'}) ";
                        $players{$ID}{'state'} = $state;
                } elsif ($ID eq $accountID) {
                        $sourceDisplay = "";
                        $chars[$config{'char'}]{'state_last'} = $chars[$config{'char'}]{'state'};
                        $chars[$config{'char'}]{'state'} = $state;
                } else {
                        $sourceDisplay = "未知 ";
                }
                if ($ID eq $accountID && ($state ne $msgstrings_lut{'0119'}{"00"} && $state ne $msgstrings_lut{'0119'}{"B32"})) {
                        printC("I6M", "$sourceDisplay变成$targetDisplay\n") if ($config{'debug'});
                } elsif ($ID eq $accountID) {
                        printC("I6W", "$sourceDisplay变成$targetDisplay\n") if (($config{'debug'} && ($chars[$config{'char'}]{'state_last'} ne $msgstrings_lut{'0119'}{"00"} && $chars[$config{'char'}]{'state_last'} ne $msgstrings_lut{'0119'}{"B32"})) || $config{'debug'} >= 2);
                } else {
                        printC("I0", "$sourceDisplay变成$targetDisplay\n") if ($config{'debug'} >= 2);
                }
                $msg_size = 54;

        } elsif ($switch eq "01D9" && $MsgLength >= 53) {
                $ID = substr($msg, 2, 4);
                makeCoords(\%coords, substr($msg, 46, 3));
                $type = unpack("S*",substr($msg, 14,  2));
                $sex = unpack("C*",substr($msg, 45,  1));
                if ($jobs_lut{$type}) {
                        if (!%{$players{$ID}}) {
                                $players{$ID}{'appear_time'} = time;
                                binAdd(\@playersID, $ID);
                                $players{$ID}{'jobID'} = $type;
                                $players{$ID}{'sex'} = $sex;
                                $players{$ID}{'name'} = "Unknown";
                                $players{$ID}{'binID'} = binFind(\@playersID, $ID);
                                $players{$ID}{'AID'} = unpack("L1", $ID);
                                if ($aid_rlut{$players{$ID}{'AID'}}{'avoid'}) {
                                        %{$players{$ID}{'pos'}} = %coords;
                                        %{$players{$ID}{'pos_to'}} = %coords;
                                        binAdd(\@avoidID, $ID);
                                }
                        }
                        %{$players{$ID}{'pos'}} = %coords;
                        %{$players{$ID}{'pos_to'}} = %coords;
                        print "Player Connected: $players{$ID}{'name'}($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});

                } else {
                        print "Unknown Connected: $type - ".getHex($ID)."\n" if $config{'debug'};
                }
                $msg_size = 53;

        } elsif ($switch eq "01DA" && $MsgLength >= 60) {
                $ID = substr($msg, 2, 4);
                makeCoords(\%coordsFrom, substr($msg, 50, 3));
                makeCoords2(\%coordsTo, substr($msg, 52, 3));
                $type = unpack("S*",substr($msg, 14,  2));
                $pet = unpack("C*",substr($msg, 16,  1));
                $sex = unpack("C*",substr($msg, 49,  1));
                if ($type >= 1000) {
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
                                print "Pet Moved: $pets{$ID}{'name'}($pets{$ID}{'binID'})\n" if ($config{'debug'});
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
                                        print "Monster Appeared: $monsters{$ID}{'name'}($monsters{$ID}{'binID'})\n" if $config{'debug'};
                                        # ICE Start - MVP Monster
                                        %{$monsters{$ID}{'pos'}} = %coordsFrom;
                                        if ($config{'mvpMode'} && $monsters{$ID}{'mvp'} != 1 && ($mon_control{lc($monsters{$ID}{'name'})}{'attack_auto'} >=1 || ($mon_control{lc($monsters{$ID}{'name'})}{'attack_auto'} eq "" && $mon_control{'all'}{'attack_auto'} >= 1))) {
                                                if($importantMonsters_rlut{$monsters{$ID}{'name'}} == 1) {
                                                        $monsters{$ID}{'mvp'} = 1;
                                                        if (!$chars[$config{'char'}]{'mvp'}) {
                                                                ai_changeToMvpMode(1);
                                                                chatLog("m", "发现: $monsters{$ID}{'name'} $field{'name'} ($monsters{$ID}{'pos'}{'x'}, $monsters{$ID}{'pos'}{'y'})\n");
                                                                attack($ID) if ($config{'attackMvpFirst'});
                                                        }
                                                }
                                        }
                                        # ICE End
                                }
                                %{$monsters{$ID}{'pos'}} = %coordsFrom;
                                %{$monsters{$ID}{'pos_to'}} = %coordsTo;
                                print "Monster Moved: $monsters{$ID}{'name'}($monsters{$ID}{'binID'})\n" if ($config{'debug'} >= 2);
                        }
                } elsif ($jobs_lut{$type}) {
                        if (!%{$players{$ID}}) {
                                binAdd(\@playersID, $ID);
                                $players{$ID}{'appear_time'} = time;
                                $players{$ID}{'sex'} = $sex;
                                $players{$ID}{'jobID'} = $type;
                                $players{$ID}{'name'} = "Unknown";
                                $players{$ID}{'binID'} = binFind(\@playersID, $ID);
                                $players{$ID}{'AID'} = unpack("L1", $ID);
                                if ($aid_rlut{$players{$ID}{'AID'}}{'avoid'}) {
                                        %{$players{$ID}{'pos'}} = %coords;
                                        %{$players{$ID}{'pos_to'}} = %coords;
                                        binAdd(\@avoidID, $ID);
                                }
                                print "Player Appeared: $players{$ID}{'name'}($players{$ID}{'binID'}) $sex_lut{$sex} $jobs_lut{$type}\n" if $config{'debug'};
                        }
                        %{$players{$ID}{'pos'}} = %coordsFrom;
                        %{$players{$ID}{'pos_to'}} = %coordsTo;
                        print "Player Moved: $players{$ID}{'name'}($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'} >= 2);
                } else {
                        print "Unknown Moved: $type - ".getHex($ID)."\n" if $config{'debug'};
                }
                $msg_size = 60;

        } elsif ($switch eq "01DB" && $MsgLength >= 2) {
                $msg_size = 2;

        } elsif ($switch eq "01DC" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;

        } elsif ($switch eq "01DD" && $MsgLength >= 47) {
                $msg_size = 47;

        } elsif ($switch eq "01DE" && $MsgLength >= 33) {
                $skillID = unpack("S1",substr($msg, 2, 2));
                $sourceID = substr($msg, 4, 4);
                $targetID = substr($msg, 8, 4);
                $damage = unpack("S1",substr($msg, 24, 2));
                $level = unpack("S1",substr($msg, 26, 2));
                $level = 0 if ($level == 65535);
                if (%{$spells{$sourceID}}) {
                        $sourceID = $spells{$sourceID}{'sourceID'}
                }
                updateDamageTables($sourceID, $targetID, $damage) if ($damage != 35536);
                if ($sourceID eq $accountID) {
                        $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
                        undef $chars[$config{'char'}]{'time_cast'};
                }

                if (%{$monsters{$targetID}}) {
                        if ($sourceID eq $accountID) {
                                $monsters{$targetID}{'castOnByYou'}++;
                        } else {
                                $monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
                        }
                }
                if ($damage != 35536) {
                        if ($level_real ne "") {
                                     $level = $level_real;
                        }
                        attackC("s", $sourceID, $targetID, $damage, 0, 0, $skillID, $level);
                } else {
                        $level_real = $level;
                        attackC("u", $sourceID, $targetID, 0, 0, 0, $skillID, $level);
                }
                $msg_size = 33;

        } elsif ($switch eq "01DF" && $MsgLength >= 6) {
                $msg_size = 6;

        } elsif ($switch eq "01E0" && $MsgLength >= 30) {
                $msg_size = 30;
        } elsif ($switch eq "01E1" && $MsgLength >= 8) {
                $msg_size = 8;
        } elsif ($switch eq "01E2" && $MsgLength >= 34) {
                $msg_size = 34;
        } elsif ($switch eq "01E3" && $MsgLength >= 14) {
                $msg_size = 14;
        } elsif ($switch eq "01E4" && $MsgLength >= 2) {
                $msg_size = 2;
        } elsif ($switch eq "01E5" && $MsgLength >= 6) {
                $msg_size = 6;
        } elsif ($switch eq "01E3" && $MsgLength >= 26) {
                $msg_size = 26;
        } elsif ($switch eq "01E7" && $MsgLength >= 2) {
                $msg_size = 2;
        } elsif ($switch eq "01E8" && $MsgLength >= 28) {
                $msg_size = 28;
        } elsif ($switch eq "01E9" && $MsgLength >= 81) {
                $msg_size = 81;
        } elsif ($switch eq "01E3" && $MsgLength >= 6) {
                $msg_size = 6;
        } elsif ($switch eq "01EB" && $MsgLength >= 10) {
                $msg_size = 10;
        } elsif ($switch eq "01EC" && $MsgLength >= 26) {
                $msg_size = 26;
        } elsif ($switch eq "01ED" && $MsgLength >= 2) {
                $msg_size = 2;
        } elsif ($switch eq "01EE" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                undef $invIndex;
                for($i = 4; $i < $msg_size; $i+=18) {
                        $index = unpack("S1", substr($msg, $i, 2));
                        $ID = unpack("S1", substr($msg, $i + 2, 2));
                        $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
                        if ($invIndex eq "") {
                                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
                        }
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = $ID;
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = unpack("S1", substr($msg, $i + 6, 2));
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
                        $display = ($items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}} ne "")
                                ? $items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}
                                : "Unknown ".$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'};
                        $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = $display;
                        if ($index == $EAIndex && $EAIndex ne "") {
                                undef $EAIndex;
                                $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = 1;
                        }
                        print "Inventory: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}($invIndex) x $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}}\n" if $config{'debug'};
                }
                $msg_size = $dMsgLength;

        } elsif ($switch eq "01EF" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                for($i = 4; $i < $msg_size; $i+=18) {
                        $index = unpack("S1", substr($msg, $i, 2));
                        $ID = unpack("S1", substr($msg, $i+2, 2));
                        $amount = unpack("S1", substr($msg, $i+6, 2));
                        if (%{$cart{'inventory'}[$index]}) {
                                $cart{'inventory'}[$index]{'amount'} += $amount;
                        } else {
                                $cart{'inventory'}[$index]{'nameID'} = $ID;
                                $cart{'inventory'}[$index]{'amount'} = $amount;
                                $cart{'inventory'}[$index]{'type_equip'} = $itemSlots_lut{$ID};
                                $display = ($items_lut{$ID} ne "")
                                        ? $items_lut{$ID}
                                        : "Unknown ".$ID;
                                $cart{'inventory'}[$index]{'name'} = $display;
                        }
                        print "Cart Item: $cart{'inventory'}[$index]{'name'}($index) x $cart{'inventory'}[$index]{'amount'} - $itemTypes_lut{$cart{'inventory'}[$index]{'type'}}\n" if $config{'debug'};
                }
                $msg_size = $dMsgLength;

        } elsif ($switch eq "01F0" && $MsgLength >= 4 && $MsgLength >= $dMsgLength) {
                $msg_size = $dMsgLength;
                decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
                $msg = substr($msg, 0, 4).$newmsg;
                undef @{$storage{'inventory'}};
                for($i = 4; $i < $msg_size; $i+=18) {
                        $index = unpack("S1", substr($msg, $i, 2));
                        $ID = unpack("S1", substr($msg, $i + 2, 2));
                        $storage{'inventory'}[$index]{'nameID'} = $ID;
                        $storage{'inventory'}[$index]{'amount'} = unpack("S1", substr($msg, $i + 6, 2));
                        $storage{'inventory'}[$index]{'type_equip'} = $itemSlots_lut{$ID};
                        $display = ($items_lut{$ID} ne "")
                                ? $items_lut{$ID}
                                : "Unknown ".$ID;
                        $storage{'inventory'}[$index]{'name'} = $display;
                        print "Storage: $storage{'inventory'}[$index]{'name'}($index) x $storage{'inventory'}[$index]{'amount'}\n" if ($config{'debug'});
                }
                printC("I4", "打开仓库\n");
                $msg_size = $dMsgLength;
        } else {
                printC("S1R", "未知封包 - $switch\n") if $config{'debug'};
        }

        $lastPacket = substr($msg, 0, $msg_size) if ($config{'debug_packet'} >= 2 && $msg_size);
        $msg = (length($msg) >= $msg_size) ? substr($msg, $msg_size, length($msg) - $msg_size) : "";
        return $msg;
}




#######################################
#######################################
#AI FUNCTIONS
#######################################
#######################################

sub ai_clientSuspend {
        my ($type,$initTimeout,@args) = @_;
        my %args;
        $args{'type'} = $type;
        $args{'time'} = time;
        $args{'timeout'} = $initTimeout;
        @{$args{'args'}} = @args;
        unshift @ai_seq, "clientSuspend";
        unshift @ai_seq_args, \%args;
}

sub ai_follow {
        my $name = shift;
        my %args;
        $args{'name'} = $name;
        unshift @ai_seq, "follow";
        unshift @ai_seq_args, \%args;
}

sub ai_getAggressives {
        my @agMonsters;
        foreach (@monstersID) {
                next if ($_ eq "");
                if ($monsters{$_}{'dmgToYou'} > 0 || $monsters{$_}{'missedYou'} > 0) {
                        push @agMonsters, $_;
                }
        }
        return @agMonsters;
}

sub ai_getIDFromChat {
        my $r_hash = shift;
        my $msg_user = shift;
        my $match_text = shift;
        my $qm;
        if ($match_text !~ /\w+/ || $match_text eq "me") {
                foreach (keys %{$r_hash}) {
                        next if ($_ eq "");
                        if ($msg_user eq $$r_hash{$_}{'name'}) {
                                return $_;
                        }
                }
        } else {
                foreach (keys %{$r_hash}) {
                        next if ($_ eq "");
                        $qm = quotemeta $match_text;
                        if ($$r_hash{$_}{'name'} =~ /$qm/i) {
                                return $_;
                        }
                }
        }
}

sub ai_getMonstersWhoHitMe {
        my @agMonsters;
        foreach (@monstersID) {
                next if ($_ eq "");
                if ($monsters{$_}{'dmgToYou'} > 0 && $monsters{$_}{'attack_failed'} <= 1) {
                        push @agMonsters, $_;
                }
        }
        return @agMonsters;
}

sub ai_getSkillUseType {
        my $skill = shift;
        if ($skill eq "WZ_FIREPILLAR" || $skill eq "WZ_METEOR"
                || $skill eq "WZ_VERMILION" || $skill eq "WZ_STORMGUST"
                || $skill eq "WZ_HEAVENDRIVE" || $skill eq "WZ_QUAGMIRE"
                || $skill eq "MG_SAFETYWALL" || $skill eq "MG_FIREWALL"
                || $skill eq "MG_THUNDERSTORM" || $skill eq "AL_PNEUMA"
                || $skill eq "AL_WARP"
                || $skill eq "PR_SANCTUARY" || $skill eq "PR_BENEDICTIO"
                || $skill eq "PR_MAGNUS" || $skill eq "BS_HAMMERFALL"
                || $skill eq "HT_SKIDTRAP" || $skill eq "HT_LANDMINE"
                || $skill eq "HT_ANKLESNARE" || $skill eq "HT_SHOCKWAVE"
                || $skill eq "HT_SANDMAN" || $skill eq "HT_FLASHER"
                || $skill eq "HT_FREEZINGTRAP" || $skill eq "HT_BLASTMINE"
                || $skill eq "HT_CLAYMORETRAP" || $skill eq "AS_VENOMDUST"
                || $skill eq "SA_VOLCANO" || $skill eq "SA_DELUGE"
                || $skill eq "SA_VIOLENTGALE" || $skill eq "SA_LANDPROTECTOR") {
                return 1;
        } else {
                return 0;
        }

}

sub ai_mapRoute_getRoute {

        my %args;

        ##VARS

        $args{'g_normal'} = 1;

        ###

        my ($returnArray, $r_start_field, $r_start_pos, $r_dest_field, $r_dest_pos, $time_giveup) = @_;
        $args{'returnArray'} = $returnArray;
        $args{'r_start_field'} = $r_start_field;
        $args{'r_start_pos'} = $r_start_pos;
        $args{'r_dest_field'} = $r_dest_field;
        $args{'r_dest_pos'} = $r_dest_pos;
        $args{'time_giveup'}{'timeout'} = $time_giveup;
        $args{'time_giveup'}{'time'} = time;
        unshift @ai_seq, "route_getMapRoute";
        unshift @ai_seq_args, \%args;
}

sub ai_mapRoute_getSuccessors {
        my ($r_args, $r_array, $r_cur) = @_;
        my $ok;
        foreach (keys %portals_lut) {
                if ($portals_lut{$_}{'source'}{'map'} eq $$r_cur{'dest'}{'map'}

                        && !($$r_cur{'source'}{'map'} eq $portals_lut{$_}{'dest'}{'map'}
                        && $$r_cur{'source'}{'pos'}{'x'} == $portals_lut{$_}{'dest'}{'pos'}{'x'}
                        && $$r_cur{'source'}{'pos'}{'y'} == $portals_lut{$_}{'dest'}{'pos'}{'y'})

                        && !(%{$$r_cur{'parent'}} && $$r_cur{'parent'}{'source'}{'map'} eq $portals_lut{$_}{'dest'}{'map'}
                        && $$r_cur{'parent'}{'source'}{'pos'}{'x'} == $portals_lut{$_}{'dest'}{'pos'}{'x'}
                        && $$r_cur{'parent'}{'source'}{'pos'}{'y'} == $portals_lut{$_}{'dest'}{'pos'}{'y'})) {
                        undef $ok;
                        if (!%{$$r_cur{'parent'}}) {
                                if (!$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solutionTried'}) {
                                        $$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solutionTried'} = 1;
                                        $timeout{'ai_route_calcRoute'}{'time'} -= $timeout{'ai_route_calcRoute'}{'timeout'};
                                        $$r_args{'waitingForSolution'} = 1;
                                        ai_route_getRoute(\@{$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solution'}},
                                                        $$r_args{'start'}{'dest'}{'field'}, \%{$$r_args{'start'}{'dest'}{'pos'}}, \%{$portals_lut{$_}{'source'}{'pos'}});
                                        last;
                                }
                                $ok = 1 if (@{$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solution'}});
                        } elsif ($portals_los{$$r_cur{'dest'}{'ID'}}{$portals_lut{$_}{'source'}{'ID'}} ne "0"
                                && $portals_los{$portals_lut{$_}{'source'}{'ID'}}{$$r_cur{'dest'}{'ID'}} ne "0") {
                                $ok = 1;
                        }
                        if ($$r_args{'dest'}{'source'}{'pos'}{'x'} ne "" && $portals_lut{$_}{'dest'}{'map'} eq $$r_args{'dest'}{'source'}{'map'}) {
                                if (!$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$portals_lut{$_}{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solutionTried'}) {
                                        $$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$portals_lut{$_}{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solutionTried'} = 1;
                                        $timeout{'ai_route_calcRoute'}{'time'} -= $timeout{'ai_route_calcRoute'}{'timeout'};
                                        $$r_args{'waitingForSolution'} = 1;
                                        ai_route_getRoute(\@{$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$portals_lut{$_}{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solution'}},
                                                        $$r_args{'dest'}{'source'}{'field'}, \%{$portals_lut{$_}{'dest'}{'pos'}}, \%{$$r_args{'dest'}{'source'}{'pos'}});
                                        last;
                                }
                        }
                        push @{$r_array}, \%{$portals_lut{$_}} if $ok;
                }
        }
}

sub ai_mapRoute_searchStep {
        my $r_args = shift;
        my @successors;
        my $r_cur, $r_suc;
        my $i;

        ###check if failed
        if (!@{$$r_args{'openList'}}) {
                #failed!
                $$r_args{'done'} = 1;
                return;
        }

        $r_cur = shift @{$$r_args{'openList'}};

        ###check if finished
        if ($$r_args{'dest'}{'source'}{'map'} eq $$r_cur{'dest'}{'map'}
                && (@{$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$$r_cur{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solution'}}
                || $$r_args{'dest'}{'source'}{'pos'}{'x'} eq "")) {
                do {
                        unshift @{$$r_args{'solutionList'}}, {%{$r_cur}};
                        $r_cur = $$r_cur{'parent'} if (%{$$r_cur{'parent'}});
                } while ($r_cur != \%{$$r_args{'start'}});
                $$r_args{'done'} = 1;
                return;
        }

        ai_mapRoute_getSuccessors($r_args, \@successors, $r_cur);
        if ($$r_args{'waitingForSolution'}) {
                undef $$r_args{'waitingForSolution'};
                unshift @{$$r_args{'openList'}}, $r_cur;
                return;
        }

        $newg = $$r_cur{'g'} + $$r_args{'g_normal'};
        foreach $r_suc (@successors) {
                undef $found;
                undef $openFound;
                undef $closedFound;
                for($i = 0; $i < @{$$r_args{'openList'}}; $i++) {
                        if ($$r_suc{'dest'}{'map'} eq $$r_args{'openList'}[$i]{'dest'}{'map'}
                                && $$r_suc{'dest'}{'pos'}{'x'} == $$r_args{'openList'}[$i]{'dest'}{'pos'}{'x'}
                                && $$r_suc{'dest'}{'pos'}{'y'} == $$r_args{'openList'}[$i]{'dest'}{'pos'}{'y'}) {
                                if ($newg >= $$r_args{'openList'}[$i]{'g'}) {
                                        $found = 1;
                                        }
                                $openFound = $i;
                                last;
                        }
                }
                next if ($found);

                undef $found;
                for($i = 0; $i < @{$$r_args{'closedList'}}; $i++) {
                        if ($$r_suc{'dest'}{'map'} eq $$r_args{'closedList'}[$i]{'dest'}{'map'}
                                && $$r_suc{'dest'}{'pos'}{'x'} == $$r_args{'closedList'}[$i]{'dest'}{'pos'}{'x'}
                                && $$r_suc{'dest'}{'pos'}{'y'} == $$r_args{'closedList'}[$i]{'dest'}{'pos'}{'y'}) {
                                if ($newg >= $$r_args{'closedList'}[$i]{'g'}) {
                                        $found = 1;
                                }
                                $closedFound = $i;
                                last;
                        }
                }
                next if ($found);
                if ($openFound ne "") {
                        binRemoveAndShiftByIndex(\@{$$r_args{'openList'}}, $openFound);
                }
                if ($closedFound ne "") {
                        binRemoveAndShiftByIndex(\@{$$r_args{'closedList'}}, $closedFound);
                }
                $$r_suc{'g'} = $newg;
                $$r_suc{'h'} = 0;
                $$r_suc{'f'} = $$r_suc{'g'} + $$r_suc{'h'};
                $$r_suc{'parent'} = $r_cur;
                minHeapAdd(\@{$$r_args{'openList'}}, $r_suc, "f");
        }
        push @{$$r_args{'closedList'}}, $r_cur;
}

sub ai_items_take {
        my ($x1, $y1, $x2, $y2) = @_;
        my %args;
        $args{'pos'}{'x'} = $x1;
        $args{'pos'}{'y'} = $y1;
        $args{'pos_to'}{'x'} = $x2;
        $args{'pos_to'}{'y'} = $y2;
        $args{'ai_items_take_end'}{'time'} = time;
        $args{'ai_items_take_end'}{'timeout'} = $timeout{'ai_items_take_end'}{'timeout'};
        $args{'ai_items_take_start'}{'time'} = time;
        $args{'ai_items_take_start'}{'timeout'} = $timeout{'ai_items_take_start'}{'timeout'};
        unshift @ai_seq, "items_take";
        unshift @ai_seq_args, \%args;
}

sub ai_route {
        my ($r_ret, $x, $y, $map, $maxRouteDistance, $maxRouteTime, $attackOnRoute, $avoidPortals, $distFromGoal, $checkInnerPortals) = @_;
        my %args;
        $x = int($x) if ($x ne "");
        $y = int($y) if ($y ne "");
        $args{'returnHash'} = $r_ret;
        $args{'dest_x'} = $x;
        $args{'dest_y'} = $y;
        $args{'dest_map'} = $map;
        $args{'maxRouteDistance'} = $maxRouteDistance;
        $args{'maxRouteTime'} = $maxRouteTime;
        $args{'attackOnRoute'} = $attackOnRoute;
        $args{'avoidPortals'} = $avoidPortals;
        $args{'distFromGoal'} = $distFromGoal;
        $args{'checkInnerPortals'} = $checkInnerPortals;
        undef %{$args{'returnHash'}};
        unshift @ai_seq, "route";
        unshift @ai_seq_args, \%args;
        print "On route to: $maps_lut{$map.'.rsw'}($map): $x, $y\n" if $config{'debug'};
}

sub ai_route_getDiagSuccessors {
        my $r_args = shift;
        my $r_pos = shift;
        my $r_array = shift;
        my $type = shift;
        my %pos;

        if (ai_route_getMap($r_args, $$r_pos{'x'}-1, $$r_pos{'y'}-1) == $type
                && !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}-1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}-1)) {
                $pos{'x'} = $$r_pos{'x'}-1;
                $pos{'y'} = $$r_pos{'y'}-1;
                push @{$r_array}, {%pos};
        }

        if (ai_route_getMap($r_args, $$r_pos{'x'}+1, $$r_pos{'y'}-1) == $type
                && !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}+1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}-1)) {
                $pos{'x'} = $$r_pos{'x'}+1;
                $pos{'y'} = $$r_pos{'y'}-1;
                push @{$r_array}, {%pos};
        }

        if (ai_route_getMap($r_args, $$r_pos{'x'}+1, $$r_pos{'y'}+1) == $type
                && !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}+1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}+1)) {
                $pos{'x'} = $$r_pos{'x'}+1;
                $pos{'y'} = $$r_pos{'y'}+1;
                push @{$r_array}, {%pos};
        }


        if (ai_route_getMap($r_args, $$r_pos{'x'}-1, $$r_pos{'y'}+1) == $type
                && !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}-1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}+1)) {
                $pos{'x'} = $$r_pos{'x'}-1;
                $pos{'y'} = $$r_pos{'y'}+1;
                push @{$r_array}, {%pos};
        }
}

sub ai_route_getMap {
        my $r_args = shift;
        my $x = shift;
        my $y = shift;
        if($x < 0 || $x >= $$r_args{'field'}{'width'} || $y < 0 || $y >= $$r_args{'field'}{'height'}) {
                return 1;
        }
        return $$r_args{'field'}{'field'}[($y*$$r_args{'field'}{'width'})+$x];
}

sub ai_route_getRoute {
        my %args;
        my ($returnArray, $r_field, $r_start, $r_dest, $time_giveup) = @_;
        $args{'returnArray'} = $returnArray;
        $args{'field'} = $r_field;
        %{$args{'start'}} = %{$r_start};
        %{$args{'dest'}} = %{$r_dest};
        $args{'time_giveup'}{'timeout'} = $time_giveup;
        $args{'time_giveup'}{'time'} = time;
        $args{'destroyFunction'} = \&ai_route_getRoute_destroy;
        undef @{$args{'returnArray'}};
        unshift @ai_seq, "route_getRoute";
        unshift @ai_seq_args, \%args;
}

sub ai_route_getRoute_destroy {
        my $r_args = shift;
        if (!$config{'buildType'}) {
                $CalcPath_destroy->Call($$r_args{'session'}) if ($$r_args{'session'} ne "");
        } elsif ($config{'buildType'} == 1) {
                &{$CalcPath_destroy}($$r_args{'session'}) if ($$r_args{'session'} ne "");
        }
}
sub ai_route_searchStep {
        my $r_args = shift;
        my $ret;

        if (!$$r_args{'initialized'}) {
                #####
                my $SOLUTION_MAX = 5000;
                $$r_args{'solution'} = "\0" x ($SOLUTION_MAX*4+4);
                #####
                if (!$config{'buildType'}) {
                        $$r_args{'session'} = $CalcPath_init->Call($$r_args{'solution'},
                                $$r_args{'field'}{'rawMap'}, $$r_args{'field'}{'width'}, $$r_args{'field'}{'height'},
                                pack("S*",$$r_args{'start'}{'x'}, $$r_args{'start'}{'y'}), pack("S*",$$r_args{'dest'}{'x'}, $$r_args{'dest'}{'y'}), $$r_args{'timeout'});
                } elsif ($config{'buildType'} == 1) {
                        $$r_args{'session'} = &{$CalcPath_init}($$r_args{'solution'},
                                $$r_args{'field'}{'rawMap'}, $$r_args{'field'}{'width'}, $$r_args{'field'}{'height'},
                                pack("S*",$$r_args{'start'}{'x'}, $$r_args{'start'}{'y'}), pack("S*",$$r_args{'dest'}{'x'}, $$r_args{'dest'}{'y'}), $$r_args{'timeout'});

                }
        }
        if ($$r_args{'session'} < 0) {
                $$r_args{'done'} = 1;
                return;
        }
        $$r_args{'initialized'} = 1;
        if (!$config{'buildType'}) {
                $ret = $CalcPath_pathStep->Call($$r_args{'session'});
        } elsif ($config{'buildType'} == 1) {
                $ret = &{$CalcPath_pathStep}($$r_args{'session'});
        }
        if (!$ret) {
                my $size = unpack("L",substr($$r_args{'solution'},0,4));
                my $j = 0;
                my $i;
                for ($i = ($size-1)*4+4; $i >= 4;$i-=4) {
                        $$r_args{'returnArray'}[$j]{'x'} = unpack("S",substr($$r_args{'solution'}, $i, 2));
                        $$r_args{'returnArray'}[$j]{'y'} = unpack("S",substr($$r_args{'solution'}, $i+2, 2));
                        $j++;
                }
                $$r_args{'done'} = 1;
        }
}

sub ai_route_getSuccessors {
        my $r_args = shift;
        my $r_pos = shift;
        my $r_array = shift;
        my $type = shift;
        my %pos;

        if (ai_route_getMap($r_args, $$r_pos{'x'}-1, $$r_pos{'y'}) == $type
                && !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}-1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'})) {
                $pos{'x'} = $$r_pos{'x'}-1;
                $pos{'y'} = $$r_pos{'y'};
                push @{$r_array}, {%pos};
        }

        if (ai_route_getMap($r_args, $$r_pos{'x'}, $$r_pos{'y'}-1) == $type
                && !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'} && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}-1)) {
                $pos{'x'} = $$r_pos{'x'};
                $pos{'y'} = $$r_pos{'y'}-1;
                push @{$r_array}, {%pos};
        }

        if (ai_route_getMap($r_args, $$r_pos{'x'}+1, $$r_pos{'y'}) == $type
                && !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}+1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'})) {
                $pos{'x'} = $$r_pos{'x'}+1;
                $pos{'y'} = $$r_pos{'y'};
                push @{$r_array}, {%pos};
        }


        if (ai_route_getMap($r_args, $$r_pos{'x'}, $$r_pos{'y'}+1) == $type
                && !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'} && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}+1)) {
                $pos{'x'} = $$r_pos{'x'};
                $pos{'y'} = $$r_pos{'y'}+1;
                push @{$r_array}, {%pos};
        }
}

#sellAuto for items_control - chobit andy 20030210
sub ai_sellAutoCheck {
        for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
                next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'});
                if ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'sell'}
                        && $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}) {
                        return 1;
                }
        }
        if ($config{'cartAuto'} && $config{'cartAutoSell'}) {
                for ($i = 0; $i < @{$cart{'inventory'}};$i++) {
                        next if (!%{$cart{'inventory'}[$i]});
                        if ($items_control{lc($cart{'inventory'}[$i]{'name'})}{'sell'}
                                && $cart{'inventory'}[$i]{'amount'} > $items_control{lc($cart{'inventory'}[$i]{'name'})}{'keep'}) {
                                return 1;
                        }
                }
        }
}

sub ai_setMapChanged {
        my $index = shift;
        $index = 0 if ($index eq "");
        if ($index < @ai_seq_args) {
                $ai_seq_args[$index]{'mapChanged'} = time;
        }
        $ai_v{'portalTrace_mapChanged'} = 1;
}

sub ai_setSuspend {
        my $index = shift;
        $index = 0 if ($index eq "");
        if ($index < @ai_seq_args) {
                $ai_seq_args[$index]{'suspended'} = time;
        }
}

sub ai_skillUse {
        my $ID = shift;
        my $lv = shift;
        my $maxCastTime = shift;
        my $minCastTime = shift;
        my $target = shift;
        my $y = shift;
        my %args;
        $args{'ai_skill_use_giveup'}{'time'} = time;
        $args{'ai_skill_use_giveup'}{'timeout'} = $timeout{'ai_skill_use_giveup'}{'timeout'};
        $args{'skill_use_id'} = $ID;
        $args{'skill_use_lv'} = $lv;
        $args{'skill_use_maxCastTime'}{'time'} = time;
        $args{'skill_use_maxCastTime'}{'timeout'} = $maxCastTime;
        $args{'skill_use_minCastTime'}{'time'} = time;
        $args{'skill_use_minCastTime'}{'timeout'} = $minCastTime;
        if ($y eq "") {
                $args{'skill_use_target'} = $target;
        } else {
                $args{'skill_use_target_x'} = $target;
                $args{'skill_use_target_y'} = $y;
        }
        unshift @ai_seq, "skill_use";
        unshift @ai_seq_args, \%args;
}

#storageAuto for items_control - chobit andy 20030210
sub ai_storageAutoCheck {
        for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
                next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'});
                if ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'storage'}
                        && $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}) {
                        return 1;
                }
        }
        if ($config{'cartAuto'} && $config{'cartAutoStorage'}) {
                for ($i = 0; $i < @{$cart{'inventory'}};$i++) {
                        next if (!%{$cart{'inventory'}[$i]});
                        if ($items_control{lc($cart{'inventory'}[$i]{'name'})}{'storage'}
                                && $cart{'inventory'}[$i]{'amount'} > $items_control{lc($cart{'inventory'}[$i]{'name'})}{'keep'}) {
                                return 1;
                        }
                }
        }
}

sub attack {
        my $ID = shift;
        my %args;
        $args{'ai_attack_giveup'}{'time'} = time;
        $args{'ai_attack_start'}{'time'} = time;
        $args{'ai_attack_giveup'}{'timeout'} = $timeout{'ai_attack_giveup'}{'timeout'};
        $args{'ID'} = $ID;
        %{$args{'pos_to'}} = %{$monsters{$ID}{'pos_to'}};
        %{$args{'pos'}} = %{$monsters{$ID}{'pos'}};
        my $dMDist = int(char_distance(\%{$monsters{$ID}}));
        unshift @ai_seq, "attack";
        unshift @ai_seq_args, \%args;
        printC("I0W", "目标: $monsters{$ID}{'name'}($monsters{$ID}{'binID'}) 距离: $dMDist\n");
        sendWindowsMessage("AA00".chr(1)."目标：$monsters{$ID}{'name'}($monsters{$ID}{'binID'}) 距离：$dMDist") if ($yelloweasy);
        switchEquipment("a", $ID) if ($swtichAuto{'autoSwitch'});
}

sub aiRemove {
        my $ai_type = shift;
        my $index;
        while (1) {
                $index = binFind(\@ai_seq, $ai_type);
                if ($index ne "") {
                        if ($ai_seq_args[$index]{'destroyFunction'}) {
                                &{$ai_seq_args[$index]{'destroyFunction'}}(\%{$ai_seq_args[$index]});
                        }
                        binRemoveAndShiftByIndex(\@ai_seq, $index);
                        binRemoveAndShiftByIndex(\@ai_seq_args, $index);
                } else {
                        last;
                }
        }
}


sub gather {
        my $ID = shift;
        my %args;
        $args{'ai_items_gather_giveup'}{'time'} = time;
        $args{'ai_items_gather_giveup'}{'timeout'} = $timeout{'ai_items_gather_giveup'}{'timeout'};
        $args{'ID'} = $ID;
        %{$args{'pos'}} = %{$items{$ID}{'pos'}};
        unshift @ai_seq, "items_gather";
        unshift @ai_seq_args, \%args;
        print "Targeting for Gather: $items{$ID}{'name'}($items{$ID}{'binID'})\n" if $config{'debug'};
}


sub look {
        my $body = shift;
        my $head = shift;
        my %args;
        unshift @ai_seq, "look";
        $args{'look_body'} = $body;
        $args{'look_head'} = $head;
        unshift @ai_seq_args, \%args;
}

sub move {
        my $x = shift;
        my $y = shift;
        my %args;
        $args{'move_to'}{'x'} = $x;
        $args{'move_to'}{'y'} = $y;
        $args{'ai_move_giveup'}{'time'} = time;
        $args{'ai_move_giveup'}{'timeout'} = $timeout{'ai_move_giveup'}{'timeout'};
        unshift @ai_seq, "move";
        unshift @ai_seq_args, \%args;
}

sub quit {
        $quit = 1;
        printC("S0", "退出游戏...\n");
}

sub relog {
        $conState = 1;
        undef $conState_tries;
        printC("S0", "重新启动\n");
}

sub sendMessage {
        my $r_socket = shift;
        my $type = shift;
        my $msg = shift;
        my $user = shift;
        my $i, $j;
        my @msg;
        my @msgs;
        my $oldmsg;
        my $amount;
        my $space;
        @msgs = split /\\n/,$msg;
        for ($j = 0; $j < @msgs; $j++) {
        @msg = split / /, $msgs[$j];
        undef $msg;
        for ($i = 0; $i < @msg; $i++) {
                if (!length($msg[$i])) {
                        $msg[$i] = " ";
                        $space = 1;
                }
                if (length($msg[$i]) > $config{'message_length_max'}) {
                        while (length($msg[$i]) >= $config{'message_length_max'}) {
                                $oldmsg = $msg;
                                if (length($msg)) {
                                        $amount = $config{'message_length_max'};
                                        if ($amount - length($msg) > 0) {
                                                $amount = $config{'message_length_max'} - 1;
                                                $msg .= " " . substr($msg[$i], 0, $amount - length($msg));
                                        }
                                } else {
                                        $amount = $config{'message_length_max'};
                                        $msg .= substr($msg[$i], 0, $amount);
                                }
                                if ($type eq "c") {
                                        sendChat($r_socket, $msg);
                                } elsif ($type eq "g") {
                                        sendGuildChat($r_socket, $msg);
                                } elsif ($type eq "p") {
                                        sendPartyChat($r_socket, $msg);
                                } elsif ($type eq "pm") {
                                        sendPrivateMsg($r_socket, $user, $msg);
                                        undef %lastpm;
                                        $lastpm{'msg'} = $msg;
                                        $lastpm{'user'} = $user;
                                        push @lastpm, {%lastpm};
                                }
                                $msg[$i] = substr($msg[$i], $amount - length($oldmsg), length($msg[$i]) - $amount - length($oldmsg));
                                undef $msg;
                        }
                }
                if (length($msg[$i]) && length($msg) + length($msg[$i]) <= $config{'message_length_max'}) {
                        if (length($msg)) {
                                if (!$space) {
                                        $msg .= " " . $msg[$i];
                                } else {
                                        $space = 0;
                                        $msg .= $msg[$i];
                                }
                        } else {
                                $msg .= $msg[$i];
                        }
                } else {
                        if ($type eq "c") {
                                sendChat($r_socket, $msg);
                        } elsif ($type eq "g") {
                                sendGuildChat($r_socket, $msg);
                        } elsif ($type eq "p") {
                                sendPartyChat($r_socket, $msg);
                        } elsif ($type eq "pm") {
                                sendPrivateMsg($r_socket, $user, $msg);
                                undef %lastpm;
                                $lastpm{'msg'} = $msg;
                                $lastpm{'user'} = $user;
                                push @lastpm, {%lastpm};
                        }
                        $msg = $msg[$i];
                }
                if (length($msg) && $i == @msg - 1) {
                        if ($type eq "c") {
                                sendChat($r_socket, $msg);
                        } elsif ($type eq "g") {
                                sendGuildChat($r_socket, $msg);
                        } elsif ($type eq "p") {
                                sendPartyChat($r_socket, $msg);
                        } elsif ($type eq "pm") {
                                sendPrivateMsg($r_socket, $user, $msg);
                                undef %lastpm;
                                $lastpm{'msg'} = $msg;
                                $lastpm{'user'} = $user;
                                push @lastpm, {%lastpm};
                        }
                }
        }
        }
}

sub sit {
        $timeout{'ai_sit_wait'}{'time'} = time;
        unshift @ai_seq, "sitting";
        unshift @ai_seq_args, {};
}

sub stand {
        unshift @ai_seq, "standing";
        unshift @ai_seq_args, {};
}

sub take {
        my $ID = shift;
        my %args;
        $args{'ai_take_giveup'}{'time'} = time;
        $args{'ai_take_giveup'}{'timeout'} = $timeout{'ai_take_giveup'}{'timeout'};
        $args{'ID'} = $ID;
        %{$args{'pos'}} = %{$items{$ID}{'pos'}};
        unshift @ai_seq, "take";
        unshift @ai_seq_args, \%args;
        print "Targeting for Pickup: $items{$ID}{'name'}($items{$ID}{'binID'})\n" if $config{'debug'};
}

# ICE Start - Teleport
sub useTeleport {
        my $level = shift;
        if ($chars[$config{'char'}]{'state'} eq $msgstrings_lut{'0119'}{'A1'} || $chars[$config{'char'}]{'state'} eq $msgstrings_lut{'0119'}{'A2'} || $chars[$config{'char'}]{'state'} eq $msgstrings_lut{'0119'}{'A3'} || $chars[$config{'char'}]{'state'} eq $msgstrings_lut{'0119'}{'A4'} || $chars[$config{'char'}]{'state'} eq $msgstrings_lut{'0119'}{'A6'}) {
                printC("I0R", "$chars[$config{'char'}]{'state'}禁止瞬移\n");
                return;
        } elsif ($ai_seq[0] ne "flyMap" && $indoor_lut{$field{'name'}.'.rsw'}) {
                printC("I0R", "此地图禁止瞬移\n");
                return;
        }
        my $invIndex;
        my $accIndex = ai_findIndexAutoSwitch($config{'accessoryTeleport'}) if ($config{'accessoryTeleport'} ne "");
        aiRemove("attack");
        aiRemove("skill_use");
        $timeout{'ai_attack'}{'time'} = time + 2;
        $timeout{'ai_attack_auto'}{'time'} = time + 2;
        $timeout{'ai_skill_use'}{'time'} = time + 2;
        $timeout{'ai_item_use_auto'}{'time'} = time + 2;
        if ($level == 1) {
                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 601) if ($level == 1);
        } elsif ($level == 2) {
                $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 602) if ($level == 2);
        }
        if ($config{'saveMap_warpToFly'} && $config{'saveMap'} && $level == 2 && $mapserver_lut{$config{'saveMap'}.'.rsw'} && $mapip_lut{$config{'saveMap'}}{'ip'} ne "" && $mapip_lut{$config{'saveMap'}}{'port'} ne ""
                && $mapip_lut{$field{'name'}.'.rsw'}{'ip'} ne "" && $mapip_lut{$field{'name'}.'.rsw'}{'port'} ne "" && ($mapip_lut{$config{'saveMap'}.'.rsw'}{'ip'} ne $mapip_lut{$field{'name'}.'.rsw'}{'ip'} || ($mapip_lut{$config{'saveMap'}.'.rsw'}{'ip'} eq $mapip_lut{$field{'name'}.'.rsw'}{'ip'} && $mapip_lut{$config{'saveMap'}.'.rsw'}{'port'} ne $mapip_lut{$field{'name'}.'.rsw'}{'port'}))) {
                printC("S0W", "正在转移到: $mapip_lut{$config{'saveMap'}.'.rsw'}{'name'}($config{'saveMap'})\n");
                sendFly($mapip_lut{$config{'saveMap'}.'.rsw'}{'ip'}, $mapip_lut{$config{'saveMap'}.'.rsw'}{'port'});
        } elsif ($accIndex ne "") {
                ai_sendEquip($accIndex,"");
                sendTeleport(\$remote_socket, "Random") if ($level == 1);
                sendTeleport(\$remote_socket, $config{'saveMap'}.".gat") if ($level == 2);
                $chars[$config{'char'}]{'teleport'} = 1;
        } elsif ($chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} >= 1) {
                sendTeleport(\$remote_socket, "Random") if ($level == 1);
                sendTeleport(\$remote_socket, $config{'saveMap'}.".gat") if ($level == 2);
        } elsif ($invIndex ne "") {
                sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}, $accountID);
        } else {
                print "Can't teleport or respawn - need wing or skill\n" if $config{'debug'};
        }
}
# -End-




#######################################
#######################################
#AI MATH
#######################################
#######################################


sub distance {
        my $r_hash1 = shift;
        my $r_hash2 = shift;
        my %line;
        if ($r_hash2) {
                $line{'x'} = abs($$r_hash1{'x'} - $$r_hash2{'x'});
                $line{'y'} = abs($$r_hash1{'y'} - $$r_hash2{'y'});
        } else {
                %line = %{$r_hash1};
        }
        return sqrt($line{'x'} ** 2 + $line{'y'} ** 2);
}

sub getVector {
        my $r_store = shift;
        my $r_head = shift;
        my $r_tail = shift;
        $$r_store{'x'} = $$r_head{'x'} - $$r_tail{'x'};
        $$r_store{'y'} = $$r_head{'y'} - $$r_tail{'y'};
}

sub lineIntersection {
        my $r_pos1 = shift;
        my $r_pos2 = shift;
        my $r_pos3 = shift;
        my $r_pos4 = shift;
        my $x1, $x2, $x3, $x4, $y1, $y2, $y3, $y4, $result, $result1, $result2;
        $x1 = $$r_pos1{'x'};
        $y1 = $$r_pos1{'y'};
        $x2 = $$r_pos2{'x'};
        $y2 = $$r_pos2{'y'};
        $x3 = $$r_pos3{'x'};
        $y3 = $$r_pos3{'y'};
        $x4 = $$r_pos4{'x'};
        $y4 = $$r_pos4{'y'};
        $result1 = ($x4 - $x3)*($y1 - $y3) - ($y4 - $y3)*($x1 - $x3);
        $result2 = ($y4 - $y3)*($x2 - $x1) - ($x4 - $x3)*($y2 - $y1);
        if ($result2 != 0) {
                $result = $result1 / $result2;
        }
        return $result;
}


sub moveAlongVector {
        my $r_store = shift;
        my $r_pos = shift;
        my $r_vec = shift;
        my $amount = shift;
        my %norm;
        if ($amount) {
                normalize(\%norm, $r_vec);
                $$r_store{'x'} = $$r_pos{'x'} + $norm{'x'} * $amount;
                $$r_store{'y'} = $$r_pos{'y'} + $norm{'y'} * $amount;
        } else {
                $$r_store{'x'} = $$r_pos{'x'} + $$r_vec{'x'};
                $$r_store{'y'} = $$r_pos{'y'} + $$r_vec{'y'};
        }
}

sub normalize {
        my $r_store = shift;
        my $r_vec = shift;
        my $dist;
        $dist = distance($r_vec);
        if ($dist > 0) {
                $$r_store{'x'} = $$r_vec{'x'} / $dist;
                $$r_store{'y'} = $$r_vec{'y'} / $dist;
        } else {
                $$r_store{'x'} = 0;
                $$r_store{'y'} = 0;
        }
}

sub percent_hp {
        my $r_hash = shift;
        if (!$$r_hash{'hp_max'}) {
                return 0;
        } else {
                return ($$r_hash{'hp'} / $$r_hash{'hp_max'} * 100);
        }
}

sub percent_sp {
        my $r_hash = shift;
        if (!$$r_hash{'sp_max'}) {
                return 0;
        } else {
                return ($$r_hash{'sp'} / $$r_hash{'sp_max'} * 100);
        }
}

sub percent_weight {
        my $r_hash = shift;
        if (!$$r_hash{'weight_max'}) {
                return 0;
        } else {
                return ($$r_hash{'weight'} / $$r_hash{'weight_max'} * 100);
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
        writeDataFile("data/overallAuth.txt", \%overallAuth);
}

sub configModify {
        my $key = shift;
        my $val = shift;
        print "Config '$key' set to $val\n";
        $config{$key} = $val;
        writeDataFileIntact("$setupPath/config.txt", \%config) if (!$chars[$config{'char'}]{'mvp'});
}

sub setTimeout {
        my $timeout = shift;
        my $time = shift;
        $timeout{$timeout}{'timeout'} = $time;
        print "Timeout '$timeout' set to $time\n";
        writeDataFileIntact2("$setupPath/timeouts.txt", \%timeout);
}


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
        my $r_socket = shift;
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
        $$r_socket->send($newmsg) if $$r_socket && $$r_socket->connected();
}

sub sendAddSkillPoint {
        my $r_socket = shift;
        my $skillID = shift;
        my $msg = pack("C*", 0x12, 0x01) . pack("S*", $skillID);
        encrypt($r_socket, $msg);
}

sub sendAddStatusPoint {
        my $r_socket = shift;
        my $statusID = shift;
        my $msg = pack("C*", 0xBB, 0) . pack("S*", $statusID) . pack("C*", 0x01);
        encrypt($r_socket, $msg);
}

sub sendAlignment {
        my $r_socket = shift;
        my $ID = shift;
        my $alignment = shift;
        my $msg = pack("C*", 0x49, 0x01) . $ID . pack("C*", $alignment);
        encrypt($r_socket, $msg);
        print "Sent Alignment: ".getHex($ID).", $alignment\n" if ($config{'debug'} >= 2);
}

sub sendAttack {
        my $r_socket = shift;
        my $monID = shift;
        my $flag = shift;
        my $msg = pack("C*", 0x89, 0x00) . $monID . pack("C*", $flag);
        encrypt($r_socket, $msg);
        print "Sent attack: ".getHex($monID)."\n" if ($config{'debug'} >= 2);
}

sub sendAttackStop {
        my $r_socket = shift;
        my $msg = pack("C*", 0x18, 0x01);
        encrypt($r_socket, $msg);
        print "Sent stop attack\n" if $config{'debug'};
}

sub sendBuy {
        my $r_socket = shift;
        my $ID = shift;
        my $amount = shift;
        my $msg = pack("C*", 0xC8, 0x00, 0x08, 0x00) . pack("S*", $amount, $ID);
        encrypt($r_socket, $msg);
        print "Sent buy: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendCartAdd {
        my $r_socket = shift;
        my $index = shift;
        my $amount = shift;
        my $msg = pack("C*", 0x26, 0x01) . pack("S*", $index) . pack("L*", $amount);
        encrypt($r_socket, $msg);
        print "Sent Cart Add: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendCartGet {
        my $r_socket = shift;
        my $index = shift;
        my $amount = shift;
        my $msg = pack("C*", 0x27, 0x01) . pack("S*", $index) . pack("L*", $amount);
        encrypt($r_socket, $msg);
        print "Sent Cart Get: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendCharLogin {
        my $r_socket = shift;
        my $char = shift;
        my $msg = pack("C*", 0x66,0) . pack("C*",$char);
        encrypt($r_socket, $msg);
}

sub sendChat {
        my $r_socket = shift;
        my $message = shift;
        my $msg = pack("C*",0x8C, 0x00) . pack("S*", length($chars[$config{'char'}]{'name'}) + length($message) + 8) .
                $chars[$config{'char'}]{'name'} . " : " . $message . chr(0);
        encrypt($r_socket, $msg);
}

sub sendChatRoomBestow {
        my $r_socket = shift;
        my $name = shift;
        $name = substr($name, 0, 24) if (length($name) > 24);
        $name = $name . chr(0) x (24 - length($name));
        my $msg = pack("C*", 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00).$name;
        encrypt($r_socket, $msg);
        print "Sent Chat Room Bestow: $name\n" if ($config{'debug'} >= 2);
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
        encrypt($r_socket, $msg);
        print "Sent Change Chat Room: $title, $limit, $public, $password\n" if ($config{'debug'} >= 2);
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
        encrypt($r_socket, $msg);
        print "Sent Create Chat Room: $title, $limit, $public, $password\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomJoin {
        my $r_socket = shift;
        my $ID = shift;
        my $password = shift;
        $password = substr($password, 0, 8) if (length($password) > 8);
        $password = $password . chr(0) x (8 - length($password));
        my $msg = pack("C*", 0xD9, 0x00).$ID.$password;
        encrypt($r_socket, $msg);
        print "Sent Join Chat Room: ".getHex($ID)." $password\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomKick {
        my $r_socket = shift;
        my $name = shift;
        $name = substr($name, 0, 24) if (length($name) > 24);
        $name = $name . chr(0) x (24 - length($name));
        my $msg = pack("C*", 0xE2, 0x00).$name;
        encrypt($r_socket, $msg);
        print "Sent Chat Room Kick: $name\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomLeave {
        my $r_socket = shift;
        my $msg = pack("C*", 0xE3, 0x00);
        encrypt($r_socket, $msg);
        print "Sent Leave Chat Room\n" if ($config{'debug'} >= 2);
}

sub sendCurrentDealCancel {
        my $r_socket = shift;
        my $msg = pack("C*", 0xED, 0x00);
        encrypt($r_socket, $msg);
        print "Sent Cancel Current Deal\n" if ($config{'debug'} >= 2);
}

sub sendDeal {
        my $r_socket = shift;
        my $ID = shift;
        my $msg = pack("C*", 0xE4, 0x00) . $ID;
        encrypt($r_socket, $msg);
        print "Sent Initiate Deal: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendDealAccept {
        my $r_socket = shift;
        my $msg = pack("C*", 0xE6, 0x00, 0x03);
        encrypt($r_socket, $msg);
        print "Sent Accept Deal\n" if ($config{'debug'} >= 2);
}

sub sendDealAddItem {
        my $r_socket = shift;
        my $index = shift;
        my $amount = shift;
        my $msg = pack("C*", 0xE8, 0x00) . pack("S*", $index) . pack("L*",$amount);
        encrypt($r_socket, $msg);
        print "Sent Deal Add Item: $index, $amount\n" if ($config{'debug'} >= 2);
}

sub sendDealCancel {
        my $r_socket = shift;
        my $msg = pack("C*", 0xE6, 0x00, 0x04);
        encrypt($r_socket, $msg);
        print "Sent Cancel Deal\n" if ($config{'debug'} >= 2);
}

sub sendDealFinalize {
        my $r_socket = shift;
        my $msg = pack("C*", 0xEB, 0x00);
        encrypt($r_socket, $msg);
        print "Sent Deal OK\n" if ($config{'debug'} >= 2);
}

sub sendDealOK {
        my $r_socket = shift;
        my $msg = pack("C*", 0xEB, 0x00);
        encrypt($r_socket, $msg);
        print "Sent Deal OK\n" if ($config{'debug'} >= 2);
}

sub sendDealTrade {
        my $r_socket = shift;
        my $msg = pack("C*", 0xEF, 0x00);
        encrypt($r_socket, $msg);
        print "Sent Deal Trade\n" if ($config{'debug'} >= 2);
}

sub sendDrop {
        my $r_socket = shift;
        my $index = shift;
        my $amount = shift;
        my $msg = pack("C*", 0xA2, 0x00) . pack("S*", $index, $amount);
        encrypt($r_socket, $msg);
        print "Sent drop: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendEmotion {
        my $r_socket = shift;
        my $ID = shift;
        my $msg = pack("C*", 0xBF, 0x00).pack("C1",$ID);
        encrypt($r_socket, $msg);
        print "Sent Emotion\n" if ($config{'debug'} >= 2);
}

sub sendEquip{
        my $r_socket = shift;
        my $index = shift;
        my $type = shift;
        my $masktype = shift;
        my $msg = pack("C*", 0xA9, 0x00) . pack("S*", $index) .  pack("C*", $type, $masktype);
        encrypt($r_socket, $msg);
        print "Sent Equip: $index\n" if ($config{'debug'} >= 2);
}

sub sendGameLogin {
        my $r_socket = shift;
        my $accountID = shift;
        my $sessionID = shift;
        my $sex = shift;
        my $msg = pack("C*", 0x65,0) . $accountID . $sessionID . pack("C*", 0,0,0,0,0,0,$sex);
        encrypt($r_socket, $msg);
}

sub sendGetPlayerInfo {
        my $r_socket = shift;
        my $ID = shift;
        my $msg = pack("C*", 0x94, 0x00) . $ID;
        encrypt($r_socket, $msg);
        print "Sent get player info: ID - ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendGetStoreList {
        my $r_socket = shift;
        my $ID = shift;
        my $msg = pack("C*", 0xC5, 0x00) . $ID . pack("C*",0x00);
        encrypt($r_socket, $msg);
        print "Sent get store list: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendGetSellList {
        my $r_socket = shift;
        my $ID = shift;
        my $msg = pack("C*", 0xC5, 0x00) . $ID . pack("C*",0x01);
        encrypt($r_socket, $msg);
        print "Sent sell to NPC: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendGuildChat {
        my $r_socket = shift;
        my $message = shift;
        my $msg = pack("C*",0x7E, 0x01) . pack("S*",length($chars[$config{'char'}]{'name'}) + length($message) + 8) .
        $chars[$config{'char'}]{'name'} . " : " . $message . chr(0);
        encrypt($r_socket, $msg);
}

sub sendIdentify {
        my $r_socket = shift;
        my $index = shift;
        my $msg = pack("C*", 0x78, 0x01) . pack("S*", $index);
        encrypt($r_socket, $msg);
        print "Sent Identify: $index\n" if ($config{'debug'} >= 2);
}

sub sendIgnore {
        my $r_socket = shift;
        my $name = shift;
        my $flag = shift;
        $name = substr($name, 0, 24) if (length($name) > 24);
        $name = $name . chr(0) x (24 - length($name));
        my $msg = pack("C*", 0xCF, 0x00).$name.pack("C*", $flag);
        encrypt($r_socket, $msg);
        print "Sent Ignore: $name, $flag\n" if ($config{'debug'} >= 2);
}

sub sendIgnoreAll {
        my $r_socket = shift;
        my $flag = shift;
        my $msg = pack("C*", 0xD0, 0x00).pack("C*", $flag);
        encrypt($r_socket, $msg);
        print "Sent Ignore All: $flag\n" if ($config{'debug'} >= 2);
}

#sendGetIgnoreList - chobit 20021223
sub sendIgnoreListGet {
        my $r_socket = shift;
        my $flag = shift;
        my $msg = pack("C*", 0xD3, 0x00);
        encrypt($r_socket, $msg);
        print "Sent get Ignore List: $flag\n" if ($config{'debug'} >= 2);
}

sub sendItemUse {
        my $r_socket = shift;
        my $ID = shift;
        my $targetID = shift;
        my $msg = pack("C*", 0xA7, 0x00).pack("S*",$ID).$targetID;
        encrypt($r_socket, $msg);
        print "Item Use: $ID\n" if ($config{'debug'} >= 2);
}


sub sendLook {
        my $r_socket = shift;
        my $body = shift;
        my $head = shift;
        my $msg = pack("C*", 0x9B, 0x00, $head, 0x00, $body);
        encrypt($r_socket, $msg);
        print "Sent look: $body $head\n" if ($config{'debug'} >= 2);
        $chars[$config{'char'}]{'look'}{'head'} = $head;
        $chars[$config{'char'}]{'look'}{'body'} = $body;
}

sub sendMapLoaded {
        my $r_socket = shift;
        my $msg = pack("C*", 0x7D,0x00);
        print "Sending Map Loaded\n" if $config{'debug'};
        encrypt($r_socket, $msg);
}

sub sendMapLogin {
        my $r_socket = shift;
        my $accountID = shift;
        my $charID = shift;
        my $sessionID = shift;
        my $sex = shift;
        my $msg = pack("C*", 0x72,0) . $accountID . $charID . $sessionID . pack("L1", getTickCount()) . pack("C*",$sex);
        encrypt($r_socket, $msg);
}

sub sendMasterLogin {
        my $r_socket = shift;
        my $username = shift;
        my $password = shift;
        my $msg = pack("C*", 0x64,0,$config{'version'},0,0,0) . $username . chr(0) x (24 - length($username)) .
                        $password . chr(0) x (24 - length($password)) . pack("C*", $config{"master_version_$config{'master'}"});
        encrypt($r_socket, $msg);
}

sub sendMemo {
        my $r_socket = shift;
        my $msg = pack("C*", 0x1D, 0x01);
        encrypt($r_socket, $msg);
        print "Sent Memo\n" if ($config{'debug'} >= 2);
}

sub sendMove {
        my $r_socket = shift;
        my $x = shift;
        my $y = shift;
        my $msg = pack("C*", 0x85, 0x00) . getCoordString($x, $y);
        encrypt($r_socket, $msg);
        print "Sent move to: $x, $y\n" if ($config{'debug'} >= 2);
}

sub sendPartyChat {
        my $r_socket = shift;
        my $message = shift;
        my $msg = pack("C*",0x08, 0x01) . pack("S*",length($chars[$config{'char'}]{'name'}) + length($message) + 8) .
                $chars[$config{'char'}]{'name'} . " : " . $message . chr(0);
        encrypt($r_socket, $msg);
}

sub sendPartyJoin {
        my $r_socket = shift;
        my $ID = shift;
        my $flag = shift;
        my $msg = pack("C*", 0xFF, 0x00).$ID.pack("L", $flag);
        encrypt($r_socket, $msg);
        print "Sent Join Party: ".getHex($ID).", $flag\n" if ($config{'debug'} >= 2);
}

sub sendPartyJoinRequest {
        my $r_socket = shift;
        my $ID = shift;
        my $msg = pack("C*", 0xFC, 0x00).$ID;
        encrypt($r_socket, $msg);
        print "Sent Request Join Party: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendPartyKick {
        my $r_socket = shift;
        my $ID = shift;
        my $name = shift;
        $name = substr($name, 0, 24) if (length($name) > 24);
        $name = $name . chr(0) x (24 - length($name));
        my $msg = pack("C*", 0x03, 0x01).$ID.$name;
        encrypt($r_socket, $msg);
        print "Sent Kick Party: ".getHex($ID).", $name\n" if ($config{'debug'} >= 2);
}

sub sendPartyLeave {
        my $r_socket = shift;
        my $msg = pack("C*", 0x00, 0x01);
        encrypt($r_socket, $msg);
        print "Sent Leave Party: $name\n" if ($config{'debug'} >= 2);
}

sub sendPartyOrganize {
        my $r_socket = shift;
        my $name = shift;
        $name = substr($name, 0, 24) if (length($name) > 24);
        $name = $name . chr(0) x (24 - length($name));
        my $msg = pack("C*", 0xF9, 0x00).$name;
        encrypt($r_socket, $msg);
        print "Sent Organize Party: $name\n" if ($config{'debug'} >= 2);
}

sub sendPartyShareEXP {
        my $r_socket = shift;
        my $flag = shift;
        my $msg = pack("C*", 0x02, 0x01).pack("L", $flag);
        encrypt($r_socket, $msg);
        print "Sent Party Share: $flag\n" if ($config{'debug'} >= 2);
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
        encrypt($r_socket, $msg);
        print "Sent Raw Packet: @raw\n" if ($config{'debug'} >= 2);
}

sub sendRespawn {
        my $r_socket = shift;
        my $msg = pack("C*", 0xB2, 0x00, 0x00);
        encrypt($r_socket, $msg);
        print "Sent Respawn\n" if ($config{'debug'} >= 2);
}

sub sendPrivateMsg {
        my $r_socket = shift;
        my $user = shift;
        my $message = shift;
        my $msg = pack("C*",0x96, 0x00) . pack("S*",length($message) + 29) . $user . chr(0) x (24 - length($user)) .
                        $message . chr(0);
        encrypt($r_socket, $msg);
}

sub sendSell {
        my $r_socket = shift;
        my $index = shift;
        my $amount = shift;
        my $msg = pack("C*", 0xC9, 0x00, 0x08, 0x00) . pack("S*", $index, $amount);
        encrypt($r_socket, $msg);
        print "Sent sell: $index x $amount\n" if ($config{'debug'} >= 2);

}

sub sendSit {
        my $r_socket = shift;
        my $msg = pack("C*", 0x89,0x00, 0x00, 0x00, 0x00, 0x00, 0x02);
        encrypt($r_socket, $msg);
        print "Sitting\n" if ($config{'debug'} >= 2);
}

sub sendSkillUse {
        my $r_socket = shift;
        my $ID = shift;
        my $lv = shift;
        my $targetID = shift;
        my $msg = pack("C*", 0x13, 0x01).pack("S*",$lv,$ID).$targetID;
        encrypt($r_socket, $msg);
        print "Skill Use: $ID\n" if ($config{'debug'} >= 2);
}

sub sendSkillUseLoc {
        my $r_socket = shift;
        my $ID = shift;
        my $lv = shift;
        my $x = shift;
        my $y = shift;
        my $msg = pack("C*", 0x16, 0x01).pack("S*",$lv,$ID,$x,$y);
        encrypt($r_socket, $msg);
        print "Skill Use Loc: $ID\n" if ($config{'debug'} >= 2);
}

sub sendStorageAdd {
        my $r_socket = shift;
        my $index = shift;
        my $amount = shift;
        my $msg = pack("C*", 0xF3, 0x00) . pack("S*", $index) . pack("L*", $amount);
        encrypt($r_socket, $msg);
        print "Sent Storage Add: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendStorageClose {
        my $r_socket = shift;
        my $msg = pack("C*", 0xF7, 0x00);
        encrypt($r_socket, $msg);
        print "Sent Storage Done\n" if ($config{'debug'} >= 2);
}

sub sendStorageGet {
        my $r_socket = shift;
        my $index = shift;
        my $amount = shift;
        my $msg = pack("C*", 0xF5, 0x00) . pack("S*", $index) . pack("L*", $amount);
        encrypt($r_socket, $msg);
        print "Sent Storage Get: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendStand {
        my $r_socket = shift;
        my $msg = pack("C*", 0x89,0x00, 0x00, 0x00, 0x00, 0x00, 0x03);
        encrypt($r_socket, $msg);
        print "Standing\n" if ($config{'debug'} >= 2);
}

sub sendSync {
        my $r_socket = shift;
        my $time = shift;
        my $msg = pack("C*", 0x7E, 0x00) . pack("L1", $time);
        encrypt($r_socket, $msg);
        print "Sent Sync: $time\n" if ($config{'debug'} >= 2);
}

sub sendTake {
        my $r_socket = shift;
        my $itemID = shift;
        my $msg = pack("C*", 0x9F, 0x00) . $itemID;
        encrypt($r_socket, $msg);
        print "Sent take\n" if ($config{'debug'} >= 2);
}

sub sendTalk {
        my $r_socket = shift;
        my $ID = shift;
        $ID = ai_getTalkID($ID);
        my $msg = pack("C*", 0x90, 0x00) . $ID . pack("C*",0x01);
        encrypt($r_socket, $msg);
        print "Sent talk: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendTalkCancel {
        my $r_socket = shift;
        my $ID = shift;
        $ID = ai_getTalkID($ID);
        my $msg = pack("C*", 0x46, 0x01) . $ID;
        encrypt($r_socket, $msg);
        print "Sent talk cancel: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendTalkContinue {
        my $r_socket = shift;
        my $ID = shift;
        $ID = ai_getTalkID($ID);
        my $msg = pack("C*", 0xB9, 0x00) . $ID;
        encrypt($r_socket, $msg);
        print "Sent talk continue: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendTalkResponse {
        my $r_socket = shift;
        my $ID = shift;
        $ID = ai_getTalkID($ID);
        my $response = shift;
        my $msg = pack("C*", 0xB8, 0x00) . $ID. pack("C1",$response);
        encrypt($r_socket, $msg);
        print "Sent talk respond: ".getHex($ID).", $response\n" if ($config{'debug'} >= 2);
}

sub sendTeleport {
        my $r_socket = shift;
        my $location = shift;
        $location = substr($location, 0, 16) if (length($location) > 16);
        $location .= chr(0) x (16 - length($location));
        my $msg = pack("C*", 0x1B, 0x01, 0x1A, 0x00) . $location;
        encrypt($r_socket, $msg);
        print "Sent Teleport: $location\n" if ($config{'debug'} >= 2);
}

sub sendUnequip{
        my $r_socket = shift;
        my $index = shift;
        my $msg = pack("C*", 0xAB, 0x00) . pack("S*", $index);
        encrypt($r_socket, $msg);
        print "Sent Unequip: $index\n" if ($config{'debug'} >= 2);
}

sub sendWho {
        my $r_socket = shift;
        my $msg = pack("C*", 0xC1, 0x00);
        encrypt($r_socket, $msg);
        print "Sent Who\n" if ($config{'debug'} >= 2);
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
        printC("S0", "正在连接 ($host:$port)... ");
        $$r_socket = IO::Socket::INET->new(
                        PeerAddr        => $host,
                        PeerPort        => $port,
                        Proto                => 'tcp',
                        Timeout                => 4);
        ($$r_socket && inet_aton($$r_socket->peerhost()) eq inet_aton($host)) ? print "已连接\n" : print "无法连接\n";
}

sub dataWaiting {
        my $r_fh = shift;
        my $bits;
        vec($bits,fileno($$r_fh),1)=1;
        return (select($bits,$bits,$bits,0.05) > 1);
}

sub input_client {
        my ($input, $switch);
        my $msg;
        my $local_socket;
        my ($addrcheck, $portcheck, $hostcheck);
        printC("S0", "正在建立本地连接...\n");
        my $pid = fork;
        if ($pid == 0) {
                $local_socket = IO::Socket::INET->new(
                                PeerAddr        => $config{'local_host'},
                                PeerPort        => $config{'local_port'},
                                Proto                => 'tcp',
                                Timeout                => 4);
                ($local_socket) || die "本地连接建立失败: $!";
                while (1) {
                        $input = <STDIN>;
                        chomp $input;
                        ($switch) = $input =~ /^(\w*)/;
                        if ($input ne "") {
                                $local_socket->send($input);
                        }
                        last if ($input eq "quit" || $input eq "dump");
                }
                close($local_socket);
                exit;
        } else {
                $input_socket = $server_socket->accept();
                (inet_aton($input_socket->peerhost()) == inet_aton($config{'local_host'}))
                || die "本地连接建立失败";
                printC("S0", "本地连接建立成功\n");
                return $pid;
        }
}

sub killConnection {
        my $r_socket = shift;
        if ($$r_socket && $$r_socket->connected()) {
                printC("S0", "正在关闭连接 (".$$r_socket->peerhost().":".$$r_socket->peerport().")... ");
                close($$r_socket);
                !$$r_socket->connected() ? print "断开连接\n" : print "无法断开\n";
        }
}





#######################################
#######################################
#FILE PARSING AND WRITING
#######################################
#######################################

sub addParseFiles {
        my $file = shift;
        my $hash = shift;
        my $function = shift;
        $parseFiles[$parseFiles]{'file'} = $file;
        $parseFiles[$parseFiles]{'hash'} = $hash;
        $parseFiles[$parseFiles]{'function'} = $function;
        $parseFiles++;
}

# ICE Start - Chat Log
sub chatLog {
        my $type = shift;
        my $message = shift;
        if ( $type eq "pm") {
                open CHAT, ">> $chatPath/private.txt";
        } elsif ( $type eq "gm" ) {
                open CHAT, ">> $chatPath/avoid.txt";
        } elsif ( $type eq "i" ) {
                open CHAT, ">> $chatPath/item.txt";
        } elsif ( $type eq "m" ) {
                open CHAT, ">> $chatPath/monster.txt";
        } elsif ( $type eq "g" || $type eq "p" ) {
                open CHAT, ">> $chatPath/guild.txt";
        } elsif ( $type eq "x" ) {
                open CHAT, ">> $chatPath/system.txt";
        } elsif ( $type eq "b" ) {
                open CHAT, ">> $chatPath/buysell.txt";
        } elsif ( $type eq "storage" ) {
                open CHAT, ">> $chatPath/storage.txt";
        } else {
                open CHAT, ">> $chatPath/public.txt";
        }
        print CHAT "[".getFormattedDate(int(time))."][".uc($type)."] $message";
        close CHAT;
}
# ICE End

sub chatLog_clear {
        if (-e "$chatPath/private.txt") { unlink("$chatPath/private.txt"); }
        if (-e "$chatPath/item.txt")    { unlink("$chatPath/item.txt"); }
        if (-e "$chatPath/monster.txt") { unlink("$chatPath/monster.txt"); }
        if (-e "$chatPath/guild.txt")   { unlink("$chatPath/guild.txt"); }
        if (-e "$chatPath/system.txt")   { unlink("$chatPath/system.txt"); }
        if (-e "$chatPath/public.txt")   { unlink("$chatPath/public.txt"); }
        if (-e "$chatPath/storage.txt")   { unlink("$chatPath/storage.txt"); }
        if (-e "$chatPath/exp.txt")   { unlink("$chatPath/exp.txt"); }
}


sub convertGatField {
        my $file = shift;
        my $r_hash = shift;
        my $i;
        open FILE, "+> $file";
        binmode(FILE);
        print FILE pack("S*", $$r_hash{'width'}, $$r_hash{'height'});
        for ($i = 0; $i < @{$$r_hash{'field'}}; $i++) {
                print FILE pack("C1", $$r_hash{'field'}[$i]);
        }
        close FILE;
}

sub dumpData {
        my $msg = shift;
        my $dump;
        my $i;
        $dump = "\n\n================================================\n".getFormattedDate(int(time))."\n\n".length($msg)." bytes\n\n";
        for ($i=0; $i + 15 < length($msg);$i += 16) {
                $dump .= getHex(substr($msg,$i,8))."    ".getHex(substr($msg,$i+8,8))."\n";
        }
        if (length($msg) - $i > 8) {
                $dump .= getHex(substr($msg,$i,8))."    ".getHex(substr($msg,$i+8,length($msg) - $i - 8))."\n";
        } elsif (length($msg) > 0) {
                $dump .= getHex(substr($msg,$i,length($msg) - $i))."\n";
        }
        open DUMP, ">> DUMP.txt";
        print DUMP $dump;
        close DUMP;
        print "$dump\n" if $config{'debug'} >= 2;
        print "Message Dumped into DUMP.txt!\n";
}

sub getField {
        my $file = shift;
        my $r_hash = shift;
        my $i, $data;
        undef %{$r_hash};
        if (!(-e $file)) {
                print "\n!!Could not load field - you must install the kore-field pack!!\n\n";
        }
        if ($file =~ /\//) {
                ($$r_hash{'name'}) = $file =~ /\/([\s\S]*)\./;
        } else {
                ($$r_hash{'name'}) = $file =~ /([\s\S]*)\./;
        }
        open FILE, $file;
        binmode(FILE);
        read(FILE, $data, 4);
        my $width = unpack("S1", substr($data, 0,2));
        my $height = unpack("S1", substr($data, 2,2));
        $$r_hash{'width'} = $width;
        $$r_hash{'height'} = $height;
        while (read(FILE, $data, 1)) {
                $$r_hash{'field'}[$i] = unpack("C",$data);
                $$r_hash{'rawMap'} .= $data;
                $i++;
        }
        close FILE;
}

sub getGatField {
        my $file = shift;
        my $r_hash = shift;
        my $i, $data;
        undef %{$r_hash};
        ($$r_hash{'name'}) = $file =~ /([\s\S]*)\./;
        open FILE, $file;
        binmode(FILE);
        read(FILE, $data, 16);
        my $width = unpack("L1", substr($data, 6,4));
        my $height = unpack("L1", substr($data, 10,4));
        $$r_hash{'width'} = $width;
        $$r_hash{'height'} = $height;
        while (read(FILE, $data, 20)) {
                $$r_hash{'field'}[$i] = unpack("C1", substr($data, 14,1));
                $i++;
        }
        close FILE;
}

sub getResponse {
        my $type = shift;
        my $key;
        my @keys;
        my $msg;
        foreach $key (keys %responses) {
                if ($key =~ /^$type\_\d+$/) {
                        push @keys, $key;
                }
        }
        $msg = $responses{$keys[int(rand(@keys))]};
        $msg =~ s/\%\$(\w+)/$responseVars{$1}/eig;
        return $msg;
}

sub load {
        my $r_array = shift;

        foreach (@{$r_array}) {
                if (-e $$_{'file'}) {
                        printC("S0", "正在加载 $$_{'file'}...\n");
                } else {
                        printC("S1R", "无法加载 $$_{'file'}\n");
                }
                &{$$_{'function'}}("$$_{'file'}", $$_{'hash'});
        }
        startKoreEasy();
}



sub parseDataFile {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $key,$value;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                s/\s+$//g;
                ($key, $value) = $_ =~ /([\s\S]*) ([\s\S]*?)$/;
                if ($key ne "" && $value ne "") {
                        $$r_hash{$key} = $value;
                }
        }
        close FILE;
}

sub parseDataFile_lc {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $key,$value;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                s/\s+$//g;
                ($key, $value) = $_ =~ /([\s\S]*) ([\s\S]*?)$/;
                if ($key ne "" && $value ne "") {
                        $$r_hash{lc($key)} = $value;
                }
        }
        close FILE;
}

sub parseDataFile2 {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $key,$value;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                s/\s+$//g;
                ($key, $value) = $_ =~ /([\s\S]*?) ([\s\S]*)$/;
                $key =~ s/\s//g;
                if ($key eq "") {
                        ($key) = $_ =~ /([\s\S]*)$/;
                        $key =~ s/\s//g;
                }
                if ($key ne "") {
                        $$r_hash{$key} = $value;
                }
        }
        close FILE;
}

sub parseItemsControl {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $key,@args;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                s/\s+$//g;
                ($key, $args) = $_ =~ /([\s\S]+?) (\d+[\s\S]*)/;
                @args = split / /,$args;
                if ($key ne "") {
                        $$r_hash{lc($key)}{'keep'} = $args[0];
                        $$r_hash{lc($key)}{'storage'} = $args[1];
                        $$r_hash{lc($key)}{'sell'} = $args[2];
                }
        }
        close FILE;
}

sub parseNPCs {
        my $file = shift;
        my $r_hash = shift;
        my $i, $string;
        undef %{$r_hash};
        my $key,$value;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                s/\s+/ /g;
                s/\s+$//g;
                @args = split /\s/, $_;
                if (@args > 4) {
                        $$r_hash{$args[0]}{'map'} = $args[1];
                        $$r_hash{$args[0]}{'pos'}{'x'} = $args[2];
                        $$r_hash{$args[0]}{'pos'}{'y'} = $args[3];
                        $string = $args[4];
                        for ($i = 5; $i < @args; $i++) {
                                $string .= " $args[$i]";
                        }
                        $$r_hash{$args[0]}{'name'} = $string;
                }
        }
        close FILE;
}

sub parseMonControl {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $key,@args;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                s/\s+$//g;
                ($key, $args) = $_ =~ /([\s\S]+?) (\d+[\s\S]*)/;
                @args = split / /,$args;
                if ($key ne "") {
                        $$r_hash{lc($key)}{'attack_auto'} = $args[0];
                        $$r_hash{lc($key)}{'teleport_auto'} = $args[1];
                        $$r_hash{lc($key)}{'teleport_count'} = $args[2];
                }
        }
        close FILE;
}

sub parsePortals {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $key,$value;
        my %IDs;
        my $i;
        my $j = 0;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                s/\s+/ /g;
                s/\s+$//g;
                @args = split /\s/, $_;
                if (@args > 5) {
                        $IDs{$args[0]}{$args[1]}{$args[2]} = "$args[0] $args[1] $args[2]";
                        $$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'ID'} = "$args[0] $args[1] $args[2]";
                        $$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'map'} = $args[0];
                        $$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'pos'}{'x'} = $args[1];
                        $$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'pos'}{'y'} = $args[2];
                        $$r_hash{"$args[0] $args[1] $args[2]"}{'dest'}{'map'} = $args[3];
                        $$r_hash{"$args[0] $args[1] $args[2]"}{'dest'}{'pos'}{'x'} = $args[4];
                        $$r_hash{"$args[0] $args[1] $args[2]"}{'dest'}{'pos'}{'y'} = $args[5];
                        if ($args[6] ne "") {
                                $$r_hash{"$args[0] $args[1] $args[2]"}{'npc'}{'ID'} = $args[6];
                                for ($i = 7; $i < @args; $i++) {
                                        $$r_hash{"$args[0] $args[1] $args[2]"}{'npc'}{'steps'}[@{$$r_hash{"$args[0] $args[1] $args[2]"}{'npc'}{'steps'}}] = $args[$i];
                                }
                        }
                }
                $j++;
        }
        foreach (keys %{$r_hash}) {
                $$r_hash{$_}{'dest'}{'ID'} = $IDs{$$r_hash{$_}{'dest'}{'map'}}{$$r_hash{$_}{'dest'}{'pos'}{'x'}}{$$r_hash{$_}{'dest'}{'pos'}{'y'}};
        }
        close FILE;
}

sub parsePortalsLOS {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $key;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                s/\s+/ /g;
                s/\s+$//g;
                @args = split /\s/, $_;
                if (@args) {
                        $map = shift @args;
                        $x = shift @args;
                        $y = shift @args;
                        for ($i = 0; $i < @args; $i += 4) {
                                $$r_hash{"$map $x $y"}{"$args[$i] $args[$i+1] $args[$i+2]"} = $args[$i+3];
                        }
                }
        }
        close FILE;
}

sub parseReload {
        my $temp = shift;
        my @temp;
        my %temp;
        my $temp2;
        my $except;
        my $found;
        while ($temp =~ /(\w+)/g) {
                $temp2 = $1;
                $qm = quotemeta $temp2;
                if ($temp2 eq "all") {
                        foreach (@parseFiles) {
                                $temp{$$_{'file'}} = $_;
                        }
                } elsif ($temp2 =~ /\bexcept\b/i || $temp2 =~ /\bbut\b/i) {
                        $except = 1;
                } else {
                        if ($except) {
                                foreach (@parseFiles) {
                                        delete $temp{$$_{'file'}} if $$_{'file'} =~ /$qm/i;
                                }
                        } else {
                                foreach (@parseFiles) {
                                        $temp{$$_{'file'}} = $_ if $$_{'file'} =~ /$qm/i;
                                }
                        }
                }
        }
        foreach $temp (keys %temp) {
                $temp[@temp] = $temp{$temp};
        }
        load(\@temp);
}

sub parseResponses {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $key,$value;
        my $i;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                ($key, $value) = $_ =~ /([\s\S]*?) ([\s\S]*)$/;
                if ($key ne "" && $value ne "") {
                        $i = 0;
                        while ($$r_hash{"$key\_$i"} ne "") {
                                $i++;
                        }
                        $$r_hash{"$key\_$i"} = $value;
                }
        }
        close FILE;
}

sub parseROLUT {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my @stuff;
        open FILE, $file;
        foreach (<FILE>) {
                s/\r//g;
                next if /^\/\//;
                @stuff = split /#/, $_;
                $stuff[1] =~ s/_/ /g;
                if ($stuff[0] ne "" && $stuff[1] ne "") {
                        $$r_hash{$stuff[0]} = $stuff[1];
                }
        }
        close FILE;
}

sub parseRODescLUT {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $ID;
        my $IDdesc;
        open FILE, $file;
        foreach (<FILE>) {
                s/\r//g;
                if (/^#/) {
                        $$r_hash{$ID} = $IDdesc;
                        undef $ID;
                        undef $IDdesc;
                } elsif (!$ID) {
                        ($ID) = /([\s\S]+)#/;
                } else {
                        $IDdesc .= $_;
                        $IDdesc =~ s/\^......//g;
                        $IDdesc =~ s/_/--------------/g;
                }
        }
        close FILE;
}

sub parseROSlotsLUT {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $ID;
        open FILE, $file;
        foreach (<FILE>) {
                if (!$ID) {
                        ($ID) = /(\d+)#/;
                } else {
                        ($$r_hash{$ID}) = /(\d+)#/;
                        undef $ID;
                }
        }
        close FILE;
}

sub parseSkillsLUT {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my @stuff;
        my $i;
        open FILE, $file;
        $i = 1;
        foreach (<FILE>) {
                @stuff = split /#/, $_;
                $stuff[1] =~ s/_/ /g;
                if ($stuff[0] ne "" && $stuff[1] ne "") {
                        $$r_hash{$stuff[0]} = $stuff[1];
                }
                $i++;
        }
        close FILE;
}


sub parseSkillsIDLUT {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my @stuff;
        my $i;
        open FILE, $file;
        $i = 1;
        foreach (<FILE>) {
                @stuff = split /#/, $_;
                $stuff[1] =~ s/_/ /g;
                if ($stuff[0] ne "" && $stuff[1] ne "") {
                        $$r_hash{$i} = $stuff[1];
                }
                $i++;
        }
        close FILE;
}

sub parseSkillsReverseLUT_lc {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my @stuff;
        my $i;
        open FILE, $file;
        $i = 1;
        foreach (<FILE>) {
                @stuff = split /#/, $_;
                $stuff[1] =~ s/_/ /g;
                if ($stuff[0] ne "" && $stuff[1] ne "") {
                        $$r_hash{lc($stuff[1])} = $stuff[0];
                }
                $i++;
        }
        close FILE;
}

sub parseSkillsSPLUT {
        my $file = shift;
        my $r_hash = shift;
        undef %{$r_hash};
        my $ID;
        my $i;
        $i = 1;
        open FILE, $file;
        foreach (<FILE>) {
                if (/^\@/) {
                        undef $ID;
                        $i = 1;
                } elsif (!$ID) {
                        ($ID) = /([\s\S]+)#/;
                } else {
                        ($$r_hash{$ID}{$i++}) = /(\d+)#/;
                }
        }
        close FILE;
}

sub parseTimeouts {
        my $file = shift;
        my $r_hash = shift;
        my $key,$value;
        open FILE, $file;
        foreach (<FILE>) {
                next if (/^#/);
                s/[\r\n]//g;
                ($key, $value) = $_ =~ /([\s\S]*) ([\s\S]*?)$/;
                if ($key ne "" && $value ne "") {
                        $$r_hash{$key}{'timeout'} = $value;
                }
        }
        close FILE;
}

sub writeDataFile {
        my $file = shift;
        my $r_hash = shift;
        my $key,$value;
        open FILE, "+> $file";
        foreach (keys %{$r_hash}) {
                if ($_ ne "") {
                        print FILE "$_ $$r_hash{$_}\n";
                }
        }
        close FILE;
}

sub writeDataFileIntact {
        my $file = shift;
        my $r_hash = shift;
        my $data;
        my $key;
        open FILE, $file;
        foreach (<FILE>) {
                if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
                        $data .= $_;
                        next;
                }
                ($key) = $_ =~ /^(\w+)/;
                $data .= "$key $$r_hash{$key}\n";
        }
        close FILE;
        open FILE, "+> $file";
        print FILE $data;
        close FILE;
}

sub writeDataFileIntact2 {
        my $file = shift;
        my $r_hash = shift;
        my $data;
        my $key;
        open FILE, $file;
        foreach (<FILE>) {
                if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
                        $data .= $_;
                        next;
                }
                ($key) = $_ =~ /^(\w+)/;
                $data .= "$key $$r_hash{$key}{'timeout'}\n";
        }
        close FILE;
        open FILE, "+> $file";
        print FILE $data;
        close FILE;
}

sub writePortalsLOS {
        my $file = shift;
        my $r_hash = shift;
        open FILE, "+> $file";
        foreach $key (keys %{$r_hash}) {
                next if (!(keys %{$$r_hash{$key}}));
                print FILE $key;
                foreach (keys %{$$r_hash{$key}}) {
                        print FILE " $_ $$r_hash{$key}{$_}";
                }
                print FILE "\n";
        }
        close FILE;
}

sub updateMonsterLUT {
        my $file = shift;
        my $ID = shift;
        my $name = shift;
        open FILE, ">> $file";
        print FILE "$ID $name\n";
        close FILE;
}

sub updatePortalLUT {
        my ($file, $src, $x1, $y1, $dest, $x2, $y2) = @_;
        open FILE, ">> $file";
        print FILE "$src $x1 $y1 $dest $x2 $y2\n";
        close FILE;
}

sub updateNPCLUT {
        my ($file, $ID, $map, $x, $y, $name) = @_;
        open FILE, ">> $file";
        print FILE "$ID $map $x $y $name\n";
        close FILE;
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
        print "===============Item Description===============\n";
        print "Item: $items_lut{$itemID}\n\n";
        print $itemsDesc_lut{$itemID};
        print "==============================================\n";
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



#######################################
#Kore Easy Add-on
#######################################



##### PARSE FILES #####

#sub parsePlusFile {
#        my $file = shift;
#        my $r_hash = shift;
#        my $i = 0;
#        undef %{$r_hash};
#        open FILE, $file;
#        foreach (<FILE>) {
#                next if (/^#/);
#                s/\r//g;
#                s/\n//g;
#                if( $_ ne "" ){
#                        $$r_hash[$i++] = $_;
#                }
#        }
#        close FILE;
#}

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
        if ($mon_control{'all'}{'attack_auto'} eq "") {
                $mon_control{'all'}{'attack_auto'} = 1;
        }
        my @monstersAttackFirst = split /,/, $config{'monstersAttackFirst'};
        foreach (@monstersAttackFirst) {
                $mon_control{lc($_)}{'attack_auto'} = 2;
        }
        my @monstersAttackSkip = split /,/, $config{'monstersAttackSkip'};
        foreach (@monstersAttackSkip) {
                $mon_control{lc($_)}{'attack_auto'} = 0;
        }
        my @monstersTeleportSee = split /,/, $config{'monstersTeleportSee'};
        foreach (@monstersTeleportSee) {
                $mon_control{lc($_)}{'attack_auto'} = 0;
                $mon_control{lc($_)}{'teleport_auto'} = 1;
        }
        my @monstersTeleportAggress = split /,/, $config{'monstersTeleportHit'};
        foreach (@monstersTeleportAggress) {
                $mon_control{lc($_)}{'teleport_auto'} = 2;
        }
        my @monstersAttackFirst = split /,/, $config{'monstersTeleportDmg'};
        foreach (@monstersAttackFirst) {
                $mon_control{lc($_)}{'teleport_auto'} = 3;
        }
}

sub initNpcControl {
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
}

sub initPlusControl {
        my $key;
        my @keys;
        foreach $key (keys %plus) {
                $config{$key} = $plus{$key} if ($config{$key} eq "");
        }
}

sub initSkillControl {
        my $key;
        my @keys;
        foreach $key (keys %skill_control) {
                $config{$key} = $skill_control{$key} if ($config{$key} eq "");
        }
}

sub initGameStart {
        $chars[$config{'char'}]{'autochat'}{'last_time'} = time;
        if (!$chars[$config{'char'}]{'exp_start'}) {
                $chars[$config{'char'}]{'exp_start'} = $chars[$config{'char'}]{'exp'};
                $chars[$config{'char'}]{'exp_job_start'} = $chars[$config{'char'}]{'exp_job'};
                $chars[$config{'char'}]{'exp_start_time'} = time;
        }
        initMapChanged();
}

sub initMapChanged {
        undef $message_old;
        ai_stateReset();
        $chars[$config{'char'}]{'time_mapChanged'} = time;
        undef $EAIndex;
}


##### ADD-ON FUNCTIONS #####

sub startKoreEasy {
        initPlusControl();
        initSkillControl();
        initNpcControl();
        initMonControl();
        undef $config{'sitAuto_hp_upper'} if (!$config{'sitAuto_hp_lower'});
        undef $config{'sitAuto_sp_upper'} if (!$config{'sitAuto_sp_lower'});
        $config{'cartAutoItemMaxWeight'} = 20 if (!$config{'cartAutoItemMaxWeight'});
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

sub autoChat {
        my $type = shift;
        my $name = shift;
        my $msg = shift;
        undef $chars[$config{'char'}]{'autochat'}{'msg'};
        $chars[$config{'char'}]{'autochat'}{'type'} = $type;
        $chars[$config{'char'}]{'autochat'}{'name'} = $name;
        $chars[$config{'char'}]{'autochat'}{'msg'} = autoChatMessage($msg);
        $chars[$config{'char'}]{'autochat'}{'time'} = time;
        $chars[$config{'char'}]{'autochat'}{'send'} = 1;
        if ($type eq "c") {
                my $j = 0;
                for ($i = 0; $i < @playersID; $i++) {
                        if ($players{$playersID[$i]}{'name'} eq $name) {
                                $j = $i;
                                last;
                        }
                }
                my $dPDist = line_distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$playersID[$j]}{'pos_to'}});
                if($dPDist > 10 || $chars[$config{'char'}]{'autochat'}{'msg'} eq ""){
                        undef $chars[$config{'char'}]{'autochat'}{'send'};
                }
        } elsif ($type eq "pm" && $chars[$config{'char'}]{'autochat'}{'msg'} eq "") {
                $chars[$config{'char'}]{'autochat'}{'msg'} = autoChatMessage("Default-responsePriMsg");
        }
}

sub autoChatMessage {
        my $type = shift;
        my $key;
        my @keys;
        my $msg;
        my $keychar;
        foreach $key (keys %airesponses) {
                $keychar = substr($key,0,index($key,'_'));
                if ($type =~ /\Q$keychar\E/i) {
                        push @keys, $key;
                }
        }
        $msg = $airesponses{$keys[int(rand(@keys))]};
        $msg =~ s/\%\$(\w+)/$airesponsesVars{$1}/eig;
        return $msg;
}

sub avoidChat {
        my $ID = shift;
        my $name = shift;
        my $message = shift;
        my @messages;
        my $sleeptime;
        my $AID = unpack("L1", $ID);
        ($map_string) = $map_name =~ /([\s\S]*)\.gat/;
        $config{'avoidGM_reconnect'} = 60 if ($config{'avoidGM_reconnect'} < 60);
        if ($config{'avoidGM_word'}) {
                @messages = split /,/, $config{'avoidGM_word'};
                @messages[0] = $chars[$config{'char'}]{'name'} if (@messages[0] eq "name");
                for ($i = 0; $i < @messages; $i++) {
                        if ($message =~ /\Q@messages[$i]\E/i) {
                                if (!$indoors_lut{$map_string.'.rsw'}) {
                                        $sleeptime = int($config{'avoidGM_reconnect'} + rand(1800) + 1800);
                                        printC("S0R", "$name($AID) 说话，瞬移断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                                        chatLog("gm", "$name($AID) 说话，瞬移断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                                        useTeleport(1);
                                        sleep(2);
                                } else {
                                        $sleeptime = int($config{'avoidGM_reconnect'} + rand(3600) + 3600);
                                        printC("S0R", "$name($AID) 说话，房内断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                                        chatLog("gm", "$name($AID) 说话，房内断线$sleeptime秒。位置: 位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                                }
                                killConnection(\$remote_socket);
                                sleep($sleeptime);
                                $chars[$config{'char'}]{'autochat'}{'send'} = 1;
                                $chars[$config{'char'}]{'autochat'}{'type'} = "x";
                                return;
                        }
                }
        }
        if($avoidlist_rlut{$name}){
                if (!$indoors_lut{$map_string.'.rsw'}) {
                        $sleeptime = int($config{'avoidGM_reconnect'} + rand(1800) + 1800);
                        printC("S0R", "$name($AID) 说话，瞬移断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        chatLog("gm", "$name($AID) 说话，瞬移断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        useTeleport(1);
                        sleep(2);
                } else {
                        $sleeptime = int($config{'avoidGM_reconnect'} + rand(3600) + 3600);
                        printC("S0R", "$name($AID) 说话，房内断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        chatLog("gm", "$name($AID) 说话，房内断线$sleeptime秒。位置: 位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                }
                killConnection(\$remote_socket);
                sleep($sleeptime);
                $chars[$config{'char'}]{'autochat'}{'send'} = 1;
                $chars[$config{'char'}]{'autochat'}{'type'} = "x";
                return;
        }
        if ($aid_rlut{$AID}{'avoid'}) {
                if (!$indoors_lut{$map_string.'.rsw'}) {
                        $sleeptime = int($config{'avoidGM_reconnect'} + rand(1800) + 1800);
                        printC("S0R", "$name($AID) 说话，瞬移断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        chatLog("gm", "$name($AID) 说话，瞬移断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        useTeleport(1);
                        sleep(2);
                } else {
                        $sleeptime = int($config{'avoidGM_reconnect'} + rand(3600) + 3600);
                        printC("S0R", "$name($AID) 说话，房内断线$sleeptime秒。位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        chatLog("gm", "$name($AID) 说话，房内断线$sleeptime秒。位置: 位置: $map_string ($chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'})\n");
                }
                killConnection(\$remote_socket);
                sleep($sleeptime);
                $chars[$config{'char'}]{'autochat'}{'send'} = 1;
                $chars[$config{'char'}]{'autochat'}{'type'} = "x";
                return;
        }
}



sub getImportantItems{
       my $ID = shift;
       my $dist = shift;
       my %args;
       if($importantItems_rlut{$items{$ID}{'name'}} == 1){
                $args{'ID'} = $ID;
                unshift @ai_seq, "items_important";
                unshift @ai_seq_args, \%args;
                printC("I3Y", "发现: $items{$ID}{'name'} - $dist\n");
                chatLog("i", "发现: $items{$ID}{'name'} - $dist\n");
                sendTake(\$remote_socket, $ID);
        }
}

sub switchEquipment {
        my $switch_type = shift;
        my $ID = shift;
        my $i = 1;
        my $type = 0;
        if ($switch_type eq "m") {
                while ($swtichAuto{"autoSwitch_$i"."_mon"} ne "" || $swtichAuto{"autoSwitch_$i"."_hp_lower"} > 0 || $swtichAuto{"autoSwitch_$i"."_sp_lower"} > 0 || $swtichAuto{"autoSwitch_$i"."_monSkills"} ne "" || $swtichAuto{"autoSwitch_$i"."_useSkills"} ne "") {
                        if (existsInList($swtichAuto{"autoSwitch_$i"."_monSkills"}, $skillsID_lut{$ID})) {
                                $type = $i;
                                last;
                        }
                        $i++;
                }
                $type = $chars[$config{'char'}]{'autoSwitch'} if ($type == 0);
        } elsif ($switch_type eq "u") {
                while ($swtichAuto{"autoSwitch_$i"."_mon"} ne "" || $swtichAuto{"autoSwitch_$i"."_hp_lower"} > 0 || $swtichAuto{"autoSwitch_$i"."_sp_lower"} > 0 || $swtichAuto{"autoSwitch_$i"."_monSkills"} ne "" || $swtichAuto{"autoSwitch_$i"."_useSkills"} ne "") {
                        if (existsInList($swtichAuto{"autoSwitch_$i"."_useSkills"}, $skillsID_lut{$ID})) {
                                $type = $i;
                                last;
                        }
                        $i++;
                }
                $type = $chars[$config{'char'}]{'autoSwitch'} if ($type == 0);
        } elsif ($switch_type eq "a") {
                while ($swtichAuto{"autoSwitch_$i"."_mon"} ne "" || $swtichAuto{"autoSwitch_$i"."_hp_lower"} > 0 || $swtichAuto{"autoSwitch_$i"."_sp_lower"} > 0 || $swtichAuto{"autoSwitch_$i"."_monSkills"} ne "" || $swtichAuto{"autoSwitch_$i"."_useSkills"} ne "") {
                        if (existsInList($swtichAuto{"autoSwitch_$i"."_mon"}, $monsters{$ID}{'name'})
                                || ($swtichAuto{"autoSwitch_$i"."_hp_lower"} > 0 && $swtichAuto{"autoSwitch_$i"."_hp_lower"} > $chars[$config{'char'}]{'hp'}/$chars[$config{'char'}]{'hp_max'} * 100)
                                || ($swtichAuto{"autoSwitch_$i"."_sp_lower"} > 0 && $swtichAuto{"autoSwitch_$i"."_sp_lower"} > $chars[$config{'char'}]{'sp'}/$chars[$config{'char'}]{'sp_max'} * 100)) {
                                $type = $i;
                                last;
                        }
                        $i++;
                }
        }
        if ($chars[$config{'char'}]{'autoSwitch'} eq "" || $chars[$config{'char'}]{'autoSwitch'} != $type) {
                my $j = 0;
                while ($swtichAuto{"autoSwitch_$type"."_equip_$j"} ne "") {
                         undef $index;
                         $index = ai_findIndexAutoSwitch($swtichAuto{"autoSwitch_$type"."_equip_$j"});
                         if ($index ne "" && existsInList($swtichAuto{"autoSwitch_$type"."_equip_$j"}, "r")) {
                                 ai_sendEquip($index,"r");
                                 $chars[$config{'char'}]{'autoSwitch'} = $type;
                         } elsif ($index ne "") {
                                 ai_sendEquip($index,"");
                                 $chars[$config{'char'}]{'autoSwitch'} = $type;
                         }
                         $j++;
                }
        }
}


##### AI FUNCTIONS #####

sub ai_changeToMvpMode {
        my $type = shift;
        if ($type == 1) {
                undef @ai_seq;
                undef @ai_seq_args;
                $chars[$config{'char'}]{'mvp'} = 1;
                $chars[$config{'char'}]{'mvp_start_time'} = time;
                $timeout{'ai_attack_giveup'}{'timeout'} = 60;
                $timeout{'ai_attack_waitAfterKill'}{'timeout'} = 2;
                my $key;
                my @keys;
                foreach $key (keys %mvp) {
                        $config{$key} = $mvp{$key};
                }
                printC("S0Y", "变为MVP模式\n");
                initMonControl();
#        } elsif ($type == 2) {
#                my $key;
#                my @keys;
#                foreach $key (keys %mvp) {
#                        $config{$key} = $free{$key};
#                }
#                undef $chars[$config{'char'}]{'mvp'};
#                printC("S0Y", "变为自由模式\n");
#                initMonControl();
        } else {
                undef $chars[$config{'char'}]{'mvp'};
                parseReload("config");
                parseReload("timeout");
                printC("S0Y", "变为正常模式\n");
                startKoreEasy();
                $chars[$config{'char'}]{'mvp_end_time'} = time;
        }
}

sub ai_findIndexAutoSwitch {
        my $String = shift;
        my $i = 0;
        my $find_index;
        for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
                next if ($chars[$config{'char'}]{'inventory'}[$i]{'type'} < 4);
                if ($chars[$config{'char'}]{'inventory'}[$i]{'name'} eq $String) {
                        $find_index = $i;
                        return $find_index if ($chars[$config{'char'}]{'inventory'}[$find_index]{'equipped'} == 0);
                } elsif ($chars[$config{'char'}]{'inventory'}[$i]{'slotName'} || $chars[$config{'char'}]{'inventory'}[$i]{'elementName'}) {
                        if (substr($chars[$config{'char'}]{'inventory'}[$i]{'name'},0,4) eq substr($String,0,4)
                                && (!$chars[$config{'char'}]{'inventory'}[$i]{'slotName'} || existsInList($String, $chars[$config{'char'}]{'inventory'}[$i]{'slotName'}))
                                && (!$chars[$config{'char'}]{'inventory'}[$i]{'elementName'} || existsInList($String, $chars[$config{'char'}]{'inventory'}[$i]{'elementName'}))) {
                                $find_index = $i;
                                return $find_index if ($chars[$config{'char'}]{'inventory'}[$find_index]{'equipped'} == 0);
                        }
                }
        }
        return $find_index;
}

sub ai_getTeleportAggressives {
        my $tpMonsters;
        foreach (@monstersID) {
                next if ($_ eq "");
                if ($monsters{$_}{'dmgToYou'} > 0 || ($monsters{$_}{'missedYou'} > 0 && (!$config{'teleportAuto_skipMiss'} || ($config{'teleportAuto_skipMiss'} ne "" && !existsInList($config{'teleportAuto_skipMiss'}, $monsters{$_}{'name'}))))) {
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
                        } elsif (@portalsID && time - $chars[$config{'char'}]{'time_mapChanged'} < 5) {
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
                next if ($_ eq "" || $passivemon_lut{$monsters{$_}{'nameID'}});
                if (line_distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}}) <= $dist) {
                        push @rdMonsters, $_;
                }
        }
        return @rdMonsters;
}

sub ai_getTalkID {
        my $talkid = shift;
        if (unpack("L1",$talkid) < 1000) {
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

sub ai_itemKeep {
        my $r_hash = shift;
        my $index = shift;
        if ($$r_hash[$index]{'enchant'} > 0 || $$r_hash[$index]{'elementName'} ne "" || $$r_hash[$index]{'slotName'} ne "") {
                return 1;
        } elsif ($$r_hash[$index]{'name'} eq $config{'accessoryDefault'} || $$r_hash[$index]{'name'} eq $config{'accessoryTeleport'}) {
                return 1;
        } elsif ($$r_hash[$index]{'type_equip'} != 0) {
                my $i = 0;
                while ($i == 0 || $swtichAuto{"autoSwitch_$i"."_mon"} ne "" || $swtichAuto{"autoSwitch_$i"."_hp_lower"} > 0) {
                        my $j = 0;
                        while ($swtichAuto{"autoSwitch_$i"."_equip_$j"} ne "") {
                                if ($$r_hash[$index]{'name'} eq $swtichAuto{"autoSwitch_$i"."_equip_$j"} || $$r_hash[$index]{'name'}.",r" eq $swtichAuto{"autoSwitch_$i"."_equip_$j"}) {
                                        return 1;
                                }
                                $j++;
                        }
                        $i++;
                }
                return 0;
        } else {
                return 0;
        }
}

sub ai_inventoryCheck {
        for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
                next if (!%{$chars[$config{'char'}]{'inventory'}[$i]});
                return 1;
        }
        return 0;
}

sub ai_sendEquip {
        my $index = shift;
        my $type = shift;
        if ($chars[$config{'char'}]{'inventory'}[$index]{'type_equip'} == 256
                || $chars[$config{'char'}]{'inventory'}[$index]{'type_equip'} == 513) {
                sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$index]{'index'}, 0, 1);
        } elsif ($chars[$config{'char'}]{'inventory'}[$index]{'type_equip'} == 512) {
                sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$index]{'index'}, 0, 2);
        } elsif ($chars[$config{'char'}]{'inventory'}[$index]{'type_equip'} == 1) {
                sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$index]{'index'}, 1, 0);
        } else {
                if ($type eq "r") {
                        sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$index]{'index'}, 32, 0);
                } else {
                        sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$index]{'index'}, $chars[$config{'char'}]{'inventory'}[$index]{'type_equip'}, 0);
                }
        }
}

sub findIndexMultiString_lc {
        my $r_array = shift;
        my $match = shift;
        my $ID = shift;
        my @Strings = split /,/, $ID;
        my $index;
        foreach (@Strings) {
                next if ($_ eq "");
                $index = findIndexString_lc($r_array, $match, $_);
                if ($index ne "") {
                        return $index;
                }
        }
        return $index;
}


##### OUTGOING PACKET FUNCTIONS #####

sub sendBuyVender {
        my $r_socket = shift;
        my $ID = shift;
        my $amount = shift;
        my $msg = pack("C*", 0x34, 0x01, 0x0C, 0x00) . $venderID . pack("S*", $amount, $ID);
        encrypt($r_socket, $msg);
        print "Sent Vender Buy: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendCloseShop {
        my $r_socket = shift;
        my $msg = pack("C*", 0x2E, 0x01);
        encrypt($r_socket, $msg);
        print "Shop Closed: $index x $amount\n" if ($config{'debug'} >= 2);
        undef $chars[$config{'char'}]{'shopOpened'};
        undef @articles;
        $timeout{'ai_shopAutoGet'}{'time'} = time;
        $timeout{'ai_shopAuto'}{'time'} = time;
}

sub sendEnteringVender {
        my $r_socket = shift;
        my $ID = shift;
        my $msg = pack("C*", 0x30, 0x01) . $ID;
        encrypt($r_socket, $msg);
        print "Sent Entering Vender: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
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

        $strShopTitle = $shop{'shop_title'};

        if (length($strShopTitle) == 0) {
                printC("I0R", "请给你的商店起个名字吧，商店未开张。\n");
                undef $shop{'shopAuto_open'} if ($shop{'shopAuto_open'});
                return;
        } elsif (length($strShopTitle) >= 36) {
                $strShopTitle = substr($strShopTitle, 0, 36);
        }

        $sellItemsCount = 0;
        $i = 0;
        my $strSellingItems = "";
        while ($shop{"name_$i"} ne "") {
                undef $itemIndex;
                undef $amount;
                undef $price;
                $itemFounded = 0;
                for ($j=0; $j < @{$cart{'inventory'}}; $j++) {
                        next if (!%{$cart{'inventory'}[$j]});
                        if ($cart{'inventory'}[$j]{'name'} eq $shop{"name_$i"} && $shop{"name_$i"} ne "") {
                                if (!existsInList($strSellingItems, $j)) {
                                        $itemIndex = $j;
                                        $itemFounded = 1;
                                        last;
                                }
                        }
                }
                if ($itemFounded == 0) {
                        printC("I0", "你的手推车里没有物品 " . $shop{"name_$i"} . ", 忽略此物品。\n");
                }
                if ($shop{"quantity_$i"} > 0 && $itemFounded == 1) {
                        if ($shop{"quantity_$i"} > $cart{'inventory'}[$j]{'amount'}) {
                                $amount = $cart{'inventory'}[$j]{'amount'};
                        } else {
                                $amount = $shop{"quantity_$i"};
                        }
                } elsif ($shop{"quantity_$i"} eq "" || $shop{"quantity_$i"} == 0) {
                        $amount = $cart{'inventory'}[$j]{'amount'};
                } else {
                        $itemFounded = 0;
                }

                if ($shop{"price_$i"} > 0 && $shop{"price_$i"} <= 10000000 && $itemFounded == 1) {
                        $price = $shop{"price_$i"};
                } elsif ($shop{"price_$i"} eq "" || $shop{"price_$i"} == 0) {
                        printC("I0R", "物品 " . $shop{"name_$i"} . " 的价格设置错误。\n");
                        $itemFounded = 0;
                } else {
                        $itemFounded = 0;
                }

                if ($itemFounded == 1) {
                        $shopmsg .= pack("S*", $itemIndex) . pack("S*", $amount) . pack("L*", $price);
#                        print "添加物品 " . $shop{"name_$i"} . " ($itemIndex) 到商店，数量：$amount，价格：$price\n";
                        if ($strSellingItems eq "") {
                                $strSellingItems = $itemIndex;
                        } else {
                                $strSellingItems .= ",$itemIndex";
                        }
                        $sellItemsCount++;
                        if ($sellItemsCount >= 12) {
                                last;
                        }
                }
                $i++;
        }

        if ($sellItemsCount > 0 && $sellItemsCount <= 12) {
                my $msglength = 0x54 + 0x08 * $sellItemsCount;

                $shopmsg = pack("C*", 0x2F, 0x01) . pack("S*", $msglength) .
                        $strShopTitle . chr(0) x (36 - length($strShopTitle)) . chr(0) x 44
                        . $shopmsg;
        }

        if( $sellItemsCount > 0 && $sellItemsCount <= 12 ) {
                encrypt($r_socket, $shopmsg);
                printC("I0C", "商店 ( $strShopTitle ) 开张了。\n");
                undef $config{'chatAutoPublic'};
                undef $config{'chatAutoPrivate'};
                $chars[$config{'char'}]{'shopOpened'} = 1;
        }else{
                printC("I0R", "开店失败, 请检查你的shop_control.txt文件\n");
                undef $shop{'shopAuto_open'} if ($shop{'shopAuto_open'});
        }
}

sub sendTalkAmount {
        my $r_socket = shift;
        my $ID = shift;
        my $Qty = shift;
        $ID = ai_getTalkID($ID);
        my $msg = pack("C*", 0x43, 0x01) . $ID . pack("C*",$Qty) . pack("C*", 0x00, 0x00, 0x00);
        encrypt($r_socket, $msg);
        print "Sent talk buy: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}


sub printC {
        my $type = shift;
        my $msg = shift;
        my $type1 = substr($type,0,1);
        my $type2 = substr($type,1,1);
        my $color = substr($type,2,1);

        if ($type1 eq "X" && $type2 eq "0") {

        } elsif ($type1 eq "S") {
                $CONSOLE->Attr($FG_YELLOW|$BG_BLACK);
                if ($type2 eq "0") {
                        $CONSOLE->Write("<系统> ");
                } elsif ($type2 eq "1") {
                        $CONSOLE->Write("<错误> ");
                }
        } elsif ($type1 eq "C") {
                $CONSOLE->Attr($FG_LIGHTGREEN|$BG_BLACK);
                if ($type2 eq "0") {
                        $CONSOLE->Write("<公告> ");
                } elsif ($type2 eq "1") {
                        $CONSOLE->Write("<公聊> ");
                } elsif ($type2 eq "2") {
                        $CONSOLE->Write("<私聊> ");
                } elsif ($type2 eq "3") {
                        $CONSOLE->Write("<组队> ");
                } elsif ($type2 eq "4") {
                        $CONSOLE->Write("<工会> ");
                }
        } elsif ($type1 eq "A") {
                if ($type2 eq "0") {
                        $CONSOLE->Attr($FG_LIGHTCYAN|$BG_BLACK);
                        $CONSOLE->Write("<攻击> ");
                } elsif ($type2 eq "1") {
                        $CONSOLE->Attr($FG_LIGHTRED|$BG_BLACK);
                        $CONSOLE->Write("<防守> ");
                } elsif ($type2 eq "2") {
                        $CONSOLE->Attr($FG_WHITE|$BG_BLACK);
                        $CONSOLE->Write("<辅助> ");
                } elsif ($type2 eq "3") {
                        $CONSOLE->Attr($FG_WHITE|$BG_BLACK);
                        $CONSOLE->Write("<玩家> ");
                } elsif ($type2 eq "4") {
                        $CONSOLE->Attr($FG_WHITE|$BG_BLACK);
                        $CONSOLE->Write("<怪物> ");
                } elsif ($type2 eq "5") {
                        $CONSOLE->Attr($FG_WHITE|$BG_BLACK);
                        $CONSOLE->Write("<瞬移> ");
                }
        } elsif ($type1 eq "I") {
                $CONSOLE->Attr($FG_WHITE|$BG_BLACK);
                if ($type2 eq "0") {
                        $CONSOLE->Write("<信息> ");
                } elsif ($type2 eq "1") {
                        $CONSOLE->Write("<玩家> ");
                } elsif ($type2 eq "2") {
                        $CONSOLE->Write("<怪物> ");
                } elsif ($type2 eq "3") {
                        $CONSOLE->Write("<物品> ");
                } elsif ($type2 eq "4") {
                        $CONSOLE->Write("<仓库> ");
                } elsif ($type2 eq "5") {
                        $CONSOLE->Write("<车子> ");
                } elsif ($type2 eq "6") {
                        $CONSOLE->Write("<状态> ");
                } elsif ($type2 eq "7") {
                        $CONSOLE->Write("<对话> ");
                } elsif ($type2 eq "8") {
                        $CONSOLE->Write("<地图> ");
                }
        } elsif ($type1 eq "M") {
                if ($type2 eq "0") {
                        $CONSOLE->Write("<玩家> ");
                } elsif ($type2 eq "1") {
                        $CONSOLE->Write("<怪物> ");
                } elsif ($type2 eq "2") {
                        $CONSOLE->Write("<物品> ");
                } elsif ($type2 eq "3") {
                        $CONSOLE->Write("<人物> ");
                } elsif ($type2 eq "4") {
                        $CONSOLE->Write("<宠物> ");
                } elsif ($type2 eq "5") {
                        $CONSOLE->Write("<传送> ");
                } elsif ($type2 eq "6") {
                        $CONSOLE->Write("<地图> ");
                } elsif ($type2 eq "7") {
                        $CONSOLE->Write("<信息> ");
                }
        }
        $CONSOLE->Attr($ATTR_NORMAL);

        if ($msg ne "") {
                if ($color eq "R") {
                        $CONSOLE->Attr($FG_LIGHTRED|$BG_BLACK);
                } elsif ($color eq "G") {
                        $CONSOLE->Attr($FG_LIGHTGREEN|$BG_BLACK);
                } elsif ($color eq "M") {
                        $CONSOLE->Attr($FG_LIGHTMAGENTA|$BG_BLACK);
                } elsif ($color eq "C") {
                        $CONSOLE->Attr($FG_LIGHTCYAN|$BG_BLACK);
                } elsif ($color eq "Y") {
                        $CONSOLE->Attr($FG_YELLOW|$BG_BLACK);
                } elsif ($color eq "W") {
                        $CONSOLE->Attr($FG_WHITE|$BG_BLACK);
                } elsif ($color eq "B") {
                        $CONSOLE->Attr($FG_BLUE|$BG_BLACK);
                } elsif ($color eq "L") {
                        $CONSOLE->Attr($FG_LIGHTBLUE|$BG_BLACK);
                } elsif ($color eq "E") {
                        $CONSOLE->Attr($FG_RED|$BG_BLACK);
                }
        print "$msg";
        $CONSOLE->Attr($ATTR_NORMAL);
        }
}

sub writeC {
        my $color = shift;
        my $msg = shift;
        if ($color eq "R") {
                $CONSOLE->Attr($FG_LIGHTRED|$BG_BLACK);
        } elsif ($color eq "G") {
                $CONSOLE->Attr($FG_LIGHTGREEN|$BG_BLACK);
        } elsif ($color eq "M") {
                $CONSOLE->Attr($FG_LIGHTMAGENTA|$BG_BLACK);
        } elsif ($color eq "C") {
                $CONSOLE->Attr($FG_LIGHTCYAN|$BG_BLACK);
        } elsif ($color eq "Y") {
                $CONSOLE->Attr($FG_YELLOW|$BG_BLACK);
        } elsif ($color eq "B") {
                $CONSOLE->Attr($FG_BLUE|$BG_BLACK);
        } elsif ($color eq "L") {
                $CONSOLE->Attr($FG_LIGHTBLUE|$BG_BLACK);
        } elsif ($color eq "W") {
                $CONSOLE->Attr($FG_WHITE|$BG_BLACK);
        }
        $CONSOLE->Write("$msg");
        $CONSOLE->Attr($ATTR_NORMAL);
}

sub attackC {
        my $type = shift;
        my $sourceID = shift;
        my $targetID = shift;
        my $damage1 = shift;
        my $damage2 = shift;
        my $extra = shift;
        my $skillID = shift;
        my $level = shift;
        my $typeDisplay, $sourceDisplay, $targetDisplay, $damageDisplay, $extraDisplay, $skillDisplay;
        $level = 0 if ($level > 50);
        $skillColor = "X";
        undef $damageDisplay;
        undef $extraDisplay;
        undef $skillDisplay;
        undef $showDisplay;

        if ($sourceID eq $accountID) {
                $sourceDisplay = "你";
                $skillColor = "C";
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
                $skillColor = "M" if ($sourceType == 3);
        } elsif (%{$players{$targetID}}) {
                $targetDisplay = "$players{$targetID}{'name'}($players{$targetID}{'binID'})";
                $targetType = 2;
        } elsif (%{$monsters{$targetID}}) {
                $targetDisplay = "$monsters{$targetID}{'name'}($monsters{$targetID}{'binID'})";
                $targetType = 3;
        } elsif ($targetID eq "pos") {
                $targetDisplay = "位置: ($damage1, $damage2)";
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
                $skillColor = "M";
        } elsif ($sourceType == 3 && $targetType == 5 && ($monsters{$sourceID}{'dmgToYou'} > 0 || $monsters{$sourceID}{'missedYou'} > 0 || $monsters{$sourceID}{'dmgFromYou'} > 0 || $monsters{$sourceID}{'missedFromYou'} > 0)) {
                $targetType = 8;
                $skillColor = "M";
        }

        if ($config{'Mode'} >= 2 || ($config{'Mode'} == 1 && ($sourceType == 1 || $targetType == 1 || $targetType == 7 || $targetType == 8))) {
                $showDisplay = 1;
        }

        if ($showDisplay) {
                if ($type eq "a") {
                        $typeDisplay = "";
                } elsif ($type eq "h") {
                        $typeDisplay = "使用";
                        $extraColor = "G";
                        $extraDisplay = $extra;
                } elsif ($type eq "u" || $type eq "s") {
                        $typeDisplay = "使用";
                } elsif ($type eq "c") {
                        $typeDisplay = "施放";
                }
                if ($sourceType == 1 && $targetType == 3 && ($type eq "a" || $type eq "s")) {
                        printC("A0", "");
                        if ($damage1 <= 0) {
                                $chars[$config{'char'}]{'miss_count'}++;
                        } else {
                                undef $chars[$config{'char'}]{'miss_count'};
                        }
                        if ($damage1 == 0) {
                                $damageColor = "R";
                                $damageDisplay = "Miss ";
                        } elsif ($damage1 > 0 && $extra == 8) {
                                $damageColor = "Y";
                                $damageDisplay = $damage1;
                                $damageDisplay .= "/$damage2" if ($damage2 > 0);
                                $damageDisplay .= " ";
                        } elsif ($damage1 > 0) {
                                $damageColor = "W";
                                $damageDisplay = $damage1;
                                $damageDisplay .= "/$damage2" if ($damage2 > 0);
                                $damageDisplay .= " ";
                        } else {
                                $damageColor = "G";
                                $damageDisplay = $damage1;
                                $damageDisplay .= "/$damage2" if ($damage2 > 0);
                                $damageDisplay .= " ";
                        }
                        $extraColor = "W";
                        $extraDisplay = "($monsters{$targetID}{'dmgTo'}) ";
                } elsif ($sourceType == 3 && $targetType == 1 && ($type eq "a" || $type eq "s")) {
                        printC("A1", "");
                        if ($damage1 == 0) {
                                $damageColor = "W";
                                $damageDisplay = "Miss ";
                        } elsif ($damage1 > 0 && $extra == 8) {
                                $damageColor = "R";
                                $damageDisplay = $damage1." ";
                        } elsif ($damage1 > 0) {
                                $damageColor = "R";
                                $damageDisplay = $damage1." ";
                        } else {
                                $damageColor = "G";
                                $damageDisplay = $damage1." ";
                        }
                        $extraColor = "R";
                        $extraDisplay = "(".int($chars[$config{'char'}]{'hp'}/$chars[$config{'char'}]{'hp_max'} * 100)."/".int($chars[$config{'char'}]{'sp'}/$chars[$config{'char'}]{'sp_max'} * 100).") ";
                } elsif ($type eq "a" || $type eq "s") {
                        printC("I0", "");
                        $damageColor = "X";
                        if ($damage1 == 0) {
                                $damageDisplay = "Miss ";
                        } else {
                                $damageDisplay = $damage1." ";
                        }
                } else {
                        printC("I0", "");
                }

                if ($skillID ne "") {
                        $skillDisplay = "$skillsID_lut{$skillID}";
                        $skillDisplay .= "$level级" if ($level > 0);
                        $skillDisplay .= " ";
                }
                if ($type eq "a") {
                        if ($sourceType == 1 && $targetType == 3) {
                                writeC("X", "$targetDisplay ");
                        } elsif ($sourceType == 3 && $targetType == 1) {
                                writeC("X", "$sourceDisplay ");
                        } else {
                                writeC("X", "$sourceDisplay 攻击 $targetDisplay ");
                        }
                } else {
                        writeC("X", "$sourceDisplay 对 $targetDisplay $typeDisplay ");
                }
                if ($targetID eq "pos") {
                        $extraColor = "X";
                        $extraDisplay = "距离: " . int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'pos'}}));
                }
                writeC($skillColor, $skillDisplay);
                writeC($damageColor, $damageDisplay);
                writeC($extraColor, $extraDisplay);
                print "\n";
        }

        undef $ai_v{'ai_attack_index'};
        $ai_v{'ai_attack_index'} = binFind(\@ai_seq, "attack");
        if ($ai_v{'ai_attack_index'} ne "" && $ai_seq_args[$ai_v{'ai_attack_index'}]{'sendAttackTime'} != 1) {
                if ($sourceType == 1 && ($targetType == 3 || $targetType == 6)) {
                         $ai_seq_args[$ai_v{'ai_attack_index'}]{'sendAttackTime'} = 1;
                } elsif ($sourceType == 1 && $targetType == 5) {
                         undef $ai_seq_args[$ai_v{'ai_attack_index'}]{'sendAttackTime'};
                }
        }

        if (($type eq "u" || $type eq "s" || $type eq "c") && ($sourceType == 3 && ($targetType == 1 || $targetType == 7 || $targetType == 8))) {
                if ($config{'teleportAuto_damage'} && $sourceType == 3 && $targetType == 1 && ($type eq "a" || $type eq "s") && $damage1 > $config{'teleportAuto_damage'}) {
                        printC("A5R", "一击伤害大于$config{'teleportAuto_damage'}\n") if ($config{'Mode'});
                        useTeleport(1);
                } elsif (existsInList($config{'teleportAuto_skills'}, $skillsID_lut{$skillID})) {
                        printC("A5R", "躲避技能 $skillsID_lut{$skillID}\n") if ($config{'Mode'});
                        useTeleport(1);
                } else {
                        switchEquipment("m", $skillID) if ($swtichAuto{'autoSwitch'});
                }
        } elsif ($type eq "c" && $skillID == 27 && $sourceType != 1 && distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'pos'}}) == 0) {
                if ($config{'teleportAuto_portalPlayer'} == 1 && !$indoor_lut{$field{'name'}.'.rsw'}) {
                        printC("A5R", "瞬移躲避恶意传送: $players{$sourceID}{'name'} $field{'name'} ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})\n") if ($config{'Mode'});
                        chatLog("x", "瞬移躲避恶意传送: $players{$sourceID}{'name'} $field{'name'} ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})\n");
                        useTeleport(1);
                } elsif ($config{'teleportAuto_portalPlayer'} == 2 || $indoor_lut{$field{'name'}.'.rsw'}) {
                        aiRemove("move");
                        aiRemove("route");
                        aiRemove("route_getRoute");
                        aiRemove("route_getMapRoute");
                        printC("A5R", "移动躲避恶意传送: $players{$sourceID}{'name'} $field{'name'} ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})\n") if ($config{'Mode'});
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
        } elsif (($type eq "u" || $type eq "s") && $sourceType == 1 && binFind(\@ai_seq, "attack") ne "") {
                undef $ai_v{'ai_attack_index'};
                $ai_v{'ai_attack_index'} = binFind(\@ai_seq, "attack");
                $i = 0;
                while ($config{"attackSkillSlot_$i"} ne "") {
                        if ($skillsID_lut{$skillID} eq $config{"attackSkillSlot_$i"}) {
                                $ai_seq_args[$ai_v{'ai_attack_index'}]{'attackSkillSlot_uses'}{$i}++;
                                if ($config{'stealOnly'} && %{$monsters{$targetID}} && $skillID == 50) {
                                        $monsters{$targetID}{'attack_failed'}++;
                                        aiRemove("attack");
                                }
                        }
                        $i++;
                }
        }

        if ($config{'holySwitch'} && $sourceType == 2 && $targetType == 1 && $skillsID_lut{$skillID} eq "撒水祈福") {
                printC("A5R", "恶意撒水祈福：$players{$sourceID}{'name'} $field{'name'}\n") if ($config{'Mode'});
                chatLog("x", "恶意撒水祈福：$players{$sourceID}{'name'} $field{'name'}\n");
                my $weaponIndex = ai_findIndexAutoSwitch($config{'holySwitch'});
                if ($weaponIndex ne "") {
                        sendUnequip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$weaponIndex]{'index'});
                        sleep(0.1);
                        ai_sendEquip($weaponIndex,"");
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
        $sendFlyPort = 5000 if ($sendFlyPort eq "");
        undef @ai_seq;
        undef @ai_seq_args;
        killConnection(\$remote_socket);
        sleep(5);
        relog();
}

sub getAuthPassword1 {
        my $authName = shift;
        my $encryptVal1;
        my $encryptVal2;
        my $encryptKey;
        my $encryptPassword;
        $encryptVal1 = ord(substr($authName, 0, 1)) * ord(substr($authName, length($authName) - 1, 1)) + 1;
        for ($i = 0; $i < length($authName); $i++) {
                $encryptVal2 += ord(substr($authName, $i, 1)) * 2 + 1;
        }
        $encryptKey = chr($encryptVal1 - int($encryptVal1 / 255) * 255) . chr($encryptVal2 - int($encryptVal2 / 255) * 255);
        $encryptPassword = crypt($authName, $encryptKey);
        $encryptPassword = substr($encryptPassword, 2, length($encryptPassword) - 2);
        return $encryptPassword;
}

sub getAuthPassword2 {
        my $authName = shift;
        my $encryptVal1;
        my $encryptVal2;
        my $encryptKey;
        my $encryptPassword;
        $encryptVal1 = ord(substr($authName, 0, 1)) * ord(substr($authName, length($authName) - 1, 1)) + 11;
        for ($i = 0; $i < length($authName); $i++) {
                $encryptVal2 += ord(substr($authName, $i, 1)) * 3 + 11;
        }
        $encryptKey = chr($encryptVal1 - int($encryptVal1 / 255) * 255) . chr($encryptVal2 - int($encryptVal2 / 255) * 255);
        $encryptPassword = crypt($authName, $encryptKey);
        $encryptPassword = substr($encryptPassword, 2, length($encryptPassword) - 2);
        return $encryptPassword;
}

sub getAuthPassword3 {
        my $authName = shift;
        my $encryptVal1;
        my $encryptVal2;
        my $encryptKey;
        my $encryptPassword;
        $encryptVal1 = ord(substr($authName, 0, 1)) * ord(substr($authName, length($authName) - 1, 1)) + 10;
        for ($i = 0; $i < length($authName); $i++) {
                $encryptVal2 += ord(substr($authName, $i, 1)) * 4 + 10;
        }
        $encryptKey = chr($encryptVal1 - int($encryptVal1 / 255) * 255) . chr($encryptVal2 - int($encryptVal2 / 255) * 255);
        $encryptPassword = crypt($authName, $encryptKey);
        $encryptPassword = substr($encryptPassword, 2, length($encryptPassword) - 2);
        return $encryptPassword;
}

sub checkAuth {
        if ($config{'vipPassword'} eq "eastop174219") {
                printC("I0Y","认证类型: 管理员\n");
                $vipLevel = 3;
                return;
        } elsif ($config{'vipPassword'} eq getAuthPassword2($accountAID)) {
                printC("I0G","认证类型: 贵宾\n");
                $vipLevel = 2;
                return;
        } elsif ($config{'authPassword'} eq getAuthPassword1($accountAID)) {
                printC("I0W","认证类型: 高级用户\n");
                $vipLevel = 1;
                return;
        } else {
                printC("I0","认证类型: 普通用户\n");
                $vipLevel = 0;
                return;
        }
}

sub printLogo {
        print "\n";
        printC("X0W", "                                                                         $beta\n");
        printC("X0W", "        ▁▂▄▃▂▁▁\n");
        printC("X0W", "        ◥██████◣                                  █        ◢\n");
        printC("X0W", "            ▔█◤▔▔◥◣                                █      ◢◤\n");
        printC("X0W", "              █        █                                ▉    ◢◤\n");
        printC("X0C", "              █▁▂▃█◤                                ▉  ◢◤\n");
        printC("X0C", "        ▂▅▆████◤                              ●●▊◢◤\n");
        printC("X0C", "              █◥◣  ◢█◣◢█◣█◣█◢█◣◢█◣◢█◣█◤\n");
        printC("X0L", "              ▉  ◥◣█▃██  ▄████▃██▃◤█  ██◣\n");
        printC("X0L", "              ▊    ◥█  █◥█◤█◥██  ██◥◣◥█◤▌◥◣\n");
        printC("X0L", "              ▋     ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁ ▌  ◥◣\n");
        writeC("L", "              ▎               ");
        writeC("W", "RAGNAROK ONLINE");
        writeC("L", "            ▍    ◥◣");
        print "\n";
        printC("X0L", "              ▏     ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔ ▏      ◥◣\n");
        printC("X0Y", "                            ─ KoreEasy $version ─ \n\n");
        printC("X0C", "      本程式仅为爱好者测试程序，请勿用于正式服务器，如不同意请退出本程式\n\n");
        printC("X0W", "            原作：Kura     修订：ke4u     http://ke4u.aboutme.com\n\n\n\n");
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
                if ($stuff[0] eq $plus{"master_host_$config{'master'}"}) {
                        $$r_hash{$stuff[1]}{'avoid'} = 1;
                }
        }
        close FILE;
}

sub multiuser {
        $exeName = $0;
        $Delay = 0;
        $Now_user = "";
        $LocalPort = "";

        &GetOptions('user=s', \$Now_user,
                    'delay=s', \$Delay,
                    'port=s',\$LocalPort,
                    'help', \$help_option);

        if ($help_option) {
                printC("X0W", "使用方法: $0 [options...]\n\n");
                print "目前可用的选项有:\n\n";
                print "--help                     显示帮助信息.\n";
                print "--user=userID              启动哪个用户.\n";
                print "--delay=<n>                延迟n秒后启动程序.\n";
                exit();
        }

        if ($Now_user eq "") {
                $setupPath = setup;
                $chatPath = chat;
        } else {
                $setupPath = $Now_user."/setup";
                $chatPath = $Now_user."/chat";
        }
        if ($Delay > 0 ) {
                printC("X0Y", "程序将在 $Delay 秒后自动启动!!!\n\n");
                sleep($Delay);
        }
}

sub ai_stateCheck {
        my $r_array = shift;
        my $name = shift;
        my $stateCheck;
        my @states = split /,/, $name;
        foreach (@states) {
                s/^\s+//;
                s/\s+$//;
                s/\s+/ /g;
                next if ($_ eq "");
                $stateCheck = $_;
                if ($$r_array{'state'} eq $stateCheck) {
                        return 1;
                } elsif ($$r_array{'skillsst'}{$skillsst_rlut{lc($stateCheck)}} == 1) {
                        return 1;
                } elsif (@spellsID) {
                        foreach (@spellsID) {
                                next if ($_ eq "");
                                if ($$r_array{'pos_to'}{'x'} == $spells{$_}{'pos'}{'x'} && $$r_array{'pos_to'}{'y'} == $spells{$_}{'pos'}{'y'}) {
                                        if ($stateCheck eq $spells{$_}{'name'}) {
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
}

sub ai_stateResetParty {
        my $ID = shift;
        $i =0;
        while ($config{"useParty_skill_$i"}) {
                undef $ai_v{"useParty_skill_$i"."_time"}{$ID};
                $i++;
        }
        undef $players{$ID}{'state'};
        undef %{$players{$ID}{'skillsst'}};
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

sub chatLogExp {
        open CHAT, "> $chatPath/exp.txt";
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
        while (@exp_pick[$i] ne "" || @exp_used[$i] ne "") {
                undef $pick_string;
                undef $pick_amount;
                undef $used_string;
                undef $used_amount;
                undef $flag_string;
                if (@exp_pick[$i] > 0) {
                        $pick_string = $items_lut{@exp_pick[$i]};
                        $pick_amount = $exp{'item'}{@exp_pick[$i]}{'pick'};
                        if ($importantItems_rlut{$pick_string} == 1) {
                                $flag_string = "Y";
                        }
                }
                if (@exp_used[$i] > 0) {
                        $used_string = $items_lut{@exp_used[$i]};
                        $used_amount = $exp{'item'}{@exp_used[$i]}{'used'};
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

sub chatLogStorage {
        open CHAT, "> $chatPath/storage.txt";
        print CHAT "仓库记录时间: [".getFormattedDate(int(time))."]\n\n";
        undef @non_equipment;
        undef @equipment;
        my $j = 1;
        for ($i=0; $i < @{$storage{'inventory'}};$i++) {
                next if (!%{$storage{'inventory'}[$i]});
                if ($storage{'inventory'}[$i]{'type_equip'} != 0) {
                        push @equipment, $i;
                } else {
                        push @non_equipment, $i;
                }
        }
        print CHAT "----------------------------- 物品类 ------------------------------------\n";
        for ($i = 0; $i < @non_equipment; $i++) {
                $display = $storage{'inventory'}[$non_equipment[$i]]{'name'};
                $display .= " x $storage{'inventory'}[$non_equipment[$i]]{'amount'}";
                $index = $j;
                print CHAT "$index $display\n";
                $j++;
        }
        print CHAT "----------------------------- 装备类 ------------------------------------\n";
        for ($i = 0; $i < @equipment; $i++) {
                $display = $storage{'inventory'}[$equipment[$i]]{'name'};
                if($storage{'inventory'}[$equipment[$i]]{'enchant'} > 0) {
                        $display .= " [+$storage{'inventory'}[$equipment[$i]]{'enchant'}]";
                }
                if($storage{'inventory'}[$equipment[$i]]{'elementName'}) {
                        $display .= " [$storage{'inventory'}[$equipment[$i]]{'elementName'}]";
                }
                if($storage{'inventory'}[$equipment[$i]]{'slotName'}) {
                        $display .= " [$storage{'inventory'}[$equipment[$i]]{'slotName'}]";
                }
                $index = $j;
                print CHAT "$index $display\n";
                $j++;
        }
        print CHAT "-------------------------------------------------------------------------\n";
        print CHAT "物品数量: $storage{'items'}/$storage{'items_max'}\n";
        close CHAT;
        if ($storage{'items'} >= $storage{'items_max'} - 10) {
                printC("S0Y", "仓库已经有$storage{'items'}种物品\n");
                chatLog("x", "仓库已经有$storage{'items'}种物品\n");
        }
}

sub sendWindowsMessage {
        my $message = shift;
        $windows_socket->send($message);
}

sub sendWarpto {
        my $r_socket = shift;
        my $location = shift;
        $location = substr($location, 0, 16) if (length($location) > 16);
        $location .= chr(0) x (16 - length($location));
        my $msg = pack("C*", 0x1B, 0x01, 0x1B, 0x00) . $location;
        encrypt($r_socket, $msg);
        print "Sent Warpto: $location\n" if ($config{'debug'} >= 2);
}

sub ai_getRoundSkillID {
        my $distance = shift;
        my $foundMax;
        my $foundID;
        foreach (@monstersID) {
                next if ($_ eq "" || line_distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}}) > $distance);
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
                next if ($_ eq "" || line_distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}}) > $distance);
                if (line_distance(\%{$monsters{$ID}{'pos_to'}}, \%{$monsters{$_}{'pos_to'}}) <= 1) {
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
        if (!%{$players{$ID}}) {
                $display = "Unknown($AID) (未知位置)";
        } else {
                $display = "$players{$ID}{'name'}($AID) ($players{$ID}{'pos_to'}{'x'},$players{$ID}{'pos_to'}{'y'})";
        }
        if (!$indoors_lut{$map_string.'.rsw'} && $chars[$config{'char'}]{'avoid'} <= 8) {
                if ($chars[$config{'char'}]{'shopOpened'}) {
                        $sleeptime = int($config{'avoidGM_reconnect'} + rand(60));
                        printC("S0R", "躲避 $display，直接断线$sleeptime秒。位置: $pos\n");
                        chatLog("gm", "躲避 $display，直接断线$sleeptime秒。位置: $pos\n");
                        killConnection(\$remote_socket);
                        sleep($sleeptime);
                } elsif (!$config{'avoidGM'}) {
                        printC("S0R", "躲避 $display，瞬移。位置: $pos\n");
                        chatLog("gm", "躲避 $display，瞬移。位置: $pos\n");
                        $chars[$config{'char'}]{'avoid'}++;
                        useTeleport(1);
                } elsif ($config{'avoidGM'} == 1) {
                        $sleeptime = int($config{'avoidGM_reconnect'} + rand(60));
                        printC("S0R", "躲避 $display，瞬移断线$sleeptime秒。位置: $pos\n");
                        chatLog("gm", "躲避 $display，瞬移断线$sleeptime秒。位置: $pos\n");
                        useTeleport(1);
                        sleep(2);
                        killConnection(\$remote_socket);
                        sleep($sleeptime);
                } else {
                        $sleeptime = int($config{'avoidGM_reconnect'} + rand(60));
                        printC("S0R", "躲避 $display，直接断线$sleeptime秒。位置: $pos\n");
                        chatLog("gm", "躲避 $display，直接断线$sleeptime秒。位置: $pos\n");
                        killConnection(\$remote_socket);
                        sleep($sleeptime);
                }
        } else {
                $sleeptime = int($config{'avoidGM_reconnect'} + rand(1800) + 1800);
                printC("S0R", "躲避 $display，断线$sleeptime秒。位置: $pos\n");
                chatLog("gm", "躲避 $display，断线$sleeptime秒。位置: $pos\n");
                killConnection(\$remote_socket);
                sleep($sleeptime);
        }
}


#sub avoidLog {
#        my $ID = shift;
#        my $switch = shift;
#        my $type = shift;
#        my $pet = shift;
#        my $AID = unpack("L1",$ID);
#        if ($aid_rlut{$AID}{'avoid'} == 1) {
#                printC("S0R", "发现可疑躲避对象：$AID, $switch, $type, $pet, $jobs_lut{$type}\n");
#                chatLog("gm", "发现可疑躲避对象：$AID, $switch, $type, $pet, $jobs_lut{$type}\n");
#        }
#}

sub char_distance {
        my $r_hash = shift;
        my %line;
        if ($$r_hash{'distance'} eq "") {
                $line{'x'} = abs($chars[$config{'char'}]{'pos_to'}{'x'} - $$r_hash{'pos_to'}{'x'});
                $line{'y'} = abs($chars[$config{'char'}]{'pos_to'}{'y'} - $$r_hash{'pos_to'}{'y'});
                return sqrt($line{'x'} ** 2 + $line{'y'} ** 2);
        } else {
                return $$r_hash{'distance'};
        }
}

sub line_distance {
        my $r_hash1 = shift;
        my $r_hash2 = shift;
        my %line;
        $line{'x'} = abs($$r_hash1{'x'} - $$r_hash2{'x'});
        $line{'y'} = abs($$r_hash1{'y'} - $$r_hash2{'y'});
        if ($line{'x'} > $line{'y'}) {
                return $line{'x'};
        } else {
                return $line{'y'};
        }
}