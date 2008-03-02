/**
 * Used to store additional maplists
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class AdditionalMapLists extends Object config(Game) dependson(UTGame);

struct ExtraMapCycle
{
	var string id;
	var string FriendlyName;
	var GameMapCycle cycle;
};

var config bool bInitialized;
var config array<ExtraMapCycle> mapCycles;
