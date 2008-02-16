/**
 * Query Handler for chaning the default settings
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class QHDefaults extends Object implements(IQueryHandler) config(WebAdmin);

`include(WebAdmin.uci)

var WebAdmin webadmin;

var SettingsRenderer settingsRenderer;

function init(WebAdmin webapp)
{
	webadmin = webapp;
}

function cleanup()
{
	webadmin = none;
	settingsRenderer = none;
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
		case "/policy/hashbans":
			handleHashBans(q);
			return true;
		case "/settings/gametypes":
			handleSettingsGametypes(q);
			return true;
	}
	return false;
}

function bool unhandledQuery(WebAdminQuery q);

function registerMenuItems(WebAdminMenu menu)
{
	menu.addMenu("/policy", "Access Policy", self, "Change the IP policies that determine who can join the server.");
	menu.addMenu("/policy/bans", "Banned IDs", self, "Change account ban records. These record ban a single online account.");
	menu.addMenu("/policy/hashbans", "Banned Hashes", self, "Change client ban records. These records ban a single copy of the game.");
	menu.addMenu("/settings", "Settings", self);
	menu.addMenu("/settings/gametypes", "Gametypes", self, "Change the default settings of the gametypes.");
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

function handleHashBans(WebAdminQuery q)
{
	local string bans, action;
	local int i;
	local BannedHashInfo NewBanInfo;

	action = q.request.getVariable("action");
	if (action ~= "delete")
	{
		i = int(q.request.getVariable("banid"));
		if (i > -1 && i < webadmin.worldinfo.game.accesscontrol.BannedHashes.Length)
		{
			webadmin.worldinfo.game.accesscontrol.BannedHashes.Remove(i, 1);
			webadmin.worldinfo.game.accesscontrol.SaveConfig();
		}
	}
	else if (action ~= "add")
	{
		action = q.request.getVariable("hashresponse");
		action -= " ";
		if (action == "0")
		{
			q.response.subst("message", "<code>"$action$"</code> is not a valid client hash");
		}
		else {
			NewBanInfo.BannedHash = action;
			NewBanInfo.playername = q.request.getVariable("playername");
			webadmin.worldinfo.game.accesscontrol.BannedHashes.AddItem(NewBanInfo);
			webadmin.worldinfo.game.accesscontrol.SaveConfig();
		}
	}

	for (i = 0; i < webadmin.worldinfo.game.accesscontrol.BannedHashes.Length; i++)
	{
		q.response.subst("ban.banid", ""$i);
		q.response.subst("ban.hash", webadmin.worldinfo.game.accesscontrol.BannedHashes[i].BannedHash);
		q.response.subst("ban.playername", class'WebAdminUtils'.static.HTMLEscape(webadmin.worldinfo.game.accesscontrol.BannedHashes[i].PlayerName));
		bans $= webadmin.include(q, "policy_hashbans_row.inc");
	}

	q.response.subst("bans", bans);
	webadmin.sendPage(q, "policy_hashbans.html");
}


function handleSettingsGametypes(WebAdminQuery q)
{
	local string currentGameType, substvar;
	local UTUIDataProvider_GameModeInfo editGametype, gametype;
	local int idx;
	local class<Settings> settingsClass;
	local class<GameInfo> gi;
	local Settings settings;
//	local SettingsPropertyPropertyMetaData prop;
//	local LocalizedStringSettingMetaData locprop;

	currentGameType = q.request.getVariable("gametype");
	if (currentGameType == "")
 	{
 		currentGameType = string(webadmin.WorldInfo.Game.class);
 	}
 	webadmin.dataStoreCache.loadGameTypes();
 	idx = webadmin.dataStoreCache.resolveGameType(currentGameType);
 	if (idx > INDEX_NONE)
 	{
 		editGametype = webadmin.dataStoreCache.gametypes[idx];
 		currentGameType = editGametype.GameMode;
 	}
 	else {
 		editGametype = none;
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

	`log(editGametype.GameSettingsClass);
	if (len(editGametype.GameMode) > 0)
	{
		gi = class<GameInfo>(DynamicLoadObject(editGametype.GameMode, class'class'));
		if (gi != none)
		{
			settingsClass = gi.default.OnlineGameSettingsClass;
		}
		if (settingsClass != none)
		{
			settings = new settingsClass;
		}
	}
	`log("settings = "$settings);

	if (settings != none)
	{
		/*
		for (idx = 0; idx < settings.PropertyMappings.length; idx++)
		{
			prop = settings.PropertyMappings[idx];
			`log(prop.Id@prop.Name@prop.ColumnHeaderText);
			`log("  "$settings.GetPropertyAsString(prop.id));
			`log("  "$prop.MappingType);
		}
		for (idx = 0; idx < settings.LocalizedSettingsMappings.length; idx++)
		{
			locprop = settings.LocalizedSettingsMappings[idx];
			`log(locprop.Id@locprop.Name@locprop.ColumnHeaderText);
			`log("  "$settings.GetPropertyAsString(locprop.id));
		}
		*/

		if (settingsRenderer == none)
		{
			settingsRenderer = new class'SettingsRenderer';
			settingsRenderer.init(webadmin.path);
		}
		settingsRenderer.render(settings, q.request, q.response);
	}

 	webadmin.sendPage(q, "default_settings_gametypes.html");
}
