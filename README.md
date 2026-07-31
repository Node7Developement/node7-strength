[README.md](https://github.com/user-attachments/files/30592863/README.md)
# node7-strength








<img width="605" height="534" alt="strengthui" src="https://github.com/user-attachments/assets/06d94ede-80b2-4c4f-a42b-451a354d2b96" />

Separate NODE7 RedM player strength resource.

This resource gives players a real strength stat without tying it into lawmen, jobs, gangs, or inventory logic.

## Features

- Separate resource: `node7-strength`
- Own SQL table: `node7_strength`
- Uses `node7-core` for player identity
- Native RedM training prompts
- `/strength` player stat UI
- Strength XP from training and clean brawls
- Small brawl, carry, stamina, and knockdown-resist multipliers
- Daily XP cap
- Training cooldown
- Admin commands
- Export-ready for future NODE7 scripts

## Install

Place the resource here:

```txt
resources/[node7]/node7-strength
```

Import the SQL:

```txt
node7-strength/sql/node7_strength.sql
```

Add to `server.cfg` after `node7-core` and `oxmysql`:

```cfg
ensure oxmysql
ensure node7-core
ensure node7-strength
```

## Required RedM Manifest Warning

The fxmanifest already includes:

```lua
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
```

## Player Command

```txt
/strength
```

Opens the player strength UI.

## Admin Commands

Requires ACE permission:

```cfg
add_ace group.admin node7.strength.admin allow
```

Commands:

```txt
/setstrength [id] [level]
/addstrengthxp [id] [amount]
/resetstrength [id]
```

## Exports

```lua
exports['node7-strength']:GetStrength(source)
exports['node7-strength']:GetStrengthLevel(source)
exports['node7-strength']:AddStrengthXP(source, amount, reason)
exports['node7-strength']:SetStrengthLevel(source, level)
exports['node7-strength']:ResetStrength(source)
exports['node7-strength']:GetCarryMultiplier(source)
exports['node7-strength']:GetBrawlMultiplier(source)
exports['node7-strength']:GetStaminaMultiplier(source)
```

## Balance

Strength does not add bullet resistance.

Strength does not give godmode.

Strength does not make players unkillable.

Strength only gives small physical bonuses so it matters without ruining PvP.

## Training Spots

Training spots are configured in:

```txt
config.lua
```

Each training spot uses native RedM prompts.

## Notes

Keep this resource separate from lawmen, jobs, and gangs.

Other scripts can use the exports when they need player strength data.
