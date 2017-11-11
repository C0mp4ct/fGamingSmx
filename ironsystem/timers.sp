public Action:Timer_PostMapStart(Handle:timer)
{
    if(DB == INVALID_HANDLE) {
        IronLog(false, "Failed - DB not connected");
        return;
    }
}

public Action:Timer_WelcomeMessage(Handle:timer, any:serial)
{
    new client = GetClientFromSerial(serial);
    if(IsValidClient(client)) {
        PluginMessageToClient(client, "{NORMAL}Srdečne ťa vítame na {BLUE}fGaming serveri. Uži si veľa zábavy!");
        PrintCommands(client);
    }
}

public Action:Timer_VipMessage(Handle:timer, any:serial)
{
    new client = GetClientFromSerial(serial);
    if(IsValidClient(client) && !HasPlayerVip(client)) {
        PluginMessageToClient(client, "{NORMAL}Aktivuj si {RED}VIP {NORMAL}a získaj super výhody. Použi príkaz {BLUE}/vip {NORMAL}pre viac info!");
        CreateTimer(60.0, Timer_UsefullCommands, GetClientSerial(client));
    }
}

public Action:Timer_UsefullCommands(Handle:timer, any:serial)
{
    new client = GetClientFromSerial(serial);
    if(IsValidClient(client)) {
        PrintCommands(client);
        CreateTimer(60.0, Timer_KnifeMessage, GetClientSerial(client));
    }
}

public Action:Timer_KnifeMessage(Handle:timer, any:serial)
{
    new client = GetClientFromSerial(serial);
    if(IsValidClient(client)) {
        PluginMessageToClient(client, "{NORMAL}Pre zmenu nožíka použi príkaz {BLUE}!knife");
        CreateTimer(60.0, Timer_Ts, GetClientSerial(client));
    }
}

public Action:Timer_Ts(Handle:timer, any:serial)
{
    new client = GetClientFromSerial(serial);
    if(IsValidClient(client)) {
        PrintTs(client);
        CreateTimer(60.0, Timer_VipMessage, GetClientSerial(client));
    }
}

public Action:Timer_ResetAntiSpams(Handle:timer, any:serial)
{
    new client = GetClientFromSerial(serial);
    g_antitelspam[client] = false;
    g_antipickspam[client] = false;
    g_antibuyspam[client] = false;
}

public Action:Timer_TimeCounter(Handle:timer, any:serial)
{
    new client = GetClientFromSerial(serial);
    if(IsValidClient(client)) {
        g_seconds[client] += 20;
        if(g_seconds[client] >= 60) {
            g_minutes[client] += 1;
            g_seconds[client] = 0;
        }
        if(g_minutes[client] >= 60) {
            g_hours[client] += 1;
            g_minutes[client] = 0;
        }
        /*new String:time[16], String:times[3][16], String:hours[16], String:minutes[16], String:seconds[16];
        IntToString(g_hours[client], hours, sizeof(hours));
        IntToString(g_minutes[client], minutes, sizeof(minutes));
        IntToString(g_seconds[client], seconds, sizeof(seconds));
        times[0] = hours;
        times[1] = minutes;
        times[2] = seconds;
        ImplodeStrings(times, 3, ":", time, sizeof(time));
        IronLog(true, "Counter Time: %s", time);*/
    }
}

public Action:Timer_CheckClientBan(Handle:timer, any:serial)
{
    new client = GetClientFromSerial(serial);
    if (IsValidClient(client))
        CheckClientBan(client);
}

public Action:Timer_Antispam(Handle:timer, any:serial)
{
    new client = GetClientFromSerial(serial);
    if(IsValidClient(client)) {
        g_GlobalAntispam[client] = false;
    }
}

public Action:Timer_CheckAdminsInDB(Handle:timer)
{
    if(!KvGotoNextKey(kvAdmins)) {
        CloseHandle(kvAdmins);
        return;
    }

    new String:buffer[64], String:DBQuery[512];
    new Handle:data = CreateArray(ByteCountToCells(64));
    KvGetString(kvAdmins, "auth", buffer, sizeof(buffer));
    if (StrEqual("steam", buffer)) {
        KvGetString(kvAdmins, "identity", buffer, sizeof(buffer));
        Format(DBQuery, sizeof(DBQuery), "SELECT idPlayer, adminFlag FROM admins JOIN players ON admins.idPlayer=players.id WHERE players.steamid='%s'", buffer);
        PushArrayString(data, buffer);
        SQL_TQuery(DB, CheckAdminsInDBCallback, DBQuery, data);
    }
    CreateTimer(6.0, Timer_CheckAdminsInDB, _);
}

/*public Action:Timer_RankNotifications(Handle:timer, any:serial) {
    new client = GetClientFromSerial(serial);
    if(IsValidClient(client)) {
        PluginMessageToClient(client, "{NORMAL}Ak chceš dostávať notifikácie o ranku, tak napíš {BLUE}/elo_notify {NORMAL}do chatu");

    }
}*/