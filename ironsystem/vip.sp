#define BLANK   ""

enum VIP {
    bool:IsVIP,
    bool:WEAPONS,
    bool:SHOWDMG,
    bool:SPEED,
    bool:AUTOBHOP,
    bool:DOUBLEELO,
    bool:BUYMENU
}

new g_VIP[MAXPLAYERS+1][VIP];
new Handle:g_VIPCookie[MAXPLAYERS+1][VIP];

new Handle:hWeaponsIDArray = INVALID_HANDLE;
new Handle:hWeaponEntityArray = INVALID_HANDLE;

new bool:g_antibuyspam[MAXPLAYERS+1];
new bool:g_antipickspam[MAXPLAYERS+1];
new bool:g_antitelspam[MAXPLAYERS+1];

new player_damage[MAXPLAYERS+1][MAXPLAYERS+1];

/*new bool:g_canPlayerTeleport[MAXPLAYERS+1] = false;
new g_teleCounter[MAXPLAYERS+1] = 180;*/

new Float:g_boost[MAXPLAYERS+1];
new bool:g_boostToggle[MAXPLAYERS+1] = false;

new g_ELOCounter[MAXPLAYERS+1];

new Float:g_bhopSpeed = 0.15;
new Float:g_bhopHeight = 0.0;

//VIP Buymenu
new Handle:g_VipPrimaryWeaponMenu = INVALID_HANDLE;
new Handle:g_VipSecondaryWeaponMenu = INVALID_HANDLE;
new Handle:g_VipsMenu = INVALID_HANDLE;

public SetVipAdvs(client, bool:status)
{
    g_VIP[client][WEAPONS]   = status;
    g_VIP[client][SHOWDMG]   = status;
    g_VIP[client][SPEED]     = status;
    g_VIP[client][AUTOBHOP]  = status;
    g_VIP[client][DOUBLEELO] = status;
    g_VIP[client][BUYMENU]   = status;
}

public SetFullVipAdvs(client)
{
    for(new VIP:i; i < VIP; i++) {
        g_VIP[client][i] = true;
    }
}

public LoadVipCookies(client)
{
    new String:value[16];
    GetClientCookie(client, g_cookieAutoBhop, value, sizeof(value));
    if(strlen(value) > 0) {
        if(StringToInt(value) == 0)
            g_VIPCookie[client][AUTOBHOP] = false;
        else
            g_VIPCookie[client][AUTOBHOP] = true;
    } else {
        g_VIPCookie[client][AUTOBHOP] = true;
        SetClientCookie(client, g_cookieAutoBhop, "1");
    }

    GetClientCookie(client, g_cookieDmg, value, sizeof(value));
    if(strlen(value) > 0) {
        if(StringToInt(value) == 0)
            g_VIPCookie[client][SHOWDMG] = false;
        else 
            g_VIPCookie[client][SHOWDMG] = true;
    } else {
        g_VIPCookie[client][SHOWDMG] = true;
        SetClientCookie(client, g_cookieDmg, "1");
    }

    GetClientCookie(client, g_cookieBuyMenu, value, sizeof(value));
    if(strlen(value) > 0) {
        if(StringToInt(value) == 0)
            g_VIPCookie[client][BUYMENU] = false;
        else 
            g_VIPCookie[client][BUYMENU] = true;
    } else {
        g_VIPCookie[client][BUYMENU] = true;
        SetClientCookie(client, g_cookieBuyMenu, "1");
    }
}

public ToggleVipCookie(const client, VIP:advant)
{
    g_VIPCookie[client][advant] = !(g_VIPCookie[client][advant]);
    if(advant == AUTOBHOP) {
        SetClientCookie(client, g_cookieAutoBhop, g_VIPCookie[client][AUTOBHOP] ? "1" : "0");
        if(g_VIPCookie[client][advant]) {
            PluginMessageToClient(client, "Auto bunny hop bol zapnutý.");
        } else {
            PluginMessageToClient(client, "Auto bunny hop bol vypnutý.");
        }
    } else if(advant == SHOWDMG) {
        SetClientCookie(client, g_cookieDmg, g_VIPCookie[client][SHOWDMG] ? "1" : "0");
        if(g_VIPCookie[client][advant]) {
            PluginMessageToClient(client, "Indikátor poškodenia bol zapnutý.");
        } else {
            PluginMessageToClient(client, "Indikátor poškodenia bol vypnutý.");
        }
    } else if(advant == BUYMENU) {
        SetClientCookie(client, g_cookieBuyMenu, g_VIPCookie[client][BUYMENU] ? "1" : "0");
        if(g_VIPCookie[client][advant]) {
            PluginMessageToClient(client, "Nákupné menu bolo zapnuté.");
        } else {
            PluginMessageToClient(client, "Nákupné menu bolo zapnuté. vypnuté.");
        }
    }
}

