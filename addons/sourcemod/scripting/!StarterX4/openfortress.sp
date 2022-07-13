#include <sdktools>
#include <dhooks>
#include <sdkhooks>

#pragma newdecls required
#pragma semicolon 1
#include <openfortress>

#define PLUGIN_VERSION 		"1.0.0"

public Plugin myinfo =  {
	name = "Open Fortress Tools", 
	author = "Scag", 
	description = "Open Fortress natives and forwards for SourceMod", 
	version = PLUGIN_VERSION, 
	url = ""
};

GlobalForward
	hOnConditionAdded,
	hOnConditionRemoved,
	hOnRegeneration,
	hOnPrimaryAttack,
	hOnSpawn
;

Handle
	hIgnitePlayer,
	hRespawnPlayer,
	hRegeneratePlayer,
	hAddCondition,
	hRemoveCondition,
	hDisguisePlayer,
	hRemovePlayerDisguise,
	hInitClass
;

Handle
	hCalcIsAttackCritical,
	hCalcIsAttackCriticalNoCrits,
	hSpawn
//	hForceRespawn
;

enum struct stun_struct_t
{
	int hPlayer;
	float flDuration;
	float flExpireTime;
	float flStartFadeTime;
	float flStunAmount;
	int iStunFlags;
	bool bActive;		// Hack

	void Reset()
	{
		this.hPlayer = 0;
		this.flDuration = 0.0;
		this.flExpireTime = 0.0;
		this.flStartFadeTime = 0.0;
		this.flStunAmount = 0.0;
		this.iStunFlags = 0;
		this.bActive = false;
	}

	void KillAllParticles(int client)
	{
		int ent = -1;
		char name[32];
		while ((ent = FindEntityByClassname(ent, "info_particle_system")) != -1)
		{
			if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client)
			{
				GetEntPropString(ent, Prop_Data, "m_iszEffectName", name, sizeof(name));
				if (!strcmp(name, "yikes_fx") || !strcmp(name, "conc_stars"))
					RemoveEntity(ent);
			}
		}
	}
}

stun_struct_t
	g_Stuns[MAXPLAYERS+1]
;

// I hate windows, so, so much
ArrayStack
	g_Bullshit1,
	g_Bullshit2
;

enum struct CondShit
{
	TFCond cond;
	float time;
}

#define CHECK(%1,%2) if (!(%1)) LogError("Could not load native for \"" ... %2 ... "\"")

