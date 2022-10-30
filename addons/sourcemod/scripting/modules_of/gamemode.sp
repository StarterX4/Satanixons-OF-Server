StringMap hGameModeFields ;
//bool g_bBlockHeal;

methodmap VSHGameMode /* < StringMap */		/* all game mode oriented code should be handled HERE ONLY */
{
	public VSHGameMode()
	{
		hGameModeFields = new StringMap();
	}
	property int iRoundState
	{
		public get()
		{
			int i; hGameModeFields.GetValue("iRoundState", i);
			return i;
		}
		public set(const int val)
		{
			hGameModeFields.SetValue("iRoundState", val);
		}
	}
	property int iSpecial
	{
		public get()
		{
			int i; hGameModeFields.GetValue("iSpecial", i);
			return i;
		}
		public set(const int val)
		{
			hGameModeFields.SetValue("iSpecial", val);
		}
	}
	property int iSpecial2
	{
		public get()
		{
			int i; hGameModeFields.GetValue("iSpecial2", i);
			return i;
		}
		public set(const int val)
		{
			hGameModeFields.SetValue("iSpecial2", val);
		}
	}
	property int iBossCount
	{
		public get()
		{
			int i; hGameModeFields.GetValue("iBossCount", i);
			return i;
		}
		public set(const int val)
		{
			hGameModeFields.SetValue("iBossCount", val);
		}
	}
	property int iSpecialRound
	{
		public get()
		{
			int i; hGameModeFields.GetValue("iSpecialRound", i);
			return i;
		}
		public set(const int val)
		{
			hGameModeFields.SetValue("iSpecialRound", val);
		}
	}
	property int iSpecialRoundPreset
	{
		public get()
		{
			int i; hGameModeFields.GetValue("iSpecialRoundPreset", i);
			return i;
		}
		public set(const int val)
		{
			hGameModeFields.SetValue("iSpecialRoundPreset", val);
		}
	}
	property int iPlaying
	{
		public get()
		{
			int playing = 0;
			for (int i=MaxClients ; i ; --i) {
				if (!IsClientInGame(i))
					continue;
				else if (!IsPlayerAlive(i))
					continue;
				if (BaseBoss(i).bIsBoss)
					continue;
				++playing;
			}
			return playing;
		}
	}
	property int iTotalMaxHealth
	{
		public get()
		{
			int i; hGameModeFields.GetValue("iTotalMaxHealth", i);
			return i;
		}
		public set(const int val)
		{
			hGameModeFields.SetValue("iTotalMaxHealth", val);
		}
	}
	property int iTimeLeft
	{
		public get()
		{
			int i; hGameModeFields.GetValue("iTimeLeft", i);
			return i;
		}
		public set(const int val)
		{
			hGameModeFields.SetValue("iTimeLeft", val);
		}
	}
	property int iRoundCount
	{
		public get()
		{
			int i; hGameModeFields.GetValue("iRoundCount", i);
			return i;
		}
		public set(const int val)
		{
			hGameModeFields.SetValue("iRoundCount", val);
		}
	}
	property int iHealthChecks
	{
		public get()
		{
			int i; hGameModeFields.GetValue("iHealthChecks", i);
			return i;
		}
		public set(const int val)
		{
			hGameModeFields.SetValue("iHealthChecks", val);
		}
	}
	property int iCaptures
	{
		public get()
		{
			int i; hGameModeFields.GetValue("iCaptures", i);
			return i;
		}
		public set(const int val)
		{
			hGameModeFields.SetValue("iCaptures", val);
		}
	}
	property int iMulti
	{
		public get()
		{
			int i; hGameModeFields.GetValue("iMulti", i);
			return i;
		}
		public set(const int val)
		{
			hGameModeFields.SetValue("iMulti", val);
		}
	}
	property int iHaleTeam
	{
		public get()
		{
			int i; hGameModeFields.GetValue("iHaleTeam", i);
			return i;
		}
		public set(const int val)
		{
			hGameModeFields.SetValue("iHaleTeam", val);
		}
	}
	property int iOtherTeam
	{
		public get()
		{
			return this.iHaleTeam == RED ? BLU : RED;
		}
	}

#if defined _steamtools_included
	property bool bSteam
	{
		public get()
		{
			bool i; hGameModeFields.GetValue("bSteam", i);
			return i;
		}
		public set(const bool val)
		{
			hGameModeFields.SetValue("bSteam", val);
		}
	}
#endif
#if defined _tf2attributes_included
	property bool bTF2Attribs
	{
		public get()
		{
			bool i; hGameModeFields.GetValue("bTF2Attribs", i);
			return i;
		}
		public set(const bool val)
		{
			hGameModeFields.SetValue("bTF2Attribs", val);
		}
	}
#endif
	property bool bPointReady
	{
		public get()
		{
			bool i; hGameModeFields.GetValue("bPointReady", i);
			return i;
		}
		public set(const bool val)
		{
			hGameModeFields.SetValue("bPointReady", val);
		}
	}
	property bool bMedieval
	{
		public get()
		{
			bool i; hGameModeFields.GetValue("bMedieval", i);
			return i;
		}
		public set(const bool val)
		{
			hGameModeFields.SetValue("bMedieval", val);
		}
	}
	property bool bNoTele
	{
		public get()
		{
			bool i; hGameModeFields.GetValue("bNoTele", i);
			return i;
		}
		public set(const bool val)
		{
			hGameModeFields.SetValue("bNoTele", val);
		}
	}

	property float flHealthTime
	{
		public get()
		{
			float i; hGameModeFields.GetValue("flHealthTime", i);
			return i;
		}
		public set(const float val)
		{
			hGameModeFields.SetValue("flHealthTime", val);
		}
	}
	property BaseBoss hNextBoss
	{
		public get()
		/*{
			if (!preselected.userid || !IsClientValid(preselected.index))
				return view_as< BaseBoss >(0);
			return preselected;
		}*/
		{
			BaseBoss i; hGameModeFields.GetValue("hNextBoss", i);
			if (!i || !i.index)
				return view_as< BaseBoss >(0);
			return i;
		}
		public set(const BaseBoss val)
		{
			hGameModeFields.SetValue("hNextBoss", val);
		}
	}

	property TFClassType iRushPre
	{
		public get()
		{
			TFClassType i; hGameModeFields.GetValue("iRushPre", i);
			return i;
		}
		public set(const TFClassType val)
		{
			hGameModeFields.SetValue("iRushPre", val);
		}
	}

	property TFClassType iRush
	{
		public get()
		{
			TFClassType i; hGameModeFields.GetValue("iRush", i);
			return i;
		}
		public set(const TFClassType val)
		{
			hGameModeFields.SetValue("iRush", val);
		}
	}
	/*
	property Handle hMusic
	{
		public get()			{ return hMusicTimer; }
		public set(const Handle val)	{ hMusicTimer = val; }
	}
	*/

	public void Init()	// When adding a new property, make sure you initialize it to a default 
	{
		this.iRoundState = 0;
		this.iSpecial = -1;
		this.iSpecial2 = 0;
		this.iSpecialRound = 0;
		this.iSpecialRoundPreset = 0;
		this.iTotalMaxHealth = 0;
		this.iTimeLeft = 0;
		this.iRoundCount = 0;
		this.iHealthChecks = 0;
		this.iCaptures = 0;
		this.iMulti = 1;
		this.iHaleTeam = BLU;
		this.iBossCount = 0;
#if defined _steamtools_included
		this.bSteam = false;
#endif
		this.bPointReady = false;
		this.bMedieval = false;
		this.bNoTele = false;
		this.flHealthTime = 0.0;
		this.iRushPre = TFClass_Unknown;
		this.iRush = TFClass_Unknown;
		this.hNextBoss = view_as< BaseBoss >(0);
	}

	public BaseBoss GetRandomBoss(const bool balive)
	{
		BaseBoss[] bosses = new BaseBoss[MaxClients];
		BaseBoss boss;
		int count;
		for (int i=MaxClients ; i ; --i)
		{
			if (!IsClientInGame(i) )
				continue;
			else if (balive && !IsPlayerAlive(i))
				continue;
			boss = BaseBoss(i);
			if (!boss.bIsBoss)
				continue;

			bosses[count++] = boss;
		}
		return (!count ? view_as< BaseBoss >(0) : bosses[GetRandomInt(0, count-1)]);
	}
	public BaseBoss GetBossByType(const bool balive, const int type)
	{
		BaseBoss boss;
		for (int i=MaxClients ; i ; --i) {
			if (!IsClientInGame(i) )
				continue;
			else if (balive && !IsPlayerAlive(i))
				continue;
			boss = BaseBoss(i);
			if (!boss.bIsBoss)
				continue;
			if (boss.iType == type)
				return boss;
		}
		return view_as< BaseBoss >(0);
	}
	public void CheckArena(const bool type)
	{
		if (type)
			SetArenaCapEnableTime(9999.0);
		else {
			SetArenaCapEnableTime(0.0);
			SetControlPoint(false);
		}
	}
	public BaseBoss FindNextBoss()
	{
		BaseBoss tBoss;
		int points = -999;
		BaseBoss boss;
		for (int i=MaxClients ; i ; --i) {
			if ( !IsValidClient(i) )
				continue;
			else if ( GetClientTeam(i) <= int(TFTeam_Spectator) )
				continue;
			boss = BaseBoss(i);
			if (boss.iQueue >= points && !boss.bSetOnSpawn) {
				tBoss = boss;
				points = boss.iQueue;
			}
		}
		return tBoss;
	}
	public BaseBoss FindNextBossEx(bool[] array)
	{
		BaseBoss tBoss;
		int points = -999;
		BaseBoss boss;
		for (int i=MaxClients ; i ; --i) {
			if ( !IsValidClient(i) )
				continue;
			else if ( GetClientTeam(i) <= int(TFTeam_Spectator) )
				continue;
			boss = BaseBoss(i);
			if (boss.iQueue >= points && !boss.bSetOnSpawn && !array[i]) {
				tBoss = boss;
				points = boss.iQueue;
			}
		}
		return tBoss;
	}
	public int CountBosses(const bool balive)
	{
		BaseBoss boss;
		int count=0;
		for (int i=MaxClients ; i ; --i) {
			if (!IsClientInGame(i) || GetClientTeam(i) <= SPEC)
				continue;
			else if (balive && !IsPlayerAlive(i))
				continue;
			boss = BaseBoss(i);
			if (!boss.bIsBoss)
				continue;
			++count;
		}
		return (count);
	}
	public int GetTotalBossHealth()
	{
		BaseBoss boss;
		int count=0;
		for (int i=MaxClients ; i ; --i) {
			if (!IsValidClient(i) )
				continue;

			boss = BaseBoss(i);
			if (!boss.bIsBoss)
				continue;
			count += boss.iHealth;
		}
		return (count);
	}
	public void SearchForItemPacks()
	{
		bool foundAmmo, foundHealth;
		int ent = -1, count = 0;
		float pos[3];
		while ( (ent = FindEntityByClassname(ent, "item_ammopack_full")) != -1 )
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
			AcceptEntityInput(ent, "Kill");

			DataPack vecPack;
			CreateDataTimer(0.2, SetSmallAmmoPack, vecPack);
			vecPack.WriteFloat(pos[0]);
			vecPack.WriteFloat(pos[1]);
			vecPack.WriteFloat(pos[2]);
			count++;
			foundAmmo = (count > 4);
		}
		ent = -1;
		count = 0;
		while ((ent = FindEntityByClassname(ent, "item_ammopack_medium")) != -1)
		{
			//SetEntProp(ent, Prop_Send, "m_iTeamNum", manager.bMainEnable ? manager.iRedTeam : 0, 4);
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
			AcceptEntityInput(ent, "Kill");

			DataPack vecPack;
			CreateDataTimer(0.2, SetSmallAmmoPack, vecPack);
			vecPack.WriteFloat(pos[0]);
			vecPack.WriteFloat(pos[1]);
			vecPack.WriteFloat(pos[2]);
			count++;
			if (!foundAmmo)
				foundAmmo = (count > 4);
		}
		ent = -1;
		count = 0;
		while ((ent = FindEntityByClassname(ent, "item_ammopack_small")) != -1)
		{
			count = 0;
			count++;
			if (!foundAmmo)
				foundAmmo = (count > 4);
		}
		ent = -1;
		count = 0;
		while ( (ent = FindEntityByClassname(ent, "item_healthkit_small")) != -1 )
		{
			count++;
			if (!foundHealth)
				foundHealth = (count > 4); //true;
		}
		ent = -1;
		count = 0;
		while ( (ent = FindEntityByClassname(ent, "item_healthkit_medium")) != -1 )
		{
			count++;
			if (!foundHealth)
				foundHealth = (count > 2);//true;
		}
		ent = -1;
		count = 0;
		while ( (ent = FindEntityByClassname(ent, "item_healthkit_full")) != -1 )
		{
			count++;
			if (!foundHealth)
				foundHealth = (count > 2); //true;
		}
		if (!foundAmmo)
			SpawnRandomAmmo();
		if (!foundHealth)
			SpawnRandomHealth();
	}
	public void UpdateBossHealth()
	{
		if (this.iRoundState != StateRunning)
			return;

		if (Call_OnHealthBarUpdate() != Plugin_Continue)
			return;

		BaseBoss boss;
		int totalHealth, bosscount;
		for (int i=MaxClients; i ; --i) {
			if (!IsClientInGame(i))	// don't count dead bosses
				{continue;}
			boss = BaseBoss(i);
			if (!boss.bIsBoss)
				{continue;}
			bosscount++;
			totalHealth += boss.iHealth;
			if (!IsPlayerAlive(i))
				totalHealth -= boss.iHealth;
		}
	}
	public void GetBossType()
	{
		if (this.hNextBoss && this.hNextBoss.iPresetType > -1) {
			this.iSpecial = this.hNextBoss.iPresetType;
			if ( this.iSpecial > MAXBOSS)
				this.iSpecial = MAXBOSS;
			return;
		}
		BaseBoss boss = this.FindNextBoss();
		if (!boss)
		{
			this.iSpecial = VSH2GetRandomInt(Hale, MAXBOSS);
			return;
		}

		if (boss.iPresetType > -1 && this.iSpecial == -1) {
			this.iSpecial = boss.iPresetType;
			boss.iPresetType = -1;
			if ( this.iSpecial > MAXBOSS )
				this.iSpecial = MAXBOSS;
			return;
		}
		if (this.iSpecial > -1)
		{	// Clamp the chosen special so we don't error out.
			if ( this.iSpecial > MAXBOSS)
				this.iSpecial = MAXBOSS;
		}
		else this.iSpecial = VSH2GetRandomInt(Hale, MAXBOSS);
	}
	public int CountMinions(const bool balive)
	{
		BaseBoss boss;
		int count=0;
		for( int i=MaxClients ; i ; --i ) {
			if( !IsClientInGame(i) )
				continue;
			else if( balive && !IsPlayerAlive(i) )
				continue;
			boss = BaseBoss(i);
			if( !boss.bIsMinion )
				continue;
			++count;
		}
		return( count );
	}
	public void ToggleTriggerList()
	{
		char config[FULLPATH], currentmap[64];
		GetCurrentMap(currentmap, sizeof(currentmap));

		BuildPath(Path_SM, config, FULLPATH, "configs/saxton_hale/tele_whitelist.cfg");
		if (!FileExists(config)) {
			LogError("[VSH 2] ERROR: **** No VSH2 Teleport Whitelist Found! ****");
			this.bNoTele = false;
			return;
		}

		File file = OpenFile(config, "r");
		if ( !file ) {
			LogError("[VSH 2] **** Error Reading Maps from %s Config ****", config);
			return;
		}

		int tries;
		while ( file.ReadLine(config, sizeof(config)) && tries < 100 )
		{
			++tries;
			if (tries == 100) {
				LogError("[VSH 2] **** Breaking Loop Looking For a Map ****");
				this.bNoTele = false;
				return;
			}

			Format(config, strlen(config)-1, config);
			if (!strncmp(config, "//", 2, false))
				continue;

			if ( !StrContains(currentmap, config, false) )
			{
				file.Close();
				this.bNoTele = true;
				return;
			}
		}
		delete file;
		this.bNoTele = false;
		return;
	}
	public int GetBosses(BaseBoss[] bossarray, const bool balive)
	{
		int count;
		BaseBoss boss;
		for( int i=MaxClients; i; --i ) {
			if( !IsClientInGame(i) )
				continue;
			else if( balive && !IsPlayerAlive(i) )
				continue;

			boss = BaseBoss(i);
			if( boss.bIsBoss )
				bossarray[count++] = boss;
		}
		return count;
	}
};

public Action SetSmallAmmoPack(Handle timer, DataPack pack)
{
	pack.Reset();

	float vecPos[3];
	vecPos[0] = pack.ReadFloat();
	vecPos[1] = pack.ReadFloat();
	vecPos[2] = pack.ReadFloat();

	int ammopacker = CreateEntityByName("item_ammopack_small");
	TeleportEntity(ammopacker, vecPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(ammopacker);
	//SetEntProp(ammopacker, Prop_Send, "m_iTeamNum", manager.bMainEnable ? manager.iRedTeam : 0, 4);
	return Plugin_Continue;
}
