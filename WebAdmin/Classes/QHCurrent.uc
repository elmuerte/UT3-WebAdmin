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

var string cssVisible;
var string cssHidden;

function init(WebAdmin webapp)
{
	webadmin = webapp;
	if (len(webapp.startpage) == 0)
	{
		webapp.startpage = "/current";
	}
	if (ChatRefresh < 1000) ChatRefresh = 5000;
}

function cleanup()
{
	webadmin = none;
}

function registerMenuItems(WebAdminMenu menu)
{
	menu.addMenu("/current", "Current Game", self, "Show the current game status.", -100);
	menu.addMenu("/current/players", "Players", self, "The players currently on the server.");
	menu.addMenu("/current/chat", "Chat console", self, "This console allows you to chat with the players on the server.");
	menu.addMenu("/current/chat/data", "", self);
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
	}
}

// not used here
function bool unhandledQuery(WebAdminQuery q);

function handleCurrent(WebAdminQuery q)
{

	webadmin.sendPage(q,"current.html");
}

function handleCurrentPlayers(WebAdminQuery q)
{

	webadmin.sendPage(q, "current_players.html");
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

	q.user.messageHistory(history, startFrom);

	foreach history(entry)
	{
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
			q.response.SendText(webadmin.include(q, "current_chat_msg.inc"));
		}
		else {
			result $= webadmin.include(q, "current_chat_msg.inc");
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
		result = webadmin.WorldInfo.Game.ConsoleCommand(cmd);
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

defaultproperties
{
	cssVisible=""
	cssHidden="display: none;"
}