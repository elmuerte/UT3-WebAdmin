/**
 * Basic webadmin user.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class BasicWebAdminUser extends Info implements(IWebAdminUser);

var MessagingSpectator PC;

var int maxHistory;
var int counter;
var array<MessageEntry> msgHistory;

function ReceiveMessage( PlayerReplicationInfo Sender, string Msg, name Type )
{
	local int idx;
	idx = msgHistory.length;
	msgHistory.Add(1);
	msgHistory[idx].counter = ++counter;
	msgHistory[idx].Sender = Sender;
	if (Sender != none)
	{
		msgHistory[idx].senderName = Sender.GetPlayerAlias();
	}
	else {
		msgHistory[idx].senderName = "";
	}
	msgHistory[idx].message = msg;
	msgHistory[idx].type = type;
	if (Sender.Team != none)
	{
		msgHistory[idx].teamName = Sender.Team.GetHumanReadableName();
		msgHistory[idx].teamColor = Sender.Team.GetHUDColor();
		msgHistory[idx].teamId = Sender.Team.TeamIndex;
	}
	else {
		msgHistory[idx].teamId = INDEX_NONE;
	}

	idx = msgHistory.Length - maxHistory;
	if (idx > 0)
	{
		msgHistory.Remove(0, idx);
	}
}

function init()
{
	local TeamChatProxy tcp;

	PC = WorldInfo.Spawn(class'MessagingSpectator');
	PC.ReceiveMessage = ReceiveMessage;

	foreach WorldInfo.AllControllers(class'TeamChatProxy', tcp)
	{
		tcp.AddReceiver(ReceiveMessage);
	}
}

function logout()
{
	Destroy();
}

event Destroyed()
{
	local TeamChatProxy tcp;
	if (PC != none)
	{
		PC.ReceiveMessage = none;
		PC.Destroy();
	}
	foreach WorldInfo.AllControllers(class'TeamChatProxy', tcp)
	{
		tcp.ClearReceiver(ReceiveMessage);
	}
	super.Destroyed();
}

function setUsername(string username)
{
	PC.PlayerReplicationInfo.PlayerName = username;
}

function string getUsername()
{
	return PC.PlayerReplicationInfo.PlayerName;
}

function PlayerController getPC()
{
	return PC;
}

function bool canPerform(string uri)
{
	// only one admin type, can perform whatever (s)he wants
	return true;
}

function messageHistory(out array<MessageEntry> history, optional int startingFrom)
{
	local int idx, i;
	idx = msgHistory.find('counter', startingFrom);
	for (i = idx+1; i < msgHistory.Length; i++)
	{
		history.addItem(msgHistory[i]);
	}
}

defaultproperties
{
	maxHistory = 25
}
