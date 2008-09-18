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

	//TODO import legacy data
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
			}
			handleMaplist(q);
			return true;
		case "/voting/mutators":
			// ...
			return true;
		case "/voting/profiles":
			// ...
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
	menu.addMenu("/voting/profiles", "Game Profiles", self, "...", -1);
	menu.addMenu("/voting/maplist", "Map lists", self, "The map list management allows you to create and edit the map lists as used by the game profiles");
	menu.addMenu("/voting/mutators", "Mutators", self, "...");
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
					webadmin.addMessage(q, "Created the map list "$tmp);
				}
				else {
					webadmin.addMessage(q, "Error creating map list: "$tmp, MT_Error);
					editMLname = "";
				}
			}
			else {
				webadmin.addMessage(q, "There is already a map list with the name: "$tmp, MT_Error);
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
			webadmin.addMessage(q, "No map list available with the id: "$editMLname, MT_Error);
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
					ParseStringIntoArray(tmp, tmpb, "?", true);
					if (tmpb.length == 0) continue;
					ml.Maps.length = ml.Maps.length+1;
					ml.Maps[ml.Maps.length-1].Map = tmpb[0];
					for (j = 1; j < tmpb.length; j++)
					{
						tmp2 = tmpb[j];
						n = InStr(tmp2, "=");
						if (n != INDEX_NONE)
						{
							ml.Maps[ml.Maps.length-1].ExtraData.length = j;
							ml.Maps[ml.Maps.length-1].ExtraData[j-1].Key = name(Left(tmp2, n));
							ml.Maps[ml.Maps.length-1].ExtraData[j-1].Value = Mid(tmp2, n+1);
						}
						else {
							ml.Maps[ml.Maps.length-1].ExtraData[j-1].Key = name(tmp2);
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
					tmp $= "?"$ml.maps[i].ExtraData[j].key;
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
			webadmin.addMessage(q, "No map list available with the id: "$editMLname, MT_Error);
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

defaultproperties
{
	bImportLegacyMaplists = true
}

`else
function init(WebAdmin webapp);
function cleanup();
function bool handleQuery(WebAdminQuery q);
function bool unhandledQuery(WebAdminQuery q);
function registerMenuItems(WebAdminMenu menu);
`endif