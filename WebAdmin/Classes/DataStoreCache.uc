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

struct MutatorGroup
{
	var string GroupName;
	var array<UTUIDataProvider_Mutator> mutators;
};
/**
 * List of mutators grouped by group
 */
var array<MutatorGroup> mutatorGroups;

/**
 * Simple list of all mutators
 */
var array<UTUIDataProvider_Mutator> mutators;

struct GameTypeMutators
{
	var string gametype;
	var array<MutatorGroup> mutatorGroups;
};
/**
 * Cache of the mutators available for a specific gametype
 */
var array<GameTypeMutators> gameTypeMutatorCache;

function cleanup()
{
	gametypes.remove(0, gametypes.length);
	maps.remove(0, maps.length);
	gameTypeMapCache.remove(0, gameTypeMapCache.length);
	mutatorGroups.remove(0, mutatorGroups.length);
	gameTypeMutatorCache.remove(0, gameTypeMutatorCache.length);
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
	return INDEX_NONE;
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
		if (idx == INDEX_NONE)
		{
			`Log("gametype not found "$gametype);
			return result;
		}
		j = gameTypeMapCache.find('gametype', gametypes[idx].GameMode);
		if (j == INDEX_NONE)
		{
			ParseStringIntoArray(Caps(gametypes[idx].Prefixes), prefixes, "|", true);
			for (i = 0; i < maps.length; i++)
			{
				prefix = maps[i].MapName;
				prefix = Caps(Left(prefix, InStr(prefix, "-")));
				if (prefixes.find(prefix) > INDEX_NONE)
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

function array<MutatorGroup> getMutators(optional string gametype = "", optional string sorton = "FriendlyName")
{
	local array<MutatorGroup> result, workset;
	local int j, idx;

	if (mutatorGroups.Length == 0)
	{
		loadMutators();
	}

	if (gametype == "")
	{
		workset = mutatorGroups;
	}
	else {
		idx = resolveGameType(gametype);
		if (idx == INDEX_NONE)
		{
			`Log("gametype not found "$gametype);
			result.length = 0;
			return result;
		}
		j = gameTypeMutatorCache.find('gametype', gametypes[idx].GameMode);
		if (j == INDEX_NONE)
		{
			workset = filterMutators(mutatorGroups, gametypes[idx].GameMode);
			gameTypeMutatorCache.add(1);
			gameTypeMutatorCache[gameTypeMutatorCache.length-1].gametype = gametypes[idx].GameMode;
			gameTypeMutatorCache[gameTypeMutatorCache.length-1].mutatorGroups = workset;
		}
		else {
			workset = gameTypeMutatorCache[j].mutatorGroups;
		}
	}

	if (sorton ~= "FriendlyName")
	{
		return workset;
	}

	return workset;
	// TODO: implement sorting
	/*
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
	*/
}

/**
 * Filter the source mutator group list on the provided gametype
 */
