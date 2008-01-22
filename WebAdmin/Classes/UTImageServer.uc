//==============================================================================
//  UT derived image server class
//  Ported to UE3 by Josh Markiewicz
//  © 1998-2008, Epic Games, Inc. All Rights Reserved
//==============================================================================
class UTImageServer extends ImageServer;

function Query(WebRequest Request, WebResponse Response)
{
	if( Right(Caps(Request.URI), 4) == ".PNG" )
	{
		Response.SendStandardHeaders("image/png", true);
		Response.IncludeBinaryFile( Path $ Request.URI );
	}
	super.query(Request, Response);
}
