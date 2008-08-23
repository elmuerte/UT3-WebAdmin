/**
 * Server wide settings
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class GeneralSettings extends WebAdminSettings;

`include(WebAdmin.uci)

function string GetSpecialValue(name PropertyName)
{
	if (PropertyName == `{WA_GROUP_SETTINGS})
	{
		return "Server Information=0,10;Connection=10,20;Cheat Detection=20,30;Game=30,40;Administration=40,50;Players=50,60;Map Voting=60,70";
	}
}

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
	`if(`WITH_BANCDHASH)
	SetIntPropertyByName('bKickMissingCDHashKeys', int(class'GameInfo'.default.bKickMissingCDHashKeys));
	SetFloatPropertyByName('TimeToWaitForHashKey', class'GameInfo'.default.TimeToWaitForHashKey);
	`endif

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
	`if(`UT3_PATCH_1_3)
	SetIntPropertyByName('bNoCustomCharacters', int(class'UTGame'.default.bNoCustomCharacters));
	`endif

	// map voting
	`if(`UT3_PATCH_1_3)
	SetIntPropertyByName('bAllowMapVoting', int(class'UTGame'.default.bAllowMapVoting));
	SetIntPropertyByName('bMidGameMapVoting', int(class'UTGame'.default.bMidGameMapVoting));
	SetIntPropertyByName('VoteDuration', class'UTGame'.default.VoteDuration);
	SetIntPropertyByName('MapVotePercentage', class'UTGame'.default.MapVotePercentage);
	SetIntPropertyByName('MinMapVotes', class'UTGame'.default.MinMapVotes);
	SetIntPropertyByName('InitialVoteDelay', class'UTGame'.default.InitialVoteDelay);
	//SetIntPropertyByName('VoteCollectorClassName', int(class'UTGame'.default.VoteCollectorClassName));
	`endif
}

function save()
{
	local int val;

	// UTGRI
	if (GetIntPropertyByName('bForceDefaultCharacter', val))
	{
		class'UTGameReplicationInfo'.default.bForceDefaultCharacter = val != 0;
	}
	class'UTGameReplicationInfo'.static.StaticSaveConfig();

	// GRI
	GetStringPropertyByName('ServerName', class'GameReplicationInfo'.default.ServerName);
	GetStringPropertyByName('ShortName', class'GameReplicationInfo'.default.ShortName);
	GetStringPropertyByName('AdminName', class'GameReplicationInfo'.default.AdminName);
	GetStringPropertyByName('AdminEmail', class'GameReplicationInfo'.default.AdminEmail);
	GetIntPropertyByName('ServerRegion', class'GameReplicationInfo'.default.ServerRegion);
	GetStringPropertyByName('MessageOfTheDay', class'GameReplicationInfo'.default.MessageOfTheDay);
	class'GameReplicationInfo'.static.StaticSaveConfig();

	// UTTeamGame
	if (GetIntPropertyByName('bPlayersBalanceTeams', val))
	{
		class'UTTeamGame'.default.bPlayersBalanceTeams = val != 0;
	}
	class'UTTeamGame'.static.StaticSaveConfig();

	// UTGame
	GetIntPropertyByName('ServerSkillLevel', class'UTGame'.default.ServerSkillLevel);
	GetFloatPropertyByName('EndTimeDelay', class'UTGame'.default.EndTimeDelay);
	GetIntPropertyByName('RestartWait', class'UTGame'.default.RestartWait);
	if (GetIntPropertyByName('bPlayersMustBeReady', val))
	{
		class'UTGame'.default.bPlayersMustBeReady = val != 0;
	}
	if (GetIntPropertyByName('bForceRespawn', val))
	{
		class'UTGame'.default.bForceRespawn = val != 0;
	}
	if (GetIntPropertyByName('bWaitForNetPlayers', val))
	{
		class'UTGame'.default.bWaitForNetPlayers = val != 0;
	}
	GetFloatPropertyByName('BotRatio', class'UTGame'.default.BotRatio);
	GetIntPropertyByName('MinNetPlayers', class'UTGame'.default.MinNetPlayers);
	`if(`UT3_PATCH_1_3)
	if (GetIntPropertyByName('bNoCustomCharacters', val))
	{
		class'UTGame'.default.bNoCustomCharacters = val != 0;
	}

	if (GetIntPropertyByName('bAllowMapVoting', val))
	{
		class'UTGame'.default.bAllowMapVoting = val != 0;
	}
	if (GetIntPropertyByName('bMidGameMapVoting', val))
	{
		class'UTGame'.default.bMidGameMapVoting = val != 0;
	}
	GetIntPropertyByName('VoteDuration', class'UTGame'.default.VoteDuration);
	GetIntPropertyByName('MapVotePercentage', class'UTGame'.default.MapVotePercentage);
	GetIntPropertyByName('MinMapVotes', class'UTGame'.default.MinMapVotes);
	GetIntPropertyByName('InitialVoteDelay', class'UTGame'.default.InitialVoteDelay);
	//GetStringPropertyByName('VoteCollectorClassName', class'UTGame'.default.VoteCollectorClassName);
	`endif
	class'UTGame'.static.StaticSaveConfig();

	// GameInfo
	GetIntPropertyByName('MaxSpectators', class'GameInfo'.default.MaxSpectators);
	GetIntPropertyByName('MaxPlayers', class'GameInfo'.default.MaxPlayers);
	if (GetIntPropertyByName('bKickLiveIdlers', val))
	{
		class'GameInfo'.default.bKickLiveIdlers = val != 0;
	}
	`if(`WITH_BANCDHASH)
	if (GetIntPropertyByName('bKickMissingCDHashKeys', val))
	{
		class'GameInfo'.default.bKickMissingCDHashKeys = val != 0;
	}
	GetFloatPropertyByName('TimeToWaitForHashKey', class'GameInfo'.default.TimeToWaitForHashKey);
	`endif
	GetFloatPropertyByName('MaxTimeMargin', class'GameInfo'.default.MaxTimeMargin);
	GetFloatPropertyByName('TimeMarginSlack', class'GameInfo'.default.TimeMarginSlack);
	GetFloatPropertyByName('MinTimeMargin', class'GameInfo'.default.MinTimeMargin);
	GetFloatPropertyByName('GameDifficulty', class'GameInfo'.default.GameDifficulty);
	GetIntPropertyByName('GoreLevel', class'GameInfo'.default.GoreLevel);
	if (GetIntPropertyByName('bChangeLevels', val))
	{
		class'GameInfo'.default.bChangeLevels = val != 0;
	}
	if (GetIntPropertyByName('bAdminCanPause', val))
	{
		class'GameInfo'.default.bAdminCanPause = val != 0;
	}
	class'GameInfo'.static.StaticSaveConfig();
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

	// Connection settings
	Properties.Add((PropertyId=10,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=11,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=12,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=13,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=14,Data=(Type=SDT_Float)))

 	PropertyMappings.Add((Id=10,Name="MaxSpectators",ColumnHeaderText="Maximum Spectators",MappingType=PVMT_Ranged,MinVal=0,MaxVal=64,RangeIncrement=1))
 	PropertyMappings.Add((Id=11,Name="MaxPlayers",ColumnHeaderText="Maximum Players",MappingType=PVMT_Ranged,MinVal=0,MaxVal=64,RangeIncrement=1))
 	PropertyMappings.Add((Id=12,Name="bKickLiveIdlers",ColumnHeaderText="Kick Idlers",MappingType=PVMT_IdMapped,ValueMappings=((Id=0,Name="No"),(Id=1,Name="Yes"))))
 	PropertyMappings.Add((Id=13,Name="bKickMissingCDHashKeys",ColumnHeaderText="Kick Missing Unique Hash",MappingType=PVMT_IdMapped,ValueMappings=((Id=0,Name="No"),(Id=1,Name="Yes"))))
 	PropertyMappings.Add((Id=14,Name="TimeToWaitForHashKey",ColumnHeaderText="Time to Wait for Unique Hash",MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=10))

	// Cheat detection settings
	Properties.Add((PropertyId=20,Data=(Type=SDT_Float)))
	Properties.Add((PropertyId=21,Data=(Type=SDT_Float)))
	Properties.Add((PropertyId=22,Data=(Type=SDT_Float)))

	PropertyMappings.Add((Id=20,Name="MaxTimeMargin",ColumnHeaderText="[Speed Hack] Maximum Time Margin",MappingType=PVMT_Ranged,MinVal=-9999,MaxVal=9999,RangeIncrement=10))
	PropertyMappings.Add((Id=21,Name="TimeMarginSlack",ColumnHeaderText="[Speed Hack] Time Margin Slack",MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=10))
	PropertyMappings.Add((Id=22,name="MinTimeMargin",ColumnHeaderText="[Speed Hack] Minimum Time Margin",MappingType=PVMT_Ranged,MinVal=-9999,MaxVal=9999,RangeIncrement=10))

	// Game settings
	Properties.Add((PropertyId=30,Data=(Type=SDT_Float)))
	Properties.Add((PropertyId=31,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=32,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=33,Data=(Type=SDT_Float)))
	Properties.Add((PropertyId=34,Data=(Type=SDT_Int32)))

	PropertyMappings.Add((Id=30,name="GameDifficulty",ColumnHeaderText="Game Difficulty",MappingType=PVMT_PredefinedValues,PredefinedValues=((Value1=0,Type=SDT_Int32),(Value1=1,Type=SDT_Int32),(Value1=2,Type=SDT_Int32),(Value1=3,Type=SDT_Int32),(Value1=4,Type=SDT_Int32),(Value1=5,Type=SDT_Int32),(Value1=6,Type=SDT_Int32),(Value1=7,Type=SDT_Int32)),MinVal=0,MaxVal=999,RangeIncrement=1))
	PropertyMappings.Add((Id=31,name="GoreLevel",ColumnHeaderText="Gore Reduction",MappingType=PVMT_PredefinedValues,PredefinedValues=((Value1=0,Type=SDT_Int32),(Value1=1,Type=SDT_Int32)),MinVal=0,MaxVal=256,RangeIncrement=1))
	PropertyMappings.Add((Id=32,name="bChangeLevels",ColumnHeaderText="Change Levels",MappingType=PVMT_IdMapped,ValueMappings=((Id=0,name="No"),(Id=1,name="Yes"))))
	PropertyMappings.Add((Id=33,Name="EndTimeDelay",ColumnHeaderText="End Game Delay",MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=10))
	PropertyMappings.Add((Id=34,Name="RestartWait",ColumnHeaderText="Game Restart Delay",MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=1))

	// Administration settings
	Properties.Add((PropertyId=40,Data=(Type=SDT_Int32)))
	PropertyMappings.Add((Id=40,Name="bAdminCanPause",ColumnHeaderText="Admin can Pause",MappingType=PVMT_IdMapped,ValueMappings=((Id=0,Name="No"),(Id=1,Name="Yes"))))

	// Player/bot settings
	Properties.Add((PropertyId=50,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=51,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=52,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=53,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=54,Data=(Type=SDT_Float)))
	Properties.Add((PropertyId=55,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=56,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=57,Data=(Type=SDT_Int32)))

	PropertyMappings.Add((Id=50,name="bPlayersMustBeReady",ColumnHeaderText="Players Must be Ready",MappingType=PVMT_IdMapped,ValueMappings=((Id=0,name="No"),(Id=1,name="Yes"))))
	PropertyMappings.Add((Id=51,Name="bForceRespawn",ColumnHeaderText="Force Respawn",MappingType=PVMT_IdMapped,ValueMappings=((Id=0,Name="No"),(Id=1,Name="Yes"))))
	PropertyMappings.Add((Id=52,Name="bWaitForNetPlayers",ColumnHeaderText="Wait for Players",MappingType=PVMT_IdMapped,ValueMappings=((Id=0,Name="No"),(Id=1,Name="Yes"))))
	PropertyMappings.Add((Id=53,Name="bPlayersBalanceTeams",ColumnHeaderText="Players Balance Teams",MappingType=PVMT_IdMapped,ValueMappings=((Id=0,Name="No"),(Id=1,Name="Yes"))))
	PropertyMappings.Add((Id=54,name="BotRatio",ColumnHeaderText="Bot/Player Ratio",MappingType=PVMT_Ranged,MinVal=0,MaxVal=64,RangeIncrement=0.1))
	PropertyMappings.Add((Id=55,Name="MinNetPlayers",ColumnHeaderText="Minimal Players",MappingType=PVMT_Ranged,MinVal=0,MaxVal=64,RangeIncrement=1))
	PropertyMappings.Add((Id=56,Name="bForceDefaultCharacter",ColumnHeaderText="Force default Character",MappingType=PVMT_IdMapped,ValueMappings=((Id=0,Name="No"),(Id=1,Name="Yes"))))
	`if(`UT3_PATCH_1_3)
	PropertyMappings.Add((Id=57,name="bNoCustomCharacters",ColumnHeaderText="No Custom Characters",MappingType=PVMT_IdMapped,ValueMappings=((Id=0,name="No"),(Id=1,name="Yes"))))
	`endif

	// mapvoting
	`if(`UT3_PATCH_1_3)
	Properties.Add((PropertyId=60,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=61,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=62,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=63,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=64,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=65,Data=(Type=SDT_Int32)))

	PropertyMappings.Add((Id=60,name="bAllowMapVoting",ColumnHeaderText="Allow Map Voting",MappingType=PVMT_IdMapped,ValueMappings=((Id=0,name="No"),(Id=1,name="Yes"))))
	PropertyMappings.Add((Id=61,name="bMidGameMapVoting",ColumnHeaderText="Allow Mid-Game Voting",MappingType=PVMT_IdMapped,ValueMappings=((Id=0,name="No"),(Id=1,name="Yes"))))
	PropertyMappings.Add((Id=62,name="VoteDuration",ColumnHeaderText="Vote Duration",MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=5))
	PropertyMappings.Add((Id=63,name="MapVotePercentage",ColumnHeaderText="Vote Percentage to Change Map",MappingType=PVMT_Ranged,MinVal=0,MaxVal=100,RangeIncrement=5))
	PropertyMappings.Add((Id=64,name="MinMapVotes",ColumnHeaderText="Minimal Votes",MappingType=PVMT_Ranged,MinVal=0,MaxVal=64,RangeIncrement=1))
	PropertyMappings.Add((Id=65,name="InitialVoteDelay",ColumnHeaderText="Mid-Game Vote Delay",MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=5))
	`endif
}
