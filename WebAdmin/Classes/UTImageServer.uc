//==============================================================================
//  UT derived image server class
//  Ported to UE3 by Josh Markiewicz
//  © 1998-2008, Epic Games, Inc. All Rights Reserved
//==============================================================================
class UTImageServer extends ImageServer;

function Query(WebRequest Request, WebResponse Response)
{
	// not really images, but we let the image server handle it anyway
	// because it may be cached and doesn't require any other validation
	if( Right(Request.URI, 3) ~= ".js" )
	{
		Response.SendStandardHeaders("text/javascript", true);
		Response.IncludeBinaryFile( Path $ Request.URI );
		return;
	}
	else if( Right(Request.URI, 4) ~= ".css" )
	{
		Response.SendStandardHeaders("text/css", true);
		Response.IncludeBinaryFile( Path $ Request.URI );
		return;
	}
	else if( Right(Request.URI, 4) ~= ".ico" )
	{
		Response.SendStandardHeaders("image/x-icon", true);
		Response.IncludeBinaryFile( Path $ Request.URI );
		return;
	}
	super.query(Request, Response);
}
