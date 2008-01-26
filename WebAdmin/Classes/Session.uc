/**
 * A session implementation
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class Session extends Object implements(ISession);

struct ObjectKV
{
	var string key;
	var Object value;
};

struct StringKV
{
	var string key;
	var string value;
};

var protected string id;
var protected array<ObjectKV> objects;
var protected array<StringKV> strings;

function string getId()
{
	local int i;
	if (id == "")
	{
		for (i = 0; i < 8; i++)
		{
			id $= Right(ToHex(rand(MaxInt)), 4);
		}
	}
	return id;
}

function reset()
{
	objects.remove(0, objects.length);
	strings.remove(0, strings.length);
}

function Object getObject(string key)
{
	local int idx;
	idx = objects.Find('key', key);
	if (idx > -1)
	{
		return objects[idx].value;
	}
    return none;
}

function putObject(string key, Object value)
{
	local int idx;
	idx = objects.Find('key', key);
	if (idx > -1)
	{
		objects[idx].value = value;
		return;
	}
    objects.add(1);
    objects[objects.length - 1].key = key;
    objects[objects.length - 1].value = value;
}

function removeObject(string key)
{
	local int idx;
	idx = objects.Find('key', key);
	if (idx > -1)
	{
		objects.remove(idx, 1);
		return;
	}
}

function string getString(string key, optional string defValue = "")
{
	local int idx;
	idx = strings.Find('key', key);
	if (idx > -1)
	{
		return strings[idx].value;
	}
    return defValue;
}

function putString(string key, string value)
{
	local int idx;
	idx = strings.Find('key', key);
	if (idx > -1)
	{
		strings[idx].value = value;
		return;
	}
    strings.add(1);
    strings[strings.length - 1].key = key;
    strings[strings.length - 1].value = value;
}

function removeString(string key)
{
	local int idx;
	idx = strings.Find('key', key);
	if (idx > -1)
	{
		strings.remove(idx, 1);
		return;
	}
}
