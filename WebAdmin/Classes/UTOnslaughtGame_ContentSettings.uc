/**
 * Settings class for the warfare gametype.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class UTOnslaughtGame_ContentSettings extends UTOnslaughtGameSettings;

`include(WebAdmin.uci)

`if(`WITH_FULL_UT3)
defaultproperties
{
	UTGameClass=class'UTOnslaughtGame_Content'
	UTTeamGameClass=class'UTOnslaughtGame_Content'
	UTOnslaughtGameClass=class'UTOnslaughtGame_Content'
}
`endif
