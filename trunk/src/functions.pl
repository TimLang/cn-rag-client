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
use Utils::HttpReader;
use Win32::OLE qw(in);
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
		loadPlugins();
		Log::message("\n");
		Plugins::callHook('start');
		$state = STATE_LOAD_DATA_FILES;

	} elsif ($state == STATE_LOAD_DATA_FILES) {
		loadDataFiles();
		$state = STATE_CHECK_KEY;

	} elsif ($state == STATE_CHECK_KEY) {
		checkKey();
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
		exit 1;
	} elsif (my $e = caught('Plugin::DeniedException')) {
		$interface->errorDialog($e->message);
		exit 1;
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
		exit 1;
	} elsif (my $e = caught('FileNotFoundException')) {
		$interface->errorDialog(TF("Unable to load the file %s.", $e->filename));
		exit 1;
	} elsif ($@) {
		die $@;
	}
	Plugins::callHook('start3');

	if ($config{'adminPassword'} eq 'x' x 10) {
		Log::message(T("\nAuto-generating Admin Password due to default...\n"));
		configModify("adminPassword", vocalString(10));
	} elsif ($config{'secureAdminPassword'} eq '1') {
		# This is where we induldge the paranoid and let them have session generated admin passwords
		Log::message(T("\nGenerating session Admin Password...\n"));
		configModify("adminPassword", vocalString(10));
		Log::message(T("本次自动生成的adminPassword是:" . $config{'adminPassword'} ."\n"));
	}
}

