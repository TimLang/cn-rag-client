#########################################################################
#  OpenKore - Network subsystem
#  Copyright (c) 2006 OpenKore Team
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################
# Servertype overview: http://wiki.openkore.com/index.php/ServerType
package Network::Receive::ServerType0;

use strict;
use Network::Receive ();
use base qw(Network::Receive);
use Time::HiRes qw(time usleep);

use AI;
use Log qw(message warning error debug);

# from old receive.pm
use Task::Wait;
use Task::Function;
use Task::Chained;
use Carp::Assert;
use Scalar::Util;
use Exception::Class ('Network::Receive::InvalidServerType', 'Network::Receive::CreationError');

use Globals;
use Actor;
use Actor::You;
use Actor::Player;
use Actor::Monster;
use Actor::Party;
use Actor::Item;
use Actor::Unknown;
use Field;
use Settings;
use FileParsers;
use Interface;
use Misc;
use Network;
use Network::MessageTokenizer;
use Network::Send ();
use Plugins;
use Utils;
use Skill;
use Utils::Assert;
use Utils::Exceptions;
use Utils::Crypton;
use Translation qw(T TF);
use I18N qw(bytesToString stringToBytes);
use encoding 'utf8';
# from old receive.pm

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new();

	$self->{packet_list} = {
		'0069' => ['account_server_info', 'x2 a4 a4 a4 a4 a26 C a*', [qw(sessionID accountID sessionID2 lastLoginIP lastLoginTime accountSex serverInfo)]],
		'006A' => ['login_error', 'C Z20', [qw(type date)]],
		'006B' => ['received_characters', 'v C3 a*', [qw(len total_slot premium_start_slot premium_end_slot charInfo)]], # struct varies a lot, this one is from XKore 2
		'006C' => ['login_error_game_login_server'],
		'006D' => ['character_creation_successful', 'a4 V9 v V2 v14 Z24 C6 v2', [qw(ID exp zeny exp_job lv_job opt1 opt2 option stance manner points_free hp hp_max sp sp_max walk_speed type hair_style weapon lv points_skill lowhead shield tophead midhead hair_color clothes_color name str agi vit int dex luk slot renameflag)]],
		'006E' => ['character_creation_failed', 'C' ,[qw(type)]],
		'006F' => ['character_deletion_successful'],
		'0070' => ['character_deletion_failed'],
		'0071' => ['received_character_ID_and_Map', 'a4 Z16 a4 v', [qw(charID mapName mapIP mapPort)]],
		'0072' => ['received_characters', 'v a*', [qw(len charInfo)]], # struct unknown, this one is from XKore 2
		'0073' => ['map_loaded', 'V a3', [qw(syncMapSync coords)]],
		'0075' => ['changeToInGameState'],
		'0077' => ['changeToInGameState'],
		'0078' => ['actor_exists',	'a4 v14 a4 a2 v2 C2 a3 C3 v',		[qw(ID walk_speed opt1 opt2 option type hair_style weapon lowhead shield tophead midhead hair_color clothes_color head_dir guildID emblemID manner opt3 stance sex coords unknown1 unknown2 act lv)]], #standing
		'0079' => ['actor_connected',	'a4 v14 a4 a2 v2 C2 a3 C2 v',		[qw(ID walk_speed opt1 opt2 option type hair_style weapon lowhead shield tophead midhead hair_color clothes_color head_dir guildID emblemID manner opt3 stance sex coords unknown1 unknown2 lv)]], #spawning
		'007A' => ['changeToInGameState'],
		'007B' => ['actor_moved',	'a4 v8 V v6 a4 a2 v2 C2 a6 C2 v',	[qw(ID walk_speed opt1 opt2 option type hair_style weapon lowhead tick shield tophead midhead hair_color clothes_color head_dir guildID emblemID manner opt3 stance sex coords unknown1 unknown2 lv)]], #walking
		'007C' => ['actor_spawned',	'a4 v14 C2 a3 C2',					[qw(ID walk_speed opt1 opt2 option hair_style weapon lowhead type shield tophead midhead hair_color clothes_color head_dir stance sex coords unknown1 unknown2)]], #spawning: eA does not send this for players
		'007F' => ['received_sync', 'V', [qw(time)]],
		'0080' => ['actor_died_or_disappeared', 'a4 C', [qw(ID type)]],
		'0081' => ['errors', 'C', [qw(type)]],
		'0086' => ['actor_display', 'a4 a6 V', [qw(ID coords tick)]],
		'0087' => ['character_moves', 'a4 a6', [qw(move_start_time coords)]], # 12
		'0088' => ['actor_movement_interrupted', 'a4 v2', [qw(ID x y)]],
		'008A' => ['actor_action', 'a4 a4 a4 V2 v2 C v', [qw(sourceID targetID tick src_speed dst_speed damage div type dual_wield_damage)]],
		'008D' => ['public_chat', 'v a4 Z*', [qw(len ID message)]],
		'008E' => ['self_chat', 'x2 Z*', [qw(message)]],
		'0091' => ['map_change', 'Z16 v2', [qw(map x y)]],
		'0092' => ['map_changed', 'Z16 v2 a4 v', [qw(map x y IP port)]], # 28
		'0095' => ['actor_info', 'a4 Z24', [qw(ID name)]],
		'0097' => ['private_message', 'v Z24 Z*', [qw(len privMsgUser privMsg)]],
		'0098' => ['private_message_sent', 'C', [qw(type)]],
		'009A' => ['system_chat', 'v a*', [qw(len message)]], #maybe use a* instead and $message =~ /\000$//; if there are problems
		'009C' => ['actor_look_at', 'a4 v C', [qw(ID head body)]],
#		'009D' => ['item_exists', 'a4 v C v3 C2', [qw(ID nameID identified x y amount subx suby)]],
		'009D' => ['del_packet'],
		'009E' => ['item_appeared', 'a4 v C v2 C2 v', [qw(ID nameID identified x y subx suby amount)]],
		'00A0' => ['inventory_item_added', 'v3 C3 a8 v C2', [qw(index amount nameID identified broken upgrade cards type_equip type fail)]],
		'00A1' => ['item_disappeared', 'a4', [qw(ID)]],
		'00A3' => ['inventory_items_stackable', 'v a*', [qw(len itemInfo)]],
		'00A4' => ['inventory_items_nonstackable', 'v a*', [qw(len itemInfo)]],
		'00A5' => ['storage_items_stackable', 'v a*', [qw(len itemInfo)]],
		'00A6' => ['storage_items_nonstackable', 'v a*', [qw(len itemInfo)]],
		'00A8' => ['use_item', 'v x2 C', [qw(index amount)]],
		'00AA' => ['equip_item', 'v3 C', [qw(index type viewid success)]],
		'00AC' => ['unequip_item', 'v2 C', [qw(index type success)]],
		'00AF' => ['inventory_item_removed', 'v2', [qw(index amount)]],
		'00B0' => ['stat_info', 'v V', [qw(type val)]],
		'00B1' => ['stat_info', 'v V', [qw(type val)]], # was "exp_zeny_info"
		'00B3' => ['switch_character', 'C', [qw(result)]], # 3
		'00B4' => ['npc_talk', 'v a4 Z*', [qw(len ID msg)]],
		'00B5' => ['npc_talk_continue', 'a4', [qw(ID)]],
		'00B6' => ['npc_talk_close', 'a4', [qw(ID)]],
		'00B7' => ['npc_talk_responses'],
		'00BC' => ['stats_added', 'v x C', [qw(type val)]], # actually 'v C2', 'type result val'
		'00BD' => ['stats_info', 'v C12 v14', [qw(points_free str points_str agi points_agi vit points_vit int points_int dex points_dex luk points_luk attack attack_bonus attack_magic_min attack_magic_max def def_bonus def_magic def_magic_bonus hit flee flee_bonus critical stance manner)]], # (stance manner) actually are (ASPD plusASPD)
		'00BE' => ['stat_info', 'v C', [qw(type val)]], # was "stats_points_needed"
		'00C0' => ['emoticon', 'a4 C', [qw(ID type)]],
		'00CA' => ['buy_result', 'C', [qw(fail)]],
		'00CB' => ['sell_result', 'C', [qw(fail)]], # 3
		'00C2' => ['users_online', 'V', [qw(users)]],
		'00C3' => ['job_equipment_hair_change', 'a4 C2', [qw(ID part number)]],
		'00C4' => ['npc_store_begin', 'a4', [qw(ID)]],
		'00C6' => ['npc_store_info'],
		'00C7' => ['npc_sell_list', 'v a*', [qw(len itemsdata)]],
		'00D1' => ['ignore_player_result', 'C2', [qw(type error)]],
		'00D2' => ['ignore_all_result', 'C2', [qw(type error)]],
		'00D4' => ['whisper_list'],
		'00E5' => ['deal_request', 'Z24', [qw(user)]],
		'00E7' => ['deal_begin', 'C', [qw(type)]],
		'00E9' => ['deal_add_other', 'V v C3 a8', [qw(amount nameID identified broken upgrade cards)]],
		'00EA' => ['deal_add_you', 'v C', [qw(index fail)]],
		'00EC' => ['deal_finalize', 'C', [qw(type)]],
		'00EE' => ['deal_cancelled'],
		'00F0' => ['deal_complete'],
		'00F2' => ['storage_opened', 'v2', [qw(items items_max)]],
		'00F4' => ['storage_item_added', 'v V v C3 a8', [qw(index amount nameID identified broken upgrade cards)]],
		'00F6' => ['storage_item_removed', 'v V', [qw(index amount)]],
		'00F8' => ['storage_closed'],
		'00FA' => ['party_organize_result', 'C', [qw(fail)]],
		'00FB' => ['party_users_info', 'x2 Z24', [qw(party_name)]],
		'00FD' => ['party_invite_result', 'Z24 C', [qw(name type)]],
		'00FE' => ['party_invite', 'a4 Z24', [qw(ID name)]],
		'0101' => ['party_exp', 'v x2', [qw(type)]],
		'0104' => ['party_join', 'a4 V v2 C Z24 Z24 Z16', [qw(ID role x y type name user map)]],
		'0105' => ['party_leave', 'a4 Z24 C', [qw(ID name result)]],
		'0106' => ['party_hp_info', 'a4 v2', [qw(ID hp hp_max)]],
		'0107' => ['party_location', 'a4 v2', [qw(ID x y)]],
		'0108' => ['item_upgrade', 'v3', [qw(type index upgrade)]],
		'0109' => ['party_chat', 'x2 a4 Z*', [qw(ID message)]],
		'0110' => ['skill_use_failed', 'v3 C2', [qw(skillID btype unknown fail type)]],
		'010A' => ['mvp_item', 'v', [qw(itemID)]],
		'010B' => ['mvp_you', 'V', [qw(expAmount)]],
		'010C' => ['mvp_other', 'a4', [qw(ID)]],
		'010E' => ['skill_update', 'v4 C', [qw(skillID lv sp range up)]], # range = skill range, up = this skill can be leveled up further
		'010F' => ['skills_list'],
		'0111' => ['skill_add', 'v2 x2 v3 Z24', [qw(skillID target lv sp range name)]],
		'0114' => ['skill_use', 'v a4 a4 V3 v3 C', [qw(skillID sourceID targetID tick src_speed dst_speed damage level option type)]],
		'0117' => ['skill_use_location', 'v a4 v3 V', [qw(skillID sourceID lv x y tick)]],
		'0119' => ['character_status', 'a4 v3 C', [qw(ID opt1 opt2 option stance)]],
		'011A' => ['skill_used_no_damage', 'v2 a4 a4 C', [qw(skillID amount targetID sourceID success)]],
		'011C' => ['warp_portal_list', 'v Z16 Z16 Z16 Z16', [qw(type memo1 memo2 memo3 memo4)]],
		'011E' => ['memo_success', 'C', [qw(fail)]],
		'011F' => ['area_spell', 'a4 a4 v2 C2', [qw(ID sourceID x y type fail)]],
		'0120' => ['area_spell_disappears', 'a4', [qw(ID)]],
		'0121' => ['cart_info', 'v2 V2', [qw(items items_max weight weight_max)]],
		'0122' => ['cart_items_nonstackable', 'v a*', [qw(len itemInfo)]],
		'0123' => ['cart_items_stackable', 'v a*', [qw(len itemInfo)]],
		'0124' => ['cart_item_added', 'v V v C3 a8', [qw(index amount nameID identified broken upgrade cards)]],
		'0125' => ['cart_item_removed', 'v V', [qw(index amount)]],
		'012C' => ['cart_add_failed', 'C', [qw(fail)]],
		'012D' => ['shop_skill', 'v', [qw(number)]],
		'0137' => ['shop_sold', 'v2', [qw(number amount)]],
		'0139' => ['monster_ranged_attack', 'a4 v5', [qw(ID sourceX sourceY targetX targetY range)]],
		'013A' => ['attack_range', 'v', [qw(type)]],
		'013B' => ['arrow_none', 'v', [qw(type)]],
		'013C' => ['arrow_equipped', 'v', [qw(index)]],
		'013D' => ['hp_sp_changed', 'v2', [qw(type amount)]],
		'013E' => ['skill_cast', 'a4 a4 v5 V', [qw(sourceID targetID x y skillID unknown type wait)]],
		'0141' => ['stat_info2', 'V2 l', [qw(type val val2)]],
		'0142' => ['npc_talk_number', 'a4', [qw(ID)]],
		'0144' => ['minimap_indicator', 'a4 V3 C5', [qw(npcID type x y ID blue green red alpha)]],
		'0147' => ['item_skill', 'v6 A*', [qw(skillID targetType unknown skillLv sp unknown2 skillName)]],
		'0148' => ['resurrection', 'a4 v', [qw(targetID type)]],
		'014A' => ['manner_message', 'V', [qw(type)]],
		'014B' => ['GM_silence', 'C Z24', [qw(type name)]],
		'016A' => ['guild_request', 'a4 Z24', [qw(ID name)]],
		'0177' => ['identify_list'],
		'0179' => ['identify', 'v C', [qw(index flag)]],
		'017B' => ['card_merge_list'],
		'017D' => ['card_merge_status', 'v2 C', [qw(item_index card_index fail)]],
		'017F' => ['guild_chat', 'x2 Z*', [qw(message)]],
		'0187' => ['sync_request', 'a4', [qw(ID)]],
		'0188' => ['item_upgrade', 'v3', [qw(type index upgrade)]],
		'0189' => ['no_teleport', 'v', [qw(fail)]],
		'018B' => ['quit_response', 'v', [qw(fail)]], # 4 # ported from kRO_Sakexe_0
		'018C' => ['sense_result', 'v3 V v4 C9', [qw(nameID level size hp def race mdef element ice earth fire wind poison holy dark spirit undead)]],
		'018D' => ['forge_list'],
		'018F' => ['refine_result', 'v2', [qw(fail nameID)]],
		'0191' => ['talkie_box', 'a4 Z80', [qw(ID message)]], # talkie box message
		'0192' => ['map_change_cell', 'v3 Z16', [qw(x y type map_name)]], # ex. due to ice wall
		'0194' => ['character_name', 'a4 Z24', [qw(ID name)]],
		'0195' => ['actor_info', 'a4 Z24 Z24 Z24 Z24', [qw(ID name partyName guildName guildTitle)]],
		'0196' => ['actor_status_active', 'v a4 C', [qw(type ID flag)]],
		'0199' => ['map_property', 'v', [qw(type)]],
		'019A' => ['pvp_rank', 'V3', [qw(ID rank num)]],
		'019B' => ['unit_levelup', 'a4 V', [qw(ID type)]],
		'019E' => ['pet_capture_process'],
		'01A0' => ['pet_capture_result', 'C', [qw(success)]],
		'01A2' => ['pet_info', 'Z24 C v5', [qw(name renameflag level hungry friendly accessory type)]],
		'01A3' => ['pet_food', 'C v', [qw(success foodID)]],
		'01A4' => ['pet_info2', 'C a4 V', [qw(type ID value)]],
		'01A6' => ['egg_list'],
		'01AA' => ['pet_emotion', 'a4 V', [qw(ID type)]],
		'01AB' => ['stat_info', 'a4 v V', [qw(ID type val)]], # was "actor_muted"; is struct/handler correct at all?
		'01AC' => ['actor_trapped', 'a4', [qw(ID)]],
		'01AD' => ['arrowcraft_list'],
		'01B0' => ['monster_typechange', 'a4 a V', [qw(ID unknown type)]],
		'01B3' => ['npc_image', 'Z64 C', [qw(npc_image type)]],
		'01B5' => ['account_payment_info', 'V2', [qw(D_minute H_minute)]],
		'01B9' => ['cast_cancelled', 'a4', [qw(ID)]],
		'01C3' => ['local_broadcast', 'x2 a3 x9 Z*', [qw(color message)]],
		'01C4' => ['storage_item_added', 'v V v C4 a8', [qw(index amount nameID type identified broken upgrade cards)]],
		'01C5' => ['cart_item_added', 'v V v C4 a8', [qw(index amount nameID type identified broken upgrade cards)]],
		'01C8' => ['item_used', 'v2 a4 v C', [qw(index itemID ID remaining success)]],
		'01C9' => ['area_spell', 'a4 a4 v2 C2 C Z80', [qw(ID sourceID x y type fail scribbleLen scribbleMsg)]],
		'01CD' => ['sage_autospell', 'x2 a*', [qw(autospell_list)]],
		'01CF' => ['devotion', 'a4 a20 v', [qw(sourceID targetIDs range)]],
		'01D0' => ['revolving_entity', 'a4 v', [qw(sourceID entity)]],
		'01D1' => ['blade_stop', 'a4 a4 V', [qw(sourceID targetID active)]],
		'01D2' => ['combo_delay', 'a4 V', [qw(ID delay)]],
		'01D4' => ['npc_talk_text', 'a4', [qw(ID)]],
		'01D7' => ['player_equipment', 'a4 C v2', [qw(sourceID type ID1 ID2)]],
		'01D8' => ['actor_exists', 'a4 v14 a4 a2 v2 C2 a3 C3 v',		[qw(ID walk_speed opt1 opt2 option type hair_style weapon shield lowhead tophead midhead hair_color clothes_color head_dir guildID emblemID manner opt3 stance sex coords unknown1 unknown2 act lv)]], # standing
		'01D9' => ['actor_connected', 'a4 v14 a4 a2 v2 C2 a3 C2 v',		[qw(ID walk_speed opt1 opt2 option type hair_style weapon shield lowhead tophead midhead hair_color clothes_color head_dir guildID emblemID manner opt3 stance sex coords unknown1 unknown2 lv)]], # spawning
		'01DA' => ['actor_moved', 'a4 v9 V v5 a4 a2 v2 C2 a6 C2 v',		[qw(ID walk_speed opt1 opt2 option type hair_style weapon shield lowhead tick tophead midhead hair_color clothes_color head_dir guildID emblemID manner opt3 stance sex coords unknown1 unknown2 lv)]], # walking
		'01DC' => ['secure_login_key', 'x2 a*', [qw(secure_key)]],
		'01D6' => ['map_property2', 'v', [qw(type)]],
		'01DE' => ['skill_use', 'v a4 a4 V4 v2 C', [qw(skillID sourceID targetID tick src_speed dst_speed damage level option type)]],
		'01E0' => ['GM_req_acc_name', 'a4 Z24', [qw(targetID accountName)]],
		'01E1' => ['revolving_entity', 'a4 v', [qw(sourceID entity)]],
		'01E9' => ['party_join', 'a4 V v2 C Z24 Z24 Z16 v C2', [qw(ID role x y type name user map lv item_pickup item_share)]],
		'01EE' => ['inventory_items_stackable', 'v a*', [qw(len itemInfo)]],
		'01EF' => ['cart_items_stackable', 'v a*', [qw(len itemInfo)]],
		'01F0' => ['storage_items_stackable', 'v a*', [qw(len itemInfo)]],
		'01F3' => ['misc_effect', 'a4 V', [qw(ID effect)]], # weather/misceffect2 packet
		'01F4' => ['deal_request', 'Z24 a4 v', [qw(user ID level)]],
		'01F5' => ['deal_begin', 'C a4 v', [qw(type targetID level)]],
		'01F6' => ['adopt_request', 'a4 a4 Z24', [qw(sourceID targetID name)]],
		#'01F8' => ['adopt_unknown'], # clif_adopt_process
		'01FC' => ['repair_list'],
		'01FE' => ['repair_result', 'v C', [qw(nameID flag)]],
		'01FF' => ['high_jump', 'a4 v2', [qw(ID x y)]],
		'0205' => ['divorced', 'Z24', [qw(name)]], # clif_divorced
		'0207' => ['friend_request', 'a4 a4 Z24', [qw(accountID charID name)]],
		'020E' => ['taekwon_packets', 'Z24 a4 C2', [qw(name ID value flag)]],
		'020F' => ['pvp_point', 'V2', [qw(AID GID)]], #TODO: PACKET_CZ_REQ_PVPPOINT
		'0215' => ['gospel_buff_aligned', 'a4', [qw(ID)]],
		'0216' => ['adopt_reply', 'V', [qw(type)]],
		'021B' => ['blacksmith_points', 'V2', [qw(points total)]],
		'021C' => ['alchemist_point', 'V2', [qw(points total)]],
		'0221' => ['upgrade_list'],
		'0223' => ['upgrade_message', 'a4 v', [qw(type itemID)]],
		'0224' => ['taekwon_rank', 'V2', [qw(type rank)]],
		'0229' => ['character_status', 'a4 v2 V C', [qw(ID opt1 opt2 option stance)]],
		'022A' => ['actor_exists', 'a4 v3 V v10 a4 a2 v V C2 a3 C3 v',		[qw(ID walk_speed opt1 opt2 option type hair_style weapon shield lowhead tophead midhead hair_color clothes_color head_dir guildID emblemID manner opt3 stance sex coords unknown1 unknown2 act lv)]], # standing
		'022B' => ['actor_connected', 'a4 v3 V v10 a4 a2 v V C2 a3 C2 v',		[qw(ID walk_speed opt1 opt2 option type hair_style weapon shield lowhead tophead midhead hair_color clothes_color head_dir guildID emblemID manner opt3 stance sex coords unknown1 unknown2 lv)]], # spawning
		'022C' => ['actor_moved', 'a4 v3 V v5 V v5 a4 a2 v V C2 a6 C2 v',			[qw(ID walk_speed opt1 opt2 option type hair_style weapon shield lowhead tick tophead midhead hair_color clothes_color head_dir guildID emblemID manner opt3 stance sex coords unknown1 unknown2 lv)]], # walking
		'022E' => ['homunculus_property', 'Z24 C v16 V2 v2', [qw(name state level hunger intimacy accessory atk matk hit critical def mdef flee aspd hp hp_max sp sp_max exp exp_max points_skill attack_range)]],
		'022F' => ['homunculus_food', 'C v', [qw(success foodID)]],
		'0230' => ['homunculus_info', 'C2 a4 V',[qw(type state ID val)]],
		'0235' => ['skills_list'], # homunculus skills
		# homunculus skill update
		'0239' => ['skill_update', 'v4 C', [qw(skillID lv sp range up)]], # range = skill range, up = this skill can be leveled up further
		'023A' => ['storage_password_request', 'v', [qw(flag)]],
		'023C' => ['storage_password_result', 'v2', [qw(type val)]],
		'023D' => ['del_packet'], #OFF []
		'023E' => ['storage_password_request', 'v', [qw(flag)]],
		'025A' => ['cooking_list', 'v', [qw(type)]],
		'027B' => ['premium_rates_info', 'V3', [qw(exp death drop)]],
		# tRO new packets, need some work on them
		'0283' => ['account_id', 'a4', [qw(accountID)]],
		'0284' => ['GANSI_RANK', 'c24 c24 c24 c24 c24 c24 c24 c24 c24 c24 V10 v', [qw(name1 name2 name3 name4 name5 name6 name7 name8 name9 name10 pt1 pt2 pt3 pt4 pt5 pt6 pt7 pt8 pt9 pt10 switch)]], #TODO: PACKET_ZC_GANGSI_RANK
		'0287' => ['cash_dealer'],
		'0289' => ['cash_buy_fail', 'V2 v', [qw(cash_points kafra_points fail)]],
		'028A' => ['character_status', 'a4 V3', [qw(ID option lv opt3)]],
		'0291' => ['message_string', 'v', [qw(msg_id)]],
		'0293' => ['boss_map_info', 'C V2 v2 x4 Z24', [qw(flag x y hours minutes name)]],
		'0294' => ['book_read', 'a4 a4', [qw(bookID page)]],
		'0295' => ['inventory_items_nonstackable', 'v a*', [qw(len itemInfo)]],
		'0296' => ['storage_items_nonstackable', 'v a*', [qw(len itemInfo)]],
		'0297' => ['cart_items_nonstackable', 'v a*', [qw(len itemInfo)]],
		'0298' => ['rental_time', 'v V', [qw(nameID seconds)]],
		'0299' => ['rental_expired', 'v2', [qw(unknown nameID)]],
		'029A' => ['inventory_item_added', 'v3 C3 a8 v C2 a4', [qw(index amount nameID identified broken upgrade cards type_equip type fail cards_ext)]],
		'029B' =>  ['mercenary_init', 'a4 v8 Z24 v V5 v V2 v',	[qw(ID atk matk hit critical def mdef flee aspd name level hp hp_max sp sp_max contract_end faith summons kills attack_range)]],
		'029D' => ['skills_list'], # mercenary skills
		'02A2' => ['stat_info', 'v V', [qw(type val)]], # was "mercenary_param_change"
		'02AA' => ['cash_password_request', 'v', [qw(info)]], #TODO: PACKET_ZC_REQ_CASH_PASSWORD
		'02AC' => ['cash_password_result', 'v2', [qw(info count)]], #TODO: PACKET_ZC_RESULT_CASH_PASSWORD
		# mRO PIN code Check
		'02AD' => ['login_pin_code_request', 'v V', [qw(flag key)]],
		# Packet Prefix encryption Support
		'02AE' => ['initialize_message_id_encryption', 'V2', [qw(param1 param2)]],
		# tRO new packets (2008-09-16Ragexe12_Th)
		'02B1' => ['quest_all_list', 'v V', [qw(len amount)]],
		'02B2' => ['quest_all_mission', 'v V', [qw(len amount)]],				# var len
		'02B3' => ['quest_add', 'V C V2 v', [qw(questID active time_start time amount)]],
		'02B4' => ['quest_delete', 'V', [qw(questID)]],
		'02B5' => ['quest_update_mission_hunt', 'v2 a*', [qw(len amount mobInfo)]],		# var len
		'02B7' => ['quest_active', 'V C', [qw(questID active)]],
		'02B8' => ['party_show_picker', 'a4 v C3 a8 v C', [qw(sourceID nameID identified broken upgrade cards location type)]],
		'02B9' => ['hotkeys'],
		'02C5' => ['party_invite_result', 'Z24 V', [qw(name type)]],
		'02C6' => ['party_invite', 'a4 Z24', [qw(ID name)]],
		'02C9' => ['party_allow_invite', 'C', [qw(type)]],
		'02CA' => ['login_error_game_login_server', 'C', [qw(type)]],
		'02CB' => ['instance_window_start', 'Z61 v', [qw(name flag)]],
		'02CC' => ['instance_window_queue', 'C', [qw(flag)]],
		'02CD' => ['instance_window_join', 'Z61 V2', [qw(name time_remaining time_close)]],
		'02CE' => ['instance_window_leave', 'C', [qw(flag)]],
		'02D0' => ['inventory_items_nonstackable', 'v a*', [qw(len itemInfo)]],
		'02D1' => ['storage_items_nonstackable', 'v a*', [qw(len itemInfo)]],
		'02D2' => ['cart_items_nonstackable', 'v a*', [qw(len itemInfo)]],
		'02D4' => ['inventory_item_added', 'v3 C3 a8 v C2 a4 v', [qw(index amount nameID identified broken upgrade cards type_equip type fail expire unknown)]],
		'02D5' => ['ISVR_DISCONNECT'], #TODO: PACKET_ZC_ISVR_DISCONNECT
		'02D7' => ['show_eq', 'v Z24 v7 C a*', [qw(len name type hair_style tophead midhead lowhead hair_color clothes_color sex equips_info)]], #type is job
		'02D9' => ['show_eq_msg_other', 'V2', [qw(unknown flag)]],
		'02DA' => ['show_eq_msg_self', 'C', [qw(type)]],
		'02E1' => ['actor_action', 'a4 a4 a4 V3 v C V', [qw(sourceID targetID tick src_speed dst_speed damage div type dual_wield_damage)]],
		'02E7' => ['map_property', 'v2 a*', [qw(len type info_table)]],
		'02E8' => ['inventory_items_stackable', 'v a*', [qw(len itemInfo)]],
		'02E9' => ['cart_items_stackable', 'v a*', [qw(len itemInfo)]],
		'02EA' => ['storage_items_stackable', 'v a*', [qw(len itemInfo)]],
		'02EB' => ['map_loaded', 'V a3 x2 v', [qw(syncMapSync coords unknown)]],
		'02EC' => ['actor_exists', 'x a4 v3 V v5 V v5 a4 a4 V C2 a6 x2 v2',[qw(ID walk_speed opt1 opt2 option type hair_style weapon shield lowhead tick tophead midhead hair_color clothes_color head_dir guildID emblemID opt3 stance sex coords lv unknown)]], # Moving
		'02ED' => ['actor_connected', 'a4 v3 V v10 a4 a4 V C2 a3 v3',			[qw(ID walk_speed opt1 opt2 option type hair_style weapon shield lowhead tophead midhead hair_color clothes_color head_dir guildID emblemID opt3 stance sex coords act lv unknown)]], # Spawning
		'02EE' => ['actor_moved', 'a4 v3 V v10 a4 a4 V C2 a3 x v3',		[qw(ID walk_speed opt1 opt2 option type hair_style weapon shield lowhead tophead midhead hair_color clothes_color head_dir guildID emblemID opt3 stance sex coords act lv unknown)]], # Standing
		'02EF' => ['font', 'a4 v', [qw(ID fontID)]],
		'02F0' => ['progress_bar', 'V2', [qw(color time)]],
		'02F2' => ['progress_bar_stop'],
		'040C' => ['local_broadcast', 'v a4 v4 Z*', [qw(len color font_type font_size font_align font_y message)]], #TODO: PACKET_ZC_BROADCAST3
		'043D' => ['skill_post_delay', 'v V', [qw(ID time)]],
		'043E' => ['skill_post_delaylist'],
		'043F' => ['actor_status_active', 'v a4 C V4', [qw(type ID flag tick unknown1 unknown2 unknown3)]],
		'0440' => ['millenium_shield', 'a4 v2', [qw(ID num state)]],
		'0441' => ['skill_delete', 'v', [qw(ID)]], #TODO: PACKET_ZC_SKILLINFO_DELETE
		'0442' => ['sage_autospell', 'x2 V a*', [qw(why autoshadowspell_list)]],
		'0444' => ['cash_item_list', 'v V3 c v', [qw(len cash_point price discount_price type item_id)]], #TODO: PACKET_ZC_SIMPLE_CASH_POINT_ITEMLIST
		'0446' => ['minimap_indicator', 'a4 v4', [qw(npcID x y effect qtype)]],
		'0449' => ['hack_shield_alarm'],
		'07D8' => ['party_exp', 'V C2', [qw(type itemPickup itemDivision)]],
		'07D9' => ['hotkeys'], # 268 # hotkeys:38
		'07DB' => ['stat_info', 'v V', [qw(type val)]], # 8
		'07E1' => ['skill_update', 'v V v3 C', [qw(skillID type lv sp range up)]],
		'07E3' => ['skill_exchange_item', 'V', [qw(type)]], #TODO: PACKET_ZC_ITEMLISTWIN_OPEN
		'07E2' => ['msg_string', 'v V', [qw(index para1)]],
		'07E6' => ['skill_msg', 'v V', [qw(id msgid)]],
		'07F6' => ['exp', 'a4 V v2', [qw(ID val type flag)]], # 14 # type: 1 base, 2 job; flag: 0 normal, 1 quest # TODO: use. I think this replaces the exp gained message trough guildchat hack
		'07F7' => ['actor_exists', 'v C a4 v3 V v5 a4 v5 a4 a2 v V C2 a6 C2 v2 Z*', [qw(len object_type ID walk_speed opt1 opt2 option type hair_style weapon shield lowhead tick tophead midhead hair_color clothes_color head_dir guildID emblemID manner opt3 stance sex coords xSize ySize lv font name)]], # -1 # walking
		'07F8' => ['actor_connected', 'v C a4 v3 V v10 a4 a2 v V C2 a3 C2 v2 Z*', [qw(len object_type ID walk_speed opt1 opt2 option type hair_style weapon shield lowhead tophead midhead hair_color clothes_color head_dir guildID emblemID manner opt3 stance sex coords xSize ySize lv font name)]], # -1 # spawning
		'07F9' => ['actor_moved', 'v C a4 v3 V v10 a4 a2 v V C2 a3 C3 v2 Z*', [qw(len object_type ID walk_speed opt1 opt2 option type hair_style weapon shield lowhead tophead midhead hair_color clothes_color head_dir guildID emblemID manner opt3 stance sex coords xSize ySize act lv font name)]], # -1 # standing
		'07FA' => ['inventory_item_removed', 'v3', [qw(reason index amount)]], #//0x07fa,8
		'07FB' => ['skill_cast', 'a4 a4 v5 V C', [qw(sourceID targetID x y skillID unknown type wait dispose)]],
		'07FC' => ['party_leader', 'V2', [qw(old new)]],
		'07FD' => ['special_item_obtain', 'v C v c/Z a*', [qw(len type nameID holder etc)]],
		'07FF' => ['define_check', 'v V', [qw(len result)]], #TODO: PACKET_ZC_DEFINE_CHECK
		'080E' => ['party_hp_info', 'a4 V2', [qw(ID hp hp_max)]],
		'080F' => ['deal_add_other', 'v C V C3 a8', [qw(nameID type amount identified broken upgrade cards)]], # 0x080F,20
		'081E' => ['stat_info', 'v V', [qw(type val)]], # 8, Sorcerer's Spirit - not implemented in Kore
		'0828' => ['char_delete2_result', 'a4 V2', [qw(charID result deleteDate)]], # 14
		'082C' => ['char_delete2_cancel_result', 'a4 V', [qw(charID result)]], # 14
		'082D' => ['received_characters', 'v C5 x20 a*', [qw(packet_len normal_slot premium_slot billing_slot producible_slot valid_slot charInfo)]],
		'083E' => ['login_error', 'V Z20', [qw(type date)]],
		'084B' => ['item_appeared', 'a4 v2 C v4', [qw(ID nameID unknown1 identified x y unknown2 amount)]], # 19 TODO   provided by try71023, modified sofax222
		'0856' => ['actor_moved', 'v C a4 v3 V v5 a4 v6 a4 a2 v V C2 a6 C2 v2 Z*', [qw(len object_type ID walk_speed opt1 opt2 option type hair_style weapon shield lowhead tick tophead midhead hair_color clothes_color head_dir costume guildID emblemID manner opt3 stance sex coords xSize ySize lv font name)]], # -1 # walking provided by try71023 TODO: costume
		'0857' => ['actor_exists', 'v C a4 v3 V v11 a4 a2 v V C2 a3 C3 v2 Z*', [qw(len object_type ID walk_speed opt1 opt2 option type hair_style weapon shield lowhead tophead midhead hair_color clothes_color head_dir costume guildID emblemID manner opt3 stance sex coords xSize ySize act lv font name)]], # -1 # spawning provided by try71023
		'0858' => ['actor_connected', 'v C a4 v3 V v11 a4 a2 v V C2 a3 C2 v2 Z*', [qw(len object_type ID walk_speed opt1 opt2 option type hair_style weapon shield lowhead tophead midhead hair_color clothes_color head_dir costume guildID emblemID manner opt3 stance sex coords xSize ySize lv font name)]], # -1 # standing provided by try71023
		'0859' => ['show_eq', 'v Z24 v7 v C a*', [qw(len name jobID hair_style tophead midhead lowhead robe hair_color clothes_color sex equips_info)]],
		'08B9' => ['login_pin_code_request', 'V a4 v', [qw(seed accountID flag)]],
		'08BB' => ['login_pin_new_code_result', 'v V', [qw(flag seed)]],
		'08C7' => ['area_spell', 'x2 a4 a4 v2 C3', [qw(ID sourceID x y type range fail)]], # -1
		'08C8' => ['actor_action', 'a4 a4 a4 V3 x v C V', [qw(sourceID targetID tick src_speed dst_speed damage div type dual_wield_damage)]],
		'08CA' => ['del_packet'],  #OFF
		'08CB' => ['rates_info', 's4 a*', [qw(len exp death drop detail)]],
		'08CF' => ['revolving_entity', 'a4 v v', [qw(sourceID type entity)]],
		'08D2' => ['high_jump', 'a4 v2', [qw(ID x y)]],
		'08FE' => ['del_packet'],  #OFF
		'0900' => ['inventory_items_stackable', 'v a*', [qw(len itemInfo)]],
		'0901' => ['inventory_items_nonstackable', 'v a*', [qw(len itemInfo)]],
		'0902' => ['cart_items_stackable', 'v a*', [qw(len itemInfo)]],
		'0903' => ['cart_items_nonstackable', 'v a*', [qw(len itemInfo)]],
		'0975' => ['storage_items_stackable', 'v Z24 a*', [qw(len title itemInfo)]],
		'0976' => ['storage_items_nonstackable', 'v Z24 a*', [qw(len title itemInfo)]],
		'0981' => ['del_packet'],  #OFF
		'097A' => ['del_packet'],  #OFF
		'09A5' => ['full_or_banned'],  # 服务器已满或者被封号
		'098B' => ['server_full'],  # 服务器已满
		
		# ChatRoom
		'00D6' => ['del_packet'],
		'00D7' => ['del_packet'],
		'00D8' => ['del_packet'],
		'00DA' => ['del_packet'],
		'00DB' => ['del_packet'],
		'00DC' => ['del_packet'],
		'00DD' => ['del_packet'],
		'00DF' => ['del_packet'],
		'00E1' => ['del_packet'],
		# vender
		'0131' => ['del_packet'],
		'0132' => ['del_packet'],
		'0133' => ['del_packet'],
		'0135' => ['del_packet'],
		'0136' => ['del_packet'],
		'0800' => ['del_packet'],
		# guild
		'014C' => ['del_packet'],
		'014E' => ['del_packet'],
		'0152' => ['del_packet'],
		'0154' => ['del_packet'],
		'0156' => ['del_packet'],
		'015A' => ['del_packet'],
		'015C' => ['del_packet'],
		'015E' => ['del_packet'],
		'0160' => ['del_packet'],
		'0162' => ['del_packet'],
		'0163' => ['del_packet'],
		'0166' => ['del_packet'],
		'0167' => ['del_packet'],
		'0169' => ['del_packet'],
		'016C' => ['del_packet'],
		'016D' => ['del_packet'],
		'016F' => ['del_packet'],
		'0171' => ['del_packet'],
		'0173' => ['del_packet'],
		'0174' => ['del_packet'],
		'0181' => ['del_packet'],
		'0182' => ['del_packet'],
		'0184' => ['del_packet'],
		'0185' => ['del_packet'],
		'01B4' => ['del_packet'],
		'01B6' => ['del_packet'],
		'01EB' => ['del_packet'],
		'01EC' => ['del_packet'],
		'01F2' => ['del_packet'],
		'0839' => ['del_packet'],
		# sound_effect
		'01D3' => ['del_packet'],
		'07FE' => ['del_packet'],
		# married
		'01E6' => ['del_packet'],
		'01EA' => ['del_packet'],
		# friend
		'0201' => ['del_packet'],
		'0206' => ['del_packet'],
		'0209' => ['del_packet'],
		'020A' => ['del_packet'],
		# top10
		'0219' => ['del_packet'],
		'021A' => ['del_packet'],
		'0226' => ['del_packet'],
		'0238' => ['del_packet'],
		# battle
		'02DC' => ['battleground_message', 'v a4 Z24 Z*', [qw(len ID name message)]],
		'02DD' => ['battleground_emblem', 'a4 Z24 v', [qw(emblemID name ID)]],
		'02DE' => ['battleground_score', 'v2', [qw(score_lion score_eagle)]],
		'02DF' => ['battleground_position', 'a4 Z24 v3', [qw(ID name job x y)]],
		'02E0' => ['battleground_hp', 'a4 Z24 v2', [qw(ID name hp max_hp)]],
		# captcha
		'07E8' => ['del_packet'],
		'07E9' => ['del_packet'],
		# booking
		'0803' => ['del_packet'],
		'0805' => ['del_packet'],
		'0807' => ['del_packet'],
		'0809' => ['del_packet'],
		'080A' => ['del_packet'],
		'080B' => ['del_packet'],
		# buying
		'0810' => ['del_packet'],
		'0812' => ['del_packet'],
		'0814' => ['del_packet'],
		'0816' => ['del_packet'],
		'0818' => ['del_packet'],
		'081C' => ['del_packet'],
	};

	# Item RECORD Struct's
	$self->{nested} = {
		items_nonstackable => { # EQUIPMENTITEM_EXTRAINFO
			type1 => {
				len => 20,
				types => 'v2 C2 v2 C2 a8',
				keys => [qw(index nameID type identified type_equip equipped broken upgrade cards)],
			},
			type2 => {
				len => 24,
				types => 'v2 C2 v2 C2 a8 l',
				keys => [qw(index nameID type identified type_equip equipped broken upgrade cards expire)],
			},
			type3 => {
				len => 26,
				types => 'v2 C2 v2 C2 a8 l v',
				keys => [qw(index nameID type identified type_equip equipped broken upgrade cards expire bindOnEquipType)],
			},
			type4 => {
				len => 28,
				types => 'v2 C2 v2 C2 a8 l v2',
				keys => [qw(index nameID type identified type_equip equipped broken upgrade cards expire bindOnEquipType sprite_id)],
			},
			type5 => {
				len => 27,
				types => 'v2 C v2 C a8 l v2 C',
				keys => [qw(index nameID type type_equip equipped upgrade cards expire bindOnEquipType sprite_id identified)],
			},
		},
		items_stackable => {
			type1 => {
				len => 10,
				types => 'v2 C2 v2',
				keys => [qw(index nameID type identified amount type_equip)], # type_equip or equipped?
			},
			type2 => {
				len => 18,
				types => 'v2 C2 v2 a8',
				keys => [qw(index nameID type identified amount type_equip cards)],
			},
			type3 => {
				len => 22,
				types => 'v2 C2 v2 a8 l',
				keys => [qw(index nameID type identified amount type_equip cards expire)],
			},
			type5 => {
				len => 22,
				types => 'v2 C v2 a8 l C',
				keys => [qw(index nameID type amount type_equip cards expire identified)],
			},
		},
	};

	return $self;
}

