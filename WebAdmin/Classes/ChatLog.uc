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

var FileWriter writer;

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
	if (writer == none)
	{
		CreateFileWriter();
	}
	writer.Logf(TimeStamp()$tab$Sender.GetPlayerAlias()$tab$uniqueid$tab$type$tab$teamindex$tab$msg);
}

reliable client event TeamMessage( PlayerReplicationInfo PRI, coerce string S, name Type, optional float MsgLifeTime  )
{
	ReceiveMessage(pri, s, type);
}

function CreateFileWriter()
{
	local string serverip;
	writer = spawn(class'FileWriter');

	serverip = WorldInfo.ComputerName;
	serverip $= "_"$WorldInfo.Game.GetServerPort();

	writer.OpenFile("Chatlog_"$serverip, FWFT_Log,, bUnique, bIncludeTimeStamp);
	writer.Logf("--- OPEN "$TimeStamp());
}

simulated function PostBeginPlay()
{
	local TeamChatProxy tcp;

	super.PostBeginPlay();
	tab = chr(9);

	foreach WorldInfo.AllControllers(class'TeamChatProxy', tcp)
	{
		`log(">>>"@tcp);
		tcp.AddReceiver(ReceiveMessage);
	}
}

event Destroyed()
{
	local TeamChatProxy tcp;
	if (writer != none)
	{
		writer.Logf("--- CLOSE "$TimeStamp());
		writer.CloseFile();
	}
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