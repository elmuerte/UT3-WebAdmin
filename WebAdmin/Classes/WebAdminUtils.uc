/**
 * Various static utility functions
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class WebAdminUtils extends Object;

function static final String HTMLEscape(coerce string inp)
{
	inp = Repl(inp, "<", "&lt;");
	inp = Repl(inp, ">", "&gt;");
	return Repl(inp, "&", "&amp;");
}

function static final String ColorToHTMLColor(Color clr)
{
	return "#"$Left(ToHex(clr.R), 2)$Left(ToHex(clr.G), 2)$Left(ToHex(clr.B), 2);
}
