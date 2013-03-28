BEGIN {
	mkdir('logs', 0777) || die "Can not create the log directory : logs" unless (-e 'logs');
        open "STDERR", "> logs/errors.txt" or die "Could not write to errors.txt: $!\n";
}

#########################################################################
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################

require 'KoreEasy_config.pl';
require 'KoreEasy_parseFiles.pl';
require 'KoreEasy_parseInput.pl';
require 'KoreEasy_parseMessage.pl';
require 'KoreEasy_sendMessage.pl';
require 'KoreEasy_AI.pl';
require 'KoreEasy_AIFunctions.pl';
require 'KoreEasy_functions.pl';
require 'KoreEasy_addon.pl';
require 'KoreEasy_auth.pl';


#######################################
#MAIN PROGRAM
#######################################
use Time::HiRes qw(time usleep);
use Getopt::Long;
use IO::Socket;
use IO::Socket::Socks;
use Digest::MD5 qw(md5 md5_hex);
use Win32::Console;
use Win32::API;

our $CONSOLE = new Win32::Console(STD_OUTPUT_HANDLE) || die "Could not init Console Attribute";
die if ($@);

  $CalcPath_init = new Win32::API("lib\\Tools", "CalcPath_init", "PPNNPPN", "N") || die "Could not locate Tools.dll";
  $CalcPath_pathStep = new Win32::API("lib\\Tools", "CalcPath_pathStep", "N", "N") || die "Could not locate Tools.dll";
  $CalcPath_destroy = new Win32::API("lib\\Tools", "CalcPath_destroy", "N", "V") || die "Could not locate Tools.dll";
	$input_init = new Win32::API("lib\\Tima", "InitInput", "P", "N") || die "Could not locate Tima.dll";
	$input_recv = new Win32::API("lib\\Tima", "GetInput", "PN", "N") || die "Could not locate Tima.dll";
	$input_release = new Win32::API("Tima", "ForceReleaseInput", "", "") || die "Could not locate Tima.dll";

#Command Line
        our $user = ".";
        &GetOptions('user=s', \$user,
                            'help', \$help_option);
        if ($help_option) {
                print "使用方法: KoreEasy.exe [options...]\n\n";
                print "目前可用的选项有:\n\n";
                print "--user=userID\t启动哪个用户.\n";
                print "--help\t显示帮助信息.\n";
                exit(1);
        }
        our $setup_path = $user."/setup";
        our $logs_path = $user."/logs";
        mkdir($logs_path, 0777) || die "Can not create the log directory : $logs_path" unless (-e $logs_path);

#cock
srand(time());
our $proto = getprotobyname('tcp');
our $MAX_READ = 10240;

our $versionText = "$KoreEasy_version $main_version $beta_version - http://www.mu20.com - ICE-WR\n\n";
our $welcomeText = "[KE] : 欢迎使用 $KoreEasy_version $main_version $beta_version - http://www.mu20.com - ICE-WR";

printLogo();

