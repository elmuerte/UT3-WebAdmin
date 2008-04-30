/**
 * Default "simple" authentication handler implementation.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class BasicWebAdminAuth extends Object implements(IWebAdminAuth) config(WebAdmin);

var AccessControl ac;

var WorldInfo worldinfo;

var array<BasicWebAdminUser> users;

/**
 * If this is not empty the simple authentication handler will require this
 * username. Otherwise any username accepted by the current AccessControl will
 * be accepted. In case of the standard AccessControl this means that any
 * username is ok.
 */
var config array<string> RequireUsername;

function init(WorldInfo wi)
{
	local int i;
	worldinfo = wi;
	ac = worldinfo.Game.AccessControl;
	for (i = RequireUsername.length-1; i >= 0; i--)
	{
		if (Len(RequireUsername[i]) == 0)
		{
			RequireUsername.remove(i, 1);
		}
	}
}

function cleanup()
{
	local IWebAdminUser user;
	foreach users(user)
	{
		user.logout();
	}
	users.remove(0, users.length);
	worldinfo = none;
	ac = none;
}

function IWebAdminUser authenticate(string username, string password, out string errorMsg)
{
	local BasicWebAdminUser user;
	if (ac == none)
	{
		`Log("No AccessControl instance.",,'WebAdminAuth');
		errorMsg = "No AccessControl instance.";
		return none;
	}
	if (RequireUsername.length > 0 && RequireUsername.find(username) == INDEX_NONE)
    {
        errorMsg = "Invalid credentials.";
        return none;
    }
	if (ac.ValidLogin(username, password))
	{
		user = worldinfo.spawn(class'BasicWebAdminUser');
		user.init();
		user.setUsername(username);
		users.AddItem(user);
		return user;
	}
	errorMsg = "Invalid credentials.";
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
	if (RequireUsername.length > 0 && RequireUsername.find(username) == INDEX_NONE)
    {
        errorMsg = "Invalid credentials.";
        return false;
    }
	if (ac.ValidLogin(username, password))
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
