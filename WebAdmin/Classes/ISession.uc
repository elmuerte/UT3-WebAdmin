/**
 * A session interface
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
interface ISession;

/**
 * Return the session identifier
 */
function string getId();

/**
 * Reset the session's data. The ID will stay the same.
 */
function reset();

/**
 * Get an object instance from this session.
 */
function Object getObject(string key);

/**
 * Add an object to the session
 */
function putObject(string key, Object value);

/**
 * Remove the entry with the given key
 */
function removeObject(string key);

/**
 * Get a string from this session.
 */
function string getString(string key, optional string defValue = "");

/**
 * Add a string value to the session.
 */
function putString(string key, string value);

/**
 * Remove the entry with the given key
 */
function removeString(string key);
