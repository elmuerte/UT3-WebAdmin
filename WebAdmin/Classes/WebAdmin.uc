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

`include(WebAdmin.uci)

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
var globalconfig string AuthenticationClass;

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
var globalconfig string SessionHandlerClass;

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
var globalconfig array<string> QueryHandlers;

/**
 * If set to true, use HTTP Basic authentication rather than a HTML form. Using
 * HTTP authentication gives the functionality of automatic re-authentication.
 */
var globalconfig bool bHttpAuth;

/**
 * The starting page. Defaults to /current
 */
var globalconfig string startpage;

/**
 * local storage. Used to construct the auth URLs.
 */
var protected string serverIp;

`if(`isdefined(COOKIE_PREFIX))
/**
 * Prefix used in cookie names to make them safer for multiple servers on the
 * same machine.
 */
var string cookiePrefix;
`endif

/**
 * Will contain the timestamp when this package was compiled
 */
var const string timestamp;

/**
 * The webadmin version
 */
var const string version;

/**
 * Minimum engine version required.
 */
var const int minengine;

var protected bool isOutdatedEngine;

/**
 * Cached datastore values
 */
var DataStoreCache dataStoreCache;

/**
 * If true start the chatlogging functionality
 */
var globalconfig bool bChatLog;

/**
 * A hack to cleanup the stale PlayerController instances which are not being
 * garbage collected but stay around due to the streaming level loading.
 */
var PCCleanUp pccleanup;

/**
 * Used to keep track of config file updated to make sure certain changes are
 * made. The dedicated server doesn't automatically merge updated config files.
 */
var globalconfig int cfgver;

/**
 * If true pages will be served as application/xhtml+xml when the browser
 * supports it, and when the QH claims it supports it.
 */
var globalconfig bool bUseStrictContentType;

var array<WebAdminSkin> Skins;

var string SkinData;

/**
 * Number of octets in the IPv4 to validate for the session. for example, a
 * value of 3 allows the IP to be between x.y.z.0-x.y.z.255 . A value of 0
 * disables validation. Values higher than 4 are useless (because of IPv4).
 */
var globalconfig int sessionOctetValidation;


//!localization
var localized string menuLogout, menuLogoutDesc, AccessDenied, msgNoPrivs,
	msgNoStartPage, msgLogoutNotice, msgUnableToLogout, error404, msgNotFound,
	msgSessionCreateFail, msgWrongAuthCookie, error403, error401, pageLogin,
	pageLoginDesc, pageAboutTitle, pageAboutDesc, pageCreditsTitle, msgUnknownDataType;

/**
 * Defines a subdirectory who's files will override the standard files. Used for
 * localized files.
 */
var localized string HTMLSubDirectory;

function init()
{
	local class/*<IWebAdminAuth>*/ authClass;
	local class/*<ISessionHandler>*/ sessClass;
	local class<Actor> aclass;
	local IpAddr ipaddr;
	local int i;
	local bool doSaveConfig;
	local string tmp;

    `Log("Starting UT3 WebAdmin v"$version$" - "$timestamp,,'WebAdmin');

    if (int(worldinfo.EngineVersion) < minengine)
    {
    	`Log("ERROR! This version requires a newer game version.",,'WebAdmin');
    	`Log("Required version: "$minengine,,'WebAdmin');
    	`Log("Engine version:   "$worldinfo.EngineVersion,,'WebAdmin');
    	isOutdatedEngine = true;
    	return;
    }

    doSaveConfig = false;

    CleanupMsgSpecs();

    `if(WITH_WEBCONX_FIX)
	WebServer.AcceptClass = class'WebConnectionEx';
    `endif

	if (class'WebConnection'.default.MaxValueLength < 4096)
	{
		class'WebConnection'.default.MaxValueLength = 4096;
		class'WebConnection'.static.StaticSaveConfig();
	}

	super.init();

	if (QueryHandlers.length == 0)
	{
		QueryHandlers[0] = class.getPackageName()$".QHCurrent";
		QueryHandlers[1] = class.getPackageName()$".QHDefaults";
		doSaveConfig = true;
	}
	if (cfgver < 1)
	{
		tmp = class.getPackageName()$".QHVoting";
		if (QueryHandlers.find(tmp) == INDEX_NONE)
		{
			QueryHandlers[QueryHandlers.length] = tmp;
		}

		doSaveConfig = true;
		cfgver = 1;
	}
	if (cfgver < 2)
	{
		tmp = class.getPackageName()$".WebAdminSystemSettings";
		if (QueryHandlers.find(tmp) == INDEX_NONE)
		{
			QueryHandlers[QueryHandlers.length] = tmp;
		}
		doSaveConfig = true;
		cfgver = 2;
	}
	if (cfgver < 3)
	{
		sessionOctetValidation = 3;
		doSaveConfig = true;
		cfgver = 3;
	}

	if (doSaveConfig)
	{
		SaveConfig();
	}

	dataStoreCache = new(Self) class'DataStoreCache';

	menu = new(Self) class'WebAdminMenu';
	menu.webadmin = self;
	menu.addMenu("/about", "", none,, MaxInt-1);
	menu.addMenu("/credits", "", none,, MaxInt-1);
	menu.addMenu("/data", "", none,, MaxInt-1);
	menu.addMenu("/logout", menuLogout, none, menuLogoutDesc, MaxInt);

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

	if (len(SessionHandlerClass) != 0)
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
	if (i > INDEX_NONE)
	{
		serverIp = left(serverIp, i);
	}

	`if(`isdefined(COOKIE_PREFIX))
	cookiePrefix = "%"$worldinfo.Game.GetServerPort()$"_";
	`endif

	initQueryHandlers();
}

function loadWebAdminSkins()
{
	local int i;
	local array<UTUIResourceDataProvider> ProviderList;

	class'UTUIDataStore_MenuItems'.static.GetAllResourceDataProviders(class'WebAdminSkin', ProviderList);
	for (i = 0; i < ProviderList.length; i++)
	{
		Skins[i] = WebAdminSkin(ProviderList[i]);
	}
}

function CreateChatLog()
{
	if (bChatLog)
	{
		WorldInfo.Spawn(class'ChatLog');
	}
}

function CleanupMsgSpecs()
{
	WorldInfo.Spawn(class'PCCleanUp');
}

/**
 * Clean up the webapplication and everything associated with it.
 */
function CleanupApp()
{
	local IQueryHandler handler;
	foreach handlers(handler)
	{
		handler.cleanup();
	}
	handlers.Remove(0, handlers.Length);
	menu.menu.Remove(0, menu.menu.length);
	menu = none;
	auth.cleanup();
	auth = none;
	sessions.destroyAll();
	sessions = none;
	dataStoreCache.cleanup();
	dataStoreCache = none;
	super.CleanupApp();
}

/**
 * Load the registered query handlers
 */
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
			addQueryHandler(qh);
		}
	}
}

/**
 * Add a query handler to the list. This will also call init() and
 * registerMenuItems() on the query handler.
 */
function addQueryHandler(IQueryHandler qh)
{
	if (handlers.find(qh) != INDEX_NONE)
	{
		return;
	}
	qh.init(self);
	qh.registerMenuItems(menu);
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

/**
 * Main entry point for the webadmin
 */
function Query(WebRequest Request, WebResponse Response)
{
	local WebAdminQuery currentQuery;
	local WebAdminMenu wamenu;
	local IQueryHandler handler;
	local string title, description;
	local bool acceptsXhtmlXml;
	local int i;

    response.Subst("build.timestamp", timestamp);
	response.Subst("build.version", version);
	response.Subst("webadmin.path", path);
	response.Subst("page.uri", Request.URI);
	response.Subst("page.fulluri", Path$Request.URI);
	response.Subst("random", Rand(MaxInt));

	if (len(SkinData) == 0)
	{
		if (skins.length == 0)
		{
			loadWebAdminSkins();
		}
		for (i = 0; i < Skins.length; i++)
		{
			response.Subst("webadminskin.name", `HTMLEscape(Skins[i].name));
			response.Subst("webadminskin.friendlyname", `HTMLEscape(Skins[i].FriendlyName));
			response.Subst("webadminskin.cssfile", `HTMLEscape(Skins[i].cssfile));
			SkinData $= response.LoadParsedUHTM(Path $ "/webadminskin_meta.inc");
		}
		if (skins.length == 0)
		{
			SkinData $= " ";
		}
	}
	response.Subst("webadminskins.meta", SkinData);

	if (InStr(Request.GetHeader("accept-encoding")$",", "gzip,") != INDEX_NONE)
	{
		if (InStr(Request.GetHeader("user-agent"), "Safari/") != INDEX_NONE)
		{
			// Safari lies, it doesn't support gzip encoded files
			response.Subst("client.gzip", "");
		}
		else if (InStr(Request.GetHeader("user-agent"), "MSIE 6.") != INDEX_NONE)
		{
			// MSIE 6. has issues with gzip
			response.Subst("client.gzip", "");
		}
		else {
			response.Subst("client.gzip", ".gz");
		}
	}
	else {
		response.Subst("client.gzip", "");
	}

	if (InStr(Request.GetHeader("accept"), "application/xhtml+xml") != INDEX_NONE)
	{
		acceptsXhtmlXml = bUseStrictContentType;
	}

	if (WorldInfo.IsInSeamlessTravel())
	{
		if (acceptsXhtmlXml) response.AddHeader("Content-Type: application/xhtml+xml");
		response.HTTPResponse("HTTP/1.1 503 Service Unavailable");
		response.subst("html.headers", "<meta http-equiv=\"refresh\" content=\"10\"/>");
		response.IncludeUHTM(Path $ "/servertravel.html");
		response.ClearSubst();
		return;
	}
	if (isOutdatedEngine)
	{
		if (acceptsXhtmlXml) response.AddHeader("Content-Type: application/xhtml+xml");
		response.HTTPResponse("HTTP/1.1 503 Service Unavailable");
		response.Subst("engine.version", worldinfo.EngineVersion);
		response.Subst("webadmin.minengine", minengine);
		response.IncludeUHTM(Path $ "/outdated.html");
		response.ClearSubst();
		return;
	}

	currentQuery.request = Request;
	currentQuery.response = Response;
	parseCookies(Request.GetHeader("cookie", ""), currentQuery.cookies);

	if (!getSession(currentQuery))
	{
		return;
	}

	if (len(pageAboutTitle) == 0)
	{
		addMessage(currentQuery, "No localization data. Please make sure the file Localization/INT/WebAdmin.int is up to date.", MT_Error);
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
		if (wamenu != none)
		{
			currentQuery.session.putObject("WebAdminMenu", wamenu);
			currentQuery.session.putString("WebAdminMenu.rendered", wamenu.render());
		}
	}
	if (wamenu == none)
	{
		Response.HTTPResponse("HTTP/1.1 403 Forbidden");
		pageGenericError(currentQuery, msgNoPrivs, AccessDenied);
		return;
	}
	response.Subst("navigation.menu", currentQuery.session.getString("WebAdminMenu.rendered"));

	if (request.URI == "/")
	{
		if (len(startpage) != 0)
		{
			Response.Redirect(path$startpage);
			return;
		}
		pageGenericError(currentQuery, msgNoStartPage);
		return;
	}
	else if (request.URI == "/logout")
	{
		if (auth.logout(currentQuery.user))
		{
			sessions.destroy(currentQuery.session);
			//response.headers[response.headers.length] = "Set-Cookie: sessionid=; Path="$path$"/; Max-Age=0";
			sendCookie(currentQuery, "sessionid", "", path, 0);
			//response.headers[response.headers.length] = "Set-Cookie: authcred=; Path="$path$"/; Max-Age=0";
			sendCookie(currentQuery, "authcred", "", path, 0);
			//response.headers[response.headers.length] = "Set-Cookie: authtimeout=; Path="$path$"/; Max-Age=0";
			sendCookie(currentQuery, "authtimeout", "", path, 0);
			if (bHttpAuth)
			{
				response.Subst("navigation.menu", "");
				//response.headers[response.headers.length] = "Set-Cookie: forceAuthentication=1; Path="$path$"/";
				sendCookie(currentQuery, "forceAuthentication", "1", path);
				addMessage(currentQuery, msgLogoutNotice, MT_Warning);
				pageGenericInfo(currentQuery, "");
				return;
			}
			Response.Redirect(path$"/");
			return;
		}
		pageGenericError(currentQuery, msgUnableToLogout);
		return;
	}
	else if (request.URI == "/about")
	{
		if (acceptsXhtmlXml) response.AddHeader("Content-Type: application/xhtml+xml");
		pageAbout(currentQuery);
		return;
	}
	else if (request.URI == "/data")
	{
		pageData(currentQuery);
		return;
	}
	else if (request.URI == ("/"$currentQuery.session.getId()) )
	{
		if (acceptsXhtmlXml) response.AddHeader("Content-Type: application/xhtml+xml");
		pageCredits(currentQuery);
		return;
	}

	// get proper handler
	handler = wamenu.getHandlerFor(request.URI, title, description);
	if (handler != none)
	{
		if (acceptsXhtmlXml && handler.producesXhtml()) response.AddHeader("Content-Type: application/xhtml+xml");
		response.Subst("page.title", title);
		response.Subst("page.description", description);
		if (handler.handleQuery(currentQuery))
		{
			return;
		}
	}

	if (currentQuery.user.canPerform(getAuthURL(request.URI))) {
		// try other way
		foreach handlers(handler)
		{
			if (handler.unhandledQuery(currentQuery))
			{
				return;
			}
		}
	}

	// check with the overal menu, if the handler is null the page doesn't exist
	if (acceptsXhtmlXml) response.AddHeader("Content-Type: application/xhtml+xml");
	if (menu.getHandlerFor(request.URI, title, description) == none)
	{
		Response.HTTPResponse("HTTP/1.1 404 Not Found");
		pageGenericError(currentQuery, msgNotFound, error404);
	}
	else {
		Response.HTTPResponse("HTTP/1.1 403 Forbidden");
		pageGenericError(currentQuery, msgNoPrivs, AccessDenied);
	}
}

