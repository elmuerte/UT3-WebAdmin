/**
 * This class provides the functionality to render a HTML page of a Settings
 * instance.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class SettingsRenderer extends Object dependsOn(Settings);

`include(WebAdmin.uci)

/**
 * Prefix of all include files.
 */
var protected string prefix;

/**
 * Prefix for variable names
 */
var protected string namePrefix;

/**
 * The base path to load the include files from
 */
var protected string path;

/**
 * Minimum number of options in a idMapped setting before switching to a listbox
 */
var int minOptionListSize;

struct SortedSetting
{
	var string txt;
	/** index of this item in one of the whole lists */
	var int idx;
	/** if true it's a localized setting rather than a property */
	var bool isLocalized;
};

struct SettingsGroup
{
	var string title;
	var array<SortedSetting> settings;
	/** range in the properties that belongs to this group */
	var int pMin,pMax;
	/** range in the localized properties that belongs to this group */
	var int lMin,lMax;
};
var array<SettingsGroup> groups;

var protected Settings curSettings;
var protected WebResponse curResponse;

/**
 * Initialization when the instance is created.
 */
function init(string basePath, optional string namePre="settings_", optional string filePrefix="settings_")
{
	prefix = filePrefix;
	path = basePath;
	namePrefix = namePre;
	minOptionListSize=4;
}

function string getPath()
{
	return path;
}

function string getFilePrefix()
{
	return prefix;
}

function string getNamePrefix()
{
	return namePrefix;
}

function cleanup()
{
	curSettings = none;
	curResponse = none;
}

/**
 * Used to initialize the rendered for an IAdvWebAdminSettings instance
 */
function initEx(Settings settings, WebResponse response)
{
	curSettings = settings;
	curResponse = response;
}

/**
 * Sort all settings based on their name
 */
function sortSettings(int groupId)
{
	local int i, j;
	local SortedSetting sortset;

	groups[groupId].settings.length = 0; // clear old
	for (i = 0; i < curSettings.LocalizedSettingsMappings.length; i++)
	{
		if (curSettings.LocalizedSettingsMappings[i].Id < groups[groupId].lMin) continue;
		if (curSettings.LocalizedSettingsMappings[i].Id >= groups[groupId].lMax) continue;
		if (curSettings.LocalizedSettingsMappings[i].Name == '') continue;
		sortset.idx = i;
		sortset.isLocalized = true;
		sortset.txt = getLocalizedSettingText(curSettings.LocalizedSettingsMappings[i].Id);
		for (j = 0; j < groups[groupId].settings.length; j++)
		{
			if (Caps(groups[groupId].settings[j].txt) > Caps(sortset.txt))
			{
				groups[groupId].settings.Insert(j, 1);
				groups[groupId].settings[j] = sortset;
				break;
			}
		}
		if (j == groups[groupId].settings.length)
		{
			groups[groupId].settings[j] = sortset;
		}
	}
	for (i = 0; i < curSettings.PropertyMappings.length; i++)
	{
		if (curSettings.PropertyMappings[i].Id < groups[groupId].pMin) continue;
		if (curSettings.PropertyMappings[i].Id >= groups[groupId].pMax) continue;
		if (curSettings.PropertyMappings[i].Name == '') continue;
		sortset.idx = i;
		sortset.isLocalized = false;
		sortset.txt = getSettingText(curSettings.PropertyMappings[i].Id);
		for (j = 0; j < groups[groupId].settings.length; j++)
		{
			if (Caps(groups[groupId].settings[j].txt) > Caps(sortset.txt))
			{
				groups[groupId].settings.Insert(j, 1);
				groups[groupId].settings[j] = sortset;
				break;
			}
		}
		if (j == groups[groupId].settings.length)
		{
			groups[groupId].settings[j] = sortset;
		}
	}
}

/**
 * Creates the settings groups
 */
