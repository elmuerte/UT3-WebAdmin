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

/**
 * If true the legacy alternative map lists are imported to the new configuration
 */
var config bool bImportLegacyMaplists;

/**
 * Called when the WebAdmin creates and initializes this query handler.
 */
function init(WebAdmin webapp)
{
	webadmin = webapp;

	//TODO import legacy data
}

/**
 * Cleanup (prepare for being destroyed). If the implementation extends Object
 * it should set all actor references to none.
 */
function cleanup()
{
	webadmin = none;
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
	menu.addMenu("/voting/gametypes", "Gametypes", self, "...");
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