use constant {
	REFUSE_INVALID_ID => 0x0,
	REFUSE_INVALID_PASSWD => 0x1,
	REFUSE_ID_EXPIRED => 0x2,
	ACCEPT_ID_PASSWD => 0x3,
	REFUSE_NOT_CONFIRMED => 0x4,
	REFUSE_INVALID_VERSION => 0x5,
	REFUSE_BLOCK_TEMPORARY => 0x6,
	REFUSE_BILLING_NOT_READY => 0x7,
	REFUSE_NONSAKRAY_ID_BLOCKED => 0x8,
	REFUSE_BAN_BY_DBA => 0x9,
	REFUSE_EMAIL_NOT_CONFIRMED => 0xa,
	REFUSE_BAN_BY_GM => 0xb,
	REFUSE_TEMP_BAN_FOR_DBWORK => 0xc,
	REFUSE_SELF_LOCK => 0xd,
	REFUSE_NOT_PERMITTED_GROUP => 0xe,
	REFUSE_WAIT_FOR_SAKRAY_ACTIVE => 0xf,
	REFUSE_NOT_CHANGED_PASSWD => 0x10,
	REFUSE_BLOCK_INVALID => 0x11,
	REFUSE_WARNING => 0x12,
	REFUSE_NOT_OTP_USER_INFO => 0x13,
	REFUSE_OTP_AUTH_FAILED => 0x14,
	REFUSE_SSO_AUTH_FAILED => 0x15,
	REFUSE_NOT_ALLOWED_IP_ON_TESTING => 0x16,
	REFUSE_OVER_BANDWIDTH => 0x17,
	REFUSE_OVER_USERLIMIT => 0x18,
	REFUSE_UNDER_RESTRICTION => 0x19,
	REFUSE_BY_OUTER_SERVER => 0x1a,
	REFUSE_BY_UNIQUESERVER_CONNECTION => 0x1b,
	REFUSE_BY_AUTHSERVER_CONNECTION => 0x1c,
	REFUSE_BY_BILLSERVER_CONNECTION => 0x1d,
	REFUSE_BY_AUTH_WAITING => 0x1e,
	REFUSE_DELETED_ACCOUNT => 0x63,
	REFUSE_ALREADY_CONNECT => 0x64,
	REFUSE_TEMP_BAN_HACKING_INVESTIGATION => 0x65,
	REFUSE_TEMP_BAN_BUG_INVESTIGATION => 0x66,
	REFUSE_TEMP_BAN_DELETING_CHAR => 0x67,
	REFUSE_TEMP_BAN_DELETING_SPOUSE_CHAR => 0x68,
	REFUSE_USER_PHONE_BLOCK => 0x69,
	ACCEPT_LOGIN_USER_PHONE_BLOCK => 0x6a,
	ACCEPT_LOGIN_CHILD => 0x6b,
	REFUSE_IS_NOT_FREEUSER => 0x6c,
	REFUSE_INVALID_ONETIMELIMIT => 0x6d,
	REFUSE_CHANGE_PASSWD_FORCE => 0x6e,
	REFUSE_OUTOFDATE_PASSWORD => 0x6f,
	REFUSE_NOT_CHANGE_ACCOUNTID => 0xf0,
	REFUSE_NOT_CHANGE_CHARACTERID => 0xf1,
	REFUSE_SSO_AUTH_BLOCK_USER => 0x1394,
	REFUSE_SSO_AUTH_GAME_APPLY => 0x1395,
	REFUSE_SSO_AUTH_INVALID_GAMENUM => 0x1396,
	REFUSE_SSO_AUTH_INVALID_USER => 0x1397,
	REFUSE_SSO_AUTH_OTHERS => 0x1398,
	REFUSE_SSO_AUTH_INVALID_AGE => 0x1399,
	REFUSE_SSO_AUTH_INVALID_MACADDRESS => 0x139a,
	REFUSE_SSO_AUTH_BLOCK_ETERNAL => 0x13c6,
	REFUSE_SSO_AUTH_BLOCK_ACCOUNT_STEAL => 0x13c7,
	REFUSE_SSO_AUTH_BLOCK_BUG_INVESTIGATION => 0x13c8,
	REFUSE_SSO_NOT_PAY_USER => 0x13ba,
	REFUSE_SSO_ALREADY_LOGIN_USER => 0x13bb,
	REFUSE_SSO_CURRENT_USED_USER => 0x13bc,
	REFUSE_SSO_OTHER_1 => 0x13bd,
	REFUSE_SSO_DROP_USER => 0x13be,
	REFUSE_SSO_NOTHING_USER => 0x13bf,
	REFUSE_SSO_OTHER_2 => 0x13c0,
	REFUSE_SSO_WRONG_RATETYPE_1 => 0x13c1,
	REFUSE_SSO_EXTENSION_PCBANG_TIME => 0x13c2,
	REFUSE_SSO_WRONG_RATETYPE_2 => 0x13c3,
};

use constant {
	VAR_SPEED => 0x0,
	VAR_EXP => 0x1,
	VAR_JOBEXP => 0x2,
	VAR_VIRTUE => 0x3,
	VAR_HONOR => 0x4,
	VAR_HP => 0x5,
	VAR_MAXHP => 0x6,
	VAR_SP => 0x7,
	VAR_MAXSP => 0x8,
	VAR_POINT => 0x9,
	VAR_HAIRCOLOR => 0xa,
	VAR_CLEVEL => 0xb,
	VAR_SPPOINT => 0xc,
	VAR_STR => 0xd,
	VAR_AGI => 0xe,
	VAR_VIT => 0xf,
	VAR_INT => 0x10,
	VAR_DEX => 0x11,
	VAR_LUK => 0x12,
	VAR_JOB => 0x13,
	VAR_MONEY => 0x14,
	VAR_SEX => 0x15,
	VAR_MAXEXP => 0x16,
	VAR_MAXJOBEXP => 0x17,
	VAR_WEIGHT => 0x18,
	VAR_MAXWEIGHT => 0x19,
	VAR_POISON => 0x1a,
	VAR_STONE => 0x1b,
	VAR_CURSE => 0x1c,
	VAR_FREEZING => 0x1d,
	VAR_SILENCE => 0x1e,
	VAR_CONFUSION => 0x1f,
	VAR_STANDARD_STR => 0x20,
	VAR_STANDARD_AGI => 0x21,
	VAR_STANDARD_VIT => 0x22,
	VAR_STANDARD_INT => 0x23,
	VAR_STANDARD_DEX => 0x24,
	VAR_STANDARD_LUK => 0x25,
	VAR_ATTACKMT => 0x26,
	VAR_ATTACKEDMT => 0x27,
	VAR_NV_BASIC => 0x28,
	VAR_ATTPOWER => 0x29,
	VAR_REFININGPOWER => 0x2a,
	VAR_MAX_MATTPOWER => 0x2b,
	VAR_MIN_MATTPOWER => 0x2c,
	VAR_ITEMDEFPOWER => 0x2d,
	VAR_PLUSDEFPOWER => 0x2e,
	VAR_MDEFPOWER => 0x2f,
	VAR_PLUSMDEFPOWER => 0x30,
	VAR_HITSUCCESSVALUE => 0x31,
	VAR_AVOIDSUCCESSVALUE => 0x32,
	VAR_PLUSAVOIDSUCCESSVALUE => 0x33,
	VAR_CRITICALSUCCESSVALUE => 0x34,
	VAR_ASPD => 0x35,
	VAR_PLUSASPD => 0x36,
	VAR_JOBLEVEL => 0x37,
	VAR_ACCESSORY2 => 0x38,
	VAR_ACCESSORY3 => 0x39,
	VAR_HEADPALETTE => 0x3a,
	VAR_BODYPALETTE => 0x3b,
	VAR_PKHONOR => 0x3c,
	VAR_CURXPOS => 0x3d,
	VAR_CURYPOS => 0x3e,
	VAR_CURDIR => 0x3f,
	VAR_CHARACTERID => 0x40,
	VAR_ACCOUNTID => 0x41,
	VAR_MAPID => 0x42,
	VAR_MAPNAME => 0x43,
	VAR_ACCOUNTNAME => 0x44,
	VAR_CHARACTERNAME => 0x45,
	VAR_ITEM_COUNT => 0x46,
	VAR_ITEM_ITID => 0x47,
	VAR_ITEM_SLOT1 => 0x48,
	VAR_ITEM_SLOT2 => 0x49,
	VAR_ITEM_SLOT3 => 0x4a,
	VAR_ITEM_SLOT4 => 0x4b,
	VAR_HEAD => 0x4c,
	VAR_WEAPON => 0x4d,
	VAR_ACCESSORY => 0x4e,
	VAR_STATE => 0x4f,
	VAR_MOVEREQTIME => 0x50,
	VAR_GROUPID => 0x51,
	VAR_ATTPOWERPLUSTIME => 0x52,
	VAR_ATTPOWERPLUSPERCENT => 0x53,
	VAR_DEFPOWERPLUSTIME => 0x54,
	VAR_DEFPOWERPLUSPERCENT => 0x55,
	VAR_DAMAGENOMOTIONTIME => 0x56,
	VAR_BODYSTATE => 0x57,
	VAR_HEALTHSTATE => 0x58,
	VAR_RESETHEALTHSTATE => 0x59,
	VAR_CURRENTSTATE => 0x5a,
	VAR_RESETEFFECTIVE => 0x5b,
	VAR_GETEFFECTIVE => 0x5c,
	VAR_EFFECTSTATE => 0x5d,
	VAR_SIGHTABILITYEXPIREDTIME => 0x5e,
	VAR_SIGHTRANGE => 0x5f,
	VAR_SIGHTPLUSATTPOWER => 0x60,
	VAR_STREFFECTIVETIME => 0x61,
	VAR_AGIEFFECTIVETIME => 0x62,
	VAR_VITEFFECTIVETIME => 0x63,
	VAR_INTEFFECTIVETIME => 0x64,
	VAR_DEXEFFECTIVETIME => 0x65,
	VAR_LUKEFFECTIVETIME => 0x66,
	VAR_STRAMOUNT => 0x67,
	VAR_AGIAMOUNT => 0x68,
	VAR_VITAMOUNT => 0x69,
	VAR_INTAMOUNT => 0x6a,
	VAR_DEXAMOUNT => 0x6b,
	VAR_LUKAMOUNT => 0x6c,
	VAR_MAXHPAMOUNT => 0x6d,
	VAR_MAXSPAMOUNT => 0x6e,
	VAR_MAXHPPERCENT => 0x6f,
	VAR_MAXSPPERCENT => 0x70,
	VAR_HPACCELERATION => 0x71,
	VAR_SPACCELERATION => 0x72,
	VAR_SPEEDAMOUNT => 0x73,
	VAR_SPEEDDELTA => 0x74,
	VAR_SPEEDDELTA2 => 0x75,
	VAR_PLUSATTRANGE => 0x76,
	VAR_DISCOUNTPERCENT => 0x77,
	VAR_AVOIDABLESUCCESSPERCENT => 0x78,
	VAR_STATUSDEFPOWER => 0x79,
	VAR_PLUSDEFPOWERINACOLYTE => 0x7a,
	VAR_MAGICITEMDEFPOWER => 0x7b,
	VAR_MAGICSTATUSDEFPOWER => 0x7c,
	VAR_CLASS => 0x7d,
	VAR_PLUSATTACKPOWEROFITEM => 0x7e,
	VAR_PLUSDEFPOWEROFITEM => 0x7f,
	VAR_PLUSMDEFPOWEROFITEM => 0x80,
	VAR_PLUSARROWPOWEROFITEM => 0x81,
	VAR_PLUSATTREFININGPOWEROFITEM => 0x82,
	VAR_PLUSDEFREFININGPOWEROFITEM => 0x83,
	VAR_IDENTIFYNUMBER => 0x84,
	VAR_ISDAMAGED => 0x85,
	VAR_ISIDENTIFIED => 0x86,
	VAR_REFININGLEVEL => 0x87,
	VAR_WEARSTATE => 0x88,
	VAR_ISLUCKY => 0x89,
	VAR_ATTACKPROPERTY => 0x8a,
	VAR_STORMGUSTCNT => 0x8b,
	VAR_MAGICATKPERCENT => 0x8c,
	VAR_MYMOBCOUNT => 0x8d,
	VAR_ISCARTON => 0x8e,
	VAR_GDID => 0x8f,
	VAR_NPCXSIZE => 0x90,
	VAR_NPCYSIZE => 0x91,
	VAR_RACE => 0x92,
	VAR_SCALE => 0x93,
	VAR_PROPERTY => 0x94,
	VAR_PLUSATTACKPOWEROFITEM_RHAND => 0x95,
	VAR_PLUSATTACKPOWEROFITEM_LHAND => 0x96,
	VAR_PLUSATTREFININGPOWEROFITEM_RHAND => 0x97,
	VAR_PLUSATTREFININGPOWEROFITEM_LHAND => 0x98,
	VAR_TOLERACE => 0x99,
	VAR_ARMORPROPERTY => 0x9a,
	VAR_ISMAGICIMMUNE => 0x9b,
	VAR_ISFALCON => 0x9c,
	VAR_ISRIDING => 0x9d,
	VAR_MODIFIED => 0x9e,
	VAR_FULLNESS => 0x9f,
	VAR_RELATIONSHIP => 0xa0,
	VAR_ACCESSARY => 0xa1,
	VAR_SIZETYPE => 0xa2,
	VAR_SHOES => 0xa3,
	VAR_STATUSATTACKPOWER => 0xa4,
	VAR_BASICAVOIDANCE => 0xa5,
	VAR_BASICHIT => 0xa6,
	VAR_PLUSASPDPERCENT => 0xa7,
	VAR_CPARTY => 0xa8,
	VAR_ISMARRIED => 0xa9,
	VAR_ISGUILD => 0xaa,
	VAR_ISFALCONON => 0xab,
	VAR_ISPECOON => 0xac,
	VAR_ISPARTYMASTER => 0xad,
	VAR_ISGUILDMASTER => 0xae,
	VAR_BODYSTATENORMAL => 0xaf,
	VAR_HEALTHSTATENORMAL => 0xb0,
	VAR_STUN => 0xb1,
	VAR_SLEEP => 0xb2,
	VAR_UNDEAD => 0xb3,
	VAR_BLIND => 0xb4,
	VAR_BLOODING => 0xb5,
	VAR_BSPOINT => 0xb6,
	VAR_ACPOINT => 0xb7,
	VAR_BSRANK => 0xb8,
	VAR_ACRANK => 0xb9,
	VAR_CHANGESPEED => 0xba,
	VAR_CHANGESPEEDTIME => 0xbb,
	VAR_MAGICATKPOWER => 0xbc,
	VAR_MER_KILLCOUNT => 0xbd,
	VAR_MER_FAITH => 0xbe,
	VAR_MDEFPERCENT => 0xbf,
	VAR_CRITICAL_DEF => 0xc0,
	VAR_ITEMPOWER => 0xc1,
	VAR_MAGICDAMAGEREDUCE => 0xc2,
	VAR_STATUSMAGICPOWER => 0xc3,
	VAR_PLUSMAGICPOWEROFITEM => 0xc4,
	VAR_ITEMMAGICPOWER => 0xc5,
	VAR_NAME => 0xc6,
	VAR_FSMSTATE => 0xc7,
	VAR_ATTMPOWER => 0xc8,
	VAR_CARTWEIGHT => 0xc9,
	VAR_HP_SELF => 0xca,
	VAR_SP_SELF => 0xcb,
	VAR_COSTUME_BODY => 0xcc,
	VAR_RESET_COSTUMES => 0xcd,
};

use constant {
	LEVELUP_EFFECT => 0x0,
	JOBLEVELUP_EFFECT => 0x1,
	REFINING_FAIL_EFFECT => 0x2,
	REFINING_SUCCESS_EFFECT => 0x3,
	GAME_OVER_EFFECT => 0x4,
	MAKEITEM_AM_SUCCESS_EFFECT => 0x5,
	MAKEITEM_AM_FAIL_EFFECT => 0x6,
	LEVELUP_EFFECT2 => 0x7,
	JOBLEVELUP_EFFECT2 => 0x8,
	LEVELUP_EFFECT3 => 0x9,
};

use constant {
	DEFINE__BROADCASTING_SPECIAL_ITEM_OBTAIN => 1 << 0,
	DEFINE__RENEWAL_ADD_2                    => 1 << 1,
	DEFINE__CHANNELING_SERVICE               => 1 << 2,
};

######################################
#### Packet inner struct handlers ####
######################################

# Override this function if you need to.
sub items_nonstackable {
	my ($self, $args) = @_;

	my $items = $self->{nested}->{items_nonstackable};

	if($args->{switch} eq '00A4' || # inventory
	   $args->{switch} eq '00A6' || # storage
	   $args->{switch} eq '0122'    # cart
	) {
		return $items->{type1};

	} elsif ($args->{switch} eq '0295' || # inventory
		 $args->{switch} eq '0296' || # storage
		 $args->{switch} eq '0297'    # cart
	) {
		return $items->{type2};

	} elsif ($args->{switch} eq '02D0' || # inventory
		 $args->{switch} eq '02D1' || # storage
		 $args->{switch} eq '02D2'    # cart
	) {
		return $items->{$rpackets{'00AA'} == 7 ? 'type3' : 'type4'};
	} elsif ($args->{switch} eq '0901' # inventory
		|| $args->{switch} eq '0976' # storage
		|| $args->{switch} eq '0903' # cart
	) {
		return $items->{type5};
	} else {
		warning "items_nonstackable: unsupported packet ($args->{switch})!\n";
	}
}

# Override this function if you need to.
sub items_stackable {
	my ($self, $args) = @_;

	my $items = $self->{nested}->{items_stackable};

	if($args->{switch} eq '00A3' || # inventory
	   $args->{switch} eq '00A5' || # storage
	   $args->{switch} eq '0123'    # cart
	) {
		return $items->{type1};

	} elsif ($args->{switch} eq '01EE' || # inventory
		 $args->{switch} eq '01F0' || # storage
		 $args->{switch} eq '01EF'    # cart
	) {
		return $items->{type2};

	} elsif ($args->{switch} eq '02E8' || # inventory
		 $args->{switch} eq '02EA' || # storage
		 $args->{switch} eq '02E9'    # cart
	) {
		return $items->{type3};

	} elsif ($args->{switch} eq '0900' # inventory
		|| $args->{switch} eq '0975' # storage
		|| $args->{switch} eq '0902' # cart
	) {
		return $items->{type5};

	} else {
		warning "items_stackable: unsupported packet ($args->{switch})!\n";
	}
}

sub parse_items {
	my ($self, $args, $unpack, $process) = @_;
	my @itemInfo;

	my $length = length $args->{itemInfo};
	for (my $i = 0; $i < $length; $i += $unpack->{len}) {
		my $item;
		@{$item}{@{$unpack->{keys}}} = unpack($unpack->{types}, substr($args->{itemInfo}, $i, $unpack->{len}));

		$process->($item);

		push @itemInfo, $item;
	}

	@itemInfo
}

=pod
parse_items_nonstackable

Change in packet behavior: the amount is not specified, but this is a
non-stackable item (equipment), so the amount is obviously "1".

=cut
sub parse_items_nonstackable {
	my ($self, $args) = @_;

	$self->parse_items($args, $self->items_nonstackable($args), sub {
		my ($item) = @_;

		#$item->{placeEtcTab} = $item->{identified} & (1 << 2);

		# Non stackable items now have no amount normally given in the
		# packet, so we must assume one.  We'll even play it safe, and
		# not change the amount if it's already a non-zero value.
		$item->{amount} = 1 unless ($item->{amount});
		$item->{broken} = $item->{identified} & (1 << 1) unless exists $item->{broken};
		$item->{idenfitied} = $item->{identified} & (1 << 0);
	})
}

sub parse_items_stackable {
	my ($self, $args) = @_;

	$self->parse_items($args, $self->items_stackable($args), sub {
		my ($item) = @_;

		#$item->{placeEtcTab} = $item->{identified} & (1 << 1);
		$item->{idenfitied} = $item->{identified} & (1 << 0);
	})
}

sub _items_list {
	my ($self, $args) = @_;

	for my $item (@{$args->{items}}) {
		my ($local_item, $add);

		unless ($local_item = $args->{getter} && $args->{getter}($item)) {
			$local_item = $args->{class}->new;
			$add = 1;
		}

		for ([keys %$item]) {
			@{$local_item}{@$_} = @{$item}{@$_};
		}
		$local_item->{name} = itemName($local_item);

		$args->{callback}($local_item) if $args->{callback};

		$args->{adder}($local_item) if $add;

		my $index = ($local_item->{invIndex} >= 0) ? $local_item->{invIndex} : $local_item->{index};
		debug "$args->{debug_str}: $local_item->{name} ($index) x $local_item->{amount} - $itemTypes_lut{$local_item->{type}}\n", 'parseMsg';
		Plugins::callHook($args->{hook}, {index => $index, item => $local_item});
	}
}

#######################################
###### Packet handling callbacks ######
#######################################

# from old ServerType0
sub map_loaded {
	my ($self, $args) = @_;
	$net->setState(Network::IN_GAME);
	undef $conState_tries;
	$char = $chars[$config{char}];
	return unless changeToInGameState();
	# assertClass($char, 'Actor::You');

	if ($net->version == 1) {
		$net->setState(4);
		message(T("Waiting for map to load...\n"), "connection");
		ai_clientSuspend(0, 10);
		main::initMapChangeVars();
	} else {
		$messageSender->sendSync();
		$messageSender->sendGuildMasterMemberCheck();
		# Replies 01B6 (Guild Info) and 014C (Guild Ally/Enemy List)
		$messageSender->sendGuildRequestInfo(0);
		$messageSender->sendGuildRequestInfo(0);
		# Replies 0166 (Guild Member Titles List) and 0154 (Guild Members List)
		$messageSender->sendGuildRequestInfo(1);
		message(T("You are now in the game\n"), "connection");
		Plugins::callHook('in_game');
		$messageSender->sendMapLoaded();
		$timeout{'ai'}{'time'} = time;
	}

	$char->{pos} = {};
	makeCoordsDir($char->{pos}, $args->{coords}, \$char->{look}{body});
	$char->{pos_to} = {%{$char->{pos}}};
	message(TF("Your Coordinates: %s, %s\n", $char->{pos}{x}, $char->{pos}{y}), undef, 1);

	$messageSender->sendIgnoreAll(0) if ($config{ignoreAll});
}

sub actor_look_at {
	my ($self, $args) = @_;
	return unless changeToInGameState();

	my $actor = Actor::get($args->{ID});
	$actor->{look}{head} = $args->{head};
	$actor->{look}{body} = $args->{body};
	debug $actor->nameString . " looks at $args->{body}, $args->{head}\n", "parseMsg";
}

sub actor_movement_interrupted {
	my ($self, $args) = @_;
	return unless changeToInGameState();
	my %coords;
	$coords{x} = $args->{x};
	$coords{y} = $args->{y};

	my $actor = Actor::get($args->{ID});
	$actor->{pos} = {%coords};
	$actor->{pos_to} = {%coords};
	if ($actor->isa('Actor::You') || $actor->isa('Actor::Player')) {
		$actor->{sitting} = 0;
	}
	if ($actor->isa('Actor::You')) {
		debug "Movement interrupted, your coordinates: $coords{x}, $coords{y}\n", "parseMsg_move";
		AI::clear("move");
	}
	if ($char->{homunculus} && $char->{homunculus}{ID} eq $actor->{ID}) {
		AI::clear("move");
	}
}

