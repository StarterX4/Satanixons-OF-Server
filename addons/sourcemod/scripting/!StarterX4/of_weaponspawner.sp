#include <sdktools>
#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

ArrayList
	hSpawners,
	hWeapons
;

StringMap
	hWeights
;

enum struct WeaponSpawner
{
	float m_vecPos[3];
	void Init()
	{
		this.m_vecPos = view_as< float >({0.0, 0.0, 0.0});
	}

	int Create(const char[] name, const char[] model, bool initialdelay = false)
	{
		int ent = CreateEntityByName("dm_weapon_spawner");
		DispatchKeyValue(ent, "model", model);
		DispatchKeyValue(ent, "weaponname", name);
		DispatchKeyValueFloat(ent, "RespawnTime", 30.0);
		DispatchKeyValueFloat(ent, "respawndelay", initialdelay ? 30.0 : -1.0);
		TeleportEntity(ent, this.m_vecPos, NULL_VECTOR, NULL_VECTOR);

		SetVariantString(name);
		AcceptEntityInput(ent, "SetWeaponName");	// This input forces an update. Now there's a valid weapon info ptr
		DispatchSpawn(ent);

		SetEntProp(ent, Prop_Data, "m_bDisabled", false);
		SetVariantInt(2);
		AcceptEntityInput(ent, "SetTeam");

		HookSingleEntityOutput(ent, "OnPlayerTouch", OnPlayerGetItem);
		return ent;
	}
}

enum struct Weapon
{
	char name[128];
	char model[128];

	void Init()
	{
		this.name[0] = '\0';
		this.model[0] = '\0';
	}
}


public void OnPluginStart()
{
	RegAdminCmd("sm_wscfg", WSConfig, ADMFLAG_GENERIC);
	RegAdminCmd("sm_addpos", AddPos, ADMFLAG_GENERIC);
	HookEvent("teamplay_round_start", OnRoundStart);

	hSpawners = new ArrayList(sizeof(WeaponSpawner));
	hWeapons = new ArrayList(sizeof(Weapon));

	hWeights = new StringMap();

	hWeights.SetValue("tf_weapon_revolver_mercenary", 4);
	hWeights.SetValue("tf_weapon_nailgun", 4);
	hWeights.SetValue("tf_weapon_pistol_akimbo", 4);
	hWeights.SetValue("tf_weapon_pistol_mercenary", 4);

	hWeights.SetValue("tf_weapon_smg_mercenary", 3);
	hWeights.SetValue("tf_weapon_shotgun", 3);
	hWeights.SetValue("tf_weapon_railgun", 3);
	hWeights.SetValue("tf_weapon_tommygun", 3);
	hWeights.SetValue("tf_weapon_gatlinggun", 3);
	hWeights.SetValue("tf_weapon_grenadelauncher_mercenary", 3);
	hWeights.SetValue("tf_weapon_eternalshotgun", 3);
	hWeights.SetValue("tf_weapon_bouncer", 3);
	hWeights.SetValue("tf_weapon_supershotgun", 3);

	hWeights.SetValue("tf_weapon_super_rocketlauncher", 2);
	hWeights.SetValue("tf_weapon_gib", 2);
	hWeights.SetValue("tf_weapon_rocketlauncher_dm", 2);
	hWeights.SetValue("tf_weapon_flamethrower", 2);
	hWeights.SetValue("tf_weapon_lightning_gun", 2);
	hWeights.SetValue("tf_weapon_assaultrifle", 2);
	hWeights.SetValue("tf_weapon_dynamite_bundle", 2);
	hWeights.SetValue("tf_weapon_medigun", 2);

//	hWeights.SetValue("tf_weapon_chainsaw", 1);
}

public void OnMapStart()
{
	char cfg[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, cfg, sizeof(cfg), "configs/openfortress/mapconfig.cfg");
	hSpawners.Clear();
	hWeapons.Clear();

	KeyValues kv = new KeyValues("WeaponSpawners");
	char map[128];
	GetCurrentMap(map, sizeof(map));
	if (!kv.ImportFromFile(cfg) || !kv.JumpToKey(map))
	{
		delete kv;
		return;
	}

	if (!kv.JumpToKey("Weapons") || !kv.GotoFirstSubKey(false))
	{
		delete kv;
		return;
	}

	Weapon w;
	do
	{
		w.Init();
		kv.GetSectionName(w.name, sizeof(w.name));
		StringToLower(w.name);
		kv.GetString(NULL_STRING, w.model, sizeof(w.model));
		PrecacheModel(w.model);

		int val = 1; hWeights.GetValue(w.name, val);
		for (int i = 0; i < val; ++i)
			hWeapons.PushArray(w, sizeof(w));
	}	while (kv.GotoNextKey(false));

	kv.GoBack();
	kv.GoBack();

	if (kv.JumpToKey("Locations") && kv.GotoFirstSubKey(false))
	{
		WeaponSpawner s;
		do
		{
			s.Init();
			kv.GetVector(NULL_STRING, s.m_vecPos);
			hSpawners.PushArray(s, sizeof(s));
		}	while kv.GotoNextKey(false);
	}
	delete kv;
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "dm_weapon_spawner")) != -1)
		RemoveEntity(ent);

	WeaponSpawner spawner;
	Weapon w;
	for (int i = 0; i < hSpawners.Length; ++i)
	{
		hSpawners.GetArray(i, spawner, sizeof(spawner));
		hWeapons.GetArray(GetRandomInt(0, hWeapons.Length-1), w, sizeof(w));
		spawner.Create(w.name, w.model);
	}
}

