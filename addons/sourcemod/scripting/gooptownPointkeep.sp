#include <sourcemod>
#include <sdkhooks>
#include <adt_trie>

#define PLUGIN_VERSION "0.1.0"
 
public Plugin myinfo =
{
	name = "GOOPTOWN - Pointkeep",
	author = "GoopSwagger",
	description = "Dead simple.",
	version = PLUGIN_VERSION,
	url = ""
};

new StringMap:pointMap;

public OnMapStart()
{
	pointMap = new StringMap();
	
	for(int i = 0; i < MAXPLAYERS; i++) {
		if(IsClientValid(i)) SetEntProp(i, Prop_Data, "m_iFrags", 0);
	}
}

public void OnClientPutInServer(int client)
{
	if(IsValidEntity(client))
	{
		decl String:steamID[64];
		GetClientAuthId(client, AuthId_Engine, steamID, sizeof(steamID));
		
		new frags;
		pointMap.GetValue(steamID, frags)

		SetEntProp(client, Prop_Data, "m_iFrags", frags)
	}
}

public OnClientDisconnect(client)
{
	if(IsValidEntity(client))
	{
		decl String:steamID[64];
		GetClientAuthId(client, AuthId_Engine, steamID, sizeof(steamID));

		new frags = GetEntProp(client, Prop_Data, "m_iFrags");
	
		pointMap.SetValue(steamID, frags);
	}
} 

stock bool IsClientValid(int client)
{
    return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client));
} 








