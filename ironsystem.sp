#include <sourcemod>
#include <csgocolors>
#include <cstrike>
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>
#include <adminmenu>
#include <cstrike_weapons>
//#include <dhooks>
#include <emitsoundany>

#define MESSAGE_PREFIX "[{DARKBLUE}fGaming{NORMAL}] "
#pragma semicolon 1

#define PLUGIN_VERSION "1.1.52"
#define PLUGIN_NAME "fGaming"

public Plugin:myinfo =
{
    name = PLUGIN_NAME,
    author = "C0mp4ct",
    description = "fGaming",
    version = PLUGIN_VERSION
}

// Variables for Database
new Handle:DB = INVALID_HANDLE;
new g_PlayerId[MAXPLAYERS+1];

new Handle:kvAdmins;

// Cookies
new Handle:g_cookieAutoBhop;
new Handle:g_cookieMusic;
new Handle:g_cookieDmg;
new Handle:g_cookieBuyMenu;
//new Handle:g_hHideRestricted = INVALID_HANDLE;

// Admin Spectate
//new Handle:hIsValidTarget;
new Handle:mp_forcecamera;
new Handle:mp_autokick;
//new bool:g_bCheckNullPtr = false;

// Music
new Handle:g_hPlayType = INVALID_HANDLE;
new bool:g_PlayMusic[MAXPLAYERS+1];

// Chat antispam
new bool:g_GlobalAntispam[MAXPLAYERS+1];

// Client spend time
new g_hours[MAXPLAYERS+1];
new g_minutes[MAXPLAYERS+1];
new g_seconds[MAXPLAYERS+1];

// BHOPPING
new VelocityOffset_0;
new VelocityOffset_1;
new BaseVelocityOffset;

new g_roundCounter;

new String:g_AdminsPath[PLATFORM_MAX_PATH];
new String:g_VipWeaponNamesPath[PLATFORM_MAX_PATH];
new Handle:hTopMenu = INVALID_HANDLE;

#include "ironsystem/generic.sp"
#include "ironsystem/vip.sp"
#include "ironsystem/adminmenu.sp"
#include "ironsystem/bans.sp"
#include "ironsystem/eloranking.sp"
#include "ironsystem/sounds.sp"
#include "ironsystem/events.sp"
#include "ironsystem/timers.sp"

//public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
//    MarkNativeAsOptional("DHookIsNullParam");
//    return APLRes_Success;
//}

public OnPluginStart()
{
    CreateConVar("sm_ironsystem_version", PLUGIN_VERSION, "IronSystem Version");

    g_hPlayType = CreateConVar("sm_ironsystem_playtype", "1", "1 - Random, 2- Play in queue", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);

    g_cookieMusic = RegClientCookie("g_PlayMusic", "", CookieAccess_Private);

    g_cookieAutoBhop = RegClientCookie("g_Autobhop", "", CookieAccess_Private);
    g_cookieDmg = RegClientCookie("g_showDmg", "", CookieAccess_Private);
    g_cookieBuyMenu = RegClientCookie("g_BuyMenu", "", CookieAccess_Private);

    BuildPath(Path_SM, g_BanReasonsPath, sizeof(g_BanReasonsPath), "configs/banreasons.txt");
    BuildPath(Path_SM, g_AdminsPath, sizeof(g_AdminsPath), "configs/admins.cfg");
    BuildPath(Path_SM, g_VipWeaponNamesPath, sizeof(g_VipWeaponNamesPath), "configs/ironsystem.weapons.txt");

    LoadTranslations("common.phrases");
    LoadTranslations("basebans.phrases");
    LoadTranslations("core.phrases");

    RegAdminCmd("sm_ban", Command_BanPlayer, ADMFLAG_BAN, "Ban player on the server");
    RegAdminCmd("sm_megaspeed", Command_MegaSpeed, ADMFLAG_BAN, "Give MegaSpeed");
    RegConsoleCmd("sm_elo", Command_show);
    //RegConsoleCmd("sm_blink", Command_Teleport);
    RegConsoleCmd("sm_speed", Command_Speed);
    RegServerCmd("sm_vipadd", Command_VipAdd);
    AddCommandListener(Command_Say, "say");
    AddCommandListener(Command_SayTeam, "say_team");
    AddCommandListener(Command_Callvote, "callvote");
    HookEvent("player_changename", Event_player_changename);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
    HookEvent("player_jump",Event_PlayerJump);
    HookEvent("round_mvp", Event_RoundMvp);
    HookEvent("server_cvar", Event_ServerCvar, EventHookMode_Pre);
    HookEvent("cs_win_panel_match", Event_MatchOver);

    LoadBanReasons();
    CheckWeaponArrays();

    new Handle:topmenu;
    if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
        OnAdminMenuReady(topmenu);

    //ADMIN SPECT
    mp_forcecamera = FindConVar("mp_forcecamera");
    mp_autokick = FindConVar("mp_autokick");
    //if(!mp_forcecamera)
    //    SetFailState("Failed to locate mp_forcecamera");
    //new Handle:temp = LoadGameConfigFile("allow-spec.games");
    //if(!temp)
    //    SetFailState("Failed to load allow-spec.games.txt");
    //new offset = GameConfGetOffset(temp, "IsValidObserverTarget");
    //hIsValidTarget = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, IsValidTarget);
    //DHookAddParam(hIsValidTarget, HookParamType_CBaseEntity);
    //CloseHandle(temp);
    //g_bCheckNullPtr = (GetFeatureStatus(FeatureType_Native, "DHookIsNullParam") == FeatureStatus_Available);

    //BHOPING
    VelocityOffset_0 = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
    if(VelocityOffset_0 == -1) {
        SetFailState("[BunnyHop] Error: Failed to find Velocity[0] offset, aborting");
    }

    VelocityOffset_1 = FindSendPropInfo("CBasePlayer", "m_vecVelocity[1]");
    if(VelocityOffset_1 == -1) {
        SetFailState("[BunnyHop] Error: Failed to find Velocity[1] offset, aborting");
    }

    BaseVelocityOffset = FindSendPropInfo("CBasePlayer", "m_vecBaseVelocity");
    if(BaseVelocityOffset == -1) {
        SetFailState("[BunnyHop] Error: Failed to find the BaseVelocity offset, aborting");
    }
    InitDB();
}