static function array<MutatorGroup> filterMutators(array<MutatorGroup> source, string gametype)
{
	local int i, j, k;
	local array<MutatorGroup> result;
	local MutatorGroup group;
	local class<UTGame> GameModeClass;

	// Why is this needed?
	gametype = Repl(gametype, "UTGameContent.", "UTGame.");
	gametype = Repl(gametype, "_Content", "");

	for (i = 0; i < source.length; i++)
	{
		group.GroupName = source[i].groupname;
		group.mutators.length = 0;
		for (j = 0; j < source[i].mutators.length; j++)
		{
			if (source[i].mutators[j].SupportedGameTypes.length > 0)
			{
				k = source[i].mutators[j].SupportedGameTypes.Find(gametype);
				if (k != INDEX_NONE)
				{
					group.mutators.AddItem(source[i].mutators[j]);
				}
			}
			else {
				if (GameModeClass == none)
				{
					GameModeClass = class<UTGame>(DynamicLoadObject(gametype, class'class'));
				}
				if(GameModeClass != none)
				{
					group.mutators.AddItem(source[i].mutators[j]);
				}
				else
				{
					`Log("DataStoreCache::filterMutators() - Unable to find game class: "$gametype);
 				}
			}
		}
		if (group.mutators.length > 0)
		{
			result.AddItem(group);
		}
	}
	return result;
}

function loadMutators()
{
	local array<UTUIResourceDataProvider> ProviderList;
	local UTUIDataProvider_Mutator item;
	local int i, j, groupid, emptyGroupId;
	local array<string> groups;
	local string group;

	if (mutatorGroups.Length > 0)
	{
		return;
	}
	mutators.Remove(0, mutators.length);
	gameTypeMutatorCache.Remove(0, gameTypeMutatorCache.length);

	emptyGroupId = -1;

	class'UTUIDataStore_MenuItems'.static.GetAllResourceDataProviders(class'UTUIDataProvider_Mutator', ProviderList);
	for (i = 0; i < ProviderList.length; i++)
	{
		item = UTUIDataProvider_Mutator(ProviderList[i]);

		ParseStringIntoArray(item.GroupNames, groups, "|", true);
		if (groups.length == 0)
		{
			groups.AddItem("");
		}
		foreach groups(group)
		{
			groupid = mutatorGroups.find('GroupName', group);
			if (groupid == INDEX_NONE)
			{
				for (groupid = 0; groupid < mutatorGroups.length; groupid++)
				{
					if (mutatorGroups[groupid].GroupName > group)
					{
						break;
					}
				}
				mutatorGroups.Insert(groupid, 1);
				mutatorGroups[groupid].GroupName = Caps(group);
			}
			if (emptyGroupId == -1 && len(group) == 0)
			{
				emptyGroupId = groupid;
			}
			for (j = 0; j < mutatorGroups[groupid].mutators.length; j++)
			{
				if (compareMutator(mutatorGroups[groupid].mutators[j], item, "FriendlyName"))
				{
					mutatorGroups[groupid].mutators.Insert(j, 1);
					mutatorGroups[groupid].mutators[j] =  item;
					break;
				}
			}
			if (j == mutatorGroups[groupid].mutators.length)
			{
				mutatorGroups[groupid].mutators.AddItem(item);
			}
		}

		for (j = 0; j < mutators.length; j++)
		{
			if (compareMutator(mutators[j], item, "FriendlyName"))
			{
				mutators.Insert(j, 1);
				mutators[j] =  item;
				break;
			}
		}
		if (j == mutators.length)
		{
			mutators.AddItem(item);
		}
	}

	if (emptyGroupId == -1)
	{
		emptyGroupId = mutatorGroups.length;
		mutatorGroups[emptyGroupId].GroupName = "";
	}

	// remove groups with single entries
	for (i = mutatorGroups.length-1; i >= 0 ; i--)
	{
		if (i == emptyGroupId) continue;
		if (mutatorGroups[i].mutators.length > 1) continue;
		item = mutatorGroups[i].mutators[0];
		for (j = 0; j < mutatorGroups[emptyGroupId].mutators.length; j++)
		{
			if (mutatorGroups[emptyGroupId].mutators[j] == item)
			{
				break;
			}
			if (compareMutator(mutatorGroups[emptyGroupId].mutators[j], item, "FriendlyName"))
			{
				mutatorGroups[emptyGroupId].mutators.Insert(j, 1);
				mutatorGroups[emptyGroupId].mutators[j] =  item;
				break;
			}
		}
		if (j == mutatorGroups[emptyGroupId].mutators.length)
		{
			mutatorGroups[emptyGroupId].mutators.AddItem(item);
		}
		mutatorGroups.Remove(i, 1);
	}
	if (mutatorGroups[emptyGroupId].mutators.Length == 0)
	{
		mutatorGroups.Remove(emptyGroupId, 1);
	}
}

static function bool compareMutator(UTUIDataProvider_Mutator m1, UTUIDataProvider_Mutator m2, string sorton)
{
	if (sorton ~= "ClassName")
	{
		return m1.ClassName > m2.ClassName;
	}
	else if (sorton ~= "FriendlyName")
	{
		return m1.FriendlyName > m2.FriendlyName;
	}
	else if (sorton ~= "Description")
	{
		return m1.Description > m2.Description;
	}
	else if (sorton ~= "GroupNames")
	{
		return m1.GroupNames > m2.GroupNames;
	}
}