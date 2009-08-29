/**
 * The query handler that provides information about the current game. It will
 * also set the start page for the webadmin.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class NewsDesk extends Object config(WebAdmin) dependson(WebAdminUtils);

`include(WebAdmin.uci)

var config array<string> gameNews;
var config array<string> contentNews;
var config string lastUpdate;

var OnlineNewsInterface newsIface;

function cleanup()
{
	`if(`WITH_GENERIC_NEWS_INTERFACE)
	newsIface.ClearReadNewsCompletedDelegate(OnReadNewsCompleted);
	`else
	newsIface.ClearReadGameNewsCompletedDelegate(OnReadGameNewsCompleted);
	newsIface.ClearReadContentAnnouncementsCompletedDelegate(OnReadContentAnnouncementsCompleted);
	`endif
	newsIface = none;
}

/**
 * Get the news when needed. Updated once a day
 */
function getNews(optional bool forceUpdate)
{
	local DateTime last, now;

	if (len(lastUpdate) > 0 && !forceUpdate)
	{
		class'WebAdminUtils'.static.getDateTime(now);
		class'WebAdminUtils'.static.getDateTime(last, lastUpdate);
		// YY,YYM,MDD
		// 20,081,231
		if (last.year*10000+last.month*100+last.day >= now.year*10000+now.month*100+now.day)
		{
			return;
		}
	}
	`log("Updating news...",,'WebAdmin');
	if (class'GameEngine'.static.GetOnlineSubsystem() != none)
	{
		newsIface = class'GameEngine'.static.GetOnlineSubsystem().NewsInterface;
		`if(`WITH_GENERIC_NEWS_INTERFACE)
		newsIface.AddReadNewsCompletedDelegate(OnReadNewsCompleted);
		newsIface.ReadNews(0, ONT_GameNews);
		newsIface.ReadNews(0, ONT_ContentAnnouncements);
		`else
		newsIface.AddReadGameNewsCompletedDelegate(OnReadGameNewsCompleted);
		if (!newsIface.ReadGameNews(0))
		{
			OnReadGameNewsCompleted(false);
		}
		newsIface.AddReadContentAnnouncementsCompletedDelegate(OnReadContentAnnouncementsCompleted);
		if (!newsIface.ReadContentAnnouncements(0))
		{
			OnReadContentAnnouncementsCompleted(false);
		}
		`endif
	}
}

`if(`WITH_GENERIC_NEWS_INTERFACE)
function OnReadNewsCompleted(bool bWasSuccessful,EOnlineNewsType NewsType)
{
	if (NewsType == ONT_GameNews)
	{
		OnReadGameNewsCompleted(bWasSuccessful);
	}
	else if (NewsType == ONT_ContentAnnouncements)
	{
		OnReadContentAnnouncementsCompleted(bWasSuccessful);
	}
}
`endif

/**
 * Callback when the news was received
 */
function OnReadGameNewsCompleted(bool bWasSuccessful)
{
	local array<string> data;
	local string ln;
	local int i,j;
	if (bWasSuccessful)
	{
		`if(`WITH_GENERIC_NEWS_INTERFACE)
		ParseStringIntoArray(newsIface.GetNews(0, ONT_GameNews), data, chr(10), false);
		`else
		ParseStringIntoArray(newsIface.GetGameNews(0), data, chr(10), false);
		`endif
		gameNews.length = data.length;
		j = 0;
		for (i = 0; i < data.length; i++)
		{
			ln = `Trim(data[i]);
			if (len(ln) > 0 || j > 0)
			{
				gameNews[j] = ln;
				++j;
			}
		}
		gameNews.length = j;
		lastUpdate = TimeStamp();
		SaveConfig();
	}
	`if(`WITH_GENERIC_NEWS_INTERFACE)
	`else
	newsIface.ClearReadGameNewsCompletedDelegate(OnReadGameNewsCompleted);
	`endif
}

/**
 * Callback when content announcement were made
 */
function OnReadContentAnnouncementsCompleted(bool bWasSuccessful)
{
	local array<string> data;
	local string ln;
	local int i,j;
	if (bWasSuccessful)
	{
		`if(`WITH_GENERIC_NEWS_INTERFACE)
		ParseStringIntoArray(newsIface.GetNews(0, ONT_ContentAnnouncements), data, chr(10), false);
		`else
		ParseStringIntoArray(newsIface.GetContentAnnouncements(0), data, chr(10), false);
		`endif
		contentNews.length = data.length;
		j = 0;
		for (i = 0; i < data.length; i++)
		{
			ln = `Trim(data[i]);
			if (len(ln) > 0 || j > 0)
			{
				contentNews[j] = ln;
				++j;
			}
		}
		contentNews.length = j;
		lastUpdate = TimeStamp();
		SaveConfig();
	}
	`if(`WITH_GENERIC_NEWS_INTERFACE)
	`else
	newsIface.ClearReadContentAnnouncementsCompletedDelegate(OnReadContentAnnouncementsCompleted);
	`endif
}

function string renderNews(WebAdmin webadmin, WebAdminQuery q)
{
	local int i;
	local string tmp;
	if (gameNews.length > 0 || contentNews.length > 0)
	{
		for (i = 0; i < gameNews.length; i++)
		{
			if (i > 0) tmp $= "<br />";
			tmp $= `HTMLEscape(gameNews[i]);
		}
		q.response.subst("news.game", tmp);
		tmp = "";
		for (i = 0; i < contentNews.length; i++)
		{
			if (i > 0) tmp $= "<br />";
			tmp $= `HTMLEscape(contentNews[i]);
		}
		q.response.subst("news.content", tmp);
		q.response.subst("news.timestamp", `HTMLEscape(lastUpdate));
	}
	return webadmin.include(q, "news.inc");
}
