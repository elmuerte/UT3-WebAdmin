/**
 * Session handler interface
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
interface ISessionHandler;

/**
 * Create a new session
 */
function ISession create();

/**
 * Get an existing session. Returns none when there is no session with that id.
 */
function ISession get(string id);

/**
 * Destroy the given session.
 */
function bool destroy(ISession session);

/**
 * Destroy all sessions
 */
function destroyAll();
