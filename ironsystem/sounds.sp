#define MUSICFOLDER "ironzone"
//#define MAX_EDICTS      2048

/*new g_iSoundEnts[MAX_EDICTS];
new g_iNumSounds;*/

new bool:SoundsSucess = false;

new g_Sounds = 0;
new g_Played = 0;
new rnd_sound = 0;
new bool:g_PlayedSound = false;
new soundtoplay;
//new g_counter = 0;

new String:sound[128][PLATFORM_MAX_PATH];
new String:soundnew[PLATFORM_MAX_PATH];

PlayMusic() {
    g_PlayedSound = false;
    if(GetConVarInt(g_hPlayType) == 1) {
        //g_counter++;
        rnd_sound = GetRandomInt(1, g_Sounds);
        if(SoundsSucess) {
            //StopMapMusic();
            g_PlayedSound = true;
            soundnew = sound[rnd_sound];
            soundtoplay = rnd_sound;
            ReplaceString(soundnew, sizeof(soundnew), ".mp3", "_.mp3", false);
            for(new i = 1; i < MaxClients; i++) {
                if(IsValidClient(i) && g_PlayMusic[i]) {
                    CreateTimer(0.1, Timer_PlayEndSound, i);
                    /*EmitSoundToClientAny(i, sound[rnd_sound], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
                    PluginMessageToClient(i, "Now playing {BLUE}%s", sound[rnd_sound]);*/
                }
            }
        }

    } else {
        if(g_Played <= g_Sounds) {
            if(SoundsSucess) {
                g_PlayedSound = true;
                g_Played++;
                //StopMapMusic();
                soundnew = sound[g_Played];
                soundtoplay = g_Played;
                ReplaceString(soundnew, sizeof(soundnew), ".mp3", "_.mp3", false);
                for(new i = 1; i < MaxClients; i++) {
                    if(IsValidClient(i) && g_PlayMusic[i]) {
                        CreateTimer(0.1, Timer_PlayEndSound, i);
                        /*EmitSoundToClientAny(i, sound[soundtoplay], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
                        PluginMessageToClient(i, "Now playing {BLUE}%s", sound[soundtoplay]);*/
                    }
                }
            }
        } else {
            //PluginMessage("Else part %d", g_Sounds);
            g_Played = 0;
            PlayMusic();
        }
    }
}

public Action:Timer_PlayEndSound(Handle:timer, any:client) {
    if(IsValidClient(client)) {
        EmitSoundToClientAny(client, sound[soundtoplay], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
        PluginMessageToClient(client, "Now playing {BLUE}%s", sound[soundtoplay]);
    }
}

LoadMusic() {
    g_Played = 0;
    //g_counter = 0;
    new FileType:type;
    new String:name[64];
    new String:soundname[64];
    new String:soundname2[64];
    decl String:soundpath[32];
    Format(soundpath, sizeof(soundpath), "sound/%s/", MUSICFOLDER);
    new Handle:pluginsdir = OpenDirectory(soundpath);
    g_Sounds = 0;
    if(pluginsdir != INVALID_HANDLE) {
        while(ReadDirEntry(pluginsdir, name, sizeof(name), type)) {
            if(StrContains(name, ".mp3", false) == strlen(name) - 4) {
                Format(soundname, sizeof(soundname), "sound/%s/%s", MUSICFOLDER, name);
                Format(soundname2, sizeof(soundname2), "%s/%s", MUSICFOLDER, name);
                AddFileToDownloadsTable(soundname);
                PrecacheSoundAny(soundname2);
                if(StrContains(name, "_.mp3", false) != (strlen(name) - 5)) {
                    g_Sounds++;
                    sound[g_Sounds] = soundname2;
                }
            }
        }
        SoundsSucess = true;
    }
    else {
        SoundsSucess = false;
    }
}

/*public StopMapMusic() {
    decl String:sSound[PLATFORM_MAX_PATH];
    new entity = INVALID_ENT_REFERENCE;
    for(new i = 1; i <= MaxClients; i++){
        if(!IsClientInGame(i)){ continue; }
        for (new u = 0; u<g_iNumSounds; u++) {
            entity = EntRefToEntIndex(g_iSoundEnts[u]);
            if (entity != INVALID_ENT_REFERENCE) {
                GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
                Client_StopSound(i, entity, SNDCHAN_STATIC, sSound);
            }
        }
    }
}

stock Client_StopSound(client, entity, channel, const String:name[])
{
    EmitSoundToClient(client, name, entity, channel, SNDLEVEL_NONE, SND_STOP, 0.0, SNDPITCH_NORMAL, _, _, _, true);
}*/