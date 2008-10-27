/**
 * Chatlogger. Writes files with the following content:
 * timestamp<tab>username<tab>uniqueid<tab>type<tab>teamid<tab>message
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class ChatLog extends MessagingSpectator config (WebAdmin);

/**
 * Mask for the filename. Following place holders can be used:
 * %i = server ip
 * %p = server port
 * %c = computer name (as reported by the OS)
 * %v = engine version
 */
var config string filename;

/**
 * Enforce unique filenames. This will simply add a number to the end of the
 * filename until its unique.
 */
var config bool bUnique;

/**
 * Append a timestamp to the filename
 */
var config bool bIncludeTimeStamp;

var FileWriter writer;

var string tab;

function ReceiveMessage( PlayerReplicationInfo Sender, string Msg, name Type )
{
	local string uniqueid;
	local int teamindex;
	if (sender == none)
	{
		writer.Logf(TimeStamp()$tab$""$tab$""$tab$type$tab$INDEX_NONE$tab$msg);
		return;
	}
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

reliable client event ReceiveLocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	if (ClassIsChildOf(Message, class'GameMessage'))
	{
		ReceiveMessage(RelatedPRI_1, Message.static.GetString(switch, false, RelatedPRI_1, RelatedPRI_2, OptionalObject), name("GameMessage_"$switch));
	}
}

reliable client event TeamMessage( PlayerReplicationInfo PRI, coerce string S, name Type, optional float MsgLifeTime  )
{
	ReceiveMessage(pri, s, type);
}

function CreateFileWriter()
{
	writer = spawn(class'FileWriter');
	writer.OpenFile(createFilename(), FWFT_Log,, bUnique, bIncludeTimeStamp);
	writer.Logf("--- OPEN "$TimeStamp());
}

function string createFilename()
{
	local string result, tmp;
	local InternetLink il;
	local IpAddr addr;

	result = filename;
	result = repl(result, "%p", WorldInfo.Game.GetServerPort());
	result = repl(result, "%c", WorldInfo.ComputerName);
	result = repl(result, "%v", WorldInfo.EngineVersion);
	if (InStr(result, "%i") > INDEX_NONE)
	{
		il = spawn(class'InternetLink');
		il.GetLocalIP(addr);
		tmp = il.IpAddrToString(addr);
		if (InStr(tmp, ":") > INDEX_NONE)
		{
			tmp = Left(tmp, InStr(tmp, ":"));
		}
		result = repl(result, "%i", tmp);
		il.Destroy();
	}
	return result;
}

simulated function PostBeginPlay()
{
	local TeamChatProxy tcp;

	super.PostBeginPlay();
	`Log("Chat logging enabled",,'WebAdmin');
	if (Len(filename) == 0)
	{
		filename = "Chatlog_%i_%p";
	}
	tab = chr(9);

	foreach WorldInfo.AllControllers(class'TeamChatProxy', tcp)
	{
		tcp.AddReceiver(ReceiveMessage);
	}
}

event Destroyed()
{
	local TeamChatProxy tcp;
	foreach WorldInfo.AllControllers(class'TeamChatProxy', tcp)
	{
		tcp.ClearReceiver(ReceiveMessage);
	}
	if (writer != none)
	{
		writer.Logf("--- CLOSE "$TimeStamp());
		writer.CloseFile();
	}
	super.Destroyed();
}

function InitPlayerReplicationInfo()
{
	super.InitPlayerReplicationInfo();
	PlayerReplicationInfo.PlayerName = "<<ChatLogger>>";
}

defaultproperties
{
	bKeepAlive=true
	bUnique=false
	bIncludeTimeStamp=true
	filename="Chatlog_%i_%p"
}