/**
 * DataStore access class.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class DataStoreCache extends Object;

/**
 * List of gametypes
 */
var array<UTUIDataProvider_GameModeInfo> gametypes;

/**
 * List of all maps
 */
var array<UTUIDataProvider_MapInfo> maps;

struct GameTypeMaps
{
	var string gametype;
	var array<UTUIDataProvider_MapInfo> maps;
};
var array<GameTypeMaps> gameTypeMapCache;

function cleanup()
{
}

function array<UTUIDataProvider_GameModeInfo> getGameTypes(optional string sorton = "FriendlyName")
{
	local array<UTUIDataProvider_GameModeInfo> result;
	local int i, j;
	if (gametypes.Length == 0)
	{
		loadGameTypes();
	}
	if (sorton ~= "FriendlyName")
	{
		result = gametypes;
		return result;
	}
	for (i = 0; i < gametypes.length; i++)
	{
		for (j = 0; j < result.length; j++)
		{
			if (compareGameType(result[j], gametypes[i], sorton))
			{
				result.Insert(j, 1);
				result[j] =  gametypes[i];
				break;
			}
		}
		if (j == result.length)
		{
			result.AddItem(gametypes[i]);
		}
	}
	return result;
}

/**
 * Resolve a partial classname of a gametype (e.g. without package name) to the
 * entry in the cache list.
 */
function int resolveGameType(coerce string classname)
{
	local int idx;
	if (gametypes.Length == 0)
	{
		loadGameTypes();
	}
	classname = "."$classname;
	for (idx = 0; idx < gametypes.length; idx++)
	{
		if (Right("."$gametypes[idx].GameMode, Len(classname)) ~= classname)
		{
			return idx;
		}
	}
	return -1;
}

function loadGameTypes()
{
	local array<UTUIResourceDataProvider> ProviderList;
	local UTUIDataProvider_GameModeInfo item;
	local int i, j;

	if (gametypes.Length > 0)
	{
		return;
	}

	class'UTUIDataStore_MenuItems'.static.GetAllResourceDataProviders(class'UTUIDataProvider_GameModeInfo', ProviderList);
	for (i = 0; i < ProviderList.length; i++)
	{
		item = UTUIDataProvider_GameModeInfo(ProviderList[i]);

		for (j = 0; j < gametypes.length; j++)
		{
			if (compareGameType(gametypes[j], item, "FriendlyName"))
			{
				gametypes.Insert(j, 1);
				gametypes[j] =  item;
				break;
			}
		}
		if (j == gametypes.length)
		{
			gametypes.AddItem(item);
		}
	}
}

static function bool compareGameType(UTUIDataProvider_GameModeInfo g1, UTUIDataProvider_GameModeInfo g2, string sorton)
{
	if (sorton ~= "FriendlyName")
	{
		return g1.FriendlyName > g2.FriendlyName;
	}
	else if (sorton ~= "GameMode")
	{
		return g1.GameMode > g2.GameMode;
	}
	else if (sorton ~= "Description")
	{
		return g1.Description > g2.Description;
	}
	else if (sorton ~= "GameSettingsClass")
	{
		return g1.GameSettingsClass > g2.GameSettingsClass;
	}
	else if (sorton ~= "GameSearchClass")
	{
		return g1.GameSearchClass > g2.GameSearchClass;
	}
	else if (sorton ~= "DefaultMap")
	{
		return g1.DefaultMap > g2.DefaultMap;
	}
}

function array<UTUIDataProvider_MapInfo> getMaps(optional string gametype = "", optional string sorton = "MapName")
{
	local array<UTUIDataProvider_MapInfo> result, workset;
	local int i, j, idx;
	local array<string> prefixes;
	local string prefix;

	if (maps.Length == 0)
	{
		loadMaps();
	}

	if (gametype == "")
	{
		workset = maps;
	}
	else {
		idx = resolveGameType(gametype);
		if (idx == -1)
		{
			`Log("gametype not found "$gametype);
			return result;
		}
		j = gameTypeMapCache.find('gametype', gametypes[idx].GameMode);
		if (j == -1)
		{
			ParseStringIntoArray(Caps(gametypes[idx].Prefixes), prefixes, "|", true);
			for (i = 0; i < maps.length; i++)
			{
				prefix = maps[i].MapName;
				prefix = Caps(Left(prefix, InStr(prefix, "-")));
				if (prefixes.find(prefix) > -1)
				{
					workset.AddItem(maps[i]);
				}
			}
			gameTypeMapCache.add(1);
			gameTypeMapCache[gameTypeMapCache.length-1].gametype = gametypes[idx].GameMode;
			gameTypeMapCache[gameTypeMapCache.length-1].maps = workset;
		}
		else {
			workset = gameTypeMapCache[j].maps;
		}
	}

	if (sorton ~= "MapName")
	{
		return workset;
	}

	for (i = 0; i < workset.length; i++)
	{
		for (j = 0; j < result.length; j++)
		{
			if (compareMap(result[j], workset[i], sorton))
			{
				result.Insert(j, 1);
				result[j] =  workset[i];
				break;
			}
		}
		if (j == result.length)
		{
			result.AddItem(workset[i]);
		}
	}
	return result;
}

function loadMaps()
{
	local array<UTUIResourceDataProvider> ProviderList;
	local UTUIDataProvider_MapInfo item;
	local int i, j;

	if (maps.Length > 0)
	{
		return;
	}
	gameTypeMapCache.Remove(0, gameTypeMapCache.length);

	class'UTUIDataStore_MenuItems'.static.GetAllResourceDataProviders(class'UTUIDataProvider_MapInfo', ProviderList);
	for (i = 0; i < ProviderList.length; i++)
	{
		item = UTUIDataProvider_MapInfo(ProviderList[i]);

		for (j = 0; j < maps.length; j++)
		{
			if (compareMap(maps[j], item, "MapName"))
			{
				maps.Insert(j, 1);
				maps[j] =  item;
				break;
			}
		}
		if (j == maps.length)
		{
			maps.AddItem(item);
		}
	}
}

static function bool compareMap(UTUIDataProvider_MapInfo g1, UTUIDataProvider_MapInfo g2, string sorton)
{
	if (sorton ~= "MapName")
	{
		return g1.MapName > g2.MapName;
	}
	else if (sorton ~= "MapID")
	{
		return g1.MapID > g2.MapID;
	}
	else if (sorton ~= "FriendlyName")
	{
		return g1.FriendlyName > g2.FriendlyName;
	}
	else if (sorton ~= "Description")
	{
		return g1.Description > g2.Description;
	}
	else if (sorton ~= "NumPlayers")
	{
		return g1.NumPlayers > g2.NumPlayers;
	}
}
