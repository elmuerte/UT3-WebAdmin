/**
 * A administrator record
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class MultiAdminData extends Object perobjectconfig config(MultiAdmin);

/**
 * The name to show. It does not have to be the same as the login name.
 */
var config string displayName;

/**
 * The password for this user
 */
var private config string password;

/**
 * Which list to process first
 */
enum EAccessOrder
{
	DenyAllow,
	AllowDeny,
};

/**
 * Sets the order in which the allow and deny options should be processed
 */
var config EAccessOrder order;

/**
 * URL segments to allow or deny. An empty list means "all".
 */
var config array<string> allow, deny;

/**
 * return the display name
 */
function string getDisplayName()
{
	if (len(displayName) == 0)
	{
		return string(name);
	}
	return displayName;
}

function setPassword(string pw)
{
	if (len(pw) > 0)
	{
		password = pw;
	}
}

/**
 * return true when the password matches
 */
function bool matchesPassword(string pw)
{
	return (password == pw) && (len(pw) > 0);
}

/**
 * Return true if this user can access this location. This is just the path part
 * not the full uri as the IWebAdminUser gets.
 */
function bool canAccess(string loc)
{
	if (order == DenyAllow)
	{
		if (matchDenied(loc))
		{
			if (!matchAllowed(loc)) return false;
		}
		return true;
	}
	else if (order == AllowDeny)
	{
		if (!matchAllowed(loc)) return false;
		if (matchDenied(loc)) return false;
		return false;
	}
	return true;
}

/**
 * True if the uri matches any entry
 */
function bool matchAllowed(string loc)
{
	local string m;
	foreach allow(m)
	{
		if (MaskedCompare(loc, m))
		{
			`log(loc@" matches "@m);
			return true;
		}
	}
	return false;
}

/**
 * True if the uri matches any denied entry
 */
function bool matchDenied(string loc)
{
	local string m;
	foreach deny(m)
	{
		if (MaskedCompare(loc, m))
		{
			`log(loc@" matches "@m);
			return true;
		}
	}
	return false;
}

/**
 * Check if the target matches the mask, which can contain * for * or more
 * matching characters.
 */
static final function bool MaskedCompare(coerce string target, string mask)
{
	local int i, off;
	local string part;

	if (mask == "*") return true;

	i = InStr(mask, "*");
	if (i == INDEX_NONE)
	{
		i = Len(mask);
		off = 0;
	}
	else {
		off = 1; // so the * is eaten
	}
	if (i > 0) // check prefix
	{
		if (left(target, i) != left(mask, i)) return false; // prefix doesn't match
		// eat prefixes
		target = mid(target, i);
	}
	mask = mid(mask, i+off);
	while ((len(target) > 0) && (len(mask) > 0))
	{
		i = InStr(mask, "*");
		if (i == INDEX_NONE)
		{
			i = Len(mask);
			off = 0;
		}
		else {
			off = 1; // so the * is eaten
		}
		if (i > 0)
		{
			part = left(mask, i); // part is to be found in target
			i = InStr(target, part);
			if (i == INDEX_NONE) return false; // part doesn't exist
			target = Mid(target, i+len(part));
		}
		mask = Mid(mask, len(part)+off); // +1 for the '*'
	}

	// if the target is empty everything matched
	// or if off == 1 the mask ended in an *
	return (len(target) == 0 && len(mask) == 0) || (off == 1 && len(mask) == 0);
}

defaultproperties
{
	order=DenyAllow
}
