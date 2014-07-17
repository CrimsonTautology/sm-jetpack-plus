/**
 * vim: set ts=4 :
 * =============================================================================
 * Jetpack Plus
 * Adds a fuel system to the jetpack.  Using
 * the jetpack depletes fuel and you can only
 * use the jetpack if you have fuel.
 *
 * Copyright 2014 CrimsonTautology
 * =============================================================================
 *
 */

#pragma semicolon 1

#include <sourcemod>
#include <jetpack_plus>

#define PLUGIN_VERSION "1.0"

#define MAX_JETPACK_TYPES 64

public Plugin:myinfo =
{
    name = "Jetpack Plus (Fuel)",
    author = "CrimsonTautology",
    description = "Adds a fuel based system to jetpack",
    version = PLUGIN_VERSION,
    url = "https://github.com/CrimsonTautology/sm_jetpack_plus"
};

//CVARs
new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new Handle:g_Cvar_JetpackFuelMax = INVALID_HANDLE;
new Handle:g_Cvar_JetpackRefuelingTime = INVALID_HANDLE;

//Player values
new g_Fuel[MAXPLAYERS+1] = {0, ...};

public OnPluginStart()
{
    LoadTranslations("jetpack_plus.phrases");

    g_Cvar_Enabled = CreateConVar(
            "sm_jetpack_fuel_enabled",
            "1",
            "Set to 1 to require jetpacks to use fuel"
            0,
            true,
            0.0,
            true,
            1.0);
    g_Cvar_JetpackFuelMax = CreateConVar(
            "sm_jetpack_fuel",
            "100",
            "The ammount of fuel a player starts with");
    g_Cvar_JetpackRefuelingTime = CreateConVar("sm_jetpack_refueling_time", "30.0", "Time in seconds a player must wait until their jetpack refuels on their own");
}

public OnClientConnected(client)
{
    RefuelClient(client);
}

public Action:OnStartJetpack(client)
{
    if(!IsFuelEnabled()) return Plugin_Continue;
    if(GetFuelOfClient(client))return Plugin_Handled;
    return Plugin_Continue;
}

public Action:OnJetpackStep(client, &Float:force, &bool:force_stop)
{
    if(!IsFuelEnabled()) return Plugin_Continue;

    UseFuelOfClient(client);

    if(GetFuelOfClient(client) <= 0)
    {
        OutOfFuel(client);
        force_stop = true;
    }

    return Plugin_Continue;
}

OutOfFuel(client)
{
    new player = GetClientUserId(client);
    //EmitSoundToClient(client, g_EmptySound);
    CreateTimer(GetConVarFloat(g_Cvar_JetpackRefuelingTime), AutoRefuel, player);
}

Action:AutoRefuel(Handle:timer, any:player)
{
    new client = GetClientOfUserId(player);
    if(client && IsPlayerAlive(client))
    {
        RefuelClient(client);
        //EmitSoundToClient(client, g_RefuelSound);
    }
}

bool:IsFuelEnabled()
{
    return GetConVarBool(g_Cvar_Enabled);
}

GetFuelOfClient(client)
{
    return g_Fuel[client];
}

UseFuelOfClient(client)
{
    g_Fuel[client] -= 1
}

RefuelClient(client)
{
    g_Fuel[client] = GetConVarInt(g_Cvar_JetpackFuelMax)
}

