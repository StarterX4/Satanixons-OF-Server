#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <sdkhooks>
#include <morecolors>
#include <vsh2_of>
#include <tbc>
#include <openfortress>

#undef REQUIRE_PLUGIN
#include <vsh2_achievements>
#include <store>
#include <smac>
#include <tbc_stats>
#include <goomba>
#define REQUIRE_PLUGIN

#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#define REQUIRE_EXTENSIONS

#pragma semicolon			1
#pragma newdecls			required

#define PLUGIN_VERSION 		"2.23"
#define PLUGIN_DESCRIPT  	"VS Saxton Hale 2"
#define CODEFRAMES 			(1.0/30.0)	/* 30 frames per second means 0.03333 seconds or 33.33 ms */

#define IsClientValid(%1) 	( 0 < (%1) && (%1) <= MaxClients && IsClientInGame((%1)) )
#define PLYR 				MAXPLAYERS+1

//Team number defines
#define UNASSIGNED 0
#define NEUTRAL 0
#define SPEC 1
#define RED 2
#define BLU 3

//Python+C style operators
/*#define and				&&
#define and_eq				&=
#define bitand				&
#define bitor				|
#define compl				~
#define not					!
#define not_eq				!=
#define or					||
#define or_eq				|=
#define xor					^
#define xor_eq				^=
#define bitl				<<
#define bitr				>>
#define is					==*/

//functional-style typecasting
#define int(%1) 			view_as<int>(%1)
#define Handle(%1) 			view_as<Handle>(%1)

//misc.
#define nullfunc 			INVALID_FUNCTION
#define nullvec 			NULL_VECTOR
#define nullstr 			NULL_STRING
#define toggle(%1) 			%1 = !%1

#define _buffer(%1) 		%1, sizeof(%1)
#define _strbuffer(%1) 		%1, sizeof(%1)
#define PLYR 				MAXPLAYERS+1
#define PATH 				64
#define FULLPATH 			PLATFORM_MAX_PATH
#define repeat(%1) 			for (int xyz=0; xyz<%1; ++xyz)	// laziness is real lmao

public Plugin myinfo =  {
	name = "TF2Bosses Mod", 
	author = "nergal/assyrian, props to Flamin' Sarge, Chdata, & Buzzkillington", 
	description = "Allows Players to play as various bosses of TF2", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?t=286701"
};

enum/*CvarName*/
{
	PointType = 0, 
	PointDelay, 
	AliveToEnable, 
	FirstRound, 
	DamagePoints, 
	DamageForQueue, 
	QueueGained, 
	EnableMusic, 
	MusicVolume, 
	HealthPercentForLastGuy, 
	HealthRegenForPlayers, 
	HealthRegenAmount, 
	MedigunReset, 
	StopTickleTime, 
	AirStrikeDamage, 
	AirblastRage, 
	JarateRage, 
	FanoWarRage, 
	LastPlayerTime, 
	EngieBuildings, 
	MedievalLives, 
	MedievalRespawnTime, 
	PermOverheal, 
	MultiCapture, 
	MultiCapAmount, 
	DemoShieldCrits, 
	CanBossGoomba, 
	CanMantreadsGoomba, 
	GoombaDamageAdd, 
	GoombaLifeMultiplier, 
	GoombaReboundPower, 
	MultiBossHandicap, 
	DroppedWeapons, 
	BlockEureka, 
	ForceLives, 
	Anchoring, 
	HealthKitLimitMax,
	HealthKitLimitMin,
	AmmoKitLimitMax,
	AmmoKitLimitMin,
	ShieldRegenDmgReq,
	VersionNumber
};

// cvar + handles
ConVar
	bEnabled,
	mp_friendlyfire,
	sv_tags,
	mp_teams_unbalance_limit,
	mp_waitingforplayers_cancel
;

ConVar cvarVSH2[VersionNumber + 1]; //Don't change this. Simply place any new CVARs above VersionNumber in the enum.

Handle
	hHudText, 
	jumpHUD, 
	rageHUD, 
	timeleftHUD
;

Cookie
	PointCookie, 
	MusicCookie,
	QueueCookie,
	DifficultyCookie,
	ckTips,
	VolumeCookie,
	PresetCookie
;

bool
	bMiniStuff,
	bAch,
	bTBC
;

int
	g_iLaserMaterial,
	g_iHaloMaterial
;

//ArrayList ptrBosses ;
ArrayList g_hPluginsRegistered;
ArrayList hFwdCompat[Fwd_OnSoundHook+1];
ArrayList hNoCycle;

#include "modules_of/stocks.inc"
#include "modules_of/handler.sp"	// Contains the game mode logic as well
#include "modules_of/events.sp"
#include "modules_of/commands.sp"
#include "modules_of/wepstats.sp"

