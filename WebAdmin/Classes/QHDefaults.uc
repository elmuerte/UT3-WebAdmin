/**
 * Query Handler for chaning the default settings
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class QHDefaults extends Object implements(IQueryHandler) config(WebAdmin);

var WebAdmin webadmin;

function init(WebAdmin webapp)
{
	webadmin = webapp;
}

function cleanup()
{
	webadmin = none;
}

function bool handleQuery(WebAdminQuery q)
{
	switch (q.request.URI)
	{
		case "/policy":
			handleIPPolicy(q);
			return true;
		case "/policy/bans":
			handleBans(q);
			return true;
	}
}

function bool unhandledQuery(WebAdminQuery q);

function registerMenuItems(WebAdminMenu menu)
{
	menu.addMenu("/policy", "Access Policy", self, "Change the IP policies that determine who can join the server.");
	menu.addMenu("/policy/bans", "Bans", self, "Change ban records.");
}

function handleIPPolicy(WebAdminQuery q)
{
	local string policies;
	local string policy, action;
	local array<string> parts;
	local int i, idx;

	action = q.request.getVariable("action");
	if (action != "")
	{
		//`Log("Action = "$action);
		if (action ~= "delete")
		{
			idx = int(q.request.getVariable("policyid"));
			if (idx > -1 && idx < webadmin.worldinfo.game.accesscontrol.IPPolicies.length)
			{
				webadmin.worldinfo.game.accesscontrol.IPPolicies.Remove(idx, 1);
				webadmin.worldinfo.game.accesscontrol.SaveConfig();
			}
		}
		else {
			policy = q.request.getVariable("ipmask");
			policy -= " ";
			ParseStringIntoArray(policy, parts, ".", false);
			for (i = 0; i < parts.length; i++)
			{
				if (parts[i] == "*")
				{
					continue;
				}
				if (parts[i] != string(int(parts[i])) || int(parts[i]) > 255 || int(parts[i]) < 0 )
				{
					q.response.subst("message", "<code>"$policy$"</code> is not a valid IP mask");
					break;
				}
			}
			if (parts.length > 4 || parts.length < 1)
			{
				q.response.subst("message", "<code>"$policy$"</code> is not a valid IP mask");
				i = -1;
			}
			if (i == parts.length)
			{
				if (q.request.getVariable("policy") == "")
				{
					q.response.subst("message", "Invalid policy selected.");
				}
				else {
					policy = q.request.getVariable("policy")$","$policy;
					if (q.request.getVariable("policyid") == "")
					{
						webadmin.worldinfo.game.accesscontrol.IPPolicies.AddItem(policy);
					}
					else {
						idx = int(q.request.getVariable("policyid"));
						if (idx < -1 || idx > webadmin.worldinfo.game.accesscontrol.IPPolicies.length)
						{
							idx = webadmin.worldinfo.game.accesscontrol.IPPolicies.length;
						}
						webadmin.worldinfo.game.accesscontrol.IPPolicies[idx] = policy;
					}
					webadmin.worldinfo.game.accesscontrol.SaveConfig();
				}
			}
		}
	}

	for (i = 0; i < webadmin.worldinfo.game.accesscontrol.IPPolicies.length; i++)
	{
		q.response.subst("policy.id", ""$i);
		policy = webadmin.worldinfo.game.accesscontrol.IPPolicies[i];
		idx = InStr(policy, ",");
		if (idx == INDEX_NONE) idx = InStr(policy, ";");
		q.response.subst("policy.ipmask", class'WebAdminUtils'.static.HTMLEscape(Mid(policy, idx+1)));
		q.response.subst("policy.policy", class'WebAdminUtils'.static.HTMLEscape(Left(policy, idx)));
		q.response.subst("policy.selected."$Caps(Left(policy, idx)), "selected=\"selected\"");
		policies $= webadmin.include(q, "policy_row.inc");
		q.response.subst("policy.selected."$Caps(Left(policy, idx)), "");
	}

	q.response.subst("policies", policies);
	webadmin.sendPage(q, "policy.html");
}

function handleBans(WebAdminQuery q)
{
	local string bans, action;
	local int i;
	local BannedInfo NewBanInfo;
	local UniqueNetId unid;

	action = q.request.getVariable("action");
	if (action ~= "delete")
	{
		action = q.request.getVariable("banid");
		i = InStr(action, "legacy:");
		if (i == INDEX_NONE)
		{
			i = int(action);
			if (i > -1 && i < webadmin.worldinfo.game.accesscontrol.BannedPlayerInfo.Length)
			{
				webadmin.worldinfo.game.accesscontrol.BannedPlayerInfo.Remove(i, 1);
				webadmin.worldinfo.game.accesscontrol.SaveConfig();
			}
		}
		else {
			i = int(Mid(action, i+1));
			if (i > -1 && i < webadmin.worldinfo.game.accesscontrol.BannedIDs.Length)
			{
				webadmin.worldinfo.game.accesscontrol.BannedIDs.Remove(i, 1);
				webadmin.worldinfo.game.accesscontrol.SaveConfig();
			}
		}
	}
	else if (action ~= "add")
	{
		action = q.request.getVariable("uniqueid");
		action -= " ";
		if (action != string(int(action)))
		{
			q.response.subst("message", "<code>"$action$"</code> is not a valid ID");
		}
		else {
			class'OnlineSubsystem'.static.StringToUniqueNetId(action, NewBanInfo.BannedID);
			NewBanInfo.playername = q.request.getVariable("playername");
			NewBanInfo.TimeStamp = timestamp();
			webadmin.worldinfo.game.accesscontrol.BannedPlayerInfo.AddItem(NewBanInfo);
			webadmin.worldinfo.game.accesscontrol.SaveConfig();
		}
	}

	for (i = 0; i < webadmin.worldinfo.game.accesscontrol.BannedPlayerInfo.Length; i++)
	{
		q.response.subst("ban.banid", ""$i);
		unid = webadmin.worldinfo.game.accesscontrol.BannedPlayerInfo[i].BannedID;
		q.response.subst("ban.uniqueid", class'OnlineSubsystem'.static.UniqueNetIdToString(unid));
		q.response.subst("ban.playername", class'WebAdminUtils'.static.HTMLEscape(webadmin.worldinfo.game.accesscontrol.BannedPlayerInfo[i].PlayerName));
		q.response.subst("ban.timestamp", class'WebAdminUtils'.static.HTMLEscape(webadmin.worldinfo.game.accesscontrol.BannedPlayerInfo[i].TimeStamp));
		bans $= webadmin.include(q, "policy_bans_row.inc");
	}

	for (i = 0; i < webadmin.worldinfo.game.accesscontrol.BannedIDs.Length; i++)
	{
		q.response.subst("ban.banid", "legacy:"$i);
		unid = webadmin.worldinfo.game.accesscontrol.BannedIDs[i];
		q.response.subst("ban.uniqueid", class'OnlineSubsystem'.static.UniqueNetIdToString(unid));
		q.response.subst("ban.playername", "");
		q.response.subst("ban.timestamp", "");
		bans $= webadmin.include(q, "policy_bans_row.inc");
	}

	q.response.subst("bans", bans);
	webadmin.sendPage(q, "policy_bans.html");
}
