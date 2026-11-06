# SWBF2 Asymmetric AI Class Randomizer & Customizer

![Lua](https://img.shields.io/badge/Lua-5.0.2-blue.svg)
![Game](https://img.shields.io/badge/Game-Star%20Wars%20Battlefront%20II%20(2005)-yellow.svg)
![Patch](https://img.shields.io/badge/Requires-Unofficial%20Patch%20v1.3-success.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

A global gameplay and AI overhaul mod for classic **Star Wars Battlefront II (2005)** that fixes the "one-man army" problem. Instead of applying a flat handicap that makes your allies useless on Elite or makes enemies brainless on Normal, this mod equalizes both teams' baseline AI and **randomly boosts specific unit classes on each team** at the start of every match.

---

## Why This Mod Exists (The Vanilla AI Problem)

In vanilla *Battlefront II*, the Zero Engine calculates AI skill on an internal numeric scale (`Base + Lua + Auto = Total`):

1. **Hidden Team Handicaps:** 
   * On **Normal (`medium`)**, your allies start at **Level 10** while enemies start at **Level 12** (+2 enemy advantage).
   * On **Elite (`hard`)**, your allies start at **Level 11** while enemies skyrocket to **Level 17** (+6 enemy advantage).
   * As a result, Normal feels too easy, while Elite turns your allies into cannon fodder that get wiped out immediately, forcing you to carry the entire team alone.
2. **Rubber-Banding (`AIAutoBalance`):** By default, the engine dynamically lowers your allies' intelligence whenever you go on a killstreak or gain a reinforcement lead.
3. **Uniform Class Scaling:** Vanilla difficulty scales an entire team equally rather than creating dynamic squad threats on the battlefield.

---

## Key Features

* **Automatic Baseline Equalization:** Detects whether your profile is set to **Normal** or **Elite** (even if changed mid-match) and lowers the Enemy team's global engine modifier (`-2` on Normal, `-6` on Elite) down to the Player team's baseline (`+0`). It also disables `AIAutoBalance` rubber-banding.
* **Per-Match Class Randomization:** Hooks globally into `SetupTeams()` so that before every Instant Action match, a random subset of unit classes (`soldier`, `assault`, `sniper`, `engineer`, `officer`, `special`) on both factions are promoted to boosted AI tiers while the remaining classes stay at the standard baseline.
* **Asymmetric Ally vs. Enemy Customization:** Configure your team and the enemy team independently:
  * Choose how many **Enemy classes** (`0` to `6`) get boosted each match.
  * Choose the **Enemy AI Boost Level** (`+1` to `+10`, where `+6` matches Vanilla Elite).
  * Choose how many **Ally classes** (`0` to `6`) get boosted each match.
  * Choose the **Ally AI Boost Level** (`+1` to `+10`, allowing you to give a few allied classes a `+7` or `+8` boost so they genuinely hold objectives).
* **Zero Player Weapon Side-Effects:** Modifies `AIBubbleSizeMultiplier` (the AI's internal target error sphere) on faction weapons and `AIVisibilityFactor` on unit ODFs. Your personal crosshair spread and weapon accuracy remain 100% untouched.
* **Smart Human Team Detection:** Hooks `OnCharacterSpawn` to automatically detect which faction you joined (even if you switch teams mid-match) and routes the Ally and Enemy boosts to the correct sides in real time.
* **Live In-Game Configuration Menu:** Adjust class counts, boost levels (`+1` to `+10`), toggle the mod on/off, or re-roll boosted classes mid-match via the in-game menu without restarting the map.

---

## How the Boost Tiers Work

Once both teams are equalized to the non-boosted baseline (`+0`), boosted unit classes receive scaled `AIBubbleSizeMultiplier` (aim cone tightness) and `AIVisibilityFactor` (spotting range & reaction speed) properties in memory:

| Boost Tier | Equivalent AI Level | `AIBubbleSizeMultiplier` | `AIVisibilityFactor` | Combat Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **`+0` (Unboosted)** | Level 11 (Base) | `1.35` | `0.85` | Standard Normal AI; forgiving aim cone against moving targets |
| **`+1` to `+3`** | Levels 12 – 14 | `1.05` – `0.45` | `0.92` – `1.06` | Sharper burst grouping and faster target acquisition |
| **`+4` (Default Enemy)** | Level 15 | `0.25` | `1.13` | Threatening and accurate without feeling unfair |
| **`+5`** | Level 16 | `0.16` | `1.20` | Aggressive, tight fire discipline |
| **`+6` (Vanilla Elite)** | Level 17 | `0.10` | `1.27` | Matches classic Elite AI lethality |
| **`+7` (Default Ally)** | Level 18 | `0.06` | `1.34` | Veteran AI; locks onto targets quickly and wins 1v1 engagements |
| **`+8` to `+10`** | Levels 19 – 21 | `0.04` – `0.02` | `1.42` – `1.60` | SpecOps / Aimbot tier; near-instant reaction and deadly accuracy |

### Example Default Scenario
Out of the box, the mod is configured for a balanced, tactical firefight:
* **Enemy Team:** **4 random classes** are boosted by **`+4`** (harder than Normal, slightly more forgiving than vanilla Elite), while **2 classes** stay at Base (`+0`).
* **Ally Team:** **2 random classes** are boosted by **`+7`** (stronger than vanilla Elite so your specialized teammates can hold command posts), while **4 classes** stay at Base (`+0`).

---

## Installation

### Prerequisites
* **Star Wars Battlefront II (2005)** (Steam, GOG, or Disc version)
* **Unofficial v1.3 Patch (r129 / r130)** installed (required for `user_script_*.lvl` auto-loading and Fake Console support).

### Method 1: Plug-and-Play Release (Recommended)
1. Download the latest release zip from the **Releases** tab.
2. Extract the `AI_Randomizer` folder into your game's `addon` directory:
   ```text
   Star Wars Battlefront II/
   └── GameData/
       └── addon/
           └── AI_Randomizer/
               └── data/
                   └── _lvl_pc/
                       └── user_script_airand.lvl
