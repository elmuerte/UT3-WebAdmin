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
class QHDefaults extends Object implements(IQueryHandler) config(WebAdmin)
	dependson(WebAdminUtils);

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

struct HasSettingsClass
{
	var string className;
	var bool hasSettings;
};
var config array<HasSettingsClass> HasSettingsCache;

struct ClassSettingsCacheEntry
{
	var string cls;
	var class<Settings> settingsCls;
};
var array<ClassSettingsCacheEntry> classSettingsCache;

struct SettingsInstance
{
	var class<Settings> cls;
	var Settings instance;
};
var array<SettingsInstance> settingsInstances;

/**
 * Settings class used for the general, server wide, settings
 */
var config string GeneralSettingsClass;

var WebAdmin webadmin;

var SettingsRenderer settingsRenderer;

var config string AdditionalMLClass;

var `if(`WITH_VOTING_1_4)deprecated`endif
	AdditionalMapLists additionalML;

var SettingsMagic settingsMagic;

//!localized
var localized string menuPolicy, menuPolicyDesc, menuBannedId, menuBannedIdDesc,
	menuBannedHash, menuBannedHashDesc, menuSession, menuSessionDesc, menuSettings,
	menuGeneral, menuGeneralDesc, menuPassword, menuPasswordDesc, menuGametypes,
	menuGametypesDesc, menuMutators, menuMutatorsDesc, menuMapCycles, menuMapCyclesDesc,
	menuMLAddition, menuMLAdditionDesc, msgSettingsCacheDesc, msgRemovedPolicy,
	msgNoValidIpMask, msgInvalidPolicy, msgAddedPolicy, msdUpdatedPolicy,
	msgNoValidId, msgAddedBanId, msgNoValidHash, msgBannedHash, msgRemovedSessionBan,
	msgSettingsSaved, msgCantSaveSettings, msgCantLoadSettings, msgGamePWError,
	msgGamePWSaved, msgAdminPWError, msgAdminPWSaved, msgAdminPWEmpty,
	msgMapCycleSaved, msgCantLoadGT, msgImportedMapList, msgInvalidMaplist,
	Untitled, msgCantFindMapCycle, msgCycleDeleted, msgCycleSaved, msgCycleActivated,
	menuServerActors, menuServerActorsDesc, msgServerActorsSaved, msgServerActorsSavedWarn;

function init(WebAdmin webapp)
{
	if (Len(GeneralSettingsClass) == 0)
	{
		GeneralSettingsClass = class.getPackageName()$".GeneralSettings";
		SaveConfig();
	}
	`if(`WITH_VOTING_1_3)
	if (Len(AdditionalMLClass) == 0)
	{
		AdditionalMLClass = class.getPackageName()$".AdditionalMapLists";
		SaveConfig();
	}
	`endif
	webadmin = webapp;
}

