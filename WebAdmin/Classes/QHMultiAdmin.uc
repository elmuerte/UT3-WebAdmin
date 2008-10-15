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
	local string editAdmin;
	local string tmp;
	local int i;
	local MultiAdminData adminData;

	editAdmin = q.request.getVariable("adminid");

	tmp = "";
	for (i = 0; i < authModule.records.length; i++)
	{
		q.response.subst("multiadmin.name", `HTMLEscape(authModule.records[i].name));
		if (authModule.records[i].name ~= editAdmin)
		{
			q.response.subst("multiadmin.selected", "selected=\"selected\"");
		}
		else {
			q.response.subst("multiadmin.selected", "");
		}
		tmp $= webadmin.include(q, "multiadmin_admin_select.inc");
	}
	q.response.subst("admins", tmp);

	if (len(editAdmin) > 0)
	{
		adminData = authModule.getRecord(editAdmin);
	}
	q.response.subst("editor", "");
	if (adminData != none)
	{
		q.response.subst("adminid", `HTMLEscape(adminData.name));
		q.response.subst("displayname", `HTMLEscape(adminData.displayName));
		if (adminData.order == DenyAllow)
		{
			q.response.subst("order.denyallow", "checked=\"checked\"");
			q.response.subst("order.allowdeny", "");
		}
		else if (adminData.order == AllowDeny)
		{
			q.response.subst("order.allowdeny", "checked=\"checked\"");
			q.response.subst("order.denyallow", "");
		}
		else {
			q.response.subst("order.denyallow", "");
			q.response.subst("order.allowdeny", "");
		}
		tmp = "";
		for (i = 0; i < adminData.allow.length; i++)
		{
			if (len(tmp) > 0) tmp $= chr(10);
			tmp $= adminData.allow[i];
		}
		q.response.subst("allow", tmp);
		tmp = "";
		for (i = 0; i < adminData.deny.length; i++)
		{
			if (len(tmp) > 0) tmp $= chr(10);
			tmp $= adminData.deny[i];
		}
		q.response.subst("deny", tmp);
		q.response.subst("editor", webadmin.include(q, "multiadmin_editor.inc"));
	}

	webadmin.sendPage(q, "multiadmin.html");
}

defaultproperties
{
}