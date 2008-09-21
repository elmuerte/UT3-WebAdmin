//==============================================================================
//  UT derived image server class
//  Ported to UE3 by Josh Markiewicz
//  © 1998-2008, Epic Games, Inc. All Rights Reserved
//==============================================================================
class UTImageServer extends ImageServer;

function string normalizeUri(string uri)
{
    local array<string> str;
    local int i;
    ParseStringIntoArray(repl(uri, "\\", "/"), str, "/", true);
    for (i = str.length-1; i >= 0; i--)
    {
        if (str[i] == "..") 
        {
            i -= 1;
            if (i < 0) 
            {
                str.remove(0, 1);
            }
            else {
                str.remove(i, 2);
            }
        }
    }
    JoinArray(str, uri, "/");
    return "/"$uri;
}

function Query(WebRequest Request, WebResponse Response)
{
	local string ext, part;
	local int idx;
	
	if (InStr(Request.URI, "..") != INDEX_NONE)
	{
	   Request.URI = normalizeUri(Request.URI);
    }
    
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
