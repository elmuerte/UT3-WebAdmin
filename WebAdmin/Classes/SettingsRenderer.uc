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

struct SortedSetting
{
	var string txt;
	/** index of this item in one of the whole lists */
	var int idx;
	/** if true it's a localized setting rather than a property */
	var bool isLocalized;
};
var protected array<SortedSetting> sorted;

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
	local int i, j;
	local EPropertyValueMappingType mtype;
	local SortedSetting sortset;

	curSettings = settings;
	curResponse = response;

	sorted.length = 0; // clear old
	for (i = 0; i < settings.LocalizedSettingsMappings.length; i++)
	{
		sortset.idx = i;
		sortset.isLocalized = true;
		sortset.txt = getLocalizedSettingText(settings.LocalizedSettingsMappings[i].Id);
		for (j = 0; j < sorted.length; j++)
		{
			if (Caps(sorted[j].txt) > Caps(sortset.txt))
			{
				sorted.Insert(j, 1);
				sorted[j] = sortset;
				break;
			}
		}
		if (j == sorted.length)
		{
			sorted[j] = sortset;
		}
	}
	for (i = 0; i < settings.PropertyMappings.length; i++)
	{
		sortset.idx = i;
		sortset.isLocalized = false;
		sortset.txt = getSettingText(settings.PropertyMappings[i].Id);
		for (j = 0; j < sorted.length; j++)
		{
			if (Caps(sorted[j].txt) > Caps(sortset.txt))
			{
				sorted.Insert(j, 1);
				sorted[j] = sortset;
				break;
			}
		}
		if (j == sorted.length)
		{
			sorted[j] = sortset;
		}
	}

	for (i = 0; i < sorted.length; i++)
	{
		if (sorted[i].isLocalized)
		{
			entry = renderLocalizedSetting(settings.LocalizedSettingsMappings[sorted[i].idx].Id);
		}
		else {
			j = sorted[i].idx;
			settings.GetPropertyMappingType(settings.PropertyMappings[j].Id, mtype);
			switch (mtype)
			{
				case PVMT_PredefinedValues:
					entry = renderPredefinedValues(settings.PropertyMappings[j].Id, j);
					break;
				case PVMT_Ranged:
					entry = renderRanged(settings.PropertyMappings[j].Id);
					break;
				case PVMT_IdMapped:
					entry = renderIdMapped(settings.PropertyMappings[j].Id, j);
					break;
				default:
					entry = renderRaw(settings.PropertyMappings[j].Id, j);
			}
		}
		if (len(entry) > 0)
		{
			curResponse.subst("setting.html", entry);
			result $= curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "entry.inc");
		}
	}

/*
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
*/

	curResponse.subst(substName, result);
}

protected function string getLocalizedSettingText(int settingId)
{
	local string val;
	val = curSettings.GetStringSettingColumnHeader(settingId);
	if (len(val) > 0) return val;
	return string(curSettings.GetStringSettingName(settingId));
}

protected function string renderLocalizedSetting(int settingId)
{
	local string options;
	local array<IdToStringMapping> values;
	local int selectedValue;
	local int i;

	curResponse.subst("setting.type", "localizedSetting");
	curResponse.subst("setting.id", string(settingId));
	curResponse.subst("setting.name", curSettings.GetStringSettingName(settingId));
	curResponse.subst("setting.text", class'WebAdminUtils'.static.HTMLEscape(getLocalizedSettingText(settingId)));

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
	part2 = renderRaw(settingId, idx, "_raw");

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

protected function string renderRaw(int settingId, int idx, optional string namePostF = "")
{
	local float min, max;
	curResponse.subst("setting.type", "raw");
	curResponse.subst("setting.id", string(settingId));
	curResponse.subst("setting.name", curSettings.GetPropertyName(settingId)$namePostF);
	curResponse.subst("setting.text", class'WebAdminUtils'.static.HTMLEscape(getSettingText(settingId)));
	curResponse.subst("setting.value", class'WebAdminUtils'.static.HTMLEscape(curSettings.GetPropertyAsString(settingId)));

	min = curSettings.PropertyMappings[idx].MinVal;
	max = curSettings.PropertyMappings[idx].MaxVal;
	switch(curSettings.GetPropertyType(settingId))
	{
		case SDT_Empty:
			return  "";
		case SDT_Int32:
		case SDT_Int64:
			if (max != 0)
			{
				curResponse.subst("setting.maxval", int(max));
				curResponse.subst("setting.minval", int(min));
			}
			else {
				curResponse.subst("setting.maxval", "NaN");
				curResponse.subst("setting.minval", "NaN");
			}
			return curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "int.inc");
		case SDT_Double:
		case SDT_Float:
			if (max != 0)
			{
				curResponse.subst("setting.maxval", max);
				curResponse.subst("setting.minval", min);
			}
			else {
				curResponse.subst("setting.maxval", "NaN");
				curResponse.subst("setting.minval", "NaN");
			}
			return curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "float.inc");
		default:
			if (max != 0)
			{
				curResponse.subst("setting.maxval", max);
				curResponse.subst("setting.minval", min);
			}
			else {
				curResponse.subst("setting.maxval", "NaN");
				curResponse.subst("setting.minval", "NaN");
			}
			if (max > 0 && max > min)
			{
				curResponse.subst("setting.maxlength", int(max));
			}
			else {
				curResponse.subst("setting.maxlength", "");
			}
			if (max > 256)
			{
				return curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "textarea.inc");
			}
			else {
				return curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "string.inc");
			}
	}
}