public void OnPluginStart()
{
	GameData conf = LoadGameConfigFile("open-fortress");
	if (!conf)	// Dies anyway but w/e
		SetFailState("Gamedata \"open_fortress/addons/sourcemod/gamedata/open-fortress.txt\" does not exist.");

	// Burn
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "Burn");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	hIgnitePlayer = EndPrepSDKCall();
	CHECK(hIgnitePlayer, "TF2_IgnitePlayer");

	// Respawn
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "ForceRespawn");
	hRespawnPlayer = EndPrepSDKCall();
	CHECK(hRespawnPlayer, "TF2_RespawnPlayer");

	// Regenerate
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "Regenerate");
	hRegeneratePlayer = EndPrepSDKCall();
	CHECK(hRegeneratePlayer, "TF2_RegeneratePlayer");

	// AddCond
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "AddCondition");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	hAddCondition = EndPrepSDKCall();
	CHECK(hAddCondition, "TF2_AddCondition");

	// RemoveCond
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "RemoveCondition");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	hRemoveCondition = EndPrepSDKCall();
	CHECK(hRemoveCondition, "TF2_RemoveCondition");

	// Disguise
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "Disguise");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	hDisguisePlayer = EndPrepSDKCall();
	CHECK(hDisguisePlayer, "TF2_DisguisePlayer");

	// RemoveDisguise
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "RemoveDisguise");
	hRemovePlayerDisguise = EndPrepSDKCall();
	CHECK(hRemovePlayerDisguise, "TF2_RemovePlayerDisguise");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "InitClass");
	hInitClass = EndPrepSDKCall();
	CHECK(hInitClass, "OF_InitClass");

	// DHooks
	Handle hook = DHookCreateDetourEx(conf, "Regenerate", CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
	if (hook)
	{
		// There's no post_inventory_application, so I'm making my own
		DHookEnableDetour(hook, false, CTFPlayer_Regenerate);
		DHookEnableDetour(hook, true, CTFPlayer_Regenerate_Post);
	}
	else LogError("Could not load detour for Regenerate, OF_OnPlayerRegenerated forward has been disabled");

	hook = DHookCreateDetourEx(conf, "AddCondition", CallConv_THISCALL, ReturnType_Void, ThisPointer_Address);
	if (hook)
	{
		DHookAddParam(hook, HookParamType_Int);
		DHookAddParam(hook, HookParamType_Float);
//		DHookAddParam(hook, HookParamType_Int);	// Pass as Int so null providers aren't "world"
		// The way the ext does it is pretty stupid, so let's just cheese it
		// This is probably better since devs can hook and remove conds before any logic gets churned
		DHookEnableDetour(hook, false, CTFPlayerShared_AddCond);
		DHookEnableDetour(hook, true, CTFPlayerShared_AddCondPost);
	}
	else LogError("Could not load detour for AddCondition, TF2_OnConditionAdded forward has been disabled");

	hook = DHookCreateDetourEx(conf, "RemoveCondition", CallConv_THISCALL, ReturnType_Void, ThisPointer_Address);
	if (hook)
	{
		DHookAddParam(hook, HookParamType_Int);
//		DHookAddParam(hook, HookParamType_Bool);
		// Same as the AddCond cheese
		DHookEnableDetour(hook, false, CTFPlayerShared_RemoveCond);
		DHookEnableDetour(hook, true, CTFPlayerShared_RemoveCondPost);		
	}
	else LogError("Could not load detour for RemoveCondition, TF2_OnConditionRemoved forward has been disabled");

	//	hook = DHookCreateDetourEx(conf, "HandleCommand_JoinClass", CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
	//	if (hook)
	//	{
	//		DHookEnableDetour(hook, false, CTFPlayer_HandleCommand_JoinClass);
	//		DHookEnableDetour(hook, false, CTFPlayer_HandleCommand_JoinClass_Post);
	//	}

	//	hook = DHookCreateDetourEx(conf, "HandleCommand_JoinTeam", CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
	//	if (hook)
	//	{
	//		DHookEnableDetour(hook, false, CTFPlayer_HandleCommand_JoinTeam);
	//		DHookEnableDetour(hook, false, CTFPlayer_HandleCommand_JoinTeam_Post);		
	//	}

//	hForceRespawn = DHookCreateEx(conf, "ForceRespawn", HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, CTFPlayer_ForceRespawn);

//	hook = DHookCreateDetourEx(conf, "PrimaryAttack", CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
//	if (hook)
//		DHookEnableDetour(hook, true, CTFWeaponBase_PrimaryAttack);
//	else LogError("Could not load detour for PrimaryAttack, OF_OnPrimaryAttack forward has been disabled");

	hCalcIsAttackCritical = DHookCreateEx(conf, "CalcIsAttackCriticalHelper", HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, CTFWeaponBase_CalcIsAttackCritical);
	if (!hCalcIsAttackCritical)
		LogError("Could not load hook for CalcIsAttackCritical, TF2_CalcIsAttackCritical forward has been disabled");

	hCalcIsAttackCriticalNoCrits = DHookCreateEx(conf, "CalcIsAttackCriticalHelperNoCrits", HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, CTFWeaponBase_CalcIsAttackCriticalNoCrits);
	if (!hCalcIsAttackCritical)
		LogError("Could not load hook for CalcIsAttackCriticalNoCrits, TF2_CalcIsAttackCritical forward has been disabled");

	hSpawn = DHookCreateEx(conf, "Spawn", HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, CTFPlayer_Spawn);
	if (!hSpawn)
		LogError("Could not load hook for Spawn, OF_OnPlayerSpawned forward has been disabled");

	delete conf;

	for (int i = MaxClients; i; --i)
		if (IsClientInGame(i))
			OnClientPutInServer(i);

	HookEvent("player_death", OnPlayerDeath);

	// SO
	// Params aren't saved inside of post hooks, so we gotta get fancy, reaaaaally fancy
	// NOT ONLY THAT!
	// Because there is a native that calls the function we are hooked into, which calls a forward,
	// we can hit some serious recursion issues!
	// THEREFORE
	// I save the bad coders a headache because I am so very nice
	// AND
	// I make an arraystack of params, so we are all one big happy family
	// 2 for add and remove
	// 2 blocksize because cond + time
	g_Bullshit1 = new ArrayStack(sizeof(CondShit));
	g_Bullshit2 = new ArrayStack(sizeof(CondShit));
}

