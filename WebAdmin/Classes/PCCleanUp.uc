/**
 * Provides a mechanism to clean up the messaging spectators. These are kept
 * in memory because they are a PlayerController subclass, and not cleaned up
 * because they are not associated with players.
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks
 */
class PCCleanUp extends Info;

var array<MessagingSpectator> cleanupControllers;

event PreBeginPlay()
{
	local MessagingSpectator specs;
	super.PreBeginPlay();

	foreach WorldInfo.AllControllers(class'MessagingSpectator', specs)
	{
		if (specs.isSeamlessDelete())
		{
			cleanupControllers[cleanupControllers.length] = specs;
		}
	}
	if (cleanupControllers.length > 0)
	{
		`Log("Cleaning up "$cleanupControllers.length$" MessagingSpectator instances");
		SetTimer(1, false, 'cleanup');
	}
	else {
		Destroy();
	}
}

function cleanup()
{
	local MessagingSpectator specs;
	foreach cleanupControllers(specs)
	{
		specs.Destroy();
	}
	Destroy();
}