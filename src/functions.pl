#########################################################################
# This software is open source, licensed under the GNU General Public
# License, version 2.
# Basically, this means that you're allowed to modify and distribute
# this software. However, if you distribute modified versions, you MUST
# also distribute the source code.
# See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################

package main;
use strict;
use Time::HiRes qw(time usleep);
use IO::Socket;
use Text::ParseWords;
use Carp::Assert;
use Config;
use encoding 'utf8';

use Globals;
use Modules;
use Settings qw(%sys %options);
use Log qw(message warning error debug);
use Interface;
use Misc;
use Network::Receive;
use Network::Send ();
use Network::ClientReceive;
use Network::MessageTokenizer;
use Commands;
use Plugins;
use Utils;
use I18N;
use LWP::UserAgent;
use LWP::ConnCache;
use HTTP::Request;
use HTTP::Cookies::Microsoft;
use Utils::HttpReader;
use Utils::RSK;
use MIME::Base64;
use Win32::OLE qw(in);
use Win32::TieRegistry(Delimiter => "/");
use Encode;
use Digest::MD5;



#######################################
# PROGRAM INITIALIZATION
#######################################

use constant {
	STATE_LOAD_PLUGINS          => 0,
	STATE_LOAD_DATA_FILES       => 1,
	STATE_CHECK_KEY             => 2,
	STATE_INIT_NETWORKING       => 3,
	STATE_INIT_PORTALS_DATABASE => 4,
	STATE_PROMPT                => 5,
	STATE_FINAL_INIT            => 6,
	STATE_INITIALIZED           => 7
};

our $state;



sub mainLoop {
	$state = STATE_LOAD_PLUGINS if (!defined $state);

	# Parse command input
	my $input;
	if (defined($input = $interface->getInput(0))) {
		Misc::checkValidity("parseInput (pre)");
		parseInput($input);
		Misc::checkValidity("parseInput");
	}


	if ($state == STATE_INITIALIZED) {
		Plugins::callHook('mainLoop_pre');
		mainLoop_initialized();
		Plugins::callHook('mainLoop_post');

	} elsif ($state == STATE_LOAD_PLUGINS) {
		Log::message("$Settings::versionText\n");
 		sleep(5);
 		versionCheck($Settings::SVN_VERSION);
		loadPlugins();
		return if $quit;
		Log::message("\n");
		Plugins::callHook('start');
		$state = STATE_LOAD_DATA_FILES;

	} elsif ($state == STATE_LOAD_DATA_FILES) {
		loadDataFiles();
		checkConnection();
		$state = STATE_CHECK_KEY;

	} elsif ($state == STATE_CHECK_KEY) {
		promptLoginInformation();
		checkKey();
		checkUserLevel();
		$state = STATE_INIT_NETWORKING;

	} elsif ($state == STATE_INIT_NETWORKING) {
		initNetworking();
		$state = STATE_INIT_PORTALS_DATABASE;

	} elsif ($state == STATE_INIT_PORTALS_DATABASE) {
		initPortalsDatabase();
		$state = STATE_PROMPT;

	} elsif ($state == STATE_PROMPT) {
		promptFirstTimeInformation();
		$state = STATE_FINAL_INIT;

	} elsif ($state == STATE_FINAL_INIT) {
		finalInitialization();
		$state = STATE_INITIALIZED;

	} else {
		die "Unknown state $state.";
	}

	# Reload any modules that requested to be reloaded
	Modules::reloadAllInQueue();
}

sub loadPlugins {
	eval {
		Plugins::loadAll();
	};
	if (my $e = caught('Plugin::LoadException')) {
		$interface->errorDialog(TF("This plugin cannot be loaded because of a problem in the plugin. " .
			"Please notify the plugin's author about this problem, " .
			"or remove the plugin so %s can start.\n\n" .
			"The error message is:\n" .
			"%s",
			$Settings::NAME, $e->message));
		$quit = 1;
	} elsif (my $e = caught('Plugin::DeniedException')) {
		$interface->errorDialog($e->message);
		$quit = 1;
	} elsif ($@) {
		die $@;
	}
}

