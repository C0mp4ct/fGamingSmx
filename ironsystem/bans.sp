// IRONZONE BAN SYSTEM CODED BY C0mp4ct

new g_BanTargetMenu[MAXPLAYERS+1];
new g_BanTimeMenu[MAXPLAYERS+1];
new g_BanTargetMenuUserId[MAXPLAYERS+1];
new g_IsWaitingForChatReason[MAXPLAYERS+1];
new Handle:g_hKvBanReasons;
new String:g_BanReasonsPath[PLATFORM_MAX_PATH];


public CheckClientBan(const client) {
    new String:DBQuery[256];
    Format(DBQuery, sizeof(DBQuery), "SELECT b.bantime, b.length, b.reason, pa.name, b.date FROM banlist AS b JOIN players p ON b.idPlayer=p.id JOIN players pa ON b.idAdmin=pa.id WHERE b.idPlayer='%d'", g_PlayerId[client]);
    SQL_TQuery(DB, CheckClientBanCallback, DBQuery, GetClientUserId(client));
}

public CheckClientBanCallback(Handle:owner, Handle:hndl, const String:error[], any:data) {
    new client = GetClientOfUserId(data);
    if(!SQL_GetRowCount(hndl)) {
        return;
    }

    while(SQL_FetchRow(hndl)) {
        new currentseconds = GetTime();
        new bantime = SQL_FetchInt(hndl, 0);
        new banminutes = SQL_FetchInt(hndl, 1);
        new String:reason[128], String:adminname[64], String:date[64];
        SQL_FetchString(hndl, 2, reason, sizeof(reason));
        SQL_FetchString(hndl, 3, adminname, sizeof(adminname));
        SQL_FetchString(hndl, 4, date, sizeof(date));
        //PrintToConsole(client, "Bantime: %d\nBanseconds: %d\nCurrentseconds: %d", bantime, banminutes * 60, currentseconds);
        if(bantime + banminutes * 60 > currentseconds || banminutes == 0) {
            new String:bantimes[32];
            switch(banminutes) {
                case 0: bantimes = "permanent";
                case 10: bantimes = "10 minutes";
                case 30: bantimes = "30 minutes";
                case 60: bantimes = "1 hour";
                case 240: bantimes = "4 hours";
                case 1440: bantimes = "1 day";
                case 10080: bantimes = "1 week";
                case 40320: bantimes = "1 month";
            }
            PrintToConsole(client, "------------------------------------------\n-------IRONZONE BANSYSTEM-------\n------------------------------------------\nZabanovaný adminom: %s\nDĺžka banu: %s\nČas zabanovania: %s\nReason: %s\n------------------------------------------", adminname, bantimes, date, reason);
            KickClient(client, "Bol si zabanovaný. Info v konzole.");
        }
    }
}

public Action:Command_BanPlayer(client, args) {
    if (args < 2) {
        ReplyToCommand(client, "[SM] Usage: sm_ban <#userid|name> <time(in minutes)> [reason]");
        return Plugin_Handled;
    }

    decl len, next_len;
    decl String:Arguments[256];
    GetCmdArgString(Arguments, sizeof(Arguments));

    decl String:arg[65];
    len = BreakString(Arguments, arg, sizeof(arg));

    new target = FindTarget(client, arg, true);
    if (target == -1)
    {
        return Plugin_Handled;
    }

    decl String:s_time[12];
    if ((next_len = BreakString(Arguments[len], s_time, sizeof(s_time))) != -1)
    {
        len += next_len;
    }
    else
    {
        len = 0;
        Arguments[0] = '\0';
    }

    BanPlayer(client, target, StringToInt(s_time), Arguments[len]);

    return Plugin_Continue;
}

public BanPlayer(const client, const target, const time, const String:reason[]) {
    if (client >= 1 && target >= 1 && IsValidClient(target)) {

        new String:datetime[32], String:DBQuery[256];
        FormatTime(datetime, sizeof(datetime), "%Y-%m-%d %H:%M:%S", GetTime());

        Format(DBQuery, sizeof(DBQuery), "INSERT INTO banlist(idPlayer, bantime, length, date, reason, idAdmin) VALUES('%d','%d','%d','%s','%s','%d')", g_PlayerId[target], GetTime(), time, datetime, reason, g_PlayerId[client]);
        SQL_TQuery(DB, SQLErrorCheckCallback, DBQuery);
        CheckClientBan(target);
    } else {
        IronLog(false, "Bad arguments in BanPlayer");
    }
}

public AdminMenu_Ban(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
    g_IsWaitingForChatReason[param] = false;
    
    if (action == TopMenuAction_DisplayOption)
    {
        Format(buffer, maxlength, "%T", "Ban player", param);
    }
    else if (action == TopMenuAction_SelectOption)
    {
        DisplayBanTargetMenu(param);
    }
}

DisplayBanTargetMenu(client) {
    new Handle:menu = CreateMenu(MenuHandler_BanPlayerList);

    decl String:title[100];
    Format(title, sizeof(title), "%T:", "Ban player", client);
    SetMenuTitle(menu, title);
    SetMenuExitBackButton(menu, true);

    AddTargetsToMenu2(menu, client, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}



public MenuHandler_BanPlayerList(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
    else if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
        {
            DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
        }
    }
    else if (action == MenuAction_Select)
    {
        decl String:info[32], String:name[32];
        new userid, target;

        GetMenuItem(menu, param2, info, sizeof(info), _, name, sizeof(name));
        userid = StringToInt(info);

        if ((target = GetClientOfUserId(userid)) == 0)
        {
            PluginMessageToClient(param1, "[SM] %t", "Player no longer available");
        }
        else if (!CanUserTarget(param1, target))
        {
            PluginMessageToClient(param1, "[SM] %t", "Unable to target");
        }
        else
        {
            g_BanTargetMenu[param1] = target;
            g_BanTargetMenuUserId[param1] = userid;
            DisplayBanTimeMenu(param1);
        }
    }
}

