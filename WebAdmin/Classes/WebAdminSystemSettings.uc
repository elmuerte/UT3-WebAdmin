/**
 * Configuration settings for the WebAdmin
 *
 * Copyright 2009 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class WebAdminSystemSettings extends WebAdminSettings implements(IQueryHandler);

`include(WebAdmin.uci)

var WebAdmin webadmin;
var QHCurrent qhcurrent;
var ChatLog chatlog;

var SettingsRenderer settingsRenderer;

function init(WebAdmin webapp)
{
	webadmin = webapp;
}

function delayedInit()
{
	local IQueryHandler qh;
	local Object o;
	foreach webadmin.handlers(qh)
	{
		if (qh.IsA('QHCurrent'))
		{
			o = qh;
			qhcurrent = QHCurrent(o);
		}
	}
	foreach webadmin.WorldInfo.AllActors(class'ChatLog', chatlog)
	{
		break;
	}
}

function cleanup()
{
	settingsRenderer = none;
	qhcurrent = none;
	chatlog = none;
	webadmin = none;
}

function registerMenuItems(WebAdminMenu menu)
{
	menu.addMenu("/settings/system", "System", self, "Change the web administration configuration.", 999);
}

function bool handleQuery(WebAdminQuery q)
{
	switch (q.request.URI)
	{
		case "/settings/system":
			handleSettings(q);
			return true;
	}
	return false;
}

function bool unhandledQuery(WebAdminQuery q);

function bool producesXhtml()
{
	return true;
}

function handleSettings(WebAdminQuery q)
{
	if (settingsRenderer == none)
	{
		delayedInit();
		loadSettings();
		settingsRenderer = new class'SettingsRenderer';
		settingsRenderer.init(webadmin.path);
	}

	if (q.request.getVariable("action") ~= "save")
	{
		class'QHDefaults'.static.applySettings(self, q.request);
		saveSettings();
		webadmin.addMessage(q, "Settings saved.");
	}

	settingsRenderer.render(self, q.response);
	webadmin.sendPage(q, "default_settings_general.html");
}

/**
 * Load the webadmin settings
 */
protected function loadSettings()
{
	// generic
	SetStringPropertyByName('AuthenticationClass', webadmin.AuthenticationClass);
	SetStringPropertyByName('SessionHandlerClass', webadmin.SessionHandlerClass);
	SetIntPropertyByName('bHttpAuth', int(webadmin.bHttpAuth));
	SetStringPropertyByName('startpage', webadmin.startpage);
	SetIntPropertyByName('bChatLog', int(webadmin.bChatLog));
	SetIntPropertyByName('bUseStrictContentType', int(webadmin.bUseStrictContentType));

	// qhcurrent
	if (qhcurrent != none)
	{
		SetIntPropertyByName('ChatRefresh', qhcurrent.ChatRefresh);
		SetIntPropertyByName('bConsoleEnabled', int(qhcurrent.bConsoleEnabled));
		SetStringArrayPropertyByName('denyUrlOptions', qhcurrent.denyUrlOptions, chr(10));
		SetStringArrayPropertyByName('denyConsoleCommands', qhcurrent.denyConsoleCommands, chr(10));
		SetIntPropertyByName('bAdminConsoleCommandsHack', int(qhcurrent.bAdminConsoleCommandsHack));
		SetStringPropertyByName('AdminCommandHandlerClass', qhcurrent.AdminCommandHandlerClass);
		SetIntPropertyByName('bEnableTeamChat', int(qhcurrent.bEnableTeamChat));
		SetIntPropertyByName('hideNews', int(qhcurrent.hideNews));
	}
	else {
		SetIntPropertyByName('ChatRefresh', class'QHCurrent'.default.ChatRefresh);
		SetIntPropertyByName('bConsoleEnabled', int(class'QHCurrent'.default.bConsoleEnabled));
		SetStringArrayPropertyByName('denyUrlOptions', class'QHCurrent'.default.denyUrlOptions, chr(10));
		SetStringArrayPropertyByName('denyConsoleCommands', class'QHCurrent'.default.denyConsoleCommands, chr(10));
		SetIntPropertyByName('bAdminConsoleCommandsHack', int(class'QHCurrent'.default.bAdminConsoleCommandsHack));
		SetStringPropertyByName('AdminCommandHandlerClass', class'QHCurrent'.default.AdminCommandHandlerClass);
		SetIntPropertyByName('bEnableTeamChat', int(class'QHCurrent'.default.bEnableTeamChat));
		SetIntPropertyByName('hideNews', int(class'QHCurrent'.default.hideNews));
	}

	if (chatlog != none)
	{
		SetStringPropertyByName('chatLogFilename', chatlog.filename);
		SetIntPropertyByName('chatLogUnique', int(chatlog.bUnique));
		SetIntPropertyByName('chatLogIncludeTimeStamp', int(chatlog.bIncludeTimeStamp));
	}
	else {
		SetStringPropertyByName('chatLogFilename', class'ChatLog'.default.filename);
		SetIntPropertyByName('chatLogUnique', int(class'ChatLog'.default.bUnique));
		SetIntPropertyByName('chatLogIncludeTimeStamp', int(class'ChatLog'.default.bIncludeTimeStamp));
	}
}

