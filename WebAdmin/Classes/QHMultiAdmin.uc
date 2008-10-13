/**
 *
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class QHMultiAdmin extends Object implements(IQueryHandler) config(WebAdmin)
	dependson(WebAdminUtils);

`include(WebAdmin.uci)

var MultiWebAdminAuth authModule;
var WebAdmin webadmin;

function init(WebAdmin webapp)
{
	local int i;
	local string clsname;

	webadmin = webapp;
	clsname = class.getPackageName()$"."$class.name;
	if (authModule == none)
	{
		`Log("Authentication module is not MultiWebAdminAuth, unregistering QHMultiAdmin",,'WebAdmin');
		for (i = 0; i < webadmin.QueryHandlers.Length; i++)
		{
			if (webadmin.QueryHandlers[i] ~= clsname)
			{
				webadmin.QueryHandlers.Remove(i, 1);
				webadmin.SaveConfig();
				break;
			}
		}
		cleanup();
		return;
	}
	else {
		for (i = 0; i < webadmin.handlers.Length; i++)
		{
			if (webadmin.handlers[i] == self)
			{
				break;
			}
		}
		if (i == webadmin.handlers.Length)
		{
			webadmin.handlers[i] = self;
		}
	}
}

function cleanup()
{
	authModule = none;
	webadmin = none;
}

function bool handleQuery(WebAdminQuery q)
{
	if (authModule == none) return false;
	switch (q.request.URI)
	{
		case "/multiadmin":
			handleAdmins(q);
			return true;
	}
}

function bool unhandledQuery(WebAdminQuery q)
{
	return false;
}

function registerMenuItems(WebAdminMenu menu)
{
	if (authModule == none) return;
	menu.addMenu("/multiadmin", "Administrators", self, "Manage WebAdmin administrators.", 1000);
}

function handleAdmins(WebAdminQuery q)
{
	local string tmp;
	local int i;

	tmp = "";
	for (i = 0; i < authModule.records.length; i++)
	{
		q.response.subst("admin.name", `HTMLEscape(authModule.records[i].name));
		tmp $= webadmin.include(q, "multiadmin_admin_select.inc");
	}
	q.response.subst("admins", tmp);

	webadmin.sendPage(q, "multiadmin.html");
}

defaultproperties
{
}