DisplayBanTimeMenu(client)
{
    new Handle:menu = CreateMenu(MenuHandler_BanTimeList);

    decl String:title[100];
    Format(title, sizeof(title), "%T: %N", "Ban player", client, g_BanTargetMenu[client]);
    SetMenuTitle(menu, title);
    SetMenuExitBackButton(menu, true);

    AddMenuItem(menu, "0", "Permanent");
    AddMenuItem(menu, "10", "10 Minutes");
    AddMenuItem(menu, "30", "30 Minutes");
    AddMenuItem(menu, "60", "1 Hour");
    AddMenuItem(menu, "240", "4 Hours");
    AddMenuItem(menu, "1440", "1 Day");
    AddMenuItem(menu, "10080", "1 Week");

    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_BanTimeList(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
    else if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
        {
            DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
        }
    }
    else if (action == MenuAction_Select)
    {
        decl String:info[32];

        GetMenuItem(menu, param2, info, sizeof(info));
        g_BanTimeMenu[param1] = StringToInt(info);

        DisplayBanReasonMenu(param1);
    }
}

DisplayBanReasonMenu(client)
{
    new Handle:menu = CreateMenu(MenuHandler_BanReasonList);

    decl String:title[100];
    Format(title, sizeof(title), "%T: %N", "Ban reason", client, g_BanTargetMenu[client]);
    SetMenuTitle(menu, title);
    SetMenuExitBackButton(menu, true);
    
    //Add custom chat reason entry first
    AddMenuItem(menu, "", "Custom reason (type in chat)");
    
    //Loading configurable entries from the kv-file
    decl String:reasonName[100];
    decl String:reasonFull[255];
    
    //Iterate through the kv-file
    KvGotoFirstSubKey(g_hKvBanReasons, false);
    do
    {
        KvGetSectionName(g_hKvBanReasons, reasonName, sizeof(reasonName));
        KvGetString(g_hKvBanReasons, NULL_STRING, reasonFull, sizeof(reasonFull));
        
        //Add entry
        AddMenuItem(menu, reasonFull, reasonName);
        
    } while (KvGotoNextKey(g_hKvBanReasons, false));
    
    //Reset kvHandle
    KvRewind(g_hKvBanReasons);

    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_BanReasonList(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
    else if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
        {
            DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
        }
    }
    else if (action == MenuAction_Select)
    {
        if(param2 == 0)
        {
            //Chat reason
            g_IsWaitingForChatReason[param1] = true;
            PluginMessageToClient(param1, "[SM] %t", "Custom ban reason explanation", "sm_abortban");
        }
        else
        {
            decl String:info[64];
            
            GetMenuItem(menu, param2, info, sizeof(info));
            
            PrepareBan(param1, g_BanTargetMenu[param1], g_BanTimeMenu[param1], info);
        }
    }
}

PrepareBan(client, target, time, const String:reason[])
{
    new originalTarget = GetClientOfUserId(g_BanTargetMenuUserId[client]);

    if (originalTarget != target)
    {
        if (client == 0)
        {
            PrintToServer("[SM] %t", "Player no longer available");
        }
        else
        {
            PluginMessageToClient(client, "[SM] %t", "Player no longer available");
        }

        return;
    }

    new String:name[32];
    GetClientName(target, name, sizeof(name));

    if (!time)
    {
        if (reason[0] == '\0')
        {
            PluginMessage("Hráč %s bol permanentne zabanovaný.", name);
        } else {
            PluginMessage("Hráč %s bol permanentne zabanovaný.\nDôvod: %s.", name, reason);
        }
    } else {
        new String:bantimes[32];
        switch(time) {
            case 0: bantimes = "permanent";
            case 10: bantimes = "10 minút";
            case 30: bantimes = "30 minút";
            case 60: bantimes = "1 hodina";
            case 240: bantimes = "4 hodiny";
            case 1440: bantimes = "1 deň";
            case 10080: bantimes = "1 týždeň";
            case 40320: bantimes = "1 mesiac";
        }
        if (reason[0] == '\0')
        {
            PluginMessage("Hráč %s bol zabanovaný na %s.", name, bantimes);
        } else {
            PluginMessage("Hráč %s bol zabanovaný na %s.\nDôvod: %s.", name, time, reason);
        }
    }

    LogAction(client, target, "\"%L\" banned \"%L\" (minutes \"%d\") (reason \"%s\")", client, target, time, reason);

    if (reason[0] == '\0')
    {
        BanPlayer(client, target, time, "Zabanovaný");
    }
    else
    {
        BanPlayer(client, target, time, reason);
    }
}

LoadBanReasons() {
    if (g_hKvBanReasons != INVALID_HANDLE)
    {
        CloseHandle(g_hKvBanReasons);
    }

    g_hKvBanReasons = CreateKeyValues("banreasons");

    if(FileToKeyValues(g_hKvBanReasons, g_BanReasonsPath))
    {
        decl String:sectionName[255];
        if(!KvGetSectionName(g_hKvBanReasons, sectionName, sizeof(sectionName)))
        {
            SetFailState("Error in %s: File corrupt or in the wrong format", g_BanReasonsPath);
        }

        if(strcmp(sectionName, "banreasons") != 0)
        {
            SetFailState("Error in %s: Couldn't find 'banreasons'", g_BanReasonsPath);
        }
        
        //Reset kvHandle
        KvRewind(g_hKvBanReasons);
    } else {
        SetFailState("Error in %s: File not found, corrupt or in the wrong format", g_BanReasonsPath);
    }

    return true;
}