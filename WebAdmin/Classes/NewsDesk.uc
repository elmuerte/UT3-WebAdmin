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

var config string gameNews;
var config string contentNews;
var config string lastUpdate;

var OnlineNewsInterface newsIface;

function cleanup()
{
	newsIface.ClearReadGameNewsCompletedDelegate(OnReadGameNewsCompleted);
	newsIface.ClearReadContentAnnouncementsCompletedDelegate(OnReadContentAnnouncementsCompleted);
	newsIface = none;
}

/**
 * Get the news when needed. Updated once a day
 */
function getNews(optional bool forceUpdate)
{
	local DateTime last, now;

	if (len(lastUpdate) == 0 && !forceUpdate)
	{
		class'WebAdminUtils'.static.getDateTime(now);
		class'WebAdminUtils'.static.getDateTime(last, lastUpdate);
		// YY.YYM.MDD
		// 20.081.231
		if (last.year*10000+last.month*100+last.day >= now.year*10000+now.month*100+now.day)
		{
			return;
		}
	}
	`log("Updating news...",,'WebAdmin');
	if (class'GameEngine'.static.GetOnlineSubsystem() != none)
	{
		newsIface = class'GameEngine'.static.GetOnlineSubsystem().NewsInterface;
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
	}
}

/**
 * Callback when the news was received
 */
function OnReadGameNewsCompleted(bool bWasSuccessful)
{
	if (bWasSuccessful)
	{
		gameNews = repl(repl(newsIface.GetGameNews(0), chr(10), " "), chr(13), "");
		lastUpdate = TimeStamp();
		SaveConfig();
	}
	newsIface.ClearReadGameNewsCompletedDelegate(OnReadGameNewsCompleted);
}

/**
 * Callback when content announcement were made
 */
function OnReadContentAnnouncementsCompleted(bool bWasSuccessful)
{
	if (bWasSuccessful)
	{
		contentNews = repl(repl(newsIface.GetContentAnnouncements(0), chr(10), " "), chr(13), "");
		lastUpdate = TimeStamp();
		SaveConfig();
	}
	newsIface.ClearReadContentAnnouncementsCompletedDelegate(OnReadContentAnnouncementsCompleted);
}

function string renderNews(WebAdmin webadmin, WebAdminQuery q)
{
	if (len(gameNews) > 0 || len(contentNews) > 0)
	{
		q.response.subst("news.game", `HTMLEscape(gameNews));
		q.response.subst("news.content", `HTMLEscape(contentNews));
		q.response.subst("news.timestamp", `HTMLEscape(lastUpdate));
	}
	return webadmin.include(q, "news.inc");
}