# TODO: translation-friendly messages
sub actor_status_active {
	my ($self, $args) = @_;

	return unless changeToInGameState();
#	my ($type, $ID, $flag, $tick) = @{$args}{qw(type ID flag tick)};
	my ($type, $ID, $flag, $tick, $unknown1, $unknown2, $unknown3) = @{$args}{qw(type ID flag tick unknown1 unknown2 unknown3)};
	my $status = defined $statusHandle{$type} ? $statusHandle{$type} : "UNKNOWN_STATUS_$type";
	$cart{type} = $unknown1 if ($type == 673 && defined $unknown1 && ($ID eq $accountID)); # for Cart active
	$args->{skillName} = defined $statusName{$status} ? $statusName{$status} : $status;
	($args->{actor} = Actor::get($ID))->setStatus($status, $flag, $tick == 9999 ? undef : $tick, $args->{unknown1});
	# Maple 回旋十字斩
}

sub actor_trapped {
	my ($self, $args) = @_;
	# original comment was that ID is not a valid ID
	# but it seems to be, at least on eAthena/Freya
	my $actor = Actor::get($args->{ID});
	debug "$actor->nameString() is trapped.\n";
}

sub area_spell {
	my ($self, $args) = @_;

	# Area effect spell; including traps!
	my $ID = $args->{ID};
	my $sourceID = $args->{sourceID};
	my $x = $args->{x};
	my $y = $args->{y};
	my $type = $args->{type};
	my $fail = $args->{fail};
	my $binID;
	if ($spells{$ID} && $spells{$ID}{'sourceID'} eq $sourceID) {
		$binID = binFind(\@spellsID, $ID);
		$binID = binAdd(\@spellsID, $ID) if ($binID eq "");
	} else {
		$binID = binAdd(\@spellsID, $ID);
	}

	$spells{$ID}{'sourceID'} = $sourceID;
	$spells{$ID}{'pos'}{'x'} = $x;
	$spells{$ID}{'pos'}{'y'} = $y;
	$spells{$ID}{'pos_to'}{'x'} = $x;
	$spells{$ID}{'pos_to'}{'y'} = $y;
	#my $binID = binAdd(\@spellsID, $ID);
	$spells{$ID}{'binID'} = $binID;
	$spells{$ID}{'type'} = $type;
	if ($type == 0x81) {
		message TF("%s opened Warp Portal on (%d, %d)\n", getActorName($sourceID), $x, $y), "skill";
	}
	debug "Area effect ".getSpellName($type)." ($binID) from ".getActorName($sourceID)." appeared on ($x, $y)\n", "skill", 2;

	if ($args->{switch} eq "01C9") {
		message TF("%s has scribbled: %s on (%d, %d)\n", getActorName($sourceID), $args->{scribbleMsg}, $x, $y);
	}

	Plugins::callHook('packet_areaSpell', {
		fail => $fail,
		sourceID => $sourceID,
		type => $type,
		x => $x,
		y => $y
	});
}

sub area_spell_disappears {
	my ($self, $args) = @_;

	# The area effect spell with ID dissappears
	my $ID = $args->{ID};
	my $spell = $spells{$ID};
	debug "Area effect ".getSpellName($spell->{type})." ($spell->{binID}) from ".getActorName($spell->{sourceID})." disappeared from ($spell->{pos}{x}, $spell->{pos}{y})\n", "skill", 2;
	delete $spells{$ID};
	binRemove(\@spellsID, $ID);
}

sub arrow_none {
	my ($self, $args) = @_;

	my $type = $args->{type};
	if ($type == 0) {
		delete $char->{'arrow'};
		if ($config{'dcOnEmptyArrow'}) {
			$interface->errorDialog(T("Please equip arrow first."));
			quit();
		} else {
			error T("Please equip arrow first.\n");
		}
	} elsif ($type == 1) {
		debug "You can't Attack or use Skills because your Weight Limit has been exceeded.\n";
	} elsif ($type == 2) {
		debug "You can't use Skills because Weight Limit has been exceeded.\n";
	} elsif ($type == 3) {
		debug "Arrow equipped\n";
	}
}

# Maple start 阅读魔法书
sub arrowcraft_list {
	my ($self, $args) = @_;

	my $newmsg;
	my $msg = $args->{RAW_MSG};
	my $msg_size = $args->{RAW_MSG_SIZE};
	$self->decrypt(\$newmsg, substr($msg, 4));
	$msg = substr($msg, 0, 4).$newmsg;
	my $ID;
	my $item;
	my $relID = 0;
	my $relName;

	undef @arrowCraftID;
	for (my $i = 4; $i < $msg_size; $i += 2) {
		$ID = unpack("v1", substr($msg, $i, 2));
		if (int($ID) == int($config{skillAutoRelease}) && $char->{skills}{WL_RELEASE}{lv} >= 1) {
			$relID = int($ID);
			$relName = $char->inventory->getByNameID($relID);
		}
		$item = $char->inventory->getByNameID($ID);
		#message "ID: ".$ID." item:" .$item." relID:" .$relID."\n";
		binAdd(\@arrowCraftID, $item->{invIndex});
	}

	if ($relID > 0 && $config{skillAutoRelease} && $char->{skills}{WL_RELEASE}{lv} >= 1) {
		Commands::cmdArrowCraft();
		my $rsb = pack("C*", 0xAE, 0x01) . pack("v*", $relID);
		$messageSender->sendToServer($rsb);
		message TF("您 已经阅读魔法书: $relName\n"), "success";
	} else {
	Commands::cmdArrowCraft();
	}
}
# Maple end

sub attack_range {
	my ($self, $args) = @_;

	my $type = $args->{type};
	debug "Your attack range is: $type\n";
	return unless changeToInGameState();

	$char->{attack_range} = $type;
	if ($config{attackDistanceAuto} && $config{attackDistance} != $type) {
		message TF("Autodetected attackDistance = %s\n", $type), "success";
		configModify('attackDistance', $type, 1);
		configModify('attackMaxDistance', $type, 1);
	}
}

sub buy_result {
	my ($self, $args) = @_;
	if ($args->{fail} == 0) {
		message T("Buy completed.\n"), "success";
	} elsif ($args->{fail} == 1) {
		error T("Buy failed (insufficient zeny).\n");
	} elsif ($args->{fail} == 2) {
		error T("Buy failed (insufficient weight capacity).\n");
	} elsif ($args->{fail} == 3) {
		error T("Buy failed (too many different inventory items).\n");
	} elsif ($args->{fail} == 4) {
		error T("Buy failed (item does not exist in store).\n");
	} elsif ($args->{fail} == 5) {
		error T("Buy failed (item cannot be exchanged).\n");
	} elsif ($args->{fail} == 6) {
		error T("Buy failed (invalid store).\n");
	} else {
		error TF("Buy failed (failure code %s).\n", $args->{fail});
	}
}

sub card_merge_list {
	my ($self, $args) = @_;

	# You just requested a list of possible items to merge a card into
	# The RO client does this when you double click a card
	my $newmsg;
	my $msg = $args->{RAW_MSG};
	$self->decrypt(\$newmsg, substr($msg, 4));
	$msg = substr($msg, 0, 4).$newmsg;
	my ($len) = unpack("x2 v1", $msg);

	my $display;
	$display .= T("-----Card Merge Candidates-----\n");

	my $index;
	for (my $i = 4; $i < $len; $i += 2) {
		$index = unpack("v1", substr($msg, $i, 2));
		my $item = $char->inventory->getByServerIndex($index);
		binAdd(\@cardMergeItemsID, $item->{invIndex});
		$display .= "$item->{invIndex} $item->{name}\n";
	}

	$display .= "-------------------------------\n";
	message $display, "list";
}

sub card_merge_status {
	my ($self, $args) = @_;

	# something about successful compound?
	my $item_index = $args->{item_index};
	my $card_index = $args->{card_index};
	my $fail = $args->{fail};

	if ($fail) {
		message T("Card merging failed\n");
	} else {
		my $item = $char->inventory->getByServerIndex($item_index);
		my $card = $char->inventory->getByServerIndex($card_index);
		message TF("%s has been successfully merged into %s\n",
			$card->{name}, $item->{name}), "success";

		# Remove one of the card
		$card->{amount} -= 1;
		if ($card->{amount} <= 0) {
			$char->inventory->remove($card);
		}

		# Rename the slotted item now
		# FIXME: this is unoptimized
		use bytes;
		no encoding 'utf8';
		my $newcards = '';
		my $addedcard;
		for (my $i = 0; $i < 4; $i++) {
			my $cardData = substr($item->{cards}, $i * 2, 2);
			if (unpack("v", $cardData)) {
				$newcards .= $cardData;
			} elsif (!$addedcard) {
				$newcards .= pack("v", $card->{nameID});
				$addedcard = 1;
			} else {
				$newcards .= pack("v", 0);
			}
		}
		$item->{cards} = $newcards;
		$item->setName(itemName($item));
	}

	undef @cardMergeItemsID;
	undef $cardMergeIndex;
}

use encoding 'utf8';
# 修复乱码问题

sub cart_info {
	my ($self, $args) = @_;

	$cart{items} = $args->{items};
	$cart{items_max} = $args->{items_max};
	$cart{weight} = int($args->{weight} / 10);
	$cart{weight_max} = int($args->{weight_max} / 10);
	$cart{exists} = 1;
	debug "[cart_info] received.\n", "parseMsg";
}

sub cart_add_failed {
	my ($self, $args) = @_;

	my $reason;
	if ($args->{fail} == 0) {
		$reason = T('overweight');
	} elsif ($args->{fail} == 1) {
		$reason = T('too many items');
	} else {
		$reason = TF("Unknown code %s",$args->{fail});
	}
	error TF("Can't Add Cart Item (%s)\n", $reason);
}

sub cart_items_nonstackable {
	my ($self, $args) = @_;

	$self->_items_list({
		# TODO: different classes for inventory/cart/storage items
		class => 'Actor::Item',
		hook => 'packet_cart',
		debug_str => 'Non-Stackable Cart Item',
		items => [$self->parse_items_nonstackable($args)],
		getter => sub { $cart{inventory}[$_[0]{index}] },
		adder => sub { $cart{inventory}[$_[0]{index}] = $_[0] },
	});

	$ai_v{'inventory_time'} = time + 1;
	$ai_v{'cart_time'} = time + 1;
}

sub cart_items_stackable {
	my ($self, $args) = @_;

	$self->_items_list({
		class => 'Actor::Item',
		hook => 'packet_cart',
		debug_str => 'Stackable Cart Item',
		items => [$self->parse_items_stackable($args)],
		getter => sub { $cart{inventory}[$_[0]{index}] },
		adder => sub { $cart{inventory}[$_[0]{index}] = $_[0] },
	});

	$ai_v{'inventory_time'} = time + 1;
	$ai_v{'cart_time'} = time + 1;
}

sub cart_item_added {
	my ($self, $args) = @_;

	my $item = $cart{inventory}[$args->{index}] ||= Actor::Item->new;
	if ($item->{amount}) {
		$item->{amount} += $args->{amount};
	} else {
		$item->{index} = $args->{index};
		$item->{nameID} = $args->{nameID};
		$item->{amount} = $args->{amount};
		$item->{identified} = $args->{identified};
		$item->{broken} = $args->{broken};
		$item->{upgrade} = $args->{upgrade};
		$item->{cards} = $args->{cards};
		$item->{type} = $args->{type} if (exists $args->{type});
		$item->{name} = itemName($item);
	}
	message TF("Cart Item Added: %s (%d) x %s\n", $item->{name}, $args->{index}, $args->{amount});
	$itemChange{$item->{name}} += $args->{amount};
	$args->{item} = $item;
}

sub cash_dealer {
	my ($self, $args) = @_;

	undef @cashList;
	my $cashList = 0;
	$char->{cashpoint} = unpack("x4 V", $args->{RAW_MSG});

	for (my $i = 8; $i < $args->{RAW_MSG_SIZE}; $i += 11) {
		my ($price, $dcprice, $type, $ID) = unpack("V2 C v", substr($args->{RAW_MSG}, $i, 11));
		my $store = $cashList[$cashList] = {};
		# TODO: use itemName() or itemNameSimple()?
		my $display = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown $ID";
		$store->{name} = $display;
		$store->{nameID} = $ID;
		$store->{type} = $type;
		$store->{price} = $dcprice;
		$cashList++;
	}

	$ai_v{npc_talk}{talk} = 'cash';
	# continue talk sequence now
	$ai_v{npc_talk}{time} = time;

	message TF("------------CashList (Cash Point: %-5d)-------------\n" .
		"#    Name                    Type               Price\n", $char->{cashpoint}), "list";
	my $display;
	for (my $i = 0; $i < @cashList; $i++) {
		$display = $cashList[$i]{name};
		message(swrite(
			"@<<< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<< @>>>>>>>p",
			[$i, $display, $itemTypes_lut{$cashList[$i]{type}}, $cashList[$i]{price}]),
			"list");
	}
	message("-----------------------------------------------------\n", "list");
}

sub combo_delay {
	my ($self, $args) = @_;

	$char->{combo_packet} = ($args->{delay}); #* 15) / 100000;
	# How was the above formula derived? I think it's better that the manipulation be
	# done in functions.pl (or whatever sub that handles this) instead of here.

	$args->{actor} = Actor::get($args->{ID});
	my $verb = $args->{actor}->verb('have', 'has');
	debug "$args->{actor} $verb combo delay $args->{delay}\n", "parseMsg_comboDelay";
}

sub cart_item_removed {
	my ($self, $args) = @_;

	my ($index, $amount) = @{$args}{qw(index amount)};

	my $item = $cart{inventory}[$index];
	$item->{amount} -= $amount;
	message TF("Cart Item Removed: %s (%d) x %s\n", $item->{name}, $index, $amount);
	$itemChange{$item->{name}} -= $amount;
	if ($item->{amount} <= 0) {
		$cart{'inventory'}[$index] = undef;
	}
	$args->{item} = $item;
}

sub change_to_constate25 {
	$net->setState(2.5);
	undef $accountID;
}

sub changeToInGameState {
	Network::Receive::changeToInGameState;
}

sub character_creation_failed {
	my ($self, $args) = @_;
	if ($args->{flag} == 0x0) {
		message T("Charname already exists.\n"), "info";
	} elsif ($args->{flag} == 0xFF) {
		message T("Char creation denied.\n"), "info";
	} elsif ($args->{flag} == 0x01) {
		message T("You are underaged.\n"), "info";
	} else {
		message T("Character creation failed. " .
			"If you didn't make any mistake, then the name you chose already exists.\n"), "info";
	}
	if (charSelectScreen() == 1) {
		$net->setState(3);
		$firstLoginMap = 1;
		$startingzeny = $chars[$config{'char'}]{'zeny'} unless defined $startingzeny;
		$sentWelcomeMessage = 1;
	}
}

sub character_creation_successful {
	my ($self, $args) = @_;
	my $char = new Actor::You;
	foreach (@{$self->{packet_list}{$args->{switch}}->[2]}) {
		$char->{$_} = $args->{$_} if (exists $args->{$_});
	}
	$char->{name} = bytesToString($args->{name});
	$char->{jobID} = 0;
	$char->{headgear}{low} = 0;
	$char->{headgear}{top} = 0;
	$char->{headgear}{mid} = 0;
	$char->{nameID} = unpack("V", $accountID); 
	#$char->{lv} = 1;
	#$char->{lv_job} = 1;
	$char->{sex} = $accountSex2;
	$chars[$char->{slot}] = $char;



	$net->setState(3);
	message TF("Character %s (%d) created.\n", $char->{name}, $char->{slot}), "info";
	if (charSelectScreen() == 1) {
		$firstLoginMap = 1;
		$startingzeny = $chars[$config{'char'}]{'zeny'} unless defined $startingzeny;
		$sentWelcomeMessage = 1;
	}
}

sub character_deletion_successful {
	if (defined $AI::temp::delIndex) {
		message TF("Character %s (%d) deleted.\n", $chars[$AI::temp::delIndex]{name}, $AI::temp::delIndex), "info";
		delete $chars[$AI::temp::delIndex];
		undef $AI::temp::delIndex;
		for (my $i = 0; $i < @chars; $i++) {
			delete $chars[$i] if ($chars[$i] && !scalar(keys %{$chars[$i]}))
		}
	} else {
		message T("Character deleted.\n"), "info";
	}

	if (charSelectScreen() == 1) {
		$net->setState(3);
		$firstLoginMap = 1;
		$startingzeny = $chars[$config{'char'}]{'zeny'} unless defined $startingzeny;
		$sentWelcomeMessage = 1;
	}
}

sub character_deletion_failed {
	error T("Character cannot be deleted. Your e-mail address was probably wrong.\n");
	undef $AI::temp::delIndex;
	if (charSelectScreen() == 1) {
		$net->setState(3);
		$firstLoginMap = 1;
		$startingzeny = $chars[$config{'char'}]{'zeny'} unless defined $startingzeny;
		$sentWelcomeMessage = 1;
	}
}

sub character_moves {
	my ($self, $args) = @_;

	return unless changeToInGameState();
	makeCoordsFromTo($char->{pos}, $char->{pos_to}, $args->{coords});
	my $dist = sprintf("%.1f", distance($char->{pos}, $char->{pos_to}));
	debug "You're moving from ($char->{pos}{x}, $char->{pos}{y}) to ($char->{pos_to}{x}, $char->{pos_to}{y}) - distance $dist\n", "parseMsg_move";
	$char->{time_move} = time;
	$char->{time_move_calc} = distance($char->{pos}, $char->{pos_to}) * ($char->{walk_speed} || 0.12);

	# Correct the direction in which we're looking
	my (%vec, $degree);
	getVector(\%vec, $char->{pos_to}, $char->{pos});
	$degree = vectorToDegree(\%vec);
	if (defined $degree) {
		my $direction = int sprintf("%.0f", (360 - $degree) / 45);
		$char->{look}{body} = $direction & 0x07;
		$char->{look}{head} = 0;
	}

	# Ugly; AI code in network subsystem! This must be fixed.
	if (AI::action eq "mapRoute" && $config{route_escape_reachedNoPortal} && $dist eq "0.0"){
	   if (!$portalsID[0]) {
		if ($config{route_escape_shout} ne "" && !defined($timeout{ai_route_escape}{time})){
			sendMessage("c", $config{route_escape_shout});
		}
 	   	 $timeout{ai_route_escape}{time} = time;
	   	 AI::queue("escape");
	   }
	}
}

sub character_name {
	my ($self, $args) = @_;
	my $name; # Type: String

	$name = bytesToString($args->{name});
	debug "Character name received: $name\n";
}

sub character_status {
	my ($self, $args) = @_;

	my $actor = Actor::get($args->{ID});

	if ($args->{switch} eq '028A') {
		$actor->{lv} = $args->{lv}; # TODO: test if it is ok to use this piece of information
		$actor->{opt3} = $args->{opt3};
	} elsif ($args->{switch} eq '0229' || $args->{switch} eq '0119') {
		$actor->{opt1} = $args->{opt1};
		$actor->{opt2} = $args->{opt2};
	}

	$actor->{option} = $args->{option};

	setStatus($actor, $args->{opt1}, $args->{opt2}, $args->{option});
}

sub cast_cancelled {
	my ($self, $args) = @_;

	# Cast is cancelled
	my $ID = $args->{ID};

	my $source = Actor::get($ID);
	$source->{cast_cancelled} = time;
	my $skill = $source->{casting}->{skill};
	my $skillName = $skill ? $skill->getName() : T('Unknown');
	my $domain = ($ID eq $accountID) ? "selfSkill" : "skill";
	message sprintf($source->verb(T("%s failed to cast %s\n"), T("%s failed to cast %s\n")), $source, $skillName), $domain;
	Plugins::callHook('packet_castCancelled', {
		sourceID => $ID
	});
	delete $source->{casting};
}

sub deal_add_other {
	my ($self, $args) = @_;

	if ($args->{nameID} > 0) {
		my $item = $currentDeal{other}{ $args->{nameID} } ||= {};
		$item->{amount} += $args->{amount};
		$item->{nameID} = $args->{nameID};
		$item->{identified} = $args->{identified};
		$item->{broken} = $args->{broken};
		$item->{upgrade} = $args->{upgrade};
		$item->{cards} = $args->{cards};
		$item->{name} = itemName($item);
		message TF("%s added Item to Deal: %s x %s\n", $currentDeal{name}, $item->{name}, $args->{amount}), "deal";
	} elsif ($args->{amount} > 0) {
		$currentDeal{other_zeny} += $args->{amount};
		my $amount = formatNumber($args->{amount});
		message TF("%s added %s z to Deal\n", $currentDeal{name}, $amount), "deal";
	}
}

sub deal_add_you {
	my ($self, $args) = @_;

	if ($args->{fail} == 1) {
		error T("That person is overweight; you cannot trade.\n"), "deal";
		return;
	} elsif ($args->{fail} == 2) {
		error T("This item cannot be traded.\n"), "deal";
		return;
	} elsif ($args->{fail}) {
		error TF("You cannot trade (fail code %s).\n", $args->{fail}), "deal";
		return;
	}

	return unless $args->{index} > 0;

	my $item = $char->inventory->getByServerIndex($args->{index});
	# FIXME: quickly add two items => lastItemAmount is lost => inventory corruption; see also Misc::dealAddItem
	# FIXME: what will be in case of two items with the same nameID?
	# TODO: no info about items is stored
	$currentDeal{you}{$item->{nameID}}{amount} += $currentDeal{lastItemAmount};
	$currentDeal{you}{$item->{nameID}}{nameID} = $item->{nameID};
	$item->{amount} -= $currentDeal{lastItemAmount};
	message TF("You added Item to Deal: %s x %s\n", $item->{name}, $currentDeal{lastItemAmount}), "deal";
	$itemChange{$item->{name}} -= $currentDeal{lastItemAmount};
	$currentDeal{you_items}++;
	$args->{item} = $item;
	$char->inventory->remove($item) if ($item->{amount} <= 0);
}

sub deal_begin {
	my ($self, $args) = @_;

	if ($args->{type} == 0) {
		error T("That person is too far from you to trade.\n"), "deal";
	} elsif ($args->{type} == 2) {
		error T("That person is in another deal.\n"), "deal";
	} elsif ($args->{type} == 3) {
		if (%incomingDeal) {
			$currentDeal{name} = $incomingDeal{name};
			undef %incomingDeal;
		} else {
			my $ID = $outgoingDeal{ID};
			my $player;
			$player = $playersList->getByID($ID) if (defined $ID);
			$currentDeal{ID} = $ID;
			if ($player) {
				$currentDeal{name} = $player->{name};
			} else {
				$currentDeal{name} = T('Unknown #') . unpack("V", $ID);
			}
			undef %outgoingDeal;
		}
		message TF("Engaged Deal with %s\n", $currentDeal{name}), "deal";
	} elsif ($args->{type} == 5) {
		error T("That person is opening storage.\n"), "deal";
	} else {
		error TF("Deal request failed (unknown error %s).\n", $args->{type}), "deal";
	}
}

sub deal_cancelled {
	undef %incomingDeal;
	undef %outgoingDeal;
	undef %currentDeal;
	message T("Deal Cancelled\n"), "deal";
}

sub deal_complete {
	undef %outgoingDeal;
	undef %incomingDeal;
	undef %currentDeal;
	message T("Deal Complete\n"), "deal";
}

sub deal_finalize {
	my ($self, $args) = @_;
	if ($args->{type} == 1) {
		$currentDeal{other_finalize} = 1;
		message TF("%s finalized the Deal\n", $currentDeal{name}), "deal";

	} else {
		$currentDeal{you_finalize} = 1;
		# FIXME: shouldn't we do this when we actually complete the deal?
		$char->{zeny} -= $currentDeal{you_zeny};
		message T("You finalized the Deal\n"), "deal";
	}
}

sub deal_request {
	my ($self, $args) = @_;
	my $level = $args->{level} || 'Unknown'; # TODO: store this info
	my $user = bytesToString($args->{user});

	$incomingDeal{name} = $user;
	$timeout{ai_dealAutoCancel}{time} = time;
	message TF("%s (level %s) Requests a Deal\n", $user, $level), "deal";
	message T("Type 'deal' to start dealing, or 'deal no' to deny the deal.\n"), "deal";
}

sub devotion {
	my ($self, $args) = @_;
	my $msg = '';
	my $source = Actor::get($args->{sourceID});

	undef $devotionList->{$args->{sourceID}};
	for (my $i = 0; $i < 5; $i++) {
		my $ID = substr($args->{targetIDs}, $i*4, 4);
		last if unpack("V", $ID) == 0;
		$devotionList->{$args->{sourceID}}->{targetIDs}->{$ID} = $i;
		my $actor = Actor::get($ID);
		$msg .= skillUseNoDamage_string($source, $actor, 0, 'devotion');
	}
	$devotionList->{$args->{sourceID}}->{range} = $args->{range};

	message TF("$msg"), "devotion";
}

sub egg_list {
	my ($self, $args) = @_;
	message T("----- Egg Hatch Candidates -----\n"), "list";
	for (my $i = 4; $i < $args->{RAW_MSG_SIZE}; $i += 2) {
		my $index = unpack("v1", substr($args->{RAW_MSG}, $i, 2));
		my $item = $char->inventory->getByServerIndex($index);
		message "$item->{invIndex} $item->{name}\n", "list";
	}
	message "------------------------------\n", "list";
}

sub emoticon {
	my ($self, $args) = @_;
	my $emotion = $emotions_lut{$args->{type}}{display} || "<emotion #$args->{type}>";

	if ($args->{ID} eq $accountID) {
		message "$char->{name}: $emotion\n", "emotion";
		chatLog("e", "$char->{name}: $emotion\n") if (existsInList($config{'logEmoticons'}, $args->{type}) || $config{'logEmoticons'} eq "all");

	} elsif (my $player = $playersList->getByID($args->{ID})) {
		my $name = $player->name;

		#my $dist = "unknown";
		my $dist = distance($char->{pos_to}, $player->{pos_to});
		$dist = sprintf("%.1f", $dist) if ($dist =~ /\./);

		# Translation Comment: "[dist=$dist] $name ($player->{binID}): $emotion\n"
		message TF("[dist=%s] %s (%d): %s\n", $dist, $name, $player->{binID}, $emotion), "emotion";
		chatLog("e", "$name".": $emotion\n") if (existsInList($config{'logEmoticons'}, $args->{type}) || $config{'logEmoticons'} eq "all");

		my $index = AI::findAction("follow");
		if ($index ne "") {
			my $masterID = AI::args($index)->{ID};
			if ($config{'followEmotion'} && $masterID eq $args->{ID} &&
			       distance($char->{pos_to}, $player->{pos_to}) <= $config{'followEmotion_distance'})
			{
				my %args = ();
				$args{timeout} = time + rand (1) + 0.75;

				if ($args->{type} == 30) {
					$args{emotion} = 31;
				} elsif ($args->{type} == 31) {
					$args{emotion} = 30;
				} else {
					$args{emotion} = $args->{type};
				}

				AI::queue("sendEmotion", \%args);
			}
		}
	} elsif (my $monster = $monstersList->getByID($args->{ID}) || $slavesList->getByID($args->{ID})) {
		my $dist = distance($char->{pos_to}, $monster->{pos_to});
		$dist = sprintf("%.1f", $dist) if ($dist =~ /\./);

		# Translation Comment: "[dist=$dist] $monster->name ($monster->{binID}): $emotion\n"
		message TF("[dist=%s] %s %s (%d): %s\n", $dist, $monster->{actorType}, $monster->name, $monster->{binID}, $emotion), "emotion";

	} else {
		my $actor = Actor::get($args->{ID});
		my $name = $actor->name;

		my $dist = T("unknown");
		if (!$actor->isa('Actor::Unknown')) {
			$dist = distance($char->{pos_to}, $actor->{pos_to});
			$dist = sprintf("%.1f", $dist) if ($dist =~ /\./);
		}

		message TF("[dist=%s] %s: %s\n", $dist, $actor->nameIdx, $emotion), "emotion";
		chatLog("e", "$name".": $emotion\n") if (existsInList($config{'logEmoticons'}, $args->{type}) || $config{'logEmoticons'} eq "all");
	}
	Plugins::callHook('packet_emotion', {
		emotion => $emotion,
		ID => $args->{ID}
	});
}

sub equip_item {
	my ($self, $args) = @_;
	my $item = $char->inventory->getByServerIndex($args->{index});
	if (!$args->{success}) {
		message TF("You can't put on %s (%d)\n", $item->{name}, $item->{invIndex});
	} else {
		$item->{equipped} = $args->{type};
		if ($args->{type} == 10 || $args->{type} == 32768) {
			$char->{equipment}{arrow} = $item;
		} else {
			foreach (%equipSlot_rlut){
				if ($_ & $args->{type}){
					next if $_ == 10; # work around Arrow bug
					next if $_ == 32768;
					$char->{equipment}{$equipSlot_lut{$_}} = $item;
				}
			}
		}
		message TF("You equip %s (%d) - %s (type %s)\n", $item->{name}, $item->{invIndex},
			$equipTypes_lut{$item->{type_equip}}, $args->{type}), 'inventory';
	}
	$ai_v{temp}{waitForEquip}-- if $ai_v{temp}{waitForEquip};
}

sub errors {
	my ($self, $args) = @_;

	Plugins::callHook('disconnected') if ($net->getState() == Network::IN_GAME);
	if ($net->getState() == Network::IN_GAME &&
		($config{dcOnDisconnect} > 1 ||
		($config{dcOnDisconnect} &&
		$args->{type} != 3 &&
		$args->{type} != 10))) {
		message T("Lost connection; exiting\n");
		$quit = 1;
	}

	$net->setState(1);
	undef $conState_tries;

	$timeout_ex{'master'}{'time'} = time;
	$timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
	if (($args->{type} != 0)) {
		$net->serverDisconnect();
	}
	if ($args->{type} == 0) {
		# FIXME BAN_SERVER_SHUTDOWN is 0x1, 0x0 is BAN_UNFAIR
		error T("Server shutting down\n"), "connection";
		if($config{'dcOnServerShutDown'} == 1) {
			$quit = 1;
		}
	} elsif ($args->{type} == 1) {
		error T("Error: Server is closed\n"), "connection";
		if($config{'dcOnServerClose'} == 1) {
			$quit = 1;
		}
	} elsif ($args->{type} == 2) {
		if ($config{'dcOnDualLogin'} == 1) {
			$interface->errorDialog(TF("Critical Error: Dual login prohibited - Someone trying to login!\n\n" .
				"%s will now immediately 	disconnect.", $Settings::NAME));
			$quit = 1;
		} elsif ($config{'dcOnDualLogin'} >= 2) {
			error T("Critical Error: Dual login prohibited - Someone trying to login!\n"), "connection";
			message TF("Disconnect for %s seconds...\n", $config{'dcOnDualLogin'}), "connection";
			$timeout_ex{'master'}{'timeout'} = $config{'dcOnDualLogin'};
		} else {
			error T("Critical Error: Dual login prohibited - Someone trying to login!\n"), "connection";
		}

	} elsif ($args->{type} == 3) {
		error T("Error: Out of sync with server\n"), "connection";
	} elsif ($args->{type} == 4) {
		# fRO: "Your account is not validated, please click on the validation link in your registration mail."
		error T("Error: Server is jammed due to over-population.\n"), "connection";
	} elsif ($args->{type} == 5) {
		error T("Error: You are underaged and cannot join this server.\n"), "connection";
	} elsif ($args->{type} == 6) {
		error T("错误: 你服务器蛋疼错误!\n"), "connection";
	} elsif ($args->{type} == 8) {
		error T("Error: The server still recognizes your last connection\n"), "connection";
	} elsif ($args->{type} == 9) {
		error T("Error: IP capacity of this Internet Cafe is full. Would you like to pay the personal base?\n"), "connection";
	} elsif ($args->{type} == 10) {
		error T("Error: You are out of available time paid for\n"), "connection";
	} elsif ($args->{type} == 15) {
		error T("Error: You have been forced to disconnect by a GM\n"), "connection";
	} elsif ($args->{type} == 101) {
		error T("Error: Your account has been suspended until the next maintenance period for possible use of 3rd party programs\n"), "connection";
	} elsif ($args->{type} == 102) {
		error T("Error: For an hour, more than 10 connections having same IP address, have made. Please check this matter.\n"), "connection";
	} elsif ($args->{type} == 114) {
		error T("错误: 认证服务器无应答.\n"), "connection";
	} else {
		error TF("Unknown error %s\n", $args->{type}), "connection";
	}
}

sub forge_list {
	my ($self, $args) = @_;

	message T("========Forge List========\n");
	for (my $i = 4; $i < $args->{RAW_MSG_SIZE}; $i += 8) {
		my $viewID = unpack("v1", substr($args->{RAW_MSG}, $i, 2));
		message "$viewID $items_lut{$viewID}\n";
		# always 0x0012
		#my $unknown = unpack("v1", substr($args->{RAW_MSG}, $i+2, 2));
		# ???
		#my $charID = substr($args->{RAW_MSG}, $i+4, 4);
	}
	message "=========================\n";
}

