/**
 * Settings class for the duel gametype.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class UTDuelGameSettings extends UTTeamGameSettings;

var class<UTDuelGame> UTDuelGameClass;

function init()
{
	super.init();
	SetIntPropertyByName('NumRounds', UTDuelGameClass.default.NumRounds);
}

protected function saveInternal()
{
	GetIntPropertyByName('NumRounds', UTDuelGameClass.default.NumRounds);
	super.saveInternal();
}

defaultproperties
{
	UTGameClass=class'UTDuelGame'
	UTTeamGameClass=class'UTDuelGame'
	UTDuelGameClass=class'UTDuelGame'

	Properties[13]=(PropertyId=13,Data=(Type=SDT_Int32))
	PropertyMappings[13]=(Id=13,Name="NumRounds",ColumnHeaderText="Rounds",MappingType=PVMT_Ranged,MinVal=1,MaxVal=999,RangeIncrement=1)
}
