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
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <smlib/entities>
#include <tags>

#define PLUGIN_VERSION "1.10.1"
#define PLUGIN_NAME "Jetpack Plus"

#define JETPACK_TAG "jetpack"

#define MOVECOLLIDE_DEFAULT 0
#define MOVECOLLIDE_FLY_BOUNCE 1

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = "CrimsonTautology",
    description = "Let client's fly around by holding jump.",
    version = PLUGIN_VERSION,
    url = "https://github.com/CrimsonTautology/sm-jetpack-plus"
};


ConVar g_EnabledCvar;
ConVar g_JetpackForceCvar;
ConVar g_JumpDelayCvar;

GlobalForward g_Forward_OnStartJetpack;
GlobalForward g_Forward_OnStartJetpackPost;
GlobalForward g_Forward_OnStopJetpack;
GlobalForward g_Forward_OnStopJetpackPost;
GlobalForward g_Forward_OnJetpackStep;

bool g_IsUsingJetpack[MAXPLAYERS+1] = {false, ...};
bool g_AdvertShown[MAXPLAYERS+1] = {false, ...};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if (LibraryExists("jetpack_plus"))
    {
        strcopy(error, err_max, "Jetpack Plus already loaded, aborting.");
        return APLRes_Failure;
    }

    RegPluginLibrary("jetpack_plus"); 

    CreateNative("IsClientUsingJetpack", _IsClientUsingJetpack);
    CreateNative("AreJetpacksEnabled", _AreJetpacksEnabled);

    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations("jetpack_plus.phrases");

    CreateConVar("sm_jetpack_version", PLUGIN_VERSION, PLUGIN_NAME,
            FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);

    g_EnabledCvar = CreateConVar(
            "sm_jetpack",
            "1",
            "Set to 1 to enable the jetpack plugin",
            FCVAR_REPLICATED | FCVAR_NOTIFY,
            true,
            0.0,
            true,
            1.0);

    g_JetpackForceCvar = CreateConVar(
            "sm_jetpack_force",
            "8.0",
            "Strength at which the jetpack pushes the player"
            );

    g_JumpDelayCvar = CreateConVar(
            "sm_jetpack_jump_delay",
            "0.15",
            "The time in seconds the jump key needs to be pressed before the jetpack starts"
            );

    HookEvent("player_spawn", Event_PlayerSpawn);
    g_EnabledCvar.AddChangeHook(OnEnabledChange);

    AddServerTag3(JETPACK_TAG);

    g_Forward_OnStartJetpack = CreateGlobalForward(
            "OnStartJetpack", ET_Event, Param_Cell);

    g_Forward_OnStartJetpackPost = CreateGlobalForward(
            "OnStartJetpackPost", ET_Ignore, Param_Cell);

    g_Forward_OnStopJetpack = CreateGlobalForward(
            "OnStopJetpack",  ET_Event, Param_Cell);

    g_Forward_OnStopJetpackPost = CreateGlobalForward(
            "OnStopJetpackPost",  ET_Ignore, Param_Cell);

    g_Forward_OnJetpackStep = CreateGlobalForward(
            "OnJetpackStep",  ET_Event, Param_Cell, Param_FloatByRef, Param_CellByRef);
}

public void OnPluginEnd()
{
    RemoveServerTag3(JETPACK_TAG);
}

public void OnClientConnected(int client)
{
    g_AdvertShown[client] = false;
}

public void OnClientDisconnect(int client)
{
    if (AreJetpacksEnabled())
    {
        StopJetpack(client);
    }
}

public void OnGameFrame()
{
    if (AreJetpacksEnabled())
    {
        StepAllJetpacks();
    }
}

void OnEnabledChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar != g_EnabledCvar) return;

    bool was_on = !!StringToInt(oldValue);
    bool now_on = !!StringToInt(newValue);

    // when changing from on to off
    if (was_on && !now_on)
    {
        StopAllJetpacks();
        RemoveServerTag3(JETPACK_TAG);
    }

    // when changing from off to on
    if (!was_on && now_on)
    {
        AddServerTag3(JETPACK_TAG);
        PrintToChatAll("\x04%t", "jetpack_enabled_on_server");
    }
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3],
        int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if (!AreJetpacksEnabled()) return Plugin_Continue;

    if (!IsClientUsingJetpack(client) && buttons & IN_JUMP)
    {
        int player = GetClientUserId(client);
        float delay = g_JumpDelayCvar.FloatValue;
        CreateTimer(delay, HeldJump, player);
    }

    return Plugin_Continue;
}

