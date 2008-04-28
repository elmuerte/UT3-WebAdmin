/**
 * Provides a proxy for team chat
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class TeamChatProxy extends MessagingSpectator;

var array< delegate<ReceiveMessage> > receivers;

function AddReceiver(delegate<ReceiveMessage> ReceiveMessageDelegate)
{
	if (receivers.Find(ReceiveMessageDelegate) == INDEX_NONE)
	{
		receivers[receivers.Length] = ReceiveMessageDelegate;
	}
}

function ClearReceiver(delegate<ReceiveMessage> ReceiveMessageDelegate)
{
	local int RemoveIndex;
	RemoveIndex = receivers.Find(ReceiveMessageDelegate);
	if (RemoveIndex != INDEX_NONE)
	{
		receivers.Remove(RemoveIndex,1);
	}
}

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
	PlayerReplicationInfo.PlayerName = "TeamChatProxy";
}

defaultProperties
{

}