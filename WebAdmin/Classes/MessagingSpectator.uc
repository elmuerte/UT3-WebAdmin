//=============================================================================
// MessagingSpectator - spectator base class for game helper spectators which receive messages
//
//  Ported to UE3 by Josh Markiewicz
//  © 1998-2008, Epic Games, Inc. All Rights Reserved
//=============================================================================

class MessagingSpectator extends Admin;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	bIsPlayer = False;
}

auto state NotPlaying
{
}

function InitPlayerReplicationInfo()
{
	Super.InitPlayerReplicationInfo();
	PlayerReplicationInfo.PlayerName="WebAdmin";
	PlayerReplicationInfo.bIsSpectator = true;
	PlayerReplicationInfo.bOnlySpectator = true;
	PlayerReplicationInfo.bOutOfLives = true;
	PlayerReplicationInfo.bWaitingPlayer = false;
}