sub friend_request {
	my ($self, $args) = @_;

	my $Friendname = bytesToString($args->{name});
	message TF("自动拒绝 %s 成为朋友\n", $Friendname);

	if (timeOut($timeout{'ai_friendAutoDeny'})) {
	$messageSender->sendFriendListReply($args->{accountID}, $args->{charID}, 0);
	$timeout{'ai_friendAutoDeny'}{'time'} = time;
	}
}

sub homunculus_food {
	my ($self, $args) = @_;
	if ($args->{success}) {
		message TF("Fed homunculus with %s\n", itemNameSimple($args->{foodID})), "homunculus";
	} else {
		error TF("Failed to feed homunculus with %s: no food in inventory.\n", itemNameSimple($args->{foodID})), "homunculus";
		# auto-vaporize
		if ($char->{homunculus} && $char->{homunculus}{hunger} <= 11 && timeOut($char->{homunculus}{vaporize_time}, 5)) {
			$messageSender->sendSkillUse(244, 1, $accountID);
			$char->{homunculus}{vaporize_time} = time;
			error "Critical hunger level reached. Homunculus is put to rest.\n", "homunculus";
		}
	}
}

use constant {
	HO_PRE_INIT => 0x0,
	HO_RELATIONSHIP_CHANGED => 0x1,
	HO_FULLNESS_CHANGED => 0x2,
	HO_ACCESSORY_CHANGED => 0x3,
	HO_HEADTYPE_CHANGED => 0x4,
};

# 0230
# TODO: what is type?
sub homunculus_info {
	my ($self, $args) = @_;
	debug "homunculus_info type: $args->{type}\n";
	if ($args->{state} == HO_PRE_INIT) {
		my $state = $char->{homunculus}{state}
			if ($char->{homunculus} && $char->{homunculus}{ID} && $char->{homunculus}{ID} ne $args->{ID});
		$char->{homunculus} = Actor::get($args->{ID}) if (!$char->{homunculus} || $slavesList->getByID($args->{ID}));
		# 尝试修复瞬移导致生命体属性null情况 Maple
		$char->{homunculus}{state} = $state if (defined $state);
		$char->{homunculus}{map} = $field->baseName;
		unless ($char->{slaves}{$char->{homunculus}{ID}}) {
			AI::SlaveManager::addSlave ($char->{homunculus});
		}
	} elsif ($args->{state} == HO_RELATIONSHIP_CHANGED) {
		$char->{homunculus}{intimacy} = $args->{val} if $char->{homunculus};
	} elsif ($args->{state} == HO_FULLNESS_CHANGED) {
		$char->{homunculus}{hunger} = $args->{val} if $char->{homunculus};
	} elsif ($args->{state} == HO_ACCESSORY_CHANGED) {
		$char->{homunculus}{accessory} = $args->{val} if $char->{homunculus};
	} elsif ($args->{state} == HO_HEADTYPE_CHANGED) {
		#
	}
}

# 029B
sub mercenary_init {
	my ($self, $args) = @_;

	$char->{mercenary} = Actor::get ($args->{ID}); # TODO: was it added to an actorList yet?
	$char->{mercenary}{map} = $field->baseName;
	unless ($char->{slaves}{$char->{mercenary}{ID}}) {
		AI::SlaveManager::addSlave ($char->{mercenary});
	}

	my $slave = $char->{mercenary};

	foreach (@{$args->{KEYS}}) {
		$slave->{$_} = $args->{$_};
	}
	$slave->{name} = bytesToString($args->{name});

	slave_calcproperty_handler($slave, $args);

	# ST0's counterpart for ST kRO, since it attempts to support all servers
	# TODO: we do this for homunculus, mercenary and our char... make 1 function and pass actor and attack_range?
	if ($config{mercenary_attackDistanceAuto} && $config{attackDistance} != $slave->{attack_range} && exists $slave->{attack_range}) {
		message TF("Autodetected attackDistance for mercenary = %s\n", $slave->{attack_range}), "success";
		configModify('mercenary_attackDistance', $slave->{attack_range}, 1);
		configModify('mercenary_attackMaxDistance', $slave->{attack_range}, 1);
	}
}

# 022E
sub homunculus_property {
	my ($self, $args) = @_;

	my $slave = $char->{homunculus} or return;

	foreach (@{$args->{KEYS}}) {
		$slave->{$_} = $args->{$_};
	}
	$slave->{name} = bytesToString($args->{name});

	slave_calcproperty_handler($slave, $args);
	homunculus_state_handler($slave, $args);

	# ST0's counterpart for ST kRO, since it attempts to support all servers
	# TODO: we do this for homunculus, mercenary and our char... make 1 function and pass actor and attack_range?
	# or make function in Actor class
	if ($config{homunculus_attackDistanceAuto} && $config{attackDistance} != $slave->{attack_range} && exists $slave->{attack_range}) {
		message TF("Autodetected attackDistance for homunculus = %s\n", $slave->{attack_range}), "success";
		configModify('homunculus_attackDistance', $slave->{attack_range}, 1);
		configModify('homunculus_attackMaxDistance', $slave->{attack_range}, 1);
	}
}

sub homunculus_state_handler {
	my ($slave, $args) = @_;
	# Homunculus states:
	# 0 - alive and unnamed
	# 2 - rest
	# 4 - dead

	return unless $char->{homunculus};

	if ($args->{state} == 0) {
		$char->{homunculus}{renameflag} = 1;
	} else {
		$char->{homunculus}{renameflag} = 0;
	}

	if (($args->{state} & ~8) > 1) {
		foreach my $handle (@{$char->{homunculus}{slave_skillsID}}) {
			delete $char->{skills}{$handle};
		}
		$char->{homunculus}->clear();
		undef @{$char->{homunculus}{slave_skillsID}};
		if (defined $slave->{state} && $slave->{state} != $args->{state}) {
			if ($args->{state} & 2) {
				message T("Your Homunculus was vaporized!\n"), 'homunculus';
			} elsif ($args->{state} & 4) {
				message T("Your Homunculus died!\n"), 'homunculus';
			}
		}
	} elsif (defined $slave->{state} && $slave->{state} != $args->{state}) {
		if ($slave->{state} & 2) {
			message T("Your Homunculus was recalled!\n"), 'homunculus';
		} elsif ($slave->{state} & 4) {
			message T("Your Homunculus was resurrected!\n"), 'homunculus';
		}
	}
}

# TODO: wouldn't it be better if we calculated these only at (first) request after a change in value, if requested at all?
sub slave_calcproperty_handler {
	my ($slave, $args) = @_;
	# so we don't devide by 0
	# wtf
=pod
	$slave->{hp_max}       = ($args->{hp_max} > 0) ? $args->{hp_max} : $args->{hp};
	$slave->{sp_max}       = ($args->{sp_max} > 0) ? $args->{sp_max} : $args->{sp};
=cut

	$slave->{attack_speed}     = int (200 - (($args->{attack_delay} < 10) ? 10 : ($args->{attack_delay} / 10)));
	$slave->{hpPercent}    = $slave->{hp_max} ? ($slave->{hp} / $slave->{hp_max}) * 100 : undef;
	$slave->{spPercent}    = $slave->{sp_max} ? ($slave->{sp} / $slave->{sp_max}) * 100 : undef;
	$slave->{expPercent}   = ($args->{exp_max}) ? ($args->{exp} / $args->{exp_max}) * 100 : undef;
}

sub guild_chat {
	my ($self, $args) = @_;
	my ($chatMsgUser, $chatMsg); # Type: String
	my $chat; # Type: String

	return unless changeToInGameState();

	$chat = bytesToString($args->{message});
	if (($chatMsgUser, $chatMsg) = $chat =~ /(.*?) : (.*)/) {
		$chatMsgUser =~ s/ $//;
		stripLanguageCode(\$chatMsg);
		$chat = "$chatMsgUser : $chatMsg";
	}

	chatLog("g", "$chat\n") if ($config{'logGuildChat'});
	# Translation Comment: Guild Chat
	message TF("[Guild] %s\n", $chat), "guildchat";

	Plugins::callHook('packet_guildMsg', {
		MsgUser => $chatMsgUser,
		Msg => $chatMsg
	});
}

sub misc_effect {
	my ($self, $args) = @_;

	my $actor = Actor::get($args->{ID});
	message sprintf(
		$actor->verb(T("%s use effect: %s\n"), T("%s uses effect: %s\n")),
		$actor, defined $effectName{$args->{effect}} ? $effectName{$args->{effect}} : "Unknown #$args->{effect}"
	), 'effect'
}

sub guild_request {
	my ($self, $args) = @_;

	my $name = bytesToString($args->{name});
	message TF("自动拒绝加入公会 '%s' 的请求\n", $name);

	if (timeOut($timeout{'ai_guildAutoDeny'})) {
	$messageSender->sendGuildJoin($args->{ID}, 0);
	$timeout{'ai_guildAutoDeny'}{'time'} = time;
	}
}

sub identify {
	my ($self, $args) = @_;
	if ($args->{flag} == 0) {
		my $item = $char->inventory->getByServerIndex($args->{index});
		$item->{identified} = 1;
		$item->{type_equip} = $itemSlots_lut{$item->{nameID}};
		message TF("Item Identified: %s (%d)\n", $item->{name}, $item->{invIndex}), "info";
	} else {
		message T("Item Appraisal has failed.\n");
	}
	undef @identifyID;
}

sub identify_list {
	my ($self, $args) = @_;

	my $newmsg;
	my $msg = $args->{RAW_MSG};
	my $msg_size = $args->{RAW_MSG_SIZE};
	$self->decrypt(\$newmsg, substr($msg, 4));
	$msg = substr($msg, 0, 4).$newmsg;

	undef @identifyID;
	for (my $i = 4; $i < $msg_size; $i += 2) {
		my $index = unpack("v1", substr($msg, $i, 2));
		my $item = $char->inventory->getByServerIndex($index);
		binAdd(\@identifyID, $item->{invIndex});
	}

	my $num = @identifyID;
	message TF("Received Possible Identify List (%s item(s)) - type 'identify'\n", $num), 'info';
}

# TODO: store this state
sub ignore_all_result {
	my ($self, $args) = @_;
	if ($args->{type} == 0) {
		message T("All Players ignored\n");
	} elsif ($args->{type} == 1) {
		if ($args->{error} == 0) {
			message T("All players unignored\n");
		}
	}
}

# TODO: store list of ignored players
sub ignore_player_result {
	my ($self, $args) = @_;
	if ($args->{type} == 0) {
		message T("Player ignored\n");
	} elsif ($args->{type} == 1) {
		if ($args->{error} == 0) {
			message T("Player unignored\n");
		}
	}
}

sub whisper_list {
	my ($self, $args) = @_;

	my @whisperList = unpack 'x4' . (' Z24' x (($args->{RAW_MSG_SIZE}-4)/24)), $args->{RAW_MSG};

	debug "whisper_list: @whisperList\n", "parseMsg";
}

sub inventory_item_added {
	my ($self, $args) = @_;

	return unless changeToInGameState();

	my ($index, $amount, $fail) = ($args->{index}, $args->{amount}, $args->{fail});

	if (!$fail) {
		my $item = $char->inventory->getByServerIndex($index);
		if (!$item) {
			# Add new item
			$item = new Actor::Item();
			$item->{index} = $index;
			$item->{nameID} = $args->{nameID};
			$item->{type} = $args->{type};
			$item->{type_equip} = $args->{type_equip};
			$item->{amount} = $amount;
			$item->{identified} = $args->{identified};
			$item->{broken} = $args->{broken};
			$item->{upgrade} = $args->{upgrade};
			$item->{cards} = ($args->{switch} eq '029A') ? $args->{cards} + $args->{cards_ext}: $args->{cards};
			if ($args->{switch} eq '029A') {
				$args->{cards} .= $args->{cards_ext};
			} elsif ($args->{switch} eq '02D4') {
				$item->{expire} = $args->{expire} if (exists $args->{expire}); #a4 or V1 unpacking?
			}
			$item->{name} = itemName($item);
			$char->inventory->add($item);
		} else {
			# Add stackable item
			$item->{amount} += $amount;
		}

		$itemChange{$item->{name}} += $amount;
		my $disp = TF("Item added to inventory: %s (%d)",
			$item->{name}, $item->{invIndex});
		message "$disp\n", "drop";
		$disp .= " (". $field->baseName . ")\n";
		itemLog($disp);

		$args->{item} = $item;

		# TODO: move this stuff to AI()
		if (grep {$_ eq $item->{nameID}} @{$ai_v{npc_talk}{itemsIDlist}}, $ai_v{npc_talk}{itemID}) {

			$ai_v{'npc_talk'}{'talk'} = 'buy';
			$ai_v{'npc_talk'}{'time'} = time;
			undef $ai_v{npc_talk}{ID};
		}

		if ($AI == AI::AUTO) {
			# Auto-drop item
			if (pickupitems(lc($item->{name})) == -1 && !AI::inQueue('storageAuto', 'buyAuto')) {
				$messageSender->sendDrop($item->{index}, $amount);
				message TF("Auto-dropping item: %s (%d) x %d\n", $item->{name}, $item->{invIndex}, $amount), "drop";
			}
		}

	} elsif ($fail == 6) {
		message T("Can't loot item...wait...\n"), "drop";
	} elsif ($fail == 2) {
		message T("Cannot pickup item (inventory full)\n"), "drop";
	} elsif ($fail == 1) {
		message T("Cannot pickup item (you're Frozen?)\n"), "drop";
	} else {
		message TF("Cannot pickup item (failure code %d)\n", $fail), "drop";
	}
}

sub item_used {
	my ($self, $args) = @_;

	my ($index, $itemID, $ID, $remaining, $success) =
		@{$args}{qw(index itemID ID remaining success)};
	my %hook_args = (
		serverIndex => $index,
		itemID => $itemID,
		userID => $ID,
		remaining => $remaining,
		success => $success
	);

	if ($ID eq $accountID) {
		my $item = $char->inventory->getByServerIndex($index);
		if ($item) {
			if ($success == 1) {
				my $amount = $item->{amount} - $remaining;
				$item->{amount} -= $amount;

				message TF("You used Item: %s (%d) x %d - %d left\n", $item->{name}, $item->{invIndex},
					$amount, $remaining), "useItem", 1;
				$itemChange{$item->{name}}--;
				if ($item->{amount} <= 0) {
					$char->inventory->remove($item);
				}

				$hook_args{item} = $item;
				$hook_args{invIndex} = $item->{invIndex};
				$hook_args{name} => $item->{name};
				$hook_args{amount} = $amount;

			} else {
				message TF("You failed to use item: %s (%d)\n", $item ? $item->{name} : "#$itemID", $remaining), "useItem", 1;
			}
 		} else {
			if ($success == 1) {
				message TF("You used unknown item #%d - %d left\n", $itemID, $remaining), "useItem", 1;
			} else {
				message TF("You failed to use unknown item #%d - %d left\n", $itemID, $remaining), "useItem", 1;
			}
		}
	} else {
		my $actor = Actor::get($ID);
		my $itemDisplay = itemNameSimple($itemID);
		message TF("%s used Item: %s - %s left\n", $actor, $itemDisplay, $remaining), "useItem", 2;
	}
	Plugins::callHook('packet_useitem', \%hook_args);
}

sub inventory_items_nonstackable {
	my ($self, $args) = @_;
	return unless changeToInGameState();

	$self->_items_list({
		class => 'Actor::Item',
		hook => 'packet_inventory',
		debug_str => 'Non-Stackable Inventory Item',
		items => [$self->parse_items_nonstackable($args)],
		getter => sub { $char->inventory->getByServerIndex($_[0]{index}) },
		adder => sub { $char->inventory->add($_[0]) },
		callback => sub {
			my ($local_item) = @_;

			if ($local_item->{equipped}) {
				foreach (%equipSlot_rlut){
					if ($_ & $local_item->{equipped}){
						next if $_ == 10; #work around Arrow bug
						next if $_ == 32768;
						$char->{equipment}{$equipSlot_lut{$_}} = $local_item;
					}
				}
			}
		}
	});

	$ai_v{'inventory_time'} = time + 1;
	$ai_v{'cart_time'} = time + 1;
}

sub inventory_items_stackable {
	my ($self, $args) = @_;
	return unless changeToInGameState();

	$self->_items_list({
		class => 'Actor::Item',
		hook => 'packet_inventory',
		debug_str => 'Stackable Inventory Item',
		items => [$self->parse_items_stackable($args)],
		getter => sub { $char->inventory->getByServerIndex($_[0]{index}) },
		adder => sub { $char->inventory->add($_[0]) },
		callback => sub {
			my ($local_item) = @_;

			if (defined $char->{arrow} && $local_item->{index} == $char->{arrow}) {
				$local_item->{equipped} = 32768;
				$char->{equipment}{arrow} = $local_item;
			}
		}
	});

	$ai_v{'inventory_time'} = time + 1;
	$ai_v{'cart_time'} = time + 1;
}

sub item_appeared {
	my ($self, $args) = @_;
	return unless changeToInGameState();

	my $item = $itemsList->getByID($args->{ID});
	my $mustAdd;
	if (!$item) {
		$item = new Actor::Item();
		$item->{appear_time} = time;
		$item->{amount} = $args->{amount};
		$item->{nameID} = $args->{nameID};
		$item->{identified} = $args->{identified};
		$item->{name} = itemName($item);
		$item->{ID} = $args->{ID};
		$mustAdd = 1;
	}
	$item->{pos}{x} = $args->{x};
	$item->{pos}{y} = $args->{y};
	$item->{pos_to}{x} = $args->{x};
	$item->{pos_to}{y} = $args->{y};
	$itemsList->add($item) if ($mustAdd);

	# Take item as fast as possible
	 if ($AI == AI::AUTO && pickupitems(lc($item->{name})) == 2
	 # && ($config{'openFastTake'})
	 && ($config{'itemsTakeAuto'})
	 && (percent_weight($char) < $config{'itemsMaxWeight'})
	 && distance($item->{pos}, $char->{pos_to}) <= 1) {
		my $myPos = $char->{pos};
		my %vec;
		my $direction;
		getVector(\%vec, $item->{pos}, $myPos);
		$direction = int(sprintf("%.0f", (360 - vectorToDegree(\%vec)) / 45)) % 8;
		$messageSender->sendLook($direction, 0);
	 	$messageSender->sendTake($args->{ID});
	 	# 上面这样可能会导致被检测到
		# AI::queue("take");
	 }

	message TF("Item Appeared: %s (%d) x %d (%d, %d)\n", $item->{name}, $item->{binID}, $item->{amount}, $args->{x}, $args->{y}), "drop", 1;
}

sub item_exists {
	my ($self, $args) = @_;
	return unless changeToInGameState();

	my $item = $itemsList->getByID($args->{ID});
	my $mustAdd;
	if (!$item) {
		$item = new Actor::Item();
		$item->{appear_time} = time;
		$item->{amount} = $args->{amount};
		$item->{nameID} = $args->{nameID};
		$item->{ID} = $args->{ID};
		$item->{identified} = $args->{identified};
		$item->{name} = itemName($item);
		$mustAdd = 1;
	}
	$item->{pos}{x} = $args->{x};
	$item->{pos}{y} = $args->{y};
	$item->{pos_to}{x} = $args->{x};
	$item->{pos_to}{y} = $args->{y};
	$itemsList->add($item) if ($mustAdd);

	message TF("Item Exists: %s (%d) x %d\n", $item->{name}, $item->{binID}, $item->{amount}), "drop", 1;
}

sub item_disappeared {
	my ($self, $args) = @_;
	return unless changeToInGameState();

	my $item = $itemsList->getByID($args->{ID});
	if ($item) {
		if ($config{attackLooters} && AI::action ne "sitAuto" && pickupitems(lc($item->{name})) > 0) {
			foreach my Actor::Monster $monster (@{$monstersList->getItems()}) { # attack looter code
				if (my $control = mon_control($monster->name,$monster->{nameID})) {
					next if ( ($control->{attack_auto}  ne "" && $control->{attack_auto} == -1)
						|| ($control->{attack_lvl}  ne "" && $control->{attack_lvl} > $char->{lv})
						|| ($control->{attack_jlvl} ne "" && $control->{attack_jlvl} > $char->{lv_job})
						|| ($control->{attack_hp}   ne "" && $control->{attack_hp} > $char->{hp})
						|| ($control->{attack_sp}   ne "" && $control->{attack_sp} > $char->{sp})
						);
				}
				if (distance($item->{pos}, $monster->{pos}) == 0) {
					attack($monster->{ID});
					message TF("Attack Looter: %s looted %s\n", $monster->nameIdx, $item->{name}), "looter";
					last;
				}
			}
		}

		debug "Item Disappeared: $item->{name} ($item->{binID})\n", "parseMsg_presence";
		my $ID = $args->{ID};
		$items_old{$ID} = $item->deepCopy();
		$items_old{$ID}{disappeared} = 1;
		$items_old{$ID}{gone_time} = time;
		$itemsList->removeByID($ID);
	}
}

sub item_skill {
	my ($self, $args) = @_;

	my $skillID = $args->{skillID};
	my $targetType = $args->{targetType}; # we don't use this yet
	my $skillLv = $args->{skillLv};
	my $sp = $args->{sp}; # we don't use this yet
	my $skillName = $args->{skillName};

	my $skill = new Skill(idn => $skillID, level => $skillLv);
	message TF("Permitted to use %s (%d), level %d\n", $skill->getName, $skill->getIDN, $skill->getLevel);

	unless ($config{noAutoSkill} && $skillID != 26)  {
		if ($skillID == 26) {
			$timeout{ai_teleport_retry}{time} = time;
			AI::queue('teleport', {item_lv => $skillLv});
		} else {
			$messageSender->sendSkillUse($skillID, $skillLv, $accountID);
		}
		undef $char->{permitSkill};
	} else {
		$char->{permitSkill} = $skill;
	}

	Plugins::callHook('item_skill', {
		ID => $skillID,
		level => $skillLv,
		name => $skillName
	});
}

sub item_upgrade {
	my ($self, $args) = @_;
	my ($type, $index, $upgrade) = @{$args}{qw(type index upgrade)};

	my $item = $char->inventory->getByServerIndex($index);
	if ($item) {
		$item->{upgrade} = $upgrade;
		message TF("Item %s has been upgraded to +%s\n", $item->{name}, $upgrade), "parseMsg/upgrade";
		$item->setName(itemName($item));
	}
}

sub job_equipment_hair_change {
	my ($self, $args) = @_;
	return unless changeToInGameState();

	my $actor = Actor::get($args->{ID});
	assert(UNIVERSAL::isa($actor, "Actor")) if DEBUG;

	if ($args->{part} == 0) {
		# Job change
		$actor->{jobID} = $args->{number};
 		message TF("%s changed job to: %s\n", $actor, $jobs_lut{$args->{number}}), "parseMsg/job", ($actor->isa('Actor::You') ? 0 : 2);

	} elsif ($args->{part} == 3) {
		# Bottom headgear change
 		message TF("%s changed bottom headgear to: %s\n", $actor, headgearName($args->{number})), "parseMsg_statuslook", 2 unless $actor->isa('Actor::You');
		$actor->{headgear}{low} = $args->{number} if ($actor->isa('Actor::Player') || $actor->isa('Actor::You'));

	} elsif ($args->{part} == 4) {
		# Top headgear change
 		message TF("%s changed top headgear to: %s\n", $actor, headgearName($args->{number})), "parseMsg_statuslook", 2 unless $actor->isa('Actor::You');
		$actor->{headgear}{top} = $args->{number} if ($actor->isa('Actor::Player') || $actor->isa('Actor::You'));

	} elsif ($args->{part} == 5) {
		# Middle headgear change
 		message TF("%s changed middle headgear to: %s\n", $actor, headgearName($args->{number})), "parseMsg_statuslook", 2 unless $actor->isa('Actor::You');
		$actor->{headgear}{mid} = $args->{number} if ($actor->isa('Actor::Player') || $actor->isa('Actor::You'));

	} elsif ($args->{part} == 6) {
		# Hair color change
		$actor->{hair_color} = $args->{number};
 		message TF("%s changed hair color to: %s (%s)\n", $actor, $haircolors{$args->{number}}, $args->{number}), "parseMsg/hairColor", ($actor->isa('Actor::You') ? 0 : 2);
	}

	#my %parts = (
	#	0 => 'Body',
	#	2 => 'Right Hand',
	#	3 => 'Low Head',
	#	4 => 'Top Head',
	#	5 => 'Middle Head',
	#	8 => 'Left Hand'
	#);
	#if ($part == 3) {
	#	$part = 'low';
	#} elsif ($part == 4) {
	#	$part = 'top';
	#} elsif ($part == 5) {
	#	$part = 'mid';
	#}
	#
	#my $name = getActorName($ID);
	#if ($part == 3 || $part == 4 || $part == 5) {
	#	my $actor = Actor::get($ID);
	#	$actor->{headgear}{$part} = $items_lut{$number} if ($actor);
	#	my $itemName = $items_lut{$itemID};
	#	$itemName = 'nothing' if (!$itemName);
	#	debug "$name changes $parts{$part} ($part) equipment to $itemName\n", "parseMsg";
	#} else {
	#	debug "$name changes $parts{$part} ($part) equipment to item #$number\n", "parseMsg";
	#}

}

# Leap, Snap, Back Slide... Various knockback
sub high_jump {
	my ($self, $args) = @_;
	return unless changeToInGameState();

	my $actor = Actor::get ($args->{ID});
	if (!defined $actor) {
		$actor = new Actor::Unknown;
		$actor->{appear_time} = time;
		$actor->{nameID} = unpack ('V', $args->{ID});
	} elsif ($actor->{pos_to}{x} == $args->{x} && $actor->{pos_to}{y} == $args->{y}) {
		message TF("%s failed to instantly move\n", $actor->nameString), 'skill';
		return;
	}

	$actor->{pos} = {x => $args->{x}, y => $args->{y}};
	$actor->{pos_to} = {x => $args->{x}, y => $args->{y}};

	message TF("%s instantly moved to %d, %d\n", $actor->nameString, $actor->{pos_to}{x}, $actor->{pos_to}{y}), 'skill', 2;

	$actor->{time_move} = time;
	$actor->{time_move_calc} = 0;
}

sub hp_sp_changed {
	my ($self, $args) = @_;
	return unless changeToInGameState();

	my $type = $args->{type};
	my $amount = $args->{amount};
	if ($type == 5) {
		$char->{hp} += $amount;
		$char->{hp} = $char->{hp_max} if ($char->{hp} > $char->{hp_max});
	} elsif ($type == 7) {
		$char->{sp} += $amount;
		$char->{sp} = $char->{sp_max} if ($char->{sp} > $char->{sp_max});
	}
}

sub local_broadcast {
	my ($self, $args) = @_;
	my $message = bytesToString($args->{message});
	stripLanguageCode(\$message);
	chatLog("lb", "$message\n");# if ($config{logLocalBroadcast});
	message "$message\n", "schat";
	Plugins::callHook('packet_localBroadcast', {
		Msg => $message
	});
}

sub login_error {
	my ($self, $args) = @_;

	$net->serverDisconnect();
	if ($args->{type} == REFUSE_INVALID_ID) {
		error TF("Account name [%s] doesn't exist\n", $config{'username'}), "connection";
		if (!$net->clientAlive() && !$config{'ignoreInvalidLogin'}) {
			my $username = $interface->query(T("Enter your Ragnarok Online username again."));
			if (defined($username)) {
				configModify('username', $username, 1);
				$timeout_ex{master}{time} = 0;
				$conState_tries = 0;
			} else {
				quit();
				return;
			}
		}
	} elsif ($args->{type} == REFUSE_INVALID_PASSWD) {
		error TF("Password Error for account [%s]\n", $config{'username'}), "connection";
		if (!$net->clientAlive() && !$config{'ignoreInvalidLogin'}) {
			my $password = $interface->query(T("Enter your Ragnarok Online password again."), isPassword => 1);
			if (defined($password)) {
				configModify('password', $password, 1);
				$timeout_ex{master}{time} = 0;
				$conState_tries = 0;
			} else {
				quit();
				return;
			}
		}
	} elsif ($args->{type} == ACCEPT_ID_PASSWD) {
		error T("The server has denied your connection.\n"), "connection";
	} elsif ($args->{type} == REFUSE_NOT_CONFIRMED) {
		$interface->errorDialog(T("Critical Error: Your account has been blocked."));
		$quit = 1 unless ($net->clientAlive());
	} elsif ($args->{type} == REFUSE_INVALID_VERSION) {
		my $master = $masterServer;
		error TF("Connect failed, something is wrong with the login settings:\n" .
			"version: %s\n" .
			"master_version: %s\n" .
			"serverType: %s\n", $master->{version}, $master->{master_version}, $config{serverType}), "connection";
		relog(30);
	} elsif ($args->{type} == REFUSE_BLOCK_TEMPORARY) {
		error TF("The server is temporarily blocking your connection until %s\n", $args->{date}), "connection";
	} elsif ($args->{type} == REFUSE_USER_PHONE_BLOCK) { #Phone lock
		error T("Please dial to activate the login procedure.\n"), "connection";
		Plugins::callHook('dial');
		relog(10);
	} elsif ($args->{type} == ACCEPT_LOGIN_USER_PHONE_BLOCK) {
		error T("Mobile Authentication: Max number of simultaneous IP addresses reached.\n"), "connection";
	} else {
		error TF("The server has denied your connection for unknown reason (%d).\n", $args->{type}), 'connection';
	}

	if ($args->{type} != REFUSE_INVALID_VERSION && $versionSearch) {
		$versionSearch = 0;
		writeSectionedFileIntact(Settings::getTableFilename("servers.txt"), \%masterServers);
	}
}

sub login_error_game_login_server {
	error T("Error logging into Character Server (invalid character specified)...\n"), 'connection';
	$net->setState(1);
	undef $conState_tries;
	$timeout_ex{master}{time} = time;
	$timeout_ex{master}{timeout} = $timeout{'reconnect'}{'timeout'};
	$net->serverDisconnect();
}

# The difference between map_change and map_changed is that map_change
# represents a map change event on the current map server, while
# map_changed means that you've changed to a different map server.
# map_change also represents teleport events.
sub map_change {
	my ($self, $args) = @_;
	return unless changeToInGameState();

	my $oldMap = $field ? $field->baseName : undef; # Get old Map name without InstanceID
	my ($map) = $args->{map} =~ /([\s\S]*)\./;
	my $map_noinstance;
	($map_noinstance, undef) = Field::nameToBaseName(undef, $map); # Hack to clean up InstanceID

	checkAllowedMap($map_noinstance);
	if (!$field || $map ne $field->name()) {
		eval {
			$field = new Field(name => $map);
		};
		if (my $e = caught('FileNotFoundException', 'IOException')) {
			error TF("Cannot load field %s: %s\n", $map_noinstance, $e);
			undef $field;
		} elsif ($@) {
			die $@;
		}
	}

	if ($ai_v{temp}{clear_aiQueue}) {
		AI::clear;
		AI::SlaveManager::clear();
	}

	main::initMapChangeVars();
	for (my $i = 0; $i < @ai_seq; $i++) {
		ai_setMapChanged($i);
	}
	AI::SlaveManager::setMapChanged ();
	if ($net->version == 0) {
		$ai_v{portalTrace_mapChanged} = time;
	}

	my %coords = (
		x => $args->{x},
		y => $args->{y}
	);
	$char->{pos} = {%coords};
	$char->{pos_to} = {%coords};
	message TF("Map Change: %s (%s, %s)\n", $args->{map}, $char->{pos}{x}, $char->{pos}{y}), "connection";
	if ($net->version == 1) {
		ai_clientSuspend(0, 10);
	} else {
		$messageSender->sendMapLoaded();
		# $messageSender->sendSync(1);
		$timeout{ai}{time} = time;
	}

	Plugins::callHook('Network::Receive::map_changed', {
		oldMap => $oldMap,
	});

	$timeout{ai}{time} = time;
}

