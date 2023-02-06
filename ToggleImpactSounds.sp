#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

Cookie g_hImpactSound;
int g_bBlockSound[MAXPLAYERS+1] = {true, ...};

ConVar g_cvLowVolume;

public Plugin myinfo =
{
	name = "Toggle Bullet Impact Sounds",
	author = "koen", // Code taken from Snowy & AntiTeal's plugins
	description = "Allow clients to toggle bullet impact sounds",
	version = "1.2",
	url = "https://github.com/notkoen"
};

public void OnPluginStart()
{
	// Register client cookie
	g_hImpactSound = RegClientCookie("impact_sounds", "Bullet impact sound cookies", CookieAccess_Private);

	// Plugin convars
	g_cvLowVolume = CreateConVar("sm_impact_volume", "0.0", "Set adjusted volume of bullet impact sounds", _, true, 0.0, true, 1.0);
	AutoExecConfig(true);

	// Plugin command
	RegConsoleCmd("sm_stopsoundmore", Command_ImpactSound, "Toggle bullet impact sounds");
	RegConsoleCmd("sm_impactsounds", Command_ImpactSound, "Toggle bullet impact sounds");

	// Set cookie menu option
	SetCookieMenuItem(CookieHandler, INVALID_HANDLE, "Bullet Impact Sounds");

	// Add soundhook for bullet impact sounds
	AddNormalSoundHook(SoundHook);
}

public void OnClientDisconnect(int client)
{
	g_bBlockSound[client] = true;
}

public void OnClientCookiesCached(int client)
{
	char cookie[2];
	GetClientCookie(client, g_hImpactSound, cookie, sizeof(cookie));

	if (cookie[0] == '\0')
	{
		g_bBlockSound[client] = true;
		SetClientCookie(client, g_hImpactSound, g_bBlockSound[client] ? "1" : "0");
		return;
	}

	g_bBlockSound[client] = StrEqual(cookie, "1");
}

public Action SoundHook(int clients[64], int &numClients, char sound[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if ((StrContains(sound, "physics/flesh/flesh_impact_bullet") != -1) || (StrContains(sound, "player/headshot") != -1) ||
		(StrContains(sound, "player/kevlar") != -1) || (StrContains(sound, "player/headshot") != -1) ||
		(StrContains(sound, "player/bhit_helmet") != -1))
	{
		for (int i = 0; i < numClients; i++)
		{
			if (g_bBlockSound[clients[i]])
			{
				for (int j = i; j < numClients - 1; j++)
				{
					clients[j] = clients[j+1];
				}
				numClients--;
				i--;
			}
		}
		volume = g_cvLowVolume.FloatValue;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void CookieHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			Format(buffer, maxlen, "Bullet Impact Sounds: %s", g_bBlockSound[client] ? "Disabled" : "Enabled");
		}
		case CookieMenuAction_SelectOption:
		{
			ShowCookieMenu(client);
			ToggleImpactSound(client);
		}
	}
}

public Action Command_ImpactSound(int client, int args)
{
	if (!IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	ToggleImpactSound(client);
	return Plugin_Handled;
}

void ToggleImpactSound(int client)
{
	g_bBlockSound[client] = !g_bBlockSound[client];
	PrintToChat(client, " \x04[SM] \x01You have %s \x01bullet impact sounds.", g_bBlockSound[client] ? "\x02disabled" : "\x04enabled");
	SetClientCookie(client, g_hImpactSound, g_bBlockSound[client] ? "1" : "0");
}
