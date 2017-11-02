/**
 * Executes a config file named by a convar.
 */
public ExecCfg(const String:msg[]) {
    ServerCommand("exec %s", msg);
}

/**
 * Adds an integer to a menu as a string choice.
 */
stock AddMenuInt(Handle:menu, any:value, String:display[], style=ITEMDRAW_DEFAULT) {
    decl String:buffer[8];
    IntToString(value, buffer, sizeof(buffer));
    AddMenuItem(menu, buffer, display, style);
}

/**
 * Adds an integer to a menu, named by the integer itself.
 */
public AddMenuInt2(Handle:menu, any:value) {
    decl String:buffer[8];
    IntToString(value, buffer, sizeof(buffer));
    AddMenuItem(menu, buffer, buffer);
}

/**
 * Gets an integer to a menu from a string choice.
 */
public GetMenuInt(Handle:menu, any:param2) {
    decl String:choice[8];
    GetMenuItem(menu, param2, choice, sizeof(choice));
    return StringToInt(choice);
}

/**
 * Adds a boolean to a menu as a string choice.
 */
stock AddMenuBool(Handle:menu, bool:value, String:display[], style=ITEMDRAW_DEFAULT) {
    new convertedInt = value ? 1 : 0;
    AddMenuInt(menu, convertedInt, display, style);
}

/**
 * Gets a boolean to a menu from a string choice.
 */
public bool:GetMenuBool(Handle:menu, any:param2) {
    return GetMenuInt(menu, param2) != 0;
}

/**
 * Returns the number of human clients on a team.
 */
public GetNumHumansOnTeam(team) {
    new count = 0;
    for (new i = 1; i <= MaxClients; i++) {
        if (!IsFakeClient(i) && GetClientTeam(i) == team)
            count++;
    }
    return count;
}

/**
 * Returns a random player client on the server.
 */
public RandomPlayer() {
    new client = -1;
    while (!IsValidClient(client) || IsFakeClient(client)) {
        if (GetRealClientCount() < 1)
            return -1;

        client = GetRandomInt(1, MaxClients);
    }
    return client;
}

public RandomizeTeams() {
    new shuffled[MAXPLAYERS+1] = false;
    new client = -1;
    new numbers[2] = {2, 3};
    new i = 1;
    new count = 0;
    
    do {
        client = RandomPlayer();
        if (!shuffled[client]) {
            SwitchPlayerTeam(client, numbers[i % 2]);
            shuffled[client] = true;
            i++;
            count++;
        }
    } while (count < GetRealClientCount());
    
}
/**
 * Switches and respawns a player onto a new team.
 */
public SwitchPlayerTeam(client, team) {
    if (team > CS_TEAM_SPECTATOR) {
        CS_SwitchTeam(client, team);
        CS_UpdateClientModel(client);
        CS_RespawnPlayer(client);
    } else {
        ChangeClientTeam(client, team);
    }
}

/**
 * Returns if a client is valid.
 */
public bool:IsValidClient(client) {
    if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
        return true;
    return false;
}

/**
 * Returns the number of clients that are actual players in the game.
 */
public GetRealClientCount() {
    new clients = 0;
    for (new i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && !IsFakeClient(i))
            clients++;
    }
    return clients;
}

/**
 * Returns a random index from an array.
 */
public any:GetArrayRandomIndex(Handle:array) {
    new len = GetArraySize(array);
    if (len == 0)
        ThrowError("Can't get random index from empty array");
    return GetRandomInt(0, len - 1);
}

/**
 * Returns a random element from an array.
 */
public any:GetArrayCellRandom(Handle:array) {
    return GetArrayCell(array, GetArrayRandomIndex(array));
}

public PluginMessageToClient(client, const String:msg[], any:...) {
    new String:formattedMsg[1024] = MESSAGE_PREFIX;
    decl String:tmp[1024];
    VFormat(tmp, sizeof(tmp), msg, 3);
    StrCat(formattedMsg, sizeof(formattedMsg), tmp);
    CPrintToChat(client, formattedMsg);
}

public PluginMessage(const String:msg[], any:...) {
    new String:formattedMsg[1024] = MESSAGE_PREFIX;
    decl String:tmp[1024];
    VFormat(tmp, sizeof(tmp), msg, 2);
    StrCat(formattedMsg, sizeof(formattedMsg), tmp);
    CPrintToChatAll(formattedMsg);
}

public Action:Timer_PluginMessage(Handle:timer, Handle:Timer_msg) {
    decl String:msg[256];
    ResetPack(Timer_msg);
    ReadPackString(Timer_msg, msg, sizeof(msg));
    PluginMessage(msg);
}

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data) {
    if(!StrEqual("", error))
        IronLog(false, "Query failed: %s", error);
}

public CheckPlayerID(client) {
    new String:steamid[32], String:DBQuery[256];
    GetClientAuthId(client, AuthId_Steam3, steamid, sizeof(steamid));
    Format(DBQuery, sizeof(DBQuery), "SELECT id FROM players WHERE steamid='%s'", steamid);
    SQL_TQuery(DB, CheckPlayerIDCallback, DBQuery, GetClientUserId(client));
}

public CheckPlayerIDCallback(Handle:owner, Handle:hndl, const String:error[], any:data) {
    new client;
    if((client = GetClientOfUserId(data)) == 0)
        return;

    if(hndl == INVALID_HANDLE) {
        IronLog(false, "Query failed: %s", error);
        return;
    }
    if(!SQL_GetRowCount(hndl)) {
        IronLog(false, "No player id found");
        return;
    }

    SQL_FetchRow(hndl);
    g_PlayerId[client] = SQL_FetchInt(hndl, 0);
}

public min(a, b)
{
    return a < b ? a : b;
}

PrintCommands(client)
{
    PluginMessageToClient(client, "{NORMAL}Užitočné príkazy do chatu: {BLUE}/rank{NORMAL}, {BLUE}/vip{NORMAL}, {BLUE}/vips{NORMAL}, {BLUE}/ts{NORMAL}, {BLUE}/session{NORMAL}, {BLUE}/top10{NORMAL}, {BLUE}/elo_notify{NORMAL}, {BLUE}/music");
}

PrintTs(client)
{
    PluginMessageToClient(client, "{NORMAL}Príď si pokecať aj na náš TeamSpeak server\n IP: {BLUE}195.62.17.205");
}

public getPlayerId(client) {
    return g_PlayerId[client];
}

IronLog(bool:useDebug, String:fmt[], any:...)
{
    decl String:format[1024];
    decl String:file[PLATFORM_MAX_PATH + 1];
    decl String:CurrentDate[32];

    // Build Path to the needed folders
    BuildPath(Path_SM, file, sizeof(file), "logs");

    VFormat(format, sizeof(format), fmt, 3);
    FormatTime(CurrentDate, sizeof(CurrentDate), "%d-%m-%y");

    if (useDebug) {
        Format(file, sizeof(file), "%s/IronDebugs_(%s).log", file, CurrentDate);
        LogToFile(file, "[ IRON DEBUG ] %s", format);

        return;
    }

    Format(file, sizeof(file), "%s/IronErrors_(%s).log", file, CurrentDate);
    LogToFile(file, "[ IRON ] %s", format);
}