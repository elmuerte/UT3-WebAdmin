/**
 * The query handler interface
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
interface IQueryHandler;

struct KeyValuePair
{
	var string key;
	var string value;
};

/**
 * Struct contain current query information. Passed to the QueryHandlers.
 */
struct WebAdminQuery
{
	var WebRequest request;
	var WebResponse response;
	var ISession session;
	var IWebAdminUser user;
	var array<KeyValuePair> cookies;
};

/**
 * Called when the WebAdmin creates and initializes this query handler.
 */
function init(WebAdmin webapp);

/**
 * Cleanup (prepare for being destroyed)
 */
function cleanup();

/**
 * Called by the webadmin to request the query handler to handle this query.
 *
 * @return true when the query was handled.
 */
function bool handleQuery(WebAdminQuery q);

/**
 * Called in case of an unhandled path.
 *
 * @return true when the query was handled.
 */
function bool unhandledQuery(WebAdminQuery q);

/**
 * Called by the webadmin to request the query handler to add its menu items to
 * the web admin menu. The menu is used to determine what query handler will be
 * handle a given path. Paths not registered will be passed to all query handlers
 * until one returns true.
 */
function registerMenuItems(WebAdminMenu menu);