function cleanup()
{
	local int i;
	if (settingsMagic != none)
	{
		settingsMagic.cleanup();
	}
	settingsMagic = none;
	webadmin = none;
	settingsRenderer = none;
	for (i = 0; i < settingsInstances.length; i++)
	{
		if (IAdvWebAdminSettings(settingsInstances[i].instance) != none)
		{
			IAdvWebAdminSettings(settingsInstances[i].instance).cleanup();
		}
		else if (settingsInstances[i].instance != none)
		{
			settingsInstances[i].instance.SetSpecialValue(`{WA_CLEANUP_SETTINGS}, "");
		}
	}
	settingsInstances.Length = 0;
}

function bool producesXhtml()
{
	return true;
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
		`if(`WITH_BANCDHASH)
		case "/policy/hashbans":
			handleHashBans(q);
			return true;
		`endif
		`if(`WITH_SESSION_BAN)
		case "/policy/session":
			handleSessionBans(q);
			return true;
		`endif
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
		`if(`WITH_VOTING_1_3)
		case "/settings/maplist":
			handleMapList(q);
			return true;
		case "/settings/maplist/additional":
			handleMapListAdditional(q);
			return true;
		`endif
		case "/system/settingscache":
			handleRebuildSettingsCache(q);
			return true;
		case "/settings/serveractors":
			handleServerActors(q);
			return true;
	}
	return false;
}

function bool unhandledQuery(WebAdminQuery q);

function registerMenuItems(WebAdminMenu menu)
{
	menu.addMenu("/policy", menuPolicy, self, menuPolicyDesc);
	menu.addMenu("/policy/bans", menuBannedId, self, menuBannedIdDesc);
	`if(`WITH_BANCDHASH)
	menu.addMenu("/policy/hashbans", menuBannedHash, self, menuBannedHashDesc);
	`endif
	`if(`WITH_SESSION_BAN)
	menu.addMenu("/policy/session", menuSession, self, menuSessionDesc);
	`endif
	menu.addMenu("/settings", menuSettings, self);
	menu.addMenu("/settings/general", menuGeneral, self, menuGeneralDesc, -10);
	menu.addMenu("/settings/general/passwords", menuPassword, self, menuPasswordDesc);
	menu.addMenu("/settings/gametypes", menuGametypes, self, menuGametypesDesc);
	menu.addMenu("/settings/mutators", menuMutators, self, menuMutatorsDesc);
	`if(`WITH_VOTING_1_3)
	menu.addMenu("/settings/maplist", menuMapCycles, self, menuMapCyclesDesc);
	menu.addMenu("/settings/maplist/additional", menuMLAddition, self, menuMLAdditionDesc);
	`endif
	menu.addMenu("/settings/serveractors", menuServerActors, self, menuServerActorsDesc);
	menu.addMenu("/system/settingscache", "", self, msgSettingsCacheDesc);
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
		idx = -1;
		if (action ~= "modify")
		{
			if (q.request.getVariable("delete") != "")
			{
				idx = int(q.request.getVariable("delete"));
				action = "delete";
			}
			else if (q.request.getVariable("update") != "")
			{
				idx = int(q.request.getVariable("update"));
				action = "update";
			}
		}

		//`Log("Action = "$action);
		if (action ~= "delete")
		{
			if (idx > -1 && idx < webadmin.worldinfo.game.accesscontrol.IPPolicies.length)
			{
				policy = webadmin.worldinfo.game.accesscontrol.IPPolicies[idx];
				webadmin.worldinfo.game.accesscontrol.IPPolicies.Remove(idx, 1);
				webadmin.worldinfo.game.accesscontrol.SaveConfig();
				webadmin.addMessage(q, msgRemovedPolicy@policy);
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
					webadmin.addMessage(q, repl(msgNoValidIpMask, "%s", "<code>"$policy$"</code>"), MT_error);
					break;
				}
			}
			if (parts.length > 4 || parts.length < 1)
			{
				webadmin.addMessage(q, repl(msgNoValidIpMask, "%s", "<code>"$policy$"</code>"), MT_error);
				i = -1;
			}
			if (i == parts.length)
			{
				if (q.request.getVariable("policy") == "")
				{
					webadmin.addMessage(q, msgInvalidPolicy, MT_error);
				}
				else {
					policy = q.request.getVariable("policy")$","$policy;
					if (idx == -1)
					{
						webadmin.worldinfo.game.accesscontrol.IPPolicies.AddItem(policy);
						webadmin.addMessage(q, msgAddedPolicy@policy);
					}
					else {
						if (idx < -1 || idx > webadmin.worldinfo.game.accesscontrol.IPPolicies.length)
						{
							idx = webadmin.worldinfo.game.accesscontrol.IPPolicies.length;
						}
						webadmin.worldinfo.game.accesscontrol.IPPolicies[idx] = policy;
						webadmin.addMessage(q, msdUpdatedPolicy@policy);
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
			webadmin.addMessage(q, repl(msgNoValidId, "%s", "<code>"$action$"</code>"), MT_error);
		}
		else {
			class'OnlineSubsystem'.static.StringToUniqueNetId(action, NewBanInfo.BannedID);
			NewBanInfo.playername = q.request.getVariable("playername");
			NewBanInfo.TimeStamp = timestamp();
			webadmin.worldinfo.game.accesscontrol.BannedPlayerInfo.AddItem(NewBanInfo);
			webadmin.worldinfo.game.accesscontrol.SaveConfig();
			webadmin.addMessage(q, msgAddedBanId@action);
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

`if(`WITH_BANCDHASH)
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
			webadmin.addMessage(q, repl(msgNoValidHash, "%s", "<code>"$action$"</code>"), MT_error);
		}
		else {
			NewBanInfo.BannedHash = action;
			NewBanInfo.playername = q.request.getVariable("playername");
			webadmin.worldinfo.game.accesscontrol.BannedHashes.AddItem(NewBanInfo);
			webadmin.worldinfo.game.accesscontrol.SaveConfig();
			webadmin.addMessage(q, msgBannedHash@action);
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
`endif

`if(`WITH_SESSION_BAN)
function handleSessionBans(WebAdminQuery q)
{
	local UniqueNetId unid, empty;
	local string bans, tmp;
	local int i;
	local SessionBanInfo sbi;

	if (q.request.getVariable("action") ~= "revoke")
	{
		i = int(q.request.getVariable("banid", "-1"));
		if (i > -1 && i < webadmin.worldinfo.game.accesscontrol.SessionBans.length)
		{
			sbi = webadmin.worldinfo.game.accesscontrol.SessionBans[i];
			webadmin.worldinfo.game.accesscontrol.SessionBans.remove(i, 1);
			unid = sbi.BanID;
			webadmin.addMessage(q, repl(repl(repl(msgRemovedSessionBan, "%1", class'OnlineSubsystem'.static.UniqueNetIdToString(unid)), "%2", sbi.BanHash), "%3", sbi.BanIP));
		}
	}

	for (i = 0; i < webadmin.worldinfo.game.accesscontrol.SessionBans.Length; i++)
	{
		q.response.subst("ban.banid", i);
		unid = webadmin.worldinfo.game.accesscontrol.SessionBans[i].BanID;
		if (empty == unid)
		{
			q.response.subst("ban.uniqueid", "");
			q.response.subst("ban.uniqueid.visible", "display: none");
		}
		else {
			q.response.subst("ban.uniqueid", class'OnlineSubsystem'.static.UniqueNetIdToString(unid));
			if (webadmin.worldinfo.game.accesscontrol.BannedPlayerInfo.find('BannedID', unid) != INDEX_NONE)
			{
				q.response.subst("ban.uniqueid.visible", "display: none");
			}
			else {
				q.response.subst("ban.uniqueid.visible", "");
			}
		}
		tmp = webadmin.worldinfo.game.accesscontrol.SessionBans[i].BanHash;
		q.response.subst("ban.hash", tmp);
		if (tmp == "" || webadmin.worldinfo.game.accesscontrol.BannedHashes.find('BannedHash', tmp) != INDEX_NONE)
		{
			q.response.subst("ban.hash.visible", "display: none");
		}
		else {
			q.response.subst("ban.hash.visible", "");
		}
		q.response.subst("ban.ip", `HTMLEscape(webadmin.worldinfo.game.accesscontrol.SessionBans[i].BanIP));
		bans $= webadmin.include(q, "policy_session_row.inc");
	}
	q.response.subst("bans", bans);
	webadmin.sendPage(q, "policy_session.html");
}
`endif

function handleRebuildSettingsCache(WebAdminQuery q)
{
	local array<UTUIDataProvider_GameModeInfo> gts;
	local int i;

	if (q.request.getVariable("action") ~= "rebuild")
	{
		HasSettingsCache.length = 0;
		gts = webadmin.dataStoreCache.getGameTypes();
		for (i = 0; i < gts.length; i++)
		{
			HasSettings(gts[i].GameMode);
		}
		webadmin.dataStoreCache.loadMutators();
		for (i = 0; i < webadmin.dataStoreCache.mutators.length; i++)
		{
			HasSettings(webadmin.dataStoreCache.mutators[i].ClassName);
		}
		webadmin.addMessage(q, "Settings cache has been rebuild.");
	}

	webadmin.addMessage(q, "<form action=\""$WebAdmin.Path$q.Request.URI$"\" method=\"post\">"
		$"<p>Only rebuild the settings cache when the server is empty. It is strongly adviced to restart the game after rebuilding has been completed.</p>"
		$"<p><button type=\"submit\" name=\"action\" value=\"rebuild\">Rebuild cache</button></p></form>", MT_Warning);

	q.response.Subst("page.title", "Rebuild Settings Cache");
	webadmin.sendPage(q, "message.html");
}

function bool HasSettings(string forClass)
{
	local int i;
	i = HasSettingsCache.find('classname', forClass);
	if (i != INDEX_NONE)
	{
		return HasSettingsCache[i].hasSettings;
	}
	i = HasSettingsCache.length;
	HasSettingsCache.length = i+1;
	HasSettingsCache[i].className = forClass;
	HasSettingsCache[i].hasSettings = getSettingsClassFqn(forClass, true) != none;
	SaveConfig();
	return HasSettingsCache[i].hasSettings;
}

/**
 * Get the settings class by the fully qualified name
 */
function class<Settings> getSettingsClassFqn(string forClass, optional bool bSilent=false)
{
	local int idx;
	if (len(forClass) == 0) return none;

	idx = classSettingsCache.find('cls', Locs(forClass));
	if (idx != INDEX_NONE)
	{
		return classSettingsCache[idx].settingsCls;
	}
	idx = InStr(forClass, ".");
	if (idx == INDEX_NONE) return getSettingsClass("", forClass, bSilent);
	return getSettingsClass(Left(forClass, idx), Mid(forClass, idx+1), bSilent);
}

/**
 * Find the settings class. package name could be empty
 */
function class<Settings> getSettingsClass(string pkgName, string clsName, optional bool bSilent=false)
{
	local string className, settingsClass;
	local class<Settings> result;
	local int idx;
	local ClassSettingsCacheEntry cacheEntry;

	if (len(clsName) == 0) return none;

	idx = classSettingsCache.find('cls', Locs(pkgName$"."$clsName));
	if (idx != INDEX_NONE)
	{
		return classSettingsCache[idx].settingsCls;
	}

	cacheEntry.cls = Locs(pkgName$"."$clsName);

	idx = settingsClasses.find('className', clsName);
	if (idx == INDEX_NONE)
	{
		className = cacheEntry.cls;
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
			cacheEntry.settingsCls = result;
			classSettingsCache.addItem(cacheEntry);
			return result;
		}
	}
	// try to find it automatically
	settingsClass = pkgName;
	// rewrite standard game classes to WebAdmin
	if (settingsClass ~= "UTGame") settingsClass = string(class.getPackageName());
	else if (settingsClass ~= "UTGameContent") settingsClass = string(class.getPackageName());
	else if (settingsClass ~= "UT3Gold") settingsClass = string(class.getPackageName());
	else if (settingsClass ~= "UT3GoldGame") settingsClass = string(class.getPackageName());
	settingsClass $= "."$clsName$"Settings";
	result = class<Settings>(DynamicLoadObject(settingsClass, class'class', true));
	if (result != none)
	{
		cacheEntry.settingsCls = result;
		classSettingsCache.addItem(cacheEntry);
		return result;
	}
	// not in the same package, try the find the object (only works when it was loaded)
	result = class<Settings>(FindObject(clsName$"Settings", class'class'));
	if (result == none)
	{
		if (!bSilent)
		{
			`Log("Settings class "$settingsClass$" for class "$pkgName$"."$clsName$" not found (auto detection).",,'WebAdmin');
		}
	}
	// even cache a none result
	cacheEntry.settingsCls = result;
	classSettingsCache.addItem(cacheEntry);
	return result;
}