sub map_changed {
	my ($self, $args) = @_;
	$net->setState(4);

	my $oldMap = $field ? $field->baseName : undef; # Get old Map name without InstanceID
	my ($map) = $args->{map} =~ /([\s\S]*)\./;
	my $map_noinstance;
	($map_noinstance, undef) = Field::nameToBaseName(undef, $map); # Hack to clean up InstanceID

	checkAllowedMap($map_noinstance);
	if (!$field || $map ne $field->name()) {
		eval {
			$field = new Field(name => $map);
		};
		if (my $e = caught('FileNotFoundException', 'IOException')) {
			error TF("Cannot load field %s: %s\n", $map_noinstance, $e);
			undef $field;
		} elsif ($@) {
			die $@;
		}
	}

	my %coords = (
		x => $args->{x},
		y => $args->{y}
	);
	$char->{pos} = {%coords};
	$char->{pos_to} = {%coords};

	undef $conState_tries;
	for (my $i = 0; $i < @ai_seq; $i++) {
		ai_setMapChanged($i);
	}
	AI::SlaveManager::setMapChanged ();
	$ai_v{portalTrace_mapChanged} = time;

	$map_ip = makeIP($args->{IP});
	$map_port = $args->{port};
	message(swrite(
		"---------Map  Info----------", [],
		"MAP Name: @<<<<<<<<<<<<<<<<<<",
		[$args->{map}],
		"MAP IP: @<<<<<<<<<<<<<<<<<<",
		[$map_ip],
		"MAP Port: @<<<<<<<<<<<<<<<<<<",
		[$map_port],
		"-------------------------------", []),
		"connection");

	message T("Closing connection to Map Server\n"), "connection";
	$net->serverDisconnect unless ($net->version == 1);

	# Reset item and skill times. The effect of items (like aspd potions)
	# and skills (like Twohand Quicken) disappears when we change map server.
	# NOTE: with the newer servers, this isn't true anymore
	my $i = 0;
	while (exists $config{"useSelf_item_$i"}) {
		if (!$config{"useSelf_item_$i"}) {
			$i++;
			next;
		}

		$ai_v{"useSelf_item_$i"."_time"} = 0;
		$i++;
	}
	$i = 0;
	while (exists $config{"useSelf_skill_$i"}) {
		if (!$config{"useSelf_skill_$i"}) {
			$i++;
			next;
		}

		$ai_v{"useSelf_skill_$i"."_time"} = 0;
		$i++;
	}
	$i = 0;
	while (exists $config{"doCommand_$i"}) {
		if (!$config{"doCommand_$i"}) {
			$i++;
			next;
		}

		$ai_v{"doCommand_$i"."_time"} = 0;
		$i++;
	}
	if ($char) {
		delete $char->{statuses};
		$char->{spirits} = 0;
		delete $char->{permitSkill};
		delete $char->{encoreSkill};
	}
	$cart{exists} = 0;

	Plugins::callHook('Network::Receive::map_changed', {
		oldMap => $oldMap,
	});
	$timeout{ai}{time} = time;
}

sub memo_success {
	my ($self, $args) = @_;
	if ($args->{fail}) {
		warning T("Memo Failed\n");
	} else {
		message T("Memo Succeeded\n"), "success";
	}
}

# +message_string
sub mercenary_off {
	$slavesList->removeByID($char->{mercenary}{ID});
	delete $char->{slaves}{$char->{mercenary}{ID}};
	delete $char->{mercenary};
}
# -message_string

# not only for mercenaries, this is an all purpose packet !
sub message_string {
	my ($self, $args) = @_;

	if (@msgTable[$args->{msg_id}++]) { # show message from msgstringtable
		warning T(@msgTable[$args->{msg_id}++]."\n");
		$self->mercenary_off() if ($args->{msg_id} >= 1267 && $args->{msg_id} <= 1270);
		
	} else {
		if ($args->{msg_id} == 1267) {
			message T("Mercenary soldier's duty hour is over.\n"), "info";
			$self->mercenary_off ();
	
		} elsif ($args->{msg_id} == 1268) {
			message T("Your mercenary soldier has been killed.\n"), "info";
			$self->mercenary_off ();
	
		} elsif ($args->{msg_id} == 1269) {
			message T("Your mercenary soldier has been fired.\n"), "info";
			$self->mercenary_off ();
	
		} elsif ($args->{msg_id} == 1270) {
			message T("Your mercenary soldier has ran away.\n"), "info";
			$self->mercenary_off ();
			
		} elsif ($args->{msg_id} ==	1358) {
			message T("View player equip request denied.\n"), "info";
		} elsif ($args->{msg_id} == 1712) {
			message T("You need to be at least base level 10 to send private messages.\n"), "info";
		} elsif ($args->{msg_id} == 1924) {
			warning T("错误1924: 请在本次操作前先完成其他动作.(例如: NPC对话, 选择技能列表等)\n"), "info";
		} elsif ($args->{msg_id} == 1774) {
			warning T("当前装备不符合装备的等级要求.\n"), "info";
		} elsif ($args->{msg_id} == 1775) {
			warning T("当前使用的道具不符合道具的等级要求.\n"), "info";
		} else {
			warning TF("msg_id: %s gave unknown results in: %s\n", $args->{msg_id}, $self->{packet_list}{$args->{switch}}->[0]);
		}
	}
}

sub monster_typechange {
	my ($self, $args) = @_;

	# Class change / monster type change
	# 01B0 : long ID, byte WhateverThisIs, long type
	my $ID = $args->{ID};
	my $type = $args->{type};
	my $monster = $monstersList->getByID($ID);
	if ($monster) {
		my $oldName = $monster->name;
		if ($monsters_lut{$type}) {
			$monster->setName($monsters_lut{$type});
		} else {
			$monster->setName(undef);
		}
		$monster->{nameID} = $type;
		$monster->{dmgToParty} = 0;
		$monster->{dmgFromParty} = 0;
		$monster->{missedToParty} = 0;
		message TF("Monster %s (%d) changed to %s\n", $oldName, $monster->{binID}, $monster->name);
	}
}

sub monster_ranged_attack {
	my ($self, $args) = @_;

	my $ID = $args->{ID};
	my $range = $args->{range};

	my %coords1;
	$coords1{x} = $args->{sourceX};
	$coords1{y} = $args->{sourceY};
	my %coords2;
	$coords2{x} = $args->{targetX};
	$coords2{y} = $args->{targetY};

	my $monster = $monstersList->getByID($ID);
	$monster->{pos_attack_info} = {%coords1} if ($monster);
	$char->{pos} = {%coords2};
	$char->{pos_to} = {%coords2};
	debug "Received attack location - monster: $coords1{x},$coords1{y} - " .
		"you: $coords2{x},$coords2{y}\n", "parseMsg_move", 2;
}

sub mvp_item {
	my ($self, $args) = @_;
	my $display = itemNameSimple($args->{itemID});
	message TF("Get MVP item %s\n", $display);
	chatLog("k", TF("Get MVP item %s\n", $display));
}

sub mvp_other {
	my ($self, $args) = @_;
	my $display = Actor::get($args->{ID});
	message TF("%s become MVP!\n", $display);
	chatLog("k", TF("%s became MVP!\n", $display));
}

sub mvp_you {
	my ($self, $args) = @_;
	my $msg = TF("Congratulations, you are the MVP! Your reward is %s exp!\n", $args->{expAmount});
	message $msg;
	chatLog("k", $msg);
}

sub npc_image {
	my ($self, $args) = @_;
	my ($imageName) = bytesToString($args->{npc_image});
	if ($args->{type} == 2) {
		debug "Show NPC image: $imageName\n", "parseMsg";
	} elsif ($args->{type} == 255) {
		debug "Hide NPC image: $imageName\n", "parseMsg";
	} else {
		debug "NPC image: $imageName ($args->{type})\n", "parseMsg";
	}
}

sub npc_sell_list {
	my ($self, $args) = @_;
	#sell list, similar to buy list
	if (length($args->{RAW_MSG}) > 4) {
		my $newmsg;
		$self->decrypt(\$newmsg, substr($args->{RAW_MSG}, 4));
		my $msg = substr($args->{RAW_MSG}, 0, 4).$newmsg;
	}
	undef $talk{buyOrSell};
	message T("Ready to start selling items\n");
	
	debug "You can sell:\n", "info";
	for (my $i = 0; $i < length($args->{itemsdata}); $i += 10) {
		my ($index, $price, $price_overcharge) = unpack("v L L", substr($args->{itemsdata},$i,($i + 10)));
		my $item = $char->inventory->getByServerIndex($index);
		$item->{sellable} = 1; # flag this item as sellable
		debug "[$item->{amount} x $item->{name}] for $price_overcharge z each. \n", "info";
	}

	# continue talk sequence now
	$ai_v{npc_talk}{time} = time;
}

sub npc_store_begin {
	my ($self, $args) = @_;
	undef %talk;
	$talk{buyOrSell} = 1;
	$talk{ID} = $args->{ID};
	$ai_v{npc_talk}{talk} = 'buy';
	$ai_v{npc_talk}{time} = time;

	my $name = getNPCName($args->{ID});

	message TF("%s: Type 'store' to start buying, or type 'sell' to start selling\n", $name), "npc";
}

sub npc_store_info {
	my ($self, $args) = @_;
	my $newmsg;
	$self->decrypt(\$newmsg, substr($args->{RAW_MSG}, 4));
	my $msg = substr($args->{RAW_MSG}, 0, 4).$newmsg;
	undef @storeList;
	my $storeList = 0;
	undef $talk{'buyOrSell'};
	for (my $i = 4; $i < $args->{RAW_MSG_SIZE}; $i += 11) {
		my $price = unpack("V1", substr($msg, $i, 4));
		my $type = unpack("C1", substr($msg, $i + 8, 1));
		my $ID = unpack("v1", substr($msg, $i + 9, 2));

		my $store = $storeList[$storeList] = {};
		# TODO: use itemName() or itemNameSimple()?
		my $display = ($items_lut{$ID} ne "")
			? $items_lut{$ID}
			: "Unknown ".$ID;
		$store->{name} = $display;
		$store->{nameID} = $ID;
		$store->{type} = $type;
		$store->{price} = $price;
		debug "Item added to Store: $store->{name} - $price z\n", "parseMsg", 2;
		$storeList++;
	}

	# Real RO client can be receive this message without NPC Information. We should mimic this behavior.
	my $name = (defined $talk{ID}) ? getNPCName($talk{ID}) : 'Unknown';

	$ai_v{npc_talk}{talk} = 'store';
	# continue talk sequence now
	$ai_v{'npc_talk'}{'time'} = time;

	if (AI::action ne 'buyAuto') {
		message TF("----------%s's Store List-----------\n" .
			"#  Name                    Type               Price\n", $name), "list";
		my $display;
		for (my $i = 0; $i < @storeList; $i++) {
			$display = $storeList[$i]{'name'};
			message(swrite(
				"@< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<< @>>>>>>>z",
				[$i, $display, $itemTypes_lut{$storeList[$i]{'type'}}, $storeList[$i]{'price'}]),
				"list");
		}
		message("-------------------------------\n", "list");
	}
}

sub npc_talk {
	my ($self, $args) = @_;

	$talk{ID} = $args->{ID};
	$talk{nameID} = unpack 'V', $args->{ID};
	$talk{msg} = bytesToString ($args->{msg});

=pod
	my $newmsg;
	$self->decrypt(\$newmsg, substr($args->{RAW_MSG}, 8));

	my $msg = substr($args->{RAW_MSG}, 0, 8) . $newmsg;
	my $ID = substr($msg, 4, 4);
	my $talkMsg = unpack("Z*", substr($msg, 8));
	$talk{ID} = $ID;
	$talk{nameID} = unpack("V1", $ID);
	$talk{msg} = bytesToString($talkMsg);
=cut

	# Remove RO color codes
	$talk{msg} =~ s/\^[a-fA-F0-9]{6}//g;

	$ai_v{npc_talk}{talk} = 'initiated';
	$ai_v{npc_talk}{time} = time;

	my $name = getNPCName($talk{ID});
	Plugins::callHook('npc_talk', {
						ID => $talk{ID},
						nameID => $talk{nameID},
						name => $name,
						msg => $talk{msg},
						});
	message "$name: $talk{msg}\n", "npc";
}

sub npc_talk_close {
	my ($self, $args) = @_;
	# 00b6: long ID
	# "Close" icon appreared on the NPC message dialog
	my $ID = $args->{ID};
	my $name = getNPCName($ID);

	message TF("%s: Done talking\n", $name), "npc";

	# I noticed that the RO client doesn't send a 'talk cancel' packet
	# when it receives a 'npc_talk_closed' packet from the server'.
	# But on pRO Thor (with Kapra password) this is required in order to
	# open the storage.
	#
	# UPDATE: not sending 'talk cancel' breaks autostorage on iRO.
	# This needs more investigation.
	if (!$talk{canceled}) {
		$messageSender->sendTalkCancel($ID);
	}

	$ai_v{npc_talk}{talk} = 'close';
	$ai_v{npc_talk}{time} = time;
	undef %talk;
	
	Plugins::callHook('npc_talk_done', {ID => $ID});
}

sub npc_talk_continue {
	my ($self, $args) = @_;
	my $ID = substr($args->{RAW_MSG}, 2, 4);
	my $name = getNPCName($ID);

	$ai_v{npc_talk}{talk} = 'next';
	$ai_v{npc_talk}{time} = time;

	if ($config{autoTalkCont}) {
		message TF("%s: Auto-continuing talking\n", $name), "npc";
		$messageSender->sendTalkContinue($ID);
		# This time will be reset once the NPC responds
		$ai_v{npc_talk}{time} = time + $timeout{'ai_npcTalk'}{'timeout'} + 5;
	} else {
		message TF("%s: Type 'talk cont' to continue talking\n", $name), "npc";
	}
}

sub npc_talk_number {
	my ($self, $args) = @_;

	my $ID = $args->{ID};

	my $name = getNPCName($ID);
	$ai_v{npc_talk}{talk} = 'number';
	$ai_v{npc_talk}{time} = time;

	message TF("%s: Type 'talk num <number #>' to input a number.\n", $name), "input";
	$ai_v{'npc_talk'}{'talk'} = 'num';
	$ai_v{'npc_talk'}{'time'} = time;
	$ai_v{'npc_talk'}{'ID'} = $ID;
	$talk{'ID'} = $ID;
}

sub npc_talk_responses {
	my ($self, $args) = @_;
	# 00b7: word len, long ID, string str
	# A list of selections appeared on the NPC message dialog.
	# Each item is divided with ':'
	my $newmsg;
	$self->decrypt(\$newmsg, substr($args->{RAW_MSG}, 8));
	my $msg = substr($args->{RAW_MSG}, 0, 8).$newmsg;

	my $ID = substr($msg, 4, 4);
	$talk{ID} = $ID;
	my $talk = unpack("Z*", substr($msg, 8));
	$talk = substr($msg, 8) if (!defined $talk);
	$talk = bytesToString($talk);

	my @preTalkResponses = split /:/, $talk;
	$talk{responses} = [];
	foreach my $response (@preTalkResponses) {
		# Remove RO color codes
		$response =~ s/\^[a-fA-F0-9]{6}//g;
		if ($response =~ /^\^nItemID\^(\d+)$/) {
			$response = itemNameSimple($1);
		}

		push @{$talk{responses}}, $response if ($response ne "");
	}

	$talk{responses}[@{$talk{responses}}] = "Cancel Chat";

	$ai_v{'npc_talk'}{'talk'} = 'select';
	$ai_v{'npc_talk'}{'time'} = time;
	$ai_v{'npc_talk'}{'ID'} = $ID;

	my $list = T("----------Responses-----------\n" .
		"#  Response\n");
	for (my $i = 0; $i < @{$talk{responses}}; $i++) {
		$list .= swrite(
			"@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<",
			[$i, $talk{responses}[$i]]);
	}
	$list .= "-------------------------------\n";
	message($list, "list");
	my $name = getNPCName($ID);
	Plugins::callHook('npc_talk_responses', {
						ID => $ID,
						name => $name,
						responses => $talk{responses},
						});
	message TF("%s: Type 'talk resp #' to choose a response.\n", $name), "npc";

	my $the_x = 0;
	my $the_y = 0;
	my $actor;
	$actor = $npcsList->getByID($ID);
	if (!defined $actor) {
		$actor = $portalsList->getByID($ID);
		if (defined $actor) {
			$the_x = $actor->{pos}{x};
			$the_y = $actor->{pos}{y};
		}
	} else {
		$the_x = $actor->{pos}{x};
		$the_y = $actor->{pos}{y};
	}
	if (defined $actor && $talk{toNPC}) {
		$talk{active} = 1 if ($the_x == $talk{toNPC}{x} && $the_y == $talk{toNPC}{y});
	}
}

sub npc_talk_text {
	my ($self, $args) = @_;

	my $ID = $args->{ID};

	my $name = getNPCName($ID);
	message TF("%s: Type 'talk text' (Respond to NPC)\n", $name), "npc";
	$ai_v{npc_talk}{talk} = 'text';
	$ai_v{npc_talk}{time} = time;
}

# TODO: store this state
sub party_allow_invite {
   my ($self, $args) = @_;

   if ($args->{type}) {
      message T("Not allowed other player invite to Party\n"), "party", 1;
   } else {
      message T("Allowed other player invite to Party\n"), "party", 1;
   }
}

sub party_chat {
	my ($self, $args) = @_;
	my $msg;

	$self->decrypt(\$msg, $args->{message});
	$msg = bytesToString($msg);

	# Type: String
	my ($chatMsgUser, $chatMsg) = $msg =~ /(.*?) : (.*)/;
	$chatMsgUser =~ s/ $//;

	stripLanguageCode(\$chatMsg);
	# Type: String
	my $chat = "$chatMsgUser : $chatMsg";
	message TF("[Party] %s\n", $chat), "partychat";

	chatLog("p", "$chat\n") if ($config{'logPartyChat'});

	Plugins::callHook('packet_partyMsg', {
		MsgUser => $chatMsgUser,
		Msg => $chatMsg
	});
}

# TODO: itemPickup itemDivision
sub party_exp {
	my ($self, $args) = @_;
	$char->{party}{share} = $args->{type};
	if ($args->{type} == 0) {
		message T("Party EXP set to Individual Take\n"), "party", 1;
	} elsif ($args->{type} == 1) {
		message T("Party EXP set to Even Share\n"), "party", 1;
	} else {
		error T("Error setting party option\n");
	}
	if ($args->{itemPickup} == 0) {
		message T("Party item set to Individual Take\n"), "party", 1;
	} elsif ($args->{itemPickup} == 1) {
		message T("Party item set to Even Share\n"), "party", 1;
	} else {
		error T("Error setting party option\n");
	}
	if ($args->{itemDivision} == 0) {
		message T("Party item division set to Individual Take\n"), "party", 1;
	} elsif ($args->{itemDivision} == 1) {
		message T("Party item division set to Even Share\n"), "party", 1;
	} else {
		error T("Error setting party option\n");
	}
}

sub party_leader {
	my ($self, $args) = @_;
	for (my $i = 0; $i < @partyUsersID; $i++) {
		if (unpack("V",$partyUsersID[$i]) eq $args->{new}) {
			$char->{party}{users}{$partyUsersID[$i]}{admin} = 1;
			message TF("New party leader: %s\n", $char->{party}{users}{$partyUsersID[$i]}{name}), "party", 1;
		}
		if (unpack("V",$partyUsersID[$i]) eq $args->{old}) {
			$char->{party}{users}{$partyUsersID[$i]}{admin} = '';
		}
	}
}

sub party_hp_info {
	my ($self, $args) = @_;
	my $ID = $args->{ID};

	if ($char->{party}{users}{$ID}) {
		$char->{party}{users}{$ID}{hp} = $args->{hp};
		$char->{party}{users}{$ID}{hp_max} = $args->{hp_max};
	}
}

sub party_invite {
	my ($self, $args) = @_;
	message TF("Incoming Request to join party '%s'\n", bytesToString($args->{name}));
	$incomingParty{ID} = $args->{ID};
	$incomingParty{ACK} = $args->{switch} eq '02C6' ? '02C7' : '00FF';
	$timeout{ai_partyAutoDeny}{time} = time;
}

use constant {
  ANSWER_ALREADY_OTHERGROUPM => 0x0,
  ANSWER_JOIN_REFUSE => 0x1,
  ANSWER_JOIN_ACCEPT => 0x2,
  ANSWER_MEMBER_OVERSIZE => 0x3,
  ANSWER_DUPLICATE => 0x4,
  ANSWER_JOINMSG_REFUSE => 0x5,
  ANSWER_UNKNOWN_ERROR => 0x6,
  ANSWER_UNKNOWN_CHARACTER => 0x7,
  ANSWER_INVALID_MAPPROPERTY => 0x8,
};

sub party_invite_result {
	my ($self, $args) = @_;
	my $name = bytesToString($args->{name});
	if ($args->{type} == ANSWER_ALREADY_OTHERGROUPM) {
		warning TF("Join request failed: %s is already in a party\n", $name);
	} elsif ($args->{type} == ANSWER_JOIN_REFUSE) {
		warning TF("Join request failed: %s denied request\n", $name);
	} elsif ($args->{type} == ANSWER_JOIN_ACCEPT) {
		message TF("%s accepted your request\n", $name), "info";
	} elsif ($args->{type} == ANSWER_MEMBER_OVERSIZE) {
		message T("Join request failed: Party is full.\n"), "info";
	} elsif ($args->{type} == ANSWER_DUPLICATE) {
		message TF("Join request failed: same account of %s allready joined the party.\n", $name), "info";
	} elsif ($args->{type} == ANSWER_JOINMSG_REFUSE) {
		message TF("Join request failed: ANSWER_JOINMSG_REFUSE.\n", $name), "info";
	} elsif ($args->{type} == ANSWER_UNKNOWN_ERROR) {
		message TF("Join request failed: unknown error.\n", $name), "info";
	} elsif ($args->{type} == ANSWER_UNKNOWN_CHARACTER) {
		message TF("Join request failed: the character is not currently online or does not exist.\n", $name), "info";
	} elsif ($args->{type} == ANSWER_INVALID_MAPPROPERTY) {
		message TF("Join request failed: ANSWER_INVALID_MAPPROPERTY.\n", $name), "info";
	}
}

sub party_join {
	my ($self, $args) = @_;

	return unless changeToInGameState();
	my ($ID, $role, $x, $y, $type, $name, $user, $map) = @{$args}{qw(ID role x y type name user map)};
	$name = bytesToString($name);
	$user = bytesToString($user);

	if (!$char->{party} || !%{$char->{party}} || !$char->{party}{users}{$ID} || !%{$char->{party}{users}{$ID}}) {
		binAdd(\@partyUsersID, $ID) if (binFind(\@partyUsersID, $ID) eq "");
		if ($ID eq $accountID) {
			message TF("You joined party '%s'\n", $name), undef, 1;
			$char->{party} = {};
			Plugins::callHook('packet_partyJoin', { partyName => $name });
		} else {
			message TF("%s joined your party '%s'\n", $user, $name), undef, 1;
		}
	}

	my $actor = $char->{party}{users}{$ID} && %{$char->{party}{users}{$ID}} ? $char->{party}{users}{$ID} : new Actor::Party;

	$actor->{admin} = !$role;
	delete $actor->{statuses} unless $actor->{online} = !$type;
	$actor->{pos}{x} = $x;
	$actor->{pos}{y} = $y;
	$actor->{map} = $map;
	$actor->{name} = $user;
	$actor->{ID} = $ID;
	$char->{party}{users}{$ID} = $actor;

=pod
	$char->{party}{users}{$ID} = new Actor::Party if ($char->{party}{users}{$ID}{name});
	$char->{party}{users}{$ID}{admin} = !$role;
	if ($type == 0) {
		$char->{party}{users}{$ID}{online} = 1;
	} elsif ($type == 1) {
		$char->{party}{users}{$ID}{online} = 0;
		delete $char->{party}{users}{$ID}{statuses};
	}
=cut
	$char->{party}{name} = $name;
=pod
	$char->{party}{users}{$ID}{pos}{x} = $x;
	$char->{party}{users}{$ID}{pos}{y} = $y;
	$char->{party}{users}{$ID}{map} = $map;
	$char->{party}{users}{$ID}{name} = $user;
	$char->{party}{users}{$ID}->{ID} = $ID;
=cut

	if (($config{partyAutoShare} || $config{partyAutoShareItem} || $config{partyAutoShareItemDiv}) && $char->{party} && %{$char->{party}} && $char->{party}{users}{$accountID}{admin}) {
		$messageSender->sendPartyOption($config{partyAutoShare}, $config{partyAutoShareItem}, $config{partyAutoShareItemDiv});

	}
}

use constant {
	GROUPMEMBER_DELETE_LEAVE => 0x0,
	GROUPMEMBER_DELETE_EXPEL => 0x1,
};

sub party_leave {
	my ($self, $args) = @_;

	my $ID = $args->{ID};
	my $actor = $char->{party}{users}{$ID}; # bytesToString($args->{name})
	delete $char->{party}{users}{$ID};
	binRemove(\@partyUsersID, $ID);
	if ($ID eq $accountID) {
		$actor = $char;
		delete $char->{party};
		undef @partyUsersID;
	}

	if ($args->{result} == GROUPMEMBER_DELETE_LEAVE) {
		message TF("%s left the party\n", $actor);
	} elsif ($args->{result} == GROUPMEMBER_DELETE_EXPEL) {
		message TF("%s left the party (kicked)\n", $actor);
	} else {
		message TF("%s left the party (unknown reason: %d)\n", $actor, $args->{result});
	}
}

sub party_location {
	my ($self, $args) = @_;

	my $ID = $args->{ID};

	if ($char->{party}{users}{$ID}) {
		$char->{party}{users}{$ID}{pos}{x} = $args->{x};
		$char->{party}{users}{$ID}{pos}{y} = $args->{y};
		$char->{party}{users}{$ID}{online} = 1;
		debug "Party member location: $char->{party}{users}{$ID}{name} - $args->{x}, $args->{y}\n", "parseMsg";
	}
}

sub party_organize_result {
	my ($self, $args) = @_;

	unless ($args->{fail}) {
		$char->{party}{users}{$accountID}{admin} = 1 if $char->{party}{users}{$accountID};
	} elsif ($args->{fail} == 1) {
		warning T("Can't organize party - party name exists\n");
	} elsif ($args->{fail} == 2) {
		warning T("Can't organize party - you are already in a party\n");
	} elsif ($args->{fail} == 3) {
		warning T("Can't organize party - not allowed in current map\n");
	} else {
		warning TF("Can't organize party - unknown (%d)\n", $args->{fail});
	}
}

sub party_users_info {
	my ($self, $args) = @_;
	return unless changeToInGameState();

	my $msg;
	$self->decrypt(\$msg, substr($args->{RAW_MSG}, 28));
	$msg = substr($args->{RAW_MSG}, 0, 28).$msg;
	$char->{party}{name} = bytesToString($args->{party_name});

	for (my $i = 28; $i < $args->{RAW_MSG_SIZE}; $i += 46) {
		my $ID = substr($msg, $i, 4);
		if (binFind(\@partyUsersID, $ID) eq "") {
			binAdd(\@partyUsersID, $ID);
		}
		$char->{party}{users}{$ID} = new Actor::Party();
		$char->{party}{users}{$ID}{name} = bytesToString(unpack("Z24", substr($msg, $i + 4, 24)));
		message TF("Party Member: %s\n", $char->{party}{users}{$ID}{name}), "party", 1;
		$char->{party}{users}{$ID}{map} = unpack("Z16", substr($msg, $i + 28, 16));
		$char->{party}{users}{$ID}{admin} = !(unpack("C1", substr($msg, $i + 44, 1)));
		$char->{party}{users}{$ID}{online} = !(unpack("C1",substr($msg, $i + 45, 1)));
		$char->{party}{users}{$ID}->{ID} = $ID;
	}

	if (($config{partyAutoShare} || $config{partyAutoShareItem} || $config{partyAutoShareItemDiv}) && $char->{party} && %{$char->{party}} && $char->{party}{users}{$accountID}{admin}) {
		$messageSender->sendPartyOption($config{partyAutoShare}, $config{partyAutoShareItem}, $config{partyAutoShareItemDiv});


	}

}

sub pet_capture_result {
	my ($self, $args) = @_;

	if ($args->{success}) {
		message T("Pet capture success\n"), "info";
	} else {
		message T("Pet capture failed\n"), "info";
	}
}

sub pet_emotion {
	my ($self, $args) = @_;

	my ($ID, $type) = ($args->{ID}, $args->{type});

	my $emote = $emotions_lut{$type}{display} || "/e$type";
	if ($pets{$ID}) {
		message $pets{$ID}->name . " : $emote\n", "emotion";
	}
}

sub pet_food {
	my ($self, $args) = @_;
	if ($args->{success}) {
		message TF("Fed pet with %s\n", itemNameSimple($args->{foodID})), "pet";
	} else {
		error TF("Failed to feed pet with %s: no food in inventory.\n", itemNameSimple($args->{foodID}));
	}
}

sub pet_info {
	my ($self, $args) = @_;
	$pet{name} = bytesToString($args->{name});
	$pet{renameflag} = $args->{renameflag};
	$pet{level} = $args->{level};
	$pet{hungry} = $args->{hungry};
	$pet{friendly} = $args->{friendly};
	$pet{accessory} = $args->{accessory};
	$pet{type} = $args->{type} if (exists $args->{type});
	debug "Pet status: name=$pet{name} name_set=". ($pet{renameflag} ? 'yes' : 'no') ." level=$pet{level} hungry=$pet{hungry} intimacy=$pet{friendly} accessory=".itemNameSimple($pet{accessory})." type=".($pet{type}||"N/A")."\n", "pet";
}

sub pet_info2 {
	my ($self, $args) = @_;
	my ($type, $ID, $value) = @{$args}{qw(type ID value)};

	# receive information about your pet

	# related freya functions: clif_pet_equip clif_pet_performance clif_send_petdata

	# these should never happen, pets should spawn like normal actors (at least on Freya)
	# this isn't even very useful, do we want random pets with no location info?
	#if (!$pets{$ID} || !%{$pets{$ID}}) {
	#	binAdd(\@petsID, $ID);
	#	$pets{$ID} = {};
	#	%{$pets{$ID}} = %{$monsters{$ID}} if ($monsters{$ID} && %{$monsters{$ID}});
	#	$pets{$ID}{'name_given'} = "Unknown";
	#	$pets{$ID}{'binID'} = binFind(\@petsID, $ID);
	#	debug "Pet spawned (unusually): $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n", "parseMsg";
	#}
	#if ($monsters{$ID}) {
	#	if (%{$monsters{$ID}}) {
	#		objectRemoved('monster', $ID, $monsters{$ID});
	#	}
	#	# always clear these in case
	#	binRemove(\@monstersID, $ID);
	#	delete $monsters{$ID};
	#}

	if ($type == 0) {
		# You own no pet.
		undef $pet{ID};

	} elsif ($type == 1) {
		$pet{friendly} = $value;
		debug "Pet friendly: $value\n";

	} elsif ($type == 2) {
		$pet{hungry} = $value;
		debug "Pet hungry: $value\n";

	} elsif ($type == 3) {
		# accessory info for any pet in range
		#debug "Pet accessory info: $value\n";

	} elsif ($type == 4) {
		# performance info for any pet in range
		#debug "Pet performance info: $value\n";

	} elsif ($type == 5) {
		# You own pet with this ID
		$pet{ID} = $ID;
	}
}

sub player_equipment {
	my ($self, $args) = @_;

	my ($sourceID, $type, $ID1, $ID2) = @{$args}{qw(sourceID type ID1 ID2)};
	my $player = ($sourceID ne $accountID)? $playersList->getByID($sourceID) : $char;
	return unless $player;

	if ($type == 0) {
		# Player changed job
		$player->{jobID} = $ID1;

	} elsif ($type == 2) {
		if ($ID1 ne $player->{weapon}) {
			message TF("%s changed Weapon to %s\n", $player, itemName({nameID => $ID1})), "parseMsg_statuslook", 2;
			$player->{weapon} = $ID1;
		}
		if ($ID2 ne $player->{shield}) {
			message TF("%s changed Shield to %s\n", $player, itemName({nameID => $ID2})), "parseMsg_statuslook", 2;
			$player->{shield} = $ID2;
		}
	} elsif ($type == 3) {
		$player->{headgear}{low} = $ID1;
	} elsif ($type == 4) {
		$player->{headgear}{top} = $ID1;
	} elsif ($type == 5) {
		$player->{headgear}{mid} = $ID1;
	} elsif ($type == 9) {
		if ($player->{shoes} && $ID1 ne $player->{shoes}) {
			message TF("%s changed Shoes to: %s\n", $player, itemName({nameID => $ID1})), "parseMsg_statuslook", 2;
		}
		$player->{shoes} = $ID1;
	}
}

sub public_chat {
	my ($self, $args) = @_;
	# Type: String
	my $message = bytesToString($args->{message});
	my ($chatMsgUser, $chatMsg); # Type: String
	my ($actor, $dist);

	if ($message =~ / : /) {
		($chatMsgUser, $chatMsg) = split / : /, $message, 2;
		$chatMsgUser =~ s/ $//;
		$chatMsg =~ s/^ //;
		stripLanguageCode(\$chatMsg);

		$actor = Actor::get($args->{ID});
		$dist = "unknown";
		if (!$actor->isa('Actor::Unknown')) {
			$dist = distance($char->{pos_to}, $actor->{pos_to});
			$dist = sprintf("%.1f", $dist) if ($dist =~ /\./);
		}
		$message = "$chatMsgUser ($actor->{binID}): $chatMsg";

	} else {
		$chatMsg = $message;
	}

	my $position = sprintf("[%s %d, %d]",
		$field ? $field->baseName : T("Unknown field,"),
		$char->{pos_to}{x}, $char->{pos_to}{y});
	my $distInfo;
	if ($actor) {
		$position .= sprintf(" [%d, %d] [dist=%s] (%d)",
			$actor->{pos_to}{x}, $actor->{pos_to}{y},
			$dist, $actor->{nameID});
		$distInfo = "[dist=$dist] ";
	}

	# this code autovivifies $actor->{pos_to} but it doesnt matter
	chatLog("c", "$position $message\n") if ($config{logChat});
	message TF("%s%s\n", $distInfo, $message), "publicchat";

	Plugins::callHook('packet_pubMsg', {
		pubID => $args->{ID},
		pubMsgUser => $chatMsgUser,
		pubMsg => $chatMsg,
		MsgUser => $chatMsgUser,
		Msg => $chatMsg
	});
}

