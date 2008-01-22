/**
 * The main entry point for the UT3 WebAdmin. This manages the initial web page
 * request and authentication and session handling. The eventual processing of
 * the request will be doen by query handlers.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class WebAdmin extends WebApplication dependsOn(IQueryHandler) config(WebAdmin);

/**
 * The menu handler
 */
var WebAdminMenu menu;

/**
 * The authorization handler instance
 */
var IWebAdminAuth auth;

/**
 * Defines the authentication handler class to use instead of the default one.
 */
var config string AuthenticationClass;

/**
 * The default authentication class
 */
var class/*<IWebAdminAuth>*/ defaultAuthClass;

/**
 * The session handler
 */
var ISessionHandler sessions;

/**
 * The session handler to use instead of the default session handler
 */
var config string SessionHandlerClass;

/**
 * The default session handler class
 */
var class/*<ISessionHandler>*/ defaultSessClass;

/**
 * The loaded handlers.
 */
var array<IQueryHandler> handlers;

/**
 * The list of query handlers to automativally load
 */
var config array<string> QueryHandlers;

/**
 * If set to true, use HTTP Basic authentication rather than a HTML form.
 */
var config bool bHttpAuth;

/**
 * local storage. Used to construct the auth URLs.
 */
var protected string serverIp;

function init()
{
	local class/*<IWebAdminAuth>*/ authClass;
	local class/*<ISessionHandler>*/ sessClass;
	local class<Actor> aclass;
	local IpAddr ipaddr;
	local int i;

	super.init();

	menu = new(Self) class'WebAdminMenu';
	menu.webadmin = self;

	if (len(AuthenticationClass) != 0)
	{
		authClass = class(DynamicLoadObject(AuthenticationClass, class'Class'));
	}
	if (authClass == none)
	{
		authClass = defaultAuthClass;
	}

	`Log("Creating IWebAdminAuth instance from: "$authClass,,'WebAdmin');
	if (!ClassIsChildOf(authClass, class'Actor'))
	{
		auth = new(self) authClass;
	}
	else {
		aclass = class<Actor>(DynamicLoadObject(""$authClass, class'Class'));
		auth = Worldinfo.spawn(aclass);
	}
	auth.init(Worldinfo);

	if (len(AuthenticationClass) != 0)
	{
		sessClass = class(DynamicLoadObject(SessionHandlerClass, class'class'));
	}
	if (sessClass == none)
	{
		sessClass = defaultSessClass;
	}

	`Log("Creating ISessionHandler instance from: "$sessClass,,'WebAdmin');
	if (!ClassIsChildOf(sessClass, class'Actor'))
	{
		sessions = new(self) sessClass;
	}
	else {
		aclass = class<Actor>(DynamicLoadObject(""$sessClass, class'Class'));
		sessions = Worldinfo.spawn(aclass);
	}

	WebServer.GetLocalIP(ipaddr);
	serverIp = WebServer.IpAddrToString(ipaddr);
	i = InStr(serverIp, ":");
	if (i > -1)
	{
		serverIp = left(serverIp, i);
	}

	initQueryHandlers();
}

function CleanupApp()
{
	local IQueryHandler handler;
	super.CleanupApp();
	foreach handlers(handler)
	{
		handler.cleanup();
	}
	handlers.Remove(0, handlers.Length);
	auth.cleanup();
	auth = none;
	sessions.destroyAll();
	sessions = none;
}

protected function initQueryHandlers()
{
	local IQueryHandler qh;
	local string entry;
	local class/*<IQueryHandler>*/ qhc;
	local class<Actor> aclass;

	foreach QueryHandlers(entry)
	{
		qhc = class(DynamicLoadObject(entry, class'class'));
		if (qhc == none)
		{
			`Log("Unable to find query handler class: "$entry,,'WebAdmin');
			continue;
		}
		qh = none;
		if (!ClassIsChildOf(qhc, class'Actor'))
		{
			qh = new(self) qhc;
		}
		else {
			aclass = class<Actor>(DynamicLoadObject(""$qhc, class'Class'));
			qh = Worldinfo.spawn(aclass);
		}
		if (qh == none)
		{
			`Log("Unable to create query handler: "$entry,,'WebAdmin');
		}
		else {
			qh.init(self);
			qh.registerMenuItems(menu);
			addQueryHandler(qh);
		}
	}
}

/**
 * Add a query handler to the list
 */
function addQueryHandler(IQueryHandler qh)
{
	if (handlers.find(qh) != -1)
	{
		return;
	}
	handlers.addItem(qh);
}

/**
 * return the authentication URL string used in the user privileged system.
 */
function string getAuthURL(string forpath)
{
	if (Left(forpath, 1) != "/") forpath = "/"$forpath;
	return "webadmin://"$ serverIp $":"$ WebServer.ListenPort $ forpath;
}

