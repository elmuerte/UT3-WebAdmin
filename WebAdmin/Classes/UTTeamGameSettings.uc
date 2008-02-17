/**
 * Settings class for the team deathmatch gametype.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class UTTeamGameSettings extends UTGameSettings;

var const class<UTTeamGame> UTTeamGameClass;

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
	super.saveInternal();
	if (GetIntPropertyByName('bAllowNonTeamChat', retval))
 	{
 		UTTeamGameClass.default.bAllowNonTeamChat = (retval != 0);
 	}
}

defaultproperties
{
	UTGameClass=class'UTTeamGame'
	UTTeamGameClass=class'UTTeamGame'

	Properties[12]=(PropertyId=12,Data=(Type=SDT_Int32))
	PropertyMappings[12]=(Id=12,Name="bAllowNonTeamChat",ColumnHeaderText="Allow Non Team Chat",MappingType=PVMT_IdMapped,ValueMappings=((Id=0,Name="No"),(Id=1,Name="Yes")))
}