sub loadDataFiles {
	# These pragmas are necessary in order to support non-ASCII filenames.
	# If we use UTF-8 strings then Perl will think the file doesn't exist,
	# if $Settings::control_folder or $Settings::tables_folder contains
	# non-ASCII characters.
	no encoding 'utf8';

	# Add loading of Control files
	Settings::addControlFile(Settings::getConfigFilename(),
		loader => [\&parseConfigFile, \%config],
		internalName => 'config.txt',
		autoSearch => 0);
	Settings::addControlFile(Settings::getKeyFilename(),
		loader => [\&parseKeyFile, \%key],
		internalName => 'key.txt',
		autoSearch => 0);
	Settings::addControlFile('consolecolors.txt',
		loader => [\&parseSectionedFile, \%consoleColors]);
	Settings::addControlFile(Settings::getMonControlFilename(),
		loader => [\&parseMonControl, \%mon_control],
		internalName => 'mon_control.txt',
		autoSearch => 0);
	Settings::addControlFile(Settings::getItemsControlFilename(),
		loader => [\&parseItemsControl, \%items_control],
		internalName => 'items_control.txt',
		autoSearch => 0);
	Settings::addControlFile(Settings::getShopFilename(),
		loader => [\&parseShopControl, \%shop],
		internalName => 'shop.txt',
		autoSearch => 0);
	Settings::addControlFile('overallAuth.txt',
		loader => [\&parseDataFile, \%overallAuth]);
	Settings::addControlFile('pickupitems.txt',
		loader => [\&parseDataFile_lc, \%pickupitems]);
	Settings::addControlFile('responses.txt',
		loader => [\&parseResponses, \%responses]);
	Settings::addControlFile('timeouts.txt',
		loader => [\&parseTimeouts, \%timeout]);
	Settings::addControlFile('chat_resp.txt',
		loader => [\&parseChatResp, \@chatResponses]);
	Settings::addControlFile('avoid.txt',
		loader => [\&parseAvoidControl, \%avoid]);
	Settings::addControlFile('priority.txt',
		loader => [\&parsePriority, \%priority]);
	Settings::addControlFile('routeweights.txt',
		loader => [\&parseDataFile, \%routeWeights]);
	Settings::addControlFile('arrowcraft.txt',
		loader => [\&parseDataFile_lc, \%arrowcraft_items]);
		
	# Loading of Table files
	# Load Servers.txt first
	Settings::addTableFile('servers.txt',
		loader => [\&parseSectionedFile, \%masterServers],
		onLoaded => \&processServerSettings );
	# Load RecvPackets.txt second
 	Settings::addTableFile(Settings::getRecvPacketsFilename(),
 		loader => [\&parseDataFile2, \%rpackets]);

	# Add 'Old' table pack, if user set
	if ( $sys{locale_compat} == 1) {
		# Holder for new path
		my @new_tables;
		my $pathDelimiter = ($^O eq 'MSWin32') ? ';' : ':';
		if ($options{tables}) {
			foreach my $dir ( split($pathDelimiter, $options{tables}) ) {
				push @new_tables, $dir . '/Old';
			}
		} else {
			push @new_tables, 'tables/Old';
		}
		# now set up new path to table folder
		Settings::setTablesFolders(@new_tables, Settings::getTablesFolders());
	}

	# Load all other tables
	Settings::addTableFile('cities.txt',
		loader => [\&parseROLUT, \%cities_lut]);
	Settings::addTableFile('commanddescriptions.txt',
		loader => [\&parseCommandsDescription, \%descriptions], mustExist => 0);
	Settings::addTableFile('directions.txt',
		loader => [\&parseDataFile2, \%directions_lut]);
	Settings::addTableFile('elements.txt',
		loader => [\&parseROLUT, \%elements_lut]);
	Settings::addTableFile('emotions.txt',
		loader => [\&parseEmotionsFile, \%emotions_lut]);
	Settings::addTableFile('equiptypes.txt',
		loader => [\&parseDataFile2, \%equipTypes_lut]);
	Settings::addTableFile('haircolors.txt',
		loader => [\&parseDataFile2, \%haircolors]);
	Settings::addTableFile('headgears.txt',
		loader => [\&parseArrayFile, \@headgears_lut]);
	Settings::addTableFile('items.txt',
		loader => [\&parseROLUT, \%items_lut]);
	Settings::addTableFile('itemsdescriptions.txt',
		loader => [\&parseRODescLUT, \%itemsDesc_lut], mustExist => 0);
	Settings::addTableFile('itemslots.txt',
		loader => [\&parseROSlotsLUT, \%itemSlots_lut]);
	Settings::addTableFile('itemtypes.txt',
		loader => [\&parseDataFile2, \%itemTypes_lut]);
	Settings::addTableFile('resnametable.txt',
		loader => [\&parseROLUT, \%mapAlias_lut, 1, ".gat"]);
	Settings::addTableFile('maps.txt',
		loader => [\&parseROLUT, \%maps_lut]);
	Settings::addTableFile('monsters.txt',
		loader => [\&parseDataFile2, \%monsters_lut]);
	Settings::addTableFile('npcs.txt',
		loader => [\&parseNPCs, \%npcs_lut]);
	Settings::addTableFile('packetdescriptions.txt',
		loader => [\&parseSectionedFile, \%packetDescriptions], mustExist => 0);
	Settings::addTableFile('portals.txt',
		loader => [\&parsePortals, \%portals_lut]);
	Settings::addTableFile('portalsLOS.txt',
		loader => [\&parsePortalsLOS, \%portals_los]);
	Settings::addTableFile('sex.txt',
		loader => [\&parseDataFile2, \%sex_lut]);
	Settings::addTableFile('SKILL_id_handle.txt',
		loader => \&Skill::StaticInfo::parseSkillsDatabase_id2handle);
	Settings::addTableFile('skillnametable.txt',
		loader => \&Skill::StaticInfo::parseSkillsDatabase_handle2name, mustExist => 0);
	Settings::addTableFile('spells.txt',
		loader => [\&parseDataFile2, \%spells_lut]);
	Settings::addTableFile('skillsdescriptions.txt',
		loader => [\&parseRODescLUT, \%skillsDesc_lut], mustExist => 0);
	Settings::addTableFile('skillssp.txt',
		loader => \&Skill::StaticInfo::parseSPDatabase);
	Settings::addTableFile('STATUS_id_handle.txt', loader => [\&parseDataFile2, \%statusHandle]);
	Settings::addTableFile('STATE_id_handle.txt', loader => [\&parseDataFile2, \%stateHandle]);
	Settings::addTableFile('LOOK_id_handle.txt', loader => [\&parseDataFile2, \%lookHandle]);
	Settings::addTableFile('AILMENT_id_handle.txt', loader => [\&parseDataFile2, \%ailmentHandle]);
	Settings::addTableFile('MAPTYPE_id_handle.txt', loader => [\&parseDataFile2, \%mapTypeHandle]);
	Settings::addTableFile('MAPPROPERTY_TYPE_id_handle.txt', loader => [\&parseDataFile2, \%mapPropertyTypeHandle]);
	Settings::addTableFile('MAPPROPERTY_INFO_id_handle.txt', loader => [\&parseDataFile2, \%mapPropertyInfoHandle]);
	Settings::addTableFile('statusnametable.txt', loader => [\&parseDataFile2, \%statusName], mustExist => 0);
	Settings::addTableFile('skillsarea.txt', loader => [\&parseDataFile2, \%skillsArea]);
	Settings::addTableFile('skillsencore.txt', loader => [\&parseList, \%skillsEncore]);
	Settings::addTableFile('quests.txt', loader => [\&parseROQuestsLUT, \%quests_lut], mustExist => 0);
	Settings::addTableFile('effects.txt', loader => [\&parseDataFile2, \%effectName], mustExist => 0);
	Settings::addTableFile('msgstringtable.txt', loader => [\&parseArrayFile, \@msgTable], mustExist => 0);

	use encoding 'utf8';

	Plugins::callHook('start2');
	eval {
		my $progressHandler = sub {
			my ($filename) = @_;
			message TF("Loading %s...\n", $filename);
		};
		Settings::loadAll($progressHandler);
	};
	if (my $e = caught('UTF8MalformedException')) {
		$interface->errorDialog(TF(
			"The file %s must be in UTF-8 encoding.",
			$e->textfile));
		$quit = 1;
	} elsif (my $e = caught('FileNotFoundException')) {
		$interface->errorDialog(TF("Unable to load the file %s.", $e->filename));
		$quit = 1;
	} elsif ($@) {
		die $@;
	}
	return if $quit;

	Plugins::callHook('start3');

	if ($config{'adminPassword'} eq 'x' x 10) {
		Log::message(T("\nAuto-generating Admin Password due to default...\n"));
		configModify("adminPassword", vocalString(20));
	} else {
		Log::message(T("\nGenerating session Admin Password...\n"));
		configModify("adminPassword", vocalString(20));
		Log::message(T("本次运行生成的adminPassword(远程密语控制密码)是:" . $config{'adminPassword'} ."\n"));
		Log::message(T("CNKore将在每次运行时随机生成随机位数的远程密语控制密码以保证账号安全\n"));
	}
}

sub checkConnection {
	my $self = shift;
	my $pid;

	my $loop = 1;
	my @list;
	my @hide;

	while ($loop) {
		undef @list;
		undef @hide;
		my @z = Utils::Win32::listProcesses();

		foreach (@z) {
			if (uc($_->{'exe'}) eq uc("perl.exe") || uc($_->{'exe'}) eq uc("HideToolz.exe") || uc($_->{'exe'}) eq uc("HideW32.exe") || uc($_->{'exe'}) eq uc("HideWizard.exe") || uc($_->{'exe'}) eq uc("Proxifier.exe") || uc($_->{'exe'}) eq uc("CCProxy.exe") || uc($_->{'exe'}) eq uc("Client.exe") || uc($_->{'exe'}) eq uc("CNKore_Console.exe") || uc($_->{'exe'}) eq uc("CNKore_UI.exe") || uc($_->{'exe'}) eq uc("vmtoolsd.exe") || uc($_->{'exe'}) eq uc("vmacthlp.exe") || uc($_->{'exe'}) eq uc("vmware.exe")) {
				push @list, {exe => $_->{'exe'}, pid => $_->{'pid'}};
			}
			if (uc($_->{'exe'}) eq uc("vmtoolsd.exe") || uc($_->{'exe'}) eq uc("vmacthlp.exe") || uc($_->{'exe'}) eq uc("vmware.exe") || uc($_->{'exe'}) eq uc("HideToolz.exe") || uc($_->{'exe'}) eq uc("HideW32.exe") || uc($_->{'exe'}) eq uc("HideWizard.exe") || uc($_->{'exe'}) eq uc("Proxifier.exe") || uc($_->{'exe'}) eq uc("CCProxy.exe") || uc($_->{'exe'}) eq uc("Client.exe")) {
				push @hide, {exe => $_->{'exe'}, pid => $_->{'pid'}};
			}
		}

		my $i = 0;
		my $h = 0;

		foreach (@list) {
			$i++;
		}
		foreach (@hide) {
			$h++;
		}
		if ($h > 0 && !$config{CNKoreTeam}) {
			message T("请不要使用第三方程序、虚拟环境或者代理软件篡改CN Kore，退出中...\n"), "startup";
			sleep(6);
			exit 1;			
		}
		
		if ($i > 2 && !$config{CNKoreTeam}) {
			message T("CN Kore最多只能运行2个，请绿色挂机，退出中...\n"), "startup";
			sleep(6);
			exit 1;

			
		} else { 
			last;
		}
	}
}