/**
 * Parse the cookie HTTP header
 */
protected function parseCookies(String cookiehdr, out array<KeyValuePair> cookies)
{
	local array<string> cookieParts;
	local string entry;
	local int pos;
	local KeyValuePair kvp;

	`if(`isdefined(COOKIE_PREFIX))
	local string prefix;
	local int pfpos;
	`endif

	ParseStringIntoArray(cookiehdr, cookieParts, ";", true);
	foreach cookieParts(entry)
	{
		pos = InStr(entry, "=");
		if (pos > INDEX_NONE)
		{
			kvp.key = Left(entry, pos);
			kvp.key -= " ";
			`if(`isdefined(COOKIE_PREFIX))
			if (left(kvp.key, 1) == "%")
			{
				// check prefix
				pfpos = InStr(kvp.key, "_");
				if (pfpos != INDEX_NONE)
				{
					prefix = mid(kvp.key, 1, pfpos-1);
					if (prefix == string(int(prefix)))
					{
						if (left(kvp.key, len(cookiePrefix)) != cookiePrefix)
						{
							continue;
						}
						kvp.key = mid(kvp.key, len(cookiePrefix));
						pfpos = cookies.Find('key', kvp.key);
						if (pfpos != INDEX_NONE)
						{
							cookies.remove(pfpos, 1);
						}
					}
				}
			}
			`endif
			kvp.value = Mid(entry, pos+1);
			//`Log("Received cookie with name="$kvp.key$" ; value="$kvp.value,,'WebAdmin');
			cookies.AddItem(kvp);
		}
	}
}

