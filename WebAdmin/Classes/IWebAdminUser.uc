/**
 * A webadmin user record. Creates by the IWebAdminAuth instance.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
interface IWebAdminUser;

/**
 * Return the name of the user
 */
function string getUsername();

/**
 * Used to check for permissions to perform given actions.
 *
 * @param path an URL containing the action description. See rfc2396 for more information.
 * 				The scheme part of the URL will be used as identifier for the interface.
 *				for example:	webadmin://127.0.0.1:8080/current/console
 *				Note that the webapplication path is not included.
 */
function bool canPerform(string url);