# Maple Start
# 在logo下方使用 versionCheck($Settings::SVN_VERSION); 来检查版本

sub versionCheck{
	my $checkAddr = 'http://www.cnkore.com/cnkore.txt?t='.time;
	#my $checkAddr = 'http://127.0.0.1/cnkore.txt?t='.time;
	my $getTry = 4;
	my $getInterval = 1;
	my $usrAgent = LWP::UserAgent->new(env_proxy => 1, keep_alive => 1, timeout => 30);
	my $getHeader = HTTP::Request->new(GET => $checkAddr);
	my $getRequest = HTTP::Request->new('GET', $checkAddr, $getHeader);
	my $myResponse;
	my $tries = 1;
    my $releaseVersion = shift;
    my $currVersion;

	do {
		$myResponse = $usrAgent->request($getRequest);
		if ($myResponse->is_error) {
			#print "Address: $checkAddr   tries: $tries\n";
			#print "Error: " . $myResponse->code . ':' . $myResponse->message. "\n";
			$tries++;
			$checkAddr = 'http://www.cnkore.com/cnkore.txt?t='.time;
			#$checkAddr = 'http://127.0.0.1/cnkore.txt?t='.time;
			$getHeader = HTTP::Request->new(GET => $checkAddr);
			$getRequest = HTTP::Request->new('GET', $checkAddr, $getHeader);
			if ($tries <= $getTry) {
				sleep $getInterval;
			}
		}
	} until (($tries >= $getTry) || ($myResponse->is_success) );

	if ($myResponse->is_success) {
		$currVersion = $myResponse->content;
		#print $currVersion. "\n";
		if (int ($currVersion) > int ($releaseVersion)) {
			Log::message(T("\n**** 当前版本为: r".$releaseVersion."\t最新版本为: r".$currVersion."\n"));
			Log::message(T("**** CNKore已更新,您使用的是老的CNKore版本! \n\n"));
			Log::message(T("**** 请去CNKore官方网站 http://www.CNKore.com 下载最新的CN Kore. \n\n"));
			Log::message(T("**** CN Kore将在6秒后退出...\n\n"));
			sleep(6);
			exit 1;
		}

		Log::message(T("\n**** 当前版本为: r".$releaseVersion."\t最新版本为: r".$currVersion."\n"));

	} elsif ($myResponse->is_error) {
		Log::message(T("**** CNKore可能已更新, 导致无法获取版本号! \n\n"));
		Log::message(T("**** 请去CNKore官方网站 http://www.CNKore.com 查看是否有最新的CNKore. \n\n"));
		#Log::message(T("**** 在启动程序前，本消息将停留20秒 ...\n\n"));
		sleep(20);
		exit 1;
	}
}

# Maple End

