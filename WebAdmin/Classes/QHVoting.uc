/**
 * The query handler for the voting configuration of UT3 patch 1.4
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class QHVoting extends Object implements(IQueryHandler) config(WebAdmin);

`include(WebAdmin.uci)
`if(`UT3_PATCH_1_4)

var WebAdmin webadmin;

var UTMapListManager MapListManager;

/**
 * If true the legacy alternative map lists are imported to the new configuration
 */
var config bool bImportLegacyMaplists;

/**
 * Simple record that keeps a cache of names
 */
struct MapList
{
	/**
	 * The object name
	 */
	var string name;
	/**
	 * A friendly name
	 */
	var string friendlyName;
};

/**
 * Contains the list of map lists. To get the actual map use the name variable
 * with UTMapListManager.GetMapListByName(). This list is sorted on friendly name
 */
var array<MapList> maplists;

/**
 * Called when the WebAdmin creates and initializes this query handler.
 */
function init(WebAdmin webapp)
{
	webadmin = webapp;
	if (UTGame(webadmin.WorldInfo.Game) != none)
	{
		MapListManager = UTGame(webadmin.WorldInfo.Game).MapListManager;
	}

	if (bImportLegacyMaplists && MapListManager != none)
	{
		bImportLegacyMaplists = false;
		SaveConfig();
		convertLegacyMaplists();
	}
}

/**
 * Cleanup (prepare for being destroyed). If the implementation extends Object
 * it should set all actor references to none.
 */
function cleanup()
{
	webadmin = none;
	MapListManager = none;
}

function bool producesXhtml()
{
	return true;
}

/**
 * Called by the webadmin to request the query handler to handle this query.
 *
 * @return true when the query was handled.
 */
function bool handleQuery(WebAdminQuery q)
{
	switch (q.request.URI)
	{
		case "/voting":
			q.response.Redirect(WebAdmin.Path$"/settings/general#SettingsGroup6");
			return true;
		case "/voting/maplist":
			if (MapListManager == none) {
				webadmin.addMessage(q, "Maplist editing is not available because no map list manager is loaded.", MT_Error);
				webadmin.sendPage(q, "message.html");
				return true;
			}
			handleMaplist(q);
			return true;
		case "/voting/mutators":
			if (MapListManager == none) {
				webadmin.addMessage(q, "Maplist editing is not available because no map list manager is loaded.", MT_Error);
				webadmin.sendPage(q, "message.html");
				return true;
			}
			handleMutators(q);
			return true;
		case "/voting/profiles":
			if (MapListManager == none) {
				webadmin.addMessage(q, "Maplist editing is not available because no map list manager is loaded.", MT_Error);
				webadmin.sendPage(q, "message.html");
				return true;
			}
			handleProfiles(q);
			return true;
		case "/voting/profiles/data":
			handleProfilesData(q);
			return true;
	}
	return false;
}

/**
 * Called in case of an unhandled path.
 *
 * @return true when the query was handled.
 */
function bool unhandledQuery(WebAdminQuery q)
{
	return false;
}

/**
 * Called by the webadmin to request the query handler to add its menu items to
 * the web admin menu. The menu is used to determine what query handler will be
 * handle a given path. Paths not registered will be passed to all query handlers
 * until one returns true.
 */
function registerMenuItems(WebAdminMenu menu)
{
	menu.addMenu("/voting", "Voting", self, "Generic voting settings");
	menu.addMenu("/voting/profiles", "Game Profiles", self, "Game profiles are votable preconfigured game types. Here you can manage the various profiles. Changes will take effect in the next game session.", -1);
	menu.addMenu("/voting/profiles/data", "", self);
	menu.addMenu("/voting/maplist", "Map lists", self, "The map list management allows you to create and edit the map lists as used by the game profiles.");
	menu.addMenu("/voting/mutators", "Mutators", self, "These mutators can be voted on by the players, unless the current game profile has the mutators in the exclude list.");
}

