/**
 * MessagingSpectator. Spectator base class for game helper spectators which receive messages
 *
 * Copyright 2008 Epic Games, Inc. All Rights Reserved
 *
 * @author  Michiel 'elmuerte' Hendriks, Josh Markiewicz
 */
class MessagingSpectator extends Admin;

// Used to clean up these actors during seamless traveling
var protected bool bSeamlessDelete;

var array< delegate<ReceiveMessage> > receivers;

/**
 * If true this messaging spectator is kept alive when the list or receivers is
 * empty;
 */
var bool bKeepAlive;

delegate ReceiveMessage( PlayerReplicationInfo Sender, string Msg, name Type );

function AddReceiver(delegate<ReceiveMessage> ReceiveMessageDelegate)
{
	if (receivers.Find(ReceiveMessageDelegate) == INDEX_NONE)
	{
		receivers[receivers.Length] = ReceiveMessageDelegate;
	}
}

function ClearReceiver(delegate<ReceiveMessage> ReceiveMessageDelegate)
{
	local int RemoveIndex;
	RemoveIndex = receivers.Find(ReceiveMessageDelegate);
	if (RemoveIndex != INDEX_NONE)
	{
		receivers.Remove(RemoveIndex,1);
	}
	if (receivers.length == 0 && ReceiveMessage == none)
	{
		Destroy();
	}
}

function bool isSeamlessDelete()
{
	return bSeamlessDelete;
}

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	bSeamlessDelete = true;
	if (PlayerReplicationInfo == none)
	{
		InitPlayerReplicationInfo();
	}

}

reliable client event TeamMessage( PlayerReplicationInfo PRI, coerce string S, name Type, optional float MsgLifeTime  )
{
	local delegate<ReceiveMessage> rm;
	if (type == 'TeamSay') return; // received through TeamChatProxy
	if (type != 'Say' && type != 'TeamSay' && type != 'none')
	{
		`Log("Received message that is not 'say' or 'teamsay'. Type="$type$" Message= "$s);
	}
	foreach receivers(rm)
	{
		rm(pri, s, type);
	}
	if (ReceiveMessage != none)
	{
		ReceiveMessage(pri, s, type);
	}
}

function InitPlayerReplicationInfo()
{
	super.InitPlayerReplicationInfo();
	PlayerReplicationInfo.bIsInactive = true;
	PlayerReplicationInfo.PlayerName = "<<WebAdmin>>";
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

event PlayerTick( float DeltaTime )
{
	// this is needed because PlayerControllers with no actual player attached
	// will leak during seamless traveling.
	if (WorldInfo.NextURL != "" || WorldInfo.IsInSeamlessTravel())
	{
		Destroy();
	}
}

defaultproperties
{
	bIsPlayer=False
	CameraClass=None
	bAlwaysTick=true
	bKeepAlive=false
}