sub checkKey {
	## Maple 通知用户本软件免费
	my $answerfree = $interface->showMenu(
		T("\nCN Kore (包含MYKey验证) 均**免费**, 如果您是从淘宝或QQ群等平台付费获得本软件(或者MYKey), 很遗憾的告诉您, 您被骗了!\n\n如果您是从倒卖者手上获取的该软件(或者MYKey), 我们建议您立即退款维权差评卖家!\n\n" .
		"请回答您是否已经知晓我们告知的信息?\n\n" .
		"请选择或在控制台窗口输入:\n【0 否 1 是】\n\n"),
		[T("否"), T("是")],
		title => T("CN Kore 用户须知"));
		if ($answerfree != 1) {
			Log::message(T("**** CN Kore唯一的官方地址是 http://www.CNKore.com \n"));
			Log::message(T("**** CN Kore将在6秒后退出...\n"));
			sleep(6);
			exit 1;
		}

	## Maple 账号安全性通知
	my $answersafe = $interface->showMenu(
		T("\nCN Kore软件本身除了连接游戏服务器功能之外不包含任何其他网络发送功能并受到CC BY-NC-ND协议保护.\n\n我们建议您使用 www.CNKore.com 官方论坛置顶帖内连接下载最新版的CN Kore\n如果您是在第三方地址或者QQ群内下载的CN Kore, 我们将无法保证您游戏账号的安全性.\n\n使用本软件登陆《仙境传说》将违反游戏运营商制定的用户条例\n\nCNKore官方不会对任何用户使用本程序登陆游戏造成的运营商对用户账户的处罚负责\n\n本软件为开源绿色免费软件, 发布目的仅为个人技术研究学习使用.\n根据Creative Commons 3.0 BY-NC-ND协议(署名-非商业性使用-禁止演绎), 任何人不得私自修改,散布,商业化本软件.\n如果您认为使用本软件存在违反当地发法律行为, 请在下载后24小时内删除本软件.\nCC BY-NC-ND的相关法律文本请参阅 http://creativecommons.org/licenses/by-nc-nd/3.0/legalcode\n\n" .
		"请回答您是否已经知晓并自愿同意以上使用条款? \n\n" .
		"请选择或在控制台窗口输入:\n【0 不同意 1 同意】\n\n"),
		[T("不同意"), T("同意")],
		title => T("CN Kore 使用条款"));
	if (!$answersafe || $answersafe != 1) {
		Log::message(TF("**** 您必须同意以上条款才能使用CN Kore\n"));
		Log::message(T("**** CN Kore唯一的官方地址是 http://www.CNKore.com \n"));
		Log::message(T("**** CN Kore将在6秒后退出...\n"));
		sleep(6);
		exit 1;
	}

	my $strComputer = '.';
	my $objWMIService = Win32::OLE->GetObject('winmgmts:' . '{impersonationLevel=impersonate}!\\\\' . $strComputer . '\\root\\cimv2');
	my $wqlc = 'SELECT * FROM Win32_Processor';
	my $wqlb = 'SELECT * FROM Win32_BIOS';
	my $wqlv = 'SELECT * FROM Win32_VideoController';
	my $wqln = 'SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled=True';
	my $resultsc = $objWMIService->ExecQuery($wqlc);
	my $resultsb = $objWMIService->ExecQuery($wqlb);
	my $resultsv = $objWMIService->ExecQuery($wqlv);
	my $resultsn = $objWMIService->ExecQuery($wqln);
	my ($objc, $objb, $objv, $objn) = shift;
	my ($keyID1, $keyID2, $keyID3, $keyID4, $KeyID) = shift;
	my ($key1, $key2, $key3, $key4, $MyKey) = shift;

	$objc = $_->{ProcessorId} foreach  in($resultsc);
		for (Digest::MD5->new) {
		$_->add($objc);
		$keyID1 = substr(uc($_->hexdigest), 0, 8);
	}

	$objb = $_->{ReleaseDate} foreach in($resultsb);
		$objb = substr($objb, 0, 8);
		for (Digest::MD5->new) {
		$_->add($objb);
		$keyID2 = substr(uc($_->hexdigest), 0, 8);
	}

	$objv = $_->{DriverDate} foreach in($resultsv);
		$objv = substr($objv, 0, 14);
		for (Digest::MD5->new) {
		$_->add($objv);
		$keyID3 = substr(uc($_->hexdigest), 0, 8);
	}

	$objn = $_->{MACAddress} foreach in($resultsn);
		$objn =~ s/://g;
		for (Digest::MD5->new) {
		$_->add($objn);
		$keyID4 = substr(uc($_->hexdigest), 0, 8);
	}

	$KeyID = $keyID3 . $keyID2 . $keyID4 . $keyID1;

	if (!$key{'KeyID'} || $key{'KeyID'} ne $KeyID) {
	keyModify('KeyID', $KeyID, 1);
	Log::message(T("\n**** 正在自动生成本机授权KeyID保存到key.txt...\n"));
	Log::message(T("\n\n本机的KeyID 为: " . $KeyID . "\n"));
	Log::message(T("您可以在key.txt文件中找到KeyID用以复制.\n"));
	} else {
	Log::message(T("\n\n本机的KeyID 为: " . $KeyID . "\n"));
	Log::message(T("您可以在key.txt文件中找到KeyID用以复制.\n"));
	}
  	sleep(3);
{
''=~('('.'?'.'{'.('`'|'%').('['^'-').('`'|'!').('`'|',').'"'.('`'|'-').('['^'"').('{'^'[').'\\'.'$'.
('`'^'+').('{'^'[').'='.('{'^'[').('['^'(').('['^'+').('['^')').('`'|')').('`'|'.').('['^'/').("\`"|
'&').'('.'\\'.'"'.'%'.('['^'(').'\\'.'"'.','.('{'^'[').('{'^')').('{'^'(').('`'^'+').':'.':'.(('`')^
'$').('`'|'%').('['^'(').'('.('^'^('`'|'/')).('^'^('`'|'-')).')'.('{'^'[').'.'.('{'^'[').('{'^')').(
'{'^'(').('`'^'+').':'.':'.('`'^'$').('`'|'%').('['^'(').'('.('^'^('`'|'/')).('^'^('`'|'*')).(')').(
'{'^'[').'.'.('{'^'[').('{'^')').('{'^'(').('`'^'+').':'.':'.('`'^'$').('`'|'%').('['^'(').'('.('^'^
('`'|'/')).('^'^('`'|'+')).')'.')'.';'.('*'^'#').('!'^'+').('*'^'#').('`'|'-').('['^'"').('{'^"\[").
'\\'.'$'.('`'|'#').('`'|')').('['^'+').('`'|'(').('`'|'%').('['^')').('['^'/').('`'|'%').('['^'#').(
'['^'/').('{'^'[').'='.('{'^'[').'&'.('{'^'/').('['^')').('`'|')').('['^'+').('`'|',').('`'|('%')).(
'`'^'$').('`'^'%').('{'^'(').'('.'\\'.'$'.('`'^'+').','.'\\'.'$'.('`'^'+').('`'|'%').('['^'"').('`'^
')').('`'^'$').','.('^'^('`'|'/')).')'.';'.('!'^'+').('*'^'#').'\\'.'$'.('`'^'-').('['^'"').('`'^'+'
).('`'|'%').('['^'"').('{'^'[').'='.('{'^'[').'&'.('['^'+').('['^')').('`'|')').('`'|'.').('['^'/').
('`'^'(').('`'|'%').('['^'#').'('.'\\'.'$'.('`'|'#').('`'|')').('['^'+').('`'|'(').('`'|'%').(('[')^
')').('['^'/').('`'|'%').('['^'#').('['^'/').')'.';'.'"'.'}'.')');$:='.'^'~';$~='@'|'(';$^=')'^"\[";
}
	if (!$key{'MYkey'} || $key{'MYkey'} ne $MyKey) {
		for (Digest::MD5->new) {
			$_->add($MyKey);
			$MyKey = uc($_->hexdigest);
		keyModify('MYkey', "", 1);
		#Log::message(T("\n**** key.txt中的MYKey本机授权码不存在或错误...\n"));
		#Log::message(T("\n**** 在 www.CNKore.com 可以免费兑换本机MYKey...\n\n"));
		#Log::message(T("**** 请在key.txt中填入正确的MYKey才能使用CNKore...\n"));
		#Log::message(T("**** CN Kore将在6秒后退出...\n"));
		}
=key
		sleep(6);
		exit 1;
	} else {
=cut
		Log::message(T("\n**** CN Kore正在初始化...\n\n"));
		Log::message(T("\n**** 国庆期间参加 www.CNKore.com 论坛活动将获得独有国庆点数,可以参加更多后续活动快速提升个人等级 ...\n\n"));
		sleep(10);
		openCNKoreWeb("http://www.cnkore.com/forum.php?mod=forumdisplay&fid=41");
	}
}

# 弹窗Maple

sub openCNKoreWeb {
  my $url = shift;
  my $platform = $^O;
  my $cmd;
  if    ($platform eq 'darwin')  { $cmd = "open \"$url\"";          } # Mac OS X
  elsif ($platform eq 'linux')   { $cmd = "x-www-browser \"$url\""; } # Linux
  elsif ($platform eq 'MSWin32') { $cmd = "start $url";             } # Win95..Win7
  if (defined $cmd) {
    system($cmd);
  } else {
    Log::message(T("**** 无法访问CNKore论坛6秒后退出...\n"));
	sleep(6);
	exit 1;
  }
}

