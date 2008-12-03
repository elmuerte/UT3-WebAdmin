/**
 * Generic settings for all builtin gamaetype
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class UTGameSettings extends WebAdminSettings abstract;

`include(WebAdmin.uci)

var class<UTGame> UTGameClass;

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
 	`if(`notdefined(UT3_PATCH_1_4))
 	SetIntPropertyByName('VoteDuration', UTGameClass.default.VoteDuration);
 	`endif
 	SetIntPropertyByName('MaxCustomChars', UTGameClass.default.MaxCustomChars);
 	SetIntPropertyByName('ResetTimeDelay', UTGameClass.default.ResetTimeDelay);
 	SetIntPropertyByName('NetWait', UTGameClass.default.NetWait);
 	SetIntPropertyByName('ClientProcessingTimeout', UTGameClass.default.ClientProcessingTimeout);
 	`if(`UT3_PATCH_1_4)
 	SetFloatPropertyByName('SpawnProtectionTime', UTGameClass.default.SpawnProtectionTime);
 	`endif
}

function save()
{
	saveInternal();
	UTGameClass.static.StaticSaveConfig();
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
 	`if(`notdefined(UT3_PATCH_1_4))
 	GetIntPropertyByName('VoteDuration', UTGameClass.default.VoteDuration);
 	`endif
 	GetIntPropertyByName('MaxCustomChars', UTGameClass.default.MaxCustomChars);
 	GetIntPropertyByName('ResetTimeDelay', UTGameClass.default.ResetTimeDelay);
 	GetIntPropertyByName('NetWait', UTGameClass.default.NetWait);
 	GetIntPropertyByName('ClientProcessingTimeout', UTGameClass.default.ClientProcessingTimeout);

 	`if(`UT3_PATCH_1_4)
 	GetFloatPropertyByName('SpawnProtectionTime', UTGameClass.default.SpawnProtectionTime);
 	`endif
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
	Properties[12]=(PropertyId=12,Data=(Type=SDT_Float))

	PropertyMappings[0]=(Id=0,Name="GoalScore" `modloc(,ColumnHeaderText="Score Limit") ,MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=1)
	PropertyMappings[1]=(Id=1,Name="TimeLimit" `modloc(,ColumnHeaderText="Time Limit") ,MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=5)
	PropertyMappings[2]=(Id=2,Name="MaxLives" `modloc(,ColumnHeaderText="Maximum Lives") ,MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=1)
	PropertyMappings[3]=(Id=3,Name="LateEntryLives" `modloc(,ColumnHeaderText="Late Entry Lives") ,MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=1)
	PropertyMappings[4]=(Id=4,Name="bWarmupRound" `modloc(,ColumnHeaderText="Warmup round") ,MappingType=PVMT_IdMapped,ValueMappings=((Id=0 `modloc(,name="No") ),(Id=1 `modloc(,name="Yes") )))
	PropertyMappings[5]=(Id=5,Name="WarmupTime" `modloc(,ColumnHeaderText="Warmup time") ,MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=30)

	PropertyMappings[6]=(Id=6,name="bForceMidGameMenuAtStart" `modloc(,ColumnHeaderText="Force MidGameMenu at Start") ,MappingType=PVMT_IdMapped,ValueMappings=((Id=0 `modloc(,name="No") ),(Id=1 `modloc(,name="Yes") )))
	`if(`notdefined(UT3_PATCH_1_4))
	PropertyMappings[7]=(Id=7,Name="VoteDuration" `modloc(,ColumnHeaderText="Vote Duration") ,MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=5)
	`endif
	PropertyMappings[8]=(Id=8,Name="ResetTimeDelay" `modloc(,ColumnHeaderText="New Round Delay") ,MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=5)
	PropertyMappings[9]=(Id=9,Name="MaxCustomChars" `modloc(,ColumnHeaderText="Maximum Custom Characters") ,MappingType=PVMT_Ranged,MinVal=0,MaxVal=64,RangeIncrement=1)
	PropertyMappings[10]=(Id=10,Name="NetWait" `modloc(,ColumnHeaderText="Delay When Waiting for Players") ,MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=10)
	PropertyMappings[11]=(Id=11,Name="ClientProcessingTimeout" `modloc(,ColumnHeaderText="Client Processing Timeout") ,MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=10)

	`if(`UT3_PATCH_1_4)
	PropertyMappings[12]=(Id=12,name="SpawnProtectionTime" `modloc(,ColumnHeaderText="Spawn Protection Time") ,MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=1)
	`endif
}