function Query(WebRequest Request, WebResponse Response)
{
	local WebAdminQuery currentQuery;
	local WebAdminMenu wamenu;
	local IQueryHandler handler;

	currentQuery.request = Request;
	currentQuery.response = Response;
	parseCookies(Request.GetHeader("cookie", ""), currentQuery.cookies);
	if (!getSession(currentQuery))
	{
		return;
	}
	if (!getWebAdminUser(currentQuery))
	{
		return;
	}
	response.Subst("admin.name", currentQuery.user.getUsername());

	wamenu = WebAdminMenu(currentQuery.session.getObject("WebAdminMenu"));
	if (wamenu == none)
	{
		wamenu = menu.getUserMenu(currentQuery.user);
		currentQuery.session.putObject("WebAdminMenu", wamenu);
		currentQuery.session.putString("WebAdminMenu.rendered", wamenu.render());
	}
	response.Subst("navigation.menu", currentQuery.session.getString("WebAdminMenu.rendered"));

	`Log("Request uri = "$request.URI,,'WebAdmin');
	if (request.URI == "/")
	{
		sendPage(currentQuery, "index.html");
		return;
	}
	else if (request.URI == "/logout")
	{
		if (auth.logout(currentQuery.user)) {
			sessions.destroy(currentQuery.session);
			Response.Redirect("/");
			Response.AddHeader("Set-Cookie: sessionid=; Path="$path$"/");
			return;
		}
		pageGenericError(currentQuery, "Unable to log out");
		return;
	}
	// get proper handler
	handler = wamenu.getHandlerFor(request.URI);
	if ((handler != none) && handler.handleQuery(currentQuery))
	{
		return;
	}
	// try other way
	foreach handlers(handler)
	{
		if (handler.unhandledQuery(currentQuery))
		{
			return;
		}
	}

	Response.HTTPResponse("HTTP/1.1 404 Not Found");
	pageGenericError(currentQuery, "Request page not found");
}

protected function parseCookies(String cookiehdr, out array<KeyValuePair> cookies)
{
	local array<string> cookieParts;
	local string entry;
	local int pos;
	local KeyValuePair kvp;

	ParseStringIntoArray(cookiehdr, cookieParts, ";", true);
	foreach cookieParts(entry)
	{
		pos = InStr(entry, "=");
		if (pos > -1)
		{
			kvp.key = Left(entry, pos);
			kvp.value = Mid(entry, pos+1);
			`Log("Received cookie with name="$kvp.key$" ; value="$kvp.value,,'WebAdmin');
			cookies.AddItem(kvp);
		}
	}
}

/**
 * Adds the ISession instance to query
 */
protected function bool getSession(out WebAdminQuery q)
{
	local string sessionId;
	local int idx;

	idx = q.cookies.Find('key', "sessionid");
	if (idx > -1)
	{
		sessionId = q.cookies[idx].value;
	}
	if (len(sessionId) == 0)
	{
		sessionId = q.request.GetVariable("sessionid");
	}
	if (len(sessionId) > 0)
	{
		q.session = sessions.get(sessionId);
	}
	if (q.session == none)
	{
		q.session = sessions.create();
	}
	if (q.session == none)
	{
		pageGenericError(q, "Unable to create a session. See the log file for details."); // TODO: localize
		return false;
	}
	q.response.Subst("sessionid", q.session.getId());
	q.response.AddHeader("Set-Cookie: sessionid="$q.session.getId()$"; Path="$path$"/");
	return true;
}

/**
 * Retreives the webadmin user. Creates a new one when needed.
 */
protected function bool getWebAdminUser(out WebAdminQuery q)
{
	local string username, password, token, errorMsg;

	local string realm;
	if (bHttpAuth)
	{
		realm = "UT3 WebAdmin - "$worldinfo.Game.GameReplicationInfo.ServerName;
		q.response.AddHeader("WWW-authenticate: basic realm=\""$realm$"\"");
		q.session.putString("UsedHttpAuth", "1");
	}

	q.user = q.session.getObject("IWebAdminUser");
	// 1: find existing user
	if (q.user != none)
	{
		if (q.session.getString("UsedHttpAuth") == "1")
		{
			// not really needed
			if (!auth.validate(q.request.Username, q.request.Password, errorMsg))
			{
				pageAuthentication(q, errorMsg);
				return false;
			}
		}
		return true;
	}
	// 2: try to authenticate
	if (len(q.request.Username) > 0 && len(q.request.Password) > 0)
	{
		username = q.request.Username;
		password = q.request.Password;
		token = "true";
		q.session.putString("AuthFormToken", token);
	}
	else {
		username = q.request.GetVariable("username");
		password = q.request.GetVariable("password");
		token = q.request.GetVariable("token");
	}

	if (len(username) == 0 || len(password) == 0)
	{
		pageAuthentication(q, "");
		return false;
	}

	// check data
	if (len(token) == 0 || token != q.session.getString("AuthFormToken"))
	{
		pageAuthentication(q, "Invalid form data."); // TODO: localize
		return false;
	}
	q.user = auth.authenticate(username, password, errorMsg);

	if (q.user == none)
	{
		pageAuthentication(q, errorMsg);
		return false;
	}
	q.session.putObject("IWebAdminUser", q.user);
	return true;
}

/**
 * Include the specified file
 */
function string include(WebAdminQuery q, string file)
{
	return q.response.LoadParsedUHTM(Path $ "/" $ file);
}

/**
 * Load the given file and send it to the client
 */
function sendPage(WebAdminQuery q, string file)
{
	q.response.IncludeUHTM(Path $ "/" $ file);
	q.response.ClearSubst();
}

/**
 * Create a generic error message
 */
function pageGenericError(WebAdminQuery q, coerce string errorMsg)
{
	q.response.Subst("message", errorMsg);
	sendPage(q, "error.html");
}

/**
 * Produces the authentication page.
 */
function pageAuthentication(WebAdminQuery q, string errorMsg)
{
	local string token;
	if (bHttpAuth)
	{
		q.response.HTTPResponse("HTTP/1.1 401 Unauthorized");
		pageGenericError(q, "Unauthorized access");
		return;
	}
	token = Right(ToHex(Rand(MaxInt)), 4)$Right(ToHex(Rand(MaxInt)), 4);
	q.session.putString("AuthFormToken", token);
	q.response.Subst("message", errorMsg);
	q.response.Subst("token", token);
	sendPage(q, "login.html");
}

defaultproperties
{
	defaultAuthClass=class'BasicWebAdminAuth'
	defaultSessClass=class'SessionHandler'
}