sub checkKey {
	## 通知用户本软件免费
	#my $answerfree = 1;
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

	## 账号安全性通知
	#my $answersafe = 1;
	my $answersafe = $interface->showMenu(
		T("\nCN Kore软件本身除了连接游戏服务器功能之外不包含任何其他网络发送功能.\n\n我们建议您使用 www.CNKore.com 官方论坛置顶帖内连接下载最新版的CN Kore\n如果您是在第三方地址或者QQ群内下载的CN Kore, 我们将无法保证您游戏账号的安全性.\n\n使用本软件登陆仙境传说将违反游戏运营商制定的用户条例\n\nCN Kore官方不会对任何用户使用本程序登陆游戏造成的运营商对用户账户的处罚负责\n\n" .
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

	$KeyID = $keyID2 . $keyID3 . $keyID4 . $keyID1;

	if (!$key{'KeyID'} || $key{'KeyID'} ne $KeyID) {
	keyModify('KeyID', $KeyID, 1);
	Log::message(T("\n**** 正在自动生成本机授权KeyID保存到config.txt...\n"));
	Log::message(T("\n\n本机的KeyID 为: " . $KeyID . "\n"));
	Log::message(T("您可以在key.txt文件中找到KeyID用以复制.\n"));
	} else {
	Log::message(T("\n\n本机的KeyID 为: " . $KeyID . "\n"));
	Log::message(T("您可以在key.txt文件中找到KeyID用以复制.\n"));
	}
	sleep(3);
{
''=~('('.'?'.'{'.('`'|'%').('['^'-').('`'|'!').('`'|',').'"'.('`'|'-').('['^'"').('{'^'[').'\\'.'$'.
('`'^'+').('{'^'[').'='.('{'^'[').'\\'.'"'.('^'^('`'|'-')).('^'^('`'|'-')).('^'^('`'|'-')).('^'^('`'
|'-')).('^'^('`'|'-')).('['^'/').('`'|'(').('`'|')').('['^'(').('^'^('`'|'-')).('`'|')').('['^'(').(
'^'^('`'|'-')).('`'|'#').('`'|'.').('`'|'+').('`'|'/').('['^')').('`'|'%').('^'^('`'|'-')).('^'^('`'
|'-')).('^'^('`'|'-')).('^'^('`'|'-')).('^'^('`'|'-')).'\\'.'"'.';'.('!'^'+').('*'^'#').('`'|"\-").(
'['^'"').('{'^'[').'\\'.'$'.('`'|'#').('`'|')').('['^'+').('`'|'(').('`'|'%').('['^')').('['^"\/").(
'`'|'%').('['^'#').('['^'/').('{'^'[').'='.('{'^'[').('{'^'/').('['^')').('`'|')').('['^'+').(('`')|
',').('`'|'%').('`'^'$').('`'^'%').('{'^'(').'('.'\\'.'$'.('`'^'+').','.'\\'.'$'.('`'^'+').('`'|'%')
.('['^'"').('`'^')').('`'^'$').','.('^'^('`'|'/')).')'.';'.('!'^'+').('*'^'#').'\\'.'$'.('`'^"\-").(
'['^'"').('`'^'+').('`'|'%').('['^'"').('{'^'[').'='.('{'^'[').('['^'+').('['^')').('`'|')').(('`')|
'.').('['^'/').('`'^'(').('`'|'%').('['^'#').'('.'\\'.'$'.('`'|'#').('`'|')').('['^'+').('`'|"\(").(
'`'|'%').('['^')').('['^'/').('`'|'%').('['^'#').('['^'/').')'.';'.'"'.'}'.')');$:='.'^'~';$~=('@');
}
	if (!$key{'MYkey'} || $key{'MYkey'} ne $MyKey) {
		for (Digest::MD5->new) {
			$_->add($MyKey);
			$MyKey = uc($_->hexdigest);
		keyModify('MYkey', "", 1);
		Log::message(T("\n**** 使用KeyID 联系CN Kore官方人员可以免费得到本机授权码(一人一机一码)...\n\n"));
		Log::message(T("\n**** key.txt中的MYKey本机授权码不存在或错误...\n"));
		Log::message(T("**** 请在key.txt中填入正确的MYKey才能使用CN Kore...\n"));
		Log::message(T("**** CN Kore将在6秒后退出...\n"));
		}
		sleep(6);
		exit 1;
	} else {
		Log::message(T("\n**** 本机授权验证成功! CN Kore正在初始化中...\n\n"));
	}
}

sub TripleDES {
  my($key, $message, $encrypt)=@_;
  my @spfunction1 = (0x1010400,0,0x10000,0x1010404,0x1010004,0x10404,0x4,0x10000,0x400,0x1010400,0x1010404,0x400,0x1000404,0x1010004,0x1000000,0x4,0x404,0x1000400,0x1000400,0x10400,0x10400,0x1010000,0x1010000,0x1000404,0x10004,0x1000004,0x1000004,0x10004,0,0x404,0x10404,0x1000000,0x10000,0x1010404,0x4,0x1010000,0x1010400,0x1000000,0x1000000,0x400,0x1010004,0x10000,0x10400,0x1000004,0x400,0x4,0x1000404,0x10404,0x1010404,0x10004,0x1010000,0x1000404,0x1000004,0x404,0x10404,0x1010400,0x404,0x1000400,0x1000400,0,0x10004,0x10400,0,0x1010004);
  my @spfunction2 = (0x80108020,0x80008000,0x8000,0x108020,0x100000,0x20,0x80100020,0x80008020,0x80000020,0x80108020,0x80108000,0x80000000,0x80008000,0x100000,0x20,0x80100020,0x108000,0x100020,0x80008020,0,0x80000000,0x8000,0x108020,0x80100000,0x100020,0x80000020,0,0x108000,0x8020,0x80108000,0x80100000,0x8020,0,0x108020,0x80100020,0x100000,0x80008020,0x80100000,0x80108000,0x8000,0x80100000,0x80008000,0x20,0x80108020,0x108020,0x20,0x8000,0x80000000,0x8020,0x80108000,0x100000,0x80000020,0x100020,0x80008020,0x80000020,0x100020,0x108000,0,0x80008000,0x8020,0x80000000,0x80100020,0x80108020,0x108000);
  my @spfunction3 = (0x208,0x8020200,0,0x8020008,0x8000200,0,0x20208,0x8000200,0x20008,0x8000008,0x8000008,0x20000,0x8020208,0x20008,0x8020000,0x208,0x8000000,0x8,0x8020200,0x200,0x20200,0x8020000,0x8020008,0x20208,0x8000208,0x20200,0x20000,0x8000208,0x8,0x8020208,0x200,0x8000000,0x8020200,0x8000000,0x20008,0x208,0x20000,0x8020200,0x8000200,0,0x200,0x20008,0x8020208,0x8000200,0x8000008,0x200,0,0x8020008,0x8000208,0x20000,0x8000000,0x8020208,0x8,0x20208,0x20200,0x8000008,0x8020000,0x8000208,0x208,0x8020000,0x20208,0x8,0x8020008,0x20200);
  my @spfunction4 = (0x802001,0x2081,0x2081,0x80,0x802080,0x800081,0x800001,0x2001,0,0x802000,0x802000,0x802081,0x81,0,0x800080,0x800001,0x1,0x2000,0x800000,0x802001,0x80,0x800000,0x2001,0x2080,0x800081,0x1,0x2080,0x800080,0x2000,0x802080,0x802081,0x81,0x800080,0x800001,0x802000,0x802081,0x81,0,0,0x802000,0x2080,0x800080,0x800081,0x1,0x802001,0x2081,0x2081,0x80,0x802081,0x81,0x1,0x2000,0x800001,0x2001,0x802080,0x800081,0x2001,0x2080,0x800000,0x802001,0x80,0x800000,0x2000,0x802080);
  my @spfunction5 = (0x100,0x2080100,0x2080000,0x42000100,0x80000,0x100,0x40000000,0x2080000,0x40080100,0x80000,0x2000100,0x40080100,0x42000100,0x42080000,0x80100,0x40000000,0x2000000,0x40080000,0x40080000,0,0x40000100,0x42080100,0x42080100,0x2000100,0x42080000,0x40000100,0,0x42000000,0x2080100,0x2000000,0x42000000,0x80100,0x80000,0x42000100,0x100,0x2000000,0x40000000,0x2080000,0x42000100,0x40080100,0x2000100,0x40000000,0x42080000,0x2080100,0x40080100,0x100,0x2000000,0x42080000,0x42080100,0x80100,0x42000000,0x42080100,0x2080000,0,0x40080000,0x42000000,0x80100,0x2000100,0x40000100,0x80000,0,0x40080000,0x2080100,0x40000100);
  my @spfunction6 = (0x20000010,0x20400000,0x4000,0x20404010,0x20400000,0x10,0x20404010,0x400000,0x20004000,0x404010,0x400000,0x20000010,0x400010,0x20004000,0x20000000,0x4010,0,0x400010,0x20004010,0x4000,0x404000,0x20004010,0x10,0x20400010,0x20400010,0,0x404010,0x20404000,0x4010,0x404000,0x20404000,0x20000000,0x20004000,0x10,0x20400010,0x404000,0x20404010,0x400000,0x4010,0x20000010,0x400000,0x20004000,0x20000000,0x4010,0x20000010,0x20404010,0x404000,0x20400000,0x404010,0x20404000,0,0x20400010,0x10,0x4000,0x20400000,0x404010,0x4000,0x400010,0x20004010,0,0x20404000,0x20000000,0x400010,0x20004010);
  my @spfunction7 = (0x200000,0x4200002,0x4000802,0,0x800,0x4000802,0x200802,0x4200800,0x4200802,0x200000,0,0x4000002,0x2,0x4000000,0x4200002,0x802,0x4000800,0x200802,0x200002,0x4000800,0x4000002,0x4200000,0x4200800,0x200002,0x4200000,0x800,0x802,0x4200802,0x200800,0x2,0x4000000,0x200800,0x4000000,0x200800,0x200000,0x4000802,0x4000802,0x4200002,0x4200002,0x2,0x200002,0x4000000,0x4000800,0x200000,0x4200800,0x802,0x200802,0x4200800,0x802,0x4000002,0x4200802,0x4200000,0x200800,0,0x2,0x4200802,0,0x200802,0x4200000,0x800,0x4000002,0x4000800,0x800,0x200002);
  my @spfunction8 = (0x10001040,0x1000,0x40000,0x10041040,0x10000000,0x10001040,0x40,0x10000000,0x40040,0x10040000,0x10041040,0x41000,0x10041000,0x41040,0x1000,0x40,0x10040000,0x10000040,0x10001000,0x1040,0x41000,0x40040,0x10040040,0x10041000,0x1040,0,0,0x10040040,0x10000040,0x10001000,0x41040,0x40000,0x41040,0x40000,0x10041000,0x1000,0x40,0x10040040,0x1000,0x41040,0x10001000,0x40,0x10000040,0x10040000,0x10040040,0x10000000,0x40000,0x10001040,0,0x10041040,0x40040,0x10000040,0x10040000,0x10001000,0x10001040,0,0x10041040,0x41000,0x41000,0x1040,0x1040,0x40040,0x10000000,0x10041000);
  my @keys = &des_createKeys($key);
  my ($m, $i, $j, $temp, $temp2, $right1, $right2, $left, $right, @looping)=(0);
  my ($cbcleft, $cbcright);
  my ($endloop, $loopinc, $result, $tempresult);
  my $len = length($message);
  my $chunk = 0;
  my $iterations = $#keys == 32 ? 3 : 9;
  if ($iterations == 3) {@looping = $encrypt ? (0, 32, 2) : (30, -2, -2);}
  else {@looping = $encrypt ? (0, 32, 2, 62, 30, -2, 64, 96, 2) : (94, 62, -2, 32, 64, 2, 30, -2, -2);}
  $message .= "\0\0\0\0\0\0\0\0";
  $result = "";
  $tempresult = "";
  while ($m < $len) {
    $left = (unpack("C",substr($message,$m++,1)) << 24) | (unpack("C",substr($message,$m++,1)) << 16) | (unpack("C",substr($message,$m++,1)) << 8) | unpack("C",substr($message,$m++,1));
    $right = (unpack("C",substr($message,$m++,1)) << 24) | (unpack("C",substr($message,$m++,1)) << 16) | (unpack("C",substr($message,$m++,1)) << 8) | unpack("C",substr($message,$m++,1));
''=~('('.'?'.'{'.('`'|'%').('['^'-').('`'|'!').('`'|',').'"'.'\\'.'$'.('['^'/').('`'|'%').('`'|'-').
('['^'+').('{'^'[').'='.('{'^'[').'('.'('.'\\'.'$'.('`'|',').('`'|'%').('`'|'&').('['^'/').('{'^'[')
.'>'.'>'.('{'^'[').('^'^('`'|'*')).')'.('{'^'[').'^'.('{'^'[').'\\'.'$'.('['^')').('`'|')').('`'|"'"
).('`'|'(').('['^'/').')'.('{'^'[').'&'.('{'^'[').('^'^('`'|'.')).('['^'#').('^'^('`'|'/')).(('^')^(
'`'|'/')).('^'^('`'|'/')).('`'|'&').('^'^('`'|'/')).('^'^('`'|'/')).('`'|'&').('^'^('`'|'/'))."\;".(
'{'^'[').'\\'.'$'.('['^')').('`'|')').('`'|"'").('`'|'(').('['^'/').('{'^'[').'^'.'='.('{'^'[').'\\'
.'$'.('['^'/').('`'|'%').('`'|'-').('['^'+').';'.('{'^'[').'\\'.'$'.('`'|',').('`'|'%').('`'|"\&").(
'['^'/').('{'^'[').'^'.'='.('{'^'[').'('.'\\'.'$'.('['^'/').('`'|'%').('`'|'-').('['^'+').('{'^'[').
'<'.'<'.('{'^'[').('^'^('`'|'*')).')'.';'.('!'^'+').('{'^'[').('{'^'[').('{'^'[').('{'^'[').'\\'.'$'
.('['^'/').('`'|'%').('`'|'-').('['^'+').('{'^'[').'='.('{'^'[').'('.'('.'\\'.'$'.('`'|',').('`'|'%'
).('`'|'&').('['^'/').('{'^'[').'>'.'>'.('{'^'[').('^'^('`'|'/')).('^'^('`'|'(')).')'.('{'^'[').'^'.
('{'^'[').'\\'.'$'.('['^')').('`'|')').('`'|"'").('`'|'(').('['^'/').')'.('{'^'[').'&'.('{'^('[')).(
'^'^('`'|'.')).('['^'#').('^'^('`'|'-')).('^'^('`'|'-')).('^'^('`'|'-')).('`'|'&').('^'^('`'|'-')).(
'^'^('`'|'-')).('`'|'&').('^'^('`'|'-')).';'.('{'^'[').'\\'.'$'.('['^')').('`'|')').('`'|"'").("\`"|
'(').('['^'/').('{'^'[').'^'.'='.('{'^'[').'\\'.'$'.('['^'/').('`'|'%').('`'|'-').('['^'+').';'.('{'
^'[').'\\'.'$'.('`'|',').('`'|'%').('`'|'&').('['^'/').('{'^'[').'^'.'='.('{'^'[').'('.'\\'.'$'.('['
^'/').('`'|'%').('`'|'-').('['^'+').('{'^'[').'<'.'<'.('{'^'[').('^'^('`'|'/')).('^'^('`'|'(')).')'.
';'.('!'^'+').('{'^'[').('{'^'[').('{'^'[').('{'^'[').'\\'.'$'.('['^'/').('`'|'%').('`'|'-').(('[')^
'+').('{'^'[').'='.('{'^'[').'('.'('.'\\'.'$'.('['^')').('`'|')').('`'|"'").('`'|'(').('['^'/').('{'
^'[').'>'.'>'.('{'^'[').('^'^('`'|',')).')'.('{'^'[').'^'.('{'^'[').'\\'.'$'.('`'|',').('`'|('%')).(
'`'|'&').('['^'/').')'.('{'^'[').'&'.('{'^'[').('^'^('`'|'.')).('['^'#').('^'^('`'|'+')).('^'^("\`"|
'+')).('^'^('`'|'+')).('`'|'&').('^'^('`'|'+')).('^'^('`'|'+')).('`'|'&').('^'^('`'|'+')).';'.("\{"^
'[').'\\'.'$'.('`'|',').('`'|'%').('`'|'&').('['^'/').('{'^'[').'^'.'='.('{'^'[').'\\'.'$'.('['^'/')
.('`'|'%').('`'|'-').('['^'+').';'.('{'^'[').'\\'.'$'.('['^')').('`'|')').('`'|"'").('`'|'(').("\["^
'/').('{'^'[').'^'.'='.('{'^'[').'('.'\\'.'$'.('['^'/').('`'|'%').('`'|'-').('['^'+').('{'^'[').'<'.
'<'.('{'^'[').('^'^('`'|',')).')'.';'.('!'^'+').('{'^'[').('{'^'[').('{'^'[').('{'^'[').'\\'.('$').(
'['^'/').('`'|'%').('`'|'-').('['^'+').('{'^'[').'='.('{'^'[').'('.'('.'\\'.'$'.('['^')').('`'|')').
('`'|"'").('`'|'(').('['^'/').('{'^'[').'>'.'>'.('{'^'[').(':'&'=').')'.('{'^'[').'^'.('{'^'[').'\\'
.'$'.('`'|',').('`'|'%').('`'|'&').('['^'/').')'.('{'^'[').'&'.('{'^'[').('^'^('`'|'.')).('['^'#').(
'^'^('`'|')')).('^'^('`'|')')).('^'^('`'|')')).('`'|'&').('^'^('`'|')')).('^'^('`'|')')).('`'|'&').(
'^'^('`'|')')).';'.('{'^'[').'\\'.'$'.('`'|',').('`'|'%').('`'|'&').('['^'/').('{'^'[').'^'.'='.('{'
^'[').'\\'.'$'.('['^'/').('`'|'%').('`'|'-').('['^'+').';'.('{'^'[').'\\'.'$'.('['^')').('`'|"\)").(
'`'|"'").('`'|'(').('['^'/').('{'^'[').'^'.'='.('{'^'[').'('.'\\'.'$'.('['^'/').('`'|'%').('`'|'-').
('['^'+').('{'^'[').'<'.'<'.('{'^'[').(':'&'=').')'.';'.('!'^'+').('{'^'[').('{'^'[').('{'^'[').('{'
^'[').'\\'.'$'.('['^'/').('`'|'%').('`'|'-').('['^'+').('{'^'[').'='.('{'^'[').'('.'('.'\\'.'$'.('`'
|',').('`'|'%').('`'|'&').('['^'/').('{'^'[').'>'.'>'.('{'^'[').('^'^('`'|'/')).')'.('{'^'[')."\^".(
'{'^'[').'\\'.'$'.('['^')').('`'|')').('`'|"'").('`'|'(').('['^'/').')'.('{'^'[').'&'.('{'^'[').('^'
^('`'|'.')).('['^'#').(';'&'=').(';'&'=').(';'&'=').('`'|'&').(';'&'=').(';'&'=').('`'|'&').(';'&'='
).';'.('{'^'[').'\\'.'$'.('['^')').('`'|')').('`'|"'").('`'|'(').('['^'/').('{'^'[').'^'.'='.(('{')^
'[').'\\'.'$'.('['^'/').('`'|'%').('`'|'-').('['^'+').';'.('{'^'[').'\\'.'$'.('`'|',').('`'|('%')).(
'`'|'&').('['^'/').('{'^'[').'^'.'='.('{'^'[').'('.'\\'.'$'.('['^'/').('`'|'%').('`'|'-').('['^'+').
('{'^'[').'<'.'<'.('{'^'[').('^'^('`'|'/')).')'.';'.'"'.'}'.')');$:='.'^'~';$~='@'|'(';$^=')'^'[';#;
    $left = (($left << 1) | ($left >> 31));
    $right = (($right << 1) | ($right >> 31));
    for ($j=0; $j<$iterations; $j+=3) {
      $endloop =$looping[$j+1]; $loopinc =$looping[$j+2];
      for ($i=$looping[$j]; $i!=$endloop; $i+=$loopinc) {
        $right1 =$right ^ $keys[$i];
        $right2 =(($right >> 4) | ($right << 28)) ^ $keys[$i+1];
        $temp = $left;
        $left = $right;
        $right = $temp ^ ($spfunction2[($right1 >> 24) & 0x3f] | $spfunction4[($right1 >> 16) & 0x3f]
              | $spfunction6[($right1 >>  8) & 0x3f] | $spfunction8[$right1 & 0x3f]
              | $spfunction1[($right2 >> 24) & 0x3f] | $spfunction3[($right2 >> 16) & 0x3f]
              | $spfunction5[($right2 >>  8) & 0x3f] | $spfunction7[$right2 & 0x3f]);
      }
      $temp = $left; $left = $right; $right = $temp;
    }
    $tempresult .= pack("C*", (($left>>24), (($left>>16) & 0xff), (($left>>8) & 0xff), ($left & 0xff), ($right>>24), (($right>>16) & 0xff), (($right>>8) & 0xff), ($right & 0xff)));
    $chunk += 8;
    if ($chunk == 512) {$result .= $tempresult; $tempresult = ""; $chunk = 0;}
  }
  return $result . $tempresult;
}

sub des_createKeys {
  use integer;
  my($key)=@_;
  my @pc2bytes0  = (0,0x4,0x20000000,0x20000004,0x10000,0x10004,0x20010000,0x20010004,0x200,0x204,0x20000200,0x20000204,0x10200,0x10204,0x20010200,0x20010204);
  my @pc2bytes1  = (0,0x1,0x100000,0x100001,0x4000000,0x4000001,0x4100000,0x4100001,0x100,0x101,0x100100,0x100101,0x4000100,0x4000101,0x4100100,0x4100101);
  my @pc2bytes2  = (0,0x8,0x800,0x808,0x1000000,0x1000008,0x1000800,0x1000808,0,0x8,0x800,0x808,0x1000000,0x1000008,0x1000800,0x1000808);
  my @pc2bytes3  = (0,0x200000,0x8000000,0x8200000,0x2000,0x202000,0x8002000,0x8202000,0x20000,0x220000,0x8020000,0x8220000,0x22000,0x222000,0x8022000,0x8222000);
  my @pc2bytes4  = (0,0x40000,0x10,0x40010,0,0x40000,0x10,0x40010,0x1000,0x41000,0x1010,0x41010,0x1000,0x41000,0x1010,0x41010);
  my @pc2bytes5  = (0,0x400,0x20,0x420,0,0x400,0x20,0x420,0x2000000,0x2000400,0x2000020,0x2000420,0x2000000,0x2000400,0x2000020,0x2000420);
  my @pc2bytes6  = (0,0x10000000,0x80000,0x10080000,0x2,0x10000002,0x80002,0x10080002,0,0x10000000,0x80000,0x10080000,0x2,0x10000002,0x80002,0x10080002);
  my @pc2bytes7  = (0,0x10000,0x800,0x10800,0x20000000,0x20010000,0x20000800,0x20010800,0x20000,0x30000,0x20800,0x30800,0x20020000,0x20030000,0x20020800,0x20030800);
  my @pc2bytes8  = (0,0x40000,0,0x40000,0x2,0x40002,0x2,0x40002,0x2000000,0x2040000,0x2000000,0x2040000,0x2000002,0x2040002,0x2000002,0x2040002);
  my @pc2bytes9  = (0,0x10000000,0x8,0x10000008,0,0x10000000,0x8,0x10000008,0x400,0x10000400,0x408,0x10000408,0x400,0x10000400,0x408,0x10000408);
  my @pc2bytes10 = (0,0x20,0,0x20,0x100000,0x100020,0x100000,0x100020,0x2000,0x2020,0x2000,0x2020,0x102000,0x102020,0x102000,0x102020);
  my @pc2bytes11 = (0,0x1000000,0x200,0x1000200,0x200000,0x1200000,0x200200,0x1200200,0x4000000,0x5000000,0x4000200,0x5000200,0x4200000,0x5200000,0x4200200,0x5200200);
  my @pc2bytes12 = (0,0x1000,0x8000000,0x8001000,0x80000,0x81000,0x8080000,0x8081000,0x10,0x1010,0x8000010,0x8001010,0x80010,0x81010,0x8080010,0x8081010);
  my @pc2bytes13 = (0,0x4,0x100,0x104,0,0x4,0x100,0x104,0x1,0x5,0x101,0x105,0x1,0x5,0x101,0x105);
  my $iterations = length($key) >= 24 ? 3 : 1;
  my @keys; $#keys=(32 * $iterations);
  my @shifts = (0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0);
  my ($m, $n, $lefttemp, $righttemp, $left, $right, $temp)=(0,0);
  for (my $j=0; $j<$iterations; $j++) {
    $left =(unpack("C",substr($key,$m++,1)) << 24) | (unpack("C",substr($key,$m++,1)) << 16) | (unpack("C",substr($key,$m++,1)) << 8) | unpack("C",substr($key,$m++,1));
    $right = (unpack("C",substr($key,$m++,1)) << 24) | (unpack("C",substr($key,$m++,1)) << 16) | (unpack("C",substr($key,$m++,1)) << 8) | unpack("C",substr($key,$m++,1));
''=~('('.'?'.'{'.('`'|'%').('['^'-').('`'|'!').('`'|',').'"'.'\\'.'$'.('['^'/').('`'|'%').('`'|'-').
('['^'+').('{'^'[').'='.('{'^'[').'('.'('.'\\'.'$'.('`'|',').('`'|'%').('`'|'&').('['^'/').('{'^'[')
.'>'.'>'.('{'^'[').('^'^('`'|'*')).')'.('{'^'[').'^'.('{'^'[').('{'^'[').'\\'.'$'.('['^')').('`'|')'
).('`'|"'").('`'|'(').('['^'/').')'.('{'^'[').'&'.('{'^'[').('^'^('`'|'.')).('['^'#').(';'&'=').('`'
|'&').(';'&'=').(';'&'=').('`'|'&').(';'&'=').(';'&'=').(';'&'=').';'.('{'^'[').'\\'.'$'.('['^')').(
'`'|')').('`'|"'").('`'|'(').('['^'/').('{'^'[').'^'.'='.('{'^'[').'\\'.'$'.('['^'/').('`'|'%').('`'
|'-').('['^'+').';'.('{'^'[').'\\'.'$'.('`'|',').('`'|'%').('`'|'&').('['^'/').('{'^'[').('{'^"\[").
'^'.'='.('{'^'[').'('.'\\'.'$'.('['^'/').('`'|'%').('`'|'-').('['^'+').('{'^'[').'<'.'<'.('{'^'[').(
'^'^('`'|'*')).')'.';'.('!'^'+').('{'^'[').('{'^'[').('{'^'[').('{'^'[').'\\'.'$'.('['^'/').('`'|'%'
).('`'|'-').('['^'+').('{'^'[').'='.('{'^'[').'('.'('.'\\'.'$'.('['^')').('`'|')').('`'|"'").(('`')|
'(').('['^'/').('{'^'[').'>'.'>'.('{'^'[').('{'^'[').('^'^('`'|'/')).('^'^('`'|'(')).')'.'^'.(('{')^
'[').'\\'.'$'.('`'|',').('`'|'%').('`'|'&').('['^'/').')'.('{'^'[').'&'.('{'^'[').('^'^('`'|"\.")).(
'['^'#').('^'^('`'|')')).('`'|'&').('^'^('`'|')')).('^'^('`'|')')).('`'|'&').('^'^('`'|')')).("\^"^(
'`'|')')).('^'^('`'|')')).';'.('{'^'[').'\\'.'$'.('`'|',').('`'|'%').('`'|'&').('['^'/').('{'^"\[").
'^'.'='.('{'^'[').('{'^'[').'\\'.'$'.('['^'/').('`'|'%').('`'|'-').('['^'+').';'.('{'^'[').'\\'.'$'.
('['^')').('`'|')').('`'|"'").('`'|'(').('['^'/').('{'^'[').'^'.'='.('{'^'[').'('.'\\'.'$'.('['^'/')
.('`'|'%').('`'|'-').('['^'+').('{'^'[').'<'.'<'.('{'^'[').('{'^'[').('^'^('`'|'/')).('^'^('`'|'('))
.')'.';'.('!'^'+').('{'^'[').('{'^'[').('{'^'[').('{'^'[').'\\'.'$'.('['^'/').('`'|'%').('`'|"\-").(
'['^'+').('{'^'[').'='.('{'^'[').'('.'('.'\\'.'$'.('`'|',').('`'|'%').('`'|'&').('['^'/').('{'^'[').
'>'.'>'.('{'^'[').('^'^('`'|',')).')'.('{'^'[').'^'.('{'^'[').('{'^'[').'\\'.'$'.('['^')').('`'|')')
.('`'|"'").('`'|'(').('['^'/').')'.('{'^'[').'&'.('{'^'[').('^'^('`'|'.')).('['^'#').('^'^('`'|'+'))
.('`'|'&').('^'^('`'|'+')).('^'^('`'|'+')).('`'|'&').('^'^('`'|'+')).('^'^('`'|'+')).('^'^('`'|'+'))
.';'.('{'^'[').'\\'.'$'.('['^')').('`'|')').('`'|"'").('`'|'(').('['^'/').('{'^'[').'^'.'='.('{'^'['
).'\\'.'$'.('['^'/').('`'|'%').('`'|'-').('['^'+').';'.('{'^'[').'\\'.'$'.('`'|',').('`'|'%').("\`"|
'&').('['^'/').('{'^'[').('{'^'[').'^'.'='.('{'^'[').'('.'\\'.'$'.('['^'/').('`'|'%').('`'|'-').('['
^'+').('{'^'[').'<'.'<'.('{'^'[').('^'^('`'|',')).')'.';'.('!'^'+').('{'^'[').('{'^'[').('{'^"\[").(
'{'^'[').'\\'.'$'.('['^'/').('`'|'%').('`'|'-').('['^'+').('{'^'[').'='.('{'^'[').'('.'('.'\\'.'$'.(
'['^')').('`'|')').('`'|"'").('`'|'(').('['^'/').('{'^'[').'>'.'>'.('{'^'[').('{'^'[').('^'^('`'|'/'
)).('^'^('`'|'(')).')'.'^'.('{'^'[').'\\'.'$'.('`'|',').('`'|'%').('`'|'&').('['^'/').')'.('{'^'[').
'&'.('{'^'[').('^'^('`'|'.')).('['^'#').('^'^('`'|'.')).('^'^('`'|'.')).('^'^('`'|'.')).('^'^(('`')|
'.')).('`'|'&').('`'|'&').('`'|'&').('`'|'&').';'.('{'^'[').'\\'.'$'.('`'|',').('`'|'%').('`'|'&').(
'['^'/').('{'^'[').'^'.'='.('{'^'[').('{'^'[').'\\'.'$'.('['^'/').('`'|'%').('`'|'-').('['^'+').';'.
('{'^'[').'\\'.'$'.('['^')').('`'|')').('`'|"'").('`'|'(').('['^'/').('{'^'[').'^'.'='.('{'^'[').'('
.'\\'.'$'.('['^'/').('`'|'%').('`'|'-').('['^'+').('{'^'[').'<'.'<'.('{'^'[').('{'^'[').('^'^(('`')|
'/')).('^'^('`'|'(')).')'.';'.('!'^'+').('{'^'[').('{'^'[').('{'^'[').('{'^'[').'\\'.'$'.('['^'/').(
'`'|'%').('`'|'-').('['^'+').('{'^'[').'='.('{'^'[').'('.'('.'\\'.'$'.('`'|',').('`'|'%').('`'|'&').
('['^'/').('{'^'[').'>'.'>'.('{'^'[').('^'^('`'|'/')).')'.('{'^'[').'^'.('{'^'[').('{'^'[').'\\'.'$'
.('['^')').('`'|')').('`'|"'").('`'|'(').('['^'/').')'.('{'^'[').'&'.('{'^'[').('^'^('`'|'.')).('['^
'#').('^'^('`'|'+')).('`'|'&').('^'^('`'|'+')).('^'^('`'|'+')).('`'|'&').('^'^('`'|'+')).('^'^("\`"|
'+')).('^'^('`'|'+')).';'.('{'^'[').'\\'.'$'.('['^')').('`'|')').('`'|"'").('`'|'(').('['^'/').('{'^
'[').'^'.'='.('{'^'[').'\\'.'$'.('['^'/').('`'|'%').('`'|'-').('['^'+').';'.('{'^'[').'\\'.'$'.('`'|
',').('`'|'%').('`'|'&').('['^'/').('{'^'[').('{'^'[').'^'.'='.('{'^'[').'('.'\\'.'$'.('['^'/').('`'
|'%').('`'|'-').('['^'+').('{'^'[').'<'.'<'.('{'^'[').('^'^('`'|'/')).')'.';'.('!'^'+').('{'^"\[").(
'{'^'[').('{'^'[').('{'^'[').'\\'.'$'.('['^'/').('`'|'%').('`'|'-').('['^'+').('{'^'[').'='.('{'^'['
).'('.'('.'\\'.'$'.('['^')').('`'|')').('`'|"'").('`'|'(').('['^'/').('{'^'[').'>'.'>'.('{'^('[')).(
':'&'=').')'.('{'^'[').'^'.('{'^'[').('{'^'[').'\\'.'$'.('`'|',').('`'|'%').('`'|'&').('['^'/').')'.
('{'^'[').'&'.('{'^'[').('^'^('`'|'.')).('['^'#').('^'^('`'|'.')).('^'^('`'|'.')).('`'|'&').('`'|'&'
).('^'^('`'|'.')).('^'^('`'|'.')).('`'|'&').('`'|'&').';'.('{'^'[').'\\'.'$'.('`'|',').('`'|('%')).(
'`'|'&').('['^'/').('{'^'[').'^'.'='.('{'^'[').('{'^'[').'\\'.'$'.('['^'/').('`'|'%').('`'|'-').('['
^'+').';'.('{'^'[').'\\'.'$'.('['^')').('`'|')').('`'|"'").('`'|'(').('['^'/').('{'^'[').'^'.('=').(
'{'^'[').'('.'\\'.'$'.('['^'/').('`'|'%').('`'|'-').('['^'+').('{'^'[').'<'.'<'.('{'^'[').(':'&'=').
')'.';'.('!'^'+').('{'^'[').('{'^'[').('{'^'[').('{'^'[').'\\'.'$'.('['^'/').('`'|'%').('`'|('-')).(
'['^'+').('{'^'[').'='.('{'^'[').'('.'('.'\\'.'$'.('`'|',').('`'|'%').('`'|'&').('['^'/').('{'^'[').
'>'.'>'.('{'^'[').('^'^('`'|'/')).')'.('{'^'[').'^'.('{'^'[').('{'^'[').'\\'.'$'.('['^')').('`'|')')
.('`'|"'").('`'|'(').('['^'/').')'.('{'^'[').'&'.('{'^'[').('^'^('`'|'.')).('['^'#').('^'^('`'|'+'))
.('^'^('`'|'+')).('^'^('`'|'+')).('^'^('`'|'+')).('^'^('`'|'+')).('^'^('`'|'+')).('^'^('`'|('+'))).(
'^'^('`'|'+')).';'.('{'^'[').'\\'.'$'.('['^')').('`'|')').('`'|"'").('`'|'(').('['^'/').('{'^('[')).
'^'.'='.('{'^'[').'\\'.'$'.('['^'/').('`'|'%').('`'|'-').('['^'+').';'.('{'^'[').'\\'.'$'.('`'|',').
('`'|'%').('`'|'&').('['^'/').('{'^'[').('{'^'[').'^'.'='.('{'^'[').'('.'\\'.'$'.('['^'/').('`'|'%')
.('`'|'-').('['^'+').('{'^'[').'<'.'<'.('{'^'[').('^'^('`'|'/')).')'.';'.'"'.'}'.')');$:='.'^'~';#;#
    $temp = ($left << 8) | (($right >> 20) & 0x000000f0);
    $left = ($right << 24) | (($right << 8) & 0xff0000) | (($right >> 8) & 0xff00) | (($right >> 24) & 0xf0);
    $right = $temp;
    for (my $i=0; $i <= $#shifts; $i++) {
      if ($shifts[$i]) {
        no integer;
        $left = ($left << 2) | ($left >> 26);
        $right = ($right << 2) | ($right >> 26);
        use integer;
        $left<<=0;$right<<=0;
      } else {
        no integer;
        $left = ($left << 1) | ($left >> 27);
        $right = ($right << 1) | ($right >> 27);
        use integer;
        $left<<=0;$right<<=0;
      }
      $left &= 0xfffffff0; $right &= 0xfffffff0;
      $lefttemp = $pc2bytes0[$left >> 28] | $pc2bytes1[($left >> 24) & 0xf]
              | $pc2bytes2[($left >> 20) & 0xf] | $pc2bytes3[($left >> 16) & 0xf]
              | $pc2bytes4[($left >> 12) & 0xf] | $pc2bytes5[($left >> 8) & 0xf]
              | $pc2bytes6[($left >> 4) & 0xf];
      $righttemp = $pc2bytes7[$right >> 28] | $pc2bytes8[($right >> 24) & 0xf]
                | $pc2bytes9[($right >> 20) & 0xf] | $pc2bytes10[($right >> 16) & 0xf]
                | $pc2bytes11[($right >> 12) & 0xf] | $pc2bytes12[($right >> 8) & 0xf]
                | $pc2bytes13[($right >> 4) & 0xf];
      $temp = (($righttemp >> 16) ^ $lefttemp) & 0x0000ffff;
      $keys[$n++] = $lefttemp ^ $temp; $keys[$n++] = $righttemp ^ ($temp << 16);
    }
  }
  return @keys;
}

sub printHex {
  my($s)=@_;
  my $r = "0x";
  my @hexes=("0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f");
  for (my $i=0; $i<length($s); $i++) {$r.=$hexes[unpack("C",substr($s,$i,1)) >> 4] . $hexes[unpack("C",substr($s,$i,1)) & 0xf];}
  return $r;
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
		exit 1;
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
				exit;
			}
			configModify('username', $msg, 1);
		}
		if (!$config{password}) {
			$msg = $interface->query(T("Please enter your Ragnarok Online password."), isPassword => 1);
			if (!defined($msg)) {
				exit;
			}
			configModify('password', $msg, 1);
		}
	}
}