function createGroups()
{
	// Group spec:
	//	<group1>;<group2>;<group3>
	// Where group:
	//	<title>=<pMin>,<pMax>,<lMin>,<lMax>
	local string spec;
	local array<string> gspec, ranges;
	local SettingsGroup group;
	local int idx;

	groups.length = 0;
	spec = curSettings.GetSpecialValue(`{WA_GROUP_SETTINGS});
	ParseStringIntoArray(spec, gspec, ";", true);
	foreach gspec(spec)
	{
		idx = InStr(spec, "=");
		if (idx == INDEX_NONE) continue;
		group.title = Left(spec, idx);
		spec = Mid(spec, idx+1);
		group.settings.Length = 0;
		ParseStringIntoArray(spec, ranges, ",", false);
		ranges.length = 4;
		group.pMin = int(ranges[0]);
		group.pMax = int(ranges[1]);
		group.lMin = int(ranges[2]);
		group.lMax = int(ranges[3]);
		groups.AddItem(group);
	}
	if (groups.length == 0)
	{
		group.title = "";
		group.pMin = 0;
		group.pMax = curSettings.PropertyMappings.Length;
		group.lMin = 0;
		group.lMax = curSettings.LocalizedSettingsMappings.length;
		group.settings.Length = 0;
		groups.AddItem(group);
		return;
	}
}

/**
 * Render all properties of the given settings instance
 */
function render(Settings settings, WebResponse response, optional string substName = "settings")
{
	local string result, entry;
	local int i;

	curSettings = settings;
	curResponse = response;

	createGroups();
	for (i = 0; i < groups.length; i++)
	{
		sortSettings(i);
	}
	if (groups.length == 1)
	{
		curResponse.Subst("settings", renderGroup(groups[0]));
		result = curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "wrapper_single.inc");
	}
	else {
		for (i = 0; i < groups.length; i++)
		{
			if (groups[i].settings.length == 0) continue;
			curResponse.Subst("group.id", "SettingsGroup"$i);
			curResponse.Subst("group.title", `HTMLEscape(groups[i].title));
			curResponse.Subst("group.settings", renderGroup(groups[i]));
			entry = curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "group.inc");
			result $= entry;
		}
		curResponse.Subst("settings", result);
		result = curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "wrapper_group.inc");
	}
	curResponse.subst(substName, result);
}

/**
 * Render a selection of settings
 */
