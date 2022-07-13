/*
ALL NON-BOSS AND NON-MINION RELATED CODE AND AT THE BOTTOM. HAVE FUN CODING!
*/

enum/* Bosses *//* When you add custom Bosses, add to the anonymous enum as the Boss' ID */
{
	Hale = 0, 
	Vagineer = 1, 
	CBS = 2, 
	HHHjr = 3, 
	Bunny = 4
};

//#define MAXBOSS		4	// When adding new bosses, increase the MAXBOSS define for the newest boss id
#define MAXBOSS 	(Bunny + g_hPluginsRegistered.Length)

#include "modules_of/bosses.sp"

/*
PLEASE REMEMBER THAT PLAYERS THAT DON'T HAVE THEIR BOSS ID'S SET ARE NOT BOSSES.
THIS PLUGIN HAS BEEN SETUP SO THAT IF YOU BECOME A BOSS, YOU MUST HAVE A VALID BOSS ID

FOR MANAGEMENT FUNCTIONS, DO NOT HAVE THEM DISCRIMINATE WHO IS A BOSS OR NOT, SIMPLY CHECK THE ITYPE TO SEE IF IT REALLY WAS A BOSS PLAYER.
*/

public void ManageDownloads()
{
	PrecacheSound("ui/item_store_add_to_cart.wav", true);
	PrecacheSound("player/doubledonk.wav", true);

	PrecacheSound("saxton_hale/9000.wav", true);
	CheckDownload("sound/saxton_hale/9000.wav");
	PrecacheSound("vo/announcer_am_capincite01.mp3", true);
	PrecacheSound("vo/announcer_am_capincite03.mp3", true);
	PrecacheSound("vo/announcer_am_capenabled02.mp3", true);

	PrecacheSound("vo/announcer_ends_60sec.mp3", true);
	PrecacheSound("vo/announcer_ends_30sec.mp3", true);
	PrecacheSound("vo/announcer_ends_10sec.mp3", true);
	PrecacheSound("vo/announcer_ends_1sec.mp3", true);
	PrecacheSound("vo/announcer_ends_2sec.mp3", true);
	PrecacheSound("vo/announcer_ends_3sec.mp3", true);
	PrecacheSound("vo/announcer_ends_4sec.mp3", true);
	PrecacheSound("vo/announcer_ends_5sec.mp3", true);
	PrecacheSound("items/pumpkin_pickup.wav", true);
	PrecacheSound("misc/ks_tier_04_kill_01.wav", true);
	PrecacheSound("items/spawn_item.wav", true);

	AddHaleToDownloads();
	AddVagToDownloads();
	AddCBSToDownloads();
	AddHHHToDownloads();
	AddBunnyToDownloads();
	Call_OnCallDownloads(); // in forwards.sp
}

public void ManageMenu(Menu & menu)
{
	AddHaleToMenu(menu);
	AddVagToMenu(menu);
	AddCBSToMenu(menu);
	AddHHHToMenu(menu);
	AddBunnyToMenu(menu);
	Call_OnBossMenu(menu);
}

public void ManageDisconnect(const int client)
{
	BaseBoss leaver = BaseBoss(client);
	if (leaver.bIsBoss) {
		if( gamemode.iRoundState >= StateRunning ) {	/// Arena mode flips out when no one is on the other team
			BaseBoss[] bosses = new BaseBoss[MaxClients];
			int numbosses = gamemode.GetBosses(bosses, false);
			if( numbosses-1 > 0 ) {	/// Exclude leaver, this is why CountBosses() can't be used
				for( int i=0; i<numbosses; i++ ) {
					if( bosses[i] == leaver )
						continue;
					if( IsPlayerAlive(bosses[i].index) )
						break;

					BaseBoss next = gamemode.FindNextBoss();
					if( gamemode.hNextBoss ) {
						next = gamemode.hNextBoss;
						gamemode.hNextBoss = view_as< BaseBoss >(0);
					}
					if( IsClientValid(next.index) ) {
						next.bIsMinion = true;	/// Dumb hack, prevents spawn hook from forcing them back to red
						next.ForceTeamChange(gamemode.iHaleTeam);
					}

					if( gamemode.iRoundState == StateRunning )
						ForceTeamWin(gamemode.iOtherTeam);
					break;
				}
			}
			else {	/// No bosses left
				BaseBoss next = gamemode.FindNextBoss();
				if( gamemode.hNextBoss ) {
					next = gamemode.hNextBoss;
					gamemode.hNextBoss = view_as< BaseBoss >(0);
				}
				if( IsClientValid(next.index) ) {
					next.bIsMinion = true;
					next.ForceTeamChange(gamemode.iHaleTeam);
				}

				if( gamemode.iRoundState == StateRunning )
					ForceTeamWin(gamemode.iOtherTeam);
			}
		}
		else if( gamemode.iRoundState == StateStarting ) {
			BaseBoss replace = gamemode.FindNextBoss();
			if( gamemode.hNextBoss ) {
				replace = gamemode.hNextBoss;
				gamemode.hNextBoss = view_as< BaseBoss >(0);
			}
			if( IsClientValid(replace.index) ) {
				replace.MakeBossAndSwitch(replace.iPresetType == -1 ? leaver.iType : replace.iPresetType, true);
				CPrintToChat(replace.index, "{olive}[VSH 2]{green} Surprise! You're on NOW!");
			}
		}
		CPrintToChatAll("{olive}[VSH 2]{red} A Boss Just Disconnected!");

		delete leaver.hSpecial;
	}
	else
	{
		//if ( IsPlayerAlive(client) )
		SetPawnTimer(CheckAlivePlayers, 0.1);
		if (IsClientInGame(client) && client == gamemode.FindNextBoss().index)
			SetPawnTimer(_SkipBossPanel, 1.0);
		
		if (leaver.userid == gamemode.hNextBoss.userid)
			gamemode.hNextBoss = view_as<BaseBoss>(0);
	}
}

public void ManageOnBossSelected(const BaseBoss base)
{
	ManageBossHelp(base);
	Call_OnBossSelected(base);

//	BaseBoss boss;
//	while (gamemode.iMulti-- > 1)
//	{
//		boss = gamemode.FindNextBoss();
//		if (boss && boss.index)
//			boss.MakeBossAndSwitch(boss.iPresetType == -1 ? GetRandomInt(Hale, MAXBOSS) : boss.iPresetType, false);
//		else
//		{
			//CPrintToChatAll("{orange}[VSH 2]{default} Couldn't find enough bosses to satisfy amount, clamping.");
//			break;
//		}
//	}
//	gamemode.iMulti = 1;

	// Uncomment this and I'll kill you
	/*
	if (gamemode.iPlaying < 10 || GetRandomInt(0, 3) > 0)
		return;

	int extraBosses = gamemode.iPlaying / 12;
	extraBosses = (extraBosses > 1) ? GetRandomInt(1, extraBosses) : extraBosses;
	while (extraBosses-- > 0)
		gamemode.FindNextBoss().MakeBossAndSwitch(GetRandomInt(Hale, MAXBOSS), false);*/
}

public void ManageOnTouchPlayer(const BaseBoss base, const BaseBoss victim)
{
	if (!IsValidEntity(base.index) || !IsValidEntity(victim.index))
		return;
		
	switch (base.iType) {
		case  - 1: {  }
	}
	Call_OnTouchPlayer(base, victim);
}

public void ManageOnTouchBuilding(const BaseBoss base, const int building)
{
	switch (base.iType) {
		case  - 1: {  }
	}
	Call_OnTouchBuilding(base, EntIndexToEntRef(building));
}

public void ManageBossHelp(const BaseBoss base)
{
	switch (base.iType) {
		case  - 1: {  }
		case Hale:ToCHale(base).Help();
		case Vagineer:ToCVagineer(base).Help();
		case CBS:ToCChristian(base).Help();
		case HHHjr:ToCHHHJr(base).Help();
		case Bunny:ToCBunny(base).Help();
	}
}

public void ManageBossThink(const BaseBoss base)
{
	if (!IsPlayerAlive(base.index))
		return;

	switch (base.iType) {
		case  - 1: {  }
		case Hale:ToCHale(base).Think();
		case Vagineer:ToCVagineer(base).Think();
		case CBS:ToCChristian(base).Think();
		case HHHjr:ToCHHHJr(base).Think();
		case Bunny:ToCBunny(base).Think();
	}
	Call_OnBossThink(base);
	/* Adding this so bosses can take minicrits if airborne */
	if (!bMiniStuff)
		TF2_AddCondition(base.index, TFCond_GrapplingHookSafeFall, 0.2);

	if (gamemode.iSpecialRound & ROUND_HVH)
		TF2_AddCondition(base.index, TFCond_TeleportedGlow, 0.2);
}

