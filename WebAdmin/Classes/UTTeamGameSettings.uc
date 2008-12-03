/**
 * Settings class for the team deathmatch gametype.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class UTTeamGameSettings extends UTGameSettings;

`include(WebAdmin.uci)

var class<UTTeamGame> UTTeamGameClass;

function save()
{
	saveInternal();
	UTGameClass.static.StaticSaveConfig();
}

function init()
{
	super.init();
	SetIntPropertyByName('bAllowNonTeamChat', int(UTTeamGameClass.default.bAllowNonTeamChat));
}

protected function saveInternal()
{
	local int retval;
	if (GetIntPropertyByName('bAllowNonTeamChat', retval))
 	{
 		UTTeamGameClass.default.bAllowNonTeamChat = (retval != 0);
 	}
 	super.saveInternal();
}

defaultproperties
{
	UTGameClass=class'UTTeamGame'
	UTTeamGameClass=class'UTTeamGame'

	Properties[13]=(PropertyId=13,Data=(Type=SDT_Int32))
	PropertyMappings[13]=(Id=13,Name="bAllowNonTeamChat" `modloc(,ColumnHeaderText="Allow Non Team Chat") ,MappingType=PVMT_IdMapped,ValueMappings=((Id=0 `modloc(,name="No") ),(Id=1 `modloc(,name="Yes") )))
}
