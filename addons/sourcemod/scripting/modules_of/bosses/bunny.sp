//defines

//models
#define BunnyModel		"models/player/saxton_hale/easter_demo.mdl"
// #define BunnyModelPrefix	"models/player/saxton_hale/easter_demo"

#define EggModel		"models/player/saxton_hale/w_easteregg.mdl"
// #define EggModelPrefix		"models/player/saxton_hale/w_easteregg"
//#define ReloadEggModel	"models/player/saxton_hale/c_easter_cannonball.mdl"
//#define ReloadEggModelPrefix	"models/player/saxton_hale/c_easter_cannonball"
#define BunnyTheme		"saxton_hale/bunnytheme1.mp3"
#define BunnyTheme2		"saxton_hale/bunnytheme2_fix2.mp3"
#define BunnyTheme3		"saxton_hale/bunnytheme3_fix.mp3"

//materials
static const char BunnyMaterials[][] = {
	"materials/models/player/easter_demo/demoman_head_red.vmt",
	"materials/models/player/easter_demo/easter_body.vmt",
	"materials/models/player/easter_demo/easter_body.vtf",
	"materials/models/player/easter_demo/easter_rabbit.vmt",
	"materials/models/player/easter_demo/easter_rabbit.vtf",
	"materials/models/player/easter_demo/easter_rabbit_normal.vtf",
	"materials/models/player/easter_demo/eyeball_r.vmt"
	// "materials/models/player/easter_demo/demoman_head_blue_invun.vmt", // This is for the new version of easter demo which VSH isn't using
	// "materials/models/player/easter_demo/demoman_head_red_invun.vmt",
	// "materials/models/player/easter_demo/easter_rabbit_blue.vmt",
	// "materials/models/player/easter_demo/easter_rabbit_blue.vtf",
	// "materials/models/player/easter_demo/easter_rabbit_invun.vmt",
	// "materials/models/player/easter_demo/easter_rabbit_invun.vtf",
	// "materials/models/player/easter_demo/easter_rabbit_invun_blue.vmt",
	// "materials/models/player/easter_demo/easter_rabbit_invun_blue.vtf",
	// "materials/models/player/easter_demo/eyeball_invun.vmt"
};

//Easter Bunny voicelines
char BunnyWin[][] = {
	"vo/demoman_gibberish01.mp3",
	"vo/demoman_gibberish12.mp3",
	"vo/demoman_cheers02.mp3",
	"vo/demoman_cheers03.mp3",
	"vo/demoman_cheers06.mp3",
	"vo/demoman_cheers07.mp3",
	"vo/demoman_cheers08.mp3",
	"vo/taunts/demoman_taunts12.mp3"
};

char BunnyJump[][] = {
	"vo/demoman_gibberish07.mp3",
	"vo/demoman_gibberish08.mp3",
	"vo/demoman_laughshort01.mp3",
	"vo/demoman_positivevocalization04.mp3"
};

char BunnyRage[][] = {
	"vo/demoman_positivevocalization03.mp3",
	"vo/demoman_dominationscout05.mp3",
	"vo/demoman_cheers02.mp3"
};

char BunnyFail[][] = {
	"vo/demoman_gibberish04.mp3",
	"vo/demoman_gibberish10.mp3",
	"vo/demoman_jeers03.mp3",
	"vo/demoman_jeers06.mp3",
	"vo/demoman_jeers07.mp3",
	"vo/demoman_jeers08.mp3"
};

char BunnyKill[][] = {
	"vo/demoman_gibberish09.mp3",
	"vo/demoman_cheers02.mp3",
	"vo/demoman_cheers07.mp3",
	"vo/demoman_positivevocalization03.mp3"
};

char BunnySpree[][] = {
	"vo/demoman_gibberish05.mp3",
	"vo/demoman_gibberish06.mp3",
	"vo/demoman_gibberish09.mp3",
	"vo/demoman_gibberish11.mp3",
	"vo/demoman_gibberish13.mp3",
	"vo/demoman_autodejectedtie01.mp3"
};