/**
 * Send a cookie to the client. Returns true when the cookie was included in
 * the output. If the headers where already send false will be returned.
 */
function bool sendCookie(out WebAdminQuery q, string key, coerce string value,
	optional string cpath = "", optional int maxage = -1, optional string domain = "")
{
	local string cookie;
	if (q.response.SentText()) return false;
	key = `trim(key);
	if (len(key) == 0) return false;
	`if(`isdefined(COOKIE_PREFIX))
	key = cookiePrefix$key; // add prefix
	`endif
	cookie = "Set-Cookie: "$key$"="$value;
	if (len(cpath) > 0)
	{
		if (right(cpath, 1) != "/") cpath $= "/";
		cookie $= "; path="$cpath;
	}
	if (len(domain) > 0)
	{
		cookie $= "; domain="$domain;
	}
	if (maxage > -1)
	{
		cookie $= "; max-age="$maxage;
	}
	q.response.headers[q.response.headers.length] = cookie;
	return true;
}

/**
 * Adds the ISession instance to query
 */
protected function bool getSession(out WebAdminQuery q)
{
	local string sessionId;
	local int idx;

	idx = q.cookies.Find('key', "sessionid");
	if (idx > INDEX_NONE)
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
		if (q.session != none && sessionOctetValidation > 0)
		{
			validateSessionOctet(q);
		}
	}
	if (q.session == none)
	{
		q.session = sessions.create();
		idx = inStr(q.request.RemoteAddr, ":");
		if (idx == INDEX_NONE) idx = len(q.request.RemoteAddr);
		q.session.putString("AuthIP", Left(q.request.RemoteAddr, idx));
		//q.response.headers[q.response.headers.length] = "Set-Cookie: sessionid="$q.session.getId()$"; Path="$path$"/";
		sendCookie(q, "sessionid", q.session.getId(), path);
	}
	if (q.session == none)
	{
		pageGenericError(q, msgSessionCreateFail); // TODO: localize
		return false;
	}
	q.response.Subst("sessionid", q.session.getId());
	return true;
}

