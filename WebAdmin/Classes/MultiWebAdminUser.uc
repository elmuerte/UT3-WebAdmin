/**
 * The webadmin user used for the multi admin authentication
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class MultiWebAdminUser extends BasicWebAdminUser;

var MultiAdminData adminData;

function logout()
{
	adminData = none;
	super.logout();
}

function bool canPerform(string uri)
{
	local int idx;
	if (adminData != none)
	{
		if (left(uri, 11) ~= "webadmin://")
		{
			idx = InStr(Mid(uri, 11), "/");
			if (idx != INDEX_NONE)
			{
				uri = Mid(uri, idx+11);
				if (uri == "/") return true; // always allow root
				return adminData.canAccess(uri);
			}
		}
	}
	return false;
}

defaultproperties
{
}
