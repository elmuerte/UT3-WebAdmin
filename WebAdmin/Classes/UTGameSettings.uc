/**
 * Generic settings for all builtin gamaetype
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class UTGameSettings extends WebAdminSettings abstract;

var const class<UTGame> UTGameClass;

var databinding int GoalScore;

function init()
{
	if (UTGameClass == none) return;
 	SetIntPropertyByName('GoalScore', UTGameClass.default.GoalScore);
 	SetIntPropertyByName('TimeLimit', UTGameClass.default.TimeLimit);
 	SetIntPropertyByName('LateEntryLives', UTGameClass.default.LateEntryLives);
 	SetIntPropertyByName('MaxLives', UTGameClass.default.MaxLives);
 	SetIntPropertyByName('bWarmupRound', int(UTGameClass.default.bWarmupRound));
 	SetIntPropertyByName('WarmupTime', UTGameClass.default.WarmupTime);
 	SetIntPropertyByName('bForceMidGameMenuAtStart', int(UTGameClass.default.bForceMidGameMenuAtStart));
 	SetIntPropertyByName('VoteDuration', UTGameClass.default.VoteDuration);
 	SetIntPropertyByName('MaxCustomChars', UTGameClass.default.MaxCustomChars);
 	SetIntPropertyByName('ResetTimeDelay', UTGameClass.default.ResetTimeDelay);
 	SetIntPropertyByName('NetWait', UTGameClass.default.NetWait);
 	SetIntPropertyByName('ClientProcessingTimeout', UTGameClass.default.ClientProcessingTimeout);
}

protected function saveInternal()
{
	local int retval;
	if (UTGameClass == none) return;
	GetIntPropertyByName('GoalScore', UTGameClass.default.GoalScore);
 	GetIntPropertyByName('TimeLimit', UTGameClass.default.TimeLimit);
 	GetIntPropertyByName('LateEntryLives', UTGameClass.default.LateEntryLives);
 	GetIntPropertyByName('MaxLives', UTGameClass.default.MaxLives);
 	if (GetIntPropertyByName('bWarmupRound', retval))
 	{
 		UTGameClass.default.bWarmupRound = (retval != 0);
 	}
 	GetIntPropertyByName('WarmupTime', UTGameClass.default.WarmupTime);
 	if (GetIntPropertyByName('bForceMidGameMenuAtStart', retval))
 	{
 		UTGameClass.default.bForceMidGameMenuAtStart = (retval != 0);
 	}
 	GetIntPropertyByName('VoteDuration', UTGameClass.default.VoteDuration);
 	GetIntPropertyByName('MaxCustomChars', UTGameClass.default.MaxCustomChars);
 	GetIntPropertyByName('ResetTimeDelay', UTGameClass.default.ResetTimeDelay);
 	GetIntPropertyByName('NetWait', UTGameClass.default.NetWait);
 	GetIntPropertyByName('ClientProcessingTimeout', UTGameClass.default.ClientProcessingTimeout);
}

defaultproperties
{
	Properties[0]=(PropertyId=0,Data=(Type=SDT_Int32))
	Properties[1]=(PropertyId=1,Data=(Type=SDT_Int32))
	Properties[2]=(PropertyId=2,Data=(Type=SDT_Int32))
	Properties[3]=(PropertyId=3,Data=(Type=SDT_Int32))
	Properties[4]=(PropertyId=4,Data=(Type=SDT_Int32))
	Properties[5]=(PropertyId=5,Data=(Type=SDT_Int32))
	Properties[6]=(PropertyId=6,Data=(Type=SDT_Int32))
	Properties[7]=(PropertyId=7,Data=(Type=SDT_Int32))
	Properties[8]=(PropertyId=8,Data=(Type=SDT_Int32))
	Properties[9]=(PropertyId=9,Data=(Type=SDT_Int32))
	Properties[10]=(PropertyId=10,Data=(Type=SDT_Int32))
	Properties[11]=(PropertyId=11,Data=(Type=SDT_Int32))

	PropertyMappings[0]=(Id=0,Name="GoalScore",ColumnHeaderText="Score Limit",MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=1)
	PropertyMappings[1]=(Id=1,Name="TimeLimit",ColumnHeaderText="Time Limit",MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=5)
	PropertyMappings[2]=(Id=2,Name="MaxLives",ColumnHeaderText="Maximum Lives",MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=1)
	PropertyMappings[3]=(Id=3,Name="LateEntryLives",ColumnHeaderText="Late Entry Lives",MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=1)
	PropertyMappings[4]=(Id=4,Name="bWarmupRound",ColumnHeaderText="Warmup round",MappingType=PVMT_IdMapped,ValueMappings=((Id=0,Name="No"),(Id=1,Name="Yes")))
	PropertyMappings[5]=(Id=5,Name="WarmupTime",ColumnHeaderText="Warmup time",MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=30)

	PropertyMappings[6]=(Id=6,Name="bForceMidGameMenuAtStart",ColumnHeaderText="Force MidGameMenu at Start",MappingType=PVMT_IdMapped,ValueMappings=((Id=0,Name="No"),(Id=1,Name="Yes")))
	PropertyMappings[7]=(Id=7,Name="VoteDuration",ColumnHeaderText="Vote Duration",MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=5)
	PropertyMappings[8]=(Id=8,Name="ResetTimeDelay",ColumnHeaderText="New Round Delay",MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=5)
	PropertyMappings[9]=(Id=9,Name="MaxCustomChars",ColumnHeaderText="Maximum Custom Characters",MappingType=PVMT_Ranged,MinVal=0,MaxVal=64,RangeIncrement=1)
	PropertyMappings[10]=(Id=10,Name="NetWait",ColumnHeaderText="Delay When Waiting for Players",MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=10)
	PropertyMappings[11]=(Id=11,Name="ClientProcessingTimeout",ColumnHeaderText="Client Processing Timeout",MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=10)
}