protected function validateSessionOctet(out WebAdminQuery q)
{
	local array<string> ip1, ip2;
	local int i;
	i = inStr(q.request.RemoteAddr, ":");
	if (i == INDEX_NONE) i = len(q.request.RemoteAddr);
	ParseStringIntoArray(Left(q.request.RemoteAddr, i), ip1, ".", false);
	ParseStringIntoArray(q.session.getString("AuthIP", "0.0.0.0"), ip2, ".", false);
	ip1.length = sessionOctetValidation;
	ip2.length = sessionOctetValidation;
	for (i = 0; i < ip1.length; ++i)
	{
		if (int(ip1[i]) != int(ip2[i]))
		{
			q.session = none;
			break;
		}
	}
}

/**
 * Retreives the webadmin user. Creates a new one when needed.
 */
protected function bool getWebAdminUser(out WebAdminQuery q)
{
	local string username, password, token, errorMsg, rememberCookie;
	local int idx;
	local bool checkToken;

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
				addMessage(q, errorMsg, MT_Error);
				pageAuthentication(q);
				return false;
			}
		}
		else {
			if (q.session.getString("AuthTimeout") == "1")
			{
				if (q.cookies.Find('key', "authcred") == INDEX_NONE)
				{
					q.session.removeString("AuthTimeout");
					q.session.removeObject("IWebAdminUser");
					auth.logout(q.user);
					q.user = none;
					addMessage(q, "Session timeout.", MT_Error);
					pageAuthentication(q);
					return false;
				}
			}
			setAuthCredCookie(q, "", -2);
		}
		return true;
	}

	idx = q.cookies.Find('key', "authcred");
	if (idx != INDEX_NONE)
	{
		rememberCookie = q.cookies[idx].value;
	}
	else {
		rememberCookie = "";
	}

	checkToken = false;

	// 2: try to authenticate
	if (len(q.request.Username) > 0 && len(q.request.Password) > 0)
	{
		username = q.request.Username;
		password = q.request.Password;
		if (bHttpAuth)
		{
			idx = q.cookies.Find('key', "forceAuthentication");
			if (idx != INDEX_NONE && q.cookies[idx].value == "1")
			{
				//q.response.headers[q.response.headers.length] = "Set-Cookie: forceAuthentication=; Path="$path$"/; Max-Age=0";
				sendCookie(q, "forceAuthentication", "", path, 0);
				pageAuthentication(q);
				return false;
			}
		}
	}
	else if (len(rememberCookie) > 0)
	{
		username = q.request.DecodeBase64(rememberCookie);
		idx = InStr(username, Chr(10));
		if (idx != INDEX_NONE)
		{
			password = Mid(username, idx+1);
			username = Left(username, idx);
		}
		else {
			username = "";
		}
	}

	// not set, check request variables
	if (len(username) == 0 || len(password) == 0)
	{
		username = q.request.GetVariable("username");
		password = q.request.GetVariable("password");
		token = q.request.GetVariable("token");
		checkToken = true;
	}

	// request authentication
	if (len(username) == 0 || len(password) == 0)
	{
		pageAuthentication(q);
		return false;
	}

	// check data
	if (checkToken && (len(token) == 0 || token != q.session.getString("AuthFormToken")))
	{
		addMessage(q, "Invalid form data.", MT_Error);
		pageAuthentication(q);
		return false;
	}
	q.user = auth.authenticate(username, password, errorMsg);

	if (q.user == none)
	{
		addMessage(q, errorMsg, MT_Error);
		if (len(rememberCookie) > 0)
		{
			// unset cookie
			//q.response.headers[q.response.headers.length] = "Set-Cookie: authcred=; Path="$path$"/; Max-Age=0";
			sendCookie(q, "authcred", "", path, 0);
			//q.response.headers[q.response.headers.length] = "Set-Cookie: authtimeout=; Path="$path$"/; Max-Age=0";
			sendCookie(q, "authtimeout", "", path, 0);
			addMessage(q, msgWrongAuthCookie, MT_Error);
			rememberCookie = "";
		}
		pageAuthentication(q);
		return false;
	}
	q.session.putObject("IWebAdminUser", q.user);

	`if(`WITH_BASE64ENC)
	if (q.request.GetVariable("remember") != "")
	{
		rememberCookie = q.request.EncodeBase64(username$chr(10)$password);
		setAuthCredCookie(q, rememberCookie, int(q.request.GetVariable("remember")));
	}
	`endif

	return true;
}

/**
 * Set the cookie data to remember the current authetication attempt
 */
function setAuthCredCookie(out WebAdminQuery q, string creddata, int timeout)
{
	local int idx;
	if (timeout == -2)
	{
		idx = q.cookies.Find('key', "authtimeout");
		if (idx != INDEX_NONE)
		{
			timeout = int(q.cookies[idx].value);
		}
		else {
			timeout = 0;
		}
	}
	if (len(creddata) == 0)
	{
		idx = q.cookies.Find('key', "authcred");
		if (idx != INDEX_NONE)
		{
			creddata = q.cookies[idx].value;
		}
	}
	if (len(creddata) == 0)
	{
		return;
	}
	if (timeout > 0)
	{
		//q.response.headers[q.response.headers.length] = "Set-Cookie: authcred="$creddata$"; Path="$path$"/; Max-Age="$timeout;
		sendCookie(q, "authcred", creddata, path, timeout);
		//q.response.headers[q.response.headers.length] = "Set-Cookie: authtimeout="$timeout$"; Path="$path$"/; Max-Age="$timeout;
		sendCookie(q, "authtimeout", timeout, path, timeout);
		q.session.putString("AuthTimeout", "1");
	}
	else if (timeout == -1)
	{
		//q.response.headers[q.response.headers.length] = "Set-Cookie: authcred="$creddata$"; Path="$path$"/";
		sendCookie(q, "authcred", creddata, path);
	}
	// else don't remember
}

/**
 * Get the messages stored for the current user.
 */
function WebAdminMessages getMessagesObject(WebAdminQuery q)
{
	local WebAdminMessages msgs;
	msgs = WebAdminMessages(q.session.getObject("WebAdmin.Messages"));
	if (msgs == none)
	{
		msgs = new class'WebAdminMessages';
		q.session.putObject("WebAdmin.Messages", msgs);
	}
	return msgs;
}

/**
 * Add a certain message. These messages will be processed at a later stage.
 */
function addMessage(WebAdminQuery q, string msg, optional EMessageType type = MT_Information)
{
	local WebAdminMessages msgs;
	if (len(msg) == 0) return;
	msgs = getMessagesObject(q);
	msgs.addMessage(msg, type);
}

/**
 * Render the message structure to HTML.
 */
function string renderMessages(WebAdminQuery q)
{
	local WebAdminMessages msgs;
	msgs = WebAdminMessages(q.session.getObject("WebAdmin.Messages"));
	if (msgs == none) return "";
	return msgs.renderMessages(self, q);
}

/**
 * Include the specified file.
 */
function string include(WebAdminQuery q, string file)
{
	if ((len(HTMLSubDirectory) > 0) && q.response.FileExists(Path $ "/" $ HTMLSubDirectory $ "/" $ file))
	{
		return q.response.LoadParsedUHTM(Path $ "/" $ HTMLSubDirectory $ "/" $ file);
	}
	return q.response.LoadParsedUHTM(Path $ "/" $ file);
}

/**
 * Load the given file and send it to the client.
 */
function sendPage(WebAdminQuery q, string file)
{
	q.response.Subst("messages", renderMessages(q));
	if ((len(HTMLSubDirectory) > 0) && q.response.FileExists(Path $ "/" $ HTMLSubDirectory $ "/" $ file))
	{
		q.response.IncludeUHTM(Path $ "/" $ HTMLSubDirectory $ "/" $ file);
	}
	else {
		q.response.IncludeUHTM(Path $ "/" $ file);
	}
	q.response.ClearSubst();
}

/**
 * Create a generic error message.
 */
function pageGenericError(WebAdminQuery q, coerce string errorMsg, optional string title = "Error")
{
	if (q.acceptsXhtmlXml) q.response.AddHeader("Content-Type: application/xhtml+xml");
	q.response.Subst("page.title", title);
	q.response.Subst("page.description", "");
	addMessage(q, errorMsg, MT_Error);
	sendPage(q, "message.html");
}

/**
 * Create a generic information message.
 */
function pageGenericInfo(WebAdminQuery q, coerce string msg, optional string title = "Information")
{
	if (q.acceptsXhtmlXml) q.response.AddHeader("Content-Type: application/xhtml+xml");
	q.response.Subst("page.title", title);
	q.response.Subst("page.description", "");
	addMessage(q, msg);
	sendPage(q, "message.html");
}

/**
 * Produces the authentication page.
 */
function pageAuthentication(WebAdminQuery q)
{
	local string token;
	if (q.request.getVariable("ajax") == "1")
	{
		q.response.HTTPResponse("HTTP/1.1 403 Forbidden");
		pageGenericError(q, msgNoPrivs, error403);
		return;
	}
	if (bHttpAuth)
	{
		q.response.HTTPResponse("HTTP/1.1 401 Unauthorized");
		pageGenericError(q, msgNoPrivs, error401);
		return;
	}
	if (q.acceptsXhtmlXml) q.response.AddHeader("Content-Type: application/xhtml+xml");
	token = Right(ToHex(Rand(MaxInt)), 4)$Right(ToHex(Rand(MaxInt)), 4);
	q.session.putString("AuthFormToken", token);
	q.response.Subst("page.title", pageLogin);
	q.response.Subst("page.description", pageLoginDesc);
	q.response.Subst("token", token);
	sendPage(q, "login.html");
}

/**
 * Show the about page
 */
function pageAbout(WebAdminQuery q)
{
	q.response.Subst("page.title", pageAboutTitle);
	q.response.Subst("page.description", pageAboutDesc);
	q.response.Subst("engine.version", worldinfo.EngineVersion);
	q.response.Subst("engine.netversion", worldinfo.MinNetVersion);
	q.response.Subst("game.version", Localize("UTUIFrontEnd", "VersionText", "utgame"));
	q.response.Subst("client.address", q.request.RemoteAddr);
	q.response.Subst("webadmin.address", serverIp$":"$WebServer.ListenPort);
	if (bHttpAuth) q.response.Subst("webadmin.authmethod", "HTTP Authentication");
	else q.response.Subst("webadmin.authmethod", "Login form");
	if (q.cookies.Find('key', "authcred") > INDEX_NONE) q.response.Subst("client.remember", "True");
	else q.response.Subst("client.remember", "False");
	q.response.Subst("client.sessionid", q.session.getId());
	q.response.Subst("client.authip", q.session.getString("AuthIP"));
	q.response.Subst("client.useragent", q.request.GetHeader("user-agent"));
	q.response.Subst("webadmin.build.profile", `BUILD_PROFILE);
	sendPage(q, "about.html");
}