#Pares Files
        addParseFiles("$setup_path/config.txt", \%config, \&parseDataFile2);
        addParseFiles("$setup_path/items_control.txt", \%items_control, \&parseItemsControl);
        addParseFiles("$setup_path/mon_control.txt", \%mon_control, \&parseMonControl);
        addParseFiles("$setup_path/pickup_control.txt", \%itemsPickup, \&parseDataFile_lc);
        addParseFiles("$setup_path/shop_control.txt", \%shop_control, \&parseDataFile2);
        addParseFiles("$setup_path/timeouts.txt", \%timeout, \&parseTimeouts);

        addParseFiles("data/monstertypes.txt", \%monsterTypes_lut, \&parseDataFile_lc);
        addParseFiles("data/avoidaid.txt", \%aid_rlut, \&parseAidRLUT);
        addParseFiles("data/avoidlist.txt", \%avoidlist_rlut, \&parsePlusRLUT);
        addParseFiles("data/cards.txt", \%cards_lut, \&parseROLUT);
        addParseFiles("data/cities.txt", \%cities_lut, \&parseROLUT);
        addParseFiles("data/elements.txt", \%elements_lut, \&parseROLUT);
        addParseFiles("data/emotions.txt", \%emotions_lut, \&parseDataFile2);
        addParseFiles("data/equiptypes.txt", \%equipTypes_lut, \&parseDataFile2);
        addParseFiles("data/items.txt", \%items_lut, \&parseROLUT);
	    addParseFiles("data/itemslots.txt", \%itemSlots_lut, \&parseROSlotsLUT);
        addParseFiles("data/itemtypes.txt", \%itemTypes_lut, \&parseDataFile2);
        addParseFiles("data/jobs.txt", \%jobs_lut, \&parseDataFile2);
        addParseFiles("data/maps.txt", \%maps_lut, \&parseROLUT);
        addParseFiles("data/monsters.txt", \%monsters_lut, \&parseDataFile2);
        addParseFiles("data/npcs.txt", \%npcs_lut, \&parseNPCs);
        addParseFiles("data/portals.txt", \%portals_lut, \&parsePortals);
        addParseFiles("data/portalsLOS.txt", \%portals_los, \&parsePortalsLOS);
        addParseFiles("data/responses.txt", \%responses, \&parseResponses);
        addParseFiles("data/sex.txt", \%sex_lut, \&parseDataFile2);
        addParseFiles("data/skills.txt", \%skills_lut, \&parseSkillsLUT);
        addParseFiles("data/skills.txt", \%skillsID_lut, \&parseSkillsIDLUT);
        addParseFiles("data/skills.txt", \%skills_rlut, \&parseSkillsReverseLUT_lc);
        addParseFiles("data/skillssp.txt", \%skillsSP_lut, \&parseSkillsSPLUT);
        addParseFiles("data/mapserver.txt", \%mapserver_lut, \&parseROLUT);
        addParseFiles("data/mapip.txt", \%mapip_lut, \&parseMapIP);
        addParseFiles("data/indoors.txt", \%indoors_lut, \&parseROLUT);
        addParseFiles("data/msgstrings.txt", \%msgstrings_lut, \&parseMsgLUT);
        addParseFiles("data/msgstrings.txt", \%msgstrings_rlut, \&parseMsgReverseLUT);        
        addParseFiles("data/recvpackets.txt", \%rpackets, \&parseDataFile2);
        load(\@parseFiles);
        
        dynParseFiles("$setup_path/mvp_control.txt", \%mvp, \&parseDataFile2) if ($config{'mvpMode'});
        dynParseFiles("$logs_path/mvptime.txt", \%mvptime, \&parseDataFile2) if ($config{'mvpMode'} >= 2);
        $master_host = $config{"master_host_$config{'master'}"};
        
#Auto generating admin password
if ($config{'adminPassword'} eq 'x' x 10 || $config{'adminPassword'} eq '') {
	print "\n";
        printc("yw", "<系统> ", "自动生成管理员密码...\n");
        configModify("adminPassword", vocalString(8));
}
print "\n";

          
             
###INIT SOCKET###

our $input_socket = $input_init->Call(pack("a16", "quit#dump#reboot"));
($input_socket) || die "Error creating input interface: $!";
printc("yn", "<系统> ", "初始化输入接口完成\n");

our $remote_socket = IO::Socket::INET->new();

if ($config{'XKore'}) {
	our $xKore = $config{'XKore'};
	our $injectServer_socket = IO::Socket::INET->new(
				Listen		=> 5,
				LocalAddr	=> 'localhost',
				LocalPort	=> 2350,
				Proto		=> 'tcp',
				Timeout		=> 999,
				Reuse		=> 1);
	($injectServer_socket) || die "Error creating local inject server: $!";
        printc("yn", "<系统> ", "初始化内挂连接完成 (".$injectServer_socket->sockhost().":2350)\n");
        our $cwd = Win32::GetCwd();
        our $injectDLL_file = $cwd."\\lib\\Inject.dll";
        $GetProcByName = new Win32::API("lib\\Tools", "GetProcByName", "P", "N") || die "Could not locate Tools.dll";
}
print "\n";
         