/**
 * Try to find the settings class for the provided class
 */
function class<Settings> getSettingsClassByClass(class forClass, optional bool bSilent=false)
{
	return getSettingsClass(string(forClass.getPackageName()), string(forClass.name), bSilent);
}

function Settings getSettingsInstance(class<Settings> cls)
{
	local Settings instance;
	local int idx;
	idx = settingsInstances.find('cls', cls);
	if (idx == INDEX_NONE)
	{
		instance = new cls;
		idx = settingsInstances.length;
		settingsInstances.Length = idx+1;
		settingsInstances[idx].cls = cls;
		settingsInstances[idx].instance = instance;
		if (IAdvWebAdminSettings(instance) != none)
		{
			IAdvWebAdminSettings(instance).initSettings(webadmin.WorldInfo, webadmin.dataStoreCache);
		}
		else {
			instance.SetSpecialValue(`{WA_INIT_SETTINGS}, "");
		}
	}
	return settingsInstances[idx].instance;
}

function handleSettingsGametypes(WebAdminQuery q)
{
	local string currentGameType, substvar, tmp;
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
 		tmp = "";
 		if (!HasSettings(gametype.GameMode))
 		{
 			//continue;
 			tmp = " &sup1;";
 		}
 		q.response.subst("gametype.gamemode", `HTMLEscape(gametype.GameMode));
 		q.response.subst("gametype.friendlyname", `HTMLEscape(class'WebAdminUtils'.static.getLocalized(gametype.FriendlyName))$tmp);
 		q.response.subst("gametype.defaultmap", `HTMLEscape(gametype.DefaultMap));
 		q.response.subst("gametype.description", `HTMLEscape(class'WebAdminUtils'.static.getLocalized(gametype.Description)));
 		if (currentGameType ~= gametype.GameMode)
 		{
 			q.response.subst("editgametype.name", `HTMLEscape(class'WebAdminUtils'.static.getLocalized(gametype.FriendlyName))$tmp);
 			q.response.subst("editgametype.class", `HTMLEscape(gametype.GameMode));
 			q.response.subst("gametype.selected", "selected=\"selected\"");
 		}
 		else {
 			q.response.subst("gametype.selected", "");
 		}
 		substvar $= webadmin.include(q, "current_change_gametype.inc");
 	}
 	q.response.subst("gametypes", substvar);

	if ((editGametype != none) && len(editGametype.GameMode) > 0)
	{
		gi = class<GameInfo>(DynamicLoadObject(editGametype.GameMode, class'class'));
		if (gi != none)
		{
			settingsClass = getSettingsClassFqn(editGametype.GameMode);
		}
		if (settingsClass != none)
		{
			settings = getSettingsInstance(settingsClass);
		}
		if (settings == none)
		{
			if (settingsMagic == none)
			{
				settingsMagic = new class'SettingsMagic';
			}
			settings = settingsMagic.find(gi);
		}
	}

	if (settings != none)
	{
		if (q.request.getVariable("action") ~= "save" || q.request.getVariable("action") ~= "save settings")
		{
			if (IAdvWebAdminSettings(settings) != none)
			{
				if (IAdvWebAdminSettings(settings).saveSettings(q.request, webadmin.getMessagesObject(q)))
				{
					webadmin.addMessage(q, msgSettingsSaved);
				}
			}
			else {
				applySettings(settings, q.request);
				if (UTGame(WebAdmin.WorldInfo.Game) != none)
				{	// this prevents some saving of variables at a level change
					UTGame(WebAdmin.WorldInfo.Game).bAdminModifiedOptions = true;
				}
				settings.SetSpecialValue(`{WA_SAVE_SETTINGS}, "");
				webadmin.addMessage(q, msgSettingsSaved);
			}
		}
		if (settingsRenderer == none)
		{
			settingsRenderer = new class'SettingsRenderer';
			settingsRenderer.init(webadmin.path);
		}
		if (IAdvWebAdminSettings(settings) != none)
		{
			settingsRenderer.initEx(settings, q.response);
			IAdvWebAdminSettings(settings).renderSettings(q.response, settingsRenderer);
		}
		else {
			settingsRenderer.render(settings, q.response);
		}
	}
	else if (editGametype != none) {
		webadmin.addMessage(q, msgCantSaveSettings, MT_Warning);
	}

 	webadmin.sendPage(q, "default_settings_gametypes.html");
}