// call back for when a player presses jump.  checks if jump is still held down
Action HeldJump(Handle timer, int player)
{
    int client = GetClientOfUserId(player);

    if (client <= 0) return Plugin_Handled;
    if (!IsClientInGame(client)) return Plugin_Handled;
    if (!IsPlayerAlive(client)) return Plugin_Handled;
    if (!AreJetpacksEnabled()) return Plugin_Handled;

    if (!IsClientUsingJetpack(client) && GetClientButtons(client) & IN_JUMP)
    {
        StartJetpack(client);
    }

    return Plugin_Handled;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (g_AdvertShown[client] || !IsClientInGame(client) || !AreJetpacksEnabled()) return;

    PrintToChat(client, "\x04%t", "jetpack_enabled_on_server");
    g_AdvertShown[client] = true;
}

public int _IsClientUsingJetpack(Handle plugin, int args) {
    return view_as<int>(IsClientUsingJetpack(GetNativeCell(1))); }
bool IsClientUsingJetpack(int client)
{
    return g_IsUsingJetpack[client];
}

public int _AreJetpacksEnabled(Handle plugin, int args) {
    return view_as<int>(AreJetpacksEnabled()); }
bool AreJetpacksEnabled()
{
    return g_EnabledCvar.BoolValue;
}

void StartJetpack(int client)
{
    // forward event
    Action result;
    Call_StartForward(g_Forward_OnStartJetpack);
    Call_PushCell(client);
    Call_Finish(result);
    if (result == Plugin_Handled) return;

    SetEntityMoveType(client, MOVETYPE_FLY);
    SetEntityMoveCollide(client, MOVECOLLIDE_FLY_BOUNCE);
    ChangeEdictState(client);
    g_IsUsingJetpack[client] = true;

    // forward post event
    Call_StartForward(g_Forward_OnStartJetpackPost);
    Call_PushCell(client);
    Call_Finish();
}

void StopJetpack(int client)
{
    // forward event
    Action result;
    Call_StartForward(g_Forward_OnStopJetpack);
    Call_PushCell(client);
    Call_Finish(result);
    if (result == Plugin_Handled) return;

    if (IsClientInGame(client))
    {
        SetEntityMoveType(client, MOVETYPE_WALK);
        SetEntityMoveCollide(client, MOVECOLLIDE_DEFAULT);
        ChangeEdictState(client);
    }
    g_IsUsingJetpack[client] = false;

    // forward post event
    Call_StartForward(g_Forward_OnStopJetpackPost);
    Call_PushCell(client);
    Call_Finish();
}

// called each frame a client is using a jetpack
void JetpackStep(int client)
{
    float force = g_JetpackForceCvar.FloatValue;
    bool force_stop = false;

    // forward event
    Action result;
    Call_StartForward(g_Forward_OnJetpackStep);
    Call_PushCell(client);
    Call_PushFloatRef(force);
    Call_PushCellRef(force_stop);
    Call_Finish(result);
    if (result == Plugin_Handled) return;

    int buttons = GetClientButtons(client);
    if (!force_stop && IsPlayerAlive(client) && (buttons & IN_JUMP))
    {
        JetpackPush(client, force);
    }
    else
    {
        StopJetpack(client);
    }
}

void StepAllJetpacks()
{
    for (int client=1; client <= MaxClients; client++)
    {
        // for each client using a jetpack
        if (IsClientUsingJetpack(client))
        {
            JetpackStep(client);
        }
    }
}

void StopAllJetpacks()
{
    for (int client=1; client <= MaxClients; client++)
    {
        // for each client using a jetpack
        if (IsClientUsingJetpack(client))
        {
            StopJetpack(client);
        }
    }
}

void JetpackPush(int client, float force)
{
    float vec[3];
    Entity_GetBaseVelocity(client, vec);
    vec[2] += force;
    Entity_SetBaseVelocity(client, vec);
    ChangeEdictState(client);
}

void SetEntityMoveCollide(int entity, int movecollide)
{
    SetEntProp(entity, Prop_Data, "m_MoveCollide", movecollide);
}
