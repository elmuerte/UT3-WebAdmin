/**
 * Settings class for the deathmatch gametype.
 *
 * Copyright 2009 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class UTGreedGameSettings extends UTTeamGameSettings;

`if(`GAME_UT3)
defaultProperties
{
	UTGameClass=class'UTGreedGame'
	UTTeamGameClass=class'UTGreedGame'
}
`endif
