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
 * Escape HTML tags in the given string.
 */
function static final String HTMLEscape(coerce string inp)
{
	inp = Repl(inp, "<", "&lt;");
	inp = Repl(inp, ">", "&gt;");
	return Repl(inp, "&", "&amp;");
}

/**
 * Convert a color to the HTML equivalent
 */
function static final String ColorToHTMLColor(Color clr)
{
	return "#"$Left(ToHex(clr.R), 2)$Left(ToHex(clr.G), 2)$Left(ToHex(clr.B), 2);
}

/**
 * Parse a timestamp to a DateTime structure. When no timestamp is given the current timestamp will be used.
 * The format of the timestamp is: YYYY/MM/DD - HH:MM:SS
 */
function static final bool getDateTime(out DateTime record, optional string ts = TimeStamp())
{
	local int idx;
	local array<string> parts;
	ts -= " ";
	idx = InStr(ts, "-");
	if (idx == -1) return false;
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