public void OnPluginStart()
{
	gamemode = VSHGameMode();
	gamemode.Init();

	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_setspecial", SetNextSpecial, ADMFLAG_RCON);
	RegAdminCmd("sm_halespecial", SetNextSpecial, ADMFLAG_RCON);
	RegAdminCmd("sm_hale_special", SetNextSpecial, ADMFLAG_RCON);
	RegAdminCmd("sm_bossspecial", SetNextSpecial, ADMFLAG_RCON);
	RegAdminCmd("sm_boss_special", SetNextSpecial, ADMFLAG_RCON);
	RegAdminCmd("sm_ff2special", SetNextSpecial, ADMFLAG_RCON);
	RegAdminCmd("sm_ff2_special", SetNextSpecial, ADMFLAG_RCON);
	
	RegConsoleCmd("sm_hale_next", QueuePanelCmd);
	RegConsoleCmd("sm_halenext", QueuePanelCmd);
	RegConsoleCmd("sm_boss_next", QueuePanelCmd);
	RegConsoleCmd("sm_bossnext", QueuePanelCmd);
	RegConsoleCmd("sm_ff2_next", QueuePanelCmd);
	RegConsoleCmd("sm_ff2next", QueuePanelCmd);
	
	RegConsoleCmd("sm_hale_hp", Command_GetHPCmd);
	RegConsoleCmd("sm_halehp", Command_GetHPCmd);
	RegConsoleCmd("sm_boss_hp", Command_GetHPCmd);
	RegConsoleCmd("sm_bosshp", Command_GetHPCmd);
	RegConsoleCmd("sm_ff2_hp", Command_GetHPCmd);
	RegConsoleCmd("sm_ff2hp", Command_GetHPCmd);

	RegConsoleCmd("sm_setboss", SetBossMenu, "Sets your boss.");
	RegConsoleCmd("sm_sethale", SetBossMenu, "Sets your boss.");
	RegConsoleCmd("sm_ff2boss", SetBossMenu, "Sets your boss.");
	RegConsoleCmd("sm_haleboss", SetBossMenu, "Sets your boss.");

	RegConsoleCmd("sm_halemusic", MusicTogglePanelCmd);
	RegConsoleCmd("sm_hale_music", MusicTogglePanelCmd);
	RegConsoleCmd("sm_bossmusic", MusicTogglePanelCmd);
	RegConsoleCmd("sm_boss_music", MusicTogglePanelCmd);
	RegConsoleCmd("sm_ff2music", MusicTogglePanelCmd);
	RegConsoleCmd("sm_ff2_music", MusicTogglePanelCmd);

	RegConsoleCmd("sm_halevolume", VolumeTogglePanelCmd);
	RegConsoleCmd("sm_halevol", VolumeTogglePanelCmd);
	RegConsoleCmd("sm_bossvolume", VolumeTogglePanelCmd);
	RegConsoleCmd("sm_boss_volume", VolumeTogglePanelCmd);
	RegConsoleCmd("sm_ff2volume", VolumeTogglePanelCmd);
	RegConsoleCmd("sm_ff2_volume", VolumeTogglePanelCmd);
	
	RegConsoleCmd("sm_halehelp", HelpPanelCmd);
	RegConsoleCmd("sm_hale_help", HelpPanelCmd);
	RegConsoleCmd("sm_boss_help", HelpPanelCmd);
	RegConsoleCmd("sm_ff2help", HelpPanelCmd);
	RegConsoleCmd("sm_ff2_help", HelpPanelCmd);
	RegConsoleCmd("sm_hale", HelpPanelCmd);
	
	RegAdminCmd("sm_hale_classrush", MenuDoClassRush, ADMFLAG_VOTE, "forces all red players to a class.");
	RegAdminCmd("sm_vsh2_classrush", MenuDoClassRush, ADMFLAG_VOTE, "forces all red players to a class.");
	RegAdminCmd("sm_c_rush", MenuDoClassRush, ADMFLAG_VOTE, "forces all red players to a class.");	
	RegAdminCmd("sm_classrush", MenuDoClassRush, ADMFLAG_VOTE, "forces all red players to a class.");
	
	RegConsoleCmd("sm_resetq", ResetQueue);
	RegConsoleCmd("sm_resetqueue", ResetQueue);
	
	RegAdminCmd("sm_reloadbosscfg", CmdReloadCFG, ADMFLAG_GENERIC);
	RegAdminCmd("sm_hale_select", CommandBossSelect, ADMFLAG_VOTE, "hale_select <target> - Select a player to be next boss.");
	RegAdminCmd("sm_ff2_select", CommandBossSelect, ADMFLAG_VOTE, "ff2_select <target> - Select a player to be next boss.");
	RegAdminCmd("sm_boss_select", CommandBossSelect, ADMFLAG_VOTE, "boss_select <target> - Select a player to be next boss.");
	RegAdminCmd("sm_bs", CommandBossSelect, ADMFLAG_VOTE, "boss_select <target> - Select a player to be next boss.");

	RegAdminCmd("sm_hale_addpoints", CommandAddPoints, ADMFLAG_VOTE);
	RegAdminCmd("sm_vsh2_addpoints", CommandAddPoints, ADMFLAG_VOTE);
	RegAdminCmd("sm_ff2_addpoints", CommandAddPoints, ADMFLAG_VOTE);
	RegAdminCmd("sm_addp", CommandAddPoints, ADMFLAG_VOTE);

	RegAdminCmd("sm_boss_force", ForceBossRealtime, ADMFLAG_VOTE, "boss_force <target> <bossID> - Force a player to the boss team as the specified boss. (Setup time only)");
	RegAdminCmd("sm_hale_force", ForceBossRealtime, ADMFLAG_VOTE, "hale_force <target> <bossID> - Force a player to the boss team as the specified boss. (Setup time only)");
	RegAdminCmd("sm_ff2_force", ForceBossRealtime, ADMFLAG_VOTE, "ff2_force <target> <bossID> - Force a player to the boss team as the specified boss. (Setup time only)");
	RegAdminCmd("sm_bf", ForceBossRealtime, ADMFLAG_VOTE, "ff2_force <target> <bossID> - Force a player to the boss team as the specified boss. (Setup time only)");

//	RegAdminCmd("sm_multiboss", MultiBoss, ADMFLAG_VOTE);
//	RegAdminCmd("sm_multihale", MultiBoss, ADMFLAG_VOTE);
	RegAdminCmd("sm_vshmode", SetGameMode, ADMFLAG_VOTE);

//	RegConsoleCmd("sm_boss_select", BossSelect, "Determine if player receives queue points");
	RegConsoleCmd("sm_haletoggle", BossSelect, "Determine if player receives queue points");
	RegConsoleCmd("sm_hale_toggle", BossSelect, "Determine if player receives queue points");
	RegConsoleCmd("sm_nohale", BossSelect, "Determine if player receives queue points");

	//RegConsoleCmd("sm_vshvote", VSHVote, "Vote for a custom VSH 2 gamemode.");

	RegAdminCmd("sm_giverage", GiveBossRage, ADMFLAG_VOTE);
	RegAdminCmd("sm_makerage", MakeBossRage, ADMFLAG_VOTE);

	RegConsoleCmd("sm_difficulty", BossDifficulty);
	RegConsoleCmd("sm_hardmode", BossDifficulty);

	RegConsoleCmd("sm_tips", TipsToggle);

	RegConsoleCmd("sm_halenew", UpdateList);

	RegAdminCmd("sm_pluglen", g_hPluginsRegisteredLength, ADMFLAG_GENERIC);

	RegAdminCmd("sm_mytype", MyType, ADMFLAG_GENERIC);

	RegConsoleCmd("sm_stuckspec", StuckSpec);
	RegConsoleCmd("sm_specstuck", StuckSpec);

	RegConsoleCmd("sm_wepstats", WepStats);
	RegConsoleCmd("sm_weaponstats", WepStats);

	AddCommandListener(BlockSuicide, "explode");
	AddCommandListener(BlockSuicide, "kill");
	AddCommandListener(BlockSuicide, "jointeam");

	hHudText = CreateHudSynchronizer();
	jumpHUD = CreateHudSynchronizer();
	rageHUD = CreateHudSynchronizer();
	timeleftHUD = CreateHudSynchronizer();

	bEnabled = CreateConVar("vsh2_enabled", "1", "Enable VSH 2 plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarVSH2[VersionNumber] = CreateConVar("vsh2_version_number", PLUGIN_VERSION, "VSH 2 Plugin Version Number. (DO NOT TOUCH)", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_CHEAT);
	cvarVSH2[PointType] = CreateConVar("vsh2_point_type", "0", "Select condition to enable point (0 - alive players, 1 - time)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarVSH2[PointDelay] = CreateConVar("vsh2_point_delay", "6", "Addition (for each player) delay before point's activation.", FCVAR_NOTIFY);
	cvarVSH2[AliveToEnable] = CreateConVar("vsh2_point_alive", "5", "Enable control points when there are X people left alive.", FCVAR_NOTIFY, true, 1.0, true, 32.0);
	cvarVSH2[FirstRound] = CreateConVar("vsh2_firstround", "0", "If 1, allows the first round to start with VSH2 enabled.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarVSH2[DamagePoints] = CreateConVar("vsh2_damage_points", "600", "Amount of damage needed to gain 1 point on the scoreboard.", FCVAR_NOTIFY, true, 1.0);
	cvarVSH2[DamageForQueue] = CreateConVar("vsh2_damage_queue", "1", "Allow damage to influence increase of queue points.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarVSH2[QueueGained] = CreateConVar("vsh2_queue_gain", "10", "How many queue points to give at the end of each round.", FCVAR_NOTIFY, true, 0.0, true, 9999.0);
	cvarVSH2[EnableMusic] = CreateConVar("vsh2_enable_music", "1", "Enable or disable background music.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarVSH2[MusicVolume] = CreateConVar("vsh2_music_volume", "0.5", "How loud the background music should be, if enabled.", FCVAR_NOTIFY, true, 0.0, true, 20.0);
	cvarVSH2[HealthPercentForLastGuy] = CreateConVar("vsh2_health_percentage_last_guy", "51", "If the health bar is lower than x out of 255, the last player timer will stop.", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	cvarVSH2[HealthRegenForPlayers] = CreateConVar("vsh2_health_regen", "0", "Allow non-boss and non-minion players to have passive health regen.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarVSH2[HealthRegenAmount] = CreateConVar("vsh2_health_regen_amount", "2.0", "If health regen is enabled, how much health regen per second should players get?", FCVAR_NOTIFY);
	cvarVSH2[MedigunReset] = CreateConVar("vsh2_medigun_reset_amount", "0.31", "How much Uber percentage should Mediguns, after Uber, reset to?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarVSH2[StopTickleTime] = CreateConVar("vsh2_stop_tickle_time", "3.0", "How long in seconds the tickle effect from the Holiday Punch lasts before being removed.", FCVAR_NOTIFY, true, 0.01);
	cvarVSH2[AirStrikeDamage] = CreateConVar("vsh2_airstrike_damage", "200", "How much damage needed for the Airstrike to gain +1 clipsize.", FCVAR_NOTIFY);
	cvarVSH2[AirblastRage] = CreateConVar("vsh2_airblast_rage", "8.0", "How much Rage should airblast give/remove? (negative number to remove rage)", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	cvarVSH2[JarateRage] = CreateConVar("vsh2_jarate_rage", "8.0", "How much rage should Jarate give/remove? (negative number to add rage)", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	cvarVSH2[FanoWarRage] = CreateConVar("vsh2_fanowar_rage", "5.0", "How much rage should the Fan o' War give/remove? (negative number to add rage)", FCVAR_NOTIFY);
	cvarVSH2[LastPlayerTime] = CreateConVar("vsh2_lastplayer_time", "180", "How many seconds to give the last player to fight the Boss(es) before a stalemate.", FCVAR_NOTIFY);
	cvarVSH2[EngieBuildings] = CreateConVar("vsh2_killbuilding_engiedeath", "1", "If 0, no building dies when engie dies. If 1, only sentry dies. If 2, all buildings die.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	cvarVSH2[MedievalLives] = CreateConVar("vsh2_medievalmode_lives", "3", "Amount of lives red players are entitled during Medieval Mode.", FCVAR_NOTIFY, true, 0.0, true, 99.0);
	cvarVSH2[MedievalRespawnTime] = CreateConVar("vsh2_medievalmode_respawntime", "5.0", "How long it takes for players to respawn after dying in medieval mode (if they have live left).", FCVAR_NOTIFY, true, 1.0, true, 999.0);
	cvarVSH2[PermOverheal] = CreateConVar("vsh2_permanent_overheal", "0", "If enabled, Mediguns give permanent overheal.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarVSH2[MultiCapture] = CreateConVar("vsh2_multiple_cp_captures", "0", "If enabled, allow control points to be captured more than once instead of ending the round instantly.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarVSH2[MultiCapAmount] = CreateConVar("vsh2_multiple_cp_capture_amount", "3", "If vsh2_allow_multiple_cp_captures is enabled, how many times must a team capture a Control Point to win.", FCVAR_NOTIFY, true, 1.0, true, 999.0);
	cvarVSH2[DemoShieldCrits] = CreateConVar("vsh2_demoman_shield_crits", "1", "Sets Demoman Shield crit behaviour. 0 - No crits, 1 - Mini-crits, 2 - Crits, 3 - Scale with Charge Meter (Losing the Shield results in no more (mini)crits.)", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	cvarVSH2[CanBossGoomba] = CreateConVar("vsh2_goomba_can_boss_stomp", "0", "Can the Boss Goomba Stomp other players? (Requires Goomba Stomp plugin). NOTE: All the CVARs in VSH2 controlling Goomba damage, lifemultiplier and rebound power are for NON-BOSS PLAYERS STOMPING THE BOSS. If you enable this CVAR, use the Goomba Stomp plugin config file to control the Boss' Goomba Variables. Not recommended to enable this unless you've coded your own Goomba Stomp behaviour.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarVSH2[CanMantreadsGoomba] = CreateConVar("vsh2_goomba_can_mantreads_stomp", "0", "Can Soldiers/Demomen Goomba Stomp the Boss while using the Mantreads/Booties? (Requires Goomba Stomp plugin). NOTE: Enabling this may cause 'double' Stomps (Goomba Stomp and Mantreads stomp together).", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarVSH2[GoombaDamageAdd] = CreateConVar("vsh2_goomba_damage_add", "450.0", "How much damage to add to a Goomba Stomp on the Boss. (Requires Goomba Stomp plugin).", FCVAR_NOTIFY, true, 0.0, false);
	cvarVSH2[GoombaLifeMultiplier] = CreateConVar("vsh2_goomba_boss_life_multiplier", "0.025", "What percentage of the Boss' CURRENT HP to deal as damage on a Goomba Stomp. (Requires Goomba Stomp plugin).", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarVSH2[GoombaReboundPower] = CreateConVar("vsh2_rebound_power", "300.0", "How much upwards velocity (in Hammer Units) should players recieve upon Goomba Stomping the Boss? (Requires Goomba Stomp plugin).", FCVAR_NOTIFY, true, 0.0, false);
	cvarVSH2[MultiBossHandicap] = CreateConVar("vsh2_multiboss_handicap", "500", "How much Health is removed on every individual boss in a multiboss round at the start of said round. 0 disables it.", FCVAR_NONE, true, 0.0, true, 99999.0);
	cvarVSH2[DroppedWeapons] = CreateConVar("vsh2_allow_dropped_weapons", "0", "Enables/Disables dropped weapons. Recommended to keep this disabled to avoid players having weapons they shouldn't.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarVSH2[BlockEureka] = CreateConVar("vsh2_allow_eureka_effect", "0", "Enables/Disables the Eureka Effect for Engineers", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarVSH2[ForceLives] = CreateConVar("vsh2_force_player_lives", "0", "Forces the gamemode to apply Medieval Mode lives on players, whether or not medieval mode is enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarVSH2[Anchoring] = CreateConVar("vsh2_allow_boss_anchor", "1", "When enabled, reduces all knockback bosses experience when crouching.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarVSH2[HealthKitLimitMax] = CreateConVar("vsh2_spawn_health_kit_limit_max", "4", "max amount of health kits that can be produced in RED spawn. 0 for unlimited amount", FCVAR_NONE, true, 0.0, true, 50.0);
	cvarVSH2[HealthKitLimitMin] = CreateConVar("vsh2_spawn_health_kit_limit_min", "3", "minimum amount of health kits that can be produced in RED spawn. 0 for no minimum limit", FCVAR_NONE, true, 0.0, true, 50.0);
	cvarVSH2[AmmoKitLimitMax] = CreateConVar("vsh2_spawn_ammo_kit_limit_max", "4", "max amount of ammo kits that can be produced in RED spawn. 0 for unlimited amount", FCVAR_NONE, true, 0.0, true, 50.0);
	cvarVSH2[AmmoKitLimitMin] = CreateConVar("vsh2_spawn_ammo_kit_limit_min", "3", "minimum amount of ammo kits that can be produced in RED spawn. 0 for no minimum limit", FCVAR_NONE, true, 0.0, true, 50.0);
	cvarVSH2[ShieldRegenDmgReq] = CreateConVar("vsh2_shield_regen_damage", "9001", "damage required for demoknights to regenerate their shield, put 0 to disable.", FCVAR_NONE, true, 0.0, true, 99999.0);

	#if defined _steamtools_included
	gamemode.bSteam = LibraryExists("SteamTools");
	#endif
	#if defined _tf2attributes_included
	gamemode.bTF2Attribs = LibraryExists("tf2attributes");
	#endif
	AutoExecConfig(true, "VSHv2");
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	HookEvent("player_hurt", PlayerHurt, EventHookMode_Pre);
	HookEvent("player_hurt", PlayerHurtPost);
	HookEvent("teamplay_round_start", RoundStart);
	HookEvent("teamplay_round_win", RoundEnd);
//	HookEvent("player_spawn", ReSpawn);
//	HookEvent("post_inventory_application", Resupply);
//	HookEvent("object_deflected", ObjectDeflected);
	HookEvent("object_destroyed", ObjectDestroyed, EventHookMode_Pre);
//	HookEvent("player_jarated", PlayerJarated);
	// HookUserMessage(GetUserMessageId("PlayerJarated"), OnPlayerJarated);
	//HookEvent("player_changeclass", ChangeClass);
//	HookEvent("rocket_jump", OnHookedEvent);
//	HookEvent("rocket_jump_landed", OnHookedEvent);
//	HookEvent("sticky_jump", OnHookedEvent);
//	HookEvent("sticky_jump_landed", OnHookedEvent);
//	HookEvent("item_pickup", ItemPickedUp);
	HookEvent("player_chargedeployed", UberDeployed);
	HookEvent("arena_round_start", ArenaRoundStart, EventHookMode_Pre);
	HookEvent("teamplay_round_active", ArenaRoundStart, EventHookMode_Pre);
	HookEvent("teamplay_point_captured", PointCapture, EventHookMode_Post);
	HookEvent("teamplay_broadcast_audio", BroadcastAudio, EventHookMode_Pre);
	HookEvent("player_healed", PlayerHealed, EventHookMode_Pre);
	HookEvent("player_team", OnJoinTeam, EventHookMode_Pre);
	HookEvent("player_jump", OnPlayerJump,  EventHookMode_Pre);

	AddCommandListener(DoTaunt, "taunt");
	AddCommandListener(DoTaunt, "+taunt");
	AddCommandListener(cdVoiceMenu, "voicemenu");
	AddCommandListener(JoinTeam, "jointeam");
	AddNormalSoundHook(SoundHook);

	PointCookie = new Cookie("vsh2_queuepoints", "Amount of VSH2 Queue points a player has.", CookieAccess_Protected);
	MusicCookie = new Cookie("vsh2_music_settings", "HaleMusic setting.", CookieAccess_Public);
	QueueCookie = new Cookie("vsh2_queueset", "Determines whether or not player receives queue points.", CookieAccess_Protected);
	DifficultyCookie = new Cookie("vsh2_difficulty", "Determines the difficulty of boss play", CookieAccess_Protected);
	ckTips = new Cookie("vsh2_tips", "Chat advertisement cookie.", CookieAccess_Protected);
	VolumeCookie = new Cookie("vsh2_music_vol", "VSH2 HaleMusic volume", CookieAccess_Protected);
	PresetCookie = new Cookie("vsh_preset_type", "VSH2 Preset boss", CookieAccess_Protected);
	
	//ManageDownloads(); // in handler.sp

	for (int i = MaxClients; i; --i) 
	{
		if (IsClientConnected(i))
			OnClientConnected(i);
		if (IsClientInGame(i))
			OnClientPutInServer(i);
	}
	
	AddMultiTargetFilter("@boss", HaleTargetFilter, "the current Boss/Bosses", false);
	AddMultiTargetFilter("@hale", HaleTargetFilter, "the current Boss/Bosses", false);
	AddMultiTargetFilter("@!boss", HaleTargetFilter, "all non-Boss players", false);
	AddMultiTargetFilter("@!hale", HaleTargetFilter, "all non-Boss players", false);
	
	hPlayerFields[0] = new StringMap(); // This will be freed when plugin is unloaded again
	g_hPluginsRegistered = new ArrayList();

	bAch = LibraryExists("VSH2Ach");
	bTBC = LibraryExists("tbc_stats");

	BuildWepMenus();
	mp_friendlyfire = FindConVar("mp_friendlyfire");
	sv_tags = FindConVar("sv_tags");
	sv_tags.Flags &= ~FCVAR_NOTIFY;
	mp_teams_unbalance_limit = FindConVar("mp_teams_unbalance_limit");
	mp_waitingforplayers_cancel = FindConVar("mp_waitingforplayers_cancel");
}

public bool HaleTargetFilter(const char[] pattern, ArrayList clients)
{
	bool non = StrContains(pattern, "!", false)!= - 1;
	for (int i = MaxClients; i; i--) {
		if (IsClientValid(i) && clients.FindValue(i) == - 1)
		{
			if (bEnabled.BoolValue && BaseBoss(i).bIsBoss) {
				if (!non)
					clients.Push(i);
			}
			else if (non)
				clients.Push(i);
		}
	}
	return true;
}

public Action BlockSuicide(int client, const char[] command, int argc)
{
	if (bEnabled.BoolValue && gamemode.iRoundState == StateRunning)
	{
		BaseBoss player = BaseBoss(client);
		if (player.bIsBoss) {
			float flhp_percent = player.iHealth / float(player.iMaxHealth);
			if (flhp_percent > 0.75)
			{
				CPrintToChat(client, "{salmon}Nope.avi. Type /resetq or /haletoggle next time.");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public void OnAllPluginsLoaded()
{
	bMiniStuff = LibraryExists("tf_ontakedamage");
	bAch = LibraryExists("VSH2Ach");
}

public void OnLibraryAdded(const char[] name)
{
	#if defined _steamtools_included
	if (!strcmp(name, "SteamTools", false))
		gamemode.bSteam = true;
	#endif
	#if defined _tf2attributes_included
	if (!strcmp(name, "tf2attributes", false))
		gamemode.bTF2Attribs = true;
	#endif
	if (!strcmp(name, "tf_ontakedamage", false))
		bMiniStuff = true;
	else if (!strcmp(name, "VSH2Ach", false))
		bAch = true;
	else if (!strcmp(name, "tbc_stats", false))
		bTBC = true;
}

public void OnLibraryRemoved(const char[] name)
{
	#if defined _steamtools_included
	if (!strcmp(name, "SteamTools", false))
		gamemode.bSteam = false;
	#endif
	#if defined _tf2attributes_included
	if (!strcmp(name, "tf2attributes", false))
		gamemode.bTF2Attribs = false;
	#endif
	if (!strcmp(name, "tf_ontakedamage", false))
		bMiniStuff = false;
	else if (!strcmp(name, "VSH2Ach", false))
		bAch = false;
	else if (!strcmp(name, "tbc_stats", false))
		bTBC = false;
}

int
tf_arena_use_queue, 
imp_teams_unbalance_limit, 
mp_forcecamera
;

public void OnGameFrame()
{
	mp_waitingforplayers_cancel.SetInt(1);
}

public void OnConfigsExecuted()
{
	//Config checker taken from VSH1
	/*static char szOldVersion[PATH];
	cvarVSH2[VersionNumber].GetString(_strbuffer(szOldVersion));
	if (StrEqual(szOldVersion, PLUGIN_VERSION))
		LogError("[VSH2] Warning: your config may be outdated. Back up your tf/cfg/sourcemod/VSHv2.cfg file and delete it, and this plugin will generate a new one that you can then modify to your original values.");
	cvarVSH2[VersionNumber].SetString(PLUGIN_VERSION, false, true);*/
	
	tf_arena_use_queue = FindConVar("tf_arena_use_queue").IntValue;
	imp_teams_unbalance_limit = mp_teams_unbalance_limit.IntValue;
//	tf_arena_first_blood = FindConVar("tf_arena_first_blood").IntValue;
	mp_forcecamera = FindConVar("mp_forcecamera").IntValue;
//	tf_scout_hype_pep_max = FindConVar("tf_scout_hype_pep_max").FloatValue;
	FindConVar("tf_arena_use_queue").SetInt(0);
	FindConVar("mp_teams_unbalance_limit").SetInt(0);
	FindConVar("mp_teams_unbalance_limit").SetInt(cvarVSH2[FirstRound].BoolValue ? 0 : 1);
//	FindConVar("tf_arena_first_blood").SetInt(0);
	FindConVar("mp_forcecamera").SetInt(0);
	FindConVar("mp_waitingforplayers_cancel").SetInt(1);
//	FindConVar("tf_scout_hype_pep_max").SetFloat(100.0);
//	FindConVar("tf_feign_death_activate_damage_scale").SetFloat(0.25);
//	FindConVar("tf_feign_death_damage_scale").SetFloat(0.25);
//	FindConVar("tf_stealth_damage_reduction").SetFloat(0.25);
	//FindConVar("tf_damage_disablespread").SetInt(1);
	#if defined _steamtools_included
	if (gamemode.bSteam)
	{
		char gameDesc[64];
		Format(gameDesc, sizeof(gameDesc), "%s (v%s)", PLUGIN_DESCRIPT, PLUGIN_VERSION);
		Steam_SetGameDescription(gameDesc);
	}
	#endif
}

public void OnClientConnected(int client)
{
	if (hPlayerFields[client] != null)
		delete hPlayerFields[client];
	
	hPlayerFields[client] = new StringMap();
	hPlayerFields[client].SetValue("iDifficulty", 0);
	hPlayerFields[client].SetValue("iQueue", 0);
	hPlayerFields[client].SetValue("flMusicVolume", 0.0);
	hPlayerFields[client].SetValue("flMusicTime", 0.0);
	hPlayerFields[client].SetValue("iPresetType", -1);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKHook(client, SDKHook_TraceAttack, TraceAttack);
	SDKHook(client, SDKHook_Touch, OnTouch);
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
	
	flHolstered[client][0] = flHolstered[client][1] = flHolstered[client][2] = 0.0;
	SDKHook(client, SDKHook_PreThinkPost, OnPreThinkPost);
	
	BaseBoss boss = BaseBoss(client);
	
	// BaseFighter properties
	boss.iKills = 0;
	boss.iKillCount = 0;
	boss.iRespawnTime = -1;
//	boss.iPresetType = -1;
	boss.iHits = 0;
	boss.iLives = 0;
	boss.iState = -1;
	boss.iDamage = 0;
	boss.iAirDamage = 0;
	boss.iSongPick = 0;
	boss.iOwnerBoss = 0;
	boss.iUberTarget = 0;
	boss.bIsMinion = false;
	boss.bInJump = false;
	boss.flGlowtime = 0.0;
	boss.flLastHit = 0.0;
	boss.flLastShot = 0.0;
	boss.iShieldDmg = 0;
	boss.iAirShots = 0;
	boss.iSurvKills = 0;
	
	// BaseBoss properties
	boss.iHealth = 0;
	boss.iMaxHealth = 0;
	boss.iType = -1;
	boss.iPureType = -1;
	boss.iClimbs = 0;
	boss.iStabbed = 0;
	boss.iMarketted = 0;
	//boss.iDifficulty = -1;
	boss.iStreaks = 0;
	boss.iStreakCount = 0;
	boss.iSpecial = 0;
	boss.iSpecial2 = 0;
	boss.iTime = 0;
	boss.bIsBoss = false;
	boss.bSetOnSpawn = false;
	boss.bUsedUltimate = false;
	boss.flSpeed = 0.0;
	boss.flCharge = 0.0;
	boss.flRAGE = 0.0;
	boss.flWeighDown = 0.0;
	boss.flSpecial = 0.0;
	boss.flSpecial2 = 0.0;

	delete boss.hSpecial;
}

public void OnClientDisconnect(int client)
{
	ManageDisconnect(client);
}
public void OnClientPostAdminCheck(int client)
{
	SetPawnTimer(HelpMsg, 5.0, client);
	if (gamemode.iSpecialRound & ROUND_SURVIVAL)
	{
		BaseBoss player = BaseBoss(client);
		player.iRespawnTime = 11;
		SetPawnTimer(DoRespawn, 1.0, player);
	}
}

public void OnClientCookiesCached(int client)
{
	BaseBoss player = BaseBoss(client);

	char ck[8]; DifficultyCookie.Get(client, ck, sizeof(ck));
	player.iStartingDifficulty = StringToInt(ck);

	ck[0] = '\0';
	VolumeCookie.Get(client, ck, sizeof(ck));
	if (ck[0] == '\0')
	{
		VolumeCookie.Set(client, "1.0");
		player.flMusicVolume = 1.0;
	}
	else player.flMusicVolume = StringToFloat(ck);
	player.flMusicTime = GetGameTime()+5.0;

	ck[0] = '\0';
	PresetCookie.Get(client, ck, sizeof(ck));
	if (ck[0] == '\0')
		PresetCookie.Set(client, "-1");
}

public void HelpMsg(const int client)
{
	if (IsClientInGame(client))
		CPrintToChat(client, "{olive}[VSH 2]{default} Welcome to {olive}The Brew Crew's Custom VSH{default}, type {lightgreen}/halehelp{default} or {lightgreen}/helpmenu{default} for help!");
}

public Action OnTouch(int client, int other)
{
	if (0 < other <= MaxClients)
	{
		BaseBoss player = BaseBoss(client);
		BaseBoss victim = BaseBoss(other);

		if (player.bIsBoss)// && !victim.bIsBoss)
			ManageOnTouchPlayer(player, victim); // in handler.sp
	}
	else if (other > MaxClients) {
		BaseBoss player = BaseBoss(client);
		if (IsValidEntity(other) && player.bIsBoss)
		{
			char ent[5];
			if ( GetEntityClassname(other, ent, sizeof(ent)), !StrContains(ent, "obj_") )
			{
				if (GetEntProp(other, Prop_Send, "m_iTeamNum") != GetClientTeam(client))
					ManageOnTouchBuilding(player, other); // in handler.sp
			}
		}
	}
	return Plugin_Continue;
}

public void OnMapStart()
{
	g_iLaserMaterial = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloMaterial = PrecacheModel("materials/sprites/halo01.vmt");
	ManageDownloads(); // in handler.sp
	//gamemode.hMusic = null;
	CreateTimer(0.1, Timer_PlayerThink, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(5.0, MakeModelTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	gamemode.iRoundCount = 0;
	gamemode.iMulti = 1;
	gamemode.ToggleTriggerList();

	CreateTimer(120.0, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	bMiniStuff = LibraryExists("tf_ontakedamage");

	if (FindEntityByClassname(-1, "tf_logic_arena") == -1)
		DispatchSpawn(CreateEntityByName("tf_logic_arena"));
}

public void OnMapEnd()
{
	FindConVar("tf_arena_use_queue").SetInt(tf_arena_use_queue);
	mp_teams_unbalance_limit.SetInt(imp_teams_unbalance_limit);
	FindConVar("mp_forcecamera").SetInt(mp_forcecamera);
}

public void OnPluginEnd()
{
	StopBackGroundMusic();
}

public void _MakePlayerBoss(const int userid)
{
	int client = GetClientOfUserId(userid);
	if (client && IsClientInGame(client))
	{
		BaseBoss player = BaseBoss(client);
		ManageBossTransition(player, false); // in handler.sp; sets health, model, and equips the boss
	}
}

public void _MakePlayerMinion(const int userid)
{
	int client = GetClientOfUserId(userid);
	if( client && IsClientInGame(client) )
	{
		BaseBoss player = BaseBoss(client);
		ManageMinionTransition(player);	// in handler.sp; sets health, model, and equips the boss
	}
}

public void _BossDeath(const int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsClientValid(client))
	{
		BaseBoss player = BaseBoss(client);
		if (player.iHealth <= 0)
			player.iHealth = 0; //ded, not big soup rice!
		
		ManageBossDeath(player); // in handler.sp
	}
}
public Action MakeModelTimer(Handle hTimer)
{
	BaseBoss player;
	for (int i = MaxClients; i; --i) 
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		player = BaseBoss(i);
		if (player.bIsBoss)
			ManageBossModels(player); // in handler.sp
	}
	return Plugin_Continue;
}
public void SetGravityNormal(const int userid)
{
	int i = GetClientOfUserId(userid);
	if (IsClientValid(i))
		SetEntityGravity(i, 1.0);
}
public Action Timer_PlayerThink(Handle hTimer) //the main 'mechanics' of bosses
{
	if (!bEnabled.BoolValue || gamemode.iRoundState != StateRunning)
		return Plugin_Continue;

	gamemode.UpdateBossHealth();
	
	BaseBoss player;
	for (int i = MaxClients; i; --i)
	{
		if (!IsClientInGame(i))
			continue;
		
		player = BaseBoss(i);
		if (player.bIsBoss) { /* If player is a boss, force Boss think on them; if not boss or on blue team, force fighter think! */
			ManageBossThink(player); // in handler.sp
			SetEntityHealth(i, player.iHealth);
			if (player.iHealth <= 0) // BUG PATCH: Bosses are not being 100% dead when the iHealth is at 0...
				SDKHooks_TakeDamage(player.index, 0, 0, 100.0, DMG_DIRECT, _, _, _); //ForcePlayerSuicide(i);
		}
		else ManageFighterThink(player);

		_MusicPlay(player);
	}
	if (gamemode.iSpecialRound & ROUND_HVH)
	{
		int numbosses[2];
		for (int i = MaxClients; i; --i)
		{
			if (!IsClientInGame(i) || !IsPlayerAlive(i))
				continue;

			player = BaseBoss(i);
			if (player.bIsBoss)
				++numbosses[GetClientTeam(i)-2];
		}

		if (!numbosses[0])
			ForceTeamWin(BLU);
		else if (!numbosses[1])
			ForceTeamWin(RED);
	}
	else if (!gamemode.CountBosses(true)) // If there's no active, living bosses, then force RED to win
		ForceTeamWin(gamemode.iOtherTeam);

	return Plugin_Continue;
}

public Action Timer_Announce(Handle timer)
{
	static int announcecount = 0;
	announcecount++;
	char strAnnounce[256];
	switch (announcecount)
	{
		case 1:strcopy(strAnnounce, sizeof(strAnnounce), "You can set your {red}Boss Difficulty{default} by typing {red}/difficulty{default}.");
		case 2:strcopy(strAnnounce, sizeof(strAnnounce), "Don't want to be a Boss? Type {green}/haletoggle{default} to set your boss selection preferences.");
		case 3:strcopy(strAnnounce, sizeof(strAnnounce), "You can turn boss themes on/off with {orange}/halemusic{default}.");
		case 4:strcopy(strAnnounce, sizeof(strAnnounce), "Type {unique}/haledmg{default} for the customizeable damage tracker menu.");
		case 5:strcopy(strAnnounce, sizeof(strAnnounce), "By {green}Nergal/Assyrian{default}, {aqua}Starblaster64{default}, and {unusual}Scag/Ragenewb{default}.");
		case 6:
		{
			announcecount = 0;
			strcopy(strAnnounce, sizeof(strAnnounce), "You can toggle these annoying chat advertisements off with {orange}/tips{default}.");
		}
	}
	char strCookie[6];
	for (int i = MaxClients; i; --i)
	{
		if (!IsClientInGame(i))
			continue;
		if (!AreClientCookiesCached(i))
			continue;
		GetClientCookie(i, ckTips, strCookie, sizeof(strCookie));
		if (StringToInt(strCookie) == 1)
			continue;
		CPrintToChat(i, "{olive}[VSH 2]{default} %s", strAnnounce);
	}
	return Plugin_Continue;
}

public Action CmdReloadCFG(int client, int args)
{
	ServerCommand("sm_rcon exec sourcemod/VSHv2.cfg");
	ReplyToCommand(client, "**** Reloading VSH 2 ConVar Config ****");
	return Plugin_Handled;
}
public void OnPreThinkPost(int client)
{
	if (!bEnabled.BoolValue)
		return;
	if (IsClientObserver(client) || !IsPlayerAlive(client))
		return;
	
	//BaseBoss player = BaseBoss(client);
	if (IsNearSpencer(client)) 
	{
		if (TF2_IsPlayerInCondition(client, TFCond_Cloaked)) 
		{
			float cloak = GetEntPropFloat(client, Prop_Send, "m_flCloakMeter") - 0.5;
			if (cloak < 0.0)
				cloak = 0.0;
			SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", cloak);
		}
	}
}

public Action TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (!bEnabled.BoolValue)
		return Plugin_Continue;
	
	if (IsClientValid(attacker) && IsClientValid(victim)) {
		BaseBoss player = BaseBoss(victim);
		BaseBoss enemy = BaseBoss(attacker);
		return ManageTraceHit(player, enemy, inflictor, damage, damagetype, ammotype, hitbox, hitgroup); // in handler.sp
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int & attacker, int & inflictor, float & damage, int & damagetype, int & weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!bEnabled.BoolValue || !IsClientValid(victim))
		return Plugin_Continue;
	BaseBoss BossVictim = BaseBoss(victim);
	int bFallDamage = (damagetype & DMG_FALL);

	if (BossVictim.bIsBoss && attacker <= 0 && bFallDamage) 
	{
		damage = (BossVictim.iHealth > 100) ? 1.0 : 30.0;
		return Plugin_Changed;
	}

	if (BossVictim.bIsBoss) // in handler.sp
		return ManageOnBossTakeDamage(BossVictim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);

	if (!IsClientValid(attacker)) // BUG PATCH: Client index 0 is invalid
		return Plugin_Continue;

	BaseBoss BossAttacker = BaseBoss(attacker);
	if (BossAttacker.bIsBoss) // in handler.sp
		return ManageOnBossDealDamage(BossVictim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);

	return Plugin_Continue;
}

public Action OnTakeDamageAlive(int victim, int & attacker, int & inflictor, float & damage, int & damagetype, int & weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!(0 < attacker <= MaxClients))
		return Plugin_Continue;

	BaseBoss fighter = BaseBoss(attacker);

	if (fighter.bIsBoss)
	{
		Action act;
		if (weapon != -1 && weapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee))
		{
			damage = 202.0;
			if (TF2_GetPlayerClass(victim) == TFClass_Spy) //eggs probably do melee damage to spies, then? That's not ideal, but eh.
				if (TF2_IsPlayerInCondition(victim, TFCond_Cloaked))
					if ((damage > 30.0 && !(damagetype & (DMG_BLAST|DMG_BULLET))) || damagecustom == TF_CUSTOM_BOOTS_STOMP)	// Hacky fix, works though
						damage = 85.0/0.25;
			act = Plugin_Changed;
		}
		return act;
	}
	return Plugin_Continue;
}


#if defined _goomba_included_
public Action OnStomp(int attacker, int victim, float & damageMultiplier, float & damageAdd, float & JumpPower)
{
	if (!bEnabled.BoolValue)
	{
		return Plugin_Continue;
	}
	return ManageOnGoombaStomp(attacker, victim, damageMultiplier, damageAdd, JumpPower);
}
#endif
public Action RemoveEnt(Handle timer, any entid)
{
	int ent = EntRefToEntIndex(entid);
	if (ent > 0 && IsValidEntity(ent))
		AcceptEntityInput(ent, "Kill");
	return Plugin_Continue;
}
public Action cdVoiceMenu(int client, const char[] command, int argc)
{
	if (!bEnabled.BoolValue)
		return Plugin_Continue;
	if (!IsClientInGame(client))
		return Plugin_Continue;
	if (argc < 2 || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	char szCmd1[8]; GetCmdArg(1, szCmd1, sizeof(szCmd1));
	char szCmd2[8]; GetCmdArg(2, szCmd2, sizeof(szCmd2));
	
	// Capture call for medic commands (represented by "voicemenu 0 0")
	BaseBoss boss = BaseBoss(client);
	if (szCmd1[0] == '0' && szCmd2[0] == '0' && boss.bIsBoss)
		return ManageBossTaunt(boss);
	
	return Plugin_Continue;
}
public Action JoinTeam(int client, const char[] command, int argc)
{
	SetPawnTimer(CheckLateSpawn, 0.2, GetClientUserId(client));
}
public Action DoTaunt(int client, const char[] command, int argc)
{
	if (!bEnabled.BoolValue)
		return Plugin_Continue;
	
	BaseBoss boss = BaseBoss(client);
	ManageBossTaunt(boss);
	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!bEnabled.BoolValue)
		return;
	
	ManageEntityCreated(entity, classname);
	
//	if (!strncmp(classname, "tf_weapon_", 10, false) && IsValidEntity(entity))
//		CreateTimer(0.6, OnWeaponSpawned, EntIndexToEntRef(entity));
//	else if (!strncmp(classname, "team_control_point", 18, false))
//		SDKHook(entity, SDKHook_Spawn, KillOnSpawn);
}
public void OnWeaponSwitchPost(int client, int weapon)
{
	static int iActiveSlot[PLYR];
	if ((client > 0 && client <= MaxClients) && IsValidEntity(weapon))
	{
		switch (iActiveSlot[client]) // This will be the previous slot at this time, that you switched FROM
		{
			case 0, 1:flHolstered[client][iActiveSlot[client]] = GetGameTime();
		}
		iActiveSlot[client] = GetSlotFromWeapon(client, weapon);
	}
}
public void ShowPlayerScores() // scores kept glitching out and I hate debugging so I made it its own func.
{
	BaseBoss hTop[3];
	
	BaseBoss(0).iDamage = 0;
	BaseBoss player;
	int fraction = cvarVSH2[DamagePoints].IntValue;
	int i;
	int totaldamage;
	for (i = MaxClients; i; --i) {
		if (!IsClientInGame(i))
			continue;

		if (GetClientTeam(i) < RED)
			continue;
		
		player = BaseBoss(i);
		if (player.bIsBoss) {
			player.iDamage = 0;
			continue;
		}
		
		if (player.iDamage >= hTop[0].iDamage/*Damage[top[0]]*/) {
			hTop[2] = hTop[1];
			hTop[1] = hTop[0];
			hTop[0] = player;
		}
		else if (player.iDamage >= hTop[1].iDamage/*Damage[top[1]]*/) {
			hTop[2] = hTop[1];
			hTop[1] = player;
		}
		else if (player.iDamage >= hTop[2].iDamage/*Damage[top[2]]*/)
			hTop[2] = player;

		totaldamage += player.iDamage;
	}
	if (hTop[0].iDamage > 9000) //if (Damage[top[0]] > 9000)
		SetPawnTimer(OverNineThousand, 1.0); // in stocks.inc

	if (bAch)
	{
		if (totaldamage - hTop[0].iDamage < hTop[0].iDamage)
			VSH2Ach_AddTo(hTop[0].index, A_HurtBack, 1);
	}

	SetHudTextParams(-1.0, 0.4, 10.0, 255, 255, 255, 255);
	PrintCenterTextAll(""); // Should clear center text
	char names[3][32];
	for (i = 0; i < 3; ++i)
		if (hTop[i].index && hTop[i].iDamage > 0)
			GetClientName(hTop[i].index, names[i], 32);
		else names[i] = "N/A";

	for (i = MaxClients; i; --i)
	{
		if (!IsClientInGame(i))
			continue;

		player = BaseBoss(i);
		if (player.iDamage > 9000)
		{
			if (bTBC)
			{
				TBC_GiveCredits(i, 15);
				CPrintToChat(i, STORE_PREFIX ... "You have earned {unique}15{default} Gimgims for getting a 9000 damage round!");
			}

			if (bAch)
				VSH2Ach_AddTo(i, A_Ova9k, 1);
		}

		if (!(GetClientButtons(i) & IN_SCORE))
		{
			ShowHudText(i, -1, "Most damage dealt by:\n1)%i - %s\n2)%i - %s\n3)%i - %s\n\nDamage Dealt: %i\nScore for this round: %i", hTop[0].iDamage, names[0], hTop[1].iDamage, names[1], hTop[2].iDamage, names[2], player.iDamage, (player.iDamage / fraction));
			//PrintToConsole(i, "did damage dealth stuff.");
		}
	}
}
public void CalcScores()
{
	int j, damage, amount, queue;
	BaseBoss player;
	for (int i = MaxClients; i; --i)
	{
		if (!IsClientInGame(i))
			continue;
		else if (GetClientTeam(i) < RED)
			continue;
		
		player = BaseBoss(i);
		if (player.bIsBoss)
			player.iQueue = 0;
		else
		{
			if (player.bQueueOff)
			{
				player.iQueue = 0;
				CPrintToChat(i, "{olive}[VSH 2] Queue{default} You gained 0 queue points because you toggled Boss Selection as {lightgreen}off{default}.");
			}
			else 
			{
				if (cvarVSH2[DamageForQueue].BoolValue)
					queue = cvarVSH2[QueueGained].IntValue + (player.iDamage / 1000);
				else queue = cvarVSH2[QueueGained].IntValue;
				player.iQueue += queue; //(i, GetClientQueuePoints(i)+queue);
				CPrintToChat(i, "{olive}[VSH 2] Queue{default} You gained %i queue points.", queue);
			}

			Event scoring = CreateEvent("player_escort_score", true);
			// We don't want the Bosses getting free points for doing damage.
			damage = player.iDamage;
			scoring.SetInt("player", i);
			amount = cvarVSH2[DamagePoints].IntValue;
			// j = damage/amount;	
			for (j = 0; damage - amount > 0; damage -= amount, j++) {  }
			scoring.SetInt("points", j);
			// scoring.FireToClient(i);
			scoring.Fire();
			CPrintToChat(i, "{olive}[VSH 2] Queue{default} You scored %i points.", j);

			if (bAch)
				VSH2Ach_AddTo(i, A_PointWhore, j);

			if (bTBC)
			{
				TBC_GiveCredits(i, j);
				CPrintToChat(i, TBC_TAG ... "You scored {unique}%d{default} gimgims.", j);
			}
		}
		//PrintToConsole(i, "CalcScores running.");
	}
}

public Action Timer_DrawGame(Handle timer)
{
	int state = gamemode.iRoundState;
	if (state == StateEnding || state == StateStarting)
		return Plugin_Stop;

	if (state == StateRunning && GetLivingPlayers(RED) != 1)
		return Plugin_Stop;
	
	int time = gamemode.iTimeLeft;
	gamemode.iTimeLeft--;
	char strTime[6];
	
	if (time / 60 > 9)
		IntToString(time / 60, strTime, 6);
	else Format(strTime, 6, "0%i", time / 60);
	
	if (time % 60 > 9)
		Format(strTime, 6, "%s:%i", strTime, time % 60);
	else Format(strTime, 6, "%s:0%i", strTime, time % 60);
	
	SetHudTextParams(-1.0, 0.17, 1.1, 255, 255, 255, 255);
	int i;
	for (i = MaxClients; i; --i)
	{
		if (!IsClientInGame(i))
			continue;
		ShowSyncHudText(i, timeleftHUD, strTime);
	}
	switch (time)
	{
		case 60:EmitSoundToAll("vo/announcer_ends_60sec.mp3");
		case 30:EmitSoundToAll("vo/announcer_ends_30sec.mp3");
		case 10:EmitSoundToAll("vo/announcer_ends_10sec.mp3");
		case 1, 2, 3, 4, 5: {
			char sound[FULLPATH];
			Format(sound, FULLPATH, "vo/announcer_ends_%isec.mp3", time);
			EmitSoundToAll(sound);
		}
		case 0: //Thx MasterOfTheXP
		{
			if (state == StateRunning)
			{
				int toset;
				if (gamemode.iSpecialRound & ROUND_HVH)
				{
					int totalhp[2];
					BaseBoss player;
					for (i = MaxClients; i; --i)
					{
						if (!IsClientInGame(i) || !IsPlayerAlive(i))
							continue;

						player = BaseBoss(i);
						if (player.bIsBoss)
							totalhp[GetClientTeam(i)-2] += player.iHealth;
					}
					if (totalhp[0] > totalhp[1])
						toset = RED;
					else if (totalhp[1] > totalhp[0])
						toset = BLU;
				}
				i = CreateEntityByName("game_round_win");
				if (i != -1)
				{
					SetVariantInt(toset);
					AcceptEntityInput(i, "SetTeam");
					AcceptEntityInput(i, "RoundWin");
				}
				else ForceTeamWin(0);
			}
			else ForceTeamWin(0);
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}
public void _ResetMediCharge(const int entid)
{
	int medigun = EntRefToEntIndex(entid);
	if (medigun > MaxClients && IsValidEntity(medigun))
		SetMediCharge(medigun, GetMediCharge(medigun) + 0.2);
}
public Action TimerLazor(Handle timer, any medigunid)
{
	int medigun = EntRefToEntIndex(medigunid);
	if (medigun && IsValidEntity(medigun) && gamemode.iRoundState == StateRunning)
	{
		int client = GetOwner(medigun);
		float charge = GetMediCharge(medigun);
		if (charge > 0.05)
		{
			if (!(gamemode.iSpecialRound & ROUND_HVH))
				TF2_AddCondition(client, TFCond_Kritzkrieged, 0.5);

			int target = GetHealingTarget(client);
			if (IsClientValid(target) && IsPlayerAlive(target))
			{
				BaseBoss(client).iUberTarget = GetClientUserId(target);
				if (!(gamemode.iSpecialRound & ROUND_HVH))
					TF2_AddCondition(target, TFCond_Kritzkrieged, 0.2);
				Call_OnUberLoop(BaseBoss(client), BaseBoss(target));
			}
			else BaseBoss(client).iUberTarget = 0;
		}
		else if (charge < 0.05)
		{
			SetPawnTimer(_ResetMediCharge, 3.0, EntIndexToEntRef(medigun)); //CreateTimer(3.0, TimerLazor2, EntIndexToEntRef(medigun));
			return Plugin_Stop;
		}
	}
	else return Plugin_Stop;
	return Plugin_Continue;
}

public void _MusicPlay(const BaseBoss player)
{
	float currtime = GetGameTime();
	if (player.bNoMusic || player.flMusicTime > currtime)
		return;

	if (!cvarVSH2[EnableMusic].BoolValue)
		return;

	char sound[FULLPATH];
	float time = -1.0;

	ManageMusic(sound, time); // in handler.sp
	
	if (sound[0] != '\0') 
	{
		strcopy(BackgroundSong[player.index], FULLPATH, sound);
		EmitSoundToClient(player.index, sound, _, _, SNDLEVEL_NORMAL, SND_NOFLAGS, player.flMusicVolume, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
	}
	if (time != -1.0)
		player.flMusicTime = currtime + time;
}

public void SkipBossPanelNotify(const int client)
{
	if (!bEnabled.BoolValue || IsVoteInProgress())
		return;

	Panel panel = new Panel();
	char strNotify[64];

	panel.SetTitle("[VSH2] You're The Next Boss!");
	strcopy(strNotify, sizeof(strNotify), "You are going to be a Boss soon! Type /halenext to check/reset your queue points.\nAlternatively, use /resetq.");

	panel.DrawItem(strNotify);
	panel.Send(client, SkipHalePanelH, 30);
	delete panel;
}

public void SkipHalePanel()
{
	bool added[MAXPLAYERS+1];
	int i, j;
	BaseBoss player;
	do
	{
		player = gamemode.FindNextBossEx(added);
		if (player.index >= 0)
			added[player.index] = true;
		if (IsClientValid(player.index) && !player.bIsBoss && !player.bQueueOff)
		{
			if (!IsFakeClient(player.index))
			{
				CPrintToChat(player.index, "{olive}[VSH 2]{default} You are going to be Hale soon! Type {olive}/halenext{default} to check/reset your queue points.");
				if (!i)
					SkipBossPanelNotify(player.index);
			}
			i++;
		}
		j++;
	}
	while (i < 3 && j < MAXPLAYERS+1);
}

public void DoRespawn(const BaseBoss player)
{
	if (!player || !player.index)
		return;

	if (gamemode.iRoundState != StateRunning)
		return;

	if (GetClientTeam(player.index) == SPEC)
		return;

	if (IsPlayerAlive(player.index))
		return;

	if (player.bIsMinion)
		return;

	player.iRespawnTime--;
	if (!player.iRespawnTime)
	{
		int team = GetClientTeam(player.index);
		if (team <= 1)
			team = RED;

		if (TF2_GetPlayerClass(player.index) == TFClass_Unknown)
			TF2_SetPlayerClass(player.index, view_as< TFClassType >(GetRandomInt(1, 9)));

		if (team <= 1 && (gamemode.iSpecialRound & ROUND_HVH))
		{
			int num[2];
			for (int i = MaxClients; i; --i)
			{
				if (!IsClientInGame(i) || GetClientTeam(i) <= SPEC)
					continue;

				++num[GetClientTeam(i)-2];
			}
			if (num[0] > num[1])
				team = BLU;
			else if (num[1] > num[0])
				team = RED;
			else team = GetRandomInt(RED, BLU);
		}
		player.ForceTeamChange(team);
		return;
	}

	SetHudTextParams(-1.0, 0.4, 1.2, 255, 255, 255, 255);
	ShowSyncHudText(player.index, jumpHUD, "You will respawn in %d second%s.", player.iRespawnTime, player.iRespawnTime == 1 ? "" : "s");
	SetPawnTimer(DoRespawn, 1.0, player);
}

public void DoRush()
{
	if (gamemode.iRoundState != StateRunning)
		return;

	TFClassType class = gamemode.iRush;
	for (int i = MaxClients; i; --i)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		if (BaseBoss(i).bIsBoss)
			continue;

		if (TF2_GetPlayerClass(i) == class)
		{
			PrepPlayers(BaseBoss(i));
			continue;
		}

		TF2_SetPlayerClass(i, class);
		TF2_RegeneratePlayer(i);
		SetPawnTimer(PrepPlayers, 0.2, GetClientUserId(i));
	}
}

public int VSH2GetRandomInt(int low, int high)
{
	int boss = GetRandomInt(low, high);
	return hNoCycle.FindValue(boss) != -1 ? VSH2GetRandomInt(low, high) : boss;
}

public Action KillOnSpawn(int ent)
{
	RemoveEntity(ent);
	return Plugin_Handled;
}

public void GiveBackRage(const int userid)
{
	BaseBoss base = BaseBoss(userid, true);
	if (base.index && IsClientInGame(base.index))
		if (Call_OnBossGiveBackRage(base) == Plugin_Continue)
			base.flRAGE = 100.0;			
}

public void RemoveRagdoll(int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsClientValid(client))
	{
		int rag = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if (rag > MaxClients && IsValidEntity(rag))
			AcceptEntityInput(rag, "Kill");
	}
}

public Action OnRagSpawn(int ent)
{
	if (!HasEntProp(ent, Prop_Send, "m_hOwnerEntity"))
		return Plugin_Continue;
	BaseBoss owner = BaseBoss(GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity"));
	if (IsClientValid(owner.index) && owner.bNoRagdoll)
	{
		RemoveEntity(ent);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action BVBGlowTransmit(int ent, int other)
{
	int owner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	if (owner == other)
		return Plugin_Handled;
	return GetClientTeam(owner) == GetClientTeam(other) ? Plugin_Continue : Plugin_Handled;
}

public void FixRagdolls(BaseBoss boss)
{
	if (!boss.index)
		return;

	int rag = GetEntPropEnt(boss.index, Prop_Send, "m_hRagdoll");
	if (rag > MaxClients && IsValidEntity(rag))
		AcceptEntityInput(rag, "Kill");
}

public void CheckLateSpawn(int userid)
{
	int client = GetClientOfUserId(userid);
	if (client && IsPlayerAlive(client))
		ForcePlayerSuicide(client);
}

public void SetTeam(int ref)
{
	if (IsValidEntity(ref))
	{
		SetVariantInt(0);
		AcceptEntityInput(ref, "SetTeam");
	}
}

/*public Action Timer_MusicTheme(Handle timer, DataPack pack)
{
	if (bEnabled.BoolValue and gamemode.iRoundState is StateRunning)
	{
		char music[FULLPATH];
		pack.Reset();
		pack.ReadString(music, sizeof(music));
		//float time = pack.ReadFloat();
		BaseBoss boss;
		float vol = cvarVSH2[MusicVolume].FloatValue;
		if (music[0] != '\0') {
			for (int i=MaxClients ; i ; --i) {
				if (!IsClientValid(i))
					continue;
				boss = BaseBoss(i);
				if (boss.bNoMusic)
					continue;
				EmitSoundToClient(i, music, _, _, SNDLEVEL_NORMAL, SND_NOFLAGS, vol, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
			}
		}
	}
	//else gamemode.hMusic = null;
	return Plugin_Continue;
}*/

stock StringMap FindPluginByName(const char name[64]) // searches in linear time or O(n) but it only searches when vsh plugin's loaded
{
	char dictVal[64];
	StringMap pluginMap;
	int arraylen = g_hPluginsRegistered.Length;
	for (int i = 0; i < arraylen; ++i) {
		pluginMap = g_hPluginsRegistered.Get(i);
		if (pluginMap.GetString("PluginName", dictVal, 64))
			if (!strcmp(name, dictVal, false)) 
				return pluginMap;
	}
	return null;
}

stock Handle GetPluginByIndex(const int index)
{
	Handle thisPlugin;
	StringMap pluginMap = g_hPluginsRegistered.Get(index);
	if (pluginMap.GetValue("PluginHandle", thisPlugin))
		return thisPlugin;
	return null;
}

public int RegisterPlugin(const Handle pluginhndl, const char modulename[64])
{
	if( !ValidateName(modulename) ) {
		LogError("VSH2 :: Register Plugin  **** Invalid Name For Plugin Registration ****");
		return -1;
	}
	StringMap PluginMap;
	if( (PluginMap = FindPluginByName(modulename)) ) {
		int idx;
		PluginMap.GetValue("BossIndex", idx);
		return idx;
	}
	
	// create dictionary to hold necessary data about plugin
	PluginMap = new StringMap();
	PluginMap.SetValue("PluginHandle", pluginhndl);
	PluginMap.SetString("PluginName", modulename);
	PluginMap.SetValue("BossIndex", MAXBOSS+1);
	
	// push to global vector
	g_hPluginsRegistered.Push(PluginMap);
	return MAXBOSS;	// Return the index of registered plugin!
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	InitializeForwards(); // in forwards.sp

	hFwdCompat[Fwd_OnBossTakeDamage] = new ArrayList();
	hFwdCompat[Fwd_OnBossDealDamage] = new ArrayList();
	hFwdCompat[Fwd_OnSoundHook] = new ArrayList();
	
	hFwdCompat[Fwd_OnBossTakeDamage].Push(Hale);
	hFwdCompat[Fwd_OnBossDealDamage].Push(Hale);
	
	hFwdCompat[Fwd_OnBossTakeDamage].Push(CBS);
	hFwdCompat[Fwd_OnBossDealDamage].Push(CBS);

	hFwdCompat[Fwd_OnBossTakeDamage].Push(HHHjr);
	hFwdCompat[Fwd_OnBossDealDamage].Push(HHHjr);

	hFwdCompat[Fwd_OnBossTakeDamage].Push(Vagineer);
	hFwdCompat[Fwd_OnBossDealDamage].Push(Vagineer);

	hFwdCompat[Fwd_OnBossTakeDamage].Push(Bunny);
	hFwdCompat[Fwd_OnBossDealDamage].Push(Bunny);

	hNoCycle = new ArrayList();

	CreateNative("VSH2_RegisterPlugin", Native_RegisterPlugin);
	CreateNative("VSH2_Hook", Native_Hook);
	CreateNative("VSH2_HookEx", Native_HookEx);
	CreateNative("VSH2_JumpHud", Native_JumpHud);
	CreateNative("VSH2_BossHud", Native_BossHud);
	CreateNative("VSH2_AddToFwdC", Native_AddToTDC);
	CreateNative("VSH2_Self", Native_Self);
	CreateNative("VSH2_UnCycle", Native_UnCycle);

	CreateNative("VSH2_Unhook", Native_Unhook);
	CreateNative("VSH2_UnhookEx", Native_UnhookEx);
	
	CreateNative("VSH2Player.VSH2Player", Native_VSH2Instance);
	
	CreateNative("VSH2Player.userid.get", Native_VSH2GetUserid);
	CreateNative("VSH2Player.index.get", Native_VSH2GetIndex);
	
	CreateNative("VSH2Player.GetProperty", Native_VSH2_getProperty);
	CreateNative("VSH2Player.SetProperty", Native_VSH2_setProperty);
	
	/*CreateNative("VSH2Player.getAmmotable", Native_VSH2_getAmmotable);
	CreateNative("VSH2Player.setAmmotable", Native_VSH2_setAmmotable);
	CreateNative("VSH2Player.getCliptable", Native_VSH2_getCliptable);
	CreateNative("VSH2Player.setCliptable", Native_VSH2_setCliptable);*/
	CreateNative("VSH2Player.SetWepInvis", Native_VSH2_SetWepInvis);
	CreateNative("VSH2Player.SetOverlay", Native_VSH2_SetOverlay);
	CreateNative("VSH2Player.TeleToSpawn", Native_VSH2_TeleToSpawn);
	CreateNative("VSH2Player.SpawnSmallHealthPack", Native_VSH2_SpawnSmallHealthPack);
	CreateNative("VSH2Player.ForceTeamChange", Native_VSH2_ForceTeamChange);
	CreateNative("VSH2Player.ClimbWall", Native_VSH2_ClimbWall);
	CreateNative("VSH2Player.ConvertToBoss", Native_VSH2_ConvertToBoss);
	CreateNative("VSH2Player.GiveRage", Native_VSH2_GiveRage);
	CreateNative("VSH2Player.MakeBossAndSwitch", Native_VSH2_MakeBossAndSwitch);
	CreateNative("VSH2Player.DoGenericStun", Native_VSH2_DoGenericStun);
	CreateNative("VSH2Player.DoGenericThink", Native_VSH2_DoGenericThink);
	CreateNative("VSH2Player.PreEquip", Native_VSH2_PreEquip);
	CreateNative("VSH2Player.ReceiveGenericRage", Native_VSH2_ReceiveGenericRage);
	CreateNative("VSH2Player.RemoveGenericRage", Native_VSH2_RemoveGenericRage);
	CreateNative("VSH2Player.iPresetType.get", Native_VSH2_PresetType_Get);
	CreateNative("VSH2Player.iPresetType.set", Native_VSH2_PresetType_Set);
	CreateNative("VSH2Player.hMap.get", Native_VSH2_Map_Get);
	CreateNative("VSH2Player.ConvertToMinion", Native_VSH2_ConvertToMinion);

	CreateNative("VSH2GameMode_GetProperty", Native_VSH2GameMode_GetProperty);
	CreateNative("VSH2GameMode_SetProperty", Native_VSH2GameMode_SetProperty);
	CreateNative("VSH2GameMode_FindNextBoss", Native_VSH2GameMode_FindNextBoss);
	CreateNative("VSH2GameMode_GetRandomBoss", Native_VSH2GameMode_GetRandomBoss);
	CreateNative("VSH2GameMode_GetBossByType", Native_VSH2GameMode_GetBossByType);
	CreateNative("VSH2GameMode_CountBosses", Native_VSH2GameMode_CountBosses);
	CreateNative("VSH2GameMode_GetTotalBossHealth", Native_VSH2GameMode_GetTotalBossHealth);
	CreateNative("VSH2GameMode_SearchForItemPacks", Native_VSH2GameMode_SearchForItemPacks);
	CreateNative("VSH2GameMode_UpdateBossHealth", Native_VSH2GameMode_UpdateBossHealth);
	CreateNative("VSH2GameMode_GetBossType", Native_VSH2GameMode_GetBossType);
	CreateNative("VSH2GameMode_GetTotalRedPlayers", Native_VSH2GameMode_GetTotalRedPlayers);
	CreateNative("VSH2GameMode_GiveBackRage", Native_VSH2GameMode_GiveBackRage);
	CreateNative("VSH2GameMode_MaxBoss", Native_VSH2GameMode_MaxBoss);
	CreateNative("VSH2GameMode_OtherTeam", Native_VSH2GameMode_OtherTeam);

	MarkNativeAsOptional("VSH2Ach_AddTo");
	MarkNativeAsOptional("VSH2Ach_Toggle");

	RegPluginLibrary("VSH2");
	
	return APLRes_Success;
}

public any Native_RegisterPlugin(Handle plugin, int numParams)
{
	char ModuleName[64]; GetNativeString(1, ModuleName, sizeof(ModuleName));
	int plugin_index = RegisterPlugin(plugin, ModuleName); // ALL PROPS TO COOKIES.NET AKA COOKIES.IO
	return plugin_index;
}

public any Native_VSH2Instance(Handle plugin, int numParams)
{
	BaseBoss player = BaseBoss(GetNativeCell(1), GetNativeCell(2));
	return player;
}

public any Native_VSH2GetUserid(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	return player.userid;
}
public any Native_VSH2GetIndex(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	return player.index;
}
public any Native_VSH2_getProperty(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	char prop_name[64]; GetNativeString(2, prop_name, 64);
	any item;
	if (hPlayerFields[player.index].GetValue(prop_name, item))
		return item;
	return 0;
}
public any Native_VSH2_setProperty(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	char prop_name[64]; GetNativeString(2, prop_name, 64);
	any item = GetNativeCell(3);
	hPlayerFields[player.index].SetValue(prop_name, item);
}

public any Native_Hook(Handle plugin, int numParams)
{
	int vsh2Hook = GetNativeCell(1);
	
	Function Func = GetNativeFunction(2);
	if (g_hForwards[vsh2Hook] != null)
		AddToForward(g_hForwards[vsh2Hook], plugin, Func);
}

public any Native_HookEx(Handle plugin, int numParams)
{
	int vsh2Hook = GetNativeCell(1);
	
	Function Func = GetNativeFunction(2);
	if (g_hForwards[vsh2Hook] != null)
		return AddToForward(g_hForwards[vsh2Hook], plugin, Func);
	return 0;
}

public any Native_Unhook(Handle plugin, int numParams)
{
	int vsh2Hook = GetNativeCell(1);
	
	if (g_hForwards[vsh2Hook] != null)
		RemoveFromForward(g_hForwards[vsh2Hook], plugin, GetNativeFunction(2));
}
public any Native_UnhookEx(Handle plugin, int numParams)
{
	int vsh2Hook = GetNativeCell(1);
	
	if (g_hForwards[vsh2Hook] != null)
		return RemoveFromForward(g_hForwards[vsh2Hook], plugin, GetNativeFunction(2));
	return 0;
}

public any Native_VSH2_SetWepInvis(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	int alpha = GetNativeCell(2);
	player.SetWepInvis(alpha);
}

public any Native_VSH2_SetOverlay(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	char overlay[256]; GetNativeString(2, overlay, 256);
	player.SetOverlay(overlay);
}

public any Native_VSH2_TeleToSpawn(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	int team = GetNativeCell(2);
	player.TeleToSpawn(team);
}

public any Native_VSH2_SpawnSmallHealthPack(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	int team = GetNativeCell(2);
	player.SpawnSmallHealthPack(team);
}

public any Native_VSH2_ForceTeamChange(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	int team = GetNativeCell(2);
	player.ForceTeamChange(team);
}

public any Native_VSH2_ClimbWall(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	int wep = GetNativeCell(2);
	float spawntime = view_as<float>(GetNativeCell(3));
	float healthdmg = view_as<float>(GetNativeCell(4));
	bool attackdelay = GetNativeCell(5);
	return player.ClimbWall(wep, spawntime, healthdmg, attackdelay);
}

public any Native_VSH2_ConvertToBoss(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	player.ConvertToBoss();
}

public any Native_VSH2_GiveRage(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	int dmg = GetNativeCell(2);
	player.GiveRage(dmg);
}

public any Native_VSH2_MakeBossAndSwitch(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	int bossid = GetNativeCell(2);
	bool callEvent = GetNativeCell(2);
	player.MakeBossAndSwitch(bossid, callEvent);
}

public any Native_VSH2_DoGenericStun(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	player.DoGenericStun(view_as< float >(GetNativeCell(2)));
}

public any Native_VSH2_DoGenericThink(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	bool jump = GetNativeCell(2);
	bool sound = GetNativeCell(3);
	char sJump[FULLPATH]; GetNativeString(4, sJump, FULLPATH);
	int random = GetNativeCell(5);
	bool mp3 = GetNativeCell(6);
	bool showhud = GetNativeCell(7);
	float weighdowntime = view_as< float >(GetNativeCell(8));
	float vol = view_as< float >(GetNativeCell(9));
	player.DoGenericThink(jump, sound, sJump, random, mp3, showhud, weighdowntime, vol);
}

public any Native_VSH2_PreEquip(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	player.PreEquip();
}

public any Native_VSH2_ReceiveGenericRage(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	player.ReceiveGenericRage();
}

public any Native_VSH2_RemoveGenericRage(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	int other = GetNativeCell(2);
	bool jarate = GetNativeCell(3);
	player.RemoveGenericRage(other, jarate);
}

public any Native_VSH2_PresetType_Get(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	return player.iPresetType;
}

public any Native_VSH2_PresetType_Set(Handle plugin, int numParams)
{
	BaseBoss player = GetNativeCell(1);
	player.iPresetType = GetNativeCell(2);
}

public any Native_VSH2_Map_Get(Handle plugin, int numParams)
{
	return hPlayerFields[GetClientOfUserId(GetNativeCell(1))];
}

public any Native_VSH2_ConvertToMinion(Handle plugin, int numParams)
{
	BaseBoss(GetNativeCell(1)).ConvertToMinion(GetNativeCell(2), GetNativeCell(3));
}

public any Native_VSH2GameMode_GetProperty(Handle plugin, int numParams)
{
	char prop_name[64]; GetNativeString(1, prop_name, 64);
	any item;
	if (hGameModeFields.GetValue(prop_name, item)) {
		return item;
	}
	return 0;
}
public any Native_VSH2GameMode_SetProperty(Handle plugin, int numParams)
{
	char prop_name[64]; GetNativeString(1, prop_name, 64);
	any item = GetNativeCell(2);
	hGameModeFields.SetValue(prop_name, item);
}
public any Native_VSH2GameMode_GetRandomBoss(Handle plugin, int numParams)
{
	bool alive = GetNativeCell(1);
	return gamemode.GetRandomBoss(alive);
}
public any Native_VSH2GameMode_GetBossByType(Handle plugin, int numParams)
{
	bool alive = GetNativeCell(1);
	int bossid = GetNativeCell(2);
	return gamemode.GetBossByType(alive, bossid);
}
public any Native_VSH2GameMode_FindNextBoss(Handle plugin, int numParams)
{
	return gamemode.FindNextBoss();
}
public any Native_VSH2GameMode_CountBosses(Handle plugin, int numParams)
{
	bool alive = GetNativeCell(1);
	return gamemode.CountBosses(alive);
}
public any Native_VSH2GameMode_GetTotalBossHealth(Handle plugin, int numParams)
{
	return gamemode.GetTotalBossHealth();
}
public any Native_VSH2GameMode_SearchForItemPacks(Handle plugin, int numParams)
{
	gamemode.SearchForItemPacks();
}
public any Native_VSH2GameMode_UpdateBossHealth(Handle plugin, int numParams)
{
	gamemode.UpdateBossHealth();
}
public any Native_VSH2GameMode_GetBossType(Handle plugin, int numParams)
{
	gamemode.GetBossType();
}
public any Native_VSH2GameMode_GetTotalRedPlayers(Handle plugin, int numParams)
{
	return gamemode.iPlaying;
}
public any Native_BossHud(Handle plugin, int numParams)
{
	return hHudText;
}
public any Native_JumpHud(Handle plugin, int numParams)
{
	return jumpHUD;
}
public any Native_AddToTDC(Handle plugin, int numParams)
{
	hFwdCompat[GetNativeCell(1)].Push(GetNativeCell(2));
}
public any Native_VSH2GameMode_GiveBackRage(Handle plugin, int numParams)
{
	RequestFrame(GiveBackRage, GetNativeCell(1));
}
public any Native_VSH2GameMode_MaxBoss(Handle plugin, int numParams)
{
	return MAXBOSS;
}
public any Native_VSH2GameMode_OtherTeam(Handle plugin, int numParams)
{
	return gamemode.iOtherTeam;
}
public any Native_Self(Handle plugin, int numParams)
{
	return GetMyHandle();
}
public any Native_UnCycle(Handle plugin, int numParams)
{
	hNoCycle.Push(GetNativeCell(1));
}