function convertLegacyMaplists()
{
	local AdditionalMapLists ml;
	local class<AdditionalMapLists> amlClass;
	local int i, j;
	local UTMapList newMl;
	local string mlName, basename;
	local array<string> listnames;

	GetPerObjectConfigSections(Class'UTMapList', listnames);

 	amlClass = class<AdditionalMapLists>(DynamicLoadObject(class'QHDefaults'.default.AdditionalMLClass, class'class'));
	if (amlClass == none)
	{
		return;
	}
	ml = new amlClass;
	for (i = 0; i < ml.mapCycles.length; i++)
	{
		mlName = repl(ml.mapCycles[i].FriendlyName, " ", "_");
		mlName -= "[";
		mlName -= "]";
		basename = mlName;
		j = 1;
		while (listnames.find(mlName) != INDEX_NONE)
		{
			++j;
			mlName = basename$"_"$j;
		}

		newMl = MapListManager.GetMapListByName(name(mlName), true);
		newMl.Maps.length = ml.mapCycles[i].cycle.Maps.length;
		for (j = 0; j < ml.mapCycles[i].cycle.Maps.length; j++)
		{
			newMl.Maps[j].Map = ml.mapCycles[i].cycle.Maps[j];
		}
		newMl.SaveConfig();
		listnames[listnames.length] = mlName;
	}
	`log("Converted "$ml.mapCycles.length$" additional map lists to new voting map lists",,'WebAdmin');
}

function handleMaplist(WebAdminQuery q)
{
	local int i, j, n;
	local string tmp, tmp2, editMLname;
	local UTMapList ml;
	local array<string> tmpa, tmpb;

	if (mapLists.length == 0)
	{
		populateListNames();
	}

	editMLname = q.request.getVariable("maplistid");

	if (q.request.getVariable("action") ~= "create")
	{
		if (len(editMLname) > 0)
		{
			tmp = editMLname;
			editMLname = repl(editMLname, " ", "_");
			editMLname -= "[";
			editMLname -= "]";
			editMLname = string(name(editMLname));
			if ((MapListManager != none) && (maplists.find('name', editMLname) == INDEX_NONE))
			{
				ml = MapListManager.GetMapListByName(name(editMLname), true);
				if (ml != none)
				{
					ml.SaveConfig();
					for (i = 0; i < maplists.length; i++)
					{
						if (caps(tmp) < caps(maplists[i].friendlyName))
						{
							maplists.insert(i, 1);
							maplists[i].name = editMLname;
							maplists[i].friendlyName = tmp;
							break;
						}
					}
					if (i == maplists.length)
					{
						maplists.length = i+1;
						maplists[i].name = editMLname;
						maplists[i].friendlyName = tmp;
					}
					webadmin.addMessage(q, "Created the map list "$`HTMLEscape(tmp));
				}
				else {
					webadmin.addMessage(q, "Error creating map list: "$`HTMLEscape(tmp), MT_Error);
					editMLname = "";
				}
			}
			else {
				webadmin.addMessage(q, "There is already a map list with the name: "$`HTMLEscape(tmp), MT_Error);
				editMLname = "";
			}
		}
		else {
			webadmin.addMessage(q, "Map list name can not be empty", MT_Error);
		}
	}

	if (q.request.getVariable("action") ~= "delete")
	{
		ml = MapListManager.GetMapListByName(name(editMLname), false);
		if (ml != none)
		{
			ml.ClearConfig();
			ml = none;
			i = maplists.find('name', editMLname);
			if (i != INDEX_NONE)
			{
				editMLname = maplists[i].friendlyName;
				maplists.remove(i, 1);
			}
			webadmin.addMessage(q, "Removed the map list: "$editMLname);
		}
		else {
			webadmin.addMessage(q, "No map list available with the id: "$`HTMLEscape(editMLname), MT_Error);
		}
		editMLname = "";
	}

	tmp = "";
	for (i = 0; i < maplists.length; i++)
	{
		q.response.subst("maplist.id", `HTMLEscape(maplists[i].name));
		if (editMLname == maplists[i].name)
		{
			q.response.subst("maplist.selected", "selected=\"selected\"");
		}
		else {
			q.response.subst("maplist.selected", "");
		}
		tmp2 = `HTMLEscape(maplists[i].friendlyName);
		if (MapListManager != none)
		{
			ml = MapListManager.GetCurrentMapList();
			if (maplists[i].name == string(ml.name))
			{
				tmp2 $= " (currently in use)";
			}
		}
		q.response.subst("maplist.friendlyname", tmp2);
		tmp $= webadmin.include(q, "voting_maplist_select.inc");
	}
	q.response.subst("maplists", tmp);

	q.response.subst("editor", "");
	if (MapListManager != none && len(editMLname) > 0)
	{
		ml = MapListManager.GetMapListByName(name(editMLname), false);
		if (ml != none)
		{
			if (q.request.getVariable("action") ~= "save")
			{
				tmp = q.request.getVariable("autoloadprefixes");
				ParseStringIntoArray(tmp, tmpa, chr(10), true);
				tmp = "";
				for (i = 0; i < tmpa.length; i++)
				{
					tmp2 = `Trim(tmpa[i]);
					if (len(tmp2) > 0)
					{
						if (len(tmp) > 0) tmp $= ",";
						tmp $= tmp2;
					}
				}
				ml.AutoLoadPrefixes = tmp;

				ParseStringIntoArray(q.request.getVariable("mapcycle"), tmpa, chr(10), true);
				ml.Maps.length = 0;
				for (i = 0; i < tmpa.length; i++)
				{
					tmp = `Trim(tmpa[i]);
					if (len(tmp) == 0) continue;
					ml.Maps.length = ml.Maps.length+1;
					j = InStr(tmp, "extra:");
					if (j == INDEX_NONE) j = Len(tmp);
					ml.Maps[ml.Maps.length-1].Map = `trim(Left(tmp, j));

					ParseStringIntoArray(`Trim(mid(tmp, j+6)), tmpb, "?", true);
					for (j = 0; j < tmpb.length; j++)
					{
						tmp2 = `Trim(tmpb[j]);
						//if (len(tmp2) == 0) continue;
						n = InStr(tmp2, "=");
						ml.Maps[ml.Maps.length-1].ExtraData.length = j+1;
						if (n != INDEX_NONE)
						{
							ml.Maps[ml.Maps.length-1].ExtraData[j].Key = name(Left(tmp2, n));
							ml.Maps[ml.Maps.length-1].ExtraData[j].Value = Mid(tmp2, n+1);
						}
						else {
							ml.Maps[ml.Maps.length-1].ExtraData[j].Key = name(tmp2);
						}
					}
				}

				ml.SaveConfig();
				webadmin.addMessage(q, "Changes saved");
			}

			q.response.subst("maplistid", `HTMLEscape(editMLname));
			i = maplists.find('name', editMLname);
			if (i != INDEX_NONE)
			{
				q.response.subst("friendlyname", `HTMLEscape(maplists[i].friendlyName));
			}
			q.response.subst("autoloadprefixes", `HTMLEscape(repl(ml.AutoLoadPrefixes, ",", chr(10))));

			tmp = "";
			for (i = 0; i < ml.maps.length; i++)
			{
    			if (len(tmp) > 0) tmp $= chr(10);
				tmp $= ml.maps[i].Map;

				for (j = 0; j < ml.maps[i].ExtraData.length; j++)
				{
					if (j == 0)
					{
						tmp $= "    extra:";
					}
					else {
						tmp $= "?";
					}
					tmp $= ml.maps[i].ExtraData[j].key;
					if (ml.maps[i].ExtraData[j].value != "")
					{
						tmp $= "="$ml.maps[i].ExtraData[j].value;
					}
				}
			}
			q.response.subst("mapcycle", `HTMLEscape(tmp));

			q.response.subst("editor", webadmin.include(q, "voting_maplist_editor.inc"));
		}
		else {
			webadmin.addMessage(q, "No map list available with the id: "$`HTMLEscape(editMLname), MT_Error);
		}
	}

	webadmin.sendPage(q, "voting_maplist.html");
}

function populateListNames()
{
	local string mlName, friendlyName;
	local array<string> listnames;
	local int i, j;
	GetPerObjectConfigSections(Class'UTMapList', listnames);
	for (i = 0; i < listnames.length; i++)
	{
		parseSectionName(listnames[i], Class'UTMapList'.name, mlName, friendlyName);
		for (j = 0; j < maplists.length; j++)
		{
			if (Caps(friendlyName) < Caps(maplists[j].friendlyName))
			{
				maplists.insert(j, 1);
				maplists[j].name = mlName;
				maplists[j].friendlyName = friendlyName;
				break;
			}
		}
		if (j == maplists.length)
		{
			maplists.length = j+1;
			maplists[j].name = mlName;
			maplists[j].friendlyName = friendlyName;
		}
	}
}

static final function parseSectionName(string sectionName, name ClsName, out string objName, out string friendlyName)
{
	if (right(sectionName, len(clsname)+1) == (" "$clsName))
	{
		objName = left(sectionName, len(sectionName)-(len(clsname)+1));
	}
	else {
		`log("sectionNameToFriendly: '"$sectionName$"' does not contain postfix: ' "$clsName$"'",, 'WebAdmin');
		objName = left(sectionName, InStr(sectionName, " "));
	}
	friendlyName = repl(objName, "_", " ");
}

