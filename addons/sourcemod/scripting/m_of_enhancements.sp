#pragma semicolon 1




public Plugin myinfo = 
{
	name =			"[Matty] OF Enhancements",
	author =		"worMatty",
	description =	"Some enhancements for OF servers",
	version =		"0.5",
	url =			""
};




#include <sourcemod>
#include <sdktools>

int g_roundsplayed;

ConVar cvar_printmapname;
ConVar cvar_killammopacks;

ConVar deathmatch;
ConVar hostname;
ConVar mp_maxrounds;
ConVar mp_fraglimit;





public void OnPluginStart()
{
	LoadTranslations("of_enhancements.phrases");
	
	deathmatch		= FindConVar("deathmatch");
	hostname		= FindConVar("hostname");
	hostname.AddChangeHook(ConVar_Hostname);
	mp_maxrounds	= FindConVar("mp_maxrounds");
	mp_fraglimit	= FindConVar("mp_fraglimit");
	
	cvar_killammopacks = CreateConVar("ofe_kill_dropped_ammo_packs", "0", "Kill tf_ammo_pack that drop from players on death to prevent causing a server crash on maps with teleporters");
	cvar_printmapname = CreateConVar("ofe_print_map", "1", "Show the current map in chat every few minutes", _, true, 0.0, true, 1.0);
	CreateTimer(120.0, Timer_ShowMap, _, TIMER_REPEAT);

	RegConsoleCmd("sm_frags", Command_Frags, "Get the frag limit");
	RegConsoleCmd("sm_who", Command_Who, "Who are you spectating?");

	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("teamplay_broadcast_audio", Event_AnnouncerLines);
	HookEvent("teamplay_round_win", Event_RoundWin);
	HookEvent("teamplay_win_panel", Event_WinPanel);
}




public void OnMapStart()
{
	// reset the count of rounds played
	g_roundsplayed = 0;
}



public void OnMapEnd()
{
	// allow ammo packs to drop from killed players again
	cvar_killammopacks.BoolValue = false;
}




public void OnEntityCreated(int entity, const char[] classname)
{
	// optionally kill dropped ammo packs
	if (cvar_killammopacks.BoolValue && StrEqual(classname, "tf_ammo_pack"))
	{
		AcceptEntityInput(entity, "Kill");
	}
}




public void OnGameFrame()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 1)
		{
			int target = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
			
			if (0 < target <= MaxClients && IsClientInGame(target))
			{
				char authid[64];
				GetClientAuthId(target, AuthId_Engine, authid, sizeof(authid));
				PrintCenterText(i, "%N  #%d  %s", target, GetClientUserId(target), authid);
			}
		}
	}
}




Action Timer_ShowMap(Handle timer)
{
	// display map name in chat
	char map[64];
	if (GetCurrentMap(map, sizeof(map)) > 0 && cvar_printmapname.BoolValue)
	{
		PrintToChatAll("%t%t", "prefix_of", "ofe_current_map", map);
	}
}




void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("userid"));
	int team = event.GetInt("team");
	
	if (player && team)
	{
		char maxrounds[32];
		char map[32];
		
		GetCurrentMap(map, sizeof(map));
		
		if (mp_maxrounds.IntValue > 1)
		{
			Format(maxrounds, sizeof(maxrounds), "%t", "ofe_welcome_fraglimit_rounds", mp_maxrounds.IntValue);
		}
		
		// print current map, frag limit and round limit to player
		PrintToChat(player, "%t%t", "prefix_of", "ofe_welcome_fraglimit", map, mp_fraglimit.IntValue, maxrounds);
	}
}



/*
When a round is won

Server event "teamplay_win_panel", Tick 694824:
- "panel_style" = "0"
- "winning_team" = "4"
- "winreason" = "12"
- "cappers" = ""
- "flagcaplimit" = "3"
- "blue_score" = "0"
- "red_score" = "0"
- "blue_score_prev" = "0"
- "red_score_prev" = "0"
- "round_complete" = "1"
- "rounds_remaining" = "0"
- "player_1" = "1"
- "player_1_points" = "25"
- "player_2" = "10"
- "player_2_points" = "3"
- "player_3" = "3"
- "player_3_points" = "3"
Server event "teamplay_round_win", Tick 694824:
- "team" = "4"
- "winreason" = "12"
- "flagcaplimit" = "0"
- "full_round" = "1"
- "round_time" = "287.04"
- "losing_team_num_caps" = "0"
- "was_sudden_death" = "0"

The panel takes a few seconds to appear.
*/


void Event_RoundWin(Event event, const char[] name, bool dontBroadcast)
{
	g_roundsplayed += 1;
	
	if (g_roundsplayed <= mp_maxrounds.IntValue)
	{
		// print number of rounds played
		PrintToChatAll("%t%t", "prefix_of", "ofe_rounds_played", g_roundsplayed, mp_maxrounds.IntValue);
	}
}


