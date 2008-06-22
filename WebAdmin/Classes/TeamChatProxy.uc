/**
 * Provides a proxy for team chat
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class TeamChatProxy extends MessagingSpectator;

reliable client event TeamMessage( PlayerReplicationInfo PRI, coerce string S, name Type, optional float MsgLifeTime  )
{
	local delegate<ReceiveMessage> rm;

	if (type != 'TeamSay') return;
	foreach receivers(rm)
	{
		rm(pri, s, type);
	}
}

function InitPlayerReplicationInfo()
{
	super.InitPlayerReplicationInfo();
	PlayerReplicationInfo.PlayerName = "<<TeamChatProxy>>";
}

defaultProperties
{
	bKeepAlive=true
}