public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
    for(new i = 1; i <= MaxClients; i++) {
        if(IsValidClient(i)) {
            if(g_PlayMusic[i] && g_PlayedSound && g_roundCounter > 1) {
                CreateTimer(0.05, Timer_PlayStartSound, i);
            }

            g_antibuyspam[i] = false;
            g_antipickspam[i] = false;
            g_boost[i] = 3.0;
            g_boostToggle[i] = false;
        }
    }
    g_roundCounter++;

    /*g_iNumSounds = 0;
    
    // Find all ambient sounds played by the map.
    decl String:sSound[PLATFORM_MAX_PATH];
    new entity = INVALID_ENT_REFERENCE;
    
    while ((entity = FindEntityByClassname(entity, "ambient_generic")) != INVALID_ENT_REFERENCE) {
        GetEntPropString(entity, Prop_Data, "m_iszSound", sSound, sizeof(sSound));
        
        new len = strlen(sSound);
        if (len > 4 && (StrEqual(sSound[len-3], "mp3") || StrEqual(sSound[len-3], "wav"))) {
            g_iSoundEnts[g_iNumSounds++] = EntIndexToEntRef(entity);
        }
    }
    StopMapMusic();*/
}

public Action:Timer_PlayStartSound(Handle:timer, any:client) {
    if(IsValidClient(client))
        EmitSoundToClientAny(client, soundnew, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
    PlayMusic();

public Action:Event_player_changename(Handle:event, const String:name[], bool:dontBroadcast) {
    decl String:clientname[64], String:steamid[32], String:DBQuery[256];
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    GetClientName(client, clientname, sizeof(clientname));
    ReplaceString(clientname, sizeof(clientname), "'", "");
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
    Format(DBQuery, sizeof(DBQuery), "UPDATE players SET name='%s' WHERE steamid='%s'", clientname, steamid);
    SQL_TQuery(DB, SQLErrorCheckCallback, DBQuery);
}

public Action:Command_Say(client, const String:command[], arg) {
    if(!IsValidClient(client) || g_GlobalAntispam[client]) {
       return Plugin_Handled;
    }

    g_GlobalAntispam[client] = true;
    CreateTimer(1.5, Timer_Antispam, GetClientSerial(client));

    decl String:text[192];

    if(GetCmdArgString(text, sizeof(text)) < 1)
        return Plugin_Continue;

    if(!ParseChatCommands(client, text))
        return Plugin_Handled;

    if(CheckCommandAccess(client, "admin_allspec_flag", ADMFLAG_GENERIC) && strlen(text) > 0) {
        new String:formattedMsg[1024], String:name[64];
        GetClientName(client, name, sizeof(name));
        Format(formattedMsg, sizeof(formattedMsg), "{RED}[ADMIN] {GREEN}%s: {NORMAL}%s", name, text);
        CPrintToChatAll(formattedMsg);
        return Plugin_Handled;
    }

    if(g_VIP[client][IsVIP] && strlen(text) > 0) {
        new String:formattedMsg[1024], String:name[64];
        GetClientName(client, name, sizeof(name));
        Format(formattedMsg, sizeof(formattedMsg), "{RED}[VIP] {GREEN}%s: {NORMAL}%s", name, text);
        CPrintToChatAll(formattedMsg);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action:Command_SayTeam(client, const String:command[], arg) {
    if(g_GlobalAntispam[client])
        return Plugin_Handled;

    if(!IsValidClient(client))
        return Plugin_Handled;

    g_GlobalAntispam[client] = true;
    CreateTimer(1.5, Timer_Antispam, GetClientSerial(client));

    decl String:text[192];

    if(GetCmdArgString(text, sizeof(text)) < 1)
        return Plugin_Continue;

    if(!ParseChatCommands(client, text))
        return Plugin_Handled;

    return Plugin_Continue;
}

public bool:ParseChatCommands(const client, String:text[]) {
    StripQuotes(text);
    //TrimString(text);

    if(strcmp(text, "/elo_notify", false)==0 || strcmp(text, "elo_notify", false)==0) {
        decl String:query[512];
        if(notify[client]==false) {
            notify[client] = true;
            PluginMessageToClient(client, "{NORMAL}Zapol si rank notifikácie. Napíš {BLUE}/elo_notify{NORMAL} pre vypnutie notifikácií.");
            Format(query, sizeof(query), "UPDATE elostats SET notify=1 WHERE idPlayer='%d'", g_PlayerId[client]);
            SQL_TQuery(DB, SQLErrorCheckCallback, query);
        } else {
            notify[client] = false;
            PluginMessageToClient(client, "{NORMAL}Rank notifikácie boli vypnuté. Pre ich zapnutie napíš {BLUE}/elo_notify{NORMAL}.");
            Format(query, sizeof(query), "UPDATE elostats SET notify=0 WHERE idPlayer='%d'", g_PlayerId[client]);
            SQL_TQuery(DB, SQLErrorCheckCallback, query);
        }
        return false;
    } else if(strcmp(text, "rank", false)==0 || strcmp(text, "/rank", false)==0 || strcmp(text, "session", false)==0 || strcmp(text, "/session", false)==0) {
        decl String:clientid[32];
        GetClientAuthId(client, AuthId_Steam2, clientid, sizeof(clientid));
        if(StrContains(text, "rank", false)!=-1) {
            decl String:query[512];
            Format(query, sizeof(query), "SELECT COUNT(*) FROM elostats WHERE rating>%i", rating[client]);
            SQL_TQuery(DB, SQLQueryRank, query, GetClientUserId(client));
            return false;
        } else {
            decl String:buffer[64];
            new Handle:panel = CreatePanel();
            SetPanelTitle(panel, "Session stats:");
            Format(buffer, sizeof(buffer), "Hodnotenie: %i", sessionrating[client]);
            DrawPanelText(panel, buffer);
            Format(buffer, sizeof(buffer), "Zabitia: %i", sessionkills[client]);
            DrawPanelText(panel, buffer);
            Format(buffer, sizeof(buffer), "Asistencie: %i", sessionassists[client]);
            DrawPanelText(panel, buffer);
            Format(buffer, sizeof(buffer), "Smrti: %i", sessiondeaths[client]);
            DrawPanelText(panel, buffer);
            DrawPanelItem(panel, "Close");
            SendPanelToClient(panel, client, PanelHandlerNothing, 15);
            CloseHandle(panel);
        }
        return false;
    } else if(strcmp(text, "top10", false)==0 || strcmp(text, "/top10", false)==0 || strcmp(text, "top", false)==0) {
        SQL_TQuery(DB, SQLQueryTop10, "SELECT players.name, elostats.rating FROM elostats JOIN players ON elostats.idPlayer=players.id ORDER BY elostats.rating DESC LIMIT 0,10", GetClientUserId(client));
        return false;
    }


    if (StrEqual(text, "/bhop", false)) {
        if(HasPlayerVipAdv(client, AUTOBHOP)) {
            ToggleVipCookie(client, AUTOBHOP);
        } else {
            PluginMessageToClient(client, "Autobhop je iba pre VIP!");
        }
    }

    if (StrEqual(text, "/ts", false) || StrEqual(text, "/teamspeak", false) || StrEqual(text, "!ts", false) || StrEqual(text, "!teamspeak", false) || StrEqual(text, "ts", false)) {
        PrintTs(client);
        return false;
    }

    if (StrEqual(text, "/vip", false) || StrEqual(text, "/vipmenu", false) || StrEqual(text, "!vip", false) || StrEqual(text, "vip", false)) {
        DisplayVipMenu(client);
        return false;
    }

    if (StrEqual(text, "/vips", false) || StrEqual(text, "!vips", false) || StrEqual(text, "vips", false)) {
        DisplayVipListMenu(client);
        return false;
    }

    if (StrEqual(text, "/help", false) || StrEqual(text, "/help", false) || StrEqual(text, "!help", false) || StrEqual(text, "help", false) || StrEqual(text, "/info", false) || StrEqual(text, "/info", false) || StrEqual(text, "!info", false) || StrEqual(text, "info", false)) {
        PrintCommands(client);
        return false;
    }

    if (StrEqual(text, "/music", false) || StrEqual(text, "!music", false) || StrEqual(text, "music", false)) {
        if(g_PlayMusic[client]) {
            g_PlayMusic[client] = false;
            SetClientCookie(client, g_cookieMusic, "0");
            PluginMessageToClient(client, "Vypol si hudbu.");
        } else {
            g_PlayMusic[client] = true;
            SetClientCookie(client, g_cookieMusic, "1");
            PluginMessageToClient(client, "Zapol si hudbu.");
        }
        return false;
    }

    return true;
}

public Action:Command_Callvote(client, const String:cmd[], argc) {
    // kick vote from client, "callvote %s \"%d %s\"\n;"
    if (argc < 2)
        return Plugin_Continue;
    
    decl String:votereason[16];
    GetCmdArg(1, votereason, sizeof(votereason));
    
    if (!!strcmp(votereason, "kick", false))
        return Plugin_Continue;
    
    decl String:therest[256];
    GetCmdArg(2, therest, sizeof(therest));
    
    new userid = 0;
    new spacepos = FindCharInString(therest, ' ');
    if (spacepos > -1) {
        decl String:temp[12];
        strcopy(temp, min(spacepos+1, sizeof(temp)), therest);
        userid = StringToInt(temp);
    } else {
        userid = StringToInt(therest);
    }
    
    new target = GetClientOfUserId(userid);
    if (target < 1)
        return Plugin_Continue;
    
    new AdminId:clientAdmin = GetUserAdmin(client);
    new AdminId:targetAdmin = GetUserAdmin(target);
    
    if (clientAdmin == INVALID_ADMIN_ID && targetAdmin == INVALID_ADMIN_ID)
        return Plugin_Continue;
    
    if (CanAdminTarget(clientAdmin, targetAdmin))
        return Plugin_Continue;
    
    PrintToChat(client, "You may not start a kick vote against \"%N\"", target);
    
    return Plugin_Handled;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client   = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new assister = GetClientOfUserId(GetEventInt(event, "assister"));
    if (g_boostToggle[client]) BoostPlayerOff(client);
    if (!IsValidClient(client) || !IsValidClient(attacker)) {
        return Plugin_Continue;
    }
    if (!IsFakeClient(client)&&!IsFakeClient(attacker)&&client!=attacker) {
        decl String:query[512], String:buffer[256];
        new Float:prob = 1/(Pow(10.0, float((rating[client]-rating[attacker]))/400)+1);
        new diff = RoundFloat(16*(1-prob));
        if(assister!=0) {
            new diff2 = RoundToCeil(float(diff)/3.0);
            rating[assister] = rating[assister]+diff2;
            assists[assister]++;
            sessionassists[assister]++;
            Format(query, sizeof(query), "UPDATE elostats SET rating=%i,assists=%i WHERE idPlayer='%d'", rating[assister], assists[assister], g_PlayerId[assister]);
            SQL_TQuery(DB, SQLErrorCheckCallback, query);
            if(notify[assister]) {
                Format(buffer, sizeof(buffer), "{NORMAL}Ty ({BLUE}%i{NORMAL}) si dostal {BLUE}%i{NORMAL} body za asistenciu pri zabití hráča {LIGHTGREEN}%N{NORMAL} ({BLUE}%i{NORMAL}).", rating[assister], diff2, client, rating[client]);
                PluginMessageToClient(assister, buffer);
            }
        }

        rating[client] -= diff;
        sessionrating[client] -= diff;
        deaths[client]++;
        sessiondeaths[client]++;

        Format(query, sizeof(query), "UPDATE elostats SET rating=%i,deaths=%i WHERE idPlayer='%d'", rating[client], deaths[client], g_PlayerId[client]);
        SQL_TQuery(DB, SQLErrorCheckCallback, query);

        if(notify[client]) {
            Format(buffer, sizeof(buffer), "{NORMAL}Ty ({BLUE}%i{NORMAL}) si bol zabitý hráčom {LIGHTGREEN}%N{NORMAL} ({BLUE}%i{NORMAL}) a stratil si {BLUE}%i{NORMAL} bodov.", rating[client], attacker, rating[attacker], diff);
            PluginMessageToClient(client, buffer);
        }

        if(HasPlayerVipAdv(attacker, DOUBLEELO) && g_ELOCounter[attacker] % 2 == 0) {
            diff *= 2;
        }

        g_ELOCounter[attacker] += 1;
        rating[attacker] += diff;
        sessionrating[attacker] += diff;
        kills[attacker]++;
        sessionkills[attacker]++;

        Format(query, sizeof(query), "UPDATE elostats SET rating=%i,kills=%i WHERE idPlayer='%d'", rating[attacker], kills[attacker], g_PlayerId[attacker]);
        SQL_TQuery(DB, SQLErrorCheckCallback, query);

        if(notify[attacker]) {
            Format(buffer, sizeof(buffer), "{NORMAL}Ty ({BLUE}%i{NORMAL}) si dostal {BLUE}%i{NORMAL} bodov za zabitie hráča {LIGHTGREEN}%N{NORMAL} ({BLUE}%i{NORMAL}).", rating[attacker], diff, client, rating[client]);
            PluginMessageToClient(attacker, buffer);
        }
    }

    return Plugin_Continue;
}

public Event_MatchOver(Handle:event, const String:name[], bool:dontBroadcast)
{
    g_roundCounter = 0;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!IsValidClient(client)) return;

    for(new i = 1; i <= MaxClients; i++) {
        player_damage[client][i] = 0;
    }

    if(HasPlayerVipAdv(client, BUYMENU) && g_VIPCookie[client][BUYMENU] && g_roundCounter > 2) {
        CreateTimer(0.4, PlayerPostSpawn, client);
    }
}

public Action:PlayerPostSpawn(Handle:timer, any:client)
{
    DisplayMenu(g_VipSecondaryWeaponMenu, client, MENU_TIME_FOREVER);
    return Plugin_Continue;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
 {
    new client_attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new damage = GetEventInt(event, "dmg_health");
    
    CalcDamage(client, client_attacker, damage);
    
    return Plugin_Continue;
}

public Action:Event_RoundMvp(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (IsValidClient(client) && GetRealClientCount() > 2) {
        new diff = 10, String:query[256], String:buffer[128];
        rating[client] += diff;
        sessionrating[client] += diff;
        Format(query, sizeof(query), "UPDATE elostats SET rating=%i WHERE idPlayer='%d'", rating[client], g_PlayerId[client]);
        SQL_TQuery(DB, SQLErrorCheckCallback, query);

        if(notify[client]) {
            Format(buffer, sizeof(buffer), "{NORMAL}Získal si %i{NORMAL} bodov za MVP", rating[client], diff);
            PluginMessageToClient(client, buffer);
        }
    }

    return Plugin_Continue;
}

public Action:Event_ServerCvar(Handle:event, const String:name[], bool:dontBroadcast)
{
    return Plugin_Handled;
}

public Action:Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!HasPlayerVipAdv(client, AUTOBHOP) || !g_VIPCookie[client][AUTOBHOP]) {
        return Plugin_Continue;
    }

    new Float:finalvec[3];
    finalvec[0] = GetEntDataFloat(client, VelocityOffset_0)* g_bhopSpeed/2.0;
    finalvec[1] = GetEntDataFloat(client, VelocityOffset_1)* g_bhopSpeed/2.0;
    finalvec[2] = g_bhopHeight * 50.0;
    SetEntDataVector(client, BaseVelocityOffset, finalvec, true);

    return Plugin_Continue;
}