public bool:HasPlayerVipAdv(client, const VIP:adv)
{
    if(g_VIP[client][adv]) {
        return true;
    }

    return false;
}

public bool:HasPlayerVip(client)
{
    if(g_VIP[client][IsVIP]) {
        return true;
    }

    return false;
}

public SetPlayerVip(client)
{
    g_VIP[client][IsVIP] = true;
    SetFullVipAdvs(client);
}

public UnsetPlayerVip(client)
{
    g_VIP[client][IsVIP] = false;
    SetVipAdvs(client, false);
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

DisplayVipMenu(const client)
{
    decl String:stav[32];
    new Handle:panel = CreatePanel();
    if(HasPlayerVip(client))
        Format(stav, sizeof(stav), "Stav VIP: AKTIVNE");
    else
        Format(stav, sizeof(stav), "Stav VIP: NEAKTIVNE");
    
    SetPanelTitle(panel, "VIP Menu");
    DrawPanelText(panel, stav);
    DrawPanelItem(panel, BLANK, ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
    if(!HasPlayerVip(client)) {
        DrawPanelItem(panel, "Aktivacia VIP");
        DrawPanelItem(panel, "VIP Výhody");
        SetPanelCurrentKey(panel, 5);
        DrawPanelItem(panel, "VIP Členovia");
        DrawPanelItem(panel, "Nastavenia", ITEMDRAW_DISABLED);
    } else {
        DrawPanelItem(panel, "Aktivacia VIP", ITEMDRAW_DISABLED);
        DrawPanelItem(panel, "VIP Výhody");
        DrawPanelItem(panel, "Nastavenia");
        DrawPanelItem(panel, "Help");
        DrawPanelItem(panel, "VIP Členovia");
    }
    DrawPanelItem(panel, BLANK, ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
    SetPanelCurrentKey(panel, 9);
    DrawPanelItem(panel, "Exit");
    SendPanelToClient(panel, client, VipMenuHandler, 20);
}

public VipMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if(action == MenuAction_Select) {
        new client = param1;
        switch(param2) {
            case 1:{DisplayVipActivationMenu(client);}
            case 2:{DisplayVipInfoMenu(client);}
            case 3:{DisplayVipSettingsMenu(client);}
            case 4:{DisplayVipHelpMenu(client);}
            case 5:{DisplayVipsMenu(client);}
        }
    }
}

DisplayVipActivationMenu(const client)
{
    new Handle:panel = CreatePanel();
    SetPanelTitle(panel, "VIP Aktivácia");
    DrawPanelText(panel, "Pracujeme na VIP");
//    new String:text[128];
//    Format(text, sizeof(text), "Pre SK: 'FAKAHEDA H82142 3.2 VIP %d' na číslo 8866", g_PlayerId[client]);
//    DrawPanelItem(panel, text, ITEMDRAW_DISABLED);
//    Format(text, sizeof(text), "Pre CZ: 'FAKAHEDA H82142 79 VIP %d' na číslo 90333", g_PlayerId[client]);
//    DrawPanelItem(panel, text, ITEMDRAW_DISABLED);
//    DrawPanelItem(panel, BLANK, ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
//    DrawPanelText(panel, "Cena VIP pre SK je 3,20€, pre CZ 79kč");
//    DrawPanelItem(panel, BLANK, ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
    SetPanelCurrentKey(panel, 8);
    DrawPanelItem(panel, "Back");
    SetPanelCurrentKey(panel, 9);
    DrawPanelItem(panel, "Exit");
    SendPanelToClient(panel, client, VipActivationMenuHandler, 20);
}

public VipActivationMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if(action == MenuAction_Select) {
        new client = param1;
        switch(param2) {
            case 8:{DisplayVipMenu(client);}
        }
    }
}

DisplayVipInfoMenu(const client)
{
    new Handle:panel = CreatePanel();
    SetPanelTitle(panel, "VIP Výhody");
    DrawPanelItem(panel, "AutoBhop.", ITEMDRAW_DISABLED);
    //DrawPanelItem(panel, "Teleport, ktorý môžeš použiť každé 3 minúty.", ITEMDRAW_DISABLED);
    DrawPanelItem(panel, "Zrýchlenie, každé kolo na 5 sec.", ITEMDRAW_DISABLED);
    DrawPanelItem(panel, "Buymenu na začiatku každého kola.", ITEMDRAW_DISABLED);
    DrawPanelItem(panel, "Možný nákup autosniperky a AWP.", ITEMDRAW_DISABLED);
    DrawPanelItem(panel, "Indikátor poškodenia.", ITEMDRAW_DISABLED);
    DrawPanelItem(panel, "Každé druhé body do ELO sa ti zdvojnásobia.", ITEMDRAW_DISABLED);
    DrawPanelItem(panel, BLANK, ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
    DrawPanelText(panel, "Cena VIP pre SK je 3,20€, pre CZ 79kč");
    DrawPanelItem(panel, BLANK, ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
    SetPanelCurrentKey(panel, 8);
    DrawPanelItem(panel, "Back");
    SetPanelCurrentKey(panel, 9);
    DrawPanelItem(panel, "Exit");
    SendPanelToClient(panel, client, VipInfoMenuHandler, 20);
}

public VipInfoMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if(action == MenuAction_Select) {
        new client = param1;
        switch(param2) {
            case 8:{DisplayVipMenu(client);}
        }
    }
}

DisplayVipSettingsMenu(const client)
{
    new Handle:panel = CreatePanel();
    decl String:item[32];
    SetPanelTitle(panel, "VIP Nastavenia");
    if(g_VIPCookie[client][SHOWDMG]) {
        Format(item, sizeof(item), "Indikátor zásahov [ZAPNUTÉ]");
    } else {
        Format(item, sizeof(item), "Indikátor zásahov [VYPNUTÉ]");
    }
    DrawPanelItem(panel, item);
    if(g_VIPCookie[client][AUTOBHOP]) {
        Format(item, sizeof(item), "AutoBhop [ZAPNUTÉ]");
    } else {
        Format(item, sizeof(item), "AutoBhop [VYPNUTÉ]");
    }
    DrawPanelItem(panel, item);
    if(g_VIPCookie[client][BUYMENU]) {
        Format(item, sizeof(item), "BuyMenu [ZAPNUTÉ]");
    } else {
        Format(item, sizeof(item), "BuyMenu [VYPNUTÉ]");
    }
    DrawPanelItem(panel, item);
    DrawPanelItem(panel, BLANK, ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
    SetPanelCurrentKey(panel, 8);
    DrawPanelItem(panel, "Back");
    SetPanelCurrentKey(panel, 9);
    DrawPanelItem(panel, "Exit");
    SendPanelToClient(panel, client, VipSettingsMenuHandler, 20);
}

public VipSettingsMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if(action == MenuAction_Select) {
        new client = param1;
        switch(param2) {
            case 1:
            {
                ToggleVipCookie(client, SHOWDMG);
                DisplayVipSettingsMenu(client);
            }
            case 2:
            {
                ToggleVipCookie(client, AUTOBHOP);
                DisplayVipSettingsMenu(client);
            }
            case 3:
            {
                ToggleVipCookie(client, BUYMENU);
                DisplayVipSettingsMenu(client);
            }
            case 8: {DisplayVipMenu(client);}
        }
    }
}

DisplayVipHelpMenu(const client)
{
    new Handle:panel = CreatePanel();
    SetPanelTitle(panel, "VIP Help");
    //DrawPanelItem(panel, "Teleport: Použiť sa dá každé 3 sekundy. Musí sa nabindovať na klávesu \n- príkaz sm_blink (bind v sm_blink)", ITEMDRAW_DISABLED);
    DrawPanelItem(panel, "Zrýchlenie: Použiť sa v každom kole na 5 sekundy. Musí sa nabindovať na klávesu \n- príkaz sm_speed (bind v sm_speed)", ITEMDRAW_DISABLED);
    DrawPanelItem(panel, BLANK, ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
    SetPanelCurrentKey(panel, 8);
    DrawPanelItem(panel, "Back");
    SetPanelCurrentKey(panel, 9);
    DrawPanelItem(panel, "Exit");
    SendPanelToClient(panel, client, VipHelpMenuHandler, 30);
}

public VipHelpMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if(action == MenuAction_Select) {
        new client = param1;
        switch(param2) {
            case 8: {DisplayVipMenu(client);}
        }
    }
}

DisplayVipsMenu(const client)
{
    if(g_VipsMenu != INVALID_HANDLE)
        SendPanelToClient(g_VipsMenu, client, VipsMenuHandler, 20);
    else {
        PluginMessageToClient(client, "Nie je k dispozícii.");
        IronLog(false, "VipsPanel not loaded");
    }
}

public VipsMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if(action == MenuAction_Select) {
        new client = param1;
        switch(param2) {
            case 8: {DisplayVipMenu(client);}
        }
    }
}

LoadVips()
{
    SQL_TQuery(DB, LoadVipsDBCallback, "SELECT name FROM players WHERE vip=1");
}

public LoadVipsDBCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if(hndl == INVALID_HANDLE) {
        IronLog(false, "Query failed: %s", error);
        return;
    }

    decl String:name[64];
    if(g_VipsMenu != INVALID_HANDLE)
        CloseHandle(g_VipsMenu);

    g_VipsMenu = CreatePanel();
    SetPanelTitle(g_VipsMenu, "Zoznam VIP hráčov");
    if (SQL_GetRowCount(hndl) < 1) {
        DrawPanelText(g_VipsMenu, "Zatiaľ neboli registrovaní žiadny VIP hráči.");
    } else {
        while(SQL_FetchRow(hndl)) {
            SQL_FetchString(hndl, 0, name, sizeof(name));
            DrawPanelItem(g_VipsMenu, name, ITEMDRAW_DISABLED);
        }
    }

    SetPanelCurrentKey(g_VipsMenu, 8);
    DrawPanelItem(g_VipsMenu, "Back");
    SetPanelCurrentKey(g_VipsMenu, 9);
    DrawPanelItem(g_VipsMenu, "Exit");
}

