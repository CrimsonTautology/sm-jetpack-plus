#if defined _particle_included_
#endinput
#endif
#define _particle_included_

// Particle Attachment Types  -------------------------------------------------
enum ParticleAttachmentType
{
    NoAttach = 0,
    Attach,
    AttachMaintainOffset
};

// Particles ------------------------------------------------------------------

/* CreateParticle()
 **
 ** Creates a particle at an entity's position. Attach determines the attachment
 ** type (0 = not attached, 1 = normal attachment, 2 = head attachment). Allows
 ** offsets from the entity's position.
 ** ------------------------------------------------------------------------- */
stock CreateParticle(const String:particleType[], Float:time=5.0, entity=0,
        ParticleAttachmentType:attach=Attach,
        const String:attachToBone[]="head",
        const Float:offsetPos[3]=NULL_VECTOR,
        const Float:offsetAng[3]=NULL_VECTOR,
        Timer:deleteFunc=Timer:0,
        &Handle:timerHandle=INVALID_HANDLE)
{
    new particle = CreateEntityByName("info_particle_system");
    if (particle > 0 && IsValidEdict(particle))
    {
        decl Float:pos[3], Float:ang[3];
        if (entity > 0)
        {
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
            AddVectors(pos, offsetPos, pos);

            GetEntPropVector(entity, Prop_Send, "m_angRotation", ang);
            AddVectors(ang, offsetAng, ang);
        }
        else
        {
            pos[0] = offsetPos[0];
            pos[1] = offsetPos[1];
            pos[2] = offsetPos[2];

            ang[0] = offsetAng[0];
            ang[1] = offsetAng[1];
            ang[2] = offsetAng[2];
        }

        TeleportEntity(particle, pos, ang, NULL_VECTOR);

        decl String:tName[32];
        Format(tName, sizeof(tName), "target%i", entity);
        DispatchKeyValue(entity, "targetname", tName);

        DispatchKeyValue(particle, "targetname", "sc2particle");
        DispatchKeyValue(particle, "parentname", tName);
        DispatchKeyValue(particle, "effect_name", particleType);

        if (attach > NoAttach)
        {
            SetVariantString("!activator");
            AcceptEntityInput(particle, "SetParent", entity, particle, 0);

            if (attachToBone[0] != '\0')
            {
                SetVariantString(attachToBone);
                AcceptEntityInput(particle, (attach >= AttachMaintainOffset)
                        ? "SetParentAttachmentMaintainOffset"
                        : "SetParentAttachment",
                        particle, particle, 0);
            }
        }

        DispatchSpawn(particle);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");

        if (time > 0.0)
        {
            timerHandle = CreateTimer(time, deleteFunc ? deleteFunc : DeleteParticles,
                    EntIndexToEntRef(particle));
        }
    }
    else
        LogError("CreateParticle: could not create info_particle_system");

    return particle;
}

stock DeleteParticle(particleRef)
{
    new particle = EntRefToEntIndex(particleRef);
    if (particle > 0 && IsValidEntity(particle))
    {
        new String:classname[32];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false))
        {
            AcceptEntityInput(particle, "stop");
            RemoveEdict(particle);
        }
    }
}

public Action:DeleteParticles(Handle:timer, any:particleRef)
{
    DeleteParticle(particleRef);
    return Plugin_Stop;
}