###COMPILE PORTALS###

printc("yn", "<系统> ", "正在检查新的地图传送点...");
compilePortals_check(\$found);

if ($found) {
        printc("y", "发现新传送点\n");
        printc("ynw", "<系统> ", "将在$timeout{'compilePortals_auto'}{'timeout'}秒后自动执行编译...", "现在进行编译吗？(y/n) ");
        $timeout{'compilePortals_auto'}{'time'} = time;
        undef $msg;
        while (!timeOut(\%{$timeout{'compilePortals_auto'}})) {
        	usleep($config{'sleepTime'});
		$msg = "\0" x 256;
		$msgLen = $input_recv->Call($msg, 0);
                if ($msgLen != -1) {
                	$msg = substr($msg, 0, $msgLen);
                	last;
                } else {
                	undef $msg;
		}
        }
        if ($msg =~ /y/ || $msg eq "") {
                printc("yw", "<系统> ", "开始编译\n\n");
                compilePortals();
        } else {
        	print "\n" if ($msg eq "");
                printc("yr", "<系统> ", "跳过编译\n\n");
        }
} else {
        printc("n", "没有发现\n");
}

if (!$xKore) {
        if (!$config{'username'}) {
                printc("yw", "<系统> ", "请输入用户名: \n");
		$msg = "\0" x 256;
		$msgLen = $input_recv->Call($msg, 1);
		$msg = substr($msg, 0, $msgLen);
                $config{'username'} = $msg;
                writeDataFileIntact("$setup_path/config.txt", \%config);
        }
        if (!$config{'password'}) {
                printc("yw", "<系统> ", "请输入密码: \n");
		$msg = "\0" x 256;
		$msgLen = $input_recv->Call($msg, 1);
		$msg = substr($msg, 0, $msgLen);
                $config{'password'} = encodePassword($msg);
                writeDataFileIntact("$setup_path/config.txt", \%config);
        }
        if ($config{'master'} eq "") {
                $i = 0;
                print "--------- Master Servers ----------\n";
                print "#         Name\n";
                while ($config{"master_name_$i"} ne "") {
                	print sprintf("%-3d %-40s\n", $i, $config{"master_name_$i"});
                        $i++;
                }
                print "-------------------------------\n";
                printc("yw", "<系统> ", "请选择主服务器: \n");
		$msg = "\0" x 256;
		$msgLen = $input_recv->Call($msg, 1);
		$msg = substr($msg, 0, $msgLen);
                $config{'master'} = $msg;
                writeDataFileIntact("$setup_path/config.txt", \%config);
        }
} else {
        $timeout{'injectSync'}{'time'} = time;
}
print "\n";

undef $msg;
our $KoreStartTime = time;
our $AI = 1;
our $conState = 1;

#initStatVars();
#initRandomRestart();