public void OnClientPutInServer(int client)
{
	g_Stuns[client].Reset();
	SDKHook(client, SDKHook_PreThink, OnPreThink);
	DHookEntity(hSpawn, true, client);
//	DHookEntity(hForceRespawn, false, client);
}

public void OnPreThink(int client)
{
	if (TF2_IsPlayerInCondition(client, TFCond_Dazed))
	{
		if (g_Stuns[client].bActive && GetGameTime() < g_Stuns[client].flExpireTime)
		{
			g_Stuns[client].Reset();
			g_Stuns[client].KillAllParticles(client);
			TF2_RemoveCondition(client, TFCond_Dazed);
		}
	}
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (g_Stuns[client].bActive)
	{
		g_Stuns[client].Reset();
		g_Stuns[client].KillAllParticles(client);
	}
}

public void TF2_OnConditionAdded(int client, TFCond cond, float dur)
{
	// Fuck it, honestly. Better than no stuns at all
	if (cond == TFCond_Dazed && g_Stuns[client].bActive)
		if (!(g_Stuns[client].iStunFlags & TF_STUNFLAG_NOSOUNDOREFFECT))
			if (g_Stuns[client].iStunFlags & TF_STUNFLAG_GHOSTEFFECT)
				AttachParticle(client, "yikes_fx", "head", dur);
			else AttachParticle(client, "conc_stars", "head", dur);
}

public void TF2_OnConditionRemoved(int client, TFCond cond)
{
	if (cond == TFCond_Dazed)
		g_Stuns[client].KillAllParticles(client);
}

