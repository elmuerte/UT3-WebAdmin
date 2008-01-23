/**
 * The query handler interface. The WebAdmin contains a collection of query
 * handlers with handle most requests assigned to the WebAdmin application.
 * During creating the query handler will receive a couple of set up calls:
 * init(...) and registerMenuItems(...). The webadmin has to register all
 * URLs it will handle (url without the webapp path prefix). It is also allowed
 * to replace an existing menu item. When the WebAdmin is shut down the
 * cleanup() method will be called. Use this to perform some clean up and to set
 * all Actor references to none (in case the query handler extends Object).
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
 * Cleanup (prepare for being destroyed). If the implementation extends Object
 * it should set all actor references to none.
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
