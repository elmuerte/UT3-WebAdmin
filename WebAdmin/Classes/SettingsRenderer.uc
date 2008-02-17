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
var protected WebResponse curResponse;

function init(string basePath, optional string filePrefix="settings_")
{
	prefix = filePrefix;
	path = basePath;
}

function cleanup()
{
	curSettings = none;
	curResponse = none;
}

function render(Settings settings, WebResponse response, optional string substName = "settings")
{
	local string result, entry;
	local int idx;
	local EPropertyValueMappingType mtype;

	curSettings = settings;
	curResponse = response;

	for (idx = 0; idx < settings.LocalizedSettingsMappings.length; idx++)
	{
		entry = renderLocalizedSetting(settings.LocalizedSettingsMappings[idx].Id);
		if (len(entry) > 0)
		{
			curResponse.subst("setting.html", entry);
			result $= curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "entry.inc");
		}
	}
	for (idx = 0; idx < settings.PropertyMappings.length; idx++)
	{
		settings.GetPropertyMappingType(settings.PropertyMappings[idx].Id, mtype);
		switch (mtype)
		{
			case PVMT_PredefinedValues:
				entry = renderPredefinedValues(settings.PropertyMappings[idx].Id, idx);
				break;
			case PVMT_Ranged:
				entry = renderRanged(settings.PropertyMappings[idx].Id);
				break;
			case PVMT_IdMapped:
				entry = renderIdMapped(settings.PropertyMappings[idx].Id, idx);
				break;
			default:
				entry = renderRaw(settings.PropertyMappings[idx].Id);
		}
		if (len(entry) > 0)
		{
			// assume other details have been set
			curResponse.subst("setting.html", entry);
			result $= curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "entry.inc");
		}
	}

	curResponse.subst(substName, result);
}

