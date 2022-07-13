#include <dhooks>
#include <sdktools>
#include <sdkhooks>
#include <vsh2_of>

Handle hItemCanBeTouchedByPlayer;

public void OnPluginStart()
{
	GameData conf = LoadGameConfigFile("tf2.vsh2_of");

	hItemCanBeTouchedByPlayer = DHookCreate(0, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, CItem_ItemCanBeTouchedByPlayer);
	DHookSetFromConf(hItemCanBeTouchedByPlayer, conf, SDKConf_Virtual, "CItem::ItemCanBeTouchedByPlayer");
	DHookAddParam(hItemCanBeTouchedByPlayer, HookParamType_CBaseEntity);
	if (!hItemCanBeTouchedByPlayer)
		SetFailState("Could not load hook for CItem::ItemCanBeTouchedByPlayer!");

	// I don't remember if this even works.
	Handle hook = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
	DHookSetFromConf(hook, conf, SDKConf_Signature, "CTFPlayer::UpdateCosmetics");
	DHookEnableDetour(hook, false, CTFPlayer_UpdateCosmetics);

	delete conf;
}

public void OnEntityCreated(int ent, const char[] classname)
{
	if (!strncmp(classname, "item_", 5, false))
		DHookEntity(hItemCanBeTouchedByPlayer, false, ent);
}

public MRESReturn CItem_ItemCanBeTouchedByPlayer(int pThis, Handle hReturn, Handle hParams)
{
	int other = DHookGetParam(hParams, 1);
	if (0 < other <= MaxClients)
		if (VSH2Player(other).bIsBoss)
		{
			DHookSetReturn(hReturn, false);
			return MRES_Supercede;
		}
	return MRES_Ignored;
}

public MRESReturn CTFPlayer_UpdateCosmetics(int pThis)
{
	VSH2Player player = VSH2Player(pThis);
	if (player.bIsBoss)
		return MRES_Supercede;
	return MRES_Ignored;
}