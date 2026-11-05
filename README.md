# HeadlessBots for UT99 469f

`HeadlessBotsMut` is a DeathMatchPlus-only mutator for an unattended server. On every map load it waits for `StartupDelay`, calls `DeathMatchPlus.AddBot()` until `DesiredBots` is reached, then calls `StartMatch()` so a dedicated server does not wait for a human connection.

It does not set `MinPlayers`, replace the game type, alter `Rainbow.RainbowArena`, or modify the map list. `DeathMatchPlus` retains normal map rotation and bot lifecycle behavior after startup.

## Configuration

```ini
[HeadlessBots.HeadlessBotsMut]
DesiredBots=8
StartupDelay=5.000000
bEnabled=True
```

## Build

```powershell
& 'C:\UnrealTournament\HeadlessBots\scripts\Build-HeadlessBots.ps1'
```

The build backs up `UnrealTournament.ini`, preserves an existing package as `HeadlessBots.u.before-build`, compiles with UCC, and installs the configuration only after a package is produced.

## Deploy

```powershell
& 'C:\UnrealTournament\HeadlessBots\scripts\Deploy-HeadlessBots.ps1'
```

Use `-WhatIf` first for a no-change preview. Deployment stages the files, saves a timestamped backup on the server, adds the package and mutator to `/home/rc6750/.utpg/System/UnrealTournament.ini` when absent, removes `Mutator=Autofill.AutofillMut`, then restarts `ut99.service`. If a deployment fails, restore the three files from the printed `headlessbots-backup-*` directory and restart the service.

## Verification

After building, confirm `C:\UnrealTournament\System\HeadlessBots.u` exists. After deployment, use `journalctl -u ut99.service -n 100 --no-pager` and look for the `HeadlessBots:` log line; verify the bot count both just after startup and after a map rotation.

This snapshot has not been compiled or deployed by this task.
