/**
 * Server wide settings
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class GeneralSettings extends WebAdminSettings;

function init()
{
	// Server Information
	SetStringPropertyByName('ServerName', class'GameReplicationInfo'.default.ServerName);
	SetStringPropertyByName('ShortName', class'GameReplicationInfo'.default.ShortName);
	SetStringPropertyByName('AdminName', class'GameReplicationInfo'.default.AdminName);
	SetStringPropertyByName('AdminEmail', class'GameReplicationInfo'.default.AdminEmail);
	SetIntPropertyByName('ServerRegion', class'GameReplicationInfo'.default.ServerRegion);
	SetStringPropertyByName('MessageOfTheDay', class'GameReplicationInfo'.default.MessageOfTheDay);
	SetIntPropertyByName('ServerSkillLevel', class'UTGame'.default.ServerSkillLevel);

	// Connection settings
	SetIntPropertyByName('MaxSpectators', class'GameInfo'.default.MaxSpectators);
	SetIntPropertyByName('MaxPlayers', class'GameInfo'.default.MaxPlayers);
	SetIntPropertyByName('bKickLiveIdlers', int(class'GameInfo'.default.bKickLiveIdlers));
	SetIntPropertyByName('bKickMissingCDHashKeys', int(class'GameInfo'.default.bKickMissingCDHashKeys));
	SetFloatPropertyByName('TimeToWaitForHashKey', class'GameInfo'.default.TimeToWaitForHashKey);

	// Cheat detection settings
	SetFloatPropertyByName('MaxTimeMargin', class'GameInfo'.default.MaxTimeMargin);
	SetFloatPropertyByName('TimeMarginSlack', class'GameInfo'.default.TimeMarginSlack);
	SetFloatPropertyByName('MinTimeMargin', class'GameInfo'.default.MinTimeMargin);

	// Game settings
	SetFloatPropertyByName('GameDifficulty', class'GameInfo'.default.GameDifficulty);
	SetIntPropertyByName('GoreLevel', class'GameInfo'.default.GoreLevel);
	SetIntPropertyByName('bChangeLevels', int(class'GameInfo'.default.bChangeLevels));
	SetFloatPropertyByName('EndTimeDelay', class'UTGame'.default.EndTimeDelay);
	SetIntPropertyByName('RestartWait', class'UTGame'.default.RestartWait);

	// Administration settings
	SetIntPropertyByName('bAdminCanPause', int(class'GameInfo'.default.bAdminCanPause));
	//SetStringPropertyByName('AdminPassword', class'AccessControl'.default.AdminPassword);
	//SetStringPropertyByName('GamePassword', class'AccessControl'.default.GamePassword);

	// Player/bot settings
	SetIntPropertyByName('bPlayersMustBeReady', int(class'UTGame'.default.bPlayersMustBeReady));
	SetIntPropertyByName('bForceRespawn', int(class'UTGame'.default.bForceRespawn));
	SetIntPropertyByName('bWaitForNetPlayers', int(class'UTGame'.default.bWaitForNetPlayers));
	SetIntPropertyByName('bPlayersBalanceTeams', int(class'UTTeamGame'.default.bPlayersBalanceTeams));
	SetFloatPropertyByName('BotRatio', class'UTGame'.default.BotRatio);
	SetIntPropertyByName('MinNetPlayers', class'UTGame'.default.MinNetPlayers);
	SetIntPropertyByName('bForceDefaultCharacter', int(class'UTGameReplicationInfo'.default.bForceDefaultCharacter));
}

function save()
{
	// ...
}

defaultproperties
{
	// Server Information
	Properties.Add((PropertyId=0,Data=(Type=SDT_String)))
	Properties.Add((PropertyId=1,Data=(Type=SDT_String)))
	Properties.Add((PropertyId=2,Data=(Type=SDT_String)))
	Properties.Add((PropertyId=3,Data=(Type=SDT_String)))
	Properties.Add((PropertyId=4,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=5,Data=(Type=SDT_String)))
	Properties.Add((PropertyId=6,Data=(Type=SDT_Int32)))

 	PropertyMappings.Add((Id=0,Name="ServerName",ColumnHeaderText="Server Name",MappingType=PVMT_RawValue,MinVal=0,MaxVal=256))
 	PropertyMappings.Add((Id=1,Name="ShortName",ColumnHeaderText="Short Server Name",MappingType=PVMT_RawValue,MinVal=0,MaxVal=64))
 	PropertyMappings.Add((Id=2,Name="AdminName",ColumnHeaderText="Admin Name",MappingType=PVMT_RawValue,MinVal=0,MaxVal=256))
 	PropertyMappings.Add((Id=3,Name="AdminEmail",ColumnHeaderText="Admin Email",MappingType=PVMT_RawValue,MinVal=0,MaxVal=256))
 	PropertyMappings.Add((Id=4,Name="ServerRegion",ColumnHeaderText="Server Region",MappingType=PVMT_IdMapped,ValueMappings=((Id=0,name="None Specified"),(Id=1,name="Southeast US"),(Id=2,name="Western US"),(Id=3,name="Midwest US"),(Id=4,name="Northwest US, West Canada"),(Id=5,name="Northeast US, East Canada"),(Id=6,name="United Kingdom"),(Id=7,name="Continental Europe"),(Id=8,name="Central Asia, Middle East"),(Id=9,name="Southeast Asia, Pacific"),(Id=10,name="Africa"),(Id=11,name="Australia / NZ / Pacific"),(Id=12,name="Central, South America"))))
 	PropertyMappings.Add((Id=5,Name="MessageOfTheDay",ColumnHeaderText="Message of the Day",MappingType=PVMT_RawValue,MinVal=0,MaxVal=1024))
 	PropertyMappings.Add((Id=6,Name="ServerSkillLevel",ColumnHeaderText="Server Skill Level Name",MappingType=PVMT_IdMapped,ValueMappings=((Id=0,name="Beginner"),(Id=1,name="Experienced"),(Id=2,name="Expert"))))
}
