/**
 * This class provides the functionality to render a HTML page of a Settings
 * instance.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class SettingsRenderer extends Object dependsOn(Settings);

/**
 * Prefix of all include files.
 */
var protected string prefix;

/**
 * The base path to load the include files from
 */
var protected string path;

var protected Settings curSettings;
var protected WebRequest curRequest;
var protected WebResponse curResponse;

function init(string basePath, optional string filePrefix="settings_")
{
	prefix = filePrefix;
	path = basePath;
}

function cleanup()
{
	curSettings = none;
	curRequest = none;
	curResponse = none;
}

function render(Settings settings, WebRequest request, WebResponse response, optional string substName = "settings")
{
	local string result;
	local int idx;
	local EPropertyValueMappingType mtype;

	curSettings = settings;
	curRequest = request;
	curResponse = response;

	for (idx = 0; idx < settings.LocalizedSettingsMappings.length; idx++)
	{
		result $= renderLocalizedSetting(settings.LocalizedSettingsMappings[idx].Id);
	}
	for (idx = 0; idx < settings.PropertyMappings.length; idx++)
	{
		settings.GetPropertyMappingType(settings.PropertyMappings[idx].Id, mtype);
		switch (mtype)
		{
			case PVMT_PredefinedValues:
				result $= renderPredefinedValues(settings.PropertyMappings[idx].Id);
				break;
			case PVMT_Ranged:
				result $= renderRanged(settings.PropertyMappings[idx].Id);
				break;
			case PVMT_IdMapped:
				result $= renderIdMapped(settings.PropertyMappings[idx].Id, idx);
				break;
			default:
				result $= renderRaw(settings.PropertyMappings[idx].Id);
		}
	}

	curResponse.subst(substName, result);
}

protected function string renderLocalizedSetting(int settingId)
{
	local string options;
	local array<IdToStringMapping> values;
	local int selectedValue;
	local int i;

	curResponse.subst("setting.id", ""$settingId);
	curResponse.subst("setting.name", curSettings.GetStringSettingName(settingId));
	curResponse.subst("setting.text", curSettings.GetStringSettingColumnHeader(settingId));

	curSettings.GetStringSettingValue(settingId, selectedValue);
	curSettings.GetStringSettingValueNames(settingId, values);
	for (i = 0; i < values.Length; i++)
	{
		curResponse.subst("setting.option.id", values[i].id);
		curResponse.subst("setting.option.name", values[i].name);
		if (values[i].id == selectedValue)
		{
			curResponse.subst("setting.option.selected", "selected=\"selected\"");
		}
		else {
			curResponse.subst("setting.option.selected", "");
		}
		options $= curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "option.inc");
	}
	curResponse.subst("setting.options", options);
	return curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "select.inc");
}

protected function string renderPredefinedValues(int settingId)
{
	return "";
}

protected function string renderRanged(int settingId)
{
	return "";
}

protected function string renderIdMapped(int settingId, int idx)
{
	local string options;
	local array<IdToStringMapping> values;
	local int selectedValue;
	local int i;

	curResponse.subst("setting.id", ""$settingId);
	curResponse.subst("setting.name", curSettings.GetPropertyName(settingId));
	curResponse.subst("setting.text", curSettings.GetPropertyColumnHeader(settingId));

	curSettings.GetIntProperty(settingId, selectedValue);
	values = curSettings.PropertyMappings[idx].ValueMappings;
	for (i = 0; i < values.Length; i++)
	{
		curResponse.subst("setting.option.id", values[i].id);
		curResponse.subst("setting.option.name", values[i].name);
		if (values[i].id == selectedValue)
		{
			curResponse.subst("setting.option.selected", "selected=\"selected\"");
		}
		else {
			curResponse.subst("setting.option.selected", "");
		}
		options $= curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "option.inc");
	}
	curResponse.subst("setting.options", options);
	return curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "select.inc");
}

protected function string renderRaw(int settingId)
{
	return "";
}
