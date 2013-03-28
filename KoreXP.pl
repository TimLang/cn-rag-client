#BEGIN { PerlApp::_init(3816272); eval INC('*SETUP'); die $@ if $@ }
#line 1 "Kore-XP.pl"
#!/usr/bin/env perl
#########################################################################
#  KoreXP
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################

use Time::HiRes qw(time usleep);
use IO::Socket;
use Getopt::Long;
use Digest::MD5 qw(md5);
use Win32::API;
use Win32::Console;
use Win32::Sound;

$EV_APPEARED					= 1;
$EV_DISAPPEARED					= 2;
$EV_CONNECTED					= 3;
$EV_DISCONNECTED				= 4;
$EV_TELEPORTED					= 5;
$EV_EXISTS						= 6;
$EV_SPAWNED						= 7;
$EV_TRANSFORMED					= 8;
$EV_DIED						= 9;
$EV_REMOVED						= 10;
$EV_GET_INFO					= 11;
$EV_STAND						= 12;
$EV_SIT							= 13;
$EV_LEVEL_UP					= 14;
$EV_JOB_LEVEL_UP				= 15;
$EV_MOVE						= 16;
$EV_MOVE_BREAK					= 17;
$EV_EQUIP						= 18;
$EV_EQUIP_FAILED				= 19;
$EV_UNEQUIP						= 20;
$EV_NO_ARROW					= 21;
$EV_STAT_CHANGED				= 22;
$EV_EMOTION						= 23;
$EV_GO_ATTACK_MONSTER			= 24;
$EV_ATTACK_MONSTER				= 25;
$EV_ATTACK_PLAYER				= 26;
$EV_ATTACK_YOU					= 27;
$EV_SKILL_USE_AT				= 28; # 117
$EV_SKILL_AREA_AT				= 29; # 11F
$EV_SKILL_DAMAGE_ON_MONSTER		= 30; # 114
$EV_SKILL_DAMAGE_ON_PLAYER		= 31; # 114
$EV_SKILL_DAMAGE_ON_YOU			= 32; # 114
$EV_SKILL_DAMAGE_ON				= 33; # 114
$EV_SKILL_RESTORE_ON_MONSTER	= 34; # 11A
$EV_SKILL_RESTORE_ON_PLAYER		= 35; # 11A
$EV_SKILL_RESTORE_ON_YOU		= 36; # 11A
$EV_SKILL_RESTORE_ON			= 37; # 11A
$EV_SKILL_CASTING_ON_MONSTER	= 38; # 13E
$EV_SKILL_CASTING_ON_PLAYER		= 39; # 13E
$EV_SKILL_CASTING_ON_YOU		= 40; # 13E
$EV_SKILL_CASTING_ON			= 41; # 13E
$EV_SKILL_CASTING_AT			= 42; # 13E
$EV_SKILL_FAILED				= 43;
$EV_SKILL_CLEARED				= 44;
$EV_SKILL_ADDED					= 45;
$EV_SKILL_UPDATED				= 46;
$EV_ITEM_PICKUP					= 47;
$EV_ITEM_USED					= 48;
$EV_ITEM_IDENTIFY				= 49;
$EV_DEAL_REQUEST				= 50;
$EV_DEAL_ADD					= 51;
$EV_DEAL_ADD_ZENY				= 52;
$EV_DEAL_ACCEPT					= 53;
$EV_DEAL_CONFIRM				= 54;
$EV_DEAL_CANCELLED				= 55;
$EV_DEAL_COMPLETED				= 56;
$EV_INVENTORY_ADDED				= 57;
$EV_INVENTORY_REMOVED			= 58;
$EV_INVENTORY_UPDATED			= 59;
$EV_CART_CAP					= 60;
$EV_CART_ADDED					= 61;
$EV_CART_ADD_FAILED				= 62;
$EV_CART_REMOVED				= 63;
$EV_CART_UPDATED				= 64;
$EV_STORAGE_CAP					= 65;
$EV_STORAGE_OPENED				= 66;
$EV_STORAGE_ADDED				= 67;
$EV_STORAGE_REMOVED				= 68;
$EV_STORAGE_UPDATED				= 69;
$EV_STORAGE_CLOSED				= 70;
$EV_MVP_ITEM					= 71;
$EV_MVP_EXP						= 72;
$EV_MAP_CHANGED					= 73;
$EV_CONTINUE					= 74;
$EV_RESPONSE					= 75;
$EV_DONT_TALK					= 76;
$EV_BUY_SELL					= 77;
$EV_BUY							= 78;
$EV_SELL						= 79;
$EV_IMAGE						= 80;
$EV_TALK_DISAPPEARED			= 81;
$EV_PORTAL_EXISTS				= 82;
$EV_PORTAL_DISAPPEARED			= 83;
$EV_PARTY_REQUEST				= 84;
$EV_PARTY_JOIN					= 85;
$EV_PARTY_LEFT					= 86;
$EV_PARTY_UPDATED				= 87;
$EV_PARTY_HP					= 88;
$EV_PARTY_MOVE					= 89;
$EV_PARTY_SHARE					= 90;
$EV_PARTY_NOSHARE				= 91;
$EV_GUILD_UPDATED				= 92;
$EV_GUILD_MEMBER_CLEARED		= 93;
$EV_GUILD_MEMBER_ADDED			= 94;
$EV_GUILD_MEMBER_UPDATED		= 95;
$EV_GUILD_ALLIES_CLEARED		= 96;
$EV_GUILD_ALLIES_ADDED			= 97;
$EV_GUILD_ALLIES_REMOVED		= 98;
$EV_GUILD_ENEMY_CLEARED			= 99;
$EV_GUILD_ENEMY_ADDED			= 100;
$EV_GUILD_ENEMY_REMOVED			= 101;
$EV_GUILD_JOIN_REQUEST			= 102;
$EV_GUILD_ALLY_REQUEST			= 103;
$EV_ITEM_EXISTS					= 104;
$EV_ITEM_APPEARED				= 105;
$EV_ITEM_DISAPPEARED			= 106;
$EV_CRITICAL					= 107;
$EV_WARNING						= 108;
$EV_OPTION						= 109;
$EV_EFFECT						= 110;
$EV_PET_BORN					= 111;
$EV_PET_FRIENDLY				= 112;
$EV_PET_HUNGRY					= 113;
$EV_PET_ACCESSORY				= 114;
$EV_PET_ACTION					= 115;
$EV_PET_SPAWNED					= 116;
$EV_PET_KEEP					= 117;
$EV_PET_INFO					= 118;
$EV_PET_CATCH					= 119;
$EV_SHOP_APPEARED				= 120;
$EV_SHOP_DISAPPEARED			= 121;

$EV_ARROWCRAFT					= 122;
$EV_EGG							= 123;
$EV_IDENTIFY					= 124;
$EV_MIXTURE						= 125;

srand(time());

$version = "1.0405.2004";

$versionText = "***KoreXP $version - Ragnarok Online Bot - http://modkore.sf.net***\n\n";

$update{'packet'} = 0;
$update{'skill'} = 0;
$update{'monster'} = 0;
$update{'npc'} = 0;

$profile = "";
$profilename = "";
&GetOptions('profile=s', \$profilename);

if ($profilename ne "") {
	$file = $profilename."_error.txt";
} else {
	$file = "error.txt";
}

$file = "log/$file";

open "STDERR", "> $file" or die "Redirect STDERR to $file failed.\n";

if ($profilename eq "") {
	$profile = "control";
} else {
	$profile = "control/$profilename";
	MakeProfile();
}

print $versionText;

sub CopyFile {
	my $des = shift;
	my $src = shift;
	my $data;
	my $len;

	$len = (-s $src);

	open FILE, "< $src";
	binmode(FILE);
	sysread(FILE, $data, $len);
	close FILE;

	open FILE, "> $des";
	binmode(FILE);
	syswrite(FILE, $data);
	close FILE;
}

sub MakeProfile {
	unless (-e $profile) {
		print "- Profile not found. Create profile $profile.\n";

		mkdir $profile;

		CopyFile("$profile/config.txt", "control/config.txt");
		CopyFile("$profile/debug.txt", "control/debug.txt");
		CopyFile("$profile/items_control.txt", "control/items_control.txt");
		CopyFile("$profile/mon_control.txt", "control/mon_control.txt");
		CopyFile("$profile/overallauth.txt", "control/overallauth.txt");
		CopyFile("$profile/cartitems.txt", "control/cartitems.txt");
		CopyFile("$profile/pickupitems.txt", "control/pickupitems.txt");
		CopyFile("$profile/responses.txt", "control/responses.txt");
		CopyFile("$profile/timeouts.txt", "control/timeouts.txt");
		CopyFile("$profile/cmd_resps.txt", "control/cmd_resps.txt");
		CopyFile("$profile/avoids.txt", "control/avoids.txt");
		CopyFile("$profile/gms.txt", "control/gms.txt");

		print "\n";
	}
}

if (!parsePacketsFile("tables/_rpackets.txt", \%rpackets)) {
	exit;
}

parsePacketsFile("tables/_spackets.txt", \%spackets);

addParseFiles("$profile/config.txt", \%config, \&parseDataFile2);
addParseFiles("$profile/debug.txt", \%debug, \&parseDataFile2);
load(\@parseFiles);

if (!$config{'buildType'}) {
} elsif ($config{'buildType'} == 1) {
	$config{'remoteSocket'} = 1;
}

if ($config{'wrapperInterface'}) {
	require Wrapper;

	if (!$config{'buildType'}) {
		Win32::Console->new(STD_OUTPUT_HANDLE)->Free or die "Free console failed.\n";
	}

	tie *STDOUT, "Kore::Wrapper::TiePrint";

	Kore::Wrapper::SetMenuResponseAuto($config{'respAuto'});
	Kore::Wrapper::SetMenuSellAuto($config{'sellAuto'});
	Kore::Wrapper::SetMenuStorageAuto($config{'storageAuto'});
	Kore::Wrapper::UpdateAi($config{'aiStart'});
	Kore::Wrapper::UpdatePopup($config{'wrapperPopup'});
} else {
	if (!$config{'buildType'}) {
		$CONSOLE = Win32::Console->new(STD_OUTPUT_HANDLE) or die "Could not init Console\n";
	}
}

sub SetColor {
	$color = shift;
	if (!$config{'buildType'} && !$config{'wrapperInterface'}) {
		$CONSOLE->Attr($color);
	}
}

sub SetWrapperTitle {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::SetKoreTitle("Kore++ ($chars[$config{'char'}]{'name'}) - $remainText");
	}
}

sub SetWrapperPartyTitle {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::SetPartyTitle($chars[$config{'char'}]{'party'}{'name'});
	}
}

sub EnableWrapperSell {
	my $val = shift;

	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::EnableSell($val);
	}
}

sub ShowWrapper {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::ShowKore();
	}
}

sub UpdateWrapper {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::SetMenuResponseAuto($config{'respAuto'});
		Kore::Wrapper::SetMenuSellAuto($config{'sellAuto'});
		Kore::Wrapper::SetMenuStorageAuto($config{'storageAuto'});
		Kore::Wrapper::UpdateAi($AI);
		Kore::Wrapper::UpdatePopup($config{'wrapperPopup'});
		Kore::Wrapper::Update();

		if (Kore::Wrapper::IsClose()) {
			return 1;
		}
	}

	return 0;
}

sub UpdateWrapperEvent {
	my $msg = shift;

	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::UpdateEvent($msg);
	}
}

sub UpdateWrapperAiBegin {
	my $ai = shift;

	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::UpdateAiBegin($ai);
	}
}

sub UpdateWrapperAiEnd {
	my $ai = shift;

	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::UpdateAiEnd($ai);
	}
}

sub UpdateWrapperStatus {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::UpdateStatus($chars[$config{'char'}]);
	}
}

sub UpdateWrapperMap {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::UpdateMap($maps_lut{$field{'name'}.'.rsw'}, $field{'name'}, $field{'width'}, $field{'height'});
	}
}

sub UpdateWrapperSkill {
	my $id =  shift;
	my $no;
	my $name;
	my $lv;
	my $sp;
	my $use;
	my $nameID;
	my $i;

	if ($config{'wrapperInterface'}) {
		$nameID = $skillsID_lut{$id}{'nameID'};
		for ($i = 0; $i < @skillsID; $i++) {
			if ($skillsID[$i] eq $nameID) {
				$no = sprintf("%02d", $i);
				last;
			}
		}

		$name = $skills_lut{$nameID};
		$lv = $chars[$config{'char'}]{'skills'}{$nameID}{'lv'};

		if ($skillsSP_lut{$nameID}{$lv} > 0) {
			$sp = $skillsSP_lut{$nameID}{$lv};
		} else {
			$sp = $chars[$config{'char'}]{'skills'}{$nameID}{'sp'};
		}

		$use = $skillsUse_lut{$chars[$config{'char'}]{'skills'}{$nameID}{'use'}};
		if ($use eq "") {
			$use = $chars[$config{'char'}]{'skills'}{$nameID}{'use'};
		}

		Kore::Wrapper::UpdateSkill($no, $id, $name, $lv, $sp, $use);
	}
}

sub ClearWrapperSkill {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::ClearSkill();
	}
}

sub UpdateWrapperPlayer {
	my $id =  shift;
	my $event = shift;
	my $no;
	my $name;
	my $guild;
	my $sex;
	my $job;
	my $level;
	my $i;
	my $lowHead;
	my $topHead;
	my $midHead;
	my $party;

	if ($config{'wrapperInterface'}) {
		for ($i = 0; $i < @playersID; $i++) {
			if ($playersID[$i] eq $id) {
				$no = sprintf("%02d", $i);
				last;
			}
		}

		$name = "$players{$id}{'name'} [".getHex($id)."]";
		$guild = $players{$id}{'guild'}{'name'};
		$sex = $sex_lut{$players{$id}{'sex'}};
		$job = $jobs_lut{$players{$id}{'jobID'}};
		$level = $players{$id}{'lv'};

		$lowHead = $items_lut{$players{$id}{'look'}{'lowHead'}};
		$topHead = $items_lut{$players{$id}{'look'}{'topHead'}};
		$midHead = $items_lut{$players{$id}{'look'}{'midHead'}};

		$look = $lowHead;
		$look = PadStr($look, $topHead);
		$look = PadStr($look, $midHead);

		if (IsPartyOnline($id)) {
			$party = 1;
		} else {
			$party = 0;
		}

		Kore::Wrapper::UpdatePlayer($no, $name, $guild, $sex, $job, $level, $players{$id}{'pos_to'}{'x'}, $players{$id}{'pos_to'}{'y'}, $players{$id}{'dead'}, $look, $event, $party);
	}
}

sub RemoveWrapperPlayer {
	my $id =  shift;
	my $no;
	my $i;

	if ($config{'wrapperInterface'}) {
		for ($i = 0; $i < @playersID; $i++) {
			if ($playersID[$i] eq $id) {
				$no = sprintf("%02d", $i);
				last;
			}
		}

		Kore::Wrapper::RemovePlayer($no);
	}
}

sub ClearWrapperPlayer {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::ClearPlayer();
	}
}

sub UpdateWrapperMonster {
	my $id =  shift;
	my $event = shift;
	my $no;
	my $nameID;
	my $name;
	my $dmgTo;
	my $dmgFrom;
	my $i;

	if ($config{'wrapperInterface'}) {
		for ($i = 0; $i < @monstersID; $i++) {
			if ($monstersID[$i] eq $id) {
				$no = sprintf("%02d", $i);
				last;
			}
		}

		$nameID = $monsters{$id}{'nameID'};
		$name = "$monsters{$id}{'name'} [".getHex($id)."]";
		$dmgTo = ($monsters{$id}{'dmgToYou'} ne "")
			? $monsters{$id}{'dmgToYou'}
			: 0;
		$dmgFrom = ($monsters{$id}{'dmgFromYou'} ne "")
			? $monsters{$id}{'dmgFromYou'}
			: 0;

		Kore::Wrapper::UpdateMonster($no, $nameID, $name, $monsters{$id}{'pos_to'}{'x'}, $monsters{$id}{'pos_to'}{'y'}, $dmgTo, $dmgFrom, $event);
	}
}

sub RemoveWrapperMonster {
	my $id =  shift;
	my $no;
	my $i;

	if ($config{'wrapperInterface'}) {
		for ($i = 0; $i < @monstersID; $i++) {
			if ($monstersID[$i] eq $id) {
				$no = sprintf("%02d", $i);
				last;
			}
		}

		Kore::Wrapper::RemoveMonster($no);
	}
}

sub ClearWrapperMonster {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::ClearMonster();
	}
}

sub UpdateWrapperNpc {
	my $id =  shift;
	my $event = shift;
	my $no;
	my $i;

	if ($config{'wrapperInterface'}) {
		for ($i = 0; $i < @npcsID; $i++) {
			if ($npcsID[$i] eq $id) {
				$no = sprintf("%02d", $i);
				last;
			}
		}

		Kore::Wrapper::UpdateNpc($no, $npcs{$id}{'nameID'}, $npcs{$id}{'name'}, $npcs{$id}{'pos'}{'x'}, $npcs{$id}{'pos'}{'y'}, $event);
	}
}

sub RemoveWrapperNpc {
	my $id =  shift;
	my $no;
	my $i;

	if ($config{'wrapperInterface'}) {
		for ($i = 0; $i < @npcsID; $i++) {
			if ($npcsID[$i] eq $id) {
				$no = sprintf("%02d", $i);
				last;
			}
		}

		Kore::Wrapper::RemoveNpc($no);
	}
}

sub ClearWrapperNpc {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::ClearNpc();
	}
}

sub UpdateWrapperItem {
	my $id =  shift;
	my $no;
	my $name;
	my $amount;

	if ($config{'wrapperInterface'}) {
		for ($i = 0; $i < @itemsID; $i++) {
			if ($itemsID[$i] eq $id) {
				$no = sprintf("%02d", $i);
				last;
			}
		}

		$name = $items{$id}{'name'};
		$amount = $items{$id}{'amount'};

		Kore::Wrapper::UpdateItem($no, $name, $amount, $items{$id}{'pos'}{'x'}, $items{$id}{'pos'}{'y'});
	}
}

sub RemoveWrapperItem {
	my $id =  shift;
	my $no;
	my $i;

	if ($config{'wrapperInterface'}) {
		for ($i = 0; $i < @itemsID; $i++) {
			if ($itemsID[$i] eq $id) {
				$no = sprintf("%02d", $i);
				last;
			}
		}

		Kore::Wrapper::RemoveItem($no);
	}
}

sub ClearWrapperItem {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::ClearItem();
	}
}

sub UpdateWrapperGuild {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::UpdateGuild($chars[$config{'char'}]{'guild'});
	}
}

sub UpdateWrapperGuildMember {
	my $index =  shift;
	my $no;
	my $name;
	my $pos_index;
	my $title;
	my $job;
	my $level;
	my $exp;
	my $support;
	my $online;

	if ($config{'wrapperInterface'}) {
		$no = sprintf("%02d", $index);

		$name = $chars[$config{'char'}]{'guild'}{'member'}[$index]{'name'};
		$pos_index = $chars[$config{'char'}]{'guild'}{'member'}[$index]{'pos_index'};
		$title = $chars[$config{'char'}]{'guild'}{'title'}[$pos_index]{'name'};
		$level = $chars[$config{'char'}]{'guild'}{'member'}[$index]{'level'};
		$job = $jobs_lut{$chars[$config{'char'}]{'guild'}{'member'}[$index]{'jobID'}};
		$exp = $chars[$config{'char'}]{'guild'}{'member'}[$index]{'exp'};
		$support = $chars[$config{'char'}]{'guild'}{'member'}[$index]{'support'};
		$online = $chars[$config{'char'}]{'guild'}{'member'}[$index]{'online'};

		Kore::Wrapper::UpdateGuildMember($no, $name, $title, $job, $level, $exp, $support, $online);
	}
}

sub ClearWrapperGuildMember {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::ClearGuildMember();
	}
}

sub AddWrapperGuildAllies {
	my $index =  shift;
	my $name;

	if ($config{'wrapperInterface'}) {
		$name = $chars[$config{'char'}]{'guild'}{'allies'}[$index]{'name'};
		Kore::Wrapper::AddGuildAllies($name);
	}
}

sub ClearWrapperGuildAllies {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::ClearGuildAllies();
	}
}

sub AddWrapperGuildEnemy {
	my $index =  shift;
	my $name;

	if ($config{'wrapperInterface'}) {
		$name = $chars[$config{'char'}]{'guild'}{'enemy'}[$index]{'name'};
		Kore::Wrapper::AddGuildEnemy($name);
	}
}

sub ClearWrapperGuildEnemy {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::ClearGuildEnemy();
	}
}

sub UpdateWrapperParty {
	my $id =  shift;
	my $no;
	my $name;
	my $map;
	my $x;
	my $y;
	my $hp;
	my $hp_max;
	my $online;
	my $admin;
	my $you;
	my $i;

	if ($config{'wrapperInterface'} && %{$chars[$config{'char'}]{'party'}}) {
		for ($i = 0; $i < @partyUsersID; $i++) {
			if ($partyUsersID[$i] eq $id) {
				$no = sprintf("%02d", $i);
				last;
			}
		}

		if ($no eq "") {
			return;
		}

		$name = $chars[$config{'char'}]{'party'}{'users'}{$id}{'name'};

		if ($id eq $accountID) {
			$map = $field{'name'};
			$x = $chars[$config{'char'}]{'pos_to'}{'x'};
			$y = $chars[$config{'char'}]{'pos_to'}{'y'};
			$hp = $chars[$config{'char'}]{'hp'};
			$hp_max = $chars[$config{'char'}]{'hp_max'};
			$online = 1;
			$you = 1;
		} else {
			($map) = $chars[$config{'char'}]{'party'}{'users'}{$id}{'map'} =~ /([\s\S]*)\.gat/;
			$x = $chars[$config{'char'}]{'party'}{'users'}{$id}{'pos'}{'x'};
			$y = $chars[$config{'char'}]{'party'}{'users'}{$id}{'pos'}{'y'};
			$hp = $chars[$config{'char'}]{'party'}{'users'}{$id}{'hp'};
			$hp_max = $chars[$config{'char'}]{'party'}{'users'}{$id}{'hp_max'};
			$online = $chars[$config{'char'}]{'party'}{'users'}{$id}{'online'};
			$you = 0;
		}

		if ($map ne "") {
			$map = qq~$maps_lut{$map.'.rsw'} ($map)~;
		}

		$admin = $chars[$config{'char'}]{'party'}{'users'}{$id}{'admin'};

		Kore::Wrapper::UpdateParty($no, $name, $map, $x, $y, $hp, $hp_max, $online, $admin, $you);
	}
}

sub RemoveWrapperParty {
	my $id =  shift;
	my $no;
	my $i;

	if ($config{'wrapperInterface'}) {
		for ($i = 0; $i < @partyUsersID; $i++) {
			if ($partyUsersID[$i] eq $id) {
				$no = sprintf("%02d", $i);
				last;
			}
		}

		Kore::Wrapper::RemoveParty($no);
	}
}

sub ClearWrapperParty {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::ClearParty();
	}
}

sub UpdateWrapperVender {
	my $id =  shift;
	my $no;

	if ($config{'wrapperInterface'}) {
		for ($i = 0; $i < @venderListsID; $i++) {
			if ($venderListsID[$i] eq $id) {
				$no = sprintf("%02d", $i);
				last;
			}
		}

		return if ($no eq "");

		$name = $venderLists{$id}{'title'};
		if (%{$players{$id}}) {
			$owner = "$players{$id}{'name'} [".getHex($id)."]";
		} else {
			$owner = "Unknown [".getHex($id)."]";
		}

		Kore::Wrapper::UpdateVender($no, $name, $owner);
	}
}

sub RemoveWrapperVender {
	my $id =  shift;
	my $no;
	my $i;

	if ($config{'wrapperInterface'}) {
		for ($i = 0; $i < @venderListsID; $i++) {
			if ($venderListsID[$i] eq $id) {
				$no = sprintf("%02d", $i);
				last;
			}
		}

		Kore::Wrapper::RemoveVender($no);
	}
}

sub ClearWrapperVender {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::ClearVender();
	}
}

sub AddWrapperShopping {
	my $no =  shift;
	my $key;
	my $name;

	if ($config{'wrapperInterface'}) {
		$key = $vender_keys[$i];

		if (%{$players{$vender_items{$key}{'ID'}}}) {
			$name = "$players{$vender_items{$key}{'ID'}}{'name'} [".getHex($vender_items{$key}{'ID'})."]";
		} else {
			$name = "Unknown [".getHex($vender_items{$key}{'ID'})."]";
		}

		Kore::Wrapper::AddShopping($no, $key, $vender_items{$key}{'amount'}, $vender_items{$key}{'minPrice'}, $vender_items{$key}{'maxPrice'}, $name);
	}
}

sub UpdateWrapperShopping {
	my $no =  shift;
	my $key;
	my $name;

	if ($config{'wrapperInterface'}) {
		$key = $vender_keys[$i];

		if (%{$players{$vender_items{$key}{'ID'}}}) {
			$name = "$players{$vender_items{$key}{'ID'}}{'name'} [".getHex($vender_items{$key}{'ID'})."]";
		} else {
			$name = "Unknown [".getHex($vender_items{$key}{'ID'})."]";
		}

		Kore::Wrapper::UpdateShopping($no, $key, $vender_items{$key}{'amount'}, $vender_items{$key}{'minPrice'}, $vender_items{$key}{'maxPrice'}, $name);
	}
}

sub ClearWrapperShopping {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::ClearShopping();
	}
}

sub ShowWrapperShopping {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::ShowShopping();
	}
}

sub UpdateWrapperInventory {
	my $i = shift;
	my $no;

	if ($config{'wrapperInterface'}) {
		$no = sprintf("%02d", $i);
		if (IsEquipment($chars[$config{'char'}]{'inventory'}[$i])) {
			if ($chars[$config{'char'}]{'inventory'}[$i]{'equipped'})	{
				my $equip = "$equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$i]{'equipped'}}";
				if ($equip eq "") {
					$equip = "Unknown ($chars[$config{'char'}]{'inventory'}[$i]{'equipped'})";
				}

				Kore::Wrapper::UpdateInventory("EQUIP", $no, GenShowName($chars[$config{'char'}]{'inventory'}[$i]), $chars[$config{'char'}]{'inventory'}[$i]{'amount'}, $equip);
			} elsif (!$chars[$config{'char'}]{'inventory'}[$i]{'identified'}) {
				Kore::Wrapper::UpdateInventory("EQUIP", $no, GenShowName($chars[$config{'char'}]{'inventory'}[$i]), $chars[$config{'char'}]{'inventory'}[$i]{'amount'}, "Not Identified");
			} else {
				my $equip = "$equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$i]{'type_equip'}}";
				if ($equip eq "") {
					$equip = "Unknown ($chars[$config{'char'}]{'inventory'}[$i]{'type_equip'})";
				}

				Kore::Wrapper::UpdateInventory("EQUIP", $no, GenShowName($chars[$config{'char'}]{'inventory'}[$i]), $chars[$config{'char'}]{'inventory'}[$i]{'amount'}, "None");
			}
		} elsif ($chars[$config{'char'}]{'inventory'}[$i]{'type'} <= 2) {
			Kore::Wrapper::UpdateInventory("USEABLE", $no, $chars[$config{'char'}]{'inventory'}[$i]{'name'}, $chars[$config{'char'}]{'inventory'}[$i]{'amount'});
		} elsif ($chars[$config{'char'}]{'inventory'}[$i]{'type'} == 6) {
			Kore::Wrapper::UpdateInventory("CARD", $no, $chars[$config{'char'}]{'inventory'}[$i]{'name'}, $chars[$config{'char'}]{'inventory'}[$i]{'amount'});
		} else {
			Kore::Wrapper::UpdateInventory("NONUSEABLE", $no, $chars[$config{'char'}]{'inventory'}[$i]{'name'}, $chars[$config{'char'}]{'inventory'}[$i]{'amount'});
		}
	}
}

sub RemoveWrapperInventory {
	my $i = shift;
	my $no;

	if ($config{'wrapperInterface'}) {
		$no = sprintf("%02d", $i);
		Kore::Wrapper::RemoveInventory($no);
	}
}

sub ClearWrapperInventory {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::ClearInventory();
	}
}

sub ShowWrapperInventory {
	my $id = shift;

	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::ShowInventory($items_lut{$id}, $itemsDesc_lut{$id});
	}
}

sub SetWrapperCartCap {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'}) {
		Kore::Wrapper::SetCartCap($cart{'items'}, $cart{'items_max'}, $cart{'weight'}, $cart{'weight_max'});
	}
}

sub UpdateWrapperCart {
	my $i = shift;
	my $no;

	if ($config{'wrapperInterface'}) {
		$no = sprintf("%02d", $i);
		if (IsEquipment($cart{'inventory'}[$i])) {
			if (!$cart{'inventory'}[$i]{'identified'}) {
				Kore::Wrapper::UpdateCart("NOID", $no, GenShowName($cart{'inventory'}[$i]), $cart{'inventory'}[$i]{'amount'});
			} else {
				Kore::Wrapper::UpdateCart("EQUIP", $no, GenShowName($cart{'inventory'}[$i]), $cart{'inventory'}[$i]{'amount'});
			}
		} elsif ($cart{'inventory'}[$i]{'type'} <= 2) {
			Kore::Wrapper::UpdateCart("USEABLE", $no, $cart{'inventory'}[$i]{'name'}, $cart{'inventory'}[$i]{'amount'});
		} elsif ($cart{'inventory'}[$i]{'type'} == 6) {
			Kore::Wrapper::UpdateCart("CARD", $no, $cart{'inventory'}[$i]{'name'}, $cart{'inventory'}[$i]{'amount'});
		} else {
			Kore::Wrapper::UpdateCart("NONUSEABLE", $no, $cart{'inventory'}[$i]{'name'}, $cart{'inventory'}[$i]{'amount'});
		}
	}
}

sub RemoveWrapperCart {
	my $i = shift;
	my $no;

	if ($config{'wrapperInterface'}) {
		$no = sprintf("%02d", $i);
		Kore::Wrapper::RemoveCart($no);
	}
}

sub ClearWrapperCart {
	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::ClearCart();
	}
}

sub SetWrapperStorageCap {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'}) {
		Kore::Wrapper::SetStorageCap($storage{'items'}, $storage{'items_max'});
	}
}

sub ShowWrapperStorage {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'} && $config{'wrapperPopup'}) {
		Kore::Wrapper::ShowStorage();
	}
}

sub HideWrapperStorage {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'} && $config{'wrapperPopup'}) {
		Kore::Wrapper::HideStorage();
	}
}

sub UpdateWrapperStorage {
	my $i = shift;
	my $no;

	if ($config{'wrapperInterface'}) {
		$no = sprintf("%02d", $i);
		if (IsEquipment($storage{'inventory'}[$i])) {
			if (!$storage{'inventory'}[$i]{'identified'}) {
				Kore::Wrapper::UpdateStorage("NOID", $no, GenShowName($storage{'inventory'}[$i]), $storage{'inventory'}[$i]{'amount'});
			} else {
				Kore::Wrapper::UpdateStorage("EQUIP", $no, GenShowName($storage{'inventory'}[$i]), $storage{'inventory'}[$i]{'amount'});
			}
		} elsif ($storage{'inventory'}[$i]{'type'} <= 2) {
			Kore::Wrapper::UpdateStorage("USEABLE", $no, $storage{'inventory'}[$i]{'name'}, $storage{'inventory'}[$i]{'amount'});
		} elsif ($storage{'inventory'}[$i]{'type'} == 6) {
			Kore::Wrapper::UpdateStorage("CARD", $no, $storage{'inventory'}[$i]{'name'}, $storage{'inventory'}[$i]{'amount'});
		} else {
			Kore::Wrapper::UpdateStorage("NONUSEABLE", $no, $storage{'inventory'}[$i]{'name'}, $storage{'inventory'}[$i]{'amount'});
		}
	}
}

sub RemoveWrapperStorage {
	my $i = shift;
	my $no;

	if ($config{'wrapperInterface'}) {
		$no = sprintf("%02d", $i);
		Kore::Wrapper::RemoveStorage($no);
	}
}

sub ShowWrapperBuySell {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'} && $config{'wrapperPopup'}) {
		Kore::Wrapper::ShowBuySell($npcs{$talk{'ID'}}{'name'});
	}
}

sub HideWrapperBuySell {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'} && $config{'wrapperPopup'}) {
		Kore::Wrapper::HideBuySell();
	}
}

sub ShowWrapperStore {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'} && $config{'wrapperPopup'}) {
		Kore::Wrapper::ShowStore($npcs{$talk{'ID'}}{'name'}, \%{@storeList});
	}
}

sub HideWrapperStore {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'} && $config{'wrapperPopup'}) {
		Kore::Wrapper::HideStore();
	}
}

sub ShowWrapperNpcCon {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'} && $config{'wrapperPopup'}) {
		my $msg = $talk{'msg'};
		$msg =~ s/\^......//g;
		$msg =~ s/_/--------------/g;

		Kore::Wrapper::ShowNpcCon($npcs{$talk{'ID'}}{'name'}, $msg);
	}
}

sub HideWrapperNpcCon {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'} && $config{'wrapperPopup'}) {
		Kore::Wrapper::HideNpcCon();
	}
}

sub ShowWrapperNpcResp {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'} && $config{'wrapperPopup'}) {
		Kore::Wrapper::ShowNpcResp($npcs{$talk{'ID'}}{'name'}, \@{$talk{'responses'}});
	}
}

sub HideWrapperNpcResp {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'} && $config{'wrapperPopup'}) {
		Kore::Wrapper::HideNpcResp();
	}
}

sub ShowWrapperNpcEnd {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'} && $config{'wrapperPopup'} && $talk{'msg'} ne "") {
		my $msg = $talk{'msg'};
		$msg =~ s/\^......//g;
		$msg =~ s/_/--------------/g;

		Kore::Wrapper::ShowNpcEnd($npcs{$talk{'ID'}}{'name'}, $msg);
	}
}

sub HideWrapperNpcEnd {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'} && $config{'wrapperPopup'}) {
		Kore::Wrapper::HideNpcEnd();
	}
}

sub ShowWrapperWarpPortal {
	my @memos;
	my $i;

	if ($config{'remoteSocket'} && $config{'wrapperInterface'}) {
		for ($i=0; $i < @{$warp{'memo'}};$i++) {
			$memos[$i]{'name'} = "$maps_lut{$warp{'memo'}[$i].'.rsw'}";
			$memos[$i]{'map'} = "$warp{'memo'}[$i]";
		}

		Kore::Wrapper::ShowWarpPortal(\%{@memos});
	}
}

sub ShowWrapperGuildJoinRequest {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'} && $config{'wrapperPopup'}) {
		Kore::Wrapper::ShowYesNo("Do you want to join guild $incomingGuild{'name'}?", "guild join 1", "guild join 0");
	}
}

sub ShowWrapperGuildAllyRequest {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'} && $config{'wrapperPopup'}) {
		Kore::Wrapper::ShowYesNo("Do you want to be ally with $incomingAllyGuild{'name'}?", "guild ally 1", "guild ally 0");
	}
}

sub ShowWrapperJoinParty {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'} && $config{'wrapperPopup'}) {
		Kore::Wrapper::ShowYesNo("Do you want to join $incomingParty{'name'}?", "party join 1", "party join 0");
	}
}

sub HideWrapperYesNo {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'} && $config{'wrapperPopup'}) {
		Kore::Wrapper::HideYesNo();
	}
}

sub ShowWrapperYesNoDeal {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'} && $config{'wrapperPopup'}) {
		Kore::Wrapper::ShowYesNo("$incomingDeal{'name'} requests a deal.", "deal", "deal no");
	}
}

sub ShowWrapperDeal {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'}) {
		Kore::Wrapper::ShowDeal();
	}
}

sub HideWrapperDeal {
	if ($config{'remoteSocket'} && $config{'wrapperInterface'}) {
		Kore::Wrapper::HideDeal();
	}
}

sub ConfirmWrapperDeal {
	my $side = shift;
	if ($config{'remoteSocket'} && $config{'wrapperInterface'}) {
		Kore::Wrapper::ConfirmDeal($side);
	}
}

sub AddWrapperDealItem {
	my $side = shift;
	my $i = shift;
	my $amount = shift;
	my $no;

	if ($config{'remoteSocket'} && $config{'wrapperInterface'}) {
		if (!$side) {
			if (IsEquipment($chars[$config{'char'}]{'inventory'}[$i])) {
				if (!$chars[$config{'char'}]{'inventory'}[$i]{'identified'}) {
					Kore::Wrapper::AddDealItem($side, "NOID", GenShowName($chars[$config{'char'}]{'inventory'}[$i]), $amount);
				} else {
					Kore::Wrapper::AddDealItem($side, "EQUIP", GenShowName($chars[$config{'char'}]{'inventory'}[$i]), $amount);
				}
			} elsif ($chars[$config{'char'}]{'inventory'}[$i]{'type'} <= 2) {
				Kore::Wrapper::AddDealItem($side, "USEABLE", $chars[$config{'char'}]{'inventory'}[$i]{'name'}, $amount);
			} elsif ($chars[$config{'char'}]{'inventory'}[$i]{'type'} == 6) {
				Kore::Wrapper::AddDealItem($side, "CARD", $chars[$config{'char'}]{'inventory'}[$i]{'name'}, $amount);
			} else {
				Kore::Wrapper::AddDealItem($side, "NONUSEABLE", $chars[$config{'char'}]{'inventory'}[$i]{'name'}, $amount);
			}
		} else {
			if (!$currentDeal{'other'}{$i}{'identified'}) {
				Kore::Wrapper::AddDealItem($side, "NOID", $currentDeal{'other'}{$i}{'name'}, $amount);
			} else {
				Kore::Wrapper::AddDealItem($side, "NONUSEABLE", $currentDeal{'other'}{$i}{'name'}, $amount);
			}
		}
	}
}

sub AddWrapperDealZeny {
	my $side = shift;
	my $zeny = shift;

	if ($config{'remoteSocket'} && $config{'wrapperInterface'}) {
		Kore::Wrapper::AddDealZeny($side, $zeny);
	}
}

sub ShowWrapperArrowCraft {
	my @arrowcrafts;
	my $i;

	if ($config{'remoteSocket'} && $config{'wrapperInterface'}) {
		for ($i=0; $i < @arrowCraftID; $i++) {
			$arrowcrafts[$i] = $chars[$config{'char'}]{'inventory'}[$arrowCraftID[$i]]{'name'};
		}

		Kore::Wrapper::ShowChoice('ARROW CRAFT LIST', \%{@arrowcrafts}, 'arrowcraft', '');
	}
}

sub ShowWrapperEgg {
	my @eggs;
	my $i;

	if ($config{'remoteSocket'} && $config{'wrapperInterface'}) {
		for ($i=0; $i < @eggID; $i++) {
			$eggs[$i] = $chars[$config{'char'}]{'inventory'}[$eggID[$i]]{'name'};
		}

		Kore::Wrapper::ShowChoice('EGG LIST', \%{@eggs}, 'egg', '');
	}
}

sub ShowWrapperIdentify {
	my @identify;
	my $i;

	if ($config{'remoteSocket'} && $config{'wrapperInterface'}) {
		for ($i=0; $i < @identifyID; $i++) {
			$identify[$i] = $chars[$config{'char'}]{'inventory'}[$identifyID[$i]]{'name'};
		}

		Kore::Wrapper::ShowChoice('IDENTIFY LIST', \%{@identify}, 'iden"', '');
	}
}

sub ShowWrapperMixture {
	my @mixtures;
	my $i;

	if ($config{'remoteSocket'} && $config{'wrapperInterface'}) {
		for ($i=0; $i < @mixtureID; $i++) {
			$mixtures[$i] = ($items_lut{$mixtureID[$i]} ne "") ? $items_lut{$mixtureID[$i]} : "Unknown ".$mixtureID[$i];
		}

		Kore::Wrapper::ShowChoice('MIXTURE LIST', \%{@mixtures}, 'mix"', '');
	}
}

sub DebugWrapper {
	my $msg = shift;

	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::DebugInsert("$msg\n");
	} else {
		print "$msg\n";
	}
}

sub PrintWrapper {
	my $msg = shift;
	my $tag = shift;

	if ($config{'wrapperInterface'}) {
		Kore::Wrapper::ConsoleInsert("$msg\n", $tag);
	} else {
		print "$msg\n";
	}
}

sub ChatWrapper {
	my $user = shift;
	my $msg = shift;
	my $chattype = shift;

	if ($config{'wrapperInterface'}) {
		if ($chattype eq "c") {
			if ($user eq $chars[$config{'char'}]{'name'}) {
				Kore::Wrapper::ChatInsert("$user : $msg\n", 'chatto');
			} elsif ($user eq "") {
				Kore::Wrapper::ChatInsert("$msg\n", 'chatfrom');
			} else {
				Kore::Wrapper::ChatInsert("$user : $msg\n", 'chatfrom');
			}
		} elsif ($chattype eq "p") {
			if ($user eq $chars[$config{'char'}]{'name'}) {
				Kore::Wrapper::ChatInsert("$user : $msg\n", 'partyto');
			} elsif ($user eq "") {
				Kore::Wrapper::ChatInsert("$msg\n", 'partyfrom');
			} else {
				Kore::Wrapper::ChatInsert("$user : $msg\n", 'partyfrom');
			}
		} elsif ($chattype eq "g") {
			if ($user eq $chars[$config{'char'}]{'name'}) {
				Kore::Wrapper::ChatInsert("$user : $msg\n", 'guildto');
			} elsif ($user eq "") {
				Kore::Wrapper::ChatInsert("$msg\n", 'guildfrom');
			} else {
				Kore::Wrapper::ChatInsert("$user : $msg\n", 'guildfrom');
			}
		} elsif ($chattype eq "s") {
			if ($user eq "") {
				Kore::Wrapper::ChatInsert("$msg\n", 's');
			} else {
				Kore::Wrapper::ChatInsert("$user : $msg\n", 's');
			}
		} elsif ($chattype eq "pm") {
			Kore::Wrapper::PlayerInsert($user);
			Kore::Wrapper::ChatInsert("(From $user) : $msg\n", 'privatefrom');
		} elsif ($chattype eq "pmto") {
			Kore::Wrapper::ChatInsert("(To $user) : $msg\n", 'privateto');
		} elsif ($chattype eq "e") {
			Kore::Wrapper::ChatInsert("$user : $msg\n", 'emotion');
		} elsif ($chattype eq "guild") {
			Kore::Wrapper::ChatInsert("$user\n$msg\n", 'guild');
		} elsif ($chattype eq "debug") {
			Kore::Wrapper::ChatInsert("$msg\n", 'debug');
		} else {
			Kore::Wrapper::ChatInsert("$user : $msg\n", $chattype);
		}
	} else {
		if ($chattype eq "c" || $chattype eq "e") {
			if ($user eq $chars[$config{'char'}]{'name'}) {
				SetColor($FG_GREEN | $BG_BLACK);
			} else {
				SetColor($FG_WHITE | $BG_BLACK);
			}
			print "$user : $msg\n";
		} elsif ($chattype eq "p") {
			if ($user eq $chars[$config{'char'}]{'name'}) {
				SetColor($FG_BROWN | $BG_BLACK);
			} else {
				SetColor($FG_LIGHTMAGENTA | $BG_BLACK);
			}
			print "[PARTY] $user : $msg\n";
		} elsif ($chattype eq "g") {
			SetColor($FG_CYAN | $BG_BLACK);
			print "[GUILD] $user : $msg\n";
		} elsif ($chattype eq "s") {
			SetColor($FG_YELLOW | $BG_BLACK);
			print "$msg\n";
		} elsif ($chattype eq "pm") {
			SetColor($FG_YELLOW | $BG_BLACK);
			print "(From $user) : $msg\n";
		} elsif ($chattype eq "pmto") {
			SetColor($FG_YELLOW | $BG_BLACK);
			print "(To $user) : $msg\n";
		} elsif ($chattype eq "guild") {
			SetColor($FG_GRAY | $BG_BLACK);
			print "$user\n$msg\n";
		} else {
			SetColor($FG_GRAY | $BG_BLACK);
			print "$user : $msg\n";
		}

		SetColor($ATTR_NORMAL);
	}
}

sub PrintFormat {
        my $format = shift;
        $^A = "";
        formline($format,@_);
        print $^A;
}

$proto = getprotobyname('tcp');
$MAX_READ = 30000;

### START SERVERS ###

if (!$config{'wrapperInterface'}) {
	$server_socket = IO::Socket::INET->new(
				Listen		=> 5,
				LocalAddr	=> $config{'local_host'},
				LocalPort	=> $config{'local_port'},
				Proto		=> 'tcp',
				Timeout		=> 2,
				Reuse		=> 1);
	($server_socket) || die "Error creating local server: $!";
	print "Local server started ($config{'local_host'}:$config{'local_port'})\n";
}

if ($config{'remoteSocket'}) {
	$remote_socket = IO::Socket::INET->new();
} else {
	$injectServer_socket = IO::Socket::INET->new(
				Listen		=> 5,
				LocalAddr	=> $config{'local_host'},
				LocalPort	=> 2350,
				Proto		=> 'tcp',
				Timeout		=> 999,
				Reuse		=> 1);
	($injectServer_socket) || die "Error creating local inject server: $!";
	print "Local inject server started ($config{'local_host'}:2350)\n";
}

if (!$config{'wrapperInterface'}) {
	$input_pid = input_client();
}

print "\n";

######################

addParseFiles("$profile/items_control.txt", \%items_control, \&parseItemsControl);
addParseFiles("$profile/mon_control.txt", \%mon_control, \&parseMonControl);
addParseFiles("$profile/overallauth.txt", \%overallAuth, \&parseDataFile);
addParseFiles("$profile/cartitems.txt", \%cartItems, \&parseDataFile_lc);
addParseFiles("$profile/pickupitems.txt", \%itemsPickup, \&parseDataFile_lc);
addParseFiles("$profile/responses.txt", \%responses, \&parseResponses);
addParseFiles("$profile/timeouts.txt", \%timeout, \&parseTimeouts);
addParseFiles("$profile/cmd_resps.txt", \%cmd_resps, \&parseResponses);
addParseFiles("$profile/avoids.txt", \@avoids, \&parseArrayFile);
addParseFiles("$profile/gms.txt", \@gms, \&parseArrayFile);

addParseFiles("tables/charlook.txt", \%charLook_lut, \&parseDataFile2);
addParseFiles("tables/charhead.txt", \%charHead_lut, \&parseCharFile);
addParseFiles("tables/cities.txt", \%cities_lut, \&parseROLUT);
addParseFiles("tables/emotions.txt", \%emotions_lut, \&parseEmotionsFile);
addParseFiles("tables/equiptypes.txt", \%equipTypes_lut, \&parseDataFile2);
addParseFiles("tables/items.txt", \%items_lut, \&parseROLUT);
addParseFiles("tables/itemsdesc.txt", \%itemsDesc_lut, \&parseRODescLUT);
addParseFiles("tables/itemsslotcount.txt", \%itemsSlotCount_lut, \&parseROLUT);
addParseFiles("tables/itemsequip.txt", \%itemsEquip_lut, \&parseROSlotsLUT);
addParseFiles("tables/itemtypes.txt", \%itemTypes_lut, \&parseDataFile2);
addParseFiles("tables/jobs.txt", \%jobs_lut, \&parseDataFile2);
addParseFiles("tables/maps.txt", \%maps_lut, \&parseROLUT);
addParseFiles("tables/monsters.txt", \%monsters_lut, \&parseMonstersFile);
addParseFiles("tables/npcs.txt", \%npcs_lut, \&parseNPCs);
addParseFiles("tables/portals.txt", \%portals_lut, \&parsePortals);
addParseFiles("tables/portalsLOS.txt", \%portals_los, \&parsePortalsLOS);
addParseFiles("tables/sex.txt", \%sex_lut, \&parseDataFile2);
addParseFiles("tables/skillsRO.txt", \%skills_lut, \&parseSkillsLUT);
addParseFiles("tables/skillsRO.txt", \%skills_rlut, \&parseSkillsReverseLUT_lc);
addParseFiles("tables/skills.txt", \%skillsID_lut, \&parseSkillsFile);
addParseFiles("tables/skillsdescriptions.txt", \%skillsDesc_lut, \&parseRODescLUT);
addParseFiles("tables/skillssp.txt", \%skillsSP_lut, \&parseSkillsSPLUT);
addParseFiles("tables/skilluses.txt", \%skillsUse_lut, \&parseDataFile2);
addParseFiles("tables/effects.txt", \%effects_lut, \&parseSkillsFile);
addParseFiles("tables/effects.txt", \%effects_rlut, \&parseSkillsFileReverse);
addParseFiles("tables/rareitems.txt", \%rareItems_lut, \&parseListFile);

addParseFiles("tables/cards.txt", \%cards_lut, \&parseROLUT);
addParseFiles("tables/cardprefixnametable.txt", \%cardsPrefix_lut, \&parseROLUT);
addParseFiles("tables/elements.txt", \%elements_lut, \&parseDataFile2);
addParseFiles("tables/strongs.txt", \%strongs_lut, \&parseDataFile2);

load(\@parseFiles);

my $CalcPath_init;
my $CalcPath_pathStep;
my $CalcPath_destroy;
my $GetProcByName;
my $Execute;
my $IsClientShow;
my $FocusClient;
my $SetDelay;
my $EnterServer;
my $EscapeClient;
my $EnterLogin;
#my $Encode;

if (!$config{'buildType'}) {
	$CalcPath_init = new Win32::API("Tools", "CalcPath_init", "PPNNPPN", "N");
	die "Could not locate Tools.dll" if (!$CalcPath_init);

	$CalcPath_pathStep = new Win32::API("Tools", "CalcPath_pathStep", "N", "N");
	die "Could not locate Tools.dll" if (!$CalcPath_pathStep);

	$CalcPath_destroy = new Win32::API("Tools", "CalcPath_destroy", "N", "V");
	die "Could not locate Tools.dll" if (!$CalcPath_destroy);

	$GetProcByName = new Win32::API("Tools", "GetProcByName", "P", "N");
	die "Could not locate Tools.dll" if (!$GetProcByName);

	if ($config{'bypassLogin'} && $config{'bypassLogin_auto'}) {
		$Execute = new Win32::API("Login", "Execute", "P", "N");
		die "Could not locate Login.dll" if (!$Execute);

		$IsClientShow = new Win32::API("Login", "IsClientShow", "V", "N");
		die "Could not locate Login.dll" if (!$IsClientShow);

		$FocusClient = new Win32::API("Login", "FocusClient", "V", "N");
		die "Could not locate Login.dll" if (!$FocusClient);

		$SetDelay = new Win32::API("Login", "SetDelay", "N", "V");
		die "Could not locate Login.dll" if (!$SetDelay);

		$EnterServer = new Win32::API("Login", "EnterServer", "N", "V");
		die "Could not locate Login.dll" if (!$EnterServer);

		$EscapeClient = new Win32::API("Login", "EscapeClient", "N", "V");
		die "Could not locate Login.dll" if (!$EscapeClient);

		$EnterLogin = new Win32::API("Login", "EnterLogin", "PP", "V");
		die "Could not locate Login.dll" if (!$EnterLogin);
	}

#	if ($config{'login'} == 1) {
#		$Encode = new Win32::API("Encode", "Encode", "NNNPPPP", "V");
#		die "Could not locate Encode.dll" if (!$Encode);
#	}
} elsif ($config{'buildType'} == 1) {
	$ToolsLib = new C::DynaLib("./Tools.so");

	$CalcPath_init = $ToolsLib->DeclareSub("CalcPath_init", "L", "p","p","L","L","p","p","L");
	die "Could not locate Tools.so" if (!$CalcPath_init);

	$CalcPath_pathStep = $ToolsLib->DeclareSub("CalcPath_pathStep", "L", "L");
	die "Could not locate Tools.so" if (!$CalcPath_pathStep);

	$CalcPath_destroy = $ToolsLib->DeclareSub("CalcPath_destroy", "", "L");
	die "Could not locate Tools.so" if (!$CalcPath_destroy);
}

sub BypassLogin {
	my $msg;
	my $listen_socket;
	my $client_socket;
	my $fdsRead;
	my $auto;

	if ($config{'bypassLogin'}) {
		if ($config{'bypassHost'} eq "") {
			$config{'bypassHost'} = "localhost";
		}

		if (!$config{'bypassPort'}) {
			$config{'bypassPort'} = 6900;
		}

		$listen_socket = IO::Socket::INET->new(
				Listen		=> 5,
				LocalAddr	=> $config{'bypassHost'},
				LocalPort		=> $config{'bypassPort'},
				Proto		=> 'tcp',
				Timeout		=> 2,
				Reuse		=> 1);

		if ($listen_socket) {
			print "Bypass Server is created. Waiting for connection...\n";

			if ($config{'bypassLogin_auto'}) {
				print "Auto Login activate...\n";
				$auto = 1;
				$SetDelay->Call(50);

				my $procID = $GetProcByName->Call($config{'processName'});
				if (!$procID) {
					print "- Execute $config{'bypassLogin_auto_command'}\n";
					my $command = $config{'bypassLogin_auto_command'}.pack("C", 0);
					if (!$Execute->Call($command)) {
						print "! Could not execute command. Please use manual login.\n";
						$auto = 0;
					}

					if ($auto) {
						while (!$IsClientShow->Call()) {}
						sleep($config{'bypassLogin_auto_waitClient'});

						print "- Select server $config{'bypassLogin_auto_server'}.\n";
						$EnterServer->Call($config{'bypassLogin_auto_server'});
						sleep(1);
					}
				} else {
					if (!$FocusClient->Call()) {
						print "! Could not focus Ragnarok window. Please use manual login.\n";
						$auto = 0;
					} else {
						sleep(1);
					}
				}

				if ($auto) {
					print "- Enter username and password.\n";
					my $username = $config{'username'}.pack("C", 0);
					my $password = $config{'password'}.pack("C", 0);
					$EnterLogin->Call($username, $password);
				}
			}

			while (1) {
				last if (UpdateWrapper());
				last if (!($remote_socket && $remote_socket->connected()));

				if (dataWaiting(\$remote_socket)) {
					$remote_socket->recv($msg, $MAX_READ);
					if ($msg ne "") {
						sendBypass(\$client_socket, $msg);
						dumpReceivePacket($msg);
					}
				}

				vec($fdsRead, fileno($listen_socket), 1) = 1;
				select($fdsRead, undef, undef, 0.05);
				# Only read flag is required on listening.
				if (vec($fdsRead, fileno($listen_socket), 1)) {
					close($client_socket);
					$client_socket = $listen_socket->accept();
					if ($client_socket) {
						print "Client connect to $config{'bypassHost'}:$config{'bypassPort'}\n";
					} else {
						print "Socket accept failed!\n";
					}
				}

				if ($client_socket && $client_socket->connected()) {
					if (dataWaiting(\$client_socket)) {
						$client_socket->recv($msg, $MAX_READ);
						if ($msg ne "") {
							$switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));

							sendBypass(\$remote_socket, $msg);
							dumpSendPacket($msg);

							if ($switch eq "0064" || $switch eq "01DD") {
								$msg = pack("C*", 0x81, 0x00, 0x08);
								sendBypass(\$client_socket, $msg);
								print "Login completed.\n";

								if ($config{'bypassLogin_auto'} && $auto) {
									sleep(1);
									$EscapeClient->Call(1);
								}
								last;
							}
						}
					}
				}
			}

			close($client_socket);
			close($listen_socket);

			print "Bypass Server is closed.\n";
			return 1;
		} else {
			print "Bypass Server is failed!\n";
			return 0;
		}
	}

	return 0;
}

print "\n";

### COMPILE PORTALS ###

print "\nChecking for new portals...";
compilePortals_check(\$found);

if ($found) {
	print "found new portals!\n";
	print "Compile portals now? (y/n)\n";
	print "Auto-compile in $timeout{'compilePortals_auto'}{'timeout'} seconds...";
	$timeout{'compilePortals_auto'}{'time'} = time;

	if ($config{'wrapperInterface'}) {
		$msg = Kore::Wrapper::WaitInput();
	} else {
		undef $msg;
		while (!timeOut(\%{$timeout{'compilePortals_auto'}})) {
			if (dataWaiting(\$input_socket)) {
				$input_socket->recv($msg, $MAX_READ);
			}
			last if $msg;
		}
	}

	if ($msg =~ /y/ || $msg eq "") {
		print "compiling portals\n\n";
		compilePortals();
	} else {
		print "skipping compile\n\n";
	}
} else {
	print "none found\n\n";
}

############################

#getField("fields/in_sphinx1.fld", \%field);
#$a{'x'} = 172;
#$a{'y'} = 149;
#$b{'x'} = 166;
#$b{'y'} = 147;
#IsAttackAble(\%{a}, \%{b});

if ($config{'remoteSocket'}) {
	if ($config{'wrapperInterface'}) {
		if ($config{'master'} eq "" || !$config{'username'} || !$config{'password'}) {
			$i = 0;
			while ($config{"master_name_$i"} ne "") {
				Kore::Wrapper::AddMasterServer($config{"master_name_$i"});
				$i++;
			}

			Kore::Wrapper::Login($config{"master_name_$config{'master'}"}, $config{'username'}, $config{'password'});
			$user = Kore::Wrapper::WaitInput();
			$pwd = Kore::Wrapper::WaitInput();
			$master = Kore::Wrapper::WaitInput();

			$i = 0;
			while ($config{"master_name_$i"} ne $master) {
				$i++;
			}

			$config{'username'} = $user;
			$config{'password'} = $pwd;
			$config{'master'} = $i;
			writeDataFileIntact("$profile/config.txt", \%config);
		}
	} else {
		if (!$config{'username'}) {
			print "Enter Username:\n";
			$input_socket->recv($msg, $MAX_READ);
			$config{'username'} = $msg;
			writeDataFileIntact("$profile/config.txt", \%config);
		}

		if (!$config{'password'}) {
			print "Enter Password:\n";
			$input_socket->recv($msg, $MAX_READ);
			$config{'password'} = $msg;
			writeDataFileIntact("$profile/config.txt", \%config);
		}

		if ($config{'master'} eq "") {
			$i = 0;
			print "--------------- Master Servers ----------------\n";
			print "#         Name\n";
			while ($config{"master_name_$i"} ne "") {
			PrintFormat(<<'MASTERS', $i, $config{"master_name_$i"});
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
MASTERS
				$i++;
			}
			print "-----------------------------------------------\n";
			print "Choose your master server:\n";
			$input_socket->recv($msg, $MAX_READ);
			$config{'master'} = $msg;
			writeDataFileIntact("$profile/config.txt", \%config);
		}
	}
}

### MAIN FUNCTION ###

undef $msg;
$KoreStartTime = time;
$conState = 1;
$AI = 0;

if ($config{'remoteSocket'}) {
	while ($quit != 1) {
		UpdateWrapper();

		usleep($config{'sleepTime'});

		if ($config{'wrapperInterface'}) {
			if (Kore::Wrapper::IsInput()) {
				$input = Kore::Wrapper::GetInput();
				parseInput($input);
			}
		} elsif (dataWaiting(\$input_socket)) {
			$stop = 1;
			$input_socket->recv($input, $MAX_READ);
			parseInput($input);
		}

		if (dataWaiting(\$remote_socket)) {
			$remote_socket->recv($new, $MAX_READ);
			$msg .= $new;
			$msg_length = length($msg);
			while ($msg ne "") {
				$msg = parseMsg($msg);
				last if ($msg_length == length($msg));
				$msg_length = length($msg);
			}
		}

		AI() if ($conState == 5 && timeOut(\%{$timeout{'ai'}}) && $remote_socket && $remote_socket->connected());

		checkConnection();
	}
} else {
	$cwd = Win32::GetCwd();
	$injectDLL_file = $cwd."\\Inject.dll";
	$timeout{'injectSync'}{'time'} = time;

	while ($quit != 1) {
		UpdateWrapper();

		usleep($config{'sleepTime'});
		if (timeOut(\%{$timeout{'injectKeepAlive'}})) {
			$conState = 1;
			$printed = 0;
			do {
				$procID = $GetProcByName->Call($config{'processName'});
				if (!$procID) {
					print "Error: Could not locate process $config{'processName'}.\nWaiting for you to start the process...\n" if (!$printed);
					$printed = 1;
				}

				if ($config{'wrapperInterface'}) {
					if (Kore::Wrapper::IsInput()) {
						$input = Kore::Wrapper::GetInput();
						parseInput($input);
					}

					last if (UpdateWrapper());
				}
			} while (!$procID);

			if ($procID) {
				if ($printed == 1) {
					print "Process found.\n";
				}

				my $InjectDLL = new Win32::API("Tools", "InjectDLL", "NP", "I");
				$retVal = $InjectDLL->Call($procID, $injectDLL_file);
				die "Could not inject DLL" if ($retVal != 1);

				print "Waiting for InjectDLL to connect...\n";
				$remote_socket = $injectServer_socket->accept();
				(inet_aton($remote_socket->peerhost()) == inet_aton($config{'local_host'})) || die "Inject Socket must be connected from localhost";
				print "InjectDLL Socket connected - Ready to start botting\n";
				$timeout{'injectKeepAlive'}{'time'} = time;
			} else {
				next;
			}
		}

		if (timeOut(\%{$timeout{'injectSync'}})) {
			sendSyncInject(\$remote_socket);
			$timeout{'injectSync'}{'time'} = time;
		}

		if ($config{'wrapperInterface'}) {
			if (Kore::Wrapper::IsInput()) {
				$input = Kore::Wrapper::GetInput();
				parseInput($input);
			}
		} elsif (dataWaiting(\$input_socket)) {
			$input_socket->recv($input, $MAX_READ);
			parseInput($input);
		}

		if (dataWaiting(\$remote_socket)) {
			$remote_socket->recv($injectMsg, $MAX_READ);
			while ($injectMsg ne "") {
				if (length($injectMsg) < 3) {
					undef $injectMsg;
					break;
				}
				$type = substr($injectMsg, 0, 1);
				$len = unpack("S",substr($injectMsg, 1, 2));
				$newMsg = substr($injectMsg, 3, $len);
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
		}

		AI() if ($AI && $conState == 5 && timeOut(\%{$timeout{'ai'}}) && $remote_socket && $remote_socket->connected());
	}
}

close($server_socket);
close($input_socket);

if (!$config{'wrapperInterface'}) {
	kill 9, $input_pid;
}

if ($config{'remoteSocket'}) {
	killConnection(\$remote_socket);
} else {
	close($remote_socket);
}

if ($update{'packet'}) {
	WritePacketsFile("tables/_spackets.txt", \%spackets);
}

if ($update{'skill'}) {
	WriteSkillsLUT("tables/skills.txt", \%skillsID_lut);
}

if ($update{'monster'}) {
	WriteMonstersLUT("tables/monsters.txt", \%monsters_lut);
}

if ($update{'npc'}) {
	WriteNPCLUT("tables/npcs.txt", \%npcs_lut);
}

if ($config{'waitOnExit'}) {
	$timeout_ex{'exit'}{'time'} = time;

	PrintMessage("\nWaiting $config{'waitOnExit'} seconds...", "white");
	$last_count = 0;
	do {
		UpdateWrapper();
		$count = $config{'waitOnExit'} - int(time - $timeout_ex{'exit'}{'time'});
		if ($count > 0 && $last_count != $count) {
			print "$count\n";
			$last_count = $count;
		}
	} while ($count > 0);
}

exit;



#######################################
#INITIALIZE VARIABLES
#######################################

sub initConnectVars {
	ClearWrapperInventory();
	ClearWrapperSkill();
	ClearWrapperCart();
	SetWrapperPartyTitle();

	initMapChangeVars(1);

	ClearWrapperParty();
	undef %{$chars[$config{'char'}]{'party'}};
	undef @partyUsersID;

	undef @{$chars[$config{'char'}]{'inventory'}};
	undef %{$chars[$config{'char'}]{'skills'}};
	undef %{$chars[$config{'char'}]{'effect'}};
	undef @skillsID;

	undef %avoidGM;
}

sub initMapChangeVars {
	my $connect = shift;

	ClearWrapperPlayer();
	ClearWrapperMonster();
	ClearWrapperNpc();
	ClearWrapperItem();
	ClearWrapperVender();

	if (!$connect) {
		@portalsID_old = @portalsID;
		%portals_old = %portals;
		%{$chars_old[$config{'char'}]{'pos_to'}} = %{$chars[$config{'char'}]{'pos_to'}};
		$ai_v{'portalTrace_mapChanged'} = 1;
	}

	undef $chars[$config{'char'}]{'sitting'};
	undef $chars[$config{'char'}]{'dead'};
	undef $chars[$config{'char'}]{'shop'};
	undef $chars[$config{'char'}]{'equip_slot'};
	undef $chars[$config{'char'}]{'wait_equip_slot'};

	#undef %{$chars[$config{'char'}]{'guild'}};
	$timeout{'play'}{'time'} = time;
	$timeout{'ai_sync'}{'time'} = time;
	$timeout{'ai_sit_idle'}{'time'} = time;
	$timeout{'ai_teleport_idle'}{'time'} = time;
	$timeout{'ai_teleport_search'}{'time'} = time;
	$timeout{'ai_teleport_safe_force'}{'time'} = time;
	$timeout{'ai_healParty'}{'time'} = time;
	$timeout{'ai_chatRoom_create'}{'time'} = time;
	$timeout{'ai_randomTalk'}{'time'} = time;
	undef %incomingDeal;
	undef %outgoingDeal;
	undef %currentDeal;
	undef $currentChatRoom;
	undef @currentChatRoomUsers;
	undef @playersID;
	undef @monstersID;
	undef @portalsID;
	undef @itemsID;
	undef @itemsDropID;
	undef @npcsID;
	undef @spellsID;
	undef @petsID;
	undef @arrowCraftID;
	undef @eggID;
	undef @identifyID;
	undef @mixtureID;
	undef %players;
	undef %monsters;
	undef %portals;
	undef %items;
	undef %npcs;
	undef %spells;
	undef %incomingGuild;
	undef %incomingAllyGuild;
	undef %incomingParty;
	undef $msg;
	undef %talk;
	undef $ai_v{'temp'};
	undef %storage;
	undef %shop;

	undef @cartID;
	undef @{$cart{'inventory'}};

	undef %vender;
	undef @venderListsID;
	undef $venderLists;

	undef %monster;
	undef %warp;

	undef %lastpm;
	undef @lastpm;
}



#######################################
#######################################
#Check Connection
#######################################
#######################################

sub checkConnection {
	if (!timeOut(\%{$timeout_ex{'master'}})) {
		$count = $timeout_ex{'master'}{'timeout'} - int(time - $timeout_ex{'master'}{'time'});
		if ($count > 0 && $last_count_master != $count) {
			print "$count\n";
			$last_count_master = $count;
		}
	}

	if ($conState == 1 && !($remote_socket && $remote_socket->connected()) && timeOut(\%{$timeout_ex{'master'}}) && !$conState_tries) {
		PrintMessage("Connecting to Master Server...", "yellow");
		$conState_tries++;
		undef $msg;
		connection(\$remote_socket, $config{"master_host_$config{'master'}"},$config{"master_port_$config{'master'}"});
		if ($remote_socket && $remote_socket->connected()) {
			if (!BypassLogin()) {
				if ($config{'login'} == 1) {
					PrintMessage("- Secure Login", "gray");
					undef $msg1DC;
					sendMasterCodeRequest(\$remote_socket);
				} else {
					sendMasterLogin(\$remote_socket, $config{'username'}, $config{'password'});
				}
			}
		}
		$timeout{'master'}{'time'} = time;
	} elsif ($conState == 1 && $config{'login'} > 0 && $msg1DC ne "" && !timeOut(\%{$timeout{'master'}}) && $conState_tries) {
		PrintMessage("- Encode password", "gray");
		$msg1DD = "\0" x (47);
		#$Encode->Call($config{'version'}, $config{'servertype'}, $config{'servicetype'}, $config{'username'}.pack("C", 0), $config{'password'}.pack("C", 0), $msg1DC, $msg1DD);

		$msg1DC = substr($msg1DC, 4, length($msg1DC) - 4);
		if ($config{'login'} == 1) {
			$msg1DC = $msg1DC.$config{'password'};
		} elsif ($config{'login'} == 2) {
			$msg1DC = $config{'password'}.$msg1DC;
		}

		$msg1DD = pack("C*", 0xDD, 0x01).pack("L1", $config{'version'}).$config{'username'}. chr(0) x (24 - length($config{'username'})) . md5($msg1DC) . pack("C*", $config{"master_version_$config{'master'}"});
		sendMasterSecureLogin(\$remote_socket, $msg1DD);
		undef $msg1DC;
	} elsif ($conState == 1 && timeOut(\%{$timeout{'master'}}) && timeOut(\%{$timeout_ex{'master'}})) {
		PrintMessage("Timeout on Master Server, reconnecting...", "lightblue");
		killConnection(\$remote_socket);
		undef $conState_tries;
	} elsif ($conState == 2 && !($remote_socket && $remote_socket->connected()) && ($config{'server'} ne "" || $config{'charServer_host'}) && !$conState_tries) {
		PrintMessage("Connecting to Game Login Server...", "yellow");
		$conState_tries++;
		if ($config{'charServer_host'} ne "") {
			connection(\$remote_socket, $config{'charServer_host'},$config{'charServer_port'});
		} else {
			connection(\$remote_socket, $servers[$config{'server'}]{'ip'},$servers[$config{'server'}]{'port'});
		}
		sendGameLogin(\$remote_socket, $accountID, $sessionID, $sessionID2, $accountSex);
		$timeout{'gamelogin'}{'time'} = time;
	} elsif ($conState == 2 && timeOut(\%{$timeout{'gamelogin'}}) && ($config{'server'} ne "" || $config{'charServer_host'})) {
		PrintMessage("Timeout on Game Login Server, reconnecting...", "lightblue");
		killConnection(\$remote_socket);
		undef $conState_tries;
		$conState = 1;
	} elsif ($conState == 3 && timeOut(\%{$timeout{'gamelogin'}}) && $config{'char'} ne "") {
		PrintMessage("Timeout on Char Login Server, reconnecting...", "lightblue");
		killConnection(\$remote_socket);
		$conState = 1;
		undef $conState_tries;
	} elsif ($conState == 4 && !($remote_socket && $remote_socket->connected()) && !$conState_tries) {
		PrintMessage("Connecting to Map Server...", "yellow");
		$conState_tries++;
		initConnectVars();
		connection(\$remote_socket, $map_ip, $map_port);
		sendMapLogin(\$remote_socket, $accountID, $charID, $sessionID, $accountSex2);
		$timeout{'maplogin'}{'time'} = time;
	} elsif ($conState == 4 && timeOut(\%{$timeout{'maplogin'}})) {
		PrintMessage("Timeout on Map Server, connecting to Master Server...", "lightblue");
		killConnection(\$remote_socket);
		$conState = 1;
		undef $conState_tries;
	} elsif ($conState == 5 && !($remote_socket && $remote_socket->connected())) {
		$conState = 1;
		undef $conState_tries;
	} elsif ($conState == 5 && timeOut(\%{$timeout{'play'}})) {
		PrintMessage("Timeout on Map Server, connecting to Master Server...", "lightblue");
		killConnection(\$remote_socket);
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
		PrintMessage("Auto-restarting!!", "white");
		killConnection(\$remote_socket);
	}
}

#######################################
#PARSE INPUT
#######################################


sub parseInput {
	my $input = shift;
	my $printType = shift;
	my $msg;
	my $i;
	my ($arg1, $arg2, $switch);
	my @params;
	my $cmd;
	my $inputparam;

	@params = parseCmdLine($input);
	$cmd = lc($params[0]);
	$inputparam = Trim(substr($input, length($cmd)));

	print "Echo: $input\n" if ($config{'debug'} >= 2);

#Check if in special state

	if ($conState == 2 && $waitingForInput) {
		$config{'server'} = $input;
		$waitingForInput = 0;
		writeDataFileIntact("$profile/config.txt", \%config);
	} elsif ($conState == 3 && $waitingForInput) {
		$config{'char'} = $input;
		SetWrapperTitle();
		$waitingForInput = 0;
		writeDataFileIntact("$profile/config.txt", \%config);
		sendCharLogin(\$remote_socket, $config{'char'});
		$timeout{'gamelogin'}{'time'} = time;
#Parse command...ugh
	} elsif (OnChat($accountID, "me", $input, "s")) {
	} elsif ($cmd eq "00C3") {
		$msg00C3 = pack("C*", 0xC3, 0x00).$accountID.pack("C*", $params[1], $params[2]);
		sendToClientByInject(\$remote_socket, $msg00C3);
	} elsif ($cmd eq "0196") {
		$msg0196 = pack("C*", 0x96, 0x01).pack("S", $params[1]).$accountID.pack("C", $params[2]);
		sendToClientByInject(\$remote_socket, $msg0196);
	} elsif ($cmd eq "help") {
		$params[1] = lc($params[1]);

		my $help;
		my $next_cmd;
		my $is_cmd;
		my $cmd;

		if ($params[1] eq "all") {
			$next_cmd = 0;

			print	"- ALL COMMAND --------------------------\n";
			open FILE, 'command.txt';
			foreach (<FILE>) {
				s/[\r\n]//g;
				s/\s+$//g;
				next if ($_ eq "");

				if (/^\s*\-+$/) {
					if ($help ne "") {
						print $help;
					}
					$help = '';
					$next_cmd = 0;
				} elsif ($next_cmd == 0) {
					$help .= "$_\n";
					$next_cmd = 1;
				}
			}
			close FILE;

			print $help;

			print	"----------------------------------------\n";
		} elsif ($params[1] ne "") {
			$is_cmd = 0;
			$next_cmd = 0;

			print	"- HELP ---------------------------------\n";
			open FILE, 'command.txt';
			foreach (<FILE>) {
				s/[\r\n]//g;
				s/\s+$//g;
				next if ($_ eq "");

				if (/^\s*\-+$/) {
					last if ($is_cmd);
					$next_cmd = 0;
				} elsif ($is_cmd) {
					if (/^\s*\[\+\]/) {
						$help .= "\n";
					}
					$help .= "$_\n";
				} elsif ($next_cmd == 0) {
					($cmd) = $_ =~ /^\s*(\w+)/;

					if (lc($cmd) eq $params[1]) {
						$help .= "$_\n";
						$is_cmd = 1;
					} else {
						$next_cmd = 1;
					}
				}
			}
			close FILE;

			print $help;
			print	"----------------------------------------\n";
		} else {
			print "HELP - Command help.\n",
				"Syntax:\n",
				"    help all\n",
				"    help <command>\n\n";
		}
	} elsif ($cmd eq "a") {
		if (IsNumber($params[1])) {
			if ($monstersID[$params[1]] ne "") {
				attack($monstersID[$params[1]]);
			} else {
				print	"A - Monster $params[1] does not exist.\n";
			}
		} else {
			print "A - Attack Monster.\n",
				"Syntax:\n",
				"    a <monster number>\n\n",
				"Options:\n",
				"    <monster number> - Type 'm' to get the monsters list.\n\n";
		}
	} elsif ($cmd eq "ai") {
		if ($AI) {
			aiRemove("clientSuspend");
			aiRemove("move");
			aiRemove("route");
			aiRemove("route_getRoute");
			aiRemove("route_getMapRoute");

			undef $AI;
			configModify("aiStart", 0);
			print "AI turned off\n";
		} else {
			$AI = 1;
			configModify("aiStart", 1);
			print "AI turned on\n";
		}
	} elsif ($cmd eq "arrowcraft") {
		$params[1] = lc($params[1]);

		if ($params[1] eq "") {
			if (@arrowCraftID) {
				print	"- ARROW CRAFT LIST ---------------------\n";
				for ($i = 0; $i < @arrowCraftID; $i++) {
					next if ($arrowCraftID[$i] eq "");
					PrintFormat(<<'ARROWCRAFT', $i, $chars[$config{'char'}]{'inventory'}[$arrowCraftID[$i]]{'name'});
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
ARROWCRAFT
				}
				print	"----------------------------------------\n";
			} else {
				print "ARROWCRAFT - Type 'arrowcraft use' to get list.\n";
			}
		} elsif ($params[1] eq "use") {
			if ($chars[$config{'char'}]{'skills'}{'AC_MAKINGARROW'}{'lv'} >= 1) {
				sendSkillUse(\$remote_socket, $chars[$config{'char'}]{'skills'}{'AC_MAKINGARROW'}{'ID'}, 1, $accountID);
			} else {
				print	"ARROWCRAFT USE - You don't have an Arrow Craft skill.\n";
			}
		} elsif (IsNumber($params[1])) {
			if ($arrowCraftID[$params[1]] ne "") {
				sendIdentify(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arrowCraftID[$params[1]]]{'index'});
			} else {
				print "ARROWCRAFT - Make arrow from Arrow craft.\n",
					"Syntax:\n",
					"    arrowcraft <item number>\n\n",
					"Options:\n",
					"    <item number> - Arrow Craft item number. Type 'arrowcraft' to get number.\n\n";
			}
		}
	} elsif ($cmd eq "auth") {
		my $player;
		my $flag;

		($player, $flag) = $inputparam =~ /^([\s\S]*) ([\s\S]*?)$/;
		if ($player ne "" && ($flag eq "0" || $flag eq "1")) {
			auth($player, $flag);
			if ($flag) {
				print "You are now an admin $player\n";
			} else {
				print "You are not an admin $player\n";
			}
		} else {
			print "AUTH - Authentic player.\n",
				"Syntax:\n",
				"    auth <player name> <flag>\n\n",
				"Options:\n",
				"    <player name> - Any player name.\n";
				"    <flag>        - 0 not admin, 1 admin\n\n";
		}
	} elsif ($cmd eq "avoidgm") {
		if (IsNumber($params[1])) {
			configModify("avoidgm", $params[1]);
		} else {
			print "AVOIDGM - Set avoid GM.\n",
				"Syntax:\n",
				"    avoidgm <type>\n\n",
				"Options:\n",
				"    <type> - Read the manual for avoidgm type.\n\n";
		}
	} elsif ($cmd eq "c") {
		if ($inputparam ne "") {
			aiRemove("respAuto");
			sendMessage(\$remote_socket, "c", $inputparam);
		} else {
			print "C - Chat message.\n",
				"Syntax:\n",
				"    c <message>\n\n",
				"Options:\n",
				"    <message> - The message send to any players.\n\n";
		}
	} elsif ($cmd eq "cg") {
		if ($inputparam ne "") {
			aiRemove("respAuto");
			sendMessage(\$remote_socket, "g", $inputparam);
		} else {
			print "CG - Guild message.\n",
				"Syntax:\n",
				"    cg <message>\n\n",
				"Options:\n",
				"    <message> - The message send to guild players.\n\n";
		}
	} elsif ($cmd eq "cp") {
		if ($inputparam ne "") {
			aiRemove("respAuto");
			sendMessage(\$remote_socket, "p", $inputparam);
		} else {
			print "CP - Party message.\n",
				"Syntax:\n",
				"    cp <message>\n\n",
				"Options:\n",
				"    <message> - The message send to party players.\n\n";
		}
	} elsif ($cmd eq "cpm") {
		if ($params[1] ne "" && $params[2] ne "") {
			aiRemove("respAuto");
			sendMessage(\$remote_socket, "pm", $params[2], $params[1]);
		} else {
			print "CPM - Private message.\n",
				"Syntax:\n",
				"    cpm \"<player name>\" \"<message>\"\n\n",
				"Options:\n",
				"    <player name> - Any player name.\n",
				"    <message>     - The message send to player.\n\n";
		}
	} elsif ($cmd eq "card") {
		$params[1] = lc($params[1]);

		if ($params[1] eq "") {
			print	"- CARD LIST ----------------------------\n";
			for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}}; $i++) {
				next if (!%{$chars[$config{'char'}]{'inventory'}[$i]});

				if ($chars[$config{'char'}]{'inventory'}[$i]{'type'} == 6) {
					print "$i $chars[$config{'char'}]{'inventory'}[$i]{'name'} x $chars[$config{'char'}]{'inventory'}[$i]{'amount'}\n";
				}
			}
			print	"----------------------------------------\n";
		} elsif ($params[1] eq "mergecancel") {
			if ($cardMergeIndex ne "") {
				undef $cardMergeIndex;
				sendCardMerge(\$remote_socket, -1, -1);
			} else {
				print "CARD MERGECANCEL - There are no card used.\n";
			}
		} elsif ($params[1] eq "mergelist") {
			if (@cardMergeItemsID) {
				print	"- CARD ITEMS LIST ----------------------\n";
				for ($i = 0; $i < @cardMergeItemsID; $i++) {
					next if ($cardMergeItemsID[$i] eq "");
					PrintFormat(<<'CARDMERGE', $i, $chars[$config{'char'}]{'inventory'}[$identifyID[$i]]{'name'});
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
CARDMERGE
				}
				print	"----------------------------------------\n";
			} else {
				print "CARD MERGELIST - There are no card item(s).\n";
			}
		} elsif ($params[1] eq "merge") {
			if (IsNumber($params[2])) {
				if ($cardMergeItemsID[$params[2]] ne "") {
					sendCardMerge(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$cardMergeIndex]{'index'}, $chars[$config{'char'}]{'inventory'}[$cardMergeItemsID[$params[2]]]{'index'});
				} else {
					print	"CARD MERGE - Item $params[2] does not exist.\n";
				}
			} else {
				print "CARD MERGE - Merge card with item.\n",
					"Syntax:\n",
					"    card merge <item number>\n\n",
					"Options:\n",
					"    <item number> - Merge item number. Type 'card mergelist' to get number.\n\n";
			}
		} elsif ($params[1] eq "use") {
			if (IsNumber($params[2])) {
				if (%{$chars[$config{'char'}]{'inventory'}[$params[2]]}) {
					$cardMergeIndex = $params[2];
					sendCardMergeRequest(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$cardMergeIndex]{'index'});
				} else {
					print	"CARD USE - Item $params[2] does not exist.\n";
				}
			} else {
				print "CARD USE - Use card.\n",
					"Syntax:\n",
					"    card use <item number>\n\n",
					"Options:\n",
					"    <item number> - Inventory item number. Type 'card' or 'i' to get number.\n\n";
			}
		} elsif ($params[1] eq "forceuse") {
			if (IsNumber($params[2])) {
				if (%{$chars[$config{'char'}]{'inventory'}[$params[2]]}) {
					$cardMergeIndex = $params[2];
					sendCardMergeRequest(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$cardMergeIndex]{'index'});
				}
			}
		}
	} elsif ($cmd eq "cart") {
		$params[1] = lc($params[1]);

		if ($params[1] eq "") {
			if ($cart{'items_max'} <= 0) {
				print "CART - You don't have a cart.\n";
			} elsif ($cart{'items'} > 0) {
				print	"- CART ---------------------------------\n";
				print "#  Name\n";

				for ($i=0; $i < @{$cart{'inventory'}}; $i++) {
					next if (!%{$cart{'inventory'}[$i]});
					PrintFormat(<<'CARTLIST', $i, GenShowName($cart{'inventory'}[$i])." x $cart{'inventory'}[$i]{'amount'}");
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
CARTLIST
				}

				print "\nCapacity: $cart{'items'} / $cart{'items_max'}  Weight: $cart{'weight'} / $cart{'weight_max'}\n";
				print	"----------------------------------------\n";
			} else {
				print "CART - There are no item(s) in cart.\n";
			}
		} elsif ($params[1] eq "add") {
			if ($cart{'items_max'} <= 0) {
				print "CART ADD - You don't have a cart.\n";
			} elsif (IsNumber($params[2])) {
				if (%{$chars[$config{'char'}]{'inventory'}[$params[2]]}) {
					if ($params[3] <= 0 || $params[3] > $chars[$config{'char'}]{'inventory'}[$params[2]]{'amount'}) {
						$params[3] = $chars[$config{'char'}]{'inventory'}[$params[2]]{'amount'};
					}

					sendCartAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$params[2]]{'index'}, $params[3]);
				} else {
					print	"CART ADD - Item $params[2] does not exist.\n";
				}
			} else {
				print "CART ADD - Add item to cart.\n",
					"Syntax:\n",
					"    cart add <item number> [<amount>]\n\n",
					"Options:\n",
					"    <item number> - Inventory item number. Type 'i' to get number.\n",
					"    <amount>      - Inventory item amount.\n\n";
			}
		} elsif ($params[1] eq "desc") {
			if ($cart{'items_max'} <= 0) {
				print "CART DESC - You don't have a cart.\n";
			} elsif (IsNumber($params[2])) {
				if (%{$cart{'inventory'}[$params[2]]}) {
					ShowWrapperInventory($cart{'inventory'}[$params[2]]{'nameID'});
					if (!$config{'wrapperInterface'}) {
						printItemDesc($cart{'inventory'}[$params[2]]{'nameID'});
					}
				} else {
					print	"CART DESC - Cart Item $params[2] does not exist.\n";
				}
			} else {
				print "CART DESC - Cart item description.\n",
					"Syntax:\n",
					"    cart desc <item number>\n\n",
					"Options:\n",
					"    <item number> - Cart item number. Type 'cart' to get number.\n\n";
			}
		} elsif ($params[1] eq "get") {
			if ($cart{'items_max'} <= 0) {
				print "CART GET - You don't have a cart.\n";
			} elsif (IsNumber($params[2])) {
				if (%{$cart{'inventory'}[$params[2]]}) {
					if ($params[3] <= 0 || $params[3] > $cart{'inventory'}[$params[2]]{'amount'}) {
						$params[3] = $cart{'inventory'}[$params[2]]{'amount'};
					}

					sendCartGet(\$remote_socket, $params[2], $params[3]);
				} else {
					print	"CART GET - Item $params[2] does not exist.\n";
				}
			} else {
				print "CART GET - Get item from cart.\n",
					"Syntax:\n",
					"    cart get <item number> [<amount>]\n\n",
					"Options:\n",
					"    <item number> - Cart item number. Type 'cart' to get number.\n",
					"    <amount>      - Cart item amount.\n\n";
			}
		} elsif ($params[1] eq "storage") {
			if ($cart{'items_max'} <= 0) {
				print "CART STORAGE - You don't have a cart.\n";
			} elsif (IsNumber($params[2])) {
				if (%{$cart{'inventory'}[$params[2]]}) {
					if ($params[3] <= 0 || $params[3] > $cart{'inventory'}[$params[2]]{'amount'}) {
						$params[3] = $cart{'inventory'}[$params[2]]{'amount'};
					}

					sendCartStorageAdd(\$remote_socket, $params[2], $params[3]);
				} else {
					print	"CART STORAGE - Item $params[2] does not exist.\n";
				}
			} else {
				print "CART STORAGE - Storage item from cart.\n",
					"Syntax:\n",
					"    cart storage <item number> [<amount>]\n\n",
					"Options:\n",
					"    <item number> - Cart item number. Type 'cart' to get number.\n",
					"    <amount>      - Cart item amount.\n\n";
			}
		}
	} elsif ($cmd eq "chat") {
		$params[1] = lc($params[1]);

		if ($params[1] eq "") {
			if (@chatRoomsID) {
				my $public;
				my $limit;
				my $owner;

				print "- CHAT ROOM LIST -----------------------\n",
					"#   Title                     Owner                     Users   Public/Private\n";

				for ($i = 0; $i < @chatRoomsID; $i++) {
					next if ($chatRoomsID[$i] eq "");
					$public = ($chatRooms{$chatRoomsID[$i]}{'public'}) ? "Public" : "Private";
					$limit = $chatRooms{$chatRoomsID[$i]}{'num_users'}."/".$chatRooms{$chatRoomsID[$i]}{'limit'};
					$owner = ($chatRooms{$chatRoomsID[$i]}{'ownerID'} ne $accountID) ? $players{$chatRooms{$chatRoomsID[$i]}{'ownerID'}}{'name'} : $chars[$config{'char'}]{'name'};
					PrintFormat(<<'CRLIST', $i, $chatRooms{$chatRoomsID[$i]}{'title'}, $owner, $limit, $public);
@<< @<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<< @<<<<<<<<<
CRLIST
				}

				print "----------------------------------------\n";
			} else {
				print "CHAT - There are no chat room.\n";
			}
		} elsif ($params[1] eq "bestow") {
			if ($currentChatRoom eq "") {
				print "CHAT BESTOW - You are not in a chat room.\n";
			} elsif (IsNumber($params[2])) {
				if ($currentChatRoomUsers[$params[2]] ne "") {
					sendChatRoomBestow(\$remote_socket, $currentChatRoomUsers[$params[2]]);
				} else {
					print	"CHAT BESTOW - User $params[2] does not exist.\n";
				}
			} else {
				print "CHAT BESTOW - Bestow admin in chat room.\n",
					"Syntax:\n",
					"    chat bestow <user number>\n\n",
					"Options:\n",
					"    <user number> - User number in chat room. Type 'chat info' to get number.\n\n";
			}
		} elsif ($params[1] eq "create") {
			if ($currentChatRoom ne "") {
				print	"CHAT CREATE - You are already in a chat room.\n";
			} elsif ($params[2] ne "") {
				if ($params[3] eq "") {
					$params[3] = 20;
				}
				if ($params[4] eq "") {
					$params[4] = 1;
				}

				$createdChatRoom{'title'} = $params[2];
				$createdChatRoom{'ownerID'} = $accountID;
				$createdChatRoom{'limit'} = $params[3];
				$createdChatRoom{'public'} = $params[4];
				$createdChatRoom{'num_users'} = 1;
				$createdChatRoom{'users'}{$chars[$config{'char'}]{'name'}} = 2;
				sendChatRoomCreate(\$remote_socket, $title, $params[3], $params[4], $params[5]);
			} else {
				print "CHAT CREATE - Create chat room.\n",
					"Syntax:\n",
					"    chat create <title> [<limit> <public flag> <password>]\n\n",
					"Options:\n",
					"    <title>       - Chat room title. Use quote (\") to have the space in title.\n",
					"    <limit>       - Maximum number of user.\n",
					"    <public flag> - 1 is public, 0 is private.\n",
					"    <password>    - Password for private chat room\n\n";
			}
		} elsif ($params[1] eq "info") {
			if ($currentChatRoom ne "") {
				my $public;
				my $limit;
				my $user;
				my $admin;

				print "- CHAT ROOM INFO -----------------------\n",
					"Title                     Users   Public/Private\n";

				$public = ($chatRooms{$currentChatRoom}{'public'}) ? "Public" : "Private";
				$limit = $chatRooms{$currentChatRoom}{'num_users'}."/".$chatRooms{$currentChatRoom}{'limit'};

				PrintFormat(<<'CHATINFO', $chatRooms{$currentChatRoom}{'title'}, $limit, $public);
@<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<< @<<<<<<<<<
CHATINFO
				print "- USERS --------------------------------\n";
				for ($i = 0; $i < @currentChatRoomUsers; $i++) {
					next if ($currentChatRoomUsers[$i] eq "");
					$user = $currentChatRoomUsers[$i];
					$admin = ($chatRooms{$currentChatRoom}{'users'}{$currentChatRoomUsers[$i]} > 1) ? "(Admin)" : "";
					PrintFormat(<<'CHATUSER', $i, $user, $admin);
@<< @<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<
CHATUSER
				}

				print "----------------------------------------\n";
			} else {
				print "CHAT INFO - You are not in a chat room.\n";
			}
		} elsif ($params[1] eq "join") {
			if ($currentChatRoom ne "") {
				print	"CHAT JOIN - You are already in a chat room.\n";
			} elsif (IsNumber($params[2])) {
				if ($chatRoomsID[$params[2]] ne "") {
					sendChatRoomJoin(\$remote_socket, $chatRoomsID[$params[2]], $params[3]);
				} else {
					print	"CHAT JOIN - Chat room $params[2] does not exist.\n";
				}
			} else {
				print "CHAT JOIN - Join chat room.\n",
					"Syntax:\n",
					"    chat join <chat room number>\n\n",
					"Options:\n",
					"    <chat room number> - Chat room number. Type 'chat' to get number.\n\n";
			}
		} elsif ($params[1] eq "kick") {
			if ($currentChatRoom eq "") {
				print "CHAT KICK - You are not in a chat room.\n";
			} elsif (IsNumber($params[2])) {
				if ($currentChatRoomUsers[$params[2]] ne "") {
					sendChatRoomKick(\$remote_socket, $currentChatRoomUsers[$params[2]]);
				} else {
					print	"CHAT KICK - User $params[2] does not exist.\n";
				}
			} else {
				print "CHAT KICK - Kick from chat room.\n",
					"Syntax:\n",
					"    chat kick <user number>\n\n",
					"Options:\n",
					"    <user number> - User number in chat room. Type 'chat info' to get number.\n\n";
			}
		} elsif ($params[1] eq "leave") {
			if ($currentChatRoom eq "") {
				print "CHAT LEAVE - You are not in a chat room.\n";
			} else {
				sendChatRoomLeave(\$remote_socket);
			}
		} elsif ($params[1] eq "mod") {
			if ($currentChatRoom eq "") {
				print "CHAT MOD - You are not in a chat room.\n";
			} elsif ($params[2] ne "") {
				if ($params[3] eq "") {
					$params[3] = 20;
				}
				if ($params[4] eq "") {
					$params[4] = 1;
				}

				sendChatRoomChange(\$remote_socket, $title, $params[3], $params[4], $params[5]);
			} else {
				print "CHAT MOD - Modify current chat room.\n",
					"Syntax:\n",
					"    chat mod <title> [<limit> <public flag> <password>]\n\n",
					"Options:\n",
					"    <title>       - Chat room title. You can use quote (\") to have the space in title.\n",
					"    <limit>       - Maximum number of user.\n",
					"    <public flag> - 1 is public, 0 is private.\n",
					"    <password>    - Password for private chat room\n\n";
			}
		}
	} elsif ($cmd eq "conf") {
		my $val;

		($val) = $inputparam =~ /^\w+ ([\s\S]+)$/;
		@{$ai_v{'temp'}{'config'}} = keys %config;
		if ($params[1] ne "") {
			if (binFind(\@{$ai_v{'temp'}{'config'}}, $params[1]) eq "") {
				print "CONF - Config variable $params[1] doesn't exist.\n";
			} elsif ($val eq "value" || $val eq "?") {
				print "CONF - Config '$params[1]' = $config{$params[1]}.\n";
			} else {
				configModify($params[1], $val);
			}
		} else {
			print "CONF - Set config variable.\n",
				"Syntax:\n",
				"    conf <variable name> [<value>]\n\n";
		}
	} elsif ($cmd eq "confm") {
		my $val;

		($val) = $inputparam =~ /^\w+ \w+ ([\s\S]+)$/;
		@{$ai_v{'temp'}{'config'}} = keys %config;
		if ($params[1] ne "" || $params[2] ne "") {
			$i = 0;
			while (binFind(\@{$ai_v{'temp'}{'config'}}, "$params[1]"."$i"."$params[2]") ne "") {
				configModify("$params[1]"."$i"."$params[2]", $val);
				$i++;
			}
		} else {
			print "CONFM - Set config multi-variable.\n",
				"Syntax:\n",
				"    conf <left variable name> <right variable name> [<value>]\n\n";
		}
	} elsif ($cmd eq "deal") {
		$params[1] = lc($params[1]);

		if ($params[1] eq "") {
			if (%currentDeal) {
				if ($currentDeal{'you_finalize'} && !$currentDeal{'other_finalize'}) {
					print "DEAL - Cannot make the trade - $currentDeal{'name'} has not finalized.\n";
				} elsif ($currentDeal{'final'}) {
					print "DEAL - You already accepted the final deal.\n";
				} elsif ($currentDeal{'you_finalize'} && $currentDeal{'other_finalize'}) {
					$currentDeal{'final'} = 1;
					sendDealTrade(\$remote_socket);
					print "DEAL - You accepted the final Deal\n";
				} else {
					sendDealAddItem(\$remote_socket, 0, $currentDeal{'you_zenny'});
					sendDealFinalize(\$remote_socket);
				}
			} elsif (%incomingDeal) {
				sendDealAccept(\$remote_socket);
			} else {
				print "DEAL - There is no deal to accept.\n";
			}
		} elsif (IsNumber($params[1])) {
			if (%currentDeal) {
				print "DEAL - You are already in a deal.\n";
			} elsif (%incomingDeal) {
				print "DEAL - You must first cancel the incoming deal. Type 'deal no' to cancel.\n";
			} elsif ($playersID[$params[1]] ne "") {
				$outgoingDeal{'ID'} = $playersID[$params[1]];
				sendDeal(\$remote_socket, $playersID[$params[1]]);
			} else {
				print "DEAL - Deal with player.\n",
					"Syntax:\n",
					"    deal <player number>\n\n",
					"Options:\n",
					"    <player number> - Player number. Type 'p' to get number.\n\n";
			}
		} elsif ($params[1] eq "add") {
			if (!%currentDeal) {
				print "DEAL ADD - No deal in progress.\n";
			} elsif ($currentDeal{'you_finalize'}) {
				print "DEAL ADD - Can't add any Items - You already finalized the deal.\n";
			} elsif (IsNumber($params[2])) {
				if (scalar(keys %{$currentDeal{'you'}}) > 10) {
					print "DEAL - You can't add any more items to the deal.\n";
				} elsif (%{$chars[$config{'char'}]{'inventory'}[$params[2]]}) {
					if ($params[3] <= 0 || $params[3] > $chars[$config{'char'}]{'inventory'}[$params[2]]{'amount'}) {
						$params[3] = $chars[$config{'char'}]{'inventory'}[$params[2]]{'amount'};
					}

					$currentDeal{'lastItemAmount'} = $params[3];
					sendDealAddItem(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$params[2]]{'index'}, $params[3]);
				} else {
					print "DEAL ADD - Add items to deal.\n",
						"Syntax:\n",
						"    deal add <item number> [<amount>]\n\n",
						"Options:\n",
						"    <item number> - Inventory item number. Type 'i' to get number.\n",
						"    <amount>      - Inventory Item amount.\n\n";
				}
			} elsif (lc($params[2]) eq "z") {
				if ($params[3] <= 0 || $params[3] > $chars[$config{'char'}]{'zenny'}) {
					$params[3] = $chars[$config{'char'}]{'zenny'};
				}
				$currentDeal{'you_zenny'} = $params[3];
				print "DEAL ADD Z - You put forward $params[3] z to Deal\n";
			} else {
				print "DEAL ADD - Add items or zeny to deal.\n",
					"Syntax:\n",
					"    deal add <item number> [<amount>]\n",
					"    deal add z [<amount>]\n\n";
			}
		} elsif ($params[1] eq "info") {
			if (!%currentDeal) {
				print "DEAL INFO - You are not in a deal\n";
			} else {
				print "- CURRENT DEAL -------------------------\n";

				if ($currentDeal{'other_finalize'}) {
					print "$currentDeal{'name'} - Finalized\n\n";
				} else {
					print "$currentDeal{'name'}\n\n";
				}

				foreach (keys %{$currentDeal{'other'}}) {
					print "$currentDeal{'other'}{$_}{'name'} x $currentDeal{'other'}{$_}{'amount'}\n";
				}

				print "\nZenny: $currentDeal{'other_zenny'}\n\n";

				if ($currentDeal{'you_finalize'}) {
					print "You - Finalized\n\n";
				} else {
					print "You\n\n";
				}

				foreach (keys %{$currentDeal{'you'}}) {
					print "$currentDeal{'you'}{$_}{'name'} x $currentDeal{'you'}{$_}{'amount'}\n";
				}

				print "\nZenny: $currentDeal{'you_zenny'}\n\n";

				print "----------------------------------------\n";
			}
		} elsif ($params[1] eq "no") {
			if (%incomingDeal || %outgoingDeal) {
				sendDealCancel(\$remote_socket);
			} elsif (%currentDeal) {
				sendCurrentDealCancel(\$remote_socket);
			} else {
				print "DEAL NO - There is no incoming/current deal to cancel.\n";
			}
		}
	} elsif ($cmd eq "dealany") {
		$params[1] = lc($params[1]);

		if ($params[1] eq "c") {
			sendDealCancel(\$remote_socket);
		} elsif ($params[1] eq "cc") {
			sendCurrentDealCancel(\$remote_socket);
		} elsif ($params[1] eq "accept") {
			sendDealAccept(\$remote_socket);
		} elsif ($params[1] eq "trade") {
			sendDealTrade(\$remote_socket);
		} elsif ($params[1] eq "zeny") {
			sendDealAddItem(\$remote_socket, 0, $params[2]);
		} elsif ($params[1] eq "end") {
			sendDealFinalize(\$remote_socket);
		}
	} elsif ($cmd eq "debug") {
		my $val;

		($val) = $inputparam =~ /^\w+ ([\s\S]+)$/;
		@{$ai_v{'temp'}{'debug'}} = keys %config;
		if ($params[1] eq "on") {
			configModify("useDebug", 1);
		} elsif ($params[1] eq "off") {
			configModify("useDebug", 0);
		} elsif ($params[1] ne "") {
			if (binFind(\@{$ai_v{'temp'}{'debug'}}, $params[1]) eq "") {
				print "DEBUG - Debug variable $params[1] doesn't exist.\n";
			} elsif ($val eq "value" || $val eq "?") {
				print "DEBUG - Debug '$params[1]' = $config{$params[1]}.\n";
			} else {
				debugModify($params[1], $val);
			}
		} else {
			print "DEBUG - Set debug variable.\n",
				"Syntax:\n",
				"    debug <variable name> [<value>]\n\n";
		}
	} elsif ($cmd eq "e") {
		my $emo;

		$ai_v{'temp'}{'emo'} = ParseEmotion($msgparam);
		if ($ai_v{'temp'}{'emo'} >= 0) {
			sendEmotion(\$remote_socket, $ai_v{'temp'}{'emo'});
		}
	} elsif ($cmd eq "effect") {
		print "- EFFECT LIST --------------------------\n";

		my @id_sort = sort { $a <=> $b } keys %{effects_lut};

		for ($i = 0; $i < @{id_sort}; $i++) {
			$id = $id_sort[$i];
			if ($chars[$config{'char'}]{'effect'}{$id}) {
				PrintMessage("$effects_lut{$id}{'name'}", "green");
			} else {
				PrintMessage("$effects_lut{$id}{'name'}", "dark");
			}
		}

		print "----------------------------------------\n";
	} elsif ($cmd eq "egg") {
		if ($params[1] eq "") {
			if (@eggID) {
				print	"- EGG LIST -----------------------------\n";
				for ($i = 0; $i < @eggID; $i++) {
					next if ($eggID[$i] eq "");
					PrintFormat(<<'EGG', $i, $chars[$config{'char'}]{'inventory'}[$eggID[$i]]{'name'});
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
EGG
				}
				print	"----------------------------------------\n";
			} else {
				print "EGG - Use Pet Incubator to get list.\n";
			}
		} elsif (IsNumber($params[1])) {
			if ($eggID[$params[1]] ne "") {
				$chars[$config{'char'}]{'eggInvIndex'} = $eggID[$params[1]];
				sendIncubator(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$eggID[$params[1]]]{'index'});
			} else {
				print "EGG - Egg incubation.\n",
					"Syntax:\n",
					"    egg <item number>\n\n",
					"Options:\n",
					"    <item number> - Egg item number. Type 'egg' to get number.\n\n";
			}
		}
	} elsif ($cmd eq "eqslot") {
		if (IsNumber($params[1])) {
			EquipSlot($params[1]);
		} else {
			print "EQSLOT - Equip slot.\n",
				"Syntax:\n",
				"    eqslot <slot number>\n\n",
				"Options:\n",
				"    <slot number> - Slot number from 'config.txt'.\n\n";
		}
	} elsif ($cmd eq "follow") {
		if (IsNumber($inputparam)) {
			if ($playersID[$inputparam] ne "") {
				ai_follow($players{$playersID[$inputparam]}{'name'}, 0);
				configModify("follow", 1);
				configModify("followTarget", $players{$playersID[$inputparam]}{'name'});
			} else {
				print "FOLLOW - Follow player.\n",
					"Syntax:\n",
					"    follow <player number>\n\n",
					"Options:\n",
					"    <player number> - Player number. Type 'p' to get number.\n\n";
			}
		} elsif ($inputparam eq "stop") {
			aiRemove("follow");
			configModify("follow", 0);
		} else {
			ai_follow($inputparam, 0);
			configModify("follow", 1);
			configModify("followTarget", $inputparam);
		}
	} elsif ($cmd eq "guild") {
		$params[1] = lc($params[1]);

		if (!%{$chars[$config{'char'}]{'guild'}} && $params[1] ne "join") {
			print "GUILD - You don't have a guild.\n";
		} else {
			my $name;
			my $pos_index;
			my $title;
			my $level;
			my $job;
			my $exp;
			my $support;
			my $id;
			my $char_id;
			my $reason;

			if ($params[1] eq "" || $params[1] eq "id") {
				print	"- GUILD --------------------------------\n";
				print "$chars[$config{'char'}]{'guild'}{'name'} [".getHex($chars[$config{'char'}]{'guild'}{'ID'})."] LV.$chars[$config{'char'}]{'guild'}{'level'}\n";
				print "Master: $chars[$config{'char'}]{'guild'}{'master'}\n";
				print "Online: $chars[$config{'char'}]{'guild'}{'online_member'} / $chars[$config{'char'}]{'guild'}{'total_member'}\n";
				print "Exp: $chars[$config{'char'}]{'guild'}{'exp'} / $chars[$config{'char'}]{'guild'}{'exp_max'}\n";
				print "Average Level: $chars[$config{'char'}]{'guild'}{'avg_level'}\n";
				print	"----------------------------------------\n";
			}

			if ($params[1] eq "") {
				print "#   Name                    Title                   Job        Lv Exp\n";

				for ($i = 0; $i < $chars[$config{'char'}]{'guild'}{'total_member'}; $i++) {
					if ($chars[$config{'char'}]{'guild'}{'member'}[$i]{'online'}) {
						$online = "*";
					} else {
						$online = "";
					}

					$name = $chars[$config{'char'}]{'guild'}{'member'}[$i]{'name'};
					$pos_index = $chars[$config{'char'}]{'guild'}{'member'}[$i]{'pos_index'};
					$title = $chars[$config{'char'}]{'guild'}{'title'}[$pos_index]{'name'};
					$level = $chars[$config{'char'}]{'guild'}{'member'}[$i]{'level'};
					$job = $jobs_lut{$chars[$config{'char'}]{'guild'}{'member'}[$i]{'jobID'}};
					$exp = $chars[$config{'char'}]{'guild'}{'member'}[$i]{'exp'};
					$support = $chars[$config{'char'}]{'guild'}{'member'}[$i]{'support'};

					PrintFormat(<<'GUILDMEMBERS', $i, $online, $name, $title, $job, $level, $exp, $support);
@< @@<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<< @< @<<<<<<<< @<%
GUILDMEMBERS
				}
			} elsif ($params[1] eq "id") {
				print "#   Name                    ID           Char ID\n";

				for ($i = 0; $i < $chars[$config{'char'}]{'guild'}{'total_member'}; $i++) {
					if ($chars[$config{'char'}]{'guild'}{'member'}[$i]{'online'}) {
						$online = "*";
					} else {
						$online = "";
					}

					$name = $chars[$config{'char'}]{'guild'}{'member'}[$i]{'name'};
					$id = getHex($chars[$config{'char'}]{'guild'}{'member'}[$i]{'ID'});
					$char_id = unpack("L1", $chars[$config{'char'}]{'guild'}{'member'}[$i]{'charID'});
					$level = $chars[$config{'char'}]{'guild'}{'member'}[$i]{'level'};
					$job = $jobs_lut{$chars[$config{'char'}]{'guild'}{'member'}[$i]{'jobID'}};
					$exp = $chars[$config{'char'}]{'guild'}{'member'}[$i]{'exp'};
					$support = $chars[$config{'char'}]{'guild'}{'member'}[$i]{'support'};

					PrintFormat(<<'GUILDMEMBERS', $i, $online, $name, $id, $char_id);
@< @@<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<  @>>>>>>>>>>
GUILDMEMBERS
				}
			} elsif ($params[1] eq "query") {
				sendGuildFirstQuery(\$remote_socket);
				sendGuildQueryPage(\$remote_socket, 0);
				sendGuildQueryPage(\$remote_socket, 1);
				sendGuildQueryPage(\$remote_socket, 2);
				sendGuildQueryPage(\$remote_socket, 3);
				sendGuildQueryPage(\$remote_socket, 4);
			} elsif ($params[1] eq "join") {
				if ($incomingGuild{'ID'} eq "") {
					print "GUILD JOIN - Can't accept/deny guild request - no incoming request.\n";
				} elsif ($params[2] eq "0" || $params[2] eq "1") {
					sendGuildJoin(\$remote_socket, $incomingGuild{'ID'}, $params[2]);
					undef %incomingGuild;
				} else {
					print "GUILD JOIN - Join a guild.\n",
						"Syntax:\n",
						"    guild join <flag>\n\n",
						"Options:\n",
						"    <flag> - 0 reject, 1 accept.\n\n";
				}
			} elsif ($params[1] eq "request") {
				if (IsNumber($params[2])) {
					if ($playersID[$params[2]] ne "") {
						sendGuildJoinRequest(\$remote_socket, $playersID[$params[2]], $accountID, $charID);
					} else {
						print "GUILD REQUEST - Player $params[2] does not exist.\n";
					}
				} else {
					print "GUILD REQUEST - Request player to join guild.\n",
						"Syntax:\n",
						"    guild request <player number>\n\n",
						"Options:\n",
						"    <player number> - Player number. Type 'p' to get number.\n\n";
				}
			} elsif ($params[1] eq "leave") {
				($reason) = $inputparam =~ /^\w+ ([\s\S]+)$/;
				sendGuildLeave(\$remote_socket, $chars[$config{'char'}]{'guild'}{'ID'}, $accountID, $charID, $reason);
			} elsif ($params[1] eq "delete") {
				if (IsNumber($params[2])) {
					if ($params[2] < $chars[$config{'char'}]{'guild'}{'total_member'} && $chars[$config{'char'}]{'guild'}{'member'}[$params[2]]{'name'} ne "") {
						($reason) = $inputparam =~ /^\w+ \w+ ([\s\S]+)$/;
						sendGuildMemberDelete(\$remote_socket,
							$chars[$config{'char'}]{'guild'}{'ID'},
							$chars[$config{'char'}]{'guild'}{'member'}[$params[2]]{'ID'},
							$chars[$config{'char'}]{'guild'}{'member'}[$params[2]]{'charID'},
							$reason);
					} else {
						print "GUILD DELETE - Member $params[2] does not exist.\n";
					}
				} else {
					print "GUILD DELETE - Delete guild member.\n",
						"Syntax:\n",
						"    guild delete <member number> [<reason>]\n\n",
						"Options:\n",
						"    <member number> - Member number. Type 'guild' to get number.\n",
						"    <reason>        - Reason to delete.\n\n";
				}
			} elsif ($params[1] eq "ally") {
				if ($incomingAllyGuild{'ID'} eq "") {
					print "GUILD ALLY - Can't accept/deny ally request - no incoming request.\n";
				} elsif ($params[2] eq "0" || $params[2] eq "1") {
					sendGuildAlly(\$remote_socket, $incomingAllyGuild{'ID'}, $params[2]);
				} else {
					print "GUILD ALLY - Ally a guild.\n",
						"Syntax:\n",
						"    guild ally <flag>\n\n",
						"Options:\n",
						"    <flag> - 0 reject, 1 accept.\n\n";
				}
			} elsif ($params[1] eq "allyrequest") {
				if (IsNumber($params[2])) {
					if ($playersID[$params[2]] ne "") {
						sendGuildAllyRequest(\$remote_socket, $playersID[$params[2]], $accountID, $charID);
					} else {
						print "GUILD ALLYREQUEST - Player $params[2] does not exist.\n";
					}
				} else {
					print "GUILD ALLYREQUEST - Request player to be guild ally.\n",
						"Syntax:\n",
						"    guild allyrequest <player number>\n\n",
						"Options:\n",
						"    <player number> - Player number. Type 'p' to get number.\n\n";
				}
			} elsif ($params[1] eq "enemyrequest") {
				if (IsNumber($params[2])) {
					if ($playersID[$params[2]] ne "") {
						sendGuildEnemyRequest(\$remote_socket, $playersID[$params[2]]);
					} else {
						print "GUILD ENEMYREQUEST - Player $params[2] does not exist.\n";
					}
				} else {
					print "GUILD ENEMYREQUEST - Request player to be guild enemy.\n",
						"Syntax:\n",
						"    guild enemyrequest <player number>\n\n",
						"Options:\n",
						"    <player number> - Player number. Type 'p' to get number.\n\n";
				}
			}

			if ($params[1] eq "" || $params[1] eq "id") {
				print	"- ALLIES -------------------------------\n";
				for ($i = 0; $i < @{$chars[$config{'char'}]{'guild'}{'allies'}}; $i++) {
					PrintFormat(<<'GUILDALLIES', $i, $chars[$config{'char'}]{'guild'}{'allies'}[$i]{'name'}, getHex($chars[$config{'char'}]{'guild'}{'allies'}[$i]{'ID'}));
@< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<
GUILDALLIES
				}
				print	"- ENEMY --------------------------------\n";
				for ($i = 0; $i < @{$chars[$config{'char'}]{'guild'}{'enemy'}}; $i++) {
					PrintFormat(<<'GUILDENEMY', $i, $chars[$config{'char'}]{'guild'}{'enemy'}[$i]{'name'}, getHex($chars[$config{'char'}]{'guild'}{'enemy'}[$i]{'ID'}));
@< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<
GUILDENEMY
				}
				print	"----------------------------------------\n";
			}
		}
	} elsif ($cmd eq "i") {
		$params[1] = lc($params[1]);

		if ($params[1] eq "" || $params[1] eq "e" || $params[1] eq "n" || $params[1] eq "u") {
			my $display;

			undef @useable;
			undef @equipment;
			undef @non_useable;

			for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}}; $i++) {
				next if (!%{$chars[$config{'char'}]{'inventory'}[$i]});

				if (IsEquipment($chars[$config{'char'}]{'inventory'}[$i])) {
					push @equipment, $i;
				} elsif ($chars[$config{'char'}]{'inventory'}[$i]{'type'} <= 2) {
					push @useable, $i;
				} else {
					push @non_useable, $i;
				}
			}

			print "- INVENTORY ----------------------------\n";
			if ($params[1] eq "" || $params[1] eq "e") {
				print	"<Equipment>\n";
				for ($i = 0; $i < @equipment; $i++) {
					$display = GenShowName($chars[$config{'char'}]{'inventory'}[$equipment[$i]]);
					$display .= " x $chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'amount'}";
					$display .= " ($itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'type'}})";

					if ($chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'equipped'}) {
						$display .= " -- Eqp: $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'type_equip'}}";
					}

					if (!$chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'identified'}) {
						$display .= " -- Not Identified";
					}

					PrintFormat(<<'EQUIPMENT', $equipment[$i], $display);
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
EQUIPMENT
				}
			}

			if ($params[1] eq "" || $params[1] eq "n") {
				print "<Non-Useable>\n";
				for ($i = 0; $i < @non_useable; $i++) {
					$display = $chars[$config{'char'}]{'inventory'}[$non_useable[$i]]{'name'};
					$display .= " x $chars[$config{'char'}]{'inventory'}[$non_useable[$i]]{'amount'}";
					$display .= " ($itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$non_useable[$i]]{'type'}})";

					PrintFormat(<<'NONUSEABLE', $non_useable[$i], $display);
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
NONUSEABLE
				}
			}

			if ($params[1] eq "" || $params[1] eq "u") {
				print "<Useable>\n";
				for ($i = 0; $i < @useable; $i++) {
					$display = $chars[$config{'char'}]{'inventory'}[$useable[$i]]{'name'};
					$display .= " x $chars[$config{'char'}]{'inventory'}[$useable[$i]]{'amount'}";
					$display .= " ($itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$useable[$i]]{'type'}})";

					PrintFormat(<<'USEABLE', $useable[$i], $display);
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
USEABLE
				}
			}
			print "----------------------------------------\n";
		} elsif ($params[1] eq "desc") {
			if (IsNumber($params[2])) {
				if (%{$chars[$config{'char'}]{'inventory'}[$params[2]]}) {
					ShowWrapperInventory($chars[$config{'char'}]{'inventory'}[$params[2]]{'nameID'});
					if (!$config{'wrapperInterface'}) {
						printItemDesc($chars[$config{'char'}]{'inventory'}[$params[2]]{'nameID'});
					}
				} else {
					print	"I DESC - Item $params[2] does not exist.\n";
				}
			} else {
				print "I DESC - Item description.\n",
					"Syntax:\n",
					"    i desc <item number>\n\n",
					"Options:\n",
					"    <item number> - Inventory item number. Type 'i' to get number.\n\n";
			}
		} elsif ($params[1] eq "drop") {
			if (IsNumber($params[2])) {
				if (%{$chars[$config{'char'}]{'inventory'}[$params[2]]}) {
					if ($params[3] <= 0 || $params[3]> $chars[$config{'char'}]{'inventory'}[$params[2]]{'amount'}) {
						$params[3] = $chars[$config{'char'}]{'inventory'}[$params[2]]{'amount'};
					}
					sendDrop(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$params[2]]{'index'}, $params[3]);
				} else {
					print	"I DROP - Item $params[2] does not exist.\n";
				}
			} else {
				print "I DROP - Drop inventory item.\n",
					"Syntax:\n",
					"    i drop <item number>\n\n",
					"Options:\n",
					"    <item number> - Inventory item number. Type 'i' to get number.\n\n";
			}
		} elsif ($params[1] eq "eq") {
			if (IsNumber($params[2])) {
				if (!%{$chars[$config{'char'}]{'inventory'}[$params[2]]}) {
					print	"I EQ - Item $params[2] does not exist.\n";
				} elsif (!IsEquipment($chars[$config{'char'}]{'inventory'}[$params[2]])) {
					print	"I EQ - Item $params[2] can't be equipped.\n";
				} else {
					if ($chars[$config{'char'}]{'inventory'}[$params[2]]{'type_equip'} == 256
						|| $chars[$config{'char'}]{'inventory'}[$params[2]]{'type_equip'} == 513) {
						sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$params[2]]{'index'}, 0, 1);
					} elsif ($chars[$config{'char'}]{'inventory'}[$params[2]]{'type_equip'} == 512) {
						sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$params[2]]{'index'}, 0, 2);
					} else {
						if ($params[3] eq "left") {
							if ($chars[$config{'char'}]{'inventory'}[$params[2]]{'type_equip'} == 136) {
								sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$params[2]]{'index'}, 8, 0);
							} else {
								sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$params[2]]{'index'}, 32, 0);
							}
						} else {
							if ($chars[$config{'char'}]{'inventory'}[$params[2]]{'type_equip'} == 136) {
								sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$params[2]]{'index'}, 128, 0);
							} else {
								sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$params[2]]{'index'}, $chars[$config{'char'}]{'inventory'}[$params[2]]{'type_equip'}, 0);
							}
						}
					}
				}
			} else {
				print "I EQ - Equip inventory item.\n",
					"Syntax:\n",
					"    i eq <item number>\n\n",
					"Options:\n",
					"    <item number> - Inventory item number. Type 'i' to get number.\n\n";
			}
		} elsif ($params[1] eq "uneq") {
			if (IsNumber($params[2])) {
				if (!%{$chars[$config{'char'}]{'inventory'}[$params[2]]}) {
					print	"I UNEQ - Item $params[2] does not exist.\n";
				} elsif ($chars[$config{'char'}]{'inventory'}[$params[2]]{'equipped'} == 0) {
					print	"I UNEQ - Item $params[2] is not equipped.\n";
				} else {
					sendUnequip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$params[2]]{'index'});
				}
			} else {
				print "I UNEQ - Un-equip inventory item.\n",
					"Syntax:\n",
					"    i uneq <item number>\n\n",
					"Options:\n",
					"    <item number> - Inventory item number. Type 'i' to get number.\n\n";
			}
		} elsif ($params[1] eq "m") {
			if (IsNumber($params[2]) && IsNumber($params[3])) {
				if (!%{$chars[$config{'char'}]{'inventory'}[$params[2]]}) {
					print	"I M - Item $params[2] does not exist.\n";
				} elsif ($chars[$config{'char'}]{'inventory'}[$params[2]]{'type'} > 2) {
					print	"I M - Item $params[2] is not useable.\n";
				} elsif ($monstersID[$params[3]] eq "") {
					print	"I M - Monster $params[3] does not exist.\n";
				} else {
					sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$params[2]]{'index'}, $monstersID[$params[3]]);
				}
			} else {
				print "I M - Use item on monster.\n",
					"Syntax:\n",
					"    i m <item number> <monster number>\n\n",
					"Options:\n",
					"    <item number>    - Inventory item number. Type 'i' to get number.\n",
					"    <monster number> - Monster number. Type 'm' to get number.\n\n";
			}
		} elsif ($params[1] eq "p") {
			if (IsNumber($params[2]) && IsNumber($params[3])) {
				if (!%{$chars[$config{'char'}]{'inventory'}[$params[2]]}) {
					print	"I P - Item $params[2] does not exist.\n";
				} elsif ($chars[$config{'char'}]{'inventory'}[$params[2]]{'type'} > 2) {
					print	"I P - Item $params[2] is not useable.\n";
				} elsif ($playersID[$params[3]] eq "") {
					print	"I P - Player $params[3] does not exist.\n";
				} else {
					sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$params[2]]{'index'}, $playersID[$params[3]]);
				}
			} else {
				print "I P - Use item on player.\n",
					"Syntax:\n",
					"    i p <item number> <player number>\n\n",
					"Options:\n",
					"    <item number>   - Inventory item number. Type 'i' to get number.\n",
					"    <player number> - Player number. Type 'p' to get number.\n\n";
			}
		} elsif ($params[1] eq "s") {
			if (IsNumber($params[2])) {
				if (!%{$chars[$config{'char'}]{'inventory'}[$params[2]]}) {
					print	"I S - Item $params[2] does not exist.\n";
				} elsif ($chars[$config{'char'}]{'inventory'}[$params[2]]{'type'} > 2) {
					print	"I S - Item $params[2] is not useable.\n";
				} else {
					sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$params[2]]{'index'}, $accountID);
				}
			} else {
				print "I S - Use item on self.\n",
					"Syntax:\n",
					"    i s <item number>\n\n",
					"Options:\n",
					"    <item number>   - Inventory item number. Type 'i' to get number.\n\n";
			}
		}
	} elsif ($cmd eq "iden") {
		if ($params[1] eq "") {
			if (@identifyID) {
				print	"- IDENTIFY LIST ------------------------\n";
				for ($i = 0; $i < @identifyID; $i++) {
					next if ($identifyID[$i] eq "");
					PrintFormat(<<'IDENTIFY', $i, $chars[$config{'char'}]{'inventory'}[$identifyID[$i]]{'name'});
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
IDENTIFY
				}
				print	"----------------------------------------\n";
			} else {
				print "IDEN - Use Magnifier to get list.\n";
			}
		} elsif (IsNumber($params[1])) {
			if ($identifyID[$params[1]] ne "") {
				sendIdentify(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$identifyID[$params[1]]]{'index'});
			} else {
				print "IDEN - Identify item.\n",
					"Syntax:\n",
					"    iden <item number>\n\n",
					"Options:\n",
					"    <item number> - Identify item number. Type 'iden' to get number.\n\n";
			}
		}
	} elsif ($cmd eq "ignore") {
		my $player;
		my $flag;

		($player, $flag) = $inputparam =~ /^([\s\S]*) ([\s\S]*?)$/;
		if ($player ne "" && ($flag eq "0" || $flag eq "1")) {
			if ($player eq "all") {
				sendIgnoreAll(\$remote_socket, !$flag);

				if ($flag) {
					print "IGNORE - All player are ignored.";
				} else {
					print "IGNORE - All player are not ignored.";
				}
			} else {
				sendIgnore(\$remote_socket, $player, !$flag);

				if ($flag) {
					print "IGNORE - $player is ignored.";
				} else {
					print "IGNORE - $player is not ignored.";
				}
			}
		} else {
			print "IGNORE - Ignore player.\n",
				"Syntax:\n",
				"    ignore <player name> <flag>\n\n",
				"Options:\n",
				"    <player name> - Any player name or 'all' to ignore all.\n";
				"    <flag>        - 0 not ignore, 1 ignore\n\n";
		}
	} elsif ($cmd eq "item") {
		$params[1] = lc($params[1]);

		if ($params[1] eq "") {
			if (@itemsID) {
				print	"- ITEM LIST ----------------------------\n",
					"#    Name\n";
				for ($i = 0; $i < @itemsID; $i++) {
					next if ($itemsID[$i] eq "");
					PrintFormat(<<'ILIST', $i, "$items{$itemsID[$i]}{'name'} x $items{$itemsID[$i]}{'amount'}");
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
ILIST
				}
				print	"----------------------------------------\n";
			} else {
				print "ITEM - No item(s) on the ground.\n";
			}
		} elsif ($params[1] eq "take") {
			if (IsNumber($params[2])) {
				if ($itemsID[$params[2]] ne "") {
					take($itemsID[$params[2]]);
				} else {
					print "ITEM TAKE - Item $params[2] does not exist.\n";
				}
			} else {
				print "ITEM TAKE - Take item on the  ground.\n",
					"Syntax:\n",
					"    item take <item number>\n\n",
					"Options:\n",
					"    <item number> - Item number. Type 'item' to get number.\n\n";
			}
		}
	} elsif ($cmd eq "look") {
		if (IsNumber($params[1]) && ($params[2] eq "" || IsNumber($params[2]))) {
			look($params[1], $params[2]);
		} else {
			print "LOOK - Look around.\n",
				"Syntax:\n",
				"    look <body dir> [<head dir>]\n\n",
				"Options:\n",
				"    <body dir> - Body direction.\n";
				"    <head dir> - Head direction.\n\n";
		}
	} elsif ($cmd eq "m") {
		if (@monstersID) {
			my $dmgTo;
			my $dmgFrom;

			print	"- MONSTER LIST -------------------------\n",
				"#    Name                     ID          DmgTo    DmgFrom\n";
			for ($i = 0; $i < @monstersID; $i++) {
				next if ($monstersID[$i] eq "");
				$dmgTo = ($monsters{$monstersID[$i]}{'dmgTo'} ne "")
					? $monsters{$monstersID[$i]}{'dmgTo'}
					: 0;
				$dmgFrom = ($monsters{$monstersID[$i]}{'dmgFrom'} ne "")
					? $monsters{$monstersID[$i]}{'dmgFrom'}
					: 0;
				PrintFormat(<<'MLIST', $i, $monsters{$monstersID[$i]}{'name'}, getHex($monstersID[$i]), $dmgTo, $dmgFrom);
@<<< @<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<< @<<<<    @<<<<
MLIST
			}
			print	"----------------------------------------\n";
		} else {
			print "M - No monster(s) found.\n";
		}
	} elsif ($cmd eq "memo") {
		print "MEMO - Location $maps_lut{$field{'name'}.'.rsw'}($field{'name'}) : $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'} \n";
		sendMemo(\$remote_socket);
	} elsif ($cmd eq "mix") {
		$params[1] = lc($params[1]);

		if ($params[1] eq "") {
			if (@mixtureID) {
				my $name;

				print	"- MIXTURE LIST -------------------------\n";
				for ($i = 0; $i < @mixtureID; $i++) {
					next if ($mixtureID[$i] eq "");
					$name = ($items_lut{$mixtureID[$i]} ne "") ? $items_lut{$mixtureID[$i]} : "Unknown ".$mixtureID[$i];

					PrintFormat(<<'MIXTURE', $i, $name);
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
MIXTURE
				}
				print	"----------------------------------------\n";
			} else {
				print "MIX - Use item or skill to get list.\n";
			}
		} elsif (IsNumber($params[1])) {
			if ($mixtureID[$params[1]] ne "") {
				sendMixture(\$remote_socket, $mixtureID[$params[1]]);
			} else {
				print "MIX - Mixture item.\n",
					"Syntax:\n",
					"    mix <item number>\n\n",
					"Options:\n",
					"    <item number> - Mixture item number. Type 'mix' to get number.\n\n";
			}
		}
	} elsif ($cmd eq "move" || $cmd eq "go") {
		$params[1] = lc($params[1]);

		if ($params[1] eq "party" && IsNumber($params[2])) {
			$i = $params[2];
			if ($partyUsersID[$i] ne "") {
				if (IsPartyMap($partyUsersID[$i], $field{'name'}) && IsPartyMove($partyUsersID[$i])) {
					$ai_v{'temp'}{'x'} = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'x'};
					$ai_v{'temp'}{'y'} = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'y'};
					$ai_v{'temp'}{'map'} = $field{'name'};
					print "MOVE PARTY - Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}.\n";
					$ai_v{'sitAuto_forceStop'} = 1;
					ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
				} elsif (IsPartyOnline($partyUsersID[$i])) {
					undef $ai_v{'temp'}{'x'};
					undef $ai_v{'temp'}{'y'};
					($ai_v{'temp'}{'map'}) = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'map'} =~ /([\s\S]*)\.gat/;
					print "MOVE PARTY - Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}).\n";
					$ai_v{'sitAuto_forceStop'} = 1;
					ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
				}
			} else {
				print "MOVE PARTY - Move to party member.\n",
					"Syntax:\n",
					"    move party <member number>\n\n",
					"Options:\n",
					"    <member number> - Party member number. Type 'party' to get number.\n\n";
			}
		} elsif ($params[1] eq "") {
			do {
				$ai_v{'temp'}{'x'} = int(rand() * ($field{'width'} - 1));
				$ai_v{'temp'}{'y'} = int(rand() * ($field{'height'} - 1));
			} while ($field{'field'}[$ai_v{'temp'}{'y'}*$field{'width'} + $ai_v{'temp'}{'x'}]);
			$ai_v{'temp'}{'map'} = $field{'name'};
			print "MOVE - Calculating random route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}.\n";
			$ai_v{'sitAuto_forceStop'} = 1;
			ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
		} elsif ($params[2] eq "") {
			$ai_v{'temp'}{'map'} = $params[1];
			if ($maps_lut{$ai_v{'temp'}{'map'}.".rsw"}) {
				undef $ai_v{'temp'}{'x'};
				undef $ai_v{'temp'}{'y'};
				print "MOVE - Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}).\n";
				$ai_v{'sitAuto_forceStop'} = 1;
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				print "MOVE - Map $ai_v{'temp'}{'map'} does not exist.\n";
			}
		} elsif ($params[3] eq "" && IsNumber($params[1]) && IsNumber($params[2])) {
			$ai_v{'temp'}{'map'} = $field{'name'};
			$ai_v{'temp'}{'x'} = $params[1];
			$ai_v{'temp'}{'y'} = $params[2];
			print "MOVE - Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}.\n";
			$ai_v{'sitAuto_forceStop'} = 1;
			ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
		} elsif (IsNumber($params[2]) && IsNumber($params[3])) {
			$ai_v{'temp'}{'map'} = $params[1];
			$ai_v{'temp'}{'x'} = $params[2];
			$ai_v{'temp'}{'y'} = $params[3];
			if ($maps_lut{$ai_v{'temp'}{'map'}.".rsw"}) {
				print "MOVE - Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}.\n";
				$ai_v{'sitAuto_forceStop'} = 1;
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				print "MOVE - Map $ai_v{'temp'}{'map'} does not exist.\n";
			}
		} else {
			print "MOVE, GO - Move command.\n",
				"Syntax:\n",
				"    move\n",
				"    move <map>\n",
				"    move <map> <x> <y>\n",
				"    move <x> <y>\n",
				"    move party <member number>\n\n";
		}
	} elsif ($cmd eq "n") {
		$params[1] = lc($params[1]);

		if ($params[1] eq "") {
			if (@npcsID) {
				print	"- NPC ----------------------------------\n",
					"#    ID    Name                         Coordinates\n";
				for ($i = 0; $i < @npcsID; $i++) {
					next if ($npcsID[$i] eq "");
					PrintFormat(<<'NLIST', $i, $npcs{$npcsID[$i]}{'nameID'}, $npcs{$npcsID[$i]}{'name'}, "($npcs{$npcsID[$i]}{'pos'}{'x'}, $npcs{$npcsID[$i]}{'pos'}{'y'})");
@<<< @<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<
NLIST
				}
				print	"----------------------------------------\n";
			} else {
				print "N - No npc(s) found.\n";
			}
		} elsif ($params[1] eq "talk") {
			if (IsNumber($params[2])) {
				if ($npcsID[$params[2]] ne "") {
					sendTalk(\$remote_socket, $npcsID[$params[2]]);
				} else {
					print	"N TALK - NPC $params[1] does not exist.\n";
				}
			} else {
				print "N TALK - Talk to NPC.\n",
					"Syntax:\n",
					"    n talk <npc number>\n\n",
					"Options:\n",
					"    <npc number> - NPC number. Type 'n' to get number.\n\n";
			}
		} elsif (!%talk) {
			print	"N - You are not talking to any NPC.\n";
		} elsif ($params[1] eq "resp") {
			if ($params[2] eq "") {
				print	"- NPC RESPONSES ------------------------\n";
				print "NPC: $npcs{$talk{'nameID'}}{'name'}\n";
				print "#  Response\n";

				for ($i=0; $i < @{$talk{'responses'}}; $i++) {
					PrintFormat(<<'RESPONSES', $i, $talk{'responses'}[$i]);
@< @<<<<<<<<<<<<<<<<<<<<<<
RESPONSES
				}

				print "$i  Cancel\n";
				print	"----------------------------------------\n";
			} elsif (IsNumber($params[2])) {
				if ($params[2] >= @{$talk{'responses'}}) {
					$params[2] = 255;
				} else {
					$params[2] += 1;
				}

				sendTalkResponse(\$remote_socket, $talk{'ID'}, $params[2]);
			} else {
				print "N RESP - Response to NPC.\n",
					"Syntax:\n",
					"    n resp\n",
					"    n resp <choice number>\n\n";
			}
		} elsif ($params[1] eq "cont") {
			sendTalkContinue(\$remote_socket, $talk{'ID'});
		} elsif ($params[1] eq "no") {
			sendTalkCancel(\$remote_socket, $talk{'ID'});
		}
	} elsif ($cmd eq "p") {
		$params[1] = lc($params[1]);

		if ($params[1] eq "") {
			if (@playersID) {
				my $name;

				print	"- PLAYER LIST --------------------------\n",
					"#    Name                     Sex         Job         ID\n";
				for ($i = 0; $i < @playersID; $i++) {
					next if ($playersID[$i] eq "");
					if (%{$players{$playersID[$i]}{'guild'}}) {
						$name = "$players{$playersID[$i]}{'name'} [$players{$playersID[$i]}{'guild'}{'name'}]";
					} else {
						$name = $players{$playersID[$i]}{'name'};
					}

					PrintFormat(<<'PLIST', $i, $name, $sex_lut{$players{$playersID[$i]}{'sex'}}, $jobs_lut{$players{$playersID[$i]}{'jobID'}}, getHex($playersID[$i]));
@<<< @<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<< @<<<<<<<<<< @>>>>>>>>>>
PLIST
				}
				print	"----------------------------------------\n";
			} else {
				print "P - No player(s) found.\n";
			}
		} elsif ($params[1] eq "judge") {
			if (IsNumber($params[2]) && ($params[3] eq "0" || $params[3] eq "1")) {
				if ($playersID[$params[2]] ne "") {
					sendAlignment(\$remote_socket, $playersID[$params[2]], $params[3]);
				} else {
					print "P JUDGE - Player $params[2] does not exist.\n";
				}
			} else {
				print "P JUDGE - Give an alignment point to player.\n",
					"Syntax:\n",
					"    p judge <player number> <flag>\n\n",
					"Options:\n",
					"    <player number> - Player number. Type 'p' to get number.\n",
					"    <flag>          - 0 good, 1 bad\n\n";
			}
		}
	} elsif ($cmd eq "party") {
		$params[1] = lc($params[1]);

		if (!%{$chars[$config{'char'}]{'party'}} && $params[1] ne "create" && $params[1] ne "join") {
			print "PARTY - You don't have a party.\n";
		} else {
			my $name;
			my $admin;
			my $map;
			my $coord;
			my $percent_hp;
			my $hp;
			my $online;

			if ($params[1] eq "") {
				print	"- PARTY --------------------------------\n";
				print "$chars[$config{'char'}]{'party'}{'name'}\n";
				print "#   Name                  Location              Online HP\n";
				for ($i = 0; $i < @partyUsersID; $i++) {
					next if ($partyUsersID[$i] eq "");

					$name = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'name'};
					$admin = ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'admin'}) ? "*" : "";

					if ($partyUsersID[$i] eq $accountID) {
						$online = "Yes";
						($map) = $map_name =~ /([\s\S]*)\.gat/;
						$coord = "$chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}";
						$percent_hp = sprintf("%.2f", $chars[$config{'char'}]{'hp'} * 100 / $chars[$config{'char'}]{'hp_max'});
						$hp = "$chars[$config{'char'}]{'hp'}/$chars[$config{'char'}]{'hp_max'} ($percent_hp%)";
					} else {
						$online = ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'}) ? "Yes" : "No";
						($map) = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'map'} =~ /([\s\S]*)\.gat/;
						$coord = "$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'x'}, $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'y'}";
						if ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'} > 0)  {
							$percent_hp = sprintf("%.2f", $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp'} * 100 / $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'});
							$hp = "$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp'}/$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'} ($percent_hp%)";
						} else {
							$hp = "";
						}
					}

					PrintFormat(<<'PARTYUSERS', $i, $admin, $name, "$map ($coord)", $online, $hp);
@< @@<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<< @<<    @<<<<<<<<<<<<<<<<<<
PARTYUSERS
				}
				print	"----------------------------------------\n";
			} elsif ($params[1] eq "create") {
				($name) = $inputparam =~ /^\w+ ([\s\S]+)$/;
				if ($name ne "") {
					sendPartyOrganize(\$remote_socket, $name);
				} else {
					print "PARTY CREATE - Create a party.\n",
						"Syntax:\n",
						"    party create <party name>\n\n",
						"Options:\n",
						"    <party name> - Any party name.\n\n";
				}
			} elsif ($params[1] eq "join") {
				if ($incomingParty{'ID'} eq "") {
					print "PARTY JOIN - Can't accept/deny party request - no incoming request.\n";
				} elsif ($params[2] eq "0" || $params[2] eq "1") {
					sendPartyJoin(\$remote_socket, $incomingParty{'ID'}, $params[2]);
					undef %incomingParty;
				} else {
					print "PARTY JOIN - Join a party.\n",
						"Syntax:\n",
						"    party join <flag>\n\n",
						"Options:\n",
						"    <flag> - 0 reject, 1 accept.\n\n";
				}
			} elsif ($params[1] eq "request") {
				if (IsNumber($params[2])) {
					if ($playersID[$params[2]] ne "") {
						sendPartyJoinRequest(\$remote_socket, $playersID[$params[2]]);
					} else {
						print "PARTY REQUEST - Player $params[2] does not exist.\n";
					}
				} else {
					print "PARTY REQUEST - Request player to join party.\n",
						"Syntax:\n",
						"    party request <player number>\n\n",
						"Options:\n",
						"    <player number> - Player number. Type 'p' to get number.\n\n";
				}
			} elsif ($params[1] eq "leave") {
				sendPartyLeave(\$remote_socket);
			} elsif ($params[1] eq "kick") {
				if (IsNumber($params[2])) {
					if ($partyUsersID[$params[2]] ne "") {
						sendPartyKick(\$remote_socket, $partyUsersID[$params[2]], $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$params[2]]}{'name'});
					} else {
						print "PARTY KICK - Member $params[2] does not exist.\n";
					}
				} else {
					print "PARTY KICK - Kick party member.\n",
						"Syntax:\n",
						"    party kick <member number>\n\n",
						"Options:\n",
						"    <member number> - Member number. Type 'party' to get number.\n\n";
				}
			} elsif ($params[1] eq "share") {
				if ($params[2] eq "0" || $params[2] eq "1") {
					sendPartyShareEXP(\$remote_socket, $params[2]);
				} else {
					print "PARTY SHARE - Share EXP.\n",
						"Syntax:\n",
						"    party share <flag>\n\n",
						"Options:\n",
						"    <flag> - 0 not share, 1 share.\n\n";
				}
			}
		}
	} elsif ($cmd eq "pet") {
		$params[1] = lc($params[1]);

		if ($params[1] eq "") {
			if (@petsID) {
				print "- PET LIST -----------------------------\n",
					"#    Type                     Name\n";
				for ($i = 0; $i < @petsID; $i++) {
					next if ($petsID[$i] eq "");
					PrintFormat(<<'PETLIST', $i, $pets{$petsID[$i]}{'name'}, $pets{$petsID[$i]}{'name_given'});
@<<< @<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<
PETLIST
				}
				print "----------------------------------------\n";
			} else {
				print "PET - There are no pet around here.\n";
			}
		} elsif (!%{$chars[$config{'char'}]{'pet'}}) {
			print "PET - No pet information. Sending query...\n";
			sendPetCommand(\$remote_socket, 0);
		} elsif ($params[1] eq "catch") {
			if (IsNumber($params[2])) {
				if ($monstersID[$params[2]] ne "") {
					sendCatch(\$remote_socket, $monstersID[$params[2]]);
				} else {
					print	"PET CATCH - Monster $params[2] does not exist.\n";
				}
			} else {
				print "PET CATCH - Catch a monster.\n",
					"Syntax:\n",
					"    pet catch <monster number>\n\n",
					"Options:\n",
					"    <monster number> - Type 'm' to get the monsters list.\n\n";
			}
		} elsif ($params[1] eq "feed") {
			sendPetCommand(\$remote_socket, 1);
		} elsif ($params[1] eq "info") {
			$name = $chars[$config{'char'}]{'pet'}{'name'};
			$level = $chars[$config{'char'}]{'pet'}{'level'};
			$hungry = $chars[$config{'char'}]{'pet'}{'hungry'};
			$friendly = $chars[$config{'char'}]{'pet'}{'friendly'};
			$accessory = $chars[$config{'char'}]{'pet'}{'accessory_name'};

			print "- PET -----------------------------\n";
			PrintFormat(<<'PET', $name, $level, $hungry, $friendly, $accessory);
@<<<<<<<<<<<<<<<<<<<<<<<<< LV.@<
Hungry:    @<<
Friendly:  @<<<
Accessory: @<<<<<<<<<<<<<<<<<<<<<<<
PET
			print "-----------------------------------\n";
		} elsif ($params[1] eq "play") {
			sendPetCommand(\$remote_socket, 2);
		} elsif ($params[1] eq "keep") {
			sendPetCommand(\$remote_socket, 3);
		} elsif ($params[1] eq "unequip") {
			sendPetCommand(\$remote_socket, 4);
		} else {
			print "PET - Pet command.\n",
				"Syntax:\n",
				"    pet catch <monster number>\n",
				"    pet feed\n",
				"    pet info\n",
				"    pet play\n",
				"    pet keep\n",
				"    pet list\n",
				"    pet unequip\n\n";
		}
	} elsif ($cmd eq "portal") {
		if (@portalsID) {
			print	"- PORTAL LIST --------------------------\n",
				"#    Name                                Coordinates\n";
			for ($i = 0; $i < @portalsID; $i++) {
				next if ($portalsID[$i] eq "");
				PrintFormat(<<'PORTALLIST', $i, $portals{$portalsID[$i]}{'name'}, "($portals{$portalsID[$i]}{'pos'}{'x'},$portals{$portalsID[$i]}{'pos'}{'y'})");
@<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<
PORTALLIST
			}
			print	"----------------------------------------\n";
		} else {
			print "PORTAL - No portal(s) found.\n";
		}
	} elsif ($cmd eq "quit") {
		quit();
	} elsif ($cmd eq "reconnect") {
		reconnect();
	} elsif ($cmd eq "reload") {
		if ($params[1] ne "") {
			parseReload($params[1]);
		} else {
			print "RELOAD - Reload configuration file(s).\n",
				"Syntax:\n",
				"    reload <file name>\n\n",
				"Options:\n",
				"    <file name> - Full file name or some part of file name to reload.\n\n";
		}
	} elsif ($cmd eq "sell") {
		$params[1] = lc($params[1]);

		if ($talk{'buyOrSell'}) {
			print "SELL - Sending query...\n";
			sendGetSellList(\$remote_socket, $talk{'ID'});
		} elsif (IsNumber($params[1])) {
			if (%{$chars[$config{'char'}]{'inventory'}[$params[1]]}) {
				if ($params[2] <= 0 || $params[2] > $chars[$config{'char'}]{'inventory'}[$params[1]]{'amount'}) {
					$params[2] = $chars[$config{'char'}]{'inventory'}[$params[1]]{'amount'};
				}

				sendSell(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$params[1]]{'index'}, $params[2]);
			} else {
				print	"SELL - Item $params[1] does not exist.\n";
			}
		} else {
			print "SELL - Sell item(s).\n",
				"Syntax:\n",
				"    sell <item number>\n\n",
				"Options:\n",
				"    <item number> - Inventory item number. Type 'i' to get number.\n\n";
		}
	} elsif ($cmd eq "send") {
		if ($inputparam ne "") {
			sendRaw(\$remote_socket, $inputparam);
		} else {
			print "SEND - Send raw packet.\n",
				"Syntax:\n",
				"    send <data>\n\n",
				"Options:\n",
				"    <data> - Data byte(s), format is '0xFF 0xEE ...' or 'FF EE ...'.\n\n";
		}
	} elsif ($cmd eq "shop") {
		$params[1] = lc($params[1]);
		if ($chars[$config{'char'}]{'shop'} == 0 && $params[1] ne "open") {
			print "SHOP - You don't have a shop.\n";
		} elsif ($params[1] eq "") {
			my $iden;

			print	"- SHOP LIST ----------------------------\n",
			print "#   Name                                     Type        Qty   Price     Sold\n";

			for ($i = 0; $i < @{$shop{'inventory'}}; $i++) {
				next if (!%{$shop{'inventory'}[$i]});
				if (!($shop{'inventory'}[$i]{'identified'})) {
					$iden = "*";
				} else {
					$iden = "";
				}

				PrintFormat(<<'SHOPLIST', $i, $iden, $shop{'inventory'}[$i]{'name'}, $itemTypes_lut{$shop{'inventory'}[$i]{'type'}}, $shop{'inventory'}[$i]{'amount'}, $shop{'inventory'}[$i]{'price'}, $shop{'inventory'}[$i]{'sold'});
@< @@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<< @>>>> @>>>>>>>z @>>>>
SHOPLIST
			}
			print	"----------------------------------------\n",
			print "You have earned $shop{'earned'}z.\n";
		} elsif ($params[1] eq "close") {
			ShopClose(\$remote_socket);
		} elsif ($params[1] eq "open") {
			if ($chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'lv'} > 0) {
				$shop{'auto'} = 1;
				ai_skillUse($chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'ID'}, $chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'lv'}, 0, 0, 0, $accountID);
			} else {
				print "SHOP - You don't have a skill to open shop.\n";
			}
		} else {
			print "SHOP - Shop command.\n",
				"Syntax:\n",
				"    shop\n",
				"    shop open\n",
				"    shop close\n\n";
		}
	} elsif ($cmd eq "sit") {
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
	} elsif ($cmd eq "skill") {
		$params[1] = lc($params[1]);
		if ($params[1] eq "") {
			print	"- SKILL LIST ---------------------------\n",
			print "#  Skill Name                    Lv     SP\n";
			for ($i=0; $i < @skillsID; $i++) {
				PrintFormat(<<'SKILLS', $i, $skills_lut{$skillsID[$i]}, $chars[$config{'char'}]{'skills'}{$skillsID[$i]}{'lv'}, $skillsSP_lut{$skillsID[$i]}{$chars[$config{'char'}]{'skills'}{$skillsID[$i]}{'lv'}});
@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<    @<<<
SKILLS
			}
			print "\nSkill Points: $chars[$config{'char'}]{'points_skill'}\n";
			print	"----------------------------------------\n",
		} elsif ($params[1] eq "add") {
			if (IsNumber($params[2])) {
				if ($skillsID[$params[2]] eq "") {
					print	"SKILL ADD - Skill $params[2] does not exist.\n";
				} elsif ($chars[$config{'char'}]{'points_skill'} < 1) {
					print	"SKILL ADD - Not enough skill points to increase $skills_lut{$skillsID[$params[2]]}.\n";
				} else {
					sendAddSkillPoint(\$remote_socket, $chars[$config{'char'}]{'skills'}{$skillsID[$params[2]]}{'ID'});
				}
			} else {
				print "SKILL ADD - Add skill point.\n",
					"Syntax:\n",
					"    skill add <skill number>\n\n",
					"Options:\n",
					"    <skill number> - Skill number. Type 'skill' to get number.\n\n";
			}
		} elsif ($params[1] eq "desc") {
			if (IsNumber($params[2])) {
				if ($skillsID[$params[2]] eq "") {
					print	"SKILL DESC - Skill $params[2] does not exist.\n";
				} else {
					print	"- SKILL DESCRIPTION --------------------\n",
					print "$skills_lut{$skillsID[$params[2]]}\n\n";
					print "$skillsDesc_lut{$skillsID[$params[2]]}\n";
					print	"----------------------------------------\n",
				}
			} else {
				print "SKILL DESC - Show skill description.\n",
					"Syntax:\n",
					"    skill desc <skill number>\n\n",
					"Options:\n",
					"    <skill number> - Skill number. Type 'skill' to get number.\n\n";
			}
		} elsif ($params[1] eq "m") {
			if (IsNumber($params[2]) && IsNumber($params[3])) {
				if ($skillsID[$params[2]] eq "") {
					print	"SKILL M - Skill $params[2] does not exist.\n";
				} elsif ($monstersID[$params[3]] eq "") {
					print	"SKILL M - Monster $params[3] does not exist.\n";
				} else {
					if ($params[4] <= 0 || $params[4] > $chars[$config{'char'}]{'skills'}{$skillsID[$params[2]]}{'lv'}) {
						$params[4] = $chars[$config{'char'}]{'skills'}{$skillsID[$params[2]]}{'lv'};
					}

					if ($chars[$config{'char'}]{'skills'}{$skillsID[$params[2]]}{'use'} == 2) {
						ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$params[2]]}{'ID'}, $params[4], 0, 0, 0, $monsters{$monstersID[$params[3]]}{'pos_to'}{'x'}, $monsters{$monstersID[$params[3]]}{'pos_to'}{'y'});
					} else {
						ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$params[2]]}{'ID'}, $params[4], 0, 0, 0, $monstersID[$params[3]]);
					}
				}
			} else {
				print "SKILL M - Use skill on monster.\n",
					"Syntax:\n",
					"    skill m <skill number> <monster number> [<skill level>]\n\n",
					"Options:\n",
					"    <skill number>   - Skill number. Type 'skill' to get number.\n",
					"    <monster number> - Monster number. Type 'm' to get number.\n",
					"    <skill level>    - Skill level.\n\n";
			}
		} elsif ($params[1] eq "p") {
			if (IsNumber($params[2]) && IsNumber($params[3])) {
				if ($skillsID[$params[2]] eq "") {
					print	"SKILL P - Skill $params[2] does not exist.\n";
				} elsif ($playersID[$params[3]] eq "") {
					print	"SKILL P - Player $params[3] does not exist.\n";
				} else {
					if ($params[4] <= 0 || $params[4] > $chars[$config{'char'}]{'skills'}{$skillsID[$params[2]]}{'lv'}) {
						$params[4] = $chars[$config{'char'}]{'skills'}{$skillsID[$params[2]]}{'lv'};
					}

					if ($chars[$config{'char'}]{'skills'}{$skillsID[$params[2]]}{'use'} == 2) {
						ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$params[2]]}{'ID'}, $params[4], 0, 0, 0, $players{$playersID[$params[3]]}{'pos_to'}{'x'}, $players{$playersID[$params[3]]}{'pos_to'}{'y'});
					} else {
						ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$params[2]]}{'ID'}, $params[4], 0, 0, 0, $playersID[$params[3]]);
					}
				}
			} else {
				print "SKILL P - Use skill on monster.\n",
					"Syntax:\n",
					"    skill p <skill number> <player number> [<skill level>]\n\n",
					"Options:\n",
					"    <skill number>   - Skill number. Type 'skill' to get number.\n",
					"    <player number> - Player number. Type 'p' to get number.\n",
					"    <skill level>    - Skill level.\n\n";
			}
		} elsif ($params[1] eq "s") {
			if (IsNumber($params[2])) {
				if ($skillsID[$params[2]] eq "") {
					print	"SKILL S - Skill $params[2] does not exist.\n";
				} else {
					if ($params[3] <= 0 || $params[3] > $chars[$config{'char'}]{'skills'}{$skillsID[$params[2]]}{'lv'}) {
						$params[3] = $chars[$config{'char'}]{'skills'}{$skillsID[$params[2]]}{'lv'};
					}

					if ($chars[$config{'char'}]{'skills'}{$skillsID[$params[2]]}{'use'} == 2) {
						ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$params[2]]}{'ID'}, $params[3], 0, 0, 0, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
					} else {
						ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$params[2]]}{'ID'}, $params[3], 0, 0, 0, $accountID);
					}
				}
			} else {
				print "SKILL S - Use skill on self.\n",
					"Syntax:\n",
					"    skill s <skill number> [<skill level>]\n\n",
					"Options:\n",
					"    <skill number> - Skill number. Type 'skill' to get number.\n",
					"    <skill level>  - Skill level.\n\n";
			}
		}
	} elsif ($cmd eq "st") {
		$params[1] = lc($params[1]);

		if ($params[1] eq "") {
			$percent_base = sprintf("%.2f", $chars[$config{'char'}]{'exp'} * 100 / $chars[$config{'char'}]{'exp_max'});
			$percent_job = sprintf("%.2f", $chars[$config{'char'}]{'exp_job'} * 100 / $chars[$config{'char'}]{'exp_job_max'});
			$percent_weight = sprintf("%.2f", $chars[$config{'char'}]{'weight'} * 100 / $chars[$config{'char'}]{'weight_max'});

			$msg = <<STAT;
- STATUS -------------------------------
HP: $chars[$config{'char'}]{'hp'} / $chars[$config{'char'}]{'hp_max'}  SP: $chars[$config{'char'}]{'sp'} / $chars[$config{'char'}]{'sp_max'}
Base: $chars[$config{'char'}]{'lv'}  |  $chars[$config{'char'}]{'exp'} / $chars[$config{'char'}]{'exp_max'}  ($percent_base %)
Job: $chars[$config{'char'}]{'lv_job'}  |  $chars[$config{'char'}]{'exp_job'} / $chars[$config{'char'}]{'exp_job_max'}  ($percent_job %)
Weight: $chars[$config{'char'}]{'weight'} / $chars[$config{'char'}]{'weight_max'}  ($percent_weight %)  |  $chars[$config{'char'}]{'zenny'}z

STR: $chars[$config{'char'}]{'str'} + $chars[$config{'char'}]{'str_bonus'}  |  $chars[$config{'char'}]{'points_str'}
AGI: $chars[$config{'char'}]{'agi'} + $chars[$config{'char'}]{'agi_bonus'}  |  $chars[$config{'char'}]{'points_agi'}
VIT: $chars[$config{'char'}]{'vit'} + $chars[$config{'char'}]{'vit_bonus'}  |  $chars[$config{'char'}]{'points_vit'}
INT: $chars[$config{'char'}]{'int'} + $chars[$config{'char'}]{'int_bonus'}  |  $chars[$config{'char'}]{'points_int'}
DEX: $chars[$config{'char'}]{'dex'} + $chars[$config{'char'}]{'dex_bonus'}  |  $chars[$config{'char'}]{'points_dex'}
LUK: $chars[$config{'char'}]{'luk'} + $chars[$config{'char'}]{'luk_bonus'}  |  $chars[$config{'char'}]{'points_luk'}

ATK: $chars[$config{'char'}]{'attack'} + $chars[$config{'char'}]{'attack_bonus'}  DEF: $chars[$config{'char'}]{'def'} + $chars[$config{'char'}]{'def_bonus'}
MATK: $chars[$config{'char'}]{'attack_magic_min'} ~ $chars[$config{'char'}]{'attack_magic_max'}  MDEF: $chars[$config{'char'}]{'def_magic'} + $chars[$config{'char'}]{'def_magic_bonus'}
HIT: $chars[$config{'char'}]{'hit'}  FLEE: $chars[$config{'char'}]{'flee'} + $chars[$config{'char'}]{'flee_bonus'}
CRI: $chars[$config{'char'}]{'critical'}  ASPD: $chars[$config{'char'}]{'attack_speed'}
STATUS POINT: $chars[$config{'char'}]{'points_free'}
GUILD: $chars[$config{'char'}]{'guild'}{'name'}
----------------------------------------
STAT
			print $msg;
		} elsif ($params[1] eq "add") {
			$params[2] = lc($params[2]);

			if ($params[2] eq "str") {
				$ID = 0x0D;
			} elsif ($params[2] eq "agi") {
				$ID = 0x0E;
			} elsif ($params[2] eq "vit") {
				$ID = 0x0F;
			} elsif ($params[2] eq "int") {
				$ID = 0x10;
			} elsif ($params[2] eq "dex") {
				$ID = 0x11;
			} elsif ($params[2] eq "luk") {
				$ID = 0x12;
			} else {
				$params[2] = '';
			}

			if ($params[2] ne "") {
				if ($chars[$config{'char'}]{"points_$params[2]"} > $chars[$config{'char'}]{'points_free'}) {
					print "ST ADD - Not enough status points to increase $params[2].\n";
				} else {
					$chars[$config{'char'}]{$params[2]} += 1;
					sendAddStatusPoint(\$remote_socket, $ID);
				}
			} else {
				print "ST ADD - Add status point.\n",
					"Syntax:\n",
					"    st add <str | agi | vit | int | dex | luk>\n\n";
			}
		}
	} elsif ($cmd eq "stand") {
		if ($ai_v{'attackAuto_old'} ne "") {
			configModify("attackAuto", $ai_v{'attackAuto_old'});
			configModify("route_randomWalk", $ai_v{'route_randomWalk_old'});
			undef $ai_v{'attackAuto_old'};
			undef $ai_v{'route_randomWalk_old'};
		}

		stand();
		$ai_v{'sitAuto_forceStop'} = 1;
	} elsif ($cmd eq "store") {
		$params[1] = lc($params[1]);

		if ($talk{'buyOrSell'}) {
			print "STORE - No store list. Sending query...\n";
			sendGetStoreList(\$remote_socket, $talk{'ID'});
		} elsif ($params[1] eq "") {
			if (@storeList) {
				print "- STORE LIST ---------------------------\n",
					"#  Name                    Type           Price\n";
				for ($i=0; $i < @storeList;$i++) {
					PrintFormat(<<'STORELIST', $i, $storeList[$i]{'name'}, $itemTypes_lut{$storeList[$i]{'type'}}, $storeList[$i]{'price'});
@< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<< @>>>>>>>
STORELIST
				}
				print "----------------------------------------\n";
			} else {
				print "STORE - There are no item(s) in store.\n";
			}
		} elsif ($params[1] eq "buy") {
			if (!@storeList) {
				print "STORE BUY - There are no item(s) in store.\n";
			} elsif (IsNumber($params[2])) {
				if ($storeList[$params[2]] ne "") {
					if ($params[3] <= 0) {
						$params[3] = 1;
					}
					sendBuy(\$remote_socket, $storeList[$params[2]]{'nameID'}, $params[3]);
				} else {
					print	"STORE BUY - Store Item $params[2] does not exist.\n";
				}
			} else {
				print "STORE BUY - Buy store item.\n",
					"Syntax:\n",
					"    store buy <item number> [<amount>]\n\n",
					"Options:\n",
					"    <item number> - Store item number. Type 'store' to get number.\n",
					"    <amount>      - Store item amount.\n\n";
			}
		} elsif ($params[1] eq "buyany") {
			if (!@storeList) {
				print "STORE BUYANY - There are no item(s) in store.\n";
			} elsif (IsNumber($params[2])) {
				if ($params[3] <= 0) {
					$params[3] = 1;
				}

				sendBuy(\$remote_socket, $params[2], $params[3]);
			} else {
				print "STORE BUYANY - Buy any item.\n",
					"Syntax:\n",
					"    store buy <item id> [<amount>]\n\n",
					"Options:\n",
					"    <item id> - Item ID.\n",
					"    <amount>  - Item amount.\n\n";
			}
		} elsif ($params[1] eq "desc") {
			if (!@storeList) {
				print "STORE DESC - There are no item(s) in store.\n";
			} elsif (IsNumber($params[2])) {
				if ($storeList[$params[2]] ne "") {
					ShowWrapperInventory($storeList[$params[2]]{'nameID'});
					if (!$config{'wrapperInterface'}) {
						printItemDesc($storeList[$params[2]]{'nameID'});
					}
				} else {
					print	"STORE DESC - Store Item $params[2] does not exist.\n";
				}
			} else {
				print "STORE DESC - Store item description.\n",
					"Syntax:\n",
					"    store desc <item number>\n\n",
					"Options:\n",
					"    <item number> - Store Item number. Type 'store' to get number.\n\n";
			}
		}
	} elsif ($cmd eq "storage") {
		$params[1] = lc($params[1]);

		if (!$storage{'open'}) {
			print "STORAGE - Storage not open.\n";
		} elsif ($params[1] eq "") {
			if ($storage{'items'} > 0) {
				print "- STORAGE LIST -------------------------\n",
					"#  Name\n";
				for ($i = 0; $i < @{$storage{'inventory'}}; $i++) {
					next if (!%{$storage{'inventory'}[$i]});
					PrintFormat(<<'STORAGELIST', $i, GenShowName($storage{'inventory'}[$i])." x $storage{'inventory'}[$i]{'amount'}");
@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
STORAGELIST
				}
				print "\nCapacity: $storage{'items'}/$storage{'items_max'}\n";
				print "----------------------------------------\n";
			} else {
				print "STORAGE - There are no item(s) in storage.\n";
			}
		} elsif ($params[1] eq "add") {
			if (IsNumber($params[2])) {
				if (%{$chars[$config{'char'}]{'inventory'}[$params[2]]}) {
					if ($params[3] <= 0 || $params[3] > $chars[$config{'char'}]{'inventory'}[$params[2]]{'amount'}) {
						$params[3] = $chars[$config{'char'}]{'inventory'}[$params[2]]{'amount'};
					}

					sendStorageAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$params[2]]{'index'}, $params[3]);
				} else {
					print	"STORAGE ADD - Item $params[2] does not exist.\n";
				}
			} else {
				print "STORAGE ADD - Add item to storage.\n",
					"Syntax:\n",
					"    storage add <item number> [<amount>]\n\n",
					"Options:\n",
					"    <item number> - Inventory number. Type 'i' to get number.\n",
					"    <amount>      - Inventory item amount.\n\n";
			}
		} elsif ($params[1] eq "get") {
			if (IsNumber($params[2])) {
				if (%{$storage{'inventory'}[$params[2]]}) {
					if ($params[3] <= 0 || $params[3] > $storage{'inventory'}[$params[2]]{'amount'}) {
						$params[3] = $storage{'inventory'}[$params[2]]{'amount'};
					}

					sendStorageGet(\$remote_socket, $storage{'inventory'}[$params[2]]{'index'}, $params[3]);
				} else {
					print	"STORAGE GET - Item $params[2] does not exist.\n";
				}
			} else {
				print "STORAGE GET - Get item from storage.\n",
					"Syntax:\n",
					"    storage get <item number> [<amount>]\n\n",
					"Options:\n",
					"    <item number> - Storage number. Type 'storage' to get number.\n",
					"    <amount>      - Storage item amount.\n\n";
			}
		} elsif ($params[1] eq "close") {
			sendStorageClose(\$remote_socket);
		} elsif ($params[1] eq "desc") {
			if (!$storage{'items'}) {
				print "STORAGE DESC - There are no item(s) in storage.\n";
			} elsif (IsNumber($params[2])) {
				if (%{$storage{'inventory'}[$params[2]]}) {
					ShowWrapperInventory($storage{'inventory'}[$params[2]]{'nameID'});
					if (!$config{'wrapperInterface'}) {
						printItemDesc($storage{'inventory'}[$params[2]]{'nameID'});
					}
				} else {
					print	"STORAGE DESC - Storage Item $params[2] does not exist.\n";
				}
			} else {
				print "STORAGE DESC - Storage item description.\n",
					"Syntax:\n",
					"    storage desc <item number>\n\n",
					"Options:\n",
					"    <item number> - Storage Item number. Type 'storage' to get number.\n\n";
			}
		}
	} elsif ($cmd eq "sum") {
		$kore_time = sprintf("%.2f", time - $KoreStartTime);
		$kore_days = int($kore_time / 86400);
		$kore_time = $kore_time % 86400;
		$kore_hours = int($kore_time / 3600);
		$kore_time = $kore_time % 3600;
		$kore_minutes = int($kore_time / 60);
		$kore_time = $kore_time % 60;
		$kore_seconds = $kore_time;

		$kore_abs_hours = $kore_hours + ($kore_minutes / 60) + ($kore_seconds / 3600);

		$exp_per_hour = $chars[$config{'char'}]{'summary'}{'exp_gain'} / $kore_abs_hours;
		$exp_job_per_hour = $chars[$config{'char'}]{'summary'}{'exp_job_gain'} / $kore_abs_hours;

		if ($exp_per_hour) {
			$level_up_estimate = int(($chars[$config{'char'}]{'exp_max'} - $chars[$config{'char'}]{'exp'}) / $exp_per_hour * 3600);
			$level_up_hours = int($level_up_estimate / 3600);
			$level_up_estimate = $level_up_estimate % 3600;
			$level_up_minutes = int($level_up_estimate / 60);
			$level_up_estimate = $level_up_estimate % 60;
			$level_up_seconds = int($level_up_estimate);
		} else {
			$level_up_hours = 0;
			$level_up_minutes = 0;
			$level_up_seconds = 0;
		}

		$level_up_estimate = sprintf("%02d:%02d:%02d", $level_up_hours, $level_up_minutes, $level_up_seconds);

		if ($exp_job_per_hour) {
			$job_level_up_estimate = int(($chars[$config{'char'}]{'exp_max'} - $chars[$config{'char'}]{'exp'}) / $exp_job_per_hour * 3600);
			$job_level_up_hours = int($job_level_up_estimate / 3600);
			$job_level_up_estimate = $job_level_up_estimate % 3600;
			$job_level_up_minutes = int($job_level_up_estimate / 60);
			$job_level_up_estimate = $job_level_up_estimate % 60;
			$job_level_up_seconds = int($job_level_up_estimate);
		} else {
			$job_level_up_hours = 0;
			$job_level_up_minutes = 0;
			$job_level_up_seconds = 0;
		}

		$job_level_up_estimate = sprintf("%02d:%02d:%02d", $job_level_up_hours, $job_level_up_minutes, $job_level_up_seconds);

		$zeny_gain = $chars[$config{'char'}]{'zenny'} - $chars[$config{'char'}]{'summary'}{'zeny'};

		print "- SUMMARY ------------------------------\n";

		print "Time since kore start:\n";
		if ($kore_days > 0) {
			print "    $kore_days days, $kore_hours hours, $kore_minutes minutes and $kore_seconds seconds\n";
		} elsif ($kore_hours > 0) {
			print "    $kore_hours hours, $kore_minutes minutes and $kore_seconds seconds\n";
		} elsif ($kore_minutes > 0) {
			print "    $kore_minutes minutes and $kore_seconds seconds\n";
		} else {
			print "    $kore_seconds seconds\n";
		}

		PrintFormat(<<'SUM', $chars[$config{'char'}]{'exp'}." / ".$chars[$config{'char'}]{'exp_max'}, $chars[$config{'char'}]{'summary'}{'exp_gain'}, $exp_per_hour, $level_up_estimate, $chars[$config{'char'}]{'exp_job'}." / ".$chars[$config{'char'}]{'exp_job_max'}, $chars[$config{'char'}]{'summary'}{'exp_job_gain'}, $exp_job_per_hour, $job_level_up_estimate, $zeny_gain);

EXP: @<<<<<<<<<<<<<<<<<<<
EXP gain: @<<<<<<<<<
EXP / Hour: @<<<<<<<<<
Level up estimate time: @<<<<<<<<<

Job EXP: @<<<<<<<<<<<<<<<<<<<
Job EXP gain: @<<<<<<<<<
Job EXP / Hour: @<<<<<<<<<
Job level up estimate time: @<<<<<<<<<

Zeny Gain: @<<<<<<<<<
SUM

		print "\n- MONSTERS -----------------------------\n";

		foreach (keys %{$chars[$config{'char'}]{'summary'}{'monsters'}}) {
			$map = $_;
			print	"\n$map\n";
			foreach (keys %{$chars[$config{'char'}]{'summary'}{'monsters'}{$map}}) {
				$mon_time = sprintf("%.2f", $chars[$config{'char'}]{'summary'}{'monsters'}{$map}{$_}{'time'});
				print	"    $_ = $chars[$config{'char'}]{'summary'}{'monsters'}{$map}{$_}{'count'}, $mon_time seconds, damage $chars[$config{'char'}]{'summary'}{'monsters'}{$map}{$_}{'min_damage'} ~ $chars[$config{'char'}]{'summary'}{'monsters'}{$map}{$_}{'max_damage'}\n";
			}
		}

		print "\n- RARE ITEMS ---------------------------\n";

		foreach (keys %{$chars[$config{'char'}]{'summary'}{'rare'}}) {
			$map = $_;
			print	"\n$map\n";
			foreach (keys %{$chars[$config{'char'}]{'summary'}{'rare'}{$map}}) {
				print	"    $_ = $chars[$config{'char'}]{'summary'}{'rare'}{$map}{$_}{'count'}\n";
			}
		}

		print "\n----------------------------------------\n";
	} elsif ($cmd eq "tank") {
		if (IsNumber($inputparam)) {
			if ($playersID[$inputparam] ne "") {
				configModify("tankMode", 1);
				configModify("tankModeTarget", $players{$playersID[$inputparam]}{'name'});
			} else {
				print "TANK - Tank player.\n",
					"Syntax:\n",
					"    tank <player number>\n\n",
					"Options:\n",
					"    <player number> - Player number. Type 'p' to get number.\n\n";
			}
		} elsif ($inputparam eq "stop") {
			configModify("tankMode", 0);
		} else {
			configModify("tankMode", 1);
			configModify("tankModeTarget", $inputparam);
		}
	} elsif ($cmd eq "tele" || $cmd eq "teleport") {
		useTeleport(1);
	} elsif ($cmd eq "timeout") {
		if ($params[1] ne "" && ($params[2] eq "" || IsNumber($params[2]))) {
			if ($timeout{$params[1]} eq "") {
				print "TIMEOUT - Timeout $params[1] doesn't exist.\n";
			} elsif (IsNumber($params[2])) {
				setTimeout($params[1], $params[2]);
			} else {
				print "TIMEOUT - Timeout $params[1] is $timeout{$params[1]}{'timeout'}.\n";
			}
		} else {
			print "TIMEOUT - Timeout setting.\n",
				"Syntax:\n",
				"    timeout <type> [<seconds>]\n\n",
				"Options:\n",
				"    <type>    - Type of timeout from timeouts.txt.\n",
				"    <seconds> - Time in second.\n\n";
		}
	} elsif ($cmd eq "town") {
		if ($chars[$config{'char'}]{'dead'}) {
			sendRespawn(\$remote_socket);
		} else {
			useTeleport(2);
		}
	} elsif ($cmd eq "v") {
		$params[1] = lc($params[1]);

		if ($params[1] eq "") {
			if (@venderListsID) {
				my $name;

				print "- VENDER SHOP LIST ---------------------\n",
					"#   Title                                Owner\n";
				for ($i = 0; $i < @venderListsID; $i++) {
					next if ($venderListsID[$i] eq "");
					$name = ($venderListsID[$i] ne $accountID) ? $players{$venderListsID[$i]}{'name'} : $chars[$config{'char'}]{'name'};
					PrintFormat(<<'VLIST', $i, $venderLists{$venderListsID[$i]}{'title'}, $name);
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<
VLIST
				}
				print "----------------------------------------\n";
			} else {
				print "V - There are no vendor(s) around here.\n";
			}
		} elsif ($params[1] eq "view") {
			if (!@venderListsID) {
				print "V VIEW - There are no vendor(s) around here.\n";
			} elsif ($params[2] eq "") {
				if ($lastVenderID ne "") {
					my $display;
					my $iden;

					print "- VENDER STORE LIST --------------------\n",
						"#  Name                                         Type           Amount Price\n";

					for ($i = 0; $i < @{$vender{'inventory'}}; $i++) {
						next if (!%{$vender{'inventory'}[$i]} eq "");

						$display = GenShowName($vender{'inventory'}[$i]);

						if (!($vender{'inventory'}[$i]{'identified'})) {
							$iden = "*";
						} else {
							$iden = "";
						}

						PrintFormat(<<'VSTORELIST', $i, $iden, $display, $itemTypes_lut{$vender{'inventory'}[$i]{'type'}}, $vender{'inventory'}[$i]{'amount'}, $vender{'inventory'}[$i]{'price'});
@< @@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<< @>>>>> @>>>>>>>z
VSTORELIST
					}
					print "----------------------------------------\n";
				} else {
					print	"V VIEW - Last vender does not exist.\n";
				}
			} elsif (IsNumber($params[2])) {
				if ($venderListsID[$params[2]] ne "") {
					sendVenderItemsList(\$remote_socket, $venderListsID[$params[2]]);
				} else {
					print	"V VIEW - Vender $params[2] does not exist.\n";
				}
			} else {
				print "V VIEW - View item(s) in vender shop.\n",
					"Syntax:\n",
					"    v view <vender number>\n\n",
					"Options:\n",
					"    <vender number> - Vender number. Type 'v' to get number.\n\n";
			}
		} elsif ($lastVenderID eq "") {
			print "V - You don't view vender shop.\n";
		} elsif ($params[1] eq "buy") {
			if (IsNumber($params[2]) && IsNumber($params[3])) {
				if (!%{$vender{'inventory'}[$params[2]]}) {
					print	"V BUY - Item $params[2] does not exist.\n";
				} else {
					if ($params[3] <= 0 || $params[3] > $vender{'inventory'}[$params[2]]{'amount'}) {
						$params[3] = 1;
					}

					sendVenderBuy(\$remote_socket, $lastVenderID, $params[2], $params[3]);
				}
			} else {
				print "V BUY - Buy item from vender.\n",
					"Syntax:\n",
					"    v buy <item number> [<amount>]\n\n",
					"Options:\n",
					"    <item number>   - Vender item number. Type 'v view' to get number.\n",
					"    <amount>        - Item amount.\n\n";
			}
		} elsif ($params[1] eq "desc") {
			if (IsNumber($params[2])) {
				if (!%{$vender{'inventory'}[$params[2]]}) {
					print	"V DESC - Item $params[2] does not exist.\n";
				} else {
					ShowWrapperInventory($vender{'inventory'}[$params[2]]{'nameID'});
					if (!$config{'wrapperInterface'}) {
						printItemDesc($vender{'inventory'}[$params[2]]{'nameID'});
					}
				}
			} else {
				print "V DESC - Vender item description.\n",
					"Syntax:\n",
					"    v desc <item number>\n\n",
					"Options:\n",
					"    <item number> - Vender item number. Type 'v view' to get number.\n\n";
			}
		}
	} elsif ($cmd eq "warp") {
		$params[1] = lc($params[1]);

		if ($chars[$config{'char'}]{'skills'}{'AL_WARP'}{'lv'} > 0 || $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} > 0) {
			if ($params[1] eq "") {
				if ($warp{'use'}) {
					print "- WARP PORTAL --------------------------\n";
					print "#  Place                           Map\n";
					for ($i = 0; $i < @{$warp{'memo'}}; $i++) {
						PrintFormat(<<'MEMOS', $i, $maps_lut{$warp{'memo'}[$i].'.rsw'}, $warp{'memo'}[$i]);
@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<
MEMOS
					}
					print "----------------------------------------\n";
				} else {
					print	"WARP - Use warp skill to get list.\n";
				}
			} elsif ($params[1] eq "me") {
				ai_skillUse(27, $chars[$config{'char'}]{'skills'}{'AL_WARP'}{'lv'}, 2, 0, 0, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
			} elsif ($params[1] eq "at" && IsNumber($params[2]) && IsNumber($params[3])) {
				ai_skillUse(27, $chars[$config{'char'}]{'skills'}{'AL_WARP'}{'lv'}, 2, 0, 0, $params[2], $params[3]);
			} elsif ($params[1] eq "no") {
				$warp{'use'} = 0;
			} elsif ($warp{'use'} && IsNumber($params[1])) {
				if ($warp{'memo'}[$params[1]] eq "") {
					print	"WARP - Memo $params[1] does not exist.\n";
				} elsif ($warp{'use'} == 0x1A) {
					print	"WARP - Teleport to $maps_lut{$warp{'memo'}[$params[1]].'.rsw'} ($warp{'memo'}[$params[1]]).\n";
					sendTeleport(\$remote_socket, $warp{'memo'}[$params[1]].".gat");
				} elsif ($warp{'use'} == 0x1B) {
					print	"WARP - Warp Portal to $maps_lut{$warp{'memo'}[$params[1]].'.rsw'} ($warp{'memo'}[$params[1]]).\n";
					sendWarpPortal(\$remote_socket, $warp{'memo'}[$params[1]].".gat");
				}
			} else {
				print "WARP - Warp command.\n",
					"Syntax:\n",
					"    warp\n",
					"    warp me\n",
					"    warp at <x> <y>\n",
					"    warp no\n",
					"    warp <memo number>\n\n";
			}
		} else {
			print	"WARP - You don't have a warp skill.\n";
		}
	} elsif ($cmd eq "whois") {
		$params[1] = lc($params[1]);

		if (IsNumber($params[1])) {
			$whois{'ID'} = pack("L1", $params[1]);
			$whois{'request'} = 1;

			sendCharacterNameRequest(\$remote_socket, $whois{'ID'});
		} else {
			print "WHOIS - Get the name of character.\n",
				"Syntax:\n",
				"    whois <character id>\n\n",
				"Options:\n",
				"    <character id> - Any character ID.\n\n";
		}
	} elsif ($cmd eq "where") {
		print "Location $maps_lut{$field{'name'}.'.rsw'}($field{'name'}) : $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'}\n";
	} elsif ($cmd eq "wrapper") {
		$params[1] = lc($params[1]);

		if ($params[1] eq "popup") {
			if ($params[2] eq "0" || $params[2] eq "1") {
				configModify('wrapperPopup', $params[2]);
			} elsif ($params[2] eq "toggle") {
				if ($config{'wrapperPopup'}) {
					configModify('wrapperPopup', 0);
				} else {
					configModify('wrapperPopup', 1);
				}
			} else {
				print "WRAPPER POPUP - Toggle wrapper popup.\n",
					"Syntax:\n",
					"    wrapper popup <flag>\n",
					"Options:\n",
					"    <flag> - 0 no popup, 1 popup\n\n";
			}
		} else {
			print "WRAPPER - Wrapper command.\n",
				"Syntax:\n",
				"    wrapper popup <flag>\n\n";
		}
	} elsif ($cmd eq "shopping") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? [\s\S]*? [\s\S]*? (\d+)/;

		if ($arg1 eq "") {
			print "\nSHOPPING - Shopping all items from around venders.\n",
				"Usage:\n",
				"    shopping <list>                  - List any items.\n",
				"    shopping <save>                  - Save the items list to file.\n",
				"    shopping <buy> <number> <amount> - Buy the lowest price item(s)\n";
		} elsif ($arg1 eq "list") {
			undef $chars[$config{'char'}]{'shoppingLastID'};
			undef @vender_keys;
			undef %vender_players;
			undef %vender_items;

			for ($i = 0; $i < @venderListsID; $i++) {
				next if ($venderListsID[$i] eq "");
				sendVenderItemsList(\$remote_socket, $venderListsID[$i]);
				$chars[$config{'char'}]{'shoppingLastID'} = $venderListsID[$i];
			}

			$chars[$config{'char'}]{'shopping'} = 1;
		} elsif ($arg1 eq "save") {
			open FILE, "> $profile/shopping.txt";

			for ($i = 0; $i < @{vender_keys}; $i++) {
				$key = $vender_keys[$i];
				$name = "$players{$vender_items{$key}{'ID'}}{'name'} [".getHex($vender_items{$key}{'ID'})."]";
				print FILE "$i $key $vender_items{$key}{'amount'} $vender_items{$key}{'minPrice'} $vender_items{$key}{'maxPrice'} $name\n";
			}

			close FILE;

			print "Save $profile/shopping.txt\n"
		} elsif ($arg1 eq "buy" && $arg2 =~ /\d+/) {
			my @key_sort = sort { $a cmp $b } keys %vender_items;
			if ($arg2 < @{key_sort}) {
				$key = $key_sort[$arg2];

				if ($arg3 <= 0) {
					$arg3 = $vender_items{$key}{'amount'};
				}

				print "Buy $key x $arg3 from ".Name($vender_items{$key}{'ID'})."\n";
				sendVenderBuy(\$remote_socket, $vender_items{$key}{'ID'}, $vender_items{$key}{'index'}, $arg3);
			}
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

	$ai_seq_begin = $ai_seq[0];

	if ($ai_seq[0] eq "") {
		UpdateWrapperAiBegin('-');
	} else {
		UpdateWrapperAiBegin($ai_seq[0]);
	}

	if (!$chars[$config{'char'}]{'summary'}{'record'}) {
		if ($chars[$config{'char'}]{'exp'} > 0 && $chars[$config{'char'}]{'zenny'} > 0) {
			$chars[$config{'char'}]{'summary'}{'record'} = 1;
			$chars[$config{'char'}]{'summary'}{'exp_last'} = $chars[$config{'char'}]{'exp'};
			$chars[$config{'char'}]{'summary'}{'exp_max_last'} = $chars[$config{'char'}]{'exp_max'};
			$chars[$config{'char'}]{'summary'}{'exp_gain'} = 0;
			$chars[$config{'char'}]{'summary'}{'exp_job_last'} = $chars[$config{'char'}]{'exp_job'};
			$chars[$config{'char'}]{'summary'}{'exp_job_max_last'} = $chars[$config{'char'}]{'exp_job_max'};
			$chars[$config{'char'}]{'summary'}{'exp_job_gain'} = 0;
			$chars[$config{'char'}]{'summary'}{'zeny'} = $chars[$config{'char'}]{'zenny'};
		}
	} else {
		if ($chars[$config{'char'}]{'summary'}{'exp_max_last'} != $chars[$config{'char'}]{'exp_max'}) {
			$chars[$config{'char'}]{'summary'}{'exp_gain'} += ($chars[$config{'char'}]{'summary'}{'exp_max_last'} - $chars[$config{'char'}]{'summary'}{'exp_last'});
			$chars[$config{'char'}]{'summary'}{'exp_gain'} += $chars[$config{'char'}]{'exp'};
		} elsif ($chars[$config{'char'}]{'summary'}{'exp_last'} != $chars[$config{'char'}]{'exp'}) {
			$chars[$config{'char'}]{'summary'}{'exp_gain'} += ($chars[$config{'char'}]{'exp'} - $chars[$config{'char'}]{'summary'}{'exp_last'});
		}

		if ($chars[$config{'char'}]{'summary'}{'exp_job_max_last'} != $chars[$config{'char'}]{'exp_job_max'}) {
			$chars[$config{'char'}]{'summary'}{'exp_job_gain'} += ($chars[$config{'char'}]{'summary'}{'exp_job_max_last'} - $chars[$config{'char'}]{'summary'}{'exp_job_last'});
			$chars[$config{'char'}]{'summary'}{'exp_job_gain'} += $chars[$config{'char'}]{'exp_job'};
		} elsif ($chars[$config{'char'}]{'summary'}{'exp_job_last'} != $chars[$config{'char'}]{'exp_job'}) {
			$chars[$config{'char'}]{'summary'}{'exp_job_gain'} += ($chars[$config{'char'}]{'exp_job'} - $chars[$config{'char'}]{'summary'}{'exp_job_last'});
		}

		$chars[$config{'char'}]{'summary'}{'exp_last'} = $chars[$config{'char'}]{'exp'};
		$chars[$config{'char'}]{'summary'}{'exp_max_last'} = $chars[$config{'char'}]{'exp_max'};
		$chars[$config{'char'}]{'summary'}{'exp_job_last'} = $chars[$config{'char'}]{'exp_job'};
		$chars[$config{'char'}]{'summary'}{'exp_job_max_last'} = $chars[$config{'char'}]{'exp_job_max'};
	}
	#print "BEGIN: $ai_seq[0]\n" if ($ai_seq[0] ne "");

	if (!$accountID) {
		$AI = 0;
		injectAdminMessage("Kore does not have enough account information, so AI has been disabled. Relog to enable AI.");
		return;
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
		DebugMessage("- Wiped old.") if ($debug{'wipe'});
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

	if ($config{'remoteSocket'} && timeOut(\%{$timeout{'ai_sync'}})) {
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
		HideWrapperYesNo();
		$timeout{'ai_partyAutoDeny'}{'time'} = time;
		undef %incomingParty;
	}

	if ($config{'guildAutoDeny'} && %incomingGuild && timeOut(\%{$timeout{'ai_guildAutoDeny'}})) {
		sendGuildJoin(\$remote_socket, $incomingGuild{'ID'}, 0);
		HideWrapperYesNo();
		$timeout{'ai_guildAutoDeny'}{'time'} = time;
		undef %incomingGuild;
	}

	if ($config{'partyAutoShare'} && %{$chars[$config{'char'}]{'party'}} && timeOut(\%{$timeout{'ai_partyAutoShare'}})) {
		if ($chars[$config{'char'}]{'party'}{'share'} == 0) {
			sendPartyShareEXP(\$remote_socket, 1);
			$timeout{'ai_partyAutoShare'}{'time'} = time;
		}
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

				updatePortalLUT("tables/portals.txt",
					$ai_v{'portalTrace'}{'source'}{'map'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'x'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'y'},
					$field{'name'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'});

				$ai_v{'temp'}{'ID2'} = "$field{'name'} $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'} $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'}";
				$portals_lut{$ai_v{'temp'}{'ID2'}}{'source'}{'map'} = $field{'name'};
				%{$portals_lut{$ai_v{'temp'}{'ID2'}}{'source'}{'pos'}} = %{$portals{$ai_v{'temp'}{'foundID'}}{'pos'}};
				$portals_lut{$ai_v{'temp'}{'ID2'}}{'dest'}{'map'} = $ai_v{'portalTrace'}{'source'}{'map'};
				%{$portals_lut{$ai_v{'temp'}{'ID2'}}{'dest'}{'pos'}} = %{$ai_v{'portalTrace'}{'source'}{'pos'}};

				updatePortalLUT("tables/portals.txt",
					$field{'name'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'},
					$ai_v{'portalTrace'}{'source'}{'map'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'x'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'y'});
			}
			undef %{$ai_v{'portalTrace'}};
		}
	}

	if ($AI && ($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute" || $ai_seq[0] eq "follow" || $ai_seq[0] eq "sitAuto") &&
		($config{'avoidGM_citiesMap'} || !$cities_lut{$field{'name'}.'.rsw'})) {
		foreach (@playersID) {
			next if ($_ eq "");

			($ai_v{'temp'}{'id'}, $ai_v{'temp'}{'name'}, $ai_v{'temp'}{'gm'}) = IsAvoidGM($_);
			if ($ai_v{'temp'}{'id'} ne "") {
				ai_avoidGM($ai_v{'temp'}{'id'}, $ai_v{'temp'}{'name'}, $ai_v{'temp'}{'gm'});
				last;
			}
		}
	}

	if ($ai_seq[0] eq "avoidGM" && $ai_seq_args[0]{'suspended'}) {
		undef $ai_seq_args[0]{'suspended'};
	}

	if ($ai_seq[0] eq "avoidGM") {
		foreach (@playersID) {
			next if ($_ eq "");

			($ai_v{'temp'}{'id'}, $ai_v{'temp'}{'name'}, $ai_v{'temp'}{'gm'}) = IsAvoidGM($_);
			last if ($ai_v{'temp'}{'id'} ne "");
		}

		$ai_v{'temp'}{'id_num'} = unpack("L1", $ai_seq_args[0]{'id'});

		if ($config{'avoidGM'} == 1) {
			PrintMessage("Found $ai_seq_args[0]{'name'} ($ai_v{'temp'}{'id_num'}), use random teleport.", "red");
			WriteLog("gm.txt", "Found $ai_seq_args[0]{'name'} ($ai_v{'temp'}{'id_num'}), use random teleport.\n");
			shift @ai_seq;
			shift @ai_seq_args;
			useTeleport(1);
		} elsif ($config{'avoidGM'} == 2) {
			PrintMessage("Found $ai_seq_args[0]{'name'} ($ai_v{'temp'}{'id_num'}), teleport to town.", "red");
			WriteLog("gm.txt", "Found $ai_seq_args[0]{'name'} ($ai_v{'temp'}{'id_num'}), teleport to town.\n");
			shift @ai_seq;
			shift @ai_seq_args;
			useTeleport(2);
		} elsif ($config{'avoidGM'} == 3) {
			shift @ai_seq;
			shift @ai_seq_args;

			if ($config{'avoidGM_reconnect'} > 0) {
				PrintMessage("Found $ai_seq_args[0]{'name'} ($ai_v{'temp'}{'id_num'}), disconnect for $config{'avoidGM_reconnect'} seconds.", "red");
				WriteLog("gm.txt", "Found $ai_seq_args[0]{'name'} ($ai_v{'temp'}{'id_num'}), disconnect for $config{'avoidGM_reconnect'} seconds.\n");
				reconnect($config{'avoidGM_reconnect'});
			} else {
				PrintMessage("Found $ai_seq_args[0]{'name'} ($ai_v{'temp'}{'id_num'}), disconnect then quit.", "red");
				WriteLog("gm.txt", "Found $ai_seq_args[0]{'name'} ($ai_v{'temp'}{'id_num'}), disconnect then quit.\n");
				quit();
			}
		} elsif ($config{'avoidGM'} == 4) {
			undef $ai_v{'temp'}{'do_route'};
			if ($config{'avoidGM_map'} ne "" && $field{'name'} ne $config{'avoidGM_map'}) {
				$ai_v{'temp'}{'do_route'} = 1;
			} elsif ($config{'avoidGM_mapX'} ne "" && $config{'avoidGM_mapY'} ne "") {
				$ai_v{'temp'}{'pos'}{'x'} = $config{'avoidGM_mapX'};
				$ai_v{'temp'}{'pos'}{'y'} = $config{'avoidGM_mapY'};
				$ai_v{'temp'}{'distance'} = distance(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
				if ($ai_v{'temp'}{'distance'} > 14) {
					$ai_v{'temp'}{'do_route'} = 1;
				}
			}

			if ($ai_v{'temp'}{'do_route'}) {
				if ($config{'avoidGM_map'} ne "") {
					$ai_v{'temp'}{'map'} = $config{'avoidGM_map'};
				} else {
					$ai_v{'temp'}{'map'} = $field{'name'};
				}

				if ($config{'avoidGM_mapX'} ne "" && $config{'avoidGM_mapY'} ne "") {
					PrintMessage("Calculating avoidGM route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}.", "dark");
					$ai_v{'temp'}{'x'} = $config{'avoidGM_mapX'};
					$ai_v{'temp'}{'y'} = $config{'avoidGM_mapY'};
				} else {
					PrintMessage("Calculating avoidGM route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}).", "dark");
					undef $ai_v{'temp'}{'x'};
					undef $ai_v{'temp'}{'y'};
				}

				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
			} elsif (!$ai_seq_args[0]{'wait'}) {
				$ai_seq_args[0]{'wait'} = 1;

				PrintMessage("Found $ai_seq_args[0]{'name'} ($ai_v{'temp'}{'id_num'}), make chat room for $config{'avoidGM_chatRoom_wait'} seconds.", "red");
				WriteLog("gm.txt", "Found $ai_seq_args[0]{'name'} ($ai_v{'temp'}{'id_num'}), make chat room for $config{'avoidGM_chatRoom_wait'} seconds.\n");

				sit();
				$ai_v{'sitAuto_forceStop'} = 0;

				$i = 0;
				while ($config{"avoidGM_chatRoom_title_$i"} ne "") {
					$i++;
				}

				undef $ai_v{'temp'}{'title'};
				if ($i) {
					$i = (rand() * 100) % $i;
					$ai_v{'temp'}{'title'} = $config{"avoidGM_chatRoom_title_$i"};
				}

				if ($ai_v{'temp'}{'title'} eq "") {
					$ai_v{'temp'}{'title'} = "KFC";
				}

				$createdChatRoom{'title'} = $ai_v{'temp'}{'title'};
				$createdChatRoom{'ownerID'} = $accountID;
				$createdChatRoom{'limit'} = $config{'avoidGM_chatRoom_limit'};
				$createdChatRoom{'public'} = $config{'avoidGM_chatRoom_public'};
				$createdChatRoom{'num_users'} = 1;
				$createdChatRoom{'users'}{$chars[$config{'char'}]{'name'}} = 2;
				sendChatRoomCreate(\$remote_socket, $ai_v{'temp'}{'title'}, $config{'avoidGM_chatRoom_limit'}, $config{'avoidGM_chatRoom_public'}, $config{'avoidGM_chatRoom_password'});

				$timeout_ex{'avoidGM'}{'time'} = time;
				$timeout_ex{'avoidGM'}{'timeout'} = $config{'avoidGM_chatRoom_wait'};
			} elsif ($currentChatRoom ne "" && timeOut(\%{$timeout_ex{'avoidGM'}})) {
				shift @ai_seq;
				shift @ai_seq_args;

				PrintMessage("$ai_seq_args[0]{'name'} ($ai_v{'temp'}{'id_num'}) was gone, close chat room.", "red");
				WriteLog("gm.txt", "$ai_seq_args[0]{'name'} ($ai_v{'temp'}{'id_num'}) was gone, close chat room.\n");

				sendChatRoomLeave(\$remote_socket);
				ai_setSuspend(0);
				stand();

				$ai_v{'sitAuto_forceStop'} = 1;
			} elsif ($ai_v{'temp'}{'id'} ne "") {
				$timeout_ex{'avoidGM'}{'time'} = time;
				$timeout_ex{'avoidGM'}{'timeout'} = $config{'avoidGM_chatRoom_wait'};
			}
		} elsif ($config{'avoidGM'} == 5) {
			undef $ai_v{'temp'}{'do_route'};
			if ($config{'avoidGM_map'} ne "" && $field{'name'} ne $config{'avoidGM_map'}) {
				$ai_v{'temp'}{'do_route'} = 1;
			} elsif ($config{'avoidGM_mapX'} ne "" && $config{'avoidGM_mapY'} ne "") {
				$ai_v{'temp'}{'pos'}{'x'} = $config{'avoidGM_mapX'};
				$ai_v{'temp'}{'pos'}{'y'} = $config{'avoidGM_mapY'};
				$ai_v{'temp'}{'distance'} = distance(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
				if ($ai_v{'temp'}{'distance'} > 14) {
					$ai_v{'temp'}{'do_route'} = 1;
				}
			}

			if ($ai_v{'temp'}{'do_route'}) {
				if ($config{'avoidGM_map'} ne "") {
					$ai_v{'temp'}{'map'} = $config{'avoidGM_map'};
				} else {
					$ai_v{'temp'}{'map'} = $field{'name'};
				}

				if ($config{'avoidGM_mapX'} ne "" && $config{'avoidGM_mapY'} ne "") {
					PrintMessage("Calculating avoidGM route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}.", "dark");
					$ai_v{'temp'}{'x'} = $config{'avoidGM_mapX'};
					$ai_v{'temp'}{'y'} = $config{'avoidGM_mapY'};
				} else {
					PrintMessage("Calculating avoidGM route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}).", "dark");
					undef $ai_v{'temp'}{'x'};
					undef $ai_v{'temp'}{'y'};
				}

				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				shift @ai_seq;
				shift @ai_seq_args;

				if ($config{'avoidGM_reconnect'} > 0) {
					PrintMessage("Found $ai_seq_args[0]{'name'} ($ai_v{'temp'}{'id_num'}), disconnect for $config{'avoidGM_reconnect'} seconds.", "red");
					WriteLog("gm.txt", "Found $ai_seq_args[0]{'name'} ($ai_v{'temp'}{'id_num'}), disconnect for $config{'avoidGM_reconnect'} seconds.\n");
					reconnect($config{'avoidGM_reconnect'});
				} else {
					PrintMessage("Found $ai_seq_args[0]{'name'} ($ai_v{'temp'}{'id_num'}), disconnect then quit.", "red");
					WriteLog("gm.txt", "Found $ai_seq_args[0]{'name'} ($ai_v{'temp'}{'id_num'}), disconnect then quit.\n");
					quit();
				}
			}
		}
	}

	Debug('AI avoidGM');


	if (!$AI && (
		$ai_seq[0] eq "avoidGM" ||
		$ai_seq[0] eq "healAuto" ||
		$ai_seq[0] eq "storageAuto" ||
		$ai_seq[0] eq "sellAuto" ||
		$ai_seq[0] eq "buyAuto" ||
		$ai_seq[0] eq "stockAuto" ||
		$ai_seq[0] eq "shopAuto" ||
		$ai_seq[0] eq "follow" ||
		$ai_seq[0] eq "sitAuto" ||
		$ai_seq[0] eq "respAuto"
		)) {
		shift @ai_seq;
		shift @ai_seq_args;
	}

	if (!$AI && $ai_seq[0] eq "") {
		return;
	}

	##### CLIENT SUSPEND #####

	if ($ai_seq[0] eq "clientSuspend" && timeOut(\%{$ai_seq_args[0]})) {
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "clientSuspend") {
		if ($ai_seq_args[0]{'type'} eq "0089") {
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
		} elsif ($switch eq "009F") {
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

	Debug('AI clientSuspend');


	#####AUTO HEAL#####

	AUTOHEAL: {

	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "sitAuto") && $config{'healAuto'} && $config{'healAuto_npc'} ne "" && percent_hp(\%{$chars[$config{'char'}]}) <= $config{'healAuto_hp'} && percent_sp(\%{$chars[$config{'char'}]}) <= $config{'healAuto_sp'}) {
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");

		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}

		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1)) {
			unshift @ai_seq, "healAuto";
			unshift @ai_seq_args, {};
		}
	}

	if ($ai_seq[0] eq "healAuto" && $ai_seq_args[0]{'done'}) {
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;

		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'storageAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'healAuto'} = 1;
			unshift @ai_seq, "storageAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
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
			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{'healAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			if ($ai_v{'temp'}{'distance'} > 14) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}

		if ($ai_v{'temp'}{'do_route'}) {
			if ($ai_seq_args[0]{'warpedToSave'} && !$ai_seq_args[0]{'mapChanged'}) {
				undef $ai_seq_args[0]{'warpedToSave'};
			}
			if (IsWarpAble() && $config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'}) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				$timeout{'ai_healAuto'}{'time'} = time;
			} else {
				PrintMessage("Calculating auto-heal route to: $maps_lut{$npcs_lut{$config{'healAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'healAuto_npc'}}{'map'}): $npcs_lut{$config{'healAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'healAuto_npc'}}{'pos'}{'y'}.", "dark");
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
		}
	}

	} #END OF BLOCK AUTOHEAL

	Debug('AI healAuto');


	#####AUTO STORAGE#####

	AUTOSTORAGE: {

	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route") && $config{'storageAuto'} && $config{'storageAuto_npc'} ne "" && $npcs_lut{$config{'storageAuto_npc'}}{'map'} ne "" && timeOut(\%{$timeout{'ai_storageAuto_wait_get_cart'}}) && timeOut(\%{$timeout{'ai_buyAuto_wait_get_cart'}}) ) {
		undef $ai_v{'temp'}{'found'};
		$i = 0;
		while ($config{"storageAutoGet_$i"} ne "") {
			$ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $config{"storageAutoGet_$i"});
			$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"storageAutoGet_$i"});
			if ($config{"storageAutoGet_$i"."_maxAmount"} > 0 && ($ai_v{'temp'}{'invIndex'} eq "" ||
				($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} <= $config{"storageAutoGet_$i"."_minAmount"} &&
				$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $config{"storageAutoGet_$i"."_maxAmount"}))) {

				# Get items from cart
				if ($ai_v{'temp'}{'cartIndex'} eq "" ||
					($cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} <= $config{"storageAutoGet_$i"."_cart_minAmount"}
					&& $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} < $config{"storageAutoGet_$i"."_cart_maxAmount"})) {
					$ai_v{'temp'}{'found'} = 1;
				} else {
					if ($ai_v{'temp'}{'invIndex'} eq "") {
						$ai_v{'temp'}{'amount'} = $config{"storageAutoGet_$i"."_maxAmount"};
					} else {
						$ai_v{'temp'}{'amount'} = $config{"storageAutoGet_$i"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'};
					}

					if ($cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} < $ai_v{'temp'}{'amount'}) {
						$ai_v{'temp'}{'amount'} = $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'};
					}

					if ($ai_v{'temp'}{'amount'} > 0) {
						PrintMessage("Get $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'name'} x $ai_v{'temp'}{'amount'} from cart.", "white");
						sendCartGet(\$remote_socket, $ai_v{'temp'}{'cartIndex'}, $ai_v{'temp'}{'amount'});
						$timeout{'ai_storageAuto_wait_get_cart'}{'time'} = time;
						last AUTOSTORAGE;
					}
				}
			} elsif ($config{"storageAutoGet_$i"."_cart_minAmount"} > 0 && ($ai_v{'temp'}{'cartIndex'} eq "" ||
				($cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} <= $config{"storageAutoGet_$i"."_cart_minAmount"}
				&& $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} < $config{"storageAutoGet_$i"."_cart_maxAmount"}))) {
				$ai_v{'temp'}{'found'} = 1;
			}

			$i++;
		}


		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		#if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && ai_storageAutoCheck()) {
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && ($ai_v{'temp'}{'found'} ne "" || (percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'} && ai_storageAutoCheck()))) {
			PrintMessage("Begin Storage Auto", "yellow");
			unshift @ai_seq, "storageAuto";
			unshift @ai_seq_args, {};
		}
	}

	if ($ai_seq[0] eq "storageAuto" && $ai_seq_args[0]{'done'}) {
		PrintMessage("End Storage Auto", "yellow");
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'sellAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'storageAuto'} = 1;
			PrintMessage("Continue Sell Auto", "yellow");
			unshift @ai_seq, "sellAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
		}
	} elsif ($ai_seq[0] eq "storageAuto" && timeOut(\%{$timeout{'ai_storageAuto'}}) && timeOut(\%{$timeout{'ai_storageAuto_wait_put_cart'}})) {
		if (!$config{'storageAuto'} || !%{$npcs_lut{$config{'storageAuto_npc'}}}) {
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
			if ($ai_seq_args[0]{'warpedToSave'} && !$ai_seq_args[0]{'mapChanged'}) {
				undef $ai_seq_args[0]{'warpedToSave'};
			}
			if (IsWarpAble() && $config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'}) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				$timeout{'ai_storageAuto'}{'time'} = time;
			} else {
				PrintMessage("Calculating auto-storage route to: $maps_lut{$npcs_lut{$config{'storageAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'storageAuto_npc'}}{'map'}): $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'}.", "dark");
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$config{'storageAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
			}
		} else {
			if (!$ai_seq_args[0]{'sentTalk'}) {
				sendTalk(\$remote_socket, pack("L1",$config{'storageAuto_npc'}));
				if ($config{'storageAuto_npc_steps'} eq "") {
					#$config{'storageAuto_npc_steps'} = "c r1 n";
					$config{'storageAuto_npc_steps'} = "c c r1 n";
				}
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

			# Storage Auto Get
			if ($ai_seq_args[0]{'get'}) {
				while (1) {
					if ($config{"storageAutoGet_$ai_seq_args[0]{'get_index'}"} ne "") {
						$ai_v{'temp'}{'storageInvIndex'} = findIndexString_lc(\@{$storage{'inventory'}}, "name", $config{"storageAutoGet_$ai_seq_args[0]{'get_index'}"});
						$ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $config{"storageAutoGet_$ai_seq_args[0]{'get_index'}"});
						$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"storageAutoGet_$ai_seq_args[0]{'get_index'}"});

						if ($ai_v{'temp'}{'storageInvIndex'} eq "") {
							$ai_seq_args[0]{'get_index'}++;
							next;
						}

						if ($ai_v{'temp'}{'invIndex'} eq "" || $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $config{"storageAutoGet_$ai_seq_args[0]{'get_index'}"."_maxAmount"}) {
							if ($ai_v{'temp'}{'cartIndex'} ne "" && $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} >= $config{"storageAutoGet_$ai_seq_args[0]{'get_index'}"."_cart_maxAmount"}) {
								if ($ai_v{'temp'}{'invIndex'} eq "") {
									$ai_v{'temp'}{'get_amount'} = $config{"storageAutoGet_$ai_seq_args[0]{'get_index'}"."_maxAmount"};
								} else {
									$ai_v{'temp'}{'get_amount'} = $config{"storageAutoGet_$ai_seq_args[0]{'get_index'}"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'};
								}
							} else {
								if ($config{"storageAutoGet_$ai_seq_args[0]{'get_index'}"."_getAmount"} > 0) {
									$ai_v{'temp'}{'amount'} = $config{"storageAutoGet_$ai_seq_args[0]{'get_index'}"."_getAmount"};
								} else {
									$ai_v{'temp'}{'amount'} = $config{"storageAutoGet_$ai_seq_args[0]{'get_index'}"."_maxAmount"};
								}

								if ($ai_v{'temp'}{'invIndex'} eq "") {
									$ai_v{'temp'}{'get_amount'} = $ai_v{'temp'}{'amount'};
									$ai_v{'temp'}{'amount'} = $config{"storageAutoGet_$ai_seq_args[0]{'get_index'}"."_maxAmount"};
								} else {
									$ai_v{'temp'}{'get_amount'} = $ai_v{'temp'}{'amount'} - $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'};
									$ai_v{'temp'}{'amount'} = $config{"storageAutoGet_$ai_seq_args[0]{'get_index'}"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'};
								}

								if ($ai_v{'temp'}{'cartIndex'} ne "") {
									$ai_v{'temp'}{'amount'} += ($config{"storageAutoGet_$ai_seq_args[0]{'get_index'}"."_cart_maxAmount"} - $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'});
									if ($ai_v{'temp'}{'amount'} < $ai_v{'temp'}{'get_amount'}) {
										$ai_v{'temp'}{'get_amount'} = $ai_v{'temp'}{'amount'};
									}
								}
							}

							if ($ai_v{'temp'}{'get_amount'} > $storage{'inventory'}[$ai_v{'temp'}{'storageInvIndex'}]{'amount'}) {
								$ai_v{'temp'}{'get_amount'} = $storage{'inventory'}[$ai_v{'temp'}{'storageInvIndex'}]{'amount'};
							}

							if ($ai_v{'temp'}{'get_amount'} > 0) {
								PrintMessage("- Get $storage{'inventory'}[$ai_v{'temp'}{'storageInvIndex'}]{'name'} x $ai_v{'temp'}{'get_amount'} from storage.", "gray");
								sendStorageGet(\$remote_socket, $storage{'inventory'}[$ai_v{'temp'}{'storageInvIndex'}]{'index'}, $ai_v{'temp'}{'get_amount'});
								$timeout{'ai_storageAuto'}{'time'} = time;
								last AUTOSTORAGE;
							}

							last;
						# Put items to cart
						} else {
							if ($config{"storageAutoGet_$ai_seq_args[0]{'get_index'}"."_cart_maxAmount"} > 0 && ($ai_v{'temp'}{'cartIndex'} eq "" ||
								$cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} < $config{"storageAutoGet_$ai_seq_args[0]{'get_index'}"."_cart_maxAmount"})) {

								if ($ai_v{'temp'}{'cartIndex'} eq "") {
									$ai_v{'temp'}{'amount'} = $config{"storageAutoGet_$ai_seq_args[0]{'get_index'}"."_cart_maxAmount"};
								} else {
									$ai_v{'temp'}{'amount'} = $config{"storageAutoGet_$ai_seq_args[0]{'get_index'}"."_cart_maxAmount"} - $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'};
								}

								if ($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $ai_v{'temp'}{'amount'}) {
									$ai_v{'temp'}{'amount'} = $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'};
								}

								PrintMessage("- Put $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'name'} x $ai_v{'temp'}{'amount'} to cart.", "gray");
								sendCartAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $ai_v{'temp'}{'amount'});

								$timeout{'ai_storageAuto_wait_put_cart'}{'time'} = time;
								last AUTOSTORAGE;
							}
						}

						$ai_seq_args[0]{'get_index'}++;
					} else {
						undef $ai_seq_args[0]{'get'};
						undef $ai_seq_args[0]{'get_index'};
						last;
					}
				}
			} else {
				for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}}; $i++) {
					next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'});

					if ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'storage'}
						&& $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}) {

						$ai_v{'temp'}{'storageInvIndex'} = findIndexString_lc(\@{$storage{'inventory'}}, "name", $chars[$config{'char'}]{'inventory'}[$i]{'name'});
						if ($ai_v{'temp'}{'storageInvIndex'} ne "" || $storage{'items'} < $storage{'items_max'}) {
							if ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $chars[$config{'char'}]{'inventory'}[$i]{'index'}
								&& timeOut(\%{$timeout{'ai_storageAuto_giveup'}})) {
								last AUTOSTORAGE;
							} elsif ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $chars[$config{'char'}]{'inventory'}[$i]{'index'}) {
								$timeout{'ai_storageAuto_giveup'}{'time'} = time;
							}

							$ai_seq_args[0]{'lastIndex'} = $chars[$config{'char'}]{'inventory'}[$i]{'index'};
							sendStorageAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$i]{'index'}, $chars[$config{'char'}]{'inventory'}[$i]{'amount'} - $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'});
							$timeout{'ai_storageAuto'}{'time'} = time;
							last AUTOSTORAGE;
						}
					}
				}

				$ai_seq_args[0]{'get'} = 1;
				$ai_seq_args[0]{'get_index'} = 0;
				last AUTOSTORAGE;
			}

			sendStorageClose(\$remote_socket);
			sendTalkCancel(\$remote_socket, pack("L1",$config{'storageAuto_npc'}));
			$ai_seq_args[0]{'done'} = 1;
			last AUTOSTORAGE;
		}
	}

	} #END OF BLOCK AUTOSTORAGE

	Debug('AI storageAuto');


	#####AUTO SELL#####

	AUTOSELL: {

	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route") && $config{'sellAuto'} && $config{'sellAuto_npc'} ne "" && percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'} && $npcs_lut{$config{'sellAuto_npc'}}{'map'} ne "") {
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && ai_sellAutoCheck()) {
			PrintMessage("Begin Sell Auto", "yellow");
			unshift @ai_seq, "sellAuto";
			unshift @ai_seq_args, {};
		}
	}

	if ($ai_seq[0] eq "sellAuto" && $ai_seq_args[0]{'done'}) {
		PrintMessage("End Sell Auto", "yellow");
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'buyAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'sellAuto'} = 1;
			PrintMessage("Continue Buy Auto", "yellow");
			unshift @ai_seq, "buyAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
		}
	} elsif ($ai_seq[0] eq "sellAuto" && timeOut(\%{$timeout{'ai_sellAuto'}})) {
		if (!$config{'sellAuto'} || !%{$npcs_lut{$config{'sellAuto_npc'}}}) {
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
			if ($ai_seq_args[0]{'warpedToSave'} && !$ai_seq_args[0]{'mapChanged'}) {
				undef $ai_seq_args[0]{'warpedToSave'};
			}
			if (IsWarpAble() && $config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'}) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				$timeout{'ai_sellAuto'}{'time'} = time;
			} else {
				PrintMessage("Calculating auto-sell route to: $maps_lut{$npcs_lut{$config{'sellAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'sellAuto_npc'}}{'map'}): $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'y'}.", "dark");
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
			for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}}; $i++) {
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
		}
	}

	} #END OF BLOCK AUTOSELL

	Debug('AI sellAuto');


	#####AUTO BUY#####

	AUTOBUY: {

	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "attack") && timeOut(\%{$timeout{'ai_buyAuto'}}) && timeOut(\%{$timeout{'ai_buyAuto_wait_get_cart'}}) && timeOut(\%{$timeout{'ai_storageAuto_wait_get_cart'}})) {
		undef $ai_v{'temp'}{'found'};
		$i = 0;
		while ($config{"buyAuto_$i"} ne "" && $config{"buyAuto_$i"."_npc"} ne "" && $npcs_lut{$config{"buyAuto_$i"."_npc"}}{'map'} ne "") {
			$ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $config{"buyAuto_$i"});
			$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"buyAuto_$i"});
			if ($config{"buyAuto_$i"."_maxAmount"} > 0 && ($ai_v{'temp'}{'invIndex'} eq "" ||
				($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} <= $config{"buyAuto_$i"."_minAmount"} &&
				$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $config{"buyAuto_$i"."_maxAmount"}))) {
				# Get items from cart
				if ($ai_v{'temp'}{'cartIndex'} eq "" ||
					($cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} <= $config{"buyAuto_$i"."_cart_minAmount"}
					&& $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} < $config{"buyAuto_$i"."_cart_maxAmount"})) {
					$ai_v{'temp'}{'found'} = 1;
				} else {
					if ($ai_v{'temp'}{'invIndex'} eq "") {
						$ai_v{'temp'}{'amount'} = $config{"buyAuto_$i"."_maxAmount"};
					} else {
						$ai_v{'temp'}{'amount'} = $config{"buyAuto_$i"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'};
					}

					if ($cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} < $ai_v{'temp'}{'amount'}) {
						$ai_v{'temp'}{'amount'} = $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'};
					}

					if ($ai_v{'temp'}{'amount'} > 0) {
						PrintMessage("Get $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'name'} x $ai_v{'temp'}{'amount'} from cart.", "white");
						sendCartGet(\$remote_socket, $ai_v{'temp'}{'cartIndex'}, $ai_v{'temp'}{'amount'});
						$timeout{'ai_buyAuto_wait_get_cart'}{'time'} = time;
						last AUTOBUY;
					}
				}
			} elsif ($config{"buyAuto_$i"."_cart_minAmount"} > 0 && ($ai_v{'temp'}{'cartIndex'} eq "" ||
				($cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} <= $config{"buyAuto_$i"."_cart_minAmount"}
				&& $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} < $config{"buyAuto_$i"."_cart_maxAmount"}))) {
				$ai_v{'temp'}{'found'} = 1;
			}

			$i++;
		}
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && $ai_v{'temp'}{'found'} && !$chars[$config{'char'}]{'shop'}) {
			PrintMessage("Begin Buy Auto", "yellow");
			unshift @ai_seq, "buyAuto";
			unshift @ai_seq_args, {};
		}
		$timeout{'ai_buyAuto'}{'time'} = time;
	}

	if ($ai_seq[0] eq "buyAuto" && $ai_seq_args[0]{'done'}) {
		PrintMessage("End Buy Auto", "yellow");
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'storageAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'buyAuto'} = 1;
			PrintMessage("Continue Storage Auto", "yellow");
			unshift @ai_seq, "storageAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
		}
	} elsif ($ai_seq[0] eq "buyAuto" && timeOut(\%{$timeout{'ai_buyAuto_wait'}}) && timeOut(\%{$timeout{'ai_buyAuto_wait_buy'}}) && timeOut(\%{$timeout{'ai_buyAuto_wait_put_cart'}})) {
		$i = 0;
		undef $ai_seq_args[0]{'index'};

		while (1) {
			last if (!$config{"buyAuto_$i"} || !%{$npcs_lut{$config{"buyAuto_$i"."_npc"}}});
			$ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $config{"buyAuto_$i"});
			$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"buyAuto_$i"});

			if (!$ai_seq_args[0]{'index_failed'}{$i} &&
				($ai_v{'temp'}{'invIndex'} eq "" || $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $config{"buyAuto_$i"."_maxAmount"})) {

				# When item is full buy only maxAmount
				if ($ai_v{'temp'}{'cartIndex'} ne "" && $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} >= $config{"buyAuto_$i"."_cart_maxAmount"}) {
					if ($ai_v{'temp'}{'invIndex'} eq "") {
						$ai_seq_args[0]{'buy_amount'} = $config{"buyAuto_$i"."_maxAmount"};
					} else {
						$ai_seq_args[0]{'buy_amount'} = $config{"buyAuto_$i"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'};
					}
				} else {
					if ($config{"buyAuto_$i"."_buyAmount"} > 0) {
						$ai_v{'temp'}{'amount'} = $config{"buyAuto_$i"."_buyAmount"};
						if ($ai_v{'temp'}{'amount'} < $config{"buyAuto_$i"."_maxAmount"}) {
							$ai_v{'temp'}{'amount'} = $config{"buyAuto_$i"."_maxAmount"};
						}
					} else {
						$ai_v{'temp'}{'amount'} = $config{"buyAuto_$i"."_maxAmount"};
					}

					if ($ai_v{'temp'}{'invIndex'} eq "") {
						$ai_seq_args[0]{'buy_amount'} = $ai_v{'temp'}{'amount'};
						$ai_v{'temp'}{'amount'} = $config{"buyAuto_$i"."_maxAmount"};
					} else {
						$ai_seq_args[0]{'buy_amount'} = $ai_v{'temp'}{'amount'} - $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'};
						$ai_v{'temp'}{'amount'} = $config{"buyAuto_$i"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'};
					}

					if ($ai_v{'temp'}{'cartIndex'} ne "") {
						$ai_v{'temp'}{'amount'} += ($config{"buyAuto_$i"."_cart_maxAmount"} - $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'});
						if ($ai_v{'temp'}{'amount'} < $ai_seq_args[0]{'buy_amount'}) {
							$ai_seq_args[0]{'buy_amount'} = $ai_v{'temp'}{'amount'};
						}
					}
				}

				if ($ai_seq_args[0]{'buy_amount'} > 0) {
					$ai_seq_args[0]{'index'} = $i;
				}

				last;
			# Put items to cart
			} else {
				#DebugMessage("- PUT: $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} ".$config{"buyAuto_$i"."_cart_maxAmount"}) if ($debug{'ai_autoBuy'});
				if ($config{"buyAuto_$i"."_cart_maxAmount"} > 0 && ($ai_v{'temp'}{'cartIndex'} eq "" ||
					$cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} < $config{"buyAuto_$i"."_cart_maxAmount"})) {

					if ($ai_v{'temp'}{'cartIndex'} eq "") {
						$ai_v{'temp'}{'amount'} = $config{"buyAuto_$i"."_cart_maxAmount"};
					} else {
						$ai_v{'temp'}{'amount'} = $config{"buyAuto_$i"."_cart_maxAmount"} - $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'};
					}

					if ($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $ai_v{'temp'}{'amount'}) {
						$ai_v{'temp'}{'amount'} = $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'};
					}

					PrintMessage("- Put $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'name'} x $ai_v{'temp'}{'amount'} to cart.", "gray");
					sendCartAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $ai_v{'temp'}{'amount'});

					undef $ai_seq_args[0]{'lastIndex'};

					$timeout{'ai_buyAuto_wait_put_cart'}{'time'} = time;
					last AUTOBUY;
				}
			}
			$i++;
		}
		if ($ai_seq_args[0]{'index'} eq ""
			|| ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $ai_seq_args[0]{'index'}
			&& timeOut(\%{$timeout{'ai_buyAuto_giveup'}}))) {
			DebugMessage("- Buy-Auto is done. LASTINDEX: $ai_seq_args[0]{'lastIndex'}, INDEX: $ai_seq_args[0]{'index'}") if ($debug{'ai_autoBuy'});
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
			if ($ai_seq_args[0]{'warpedToSave'} && !$ai_seq_args[0]{'mapChanged'}) {
				undef $ai_seq_args[0]{'warpedToSave'};
			}
			if (IsWarpAble() && $config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'}) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				$timeout{'ai_buyAuto_wait'}{'time'} = time;
			} else {
				PrintMessage(qq~Calculating auto-buy route to: $maps_lut{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}.'.rsw'}($npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}): $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'x'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'y'}.~, "dark");
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
					DebugMessage("- Auto-buy index $ai_seq_args[0]{'index'} failed.") if ($debug{'ai_autoBuy'});
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

			if ($ai_seq_args[0]{'buy_amount'} > 0) {
				PrintMessage("- Buy $items_lut{$ai_seq_args[0]{'itemID'}} x $ai_seq_args[0]{'buy_amount'}", "gray");
				sendBuy(\$remote_socket, $ai_seq_args[0]{'itemID'}, $ai_seq_args[0]{'buy_amount'});
			}

			$timeout{'ai_buyAuto_wait_buy'}{'time'} = time;
		}
	}

	} #END OF BLOCK AUTOBUY

	Debug('AI buyAuto');


	#####AUTO STOCK#####

	AUTOSTOCK: {

	if ($ai_seq[0] eq "" && !$chars[$config{'char'}]{'stockAuto'} && $config{'stockAuto'} && $config{'stockAuto_npc'} ne "" && $npcs_lut{$config{'stockAuto_npc'}}{'map'} ne "") {
		PrintMessage("Begin Stock Auto", "yellow");
		unshift @ai_seq, "stockAuto";
		unshift @ai_seq_args, {};
	}

	if ($ai_seq[0] eq "stockAuto" && $ai_seq_args[0]{'done'}) {
		$chars[$config{'char'}]{'stockAuto'} = 1;
		PrintMessage("End Stock Auto", "yellow");
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "stockAuto" &&
		timeOut(\%{$timeout{'ai_stockAuto'}}) &&
		timeOut(\%{$timeout{'ai_stockAuto_wait_buy'}}) &&
		timeOut(\%{$timeout{'ai_stockAuto_wait_put_cart'}})
		) {
		if (!$config{'stockAuto'} || !%{$npcs_lut{$config{'stockAuto_npc'}}}) {
			$ai_seq_args[0]{'done'} = 1;
			last AUTOSTOCK;
		}

		if (!$ai_seq_args[0]{'checkStock'} || $ai_seq_args[0]{'putStock'}) {
			undef $ai_v{'temp'}{'do_storage_route'};
			if ($field{'name'} ne $npcs_lut{$config{'stockAuto_npc'}}{'map'}) {
				$ai_v{'temp'}{'do_storage_route'} = 1;
			} else {
				$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{'stockAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
				if ($ai_v{'temp'}{'distance'} > 14) {
					$ai_v{'temp'}{'do_storage_route'} = 1;
				}
			}
		} elsif ($ai_seq_args[0]{'stockBuy'} >= 0) {
			undef $ai_v{'temp'}{'do_buy_route'};
			if ($field{'name'} ne $npcs_lut{$ai_seq_args[0]{'buy_npc'}}{'map'}) {
				$ai_v{'temp'}{'do_buy_route'} = 1;
			} else {
				$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$ai_seq_args[0]{'buy_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
				if ($ai_v{'temp'}{'distance'} > 14) {
					$ai_v{'temp'}{'do_buy_route'} = 1;
				}
			}
		} else {
			$ai_seq_args[0]{'done'} = 1;
			last AUTOSTOCK;
		}

		if ($ai_v{'temp'}{'do_storage_route'}) {
			PrintMessage("Calculating auto-stock route to: $maps_lut{$npcs_lut{$config{'stockAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'stockAuto_npc'}}{'map'}): $npcs_lut{$config{'stockAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'stockAuto_npc'}}{'pos'}{'y'}.", "dark");
			ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{'stockAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'stockAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$config{'stockAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
		} elsif ($ai_v{'temp'}{'do_buy_route'}) {
			PrintMessage("Calculating auto-stock-buy route to: $maps_lut{$npcs_lut{$ai_seq_args[0]{'buy_npc'}}{'map'}.'.rsw'}($npcs_lut{$ai_seq_args[0]{'buy_npc'}}{'map'}): $npcs_lut{$ai_seq_args[0]{'buy_npc'}}{'pos'}{'x'}, $npcs_lut{$ai_seq_args[0]{'buy_npc'}}{'pos'}{'y'}.", "dark");
			ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$ai_seq_args[0]{'buy_npc'}}{'pos'}{'x'}, $npcs_lut{$ai_seq_args[0]{'buy_npc'}}{'pos'}{'y'}, $npcs_lut{$ai_seq_args[0]{'buy_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
		} elsif (!$ai_seq_args[0]{'checkStock'} || $ai_seq_args[0]{'putStock'}) {
			if (!$ai_seq_args[0]{'sentTalk'}) {
				sendTalk(\$remote_socket, pack("L1",$config{'stockAuto_npc'}));
				if ($config{'stockAuto_npc_steps'} eq "") {
					$config{'stockAuto_npc_steps'} = "c c r1 n";
				}
				@{$ai_seq_args[0]{'steps'}} = split(/ /, $config{'stockAuto_npc_steps'});
				$ai_seq_args[0]{'sentTalk'} = 1;
				$timeout{'ai_stockAuto'}{'time'} = time;
				last AUTOSTOCK;
			} elsif (defined(@{$ai_seq_args[0]{'steps'}})) {
				if ($ai_seq_args[0]{'steps'}[$ai_seq_args[0]{'step'}] =~ /c/i) {
					sendTalkContinue(\$remote_socket, pack("L1",$config{'stockAuto_npc'}));
				} elsif ($ai_seq_args[0]{'steps'}[$ai_seq_args[0]{'step'}] =~ /n/i) {
					sendTalkCancel(\$remote_socket, pack("L1",$config{'stockAuto_npc'}));
				} elsif ($ai_seq_args[0]{'steps'}[$ai_seq_args[0]{'step'}] ne "") {
					($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'steps'}[$ai_seq_args[0]{'step'}] =~ /r(\d+)/i;
					if ($ai_v{'temp'}{'arg'} ne "") {
						$ai_v{'temp'}{'arg'}++;
						sendTalkResponse(\$remote_socket, pack("L1",$config{'stockAuto_npc'}), $ai_v{'temp'}{'arg'});
					}
				} else {
					undef @{$ai_seq_args[0]{'steps'}};
				}
				$ai_seq_args[0]{'step'}++;
				$timeout{'ai_stockAuto'}{'time'} = time;
				last AUTOSTOCK;
			}

			if (!$ai_seq_args[0]{'checkStock'}) {
				PrintMessage("Checking stock...", "lightblue");

				$ai_seq_args[0]{'stockBuy'} = -1;
				$i = 0;
				while ($config{"stockAuto_$i"} ne "") {
					$ai_v{'temp'}{'storageInvIndex'} = findIndexString_lc(\@{$storage{'inventory'}}, "name", $config{"stockAuto_$i"});
					if ($ai_v{'temp'}{'storageInvIndex'} ne "") {
						if ($storage{'inventory'}[$ai_v{'temp'}{'storageInvIndex'}]{'amount'} >= $config{"stockAuto_$i"."_maxAmount"}) {
							$ai_v{'temp'}{'addAmount'} = 0;
						} else {
							$ai_v{'temp'}{'addAmount'} = $config{"stockAuto_$i"."_maxAmount"} - $storage{'inventory'}[$ai_v{'temp'}{'storageInvIndex'}]{'amount'};
						}
					} else {
						$ai_v{'temp'}{'addAmount'} = $config{"stockAuto_$i"."_maxAmount"};
					}

					undef $ai_v{'temp'}{'itemID'};

					foreach (keys %items_lut) {
						if (lc($items_lut{$_}) eq lc($config{"stockAuto_$i"})) {
							$ai_v{'temp'}{'itemID'} = $_;
							last;
						}
					}

					if ($ai_v{'temp'}{'itemID'} eq "") {
						$ai_v{'temp'}{'addAmount'} = 0;
					}

					PrintMessage(($i + 1).". ".$config{"stockAuto_$i"}." x $ai_v{'temp'}{'addAmount'}", "gray");

					if ($ai_seq_args[0]{'stockBuy'} < 0 && $ai_v{'temp'}{'addAmount'} > 0) {
						$ai_seq_args[0]{'stockBuy'} = $i;
						$ai_seq_args[0]{'addAmount'} = $ai_v{'temp'}{'addAmount'};
						$ai_seq_args[0]{'item'} = $config{"stockAuto_$i"};
						$ai_seq_args[0]{'itemID'} = $ai_v{'temp'}{'itemID'};
						$ai_seq_args[0]{'maxAmount'} = $config{"stockAuto_$i"."_maxAmount"};
						$ai_seq_args[0]{'buy_npc'} = $config{"stockAuto_$i"."_buy_npc"};
						$ai_seq_args[0]{'buy_maxAmount'} = $config{"stockAuto_$i"."_buy_maxAmount"};
						$ai_seq_args[0]{'buy_buyAmount'} = $config{"stockAuto_$i"."_buy_buyAmount"};
						$ai_seq_args[0]{'buy_cart_maxAmount'} = $config{"stockAuto_$i"."_buy_cart_maxAmount"};
					}

					$i++;
				}

				if ($ai_seq_args[0]{'stockBuy'} < 0) {
					$ai_seq_args[0]{'done'} = 1;
				}

				$ai_seq_args[0]{'checkStock'} = 1;
				undef $ai_seq_args[0]{'putStock'};
				undef $ai_seq_args[0]{'sentBuy'};
				undef $ai_seq_args[0]{'buy_amount'};
			} elsif ($ai_seq_args[0]{'putStock'}) {
				$ai_v{'temp'}{'storageInvIndex'} = findIndexString_lc(\@{$storage{'inventory'}}, "name", $ai_seq_args[0]{'item'});
				if ($ai_v{'temp'}{'storageInvIndex'} ne "") {
					if ($storage{'inventory'}[$ai_v{'temp'}{'storageInvIndex'}]{'amount'} >= $ai_seq_args[0]{'maxAmount'}) {
						$ai_seq_args[0]{'addAmount'} = 0;
					} else {
						$ai_seq_args[0]{'addAmount'} = $ai_seq_args[0]{'maxAmount'} - $storage{'inventory'}[$ai_v{'temp'}{'storageInvIndex'}]{'amount'};
					}
				} else {
					$ai_seq_args[0]{'addAmount'} = $ai_seq_args[0]{'maxAmount'};
				}

				if ($ai_seq_args[0]{'addAmount'} == 0) {
					undef $ai_seq_args[0]{'checkStock'};
					undef $ai_seq_args[0]{'putStock'};
					undef $ai_seq_args[0]{'sentBuy'};
					undef $ai_seq_args[0]{'buy_amount'};
					last AUTOSTOCK;
				} else {
					$ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $ai_seq_args[0]{'item'});
					$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $ai_seq_args[0]{'item'});

					$ai_v{'temp'}{'amount'} = 0;

					if ($ai_v{'temp'}{'invIndex'} ne "") {
						$ai_v{'temp'}{'amount'} += $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'};
					}

					if ($ai_v{'temp'}{'cartIndex'} ne "") {
						$ai_v{'temp'}{'amount'} += $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'};
					}

					if ($ai_v{'temp'}{'amount'} > $ai_seq_args[0]{'addAmount'}) {
						$ai_v{'temp'}{'amount'} = $ai_seq_args[0]{'addAmount'};
					}

					if ($ai_v{'temp'}{'invIndex'} ne "") {
						if ($ai_v{'temp'}{'amount'} > $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'}) {
							$ai_v{'temp'}{'amount'} = $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'};
						}

						PrintMessage("- Add inventory $ai_seq_args[0]{'item'} x $ai_v{'temp'}{'amount'} to storage.", "gray");
						sendStorageAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $ai_v{'temp'}{'amount'});
					} elsif ($ai_v{'temp'}{'cartIndex'} ne "") {
						if ($ai_v{'temp'}{'amount'} > $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'}) {
							$ai_v{'temp'}{'amount'} = $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'};
						}

						PrintMessage("- Add cart $ai_seq_args[0]{'item'} x $ai_v{'temp'}{'amount'} to storage.", "gray");
						sendCartStorageAdd(\$remote_socket, $ai_v{'temp'}{'cartIndex'}, $ai_v{'temp'}{'amount'});
					} else {
						undef $ai_seq_args[0]{'checkStock'};
						undef $ai_seq_args[0]{'putStock'};
						undef $ai_seq_args[0]{'sentBuy'};
						undef $ai_seq_args[0]{'buy_amount'};
					}

					$timeout{'ai_stockAuto'}{'time'} = time;
					last AUTOSTOCK;
				}
			}

			sendStorageClose(\$remote_socket);
			sendTalkCancel(\$remote_socket, pack("L1",$config{'stockAuto_npc'}));
			undef $ai_seq_args[0]{'sentTalk'};
			undef $ai_seq_args[0]{'step'};
			last AUTOSTOCK;
		} else {
			if ($ai_seq_args[0]{'buy_amount'} == 0) {
				$ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $ai_seq_args[0]{'item'});
				$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $ai_seq_args[0]{'item'});

				if ($ai_v{'temp'}{'invIndex'} eq "" || $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $ai_seq_args[0]{'buy_maxAmount'}) {
					# When item is full buy only maxAmount
					if ($ai_v{'temp'}{'cartIndex'} ne "" && $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} >= $ai_seq_args[0]{'buy_cart_maxAmount'}) {
						if ($ai_v{'temp'}{'invIndex'} eq "") {
							$ai_seq_args[0]{'buy_amount'} = $ai_seq_args[0]{'buy_maxAmount'};
						} else {
							$ai_seq_args[0]{'buy_amount'} = $ai_seq_args[0]{'buy_maxAmount'} - $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'};
						}
					} else {
						if ($ai_seq_args[0]{'buy_buyAmount'} > 0) {
							$ai_v{'temp'}{'amount'} = $ai_seq_args[0]{'buy_buyAmount'};
							if ($ai_v{'temp'}{'amount'} < $ai_seq_args[0]{'buy_maxAmount'}) {
								$ai_v{'temp'}{'amount'} = $ai_seq_args[0]{'buy_maxAmount'};
							}
						} else {
							$ai_v{'temp'}{'amount'} = $ai_seq_args[0]{'buy_maxAmount'};
						}

						if ($ai_v{'temp'}{'invIndex'} eq "") {
							$ai_seq_args[0]{'buy_amount'} = $ai_v{'temp'}{'amount'};
							$ai_v{'temp'}{'amount'} = $ai_seq_args[0]{'buy_maxAmount'};
						} else {
							$ai_seq_args[0]{'buy_amount'} = $ai_v{'temp'}{'amount'} - $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'};
							$ai_v{'temp'}{'amount'} = $ai_seq_args[0]{'buy_maxAmount'} - $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'};
						}

						if ($ai_v{'temp'}{'cartIndex'} ne "") {
							$ai_v{'temp'}{'amount'} += ($ai_seq_args[0]{'buy_cart_maxAmount'} - $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'});
							if ($ai_v{'temp'}{'amount'} < $ai_seq_args[0]{'buy_amount'}) {
								$ai_seq_args[0]{'buy_amount'} = $ai_v{'temp'}{'amount'};
							}
						}
					}

					$ai_v{'temp'}{'amount'} = 0;

					if ($ai_v{'temp'}{'invIndex'} ne "") {
						$ai_v{'temp'}{'amount'} += $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'};
					}

					if ($ai_v{'temp'}{'cartIndex'} ne "") {
						$ai_v{'temp'}{'amount'} += $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'};
					}

					if ($ai_v{'temp'}{'amount'} > $ai_seq_args[0]{'addAmount'}) {
						$ai_seq_args[0]{'buy_amount'} = 0;
					} else {
						$ai_v{'temp'}{'amount'} = $ai_seq_args[0]{'addAmount'} - $ai_v{'temp'}{'amount'};
						if ($ai_seq_args[0]{'buy_amount'} > $ai_v{'temp'}{'amount'}) {
							$ai_seq_args[0]{'buy_amount'} = $ai_v{'temp'}{'amount'};
						}
					}
				} else {
					# Put items to cart
					if ($ai_seq_args[0]{'buy_cart_maxAmount'} > 0 && ($ai_v{'temp'}{'cartIndex'} eq "" ||
						$cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} < $config{"buyAuto_$i"."_cart_maxAmount"})) {

						if ($ai_v{'temp'}{'cartIndex'} eq "") {
							$ai_v{'temp'}{'amount'} = $ai_seq_args[0]{'buy_cart_maxAmount'};
						} else {
							$ai_v{'temp'}{'amount'} = $ai_seq_args[0]{'buy_cart_maxAmount'} - $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'};
						}

						if ($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $ai_v{'temp'}{'amount'}) {
							$ai_v{'temp'}{'amount'} = $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'};
						}

						PrintMessage("- Put $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'name'} x $ai_v{'temp'}{'amount'} to cart.", "gray");
						sendCartAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $ai_v{'temp'}{'amount'});

						$timeout{'ai_stockAuto_wait_put_cart'}{'time'} = time;
						undef $ai_seq_args[0]{'buy_amount'};
						last AUTOSTOCK;
					}
				}
			}

			if ($ai_seq_args[0]{'buy_amount'} == 0) {
				PrintMessage("Put $ai_seq_args[0]{'item'} to stock.", "lightblue");
				$ai_seq_args[0]{'putStock'} = 1;
				last AUTOSTOCK;
			}

			if ($ai_seq_args[0]{'sentBuy'} <= 1) {
				sendTalk(\$remote_socket, pack("L1",$ai_seq_args[0]{'buy_npc'})) if !$ai_seq_args[0]{'sentBuy'};
				sendGetStoreList(\$remote_socket, pack("L1",$ai_seq_args[0]{'buy_npc'})) if $ai_seq_args[0]{'sentBuy'};
				$ai_seq_args[0]{'sentBuy'}++;
				$timeout{'ai_stockAuto_wait_buy'}{'time'} = time;
				last AUTOSTOCK;
			}

			if ($ai_seq_args[0]{'buy_amount'} > 0) {
				PrintMessage("- Buy $items_lut{$ai_seq_args[0]{'itemID'}} x $ai_seq_args[0]{'buy_amount'}", "gray");
				sendBuy(\$remote_socket, $ai_seq_args[0]{'itemID'}, $ai_seq_args[0]{'buy_amount'});
			}

			$timeout{'ai_stockAuto_wait_buy'}{'time'} = time;
			undef $ai_seq_args[0]{'buy_amount'};
			last AUTOSTOCK;
		}
	}

	} #END OF BLOCK AUTOSTOCK

	Debug('AI stockAuto');

	##### AUTO SHOP #####
	AUTOSHOP: {

	if (($ai_seq[0] eq "") && $config{'shopAuto'} && $chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'lv'} > 0) {
		undef $ai_v{'temp'}{'found'};
		$i = 0;
		while ($config{"shop_item_$i"} ne "") {
			$index = findIndexString_lc(\@{$cart{'inventory'}}, "name", $config{"shop_item_$i"});
			if ($index ne "") {
				if ($config{"shop_item_$i"."_price"} > 0 && $cart{'inventory'}[$index]{'amount'} >= $config{"shop_item_$i"."_minAmount"}) {
					$ai_v{'temp'}{'found'} = 1;
				} elsif ($config{"shop_item_$i"."_require"}) {
					undef $ai_v{'temp'}{'found'};
					last;
				}
			}

			$i++;
		}

		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && $ai_v{'temp'}{'found'}) {
			PrintMessage("Begin Shop Auto", "yellow");
			unshift @ai_seq, "shopAuto";
			unshift @ai_seq_args, {};
		} elsif (!$ai_v{'temp'}{'found'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'storageAuto'} = 1;
			unshift @ai_seq, "buyAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
		}
	}

	if ($ai_seq[0] eq "shopAuto" && $ai_seq_args[0]{'done'}) {
		PrintMessage("End Shop Auto", "yellow");
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'buyAuto'}) {
			PrintMessage("Continue Buy Auto", "yellow");
			$ai_v{'temp'}{'ai'}{'completedAI'}{'shopAuto'} = 1;
			$ai_v{'temp'}{'ai'}{'completedAI'}{'storageAuto'} = 1;
			unshift @ai_seq, "buyAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
		}
	} elsif ($ai_seq[0] eq "shopAuto") {
		if (!$config{'shopAuto'} || $config{'shopAuto_title'} eq "") {
			$ai_seq_args[0]{'done'} = 1;

			if ($chars[$config{'char'}]{'shop'}) {
				ShopClose(\$remote_socket);
			}

			last AUTOSHOP;
		}

		undef $ai_v{'temp'}{'do_route'};
		if (($config{"shopAuto_map"} ne "" && $field{'name'} ne $config{"shopAuto_map"}) &&
			(($config{"shopAuto_mapX"} eq "" && $config{"shopAuto_mapY"} eq "") ||
			($config{"shopAuto_mapX"} ne "" && $chars[$config{'char'}]{'pos_to'}{'x'} != $config{"shopAuto_mapX"} &&
			$config{"shopAuto_mapY"} ne "" && $chars[$config{'char'}]{'pos_to'}{'y'} != $config{"shopAuto_mapY"}))) {
			$ai_v{'temp'}{'pos'}{'x'} = $config{"shopAuto_mapX"};
			$ai_v{'temp'}{'pos'}{'y'} = $config{"shopAuto_mapY"};

			$ai_v{'temp'}{'distance'} = distance(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			if ($ai_v{'temp'}{'distance'} > 5) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}

		if ($ai_v{'temp'}{'do_route'}) {
			if ($ai_seq_args[0]{'warpedToSave'} && !$ai_seq_args[0]{'mapChanged'}) {
				undef $ai_seq_args[0]{'warpedToSave'};
			}
			if (IsWarpAble() && $config{'saveMap'} eq $config{"shopAuto_map"} && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'}) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
			} else {
				PrintMessage(qq~Calculating auto-shop route to: $maps_lut{$config{"shopAuto_map"}.'.rsw'}($config{"shopAuto_map"}): $config{"shopAuto_mapX"}, $config{"shopAuto_mapY"}.~, "dark");
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $config{"shopAuto_mapX"}, $config{"shopAuto_mapY"}, $config{"shopAuto_map"}, 0, 0, 1, 0, 0, 1);
			}
		} else {
			if ($chars[$config{'char'}]{'shop'}) {
				for ($i = 0; $i < @{$shop{'inventory'}}; $i++) {
					next if (!%{$shop{'inventory'}[$i]});
					if ($shop{'inventory'}[$i]{'require'} && $shop{'inventory'}[$i]{'amount'} <= $shop{'inventory'}[$i]{'minAmount'}) {
						$ai_seq_args[0]{'done'} = 1;
						PrintMessage("Close shop because $shop{'inventory'}[$i]{'name'} x $shop{'inventory'}[$i]{'amount'}", "red");
						ShopClose(\$remote_socket);
						last AUTOSHOP;
					}
				}
			} elsif ($chars[$config{'char'}]{'sp'} < 30) {
				if ($chars[$config{'char'}]{'sitting'} == 0) {
					sit();
				}
			} elsif (timeOut(\%{$timeout{'ai_shopAuto_wait'}})) {
				$shop{'auto'} = 1;
				ai_skillUse($chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'ID'}, $chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'lv'}, 0, 0, 0, $accountID);
				$timeout{'ai_shopAuto_wait'}{'time'} = time;
			}
		}
	}

	}

	Debug('AI shopAuto');


	##### LOCKMAP #####

	if ($AI) {
		if ($chars[$config{'char'}]{'lockMap'} eq "") {
			if ($config{"lockMap_random"}) {
				$count = 0;
				while ($config{"lockMap_$count"} ne "") {
					$count++;
				}

				if ($count > 1) {
					if ($chars[$config{'char'}]{'lockMapSlot'} eq "") {
						$i = (rand() * 100) % $count;
					} else {
						do {
							$i = (rand() * 100) % $count;
						} while ($i == $chars[$config{'char'}]{'lockMapSlot'});
					}
				} else {
					$i = 0;
				}
			} else {
				if ($chars[$config{'char'}]{'lockMapSlot'} eq "") {
					$i = 0;
				} else {
					$i = $chars[$config{'char'}]{'lockMapSlot'} + 1;
				}

				if ($config{"lockMap_$i"} eq "") {
					$i = 0;
				}
			}

			if ($config{"lockMap_$i"} ne "") {
				PrintMessage("-------------------------------------------------------------------------------", "dark");

				if ($config{"lockMap_$i"."_x"} eq "") {
					PrintMessage("Lock map: ".$config{"lockMap_$i"}, "yellow");
				} else {
					PrintMessage("Lock map: ".$config{"lockMap_$i"}." ".$config{"lockMap_$i"."_x"}.", ".$config{"lockMap_$i"."_y"}, "yellow");
				}

				$chars[$config{'char'}]{'lockMap'} = $config{"lockMap_$i"};
				$chars[$config{'char'}]{'lockMapSlot'} = $i;

				$timeout_ex{'lockMap'}{'time'} = time;
				$timeout_ex{'lockMap'}{'timeout'} = 0;

				configModify("lockMap", $config{"lockMap_$i"});
				configModify("lockMap_x", $config{"lockMap_$i"."_x"});
				configModify("lockMap_y", $config{"lockMap_$i"."_y"});
			}
		} elsif ($config{'lockMap'} && $field{'name'} &&
			($field{'name'} eq $config{'lockMap'} && ($config{'lockMap_x'} eq "" || ($chars[$config{'char'}]{'pos_to'}{'x'} == $config{'lockMap_x'} && $chars[$config{'char'}]{'pos_to'}{'y'} == $config{'lockMap_y'})))) {
			undef $ai_v{'temp'}{'unlock'};

			$i = $chars[$config{'char'}]{'lockMapSlot'};

			if ($config{"lockMap_$i"."_leaveWhenNoMonsters"} ne "") {
				undef $ai_v{'temp'}{'found'};
				foreach (@monstersID) {
					next if ($_ eq "");
					if (existsInList($config{"lockMap_$i"."_leaveWhenNoMonsters"}, $monsters{$_}{'name'})) {
						$ai_v{'temp'}{'found'} = 1;
					}
				}

				if (!$ai_v{'temp'}{'found'}) {
					$ai_v{'temp'}{'unlock'} = 1;
					PrintMessage("Not found ".$config{"lockMap_$i"."_leaveWhenNoMonsters"}.". Lock map is changed.", "lightblue");
				}
			}

			if ($config{"lockMap_$i"."_leaveWhenFoundMonsters"} ne "") {
				foreach (@monstersID) {
					next if ($_ eq "");
					if (existsInList($config{"lockMap_$i"."_leaveWhenFoundMonsters"}, $monsters{$_}{'name'})) {
						$ai_v{'temp'}{'unlock'} = 1;
						PrintMessage("Found $monsters{$_}{'name'}. Lock map is changed.", "lightblue");
					}
				}
			}

			if ($config{"lockMap_$i"."_leaveWhenDead"} > 0 && $chars[$config{'char'}]{'dead'}) {
				PrintMessage("You have died. Lock map is changed.", "lightblue");
				$ai_v{'temp'}{'unlock'} = 1;
			}

			if ($timeout_ex{'lockMap'}{'timeout'} != $config{"lockMap_$i"."_leaveTime"}) {
				$timeout_ex{'lockMap'}{'time'} = time;
				$timeout_ex{'lockMap'}{'timeout'} = $config{"lockMap_$i"."_leaveTime"};
			}

			if ($timeout_ex{'lockMap'}{'timeout'} > 0 && timeOut(\%{$timeout_ex{'lockMap'}})) {
				PrintMessage("Timeout on lock map. Lock map is changed.", "lightblue");
				$ai_v{'temp'}{'unlock'} = 1;
			}

			if ($ai_v{'temp'}{'unlock'}) {
				undef $chars[$config{'char'}]{'lockMap'};
			}
		}
	}

	if ($AI && ($ai_seq[0] eq "" || ($ai_seq[0] eq "follow" && !$ai_seq_args[0]{'following'})) && $config{'lockMap'} && $field{'name'}
		&& ($field{'name'} ne $config{'lockMap'} || ($config{'lockMap_x'} ne "" && ($chars[$config{'char'}]{'pos_to'}{'x'} != $config{'lockMap_x'} || $chars[$config{'char'}]{'pos_to'}{'y'} != $config{'lockMap_y'})))) {
		if ($maps_lut{$config{'lockMap'}.'.rsw'} eq "") {
			DebugMessage("- Invalid map specified for lockMap - map $config{'lockMap'} doesn't exist.") if ($debug{'ai_lockMap'});
		} else {
			if ($config{'lockMap_x'} ne "" && $config{'lockMap_y'} ne "") {
				PrintMessage("Calculating lockMap route to: $maps_lut{$config{'lockMap'}.'.rsw'}($config{'lockMap'}): $config{'lockMap_x'}, $config{'lockMap_y'}.", "dark");
			} else {
				PrintMessage("Calculating lockMap route to: $maps_lut{$config{'lockMap'}.'.rsw'}($config{'lockMap'}).", "dark");
			}
			ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $config{'lockMap_x'}, $config{'lockMap_y'}, $config{'lockMap'}, 0, 0, 1, 0, 0, 1);
		}
	}

	Debug('AI lockMap');


	##### RANDOM WALK #####
	if ($AI && $config{'route_randomWalk'} && $ai_seq[0] eq "" && $currentChatRoom eq "" && @{$field{'field'}} > 1 && !$cities_lut{$field{'name'}.'.rsw'}) {
		do {
			$ai_v{'temp'}{'randX'} = int(rand() * ($field{'width'} - 1));
			$ai_v{'temp'}{'randY'} = int(rand() * ($field{'height'} - 1));
		} while ($field{'field'}[$ai_v{'temp'}{'randY'}*$field{'width'} + $ai_v{'temp'}{'randX'}]);
		PrintMessage("Calculating random route to: $maps_lut{$field{'name'}.'.rsw'}($field{'name'}): $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}.", "dark");
		ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $field{'name'}, 0, $config{'route_randomWalk_maxRouteTime'}, 2);
	}

	Debug('AI randomWalk');


	##### DEAD #####


	if ($ai_seq[0] eq "dead" && !$chars[$config{'char'}]{'dead'}) {
		shift @ai_seq;
		shift @ai_seq_args;

		if ($config{'teleportOnDead'}) {
			#force storage after death
			unshift @ai_seq, "storageAuto";
			unshift @ai_seq_args, {};
		}
	} elsif ($ai_seq[0] ne "dead" && $chars[$config{'char'}]{'dead'}) {
		undef @ai_seq;
		undef @ai_seq_args;
		unshift @ai_seq, "dead";
		unshift @ai_seq_args, {};
	}

	if ($ai_seq[0] eq "dead" && time - $chars[$config{'char'}]{'dead_time'} >= $timeout{'ai_dead_respawn'}{'timeout'}) {
		# Teleport on dead.
		if ($config{'teleportOnDead'} && !$chars[$config{'char'}]{'shop'}) {
			sendRespawn(\$remote_socket);
		}

		$chars[$config{'char'}]{'dead_time'} = time;
	}

	if ($ai_seq[0] eq "dead" && $config{'dcOnDeath'}) {
		DebugMessage("- Disconnecting on death!") if ($debug{'ai_dead'});
		$quit = 1;
	}

	Debug('AI dead');


	##### AUTO-ITEM USE #####

	if ($AI && ($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute"
		|| $ai_seq[0] eq "follow" || $ai_seq[0] eq "sitAuto" || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather"
		|| $ai_seq[0] eq "items_take" || $ai_seq[0] eq "attack")
		&& timeOut(\%{$timeout{'ai_item_use_auto'}})) {
		$i = 0;
		while (1) {
			last if (!$config{"useSelf_item_$i"});
			if (percent_hp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_item_$i"."_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_item_$i"."_hp_lower"}
				&& percent_sp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_item_$i"."_sp_upper"} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_item_$i"."_sp_lower"}
				&& !($config{"useSelf_item_$i"."_stopWhenHit"} && ai_getMonstersWhoHitMe())
				&& $config{"useSelf_item_$i"."_minAggressives"} <= ai_getAggressives()
				&& (!$config{"useSelf_item_$i"."_maxAggressives"} || $config{"useSelf_item_$i"."_maxAggressives"} >= ai_getAggressives())
				&& ($config{"useSelf_item_$i"."_useWhenStatus"} eq "" || GotStatus($chars[$config{'char'}], $config{"useSelf_item_$i"."_useWhenStatus"}))) {

				undef $ai_v{'temp'}{'invIndex'};
				if ($config{"useSelf_item_$i"."_monsters"} ne "") {
					foreach (@monstersID) {
						next if ($_ eq "");
						if (existsInList($config{"useSelf_item_$i"."_monsters"}, $monsters{$_}{'name'})) {
							$ai_v{'temp'}{'invIndex'} = findIndexStringList_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"useSelf_item_$i"});
							last;
						}
					}
				} else {
					$ai_v{'temp'}{'invIndex'} = findIndexStringList_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"useSelf_item_$i"});
				}

				if ($ai_v{'temp'}{'invIndex'} ne "") {
					if ($config{"useSelf_item_$i"."_useWhenNoEffects"} eq "") {
						$timeout{'ai_item_use_auto'}{'time'} = time;
						PrintMessage(qq~Auto-item use: $items_lut{$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'nameID'}}~, "brown");
						sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $accountID);
						last;
					} elsif (timeOut(\%{$timeout{'ai_item_use_auto_on_effect'}}) && NoEffectInList($config{"useSelf_item_$i"."_useWhenNoEffects"})) {
						$timeout{'ai_item_use_auto_on_effect'}{'time'} = time;
						PrintMessage(qq~Auto-item use on effect: $items_lut{$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'nameID'}}~, "brown");
						sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $accountID);
						last;
					}
				}
			}
			$i++;
		}
	}


	Debug('AI itemUseAuto');

	##### AUTO-EQUIP #####

	if ($AI && ($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute"
		|| $ai_seq[0] eq "follow" || $ai_seq[0] eq "sitAuto" || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather"
		|| $ai_seq[0] eq "items_take" || $ai_seq[0] eq "attack")) {

		undef $ai_v{'temp'}{'monster'};
		$ai_v{'temp'}{'ai_attack_index'} = binFind(\@ai_seq, "attack");

		if ($ai_v{'temp'}{'ai_attack_index'} ne "" && $ai_seq_args[$ai_v{'temp'}{'ai_attack_index'}]{'ID'} ne "" && %{$monsters{$ai_seq_args[$ai_v{'temp'}{'ai_attack_index'}]{'ID'}}}) {
			$ai_v{'temp'}{'monster'} = $monsters{$ai_seq_args[$ai_v{'temp'}{'ai_attack_index'}]{'ID'}}{'name'};
		}

		if ($chars[$config{'char'}]{'wait_equip_slot'} ne "") {
			if (IsEquipedSlot($chars[$config{'char'}]{'wait_equip_slot'}) == 1) {
				$chars[$config{'char'}]{'equip_slot'} = $chars[$config{'char'}]{'wait_equip_slot'};

				if ($chars[$config{'char'}]{'equip_slot'} eq "def") {
					PrintMessage("Default slot is equiped.", "white");
				} else {
					PrintMessage("Slot $chars[$config{'char'}]{'equip_slot'} is equiped.", "white");
				}

				undef $chars[$config{'char'}]{'wait_equip_slot'};
			} elsif (timeOut(\%{$timeout{'ai_equip_auto'}})) {
				PrintMessage("Retry equip slot $chars[$config{'char'}]{'wait_equip_slot'}.", "dark");
				EquipSlot($chars[$config{'char'}]{'wait_equip_slot'});
				$timeout{'ai_equip_auto'}{'time'} = time;
			}
		} else {
			$ai_v{'temp'}{'default'} = 1;
			$i = 0;
			while (IsEquipSlot($i)) {
				if (($config{"equipAuto_$i"."_monsters"} eq "" || existsInList($config{"equipAuto_$i"."_monsters"}, $ai_v{'temp'}{'monster'})) &&
					percent_hp(\%{$chars[$config{'char'}]}) <= $config{"equipAuto_$i"."_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{"equipAuto_$i"."_hp_lower"} &&
					percent_sp(\%{$chars[$config{'char'}]}) <= $config{"equipAuto_$i"."_sp_upper"} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{"equipAuto_$i"."_sp_lower"} &&
					$config{"equipAuto_$i"."_minAggressives"} <= ai_getAggressives() &&
					(!$config{"equipAuto_$i"."_maxAggressives"} || $config{"equipAuto_$i"."_maxAggressives"} >= ai_getAggressives())) {
					if ($chars[$config{'char'}]{'equip_slot'} ne "$i") {
						$chars[$config{'char'}]{'wait_equip_slot'} = $i;
						PrintMessage("Auto-equip slot $i.", "brown");
						EquipSlot($i);
						$timeout{'ai_equip_auto'}{'time'} = time;
					}

					$ai_v{'temp'}{'default'} = 0;
					last;
				}
				$i++;
			}

			if ($ai_v{'temp'}{'default'} && $chars[$config{'char'}]{'equip_slot'} ne "def") {
				$chars[$config{'char'}]{'wait_equip_slot'} = "def";
				PrintMessage("Auto-equip default slot.", "brown");
				EquipSlot("def");
				$timeout{'ai_equip_auto'}{'time'} = time;
			}
		}
	}


	Debug('AI equipAuto');


	##### AUTO-SKILL USE #####

	if ($AI && ($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute"
		|| $ai_seq[0] eq "follow" || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather"
		|| $ai_seq[0] eq "items_take" || $ai_seq[0] eq "attack" || $ai_seq[0] eq "sitAuto")) {
		$i = 0;
		undef $ai_v{'useSelf_skill'};
		undef $ai_v{'useSelf_skill_lvl'};

		while (1) {
			last if (!$config{"useSelf_skill_$i"});

			if (percent_hp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_skill_$i"."_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_skill_$i"."_hp_lower"}
				&& percent_sp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_skill_$i"."_sp_upper"} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_skill_$i"."_sp_lower"}
				&& $chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc($config{"useSelf_skill_$i"})}}{$config{"useSelf_skill_$i"."_lvl"}}
				&& timeOut($config{"useSelf_skill_$i"."_timeout"}, $ai_v{"useSelf_skill_$i"."_time"})
				&& !($config{"useSelf_skill_$i"."_stopWhenHit"} && ai_getMonstersWhoHitMe())
				&& $config{"useSelf_skill_$i"."_minAggressives"} <= ai_getAggressives()
				&& (!$config{"useSelf_skill_$i"."_maxAggressives"} || $config{"useSelf_skill_$i"."_maxAggressives"} > ai_getAggressives())
				&& ($config{"useSelf_skill_$i"."_useWhenStatus"} eq "" || GotStatus($chars[$config{'char'}], $config{"useSelf_skill_$i"."_useWhenStatus"}))
				&& ($ai_seq[0] ne "attack" || $config{"useSelf_skill_$i"."_useWhenAttack"})
				&& ($ai_seq[0] ne "sitAuto" || $config{"useSelf_skill_$i"."_useWhenSit"})
				&& ($config{"useSelf_skill_$i"."_count"} eq "" || $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"useSelf_skill_$i"})}}{'count'} < $config{"useSelf_skill_$i"."_count"})) {

				undef $ai_v{'temp'}{'use'};
				if ($config{"useSelf_skill_$i"."_monsters"} ne "") {
					foreach (@monstersID) {
						next if ($_ eq "");
						if (existsInList($config{"useSelf_skill_$i"."_monsters"}, $monsters{$_}{'name'})) {
							$ai_v{'temp'}{'use'} = 1;
							last;
						}
					}
				} else {
					$ai_v{'temp'}{'use'} = 1;
				}

				if ($ai_v{'temp'}{'use'}) {
					if ($config{"useSelf_skill_$i"."_useWhenNoEffects"} eq "") {
						$ai_v{"useSelf_skill_$i"."_time"} = time;
						$ai_v{'useSelf_skill'} = $config{"useSelf_skill_$i"};
						$ai_v{'useSelf_skill_lvl'} = $config{"useSelf_skill_$i"."_lvl"};
						$ai_v{'useSelf_skill_maxCastTime'} = $config{"useSelf_skill_$i"."_maxCastTime"};
						$ai_v{'useSelf_skill_minCastTime'} = $config{"useSelf_skill_$i"."_minCastTime"};
						last;
					} elsif (timeOut(\%{$timeout{'ai_skill_use_on_effect'}}) && NoEffectInList($config{"useSelf_skill_$i"."_useWhenNoEffects"})) {
						$timeout{'ai_skill_use_on_effect'}{'time'} = time;
						$ai_v{"useSelf_skill_$i"."_time"} = time;
						$ai_v{'useSelf_skill'} = $config{"useSelf_skill_$i"};
						$ai_v{'useSelf_skill_lvl'} = $config{"useSelf_skill_$i"."_lvl"};
						$ai_v{'useSelf_skill_maxCastTime'} = $config{"useSelf_skill_$i"."_maxCastTime"};
						$ai_v{'useSelf_skill_minCastTime'} = $config{"useSelf_skill_$i"."_minCastTime"};
						last;
					}
				}
			}
			$i++;
		}
		if ($config{'useSelf_skill_smartHeal'} && $skills_rlut{lc($ai_v{'useSelf_skill'})} eq "AL_HEAL") {
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
			PrintMessage(qq~Auto-skill on self: $skills_lut{$skills_rlut{lc($ai_v{'useSelf_skill'})}} (LV.$ai_v{'useSelf_skill_lvl'}).~, "brown");
			if ($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useSelf_skill'})}}{'use'} == 2) {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useSelf_skill'})}}{'ID'}, $ai_v{'useSelf_skill_lvl'}, $ai_v{'useSelf_skill_maxCastTime'}, $ai_v{'useSelf_skill_minCastTime'}, 0, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
			} else {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useSelf_skill'})}}{'ID'}, $ai_v{'useSelf_skill_lvl'}, $ai_v{'useSelf_skill_maxCastTime'}, $ai_v{'useSelf_skill_minCastTime'}, 0, $accountID);
			}
		}
	}

	Debug('AI skillUseAuto');

	##### SKILL USE #####

	if ($ai_seq[0] eq "skill_use" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_skill_use_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		$ai_seq_args[0]{'ai_skill_use_minCastTime'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		$ai_seq_args[0]{'ai_skill_use_maxCastTime'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "skill_use") {
		if ($currentChatRoom ne "") {
			sendChatRoomLeave(\$remote_socket);
			ai_setSuspend(0);
			stand();
		} elsif ($chars[$config{'char'}]{'shop'}) {
			shift @ai_seq;
			shift @ai_seq_args;
		} elsif ($chars[$config{'char'}]{'sitting'}) {
			ai_setSuspend(0);
			stand();
		} elsif (!$chars[$config{'char'}]{'skills'}{$skillsID_lut{$ai_seq_args[0]{'skill_use_id'}}{'nameID'}}{'lv'}) {
			shift @ai_seq;
			shift @ai_seq_args;
		} elsif (!$ai_seq_args[0]{'skill_used'} && timeOut(\%{$timeout{'ai_skill_use_resend'}}) && timeOut(\%{$timeout_ex{'skill_use_waitBeforeNextUse'}})) {
			sendAttackStop(\$remote_socket);

			if ($ai_seq_args[0]{'skill_use_target_x'} ne "") {
				sendSkillUseLoc(\$remote_socket, $ai_seq_args[0]{'skill_use_id'}, $ai_seq_args[0]{'skill_use_lv'}, $ai_seq_args[0]{'skill_use_target_x'}, $ai_seq_args[0]{'skill_use_target_y'});
			} else {
				sendSkillUse(\$remote_socket, $ai_seq_args[0]{'skill_use_id'}, $ai_seq_args[0]{'skill_use_lv'}, $ai_seq_args[0]{'skill_use_target'});
			}

			$chars[$config{'char'}]{'last_skill_send'} = $ai_seq_args[0]{'skill_use_id'};

			$timeout{'ai_skill_use_resend'}{'time'} = time;

			if ($ai_seq_args[0]{'skill_use_target'} eq $accountID) {
				$ai_seq_args[0]{'target'} = 0;
			} elsif (%{$players{$ai_seq_args[0]{'skill_use_target'}}}) {
				$ai_seq_args[0]{'target'} = 2;
			} else {
				$ai_seq_args[0]{'target'} = 1;
			}

			$ai_seq_args[0]{'skill_used'} = 1;
			$ai_seq_args[0]{'skill_count'}++;
			$ai_seq_args[0]{'ai_skill_use_giveup'}{'time'} = time;
			$ai_seq_args[0]{'skill_use_maxCastTime'}{'time'} = time;
			$ai_seq_args[0]{'skill_use_minCastTime'}{'time'} = time;
			$ai_seq_args[0]{'skill_use_last'} = $chars[$config{'char'}]{'skills'}{$skillsID_lut{$ai_seq_args[0]{'skill_use_id'}}{'nameID'}}{'time_used'};
#		} elsif (($ai_seq_args[0]{'skill_use_last'} != $chars[$config{'char'}]{'skills'}{$skillsID_lut{$ai_seq_args[0]{'skill_use_id'}}{'nameID'}}{'time_used'}
#			|| (timeOut(\%{$ai_seq_args[0]{'ai_skill_use_giveup'}}) && (!$chars[$config{'char'}]{'last_time_cast'} || !$ai_seq_args[0]{'skill_use_maxCastTime'}{'timeout'}))
#			|| ($ai_seq_args[0]{'skill_use_maxCastTime'}{'timeout'} && timeOut(\%{$ai_seq_args[0]{'skill_use_maxCastTime'}})))
#			&& timeOut(\%{$ai_seq_args[0]{'skill_use_minCastTime'}})) {
		} elsif ($chars[$config{'char'}]{'last_skill_used'} == $ai_seq_args[0]{'skill_use_id'} || $chars[$config{'char'}]{'last_skill_failed'}) {
			if ($chars[$config{'char'}]{'last_skill_failed'}) {
				$ai_v{'temp'}{'ai_attack_index'} = binFind(\@ai_seq, "attack");
				if ($ai_v{'temp'}{'ai_attack_index'} ne "") {
					$i = $ai_seq_args[$ai_v{'temp'}{'ai_attack_index'}]{'attackSkillSlot'};
					$ai_seq_args[$ai_v{'temp'}{'ai_attack_index'}]{'attackSkillSlot_wait'}{$i}{'timeout'} = 0;
				}
			}

			$timeout_ex{'skill_use_waitBeforeNextUse'}{'time'} = time;
			undef $chars[$config{'char'}]{'last_skill_cast'};
			undef $chars[$config{'char'}]{'last_skill_used'};
			undef $chars[$config{'char'}]{'last_skill_target'};
			undef $chars[$config{'char'}]{'last_skill_failed'};
			shift @ai_seq;
			shift @ai_seq_args;
		} elsif ($ai_seq_args[0]{'skill_use_target_x'} eq "" && $ai_seq_args[0]{'target'} == 1 && !%{$monsters{$ai_seq_args[0]{'skill_use_target'}}}) {
			shift @ai_seq;
			shift @ai_seq_args;
		} elsif ($ai_seq_args[0]{'skill_use_target_x'} eq "" && $ai_seq_args[0]{'target'} == 2 && !%{$players{$ai_seq_args[0]{'skill_use_target'}}}) {
			shift @ai_seq;
			shift @ai_seq_args;
		} elsif ($ai_seq_args[0]{'skill_use_target_x'} eq "" && $ai_seq_args[0]{'target'} == 2 && $players{$ai_seq_args[0]{'skill_use_target'}}{'dead'} && $ai_seq_args[0]{'skill_use_id'} != 54) {
			shift @ai_seq;
			shift @ai_seq_args;
		} elsif (!$chars[$config{'char'}]{'last_skill_cast'}) {
			if ($ai_seq_args[0]{'skill_count'} > 20) {
				shift @ai_seq;
				shift @ai_seq_args;
			} else {
				$ai_seq_args[0]{'skill_used'} = 0;
			}
		} elsif ($ai_seq_args[0]{'skill_use_maxCastTime'}{'timeout'} &&
			timeOut(\%{$ai_seq_args[0]{'skill_use_maxCastTime'}}) &&
			timeOut(\%{$ai_seq_args[0]{'skill_use_minCastTime'}})) {
			shift @ai_seq;
			shift @ai_seq_args;
		} elsif (!$ai_seq_args[0]{'skill_use_maxCastTime'}{'timeout'} &&
			timeOut(\%{$ai_seq_args[0]{'ai_skill_use_giveup'}})) {
			shift @ai_seq;
			shift @ai_seq_args;
		}
	}

	Debug('AI skillUse');


	##### PARTY-SKILL #####

	if ($AI && ($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute"
		|| $ai_seq[0] eq "follow" || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather"
		|| $ai_seq[0] eq "items_take" || $ai_seq[0] eq "attack" || $ai_seq[0] eq "sitAuto")) {

		$i = 0;
		while (1) {
			last if (!$config{"partyPmSkill_$i"});

			if (percent_hp(\%{$chars[$config{'char'}]}) <= $config{"partyPmSkill_$i"."_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{"partyPmSkill_$i"."_hp_lower"}
				&& percent_sp(\%{$chars[$config{'char'}]}) <= $config{"partyPmSkill_$i"."_sp_upper"} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{"partyPmSkill_$i"."_sp_lower"}
				&& $chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc($config{"partyPmSkill_$i"})}}{$config{"partyPmSkill_$i"."_lvl"}}
				&& $config{"partyPmSkill_$i"."_minAggressives"} <= ai_getAggressives()
				&& (!$config{"partyPmSkill_$i"."_maxAggressives"} || $config{"partyPmSkill_$i"."_maxAggressives"} > ai_getAggressives())
				&& ($config{"partyPmSkill_$i"."_useWhenStatus"} eq "" || GotStatus($chars[$config{'char'}], $config{"partyPmSkill_$i"."_useWhenStatus"}))
				&& ($config{"partyPmSkill_$i"."_useWhenNoEffects"} eq "" || NoEffectInList($config{"partyPmSkill_$i"."_useWhenNoEffects"}))
				&& ($ai_seq[0] ne "attack" || $config{"partyPmSkill_$i"."_useWhenAttack"})
				&& ($ai_seq[0] ne "sitAuto" || $config{"partyPmSkill_$i"."_useWhenSit"})) {

				undef $ai_v{'temp'}{'use'};
				if ($config{"partyPmSkill_$i"."_monsters"} ne "") {
					foreach (@monstersID) {
						next if ($_ eq "");
						if (existsInList($config{"partyPmSkill_$i"."_monsters"}, $monsters{$_}{'name'})) {
							$ai_v{'temp'}{'use'} = 1;
							last;
						}
					}
				} else {
					$ai_v{'temp'}{'use'} = 1;
				}

				if ($ai_v{'temp'}{'use'}) {
					for ($j = 0; $j < @partyUsersID; $j++) {
						next if ($partyUsersID[$j] eq "");
						if ($partyUsersID[$j] ne $accountID) {
							if (IsPartyName($partyUsersID[$j], $config{"partyPmSkill_$i"."_player"}) &&
								IsPartyMap($partyUsersID[$j], $field{'name'}) &&
								IsPartyOnline($partyUsersID[$j])) {

								if (%{$players{$partyUsersID[$j]}}) {
									$ai_v{'temp'}{'distance'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$partyUsersID[$j]}{'pos_to'}});
								} else {
									$ai_v{'temp'}{'distance'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$j]}{'pos'}});
								}

								if ($ai_v{'temp'}{'distance'} <= $config{"partyPmSkill_$i"."_distance"}) {
									PrintMessage(qq~Auto-pm-skill on party: $config{"partyPmSkill_$i"}.~, "brown");
									sendMessage(\$remote_socket, "pm", $config{"partyPmSkill_$i"}, $config{"partyPmSkill_$i"."_player"});
									ai_clientSuspend(0, $config{"partyPmSkill_$i"."_waitAfterPm"});
								} elsif ($config{"partyPmSkill_$i"."_walkToPlayer"} && binFind(\@ai_seq, "follow") eq "" && !%{$players{$partyUsersID[$j]}}) {
									PrintMessage("Follow ".$config{"partyPmSkill_$i"."_player"}." to PM skill ".$config{"partyPmSkill_$i"}.".", "brown");
									ai_follow($config{"partyPmSkill_$i"."_player"}, 1);
								} elsif ($config{"partyPmSkill_$i"."_walkToPlayer"} && binFind(\@ai_seq, "route") eq "" && %{$players{$partyUsersID[$j]}}) {
									$ai_v{'temp'}{'map'} = $field{'name'};
									$ai_v{'temp'}{'x'} = $players{$partyUsersID[$j]}{'pos_to'}{'x'};
									$ai_v{'temp'}{'y'} = $players{$partyUsersID[$j]}{'pos_to'}{'y'};

									PrintMessage("Calculating PM skill route to: $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}.", "dark");
									ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
								}

								last;
							}
						}
					}

					last;
				}
			}

			$i++;
		}
	}

	##### AUTO RESPONSE #####

	if ($currentChatRoom eq "" && $config{'randomTalk'} && timeOut(\%{$timeout{'ai_randomTalk'}})) {
		$timeout{'ai_randomTalk'}{'time'} = time;
		sendMessage(\$remote_socket, "c", getResponse("randomTalkS"), "");
	}

	if ($ai_seq[0] eq "respAuto" && $ai_seq_args[0]{'suspended'}) {
		undef $ai_seq_args[0]{'suspended'};
	}

	if ($ai_seq[0] eq "respAuto") {
		$ai_v{'temp'}{'user'} = $ai_seq_args[0]{'user'};
		$ai_v{'temp'}{'cmd'} = $ai_seq_args[0]{'cmd'};
		$ai_v{'temp'}{'chattype'} = $ai_seq_args[0]{'chattype'};
		$ai_v{'temp'}{'count'} = $respAuto{'user'}{$ai_v{'temp'}{'user'}}{lc($ai_v{'temp'}{'cmd'})."_count"};
		$ai_v{'temp'}{'count'}++;

		if (!$ai_seq_args[0]{'wait'}) {
			undef $respAuto{'msg'};

			$responseVars{'resp_count'} = $ai_v{'temp'}{'count'};
			if ($ai_seq_args[0]{'cmd'} eq "_HEAL") {
				if ($config{'respHeal'}) {
					if ($chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'} > 0) {
						$ai_v{'temp'}{'percent'} = percent_sp(\%{$chars[$config{'char'}]});
						if ($ai_v{'temp'}{'percent'} >= $config{'respHeal_sp'}) {
							$ai_v{'temp'}{'id'} = ai_getID(\%players, $ai_v{'temp'}{'user'});
							if ($ai_v{'temp'}{'id'} ne "") {
								$responseVars{'heal_count'} = $config{'respHeal_count'};
								$respAuto{'msg'} = getResponseCount("_healRespS", $ai_v{'temp'}{'count'});
							} else {
								undef $ai_seq_args[0]{'cmd'};
								$respAuto{'msg'} = getResponseCount("_healRespF1", $ai_v{'temp'}{'count'});
							}
						} else {
							undef $ai_seq_args[0]{'cmd'};
							$respAuto{'msg'} = getResponseCount("_healRespF2", $ai_v{'temp'}{'count'});
						}
					} else {
						undef $ai_seq_args[0]{'cmd'};
						$respAuto{'msg'} = getResponseCount("_healRespF3", $ai_v{'temp'}{'count'});
					}
				} else {
					undef $ai_seq_args[0]{'cmd'};
					$respAuto{'msg'} = getResponseCount("_healRespF4", $ai_v{'temp'}{'count'});
				}
			} elsif ($ai_seq_args[0]{'cmd'} eq "_AGI") {
				if ($config{'respAgi'}) {
					if ($chars[$config{'char'}]{'skills'}{'AL_INCAGI'}{'lv'} > 0) {
						$ai_v{'temp'}{'percent'} = percent_sp(\%{$chars[$config{'char'}]});
						if ($ai_v{'temp'}{'percent'} >= $config{'respAgi_sp'}) {
							$ai_v{'temp'}{'id'} = ai_getID(\%players, $ai_v{'temp'}{'user'});
							if ($ai_v{'temp'}{'id'} ne "") {
								$respAuto{'msg'} = getResponseCount("_agiRespS", $ai_v{'temp'}{'count'});
							} else {
								undef $ai_seq_args[0]{'cmd'};
								$respAuto{'msg'} = getResponseCount("_agiRespF1", $ai_v{'temp'}{'count'});
							}
						} else {
							undef $ai_seq_args[0]{'cmd'};
							$respAuto{'msg'} = getResponseCount("_agiRespF2", $ai_v{'temp'}{'count'});
						}
					} else {
						undef $ai_seq_args[0]{'cmd'};
						$respAuto{'msg'} = getResponseCount("_agiRespF3", $ai_v{'temp'}{'count'});
					}
				} else {
					undef $ai_seq_args[0]{'cmd'};
					$respAuto{'msg'} = getResponseCount("_agiRespF4", $ai_v{'temp'}{'count'});
				}
			} elsif ($ai_seq_args[0]{'cmd'} eq "_BLESS") {
				if ($config{'respBless'}) {
					if ($chars[$config{'char'}]{'skills'}{'AL_BLESSING'}{'lv'} > 0) {
						$ai_v{'temp'}{'percent'} = percent_sp(\%{$chars[$config{'char'}]});
						if ($ai_v{'temp'}{'percent'} >= $config{'respBless_sp'}) {
							$ai_v{'temp'}{'id'} = ai_getID(\%players, $ai_v{'temp'}{'user'});
							if ($ai_v{'temp'}{'id'} ne "") {
								$respAuto{'msg'} = getResponseCount("_blessRespS", $ai_v{'temp'}{'count'});
							} else {
								undef $ai_seq_args[0]{'cmd'};
								$respAuto{'msg'} = getResponseCount("_blessRespF1", $ai_v{'temp'}{'count'});
							}
						} else {
							undef $ai_seq_args[0]{'cmd'};
							$respAuto{'msg'} = getResponseCount("_blessRespF2", $ai_v{'temp'}{'count'});
						}
					} else {
						undef $ai_seq_args[0]{'cmd'};
						$respAuto{'msg'} = getResponseCount("_blessRespF3", $ai_v{'temp'}{'count'});
					}
				} else {
					undef $ai_seq_args[0]{'cmd'};
					$respAuto{'msg'} = getResponseCount("_blessRespF4", $ai_v{'temp'}{'count'});
				}
			} elsif ($ai_seq_args[0]{'cmd'} eq "AGI") {
				$responseVars{'char_agi'} = $chars[$config{'char'}]{'agi'};
				$respAuto{'msg'} = getResponseCount("agiRespS", $ai_v{'temp'}{'count'});
			} elsif ($ai_seq_args[0]{'cmd'} eq "LEVEL" && timeOut(\%{$timeout{'ai_respAuto_var'}})) {
				$responseVars{'char_level'} = $chars[$config{'char'}]{'lv'};
				$respAuto{'msg'} = getResponseCount("levelRespS", $ai_v{'temp'}{'count'});
			} else {
				$respAuto{'msg'} = getResponseCount(lc($ai_v{'temp'}{'cmd'})."RespS", $ai_v{'temp'}{'count'});
			}

			$timeout{'ai_randomTalk'}{'time'} = time;
			$respAuto{'wait'}{'time'} = time;
			$respAuto{'wait'}{'timeout'} = $config{'respAuto_typingRate'} * length($respAuto{'msg'});
			$ai_seq_args[0]{'wait'} = 1;
		} else {
			$responseVars{'resp_count'} = $ai_v{'temp'}{'count'};
			if ($ai_seq_args[0]{'cmd'} eq "_HEAL" && timeOut(\%{$respAuto{'wait'}})) {
				shift @ai_seq;
				shift @ai_seq_args;

				$ai_v{'temp'}{'id'} = ai_getID(\%players, $ai_v{'temp'}{'user'});
				if ($ai_v{'temp'}{'id'} ne "") {
					for ($i = 0; $i < $config{'respHeal_count'}; $i++) {
						ai_skillUse(28, $config{'respHeal_lv'}, 3, 1, 1, $ai_v{'temp'}{'id'});
					}

					$respAuto{'user'}{$ai_v{'temp'}{'user'}}{'_heal_time'} = time;
					$respAuto{'user'}{$ai_v{'temp'}{'user'}}{'_heal_count'}++;

					sendMessage(\$remote_socket, $ai_v{'temp'}{'chattype'}, $respAuto{'msg'}, $ai_v{'temp'}{'user'});
				}
			} elsif ($ai_seq_args[0]{'cmd'} eq "_AGI" && timeOut(\%{$respAuto{'wait'}})) {
				shift @ai_seq;
				shift @ai_seq_args;

				$ai_v{'temp'}{'id'} = ai_getID(\%players, $ai_v{'temp'}{'user'});
				if ($ai_v{'temp'}{'id'} ne "") {
					ai_skillUse(29, $config{'respAgi_lv'}, 3, 1, 0, $ai_v{'temp'}{'id'});

					$respAuto{'user'}{$ai_v{'temp'}{'user'}}{'_agi_time'} = time;
					$respAuto{'user'}{$ai_v{'temp'}{'user'}}{'_agi_count'}++;

					sendMessage(\$remote_socket, $ai_v{'temp'}{'chattype'}, $respAuto{'msg'}, $ai_v{'temp'}{'user'});
				}
			} elsif ($ai_seq_args[0]{'cmd'} eq "_BLESS" && timeOut(\%{$respAuto{'wait'}})) {
				shift @ai_seq;
				shift @ai_seq_args;

				$ai_v{'temp'}{'id'} = ai_getID(\%players, $ai_v{'temp'}{'user'});
				if ($ai_v{'temp'}{'id'} ne "") {
					ai_skillUse(34, $config{'respBless_lv'}, 3, 1, 0, $ai_v{'temp'}{'id'});

					$respAuto{'user'}{$ai_v{'temp'}{'user'}}{'_bless_time'} = time;
					$respAuto{'user'}{$ai_v{'temp'}{'user'}}{'_bless_count'}++;

					sendMessage(\$remote_socket, $ai_v{'temp'}{'chattype'}, $respAuto{'msg'}, $ai_v{'temp'}{'user'});
				}
			} elsif ($ai_seq_args[0]{'cmd'} eq "AGI" && timeOut(\%{$respAuto{'wait'}})) {
				shift @ai_seq;
				shift @ai_seq_args;

				$respAuto{'user'}{$ai_v{'temp'}{'user'}}{'agi_time'} = time;
				$respAuto{'user'}{$ai_v{'temp'}{'user'}}{'agi_count'}++;

				$responseVars{'char_agi'} = $chars[$config{'char'}]{'agi'};
				sendMessage(\$remote_socket, $ai_v{'temp'}{'chattype'}, $respAuto{'msg'}, $ai_v{'temp'}{'user'});
			} elsif ($ai_seq_args[0]{'cmd'} eq "LEVEL" && timeOut(\%{$respAuto{'wait'}})) {
				shift @ai_seq;
				shift @ai_seq_args;

				$respAuto{'user'}{$ai_v{'temp'}{'user'}}{'level_time'} = time;
				$respAuto{'user'}{$ai_v{'temp'}{'user'}}{'level_count'}++;

				$responseVars{'char_level'} = $chars[$config{'char'}]{'lv'};
				sendMessage(\$remote_socket, $ai_v{'temp'}{'chattype'}, $respAuto{'msg'}, $ai_v{'temp'}{'user'});
			} elsif (timeOut(\%{$respAuto{'wait'}})) {
				shift @ai_seq;
				shift @ai_seq_args;

				$respAuto{'user'}{$ai_v{'temp'}{'user'}}{lc($ai_v{'temp'}{'cmd'})."_time"} = time;
				$respAuto{'user'}{$ai_v{'temp'}{'user'}}{lc($ai_v{'temp'}{'cmd'})."_count"}++;

				sendMessage(\$remote_socket, $ai_v{'temp'}{'chattype'}, $respAuto{'msg'}, $ai_v{'temp'}{'user'});
			}
		}
	}

	Debug('AI respAuto');


	##### FOLLOW #####

	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route") && !binFind(\@ai_seq, "follow") && $config{'follow'}) {
		ai_follow($config{'followTarget'}, 0);
	}

	if ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'suspended'}) {
		if ($ai_seq_args[0]{'ai_follow_lost'}) {
			$ai_seq_args[0]{'ai_follow_lost_end'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		}
		undef $ai_seq_args[0]{'suspended'};
	}

	if ($ai_seq[0] eq "follow" && !$ai_seq_args[0]{'ai_follow_lost'}) {
		# Follow Party
		if (!$ai_seq_args[0]{'following'}) {
			undef $ai_seq_args[0]{'party'};

			foreach (keys %players) {
				if ($players{$_}{'name'} eq $ai_seq_args[0]{'name'} && !$players{$_}{'dead'}) {
					$ai_seq_args[0]{'ID'} = $_;
					$ai_seq_args[0]{'following'} = 1;

					if (IsPartyOnline($_)) {
						$ai_seq_args[0]{'party'} = 1;
					}
					last;
				}
			}

			if (!$ai_seq_args[0]{'following'}) {
				for ($i = 0; $i < @partyUsersID; $i++) {
					next if ($partyUsersID[$i] eq "");
					if ($partyUsersID[$i] ne $accountID) {
						if (IsPartyName($partyUsersID[$i], $ai_seq_args[0]{'name'}) && IsPartyMap($partyUsersID[$i], $field{'name'})) {
							$ai_seq_args[0]{'ID'} = $partyUsersID[$i];
							$ai_seq_args[0]{'party'} = 1;
							last;
						}
					}
				}

				if ($ai_seq_args[0]{'party'}) {
					if (%{$players{$ai_seq_args[0]{'ID'}}}) {
						$ai_seq_args[0]{'following'} = 1;
					} else {
						DebugMessage("- $ai_seq_args[0]{'name'} is lost.") if ($debug{'ai_follow'});
						$ai_seq_args[0]{'ai_follow_lost'} = 1;
						$ai_seq_args[0]{'ai_follow_lost_end'}{'timeout'} = $timeout{'ai_follow_lost_end'}{'timeout'};
						$ai_seq_args[0]{'ai_follow_lost_end'}{'time'} = time;
					}
				}
			}
		}

		if ($ai_seq_args[0]{'following'} && $ai_seq_args[0]{'stopWhenFound'}) {
			shift @ai_seq;
			shift @ai_seq_args;
		} elsif ($ai_seq_args[0]{'following'}) {
			if ($ai_seq_args[0]{'party'}) {
				#print "Follow party.\n";
				if (IsPartyMap($ai_seq_args[0]{'ID'}, $field{'name'}) && IsPartyMove($ai_seq_args[0]{'ID'})) {
					$ai_v{'temp'}{'distance'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'pos'}});
					if ($ai_v{'temp'}{'distance'} > $config{'followLostDistance'}) {
						DebugMessage("- $ai_seq_args[0]{'name'} is lost. How does he do?") if ($debug{'ai_follow'});
						undef $ai_seq_args[0]{'following'};
						$ai_seq_args[0]{'ai_follow_lost'} = 1;
						$ai_seq_args[0]{'ai_follow_lost_end'}{'timeout'} = $timeout{'ai_follow_lost_end'}{'timeout'};
						$ai_seq_args[0]{'ai_follow_lost_end'}{'time'} = time;
					} elsif ($ai_v{'temp'}{'distance'} > $config{'followDistanceMax'}) {
						ai_route(\%{$ai_seq_args[0]{'ai_route_returnHash'}}, $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'pos'}{'x'}, $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'pos'}{'y'}, $field{'name'}, 0, 0, 1, 0, $config{'followDistanceMin'});
					}
				}
			} elsif (%{$players{$ai_seq_args[0]{'ID'}}} && $players{$ai_seq_args[0]{'ID'}}{'pos_to'}) {
				#print "Follow $players{$ai_seq_args[0]{'ID'}}{'name'}\n";
				$ai_v{'temp'}{'distance'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$ai_seq_args[0]{'ID'}}{'pos_to'}});
				#print "DISTANCE = $ai_v{'temp'}{'distance'} $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'} to $players{$ai_seq_args[0]{'ID'}}{'name'} at $players{$ai_seq_args[0]{'ID'}}{'pos_to'}{'x'}, $players{$ai_seq_args[0]{'ID'}}{'pos_to'}{'y'}\n";
				if ($ai_v{'temp'}{'distance'} > $config{'followDistanceMax'}) {
					ai_route(\%{$ai_seq_args[0]{'ai_route_returnHash'}}, $players{$ai_seq_args[0]{'ID'}}{'pos_to'}{'x'}, $players{$ai_seq_args[0]{'ID'}}{'pos_to'}{'y'}, $field{'name'}, 0, 0, 1, 0, $config{'followDistanceMin'});
				}
			}

			if ($config{'followTank'} && %{$players{$ai_seq_args[0]{'ID'}}}) {
				if ($players{$ai_seq_args[0]{'ID'}}{'sitting'} && !$chars[$config{'char'}]{'sitting'}) {
					sit();
				} elsif (!$players{$ai_seq_args[0]{'ID'}}{'sitting'} && $chars[$config{'char'}]{'sitting'}) {
					PrintMessage("Let's go!", "dark");
					stand();
				}
			} elsif (%{$players{$ai_seq_args[0]{'ID'}}} && $players{$ai_seq_args[0]{'ID'}}{'sitting'} && !$chars[$config{'char'}]{'sitting'}) {
				sit();
			}
		}
	}

	if ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'following'} && ((%{$players{$ai_seq_args[0]{'ID'}}} && $players{$ai_seq_args[0]{'ID'}}{'dead'}) || $players_old{$ai_seq_args[0]{'ID'}}{'dead'})) {
		DebugMessage("- $ai_seq_args[0]{'name'} died.  I'll wait here.") if ($debug{'ai_follow'});
		undef $ai_seq_args[0]{'following'};
	} elsif ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'following'} && !%{$players{$ai_seq_args[0]{'ID'}}}) {
		DebugMessage("- I lost $ai_seq_args[0]{'name'}.") if ($debug{'ai_follow'});
		undef $ai_seq_args[0]{'following'};
		if ($players_old{$ai_seq_args[0]{'ID'}}{'disconnected'}) {
			DebugMessage("- $ai_seq_args[0]{'name'} is disconnected.") if ($debug{'ai_follow'});
		} elsif ($players_old{$ai_seq_args[0]{'ID'}}{'disappeared'}) {
			DebugMessage("- Trying to find $ai_seq_args[0]{'name'}.") if ($debug{'ai_follow'});
			undef $ai_seq_args[0]{'ai_follow_lost_char_last_pos'};
			undef $ai_seq_args[0]{'follow_lost_portal_tried'};
			$ai_seq_args[0]{'ai_follow_lost'} = 1;
			$ai_seq_args[0]{'ai_follow_lost_end'}{'timeout'} = $timeout{'ai_follow_lost_end'}{'timeout'};
			$ai_seq_args[0]{'ai_follow_lost_end'}{'time'} = time;
			getVector(\%{$ai_seq_args[0]{'ai_follow_lost_vec'}}, \%{$players_old{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$chars[$config{'char'}]{'pos_to'}});

			#check if player went through portal
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
		} else {
			DebugMessage("- Don't know what happened to $ai_seq_args[0]{'name'}.") if ($debug{'ai_follow'});
		}
	}

	Debug('AI follow');

	##### FOLLOW-LOST #####

	# Follow Party
	if ($ai_seq[0] eq "route" || $ai_seq[0] eq "move") {
		$ai_v{'temp'}{'ai_follow_index'} = binFind(\@ai_seq, "follow");

		if ($ai_v{'temp'}{'ai_follow_index'} ne "" && $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'ai_follow_lost'} && $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'party'}) {
			$ai_v{'temp'}{'ai_follow_id'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'ID'};
			$ai_v{'temp'}{'ai_follow_name'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'name'};

			if (%{$players{$ai_v{'temp'}{'ai_follow_id'}}}) {
				$ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'following'} = 1;
				undef $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'ai_follow_lost'};
				undef $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'ai_follow_lost_party_last_pos'};

				aiRemove("move");
				aiRemove("route");
				aiRemove("route_getRoute");
				aiRemove("route_getMapRoute");

				DebugMessage("- Found $ai_v{'temp'}{'ai_follow_name'} on move!") if ($debug{'ai_follow'});
			} elsif (IsPartyMap($ai_v{'temp'}{'ai_follow_id'}, $field{'name'}) && IsPartyMove($ai_v{'temp'}{'ai_follow_id'})) {
				%{$ai_v{'temp'}{'pos'}} = %{$ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'ai_follow_lost_party_last_pos'}};
				%{$ai_v{'temp'}{'pos_to'}} = %{$chars[$config{'char'}]{'party'}{'users'}{$ai_v{'temp'}{'ai_follow_id'}}{'pos'}};
				$ai_v{'temp'}{'distance'} = distance(\%{$ai_v{'temp'}{'pos'}}, \%{$ai_v{'temp'}{'pos_to'}});

				if ($ai_v{'temp'}{'distance'} > 7) {
					# Recalculate route when party move more than 7 block.
					DebugMessage("- $ai_v{'temp'}{'ai_follow_name'} move from ($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}) to ($ai_v{'temp'}{'pos_to'}{'x'}, $ai_v{'temp'}{'pos_to'}{'y'}), DISTANCE: $ai_v{'temp'}{'distance'}") if ($debug{'ai_follow'});
					DebugMessage("- Change move to $ai_v{'temp'}{'ai_follow_name'} ($ai_v{'temp'}{'pos_to'}{'x'}, $ai_v{'temp'}{'pos_to'}{'y'})") if ($debug{'ai_follow'});
					%{$ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'ai_follow_lost_party_last_pos'}} = %{$ai_v{'temp'}{'pos_to'}};

					aiRemove("move");
					aiRemove("route");
					aiRemove("route_getRoute");
					aiRemove("route_getMapRoute");

					ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'pos_to'}{'x'}, $ai_v{'temp'}{'pos_to'}{'y'}, $field{'name'}, 0, 0, 1);
				}
			} else {
				undef $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'ai_follow_lost'};
				DebugMessage("- $ai_v{'temp'}{'ai_follow_name'} lost on move.") if ($debug{'ai_follow'});
			}
		}
	}

	if ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'ai_follow_lost'}) {
		if ($ai_seq_args[0]{'ai_follow_lost_char_last_pos'}{'x'} == $chars[$config{'char'}]{'pos_to'}{'x'} && $ai_seq_args[0]{'ai_follow_lost_char_last_pos'}{'y'} == $chars[$config{'char'}]{'pos_to'}{'y'}) {
			$ai_seq_args[0]{'lost_stuck'}++;
		} else {
			undef $ai_seq_args[0]{'lost_stuck'};
		}
		%{$ai_seq_args[0]{'ai_follow_lost_char_last_pos'}} = %{$chars[$config{'char'}]{'pos_to'}};

		# Follow Party
		if ($ai_seq_args[0]{'party'}) {
			if (IsPartyMap($ai_seq_args[0]{'ID'}, $field{'name'}) && IsPartyMove($ai_seq_args[0]{'ID'})) {
				if (%{$players{$ai_seq_args[0]{'ID'}}}) {
					$ai_seq_args[0]{'following'} = 1;
					undef $ai_seq_args[0]{'ai_follow_lost'};
					DebugMessage("- Found $ai_seq_args[0]{'name'} !") if ($debug{'ai_follow'});
				} elsif ($ai_seq_args[0]{'ai_follow_lost_party_last_pos'}{'x'} != $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'pos'}{'x'} ||
					$ai_seq_args[0]{'ai_follow_lost_party_last_pos'}{'y'} != $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'pos'}{'y'}) {
					undef $ai_seq_args[0]{'ai_follow_lost_party_last_pos'};

					%{$ai_v{'temp'}{'pos_to'}} = %{$chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'pos'}};
					DebugMessage("- Move to $ai_seq_args[0]{'name'} ($ai_v{'temp'}{'pos_to'}{'x'}, $ai_v{'temp'}{'pos_to'}{'y'})") if ($debug{'ai_follow'});

					%{$ai_seq_args[0]{'ai_follow_lost_party_last_pos'}} = %{$ai_v{'temp'}{'pos_to'}};
					ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'pos_to'}{'x'}, $ai_v{'temp'}{'pos_to'}{'y'}, $field{'name'}, 0, 0, 1);
				}
			} elsif (!IsPartyMap($ai_seq_args[0]{'ID'}, $field{'name'})) {
				undef $ai_v{'temp'}{'x'};
				undef $ai_v{'temp'}{'y'};
				($ai_v{'temp'}{'party_map'}) = $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'map'} =~ /([\s\S]*)\.gat/;
				DebugMessage("- Follow to map $ai_v{'temp'}{'party_map'}.") if ($debug{'ai_follow'});
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'party_map'}, 0, 0, 1, 0, 0, 1);
			}
		} elsif (timeOut(\%{$ai_seq_args[0]{'ai_follow_lost_end'}})) {
			undef $ai_seq_args[0]{'ai_follow_lost'};
			DebugMessage("- Couldn't find $ai_seq_args[0]{'name'}, giving up.") if ($debug{'ai_follow'});
		} elsif ($players_old{$ai_seq_args[0]{'ID'}}{'disconnected'}) {
			undef $ai_seq_args[0]{'ai_follow_lost'};
			DebugMessage("- $ai_seq_args[0]{'name'} is disconnected.") if ($debug{'ai_follow'});
		} elsif (%{$players{$ai_seq_args[0]{'ID'}}}) {
			$ai_seq_args[0]{'following'} = 1;
			undef $ai_seq_args[0]{'ai_follow_lost'};
			DebugMessage("- Found $ai_seq_args[0]{'name'} !") if ($debug{'ai_follow'});
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
				}
			} else {
				moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'ai_follow_lost_vec'}}, $config{'followLostStep'});
				move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
			}
		}
	}

	Debug('AI followLost');


	##### AUTO-CHATROOM #####
	if ($config{'chatRoomAuto'}) {
		if ($chars[$config{'char'}]{'sitting'} && $currentChatRoom eq "" && timeOut(\%{$timeout{'ai_chatRoom_create'}})) {
			$i = 0;
			while ($config{"chatRoomAuto_title_$i"} ne "") {
				$i++;
			}

			undef $ai_v{'temp'}{'title'};
			if ($i) {
				$i = (rand() * 100) % $i;
				$ai_v{'temp'}{'title'} = $config{"chatRoomAuto_title_$i"};
			}

			if ($ai_v{'temp'}{'title'} eq "") {
				$ai_v{'temp'}{'title'} = "KFC";
			}

			$createdChatRoom{'title'} = $ai_v{'temp'}{'title'};
			$createdChatRoom{'ownerID'} = $accountID;
			$createdChatRoom{'limit'} = $config{'chatRoomAuto_limit'};
			$createdChatRoom{'public'} = $config{'chatRoomAuto_public'};
			$createdChatRoom{'num_users'} = 1;
			$createdChatRoom{'users'}{$chars[$config{'char'}]{'name'}} = 2;
			sendChatRoomCreate(\$remote_socket, $ai_v{'temp'}{'title'}, $config{'chatRoomAuto_limit'}, $config{'chatRoomAuto_public'}, $config{'chatRoomAuto_password'});
			$timeout{'ai_chatRoom_create'}{'time'} = time;
		} elsif (!$chars[$config{'char'}]{'sitting'} && $currentChatRoom ne "") {
			sendChatRoomLeave(\$remote_socket);
		}
	}

	Debug('AI chatAuto');


	##### AUTO-SIT/SIT/STAND #####

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

	if (!$ai_v{'sitAuto_forceStop'} && ($ai_seq[0] eq "" || $ai_seq[0] eq "follow" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute")
		&& binFind(\@ai_seq, "attack") eq "" && binFind(\@ai_seq, "items_take") eq "" && !ai_getAggressives()
		&& (percent_hp(\%{$chars[$config{'char'}]}) < $config{'sitAuto_hp_lower'} || percent_sp(\%{$chars[$config{'char'}]}) < $config{'sitAuto_sp_lower'})) {
		unshift @ai_seq, "sitAuto";
		unshift @ai_seq_args, {};
		DebugMessage("- Auto-sitting.") if ($debug{'ai_autoSitStand'});
	}

	if (($ai_seq[0] eq "" || $ai_seq[0] eq "follow" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute") && $config{'tankMode'} && !$config{'tankModeParty'}) {
		undef $ai_v{'temp'}{'tank'};
		foreach (@playersID) {
			next if ($_ eq "");
			if ($config{'tankModeTarget'} eq $players{$_}{'name'}) {
				$ai_v{'temp'}{'tankID'} = $_;
				last;
			}
		}

		if (($ai_v{'temp'}{'tankID'} eq "" || $players{$ai_v{'temp'}{'tankID'}}{'sitting'}) && !$chars[$config{'char'}]{'sitting'}) {
			print "Waiting for $config{'tankModeTarget'}.\n";
			unshift @ai_seq, "sitAuto";
			unshift @ai_seq_args, {};
		}
	}

	if ($ai_seq[0] eq "sitAuto" && !$chars[$config{'char'}]{'sitting'} && $chars[$config{'char'}]{'skills'}{'NV_BASIC'}{'lv'} >= 3
		&& !ai_getAggressives()) {
		sit();
	}

	if ($ai_seq[0] eq "sitAuto" && $config{'tankMode'} && !$config{'tankModeParty'}) {
		undef $ai_v{'temp'}{'tank'};
		foreach (@playersID) {
			next if ($_ eq "");
			if ($config{'tankModeTarget'} eq $players{$_}{'name'}) {
				$ai_v{'temp'}{'tankID'} = $_;
				last;
			}
		}

		if ($ai_v{'temp'}{'tankID'} ne "" && !$players{$ai_v{'temp'}{'tankID'}}{'sitting'}) {
			print "Go! Go! Go!\n";
			shift @ai_seq;
			shift @ai_seq_args;
			if ($chars[$config{'char'}]{'sitting'}) {
				stand();
			}
		}
	} elsif ($ai_seq[0] eq "sitAuto" && ($ai_v{'sitAuto_forceStop'}
		|| (percent_hp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_hp_upper'} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_sp_upper'}))) {
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$config{'sitAuto_idle'} && $chars[$config{'char'}]{'sitting'}) {
			print "Ready!\n";
			stand();
		}
	} elsif ($ai_seq[0] eq "sitAuto" && ($chars[$config{'char'}]{'effect'}{35} || $chars[$config{'char'}]{'effect'}{36})) {
		shift @ai_seq;
		shift @ai_seq_args;
	}

	Debug('AI sit-stand');


	##### AUTO-ATTACK #####

	if ($AI && ($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute" || $ai_seq[0] eq "follow"
		|| $ai_seq[0] eq "sitAuto" || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather" || $ai_seq[0] eq "items_take")
		&& $currentChatRoom eq ""
		&& !($config{'itemsTakeAuto'} >= 2 && ($ai_seq[0] eq "take" || $ai_seq[0] eq "items_take"))
		&& !($config{'itemsGatherAuto'} >= 2 && ($ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather"))
		&& timeOut(\%{$timeout{'ai_attack_auto'}})) {

		undef @{$ai_v{'ai_attack_agMonsters'}};
		undef @{$ai_v{'ai_attack_cleanMonsters'}};
		undef @{$ai_v{'ai_attack_partyMonsters'}};
		undef $ai_v{'temp'}{'foundID'};

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

		@{$ai_v{'ai_attack_agMonsters'}} = ai_getAggressives() if ($config{'attackAuto'} && !($ai_v{'temp'}{'ai_route_index'} ne "" && !$ai_v{'temp'}{'ai_route_attackOnRoute'}));
		foreach (@monstersID) {
			next if ($_ eq "");
		 	next if (!IsAttackAble(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}}));
			if ((($config{'attackAuto_party'}
				&& ($monsters_lut{$monsters{$_}{'nameID'}}{'agg'} != 1 || $config{'attackAuto_party_agg'})
				&& $ai_seq[0] ne "take" && $ai_seq[0] ne "items_take"
				&& ($monsters{$_}{'dmgToParty'} > 0 || $monsters{$_}{'missedToParty'} > 0))
				|| ($config{'attackAuto_followTarget'} && $ai_v{'temp'}{'ai_follow_following'}
				&& ($monsters{$_}{'dmgToPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0 || $monsters{$_}{'missedToPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0)))
				&& !($ai_v{'temp'}{'ai_route_index'} ne "" && !$ai_v{'temp'}{'ai_route_attackOnRoute'})
				&& $monsters{$_}{'attack_failed'} == 0 && ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} >= 1 || $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "")) {
				push @{$ai_v{'ai_attack_partyMonsters'}}, $_;
			} elsif ($config{'attackAuto'} >= 2
				&& $ai_seq[0] ne "sitAuto" && $ai_seq[0] ne "take" && $ai_seq[0] ne "items_gather" && $ai_seq[0] ne "items_take"
				&& !($monsters{$_}{'dmgFromYou'} == 0 && ($monsters{$_}{'dmgTo'} > 0 || $monsters{$_}{'dmgFrom'} > 0 || %{$monsters{$_}{'missedFromPlayer'}} || %{$monsters{$_}{'missedToPlayer'}} || %{$monsters{$_}{'castOnByPlayer'}} || $monsters{$_}{'status_critical'} ne "" || $monsters{$_}{'status_warning'} ne "")) && $monsters{$_}{'attack_failed'} == 0
				&& !($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1)
				&& ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} >= 1 || $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "")) {
				push @{$ai_v{'ai_attack_cleanMonsters'}}, $_;
			}
		}
		undef $ai_v{'temp'}{'distSmall'};
		undef $ai_v{'temp'}{'foundID'};

		$ai_v{'temp'}{'first'} = 1;
		foreach (@{$ai_v{'ai_attack_agMonsters'}}) {
		 	next if (!IsAttackAble(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}}));

			$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
			if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'distSmall'}) {
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
				if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'distSmall'}) {
					$ai_v{'temp'}{'distSmall'} = $ai_v{'temp'}{'dist'};
					$ai_v{'temp'}{'foundID'} = $_;
					undef $ai_v{'temp'}{'first'};
				}
			}
		}

		# Attack First
		if (!$ai_v{'temp'}{'foundID'}) {
			undef $ai_v{'temp'}{'agg'};
			undef $ai_v{'temp'}{'order'};
			undef $ai_v{'temp'}{'distSmall'};
			undef $ai_v{'temp'}{'foundID'};
			$ai_v{'temp'}{'first'} = 1;
			foreach (@{$ai_v{'ai_attack_cleanMonsters'}}) {
				$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
				$ai_v{'temp'}{'order_temp'} = $mon_control{lc($monsters{$_}{'name'})}{'attack_order'};
				if ($monsters_lut{$monsters{$_}{'nameID'}}{'agg'} == 1) {
					$ai_v{'temp'}{'agg_temp'} = 1;
				} else {
					# No aggressive or Aggressive on casting
					$ai_v{'temp'}{'agg_temp'} = 0;
				}
				if ($ai_v{'temp'}{'first'} ||
					($ai_v{'temp'}{'agg_temp'} > $ai_v{'temp'}{'agg'}) ||
					($ai_v{'temp'}{'agg_temp'} == $ai_v{'temp'}{'agg'} && $ai_v{'temp'}{'order_temp'} > $ai_v{'temp'}{'order'}) ||
					($ai_v{'temp'}{'agg_temp'} == $ai_v{'temp'}{'agg'} && $ai_v{'temp'}{'order_temp'} == $ai_v{'temp'}{'order'} && $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'distSmall'})) {
					$ai_v{'temp'}{'agg'} = $ai_v{'temp'}{'agg_temp'};
					$ai_v{'temp'}{'order'} = $ai_v{'temp'}{'order_temp'};
					$ai_v{'temp'}{'distSmall'} = $ai_v{'temp'}{'dist'};
					$ai_v{'temp'}{'foundID'} = $_;
					undef $ai_v{'temp'}{'first'};
				}
			}
		}

#		if (!$ai_v{'temp'}{'foundID'}) {
#			undef $ai_v{'temp'}{'distSmall'};
#			undef $ai_v{'temp'}{'foundID'};
#			$ai_v{'temp'}{'first'} = 1;
#			foreach (@{$ai_v{'ai_attack_cleanMonsters'}}) {
#				$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
#				if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'distSmall'}) {
#					$ai_v{'temp'}{'distSmall'} = $ai_v{'temp'}{'dist'};
#					$ai_v{'temp'}{'foundID'} = $_;
#					undef $ai_v{'temp'}{'first'};
#				}
#			}
#		}

		if ($ai_v{'temp'}{'foundID'} ne "" && %{$monsters{$ai_v{'temp'}{'foundID'}}} && $monsters{$ai_v{'temp'}{'foundID'}}{'attack_failed'} < 10) {
			ai_setSuspend(0);
			attack($ai_v{'temp'}{'foundID'});
		} else {
			$timeout{'ai_attack_auto'}{'time'} = time;
		}
	}

	Debug('AI attackAuto');


	##### ATTACK #####

	if ($ai_seq[0] eq "attack" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_attack_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "attack" && %{$monsters{$ai_seq_args[0]{'ID'}}} && timeOut(\%{$ai_seq_args[0]{'ai_attack_giveup'}})) {
		$monsters{$ai_seq_args[0]{'ID'}}{'attack_failed'}++;
		shift @ai_seq;
		shift @ai_seq_args;
		undef %monster;
		PrintMessage("Can't reach or damage target, dropping target.", "lightblue");
	} elsif ($ai_seq[0] eq "attack" && !%{$monsters{$ai_seq_args[0]{'ID'}}}) {
		$timeout{'ai_attack'}{'time'} -= $timeout{'ai_attack'}{'timeout'};
		$ai_v{'ai_attack_ID_old'} = $ai_seq_args[0]{'ID'};
		shift @ai_seq;
		shift @ai_seq_args;
		if ($monsters_old{$ai_v{'ai_attack_ID_old'}}{'dead'}) {
			$ai_v{'temp'}{'name'} = $monsters_old{$ai_v{'ai_attack_ID_old'}}{'name'};

			if ($monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgFromYou'} > 0) {
				$timecount{'attack'}{'stop'} = time;
				$timecount{'attack'}{'count'} = $timecount{'attack'}{'stop'} - $timecount{'attack'}{'start'};
				$ai_v{'temp'}{'time'} = sprintf("%.2f", $timecount{'attack'}{'count'});

				PrintMessage("$ai_v{'temp'}{'name'} died on $ai_v{'temp'}{'time'} seconds, damage $monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgFromYou'}.", "lightblue");
				if ($chars[$config{'char'}]{'summary'}{'monsters'}{$field{'name'}}{$ai_v{'temp'}{'name'}}{'min_damage'} == 0 || $monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgFromYou'} < $chars[$config{'char'}]{'summary'}{'monsters'}{$field{'name'}}{$ai_v{'temp'}{'name'}}{'min_damage'}) {
					$chars[$config{'char'}]{'summary'}{'monsters'}{$field{'name'}}{$ai_v{'temp'}{'name'}}{'min_damage'} = $monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgFromYou'};
				}

				if ($monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgFromYou'} > $chars[$config{'char'}]{'summary'}{'monsters'}{$field{'name'}}{$ai_v{'temp'}{'name'}}{'max_damage'}) {
					$chars[$config{'char'}]{'summary'}{'monsters'}{$field{'name'}}{$ai_v{'temp'}{'name'}}{'max_damage'} = $monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgFromYou'};
				}

				$chars[$config{'char'}]{'summary'}{'monsters'}{$field{'name'}}{$ai_v{'temp'}{'name'}}{'count'}++;
				if ($chars[$config{'char'}]{'summary'}{'monsters'}{$field{'name'}}{$ai_v{'temp'}{'name'}}{'count'} > 1) {
					$chars[$config{'char'}]{'summary'}{'monsters'}{$field{'name'}}{$ai_v{'temp'}{'name'}}{'time'} = ($chars[$config{'char'}]{'summary'}{'monsters'}{$field{'name'}}{$ai_v{'temp'}{'name'}}{'time'} + $ai_v{'temp'}{'time'}) / 2;
				} else {
					$chars[$config{'char'}]{'summary'}{'monsters'}{$field{'name'}}{$ai_v{'temp'}{'name'}}{'time'} = $ai_v{'temp'}{'time'};
				}
			} else {
				PrintMessage("$ai_v{'temp'}{'name'} died. No loot.", "lightblue");
			}

			if ($config{'itemsTakeAuto'} && $monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgFromYou'} > 0) {
				undef $ai_v{'temp'}{'nearest_id'};
				$ai_v{'temp'}{'nearest_distance'} = 9999;
				foreach (@monstersID) {
					next if ($_ eq "");
					if ($monsters_lut{$monsters{$_}{'nameID'}}{'loot'} && !$monsters{$_}{'dmgToPlayers'} && !$monsters{$_}{'dmgFromPlayers'}) {
						$ai_v{'temp'}{'distance'} = distance(\%{$monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos'}}, \%{$monsters{$_}{'pos_to'}});
						if ($ai_v{'temp'}{'distance'} < 3 && $ai_v{'temp'}{'distance'} < $ai_v{'temp'}{'nearest_distance'}) {
							$ai_v{'temp'}{'nearest_id'} = $_;
							$ai_v{'temp'}{'nearest_distance'} = $ai_v{'temp'}{'distance'};
						}
					}
				}

				if ($config{'attackAuto'} >= 2 && $ai_v{'temp'}{'nearest_id'} ne "" && %{$monsters{$ai_v{'temp'}{'nearest_id'}}} && ($mon_control{lc($monsters{$ai_v{'temp'}{'nearest_id'}}{'name'})}{'attack_auto'} >= 1 || $mon_control{lc($monsters{$ai_v{'temp'}{'nearest_id'}}{'name'})}{'attack_auto'} eq "")) {
					PrintMessage("Attack loot monster: $monsters{$ai_v{'temp'}{'nearest_id'}}{'name'} [".getHex($ai_v{'temp'}{'nearest_id'})."]", "yellow");
					ai_setSuspend(0);
					$monsters{$ai_v{'temp'}{'nearest_id'}}{'loot'} = 1;
					attack($ai_v{'temp'}{'nearest_id'});
				} else {
					ai_items_take($monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos'}{'x'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos'}{'y'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos_to'}{'x'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos_to'}{'y'});
				}
			} else {
				#cheap way to suspend all movement to make it look real
				undef %monster;
				ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
			}
		} else {
			PrintMessage("Target lost.", "lightblue");
		}
	} elsif ($ai_seq[0] eq "attack") {
		if ($monsters_lut{$monsters{$ai_seq_args[0]{'ID'}}{'nameID'}}{'agg'} != 1 &&
			!$monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'} &&
			!$monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'} &&
			!$monsters{$ai_seq_args[0]{'ID'}}{'missedYou'}) {
			undef $ai_v{'temp'}{'distSmall'};
			undef $ai_v{'temp'}{'foundID'};
			undef @{$ai_v{'ai_attack_agMonsters'}};
			@{$ai_v{'ai_attack_agMonsters'}} = ai_getAggressives();

			$ai_v{'temp'}{'first'} = 1;
			foreach (@{$ai_v{'ai_attack_agMonsters'}}) {
				$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
				if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'distSmall'}) {
					$ai_v{'temp'}{'distSmall'} = $ai_v{'temp'}{'dist'};
					$ai_v{'temp'}{'foundID'} = $_;
					undef $ai_v{'temp'}{'first'};
				}
			}

			if ($ai_v{'temp'}{'foundID'} ne "" && $ai_seq_args[0]{'ID'} ne $ai_v{'temp'}{'foundID'} && %{$monsters{$ai_v{'temp'}{'foundID'}}}) {
				$ai_seq_args[0]{'ID'} = $ai_v{'temp'}{'foundID'};
				undef $ai_seq_args[0]{'attackMethod'};

				PrintMessage("Attack aggressive monster: $monsters{$ai_seq_args[0]{'ID'}}{'name'} [".getHex($ai_seq_args[0]{'ID'})."]", "yellow");
			}
		}

		undef $ai_v{'temp'}{'tank'};
		if ($config{'tankMode'}) {
			foreach (@playersID) {
				next if ($_ eq "");
				if ($config{'tankModeTarget'} eq $players{$_}{'name'}) {
					if ($monsters_lut{$monsters{$ai_seq_args[0]{'ID'}}{'nameID'}}{'agg'} != 1 || $jobs_lut{$players{$_}{'jobID'}} eq "Mage"  || $jobs_lut{$players{$_}{'jobID'}} ne "Archer") {
						$ai_v{'temp'}{'tank'} = 1;
					}

					last;
				}
			}
		}

		$ai_v{'temp'}{'ai_follow_index'} = binFind(\@ai_seq, "follow");
		if ($ai_v{'temp'}{'ai_follow_index'} ne "") {
			$ai_v{'temp'}{'ai_follow_following'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'following'};
			$ai_v{'temp'}{'ai_follow_ID'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'ID'};
		} else {
			undef $ai_v{'temp'}{'ai_follow_following'};
		}

		$ai_v{'ai_attack_monsterDist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}});

		if (($config{'attackAuto_party'} && ($monsters{$ai_seq_args[0]{'ID'}}{'dmgToParty'} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'missedToParty'} > 0))
			|| ($config{'attackAuto_followTarget'} && $ai_v{'temp'}{'ai_follow_following'} && ($monsters{$ai_seq_args[0]{'ID'}}{'dmgToPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'missedToPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0))
			|| ($monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'missedYou'} > 0)	) {
			$ai_v{'ai_attack_cleanMonster'} = 1;
		} elsif ($monsters{$ai_seq_args[0]{'ID'}}{'missedToPlayers'}
			|| $monsters{$ai_seq_args[0]{'ID'}}{'dmgToPlayers'}
			|| ($monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'} == 0 && ($monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'dmgFrom'} > 0 || %{$monsters{$ai_seq_args[0]{'ID'}}{'missedFromPlayer'}} || %{$monsters{$ai_seq_args[0]{'ID'}}{'missedToPlayer'}} || %{$monsters{$ai_seq_args[0]{'ID'}}{'castOnByPlayer'}}))) {
			$ai_v{'ai_attack_cleanMonster'} = 0;
		} else {
			$ai_v{'ai_attack_cleanMonster'} = 1;
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
			$i = 0;
			while ($config{"attackComboSlot_$i"} ne "") {
				if (percent_hp(\%{$chars[$config{'char'}]}) >= $config{"attackComboSlot_$i"."_hp_lower"} && percent_hp(\%{$chars[$config{'char'}]}) <= $config{"attackComboSlot_$i"."_hp_upper"}
					&& percent_sp(\%{$chars[$config{'char'}]}) >= $config{"attackComboSlot_$i"."_sp_lower"} && percent_sp(\%{$chars[$config{'char'}]}) <= $config{"attackComboSlot_$i"."_sp_upper"}
					&& $chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc($config{"attackComboSlot_$i"})}}{$config{"attackComboSlot_$i"."_lvl"}}
					&& $config{"attackComboSlot_$i"."_minAggressives"} <= ai_getAggressives()
					&& (!$config{"attackComboSlot_$i"."_maxAggressives"} || $config{"attackComboSlot_$i"."_maxAggressives"} >= ai_getAggressives())
					&& (!$config{"attackComboSlot_$i"."_monsters"} || existsInList($config{"attackComboSlot_$i"."_monsters"}, $monsters{$ai_seq_args[0]{'ID'}}{'name'}))
					&& $config{"attackComboSlot_$i"."_afterSkill"} eq GetSkillName($chars[$config{'char'}]{'last_skill_used'})
					&& $ai_seq_args[0]{'ID'} eq $chars[$config{'char'}]{'last_skill_target'}
					&& !$ai_seq_args[0]{'attackComboSlot_wait'}{$i}{'waiting'}) {

					if ($config{"attackComboSlot_$i"."_waitBeforeUse"} > 0) {
						PrintMessage("- Active: ".$config{"attackComboSlot_$i"}.", LV.".$config{"attackComboSlot_$i"."_lvl"}, "dark");
						$ai_seq_args[0]{'attackComboSlot_wait'}{$i}{'time'} = $chars[$config{'char'}]{'skills'}{$skillsID_lut{$chars[$config{'char'}]{'last_skill_used'}}{'nameID'}}{'time_used'};
						$ai_seq_args[0]{'attackComboSlot_wait'}{$i}{'timeout'} = $config{"attackComboSlot_$i"."_waitBeforeUse"};
						$ai_seq_args[0]{'attackComboSlot_wait'}{$i}{'waiting'} = 1;
					} else {
						PrintMessage("- Use: ".$config{"attackComboSlot_$i"}.", LV.".$config{"attackComboSlot_$i"."_lvl"}, "dark");
						$ai_seq_args[0]{'attackComboSlot_uses'}{$i}++;
						$ai_seq_args[0]{'attackMethod'}{'type'} = "combo";
						$ai_seq_args[0]{'attackMethod'}{'comboSlot'} = $i;
						last;
					}
				}
				$i++;
			}

			$i = 0;
			while ($config{"attackComboSlot_$i"} ne "") {
				if ($ai_seq_args[0]{'attackComboSlot_wait'}{$i}{'waiting'} > 0) {
					if (!$ai_seq_args[0]{'attackComboSlot_wait'}{$i}{'timeout'} || timeOut(\%{$ai_seq_args[0]{'attackComboSlot_wait'}{$i}})) {
						PrintMessage("- Use: ".$config{"attackComboSlot_$i"}.", LV.".$config{"attackComboSlot_$i"."_lvl"}, "dark");
						$ai_seq_args[0]{'attackComboSlot_uses'}{$i}++;
						$ai_seq_args[0]{'attackComboSlot_wait'}{$i}{'waiting'} = 0;
						$ai_seq_args[0]{'attackMethod'}{'type'} = "combo";
						$ai_seq_args[0]{'attackMethod'}{'comboSlot'} = $i;
						last;
					} else {
						PrintMessage("Waiting slot $i ... ".(time - $ai_seq_args[0]{'attackComboSlot_wait'}{$i}{'time'}), "dark");
					}
				}

				$i++;
			}

			if ($ai_seq_args[0]{'attackMethod'}{'type'} eq "" && $config{"attackComboSlot_$i"} eq "") {
				undef %{$ai_seq_args[0]{'attackMethod'}};
			}

			$ai_seq_args[0]{'distanceIncrease'} = 0;
			$ai_seq_args[0]{'nomove'} = 0;
			$ai_seq_args[0]{'attack_step'} = 1;
		}

		if (!%{$ai_seq_args[0]{'attackMethod'}}) {
			if ($config{'attackUseWeapon'}) {
				$ai_seq_args[0]{'attackMethod'}{'distance_min'} = $config{'attackDistance_min'};
				$ai_seq_args[0]{'attackMethod'}{'distance_max'} = $config{'attackDistance_max'};
				$ai_seq_args[0]{'attackMethod'}{'type'} = "weapon";
			} else {
				$ai_seq_args[0]{'attackMethod'}{'distance_min'} = 1;
				$ai_seq_args[0]{'attackMethod'}{'distance_max'} = 30;
				undef $ai_seq_args[0]{'attackMethod'}{'type'};
			}

			$i = 0;
			while ($config{"attackSkillSlot_$i"} ne "") {
				if (percent_hp(\%{$chars[$config{'char'}]}) >= $config{"attackSkillSlot_$i"."_hp_lower"} && percent_hp(\%{$chars[$config{'char'}]}) <= $config{"attackSkillSlot_$i"."_hp_upper"}
					&& percent_sp(\%{$chars[$config{'char'}]}) >= $config{"attackSkillSlot_$i"."_sp_lower"} && percent_sp(\%{$chars[$config{'char'}]}) <= $config{"attackSkillSlot_$i"."_sp_upper"}
					&& $chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc($config{"attackSkillSlot_$i"})}}{$config{"attackSkillSlot_$i"."_lvl"}}
					&& !($config{"attackSkillSlot_$i"."_stopWhenHit"} && ai_getMonstersWhoHitMe())
					&& (!$config{"attackSkillSlot_$i"."_maxUses"} || $ai_seq_args[0]{'attackSkillSlot_uses'}{$i} < $config{"attackSkillSlot_$i"."_maxUses"})
					&& $config{"attackSkillSlot_$i"."_minAggressives"} <= ai_getAggressives()
					&& (!$config{"attackSkillSlot_$i"."_maxAggressives"} || $config{"attackSkillSlot_$i"."_maxAggressives"} >= ai_getAggressives())
					&& (!$config{"attackSkillSlot_$i"."_monsters"} || existsInList($config{"attackSkillSlot_$i"."_monsters"}, $monsters{$ai_seq_args[0]{'ID'}}{'name'}))
					&& ($config{"attackSkillSlot_$i"."_afterSlot"} eq "" || $ai_seq_args[0]{'attackSkillSlot_uses'}{$config{"attackSkillSlot_$i"."_afterSlot"}} > 0)
					&& ($config{"attackSkillSlot_$i"."_useWhenStatus"} eq "" || GotStatus($monsters{$ai_seq_args[0]{'ID'}}, $config{"attackSkillSlot_$i"."_useWhenStatus"}))
					&& ($config{"attackSkillSlot_$i"."_useWhenNoStatus"} eq "" || LostStatus($monsters{$ai_seq_args[0]{'ID'}}, $config{"attackSkillSlot_$i"."_useWhenNoStatus"}))) {

					if (!$ai_seq_args[0]{'attackSkillSlot_wait'}{$i}{'timeout'} || timeOut(\%{$ai_seq_args[0]{'attackSkillSlot_wait'}{$i}})) {
						$ai_seq_args[0]{'attackSkillSlot_wait'}{$i}{'time'} = time;
						if ($config{"attackSkillSlot_$i"."_waitBeforeNextUse"} > 0) {
							$ai_seq_args[0]{'attackSkillSlot_wait'}{$i}{'timeout'} = $config{"attackSkillSlot_$i"."_waitBeforeNextUse"};
						} else {
							$ai_seq_args[0]{'attackSkillSlot_wait'}{$i}{'timeout'} = 0;
						}

						$ai_seq_args[0]{'attackSkillSlot_uses'}{$i}++;
						$ai_seq_args[0]{'attackMethod'}{'distance_min'} = $config{"attackSkillSlot_$i"."_dist_min"};
						$ai_seq_args[0]{'attackMethod'}{'distance_max'} = $config{"attackSkillSlot_$i"."_dist_max"};
						$ai_seq_args[0]{'attackMethod'}{'distance_cast'} = $config{"attackSkillSlot_$i"."_dist_cast"};
						$ai_seq_args[0]{'attackMethod'}{'type'} = "skill";
						$ai_seq_args[0]{'attackMethod'}{'skillSlot'} = $i;

						PrintMessage("- Use: ".$config{"attackSkillSlot_$i"}.", LV.".$config{"attackSkillSlot_$i"."_lvl"}, "dark");

						if ($config{"attackSkillSlot_$i"."_resetSlot"} ne "") {
							$ai_seq_args[0]{'attackSkillSlot_uses'}{$config{"attackSkillSlot_$i"."_resetSlot"}} = 0;
						}

						$ai_seq_args[0]{'attackSkillSlot'} = $i;
						last;
					} else {
						PrintMessage("Waiting slot $i ... ".(time - $ai_seq_args[0]{'attackSkillSlot_wait'}{$i}{'time'}), "dark");
					}
				}
				$i++;
			}

			if ($ai_seq_args[0]{'attackMethod'}{'type'} eq "" && $config{"attackSkillSlot_$i"} eq "") {
				undef %{$ai_seq_args[0]{'attackMethod'}};
			}

			$ai_seq_args[0]{'distanceIncrease'} = 0;
			$ai_seq_args[0]{'nomove'} = 0;
			$ai_seq_args[0]{'attack_step'} = 0;
		}

		if ($currentChatRoom ne "") {
			sendChatRoomLeave(\$remote_socket);
			ai_setSuspend(0);
			stand();
		} elsif ($chars[$config{'char'}]{'sitting'}) {
			ai_setSuspend(0);
			stand();
		} elsif (!%{$ai_seq_args[0]{'attackMethod'}}) {
			DebugMessage("- No attack. Waiting for next turn.") if ($debug{'ai_attack'});
		} elsif (!$ai_v{'ai_attack_cleanMonster'}) {
			shift @ai_seq;
			shift @ai_seq_args;
			undef %monster;
			PrintMessage("Dropping target - No kill steal.", "lightblue");
		} elsif (!$ai_seq_args[0]{'attack_step'} && !$ai_seq_args[0]{'nomove'} && $ai_v{'ai_attack_monsterDist'} < $ai_seq_args[0]{'attackMethod'}{'distance_min'}) {
			if (%{$ai_seq_args[0]{'char_pos_last'}} && %{$ai_seq_args[0]{'attackMethod_last'}}
				&& $ai_seq_args[0]{'attackMethod_last'}{'distance_min'} == $ai_seq_args[0]{'attackMethod'}{'distance_min'}
				&& $ai_seq_args[0]{'char_pos_last'}{'x'} == $chars[$config{'char'}]{'pos_to'}{'x'}
				&& $ai_seq_args[0]{'char_pos_last'}{'y'} == $chars[$config{'char'}]{'pos_to'}{'y'}) {
				$ai_seq_args[0]{'nomove'} = 1;
			} else {
				if (%{$ai_seq_args[0]{'char_pos_last'}} && %{$ai_seq_args[0]{'attackMethod_last'}}
					&& $ai_seq_args[0]{'attackMethod_last'}{'distance_min'} == $ai_seq_args[0]{'attackMethod'}{'distance_min'}
					&& $ai_seq_args[0]{'char_pos_last'}{'x'} != $chars[$config{'char'}]{'pos_to'}{'x'}
					&& $ai_seq_args[0]{'char_pos_last'}{'y'} != $chars[$config{'char'}]{'pos_to'}{'y'}) {
					$ai_seq_args[0]{'distanceIncrease'}++;
				}

				DebugMessage("- Too close. DISTANCE: $ai_v{'ai_attack_monsterDist'} MIN DISTANCE: $ai_seq_args[0]{'attackMethod'}{'distance_min'}") if ($debug{'ai_attack'});

				getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$chars[$config{'char'}]{'pos_to'}});

				if ($monsters_lut{$monsters{$ai_seq_args[0]{'ID'}}{'nameID'}}{'agg'} == 1 ||
					$monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'}) {
					$ai_v{'temp'}{'distance'} = -$ai_seq_args[0]{'attackMethod'}{'distance_min'} - $ai_seq_args[0]{'distanceIncrease'};
				} else {
					$ai_v{'temp'}{'distance'} = $ai_v{'ai_attack_monsterDist'} - $ai_seq_args[0]{'attackMethod'}{'distance_min'};
				}

				if ($ai_v{'temp'}{'distance'} > -1) {
					$ai_v{'temp'}{'distance'} = -1;
				}
				moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'temp'}{'distance'});

				DebugMessage("- Move from ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'}) to ($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}).") if ($debug{'ai_attack'});

				%{$ai_seq_args[0]{'char_pos_last'}} = %{$chars[$config{'char'}]{'pos_to'}};
				%{$ai_seq_args[0]{'attackMethod_last'}} = %{$ai_seq_args[0]{'attackMethod'}};

				ai_setSuspend(0);

				if (@{$field{'field'}} > 1) {
					ai_route(\%{$ai_seq_args[0]{'ai_route_returnHash'}}, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}, $field{'name'}, $config{'attackMaxRouteDistance'}, $config{'attackMaxRouteTime'}, 0, 0);
				} else {
					move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
				}

				$ai_seq_args[0]{'attack_step'} = 1;
			}
		} elsif (!$ai_seq_args[0]{'attack_step'} && !$ai_seq_args[0]{'nomove'} && $ai_v{'ai_attack_monsterDist'}  > 2 && $ai_v{'ai_attack_monsterDist'} > $ai_seq_args[0]{'attackMethod'}{'distance_max'}) {
			if (%{$ai_seq_args[0]{'char_pos_last'}} && %{$ai_seq_args[0]{'attackMethod_last'}}
				&& $ai_seq_args[0]{'attackMethod_last'}{'distance_max'} == $ai_seq_args[0]{'attackMethod'}{'distance_max'}
				&& $ai_seq_args[0]{'char_pos_last'}{'x'} == $chars[$config{'char'}]{'pos_to'}{'x'}
				&& $ai_seq_args[0]{'char_pos_last'}{'y'} == $chars[$config{'char'}]{'pos_to'}{'y'}) {
				$ai_seq_args[0]{'distanceDivide'}++;
			} else {
				$ai_seq_args[0]{'distanceDivide'} = 1;
			}

			if (int($ai_seq_args[0]{'attackMethod'}{'distance_max'} / $ai_seq_args[0]{'distanceDivide'}) == 0
				|| ($config{'attackMaxRouteDistance'} && $ai_seq_args[0]{'ai_route_returnHash'}{'solutionLength'} > $config{'attackMaxRouteDistance'})
				|| ($config{'attackMaxRouteTime'} && $ai_seq_args[0]{'ai_route_returnHash'}{'solutionTime'} > $config{'attackMaxRouteTime'})) {
				$monsters{$ai_seq_args[0]{'ID'}}{'attack_failed'}++;
				shift @ai_seq;
				shift @ai_seq_args;
				undef %monster;

				PrintMessage("Dropping target - Couldn't reach target.", "lightblue");
			} else {
				DebugMessage("- Too far. DISTANCE: $ai_v{'ai_attack_monsterDist'} MAX DISTANCE: $ai_seq_args[0]{'attackMethod'}{'distance_max'}") if ($debug{'ai_attack'});

				getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$chars[$config{'char'}]{'pos_to'}});

				if ($monsters_lut{$monsters{$ai_seq_args[0]{'ID'}}{'nameID'}}{'agg'} == 1 ||
					$monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'}) {
					$ai_v{'temp'}{'distance'} = 1;
				} else {
					$ai_v{'temp'}{'distance'} = $ai_v{'ai_attack_monsterDist'} - ($ai_seq_args[0]{'attackMethod'}{'distance_max'} / $ai_seq_args[0]{'distanceDivide'}) + 1;
				}

				moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'temp'}{'distance'});

				DebugMessage("- Move from ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'}) to ($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}).") if ($debug{'ai_attack'});

				%{$ai_seq_args[0]{'char_pos_last'}} = %{$chars[$config{'char'}]{'pos_to'}};
				%{$ai_seq_args[0]{'attackMethod_last'}} = %{$ai_seq_args[0]{'attackMethod'}};

				ai_setSuspend(0);

				if (@{$field{'field'}} > 1) {
					ai_route(\%{$ai_seq_args[0]{'ai_route_returnHash'}}, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}, $field{'name'}, $config{'attackMaxRouteDistance'}, $config{'attackMaxRouteTime'}, 0, 0);
				} else {
					move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
				}

				$ai_seq_args[0]{'attack_step'} = 1;
				$ai_seq_args[0]{'distanceIncrease'} = 0;
			}
		} else {
			if ($config{'tankMode'}) {
				if ($ai_seq_args[0]{'dmgTo_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'}) {
					$ai_seq_args[0]{'ai_attack_giveup'}{'time'} = time;
				}

				$ai_seq_args[0]{'dmgTo_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'};
			}

			$ai_seq_args[0]{'attack_step'} = 0;
			if ($ai_seq_args[0]{'attackMethod'}{'type'} eq "weapon" && timeOut(\%{$timeout{'ai_attack'}})) {
				if ($ai_v{'temp'}{'tank'}) {
					if ($monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'} == 0) {
						sendAttack(\$remote_socket, $ai_seq_args[0]{'ID'}, 0);
					} else {
						sendAttackStop(\$remote_socket);
					}
				} else {
					sendAttack(\$remote_socket, $ai_seq_args[0]{'ID'}, 7);
				}

				$timeout{'ai_attack'}{'time'} = time;
				undef %{$ai_seq_args[0]{'attackMethod'}};
			} elsif ($ai_seq_args[0]{'attackMethod'}{'type'} eq "combo") {
				$ai_v{'ai_attack_method_comboSlot'} = $ai_seq_args[0]{'attackMethod'}{'comboSlot'};
				$ai_v{'ai_attack_ID'} = $ai_seq_args[0]{'ID'};
				undef %{$ai_seq_args[0]{'attackMethod'}};

				$skill_nameID = $skills_rlut{lc($config{"attackComboSlot_$ai_v{'ai_attack_method_comboSlot'}"})};
				$skill_lv = $config{"attackComboSlot_$ai_v{'ai_attack_method_comboSlot'}"."_lvl"};
				if ($chars[$config{'char'}]{'sp'} >= SkillSP($skill_nameID, $skill_lv)) {
					if ($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"attackComboSlot_$ai_v{'ai_attack_method_skillSlot'}"})}}{'use'} == 1) {
						sendSkillUse(\$remote_socket, $chars[$config{'char'}]{'skills'}{$skill_nameID}{'ID'}, $skill_lv, $ai_v{'ai_attack_ID'});
					} else {
						sendSkillUse(\$remote_socket, $chars[$config{'char'}]{'skills'}{$skill_nameID}{'ID'}, $skill_lv, $accountID);
					}

					DebugMessage(qq~- Auto-combo on monster: $skills_lut{$skills_rlut{lc($config{"attackComboSlot_$ai_v{'ai_attack_method_skillSlot'}"})}} (lvl $config{"attackComboSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}).~) if ($debug{'ai_attack'});
				}
			} elsif ($ai_seq_args[0]{'attackMethod'}{'type'} eq "skill") {
				if ($ai_seq_args[0]{'attackMethod'}{'distance_cast'}) {
					getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$chars[$config{'char'}]{'pos_to'}});
					moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_seq_args[0]{'attackMethod'}{'distance_cast'});
				} else {
					%{$ai_v{'temp'}{'pos'}} = %{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}};
				}

				$ai_v{'ai_attack_method_skillSlot'} = $ai_seq_args[0]{'attackMethod'}{'skillSlot'};
				$ai_v{'ai_attack_ID'} = $ai_seq_args[0]{'ID'};
				undef %{$ai_seq_args[0]{'attackMethod'}};
				ai_setSuspend(0);
				$skill_nameID = $skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})};
				$skill_lv = $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"};
				if ($chars[$config{'char'}]{'sp'} >= SkillSP($skill_nameID, $skill_lv)) {
					if ($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}}{'use'} == 2) {
						ai_skillUse($chars[$config{'char'}]{'skills'}{$skill_nameID}{'ID'}, $skill_lv, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_maxCastTime"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"}, 0, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
						#ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}}{'ID'}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_maxCastTime"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"}, $monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'x'}, $monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'y'});
					} else {
						ai_skillUse($chars[$config{'char'}]{'skills'}{$skill_nameID}{'ID'}, $skill_lv, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_maxCastTime"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"}, 0, $ai_v{'ai_attack_ID'});
					}

					DebugMessage(qq~- Auto-skill on monster: $skills_lut{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}} (lvl $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}).~) if ($debug{'ai_attack'});
				}
			}
		}
	}

	Debug('AI attack');


	##### ROUTE #####

	ROUTE: {

	if ($ai_seq[0] eq "route" && @{$ai_seq_args[0]{'solution'}} && $ai_seq_args[0]{'index'} == @{$ai_seq_args[0]{'solution'}} - 1 && $ai_seq_args[0]{'solutionReady'}) {
		DebugMessage("- Route success.") if ($debug{'ai_route'});
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "route" && $ai_seq_args[0]{'failed'}) {
		DebugMessage("- Route failed.") if ($debug{'ai_route'});
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "route" && timeOut(\%{$timeout{'ai_route_npcTalk'}})) {
		last ROUTE if (!$field{'name'});

		if ($ai_seq_args[0]{'waitingForMapSolution'}) {
			#DebugMessage("- waitingForMapSolution.") if ($debug{'ai_route'});
			undef $ai_seq_args[0]{'waitingForMapSolution'};
			if (!@{$ai_seq_args[0]{'mapSolution'}}) {
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}
			$ai_seq_args[0]{'mapIndex'} = -1;
		}
		if ($ai_seq_args[0]{'waitingForSolution'}) {
			#DebugMessage("- waitingForSolution.") if ($debug{'ai_route'});
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

		DebugMessage("- Map change on route.") if ($ai_seq_args[0]{'mapChanged'});

		if (@{$ai_seq_args[0]{'mapSolution'}} && $ai_seq_args[0]{'mapChanged'} && $field{'name'} eq $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'dest'}{'map'}) {
			DebugMessage("- Route to target map.") if ($debug{'ai_route'});
			undef $ai_seq_args[0]{'mapChanged'};
			undef @{$ai_seq_args[0]{'solution'}};
			undef %{$ai_seq_args[0]{'last_pos'}};
			undef $ai_seq_args[0]{'index'};
			undef $ai_seq_args[0]{'npc'};
			undef $ai_seq_args[0]{'divideIndex'};
		}
		if (!@{$ai_seq_args[0]{'solution'}}) {
			#DebugMessage("- No Solution.") if ($debug{'ai_route'});
			if (@{$ai_seq_args[0]{'mapSolution'}}) {
				for ($i = @{$ai_seq_args[0]{'mapSolution'}} - 1; $i >= 0; $i--) {
					if ($ai_seq_args[0]{'mapSolution'}[$i]{'source'}{'map'} eq "" || $ai_seq_args[0]{'mapSolution'}[$i]{'dest'}{'map'} eq "") {
						shift @{$ai_seq_args[0]{'mapSolution'}};
					} else {
						last;
					}
				}

				DebugMessage("- Map Index = $ai_seq_args[0]{'mapIndex'}") if ($debug{'ai_route'});
				for ($i = 0; $i < @{$ai_seq_args[0]{'mapSolution'}}; $i++) {
					DebugMessage("- Map Solution [$i]") if ($debug{'ai_route'});
					DebugMessage("- Src $ai_seq_args[0]{'mapSolution'}[$i]{'source'}{'map'} ($ai_seq_args[0]{'mapSolution'}[$i]{'source'}{'pos'}{'x'}, $ai_seq_args[0]{'mapSolution'}[$i]{'source'}{'pos'}{'y'})") if ($debug{'ai_route'});
					DebugMessage("- Des $ai_seq_args[0]{'mapSolution'}[$i]{'dest'}{'map'} ($ai_seq_args[0]{'mapSolution'}[$i]{'dest'}{'pos'}{'x'}, $ai_seq_args[0]{'mapSolution'}[$i]{'dest'}{'pos'}{'y'})") if ($debug{'ai_route'});
				}
			}
			if ($ai_seq_args[0]{'dest_map'} eq $field{'name'}
				&& (!@{$ai_seq_args[0]{'mapSolution'}} || $ai_seq_args[0]{'mapIndex'} == @{$ai_seq_args[0]{'mapSolution'}} - 1)) {
				#DebugMessage("- Solution Ready.") if ($debug{'ai_route'});
				$ai_seq_args[0]{'temp'}{'dest'}{'x'} = $ai_seq_args[0]{'dest_x'};
				$ai_seq_args[0]{'temp'}{'dest'}{'y'} = $ai_seq_args[0]{'dest_y'};
				$ai_seq_args[0]{'solutionReady'} = 1;
				undef @{$ai_seq_args[0]{'mapSolution'}};
				undef $ai_seq_args[0]{'mapIndex'};
			} else {
				#DebugMessage("- Next Solution.") if ($debug{'ai_route'});
				if (!(@{$ai_seq_args[0]{'mapSolution'}})) {
					if (!%{$ai_seq_args[0]{'dest_field'}}) {
						getField("fields/$ai_seq_args[0]{'dest_map'}.fld", \%{$ai_seq_args[0]{'dest_field'}});
					}
					$ai_seq_args[0]{'temp'}{'pos'}{'x'} = $ai_seq_args[0]{'dest_x'};
					$ai_seq_args[0]{'temp'}{'pos'}{'y'} = $ai_seq_args[0]{'dest_y'};
					$ai_seq_args[0]{'waitingForMapSolution'} = 1;
					ai_mapRoute_getRoute(\@{$ai_seq_args[0]{'mapSolution'}}, \%field, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'dest_field'}}, \%{$ai_seq_args[0]{'temp'}{'pos'}}, $ai_seq_args[0]{'maxRouteTime'});
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
			#DebugMessage("- NpcSolution.") if ($debug{'ai_route'});
			if ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] ne "") {
				if (!$ai_seq_args[0]{'npc'}{'sentTalk'}) {
					# Find Nearest NPC
					if ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'} eq "auto") {
						undef $ai_v{'temp'}{'nearest_npc_id'};
						$ai_v{'temp'}{'nearest_distance'} = 9999;
						for ($i = 0; $i < @npcsID; $i++) {
							next if ($npcsID[$i] eq "");
							$ai_v{'temp'}{'distance'} = distance(\%{$npcs{$npcsID[$i]}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
							if ($ai_v{'temp'}{'distance'} < $ai_v{'temp'}{'nearest_distance'}) {
								$ai_v{'temp'}{'nearest_npc_id'} = $npcs{$npcsID[$i]}{'nameID'};
								$ai_v{'temp'}{'nearest_distance'} = $ai_v{'temp'}{'distance'};
							}
						}

						if ($ai_v{'temp'}{'nearest_npc_id'} ne "") {
							$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'} = $ai_v{'temp'}{'nearest_npc_id'};
							PrintMessage("Found nearest NPC: $ai_v{'temp'}{'nearest_npc_id'}", "white");
						} else {
							# Not found nearest NPC, cancel all steps.
							$ai_seq_args[0]{'npc'}{'step'} = 9999;
						}
					}

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
			#DebugMessage("- MoveSolution.") if ($debug{'ai_route'});
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
				# Fixed move
				if ($ai_seq_args[0]{'last_pos'}{'x'} == $chars[$config{'char'}]{'pos_to'}{'x'} &&
					$ai_seq_args[0]{'last_pos'}{'y'} == $chars[$config{'char'}]{'pos_to'}{'y'}) {

					$ai_seq_args[0]{'failed_count'}++;
					if ($ai_seq_args[0]{'failed_count'} > 3) {
						DebugMessage("- Route failed. Use random move.") if ($debug{'ai_route'});
						($ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}) = GetRandPosition(2);
						move($ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'});
					} elsif ($ai_seq_args[0]{'failed_count'} > 6) {
						$ai_seq_args[0]{'failed'} = 1;
						last ROUTE;
					}
				} else {
					$ai_seq_args[0]{'failed_count'} = 0;
					%{$ai_seq_args[0]{'last_pos'}} = %{$chars[$config{'char'}]{'pos_to'}};

					$ai_v{'temp'}{'first'} = 1;
					undef $ai_v{'temp'}{'foundID'};
					undef $ai_v{'temp'}{'smallDist'};
					foreach (@portalsID) {
						$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$portals{$_}{'pos'}});
						if ($ai_v{'temp'}{'dist'} <= 12 && ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'})) {
							$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
							$ai_v{'temp'}{'foundID'} = $_;
							undef $ai_v{'temp'}{'first'};
						}
					}

					undef $ai_v{'temp'}{'des'};
					undef $ai_v{'temp'}{'src'};
					undef $ai_v{'temp'}{'src_x'};
					undef $ai_v{'temp'}{'src_y'};
					if (@{$ai_seq_args[0]{'mapSolution'}} && $ai_seq_args[0]{'mapIndex'} <= @{$ai_seq_args[0]{'mapSolution'}} - 1) {
						$ai_v{'temp'}{'des'} = $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'dest'}{'map'};
						$ai_v{'temp'}{'des_x'} = $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'dest'}{'pos'}{'x'};
						$ai_v{'temp'}{'des_y'} = $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'dest'}{'pos'}{'y'};
						$ai_v{'temp'}{'src'} = $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'map'};
						$ai_v{'temp'}{'src_x'} = $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'pos'}{'x'};
						$ai_v{'temp'}{'src_y'} = $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'pos'}{'y'};
					}

					if (!$ai_seq_args[0]{'avoidOtherPortal'} && $ai_v{'temp'}{'foundID'} &&
						$ai_v{'temp'}{'des'} ne "" &&
						$ai_v{'temp'}{'src'} ne "" &&
						$field{'name'} ne $ai_v{'temp'}{'des'} &&
						($ai_v{'temp'}{'src'} ne $portals{$ai_v{'temp'}{'foundID'}}{'source'}{'map'} ||
						$ai_v{'temp'}{'src_x'} != $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'} ||
						$ai_v{'temp'}{'src_y'} != $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'})) {
						$ai_seq_args[0]{'avoidOtherPortal'} = 1;
						DebugMessage("- None target portal found, get out from here.") if ($debug{'ai_route'});
						#getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$portals{$ai_v{'temp'}{'foundID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
						#moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, -5);
						#move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
						while ($ai_seq_args[0]{'index'} < @{$ai_seq_args[0]{'solution'}} - 1) {
							$ai_v{'temp'}{'pos'}{'x'} = $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'};
							$ai_v{'temp'}{'pos'}{'y'} = $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'};
							$ai_v{'temp'}{'distance'} = distance(\%{$portals{$ai_v{'temp'}{'foundID'}}{'pos'}}, \%{$ai_v{'temp'}{'pos'}});

							last if ($ai_v{'temp'}{'distance'} > 6);

							$ai_seq_args[0]{'index'}++;
						}

						move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
					} else {
						undef $ai_seq_args[0]{'avoidOtherPortal'};
						$ai_v{'temp'}{'pos'}{'x'} = $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'};
						$ai_v{'temp'}{'pos'}{'y'} = $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'};
						if ($field{'field'}[$ai_v{'temp'}{'pos'}{'y'} * $field{'width'} + $ai_v{'temp'}{'pos'}{'x'}]) {
							DebugMessage("- Move to bad position. Change target position.") if ($debug{'ai_route'});
							($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}) = GetRandPosition(1, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
						}

						if (!binFind(\@ai_seq, "attack") && $ai_seq_args[0]{'index'} < (@{$ai_seq_args[0]{'solution'}} - $config{'route_step'} - 1)) {
							$ai_v{'temp'}{'pos_to'}{'x'} = $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'} + $config{'route_step'}]{'x'};
							$ai_v{'temp'}{'pos_to'}{'y'} = $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'} + $config{'route_step'}]{'y'};
							($ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}) = AlignWalk(\%{$ai_v{'temp'}{'pos'}}, \%{$ai_v{'temp'}{'pos_to'}});
							if ($ai_v{'temp'}{'x'} >= 0 && $ai_v{'temp'}{'y'} >= 0) {
								$ai_v{'temp'}{'pos'}{'x'} = $ai_v{'temp'}{'x'};
								$ai_v{'temp'}{'pos'}{'y'} = $ai_v{'temp'}{'y'};
							}
						}

						move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
						#move($ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}, $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'});
					}
				}
			} else {
				%{$ai_seq_args[0]{'last_pos'}} = %{$chars[$config{'char'}]{'pos_to'}};
			}
		}
	}

	} #END OF ROUTE BLOCK

	Debug('AI route');


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

	Debug('AI route_getRoute');


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

	Debug('AI route_getMapRoute');


	##### ITEMS TAKE #####

	if ($ai_seq[0] eq "items_take" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_items_take_start'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		$ai_seq_args[0]{'ai_items_take_end'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
#	if ($ai_seq[0] eq "items_take" && (percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'})) {
#		shift @ai_seq;
#		shift @ai_seq_args;
#
#		ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
#	}
	if ($config{'itemsTakeAuto'} && $ai_seq[0] eq "items_take" && timeOut(\%{$ai_seq_args[0]{'ai_items_take_start'}})) {
		undef $ai_v{'temp'}{'foundID'};
		undef $ai_v{'temp'}{'rare'};
#		foreach (@itemsID) {
#			next if ($_ eq "" || $itemsPickup{lc($items{$_}{'name'})} eq "0" || (!$itemsPickup{'all'} && !$itemsPickup{lc($items{$_}{'name'})}));
#			$ai_v{'temp'}{'dist'} = distance(\%{$items{$_}{'pos'}}, \%{$ai_seq_args[0]{'pos'}});
#			$ai_v{'temp'}{'dist_to'} = distance(\%{$items{$_}{'pos'}}, \%{$ai_seq_args[0]{'pos_to'}});
#			if (($ai_v{'temp'}{'dist'} <= 4 || $ai_v{'temp'}{'dist_to'} <= 4) && $items{$_}{'take_failed'} == 0) {
#				$ai_v{'temp'}{'foundID'} = $_;
#				if ($rareItems_lut{lc($items{$_}{'name'})}) {
#					last;
#				}
#			}
#		}

		foreach (@itemsDropID) {
			next if ($_ eq "" || $itemsPickup{lc($items{$_}{'name'})} eq "0" || (!$itemsPickup{'all'} && !$itemsPickup{lc($items{$_}{'name'})}));
			if ($items{$_}{'take_failed'} == 0) {
				$ai_v{'temp'}{'foundID'} = $_;
				if ($rareItems_lut{lc($items{$_}{'name'})}) {
					$ai_v{'temp'}{'rare'} = 1;
					last;
				}
			}
		}

		if (!$ai_v{'temp'}{'rare'} && (percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'})) {
			undef %monster;
			shift @ai_seq;
			shift @ai_seq_args;
			ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
		} elsif ($ai_v{'temp'}{'foundID'}) {
			$ai_seq_args[0]{'ai_items_take_end'}{'time'} = time;
			$ai_seq_args[0]{'started'} = 1;
			take($ai_v{'temp'}{'foundID'});
		} elsif ($ai_seq_args[0]{'started'} || timeOut(\%{$ai_seq_args[0]{'ai_items_take_end'}})) {
			undef %monster;
			shift @ai_seq;
			shift @ai_seq_args;
			ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
		}
	}

	Debug('AI items_take');


	##### ITEMS AUTO-GATHER #####

	if (($ai_seq[0] eq "" || $ai_seq[0] eq "follow" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute") && $config{'itemsGatherAuto'} && !(percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'}) && timeOut(\%{$timeout{'ai_items_gather_auto'}})) {
		undef @{$ai_v{'ai_items_gather_foundIDs'}};
		foreach (@playersID) {
			next if ($_ eq "");
			if (!IsPartyOnline($_)) {
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

	Debug('AI itemGatherAuto');


	##### ITEMS GATHER #####

	if ($ai_seq[0] eq "items_gather" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_items_gather_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "items_gather" && !%{$items{$ai_seq_args[0]{'ID'}}}) {
		DebugMessage("- Failed to gather $items_old{$ai_seq_args[0]{'ID'}}{'name'} ($items_old{$ai_seq_args[0]{'ID'}}{'binID'}) : Lost target.") if ($debug{'ai_itemsGather'});
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "items_gather") {
		undef $ai_v{'temp'}{'dist'};
		undef @{$ai_v{'ai_items_gather_foundIDs'}};
		undef $ai_v{'temp'}{'found'};
		foreach (@playersID) {
			next if ($_ eq "");
			if (!IsPartyOnline($_)) {
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
			DebugMessage("- Failed to gather $items{$ai_seq_args[0]{'ID'}}{'name'} ($items{$ai_seq_args[0]{'ID'}}{'binID'}) : Timeout.") if ($debug{'ai_itemsGather'});
			$items{$ai_seq_args[0]{'ID'}}{'take_failed'}++;
			shift @ai_seq;
			shift @ai_seq_args;
		} elsif ($currentChatRoom ne "") {
			sendChatRoomLeave(\$remote_socket);
			ai_setSuspend(0);
			stand();
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
			DebugMessage("- Failed to gather $items{$ai_seq_args[0]{'ID'}}{'name'} ($items{$ai_seq_args[0]{'ID'}}{'binID'}) : No looting!") if ($debug{'ai_itemsGather'});
			shift @ai_seq;
			shift @ai_seq_args;
		}
	}

	Debug('AI items_gather');


	##### TAKE #####

	if ($ai_seq[0] eq "take" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_take_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "take" && !%{$items{$ai_seq_args[0]{'ID'}}}) {
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "take" && timeOut(\%{$ai_seq_args[0]{'ai_take_giveup'}})) {
		PrintMessage("Failed to take $items{$ai_seq_args[0]{'ID'}}{'name'} x $items{$ai_seq_args[0]{'ID'}}{'amount'}", "lightblue");
		$items{$ai_seq_args[0]{'ID'}}{'take_failed'}++;
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "take") {
		$ai_v{'temp'}{'dist'} = distance(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
		if ($currentChatRoom ne "") {
			sendChatRoomLeave(\$remote_socket);
			ai_setSuspend(0);
			stand();
		} elsif ($chars[$config{'char'}]{'sitting'}) {
			ai_setSuspend(0);
			stand();
		} elsif ($ai_v{'temp'}{'dist'} > 2) {
			getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'temp'}{'dist'} - 1);

			if (@{$field{'field'}} > 1) {
				ai_route(\%{$ai_seq_args[0]{'ai_route_returnHash'}}, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}, $field{'name'}, $config{'attackMaxRouteDistance'}, $config{'attackMaxRouteTime'}, 0, 0);
			} else {
				move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
			}
		} elsif (timeOut(\%{$timeout{'ai_take'}})) {
			sendTake(\$remote_socket, $ai_seq_args[0]{'ID'});
			$timeout{'ai_take'}{'time'} = time;
		}
	}

	Debug('AI take');


	##### MOVE #####

	if ($ai_seq[0] eq "move" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_move_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "move") {
		if (!$ai_seq_args[0]{'ai_moved'} && $ai_seq_args[0]{'ai_moved_tried'} && $ai_seq_args[0]{'ai_move_time_last'} != $chars[$config{'char'}]{'time_move'}) {
			$ai_seq_args[0]{'ai_moved'} = 1;
		}
		if ($currentChatRoom ne "") {
			sendChatRoomLeave(\$remote_socket);
			ai_setSuspend(0);
			stand();
		} elsif ($chars[$config{'char'}]{'sitting'}) {
			ai_setSuspend(0);
			stand();
		} elsif (!$ai_seq_args[0]{'ai_moved'} && timeOut(\%{$ai_seq_args[0]{'ai_move_giveup'}})) {
			shift @ai_seq;
			shift @ai_seq_args;
		} elsif (!$ai_seq_args[0]{'ai_moved_tried'}) {
			sendMove(\$remote_socket, int($ai_seq_args[0]{'move_to'}{'x'}), int($ai_seq_args[0]{'move_to'}{'y'}));
			$ai_seq_args[0]{'ai_move_giveup'}{'time'} = time;
			$ai_seq_args[0]{'ai_move_time_last'} = $chars[$config{'char'}]{'time_move'};
			$ai_seq_args[0]{'ai_moved_tried'} = 1;
		} elsif ($ai_seq_args[0]{'ai_moved'} && time - $chars[$config{'char'}]{'time_move'} >= $chars[$config{'char'}]{'time_move_calc'}) {
			shift @ai_seq;
			shift @ai_seq_args;
		}
	}

	Debug('AI move');


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

	if (timeOut(\%{$timeout{'ai_teleport_away'}}) && $ai_v{'ai_teleport_safe'}) {
		foreach (@monstersID) {
			next if ($_ eq "");
			if ($mon_control{lc($monsters{$_}{'name'})}{'teleport_auto'}) {
				useTeleport(1);
				$ai_v{'temp'}{'search'} = 1;
				last;
			}
		}
		$timeout{'ai_teleport_away'}{'time'} = time;
	}

	if ((($config{'teleportAuto_hp'} && percent_hp(\%{$chars[$config{'char'}]}) <= $config{'teleportAuto_hp'} && ai_getAggressives())
		|| ($config{'teleportAuto_minAggressives'} && ai_getAggressives() >= $config{'teleportAuto_minAggressives'}))
		&& $ai_v{'ai_teleport_safe'} && timeOut(\%{$timeout{'ai_teleport_hp'}})) {
		useTeleport(1);
		$ai_v{'clear_aiQueue'} = 1;
		$timeout{'ai_teleport_hp'}{'time'} = time;
	}

	if ($config{'teleportAuto_search'} && $ai_seq[0] ne "buyAuto" && $ai_seq[0] ne "sellAuto" && $ai_seq[0] ne "storageAuto" &&
		timeOut(\%{$timeout{'ai_teleport_search'}}) && binFind(\@ai_seq, "attack") eq "" && binFind(\@ai_seq, "items_take") eq ""
		&& $ai_v{'ai_teleport_safe'} && binFind(\@ai_seq, "sitAuto") eq ""
		&& ($config{'lockMap'} eq "" || $field{'name'} ne $config{'lockMap'})) {

		undef $ai_v{'temp'}{'search'};
		foreach (keys %mon_control) {
			if ($mon_control{$_}{'teleport_search'}) {
				$ai_v{'temp'}{'search'} = 1;
				last;
			}
		}
		if ($ai_v{'temp'}{'search'}) {
			undef $ai_v{'temp'}{'found'};
			foreach (@monstersID) {
				if ($mon_control{lc($monsters{$_}{'name'})}{'teleport_search'} && !$monsters{$_}{'attack_failed'}) {
					$ai_v{'temp'}{'found'} = 1;
					last;
				}
			}
			if (!$ai_v{'temp'}{'found'}) {
				useTeleport(1);
				$ai_v{'clear_aiQueue'} = 1;
			}
		}
		$timeout{'ai_teleport_search'}{'time'} = time;
	}

	if ($config{'teleportAuto_idle'} && $ai_seq[0] ne "") {
		$timeout{'ai_teleport_idle'}{'time'} = time;
	}

	if ($config{'teleportAuto_idle'} && timeOut(\%{$timeout{'ai_teleport_idle'}}) && $ai_v{'ai_teleport_safe'}) {
		useTeleport(1);
		$ai_v{'clear_aiQueue'} = 1;
		$timeout{'ai_teleport_idle'}{'time'} = time;
	}

	if ($config{'teleportAuto_portal'} && timeOut(\%{$timeout{'ai_teleport_portal'}}) && $ai_v{'ai_teleport_safe'}) {
		if (binSize(\@portalsID)) {
			useTeleport(1);
			$ai_v{'clear_aiQueue'} = 1;
		}
		$timeout{'ai_teleport_portal'}{'time'} = time;
	}

	Debug('AI teleportAuto');


	##### PET AUTO #####

	if (%{$chars[$config{'char'}]{'pet'}}) {
		if (!$chars[$config{'char'}]{'pet'}{'hungry'}) {
			sendPetCommand(\$remote_socket, 0);
		} elsif (timeOut(\%{$timeout{'ai_petAuto_feed'}}) && $config{'petAutoFeed'} > 0 && $chars[$config{'char'}]{'pet'}{'hungry'} <= $config{'petAutoFeed_hungry'}) {
			PrintMessage("Auto-feed on pet, hungry is $chars[$config{'char'}]{'pet'}{'hungry'}.", "brown");
			sendPetCommand(\$remote_socket, 1);
			$timeout{'ai_petAuto_feed'}{'time'} = time;
		}

		if ($config{'petAutoKeep'} == 1) {
			PrintMessage("Auto-keep on pet.", "brown");
			sendPetCommand(\$remote_socket, 3);
		} elsif ($config{'petAutoKeep'} == 2) {
			if (timeOut(\%{$timeout{'ai_petAuto_keep'}}) &&
				(($chars[$config{'char'}]{'pet'}{'hungry'} <= $config{'petAutoKeep_hungry'}) ||
				($chars[$config{'char'}]{'pet'}{'friendly'} <= $config{'petAutoKeep_friendly_lower'}) ||
				($config{'petAutoKeep_friendly_upper'} > 0 && $chars[$config{'char'}]{'pet'}{'friendly'} >= $config{'petAutoKeep_friendly_upper'}))) {
				PrintMessage("Auto-keep on pet, hungry is $chars[$config{'char'}]{'pet'}{'hungry'} and friendly is $chars[$config{'char'}]{'pet'}{'friendly'}.", "brown");
				$timeout{'ai_petAuto_keep'}{'time'} = time;
				sendPetCommand(\$remote_socket, 3);
			}

			if ($config{'petAutoKeep_autoFriendly'} > 0 &&
				$chars[$config{'char'}]{'pet'}{'friendly'} - $config{'petAutoKeep_friendly_lower'} > $config{'petAutoKeep_autoFriendly_range'}) {
				configModify("petAutoKeep_friendly_lower", $chars[$config{'char'}]{'pet'}{'friendly'} - $config{'petAutoKeep_autoFriendly_range'});
			}
		}

		if ($timeout_ex{'petAutoPlay'}{'timeout'} != $config{'petAutoPlay_wait'}) {
			$timeout_ex{'petAutoPlay'}{'time'} = time;
			$timeout_ex{'petAutoPlay'}{'timeout'} = $config{'petAutoPlay_wait'};
		}

		if ($config{'petAutoPlay'} > 0 && timeOut(\%{$timeout_ex{'petAutoPlay'}})) {
			PrintMessage("Auto-play on pet every $config{'petAutoPlay_wait'} seconds.", "brown");
			sendPetCommand(\$remote_socket, 2);
			$timeout_ex{'petAutoPlay'}{'time'} = time;
		}
	}

	Debug('AI petAuto');

	if ($ai_seq[0] eq "") {
		UpdateWrapperAiEnd('-');
	} else {
		UpdateWrapperAiEnd($ai_seq[0]);
	}

	##########

	#DEBUG CODE
	if (time - $ai_v{'time'} > 2 && $debug{'ai_seq'}) {
		$stuff = @ai_seq_args;
		DebugMessage("- AI: @ai_seq | $stuff\n");
		$ai_v{'time'} = time;
	}

	if ($ai_v{'clear_aiQueue'}) {
		undef $ai_v{'clear_aiQueue'};
		undef @ai_seq;
		undef @ai_seq_args;
	}

	if (%{$chars[$config{'char'}]{'pet'}}) {
		$chars[$config{'char'}]{'pet'}{'action'} = 0;
	}
} # END AI

#######################################
#######################################
#Parse RO Client Send Message
#######################################
#######################################

sub parseSendMsg {
	my $msg = shift;
	$sendMsg = $msg;
	if (length($msg) >= 4 && $conState >= 4 && length($msg) >= unpack("S1", substr($msg, 0, 2))) {
		decrypt(\$msg, $msg);
	}

	$switch = uc(unpack("H2", substr($msg, 1, 1))).uc(unpack("H2", substr($msg, 0, 1)));

	if ($dpackets{$switch}) {
		dumpSendPacket($msg);
	}

	if ($spackets{$switch}{'desc'} eq "" || ($spackets{$switch}{'length'} && $spackets{$switch}{'length'} != length($msg))) {
		print "CLIENT SEND PACKET: $switch\n" if ($debug{'sendPacket'} || $debug{'sendPacketFromClient'} || $debug{'sendUnknownPacket'});
		dumpSendPacket($msg) if ($config{'dumpUnknownPacket'});
		$spackets{$switch}{'length'} = length($msg);
		$update{'packet'} = 1;
	} else {
		print "CLIENT SEND PACKET: $switch $spackets{$switch}{'desc'}\n" if ($debug{'sendPacket'} || $debug{'sendPacketFromClient'});
	}

	if ($switch eq "0066") {
		configModify("char", unpack("C*",substr($msg, 2, 1)));
		SetWrapperTitle();
	} elsif ($switch eq "0072") {
		initConnectVars();
		if ($config{'sex'} ne "") {
			$sendMsg = substr($sendMsg, 0, 18) . pack("C",$config{'sex'});
		}
	} elsif ($switch eq "007D") {
		$conState = 5;
		$timeout{'ai'}{'time'} = time;

		print "Map loaded.\n";

		if ($AI_mapOff) {
			$AI = 1;
			undef $AI_mapOff;
		}
	} elsif ($switch eq "0085") {
		aiRemove("clientSuspend");
		makeCoords(\%coords, substr($msg, 2, 3));
		ai_clientSuspend($switch, (distance(\%{$chars[$config{'char'}]{'pos'}}, \%coords) * $config{'seconds_per_block'}) + 2);
	} elsif ($switch eq "0089") {
		if (!($config{'tankMode'} && binFind(\@ai_seq, "attack") ne "")) {
			aiRemove("clientSuspend");
			ai_clientSuspend($switch, 2, unpack("C*",substr($msg,6,1)), substr($msg,2,4));
		} else {
			undef $sendMsg;
		}
	} elsif ($switch eq "008C" || $switch eq "0108" || $switch eq "017E") {
		$length = unpack("S",substr($msg,2,2));
		$message = substr($msg, 4, $length - 4);
		($chat) = $message =~ /^[\s\S]*? : ([\s\S]*)\000/;
		$chat =~ s/^\s*//;
		if ($chat =~ /^$config{'commandPrefix'}/) {
			$chat =~ s/^$config{'commandPrefix'}//;
			$chat =~ s/^\s*//;
			$chat =~ s/\s*$//;
			parseInput($chat, 1);
			undef $sendMsg;
		}
	} elsif ($switch eq "0096") {
		$length = unpack("S",substr($msg,2,2));
		($privMsgUser) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
		$privMsg = substr($msg, 28, $msg_size - 29);

		$lastpm{'user'} = $privMsgUser;
		$lastpm{'msg'} = $privMsg;

		ChatWrapper($privMsgUser, $privMsg, "pm");
		OnChat("", $privMsgUser, $privMsg, "pm");
	} elsif ($switch eq "009A") {
		$length = unpack("S",substr($msg,2,2));
		($msg) = substr($msg, 4, $length - 4) =~ /([\s\S]*?)\000/;
		PrintMessage("$msg", "brown");
	} elsif ($switch eq "009B") {
		$body = unpack("C1",substr($msg, 4, 1));
		$head = unpack("C1",substr($msg, 2, 1));

		$chars[$config{'char'}]{'look'}{'head'} = $head;
		$chars[$config{'char'}]{'look'}{'body'} = $body;
		print "You look at $chars[$config{'char'}]{'look'}{'body'}, $chars[$config{'char'}]{'look'}{'head'}\n" if ($config{'debug'} >= 2);
	} elsif ($switch eq "009F") {
		aiRemove("clientSuspend");
		ai_clientSuspend($switch, 2, substr($msg,2,4));
	} elsif ($switch eq "00B2") {
		aiRemove("clientSuspend");
		ai_clientSuspend($switch, 10);
	} elsif ($switch eq "012E") {
		undef %shop;
		$chars[$config{'char'}]{'shop'} = 0;
		stand();
	} elsif ($switch eq "018A") {
		# Trying to exit
		aiRemove("clientSuspend");
		ai_clientSuspend($switch, 10);
	} elsif ($switch eq "019F") {
		# Pet catch
		$timecount{'catch'}{'stop'} = time;
		$timecount{'catch'}{'count'} = $timecount{'catch'}{'stop'} - $timecount{'catch'}{'start'};
		PrintMessage("Time count :: Catch = $timecount{'catch'}{'count'} seconds", "brown");
	}

	if ($sendMsg ne "") {
		sendToServerByInject(\$remote_socket, $sendMsg);
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

	if (length($msg) < 2) {
		# My bot was received message length 1. It's possible!!
		return $msg;
	}

	$switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));
	if (length($msg) >= 4 && substr($msg,0,4) ne $accountID && $conState >= 4 && $lastswitch ne $switch
		&& length($msg) >= unpack("S1", substr($msg, 0, 2))) {
		decrypt(\$msg, $msg);
	}

	$switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));
	$switch_no = unpack("S1", substr($msg, 0, 2));

	if ($lastswitch eq $switch && length($msg) > $lastMsgLength) {
		$errorCount++;
	} else {
		$errorCount = 0;
	}

	if ($errorCount > 3) {
		dumpReceivePacket($msg);
		$msg_size = length($msg);
		print "$last_know_switch > $switch ($msg_size): Caught unparsed packet error, potential loss of data.\n";
		$errorCount = 0;
	}

	$lastswitch = $switch;

	if (substr($msg,0,4) ne $accountID || ($conState != 2 && $conState != 4)) {
		if (%{$rpackets{$switch}}) {
			if ($rpackets{$switch}{'length'} eq "-") {
				$msg_size = length($msg);
			} elsif ($rpackets{$switch}{'length'} eq "0") {
				if (length($msg) < 4) {
					return $msg;
				}

				$msg_size = unpack("S1", substr($msg, 2, 2));

				if (length($msg) < $msg_size) {
					return $msg;
				}
			} elsif ($rpackets{$switch}{'length'} > 1) {
				if (length($msg) < $rpackets{$switch}{'length'}) {
					return $msg;
				}

				$msg_size = $rpackets{$switch}{'length'};
			}

			if ($rpackets{$switch}{'desc'} eq "") {
				print "RECEIVE PACKET: $switch\n" if ($debug{'receivePacket'} || $debug{'receiveUnknownPacket'});
				dumpReceivePacket(substr($msg, 0, $msg_size)) if ($config{'dumpUnknownPacket'});
			} else {
				print "RECEIVE PACKET: $switch $rpackets{$switch}{'desc'}\n" if ($debug{'receivePacket'});
			}

			$last_know_msg = substr($msg, 0, $msg_size);
			$last_know_switch = $switch;
		} else {
			print "RECEIVE PACKET: $last_know_switch > $switch\n" if ($debug{'receivePacket'} || $debug{'receiveUnparsePacket'});
			dumpReceivePacket($last_know_msg.$msg);
		}

		if ($dpackets{$switch}) {
			dumpReceivePacket(substr($msg, 0, $msg_size));
		}
	}

	$lastMsgLength = length($msg);
	if ((substr($msg,0,4) eq $accountID && ($conState == 2 || $conState == 4)) || (!$accountID && length($msg) == 4)) {
		$accountID = substr($msg,0,4);
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
	} elsif ($switch eq "0069") {
		$conState = 2;
		undef $conState_tries;
		if ($versionSearch) {
			$versionSearch = 0;
			writeDataFileIntact("$profile/config.txt", \%config);
		}
		$sessionID = substr($msg, 4, 4);
		$accountID = substr($msg, 8, 4);
		$sessionID2 = substr($msg, 12, 4);
		$accountSex = unpack("C1",substr($msg, 46, 1));
		$accountSex2 = ($config{'sex'} ne "") ? $config{'sex'} : $accountSex;

		PrintFormat(<<'ACCOUNT', getHex($accountID), $sex_lut{$accountSex}, getHex($sessionID), getHex($sessionID2));
-------- Account Info ----------
Account ID:  @<<<<<<<<<<<<<<<<<<
Sex:         @<<<<<<<<<<<<<<<<<<
Session ID1: @<<<<<<<<<<<<<<<<<<
Session ID2: @<<<<<<<<<<<<<<<<<<
--------------------------------
ACCOUNT

		$num = 0;
		undef @servers;
		for($i = 47; $i < $msg_size; $i+=32) {
			$servers[$num]{'ip'} = makeIP(substr($msg, $i, 4));
			$servers[$num]{'port'} = unpack("S1", substr($msg, $i+4, 2));
			($servers[$num]{'name'}) = substr($msg, $i + 6, 20) =~ /([\s\S]*?)\000/;
			$servers[$num]{'users'} = unpack("L",substr($msg, $i + 26, 4));
			$num++;
		}

		print "----------------------- Servers -----------------------\n";
		print "#         Name            Users  IP              Port\n";
		for ($num = 0; $num < @servers; $num++) {
			PrintFormat(<<'SERVERS', $num, $servers[$num]{'name'}, $servers[$num]{'users'}, $servers[$num]{'ip'}, $servers[$num]{'port'});
@<< @<<<<<<<<<<<<<<<<<<<< @<<<<< @<<<<<<<<<<<<<< @<<<<<
SERVERS
		}
		print "-------------------------------------------------------\n";

		if ($config{'remoteSocket'}) {
			PrintMessage("Closing connection to Master Server", "lightblue");
			killConnection(\$remote_socket);
			if (!$config{'charServer_host'} && $config{'server'} eq "") {
				print "Choose your server.  Enter the server number:\n";
				$waitingForInput = 1;
			} elsif ($config{'charServer_host'}) {
				print "Forcing connect to char server $config{'charServer_host'}:$config{'charServer_port'}\n";
			} else {
				print "Server $config{'server'} selected\n";
			}
		}
	} elsif ($switch eq "006A") {
		$type = unpack("C1",substr($msg, 2, 1));
		if ($type == 0) {
			print "Account name doesn't exist\n";
			if ($config{'remoteSocket'} && !$config{'wrapperInterface'}) {
				print "Enter Username Again:\n";
				$input_socket->recv($msg, $MAX_READ);
				$config{'username'} = $msg;
				writeDataFileIntact("$profile/config.txt", \%config);
			}
		} elsif ($type == 1) {
			print "Password Error\n";
			if ($config{'remoteSocket'} && !$config{'wrapperInterface'}) {
				print "Enter Password Again:\n";
				$input_socket->recv($msg, $MAX_READ);
				$config{'password'} = $msg;
				writeDataFileIntact("$profile/config.txt", \%config);
			}
		} elsif ($type == 3) {
			print "Server connection has been denied\n";
		} elsif ($type == 4) {
			print "Critical Error: Account has been disabled by evil Gravity\n";

			if ($config{'wrapperInterface'}) {
				$input = Kore::Wrapper::WaitInput();
			} else {
				undef $input;
				while (1) {
					if (dataWaiting(\$input_socket)) {
						$input_socket->recv($input, $MAX_READ);
					}
					last if $input;
				}
			}

			$quit = 1;
		} elsif ($type == 5) {
			print "Version $config{'version'} failed...trying to find version\n";
			$config{'version'}++;
			if (!$versionSearch) {
				#$config{'version'} = 0;
				$versionSearch = 1;
			}
		} elsif ($type == 6) {
			print "The server is temporarily blocking your connection\n";
		}
		if ($type != 5 && $versionSearch) {
			$versionSearch = 0;
			writeDataFileIntact("$profile/config.txt", \%config);
		}

		if (($type == 0 || $type == 1) && $config{'remoteSocket'} && $config{'wrapperInterface'}) {
			if ($config{'master'} eq "" || !$config{'username'} || !$config{'password'}) {
				$i = 0;
				while ($config{"master_name_$i"} ne "") {
					Kore::Wrapper::AddMasterServer($config{"master_name_$i"});
					$i++;
				}

				Kore::Wrapper::Login($config{'master'}, $config{'username'}, $config{'password'});
				$user = Kore::Wrapper::WaitInput();
				$pwd = Kore::Wrapper::WaitInput();
				$master = Kore::Wrapper::WaitInput();

				$i = 0;
				while ($config{"master_name_$i"} ne $master) {
					$i++;
				}

				$config{'username'} = $user;
				$config{'password'} = $pwd;
				$config{'master'} = $i;
				writeDataFileIntact("$profile/config.txt", \%config);
			}
		}
	} elsif ($switch eq "006B") {
		print "Recieved characters from Game Login Server\n";
		$conState = 3;
		undef $conState_tries;
		if ($config{"master_version_$config{'master'}"} ne "" && $config{"master_version_$config{'master'}"} == 0) {
			$startVal = 24;
		} else {
			$startVal = 4;
		}
		for($i = $startVal; $i < $msg_size; $i+=106) {

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
			$chars[$num]{'job_name'} = $jobs_lut{$chars[$num]{'jobID'}};
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
		for ($num = 0; $num < @chars; $num++) {
			PrintFormat(<<'CHAR', $num, $chars[$num]{'name'}, $jobs_lut{$chars[$num]{'jobID'}}, $chars[$num]{'hp'}, $chars[$num]{'hp_max'}, $chars[$num]{'sp'}, $chars[$num]{'sp_max'}, $chars[$num]{'lv'}, $chars[$num]{'exp'}, $chars[$num]{'lv_job'}, $chars[$num]{'exp_job'}, $chars[$num]{'str'}, $chars[$num]{'agi'}, $chars[$num]{'vit'}, $chars[$num]{'int'}, $chars[$num]{'dex'}, $chars[$num]{'luk'}, $chars[$num]{'zenny'});
-------- Character @< ---------
Name: @<<<<<<<<<<<<<<<<<<<<<<<<
Job:  @<<<<<<<
HP:   @||||/@||||   SP:    @||||/@||||
Lv:   @<<<<<<<      Exp:   @<<<<<<<
J.Lv: @<<<<<<<      J.Exp: @<<<<<<<
Str:  @<<<<<<<<     Agi:   @<<<<<<<<
Vit:  @<<<<<<<<     Int:   @<<<<<<<<
Dex:  @<<<<<<<<     Luk:   @<<<<<<<<
Zenny: @<<<<<<<<<<
CHAR
		}
		print "-------------------------------\n";

		if ($config{'remoteSocket'}) {
			if ($config{'char'} eq "") {
				print "Choose your character.  Enter the character number:\n";
				$waitingForInput = 1;
			} else {
				print "Character $config{'char'} selected\n";
				sendCharLogin(\$remote_socket, $config{'char'});
				SetWrapperTitle();
				$timeout{'gamelogin'}{'time'} = time;
			}
		}

		$msg_size = length($msg);
	} elsif ($switch eq "006C") {
		print "Error logging into Game Login Server (invalid character specified)...\n";
		$conState = 1;
		undef $conState_tries;
	} elsif ($switch eq "006E") {
	} elsif ($switch eq "0071") {
		print "Recieved character ID and Map IP from Game Login Server\n";
		$conState = 4;
		undef $conState_tries;
		$charID = substr($msg, 2, 4);

		initMapChangeVars();

		($map_name) = substr($msg, 6, 16) =~ /([\s\S]*?)\000/;

		($ai_v{'temp'}{'map'}) = $map_name =~ /([\s\S]*)\./;
		if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
			getField("fields/$ai_v{'temp'}{'map'}.fld", \%field);
			OnYou($EV_MAP_CHANGED);
		}

		$map_ip = makeIP(substr($msg, 22, 4));
		$map_port = unpack("S1", substr($msg, 26, 2));
		PrintFormat(<<'CHARINFO', getHex($charID), $map_name, $map_ip, $map_port);
-------- Game Info ----------
Char ID:  @<<<<<<<<<<<<<<<<<<
MAP Name: @<<<<<<<<<<<<<<<<<<
MAP IP:   @<<<<<<<<<<<<<<<<<<
MAP Port: @<<<<<<<<<<<<<<<<<<
-----------------------------
CHARINFO

		if ($config{'remoteSocket'}) {
			PrintMessage("Closing connection to Game Login Server", "lightblue");
			killConnection(\$remote_socket);
		}

		$chars[$config{'char'}]{'usewing'} = 1;
	} elsif ($switch eq "0073") {
		undef $conState_tries;
		makeCoords(\%{$chars[$config{'char'}]{'pos'}}, substr($msg, 6, 3));
		%{$chars[$config{'char'}]{'pos_to'}} = %{$chars[$config{'char'}]{'pos'}};
		print "Your Coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n" if $config{'debug'};

		if ($config{'remoteSocket'}) {
			$conState = 5;
			PrintMessage("You are now in the game.", "white");
			sendMapLoaded(\$remote_socket);
			$timeout{'ai'}{'time'} = time;

			if ($config{'aiStart'} eq "") {
				$AI = 1;
			} else {
				$AI = $config{'aiStart'};
			}

			if ($AI) {
				if ($config{'waitOnStart'} eq "") {
					ai_clientSuspend(0, 5);
				} else {
					ai_clientSuspend(0, $config{'waitOnStart'});
				}
			}
		} else {
			print "Waiting for map to load...\n";

			if ($config{'aiStart'} eq "") {
				$AI = 1;
			} else {
				$AI = $config{'aiStart'};
			}

			if ($AI) {
				$AI_mapOff = 1;
				undef $AI;
			}
		}

		if ($config{'petAutoKeep_autoFriendly'} > 0) {
			configModify("petAutoKeep_friendly_lower", 0);
		}
	} elsif ($switch eq "0075") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
	} elsif ($switch eq "0077") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
	} elsif ($switch eq "0078") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}

		$ID = substr($msg, 2, 4);
		$critical = unpack("S*", substr($msg, 8, 2));
		$warning = unpack("S*", substr($msg, 10, 2));
		$option = unpack("S*", substr($msg, 12, 2));
		$type = unpack("S*",substr($msg, 14,  2));
		$pet = unpack("C*",substr($msg, 16,  1));
		$charlowheadID = $charHead_lut{unpack("S1",substr($msg, 20,  2))};
		$chartopheadID = $charHead_lut{unpack("S1",substr($msg, 24,  2))};
		$charmidheadID = $charHead_lut{unpack("S1",substr($msg, 26,  2))};
		$guildID = substr($msg, 34,  4);
		$sex = unpack("C*",substr($msg, 45,  1));
		makeCoords(\%coords, substr($msg, 46, 3));
		$act = unpack("C*",substr($msg, 51,  1));
		# 4.0
		$lv = unpack("S*",substr($msg, 52,  2));
		if ($type >= 1000) {
			if ($pet) {
				if (%{$chars[$config{'char'}]{'pet'}} && $chars[$config{'char'}]{'pet'}{'ID'} eq $ID) {
					if ($chars[$config{'char'}]{'pet'}{'type'} eq "") {
						$chars[$config{'char'}]{'pet'}{'nameID'} = $type;
						$chars[$config{'char'}]{'pet'}{'type'} = ($monsters_lut{$type}{'name'} ne "") ? $monsters_lut{$type}{'name'} : "Unknown ".$type;
					}

					%{$chars[$config{'char'}]{'pet'}{'pos'}} = %coords;
					%{$chars[$config{'char'}]{'pet'}{'pos_to'}} = %coords;
				} else {
					if (!%{$pets{$ID}}) {
						$pets{$ID}{'appear_time'} = time;
						$display = ($monsters_lut{$type}{'name'} ne "")
								? $monsters_lut{$type}{'name'}
								: "Unknown ".$type;
						binAdd(\@petsID, $ID);
						$pets{$ID}{'nameID'} = $type;
						$pets{$ID}{'name'} = $display;
						$pets{$ID}{'name_given'} = "Unknown";
						$pets{$ID}{'binID'} = binFind(\@petsID, $ID);
					} elsif ($pets{$ID}{'name'} eq "Unknown") {
						$display = ($monsters_lut{$type}{'name'} ne "")
								? $monsters_lut{$type}{'name'}
								: "Unknown ".$type;
						$pets{$ID}{'nameID'} = $type;
						$pets{$ID}{'name'} = $display;
					}
					%{$pets{$ID}{'pos'}} = %coords;
					%{$pets{$ID}{'pos_to'}} = %coords;
					print "Pet Exists: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});
				}

				OnPet($ID, $EV_EXISTS);

				if (%{$monsters{$ID}}) {
					OnMonster($ID, $EV_REMOVED);
					binRemove(\@monstersID, $ID);
					#undef %{$monsters{$ID}};
					delete $monsters{$ID};
				}
			} else {
				if (!%{$monsters{$ID}}) {
					$monsters{$ID}{'appear_time'} = time;
					$display = ($monsters_lut{$type}{'name'} ne "")
							? $monsters_lut{$type}{'name'}
							: "Unknown ".$type;
					binAdd(\@monstersID, $ID);
					$monsters{$ID}{'nameID'} = $type;
					$monsters{$ID}{'name'} = $display;
					$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
				}
				SetStatus($monsters{$ID}, $critical, $warning, $option);
				%{$monsters{$ID}{'pos'}} = %coords;
				%{$monsters{$ID}{'pos_to'}} = %coords;
				print "Monster Exists: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if ($config{'debug'});

				OnMonster($ID, $EV_EXISTS);
			}

		} elsif ($jobs_lut{$type}) {
			if (!%{$players{$ID}}) {
				$players{$ID}{'appear_time'} = time;
				binAdd(\@playersID, $ID);
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'name'} = "Unknown";
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);
			}
			$players{$ID}{'lv'} = $lv;
			$players{$ID}{'dead'} = ($act == 1);
			$players{$ID}{'sitting'} = ($act == 2);
			$players{$ID}{'look'}{'lowHead'} = $charlowheadID;
			$players{$ID}{'look'}{'topHead'} = $chartopheadID;
			$players{$ID}{'look'}{'midHead'} = $charmidheadID;
			SetStatus($players{$ID}, $critical, $warning, $option);
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
			print "Player Exists: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});

			OnPlayer($ID, $EV_EXISTS);
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
			print "Portal Exists: $portals{$ID}{'name'} - ($portals{$ID}{'binID'})\n" if $config{'debug'};

			OnYou($EV_PORTAL_EXISTS, $ID);
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
			print "NPC Exists: $npcs{$ID}{'name'} - ($npcs{$ID}{'binID'})\n" if $config{'debug'};

			OnNpc($ID, $EV_EXISTS);
		} else {
			PrintMessage("Unknown Exists: $type - ".unpack("L*",$ID), "red");
		}
	} elsif ($switch eq "0079") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		$ID = substr($msg, 2, 4);
		$critical = unpack("S*", substr($msg, 8, 2));
		$warning = unpack("S*", substr($msg, 10, 2));
		$option = unpack("S*", substr($msg, 12, 2));
		$type = unpack("S*",substr($msg, 14,  2));
		$charlowheadID = $charHead_lut{unpack("S1",substr($msg, 20,  2))};
		$chartopheadID = $charHead_lut{unpack("S1",substr($msg, 24,  2))};
		$charmidheadID = $charHead_lut{unpack("S1",substr($msg, 26,  2))};
		$guildID = substr($msg, 34,  4);
		$sex = unpack("C*",substr($msg, 45,  1));
		makeCoords(\%coords, substr($msg, 46, 3));
		# 4.0
		$lv = unpack("S*",substr($msg, 51,  2));
		if ($jobs_lut{$type}) {
			if (!%{$players{$ID}}) {
				$players{$ID}{'appear_time'} = time;
				binAdd(\@playersID, $ID);
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'name'} = "Unknown";
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);
			}
			$players{$ID}{'lv'} = $lv;
			$players{$ID}{'look'}{'lowHead'} = $charlowheadID;
			$players{$ID}{'look'}{'topHead'} = $chartopheadID;
			$players{$ID}{'look'}{'midHead'} = $charmidheadID;
			SetStatus($players{$ID}, $critical, $warning, $option);
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
			print "Player Connected: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});
			OnPlayer($ID, $EV_CONNECTED);
		} else {
			PrintMessage("Unknown Connected: $type - ".getHex($ID), "red");
		}
	} elsif ($switch eq "007A") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
	} elsif ($switch eq "007B") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		$ID = substr($msg, 2, 4);
		$critical = unpack("S*", substr($msg, 8, 2));
		$warning = unpack("S*", substr($msg, 10, 2));
		$option = unpack("S*", substr($msg, 12, 2));
		$type = unpack("S*",substr($msg, 14,  2));
		$pet = unpack("C*",substr($msg, 16,  1));
		$charlowheadID = $charHead_lut{unpack("S1",substr($msg, 20,  2))};
		$chartopheadID = $charHead_lut{unpack("S1",substr($msg, 28,  2))};
		$charmidheadID = $charHead_lut{unpack("S1",substr($msg, 30,  2))};
		$guildID = substr($msg, 38,  4);
		$sex = unpack("C*",substr($msg, 49,  1));
		makeCoords(\%coordsFrom, substr($msg, 50, 3));
		makeCoords2(\%coordsTo, substr($msg, 52, 3));
		# 4.0
		$lv = unpack("S*",substr($msg, 58,  2));
		if ($type >= 1000) {
			if ($pet) {
				if (%{$chars[$config{'char'}]{'pet'}} && $chars[$config{'char'}]{'pet'}{'ID'} eq $ID) {
					if ($chars[$config{'char'}]{'pet'}{'type'} eq "") {
						$chars[$config{'char'}]{'pet'}{'nameID'} = $type;
						$chars[$config{'char'}]{'pet'}{'type'} = ($monsters_lut{$type}{'name'} ne "") ? $monsters_lut{$type}{'name'} : "Unknown ".$type;
					}

					%{$chars[$config{'char'}]{'pet'}{'pos'}} = %coords;
					%{$chars[$config{'char'}]{'pet'}{'pos_to'}} = %coords;

					$action = $EV_MOVE;
				} else {
					if (!%{$pets{$ID}}) {
						$pets{$ID}{'appear_time'} = time;
						$display = ($monsters_lut{$type}{'name'} ne "")
								? $monsters_lut{$type}{'name'}
								: "Unknown ".$type;
						binAdd(\@petsID, $ID);
						$pets{$ID}{'nameID'} = $type;
						$display = ($monsters_lut{$pets{$ID}{'nameID'}}{'name'} ne "")
						? $monsters_lut{$pets{$ID}{'nameID'}}{'name'}
						: "Unknown ".$pets{$ID}{'nameID'};
						$pets{$ID}{'name'} = $display;
						$pets{$ID}{'binID'} = binFind(\@petsID, $ID);
						print "Pet Appeared: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});
						$action = $EV_APPEARED;
					} elsif ($pets{$ID}{'name'} eq "Unknown") {
						$display = ($monsters_lut{$type}{'name'} ne "")
								? $monsters_lut{$type}{'name'}
								: "Unknown ".$type;
						$pets{$ID}{'nameID'} = $type;
						$pets{$ID}{'name'} = $display;
						$action = $EV_APPEARED;
					} else {
						$action = $EV_MOVE;
					}
					%{$pets{$ID}{'pos'}} = %coords;
					%{$pets{$ID}{'pos_to'}} = %coords;

					print "Pet Moved: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'} >= 2);
				}

				OnPet($ID, $action);

				if (%{$monsters{$ID}}) {
					OnMonster($ID, $EV_REMOVED);
					binRemove(\@monstersID, $ID);
					#undef %{$monsters{$ID}};
					delete $monsters{$ID};
				}
			} else {
				if (!%{$monsters{$ID}}) {
					binAdd(\@monstersID, $ID);
					$monsters{$ID}{'appear_time'} = time;
					$monsters{$ID}{'nameID'} = $type;
					$display = ($monsters_lut{$type}{'name'} ne "")
						? $monsters_lut{$type}{'name'}
						: "Unknown ".$type;
					$monsters{$ID}{'name'} = $display;
					$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
					print "Monster Appeared: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if $config{'debug'};
					$action = $EV_APPEARED;
				} else {
					$action = $EV_MOVE;
				}

				SetStatus($monsters{$ID}, $critical, $warning, $option);
				%{$monsters{$ID}{'pos'}} = %coordsFrom;
				%{$monsters{$ID}{'pos_to'}} = %coordsTo;
				print "Monster Moved: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if ($config{'debug'} >= 2);

				OnMonster($ID, $action);
			}
		} elsif ($jobs_lut{$type}) {
			if (!%{$players{$ID}}) {
				binAdd(\@playersID, $ID);
				$players{$ID}{'appear_time'} = time;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'name'} = "Unknown";
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);

				print "Player Appeared: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$sex} $jobs_lut{$type}\n" if $config{'debug'};
				$action = $EV_APPEARED;
			} else {
				$action = $EV_MOVE;
			}

			$players{$ID}{'lv'} = $lv;
			$players{$ID}{'look'}{'lowHead'} = $charlowheadID;
			$players{$ID}{'look'}{'topHead'} = $chartopheadID;
			$players{$ID}{'look'}{'midHead'} = $charmidheadID;
			SetStatus($players{$ID}, $critical, $warning, $option);
			%{$players{$ID}{'pos'}} = %coordsFrom;
			%{$players{$ID}{'pos_to'}} = %coordsTo;
			print "Player Moved: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'} >= 2);

			OnPlayer($ID, $action);
		} else {
			PrintMessage("Unknown Moved: $type - ".getHex($ID), "red");
		}
	} elsif ($switch eq "007C") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		$ID = substr($msg, 2, 4);
		makeCoords(\%coords, substr($msg, 36, 3));
		$type = unpack("S*",substr($msg, 20,  2));
		$sex = unpack("C*",substr($msg, 35,  1));
		if ($type >= 1000) {
			if (%{$chars[$config{'char'}]{'pet'}} && $chars[$config{'char'}]{'pet'}{'ID'} eq $ID) {
				if ($chars[$config{'char'}]{'pet'}{'type'} eq "") {
					$chars[$config{'char'}]{'pet'}{'nameID'} = $type;
					$chars[$config{'char'}]{'pet'}{'type'} = ($monsters_lut{$type}{'name'} ne "") ? $monsters_lut{$type}{'name'} : "Unknown ".$type;
				}

				%{$chars[$config{'char'}]{'pet'}{'pos'}} = %coords;
				%{$chars[$config{'char'}]{'pet'}{'pos_to'}} = %coords;

				OnPet($ID, $EV_SPAWNED);
			} else {
				if (!%{$monsters{$ID}}) {
					binAdd(\@monstersID, $ID);
					$monsters{$ID}{'nameID'} = $type;
					$monsters{$ID}{'appear_time'} = time;
					$display = ($monsters_lut{$monsters{$ID}{'nameID'}}{'name'} ne "")
							? $monsters_lut{$monsters{$ID}{'nameID'}}{'name'}
							: "Unknown ".$monsters{$ID}{'nameID'};
					$monsters{$ID}{'name'} = $display;
					$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
				}
				%{$monsters{$ID}{'pos'}} = %coords;
				%{$monsters{$ID}{'pos_to'}} = %coords;

				print "Monster Spawned: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if ($config{'debug'});
				OnMonster($ID, $EV_SPAWNED);
			}
		} elsif ($jobs_lut{$type}) {
			if (!%{$players{$ID}}) {
				binAdd(\@playersID, $ID);
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'name'} = "Unknown";
				$players{$ID}{'appear_time'} = time;
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);
			}
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
			print "Player Spawned: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});
			OnPlayer($ID, $EV_SPAWNED);
		} else {
			PrintMessage("Unknown Spawned: $type - ".getHex($ID), "red");
		}
	} elsif ($switch eq "007F") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		$time = unpack("L1",substr($msg, 2, 4));
		print "Recieved Sync\n" if ($config{'debug'} >= 2);
		$timeout{'play'}{'time'} = time;
	} elsif ($switch eq "0080") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		$ID = substr($msg, 2, 4);
		$type = unpack("C1",substr($msg, 6, 1));

		if ($ID eq $accountID) {
			print "You have died\n";

			$chars[$config{'char'}]{'dead'} = 1;
			$chars[$config{'char'}]{'dead_time'} = time;

			OnYou($EV_DIED);
		} elsif (%{$monsters{$ID}}) {
			%{$monsters_old{$ID}} = %{$monsters{$ID}};
			$monsters_old{$ID}{'gone_time'} = time;
			if ($type == 0) {
				print "Monster Disappeared: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if $config{'debug'};
				$monsters_old{$ID}{'disappeared'} = 1;
				OnMonster($ID, $EV_DISAPPEARED);
			} elsif ($type == 1) {
				print "Monster Died: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if $config{'debug'};
				$monsters_old{$ID}{'dead'} = 1;
				OnMonster($ID, $EV_DIED);
			} else {
				PrintMessage("Monster lost ($type): $monsters{$ID}{'name'} [".getHex($ID)."]", "red");
				OnMonster($ID, $EV_REMOVED);
			}

			binRemove(\@monstersID, $ID);
			#undef %{$monsters{$ID}};
			delete $monsters{$ID};

			foreach (keys %monsters) {
				if ($_ eq $ID) {
					WriteLog("bug.txt", "0080: Remove Failed.\n");
				}
			}
		} elsif (%{$players{$ID}}) {
			if ($type == 0) {
				print "Player Disappeared: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if $config{'debug'};
				OnPlayer($ID, $EV_DISAPPEARED);
			} elsif ($type == 1) {
				print "Player Died: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if $config{'debug'};
				$players{$ID}{'dead'} = 1;
				OnPlayer($ID, $EV_DIED);
			} elsif ($type == 2) {
				if (IsPartyOnline($ID)) {
					$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 0;
					$chars[$config{'char'}]{'party'}{'users'}{$ID}{'move'} = 0;
				}

				print "Player Disconnected: $players{$ID}{'name'}\n" if $config{'debug'};
				OnPlayer($ID, $EV_DISCONNECTED);
			} elsif ($type == 3) {
				print "Player Teleported: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if $config{'debug'};
				OnPlayer($ID, $EV_TELEPORTED);
			} else {
				PrintMessage("Player lost ($type): $players{$ID}{'name'} [".getHex($ID)."]", "red");
				OnPlayer($ID, $EV_REMOVED);
			}

			if ($type != 1) {
				%{$players_old{$ID}} = %{$players{$ID}};
				if ($type == 2) {
					$players_old{$ID}{'disconnected'} = 1;
				} else {
					$players_old{$ID}{'disappeared'} = 1;
				}
				$players_old{$ID}{'gone_time'} = time;

				binRemove(\@playersID, $ID);
				#undef %{$players{$ID}};
				delete $players{$ID};

				if (%{$venderLists{$ID}}) {
					OnPlayer($ID, $EV_SHOP_DISAPPEARED);
					binRemove(\@venderListsID, $ID);
					#undef %{$venderLists{$ID}};
					delete $venderLists{$ID};
				}
			}
		} elsif (%{$players_old{$ID}}) {
			if ($type == 2) {
				print "Player Disconnected: $players_old{$ID}{'name'}\n" if $config{'debug'};
				$players_old{$ID}{'disconnected'} = 1;
				OnPlayer($ID, $EV_DISCONNECTED);
			}
		} elsif (%{$portals{$ID}}) {
			print "Portal Disappeared: $portals{$ID}{'name'} ($portals{$ID}{'binID'})\n" if ($config{'debug'});

			OnYou($EV_PORTAL_DISAPPEARED, $ID);

			%{$portals_old{$ID}} = %{$portals{$ID}};
			$portals_old{$ID}{'disappeared'} = 1;
			$portals_old{$ID}{'gone_time'} = time;
			binRemove(\@portalsID, $ID);
			#undef %{$portals{$ID}};
			delete $portals{$ID};
		} elsif (%{$npcs{$ID}}) {
			print "NPC Disappeared: $npcs{$ID}{'name'} ($npcs{$ID}{'binID'})\n" if ($config{'debug'});

			if ($ID eq $talk{'ID'}) {
				OnNpc($ID, $EV_TALK_DISAPPEARED);
			}

			OnNpc($ID, $EV_DISAPPEARED);

			%{$npcs_old{$ID}} = %{$npcs{$ID}};
			$npcs_old{$ID}{'disappeared'} = 1;
			$npcs_old{$ID}{'gone_time'} = time;

			binRemove(\@npcsID, $ID);
			#undef %{$npcs{$ID}};
			delete $npcs{$ID};
		} elsif (%{$pets{$ID}}) {
			print "Pet Disappeared: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});

			OnPet($ID, $EV_DISAPPEARED);

			binRemove(\@petsID, $ID);
			#undef %{$pets{$ID}};
			delete $pets{$ID};
		} else {
			#PrintMessage("Unknown Disappeared: ".getHex($ID), "red");
		}
	} elsif ($switch eq "0081") {
		$type = unpack("C1", substr($msg, 2, 1));
		$conState = 1;
		undef $conState_tries;
		if ($type == 2) {
			PrintMessage("Critical Error: Dual login prohibited - Someone trying to login!", "red");
			if ($config{'dcOnDualLogin'} == 1) {
				print "Disconnect immediately!\n";
				$quit = 1;
			} elsif ($config{'dcOnDualLogin'} >= 2) {
				print "Disconnect for $config{'dcOnDualLogin'} seconds...\n";
				$timeout_ex{'master'}{'time'} = time;
				$timeout_ex{'master'}{'timeout'} = $config{'dcOnDualLogin'};
			}
		} elsif ($type == 3) {
			PrintMessage("Error: Out of sync with server", "red");
		} elsif ($type == 4) {
			PrintMessage("You cannot connect at this point.", "red");
		} elsif ($type == 5) {
			PrintMessage("You cannot login because the age policy.", "red");
		} elsif ($type == 6) {
			PrintMessage("Your account was expired.", "red");
		} elsif ($type == 7) {
			PrintMessage("Server was exceed the limit.", "red");
		} elsif ($type == 8) {
			PrintMessage("Error: The server still recognizes your last connection.", "red");
		} elsif ($type == 11) {
			PrintMessage("Your account was banned.", "red");
		} elsif ($type == 12) {
			PrintMessage("Under construction.", "red");
		} elsif ($type == 13) {
			PrintMessage("Your IP was blocked.", "red");
		} elsif ($type == 15) {
			PrintMessage("Kicked by GM.", "red");
		} elsif ($type == 16) {
			PrintMessage("Payment system was changed.", "red");
		} elsif ($type == 18) {
			PrintMessage("This ID was login to another server.", "red");
		} else {
			PrintMessage("Unknown Error: $type", "red");
		}

		if (($type == 2 && $config{'dcOnDualLogin'} == 1) || $type == 5 || $type == 6 || $type == 15) {
			if ($config{'wrapperInterface'}) {
				$input = Kore::Wrapper::WaitInput();
			} else {
				undef $input;
				while (1) {
					if (dataWaiting(\$input_socket)) {
						$input_socket->recv($input, $MAX_READ);
					}
					last if $input;
				}
			}

			$quit = 1;
		}
	} elsif ($switch eq "0087") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		makeCoords(\%coordsFrom, substr($msg, 6, 3));
		makeCoords2(\%coordsTo, substr($msg, 8, 3));
		%{$chars[$config{'char'}]{'pos'}} = %coordsFrom;
		%{$chars[$config{'char'}]{'pos_to'}} = %coordsTo;

		$chars[$config{'char'}]{'look'}{'head'} = 0;
		$chars[$config{'char'}]{'look'}{'body'} = GetBodyDir(\%{$chars[$config{'char'}]{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});;

		print "You move to: $coordsTo{'x'}, $coordsTo{'y'}\n" if $config{'debug'};

		OnYou($EV_MOVE);

		$chars[$config{'char'}]{'time_move'} = time;
		$chars[$config{'char'}]{'time_move_calc'} = distance(\%{$chars[$config{'char'}]{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}) * $config{'seconds_per_block'};
	} elsif ($switch eq "0088") {
		# Long distance attack solution
		$ID = substr($msg, 2, 4);
		undef %coords;
		$coords{'x'} = unpack("S1", substr($msg, 6, 2));
		$coords{'y'} = unpack("S1", substr($msg, 8, 2));
		if ($ID eq $accountID) {
			%{$chars[$config{'char'}]{'pos'}} = %coords;
			%{$chars[$config{'char'}]{'pos_to'}} = %coords;

			OnYou($EV_MOVE_BREAK);

			print "Movement interrupted, your coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n" if $config{'debug'};
			aiRemove("move");
		} elsif (%{$monsters{$ID}}) {
			%{$monsters{$ID}{'pos'}} = %coords;
			%{$monsters{$ID}{'pos_to'}} = %coords;
		} elsif (%{$players{$ID}}) {
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
		} else {
			dumpReceivePacket(substr($msg, 0, 10)) if ($config{'debug_packet'} >= 2);
		}
	} elsif ($switch eq "008A") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		$ID1 = substr($msg, 2, 4);
		$ID2 = substr($msg, 6, 4);
		$damage = unpack("S1", substr($msg, 22, 2));
		$hit = unpack("S1", substr($msg, 24, 2));
		$type = unpack("C1", substr($msg, 26, 1));
		$damage2 = unpack("S1", substr($msg, 27, 2));
		if ($damage == 0) {
			$dmgdisplay = "Miss!";
		} else {
			$dmgdisplay = $damage;
		}
		updateDamageTables($ID1, $ID2, $damage);
		if ($ID1 eq $accountID) {
			if (%{$monsters{$ID2}}) {
				print "You attack Monster: $monsters{$ID2}{'name'} ($monsters{$ID2}{'binID'}) - Dmg: $dmgdisplay\n" if $config{'debug'};
				OnYou($EV_ATTACK_MONSTER, $ID2, $type, $hit, $damage, $damage2);
			} elsif (%{$items{$ID2}}) {
				print "You pick up Item: $items{$ID2}{'name'} ($items{$ID2}{'binID'})\n" if $config{'debug'};
				$items{$ID2}{'takenBy'} = $accountID;
				OnYou($EV_ITEM_PICKUP, $ID2);
			} elsif ($ID2 == 0) {
				if ($type == 3) {
					$chars[$config{'char'}]{'sitting'} = 0;
					print "You're Standing\n" if $config{'debug'};
					OnYou($EV_STAND, $ID2);
				} elsif ($type == 2) {
					$chars[$config{'char'}]{'sitting'} = 1;
					print "You're Sitting\n" if $config{'debug'};
					OnYou($EV_SIT, $ID2);
				}
			}
		} elsif ($ID2 eq $accountID) {
			if (%{$monsters{$ID1}}) {
				print "Monster attacks You: $monsters{$ID1}{'name'} ($monsters{$ID1}{'binID'}) - Dmg: $dmgdisplay\n" if $config{'debug'};
				OnMonster($ID1, $EV_ATTACK_YOU, $type, $hit, $damage, $damage2);
			}

			undef $chars[$config{'char'}]{'last_skill_cast'};
			undef $chars[$config{'char'}]{'last_time_cast'};
		} elsif (%{$monsters{$ID1}}) {
			if (%{$players{$ID2}}) {
				print "Monster $monsters{$ID1}{'name'} ($monsters{$ID1}{'binID'}) attacks Player $players{$ID2}{'name'} ($players{$ID2}{'binID'}) - Dmg: $dmgdisplay\n" if ($config{'debug'});
				OnMonster($ID1, $EV_ATTACK_PLAYER, $ID2, $type, $hit, $damage, $damage2);
			}

		} elsif (%{$players{$ID1}}) {
			if (%{$monsters{$ID2}}) {
				print "Player $players{$ID1}{'name'} ($players{$ID1}{'binID'}) attacks Monster $monsters{$ID2}{'name'} ($monsters{$ID2}{'binID'}) - Dmg: $dmgdisplay\n" if ($config{'debug'});
				OnPlayer($ID1, $EV_ATTACK_MONSTER, $ID2, $type, $hit, $damage, $damage2);
			} elsif (%{$items{$ID2}}) {
				$items{$ID2}{'takenBy'} = $ID1;
				print "Player $players{$ID1}{'name'} ($players{$ID1}{'binID'}) picks up Item $items{$ID2}{'name'} ($items{$ID2}{'binID'})\n" if ($config{'debug'});
				OnPlayer($ID1, $EV_ITEM_PICKUP, $ID2);
			} elsif ($ID2 == 0) {
				if ($type == 3) {
					$players{$ID1}{'sitting'} = 0;
					print "Player is Standing: $players{$ID1}{'name'} ($players{$ID1}{'binID'})\n" if $config{'debug'};
					OnPlayer($ID1, $EV_STAND);
				} elsif ($type == 2) {
					$players{$ID1}{'sitting'} = 1;
					print "Player is Sitting: $players{$ID1}{'name'} ($players{$ID1}{'binID'})\n" if $config{'debug'};
					OnPlayer($ID1, $EV_SIT);
				}
			}
		} else {
			print "Unknown ".getHex($ID1)." attacks ".getHex($ID2)." - Dmg: $dmgdisplay\n" if $config{'debug'};
		}
	} elsif ($switch eq "008D") {
		$ID = substr($msg, 4, 4);
		$chat = substr($msg, 8, $msg_size - 8);
		($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
		chatLog("c", $chat."\n");

		if ($chatMsg eq "") {
			ChatWrapper("", $chat, "c");
		} else {
			ChatWrapper($chatMsgUser, $chatMsg, "c");
			OnChat($ID, $chatMsgUser, $chatMsg, "c");
		}
	} elsif ($switch eq "008E") {
		$chat = substr($msg, 4, $msg_size - 4);
		($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
		chatLog("c", $chat."\n");

		if ($chatMsg eq "") {
			ChatWrapper("", $chat, "c");
		} else {
			ChatWrapper($chatMsgUser, $chatMsg, "c");
			OnChat($accountID, "me", $chatMsg, "c");
		}
	} elsif ($switch eq "0091") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		initMapChangeVars();
		for ($i = 0; $i < @ai_seq; $i++) {
			ai_setMapChanged($i);
		}
		($map_name) = substr($msg, 2, 16) =~ /([\s\S]*?)\000/;
		($ai_v{'temp'}{'map'}) = $map_name =~ /([\s\S]*)\./;
		if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
			getField("fields/$ai_v{'temp'}{'map'}.fld", \%field);
			OnYou($EV_MAP_CHANGED);
		}
		$coords{'x'} = unpack("S1", substr($msg, 18, 2));
		$coords{'y'} = unpack("S1", substr($msg, 20, 2));
		%{$chars[$config{'char'}]{'pos'}} = %coords;
		%{$chars[$config{'char'}]{'pos_to'}} = %coords;
		PrintMessage("Map Change: $map_name", "white");
		print "Your Coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n" if $config{'debug'};

		if ($config{'remoteSocket'}) {
			print "Sending Map Loaded\n" if $config{'debug'};
			sendMapLoaded(\$remote_socket);
		} else {
			if ($AI) {
				$AI_mapOff = 1;
				undef $AI;
			}
		}
	} elsif ($switch eq "0092") {
		$conState = 4;
		initMapChangeVars();
		undef $conState_tries;
		for ($i = 0; $i < @ai_seq; $i++) {
			ai_setMapChanged($i);
		}
		($map_name) = substr($msg, 2, 16) =~ /([\s\S]*?)\000/;
		($ai_v{'temp'}{'map'}) = $map_name =~ /([\s\S]*)\./;
		if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
			getField("fields/$ai_v{'temp'}{'map'}.fld", \%field);
			OnYou($EV_MAP_CHANGED);
		}
		$map_ip = makeIP(substr($msg, 22, 4));
		$map_port = unpack("S1", substr($msg, 26, 2));

		PrintFormat(<<'MAPINFO', $map_name, $map_ip, $map_port);
------ Map Change Info ------
MAP Name: @<<<<<<<<<<<<<<<<<<
MAP IP:   @<<<<<<<<<<<<<<<<<<
MAP Port: @<<<<<<<<<<<<<<<<<<
-----------------------------
MAPINFO

		if ($config{'remoteSocket'}) {
			PrintMessage("Closing connection to Map Server", "lightblue");
			killConnection(\$remote_socket);
		}

		$chars[$config{'char'}]{'usewing'} = 1;
	} elsif ($switch eq "0093") {
	} elsif ($switch eq "0095") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		$ID = substr($msg, 2, 4);

		if ($ID eq $whois{'ID'} && $whois{'request'}) {
			($whois{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			ChatWrapper("Whois ".unpack("L1", $whois{'ID'}), $whois{'name'}, "lightblue");
			undef $whois{'request'};
		}

		if (%{$players{$ID}}) {
			($players{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			if ($config{'debug'} >= 2) {
				$binID = binFind(\@playersID, $ID);
				print "Player Info: $players{$ID}{'name'} ($binID)\n";
			}

			OnPlayer($ID, $EV_GET_INFO);
		}
		if (%{$monsters{$ID}}) {
			($monsters{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			if ($config{'debug'} >= 2) {
				$binID = binFind(\@monstersID, $ID);
				print "Monster Info: $monsters{$ID}{'name'} ($binID)\n";
			}

			# New monster
			if ($monsters{$ID}{'nameID'} ne "" && $monsters{$ID}{'name'} ne "" && $monsters{$ID}{'name'} ne $monsters_lut{$monsters{$ID}{'nameID'}}{'name'}) {
				#foreach (keys %{monsters_lut}) {
				#	if ($monsters_lut{$_}{'name'} eq $monsters{$ID}{'name'}) {
						# Delete exist monster.
				#		delete $monsters_lut{$_};
				#		last;
				#	}
				#}

				DebugMessage("0095: FOUND MONSTER, ID: $monsters{$ID}{'nameID'}, NAME: $monsters{$ID}{'name'}") if ($debug{'msg0095'});

				$monsters_lut{$monsters{$ID}{'nameID'}}{'name'} = $monsters{$ID}{'name'};
				$update{'monster'} = 1;
				#updateMonsterLUT("tables/monsters.txt", $monsters{$ID}{'nameID'}, $monsters{$ID}{'name'});
			}

			OnMonster($ID, $EV_GET_INFO);
		}
		if (%{$npcs{$ID}}) {
			($npcs{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			if ($config{'debug'} >= 2) {
				$binID = binFind(\@npcsID, $ID);
				print "NPC Info: $npcs{$ID}{'name'} ($binID)\n";
			}

			#if (!%{$npcs_lut{$npcs{$ID}{'nameID'}}}) {
			# New NPC
			if ($npcs{$ID}{'nameID'} ne "" && $npcs{$ID}{'name'} ne "" && $npcs{$ID}{'name'} ne $npcs_lut{$npcs{$ID}{'nameID'}}{'name'}) {
				foreach (keys %{npcs_lut}) {
					if ($npcs_lut{$_}{'map'} eq $field{'name'} && $npcs_lut{$_}{'pos'}{'x'} == $npcs{$ID}{'pos'}{'x'} && $npcs_lut{$_}{'pos'}{'y'} == $npcs{$ID}{'pos'}{'y'}) {
						PrintMessage("Update NPC $_ -> $npcs{$ID}{'nameID'}", "yellow");

						if ($config{"storageAuto_npc"} eq $_) {
							configModify("storageAuto_npc", $npcs{$ID}{'nameID'});
						}

						if ($config{"sellAuto_npc"} eq $_) {
							configModify("sellAuto_npc", $npcs{$ID}{'nameID'});
						}

						$i = 0;
						while ($config{"buyAuto_$i"} ne "") {
							if ($config{"buyAuto_$i"."_npc"} eq $_) {
								configModify("buyAuto_$i"."_npc", $npcs{$ID}{'nameID'});
							}
							$i++;
						}

						# Delete exist NPC.
						delete $npcs_lut{$_};
						last;
					}
				}

				DebugMessage("0095: FOUND NPC, ID: $npcs{$ID}{'nameID'}, NAME: $npcs{$ID}{'name'}") if ($debug{'msg0095'});

				$npcs_lut{$npcs{$ID}{'nameID'}}{'name'} = $npcs{$ID}{'name'};
				$npcs_lut{$npcs{$ID}{'nameID'}}{'map'} = $field{'name'};
				%{$npcs_lut{$npcs{$ID}{'nameID'}}{'pos'}} = %{$npcs{$ID}{'pos'}};

				$update{'npc'} = 1;
				#updateNPCLUT("tables/npcs.txt", $npcs{$ID}{'nameID'}, $field{'name'}, $npcs{$ID}{'pos'}{'x'}, $npcs{$ID}{'pos'}{'y'}, $npcs{$ID}{'name'});
			}

			OnNpc($ID, $EV_GET_INFO);
		}
		if (%{$pets{$ID}}) {
			($pets{$ID}{'name_given'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			if ($config{'debug'} >= 2) {
				$binID = binFind(\@petsID, $ID);
				print "Pet Info: $pets{$ID}{'name_given'} ($binID)\n";
			}

			OnPet($ID, $EV_GET_INFO);
		}
	} elsif ($switch eq "0097") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		decrypt(\$newmsg, substr($msg, 28, length($msg)-28));
		$msg = substr($msg, 0, 28).$newmsg;
		($privMsgUser) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
		$privMsg = substr($msg, 28, $msg_size - 29);

		chatLog("pm", "(From: $privMsgUser) : $privMsg\n");

		ChatWrapper($privMsgUser, $privMsg, "pm");
		OnChat("", $privMsgUser, $privMsg, "pm");
	} elsif ($switch eq "0098") {
		$type = unpack("C1",substr($msg, 2, 1));
		if ($type == 0) {
			ChatWrapper($lastpm{'user'}, $lastpm{'msg'}, "pmto");
			chatLog("pm", "(To: $lastpm{'user'}) : $lastpm{'msg'}\n");
		} elsif ($type == 1) {
			ChatWrapper($lastpm{'user'}, "$lastpm{'user'} is not online.", "pmto");
		} elsif ($type == 2) {
			ChatWrapper($lastpm{'user'}, "Player can't hear you - you are ignored.", "pmto");
		}
		shift @lastpm;
	} elsif ($switch eq "009A") {
		$chat = substr($msg, 4, $msg_size - 4);
		($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;

		if ($chatMsg eq "") {
			ChatWrapper("", $chat, "s");
		} else {
			ChatWrapper($chatMsgUser, $chatMsg, "s");
			OnChat("", $chatMsgUser, $chatMsg, "s");
		}

		WriteLog("special.txt", "$chat\n");
	} elsif ($switch eq "009C") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		$ID = substr($msg, 2, 4);
		$body = unpack("C1",substr($msg, 8, 1));
		$head = unpack("C1",substr($msg, 6, 1));

		if ($ID eq $accountID) {
			$chars[$config{'char'}]{'look'}{'head'} = $head;
			$chars[$config{'char'}]{'look'}{'body'} = $body;
			PrintMessage("You look at $chars[$config{'char'}]{'look'}{'body'}, $chars[$config{'char'}]{'look'}{'head'}.", "dark");
		} elsif (%{$players{$ID}}) {
			$players{$ID}{'look'}{'head'} = $head;
			$players{$ID}{'look'}{'body'} = $body;
			print "Player $players{$ID}{'name'} ($players{$ID}{'binID'}) looks at $players{$ID}{'look'}{'body'}, $players{$ID}{'look'}{'head'}\n" if ($config{'debug'} >= 2);
		} elsif (%{$monsters{$ID}}) {
			$monsters{$ID}{'look'}{'head'} = $head;
			$monsters{$ID}{'look'}{'body'} = $body;
			print "Monster $monsters{$ID}{'name'} ($monsters{$ID}{'binID'}) looks at $monsters{$ID}{'look'}{'body'}, $monsters{$ID}{'look'}{'head'}\n" if ($config{'debug'} >= 2);
		}
	} elsif ($switch eq "009D") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
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
		print "Item Exists: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'}\n" if $config{'debug'};
		OnYou($EV_ITEM_EXISTS, $ID);
	} elsif ($switch eq "009E") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
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

		if ($monster{'id'} ne "" && $monster{'dmgFromYou'} > 0) {
			$distance = distance(\%{$items{$ID}{'pos'}}, \%{$monster{'pos'}});
			if ($distance <= 4) {
				binAdd(\@itemsDropID, $ID);
				if ($rareItems_lut{lc($items{$ID}{'name'})}) {
					WriteLog("rare.txt", "$monster{'name'} DROP $items{$ID}{'name'} x $items{$ID}{'amount'}\n");
					PrintMessage("Rare item drop: $items{$ID}{'name'} x $items{$ID}{'amount'}", "white");
				} else {
					PrintMessage("Item drop: $items{$ID}{'name'} x $items{$ID}{'amount'}", "dark");
				}
			}
		}

		print "Item Appeared: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'}\n" if $config{'debug'};
		OnYou($EV_ITEM_APPEARED, $ID);
	} elsif ($switch eq "00A0") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}

		$index = unpack("S1",substr($msg, 2, 2));
		$ID = unpack("S1",substr($msg, 6, 2));
		$amount = unpack("S1",substr($msg, 4, 2));
		$fail = unpack("C1",substr($msg, 22, 1));
		undef $invIndex;

		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);

		if ($fail == 0) {
			if ($invIndex eq "" || $itemsSlotCount_lut{$ID} ne "") {
				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = $ID;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = $amount;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = unpack("C1",substr($msg, 21, 1));
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = unpack("C1",substr($msg, 8, 1));
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} = unpack("S1",substr($msg, 19, 2));

				$chars[$config{'char'}]{'inventory'}[$invIndex]{'refine'} = unpack("C1",substr($msg, 10, 1));
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'cardID_1'} = unpack("S1", substr($msg, 11, 2));
				if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'cardID_1'} == 255) {
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'elementID'} = unpack("C1", substr($msg, 13, 1));
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'elementName'} = $elements_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'elementID'}};
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'strongID'} = unpack("C1", substr($msg, 14, 1));
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'strongName'} = $strongs_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'strongID'}};
				} else {
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'cardID_2'} = unpack("S1", substr($msg, 13, 2));
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'cardID_3'} = unpack("S1", substr($msg, 15, 2));
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'cardID_4'} = unpack("S1", substr($msg, 17, 2));
				}

				GenName($chars[$config{'char'}]{'inventory'}[$invIndex]);
			} else {
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} += $amount;
			}

			OnYou($EV_INVENTORY_ADDED, $invIndex, $amount);

			print "Item added to inventory: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} x $amount ($itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}})\n" if $config{'debug'};
		} elsif ($fail == 6) {
			if (%{$items{$ID}}) {
				$items{$ID}{'take_failed'}++;
				PrintMessage("Loot item: $items{$ID}{'name'} x $items{$ID}{'amount'}", "lightblue");
			}
		}
	} elsif ($switch eq "00A1") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		$ID = substr($msg, 2, 4);
		if (%{$items{$ID}}) {
			OnYou($EV_ITEM_DISAPPEARED, $ID);

			print "Item Disappeared: $items{$ID}{'name'} ($items{$ID}{'binID'})\n" if $config{'debug'};
			%{$items_old{$ID}} = %{$items{$ID}};
			$items_old{$ID}{'disappeared'} = 1;
			$items_old{$ID}{'gone_time'} = time;
			undef %{$items{$ID}};
			binRemove(\@itemsID, $ID);
			binRemove(\@itemsDropID, $ID);
		}
	} elsif ($switch eq "00A3") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
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
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = unpack("S1", substr($msg, $i + 6, 2));
			$display = ($items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}} ne "")
				? $items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}
				: "Unknown ".$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'};
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = $display;
			print "Inventory: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}}\n" if $config{'debug'};

			OnYou($EV_INVENTORY_UPDATED, $invIndex);
		}

		# Use proper way to teleport
		useTeleport($teleQueue) if $teleQueue;
	} elsif ($switch eq "00A4") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef $invIndex;
		$petkeep = 1;
		for($i = 4; $i < $msg_size; $i+=20) {
			$index = unpack("S1", substr($msg, $i, 2));
			$ID = unpack("S1", substr($msg, $i + 2, 2));
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			if ($invIndex eq "") {
				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
			}
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = $ID;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = 1;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} = unpack("S1", substr($msg, $i + 6, 2));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = unpack("S1", substr($msg, $i + 8, 2));

			$chars[$config{'char'}]{'inventory'}[$invIndex]{'special'} = unpack("C1", substr($msg, $i + 10, 1));
			if (!$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} && $chars[$config{'char'}]{'inventory'}[$invIndex]{'special'} > 0) {
				$petkeep = 0;
			}

			$chars[$config{'char'}]{'inventory'}[$invIndex]{'refine'} = unpack("C1", substr($msg, $i + 11, 1));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'cardID_1'} = unpack("S1", substr($msg, $i + 12, 2));
			if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'cardID_1'} == 255) {
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'elementID'} = unpack("C1", substr($msg, $i + 14, 1));
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'elementName'} = $elements_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'elementID'}};
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'strongID'} = unpack("C1", substr($msg, $i + 15, 1));
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'strongName'} = $strongs_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'strongID'}};
			} else {
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'cardID_2'} = unpack("S1", substr($msg, $i + 14, 2));
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'cardID_3'} = unpack("S1", substr($msg, $i + 16, 2));
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'cardID_4'} = unpack("S1", substr($msg, $i + 18, 2));
			}

			GenName($chars[$config{'char'}]{'inventory'}[$invIndex]);

			print "Inventory: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}} - $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}}\n" if $config{'debug'};

			OnYou($EV_INVENTORY_UPDATED, $invIndex);
		}

		if ($petkeep) {
			undef %{$chars[$config{'char'}]{'pet'}};
			OnYou($EV_PET_KEEP);
		}
	} elsif ($switch eq "00A5") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;

		if (!$storage{'open'}) {
			PrintMessage("Storage Opened", "yellow");
			OnYou($EV_STORAGE_OPENED);
		}

		for($i = 4; $i < $msg_size; $i+=10) {
			$index = unpack("S1", substr($msg, $i, 2));

			$invIndex = findIndex(\@{$storage{'inventory'}}, "index", $index);
			if ($invIndex eq "") {
				$invIndex = findIndex(\@{$storage{'inventory'}}, "nameID", "");
			}

			$ID = unpack("S1", substr($msg, $i + 2, 2));
			$storage{'inventory'}[$invIndex]{'index'} = $index;
			$storage{'inventory'}[$invIndex]{'nameID'} = $ID;
			$storage{'inventory'}[$invIndex]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
			$storage{'inventory'}[$invIndex]{'amount'} = unpack("S1", substr($msg, $i + 6, 2));
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "Unknown ".$ID;
			$storage{'inventory'}[$invIndex]{'name'} = $display;
			print "Storage: $storage{'inventory'}[$invIndex]{'name'} ($index)\n" if $config{'debug'};

			OnYou($EV_STORAGE_UPDATED, $invIndex);
		}

		$storage{'open'} = 1;
	} elsif ($switch eq "00A6") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
 		$msg = substr($msg, 0, 4).$newmsg;

		if (!$storage{'open'}) {
			PrintMessage("Storage Opened", "yellow");

			OnYou($EV_STORAGE_OPENED);
		}

		for($i = 4; $i < $msg_size; $i += 20) {
			$index = unpack("S1", substr($msg, $i, 2));

			$invIndex = findIndex(\@{$storage{'inventory'}}, "index", $index);
			if ($invIndex eq "") {
				$invIndex = findIndex(\@{$storage{'inventory'}}, "nameID", "");
			}

			$ID = unpack("S1", substr($msg, $i + 2, 2));
			$storage{'inventory'}[$invIndex]{'index'} = $index;
			$storage{'inventory'}[$invIndex]{'nameID'} = $ID;
			$storage{'inventory'}[$invIndex]{'amount'} = 1;
			$storage{'inventory'}[$invIndex]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
			$storage{'inventory'}[$invIndex]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
			$storage{'inventory'}[$invIndex]{'type_equip'} = unpack("S1", substr($msg, $i + 6, 2));
			$storage{'inventory'}[$invIndex]{'special'} = unpack("C1", substr($msg, $i + 10, 1));
			$storage{'inventory'}[$invIndex]{'refine'} = unpack("C1", substr($msg, $i + 11, 1));
			$storage{'inventory'}[$invIndex]{'cardID_1'} = unpack("S1", substr($msg, $i + 12, 2));
			if ($storage{'inventory'}[$invIndex]{'cardID_1'} == 255) {
				$storage{'inventory'}[$invIndex]{'elementID'} = unpack("C1", substr($msg, $i + 14, 1));
				$storage{'inventory'}[$invIndex]{'elementName'} = $elements_lut{$storage{'inventory'}[$invIndex]{'elementID'}};
				$storage{'inventory'}[$invIndex]{'strongID'} = unpack("C1", substr($msg, $i + 15, 1));
				$storage{'inventory'}[$invIndex]{'strongName'} = $strongs_lut{$storage{'inventory'}[$invIndex]{'strongID'}};
			} else {
				$storage{'inventory'}[$invIndex]{'cardID_2'} = unpack("S1", substr($msg, $i + 14, 2));
				$storage{'inventory'}[$invIndex]{'cardID_3'} = unpack("S1", substr($msg, $i + 16, 2));
				$storage{'inventory'}[$invIndex]{'cardID_4'} = unpack("S1", substr($msg, $i + 18, 2));
			}

			GenName($storage{'inventory'}[$invIndex]);

			print "Storage Item: $storage{'inventory'}[$invIndex]{'name'} ($index) x $storage{'inventory'}[$invIndex]{'amount'}\n" if $config{'debug'};

			OnYou($EV_STORAGE_UPDATED, $invIndex);
		}

		$storage{'open'} = 1;
	} elsif ($switch eq "00A8") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		$index = unpack("S1",substr($msg, 2, 2));
		$amount = unpack("C1",substr($msg, 6, 1));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $amount;
		print "You used Item: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amount\n" if $config{'debug'};

		OnYou($EV_ITEM_USED, $invIndex, $amount);
		OnYou($EV_INVENTORY_REMOVED, $invIndex, $amount);

		if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
			undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
		}
	} elsif ($switch eq "00AA") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		$index = unpack("S1",substr($msg, 2, 2));
		$type = unpack("S1",substr($msg, 4, 2));
		$fail = unpack("C1",substr($msg, 6, 1));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		if ($invIndex ne "") {
			if ($fail == 0) {
				print "You can't put on $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex)\n" if $config{'debug'};
				OnYou($EV_EQUIP_FAILED, $invIndex);
			} else {
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = $type;
				print "You equip $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) - $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}}\n" if $config{'debug'};
				OnYou($EV_EQUIP, $invIndex);
				OnYou($EV_INVENTORY_UPDATED, $invIndex);
			}
		}
	} elsif ($switch eq "00AC") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		$index = unpack("S1",substr($msg, 2, 2));
		$type = unpack("S1",substr($msg, 4, 2));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		if ($invIndex ne "") {
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = 0;
			print "You unequip $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) - $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}}\n" if $config{'debug'};
			OnYou($EV_UNEQUIP, $invIndex);
			OnYou($EV_INVENTORY_UPDATED, $invIndex);
		}
	} elsif ($switch eq "00AF") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		$index = unpack("S1",substr($msg, 2, 2));
		$amount = unpack("S1",substr($msg, 4, 2));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		print "Inventory Item Removed: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amount\n" if $config{'debug'};
		$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $amount;

		OnYou($EV_INVENTORY_REMOVED, $invIndex, $amount);

		if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
			undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
		}
	} elsif ($switch eq "00B0") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		$type = unpack("S1",substr($msg, 2, 2));
		$val = unpack("L1",substr($msg, 4, 4));

		if ($type == 0) {
			print "Something1: $val\n" if $config{'debug'};
		} elsif ($type == 3) {
			print "Something2: $val\n" if $config{'debug'};
		} elsif ($type == 4) {
			$chars[$config{'char'}]{'ban'} = -$val;
			print "Ban: $val minutes\n" if $config{'debug'};
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
			$chars[$config{'char'}]{'attack_magic_max'} = $val;
			print "Magic Attack Min: $val\n" if $config{'debug'};
		} elsif ($type == 44) {
			$chars[$config{'char'}]{'attack_magic_min'} = $val;
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
		OnYou($EV_STAT_CHANGED);
	} elsif ($switch eq "00B1") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		$type = unpack("S1",substr($msg, 2, 2));
		$val = unpack("L1",substr($msg, 4, 4));
		if ($type == 1) {
			$chars[$config{'char'}]{'exp_last'} = $chars[$config{'char'}]{'exp'};
			$chars[$config{'char'}]{'exp'} = $val;
			print "Exp: $val\n" if $config{'debug'};
		} elsif ($type == 2) {
			$chars[$config{'char'}]{'exp_job_last'} = $chars[$config{'char'}]{'exp_job'};
			$chars[$config{'char'}]{'exp_job'} = $val;
			print "Job Exp: $val\n" if $config{'debug'};
		} elsif ($type == 20) {
			$chars[$config{'char'}]{'zenny'} = $val;
			print "Zenny: $val\n" if $config{'debug'};
		} elsif ($type == 22) {
			$chars[$config{'char'}]{'exp_max_last'} = $chars[$config{'char'}]{'exp_max'};
			$chars[$config{'char'}]{'exp_max'} = $val;
			print "Required Exp: $val\n" if $config{'debug'};
		} elsif ($type == 23) {
			$chars[$config{'char'}]{'exp_job_max_last'} = $chars[$config{'char'}]{'exp_job_max'};
			$chars[$config{'char'}]{'exp_job_max'} = $val;
			print "Required Job Exp: $val\n" if $config{'debug'};
		}
		OnYou($EV_STAT_CHANGED);
	} elsif ($switch eq "00B3") {
		$type = unpack("C1",substr($msg, 2, 1));
		if ($type == 1) {
			print "Character Selected.\n";
		}

		if (!$config{'remoteSocket'}) {
			$conState = 2;
		}
	} elsif ($switch eq "00B4") {
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
		$msg = substr($msg, 0, 8).$newmsg;
		$ID = substr($msg, 4, 4);
		($talk) = substr($msg, 8, $msg_size - 8) =~ /([\s\S]*?)\000/;
		$talk{'ID'} = $ID;
		$talk{'nameID'} = unpack("L1", $ID);
		$talk{'msg'} .= $talk;
	} elsif ($switch eq "00B5") {
		$ID = substr($msg, 2, 4);
		if (%{$npcs{$ID}}) {
			print "$npcs{$ID}{'nameID'} : Type 'n cont' to continue talking\n";
			OnNpc($ID, $EV_CONTINUE);
		}
	} elsif ($switch eq "00B6") {
		$ID = substr($msg, 2, 4);
		if (%{$npcs{$ID}}) {
			print "$npcs{$ID}{'nameID'} : Done talking\n";
			OnNpc($ID, $EV_DONT_TALK);
		}
	} elsif ($switch eq "00B7") {
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
		$msg = substr($msg, 0, 8).$newmsg;
		$ID = substr($msg, 4, 4);
		($talk) = substr($msg, 8, $msg_size - 8) =~ /([\s\S]*?)\000/;

		if (%{$npcs{$ID}}) {
			@preTalkResponses = split /:/, $talk;
			undef @{$talk{'responses'}};
			foreach (@preTalkResponses) {
				push @{$talk{'responses'}}, $_ if $_ ne "";
			}

			print "$npcs{$ID}{'nameID'} : Type 'n resp' and choose a response.\n";

			OnNpc($ID, $EV_RESPONSE);
		}
	} elsif ($switch eq "00BC") {
		$type = unpack("S1",substr($msg, 2, 2));
		$val = unpack("C1",substr($msg, 5, 1));
		if ($val == 207) {
			print "Not enough stat points to add\n";
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
			OnYou($EV_STAT_CHANGED);
		}
	} elsif ($switch eq "00BD") {
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
		$chars[$config{'char'}]{'attack_magic_max'} = unpack("S1", substr($msg, 20, 2));
		$chars[$config{'char'}]{'attack_magic_min'} = unpack("S1", substr($msg, 22, 2));
		$chars[$config{'char'}]{'def'} = unpack("S1", substr($msg, 24, 2));
		$chars[$config{'char'}]{'def_bonus'} = unpack("S1", substr($msg, 26, 2));
		$chars[$config{'char'}]{'def_magic'} = unpack("S1", substr($msg, 28, 2));
		$chars[$config{'char'}]{'def_magic_bonus'} = unpack("S1", substr($msg, 30, 2));
		$chars[$config{'char'}]{'hit'} = unpack("S1", substr($msg, 32, 2));
		$chars[$config{'char'}]{'flee'} = unpack("S1", substr($msg, 34, 2));
		$chars[$config{'char'}]{'flee_bonus'} = unpack("S1", substr($msg, 36, 2));
		$chars[$config{'char'}]{'critical'} = unpack("S1", substr($msg, 38, 2));
		print	"Strength: $chars[$config{'char'}]{'str'} #$chars[$config{'char'}]{'points_str'}\n"
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

		OnYou($EV_STAT_CHANGED);
	} elsif ($switch eq "00BE") {
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

		OnYou($EV_STAT_CHANGED);
	} elsif ($switch eq "00C0") {
		$ID = substr($msg, 2, 4);
		$type = unpack("C*", substr($msg, 6, 1));
		if ($ID eq $accountID) {
			ChatWrapper($chars[$config{'char'}]{'name'}, $emotions_lut{$type}{'name'}, "e");
			OnYou($EV_EMOTION, $type);
		} elsif (%{$players{$ID}}) {
			ChatWrapper($players{$ID}{'name'}, $emotions_lut{$type}{'name'}, "e");
			OnPlayer($ID, $EV_EMOTION, $type);
		}
	} elsif ($switch eq "00C2") {
		$users = unpack("L*", substr($msg, 2, 4));
		print "There are currently $users users online\n";
	} elsif ($switch eq "00C3") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}

		$ID = substr($msg, 2, 4);
		$part = unpack("C1",substr($msg, 6, 1));
		$no = unpack("C1",substr($msg, 7, 1));

		undef $itemID;
		$charpart = $charLook_lut{$part};
		if ($part == 3) {
			$part = 'lowHead';
			$itemID = $charHead_lut{$no};
		} elsif ($part == 4) {
			$part = 'topHead';
			$itemID = $charHead_lut{$no};
		} elsif ($part == 5) {
			$part = 'midHead';
			$itemID = $charHead_lut{$no};
		} else {
		}

		if ($itemID) {
			$name = $items_lut{$itemID};
		} elsif (!$no) {
			$name = "None";
		} else {
			$name = "$no";
		}

		DebugMessage("00C3: CHANGE EQIUPMENT DISPLAY, ".Name($ID)." PART: $charpart TYPE: $name") if ($debug{'msg00C3'});

		if ($ID eq $accountID) {
			$chars[$config{'char'}]{'look'}{$part} = $itemID;
		} elsif (%{$players{$ID}}) {
			$players{$ID}{'look'}{$part} = $itemID;
			OnPlayer($ID, $EV_EQUIP);
		}
	} elsif ($switch eq "00C4") {
		$ID = substr($msg, 2, 4);
		if (%{$npcs{$ID}}) {
			undef %talk;
			$talk{'buyOrSell'} = 1;
			$talk{'ID'} = $ID;
			print "$npcs{$ID}{'nameID'} : Type 'store' to start buying, or type 'sell' to start selling\n";

			OnNpc($ID, $EV_BUY_SELL);
		}
	} elsif ($switch eq "00C6") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef @storeList;
		$index = 0;
		undef $talk{'buyOrSell'};
		for ($i = 4; $i < $msg_size; $i+=11) {
			$price = unpack("L1", substr($msg, $i, 4));
			$type = unpack("C1", substr($msg, $i + 8, 1));
			$ID = unpack("S1", substr($msg, $i + 9, 2));
			$storeList[$index]{'nameID'} = $ID;
			$storeList[$index]{'name'} = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
			$storeList[$index]{'nameID'} = $ID;
			$storeList[$index]{'type'} = $type;
			if ($chars[$config{'char'}]{'skills'}{'MC_DISCOUNT'}{'lv'} > 0) {
				$discount = ($chars[$config{'char'}]{'skills'}{'MC_DISCOUNT'}{'lv'} * 2) + 5;
				$discount = ($discount > 24) ? 24 : $discount;
				$dprice = int($price * (100 - $discount) / 100);
				$dprice = ($dprice <= 0) ? 1 : $dprice;
				$storeList[$index]{'price'} = "$price -> $dprice z";
			} else {
				$storeList[$index]{'price'} = "$price z";
			}
			print "Item added to Store: $storeList[$count]{'name'} - $price z\n" if ($config{'debug'} >= 2);
			$index++;
		}
		print "$npcs{$talk{'ID'}}{'nameID'} : Check my store list by typing 'store'\n" if $config{'debug'};

		OnNpc($talk{'ID'}, $EV_BUY);
	} elsif ($switch eq "00C7") {
		#sell list, similar to buy list
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef $talk{'buyOrSell'};
		print "Ready to start selling items\n" if $config{'debug'};

		OnNpc($talk{'ID'}, $EV_SELL);
	} elsif ($switch eq "00CA") {
		$fail = unpack("C1", substr($msg, 2, 1));
		if ($fail) {
			print "Buy item is failed.\n"
		}
	} elsif ($switch eq "00CB") {
		$fail = unpack("C1", substr($msg, 2, 1));
		if ($fail) {
			print "Sell item is failed.\n"
		}
	} elsif ($switch eq "00D1") {
		$type = unpack("C1", substr($msg, 2, 1));
		$error = unpack("C1", substr($msg, 3, 1));
		if ($type == 0) {
			print "Player ignored\n";
		} elsif ($type == 1) {
			if ($error == 0) {
				print "Player unignored\n";
			}
		}
	} elsif ($switch eq "00D2") {
		$type = unpack("C1", substr($msg, 2, 1));
		$error = unpack("C1", substr($msg, 3, 1));
		if ($type == 0) {
			print "All Players ignored\n";
		} elsif ($type == 1) {
			if ($error == 0) {
				print "All players unignored\n";
			}
		}
	} elsif ($switch eq "00D3") {
	} elsif ($switch eq "00D6") {
		$currentChatRoom = "new";
		%{$chatRooms{'new'}} = %createdChatRoom;
		binAdd(\@chatRoomsID, "new");
		binAdd(\@currentChatRoomUsers, $chars[$config{'char'}]{'name'});
		print "Chat Room Created\n";
	} elsif ($switch eq "00D7") {
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

	} elsif ($switch eq "00D8") {
		$ID = substr($msg,2,4);
		binRemove(\@chatRoomsID, $ID);
		undef %{$chatRooms{$ID}};
	} elsif ($switch eq "00DA") {
		$type = unpack("C1",substr($msg, 2, 1));
		if ($type == 1) {
			PrintMessage("Can't join Chat Room - Incorrect Password.", "lightblue");
		} elsif ($type == 2) {
			PrintMessage("Can't join Chat Room - You're banned.", "lightblue");
		}
	} elsif ($switch eq "00DB") {
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
		print qq~You have joined the Chat Room "$chatRooms{$currentChatRoom}{'title'}"\n~;

	} elsif ($switch eq "00DC") {
		if ($currentChatRoom ne "") {
			$num_users = unpack("S1", substr($msg,2,2));
			($joinedUser) = substr($msg,4,24) =~ /([\s\S]*?)\000/;
			binAdd(\@currentChatRoomUsers, $joinedUser);
			$chatRooms{$currentChatRoom}{'users'}{$joinedUser} = 1;
			$chatRooms{$currentChatRoom}{'num_users'} = $num_users;
			print "$joinedUser has joined the Chat Room\n";
		}
	} elsif ($switch eq "00DD") {
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
			print "You left the Chat Room\n";
		} else {
			print "$leaveUser has left the Chat Room\n";
		}
	} elsif ($switch eq "00DF") {
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
		print "Chat Room Properties Modified\n";
	} elsif ($switch eq "00E1") {
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
	} elsif ($switch eq "00E5") {
		($dealUser) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		$incomingDeal{'name'} = $dealUser;
		$timeout{'ai_dealAutoCancel'}{'time'} = time;
		print "$dealUser Requests a Deal\n" if $config{'debug'};
		$incomingDeal{'ID'} = ai_getID(\%players, $dealUser);
		if ($incomingDeal{'ID'} ne "") {
			OnPlayer($ID, $EV_DEAL_REQUEST);
		}
	} elsif ($switch eq "00E7") {
		$type = unpack("C1", substr($msg, 2, 1));

		if ($type == 3) {
			if (%incomingDeal) {
				$currentDeal{'ID'} = $incomingDeal{'ID'};
				$currentDeal{'name'} = $incomingDeal{'name'};
			} else {
				$currentDeal{'ID'} = $outgoingDeal{'ID'};
				$currentDeal{'name'} = $players{$outgoingDeal{'ID'}}{'name'};
			}

			OnPlayer($currentDeal{'ID'}, $EV_DEAL_ACCEPT);
			print "Engaged Deal with $currentDeal{'name'}\n" if $config{'debug'};
		}
		undef %outgoingDeal;
		undef %incomingDeal;
	} elsif ($switch eq "00E9") {
		$amount = unpack("L*", substr($msg, 2,4));
		$ID = unpack("S*", substr($msg, 6,2));
		if ($ID > 0) {
			$currentDeal{'other'}{$ID}{'nameID'} = $ID;
			$currentDeal{'other'}{$ID}{'amount'} += $amount;
			$currentDeal{'other'}{$ID}{'identified'} = unpack("C1", substr($msg, 8, 1));
			$currentDeal{'other'}{$ID}{'refine'} = unpack("C1", substr($msg, 10, 1));
			$currentDeal{'other'}{$ID}{'cardID_1'} = unpack("S1", substr($msg, 11, 2));
			if ($currentDeal{'other'}{$ID}{'cardID_1'} == 255) {
				$currentDeal{'other'}{$ID}{'elementID'} = unpack("C1", substr($msg, $i + 13, 1));
				$currentDeal{'other'}{$ID}{'elementName'} = $elements_lut{$vender{'inventory'}[$index]{'elementID'}};
				$currentDeal{'other'}{$ID}{'strongID'} = unpack("C1", substr($msg, $i + 14, 1));
				$currentDeal{'other'}{$ID}{'strongName'} = $strongs_lut{$vender{'inventory'}[$index]{'strongID'}};
			} else {
				$currentDeal{'other'}{$ID}{'cardID_2'} = unpack("S1", substr($msg, $i + 13, 2));
				$currentDeal{'other'}{$ID}{'cardID_3'} = unpack("S1", substr($msg, $i + 15, 2));
				$currentDeal{'other'}{$ID}{'cardID_4'} = unpack("S1", substr($msg, $i + 17, 2));
			}

			GenName($currentDeal{'other'}{$ID});

			print "$currentDeal{'name'} added Item to Deal: $currentDeal{'other'}{$ID}{'name'} x $amount\n" if $config{'debug'};
			OnPlayer($currentDeal{'ID'}, $EV_DEAL_ADD, $ID, $amount);
		} elsif ($amount > 0) {
			$currentDeal{'other_zenny'} += $amount;
			print "$currentDeal{'name'} added $amount z to Deal\n" if $config{'debug'};
			OnPlayer($currentDeal{'ID'}, $EV_DEAL_ADD_ZENY, $amount);
		}
#E9 00 | 01 00 00 00 | C8 09 | 01 | 00 | 05 | F8 0F | 00 00 | 00 00 | 00 00
	} elsif ($switch eq "00EA") {
		$index = unpack("S1", substr($msg, 2, 2));
		undef $invIndex;
		if ($index > 0) {
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			$currentDeal{'you'}{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}{'name'} = $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'};
			$currentDeal{'you'}{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}{'amount'} += $currentDeal{'lastItemAmount'};
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $currentDeal{'lastItemAmount'};
			print "You added Item to Deal: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} x $currentDeal{'lastItemAmount'}\n" if $config{'debug'};

			OnYou($EV_DEAL_ADD, $invIndex, $currentDeal{'lastItemAmount'});
			OnYou($EV_INVENTORY_REMOVED, $invIndex, $currentDeal{'lastItemAmount'});

			if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
				undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
			}
		} elsif ($currentDeal{'lastItemAmount'} > 0) {
			OnYou($EV_DEAL_ADD_ZENY, $currentDeal{'you_zenny'});
			$chars[$config{'char'}]{'zenny'} -= $currentDeal{'you_zenny'};
		}
	} elsif ($switch eq "00EC") {
		$type = unpack("C1", substr($msg, 2, 1));
		if ($type == 1) {
			$currentDeal{'other_finalize'} = 1;
			print "$currentDeal{'name'} finalized the Deal\n" if $config{'debug'};
			OnPlayer($currentDeal{'ID'}, $EV_DEAL_CONFIRM);
		} else {
			$currentDeal{'you_finalize'} = 1;
			print "You finalized the Deal\n" if $config{'debug'};
			OnYou($EV_DEAL_CONFIRM);
		}
	} elsif ($switch eq "00EE") {
		undef %incomingDeal;
		undef %outgoingDeal;
		undef %currentDeal;
		print "Deal Cancelled\n" if $config{'debug'};

		OnYou($EV_DEAL_CANCELLED);
	} elsif ($switch eq "00F0") {
		undef %currentDeal;
		print "Deal Completed\n" if $config{'debug'};

		OnYou($EV_DEAL_COMPLETED);
	} elsif ($switch eq "00F2") {
		$storage{'items'} = unpack("S1", substr($msg, 2, 2));
		$storage{'items_max'} = unpack("S1", substr($msg, 4, 2));

		OnYou($EV_STORAGE_CAP);
	} elsif ($switch eq "00F4") {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));
		$ID = unpack("S1", substr($msg, 8, 2));

		$invIndex = findIndex(\@{$storage{'inventory'}}, "index", $index);
		if ($invIndex eq "") {
			$invIndex = findIndex(\@{$storage{'inventory'}}, "nameID", "");
			$storage{'inventory'}[$invIndex]{'index'} = $index;
			$storage{'inventory'}[$invIndex]{'nameID'} = $ID;
			$storage{'inventory'}[$invIndex]{'amount'} = $amount;
			$storage{'inventory'}[$invIndex]{'identified'} = unpack("C1", substr($msg, 10, 1));
			$storage{'inventory'}[$invIndex]{'refine'} = unpack("C1", substr($msg, 12, 1));
			$storage{'inventory'}[$invIndex]{'cardID_1'} = unpack("S1", substr($msg, 13, 2));
			if ($storage{'inventory'}[$invIndex]{'cardID_1'} == 255) {
				$storage{'inventory'}[$invIndex]{'elementID'} = unpack("C1", substr($msg, 15, 1));
				$storage{'inventory'}[$invIndex]{'elementName'} = $elements_lut{$storage{'inventory'}[$invIndex]{'elementID'}};
				$storage{'inventory'}[$invIndex]{'strongID'} = unpack("C1", substr($msg, 16, 1));
				$storage{'inventory'}[$invIndex]{'strongName'} = $strongs_lut{$storage{'inventory'}[$invIndex]{'strongID'}};
			} else {
				$storage{'inventory'}[$invIndex]{'cardID_2'} = unpack("S1", substr($msg, 15, 2));
				$storage{'inventory'}[$invIndex]{'cardID_3'} = unpack("S1", substr($msg, 17, 2));
				$storage{'inventory'}[$invIndex]{'cardID_4'} = unpack("S1", substr($msg, 19, 2));
			}

			GenName($storage{'inventory'}[$invIndex]);
		} else {
			$storage{'inventory'}[$invIndex]{'amount'} += $amount;
		}
		print "Storage Item Added: $storage{'inventory'}[$invIndex]{'name'} ($index) x $amount\n" if $config{'debug'};
		OnYou($EV_STORAGE_ADDED, $invIndex);
	} elsif ($switch eq "00F6") {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));

		$invIndex = findIndex(\@{$storage{'inventory'}}, "index", $index);
		if ($invIndex ne "") {
			$storage{'inventory'}[$invIndex]{'amount'} -= $amount;
			print "Storage Item Removed: $storage{'inventory'}[$invIndex]{'name'} ($index) x $amount\n" if $config{'debug'};

			OnYou($EV_STORAGE_REMOVED, $invIndex);

			if ($storage{'inventory'}[$invIndex]{'amount'} <= 0) {
				undef %{$storage{'inventory'}[$invIndex]};
			}
		}
	} elsif ($switch eq "00F8") {
		undef %storage;

		PrintMessage("Storage Closed", "yellow");

		OnYou($EV_STORAGE_CLOSED);
	} elsif ($switch eq "00FA") {
		$type = unpack("C1", substr($msg, 2, 1));
		if ($type == 1) {
			PrintMessage("Can't organize party - party name exists.", "lightblue");
		}
	} elsif ($switch eq "00FB") {
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
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = !(unpack("C1",substr($msg, $i + 45, 1)));

			if ($chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'}) {
				($chars[$config{'char'}]{'party'}{'users'}{$ID}{'map'}) = substr($msg, $i + 28, 16) =~ /([\s\S]*?)\000/;
			} else {
				$chars[$config{'char'}]{'party'}{'users'}{$ID}{'map'} = '';
			}

			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'x'} = 0;
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'y'} = 0;
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp'} = 0;
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp_max'} = 0;

			if ($num == 0) {
				$chars[$config{'char'}]{'party'}{'users'}{$ID}{'admin'} = 1;
			} else {
				$chars[$config{'char'}]{'party'}{'users'}{$ID}{'admin'} = 0;
			}

			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'move'} = 0;

			if ($ID eq $accountID) {
				OnYou($EV_PARTY_UPDATED);
			} else {
				OnPlayer($ID, $EV_PARTY_UPDATED);
			}
		}
	} elsif ($switch eq "00FD") {
		($name) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		$type = unpack("C1", substr($msg, 26, 1));
		if ($type == 0) {
			print "Join request failed: $name is already in a party\n";
		} elsif ($type == 1) {
			print "Join request failed: $name denied request\n";
		} elsif ($type == 2) {
			print "$name accepted your request\n";
		}
	} elsif ($switch eq "00FE") {
		$ID = substr($msg, 2, 4);
		($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
		#print "Incoming Request to join party '$name'\n";

		$incomingParty{'name'} = $name;
		$incomingParty{'ID'} = $ID;

		OnPlayer($ID, $EV_PARTY_REQUEST);

		$timeout{'ai_partyAutoDeny'}{'time'} = time;
	} elsif ($switch eq "0101") {
		$type = unpack("C1", substr($msg, 2, 1));
		if ($type == 0) {
			PrintMessage("Party EXP set to Individual Take", "green");
			$chars[$config{'char'}]{'party'}{'share'} = 0;
			OnYou($EV_PARTY_NOSHARE);
		} elsif ($type == 1) {
			PrintMessage("Party EXP set to Even Share", "green");
			$chars[$config{'char'}]{'party'}{'share'} = 1;
			OnYou($EV_PARTY_SHARE);
		} else {
			print "Error setting party option\n";
		}
	} elsif ($switch eq "0104") {
		$ID = substr($msg, 2, 4);
		$x = unpack("S1", substr($msg,10, 2));
		$y = unpack("S1", substr($msg,12, 2));
		$type = unpack("C1",substr($msg, 14, 1));
		($name) = substr($msg, 15, 24) =~ /([\s\S]*?)\000/;
		($partyUser) = substr($msg, 39, 24) =~ /([\s\S]*?)\000/;
		($map) = substr($msg, 63, 16) =~ /([\s\S]*?)\000/;

		$join = 0;
		if (!%{$chars[$config{'char'}]{'party'}{'users'}{$ID}}) {
			binAdd(\@partyUsersID, $ID);
			$join = 1;
		}

		if ($type == 0) {
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 1;
		} elsif ($type == 1) {
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 0;
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp'} = 0;
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp_max'} = 0;
			$x = 0;
			$y = 0;
			$map = '';
		}

		if ($chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} &&
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'map'} ne $map &&
			$chars[$config{'char'}]{'party'}{'users'}{$accountID}{'map'} eq $map) {
			$chars[$config{'char'}]{'party'}{'share'} = 0;
		}

		$chars[$config{'char'}]{'party'}{'name'} = $name;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'x'} = $x;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'y'} = $y;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'map'} = $map;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'} = $partyUser;

		if ($x != 0 || $y != 0) {
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'move'} = 1;
		} else {
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'move'} = 0;
		}

		if ($join) {
			if ($ID eq $accountID) {
				OnYou($EV_PARTY_JOIN);
			} else {
				OnPlayer($ID, $EV_PARTY_JOIN);
			}
		} else {
			if ($ID eq $accountID) {
				OnYou($EV_PARTY_UPDATED);
			} else {
				OnPlayer($ID, $EV_PARTY_UPDATED);
			}
		}
	} elsif ($switch eq "0105") {
		$ID = substr($msg, 2, 4);
		($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
		if ($ID eq $accountID) {
			print "You left the party\n";
			undef %{$chars[$config{'char'}]{'party'}};
			undef @partyUsersID;
			OnYou($EV_PARTY_LEFT);
		} else {
			print "$name left the party\n";
			OnPlayer($ID, $EV_PARTY_LEFT);
			undef %{$chars[$config{'char'}]{'party'}{'users'}{$ID}};
			binRemove(\@partyUsersID, $ID);
		}
	} elsif ($switch eq "0106") {
		$ID = substr($msg, 2, 4);
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp'} = unpack("S1", substr($msg, 6, 2));
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp_max'} = unpack("S1", substr($msg, 8, 2));
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 1;
		DebugMessage("0106: $chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'}, HP $chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp'}/$chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp_max'}") if ($debug{'msg0106'});
		print "Party member hp: $chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp'}\n" if ($config{'debug'} >= 2);
		OnPlayer($ID, $EV_PARTY_HP);
	} elsif ($switch eq "0107") {
		$ID = substr($msg, 2, 4);
		$x = unpack("S1", substr($msg,6, 2));
		$y = unpack("S1", substr($msg,8, 2));
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'x'} = $x;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'y'} = $y;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 1;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'move'} = 1;

		DebugMessage("0107: $chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'}, ($x, $y)") if ($debug{'msg0107'});
		print "Party member location: $chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'} - $x, $y\n" if ($config{'debug'} >= 2);
		OnPlayer($ID, $EV_PARTY_MOVE);
	} elsif ($switch eq "0109") {
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
		$msg = substr($msg, 0, 8).$newmsg;
		$chat = substr($msg, 8, $msg_size - 8);
		($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
		chatLog("p", $chat."\n");

		if ($chatMsg eq "") {
			ChatWrapper("", $chat, "p");
		} else {
			ChatWrapper($chatMsgUser, $chatMsg, "p");
			OnChat("", $chatMsgUser, $chatMsg, "p");
		}
	} elsif ($switch eq "010A") {
  		$ID = unpack("S1", substr($msg, 2, 2));
		PrintMessage("You get MVP Item : ".$items_lut{$ID}, "green");
		OnYou($EV_MVP_ITEM, $ID);
   	} elsif ($switch eq "010B") {
      		$val = unpack("S1",substr($msg, 2, 2));
		PrintMessage("You're MVP!!! Special exp gained: $val", "green");
		OnYou($EV_MVP_EXP, $val);
   	} elsif ($switch eq "010C") {
		$ID = substr($msg, 2, 4);
		if (%{$players{$ID}}) {
			PrintMessage("$players{$ID}{'name'} got MVP!!!", "green");
		}
	} elsif ($switch eq "010E") {
		$ID = unpack("S1",substr($msg, 2, 2));
		$lv = unpack("S1",substr($msg, 4, 2));
		$chars[$config{'char'}]{'skills'}{$skillsID_lut{$ID}{'nameID'}}{'lv'} = $lv;
		print "Skill $skillsID_lut{$ID}{'name'}: $lv\n" if $config{'debug'};

		OnYou($EV_SKILL_UPDATED, $ID);
	} elsif ($switch eq "010F") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;

		OnYou($EV_SKILL_CLEARED);

		undef @skillsID;
		for($i = 4;$i < $msg_size;$i+=37) {
			$ID = unpack("S1", substr($msg, $i, 2));
			($nameID) = substr($msg, $i + 12, 24) =~ /([\s\S]*?)\000/;
			if (!$nameID) {
				$nameID = $skillsID_lut{$ID}{'nameID'};
			}

			if ($nameID ne "" && $skillsID_lut{$ID}{'nameID'} ne $nameID) {
				$skillsID_lut{$ID}{'nameID'} = $nameID;
				$skillsID_lut{$ID}{'name'} = $skills_lut{$nameID};
				$update{'skill'} = 1;
			}

			$chars[$config{'char'}]{'skills'}{$nameID}{'ID'} = $ID;
			$chars[$config{'char'}]{'skills'}{$nameID}{'use'} = unpack("S1", substr($msg, $i + 2, 2));
			$chars[$config{'char'}]{'skills'}{$nameID}{'lv'} = unpack("S1", substr($msg, $i + 6, 2));
			#if (!$chars[$config{'char'}]{'skills'}{$nameID}{'lv'}) {
			#	$chars[$config{'char'}]{'skills'}{$nameID}{'lv'} = unpack("S1", substr($msg, $i + 6, 2));
			#}
			$chars[$config{'char'}]{'skills'}{$nameID}{'sp'} = unpack("S1", substr($msg, $i + 8, 2));

			binAdd(\@skillsID, $nameID);

			OnYou($EV_SKILL_ADDED, $ID);
		}
	} elsif ($switch eq "0110") {
		$skillID = unpack("S1",substr($msg, 2, 2));
		if ($chars[$config{'char'}]{'last_skill_send'} == $skillID) {
			$chars[$config{'char'}]{'last_skill_failed'} = 1;
		}

		OnYou($EV_SKILL_FAILED, $skillID);
		PrintMessage(GetSkillName($skillID)." is failed.", "red");
# Skill failed
#10 01 6E 00 00 00 00 00    00 06 Hammer Fall
#10 01 6F 00 00 00 00 00    00 06 Adrenaline Rush
#10 01 0F 00 00 00 00 00    00 00 Frost Diver
	} elsif ($switch eq "0111") {
		$ID = unpack("S1", substr($msg, 2, 2));
		($nameID) = substr($msg, 14, 24) =~ /([\s\S]*?)\000/;
		if (!$nameID) {
			$nameID = $skillsID_lut{$ID}{'nameID'};
		}

		if ($nameID ne "" && $skillsID_lut{$ID}{'nameID'} ne $nameID) {
			$skillsID_lut{$ID}{'nameID'} = $nameID;
			$skillsID_lut{$ID}{'name'} = $skills_lut{$nameID};
			$update{'skill'} = 1;
		}

		$use = unpack("S1", substr($msg, 4, 2));
		$level = unpack("S1", substr($msg, 8, 2));
		$sp = unpack("S1", substr($msg, 10, 2));

		print "New skill: $skillsID_lut{$ID}{'name'} LV.$level SP: $sp\n";
#11 01 87 00 04 00 00 00    01 00 0F 00 00 00 41 53
#5F 43 4C 4F 41 4B 49 4E    47 00 00 00 00 00 00 00
#00 00 00 00 00 00 00
	} elsif ($switch eq "0114") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}

		$skillID = unpack("S1",substr($msg, 2, 2));
		$sourceID = substr($msg, 4, 4);
		$targetID = substr($msg, 8, 4);
		$damage = unpack("S1",substr($msg, 24, 2));
		$level = unpack("S1",substr($msg, 26, 2));
		$hit = unpack("S1",substr($msg, 28, 2));
		$skill = GetSkillName($skillID);

		if (%{$spells{$sourceID}}) {
			$sourceID = $spells{$sourceID}{'sourceID'}
		}

		updateDamageTables($sourceID, $targetID, $damage) if ($damage != 35536);
		if ($sourceID eq $accountID) {
			$chars[$config{'char'}]{'last_skill_used'} = $skillID;
			$chars[$config{'char'}]{'last_skill_target'} = $targetID;
			$chars[$config{'char'}]{'skills'}{$skillsID_lut{$skillID}{'nameID'}}{'time_used'} = time;
			undef $chars[$config{'char'}]{'last_skill_cast'};
			undef $chars[$config{'char'}]{'last_time_cast'};
		}

		if (%{$monsters{$targetID}}) {
			if ($sourceID eq $accountID) {
				$monsters{$targetID}{'castOnByYou'}++;
			} else {
				$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
			}
		}

		DebugMessage("0114: DAMAGE_ON, SOURCE: ".Name($sourceID).", TARGET: ".Name($targetID).", SKILL: $skill, DAMAGE: $damage, LV: $level") if ($debug{'msg0114'});

		if (%{$monsters{$sourceID}}) {
			if (%{$monsters{$targetID}}) {
				OnMonster($sourceID, $EV_SKILL_DAMAGE_ON_MONSTER, $targetID, $skillID, $damage, $level);
			} elsif (%{$players{$targetID}}) {
				OnMonster($sourceID, $EV_SKILL_DAMAGE_ON_PLAYER, $targetID, $skillID, $damage, $level);
			} elsif ($targetID eq $accountID) {
				OnMonster($sourceID, $EV_SKILL_DAMAGE_ON_YOU, $skillID, $damage, $level);
			} else {
				OnMonster($sourceID, $EV_SKILL_DAMAGE_ON, $targetID, $skillID, $damage, $level);
			}
		} elsif (%{$players{$sourceID}}) {
			if (%{$monsters{$targetID}}) {
				OnPlayer($sourceID, $EV_SKILL_DAMAGE_ON_MONSTER, $targetID, $skillID, $damage, $level);
			} elsif (%{$players{$targetID}}) {
				OnPlayer($sourceID, $EV_SKILL_DAMAGE_ON_PLAYER, $targetID, $skillID, $damage, $level);
			} elsif ($targetID eq $accountID) {
				OnPlayer($sourceID, $EV_SKILL_DAMAGE_ON_YOU, $skillID, $damage, $level);
			} else {
				OnPlayer($sourceID, $EV_SKILL_DAMAGE_ON, $targetID, $skillID, $damage, $level);
			}
		} elsif ($sourceID eq $accountID) {
			if (%{$monsters{$targetID}}) {
				OnYou($EV_SKILL_DAMAGE_ON_MONSTER, $targetID, $skillID, $damage, $level);
			} elsif (%{$players{$targetID}}) {
				OnYou($EV_SKILL_DAMAGE_ON_PLAYER, $targetID, $skillID, $damage, $level);
			} elsif ($targetID eq $accountID) {
				OnYou($EV_SKILL_DAMAGE_ON_YOU, $skillID, $damage, $level);
			} else {
				OnYou($EV_SKILL_DAMAGE_ON, $targetID, $skillID, $damage, $level);
			}
		}
	} elsif ($switch eq "0117") {
		$skillID = unpack("S1",substr($msg, 2, 2));
		$sourceID = substr($msg, 4, 4);
		$lv = unpack("S1",substr($msg, 8, 2));
		$x = unpack("S1",substr($msg, 10, 2));
		$y = unpack("S1",substr($msg, 12, 2));
		$skill = GetSkillName($skillID);

		undef $sourceDisplay;
		if (%{$monsters{$sourceID}}) {
			OnMonster($sourceID, $EV_SKILL_USE_AT, $skillID, $x, $y, $lv);
		} elsif (%{$players{$sourceID}}) {
			OnPlayer($sourceID, $EV_SKILL_USE_AT, $skillID, $x, $y, $lv);
		} elsif ($sourceID eq $accountID) {
			$chars[$config{'char'}]{'last_skill_used'} = $skillID;
			undef $chars[$config{'char'}]{'last_skill_target'};
			$chars[$config{'char'}]{'skills'}{$skillsID_lut{$skillID}{'nameID'}}{'time_used'} = time;
			undef $chars[$config{'char'}]{'last_skill_cast'};
			undef $chars[$config{'char'}]{'last_time_cast'};
			OnYou($EV_SKILL_USE_AT, $skillID, $x, $y, $lv);
		}

		DebugMessage("0117: USE_AT, SOURCE: ".Name($sourceID).", SKILL: $skill, ($x, $y), LV: $level") if ($debug{'msg0117'});

		print "$sourceDisplay $skill on location ($x, $y)\n" if $config{'debug'};
	} elsif ($switch eq "0119") {
		$ID = substr($msg, 2, 4);
		$critical = unpack("S1", substr($msg, 6, 2));
		$warning = unpack("S1", substr($msg, 8, 2));
		$option = unpack("S1", substr($msg, 10, 2));
		$val = unpack("S1", substr($msg, 12, 1));

		if (%{$monsters{$ID}}) {
			$status_critical = $monsters{$ID}{'status_critical'};
			$status_warning = $monsters{$ID}{'status_warning'};
			$status_option = $monsters{$ID}{'status_option'};

			SetStatus($monsters{$ID}, $critical, $warning, $option);

			if ($status_critical ne $monsters{$ID}{'status_critical'}) {
				if ($monsters{$ID}{'status_critical'} ne "") {
					OnMonster($ID, $EV_CRITICAL, ucfirst($monsters{$ID}{'status_critical'}), 1);
				} else {
					OnMonster($ID, $EV_CRITICAL, ucfirst($status_critical), 0);
				}
			}

			if ($status_warning ne $monsters{$ID}{'status_warning'}) {
				if ($monsters{$ID}{'status_warning'} ne "") {
					OnMonster($ID, $EV_WARNING, ucfirst($monsters{$ID}{'status_warning'}), 1);
				} else {
					OnMonster($ID, $EV_WARNING, ucfirst($status_warning), 0);
				}
			}

			if ($status_option ne $monsters{$ID}{'status_option'}) {
				if ($monsters{$ID}{'status_option'} ne "") {
					OnMonster($ID, $EV_OPTION, ucfirst($monsters{$ID}{'status_option'}), 1);
				} else {
					OnMonster($ID, $EV_OPTION, ucfirst($status_option), 0);
				}
			}
		} elsif (%{$players{$ID}}) {
			$status_critical = $players{$ID}{'status_critical'};
			$status_warning = $players{$ID}{'status_warning'};
			$status_option = $players{$ID}{'status_option'};

			SetStatus($players{$ID}, $critical, $warning, $option);

			if ($status_critical ne $players{$ID}{'status_critical'}) {
				if ($players{$ID}{'status_critical'} ne "") {
					OnPlayer($ID, $EV_CRITICAL, ucfirst($players{$ID}{'status_critical'}), 1);
				} else {
					OnPlayer($ID, $EV_CRITICAL, ucfirst($status_critical), 0);
				}
			}

			if ($status_warning ne $players{$ID}{'status_warning'}) {
				if ($players{$ID}{'status_warning'} ne "") {
					OnPlayer($ID, $EV_WARNING, ucfirst($players{$ID}{'status_warning'}), 1);
				} else {
					OnPlayer($ID, $EV_WARNING, ucfirst($status_warning), 0);
				}
			}

			if ($status_option ne $players{$ID}{'status_option'}) {
				if ($players{$ID}{'status_option'} ne "") {
					OnPlayer($ID, $EV_OPTION, ucfirst($players{$ID}{'status_option'}), 1);
				} else {
					OnPlayer($ID, $EV_OPTION, ucfirst($status_option), 0);
				}
			}
		} elsif ($ID eq $accountID) {
			$status_critical = $chars[$config{'char'}]{'status_critical'};
			$status_warning = $chars[$config{'char'}]{'status_warning'};
			$status_option = $chars[$config{'char'}]{'status_option'};

			SetStatus($chars[$config{'char'}], $critical, $warning, $option);

			if ($status_critical ne $chars[$config{'char'}]{'status_critical'}) {
				if ($chars[$config{'char'}]{'status_critical'} ne "") {
					OnYou($EV_CRITICAL, ucfirst($chars[$config{'char'}]{'status_critical'}), 1);
				} else {
					OnYou($EV_CRITICAL, ucfirst($status_critical), 0);
				}
			}

			if ($status_warning ne $chars[$config{'char'}]{'status_warning'}) {
				if ($chars[$config{'char'}]{'status_warning'} ne "") {
					OnYou($EV_WARNING, ucfirst($chars[$config{'char'}]{'status_warning'}), 1);
				} else {
					OnYou($EV_WARNING, ucfirst($status_warning), 0);
				}
			}

			if ($status_option ne $chars[$config{'char'}]{'status_option'}) {
				if ($chars[$config{'char'}]{'status_option'} ne "") {
					OnYou($EV_OPTION, ucfirst($chars[$config{'char'}]{'status_option'}), 1);
				} else {
					OnYou($EV_OPTION, ucfirst($status_option), 0);
				}
			}
		}

		DebugMessage("0119: STATUS, ".Name($ID).", TYPE: $critical, $warning, $option, VAL: $val") if ($debug{'msg0119'});
	} elsif ($switch eq "011A") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		$skillID = unpack("S1",substr($msg, 2, 2));
		$targetID = substr($msg, 6, 4);
		$sourceID = substr($msg, 10, 4);
		$amount = unpack("S1",substr($msg, 4, 2));
		$skill = GetSkillName($skillID);

		if (%{$spells{$sourceID}}) {
			$sourceID = $spells{$sourceID}{'sourceID'}
		}

		if ($sourceID eq $accountID) {
			$chars[$config{'char'}]{'last_skill_used'} = $skillID;
			$chars[$config{'char'}]{'last_skill_target'} = $targetID;
			$chars[$config{'char'}]{'skills'}{$skillsID_lut{$skillID}{'nameID'}}{'time_used'} = time;
			undef $chars[$config{'char'}]{'last_skill_cast'};
			undef $chars[$config{'char'}]{'last_time_cast'};
		}

		if (%{$monsters{$targetID}}) {
			if ($sourceID eq $accountID) {
				$monsters{$targetID}{'castOnByYou'}++;
			} else {
				$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
			}
		}

		DebugMessage("011A: RESTORE_ON, SOURCE: ".Name($sourceID).", TARGET: ".Name($targetID).", SKILL: $skill, AMOUNT: $amount") if ($debug{'msg011A'});

		if (%{$monsters{$sourceID}}) {
			if (%{$monsters{$targetID}}) {
				OnMonster($sourceID, $EV_SKILL_RESTORE_ON_MONSTER, $targetID, $skillID, $amount);
			} elsif (%{$players{$targetID}}) {
				OnMonster($sourceID, $EV_SKILL_RESTORE_ON_PLAYER, $targetID, $skillID, $amount);
			} elsif ($targetID eq $accountID) {
				OnMonster($sourceID, $EV_SKILL_RESTORE_ON_YOU, $skillID, $amount);
			} else {
				OnMonster($sourceID, $EV_SKILL_RESTORE_ON, $targetID, $skillID, $amount);
			}

			if ($skillsID_lut{$skillID}{'nameID'} eq "AL_TELEPORT") {
				OnMonster($sourceID, $EV_DISAPPEARED);

				%{$monsters_old{$sourceID}} = %{$monsters{$sourceID}};
				$monsters_old{$sourceID}{'disappeared'} = 1;
				$monsters_old{$sourceID}{'gone_time'} = time;

				binRemove(\@monstersID, $sourceID);
				#undef %{$monsters{$sourceID}};
				delete $monsters{$sourceID};
			}
		} elsif (%{$players{$sourceID}}) {
			if (%{$monsters{$targetID}}) {
				OnPlayer($sourceID, $EV_SKILL_RESTORE_ON_MONSTER, $targetID, $skillID, $amount);
			} elsif (%{$players{$targetID}}) {
				OnPlayer($sourceID, $EV_SKILL_RESTORE_ON_PLAYER, $targetID, $skillID, $amount);
			} elsif ($targetID eq $accountID) {
				OnPlayer($sourceID, $EV_SKILL_RESTORE_ON_YOU, $skillID, $amount);
			} else {
				OnPlayer($sourceID, $EV_SKILL_RESTORE_ON, $targetID, $skillID, $amount);
			}
		} elsif ($sourceID eq $accountID) {
			if (%{$monsters{$targetID}}) {
				OnYou($EV_SKILL_RESTORE_ON_MONSTER, $targetID, $skillID, $amount);
			} elsif (%{$players{$targetID}}) {
				OnYou($EV_SKILL_RESTORE_ON_PLAYER, $targetID, $skillID, $amount);
			} elsif ($targetID eq $accountID) {
				OnYou($EV_SKILL_RESTORE_ON_YOU, $skillID, $amount);
			} else {
				OnYou($EV_SKILL_RESTORE_ON, $targetID, $skillID, $amount);
			}
		}
	} elsif ($switch eq "011C") {
		$type = unpack("S1",substr($msg, 2, 2));

		($memo1) = substr($msg, 4, 16) =~ /([\s\S]*?)\000/;
		($memo2) = substr($msg, 20, 16) =~ /([\s\S]*?)\000/;
		($memo3) = substr($msg, 36, 16) =~ /([\s\S]*?)\000/;
		($memo4) = substr($msg, 52, 16) =~ /([\s\S]*?)\000/;

		($memo1) = $memo1 =~ /([\s\S]*)\.gat/;
		($memo2) = $memo2 =~ /([\s\S]*)\.gat/;
		($memo3) = $memo3 =~ /([\s\S]*)\.gat/;
		($memo4) = $memo4 =~ /([\s\S]*)\.gat/;

		$warp{'use'} = $type;
		undef @{$warp{'memo'}};
		push @{$warp{'memo'}}, $memo1 if $memo1 ne "";
		push @{$warp{'memo'}}, $memo2 if $memo2 ne "";
		push @{$warp{'memo'}}, $memo3 if $memo3 ne "";
		push @{$warp{'memo'}}, $memo4 if $memo4 ne "";

		print "----------------- Warp Portal --------------------\n";
		print "#  Place                           Map\n";
		for ($i=0; $i < @{$warp{'memo'}};$i++) {
			PrintFormat(<<'MEMOS', $i, $maps_lut{$warp{'memo'}[$i].'.rsw'}, $warp{'memo'}[$i]);
@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<
MEMOS
		}
		print "--------------------------------------------------\n";

		if ($chars[$config{'char'}]{'useteleport'}) {
			sendTeleport(\$remote_socket, $warp{'memo'}[0].".gat");
			undef $chars[$config{'char'}]{'useteleport'};
		} else {
			ShowWrapperWarpPortal();
		}

#1C 01 1B 00 6D 6F 72 6F    63 63 2E 67 61 74 00 00
#00 00 00 00 63 6F 6D 6F    64 6F 2E 67 61 74 00 00
#00 00 00 00 67 65 66 66    65 6E 2E 67 61 74 00 00
#00 00 00 00 70 72 6F 6E    74 65 72 61 2E 67 61 74
#00 00 00 00
	} elsif ($switch eq "011E") {
		$fail = unpack("C1", substr($msg, 2, 1));
		if ($fail) {
			print "Memo Failed\n";
		} else {
			print "Memo Succeeded\n";
		}
	} elsif ($switch eq "011F") {
		#area effect spell
		$ID = substr($msg, 2, 4);
		$SourceID = substr($msg, 6, 4);
		$x = unpack("S1",substr($msg, 10, 2));
		$y = unpack("S1",substr($msg, 12, 2));
		$spells{$ID}{'sourceID'} = $SourceID;
		$spells{$ID}{'pos'}{'x'} = $x;
		$spells{$ID}{'pos'}{'y'} = $y;
		$binID = binAdd(\@spellsID, $ID);
		$spells{$ID}{'binID'} = $binID;

		$skillID = unpack("C1", substr($msg, 14, 1));
		$useskill = unpack("C1", substr($msg, 15, 1));
		$skill = GetSkillName($skillID);

		DebugMessage("011F: AREA_AT, SOURCE: ".Name($SourceID).", SKILL: $skill, ($x, $y)") if ($debug{'msg011F'});

		if (%{$monsters{$SourceID}}) {
			OnMonster($SourceID, $EV_SKILL_AREA_AT, $skillID, $x, $y);
		} elsif (%{$players{$SourceID}}) {
			OnPlayer($SourceID, $EV_SKILL_AREA_AT, $skillID, $x, $y);
		} elsif ($SourceID eq $accountID) {
			OnYou($EV_SKILL_AREA_AT, $skillID, $x, $y);
		}
	} elsif ($switch eq "0120") {
		#The area effect spell with ID dissappears
		$ID = substr($msg, 2, 4);
		undef %{$spells{$ID}};
		binRemove(\@spellsID, $ID);
#Cart Parses - chobit andy 20030102
	} elsif ($switch eq "0121") {
		$cart{'items'} = unpack("S1", substr($msg, 2, 2));
		$cart{'items_max'} = unpack("S1", substr($msg, 4, 2));
		$cart{'weight'} = int(unpack("L1", substr($msg, 6, 4)) / 10);
		$cart{'weight_max'} = int(unpack("L1", substr($msg, 10, 4)) / 10);

		OnYou($EV_CART_CAP);
	} elsif ($switch eq "0122") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		for($i = 4; $i < $msg_size; $i += 20) {
# No      ID     Type Iden Eq.Type            Enc  Slot 1  Slot 2  Slot 3  Slot 4
# 55 00 | 60 04 | 05 | 01 | 02 00 | 00 00 00 | 00 | CB 0F | CB 0F | 00 00 | 00 00
			$index = unpack("S1", substr($msg, $i, 2));
			$ID = unpack("S1", substr($msg, $i+2, 2));
			if (%{$cart{'inventory'}[$index]}) {
				$cart{'inventory'}[$index]{'amount'} += 1;
			} else {
				$cart{'inventory'}[$index]{'nameID'} = $ID;
				$cart{'inventory'}[$index]{'amount'} = 1;
				$cart{'inventory'}[$index]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
				$cart{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
				$cart{'inventory'}[$index]{'type_equip'} = unpack("S1", substr($msg, $i + 6, 2));
				$cart{'inventory'}[$index]{'special'} = unpack("C1", substr($msg, $i + 10, 1));
				$cart{'inventory'}[$index]{'refine'} = unpack("C1", substr($msg, $i + 11, 1));
				$cart{'inventory'}[$index]{'cardID_1'} = unpack("S1", substr($msg, $i + 12, 2));
				if ($cart{'inventory'}[$index]{'cardID_1'} == 255) {
					$cart{'inventory'}[$index]{'elementID'} = unpack("C1", substr($msg, $i + 14, 1));
					$cart{'inventory'}[$index]{'elementName'} = $elements_lut{$cart{'inventory'}[$index]{'elementID'}};
					$cart{'inventory'}[$index]{'strongID'} = unpack("C1", substr($msg, $i + 15, 1));
					$cart{'inventory'}[$index]{'strongName'} = $strongs_lut{$cart{'inventory'}[$index]{'strongID'}};
				} else {
					$cart{'inventory'}[$index]{'cardID_2'} = unpack("S1", substr($msg, $i + 14, 2));
					$cart{'inventory'}[$index]{'cardID_3'} = unpack("S1", substr($msg, $i + 16, 2));
					$cart{'inventory'}[$index]{'cardID_4'} = unpack("S1", substr($msg, $i + 18, 2));
				}

				GenName($cart{'inventory'}[$index]);
			}

			OnYou($EV_CART_UPDATED, $index);

			print "Cart Item: $cart{'inventory'}[$index]{'name'} ($index) x 1\n" if ($config{'debug'} >= 1);
		}

	} elsif ($switch eq "0123") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		for($i = 4; $i < $msg_size; $i+=10) {
			# 02 00 C4 02 03 01 07 00 00 00
			# 03 00 C0 02 03 01 06 00 00 00
			$index = unpack("S1", substr($msg, $i, 2));
			$ID = unpack("S1", substr($msg, $i+2, 2));
			$amount = unpack("S1", substr($msg, $i+6, 2));
			if (%{$cart{'inventory'}[$index]}) {
				$cart{'inventory'}[$index]{'amount'} += $amount;
			} else {
				$cart{'inventory'}[$index]{'nameID'} = $ID;
				$cart{'inventory'}[$index]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
				$cart{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
				$cart{'inventory'}[$index]{'amount'} = $amount;
				$display = ($items_lut{$ID} ne "")
					? $items_lut{$ID}
					: "Unknown ".$ID;
				$cart{'inventory'}[$index]{'name'} = $display;
			}

			OnYou($EV_CART_UPDATED, $index);
			print "Cart Item: $cart{'inventory'}[$index]{'name'} ($index) x $amount\n" if ($config{'debug'} >= 1);
		}
	} elsif ($switch eq "0124") {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));
		$ID = unpack("S1", substr($msg, 8, 2));
		if (%{$cart{'inventory'}[$index]}) {
			$cart{'inventory'}[$index]{'amount'} += $amount;
		} else {
			$cart{'inventory'}[$index]{'nameID'} = $ID;
			$cart{'inventory'}[$index]{'amount'} = $amount;
			$cart{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, 10, 1));
			$cart{'inventory'}[$index]{'refine'} = unpack("C1", substr($msg, 12, 1));
			$cart{'inventory'}[$index]{'cardID_1'} = unpack("S1", substr($msg, 13, 2));
			if ($cart{'inventory'}[$index]{'cardID_1'} == 255) {
				$cart{'inventory'}[$index]{'elementID'} = unpack("C1", substr($msg, 15, 1));
				$cart{'inventory'}[$index]{'elementName'} = $elements_lut{$cart{'inventory'}[$index]{'elementID'}};
				$cart{'inventory'}[$index]{'strongID'} = unpack("C1", substr($msg, 16, 1));
				$cart{'inventory'}[$index]{'strongName'} = $strongs_lut{$cart{'inventory'}[$index]{'strongID'}};
			} else {
				$cart{'inventory'}[$index]{'cardID_2'} = unpack("S1", substr($msg, 15, 2));
				$cart{'inventory'}[$index]{'cardID_3'} = unpack("S1", substr($msg, 17, 2));
				$cart{'inventory'}[$index]{'cardID_4'} = unpack("S1", substr($msg, 19, 2));
			}

			GenName($cart{'inventory'}[$index]);
		}

		OnYou($EV_CART_ADDED, $index);

		PrintMessage("Cart item added: $cart{'inventory'}[$index]{'name'} x $amount", "white");
		#print "Cart Item Added: $cart{'inventory'}[$index]{'name'} ($index) x $amount\n" if $config{'debug'};
#24 01 | 04 00 | 01 00 00 00 | 5C 02 | 01 | 00 | 00 | 00 00 | 00 00 | 00 00 | 00 00
#24 01 | 5F 00 | 01 00 00 00 | 4A 05 | 01 | 00 | 07 | 00 00 | 00 00 | 00 00 | 00 00
	} elsif ($switch eq "0125") {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));
		$cart{'inventory'}[$index]{'amount'} -= $amount;
		$cart{'full'} = 0;

		OnYou($EV_CART_REMOVED, $index);

		PrintMessage("Cart item removed: $cart{'inventory'}[$index]{'name'} x $amount", "white");
		#print "Cart Item Removed: $cart{'inventory'}[$index]{'name'} ($index) x $amount\n" if $config{'debug'};
		if ($cart{'inventory'}[$index]{'amount'} <= 0) {
			undef %{$cart{'inventory'}[$index]};
		}
	} elsif ($switch eq "012C") {
		$fail = unpack("C1", substr($msg, 2, 1));
		$cart{'full'} = 1;

		PrintMessage("Could not add item to cart.", "red");
		OnYou($EV_CART_ADD_FAILED);
	} elsif ($switch eq "012D") {
		# Used the shop skill.
		$shop{'items_max'} = unpack("S1",substr($msg, 2, 2));
		print "You can sell $shop{'items_max'} items!\n" if $config{'debug'};

		if ($shop{'auto'} || $config{'remoteSocket'}) {
			ShopOpen(\$remote_socket);
		}
	} elsif ($switch eq "0131") {
		$ID = substr($msg,2,4);
		if (!%{$venderLists{$ID}}) {
			binAdd(\@venderListsID, $ID);
		}
		($venderLists{$ID}{'title'}) = substr($msg,6,36) =~ /(.*?)\000/;
		$venderLists{$ID}{'id'} = $ID;

		OnPlayer($ID, $EV_SHOP_APPEARED);
	} elsif ($switch eq "0132") {
		$ID = substr($msg,2,4);
		OnPlayer($ID, $EV_SHOP_DISAPPEARED);

		binRemove(\@venderListsID, $ID);
		#undef %{$venderLists{$ID}};
		delete $venderLists{$ID};
	} elsif ($switch eq "0133") {
		undef $lastVenderID;
		undef %vender;

		$ID = substr($msg,4,4);
		$lastVenderID = $ID;

		print "------------------------------ Vender Store List ------------------------------\n";
		print "#   Name                                         Type           Amount Price\n";
		for ($i = 8; $i < $msg_size; $i += 22) {
			$index = unpack("S1", substr($msg, $i + 6, 2));

			$vender{'inventory'}[$index]{'price'} = unpack("L1", substr($msg, $i, 4));
			$vender{'inventory'}[$index]{'amount'} = unpack("S1", substr($msg, $i + 4, 2));
			$vender{'inventory'}[$index]{'type'} = unpack("C1", substr($msg, $i + 8, 1));
			$vender{'inventory'}[$index]{'nameID'} = unpack("S1", substr($msg, $i + 9, 2));
			$vender{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, $i + 11, 1));
			$vender{'inventory'}[$index]{'special'} = unpack("C1", substr($msg, $i + 12, 1));
			$vender{'inventory'}[$index]{'refine'} = unpack("C1", substr($msg, $i + 13, 1));
			$vender{'inventory'}[$index]{'cardID_1'} = unpack("S1", substr($msg, $i + 14, 2));
			if ($vender{'inventory'}[$index]{'cardID_1'} == 255) {
				$vender{'inventory'}[$index]{'elementID'} = unpack("C1", substr($msg, $i + 16, 1));
				$vender{'inventory'}[$index]{'elementName'} = $elements_lut{$vender{'inventory'}[$index]{'elementID'}};
				$vender{'inventory'}[$index]{'strongID'} = unpack("C1", substr($msg, $i + 17, 1));
				$vender{'inventory'}[$index]{'strongName'} = $strongs_lut{$vender{'inventory'}[$index]{'strongID'}};
			} else {
				$vender{'inventory'}[$index]{'cardID_2'} = unpack("S1", substr($msg, $i + 16, 2));
				$vender{'inventory'}[$index]{'cardID_3'} = unpack("S1", substr($msg, $i + 18, 2));
				$vender{'inventory'}[$index]{'cardID_4'} = unpack("S1", substr($msg, $i + 20, 2));
			}

			GenName($vender{'inventory'}[$index]);

			$display = GenShowName($vender{'inventory'}[$index]);

			if (!$vender_items{$display}{'minPrice'} || $vender_items{$display}{'minPrice'} > $vender{'inventory'}[$index]{'price'}) {
				$vender_items{$display}{'minPrice'} = $vender{'inventory'}[$index]{'price'};
				$vender_items{$display}{'ID'} = $ID;
				$vender_items{$display}{'index'} = $index;
				$vender_items{$display}{'amount'} = $vender{'inventory'}[$index]{'amount'};
			}

			if ($vender_items{$display}{'maxPrice'} < $vender{'inventory'}[$index]{'price'}) {
				$vender_items{$display}{'maxPrice'} = $vender{'inventory'}[$index]{'price'};
			}

			print "Item added to Vender Store: $display - $price z\n" if ($config{'debug'} >= 2);

			if (!($vender{'inventory'}[$index]{'identified'})) {
				$iden = "*";
			} else {
				$iden = "";
			}

			PrintFormat(<<'VSTORELIST', $index, $iden, $display, $itemTypes_lut{$vender{'inventory'}[$index]{'type'}}, $vender{'inventory'}[$index]{'amount'}, $vender{'inventory'}[$index]{'price'});
@< @@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<< @>>>>> @>>>>>>>z
VSTORELIST
		}

		print "-------------------------------------------------------------------------------\n";

		if ($chars[$config{'char'}]{'shopping'} && $ID eq $chars[$config{'char'}]{'shoppingLastID'}) {
			@key_sort = sort { $a cmp $b } keys %vender_items;

			ClearWrapperShopping();

			for ($i = 0; $i < @{key_sort}; $i++) {
				$key = $key_sort[$i];
				$vender_keys[$i] = $key;
				$vender_players{$vender_items{$key}{'ID'}} = $i;
				AddWrapperShopping($i);
			}

			ShowWrapperShopping();

			undef $chars[$config{'char'}]{'shopping'};
		}
	} elsif ($switch eq "0135") {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("S1", substr($msg, 4, 2));
		$type = unpack("C1", substr($msg, 6, 1));

		PrintMessage("The number of Item is $amount. (index $index, type $type)", "red");
#35 01 1F 00 00 00 04
#35 01 0C 00 01 00 04
#35 01 0D 00 01 00 04
	} elsif ($switch eq "0136") {
		undef @{$shop{'inventory'}};

		$shop{'items'} = 0;

		print "---------------------------------- Shop List ----------------------------------\n";
		print "#  Name                                         Type           Amount Price\n";
		for ($i = 8; $i < $msg_size; $i+=22) {
			$index = unpack("S1", substr($msg, $i + 4, 2));
			$shop{'inventory'}[$index]{'sold'} = 0;
			$shop{'inventory'}[$index]{'price'} = unpack("L1", substr($msg, $i, 4));
			$shop{'inventory'}[$index]{'amount'} = unpack("S1", substr($msg, $i + 6, 2));
			$shop{'inventory'}[$index]{'type'} = unpack("C1", substr($msg, $i + 8, 1));
			$shop{'inventory'}[$index]{'nameID'} = unpack("S1", substr($msg, $i + 9, 2));
			$shop{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, $i + 11, 1));
			$shop{'inventory'}[$index]{'special'} = unpack("C1", substr($msg, $i + 12, 1));
			$shop{'inventory'}[$index]{'refine'} = unpack("C1", substr($msg, $i + 13, 1));
			$shop{'inventory'}[$index]{'cardID_1'} = unpack("S1", substr($msg, $i + 14, 2));
			if ($shop{'inventory'}[$index]{'cardID_1'} == 255) {
				$shop{'inventory'}[$index]{'elementID'} = unpack("C1", substr($msg, $i + 16, 1));
				$shop{'inventory'}[$index]{'elementName'} = $elements_lut{$shop{'inventory'}[$index]{'elementID'}};
				$shop{'inventory'}[$index]{'strongID'} = unpack("C1", substr($msg, $i + 17, 1));
				$shop{'inventory'}[$index]{'strongName'} = $strongs_lut{$shop{'inventory'}[$index]{'strongID'}};
			} else {
				$shop{'inventory'}[$index]{'cardID_2'} = unpack("S1", substr($msg, $i + 16, 2));
				$shop{'inventory'}[$index]{'cardID_3'} = unpack("S1", substr($msg, $i + 18, 2));
				$shop{'inventory'}[$index]{'cardID_4'} = unpack("S1", substr($msg, $i + 20, 2));
			}

			GenName($shop{'inventory'}[$index]);

			$display = $shop{'inventory'}[$index]{'name'};

			print "Item added to Vender Store: $display - $price z\n" if ($config{'debug'} >= 2);

			if (!($shop{'inventory'}[$index]{'identified'})) {
				$display = $display."[NI]";
			}

			PrintFormat(<<'SHOPLIST', $index, $display, $itemTypes_lut{$shop{'inventory'}[$index]{'type'}}, $shop{'inventory'}[$index]{'amount'}, $shop{'inventory'}[$index]{'price'});
@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<< @>>>>> @>>>>>>>z
SHOPLIST

			$shop{'items'}++;
		}

		print "-------------------------------------------------------------------------------\n";

		$i = 0;
		while (1) {
			last if ($config{"shop_item_$i"} eq "");

			$index = findIndexString_lc(\@{$shop{'inventory'}}, "name", $config{"shop_item_$i"});
			if ($index ne "") {
				$shop{'inventory'}[$index]{'require'} = $config{"shop_item_$i"."_require"};
				$shop{'inventory'}[$index]{'minAmount'} = $config{"shop_item_$i"."_minAmount"};
				$shop{'inventory'}[$index]{'maxAmount'} = $config{"shop_item_$i"."_maxAmount"};
			}

			$i++;
		}

		$shop{'earned'} = 0;
	} elsif ($switch eq "0137") {
		# Sold something.
		$index = unpack("S1",substr($msg, 2, 2));
		$amount = unpack("S1",substr($msg, 4, 2));
		$shop{'inventory'}[$index]{'sold'} += $amount;
		$shop{'earned'} += $amount * $shop{'inventory'}[$index]{'price'};
		$shop{'inventory'}[$index]{'amount'} -= $amount;
		PrintMessage("Sold: $amount $shop{'inventory'}[$index]{'name'}", "white");
		if ($shop{'inventory'}[$index]{'amount'} <= 0) {
			PrintMessage("Sold out: $shop{'inventory'}[$index]{'name'}", "red");
			$shop{'items'}--;

			if (!$shop{'items'}){
				PrintMessage("Sold all out. ^_^", "white");
				ShopClose(\$remote_socket);
			}
		}
	} elsif ($switch eq "0139") {
		$ID = substr($msg, 2, 4);
		$coords1{'x'} = unpack("S1",substr($msg, 6, 2));
		$coords1{'y'} = unpack("S1",substr($msg, 8, 2));
		$coords2{'x'} = unpack("S1",substr($msg, 10, 2));
		$coords2{'y'} = unpack("S1",substr($msg, 12, 2));
		$range = unpack("S1",substr($msg, 14, 2));

		#if (%{$monsters{$ID}}) {
		#	%{$monsters{$ID}{'pos_attack_info'}} = %coords1;
		#	print "Recieved attack location - $monsters{$ID}{'pos_attack_info'}{'x'}, $monsters{$ID}{'pos_attack_info'}{'y'} - ".getHex($ID)."\n" if ($config{'debug'} >= 2);
		#}

		%{$chars[$config{'char'}]{'pos'}} = %coords2;
		%{$chars[$config{'char'}]{'pos_to'}} = %coords2;
	} elsif ($switch eq "013A") {
		$chars[$config{'char'}]{'attack_range'} = unpack("S1",substr($msg, 2, 2));
	} elsif ($switch eq "013B") {
		$type = unpack("S1",substr($msg, 2, 2));
		if ($type == 0) {
			PrintMessage("No arrow.", "red");
			OnYou($EV_NO_ARROW);
		} elsif ($type == 3) {
			PrintMessage("Arrow is equipped.", "white");
		} else {
			print "013B: $type\n";
		}
	} elsif ($switch eq "013C") {
		$index = unpack("S1", substr($msg, 2, 2));
		if ($index) {
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			if ($invIndex ne "") {
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = 1024;
				print "You equip $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) - $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}}\n" if $config{'debug'};
				OnYou($EV_EQUIP, $invIndex);
				OnYou($EV_INVENTORY_UPDATED, $invIndex);
			} else {
				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = 1;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = 1024;
			}
		} else {
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "equipped", 1024);
			if ($invIndex ne "") {
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = 0;
				OnYou($EV_UNEQUIP, $invIndex);
				OnYou($EV_INVENTORY_UPDATED, $invIndex);
			}
		}
	} elsif ($switch eq "013D") {
		$type = unpack("S1",substr($msg, 2, 2));
		$amount = unpack("S1",substr($msg, 4, 2));
		if ($type == 5) {
			$chars[$config{'char'}]{'hp'} += $amount;
			$chars[$config{'char'}]{'hp'} = $chars[$config{'char'}]{'hp_max'} if ($chars[$config{'char'}]{'hp'} > $chars[$config{'char'}]{'hp_max'});
		} elsif ($type == 7) {
			$chars[$config{'char'}]{'sp'} += $amount;
			$chars[$config{'char'}]{'sp'} = $chars[$config{'char'}]{'sp_max'} if ($chars[$config{'char'}]{'sp'} > $chars[$config{'char'}]{'sp_max'});
		}
		OnYou($EV_STAT_CHANGED);
	} elsif ($switch eq "013E") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		$sourceID = substr($msg, 2, 4);
		$targetID = substr($msg, 6, 4);
		$x = unpack("S1",substr($msg, 10, 2));
		$y = unpack("S1",substr($msg, 12, 2));
		$skillID = unpack("S1",substr($msg, 14, 2));
		$wait = unpack("L1",substr($msg, 20, 4));
		$skill = GetSkillName($skillID);
		undef $sourceDisplay;
		undef $targetDisplay;
		if ($sourceID eq $accountID) {
			$chars[$config{'char'}]{'last_skill_cast'} = $skillID;
			$chars[$config{'char'}]{'last_time_cast'} = time;
		}

		if (%{$monsters{$targetID}}) {
			if ($sourceID eq $accountID) {
				$monsters{$targetID}{'castOnByYou'}++;
			} else {
				$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
			}
		}

		DebugMessage("013E: CASTING, SOURCE: ".Name($SourceID).", TARGET: ".Name($targetID).", SKILL: $skill, ($x, $y)") if ($debug{'msg013E'});

		if (%{$monsters{$sourceID}}) {
			if (%{$monsters{$targetID}}) {
				OnMonster($sourceID, $EV_SKILL_CASTING_ON_MONSTER, $targetID, $skillID, $wait);
			} elsif (%{$players{$targetID}}) {
				OnMonster($sourceID, $EV_SKILL_CASTING_ON_PLAYER, $targetID, $skillID, $wait);
			} elsif ($targetID eq $accountID) {
				OnMonster($sourceID, $EV_SKILL_CASTING_ON_YOU, $skillID, $wait);
			} elsif ($x != 0 || $y != 0) {
				OnMonster($sourceID, $EV_SKILL_CASTING_AT, $skillID, $x, $y, $wait);
			}
		} elsif (%{$players{$sourceID}}) {
			if (%{$monsters{$targetID}}) {
				OnPlayer($sourceID, $EV_SKILL_CASTING_ON_MONSTER, $targetID, $skillID, $wait);
			} elsif (%{$players{$targetID}}) {
				OnPlayer($sourceID, $EV_SKILL_CASTING_ON_PLAYER, $targetID, $skillID, $wait);
			} elsif ($targetID eq $accountID) {
				OnPlayer($sourceID, $EV_SKILL_CASTING_ON_YOU, $skillID, $wait);
			} elsif ($x != 0 || $y != 0) {
				OnPlayer($sourceID, $EV_SKILL_CASTING_AT, $skillID, $x, $y, $wait);
			}
		} elsif ($sourceID eq $accountID) {
			if (%{$monsters{$targetID}}) {
				OnYou($EV_SKILL_CASTING_ON_MONSTER, $targetID, $skillID, $wait);
			} elsif (%{$players{$targetID}}) {
				OnYou($EV_SKILL_CASTING_ON_PLAYER, $targetID, $skillID, $wait);
			} elsif ($targetID eq $accountID) {
				OnYou($EV_SKILL_CASTING_ON_YOU, $skillID, $wait);
			} elsif ($x != 0 || $y != 0) {
				OnYou($EV_SKILL_CASTING_AT, $skillID, $x, $y, $wait);
			}
		}
	} elsif ($switch eq "0141") {
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
		OnYou($EV_STAT_CHANGED);
	} elsif ($switch eq "0145") {
		($npc_image) = substr($msg, 2, 16) =~ /([\s\S]*?)\000/;
		$type = unpack("C1",substr($msg, 18, 1));
		print "NPC image: $npc_image, $type\n";

		OnNpc($ID, $EV_IMAGE);
	} elsif ($switch eq "0147") {
      		$skillID = unpack("S*",substr($msg, 2, 2));
      		$skillLv = unpack("S*",substr($msg, 8, 2));
		$skill = GetSkillName($skillID);

		if ($config{'teleportAuto_useItem'} == 2 && $skillID == 26) {
			sendTeleport(\$remote_socket, "Random") if ($chars[$config{'char'}]{'usewing'} == 1);
			sendTeleport(\$remote_socket, $config{'saveMap'}.".gat") if ($chars[$config{'char'}]{'usewing'} >= 2);
			$chars[$config{'char'}]{'usewing'} = 0;
		} else {
			print "Now using $skill, lv $skillLv\n" if $config{'debug'};
			sendSkillUse(\$remote_socket, $skillID, $skillLv, $accountID);
		}
	} elsif ($switch eq "0148") {
		$ID = substr($msg, 2, 4);
		if ($ID eq $accountID) {
			undef $chars[$config{'char'}]{'dead'};
		} elsif (%{$players{$ID}}) {
			undef $players{$ID}{'dead'};
		}

		ChatWrapper("", Name($ID)." is alive!", "debug");
	} elsif ($switch eq "014A") {
		$type = unpack("L1", substr($msg, 2, 4));
	} elsif ($switch eq "014B") {
		$type = unpack("C1", substr($msg, 2, 1));
		($name) = substr($msg, 3, 24) =~ /([\s\S]*?)\000/;
	} elsif ($switch eq "014C") {
		OnYou($EV_GUILD_ALLIES_CLEARED);
		OnYou($EV_GUILD_ENEMY_CLEARED);

		undef @{$chars[$config{'char'}]{'guild'}{'allies'}};
		undef @{$chars[$config{'char'}]{'guild'}{'enemy'}};

		$indexAllies = 0;
		$indexEnemy = 0;
		for($i = 4; $i < $msg_size; $i += 32) {
			$type = unpack("L1", substr($msg, $i, 4));
			$ID = substr($msg, $i + 4, 4);
			if (!$type) {
				$chars[$config{'char'}]{'guild'}{'allies'}[$indexAllies]{'ID'} = $ID;
				($chars[$config{'char'}]{'guild'}{'allies'}[$indexAllies]{'name'}) = substr($msg, $i + 8, 24) =~ /([\s\S]*?)\000/;
				OnYou($EV_GUILD_ALLIES_ADDED, $indexAllies);

				$indexAllies++;
			} else {
				$chars[$config{'char'}]{'guild'}{'enemy'}[$indexEnemy]{'ID'} = $ID;
				($chars[$config{'char'}]{'guild'}{'enemy'}[$indexEnemy]{'name'}) = substr($msg, $i + 8, 24) =~ /([\s\S]*?)\000/;
				OnYou($EV_GUILD_ENEMY_ADDED, $indexEnemy);

				$indexEnemy++;
			}
		}
#4C 01 24 00 01 00 00 00    70 17 00 00 5B 2D 3D 47
#72 65 61 74 2D 50 6C 61    79 65 72 5D 3D 2D 49 49
#49 00 00 00
	} elsif ($switch eq "014E") {
#4E 01 57 00 00 00
	} elsif ($switch eq "0150") {
		$chars[$config{'char'}]{'guild'}{'ID'} = substr($msg, 2, 4);
		$chars[$config{'char'}]{'guild'}{'level'} = unpack("C1", substr($msg, 6, 1));
		$chars[$config{'char'}]{'guild'}{'online_member'} = unpack("C1", substr($msg, 10, 1));
		$chars[$config{'char'}]{'guild'}{'total_member'} = unpack("C1", substr($msg, 14, 1));
		$chars[$config{'char'}]{'guild'}{'avg_level'} = unpack("S1", substr($msg, 18, 2));
		$chars[$config{'char'}]{'guild'}{'exp'} = unpack("L1", substr($msg, 22, 4));
		($chars[$config{'char'}]{'guild'}{'name'}) = substr($msg, 46, 24) =~ /([\s\S]*?)\000/;
		($chars[$config{'char'}]{'guild'}{'master'}) = substr($msg, 70, 24) =~ /([\s\S]*?)\000/;

		OnYou($EV_GUILD_UPDATED);

#50 01 9F 2B 00 00 01 00    00 00 02 00 00 00 10 00
#00 00 3B 00 00 00 1D 77    00 00 80 84 1E 00 00 00
#00 00 00 00 00 00 00 00    00 00 01 00 00 00 7E 47
#2E 4F 2E 44 7E 00 A4 C7    D2 C1 C1 D1 B9 7E 7C 00
#5B 4E 5D 00 2E 00 4D 69    6E 74 20 28 57 69 7A 61
#72 64 29 00 57 69 7A 61    65 44 00 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 00 00 00
	} elsif ($switch eq "0152") {
	} elsif ($switch eq "0154") {
		OnYou($EV_GUILD_MEMBER_CLEARED);

		$index = 0;
		for($i = 4; $i < $msg_size; $i += 104) {
			$chars[$config{'char'}]{'guild'}{'member'}[$index]{'ID'} = substr($msg, $i, 4);
			$chars[$config{'char'}]{'guild'}{'member'}[$index]{'charID'} = substr($msg, $i + 4, 4);
			$chars[$config{'char'}]{'guild'}{'member'}[$index]{'jobID'} = unpack("S1", substr($msg, $i + 14, 2));
			$chars[$config{'char'}]{'guild'}{'member'}[$index]{'level'} = unpack("S1", substr($msg, $i + 16, 2));
			$chars[$config{'char'}]{'guild'}{'member'}[$index]{'exp'} = unpack("L1", substr($msg, $i + 18, 4));
			$chars[$config{'char'}]{'guild'}{'member'}[$index]{'online'} = unpack("C1", substr($msg, $i + 22, 1));
			$chars[$config{'char'}]{'guild'}{'member'}[$index]{'pos_index'} = unpack("L1", substr($msg, $i + 26, 4));
			($chars[$config{'char'}]{'guild'}{'member'}[$index]{'name'}) = substr($msg, $i + 80, 24) =~ /([\s\S]*?)\000/;

			OnYou($EV_GUILD_MEMBER_ADDED, $index);

			$index++;
		}
#54 01 84 06

#7C C4 0A 00 44 2F 09 00    00 00 00 00 00 00 09 00
#4A 00 6D 1F 01 00 00 00    00 00 00 00 00 00 00 00
#13 00 00 00 00 00 00 00    00 00 09 00 00 00 00 00
#00 00 00 00 00 00 00 00    E6 30 00 00 63 DE 05 00
#13 00 00 00 00 00 00 00    00 00 0B 00 00 00 00 00
#4D 69 6E 74 20 28 57 69    7A 61 72 64 29 00 00 00
#41 00 00 00 00 00 00 00

#36 5A 03 00 BD 67 0C 00    00 00 00 00 00 00 0C 00
#4F 00 76 74 02 00 00 00    00 00 01 00 00 00 00 00
#13 00 00 00 00 00 00 00    00 00 09 00 00 00 00 00
#00 00 00 00 00 00 00 00    E6 30 00 00 63 DE 05 00
#13 00 00 00 00 00 00 00    00 00 0B 00 00 00 00 00
#7E 5B 49 63 59 27 73 5D    7E 00 72 64 29 00 00 00
#41 00 00 00 00 00 00 00

#01 37 05 00 76 9B 08 00    00 00 00 00 00 00 08 00
#3B 00 00 00 00 00 00 00    00 00 02 00 00 00 00 00
#13 00 00 00 00 00 00 00    00 00 09 00 00 00 00 00
#00 00 00 00 00 00 00 00    E6 30 00 00 63 DE 05 00
#13 00 00 00 00 00 00 00    00 00 0B 00 00 00 00 00
#42 21 42 21 00 27 73 5D    7E 00 72 64 29 00 00 00
#41 00 00 00 00 00 00 00
	} elsif ($switch eq "0156") {
		for($i = 4; $i < $msg_size; $i += 12) {
			$memberID = substr($msg, $i, 4);
			$memberCharID = substr($msg, $i + 4, 4);

			for ($j = 0; $j < $chars[$config{'char'}]{'guild'}{'total_member'}; $j++) {
				if ($chars[$config{'char'}]{'guild'}{'member'}[$j]{'ID'} eq $memberID &&
					$chars[$config{'char'}]{'guild'}{'member'}[$j]{'charID'} eq $memberCharID) {

					$chars[$config{'char'}]{'guild'}{'member'}[$j]{'pos_index'} = unpack("L1", substr($msg, $i + 8, 4));

					OnYou($EV_GUILD_MEMBER_UPDATED, $j);
					last;
				}
			}
		}
#56 01 10 00 72 99 06 00 90 24 14 00 0E 00 00 00
	} elsif ($switch eq "015A") {
		($name) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		($cause) = substr($msg, 26, 40) =~ /([\s\S]*?)\000/;
		ChatWrapper("", "Guild Member Leave: $name : $cause", "g");
#5A 01 7E 5B 50 5D 6C 65    3A 2B 3A 5B 4B 75 6E 67
#5D 7E 00 00 00 00 00 00    00 00 B7 B4 CA CD BA 00
#00 00 00 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00
	} elsif ($switch eq "015C") {
		($name) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		($cause) = substr($msg, 26, 40) =~ /([\s\S]*?)\000/;
		($id) = substr($msg, 66, 24) =~ /([\s\S]*?)\000/;
		ChatWrapper("", "Guild Member Delete: $id : $name : $cause", "g");
#5C 01 E0 C1 A8 BC D9 E9    E0 B4 D5 C2 C7 00 61 00
#74 7E 00 2A 2A 00 00 00    00 00 C5 BA B5 D1 C7 C5
#D0 A4 C3 E4 BB E1 C5 E9    C7 20 CA D2 C7 E6 20 C5
#BA E4 B4 E9 E4 A7 00 00    00 00 00 00 00 00 00 00
#00 00 66 6F 6F 6F 6E 67    6F 32 30 30 33 00 00 00
#00 00 00 00 00 00 01 00    00 00
	} elsif ($switch eq "0160") {
		for($i = 4; $i < $msg_size; $i += 16) {
			$index = unpack("L1", substr($msg, $i, 4));
			for ($j = 0; $j < $chars[$config{'char'}]{'guild'}{'total_member'}; $j++) {
				if ($chars[$config{'char'}]{'guild'}{'member'}[$j]{'pos_index'} == $index) {
					$chars[$config{'char'}]{'guild'}{'member'}[$j]{'support'} = unpack("L1", substr($msg, $i + 12, 4));

					OnYou($EV_GUILD_MEMBER_UPDATED, $j);
					last;
				}
			}
		}
#60 01 44 01
#00 00 00 00 11 00 00 00    00 00 00 00 01 00 00 00
#01 00 00 00 11 00 00 00    01 00 00 00 01 00 00 00
#02 00 00 00 11 00 00 00    02 00 00 00 00 00 00 00
#03 00 00 00 11 00 00 00    03 00 00 00 00 00 00 00
#04 00 00 00 11 00 00 00    04 00 00 00 00 00 00 00
#05 00 00 00 00 00 00 00    05 00 00 00 01 00 00 00
#06 00 00 00 11 00 00 00    06 00 00 00 00 00 00 00
#07 00 00 00 11 00 00 00    07 00 00 00 00 00 00 00
#08 00 00 00 11 00 00 00    08 00 00 00 01 00 00 00
#09 00 00 00 01 00 00 00    09 00 00 00 01 00 00 00
#0A 00 00 00 11 00 00 00    0A 00 00 00 01 00 00 00
#0B 00 00 00 01 00 00 00    0B 00 00 00 00 00 00 00
#0C 00 00 00 00 00 00 00    0C 00 00 00 00 00 00 00
#0D 00 00 00 00 00 00 00    0D 00 00 00 00 00 00 00
#0E 00 00 00 00 00 00 00    0E 00 00 00 00 00 00 00
#0F 00 00 00 00 00 00 00    0F 00 00 00 00 00 00 00
#10 00 00 00 00 00 00 00    10 00 00 00 00 00 00 00
#11 00 00 00 00 00 00 00    11 00 00 00 00 00 00 00
#12 00 00 00 00 00 00 00    12 00 00 00 00 00 00 00
#13 00 00 00 00 00 00 00    13 00 00 00 00 00 00 00
	} elsif ($switch eq "0162") {
		for($i = 6; $i < $msg_size; $i += 37) {
			($nameID) = substr($msg, $i + 12, 24) =~ /([\s\S]*?)\000/;

			$chars[$config{'char'}]{'guild'}{'skills'}{$nameID}{'ID'} = unpack("S1",substr($msg, $i, 2));
			$chars[$config{'char'}]{'guild'}{'skills'}{$nameID}{'lv'} = unpack("S1",substr($msg, $i + 6, 2));

			#print "$ID $nameID LV.$lv ($type)\n";
		}
#62 01 BF 00 00 00 10 27    00 00 00 00 01 00 00 00
#00 00 47 44 5F 41 50 50    52 4F 56 41 4C 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 11 27 00 00 00
#00 00 00 00 00 00 00 47    44 5F 4B 41 46 52 41 43
#4F 4E 54 52 41 43 54 00    00 00 00 00 00 00 00 01
#12 27 00 00 00 00 00 00    00 00 00 00 47 44 5F 47
#55 41 52 44 52 45 53 45    41 52 43 48 00 00 00 00
#00 00 00 00 01 13 27 00    00 00 00 00 00 00 00 00
#00 47 44 5F 43 48 41 52    49 53 4D 41 00 41 52 43
#48 00 00 00 00 00 00 00    00 00 14 27 00 00 00 00
#00 00 00 00 00 00 47 44    5F 45 58 54 45 4E 53 49
#4F 4E 00 00 00 00 00 00    00 00 00 00 00 00 01
	} elsif ($switch eq "0163") {
		for($i = 4; $i < $msg_size; $i += 88) {
			($name) = substr($msg, $i, 24) =~ /([\s\S]*?)\000/;
			$id = substr($msg, $i + 24, 24) =~ /([\s\S]*?)\000/;
			($cause) = substr($msg, $i + 48, 44) =~ /([\s\S]*?)\000/;
			$chars[$config{'char'}]{'guild'}{'leave'}{$id}{'name'} = $name;
			$chars[$config{'char'}]{'guild'}{'leave'}{$id}{'cause'} = $cause;
			print "Guild Leave: $name ($id): $cause\n" if $config{'debug'};
		}
#63 01 5C 00 2A 2A 2F 2F    6D 69 6B 69 2F 2F 2A 2A
#00 00 00 00 00 00 00 00    00 00 00 00 72 65 64 61
#70 70 6C 65 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 A8 D2 E4 C5    E8 CD CD A1 A7 D0 00 00
#00 00 00 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 00
	} elsif ($switch eq "0166") {
		for($i = 4; $i < $msg_size; $i += 28) {
			$index = unpack("L1", substr($msg, $i, 4));
			($chars[$config{'char'}]{'guild'}{'title'}[$index]{'name'}) = substr($msg, $i + 4, 24) =~ /([\s\S]*?)\000/;

			for ($j = 0; $j < $chars[$config{'char'}]{'guild'}{'total_member'}; $j++) {
				if ($chars[$config{'char'}]{'guild'}{'member'}[$j]{'pos_index'} eq $index) {
					OnYou($EV_GUILD_MEMBER_UPDATED, $j);
					last;
				}
			}
			print "Guild Title: $chars[$config{'char'}]{'guild'}{'title'}[$index]{'name'} ($index)\n" if $config{'debug'};
		}
#66 01 34 02 00 00 00 00    54 68 65 20 4D 61 53 54
#65 52 00 00 00 00 00 00    00 00 00 00 00 00 00 00
#01 00 00 00 58 5D CB B9    E8 C7 C2 C3 BA BD D8 A7
#BA D4 B9 B5 E8 D3 5B 58    00 00 00 00 02 00 00 00
#E0 B4 E7 A1 B4 D5 B7 D5    E8 E0 CA D5 C2 A4 B9 E1
#C5 E9 C7 00 00 00 00 00    03 00 00 00 C7 D4 AB D2
#B4 B9 E9 D3 E1 A2 E7 A7    E3 CA 20 C7 D1 C2 CA D0
#CD CD B9 00 04 00 00 00    A2 CD CE D5 C5 BA CD A1
#B9 D0 A4 D0 00 00 00 00    00 00 00 00 00 00 00 00
#05 00 00 00 C3 D1 A1 B7    D8 A1 A4 B9 E0 C5 C2 B7
#D3 E4 A7 B4 D5 A4 D0 00    00 00 00 00 06 00 00 00
#CD D4 EA A1 A4 D4 C7 20    E4 CD E9 E2 C5 E9 B9 C1
#CB D2 BB D0 C5 D1 C2 00    07 00 00 00 E0 C1 A8 B9
#E9 CD C2 A1 C5 CD C2 E3    A8 00 00 00 00 00 00 00
#00 00 00 00 08 00 00 00    E0 B4 C7 A4 D4 B4 C1 D2
#E3 CB E9 00 00 00 00 00    00 00 00 00 00 00 00 00
#09 00 00 00 CE D1 B9 E0    B5 CD C3 EC E3 B9 B5 D3
#B9 D2 B9 20 28 E4 C1 E8    BE CD 29 00 0A 00 00 00
#E1 A8 C1 E4 B4 E9 E0 C5    C2 E0 B4 C7 E0 CD D2 A4
#D7 B9 00 00 00 00 00 00    0B 00 00 00 C3 D1 A1 A4
#D8 B3 A4 B9 E0 B4 C7 B5    CD B9 B9 D5 E9 00 00 00
#00 00 00 00 0C 00 00 00    50 6F 73 69 74 69 6F 6E
#20 31 33 00 00 00 00 00    00 00 00 00 00 00 00 00
#0D 00 00 00 50 6F 73 69    74 69 6F 6E 20 31 34 00
#00 00 00 00 00 00 00 00    00 00 00 00 0E 00 00 00
#50 6F 73 69 74 69 6F 6E    20 31 35 00 00 00 00 00
#00 00 00 00 00 00 00 00    0F 00 00 00 50 6F 73 69
#74 69 6F 6E 20 31 36 00    00 00 00 00 00 00 00 00
#00 00 00 00 10 00 00 00    50 6F 73 69 74 69 6F 6E
#20 31 37 00 00 00 00 00    00 00 00 00 00 00 00 00
#11 00 00 00 50 6F 73 69    74 69 6F 6E 20 31 38 00
#00 00 00 00 00 00 00 00    00 00 00 00 12 00 00 00
#50 6F 73 69 74 69 6F 6E    20 31 39 00 00 00 00 00
#00 00 00 00 00 00 00 00    13 00 00 00 50 6F 73 69
#74 69 6F 6E 20 32 30 00    00 00 00 00 00 00 00 00
#00 00 00 00
	} elsif ($switch eq "0169") {
		$type = unpack("C1", substr($msg, 2, 1));

		if (%incomingGuild) {
			$name = "You";
		} else {
			$name = "Player";
		}

		if ($type == 1) {
			print "$name do not accept guild.\n";
		} elsif ($type == 2) {
			print "$name accept guild.\n";
		} else {
			print "0169, TYPE: $type\n";
		}

		undef %incomingGuild;
	} elsif ($switch eq "016A") {
#6A 01 A1 2F 00 00 95 68    6F 6C 79 64 72 61 67 6F
#6E 95 00 00 F0 25 37 0D    51 29 00 00 90 E6
		$ID = substr($msg, 2, 4);
		($guild) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;

		$incomingGuild{'ID'} = $ID;
		$incomingGuild{'name'} = $guild;

		OnYou($EV_GUILD_JOIN_REQUEST);

		$timeout{'ai_guildAutoDeny'}{'time'} = time;
	} elsif ($switch eq "016C") {
#6C 01 9F 2B 00 00 01 00    00 00 11 00 00 00 01 01
#00 00 00 7E 47 2E 4F 2E    44 7E 00 6C 75 65 2D 53
#74 72 65 61 6B 5F 5D 5D    00 00 00
		$chars[$config{'char'}]{'guild'}{'ID'} = substr($msg, 2, 4);
		($chars[$config{'char'}]{'guild'}{'name'}) = substr($msg, 19, 24) =~ /([\s\S]*?)\000/;
	} elsif ($switch eq "016D") {
		$memberOnline{'ID'} = substr($msg, 2, 4);
		$memberOnline{'charID'} = substr($msg, 6, 4);
		$memberOnline{'online'} = unpack("L1", substr($msg, 10, 4));

		sendCharacterNameRequest(\$remote_socket, $memberOnline{'charID'});
	} elsif ($switch eq "016F") {
		($subject) = substr($msg, 2, 60) =~ /([\s\S]*?)\000/;
		($message) = substr($msg, 62, 120) =~ /([\s\S]*?)\000/;
		$chars[$config{'char'}]{'guild'}{'notice_subject'} = $subject;
		$chars[$config{'char'}]{'guild'}{'notice_message'} = $message;
		ChatWrapper($subject, $message, "guild");
	} elsif ($switch eq "0171") {
		$ID = substr($msg, 2, 4);
		($guild) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;

		$incomingAllyGuild{'ID'} = $ID;
		$incomingAllyGuild{'name'} = $guild;

		OnYou($EV_GUILD_ALLY_REQUEST);

		print Name($ID)." request $guild to be ally.\n";
#71 01 7C C4 0A 00 7E 47    2E 4F 2E 44 7E 00 5D 6E
#6C 69 6E 65 00 45 5D 60    EF 60 7E 00 7E 00
	} elsif ($switch eq "0173") {
		$type = unpack("C1", substr($msg, 2, 1));

		if (%incomingAllyGuild) {
			$name = "You";
		} else {
			$name = "Player";
		}

		if ($type == 1) {
			print "$name do not accept ally.\n";
		} elsif ($type == 2) {
			print "$name accept ally.\n";
		} elsif ($type == 3) {
			print "$name have a lot allies.\n";
		} else {
			print "0173, TYPE: $type\n";
		}

		undef %incomingAllyGuild;
	} elsif ($switch eq "0174") {
		for($i = 4; $i < $msg_size; $i += 40) {
			$index = unpack("L1", substr($msg, $i, 4));
			($chars[$config{'char'}]{'guild'}{'title'}[$index]{'name'}) = substr($msg, $i + 16, 24) =~ /([\s\S]*?)\000/;

			for ($j = 0; $j < $chars[$config{'char'}]{'guild'}{'total_member'}; $j++) {
				if ($chars[$config{'char'}]{'guild'}{'member'}[$j]{'pos_index'} eq $index) {
					OnYou($EV_GUILD_MEMBER_UPDATED, $j);
					last;
				}
			}
			print "Guild Title: $chars[$config{'char'}]{'guild'}{'title'}[$index]{'name'} ($index)\n" if $config{'debug'};
		}

#74 01 2C 00 0F 00 00 00    01 00 00 00 0F 00 00 00
#00 00 00 00 E3 A4 C3 CB    C7 E8 D2 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 00
	} elsif ($switch eq "0177") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef @identifyID;
		undef $invIndex;
		for ($i = 4; $i < $msg_size; $i += 2) {
			$index = unpack("S1", substr($msg, $i, 2));
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			binAdd(\@identifyID, $invIndex);
		}

		print "Recieved Possible Identify List - type 'identify'\n";

		OnYou($EV_IDENTIFY);
	} elsif ($switch eq "0179") {
		$index = unpack("S*",substr($msg, 2, 2));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		if ($invIndex ne "") {
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = 1;
			OnYou($EV_ITEM_IDENTIFY, $invIndex);
			OnYou($EV_INVENTORY_UPDATED, $invIndex);
			print "Item Identified: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}\n" if $config{'debug'};
		}
		undef @identifyID;
	} elsif ($switch eq "017B") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef @cardMergeItemsID;
		undef $invIndex;
		for ($i = 4; $i < $msg_size; $i += 2) {
			$index = unpack("S1", substr($msg, $i, 2));
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			binAdd(\@cardMergeItemsID, $invIndex);
		}
		print "Recieved Possible Items List - type 'card mergelist'\n";
# 7B 01 08 00 10 00 11 00
	} elsif ($switch eq "017D") {
		$item_index = unpack("S1", substr($msg, 2, 2));
		$card_index = unpack("S1", substr($msg, 4, 2));
		$type = unpack("C1", substr($msg, 6, 1));

		undef @cardMergeItemsID;
		undef $cardMergeIndex;
# 7D 01 10 00 39 00 00
	} elsif ($switch eq "017F") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		$ID = substr($msg, 4, 4);
		$chat = substr($msg, 4, $msg_size - 4);
		($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
		chatLog("g", $chat."\n");

		if ($chatMsg eq "") {
			ChatWrapper("", $chat, "g");
		} else {
			ChatWrapper($chatMsgUser, $chatMsg, "g");
			OnChat("", $chatMsgUser, $chatMsg, "g");
		}
	} elsif ($switch eq "0180") {
	} elsif ($switch eq "0181") {
		$type = unpack("C1", substr($msg, 2, 1));
		if ($type == 1) {
			print "You have more allies.\n";
		} elsif ($type == 2) {
			print "This guild is already in list.\n";
		} else {
			print "0181, TYPE: $type\n";
		}
	} elsif ($switch eq "0182") {
		$index = unpack("L1", substr($msg, 28, 4));
		$chars[$config{'char'}]{'guild'}{'member'}[$index]{'ID'} = substr($msg, 2, 4);
		$chars[$config{'char'}]{'guild'}{'member'}[$index]{'charID'} = substr($msg, 6, 4);
		$chars[$config{'char'}]{'guild'}{'member'}[$index]{'jobID'} = unpack("S1", substr($msg, 16, 2));
		$chars[$config{'char'}]{'guild'}{'member'}[$index]{'level'} = unpack("S1", substr($msg, 18, 2));
		$chars[$config{'char'}]{'guild'}{'member'}[$index]{'exp'} = unpack("L1", substr($msg, 20, 4));
		$chars[$config{'char'}]{'guild'}{'member'}[$index]{'online'} = unpack("C1", substr($msg, 24, 1));
		($chars[$config{'char'}]{'guild'}{'member'}[$index]{'name'}) = substr($msg, 82, 24) =~ /([\s\S]*?)\000/;

		OnYou($EV_GUILD_MEMBER_ADDED, $index);
#82 01
#72 99 06 00 90 24 14 00    01 00 02 00 00 00 06 00
#36 00 00 00 00 00 01 00    00 00 13 00 00 00 00 00
#00 00 01 00 00 00 00 00    00 00 00 00 00 00 18 FC
#00 00 00 00 00 00 00 00    C8 02 00 00 95 E0 13 00
#13 00 00 00 00 00 00 00    00 00 02 00 00 00 00 00
#7E 5B 50 5D 6C 65 3A 2B    3A 5B 4B 75 6E 67 5D 7E
#00 00 00 00 00 00 00 00
	} elsif ($switch eq "0183") {
	} elsif ($switch eq "0184") {
		$ID = substr($msg, 2, 4);
		$type = unpack("L1", substr($msg, 6, 4));
		if ($type == 0) {
			for ($i = 0; $i < @{$chars[$config{'char'}]{'guild'}{'allies'}}; $i++) {
				if ($chars[$config{'char'}]{'guild'}{'allies'}[$i]{'ID'} eq $ID) {
					OnYou($EV_GUILD_ALLIES_REMOVED, $i);

					print "$chars[$config{'char'}]{'guild'}{'allies'}[$i]{'name'} is not an ally.\n";
					splice(@{$chars[$config{'char'}]{'guild'}{'allies'}}, $i, 1);
					last;
				}
			}
		} elsif ($type == 1) {
			for ($i = 0; $i < @{$chars[$config{'char'}]{'guild'}{'enemy'}}; $i++) {
				if ($chars[$config{'char'}]{'guild'}{'enemy'}[$i]{'ID'} eq $ID) {
					OnYou($EV_GUILD_ENEMY_REMOVED, $i);

					print "$chars[$config{'char'}]{'guild'}{'enemy'}[$i]{'name'} is not an enemy.\n";
					splice(@{$chars[$config{'char'}]{'guild'}{'enemy'}}, $i, 1);
					last;
				}
			}
		} else {
			print "0184, TYPE: $type, ID: ".getHex($ID)."\n";
		}
	} elsif ($switch eq "0185") {
		$type = unpack("L1", substr($msg, 2, 4));
		$ID = substr($msg, 6, 4);
		($guild) = substr($msg, 10, 24) =~ /([\s\S]*?)\000/;

		if ($type == 0) {
			$i = @{$chars[$config{'char'}]{'guild'}{'allies'}};
			$chars[$config{'char'}]{'guild'}{'allies'}[$i]{'ID'} = $ID;
			$chars[$config{'char'}]{'guild'}{'allies'}[$i]{'name'} = $guild;

			OnYou($EV_GUILD_ALLIES_ADDED, $i);
			print "$guild is an ally.\n";
		} elsif ($type == 1) {
			$i = @{$chars[$config{'char'}]{'guild'}{'enemy'}};
			$chars[$config{'char'}]{'guild'}{'enemy'}[$i]{'ID'} = $ID;
			$chars[$config{'char'}]{'guild'}{'enemy'}[$i]{'name'} = $guild;

			OnYou($EV_GUILD_ENEMY_ADDED, $i);
			print "$guild is an enemy.\n";
		} else {
			print "0185, TYPE: $type, ID: ".getHex($ID)."GUILD: $guild\n";
		}
	} elsif ($switch eq "0187") {
		$ID = substr($msg, 2, 4);
		#print "0187, ".Name($ID)."\n";
	} elsif ($switch eq "0189") {
		$chars[$config{'char'}]{'last_skill_failed'} = 1;
		OnYou($EV_SKILL_FAILED, $chars[$config{'char'}]{'last_skill_send'});
		PrintMessage(GetSkillName($chars[$config{'char'}]{'last_skill_send'})." is failed.", "red");
	} elsif ($switch eq "018B") {
		if ($reconnect) {
			PrintMessage("The server is disconnected. Try to reconnect...\n", "lightblue");

			$timeout_ex{'master'}{'time'} = time;
			$timeout_ex{'master'}{'timeout'} = $reconnect;
			killConnection(\$remote_socket);

			undef $reconnect;

			PrintMessage("\nWaiting $timeout_ex{'master'}{'timeout'} seconds...", "white");
			$last_count_master = 0;
		} else {
			PrintMessage("The server is disconnected. Exiting...\n", "lightblue");
			$quit = 1;
		}
	} elsif ($switch eq "018C") {
		$nameID = unpack("S1", substr($msg, 2, 2));
		$level = unpack("S1", substr($msg, 4, 2));
		$size = unpack("S1", substr($msg, 6, 2));
		$hp = unpack("L1", substr($msg, 8, 4));
		$def = unpack("S1", substr($msg, 12, 2));
		$element = unpack("S1", substr($msg, 14, 2));
		$mdef = unpack("S1", substr($msg, 16, 2));
		$element_def = unpack("S1", substr($msg, 18, 2));
		$e_ice = unpack("C1", substr($msg, 20, 1));
		$e_earth = unpack("C1", substr($msg, 21, 1));
		$e_fire = unpack("C1", substr($msg, 22, 1));
		$e_wind = unpack("C1", substr($msg, 23, 1));
		$e_poison = unpack("C1", substr($msg, 24, 1));
		$e_holy = unpack("C1", substr($msg, 25, 1));
		$e_dark = unpack("C1", substr($msg, 26, 1));
		$e_spirit = unpack("C1", substr($msg, 27, 1));
		$e_undead = unpack("C1", substr($msg, 28, 1));

#8C 01 1A 04 04 00 00 00    53 00 00 00 03 00 02 00
#0B 00 17 00 96 32 19 64    64 64 64 64 64

#8C 01 59 04 03 00 01 00    37 00 00 00 03 00 03 00
#01 00 17 00 96 32 19 64    64 64 64 64 64
	} elsif ($switch eq "018D") {
		if ($msg_size <= 4) {
			print "No mixture items.\n";
		} else {
			undef @mixtureID;
			for ($i = 4; $i < $msg_size; $i += 8) {
				$ID = unpack("S1", substr($msg, $i, 2));
				binAdd(\@mixtureID, $ID);
			}
			print "Recieved Mixture List - type 'mix'\n";
		}

		OnYou($EV_MIXTURE);
#8D 01 0C 00 E6 03 FC 77   38 08 CE 00

#8D 01 14 00 E6 03 FC 77    38 08 CE 00 E7 03 FC 77
#38 08 CE 00
	} elsif ($switch eq "018F") {
		$fail = unpack("S1", substr($msg, 2, 2));
		$type = unpack("S1",substr($msg, 4, 2));

		$name = ($items_lut{$type} ne "") ? $items_lut{$type} : "Unknown ".$type;
		if (!$fail) {
			PrintMessage("Mixture $name is success.", "white");
		} else {
			PrintMessage("Mixture $name is failed.", "red");
		}

		undef @mixtureID;
#8F 01 00 00 E6 03
	} elsif ($switch eq "0191") {
		$ID = substr($msg, 2, 4);
#91 01 92 92 00 00 C3 D1    BA CA C1 D1 A4 C3 AA D2
#C2 CB B9 D8 E8 C1 A8 EA    D2 20 00 00 00 00 C3 00
#00 00 00 00 30 00 00 00    14 00 00 00 1F 00 00 00
#84 F5 DC 06 14 00 00 00    84 F5 DC 06 5B 2B 78 73
#28 FB 12 00 80 0A 5C 00    28 A4 5E 00 FF FF FF FF
#34 FB 12 00 67 2B
	} elsif ($switch eq "0192") {
#92 01 C5 00 55 00 00 00    6D 6F 72 6F 63 63 2E 67
#61 74 00 00 00 00 00 00
	} elsif ($switch eq "0194") {
		$ID = substr($msg, 2, 4);
		if ($ID eq $whois{'ID'} && $whois{'request'}) {
			($whois{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			ChatWrapper("Whois ".unpack("L1", $whois{'ID'}), $whois{'name'}, "lightblue");
			undef $whois{'request'};
		} elsif ($ID eq $memberOnline{'charID'}) {
			($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;

			if ($memberOnline{'online'}) {
				ChatWrapper("", "Guild member $name log in.", "g");
			} else {
				ChatWrapper("", "Guild member $name log out.", "g");
			}

			if (%{$chars[$config{'char'}]{'guild'}}) {
				for ($i = 0; $i < $chars[$config{'char'}]{'guild'}{'total_member'}; $i++) {
					if ($chars[$config{'char'}]{'guild'}{'member'}[$i]{'name'} eq $name) {
						$chars[$config{'char'}]{'guild'}{'member'}[$i]{'online'} = $memberOnline{'online'};

						OnYou($EV_GUILD_MEMBER_UPDATED, $i);
						last;
					}
				}
			}
		}
	} elsif ($switch eq "0195") {
		$ID = substr($msg, 2, 4);
		if (%{$players{$ID}}) {
			($players{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			($players{$ID}{'party'}{'name'}) = substr($msg, 30, 24) =~ /([\s\S]*?)\000/;
			($players{$ID}{'guild'}{'name'}) = substr($msg, 54, 24) =~ /([\s\S]*?)\000/;
			($players{$ID}{'guild'}{'title'}) = substr($msg, 78, 24) =~ /([\s\S]*?)\000/;
			print "Player Info: $players{$ID}{'name'} ($players{$ID}{'binID'})\n" if ($config{'debug'} >= 2);

			OnPlayer($ID, $EV_GET_INFO);
		}
#95 01 7C C4 0A 00 4D 69    6E 74 20 28 57 69 7A 61
#72 64 29 00 CE 00 A4 6A    51 00 38 01 00 00 95 E4
#C1 E8 E4 B7 C3 EC A1 E9    CD E2 BB C3 95 00 6E 00
#74 00 65 00 72 00 7E 47    2E 4F 2E 44 7E 00 E0 B4
#E7 A1 E0 A1 E8 A7 A4 C3    D1 BA 5D 7E 00 00 4D 61
#53 54 65 52 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00
	} elsif ($switch eq "0196") {
		$effectID = unpack("S1",substr($msg, 2, 2));
		$ID = substr($msg, 4, 4);
		$val = unpack("C1",substr($msg, 8, 1));

		if (%{$players{$ID}}) {
			$players{$ID}{'effect'}{$effectID} = $val;

			#PrintMessage("$players{$ID}{'name'} - $effects_lut{$effectID}{'name'} ($effectID) is on.", "green");
			OnPlayer($ID, $EV_EFFECT, $effectID, $val);
		} elsif ($accountID eq $ID) {
			$chars[$config{'char'}]{'effect'}{$effectID} = $val;

			if (%{$effects_lut{$effectID}}) {
				if ($val) {
					PrintMessage("$effects_lut{$effectID}{'name'} is on.", "green");
				} else {
					PrintMessage("$effects_lut{$effectID}{'name'} is off.", "green");
				}
			} else {
				if ($val) {
					PrintMessage("Unknown effect ($effectID) is on.", "green");
				} else {
					PrintMessage("Unknown effect ($effectID) is off.", "green");
				}
			}

			OnYou($EV_EFFECT, $effectID, $val);
		}

		if (%{$effects_lut{$effectID}}) {
			DebugMessage("0196: EFFECT, $effects_lut{$effectID}{'name'}, VAL: $val") if ($debug{'msg0196'});
		} else {
			DebugMessage("0196: EFFECT, No: $effectID, VAL: $val") if ($debug{'msg0196'});
		}
	} elsif ($switch eq "0199") {
		$type = unpack("S1",substr($msg, 2, 2));
		if ($type == 1) {
			PrintMessage("You leave the PVP mode.", "dark");
		} else {
			print "0199: $type\n";
		}
	} elsif ($switch eq "019A") {
		$ID = substr($msg, 2, 4);
		$users = unpack("L1",substr($msg, 6, 4));
		$users_max = unpack("L1",substr($msg, 10, 4));
		#PrintMessage(Name($ID)." enter PVP [$users / $users_max]", "dark");
#9A 01 62 BD 19 00 09 00    00 00 0A 00 00 00
	} elsif ($switch eq "019B") {
		$ID = substr($msg, 2, 4);
		$type = unpack("L1",substr($msg, 6, 4));
		if (%{$players{$ID}}) {
			$name = $players{$ID}{'name'};
			if ($type == 0) {
				OnPlayer($ID, $EV_LEVEL_UP);
			} elsif ($type == 1) {
				OnPlayer($ID, $EV_JOB_LEVEL_UP);
			}
		} elsif ($ID == $accountID) {
			if ($type == 0) {
				OnYou($EV_LEVEL_UP);
			} elsif ($type == 1) {
				OnYou($EV_JOB_LEVEL_UP);
			}
		} else {
			$name = "Unknown";
		}

		if ($type == 0) {
			print "Player $name gained a level!\n" if ($config{'debug'});
		} elsif ($type == 1) {
			print "Player $name gained a job level!\n" if ($config{'debug'});
		}
	} elsif ($switch eq "019E") {
#3.0
#9E 01 A8 00 1A 00 00 00 01
#9E 01 A8 00 1B 00 00 00 01
#4.0
#PecoPeco
#9E 01 C8 01 1A 00 78 02    7C C4 0A 00 05 00 01
		$ID = substr($msg, 8, 4);
		$index = unpack("S1",substr($msg, 4, 2));
		$remain = unpack("C1",substr($msg, 12, 1));
		if ($ID eq $accountID) {
			undef $invIndex;
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			$amount = $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $remain;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = $remain;
			print "You used catch item: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex)\n" if $config{'debug'};

			OnYou($EV_ITEM_USED, $invIndex, $amount);
			OnYou($EV_INVENTORY_REMOVED, $invIndex, $amount);

			if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
				undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
			}

			OnYou($EV_PET_CATCH, $invIndex);
		}
	} elsif ($switch eq "01A0") {
		$success = unpack("C1",substr($msg, 2, 1));
		if ($success) {
			PrintMessage("You got a pet!", "green");
		} else {
			PrintMessage("Catch failed!", "red");
		}
	} elsif ($switch eq "01A2") {
		($chars[$config{'char'}]{'pet'}{'name'}) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		$chars[$config{'char'}]{'pet'}{'name_flag'} = unpack("C1",substr($msg, 26, 1));
		$chars[$config{'char'}]{'pet'}{'level'} = unpack("S1",substr($msg, 27, 2));
		$chars[$config{'char'}]{'pet'}{'hungry'} = unpack("S1",substr($msg, 29, 2));
		$chars[$config{'char'}]{'pet'}{'friendly'} = unpack("S1",substr($msg, 31, 2));
		$chars[$config{'char'}]{'pet'}{'accessory'} = unpack("S1",substr($msg, 33, 2));
		$chars[$config{'char'}]{'pet'}{'accessory_name'} = ($items_lut{$chars[$config{'char'}]{'pet'}{'accessory'}} ne "") ? $items_lut{$chars[$config{'char'}]{'pet'}{'accessory'}} : "None";

		$chars[$config{'char'}]{'pet'}{'action'} = 0;

		OnYou($EV_PET_INFO);
#A2 01 50 65 63 6F 50 65    63 6F 00 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 0D 00 19 00 FA
#00 00 00
	} elsif ($switch eq "01A3") {
		$type = unpack("C1",substr($msg, 2, 1));
		$ID = unpack("S1", substr($msg, 3, 2));
		$name = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;

		if ($type) {
			PrintMessage("Your pet got a $name.", "green");
		} else {
			PrintMessage("Could not give a $name to your pet.", "red");
		}
	} elsif ($switch eq "01A4") {
		$type = unpack("C1",substr($msg, 2, 1));
		$ID = substr($msg, 3, 4);
		$val = unpack("L",substr($msg, 7, 4));
		# 0 Born
		# 1 Friendly
		# 2 Hungry 25 หิวเล็กน้อ?75 ปกติ 90 อิ่ม
		# 3 Accessory
		# 4 Action
		# 5 Spawn
		if (($type < 3 || $chars[$config{'char'}]{'pet'}{'ID'} eq $ID) && %{$pets{$ID}}) {
			binRemove(\@petsID, $ID);
			#undef %{$pets{$ID}};
			delete $pets{$ID};
		}

		if ($type == 0) {
			if ($chars[$config{'char'}]{'eggInvIndex'} ne "") {
				PrintMessage($chars[$config{'char'}]{'inventory'}[$chars[$config{'char'}]{'eggInvIndex'}]{'name'}." was born.", "green");

				$chars[$config{'char'}]{'inventory'}[$chars[$config{'char'}]{'eggInvIndex'}]{'special'} = 1;
				GenName($chars[$config{'char'}]{'inventory'}[$chars[$config{'char'}]{'eggInvIndex'}]);
				OnYou($EV_INVENTORY_UPDATED, $chars[$config{'char'}]{'eggInvIndex'});
				undef $chars[$config{'char'}]{'eggInvIndex'};

				if ($config{'petAutoKeep_autoFriendly'} > 0) {
					configModify("petAutoKeep_friendly_lower", 0);
				}
			}

			$chars[$config{'char'}]{'pet'}{'ID'} = $ID;

			OnYou($EV_PET_BORN);
		} elsif ($type == 1) {
			$chars[$config{'char'}]{'pet'}{'friendly'} = $val;
			OnYou($EV_PET_FRIENDLY, $val);
		} elsif ($type == 2) {
			$chars[$config{'char'}]{'pet'}{'hungry'} = $val;
			OnYou($EV_PET_HUNGRY, $val);
		} else {
			if ($chars[$config{'char'}]{'pet'}{'ID'} eq $ID) {
				if ($type == 3) {
					$chars[$config{'char'}]{'pet'}{'accessory'} = $val;
					OnYou($EV_PET_ACCESSORY, $val);
				} elsif ($type == 4) {
					$chars[$config{'char'}]{'pet'}{'action'} = $val;
					OnYou($EV_PET_ACTION, $val);
				} elsif ($type == 5) {
					OnYou($EV_PET_SPAWNED);
				}
			} else {
				if (!%{$pets{$ID}}) {
					$pets{$ID}{'appear_time'} = time;

					binAdd(\@petsID, $ID);

					if (%{$monsters{$ID}}) {
						%{$pets{$ID}} = %{$monsters{$ID}};
					} else {
						$pets{$ID}{'name'} = "Unknown";
					}

					$pets{$ID}{'name_given'} = "Unknown";
					$pets{$ID}{'binID'} = binFind(\@petsID, $ID);
				}

				if ($type == 3) {
					$pets{$ID}{'accessory'} = $val;
				} elsif ($type == 4) {
					$pets{$ID}{'action'} = $val;
				} elsif ($type == 5) {
					print "Pet Spawned: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});

					OnPet($ID, $EV_SPAWNED);
				}
			}
		}

		if (%{$monsters{$ID}}) {
			OnMonster($ID, $EV_REMOVED);
			binRemove(\@monstersID, $ID);
			#undef %{$monsters{$ID}};
			delete $monsters{$ID};
		}
	} elsif ($switch eq "01A6") {
		undef @eggID;
		undef $invIndex;
		for ($i = 4; $i < $msg_size; $i += 2) {
			$index = unpack("S1", substr($msg, $i, 2));
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			binAdd(\@eggID, $invIndex);
		}
		print "Recieved Eggs List - type 'egg'\n";

		OnYou($EV_EGG);
#A6 01 0E 00 06 00 22 00    34 00 35 00 36 00
	} elsif ($switch eq "01AA") {
		$ID = substr($msg, 2, 4);
		$talk = unpack("L",substr($msg, 6, 4));

		if ($talk < 34) {
			ChatWrapper("", Name($ID)." : $emotions_lut{$talk}{'name'}", "c");
		} else {
			ChatWrapper("", Name($ID)." : $talk", "c");
		}
#AA 01 20 91 00 00 EE DB 00 00
#AA 01 20 91 00 00 0F 00 00 00
	} elsif ($switch eq "01AB") {
		$ID = substr($msg, 2, 4);
		$type = unpack("S1",substr($msg, 6, 2));
		$counter = unpack("l1",substr($msg, 8, 4));
		$counter = -$counter;
		print "Player ".Name($ID)." is banned ($type). Counter: $counter minute(s)\n";
#AB 01 36 05 09 00 04 00    FE FF FF FF
	} elsif ($switch eq "01AC") {
		$ID = substr($msg, 2, 4);
		$time = unpack("L1",substr($msg, 2, 4));
		#print "01AC: LONG $time, NAME ".Name($ID)."\n";
#AC 01 D4 8C 00 00
	} elsif ($switch eq "01AD") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef @arrowCraftID;
		undef $invIndex;
		for ($i = 4; $i < $msg_size; $i += 2) {
			$ID = unpack("S1", substr($msg, $i, 2));
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", $ID);
			binAdd(\@arrowCraftID, $invIndex);
		}
		print "Recieved Possible Arrow Craft List - type 'craft'\n";

		OnYou($EV_ARROWCRAFT);
#AD 01 0A 00 9A 03 FD 03 13 04
	} elsif ($switch eq "01B0") {
		$ID = substr($msg, 2, 4);
		$fail = unpack("C1",substr($msg, 6, 1));
		$type = unpack("S1",substr($msg, 7, 2));

		if (%{$monsters{$ID}}) {
			$name = ($monsters_lut{$type}{'name'} ne "") ? $monsters_lut{$type}{'name'} : "Unknown ".$type;
			PrintMessage("$monsters{$ID}{'name'} [".getHex($ID)."] transform to $name.", "green");

			$monsters{$ID}{'nameID'} = $type;
			$monsters{$ID}{'name'} = $name;

			OnMonster($ID, $EV_TRANSFORMED);
		}
#B0 01 3B A2 00 00 00 EA 03 00 00
	} elsif ($switch eq "01B1") {
#B1 01 00 00 1C 02 00 00 73 00 01 00 00 00 00
	} elsif ($switch eq "01B3") {
		# NPC image
		$npc_image = substr($msg, 2, 64);
		$type = unpack("C1", substr($msg, 66, 1));

		($npc_image) = $npc_image =~ /(\S+)/;
		if ($type == 2) {
			print "Show NPC image: $npc_image\n";
		} elsif ($type == 255) {
			print "Hide NPC image: $npc_image\n";
		} else {
			print "NPC image: $npc_image ($type)\n";
		}

		OnNpc($ID, $EV_IMAGE, $type);
	} elsif ($switch eq "01B5") {
		$remain = unpack("L1", substr($msg, 2, 4));
		if (!$remain) {
			$remain = unpack("L1", substr($msg, 6, 4));
		}

		$account{'remain'} = $remain;
		$account{'remain'}{'days'} = int($remain / 1440);
		$remain = $remain % 1440;
		$account{'remain'}{'hours'} = int($remain / 60);
		$remain = $remain % 60;
		$account{'remain'}{'minutes'} = $remain;

		$remainText = "$account{'remain'}{'days'} days, $account{'remain'}{'hours'} hours and $account{'remain'}{'minutes'} minutes";
		PrintMessage("Your account was remain $remainText.", "white");

# 1 Day 4 Hour 43 Minute (1723)
#B5 01 BB 06 00 00 00 00    00 00 00 00 00 00 00 00 00 00 Daily
#B5 01 00 00 00 00 1A 07    00 00 00 00 00 00 00 00 00 00 Hourly

	} elsif ($switch eq "01B6") {
		$chars[$config{'char'}]{'guild'}{'ID'} = substr($msg, 2, 4);
		$chars[$config{'char'}]{'guild'}{'level'} = unpack("C1", substr($msg, 6, 1));
		$chars[$config{'char'}]{'guild'}{'online_member'} = unpack("C1", substr($msg, 10, 1));
		$chars[$config{'char'}]{'guild'}{'total_member'} = unpack("C1", substr($msg, 14, 1));
		$chars[$config{'char'}]{'guild'}{'avg_level'} = unpack("S1", substr($msg, 18, 2));
		$chars[$config{'char'}]{'guild'}{'exp'} = unpack("L1", substr($msg, 22, 4));
		$chars[$config{'char'}]{'guild'}{'exp_max'} = unpack("L1", substr($msg, 26, 4));
		($chars[$config{'char'}]{'guild'}{'name'}) = substr($msg, 46, 24) =~ /([\s\S]*?)\000/;
		($chars[$config{'char'}]{'guild'}{'master'}) = substr($msg, 70, 24) =~ /([\s\S]*?)\000/;

		OnYou($EV_GUILD_UPDATED);
#B6 01 9F 2B 00 00 01 00    00 00 02 00 00 00 10 00
#00 00 40 00 00 00 21 7E    0F 00 80 84 1E 00 00 00
#00 00 00 00 00 00 00 00    00 00 01 00 00 00 7E 47
#2E 4F 2E 44 7E 00 C3 E1    C5 D0 CD E2 A4 F0 00 4B
#5D 61 5B 52 5D 00 4D 69    6E 74 20 28 57 69 7A 61
#72 64 29 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00
	} elsif ($switch eq "01B9") {
		$ID = substr($msg, 2, 4);

		if ($ID eq $accountID) {
			$chars[$config{'char'}]{'last_skill_failed'} = 1;
			OnYou($EV_SKILL_FAILED, 0);

			PrintMessage("You failed to use skill.", "red");
		} elsif (%{$monsters{$ID}}) {
			OnMonster($ID, $EV_SKILL_FAILED, 0);

			if ($ID eq $monster{'id'}) {
				PrintMessage("<$monsters{$ID}{'name'}> failed to use skill.", "red");
			} else {
				PrintMessage("$monsters{$ID}{'name'} failed to use skill.", "red");
			}
		} elsif (%{$players{$ID}}) {
			OnPlayer($ID, $EV_SKILL_FAILED, 0);
		}

	} elsif ($switch eq "01C4") {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));
		$ID = unpack("S1", substr($msg, 8, 2));

		$invIndex = findIndex(\@{$storage{'inventory'}}, "index", $index);
		if ($invIndex eq "") {
			$invIndex = findIndex(\@{$storage{'inventory'}}, "nameID", "");
			$storage{'inventory'}[$invIndex]{'index'} = $index;
			$storage{'inventory'}[$invIndex]{'nameID'} = $ID;
			$storage{'inventory'}[$invIndex]{'amount'} = $amount;
			$storage{'inventory'}[$invIndex]{'identified'} = unpack("C1", substr($msg, 10, 1));
			$storage{'inventory'}[$invIndex]{'refine'} = unpack("C1", substr($msg, 12, 1));
			$storage{'inventory'}[$invIndex]{'cardID_1'} = unpack("S1", substr($msg, 13, 2));
			if ($storage{'inventory'}[$invIndex]{'cardID_1'} == 255) {
				$storage{'inventory'}[$invIndex]{'elementID'} = unpack("C1", substr($msg, 15, 1));
				$storage{'inventory'}[$invIndex]{'elementName'} = $elements_lut{$storage{'inventory'}[$invIndex]{'elementID'}};
				$storage{'inventory'}[$invIndex]{'strongID'} = unpack("C1", substr($msg, 16, 1));
				$storage{'inventory'}[$invIndex]{'strongName'} = $strongs_lut{$storage{'inventory'}[$invIndex]{'strongID'}};
			} else {
				$storage{'inventory'}[$invIndex]{'cardID_2'} = unpack("S1", substr($msg, 15, 2));
				$storage{'inventory'}[$invIndex]{'cardID_3'} = unpack("S1", substr($msg, 17, 2));
				$storage{'inventory'}[$invIndex]{'cardID_4'} = unpack("S1", substr($msg, 19, 2));
			}

			GenName($storage{'inventory'}[$invIndex]);
		} else {
			$storage{'inventory'}[$invIndex]{'amount'} += $amount;
		}
		print "Storage Item Added: $storage{'inventory'}[$invIndex]{'name'} ($index) x $amount\n" if $config{'debug'};
		OnYou($EV_STORAGE_ADDED, $invIndex);
	} elsif ($switch eq "01C8") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}

		$index = unpack("S1",substr($msg, 2, 2));
		$ID = unpack("S1", substr($msg, 4, 2));
		$sourceID = substr($msg, 6, 4);
		$amountleft = unpack("S1",substr($msg, 10, 2));
		$display = ($items_lut{$ID} ne "")
			? $items_lut{$ID}
			: "Unknown ".$ID;

		undef $invIndex;

		if ($sourceID eq $accountID) {
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			$amount = $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $amountleft;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $amount;

			print "You used Item: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amount\n" if ($config{'debug'});

			OnYou($EV_ITEM_USED, $invIndex, $amount);
			OnYou($EV_INVENTORY_REMOVED, $invIndex);

			if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
				undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
			}
		} elsif (%{$players{$sourceID}}) {
			print  "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) used $display\n" if ($config{'debug'});

			OnPlayer($sourceID, $EV_ITEM_USED, $ID);

			if ($ID == 601 || $ID == 602) {
				OnPlayer($sourceID, $EV_DISAPPEARED);

				%{$players_old{$sourceID}} = %{$players{$sourceID}};
				$players_old{$sourceID}{'disappeared'} = 1;
				$players_old{$sourceID}{'gone_time'} = time;

				binRemove(\@playersID, $sourceID);
				#undef %{$players{$sourceID}};
				delete $players{$sourceID};

				if (%{$venderLists{$sourceID}}) {
					OnPlayer($sourceID, $EV_SHOP_DISAPPEARED);
					binRemove(\@venderListsID, $sourceID);
					delete $venderLists{$sourceID};
				}
			}
		} elsif (%{$monsters{$sourceID}}) {
			print  "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) used $display\n" if ($config{'debug'});
			OnMonster($sourceID, $EV_ITEM_USED, $ID);
		#} else {
		#	print  Name($sourceID)." used $display\n";
		}
	} elsif ($switch eq "01C9") {
		#area effect spell
		$ID = substr($msg, 2, 4);
		$SourceID = substr($msg, 6, 4);
		$x = unpack("S1",substr($msg, 10, 2));
		$y = unpack("S1",substr($msg, 12, 2));
		$spells{$ID}{'sourceID'} = $SourceID;
		$spells{$ID}{'pos'}{'x'} = $x;
		$spells{$ID}{'pos'}{'y'} = $y;
		$binID = binAdd(\@spellsID, $ID);
		$spells{$ID}{'binID'} = $binID;

		$skillID = unpack("C1", substr($msg, 14, 1));
		$useskill = unpack("C1", substr($msg, 15, 1));
		$skill = GetSkillName($skillID);

		DebugMessage("01C9: AREA_AT, SOURCE: ".Name($SourceID).", SKILL: $skill, ($x, $y)") if ($debug{'msg011F'});

		if (%{$monsters{$SourceID}}) {
			OnMonster($SourceID, $EV_SKILL_AREA_AT, $skillID, $x, $y);
		} elsif (%{$players{$SourceID}}) {
			OnPlayer($SourceID, $EV_SKILL_AREA_AT, $skillID, $x, $y);
		} elsif ($SourceID eq $accountID) {
			OnYou($EV_SKILL_AREA_AT, $skillID, $x, $y);
		}

# Fire Wall 159, 144
#C9 01 74 03 00 00 7C C4    0A 00 9F 00 90 00 7F 01
#00 00 00 00 00 00 00 00    D0 C9 41 0D 7E 00 00 00
#4D C1 4E 00 7C F6 12 00    6C F6 12 00 5C F6 12 00
#BC 7B 57 77 C4 41 E1 2B    00 00 00 00 00 00 00 00
#00 00 00 00 29 78 48 00    3E 00 00 00 74 F6 12 00
#A0 4D BE 2C 74 4B 14 15    90 00 00 00 49 00 00 00
#BA
	} elsif ($switch eq "01D0") {
		$ID = substr($msg, 2, 4);
		$count = unpack("S1",substr($msg, 6, 2));
		if ($ID eq $accountID) {
			$chars[$config{'char'}]{'skills'}{'MO_CALLSPIRITS'}{'count'} = $count;
			PrintMessage("Vigor condensation [".$count."]", "pink");
		}
	} elsif ($switch eq "01D2") {
	} elsif ($switch eq "01D6") {
	} elsif ($switch eq "01D7") {
#D7 01 72 99 06 00 02 00 00 00 00
		$ID = substr($msg, 2, 4);
		$part = unpack("C1",substr($msg, 6, 1));
		$type = unpack("L1",substr($msg, 7, 4));
	} elsif ($switch eq "01D8") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}

		$ID = substr($msg, 2, 4);
		$critical = unpack("S*", substr($msg, 8, 2));
		$warning = unpack("S*", substr($msg, 10, 2));
		$option = unpack("S*", substr($msg, 12, 2));
		$type = unpack("S*",substr($msg, 14,  2));
		$pet = unpack("C*",substr($msg, 16,  1));
		$charlowheadID = $charHead_lut{unpack("S1",substr($msg, 22,  2))};
		$chartopheadID = $charHead_lut{unpack("S1",substr($msg, 24,  2))};
		$charmidheadID = $charHead_lut{unpack("S1",substr($msg, 26,  2))};
		$guildID = substr($msg, 34,  4);
		$sex = unpack("C*",substr($msg, 45,  1));
		makeCoords(\%coords, substr($msg, 46, 3));
		$act = unpack("C*",substr($msg, 51,  1));
		# 4.0
		$lv = unpack("S*",substr($msg, 52,  2));
		if ($type >= 1000) {
			if ($pet) {
				if (%{$chars[$config{'char'}]{'pet'}} && $chars[$config{'char'}]{'pet'}{'ID'} eq $ID) {
					if ($chars[$config{'char'}]{'pet'}{'type'} eq "") {
						$chars[$config{'char'}]{'pet'}{'nameID'} = $type;
						$chars[$config{'char'}]{'pet'}{'type'} = ($monsters_lut{$type}{'name'} ne "") ? $monsters_lut{$type}{'name'} : "Unknown ".$type;
					}

					%{$chars[$config{'char'}]{'pet'}{'pos'}} = %coords;
					%{$chars[$config{'char'}]{'pet'}{'pos_to'}} = %coords;
				} else {
					if (!%{$pets{$ID}}) {
						$pets{$ID}{'appear_time'} = time;
						$display = ($monsters_lut{$type}{'name'} ne "")
								? $monsters_lut{$type}{'name'}
								: "Unknown ".$type;
						binAdd(\@petsID, $ID);
						$pets{$ID}{'nameID'} = $type;
						$pets{$ID}{'name'} = $display;
						$pets{$ID}{'name_given'} = "Unknown";
						$pets{$ID}{'binID'} = binFind(\@petsID, $ID);
					} elsif ($pets{$ID}{'name'} eq "Unknown") {
						$display = ($monsters_lut{$type}{'name'} ne "")
								? $monsters_lut{$type}{'name'}
								: "Unknown ".$type;
						$pets{$ID}{'nameID'} = $type;
						$pets{$ID}{'name'} = $display;
					}
					%{$pets{$ID}{'pos'}} = %coords;
					%{$pets{$ID}{'pos_to'}} = %coords;
					print "Pet Exists: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});
				}

				OnPet($ID, $EV_EXISTS);

				if (%{$monsters{$ID}}) {
					OnMonster($ID, $EV_REMOVED);
					binRemove(\@monstersID, $ID);
					#undef %{$monsters{$ID}};
					delete $monsters{$ID};
				}
			} else {
				if (!%{$monsters{$ID}}) {
					$monsters{$ID}{'appear_time'} = time;
					$display = ($monsters_lut{$type}{'name'} ne "")
							? $monsters_lut{$type}{'name'}
							: "Unknown ".$type;
					binAdd(\@monstersID, $ID);
					$monsters{$ID}{'nameID'} = $type;
					$monsters{$ID}{'name'} = $display;
					$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
				}
				SetStatus($monsters{$ID}, $critical, $warning, $option);
				%{$monsters{$ID}{'pos'}} = %coords;
				%{$monsters{$ID}{'pos_to'}} = %coords;
				print "Monster Exists: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if ($config{'debug'});

				OnMonster($ID, $EV_EXISTS);
			}

		} elsif ($jobs_lut{$type}) {
			if (!%{$players{$ID}}) {
				$players{$ID}{'appear_time'} = time;
				binAdd(\@playersID, $ID);
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'name'} = "Unknown";
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);
			}
			$players{$ID}{'lv'} = $lv;
			$players{$ID}{'dead'} = ($act == 1);
			$players{$ID}{'sitting'} = ($act == 2);
			$players{$ID}{'look'}{'lowHead'} = $charlowheadID;
			$players{$ID}{'look'}{'topHead'} = $chartopheadID;
			$players{$ID}{'look'}{'midHead'} = $charmidheadID;
			SetStatus($players{$ID}, $critical, $warning, $option);
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
			print "Player Exists: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});

			OnPlayer($ID, $EV_EXISTS);
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
			print "Portal Exists: $portals{$ID}{'name'} - ($portals{$ID}{'binID'})\n" if $config{'debug'};
			OnYou($EV_PORTAL_EXISTS, $ID);
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
			print "NPC Exists: $npcs{$ID}{'name'} - ($npcs{$ID}{'binID'})\n" if $config{'debug'};

			OnNpc($ID, $EV_EXISTS);
		} else {
			PrintMessage("Unknown Exists: $type - ".unpack("L*",$ID), "red");
		}

#D8 01 7C C4 0A 00 96 00    00 00 00 00 00 00 09 00
#01 00 4A 06 36 08 38 00    12 00 0C 00 01 00 00 00
#00 00 9F 2B 00 00 01 00    00 00 31 75 00 01 23 44
#F0 05 05 00 4A 00
	} elsif ($switch eq "01D9") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		$ID = substr($msg, 2, 4);
		$critical = unpack("S*", substr($msg, 8, 2));
		$warning = unpack("S*", substr($msg, 10, 2));
		$option = unpack("S*", substr($msg, 12, 2));
		$type = unpack("S*",substr($msg, 14,  2));
		$charlowheadID = $charHead_lut{unpack("S1",substr($msg, 22,  2))};
		$chartopheadID = $charHead_lut{unpack("S1",substr($msg, 24,  2))};
		$charmidheadID = $charHead_lut{unpack("S1",substr($msg, 26,  2))};
		$guildID = substr($msg, 34,  4);
		$sex = unpack("C*",substr($msg, 45,  1));
		makeCoords(\%coords, substr($msg, 46, 3));
		# 4.0
		$lv = unpack("S*",substr($msg, 51,  2));
		if ($jobs_lut{$type}) {
			if (!%{$players{$ID}}) {
				$players{$ID}{'appear_time'} = time;
				binAdd(\@playersID, $ID);
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'name'} = "Unknown";
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);
			}
			$players{$ID}{'lv'} = $lv;
			$players{$ID}{'look'}{'lowHead'} = $charlowheadID;
			$players{$ID}{'look'}{'topHead'} = $chartopheadID;
			$players{$ID}{'look'}{'midHead'} = $charmidheadID;
			SetStatus($players{$ID}, $critical, $warning, $option);
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
			print "Player Connected: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});
			OnPlayer($ID, $EV_CONNECTED);
		} else {
			PrintMessage("Unknown Connected: $type - ".getHex($ID), "red");
		}

#D9 01 7C C4 0A 00 96 00    00 00 00 00 00 00 09 00
#01 00 4A 06 36 08 38 00    12 00 0C 00 01 00 00 00
#00 00 9F 2B 00 00 01 00    00 00 31 75 00 01 23 44
#F0 05 05 4A 00
	} elsif ($switch eq "01DA") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
		$ID = substr($msg, 2, 4);
		$critical = unpack("S*", substr($msg, 8, 2));
		$warning = unpack("S*", substr($msg, 10, 2));
		$option = unpack("S*", substr($msg, 12, 2));
		$type = unpack("S*",substr($msg, 14,  2));
		$pet = unpack("C*",substr($msg, 16,  1));
		$charlowheadID = $charHead_lut{unpack("S1",substr($msg, 22,  2))};
		$chartopheadID = $charHead_lut{unpack("S1",substr($msg, 28,  2))};
		$charmidheadID = $charHead_lut{unpack("S1",substr($msg, 30,  2))};
		$guildID = substr($msg, 38,  4);
		$sex = unpack("C*",substr($msg, 49,  1));
		makeCoords(\%coordsFrom, substr($msg, 50, 3));
		makeCoords2(\%coordsTo, substr($msg, 52, 3));
		# 4.0
		$lv = unpack("S*",substr($msg, 58,  2));
		if ($type >= 1000) {
			if ($pet) {
				if (%{$chars[$config{'char'}]{'pet'}} && $chars[$config{'char'}]{'pet'}{'ID'} eq $ID) {
					if ($chars[$config{'char'}]{'pet'}{'type'} eq "") {
						$chars[$config{'char'}]{'pet'}{'nameID'} = $type;
						$chars[$config{'char'}]{'pet'}{'type'} = ($monsters_lut{$type}{'name'} ne "") ? $monsters_lut{$type}{'name'} : "Unknown ".$type;
					}

					%{$chars[$config{'char'}]{'pet'}{'pos'}} = %coords;
					%{$chars[$config{'char'}]{'pet'}{'pos_to'}} = %coords;

					$action = $EV_MOVE;
				} else {
					if (!%{$pets{$ID}}) {
						$pets{$ID}{'appear_time'} = time;
						$display = ($monsters_lut{$type}{'name'} ne "")
								? $monsters_lut{$type}{'name'}
								: "Unknown ".$type;
						binAdd(\@petsID, $ID);
						$pets{$ID}{'nameID'} = $type;
						$pets{$ID}{'appear_time'} = time;
						$display = ($monsters_lut{$pets{$ID}{'nameID'}}{'name'} ne "")
						? $monsters_lut{$pets{$ID}{'nameID'}}{'name'}
						: "Unknown ".$pets{$ID}{'nameID'};
						$pets{$ID}{'name'} = $display;
						$pets{$ID}{'binID'} = binFind(\@petsID, $ID);
						print "Pet Appeared: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});
						$action = $EV_APPEARED;
					} elsif ($pets{$ID}{'name'} eq "Unknown") {
						$display = ($monsters_lut{$type}{'name'} ne "")
								? $monsters_lut{$type}{'name'}
								: "Unknown ".$type;
						$pets{$ID}{'nameID'} = $type;
						$pets{$ID}{'name'} = $display;
						$action = $EV_APPEARED;
					} else {
						$action = $EV_MOVE;
					}
					%{$pets{$ID}{'pos'}} = %coords;
					%{$pets{$ID}{'pos_to'}} = %coords;

					print "Pet Moved: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'} >= 2);
				}

				OnPet($ID, $action);

				if (%{$monsters{$ID}}) {
					OnMonster($ID, $EV_REMOVED);
					binRemove(\@monstersID, $ID);
					#undef %{$monsters{$ID}};
					delete $monsters{$ID};
				}
			} else {
				if (!%{$monsters{$ID}}) {
					binAdd(\@monstersID, $ID);
					$monsters{$ID}{'appear_time'} = time;
					$monsters{$ID}{'nameID'} = $type;
					$display = ($monsters_lut{$type}{'name'} ne "")
						? $monsters_lut{$type}{'name'}
						: "Unknown ".$type;
					$monsters{$ID}{'name'} = $display;
					$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
					print "Monster Appeared: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if $config{'debug'};
					$action = $EV_APPEARED;
				} else {
					$action = $EV_MOVE;
				}

				SetStatus($monsters{$ID}, $critical, $warning, $option);
				%{$monsters{$ID}{'pos'}} = %coordsFrom;
				%{$monsters{$ID}{'pos_to'}} = %coordsTo;
				print "Monster Moved: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if ($config{'debug'} >= 2);

				OnMonster($ID, $action);
			}
		} elsif ($jobs_lut{$type}) {
			if (!%{$players{$ID}}) {
				binAdd(\@playersID, $ID);
				$players{$ID}{'appear_time'} = time;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'name'} = "Unknown";
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);

				print "Player Appeared: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$sex} $jobs_lut{$type}\n" if $config{'debug'};
				$action = $EV_APPEARED;
			} else {
				$action = $EV_MOVE;
			}

			$players{$ID}{'lv'} = $lv;
			$players{$ID}{'look'}{'lowHead'} = $charlowheadID;
			$players{$ID}{'look'}{'topHead'} = $chartopheadID;
			$players{$ID}{'look'}{'midHead'} = $charmidheadID;
			SetStatus($players{$ID}, $critical, $warning, $option);
			%{$players{$ID}{'pos'}} = %coordsFrom;
			%{$players{$ID}{'pos_to'}} = %coordsTo;
			print "Player Moved: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'} >= 2);

			OnPlayer($ID, $action);
		} else {
			PrintMessage("Unknown Moved: $type - ".getHex($ID), "red");
		}

#DA 01 7C C4 0A 00 96 00    00 00 00 00 00 00 09 00
#01 00 4A 06 36 08 38 00    07 D6 77 45 12 00 0C 00
#01 00 00 00 00 00 9F 2B    00 00 01 00 00 00 31 75
#00 01 23 84 B2 34 4F 88    05 05 4A 00
	} elsif ($switch eq "01DC") {
		$msg1DC = substr($msg, 0, $msg_size);
	} elsif ($switch eq "01DE") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}

		$skillID = unpack("S1",substr($msg, 2, 2));
		$sourceID = substr($msg, 4, 4);
		$targetID = substr($msg, 8, 4);
		$damage = unpack("S1",substr($msg, 24, 2));
		$level = unpack("S1",substr($msg, 28, 2));
		$hit = unpack("S1",substr($msg, 30, 2));
		$skill = GetSkillName($skillID);

		if (%{$spells{$sourceID}}) {
			$sourceID = $spells{$sourceID}{'sourceID'}
		}

		updateDamageTables($sourceID, $targetID, $damage) if ($damage != 35536);
		if ($sourceID eq $accountID) {
			$chars[$config{'char'}]{'last_skill_used'} = $skillID;
			$chars[$config{'char'}]{'last_skill_target'} = $targetID;
			$chars[$config{'char'}]{'skills'}{$skillsID_lut{$skillID}{'nameID'}}{'time_used'} = time;
			undef $chars[$config{'char'}]{'last_skill_cast'};
			undef $chars[$config{'char'}]{'last_time_cast'};
		}

		if (%{$monsters{$targetID}}) {
			if ($sourceID eq $accountID) {
				$monsters{$targetID}{'castOnByYou'}++;
			} else {
				$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
			}
		}

		DebugMessage("01DE: DAMAGE_ON, SOURCE: ".Name($sourceID).", TARGET: ".Name($targetID).", SKILL: $skill, DAMAGE: $damage, LV: $level") if ($debug{'msg01DE'});

		if (%{$monsters{$sourceID}}) {
			if (%{$monsters{$targetID}}) {
				OnMonster($sourceID, $EV_SKILL_DAMAGE_ON_MONSTER, $targetID, $skillID, $damage, $level);
			} elsif (%{$players{$targetID}}) {
				OnMonster($sourceID, $EV_SKILL_DAMAGE_ON_PLAYER, $targetID, $skillID, $damage, $level);
			} elsif ($targetID eq $accountID) {
				OnMonster($sourceID, $EV_SKILL_DAMAGE_ON_YOU, $skillID, $damage, $level);
			} else {
				OnMonster($sourceID, $EV_SKILL_DAMAGE_ON, $targetID, $skillID, $damage, $level);
			}
		} elsif (%{$players{$sourceID}}) {
			if (%{$monsters{$targetID}}) {
				OnPlayer($sourceID, $EV_SKILL_DAMAGE_ON_MONSTER, $targetID, $skillID, $damage, $level);
			} elsif (%{$players{$targetID}}) {
				OnPlayer($sourceID, $EV_SKILL_DAMAGE_ON_PLAYER, $targetID, $skillID, $damage, $level);
			} elsif ($targetID eq $accountID) {
				OnPlayer($sourceID, $EV_SKILL_DAMAGE_ON_YOU, $skillID, $damage, $level);
			} else {
				OnPlayer($sourceID, $EV_SKILL_DAMAGE_ON, $targetID, $skillID, $damage, $level);
			}
		} elsif ($sourceID eq $accountID) {
			if (%{$monsters{$targetID}}) {
				OnYou($EV_SKILL_DAMAGE_ON_MONSTER, $targetID, $skillID, $damage, $level);
			} elsif (%{$players{$targetID}}) {
				OnYou($EV_SKILL_DAMAGE_ON_PLAYER, $targetID, $skillID, $damage, $level);
			} elsif ($targetID eq $accountID) {
				OnYou($EV_SKILL_DAMAGE_ON_YOU, $skillID, $damage, $level);
			} else {
				OnYou($EV_SKILL_DAMAGE_ON, $targetID, $skillID, $damage, $level);
			}
		}
#DE 01 5A 00 7C C4 0A 00    9E CD 00 00 6F 67 5F 2B
#45 02 00 00 10 02 00 00    F9 03 00 00 03 00 03 00
#08

#DE 01 2E 00 56 1F 21 00    46 D1 00 00 C1 E0 70 2C
#77 01 00 00 68 01 00 00    D8 0A 00 00 0A 00 02 00
#08
	} elsif ($switch eq "01E1") {
		$ID = substr($msg, 2, 4);
		$count = unpack("S1",substr($msg, 6, 2));
		if ($ID eq $accountID) {
			$chars[$config{'char'}]{'skills'}{'MO_CALLSPIRITS'}{'count'} = $count;
			PrintMessage("Vigor condensation [".$count."]", "pink");
		}
	} elsif ($switch eq "01EE") {
		if (!$config{'remoteSocket'}) {
			$conState = 5 if ($conState != 4);
		}
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
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = unpack("S1", substr($msg, $i + 6, 2));
			$display = ($items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}} ne "")
				? $items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}
				: "Unknown ".$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'};
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = $display;
			print "Inventory: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}}\n" if $config{'debug'};

			OnYou($EV_INVENTORY_UPDATED, $invIndex);
		}

		useTeleport($teleQueue) if $teleQueue;
#EE 01 36 01 11 00 CD 02    03 01 04 00 00 00 00 00
#00 00 00 00 00 00 12 00    90 02 02 01 01 00 00 00
#00 00 00 00 00 00 00 00
	} elsif ($switch eq "01EF") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		for($i = 4; $i < $msg_size; $i+=18) {
			# 02 00 C4 02 03 01 07 00 00 00
			# 03 00 C0 02 03 01 06 00 00 00
			# 03 00 6D 1B 03 01 03 00 00 00 00 00 00 00 00 00 00 00
			$index = unpack("S1", substr($msg, $i, 2));
			$ID = unpack("S1", substr($msg, $i+2, 2));
			$amount = unpack("S1", substr($msg, $i+6, 2));
			if (%{$cart{'inventory'}[$index]}) {
				$cart{'inventory'}[$index]{'amount'} += $amount;
			} else {
				$cart{'inventory'}[$index]{'nameID'} = $ID;
				$cart{'inventory'}[$index]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
				$cart{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
				$cart{'inventory'}[$index]{'amount'} = $amount;
				$display = ($items_lut{$ID} ne "")
					? $items_lut{$ID}
					: "Unknown ".$ID;
				$cart{'inventory'}[$index]{'name'} = $display;
			}

			OnYou($EV_CART_UPDATED, $index);
			print "Cart Item: $cart{'inventory'}[$index]{'name'} ($index) x $amount\n" if ($config{'debug'} >= 1);
		}
#EF 01 44 02 03 00 6D 1B    03 01 03 00 00 00 00 00
#00 00 00 00 00 00 0E 00    0D 02 00 01 05 00 00 00
#00 00 00 00 00 00 00 00
	} elsif ($switch eq "01F0") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;

		if (!$storage{'open'}) {
			PrintMessage("Storage Opened", "yellow");
			OnYou($EV_STORAGE_OPENED);
		}

		for($i = 4; $i < $msg_size; $i += 18) {
			$index = unpack("S1", substr($msg, $i, 2));

			$invIndex = findIndex(\@{$storage{'inventory'}}, "index", $index);
			if ($invIndex eq "") {
				$invIndex = findIndex(\@{$storage{'inventory'}}, "nameID", "");
			}

			$ID = unpack("S1", substr($msg, $i + 2, 2));
			$storage{'inventory'}[$invIndex]{'index'} = $index;
			$storage{'inventory'}[$invIndex]{'nameID'} = $ID;
			$storage{'inventory'}[$invIndex]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
			$storage{'inventory'}[$invIndex]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
			$storage{'inventory'}[$invIndex]{'amount'} = unpack("S1", substr($msg, $i + 6, 2));
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "Unknown ".$ID;
			$storage{'inventory'}[$invIndex]{'name'} = $display;
			print "Storage: $storage{'inventory'}[$invIndex]{'name'} ($index)\n" if $config{'debug'};

			OnYou($EV_STORAGE_UPDATED, $invIndex);
		}

		$storage{'open'} = 1;
#F0 01 26 05 02 00 63 02    02 01 68 00 00 00 00 00
#00 00 00 00 00 00 03 00    13 02 00 01 44 02 00 00
#00 00 00 00 00 00 00 00
	} elsif ($switch_no > 4096 && length($msg) >= 4) {
		$msg_size = length($msg);
		#print "$last_know_switch > $switch ($msg_size): unparsed packet.\n" if $config{'debug'};
		print "$last_know_switch > $switch ($msg_size): unparsed packet.\n";
	} else {
		#print "Unparsed packet - $switch\n" if $config{'debug'};
		print "Unparsed packet - $switch\n";
	}

	$msg = (length($msg) >= $msg_size) ? substr($msg, $msg_size, length($msg) - $msg_size) : "";

	Debug('MSG');

	return $msg;
}




#######################################
#######################################
#AI FUNCTIONS
#######################################
#######################################

sub ai_avoidGM {
	my $id = shift;
	my $name = shift;
	my $gm = shift;
	my %args;

	$ai_v{'temp'}{'ai_avoidGM_index'} = binFind(\@ai_seq, "avoidGM");
	if ($ai_v{'temp'}{'ai_avoidGM_index'} eq "") {
		$args{'id'} = $id;
		$args{'name'} = $name;
		$args{'gm'} = $gm;
		unshift @ai_seq, "avoidGM";
		unshift @ai_seq_args, \%args;

		DebugMessage("avoidGM(".getHex($id).", $name, $gm)") if ($debug{'ai_avoidGM'});
	}
}

sub ai_clientSuspend {
	my ($type,$initTimeout,@args) = @_;
	my %args;
	$args{'type'} = $type;
	$args{'time'} = time;
	$args{'timeout'} = $initTimeout;
	@{$args{'args'}} = @args;
	unshift @ai_seq, "clientSuspend";
	unshift @ai_seq_args, \%args;

	DebugMessage("ai_clientSuspend($type, $initTimeout)") if ($debug{'ai_clientSuspend'});
}

sub ai_follow {
	my $name = shift;
	my $stopWhenFound = shift;
	my %args;

	$args{'name'} = $name;
	$args{'stopWhenFound'} = $stopWhenFound;

	unshift @ai_seq, "follow";
	unshift @ai_seq_args, \%args;

	DebugMessage("ai_follow($name, $stopWhenFound)") if ($debug{'ai_follow'});
}

sub ai_respAuto {
	my $user = shift;
	my $cmd = shift;
	my $chattype = shift;
	my %args;

	$ai_v{'temp'}{'ai_reapAuto_index'} = binFind(\@ai_seq, "respAuto");
	if ($ai_v{'temp'}{'ai_reapAuto_index'} eq "" && $currentChatRoom eq "") {
		$args{'user'} = $user;
		$args{'cmd'} = $cmd;
		$args{'chattype'} = $chattype;
		$args{'wait'} = 0;
		unshift @ai_seq, "respAuto";
		unshift @ai_seq_args, \%args;

		DebugMessage("ai_respAuto($user, $cmd, $chattype)") if ($debug{'ai_respAuto'});
	}
}

sub ai_getAggressives {
	my @agMonsters;
	my $distance;
	foreach (@monstersID) {
		next if ($_ eq "");

		$distance = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
		if (($monsters{$_}{'dmgToYou'} > 0 || $monsters{$_}{'missedYou'} > 0) && $monsters{$_}{'attack_failed'} <= 1) {
			push @agMonsters, $_;
		} elsif ((($monsters_lut{$monsters{$_}{'nameID'}}{'agg'} == 1 && $distance < 6) || $monsters{$_}{'dmgFromYou'} > 0) &&
			!$monsters{$_}{'missedToPlayers'} &&
			#!$monsters{$_}{'missedFromPlayers'} &&
			!$monsters{$_}{'dmgToPlayers'} &&
			!$monsters{$_}{'dmgFromPlayers'} &&
			$distance < 9) {
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

sub ai_getID {
	my $r_hash = shift;
	my $name = shift;

	foreach (keys %{$r_hash}) {
		next if ($_ eq "");
		if ($name eq $$r_hash{$_}{'name'}) {
			return $_;
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

	DebugMessage("ai_items_take(($x1, $y1), ($x2, $y2))") if ($debug{'ai_itemsTake'});
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

	DebugMessage("ai_mapRoute_getRoute($args{'r_start_field'}{'name'}, ($args{'r_start_pos'}{'x'}, $args{'r_start_pos'}{'y'}), $args{'r_dest_field'}{'name'}, ($args{'r_dest_pos'}{'x'}, $args{'r_dest_pos'}{'y'}))") if ($debug{'ai_mapRoute_getRoute'});
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

	DebugMessage("ai_mapRoute_getSuccessors($r_args, $r_array, $r_cur)") if ($debug{'ai_mapRoute_getSuccessors'});
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
			#print "$$r_cur{'source'}{'map'} -> $$r_cur{'dest'}{'map'}\n";
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

	DebugMessage("ai_mapRoute_searchStep($r_args)") if ($debug{'ai_mapRoute_searchStep'});
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

	DebugMessage("ai_route(($x, $y), $map, $maxRouteDistance, $maxRouteTime, $attackOnRoute, $avoidPortals, $distFromGoal, $checkInnerPortals)") if ($debug{'ai_route'});
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

	DebugMessage("ai_route_getDiagSuccessors($r_args, $r_pos, $r_array, $type)") if ($debug{'ai_route_getDiagSuccessors'});
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

	DebugMessage("ai_route_getRoute($r_field, $r_start{'x'}, $r_start{'y'}, $r_dest{'x'}, $r_dest{'y'})") if ($debug{'ai_route_getRoute'});
}

sub ai_route_getRoute_destroy {
	my $r_args = shift;
	$CalcPath_destroy->Call($$r_args{'session'});
}
sub ai_route_searchStep {
	my $r_args = shift;
	my $ret;

	if (!$$r_args{'initialized'}) {
		#####
		my $SOLUTION_MAX = 5000;
		$$r_args{'solution'} = "\0" x ($SOLUTION_MAX*4+4);
		#####

		$$r_args{'session'} = $CalcPath_init->Call($$r_args{'solution'},
			$$r_args{'field'}{'rawMap'}, $$r_args{'field'}{'width'}, $$r_args{'field'}{'height'},
			pack("S*",$$r_args{'start'}{'x'}, $$r_args{'start'}{'y'}), pack("S*",$$r_args{'dest'}{'x'}, $$r_args{'dest'}{'y'}), $$r_args{'timeout'});
	}
	if ($$r_args{'session'} < 0) {
		$$r_args{'done'} = 1;
		return;
	}
	$$r_args{'initialized'} = 1;

	$ret = $CalcPath_pathStep->Call($$r_args{'session'});
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

	DebugMessage("ai_route_searchStep($r_args)") if ($debug{'ai_route_searchStep'});
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

	DebugMessage("ai_route_getSuccessors($r_args, $r_pos, $r_array, $type)") if ($debug{'ai_route_getSuccessors'});
}


#sellAuto for items_control - chobit andy 20030210
sub ai_sellAutoCheck {
	for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}}; $i++) {
		next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'});
		if ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'sell'}
			&& $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}) {
			return 1;
		}
	}
}

sub ai_setMapChanged {
	my $index = shift;
	$index = 0 if ($index eq "");
	if ($index < @ai_seq_args) {
		$ai_seq_args[$index]{'mapChanged'} = time;
	}
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
	my $waitBeforeNextUse = shift;
	my $target = shift;
	my $y = shift;
	my %args;
	my $skill = GetSkillName($ID);

	if (binCount(\@ai_seq, "skill_use") < 5) {
		$args{'ai_skill_use_giveup'}{'time'} = time;
		$args{'ai_skill_use_giveup'}{'timeout'} = $timeout{'ai_skill_use_giveup'}{'timeout'};
		$args{'skill_use_id'} = $ID;
		$args{'skill_use_lv'} = $lv;
		$args{'skill_use_maxCastTime'}{'time'} = time;
		$args{'skill_use_maxCastTime'}{'timeout'} = $maxCastTime;
		$args{'skill_use_minCastTime'}{'time'} = time;
		$args{'skill_use_minCastTime'}{'timeout'} = $minCastTime;
		$args{'skill_use_waitBeforeNextUse'}{'time'} = time;

		$timeout_ex{'skill_use_waitBeforeNextUse'}{'time'} = time - $waitBeforeNextUse;
		$timeout_ex{'skill_use_waitBeforeNextUse'}{'timeout'} = $waitBeforeNextUse;

		if ($y eq "") {
			$args{'skill_use_target'} = $target;
		} else {
			$args{'skill_use_target_x'} = $target;
			$args{'skill_use_target_y'} = $y;
		}
		unshift @ai_seq, "skill_use";
		unshift @ai_seq_args, \%args;

		if ($y eq "") {
			DebugMessage("ai_skillUse($skill, $lv, $maxCastTime, $minCastTime, $waitBeforeNextUse, ".Name($target).")") if ($debug{'ai_skillUse'});
		} else {
			DebugMessage("ai_skillUse($skill, $lv, $maxCastTime, $minCastTime, $waitBeforeNextUse, ($target, $y))") if ($debug{'ai_skillUse'});
		}
	}
}

#storageAuto for items_control - chobit andy 20030210
sub ai_storageAutoCheck {
	for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}}; $i++) {
		next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'});
		if ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'storage'}
			&& $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}) {
			return 1;
		}
	}
}

sub attack {
	my $ID = shift;
	my %args;

	OnYou($EV_GO_ATTACK_MONSTER, $ID);

	$args{'ai_attack_giveup'}{'time'} = time;
	$args{'ai_attack_giveup'}{'timeout'} = $timeout{'ai_attack_giveup'}{'timeout'};
	$args{'ID'} = $ID;
	%{$args{'pos_to'}} = %{$monsters{$ID}{'pos_to'}};
	%{$args{'pos'}} = %{$monsters{$ID}{'pos'}};
	unshift @ai_seq, "attack";
	unshift @ai_seq_args, \%args;

	DebugMessage("attack($monsters{$ID}{'name'} ($monsters{$ID}{'binID'}) [".getHex($ID)."]) at $monsters{$ID}{'pos_to'}{'x'}, $monsters{$ID}{'pos_to'}{'y'}") if ($debug{'ai_attack'});
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
	DebugMessage("gather($items{$ID}{'name'} ($items{$ID}{'binID'}) [".getHex($ID)."])") if ($debug{'ai_itemsGather'});
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
	DebugMessage("move($x, $y)") if ($debug{'ai_move'});
}

sub quit {
	if ($conState == 5 && $remote_socket && $remote_socket->connected()) {
		PrintMessage("\nSend exit request. Waiting response from server...", "lightblue");
		sendExit(\$remote_socket);
	} else {
		$quit = 1;
	}
}

sub reconnect {
	my $delay = shift;

	if ($conState == 5 && $remote_socket && $remote_socket->connected()) {
		PrintMessage("\nSend exit request. Waiting response from server...", "lightblue");
		if ($delay > 0) {
			$reconnect = $delay;
		} else {
			$reconnect = 7;
		}

		sendExit(\$remote_socket);
	} else {
		$timeout_ex{'master'}{'time'} = time;
		$timeout_ex{'master'}{'timeout'} = 7;
		killConnection(\$remote_socket);
	}
}

sub relog {
	$conState = 1;
	undef $conState_tries;
	print "Relogging\n";
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
	my $emo;

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

				$emo = ParseEmotion($msg);
				if ($emo >= 0) {
					sendEmotion($r_socket, $emo);
				} elsif ($type eq "c") {
					sendChat($r_socket, $msg);
				} elsif ($type eq "g") {
					sendGuildChat($r_socket, $msg);
				} elsif ($type eq "p") {
					sendPartyChat($r_socket, $msg);
				} elsif ($type eq "pm") {
					$lastpm{'user'} = $user;
					$lastpm{'msg'} = $msg;
					sendPrivateMsg($r_socket, $user, $msg);
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
			$emo = ParseEmotion($msg);
			if ($emo >= 0) {
				sendEmotion($r_socket, $emo);
			} elsif ($type eq "c") {
				sendChat($r_socket, $msg);
			} elsif ($type eq "g") {
				sendGuildChat($r_socket, $msg);
			} elsif ($type eq "p") {
				sendPartyChat($r_socket, $msg);
			} elsif ($type eq "pm") {
				$lastpm{'user'} = $user;
				$lastpm{'msg'} = $msg;
				sendPrivateMsg($r_socket, $user, $msg);
			} elsif ($type eq "k") {
				injectMessage($msg);
			}
			$msg = $msg[$i];
		}
		if (length($msg) && $i == @msg - 1) {
			$emo = ParseEmotion($msg);
			if ($emo >= 0) {
				sendEmotion($r_socket, $emo);
			} elsif ($type eq "c") {
				sendChat($r_socket, $msg);
			} elsif ($type eq "g") {
				sendGuildChat($r_socket, $msg);
			} elsif ($type eq "p") {
				sendPartyChat($r_socket, $msg);
			} elsif ($type eq "pm") {
				$lastpm{'user'} = $user;
				$lastpm{'msg'} = $msg;
				sendPrivateMsg($r_socket, $user, $msg);
			} elsif ($type eq "k") {
				injectMessage($msg);
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

	DebugMessage("take($items{$ID}{'name'})") if ($debug{'ai_take'});
}

#Karusu
sub useTeleport {
	my $level = shift;
	my $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", $level + 600);

	undef $teleQueue;
	undef $chars[$config{'char'}]{'useteleport'};

	# Stand up before teleporting
	if ($chars[$config{'char'}]{'sitting'}) {
		sendStand(\$remote_socket);
		sleep(0.5);
	}

	#if (!$config{'teleportAuto_useItem'} || $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} >= $level || ($config{'teleportAuto_useItem'} == 2 && !$chars[$config{'char'}]{'usewing'})) {
	#	sendTeleport(\$remote_socket, "Random") if ($level == 1);
	#	sendTeleport(\$remote_socket, $config{'saveMap'}.".gat") if ($level == 2);
	#}
	if ($config{'teleportAuto_useItem'} == 2 && !$chars[$config{'char'}]{'usewing'}) {
		sendTeleport(\$remote_socket, "Random") if ($level == 1);
		sendTeleport(\$remote_socket, $config{'saveMap'}.".gat") if ($level == 2);
	} elsif ($level == 1 && $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} >= 1) {
		sendTeleport(\$remote_socket, "Random");
	} elsif ($level == 2 && $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} >= 2) {
		if (!$config{'teleportAuto_useSkill'}) {
			$chars[$config{'char'}]{'useteleport'} = 1;
			sendSkillUse(\$remote_socket, $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'ID'}, 2, $accountID);
		} else {
			sendTeleport(\$remote_socket, $config{'saveMap'}.".gat");
		}
	} elsif ($invIndex ne "") {
		$chars[$config{'char'}]{'usewing'} = $level;
		sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}, $accountID);
	# Wait for the inventory info to come
	} elsif (!scalar(@{$chars[$config{'char'}]{'inventory'}})) {
		$teleQueue = $level;
	} else {
		print "Can't teleport or respawn - need wing or skill\n" if $config{'debug'};
	}
}

#sub useTeleport {
#	my $level = shift;
#	my $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", $level + 600);
#	if (!$config{'teleportAuto_useItem'} || $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'}) {
#		sendTeleport(\$remote_socket, "Random") if ($level == 1);
#		sendTeleport(\$remote_socket, $config{'saveMap'}.".gat") if ($level == 2);
#	} elsif ($invIndex ne "") {
#		sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}, $accountID);
#	} else {
#		print "Can't teleport or respawn - need wing or skill\n" if $config{'debug'};
#	}
#}

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
	writeDataFile("$profile/overallAuth.txt", \%overallAuth);
}

sub avoidPlayer {
	my $player = shift;
	my $flag = shift;
	if ($flag) {
		print "Avoid player '$player'\n";
	} else {
		print "Revoked avoid for player '$player'\n";
	}
	$avoid{$user} = $flag;
	writeDataFile("$profile/avoid.txt", \%avoid);
}

sub configModify {
	my $key = shift;
	my $val = shift;
	print "Config '$key' set to $val\n";
	$config{$key} = $val;
	writeDataFileIntact("$profile/config.txt", \%config);
}

sub debugModify {
	my $key = shift;
	my $val = shift;
	print "Debug '$key' set to $val\n";
	$debug{$key} = $val;
	writeDataFileIntact("$profile/debug.txt", \%debug);
}

sub setTimeout {
	my $timeout = shift;
	my $time = shift;
	$timeout{$timeout}{'timeout'} = $time;
	print "Timeout '$timeout' set to $time\n";
	writeDataFileIntact2("$profile/timeouts.txt", \%timeout);
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
	my $r_msg = shift;
	my $themsg = shift;
	my @mask;
	my $newmsg;
	my ($in, $out);

	if ($debug{'sendPacket'}) {
		$switch = uc(unpack("H2", substr($themsg, 1, 1))) . uc(unpack("H2", substr($themsg, 0, 1)));
		print "SEND PACKET: $switch $spackets{$switch}{'desc'}\n";

		if ($dpackets{$switch}) {
			dumpSendPacket($themsg);
		}
	}

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

sub injectMessage {
	my $message = shift;
	my $name = "KORE";
	my $msg .= $name . " : " . $message . chr(0);
	encrypt(\$msg, $msg);
	$msg = pack("C*",0x09, 0x01) . pack("S*", length($name) + length($message) + 12) . pack("C*",0,0,0,0) . $msg;
	encrypt(\$msg, $msg);
	sendToClientByInject(\$remote_socket, $msg);
}

sub injectAdminMessage {
	my $message = shift;
	my $msg = pack("C*",0x9A, 0x00) . pack("S*", length($message)+5) . $message .chr(0);
	encrypt(\$msg, $msg);
	sendToClientByInject(\$remote_socket, $msg);
}

sub sendAddSkillPoint {
	my $r_socket = shift;
	my $skillID = shift;
	my $msg = pack("C*", 0x12, 0x01) . pack("S*", $skillID);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
}

sub sendAddStatusPoint {
	my $r_socket = shift;
	my $statusID = shift;
	my $msg = pack("C*", 0xBB, 0) . pack("S*", $statusID) . pack("C*", 0x01);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
}

sub sendAlignment {
	my $r_socket = shift;
	my $ID = shift;
	my $alignment = shift;
	my $msg = pack("C*", 0x49, 0x01) . $ID . pack("C*", $alignment);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Alignment: ".getHex($ID).", $alignment\n" if ($config{'debug'} >= 2);
}

sub sendAttack {
	my $r_socket = shift;
	my $monID = shift;
	my $flag = shift;
        my $msg = pack("C*", 0x89, 0x00) . $monID . pack("C*", $flag);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent attack: ".getHex($monID)."\n" if ($config{'debug'} >= 2);
}

sub sendAttackStop {
	my $r_socket = shift;
	my $msg = pack("C*", 0x18, 0x01);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent stop attack\n" if $config{'debug'};
}

sub sendBuy {
	my $r_socket = shift;
	my $ID = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xC8, 0x00, 0x08, 0x00) . pack("S*", $amount, $ID);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent buy: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendBypass {
	my $r_socket = shift;
	my $msg = shift;
	$$r_socket->send($msg) if $$r_socket && $$r_socket->connected();
}

sub sendCardMergeRequest {
	my $r_socket = shift;
	my $card_index = shift;
	my $msg = pack("C*", 0x7A, 0x01) . pack("S*", $card_index);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Card Merge Request: $card_index\n" if ($config{'debug'} >= 2);
# 7A 01 39 00
}

sub sendCardMerge {
	my $r_socket = shift;
	my $card_index = shift;
	my $item_index = shift;
	my $msg = pack("C*", 0x7C, 0x01) . pack("S*", $card_index, $item_index);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Card Merge: $card_index, $item_index\n" if ($config{'debug'} >= 2);
# 7C 01 39 00 10 00
}

sub sendCartAdd {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0x26, 0x01) . pack("S*", $index) . pack("L*", $amount);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Cart Add: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendCartGet {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0x27, 0x01) . pack("S*", $index) . pack("L*", $amount);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Cart Get: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendCartStorageAdd {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0x29, 0x01) . pack("S*", $index) . pack("L*", $amount);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Cart Storage Add: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendCatch {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x9F, 0x01) . $ID;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Catch: ".Name($ID)." (".getHex($ID).")\n" if ($config{'debug'} >= 2);
}

sub sendCharLogin {
	my $r_socket = shift;
	my $char = shift;
	my $msg = pack("C*", 0x66,0) . pack("C*",$char);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
}

sub sendChat {
	my $r_socket = shift;
	my $message = shift;
	my $msg = pack("C*",0x8C, 0x00) . pack("S*", length($chars[$config{'char'}]{'name'}) + length($message) + 8) .
		$chars[$config{'char'}]{'name'} . " : " . $message . chr(0);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
}

sub sendChatRoomBestow {
	my $r_socket = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00).$name;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
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
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
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
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Create Chat Room: $title, $limit, $public, $password\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomJoin {
	my $r_socket = shift;
	my $ID = shift;
	my $password = shift;
	$password = substr($password, 0, 8) if (length($password) > 8);
	$password = $password . chr(0) x (8 - length($password));
	my $msg = pack("C*", 0xD9, 0x00).$ID.$password;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Join Chat Room: ".getHex($ID)." $password\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomKick {
	my $r_socket = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xE2, 0x00).$name;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Chat Room Kick: $name\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomLeave {
	my $r_socket = shift;
	my $msg = pack("C*", 0xE3, 0x00);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Leave Chat Room\n" if ($config{'debug'} >= 2);
}

sub sendCurrentDealCancel {
	my $r_socket = shift;
	my $msg = pack("C*", 0xED, 0x00);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Cancel Current Deal\n" if ($config{'debug'} >= 2);
}

sub sendDeal {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xE4, 0x00) . $ID;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Initiate Deal: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendDealAccept {
	my $r_socket = shift;
	my $msg = pack("C*", 0xE6, 0x00, 0x03);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Accept Deal\n" if ($config{'debug'} >= 2);
}

sub sendDealAddItem {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xE8, 0x00) . pack("S*", $index) . pack("L*",$amount);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Deal Add Item: $index, $amount\n" if ($config{'debug'} >= 2);
}

sub sendDealCancel {
	my $r_socket = shift;
	my $msg = pack("C*", 0xE6, 0x00, 0x04);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Cancel Deal\n" if ($config{'debug'} >= 2);
}

sub sendDealFinalize {
	my $r_socket = shift;
	my $msg = pack("C*", 0xEB, 0x00);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Deal OK\n" if ($config{'debug'} >= 2);
}

sub sendDealOK {
	my $r_socket = shift;
	my $msg = pack("C*", 0xEB, 0x00);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Deal OK\n" if ($config{'debug'} >= 2);
}

sub sendDealTrade {
	my $r_socket = shift;
	my $msg = pack("C*", 0xEF, 0x00);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Deal Trade\n" if ($config{'debug'} >= 2);
}

sub sendDrop {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xA2, 0x00) . pack("S*", $index, $amount);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent drop: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendEmotion {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xBF, 0x00).pack("C1",$ID);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Emotion\n" if ($config{'debug'} >= 2);
}

sub sendEquip {
	my $r_socket = shift;
	my $index = shift;
	my $type = shift;
	my $masktype = shift;
	my $msg = pack("C*", 0xA9, 0x00) . pack("S*", $index) .  pack("C*", $type, $masktype);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Equip: $index\n" if ($config{'debug'} >= 2);
}

sub sendExit {
	my $r_socket = shift;
	my $msg = pack("C*", 0x8A, 0x01, 0x00, 0x00);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Exit\n" if ($config{'debug'} >= 2);
}

sub sendGameLogin {
	my $r_socket = shift;
	my $accountID = shift;
	my $sessionID = shift;
	my $sessionID2 = shift;
	my $sex = shift;
	my $msg = pack("C*", 0x65,0) . $accountID . $sessionID . $sessionID2 . pack("C*", 0,0,$sex);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
}

sub sendGetPlayerInfo {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x94, 0x00) . $ID;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent get player info: ID - ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendGetStoreList {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xC5, 0x00) . $ID . pack("C*",0x00);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent get store list: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendGetSellList {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xC5, 0x00) . $ID . pack("C*",0x01);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent sell to NPC: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendGuildFirstQuery {
	my $r_socket = shift;
	my $msg = pack("C*", 0x4D, 0x01);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Guild First Request\n" if ($config{'debug'} >= 2);
}

sub sendGuildQueryPage {
	my $r_socket = shift;
	my $page = shift;
	my $msg = pack("C*", 0x4F, 0x01).pack("L*",$page);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Guild Request $page\n" if ($config{'debug'} >= 2);
}

sub sendGuildMemberDelete {
	my $r_socket = shift;
	my $guildID = shift;
	my $accountID = shift;
	my $charID = shift;
	my $cause = shift;

	$cause = substr($cause, 0, 40) if (length($cause) > 40);
	$cause = $cause . chr(0) x (40 - length($cause));

	my $msg = pack("C*", 0x5B, 0x01).$guildID.$accountID.$charID;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Guild Member Delete: ".Name($accountID)."\n" if ($config{'debug'} >= 2);

#       Guild ID      Account ID    Char ID
#5B 01 | 9F 2B 00 00 | CE 72 0C 00 | 63 6A 13 00 |
#C5 BA B5 D1 C7 C5 D0 A4 C3 E4 BB E1 C5 E9 C7 20 CA D2 C7 E6
#20 C5 BA E4 B4 E9 E4 A7 00 00 00 00 00 00 00 00 00 00 00 00
}

sub sendGuildJoinRequest {
	my $r_socket = shift;
	my $targetID = shift;
	my $accountID = shift;
	my $charID = shift;
	my $msg = pack("C*", 0x68, 0x01).$targetID.$accountID.$charID;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Request Join Guild: ".Name($targetID)."\n" if ($config{'debug'} >= 2);

#           Target ID       Account ID      Char ID
# 68 01 | 72 99 06 00 | 7C C4 0A 00 | DE 59 08 00
}

sub sendGuildJoin {
	my $r_socket = shift;
	my $guildID = shift;
	my $type = shift;
	my $msg = pack("C*", 0x6B, 0x01).$guildID.pack("L*",$type);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Guild Join\n" if ($config{'debug'} >= 2);

#       Guild ID      Type
#6B 01 | 9F 2B 00 00 | 01 00 00 00
}

sub sendGuildLeave {
	my $r_socket = shift;
	my $guildID = shift;
	my $accountID = shift;
	my $charID = shift;
	my $cause = shift;

	$cause = substr($cause, 0, 40) if (length($cause) > 40);
	$cause = $cause . chr(0) x (40 - length($cause));

	my $msg = pack("C*", 0x59, 0x01).$guildID.$accountID.$charID.$cause;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Guild Leave\n" if ($config{'debug'} >= 2);

#       Guild ID      Account ID    Char ID       Cause
#59 01 | 9F 2B 00 00 | 72 99 06 00 | 90 24 14 00 | B7 B4
#CA CD BA 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00
}

sub sendGuildAllyRequest {
	my $r_socket = shift;
	my $targetID = shift;
	my $accountID = shift;
	my $charID = shift;
	my $msg = pack("C*", 0x70, 0x01).$targetID.$accountID.$charID;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Guild Request Ally ".Name($targetID)."\n" if ($config{'debug'} >= 2);

#           Target ID       Account ID      Char ID
# 70 01 | 72 99 06 00 | 7C C4 0A 00 | 44 2F 09 00
}

sub sendGuildAlly {
	my $r_socket = shift;
	my $targetID = shift;
	my $type = shift;
	my $msg = pack("C*", 0x72, 0x01).$targetID.pack("L*",$type);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Guild Ally ".Name($targetID)."\n" if ($config{'debug'} >= 2);

#           Target ID       Type
#72 01 | 72 99 06 00 | 01 00 00 00
}

sub sendGuildEnemyRequest {
	my $r_socket = shift;
	my $targetID = shift;
	my $msg = pack("C*", 0x80, 0x01).$targetID;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Guild Request Enemy ".Name($targetID)."\n" if ($config{'debug'} >= 2);

#          Target ID
#80 01 | 72 99 06 00
}

sub sendGuildDeleteRequest {
	my $r_socket = shift;
	my $guildID = shift;
	my $type = shift;
	my $msg = pack("C*", 0x80, 0x01).$guildID.pack("L*",$type);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Guild Delete Request\n" if ($config{'debug'} >= 2);

#          Guild ID
#83 01 | 70 17 00 00 | 01 00 00 00
}

sub sendCharacterNameRequest {
	my $r_socket = shift;
	my $charID = shift;
	my $msg = pack("C*", 0x93, 0x01) . $charID;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Guild Member Name Request : ".getHex($charID)."\n" if ($config{'debug'} >= 2);
}

sub sendGuildMemberTitleSelect {
	my $r_socket = shift;
	my $accountID = shift;
	my $charID = shift;
	my $index = shift;

	my $msg = pack("C*", 0x55, 0x01).pack("S*",16).$accountID.$charID.pack("L*",$index);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Guild Member Title Selected\n" if ($config{'debug'} >= 2);

#55 01 10 00 72 99 06 00    90 24 14 00 0E 00 00 00
}

sub sendGuildMemberTitleChange {
	my $r_socket = shift;
	my $index = shift;
	my $title = shift;

	$title = substr($title, 0, 24) if (length($title) > 24);
	$title = $title . chr(0) x (24 - length($title));

	my $msg = pack("C*", 0x61, 0x01).pack("S*",44).pack("L*",$index).pack("L*",1).pack("L*",$index).pack("L*",0).$title;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Guild Member Title Changed\n" if ($config{'debug'} >= 2);

#61 01 54 00 0E 00 00 00    01 00 00 00 0E 00 00 00
#00 00 00 00 CA C7 C2 E3    CA A1 C3 D0 AA D2 A1 E3
#A8 BB EB D2 00 00 00 00    00 00 00 00 10 00 00 00
#00 00 00 00 10 00 00 00    00 00 00 00 50 6F 73 69
#74 69 6F 6E 20 31 37 00    00 00 00 00 00 00 00 00
#00 00 00 00
}

sub sendGuildNotice {
	my $r_socket = shift;
	my $guildID = shift;
	my $name = shift;
	my $notice = shift;

	$name = substr($name, 0, 60) if (length($name) > 60);
	$name = $name . chr(0) x (60 - length($name));

	$notice = substr($notice, 0, 120) if (length($notice) > 120);
	$notice = $notice . chr(0) x (120 - length($notice));

	my $msg = pack("C*", 0x6E, 0x01).$guildID.$name.$notice;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Guild Notice\n" if ($config{'debug'} >= 2);

#      Guild ID    Name
#6E 01 9F 2B 00 00 7E 47    2E 4F 2E 44 7E 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 43 61 74 63 68 20    6D 65 2C 20 69 66 20 79
#6F 75 20 63 61 6E 2E 20    4C 6F 76 65 20 6D 65 2C
#20 69 66 20 79 6F 75 20    61 72 65 20 61 20 67 69
#72 6C 2E 20 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00
}

sub sendGuildChat {
	my $r_socket = shift;
	my $message = shift;
	my $msg = pack("C*",0x7E, 0x01) . pack("S*",length($chars[$config{'char'}]{'name'}) + length($message) + 8) .
	$chars[$config{'char'}]{'name'} . " : " . $message . chr(0);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
}

sub sendIdentify {
	my $r_socket = shift;
	my $index = shift;
	my $msg = pack("C*", 0x78, 0x01) . pack("S*", $index);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Identify: $index\n" if ($config{'debug'} >= 2);
}

sub sendIgnore {
	my $r_socket = shift;
	my $name = shift;
	my $flag = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xCF, 0x00).$name.pack("C*", $flag);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Ignore: $name, $flag\n" if ($config{'debug'} >= 2);
}

sub sendIgnoreAll {
	my $r_socket = shift;
	my $flag = shift;
	my $msg = pack("C*", 0xD0, 0x00).pack("C*", $flag);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Ignore All: $flag\n" if ($config{'debug'} >= 2);
}

#sendGetIgnoreList - chobit 20021223
sub sendIgnoreListGet {
	my $r_socket = shift;
	my $flag = shift;
	my $msg = pack("C*", 0xD3, 0x00);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent get Ignore List: $flag\n" if ($config{'debug'} >= 2);
}

sub sendIncubator {
	my $r_socket = shift;
	my $index = shift;
	my $msg = pack("C*", 0xA7, 0x01) . pack("S*", $index);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Incubator: $index\n" if ($config{'debug'} >= 2);
}

sub sendItemUse {
	my $r_socket = shift;
	my $ID = shift;
	my $targetID = shift;
	my $msg = pack("C*", 0xA7, 0x00).pack("S*",$ID).$targetID;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Item Use: $ID\n" if ($config{'debug'} >= 2);
}


sub sendLook {
	my $r_socket = shift;
	my $body = shift;
	my $head = shift;
	my $msg = pack("C*", 0x9B, 0x00, $head, 0x00, $body);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent look: $body $head\n" if ($config{'debug'} >= 2);
	$chars[$config{'char'}]{'look'}{'head'} = $head;
	$chars[$config{'char'}]{'look'}{'body'} = $body;
}

sub sendMapLoaded {
	my $r_socket = shift;
	my $msg = pack("C*", 0x7D,0x00);
	print "Sending Map Loaded\n" if $config{'debug'};
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
}

sub sendMapLogin {
	my $r_socket = shift;
	my $accountID = shift;
	my $charID = shift;
	my $sessionID = shift;
	my $sex = shift;
	my $msg = pack("C*", 0x72,0) . $accountID . $charID . $sessionID . pack("L1", getTickCount()) . pack("C*",$sex);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
}

sub sendMasterCodeRequest {
	my $r_socket = shift;
	my $msg = pack("C*", 0xDB, 0x01);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
}

sub sendMasterSecureLogin {
	my $r_socket = shift;
	my $msg = shift;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
}

sub sendMasterLogin {
	my $r_socket = shift;
	my $username = shift;
	my $password = shift;
	my $msg = pack("C*", 0x64,0,$config{'version'},0,0,0) . $username . chr(0) x (24 - length($username)) .
			$password . chr(0) x (24 - length($password)) . pack("C*", $config{"master_version_$config{'master'}"});
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
}

sub sendMemo {
	my $r_socket = shift;
	my $msg = pack("C*", 0x1D, 0x01);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Memo\n" if ($config{'debug'} >= 2);
}

sub sendMove {
	my $r_socket = shift;
	my $x = shift;
	my $y = shift;
	my $msg = pack("C*", 0x85, 0x00) . getCoordString($x, $y);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent move to: $x, $y\n" if ($config{'debug'} >= 2);
}

sub sendPartyChat {
	my $r_socket = shift;
	my $message = shift;
	my $msg = pack("C*",0x08, 0x01) . pack("S*",length($chars[$config{'char'}]{'name'}) + length($message) + 8) .
		$chars[$config{'char'}]{'name'} . " : " . $message . chr(0);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
}

sub sendPartyJoin {
	my $r_socket = shift;
	my $ID = shift;
	my $flag = shift;
	my $msg = pack("C*", 0xFF, 0x00).$ID.pack("L", $flag);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Join Party: ".getHex($ID).", $flag\n" if ($config{'debug'} >= 2);
}

sub sendPartyJoinRequest {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xFC, 0x00).$ID;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Request Join Party: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendPartyKick {
	my $r_socket = shift;
	my $ID = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0x03, 0x01).$ID.$name;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Kick Party: ".getHex($ID).", $name\n" if ($config{'debug'} >= 2);
}

sub sendPartyLeave {
	my $r_socket = shift;
	my $msg = pack("C*", 0x00, 0x01);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Leave Party: $name\n" if ($config{'debug'} >= 2);
}

sub sendPartyOrganize {
	my $r_socket = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xF9, 0x00).$name;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Organize Party: $name\n" if ($config{'debug'} >= 2);
}

sub sendPartyShareEXP {
	my $r_socket = shift;
	my $flag = shift;
	my $msg = pack("C*", 0x02, 0x01).pack("L", $flag);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Party Share: $flag\n" if ($config{'debug'} >= 2);
}

sub sendPetCommand {
	my $r_socket = shift;
	my $cmd = shift;
	my $msg = pack("C*", 0xA1, 0x01) . pack("C*", $cmd);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Pet Command: $cmd\n" if ($config{'debug'} >= 2);
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
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Raw Packet: @raw\n" if ($config{'debug'} >= 2);
}

sub sendRespawn {
	my $r_socket = shift;
	my $msg = pack("C*", 0xB2, 0x00, 0x00);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Respawn\n" if ($config{'debug'} >= 2);
}

sub sendPrivateMsg {
	my $r_socket = shift;
	my $user = shift;
	my $message = shift;
	my $msg = pack("C*",0x96, 0x00) . pack("S*",length($message) + 29) . $user . chr(0) x (24 - length($user)) .
			$message . chr(0);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
}

sub sendSell {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xC9, 0x00, 0x08, 0x00) . pack("S*", $index, $amount);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent sell: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendSit {
	my $r_socket = shift;
	my $msg = pack("C*", 0x89,0x00, 0x00, 0x00, 0x00, 0x00, 0x02);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sitting\n" if ($config{'debug'} >= 2);
}

sub sendSkillUse {
	my $r_socket = shift;
	my $ID = shift;
	my $lv = shift;
	my $targetID = shift;
	my $msg = pack("C*", 0x13, 0x01).pack("S*",$lv,$ID).$targetID;
	my $skill = GetSkillName($ID);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Skill Use: $ID\n" if ($config{'debug'} >= 2);

	undef $chars[$config{'char'}]{'last_skill_used'};
	undef $chars[$config{'char'}]{'last_skill_target'};
	undef $chars[$config{'char'}]{'last_skill_failed'};

	DebugMessage("sendSkillUse($skill, $lv, ".Name($targetID).")") if ($debug{'sendSkillUse'});
}

sub sendSkillUseLoc {
	my $r_socket = shift;
	my $ID = shift;
	my $lv = shift;
	my $x = shift;
	my $y = shift;
	my $msg = pack("C*", 0x16, 0x01).pack("S*",$lv,$ID,$x,$y);
	my $skill = GetSkillName($ID);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Skill Use Loc: $ID\n" if ($config{'debug'} >= 2);

	undef $chars[$config{'char'}]{'last_skill_used'};
	undef $chars[$config{'char'}]{'last_skill_target'};
	undef $chars[$config{'char'}]{'last_skill_failed'};

	DebugMessage("sendSkillUseLoc($skill, $lv, ($x, $y))") if ($debug{'	'});
}

sub sendStorageAdd {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xF3, 0x00) . pack("S*", $index) . pack("L*", $amount);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Storage Add: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendStorageClose {
	my $r_socket = shift;
	my $msg = pack("C*", 0xF7, 0x00);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Storage Done\n" if ($config{'debug'} >= 2);
}

sub sendStorageGet {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xF5, 0x00) . pack("S*", $index) . pack("L*", $amount);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Storage Get: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendStand {
	my $r_socket = shift;
	my $msg = pack("C*", 0x89,0x00, 0x00, 0x00, 0x00, 0x00, 0x03);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Standing\n" if ($config{'debug'} >= 2);
}

sub sendSync {
	my $r_socket = shift;
	my $time = shift;
	my $msg = pack("C*", 0x7E, 0x00) . pack("L1", $time);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Sync: $time\n" if ($config{'debug'} >= 2);
}

sub sendSyncInject {
	my $r_socket = shift;
	$$r_socket->send("K".pack("S", 0)) if $$r_socket && $$r_socket->connected();
}

sub sendTake {
	my $r_socket = shift;
	my $itemID = shift;
	my $msg = pack("C*", 0x9F, 0x00) . $itemID;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent take\n" if ($config{'debug'} >= 2);
}

sub sendTalk {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x90, 0x00) . $ID . pack("C*",0x01);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);

	$talk{'msg'} = "";
	print "Sent talk: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendTalkCancel {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x46, 0x01) . $ID;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);

	$talk{'msg'} = "";
	print "Sent talk cancel: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendTalkContinue {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xB9, 0x00) . $ID;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);

	$talk{'msg'} = "";
	print "Sent talk continue: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendTalkResponse {
	my $r_socket = shift;
	my $ID = shift;
	my $response = shift;
	my $msg = pack("C*", 0xB8, 0x00) . $ID. pack("C1",$response);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);

	$talk{'msg'} = "";
	print "Sent talk respond: ".getHex($ID).", $response\n" if ($config{'debug'} >= 2);
}

sub sendTeleport {
	my $r_socket = shift;
	my $location = shift;
	$location = substr($location, 0, 16) if (length($location) > 16);
	$location .= chr(0) x (16 - length($location));
	my $msg = pack("C*", 0x1B, 0x01, 0x1A, 0x00) . $location;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Teleport: $location\n" if ($config{'debug'} >= 2);
}

sub sendMixture {
	my $r_socket = shift;
	my $type = shift;
	my $msg = pack("C*", 0x8E, 0x01).pack("S1",$type).pack("C*", 0, 0, 0, 0, 0, 0);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Tempering: $type\n" if ($config{'debug'} >= 2);
}

sub sendWarpPortal {
	my $r_socket = shift;
	my $location = shift;
	$location = substr($location, 0, 16) if (length($location) > 16);
	$location .= chr(0) x (16 - length($location));
	my $msg = pack("C*", 0x1B, 0x01, 0x1B, 0x00) . $location;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Warp Portal: $location\n" if ($config{'debug'} >= 2);
}

sub sendToClientByInject {
	my $r_socket = shift;
	my $msg = shift;
	$$r_socket->send("R".pack("S", length($msg)).$msg) if $$r_socket && $$r_socket->connected();
}

sub sendToServerByInject {
	my $r_socket = shift;
	my $msg = shift;

	if ($config{'remoteSocket'}) {
		$$r_socket->send($msg) if $$r_socket && $$r_socket->connected();
	} else {
		$$r_socket->send("S".pack("S", length($msg)).$msg) if $$r_socket && $$r_socket->connected();
	}
}

sub sendUnequip {
	my $r_socket = shift;
	my $index = shift;
	my $msg = pack("C*", 0xAB, 0x00) . pack("S*", $index);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Unequip: $index\n" if ($config{'debug'} >= 2);
}

sub sendVenderItemsList {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x30, 0x01) . $ID;
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Entering Vender: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendVenderBuy {
	my $r_socket = shift;
	my $venderID = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0x34, 0x01, 0x0C, 0x00) . $venderID . pack("S*", $amount, $index);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Sent Vender Buy: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendWho {
	my $r_socket = shift;
	my $msg = pack("C*", 0xC1, 0x00);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
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
	print "Connecting ($host:$port)... ";
	$$r_socket = IO::Socket::INET->new(
			PeerAddr	=> $host,
			PeerPort	=> $port,
			Proto		=> 'tcp',
			Timeout		=> 4);
	($$r_socket && inet_aton($$r_socket->peerhost()) eq inet_aton($host)) ? print "connected\n" : print "couldn't connect\n";
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
	print "Spawning Input Socket...\n";
	my $pid = fork;

	if ($pid == 0) {
		$local_socket = IO::Socket::INET->new(
				PeerAddr	=> $config{'local_host'},
				PeerPort	=> $config{'local_port'},
				Proto		=> 'tcp',
				Timeout		=> 4);
		($local_socket) || die "Error creating connection to local server: $!";
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
		|| die "Input Socket must be connected from localhost";
		print "Input Socket connected\n";

		return $pid;
	}
}

sub killConnection {
	my $r_socket = shift;
	if ($$r_socket && $$r_socket->connected()) {
		print "Disconnecting (".$$r_socket->peerhost().":".$$r_socket->peerport().")... ";
		close($$r_socket);
		!$$r_socket->connected() ? print "disconnected\n" : print "couldn't disconnect\n";
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

sub chatLog {
	my $type = shift;
	my $msg = shift;
	my $file;

	if ($profilename ne "") {
		$file = $profilename."_chat.txt";
	} else {
		$file = "chat.txt";
	}

	$file = "log/$file";

	open CHAT, ">> $file";
	print CHAT "[".getFormattedDate(int(time))."][".uc($type)."] $msg";
	close CHAT;
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
	my $file;

	$dump = "\n\n==================================================\n".getFormattedDate(int(time))."\n\n".length($msg)." bytes\n\n";
	for ($i=0; $i + 15 < length($msg);$i += 16) {
		$dump .= getHex(substr($msg,$i,8))."    ".getHex(substr($msg,$i+8,8))."\n";
	}
	if (length($msg) - $i > 8) {
		$dump .= getHex(substr($msg,$i,8))."    ".getHex(substr($msg,$i+8,length($msg) - $i - 8))."\n";
	} elsif (length($msg) > 0) {
		$dump .= getHex(substr($msg,$i,length($msg) - $i))."\n";
	}

	if ($profilename ne "") {
		$file = $profilename."_dump.txt";
	} else {
		$file = "dump.txt";
	}

	$file = "log/$file";

	open DUMP, ">> $file";
	print DUMP $dump;
	close DUMP;
	print "$dump\n" if $config{'debug'} >= 2;
	print "Message Dumped into DUMP.txt!\n";
}

sub dumpReceivePacket {
	my $msg = shift;
	my $dump;
	my $i;
	my $file;

	my $switch = uc(unpack("H2", substr($msg, 1, 1))).uc(unpack("H2", substr($msg, 0, 1)));
	my $msg_size = length($msg);

	$dump = "\n\n- Receive ".$switch." -----------------------------------\n".getFormattedDate(int(time))."\n\n".length($msg)." bytes\n\n";
	for ($i=0; $i + 15 < length($msg);$i += 16) {
		$dump .= getHex(substr($msg,$i,8))."    ".getHex(substr($msg,$i+8,8))."\n";
	}
	if (length($msg) - $i > 8) {
		$dump .= getHex(substr($msg,$i,8))."    ".getHex(substr($msg,$i+8,length($msg) - $i - 8))."\n";
	} elsif (length($msg) > 0) {
		$dump .= getHex(substr($msg,$i,length($msg) - $i))."\n";
	}

	if ($profilename ne "") {
		$file = $profilename."_dump.txt";
	} else {
		$file = "dump.txt";
	}

	$file = "log/$file";

	open DUMP, ">> $file";
	print DUMP $dump;
	close DUMP;
	print "$dump\n" if $config{'debug'} >= 2;
	print "$switch ($msg_size): Receive Packet Dumped!\n";
}

sub dumpSendPacket {
	my $msg = shift;
	my $dump;
	my $i;
	my $file;

	my $switch = uc(unpack("H2", substr($msg, 1, 1))).uc(unpack("H2", substr($msg, 0, 1)));
	my $msg_size = length($msg);

	$dump = "\n\n- Send ".$switch." --------------------------------------\n".getFormattedDate(int(time))."\n\n".length($msg)." bytes\n\n";
	for ($i=0; $i + 15 < length($msg);$i += 16) {
		$dump .= getHex(substr($msg,$i,8))."    ".getHex(substr($msg,$i+8,8))."\n";
	}
	if (length($msg) - $i > 8) {
		$dump .= getHex(substr($msg,$i,8))."    ".getHex(substr($msg,$i+8,length($msg) - $i - 8))."\n";
	} elsif (length($msg) > 0) {
		$dump .= getHex(substr($msg,$i,length($msg) - $i))."\n";
	}

	if ($profilename ne "") {
		$file = $profilename."_dump.txt";
	} else {
		$file = "dump.txt";
	}

	$file = "log/$file";

	open DUMP, ">> $file";
	print DUMP $dump;
	close DUMP;
	print "$dump\n" if $config{'debug'} >= 2;
	print "$switch ($msg_size): Send Packet Dumped!\n";
}

sub getField {
	my $file = shift;
	my $r_hash = shift;
	my $i, $data;
	undef %{$r_hash};
	if (!(-e $file)) {
		print "\n!!Could not load field from ".Win32::GetCwd()."\\$file!!\n\n";
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

sub getResponseCount {
	my $type = shift;
	my $count = shift;
	my $msg;
	$msg = getResponse($type.$count);
	if ($msg eq "") {
		$msg = getResponse($type);
	}
	return $msg;
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
			print "Loading $$_{'file'}...\n";
		} else {
			print "Error: Couldn't load $$_{'file'}\n";
		}
		&{$$_{'function'}}("$$_{'file'}", $$_{'hash'});
	}
}

sub parseArrayFile {
	my $file = shift;
	my $r_array = shift;
	undef @{$r_array};

	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;

		push @{$r_array}, $_;
	}
	close FILE;
}

sub parseCharFile {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $key, $id;

	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;

		($key, $id) = $_ =~ /^(\d+) (\d+)/;

		$key =~ s/\s//g;

		if ($key ne "") {
			$$r_hash{$key} = $id;
		}
	}
	close FILE;
}

sub parseListFile {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $key,$value;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key) = $_ =~ /([\s\S]*)/;
		if ($key ne "") {
			$$r_hash{lc($key)} = 1;
		}
	}
	close FILE;
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
			$$r_hash{lc($key)}{'teleport_search'} = $args[2];
			$$r_hash{lc($key)}{'attack_order'} = $args[3];
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
		# Enable empty value on response
		#($key, $value) = $_ =~ /([\s\S]*?) ([\s\S]*)$/;
		#if ($key ne "" && $value ne "") {
		($key, $value) = $_ =~ /\s*(\S+)\s*([\s\S]*)$/;
		if ($key ne "") {
			$i = 0;
			while (exists $$r_hash{"$key\_$i"}) {
				$i++;
			}

			$value =~ s/\s+$//g;
			#print "$i $key $value\n";
			$$r_hash{"$key\_$i"} = $value;
		}
	}
	close FILE;

	#foreach $key (keys %cmd_resps) {
	#	print "$key = $cmd_resps{$key}\n";
	#}
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

sub parseEmotionsFile {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $line, $key, $word, $name;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+$//g;

		$line = $_;
		($key, $word, $name) = $line =~ /^(\d+) (\S+) ([\s\S]*)$/;

		if ($key ne "") {
			$word =~ s/\^/\\^/g;
			$word =~ s/\+/\\+/g;
			$word =~ s/\./\\./g;
			$word =~ s/\?/\\?/g;
			$word =~ s/\$/\\\$/g;
			$word =~ s/\*/\\*/g;
			$word =~ s/\(/\\(/g;
			$word =~ s/\)/\\)/g;
			$word =~ s/\[/\\[/g;
			$$r_hash{$key}{'word'} = $word;
			$$r_hash{$key}{'name'} = $name;
		}
	}
	close FILE;
}

sub parseMonstersFile {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $line, $key, $name, $agg, $mob, $loot, $range;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+$//g;

		$line = $_;
		($agg, $mob, $loot, $range) = $line =~ / (\d+) (\d+) (\d+) (\d+)$/;
		if ($agg ne "" && $mob ne "" && $loot ne "" && $range ne "") {
			$line =~ s/ \d+ \d+ \d+ \d+$//g;
		}

		($key, $name) = $line =~ /([\s\S]*?) ([\s\S]*)$/;

		$key =~ s/\s//g;
		if ($key eq "") {
			($key) = $_ =~ /([\s\S]*)$/;
			$key =~ s/\s//g;
		}

		if ($key ne "") {
			$$r_hash{$key}{'name'} = $name;
			$$r_hash{$key}{'agg'} = $agg;
			$$r_hash{$key}{'mob'} = $mob;
			$$r_hash{$key}{'loot'} = $loot;
			$$r_hash{$key}{'range'} = $range;
		}
	}
	close FILE;
}

sub parseSkillsFile {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $line, $key, $nameID, $name;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+$//g;

		$line = $_;
		($key, $nameID, $name) = $line =~ /^(\d+) (\S+) ([\s\S]*)$/;

		if ($key ne "") {
			$$r_hash{$key}{'nameID'} = $nameID;
			$$r_hash{$key}{'name'} = $name;
		}
	}
	close FILE;
}

sub parseSkillsFileReverse {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $line, $id, $nameID, $name;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+$//g;

		$line = $_;
		($id, $nameID, $name) = $line =~ /^(\d+) (\S+) ([\s\S]*)$/;

		if ($name ne "") {
			$$r_hash{lc($name)}{'nameID'} = $nameID;
			$$r_hash{lc($name)}{'ID'} = $id;
		}
	}
	close FILE;
}

sub parsePacketsFile {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $key, $length, $desc;

	if (-e $file) {
		print "Loading $file...\n";

		open FILE, $file;
		foreach (<FILE>) {
			next if (/^#/);
			s/[\r\n]//g;
			s/\s+$//g;

			$line = $_;
			($key, $length) = $line =~ /^([\d\S]+) ([\d\S]+)/;
			($desc) = $line =~ /^[\d\S]+ [\d\S]+ ([\s\S]*)$/;

			$key =~ s/\s//g;
			$desc =~ s/^\s+//g;

			#print "$key $length $desc\n";
			if ($key ne "") {
				$$r_hash{$key}{'length'} = $length;
				$$r_hash{$key}{'desc'} = $desc;
			}
		}
		close FILE;
		return 1;
	} else {
		print "Error: Couldn't load $file\n";
		return 0;
	}
}

sub WritePacketsFile {
	my $file = shift;
	my $r_hash = shift;
	my $i;
	my $id;

	open FILE, "> $file";

	print FILE "# <switch> <length> <description>\n";

	my @id_sort = sort { $a cmp $b } keys %{$r_hash};
	my $total = @{id_sort};

	print FILE "# Total Packets: $total\n";

	for ($i = 0; $i < @{id_sort}; $i++) {
		$id = $id_sort[$i];
		print FILE "$id $$r_hash{$id}{'length'} $$r_hash{$id}{'desc'}\n";
	}

	close FILE;
}

sub WriteSkillsLUT {
	my $file = shift;
	my $r_hash = shift;
	my $i;
	my $id;

	open FILE, "> $file";

	print FILE "# A default english table has been provided\n";
	print FILE "# Remove all lines below to have Kore auto-generate this table\n";

	my @id_sort = sort { $a <=> $b } keys %{$r_hash};
	my $total = @{id_sort};

	print FILE "# Total Skills: $total\n";

	for ($i = 0; $i < @{id_sort}; $i++) {
		$id = $id_sort[$i];
		print FILE "$id $$r_hash{$id}{'nameID'} $$r_hash{$id}{'name'}\n";
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

sub WriteMonstersLUT {
	my $file = shift;
	my $r_hash = shift;
	my $i;
	my $id;

	open FILE, "> $file";

	print FILE "# A default english table has been provided\n";
	print FILE "# Remove all lines below to have Kore auto-generate this table\n";

	my @id_sort = sort { $a <=> $b } keys %{$r_hash};
	my $total_mon = @{id_sort};

	print FILE "# Total Monster: $total_mon\n";
	print FILE "#<id> <name> <agg flag> <mob flag> <loot flag> <attack range>\n";
	print FILE "#<agg flag> 1 = Aggressive, 2 = Aggressive on skill\n";

	for ($i = 0; $i < @{id_sort}; $i++) {
		$id = $id_sort[$i];
		print FILE "$id $$r_hash{$id}{'name'} $$r_hash{$id}{'agg'} $$r_hash{$id}{'mob'} $$r_hash{$id}{'loot'} $$r_hash{$id}{'range'}\n";
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

sub WriteNPCLUT {
	my $file = shift;
	my $r_hash = shift;
	my $i;
	my $id;

	open FILE, "> $file";

	print FILE "# A default english table has been provided\n";
	print FILE "# Remove all lines below to have Kore auto-generate this table\n";

	my @id_sort = sort { $a <=> $b } keys %{$r_hash};
	my $total_npc = @{id_sort};

	print FILE "# Total NPC: $total_npc\n";

	for ($i = 0; $i < @{id_sort}; $i++) {
		$id = $id_sort[$i];
		print FILE "$id $$r_hash{$id}{'map'} $$r_hash{$id}{'pos'}{'x'} $$r_hash{$id}{'pos'}{'y'} $$r_hash{$id}{'name'}\n";
	}

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

sub binCount {
	my $r_array = shift;
	my $ID = shift;
	my $i;
	my $count = 0;
	for ($i = 0; $i < @{$r_array};$i++) {
		if ($$r_array[$i] eq $ID) {
			$count++;
		}
	}

	return $count;
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

sub findIndexStringList_lc {
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my $i;
	my @aID = split /,/, $ID;

	foreach (@aID) {
		s/^\s+//;
		s/\s+$//;
		s/\s+/ /g;
		next if ($_ eq "");

		for ($i = 0; $i < @{$r_array} ;$i++) {
			if ((%{$$r_array[$i]} && lc($$r_array[$i]{$match}) eq lc($_))
				|| (!%{$$r_array[$i]} && $_ eq "")) {
				return $i;
			}
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
		}
	} elsif (%{$monsters{$ID1}}) {
		if (%{$players{$ID2}}) {
			$monsters{$ID1}{'dmgFrom'} += $damage;
			$monsters{$ID1}{'dmgToPlayer'}{$ID2} += $damage;
			$monsters{$ID1}{'dmgToPlayers'} += $damage;
			$players{$ID2}{'dmgFromMonster'}{$ID1} += $damage;
			if ($damage == 0) {
				$monsters{$ID1}{'missedToPlayer'}{$ID2}++;
				$monsters{$ID1}{'missedToPlayers'}++;
				$players{$ID2}{'missedFromMonster'}{$ID1}++;
			}

			if (IsPartyOnline($ID2)) {
				$monsters{$ID1}{'dmgToParty'} += $damage;
				if ($damage == 0) {
					$monsters{$ID1}{'missedToParty'}++;
				}
			}
		}

	} elsif (%{$players{$ID1}}) {
		if (%{$monsters{$ID2}}) {
			$monsters{$ID2}{'dmgTo'} += $damage;
			$monsters{$ID2}{'dmgFromPlayer'}{$ID1} += $damage;
			$monsters{$ID2}{'dmgFromPlayers'} += $damage;
			$players{$ID1}{'dmgToMonster'}{$ID2} += $damage;
			if ($damage == 0) {
				$monsters{$ID2}{'missedFromPlayer'}{$ID1}++;
				$monsters{$ID2}{'missedFromPlayers'}++;
				$players{$ID1}{'missedToMonster'}{$ID2}++;
			}

			if (IsPartyOnline($ID1)) {
				$monsters{$ID2}{'dmgFromParty'} += $damage;
				if ($damage == 0) {
					$monsters{$ID2}{'missedFromParty'}++;
				}
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
						getField("fields/$map.fld", \%field);
					}
					print "Calculating portal route $portal -> $_\n";
					ai_route_getRoute(\@solution, \%field, \%{$mapPortals{$map}{$portal}{'pos'}}, \%{$mapPortals{$map}{$_}{'pos'}});
					compilePortals_getRoute();
					$portals_los{$portal}{$_} = (@solution) ? 1 : 0;
				}
			}
		}
	}

	writePortalsLOS("tables/portalsLOS.txt", \%portals_los);

	print "Wrote portals Line of Sight table to 'tables/portalsLOS.txt'\n";
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
        $$r_date = "$themonth $localtime[3] $localtime[2]:$localtime[1]:$localtime[0] " . ($localtime[5] + 1900);
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

sub ShopOpen {
	my $r_socket = shift;
	my $i = 0;
	my $index;
	my @indices;
	my $skip;
	my $amount;
	my $count = 0;
	my $msg = "";

	exit if (!$config{"shopAuto"});

	while ($config{"shop_item_$i"} ne "") {
		for ($index = 0; $index < @{$cart{'inventory'}}; $index++) {
			$skip = 0;
			foreach (@indices) {
				if ($index == $_) {
					$skip = 1;
					last;
				}
			}

			if ($skip == 0 && $cart{'inventory'}[$index]{'name'} eq $config{"shop_item_$i"} && $config{"shop_item_$i"."_price"} > 0 && $cart{'inventory'}[$index]{'amount'} >= $config{"shop_item_$i"."_minAmount"}) {
				push @indices, $index;

				$amount = $config{"shop_item_$i"."_maxAmount"};
				if ($amount > $cart{'inventory'}[$index]{'amount'}) {
					$amount = $cart{'inventory'}[$index]{'amount'};
				}

				$msg .= pack("S*", $index) . pack("S*", $amount) . pack("L*", $config{"shop_item_$i"."_price"});
				$count++;
				last;
			}
		}

		last if ($count >= $shop{'items_max'});
		$i++;
	}

	my $length = 0x54 + 0x08 * $count;
	$msg = pack("C*", 0x2F, 0x01).pack("S*", $length).$config{'shopAuto_title'}.chr(0) x (36 - length($config{'shopAuto_title'})).chr(0) x (44).$msg;

	if (length($msg) == $length) {
		encrypt(\$encryptMsg, $msg);
		sendToServerByInject($r_socket, $encryptMsg);
		print "Shop Opened.\n";
		$chars[$config{'char'}]{'shop'} = 1;
		sit();
	}
}

sub ShopClose {
	my $r_socket = shift;
	my $msg = pack("C*", 0x2E, 0x01);
	encrypt(\$encryptMsg, $msg);
	sendToServerByInject($r_socket, $encryptMsg);
	print "Shop Closed\n" if ($config{'debug'} >= 2);

	undef %shop;
	$chars[$config{'char'}]{'shop'} = 0;
	stand();
}

sub findIndexString_lc_equip {
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array} ;$i++) {
		if ((%{$$r_array[$i]} && lc($$r_array[$i]{$match}) eq lc($ID) && ($$r_array[$i]{'equipped'}))
			 || (!%{$$r_array[$i]} && $ID eq "")) {
			return $i;
		}
	}
	if ($ID eq "") {
		return $i;
	}
}

sub findIndexString_lc_not_equip {
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my $index = shift;
	my $i;

	for ($i = 0; $i < @{$r_array} ;$i++) {
		next if ($i == $index);

		if ((%{$$r_array[$i]} && lc($$r_array[$i]{$match}) eq lc($ID) && !($$r_array[$i]{'equipped'}))
			 || (!%{$$r_array[$i]} && $ID eq "")) {
			return $i;
		}
	}
	if ($ID eq "") {
		return $i;
	}
}

sub GotStatus {
	my $unit = shift;
	my $status = shift;

	if (existsInList($status, $$unit{'status_critical'}) ||
		existsInList($status, $$unit{'status_warning'}) ||
		existsInList($status, $$unit{'status_option'})) {
		return 1;
	}

	return 0;
}

sub LostStatus {
	my $unit = shift;
	my $status = shift;

	if (!existsInList($status, $$unit{'status_critical'}) &&
		!existsInList($status, $$unit{'status_warning'}) &&
		!existsInList($status, $$unit{'status_option'})) {
		return 1;
	}

	return 0;
}

sub EffectInList {
	my $list = shift;
	@array = split /,/, $list;
	return 0 if ($list eq "");
	foreach (@array) {
		s/^\s+//;
		s/\s+$//;
		s/\s+/ /g;
		next if ($_ eq "");
		return 1 if ($chars[$config{'char'}]{'effect'}{$effects_rlut{lc($_)}{'ID'}});
	}
	return 0;
}

sub NoEffectInList {
	my $list = shift;
	@array = split /,/, $list;
	return 0 if ($list eq "");
	foreach (@array) {
		s/^\s+//;
		s/\s+$//;
		s/\s+/ /g;
		next if ($_ eq "");
		return 0 if ($chars[$config{'char'}]{'effect'}{$effects_rlut{lc($_)}{'ID'}});
	}
	return 1;
}

sub PadStr {
	my $s = shift;
	my $pad = shift;

	if ($pad ne "") {
		if ($s ne "") {
			$s .= ", $pad";
		} else {
			$s = $pad;
		}
	}

	return $s;
}

sub PlaySound {
	my $file = shift;

	if (!$config{'buildType'}) {
		#Win32::Sound::Volume('100%');
 		Win32::Sound::Play($file);
	}
}

sub WriteLog {
	my $file = shift;
	my $msg = shift;

	if ($profilename ne "") {
		$file = $profilename."_".$file;
	}

	$file = "log/$file";

	open TEXT, ">> $file";
	print TEXT "[".getFormattedDate(int(time))."] $msg";
	close TEXT;
}

sub GetBodyDir {
	my $r_pos = shift;
	my $r_pos_to = shift;
	my $dx;
	my $dy;
	my $body = 0;

	$dx = $$r_pos{'x'} - $$r_pos_to{'x'};
	$dy = $$r_pos{'y'} - $$r_pos_to{'y'};

	#print "DX: $dx, DY: $dy\n";
	if ($dx < 0) {
		if ($dy < 0) {
			$body = 7;
		} elsif ($dy > 0) {
			$body = 5;
		} else {
			$body = 6;
		}
	} elsif ($dx > 0) {
		if ($dy < 0) {
			$body = 1;
		} elsif ($dy > 0) {
			$body = 3;
		} else {
			$body = 2;
		}
	} else {
		if ($dy < 0) {
			$body = 0;
		} elsif ($dy > 0) {
			$body = 4;
		}
	}

	return $body;
}

sub AlignWalk {
	my $r_pos = shift;
	my $r_pos_to = shift;
	my $dx;
	my $dy;
	my $x = -1;
	my $y = -1;
	my $lenA = -1;
	my $lenB = -1;

	$dx = abs($$r_pos{'x'} - $$r_pos_to{'x'});
	$dy = abs($$r_pos{'y'} - $$r_pos_to{'y'});

	if ($dx - $dy > 5) {
		$x = $$r_pos{'x'};
		$y = $$r_pos{'y'};
		do {
			last if($x < 0 || $x >= $field{'width'} || $y < 0 || $y >= $field{'height'});
			$y--;
			$lenA++;
		} while (!$field{'field'}[$y * $field{'width'} + $x]);

		$y = $$r_pos{'y'};
		do {
			last if($x < 0 || $x >= $field{'width'} || $y < 0 || $y >= $field{'height'});
			$y++;
			$lenB++;
		} while (!$field{'field'}[$y * $field{'width'} + $x]);

		#print "V: A = $lenA, B = $lenB\n";
		$y = $$r_pos{'y'};
		if ($lenA + $lenB < 20) {
			if ($lenA > $lenB) {
				$y -= ((($lenA + $lenB) / 2) - $lenB);
			} elsif ($lenB > $lenA) {
				$y += ((($lenA + $lenB) / 2) - $lenA);
			}
		}
	} elsif ($dy - $dx > 5) {
		$x = $$r_pos{'x'};
		$y = $$r_pos{'y'};
		do {
			last if($x < 0 || $x >= $field{'width'} || $y < 0 || $y >= $field{'height'});
			$x--;
			$lenA++;
		} while (!$field{'field'}[$y * $field{'width'} + $x]);

		$x = $$r_pos{'x'};
		do {
			last if($x < 0 || $x >= $field{'width'} || $y < 0 || $y >= $field{'height'});
			$x++;
			$lenB++;
		} while (!$field{'field'}[$y * $field{'width'} + $x]);

		#print "H: A = $lenA, B = $lenB\n";
		$x = $$r_pos{'x'};
		if ($lenA + $lenB < 20) {
			if ($lenA > $lenB) {
				$x -= ((($lenA + $lenB) / 2) - $lenB);
			} elsif ($lenB > $lenA) {
				$x += ((($lenA + $lenB) / 2) - $lenA);
			}
		}
	}

	my @ret = ($x, $y);
	return @ret;
}

sub GetWallLength {
	my $r_pos = shift;
	my $dx = shift;
	my $dy = shift;
	my $x;
	my $y;
	my $len = 0;

	$x = $$r_pos{'x'};
	$y = $$r_pos{'y'};

	do {
		last if($x < 0 || $x >= $field{'width'} || $y < 0 || $y >= $field{'height'});

		$x += $dx;
		$y += $dy;
		$len++;
	} while ($field{'field'}[$y * $field{'width'} + $x]);

	#print "- Wall length at $$r_pos{'x'}, $$r_pos{'y'} $dx $dy is $len\n";
	return $len;
}

sub IsAttackAble {
	my $r_pos = shift;
	my $r_pos_to = shift;
	my $distance;
	my $i;
	my %vector;
	my %pos;

	if ($config{'attackAuto_noWall'}) {
		return 1;
	}

	$distance = distance($r_pos, $r_pos_to);

	#print "$$r_pos{'x'}, $$r_pos{'y'} -> $$r_pos_to{'x'}, $$r_pos_to{'y'} DIST: $distance\n";
	getVector(\%{vector}, $r_pos, $r_pos_to);
	for ($i = 1; $i < $distance; $i++) {
		moveAlongVector(\%{pos}, $r_pos, \%{vector}, -$i);
		$pos{'x'} = int($pos{'x'});
		$pos{'y'} = int($pos{'y'});
		#print "- $pos{'x'}, $pos{'y'} $i $distance\n";
		if ($field{'field'}[$pos{'y'} * $field{'width'} + $pos{'x'}]) {
			#print "- Found wall at $pos{'x'}, $pos{'y'}\n";
			if (GetWallLength(\%{pos}, -1, 0) > 5 || GetWallLength(\%{pos}, 1, 0) > 5 ||
				GetWallLength(\%{pos}, 0, -1) > 5 || GetWallLength(\%{pos}, 0, 1) > 5 ||
				GetWallLength(\%{pos}, -1, -1) > 5 || GetWallLength(\%{pos}, 1, 1) > 5 ||
				GetWallLength(\%{pos}, 1, -1) > 5 || GetWallLength(\%{pos}, -1, 1) > 5) {
				#print "- Can not attack.\n";
				return 0;
			}
		}
	}

	#print "- Attack able.\n";
	return 1;
}

sub IsWarpAble {
	my $invIndex;

	if ($chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} > 1) {
		return 1;
	}

	$invIndex = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", "Butterfly Wing");
	if ($invIndex ne "") {
		return 1;
	}

	return 0;
}

sub GenName {
	my $inv = shift;
	my @cards;
	my $count = 0;
	my $i;
	my $j;
	my $name;
	my $special;
	my $enchant;
	my $strong;
	my $element;
	my $nameL;
	my $nameR;

	if ($inv->{'cardID_1'} != 255) {
		for($i = 1; $i < 5; $i++) {
			if ($inv->{"cardID_$i"} ne "") {
				for($j = 0; $j < $count; $j++) {
					if($inv->{"cardID_$i"} eq $cards[$j]{'ID'}) {
						$cards[$j]{'amount'}++;
						last;
					}
				}

				if ($j >= $count) {
					$cards[$j]{'amount'} = 1;
					$cards[$j]{'name'} = $cards_lut{$inv->{"cardID_$i"}};
					$cards[$j]{'prefix'} = $cardsPrefix_lut{$inv->{"cardID_$i"}};
					$cards[$j]{'ID'} = $inv->{"cardID_$i"};
					$count++;
				}
			}
		}

		($nameL, $nameR) = GenCard(\%{@cards});

		$inv->{'nameL'} = $nameL;
		$inv->{'nameR'} = $nameR;
	}

	if ($inv->{'cardID_1'} == 0 &&
		$inv->{'cardID_4'} == 1) {
		# Egg
		$nameL = '[';
		$nameR = ']';

		$inv->{'nameL'} = $nameL;
		$inv->{'nameR'} = $nameR;
	}

	$name = ($items_lut{$inv->{'nameID'}} ne "") ? $items_lut{$inv->{'nameID'}} : "Unknown ".$inv->{'nameID'};

	$special = "";
	if ($inv->{'special'} > 0) {
		$special = "# ";
	}

	$enchant = "";
	if ($inv->{'refine'} > 0) {
		$enchant = "+$inv->{'refine'} ";
	}

	$strong = "";
	if ($inv->{'strongName'} ne "") {
		$strong = "$inv->{'strongName'} ";
	}

	$element = "";
	if ($inv->{'elementName'} ne "") {
		$element = "$inv->{'elementName'} ";
	}

	if($nameL ne "" && $nameL ne "[") {
		$nameL = "$nameL ";
	}

	if($nameR ne "" && $nameR ne "]") {
		$nameR = " $nameR";
	}

	$inv->{'name'} = $special.$enchant.$strong.$element.$nameL.$name.$nameR;
}

sub GenCard {
	my $cards = shift;
	my $nameL = "";
	my $nameR = "";
	my $prefix;
	my $h;

	foreach $h (@{$cards}) {
		if ($$h{'prefix'} =~ /^of /i) {
			($prefix) = $$h{'prefix'} =~ /^[\s\S]*? (\w+)/;

			if ($nameR ne "") {
				$nameR .= " ";
			}

			if ($$h{'amount'} == 4) {
				$nameR .= "of Quadruple $prefix";
			} elsif ($$h{'amount'} == 3) {
				$nameR .= "of Triple $prefix";
			} elsif ($$h{'amount'} == 2) {
				$nameR .= "of Double $prefix";
			} else {
				$nameR .= "of $prefix";
			}
		} elsif ($$h{'prefix'} ne "") {
			$prefix = $$h{'prefix'};

			if ($nameL ne "") {
				$nameL .= "'s ";
			}

			if ($$h{'amount'} == 4) {
				$nameL .= "Quadruple $prefix";
			} elsif ($$h{'amount'} == 3) {
				$nameL .= "Triple $prefix";
			} elsif ($$h{'amount'} == 2) {
				$nameL .= "Double $prefix";
			} else {
				$nameL .= "$prefix";
			}
		}
	}

	my @ret = ($nameL, $nameR);
	return @ret;
}

sub GetRandPosition {
	my $range = shift;
	my $x_pos = shift;
	my $y_pos = shift;
	my $x_rand;
	my $y_rand;
	my $x;
	my $y;

	if ($x_pos eq "" || $y_pos eq "") {
		$x_pos = $chars[$config{'char'}]{'pos_to'}{'x'};
		$y_pos = $chars[$config{'char'}]{'pos_to'}{'y'};
	}

	do {
		$x_rand = int(rand($range)) + 1;
		$y_rand = int(rand($range)) + 1;

		if (int(rand(2))) {
			$x = $x_pos + $x_rand;
		} else {
			$x = $x_pos - $x_rand;
		}

		if (int(rand(2))) {
			$y = $y_pos + $y_rand;
		} else {
			$y = $y_pos - $y_rand;
		}
	} while ($field{'field'}[$y * $field{'width'} + $x]);

	my @ret = ($x, $y);
	return @ret;
}

sub ParseCmdResps {
	my $msg = shift;
	my $key;
	my $count;
	my $cmd;
	my @words;
	my $word;

	$msg =~ s/^\s+//g;
	$msg =~ s/\s+$//g;

	foreach $key (keys %cmd_resps) {
		@words = split /\s/,$cmd_resps{$key};
		if (@words == 1) {
			if ($msg eq $cmd_resps{$key}) {
				($cmd) = $key =~ /(\w+)\_\d+$/;
				return $cmd;
			}
		} else {
			$count = 0;
			foreach (@words) {
				$word = $_;
				$word =~ s/\^/\\^/g;
				$word =~ s/\+/\\+/g;
				$word =~ s/\./\\./g;
				$word =~ s/\?/\\?/g;
				$word =~ s/\$/\\\$/g;
				$word =~ s/\*/\\*/g;
				$word =~ s/\(/\\(/g;
				$word =~ s/\)/\\)/g;
				$word =~ s/\[/\\[/g;
				if ($msg =~ /.*($word).*/i) {
					#print "$key = $_\n";
					$count++;
				} else {
					last;
				}
			}

			if ($count == @words) {
				($cmd) = $key =~ /(\w+)\_\d+$/;
				return $cmd;
			}
		}
	}

	return "";
}

sub ParseEmotion {
	my $msg = shift;
	my $emo;
	my $i;

	$emo = -1;
	foreach (keys %emotions_lut) {
		if ($msg =~ /^\s*?\/$emotions_lut{$_}{'word'}/i) {
			if ($emo < 0 || length($emotions_lut{$_}{'word'}) > length($emotions_lut{$emo}{'word'})) {
				$emo = $_;
				#print "$emotions_lut{$_}{'word'} ";
			}
		}
	}

	return $emo;
}

sub ParseSkill {
	my $msg = shift;
	my $id;
	my $name;
	my $count;
	my @words;
	my $word;

	@words = split /\s/,$msg;

	foreach $id (@skillsID) {
		$name = $skills_lut{$id};

		$count = 0;
# Quantifier follows nothing in regex; marked by <-- HERE in m/.*(+ <-- HERE 8).*/ at kpp.pl line 14178.
# Unmatched ( in regex; marked by <-- HERE in m/.*( <-- HERE (บ้าการ์ตูน).*/ at kpp.pl line 15475.
		foreach (@words) {
			$word = $_;
			$word =~ s/\^/\\^/g;
			$word =~ s/\+/\\+/g;
			$word =~ s/\./\\./g;
			$word =~ s/\?/\\?/g;
			$word =~ s/\$/\\\$/g;
			$word =~ s/\*/\\*/g;
			$word =~ s/\(/\\(/g;
			$word =~ s/\)/\\)/g;
			$word =~ s/\[/\\[/g;

			if ($name =~ /.*($word).*/i) {
				$count++;
			} else {
				last;
			}
		}

		if ($count == @words) {
			return $id;
		}
	}

	return "";
}

sub EquipByType {
	my $type = shift;
	my $i;

	for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}}; $i++) {
		next if (!%{$chars[$config{'char'}]{'inventory'}[$i]});

		if (($chars[$config{'char'}]{'inventory'}[$i]{'equipped'} & $type) != 0) {
			return $i;
		}
	}

	return "";
}

sub UnEquipByType {
	my $type = shift;
	my $i;

	for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}}; $i++) {
		next if (!%{$chars[$config{'char'}]{'inventory'}[$i]});

		if (($chars[$config{'char'}]{'inventory'}[$i]{'equipped'} & $type) != 0) {
			sendUnequip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$i]{'index'});
			return $i;
		}
	}

	return "";
}

sub IsEquipedItem {
	my $name = shift;
	my $type = shift;
	my $invIndex = "";

	$invIndex = EquipByType($type);
	if ($name ne "" && $invIndex ne "" && $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} eq $name) {
		return 1;
	}

	return 0;
}

sub EquipItem {
	my $name = shift;
	my $type = shift;
	my $invSkipIndex = shift;
	my $invIndex = "";
	my $index;
	my $type_equip;

	$invIndex = EquipByType($type);

	if ($name ne "" && $invIndex ne "" && $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} eq $name) {
		PrintMessage("- Equipped: $name", "gray");
	} else {
		 if (lc($name) eq "none") {
			$invIndex = UnEquipByType($type);
			if ($invIndex ne "") {
				PrintMessage("- Unequip $equipTypes_lut{$type}: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}", "gray");
			}
		} elsif ($name ne "") {
			$invIndex = findIndexString_lc_not_equip(\@{$chars[$config{'char'}]{'inventory'}}, "name", $name, $invSkipIndex);
			if ($invIndex ne "") {
				if (!$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}) {
					PrintMessage("- Equip Carry: $name", "gray");
				} else {
					PrintMessage("- Equip $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}}: $name", "gray");
				}

				$index = $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'};
				$type_equip = $chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'};

				if ($type_equip != 34) {
					UnEquipByType($type);
				}

				if ($type_equip == 256 || $type_equip == 513) {
					sendEquip(\$remote_socket, $index, 0, 1);
				} elsif ($type_equip == 512) {
					sendEquip(\$remote_socket, $index, 0, 2);
				} elsif ($type == 32) {
					sendEquip(\$remote_socket, $index, 32, 0);
				} else {
					sendEquip(\$remote_socket, $index, $type_equip, 0);
				}
			}
		}
	}

	if ($invIndex eq "") {
		return -1;
	}

	return $invIndex;
}

sub EquipSlot {
	my $i = shift;
	my $invIndex;

	if ($config{"equipAuto_$i"."_top_head"} ne "") {
		EquipItem($config{"equipAuto_$i"."_top_head"}, 256, -1);
	}

	if ($config{"equipAuto_$i"."_mid_head"} ne "") {
		EquipItem($config{"equipAuto_$i"."_mid_head"}, 512, -1);
	}

	if ($config{"equipAuto_$i"."_low_head"} ne "") {
		EquipItem($config{"equipAuto_$i"."_low_head"}, 1, -1);
	}

	if ($config{"equipAuto_$i"."_body"} ne "") {
		EquipItem($config{"equipAuto_$i"."_body"}, 16, -1);
	}

	if ($config{"equipAuto_$i"."_right_hand"} ne "") {
		$invIndex = EquipItem($config{"equipAuto_$i"."_right_hand"}, 2, -1);
	}

	if ($config{"equipAuto_$i"."_left_hand"} ne "") {
		EquipItem($config{"equipAuto_$i"."_left_hand"}, 32, $invIndex);
	}

	if ($config{"equipAuto_$i"."_robe"} ne "") {
		EquipItem($config{"equipAuto_$i"."_robe"}, 4, -1);
	}

	if ($config{"equipAuto_$i"."_shoes"} ne "") {
		EquipItem($config{"equipAuto_$i"."_shoes"}, 64, -1);
	}

	if ($config{"equipAuto_$i"."_right_accessory"} ne "") {
		EquipItem($config{"equipAuto_$i"."_right_accessory"}, 128, -1);
	}

	if ($config{"equipAuto_$i"."_left_accessory"} ne "") {
		EquipItem($config{"equipAuto_$i"."_left_accessory"}, 8, -1);
	}

	if ($config{"equipAuto_$i"."_carry"} ne "") {
		EquipItem($config{"equipAuto_$i"."_carry"}, 1024, -1);
	}
}

sub IsEquipedSlot {
	my $i = shift;

	if ($config{"equipAuto_$i"."_top_head"} ne "") {
		if (IsEquipedItem($config{"equipAuto_$i"."_top_head"}, 256) == 0) {
			return 0;
		}
	}

	if ($config{"equipAuto_$i"."_mid_head"} ne "") {
		if (IsEquipedItem($config{"equipAuto_$i"."_mid_head"}, 512) == 0) {
			return 0;
		}
	}

	if ($config{"equipAuto_$i"."_low_head"} ne "") {
		if (IsEquipedItem($config{"equipAuto_$i"."_low_head"}, 1) == 0) {
			return 0;
		}
	}

	if ($config{"equipAuto_$i"."_body"} ne "") {
		if (IsEquipedItem($config{"equipAuto_$i"."_body"}, 16) == 0) {
			return 0;
		}
	}

	if ($config{"equipAuto_$i"."_right_hand"} ne "") {
		if (IsEquipedItem($config{"equipAuto_$i"."_right_hand"}, 2) == 0) {
			return 0;
		}
	}

	if ($config{"equipAuto_$i"."_left_hand"} ne "") {
		if (IsEquipedItem($config{"equipAuto_$i"."_left_hand"}, 32) == 0) {
			return 0;
		}
	}

	if ($config{"equipAuto_$i"."_robe"} ne "") {
		if (IsEquipedItem($config{"equipAuto_$i"."_robe"}, 4) == 0) {
			return 0;
		}
	}

	if ($config{"equipAuto_$i"."_shoes"} ne "") {
		if (IsEquipedItem($config{"equipAuto_$i"."_shoes"}, 64) == 0) {
			return 0;
		}
	}

	if ($config{"equipAuto_$i"."_right_accessory"} ne "") {
		if (IsEquipedItem($config{"equipAuto_$i"."_right_accessory"}, 128) == 0) {
			return 0;
		}
	}

	if ($config{"equipAuto_$i"."_left_accessory"} ne "") {
		if (IsEquipedItem($config{"equipAuto_$i"."_left_accessory"}, 8) == 0) {
			return 0;
		}
	}

	if ($config{"equipAuto_$i"."_carry"} ne "") {
		if (IsEquipedItem($config{"equipAuto_$i"."_carry"}, 1024) == 0) {
			return 0;
		}
	}

	return 1;
}

sub IsEquipSlot {
	my $i = shift;

	if ($config{"equipAuto_$i"."_top_head"} ne "" ||
		$config{"equipAuto_$i"."_mid_head"} ne "" ||
		$config{"equipAuto_$i"."_low_head"} ne "" ||
		$config{"equipAuto_$i"."_body"} ne "" ||
		$config{"equipAuto_$i"."_right_hand"} ne "" ||
		$config{"equipAuto_$i"."_left_hand"} ne "" ||
		$config{"equipAuto_$i"."_robe"} ne "" ||
		$config{"equipAuto_$i"."_shoes"} ne "" ||
		$config{"equipAuto_$i"."_right_accessory"} ne "" ||
		$config{"equipAuto_$i"."_left_accessory"} ne "" ||
		$config{"equipAuto_$i"."_carry"} ne "") {
		return 1;
	}

	return 0;
}

sub SetStatus {
	my $unit = shift;
	my $critical = shift;
	my $warning = shift;
	my $option = shift;
	my $name;
	my $status;

	if ($critical == 1) {
		$$unit{'status_critical'} = "stone";
	} elsif ($critical == 2) {
		$$unit{'status_critical'} = "frozen";
	} elsif ($critical == 3) {
		$$unit{'status_critical'} = "stun";
	} elsif ($critical == 4) {
		$$unit{'status_critical'} = "sleep";
	} elsif ($critical) {
		$$unit{'status_critical'} = "$critical";
	} else {
		undef $$unit{'status_critical'};
	}

	if ($warning == 1) {
		$$unit{'status_warning'} = "poison";
	} elsif ($warning == 2) {
		$$unit{'status_warning'} = "curse";
	} elsif ($warning == 4) {
		$$unit{'status_warning'} = "silence";
	} elsif ($warning == 16) {
		$$unit{'status_warning'} = "darkness";
	} elsif ($warning) {
		$$unit{'status_warning'} = "$warning";
	} else {
		undef $$unit{'status_warning'};
	}

	if ($option == 1) {
		$$unit{'status_option'} = "sight";
	} elsif ($option == 2) {
		$$unit{'status_option'} = "hiding";
	} elsif ($option == 4) {
		$$unit{'status_option'} = "cloaking";
	} elsif ($option == 8) {
		$$unit{'status_option'} = "cart";
	} elsif ($option == 16) {
		$$unit{'status_option'} = "falcon";
	} elsif ($option == 32) {
		$$unit{'status_option'} = "peco peco";
	} elsif ($option == 64) {
		$$unit{'status_option'} = "invisibility";
	} elsif ($option == 128) {
		$$unit{'status_option'} = "cart type 1";
	} elsif ($option == 256) {
		$$unit{'status_option'} = "cart type 2";
	} elsif ($option == 512) {
		$$unit{'status_option'} = "cart type 3";
	} elsif ($option == 1024) {
		$$unit{'status_option'} = "cart type 4";
	} elsif ($option) {
		$$unit{'status_option'} = "$option";
	} else {
		undef $$unit{'status_option'};
	}
}

sub GenShowName {
	my $inv = shift;
	my $name;
	my $slots = $itemsSlotCount_lut{$inv->{'nameID'}};

	if ($inv->{'cardID_1'} != 255 && $slots > 0) {
		$name = "$inv->{'name'} [$slots]";
	} else {
		$name = "$inv->{'name'}";
	}

	return $name;
}

sub IsEquipment {
	my $item = shift;
	my $slots = $itemsSlotCount_lut{$item->{'nameID'}};
	my $type = $itemTypes_lut{$item->{'type'}};

	if ($slots ne "") {
		return 1;
	} elsif (($type =~ /^(Armour).*/i) ||
		($type =~ /^(Weapon).*/i) ||
		($type =~ /^(Helmet).*/i) ||
		($type =~ /^(Arrow).*/i) ||
		($type =~ /^(Mask).*/i)) {
		return 1;
	}

	return 0;
}

sub Name {
	my $id = shift;
	my $name;

	if (%{$monsters{$id}}) {
		$name = "$monsters{$id}{'name'}";
	} elsif (%{$players{$id}}) {
		$name = ($players{$id}{'name'} eq "Unknown") ? getHex($id) : "$players{$id}{'name'}";
	} elsif ($id eq $chars[$config{'char'}]{'pet'}{'ID'}) {
		$name = "[PET] $chars[$config{'char'}]{'pet'}{'name'}";
	} elsif (%{$pets{$id}}) {
		$name = ($pets{$id}{'name_given'} eq "Unknown" || $pets{$id}{'name_given'} eq "") ? "[PET] $pets{$id}{'name'}" : "[PET] $pets{$id}{'name_given'}";
	} elsif (%{$items{$id}}) {
		$name = "$items{$id}{'name'}";
	} elsif ($id eq $accountID) {
		$name = "$chars[$config{'char'}]{'name'}";
	} else {
		$name = getHex($id);
	}

	return $name;
}

sub IsParty {
	my $id = shift;

	if (%{$chars[$config{'char'}]{'party'}{'users'}{$id}}) {
		return 1;
	}

	return 0;
}

sub IsPartyOnline {
	my $id = shift;

	if (%{$chars[$config{'char'}]{'party'}{'users'}{$id}} &&
		$chars[$config{'char'}]{'party'}{'users'}{$id}{'online'}) {
		return 1;
	}

	return 0;
}

sub IsPartyName {
	my $id = shift;
	my $name = shift;

	if (%{$chars[$config{'char'}]{'party'}{'users'}{$id}} &&
		$chars[$config{'char'}]{'party'}{'users'}{$id}{'name'} eq $name) {
		return 1;
	}

	return 0;
}

sub IsPartyMove {
	my $id = shift;

	if (%{$chars[$config{'char'}]{'party'}{'users'}{$id}} &&
		$chars[$config{'char'}]{'party'}{'users'}{$id}{'move'}) {
		return 1;
	}

	return 0;
}

sub IsPartyMap {
	my $id = shift;
	my $map = shift;
	my $party_map;

	($party_map) = $chars[$config{'char'}]{'party'}{'users'}{$id}{'map'} =~ /([\s\S]*)\.gat/;
	if (%{$chars[$config{'char'}]{'party'}{'users'}{$id}} &&
		$chars[$config{'char'}]{'party'}{'users'}{$id}{'online'} &&
		$party_map eq $map) {
		return 1;
	}

	return 0;
}

sub PrintMessage {
	my $msg = shift;
	my $tag = shift;
	my @msgs;
	my $i;

	@msgs = split /\\n/,$msg;
	for ($i = 0; $i < @msgs; $i++) {
		if ($config{'wrapperInterface'}) {
			PrintWrapper("$msgs[$i]", $tag);
		} else {
			SetColor($FG_GRAY | $BG_BLACK);
			print "$msgs[$i]\n";
			SetColor($ATTR_NORMAL);
		}
	}
}

sub DebugMessage {
	my $msg = shift;
	my @msgs;
	my $i;

	if ($config{'useDebug'}) {
		@msgs = split /\\n/,$msg;
		for ($i = 0; $i < @msgs; $i++) {
			if ($config{'remoteSocket'}) {
				if ($config{'wrapperInterface'}) {
					DebugWrapper("$msgs[$i]");
				} else {
					SetColor($FG_GRAY | $BG_BLACK);
					print "$msgs[$i]\n";
					SetColor($ATTR_NORMAL);
				}
			} else {
				injectAdminMessage($msgs[$i]);
			}
		}
	}
}

sub ReplyMessage {
	my $user = shift;
	my $msg = shift;
	my $chattype = shift;
	my @msgs;
	my $i;

	$msg =~ s/\n//g;
	if ($user eq "me" || $user eq $chars[$config{'char'}]{'name'}) {
		@msgs = split /\\n/,$msg;
		for ($i = 0; $i < @msgs; $i++) {
			if ($config{'remoteSocket'} || $user eq "me") {
				if ($config{'wrapperInterface'}) {
					ChatWrapper($user, $msgs[$i], $chattype);
				} else {
					print "$msgs[$i]\n";
				}
			} else {
				injectAdminMessage($msgs[$i]);
			}
		}
	} else {
		$msg =~ s/\\n/\\n /g;
		$msg = " $msg";

		sendMessage(\$remote_socket, $chattype, $msg, $user);
	}
}

sub StatusCmd {
	my $user = shift;
	my $type = shift;
	my $chattype = shift;
	my $msg;

	if ($type == 1) {
	$msg = <<TYPE1;
STR: $chars[$config{'char'}]{'str'} + $chars[$config{'char'}]{'str_bonus'}  |  $chars[$config{'char'}]{'points_str'}\\n
AGI: $chars[$config{'char'}]{'agi'} + $chars[$config{'char'}]{'agi_bonus'}  |  $chars[$config{'char'}]{'points_agi'}\\n
VIT: $chars[$config{'char'}]{'vit'} + $chars[$config{'char'}]{'vit_bonus'}  |  $chars[$config{'char'}]{'points_vit'}\\n
INT: $chars[$config{'char'}]{'int'} + $chars[$config{'char'}]{'int_bonus'}  |  $chars[$config{'char'}]{'points_int'}\\n
DEX: $chars[$config{'char'}]{'dex'} + $chars[$config{'char'}]{'dex_bonus'}  |  $chars[$config{'char'}]{'points_dex'}\\n
LUK: $chars[$config{'char'}]{'luk'} + $chars[$config{'char'}]{'luk_bonus'}  |  $chars[$config{'char'}]{'points_luk'}
TYPE1
	} elsif ($type == 2) {
	$msg = <<TYPE2;
ATK: $chars[$config{'char'}]{'attack'} + $chars[$config{'char'}]{'attack_bonus'}  DEF: $chars[$config{'char'}]{'def'} + $chars[$config{'char'}]{'def_bonus'}\\n
MATK: $chars[$config{'char'}]{'attack_magic_min'} ~ $chars[$config{'char'}]{'attack_magic_max'}  MDEF: $chars[$config{'char'}]{'def_magic'} + $chars[$config{'char'}]{'def_magic_bonus'}\\n
HIT: $chars[$config{'char'}]{'hit'}  FLEE: $chars[$config{'char'}]{'flee'} + $chars[$config{'char'}]{'flee_bonus'}\\n
CRI: $chars[$config{'char'}]{'critical'}  ASPD: $chars[$config{'char'}]{'attack_speed'}\\n
STATUS POINT: $chars[$config{'char'}]{'points_free'}\\n
GUILD: $chars[$config{'char'}]{'guild'}{'name'}
TYPE2
	} else {
	$percent_base = sprintf("%.2f", $chars[$config{'char'}]{'exp'} * 100 / $chars[$config{'char'}]{'exp_max'});
	$percent_job = sprintf("%.2f", $chars[$config{'char'}]{'exp_job'} * 100 / $chars[$config{'char'}]{'exp_job_max'});
	$percent_weight = sprintf("%.2f", $chars[$config{'char'}]{'weight'} * 100 / $chars[$config{'char'}]{'weight_max'});

	$msg = <<TYPE3;
HP: $chars[$config{'char'}]{'hp'} / $chars[$config{'char'}]{'hp_max'}  SP: $chars[$config{'char'}]{'sp'} / $chars[$config{'char'}]{'sp_max'}\\n
Base: $chars[$config{'char'}]{'lv'}  |  $chars[$config{'char'}]{'exp'} / $chars[$config{'char'}]{'exp_max'}  ($percent_base %)\\n
Job: $chars[$config{'char'}]{'lv_job'}  |  $chars[$config{'char'}]{'exp_job'} / $chars[$config{'char'}]{'exp_job_max'}  ($percent_job %)\\n
Weight: $chars[$config{'char'}]{'weight'} / $chars[$config{'char'}]{'weight_max'}  ($percent_weight %)  |  $chars[$config{'char'}]{'zenny'} Z
TYPE3
	}

	ReplyMessage($user, $msg, $chattype);
}

sub HealCmd {
	my $id = shift;
	my $user = shift;
	my $target = shift;
	my $amount = shift;
	my $chattype = shift;

	if ($id eq "") {
		if ($user eq $chars[$config{'char'}]{'name'}) {
			$id = $accountID;

			if (!$amount) {
				$amount = $chars[$config{'char'}]{'hp_max'} - $chars[$config{'char'}]{'hp'};
			}
		} else {
			$id = ai_getIDFromChat(\%players, $user, $target);
			if (IsPartyOnline($id) && $amount <= 0) {
				$amount = $chars[$config{'char'}]{'party'}{'users'}{$id}{'hp_max'} - $chars[$config{'char'}]{'party'}{'users'}{$id}{'hp'};
			}
		}
	} else {
		if ($id eq $accountID) {
			$amount = $chars[$config{'char'}]{'hp_max'} - $chars[$config{'char'}]{'hp'};
		} else {
			if (IsPartyOnline($id) && $amount <= 0) {
				$amount = $chars[$config{'char'}]{'party'}{'users'}{$id}{'hp_max'} - $chars[$config{'char'}]{'party'}{'users'}{$id}{'hp'};
			}
		}
	}

	if ($id eq "") {
		ReplyMessage($user, getResponse("healF1"), $chattype);
	} elsif ($chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'} > 0) {
		if ($amount <= 0) {
			if ($id == $accountID) {
				ReplyMessage($user, getResponse("healF5"), $chattype);
			} else {
				ReplyMessage($user, getResponse("healF6"), $chattype);
			}

			return;
		}

		undef $ai_v{'temp'}{'amount_healed'};
		undef $ai_v{'temp'}{'sp_needed'};
		undef $ai_v{'temp'}{'sp_used'};
		undef $ai_v{'temp'}{'failed'};
		undef $ai_v{'temp'}{'count'};
		undef @{$ai_v{'temp'}{'skillCasts'}};

		$endloop = 0;
		$ai_v{'temp'}{'count'} = 0;
		while (!$endloop) {
			for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'}; $i++) {
				$ai_v{'temp'}{'lv'} = $i;
				$ai_v{'temp'}{'sp'} = 10 + ($i * 3);
				$ai_v{'temp'}{'amount_this'} = int(($chars[$config{'char'}]{'lv'} + $chars[$config{'char'}]{'int'} + $chars[$config{'char'}]{'int_bonus'}) / 8)
						* (4 + $i * 8);
				if ($ai_v{'temp'}{'amount_healed'} + $ai_v{'temp'}{'amount_this'} >= $amount) {
					$endloop = 1;
					last;
				}
			}

			if ($ai_v{'temp'}{'sp_needed'} + $ai_v{'temp'}{'sp'} > $chars[$config{'char'}]{'sp'}) {
				for ($i = $ai_v{'temp'}{'lv'} - 1; $i >= 1; $i--) {
					$ai_v{'temp'}{'lv'} = $i;
					$ai_v{'temp'}{'sp'} = 10 + ($i * 3);

					if ($ai_v{'temp'}{'sp_needed'} + $ai_v{'temp'}{'sp'} <= $chars[$config{'char'}]{'sp'}) {
						$endloop = 2;
						last;
					}
				}

				if ($i <= 0) {
					$endloop = 2;
					$ai_v{'temp'}{'lv'} = 0;
				}
			}

			if ($ai_v{'temp'}{'lv'} > 0) {
				$ai_v{'temp'}{'sp_used'} += $ai_v{'temp'}{'sp'};
				$ai_v{'temp'}{'skillCast'}{'skill'} = 28;
				$ai_v{'temp'}{'skillCast'}{'lv'} = $ai_v{'temp'}{'lv'};
				$ai_v{'temp'}{'skillCast'}{'maxCastTime'} = 0;
				$ai_v{'temp'}{'skillCast'}{'minCastTime'} = 0;
				$ai_v{'temp'}{'skillCast'}{'waitBeforeNextUse'} = 1;
				$ai_v{'temp'}{'skillCast'}{'ID'} = $id;
				unshift @{$ai_v{'temp'}{'skillCasts'}}, {%{$ai_v{'temp'}{'skillCast'}}};

				$ai_v{'temp'}{'count'}++;
			} else {
				last;
			}

			$ai_v{'temp'}{'sp_needed'} += $ai_v{'temp'}{'sp'};
			$ai_v{'temp'}{'amount_healed'} += $ai_v{'temp'}{'amount_this'};
		}

		if (!$ai_v{'temp'}{'count'}) {
			$responseVars{'char_sp'} = $chars[$config{'char'}]{'sp'};
			ReplyMessage($user, getResponse("healF2"), $chattype);
		} else {
			if ($endloop == 2) {
				$responseVars{'heal_hp'} = $ai_v{'temp'}{'amount_healed'};
				$responseVars{'char_sp'} = $chars[$config{'char'}]{'sp'};
				ReplyMessage($user, getResponse("healF4"), $chattype);
			} else {
				$ai_v{'temp'}{'overhp'} = $ai_v{'temp'}{'amount_healed'} - $amount;
				if ($ai_v{'temp'}{'overhp'} <= 0) {
					$responseVars{'heal_hp'} = $ai_v{'temp'}{'amount_healed'};
					ReplyMessage($user, getResponse("healS1"), $chattype);
				} else {
					$responseVars{'heal_hp'} = $ai_v{'temp'}{'amount_healed'};
					$responseVars{'heal_overhp'} = $ai_v{'temp'}{'overhp'};
					ReplyMessage($user, getResponse("healS2"), $chattype);
				}
			}

			foreach (@{$ai_v{'temp'}{'skillCasts'}}) {
				ai_skillUse($$_{'skill'}, $$_{'lv'}, $$_{'maxCastTime'}, $$_{'minCastTime'}, $$_{'waitBeforeNextUse'}, $$_{'ID'});
			}
		}
	} else {
		ReplyMessage($user, getResponse("healF3"), $chattype);
	}
}

sub Heal {
	my $id = shift;
	my $amount = shift;
	my $endloop;
	my $i;

	if ($chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'} > 0) {
		if ($amount <= 0) {
			return;
		}

		undef $ai_v{'temp'}{'amount_healed'};
		undef $ai_v{'temp'}{'sp_needed'};
		undef $ai_v{'temp'}{'sp_used'};
		undef $ai_v{'temp'}{'failed'};
		undef $ai_v{'temp'}{'count'};
		undef @{$ai_v{'temp'}{'skillCasts'}};

		$endloop = 0;
		$ai_v{'temp'}{'count'} = 0;
		while (!$endloop) {
			for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'}; $i++) {
				$ai_v{'temp'}{'lv'} = $i;
				$ai_v{'temp'}{'sp'} = 10 + ($i * 3);
				$ai_v{'temp'}{'amount_this'} = int(($chars[$config{'char'}]{'lv'} + $chars[$config{'char'}]{'int'} + $chars[$config{'char'}]{'int_bonus'}) / 8)
						* (4 + $i * 8);
				if ($ai_v{'temp'}{'amount_healed'} + $ai_v{'temp'}{'amount_this'} >= $amount) {
					$endloop = 1;
					last;
				}
			}

			if ($ai_v{'temp'}{'sp_needed'} + $ai_v{'temp'}{'sp'} > $chars[$config{'char'}]{'sp'}) {
				for ($i = $ai_v{'temp'}{'lv'} - 1; $i >= 1; $i--) {
					$ai_v{'temp'}{'lv'} = $i;
					$ai_v{'temp'}{'sp'} = 10 + ($i * 3);

					if ($ai_v{'temp'}{'sp_needed'} + $ai_v{'temp'}{'sp'} <= $chars[$config{'char'}]{'sp'}) {
						$endloop = 2;
						last;
					}
				}

				if ($i <= 0) {
					$endloop = 2;
					$ai_v{'temp'}{'lv'} = 0;
				}
			}

			if ($ai_v{'temp'}{'lv'} > 0) {
				$ai_v{'temp'}{'sp_used'} += $ai_v{'temp'}{'sp'};
				$ai_v{'temp'}{'skillCast'}{'skill'} = 28;
				$ai_v{'temp'}{'skillCast'}{'lv'} = $ai_v{'temp'}{'lv'};
				$ai_v{'temp'}{'skillCast'}{'maxCastTime'} = 0;
				$ai_v{'temp'}{'skillCast'}{'minCastTime'} = 0;
				$ai_v{'temp'}{'skillCast'}{'waitBeforeNextUse'} = 1;
				$ai_v{'temp'}{'skillCast'}{'ID'} = $id;
				unshift @{$ai_v{'temp'}{'skillCasts'}}, {%{$ai_v{'temp'}{'skillCast'}}};

				$ai_v{'temp'}{'count'}++;
			} else {
				last;
			}

			$ai_v{'temp'}{'sp_needed'} += $ai_v{'temp'}{'sp'};
			$ai_v{'temp'}{'amount_healed'} += $ai_v{'temp'}{'amount_this'};
		}

		if ($ai_v{'temp'}{'count'}) {
			foreach (@{$ai_v{'temp'}{'skillCasts'}}) {
				ai_skillUse($$_{'skill'}, $$_{'lv'}, $$_{'maxCastTime'}, $$_{'minCastTime'}, $$_{'waitBeforeNextUse'}, $$_{'ID'});
			}
		}
	}
}

sub SkillSP {
	my $skill_nameID = shift;
	my $skill_lv = shift;
	my $sp = 65535;

	if ($skill_lv > 0) {
		if ($skillsSP_lut{$skill_nameID}{$skill_lv} > 0) {
			$sp = $skillsSP_lut{$skill_nameID}{$skill_lv};
		} else {
			$sp = $chars[$config{'char'}]{'skills'}{$skill_nameID}{'sp'};
		}
	}

	return $sp;
}

sub SkillCmd {
	my $id = shift;
	my $skill_id = shift;
	my $user = shift;
	my $target = shift;
	my $chattype = shift;
	my $x;
	my $y;
	my $i;

	if ($chars[$config{'char'}]{'skills'}{$skill_id}{'use'} == 0) {
		return;
	}

	if ($id eq "") {
		if ($user eq $chars[$config{'char'}]{'name'} || $chars[$config{'char'}]{'skills'}{$skill_id}{'use'} == 4) {
			$id = $accountID;
			$x = $chars[$config{'char'}]{'pos_to'}{'x'};
			$y = $chars[$config{'char'}]{'pos_to'}{'y'};
		} else {
			$id = ai_getIDFromChat(\%players, $user, $target);
			$x = $players{$id}{'pos_to'}{'x'};
			$y = $players{$id}{'pos_to'}{'y'};
		}
	} else {
		if ($id eq $accountID) {
			$x = $chars[$config{'char'}]{'pos_to'}{'x'};
			$y = $chars[$config{'char'}]{'pos_to'}{'y'};
		} else {
			$x = $players{$id}{'pos_to'}{'x'};
			$y = $players{$id}{'pos_to'}{'y'};
		}
	}

	if ($id eq "") {
		$responseVars{'skill'} = $skills_lut{$skill_id};
		ReplyMessage($user, getResponse("skillF1"), $chattype);
	} elsif ($players{$id}{'effect'}{$effects_rlut{lc(GetSkillName($chars[$config{'char'}]{'skills'}{$skill_id}{'ID'}))}{'ID'}}) {
		$responseVars{'skill'} = $skills_lut{$skill_id};
		ReplyMessage($user, getResponse("skillF4"), $chattype);
	} elsif ($chars[$config{'char'}]{'skills'}{$skill_id}{'lv'} > 0) {
		if ($skillsSP_lut{$skill_id}{$chars[$config{'char'}]{'skills'}{$skill_id}{'lv'}} > 0) {
			for ($i = $chars[$config{'char'}]{'skills'}{$skill_id}{'lv'}; $i >= 1; $i--) {
				$ai_v{'temp'}{'sp_needed'} = $skillsSP_lut{$skill_id}{$i};
				if ($chars[$config{'char'}]{'sp'} >= $ai_v{'temp'}{'sp_needed'}) {
					if ($chars[$config{'char'}]{'skills'}{$skill_id}{'use'} == 2) {
						ai_skillUse($chars[$config{'char'}]{'skills'}{$skill_id}{'ID'}, $i, 0, 0, 0, $x, $y);
					} else {
						ai_skillUse($chars[$config{'char'}]{'skills'}{$skill_id}{'ID'}, $i, 0, 0, 0, $id);
					}

					$responseVars{'skill'} = $skills_lut{$skill_id};
					$responseVars{'skill_lv'} = $i;
					$responseVars{'skill_sp'} = $ai_v{'temp'}{'sp_needed'};
					ReplyMessage($user, getResponse("skillS"), $chattype);
					last;
				}
			}

			if ($i <= 0) {
				$responseVars{'skill'} = $skills_lut{$skill_id};
				$responseVars{'skill_lv'} = $chars[$config{'char'}]{'skills'}{$skill_id}{'lv'};
				$responseVars{'char_sp'} = $chars[$config{'char'}]{'sp'};
				ReplyMessage($user, getResponse("skillF2"), $chattype);
			}
		} else {
			if ($chars[$config{'char'}]{'sp'} >= $chars[$config{'char'}]{'skills'}{$skill_id}{'sp'}) {
				if ($chars[$config{'char'}]{'skills'}{$skill_id}{'use'} == 2) {
					ai_skillUse($chars[$config{'char'}]{'skills'}{$skill_id}{'ID'}, $chars[$config{'char'}]{'skills'}{$skill_id}{'lv'}, 0, 0, 0, $x, $y);
				} else {
					ai_skillUse($chars[$config{'char'}]{'skills'}{$skill_id}{'ID'}, $chars[$config{'char'}]{'skills'}{$skill_id}{'lv'}, 0, 0, 0, $id);
				}

				$responseVars{'skill'} = $skills_lut{$skill_id};
				$responseVars{'skill_lv'} = $chars[$config{'char'}]{'skills'}{$skill_id}{'lv'};
				$responseVars{'skill_sp'} = $chars[$config{'char'}]{'skills'}{$skill_id}{'sp'};
				ReplyMessage($user, getResponse("skillS"), $chattype);
			} else {
				$responseVars{'skill'} = $skills_lut{$skill_id};
				$responseVars{'skill_lv'} = $chars[$config{'char'}]{'skills'}{$skill_id}{'lv'};
				$responseVars{'char_sp'} = $chars[$config{'char'}]{'sp'};
				ReplyMessage($user, getResponse("skillF2"), $chattype);
			}
		}
	} else {
		$responseVars{'skill'} = $skills_lut{$skill_id};
		ReplyMessage($user, getResponse("skillF3"), $chattype);
	}
}

sub Skill {
	my $id = shift;
	my $skill_id = shift;
	my $x;
	my $y;
	my $i;

	if ($chars[$config{'char'}]{'skills'}{$skill_id}{'use'} == 0) {
		return;
	}

	return if ($id eq "");

	if ($id eq $accountID) {
		$x = $chars[$config{'char'}]{'pos_to'}{'x'};
		$y = $chars[$config{'char'}]{'pos_to'}{'y'};
	} else {
		$x = $players{$id}{'pos_to'}{'x'};
		$y = $players{$id}{'pos_to'}{'y'};
	}

	if ($chars[$config{'char'}]{'skills'}{$skill_id}{'lv'} > 0) {
		if ($skillsSP_lut{$skill_id}{$chars[$config{'char'}]{'skills'}{$skill_id}{'lv'}} > 0) {
			for ($i = $chars[$config{'char'}]{'skills'}{$skill_id}{'lv'}; $i >= 1; $i--) {
				$ai_v{'temp'}{'sp_needed'} = $skillsSP_lut{$skill_id}{$i};
				if ($chars[$config{'char'}]{'sp'} >= $ai_v{'temp'}{'sp_needed'}) {
					if ($chars[$config{'char'}]{'skills'}{$skill_id}{'use'} == 2) {
						ai_skillUse($chars[$config{'char'}]{'skills'}{$skill_id}{'ID'}, $i, 0, 0, 0, $x, $y);
					} else {
						ai_skillUse($chars[$config{'char'}]{'skills'}{$skill_id}{'ID'}, $i, 0, 0, 0, $id);
					}

					last;
				}
			}
		} else {
			if ($chars[$config{'char'}]{'sp'} >= $chars[$config{'char'}]{'skills'}{$skill_id}{'sp'}) {
				if ($chars[$config{'char'}]{'skills'}{$skill_id}{'use'} == 2) {
					ai_skillUse($chars[$config{'char'}]{'skills'}{$skill_id}{'ID'}, $chars[$config{'char'}]{'skills'}{$skill_id}{'lv'}, 0, 0, 0, $x, $y);
				} else {
					ai_skillUse($chars[$config{'char'}]{'skills'}{$skill_id}{'ID'}, $chars[$config{'char'}]{'skills'}{$skill_id}{'lv'}, 0, 0, 0, $id);
				}
			}
		}
	}
}

sub Pneuma {
	my $id = shift;
	my $x;
	my $y;

	if ($id eq $accountID) {
		$x = $chars[$config{'char'}]{'pos_to'}{'x'};
		$y = $chars[$config{'char'}]{'pos_to'}{'y'};
	} else {
		$x = $players{$id}{'pos_to'}{'x'};
		$y = $players{$id}{'pos_to'}{'y'};
	}

	if ($chars[$config{'char'}]{'skills'}{'AL_PNEUMA'}{'lv'} > 0 && $chars[$config{'char'}]{'sp'} >= $chars[$config{'char'}]{'skills'}{'AL_PNEUMA'}{'sp'}) {
		ai_skillUse($chars[$config{'char'}]{'skills'}{'AL_PNEUMA'}{'ID'}, $chars[$config{'char'}]{'skills'}{'AL_PNEUMA'}{'lv'}, 0, 0, 0, $x, $y);
	}
}

sub StatusRecovery {
	my $id = shift;

	if ($chars[$config{'char'}]{'skills'}{'PR_STRECOVERY'}{'lv'} > 0 && $chars[$config{'char'}]{'sp'} >= $chars[$config{'char'}]{'skills'}{'PR_STRECOVERY'}{'sp'}) {
		ai_skillUse($chars[$config{'char'}]{'skills'}{'PR_STRECOVERY'}{'ID'}, $chars[$config{'char'}]{'skills'}{'PR_STRECOVERY'}{'lv'}, 0, 0, 0, $id);
	}
}

sub LexAeterna {
	my $id = shift;

	if ($chars[$config{'char'}]{'skills'}{'PR_LEXAETERNA'}{'lv'} > 0 && $chars[$config{'char'}]{'sp'} >= $chars[$config{'char'}]{'skills'}{'PR_LEXAETERNA'}{'sp'}) {
		ai_skillUse($chars[$config{'char'}]{'skills'}{'PR_LEXAETERNA'}{'ID'}, $chars[$config{'char'}]{'skills'}{'PR_LEXAETERNA'}{'lv'}, 0, 0, 0, $id);
	}
}

sub ReplyVar {
	my $user = shift;
	my $chattype = shift;
	my $level = shift;
	my $var_name = shift;
	my $var = shift;
	my $s = "$var";
	my $length;
	my $i;

	if ($s =~ /^HASH/i) {
		$s = chr(32) x ($level * 4);
		ReplyMessage($user, "$s$var_name = {", $chattype);
		$level++;
		foreach (keys %{$var}) {
			ReplyVar($user, $chattype, $level, $_, $var->{$_});
		}
		ReplyMessage($user, "$s}", $chattype);
	} elsif ($s =~ /^ARRAY/i) {
		$s = chr(32) x ($level * 4);
		$length = @{$var};
		ReplyMessage($user, "$s$var_name = ARRAY[$length] {", $chattype);
		$level++;
		for ($i = 0; $i < $length; $i++) {
			ReplyVar($user, $chattype, $level, "$var_name[$i]", $var[$i]);
		}
		ReplyMessage($user, "$s}", $chattype);
	} else {
		$s = chr(32) x ($level * 4);
		ReplyMessage($user, "$s$var_name = $var", $chattype);
	}
}

sub OnChat {
	my $id = shift;
	my $user = shift;
	my $msg = shift;
	my $chattype = shift;
	my @params;
	my $cmd;
	my $resp = 0;
	my $msgparam;
	my $result = 1;
	my $i;

	if ($user eq "me" || ($config{'useCommand'} && $overallAuth{$user} == 1)) {
		@params = parseCmdLine($msg);
		$cmd = lc($params[0]);
		$msgparam = Trim(substr($msg, length($cmd)));

		DebugMessage("CMD: $cmd $msgparam") if ($debug{'command'});

		if ($user ne "me" && $config{'remoteSocket'} && $cmd eq "reconnect") {
			reconnect();
		} elsif ($cmd eq "ai_seq") {
			if ($params[1] eq "") {
				$params[1] = 0;
			}

			if ($params[2] eq "") {
				$params[2] = 1;
			} elsif ($params[2] > @{ai_seq}) {
				$params[2] = @{ai_seq};
			}

			for ($i = $params[1]; $i < $params[2];$i++) {
				ReplyMessage($user, "AI[$i] = $ai_seq[$i]", $chattype);
				ReplyVar($user, $chattype, 0, "ARG[$i]", $ai_seq_args[$i]);
			}
		} elsif ($cmd eq "ai_buy") {
			unshift @ai_seq, "buyAuto";
			unshift @ai_seq_args, {};
		} elsif ($cmd eq "ai_sell") {
			unshift @ai_seq, "sellAuto";
			unshift @ai_seq_args, {};
		} elsif ($cmd eq "ai_storage") {
			unshift @ai_seq, "storageAuto";
			unshift @ai_seq_args, {};
		} elsif ($cmd eq "ai_remove") {
			shift @ai_seq;
			shift @ai_seq_args;
		} elsif ($user ne "me" && $cmd eq "auth") {
			my $player;
			my $flag;

			($player, $flag) = $msgparam =~ /^([\s\S]*) ([\s\S]*?)$/;
			if ($player ne "" && $flag ne "") {
				auth($player, $flag);
				if ($flag) {
					ReplyMessage($user, "- You are now an admin $player.", $chattype);
				} else {
					ReplyMessage($user, "- You are not an admin $player.", $chattype);
				}
			}
		} elsif ($user ne "me" && $cmd eq "avoid") {
			my $player;
			my $flag;

			($player, $flag) = $msgparam =~ /^([\s\S]*) ([\s\S]*?)$/;
			if ($player ne "" && $flag ne "") {
				avoidPlayer($player, $flag);
				if ($flag) {
					ReplyMessage($user, "- Avoid player $player.", $chattype);
				} else {
					ReplyMessage($user, "- Revoked avoid for player $player.", $chattype);
				}
			}
		} elsif ($user ne "me" && $cmd eq "conf") {
			my $val;

			($val) = $msgparam =~ /^\w+ ([\s\S]+)$/;
			@{$ai_v{'temp'}{'config'}} = keys %config;
			if ($params[1] eq "") {
				ReplyMessage($user, "Syntax: conf <variable> [<value>]", $chattype);
			} elsif (binFind(\@{$ai_v{'temp'}{'config'}}, $params[1]) eq "") {
				ReplyMessage($user, "- Config variable $params[1] doesn't exist", $chattype);
			} elsif ($val eq "value") {
				ReplyMessage($user, "- Config '$params[1]' is $config{$params[1]}", $chattype);
			} else {
				configModify($params[1], $val);
			}
		} elsif ($user ne "me" && $cmd eq "debug") {
			@{$ai_v{'temp'}{'debug'}} = keys %debug;
			if ($params[1] eq "" || $params[1] eq "on") {
				configModify("useDebug", 1);
			} elsif ($params[1] eq "off") {
				configModify("useDebug", 0);
			} elsif (binFind(\@{$ai_v{'temp'}{'debug'}}, $params[1]) eq "") {
				ReplyMessage($user, "- Debug variable $params[1] doesn't exist", $chattype);
			} elsif ($params[2] eq "value") {
				ReplyMessage($user, "- Debug '$params[1]' is $debug{$params[1]}", $chattype);
			} else {
				debugModify($params[1], $params[2]);
				ReplyMessage($user, "- Debug '$params[1]' set to $params[2]", $chattype);
			}
		} elsif ($user ne "me" && $cmd eq "c") {
			sendMessage(\$remote_socket, "c", $msgparam, $user);
		} elsif ($cmd eq "dump") {
			if ($dpackets{uc($params[1])}) {
				undef $dpackets{uc($params[1])};
				ReplyMessage($user, "- No dump packet $params[1].", $chattype);
			} else {
				$dpackets{uc($params[1])} = 1;
				ReplyMessage($user, "- Dump packet $params[1].", $chattype);
			}
		} elsif ($user ne "me" && $cmd eq "e") {
			$ai_v{'temp'}{'emo'} = ParseEmotion($msgparam);
			DebugMessage("- Emotion $ai_v{'temp'}{'emo'}.") if ($debug{'command'});
			if ($ai_v{'temp'}{'emo'} >= 0) {
				sendEmotion(\$remote_socket, $ai_v{'temp'}{'emo'});
			} else {
				sendEmotion(\$remote_socket, 1);
			}
		} elsif ($cmd eq "e_resp") {
			if ($params[1] eq "") {
				$params[1] = 1;
			} else {
				$params[1] = int($params[1]);
			}

			configModify("respAuto", $params[1]);

			if (!$params[1]) {
				ReplyMessage($user, "- No response.", $chattype);
			} else {
				ReplyMessage($user, "- Response turn on.", $chattype);
			}
		} elsif ($cmd eq "e_sell") {
			if ($params[1] eq "") {
				$params[1] = 1;
			} else {
				$params[1] = int($params[1]);
			}

			configModify("sellAuto", $params[1]);

			if (!$params[1]) {
				ReplyMessage($user, "- No sell.", $chattype);
			} else {
				ReplyMessage($user, "- Sell to NPC $config{'sellAuto_npc'}.", $chattype);
			}
		} elsif ($cmd eq "e_storage") {
			if ($params[1] eq "") {
				$params[1] = 1;
			} else {
				$params[1] = int($params[1]);
			}

			configModify("storageAuto", $params[1]);

			if (!$params[1]) {
				ReplyMessage($user, "- No storage.", $chattype);
			} else {
				ReplyMessage($user, "- Storage to NPC $config{'storageAuto_npc'}.", $chattype);
			}
		} elsif ($user ne "me" && $cmd eq "follow") {
			if ($params[1] eq "stop") {
				aiRemove("follow");
				configModify("follow", 0);
				ReplyMessage($user, "- Stop following.", $chattype);
			} elsif ($params[1] eq "me") {
				ai_follow($user, 0);
				configModify("follow", 1);
				configModify("followTarget", $user);
				ReplyMessage($user, "- Follow $user.", $chattype);
			} elsif ($playersID[$params[1]] ne "") {
				ai_follow($players{$playersID[$params[1]]}{'name'}, 0);
				configModify("follow", 1);
				configModify("followTarget", $players{$playersID[$params[1]]}{'name'});
			}
		} elsif ($user ne "me" && $cmd eq "tank") {
			if ($params[1] eq "stop") {
				configModify("tankMode", 0);
				ReplyMessage($user, "- Stop tanking.", $chattype);
			} elsif ($params[1] eq "me") {
				configModify("tankMode", 1);
				configModify("tankModeTarget", $user);
				ReplyMessage($user, "- Tank $user.", $chattype);
			} elsif ($playersID[$params[1]] ne "") {
				configModify("tankMode", 1);
				configModify("tankModeTarget", $players{$playersID[$params[1]]}{'name'});
			}
		} elsif ($cmd eq "on") {
			if (!$AI) {
				$AI = 1;
				configModify("aiStart", 1);
				ReplyMessage($user, "- AI turned on.", $chattype);
			}
		} elsif ($cmd eq "off") {
			if ($AI) {
				aiRemove("clientSuspend");
				aiRemove("move");
				aiRemove("route");
				aiRemove("route_getRoute");
				aiRemove("route_getMapRoute");

				undef $AI;
				configModify("aiStart", 0);
				ReplyMessage($user, "- AI turned off.", $chattype);
			}
		} elsif ($user ne "me" && ($cmd eq "tele" || $cmd eq "teleport")) {
			useTeleport(1);
		} elsif ($user ne "me" && $cmd eq "town") {
			if ($chars[$config{'char'}]{'dead'}) {
				sendRespawn(\$remote_socket);
			} else {
				useTeleport(2);
			}
		} elsif ($user ne "me" && $cmd eq "sit") {
			$ai_v{'attackAuto_old'} = $config{'attackAuto'};
			$ai_v{'route_randomWalk_old'} = $config{'route_randomWalk'};

			if ($config{'attackAuto'} > 1) {
				configModify("attackAuto", 1);
			}

			configModify("route_randomWalk", 0);
			aiRemove("move");
			aiRemove("route");
			aiRemove("route_getRoute");
			aiRemove("route_getMapRoute");
			sit();
			$ai_v{'sitAuto_forceStop'} = 0;
		} elsif ($user ne "me" && $cmd eq "stand") {
			if ($ai_v{'attackAuto_old'} ne "") {
				configModify("attackAuto", $ai_v{'attackAuto_old'});
				configModify("route_randomWalk", $ai_v{'route_randomWalk_old'});
			}
			stand();
			$ai_v{'sitAuto_forceStop'} = 1;
		} elsif ($user ne "me" && $cmd eq "memo") {
			sendMemo(\$remote_socket);
			ReplyMessage($user, "- Memo $field{'name'}.", $chattype);
		} elsif ($cmd eq "save") {
			configModify("saveMap", $field{'name'});
			ReplyMessage($user, "- Save to $field{'name'}.", $chattype);
		} elsif ($cmd eq "lock") {
			if ($params[1] eq "") {
				$ai_v{'temp'}{'map'} = $field{'name'};
			} elsif ($params[1] eq "master") {
				$ai_v{'temp'}{'map'} = "none";
				for ($i = 0; $i < @partyUsersID; $i++) {
					next if ($partyUsersID[$i] eq "");
					if (IsPartyName($partyUsersID[$i], $config{'followTarget'})) {
						($ai_v{'temp'}{'map'}) = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'map'} =~ /([\s\S]*)\.gat/;
						last;
					}
				}
			} else {
				$ai_v{'temp'}{'map'} = $params[1];
			}

			if ($maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}) {
				configModify("lockMap", $ai_v{'temp'}{'map'});
				configModify("lockMap_x", "");
				configModify("lockMap_y", "");
				ReplyMessage($user, "- Lock to $ai_v{'temp'}{'map'}.", $chattype);
			} else {
				ReplyMessage($user, "- Map $ai_v{'temp'}{'map'} does not exist.", $chattype);
			}
		} elsif ($cmd eq "unlock") {
			configModify("lockMap", "");
			configModify("lockMap_x", "");
			configModify("lockMap_y", "");
			ReplyMessage($user, "- Unlock map.", $chattype);
		} elsif ($cmd eq "lockhere") {
			configModify("lockMap", $field{'name'});
			configModify("lockMap_x", $chars[$config{'char'}]{'pos_to'}{'x'});
			configModify("lockMap_y", $chars[$config{'char'}]{'pos_to'}{'y'});
			ReplyMessage($user, "- Lock to $field{'name'}: $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'}.", $chattype);
		} elsif ($cmd eq "move" || $cmd eq "go") {
			aiRemove("clientSuspend");
			aiRemove("move");
			aiRemove("route");
			aiRemove("route_getRoute");
			aiRemove("route_getMapRoute");

			if ($params[1] eq "here" || $params[1] eq "master") {
				if ($params[1] eq "master") {
					$ai_v{'temp'}{'master'} = $config{'followTarget'};
				} else {
					$ai_v{'temp'}{'master'} = $user;
				}

				$ai_v{'temp'}{'chat_id'} = ai_getID(\%players, $ai_v{'temp'}{'master'});
				if ($ai_v{'temp'}{'chat_id'} eq "") {
					for ($i = 0; $i < @partyUsersID; $i++) {
						next if ($partyUsersID[$i] eq "");

						if (IsPartyName($partyUsersID[$i], $ai_v{'temp'}{'master'})) {
							if (IsPartyMap($partyUsersID[$i], $field{'name'}) && IsPartyMove($partyUsersID[$i])) {
								$ai_v{'temp'}{'x'} = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'x'};
								$ai_v{'temp'}{'y'} = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'y'};
								$ai_v{'temp'}{'map'} = $field{'name'};
								ReplyMessage($user, "- Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}.", $chattype);
								$ai_v{'sitAuto_forceStop'} = 1;
								ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
							} elsif (IsPartyOnline($partyUsersID[$i])) {
								undef $ai_v{'temp'}{'x'};
								undef $ai_v{'temp'}{'y'};
								($ai_v{'temp'}{'map'}) = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'map'} =~ /([\s\S]*)\.gat/;
								ReplyMessage($user, "- Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}).", $chattype);
								$ai_v{'sitAuto_forceStop'} = 1;
								ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
							}

							last;
						}
					}
				} else {
					$ai_v{'temp'}{'x'} = $players{$ai_v{'temp'}{'chat_id'}}{'pos_to'}{'x'};
					$ai_v{'temp'}{'y'} = $players{$ai_v{'temp'}{'chat_id'}}{'pos_to'}{'y'};
					$ai_v{'temp'}{'map'} = $field{'name'};
					ReplyMessage($user, "- Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}.", $chattype);
					$ai_v{'sitAuto_forceStop'} = 1;
					ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
				}
			} elsif ($params[1] eq "party") {
				$i = $params[2];
				if ($partyUsersID[$i] ne "") {
					if (IsPartyMap($partyUsersID[$i], $field{'name'}) && IsPartyMove($partyUsersID[$i])) {
						$ai_v{'temp'}{'x'} = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'x'};
						$ai_v{'temp'}{'y'} = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'y'};
						$ai_v{'temp'}{'map'} = $field{'name'};
						ReplyMessage($user, "- Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}.", $chattype);
						$ai_v{'sitAuto_forceStop'} = 1;
						ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
					} elsif (IsPartyOnline($partyUsersID[$i])) {
						undef $ai_v{'temp'}{'x'};
						undef $ai_v{'temp'}{'y'};
						($ai_v{'temp'}{'map'}) = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'map'} =~ /([\s\S]*)\.gat/;
						ReplyMessage($user, "- Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}).", $chattype);
						$ai_v{'sitAuto_forceStop'} = 1;
						ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
					}
				}
			} elsif ($params[1] eq "") {
				do {
					$ai_v{'temp'}{'x'} = int(rand() * ($field{'width'} - 1));
					$ai_v{'temp'}{'y'} = int(rand() * ($field{'height'} - 1));
				} while ($field{'field'}[$ai_v{'temp'}{'y'}*$field{'width'} + $ai_v{'temp'}{'x'}]);
				$ai_v{'temp'}{'map'} = $field{'name'};
				ReplyMessage($user, "- Calculating random route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}.", $chattype);
				$ai_v{'sitAuto_forceStop'} = 1;
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
			} elsif ($params[2] eq "") {
				$ai_v{'temp'}{'map'} = $params[1];
				if ($maps_lut{$ai_v{'temp'}{'map'}.".rsw"}) {
					undef $ai_v{'temp'}{'x'};
					undef $ai_v{'temp'}{'y'};
					ReplyMessage($user, "- Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}).", $chattype);
					$ai_v{'sitAuto_forceStop'} = 1;
					ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
				} else {
					ReplyMessage($user, "- Map $ai_v{'temp'}{'map'} does not exist.", $chattype);
				}
			} elsif ($params[3] eq "" && IsNumber($params[1]) && IsNumber($params[2])) {
				$ai_v{'temp'}{'map'} = $field{'name'};
				$ai_v{'temp'}{'x'} = $params[1];
				$ai_v{'temp'}{'y'} = $params[2];
				ReplyMessage($user, "- Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}.", $chattype);
				$ai_v{'sitAuto_forceStop'} = 1;
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
			} elsif (IsNumber($params[2]) && IsNumber($params[3])) {
				$ai_v{'temp'}{'map'} = $params[1];
				$ai_v{'temp'}{'x'} = $params[2];
				$ai_v{'temp'}{'y'} = $params[3];
				if ($maps_lut{$ai_v{'temp'}{'map'}.".rsw"}) {
					ReplyMessage($user, "- Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}.", $chattype);
					$ai_v{'sitAuto_forceStop'} = 1;
					ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
				} else {
					ReplyMessage($user, "- Map $ai_v{'temp'}{'map'} does not exist.", $chattype);
				}
			}
		} elsif ($cmd eq "status") {
			StatusCmd($user, $params[1], $chattype);
		} elsif ($cmd eq "stop") {
			aiRemove("clientSuspend");
			aiRemove("move");
			aiRemove("route");
			aiRemove("route_getRoute");
			aiRemove("route_getMapRoute");
			configModify("route_randomWalk", 0);
			ReplyMessage($user, "- Stop all movement.", $chattype);
		} elsif ($cmd eq "walk") {
			configModify("route_randomWalk", 1);
			ReplyMessage($user, "- Walk enable.", $chattype);
		} elsif ($user ne "me" && $cmd eq "where") {
			$responseVars{'x'} = $chars[$config{'char'}]{'pos_to'}{'x'};
			$responseVars{'y'} = $chars[$config{'char'}]{'pos_to'}{'y'};
			$responseVars{'map'} = qq~$maps_lut{$field{'name'}.'.rsw'} ($field{'name'})~;
			ReplyMessage($user, getResponse("whereS"), $chattype);
# MODE COMMAND ################################################################
		} elsif ($cmd eq "attack") {
			configModify("attackAuto", 2);
			ReplyMessage($user, "- Attack mode.", $chattype);
		} elsif ($cmd eq "defence") {
			configModify("attackAuto", 1);
			ReplyMessage($user, "- Defence mode.", $chattype);
		} elsif ($cmd eq "escape") {
			if ($params[1] eq "") {
				$params[1] = 1;
			} else {
				$params[1] = int($params[1]);
			}

			configModify("teleportAuto_minAggressives", $params[1]);
			if (!$params[1]) {
				ReplyMessage($user, "- No escape.", $chattype);
			} else {
				ReplyMessage($user, "- Escape on $params[1] aggressives.", $chattype);
			}
		} elsif ($cmd eq "hold") {
			configModify("attackAuto", 0);
			ReplyMessage($user, "- Hold mode.", $chattype);
		} elsif ($cmd eq "share") {
			if ($params[1] eq "none") {
				configModify("lockMap", "");
				configModify("lockMap_x", "");
				configModify("lockMap_y", "");
				ReplyMessage($user, "- Unlock map.", $chattype);
			} else {
				if ($params[1] eq "here") {
					$ai_v{'temp'}{'map'} = $field{'name'};
				} else {
					$ai_v{'temp'}{'map'} = $params[1];
				}

				if ($maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}) {
					configModify("lockMap", $ai_v{'temp'}{'map'});
					configModify("lockMap_x", "");
					configModify("lockMap_y", "");
					ReplyMessage($user, "- Lock to $ai_v{'temp'}{'map'}.", $chattype);
				} else {
					ReplyMessage($user, "- Map $ai_v{'temp'}{'map'} does not exist.", $chattype);
				}
			}

			if ($params[2] eq "") {
				$params[2] = 0;
			} else {
				$params[2] = int($params[2]);
			}

			if ($params[1] eq "none") {
				aiRemove("clientSuspend");
				aiRemove("move");
				aiRemove("route");
				aiRemove("route_getRoute");
				aiRemove("route_getMapRoute");
				configModify("route_randomWalk", 0);
				ReplyMessage($user, "- Stop all movement.", $chattype);
				configModify("attackAuto", 0);
				ReplyMessage($user, "- Hold mode.", $chattype);
				configModify("teleportAuto_minAggressives", 0);
				ReplyMessage($user, "- No escape.", $chattype);
			} elsif (!$params[2]) {
				configModify("route_randomWalk", 1);
				ReplyMessage($user, "- Walk enable.", $chattype);
				configModify("attackAuto", 2);
				ReplyMessage($user, "- Attack mode.", $chattype);
				configModify("teleportAuto_minAggressives", 3);
				ReplyMessage($user, "- Escape on 3 aggressives.", $chattype);
			} elsif ($params[2] == 1) {
				aiRemove("clientSuspend");
				aiRemove("move");
				aiRemove("route");
				aiRemove("route_getRoute");
				aiRemove("route_getMapRoute");
				configModify("route_randomWalk", 0);
				configModify("attackAuto", 1);
				ReplyMessage($user, "- Defence mode.", $chattype);
				configModify("teleportAuto_minAggressives", 2);
				ReplyMessage($user, "- Escape on 2 aggressives.", $chattype);
			} else {
				aiRemove("clientSuspend");
				aiRemove("move");
				aiRemove("route");
				aiRemove("route_getRoute");
				aiRemove("route_getMapRoute");
				configModify("route_randomWalk", 0);
				ReplyMessage($user, "- Stop all movement.", $chattype);
				configModify("attackAuto", 0);
				ReplyMessage($user, "- Hold mode.", $chattype);
				configModify("teleportAuto_minAggressives", 1);
				ReplyMessage($user, "- Escape on 1 aggressives.", $chattype);
			}
# SKILL COMMAND ###############################################################
		} elsif ($msg =~ /^,/) {
			$msg =~ s/^,//;
			$ai_v{'temp'}{'skill_id'} = ParseSkill($msg);
			if ($ai_v{'temp'}{'skill_id'} ne "") {
				if ($id eq "") {
					$ai_v{'temp'}{'chat_id'} = ai_getID(\%players, $user);
				} else {
					$ai_v{'temp'}{'chat_id'} = $id;
				}

				undef $ai_v{'temp'}{'min_id'};

				if (%{$players{$ai_v{'temp'}{'chat_id'}}}) {
					$ai_v{'temp'}{'min_distance'} = 9999;
					for ($i = 0; $i < @playersID; $i++) {
						next if ($playersID[$i] eq "");

						$ai_v{'temp'}{'distance'} = distance(\%{$players{$ai_v{'temp'}{'chat_id'}}{'pos_to'}}, \%{$players{$playersID[$i]}{'pos_to'}});
						if ($ai_v{'temp'}{'distance'} && $ai_v{'temp'}{'distance'} < $ai_v{'temp'}{'min_distance'}) {
							$ai_v{'temp'}{'min_id'} = $playersID[$i];
							$ai_v{'temp'}{'min_distance'} = $ai_v{'temp'}{'distance'};
						}
					}
				}

				if (%{$players{$ai_v{'temp'}{'min_id'}}}) {
					Skill($ai_v{'temp'}{'min_id'}, $ai_v{'temp'}{'skill_id'});
				}
			} else {
				$result = 0;
			}
		} elsif ($cmd eq ".heal") {
			HealCmd($accountID, $chars[$config{'char'}]{'name'}, "me", 0, $chattype);
		} elsif ($msg =~ /^\./) {
			$msg =~ s/^\.//;
			$ai_v{'temp'}{'skill_id'} = ParseSkill($msg);
			if ($ai_v{'temp'}{'skill_id'} ne "") {
				SkillCmd($accountID, $ai_v{'temp'}{'skill_id'}, $chars[$config{'char'}]{'name'}, "me", $chattype);
			} else {
				$result = 0;
			}
		} elsif ($cmd eq "heal") {
			($ai_v{'temp'}{'amount'}) = $params[1] =~ /^(\d+)$/;
			if ($user eq "me") {
				HealCmd($accountID, $chars[$config{'char'}]{'name'}, "me", $ai_v{'temp'}{'amount'}, $chattype);
			} else {
				HealCmd($id, $user, "me", $ai_v{'temp'}{'amount'}, $chattype);
			}
		} elsif ($user ne "me") {
			$ai_v{'temp'}{'skill_id'} = ParseSkill($msg);
			if ($ai_v{'temp'}{'skill_id'} ne "") {
				DebugMessage("- Request skill $ai_v{'temp'}{'skill_id'}.") if ($debug{'command'});
				SkillCmd($id, $ai_v{'temp'}{'skill_id'}, $user, "me", $chattype);
			} else {
				$result = 0;
			}
		} else {
			$result = 0;
		}
	} else {
		$result = 0;
	}

	if (!$result && $config{'respAuto'} && $user ne $chars[$config{'char'}]{'name'}) {
		if ($id eq "") {
			$ai_v{'temp'}{'chat_id'} = ai_getID(\%players, $user);
		} else {
			$ai_v{'temp'}{'chat_id'} = $id;
		}

		if ($ai_v{'temp'}{'chat_id'} ne $accountID && ($ai_v{'temp'}{'chat_id'} ne "" || $chattype eq "pm")) {
			if (%{$players{$ai_v{'temp'}{'chat_id'}}}) {
				$ai_v{'temp'}{'chat_job'} = $jobs_lut{$players{$ai_v{'temp'}{'chat_id'}}{'jobID'}};
			} else {
				$ai_v{'temp'}{'chat_job'} = "Unknown";
			}

			$cmd = ParseCmdResps($msg);
			if ($cmd ne "") {
				DebugMessage("- $user request $cmd.") if ($debug{'respAuto'});
			} else {
				DebugMessage("- No command.") if ($debug{'respAuto'});
			}

			undef $ai_v{'temp'}{'min_id'};
			undef $ai_v{'temp'}{'min_job'};
			undef $ai_v{'temp'}{'min_distance'};

			if ($cmd eq "_HEAL" || $cmd eq "_AGI" || $cmd eq "_BLESS") {
				if (!$config{'respSkillWait'}) {
					$config{'respSkillWait'} = 300;
				}

				if (time - $respAuto{'user'}{$user}{lc($cmd)."_time"} > $config{'respSkillWait'}) {
					$resp = 1;
				}
			} else {
#			} elsif (!$respAuto{'user'}{$user}{lc($cmd)."_count"} || (time - $respAuto{'user'}{$user}{lc($cmd)."_time"} > 15)) {
				$resp = 1;
			}

			if (%{$players{$ai_v{'temp'}{'chat_id'}}}) {
				$ai_v{'temp'}{'our_distance'} = distance(\%{$players{$ai_v{'temp'}{'chat_id'}}{'pos_to'}}, \%{$chars[$config{'char'}]{'pos_to'}});
				$ai_v{'temp'}{'min_distance'} = 9999;
				for ($i = 0; $i < @playersID; $i++) {
					next if ($playersID[$i] eq "");

					if ($cmd eq "_HEAL" || $cmd eq "_AGI" || $cmd eq "_BLESS") {
						$ai_v{'temp'}{'job'} = $jobs_lut{$players{$playersID[$i]}{'jobID'}};
						next if ($ai_v{'temp'}{'job'} ne "Acolyte" && $ai_v{'temp'}{'job'} ne "Priest");
					}

					$ai_v{'temp'}{'distance'} = distance(\%{$players{$ai_v{'temp'}{'chat_id'}}{'pos_to'}}, \%{$players{$playersID[$i]}{'pos_to'}});
					if ($ai_v{'temp'}{'distance'} && $ai_v{'temp'}{'distance'} < $ai_v{'temp'}{'min_distance'}) {
						$ai_v{'temp'}{'min_id'} = $playersID[$i];
						$ai_v{'temp'}{'min_job'} = $jobs_lut{$players{$playersID[$i]}{'jobID'}};
						$ai_v{'temp'}{'min_distance'} = $ai_v{'temp'}{'distance'};
					}
				}
			} else {
				$ai_v{'temp'}{'our_distance'} = 9999;
			}

			if ($ai_v{'temp'}{'our_distance'} < $ai_v{'temp'}{'min_distance'} || $chattype eq "pm") {
				if ($chattype ne "pm") {
					ChatWrapper("", "- Player talk to you and distance is $ai_v{'temp'}{'our_distance'}.", "debug");
					DebugMessage("- Player talk to you and distance is $ai_v{'temp'}{'our_distance'}.") if ($debug{'respAuto'});
				}

				if ($ai_v{'temp'}{'our_distance'} <= $config{'respAuto_Distance'} || $chattype eq "pm") {
					if ($cmd ne "") {
						if ($resp) {
							ChatWrapper("", "- Auto response to command $cmd, ".($respAuto{'user'}{$user}{lc($cmd)."_count"} + 1).".", "debug");
							ai_respAuto($user, $cmd, $chattype);
						} else {
							ChatWrapper("", "- No response to command $cmd, ".($respAuto{'user'}{$user}{lc($cmd)."_count"} + 1).".", "debug");
						}
					} else {
						if ($config{'playerTalkAlarm'}) {
							PlaySound("alarm.wav");
						}

						if ($config{'playerTalkPopup'}) {
							ShowWrapper();
						}
					}
				}
			} elsif (%{$players{$ai_v{'temp'}{'min_id'}}}) {
				ChatWrapper("", "- Nearest player is $players{$ai_v{'temp'}{'min_id'}}{'name'} ($ai_v{'temp'}{'min_job'}) and distance is $ai_v{'temp'}{'min_distance'}.", "debug");
				DebugMessage("- Nearest player is $players{$ai_v{'temp'}{'min_id'}}{'name'} ($ai_v{'temp'}{'min_job'}) and distance is $ai_v{'temp'}{'min_distance'}.") if ($debug{'respAuto'});
			}
		}
	}

	return $result;
}

sub IsAvoidGM {
	my $id = shift;
	my $found = 0;
	my $gm;
	my $name;
	my $id_num;
	my @ret;

	$name = $players{$id}{'name'};
	$id_num = unpack("L1", $id);

	foreach (@gms) {
		if ($name eq $_ || "$id_num" eq $_) {
			$found = 1;
			$gm = 1;
			last;
		}
	}

	if (!$found) {
		foreach (@avoids) {
			if ($name eq $_ || "$id_num" eq $_) {
				$found = 1;
				$gm = 0;
				last;
			}
		}
	}

	if ($found) {
		@ret = ($id, $name, $gm);
	} else {
		@ret = ("", "", 0);
	}

	return @ret;
}

sub GetSkillName {
	my $skillID = shift;

	if ($skillsID_lut{$skillID}{'name'} eq "") {
		return "Unknown ($skillID)";
	} else {
		return $skillsID_lut{$skillID}{'name'};
	}
}

sub ParseDamage {
	my $damage = shift;

	if ($damage <= 0) {
		return " MISS";
	} else {
		return " $damage";
	}
}

sub ParseSkillDamage {
	my $damage = shift;

	if ($damage <= 0) {
		return " - MISS";
	} elsif ($damage == 35536) {
		return "";
	} else {
		return " - $damage";
	}
}

sub ParseSkillAmount {
	my $skillID = shift;
	my $amount = shift;

	if ($skillsID_lut{$skillID}{'nameID'} eq "AL_HEAL") {
		return " - $amount HP";
	} elsif ($amount == 35536) {
		return "";
	} elsif ($amount > 10) {
		return " - LIVE: ".($amount / 100)." seconds";
	} else {
		return " - LV: $amount";
	}
}

sub ParseLevel {
	my $level = shift;

	if ($level == 65535) {
		return "";
	} else {
		return " LV.$level";
	}
}

sub IsYourMonster {
	my $id = shift;

	if (($monsters{$id}{'dmgToYou'} > 0 || $monsters{$id}{'missedYou'} > 0) && $monsters{$id}{'attack_failed'} <= 1) {
		return 1;
	} elsif ($monsters{$id}{'dmgFromYou'} > 0 &&
		!$monsters{$id}{'missedToPlayers'} &&
		#!$monsters{$id}{'missedFromPlayers'} &&
		!$monsters{$id}{'dmgToPlayers'} &&
		!$monsters{$id}{'dmgFromPlayers'}) {
		return 1;
	}

	return 0;
}

sub GenAttack {
	my $target = shift;
	my $type = shift;
	my $hit = shift;
	my $damage = shift;
	my $damage2 = shift;
	my $action;

	if ($type == 10) {
		$action = "CRITICAL ATTACK";
	} elsif ($type == 8) {
		$action = "DOUBLE ATTACK";
	} elsif (!$type) {
		$action = "ATTACK";
	} else {
		$action = "ATTACK ($type)";
	}

	$action = "$action $target -".ParseDamage($damage);

	if ($damage2 > 0) {
		$action .= " +".ParseDamage($damage2);
	}

	if ($hit > 1) {
		$action .= ", $hit hits";
	}

	return $action;
}

sub AvoidSkill {
	my $sourceID = shift;
	my $skillID = shift;
	my $x = shift;
	my $y = shift;
	my $skill = GetSkillName($skillID);
	my $name;
	my $left;
	my $right;
	my $top;
	my $bottom;
	my $sourceNo;
	my $i;
	my $count;
	my $dx;
	my $dy;
	my %random;
	my %move;
	my %src;
	my %nearest;
	my $in_left;
	my $in_right;
	my $in_top;
	my $in_bottom;
	my $ex_left;
	my $ex_right;
	my $ex_top;
	my $ex_bottom;
	my $dist;
	my $nearest_dist;
	my $found;

	$i = 0;
	while ($config{"avoidSkill_$i"} ne "") {
		if (existsInList($config{"avoidSkill_$i"}, $skill)) {
			$left = $x - $config{"avoidSkill_$i"."_radius"};
			$right = $x + $config{"avoidSkill_$i"."_radius"};
			$top = $y - $config{"avoidSkill_$i"."_radius"};
			$bottom = $y + $config{"avoidSkill_$i"."_radius"};
			if ($left <= $chars[$config{'char'}]{'pos_to'}{'x'} &&
				$right >= $chars[$config{'char'}]{'pos_to'}{'x'} &&
				$top <= $chars[$config{'char'}]{'pos_to'}{'y'} &&
				$bottom >= $chars[$config{'char'}]{'pos_to'}{'y'}) {

				if ($chars[$config{'char'}]{'sitting'}) {
					sendStand(\$remote_socket);
				}

				if (%{$players{$sourceID}}) {
					$sourceNo = unpack("L1", $sourceID);
					WriteLog("avoidskill.txt", "$sourceNo $players{$sourceID}{'name'} $sex_lut{$players{$sourceID}{'sex'}} $jobs_lut{$players{$sourceID}{'jobID'}}\n");
				}

				if ($config{"avoidSkill_$i"."_method"} == 0) {
					$found = 1;
					$count = 0;
					do {
						($move{'x'}, $move{'y'}) = GetRandPosition($config{"avoidSkill_$i"."_step"});
						$count++;
						if ($count > 100) {
							$found = 0;
							last;
						}
					} while ($left <= $move{'x'} && $right >= $move{'x'} && $top <= $move{'y'} && $bottom >= $move{'y'});

					if ($found) {
						sendAttackStop(\$remote_socket);
						sendMove(\$remote_socket, $move{'x'}, $move{'y'});
						PrintMessage("Avoid skill $skill, random move to $move{'x'}, $move{'y'}.", "red");
					}
				} elsif ($config{"avoidSkill_$i"."_method"} == 1) {
					$dx = $x - $chars[$config{'char'}]{'pos_to'}{'x'};
					$dy = $y - $chars[$config{'char'}]{'pos_to'}{'y'};

					$found = 1;
					$count = 0;
					do {
						$random{'x'} = int(rand($config{"avoidSkill_$i"."_step"})) + 1;
						$random{'y'} = int(rand($config{"avoidSkill_$i"."_step"})) + 1;

						if ($dx >= 0) {
							$move{'x'} = $chars[$config{'char'}]{'pos_to'}{'x'} - $random{'x'};
						} else {
							$move{'x'} = $chars[$config{'char'}]{'pos_to'}{'x'} + $random{'x'};
						}

						if ($dy >= 0) {
							$move{'y'} = $chars[$config{'char'}]{'pos_to'}{'y'} - $random{'y'};
						} else {
							$move{'y'} = $chars[$config{'char'}]{'pos_to'}{'y'} + $random{'y'};
						}

						$count++;
						if ($count > 100) {
							$found = 0;
							last;
						}
					} while ($field{'field'}[$move{'y'} * $field{'width'} + $move{'x'}]);

					if ($found) {
						sendAttackStop(\$remote_socket);
						sendMove(\$remote_socket, $move{'x'}, $move{'y'});
						PrintMessage("Avoid skill $skill, move to $move{'x'}, $move{'y'}.", "red");
					}
				} elsif ($config{"avoidSkill_$i"."_method"} == 2) {
					if (%{$monsters{$sourceID}}) {
						$src{'x'} = $monsters{$sourceID}{'pos_to'}{'x'};
						$src{'y'} = $monsters{$sourceID}{'pos_to'}{'y'};
					} elsif (%{$players{$sourceID}}) {
						$src{'x'} = $players{$sourceID}{'pos_to'}{'x'};
						$src{'y'} = $players{$sourceID}{'pos_to'}{'y'};
					}

					$found = 0;
					$count = 0;
					do {
						$ex_left = $src{'x'} - $count;
						$ex_right = $src{'x'} + $count;
						$ex_top = $src{'y'} - $count;
						$ex_bottom = $src{'y'} + $count;

						$count++;

						$in_left = $src{'x'} - $count;
						$in_right = $src{'x'} + $count;
						$in_top = $src{'y'} - $count;
						$in_bottom = $src{'y'} + $count;

						$nearest_dist = 9999;
						for ($move{'y'} = $in_top; $move{'y'} <= $in_bottom; $move{'y'}++) {
							for ($move{'x'} = $in_left; $move{'x'} <= $in_right; $move{'x'}++) {
								if (($move{'x'} < $ex_left || $move{'x'} > $ex_right) && ($move{'y'} < $ex_top || $move{'y'} > $ex_bottom)) {
									next if (($left <= $move{'x'} && $right >= $move{'x'} && $top <= $move{'y'} && $bottom >= $move{'y'}) ||
										$field{'field'}[$move{'y'} * $field{'width'} + $move{'x'}]);

									$dist = distance(\%{$move}, \%{$src});

									if ($dist < $nearest_dist) {
										$nearest_dist = $dist;
										$nearest{'x'} = $move{'x'};
										$nearest{'y'} = $move{'y'};
										$found = 1;
									}
								}
							}
						}
					} while (($count < 100) && (!$found));

					if ($found) {
						sendAttackStop(\$remote_socket);
						sendMove(\$remote_socket, $nearest{'x'}, $nearest{'y'});
						PrintMessage("Avoid skill $skill, move to nearest position $nearest{'x'}, $nearest{'y'}.", "red");
					}
				} elsif ($config{"avoidSkill_$i"."_method"} == 3) {
					$found = 1;
					PrintMessage("Avoid skill $skill, use random teleport.", "red");
					useTeleport(1);
				}

				if (!$found) {
					PrintMessage("Avoid skill $skill, could not find the position to move.", "red");
				}

				if ($chars[$config{'char'}]{'sitting'}) {
					sendSit(\$remote_socket);
				}
			}

			last;
		}

		$i++;
	}
}

sub OnPlayer {
	my $id = shift;
	my $event = shift;
	my $i;

	if ($event == $EV_APPEARED) {
		UpdateWrapperPlayer($id, "APPEARED");
	} elsif ($event == $EV_DISAPPEARED) {
		RemoveWrapperPlayer($id);
	} elsif ($event == $EV_CONNECTED) {
		UpdateWrapperPlayer($id, "CONNECTED");
	} elsif ($event == $EV_DISCONNECTED) {
		RemoveWrapperPlayer($id);
	} elsif ($event == $EV_TELEPORTED) {
		RemoveWrapperPlayer($id);
	} elsif ($event == $EV_EXISTS) {
		UpdateWrapperPlayer($id, "EXISTS");
	} elsif ($event == $EV_SPAWNED) {
		UpdateWrapperPlayer($id, "SPAWNED");
	} elsif ($event == $EV_DIED) {
		UpdateWrapperPlayer($id, "DEAD");
	} elsif ($event == $EV_REMOVED) {
		RemoveWrapperPlayer($id);
	} elsif ($event == $EV_GET_INFO) {
		UpdateWrapperPlayer($id, "GET INFO");
		UpdateWrapperVender($id);

		if (!$chars[$config{'char'}]{'shopping'} && %{$vender_players{$id}}) {
			UpdateWrapperShopping($vender_players{$id});
		}
	} elsif ($event == $EV_MOVE) {
		UpdateWrapperPlayer($id, "MOVE");
	} elsif ($event == $EV_EQUIP) {
		UpdateWrapperPlayer($id, "EQUIP");
	} elsif ($event == $EV_EMOTION) {
		my $type = shift;

		OnChat($ID, $players{$ID}{'name'}, "/$emotions_lut{$type}{'word'}", "c");
	} elsif ($event == $EV_EFFECT) {
		my $effectID = shift;
		my $val = shift;

		if ($val) {
			$val = "ON";
		} else {
			$val = "OFF";
		}

		if (%{$effects_lut{$effectID}}) {
			UpdateWrapperPlayer($id, "$effects_lut{$effectID}{'name'} ($effectID): $val");
		} else {
			UpdateWrapperPlayer($id, "EFFECT ($effectID): $val");
		}
	} elsif ($event == $EV_ITEM_PICKUP) {
		my $itemID = shift;

		if ($rareItems_lut{lc($items{$itemID}{'name'})}) {
			if (IsPartyOnline($id)) {
				WriteLog("party_rare.txt", Name($id)." PICKUP $items{$itemID}{'name'} x $items{$itemID}{'amount'}\n");
			} else {
				WriteLog("player_rare.txt", Name($id)." PICKUP $items{$itemID}{'name'} x $items{$itemID}{'amount'}\n");
			}
		}
	} elsif ($event == $EV_ATTACK_MONSTER) {
		my $targetID = shift;
		my $type = shift;
		my $hit = shift;
		my $damage = shift;
		my $damage2 = shift;

		UpdateWrapperPlayer($id, GenAttack($monsters{$targetID}{'name'}, $type, $hit, $damage, $damage2));

		if (!IsPartyOnline($id)) {
	 		if ($config{'respAuto'} && $config{'respJamMon'} && $config{'tankModeTarget'} ne $players{$id}{'name'} && IsYourMonster($targetID)) {
				WriteLog("jam.txt", "$players{$id}{'name'} $sex_lut{$players{$id}{'sex'}} $jobs_lut{$players{$id}{'jobID'}}\n");
				ai_respAuto($players{$id}{'name'}, "JAMMON", "c");
 			}
 		}
	} elsif ($event == $EV_ATTACK_PLAYER) {
		my $targetID = shift;
		my $type = shift;
		my $hit = shift;
		my $damage = shift;
		my $damage2 = shift;

		UpdateWrapperPlayer($id, GenAttack($players{$targetID}{'name'}, $type, $hit, $damage, $damage2));

		if (IsPartyOnline($targetID)) {
			UpdateWrapperParty($targetID);
		}
	} elsif ($event == $EV_ATTACK_YOU) {
		my $type = shift;
		my $hit = shift;
		my $damage = shift;
		my $damage2 = shift;

		UpdateWrapperPlayer($id, GenAttack("YOU", $type, $hit, $damage, $damage2));
		UpdateWrapperParty($accountID);
	} elsif ($event == $EV_SKILL_USE_AT) {
		my $skillID = shift;
		my $x = shift;
		my $y = shift;
		my $level = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperPlayer($id, "USE $skill".ParseLevel($level)." AT $x, $y");

		DebugMessage("- $players{$id}{'name'} use $skill ($x, $y).") if ($debug{'onPlayer_skill_use_at'});

		AvoidSkill($id, $skillID, $x, $y);
	} elsif ($event == $EV_SKILL_DAMAGE_ON_MONSTER) {
		my $targetID = shift;
		my $skillID = shift;
		my $damage = shift;
		my $level = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperPlayer($id, "USE $skill".ParseLevel($level)." ON $monsters{$targetID}{'name'}".ParseSkillDamage($damage));

		if (!IsPartyOnline($id)) {
	 		if ($config{'respAuto'} && $config{'respJamMon'} && $config{'tankModeTarget'} ne $players{$id}{'name'} && IsYourMonster($targetID)) {
				WriteLog("jam.txt", "$players{$id}{'name'} $sex_lut{$players{$id}{'sex'}} $jobs_lut{$players{$id}{'jobID'}}\n");
				ai_respAuto($players{$id}{'name'}, "JAMMON", "c");
 			}
 		}
	} elsif ($event == $EV_SKILL_DAMAGE_ON_PLAYER) {
		my $targetID = shift;
		my $skillID = shift;
		my $damage = shift;
		my $level = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperPlayer($id, "USE $skill".ParseLevel($level)." ON $players{$targetID}{'name'}".ParseSkillDamage($damage));

		if (IsPartyOnline($targetID)) {
			UpdateWrapperParty($targetID);
		}
	} elsif ($event == $EV_SKILL_DAMAGE_ON_YOU) {
		my $skillID = shift;
		my $damage = shift;
		my $level = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperPlayer($id, "USE $skill".ParseLevel($level)." ON YOU".ParseSkillDamage($damage));
		UpdateWrapperParty($accountID);
	} elsif ($event == $EV_SKILL_RESTORE_ON_MONSTER) {
		my $targetID = shift;
		my $skillID = shift;
		my $amount = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperPlayer($id, "USE $skill ON $monsters{$targetID}{'name'}".ParseSkillAmount($skillID, $amount));

		if ($skillsID_lut{$skillID}{'nameID'} eq "AL_HEAL") {
	 		if ($config{'respAuto'} && $config{'respHealMon'} && IsYourMonster($targetID)) {
				WriteLog("heal.txt", "$players{$id}{'name'} $sex_lut{$players{$id}{'sex'}} $jobs_lut{$players{$id}{'jobID'}}\n");
				ai_respAuto($players{$id}{'name'}, "HEALMON", "c");
 			}
 		}
	} elsif ($event == $EV_SKILL_RESTORE_ON_PLAYER) {
		my $targetID = shift;
		my $skillID = shift;
		my $amount = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperPlayer($id, "USE $skill ON $players{$targetID}{'name'}".ParseSkillAmount($skillID, $amount));

		if (IsPartyOnline($targetID)) {
			UpdateWrapperParty($targetID);
		}
	} elsif ($event == $EV_SKILL_RESTORE_ON_YOU) {
		my $skillID = shift;
		my $amount = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperPlayer($id, "USE $skill ON YOU".ParseSkillAmount($skillID, $amount));
		UpdateWrapperParty($accountID);
	} elsif ($event == $EV_SKILL_CASTING_ON_MONSTER) {
		my $targetID = shift;
		my $skillID = shift;
		my $wait = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperPlayer($id, "CAST $skill ON $monsters{$targetID}{'name'} TIME $wait");

		if (!IsPartyOnline($id)) {
	 		if ($config{'respAuto'} && $config{'respJamMon'} && $config{'tankModeTarget'} ne $players{$id}{'name'} && IsYourMonster($targetID)) {
				WriteLog("jam.txt", "CAST :: $players{$id}{'name'} $sex_lut{$players{$id}{'sex'}} $jobs_lut{$players{$id}{'jobID'}}\n");
				ai_respAuto($players{$id}{'name'}, "JAMMON", "c");
 			}
 		} else {
			LexAeterna($targetID);
 		}
	} elsif ($event == $EV_SKILL_CASTING_ON_PLAYER) {
		my $targetID = shift;
		my $skillID = shift;
		my $wait = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperPlayer($id, "CAST $skill ON $players{$targetID}{'name'} TIME $wait");
	} elsif ($event == $EV_SKILL_CASTING_ON_YOU) {
		my $skillID = shift;
		my $wait = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperPlayer($id, "CAST $skill ON YOU, TIME $wait");
	} elsif ($event == $EV_SKILL_CASTING_AT) {
		my $skillID = shift;
		my $x = shift;
		my $y = shift;
		my $wait = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperPlayer($id, "CAST $skill AT $x, $y TIME $wait");

		DebugMessage("- $players{$id}{'name'} casting $skill ($x, $y).") if ($debug{'onPlayer_skill_casting_at'});

		AvoidSkill($id, $skillID, $x, $y);
	} elsif ($event == $EV_STAND) {
		UpdateWrapperPlayer($id, "STAND");
	} elsif ($event == $EV_SIT) {
		UpdateWrapperPlayer($id, "SIT");
	} elsif ($event == $EV_PARTY_REQUEST) {
		if  (!$config{'partyAutoDeny'}) {
			ShowWrapperJoinParty();
		}
	} elsif ($event == $EV_PARTY_JOIN) {
		UpdateWrapperParty($id);
	} elsif ($event == $EV_PARTY_LEFT) {
		RemoveWrapperParty($id);
	} elsif ($event == $EV_PARTY_UPDATED) {
		UpdateWrapperParty($id);
	} elsif ($event == $EV_PARTY_HP) {
		UpdateWrapperParty($id);

		# Party Auto Heal
		$ai_v{'temp'}{'percent'} = percent_hp(\%{$chars[$config{'char'}]{'party'}{'users'}{$id}});
		$ai_v{'temp'}{'distance'} = distance(\%{$chars[$config{'char'}]{'party'}{'users'}{$id}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});

		DebugMessage("- $chars[$config{'char'}]{'party'}{'users'}{$id}{'name'}, HP $chars[$config{'char'}]{'party'}{'users'}{$id}{'hp'}/$chars[$config{'char'}]{'party'}{'users'}{$id}{'hp_max'} $percent%, DISTANCE: $distance.") if ($debug{'onPlayer_party_hp'});

		if ($config{"partyHeal"} && $ai_v{'temp'}{'percent'} <= $config{"partyHeal_hp_lower"} && $ai_v{'temp'}{'distance'} <= $config{"partyHeal_distance"}) {
			$ai_v{'temp'}{'amount'} = int($chars[$config{'char'}]{'party'}{'users'}{$id}{'hp_max'} * $config{"partyHeal_hp_upper"} / 100) - $chars[$config{'char'}]{'party'}{'users'}{$id}{'hp'};
			if ($ai_v{'temp'}{'amount'} > 0 && $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'} > 0) {
				if (timeOut(\%{$timeout{'ai_healParty'}})) {
					DebugMessage("- Auto heal $chars[$config{'char'}]{'party'}{'users'}{$id}{'name'}, AMOUNT: $ai_v{'temp'}{'amount'}");
					Heal($id, $ai_v{'temp'}{'amount'});
					$timeout{'ai_healParty'}{'time'} = time;
				}
			}
		}
	} elsif ($event == $EV_PARTY_MOVE) {
		UpdateWrapperParty($id);
		$ai_v{'temp'}{'distance'} = distance(\%{$chars[$config{'char'}]{'party'}{'users'}{$id}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});

		DebugMessage("- $chars[$config{'char'}]{'party'}{'users'}{$id}{'name'}, ($chars[$config{'char'}]{'party'}{'users'}{$id}{'pos'}{'x'}, $chars[$config{'char'}]{'party'}{'users'}{$id}{'pos'}{'y'}), DISTANCE: $distance.") if ($debug{'onPlayer_party_move'});
	} elsif ($event == $EV_DEAL_REQUEST) {
		if (!$config{'dealAutoCancel'}) {
			ShowWrapperYesNoDeal();
		}
	} elsif ($event == $EV_DEAL_ADD) {
		my $itemID = shift;
		my $amount = shift;
		AddWrapperDealItem(1, $itemID, $amount);
	} elsif ($event == $EV_DEAL_ADD_ZENY) {
		my $zeny = shift;
		AddWrapperDealZeny(1, $zeny);
	} elsif ($event == $EV_DEAL_ACCEPT) {
		ShowWrapperDeal();
	} elsif ($event == $EV_DEAL_CONFIRM) {
		ConfirmWrapperDeal(1)
	} elsif ($event == $EV_CRITICAL) {
		if (IsParty($id)) {
			StatusRecovery($id);
		}
	} elsif ($event == $EV_SHOP_APPEARED) {
		UpdateWrapperVender($id);
	} elsif ($event == $EV_SHOP_DISAPPEARED) {
		RemoveWrapperVender($id);
	}
}

sub OnMonster {
	my $id = shift;
	my $event = shift;

	if ($event == $EV_APPEARED) {
		UpdateWrapperMonster($id, "APPEARED");
	} elsif ($event == $EV_DISAPPEARED) {
		RemoveWrapperMonster($id);
	} elsif ($event == $EV_CONNECTED) {
		UpdateWrapperMonster($id, "CONNECTED");
	} elsif ($event == $EV_DISCONNECTED) {
		RemoveWrapperMonster($id);
	} elsif ($event == $EV_EXISTS) {
		UpdateWrapperMonster($id, "EXISTS");
	} elsif ($event == $EV_SPAWNED) {
		UpdateWrapperMonster($id, "SPAWNED");
	} elsif ($event == $EV_TRANSFORMED) {
		UpdateWrapperMonster($id, "TRANSFORMED");
	} elsif ($event == $EV_DIED) {
		if ($id eq $monster{'id'}) {
			UpdateWrapperEvent("");
			$monster{'dead'} = 1;
			$monster{'dmgFromYou'} = $monsters{$id}{'dmgFromYou'};
			$monster{'pos'}{'x'} = $monsters{$id}{'pos_to'}{'x'};
			$monster{'pos'}{'y'} = $monsters{$id}{'pos_to'}{'y'};
		}

		RemoveWrapperMonster($id);
	} elsif ($event == $EV_REMOVED) {
		RemoveWrapperMonster($id);
	} elsif ($event == $EV_GET_INFO) {
		UpdateWrapperMonster($id, "GET INFO");
	} elsif ($event == $EV_MOVE) {
		UpdateWrapperMonster($id, "MOVE");
	} elsif ($event == $EV_ATTACK_MONSTER) {
		my $targetID = shift;
		my $type = shift;
		my $hit = shift;
		my $damage = shift;
		my $damage2 = shift;

		UpdateWrapperMonster($id, GenAttack($monsters{$targetID}{'name'}, $type, 1, $damage, 0));
	} elsif ($event == $EV_ATTACK_PLAYER) {
		my $targetID = shift;
		my $type = shift;
		my $hit = shift;
		my $damage = shift;
		my $damage2 = shift;

		UpdateWrapperMonster($id, GenAttack($players{$targetID}{'name'}, $type, 1, $damage, 0));

		if (IsParty($targetID)) {
			if ($monsters_lut{$monsters{$id}{'nameID'}}{'range'} > 2 && $damage > 0) {
				Pneuma($targetID);
			}

			UpdateWrapperParty($targetID);
		}
	} elsif ($event == $EV_ATTACK_YOU) {
		my $type = shift;
		my $hit = shift;
		my $damage = shift;
		my $damage2 = shift;
		UpdateWrapperMonster($id, GenAttack("YOU", $type, 1, $damage, 0));
		UpdateWrapperParty($accountID);

		if ($monsters_lut{$monsters{$id}{'nameID'}}{'range'} > 2 && $damage > 0) {
			Pneuma($accountID);
		}

		if ($config{'teleportAuto_WhenHit'} && $damage >= $config{'teleportAuto_WhenHit'}) {
			useTeleport(1);
			$ai_v{'clear_aiQueue'} = 1;
		}
	} elsif ($event == $EV_SKILL_USE_AT) {
		my $skillID = shift;
		my $x = shift;
		my $y = shift;
		my $level = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperMonster($id, "USE $skill".ParseLevel($level)." AT $x, $y");

		AvoidSkill($id, $skillID, $x, $y);
	} elsif ($event == $EV_SKILL_DAMAGE_ON_MONSTER) {
		my $targetID = shift;
		my $skillID = shift;
		my $damage = shift;
		my $level = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperMonster($id, "USE $skill".ParseLevel($level)." ON $monsters{$targetID}{'name'}".ParseSkillDamage($damage));
	} elsif ($event == $EV_SKILL_DAMAGE_ON_PLAYER) {
		my $targetID = shift;
		my $skillID = shift;
		my $damage = shift;
		my $level = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperMonster($id, "USE $skill".ParseLevel($level)." ON $players{$targetID}{'name'}".ParseSkillDamage($damage));

		if (IsPartyOnline($targetID)) {
			UpdateWrapperParty($targetID);
		}
	} elsif ($event == $EV_SKILL_DAMAGE_ON_YOU) {
		my $skillID = shift;
		my $damage = shift;
		my $level = shift;
		my $skill = GetSkillName($skillID);

		if ($id eq $monster{'id'}) {
			PrintMessage("<$monsters{$id}{'name'}> USE $skill".ParseLevel($level)." ON YOU".ParseSkillDamage($damage), "dark");
		} else {
			PrintMessage("$monsters{$id}{'name'} USE $skill".ParseLevel($level)." ON YOU".ParseSkillDamage($damage), "dark");
		}

		UpdateWrapperMonster($id, "USE $skill".ParseLevel($level)." ON YOU".ParseSkillDamage($damage));
		UpdateWrapperParty($accountID);
	} elsif ($event == $EV_SKILL_RESTORE_ON_MONSTER) {
		my $targetID = shift;
		my $skillID = shift;
		my $amount = shift;
		my $skill = GetSkillName($skillID);

		if ($id eq $monster{'id'}) {
			if ($id eq $targetID) {
				PrintMessage("<$monsters{$id}{'name'}> USE $skill".ParseSkillAmount($skillID, $amount), "dark");
			} else {
				PrintMessage("<$monsters{$id}{'name'}> USE $skill ON $monsters{$targetID}{'name'}".ParseSkillAmount($skillID, $amount), "dark");
			}
		} elsif ($targetID eq $monster{'id'}) {
			PrintMessage("$monsters{$id}{'name'} USE $skill ON <$monsters{$targetID}{'name'}>".ParseSkillAmount($skillID, $amount), "dark");
		}

		UpdateWrapperMonster($id, "USE $skill ON $monsters{$targetID}{'name'}".ParseSkillAmount($skillID, $amount));
	} elsif ($event == $EV_SKILL_RESTORE_ON_PLAYER) {
		my $targetID = shift;
		my $skillID = shift;
		my $amount = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperMonster($id, "USE $skill ON $players{$targetID}{'name'}".ParseSkillAmount($skillID, $amount));

		if (IsPartyOnline($targetID)) {
			UpdateWrapperParty($targetID);
		}
	} elsif ($event == $EV_SKILL_RESTORE_ON_YOU) {
		my $skillID = shift;
		my $amount = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperMonster($id, "USE $skill ON YOU".ParseSkillAmount($skillID, $amount));
		UpdateWrapperParty($accountID);
	} elsif ($event == $EV_SKILL_CASTING_ON_MONSTER) {
		my $targetID = shift;
		my $skillID = shift;
		my $wait = shift;
		my $skill = GetSkillName($skillID);

		if ($id eq $monster{'id'}) {
			if ($id eq $targetID) {
				PrintMessage("<$monsters{$id}{'name'}> CAST $skill TIME $wait", "dark");
			} else {
				PrintMessage("<$monsters{$id}{'name'}> CAST $skill ON $monsters{$targetID}{'name'} TIME $wait", "dark");
			}
		} elsif ($targetID eq $monster{'id'}) {
			PrintMessage("$monsters{$id}{'name'} CAST $skill ON <$monsters{$targetID}{'name'}> TIME $wait", "dark");
		}

		UpdateWrapperMonster($id, "CAST $skill ON $monsters{$targetID}{'name'} TIME $wait");
	} elsif ($event == $EV_SKILL_CASTING_ON_PLAYER) {
		my $targetID = shift;
		my $skillID = shift;
		my $wait = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperMonster($id, "CAST $skill ON $players{$targetID}{'name'} TIME $wait");
	} elsif ($event == $EV_SKILL_CASTING_ON_YOU) {
		my $skillID = shift;
		my $wait = shift;
		my $skill = GetSkillName($skillID);

		if ($id eq $monster{'id'}) {
			PrintMessage("<$monsters{$id}{'name'}> CAST $skill ON YOU, TIME $wait", "dark");
		} else {
			PrintMessage("$monsters{$id}{'name'} CAST $skill ON YOU, TIME $wait", "dark");
		}

		UpdateWrapperMonster($id, "CAST $skill ON YOU, TIME $wait");
	} elsif ($event == $EV_SKILL_CASTING_AT) {
		my $skillID = shift;
		my $x = shift;
		my $y = shift;
		my $wait = shift;
		my $skill = GetSkillName($skillID);

		if ($id eq $monster{'id'}) {
			PrintMessage("<$monsters{$id}{'name'}> CAST $skill AT $x, $y TIME $wait", "dark");
		} else {
			PrintMessage("$monsters{$id}{'name'} CAST $skill AT $x, $y TIME $wait", "dark");
		}

		UpdateWrapperMonster($id, "CAST $skill AT $x, $y TIME $wait");

		AvoidSkill($id, $skillID, $x, $y);
	} elsif ($event == $EV_STAND) {
		UpdateWrapperMonster($id, "STAND");
	} elsif ($event == $EV_SIT) {
		UpdateWrapperMonster($id, "SIT");
	} elsif ($event == $EV_CRITICAL || $event == $EV_WARNING || $event == $EV_OPTION) {
		my $name = shift;
		my $on = shift;

		$on = ($on) ? "on" : "off";
		if ($id eq $monster{'id'}) {
			PrintMessage("<$monsters{$id}{'name'}> - $name is $on.", "dark");
		}
	}
}

sub OnYou {
	my $event = shift;
	my $i;

	if ($event == $EV_DIED) {
		UpdateWrapperEvent("DEAD");
		if ($config{'closeShopOnDead'} && $chars[$config{'char'}]{'shop'}) {
			ShopClose(\$remote_socket);
		}
	} elsif ($event == $EV_MOVE) {
		UpdateWrapperStatus();
		UpdateWrapperEvent("MOVE");
		UpdateWrapperParty($accountID);
	} elsif ($event == $EV_PORTAL_EXISTS) {
		my $id = shift;

		PrintMessage("Portal: $portals{$ID}{'name'}", "white");
		UpdateWrapperEvent($portals{$id}{'name'});
	} elsif ($event == $EV_PORTAL_DISAPPEARED) {
		my $id = shift;

		PrintMessage("Portal disappeared: $portals{$ID}{'name'}", "white");
		UpdateWrapperEvent($portals{$id}{'name'});
	} elsif ($event == $EV_EFFECT) {
		my $effectID = shift;
		my $val = shift;

	} elsif ($event == $EV_ITEM_EXISTS) {
		my $itemID = shift;
		UpdateWrapperItem($itemID);
	} elsif ($event == $EV_ITEM_APPEARED) {
		my $itemID = shift;
		UpdateWrapperItem($itemID);
	} elsif ($event == $EV_ITEM_DISAPPEARED) {
		my $itemID = shift;
		RemoveWrapperItem($itemID);
	} elsif ($event == $EV_ITEM_PICKUP) {
		my $itemID = shift;

		if ($rareItems_lut{lc($items{$itemID}{'name'})}) {
			$chars[$config{'char'}]{'summary'}{'rare'}{$field{'name'}}{$items{$itemID}{'name'}}{'count'} += $items{$itemID}{'amount'};

			WriteLog("rare.txt", "PICKUP $items{$itemID}{'name'} x $items{$itemID}{'amount'}\n");
			PrintMessage("Pickup rare item: $items{$itemID}{'name'} x $items{$itemID}{'amount'}", "white");
		} else {
			PrintMessage("Pickup item: $items{$itemID}{'name'} x $items{$itemID}{'amount'}", "white");
		}
	} elsif ($event == $EV_GO_ATTACK_MONSTER) {
		my $id = shift;

		undef %monster;

		$monster{'id'} = $id;
		$monster{'name'} = $monsters{$id}{'name'};
		$timecount{'attack'}{'start'} = time;

		PrintMessage("Attack: $monsters{$id}{'name'} [".getHex($id)."]", "yellow");
	} elsif ($event == $EV_ATTACK_MONSTER) {
		my $targetID = shift;
		my $type = shift;
		my $hit = shift;
		my $damage = shift;
		my $damage2 = shift;

		UpdateWrapperEvent(GenAttack($monsters{$targetID}{'name'}, $type, $hit, $damage, $damage2));
	} elsif ($event == $EV_ATTACK_PLAYER) {
		my $targetID = shift;
		my $type = shift;
		my $hit = shift;
		my $damage = shift;
		my $damage2 = shift;

		UpdateWrapperEvent(GenAttack($players{$targetID}{'name'}, $type, $hit, $damage, $damage2));
	} elsif ($event == $EV_SKILL_DAMAGE_ON_MONSTER) {
		my $targetID = shift;
		my $skillID = shift;
		my $damage = shift;
		my $level = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperEvent("USE $skill".ParseLevel($level)." ON $monsters{$targetID}{'name'}".ParseSkillDamage($damage));
	} elsif ($event == $EV_SKILL_DAMAGE_ON_PLAYER) {
		my $targetID = shift;
		my $skillID = shift;
		my $damage = shift;
		my $level = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperEvent("USE $skill".ParseLevel($level)." ON $players{$targetID}{'name'}".ParseSkillDamage($damage));
	} elsif ($event == $EV_SKILL_RESTORE_ON_MONSTER) {
		my $targetID = shift;
		my $skillID = shift;
		my $amount = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperEvent("USE $skill ON $monsters{$targetID}{'name'}".ParseSkillAmount($skillID, $amount));
	} elsif ($event == $EV_SKILL_RESTORE_ON_PLAYER) {
		my $targetID = shift;
		my $skillID = shift;
		my $amount = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperEvent("USE $skill ON $players{$targetID}{'name'}".ParseSkillAmount($skillID, $amount));
	} elsif ($event == $EV_SKILL_RESTORE_ON_YOU) {
		my $skillID = shift;
		my $amount = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperEvent("USE $skill ON YOU".ParseSkillAmount($skillID, $amount));
	} elsif ($event == $EV_SKILL_CASTING_ON_MONSTER) {
		my $targetID = shift;
		my $skillID = shift;
		my $wait = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperEvent("CAST $skill ON $monsters{$targetID}{'name'} TIME $wait");
	} elsif ($event == $EV_SKILL_CASTING_ON_PLAYER) {
		my $targetID = shift;
		my $skillID = shift;
		my $wait = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperEvent("CAST $skill ON $players{$targetID}{'name'} TIME $wait");
	} elsif ($event == $EV_SKILL_CASTING_ON_YOU) {
		my $skillID = shift;
		my $wait = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperEvent("CAST $skill ON YOU, TIME $wait");
	} elsif ($event == $EV_SKILL_CASTING_AT) {
		my $skillID = shift;
		my $x = shift;
		my $y = shift;
		my $wait = shift;
		my $skill = GetSkillName($skillID);

		UpdateWrapperEvent("CAST $skill AT $x, $y TIME $wait");
	} elsif ($event == $EV_SKILL_FAILED) {
		my $skillID = shift;
		my $skill = GetSkillName($skillID);
		UpdateWrapperEvent("FAILED TO USE SKILL $skill");
	} elsif ($event == $EV_STAND) {
		UpdateWrapperEvent("STAND");
	} elsif ($event == $EV_SIT) {
		UpdateWrapperEvent("SIT");
	} elsif ($event == $EV_MAP_CHANGED) {
		UpdateWrapperMap();
		HideWrapperNpcCon();
		HideWrapperNpcResp();
		HideWrapperBuySell();
		HideWrapperStore();
	} elsif ($event == $EV_STAT_CHANGED) {
		UpdateWrapperStatus();
	} elsif ($event == $EV_INVENTORY_ADDED) {
		my $index = shift;
		my $amount = shift;
		my $name = $chars[$config{'char'}]{'inventory'}[$index]{'name'};

		UpdateWrapperInventory($index);

		if ((!$cart{'full'} || $cart{'add'} ne $name) && $cart{'items_max'} > 0 && $cartItems{lc($name)} > 0) {
			$cart{'full'} = 0;
			$cart{'add'} = $name;

			if ($cart{'items'} >= $cart{'items_max'}) {
				for ($i=0; $i < @{$cart{'inventory'}}; $i++) {
					next if (!%{$cart{'inventory'}[$i]});

					if ($cart{'inventory'}[$i]{'name'} eq $name) {
						sendCartAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$index]{'index'}, $amount);
					}
				}
			} else {
				sendCartAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$index]{'index'}, $amount);
			}
		}
	} elsif ($event == $EV_INVENTORY_REMOVED) {
		my $index = shift;
		my $amount = shift;
		if ($chars[$config{'char'}]{'inventory'}[$index]{'amount'} <= 0) {
			RemoveWrapperInventory($index);
		} else {
			UpdateWrapperInventory($index);
		}
	} elsif ($event == $EV_INVENTORY_UPDATED) {
		my $index = shift;
		UpdateWrapperInventory($index);
	} elsif ($event == $EV_CART_CAP) {
		SetWrapperCartCap();
	} elsif ($event == $EV_CART_ADDED) {
		my $index = shift;
		UpdateWrapperCart($index);
	} elsif ($event == $EV_CART_REMOVED) {
		my $index = shift;
		if ($cart{'inventory'}[$index]{'amount'} <= 0) {
			RemoveWrapperCart($index);
		} else {
			UpdateWrapperCart($index);
		}
	} elsif ($event == $EV_CART_UPDATED) {
		my $index = shift;
		UpdateWrapperCart($index);
	} elsif ($event == $EV_STORAGE_CAP) {
		SetWrapperStorageCap();
	} elsif ($event == $EV_STORAGE_OPENED) {
		ShowWrapperStorage();
	} elsif ($event == $EV_STORAGE_ADDED) {
		my $index = shift;
		UpdateWrapperStorage($index);
	} elsif ($event == $EV_STORAGE_REMOVED) {
		my $index = shift;
		if ($storage{'inventory'}[$index]{'amount'} <= 0) {
			RemoveWrapperStorage($index);
		} else {
			UpdateWrapperStorage($index);
		}
	} elsif ($event == $EV_STORAGE_UPDATED) {
		my $index = shift;
		UpdateWrapperStorage($index);
	} elsif ($event == $EV_STORAGE_CLOSED) {
		HideWrapperStorage();
	} elsif ($event == $EV_SKILL_CLEARED) {
		ClearWrapperSkill();
	} elsif ($event == $EV_SKILL_ADDED) {
		my $id = shift;
		UpdateWrapperSkill($id);
	} elsif ($event == $EV_SKILL_UPDATED) {
		my $id = shift;
		UpdateWrapperSkill($id);
	} elsif ($event == $EV_GUILD_UPDATED) {
		UpdateWrapperGuild();
	} elsif ($event == $EV_GUILD_MEMBER_CLEARED) {
		ClearWrapperGuildMember();
	} elsif ($event == $EV_GUILD_MEMBER_ADDED) {
		my $index = shift;
		UpdateWrapperGuildMember($index);
	} elsif ($event == $EV_GUILD_MEMBER_UPDATED) {
		my $index = shift;
		UpdateWrapperGuildMember($index);
	} elsif ($event == $EV_GUILD_ALLIES_CLEARED) {
		ClearWrapperGuildAllies();
	} elsif ($event == $EV_GUILD_ALLIES_ADDED) {
		my $index = shift;
		AddWrapperGuildAllies($index);
	} elsif ($event == $EV_GUILD_ALLIES_REMOVED) {
		my $index = shift;
		ClearWrapperGuildAllies();
		for ($i = 0; $i < @{$chars[$config{'char'}]{'guild'}{'allies'}}; $i++) {
			if ($i != $index) {
				AddWrapperGuildAllies($i);
			}
		}
	} elsif ($event == $EV_GUILD_ENEMY_CLEARED) {
		ClearWrapperGuildEnemy();
	} elsif ($event == $EV_GUILD_ENEMY_ADDED) {
		my $index = shift;
		AddWrapperGuildEnemy($index);
	} elsif ($event == $EV_GUILD_ENEMY_REMOVED) {
		my $index = shift;
		ClearWrapperGuildEnemy();
		for ($i = 0; $i < @{$chars[$config{'char'}]{'guild'}{'enemy'}}; $i++) {
			if ($i != $index) {
				AddWrapperGuildEnemy($i);
			}
		}
	} elsif ($event == $EV_GUILD_JOIN_REQUEST) {
		if (!$config{'guildAutoDeny'}) {
			ShowWrapperGuildJoinRequest();
		}
	} elsif ($event == $EV_GUILD_ALLY_REQUEST) {
		if (!$config{'guildAutoDeny'}) {
			ShowWrapperGuildAllyRequest();
		}
	} elsif ($event == $EV_PARTY_JOIN) {
		SetWrapperPartyTitle();
		UpdateWrapperParty($accountID);
	} elsif ($event == $EV_PARTY_LEFT) {
		SetWrapperPartyTitle();
		ClearWrapperParty();
	} elsif ($event == $EV_PARTY_UPDATED) {
		SetWrapperPartyTitle();
		UpdateWrapperParty($accountID);
	} elsif ($event == $EV_PARTY_SHARE) {
	} elsif ($event == $EV_PARTY_NOSHARE) {
	} elsif ($event == $EV_DEAL_ADD) {
		my $i = shift;
		my $amount = shift;
		AddWrapperDealItem(0, $i, $amount);
	} elsif ($event == $EV_DEAL_ADD_ZENY) {
		my $zeny = shift;
		AddWrapperDealZeny(0, $zeny);
	} elsif ($event == $EV_DEAL_CONFIRM) {
		ConfirmWrapperDeal(0)
	} elsif ($event == $EV_DEAL_CANCELLED) {
		HideWrapperDeal();
	} elsif ($event == $EV_DEAL_COMPLETED) {
		HideWrapperDeal();
	} elsif ($event == $EV_NO_ARROW) {
		UpdateWrapperEvent("NO ARROW");

		if (timeOut(\%{$timeout{'ai_equip_auto'}})) {
			$chars[$config{'char'}]{'equip_slot'} = "def";
			EquipSlot("def");
			$timeout{'ai_equip_auto'}{'time'} = time;
		}
	} elsif ($event == $EV_CRITICAL || $event == $EV_WARNING || $event == $EV_OPTION) {
		my $name = shift;
		my $on = shift;

		$on = ($on) ? "on" : "off";
		if ($ID eq $monster{'id'}) {
			PrintMessage("$name is $on.", "red");
		}
	} elsif ($event == $EV_PET_BORN || $event == $EV_PET_FRIENDLY || $event == $EV_PET_HUNGRY || $event == $EV_PET_ACCESSORY || $event == $EV_PET_ACTION || $event == $EV_PET_SPAWNED || $event == $EV_PET_KEEP || $event == $EV_PET_INFO) {
		UpdateWrapperStatus();
	} elsif ($event == $EV_PET_CATCH) {
		my $index = shift;
		my $nameID;

		$timecount{'catch'}{'start'} = time;

		if ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 619) {
			$nameID = 1002; # Unripe Apple
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 620) {
			$nameID = 1113; # Orange Juice
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 621) {
			$nameID = 1031; # Bitter Herb
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 622) {
			$nameID = 1063; # Rainbow Carrot
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 623) {
			$nameID = 1050; # Earthworm the Dude
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 624) {
			$nameID = 1011; # Rotten Fish
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 625) {
			$nameID = 1042; # Lusty Iron
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 626) {
			$nameID = 1035; # Monster Juice
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 627) {
			$nameID = 1167; # Sweet Milk
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 628) {
			$nameID = 1107; # Well-Dried Bone
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 629) {
			$nameID = 1052; # Singing Flower
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 630) {
			$nameID = 1014; # Dew Laden Moss
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 631) {
			$nameID = 1077; # Deadly Noxious Herb
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 632) {
			$nameID = 1019; # Fatty Chubby Earthworm
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 633) {
			$nameID = 1056; # Baked Yam
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 634) {
			$nameID = 1057; # Tropical Banana
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 635) {
			$nameID = 1023; # Horror of Tribe
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 636) {
			$nameID = 1026; # No Recipient
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 637) {
			$nameID = 1110; # Old Broom
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 638) {
			$nameID = 1170; # Silver Knife of Chastity
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 639) {
			$nameID = 1029; # Armlet of Obedience
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 640) {
			$nameID = 1155; # Shining Stone
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 641) {
			$nameID = 1109; # Contracts in Shadow
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 642) {
			$nameID = 1101; # Book of Devil
		} elsif ($chars[$config{'char'}]{'inventory'}[$index]{'nameID'} == 659) {
			$nameID = 1188; # Her Heart
		}

		if ($config{'petAutoCatch'}) {
			sleep($config{'petAutoCatch_wait'});

			foreach (@monstersID) {
				next if ($_ eq "");
				if ($monsters{$_}{'nameID'} == $nameID) {
					sendCatch(\$remote_socket, $_);
					last;
				}
			}
		}
	} elsif ($event == $EV_ARROWCRAFT) {
		ShowWrapperArrowCraft();
	} elsif ($event == $EV_EGG) {
		ShowWrapperEgg();
	} elsif ($event == $EV_IDENTIFY) {
		ShowWrapperIdentify();
	} elsif ($event == $EV_MIXTURE) {
		ShowWrapperMixture();
	}
}

sub OnNpc {
	my $id = shift;
	my $event = shift;

	if ($event == $EV_EXISTS) {
		UpdateWrapperNpc($id, "EXISTS");
	} elsif ($event == $EV_DISAPPEARED) {
		RemoveWrapperNpc($id);
	} elsif ($event == $EV_TALK_DISAPPEARED) {
		HideWrapperNpcCon();
		HideWrapperNpcResp();
		HideWrapperNpcEnd();
		HideWrapperBuySell();
		HideWrapperStore();
	} elsif ($event == $EV_GET_INFO) {
		UpdateWrapperNpc($id, "GET INFO");
	} elsif ($event == $EV_CONTINUE) {
		ShowWrapperNpcCon();
	} elsif ($event == $EV_RESPONSE) {
		ShowWrapperNpcResp();
	} elsif ($event == $EV_DONT_TALK) {
		HideWrapperNpcCon();
		HideWrapperNpcResp();
		ShowWrapperNpcEnd();
	} elsif ($event == $EV_BUY_SELL) {
		ShowWrapperBuySell();
	} elsif ($event == $EV_BUY) {
		HideWrapperBuySell();
		ShowWrapperStore();
	} elsif ($event == $EV_SELL) {
		HideWrapperBuySell();
		EnableWrapperSell(1);
	} elsif ($event == $EV_IMAGE) {
	}
}

sub OnPet {
	my $id = shift;
	my $event = shift;

	if ($chars[$config{'char'}]{'pet'}{'ID'} eq $id) {
		UpdateWrapperStatus();
	}
}

sub Trim {
	my $s = shift;

	$s =~ s/\s+$//g;
	$s =~ s/^\s+//g;

	return $s;
}

sub parseCmdLine {
	my $cmd_line = shift;
	my $param;
	my $noquote;
	my @params;
	my $n;

	$n = 0;
	while ($cmd_line ne "") {
		$cmd_line =~ s/\s+$//g;
		$cmd_line =~ s/^\s+//g;

		($param, $noquote) = $cmd_line =~ /^(\"([\s\S]*?)\")/;
		if ($param eq "") {
			($param) = $cmd_line =~ /^(\w*)/;
		}

		$cmd_line = substr($cmd_line, length($param) + 1);

		if ($noquote ne "") {
			$params[$n] = $noquote;
		} else {
			$params[$n] = $param;
		}

		$n++;
	}

	return @params;
}

sub IsNumber {
	my $n = shift;

	if ($n =~ /^\d+$/ ) {
		return 1;
	}

	return 0;
}

sub Debug {
	my $where = shift;

	foreach (keys %players) {
		next if ($_ eq "");
		if ($players{$_}{'name'} eq "") {
			WriteLog("bug.txt", "$where :: PLAYER :: $ai_seq_begin > $ai_seq[0] :: $switch : ".getHex($_).".\n");
			delete $players{$_};
		}
	}

	foreach (keys %monsters) {
		next if ($_ eq "");
		if ($monsters{$_}{'name'} eq "") {
			WriteLog("bug.txt", "$where :: MONSTER :: $ai_seq_begin > $ai_seq[0] :: $switch : ".getHex($_).".\n");
			delete $monsters{$_};
		} elsif ($monsters{$_}{'nameID'} < 1000) {
			WriteLog("bug.txt", "$where :: MONSTER ID ($monsters{$_}{'nameID'}) :: $ai_seq_begin > $ai_seq[0] :: $switch : ".getHex($_).".\n");
			delete $monsters{$_};
		}
	}

	foreach (keys %npcs) {
		next if ($_ eq "");
		if ($npcs{$_}{'name'} eq "") {
			WriteLog("bug.txt", "$where :: NPC :: $ai_seq_begin > $ai_seq[0] :: $switch : ".getHex($_).".\n");
			delete $npcs{$_};
		}
	}

	foreach (keys %pets) {
		next if ($_ eq "");
		if ($pets{$_}{'name'} eq "") {
			WriteLog("bug.txt", "$where :: PET :: $ai_seq_begin > $ai_seq[0] :: $switch : ".getHex($_).".\n");
			delete $pets{$_};
		}
	}

	foreach (keys %portals) {
		next if ($_ eq "");
		if ($portals{$_}{'name'} eq "") {
			WriteLog("bug.txt", "$where :: PORTAL :: $ai_seq_begin > $ai_seq[0] :: $switch : ".getHex($_).".\n");
			delete $portals{$_};
		}
	}
}
