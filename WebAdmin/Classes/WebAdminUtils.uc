/**
 * Various static utility functions
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class WebAdminUtils extends Object;

struct TranslitEntry
{
	/** from */
	var string f;
	/** to */
	var string t;
};

/** translit characters */
var localized array<TranslitEntry> translit;

struct DateTime
{
	var int year;
	var int month;
	var int day;
	var int hour;
	var int minute;
	var int second;
};

static final function String translitText(coerce string inp)
{
	local int i;
	for (i = 0; i < default.translit.length; i++)
	{
		inp = Repl(inp, default.translit[i].f, default.translit[i].t);
	}
	return inp;
}

/**
 * Escape HTML tags in the given string. Expects the input to not contain any
 * escaped entities (i.e. &...;)
 */
static final function String HTMLEscape(coerce string inp)
{
	inp = translitText(inp);
	inp = Repl(inp, "&", "&amp;");
	inp = Repl(inp, "<", "&lt;");
	inp = Repl(inp, "\"", "&quot;");
	return Repl(inp, ">", "&gt;");
}

/**
 * Trim everything below ascii 32 from begin and end
 */
static final function String Trim(coerce string inp)
{
	local int b,e;
	b = 0;
	e = Len(inp)-1;
	while (b < e)
	{
		if (Asc(Mid(inp, b, 1)) > 32) break;
		b++;
	}
	while (e >= b)
	{
		if (Asc(Mid(inp, e, 1)) > 32) break;
		e--;
	}
	return mid(inp, b, e-b+1);
}

/**
 * Convert a color to the HTML equivalent
 */
static final function String ColorToHTMLColor(color clr)
{
	return "#"$Right(ToHex(clr.R), 2)$Right(ToHex(clr.G), 2)$Right(ToHex(clr.B), 2);
}

/**
 * Parse a timestamp to a DateTime structure.
 * The format of the timestamp is: YYYY/MM/DD - HH:MM:SS
 */
static final function bool getDateTime(out DateTime record, string ts)
{
	local int idx;
	local array<string> parts;
	ts -= " ";
	idx = InStr(ts, "-");
	if (idx == INDEX_NONE) return false;
	ParseStringIntoArray(Left(ts, idx), parts, "/", false);
	if (parts.length != 3) return false;
	record.year = int(parts[0]);
	record.month = int(parts[1]);
	record.day = int(parts[2]);
	ParseStringIntoArray(Mid(ts, idx+1), parts, ":", false);
	if (parts.length != 3) return false;
	record.hour = int(parts[0]);
	record.minute = int(parts[1]);
	record.second = int(parts[2]);
	return true;
}

static final function string getLocalized(coerce string data)
{
	local array<string> parts;
	if (!(Left(data, 9) ~= "<Strings:")) return data;
	data = Mid(data, 9, Len(data)-10);
	ParseStringIntoArray(data, parts, ".", true);
	if (parts.length >= 3)
	{
		return Localize(parts[1], parts[2], parts[0]);
	}
	return "";
}

static final function parseUrlOptions(out array<KeyValuePair> options, string url)
{
	local string part;
	local array<string> parts;
	local int idx, i;
	local KeyValuePair kv;

	ParseStringIntoArray(url, parts, "?", true);
	foreach parts(part)
	{
		i = InStr(part, "=");
		if (i == INDEX_NONE)
		{
			kv.Key = part;
			kv.Value = "";
		}
		else {
			kv.Key = Left(part, i);
			kv.Value = Mid(part, i+1);
		}
		for (idx = 0; idx < options.length; idx++)
		{
			if (kv.key ~= options[idx].key)
			{
				break;
			}
		}
		`Log("Add "$kv.key$" at "$idx);
		options[idx] = kv;
	}
}
