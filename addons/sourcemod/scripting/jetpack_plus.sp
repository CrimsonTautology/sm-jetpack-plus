/**
 * vim: set ts=4 :
 * =============================================================================
 * Jetpack Plus
 * TODO: Describe this plugin
 *
 * Copyright 2014 CrimsonTautology
 * =============================================================================
 *
 */

#pragma semicolon 1

#include <sourcemod>
#include <jetpack_plus>

#define PLUGIN_VERSION "0.1"

public Plugin:myinfo =
{
    name = "Jetpack Plus",
    author = "CrimsonTautology",
    description = "TODO: description",
    version = PLUGIN_VERSION,
    url = "https://github.com/CrimsonTautology/sm_jetpack_plus"
};


new Handle:g_Cvar_Enabled = INVALID_HANDLE;

new bool:g_IsUsingJetpack[MAXPLAYERS+1] = {false, ...};


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    if (LibraryExists("jetpack_plus"))
    {
        strcopy(error, err_max, "Jetpack Plus already loaded, aborting.");
        return APLRes_Failure;
    }

    RegPluginLibrary("jetpack_plus"); 

    return APLRes_Success;
}

public OnPluginStart()
{
    LoadTranslations("jetpack_plus.phrases");

    g_Cvar_Enabled = CreateConVar("sm_jetpack_enabled", "1", "Enabled");

    RegConsoleCmd("sm_test", Command_Test, "TODO: TEST");
}

public Action:Command_Test(client, args)
{
    return Plugin_Handled;
}

public OnGameFrame()
{
    if(AreJetpacksEnabled())
    {
        for (new client=1; client <= MaxClients; client++)
        {
            //For each client using a jetpack
            if(IsClientUsingJetpack(client))
            {
                JetpackStep(client);
            }

        }

    }
}

bool:IsClientUsingJetpack(client)
{
    return g_IsUsingJetpack[client];
}

bool:AreJetpacksEnabled()
{
    return GetConVarBool(g_Cvar_Enabled);
}

StartJetpack(client)
{
    g_IsUsingJetpack[client] = true;
}

//Called each frame a client is using a jetpack
JetpackStep(client)
{
}

StopJetpack(client)
{
    g_IsUsingJetpack[client] = false;
}
