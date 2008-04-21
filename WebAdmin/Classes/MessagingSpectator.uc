/**
 * MessagingSpectator. Spectator base class for game helper spectators which receive messages
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks, Josh Markiewicz
 */
class MessagingSpectator extends Admin;

delegate ReceiveMessage( PlayerReplicationInfo Sender, string Msg, name Type );

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	if (PlayerReplicationInfo == none)
	{
		InitPlayerReplicationInfo();
	}

}

reliable client event TeamMessage( PlayerReplicationInfo PRI, coerce string S, name Type, optional float MsgLifeTime  )
{
	if (type != 'Say' && type != 'TeamSay' && type != 'none')
	{
		`Log("Received message that is not 'say' or 'teamsay'. Type="$type$" Message= "$s);
	}
	ReceiveMessage(pri, s, type);
}

function InitPlayerReplicationInfo()
{
	super.InitPlayerReplicationInfo();
	PlayerReplicationInfo.bIsInactive = true;
	PlayerReplicationInfo.PlayerName = "WebAdmin";
	PlayerReplicationInfo.bIsSpectator = true;
	PlayerReplicationInfo.bOnlySpectator = true;
	PlayerReplicationInfo.bOutOfLives = true;
	PlayerReplicationInfo.bWaitingPlayer = false;
}

auto state NotPlaying
{}

function EnterStartState()
{
	GotoState('NotPlaying');
}

function bool IsSpectating()
{
	return true;
}

reliable client function ClientGameEnded(Actor EndGameFocus, bool bIsWinner)
{}

function GameHasEnded(optional Actor EndGameFocus, optional bool bIsWinner)
{}

function Reset()
{}

reliable client function ClientReset()
{}

event InitInputSystem()
{
	if (PlayerInput == None)
	{
		Assert(InputClass != None);
		PlayerInput = new(Self) InputClass;
	}
	if ( Interactions.Find(PlayerInput) == -1 )
	{
		Interactions[Interactions.Length] = PlayerInput;
	}
}

defaultproperties
{
	bIsPlayer=False
	CameraClass=None
}