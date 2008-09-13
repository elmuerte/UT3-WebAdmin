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
	menu.addMenu("/voting/maplist", "Maps", self, "...");
	menu.addMenu("/voting/mutators", "Mutators", self, "...");
	menu.addMenu("/voting/profiles", "Game Profiles", self, "...");
}

function handleMaplist(WebAdminQuery q)
{
	local int i;
	local string tmp, tmp2, editMLname;
	local UTMapList ml;

	if (mapLists.length == 0)
	{
		populateListNames();
	}

	editMLname = q.request.getVariable("maplistid");

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
			q.response.subst("maplistid", `HTMLEscape(editMLname));
			i = maplists.find('name', editMLname);
			if (i != INDEX_NONE)
			{
				q.response.subst("friendlyname", `HTMLEscape(maplists[i].friendlyName));
			}
			q.response.subst("autoloadprefixes", `HTMLEscape(repl(ml.AutoLoadPrefixes, ",", chr(10)$chr(13))));

			q.response.subst("editor", webadmin.include(q, "voting_maplist_editor.inc"));
		}
		else {
			webadmin.addMessage(q, "No map list available with the id: "$editMLname, MT_Error);
		}
	}
	else {
		webadmin.addMessage(q, "Maplist editing is not available because no map list manager is loaded.", MT_Error);
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