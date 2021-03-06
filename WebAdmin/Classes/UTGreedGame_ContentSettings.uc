/**
 * Settings class for the deathmatch gametype.
 *
 * Copyright 2009 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class UTGreedGame_ContentSettings extends UTGreedGameSettings;

`include(WebAdmin.uci)
`if(`GAME_UT3)
defaultProperties
{
	UTGameClass=class'UTGreedGame_Content'
	UTTeamGameClass=class'UTGreedGame_Content'
}
`endif
