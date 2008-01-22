/**
 * Basic webadmin user.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class BasicWebAdminUser extends Info implements(IWebAdminUser);

var MessagingSpectator PC;

function init()
{
	PC = WorldInfo.Spawn(class'MessagingSpectator');
}

function setUsername(string username)
{
	PC.PlayerReplicationInfo.PlayerName = username;
}

function string getUsername()
{
	return PC.PlayerReplicationInfo.PlayerName;
}

function bool canPerform(string uri)
{
	// only one admin type, can perform whatever (s)he wants
	return true;
}