public void ManageBossModels(const BaseBoss base)
{
	switch (base.iType) {
		case  - 1: {  }
		case Hale:ToCHale(base).SetModel();
		case Vagineer:ToCVagineer(base).SetModel();
		case CBS:ToCChristian(base).SetModel();
		case HHHjr:ToCHHHJr(base).SetModel();
		case Bunny:ToCBunny(base).SetModel();
	}
	Call_OnBossModelTimer(base);
}

public void ManageBossDeath(const BaseBoss base)
{
	if (gamemode.iRoundState == StateStarting)
		return;

	base.iType = base.iPureType;
	switch (base.iType) {
		case  - 1: {  }
		case Hale:ToCHale(base).Death();
		case Vagineer:ToCVagineer(base).Death();
		case CBS:ToCChristian(base).Death();
		case HHHjr:ToCHHHJr(base).Death();
		case Bunny:ToCBunny(base).Death();
	}
	Call_OnBossDeath(base);
}

public void ManageBossEquipment(const BaseBoss base)
{
	switch (base.iType) {
		case  - 1: {  }
		case Hale:ToCHale(base).Equip();
		case Vagineer:ToCVagineer(base).Equip();
		case CBS:ToCChristian(base).Equip();
		case HHHjr:ToCHHHJr(base).Equip();
		case Bunny:ToCBunny(base).Equip();
	}
	Call_OnBossEquipped(base);

	char s[MAX_BOSS_NAME_LENGTH];
	switch (base.iPureType)
	{
		case Hale:strcopy(s, sizeof(s), "Saxton Hale");
		case Vagineer:strcopy(s, sizeof(s), "The Vagineer");
		case HHHjr:strcopy(s, sizeof(s), "The Horseless Headless Horsemann Jr.");
		case CBS:strcopy(s, sizeof(s), "The Christian Brutal Sniper");
		case Bunny:strcopy(s, sizeof(s), "The Easter Bunny");
		default:Call_OnBossSetName(base, s);
	}
	if (s[0] != '\0')
		base.SetName(s);

//	if (gamemode.iSpecialRound & ROUND_MANNPOWER)
//		base.SpawnWeapon("tf_weapon_grapplinghook", 1152, 1, 10, "241 ; 0 ; 280 ; 26 ; 712 ; 1");
}

public void ManageBossTransition(const BaseBoss base, const bool override)/* whatever stuff needs initializing should be done here */
{
	// Awful
	TeleportToSpawn(base.index, GetClientTeam(base.index));

	switch (base.iType)
	{
		case  - 1: {  }
		case Hale:
		TF2_SetPlayerClass(base.index, TFClass_Soldier, _, false);
		case Vagineer:
		TF2_SetPlayerClass(base.index, TFClass_Engineer, _, false);
		case CBS:
		TF2_SetPlayerClass(base.index, TFClass_Sniper, _, false);
		case HHHjr, Bunny:
		TF2_SetPlayerClass(base.index, TFClass_DemoMan, _, false);
	}

//	SetEntProp(base.index, Prop_Send, "m_nSkin", 2);

	ManageBossModels(base);
	switch (base.iType) {
		case  - 1: {  }
		case HHHjr:if (!override) ToCHHHJr(base).flCharge = -1000.0;
		default:if (!override) base.flCharge = -100.0;
	}
	Call_OnBossInitialized(base, override);
	ManageBossEquipment(base);
}

public void ManageMinionTransition(const BaseBoss base)
{
	if( !base.bIsMinion )
		return;

//	base.ForceTeamChange(gamemode.iHaleTeam);
	BaseBoss owner = BaseBoss(base.iOwnerBoss);

	switch (owner.iType)
	{
		case -1: {	}
	}
	Call_OnMinionInitialized(base, owner);
}

public void ManagePlayBossIntro(const BaseBoss base)
{
	switch (base.iType) {
		case  - 1: {  }
		case Hale:ToCHale(base).PlaySpawnClip();
		case Vagineer:ToCVagineer(base).PlaySpawnClip();
		case CBS:ToCChristian(base).PlaySpawnClip();
		case HHHjr:ToCHHHJr(base).PlaySpawnClip();
		case Bunny:ToCBunny(base).PlaySpawnClip();
	}
	Call_OnBossPlayIntro(base);
}

public Action ManageOnBossTakeDamage(const BaseBoss victim, int & attacker, int & inflictor, float & damage, int & damagetype, int & weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Action action, action2;
	switch (victim.iType) {
		case  - 1: {  }
		default:
		{
			if (hFwdCompat[Fwd_OnBossTakeDamage].FindValue(victim.iType) == -1)
				return Call_OnBossTakeDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
			int client = victim.index;
			char trigger[32];
			if (attacker != -1 && GetEdictClassname(attacker, trigger, sizeof(trigger)) && !strcmp(trigger, "trigger_hurt", false))
			{
				if (damage >= 100.0 && !gamemode.bNoTele)
					TeleportToSpawn(client, GetClientTeam(client));

				victim.iHealth -= (damage > 1000.0 ? 1000 : RoundFloat(damage));
				action = Plugin_Changed;
			}
			if (attacker <= 0 || attacker > MaxClients)
				return action;

			if (gamemode.iRoundState == StateStarting)
			{
				damage *= 0.0;
				return Plugin_Changed;
			}

			if (!TF2_IsKillable(victim.index))
				return Plugin_Continue;

			char classname[64], strEntname[32];
			if (IsValidEdict(inflictor))
				GetEntityClassname(inflictor, strEntname, sizeof(strEntname));
			if (IsValidEdict(weapon))
				GetEdictClassname(weapon, classname, sizeof(classname));

			float curtime = GetGameTime();

			if (damagecustom == TF_CUSTOM_BACKSTAB)
			{
				char snd[PLATFORM_MAX_PATH];
				switch (victim.iType)
				{
					case Hale:Format(snd, FULLPATH, "%s%i.wav", HaleStubbed132, GetRandomInt(1, 4));
					case Vagineer:strcopy(snd, FULLPATH, "vo/engineer_positivevocalization01.mp3");
					case HHHjr:Format(snd, FULLPATH, "vo/halloween_boss/knight_pain0%d.mp3", GetRandomInt(1, 3));
					case Bunny:strcopy(snd, PLATFORM_MAX_PATH, BunnyPain[GetRandomInt(0, sizeof(BunnyPain) - 1)]);
				}
				if (snd[0] != '\0')
				{
					EmitSoundToAll(snd, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, victim.index, NULL_VECTOR, NULL_VECTOR, false, 0.0);
					EmitSoundToAll(snd, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, victim.index, NULL_VECTOR, NULL_VECTOR, false, 0.0);
				}

				float changedamage = ((Pow(float(victim.iMaxHealth) * 0.0014, 2.0) + 899.0) - (float(victim.iMaxHealth) * (float(victim.iStabbed) / 100)));
				if (victim.iStabbed < 4)
					victim.iStabbed++;
				damage = changedamage / 3; // You can level "damage dealt" with backstabs
				damagetype |= DMG_CRIT;
				
				EmitSoundToAll("player/spy_shield_break.wav", client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, true, 0.0);
				EmitSoundToAll("player/crit_received3.wav", client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, true, 0.0);
				SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", curtime + 2.0);
				SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", curtime + 2.0);
				SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", curtime + 2.0);

				PrintCenterText(attacker, "You Tickled The Boss!");
				PrintCenterText(client, "You Were Just Backstabbed!");

				int vm = GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
				if (vm > MaxClients && IsValidEntity(vm) && TF2_GetPlayerClass(attacker) == TFClass_Spy)
				{
					int anim = 15;
					SetEntProp(vm, Prop_Send, "m_nSequence", anim);
				}
				Call_OnBossBackstabbed(victim, BaseBoss(attacker));
				action = Plugin_Changed;

				++BaseBoss(attacker).iStabs;
				if (bAch)
					VSH2Ach_AddTo(attacker, A_Backstabber, 1);
			}
			// Detects if boss is damaged by Rock Paper Scissors
			/*if ( !damagecustom
				 && TF2_IsPlayerInCondition(client, TFCond_Taunting)
				 && TF2_IsPlayerInCondition(attacker, TFCond_Taunting) )
			{
				damage = victim.iHealth+0.2;
				BaseBoss(attacker).iDamage += RoundFloat(damage);	// If necessary, just cheat by using the arrays.
				action = Plugin_Changed;
			}*/
			if (damagecustom == TF_CUSTOM_TELEFRAG) 
			{
				damage = victim.iHealth + 0.2;
				int teleowner = FindTeleOwner(attacker);
				if( teleowner != -1 && teleowner != attacker )
				{
					BaseBoss builder = BaseBoss(teleowner);
					builder.iDamage += 5401;
					PrintCenterText(teleowner, "Telefrag assist! Good job setting it up.");
				}
				PrintCenterText(attacker, "Telefrag! You are pro.");
				action = Plugin_Changed;
			}

			if (cvarVSH2[Anchoring].BoolValue && victim.iDifficulty <= 3)
			{
				int iFlags = GetEntityFlags(client);
				if (iFlags & (FL_DUCKING|FL_ONGROUND) == (FL_DUCKING|FL_ONGROUND))
				{
					// If Hale is ducking on the ground, it's harder to knock him back
					damagetype |= DMG_PREVENT_PHYSICS_FORCE;
					action = Plugin_Changed;
				}
			}

			if (StrContains(classname, "tf_weapon_sniperrifle", false) > -1 && gamemode.iRoundState != StateEnding)
			{
				damagetype |= DMG_SLOWBURN|DMG_POISON;

				if ((damagetype & DMG_CRIT) && damagecustom == TF_CUSTOM_HEADSHOT)
					damage *= 1.2;

				float bossGlow = victim.flGlowtime;
				// float chargelevel = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
				float time = (bossGlow > 10 ? 1.0 : 2.0);
				time += (bossGlow > 10 ? (bossGlow > 20 ? 1 : 2) : 4);
				bossGlow += RoundToCeil(time);
				if (bossGlow > 30.0)
					bossGlow = 30.0;
				victim.flGlowtime = bossGlow;

				if (!(damagetype & DMG_CRIT))
				{
					bool ministatus = (TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed) || TF2_IsPlayerInCondition(attacker, TFCond_CritHype));
					damage *= (ministatus) ? 2.222222 : 3.0;
				}
				//if (damage > 450.0 && custom != TF_CUSTOM_HEADSHOT)
				//	damage = 450.0;

				action = Plugin_Changed;
			}
		}
	}
	action2 = Call_OnBossTakeDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
	return action > action2 ? action : action2;
}