char BunnyLast[][] = {
	"vo/taunts/demoman_taunts05.mp3",
	"vo/taunts/demoman_taunts04.mp3",
	"vo/demoman_specialcompleted07.mp3"
};

char BunnyPain[][] = {
	"vo/demoman_sf12_badmagic01.mp3",
	"vo/demoman_sf12_badmagic07.mp3",
	"vo/demoman_sf12_badmagic10.mp3"
};

char BunnyStart[][] = {
	"vo/demoman_gibberish03.mp3",
	"vo/demoman_gibberish11.mp3"
};

char BunnyRandomVoice[][] = {
	"vo/demoman_positivevocalization03.mp3",
	"vo/demoman_jeers08.mp3",
	"vo/demoman_gibberish03.mp3",
	"vo/demoman_cheers07.mp3",
	"vo/demoman_sf12_badmagic01.mp3",
	"vo/burp02.mp3",
	"vo/burp03.mp3",
	"vo/burp04.mp3",
	"vo/burp05.mp3",
	"vo/burp06.mp3",
	"vo/burp07.mp3"
};


methodmap CBunny < BaseBoss
{
	public CBunny(const int ind, bool uid = false)
	{
		if (uid)
			return view_as<CBunny>( BaseBoss(ind, true) );
		return view_as<CBunny>( BaseBoss(ind) );
	}

	public void PlaySpawnClip()
	{
		char snd[PLATFORM_MAX_PATH];
		strcopy(snd, PLATFORM_MAX_PATH, BunnyStart[GetRandomInt(0, sizeof(BunnyStart)-1)]);
		EmitSoundToAll(snd);
	}

	public void Think ()
	{
		this.DoGenericThink(true, true, BunnyJump[GetRandomInt(0, sizeof(BunnyJump)-1)]);
	}
	public void SetModel ()
	{
		SetVariantString(BunnyModel);
		AcceptEntityInput(this.index, "SetCustomModel");
//		SetEntProp(this.index, Prop_Send, "m_bUseClassAnimations", 1);
		//SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.25);
	}

	public void Death ()
	{
		char snd[PLATFORM_MAX_PATH];
		strcopy(snd, PLATFORM_MAX_PATH, BunnyFail[GetRandomInt(0, sizeof(BunnyFail)-1)]);
		EmitSoundToAll(snd, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, this.index, NULL_VECTOR, NULL_VECTOR, false, 0.0);
		EmitSoundToAll(snd, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, this.index, NULL_VECTOR, NULL_VECTOR, false, 0.0);
		SpawnManyAmmoPacks(this.index, EggModel, 1);
	}

	public void Equip ()
	{
		this.PreEquip();
		int wep = GivePlayerItem(this.index, "tf_weapon_bottle");
		EquipPlayerWeapon(this.index, wep);
		SetActiveWep(this.index, wep);
		this.iSpecial = 0;
	}
	public void RageAbility()
	{
		TF2_AddCondition(this.index, view_as<TFCond>(42), 4.0);
		TF2_RemoveCondition(this.index, TFCond_Taunting);
		this.SetModel(); //MakeModelTimer(null); // should reset Hale's animation

//		TF2_RemoveWeaponSlot(this.index, TFWeaponSlot_Primary);
//		int weapon = this.SpawnWeapon("tf_weapon_grenadelauncher", 19, 100, 5, "2 ; 1.25 ; 6 ; 0.1 ; 411 ; 150.0 ; 413 ; 1.0 ; 37 ; 0.0 ; 280 ; 17 ; 477 ; 1.0 ; 467 ; 1.0 ; 181 ; 2.0 ; 252 ; 0.7");
//		SetEntPropEnt(this.index, Prop_Send, "m_hActiveWeapon", weapon);
//		SetEntProp(weapon, Prop_Send, "m_iClip1", 50);
//		SetWeaponAmmo(weapon, 0);

		this.DoGenericStun(VAGRAGEDIST);

		char snd[PLATFORM_MAX_PATH];
		strcopy(snd, PLATFORM_MAX_PATH, BunnyRage[GetRandomInt(1, sizeof(BunnyRage)-1)]);

		float pos[3]; GetClientAbsOrigin(this.index, pos);
		EmitSoundToAll(snd, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, this.index, pos, NULL_VECTOR, false, 0.0);
		EmitSoundToAll(snd, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, this.index, pos, NULL_VECTOR, false, 0.0);

		SpawnNades(this);
	}

	public void KilledPlayer(const BaseBoss victim, Event event)
	{
		char snd[PLATFORM_MAX_PATH];
		strcopy(snd, PLATFORM_MAX_PATH, BunnyKill[GetRandomInt(0, sizeof(BunnyKill)-1)]);
		EmitSoundToAll(snd, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, this.index, NULL_VECTOR, NULL_VECTOR, false, 0.0);
		EmitSoundToAll(snd, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, this.index, NULL_VECTOR, NULL_VECTOR, false, 0.0);
		SpawnManyAmmoPacks(victim.index, EggModel, 1);
		this.iKills++;

		if (!(this.iKills % 3)) {
			strcopy(snd, PLATFORM_MAX_PATH, BunnySpree[GetRandomInt(0, sizeof(BunnySpree)-1)]);
			EmitSoundToAll(snd, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, this.index, NULL_VECTOR, NULL_VECTOR, false, 0.0);
			EmitSoundToAll(snd, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, this.index, NULL_VECTOR, NULL_VECTOR, false, 0.0);
			this.iKills = 0;
		}
	}
	public void Help()
	{
		if ( IsVoteInProgress() )
			return ;
		char helpstr[] = "The Easter Bunny:\nI think he wants to give out candy? Maybe?\nSuper Jump: Right-click, look up, and release.\nWeigh-down: After 3 seconds in midair, look down and crouch\nRage (Happy Easter, Fools): Call for medic (e) when Rage Meter is full.\nNearby enemies are stunned and you receive a grenade launcher.";
		Panel panel = new Panel();
		panel.SetTitle (helpstr);
		panel.DrawItem( "Exit" );
		panel.Send(this.index, HintPanel, 10);
		delete (panel);
	}

	public void LastPlayerSoundClip()
	{
		float pos[3]; GetClientAbsOrigin(this.index, pos);
		char snd[PLATFORM_MAX_PATH];
		strcopy(snd, PLATFORM_MAX_PATH, BunnyLast[GetRandomInt(0, sizeof(BunnyLast)-1)]);
		EmitSoundToAll(snd, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, this.index, pos, NULL_VECTOR, false, 0.0);
		EmitSoundToAll(snd, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, this.index, pos, NULL_VECTOR, false, 0.0);
	}
};

