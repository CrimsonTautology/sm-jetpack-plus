/**
 * vim: set ts=4 :
 * =============================================================================
 * Jetpack Plus
 * Rewrite of the Sourcemod plugin to make it easier to extend and modify.
 *
 * Copyright 2014 CrimsonTautology
 * =============================================================================
 *
 */

#pragma semicolon 1

#include <sourcemod>
#include <jetpack_plus>
#include <sdktools>
#include <smlib/entities>

#define PLUGIN_VERSION "0.1"

#define MOVECOLLIDE_DEFAULT		0
#define MOVECOLLIDE_FLY_BOUNCE	1

public Plugin:myinfo =
{
    name = "Jetpack Plus",
    author = "CrimsonTautology",
    description = "Let client's fly around by holding jump.",
    version = PLUGIN_VERSION,
    url = "https://github.com/CrimsonTautology/sm_jetpack_plus"
};


new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new Handle:g_Cvar_JetpackSpeed = INVALID_HANDLE;

new Handle:g_Forward_OnStartJetpack = INVALID_HANDLE;
new Handle:g_Forward_OnStopJetpack = INVALID_HANDLE;
new Handle:g_Forward_OnJetpackStep= INVALID_HANDLE;

new g_Offset_movecollide = -1;

new bool:g_IsUsingJetpack[MAXPLAYERS+1] = {false, ...};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    if (LibraryExists("jetpack_plus"))
    {
        strcopy(error, err_max, "Jetpack Plus already loaded, aborting.");
        return APLRes_Failure;
    }

    RegPluginLibrary("jetpack_plus"); 

    CreateNative("IsClientUsingJetpack", IsClientUsingJetpack);
    CreateNative("AreJetpacksEnabled", AreJetpacksEnabled);

    return APLRes_Success;
}

public OnPluginStart()
{
    LoadTranslations("jetpack_plus.phrases");

    g_Cvar_Enabled = CreateConVar(
            "sm_jetpack",
            "1",
            "Set to 1 to enable the jetpack plugin");
    g_Cvar_JetpackSpeed = CreateConVar(
            "sm_jetpack_speed",
            "8.0",
            "Speed of the jetpack"
            );

    g_Forward_OnStartJetpack = CreateGlobalForward("OnStartJetpack", ET_Ignore, Param_Cell);
    g_Forward_OnStopJetpack =  CreateGlobalForward("OnStopJetpack",  ET_Ignore, Param_Cell);
    g_Forward_OnJetpackStep =  CreateGlobalForward("OnJetpackStep",  ET_Ignore, Param_Cell);

    if((g_Offset_movecollide = FindSendPropOffs("CBaseEntity", "movecollide")) == -1)
        LogError("Could not find offset for CBaseEntity::movecollide");
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

    if(!IsClientUsingJetpack(client) && buttons & IN_JUMP)
    {
        new player = GetClientUserId(client);
        CreateTimer(0.17, HeldJump, player);
    }

    return Plugin_Continue;
}

//Call back for when a player presses jump.  Checks if jump is still held down
public Action:HeldJump(Handle:timer, any:player)
{
    new client = GetClientOfUserId(player);

    if(!IsClientInGame(client)) return Plugin_Handled;

    if(!IsClientUsingJetpack(client) && GetClientButtons(client) & IN_JUMP)
    {
        StartJetpack(client);
    }

    return Plugin_Handled;
}

public IsClientUsingJetpack(Handle:plugin, args) { return _:_IsClientUsingJetpack(GetNativeCell(1)); }
bool:_IsClientUsingJetpack(client)
{
    return g_IsUsingJetpack[client];
}

public AreJetpacksEnabled(Handle:plugin, args) { return _:_AreJetpacksEnabled(); }
bool:_AreJetpacksEnabled()
{
    return GetConVarBool(g_Cvar_Enabled);
}

StartJetpack(client)
{
    //Forward event
    decl Action:result;
    Call_StartForward(g_Forward_OnStartJetpack);
    Call_PushCell(client);
    Call_Finish(result);
    if(result == Plugin_Handled) return;

    SetEntityMoveType(client, MOVETYPE_FLY);
    SetEntityMoveCollide(client, MOVECOLLIDE_FLY_BOUNCE);
    g_IsUsingJetpack[client] = true;
}

StopJetpack(client)
{
    //Forward event
    decl Action:result;
    Call_StartForward(g_Forward_OnStopJetpack);
    Call_PushCell(client);
    Call_Finish(result);
    if(result == Plugin_Handled) return;

    SetEntityMoveType(client, MOVETYPE_WALK);
    SetEntityMoveCollide(client, MOVECOLLIDE_DEFAULT);
    g_IsUsingJetpack[client] = false;
}

//Called each frame a client is using a jetpack
JetpackStep(client)
{
    //Forward event
    decl Action:result;
    Call_StartForward(g_Forward_OnJetpackStep);
    Call_PushCell(client);
    Call_Finish(result);
    if(result == Plugin_Handled) return;

    new buttons = GetClientButtons(client);
    if(IsPlayerAlive(client) && (buttons & IN_JUMP))
    {
        JetpackPush(client, GetConVarFloat(g_Cvar_JetpackSpeed));
    }
    else
    {
        StopJetpack(client);
    }
}

JetpackPush(client, Float:force)
{
    new Float:vec[3];
    Entity_GetBaseVelocity(client, vec);
    vec[2] += force;
    Entity_SetBaseVelocity(client, vec);
}

SetEntityMoveCollide(entity, movecollide)
{
    if(g_Offset_movecollide == -1) return;
    SetEntData(entity, g_Offset_movecollide, movecollide);
}