public void OnEntityCreated(int ent, const char[] name)
{
	if (!strncmp(name, "tf_weapon_", 10, false) || !strncmp(name, "of_weapon_", 10, false))
	{
		DHookEntity(hCalcIsAttackCritical, true, ent);
		DHookEntity(hCalcIsAttackCriticalNoCrits, true, ent);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (TF2_IsPlayerInCondition(client, TFCond_Dazed))
	{
		buttons &= ~(IN_JUMP|IN_ATTACK|IN_ATTACK2);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

bool g_iCondAdd[MAXPLAYERS+1][view_as< int >(TFCond_LAST)*2];
bool g_iCondRemove[MAXPLAYERS+1][view_as< int >(TFCond_LAST)*2];
public MRESReturn CTFPlayerShared_AddCond(Address pThis, Handle hParams)
{
	Address m_pOuter = view_as< Address >(FindSendPropInfo("CTFPlayer", "m_bIsZombie") - FindSendPropInfo("CTFPlayer", "m_Shared") + 3);
	int client = GetEntityFromAddress(view_as< Address >(LoadFromAddress(pThis + m_pOuter, NumberType_Int32)));

	CondShit shit;
	shit.cond = DHookGetParam(hParams, 1);
	shit.time = DHookGetParam(hParams, 2);

	g_Bullshit1.PushArray(shit, sizeof(shit));

	if (client == -1 || !IsClientInGame(client) || !IsPlayerAlive(client))	// Sanity check
		return;

	if (!TF2_IsPlayerInCondition(client, shit.cond))
		g_iCondAdd[client][shit.cond] = true;
}
public MRESReturn CTFPlayerShared_AddCondPost(Address pThis, Handle hParams)
{
	Address m_pOuter = view_as< Address >(FindSendPropInfo("CTFPlayer", "m_bIsZombie") - FindSendPropInfo("CTFPlayer", "m_Shared") + 3);
	int client = GetEntityFromAddress(view_as< Address >(LoadFromAddress(pThis + m_pOuter, NumberType_Int32)));

	CondShit shit;
	g_Bullshit1.PopArray(shit, sizeof(shit));

	if (client == -1 ||!IsClientInGame(client))	// Sanity check
		return;

	if (IsPlayerAlive(client))
	{
		// If this cond was added, and it stuck, launch the forward
		if (g_iCondAdd[client][shit.cond] && TF2_IsPlayerInCondition(client, shit.cond))
		{
			Call_StartForward(hOnConditionAdded);
			Call_PushCell(client);
			Call_PushCell(shit.cond);
			Call_PushFloat(shit.time);
//			Call_PushCell(provider);
			Call_Finish();
		}
	}
	g_iCondAdd[client][shit.cond] = false;
}

public MRESReturn CTFPlayerShared_RemoveCond(Address pThis, Handle hParams)
{
	Address m_pOuter = view_as< Address >(FindSendPropInfo("CTFPlayer", "m_bIsZombie") - FindSendPropInfo("CTFPlayer", "m_Shared") + 3);
	int client = GetEntityFromAddress(view_as< Address >(LoadFromAddress(pThis + m_pOuter, NumberType_Int32)));

	CondShit shit;
	shit.cond = DHookGetParam(hParams, 1);
	g_Bullshit2.PushArray(shit, sizeof(shit));

	if (client == -1 || !IsPlayerAlive(client))	// Sanity check
		return;

	if (TF2_IsPlayerInCondition(client, shit.cond))
		g_iCondRemove[client][shit.cond] = true;
}

public MRESReturn CTFPlayerShared_RemoveCondPost(Address pThis, Handle hParams)
{
	Address m_pOuter = view_as< Address >(FindSendPropInfo("CTFPlayer", "m_bIsZombie") - FindSendPropInfo("CTFPlayer", "m_Shared") + 3);
	int client = GetEntityFromAddress(view_as< Address >(LoadFromAddress(pThis + m_pOuter, NumberType_Int32)));

	CondShit shit;
	g_Bullshit2.PopArray(shit, sizeof(shit));

	if (client == -1)	// Sanity check
		return;

	if (IsPlayerAlive(client))
	{
		// If this cond was actually removed, launch the forward
		if (g_iCondRemove[client][shit.cond] && !TF2_IsPlayerInCondition(client, shit.cond))
		{
			Call_StartForward(hOnConditionRemoved);
			Call_PushCell(client);
			Call_PushCell(shit.cond);
			Call_Finish();
		}
	}
	g_iCondRemove[client][shit.cond] = false;
}

public MRESReturn CTFPlayer_Regenerate(int pThis)
{
}
public MRESReturn CTFPlayer_Regenerate_Post(int pThis)
{
	// If regenerate doesn't make null checks, then I won't
	Call_StartForward(hOnRegeneration);
	Call_PushCell(pThis);
	Call_Finish();
}

public MRESReturn CTFWeaponBase_CalcIsAttackCritical(int pThis, Handle hReturn)
{
	return CalcIsAttackCritical(pThis, hReturn);
}

public MRESReturn CTFWeaponBase_CalcIsAttackCriticalNoCrits(int pThis, Handle hReturn)
{
	return CalcIsAttackCritical(pThis, hReturn);
}

public MRESReturn CalcIsAttackCritical(int ent, Handle hReturn)
{
	char cls[64]; GetEntityClassname(ent, cls, sizeof(cls));
	int owner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	bool ret = DHookGetReturn(hReturn);
	Action act;

	Call_StartForward(hOnPrimaryAttack);
	Call_PushCell(owner);
	Call_PushCell(ent);
	Call_PushString(cls);
	Call_PushCellRef(ret);
	Call_Finish(act);

	if (act > Plugin_Continue)
	{
		DHookSetReturn(hReturn, ret);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public MRESReturn CTFPlayer_Spawn(int pThis)
{
	Call_StartForward(hOnSpawn);
	Call_PushCell(pThis);
	Call_Finish();
}

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int max)
{
	CreateNative("TF2_IgnitePlayer", Native_TF2_IgnitePlayer);
	CreateNative("TF2_RespawnPlayer", Native_TF2_RespawnPlayer);
	CreateNative("TF2_RegeneratePlayer", Native_TF2_RegeneratePlayer);
	CreateNative("TF2_AddCondition", Native_TF2_AddCondition);
	CreateNative("TF2_RemoveCondition", Native_TF2_RemoveCondition);
	CreateNative("TF2_DisguisePlayer", Native_TF2_DisguisePlayer);
	CreateNative("TF2_RemovePlayerDisguise", Native_TF2_RemovePlayerDisguise);
	CreateNative("TF2_StunPlayer", Native_TF2_StunPlayer);
	CreateNative("OF_InitClass", Native_OF_InitClass);

	hOnConditionAdded = new GlobalForward("TF2_OnConditionAdded", ET_Ignore, Param_Cell, Param_Cell, Param_Float);
	hOnConditionRemoved = new GlobalForward("TF2_OnConditionRemoved", ET_Ignore, Param_Cell, Param_Cell);
	hOnRegeneration = new GlobalForward("OF_OnPlayerRegenerated", ET_Ignore, Param_Cell);
	hOnPrimaryAttack = new GlobalForward("TF2_CalcIsAttackCritical", ET_Event, Param_Cell, Param_Cell, Param_String, Param_CellByRef);
	hOnSpawn = new GlobalForward("OF_OnPlayerSpawned", ET_Ignore, Param_Cell);

	RegPluginLibrary("openfortress");
	return APLRes_Success;
}

#undef CHECK
#define CHECK(%1,%2)\
if (!(%1)) return ThrowNativeError(SP_ERROR_NATIVE, "\"" ... %2 ... "\" function is not supported.")

#define DECLARE_BS(%1)\
if (!(0 < (%1) <= MaxClients))\
	return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d) specified.", (%1));\
if (!IsClientInGame((%1)))\
	return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in-game.", (%1))

public any Native_TF2_IgnitePlayer(Handle plugin, int numParams)
{
	CHECK(hIgnitePlayer, "Burn");
	int client = GetNativeCell(1);
	DECLARE_BS(client);

	int attacker = GetNativeCell(2);
	if (!(0 < attacker <= MaxClients))
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid attacker index (%d) specified.", attacker);

	if (!IsClientInGame(attacker))
		return ThrowNativeError(SP_ERROR_NATIVE, "Attacker %d is not in-game.", attacker);

	SDKCall(hIgnitePlayer, client, attacker);
	return 0;
}

public any Native_TF2_RespawnPlayer(Handle plugin, int numParams)
{
	CHECK(hRespawnPlayer, "ForceRespawn");
	int client = GetNativeCell(1);
	DECLARE_BS(client);

	SDKCall(hRespawnPlayer, client);
	return 0;
}

public any Native_TF2_RegeneratePlayer(Handle plugin, int numParams)
{
	CHECK(hRegeneratePlayer, "Regenerate");
	int client = GetNativeCell(1);
	DECLARE_BS(client);

	SDKCall(hRegeneratePlayer, client);
	return 0;
}

public any Native_TF2_AddCondition(Handle plugin, int numParams)
{
	CHECK(hAddCondition, "AddCondition");
	int client = GetNativeCell(1);
	DECLARE_BS(client);

	int cond = GetNativeCell(2);
	if (cond < 0)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid condition index (%d) specified.", cond);

	// If they've gotten this far, just help them out
	float duration = GetNativeCell(3);
	if (duration < -1.0)
		duration = -1.0;

	SDKCall(hAddCondition, GetEntityAddress(client) + view_as< Address >(FindSendPropInfo("CTFPlayer", "m_Shared")), cond, duration);
	return 0;
}

public any Native_TF2_RemoveCondition(Handle plugin, int numParams)
{
	CHECK(hRemoveCondition, "RemoveCondition");
	int client = GetNativeCell(1);
	DECLARE_BS(client);

	int cond = GetNativeCell(2);
	if (cond < 0)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid condition index (%d) specified.", cond);

	SDKCall(hRemoveCondition, GetEntityAddress(client) + view_as< Address >(FindSendPropInfo("CTFPlayer", "m_Shared")), cond);
	return 0;
}

public any Native_TF2_DisguisePlayer(Handle plugin, int numParams)
{
	CHECK(hDisguisePlayer, "Disguise");
	int client = GetNativeCell(1);
	DECLARE_BS(client);

	int team = GetNativeCell(2);
	int class = GetNativeCell(3);
	int target = GetNativeCell(4);
	if (target == 0)
		target = -1;	// -1 -> NULL

	SDKCall(hDisguisePlayer, GetEntityAddress(client) + view_as< Address >(FindSendPropInfo("CTFPlayer", "m_Shared")), team, class, target);
	return 0;
}

public any Native_TF2_RemovePlayerDisguise(Handle plugin, int numParams)
{
	CHECK(hRemovePlayerDisguise, "RemoveDisguise");
	int client = GetNativeCell(1);
	DECLARE_BS(client);
	SDKCall(hRemovePlayerDisguise, GetEntityAddress(client) + view_as< Address >(FindSendPropInfo("CTFPlayer", "m_Shared")));
	return 0;
}

// No support, gotta do it the fun way
public any Native_TF2_StunPlayer(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	DECLARE_BS(client);

	float time = GetNativeCell(2);
	if (time < 0.0)
		time = 0.0;

	float reduction = GetNativeCell(3);

	int flags = GetNativeCell(4);
	int attacker = GetNativeCell(5);
	if (attacker)
	{
		if (!(0 < attacker <= MaxClients))
			return ThrowNativeError(SP_ERROR_NATIVE, "Attacker index %d is invalid.", attacker);
		if (!IsClientInGame(attacker))
			return ThrowNativeError(SP_ERROR_NATIVE, "Attacker %d is not in-game", attacker);

//		if (GetClientTeam(attacker) == GetClientTeam(victim))
//			return;
	}

	float remapamount = RemapValClamped(reduction, 0.0, 1.0, 0.0, 255.0);
//	int oldstunflags = g_Stuns[client].iStunFlags;
	bool stomp;

	if (TF2_IsPlayerInCondition(client, TFCond_Dazed))
	{
		if (remapamount > g_Stuns[client].flStunAmount || flags & (TF_STUNFLAG_LIMITMOVEMENT|TF_STUNFLAG_THIRDPERSON))
			stomp = true;
		else if (GetGameTime() + time < g_Stuns[client].flExpireTime)
			return 0;
	}

	stun_struct_t stunEvent;
	stunEvent.hPlayer = 0 < attacker <= MaxClients ? GetClientUserId(attacker) : 0;		// Store by userid, better this way
	stunEvent.flDuration = time;
	stunEvent.flExpireTime = GetGameTime() + time;
	stunEvent.flStartFadeTime = GetGameTime() + time;
	stunEvent.flStunAmount = remapamount;
	stunEvent.iStunFlags = flags;

	if (stomp || !g_Stuns[client].bActive)
	{
		float oldstun = g_Stuns[client].bActive ? g_Stuns[client].flStunAmount : 0.0;

		g_Stuns[client] = stunEvent;
		if (oldstun > remapamount)
			g_Stuns[client].flStunAmount = oldstun;
	}
	else
	{
		// TODO; make an actual stun vector
	}

	if (g_Stuns[client].iStunFlags & TF_STUNFLAG_BONKSTUCK)
		g_Stuns[client].flExpireTime += 1.5;

	g_Stuns[client].flStartFadeTime = GetGameTime() + g_Stuns[client].flDuration;

	if (g_Stuns[client].iStunFlags & (TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_THIRDPERSON))
	{
		// Third person and concept sounds
	}

	if (!(g_Stuns[client].iStunFlags & TF_STUNFLAG_NOSOUNDOREFFECT))
	{
		// Stun sound
	}

	if (g_Stuns[client].iStunFlags & (TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_THIRDPERSON))
	{
		TF2_RemoveCondition(client, TFCond_Taunting);
	}

	// This condition literally isn' touched in the source, so I have to do fucking EVERYTHING
	TF2_AddCondition(client, TFCond_Dazed, g_Stuns[client].flDuration);
	return 0;
}

public any Native_OF_InitClass(Handle plugin, int numParams)
{
	CHECK(hInitClass, "OF_InitClass");
	int client = GetNativeCell(1);
	DECLARE_BS(client);

	if (IsPlayerAlive(client))
		SDKCall(hInitClass, client);
	return 0;
}

stock Handle DHookCreateDetourEx(GameData conf, const char[] name, CallingConvention callConv, ReturnType returntype, ThisPointerType thisType)
{
	Handle h = DHookCreateDetour(Address_Null, callConv, returntype, thisType);
	if (h)
	{
		if (!DHookSetFromConf(h, conf, SDKConf_Signature, name))
		{
			LogError("Could not set %s from config!", name);
			delete h;
			return null;
		}
	}
	return h;
}

// Props to nosoop
stock int GetEntityFromAddress(Address pEntity)
{
	if (pEntity == Address_Null)
		return -1;

	int ent = LoadFromAddress(pEntity + view_as< Address >(FindDataMapInfo(0, "m_angRotation") + 12), NumberType_Int32) & 0xFFF;
	if (!ent || ent == 0xFFF)
		return -1;
	return ent;
}
stock Handle DHookCreateEx(Handle gc, const char[] key, HookType hooktype, ReturnType returntype, ThisPointerType thistype, DHookCallback callback)
{
	int iOffset = GameConfGetOffset(gc, key);
	if (iOffset == -1)
	{
		LogError("Failed to get offset of %s", key);
		return null;
	}
	
	return DHookCreate(iOffset, hooktype, returntype, thistype, callback);
}

stock float RemapValClamped(float val, float A, float B, float C, float D)
{
	if (A == B)
		return val >= B ? D : C;
	float cVal = (val - A) / (B - A);
	cVal = clamp(cVal, 0.0, 1.0);

	return C + (D - C) * cVal;
}

stock float clamp(float val, float a, float b)
{
	if (val < a)
		val = a;
	if (val > b)
		val = b;
	return val;
}

stock int AttachParticle(int ent, const char[] particleType, const char[] attach, float dur)
{
	int particle = CreateEntityByName("info_particle_system");
	float pos[3]; GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);

	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);

	SetVariantString("!activator");
	AcceptEntityInput(particle, "SetParent", ent, particle);

	SetVariantString(attach);
	AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", ent, particle);

	SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", ent);

	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");

	return particle;
}