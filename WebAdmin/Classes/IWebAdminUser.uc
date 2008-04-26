/**
 * A webadmin user record. Creates by the IWebAdminAuth instance.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
interface IWebAdminUser;

struct MessageEntry
{
	var int counter;
	/**
	 * Can be none
	 */
	var PlayerReplicationInfo sender;
	var string senderName;
	var string message;
	/**
	 * Say, TeamSay, None
	 */
	var name type;
	var string teamName;
	var color teamColor;
	/**
	 * INDEX_NONE if not a member of a team
	 */
	var int teamId;
};

/**
 * Return the name of the user
 */
function string getUsername();

/**
 * Used to check for permissions to perform given actions.
 *
 * @param path an URL containing the action description. See rfc2396 for more information.
 * 				The scheme part of the URL will be used as identifier for the interface.
 *				The host is the IP to witch the webserver is bound.
 *				for example:	webadmin://127.0.0.1:8080/current/console
 *				Note that the webapplication path is not included.
 */
function bool canPerform(string url);


/**
 * Return a PlayerController associated with this user. This method might return
 * none when there is no player controller associated with this user.
 */
function PlayerController getPC();

/**
 * Get the message history.
 */
function messageHistory(out array<MessageEntry> history, optional int startingFrom);