function saveSettings()
{
	local int intval;
	// generic
	GetStringPropertyByName('AuthenticationClass', webadmin.AuthenticationClass);
	GetStringPropertyByName('SessionHandlerClass', webadmin.SessionHandlerClass);
	if (GetIntPropertyByName('bHttpAuth', intval))
	{
		webadmin.bHttpAuth = intval != 0;
	}
	GetStringPropertyByName('startpage', webadmin.startpage);
	if (GetIntPropertyByName('bChatLog', intval))
	{
		webadmin.bChatLog = intval != 0;
	}
	if (GetIntPropertyByName('bUseStrictContentType', intval))
	{
		webadmin.bUseStrictContentType = intval != 0;
	}
	webadmin.SaveConfig();

	// qhcurrent
	if (qhcurrent != none)
	{
		GetIntPropertyByName('ChatRefresh', qhcurrent.ChatRefresh);
		if (GetIntPropertyByName('bConsoleEnabled', intval))
		{
			qhcurrent.bConsoleEnabled = intval != 0;
		}
		GetStringArrayPropertyByName('denyUrlOptions', qhcurrent.denyUrlOptions, chr(10));
		GetStringArrayPropertyByName('denyConsoleCommands', qhcurrent.denyConsoleCommands, chr(10));
		if (GetIntPropertyByName('bAdminConsoleCommandsHack', intval))
		{
			qhcurrent.bAdminConsoleCommandsHack = intval != 0;
		}
		GetStringPropertyByName('AdminCommandHandlerClass', qhcurrent.AdminCommandHandlerClass);
		if (GetIntPropertyByName('bEnableTeamChat', intval))
		{
			qhcurrent.bEnableTeamChat = intval != 0;
		}
		if (GetIntPropertyByName('hideNews', intval))
		{
			qhcurrent.hideNews = intval != 0;
		}
		qhcurrent.SaveConfig();
	}
	else {
		GetIntPropertyByName('ChatRefresh', class'QHCurrent'.default.ChatRefresh);
		if (GetIntPropertyByName('bConsoleEnabled', intval))
		{
			class'QHCurrent'.default.bConsoleEnabled = intval != 0;
		}
		GetStringArrayPropertyByName('denyUrlOptions', class'QHCurrent'.default.denyUrlOptions, chr(10));
		GetStringArrayPropertyByName('denyConsoleCommands', class'QHCurrent'.default.denyConsoleCommands, chr(10));
		if (GetIntPropertyByName('bAdminConsoleCommandsHack', intval))
		{
			class'QHCurrent'.default.bAdminConsoleCommandsHack = intval != 0;
		}
		GetStringPropertyByName('AdminCommandHandlerClass', class'QHCurrent'.default.AdminCommandHandlerClass);
		if (GetIntPropertyByName('bEnableTeamChat', intval))
		{
			class'QHCurrent'.default.bEnableTeamChat = intval != 0;
		}
		if (GetIntPropertyByName('hideNews', intval))
		{
			class'QHCurrent'.default.hideNews = intval != 0;
		}
		class'QHCurrent'.static.StaticSaveConfig();
	}

	// chatlog
	if (chatlog != none)
	{
		GetStringPropertyByName('chatLogFilename', chatlog.filename);
		if (GetIntPropertyByName('chatLogUnique', intval))
		{
			chatlog.bUnique = intval != 0;
		}
		if (GetIntPropertyByName('chatLogIncludeTimeStamp', intval))
		{
			chatlog.bIncludeTimeStamp = intval != 0;
		}
		chatlog.SaveConfig();
	}
	else {
		GetStringPropertyByName('chatLogFilename', class'ChatLog'.default.filename);
		if (GetIntPropertyByName('chatLogUnique', intval))
		{
			class'ChatLog'.default.bUnique = intval != 0;
		}
		if (GetIntPropertyByName('chatLogIncludeTimeStamp', intval))
		{
			class'ChatLog'.default.bIncludeTimeStamp = intval != 0;
		}
		class'ChatLog'.static.StaticSaveConfig();
	}
}

