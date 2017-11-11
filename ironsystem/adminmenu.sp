new g_advtarget[MAXPLAYERS+1];

public Handle_AdminCategory(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
    switch(action) {
        case TopMenuAction_DisplayTitle:
            Format(buffer, maxlength, "IronSystem manager");
        case TopMenuAction_DisplayOption:
            Format(buffer, maxlength, "IronSystem manager");
    }
}

public Handle_VipAdd(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
    switch(action) {
        case TopMenuAction_DisplayOption:
            Format(buffer, maxlength, "Zapnúť / vypnúť VIP");
        case TopMenuAction_SelectOption:
            DisplayVipAddTargetMenu(param);
    }
}

public Handle_AdvAdd(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
    switch(action) {
        case TopMenuAction_DisplayOption:
            Format(buffer, maxlength, "Nastaviť VIP výhody");
        case TopMenuAction_SelectOption:
            DisplayAdvAddTargetMenu(param);
    }
}

public Handle_Bhop(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
    switch(action) {
        case TopMenuAction_DisplayOption:
            Format(buffer, maxlength, "Bhop nastavenia");
        case TopMenuAction_SelectOption:
            DisplayBhopMenu(param);
    }
}

public Handle_MusicType(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
    switch(action) {
        case TopMenuAction_DisplayOption:
            Format(buffer, maxlength, "Zmeniť prehrávanie hudby");
        case TopMenuAction_SelectOption: {
            if(GetConVarInt(g_hPlayType) == 1) {
                SetConVarInt(g_hPlayType, 2);
                PluginMessageToClient(param, "Štýl prehrávania bol zmenený na {BLUE}postupný");
            } else {
                SetConVarInt(g_hPlayType, 1);
                PluginMessageToClient(param, "Štýl prehrávania bol zmenený na {BLUE}náhodný");
            }
            DisplayTopMenu(topmenu, param, TopMenuPosition_LastCategory);
        }
    }
}

public OnAdminMenuReady(Handle:topmenu)
{
    /* Block us from being called twice */
    if (topmenu == hTopMenu)
        return;
    
    /* Save the Handle */
    hTopMenu = topmenu;
    
    /* Find the "Player Commands" category */
    new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
    new TopMenuObject:ironsystem = FindTopMenuCategory(hTopMenu, "Ironsystem");
    
    if (ironsystem == INVALID_TOPMENUOBJECT) {
        ironsystem = AddToTopMenu(hTopMenu, "Ironsystem", TopMenuObject_Category, Handle_AdminCategory, INVALID_TOPMENUOBJECT, "sm_ironsystem", ADMFLAG_CHEATS);

        AddToTopMenu(hTopMenu, "sm_vipadd", TopMenuObject_Item, Handle_VipAdd, ironsystem, "sm_vipadd", ADMFLAG_BAN);
        AddToTopMenu(hTopMenu, "sm_advadd", TopMenuObject_Item, Handle_AdvAdd, ironsystem, "sm_advadd", ADMFLAG_BAN);
        AddToTopMenu(hTopMenu, "sm_bhop", TopMenuObject_Item, Handle_Bhop, ironsystem, "sm_bhop", ADMFLAG_BAN);
        AddToTopMenu(hTopMenu, "sm_musictype", TopMenuObject_Item, Handle_MusicType, ironsystem, "sm_musictype", ADMFLAG_BAN);
    }

    if (player_commands != INVALID_TOPMENUOBJECT)
        AddToTopMenu(hTopMenu, "sm_ban", TopMenuObject_Item, AdminMenu_Ban, player_commands, "sm_ban", ADMFLAG_BAN);
}