public OnMapStart()
{
    LoadMusic();
    CreateTimer(4.0, Timer_PostMapStart);
    g_PlayedSound = false;
}

public OnConfigsExecuted()
{
    if (!LoadVipBuyConfig())
        IronLog(false, "Nemožno načitať %s", g_VipWeaponNamesPath);
}

public OnClientPostAdminCheck(client)
{
    if (!IsValidClient(client)) {
        return;
    }

    if (AreClientCookiesCached(client)) {
        new String:value[16];

        GetClientCookie(client, g_cookieMusic, value, sizeof(value));
        if(strlen(value) > 0) {
            g_PlayMusic[client] = StringToInt(value) == 1;
        } else {
            g_PlayMusic[client] = true;
            SetClientCookie(client, g_cookieMusic, "1");
        }

        UnsetPlayerVip(client);
        //IronLog(true, "Checked and resetet %d", client);
        //g_canPlayerTeleport[client] = true;
    }

    if(DB != INVALID_HANDLE) {
        CheckClientInDB(client);
        CreateTimer(6.5, Timer_CheckClientBan, GetClientSerial(client));
    } else {
        IronLog(false, "Database failure on Authorize!");
    }

    CreateTimer(16.0, Timer_WelcomeMessage, GetClientSerial(client));
    CreateTimer(60.0, Timer_VipMessage, GetClientSerial(client));
    CreateTimer(4.0, Timer_ResetAntiSpams, GetClientSerial(client), TIMER_REPEAT);
    CreateTimer(20.0, Timer_TimeCounter, GetClientSerial(client), TIMER_REPEAT);

    if(CheckCommandAccess(client, "admin_allspec_flag", ADMFLAG_BAN)) {
        SendConVarValue(client, mp_forcecamera, "0");
        if(!SendConVarValue(client, mp_autokick, "0")) {
            IronLog(false, "Cant unset autokick");
        }
        ServerCommand("mp_disable_autokick %d", GetClientUserId(client));
    }
}

public OnClientDisconnect(client)
{
    if(!IsValidClient(client)) {
        return;
    }

    new String:steamid[32], String:datetime[32], String:DBQuery[256];
    new String:time[16], String:times[3][16], String:hours[16], String:minutes[16], String:seconds[16];
    IntToString(g_hours[client], hours, sizeof(hours));
    IntToString(g_minutes[client], minutes, sizeof(minutes));
    IntToString(g_seconds[client], seconds, sizeof(seconds));
    times[0] = hours;
    times[1] = minutes;
    times[2] = seconds;
    ImplodeStrings(times, 3, ":", time, sizeof(time));
    FormatTime(datetime, sizeof(datetime), "%Y-%m-%d %H:%M:%S", GetTime());
    GetClientAuthId(client, AuthId_Steam3, steamid, sizeof(steamid));
    Format(DBQuery, sizeof(DBQuery), "UPDATE players SET lastConnect='%s', spendedTime='%s' WHERE steamid='%s'", datetime, time, steamid);
    SQL_TQuery(DB, SQLErrorCheckCallback, DBQuery);
    UnsetPlayerVip(client);
}