protected function string renderLocalizedSetting(int settingId)
{
	local string options, settingtext;
	local array<IdToStringMapping> values;
	local int selectedValue;
	local int i;

	curResponse.subst("setting.type", "localizedSetting");
	curResponse.subst("setting.id", string(settingId));
	curResponse.subst("setting.name", curSettings.GetStringSettingName(settingId));
	settingtext = curSettings.GetStringSettingColumnHeader(settingId);
	if (len(settingtext) == 0)
	{
		settingtext = string(curSettings.GetStringSettingName(settingId));
	}
	curResponse.subst("setting.text", class'WebAdminUtils'.static.HTMLEscape(settingtext));

	curSettings.GetStringSettingValue(settingId, selectedValue);
	curSettings.GetStringSettingValueNames(settingId, values);
	for (i = 0; i < values.Length; i++)
	{
		curResponse.subst("setting.option.value", values[i].id);
		curResponse.subst("setting.option.text", class'WebAdminUtils'.static.HTMLEscape(values[i].name));
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

protected function string getSettingText(int settingId)
{
	local string val;
	val = curSettings.GetPropertyColumnHeader(settingId);
	if (len(val) > 0) return val;
	return string(curSettings.GetPropertyName(settingId));
}

protected function string renderPredefinedValues(int settingId, int idx)
{
	local string options, selectedValue, part1, part2;
	local int i;
	local array<SettingsData> values;

	local string svalue;
	local int ivalue;
	local float fvalue;

	curResponse.subst("setting.type", "predefinedValues");
	curResponse.subst("setting.id", string(settingId));
	curResponse.subst("setting.name", curSettings.GetPropertyName(settingId));
	curResponse.subst("setting.text", class'WebAdminUtils'.static.HTMLEscape(getSettingText(settingId)));

	selectedValue = curSettings.GetPropertyAsString(settingId);
	values = curSettings.PropertyMappings[idx].PredefinedValues;
	for (i = 0; i < values.Length; i++)
	{
		switch (values[i].Type)
		{
			case SDT_Int32:
			case SDT_Int64:
				ivalue = curSettings.GetSettingsDataInt(values[i]);
				curResponse.subst("setting.option.value", string(ivalue));
				curResponse.subst("setting.option.text", string(ivalue));
				svalue = string(ivalue);
				break;
			case SDT_Double:
			case SDT_Float:
				fvalue = curSettings.GetSettingsDataFloat(values[i]);
				curResponse.subst("setting.option.value", string(fvalue));
				curResponse.subst("setting.option.text", string(fvalue));
				svalue = string(fvalue);
				break;
			case SDT_String:
				svalue = curSettings.GetSettingsDataString(values[i]);
				curResponse.subst("setting.option.value", class'WebAdminUtils'.static.HTMLEscape(svalue));
				curResponse.subst("setting.option.text", class'WebAdminUtils'.static.HTMLEscape(svalue));
				break;
			default:
				`Log("Unsupported data type",,'WebAdmin');
				return "";
		}
		if (svalue ~= selectedValue)
		{
			curResponse.subst("setting.option.selected", "selected=\"selected\"");
		}
		else {
			curResponse.subst("setting.option.selected", "");
		}
		options $= curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "option.inc");
	}
	curResponse.subst("setting.options", options);

	part1 = curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "select.inc");
	part2 = renderRaw(settingId, "_raw");

	curResponse.subst("mutlisetting.predef", part1);
	curResponse.subst("mutlisetting.raw", part2);
	curResponse.subst("setting.name", curSettings.GetPropertyName(settingId));

	return curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "multisetting.inc");
}

protected function string renderRanged(int settingId)
{
	local float value, min, max, incr;
	local byte asInt;

	curResponse.subst("setting.type", "ranged");
	curResponse.subst("setting.id", string(settingId));
	curResponse.subst("setting.name", curSettings.GetPropertyName(settingId));
	curResponse.subst("setting.text", class'WebAdminUtils'.static.HTMLEscape(getSettingText(settingId)));

	curSettings.GetRangedPropertyValue(settingId, value);
	curSettings.GetPropertyRange(settingId, min, max, incr, asInt);

	if (asInt != 1)
	{
		curResponse.subst("setting.value", string(value));
		curResponse.subst("setting.minval", string(min));
		curResponse.subst("setting.maxval", string(max));
		curResponse.subst("setting.increment", string(incr));
	}
	else {
		curResponse.subst("setting.value", string(int(value)));
		curResponse.subst("setting.minval", string(int(min)));
		curResponse.subst("setting.maxval", string(int(max)));
		curResponse.subst("setting.increment", string(int(incr)));
	}

	return curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "ranged.inc");
}

protected function string renderIdMapped(int settingId, int idx)
{
	local string options;
	local array<IdToStringMapping> values;
	local int selectedValue;
	local int i;

	curResponse.subst("setting.type", "idMapped");
	curResponse.subst("setting.id", string(settingId));
	curResponse.subst("setting.name", curSettings.GetPropertyName(settingId));
	curResponse.subst("setting.text", class'WebAdminUtils'.static.HTMLEscape(getSettingText(settingId)));

	curSettings.GetIntProperty(settingId, selectedValue);
	values = curSettings.PropertyMappings[idx].ValueMappings;
	for (i = 0; i < values.Length; i++)
	{
		curResponse.subst("setting.option.value", values[i].id);
		curResponse.subst("setting.option.text", class'WebAdminUtils'.static.HTMLEscape(values[i].name));
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

protected function string renderRaw(int settingId, optional string namePostF = "")
{
	curResponse.subst("setting.type", "raw");
	curResponse.subst("setting.id", string(settingId));
	curResponse.subst("setting.name", curSettings.GetPropertyName(settingId)$namePostF);
	curResponse.subst("setting.text", class'WebAdminUtils'.static.HTMLEscape(getSettingText(settingId)));
	curResponse.subst("setting.value", class'WebAdminUtils'.static.HTMLEscape(curSettings.GetPropertyAsString(settingId)));

	switch(curSettings.GetPropertyType(settingId))
	{
		case SDT_Empty:
			return  "";
		case SDT_Int32:
		case SDT_Int64:
			return curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "int.inc");
		case SDT_Double:
		case SDT_Float:
			return curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "float.inc");
		default:
			return curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "string.inc");
	}
}
