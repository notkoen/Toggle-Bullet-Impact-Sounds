#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <csgocolors_fix>

Cookie g_hImpactSound;
int g_bBlockImpactSound[MAXPLAYERS+1] = {true, ...};

ConVar g_cvLowVolume;

public Plugin myinfo =
{
    name = "Toggle Bullet Impact Sounds",
    author = "koen", // Inspiration from both Snowy and AntiTeal's plugins
    description = "Allow clients to toggle bullet impact sounds",
    version = "1.0.1",
    url = ""
};

public void OnPluginStart()
{
    // Register client cookie
    g_hImpactSound = RegClientCookie("impact_sounds", "Bullet impact sounds", CookieAccess_Private);
    
    // Plugin Cvars
    g_cvLowVolume = CreateConVar("sm_impact_volume", "0.2", "Set adjusted volume of bullet impact sounds", _, true, 0.0, true, 1.0);
    AutoExecConfig(true);
    
    // Register plugin command
    RegConsoleCmd("sm_stopsoundmore", Command_ImpactSound, "Toggle bullet impact sounds");
    RegConsoleCmd("sm_impactsounds", Command_ImpactSound, "Toggle bullet impact sounds");
    
    // Set cookie menu option
    SetCookieMenuItem(CookieHandler, INVALID_HANDLE, "Bullet Impact Sounds");
    
    // Add soundhook for bullet impact sounds
    AddNormalSoundHook(SoundHook);
}

public void OnClientPostAdminCheck(int client)
{
    OnClientCookiesCached(client);
}

public void OnClientDisconnect(int client)
{
    g_bBlockImpactSound[client] = true;
}

public void OnClientCookiesCached(int client)
{
    if (!IsValidClient(client)) return;
    
    char cookie[2];
    GetClientCookie(client, g_hImpactSound, cookie, sizeof(cookie));
    g_bBlockImpactSound[client] = StrEqual(cookie, "1");
}

public Action SoundHook(int clients[64], int &numClients, char sound[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
    if ((StrContains(sound, "physics/flesh/flesh_impact_bullet") != -1) ||
        (StrContains(sound, "player/headshot") != -1) ||
        (StrContains(sound, "player/kevlar") != -1) ||
        (StrContains(sound, "player/headshot") != -1) ||
        (StrContains(sound, "player/bhit_helmet") != -1))
    {
        for (int i = 0; i < numClients; i++)
        {
            if (g_bBlockImpactSound[clients[i]])
            {
                for (int j = 1; j < numClients - 1; j++)
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
            FormatEx(buffer, maxlen, "Bullet Impact Sounds: %s", g_bBlockImpactSound[client] ? "Disabled" : "Enabled");
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
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }
    
    ToggleImpactSound(client);
    return Plugin_Handled;
}

void ToggleImpactSound(int client)
{
    g_bBlockImpactSound[client] = !g_bBlockImpactSound[client];
    CPrintToChat(client, "{red}[Sound] {default}You have %s {default}bullet impact sounds.", g_bBlockImpactSound[client] ? "{red}disabled" : "{green}enabled");
    SetClientCookie(client, g_hImpactSound, g_bBlockImpactSound[client] ? "1" : "");
}

bool IsValidClient(int client, bool nobots = true)
{
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
        return false;
    return IsClientInGame(client);
}