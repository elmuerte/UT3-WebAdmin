/**
 * Query handler for the multi admin access control.
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

/**
 * A list of administrator names that are protected. These can not be deleted
 * at all. And can not be modified by themselves.
 */
var config array<string> protectedAdmins;

var string fullMenu;

//!localization
var localized string menuAdmins, menuAdminsDesc, msgCreatedAdmin, msgDupName,
	msgCantRemoveLast, msgCantDelete, msgRemovedAdmin, msgUnableToRemove,
	msgSavedAdmin, msgPassError;

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

function bool producesXhtml()
{
	return true;
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
	menu.addMenu("/multiadmin", menuAdmins, self, menuAdminsDesc, 1000);
}

function handleAdmins(WebAdminQuery q)
{
	local string editAdmin;
	local string tmp;
	local array<string> tmpa;
	local int i;
	local MultiAdminData adminData;

	editAdmin = q.request.getVariable("adminid");

	if ((q.request.getVariable("action") ~= "create") || (q.request.getVariable("action") ~= "create administrator"))
	{
		if (len(editAdmin) > 0)
		{
			if (authModule.records.find('name', editAdmin) == INDEX_NONE)
			{
				adminData = new(none, editAdmin) class'MultiAdminData';
				adminData.SaveConfig();
				for (i = 0; i < authModule.records.length; i++)
				{
					if (caps(authModule.records[i].name) > caps(editAdmin))
					{
						authModule.records.insert(i, 1);
						authModule.records[i].name = editAdmin;
						authModule.records[i].data = adminData;
						break;
					}
				}
				if (i == authModule.records.length)
				{
					authModule.records.length = i+1;
					authModule.records[i].name = editAdmin;
					authModule.records[i].data = adminData;
				}
				webadmin.addMessage(q, repl(msgCreatedAdmin, "%s", editAdmin));
			}
			else {
				webadmin.addMessage(q, repl(msgDupName, "%s", editAdmin), MT_Error);
				editAdmin = "";
			}
		}
		else {
			webadmin.addMessage(q, "No name given.", MT_Error);
		}
	}

	if (q.request.getVariable("action") ~= "delete")
	{
		if (authModule.records.length <= 1)
		{
			webadmin.addMessage(q, msgCantRemoveLast, MT_Error);
		}
		else if (len(editAdmin) > 0)
		{
			if (!canDeleteAdmin(editAdmin, q.user))
			{
				webadmin.addMessage(q, repl(msgCantDelete, "%s", editAdmin), MT_Error);
			}
			else if (authModule.removeAdminRecord(editAdmin))
			{
				webadmin.addMessage(q, repl(msgRemovedAdmin, "%s", editAdmin));
			}
			else {
				webadmin.addMessage(q, repl(msgUnableToRemove, "%s", editAdmin), MT_Error);
			}
		}
	}

	tmp = "";
	for (i = 0; i < authModule.records.length; i++)
	{
		if (!canEditAdmin(authModule.records[i].name, q.user)) continue;
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
		if (q.request.getVariable("action") ~= "save" && canEditAdmin(editAdmin, q.user))
		{
			tmp = q.request.getVariable("password1");
			if (tmp == q.request.getVariable("password2"))
			{
				if (len(tmp) > 0)
				{
					adminData.setPassword(tmp);
				}
				adminData.displayName = q.request.getVariable("displayname");

				ParseStringIntoArray(q.request.getVariable("allow"), tmpa, chr(10), true);
				adminData.allow.length = 0;
				for (i = 0; i < tmpa.length; i++)
				{
					tmp = `Trim(tmpa[i]);
					if (len(tmp) == 0) continue;
					adminData.allow[adminData.allow.length] = tmp;
				}

				ParseStringIntoArray(q.request.getVariable("deny"), tmpa, chr(10), true);
				adminData.deny.length = 0;
				for (i = 0; i < tmpa.length; i++)
				{
					tmp = `Trim(tmpa[i]);
					if (len(tmp) == 0) continue;
					adminData.deny[adminData.deny.length] = tmp;
				}

				if (q.request.getVariable("order") ~= "AllowDeny") {
					adminData.order = AllowDeny;
				}
				else {
					adminData.order = DenyAllow;
				}

				adminData.saveconfig();
				webadmin.addMessage(q, msgSavedAdmin);
			}
			else {
				webadmin.addMessage(q, msgPassError, MT_Error);
			}
		}

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

		if (!canDeleteAdmin(string(adminData.name), q.user))
		{
			q.response.subst("allowdelete", "disabled=\"disabled\"");
		}
		else {
			q.response.subst("allowdelete", "");
		}

		if (len(fullMenu) == 0)
		{
			fullMenu = webadmin.menu.render("/multiadmin_editor_menu.inc", "/multiadmin_editor_menuitem.inc");
		}
		q.response.subst("menueditor", fullMenu);

		q.response.subst("editor", webadmin.include(q, "multiadmin_editor.inc"));
	}

	webadmin.sendPage(q, "multiadmin.html");
}

/**
 * True if the user can be deleted. Users can not delete themselves.
 */
function bool canDeleteAdmin(string adminName, IWebAdminUser me)
{
    `if(`UT3_PATCH_1_4)
	if (protectedAdmins.find(adminName) != INDEX_NONE)
	{
		return false;
	}
	if (me.getUserid() ~= adminName)
	{
		return false;
	}
	return true;
	`else
	return false;
	`endif
}

/**
 * True if the user can be edited. Users can edit themselves if they are protected.
 */
function bool canEditAdmin(string adminName, IWebAdminUser me)
{
	if (protectedAdmins.find(adminName) != INDEX_NONE)
	{
		if (me.getUserid() ~= adminName)
		{
			return true;
		}
		return false;
	}
	return true;
}

defaultproperties
{
}
