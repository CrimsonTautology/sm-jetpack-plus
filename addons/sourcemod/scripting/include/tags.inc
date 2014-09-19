//Logic stolen from Flyflo's GoombaStomp plugin;  other implementations are terrible
//https://github.com/Flyflo/SM-Goomba-Stomp

#if defined _tags_included_
#endinput
#endif
#define _tags_included_

/**
 * Adds an informational string to the server's public "tags".
 * This string should be a short, unique identifier.
 *
 *
 * @param tag            Tag string to append.
 * @noreturn
 */
stock AddServerTag3(const String:tag[])
{
    decl String:current_tags[128];
    new Handle:sv_tags = FindConVar("sv_tags");

    if (sv_tags == INVALID_HANDLE)
    {
        return;
    }

    GetConVarString(sv_tags, current_tags, sizeof(current_tags));
    if (StrContains(current_tags, tag) > -1)
    {
        // already have tag
        return;
    }

    decl String:new_tags[128];
    Format(new_tags, sizeof(new_tags), "%s%s%s", current_tags, (current_tags[0]!=0)?",":"", tag);
    new flags = GetConVarFlags(sv_tags);
    SetConVarFlags(sv_tags, flags & ~FCVAR_NOTIFY);
    SetConVarString(sv_tags, new_tags);
    SetConVarFlags(sv_tags, flags);
}

/**
 * Removes a tag previously added by the calling plugin.
 *
 * @param tag            Tag string to remove.
 * @noreturn
 */
stock RemoveServerTag3(const String:tag[])
{
    decl String:new_tags[128];
    new Handle:sv_tags = FindConVar("sv_tags");

    if (sv_tags == INVALID_HANDLE)
    {
        return;
    }

    GetConVarString(sv_tags, new_tags, sizeof(new_tags));
    if (StrContains(new_tags, tag) == -1)
    {
        // tag isn't on here, just bug out
        return;
    }

    ReplaceString(new_tags, sizeof(new_tags), tag, "");
    ReplaceString(new_tags, sizeof(new_tags), ",,", "");
    new flags = GetConVarFlags(sv_tags);
    SetConVarFlags(sv_tags, flags & ~FCVAR_NOTIFY);
    SetConVarString(sv_tags, new_tags);
    SetConVarFlags(sv_tags, flags);
}