sub private_message {
	my ($self, $args) = @_;
	my ($newmsg, $msg); # Type: Bytes

	return unless changeToInGameState();

	# Type: String
	my $privMsgUser = bytesToString($args->{privMsgUser});
	my $privMsg = bytesToString($args->{privMsg});

	if ($privMsgUser ne "" && binFind(\@privMsgUsers, $privMsgUser) eq "") {
		push @privMsgUsers, $privMsgUser;
		Plugins::callHook('parseMsg/addPrivMsgUser', {
			user => $privMsgUser,
			msg => $privMsg,
			userList => \@privMsgUsers
		});
	}

	stripLanguageCode(\$privMsg);
	chatLog("pm", TF("(From: %s) : %s\n", $privMsgUser, $privMsg)) if ($config{'logPrivateChat'});
 	message TF("(From: %s) : %s\n", $privMsgUser, $privMsg), "pm";

	Plugins::callHook('packet_privMsg', {
		privMsgUser => $privMsgUser,
		privMsg => $privMsg,
		MsgUser => $privMsgUser,
		Msg => $privMsg
	});

	if ($config{dcOnPM} && $AI == AI::AUTO) {
		chatLog("k", T("*** You were PM'd, auto disconnect! ***\n"));
		message T("Disconnecting on PM!\n");
		quit();
	}
}

sub private_message_sent {
	my ($self, $args) = @_;
	if ($args->{type} == 0) {
 		message TF("(To %s) : %s\n", $lastpm[0]{'user'}, $lastpm[0]{'msg'}), "pm/sent";
		chatLog("pm", "(To: $lastpm[0]{user}) : $lastpm[0]{msg}\n") if ($config{'logPrivateChat'});

		Plugins::callHook('packet_sentPM', {
			to => $lastpm[0]{user},
			msg => $lastpm[0]{msg}
		});

	} elsif ($args->{type} == 1) {
		warning TF("%s is not online\n", $lastpm[0]{user});
	} elsif ($args->{type} == 2) {
		warning TF("Player %s ignored your message\n", $lastpm[0]{user});
	} else {
		warning TF("Player %s doesn't want to receive messages\n", $lastpm[0]{user});
	}
	shift @lastpm;
}

sub received_characters {
	return if ($net->getState() == Network::IN_GAME);
	my ($self, $args) = @_;
	$net->setState(Network::CONNECTED_TO_LOGIN_SERVER);
	$charSvrSet{total_slot} = $args->{total_slot} if (exists $args->{total_slot});
	$charSvrSet{normal_slot} = $args->{normal_slot} if (exists $args->{normal_slot});
	$charSvrSet{premium_slot} = $args->{premium_slot} if (exists $args->{premium_slot});
	$charSvrSet{billing_slot} = $args->{billing_slot} if (exists $args->{billing_slot});
	$charSvrSet{producible_slot} = $args->{producible_slot} if (exists $args->{producible_slot});
	$charSvrSet{valid_slot} = $args->{valid_slot} if (exists $args->{valid_slot});
	undef $conState_tries;

	Plugins::callHook('parseMsg/recvChars', $args->{options});
	if ($args->{options} && exists $args->{options}{charServer}) {
		$charServer = $args->{options}{charServer};
	} else {
		$charServer = $net->serverPeerHost . ":" . $net->serverPeerPort;
	}

	# PACKET_HC_ACCEPT_ENTER2 contains no character info
	return unless exists $args->{charInfo};

	my $blockSize = $self->received_characters_blockSize();
	for (my $i = $args->{RAW_MSG_SIZE} % $blockSize; $i < $args->{RAW_MSG_SIZE}; $i += $blockSize) {
		#exp display bugfix - chobit andy 20030129
		my $unpack_string = $self->received_characters_unpackString;
		# TODO: What would be the $unknown ?
		my ($cID,$exp,$zeny,$jobExp,$jobLevel, $opt1, $opt2, $option, $stance, $manner, $statpt,
			$hp,$maxHp,$sp,$maxSp, $walkspeed, $jobId,$hairstyle, $weapon, $level, $skillpt,$headLow, $shield,$headTop,$headMid,$hairColor,
			$clothesColor,$name,$str,$agi,$vit,$int,$dex,$luk,$slot, $rename, $unknown, $mapname, $deleteDate) =
			unpack($unpack_string, substr($args->{RAW_MSG}, $i));
		$chars[$slot] = new Actor::You;

		# Re-use existing $char object instead of re-creating it.
		# Required because existing AI sequences (eg, route) keep a reference to $char.
		$chars[$slot] = $char if $char && $char->{ID} eq $accountID && $char->{charID} eq $cID;

		$chars[$slot]{ID} = $accountID;
		$chars[$slot]{charID} = $cID;
		$chars[$slot]{exp} = $exp;
		$chars[$slot]{zeny} = $zeny;
		$chars[$slot]{exp_job} = $jobExp;
		$chars[$slot]{lv_job} = $jobLevel;
		$chars[$slot]{hp} = $hp;
		$chars[$slot]{hp_max} = $maxHp;
		$chars[$slot]{sp} = $sp;
		$chars[$slot]{sp_max} = $maxSp;
		$chars[$slot]{jobID} = $jobId;
		$chars[$slot]{hair_style} = $hairstyle;
		$chars[$slot]{lv} = $level;
		$chars[$slot]{headgear}{low} = $headLow;
		$chars[$slot]{headgear}{top} = $headTop;
		$chars[$slot]{headgear}{mid} = $headMid;
		$chars[$slot]{hair_color} = $hairColor;
		$chars[$slot]{clothes_color} = $clothesColor;
		$chars[$slot]{name} = $name;
		$chars[$slot]{str} = $str;
		$chars[$slot]{agi} = $agi;
		$chars[$slot]{vit} = $vit;
		$chars[$slot]{int} = $int;
		$chars[$slot]{dex} = $dex;
		$chars[$slot]{luk} = $luk;
		$chars[$slot]{sex} = $accountSex2;

		$chars[$slot]{deleteDate} = getFormattedDate($deleteDate) if ($deleteDate);
		$chars[$slot]{nameID} = unpack("V", $chars[$slot]{ID});
		$chars[$slot]{name} = bytesToString($chars[$slot]{name});
	}

	my $nChars = 0;
	foreach (@chars) { $nChars++ if($_); } 

	# FIXME better support for multiple received_characters packets
	if ($args->{switch} eq '099D' && $args->{RAW_MSG_SIZE} >= ($blockSize * 3)) {
		$net->setState(1.5);
		if ($nChars < $charSvrSet{normal_slot} && $config{'XKore'} ne '1') {
			$messageSender->sendToServer($messageSender->reconstruct({switch => 'sync_received_characters'}));
		}
		return;
	}

	message T("Received characters from Character Server\n"), "connection";

	# gradeA says it's supposed to send this packet here, but
	# it doesn't work...
	# 30 Dec 2005: it didn't work before because it wasn't sending the accountiD -> fixed (kaliwanagan)
	return if ($args->{switch} eq '099D' && $config{serverType} eq 'twRO');
	if (charSelectScreen(1) == 1) {
		$firstLoginMap = 1;
		$startingzeny = $chars[$config{'char'}]{'zeny'} unless defined $startingzeny;
		$sentWelcomeMessage = 1;
	}
}

sub received_character_ID_and_Map {
	my ($self, $args) = @_;
	message T("Received character ID and Map IP from Character Server\n"), "connection";
	$net->setState(4);
	undef $conState_tries;
	$charID = $args->{charID};

	if ($net->version == 1) {
		undef $masterServer;
		$masterServer = $masterServers{$config{master}} if ($config{master} ne "");
	}

	my ($map) = $args->{mapName} =~ /([\s\S]*)\./; # cut off .gat
	my $map_noinstance;
	($map_noinstance, undef) = Field::nameToBaseName(undef, $map); # Hack to clean up InstanceID
	if (!$field || $map ne $field->name()) {
		eval {
			$field = new Field(name => $map);
		};
		if (my $e = caught('FileNotFoundException', 'IOException')) {
			error TF("Cannot load field %s: %s\n", $map_noinstance, $e);
			undef $field;
		} elsif ($@) {
			die $@;
		}
	}

	$map_ip = makeIP($args->{mapIP});
	$map_ip = $masterServer->{ip} if ($masterServer && $masterServer->{private});
	$map_port = $args->{mapPort};
	message TF("----------Game Info----------\n" .
		"Char ID: %s (%s)\n" .
		"MAP Name: %s\n" .
		"MAP IP: %s\n" .
		"MAP Port: %s\n" .
		"-----------------------------\n", getHex($charID), unpack("V1", $charID),
		$args->{mapName}, $map_ip, $map_port), "connection";
	checkAllowedMap($map_noinstance);
	message(T("Closing connection to Character Server\n"), "connection") unless ($net->version == 1);
	$net->serverDisconnect(1);
	main::initStatVars();
}

sub received_sync {
	return unless changeToInGameState();
	debug "Received Sync\n", 'parseMsg', 2;
	$timeout{'play'}{'time'} = time;
}

sub refine_result {
	my ($self, $args) = @_;
	if ($args->{fail} == 0) {
		message TF("You successfully refined a weapon (ID %s)!\n", $args->{nameID});
	} elsif ($args->{fail} == 1) {
		message TF("You failed to refine a weapon (ID %s)!\n", $args->{nameID});
	} elsif ($args->{fail} == 2) {
		message TF("You successfully made a potion (ID %s)!\n", $args->{nameID});
	} elsif ($args->{fail} == 3) {
		message TF("You failed to make a potion (ID %s)!\n", $args->{nameID});
	} else {
		message TF("You tried to refine a weapon (ID %s); result: unknown %s\n", $args->{nameID}, $args->{fail});
	}
}

sub blacksmith_points {
	my ($self, $args) = @_;
	message TF("[POINT] Blacksmist Ranking Point is increasing by %s. Now, The total is %s points.\n", $args->{points}, $args->{total}, "list");
}

sub alchemist_point {
	my ($self, $args) = @_;
	message TF("[POINT] Alchemist Ranking Point is increasing by %s. Now, The total is %s points.\n", $args->{points}, $args->{total}, "list");
}

sub repair_list {
	my ($self, $args) = @_;
	my $msg = T("--------Repair List--------\n");
	undef $repairList;
	for (my $i = 4; $i < $args->{RAW_MSG_SIZE}; $i += 13) {
		my $listID = unpack("C1", substr($args->{RAW_MSG}, $i+12, 1));
		$repairList->[$listID]->{index} = unpack("v1", substr($args->{RAW_MSG}, $i, 2));
		$repairList->[$listID]->{nameID} = unpack("v1", substr($args->{RAW_MSG}, $i+2, 2));
		# what are these  two?
		$repairList->[$listID]->{status} = unpack("V1", substr($args->{RAW_MSG}, $i+4, 4));
		$repairList->[$listID]->{status2} = unpack("V1", substr($args->{RAW_MSG}, $i+8, 4));
		$repairList->[$listID]->{listID} = $listID;

		my $name = itemNameSimple($repairList->[$listID]->{nameID});
		$msg .= "$listID $name\n";
	}
	$msg .= "---------------------------\n";
	message $msg, "list";
}

sub repair_result {
	my ($self, $args) = @_;
	undef $repairList;
	my $itemName = itemNameSimple($args->{nameID});
	if ($args->{flag}) {
		message TF("Repair of %s failed.\n", $itemName);
	} else {
		message TF("Successfully repaired %s.\n", $itemName);
	}
}

sub resurrection {
	my ($self, $args) = @_;

	my $targetID = $args->{targetID};
	my $player = $playersList->getByID($targetID);
	my $type = $args->{type};

	if ($targetID eq $accountID) {
		message T("You have been resurrected\n"), "info";
		undef $char->{'dead'};
		undef $char->{'dead_time'};
		$char->{'resurrected'} = 1;

	} else {
		if ($player) {
			undef $player->{'dead'};
			$player->{deltaHp} = 0;
		}
		message TF("%s has been resurrected\n", getActorName($targetID)), "info";
	}
}

sub secure_login_key {
	my ($self, $args) = @_;
	$secureLoginKey = $args->{secure_key};
	debug sprintf("Secure login key: %s\n", getHex($args->{secure_key})), 'connection';
}

sub self_chat {
	my ($self, $args) = @_;
	my ($message, $chatMsgUser, $chatMsg); # Type: String

	$message = bytesToString($args->{message});

	($chatMsgUser, $chatMsg) = $message =~ /([\s\S]*?) : ([\s\S]*)/;
	# Note: $chatMsgUser/Msg may be undefined. This is the case on
	# eAthena servers: it uses this packet for non-chat server messages.

	if (defined $chatMsgUser) {
		stripLanguageCode(\$chatMsg);
		$message = $chatMsgUser . " : " . $chatMsg;
	}

	chatLog("c", "$message\n") if ($config{'logChat'});
	message "$message\n", "selfchat";

	Plugins::callHook('packet_selfChat', {
		user => $chatMsgUser,
		msg => $chatMsg
	});
}

sub sync_request {
	my ($self, $args) = @_;

	# 0187 - long ID
	# I'm not sure what this is. In inRO this seems to have something
	# to do with logging into the game server, while on
	# oRO it has got something to do with the sync packet.
	if ($masterServer->{serverType} == 1) {
		my $ID = $args->{ID};
		if ($ID == $accountID) {
			$timeout{ai_sync}{time} = time;
			$messageSender->sendSync() unless ($net->clientAlive);
			debug "Sync packet requested\n", "connection";
		} else {
			warning T("Sync packet requested for wrong ID\n");
		}
	}
}

sub taekwon_rank {
	my ($self, $args) = @_;
	message T("TaeKwon Mission Rank : ".$args->{rank}."\n"), "info";
}

sub gospel_buff_aligned {
	my ($self, $args) = @_;
	my $status = unpack("V1", $args->{ID});

	if ($status == 21) {
     		message T("All abnormal status effects have been removed.\n"), "info";
	} elsif ($status == 22) {
     		message T("You will be immune to abnormal status effects for the next minute.\n"), "info";
	} elsif ($status == 23) {
     		message T("Your Max HP will stay increased for the next minute.\n"), "info";
	} elsif ($status == 24) {
     		message T("Your Max SP will stay increased for the next minute.\n"), "info";
	} elsif ($status == 25) {
     		message T("All of your Stats will stay increased for the next minute.\n"), "info";
	} elsif ($status == 28) {
     		message T("Your weapon will remain blessed with Holy power for the next minute.\n"), "info";
	} elsif ($status == 29) {
     		message T("Your armor will remain blessed with Holy power for the next minute.\n"), "info";
	} elsif ($status == 30) {
     		message T("Your Defense will stay increased for the next 10 seconds.\n"), "info";
	} elsif ($status == 31) {
     		message T("Your Attack strength will stay increased for the next minute.\n"), "info";
	} elsif ($status == 32) {
     		message T("Your Accuracy and Flee Rate will stay increased for the next minute.\n"), "info";
	} else {
     		#message T("Unknown buff from Gospel: " . $status . "\n"), "info";
	}
}

sub no_teleport {
	my ($self, $args) = @_;
	my $fail = $args->{fail};

	if ($fail == 0) {
		error T("Unavailable Area To Teleport\n");
		AI::clear(qw/teleport/);
	} elsif ($fail == 1) {
		error T("Unavailable Area To Memo\n");
	} else {
		error TF("Unavailable Area To Teleport (fail code %s)\n", $fail);
	}
}

sub map_property {
	my ($self, $args) = @_;

	if($config{'status_mapProperty'}){
		$char->setStatus(@$_) for map {[$_->[1], $args->{type} == $_->[0]]}
		grep { $args->{type} == $_->[0] || $char->{statuses}{$_->[1]} }
		map {[$_, defined $mapPropertyTypeHandle{$_} ? $mapPropertyTypeHandle{$_} : "UNKNOWN_MAPPROPERTY_TYPE_$_"]}
		1 .. List::Util::max $args->{type}, keys %mapPropertyTypeHandle;

		if ($args->{info_table}) {
			my @info_table = unpack 'C*', $args->{info_table};
			$char->setStatus(@$_) for map {[
				defined $mapPropertyInfoHandle{$_} ? $mapPropertyInfoHandle{$_} : "UNKNOWN_MAPPROPERTY_INFO_$_",
				$info_table[$_],
			]} 0 .. @info_table-1;
		}
	}
	$pvp = {1 => 1, 3 => 2}->{$args->{type}};
	if ($pvp) {
		Plugins::callHook('pvp_mode', {
			pvp => $pvp # 1 PvP, 2 GvG
		});
	}
}

sub map_property2 {
	my ($self, $args) = @_;

	if($config{'status_mapType'}){
		$char->setStatus(@$_) for map {[$_->[1], $args->{type} == $_->[0]]}
		grep { $args->{type} == $_->[0] || $char->{statuses}{$_->[1]} }
		map {[$_, defined $mapTypeHandle{$_} ? $mapTypeHandle{$_} : "UNKNOWN_MAPTYPE_$_"]}
		0 .. List::Util::max $args->{type}, keys %mapTypeHandle;
	}
	$pvp = {6 => 1, 8 => 2, 19 => 3}->{$args->{type}};
	if ($pvp) {
		Plugins::callHook('pvp_mode', {
			pvp => $pvp # 1 PvP, 2 GvG, 3 Battleground
		});
	}
}

sub pvp_rank {
	my ($self, $args) = @_;

	# 9A 01 - 14 bytes long
	my $ID = $args->{ID};
	my $rank = $args->{rank};
	my $num = $args->{num};;
	if ($rank != $ai_v{temp}{pvp_rank} ||
	    $num != $ai_v{temp}{pvp_num}) {
		$ai_v{temp}{pvp_rank} = $rank;
		$ai_v{temp}{pvp_num} = $num;
		if ($ai_v{temp}{pvp}) {
			message TF("Your PvP rank is: %s/%s\n", $rank, $num), "map_event";
		}
	}
}

sub sense_result {
	my ($self, $args) = @_;
	# nameID level size hp def race mdef element ice earth fire wind poison holy dark spirit undead
	my @race_lut = qw(Formless Undead Beast Plant Insect Fish Demon Demi-Human Angel Dragon Boss Non-Boss);
	my @size_lut = qw(Small Medium Large);
	message TF("=====================Sense========================\n" .
			"Monster: %-16s Level: %-12s\n" .
			"Size:    %-16s Race:  %-12s\n" .
			"Def:     %-16s MDef:  %-12s\n" .
			"Element: %-16s HP:    %-12s\n" .
			"=================Damage Modifiers=================\n" .
			"Ice: %-3s     Earth: %-3s  Fire: %-3s  Wind: %-3s\n" .
			"Poison: %-3s  Holy: %-3s   Dark: %-3s  Spirit: %-3s\n" .
			"Undead: %-3s\n" .
			"==================================================\n",
			$monsters_lut{$args->{nameID}}, $args->{level}, $size_lut[$args->{size}], $race_lut[$args->{race}],
			$args->{def}, $args->{mdef}, $elements_lut{$args->{element}}, $args->{hp},
			$args->{ice}, $args->{earth}, $args->{fire}, $args->{wind}, $args->{poison}, $args->{holy}, $args->{dark},
			$args->{spirit}, $args->{undead}), "list";
}

sub shop_sold {
	my ($self, $args) = @_;

	# sold something
	my $number = $args->{number};
	my $amount = $args->{amount};

	$articles[$number]{sold} += $amount;
	my $earned = $amount * $articles[$number]{price};
	$shopEarned += $earned;
	$articles[$number]{quantity} -= $amount;
	my $msg = TF("sold: %s - %s %sz\n", $amount, $articles[$number]{name}, $earned);
	shopLog($msg);
	message($msg, "sold");
	if ($articles[$number]{quantity} < 1) {
		message TF("sold out: %s\n", $articles[$number]{name}), "sold";
		#$articles[$number] = "";
		if (!--$articles){
			message T("Items have been sold out.\n"), "sold";
			closeShop();
		}
	}
}

# TODO:
# Add 'dispose' support
sub skill_cast {
	my ($self, $args) = @_;

	return unless changeToInGameState();
	my $sourceID = $args->{sourceID};
	my $targetID = $args->{targetID};
	my $x = $args->{x};
	my $y = $args->{y};
	my $skillID = $args->{skillID};
	my $type = $args->{type};
	my $wait = $args->{wait};
	my ($dist, %coords);

	# Resolve source and target
	my $source = Actor::get($sourceID);
	my $target = Actor::get($targetID);
	my $verb = $source->verb('are casting', 'is casting');

	Misc::checkValidity("skill_cast part 1");

	my $skill = new Skill(idn => $skillID);
	$source->{casting} = {
		skill => $skill,
		target => $target,
		x => $x,
		y => $y,
		startTime => time,
		castTime => $wait
	};
	# Since we may have a circular reference, weaken this reference
	# to prevent memory leaks.
	Scalar::Util::weaken($source->{casting}{target});

	my $targetString;
	if ($x != 0 || $y != 0) {
		# If $dist is positive we are in range of the attack?
		$coords{x} = $x;
		$coords{y} = $y;
		$dist = judgeSkillArea($skillID) - distance($char->{pos_to}, \%coords);
			$targetString = "location ($x, $y)";
		undef $targetID;
	} else {
		$targetString = $target->nameString($source);
	}

	# Perform trigger actions
	if ($sourceID eq $accountID) {
		$char->{time_cast} = time;
		$char->{time_cast_wait} = $wait / 1000;
		delete $char->{cast_cancelled};
	}
	countCastOn($sourceID, $targetID, $skillID, $x, $y);

	Misc::checkValidity("skill_cast part 2");

	my $domain = ($sourceID eq $accountID) ? "selfSkill" : "skill";
	my $disp = skillCast_string($source, $target, $x, $y, $skill->getName(), $wait, $skillID);
	message $disp, $domain, 1;

	Plugins::callHook('is_casting', {
		sourceID => $sourceID,
		targetID => $targetID,
		source => $source,
		target => $target,
		skillID => $skillID,
		skill => $skill,
		time => $source->{casting}{time},
		castTime => $wait,
		x => $x,
		y => $y
	});

	Misc::checkValidity("skill_cast part 3");

	# Skill Cancel
	my $monster = $monstersList->getByID($sourceID);
	my $control;
	$control = mon_control($monster->name,$monster->{nameID}) if ($monster);
	if ($AI == AI::AUTO && $control->{skillcancel_auto}) {
		if ($targetID eq $accountID || $dist > 0 || (AI::action eq "attack" && AI::args->{ID} ne $sourceID)) {
			message TF("Monster Skill - switch Target to : %s (%d)\n", $monster->name, $monster->{binID});
			$char->sendAttackStop;
			AI::dequeue;
			attack($sourceID);
		}

		# Skill area casting -> running to monster's back
		my $ID;
		if ($dist > 0 && AI::action eq "attack" && ($ID = AI::args->{ID}) && (my $monster2 = $monstersList->getByID($ID))) {
			# Calculate X axis
			if ($char->{pos_to}{x} - $monster2->{pos_to}{x} < 0) {
				$coords{x} = $monster2->{pos_to}{x} + 3;
			} else {
				$coords{x} = $monster2->{pos_to}{x} - 3;
			}
			# Calculate Y axis
			if ($char->{pos_to}{y} - $monster2->{pos_to}{y} < 0) {
				$coords{y} = $monster2->{pos_to}{y} + 3;
			} else {
				$coords{y} = $monster2->{pos_to}{y} - 3;
			}

			my (%vec, %pos);
			getVector(\%vec, \%coords, $char->{pos_to});
			moveAlongVector(\%pos, $char->{pos_to}, \%vec, distance($char->{pos_to}, \%coords));
			ai_route($field->baseName, $pos{x}, $pos{y},
				maxRouteDistance => $config{attackMaxRouteDistance},
				maxRouteTime => $config{attackMaxRouteTime},
				noMapRoute => 1);
			message TF("Avoid casting Skill - switch position to : %s,%s\n", $pos{x}, $pos{y}), 1;
		}

		Misc::checkValidity("skill_cast part 4");
	}
}

# TODO: use $args->{type} if present
sub skill_update {
	my ($self, $args) = @_;

	my ($ID, $lv, $sp, $range, $up) = ($args->{skillID}, $args->{lv}, $args->{sp}, $args->{range}, $args->{up});

	my $skill = new Skill(idn => $ID);
	my $handle = $skill->getHandle();
	my $name = $skill->getName();
	$char->{skills}{$handle}{lv} = $lv;
	$char->{skills}{$handle}{sp} = $sp;
	$char->{skills}{$handle}{range} = $range;
	$char->{skills}{$handle}{up} = $up;

	Skill::DynamicInfo::add($ID, $handle, $lv, $sp, $range, $skill->getTargetType(), Skill::OWNER_CHAR);

	Plugins::callHook('packet_charSkills', {
		ID => $ID,
		handle => $handle,
		level => $lv,
		upgradable => $up,
	});

	debug "Skill $name: $lv\n", "parseMsg";
}

sub skill_use {
	my ($self, $args) = @_;
	return unless changeToInGameState();

	if (my $spell = $spells{$args->{sourceID}}) {
		# Resolve source of area attack skill
		$args->{sourceID} = $spell->{sourceID};
	}

	my $source = Actor::get($args->{sourceID});
	my $target = Actor::get($args->{targetID});
	$args->{source} = $source;
	$args->{target} = $target;
	delete $source->{casting};

	# Perform trigger actions
	if ($args->{switch} eq "0114") {
		$args->{damage} = intToSignedShort($args->{damage});
	} else {
		$args->{damage} = intToSignedInt($args->{damage});
	}
	updateDamageTables($args->{sourceID}, $args->{targetID}, $args->{damage}) if ($args->{damage} != -30000);
	# 反击斩优化
	if ($args->{skillID} != 2028) {
		setSkillUseTimer($args->{skillID}, $args->{targetID}) if (
		$args->{sourceID} eq $accountID
		or $char->{slaves} && $char->{slaves}{$args->{sourceID}}
		);
	}
	setPartySkillTimer($args->{skillID}, $args->{targetID}) if (
		$args->{sourceID} eq $accountID
		or $char->{slaves} && $char->{slaves}{$args->{sourceID}}
		or $args->{sourceID} eq $args->{targetID} # wtf?
	);
	countCastOn($args->{sourceID}, $args->{targetID}, $args->{skillID});

	# Resolve source and target names
	my $skill = new Skill(idn => $args->{skillID});
	$args->{skill} = $skill;
	my $disp = skillUse_string($source, $target, $skill->getName(), $args->{damage},
		$args->{level}, ($args->{src_speed}), $args->{skillID});

	if ($args->{damage} != -30000 &&
	    $args->{sourceID} eq $accountID &&
		$args->{targetID} ne $accountID) {
		calcStat($args->{damage});
	}

	my $domain = ($args->{sourceID} eq $accountID) ? "selfSkill" : "skill";

	if ($args->{damage} == 0) {
		$domain = "attackMonMiss" if (($args->{sourceID} eq $accountID && $args->{targetID} ne $accountID) || ($char->{homunculus} && $args->{sourceID} eq $char->{homunculus}{ID} && $args->{targetID} ne $char->{homunculus}{ID}));
		$domain = "attackedMiss" if (($args->{sourceID} ne $accountID && $args->{targetID} eq $accountID) || ($char->{homunculus} && $args->{sourceID} ne $char->{homunculus}{ID} && $args->{targetID} eq $char->{homunculus}{ID}));

	} elsif ($args->{damage} != -30000) {
		$domain = "attackMon" if (($args->{sourceID} eq $accountID && $args->{targetID} ne $accountID) || ($char->{homunculus} && $args->{sourceID} eq $char->{homunculus}{ID} && $args->{targetID} ne $char->{homunculus}{ID}));
		$domain = "attacked" if (($args->{sourceID} ne $accountID && $args->{targetID} eq $accountID) || ($char->{homunculus} && $args->{sourceID} ne $char->{homunculus}{ID} && $args->{targetID} eq $char->{homunculus}{ID}));
	}

	if ((($args->{sourceID} eq $accountID) && ($args->{targetID} ne $accountID)) ||
	    (($args->{sourceID} ne $accountID) && ($args->{targetID} eq $accountID))) {
		my $status = sprintf("[%3d/%3d] ", $char->hp_percent, $char->sp_percent);
		$disp = $status.$disp;
	} elsif ($char->{slaves} && $char->{slaves}{$args->{sourceID}} && !$char->{slaves}{$args->{targetID}}) {
		my $status = sprintf("[%3d/%3d] ", $char->{slaves}{$args->{sourceID}}{hpPercent}, $char->{slaves}{$args->{sourceID}}{spPercent});
		$disp = $status.$disp;
	} elsif ($char->{slaves} && !$char->{slaves}{$args->{sourceID}} && $char->{slaves}{$args->{targetID}}) {
		my $status = sprintf("[%3d/%3d] ", $char->{slaves}{$args->{targetID}}{hpPercent}, $char->{slaves}{$args->{targetID}}{spPercent});
		$disp = $status.$disp;
	}
	$target->{sitting} = 0 unless $args->{type} == 4 || $args->{type} == 9 || $args->{damage} == 0;

	Plugins::callHook('packet_skilluse', {
			'skillID' => $args->{skillID},
			'sourceID' => $args->{sourceID},
			'targetID' => $args->{targetID},
			'damage' => $args->{damage},
			'amount' => 0,
			'x' => 0,
			'y' => 0,
			'disp' => \$disp
		});
	message $disp, $domain, 1;

	if ($args->{targetID} eq $accountID && $args->{damage} > 0) {
		$damageTaken{$source->{name}}{$skill->getName()} += $args->{damage};
	}
}

sub skill_use_failed {
	my ($self, $args) = @_;

	# skill fail/delay
	my $skillID = $args->{skillID};
	my $btype = $args->{btype};
	my $fail = $args->{fail};
	my $type = $args->{type};

	my %failtype = (
		0 => T('Basic'),
		1 => T('Insufficient SP'),
		2 => T('Insufficient HP'),
		3 => T('No Memo'),
		4 => T('Mid-Delay'),
		5 => T('No Zeny'),
		6 => T('Wrong Weapon Type'),
		7 => T('Red Gem Needed'),
		8 => T('Blue Gem Needed'),
		9 => T('90% Overweight'),
		10 => T('Requirement'),
		13 => T('Need this within the water'),
		19 => T('Full Amulet'),
		29 => T('Must have at least 1% of base XP'),
		83 => T('Location not allowed to create market')
		);

	setSkillUseTimer($skillID) if ($skillID == 50 && $type == 10);
	my $errorMessage;
	if (exists $failtype{$type}) {
		$errorMessage = $failtype{$type};
	} else {
		$errorMessage = 'Unknown error';
	}
	
	warning TF("Skill %s failed: %s (error number %s)\n", Skill->new(idn => $skillID)->getName(), $errorMessage, $type), "skill";
	Plugins::callHook('packet_skillfail', {
		skillID     => $skillID,
		failType    => $type,
		failMessage => $errorMessage
	});
}

