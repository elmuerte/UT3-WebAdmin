/**
 * Settings for the UTMutator_Arena
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class UTMutator_ArenaSettings extends Settings implements(IAdvWebAdminSettings);

`include(WebAdmin.uci)

var array<UTUIDataProvider_Weapon> weapons;

function initSettings(WorldInfo worldinfo, DataStoreCache dscache)
{
	dscache.loadWeapons();
	weapons = dscache.weapons;
}

function cleanup()
{
	weapons.length = 0;
}

function bool saveSettings(WebRequest request, WebAdminMessages messages)
{
	class'UTMutator_Arena'.default.ArenaWeaponClassPath = request.GetVariable("ArenaWeaponClassPath", class'UTMutator_Arena'.default.ArenaWeaponClassPath);
	class'UTMutator_Arena'.static.StaticSaveConfig();
	return true;
}

function renderSettings(WebResponse response, SettingsRenderer renderer, optional string substName = "settings")
{
	local string selectedValue, options;
	local int i;

	response.subst("setting.id", "0");
	response.subst("setting.name", "ArenaWeaponClassPath");
	response.subst("setting.formname", "ArenaWeaponClassPath");
	response.subst("setting.text", `HTMLEscape("Area Weapon"));

	selectedValue = class'UTMutator_Arena'.default.ArenaWeaponClassPath;
 	for (i = 0; i < weapons.Length; i++)
	{
		response.subst("setting.option.value", weapons[i].ClassName);
		response.subst("setting.option.text", `HTMLEscape(weapons[i].FriendlyName));
		if (weapons[i].ClassName ~= selectedValue)
		{
			response.subst("setting.option.selected", "selected=\"selected\"");
		}
		else {
			response.subst("setting.option.selected", "");
		}
		options $= response.LoadParsedUHTM(renderer.getPath() $ "/" $ renderer.getFilePrefix() $ "option.inc");
	}
	response.subst("setting.options", options);
	response.subst("setting.html", response.LoadParsedUHTM(renderer.getPath() $ "/" $ renderer.getFilePrefix() $ "select.inc"));
	response.Subst(substName, response.LoadParsedUHTM(renderer.getPath() $ "/" $ renderer.getFilePrefix() $ "entry.inc"));
}