/**
 * Apply the settings received from the response to the settings instance
 */
static function applySettings(Settings settings, WebRequest request, optional string prefix = "settings_")
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
		settings = getSettingsInstance(settingsClass);
	}

	if (settings != none)
	{
		if (q.request.getVariable("action") ~= "save" || q.request.getVariable("action") ~= "save settings")
		{
			if (IAdvWebAdminSettings(settings) != none)
			{
				if (IAdvWebAdminSettings(settings).saveSettings(q.request, webadmin.getMessagesObject(q)))
				{
					webadmin.addMessage(q, msgSettingsSaved);
				}
			}
			else {
				applySettings(settings, q.request);
				if (UTGame(WebAdmin.WorldInfo.Game) != none)
				{	// this prevents some saving of variables at a level change
					UTGame(WebAdmin.WorldInfo.Game).bAdminModifiedOptions = true;
				}
				settings.SetSpecialValue(`{WA_SAVE_SETTINGS}, "");
				webadmin.addMessage(q, msgSettingsSaved);
			}
			// server name change takes immediate effect
			if (WebAdmin.WorldInfo.Game.GameReplicationInfo != none	&& WebAdmin.WorldInfo.Game.GameSettings != none
				&& WebAdmin.WorldInfo.Game.GameInterface != none
				&& (WebAdmin.WorldInfo.Game.GameReplicationInfo.ServerName != class'GameReplicationInfo'.default.ServerName))
			{
				WebAdmin.WorldInfo.Game.GameReplicationInfo.ServerName = class'GameReplicationInfo'.default.ServerName;
				WebAdmin.WorldInfo.Game.GameSettings.OwningPlayerName = class'GameReplicationInfo'.default.ServerName;
				WebAdmin.WorldInfo.Game.GameInterface.UpdateOnlineGame(WebAdmin.WorldInfo.Game.GameSettings);
			}
		}
		if (settingsRenderer == none)
		{
			settingsRenderer = new class'SettingsRenderer';
			settingsRenderer.init(webadmin.path);
		}
		if (IAdvWebAdminSettings(settings) != none)
		{
			settingsRenderer.initEx(settings, q.response);
			IAdvWebAdminSettings(settings).renderSettings(q.response, settingsRenderer);
		}
		else {
			settingsRenderer.render(settings, q.response);
		}
	}
	else {
		`Log("Failed to load the general settings class "$GeneralSettingsClass,,'WebAdmin');
		webadmin.addMessage(q, msgCantLoadSettings, MT_Warning);
	}

 	webadmin.sendPage(q, "default_settings_general.html");
}

function handleSettingsPasswords(WebAdminQuery q)
{
	local string action, pw1, pw2;
	action = q.request.getVariable("action");
	if (action ~= "gamepassword")
	{
		pw1 = q.request.getVariable("gamepw1");
		pw2 = q.request.getVariable("gamepw2");
		if (pw1 != pw2)
		{
			webadmin.addMessage(q, msgGamePWError, MT_Error);
		}
		else {
			webadmin.WorldInfo.Game.AccessControl.SetGamePassword(pw1);
			webadmin.WorldInfo.Game.AccessControl.SaveConfig();
			webadmin.addMessage(q, msgGamePWSaved);
		}
	}
	else if (action ~= "adminpassword")
	{
		pw1 = q.request.getVariable("adminpw1");
		pw2 = q.request.getVariable("adminpw2");
		if (pw1 != pw2)
		{
			webadmin.addMessage(q, msgAdminPWError, MT_Error);
		}
		else if (len(pw1) == 0)
		{
			webadmin.addMessage(q, msgAdminPWEmpty, MT_Error);
		}
		else {
			webadmin.WorldInfo.Game.AccessControl.SetAdminPassword(pw1);
			webadmin.WorldInfo.Game.AccessControl.SaveConfig();
			webadmin.addMessage(q, msgAdminPWSaved);
		}
	}
	q.response.subst("has.gamepassword", `HTMLEscape(webadmin.WorldInfo.Game.AccessControl.RequiresPassword()));
	webadmin.sendPage(q, "default_settings_password.html");
}

function handleSettingsMutators(WebAdminQuery q)
{
	local UTUIDataProvider_Mutator mutator, editMutator;
	local string currentMutator, substvar;
	local class<Mutator> mut;
	local class<Settings> settingsClass;
	local Settings settings;
	local int idx;

	currentMutator = q.request.getVariable("mutator");
 	webadmin.dataStoreCache.loadMutators();
 	for (idx = 0; idx < webadmin.dataStoreCache.mutators.length; idx++)
 	{
 		if (webadmin.dataStoreCache.mutators[idx].ClassName ~= currentMutator)
 		{
 			break;
 		}
 	}
	if (idx >= webadmin.dataStoreCache.mutators.length) idx = INDEX_NONE;
 	if (idx > INDEX_NONE)
 	{
 		editMutator = webadmin.dataStoreCache.mutators[idx];
 		currentMutator = editMutator.ClassName;
 	}
 	else {
 		editMutator = none;
 		currentMutator = "";
 	}

 	substvar = "";
 	foreach webadmin.dataStoreCache.mutators(mutator)
 	{
 		if (!HasSettings(mutator.ClassName))
 		{
 			continue;
 		}
 		q.response.subst("mutator.classname", `HTMLEscape(mutator.ClassName));
 		q.response.subst("mutator.friendlyname", `HTMLEscape(mutator.FriendlyName));
 		q.response.subst("mutator.description", `HTMLEscape(mutator.Description));

 		if (currentMutator ~= mutator.ClassName)
 		{
 			q.response.subst("editmutator.name", `HTMLEscape(mutator.FriendlyName));
 			q.response.subst("editmutator.class", `HTMLEscape(mutator.ClassName));
 			q.response.subst("editmutator.description", `HTMLEscape(mutator.Description));
 			q.response.subst("mutator.selected", "selected=\"selected\"");
 		}
 		else {
 			q.response.subst("mutator.selected", "");
 		}
 		substvar $= webadmin.include(q, "default_settings_mutators_select.inc");
 	}
 	q.response.subst("mutators", substvar);

 	if ((editMutator != none) && len(editMutator.ClassName) > 0)
	{
		mut = class<Mutator>(DynamicLoadObject(editMutator.ClassName, class'class'));
		if (mut != none)
		{
			settingsClass = getSettingsClassFqn(editMutator.ClassName);
		}
		if (settingsClass != none)
		{
			settings = getSettingsInstance(settingsClass);
		}
	}

	if (settings != none)
	{
		if (q.request.getVariable("action") ~= "save" || q.request.getVariable("action") ~= "save settings")
		{
			if (IAdvWebAdminSettings(settings) != none)
			{
				if (IAdvWebAdminSettings(settings).saveSettings(q.request, webadmin.getMessagesObject(q)))
				{
					webadmin.addMessage(q, msgSettingsSaved);
				}
			}
			else {
				applySettings(settings, q.request);
				settings.SetSpecialValue(`{WA_SAVE_SETTINGS}, "");
				webadmin.addMessage(q, msgSettingsSaved);
			}
		}
		if (settingsRenderer == none)
		{
			settingsRenderer = new class'SettingsRenderer';
			settingsRenderer.init(webadmin.path);
		}
		if (IAdvWebAdminSettings(settings) != none)
		{
			settingsRenderer.initEx(settings, q.response);
			IAdvWebAdminSettings(settings).renderSettings(q.response, settingsRenderer);
		}
		else {
			settingsRenderer.render(settings, q.response);
		}
		q.response.subst("settings", webadmin.include(q, "default_settings_mutators.inc"));
	}
	else if (editMutator != none) {
		webadmin.addMessage(q, msgCantLoadSettings, MT_Warning);
	}

	webadmin.sendPage(q, "default_settings_mutators.html");
}

