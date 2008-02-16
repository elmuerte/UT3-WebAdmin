//==============================================================================
//  UT derived image server class
//  Ported to UE3 by Josh Markiewicz
//  © 1998-2008, Epic Games, Inc. All Rights Reserved
//==============================================================================
class UTImageServer extends ImageServer;

function Query(WebRequest Request, WebResponse Response)
{
	local string ext, part;
	local int idx;
	// not really images, but we let the image server handle it anyway
	// because it may be cached and doesn't require any other validation
	idx = InStr(Request.URI, ".", true);
	if (idx != INDEX_NONE)
	{
		ext = Mid(Request.URI, idx+1);
		if (ext ~= "gz")
		{
			part = Left(Request.URI, idx);
			idx = InStr(part, ".", true);
			if (idx != INDEX_NONE)
			{
				ext = Mid(part, idx+1);
				response.AddHeader("Content-Encoding: gzip");
			}
		}
	}
	if( ext ~= "js" )
	{
		Response.SendStandardHeaders("text/javascript", true);
		Response.IncludeBinaryFile( Path $ Request.URI );
		return;
	}
	else if( ext ~= "css" )
	{
		Response.SendStandardHeaders("text/css", true);
		Response.IncludeBinaryFile( Path $ Request.URI );
		return;
	}
	else if( ext ~= "ico" )
	{
		Response.SendStandardHeaders("image/x-icon", true);
		Response.IncludeBinaryFile( Path $ Request.URI );
		return;
	}
	else if( ext ~= "gz" )
	{
		Response.SendStandardHeaders("application/x-gzip", true);
		Response.IncludeBinaryFile( Path $ Request.URI );
		return;
	}
	super.query(Request, Response);
}