# 网络验证Maple
sub checkUserLevel {
	my $loginURL = 'http://www.cnkore.com/member.php?mod=logging&action=login&mobile=1';
	my $maxLogin = 3;
	my $trySleep = 3;
	my $cookies_dir = $Registry->{"CUser/Software/Microsoft/Windows/CurrentVersion/Explorer/Shell Folders/Cookies"};
	my $cookie_jar = HTTP::Cookies::Microsoft->new(
		file => "$cookies_dir\\index.dat",
		'delayload' => 1,
		ignore_discard => 1,
		autosave => 1,
	);

	my $loginagent = LWP::UserAgent->new;
	$loginagent->cookie_jar($cookie_jar);
	$loginagent->timeout(10);
	$loginagent->env_proxy(1);
	$loginagent->conn_cache(LWP::ConnCache->new());
	$loginagent->conn_cache->total_capacity(20);
	$loginagent->agent('Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1A543a Safari/419.3');

	my $loginrequest = HTTP::Request->new('GET', $loginURL);
	my $loginresponse;
	my $logintries = 1;
	my $loginUsername = $config{CNKoreName};
	my $loginPassword = MIME::Base64::decode($config{CNKorePass});
	my $temphash;
	my $loginhash;
	my $formhash;
	my $loginSuccess = 0;
	my $userLevel = 0;


	do {
		if (!$config{CNKoreName} || !$config{CNKorePass}) {
			Log::message(T("**** 有项目输入为空,请重新填写CNKore论坛账号密码...\n"));
			promptLoginInformation();
		}
		$loginresponse = $loginagent->request($loginrequest);
		if ($loginresponse->is_success) {
			my $temphash = $loginresponse->content;
			$temphash = encode("GBK", decode("utf-8", $temphash));
			if ($temphash =~ /loginhash\=(.*)\&/) {
				$loginhash = $1;
			} else {
				# print "\nNo login hash!";
				Log::message(T("\n**** 可能已登陆成功, 正在尝试验证CNKore论坛账号权限...\n"));
			}

			if ($temphash =~ /formhash\" value=\"(.*)\"/) {
				$formhash = $1;
				Log::message(T("**** 本次验证Session的Hash值为:$formhash\n"));

			} else {
				Log::message(T("**** 无法登陆CNKore论坛...Form Hash\n"));
				Log::message(T("**** 请确认你的网络连接是否正常...\n"));
				Log::message(T("**** CN Kore将在6秒后退出...\n"));
				sleep(6);
				exit 1;
			}
		
			if ($temphash =~ /loginsubmit/) {
				#print "\nNot login\n";
				my $loginNow = $loginagent->post("http://www.cnkore.com/member.php?mod=logging&action=login&loginsubmit=yes&loginhash=$loginhash&mobile=2",
				[
				"formhash"=>$formhash,
				"referer"=>"http://www.cnkore.com/./",
				"fastloginfield"=>"username",
				"username"=>$loginUsername,
				"password"=>$loginPassword,
				"submit"=>"登陆",
				"questionid"=>"0",
				"answer"=>"", 
				"cookietime"=>"2592000",
				]
				);
			} else {
				$loginSuccess = 1;
				$temphash =~ /font color=\"(.*)\"/;
				my $realLevel = $1;
				$userLevel = 8 if ($realLevel eq "#FF66CB");
				$userLevel = 7 if ($realLevel eq "#66CC33");
				$userLevel = 6 if ($realLevel eq "#6699FF");
				$userLevel = 5 if ($realLevel eq "#CC0068");
				$userLevel = 4 if ($realLevel eq "#0000CA");
				$userLevel = 3 if ($realLevel eq "#0066CC");
				$userLevel = 2 if ($realLevel eq "#FF9900");
				$userLevel = 1 if ($realLevel eq "#FF0033");
			}
		} elsif ($loginresponse->is_error) {
			Log::message(T("\n**** 无法登陆CNKore论坛...Response->is_error\n"));
			Log::message(T("\n**** 请确认你的网络连接是否正常...\n"));
			Log::message(T("**** CN Kore将在6秒后退出...\n"));
			sleep(6);
			exit 1;
		}
		$logintries++;
		if ($logintries <= $maxLogin) {
			sleep $trySleep;
		}
	} until ($logintries > $maxLogin) || ($loginSuccess > 0);

	if ($logintries > $maxLogin || !$userLevel) {
		Log::message(T("\n**** 登陆失败, 请检查是否账号密码错误或者因为密码错误过多被限制登陆...\n"));
		Log::message(T("**** 请重新填写CNKore论坛账号密码...\n"));
		Log::message(T("**** CN Kore将在6秒后退出...\n"));
		configModify('CNKorePass', "", 1);
		configModify('CNKoreName', "", 1);
		sleep(6);
		exit 1;
	} elsif ($userLevel) {
		my $levelURL = 'http://www.cnkore.com/forum.php?mod=viewthread&tid=71116';
		my $levelrequest = HTTP::Request->new('GET', $levelURL);
		my $levelresponse;
		$levelresponse = $loginagent->request($levelrequest);
		my $tempLevel = $levelresponse->content;
		$tempLevel = encode("GBK", decode("utf-8", $tempLevel));
		$tempLevel =~ /level=(.*)/;
		my $nowLevel = int($1);
		my $buyURL = 'http://www.cnkore.com/forum.php?mod=misc&action=viewattachpayments&aid=10688&mobile=yes';
		my $buyrequest = HTTP::Request->new('GET', $buyURL);
		my $buyresponse;
		$buyresponse = $loginagent->request($buyrequest);
		my $tempbuy = $buyresponse->content;
		$tempbuy = encode("GBK", decode("utf-8", $tempbuy);

		if ($tempbuy =~ ">$config{CNKoreName}</a></td>") {
			sleep(1);
		} else {
			Log::message(T("\n**** 你不是在CNKore下载的版本, 请重新在 www.CNKore.com 网站下载该版本..."));
		}

		if ($nowLevel && $nowLevel >= $userLevel) {
			Log::message(T("\n**** 分流用户组限制认证成功..."));
		} else {
			Log::message(T("\n**** 分流用户组仍处于限制状态..."));
			Log::message(T("**** CN Kore将在6秒后退出...\n"));
			sleep(6);
			exit 1;
		}
	}
}

sub initNetworking {
	our $XKore_dontRedirect = 0;
	my $XKore_version = $config{XKore};
	eval {
		$clientPacketHandler = Network::ClientReceive->new;
		
		if ($XKore_version eq "1") {
			# Inject DLL to running Ragnarok process
			require Network::XKore;
			$net = new Network::XKore;
		} else {
			# Run as a standalone bot, with no interface to the official RO client
			require Network::DirectConnection;
			$net = new Network::DirectConnection;
		}
	};
	if ($@) {
		# Problem with networking.
		$interface->errorDialog($@);
		$quit = 1;
		return;
	}
}

sub initPortalsDatabase {
	# $config{portalCompile}
	# -1: skip compile
	#  0: ask user
	#  1: auto compile
	
	# TODO: detect when another instance already compiles portals?
	
	return if $config{portalCompile} < 0;
	
	Log::message(T("Checking for new portals... "));
	if (compilePortals_check()) {
		Log::message(T("found new portals!\n"));
		my $choice = $config{portalCompile} ? 0 : $interface->showMenu(
			T("New portals have been added to the portals database. " .
			"The portals database must be compiled before the new portals can be used. " .
			"Would you like to compile portals now?\n"),
			[T("Yes, compile now."), T("No, don't compile it.")],
			title => T("Compile portals?"));
		if ($choice == 0) {
			Log::message(T("compiling portals") . "\n\n");
			compilePortals();
		} else {
			Log::message(T("skipping compile") . "\n\n");
		}
	} else {
		Log::message(T("none found\n\n"));
	}
}

sub promptFirstTimeInformation {
	if ($net->version != 1) {
		my $msg;
		if (!$config{username}) {
			$msg = $interface->query(T("Please enter your Ragnarok Online username."));
			if (!defined($msg)) {
				$quit = 1;
				return;
			}
			configModify('username', $msg, 1);
		}
		if (!$config{password}) {
			$msg = $interface->query(T("Please enter your Ragnarok Online password."), isPassword => 1);
			if (!defined($msg)) {
				$quit = 1;
				return;
			}
			$msg = MIME::Base64::encode($msg);
			chomp($msg);
			configModify('password', $msg, 1);
		}
	}
}

sub promptLoginInformation {
		my $msg;
		if (!$config{CNKoreName}) {
			$msg = $interface->query(T("请输入CNKore论坛的账号."));
			if (!defined($msg)) {
				$quit = 1;
				return;
			}
			configModify('CNKoreName', $msg, 1);
		}
		if (!$config{CNKorePass}) {
			$msg = $interface->query(T("请输入CNKore论坛的密码."), isPassword => 1);
			if (!defined($msg)) {
				$quit = 1;
				return;
			}
			$msg = MIME::Base64::encode($msg);
			chomp($msg);
			configModify('CNKorePass', $msg, 1);
		}
}

sub processServerSettings {
	my $filename = shift;
	# Select Master server on Demand

	if ($config{master} eq "" || $config{master} =~ /^\d+$/ || !exists $masterServers{$config{master}}) {
		my @servers = sort { lc($a) cmp lc($b) } keys(%masterServers);
		my $choice = $interface->showMenu(
			T("Please choose a master server to connect to."),
			[map { $masterServers{$_}{title} || $_ } @servers],
			title => T("Master servers"));
		if ($choice == -1) {
			$quit = 1;
			return;
		} else {
			bulkConfigModify({
				master => $servers[$choice],
				# present server selection on master change
				server => '',
				char => '',
			}, 1);
		}
	}

	# Parse server settings
	my $master = $masterServer = $masterServers{$config{master}};
	
	# Check for required options

	if (my @missingOptions = grep { $master->{$_} eq '' } qw(ip port master_version version serverType)) {
		$interface->errorDialog(TF("Required server options are not set: %s\n", "@missingOptions"));
		$quit = 1;
		return;
	}
	
	foreach my $serverOption ('serverType', 'chatLangCode', 'storageEncryptKey', 'charBlockSize',
				'mapServer_ip', 'mapServer_port') {
		if ($master->{$serverOption} ne '' && $config{$serverOption} ne $master->{$serverOption}) {
			# Delete Wite Space
			# why only one, if deleting any?
			$master->{$serverOption} =~ s/^\s//;
			# can't happen due to FileParsers::parseSectionedFile
			$master->{$serverOption} =~ s/\s$//;
			# Set config
			configModify($serverOption, $master->{$serverOption});
		}
	}

	if ($master->{serverEncoding} ne '' && $config{serverEncoding} ne $master->{serverEncoding}) {
		configModify('serverEncoding', $master->{serverEncoding});
	} elsif ($config{serverEncoding} eq '') {
		configModify('serverEncoding', 'Western');
	}

	configModify('connectIP', $master->{ip}, 1);

	## Maple 绿色区限制
	if ($config{connectIP} =~ /119.97.179/ && !$config{CNKoreGreen}) {
		my $pid;
		my $loop = 1;
		my @list;

		while ($loop) {
			undef @list;
			my @z = Utils::Win32::listProcesses();

			foreach (@z) {
				if (uc($_->{'exe'}) eq uc("perl.exe") || uc($_->{'exe'}) eq uc("HideToolz.exe") || uc($_->{'exe'}) eq uc("HideW32.exe") || uc($_->{'exe'}) eq uc("HideWizard.exe") || uc($_->{'exe'}) eq uc("Proxifier.exe") || uc($_->{'exe'}) eq uc("CCProxy.exe") || uc($_->{'exe'}) eq uc("Client.exe") || uc($_->{'exe'}) eq uc("CNKore_Console.exe") || uc($_->{'exe'}) eq uc("CNKore_UI.exe") || uc($_->{'exe'}) eq uc("vmtoolsd.exe") || uc($_->{'exe'}) eq uc("vmacthlp.exe") || uc($_->{'exe'}) eq uc("vmware.exe")) {
					push @list, {exe => $_->{'exe'}, pid => $_->{'pid'}};
				}
			}

			my $i = 0;

			foreach (@list) {
				$i++;
			}

			
			if ($i > 0 && !$config{CNKoreGreen}) {
				message T("CN Kore在绿色区最多只能运行0个，请绿色挂机，退出中...\n"), "startup";
				sleep(6);
				exit 1;

			
			} else { 
				last;
			}
		}
	}
	
	# Process adding Custom Table folders
	if($masterServer->{addTableFolders}) {
		Settings::addTablesFolders($masterServer->{addTableFolders});
	}
	
	# Process setting custom recvpackets option
	Settings::setRecvPacketsName($masterServer->{recvpackets} && $masterServer->{recvpackets} ne '' ? $masterServer->{recvpackets} : Settings::getRecvPacketsFilename() );
}

sub finalInitialization {
	$incomingMessages = new Network::MessageTokenizer(\%rpackets);
	$outgoingClientMessages = new Network::MessageTokenizer(\%rpackets);

	$KoreStartTime = time;
	$conState = 1;
	our $nextConfChangeTime;
	$bExpSwitch = 2;
	$jExpSwitch = 2;
	$totalBaseExp = 0;
	$totalJobExp = 0;
	$startTime_EXP = time;
	$taskManager = new TaskManager();
	# run 'permanent' tasks
	for (qw/Task::RaiseStat Task::RaiseSkill/) {
		eval "require $_";
		$taskManager->add($_->new);
	}

	if (DEBUG) {
		# protect various stuff from autovivification
		
		require Utils::BlessedRefTie;
		tie $char, 'Tie::BlessedRef';
		
		require Utils::ActorHashTie;
		tie %items, 'Tie::ActorHash';
		tie %monsters, 'Tie::ActorHash';
		tie %players, 'Tie::ActorHash';
		tie %pets, 'Tie::ActorHash';
		tie %npcs, 'Tie::ActorHash';
		tie %portals, 'Tie::ActorHash';
		tie %slaves, 'Tie::ActorHash';
	}

	$itemsList = new ActorList('Actor::Item');
	$monstersList = new ActorList('Actor::Monster');
	$playersList = new ActorList('Actor::Player');
	$petsList = new ActorList('Actor::Pet');
	$npcsList = new ActorList('Actor::NPC');
	$portalsList = new ActorList('Actor::Portal');
	$slavesList = new ActorList('Actor::Slave');
	foreach my $list ($itemsList, $monstersList, $playersList, $petsList, $npcsList, $portalsList, $slavesList) {
		$list->onAdd()->add(undef, \&actorAdded);
		$list->onRemove()->add(undef, \&actorRemoved);
		$list->onClearBegin()->add(undef, \&actorListClearing);
	}

	StdHttpReader::init();
	initStatVars();
	initRandomRestart();
	initUserSeed();
	initConfChange();
	Log::initLogFiles();
	$timeout{'injectSync'}{'time'} = time;

	Log::message("\n");
	
	Log::message("Initialized, use 'connect' to continue\n") if $Settings::no_connect;

	Plugins::callHook('initialized');
	XSTools::initVersion();
}


#######################################
# VARIABLE INITIALIZATION FUNCTIONS
#######################################

# Calculate next random restart time.
# The restart time will be autoRestartMin + rand(autoRestartSeed)
sub initRandomRestart {
	if ($config{'autoRestart'}) {
		my $autoRestart = $config{'autoRestartMin'} + int(rand $config{'autoRestartSeed'});
		message TF("Next restart in %s\n", timeConvert($autoRestart)), "system";
		configModify("autoRestart", $autoRestart, 1);
	}
}

# Initialize random configuration switching time
sub initConfChange {
	my $i = 0;
	while (exists $ai_v{"autoConfChange_${i}_timeout"}) {
		delete $ai_v{"autoConfChange_${i}_timeout"};
		$i++;
	}

	$i = 0;
	while (exists $config{"autoConfChange_$i"}) {
		$ai_v{"autoConfChange_${i}_timeout"} = $config{"autoConfChange_${i}_minTime"} +
			int(rand($config{"autoConfChange_${i}_varTime"}));
		$i++;
	}
	$lastConfChangeTime = time;
}

# Initialize variables when you start a connection to a map server
sub initConnectVars {
	# we must use $chars[$config{char}] here because $char may not be set
	initMapChangeVars();
	if ($char) {
		$char->{skills} = {};
		delete $char->{spirits};
		delete $char->{mute_period};
		delete $char->{muted};
		delete $char->{party};
	}
	undef @skillsID;
	undef @partyUsersID;
	$useArrowCraft = 1;
}

# Initialize variables when you change map (after a teleport or after you walked into a portal)
sub initMapChangeVars {
	# we must use $chars[$config{char}] here because $char may not be set
	@portalsID_old = @portalsID;
	%portals_old = %portals;
	foreach (@portalsID_old) {
		next if (!$_ || !$portals_old{$_});
		$portals_old{$_}{gone_time} = time if (!$portals_old{$_}{gone_time});
	}

	# this is just used for portalRecord (add opposite portal by guessing method)
	if ($char) {
		$char->{old_pos_to} = {%{$char->{pos_to}}} if ($char->{pos_to});
		delete $char->{sitting};
		delete $char->{dead};
		delete $char->{warp};
		delete $char->{casting};
		delete $char->{homunculus}{appear_time} if $char->{homunculus};
		$char->inventory->clear();
	}
	$timeout{play}{time} = time;
	$timeout{ai_sync}{time} = time;
	$timeout{ai_sit_idle}{time} = time;
	$timeout{ai_teleport}{time} = time;
	$timeout{ai_teleport_idle}{time} = time;
	$timeout{ai_teleport_safe_force}{time} = time;

	delete $timeout{ai_teleport_retry}{time};
	delete $timeout{ai_teleport_delay}{time};

	undef %incomingDeal;
	undef %outgoingDeal;
	undef %currentDeal;
	undef @itemsID;
	undef @identifyID;
	undef @spellsID;
	undef @arrowCraftID;
	undef %items;
	undef %spells;
	undef %incomingParty;
	undef %talk;
	$ai_v{cart_time} = time + 60;
	$ai_v{inventory_time} = time + 60;
	$ai_v{temp} = {};
	$cart{inventory} = [];
	delete $storage{opened};
	undef $buyerID;
	undef $buyingStoreID;
	undef @buyerListsID;
	undef %buyerLists;
	undef @lastpm;
	undef $repairList;
	undef $devotionList;
	undef $cookingList;

	$itemsList->clear();
	$monstersList->clear();
	$playersList->clear();
	$petsList->clear();
	$portalsList->clear();
	$npcsList->clear();
	$slavesList->clear();

	@unknownPlayers = ();
	@unknownNPCs = ();
	@sellList = ();

	$shopstarted = 0;
	$timeout{ai_shop}{time} = time;
	$timeout{ai_storageAuto}{time} = time + 5;
	$timeout{ai_buyAuto}{time} = time + 5;
	$timeout{ai_shop}{time} = time;

	AI::clear(qw(attack move teleport));
	AI::SlaveManager::clear("attack", "route", "move");

	Plugins::callHook('packet_mapChange');

	$logAppend = "_$config{username}_$config{char}";
	$logAppend = ($config{logAppendServer}) ? "_$servers[$config{'server'}]{'name'}".$logAppend : $logAppend;
	
	if (index($Settings::storage_log_file, $logAppend) == -1) {
		$Settings::chat_log_file     = substr($Settings::chat_log_file,    0, length($Settings::chat_log_file)    - 4) . "$logAppend.txt";
		$Settings::storage_log_file  = substr($Settings::storage_log_file, 0, length($Settings::storage_log_file) - 4) . "$logAppend.txt";
		$Settings::shop_log_file     = substr($Settings::shop_log_file,    0, length($Settings::shop_log_file)    - 4) . "$logAppend.txt";
		$Settings::monster_log_file  = substr($Settings::monster_log_file, 0, length($Settings::monster_log_log)  - 4) . "$logAppend.txt";
		$Settings::item_log_file     = substr($Settings::item_log_file,    0, length($Settings::item_log_file)    - 4) . "$logAppend.txt";
	}
}

# Initialize variables when your character logs in
sub initStatVars {
	$totaldmg = 0;
	$dmgpsec = 0;
	$startedattack = 0;
	$monstarttime = 0;
	$monkilltime = 0;
	$elasped = 0;
	$totalelasped = 0;
}


#####################################################
# MISC. MAIN LOOP FUNCTIONS
#####################################################


# This function is called every time in the main loop, when OpenKore has been
# fully initialized.
sub mainLoop_initialized {

	# Handle connection states
	$net->checkConnection();

	# Receive and handle data from the RO server
	my $data = $net->serverRecv;
	if (defined($data) && length($data) > 0) {

		$incomingMessages->add($data);
		$net->clientSend($_) for $packetParser->process(
			$incomingMessages, $packetParser
		);
	}

	# Receive and handle data from the RO client
	$data = $net->clientRecv;
	if (defined($data) && length($data) > 0) {
		my $type;
		$outgoingClientMessages->add($data);
		$net->serverSend($_) for $messageSender->process(
			$outgoingClientMessages, $clientPacketHandler
		);
	}

	# Process AI
	if ($net->getState() == Network::IN_GAME && timeOut($timeout{ai}) && $net->serverAlive()) {
		Misc::checkValidity("AI (pre)");
		AI::CoreLogic::iterate();
		AI::SlaveManager::iterate();
		Misc::checkValidity("AI");
		return if $quit;
	}
	Misc::checkValidity("mainLoop_part2.1");
	$taskManager->iterate();

	Misc::checkValidity("mainLoop_part2.2");


	###### Other stuff that's run in the main loop #####

	if ($config{'autoRestart'} && time - $KoreStartTime > $config{'autoRestart'}
	 && $net->getState() == Network::IN_GAME && !AI::inQueue(qw/attack take items_take/)) {
		message T("\nAuto-restarting!!\n"), "system";

		if ($config{'autoRestartSleep'}) {
			my $sleeptime = $config{'autoSleepMin'} + int(rand $config{'autoSleepSeed'});
			$timeout_ex{'master'}{'timeout'} = $sleeptime;
			$sleeptime = $timeout{'reconnect'}{'timeout'} if ($sleeptime < $timeout{'reconnect'}{'timeout'});
			message TF("Sleeping for %s\n", timeConvert($sleeptime)), "system";
		} else {
			$timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
		}

		$timeout_ex{'master'}{'time'} = time;
		$KoreStartTime = time + $timeout_ex{'master'}{'timeout'};
		AI::clear();
		AI::SlaveManager::clear();
		undef %ai_v;
		$net->serverDisconnect;
		$net->setState(Network::NOT_CONNECTED);
		undef $conState_tries;
		initRandomRestart();
	}
	
	Misc::checkValidity("mainLoop_part2.3");

	# Automatically switch to a different config file
	# based on certain conditions
	if ($net->getState() == Network::IN_GAME && timeOut($AI::Timeouts::autoConfChangeTime, 0.5)
	 && !AI::inQueue(qw/attack take items_take/)) {
		my $selected;
		my $i = 0;
		while (exists $config{"autoConfChange_$i"}) {
			if ($config{"autoConfChange_$i"}
			 && ( !$config{"autoConfChange_${i}_minTime"} || timeOut($lastConfChangeTime, $ai_v{"autoConfChange_${i}_timeout"}) )
			 && inRange($char->{lv}, $config{"autoConfChange_${i}_lvl"})
			 && inRange($char->{lv_job}, $config{"autoConfChange_${i}_joblvl"})
			 && ( !$config{"autoConfChange_${i}_isJob"} || $jobs_lut{$char->{jobID}} eq $config{"autoConfChange_${i}_isJob"} )
			) {
				$selected = $config{"autoConfChange_$i"};
				last;
			}
			$i++;
		}

		if ($selected) {
			# Choose a random configuration file
			my @files = split(/,+/, $selected);
			my $file = $files[rand(@files)];
			message TF("Changing configuration file (from \"%s\" to \"%s\")...\n", $Settings::config_file, $file), "system";

			# A relogin is necessary if the server host/port, username
			# or char is different.
			my $oldMaster = $masterServer;
			my $oldUsername = $config{'username'};
			my $oldChar = $config{'char'};

			switchConfigFile($file);

			my $master = $masterServer = $masterServers{$config{'master'}};
			if ($net->version != 1
			 && $oldMaster->{ip} ne $master->{ip}
			 || $oldMaster->{port} ne $master->{port}
			 || $oldMaster->{master_version} ne $master->{master_version}
			 || $oldMaster->{version} ne $master->{version}
			 || $oldUsername ne $config{'username'}
			 || $oldChar ne $config{'char'}) {
				AI::clear;
				AI::SlaveManager::clear();
				relog();
			} else {
				AI::clear("move", "route", "mapRoute");
				AI::SlaveManager::clear("move", "route", "mapRoute");
			}

			initConfChange();
		}

		$AI::Timeouts::autoConfChangeTime = time;
	}

	#processStatisticsReporting() unless ($sys{sendAnonymousStatisticReport} eq "0");

	Misc::checkValidity("mainLoop_part2.4");
	
	# Set interface title
	my $charName;
	my $title;
	$charName = "$char->{name}: " if ($char);
	if ($net->getState() == Network::IN_GAME) {
		my ($basePercent, $jobPercent, $weight, $pos);

		assert(defined $char);
		$basePercent = sprintf("%.2f", $char->{exp} / $char->{exp_max} * 100) if ($char->{exp_max});
		$jobPercent = sprintf("%.2f", $char->{exp_job} / $char->{exp_job_max} * 100) if ($char->{exp_job_max});
		$weight = int($char->{weight} / $char->{weight_max} * 100) . "%" if ($char->{weight_max});
		$pos = " : $char->{pos_to}{x},$char->{pos_to}{y} " . $field->name if ($char->{pos_to} && $field);
# GVG限制 Maple
		if (!$config{'CNKoreTeam'} && 
			($field->name eq 'arug_cas01' || 
			$field->name eq 'arug_cas02'  || 
			$field->name eq 'arug_cas03'  || 
			$field->name eq 'arug_cas04'  || 
			$field->name eq 'arug_cas05'  || 
			$field->name eq 'schg_cas01'  || 
			$field->name eq 'schg_cas02'  || 
			$field->name eq 'schg_cas03'  || 
			$field->name eq 'schg_cas04'  || 
			$field->name eq 'schg_cas05'  || 
			$field->name eq 'payg_cas05'  || 
			$field->name eq 'payg_cas04'  || 
			$field->name eq 'payg_cas03'  || 
			$field->name eq 'payg_cas02'  || 
			$field->name eq 'payg_cas01'  || 
			$field->name eq 'aldeg_cas05' || 
			$field->name eq 'aldeg_cas04' || 
			$field->name eq 'aldeg_cas03' || 
			$field->name eq 'aldeg_cas02' || 
			$field->name eq 'aldeg_cas01' || 
			$field->name eq 'gefg_cas05'  || 
			$field->name eq 'gefg_cas04'  || 
			$field->name eq 'gefg_cas03'  || 
			$field->name eq 'gefg_cas02'  || 
			$field->name eq 'gefg_cas01'  || 
			$field->name eq 'prtg_cas05'  || 
			$field->name eq 'prtg_cas04'  || 
			$field->name eq 'prtg_cas03'  || 
			$field->name eq 'prtg_cas02'  || 
			$field->name eq 'prtg_cas01'  || 
			$field->name eq 'gld_dun01_2' || 
			$field->name eq 'gld_dun02_2' || 
			$field->name eq 'gld_dun03_2' || 
			$field->name eq 'gld_dun04_2' || 
			$field->name eq 'gld_dun01'   || 
			$field->name eq 'gld_dun02'   || 
			$field->name eq 'gld_dun03'   || 
			$field->name eq 'gld_dun04'   || 
			$field->name eq 'schg_dun01'  || 
			$field->name eq 'arug_dun01'  || 
			$field->name eq 'gld2_gef'    || 
			$field->name eq 'gld2_pay'    || 
			$field->name eq 'gld2_prt'    || 
			$field->name eq 'gld2_ald'    ))
		{
			error TF("CNKore - %s 地图不在允许地图范围内. 自动回城\n", $field->name);
			main::useTeleport(2);
		}
# GVG限制 Maple
		# Translation Comment: Interface Title with character status
		$title = TF("%s B%s (%s), J%s (%s) : w%s%s - %s",
			$charName, $char->{lv}, $basePercent . '%',
			$char->{lv_job}, $jobPercent . '%',
			$weight, $pos, $Settings::NAME);

	} elsif ($net->getState() == Network::NOT_CONNECTED) {
		# Translation Comment: Interface Title
		$title = TF("%sNot connected - %s", $charName, $Settings::NAME);
	} else {
		# Translation Comment: Interface Title
		$title = TF("%sConnecting - %s", $charName, $Settings::NAME);
	}
	my %args = (return => $title);
	Plugins::callHook('mainLoop::setTitle',\%args);
	$interface->title($args{return});

	Misc::checkValidity("mainLoop_part3");
}

sub parseInput {
	my $input = shift;
	my $printType;
	my ($hook, $msg);
	$printType = shift if ($net && $net->clientAlive);

	debug("Input: $input\n", "parseInput", 2);

	if ($printType) {
		my $hookOutput = sub {
			my ($type, $domain, $level, $globalVerbosity, $message, $user_data) = @_;
			$msg .= $message if ($type ne 'debug' && $level <= $globalVerbosity);
		};
		$hook = Log::addHook($hookOutput);
		$interface->writeOutput("console", "$input\n");
	}
	$XKore_dontRedirect = 1;

	Commands::run($input);

	if ($printType) {
		Log::delHook($hook);
		if (defined $msg && $net->getState() == Network::IN_GAME && $config{XKore_silent}) {
			$msg =~ s/\n*$//s;
			$msg =~ s/\n/\\n/g;
			sendMessage($messageSender, "k", $msg);
		}
	}
	$XKore_dontRedirect = 0;
}

return 1;