void Event_WinPanel(Event event, const char[] name, bool dontBroadcast)
{
	if (!deathmatch.BoolValue)
		return;
	
	int leader = event.GetInt("player_1");
	int points = event.GetInt("player_1_points");
	
	if (!leader || !points)
		return;

	char leadername[64];	
	float namecolor[3];
	int resource = GetPlayerResourceEntity();
	
	if (resource != -1)
	{
		GetEntPropVector(resource, Prop_Send, "m_vecColors", namecolor, leader);
		Format(leadername, sizeof(leadername), "\x08%X%X%XFF%N", RoundFloat(namecolor[0] * 255), RoundFloat(namecolor[1] * 255), RoundFloat(namecolor[2] * 255), leader);
	}
	else
	{
		Format(leadername, sizeof(leadername), "\x03%N", leader);
	}

	PrintToChatAll("%t%t", "prefix_of", "ofe_deathmatch_winning_player_points", leadername, points);
}




Action Event_AnnouncerLines(Event event, const char[] name, bool dontBroadcast)
{
	char sound[64];
	event.GetString("sound", sound, sizeof(sound));
	
	if (StrEqual(sound, "FragsLeft3"))
	{
		if (event.GetInt("team") == 4) PrintToChatAll("%t%t", "prefix_of", "ofe_frags_left_three");
	}
	
	if (StrEqual(sound, "FragsLeft2"))
	{
		if (event.GetInt("team") == 4) PrintToChatAll("%t%t", "prefix_of", "ofe_frags_left_two");
	}
	
	if (StrEqual(sound, "FragsLeft1"))
	{
		if (event.GetInt("team") == 4) PrintToChatAll("%t%t", "prefix_of", "ofe_frags_left_one");
	}
	
	//if (StrEqual(sound, "FragsLeft0"))
	//{
		//if (event.GetInt("team") == 4) PrintToChatAll("%t%t", "prefix_of", "ofe_frag_limit_reached");
	//}
}




// Commands

Action Command_Frags(int client, int args)
{
	ReplyToCommand(client, "%t%t", "prefix_of", "ofe_command_frag_limit", mp_fraglimit.IntValue);
	return Plugin_Handled;
}


#define TEST_COLOR

Action Command_Who (int client, int args)
{
	int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	
	if (!IsPlayerAlive(client) && 0 < target <= MaxClients && IsClientInGame(target))
	{
		char authid[64];
		GetClientAuthId(target, AuthId_Engine, authid, sizeof(authid));

		float color[3];
		bool colored;
		int resource = GetPlayerResourceEntity();
		if (resource != -1)
		{
			GetEntPropVector(resource, Prop_Send, "m_vecColors", color, target);
			
			if (color[0] + color[1] + color[2] != 0.0)
			{
				colored = true;
			}
		}
		
		char hexcolor[16];
		Format(hexcolor, sizeof(hexcolor), "\x08%X%X%XFF", RoundFloat(color[0] * 255), RoundFloat(color[1] * 255), RoundFloat(color[2] * 255));
		ReplyToCommand(client, "\x01You're spectating %s%N\x01 (#%d / %s)", (colored) ? hexcolor : "", target, GetClientUserId(target), authid);
	}
	else
	{
		ReplyToCommand(client, "You aren't currently spectating anyone");
	}
	
	return Plugin_Handled;
}




// Hostname

void ConVar_Hostname(ConVar convar, const char[] oldValue, const char[] newValue)
{
	char version[8] = "Unknown";
	File file = OpenFile(".revision", "r");
	
	if (file != null)
	{
		ReadFileLine(file, version, sizeof(version));
		CleanString(version);
		
		char sHostname[256];
		hostname.GetString(sHostname, sizeof(sHostname));
		
		if (ReplaceString(sHostname, sizeof(sHostname), "{revision}", version))
		{
			hostname.SetString(sHostname, true, true);
			LogMessage("Set hostname to \"%s\"", sHostname);
		}
	}
	
	delete file;
}




// Stocks

/**
 * Remove special characters from a parsed string.
 * 
 * @param		char	String
 * @noreturn
 */
stock void CleanString(char[] buffer)
{
	// Get the length of the string
	int len = strlen(buffer);
	
	// For every character, if it's a special character replace it with whitespace
	for (int i = 0; i < len; i++)
	{
		switch (buffer[i])
		{
			case '\r': buffer[i] = ' ';
			case '\n': buffer[i] = ' ';
			case '\t': buffer[i] = ' ';
		}
	}

	// Remove whitespace from the beginning and end
	TrimString(buffer);
}