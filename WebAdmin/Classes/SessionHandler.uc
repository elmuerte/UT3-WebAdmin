/**
 * Default session handler implementation
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class SessionHandler extends Object implements(ISessionHandler) dependson(WebAdminUtils);

`define WITH_BROKEN_RAND

struct SessionKV
{
	var string id;
	var Session s;
};

var protected array<SessionKV> sessions;

function ISession create()
{
	local SessionKV skv;
	local WebAdminUtils.DateTime dt;
	local int i;

	`if(WITH_BROKEN_RAND)
	// seed the broken rand function
	class'WebAdminUtils'.static.getDateTime(dt);
	for (i = 0; i < dt.second+dt.minute+dt.day; i++)
	{
		rand(0xffff);
	}
	`endif

	skv.s = new(Self) class'Session';
	skv.id = skv.s.getId();
	sessions.AddItem(skv);
	//`Log("Created a new session with id: "$skv.id,,'WebAdmin');
	return skv.s;
}

function ISession get(string id)
{
	local int idx;
	idx = sessions.Find('id', id);
	if (idx > -1)
	{
		//`Log("Found session with id: "$id,,'WebAdmin');
		return sessions[idx].s;
	}
	return none;
}

function bool destroy(ISession session)
{
	local int idx;
	idx = sessions.Find('s', session);
	if (idx > -1)
	{
		session.reset();
		//`Log("Destroyed session with id: "$sessions[idx].id,,'WebAdmin');
		sessions.remove(idx, 1);
		return true;
	}
	return false;
}

function destroyAll()
{
	local int i;
	for (i = 0; i < sessions.length; i++)
	{
		sessions[i].s.reset();
	}
	sessions.Remove(0, sessions.Length);
}
