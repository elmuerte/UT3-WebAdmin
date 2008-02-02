/**
 * The query handler that provides information about the current game. It will
 * also set the start page for the webadmin.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class QHCurrent extends Object implements(IQueryHandler) config(WebAdmin);

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

var string cssVisible;
var string cssHidden;

var array<PlayerReplicationInfo> sortedPRI;

function init(WebAdmin webapp)
{
	webadmin = webapp;
	if (len(webapp.startpage) == 0)
	{
		webapp.startpage = "/current";
	}
	if (ChatRefresh < 500) ChatRefresh = 5000;
}

function cleanup()
{
	webadmin = none;
	sortedPRI.Remove(0, sortedPRI.Length);
}

function registerMenuItems(WebAdminMenu menu)
{
	menu.addMenu("/current", "Current Game", self, "The current game status.", -100);
	menu.addMenu("/current/players", "Players", self, "Manage the players currently on the server.");
	menu.addMenu("/current/chat", "Chat console", self, "This console allows you to chat with the players on the server.");
	menu.addMenu("/current/chat/data", "", self);
	menu.addMenu("/current/change", "Change Game", self, "Change the current game.");
	menu.addMenu("/current/change/data", "", self);
	if (bConsoleEnabled)
	{
		menu.addMenu("/console", "Management Console", self,
			"Execute console commands as if they are directly entered on the console of the server."$
			"You may not have access to the same commands as you would when logged in as admin when playing on the server."
		);
	}
}

function bool handleQuery(WebAdminQuery q)
{
	switch (q.request.URI)
	{
		case "/current":
			handleCurrent(q);
			return true;
		case "/current/players":
			handleCurrentPlayers(q);
			return true;
		case "/current/chat":
			handleCurrentChat(q);
			return true;
		case "/current/chat/data":
			handleCurrentChatData(q);
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
	}
}

// not used here
function bool unhandledQuery(WebAdminQuery q);

function handleCurrent(WebAdminQuery q)
{
	local string players;
	local PlayerReplicationInfo pri;
	local int idx;

	q.response.subst("game.name", class'WebAdminUtils'.static.HTMLEscape(webadmin.WorldInfo.Game.GameName));
	q.response.subst("game.type", webadmin.WorldInfo.Game.class.getPackageName()$"."$webadmin.WorldInfo.Game.class);

	q.response.subst("map.title", class'WebAdminUtils'.static.HTMLEscape(webadmin.WorldInfo.Title));
	q.response.subst("map.author", class'WebAdminUtils'.static.HTMLEscape(webadmin.WorldInfo.Author));
	q.response.subst("map.name", webadmin.WorldInfo.GetPackageName());

	q.response.subst("rules.timelimit", webadmin.WorldInfo.Game.TimeLimit);
	q.response.subst("rules.goalscore", webadmin.WorldInfo.Game.GoalScore);
	q.response.subst("rules.maxlives", webadmin.WorldInfo.Game.MaxLives);

	q.response.subst("rules.maxspectators", webadmin.WorldInfo.Game.MaxSpectators);
	q.response.subst("rules.maxplayers", webadmin.WorldInfo.Game.MaxPlayers);

	q.response.subst("time.elapsed", webadmin.WorldInfo.Game.GameReplicationInfo.ElapsedTime);
	q.response.subst("time.remaining", webadmin.WorldInfo.Game.GameReplicationInfo.RemainingTime);

	q.response.subst("server.name", class'WebAdminUtils'.static.HTMLEscape(webadmin.WorldInfo.Game.GameReplicationInfo.ServerName));
	q.response.subst("server.admin.name", class'WebAdminUtils'.static.HTMLEscape(webadmin.WorldInfo.Game.GameReplicationInfo.AdminName));
	q.response.subst("server.admin.email", class'WebAdminUtils'.static.HTMLEscape(webadmin.WorldInfo.Game.GameReplicationInfo.AdminEmail));
	q.response.subst("server.motd", class'WebAdminUtils'.static.HTMLEscape(webadmin.WorldInfo.Game.GameReplicationInfo.MessageOfTheDay));

	buildSortedPRI(q.request.getVariable("sortby", "score"), q.request.getVariable("reverse", "true") ~= "true");
	foreach sortedPRI(pri, idx)
	{
		q.response.subst("evenodd", idx % 2);
		substPri(q, pri);
		players $= webadmin.include(q, "current_player_row.inc");
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

static function substPri(WebAdminQuery q, PlayerReplicationInfo pri)
{
	q.response.subst("player.playerid", pri.PlayerID);
	if (len(pri.PlayerName) == 0)
	{
		q.response.subst("player.name", class'WebAdminUtils'.static.HTMLEscape(pri.PlayerAlias));
	}
	else {
		q.response.subst("player.name", class'WebAdminUtils'.static.HTMLEscape(pri.PlayerName));
	}
	q.response.subst("player.playername", class'WebAdminUtils'.static.HTMLEscape(pri.PlayerName));
	q.response.subst("player.playeralias", class'WebAdminUtils'.static.HTMLEscape(pri.PlayerAlias));
	q.response.subst("player.score", int(pri.score));
	q.response.subst("player.deaths", int(pri.deaths));
	q.response.subst("player.ping", pri.ping);
	q.response.subst("player.lives", pri.numlives);
	q.response.subst("player.ranking", pri.playerranking);
	q.response.subst("player.teamid", pri.TeamID);
	if (pri.Team != none)
	{
		q.response.subst("player.teamcolor", class'WebAdminUtils'.static.ColorToHTMLColor(pri.Team.GetHUDColor()));
		q.response.subst("player.teamcolor2", class'WebAdminUtils'.static.ColorToHTMLColor(pri.Team.GetTextColor()));
		q.response.subst("player.teamname", class'WebAdminUtils'.static.HTMLEscape(pri.Team.GetHumanReadableName()));
	}
	else {
		q.response.subst("player.teamcolor", "transparent");
		q.response.subst("player.teamcolor2", "transparent");
		q.response.subst("player.teamname", "");
	}
	q.response.subst("player.admin", pri.bAdmin);
	q.response.subst("player.bot", pri.bBot);
	q.response.subst("player.spectator", pri.bIsSpectator);
	q.response.subst("player.kills", pri.kills);
	q.response.subst("player.starttime", pri.starttime);
}

function handleCurrentPlayers(WebAdminQuery q)
{
	local PlayerReplicationInfo PRI;
	local int idx;
	local string players, IP, action;
	local PlayerController PC;

	action = q.request.getVariable("action");
	if (action != "")
	{
		PRI = webadmin.WorldInfo.Game.GameReplicationInfo.FindPlayerByID(int(q.request.getVariable("playerid")));
		if (PRI == none)
		{
			q.response.subst("message", "Unable to find the requested player.");
		}
		else {
			PC = PlayerController(PRI.Owner);
			if ( NetConnection(PC.Player) == None )
			{
				PC = none;
			}
			if (PC == none)
			{
				q.response.subst("message", "No human player associated with this player.");
			}
			else {
				//`Log("Action = "$q.request.getVariable("action"));
				if (action ~= "banip" || action ~= "ban ip")
				{
					banByIP(PC);
				}
				else if (action ~= "banid" || action ~= "ban unique id")
				{
					banByID(PC);
				}
				if (!webadmin.WorldInfo.Game.AccessControl.KickPlayer(PC, webadmin.WorldInfo.Game.AccessControl.DefaultKickReason))
				{
					q.response.subst("message", "Unable to kick the player "$PRI.PlayerName$". Logged in admins can not be kicked.");
				}
				else {
					q.response.subst("message", "Player "$PRI.PlayerName$" was removed from the server.");
				}
			}
		}
	}

	buildSortedPRI(q.request.getVariable("sortby", "name"), q.request.getVariable("reverse", "") ~= "true", false);
	foreach sortedPRI(pri, idx)
	{
		PC = PlayerController(pri.owner);
		if (PC == none)
		{
			continue;
		}

		q.response.subst("evenodd", idx % 2);
		substPri(q, pri);
		IP = PC.GetPlayerNetworkAddress();
		IP = Left(IP, InStr(IP, ":"));
		q.response.subst("player.ip", IP);
		q.response.subst("player.uniqueid", class'OnlineSubsystem'.static.UniqueNetIdToString(pri.UniqueId));

		players $= webadmin.include(q, "current_players_row.inc");
	}
	q.response.subst("sorted."$q.request.getVariable("sortby", "name"), "sorted");
	if (!(q.request.getVariable("reverse", "") ~= "true"))
	{
		q.response.subst("reverse."$q.request.getVariable("sortby", "name"), "true");
	}

	q.response.subst("players", players);

	webadmin.sendPage(q, "current_players.html");
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

function handleCurrentChat(WebAdminQuery q)
{
	procChatData(q, 0, "chat.log");
	q.response.subst("chat.refresh", ChatRefresh);
	webadmin.sendPage(q, "current_chat.html");
}

function handleCurrentChatData(WebAdminQuery q)
{
	local string msg;

	msg = q.request.getVariable("message");
	if (len(msg) > 0)
	{
		webadmin.WorldInfo.Game.Broadcast(q.user.getPC(), msg, 'Say');
	}
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
		if (entry.type == 'say' || entry.type == 'teamsay')
		{
			template = "current_chat_msg.inc";
		}
		else {
			template = "current_chat_notice.inc";
		}

		q.response.subst("msg.username", class'WebAdminUtils'.static.HTMLEscape(entry.senderName));
		q.response.subst("msg.text", class'WebAdminUtils'.static.HTMLEscape(entry.message));
		if (entry.sender != none && entry.sender.Team != none)
		{
			q.response.subst("msg.teamcolor", class'WebAdminUtils'.static.ColorToHTMLColor(entry.sender.Team.TeamColor));
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
	cmd = q.request.getVariable("command");
	if (len(cmd) > 0)
	{
		result = webadmin.WorldInfo.Game.ConsoleCommand(cmd, false);
		q.response.subst("console.command", class'WebAdminUtils'.static.HTMLEscape(cmd));
		q.response.subst("console.results", class'WebAdminUtils'.static.HTMLEscape(result));
		q.response.subst("console.visible", cssVisible);
	}
	else {
		q.response.subst("console.command", "");
		q.response.subst("console.results", "");
		q.response.subst("console.visible", cssHidden);
	}
	webadmin.sendPage(q, "console.html");
}

function handleCurrentChange(WebAdminQuery q)
{
	local UTUIDataProvider_GameModeInfo gametype;
	local string currentGameType, curmap, curmiscurl;
	local array<string> currentMutators;
	local string substvar, substvar2, substvar3;
	local int idx, i, j, k;
	local array<UTUIDataProvider_MapInfo> maps;
	local array<MutatorGroup> mutators;
	local mutator mut;

 	webadmin.dataStoreCache.loadGameTypes();

 	currentGameType = q.request.getVariable("gametype");
 	curmap = q.request.getVariable("map");
 	curmiscurl = q.request.getVariable("urlextra", "");

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
 		substvar = curmap;
 		if (len(currentGameType) > 0) substvar $= "?game="$currentGameType;
 		if (currentMutators.length > 0)
 		{
 			JoinArray(currentMutators, substvar2, ",");
 			substvar $= "?mutator="$substvar2;
 		}
 		if (len(curmiscurl) > 0) substvar $= "?"$curmiscurl;

 		for (i = 0; i < denyUrlOptions.length; i++)
 		{
 			idx = InStr(substvar, "?"$denyUrlOptions[i]);
 			if (idx != INDEX_NONE)
 			{
 				j = InStr(mid(substvar, idx+1), "?");
 				if (j == INDEX_NONE)
 				{
 					substvar = Left(substvar, idx);
 				}
 				else {
 					substvar = Left(substvar, idx)$Mid(substvar, idx+j+1);
 				}
 			}
 		}

 		webadmin.pageGenericInfo(q, "<p>Chaning the current game with the following url:<br /><input type=\"text\" readonly=\"readonly\" value=\""$class'WebAdminUtils'.static.HTMLEscape(substvar)$"\" size=\"80\" class=\"monospace\"/></p><p>Please wait, this could take a little while.", "Changing game");
 		webadmin.WorldInfo.ServerTravel(substvar);
 		return;
 	}

 	if (currentGameType == "")
 	{
 		currentGameType = string(webadmin.WorldInfo.Game.class);
 		curmap = string(webadmin.WorldInfo.GetPackageName());
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
 		q.response.subst("gametype.gamemode", class'WebAdminUtils'.static.HTMLEscape(gametype.GameMode));
 		q.response.subst("gametype.friendlyname", class'WebAdminUtils'.static.HTMLEscape(class'WebAdminUtils'.static.getLocalized(gametype.FriendlyName)));
 		q.response.subst("gametype.defaultmap", class'WebAdminUtils'.static.HTMLEscape(gametype.DefaultMap));
 		q.response.subst("gametype.description", class'WebAdminUtils'.static.HTMLEscape(class'WebAdminUtils'.static.getLocalized(gametype.Description)));
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

	substvar = "";
 	if (currentGameType != "")
 	{
 		maps = webadmin.dataStoreCache.getMaps(currentGameType);
 		for (i = 0; i < maps.length; i++)
 		{
			q.response.subst("map.mapname", class'WebAdminUtils'.static.HTMLEscape(maps[i].MapName));
 			q.response.subst("map.friendlyname", class'WebAdminUtils'.static.HTMLEscape(class'WebAdminUtils'.static.getLocalized(maps[i].FriendlyName)));
 			q.response.subst("map.mapid", string(maps[i].MapID));
 			q.response.subst("map.numplayers", class'WebAdminUtils'.static.HTMLEscape(class'WebAdminUtils'.static.getLocalized(maps[i].NumPlayers)));
 			q.response.subst("map.description", class'WebAdminUtils'.static.HTMLEscape(class'WebAdminUtils'.static.getLocalized(maps[i].Description)));
	 		if (curmap ~= maps[i].MapName)
 			{
 				q.response.subst("map.selected", "selected=\"selected\"");
	 		}
 			else {
 				q.response.subst("map.selected", "");
	 		}
 			substvar $= webadmin.include(q, "current_change_map.inc");
 		}
 	}
 	q.response.subst("maps", substvar);

	substvar = "";
 	if (currentGameType != "")
 	{
 		mutators = webadmin.dataStoreCache.getMutators(currentGameType);
 		idx = 0;
 		for (i = 0; i < mutators.length; i++)
 		{
 			if (mutators[i].mutators.Length == 1)
 			{
 				q.response.subst("mutator.formtype", "checkbox");
 				q.response.subst("mutator.groupid", "mutgroup"$i);
 				q.response.subst("mutator.classname", class'WebAdminUtils'.static.HTMLEscape(mutators[i].mutators[0].ClassName));
 				q.response.subst("mutator.id", "mutfield"$(++idx));
 				q.response.subst("mutator.friendlyname", class'WebAdminUtils'.static.HTMLEscape(mutators[i].mutators[0].FriendlyName));
 				q.response.subst("mutator.description", class'WebAdminUtils'.static.HTMLEscape(mutators[i].mutators[0].Description));
 				if (currentMutators.find(mutators[i].mutators[0].ClassName) != INDEX_NONE)
 				{
 					q.response.subst("mutator.selected", "checked=\"checked\"");
		 		}
 				else {
		 			q.response.subst("mutator.selected", "");
 				}
 				substvar3 $= webadmin.include(q, "current_change_mutator.inc");
 			}
 			else {
 				substvar2 = "";
 				k = INDEX_NONE;

	 			for (j = 0; j < mutators[i].mutators.Length; j++)
 				{
 					q.response.subst("mutator.formtype", "radio");
	 				q.response.subst("mutator.groupid", "mutgroup"$i);
 					q.response.subst("mutator.classname", class'WebAdminUtils'.static.HTMLEscape(mutators[i].mutators[j].ClassName));
 					q.response.subst("mutator.id", "mutfield"$(++idx));
 					q.response.subst("mutator.friendlyname", class'WebAdminUtils'.static.HTMLEscape(mutators[i].mutators[j].FriendlyName));
 					q.response.subst("mutator.description", class'WebAdminUtils'.static.HTMLEscape(mutators[i].mutators[j].Description));
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
	 			substvar $= webadmin.include(q, "current_change_mutator_group.inc");
	 		}
 		}
 		if (len(substvar3) > 0)
 		{
 			q.response.subst("group.id", "mutgroup0");
	 		q.response.subst("group.name", "");
 			q.response.subst("group.mutators", substvar3);
 			substvar = webadmin.include(q, "current_change_mutator_nogroup.inc")$substvar;
 		}
 	}
 	q.response.subst("mutators", substvar);
 	q.response.subst("mutator.groups", mutators.Length);

	q.response.subst("urlextra", curmiscurl);
	Joinarray(denyUrlOptions, substvar, ", ", true);
	q.response.subst("urlextra.deny", substvar);

	webadmin.sendPage(q, "current_change.html");
}

function procCurrentChange(WebAdminQuery q, string currentGameType, string curmap, array<string>currentMutators,
	out string maps, out string mutators, out int mutatorGroups)
{
}

function handleCurrentChangeData(WebAdminQuery q)
{
	local string currentGameType, curmap;
	local array<UTUIDataProvider_MapInfo> maps;
	local int i;

	currentGameType = q.request.getVariable("gametype");

	if (currentGameType != "")
 	{
 		webadmin.dataStoreCache.loadGameTypes();
 		i = webadmin.dataStoreCache.resolveGameType(currentGameType);
	 	if (i > INDEX_NONE)
 		{
 			curmap = webadmin.dataStoreCache.gametypes[i].DefaultMap;
 		}
 		maps = webadmin.dataStoreCache.getMaps(currentGameType);
 		for (i = 0; i < maps.length; i++)
 		{
			q.response.subst("map.mapname", class'WebAdminUtils'.static.HTMLEscape(maps[i].MapName));
 			q.response.subst("map.friendlyname", class'WebAdminUtils'.static.HTMLEscape(class'WebAdminUtils'.static.getLocalized(maps[i].FriendlyName)));
 			q.response.subst("map.mapid", string(maps[i].MapID));
 			q.response.subst("map.numplayers", class'WebAdminUtils'.static.HTMLEscape(class'WebAdminUtils'.static.getLocalized(maps[i].NumPlayers)));
 			q.response.subst("map.description", class'WebAdminUtils'.static.HTMLEscape(class'WebAdminUtils'.static.getLocalized(maps[i].Description)));
	 		if (curmap ~= maps[i].MapName)
 			{
 				q.response.subst("map.selected", "selected=\"selected\"");
	 		}
 			else {
 				q.response.subst("map.selected", "");
	 		}
 			q.response.SendText(webadmin.include(q, "current_change_map.inc"));
 		}
 	}
}

defaultproperties
{
	cssVisible=""
	cssHidden="display: none;"
}