/**
 * Settings class for the warfare gametype.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class UTOnslaughtGameSettings extends UTTeamGameSettings abstract;

`include(WebAdmin.uci)

`if(`WITH_FULL_UT3)

var class<UTOnslaughtGame> UTOnslaughtGameClass;

function initSettings()
{
	super.initSettings();
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

	Properties[14]=(PropertyId=14,Data=(Type=SDT_Int32))
	PropertyMappings[14]=(Id=14,Name="bSwapSidesAfterReset" `modloc(,ColumnHeaderText="Swap Sides Each Round") ,MappingType=PVMT_IdMapped,ValueMappings=((Id=0 `modloc(,name="No") ),(Id=1 `modloc(,name="Yes") )))
}
`endif
