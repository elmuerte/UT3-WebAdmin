/**
 * Query Handler for changing the default settings. It will try to find settings
 * handles for all gametypes and mutators. Custom gametypes have to implement a
 * subclass of the Settings class as name it: <GameTypeClass>Settings.
 * for example the gametype: FooBarQuuxGame has a settings class
 * FooBarQuuxGameSettings. See "UTTeamGameSettings" for an example implementation.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class QHDefaults extends Object implements(IQueryHandler) config(WebAdmin);

`include(WebAdmin.uci)

struct ClassSettingsMapping
{
	var string className;
	var string settingsClass;
};
/**
 * Mapping for classname to settings class. Will be used to resolve classnames
 * for Settings classes that provide configuration possibilities for gametypes/
 * mutators when it can not be automatically found.
 */
var config array<ClassSettingsMapping> SettingsClasses;

/**
 * Settings class used for the general, server wide, settings
 */
var config string GeneralSettingsClass;

var WebAdmin webadmin;

var SettingsRenderer settingsRenderer;

function init(WebAdmin webapp)
{
	if (Len(GeneralSettingsClass) == 0)
	{
		GeneralSettingsClass = "WebAdmin.GeneralSettings";
		SaveConfig();
	}
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
		case "/settings":
			q.response.Redirect(WebAdmin.Path$"/settings/general");
			return true;
		case "/settings/general":
			handleSettingsGeneral(q);
			return true;
		case "/settings/general/passwords":
			handleSettingsPasswords(q);
			return true;
		case "/settings/gametypes":
			handleSettingsGametypes(q);
			return true;
		case "/settings/mutators":
			handleSettingsMutators(q);
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
	menu.addMenu("/settings/general", "General", self, "Change various server wide settings. These settings affect all game types.", 0);
	menu.addMenu("/settings/general/passwords", "Passwords", self, "Change the game and/or administration passwords.", 0);
	menu.addMenu("/settings/gametypes", "Gametypes", self, "Change the default settings of the gametypes.", 10);
	//menu.addMenu("/settings/mutators", "Mutators", self, "Change settings for mutators. Not all mutators can configurable.", 20);
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
					webadmin.addMessage(q, "<code>"$policy$"</code> is not a valid IP mask", MT_error);
					break;
				}
			}
			if (parts.length > 4 || parts.length < 1)
			{
				webadmin.addMessage(q, "<code>"$policy$"</code> is not a valid IP mask", MT_error);
				i = -1;
			}
			if (i == parts.length)
			{
				if (q.request.getVariable("policy") == "")
				{
					webadmin.addMessage(q, "Invalid policy selected.", MT_error);
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
		q.response.subst("policy.ipmask", `HTMLEscape(Mid(policy, idx+1)));
		q.response.subst("policy.policy", `HTMLEscape(Left(policy, idx)));
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
			webadmin.addMessage(q, "<code>"$action$"</code> is not a valid ID", MT_error);
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
		q.response.subst("ban.playername", `HTMLEscape(webadmin.worldinfo.game.accesscontrol.BannedPlayerInfo[i].PlayerName));
		q.response.subst("ban.timestamp", `HTMLEscape(webadmin.worldinfo.game.accesscontrol.BannedPlayerInfo[i].TimeStamp));
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
			webadmin.addMessage(q, "<code>"$action$"</code> is not a valid client hash", MT_error);
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
		q.response.subst("ban.playername", `HTMLEscape(webadmin.worldinfo.game.accesscontrol.BannedHashes[i].PlayerName));
		bans $= webadmin.include(q, "policy_hashbans_row.inc");
	}

	q.response.subst("bans", bans);
	webadmin.sendPage(q, "policy_hashbans.html");
}

/**
 * Try to find the settings class for the provided class
 */
function class<Settings> getSettingsClass(class forClass)
{
	local string className, settingsClass;
	local class<Settings> result;
	local int idx;

	if (forClass == none)
	{
		return none;
	}

	className = string(forClass);
	idx = settingsClasses.find('className', className);
	if (idx == INDEX_NONE)
	{
		className = forClass.getPackageName()$"."$string(forClass);
		idx = settingsClasses.find('className', className);
	}
	if (idx != INDEX_NONE)
	{
		result = class<Settings>(DynamicLoadObject(settingsClasses[idx].settingsClass, class'Class'));
		if (result == none)
		{
			`Log("Unable to load settings class "$settingsClasses[idx].settingsClass$" for the class "$settingsClasses[idx].className,,'WebAdmin');
		}
		else {
			return result;
		}
	}
	// try to find it automatically
	settingsClass = string(forClass.GetPackageName());
	// rewrite standard game classes to WebAdmin
	if (settingsClass != "UTGame") settingsClass = "WebAdmin";
	else if (settingsClass != "UTGameContent") settingsClass = "WebAdmin";
	settingsClass $= "."$string(forClass)$"Settings";
	result = class<Settings>(DynamicLoadObject(settingsClass, class'class', true));
	if (result != none)
	{
		return result;
	}
	// not in the same package, try the find the object (only works when it was loaded)
	result = class<Settings>(FindObject(string(forClass)$"Settings", class'class'));
	if (result == none)
	{
		`Log("Settings class "$settingsClass$" for class "$forClass$" not found (auto detection).",,'WebAdmin');
	}
	return result;
}

function handleSettingsGametypes(WebAdminQuery q)
{
	local string currentGameType, substvar;
	local UTUIDataProvider_GameModeInfo editGametype, gametype;
	local int idx;
	local class<Settings> settingsClass;
	local class<GameInfo> gi;
	local Settings settings;

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
 		q.response.subst("gametype.gamemode", `HTMLEscape(gametype.GameMode));
 		q.response.subst("gametype.friendlyname", `HTMLEscape(class'WebAdminUtils'.static.getLocalized(gametype.FriendlyName)));
 		q.response.subst("gametype.defaultmap", `HTMLEscape(gametype.DefaultMap));
 		q.response.subst("gametype.description", `HTMLEscape(class'WebAdminUtils'.static.getLocalized(gametype.Description)));
 		if (currentGameType ~= gametype.GameMode)
 		{
 			q.response.subst("editgametype.name", `HTMLEscape(class'WebAdminUtils'.static.getLocalized(gametype.FriendlyName)));
 			q.response.subst("editgametype.class", `HTMLEscape(gametype.GameMode));
 			q.response.subst("gametype.selected", "selected=\"selected\"");
 		}
 		else {
 			q.response.subst("gametype.selected", "");
 		}
 		substvar $= webadmin.include(q, "current_change_gametype.inc");
 	}
 	q.response.subst("gametypes", substvar);

	if (len(editGametype.GameMode) > 0)
	{
		gi = class<GameInfo>(DynamicLoadObject(editGametype.GameMode, class'class'));
		if (gi != none)
		{
			settingsClass = getSettingsClass(gi);
		}
		if (settingsClass != none)
		{
			// save this somewhere?
			settings = new settingsClass;
			settings.SetSpecialValue(`{WA_INIT_SETTINGS}, "");
		}
	}

	if (settings != none)
	{
		if (q.request.getVariable("action") ~= "save" || q.request.getVariable("action") ~= "save settings")
		{
			applySettings(settings, q.request);
			if (UTGame(WebAdmin.WorldInfo.Game) != none)
			{	// this prevents some saving of variables at a level change
				UTGame(WebAdmin.WorldInfo.Game).bAdminModifiedOptions = true;
			}
			settings.SetSpecialValue(`{WA_SAVE_SETTINGS}, "");
			webadmin.addMessage(q, "Settings saved.");
		}
		if (settingsRenderer == none)
		{
			settingsRenderer = new class'SettingsRenderer';
			settingsRenderer.init(webadmin.path);
		}
		settingsRenderer.render(settings, q.response);
	}
	else {
		webadmin.addMessage(q, "Unable to load a settings information for this game type.", MT_Warning);
	}

 	webadmin.sendPage(q, "default_settings_gametypes.html");
}

/**
 * Apply the settings received from the response to the settings instance
 */
function applySettings(Settings settings, WebRequest request, optional string prefix = "settings_")
{
	local int i, idx;
	local name sname;
	local string val;

	for (i = 0; i < settings.LocalizedSettingsMappings.Length; i++)
	{
		idx = settings.LocalizedSettingsMappings[i].Id;
		sname = settings.GetStringSettingName(idx);
		if (request.GetVariableCount(prefix$sname) > 0)
		{
			val = request.GetVariable(prefix$sname);
			settings.SetStringSettingValue(idx, int(val), false);
		}
	}
	for (i = 0; i < settings.PropertyMappings.Length; i++)
	{
		idx = settings.PropertyMappings[i].Id;
		sname = settings.GetPropertyName(idx);
		if (request.GetVariableCount(prefix$sname) > 0)
		{
			val = request.GetVariable(prefix$sname);
			settings.SetPropertyFromStringByName(sname, val);
		}
	}
}

function handleSettingsGeneral(WebAdminQuery q)
{
	local class<Settings> settingsClass;
	local Settings settings;

	settingsClass = class<Settings>(DynamicLoadObject(GeneralSettingsClass, class'class'));
	if (settingsClass != none)
	{
		// save this somewhere?
		settings = new settingsClass;
		settings.SetSpecialValue(`{WA_INIT_SETTINGS}, "");
	}

	if (settings != none)
	{
		if (q.request.getVariable("action") ~= "save" || q.request.getVariable("action") ~= "save settings")
		{
			applySettings(settings, q.request);
			if (UTGame(WebAdmin.WorldInfo.Game) != none)
			{	// this prevents some saving of variables at a level change
				UTGame(WebAdmin.WorldInfo.Game).bAdminModifiedOptions = true;
			}
			settings.SetSpecialValue(`{WA_SAVE_SETTINGS}, "");
			webadmin.addMessage(q, "Settings saved.");
		}
		if (settingsRenderer == none)
		{
			settingsRenderer = new class'SettingsRenderer';
			settingsRenderer.init(webadmin.path);
		}
		settingsRenderer.render(settings, q.response);
	}
	else {
		`Log("Failed to load the general settings class "$GeneralSettingsClass,,'WebAdmin');
		webadmin.addMessage(q, "Unable to load settings.", MT_Warning);
	}

 	webadmin.sendPage(q, "default_settings_general.html");
}

function handleSettingsPasswords(WebAdminQuery q)
{
	webadmin.sendPage(q, "default_settings_password.html");
}

function handleSettingsMutators(WebAdminQuery q)
{
	WebAdmin.pageGenericError(q, "Not yet implemented");
}
