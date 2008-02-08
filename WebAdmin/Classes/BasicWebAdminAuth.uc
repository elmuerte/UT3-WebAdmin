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
var config string RequireUsername;

function init(WorldInfo wi)
{
    `Log("RequireUsername = "$RequireUsername);
	worldinfo = wi;
	ac = worldinfo.Game.AccessControl;
}

function cleanup()
{
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
	if (Len(RequireUsername) > 0 && RequireUsername != username)
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
	users.RemoveItem(user);
	return true;
}

function bool validate(string username, string password, out string errorMsg)
{
    if (Len(RequireUsername) > 0 && RequireUsername != username)
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
