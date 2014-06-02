/**
 * vim: set ts=4 :
 * =============================================================================
 * Jetpack Plus
 * Handles the sounds and particle effects for the jetpacks.  Also allows
 * donators to customize their jetpack.
 *
 * Copyright 2014 CrimsonTautology
 * =============================================================================
 *
 */

#pragma semicolon 1

#include <sourcemod>
#include <jetpack_plus>
#include <sdktools>
#include <particle>
#undef REQUIRE_PLUGIN
#include <donator>

#define PLUGIN_VERSION "0.1"

#define MAX_JETPACK_TYPES 64

public Plugin:myinfo =
{
    name = "Jetpack Plus (Bling)",
    author = "CrimsonTautology",
    description = "Handles sounds and particle effects for jetpacks",
    version = PLUGIN_VERSION,
    url = "https://github.com/CrimsonTautology/sm_jetpack_plus"
};

new bool:g_DonatorLibraryExists = false;

//Player options
new g_ClientSelectedJetpackType[MAXPLAYERS+1] = {0, ...};
new g_JetpackParticle[MAXPLAYERS+1][2];

//Parallel arrays to store types of jetpacks
new String:g_JetpackTypeName[MAX_JETPACK_TYPES][PLATFORM_MAX_PATH];
new String:g_JetpackTypeParticle[MAX_JETPACK_TYPES][PLATFORM_MAX_PATH];
new String:g_JetpackTypeSound[MAX_JETPACK_TYPES][PLATFORM_MAX_PATH];
new g_JetpackTypeCount = 0;


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    MarkNativeAsOptional("IsPlayerDonator");
    MarkNativeAsOptional("Donator_RegisterMenuItem");

    return APLRes_Success;
}

public OnPluginStart()
{
    LoadTranslations("jetpack_plus.phrases");

    RegConsoleCmd("sm_jetpack", Command_Jetpack, "Change jetpack");

    g_DonatorLibraryExists = LibraryExists("donator.core");
}

public OnAllPluginsLoaded()
{
    if (g_DonatorLibraryExists)
    {
        //Donator_RegisterMenuItem("Jetpack Bling", JetpackBlingMenu);
    }
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "donator.core"))
    {
        g_DonatorLibraryExists = false;
    }
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "donator.core"))
    {
        g_DonatorLibraryExists = true;
    }
}

public OnMapStart()
{
    ReadJetpacks();
}

ReadJetpacks()
{
    //Create default jetpack
    g_JetpackTypeName[0] = "Default";
    g_JetpackTypeParticle[0] = "burninggibs";
    g_JetpackTypeSound[0] = "vehicles/airboat/fan_blade_fullthrottle_loop1.wav";
    PrecacheSound(g_JetpackTypeSound[0], true);
    g_JetpackTypeCount = 1;

    new Handle:kv = CreateKeyValues("Jetpacks");

    decl String:path[PLATFORM_MAX_PATH], String:tmp[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/jetpacks.cfg");

    if(FileExists(path))
    {
        FileToKeyValues(kv, path);
        KvGotoFirstSubKey(kv);

        do
        {
            KvGetSectionName(kv, tmp, sizeof(tmp));
            PrintToConsole(0, "hit ------- %s", tmp);
            if(StrEqual(tmp, "Jetpack") )
            {
                KvGetString(kv, "name", g_JetpackTypeName[g_JetpackTypeCount], PLATFORM_MAX_PATH);
                KvGetString(kv, "particle", g_JetpackTypeParticle[g_JetpackTypeCount], PLATFORM_MAX_PATH);
                KvGetString(kv, "sound", g_JetpackTypeSound[g_JetpackTypeCount], PLATFORM_MAX_PATH);

                PrecacheSound(g_JetpackTypeSound[g_JetpackTypeCount], true);
                g_JetpackTypeCount++;
            }

        } while(KvGotoNextKey(kv) && g_JetpackTypeCount < MAX_JETPACK_TYPES);

    } else {
        LogError("File Not Found: %s", path);
    }

    CloseHandle(kv);
}

public Action:Command_Jetpack(client, args)
{
    if (client)
    {
        ChangeJetpackMenu(client);
    }

    return Plugin_Handled;
}

public Action:OnStartJetpack(client)
{
    ApplyJetpackEffects(client);

    //https://forums.alliedmods.net/showthread.php?t=127111
    //pyrovision_flaming_arrow
    //pyrovision_flying_flaming_arrow
    //ghost_pumpkin
    //ghost_pumpkin_flyingbits

    //burningplayer_corpse_rainbow_stars
    //burningplayer_rainbow_OLD
    //flamethrower_rainbow_bubbles02
    //burninggibs
    //electrocuted_blue
    //spell_batball_blue
    //g_JetpackParticle[client][0] = CreateParticle("halloween_rockettrail", 0.0, client, Attach, "flag", pos, ang);

    return Plugin_Continue;
}

public Action:OnStopJetpack(client)
{
    ClearJetpackEffects(client);

    return Plugin_Continue;
}

ApplyJetpackEffects(client)
{
    new selected = g_ClientSelectedJetpackType[client];
    EmitSoundToAll(g_JetpackTypeSound[selected], client, SNDCHAN_AUTO);

    static const Float:ang[3] = { -25.0, 90.0, 0.0 };
    static const Float:pos[3] = {   0.0, 10.0, 1.0 };
    g_JetpackParticle[client][0] = CreateParticle(g_JetpackTypeParticle[selected], 0.0, client, Attach, "flag", pos, ang);
}

ClearJetpackEffects(client)
{
    new selected = g_ClientSelectedJetpackType[client];
    StopSound(client, SNDCHAN_AUTO, g_JetpackTypeSound[selected]);
    DeleteParticle(g_JetpackParticle[client][0]);
}

//Menus
//public DonatorMenu:JetpackBlingMenu(client) ChangeJetpackMenu;
ChangeJetpackMenu(client)
{
    new Handle:menu = CreateMenu(ChangeJetpackMenuHandler);
    new selected = g_ClientSelectedJetpackType[client];

    SetMenuTitle(menu, "Choose your jetpack");

    decl String:buf[16];
    for(new i=0; i < g_JetpackTypeCount && i < MAX_JETPACK_TYPES; i++)
    {
        IntToString(i, buf, sizeof(buf));
        AddMenuItem(menu, buf, g_JetpackTypeName[i], i == selected ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    }

    DisplayMenu(menu, client, 20);
}

public ChangeJetpackMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
            {
                new client = param1;
                new String:info[32];
                GetMenuItem(menu, param2, info, sizeof(info));
                new selected = StringToInt(info);

                //Clear running particle and sound to prevent overlap
                ClearJetpackEffects(client);

                g_ClientSelectedJetpackType[client] = selected;
            }
        case MenuAction_End: CloseHandle(menu);
    }
}
