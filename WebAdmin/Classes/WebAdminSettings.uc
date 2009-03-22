/**
 * Base class for all WebAdminSettings instances that are include with the
 * WebAdmin package. You can use it as base class for your own WebAdmin
 * configuration classes, but that imposes a dependency on the WebAdmin package.
 * It's simply best to create a subclass of Settings and copy the
 * SetSpecialValue(...) implementation from this class to your own.
 *
 * IMPORTANT! The WebAdmin is an optional server-side only package. Do not
 * introduce a dependency on this package from a package that a client needs to
 * download in order to play your mod.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class WebAdminSettings extends Settings abstract;

`include(WebAdmin.uci)

function SetSpecialValue(name PropertyName, string NewValue)
{
	if (PropertyName == `{WA_INIT_SETTINGS})
	{
		init();
	}
	else if (PropertyName == `{WA_SAVE_SETTINGS})
	{
		save();
	}
}

function init();

function save()
{
	saveInternal();
}

protected function saveInternal();

/** return the tooltip for a given property */
protected function string settingsTooltip(name PropertyName);

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