function handleProfiles(WebAdminQuery q)
{
	local int i, idx;
	local string tmp, tmp2, editProfile;
	local UTUIDataProvider_GameModeInfo gametype;
	local array<string> tmpArray;

	editProfile = q.request.getVariable("profilename");
	if (len(editProfile) == 0) editProfile = MapListManager.ActiveGameProfileName;
	idx = MapListManager.default.GameProfiles.find('GameName', editProfile);

	if (q.request.getVariable("action") ~= "create" || q.request.getVariable("action") ~= "create new profile")
	{
		tmp = q.request.getVariable("newprofilename");
		idx = INDEX_NONE;
		for (i = 0; i < MapListManager.default.GameProfiles.length; i++)
		{
			if (MapListManager.default.GameProfiles[i].GameName ~= tmp)
			{
				idx = i;
				break;
			}
		}

		if (idx != INDEX_NONE)
		{
			webadmin.addMessage(q, "There is already a game profile with the name: "$`HTMLEscape(tmp), MT_Error);
		}
		else {
			idx = MapListManager.default.GameProfiles.length;
			MapListManager.default.GameProfiles.length = idx+1;
			MapListManager.default.GameProfiles[idx].GameName = tmp;
			MapListManager.default.GameProfiles[idx].GameClass = q.request.getVariable("newgameclass");
			MapListManager.static.StaticSaveConfig();
			webadmin.addMessage(q, "Created game profile: "$`HTMLEscape(tmp));
			editProfile = tmp;
		}
	}
	else if (q.request.getVariable("action") ~= "save")
	{
		if (idx != INDEX_NONE)
		{
			tmp = q.request.getVariable("friendlyname");
			if (len(tmp) > 0 && tmp != editProfile)
			{
				MapListManager.default.GameProfiles[idx].GameName = tmp;
				if (editProfile == MapListManager.ActiveGameProfileName)
				{
					MapListManager.ActiveGameProfileName = tmp;
				}
				webadmin.addMessage(q, "Game profile '"$`HTMLEscape(editProfile)$"' renamed to '"$`HTMLEscape(tmp)$"'");
				editProfile = tmp;
			}
			MapListManager.default.GameProfiles[idx].GameClass = q.request.getVariable("gameclass");
			MapListManager.default.GameProfiles[idx].MapListName = name(q.request.getVariable("maplist"));
			tmp = Repl(q.request.getVariable("options"), chr(10), ",");
			tmp -= " ";
			tmp -= chr(13);
			MapListManager.default.GameProfiles[idx].options = tmp;

			tmp = "";
			for (i = 0; i < int(q.request.getVariable("mutatorcount")); i++)
			{
				tmp2 = q.request.getVariable("mutgroup"$i);
				if (len(tmp2) > 0)
				{
					if (len(tmp) > 0)
					{
						tmp $= ",";
					}
					tmp $= tmp2;
				}
			}
			MapListManager.default.GameProfiles[idx].Mutators = tmp;

			tmp = "";
			for (i = 0; i < int(q.request.getVariable("excludedmutcount")); i++)
			{
				tmp2 = q.request.getVariable("excludedmut_"$i);
				if (len(tmp2) > 0)
				{
					if (len(tmp) > 0)
					{
						tmp $= ",";
					}
					tmp $= tmp2;
				}
			}
			MapListManager.default.GameProfiles[idx].ExcludedMuts = tmp;

			MapListManager.static.StaticSaveConfig();
			webadmin.addMessage(q, "Game profile '"$`HTMLEscape(editProfile)$"' saved");
		}
		else {
			webadmin.addMessage(q, "Unable to find the game profile: "$`HTMLEscape(editProfile), MT_Error);
		}
	}
	else if (q.request.getVariable("action") ~= "delete")
	{
		if (idx != INDEX_NONE)
		{
			MapListManager.default.GameProfiles.remove(idx, 1);
			if (editProfile == MapListManager.ActiveGameProfileName)
			{
				MapListManager.ActiveGameProfileName = "";
			}
			MapListManager.static.StaticSaveConfig();
   			idx = INDEX_NONE;
			webadmin.addMessage(q, "Game profile '"$`HTMLEscape(editProfile)$"' deleted");
		}
		else {
			webadmin.addMessage(q, "Unable to find the game profile: "$`HTMLEscape(editProfile), MT_Error);
		}
	}
	else if (q.request.getVariable("action") ~= "activate")
	{
		if (idx != INDEX_NONE)
		{
			MapListManager.default.ActiveGameProfileName = editProfile;
			MapListManager.static.StaticSaveConfig();
			// TODO: map change?
		}
		else {
			webadmin.addMessage(q, "Unable to find the game profile: "$`HTMLEscape(editProfile), MT_Error);
		}
	}

	tmp = "";
	// TODO: sort this list
	for (i = 0; i < MapListManager.default.GameProfiles.length; i++)
	{
		q.response.subst("profile.id", `HTMLEscape(MapListManager.default.GameProfiles[i].GameName));
		if (editProfile == MapListManager.default.GameProfiles[i].GameName)
		{
			q.response.subst("profile.selected", "selected=\"selected\"");
		}
		else {
			q.response.subst("profile.selected", "");
		}
		tmp2 = `HTMLEscape(MapListManager.default.GameProfiles[i].GameName);
		if (MapListManager != none)
		{
			if (MapListManager.default.GameProfiles[i].GameName == MapListManager.ActiveGameProfileName)
			{
				tmp2 $= " (currently in use)";
			}
		}
		q.response.subst("profile.friendlyname", tmp2);
		tmp $= webadmin.include(q, "voting_profile_select.inc");
	}
	q.response.subst("profiles", tmp);

	tmp = "";
	webadmin.dataStoreCache.loadGameTypes();
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
		tmp $= webadmin.include(q, "current_change_gametype.inc");
 	}
	q.response.subst("newgametypes", tmp);

	q.response.subst("editor", "");
 	if (idx != INDEX_NONE)
 	{
 		q.response.subst("profilename", `HTMLEscape(MapListManager.default.GameProfiles[idx].GameName));
 		q.response.subst("profile.friendlyname", `HTMLEscape(MapListManager.default.GameProfiles[idx].GameName));
 		q.response.subst("profile.gameclass", `HTMLEscape(MapListManager.default.GameProfiles[idx].GameClass));
 		q.response.subst("profile.maplist", `HTMLEscape(MapListManager.default.GameProfiles[idx].MapListName));
 		q.response.subst("profile.options", `HTMLEscape(MapListManager.default.GameProfiles[idx].Options));
 		q.response.subst("profile.mutators", `HTMLEscape(repl(MapListManager.default.GameProfiles[idx].Mutators, ",", chr(10))));
 		q.response.subst("profile.excludedmuts", `HTMLEscape(repl(MapListManager.default.GameProfiles[idx].ExcludedMuts, ",", chr(10))));

		tmp = "";
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
 			if (MapListManager.default.GameProfiles[idx].GameClass ~= gametype.GameMode)
	 		{
 				q.response.subst("gametype.selected", "selected=\"selected\"");
	 		}
 			else {
 				q.response.subst("gametype.selected", "");
	 		}
 			tmp $= webadmin.include(q, "current_change_gametype.inc");
	 	}
 		q.response.subst("gametypes", tmp);

 		tmp = "";
 		if (mapLists.length == 0)
		{
			populateListNames();
		}
		for (i = 0; i < maplists.length; i++)
		{
			q.response.subst("maplist.id", `HTMLEscape(maplists[i].name));
			if (MapListManager.default.GameProfiles[idx].MapListName == name(maplists[i].name))
			{
				q.response.subst("maplist.selected", "selected=\"selected\"");
			}
			else {
				q.response.subst("maplist.selected", "");
			}
			q.response.subst("maplist.friendlyname", `HTMLEscape(maplists[i].friendlyName));
			tmp $= webadmin.include(q, "voting_maplist_select.inc");
		}
		q.response.subst("maplists", tmp);

		ParseStringIntoArray(MapListManager.default.GameProfiles[idx].Mutators, tmpArray, ",", true);
		tmp = "";
		i = 0;
		procVotingMutators(q, MapListManager.default.GameProfiles[idx].GameClass, tmpArray, tmp, i);
		q.response.subst("mutatorcount", i);
		q.response.subst("mutators", tmp);

		tmp = "";
		webadmin.dataStoreCache.loadMutators();
		ParseStringIntoArray(MapListManager.default.GameProfiles[idx].ExcludedMuts, tmpArray, ",", true);
 		for (i = 0; i < webadmin.dataStoreCache.mutators.length; i++)
 		{
 			q.response.subst("mutator.fieldname", "excludedmut_"$i);
 			q.response.subst("mutator.classname", `HTMLEscape(webadmin.dataStoreCache.mutators[i].ClassName));
			q.response.subst("mutator.friendlyname", `HTMLEscape(webadmin.dataStoreCache.mutators[i].friendlyName));
			q.response.subst("mutator.description", `HTMLEscape(webadmin.dataStoreCache.mutators[i].description));
			if (tmpArray.find(Locs(webadmin.dataStoreCache.mutators[i].ClassName)) != INDEX_NONE)
			{
				q.response.subst("mutator.checked", "checked=\"checked\"");
			}
			else {
				q.response.subst("mutator.checked", "");
			}
			tmp $= webadmin.include(q, "voting_profile_editor_excludedmut.inc");
 		}
 		q.response.subst("excludedmutcount", string(webadmin.dataStoreCache.mutators.length));
		q.response.subst("excludedmuts", tmp);

		q.response.subst("editor", webadmin.include(q, "voting_profile_editor.inc"));
	}

	webadmin.sendPage(q, "voting_profile.html");
}

function procVotingMutators(WebAdminQuery q, string currentGameType, array<string> currentMutators,
	out string outMutators, out int outMutatorGroups)
{
	local string substvar2, substvar3, mutname;
	local int idx, i, j, k;
	local array<MutatorGroup> mutators;
	local array<string> seenSingleMuts;

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
 					if (seenSingleMuts.find(mutators[i].mutators[j].ClassName) != INDEX_NONE)
 					{
 						continue;
 					}
 					seenSingleMuts[seenSingleMuts.length] = mutators[i].mutators[j].ClassName;

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

function handleProfilesData(WebAdminQuery q)
{
	local string currentGameType;
	local array<string> currentMutators;
	local string substMutators, tmp;
	local int idx;

	currentGameType = q.request.getVariable("gametype");
	currentMutators.length = 0;

	webadmin.dataStoreCache.loadGameTypes();
	idx = webadmin.dataStoreCache.resolveGameType(currentGameType);
 	if (idx > INDEX_NONE)
 	{
 		currentGameType = webadmin.dataStoreCache.gametypes[idx].GameMode;
 	}
 	else {
 		currentGameType = "";
 	}

 	for (idx = 0; idx < int(q.request.getVariable("mutatorcount", "0")); idx++)
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

	procVotingMutators(q, currentGameType, currentMutators, substMutators, idx);

	q.response.AddHeader("Content-Type: text/html");

	q.response.SendText("<div id=\"mutators\">");
	q.response.SendText(substMutators);
	q.response.SendText("</div>");

	q.response.SendText("<input type=\"hidden\" id=\"mutatorcount\" value=\""$idx$"\" />");
}

function handleMutators(WebAdminQuery q)
{
	local int i, j, idx;
	local string tmp, mutname;

	webadmin.dataStoreCache.loadMutators();

	if (q.request.GetVariable("action") ~= "save")
	{
		j = q.request.GetVariableCount("mutators");
		class'UTVoteCollector'.default.VotableMutators.length = 0;
		for (i = 0; i < j; i++)
		{
			tmp = `Trim(q.request.GetVariableNumber("mutators", i));
			mutname = tmp;
			for (idx = 0; idx < webadmin.dataStoreCache.mutators.length; idx++)
			{
				if (webadmin.dataStoreCache.mutators[idx].ClassName ~= tmp)
				{
					mutname = webadmin.dataStoreCache.mutators[idx].FriendlyName;
					if (len(mutname) == 0) mutname = tmp;
					break;
				}
			}
			idx = class'UTVoteCollector'.default.VotableMutators.length;
			class'UTVoteCollector'.default.VotableMutators.length = idx+1;
			class'UTVoteCollector'.default.VotableMutators[idx].MutClass = tmp;
			class'UTVoteCollector'.default.VotableMutators[idx].MutName = mutname;
		}
		class'UTVoteCollector'.static.StaticSaveConfig();
		webadmin.addMessage(q, "Settings saved.");
	}

	tmp = "";
	for (i = 0; i < webadmin.dataStoreCache.mutators.length; i++)
	{
		q.response.subst("mutator.classname", `HTMLEscape(webadmin.dataStoreCache.mutators[i].ClassName));
		q.response.subst("mutator.id", "mutfield"$i);
		mutname = webadmin.dataStoreCache.mutators[i].FriendlyName;
		if (len(mutname) == 0) mutname = webadmin.dataStoreCache.mutators[i].ClassName;
		q.response.subst("mutator.friendlyname", `HTMLEscape(mutname));
		q.response.subst("mutator.description", `HTMLEscape(webadmin.dataStoreCache.mutators[i].Description));
		if (class'UTVoteCollector'.default.VotableMutators.find('MutClass', webadmin.dataStoreCache.mutators[i].ClassName) != INDEX_NONE)
 		{
 			q.response.subst("mutator.selected", "checked=\"checked\"");
		}
 		else {
			q.response.subst("mutator.selected", "");
 		}
		tmp $= webadmin.include(q, "voting_mutators_mutator.inc");
	}
	q.response.subst("mutatorcount", tmp);
	q.response.subst("mutators", tmp);
	webadmin.sendPage(q, "voting_mutators.html");
}

defaultproperties
{
    `if(`isdefined(BUILD_AS_MOD))
	bImportLegacyMaplists = true
	`endif
}

`else
function init(WebAdmin webapp);
function cleanup();
function bool handleQuery(WebAdminQuery q);
function bool unhandledQuery(WebAdminQuery q);
function registerMenuItems(WebAdminMenu menu);
`endif
