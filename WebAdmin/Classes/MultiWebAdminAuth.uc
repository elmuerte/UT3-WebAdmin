/**
 * Authentication handler that accepts multiple user accounts
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class MultiWebAdminAuth extends Object implements(IWebAdminAuth) config(WebAdmin);

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

function init(WorldInfo wi)
{
	worldinfo = wi;
	loadRecords();
	loadQueryHandler();
}

function loadRecords()
{
	local array<string> names;
	local int i;
	local int idx;

	GetPerObjectConfigSections(class'MultiAdminData', names);
	records.length = names.length;
	for (i = 0; i < names.length; i++)
	{
		idx = InStr(names[i], " ");
		if (idx == INDEX_NONE) continue;
		records[i].name = Left(names[i], idx);
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
        errorMsg = "Invalid credentials.1";
        if (records.length == 0)
        {
        	errorMsg @= "No administrators have been created. Please update the configuration.";
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
	errorMsg = "Invalid credentials.2";
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
        errorMsg = "Invalid credentials.";
        return false;
    }
    if (adminData.matchesPassword(password))
	{
		return true;
	}
	errorMsg = "Invalid credentials.";
	return false;
}

function bool validateUser(IWebAdminUser user, out string errorMsg)
{
	return true;
}
