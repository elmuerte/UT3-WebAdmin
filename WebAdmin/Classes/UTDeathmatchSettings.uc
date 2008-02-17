/**
 * Settings class for the deathmatch gametype.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class UTDeathmatchSettings extends UTGameSettings;

function save()
{
	saveInternal();
	UTGameClass.static.StaticSaveConfig();
}

defaultproperties
{
	UTGameClass=class'UTDeathmatch'
	// reset delay does not apply here
	Properties.RemoveIndex(8)
	PropertyMappings.RemoveIndex(8)
}
