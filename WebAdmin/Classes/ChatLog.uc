/**
 * Chatlogger. Writes files with the following content:
 * timestamp<tab>username<tab>uniqueid<tab>type<tab>teamid<tab>message
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class ChatLog extends MessagingSpectator config (WebAdmin);

var config bool bUnique;
var config bool bIncludeTimeStamp;

var FileWriter log;

var string tab;

function ReceiveMessage( PlayerReplicationInfo Sender, string Msg, name Type )
{
	local string uniqueid;
	local int teamindex;
	uniqueid = class'OnlineSubsystem'.static.UniqueNetIdToString(Sender.UniqueId);
	if (Sender.Team == none)
	{
		teamindex = INDEX_NONE;
	}
	else {
		teamindex = Sender.Team.TeamIndex;
	}
	log.Logf(TimeStamp()$tab$Sender.GetPlayerAlias()$tab$uniqueid$tab$type$tab$teamindex$tab$msg);
}

reliable client event TeamMessage( PlayerReplicationInfo PRI, coerce string S, name Type, optional float MsgLifeTime  )
{
	ReceiveMessage(pri, s, type);
}

simulated function PostBeginPlay()
{
	local TeamChatProxy tcp;
	local string serverip;

	super.PostBeginPlay();
	tab = chr(9);
	log = spawn(class'FileWriter');

	serverip = WorldInfo.ComputerName;
	serverip $= "_"$WorldInfo.Game.GetServerPort();

	log.OpenFile("Chatlog_"$serverip, FWFT_Log,, bUnique, bIncludeTimeStamp);
	log.Logf("--- OPEN "$TimeStamp());
	foreach WorldInfo.AllControllers(class'TeamChatProxy', tcp)
	{
		tcp.AddReceiver(ReceiveMessage);
	}
}

event Destroyed()
{
	local TeamChatProxy tcp;
	log.Logf("--- CLOSE "$TimeStamp());
	log.CloseFile();
	foreach WorldInfo.AllControllers(class'TeamChatProxy', tcp)
	{
		tcp.ClearReceiver(ReceiveMessage);
	}
	super.Destroyed();
}

function InitPlayerReplicationInfo()
{
	super.InitPlayerReplicationInfo();
	PlayerReplicationInfo.PlayerName = "ChatLogger";
}

defaultProperties
{

}