sub skill_use_location {
	my ($self, $args) = @_;

	# Skill used on coordinates
	my $skillID = $args->{skillID};
	my $sourceID = $args->{sourceID};
	my $lv = $args->{lv};
	my $x = $args->{x};
	my $y = $args->{y};

	# Perform trigger actions
	setSkillUseTimer($skillID) if $sourceID eq $accountID;

	# Resolve source name
	my $source = Actor::get($sourceID);
	my $skillName = Skill->new(idn => $skillID)->getName();
	my $disp = skillUseLocation_string($source, $skillName, $args);

	# Print skill use message
	my $domain = ($sourceID eq $accountID) ? "selfSkill" : "skill";
	message $disp, $domain;

	Plugins::callHook('packet_skilluse', {
		'skillID' => $skillID,
		'sourceID' => $sourceID,
		'targetID' => '',
		'damage' => 0,
		'amount' => $lv,
		'x' => $x,
		'y' => $y
	});
}
# TODO: a skill can fail, do something with $args->{success} == 0 (this means that the skill failed)
sub skill_used_no_damage {
	my ($self, $args) = @_;
	return unless changeToInGameState();

	# Skill used on target, with no damage done
	if (my $spell = $spells{$args->{sourceID}}) {
		# Resolve source of area attack skill
		$args->{sourceID} = $spell->{sourceID};
	}

	# Perform trigger actions
	# FIXME: setSkillUseTimer does many different things, so which of them "screw up monk comboing"?
	if ($args->{sourceID} eq $accountID && $skillsArea{$args->{skillHandle}} != 2) { # ignore these skills because they screw up monk comboing
		if ($args->{skillID} == 2028) { # 修复武器防御状态 GC_WEAPONBLOCKING
			if ($args->{amount} == 1) {
				setSkillUseTimer($args->{skillID}, $args->{targetID});
			}
		} else {
			setSkillUseTimer($args->{skillID}, $args->{targetID});
		}
	}
	setPartySkillTimer($args->{skillID}, $args->{targetID}) if
			$args->{sourceID} eq $accountID or $args->{sourceID} eq $args->{targetID};
	countCastOn($args->{sourceID}, $args->{targetID}, $args->{skillID});
	if ($args->{sourceID} eq $accountID) {
		if($config{'CNKoreTeam'} && $config{'releaseHack'} && $config{'releaseID'} && $args->{skillID} == 2230) {
			my $msg = pack("C*", 0xAE, 0x01) . pack("v*", $config{'releaseID'});
			$messageSender->sendToServer($msg);
			message "Sent RSB from Recv: $config{'releaseID'}\n";
		}
		my $pos = calcPosition($char);
		$char->{pos_to} = $pos;
		$char->{time_move} = 0;
		$char->{time_move_calc} = 0;
	}

	# Resolve source and target names
	my ($source, $target);
	$target = $args->{target} = Actor::get($args->{targetID});
	$source = $args->{source} = (
		$args->{sourceID} ne "\000\000\000\000"
		? Actor::get($args->{sourceID})
		: $target # for Heal generated by Potion Pitcher sourceID = 0
	);
	my $verb = $source->verb('use', 'uses');

	delete $source->{casting};

	# Print skill use message
	my $extra = "";
	if ($args->{skillID} == 28) {
		$extra = ": $args->{amount} hp gained";
		updateDamageTables($args->{sourceID}, $args->{targetID}, -$args->{amount});
	} elsif ($args->{amount} != 65535) {
		$extra = ": Lv $args->{amount}";
	}

	my $domain = ($args->{sourceID} eq $accountID) ? "selfSkill" : "skill";
	my $skill = $args->{skill} = new Skill(idn => $args->{skillID});
	my $disp = skillUseNoDamage_string($source, $target, $skill->getIDN(), $skill->getName(), $args->{amount}, $args->{skillID});
	message $disp, $domain;

	# Set teleport time
	if ($args->{sourceID} eq $accountID && $skill->getHandle() eq 'AL_TELEPORT') {
		$timeout{ai_teleport_delay}{time} = time;
	}

	if ($AI == AI::AUTO && $config{'autoResponseOnHeal'}) {
		# Handle auto-response on heal
		my $player = $playersList->getByID($args->{sourceID});
		if ($player && ($args->{skillID} == 28 || $args->{skillID} == 29 || $args->{skillID} == 34)) {
			if ($args->{targetID} eq $accountID) {
				chatLog("k", "***$source ".$skill->getName()." on $target$extra***\n");
				sendMessage("pm", getResponse("skillgoodM"), $player->name);
			} elsif ($monstersList->getByID($args->{targetID})) {
				chatLog("k", "***$source ".$skill->getName()." on $target$extra***\n");
				sendMessage("pm", getResponse("skillbadM"), $player->name);
			}
		}
	}
	Plugins::callHook('packet_skilluse', {
		skillID => $args->{skillID},
		sourceID => $args->{sourceID},
		targetID => $args->{targetID},
		damage => 0,
		amount => $args->{amount},
		x => 0,
		y => 0
	});
}

# TODO: move @skillsID to Actor, per-actor {skills}, Skill::DynamicInfo
sub skills_list {
	my ($self, $args) = @_;

	return unless changeToInGameState;

	my ($msg, $newmsg);
	$msg = $args->{RAW_MSG};
	$self->decrypt(\$newmsg, substr $msg, 4);
	$msg = substr ($msg, 0, 4) . $newmsg;

	# TODO: per-actor, if needed at all
	# Skill::DynamicInfo::clear;

	my ($ownerType, $hook, $actor) = @{{
		'010F' => [Skill::OWNER_CHAR, 'packet_charSkills'],
		'0235' => [Skill::OWNER_HOMUN, 'packet_homunSkills', $char->{homunculus}],
		'029D' => [Skill::OWNER_MERC, 'packet_mercSkills', $char->{mercenary}],
	}->{$args->{switch}}};

	my $skillsIDref = $actor ? \@{$actor->{slave_skillsID}} : \@skillsID;
	delete @{$char->{skills}}{@$skillsIDref};
	@$skillsIDref = ();

	# TODO: $actor can be undefined here
	undef @{$actor->{slave_skillsID}};
	for (my $i = 4; $i < $args->{RAW_MSG_SIZE}; $i += 37) {
		my ($ID, $targetType, $lv, $sp, $range, $handle, $up) = unpack 'v1 V1 v3 Z24 C1', substr $msg, $i, 37;
		$handle ||= Skill->new(idn => $ID)->getHandle;

		@{$char->{skills}{$handle}}{qw(ID targetType lv sp range up)} = ($ID, $targetType, $lv, $sp, $range, $up);
		# $char->{skills}{$handle}{lv} = $lv unless $char->{skills}{$handle}{lv};

		binAdd($skillsIDref, $handle) unless defined binFind($skillsIDref, $handle);
		Skill::DynamicInfo::add($ID, $handle, $lv, $sp, $range, $targetType, $ownerType);

		Plugins::callHook($hook, {
			ID => $ID,
			handle => $handle,
			level => $lv,
			upgradable => $up,
		});
	}
}

sub skill_add {
	my ($self, $args) = @_;

	return unless changeToInGameState();
	my $handle = ($args->{name}) ? $args->{name} : Skill->new(idn => $args->{skillID})->getHandle();

	$char->{skills}{$handle}{ID} = $args->{skillID};
	$char->{skills}{$handle}{sp} = $args->{sp};
	$char->{skills}{$handle}{range} = $args->{range};
	$char->{skills}{$handle}{up} = 0;
	$char->{skills}{$handle}{targetType} = $args->{target};
	$char->{skills}{$handle}{lv} = $args->{lv};
	$char->{skills}{$handle}{new} = 1;

	#Fix bug , receive status "Night" 2 time
	binAdd(\@skillsID, $handle) if (binFind(\@skillsID, $handle) eq "");

	Skill::DynamicInfo::add($args->{skillID}, $handle, $args->{lv}, $args->{sp}, $args->{target}, $args->{target}, Skill::OWNER_CHAR);

	Plugins::callHook('packet_charSkills', {
		ID => $args->{skillID},
		handle => $handle,
		level => $args->{lv},
		upgradable => 0,
	});
}

# TODO: merge with stat_info
sub stats_added {
	my ($self, $args) = @_;

	if ($args->{val} == 207) { # client really checks this and not the result field?
		error T("Not enough stat points to add\n");
	} else {
		if ($args->{type} == VAR_STR) {
			$char->{str} = $args->{val};
			debug "Strength: $args->{val}\n", "parseMsg";

		} elsif ($args->{type} == VAR_AGI) {
			$char->{agi} = $args->{val};
			debug "Agility: $args->{val}\n", "parseMsg";

		} elsif ($args->{type} == VAR_VIT) {
			$char->{vit} = $args->{val};
			debug "Vitality: $args->{val}\n", "parseMsg";

		} elsif ($args->{type} == VAR_INT) {
			$char->{int} = $args->{val};
			debug "Intelligence: $args->{val}\n", "parseMsg";

		} elsif ($args->{type} == VAR_DEX) {
			$char->{dex} = $args->{val};
			debug "Dexterity: $args->{val}\n", "parseMsg";

		} elsif ($args->{type} == VAR_LUK) {
			$char->{luk} = $args->{val};
			debug "Luck: $args->{val}\n", "parseMsg";

		} else {
			debug "Something: $args->{val}\n", "parseMsg";
		}
	}
	Plugins::callHook('packet_charStats', {
		type	=> $args->{type},
		val	=> $args->{val},
	});
}

sub stats_info {
	my ($self, $args) = @_;
	return unless changeToInGameState();
	$char->{points_free} = $args->{points_free};
	$char->{str} = $args->{str};
	$char->{points_str} = $args->{points_str};
	$char->{agi} = $args->{agi};
	$char->{points_agi} = $args->{points_agi};
	$char->{vit} = $args->{vit};
	$char->{points_vit} = $args->{points_vit};
	$char->{int} = $args->{int};
	$char->{points_int} = $args->{points_int};
	$char->{dex} = $args->{dex};
	$char->{points_dex} = $args->{points_dex};
	$char->{luk} = $args->{luk};
	$char->{points_luk} = $args->{points_luk};
	$char->{attack} = $args->{attack};
	$char->{attack_bonus} = $args->{attack_bonus};
	$char->{attack_magic_min} = $args->{attack_magic_min};
	$char->{attack_magic_max} = $args->{attack_magic_max};
	$char->{def} = $args->{def};
	$char->{def_bonus} = $args->{def_bonus};
	$char->{def_magic} = $args->{def_magic};
	$char->{def_magic_bonus} = $args->{def_magic_bonus};
	$char->{hit} = $args->{hit};
	$char->{flee} = $args->{flee};
	$char->{flee_bonus} = $args->{flee_bonus};
	$char->{critical} = $args->{critical};
	debug	"Strength: $char->{str} #$char->{points_str}\n"
		."Agility: $char->{agi} #$char->{points_agi}\n"
		."Vitality: $char->{vit} #$char->{points_vit}\n"
		."Intelligence: $char->{int} #$char->{points_int}\n"
		."Dexterity: $char->{dex} #$char->{points_dex}\n"
		."Luck: $char->{luk} #$char->{points_luk}\n"
		."Attack: $char->{attack}\n"
		."Attack Bonus: $char->{attack_bonus}\n"
		."Magic Attack Min: $char->{attack_magic_min}\n"
		."Magic Attack Max: $char->{attack_magic_max}\n"
		."Defense: $char->{def}\n"
		."Defense Bonus: $char->{def_bonus}\n"
		."Magic Defense: $char->{def_magic}\n"
		."Magic Defense Bonus: $char->{def_magic_bonus}\n"
		."Hit: $char->{hit}\n"
		."Flee: $char->{flee}\n"
		."Flee Bonus: $char->{flee_bonus}\n"
		."Critical: $char->{critical}\n"
		."Status Points: $char->{points_free}\n", "parseMsg";
}

our %stat_info_handlers = (
	VAR_SPEED, sub { $_[0]{walk_speed} = $_[1] / 1000 },
	VAR_EXP, sub {
		my ($actor, $value) = @_;

		$actor->{exp_last} = $actor->{exp};
		$actor->{exp} = $value;

		return unless $actor->isa('Actor::You');

		unless ($bExpSwitch) {
			$bExpSwitch = 1;
		} else {
			if ($actor->{exp_last} > $actor->{exp}) {
				$monsterBaseExp = 0;
			} else {
				$monsterBaseExp = $actor->{exp} - $actor->{exp_last};
			}
			$totalBaseExp += $monsterBaseExp;
			if ($bExpSwitch == 1) {
				$totalBaseExp += $monsterBaseExp;
				$bExpSwitch = 2;
			}
		}

		# no VAR_JOBEXP next - no message?
	},
	VAR_JOBEXP, sub {
		my ($actor, $value) = @_;

		$actor->{exp_job_last} = $actor->{exp_job};
		$actor->{exp_job} = $value;

		# TODO: message for all actors
		return unless $actor->isa('Actor::You');
		# TODO: exp report (statistics) - no globals, move to plugin

		if ($jExpSwitch == 0) {
			$jExpSwitch = 1;
		} else {
			if ($char->{exp_job_last} > $char->{exp_job}) {
				$monsterJobExp = 0;
			} else {
				$monsterJobExp = $char->{exp_job} - $char->{exp_job_last};
			}
			$totalJobExp += $monsterJobExp;
			if ($jExpSwitch == 1) {
				$totalJobExp += $monsterJobExp;
				$jExpSwitch = 2;
			}
		}
		my $basePercent = $char->{exp_max} ?
			($monsterBaseExp / $char->{exp_max} * 100) :
			0;
		my $jobPercent = $char->{exp_job_max} ?
			($monsterJobExp / $char->{exp_job_max} * 100) :
			0;
		message TF("%s have gained %d/%d (%.2f%%/%.2f%%) Exp\n", $char, $monsterBaseExp, $monsterJobExp, $basePercent, $jobPercent), "exp";
		Plugins::callHook('exp_gained');
	},
	#VAR_VIRTUE
	VAR_HONOR, sub {
		my ($actor, $value) = @_;

		if ($value > 0) {
			my $duration = 0xffffffff - $value + 1;
			$actor->{mute_period} = $duration * 60;
			$actor->{muted} = time;
			message sprintf(
				$actor->verb(T("%s have been muted for %d minutes\n"), T("%s has been muted for %d minutes\n")),
				$actor, $duration
			), "parseMsg_statuslook", $actor->isa('Actor::You') ? 1 : 2;
		} else {
			delete $actor->{muted};
			delete $actor->{mute_period};
			message sprintf(
				$actor->verb(T("%s are no longer muted."), T("%s is no longer muted.")), $actor
			), "parseMsg_statuslook", $actor->isa('Actor::You') ? 1 : 2;
		}

		return unless $actor->isa('Actor::You');

		if ($config{dcOnMute} && $actor->{muted}) {
			chatLog("k", TF("*** %s have been muted for %d minutes, auto disconnect! ***\n", $actor, $actor->{mute_period}/60));
			quit();
		}
	},
	VAR_HP, sub {
		$_[0]{hp} = $_[1];
		$_[0]{hpPercent} = $_[0]{hp_max} ? 100 * $_[0]{hp} / $_[0]{hp_max} : undef;
	},
	VAR_MAXHP, sub {
		$_[0]{hp_max} = $_[1];
		$_[0]{hpPercent} = $_[0]{hp_max} ? 100 * $_[0]{hp} / $_[0]{hp_max} : undef;
	},
	VAR_SP, sub {
		$_[0]{sp} = $_[1];
		$_[0]{spPercent} = $_[0]{sp_max} ? 100 * $_[0]{sp} / $_[0]{sp_max} : undef;
	},
	VAR_MAXSP, sub {
		$_[0]{sp_max} = $_[1];
		$_[0]{spPercent} = $_[0]{sp_max} ? 100 * $_[0]{sp} / $_[0]{sp_max} : undef;
	},
	VAR_POINT, sub { $_[0]{points_free} = $_[1] },
	#VAR_HAIRCOLOR
	VAR_CLEVEL, sub {
		my ($actor, $value) = @_;

		$actor->{lv} = $value;

		message sprintf($actor->verb(T("%s are now level %d\n"), T("%s is now level %d\n")), $actor, $value), "success", $actor->isa('Actor::You') ? 1 : 2;

		return unless $actor->isa('Actor::You');

		if ($config{dcOnLevel} && $actor->{lv} >= $config{dcOnLevel}) {
			message TF("Disconnecting on level %s!\n", $config{dcOnLevel});
			chatLog("k", TF("Disconnecting on level %s!\n", $config{dcOnLevel}));
			quit();
		}
	},
	VAR_SPPOINT, sub { $_[0]{points_skill} = $_[1] },
	#VAR_STR
	#VAR_AGI
	#VAR_VIT
	#VAR_INT
	#VAR_DEX
	#VAR_LUK
	#VAR_JOB
	VAR_MONEY, sub {
		my ($actor, $value) = @_;

		my $change = $value - $actor->{zeny};
		$actor->{zeny} = $value;

		message sprintf(
			$change > 0
			? $actor->verb(T("%s gained %s zeny.\n"), T("%s gained %s zeny.\n"))
			: $actor->verb(T("%s lost %s zeny.\n"), T("%s lost %s zeny.\n")),
			$actor, formatNumber(abs $change)
		), 'info', $actor->isa('Actor::You') ? 1 : 2 if $change;

		return unless $actor->isa('Actor::You');

		if ($config{dcOnZeny} && $actor->{zeny} <= $config{dcOnZeny}) {
			$interface->errorDialog(TF("Disconnecting due to zeny lower than %s.", $config{dcOnZeny}));
			$quit = 1;
		}
	},
	#VAR_SEX
	VAR_MAXEXP, sub {
		$_[0]{exp_max_last} = $_[0]{exp_max};
		$_[0]{exp_max} = $_[1];

		if (!$net->clientAlive() && $initSync && $masterServer->{serverType} == 2) {
			$messageSender->sendSync(1);
			$initSync = 0;
		}
	},
	VAR_MAXJOBEXP, sub {
		$_[0]{exp_job_max_last} = $_[0]{exp_job_max};
		$_[0]{exp_job_max} = $_[1];
		#message TF("BaseExp: %s | JobExp: %s\n", $monsterBaseExp, $monsterJobExp), "info", 2 if ($monsterBaseExp);
	},
	VAR_WEIGHT, sub { $_[0]{weight} = $_[1] / 10 },
	VAR_MAXWEIGHT, sub { $_[0]{weight_max} = int($_[1] / 10) },
	#VAR_POISON
	#VAR_STONE
	#VAR_CURSE
	#VAR_FREEZING
	#VAR_SILENCE
	#VAR_CONFUSION
	VAR_STANDARD_STR, sub { $_[0]{points_str} = $_[1] },
	VAR_STANDARD_AGI, sub { $_[0]{points_agi} = $_[1] },
	VAR_STANDARD_VIT, sub { $_[0]{points_vit} = $_[1] },
	VAR_STANDARD_INT, sub { $_[0]{points_int} = $_[1] },
	VAR_STANDARD_DEX, sub { $_[0]{points_dex} = $_[1] },
	VAR_STANDARD_LUK, sub { $_[0]{points_luk} = $_[1] },
	#VAR_ATTACKMT
	#VAR_ATTACKEDMT
	#VAR_NV_BASIC
	VAR_ATTPOWER, sub { $_[0]{attack} = $_[1] },
	VAR_REFININGPOWER, sub { $_[0]{attack_bonus} = $_[1] },
	VAR_MAX_MATTPOWER, sub { $_[0]{attack_magic_max} = $_[1] },
	VAR_MIN_MATTPOWER, sub { $_[0]{attack_magic_min} = $_[1] },
	VAR_ITEMDEFPOWER, sub { $_[0]{def} = $_[1] },
	VAR_PLUSDEFPOWER, sub { $_[0]{def_bonus} = $_[1] },
	VAR_MDEFPOWER, sub { $_[0]{def_magic} = $_[1] },
	VAR_PLUSMDEFPOWER, sub { $_[0]{def_magic_bonus} = $_[1] },
	VAR_HITSUCCESSVALUE, sub { $_[0]{hit} = $_[1] },
	VAR_AVOIDSUCCESSVALUE, sub { $_[0]{flee} = $_[1] },
	VAR_PLUSAVOIDSUCCESSVALUE, sub { $_[0]{flee_bonus} = $_[1] },
	VAR_CRITICALSUCCESSVALUE, sub { $_[0]{critical} = $_[1] },
	VAR_ASPD, sub {
		$_[0]{attack_delay} = $_[1] >= 10 ? $_[1] : 10; # at least for mercenary
		$_[0]{attack_speed} = 200 - $_[0]{attack_delay} / 10;
	},
	#VAR_PLUSASPD
	VAR_JOBLEVEL, sub {
		my ($actor, $value) = @_;

		$actor->{lv_job} = $value;
		message sprintf($actor->verb("%s are now job level %d\n", "%s is now job level %d\n"), $actor, $actor->{lv_job}), "success", $actor->isa('Actor::You') ? 1 : 2;

		return unless $actor->isa('Actor::You');

		if ($config{dcOnJobLevel} && $actor->{lv_job} >= $config{dcOnJobLevel}) {
			message TF("Disconnecting on job level %d!\n", $config{dcOnJobLevel});
			chatLog("k", TF("Disconnecting on job level %d!\n", $config{dcOnJobLevel}));
			quit();
		}
	},
	#...
	VAR_MER_KILLCOUNT, sub { $_[0]{kills} = $_[1] },
	VAR_MER_FAITH, sub { $_[0]{faith} = $_[1] },
	#...
);

sub stat_info {
	my ($self, $args) = @_;

	return unless changeToInGameState;

	my $actor = {
		'00B0' => $char,
		'00B1' => $char,
		'00BE' => $char,
		'0141' => $char,
		'01AB' => exists $args->{ID} && Actor::get($args->{ID}),
		'02A2' => $char->{mercenary},
		'07DB' => $char->{homunculus},
		#'081E' => Sorcerer's Spirit - not implemented in Kore
	}->{$args->{switch}};

	unless ($actor) {
		warning sprintf "Actor is unknown or not ready for stat information (switch %s, type %d, val %d)\n", @{$args}{qw(switch type val)};
		return;
	}

	if (exists $stat_info_handlers{$args->{type}}) {
		# TODO: introduce Actor->something() to determine per-actor configurable verbosity level? (not only here)
		debug "Stat: $args->{type} => $args->{val}\n", "parseMsg",  $_[0]->isa('Actor::You') ? 1 : 2;
		$stat_info_handlers{$args->{type}}($actor, $args->{val});
	} else {
		warning sprintf "Unknown stat (%d => %d) received for %s\n", @{$args}{qw(type val)}, $actor;
	}

	if (!$char->{walk_speed}) {
		$char->{walk_speed} = 0.15; # This is the default speed, since xkore requires this and eA (And aegis?) do not send this if its default speed
	}
}

sub stat_info2 {
	my ($self, $args) = @_;
	return unless changeToInGameState();
	my ($type, $val, $val2) = @{$args}{qw(type val val2)};
	if ($type == VAR_STR) {
		$char->{str} = $val;
		$char->{str_bonus} = $val2;
		debug "Strength: $val + $val2\n", "parseMsg";
	} elsif ($type == VAR_AGI) {
		$char->{agi} = $val;
		$char->{agi_bonus} = $val2;
		debug "Agility: $val + $val2\n", "parseMsg";
	} elsif ($type == VAR_VIT) {
		$char->{vit} = $val;
		$char->{vit_bonus} = $val2;
		debug "Vitality: $val + $val2\n", "parseMsg";
	} elsif ($type == VAR_INT) {
		$char->{int} = $val;
		$char->{int_bonus} = $val2;
		debug "Intelligence: $val + $val2\n", "parseMsg";
	} elsif ($type == VAR_DEX) {
		$char->{dex} = $val;
		$char->{dex_bonus} = $val2;
		debug "Dexterity: $val + $val2\n", "parseMsg";
	} elsif ($type == VAR_LUK) {
		$char->{luk} = $val;
		$char->{luk_bonus} = $val2;
		debug "Luck: $val + $val2\n", "parseMsg";
	}
}

sub storage_closed {
	message T("Storage closed.\n"), "storage";
	delete $ai_v{temp}{storage_opened};
	delete $storage{opened};
	Plugins::callHook('packet_storage_close');

	# Storage log
	writeStorageLog(0);

	if ($char->{dcOnEmptyItems} ne "") {
		message TF("Disconnecting on empty %s!\n", $char->{dcOnEmptyItems});
		chatLog("k", TF("Disconnecting on empty %s!\n", $char->{dcOnEmptyItems}));
		quit();
	}
}

sub storage_item_added {
	my ($self, $args) = @_;

	my $index = $args->{index};
	my $amount = $args->{amount};

	my $item = $storage{$index} ||= Actor::Item->new;
	if ($item->{amount}) {
		$item->{amount} += $amount;
	} else {
		binAdd(\@storageID, $index);
		$item->{nameID} = $args->{nameID};
		$item->{index} = $index;
		$item->{amount} = $amount;
		$item->{type} = $args->{type};
		$item->{identified} = $args->{identified};
		$item->{broken} = $args->{broken};
		$item->{upgrade} = $args->{upgrade};
		$item->{cards} = $args->{cards};
		$item->{name} = itemName($item);
		$item->{binID} = binFind(\@storageID, $index);
	}
	message TF("Storage Item Added: %s (%d) x %s\n", $item->{name}, $item->{binID}, $amount), "storage", 1;
	$itemChange{$item->{name}} += $amount;
	$args->{item} = $item;
}

sub storage_item_removed {
	my ($self, $args) = @_;

	my ($index, $amount) = @{$args}{qw(index amount)};

	my $item = $storage{$index};
	$item->{amount} -= $amount;
	message TF("Storage Item Removed: %s (%d) x %s\n", $item->{name}, $item->{binID}, $amount), "storage";
	$itemChange{$item->{name}} -= $amount;
	$args->{item} = $item;
	if ($item->{amount} <= 0) {
		delete $storage{$index};
		binRemove(\@storageID, $index);
	}
}

sub storage_items_nonstackable {
	my ($self, $args) = @_;

	$self->_items_list({
		class => 'Actor::Item',
		hook => 'packet_storage',
		debug_str => 'Non-Stackable Storage Item',
		items => [$self->parse_items_nonstackable($args)],
		adder => sub { $_[0]{binID} = binAdd(\@storageID, $_[0]{index}); $storage{$_[0]{index}} = $_[0] },
	});

	$storageTitle = exists $args->{title} ? $args->{title} : undef;
}

sub storage_items_stackable {
	my ($self, $args) = @_;

	undef %storage;
	undef @storageID;

	$self->_items_list({
		class => 'Actor::Item',
		hook => 'packet_storage',
		debug_str => 'Stackable Storage Item',
		items => [$self->parse_items_stackable($args)],
		adder => sub { $_[0]{binID} = binAdd(\@storageID, $_[0]{index}); $storage{$_[0]{index}} = $_[0] },
		callback => sub {
			my ($local_item) = @_;

			$local_item->{amount} = $local_item->{amount} & ~0x80000000;
		},
	});

	$storageTitle = exists $args->{title} ? $args->{title} : undef;
}

sub storage_opened {
	my ($self, $args) = @_;
	$storage{items} = $args->{items};
	$storage{items_max} = $args->{items_max};

	$ai_v{temp}{storage_opened} = 1;
	if (!$storage{opened}) {
		$storage{opened} = 1;
		$storage{openedThisSession} = 1;
		message defined $storageTitle ? TF("Storage '%s' opened.\n", $storageTitle) : T("Storage opened.\n"), "storage";
		Plugins::callHook('packet_storage_open');
	}
}

sub storage_password_request {
	my ($self, $args) = @_;

	if ($args->{flag} == 0) {
		if ($args->{switch} eq '023E') {
			message T("Please enter a new character password:\n");
		} else {
			if ($config{storageAuto_password} eq '') {
				my $input = $interface->query(T("You've never set a storage password before.\nYou must set a storage password before you can use the storage.\nPlease enter a new storage password:"), isPassword => 1);
				if (!defined($input)) {
					return;
				}
				configModify('storageAuto_password', $input, 1);
			}
		}

		my @key = split /[, ]+/, $config{storageEncryptKey};
		if (!@key) {
			error (($args->{switch} eq '023E') ?
				T("Unable to send character password. You must set the 'storageEncryptKey' option in config.txt or servers.txt.\n") :
				T("Unable to send storage password. You must set the 'storageEncryptKey' option in config.txt or servers.txt.\n"));
			return;
		}
		my $crypton = new Utils::Crypton(pack("V*", @key), 32);
		my $num = ($args->{switch} eq '023E') ? $config{charSelect_password} : $config{storageAuto_password};
		$num = sprintf("%d%08d", length($num), $num);
		my $ciphertextBlock = $crypton->encrypt(pack("V*", $num, 0, 0, 0));
		message TF("Storage password set to: %s\n", $config{storageAuto_password}), "success";
		$messageSender->sendStoragePassword($ciphertextBlock, 2);
		$messageSender->sendStoragePassword($ciphertextBlock, 3);

	} elsif ($args->{flag} == 1) {
		if ($args->{switch} eq '023E') {
			if ($config{charSelect_password} eq '') {
				my $input = $interface->query(T("Please enter your character password."), isPassword => 1);
				if (!defined($input)) {
					return;
				}
				configModify('charSelect_password', $input, 1);
				message TF("Character password set to: %s\n", $input), "success";
			}
		} else {
			if ($config{storageAuto_password} eq '') {
				my $input = $interface->query(T("Please enter your storage password."), isPassword => 1);
				if (!defined($input)) {
					return;
				}
				configModify('storageAuto_password', $input, 1);
				message TF("Storage password set to: %s\n", $input), "success";
			}
		}

		my @key = split /[, ]+/, $config{storageEncryptKey};
		if (!@key) {
			error (($args->{switch} eq '023E') ?
				T("Unable to send character password. You must set the 'storageEncryptKey' option in config.txt or servers.txt.\n") :
				T("Unable to send storage password. You must set the 'storageEncryptKey' option in config.txt or servers.txt.\n"));
			return;
		}
		my $crypton = new Utils::Crypton(pack("V*", @key), 32);
		my $num = ($args->{switch} eq '023E') ? $config{charSelect_password} : $config{storageAuto_password};
		$num = sprintf("%d%08d", length($num), $num);
		my $ciphertextBlock = $crypton->encrypt(pack("V*", $num, 0, 0, 0));
		$messageSender->sendStoragePassword($ciphertextBlock, 3);

	} elsif ($args->{flag} == 8) {	# apparently this flag means that you have entered the wrong password
									# too many times, and now the server is blocking you from using storage
		error T("You have entered the wrong password 5 times. Please try again later.\n");
		# temporarily disable storageAuto
		$config{storageAuto} = 0;
		my $index = AI::findAction('storageAuto');
		if (defined $index) {
			AI::args($index)->{done} = 1;
			while (AI::action ne 'storageAuto') {
				AI::dequeue;
			}
		}
	} else {
		debug(($args->{switch} eq '023E') ?
			"Character password: unknown flag $args->{flag}\n" :
			"Storage password: unknown flag $args->{flag}\n");
	}
}

# TODO
sub storage_password_result {
	my ($self, $args) = @_;

	# TODO:
    # STORE_PASSWORD_EMPTY =  0x0
    # STORE_PASSWORD_EXIST =  0x1
    # STORE_PASSWORD_CHANGE =  0x2
    # STORE_PASSWORD_CHECK =  0x3
    # STORE_PASSWORD_PANALTY =  0x8

	if ($args->{type} == 4) { # STORE_PASSWORD_CHANGE_OK =  0x4
		message T("Successfully changed storage password.\n"), "success";
	} elsif ($args->{type} == 5) { # STORE_PASSWORD_CHANGE_NG =  0x5
		error T("Error: Incorrect storage password.\n");
	} elsif ($args->{type} == 6) { # STORE_PASSWORD_CHECK_OK =  0x6
		message T("Successfully entered storage password.\n"), "success";
	} elsif ($args->{type} == 7) { # STORE_PASSWORD_CHECK_NG =  0x7
		error T("Error: Incorrect storage password.\n");
		# disable storageAuto or the Kafra storage will be blocked
		configModify("storageAuto", 0);
		my $index = AI::findAction('storageAuto');
		if (defined $index) {
			AI::args($index)->{done} = 1;
			while (AI::action ne 'storageAuto') {
				AI::dequeue;
			}
		}
	} else {
		#message "Storage password: unknown type $args->{type}\n";
	}

	# $args->{val}
	# unknown, what is this for?
}

sub initialize_message_id_encryption {
	my ($self, $args) = @_;
	if ($masterServer->{messageIDEncryption} ne '0') {
		$messageSender->sendMessageIDEncryptionInitialized();

		my @c;
		my $shtmp = $args->{param1};
		for (my $i = 8; $i > 0; $i--) {
			$c[$i] = $shtmp & 0x0F;
			$shtmp >>= 4;
		}
		my $w = ($c[6]<<12) + ($c[4]<<8) + ($c[7]<<4) + $c[1];
		$enc_val1 = ($c[2]<<12) + ($c[3]<<8) + ($c[5]<<4) + $c[8];
		$enc_val2 = (((($enc_val1 ^ 0x0000F3AC) + $w) << 16) | (($enc_val1 ^ 0x000049DF) + $w)) ^ $args->{param2};
	}
}

# TODO: known prefixes (chat domains): micc | ssss | ...
sub system_chat {
	my ($self, $args) = @_;

	my $message = bytesToString($args->{message});
	if (substr($message,0,4) eq 'micc') {
		$message = bytesToString(substr($args->{message},34));
	}
	$message =~ s/\000//g; # remove null charachters
	$message =~ s/^(tool[0-9a-fA-F]{6})//g; # remove those annoying toolDDDDDD from bRO (and maybe some other server?)
	$message =~ s/^ssss//g; # remove those annoying ssss from bRO (and maybe some other server?)
	$message =~ s/^ +//g; $message =~ s/ +$//g; # remove whitespace in the beginning and the end of $message
	stripLanguageCode(\$message);
	chatLog("s", "$message\n") if ($config{logSystemChat});
	# Translation Comment: System/GM chat
	message TF("[系统] %s\n", $message), "schat";

	Plugins::callHook('packet_sysMsg', {
	Msg => $message
	});
}

sub unequip_item {
	my ($self, $args) = @_;

	return unless changeToInGameState();
	my $item = $char->inventory->getByServerIndex($args->{index});
	delete $item->{equipped};

	if ($args->{type} == 10 || $args->{type} == 32768) {
		delete $char->{equipment}{arrow};
		delete $char->{arrow};
	} else {
		foreach (%equipSlot_rlut){
			if ($_ & $args->{type}){
				next if $_ == 10; #work around Arrow bug
				next if $_ == 32768;
				delete $char->{equipment}{$equipSlot_lut{$_}};
			}
		}
	}
	if ($item) {
		message TF("You unequip %s (%d) - %s\n",
			$item->{name}, $item->{invIndex},
			$equipTypes_lut{$item->{type_equip}}), 'inventory';
	}
}