function string renderGroup(SettingsGroup group)
{
	local string result, entry;
	local int i, j;
	local EPropertyValueMappingType mtype;

	for (i = 0; i < group.settings.length; i++)
	{
		if (group.settings[i].isLocalized)
		{
			entry = renderLocalizedSetting(curSettings.LocalizedSettingsMappings[group.settings[i].idx].Id);
		}
		else {
			j = group.settings[i].idx;
			curSettings.GetPropertyMappingType(curSettings.PropertyMappings[j].Id, mtype);
			`log(""@i@group.settings[i].idx@curSettings.PropertyMappings[j].Id);
			defaultSubst(curSettings.PropertyMappings[j].Id);
			switch (mtype)
			{
				case PVMT_PredefinedValues:
					entry = renderPredefinedValues(curSettings.PropertyMappings[j].Id, j);
					break;
				case PVMT_Ranged:
					entry = renderRanged(curSettings.PropertyMappings[j].Id);
					break;
				case PVMT_IdMapped:
					entry = renderIdMapped(curSettings.PropertyMappings[j].Id, j);
					break;
				default:
					entry = renderRaw(curSettings.PropertyMappings[j].Id, j);
			}
		}
		if (len(entry) > 0)
		{
			curResponse.subst("setting.html", entry);
			result $= curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "entry.inc");
		}
	}
	return result;
}

/**
 * Get a readable name for the current localized property
 */
function string getLocalizedSettingText(int settingId)
{
	local string val;
	val = curSettings.GetStringSettingColumnHeader(settingId);
	if (len(val) > 0) return val;
	return string(curSettings.GetStringSettingName(settingId));
}

/**
 * Render a localized property
 */
function string renderLocalizedSetting(int settingId)
{
	local string options;
	local array<IdToStringMapping> values;
	local int selectedValue;
	local int i;

	curResponse.subst("setting.type", "localizedSetting");
	curResponse.subst("setting.id", string(settingId));
	curResponse.subst("setting.name", curSettings.GetStringSettingName(settingId));
	curResponse.subst("setting.formname", namePrefix$curSettings.GetStringSettingName(settingId));
	curResponse.subst("setting.text", `HTMLEscape(getLocalizedSettingText(settingId)));

	curSettings.GetStringSettingValue(settingId, selectedValue);
	curSettings.GetStringSettingValueNames(settingId, values);
	if (values.length >= minOptionListSize)
	{
		for (i = 0; i < values.Length; i++)
		{
			curResponse.subst("setting.option.value", values[i].id);
			curResponse.subst("setting.option.text", `HTMLEscape(values[i].name));
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
	else {
		for (i = 0; i < values.Length; i++)
		{
			curResponse.subst("setting.radio.index", i);
			curResponse.subst("setting.radio.value", values[i].id);
			curResponse.subst("setting.radio.text", `HTMLEscape(values[i].name));
			if (values[i].id == selectedValue)
			{
				curResponse.subst("setting.radio.selected", "checked=\"checked\"");
			}
			else {
				curResponse.subst("setting.radio.selected", "");
			}
			options $= curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "radio.inc");
		}
		return options;
	}
}

/**
 * Get a name for the current setting property.
 */
function string getSettingText(int settingId)
{
	local string val;
	val = curSettings.GetPropertyColumnHeader(settingId);
	if (len(val) > 0) return val;
	return string(curSettings.GetPropertyName(settingId));
}

/**
 * Set the default substitution parts for the current property
 */
function defaultSubst(int settingId)
{
	curResponse.subst("setting.id", string(settingId));
	curResponse.subst("setting.name", curSettings.GetPropertyName(settingId));
	curResponse.subst("setting.formname", namePrefix$curSettings.GetPropertyName(settingId));
	curResponse.subst("setting.text", `HTMLEscape(getSettingText(settingId)));
}

function string renderPredefinedValues(int settingId, int idx)
{
	local string options, selectedValue, part1, part2;
	local int i;
	local array<SettingsData> values;

	local bool usedPreDef, selected;
	local string svalue;
	local int ivalue;
	local float fvalue;

	curResponse.subst("setting.type", "predefinedValues");

	selectedValue = curSettings.GetPropertyAsString(settingId);
	values = curSettings.PropertyMappings[idx].PredefinedValues;
	usedPreDef = false;
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
				selected = (ivalue == int(selectedValue));
				break;
			case SDT_Double:
			case SDT_Float:
				fvalue = curSettings.GetSettingsDataFloat(values[i]);
				curResponse.subst("setting.option.value", string(fvalue));
				curResponse.subst("setting.option.text", string(fvalue));
				selected = (fvalue ~= float(selectedValue));
				break;
			case SDT_String:
				svalue = curSettings.GetSettingsDataString(values[i]);
				curResponse.subst("setting.option.value", `HTMLEscape(svalue));
				curResponse.subst("setting.option.text", `HTMLEscape(svalue));
				selected = (svalue ~= selectedValue);
				break;
			default:
				`Log("Unsupported data type",,'WebAdmin');
				return "";
		}
		if (selected)
		{
			usedPreDef = true;
			curResponse.subst("setting.option.selected", "selected=\"selected\"");
		}
		else {
			curResponse.subst("setting.option.selected", "");
		}
		options $= curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "option.inc");
	}
	if (usedPreDef)
	{
		curResponse.subst("setting.options", options);

		part1 = curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "select.inc");
		curResponse.subst("setting.formname", namePrefix$curSettings.GetPropertyName(settingId)$"_raw");
		part2 = renderRaw(settingId, idx);

		curResponse.subst("mutlisetting.predef", part1);
		curResponse.subst("mutlisetting.raw", part2);
		curResponse.subst("setting.formname", namePrefix$curSettings.GetPropertyName(settingId));

		return curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "multisetting.inc");
	}
	else {
		return renderRaw(settingId, idx);
	}
}