public Action ManageOnBossDealDamage(const BaseBoss victim, int & attacker, int & inflictor, float & damage, int & damagetype, int & weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	BaseBoss fighter = BaseBoss(attacker);
	Action action, action2;
	switch (fighter.iType) {
		case  - 1: {  }
		default:
		{
			if (hFwdCompat[Fwd_OnBossDealDamage].FindValue(fighter.iType) == -1)
				return Call_OnBossDealDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);

			if (damagetype & DMG_CRIT)
				damagetype &= ~DMG_CRIT;

			int client = victim.index;

			if (damagecustom == TF_CUSTOM_BOOTS_STOMP)
			{
				float flFallVelocity = GetEntPropFloat(inflictor, Prop_Send, "m_flFallVelocity");
				damage = 10.0 * (GetRandomFloat(0.8, 1.2) * (5.0 * (flFallVelocity / 300.0))); //TF2 Fall Damage formula, modified for VSH2
				action = Plugin_Changed;
			}

			if (TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed))
			{
				ScaleVector(damageForce, 9.0);
				damage *= 0.3;
				action = Plugin_Changed;
			}
			if (TF2_IsPlayerInCondition(client, TFCond_CritMmmph) || TF2_IsPlayerInCondition(client, TFCond_DefenseBuffMmmph))
			{
				damage *= 0.35;
				action = Plugin_Changed;
			}

			int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
			if (medigun != -1
				 && HasEntProp(medigun, Prop_Send, "m_bChargeRelease")
				 && !TF2_IsPlayerInCondition(client, TFCond_Ubercharged)
				 && weapon == GetPlayerWeaponSlot(attacker, 2)) {
				/*
					If medic has (nearly) full uber, use it as a single-hit shield to prevent medics from dying early.
					Entire team is pretty much screwed if all the medics just die.
				*/
				if (GetMediCharge(medigun) >= 1.0)
				{
					SetMediCharge(medigun, 0.2);
					damage *= 10;
					TF2_AddCondition(client, TFCond_UberchargedOnTakeDamage, 0.1);
					EmitSoundToAll("misc/ks_tier_04_kill_01.wav", client);
					action = Plugin_Changed;
				}
			}
		}
	}
	action2 = Call_OnBossDealDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
	return action > action2 ? action : action2;
}
#if defined _goomba_included_
public Action ManageOnGoombaStomp(int attacker, int client, float & damageMultiplier, float & damageAdd, float & JumpPower)
{
	BaseBoss boss = BaseBoss(client);
	if (boss.bIsBoss) //Players Stomping the Boss
	{
		switch (boss.iType)
		{
			case  - 1: {  } // Ignore if not boss at all.
			default: //Default behaviour for Goomba Stompoing the Boss
			{
				if (!TF2_IsKillable(client))
					return Plugin_Handled;

				//TF2_RemoveCondition(client, TFCond_LostFooting);
				damageAdd = float(cvarVSH2[GoombaDamageAdd].IntValue);
				damageMultiplier = cvarVSH2[GoombaLifeMultiplier].FloatValue;
				JumpPower = cvarVSH2[GoombaReboundPower].FloatValue;
				
				//PrintToChatAll("%N Just Goomba stomped %N(The Boss)!", attacker, client);
				//CPrintToChatAllEx(attacker, "{olive}>> {teamcolor}%N {default}just goomba stomped {unique}%N{default}!", attacker, client);
				return Plugin_Changed;
			}
		}
		return Plugin_Continue;
	}
	boss = BaseBoss(attacker);
	if (boss.bIsBoss) //The Boss(es) Stomping a player
	{
		switch (boss.iType)
		{
			case  - 1: {  } // Ignore if !boss at all.
			default: //Default behaviour for the Boss Goomba Stomping other players.
			{
				if (!cvarVSH2[CanBossGoomba].BoolValue)
				{
					return Plugin_Handled; //Block the Boss from Goomba Stomping if disabled.
				}
			}
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}
#endif
public void ManageBossKillPlayer(const BaseBoss attacker, const BaseBoss victim, Event event) // To lazy to code this better lol
{
	// int dmgbits = event.GetInt("damagebits");
	int deathflags = event.GetInt("death_flags");
	if (!event.GetBool("sourcemod") && victim.bIsBoss)
		RequestFrame(FixRagdolls, victim.userid);
	if (victim.bIsBoss && gamemode.iRoundState == StateRunning && !event.GetBool("sourcemod")) // If victim is a boss, kill him off
	{
		if (0 < attacker.index <= MaxClients && IsClientInGame(attacker.index) && attacker.index != victim.index)
		{
			if (bTBC)
			{
				TBC_GiveCredits(attacker.index, 15);
				CPrintToChat(attacker.index, TBC_TAG ... "You have earned {unique}15{default} Gimgims for killing a boss!");
			}
			if (bAch)
			{
				if (GetLivingPlayers(GetClientTeam(attacker.index)) == 1)
					VSH2Ach_AddTo(attacker.index, A_Soloer, 1);

				VSH2Ach_AddTo(attacker.index, A_HaleKiller, 1);
				VSH2Ach_AddTo(attacker.index, A_HaleGenocide, 1);
				VSH2Ach_AddTo(attacker.index, A_HaleExtinction, 1);

				if (!IsPlayerAlive(attacker.index))
					VSH2Ach_AddTo(attacker.index, A_BeyondTheGrave, 1);

//				if (victim.iType == Hale && BeTheRobot_GetRobotStatus(victim.index) == RobotStatus_Robot)
//					VSH2Ach_AddTo(attacker.index, A_BeepBoop, 1);

				switch (event.GetInt("customkill"))
				{
					case TF_CUSTOM_TAUNT_HADOUKEN,
						TF_CUSTOM_TAUNT_HIGH_NOON,
						TF_CUSTOM_TAUNT_GRAND_SLAM,
						TF_CUSTOM_TAUNT_FENCING,
						TF_CUSTOM_TAUNT_ARROW_STAB,
						TF_CUSTOM_TAUNT_GRENADE,
						TF_CUSTOM_TAUNT_BARBARIAN_SWING,
						TF_CUSTOM_TAUNT_UBERSLICE,
						TF_CUSTOM_TAUNT_ENGINEER_SMASH,
						TF_CUSTOM_TAUNT_ENGINEER_ARM,
						TF_CUSTOM_TAUNT_ARMAGEDDON,
						TF_CUSTOM_TAUNTATK_GASBLAST:VSH2Ach_AddTo(attacker.index, A_Embarrassed, 1);
				}

				char wpn[32]; event.GetString("weapon_logclassname", wpn, 32);
				if (!strcmp(wpn, "warfan"))
					VSH2Ach_AddTo(attacker.index, A_Pulverised, 1);
			}
			Call_OnActualBossDeath(victim, attacker, event);
		}
		SetPawnTimer(_BossDeath, 0.1, victim.userid);
		if (victim.bNoRagdoll)
			RequestFrame(RemoveRagdoll, victim.userid);
	}

	if (attacker.bIsBoss)
	{
		if (attacker.index != victim.index && gamemode.iRoundState == StateRunning) 
		{
			if (bAch)
			{
				VSH2Ach_AddTo(attacker.index, A_MercKiller, 1);
				VSH2Ach_AddTo(attacker.index, A_MercGenocide, 1);
				VSH2Ach_AddTo(attacker.index, A_MercExtinction, 1);

				switch (event.GetInt("customkill"))
				{
					case TF_CUSTOM_TAUNT_HADOUKEN,
						TF_CUSTOM_TAUNT_HIGH_NOON,
						TF_CUSTOM_TAUNT_GRAND_SLAM,
						TF_CUSTOM_TAUNT_FENCING,
						TF_CUSTOM_TAUNT_ARROW_STAB,
						TF_CUSTOM_TAUNT_GRENADE,
						TF_CUSTOM_TAUNT_BARBARIAN_SWING,
						TF_CUSTOM_TAUNT_UBERSLICE,
						TF_CUSTOM_TAUNT_ENGINEER_SMASH,
						TF_CUSTOM_TAUNT_ENGINEER_ARM,
						TF_CUSTOM_TAUNT_ARMAGEDDON,
						TF_CUSTOM_TAUNTATK_GASBLAST:VSH2Ach_AddTo(attacker.index, A_Overkill, 1);
				}
			}
			if (gamemode.iSpecialRound & ROUND_SURVIVAL)
				attacker.iSurvKills++;
			switch (attacker.iType)
			{
				case  - 1: {  }
				case Hale:
				{
					if (deathflags & TF_DEATHFLAG_DEADRINGER)
						event.SetString("weapon", "fists");
					else ToCHale(attacker).KilledPlayer(victim, event);
				}
				case Vagineer:ToCVagineer(attacker).KilledPlayer(victim, event);
				case CBS:ToCChristian(attacker).KilledPlayer(victim, event);
				case HHHjr:ToCHHHJr(attacker).KilledPlayer(victim, event);
				case Bunny:ToCBunny(attacker).KilledPlayer(victim, event);
			}
		}
	}
	else if (attacker.bIsMinion && !(deathflags & TF_DEATHFLAG_DEADRINGER))
		if (GetClientTeam(victim.index) == gamemode.iOtherTeam && ++attacker.iKillCount >= 5 && bAch)
			VSH2Ach_AddTo(attacker.index, A_Minion1, 1);
	if (victim.bIsMinion && IsClientValid(attacker.index) && attacker.index != victim.index && GetClientTeam(attacker.index) == gamemode.iOtherTeam)
	{
		if (!(deathflags & TF_DEATHFLAG_DEADRINGER))
			if (++attacker.iKillCount >= 10 && bAch)
				VSH2Ach_AddTo(attacker.index, A_Alternate, 1);
	}
	Call_OnPlayerKilled(attacker, victim, event);
}
public void ManageMinionKillPlayer(const BaseBoss attacker, const BaseBoss victim, Event event)
{
	BaseBoss boss = BaseBoss(attacker.iOwnerBoss);
	switch (boss.iType)
	{
		case -1: {}
	}
}
public void ManageHurtPlayer(const BaseBoss attacker, const BaseBoss victim, Event event)
{
	int damage = event.GetInt("damageamount");
	int custom = event.GetInt("custom");
//	int weapon = event.GetInt("weaponid");
	int client = attacker.index;
	
	switch (victim.iType)
	{
		case  - 1: {  }
		default:
		{
			victim.iHealth -= damage;
			victim.GiveRage(damage);
		}
	}

	if (attacker.bIsMinion || attacker.bIsBoss)
		return;

	if (victim.bIsMinion)
	{
		BaseBoss owner = BaseBoss(victim.iOwnerBoss);
		switch (owner.iType)
		{
			case -1:{}
		}
	}

	if (attacker.bIsBoss && TF2_IsKillable(victim.index))
		++victim.iHits;

	if (custom == TF_CUSTOM_TELEFRAG && victim.bIsBoss)
	{
		damage = (IsPlayerAlive(client) ? 9001 : 1); // Telefrags normally 1-shot the boss but let's cap damage at 9k
		if (bTBC)
		{
			TBC_GiveCredits(client, 20);
			CPrintToChat(client, TBC_TAG ... "You have earned {unique}20{default} Gimgims for telefragging a Boss!");
		}
		if (bAch)
		{
			VSH2Ach_AddTo(client, A_Telefragger, 1);
			VSH2Ach_AddTo(client, A_TelefragMachine, 1);
			VSH2Ach_AddTo(client, A_FrogMan, 1);
			VSH2Ach_AddTo(client, A_MasterFrogMan, 1);
		}
	}
	
	if (victim.bIsBoss && gamemode.iRoundState == StateRunning)
	{
		attacker.iDamage += damage;
		if (bAch)
		{
			VSH2Ach_AddTo(attacker.index, A_Damager, damage);
			VSH2Ach_AddTo(attacker.index, A_DamageKing, damage);
		}
	}
}

public void ManagePlayerAirblast(const BaseBoss airblaster, const BaseBoss airblasted, Event event)
{
	if (!(-1 < airblasted.iDifficulty <= 2))
		return;
	switch (airblasted.iType) {
		case  - 1: {  }
		case Vagineer:
		{
			if (TF2_IsPlayerInCondition(airblasted.index, TFCond_Ubercharged))
				TF2_AddCondition(airblasted.index, TFCond_Ubercharged, 2.0);
			else airblasted.flRAGE += cvarVSH2[AirblastRage].FloatValue;
		}
		default:if (!TF2_IsPlayerInCondition(airblasted.index, TFCond_MegaHeal))
			airblasted.ReceiveGenericRage();
	}
	Call_OnPlayerAirblasted(airblaster, airblasted, event);
}

public Action ManageTraceHit(const BaseBoss victim, const BaseBoss attacker, int & inflictor, float & damage, int & damagetype, int & ammotype, int hitbox, int hitgroup)
{
	switch (victim.iType) {
		case  - 1: {  }
	}
	Call_OnTraceAttack(victim, attacker, inflictor, damage, damagetype, ammotype, hitbox, hitgroup);
	if (damagetype & DMG_BULLET && hitgroup == 1)
	{
		damagetype |= DMG_CRIT;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
public Action OnPlayerRunCmd(int client, int & buttons, int & impulse, float vel[3], float angles[3], int & weapon, int & subtype, int & cmdnum, int & tickcount, int & seed, int mouse[2])
{
	if (!bEnabled.BoolValue || !IsPlayerAlive(client))
		return Plugin_Continue;

	BaseBoss base = BaseBoss(client);

	switch (base.iType)
	{
		case -1:{}
		case Bunny:
		{
			if (GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) == GetActiveWep(client))
			{
				buttons &= ~IN_ATTACK;
				return Plugin_Changed;
			}
		}
		case HHHjr: {
			if (base.flCharge >= 47.0 && (buttons & IN_ATTACK))
			{
				buttons &= ~IN_ATTACK;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	BaseBoss player = BaseBoss(client);
	//int provider = GetConditionProvider(client, condition);
	if (!player.bIsBoss)
	{
		if (condition == TFCond_SpeedBuffAlly && TF2_IsPlayerInCondition(client, TFCond_DeadRingered))
			TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);
	}
	else
	{
		switch (condition)
		{
			case TFCond_Disguised, TFCond_Jarated:TF2_RemoveCondition(client, condition);
//			case TFCond_Dazed:
//			{
//				float dur = GetConditionDuration(client, condition);
//				if (dur >= 0.5)
//					player.flCharge -= dur * 50.0;
//			}
		}
	}
}

public void ManageBossMedicCall(const BaseBoss base)
{
	switch (base.iType) {
		case  - 1: {  }
		default:DoTaunt(base.index, "", 0);
	}
	Call_OnBossMedicCall(base);
}
public Action ManageBossTaunt(const BaseBoss base)
{
	if (gamemode.iRoundState != StateRunning)
		return Plugin_Continue;

	if (base.flRAGE < 100.0)
		return Plugin_Continue;

	switch (base.iType)
	{
		case  - 1: {  }
		case Hale:ToCHale(base).RageAbility();
		case Vagineer:ToCVagineer(base).RageAbility();
		case CBS:ToCChristian(base).RageAbility();
		case HHHjr:ToCHHHJr(base).RageAbility();
		case Bunny:ToCBunny(base).RageAbility();
		default:Call_OnBossTaunt(base);
	}

	if (bAch && base.iType != -1)
	{
		VSH2Ach_AddTo(base.index, A_Rager, 1);
		VSH2Ach_AddTo(base.index, A_EMasher, 1);
		VSH2Ach_AddTo(base.index, A_RageNewb, 1);
	}

	base.flRAGE = 0.0;
	return Plugin_Handled;
}
public void ManageBuildingDestroyed(const BaseBoss base, const int building, const int objecttype, Event event)
{
	switch (base.iType) {
		case  - 1: {  }
		case Hale: {
			event.SetString("weapon", "fists");
			if (!GetRandomInt(0, 3))
			{
				char snd[PLATFORM_MAX_PATH];
				strcopy(snd, FULLPATH, HaleSappinMahSentry132);
				EmitSoundToAll(snd, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, base.index, NULL_VECTOR, NULL_VECTOR, false, 0.0);
				EmitSoundToAll(snd, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, base.index, NULL_VECTOR, NULL_VECTOR, false, 0.0);
			}
		}
	}
	Call_OnBossKillBuilding(base, building, event);
}
public void ManagePlayerJarated(const BaseBoss attacker, const BaseBoss victim)
{
	switch (victim.iType) {
		case  - 1: {  }
		case CBS:
		{
			victim.flRAGE -= cvarVSH2[JarateRage].FloatValue;
			if (bAch)
				VSH2Ach_AddTo(attacker.index, A_DeRage, cvarVSH2[JarateRage].IntValue);
			int ammo = GetAmmo(victim.index, 0);
			if (ammo > 0)
				SetWeaponAmmo(GetPlayerWeaponSlot(victim.index, 0), ammo-1);
		}
		default:victim.RemoveGenericRage(attacker.index);
	}
	Call_OnBossJarated(victim, attacker);
}
public Action SoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (!bEnabled.BoolValue || !IsClientValid(entity))
		return Plugin_Continue;

	BaseBoss base = BaseBoss(entity);

	switch (base.iType) {
		case  - 1: {
			if (StrEqual(sample, "player/pl_impact_stun.wav", false) && gamemode.iRoundState != StateDisabled)
				return Plugin_Handled;
		}
		case Hale:
		{
			if (!strncmp(sample, "vo", 2, false))
				return Plugin_Handled;
		}
		case Vagineer: {
			if (StrContains(sample, "vo/engineer_laughlong01", false)!= - 1)
			{
				strcopy(sample, FULLPATH, VagineerKSpree);
				return Plugin_Changed;
			}
			
			if (!strncmp(sample, "vo", 2, false))
			{
				if (StrContains(sample, "positivevocalization01", false)!= - 1) // For backstab sound
					return Plugin_Continue;
				if (StrContains(sample, "engineer_moveup", false)!= - 1)
					Format(sample, FULLPATH, "%s%i.wav", VagineerJump, GetRandomInt(1, 2));
				
				else if (StrContains(sample, "engineer_no", false)!= - 1 || GetRandomInt(0, 9) > 6)
					strcopy(sample, FULLPATH, "vo/engineer_no01.mp3");
				
				else strcopy(sample, FULLPATH, "vo/engineer_jeers02.mp3");
				return Plugin_Changed;
			}
			else return Plugin_Continue;
		}
		case HHHjr: {
			if (!strncmp(sample, "vo", 2, false))
			{
				if (GetRandomInt(0, 30) <= 10) {
					Format(sample, FULLPATH, "%s0%i.mp3", HHHLaught, GetRandomInt(1, 4));
					return Plugin_Changed;
				}
				if (StrContains(sample, "halloween_boss") == - 1)
					return Plugin_Handled;
			}
		}
		case Bunny: {
			if (StrContains(sample, "gibberish", false) == -1
				 && StrContains(sample, "burp", false) == -1
				 && !GetRandomInt(0, 2)) // Do sound things
			{
				strcopy(sample, PLATFORM_MAX_PATH, BunnyRandomVoice[GetRandomInt(0, sizeof(BunnyRandomVoice) - 1)]);
				return Plugin_Changed;
			}
		}
		default: {
			if (hFwdCompat[Fwd_OnSoundHook].FindValue(base.iType) != -1)
				if (!strncmp(sample, "vo", 2, false))
					return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool & result)
{
	if (!bEnabled.BoolValue)
		return Plugin_Continue;
	
	BaseBoss base = BaseBoss(client);
	switch (base.iType) {
		case  - 1: {  }
		case HHHjr: {
			if (base.iClimbs < 10)
			{
				if (base.ClimbWall(weapon, 600.0, 0.0, false))
				{
					base.flWeighDown = 0.0;
					base.iClimbs++;					
				}
			}
		}
	}
	
	if (!base.bIsBoss) {
		if (TF2_GetPlayerClass(base.index) == TFClass_Sniper && IsWeaponSlotActive(base.index, TFWeaponSlot_Melee))
			base.ClimbWall(weapon, 600.0, 15.0, true);
	}
	return Plugin_Continue;
}

/*
IT SHOULD BE WORTH NOTING THAT ManageMessageIntro IS CALLED AFTER BOSS HEALTH CALCULATION, IT MAY OR MAY NO BE A GOOD IDEA TO RESET BOSS HEALTH HERE IF NECESSARY. ESPECIALLY IF YOU HAVE A MULTIBOSS THAT REQUIRES UNEQUAL HEALTH DISTRIBUTION.
*/
public void ManageMessageIntro(ArrayList bosses) //(const BaseBoss base[34])		// I can't believe this works lmaooo
{
	gameMessage[0] = '\0';
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "func_door"))!= - 1)
	{
		AcceptEntityInput(ent, "Open");
		AcceptEntityInput(ent, "Unlock");
	}
	//Call_OnMessageIntro(bosses);
	int i;
	BaseBoss base;
	int len = bosses.Length;
	char name[MAX_BOSS_NAME_LENGTH];
	int gmflags = gamemode.iSpecialRound;
	for (i = 0; i < len; ++i) {  //for (i=0 ; i<34 ; ++i) {
		base = bosses.Get(i);
		if (base == view_as<BaseBoss>(0))
			continue;

		base.GetName(name);
		Format(gameMessage, MAXMESSAGE, "%s\n%s%N has become %s with %i Health", gameMessage, (gmflags & ROUND_HVH ? (GetClientTeam(base.index) == RED ? "RED's " : "BLU's ") : ""),
						base.index, name, base.iHealth);
		Call_OnMessageIntro(base, gameMessage);
		switch (base.iDifficulty)
		{
			case -1:Format(gameMessage, MAXMESSAGE, "%s\nNo-Rage Mode", gameMessage);
			case 2:Format(gameMessage, MAXMESSAGE, "%s\nHARD MODE", gameMessage);
			case 3:Format(gameMessage, MAXMESSAGE, "%s\nINSANE MODE", gameMessage);
			case 4:Format(gameMessage, MAXMESSAGE, "%s\nIMPOSSIBLE MODE", gameMessage);
		}
	}
	if (gameMessage[0] != '\0')
	{
		if (gmflags & ROUND_SURVIVAL)
			StrCat(gameMessage, sizeof(gameMessage), "\nSURVIVAL MODE");
		if (gmflags & ROUND_MANNPOWER)
			StrCat(gameMessage, sizeof(gameMessage), "\nMANNPOWER MODE");
		if (gmflags & ROUND_HVH)
			StrCat(gameMessage, sizeof(gameMessage), "\nBOSS VS BOSS");

		SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
		for (i = MaxClients; i; --i) {
			if (IsClientValid(i))
				ShowHudText(i, -1, "%s", gameMessage);
			//PrintCenterTextAll(gameMessage);
		}
	}
	//SetPawnTimer(_MusicPlay, 2.0);		// in vsh2.sp
	gamemode.iRoundState = StateRunning;
	delete bosses;
}

public void ManageBossPickUpItem(const BaseBoss base, const char item[64])
{
	//if (GetIndexOfWeaponSlot(base.index, TFWeaponSlot_Melee) == 404)	// block Persian Persuader
	//	return;
	switch (base.iType) {
		case  - 1: {  }
	}
	Call_OnBossPickUpItem(base, item);
}

public void ManageResetVariables(const BaseBoss base)
{
	base.bIsBoss = base.bSetOnSpawn = false;
	base.iType = -1;
	base.iPureType = -1;
	base.iStabbed = 0;
	base.iMarketted = 0;
	base.flRAGE = 0.0;
	base.iDifficulty = 0;
	base.iDamage = 0;
	base.iAirDamage = 0;
	base.iUberTarget = 0;
	base.flCharge = 0.0;
	base.bGlow = 0;
	base.flGlowtime = 0.0;
	base.bUsedUltimate = false;
	base.bIsMinion = false;
	base.bNoRagdoll = false;
	base.iOwnerBoss = 0;
	base.iSongPick = -1;
	SetEntityRenderColor(base.index, 255, 255, 255, 255);
	base.flLastShot = 0.0;
	base.flLastHit = 0.0;
	base.iState = -1;
	base.iHits = 0;
	base.iKillCount = 0;
	base.iLives = ((gamemode.bMedieval || cvarVSH2[ForceLives].BoolValue) ? cvarVSH2[MedievalLives].IntValue : 0);
	base.iHealth = 0;
	base.iMaxHealth = 0;
	base.iShieldDmg = 0;
	base.iStreaks = 0;
	base.iStreakCount = 0;
	base.iStabs = 0;
	base.iSpecial = 0;
	base.iSpecial2 = 0;
	base.iSurvKills = 0;
	base.flSpecial = 0.0;
	base.flSpecial2 = 0.0;
	base.flMusicTime = 0.0;
	delete base.hSpecial;
	base.SetOverlay("0");
	Call_OnVariablesReset(base);
}
public void ManageEntityCreated(const int entity, const char[] classname)
{
//	if (StrContains(classname, "rune")!= - 1) // Special request
//		SDKHook(entity, SDKHook_Spawn, KillOnSpawn);
	
//	if (!cvarVSH2[DroppedWeapons].BoolValue && StrEqual(classname, "tf_dropped_weapon")) //Remove dropped weapons to avoid bad things
//	{
//		AcceptEntityInput(entity, "kill");
//		return;
//	}

	if (gamemode.iRoundState == StateRunning && !strcmp(classname, "tf_projectile_pipe", false))
		SDKHook(entity, SDKHook_SpawnPost, OnEggBombSpawned);

	else if (!strcmp(classname, "tf_ragdoll", false))
		SDKHook(entity, SDKHook_Spawn, OnRagSpawn);
	else if (gamemode.iSpecialRound & ROUND_HVH && !strcmp(classname, "dm_weapon_spawner", false))
		RequestFrame(SetTeam, EntIndexToEntRef(entity));
}

public void OnEggBombSpawned(int entity)
{
	int owner = GetOwner(entity);
	BaseBoss boss = BaseBoss(owner);
	if (IsClientValid(owner) && boss.bIsBoss && boss.iType == Bunny)
		CreateTimer(0.0, Timer_SetEggBomb, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
}

public void ManageUberDeploy(const BaseBoss medic, const BaseBoss patient)
{
	if (medic.bIsMinion)
		return;

	int medigun = GetPlayerWeaponSlot(medic.index, TFWeaponSlot_Secondary);
	if (IsValidEntity(medigun) && HasEntProp(medigun, Prop_Send, "m_bChargeRelease"))
	{
		if (!(gamemode.iSpecialRound & ROUND_HVH))
			TF2_AddCondition(medic.index, TFCond_Kritzkrieged, 0.5, medic.index);

		if (IsClientValid(patient.index) && IsPlayerAlive(patient.index))
		{
			medic.iUberTarget = patient.userid;
			if (!(gamemode.iSpecialRound & ROUND_HVH))
				TF2_AddCondition(patient.index, TFCond_Kritzkrieged, 0.2);
		}
		else medic.iUberTarget = 0;

		Call_OnUberDeployed(medic, patient);
		CreateTimer(0.1, TimerLazor, EntIndexToEntRef(medigun), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void ManageMusic(char song[FULLPATH], float & time)
{
	// UNFORTUNATELY, we have to get a random boss so we can set our music, tragic I know...
	// Remember that you can get a random boss filtered by type as well!
	if (MapHasMusic()) { song[0] = '\0'; time = -1.0; return; }

	BaseBoss currBoss = gamemode.GetRandomBoss(false);
	if (currBoss) {
		switch (currBoss.iPureType) {
			case  - 1: { song[0] = '\0'; time = -1.0; }
			case Hale: {
				switch (GetRandomInt(1, 2))
				{
					case 1:
					{
						strcopy(song, sizeof(song), HaleTheme);
						time = 170.0;
					}
					case 2:
					{
						strcopy(song, sizeof(song), HaleTheme3);
						time = 220.0;
					}
				}
			}
			case Vagineer: {
				switch (GetRandomInt(1, 3))
				{
					case 1:
					{
						strcopy(song, sizeof(song), VagTheme);
						time = 226.0;
					}
					case 2:
					{
						strcopy(song, sizeof(song), VagTheme2);
						time = 212.0;
					}
					case 3:
					{
						strcopy(song, sizeof(song), VagTheme3);
						time = 186.0;
					}
				}
			}
			case CBS: {
				switch (GetRandomInt(1, 3))
				{
					case 1:
					{
						strcopy(song, sizeof(song), CBSTheme);
						time = 140.0;
					}
					case 2:
					{
						strcopy(song, sizeof(song), CBSTheme2);
						time = 146.0;
					}
					case 3:
					{
						strcopy(song, sizeof(song), CBSTheme3);
						time = 217.0;
					}
				}
			}
			case HHHjr: {
				switch (GetRandomInt(1, 3))
				{
					case 1:
					{
						strcopy(song, sizeof(song), HHHTheme);
						time = 90.0;
					}
					case 2:
					{
						strcopy(song, sizeof(song), HHHTheme2);
						time = 150.0;
					}
					case 3:
					{
						strcopy(song, sizeof(song), HHHTheme2);
						time = 234.0;
					}
				}
			}
			case Bunny: {
				switch (GetRandomInt(1, 3)) 
				{
					case 1:
					{
						strcopy(song, sizeof(song), BunnyTheme);
						time = 272.0;
					}
					case 2:
					{
						strcopy(song, sizeof(song), BunnyTheme2);
						time = 153.0;
					}
					case 3:
					{
						strcopy(song, sizeof(song), BunnyTheme3);
						time = 185.0;
					}
				}
			}
			default:Call_OnMusic(song, time, currBoss);
		}
	}
}
public void StopBackGroundMusic()
{
	for (int i = MaxClients; i; --i) 
		if (IsClientInGame(i))
			if (BackgroundSong[i][0] != '\0')
				StopSound(i, SNDCHAN_AUTO, BackgroundSong[i]);
}
public void ManageRoundEndBossInfo(ArrayList bosses, int team) //(const BaseBoss base[34])	// I STILL can't believe this works lmaoooo.
{
	char victory[FULLPATH];
	gameMessage[0] = '\0';
	char name[64];
	char time[32];
	int i = 0;
	BaseBoss base;
	//Call_OnRoundEndInfo(bosses, bossWon);
	int len = bosses.Length;
	bool surv = !!(gamemode.iSpecialRound & ROUND_SURVIVAL);

	for (i = 0; i < len; ++i) {  //for (i=0 ; i<34 ; ++i) {
		base = bosses.Get(i);
		if (base == view_as<BaseBoss>(0))
			continue;

		if (!IsPlayerAlive(base.index) && !surv)
			continue;

		base.GetName(name);
		base.SetName("");

		if (surv)
		{
			FormatTime(time, sizeof(time), "%M:%S", GetTime() - base.iTime);
			Format(gameMessage, MAXMESSAGE, "%s\n%s (%N) got %d kill%s and survived %s.", gameMessage, name, base.index, base.iSurvKills, base.iSurvKills == 1 ? "" : "s", time);
		}
		else Format(gameMessage, MAXMESSAGE, "%s\n%s (%N) had %i (of %i) health left.", gameMessage, name, base.index, base.iHealth, base.iMaxHealth);

		switch (base.iDifficulty)
		{
			case -1:Format(gameMessage, MAXMESSAGE, "%s (No-Rage Mode)", gameMessage);
			case 2:Format(gameMessage, MAXMESSAGE, "%s (HARD MODE)", gameMessage);
			case 3:Format(gameMessage, MAXMESSAGE, "%s (INSANE MODE)", gameMessage);
			case 4:Format(gameMessage, MAXMESSAGE, "%s (IMPOSSIBLE MODE)", gameMessage);
		}
		Call_OnRoundEndInfo(base, team == gamemode.iHaleTeam, gameMessage);
		if (team == GetClientTeam(base.index))
		{
			if (surv)
				CPrintToChat(base.index, "{olive}[VSH 2]{default} You did it!");

			if (bAch)
			{
				if (base.iHealth < 100)
					VSH2Ach_AddTo(base.index, A_CloseCall, 1);
				else if (base.iHealth == base.iMaxHealth)
					VSH2Ach_AddTo(base.index, A_Invincible, 1);
			}
		}
		else if (gamemode.iSpecialRound & ROUND_HVH)
			bosses.Erase(i);
	}

	if (team == gamemode.iHaleTeam && bosses.Length)
	{
		victory[0] = '\0';
		base = bosses.Get(GetRandomInt(0, bosses.Length-1));
		int sndflags = SND_NOFLAGS;
		int pitch = 100;
		switch (base.iType)
		{
			case  -1: {  }
			case Vagineer:Format(victory, FULLPATH, "%s%i.wav", VagineerKSpreeNew, GetRandomInt(1, 5));
			case Bunny:strcopy(victory, FULLPATH, BunnyWin[GetRandomInt(0, sizeof(BunnyWin) - 1)]);
			case Hale:Format(victory, FULLPATH, "%s%i.wav", HaleWin, GetRandomInt(1, 2));
			default:Call_OnBossWin(base, victory, sndflags, pitch);
		}
		if (victory[0] != '\0')
		{
			EmitSoundToAll(victory, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, sndflags, SNDVOL_NORMAL, pitch, base.index, _, NULL_VECTOR, false, 0.0);
			EmitSoundToAll(victory, _, SNDCHAN_ITEM, SNDLEVEL_TRAFFIC, sndflags, SNDVOL_NORMAL, pitch, base.index, _, NULL_VECTOR, false, 0.0);
		}
	}
	if (gameMessage[0] !='\0') {
		CPrintToChatAll("{olive}[VSH 2] End of Round{default} %s", gameMessage);
		SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
		for (i = MaxClients; i; --i) {
			if (IsClientInGame(i) && !(GetClientButtons(i) & IN_SCORE))
				ShowHudText(i, -1, "%s", gameMessage);
		}
	}
	delete bosses;
}
public void ManageLastPlayer()
{
	BaseBoss currBoss = gamemode.GetRandomBoss(true);
	switch (currBoss.iType)
	{
		case  - 1: {  }
		case Hale:ToCHale(currBoss).LastPlayerSoundClip();
		case Vagineer:ToCVagineer(currBoss).LastPlayerSoundClip();
		case CBS:ToCChristian(currBoss).LastPlayerSoundClip();
		case Bunny:ToCBunny(currBoss).LastPlayerSoundClip();
		default:Call_OnLastPlayer(currBoss);
	}
}
public void ManageBossCheckHealth(const BaseBoss base)
{
	static int LastBossTotalHealth;
	float currtime = GetGameTime();
	char name[MAX_BOSS_NAME_LENGTH];
	if (base.bIsBoss) {  // If a boss reveals their own health, only show that one boss' health.
		base.GetName(name);
		PrintCenterTextAll("%s showed his current HP: %i of %i", name, base.iHealth, base.iMaxHealth);
		Call_OnBossHealthCheck(base, true, gameMessage);
		LastBossTotalHealth = base.iHealth;
		return;
	}
	if (currtime >= gamemode.flHealthTime) {  // If a non-boss is checking health, reveal all Boss' hp
		gamemode.iHealthChecks++;
		BaseBoss boss;
		int totalHealth;
		gameMessage[0] = '\0';
		int gmflags = gamemode.iSpecialRound;
		for (int i = MaxClients; i; --i) {
			if (!IsClientInGame(i) || !IsPlayerAlive(i)) // exclude dead bosses for health check
				continue;
			boss = BaseBoss(i);
			if (!boss.bIsBoss)
				continue;

			boss.GetName(name);
			Format(gameMessage, MAXMESSAGE, "%s\n%s%s%s current health is: %i of %i", gameMessage, (gmflags & ROUND_HVH ? (GetClientTeam(i) == RED ? "RED's " : "BLU's ") : ""),
			 				name, (name[strlen(name)-1] == 's' ? "'" : "'s"), boss.iHealth, boss.iMaxHealth);
			Call_OnBossHealthCheck(boss, false, gameMessage);

			if (gameMessage[0] != '\0' && boss.iPureType != -1)
			{
				switch (base.iDifficulty)
				{
					case -1:Format(gameMessage, MAXMESSAGE, "%s. (No-Rage Mode)", gameMessage);
					case 2:Format(gameMessage, MAXMESSAGE, "%s. (HARD MODE)", gameMessage);
					case 3:Format(gameMessage, MAXMESSAGE, "%s. (INSANE MODE)", gameMessage);
					case 4:Format(gameMessage, MAXMESSAGE, "%s. (IMPOSSIBLE MODE)", gameMessage);
				}
			}
			//Call_OnBossHealthCheck(boss);
			totalHealth += boss.iHealth;
		}
		if (gameMessage[0] != '\0')
		{
			if (gmflags & ROUND_SURVIVAL)
				StrCat(gameMessage, sizeof(gameMessage), "\nSURVIVAL MODE");
			if (gmflags & ROUND_MANNPOWER)
				StrCat(gameMessage, sizeof(gameMessage), "\nMANNPOWER MODE");
			if (gmflags & ROUND_HVH)
				StrCat(gameMessage, sizeof(gameMessage), "\nBOSS VS BOSS");
			PrintCenterTextAll(gameMessage);

			CPrintToChatAll("{olive}[VSH 2] Boss Health Check{default} %s", gameMessage);
		}
		LastBossTotalHealth = totalHealth;
		gamemode.flHealthTime = currtime + (gamemode.iHealthChecks < 3 ? 10.0 : 60.0);
	}
	else CPrintToChat(base.index, "{olive}[VSH 2]{default} You can not see the Boss HP now (wait %i seconds). Last known total health was %i.", RoundFloat(gamemode.flHealthTime - currtime), LastBossTotalHealth);
}
public void CheckAlivePlayers()
{
	if (gamemode.iRoundState != StateRunning)
		return;
	
	int living = GetLivingPlayers(gamemode.iHaleTeam);
	if (!living)
		ForceTeamWin(gamemode.iOtherTeam);
	
	living = GetLivingPlayers(gamemode.iOtherTeam);
	if (!living)
		ForceTeamWin(gamemode.iHaleTeam);

	if (!(gamemode.iSpecialRound & ROUND_HVH) && living == 1 && gamemode.GetRandomBoss(true) && gamemode.iTimeLeft <= 0)
	{
		ManageLastPlayer(); // in handler.sp
		gamemode.iTimeLeft = cvarVSH2[LastPlayerTime].IntValue;
		/*int RoundTimer = -1;
		RoundTimer = FindEntityByClassname(RoundTimer, "team_round_timer");
		if (RoundTimer <= 0)
			RoundTimer = CreateEntityByName("team_round_timer");

		if ( RoundTimer > MaxClients && IsValidEntity(RoundTimer) ) {
			SetVariantInt(cvarVSH2[LastPlayerTime].IntValue);
			//DispatchKeyValue(RoundTimer, "targetname", TIMER_NAME);
			//DispatchKeyValue(RoundTimer, "setup_length", setupLength);
			//DispatchKeyValue(RoundTimer, "setup_length", "30");
			DispatchKeyValue(RoundTimer, "reset_time", "1");
			DispatchKeyValue(RoundTimer, "auto_countdown", "1");
			char time[5];
			IntToString(cvarVSH2[LastPlayerTime].IntValue, time, sizeof(time));
			DispatchKeyValue(RoundTimer, "timer_length", time);
			DispatchSpawn(RoundTimer);
		}*/
		CreateTimer(1.0, Timer_DrawGame, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	
	/*int Alive = cvarVSH2[AliveToEnable].IntValue;
	if (!cvarVSH2[PointType].BoolValue && living <= Alive && !gamemode.bPointReady)
	{
		SetControlPoint(true);
		gamemode.bPointReady = true;
	}*/
}
public int ManageSetBossArgs(const char[] bossname, char[] buffer)
{
	int typei = -1;
	if (StrContains("Saxton Hale", bossname, false) != -1)
	{
		typei = Hale;
		strcopy(buffer, MAX_BOSS_NAME_LENGTH, "Saxton Hale");
	}
	else if (StrContains("The Vagineer", bossname, false) != -1)
	{
		typei = Vagineer;
		strcopy(buffer, MAX_BOSS_NAME_LENGTH, "The Vagineer");
	}
	else if (StrContains(bossname, "hhh", false) != -1 || StrContains("The Horseless Headless Horsemann Jr.", bossname, false) != -1)
	{
		typei = HHHjr;
		strcopy(buffer, MAX_BOSS_NAME_LENGTH, "The Horseless Headless Horsemann Jr.");
	}
	else if (StrContains("The Christian Brutal Sniper", bossname, false) != -1)
	{
		typei = CBS;
		strcopy(buffer, MAX_BOSS_NAME_LENGTH, "The Christian Brutal Sniper");
	}
	else if (StrContains("The Easter Bunny", bossname, false) != -1)
	{
		typei = Bunny;
		strcopy(buffer, MAX_BOSS_NAME_LENGTH, "The Easter Bunny");
	}
	else Call_OnSetBossArgs(bossname, typei, buffer);
	return typei;
}

public void ManageOnBossCap(char sCappers[MAXPLAYERS + 1], const int CappingTeam)
{
	switch (CappingTeam) {
		case RED: {  } // Code pertaining to red team here
		case BLU: {  } // Code pertaining to blu team and/or bosses here
	}
	Call_OnControlPointCapped(sCappers, CappingTeam);
}

public void _SkipBossPanel()
{
	BaseBoss upnext[3];
	for (int j = 0; j < 3; ++j) {
		upnext[j] = gamemode.FindNextBoss();
		if (!upnext[j].userid)
			continue;
		upnext[j].bSetOnSpawn = true;
		if (!j) // If up next to become a boss.
			SkipBossPanelNotify(upnext[j].index);
		else if (!IsFakeClient(upnext[j].index))
			CPrintToChat(upnext[j].index, "{olive}[VSH 2]{default} You are going to be a Boss soon! Type {olive}/halenext{default} to check/reset your queue points.");
	}
	for (int n = MaxClients; n; --n) {  // Ughhh, reset shit...
		if (!IsClientValid(n))
			continue;
		upnext[0] = BaseBoss(n);
		if (!upnext[0].bIsBoss)
			upnext[0].bSetOnSpawn = false;
	}
}

public void PrepPlayers(const BaseBoss player)
{
	int client = player.index;
	if (!IsClientValid(client))
		return;

	if (gamemode.iRoundState == StateRunning)
		SetEntityMoveType(player.index, MOVETYPE_WALK);
	else if (gamemode.iRoundState == StateStarting)
		SetEntityMoveType(player.index, MOVETYPE_NONE);

	if (!IsPlayerAlive(client)
		|| gamemode.iRoundState == StateEnding
		|| player.bIsBoss
		|| player.bIsMinion)
	return;

//	TeleportToSpawn(player.index, GetClientTeam(player.index));


	if (!(gamemode.iSpecialRound & ROUND_HVH) && GetClientTeam(client) != gamemode.iOtherTeam && GetClientTeam(client) > int(TFTeam_Spectator) && gamemode.iRoundState != StateDisabled)
	{
		if (!(CheckCommandAccess(player.index, "sm_asdcdfc", ADMFLAG_ROOT, true) && gamemode.iRoundState == StateRunning))
		{
			player.ForceTeamChange(gamemode.iOtherTeam);
			TF2_RegeneratePlayer(client); // Added fix by Chdata to correct team colors
		}
	}
	TF2_RegeneratePlayer(client);
	SetEntityHealth(client, GetEntProp(client, Prop_Data, "m_iMaxHealth"));
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	
	Call_OnPrepRedTeam(player);
}

public void ManageFighterThink(const BaseBoss fighter)
{
	int i = fighter.index;
	int buttons = GetClientButtons(i);
	SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
	if (!IsPlayerAlive(i))
	{
		BaseBoss player;
		int obstarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
		player = BaseBoss(obstarget);
		if (obstarget != i && IsClientValid(obstarget) && player.iType == -1)
		{
			if (!(buttons & IN_SCORE))
				ShowSyncHudText(i, rageHUD, "Damage: %d - %N's Damage: %d", fighter.iDamage, obstarget, player.iDamage);
		}
		else if (!(buttons & IN_SCORE))
			ShowSyncHudText(i, rageHUD, "Damage: %d", fighter.iDamage);

		Call_OnFighterDeadThink(fighter);
		return;
	}

	if (fighter.bIsMinion)
		return;

	if (!(buttons & IN_SCORE))
	{
		if (gamemode.bMedieval || cvarVSH2[ForceLives].BoolValue)
			ShowSyncHudText(i, rageHUD, "Damage: %d | Lives: %d", fighter.iDamage, fighter.iLives);
		else ShowSyncHudText(i, rageHUD, "Damage: %d", fighter.iDamage);
	}
	Call_OnRedPlayerThink(fighter);

	TFClassType TFClass = TF2_GetPlayerClass(i);
	int weapon = GetActiveWep(i);
	char wepclassname[64];
	bool validwep = weapon > MaxClients && IsValidEntity(weapon);
	if (validwep)
		GetEntityClassname(weapon, wepclassname, sizeof(wepclassname));

	if (gamemode.iSpecialRound & ROUND_HVH)
		return;

	int living = GetLivingPlayers(gamemode.iOtherTeam);
	if (living == 1 && !TF2_IsPlayerInCondition(i, TFCond_Cloaked))
	{
		TF2_AddCondition(i, TFCond_Kritzkrieged, 0.2);
		TF2_AddCondition(i, TFCond_Buffed, 0.2);
		return;
	}
	else if (living == 2 && !TF2_IsPlayerInCondition(i, TFCond_Cloaked))
		TF2_AddCondition(i, TFCond_Buffed, 0.2);

	/* THIS section really needs cleaning! */
	TFCond cond = TFCond_Kritzkrieged;
	if (TF2_IsPlayerInCondition(i, TFCond_CritCola) && (TFClass == TFClass_Scout || TFClass == TFClass_Heavy))
	{
		TF2_AddCondition(i, cond, 0.2);
		return;
	}
	
	bool addthecrit = false;
	bool addmini = false;

	if (weapon == GetPlayerWeaponSlot(i, TFWeaponSlot_Melee))
	{
		addthecrit = true;
		if (!strcmp(wepclassname, "tf_weapon_chainsaw", false)
		 || !strcmp(wepclassname, "tf_weapon_knife", false))
			addthecrit = false;
	}
	
	if (addthecrit) {
		TF2_AddCondition(i, cond, 0.2);
		if (addmini && cond != TFCond_Buffed)
			TF2_AddCondition(i, TFCond_Buffed, 0.2);
	}

	if (TF2_IsPlayerInCondition(i, TFCond_Charging))
	{
		int wep = GetPlayerWeaponSlot(i, TFWeaponSlot_Melee);
		if (wep > MaxClients)
		{
			char cls[32]; GetEntityClassname(wep, cls, sizeof(cls));
			if (strcmp(cls, "tf_weapon_chainsaw", false))
				TF2_RemoveCondition(i, TFCond_Charging);
		}
	}
}

public void _RespawnPlayer(BaseBoss player)
{
	TF2_RespawnPlayer(player.index);
}