#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required

Cookie g_hCookie;
bool g_bSound[MAXPLAYERS+1] = {true, ...};

ConVar g_cvVolume;

public Plugin myinfo =
{
	name = "Toggle Impact Sounds",
	author = "Snowy, koen", // With additional code from AntiTeal
	description = "Adjust volume of body shot and headshot sounds",
	version = "2.0",
	url = ""
};

public void OnPluginStart()
{
	AddNormalSoundHook(SoundHook);

	SetCookieMenuItem(CookieHandler, INVALID_HANDLE, "Hitsound Volume");

	g_cvVolume = CreateConVar("sm_hitsound_volume", "0.3", "Defalt volume of hitsounds if not disabled", _, true, 0.0, true, 1.0);
	AutoExecConfig(true);

	RegConsoleCmd("sm_impactsound", Command_Hitsound, "Toggle hitsounds");
	RegConsoleCmd("sm_impactsounds", Command_Hitsound, "Toggle hitsounds");
	RegConsoleCmd("sm_stopsoundmore", Command_Hitsound, "Toggle hitsounds");

	g_hCookie = RegClientCookie("toggle_hitsound", "Toggle Hitsounds", CookieAccess_Private);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
}

//--------------------------------------------------
// Purpose: Reset client volume on disconnect
//--------------------------------------------------
public void OnClientDisconnect(int client)
{
	g_bSound[client] = true;
}

//--------------------------------------------------
// Purpose: Cookie menu handler
//--------------------------------------------------
public void CookieHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			Format(buffer, maxlen, "Hitsounds: %s", g_bSound[client] ? "Enabled" : "Disabled");
		}
		case CookieMenuAction_SelectOption:
		{
			ToggleHitsound(client);
			ShowCookieMenu(client);
		}
	}
}

//--------------------------------------------------
// Purpose: Hitsound volume command callback
//--------------------------------------------------
public Action Command_Hitsound(int client, int args)
{
	if (!IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	ToggleHitsound(client);
	return Plugin_Handled;
}

//--------------------------------------------------
// Purpose: Toggle hitsounds function
//--------------------------------------------------
public void ToggleHitsound(int client)
{
	g_bSound[client] = !g_bSound[client];
	PrintToChat(client, " \x04[SM] \x01Hitsounds are now %s", g_bSound[client] ? "\x04enabled" : "\x07disabled");
	SaveClientCookies(client);
}

//--------------------------------------------------
// Purpose: Cookie functions
//--------------------------------------------------
public void OnClientCookiesCached(int client)
{
	char buffer[4];
	GetClientCookie(client, g_hCookie, buffer, sizeof(buffer));

	if (buffer[0] == '\0')
	{
		g_bSound[client] = true;
		SaveClientCookies(client);
		return;
	}

	g_bSound[client] = StrEqual(buffer, "1");
}

public void SaveClientCookies(int client)
{
	char buffer[4];
	Format(buffer, sizeof(buffer), "%b", g_bSound[client]);
	SetClientCookie(client, g_hCookie, buffer);
}

//--------------------------------------------------
// Purpose: Sound hook
//--------------------------------------------------
public Action SoundHook(int clients[MAXPLAYERS], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed)
{
	if ((StrContains(sample, "physics/flesh/flesh_impact_bullet") != -1) || (StrContains(sample, "player/headshot") != -1))
	{
		for (int i = 0; i < numClients; i++)
		{
			if (!g_bSound[clients[i]])
			{
				for (int j = i; j < numClients-1; j++)
				{
					clients[j] = clients[j+1];
				}
				numClients--;
				i--;
			}
		}
		volume = g_cvVolume.FloatValue;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}