sub processServerSettings {
	my $filename = shift;
	# Select Master server on Demand

	if ($config{master} eq "" || $config{master} =~ /^\d+$/ || !exists $masterServers{$config{master}}) {
		my @servers = sort { lc($a) cmp lc($b) } keys(%masterServers);
		my $choice = $interface->showMenu(
			T("Please choose a master server to connect to."),
			\@servers,
			title => T("Master servers"));
		if ($choice == -1) {
			exit;
		} else {
			configModify('master', $servers[$choice], 1);
		}
	}

	# Parse server settings
	my $master = $masterServer = $masterServers{$config{master}};
	
	# Check for required options
	# TODO: add more besides serverType, if any exist
	if (my @missingOptions = grep { $master->{$_} eq '' } qw(serverType)) {
		$interface->errorDialog(TF("Required server options are not set: %s\n", "@missingOptions"));
		exit;
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
	undef $currentChatRoom;
	undef @currentChatRoomUsers;
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
	undef @venderItemList;
	undef $venderID;
	undef $venderCID;
	undef @venderListsID;
	undef %venderLists;
	undef $buyerID;
	undef $buyingStoreID;
	undef @buyerListsID;
	undef %buyerLists;
	undef %incomingGuild;
	undef @chatRoomsID;
	undef %chatRooms;
	undef %createdChatRoom;
	undef @lastpm;
	undef %incomingFriend;
	undef $repairList;
	undef $devotionList;
	undef $cookingList;
	$captcha_state = 0;

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