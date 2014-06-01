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
#include <sdktools>
#include <particle>
#include <smlib/entities>

#define PLUGIN_VERSION "0.1"

#define MOVECOLLIDE_DEFAULT		0
#define MOVECOLLIDE_FLY_BOUNCE	1

public Plugin:myinfo =
{
    name = "Jetpack Plus",
    author = "CrimsonTautology",
    description = "TODO: description",
    version = PLUGIN_VERSION,
    url = "https://github.com/CrimsonTautology/sm_jetpack_plus"
};


new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new Handle:g_Cvar_JetpackSound = INVALID_HANDLE;
new Handle:g_Cvar_JetpackSpeed = INVALID_HANDLE;

new g_Offset_movecollide = -1;

new bool:g_IsUsingJetpack[MAXPLAYERS+1] = {false, ...};
new String:g_JetpackSound[PLATFORM_MAX_PATH];

new g_JetpackParticle[MAXPLAYERS+1][2];
new String:g_JetpackParticleName[64];


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

    g_Cvar_Enabled = CreateConVar(
        "sm_jetpack",
        "1",
        "Set to 1 to enable the jetpack plugin");
    g_Cvar_JetpackSound = CreateConVar(
        "sm_jetpack_sound",
        "vehicles/airboat/fan_blade_fullthrottle_loop1.wav",
        "The default sound for the jetpack"
        );
    g_Cvar_JetpackSpeed = CreateConVar(
        "sm_jetpack_speed",
        "8.0",
        "Speed of the jetpack"
        );

    RegConsoleCmd("sm_jp", Command_Jp, "Change jetpack particle");

    if((g_Offset_movecollide = FindSendPropOffs("CBaseEntity", "movecollide")) == -1)
        LogError("Could not find offset for CBaseEntity::movecollide");
}

public Action:Command_Jp(client, args)
{

    if(client && IsClientAuthorized(client)){
        decl String:path[64];
        GetCmdArgString(path, sizeof(path));
        strcopy(g_JetpackParticleName, 64, path);
    }

    return Plugin_Handled;
}

public OnConfigsExecuted()
{
    GetConVarString(g_Cvar_JetpackSound, g_JetpackSound, sizeof(g_JetpackSound));
    PrecacheSound(g_JetpackSound, true);
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
    SetEntityMoveType(client, MOVETYPE_FLY);
    SetEntityMoveCollide(client, MOVECOLLIDE_FLY_BOUNCE);
    g_IsUsingJetpack[client] = true;

    EmitSoundToAll(g_JetpackSound, client, SNDCHAN_AUTO);

    static const Float:ang[3] = { -25.0, 90.0, 0.0 };
    static const Float:pos[3] = {   0.0, 10.0, 1.0 };

    //https://forums.alliedmods.net/showthread.php?t=127111
    //pyrovision_flaming_arrow
    //pyrovision_flying_flaming_arrow
    //ghost_pumpkin
    //ghost_pumpkin_flyingbits
    //burningplayer_rainbow
    //burningplayer_corpse_rainbow_stars
    //burningplayer_rainbow_OLD
    //flamethrower_rainbow_bubbles02
    //burninggibs
    //electrocuted_blue
    //spell_batball_blue
    //g_JetpackParticle[client][0] = CreateParticle("halloween_rockettrail", 0.0, client, Attach, "flag", pos, ang);
    g_JetpackParticle[client][0] = CreateParticle(g_JetpackParticleName, 0.0, client, Attach, "flag", pos, ang);
}

StopJetpack(client)
{
    SetEntityMoveType(client, MOVETYPE_WALK);
    SetEntityMoveCollide(client, MOVECOLLIDE_DEFAULT);
    g_IsUsingJetpack[client] = false;
    StopSound(client, SNDCHAN_AUTO, g_JetpackSound);
    DeleteParticle(g_JetpackParticle[client][0]);
}

//Called each frame a client is using a jetpack
JetpackStep(client)
{
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
