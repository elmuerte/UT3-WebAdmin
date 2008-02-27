/**
 * Various static utility functions
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class WebAdminUtils extends Object;

struct DateTime
{
	var int year;
	var int month;
	var int day;
	var int hour;
	var int minute;
	var int second;
};

/**
 * Escape HTML tags in the given string. Expects the input to not contain any
 * escaped entities (i.e. &...;)
 */
static final function String HTMLEscape(coerce string inp)
{
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
	while (e > b)
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
 * Parse a timestamp to a DateTime structure. When no timestamp is given the current timestamp will be used.
 * The format of the timestamp is: YYYY/MM/DD - HH:MM:SS
 */
static final function bool getDateTime(out DateTime record, optional string ts = TimeStamp())
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