InitDB() {
    decl String:error[256];
    if (SQL_CheckConfig("fGaming")) {
        SQL_TConnect(DBConnect, "fGaming");
    } else {
        SQL_TConnect(DBConnect, "storage-local");
    }

    if (DB == INVALID_HANDLE) {
        LogError("Could not connect to database: %s", error);
        return;
    }
    decl String:ident[16], bool:sqlite;
    SQL_ReadDriver(DB, ident, sizeof(ident));
    if (strcmp(ident, "mysql", false) == 0) {
        sqlite = false;
    } else if(strcmp(ident, "sqlite", false) == 0) {
        sqlite = true;
    } else {
        LogError("Invalid database.");
        return;
    }
    if (sqlite) {
        SQL_FastQuery(DB, "CREATE TABLE IF NOT EXISTS elostats (idPlayer INTEGER, rating INTEGER, kills INTEGER, assists INTEGER, deaths INTEGER, notify INTEGER)");
        SQL_FastQuery(DB, "CREATE TABLE IF NOT EXISTS players (id INTEGER, name TEXT, steamid TEXT, vip INTEGER, lastConnect TEXT, ip TEXT, spendedTime TEXT)");
        SQL_FastQuery(DB, "CREATE TABLE IF NOT EXISTS admins (idPlayer INTEGER, adminFlag TEXT)");
    } else {
        SQL_FastQuery(DB, "CREATE TABLE IF NOT EXISTS elostats (idPlayer int(8), rating int(8) NOT NULL, kills int(8) NOT NULL, assists int(8) NOT NULL deaths int(8) NOT NULL, notify int(2) NOT NULL)");
        SQL_FastQuery(DB, "CREATE TABLE IF NOT EXISTS players (id int(8), name varchar(255), steamid varchar(32), vip int(1), lastConnect varchar(64), ip varchar(64), spendedTime varchar(64))");
        SQL_FastQuery(DB, "CREATE TABLE IF NOT EXISTS admins (idPlayer int(8), adminFlag varchar(1)");
    }
}

public DBConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE) {
        IronLog(false, "Database failure: %s", error);
        return;
    }

    DB = hndl;
    CheckAdminsInDB();
}

CheckClientInDB(const client)
{
    new String:steamid[32], String:DBQuery[256];
    GetClientAuthId(client, AuthId_Steam3, steamid, sizeof(steamid));
    Format(DBQuery, sizeof(DBQuery), "SELECT vip, spendedTime, id FROM players WHERE steamid='%s'", steamid);
    SQL_TQuery(DB, CheckClientInDBCallback, DBQuery, GetClientUserId(client));
}

public CheckClientInDBCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    new client = GetClientOfUserId(data);
    if(!IsValidClient(client)) {
        IronLog(false, "Invalid client: %d", client);
        return;
    }
    if(hndl == INVALID_HANDLE) {
        IronLog(false, "Query failed: %s", error);
        return;
    }

    new String:steamid[32], String:name[64], String:ip[32], String:datetime[32], String:DBQuery[512];
    GetClientAuthId(client, AuthId_Steam3, steamid, sizeof(steamid));
    GetClientName(client, name, sizeof(name));
    ReplaceString(name, sizeof(name), "'", "");
    GetClientIP(client, ip, sizeof(ip));
    if (SQL_GetRowCount(hndl) < 1) {
        FormatTime(datetime, sizeof(datetime), "%Y-%m-%d %H:%M:%S", GetTime());
        Format(DBQuery, sizeof(DBQuery), "INSERT INTO players(name, steamid, vip, lastConnect, ip, spendedTime) VALUES('%s','%s','%d','%s','%s','00:00:00')", name, steamid, 0, datetime, ip);
        SQL_TQuery(DB, SQLErrorCheckCallback, DBQuery);
        CheckPlayerID(client);
    } else {
        new String:time[16], String:times[3][16];

        // VIP INIT
        SQL_FetchRow(hndl);
        if(SQL_FetchInt(hndl, 0) == 1) {
            SetPlayerVip(client);
        }

        // STORE PLAYER DATA
        SQL_FetchString(hndl, 1, time, sizeof(time));
        ExplodeString(time, ":", times, 3, sizeof(time));
        g_hours[client] = StringToInt(times[0]);
        g_minutes[client] = StringToInt(times[1]);
        g_seconds[client] = StringToInt(times[2]);
        Format(DBQuery, sizeof(DBQuery), "UPDATE players SET name='%s', ip='%s' WHERE steamid='%s'", name, ip, steamid);
        SQL_TQuery(DB, SQLErrorCheckCallback, DBQuery);

        // STORE PLAYER ID
        g_PlayerId[client] = SQL_FetchInt(hndl, 2);
    }
    CheckClientInElo(client);
    if(HasPlayerVip(client)) {
        SendConVarValue(client, mp_forcecamera, "0");
        ServerCommand("mp_disable_autokick %d", GetClientUserId(client));
        SetFullVipAdvs(client);
        LoadVipCookies(client);
    }
}

