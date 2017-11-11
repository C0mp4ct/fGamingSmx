new bool:notify[MAXPLAYERS+1] = {true, ...};
new rankcount;
new rank[MAXPLAYERS+1];
new rating[MAXPLAYERS+1];
new kills[MAXPLAYERS+1];
new assists[MAXPLAYERS+1];
new deaths[MAXPLAYERS+1];
new sessionrating[MAXPLAYERS+1];
new sessionkills[MAXPLAYERS+1];
new sessionassists[MAXPLAYERS+1];
new sessiondeaths[MAXPLAYERS+1];

public CheckClientInElo(client)
{
    new playerId = getPlayerId(client);
    if (!playerId) {
        return;
    }

    new String:steamid[32], String:DBQuery[512];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
    Format(DBQuery, sizeof(DBQuery), "SELECT rating, kills, assists, deaths, notify FROM elostats WHERE idPlayer = %d", steamid);
    SQL_TQuery(DB, CheckClientInEloCallback, DBQuery, GetClientUserId(client));
    sessionrating[client]  = 0;
    sessionkills[client]   = 0;
    sessionassists[client] = 0;
    sessiondeaths[client]  = 0;
}

public CheckClientInEloCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    new client = GetClientOfUserId(data);
    if (client == 0) {
        return;
    }

    if (hndl == INVALID_HANDLE) {
        IronLog(false, "Query failed: %s", error);
        return;
    }

    if (SQL_GetRowCount(hndl) < 1) {
        new String:DBQuery[512];
        Format(DBQuery, sizeof(DBQuery), "INSERT INTO elostats(idPlayer, rating, kills, assists, deaths, notify) VALUES('%d', 1600, 0, 0, 0, 1)", g_PlayerId[client]);
        SQL_TQuery(DB, SQLErrorCheckCallback, DBQuery);
        rating[client]  = 1600;
        kills[client]   = 0;
        assists[client] = 0;
        deaths[client]  = 0;
        notify[client]  = true;
    } else {
        while (SQL_FetchRow(hndl)) {
            rating[client]  = SQL_FetchInt(hndl, 0);
            kills[client]   = SQL_FetchInt(hndl, 1);
            assists[client] = SQL_FetchInt(hndl, 2);
            deaths[client]  = SQL_FetchInt(hndl, 3);
            notify[client]  = !(SQL_FetchInt(hndl, 4) == 0);
        }
    }
}

public SQLQueryRank(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    new client = GetClientOfUserId(data);
    if (client == 0) {
        return;
    }

    if (hndl == INVALID_HANDLE) {
        IronLog(false, "Query failed: %s", error);
        return;
    }

    SQL_FetchRow(hndl);
    rank[client] = SQL_FetchInt(hndl, 0) + 1;
    SQL_TQuery(DB, SQLQueryCount, "SELECT COUNT(*) FROM elostats", GetClientUserId(client));
}

public SQLQueryCount(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    new client = GetClientOfUserId(data);
    if(client == 0) {
        IronLog(false, "Invalid client: %d", client);
        return;
    }
    SQL_FetchRow(hndl);
    rankcount = SQL_FetchInt(hndl, 0);
    decl String:rankstr[16];
    new Float:kpd = deaths[client]==0?0.0:float(kills[client])/float(deaths[client]);
    if((rank[client]%100)>10 && (rank[client]%100)<14)
        Format(rankstr, sizeof(rankstr), "%ith", rank[client]);
    else {
        switch(rank[client]%10) {
            case 0: Format(rankstr, sizeof(rankstr), "%ith", rank[client]);
            case 1: Format(rankstr, sizeof(rankstr), "%ist", rank[client]);
            case 2: Format(rankstr, sizeof(rankstr), "%ind", rank[client]);
            case 3: Format(rankstr, sizeof(rankstr), "%ird", rank[client]);
            case 4: Format(rankstr, sizeof(rankstr), "%ith", rank[client]);
            case 5: Format(rankstr, sizeof(rankstr), "%ith", rank[client]);
            case 6: Format(rankstr, sizeof(rankstr), "%ith", rank[client]);
            case 7: Format(rankstr, sizeof(rankstr), "%ith", rank[client]);
            case 8: Format(rankstr, sizeof(rankstr), "%ith", rank[client]);
            case 9: Format(rankstr, sizeof(rankstr), "%ith", rank[client]);
        }
    }
    decl String:buffer[64];
    new Handle:panel = CreatePanel();
    SetPanelTitle(panel, "fGaming ELO Ranking:");

    Format(buffer, sizeof(buffer), "Hodnotenie: %i", rating[client]);
    DrawPanelText(panel, buffer);

    Format(buffer, sizeof(buffer), "Rank: %s (of %i)", rankstr, rankcount);
    DrawPanelText(panel, buffer);

    Format(buffer, sizeof(buffer), "KPD: %.2f", kpd);
    DrawPanelText(panel, buffer);

    Format(buffer, sizeof(buffer), "Asistencie: %i", assists[client]);
    DrawPanelText(panel, buffer);

    DrawPanelItem(panel, "Close");

    SendPanelToClient(panel, client, PanelHandlerNothing, 15);
    CloseHandle(panel);
}

public SQLQueryTop10(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    new client = GetClientOfUserId(data);
    if(client == 0) {
        return;
    }

    if(hndl == INVALID_HANDLE) {
        IronLog(false, "Query failed: %s", error);
        return;
    }

    decl String:qname[64], String:qrating[8], String:buffer[68];
    new i = 0;
    new Handle:panel = CreatePanel();
    SetPanelTitle(panel, "Top 10 hráčov:");
    while(SQL_FetchRow(hndl)) {
        SQL_FetchString(hndl, 0, qname, sizeof(qname));
        SQL_FetchString(hndl, 1, qrating, sizeof(qrating));
        Format(buffer, sizeof(buffer), "%s: %s", qrating, qname);
        DrawPanelText(panel, buffer);
        i++;
    }
    DrawPanelItem(panel, "Close");
    SendPanelToClient(panel, client, PanelHandlerNothing, 15);
    CloseHandle(panel);
}

public Action:Command_show(client, args)
{
    for(new i=1; i <= GetMaxClients(); i++) {
        if(!IsClientInGame(i)) {
            continue;
        }
        PrintToConsole(client, "%N: %i", i, rating[i]);
    }

    return Plugin_Handled;
}

public PanelHandlerNothing(Handle:menu, MenuAction:action, param1, param2)
{
    // Do nothing
}