`if(`WITH_VOTING_1_3)
function handleMapList(WebAdminQuery q)
{
	local string currentGameType, substvar;
	local UTUIDataProvider_GameModeInfo editGametype, gametype;
	local int idx, i;
	local class<GameInfo> gi;
	local GameMapCycle cycle;
	local array<UTUIDataProvider_MapInfo> allMaps;
	local array<string> postcycle;

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

	if ((editGametype != none) && len(editGametype.GameMode) > 0)
	{
		gi = class<GameInfo>(DynamicLoadObject(editGametype.GameMode, class'class'));
	}
	if (gi != none)
	{
		allMaps = webadmin.dataStoreCache.getMaps(editGametype.GameMode);
		idx = class'UTGame'.default.GameSpecificMapCycles.find('GameClassName', gi.name);
		if (idx != INDEX_NONE)
		{
			cycle = class'UTGame'.default.GameSpecificMapCycles[idx];
		}
		else {
			cycle.GameClassName = gi.name;
			cycle.Maps.length = 0;
			idx = class'UTGame'.default.GameSpecificMapCycles.length;
		}

		if (len(q.request.getVariable("action")) > 0)
		{
			ParseStringIntoArray(q.request.getVariable("mapcycle"), postcycle, chr(10), true);
			cycle.Maps.length = 0;
			for (i = 0; i < postcycle.length; i++)
			{
				substvar = `Trim(postcycle[i]);
				if (len(substvar) > 0)
				{
					cycle.Maps[cycle.Maps.length] = substvar;
				}
			}
			class'UTGame'.default.GameSpecificMapCycles[idx] = cycle;
			class'UTGame'.static.StaticSaveConfig();
			if (UTGame(webadmin.WorldInfo.Game) != none)
			{
				UTGame(webadmin.WorldInfo.Game).GameSpecificMapCycles = class'UTGame'.default.GameSpecificMapCycles;
			}
			webadmin.addMessage(q, msgMapCycleSaved);
		}

		substvar = "";
		for (i = 0; i < allMaps.length; i++)
		{
			if (i > 0) substvar $= chr(10);
			substvar $= allMaps[i].MapName;
		}
		q.response.subst("allmaps.plain", `HTMLEscape(substvar));

		substvar = "";
		for (i = 0; i < cycle.Maps.length; i++)
		{
			if (i > 0) substvar $= chr(10);
			substvar $= cycle.Maps[i];
		}
		q.response.subst("cycle.plain", `HTMLEscape(substvar));

		q.response.subst("maplist_editor", webadmin.include(q, "default_maplist_editor.inc"));
	}
	else {
		webadmin.addMessage(q, msgCantLoadGT, MT_Warning);
	}
 	webadmin.sendPage(q, "default_maplist.html");
}

function handleMapListAdditional(WebAdminQuery q)
{
	local int i, currentCycleIdx;
	local string editCycleId, substvar, postAction;
	local ExtraMapCycle currentCycle, cycle;
	local UTUIDataProvider_GameModeInfo gametype;
	local class<GameInfo> gi;
	local WebAdminUtils.DateTime datetime;
	local array<UTUIDataProvider_MapInfo> allMaps;
	local array<string> postcycle;
	local class<AdditionalMapLists> amlClass;

	currentCycleIdx = INDEX_NONE;
	webadmin.dataStoreCache.loadGameTypes();

	if (additionalML == none)
	{
		amlClass = class<AdditionalMapLists>(DynamicLoadObject(AdditionalMLClass, class'class'));
		if (amlClass == none)
		{
			`Log("Failed to load the configured additional map lists storage class "$AdditionalMLClass,,'WebAdmin');
			amlClass = class'AdditionalMapLists';
		}
		additionalML = new amlClass;
		if (additionalML.mapCycles.Length == 0 && !additionalML.bInitialized)
		{
			for (i = 0; i < class'UTGame'.default.GameSpecificMapCycles.length; i++)
			{
				if (webadmin.dataStoreCache.resolveGameType(class'UTGame'.default.GameSpecificMapCycles[i].GameClassName) == INDEX_NONE)
				{
					continue;
				}
				if (class'UTGame'.default.GameSpecificMapCycles[i].maps.length == 0)
				{
					continue;
				}
				class'WebAdminUtils'.static.getDateTime(datetime);
				cycle.id = "imported"$i@datetime.year$datetime.month$datetime.day$datetime.hour$datetime.minute$datetime.second;
				cycle.FriendlyName = msgImportedMapList;
				cycle.cycle = class'UTGame'.default.GameSpecificMapCycles[i];
				additionalML.mapCycles.AddItem(cycle);
			}
			additionalML.bInitialized = true;
			additionalML.SaveConfig();
		}
	}

	editCycleId = q.request.getVariable("maplistid");

	postAction = q.request.getVariable("action");
	if (postAction ~= "create")
	{
		gi = class<GameInfo>(DynamicLoadObject(q.request.getVariable("gametype"), class'class', true));
		if (gi == none)
		{
			webadmin.addMessage(q, msgInvalidMaplist, MT_Error);
		}
		else {
			currentCycle.FriendlyName = q.request.getVariable("name");
			if (Len(currentCycle.FriendlyName) == 0)
			{
				currentCycle.FriendlyName = Untitled;
			}
			currentCycle.cycle.GameClassName = gi.name;
			currentCycle.cycle.maps.length = 0;
			class'WebAdminUtils'.static.getDateTime(datetime);
			editCycleId = gi.name@datetime.year$datetime.month$datetime.day$datetime.hour$datetime.minute$datetime.second;
			currentCycle.id = editCycleId;
			currentCycleIdx = additionalML.mapCycles.length;
			additionalML.mapCycles[currentCycleIdx] = currentCycle;
		}
	}
	else if (postAction ~= "delete")
	{
		currentCycleIdx = additionalML.mapCycles.find('id', editCycleId);
		if (currentCycleIdx == INDEX_NONE)
		{
			webadmin.addMessage(q, msgCantFindMapCycle, MT_Error);
		}
		else {
			webadmin.addMessage(q, repl(msgCycleDeleted, "%s", "<em>"$`HTMLEscape(additionalML.mapCycles[currentCycleIdx].FriendlyName)$"</em>");
			additionalML.mapCycles.remove(currentCycleIdx, 1);
			additionalML.SaveConfig();
			currentCycleIdx = INDEX_NONE;
		}
	}

	if (len(editCycleId) == 0 && additionalML.mapCycles.length > 0)
	{
		currentCycle = additionalML.mapCycles[0];
		currentCycleIdx = additionalML.mapCycles.length;
	}
	else if (currentCycleIdx == INDEX_NONE && len(editCycleId) > 0)
	{
		currentCycleIdx = additionalML.mapCycles.find('id', editCycleId);
		if (currentCycleIdx != INDEX_NONE)
		{
			currentCycle = additionalML.mapCycles[currentCycleIdx];
		}
	}

	if (currentCycleIdx != INDEX_NONE)
	{
		if (postAction ~= "save" || postAction ~= "activate")
		{
			currentCycle.FriendlyName = q.request.getVariable("name");
			ParseStringIntoArray(q.request.getVariable("mapcycle"), postcycle, chr(10), true);
			currentCycle.cycle.Maps.length = 0;
			for (i = 0; i < postcycle.length; i++)
			{
				substvar = `Trim(postcycle[i]);
				if (len(substvar) > 0)
				{
					currentCycle.cycle.Maps[currentCycle.cycle.Maps.length] = substvar;
				}
			}
			additionalML.mapCycles[currentCycleIdx] = currentCycle;
			additionalML.SaveConfig();
			webadmin.addMessage(q, repl(msgCycleSaved, "%s", "<em>"$`HTMLEscape(currentCycle.FriendlyName)$"</em>");
		}
		if (postAction ~= "activate")
		{
			i = class'UTGame'.default.GameSpecificMapCycles.find('GameClassName', currentCycle.cycle.GameClassName);
			if (i == INDEX_NONE)
			{
				i = class'UTGame'.default.GameSpecificMapCycles.length;
			}
			class'UTGame'.default.GameSpecificMapCycles[i] = currentCycle.cycle;
			class'UTGame'.static.StaticSaveConfig();
   			if (UTGame(webadmin.WorldInfo.Game) != none)
			{
				UTGame(webadmin.WorldInfo.Game).GameSpecificMapCycles = class'UTGame'.default.GameSpecificMapCycles;
			}
			webadmin.addMessage(q, repl(msgCycleActivated, "%s", currentCycle.cycle.GameClassName));
		}

		q.response.subst("editmaplist.friendlyname", `HTMLEscape(class'WebAdminUtils'.static.getLocalized(currentCycle.FriendlyName)));
 		q.response.subst("editmaplist.id", `HTMLEscape(currentCycle.id));
 		q.response.subst("editmaplist.gametype", `HTMLEscape(currentCycle.cycle.GameClassName));
 		i = webadmin.dataStoreCache.resolveGameType(currentCycle.cycle.GameClassName);
 		if (i != INDEX_NONE)
 		{
 			q.response.subst("editmaplist.gametype", `HTMLEscape(class'WebAdminUtils'.static.getLocalized(webadmin.dataStoreCache.gametypes[i].FriendlyName)));
 		}

		substvar = "";
		allMaps = webadmin.dataStoreCache.getMaps(""$currentCycle.cycle.GameClassName);
		for (i = 0; i < allMaps.length; i++)
		{
			if (i > 0) substvar $= chr(10);
			substvar $= allMaps[i].MapName;
		}
		q.response.subst("allmaps.plain", `HTMLEscape(substvar));

		substvar = "";
		for (i = 0; i < currentCycle.cycle.Maps.length; i++)
		{
			if (i > 0) substvar $= chr(10);
			substvar $= currentCycle.cycle.Maps[i];
		}
		q.response.subst("cycle.plain", `HTMLEscape(substvar));

		q.response.subst("maplist_editor", webadmin.include(q, "default_maplist_editor.inc"));

		q.response.subst("maplist_editor", webadmin.include(q, "default_maplist_additional_edit.inc"));
	}

	substvar = "";
 	foreach additionalML.mapCycles(cycle)
 	{
 		q.response.subst("maplist.id", `HTMLEscape(cycle.id));
 		q.response.subst("maplist.friendlyname", `HTMLEscape(class'WebAdminUtils'.static.getLocalized(cycle.FriendlyName)));
 		q.response.subst("maplist.gametype", `HTMLEscape(cycle.cycle.GameClassName));

 		i = webadmin.dataStoreCache.resolveGameType(cycle.cycle.GameClassName);
 		if (i != INDEX_NONE)
 		{
 			q.response.subst("maplist.gametype", `HTMLEscape(class'WebAdminUtils'.static.getLocalized(webadmin.dataStoreCache.gametypes[i].FriendlyName)));
 		}

 		if (editCycleId ~= cycle.id)
 		{
 			q.response.subst("maplist.selected", "selected=\"selected\"");
 		}
 		else {
 			q.response.subst("maplist.selected", "");
 		}
 		substvar $= webadmin.include(q, "default_maplist_additional_cycle.inc");
 	}
 	q.response.subst("maplists", substvar);

	// used to create a new maplist
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
		q.response.subst("gametype.selected", "");
 		substvar $= webadmin.include(q, "current_change_gametype.inc");
 	}
 	q.response.subst("gametypes", substvar);

	webadmin.sendPage(q, "default_maplist_additional.html");
}
`endif

function handleServerActors(WebAdminQuery q)
{
	local string tmp;
	local array<string> tmpa;
	local int i;
	local GameEngine gameengine;

	if (q.request.getVariable("action") ~= "save")
	{
		ParseStringIntoArray(q.request.getVariable("serveractors"), tmpa, chr(10), true);
		class'GameEngine'.default.ServerActors.length = 0;
		for (i = 0; i < tmpa.length; i++)
		{
			tmp = `Trim(tmpa[i]);
			if (len(tmp) > 0)
			{
				class'GameEngine'.default.ServerActors.addItem(tmp);
			}
		}
		class'GameEngine'.static.StaticSaveConfig();
		gameengine = GameEngine(FindObject("Transient.GameEngine_0", class'GameEngine'));
		if (gameengine != none)
		{
			gameengine.ServerActors = class'GameEngine'.default.ServerActors;
			webadmin.addMessage(q, msgServerActorsSaved);
		}
		else {
			webadmin.addMessage(q, msgServerActorsSavedWarn, MT_Warning);
		}
	}

	tmp = "";
	for (i = 0; i < class'GameEngine'.default.ServerActors.length; i++)
	{
		if (i > 0) tmp $= chr(10);
		tmp $= class'GameEngine'.default.ServerActors[i];
	}
	q.response.subst("serveractors", tmp);
	webadmin.sendPage(q, "default_serveractors.html");
}

defaultproperties
{
    `if(`isdefined(BUILD_AS_MOD))
	GeneralSettingsClass="WebAdmin.GeneralSettings"
	AdditionalMLClass="WebAdmin.AdditionalMapLists"
	`endif
}
