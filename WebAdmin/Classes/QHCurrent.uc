/**
 * The query handler that provides information about the current game. It will
 * also set the start page for the webadmin.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class QHCurrent extends Object implements(IQueryHandler) config(WebAdmin);

`include(WebAdmin.uci)

var WebAdmin webadmin;

/**
 * Refresh time of the chat console
 */
var config int ChatRefresh;

/**
 * If true the management console will be available. This will allow users to
 * directly enter console commands on the server. This means that the user will
 * have the ability to shutdown the server or execute commands that change
 * certain core variables.
 */
var config bool bConsoleEnabled;

/**
 * Options in this list are not allowed to be set in the "change game" page.
 * They will removed from the url.
 */
var config array<string> denyUrlOptions;

/**
 * Lists of console commands that are not allowed to be executed.
 */
var config array<string> denyConsoleCommands;

/**
 * if true use the hack to access some special admin commands lick "kickban ...",
 * "restartlevel". If false these commands would not be available
 */
var config bool bAdminConsoleCommandsHack;

/**
 * The AdminCommandHandler class to use for handling the admin console command hack.
 */
var config string AdminCommandHandlerClass;

/**
 * if true team chat will be enabled.
 */
var config bool bEnableTeamChat;

/**
 * Instance that handled "Admin" console command aliases.
 */
var AdminCommandHandler adminCmdHandler;

/**
 * CSS code to make things visible.
 */
var string cssVisible;

/**
 * CSS code to make HTML elements hidden.
 */
var string cssHidden;

/**
 * Will hold a sorted player replication info list.
 */
var array<PlayerReplicationInfo> sortedPRI;

/**
 * Will hold the url where to switch the game to. Game switching a delayed for
 * a few ms.
 */
var private string newUrl;

/**
 * Characters ordered by faction.
 */
struct FactionCharacters
{
	var string factionName;
	var FactionInfo fi;
	var array<CharacterInfo> chars;
};

/**
 * List of factions and their characters
 */
var array<FactionCharacters> factions;

/**
 * if true the news will be shown on the "current" page
 */
var config bool hideNews;

var NewsDesk newsDesk;

/**
 * Notes which an admin can enter if they feel like
 */
var config array<string> notes;

//!localization
var localized string menuCurrent, menuCurrentDesc, menuPlayers, menuPlayersDesc,
	menuChat, menuChatDesc, menuChange, menuChangeDesc, menuConsole, menuConsoleDesc,
	menuBots, menuBotsDesc, NotesSaved, msgPlayerNotFound, msgNoHumanPlayer,
	msgVoiceMuted, msgVoiceUnmuted, msgTextMuted, msgTextUnmuted, msgCantBanAdmin,
	msgSessionBanned, msgCantKickAdmin, msgPlayerRemoved, msgTextMute, msgTextUnmute,
	msgExecDisabled, msgChangingGame, msgAddingBots, msgRemovedBots, msgAddedBots,
	msgRostedSaved;

function init(WebAdmin webapp)
{
	local class<AdminCommandHandler> achc;

	if (Len(AdminCommandHandlerClass) == 0)
	{
  		AdminCommandHandlerClass = class.getPackageName()$".AdminCommandHandler";
		SaveConfig();
	}

	webadmin = webapp;
	if (len(webapp.startpage) == 0)
	{
		webapp.startpage = "/current";
		webapp.SaveConfig();
	}
	if (ChatRefresh < 500) ChatRefresh = 5000;

	if (bAdminConsoleCommandsHack)
	{
		achc = class<AdminCommandHandler>(DynamicLoadObject(AdminCommandHandlerClass, class'class'));
		if (achc != none)
		{
			adminCmdHandler = webadmin.worldinfo.spawn(achc);
		}
	}

	webadmin.WorldInfo.Game.SetTimer(0.1, false, 'CreateTeamChatProxy', self);
	if (!hideNews)
	{
		newsDesk = new class'NewsDesk';
		newsDesk.getNews();
	}
}

function CreateTeamChatProxy()
{
	local TeamChatProxy tcp;
	local int i;
	if (bEnableTeamChat && webadmin.WorldInfo.Game.bTeamGame)
	{
		if (webadmin.WorldInfo.Game.GameReplicationInfo == none)
		{
			webadmin.WorldInfo.Game.SetTimer(0.1, false, 'CreateTeamChatProxy', self);
			return;
		}

		`log("Creating team chat proxies",,'WebAdmin');

		for (i = 0; i < webadmin.WorldInfo.Game.GameReplicationInfo.Teams.length; i++)
		{
			if (webadmin.WorldInfo.Game.GameReplicationInfo.Teams[i] == none) continue;
			tcp = webadmin.WorldInfo.Spawn(class'TeamChatProxy',, name("TeamChatProxy__"$i));
			if (tcp != none)
			{
				tcp.PlayerReplicationInfo.Team = webadmin.WorldInfo.Game.GameReplicationInfo.Teams[i];
			}
			else {
				`log("Failed to create TeamChatProxy for team "$i,,'WebAdmin');
			}
		}
		if (WebAdmin.bChatLog)
		{
			WebAdmin.CreateChatLog();
		}
	}
	else if (WebAdmin.bChatLog)
	{
		WebAdmin.CreateChatLog();
	}
}

function cleanup()
{
	adminCmdHandler = none;
	webadmin = none;
	newsDesk.cleanup();
	newsDesk = none;
	sortedPRI.Remove(0, sortedPRI.Length);
}

function bool producesXhtml()
{
	return true;
}

function registerMenuItems(WebAdminMenu menu)
{
	menu.addMenu("/current", menuCurrent, self, menuCurrentDesc, -100);
	menu.addMenu("/current/data", "", self);
	menu.addMenu("/current/players", menuPlayers, self, menuPlayersDesc);
	menu.addMenu("/current/players/data", "", self);
	menu.addMenu("/current/chat", menuChat, self, menuChatDesc);
	menu.addMenu("/current/chat/data", "", self);
	menu.addMenu("/current/change", menuChange, self, menuChangeDesc);
	menu.addMenu("/current/change/data", "", self);
	menu.addMenu("/current/change/check", "", self);
	if (bConsoleEnabled)
	{
		menu.addMenu("/console", menuConsole, self, menuConsoleDesc);
	}
	menu.addMenu("/current/bots", menuBots, self, menuBotsDesc);
}

function bool handleQuery(WebAdminQuery q)
{
	switch (q.request.URI)
	{
		case "/current":
			handleCurrent(q);
			return true;
		case "/current/data":
			handleCurrentData(q);
			return true;
		case "/current/players":
			handleCurrentPlayers(q);
			return true;
		case "/current/players/data":
			handleCurrentPlayersData(q);
			return true;
		case "/current/chat":
			handleCurrentChat(q);
			return true;
		case "/current/chat/data":
			handleCurrentChatData(q);
			return true;
		case "/current/chat/check":
			q.response.SendStandardHeaders();
			q.response.SendText("done");
			return true;
		case "/console":
			if (bConsoleEnabled)
			{
				handleConsole(q);
				return true;
			}
			return false;
		case "/current/change":
			handleCurrentChange(q);
			return true;
		case "/current/change/data":
			handleCurrentChangeData(q);
			return true;
		case "/current/change/check":
			if (newUrl == "")
			{
				q.response.SendText("ok");
			}
			else {
				q.response.HTTPResponse("HTTP/1.1 503 Service Unavailable");
			}
			return true;
		case "/current/bots":
			handleBots(q);
			return true;
	}
	return false;
}

