/**
 * Settings class for the deathmatch gametype.
 *
 * Copyright 2009 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class UTBetrayalGameSettings extends UTDeathmatchSettings;

`if(`GAME_UT3)
defaultProperties
{
	UTGameClass=class'UTBetrayalGame'
}
`endif