/**
 * Show the credit page
 */
function pageCredits(WebAdminQuery q)
{
	q.response.Subst("page.title", pageCreditsTitle);
	q.response.Subst("credits", `HTMLEscape(Localize("Credits", "01", "UTGameCredits")));
	sendPage(q, "credits.html");
}

/**
 * Generic XML data provider, could be used by AJAX calls.
 */
function pageData(WebAdminQuery q)
{
	local string tmp;
	local int i, j;

	local UTUIDataProvider_GameModeInfo gametype;
	local array<UTUIDataProvider_MapInfo> maps;
	local array<MutatorGroup> mutators;

	q.response.AddHeader("Content-Type: text/xml");
	q.response.SendText("<request>");

	tmp = q.request.getVariable("type");
	if (tmp == "gametypes") {
		dataStoreCache.loadGameTypes();
		q.response.SendText("<gametypes>");
		foreach dataStoreCache.gametypes(gametype)
	 	{
 			if (gametype.bIsCampaign)
 			{
 				continue;
	 		}
	 		q.response.SendText("<gametype>");
	 		q.response.SendText("<class>"$`HTMLEscape(gametype.GameMode)$"</class>");
	 		q.response.SendText("<friendlyname>"$`HTMLEscape(class'WebAdminUtils'.static.getLocalized(gametype.FriendlyName))$"</friendlyname>");
 			q.response.SendText("</gametype>");
	 	}
		q.response.SendText("</gametypes>");
	}
	else if (tmp == "maps") {
		q.response.SendText("<maps>");
		maps = dataStoreCache.getMaps(q.request.getVariable("gametype"));
 		for (i = 0; i < maps.length; i++)
 		{
 			q.response.SendText("<map>");
 			q.response.SendText("<name>"$`HTMLEscape(maps[i].MapName)$"</name>");
 			q.response.SendText("<friendlyname>"$`HTMLEscape(class'WebAdminUtils'.static.getLocalized(maps[i].FriendlyName))$"</friendlyname>");
 			q.response.SendText("</map>");
 		}
 		q.response.SendText("</maps>");
	}
	else if (tmp == "mutators") {
		mutators = dataStoreCache.getMutators(q.request.getVariable("gametype"));
 		for (i = 0; i < mutators.length; i++)
 		{
 			q.response.SendText("<mutatorGroup>");
			q.response.SendText("<name>"$`HTMLEscape(mutators[i].GroupName)$"</name>");
			q.response.SendText("<mutators>");
			for (j = 0; j < mutators[i].mutators.length; j++)
	 		{
	 			q.response.SendText("<mutator>");
	 			q.response.SendText("<class>"$`HTMLEscape(mutators[i].mutators[j].ClassName)$"</class>");
	 			q.response.SendText("<friendlyname>"$`HTMLEscape(mutators[i].mutators[j].FriendlyName)$"</friendlyname>");
	 			q.response.SendText("</mutator>");
	 		}
			q.response.SendText("</mutators>");
 			q.response.SendText("</mutatorGroup>");
 		}
	}
	else {
		addMessage(q, msgUnknownDataType@tmp, MT_Error);
	}

	q.response.SendText("<messages><![CDATA[");
	q.response.SendText(renderMessages(q));
	q.response.SendText("]]></messages>");
	q.response.SendText("</request>");
}