public CBunny ToCBunny (const BaseBoss guy)
{
	return view_as<CBunny>(guy);
}

public void AddBunnyToDownloads()
{
	// char s[PLATFORM_MAX_PATH];
	
	// int i;
	PrepareModel(BunnyModel);
	PrepareModel(EggModel);

	DownloadMaterialList(BunnyMaterials, sizeof(BunnyMaterials));

	PrepareMaterial("materials/models/props_easteregg/c_easteregg");
	CheckDownload("materials/models/props_easteregg/c_easteregg_gold.vmt");

	PrecacheSoundList(BunnyWin, sizeof(BunnyWin));
	PrecacheSoundList(BunnyJump, sizeof(BunnyJump));
	PrecacheSoundList(BunnyRage, sizeof(BunnyRage));
	PrecacheSoundList(BunnyFail, sizeof(BunnyFail));
	PrecacheSoundList(BunnyKill, sizeof(BunnyKill));
	PrecacheSoundList(BunnySpree, sizeof(BunnySpree));
	PrecacheSoundList(BunnyLast, sizeof(BunnyLast));
	PrecacheSoundList(BunnyPain, sizeof(BunnyPain));
	PrecacheSoundList(BunnyStart, sizeof(BunnyStart));
	PrecacheSoundList(BunnyRandomVoice, sizeof(BunnyRandomVoice));
	PrepareSound(BunnyTheme);
	PrepareSound(BunnyTheme2);
	PrepareSound(BunnyTheme3);
}