DisplayVipAddTargetMenu(client)
{
    new Handle:menu = CreateMenu(MenuHandler_VipAddPlayerList);

    decl String:title[100], String:buffer[100], String:name[64], String:userid[8];
    Format(title, sizeof(title), "Pridelit VIP");
    SetMenuTitle(menu, title);
    SetMenuExitBackButton(menu, true);

    for(new i = 1; i < MaxClients; i++) {
        if(IsValidClient(i)) {
            GetClientName(i, name, sizeof(name));
            IntToString(GetClientUserId(i), userid, sizeof(userid));
            Format(buffer, sizeof(buffer), "%s %s", name, HasPlayerVip(i) ? "-" : "+");
            AddMenuItem(menu, userid, buffer);
        }
    }

    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_VipAddPlayerList(Handle:menu, MenuAction:action, param1, param2) {
    if (action == MenuAction_End)
        CloseHandle(menu);

    else if (action == MenuAction_Cancel) {
        if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
            DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
    }
    else if (action == MenuAction_Select) {
        decl String:info[32];
        new userid, target;

        GetMenuItem(menu, param2, info, sizeof(info));
        userid = StringToInt(info);

        if ((target = GetClientOfUserId(userid)) == 0)
            PluginMessageToClient(param1, "Hráč už nie je k dispozícii");

        else if (!CanUserTarget(param1, target))
            PluginMessageToClient(param1, "Neplatný cieľ");

        else {
            VipToggle(target, param1);
            DisplayVipAddTargetMenu(param1);
        }
    }
}

DisplayAdvAddTargetMenu(client) {
    new Handle:menu = CreateMenu(MenuHandler_AdvAddPlayerList);

    decl String:title[100];
    Format(title, sizeof(title), "VIP manager");
    SetMenuTitle(menu, title);
    SetMenuExitBackButton(menu, true);

    AddTargetsToMenu2(menu, client, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_AdvAddPlayerList(Handle:menu, MenuAction:action, param1, param2) {
    if (action == MenuAction_End) {
        CloseHandle(menu);
    }
    else if (action == MenuAction_Cancel) {
        if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
            DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
    }
    else if (action == MenuAction_Select) {
        decl String:info[32], String:name[32];
        new userid, target;

        GetMenuItem(menu, param2, info, sizeof(info), _, name, sizeof(name));
        userid = StringToInt(info);

        if ((target = GetClientOfUserId(userid)) == 0)
            PluginMessageToClient(param1, "Hráč už nie je k dispozícii");

        else if (!CanUserTarget(param1, target))
            PluginMessageToClient(param1, "Neplatný cieľ");

        else {
            g_advtarget[param1] = target;
            DisplayAdvAddAdvsMenu(param1);
        }
    }
}

DisplayAdvAddAdvsMenu(client) {
    new Handle:menu = CreateMenu(MenuHandler_AdvAddAdvs);

    decl String:title[100], String:buffer[100];
    Format(title, sizeof(title), "Prideliť VIP výhody");
    SetMenuTitle(menu, title);
    SetMenuExitBackButton(menu, true);
    new target = g_advtarget[client];

    Format(buffer, sizeof(buffer), "Nákup AWP/autolam [%s]", HasPlayerVipAdv(target, WEAPONS) ? "-" : "+");
    AddMenuItem(menu, "WEAPONS", buffer);
    Format(buffer, sizeof(buffer), "Indikátor zásahov [%s]", HasPlayerVipAdv(target, SHOWDMG) ? "-" : "+");
    AddMenuItem(menu, "SHOWDMG", buffer);
    Format(buffer, sizeof(buffer), "Zrýchlenie [%s]", HasPlayerVipAdv(target, SPEED) ? "-" : "+");
    AddMenuItem(menu, "SPEED", buffer);
    Format(buffer, sizeof(buffer), "AutoBhop [%s]", HasPlayerVipAdv(target, AUTOBHOP) ? "-" : "+");
    AddMenuItem(menu, "AUTOBHOP", buffer);
    Format(buffer, sizeof(buffer), "Double ELO points [%s]", HasPlayerVipAdv(target, DOUBLEELO) ? "-" : "+");
    AddMenuItem(menu, "DOUBLEELO", buffer);
    Format(buffer, sizeof(buffer), "Buy Menu [%s]", HasPlayerVipAdv(target, BUYMENU) ? "-" : "+");
    AddMenuItem(menu, "BUYMENU", buffer);

    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_AdvAddAdvs(Handle:menu, MenuAction:action, param1, param2) {
    if (action == MenuAction_End)
        CloseHandle(menu);

    else if (action == MenuAction_Cancel) {
        if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
            DisplayAdvAddTargetMenu(param1);
    }
    else if (action == MenuAction_Select) {
        decl String:info[32];
        new target = g_advtarget[param1];
        GetMenuItem(menu, param2, info, sizeof(info));
        if(StrEqual(info, "WEAPONS", false)) {
            g_VIP[target][WEAPONS] = !g_VIP[target][WEAPONS];
        } else if(StrEqual(info, "SHOWDMG", false)) {
            g_VIP[target][SHOWDMG] = !g_VIP[target][SHOWDMG];
        } else if(StrEqual(info, "SPEED", false)) {
            g_VIP[target][SPEED] = !g_VIP[target][SPEED];
        } else if(StrEqual(info, "AUTOBHOP", false)) {
            g_VIP[target][AUTOBHOP] = !g_VIP[target][AUTOBHOP];
        } else if(StrEqual(info, "DOUBLEELO", false)) {
            g_VIP[target][DOUBLEELO] = !g_VIP[target][DOUBLEELO];
        } else if(StrEqual(info, "BUYMENU", false)) {
            g_VIP[target][BUYMENU] = !g_VIP[target][BUYMENU];
        }

        DisplayAdvAddAdvsMenu(param1);
    }
}

DisplayBhopMenu(client) {
    new Handle:menu = CreateMenu(MenuHandler_Bhop);

    decl String:title[100];
    Format(title, sizeof(title), "Bhop nastavenia");
    SetMenuTitle(menu, title);
    SetMenuExitBackButton(menu, true);

    AddMenuItem(menu, "speed", "Rýchlosť odpichu");
    AddMenuItem(menu, "height", "Výška odpichu");

    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Bhop(Handle:menu, MenuAction:action, param1, param2) {
    if (action == MenuAction_End) {
        CloseHandle(menu);
    }
    else if (action == MenuAction_Cancel) {
        if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE) {
            DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
        }
    }
    else if (action == MenuAction_Select) {
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        if(StrEqual(info, "speed", false)) {
            DisplayBhopSpeedMenu(param1);
        } else if(StrEqual(info, "height", false)) {
            DisplayBhopHeightMenu(param1);
        }
    }
}

DisplayBhopSpeedMenu(client) {
    new Handle:menu = CreateMenu(MenuHandler_BhopSpeed);

    decl String:title[100];
    Format(title, sizeof(title), "Nastavenie rýchlosti odpichu");
    SetMenuTitle(menu, title);
    SetMenuExitBackButton(menu, true);

    AddMenuItem(menu, "+001", "+0.01");
    AddMenuItem(menu, "+005", "+0.05");
    AddMenuItem(menu, "+01", "+0.1");
    AddMenuItem(menu, "-001", "-0.01");
    AddMenuItem(menu, "-005", "-0.05");
    AddMenuItem(menu, "-01", "-0.1");

    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_BhopSpeed(Handle:menu, MenuAction:action, param1, param2) {
    if (action == MenuAction_End) {
        CloseHandle(menu);
    }
    else if (action == MenuAction_Cancel) {
        if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE) {
            DisplayBhopMenu(param1);
        }
    }
    else if (action == MenuAction_Select) {
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        if(StrEqual(info, "+001", false)) {
            g_bhopSpeed += 0.01;
        } else if(StrEqual(info, "+005", false)) {
            g_bhopSpeed += 0.05;
        } else if(StrEqual(info, "+01", false)) {
            g_bhopSpeed += 0.1;
        } else if(StrEqual(info, "-001", false)) {
            g_bhopSpeed -= 0.01;
        } else if(StrEqual(info, "-005", false)) {
            g_bhopSpeed -= 0.05;
        } else if(StrEqual(info, "-01", false)) {
            g_bhopSpeed -= 0.1;
        }
        PluginMessageToClient(param1, "Rýchlosť bhop zmenená na {BLUE}%f {NORMAL}(default: 0.35)", g_bhopSpeed);
        DisplayBhopSpeedMenu(param1);
    }
}

DisplayBhopHeightMenu(client) {
    new Handle:menu = CreateMenu(MenuHandler_BhopHeight);

    decl String:title[100];
    Format(title, sizeof(title), "Nastavenia výšky odpichu");
    SetMenuTitle(menu, title);
    SetMenuExitBackButton(menu, true);

    AddMenuItem(menu, "+001", "+0.01");
    AddMenuItem(menu, "+005", "+0.05");
    AddMenuItem(menu, "+01", "+0.1");
    AddMenuItem(menu, "-001", "-0.01");
    AddMenuItem(menu, "-005", "-0.05");
    AddMenuItem(menu, "-01", "-0.1");

    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_BhopHeight(Handle:menu, MenuAction:action, param1, param2) {
    if (action == MenuAction_End) {
        CloseHandle(menu);
    }
    else if (action == MenuAction_Cancel) {
        if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE) {
            DisplayBhopMenu(param1);
        }
    }
    else if (action == MenuAction_Select) {
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        if(StrEqual(info, "+001", false)) {
            g_bhopHeight += 0.01;
        } else if(StrEqual(info, "+005", false)) {
            g_bhopHeight += 0.05;
        } else if(StrEqual(info, "+01", false)) {
            g_bhopHeight += 0.1;
        } else if(StrEqual(info, "-001", false)) {
            g_bhopHeight -= 0.01;
        } else if(StrEqual(info, "-005", false)) {
            g_bhopHeight -= 0.05;
        } else if(StrEqual(info, "-01", false)) {
            g_bhopHeight -= 0.1;
        }
        PluginMessageToClient(param1, "Výška bhop zmenená na {BLUE}%f {NORMAL}(default: 0.0)", g_bhopHeight);
        DisplayBhopHeightMenu(param1);
    }
}