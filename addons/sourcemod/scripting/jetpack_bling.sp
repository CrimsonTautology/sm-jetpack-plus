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
#include <clientprefs>
#include <sdktools>
#include <particle>
#undef REQUIRE_PLUGIN
#include <donator>

#define PLUGIN_VERSION "1.0"

#define MAX_JETPACK_TYPES 64

public Plugin:myinfo =
{
    name = "Jetpack Plus (Bling)",
    author = "CrimsonTautology",
    description = "Handles sounds and particle effects for jetpacks",
    version = PLUGIN_VERSION,
    url = "https://github.com/CrimsonTautology/sm_jetpack_plus"
};

new Handle:g_Cvar_DonatorsOnly = INVALID_HANDLE;

new bool:g_DonatorLibraryExists = false;

//Player options
new Handle:g_Cookie_SelectedJetpack = INVALID_HANDLE;
new g_SelectedJetpack[MAXPLAYERS+1] = {0, ...};
new g_JetpackParticle[MAXPLAYERS+1];

//Parallel arrays to store types of jetpacks
new String:g_JetpackTypeName[MAX_JETPACK_TYPES][PLATFORM_MAX_PATH];
new String:g_JetpackTypeParticle[MAX_JETPACK_TYPES][PLATFORM_MAX_PATH];
new String:g_JetpackTypeSound[MAX_JETPACK_TYPES][PLATFORM_MAX_PATH];
new g_JetpackTypeCount = 0;


public OnPluginStart()
{
    LoadTranslations("jetpack_plus.phrases");

    g_Cvar_DonatorsOnly = CreateConVar("sm_jetpack_donators_only", "0", "Whether only dontaors can change their jetpack bling");

    RegConsoleCmd("sm_bling", Command_Bling, "Change jetpack bling.");

    g_Cookie_SelectedJetpack = RegClientCookie("selected_jetpack", "Selected jetpack type", CookieAccess_Private);
    g_DonatorLibraryExists = LibraryExists("donator.core");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    MarkNativeAsOptional("IsPlayerDonator");
    MarkNativeAsOptional("Donator_RegisterMenuItem");

    return APLRes_Success;
}

public OnAllPluginsLoaded()
{
    if (g_DonatorLibraryExists)
    {
        Donator_RegisterMenuItem("Jetpack Effects", JetpackBlingMenu);
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

public OnClientCookiesCached(client)
{
    new String:buffer[11];

    GetClientCookie(client, g_Cookie_SelectedJetpack, buffer, sizeof(buffer));
    new type_of = StringToInt(buffer);
    if (strlen(buffer) > 0 && type_of < g_JetpackTypeCount){
        g_SelectedJetpack[client] = type_of;
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

public Action:Command_Bling(client, args)
{
    if(!DonatorCheck(client))
    {
        ReplyToCommand(client, "\x04%t", "donators_only");
        return Plugin_Handled;
    }

    if(client)
    {
        ChangeJetpackMenu(client);
    }

    return Plugin_Handled;
}

public Action:OnStartJetpack(client)
{
    ApplyJetpackEffects(client);
    return Plugin_Continue;
}

public Action:OnStopJetpack(client)
{
    ClearJetpackEffects(client);

    return Plugin_Continue;
}

GetSelectedJetpackOfClient(client)
{
    return g_SelectedJetpack[client];
}

SetSelectedJetpackOfClient(client, type_of)
{
    new String:tmp[11];
    IntToString(type_of, tmp, sizeof(tmp));
    SetClientCookie(client, g_Cookie_SelectedJetpack, tmp);
    g_SelectedJetpack[client] = type_of;
}

ApplyJetpackEffects(client)
{
    new selected = GetSelectedJetpackOfClient(client);
    EmitSoundToAll(g_JetpackTypeSound[selected], client, SNDCHAN_AUTO);

    static const Float:ang[3] = { -25.0, 90.0, 0.0 };
    static const Float:pos[3] = {   0.0, 10.0, 1.0 };
    g_JetpackParticle[client] = CreateParticle(g_JetpackTypeParticle[selected], 0.0, client, Attach, "flag", pos, ang);
}

ClearJetpackEffects(client)
{
    new selected = GetSelectedJetpackOfClient(client);
    StopSound(client, SNDCHAN_AUTO, g_JetpackTypeSound[selected]);
    DeleteParticle(g_JetpackParticle[client]);
}

//True if client can use a donator action. If donations are not enabled this
//will always be true, otherwise check if client is a donator.
public bool:DonatorCheck(client)
{
    if(!g_DonatorLibraryExists || !GetConVarBool(g_Cvar_DonatorsOnly))
        return true;
    else
        return IsPlayerDonator(client);
}
//Menus
public DonatorMenu:JetpackBlingMenu(client) ChangeJetpackMenu(client);
ChangeJetpackMenu(client)
{
    new Handle:menu = CreateMenu(ChangeJetpackMenuHandler);
    new selected = GetSelectedJetpackOfClient(client);

    SetMenuTitle(menu, "Choose your jetpack");

    decl String:buf[16];
    for(new i=0; i < g_JetpackTypeCount && i < MAX_JETPACK_TYPES; i++)
    {
        IntToString(i, buf, sizeof(buf));
        AddMenuItem(menu,
                buf,
                g_JetpackTypeName[i],
                i == selected ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
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
                new type_of = StringToInt(info);

                //Clear running particle and sound to prevent overlap
                ClearJetpackEffects(client);

                SetSelectedJetpackOfClient(client, type_of);
            }
        case MenuAction_End: CloseHandle(menu);
    }
}