CheckAdminsInDB()
{
    kvAdmins = CreateKeyValues("Admins");
    if(!FileToKeyValues(kvAdmins, g_AdminsPath))  {
        IronLog(false, "Failed to load admins");
        return false;
    }

    if(!KvGotoFirstSubKey(kvAdmins)) {
        return false;
    }

    decl String:buffer[64], String:DBQuery[512];
    new Handle:data = CreateArray(ByteCountToCells(64));
    KvGetString(kvAdmins, "auth", buffer, sizeof(buffer));
    if (StrEqual("steam", buffer)) {
        KvGetString(kvAdmins, "identity", buffer, sizeof(buffer));
        Format(DBQuery, sizeof(DBQuery), "SELECT idPlayer, adminFlag FROM admins JOIN players ON admins.idPlayer=players.id WHERE players.steamid='%s'", buffer);
        PushArrayString(data, buffer);
        SQL_TQuery(DB, CheckAdminsInDBCallback, DBQuery, data);
    }

    CreateTimer(6.0, Timer_CheckAdminsInDB, _);

    return true;
}

public CheckAdminsInDBCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    new String:dataString[64], String:DBQuery[256];
    GetArrayString(data, 0, dataString, sizeof(dataString));

    if(hndl == INVALID_HANDLE) {
        IronLog(false, "Query to DBCallback failed: %s", error);
        return;
    }

    if (SQL_GetRowCount(hndl) < 1) {
        Format(DBQuery, sizeof(DBQuery), "SELECT id, name FROM players WHERE steamid='%s'", dataString);
        SQL_TQuery(DB, CheckAdminsInDBCallback2, DBQuery, data);
    } else {
        decl String:buffer[64], String:flags[64];
        SQL_FetchRow(hndl);
        SQL_FetchString(hndl, 1, flags, sizeof(buffer));
        KvGetString(kvAdmins, "flags", buffer, sizeof(buffer));
        if(!StrEqual(buffer, flags, false)) {
            Format(DBQuery, sizeof(DBQuery), "UPDATE admins SET adminFlag='%s' WHERE idPlayer='%d'", buffer, SQL_FetchInt(hndl, 0));
            IronLog(true, "Admin %s was updated in database.", dataString);
            SQL_TQuery(DB, SQLErrorCheckCallback, DBQuery);
        }
    }
}

public CheckAdminsInDBCallback2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if(hndl == INVALID_HANDLE) {
        IronLog(false, "Query to DBCallback2 failed: %s", error);
        return;
    }

    if(!SQL_GetRowCount(hndl)) {
        return;
    }

    new String:dataString[64], String:DBQuery[256];
    GetArrayString(data, 0, dataString, sizeof(dataString));
    SQL_FetchRow(hndl);
    new id = SQL_FetchInt(hndl, 0);
    new String:name[64], String:buffer[64];
    SQL_FetchString(hndl, 1, name, sizeof(name));
    KvGetString(kvAdmins, "flags", buffer, sizeof(buffer));
    Format(DBQuery, sizeof(DBQuery), "INSERT INTO admins(idPlayer, adminFlag) VALUES('%d','%s')", id, buffer);
    IronLog(true, "Admin %s was inserted into database.", name);
    SQL_TQuery(DB, SQLErrorCheckCallback, DBQuery);
}

//public MRESReturn:IsValidTarget(this, Handle:hReturn, Handle:hParams)
//{
    // As of DHooks 1.0.12 we must check for a null param.
//    if (g_bCheckNullPtr && DHookIsNullParam(hParams, 1))
//        return MRES_Ignored;
    
//    new target = DHookGetParam(hParams, 1);
//    if(target <= 0 || target > MaxClients || !IsClientInGame(this) || !IsClientInGame(target) || !IsPlayerAlive(target) || IsPlayerAlive(this) || GetClientTeam(this) <= 1 || GetClientTeam(target) <= 1) {
//        return MRES_Ignored;
//    }
//    else {
//        DHookSetReturn(hReturn, true);
//        return MRES_Override;
//    }
//}