public VipToggle(const target, const client)
{
    if(!IsValidClient(target)) {
        return;
    }

    decl String:DBQuery[256], String:nametarget[64], String:name[64];
    GetClientName(client, name, sizeof(name));
    GetClientName(target, nametarget, sizeof(nametarget));

    if(HasPlayerVip(target)) {
        Format(DBQuery, sizeof(DBQuery), "UPDATE players SET vip=0 WHERE id=%d", g_PlayerId[target]);
        UnsetPlayerVip(target);
        PluginMessageToClient(target, "{RED}VIP {NORMAL}ti bolo odobraté!");
        IronLog(true, "Admin %s odobral VIP hráčovi %s", name, nametarget);
    } else {
        Format(DBQuery, sizeof(DBQuery), "UPDATE players SET vip=1 WHERE id=%d", g_PlayerId[target]);
        SetPlayerVip(target);
        PluginMessageToClient(target, "{RED}VIP {NORMAL}ti bolo aktivované!");
        IronLog(true, "Admin %s aktivoval VIP hráčovi %s", name, nametarget);
    }

    LoadVips();

    SQL_TQuery(DB, SQLErrorCheckCallback, DBQuery);
}

public Action:Command_VipAdd(args)
{
    if (args < 1) {
        PrintToServer("[SM] Usage: sm_VipAdd <dbid>");
        return Plugin_Handled;
    }

    decl String:Argument[8], String:DBQuery[256], String:name[64];
    GetCmdArg(1, Argument, sizeof(Argument));
    new id = StringToInt(Argument);

    if(id > 0) {
        Format(DBQuery, sizeof(DBQuery), "UPDATE players SET vip=1 WHERE id=%d", id);
        SQL_TQuery(DB, SQLErrorCheckCallback, DBQuery);
        for(new i = 1; i <= MaxClients; i++) {
            if(IsValidClient(i) && g_PlayerId[i] == id) {
                SetPlayerVip(i);
                GetClientName(i, name, sizeof(name));
                PluginMessageToClient(i, "{RED}VIP ti{NORMAL}bolo aktivované!");
                PluginMessage("Hráč {GREEN}%s {NORMAL}si práve aktivoval {RED}VIP{NORMAL}!", name);
                IronLog(true, "Hráč %s aktivoval VIP!", name);
                LoadVips();
                break;
            } else continue;
        }
    } else {
        PrintToServer("[SM] Bad argument <dbid>");
        IronLog(false, "Bad vip argument (%d)", id);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    new index = GetEntProp(client, Prop_Data, "m_nWaterLevel");
    new water = EntIndexToEntRef(index);
    if (water != INVALID_ENT_REFERENCE) {
        if (IsPlayerAlive(client)) {
            if (buttons & IN_JUMP) {
                if (!(Client_GetWaterLevel(client) > 1)) {
                    if (!(GetEntityMoveType(client) & MOVETYPE_LADDER)) {
                        SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
                        if (!(GetEntityFlags(client) & FL_ONGROUND)) {
                            if(HasPlayerVipAdv(client, AUTOBHOP) && g_VIPCookie[client][AUTOBHOP]) {
                                buttons &= ~IN_JUMP;
                            }
                        }
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}

stock Client_GetWaterLevel(client) {
  return GetEntProp(client, Prop_Send, "m_nWaterLevel");
}

public Action:OnWeaponCanUse(client, weapon)
{
    if(!IsValidClient(client))
        return Plugin_Continue;

    if (HasPlayerVipAdv(client, WEAPONS))
        return Plugin_Continue;

    new WeaponID:idweapon = GetWeaponIDFromEnt(weapon);

    if (idweapon == WEAPON_G3SG1 || idweapon == WEAPON_SCAR20) {
        if(!g_antipickspam[client]) {
            PluginMessageToClient(client, "Táto zbraň je určená iba pre VIP hráčoch");
            g_antipickspam[client] = true;
        }
        return Plugin_Handled;
    }

    if (idweapon == WEAPON_AWP) {
        new awpsT = 0;
        new awpsCT = 0;

        for(new i = 1; i <= MaxClients; i++) {
            if(!IsValidClient(i))
                continue;

            if(GetClientTeam(i) == 2) {
                new ent = GetPlayerWeaponSlot(i, 0);
                if(GetWeaponIDFromEnt(ent) == WEAPON_AWP)
                    awpsT++;
            } else if(GetClientTeam(i) == 3) {
                new ent = GetPlayerWeaponSlot(i, 0);
                if(GetWeaponIDFromEnt(ent) == WEAPON_AWP)
                    awpsCT++;
            }
        }

        if (GetClientTeam(client) == 2 && awpsT >= 1) {
            if(!g_antipickspam[client]) {
                PluginMessageToClient(client, "Počet AWP v týme pre non-VIP hráčov je obmedzený.");
                g_antipickspam[client] = true;
            }
            return Plugin_Handled;
        } else if (GetClientTeam(client) == 3 && awpsCT >= 1) {
            if(!g_antipickspam[client]) {
                PluginMessageToClient(client, "Počet AWP v týme pre non-VIP hráčov je obmedzený.");
                g_antipickspam[client] = true;
            }
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public Action:CS_OnBuyCommand(client, const String:weapon[])
{
    if(!IsValidClient(client)) {
        return Plugin_Continue;
    }

    if (HasPlayerVipAdv(client, WEAPONS)) {
        return Plugin_Continue;
    }
    
    new WeaponID:idweapon = GetWeaponID(weapon);

    if (idweapon == WEAPON_G3SG1 || idweapon == WEAPON_SCAR20) {
        if(!g_antibuyspam[client]) {
            PluginMessageToClient(client, "Táto zbraň je určená iba pre VIP hráčoch");
            g_antibuyspam[client] = true;
        }
        return Plugin_Handled;
    }   

    if (idweapon == WEAPON_AWP) {
        new awpsT = 0;
        new awpsCT = 0;

        for(new i = 1; i <= MaxClients; i++) {
            if(!IsValidClient(i)) {
                continue;
            }

            if(GetClientTeam(i) == 2) {
                new ent = GetPlayerWeaponSlot(i, 0);
                if(GetWeaponIDFromEnt(ent) == WEAPON_AWP)
                    awpsT++;
            } else if(GetClientTeam(i) == 3) {
                new ent = GetPlayerWeaponSlot(i, 0);
                if(GetWeaponIDFromEnt(ent) == WEAPON_AWP)
                    awpsCT++;
            }
        }

        if (GetClientTeam(client) == 2 && awpsT >= 1) {
            if(!g_antibuyspam[client]) {
                PluginMessageToClient(client, "Počet AWP v týme pre non-VIP hráčov je obmedzený.");
                g_antibuyspam[client] = true;
            }
            return Plugin_Handled;
        } else if (GetClientTeam(client) == 3 && awpsCT >= 1) {
            if(!g_antibuyspam[client]) {
                PluginMessageToClient(client, "Počet AWP v týme pre non-VIP hráčov je obmedzený.");
                g_antibuyspam[client] = true;
            }
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public CheckWeaponArrays()
{
    if(hWeaponsIDArray == INVALID_HANDLE) {
        hWeaponsIDArray = CreateArray();
    } else {
        ClearArray(hWeaponsIDArray);
    }
    if(hWeaponEntityArray == INVALID_HANDLE)
        hWeaponEntityArray = CreateArray();
    else
        ClearArray(hWeaponEntityArray);
    
    decl String:name[64];
    for (new i = MaxClients; i <= GetMaxEntities(); i++)
    {
        if (IsValidEdict(i) && IsValidEntity(i))
        {
            GetEdictClassname(i, name, sizeof(name));
            if((strncmp(name, "weapon_", 7, false) == 0 || strncmp(name, "item_", 5, false) == 0))
            {   
                new WeaponID:id = GetWeaponID(name);
                new index = FindValueInArray(hWeaponEntityArray, i);
                if(id != WEAPON_NONE && index == -1)
                {
                    PushArrayCell(hWeaponsIDArray, _:id);
                    PushArrayCell(hWeaponEntityArray, i); 
                }
            }
        }
    }
}

stock WeaponID:GetWeaponIDFromEnt(entity)
{
    if(!IsValidEdict(entity))
        return WEAPON_NONE;
    
    new index = FindValueInArray(hWeaponEntityArray, entity);
    if(index != -1)
        return GetArrayCell(hWeaponsIDArray, index);
    //Just incase code
    new String:classname[64];
    GetEdictClassname(entity, classname, sizeof(classname));
    if(StrContains(classname, "weapon_", false) != -1 || StrContains(classname, "item_", false) != -1) {
        new WeaponID:id = GetWeaponID(classname);
        
        if(id == WEAPON_NONE)
            return WEAPON_NONE;
        
        PushArrayCell(hWeaponsIDArray, _:id);
        PushArrayCell(hWeaponEntityArray, entity);
        
        return id;
    }
    
    return WEAPON_NONE;
}

public OnEntityCreated(entity, const String:classname[])
{
    if(hWeaponsIDArray == INVALID_HANDLE || hWeaponEntityArray == INVALID_HANDLE)
        return;
    
    if(StrContains(classname, "weapon_", false) != -1 || StrContains(classname, "item_", false) != -1) {
        new WeaponID:id = GetWeaponID(classname);
        
        if(id == WEAPON_NONE || FindValueInArray(hWeaponEntityArray, entity) != -1)
            return;
        
        PushArrayCell(hWeaponsIDArray, _:id);
        PushArrayCell(hWeaponEntityArray, entity); 
    }
}

public OnEntityDestroyed(entity)
{
    if(hWeaponsIDArray == INVALID_HANDLE || hWeaponEntityArray == INVALID_HANDLE)
        return;
    
    new index = FindValueInArray(hWeaponEntityArray, entity);
    if(index != -1) {
        RemoveFromArray(hWeaponEntityArray, index);
        RemoveFromArray(hWeaponsIDArray, index);
    }
}

CalcDamage(client, client_attacker, damage)
{
    if (!HasPlayerVipAdv(client_attacker, SHOWDMG) || !IsValidClient(client_attacker) || damage <= 0 || !g_VIPCookie[client_attacker][SHOWDMG])
        return;
    
    player_damage[client_attacker][client] += damage;

    PrintCenterText(client_attacker, "-%d", player_damage[client_attacker][client]);
}

/*public Action:Command_Teleport(client, args) {
    if(g_vip[client]) {
        TeleportPlayer(client);
    }
}*/

public Action:Command_Speed(client, args)
{
    if(HasPlayerVipAdv(client, SPEED)) {
        if(!g_boostToggle[client] && g_boost[client] > 0) {
            BoostPlayerOn(client, 1.6);
        } else if(g_boost[client] > 0) {
            BoostPlayerOff(client);
        }
    }
}

public Action:Command_MegaSpeed(client, args)
{
    if(!g_boostToggle[client] && g_boost[client] > 0) {
        BoostPlayerOn(client, 6.0);
    } else if(g_boost[client] > 0) {
        BoostPlayerOff(client);
    }
}

BoostPlayerOn(const client, Float:value)
{
    if(IsValidClient(client)) {
        g_boostToggle[client] = true;
        SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", value);
        PluginMessageToClient(client, "Boost{GREEN}ON");
        CreateTimer(0.1, Timer_Boost, GetClientSerial(client));
    }
}

BoostPlayerOff(const client)
{
    if(IsValidClient(client)) {
        g_boostToggle[client] = false;
        SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
        PluginMessageToClient(client, "Boost{RED}OFF");
    }
}

public Action:Timer_Boost(Handle:timer, any:serial)
{
    new client = GetClientFromSerial(serial);
    if(IsValidClient(client)) {
        if(HasPlayerVipAdv(client, SPEED) && g_boostToggle[client] && g_boost[client] > 0) {
            new String:steamid[32];
            GetClientAuthId(client, AuthId_Steam3, steamid, sizeof(steamid));
            if (!StrEqual(steamid, "STEAM_1:1:2168209", false)) {
                g_boost[client] -= 0.1;
                CreateTimer(0.1, Timer_Boost, GetClientSerial(client));
            }
        } else {
            BoostPlayerOff(client);
        }
    }
}

bool:LoadVipBuyConfig()
{
    new Handle:kv = CreateKeyValues("Weapons");

    if (!FileToKeyValues(kv, g_VipWeaponNamesPath))
        return false;

    if (g_VipPrimaryWeaponMenu != INVALID_HANDLE)
        CloseHandle(g_VipPrimaryWeaponMenu);

    g_VipPrimaryWeaponMenu = CreateMenu(Menu_PrimaryHandler, MenuAction_DrawItem|MenuAction_Display);
    SetMenuTitle(g_VipPrimaryWeaponMenu, "Vyber si primárnu zbraň:");

    if (g_VipSecondaryWeaponMenu != INVALID_HANDLE)
        CloseHandle(g_VipSecondaryWeaponMenu);

    g_VipSecondaryWeaponMenu = CreateMenu(Menu_SecondaryHandler, MenuAction_DrawItem|MenuAction_Display);
    SetMenuTitle(g_VipSecondaryWeaponMenu, "Vyber si sekundárnu zbraň:");
    
    decl String:name[64], String:menuname[64], String:slot[16];

    if (!KvGotoFirstSubKey(kv, false))
        return false;

    do {
        KvGetSectionName(kv, name, sizeof(name));
        KvGetString(kv, "name", menuname, sizeof(menuname));
        KvGetString(kv, "type", slot, sizeof(slot));
        if(StrEqual(slot, "primary", false)) {
            AddMenuItem(g_VipPrimaryWeaponMenu, name, menuname);
        } else if(StrEqual(slot, "secondary", false)) {
            AddMenuItem(g_VipSecondaryWeaponMenu, name, menuname);
        }
    } while (KvGotoNextKey(kv));
    
    CloseHandle(kv);
    
    return true;
}

public Menu_PrimaryHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_DrawItem)
        return ITEMDRAW_DEFAULT;

    else if (action == MenuAction_Select) {
        decl String:gun[32];
        GetMenuItem(menu, param2, gun, sizeof(gun));
        GiveWeapon(param1, gun);
    }
    else if (action == MenuAction_Display) {
        new Handle:hPanel = Handle:param2;
        decl String:title[128];
        Format(title, sizeof(title), "Primárne zbrane:");
        SetPanelTitle(hPanel, title);
    }
    return 0;
}

public Menu_SecondaryHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_DrawItem)
        return ITEMDRAW_DEFAULT;

    else if (action == MenuAction_Select) {
        decl String:gun[32];
        GetMenuItem(menu, param2, gun, sizeof(gun));
        GiveWeapon(param1, gun);
        DisplayMenu(g_VipPrimaryWeaponMenu, param1, MENU_TIME_FOREVER);
    }
    else if (action == MenuAction_Cancel && param2 == MenuCancel_Exit) {
        DisplayMenu(g_VipPrimaryWeaponMenu, param1, MENU_TIME_FOREVER);
    }
    else if (action == MenuAction_Display) {
        new Handle:hPanel = Handle:param2;
        decl String:title[128];
        Format(title, sizeof(title), "Sekundárne zbrane:");
        SetPanelTitle(hPanel, title);
    }
    return 0;
}

GiveWeapon(client, String:name[])
{
    if (!IsPlayerAlive(client))
        return;

    new String:cls[64], ent;

    if(GetWeaponSlot(name) == SlotPrimmary)
        ent = GetPlayerWeaponSlot(client, 0);
    else if(GetWeaponSlot(name) == SlotPistol)
        ent = GetPlayerWeaponSlot(client, 1);

    if(GetWeaponIDFromEnt(ent) != WEAPON_NONE)
        CS_DropWeapon(client, ent, false);
    
    Format(cls, sizeof(cls), "weapon_%s", name);
    GivePlayerItem(client, cls);
}

/*TeleportPlayer(const client) {
    if (!IsValidClient(client))
        return;

    if(!g_canPlayerTeleport[client]) {
        if(!g_antitelspam[client]) {
            PluginMessageToClient(client, "Teleport bude pripravený za {RED}%d {NORMAL}sec.", g_teleCounter[client]);
            g_antitelspam[client] = true;
        }
    } else {
        //Declare:
        decl Float:PlayerOrigin[3], Float:TeleportOrigin[3];

        //Initialize:
        if(GetTeleportEndpoint(client, PlayerOrigin)) {
        
            //Math
            TeleportOrigin[0] = PlayerOrigin[0];
            TeleportOrigin[1] = PlayerOrigin[1];
            TeleportOrigin[2] = (PlayerOrigin[2] + 4);
            
            //Teleport
            TeleportEntity(client, TeleportOrigin, NULL_VECTOR, NULL_VECTOR);
            CreateTimer(2.0, Timer_PlayerCanTeleport, GetClientSerial(client));
            g_teleCounter[client] = 180;
            g_canPlayerTeleport[client] = false;
            g_antitelspam[client] = false;
        } else {
            PrintCenterText(client, "Bad location");
        }
    }
}

public Action:Timer_PlayerCanTeleport(Handle:timer, any:serial) {
    new client = GetClientFromSerial(serial);
    if(IsValidClient(client)) {
        g_teleCounter[client] -= 2;
        if(g_teleCounter[client] == 0) {
            g_canPlayerTeleport[client] = true;
            PluginMessageToClient(client, "Teleport je pripravený!");
        } else {
            CreateTimer(2.0, Timer_PlayerCanTeleport, GetClientSerial(client));
        }
    }
}*/


/*stock bool:GetCollisionPoint(client, Float:pos[3], bool:eyes=true)
{
    decl Float:vOrigin[3], Float:vAngles[3], Float:vBackwards[3];
    new bool:failed = false;
    new loopLimit = 100;    // only check 100 times, as a precaution against runaway loops

    if (eyes)
    {
        GetClientEyePosition(client, vOrigin);
    }
    else
    {
        // if eyes is false, fall back to the AbsOrigin ( = feet)
        GetClientAbsOrigin(client, vOrigin);
    }
    
    GetClientEyeAngles(client, vAngles);
    GetAngleVectors(vAngles, vBackwards, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(vBackwards, vBackwards);
    ScaleVector(vBackwards, 10.0);    // TODO: percentage of distance from endpoint to eyes instead of fixed distance?
    
    new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
        
    if (TR_DidHit(trace))
    {    
        TR_GetEndPosition(pos, trace);
        //PrintToChat(client, "endpos %f %f %f", pos[0], pos[1], pos[2]);
        
        while (IsPlayerStuck(pos, client) && !failed)    // iteratively check if they would become stuck
        {
            SubtractVectors(pos, vBackwards, pos);        // if they would, subtract backwards from the position
            //PrintToChat(client, "endpos %f %f %f", pos[0], pos[1], pos[2]);
            if (GetVectorDistance(pos, vOrigin) < 10 || loopLimit-- < 1)
            {
                
                failed = true;    // If we get all the way back to the origin without colliding, we have failed
                //PrintToChat(client, "failed to find endpos");
                pos = vOrigin;    // Use the client position as a fallback
            }
        }
    }
    
    CloseHandle(trace);
    return !failed;        // If we have not failed, return true to let the caller know pos has teleport coordinates
}*/

/*#define BOUNDINGBOX_INFLATION_OFFSET 3

// Checks to see if a player would collide with MASK_SOLID (i.e. they would be stuck)
// Inflates player mins/maxs a little bit for better protection against sticking
// Thanks to andersso for the basis of this function
stock bool:IsPlayerStuck(Float:pos[3], client) {
    new Float:mins[3];
    new Float:maxs[3];

    GetClientMins(client, mins);
    GetClientMaxs(client, maxs);
    
    // inflate the sizes just a little bit
    for (new i=0; i<sizeof(mins); i++) {
        mins[i] -= BOUNDINGBOX_INFLATION_OFFSET;
        maxs[i] += BOUNDINGBOX_INFLATION_OFFSET;
    }

    TR_TraceHullFilter(pos, pos, mins, maxs, MASK_SOLID, TraceEntityFilterPlayer, client);

    return TR_DidHit();
}

public bool:TraceEntityFilterPlayer(entity, contentsMask) {
    return entity <= 0 || entity > MaxClients;
}

stock bool:GetTeleportEndpoint(client, Float:pos[3], bool:findFloor=true) {
    decl Float:vOrigin[3], Float:vAngles[3], Float:vBackwards[3], Float:vUp[3];
    new bool:failed = false;
    new loopLimit = 100;    // only check 100 times, as a precaution against runaway loops
    new Float:downAngles[3];
    new Handle:traceDown;
    new Float:floor[3];

    GetClientAbsOrigin(client, floor);
    GetClientEyePosition(client, vOrigin);

    downAngles[0] = 90.0;    //thats right you'd think its a z value - this will point you down
    GetAngleVectors(downAngles, vUp, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(vUp, vUp);
    ScaleVector(vUp, -3.0);    // TODO: percentage of distance from endpoint to eyes instead of fixed distance?

    GetClientEyeAngles(client, vAngles);
    GetAngleVectors(vAngles, vBackwards, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(vBackwards, vBackwards);
    ScaleVector(vBackwards, 10.0);    // TODO: percentage of distance from endpoint to eyes instead of fixed distance?
    
    new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
            
    if (TR_DidHit(trace)) {    
        new bool:first = true;
                
        while (first || (IsPlayerStuck(floor, client) && !failed))    // iteratively check if they would become stuck
        {
            if (first) {
                TR_GetEndPosition(pos, trace);
                first = false;
            }
            else {
                SubtractVectors(pos, vBackwards, pos);        // if they would, subtract backwards from the position
            }
            //PrintToChat(client, "endpos %f %f %f", pos[0], pos[1], pos[2]);
            
            if(findFloor) {
                traceDown = TR_TraceRayFilterEx(pos, downAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
                new bool:hit = TR_DidHit(traceDown);
                if (hit) {
                    TR_GetEndPosition(floor, traceDown);
                    new j = 10;
                    while (j > 0 && IsPlayerStuck(floor, client)) {
                        AddVectors(floor, vUp, floor);    // lift off the floor a hair
                        j--;
                    }
                }
                    
                CloseHandle(traceDown);
                
                if (!hit) continue;    // If there is no floor, continue searching
            }
            else {
                floor = pos;
            }
            //PrintToChat(client, "floorpos %f %f %f", floor[0], floor[1], floor[2]);
            
            if (GetVectorDistance(pos, vOrigin) < 10 || loopLimit-- < 1) {
                
                failed = true;    // If we get all the way back to the origin without colliding, we have failed
                //PrintToChat(client, "failed to find endpos");
                GetClientAbsOrigin(client, floor);
            }
        }
    }
    
    pos = floor;
    
    CloseHandle(trace);
    return !failed;        // If we have not failed, return true to let the caller know pos has teleport coordinates
}*/

/*public Action:DecoyPorte(Handle:event,String:name[], bool:dontBroadcast)
{
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        new Float:Tel[3];
        GetClientAbsOrigin(client, Tel);      
        Tel[0] = GetEventFloat(event, "x");
        Tel[1] = GetEventFloat(event, "y");
        Tel[2] = GetEventFloat(event, "z") + 10;
        if (!IsFakeClient(client) && HasPlayerVipAdv(client, WEAPONS))
        {
            TeleportEntity(client, Tel, NULL_VECTOR, NULL_VECTOR);
        }
        //SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 0);
}*/