public Action WSConfig(int client, int args)
{
	OnMapStart();
	ReplyToCommand(client, "[SM] Running Weapon Spawner config.");

	char map[64]; GetCurrentMap(map, sizeof(map));
	PrintToChat(client, "Map %s size %d", map, hWeapons.Length);

	for (int i = 0; i < hWeapons.Length; ++i)
	{
		float v[3]; hWeapons.GetArray(i, v, 3);
		PrintToChat(client, "%.0f, %.0f, %.0f", v[0], v[1], v[2]);
	}
	return Plugin_Handled;
}

public Action AddPos(int client, int args)
{
	float pos[3]; GetClientAbsOrigin(client, pos);
	pos[2] += 50.0;

	char cfg[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, cfg, sizeof(cfg), "configs/openfortress/mapconfig.cfg");

	KeyValues kv = new KeyValues("WeaponSpawners");
	char map[128];
	GetCurrentMap(map, sizeof(map));
	if (!kv.ImportFromFile(cfg) || !kv.JumpToKey(map, true))
	{
		delete kv;
		PrintToChat(client, "Failed");
		return Plugin_Handled;
	}

	if (kv.JumpToKey("Weapons"))
		kv.GoBack();
	else
	{
		kv.JumpToKey("Weapons", true);
		kv.SetString("tf_weapon_revolver_mercenary",		"models/weapons/w_models/w_revolver_dm.mdl");
		kv.SetString("tf_weapon_nailgun", 					"models/weapons/w_models/w_nailgun.mdl");
		kv.SetString("tf_weapon_pistol_akimbo", 			"models/weapons/w_models/w_pistol_akimbo.mdl");
		kv.SetString("tf_weapon_smg_mercenary", 			"models/weapons/w_models/w_smg_dm.mdl");
		kv.SetString("tf_weapon_shotgun", 					"models/weapons/w_models/w_shotgun.mdl");
		kv.SetString("tf_weapon_dynamite_bundle", 			"models/weapons/w_models/w_dynamite.mdl");
//		kv.SetString("tf_weapon_chainsaw",					"models/weapons/w_models/w_chainsaw_dm.mdl");
		kv.SetString("tf_weapon_assaultrifle", 				"models/weapons/w_models/w_assault_rifle.mdl");
		kv.SetString("tf_weapon_supershotgun", 				"models/weapons/w_models/w_supershotgun.mdl");
		kv.SetString("tf_weapon_rocketlauncher_dm", 		"models/weapons/w_models/w_rocketlauncher_dm.mdl");
		kv.SetString("tf_weapon_railgun", 					"models/weapons/w_models/w_railgun.mdl");
		kv.SetString("tf_weapon_tommygun", 					"models/weapons/w_models/w_tommygun.mdl");
		kv.SetString("tf_weapon_gatlinggun", 				"models/weapons/w_models/w_minigun_dm.mdl");
		kv.SetString("tf_weapon_flamethrower", 				"models/weapons/w_models/w_flamethrower.mdl");
		kv.SetString("tf_weapon_grenadelauncher_mercenary",	"models/weapons/w_models/w_grenadelauncher_dm.mdl");
		kv.SetString("tf_weapon_lightning_gun", 			"models/weapons/w_models/w_lightning_gun.mdl");
		kv.SetString("tf_weapon_bouncer", 					"models/weapons/w_models/w_bouncer.mdl");
		kv.SetString("tf_weapon_eternalshotgun", 			"models/weapons/w_models/w_supershotgun_doom.mdl");
		kv.GoBack();
	}

	kv.JumpToKey("Locations", true);
	int count;
	if (kv.GotoFirstSubKey(false))
	{
		do
			++count;
			while kv.GotoNextKey(false);

		kv.GoBack();
	}

	char num[4]; IntToString(count, num, 4);
	kv.SetVector(num, pos);
	kv.Rewind();
	kv.ExportToFile(cfg);

	delete kv;

	PrintToChat(client, "Success");
	return Plugin_Handled;
}

public void OnPlayerGetItem(const char[] output, int caller, int activator, float delay)
{
	WeaponSpawner spawner;
	GetEntPropVector(caller, Prop_Send, "m_vecOrigin", spawner.m_vecPos);
	RemoveEntity(caller);

	Weapon w;
	hWeapons.GetArray(GetRandomInt(0, hWeapons.Length-1), w, sizeof(w));
	spawner.Create(w.name, w.model, true);
}

stock void StringToLower(char[] s)
{
	for (int i = 0; s[i] != '\0'; ++i)
	{
		s[i] = CharToLower(s[i]);
	}
}