defaultproperties
{
	defaultAuthClass=class'BasicWebAdminAuth'
	defaultSessClass=class'SessionHandler'

	timestamp=`{WEBADMIN_TIMESTAMP}
	version=`{WEBADMIN_VERSION}
	minengine=`{WEBADMIN_MINENGINE}

    `if(`isdefined(BUILD_AS_MOD))
	// config
	bHttpAuth=false
	bChatLog=false
	sessionOctetValidation=3
	startpage="/current"
	QueryHandlers[0]="WebAdmin.QHCurrent"
	QueryHandlers[1]="WebAdmin.QHDefaults"

	//!localization
	menuLogout="Log out"
	menuLogoutDesc="Log out from the webadmin and clear all authentication information."
	AccessDenied="Access Denied"
	msgNoPrivs="You do not have the privileges to view this page."
	msgNoStartPage="No starting page."
	msgLogoutNotice="To properly log out you will need to close the webbrowser to clear the saved authentication information."
	msgUnableToLogout="Unable to log out."
	error404="Error 404 - Page not found"
	error403="Error 403 - Forbidden"
	error401="Error 401 - Unauthorized"
	msgNotFound="The requested page was not found."
	msgSessionCreateFail="Unable to create a session. See the log file for details."
	msgWrongAuthCookie="Authentication cookie does not contain correct information."
	pageLogin="Login"
	pageLoginDesc="Log in using the administrator username and password. Cookies must be enabled for this site."
	pageAboutTitle="About"
	pageAboutDesc="Various information about the UT3 WebAdmin"
	pageCreditsTitle="Credits"
	msgUnknownDataType="Requested unknown data type:"
	`endif
}