sub unit_levelup {
	my ($self, $args) = @_;

	my $ID = $args->{ID};
	my $type = $args->{type};
	my $actor = Actor::get($ID);
	if ($type == LEVELUP_EFFECT) {
		message TF("%s gained a level!\n", $actor);
		Plugins::callHook('base_level', {name => $actor});
	} elsif ($type == JOBLEVELUP_EFFECT) {
		message TF("%s gained a job level!\n", $actor);
		Plugins::callHook('job_level', {name => $actor});
	} elsif ($type == REFINING_FAIL_EFFECT) {
		message TF("%s failed to refine a weapon!\n", $actor), "refine";
	} elsif ($type == REFINING_SUCCESS_EFFECT) {
		message TF("%s successfully refined a weapon!\n", $actor), "refine";
	} elsif ($type == MAKEITEM_AM_SUCCESS_EFFECT) {
	} elsif ($type == MAKEITEM_AM_FAIL_EFFECT) {
	} else {
		message TF("%s unknown unit_levelup effect (%d)\n", $actor, $type);
	}
}

sub use_item {
	my ($self, $args) = @_;

	return unless changeToInGameState();
	my $item = $char->inventory->getByServerIndex($args->{index});
	if ($item) {
		$item->{amount} -= $args->{amount};
		message TF("You used Item: %s (%d) x %s\n", $item->{name}, $item->{invIndex}, $args->{amount}), "useItem";
		if ($item->{amount} <= 0) {
			$char->inventory->remove($item);
		}
	}
}

sub users_online {
	my ($self, $args) = @_;

	message TF("There are currently %s users online\n", $args->{users}), "info";
}

sub warp_portal_list {
	my ($self, $args) = @_;

	# strip gat extension
	($args->{memo1}) = $args->{memo1} =~ /^(.*)\.gat/;
	($args->{memo2}) = $args->{memo2} =~ /^(.*)\.gat/;
	($args->{memo3}) = $args->{memo3} =~ /^(.*)\.gat/;
	($args->{memo4}) = $args->{memo4} =~ /^(.*)\.gat/;
	# Auto-detect saveMap
	if ($args->{type} == 26) {
		configModify('saveMap', $args->{memo2}) if ($args->{memo2} && $config{'saveMap'} ne $args->{memo2});
	} elsif ($args->{type} == 27) {
		configModify('saveMap', $args->{memo1}) if ($args->{memo1} && $config{'saveMap'} ne $args->{memo1});
	}

	$char->{warp}{type} = $args->{type};
	undef @{$char->{warp}{memo}};
	push @{$char->{warp}{memo}}, $args->{memo1} if $args->{memo1} ne "";
	push @{$char->{warp}{memo}}, $args->{memo2} if $args->{memo2} ne "";
	push @{$char->{warp}{memo}}, $args->{memo3} if $args->{memo3} ne "";
	push @{$char->{warp}{memo}}, $args->{memo4} if $args->{memo4} ne "";

	message T("----------------- Warp Portal --------------------\n" .
		"#  Place                           Map\n"), "list";
	for (my $i = 0; $i < @{$char->{warp}{memo}}; $i++) {
		message(swrite(
			"@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<",
			[$i, $maps_lut{$char->{warp}{memo}[$i].'.rsw'},
			$char->{warp}{memo}[$i]]),
			"list");
	}
	message("--------------------------------------------------\n", "list");
}

# 08CB
sub rates_info {
	my ($self, $args) = @_;
	my %rates = (
		exp => { total => $args->{exp} },
		death => { total => $args->{death} },
		drop => { total => $args->{drop} },
	);
	
	# get details
	for (my $offset = 0; $offset < length($args->{detail}); $offset += 7) {
		my ($type, $exp, $death, $drop) = unpack("C s3", substr($args->{detail}, $offset, 7));
		$rates{exp}{$type} = $exp; $rates{death}{$type} = $death; $rates{drop}{$type} = $drop;
	}
	 
	# we have 4 kinds of detail:
	# $rates{exp or drop or death}{DETAIL_KIND}
	# 0 = base server exp (?)
	# 1 = premium acc additional exp
	# 2 = server additional exp
	# 3 = not sure, maybe it's for "extra exp" events? never seen this using the official client (bRO)
	message T("=========================== Server Infos ===========================\n"), "info";
	message TF("EXP Rates: %s\% (Base %s\% + Premium %s\% + Server %s\% + Plus %s\%) \n", $rates{exp}{total}, $rates{exp}{0}, $rates{exp}{1}, $rates{exp}{2}, $rates{exp}{3}), "info";
	message TF("Drop Rates: %s\% (Base %s\% + Premium %s\% + Server %s\% + Plus %s\%) \n", $rates{drop}{total}, $rates{drop}{0}, $rates{drop}{1}, $rates{drop}{2}, $rates{drop}{3}), "info";
	message TF("Death Penalty: %s\% (Base %s\% + Premium %s\% + Server %s\% + Plus %s\%) \n", $rates{death}{total}, $rates{death}{0}, $rates{death}{1}, $rates{death}{2}, $rates{death}{3}), "info";
	message T("=====================================================================\n"), "info";
}

sub premium_rates_info {
	my ($self, $args) = @_;
	message TF("Premium rates: exp %+i%%, death %+i%%, drop %+i%%.\n", $args->{exp}, $args->{death}, $args->{drop}), "info";
}

# this info will be sent to xkore 2 clients
sub hotkeys {
	my ($self, $args) = @_;
	undef $hotkeyList;
	my $msg;
	$msg .= center(" " . T("Hotkeys") . " ", 79, '-') . "\n";
	$msg .=	swrite(sprintf("\@%s \@%s \@%s \@%s", ('>'x3), ('<'x30), ('<'x5), ('>'x3)),
			["#", T("Name"), T("Type"), T("Lv")]);
	$msg .= sprintf("%s\n", ('-'x79));
	my $j = 0;
	for (my $i = 2; $i < $args->{RAW_MSG_SIZE}; $i+=7) {
		$hotkeyList->[$j]->{type} = unpack("C1", substr($args->{RAW_MSG}, $i, 1));
		$hotkeyList->[$j]->{ID} = unpack("V1", substr($args->{RAW_MSG}, $i+1, 4));
		$hotkeyList->[$j]->{lv} = unpack("v1", substr($args->{RAW_MSG}, $i+5, 2));

		$msg .= swrite(TF("\@%s \@%s \@%s \@%s", ('>'x3), ('<'x30), ('<'x5), ('>'x3)),
			[$j, $hotkeyList->[$j]->{type} ? Skill->new(idn => $hotkeyList->[$j]->{ID})->getName() : itemNameSimple($hotkeyList->[$j]->{ID}),
			$hotkeyList->[$j]->{type} ? T("skill") : T("item"),
			$hotkeyList->[$j]->{lv}]);
		$j++;
	}
	$msg .= sprintf("%s\n", ('-'x79));
	debug($msg, "list");
}

sub hack_shield_alarm {
	error T("Error: You have been forced to disconnect by a Hack Shield.\n Please check Poseidon.\n"), "connection";
	Commands::run('relog 100000000');
}

sub talkie_box {
	my ($self, $args) = @_;
	message TF("%s's talkie box message: %s.\n", Actor::get($args->{ID})->nameString(), $args->{message}), "info";
}

sub manner_message {
	my ($self, $args) = @_;
	if ($args->{flag} == 0) {
		message T("A manner point has been successfully aligned.\n"), "info";
	} elsif ($args->{flag} == 3) {
		message T("Chat Block has been applied by GM due to your ill-mannerous action.\n"), "info";
	} elsif ($args->{flag} == 4) {
		message T("Automated Chat Block has been applied due to Anti-Spam System.\n"), "info";
	} elsif ($args->{flag} == 5) {
		message T("You got a good point.\n"), "info";
	} else {
		warning TF("flag: %s gave unknown results in: %s\n", $args->{flag}, $self->{packet_list}{$args->{switch}}->[0]);
	}
}

sub GM_silence {
	my ($self, $args) = @_;
	if ($args->{flag}) {
		message TF("You have been: muted by %s.\n", bytesToString($args->{name})), "info";
	}
	else {
		message TF("You have been: unmuted by %s.\n", bytesToString($args->{name})), "info";
	}
}

# TODO test if we must use ID to know if the packets are meant for us.
# ID is monsterID
sub taekwon_packets {
	my ($self, $args) = @_;
	my $string = ($args->{value} == 1) ? T("Sun") : ($args->{value} == 2) ? T("Moon") : ($args->{value} == 3) ? T("Stars") : TF("Unknown (%d)", $args->{value});
	if ($args->{flag} == 0) { # Info about Star Gladiator save map: Map registered
		message TF("You have now marked: %s as Place of the %s.\n", bytesToString($args->{name}), $string), "info";
	} elsif ($args->{flag} == 1) { # Info about Star Gladiator save map: Information
		message TF("%s is marked as Place of the %s.\n", bytesToString($args->{name}), $string), "info";
	} elsif ($args->{flag} == 10) { # Info about Star Gladiator hate mob: Register mob
		message TF("You have now marked %s as Target of the %s.\n", bytesToString($args->{name}), $string), "info";
	} elsif ($args->{flag} == 11) { # Info about Star Gladiator hate mob: Information
		message TF("%s is marked as Target of the %s.\n", bytesToString($args->{name}), $string);
	} elsif ($args->{flag} == 20) { #Info about TaeKwon Do TK_MISSION mob
		message TF("[TaeKwon Mission] Target Monster : %s (%d%)"."\n", bytesToString($args->{name}), $args->{value}), "info";
	} elsif ($args->{flag} == 30) { #Feel/Hate reset
		message T("Your Hate and Feel targets have been resetted.\n"), "info";
	} else {
		warning TF("flag: %s gave unknown results in: %s\n", $args->{flag}, $self->{packet_list}{$args->{switch}}->[0]);
	}
}

# 0192
# TODO: add actual functionality, maybe alter field?
sub map_change_cell {
	my ($self, $args) = @_;
	debug "Cell on ($args->{x}, $args->{y}) has been changed to $args->{type} on $args->{map_name}\n", "info";
}

# 01D1
sub blade_stop {
	my ($self, $args) = @_;
	if($args->{active} == 0) {
		message TF("Blade Stop by %s on %s is deactivated.\n", Actor::get($args->{sourceID})->nameString(), Actor::get($args->{targetID})->nameString()), "info";
	} elsif($args->{active} == 1) {
		message TF("Blade Stop by %s on %s is active.\n", Actor::get($args->{sourceID})->nameString(), Actor::get($args->{targetID})->nameString()), "info";
	}
}

sub divorced {
	my ($self, $args) = @_;
	message TF("%s and %s have divorced from each other.\n", $char->{name}, $args->{name}), "info"; # is it $char->{name} or is this packet also used for other players?
}

# 0221
# TODO -> Check If we use correct unpack string
sub upgrade_list {
	my ($self, $args) = @_;
	my $msg;
	$msg .= center(" " . T("Upgrade List") . " ", 79, '-') . "\n";
	for (my $i = 4; $i < $args->{RAW_MSG_SIZE}; $i += 13) {
		my ($index, $nameID) = unpack('v x6 C', substr($args->{RAW_MSG}, $i, 13));
		my $item = $char->inventory->getByServerIndex($index);
		$msg .= swrite(sprintf("\@%s \@%s", ('>'x2), ('<'x50)), [$item->{invIndex}, itemName($item)]);
	}
	$msg .= sprintf("%s\n", ('-'x79));
	message($msg, "list");
}

# 0223
sub upgrade_message {
	my ($self, $args) = @_;
	if($args->{type} == 0) { # Success
		message TF("Weapon upgraded: %s\n", itemName(Actor::Item::get($args->{nameID}))), "info";
	} elsif($args->{type} == 1) { # Fail
		message TF("Weapon not upgraded: %s\n", itemName(Actor::Item::get($args->{nameID}))), "info";
		# message TF("Weapon upgraded: %s\n", itemName(Actor::Item::get($args->{nameID}))), "info";
	} elsif($args->{type} == 2) { # Fail Lvl
		message TF("Cannot upgrade %s until you level up the upgrade weapon skill.\n", itemName(Actor::Item::get($args->{nameID}))), "info";
	} elsif($args->{type} == 3) { # Fail Item
		message TF("You lack item %s to upgrade the weapon.\n", itemNameSimple($args->{nameID})), "info";
	}
}

# 025A
# TODO
sub cooking_list {
	my ($self, $args) = @_;
	undef $cookingList;
	my $k = 0;
	my $msg;
	$msg .= center(" " . T("Cooking List") . " ", 79, '-') . "\n";
	for (my $i = 6; $i < $args->{RAW_MSG_SIZE}; $i += 2) {
		my $nameID = unpack('v', substr($args->{RAW_MSG}, $i, 2));
		$cookingList->[$k] = $nameID;
		$msg .= swrite(sprintf("\@%s \@%s", ('>'x2), ('<'x50)), [$k, itemNameSimple($nameID)]);
		$k++;
	}
	$msg .= sprintf("%s\n", ('-'x79));
	message($msg, "list");
	message T("You can now use the 'cook' command.\n"), "info";
}

sub party_show_picker {
	my ($self, $args) = @_;

	# wtf the server sends this packet for your own character? (rRo)
	return if $args->{sourceID} eq $accountID;

	my $string = ($char->{party}{users}{$args->{sourceID}} && %{$char->{party}{users}{$args->{sourceID}}}) ? $char->{party}{users}{$args->{sourceID}}->name() : $args->{sourceID};
	my $item = {};
	$item->{nameID} = $args->{nameID};
	$item->{identified} = $args->{identified};
	$item->{upgrade} = $args->{upgrade};
	$item->{cards} = $args->{cards};
	$item->{broken} = $args->{broken};
	message TF("Party member %s has picked up item %s.\n", $string, itemName($item)), "info";
}

# 02CB
# TODO
# Required to start the instancing information window on Client
# This window re-appear each "refresh" of client automatically until 02CD is send to client.
sub instance_window_start {
	my ($self, $args) = @_;
	debug $self->{packet_list}{$args->{switch}}->[0] . " " . join(', ', @{$args}{@{$self->{packet_list}{$args->{switch}}->[2]}}) . "\n";
}

# 02CC
# TODO
# To announce Instancing queue creation if no maps available
sub instance_window_queue {
	my ($self, $args) = @_;
	debug $self->{packet_list}{$args->{switch}}->[0] . " " . join(', ', @{$args}{@{$self->{packet_list}{$args->{switch}}->[2]}}) . "\n";
}

# 02CD
# TODO
sub instance_window_join {
	my ($self, $args) = @_;
	debug $self->{packet_list}{$args->{switch}}->[0] . " " . join(', ', @{$args}{@{$self->{packet_list}{$args->{switch}}->[2]}}) . "\n";
}

# 02CE
#0 = "The Memorial Dungeon reservation has been canceled."
#    Re-innit Window, in some rare cases.
#1 = "The Memorial Dungeon expired; it has been destroyed."
#2 = "The Memorial Dungeon's entry time limit expired; it has been destroyed."
#3 = "The Memorial Dungeon has been removed."
#4 = "A system error has occurred in the Memorial Dungeon. Please relog in to the game to continue playing."
#    Just remove the window, maybe party leave.
# TODO: test if correct message displays, no type == 0 ?
sub instance_window_leave {
	my ($self, $args) = @_;
	# TYPE_NOTIFY =  0x0; Ihis one will make Window, as Client logic do.
	if($args->{flag} == 1) { # TYPE_DESTROY_LIVE_TIMEOUT =  0x1
		message T("The Memorial Dungeon expired it has been destroyed.\n"), "info";
	} elsif($args->{flag} == 2) { # TYPE_DESTROY_ENTER_TIMEOUT =  0x2
		message T("The Memorial Dungeon's entry time limit expired it has been destroyed.\n"), "info";
	} elsif($args->{flag} == 3) { # TYPE_DESTROY_USER_REQUEST =  0x3
		message T("The Memorial Dungeon has been removed.\n"), "info";
	} elsif ($args->{flag} == 4) { # TYPE_CREATE_FAIL =  0x4
		message T("The instance windows has been removed, possibly due to party leave.\n"), "info";
	} else {
		warning TF("flag: %s gave unknown results in: %s\n", $args->{flag}, $self->{packet_list}{$args->{switch}}->[0]);
	}
}

# 02DC
# TODO
sub battleground_message {
	my ($self, $args) = @_;
	debug $self->{packet_list}{$args->{switch}}->[0] . " " . join(', ', @{$args}{@{$self->{packet_list}{$args->{switch}}->[2]}}) . "\n";
}

# 02DD
# TODO
sub battleground_emblem {
	my ($self, $args) = @_;
	debug $self->{packet_list}{$args->{switch}}->[0] . " " . join(', ', @{$args}{@{$self->{packet_list}{$args->{switch}}->[2]}}) . "\n";
}

sub battleground_score {
	my ($self, $args) = @_;
	message TF("Battleground score - Lions: '%d' VS Eagles: '%d'\n", $args->{score_lion}, $args->{score_eagle}), "info";
}

sub battleground_position {
	my ($self, $args) = @_;
}

sub battleground_hp {
	my ($self, $args) = @_;
}

# 02EF
# TODO
sub font {
	my ($self, $args) = @_;
	debug "Account: $args->{ID} is using fontID: $args->{fontID}\n", "info";
}

# 019E
# TODO
# note: this is probably the trigger for the client's slotmachine effect or so.
sub pet_capture_process {
	my ($self, $args) = @_;
	message T("Attempting to capture pet (slot machine).\n"), "info";
}

# 0294
# TODO -> maybe add table file?
sub book_read {
	my ($self, $args) = @_;
	debug "Reading book: $args->{bookID} page: $args->{page}\n", "info";
}

# TODO can we use itemName($actor)? -> tech: don't think so because it seems that this packet is received before the inventory list
sub rental_time {
	my ($self, $args) = @_;
	message TF("The '%s' item will disappear in %d minutes.\n", itemNameSimple($args->{nameID}), $args->{seconds}/60), "info";
}

# TODO can we use itemName($actor)? -> tech: don't think so because the item might be removed from inventory before this packet is sent -> untested
sub rental_expired {
	my ($self, $args) = @_;
	message TF("Rental item '%s' has expired!\n", itemNameSimple($args->{nameID})), "info";
}

# 0289
# TODO
sub cash_buy_fail {
	my ($self, $args) = @_;
	debug "cash_buy_fail $args->{cash_points} $args->{kafra_points} $args->{fail}\n";
}

sub adopt_reply {
	my ($self, $args) = @_;
	if($args->{type} == 0) {
		message T("You cannot adopt more than 1 child.\n"), "info";
	} elsif($args->{type} == 1) {
		message T("You must be at least character level 70 in order to adopt someone.\n"), "info";
	} elsif($args->{type} == 2) {
		message T("You cannot adopt a married person.\n"), "info";
	}
}

# TODO do something with sourceID, targetID? -> tech: maybe your spouses adopt_request will also display this message for you.
sub adopt_request {
	my ($self, $args) = @_;
	message TF("%s wishes to adopt you. Do you accept?\n", $args->{name}), "info";
	# TODO how to accept?
}

# 0293
sub boss_map_info {
	my ($self, $args) = @_;

	if ($args->{flag} == 0) {
		message T("You cannot find any trace of a Boss Monster in this area.\n"), "info";
	} elsif ($args->{flag} == 1) {
		message TF("MVP Boss %s is now on location: (%d, %d)\n", $args->{name}, $args->{x}, $args->{y}), "info";
	} elsif ($args->{flag} == 2) {
		message TF("MVP Boss %s has been detected on this map!\n", $args->{name}), "info";
	} elsif ($args->{flag} == 3) {
		message TF("MVP Boss %s is dead, but will spawn again in %d hour(s) and %d minutes(s).\n", $args->{name}, $args->{hours}, $args->{minutes}), "info";
	} else {
		debug $self->{packet_list}{$args->{switch}}->[0] . " " . join(', ', @{$args}{@{$self->{packet_list}{$args->{switch}}->[2]}}) . "\n";
		warning TF("flag: %s gave unknown results in: %s\n", $args->{flag}, $self->{packet_list}{$args->{switch}}->[0]);
	}
}

# 02B1
sub quest_all_list {
	my ($self, $args) = @_;
	$questList = {};
	for (my $i = 8; $i < $args->{amount}*5+8; $i += 5) {
		my ($questID, $active) = unpack('V C', substr($args->{RAW_MSG}, $i, 5));
		$questList->{$questID}->{active} = $active;
		debug "$questID $active\n", "info";
	}
}

# 02B2
# note: this packet shows all quests + their missions and has variable length
sub quest_all_mission {
	my ($self, $args) = @_;
	debug $self->{packet_list}{$args->{switch}}->[0] . " " . join(', ', @{$args}{@{$self->{packet_list}{$args->{switch}}->[2]}}) ."\n";
	for (my $i = 8; $i < $args->{amount}*104+8; $i += 104) {
		my ($questID, $time_start, $time, $mission_amount) = unpack('V3 v', substr($args->{RAW_MSG}, $i, 14));
		my $quest = \%{$questList->{$questID}};
		$quest->{time_start} = $time_start;
		$quest->{time} = $time;
		debug "$questID $time_start $time $mission_amount\n", "info";
		for (my $j = 0; $j < $mission_amount; $j++) {
			my ($mobID, $count, $mobName) = unpack('V v Z24', substr($args->{RAW_MSG}, 14+$i+$j*30, 30));
			my $mission = \%{$quest->{missions}->{$mobID}};
			$mission->{mobID} = $mobID;
			$mission->{count} = $count;
			$mission->{mobName} = bytesToString($mobName);
			debug "- $mobID $count $mobName\n", "info";
		}
	}
}

# 02B3
# note: this packet shows all missions for 1 quest and has fixed length
sub quest_add {
	my ($self, $args) = @_;
	my $questID = $args->{questID};
	my $quest = \%{$questList->{$questID}};

	unless (%$quest) {
		message TF("Quest: %s has been added.\n", $quests_lut{$questID} ? "$quests_lut{$questID}{title} ($questID)" : $questID), "info";
	}

	$quest->{time_start} = $args->{time_start};
	$quest->{time} = $args->{time};
	$quest->{active} = $args->{active};
	debug $self->{packet_list}{$args->{switch}}->[0] . " " . join(', ', @{$args}{@{$self->{packet_list}{$args->{switch}}->[2]}}) ."\n";
	for (my $i = 0; $i < $args->{amount}; $i++) {
		my ($mobID, $count, $mobName) = unpack('V v Z24', substr($args->{RAW_MSG}, 17+$i*30, 30));
		my $mission = \%{$quest->{missions}->{$mobID}};
		$mission->{mobID} = $mobID;
		$mission->{count} = $count;
		$mission->{mobName} = bytesToString($mobName);
		debug "- $mobID $count $mobName\n", "info";
	}
}

# 02B4
sub quest_delete {
	my ($self, $args) = @_;
	my $questID = $args->{questID};
	message TF("Quest: %s has been deleted.\n", $quests_lut{$questID} ? "$quests_lut{$questID}{title} ($questID)" : $questID), "info";
	delete $questList->{$questID};
}

sub parse_quest_update_mission_hunt {
	my ($self, $args) = @_;
	@{$args->{mobs}} = map {
		my %result; @result{qw(questID mobID count)} = unpack 'V2 v', $_; \%result
	} unpack '(a10)*', $args->{mobInfo};
}

sub reconstruct_quest_update_mission_hunt {
	my ($self, $args) = @_;
	$args->{mobInfo} = pack '(a10)*', map { pack 'V2 v', @{$_}{qw(questID mobID count)} } @{$args->{mobs}};
}

sub parse_quest_update_mission_hunt_v2 {
	my ($self, $args) = @_;
	@{$args->{mobs}} = map {
		my %result; @result{qw(questID mobID goal count)} = unpack 'V2 v2', $_; \%result
	} unpack '(a12)*', $args->{mobInfo};
}

sub reconstruct_quest_update_mission_hunt_v2 {
	my ($self, $args) = @_;
	$args->{mobInfo} = pack '(a12)*', map { pack 'V2 v2', @{$_}{qw(questID mobID goal count)} } @{$args->{mobs}};
}

# 02B5
# note: this packet updates the objectives counters
sub quest_update_mission_hunt {
	my ($self, $args) = @_;
	for my $mob (@{$args->{mobs}}) {
		@{$questList->{$mob->{questID}}{missions}{$mob->{mobID}}}{@$_} = @{$mob}{@$_} for [qw(mobID goal count)];
	}
}

# 02B7
sub quest_active {
	my ($self, $args) = @_;
	my $questID = $args->{questID};

	message $args->{active}
		? TF("Quest %s is now active.\n", $quests_lut{$questID} ? "$quests_lut{$questID}{title} ($questID)" : $questID)
		: TF("Quest %s is now inactive.\n", $quests_lut{$questID} ? "$quests_lut{$questID}{title} ($questID)" : $questID)
	, "info";

	$questList->{$args->{questID}}->{active} = $args->{active};
}

# 018B
sub quit_response {
	my ($self, $args) = @_;
	if ($args->{fail}) { # NOTDISCONNECTABLE_STATE =  0x1
		error T("Please wait 10 seconds before trying to log out.\n"); # MSI_CANT_EXIT_NOW =  0x1f6
	} else { # DISCONNECTABLE_STATE =  0x0
		message T("Logged out from the server succesfully.\n"), "success";
	}
}

sub GM_req_acc_name {
	my ($self, $args) = @_;
	message TF("The accountName for ID %s is %s.\n", $args->{targetID}, $args->{accountName}), "info";
}

# 00CB
sub sell_result {
	my ($self, $args) = @_;
	if ($args->{fail}) {
		error T("Sell failed.\n");
	} else {
		message T("Sell completed.\n"), "success";
	}
}

# 018B
sub quit_response {
	my ($self, $args) = @_;
	if ($args->{fail}) { # NOTDISCONNECTABLE_STATE =  0x1
		error T("Please wait 10 seconds before trying to log out.\n"); # MSI_CANT_EXIT_NOW =  0x1f6
	} else { # DISCONNECTABLE_STATE =  0x0
		message T("Logged out from the server succesfully.\n"), "success";
	}
}

# 00B3
# TODO: add real client messages and logic?
# ClientLogic: LoginStartMode = 5; ShowLoginScreen;
sub switch_character {
	my ($self, $args) = @_;
	# User is switching characters in X-Kore
	$net->setState(Network::CONNECTED_TO_MASTER_SERVER);
	$net->serverDisconnect();

	# FIXME better support for multiple received_characters packets
	undef @chars;

	debug "result: $args->{result}\n";
}

use constant {
	EXP_FROM_BATTLE => 0x0,
	EXP_FROM_QUEST => 0x1,
};

# 07F6 (exp) doesn't change any exp information because 00B1 (exp_zeny_info) is always sent with it
# r7643 - copy-pasted to RagexeRE_2009_10_27a.pm
sub exp {
	my ($self, $args) = @_;

	my $max = {VAR_EXP, $char->{exp_max}, VAR_JOBEXP, $char->{exp_job_max}}->{$args->{type}};
	$args->{percent} = $max ? $args->{val} / $max * 100 : 0;

	if ($args->{flag} == EXP_FROM_BATTLE) {
		if ($args->{type} == VAR_EXP) {
			message TF("Base Exp gained: %d (%.2f%%)\n", @{$args}{qw(val percent)}), 'exp2', 2;
		} elsif ($args->{type} == VAR_JOBEXP) {
			message TF("Job Exp gained: %d (%.2f%%)\n", @{$args}{qw(val percent)}), 'exp2', 2;
		} else {
			message TF("Unknown (type=%d) Exp gained: %d\n", @{$args}{qw(type val)}), 'exp2', 2;
		}
	} elsif ($args->{flag} == EXP_FROM_QUEST) {
		if ($args->{type} == VAR_EXP) {
			message TF("Base Quest Exp gained: %d (%.2f%%)\n", @{$args}{qw(val percent)}), 'exp2', 2;
		} elsif ($args->{type} == VAR_JOBEXP) {
			message TF("Job Quest Exp gained: %d (%.2f%%)\n", @{$args}{qw(val percent)}), 'exp2', 2;
		} else {
			message TF("Unknown (type=%d) Quest Exp gained: %d\n", @{$args}{qw(type val)}), 'exp2', 2;
		}
	} else {
		if ($args->{type} == VAR_EXP) {
			message TF("Base Unknown (flag=%d) Exp gained: %d (%.2f%%)\n", @{$args}{qw(flag val percent)}), 'exp2', 2;
		} elsif ($args->{type} == VAR_JOBEXP) {
			message TF("Job Unknown (flag=%d) Exp gained: %d (%.2f%%)\n", @{$args}{qw(flag val percent)}), 'exp2', 2;
		} else {
			message TF("Unknown (type=%d) Unknown (flag=%d) Exp gained: %d\n", @{$args}{qw(type flag val)}), 'exp2', 2;
		}
	}
}

use constant {
	TYPE_BOXITEM => 0x0,
	TYPE_MONSTER_ITEM => 0x1,
};

# TODO: more meaningful messages?
sub special_item_obtain {
	my ($self, $args) = @_;

	my $item_name = itemNameSimple($args->{nameID});
	my $holder =  bytesToString($args->{holder});
	stripLanguageCode(\$holder);
	if ($args->{type} == TYPE_BOXITEM) {
		@{$args}{qw(box_nameID)} = unpack 'c/v', $args->{etc};

		my $box_item_name = itemNameSimple($args->{box_nameID});
		chatLog("GM", "$holder has got $item_name from $box_item_name\n") if ($config{logSystemChat});
		message TF("%s has got %s from %s.\n", $holder, $item_name, $box_item_name), 'schat';

	} elsif ($args->{type} == TYPE_MONSTER_ITEM) {
		@{$args}{qw(len monster_name)} = unpack 'c Z*', $args->{etc};
		my $monster_name = bytesToString($args->{monster_name});
		stripLanguageCode(\$monster_name);
		chatLog("GM", "$holder has got $item_name from $monster_name\n") if ($config{logSystemChat});
		message TF("%s has got %s from %s.\n", $holder, $item_name, $monster_name), 'schat';

	} else {
		warning TF("%s has got %s (from Unknown type %d).\n", $holder, $item_name, $args->{type}), 'schat';
	}
}

sub progress_bar {
	my($self, $args) = @_;
	message TF("Progress bar loading (time: %d).\n", $args->{time}), 'info';
	$taskManager->add(
		new Task::Chained(tasks => [new Task::Wait(seconds => $args->{time}),
		new Task::Function(function => sub {
			 $messageSender->sendProgress();
			 message TF("Progress bar finished.\n"), 'info';
			 $_[0]->setDone;
		})]));
}

sub progress_bar_stop {
	my($self, $args) = @_;
	message TF("Progress bar finished.\n", 'info');
}

sub define_check {
	my ($self, $args) = @_;
	#TODO
}

sub buyer_found {
    my($self, $args) = @_;
    my $ID = $args->{ID};

	if (!$buyerLists{$ID} || !%{$buyerLists{$ID}}) {
		binAdd(\@buyerListsID, $ID);
		Plugins::callHook('packet_buyer', {ID => $ID});
	}
	$buyerLists{$ID}{title} = bytesToString($args->{title});
	$buyerLists{$ID}{id} = $ID;
}

sub buyer_lost {
	my ($self, $args) = @_;

	my $ID = $args->{ID};
	binRemove(\@buyerListsID, $ID);
	delete $buyerLists{$ID};
}

sub battlefield_position {
	my ($self, $args) = @_;
	
	my $ID = $args->{ID};
	my $name = $args->{name};
}

sub battlefield_hp {
	my ($self, $args) = @_;
	
	my $ID = $args->{ID};
	my $name = $args->{name};
	
}

sub millenium_shield {
	my ($self, $args) = @_;
}

sub skill_post_delaylist {
	my ($self, $args) = @_;
	
	my $msg = $args->{RAW_MSG};
	my $msg_size = $args->{RAW_MSG_SIZE};
	for (my $i = 4; $i < $args->{msg_size}; $i += 6){
		my ($ID,$time) = unpack("v V", substr($msg, $i,6));
		my $skillName = (new Skill(idn => $ID))->getName;
		my $status = defined $statusName{'EFST_DELAY'} ? $statusName{'EFST_DELAY'} : ' Delay';
		$char->setStatus($skillName.$status, 1, $time);
	}
}

sub msg_string {
	my ($self, $args) = @_;
	message TF("index: %s para1: %s\n", $args->{index}, $args->{para1}), "info";
	#		'07E2' => ['msg_string', 'v V', [qw(index para1)]], #TODO PACKET_ZC_MSG_VALUE        **msgtable
}

sub skill_msg {
	my ($self, $args) = @_;
	message TF("id: %s msgid: %s\n", $args->{id}, $args->{msgid}), "info";
	
	#	'07E6' => ['skill_msg', 'v V', [qw(id msgid)]], #TODO: PACKET_ZC_MSG_SKILL     **msgtable
}

sub del_packet {
	my ($self, $args) = @_;
}

sub full_or_banned {
	my ($self, $args) = @_;
	message TF("Server full or Banned.\n");
}

sub server_full
{
	my ($self, $args) = @_;
	message TF("Server is full. Please try later.\n");
}

1;
