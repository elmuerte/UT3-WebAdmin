/**
 * Holds a list of messages for the current session.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */

class WebAdminMessages extends Object dependson(IQueryHandler);

var array<Message> messages;

function addMessage(string msg, optional EMessageType type = MT_Information)
{
	local Message newmsg;
	if (len(msg) == 0) return;
	newmsg.text = msg;
	newmsg.type = type;
	messages.AddItem(newmsg);
}

function string renderMessages(WebAdmin wa, WebAdminQuery q)
{
	local string result;
	local Message msg;
	foreach messages(msg)
	{
		q.response.subst("message", msg.text);
		switch(msg.type)
		{
			case MT_Information:
				result $= wa.include(q, "message_info.inc");
				break;
			case MT_Warning:
				result $= wa.include(q, "message_warn.inc");
				break;
			case MT_Error:
				result $= wa.include(q, "message_error.inc");
				break;
		}
	}
	q.response.subst("messages", result);
	messages.length = 0;
	return wa.include(q, "messages.inc");;
}