public void AddBunnyToMenu ( Menu& menu )
{
	menu.AddItem("4", "Easter Bunny Demoman");
}

stock void SpawnManyAmmoPacks(const int client, const char[] model, int skin=0, int num=14, float offsz = 30.0)
{
	float pos[3], vel[3], ang[3];
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;
	GetClientAbsOrigin(client, pos);
	pos[2] += offsz;
	for (int i=0; i<num; i++) {
		vel[0] = GetRandomFloat(-400.0, 400.0);
		vel[1] = GetRandomFloat(-400.0, 400.0);
		vel[2] = GetRandomFloat(300.0, 500.0);
		pos[0] += GetRandomFloat(-5.0, 5.0);
		pos[1] += GetRandomFloat(-5.0, 5.0);
		int ent = CreateEntityByName("tf_ammo_pack");
		if (!IsValidEntity(ent))
			continue;
		SetEntityModel(ent, model);
		DispatchKeyValue(ent, "OnPlayerTouch", "!self,Kill,,0,-1"); //for safety, but it shouldn't act like a normal ammopack
		SetEntProp(ent, Prop_Send, "m_nSkin", skin);
		SetEntProp(ent, Prop_Send, "m_nSolidType", 6);
		SetEntProp(ent, Prop_Send, "m_usSolidFlags", 152);
		SetEntProp(ent, Prop_Send, "m_triggerBloat", 24);
		SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
		SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(ent, Prop_Send, "m_iTeamNum", 2);
		TeleportEntity(ent, pos, ang, vel);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, vel);
		SetEntProp(ent, Prop_Data, "m_iHealth", 900);
		int offs = GetEntSendPropOffs(ent, "m_vecInitialVelocity", true);
		SetEntData(ent, offs-4, 1, _, true);
		HookSingleEntityOutput(ent, "OnCacheInteraction", OnEggPickup);
	}
}
public Action Timer_SetEggBomb(Handle timer, any ref)
{
	int entity = EntRefToEntIndex(ref);
	if (FileExists(EggModel) && IsModelPrecached(EggModel) && IsValidEntity(entity))
	{
		int att = AttachProjectileModel(entity, EggModel);
		SetEntProp(att, Prop_Send, "m_nSkin", 0);
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 255, 255, 255, 0);
	}
	return Plugin_Continue;
}

public void OnEggPickup(const char[] output, int caller, int activator, float delay)
{
	TF2_AddCondition(activator, TFCond_Kritzkrieged, 4.0);
}

public void SpawnNades(BaseBoss boss)
{
	if (!IsClientValid(boss.index))
		return;

	if (++boss.iSpecial > 4)
	{
		boss.iSpecial = 0;
		return;
	}

	for (int i = 0; i < 10; ++i)
		SpawnNade(boss.index);

	SetPawnTimer(SpawnNades, 0.8, boss);
}

public void SpawnNade(int client)
{
	float pos[3], vel[3], ang[3];
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;
	GetClientAbsOrigin(client, pos);
	pos[2] += 30.0;
	vel[0] = GetRandomFloat(-400.0, 400.0);
	vel[1] = GetRandomFloat(-400.0, 400.0);
	vel[2] = GetRandomFloat(300.0, 500.0);
	pos[0] += GetRandomFloat(-5.0, 5.0);
	pos[1] += GetRandomFloat(-5.0, 5.0);

	int ent = CreateEntityByName("tf_projectile_pipe");
	SetEntProp(ent, Prop_Send, "m_nSkin", 0);
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
//	SetEntPropEnt(ent, Prop_Send, "m_hLauncher", client);
	SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client));
	SetEntPropFloat(ent, Prop_Send, "m_flDamage", 100.0);
	TeleportEntity(ent, pos, ang, vel);
	DispatchSpawn(ent);
	TeleportEntity(ent, pos, ang, vel);
}