//=============================================================================
// HeadlessBotsMut.
// Populates an unattended DeathMatchPlus server once per map load.
//=============================================================================
class HeadlessBotsMut extends Mutator
	config(HeadlessBots);

var() config int DesiredBots;
var() config float StartupDelay;
var() config bool bEnabled;
var bool bPopulationAttempted;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	if ( bEnabled )
		SetTimer(FMax(StartupDelay, 0.1), false);
}

function Timer()
{
	local DeathMatchPlus DM;
	local int BotsToAdd;

	if ( bPopulationAttempted || !bEnabled )
		return;
	bPopulationAttempted = true;
	DM = DeathMatchPlus(Level.Game);
	if ( DM == None )
	{
		Log("HeadlessBots: not running DeathMatchPlus; no bots added.");
		return;
	}
	// NumBots is maintained by DeathMatchPlus; fill once, rather than running
	// a second ongoing bot controller that could create duplicate bots.
	BotsToAdd = Max(0, DesiredBots - DM.NumBots);
	while ( (BotsToAdd > 0) && DM.ForceAddBot() )
		BotsToAdd--;
	// Dedicated DeathMatchPlus waits for a human before it leaves bNetReady.
	// Its Timer then clears bNetReady AND bRequireReady before StartMatch().
	// Do the same here: while bNetReady is true the Timer returns early, and
	// while bRequireReady is true (CountDown > 0) it stays in the "waiting for
	// ready" branch. Either way it never reaches the time limit or the restart
	// after a match (map rotation), and joining players are held in
	// PlayerWaiting, which looks like spectating. (2026-11-05: matches ended at
	// the frag limit and the server sat on the end screen until restarted.)
	if ( !DM.bGameEnded )
	{
		DM.bNetReady = false;
		DM.bRequireReady = false;
		DM.StartMatch();
	}
	Log("HeadlessBots: requested "$DesiredBots$" bots; DeathMatchPlus has "$DM.NumBots$".");
}

defaultproperties
{
	DesiredBots=8
	StartupDelay=5.000000
	bEnabled=True
}
