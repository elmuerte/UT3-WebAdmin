/**
 * Settings for the UTMutator_Arena
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class UTMutator_WeaponReplacementSettings extends Settings implements(IAdvWebAdminSettings);

`include(WebAdmin.uci)

struct WeaponData
{
	var name clsName;
	var name ammoClsName;
	var UTUIDataProvider_Weapon data;
};

var array<WeaponData> weapons;

function initSettings(WorldInfo worldinfo, DataStoreCache dscache)
{
	local int i, idx;
	dscache.loadWeapons();
	for (i = 0; i < dscache.weapons.Length; i++)
	{
		if (InStr(dscache.weapons[i].ClassName, ".") == INDEX_NONE)
		{
			`Warn("Invalid weapon class: "$dscache.weapons[i].ClassName,,'WebAdmin');
			continue;
		}
		idx = weapons.length;
		weapons.length = idx+1;
		weapons[idx].clsName = name(Split(dscache.weapons[i].ClassName, ".", true));
		if (InStr(dscache.weapons[i].AmmoClassPath, ".") != INDEX_NONE)
		{
			weapons[idx].ammoClsName = name(Split(dscache.weapons[i].AmmoClassPath, ".", true));
		}
		else {
			weapons[idx].ammoClsName = 'none';
		}
		weapons[idx].data = dscache.weapons[i];
	}
}

function cleanup()
{
	weapons.length = 0;
}

function bool saveSettings(WebRequest request, WebAdminMessages messages)
{
	local int i, idx;
	local string cls;
	local ReplacementInfo entry;

	class'UTMutator_WeaponReplacement'.default.WeaponsToReplace.Length = 0;
	class'UTMutator_WeaponReplacement'.default.AmmoToReplace.Length = 0;
	for (i = 0; i < weapons.length; i++)
	{
		cls = request.GetVariable("weapon.."$weapons[i].data.ClassName);
		if (Len(cls) == 0) continue;
		if (cls ~= weapons[i].data.ClassName) continue;
		for (idx = 0; idx < weapons.Length; idx++)
		{
			if (weapons[idx].data.ClassName ~= cls) break;
		}
		if (idx == weapons.Length) continue;

		entry.OldClassName = weapons[i].clsName;
		entry.NewClassPath = weapons[idx].data.ClassName;
		class'UTMutator_WeaponReplacement'.default.WeaponsToReplace.AddItem(entry);
		if (weapons[i].ammoClsName != 'none')
		{
			entry.OldClassName = weapons[i].ammoClsName;
			entry.NewClassPath = weapons[idx].data.AmmoClassPath;
			class'UTMutator_WeaponReplacement'.default.AmmoToReplace.AddItem(entry);
		}
	}

	class'UTMutator_WeaponReplacement'.static.StaticSaveConfig();
	return true;
}

function renderSettings(WebResponse response, SettingsRenderer renderer, optional string substName = "settings")
{
	local string substvar, selectedValue, options;
	local int i, j, idx;

	for (i = 0; i < weapons.Length; i++)
	{
		response.subst("setting.id", string(i));
		response.subst("setting.name", weapons[i].data.ClassName);
		response.subst("setting.formname", "weapon.."$weapons[i].data.ClassName);
		response.subst("setting.text", `HTMLEscape(weapons[i].data.FriendlyName));

		idx = class'UTMutator_WeaponReplacement'.default.WeaponsToReplace.find('OldClassName', weapons[i].clsName);
		if (idx != INDEX_NONE)
		{
			selectedValue = class'UTMutator_WeaponReplacement'.default.WeaponsToReplace[idx].NewClassPath;
		}
		else {
			selectedValue = weapons[i].data.ClassName;
		}
		options = "";
 		for (j = 0; j < weapons.Length; j++)
		{
			response.subst("setting.option.value", weapons[j].data.ClassName);
			response.subst("setting.option.text", `HTMLEscape(weapons[j].data.FriendlyName));
			if (weapons[j].data.ClassName ~= selectedValue)
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
		substvar $= response.LoadParsedUHTM(renderer.getPath() $ "/" $ renderer.getFilePrefix() $ "entry.inc");
	}
	response.subst("settings", substvar);
	response.Subst(substName, response.LoadParsedUHTM(renderer.getPath() $ "/" $ renderer.getFilePrefix() $ "wrapper_single.inc"));
}