function string GetSpecialValue(name PropertyName)
{
	if (PropertyName == `{WA_GROUP_SETTINGS})
	{
		return "General=0,20;Chat Logging=20,30;Authentication=30,40;Advanced=100,120";
	}
	return super.GetSpecialValue(PropertyName);
}

defaultProperties
{
	// generic
	Properties.Add((PropertyId=100,Data=(Type=SDT_String)))
	Properties.Add((PropertyId=101,Data=(Type=SDT_String)))
	Properties.Add((PropertyId=30,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=0,Data=(Type=SDT_String)))
	Properties.Add((PropertyId=20,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=102,Data=(Type=SDT_Int32)))

	PropertyMappings.Add((Id=100,Name="AuthenticationClass" `modloc(,ColumnHeaderText="Authentication class") ,MappingType=PVMT_RawValue,MinVal=0,MaxVal=256))
	PropertyMappings.Add((Id=101,name="SessionHandlerClass" `modloc(,ColumnHeaderText="Session Handler class") ,MappingType=PVMT_RawValue,MinVal=0,MaxVal=256))
	PropertyMappings.Add((Id=30,name="bHttpAuth" `modloc(,ColumnHeaderText="HTTP Authentication") ,MappingType=PVMT_IdMapped,ValueMappings=((Id=0 `modloc(,name="No") ),(Id=1 `modloc(,name="Yes") ))))
	PropertyMappings.Add((Id=0,name="startpage" `modloc(,ColumnHeaderText="Starting Page") ,MappingType=PVMT_RawValue,MinVal=0,MaxVal=256))
	PropertyMappings.Add((Id=20,name="bChatLog" `modloc(,ColumnHeaderText="Chat Logging") ,MappingType=PVMT_IdMapped,ValueMappings=((Id=0 `modloc(,name="No") ),(Id=1 `modloc(,name="Yes") ))))
	PropertyMappings.Add((Id=102,name="bUseStrictContentType" `modloc(,ColumnHeaderText="Send XHTML headers") ,MappingType=PVMT_IdMapped,ValueMappings=((Id=0 `modloc(,name="No") ),(Id=1 `modloc(,name="Yes") ))))

	// qhcurrent
	Properties.Add((PropertyId=1,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=2,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=3,Data=(Type=SDT_String)))
	Properties.Add((PropertyId=4,Data=(Type=SDT_String)))
	Properties.Add((PropertyId=104,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=103,Data=(Type=SDT_String)))
	Properties.Add((PropertyId=5,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=6,Data=(Type=SDT_Int32)))

	PropertyMappings.Add((Id=1,name="ChatRefresh" `modloc(,ColumnHeaderText="Chat Windows Refresh") ,MappingType=PVMT_Ranged,MinVal=0,MaxVal=9999,RangeIncrement=10))
	PropertyMappings.Add((Id=2,name="bConsoleEnabled" `modloc(,ColumnHeaderText="Management Console Enabled") ,MappingType=PVMT_IdMapped,ValueMappings=((Id=0 `modloc(,name="No") ),(Id=1 `modloc(,name="Yes") ))))
	PropertyMappings.Add((Id=3,name="denyUrlOptions" `modloc(,ColumnHeaderText="Deny URL options") ,MappingType=PVMT_RawValue,MinVal=0,MaxVal=1024))
	PropertyMappings.Add((Id=4,name="denyConsoleCommands" `modloc(,ColumnHeaderText="Deny Console Commands") ,MappingType=PVMT_RawValue,MinVal=0,MaxVal=1024))
	PropertyMappings.Add((Id=104,name="bAdminConsoleCommandsHack" `modloc(,ColumnHeaderText="Admin Console Commands Enabled") ,MappingType=PVMT_IdMapped,ValueMappings=((Id=0 `modloc(,name="No") ),(Id=1 `modloc(,name="Yes") ))))
	PropertyMappings.Add((Id=103,name="AdminCommandHandlerClass" `modloc(,ColumnHeaderText="Admin Console Commands Handler") ,MappingType=PVMT_RawValue,MinVal=0,MaxVal=256))
	PropertyMappings.Add((Id=5,name="bEnableTeamChat" `modloc(,ColumnHeaderText="Enable Team Chatting") ,MappingType=PVMT_IdMapped,ValueMappings=((Id=0 `modloc(,name="No") ),(Id=1 `modloc(,name="Yes") ))))
	PropertyMappings.Add((Id=6,name="hideNews" `modloc(,ColumnHeaderText="Hide News") ,MappingType=PVMT_IdMapped,ValueMappings=((Id=0 `modloc(,name="No") ),(Id=1 `modloc(,name="Yes") ))))

	// chatlog
	Properties.Add((PropertyId=21,Data=(Type=SDT_String)))
	Properties.Add((PropertyId=22,Data=(Type=SDT_Int32)))
	Properties.Add((PropertyId=23,Data=(Type=SDT_Int32)))
	PropertyMappings.Add((Id=21,name="chatLogFilename" `modloc(,ColumnHeaderText="Filename") ,MappingType=PVMT_RawValue,MinVal=0,MaxVal=256))
	PropertyMappings.Add((Id=22,name="chatLogUnique" `modloc(,ColumnHeaderText="Force uniqe name") ,MappingType=PVMT_IdMapped,ValueMappings=((Id=0 `modloc(,name="No") ),(Id=1 `modloc(,name="Yes") ))))
	PropertyMappings.Add((Id=23,name="chatLogIncludeTimeStamp" `modloc(,ColumnHeaderText="Append timestamp") ,MappingType=PVMT_IdMapped,ValueMappings=((Id=0 `modloc(,name="No") ),(Id=1 `modloc(,name="Yes") ))))
}