function string renderRanged(int settingId)
{
	local float value, min, max, incr;
	local byte asInt;

	curResponse.subst("setting.type", "ranged");

	curSettings.GetRangedPropertyValue(settingId, value);
	curSettings.GetPropertyRange(settingId, min, max, incr, asInt);

	if (asInt != 1)
	{
		curResponse.subst("setting.value", string(value));
		curResponse.subst("setting.minval", string(min));
		curResponse.subst("setting.maxval", string(max));
		curResponse.subst("setting.increment", string(incr));
		curResponse.subst("setting.asint", "false");
	}
	else {
		curResponse.subst("setting.value", string(int(value)));
		curResponse.subst("setting.minval", string(int(min)));
		curResponse.subst("setting.maxval", string(int(max)));
		curResponse.subst("setting.increment", string(int(incr)));
		curResponse.subst("setting.asint", "true");
	}

	return curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "ranged.inc");
}

function string renderIdMapped(int settingId, int idx)
{
	local string options;
	local array<IdToStringMapping> values;
	local int selectedValue;
	local int i;

	curResponse.subst("setting.type", "idMapped");

	curSettings.GetIntProperty(settingId, selectedValue);
	values = curSettings.PropertyMappings[idx].ValueMappings;
	if (values.length >= minOptionListSize)
	{
		for (i = 0; i < values.Length; i++)
		{
			curResponse.subst("setting.option.value", values[i].id);
			curResponse.subst("setting.option.text", `HTMLEscape(values[i].name));
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
	else {
		for (i = 0; i < values.Length; i++)
		{
			curResponse.subst("setting.radio.index", i);
			curResponse.subst("setting.radio.value", values[i].id);
			curResponse.subst("setting.radio.text", `HTMLEscape(values[i].name));
			if (values[i].id == selectedValue)
			{
				curResponse.subst("setting.radio.selected", "checked=\"checked\"");
			}
			else {
				curResponse.subst("setting.radio.selected", "");
			}
			options $= curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "radio.inc");
		}
		return options;
	}
}

function string renderRaw(int settingId, int idx)
{
	local float min, max, incr;
	curResponse.subst("setting.type", "raw");
	curResponse.subst("setting.value", `HTMLEscape(curSettings.GetPropertyAsString(settingId)));

	min = curSettings.PropertyMappings[idx].MinVal;
	max = curSettings.PropertyMappings[idx].MaxVal;
	incr = curSettings.PropertyMappings[idx].RangeIncrement;
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
				curResponse.subst("setting.maxval", "Number.NaN");
				curResponse.subst("setting.minval", "Number.NaN");
			}
			if (incr > 0)
			{
				curResponse.subst("setting.increment", string(int(incr)));
			}
			curResponse.subst("setting.asint", "true");
			return curResponse.LoadParsedUHTM(path $ "/" $ prefix $ "int.inc");
		case SDT_Double:
		case SDT_Float:
			if (max != 0)
			{
				curResponse.subst("setting.maxval", max);
				curResponse.subst("setting.minval", min);
			}
			else {
				curResponse.subst("setting.maxval", "Number.NaN");
				curResponse.subst("setting.minval", "Number.NaN");
			}
			if (incr > 0)
			{
				curResponse.subst("setting.increment", string(incr));
			}
			curResponse.subst("setting.asint", "false");
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

defaultproperties
{
	minOptionListSize=4
}
