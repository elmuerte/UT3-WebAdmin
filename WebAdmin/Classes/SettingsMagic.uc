/**
 * A bit of magic to fake settings classes for gametypes who don't have any.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class SettingsMagic extends Object config(WebAdmin);

`include(WebAdmin.uci)

struct MagicCacheEntry
{
	var class<GameInfo> cls;
	var Settings inst;
};
var array<MagicCacheEntry> magicCache;

function cleanup()
{
	local int i;
	for (i = 0; i < magicCache.length; i++)
	{
		magicCache[i].inst.SetSpecialValue(`{WA_CLEANUP_SETTINGS}, "");
		magicCache[i].inst = none;
	}
	magicCache.length = 0;
}

function Settings find(class<GameInfo> GameClass)
{
	local Settings result;
	local int idx;

	idx = magicCache.find('cls', GameClass);
	if (idx != INDEX_NONE)
	{
		return magicCache[idx].inst;
	}

	`if(`GAME_UT3)
	if (class<UTOnslaughtGame_Content>(GameClass) != none)
	{
		result = _UTOnslaughtGame_Content(class<UTOnslaughtGame_Content>(GameClass));
	}
	else if (class<UTOnslaughtGame>(GameClass) != none)
	{
		result = _UTOnslaughtGame(class<UTOnslaughtGame>(GameClass));
	}
	else
	`endif
	if (class<UTVehicleCTFGame_Content>(GameClass) != none)
	{
		result = _UTVehicleCTFGame_Content(class<UTVehicleCTFGame_Content>(GameClass));
	}
	else
	`if(`GAME_UT3)
	if (class<UTDuelGame>(GameClass) != none)
	{
		result = _UTDuelGame(class<UTDuelGame>(GameClass));
	}
	else
	`endif
	if (class<UTCTFGame_Content>(GameClass) != none)
	{
		result = _UTCTFGame_Content(class<UTCTFGame_Content>(GameClass));
	}
	else if (class<UTTeamGame>(GameClass) != none)
	{
		result = _UTTeamGame(class<UTTeamGame>(GameClass));
	}
	else if (class<UTTeamGame>(GameClass) != none)
	{
		result = _UTTeamGame(class<UTTeamGame>(GameClass));
	}
	else if (class<UTDeathmatch>(GameClass) != none)
	{
		result = _UTDeathmatch(class<UTDeathmatch>(GameClass));
	}
	else if (class<UTGame>(GameClass) != none)
	{
		result = _UTGame(class<UTGame>(GameClass));
	}
	if (result != none)
	{
		result.SetSpecialValue(`{WA_INIT_SETTINGS}, "");
		magicCache.Length = magicCache.Length+1;
		magicCache[magicCache.Length-1].cls = GameClass;
		magicCache[magicCache.Length-1].inst = result;
	}
	return result;
}

`if(`GAME_UT3)
function UTOnslaughtGame_ContentSettings _UTOnslaughtGame_Content(class<UTOnslaughtGame_Content> cls)
{
	local UTOnslaughtGame_ContentSettings r;
	r = new class'UTOnslaughtGame_ContentSettings';
	r.UTGameClass=cls;
	r.UTTeamGameClass=cls;
	r.UTOnslaughtGameClass=cls;
	return r;
}

function UTOnslaughtGameSettings _UTOnslaughtGame(class<UTOnslaughtGame> cls)
{
	local UTOnslaughtGameSettings r;
	r = new class'UTOnslaughtGameSettings';
	r.UTGameClass=cls;
	r.UTTeamGameClass=cls;
	r.UTOnslaughtGameClass=cls;
	return r;
}

function UTDuelGameSettings _UTDuelGame(class<UTDuelGame> cls)
{
	local UTDuelGameSettings r;
	r = new class'UTDuelGameSettings';
	r.UTGameClass=cls;
	r.UTTeamGameClass=cls;
	r.UTDuelGameClass=cls;
	return r;
}
`endif

function UTVehicleCTFGame_ContentSettings _UTVehicleCTFGame_Content(class<UTVehicleCTFGame_Content> cls)
{
	local UTVehicleCTFGame_ContentSettings r;
	r = new class'UTVehicleCTFGame_ContentSettings';
	r.UTGameClass=cls;
	r.UTTeamGameClass=cls;
	return r;
}

function UTCTFGame_ContentSettings _UTCTFGame_Content(class<UTCTFGame_Content> cls)
{
	local UTCTFGame_ContentSettings r;
	r = new class'UTCTFGame_ContentSettings';
	r.UTGameClass=cls;
	r.UTTeamGameClass=cls;
	return r;
}

function UTTeamGameSettings _UTTeamGame(class<UTTeamGame> cls)
{
	local UTTeamGameSettings r;
	r = new class'UTTeamGameSettings';
	r.UTGameClass=cls;
	r.UTTeamGameClass=cls;
	return r;
}

function UTDeathmatchSettings _UTDeathmatch(class<UTDeathmatch> cls)
{
	local UTDeathmatchSettings r;
	r = new class'UTDeathmatchSettings';
	r.UTGameClass=cls;
	return r;
}

function UTGameSettings _UTGame(class<UTGame> cls)
{
	local UTGameSettings r;
	r = new class'UTGameSettings';
	r.UTGameClass=cls;
	return r;
}
