/**
 * Authentication handler that accepts multiple user accounts
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class MultiWebAdminAuth extends Object implements(IWebAdminAuth) config(WebAdmin);

`include(WebAdmin.uci)

var WorldInfo worldinfo;

var array<MultiWebAdminUser> users;

/**
 * Contains a list of known names and the associated data (when instantiated)
 */
struct UserRecord
{
	var string name;
	var MultiAdminData data;
};
var array<UserRecord> records;

//!localization
var localized string InvalidCreds, NoAdmins;

function init(WorldInfo wi)
{
	worldinfo = wi;
	loadRecords();
	loadQueryHandler();
}

function loadRecords()
{
	local array<string> names;
	local int i, j;
	local int idx;
	local string tmp;

	GetPerObjectConfigSections(class'MultiAdminData', names);
	for (i = 0; i < names.length; i++)
	{
		idx = InStr(names[i], " ");
		if (idx == INDEX_NONE) continue;
		tmp = Left(names[i], idx);
		for (j = 0; j < records.length; j++)
		{
			if (caps(records[j].name) > caps(tmp))
			{
				records.insert(j, 1);
				records[j].name = tmp;
				break;
			}
		}
		if (j == records.length)
		{
			records.length = j+1;
			records[j].name = tmp;
		}
	}
	if (records.length == 0)
	{
		records.length = 1;
		records[0].name = "Admin";
		records[0].data = new(none, records[0].name) class'MultiAdminData';
		tmp = worldinfo.game.consolecommand("get engine.accesscontrol adminpassword", false);
		if (len(tmp) == 0) tmp = "Admin";
		records[0].data.setPassword(tmp);
		records[0].data.SaveConfig();
		`Log("Created initial webadmin administrator account: "$records[0].name,,'WebAdmin');
	}
}

function loadQueryHandler()
{
	local QHMultiAdmin qh;
	local WebAdmin webadmin;
	local WebServer ws;
	local int i;

	if (WebAdmin(Outer) != none)
	{
		webadmin = WebAdmin(Outer);
	}
	else {
		foreach worldinfo.AllActors(class'WebServer', ws)
		{
			break;
		}
		if (ws == none) return;
		for (i = 0; i < ArrayCount(ws.ApplicationObjects); i++)
		{
			if (WebAdmin(ws.ApplicationObjects[i]) != none)
			{
				webadmin = WebAdmin(ws.ApplicationObjects[i]);
				break;
			}
		}
	}

	if (webadmin == none) return;
	qh = new class'QHMultiAdmin';
	qh.authModule = self;
	qh.init(webadmin);
	qh.registerMenuItems(webadmin.menu);
}

function MultiAdminData getRecord(string username)
{
	local int idx;
	idx = records.find('name', username);
	if (idx == INDEX_NONE)
	{
		return none;
	}
	if (records[idx].data == none)
	{
		records[idx].data = new(none, records[idx].name) class'MultiAdminData';
	}
	return records[idx].data;
}

function bool removeAdminRecord(string username)
{
    `if(`UT3_PATCH_1_4)
	local int idx;
	local MultiAdminData data;

	idx = records.find('name', username);
	if (idx == INDEX_NONE)
	{
		return false;
	}
	if (records[idx].data == none)
	{
		records[idx].data = new(none, records[idx].name) class'MultiAdminData';
	}
	data = records[idx].data;
	data.ClearConfig();

	records.remove(idx, 1);
	for (idx = users.length-1; idx >= 0; idx--)
	{
		if (users[idx].adminData == data)
		{
			logout(users[idx]);
		}
	}
	return true;
	`endif
	return false;
}

function cleanup()
{
	local IWebAdminUser user;
	foreach users(user)
	{
		user.logout();
	}
	users.remove(0, users.length);
	records.length = 0;
	worldinfo = none;
}

function IWebAdminUser authenticate(string username, string password, out string errorMsg)
{
	local MultiWebAdminUser user;
	local MultiAdminData adminData;

	adminData = getRecord(username);
	if (adminData == none)
    {
        errorMsg = InvalidCreds;
        if (records.length == 0)
        {
        	errorMsg @= NoAdmins;
        }
        return none;
    }
	if (adminData.matchesPassword(password))
	{
		user = worldinfo.spawn(class'MultiWebAdminUser');
		user.adminData = adminData;
		user.init();
		user.setUsername(adminData.getDisplayName());
		users.AddItem(user);
		return user;
	}
	errorMsg = InvalidCreds;
	return none;
}

function bool logout(IWebAdminUser user)
{
	user.logout();
	users.RemoveItem(user);
	return true;
}

function bool validate(string username, string password, out string errorMsg)
{
	local MultiAdminData adminData;
	adminData = getRecord(username);
	if (adminData == none)
    {
        errorMsg = InvalidCreds;
        return false;
    }
    if (adminData.matchesPassword(password))
	{
		return true;
	}
	errorMsg = InvalidCreds;
	return false;
}

function bool validateUser(IWebAdminUser user, out string errorMsg)
{
	return true;
}
