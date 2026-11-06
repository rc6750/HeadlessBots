# HeadlessBots for UT99 469f

`HeadlessBotsMut` is a DeathMatchPlus-only mutator for an unattended server. On every map load it waits for `StartupDelay`, calls `DeathMatchPlus.ForceAddBot()` until `DesiredBots` is reached, clears `bNetReady` and `bRequireReady` and calls `StartMatch()` (exactly what DeathMatchPlus itself does once a human has waited long enough) so a dedicated server does not wait for a human connection.

Clearing both matters (fixed 2026-11-05): while `bNetReady` is true, `DeathMatchPlus.Timer` returns early every second; while `bRequireReady` is true (with `CountDown > 0`) it stays in its "waiting for players to be ready" branch. Either way, with no human connected the time limit and the restart after a match never ran — a match ended at the frag limit and the server stayed on the end screen instead of rotating to the next map — and a person joining was held in `PlayerWaiting`, which looks like spectating. The first fix cleared only `bNetReady`; the stock code (`Botpack/DeathMatchPlus.uc`, `Timer`) clears both.

It does not set `MinPlayers`, replace the game type, or modify the map list. `DeathMatchPlus` retains normal map rotation and bot lifecycle behavior after startup.

## Configuration

```ini
[HeadlessBots.HeadlessBotsMut]
DesiredBots=8
StartupDelay=5.000000
bEnabled=True
```



