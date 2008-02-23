/**
 * Settings class for the warfare gametype.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class UTOnslaughtGameSettings extends UTTeamGameSettings abstract;

var const class<UTOnslaughtGame> UTOnslaughtGameClass;

function init()
{
	super.init();
	SetIntPropertyByName('bSwapSidesAfterReset', int(UTOnslaughtGameClass.default.bSwapSidesAfterReset));
}

protected function saveInternal()
{
	local int retval;
	if (GetIntPropertyByName('bSwapSidesAfterReset', retval))
	{
		UTOnslaughtGameClass.default.bSwapSidesAfterReset = (retval != 0);
	}
	super.saveInternal();
}

defaultproperties
{
	UTGameClass=class'UTOnslaughtGame'
	UTTeamGameClass=class'UTOnslaughtGame'
	UTOnslaughtGameClass=class'UTOnslaughtGame'

	Properties[13]=(PropertyId=13,Data=(Type=SDT_Int32))
	PropertyMappings[13]=(Id=13,Name="bSwapSidesAfterReset",ColumnHeaderText="Swap Sides Each Round",MappingType=PVMT_IdMapped,ValueMappings=((Id=0,Name="No"),(Id=1,Name="Yes")))
}
