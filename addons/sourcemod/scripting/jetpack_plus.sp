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
#include <smlib/entities>
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

public OnClientDisconnect(client)
{
    StopJetpack(client);
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

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
    if(!AreJetpacksEnabled()) return Plugin_Continue;

    if(buttons & IN_JUMP && !IsClientUsingJetpack(client))
    {
        //TODO send player id, not client id
        CreateTimer(0.2, HeldJump, client);
    }
    
    return Plugin_Continue;
}

//Call back for when a player presses jump.  Checks if jump is still held down
public Action:HeldJump(Handle:timer, any:client)
{
    //TODO retrieve client id from player id
    if(!IsClientInGame(client)) return Plugin_Handled;

    if(GetClientButtons(client) & IN_JUMP)
    {
        StartJetpack(client);
    }

    return Plugin_Handled;
}

public Action:Command_Test(client, args)
{
    return Plugin_Handled;
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

StopJetpack(client)
{
    g_IsUsingJetpack[client] = false;
}

//Called each frame a client is using a jetpack
JetpackStep(client)
{
    if(IsPlayerAlive(client))
    {
        JetpackPush(client, 100.0);
    }
    else
    {
        StopJetpack(client);
    }
}

JetpackPush(client, Float:force)
{
    new Float:vec[3];
    Entity_GetLocalVelocity(client, vec);
    vec[2] += force;
    Entity_SetLocalVelocity(client, vec);
}
