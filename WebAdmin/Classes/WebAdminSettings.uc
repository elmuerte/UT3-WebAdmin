/**
 * Base class for all WebAdminSettings instances that are include with the
 * WebAdmin package. You can use it as base class for your own WebAdmin
 * configuration classes, but that imposes a dependency on the WebAdmin package.
 * It's simply best to create a direct subclass of Settings and copy The
 * SetSpecialValue(...) implementation.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class WebAdminSettings extends Settings abstract;

`include(WebAdmin.uci)

function SetSpecialValue(name PropertyName, string NewValue)
{
	if (PropertyName == `{SETTINGS_COMMAND})
	{
		if (NewValue ~= `{SETTINGS_INIT_CMD})
		{
			init();
		}
		else if (NewValue ~= `{SETTINGS_SAVE_CMD})
		{
			save();
		}
		else {
			`Log("Unknown command for WebAdminSettings: "$NewValue,,'WebAdmin');
		}
	}
}

function init();

function save()
{
	saveInternal();
}

protected function saveInternal();

protected function bool SetFloatPropertyByName(name prop, float value)
{
	local int PropertyId;
	if (GetPropertyId(prop, PropertyId))
	{
		SetFloatProperty(PropertyId, value);
		return true;
	}
	return false;
}

protected function bool SetIntPropertyByName(name prop, int value)
{
	local int PropertyId;
	if (GetPropertyId(prop, PropertyId))
	{
		SetIntProperty(PropertyId, value);
		return true;
	}
	return false;
}

protected function bool SetStringPropertyByName(name prop, string value)
{
	local int PropertyId;
	if (GetPropertyId(prop, PropertyId))
	{
		SetStringProperty(PropertyId, value);
		return true;
	}
	return false;
}

protected function bool GetFloatPropertyByName(name prop, out float value)
{
	local int PropertyId;
	if (GetPropertyId(prop, PropertyId))
	{
		return GetFloatProperty(PropertyId, value);
	}
	return false;
}

protected function bool GetIntPropertyByName(name prop, out int value)
{
	local int PropertyId;
	if (GetPropertyId(prop, PropertyId))
	{
		return GetIntProperty(PropertyId, value);
	}
	return false;
}

protected function bool GetStringPropertyByName(name prop, out string value)
{
	local int PropertyId;
	if (GetPropertyId(prop, PropertyId))
	{
		return GetStringProperty(PropertyId, value);
	}
	return false;
}

defaultproperties
{
}
