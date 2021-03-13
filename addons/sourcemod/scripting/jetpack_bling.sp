/**
 * vim: set ts=4 :
 * =============================================================================
 * Jetpack Plus
 * Handles the sounds and particle effects for the jetpacks.
 *
 * Copyright 2014 CrimsonTautology
 * =============================================================================
 *
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <jetpack_plus>
#include <clientprefs>
#include <sdktools>
#include <particle>
#include <smlib/general>

#define PLUGIN_VERSION "1.10.1"
#define PLUGIN_NAME "Jetpack Plus (Bling)"

#define MAX_JETPACK_TYPES 64
#define DEFAULT_JETPACK 0

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = "CrimsonTautology",
    description = "Handles sounds and particle effects for jetpacks",
    version = PLUGIN_VERSION,
    url = "https://github.com/CrimsonTautology/sm-jetpack-plus"
};

// player options
Cookie g_SelectedJetpackCookie;
int g_SelectedJetpack[MAXPLAYERS+1] = {DEFAULT_JETPACK, ...};
int g_JetpackParticle[MAXPLAYERS+1];

// parallel arrays to store types of jetpacks
char g_JetpackTypeName[MAX_JETPACK_TYPES][PLATFORM_MAX_PATH];
char g_JetpackTypeParticle[MAX_JETPACK_TYPES][PLATFORM_MAX_PATH];
char g_JetpackTypeSound[MAX_JETPACK_TYPES][PLATFORM_MAX_PATH];
int g_JetpackTypeCount = 0;

public void OnPluginStart()
{
    LoadTranslations("jetpack_plus.phrases");

    CreateConVar("sm_jetpack_bling_version", PLUGIN_VERSION, PLUGIN_NAME,
            FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);

    RegConsoleCmd("sm_bling", Command_Bling, "Change jetpack bling.");

    g_SelectedJetpackCookie = new Cookie("selected_jetpack",
            "Selected jetpack type", CookieAccess_Private);
}

public void OnClientCookiesCached(int client)
{
    char buffer[11];

    GetClientCookie(client, g_SelectedJetpackCookie, buffer, sizeof(buffer));
    int type_of = StringToInt(buffer);
    if (strlen(buffer) > 0 && type_of < g_JetpackTypeCount){
        g_SelectedJetpack[client] = type_of;
    }else{
        g_SelectedJetpack[client] = DEFAULT_JETPACK;
    }
}

public void OnMapStart()
{
    ReadJetpacks();
}

void ReadJetpacks()
{
    g_JetpackTypeCount = 0;

    KeyValues kv = new KeyValues("Jetpacks");

    // find the jetpack config file for the current game, if one exists
    char path[PLATFORM_MAX_PATH], tmp[PLATFORM_MAX_PATH], game_folder[PLATFORM_MAX_PATH];
    GetGameFolderName(game_folder, sizeof(game_folder));
    Format(tmp, sizeof(tmp), "configs/jetpacks.%s.cfg", game_folder);
    BuildPath(Path_SM, path, sizeof(path), tmp);

    if (FileExists(path))
    {
        kv.ImportFromFile(path);
        kv.GotoFirstSubKey();

        do
        {
            kv.GetSectionName(tmp, sizeof(tmp));
            if (StrEqual(tmp, "Jetpack") )
            {
                KvGetJetpack(kv, g_JetpackTypeCount);
            }

        } while(kv.GotoNextKey() && g_JetpackTypeCount < MAX_JETPACK_TYPES);

    } else {
        LogError("File Not Found: %s", path);
    }

    delete kv;
}

void KvGetJetpack(KeyValues kv, int& index)
{
    kv.GetString("name", g_JetpackTypeName[index], PLATFORM_MAX_PATH);
    kv.GetString("particle", g_JetpackTypeParticle[index], PLATFORM_MAX_PATH);
    kv.GetString("sound", g_JetpackTypeSound[index], PLATFORM_MAX_PATH);

    if (view_as<bool>(kv.GetNum("particle_precache_required", 0)))
    {
        PrecacheParticleSystem(g_JetpackTypeParticle[index]);
    }
    if (view_as<bool>(kv.GetNum("particle_download_required", 0)))
    {
        AddFileToDownloadsTable(g_JetpackTypeParticle[index]);
    }
    if (view_as<bool>(kv.GetNum("sound_download_required", 0)))
    {
        AddFileToDownloadsTable(g_JetpackTypeSound[index]);
    }

    PrecacheSound(g_JetpackTypeSound[index], true);
    index++;
}

Action Command_Bling(int client, int args)
{
    if (client)
    {
        ChangeJetpackMenu(client);
    }

    return Plugin_Handled;
}

public Action OnStartJetpackPost(int client)
{
    ApplyJetpackEffects(client);
    return Plugin_Continue;
}

public Action OnStopJetpackPost(int client)
{
    ClearJetpackEffects(client);

    return Plugin_Continue;
}

int GetSelectedJetpackOfClient(int client)
{
    return g_SelectedJetpack[client];
}

void SetSelectedJetpackOfClient(int client, int type_of)
{
    char tmp[11];
    IntToString(type_of, tmp, sizeof(tmp));
    SetClientCookie(client, g_SelectedJetpackCookie, tmp);
    g_SelectedJetpack[client] = type_of;
}

void ApplyJetpackEffects(int client)
{
    int selected = GetSelectedJetpackOfClient(client);
    EmitSoundToAll(g_JetpackTypeSound[selected], client, SNDCHAN_AUTO);

    static const float ang[3] = {-25.0, 90.0, 0.0};
    static const float pos[3] = {0.0, 10.0, 1.0};
    g_JetpackParticle[client] = CreateParticle(
            g_JetpackTypeParticle[selected], 0.0, client, Attach, "flag", pos, ang);
}

void ClearJetpackEffects(int client)
{
    int selected = GetSelectedJetpackOfClient(client);
    StopSound(client, SNDCHAN_AUTO, g_JetpackTypeSound[selected]);
    DeleteParticle(g_JetpackParticle[client]);
}

// menus
void ChangeJetpackMenu(int client)
{
    Menu menu = new Menu(ChangeJetpackMenuHandler);
    int selected = GetSelectedJetpackOfClient(client);

    menu.SetTitle("Choose your jetpack");

    char buf[16];
    for (int i = 0; i < g_JetpackTypeCount && i < MAX_JETPACK_TYPES; i++)
    {
        IntToString(i, buf, sizeof(buf));
        menu.AddItem(buf,
                g_JetpackTypeName[i],
                i == selected ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    }

    menu.Display(client, 20);
}

int ChangeJetpackMenuHandler(Menu menu, MenuAction action, int client, int selected)
{
    switch (action)
    {
        case MenuAction_Select:
            {
                char info[32];
                menu.GetItem(selected, info, sizeof(info));
                int type_of = StringToInt(info);

                // clear running particle and sound to prevent overlap
                ClearJetpackEffects(client);

                SetSelectedJetpackOfClient(client, type_of);
            }
        case MenuAction_End: delete menu;
    }
}