while ($quit != 1) {
        usleep($config{'sleepTime'});

        if ($xKore) {
                if (timeOut(\%{$timeout{'injectKeepAlive'}})) {
                        $conState = 1;
                        undef $msg;
                        my $printed = 0;
                        my $procID = 0;
                        do {
                                $procID = $GetProcByName->Call($config{'exeName'});
                                if (!$procID) {
                                        printc("yr", "<错误> ", "不能找到进程 $config{'exeName'}\n") if (!$printed);;
                                        printc("yw", "<系统> ", "请运行游戏客户端...\n") if (!$printed);
                                        $printed = 1;
                                }
                                sleep 2;
                        } while (!$procID);

                        if ($printed == 1) {
                                printc("yc", "<系统> ", "游戏客户端正在运行\n");
                        }
                        my $InjectDLL = new Win32::API("lib\\Tools", "InjectDLL", "NP", "I") || die "Could not locate Tools.dll";
                        my $retVal = $InjectDLL->Call($procID, $injectDLL_file);
                        die "Could not inject DLL" if ($retVal != 1);

                        printc("yn", "<系统> ", "正在建立内挂连接...\n");
                        $remote_socket = $injectServer_socket->accept();
                        (inet_aton($remote_socket->peerhost()) == inet_aton('localhost')) || die "Inject Socket must be connected from localhost";
                        printc("yy", "<系统> ", "内挂连接建立成功\n");
                        $timeout{'injectKeepAlive'}{'time'} = time;
                }
                if (timeOut(\%{$timeout{'injectSync'}})) {
                        sendSyncInject(\$remote_socket);
                        $timeout{'injectSync'}{'time'} = time;
                }
        }

	$tmp_input = "\0" x 256;
	$inputLen = $input_recv->Call($tmp_input, 0);
	if ($inputLen != -1) {
		$tmp_input = substr($tmp_input, 0, $inputLen);
		parseInput($tmp_input);
        } elsif (dataWaiting(\$window_socket)) {
                $window_socket->recv($input, $MAX_READ);
                parseInput($input);
        } elsif (!$xKore && dataWaiting(\$remote_socket)) {
                $remote_socket->recv($new, $MAX_READ);
                $msg .= $new;
                $msg_length = length($msg);
                while ($msg ne "") {
                        $msg = parseMsg($msg);
                        last if ($msg_length == length($msg));
                        $msg_length = length($msg);
                        #usleep(1000) if ($last_know_switch ne "00B0" && $config{'sleepTime'} > 30000);
                }
        } elsif ($xKore && dataWaiting(\$remote_socket)) {
                my $injectMsg;
                $remote_socket->recv($injectMsg, $MAX_READ);
                while ($injectMsg ne "") {
                        if (length($injectMsg) < 3) {
                                undef $injectMsg;
                                break;
                        }
                        my $type = substr($injectMsg, 0, 1);
                        my $len = unpack("S",substr($injectMsg, 1, 2));
                        my $newMsg = substr($injectMsg, 3, $len);
                        $injectMsg = (length($injectMsg) >= $len+3) ? substr($injectMsg, $len+3, length($injectMsg) - $len - 3) : "";
                        if ($type eq "R") {
                                $msg .= $newMsg;
                                $msg_length = length($msg);
                                while ($msg ne "") {
                                        $msg = parseMsg($msg);
                                        last if ($msg_length == length($msg));
                                        $msg_length = length($msg);
                                }
                        } elsif ($type eq "S") {
                                parseSendMsg($newMsg);
                        }
                        $timeout{'injectKeepAlive'}{'time'} = time;
                }
        } elsif ($xKore && @sendToClient_injectQue) {
                $remote_socket->send("R".pack("S", length($sendToClient_injectQue[0])).$sendToClient_injectQue[0]) if ($conState == 5 && $remote_socket && $remote_socket->connected());
                shift @sendToClient_injectQue;
        }
        $ai_cmdQue_shift = 0;
        do {
                AI(\%{$ai_cmdQue[$ai_cmdQue_shift]}) if ($conState == 5 && timeOut(\%{$timeout{'ai'}}) && $remote_socket && $remote_socket->connected());
                undef %{$ai_cmdQue[$ai_cmdQue_shift++]};
                $ai_cmdQue-- if ($ai_cmdQue > 0);
        } while ($ai_cmdQue > 0);
        checkConnection();
}

#close($input_server_socket);
#close($input_socket);
#kill 9, $input_pid;
$input_release->Call();
close($remote_socket);
killConnection(\$remote_socket);
unlink('buffer') if ($xKore && -f 'buffer');
printc("yw", "<系统> ", $versionText);
sleep(2);
exit;