// not used here
function bool unhandledQuery(WebAdminQuery q);

function handleCurrentData(WebAdminQuery q)
{
	local string tmp;
	local int idx;

	if (q.request.getVariable("action") ~= "save")
	{
		notes.length = 0;
		tmp = q.request.getVariable("notes");
		idx = InStr(tmp, chr(10));
		while (idx != INDEX_NONE)
		{
			notes[notes.length] = `Trim(Left(tmp, idx));
			tmp = Mid(tmp, idx+1);
			idx = InStr(tmp, chr(10));
		}
		tmp = `Trim(tmp);
		if (len(tmp) > 0)
		{
			notes[notes.length] = tmp;
		}
		SaveConfig();
		webadmin.addMessage(q, NotesSaved);
	}

	if (q.request.getVariable("ajax") == "1")
	{
		q.response.AddHeader("Content-Type: text/xml");
		q.response.SendText("<request>");
  		q.response.SendText("<messages><![CDATA[");
		q.response.SendText(webadmin.renderMessages(q));
		q.response.SendText("]]></messages>");
		q.response.SendText("</request>");
	}
}

function handleCurrent(WebAdminQuery q)
{
	local string players;
	local PlayerReplicationInfo pri;
	local int idx, i;
	local mutator mut;
	local string tmp, tmp2;
	local array<string> activeMuts;

	handleCurrentData(q);

	if (!hideNews && newsDesk != none)
	{
		q.response.subst("news", newsDesk.renderNews(webadmin, q));
	}
	else {
		q.response.subst("news", "");
	}

	tmp = "";
	for (idx = 0; idx < notes.length; idx++)
	{
		tmp $= notes[idx]$chr(10);
	}
	q.response.subst("notes", `HTMLEscape(tmp));

	q.response.subst("game.name", `HTMLEscape(webadmin.WorldInfo.Game.GameName));
	q.response.subst("game.type", webadmin.WorldInfo.Game.class.getPackageName()$"."$webadmin.WorldInfo.Game.class);

	q.response.subst("map.title", `HTMLEscape(webadmin.WorldInfo.Title));
	q.response.subst("map.author", `HTMLEscape(webadmin.WorldInfo.Author));
	q.response.subst("map.name", webadmin.WorldInfo.GetPackageName());

	webadmin.dataStoreCache.loadMutators();
	ParseStringIntoArray(webadmin.WorldInfo.Game.ParseOption(webadmin.WorldInfo.Game.ServerOptions, "mutator"), activeMuts, ",", true);

	mut = webadmin.WorldInfo.Game.BaseMutator;
	while (mut != none)
	{
		tmp2 = mut.class.getPackageName()$"."$mut.class;
		if (activeMuts.find(tmp2) == INDEX_none)
		{
			activeMuts.addItem(tmp2);
		}
		mut = mut.NextMutator;
	}

	tmp = "";
	for (i = 0; i < activeMuts.length; i++)
	{
		if (len(tmp) > 0) tmp $= ", ";
		tmp2 = activeMuts[i];
		for (idx = 0; idx < webadmin.dataStoreCache.mutators.Length; ++idx)
		{
			if (webadmin.dataStoreCache.mutators[idx].ClassName ~= tmp2)
			{
				tmp $= webadmin.dataStoreCache.mutators[idx].FriendlyName;
				break;
			}
		}
		if (idx == webadmin.dataStoreCache.mutators.Length)
		{
			tmp $= tmp2;
		}
	}
	q.response.subst("mutators", tmp);

	q.response.subst("rules.timelimit", webadmin.WorldInfo.Game.TimeLimit);
	q.response.subst("rules.goalscore", webadmin.WorldInfo.Game.GoalScore);
	q.response.subst("rules.maxlives", webadmin.WorldInfo.Game.MaxLives);

	q.response.subst("rules.maxspectators", webadmin.WorldInfo.Game.MaxSpectators);
	q.response.subst("rules.numspectators", webadmin.WorldInfo.Game.NumSpectators);
	q.response.subst("rules.maxplayers", webadmin.WorldInfo.Game.MaxPlayers);
	q.response.subst("rules.numplayers", webadmin.WorldInfo.Game.NumPlayers);
	q.response.subst("rules.numbots", webadmin.WorldInfo.Game.NumBots);

	q.response.subst("time.elapsed", webadmin.WorldInfo.Game.GameReplicationInfo.ElapsedTime);
	q.response.subst("time.remaining", webadmin.WorldInfo.Game.GameReplicationInfo.RemainingTime);

	q.response.subst("server.name", `HTMLEscape(webadmin.WorldInfo.Game.GameReplicationInfo.ServerName));
	q.response.subst("server.admin.name", `HTMLEscape(webadmin.WorldInfo.Game.GameReplicationInfo.AdminName));
	q.response.subst("server.admin.email", `HTMLEscape(webadmin.WorldInfo.Game.GameReplicationInfo.AdminEmail));
	q.response.subst("server.motd", `HTMLEscape(webadmin.WorldInfo.Game.GameReplicationInfo.MessageOfTheDay));

	buildSortedPRI(q.request.getVariable("sortby", "score"), q.request.getVariable("reverse", "true") ~= "true");
	foreach sortedPRI(pri, idx)
	{
		if (int(idx % 2) == 0) q.response.subst("evenodd", "even");
		else q.response.subst("evenodd", "odd");
		substPri(q, pri);
		players $= webadmin.include(q, "current_player_row.inc");
	}
	if (sortedPRI.Length == 0)
	{
		players = webadmin.include(q, "current_player_empty.inc");
	}
	q.response.subst("sorted."$q.request.getVariable("sortby", "score"), "sorted");
	if (!(q.request.getVariable("reverse", "true") ~= "true"))
	{
		q.response.subst("reverse."$q.request.getVariable("sortby", "score"), "true");
	}

	q.response.subst("players", players);
	webadmin.sendPage(q, "current.html");
}

function buildSortedPRI(string sortkey, optional bool reverse=false, optional bool includeBots=true)
{
	local Controller P;
	local PlayerReplicationInfo PRI;
	local int idx;
	local bool cmp, inserted;

	sortedPRI.Remove(0, sortedPRI.Length);

	foreach WebAdmin.WorldInfo.AllControllers(class'Controller', P)
	{
		if (!P.bDeleteMe && P.PlayerReplicationInfo != None && P.bIsPlayer)
		{
			if (!includeBots && P.PlayerReplicationInfo.bBot)
			{
				continue;
			}
			if (DemoRecSpectator(P) != none)
			{
				// never mess with this one
				continue;
			}
			inserted = false;
			foreach sortedPRI(PRI, idx)
			{
				cmp = comparePRI(PRI, P.PlayerReplicationInfo, sortkey);
				if (reverse)
				{
					cmp = !cmp;
				}
				if (cmp)
				{
					sortedPRI.Insert(idx, 1);
					sortedPRI[idx] = P.PlayerReplicationInfo;
					inserted = true;
					break;
				}
			}
			if (!inserted)
			{
				sortedPRI.addItem(P.PlayerReplicationInfo);
			}
		}
	}
}

static function bool comparePRI(PlayerReplicationInfo PRI1, PlayerReplicationInfo PRI2, string key)
{
	local string s1, s2;
	if (key ~= "name")
	{
		if (len(pri1.PlayerName) == 0)
		{
			s1 = pri1.PlayerAlias;
		}
		else {
			s1 = pri1.PlayerName;
		}
		if (len(pri2.PlayerName) == 0)
		{
			s2 = pri2.PlayerAlias;
		}
		else {
			s2 = pri2.PlayerName;
		}
		return caps(s1) > caps(s2);
	}
	else if (key ~= "playername")
	{
		return caps(pri1.PlayerName) > caps(pri2.PlayerName);
	}
	else if (key ~= "playeralias")
	{
		return caps(pri1.PlayerAlias) > caps(pri2.PlayerAlias);
	}
	else if (key ~= "score")
	{
		return pri1.score > pri2.score;
	}
	else if (key ~= "deaths")
	{
		return pri1.deaths > pri2.deaths;
	}
	else if (key ~= "ping")
	{
		return pri1.ping > pri2.ping;
	}
	else if (key ~= "lives")
	{
		return pri1.NumLives > pri2.numlives;
	}
	else if (key ~= "ranking")
	{
		return pri1.playerranking > pri2.playerranking;
	}
	else if (key ~= "teamid")
	{
		return pri1.teamid > pri2.teamid;
	}
	else if (key ~= "kills")
	{
		return pri1.kills > pri2.kills;
	}
	else if (key ~= "starttime")
	{
		return pri1.starttime > pri2.starttime;
	}
}

static function string getPlayerKey(PlayerReplicationInfo pri)
{
	return pri.PlayerID$"_"$class'OnlineSubsystem'.static.UniqueNetIdToString(pri.UniqueId)$"_"$pri.CreationTime;
}

static function substPri(WebAdminQuery q, PlayerReplicationInfo pri)
{
	q.response.subst("player.playerid", pri.PlayerID);
	q.response.subst("player.playerkey", getPlayerKey(pri));
	if (len(pri.PlayerName) == 0)
	{
		q.response.subst("player.name", `HTMLEscape(pri.PlayerAlias));
	}
	else {
		q.response.subst("player.name", `HTMLEscape(pri.PlayerName));
	}
	q.response.subst("player.playername", `HTMLEscape(pri.PlayerName));
	q.response.subst("player.playeralias", `HTMLEscape(pri.PlayerAlias));
	q.response.subst("player.score", int(pri.score));
	q.response.subst("player.deaths", int(pri.deaths));
	q.response.subst("player.ping", pri.ping * 4); // this ping value is divided by 4 (250 = 1sec) see bug #40
	q.response.subst("player.exactping", pri.ExactPing);
	q.response.subst("player.packetloss", pri.PacketLoss);
	q.response.subst("player.lives", pri.numlives);
	q.response.subst("player.ranking", pri.playerranking);
	if (pri.Team != none)
	{
		q.response.subst("player.teamid", pri.Team.TeamIndex);
		q.response.subst("player.teamcolor", class'WebAdminUtils'.static.ColorToHTMLColor(pri.Team.GetHUDColor()));
		q.response.subst("player.teamcolor2", class'WebAdminUtils'.static.ColorToHTMLColor(pri.Team.GetTextColor()));
		q.response.subst("player.teamname", `HTMLEscape(pri.Team.GetHumanReadableName()));
	}
	else {
		q.response.subst("player.teamid", "");
		q.response.subst("player.teamcolor", "transparent");
		q.response.subst("player.teamcolor2", "transparent");
		q.response.subst("player.teamname", "");
	}
	q.response.subst("player.admin", `HTMLEscape(pri.bAdmin));
	q.response.subst("player.bot", `HTMLEscape(pri.bBot));
	q.response.subst("player.spectator", `HTMLEscape(pri.bIsSpectator));
	q.response.subst("player.kills", pri.kills);
	q.response.subst("player.starttime", pri.starttime);
}

function int handleCurrentPlayersAction(WebAdminQuery q)
{
	local PlayerReplicationInfo PRI;
	local int idx;
	local string IP, action;
	local PlayerController PC,otherPC;
	local UTPlayerController UTPC;

	action = q.request.getVariable("action");
	if (action != "")
	{
		//PRI = webadmin.WorldInfo.Game.GameReplicationInfo.FindPlayerByID(int(q.request.getVariable("playerid")));
		IP = q.request.getVariable("playerkey");
		PRI = none;
		for (idx = 0; idx < webadmin.WorldInfo.Game.GameReplicationInfo.PRIArray.length; idx++)
		{
			if (getPlayerKey(webadmin.WorldInfo.Game.GameReplicationInfo.PRIArray[idx]) == IP)
			{
				PRI = webadmin.WorldInfo.Game.GameReplicationInfo.PRIArray[idx];
				break;
			}
		}
		if (PRI == none)
		{
			webadmin.addMessage(q, msgPlayerNotFound, MT_Warning);
		}
		else {
			PC = PlayerController(PRI.Owner);
			if ( NetConnection(PC.Player) == None )
			{
				PC = none;
			}
			if (PC == none)
			{
				webadmin.addMessage(q, msgNoHumanPlayer, MT_Warning);
			}
			else {
				if (action ~= "mutevoice")
				{
					foreach webadmin.WorldInfo.AllControllers(class'PlayerController', otherPC)
					{
						otherPC.ServerMutePlayer(PC.PlayerReplicationInfo.UniqueId);
					}
					webadmin.addMessage(q, repl(msgVoiceMuted, "%s", PRI.PlayerName));
					return 0;
				}
				else if (action ~= "unmutevoice")
				{
					foreach webadmin.WorldInfo.AllControllers(class'PlayerController', otherPC)
					{
						otherPC.ServerUnMutePlayer(PC.PlayerReplicationInfo.UniqueId);
					}
					webadmin.addMessage(q, repl(msgVoiceUnmuted, "%s", PRI.PlayerName));
					return 0;
				}
				else if (action ~= "toggletext")
				{
					UTPC = UTPlayerController(PC);
					if (UTPC != none)
					{
						UTPC.bServerMutedText = !UTPC.bServerMutedText;
						if (UTPC.bServerMutedText) webadmin.addMessage(q, repl(msgTextMuted, "%s", PRI.PlayerName));
						else webadmin.addMessage(q, repl(msgTextUnmuted, "%s", PRI.PlayerName));
						return (UTPC.bServerMutedText?2:3);
					}
					return 0;
				}

				else if (action ~= "banip" || action ~= "ban ip")
				{
					banByIP(PC);
				}
				else if (action ~= "banid" || action ~= "ban unique id")
				{
					banByID(PC);
				}
				`if(`WITH_BANCDHASH)
				else if (action ~= "banhash" || action ~= "ban client hash")
				{
					banByHash(PC);
				}
				`endif
				`if(`WITH_SESSION_BAN)
				else if (action ~= "sessionban" || action ~= "session ban")
				{
					if (webadmin.WorldInfo.Game.AccessControl.IsAdmin(PC))
					{
						webadmin.addMessage(q, repl(msgCantBanAdmin, "%s", PRI.PlayerName), MT_Error);
						return 0;
					}
					else {
						webadmin.WorldInfo.Game.AccessControl.SessionBanPlayer(PC);
						webadmin.addMessage(q, repl(msgSessionBanned, "%s", PRI.PlayerName));
						return 1;
					}
				}
				`endif
				if (!webadmin.WorldInfo.Game.AccessControl.KickPlayer(PC, webadmin.WorldInfo.Game.AccessControl.DefaultKickReason))
				{
					webadmin.addMessage(q, repl(msgCantKickAdmin, "%s", PRI.PlayerName), MT_Error);
				}
				else {
					webadmin.addMessage(q, repl(msgPlayerRemoved, "%s", PRI.PlayerName));
					return 1;
				}
			}
		}
	}
	return 0;
}

function handleCurrentPlayers(WebAdminQuery q)
{
	local PlayerReplicationInfo PRI;
	local int idx;
	local string players, IP;
	local PlayerController PC;

	handleCurrentPlayersAction(q);

	buildSortedPRI(q.request.getVariable("sortby", "name"), q.request.getVariable("reverse", "") ~= "true", false);
	foreach sortedPRI(pri, idx)
	{
		PC = PlayerController(pri.owner);
		if (PC == none)
		{
			continue;
		}

		if (int(idx % 2) == 0) q.response.subst("evenodd", "even");
		else q.response.subst("evenodd", "odd");

		substPri(q, pri);
		IP = PC.GetPlayerNetworkAddress();
		IP = Left(IP, InStr(IP, ":"));
		q.response.subst("player.ip", IP);
		q.response.subst("player.uniqueid", class'OnlineSubsystem'.static.UniqueNetIdToString(pri.UniqueId));
		`if(`WITH_BANCDHASH)
		q.response.subst("player.hashresponse", PC.HashResponseCache);
		`endif
		if (UTPlayerController(PC) != none && UTPlayerController(PC).bServerMutedText)
		{
			q.response.subst("player.mutetext", msgTextUnmute);
		}
		else {
			q.response.subst("player.mutetext", msgTextMute);
		}
		players $= webadmin.include(q, "current_players_row.inc");
	}
	if (sortedPRI.Length == 0)
	{
		players = webadmin.include(q, "current_players_empty.inc");
	}

	q.response.subst("sorted."$q.request.getVariable("sortby", "name"), "sorted");
	if (!(q.request.getVariable("reverse", "") ~= "true"))
	{
		q.response.subst("reverse."$q.request.getVariable("sortby", "name"), "true");
	}

	q.response.subst("players", players);

	webadmin.sendPage(q, "current_players.html");
}

function handleCurrentPlayersData(WebAdminQuery q)
{
	q.response.AddHeader("Content-Type: text/xml");
	q.response.SendText("<request>");
	switch (handleCurrentPlayersAction(q))
	{
		case 3: // is NOT muted
			q.response.SendText("<text playerkey=\""$q.request.getVariable("playerkey")$"\" label=\""$msgTextMute$"\"/>");
			break;
		case 2: // is muted
			q.response.SendText("<text playerkey=\""$q.request.getVariable("playerkey")$"\" label=\""$msgTextUnmute$"\"/>");
			break;
		case 1:
			q.response.SendText("<kicked playerkey=\""$q.request.getVariable("playerkey")$"\"/>");
			break;
		case 0:
			q.response.SendText("<nop/>");
			break;
	}
	q.response.SendText("<messages><![CDATA[");
	q.response.SendText(webadmin.renderMessages(q));
	q.response.SendText("]]></messages>");
	q.response.SendText("</request>");
}

protected function banByIP(PlayerController PC)
{
	local string IP;
	IP = PC.GetPlayerNetworkAddress();
	IP = Left(IP, InStr(IP, ":"));
 	webadmin.WorldInfo.Game.AccessControl.IPPolicies[webadmin.WorldInfo.Game.AccessControl.IPPolicies.length] = "DENY," $ IP;
	webadmin.WorldInfo.Game.AccessControl.SaveConfig();
}

protected function banByID(PlayerController PC)
{
	local BannedInfo NewBanInfo;
	if ( PC.PlayerReplicationInfo.UniqueId != PC.PlayerReplicationInfo.default.UniqueId &&
			!webadmin.WorldInfo.Game.AccessControl.IsIDBanned(PC.PlayerReplicationInfo.UniqueID) )
	{
		NewBanInfo.BannedID = PC.PlayerReplicationInfo.UniqueId;
		NewBanInfo.PlayerName = PC.PlayerReplicationInfo.PlayerName;
		NewBanInfo.TimeStamp = Timestamp();
		webadmin.WorldInfo.Game.AccessControl.BannedPlayerInfo.AddItem(NewBanInfo);
		webadmin.WorldInfo.Game.AccessControl.SaveConfig();
	}
}

`if(`WITH_BANCDHASH)
protected function banByHash(PlayerController PC)
{
	local BannedHashInfo NewBanHashInfo;
	if (PC.HashResponseCache != "" && PC.HashResponseCache != "0" && !webadmin.WorldInfo.Game.AccessControl.IsHashBanned(PC.HashResponseCache))
	{
		NewBanHashInfo.PlayerName = PC.PlayerReplicationInfo.PlayerName;
		NewBanHashInfo.BannedHash = PC.HashResponseCache;
		webadmin.WorldInfo.Game.AccessControl.BannedHashes.AddItem(NewBanHashInfo);
		webadmin.WorldInfo.Game.AccessControl.SaveConfig();
	}
}
`endif

function handleCurrentChat(WebAdminQuery q)
{
	local string msg;
	local int i;

	msg = q.request.getVariable("message");
	if (len(msg) > 0)
	{
		i = int(q.request.getVariable("teamsay", "-1"));
		if (i < 0 || i >= webadmin.WorldInfo.Game.GameReplicationInfo.Teams.length)
		{
			BroadcastMessage(q.user.getPC(), INDEX_NONE, msg, 'Say');
		}
		else {
			BroadcastMessage(q.user.getPC(), i, msg, 'TeamSay');
		}
	}
	procChatData(q, 0, "chat.log");
	q.response.subst("chat.refresh", ChatRefresh);
	q.response.subst("chat.max", class'BasicWebAdminUser'.default.maxHistory);

	msg = "";
	if (bEnableTeamChat && webadmin.WorldInfo.Game.bTeamGame)
	{
		q.response.subst("team.teamid", -1);
		q.response.subst("team.name", "Everybody");
		q.response.subst("team.checked", "checked=\"checked\"");
		msg $= webadmin.include(q, "current_chat_teamctrl.inc");
		for (i = 0; i < webadmin.WorldInfo.Game.GameReplicationInfo.Teams.length; i++)
		{
			q.response.subst("team.teamid", i);
			q.response.subst("team.name", `HTMLEscape(webadmin.WorldInfo.Game.GameReplicationInfo.Teams[i].GetHumanReadableName()));
			q.response.subst("team.checked", "");
			msg $= webadmin.include(q, "current_chat_teamctrl.inc");
		}
	}
	q.response.subst("teamsaycontrols", msg);

	webadmin.sendPage(q, "current_chat.html");
}

function BroadcastMessage( Controller Sender, int teamidx, coerce string Msg, name Type )
{
	//local PlayerController P;
	local TeamInfo oldTeam;
	if (teamidx > INDEX_NONE)
	{
		oldTeam = Sender.PlayerReplicationInfo.Team;
		Sender.PlayerReplicationInfo.Team = webadmin.WorldInfo.Game.GameReplicationInfo.Teams[teamidx];
		webadmin.WorldInfo.Game.BroadcastTeam(Sender, msg, Type);
		//foreach webadmin.WorldInfo.AllControllers(class'PlayerController', P)
		//{
		//	if (P.PlayerReplicationInfo.Team == webadmin.WorldInfo.Game.GameReplicationInfo.Teams[teamidx])
		//	{
		//		webadmin.WorldInfo.Game.BroadcastHandler.BroadcastText(Sender.PlayerReplicationInfo, P, Msg, Type);
		//	}
		//}
		Sender.PlayerReplicationInfo.Team = oldTeam;
	}
	else {
		webadmin.WorldInfo.Game.Broadcast(Sender, msg, Type);
	}
}

function handleCurrentChatData(WebAdminQuery q)
{
	local string msg;
	local int i;

	msg = q.request.getVariable("message");
	if (len(msg) > 0)
	{
		i = int(q.request.getVariable("teamsay", "-1"));
		if (i < 0 || i >= webadmin.WorldInfo.Game.GameReplicationInfo.Teams.length)
		{
			BroadcastMessage(q.user.getPC(), INDEX_NONE, msg, 'Say');
		}
		else {
			BroadcastMessage(q.user.getPC(), i, msg, 'TeamSay');
		}
	}
	q.response.AddHeader("Content-Type: text/html");
	q.response.SendStandardHeaders();
	procChatData(q, int(q.session.getString("chatlog.lastid")));
}

function procChatData(WebAdminQuery q, optional int startFrom, optional string substvar)
{
	local string result;
	local array<MessageEntry> history;
	local MessageEntry entry;
	local string template;

	q.user.messageHistory(history, startFrom);

	foreach history(entry)
	{
		if (entry.type == 'say')
		{
			template = "current_chat_msg.inc";
		}
		else if (entry.type == 'teamsay')
		{
			template = "current_chat_teammsg.inc";
		}
		else {
			template = "current_chat_notice.inc";
		}

		q.response.subst("msg.type", `HTMLEscape(entry.type));
		q.response.subst("msg.username", `HTMLEscape(entry.senderName));
		q.response.subst("msg.text", `HTMLEscape(entry.message));
		if (entry.teamId > INDEX_NONE)
		{
			q.response.subst("msg.teamcolor", class'WebAdminUtils'.static.ColorToHTMLColor(entry.teamColor));
		}
		else {
			q.response.subst("msg.teamcolor", "transparent");
		}
		if (substvar == "")
		{
			q.response.SendText(webadmin.include(q, template));
		}
		else {
			result $= webadmin.include(q, template);
		}
		startFrom = entry.counter;
	}

	if (substvar != "")
	{
		q.response.subst(substvar, result);
	}
	q.session.putString("chatlog.lastid", ""$startFrom);
}

function handleConsole(WebAdminQuery q)
{
	local string cmd, result;
	local int i;
	local bool denied;

	cmd = q.request.getVariable("command");
	if (len(cmd) > 0)
	{
		denied = false;
		for (i = 0; i < denyConsoleCommands.length; i++)
		{
			if (denyConsoleCommands[i] ~= cmd || InStr(cmd$" ", denyConsoleCommands[i]$" ") == 0)
			{
				denied = true;
				break;
			}
		}

		if (!denied)
		{
			result = "";
			if (bAdminConsoleCommandsHack && adminCmdHandler != none)
			{
				// hack to blend in some admin exec commands
				denied = adminCmdHandler.execute(cmd, result, q.user.getPC());
			}
			if (!denied)
			{
				result = webadmin.WorldInfo.Game.ConsoleCommand(cmd, false);
			}
			q.response.subst("console.command", `HTMLEscape(cmd));
			q.response.subst("console.results", `HTMLEscape(result));
			q.response.subst("console.visible", cssVisible);
		}
		else {
			q.response.subst("console.command", `HTMLEscape(cmd));
			q.response.subst("console.results", `HTMLEscape(msgExecDisabled));
			q.response.subst("console.visible", cssVisible);
		}
	}
	else {
		q.response.subst("console.command", "");
		q.response.subst("console.results", "");
		q.response.subst("console.visible", cssHidden);
	}
	webadmin.sendPage(q, "console.html");
}

event ChangeGameTimer()
{
	if (Len(newUrl) > 0)
	{
		webadmin.WorldInfo.ServerTravel(newUrl, true);
		newUrl = "";
	}
}

function handleCurrentChange(WebAdminQuery q)
{
	local UTUIDataProvider_GameModeInfo gametype;
	local string currentGameType, curmap, curmiscurl;
	local array<string> currentMutators;
	local string substvar, substvar2;
	local int idx, i, j;
	local mutator mut;
	local array<KeyValuePair> options;

 	webadmin.dataStoreCache.loadGameTypes();

 	currentGameType = q.request.getVariable("gametype");
 	curmap = q.request.getVariable("map");

 	curmiscurl = webadmin.WorldInfo.Game.ServerOptions;
 	class'UTGame'.static.RemoveOption(curmiscurl, "Mutator");
 	class'UTGame'.static.RemoveOption(curmiscurl, "Game");
 	class'UTGame'.static.RemoveOption(curmiscurl, "Team");
 	class'UTGame'.static.RemoveOption(curmiscurl, "Name");
 	class'UTGame'.static.RemoveOption(curmiscurl, "Class");
 	for (i = 0; i < denyUrlOptions.length; i++)
 	{
 		class'UTGame'.static.RemoveOption(curmiscurl, denyUrlOptions[i]);
 	}
 	curmiscurl = q.request.getVariable("urlextra", curmiscurl);

 	idx = int(q.request.getVariable("mutatorGroupCount", "0"));
 	for (i = 0; i < idx; i++)
 	{
 		substvar = q.request.getVariable("mutgroup"$i, "");
 		if (len(substvar) > 0)
 		{
 			if (currentMutators.find(substvar) == INDEX_NONE)
 			{
 				currentMutators.addItem(substvar);
 			}
 		}
 	}

 	if (q.request.getVariable("action") ~= "change" || q.request.getVariable("action") ~= "change game")
 	{
 		options.length = 0;
 		class'WebAdminUtils'.static.parseUrlOptions(options, curmiscurl);
 		if (currentMutators.length > 0)
 		{
 			JoinArray(currentMutators, substvar2, ",");
 			class'WebAdminUtils'.static.parseUrlOptions(options, "mutator="$substvar2);
 		}
 		class'WebAdminUtils'.static.parseUrlOptions(options, "game="$currentGameType);
 		i = InStr(curmap, "?");
 		if (i != INDEX_NONE)
 		{
 			class'WebAdminUtils'.static.parseUrlOptions(options, Mid(curmap, i+1));
 			curmap = Left(curmap, i);
 		}
 		// remove denied options
 		for (i = 0; i < denyUrlOptions.length; i++)
 		{
 			for (j = options.length-1; j >= 0; j--)
 			{
 				if (options[j].key ~= denyUrlOptions[i])
 				{
 					options.remove(j, 1);
 				}
 			}
 		}

		// construct url
 		substvar = curmap;
 		for (i = 0; i < options.length; i++)
 		{
 			substvar $= "?"$options[i].key;
 			if (Len(options[i].value) > 0)
 			{
 				substvar $= "="$options[i].value;
 			}
 		}

		webadmin.addMessage(q, msgChangingGame);
		q.response.subst("newurl", `HTMLEscape(substvar));
		webadmin.sendPage(q, "current_changing.html");

		// add deny options when they were set on previous the commandline
		for (i = 0; i < denyUrlOptions.length; i++)
 		{
 			if (webadmin.WorldInfo.Game.HasOption(webadmin.WorldInfo.Game.ServerOptions, denyUrlOptions[i]))
 			{
 				substvar $= "?"$denyUrlOptions[i];
 				substvar2 = webadmin.WorldInfo.Game.ParseOption(webadmin.WorldInfo.Game.ServerOptions, denyUrlOptions[i]);
 				if (len(substvar2) > 0)
 				{
 					substvar $= "="$substvar2;
 				}
 			}
		}

		newUrl = substvar;
		webadmin.WebServer.SetTimer(0.5, false, 'ChangeGameTimer', self);
 		//webadmin.WorldInfo.ServerTravel(substvar, true);
 		return;
 	}

 	if (currentGameType == "")
 	{
 		currentGameType = string(webadmin.WorldInfo.Game.class);
 		curmap = string(webadmin.WorldInfo.GetPackageName());
 		ParseStringIntoArray(webadmin.WorldInfo.Game.ParseOption(webadmin.WorldInfo.Game.ServerOptions, "mutator"), currentMutators, ",", true);
		mut = webadmin.WorldInfo.Game.BaseMutator;
		while (mut != none)
		{
			substvar = mut.class.getPackageName()$"."$mut.class;
			currentMutators.addItem(substvar);
			mut = mut.NextMutator;
		}
 	}
 	idx = webadmin.dataStoreCache.resolveGameType(currentGameType);
 	if (idx > INDEX_NONE)
 	{
 		currentGameType = webadmin.dataStoreCache.gametypes[idx].GameMode;
 		if (curmap == "")
 		{
 			curmap = webadmin.dataStoreCache.gametypes[idx].DefaultMap;
 		}
 	}
 	else {
 		currentGameType = "";
 	}

	substvar = "";
 	foreach webadmin.dataStoreCache.gametypes(gametype)
 	{
 		if (gametype.bIsCampaign)
 		{
 			continue;
 		}
 		q.response.subst("gametype.gamemode", `HTMLEscape(gametype.GameMode));
 		q.response.subst("gametype.friendlyname", `HTMLEscape(class'WebAdminUtils'.static.getLocalized(gametype.FriendlyName)));
 		q.response.subst("gametype.defaultmap", `HTMLEscape(gametype.DefaultMap));
 		q.response.subst("gametype.description", `HTMLEscape(class'WebAdminUtils'.static.getLocalized(gametype.Description)));
 		if (currentGameType ~= gametype.GameMode)
 		{
 			q.response.subst("gametype.selected", "selected=\"selected\"");
 		}
 		else {
 			q.response.subst("gametype.selected", "");
 		}
 		substvar $= webadmin.include(q, "current_change_gametype.inc");
 	}
 	q.response.subst("gametypes", substvar);

	procCurrentChange(q, currentGameType, curmap, currentMutators, substvar, substvar2, idx);
	q.response.subst("maps", substvar);
	q.response.subst("mutators", substvar2);
	q.response.subst("mutator.groups", idx);

	q.response.subst("urlextra", curmiscurl);
	Joinarray(denyUrlOptions, substvar, ", ", true);
	q.response.subst("urlextra.deny", substvar);

	webadmin.sendPage(q, "current_change.html");
}

function procCurrentChange(WebAdminQuery q, string currentGameType, string curmap, array<string> currentMutators,
	out string outMaps, out string outMutators, out int outMutatorGroups)
{
	local string substvar2, substvar3, mutname;
	local int idx, i, j, k;
	local array<UTUIDataProvider_MapInfo> maps;
	local array<MutatorGroup> mutators;

	outMaps = "";
 	if (currentGameType != "")
 	{
 		maps = webadmin.dataStoreCache.getMaps(currentGameType);
 		for (i = 0; i < maps.length; i++)
 		{
			q.response.subst("map.mapname", `HTMLEscape(maps[i].MapName));
 			q.response.subst("map.friendlyname", `HTMLEscape(class'WebAdminUtils'.static.getLocalized(maps[i].FriendlyName)));
 			q.response.subst("map.mapid", string(maps[i].MapID));
 			q.response.subst("map.numplayers", `HTMLEscape(class'WebAdminUtils'.static.getLocalized(maps[i].NumPlayers)));
 			q.response.subst("map.description", `HTMLEscape(class'WebAdminUtils'.static.getLocalized(maps[i].Description)));
	 		if (curmap ~= maps[i].MapName)
 			{
 				q.response.subst("map.selected", "selected=\"selected\"");
	 		}
 			else {
 				q.response.subst("map.selected", "");
	 		}
 			outMaps $= webadmin.include(q, "current_change_map.inc");
 		}
 	}

	outMutators = "";
	outMutatorGroups = 0;
 	if (currentGameType != "")
 	{
 		mutators = webadmin.dataStoreCache.getMutators(currentGameType);
 		idx = 0;
 		for (i = 0; i < mutators.length; i++)
 		{
 			if ((mutators[i].mutators.Length == 1) || len(mutators[i].GroupName) == 0)
 			{
 				for (j = 0; j < mutators[i].mutators.Length; j++)
 				{
 					q.response.subst("mutator.formtype", "checkbox");
	 				q.response.subst("mutator.groupid", "mutgroup"$(mutators.Length+outMutatorGroups));
 					q.response.subst("mutator.classname", `HTMLEscape(mutators[i].mutators[j].ClassName));
 					q.response.subst("mutator.id", "mutfield"$(++idx));
 					mutname = mutators[i].mutators[j].FriendlyName;
 					if (len(mutname) == 0) mutname = mutators[i].mutators[j].ClassName;
 					q.response.subst("mutator.friendlyname", `HTMLEscape(mutname));
 					q.response.subst("mutator.description", `HTMLEscape(mutators[i].mutators[j].Description));
	 				if (currentMutators.find(mutators[i].mutators[j].ClassName) != INDEX_NONE)
 					{
 						q.response.subst("mutator.selected", "checked=\"checked\"");
		 			}
 					else {
		 				q.response.subst("mutator.selected", "");
	 				}
 					substvar3 $= webadmin.include(q, "current_change_mutator.inc");
 					outMutatorGroups++;
 				}
 			}
 			else {
 				substvar2 = "";
 				k = INDEX_NONE;

	 			for (j = 0; j < mutators[i].mutators.Length; j++)
 				{
 					q.response.subst("mutator.formtype", "radio");
	 				q.response.subst("mutator.groupid", "mutgroup"$i);
 					q.response.subst("mutator.classname", `HTMLEscape(mutators[i].mutators[j].ClassName));
 					q.response.subst("mutator.id", "mutfield"$(++idx));
 					mutname = mutators[i].mutators[j].FriendlyName;
 					if (len(mutname) == 0) mutname = mutators[i].mutators[j].ClassName;
 					q.response.subst("mutator.friendlyname", `HTMLEscape(mutname));
 					q.response.subst("mutator.description", `HTMLEscape(mutators[i].mutators[j].Description));
					if (currentMutators.find(mutators[i].mutators[j].ClassName) != INDEX_NONE)
 					{
 						k = j;
 						q.response.subst("mutator.selected", "checked=\"checked\"");
			 		}
 					else {
			 			q.response.subst("mutator.selected", "");
 					}
	 				substvar2 $= webadmin.include(q, "current_change_mutator.inc");
 				}

 				q.response.subst("mutator.formtype", "radio");
	 			q.response.subst("mutator.groupid", "mutgroup"$i);
 				q.response.subst("mutator.classname", "");
 				q.response.subst("mutator.id", "mutfield"$(++idx));
 				q.response.subst("mutator.friendlyname", "none");
 				q.response.subst("mutator.description", "");
 				if (k == INDEX_NONE)
 				{
 					q.response.subst("mutator.selected", "checked=\"checked\"");
			 	}
 				else {
			 		q.response.subst("mutator.selected", "");
 				}
 				substvar2 = webadmin.include(q, "current_change_mutator.inc")$substvar2;

 				q.response.subst("group.id", "mutgroup"$i);
 				q.response.subst("group.name", Locs(mutators[i].GroupName));
 				q.response.subst("group.mutators", substvar2);
	 			outMutators $= webadmin.include(q, "current_change_mutator_group.inc");
	 		}
 		}
 		if (len(substvar3) > 0)
 		{
 			q.response.subst("group.id", "mutgroup0");
	 		q.response.subst("group.name", "");
 			q.response.subst("group.mutators", substvar3);
 			outMutators = webadmin.include(q, "current_change_mutator_nogroup.inc")$outMutators;
 		}
 	}
 	outMutatorGroups = outMutatorGroups+mutators.Length;
}

function handleCurrentChangeData(WebAdminQuery q)
{
	local string currentGameType, curmap;
	local array<string> currentMutators;
	local string substMaps, substMutators, tmp;
	local int idx;

	currentGameType = q.request.getVariable("gametype");
	curmap = "";
	currentMutators.length = 0;

	webadmin.dataStoreCache.loadGameTypes();
	idx = webadmin.dataStoreCache.resolveGameType(currentGameType);
 	if (idx > INDEX_NONE)
 	{
 		currentGameType = webadmin.dataStoreCache.gametypes[idx].GameMode;
 		curmap = webadmin.dataStoreCache.gametypes[idx].DefaultMap;
 	}
 	else {
 		currentGameType = "";
 	}

 	for (idx = 0; idx < int(q.request.getVariable("mutatorGroupCount", "0")); idx++)
 	{
 		tmp = q.request.getVariable("mutgroup"$idx, "");
 		if (len(tmp) > 0)
 		{
 			if (currentMutators.find(tmp) == INDEX_NONE)
 			{
 				currentMutators.addItem(tmp);
 			}
 		}
 	}

	procCurrentChange(q, currentGameType, curmap, currentMutators, substMaps, substMutators, idx);
	//q.response.SendText("<result>");

	q.response.AddHeader("Content-Type: text/html");

	q.response.SendText("<select id=\"map\">");
	q.response.SendText(substMaps);
	q.response.SendText("</select>");

	q.response.SendText("<div id=\"mutators\">");
	q.response.SendText(substMutators);
	q.response.SendText("</div>");

	q.response.SendText("<input type=\"hidden\" id=\"mutatorGroupCount\" value=\""$idx$"\" />");

	//q.response.SendText("</result>");
}

function handleBots(WebAdminQuery q)
{
	local FactionCharacters facchar;
	local CharacterInfo ci1;
	local int i,j,k;
	local string sv1, sv2, tmp;
	local array<string> roster;
	local array<ActiveBotInfo> activeBots;
	local UTBot bot;
	local array<UTBot> bots;
	local array<string> activeRoster;

	if (factions.length == 0)
	{
		for (i = 0; i < class'UTCustomChar_Data'.default.Factions.Length; i++)
		{
			facchar.fi = class'UTCustomChar_Data'.default.Factions[i];
			facchar.factionName = class'WebAdminUtils'.static.getLocalized(class'UTCustomChar_Data'.default.Factions[i].FriendlyName);
			facchar.chars.Length = 0;
			for (j = 0; j < class'UTCustomChar_Data'.default.Characters.length; j++)
			{
				ci1 = class'UTCustomChar_Data'.default.Characters[j];
				if (ci1.Faction != facchar.fi.Faction)
				{
					continue;
				}
				for (k = 0; k < facchar.chars.Length; k++)
				{
					if (facchar.chars[k].CharName > ci1.CharName)
					{
						facchar.chars.insert(k, 1);
						facchar.chars[k] = ci1;
						break;
					}
				}
				if (k == facchar.chars.Length)
				{
					facchar.chars.AddItem(ci1);
				}
			}

			for (j = 0; j < factions.length; j++)
			{
				if (factions[j].factionName > facchar.factionName)
				{
					factions.Insert(j, 1);
					factions[j] = facchar;
					break;
				}
			}
			if (j == factions.length)
			{
				factions.AddItem(facchar);
			}
		}
	}

	sv1 = q.request.getVariable("action", "");

	if (sv1 ~= "addbots")
	{
		i = int(q.request.getVariable("numbots", "0"));
		if (i > 0)
		{
			UTGame(webadmin.WorldInfo.Game).AddBots(i);
			webadmin.addMessage(q, repl(msgAddingBots, "%d", string(i)));
		}
	}

	foreach webadmin.WorldInfo.AllControllers(class'UTBot', bot)
	{
		i = class'UTCustomChar_Data'.default.Characters.find('CharName', bot.PlayerReplicationInfo.PlayerName);
		if (i != INDEX_NONE)
		{
			ci1 = class'UTCustomChar_Data'.default.Characters[i];
			activeRoster.length = activeRoster.length+1;
			activeRoster[activeRoster.length-1] = ci1.Faction$"."$ci1.CharID;
		}
		bots.addItem(bot);
	}

	if (sv1 ~= "activation")
	{
		sv1 = "";
		foreach bots(bot)
		{
			i = class'UTCustomChar_Data'.default.Characters.find('CharName', bot.PlayerReplicationInfo.PlayerName);
			if (i != INDEX_NONE)
			{
				ci1 = class'UTCustomChar_Data'.default.Characters[i];
				sv2 = ci1.Faction$"."$ci1.CharID;
				if (q.request.getVariable(sv2) != "1")
				{
					if (len(sv1) > 0) sv1 $= ", ";
					sv1 $= ci1.CharName;
					UTGame(webadmin.WorldInfo.Game).DesiredPlayerCount = webadmin.WorldInfo.Game.NumPlayers + webadmin.WorldInfo.Game.NumBots-1;
					UTGame(webadmin.WorldInfo.Game).KillBot(bot);
					j = activeRoster.find(sv2);
					if (j != INDEX_NONE) activeRoster.Remove(j,1);
				}
			}
		}
		if (len(sv1) > 0)
		{
			webadmin.addMessage(q, msgRemovedBots@sv1);
		}
		bots.length = 0;

		sv1 = "";
		for (i = 0; i < class'UTCustomChar_Data'.default.Characters.length; i++)
		{
			ci1 = class'UTCustomChar_Data'.default.Characters[i];
			sv2 = ci1.Faction$"."$ci1.CharID;
			if (q.request.getVariable(sv2) == "1")
			{
				if (activeRoster.find(sv2) != INDEX_NONE)
				{
					continue;
				}
				if (UTGame(webadmin.WorldInfo.Game).AddNamedBot(ci1.CharName) != none)
				{
					if (len(sv1) > 0) sv1 $= ", ";
					sv1 $= ci1.CharName;
					activeRoster.AddItem(sv2);
				}
			}
		}
		if (len(sv1) > 0)
		{
			webadmin.addMessage(q, msgAddedBots@sv1);
		}
	}
	else if (sv1 ~= "roster")
	{
		ParseStringIntoArray(q.request.getVariable("botroster"), roster, chr(10), true);
		for (i = 0; i < roster.length; i++)
		{
			sv1 = `Trim(roster[i]);
			if (len(sv1) > 0)
			{
				activeBots.length = activeBots.length+1;
				activeBots[activeBots.length-1].BotName = sv1;
			}
		}
		class'UTGame'.default.ActiveBots = activeBots;
		class'UTGame'.StaticSaveConfig();
		if (UTGame(webadmin.worldinfo.Game) != none)
		{
			for (i = 0; i < activeBots.length; i++)
			{
				j = UTGame(webadmin.worldinfo.Game).ActiveBots.find('BotName', activeBots[i].BotName);
				if (j != INDEX_NONE)
				{
					activeBots[i].bInUse = UTGame(webadmin.worldinfo.Game).ActiveBots[j].bInUse;
				}
			}
			UTGame(webadmin.worldinfo.Game).ActiveBots = activeBots;
		}
		webadmin.addMessage(q, msgRostedSaved);
	}

	sv1 = "";
	for (i = 0; i < factions.length; i++)
	{
		q.response.subst("faction.id", factions[i].fi.Faction);
		q.response.subst("faction.name", `HTMLEscape(factions[i].factionName));
		q.response.subst("faction.description", `HTMLEscape(class'WebAdminUtils'.static.getLocalized(factions[i].fi.Description)));
		sv2 = "";
		for (j = 0; j < factions[i].chars.length; j++)
		{
			q.response.subst("char.id", factions[i].chars[j].CharID);
			q.response.subst("char.name", `HTMLEscape(factions[i].chars[j].CharName));
			q.response.subst("char.description", `HTMLEscape(class'WebAdminUtils'.static.getLocalized(factions[i].chars[j].Description)));
			tmp = factions[i].fi.Faction$"."$factions[i].chars[j].CharID;
			if (activeRoster.find(tmp) != INDEX_NONE)
			{
				q.response.subst("char.active", "checked=\"checked\"");
			}
			else {
				q.response.subst("char.active", "");
			}
			sv2 $= webadmin.include(q, "current_bots_character.inc");
		}
		q.response.subst("faction.characters", sv2);
		sv1 $= webadmin.include(q, "current_bots_faction.inc");
	}
	q.response.subst("factions", sv1);

	sv1 = "";
	if (UTGame(webadmin.worldinfo.Game) != none)
	{
		for (i = 0; i < UTGame(webadmin.worldinfo.Game).ActiveBots.Length; i++)
		{
			if (len(sv1) > 0) sv1 $= chr(10);
			sv1 $= UTGame(webadmin.worldinfo.Game).ActiveBots[i].BotName;
		}
	}
	else {
		for (i = 0; i < class'UTGame'.default.ActiveBots.Length; i++)
		{
			if (len(sv1) > 0) sv1 $= chr(10);
			sv1 $= class'UTGame'.default.ActiveBots[i].BotName;
		}
	}
	q.response.subst("activebots", sv1);
	q.response.subst("playerlimit", webadmin.worldinfo.game.MaxPlayers);

	webadmin.sendPage(q, "current_bots.html");
}

defaultproperties
{
	cssVisible=""
	cssHidden="display: none;"

    `if(`isdefined(BUILD_AS_MOD))
	// config
	ChatRefresh=5000
	bEnableTeamChat=true
	denyUrlOptions[0]="GamePassword"
	denyUrlOptions[1]="AdminPassword"
	denyUrlOptions[2]="Port"
	denyUrlOptions[3]="QueryPort"
	bConsoleEnabled=true
	bAdminConsoleCommandsHack=true
	AdminCommandHandlerClass="WebAdmin.AdminCommandHandler"
	denyConsoleCommands[0]="say"
	denyConsoleCommands[1]="obj"
	denyConsoleCommands[2]="debug"
	denyConsoleCommands[3]="flush"
	denyConsoleCommands[4]="set"
	denyConsoleCommands[5]="get engine.accesscontrol"
	`endif
}
